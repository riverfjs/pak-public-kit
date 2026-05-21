require("UnLuaEx")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TemperatureEnum = require("NewRoco.Modules.Core.Scene.Component.Temperature.TemperatureEnum")
local CameraAdditiveParamStatus = require("NewRoco.Modules.Core.Character.WorldCamera.CameraAdditiveParamStatus")
local CameraAdditiveParamType = require("NewRoco.Modules.Core.Character.WorldCamera.CameraAdditiveParamType")
local BP_PlayerCameraManager_C = NRCClass()

function BP_PlayerCameraManager_C:Initialize(Initializer)
  self._cameraLocation = UE4.FVector(0, 0, 0)
  self._cameraRotation = UE4.FRotator(0, 0, 0)
  self._FOV = 90
  self._pivotLocation = UE4.FVector(0, 0, 0)
  self._smoothPivotTarget = nil
  self._pivotTarget = nil
  self._ctrlRotation = nil
  self._tarRotation = nil
  self._cameraRotatorYaw = UE4.FRotator(0, 0, 0)
  self._init = false
  self._cameraLagMaxTimeStep = 0.0033333333333333335
  self.UseBagCamera = false
  self._bagCurveForward = false
  self._bagFovEntry = 0
  self._bagCameraLengthEntry = 0
  self._bagCameraTime = 0
  self._additiveStatus = {}
  self._radius = 12
  self._highlightStatus = {}
  local highlightActions = DataConfigManager:GetGlobalConfig("mark_video_preview_highlight_action")
  if highlightActions then
    for _, v in pairs(highlightActions.numList) do
      table.insert(self._highlightStatus, v)
    end
  end
end

function BP_PlayerCameraManager_C:Attach()
  self._Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self._Player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self._Player:AddEventListener(self, PlayerModuleEvent.ON_ADDITIVE_CAMERA_PARAM, self.ApplyCameraAdditiveStatus)
  self._Player:AddEventListener(self, PlayerModuleEvent.ON_BODY_TEMP_STATE_CHANGED, self.OnBodyTempStateChanged)
  self._Player:AddEventListener(self, PlayerModuleEvent.ON_LUOPAN_STATE_CHANGED, self.OnLuopanStateChanged)
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
  end
  self._additiveStatus[CameraAdditiveParamType.AimThrow] = CameraAdditiveParamStatus(self.GroundThrowWiggleStatus.Time, self.GroundThrowWiggleStatus.PosCurve, self.GroundThrowWiggleStatus.RotCurve)
  self._additiveStatus[CameraAdditiveParamType.RideThrow] = CameraAdditiveParamStatus(self.RideThrowWiggleStatus.Time, self.RideThrowWiggleStatus.PosCurve, self.RideThrowWiggleStatus.RotCurve)
  self._additiveStatus[CameraAdditiveParamType.FlyThrow] = CameraAdditiveParamStatus(self.FlyThrowWiggleStatus.Time, self.FlyThrowWiggleStatus.PosCurve, self.FlyThrowWiggleStatus.RotCurve)
  self._additiveStatus[CameraAdditiveParamType.DungeonGate] = CameraAdditiveParamStatus(self.DungeonGateWiggleStatus.Time, self.DungeonGateWiggleStatus.PosCurve, self.DungeonGateWiggleStatus.RotCurve)
  self._additiveStatus[CameraAdditiveParamType.DungeonExit] = CameraAdditiveParamStatus(self.DungeonExitWiggleStatus.Time, self.DungeonExitWiggleStatus.PosCurve, self.DungeonExitWiggleStatus.RotCurve)
  self._additiveStatus[CameraAdditiveParamType.InteractionBlock] = CameraAdditiveParamStatus(self.InteractionBlockWiggleStatus.Time, self.InteractionBlockWiggleStatus.PosCurve, self.InteractionBlockWiggleStatus.RotCurve)
end

function BP_PlayerCameraManager_C:ReceiveEndPlay()
  if self._Player then
    self._Player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self._Player:RemoveEventListener(self, PlayerModuleEvent.ON_BODY_TEMP_STATE_CHANGED, self.OnBodyTempStateChanged)
    self._Player:RemoveEventListener(self, PlayerModuleEvent.ON_ADDITIVE_CAMERA_PARAM, self.ApplyCameraAdditiveStatus)
  end
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
  end
  self._additiveStatus = {}
end

function BP_PlayerCameraManager_C:StartCaptureImmediately(RT, bEnableClipOverride)
  local SceneCaptureComponent2D = self.SceneCaptureComponent2D
  if not SceneCaptureComponent2D then
    Log.Error("invalid SceneCaptureComponent2D")
    return nil
  end
  UE4.UNRCStatics.SetCapturePostProcessing(SceneCaptureComponent2D)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = player:GetUEController()
  local Viewport = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  local CameraLocation, ForwardVector = Controller:Abs_DeprojectScreenPositionToWorld(Viewport.X / 2, Viewport.Y / 2)
  local Rotator = UE.UKismetMathLibrary.MakeRotFromX(ForwardVector)
  SceneCaptureComponent2D:Abs_K2_SetWorldLocationAndRotation(CameraLocation, self:GetCameraRotation(), false, nil, false)
  SceneCaptureComponent2D.TextureTarget = RT
  SceneCaptureComponent2D.bDisableFlipCopyGLES = true
  SceneCaptureComponent2D.bOverride_CustomNearClippingPlane = bEnableClipOverride or false
  SceneCaptureComponent2D.bCaptureEveryFrame = false
  SceneCaptureComponent2D.FOVAngle = self.FOV
  SceneCaptureComponent2D:CaptureScene()
  SceneCaptureComponent2D.TextureTarget = nil
end

function BP_PlayerCameraManager_C:DrawDebug()
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  local smoothColor = UE4.FLinearColor(1, 1, 0, 1)
  if UE4.UKismetMathLibrary.Vector_Distance(self.SmoothPivotTarget.Translation, self.PivotTarget.Translation) > 119 then
    smoothColor = UE4.FLinearColor(1, 0, 0, 1)
  end
  if CurrentTarget then
    UE4.UKismetSystemLibrary.DrawDebugSphere(CurrentTarget, self.PivotTarget.Translation, 16, 8, UE4.FLinearColor(0, 1, 0, 1), 0, 0.5)
    UE4.UKismetSystemLibrary.DrawDebugSphere(CurrentTarget, self.SmoothPivotTarget.Translation, 16, 8, smoothColor, 0, 0.5)
    UE4.UKismetSystemLibrary.DrawDebugSphere(CurrentTarget, self.PivotLocation, 16, 8, UE4.FLinearColor(0, 0, 1, 1), 0, 0.5)
    UE4.UKismetSystemLibrary.DrawDebugLine(CurrentTarget, self.PivotTarget.Translation, self.SmoothPivotTarget.Translation, smoothColor, 0, 0.5)
    UE4.UKismetSystemLibrary.DrawDebugLine(CurrentTarget, self.SmoothPivotTarget.Translation, self.PivotLocation, UE4.FLinearColor(0, 0, 1, 1), 0, 0.5)
  end
end

function BP_PlayerCameraManager_C:OnStatusChanged(status, value, type)
  if not UE.UObject.IsValid(self.CameraTargetProxy) then
    return
  end
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  if not CurrentTarget then
    return
  end
  local character = CurrentTarget.sceneCharacter or CurrentTarget.Rider.sceneCharacter
  if not character or not character.statusComponent then
    return
  end
  self.bInRiding = character.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  self.bForceRadius = self.bInRiding or character.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING)
end

function BP_PlayerCameraManager_C:OnInputTouchStart(isJoyStick)
  self:SetCameraBool("bHasInput", true)
end

function BP_PlayerCameraManager_C:OnBodyTempStateChanged(state)
  Log.Debug("BP_PlayerCameraManager_C:OnBodyTempStateChanged", state)
  if state == TemperatureEnum.BodyState.HOT then
    self:ShowHotPostEffect()
  elseif state == TemperatureEnum.BodyState.NORMAL then
    self:HideHotPostEffect()
  end
end

function BP_PlayerCameraManager_C:OnLuopanStateChanged(bOpen)
end

function BP_PlayerCameraManager_C:Reset(bResetTarget)
  if bResetTarget then
    local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
    if CurrentTarget then
      self._pivotTarget = CurrentTarget:GetTransform()
      self._ctrlRotation = CurrentTarget:GetControlRotation()
      self._tarRotation = self._ctrlRotation + UE4.FRotator(self:Get_CameraBehaviorParam("RotationOffsetPitch"), self:Get_CameraBehaviorParam("RotationOffsetYaw"), self:Get_CameraBehaviorParam("RotationOffsetRoll"))
      self._cameraRotation = self._tarRotation
      self._smoothPivotTarget = self._pivotTarget
    end
  end
  for _, v in ipairs(self._additiveStatus) do
    if v.isActive then
      v:SetStatusReActive(false)
    end
  end
  self.bEnableAdditive = false
  self.UseBagCamera = false
  self._bagCameraTime = 0
  self:SetCameraBool("ForceEndThrow", true)
end

function BP_PlayerCameraManager_C:SwitchBagCamera(Entry)
  if nil == Entry then
    Entry = not self._bagCurveForward
  end
  if Entry then
    if not self.UseBagCamera then
      self._bagFovEntry = self:Get_CameraBehaviorParam("FOV")
      local deltaLocation = UE4.UKismetMathLibrary.Subtract_VectorVector(self.CameraLocation, self.SmoothPivotTarget.Translation)
      self._bagCameraLengthEntry = UE4.UKismetMathLibrary.Dot_VectorVector(deltaLocation, UE4.UKismetMathLibrary.GetForwardVector(self.CameraRotation))
    end
    self.UseBagCamera = true
    self._bagCurveForward = true
  else
    self._bagCurveForward = false
  end
end

function BP_PlayerCameraManager_C:SwitchMainUiCamera(Entry, Speed)
  if nil == Entry then
    return
  end
  if Entry then
    self:SetCameraBool("MainUiCamera", true)
    self.bEnableMainUICamera = true
    local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
    if CurrentTarget then
      CurrentTarget:GetController():ResetCtrlRotation(Speed)
    end
  else
    self:SetCameraBool("MainUiCamera", false)
    self.bEnableMainUICamera = false
  end
end

function BP_PlayerCameraManager_C:CalculateBagCamera(deltaTime)
  local MinTime, MaxTime = self.BagCameraCurve:GetTimeRange()
  if self._bagCurveForward then
    self:CalculateBagFOVAndLength()
    if MaxTime > self._bagCameraTime then
      self._bagCameraTime = self._bagCameraTime + deltaTime
    else
    end
  else
    if MinTime < self._bagCameraTime then
      self:CalculateBagFOVAndLength()
      self._bagCameraTime = self._bagCameraTime - deltaTime
    end
    if MinTime >= self._bagCameraTime then
      self._bagCameraTime = 0
      self.UseBagCamera = false
    end
  end
end

function BP_PlayerCameraManager_C:CalculateBagFOVAndLength()
  local FOVoffset = self.BagCameraCurve:GetFloatValue(self._bagCameraTime)
  local EntryTan = math.tan(math.rad(self._bagFovEntry / 2))
  local NowTan = math.tan(math.rad((self._bagFovEntry + FOVoffset) / 2))
  local LengthOffset = self._bagCameraLengthEntry * (EntryTan / NowTan - 1)
  self.CameraLocation = self.CameraLocation + UE4.UKismetMathLibrary.GetForwardVector(self.CameraRotation) * LengthOffset
  self.FOV = self.FOV + FOVoffset
end

function BP_PlayerCameraManager_C:ApplyCameraAdditiveStatus(Type)
  self._additiveStatus[Type]:SetStatusActive(true)
  self.bEnableAdditive = true
end

function BP_PlayerCameraManager_C:RemoveCameraAdditiveStatus(Type)
  self._additiveStatus[Type]:SetStatusActive(false)
end

function BP_PlayerCameraManager_C:OnWorldOffsetChange(InOffset, bWorldShift)
  if self._smoothPivotTarget then
    self._smoothPivotTarget.Translation = self._smoothPivotTarget.Translation + InOffset
  end
end

function BP_PlayerCameraManager_C:PreMainUiCameraCheck()
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  if CurrentTarget and CurrentTarget.sceneCharacter then
    local pivotTarget = CurrentTarget:GetTransform().Translation
    local TargetRotation = CurrentTarget:K2_GetActorRotation()
    local Params = {
      Rotator = {
        x = 10,
        y = 5,
        z = 0
      },
      Pivot = {
        x = 0,
        y = 0,
        z = 55
      },
      Offset = {
        x = -195,
        y = 42,
        z = 0
      },
      MinLength = 170
    }
    local Radius = 12
    if CurrentTarget.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) then
      Params.Pivot.z = Params.Pivot.z + 45
      Params.Offset.z = Params.Offset.z - 15
      Params.Rotator.x = Params.Rotator.x - 10
      Params.MinLength = 170
    end
    if CurrentTarget.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and CurrentTarget and CurrentTarget.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_Swimming then
      Params.Pivot.z = Params.Pivot.z + 45
      Params.Offset.z = Params.Offset.z - 15
      Params.Rotator.x = Params.Rotator.x - 10
      Params.MinLength = 170
    end
    TargetRotation = TargetRotation + UE4.FRotator(Params.Rotator.x, Params.Rotator.y, Params.Rotator.z)
    local offsetedPivot = pivotTarget + UE4.UKismetMathLibrary.GetForwardVector(TargetRotation) * Params.Pivot.x + UE4.UKismetMathLibrary.GetRightVector(TargetRotation) * Params.Pivot.y + UE4.UKismetMathLibrary.GetUpVector(TargetRotation) * Params.Pivot.z
    local cameraLocation = offsetedPivot + UE4.UKismetMathLibrary.GetForwardVector(TargetRotation) * Params.Offset.x + UE4.UKismetMathLibrary.GetRightVector(TargetRotation) * Params.Offset.y + UE4.UKismetMathLibrary.GetUpVector(TargetRotation) * Params.Offset.z
    cameraLocation = self:CameraMultiSweep(offsetedPivot, cameraLocation, Radius)
    local length = (cameraLocation - pivotTarget):Size()
    return length > Params.MinLength
  end
end

function BP_PlayerCameraManager_C:GetBigWorldCameraFinalPOV()
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  if CurrentTarget then
    local pivotTarget = CurrentTarget:GetTransform().Translation
    local TargetRotation = CurrentTarget:GetControlRotation() + UE4.FRotator(self:Get_CameraBehaviorParam("RotationOffsetPitch"), self:Get_CameraBehaviorParam("RotationOffsetYaw"), self:Get_CameraBehaviorParam("RotationOffsetRoll"))
    local offsetedPivot = pivotTarget + UE4.UKismetMathLibrary.Quat_GetAxisX(pivotTarget.Rotation) * self:Get_CameraBehaviorParam("PivotOffset_X") + UE4.UKismetMathLibrary.Quat_GetAxisY(pivotTarget.Rotation) * self:Get_CameraBehaviorParam("PivotOffset_Y") + UE4.UKismetMathLibrary.Quat_GetAxisZ(pivotTarget.Rotation) * self:Get_CameraBehaviorParam("PivotOffset_Z")
    local cameraLocation = offsetedPivot + UE4.UKismetMathLibrary.GetForwardVector(TargetRotation) * self:Get_CameraBehaviorParam("CameraOffset_X") + UE4.UKismetMathLibrary.GetRightVector(TargetRotation) * self:Get_CameraBehaviorParam("CameraOffset_Y") + UE4.UKismetMathLibrary.GetUpVector(TargetRotation) * self:Get_CameraBehaviorParam("CameraOffset_Z")
    cameraLocation = self:CameraMultiSweep(offsetedPivot, cameraLocation, self:GetCameraRadius(TargetRotation))
    return cameraLocation, TargetRotation, self:Get_CameraBehaviorParam("FOV")
  end
end

function BP_PlayerCameraManager_C:UpdateAdditive(DeltaTime)
  self.AdditiveLocation = UE.FVector(0, 0, 0)
  self.AdditiveRotation = UE.FRotator(0, 0, 0)
  for _, v in ipairs(self._additiveStatus) do
    if v.isActive then
      local additiveRot = v:GetRotationOffset(_ == CameraAdditiveParamType.DungeonGate or _ == CameraAdditiveParamType.DungeonExit)
      self.AdditiveRotation = self.AdditiveRotation + UE4.FRotator(additiveRot.X, additiveRot.Y, additiveRot.Z)
    end
  end
  for _, v in ipairs(self._additiveStatus) do
    if v.isActive then
      local additivePos = v:GetCameraOffset(_ == CameraAdditiveParamType.DungeonGate or _ == CameraAdditiveParamType.DungeonExit)
      self.AdditiveLocation = self.AdditiveLocation + UE4.UKismetMathLibrary.GetForwardVector(self.CameraRotation) * additivePos.Y + UE4.UKismetMathLibrary.GetRightVector(self.CameraRotation) * additivePos.X + UE4.UKismetMathLibrary.GetUpVector(self.CameraRotation) * additivePos.Z
    end
  end
  local useAdditive = false
  for _, v in ipairs(self._additiveStatus) do
    if v.isActive then
      useAdditive = true
      v:UpdateData(DeltaTime)
    end
  end
  self.bEnableAdditive = useAdditive
end

function BP_PlayerCameraManager_C:OnPossess(Pawn)
  self.Overridden.OnPossess(self, Pawn)
  self:RefreshPCCameraRotateSetting()
end

function BP_PlayerCameraManager_C:GetCameraRadius(Rotation)
  local Pitch = Rotation.Pitch
  if Pitch > 180 then
    Pitch = Pitch - 360
  end
  if Pitch < -180 then
    Pitch = Pitch + 360
  end
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  local radiusBase = self.CameraRadiusCurve:GetFloatValue(Pitch)
  local moveComp = CurrentTarget and CurrentTarget:GetMovementComponent()
  local waterDepth = moveComp and moveComp.GetImmergeWaterDepth and moveComp:GetImmergeWaterDepth()
  if nil ~= waterDepth and waterDepth > 0 then
    local inWaterMax = UE.UKismetMathLibrary.MapRangeClamped(waterDepth, 0, 100, 70, 20)
    radiusBase = radiusBase < inWaterMax and radiusBase or inWaterMax
  end
  return radiusBase
end

function BP_PlayerCameraManager_C:RefreshPCCameraRotateSetting()
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  if CurrentTarget then
    local InputHandleComponent
    if CurrentTarget.InputHandleComponentBase then
      InputHandleComponent = CurrentTarget.InputHandleComponentBase
    end
    if CurrentTarget.BP_PlayerInputHandleCompnent then
      InputHandleComponent = CurrentTarget.BP_PlayerInputHandleCompnent
    end
    if CurrentTarget.BP_DimoInputHandle then
      InputHandleComponent = CurrentTarget.BP_DimoInputHandle
    end
    if InputHandleComponent then
      InputHandleComponent.MouseTurnRate = _G.UserSettingManager.camera_rotate_yaw_pc
      InputHandleComponent.MouseLookUpRate = _G.UserSettingManager.camera_rotate_pitch_pc
    end
  else
    local playerModule = NRCModuleManager:GetModule("PlayerModule")
    if playerModule and playerModule.playerActor and playerModule.playerActor.BP_DimoInputHandle then
      local InputHandleComponent = playerModule.playerActor.BP_DimoInputHandle
      InputHandleComponent.MouseTurnRate = _G.UserSettingManager.camera_rotate_yaw_pc
      InputHandleComponent.MouseLookUpRate = _G.UserSettingManager.camera_rotate_pitch_pc
    end
  end
end

function BP_PlayerCameraManager_C:SetCameraInHighlight(bInHighlight)
  local cameraAnimInstance = self:GetCameraAnimInstance()
  self.bInHighlight = bInHighlight
  if cameraAnimInstance then
    cameraAnimInstance.bInHighlight = bInHighlight
  end
end

function BP_PlayerCameraManager_C:BeginFilming(NewPawn, bGenNewPawn)
  if not UE.UObject.IsValid(NewPawn) then
    Log.Error("BP_PlayerCameraManager_C:BeginFilming NewPawn \233\157\158\230\179\149")
    return
  end
  if self._Player then
    self._Player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  end
  self.CameraTargetProxy:RequestSetTarget(NewPawn, UE.ECameraTargetType.PlayerPawn)
  self.FilmCtrlRotation = NewPawn:K2_GetActorRotation()
  self.FilmCtrlRotation.Roll = 0
  self.FilmCtrlRotation.Pitch = 0
  if bGenNewPawn then
    self.FilmCtrlRotation = self.FilmCtrlRotation + self.InitialRotationOffset
  end
  self.ECurrentFilmingMode = UE.EFilmingMode.Cruise
  self.IdleTime = 0.0
  local character = NewPawn.sceneCharacter or NewPawn.Rider.sceneCharacter
  if character then
    character:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.DetectRidingAndHighlights)
    if character.statusComponent then
      self.bInRiding = character.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      self.bForceRadius = self.bInRiding or character.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING)
      self:SetCameraInHighlight(false)
      for _, v in ipairs(self._highlightStatus) do
        if character.statusComponent:HasStatus(v) then
          self:SetCameraInHighlight(true)
          break
        end
      end
    end
  end
  local cameraAnimInstance = self:GetCameraAnimInstance()
  if cameraAnimInstance then
    cameraAnimInstance.InRiding = self.bInRiding or false
    self._lastAnimMode = cameraAnimInstance.AnimMode
    if bGenNewPawn then
      self:SetPlayerCameraMode(UE.EPlayerCameraMode.Film)
    end
  end
end

function BP_PlayerCameraManager_C:EndFilming()
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  if CurrentTarget and CurrentTarget.sceneCharacter then
    CurrentTarget.sceneCharacter:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.DetectRidingAndHighlights)
  end
  self.CameraTargetProxy:ResetTarget()
  if self._Player then
    if self._Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      self.CameraTargetProxy:RequestSetTarget(self._Player.viewObj.BP_RideComponent.RidePet, UE.ECameraTargetType.PlayerPawn)
    end
    self._Player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  end
  self.ECurrentFilmingMode = UE.EFilmingMode.None
  self:SetCameraInHighlight(false)
  local cameraAnimInstance = self:GetCameraAnimInstance()
  if cameraAnimInstance then
    cameraAnimInstance.AnimMode = self._lastAnimMode or 0
  end
  self:SetPlayerCameraMode(self._lastAnimMode or UE.EPlayerCameraMode.Locomotion)
end

function BP_PlayerCameraManager_C:DetectRidingAndHighlights(status, value, type)
  local CurrentTarget = self.CameraTargetProxy:GetCurrentTarget()
  if not CurrentTarget then
    return
  end
  if self.ECurrentFilmingMode == UE.EFilmingMode.None then
    return
  end
  local character = CurrentTarget.sceneCharacter or CurrentTarget.Rider.sceneCharacter
  if not character or not character.statusComponent then
    return
  end
  self.bInRiding = character.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  self.bForceRadius = self.bInRiding or character.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING)
  local cameraAnimInstance = self:GetCameraAnimInstance()
  if cameraAnimInstance then
    cameraAnimInstance.InRiding = self.bInRiding
  end
  self:SetCameraInHighlight(false)
  for _, v in ipairs(self._highlightStatus) do
    if character.statusComponent:HasStatus(v) then
      self:SetCameraInHighlight(true)
      break
    end
  end
end

function BP_PlayerCameraManager_C:BeginSideView()
  local cameraAnimInstance = self:GetCameraAnimInstance()
  if cameraAnimInstance then
    self._lastAnimMode = self:GetCameraAnimInstance().AnimMode
    self:SetPlayerCameraMode(UE.EPlayerCameraMode.SideView)
  end
  self.blastBlendBack = self.bBlendBack
  self.bLastEnableAdditive = self.bEnableAdditive
  self.blendBack = false
  self.bEnableAdditive = false
end

function BP_PlayerCameraManager_C:LeaveSideView()
  self:SetPlayerCameraMode(self._lastAnimMode or UE.EPlayerCameraMode.Locomotion)
  self.blendBack = self.blastBlendBack or false
  self.bEnableAdditive = self.bLastEnableAdditive or false
end

return BP_PlayerCameraManager_C

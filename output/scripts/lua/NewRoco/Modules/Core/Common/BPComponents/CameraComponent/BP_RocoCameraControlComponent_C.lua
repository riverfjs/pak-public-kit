require("UnLuaEx")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local FBP_RocoCameraStatusParams = require("NewRoco.Modules.Core.Common.BPComponents.CameraComponent.FBP_RocoCameraStatusParams")
local InputModuleEvent = require("NewRoco.Modules.Core.Input.InputModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local BP_RocoCameraControlComponent_C = NRCClass()
local LocalUE4 = UE4
local LocalUE4Helper = UE4Helper
local LocalQueryExtent = LocalUE4.FVector(1, 1, 200)

function BP_RocoCameraControlComponent_C:GetScenePlayer()
  if PlayerModuleCmd then
    return NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  else
  end
end

function BP_RocoCameraControlComponent_C:GetScenePlayerFsmComp()
  local LocalPlayer = self:GetScenePlayer()
  if LocalPlayer then
    return LocalPlayer.fsmComponent
  end
end

function BP_RocoCameraControlComponent_C:GetCurrentPlayerState()
  local LocalPlayer = self:GetScenePlayer()
  if LocalPlayer then
    return LocalPlayer.fsmComponent:GetCurState()
  end
end

function BP_RocoCameraControlComponent_C:GetInputModule()
  return NRCModuleManager:GetModule("InputModule")
end

function BP_RocoCameraControlComponent_C:GetPlayerModule()
  return NRCModuleManager:GetModule("PlayerModule")
end

function BP_RocoCameraControlComponent_C:Ctor()
  self._hasAddListener = false
  self._lastPlayerLocationVariableCache = UE4.FVector(0, 0, 0)
  self._moveLocationDirectionVariableCache = UE4.FVector(0, 0, 0)
end

function BP_RocoCameraControlComponent_C:Initialize(Initializer)
  self.PrimaryComponentTick.bCanEverTick = true
  self.PrimaryComponentTick.TickGroup = UE4.ETickingGroup.TG_DuringPhysics
end

function BP_RocoCameraControlComponent_C:ReceiveBeginPlay()
  self._ueCtrl = self:GetOwner()
  self._currentPawn = self._ueCtrl:K2_GetPawn()
  if 0 ~= self.Yaw_IgnoreAngle then
    self._maxDirCos = math.cos(math.rad(self.Yaw_IgnoreAngle))
    self._minDirCos = math.cos(math.rad(180 - self.Yaw_IgnoreAngle))
  end
  self._PitchAngleSpeed = 0
  self._needLerpPitchAngle = true
  self._needLerpYaw = true
  self._needApplySlopeOffset = false
  self._isClimbing = false
  self:SetTickEnable(true)
end

function BP_RocoCameraControlComponent_C:ReceiveEndPlay()
  self:RemoveEventListener()
  self._ueCtrl = nil
  self:SetTickEnable(false)
end

function BP_RocoCameraControlComponent_C:SetTickEnable(Enable)
  if Enable then
    UpdateManager:Register(self)
  else
    UpdateManager:UnRegister(self)
  end
end

function BP_RocoCameraControlComponent_C:Attach()
  Log.Debug("BP_RocoCameraControlComponent_C:Attach")
  self:AddEventListener()
end

function BP_RocoCameraControlComponent_C:MouseMoveStart()
  Log.Debug("BP_RocoCameraControlComponent_C:MouseMoveStart()")
  self:OnInputTouchStart()
end

function BP_RocoCameraControlComponent_C:MouseMoveEnd()
  Log.Debug("BP_RocoCameraControlComponent_C:MouseMoveEnd()")
  self:OnInputTouchEnd()
end

function BP_RocoCameraControlComponent_C:AddEventListener()
  if not self._hasAddListener then
    local playerModule = self:GetPlayerModule()
    if playerModule then
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_END, self.OnInputTouchEnd)
      self._currentPawn.sceneCharacter:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
      self._hasAddListener = true
      if LocalUE4Helper.IsPCMode() then
        local iaMoveStart = UE.UNRCEnhancedInputHelper.GetInputAction("IA_MouseMoveStart")
        local iaMoveEnd = UE.UNRCEnhancedInputHelper.GetInputAction("IA_MouseMoveEnd")
        UE.UNRCEnhancedInputHelper.BindAction(iaMoveStart, UE.ETriggerEvent.Triggered, self, "MouseMoveStart")
        UE.UNRCEnhancedInputHelper.BindAction(iaMoveEnd, UE.ETriggerEvent.Triggered, self, "MouseMoveEnd")
      end
    end
  end
end

function BP_RocoCameraControlComponent_C:RemoveEventListener()
  if self._hasAddListener then
    local playerModule = self:GetPlayerModule()
    if playerModule then
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_END, self.OnInputTouchEnd)
      if self._currentPawn.sceneCharacter then
        self._currentPawn.sceneCharacter:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
      end
      local iaStart = UE.UNRCEnhancedInputHelper.GetInputAction("IA_MouseMoveStart")
      local iaEnd = UE.UNRCEnhancedInputHelper.GetInputAction("IA_MouseMoveEnd")
      UE.UNRCEnhancedInputHelper.UnBindAction(iaStart)
      UE.UNRCEnhancedInputHelper.UnBindAction(iaEnd)
    end
    self._hasAddListener = false
  end
end

function BP_RocoCameraControlComponent_C:OnTick(DeltaSeconds)
  if not UE.UObject.IsValid(self._currentPawn) or not self._currentPawn.sceneCharacter then
    return
  end
  if (self._isControllingView or self._ueCtrl.Aiming) and not self._resetRotation then
    return
  end
  if not self._ueCtrl or self._ueCtrl.IsCameraControlDisabled and self._ueCtrl:IsCameraControlDisabled() then
    return
  end
  self:TickCheckParams(DeltaSeconds)
  self:TickLerp(DeltaSeconds)
end

function BP_RocoCameraControlComponent_C:OnInputTouchStart(isJoyStick)
  if isJoyStick then
    if not self._isControllingView then
      self:ClearStatus()
    end
  else
    self._isControllingView = true
    self:ClearStatus()
  end
end

function BP_RocoCameraControlComponent_C:OnInputTouchEnd(isJoyStick)
  if isJoyStick then
    if not self._isControllingView then
      self:ClearStatus()
    end
  else
    self._isControllingView = false
    self:ClearStatus()
    self:CheckRunning()
  end
end

function BP_RocoCameraControlComponent_C:OnPlayerMountingChanged(isMounting)
  self:RefreshCameraStatusParam()
end

function BP_RocoCameraControlComponent_C:OnPlayerStatusChanged(...)
  local StatusComponent = self._currentPawn.sceneCharacter.statusComponent
  local isClimb = StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB)
  if self._isClimbing ~= isClimb then
    self._isClimbing = isClimb
    if isClimb and not self._isControllingView then
      local PlayerForward = self._currentPawn:GetMovementComponent().CurrentClimbingNormal * -1
      local BaseRoatation = UE.UKismetMathLibrary.MakeRotFromX(PlayerForward)
      BaseRoatation.Pitch = BaseRoatation.Pitch + self.ClimbStartPitchOffset
      self:OnResetRotation(self.ClimbStartPitch_LerpSpeed, 2, BaseRoatation, true)
    end
  end
end

function BP_RocoCameraControlComponent_C:ClearStatus()
  self._playerStartRunTime = nil
  self._needLerpPitchAngle = false
  self._needLerpYaw = false
  self._needApplySlopeOffset = false
  self._lastPlayerLocation = nil
  self._startMoveTime = nil
  self._slopeCurrentAngle = 0
  self._slopeEnterSlopeStartTime = nil
end

function BP_RocoCameraControlComponent_C:OnResetRotation(ResetSpeed, ErrorTolerance, RotationOverride, InterruptByInput)
  self._resetRotation = true
  self._resetRotationSpeed = ResetSpeed or 5
  self._resetTolerance = ErrorTolerance or 2
  self._resetRotationOverride = RotationOverride or self._currentPawn:K2_GetActorRotation()
  self._resetInterruptByInput = InterruptByInput or false
end

function BP_RocoCameraControlComponent_C:OnStopResetRotation()
  self._resetRotation = false
  self._resetInterruptByInput = false
end

local CheckRunningVelocityCache = UE4.FVector()

function BP_RocoCameraControlComponent_C:CheckRunning()
  self:RefreshCameraStatusParam()
  if self._currentPawn == nil or nil == self._currentPawn.GetVelocity or not UE4.UObject.IsValid(self._currentPawn) then
    return
  end
  UE4.UNRCStatics.GetVelocityInplace(self._currentPawn, CheckRunningVelocityCache)
  local Velocity = CheckRunningVelocityCache
  if nil == Velocity then
    return
  end
  local speed = Velocity:Size()
  if speed > 300 or self._isClimbing and speed > 50 then
    if not self._playerStartRunTime then
      self._playerStartRunTime = LocalUE4Helper.GetTime()
    end
  elseif self._playerStartRunTime then
    self._playerStartRunTime = nil
    self._needApplySlopeOffset = false
    self._needLerpPitchAngle = false
    self._needLerpYaw = false
  end
end

function BP_RocoCameraControlComponent_C:RefreshCameraStatusParam()
  if not self:GetScenePlayer() then
    return
  end
  if not self:GetScenePlayer().statusComponent then
    return
  end
  if not NRCEnv:IsLocalMode() and _G.DialogueModuleCmd and _G.NRCModuleManager:GetModule(_G.NRCModuleManager.moduleCmdDict[_G.DialogueModuleCmd.HasDialogue]) and not _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) and not self:GetScenePlayer().statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_BATTLE) then
    local springArmComponent = self:GetSpringArmComponent()
    if springArmComponent then
      springArmComponent.TickStateType = "[BP_RocoCameraControlComponent_C:RefreshCameraStatusParam] DefaultCamera"
    end
  end
end

local TickCheckParamsPlayerLocationCache = UE4.FVector()
local TickCheckParamsMoveDirectionCache = UE4.FVector()
local TickCheckParamsControlRotationCache = UE4.FRotator()

function BP_RocoCameraControlComponent_C:TickCheckParams(DeltaSeconds)
  local curUE4Time = LocalUE4Helper.GetTime()
  if self._ueCtrl and UE4.UObject.IsValid(self._currentPawn) then
    self:CheckRunning()
    if self._playerStartRunTime and curUE4Time - self._playerStartRunTime >= self.PitchAngle_FixedAfterRunTime then
      self._needLerpPitchAngle = true
    end
    if self._playerStartRunTime and curUE4Time - self._playerStartRunTime >= self.Yaw_FixedAfterRunTime then
      self._needLerpYaw = true
    end
    if self._isClimbing then
      if math.abs(self._currentPawn:GetVelocity().Z) < 10 then
        self._needLerpPitchAngle = false
      end
      if self._playerStartRunTime and math.abs(self._currentPawn:GetVelocity().Z) > 70 then
        self._needLerpYaw = false
      end
      if self._currentPawn:GetMovementComponent():IsClimbUpLedge() then
        if false == self._isClimbUpLedge and not self._isControllingView then
          self:OnResetRotation(self.ClimbEndPitch_LerpSpeed, nil, nil, true)
        end
        self._isClimbUpLedge = true
      else
        self._isClimbUpLedge = false
      end
    else
      self._isClimbUpLedge = false
    end
    local MoveDistanceSqr, MoveDistanceSqrIgnoreZ
    UE4.UNRCStatics.Abs_K2_GetActorLocationInplace(self._currentPawn, TickCheckParamsPlayerLocationCache)
    local PlayerLocation = TickCheckParamsPlayerLocationCache
    local MoveDirection
    if self._lastPlayerLocation then
      PlayerLocation:SubInto(self._lastPlayerLocation, TickCheckParamsMoveDirectionCache)
      MoveDirection = TickCheckParamsMoveDirectionCache
    end
    if MoveDirection then
      MoveDirection.Z = 0
      MoveDistanceSqrIgnoreZ = MoveDirection.X * MoveDirection.X + MoveDirection.Y * MoveDirection.Y
      MoveDistanceSqr = MoveDistanceSqrIgnoreZ + MoveDirection.Z * MoveDirection.Z
    end
    self._lastPlayerLocationVariableCache:Set(PlayerLocation.X, PlayerLocation.Y, PlayerLocation.Z)
    self._lastPlayerLocation = self._lastPlayerLocationVariableCache
    local DeltaSecondsSqr = DeltaSeconds * DeltaSeconds
    if MoveDistanceSqr and MoveDistanceSqr > 900 * DeltaSecondsSqr then
      if self._startMoveTime then
      else
        self._startMoveTime = LocalUE4Helper.GetTime()
      end
    elseif self._startMoveTime then
      self:ClearStatus()
    end
    self._moveVectorFromViewForward = nil
    self._moveLocationDirection = nil
    if self._needLerpYaw and MoveDistanceSqrIgnoreZ and MoveDistanceSqrIgnoreZ > 900 * DeltaSecondsSqr then
      local Rotation = self._ueCtrl:GetControlRotation()
      Rotation:Set(0, Rotation.Yaw, 0)
      local ForwardVector = Rotation:ToVector()
      local PlayerVelocity = self._currentPawn:GetVelocity()
      if self._currentPawn.RidePet and PlayerVelocity:Size() < 0.1 then
        PlayerVelocity = self._currentPawn.RidePet:GetVelocity()
      end
      if not (not ForwardVector or self:CheckMoveDirectionInYawIgnoreRange(PlayerVelocity, ForwardVector)) or self._isClimbing then
        local TempTransform = LocalUE4.UKismetMathLibrary.Conv_RotatorToTransform(LocalUE4.UKismetMathLibrary.Conv_VectorToRotator(PlayerVelocity))
        local localDir = LocalUE4.UKismetMathLibrary.InverseTransformDirection(TempTransform, ForwardVector)
        self._moveVectorFromViewForward = localDir
        self._moveLocationDirectionVariableCache:Set(MoveDirection.X, MoveDirection.Y, MoveDirection.Z)
        self._moveLocationDirection = self._moveLocationDirectionVariableCache
      end
    end
    local needResetSlopeAngle = true
    self._needApplySlopeOffset = false
    if nil == self._slopeCurrentAngle then
      self._slopeCurrentAngle = self:ConvertPitchToAngle(self._ueCtrl:GetControlRotation().Pitch) - self.DefaultPitchAngle
    end
    if self._needLerpPitchAngle then
      if self._isClimbing then
        needResetSlopeAngle = false
        self._needApplySlopeOffset = true
        self._slopeCurrentAngle = self.ClimbPitchAngle_MinDown
        if self._currentPawn:GetVelocity().Z > 0 then
          self._slopeCurrentAngle = self.ClimbPitchAngle_MaxUp
        end
      else
        local movementComponent = self._currentPawn:GetMovementComponent()
        if not movementComponent then
          Log.Error("movementComponent\229\164\177\232\184\170\228\186\134")
          return
        end
        local floorAngle = math.abs(movementComponent.SlopeAngle)
        if floorAngle > self.Slope_MinStartSlopeAngle then
          needResetSlopeAngle = false
          local targetAngle = floorAngle * self.Slope_Ratio / 100
          local floorNormal = movementComponent.CurrentFloor.HitResult.Normal
          local cameraDir = UE4.UKismetMathLibrary.GetForwardVector(self._currentPawn:GetController().PlayerCameraManager:GetCameraRotation())
          cameraDir.Z = 0
          local isFaceUp = 1
          if UE4.UKismetMathLibrary.Dot_VectorVector(floorNormal, cameraDir) > 0 then
            isFaceUp = -1
          end
          self._slopeDeltaPitchAngle = targetAngle * isFaceUp
          self._slopeCurrentAngle = LuaMathUtils.LerpWithLength(self._slopeCurrentAngle, self._slopeDeltaPitchAngle, self.Slope_ChangeSpeed * DeltaSeconds)
          self._needApplySlopeOffset = true
        end
      end
    end
    if needResetSlopeAngle then
      UE4.UNRCStatics.GetControlRotationFromControllerInplace(self._ueCtrl, TickCheckParamsControlRotationCache)
      self._slopeCurrentAngle = self:ConvertPitchToAngle(TickCheckParamsControlRotationCache.Pitch) - self.DefaultPitchAngle
    end
  end
end

function BP_RocoCameraControlComponent_C:CheckMoveDirectionInYawIgnoreRange(MoveDirection, ForwardVector)
  if self.Yaw_IgnoreAngle ~= nil and 0 ~= self.Yaw_IgnoreAngle then
    MoveDirection.Z = 0
    MoveDirection:Normalize()
    local cosValue = LocalUE4.FVector.Dot(MoveDirection, ForwardVector)
    if cosValue < self._minDirCos or cosValue > self._maxDirCos then
      return true
    end
  end
  return false
end

local TickLerpRotationCache = UE4.FRotator()

function BP_RocoCameraControlComponent_C:TickLerp(DeltaSeconds)
  if not self._ueCtrl then
    return
  end
  if self._ueCtrl.IsCameraControlDisabled and self._ueCtrl:IsCameraControlDisabled() then
    return
  end
  UE4.UNRCStatics.GetControlRotationFromControllerInplace(self._ueCtrl, TickLerpRotationCache)
  local Rotation = TickLerpRotationCache
  if self._resetRotation then
    local TargetRotation = self._resetRotationOverride
    if not UE4.UKismetMathLibrary.NotEqual_RotatorRotator(Rotation, TargetRotation, self._resetTolerance) then
      self._currentPawn.sceneCharacter.inputComponent:SetCameraControlEnable(self, true, "ResetCameraRotation")
      self._resetRotation = false
      self._resetRotationOverride = nil
      return
    end
    if self._resetInterruptByInput then
      if self._isControllingView then
        self:OnStopResetRotation()
        return
      end
    else
      self._currentPawn.sceneCharacter.inputComponent:SetCameraControlEnable(self, false, "ResetCameraRotation")
    end
    Rotation = UE4.UKismetMathLibrary.RInterpTo(Rotation, TargetRotation, DeltaSeconds, self._resetRotationSpeed)
    self._ueCtrl:SetControlRotation(Rotation)
    return
  end
  if self._moveVectorFromViewForward then
    if self._isClimbing then
      local WallNormal = self._currentPawn:GetMovementComponent().CurrentClimbingNormal
      WallNormal.Z = 0
      WallNormal:Normalize()
      local WallYaw = UE.UKismetMathLibrary.MakeRotFromX(WallNormal).Yaw
      if WallYaw < 0 then
        WallYaw = WallYaw + 360
      end
      if nil == self._LastWallYaw then
        self._LastWallYaw = WallYaw
      end
      if math.abs(WallYaw - self._LastWallYaw) > self.ClimbYawAngle_LimitIgnore then
        self._LastWallYaw = WallYaw
      end
      WallYaw = self._LastWallYaw
      WallYaw = WallYaw + 180
      if WallYaw > 360 then
        WallYaw = WallYaw - 360
      end
      local CameraYawDelta = Rotation.Yaw - WallYaw
      if CameraYawDelta < -180 then
        CameraYawDelta = CameraYawDelta + 360
      end
      if CameraYawDelta > 180 then
        CameraYawDelta = CameraYawDelta - 360
      end
      local isRight = 1
      if CameraYawDelta < 0 then
        isRight = -1
      end
      if math.abs(CameraYawDelta) > self.ClimbYawAngle_Limit then
        CameraYawDelta = math.abs(CameraYawDelta) - self.ClimbYawAngle_LerpSpeed * DeltaSeconds
        CameraYawDelta = CameraYawDelta * isRight
        if math.abs(CameraYawDelta) < self.ClimbYawAngle_Limit then
          CameraYawDelta = self.ClimbYawAngle_Limit * isRight
        end
      else
        local ratio = self._moveVectorFromViewForward.Y < 0 and 1 or -1
        CameraYawDelta = CameraYawDelta + ratio * self.ClimbYawAngle_LerpSpeed * DeltaSeconds
        if math.abs(CameraYawDelta) > self.ClimbYawAngle_Limit then
          CameraYawDelta = self.ClimbYawAngle_Limit * isRight
        end
      end
      Rotation.Yaw = LocalUE4.UKismetMathLibrary.ClampAxis(WallYaw + CameraYawDelta)
    else
      local ratio = self._moveVectorFromViewForward.Y < 0 and 1 or -1
      local OriPitchAngle = self:ConvertPitchToAngle(Rotation.Pitch)
      Rotation.Yaw = Rotation.Yaw + ratio * (self.Yaw_MoveSpeed + self.Yaw_PitchRatio * math.abs(OriPitchAngle)) * DeltaSeconds
      Rotation.Yaw = LocalUE4.UKismetMathLibrary.ClampAxis(Rotation.Yaw)
    end
  end
  if self._needLerpPitchAngle and GlobalConfig.AutoCamera then
    local TargetPitchAngle = self:ConvertPitchToAngle(self.DefaultPitchAngle)
    if self._isClimbing then
      local WallNormal = self._currentPawn:GetMovementComponent().CurrentClimbingNormal
      local CosAngle = UE.UKismetMathLibrary.Dot_VectorVector(WallNormal, UE.FVector(0, 0, 1))
      TargetPitchAngle = UE.UKismetMathLibrary.DegAcos(CosAngle) - 90
    end
    if self._needApplySlopeOffset then
      TargetPitchAngle = TargetPitchAngle + self._slopeCurrentAngle
    end
    local OriPitchAngle = self:ConvertPitchToAngle(Rotation.Pitch)
    local PitchAngle = 0
    if self._isClimbing then
      PitchAngle, self._PitchAngleSpeed = LuaMathUtils.CriticalSpringDamper(TargetPitchAngle, self._PitchAngleSpeed, OriPitchAngle, DeltaSeconds, self.ClimbPitchAngle_LerpSpeed, 10)
    else
      PitchAngle, self._PitchAngleSpeed = LuaMathUtils.CriticalSpringDamper(TargetPitchAngle, self._PitchAngleSpeed, OriPitchAngle, DeltaSeconds, self.PitchAngle_LerpSpeed, 10)
    end
    if math.abs(OriPitchAngle - TargetPitchAngle) > 1 then
      Rotation.Pitch = PitchAngle
    else
      self._needLerpPitchAngle = false
    end
  else
    self._PitchAngleSpeed = 0
  end
  self._ueCtrl:SetControlRotation(Rotation)
end

function BP_RocoCameraControlComponent_C:ConvertPitchToAngle(Pitch)
  if Pitch > 270 then
    return Pitch - 360
  end
  return Pitch
end

function BP_RocoCameraControlComponent_C:ConvertAngleToPitch(Angle)
  if Angle < 0 then
    return Angle + 360
  end
  return Angle
end

function BP_RocoCameraControlComponent_C:EnableLag(enable)
  local springArmComponent = self:GetSpringArmComponent()
  if springArmComponent then
    springArmComponent.bEnableCameraLag = enable
    springArmComponent.bEnableCameraRotationLag = enable
  end
end

function BP_RocoCameraControlComponent_C:UpdateCameraPosition()
  local springArmComponent = self:GetSpringArmComponent()
  if springArmComponent then
    springArmComponent.PawnController = self._currentPawn:GetController()
    springArmComponent:UpdateSpringArmAndCamCache(1)
  end
end

function BP_RocoCameraControlComponent_C:GetSpringArmComponent()
  if self.BP_RocoSpringArmComponent then
    return self.BP_RocoSpringArmComponent
  end
  return nil
end

return BP_RocoCameraControlComponent_C

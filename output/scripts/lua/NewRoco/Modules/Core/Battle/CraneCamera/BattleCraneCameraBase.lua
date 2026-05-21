local BattleCraneCameraBase = NRCClass()
local BattleCraneCameraData = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraData")
local BattleCraneCameraEvent = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")

function BattleCraneCameraBase:Ctor()
end

function BattleCraneCameraBase:Construct()
  self.confData = BattleCraneCameraData()
  self.KontrolEnabled = false
  BattleResourceManager:LoadResAsync(self, BattleConst.HandheldShake, self.LoadShakeClassOver)
  self.IsShake = false
end

function BattleCraneCameraBase:CalCameraBaseInfo(TargetType1, TargetType2, SpringArmRotation, SpringArmOffset, SpringArmLength, Fov, CameraCurveEnum)
  self.confData:CalcBaseRotation()
  self:ChangeCamParent(false)
  self.curFov = Fov
  self.FOV = self.curFov
  self.CurSprintArmRotation = self.confData:CalcBaseSpringArmRot(SpringArmRotation)
  if not self.SpringArmComponent or not self.CameraComponent then
    self:InitCameraFromBattleField()
  end
  if not _G.NRCEditorEntranceEnable and not self.SpringArmComponent then
    Log.Warning("self.SpringArmComponent is nil", "CameraActor=", self.CameraActor, "cameraComponent=", self.CameraComponent)
    return false
  end
  self.confData:CalcBaseLookPos(TargetType1, TargetType2, SpringArmOffset)
  if not self.confData.targetPos1 then
    Log.Error("targetPos1\230\149\176\230\141\174\233\148\153\232\175\175,\230\136\152\229\156\186\230\149\176\230\141\174vBattleField:GetBattleFieldCenter\230\156\137\233\151\174\233\162\152TargetType1, TargetType2,=", TargetType1, TargetType2)
    return
  end
  if not self.confData.targetPos2 then
    Log.Error("targetPos2\230\149\176\230\141\174\233\148\153\232\175\175,\230\136\152\229\156\186\230\149\176\230\141\174vBattleField:GetBattleFieldCenter\230\156\137\233\151\174\233\162\152TargetType1, TargetType2,=", TargetType1, TargetType2)
    return
  end
  local CurLookPos = self.confData:CalcCurLookPosByRatio(self.confData:GetCurPointRatio())
  self.curLookPos = UE4.FVector(CurLookPos.X, CurLookPos.Y, CurLookPos.Z)
  self.CurPointRatio = 0.5
  self.CurSpringArmLength = SpringArmLength
  self.curCameraRotation = FRotatorZero
  self.curCameraLocation = FVectorZero
  self.confData:LoadTargetCameraCurve(CameraCurveEnum)
  self:CheckSpringCollision()
  return true
end

function BattleCraneCameraBase:SetCameraBaseInfo(InG6Editor, CurveForce)
  if not self.CameraBlendFunc or CurveForce then
    self.CameraComponent.FieldOfView = self.FOV
    self:SetCameraActorLocation(self.curLookPos)
    self:SetSpringArmRotAndLength(self.CurSprintArmRotation, self.CurSpringArmLength)
    self:SetCamComponentLocation(FRotatorZero, FVectorZero)
    if not InG6Editor then
      _G.BattleCraneCameraHost.InitCameraForRotation()
    end
    self:TryInitBaseCamRelativeRot()
  end
end

function BattleCraneCameraBase:CheckSpringCollision()
  if _G.NRCEditorEntranceEnable then
    self.SpringArmComponent.bDoCollisionTest = false
    return
  end
  if BattleUtils.IsBeastTeam() or BattleUtils.IsBloodTeam() then
    self.SpringArmComponent.bDoCollisionTest = false
  else
    self.SpringArmComponent.bDoCollisionTest = true
  end
end

function BattleCraneCameraBase:GetLookPosAdditional()
  if self.CameraActor then
    local CurLookPos = self.CameraActor:Abs_K2_GetActorLocation()
    local BaseLookPos = self.confData:GetBaseLookPos()
    return BaseLookPos - CurLookPos
  end
end

function BattleCraneCameraBase:GetSpringArmRotationAdditional()
  if self.SpringArmComponent then
    local curRot = self.SpringArmComponent:K2_GetComponentRotation()
    local BaseLookPos = self.confData:GetBaseSpringArmRotation()
    return BaseLookPos - curRot
  else
    return FRotatorZero
  end
end

function BattleCraneCameraBase:SetCameraActorLocation(LookPos)
  if UE4.UObject.IsValid(self.CameraActor) then
    local camTransform = UE4.UKismetMathLibrary.MakeTransform(LookPos, _G.FRotatorZero, UE4.FVector(1, 1, 1))
    self.CameraActor:Abs_K2_SetActorTransform_WithoutHit(camTransform, false, false)
  end
end

function BattleCraneCameraBase:SetSpringArmRotAndLength(Rotation, Length)
  if UE4.UObject.IsValid(self.SpringArmComponent) then
    self.SpringArmComponent:K2_SetWorldRotation(Rotation, false, nil, false)
    self.SpringArmComponent.TargetArmLength = Length
  end
end

function BattleCraneCameraBase:SetCamComponentLocation(Rotation, Location)
  if UE4.UObject.IsValid(self.CameraComponent) then
    self.CameraComponent:K2_SetRelativeRotation(Rotation, false, nil, false)
    self.CameraComponent:K2_SetRelativeLocation(Location, false, nil, false)
  end
end

function BattleCraneCameraBase:Init(conf)
  self.conf = conf
  self.PlayerNearPos = conf.BattleFieldAttachPointMap:Find(UE4.EBattleFieldAttachPoint.Pos_Round_Prepare_Player1)
  self.PlayerFarPos = conf.BattleFieldAttachPointMap:Find(UE4.EBattleFieldAttachPoint.Pos_Player1)
  self.PlayerController = _G.UE4Helper.GetPlayerCharacter(0):GetController()
  self.PlayerCameraManager = self.PlayerController.PlayerCameraManager
  self.CurrentAnimID = 0
end

function BattleCraneCameraBase:InitCameraFromBattleField()
  local CameraActor = _G.BattleManager:GetCraneCamera()
  self:InitCameraComponent(CameraActor)
end

function BattleCraneCameraBase:InitPanelCameraController(CameraActor)
  local panelCameraController = _G.BattleManager.vBattleField.panelCameraController
  if not panelCameraController or not UE4.UObject.IsValid(panelCameraController) then
    return
  end
  local HitComps = CameraActor:GetComponentsByTag(UE4.USceneComponent, "PanelControllerCom")
  if HitComps:Length() > 0 then
    local PanelControllerCom = HitComps:Get(1)
    panelCameraController:K2_AttachToComponent(PanelControllerCom, "None", UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, true)
  end
end

function BattleCraneCameraBase:InitCameraComponent(CameraActor)
  self.CameraActor = CameraActor
  self.PCGCam = self.CameraActor
  if self.CameraActor and UE.UObject.IsValid(self.CameraActor) then
    self.CameraComponent = self.CameraActor:GetComponentByClass(UE4.UCameraComponent)
    self:InitPanelCameraController(CameraActor)
    self.SpringArmComponent = self.CameraActor:GetComponentByClass(UE4.URocoSpringArmComponent)
    self.SpringArmComponent.bInheritRoll = true
  end
end

function BattleCraneCameraBase:LoadShakeClassOver(res)
  self.ShakeClass = res
  self.ShakeClassRef = res and UnLua.Ref(res)
  self:TryStartShake()
end

function BattleCraneCameraBase:EnableShake()
  self.isEnableShake = true
end

function BattleCraneCameraBase:DisableShake()
  self.isEnableShake = false
end

function BattleCraneCameraBase:StartShake()
  if not self.isEnableShake then
    return
  end
  if self.HandheldShakeInstance then
    return
  end
  self.IsShake = true
  self:TryStartShake()
end

function BattleCraneCameraBase:TryStartShake()
  if self.IsShake then
    local ShakeClass = self.ShakeClass
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and ShakeClass then
      self.HandheldWaterShakeInstance = BattleUtils.SafeCallUObject(self.PlayerCameraManager, "StartCameraShake", ShakeClass, 1, UE4.ECameraShakePlaySpace.CameraLocal)
    end
  end
end

function BattleCraneCameraBase:StopShake(immediately)
  if not self.HandheldShakeInstance then
    return
  end
  Log.Debug("Stop Camera Shake...", self.HandheldShakeInstance)
  self.IsShake = false
  self:TryStopShake()
end

function BattleCraneCameraBase:TryStopShake()
  if not self.IsShake then
    BattleUtils.SafeCallUObject(self.PlayerCameraManager, "StopCameraShake", self.HandheldWaterShakeInstance, immediately)
    self.HandheldWaterShakeInstance = nil
  end
end

function BattleCraneCameraBase:StartWaterShake()
  if not self.PlayerCameraManager then
    return
  end
  BattleResourceManager:LoadResAsync(self, BattleConst.HandheldWaterShake, self.OnClassLoad)
end

function BattleCraneCameraBase:OnClassLoad(ShakeClass)
  if not ShakeClass then
    return
  end
  Log.Debug("Start Camera WaterShake...")
  self.HandheldWaterShakeInstance = BattleUtils.SafeCallUObject(self.PlayerCameraManager, "StartCameraShake", ShakeClass, 1, UE4.ECameraShakePlaySpace.CameraLocal)
end

function BattleCraneCameraBase:StopWaterShake(immediately)
  if not self.HandheldWaterShakeInstance then
    return
  end
  Log.Debug("Stop Camera WaterShake...", self.HandheldWaterShakeInstance)
  BattleUtils.SafeCallUObject(self.PlayerCameraManager, "StopCameraShake", self.HandheldWaterShakeInstance, immediately)
  self.HandheldWaterShakeInstance = nil
end

function BattleCraneCameraBase:ModifyCameraPitchAnglePlus(value)
  self.CurSprintArmRotation.Pitch = self.CurSprintArmRotation.Pitch + value
end

function BattleCraneCameraBase:ModifyCameraYawAnglePlus(value)
  self.CurSprintArmRotation.Yaw = self.CurSprintArmRotation.Yaw + value
end

function BattleCraneCameraBase:ModifyCameraRollAnglePlus(value)
  self.CurSprintArmRotation.Roll = self.CurSprintArmRotation.Roll + value
end

function BattleCraneCameraBase:Destruct()
  self.CameraActor = nil
  self.CameraComponent = nil
  self.SpringArmComponent = nil
  self.confData = nil
  self.ShakeClass = nil
  self.ShakeClassRef = nil
  self.PlayerCameraManager = nil
end

function BattleCraneCameraBase:InitCameraInfo(Fov, AspectR, Constrain)
  if self.CameraComponent then
    self.CameraComponent.FieldOfView = Fov
    self.CameraComponent.AspectRatio = AspectR
    self.CameraComponent.bConstrainAspectRatio = Constrain
  end
end

function BattleCraneCameraBase:ModifySpringArmLengthPlus(value)
  self.CurSpringArmLength = self.CurSpringArmLength + value
end

function BattleCraneCameraBase:ModifySpringArmRotation(TXOff, TYOff, DeltaXScaled, DeltaYScaled)
  if self.IsAidCameraOpen and self:IsControlEnabled() then
    self:ModifySpringArmRotationWithAidCam(TXOff, TYOff, DeltaXScaled, DeltaYScaled)
    BattleCraneCameraHost.SendInputParamToUmg()
    BattleCraneCameraHost.SendCameraParamToUmg()
    BattleCraneCameraHost.SendCameraAdditionalToUmg()
  end
end

function BattleCraneCameraBase:ModifySpringArmRotationWithCraneCam(TXOff, TYOff, DeltaXScaled, DeltaYScaled)
  self.SpringArmXOffset = TXOff
  self.SpringArmYOffset = TYOff
  local curSprintArmRotation = self.SpringArmComponent:K2_GetComponentRotation()
  local rot = UE4.FRotator(curSprintArmRotation.Pitch - DeltaYScaled, curSprintArmRotation.Yaw + DeltaXScaled, curSprintArmRotation.Roll)
  self.SpringArmComponent:K2_SetRelativeRotation(rot, false, nil, false)
  BattleCraneCameraHost.SendInputParamToUmg()
  BattleCraneCameraHost.SendCameraParamToUmg()
end

function BattleCraneCameraBase:ModifySpringArmRotationWithAidCam(TXOff, TYOff, DeltaXScaled, DeltaYScaled)
  local GetAidRotationCam = _G.BattleManager:GetAidRotationCam()
  if GetAidRotationCam then
    self.lastCamComRotForCollision = self.CameraComponent:Abs_K2_GetComponentLocation()
    local SpringArmComponent_2 = GetAidRotationCam:GetComponentByClass(UE4.URocoSpringArmComponent)
    local curSprintArmRotation = SpringArmComponent_2:K2_GetComponentRotation()
    local rot = UE4.FRotator(curSprintArmRotation.Pitch - DeltaYScaled, curSprintArmRotation.Yaw + DeltaXScaled, curSprintArmRotation.Roll)
    SpringArmComponent_2:K2_SetRelativeRotation(rot, false, nil, false)
    if self:CheckIsCollisionLand() then
      SpringArmComponent_2:K2_SetRelativeRotation(curSprintArmRotation, false, nil, false)
    else
      self.SpringArmXOffset = TXOff
      self.SpringArmYOffset = TYOff
    end
  else
    Log.Error("BattleCraneCameraBase:ModifySpringArmRotationWithAidCam  GetAidRotationCam is nil")
    return
  end
  self:UpdateCamRelativeRot()
  local CameraComponent = self.CameraComponent
  local Rot1 = CameraComponent:K2_GetComponentRotation()
  local newRot = UE4.FRotator(Rot1.Pitch, Rot1.Yaw, 0)
  CameraComponent:K2_SetWorldRotation(newRot, false, nil, false)
end

function BattleCraneCameraBase:ModifyLookPosPlus(Value)
  self.confData:ModifyCurLookPos(0, 0, Value)
  self.curLookPos = self.confData:GetCurLookPos()
end

function BattleCraneCameraBase:ModifyCameraFovPlus(value)
  self.curFov = self.curFov + value
  self.FOV = self.curFov
end

function BattleCraneCameraBase:ModifyPointRatio(value)
  self.CurPointRatio = self.CurPointRatio + value
  self.CurPointRatio = math.min(self.CurPointRatio, 1)
  self.CurPointRatio = math.max(self.CurPointRatio, 0)
  local camTransform = self.confData:SetPointRatio(self.CurPointRatio)
  self.curLookPos = self.confData:GetCurLookPos()
end

function BattleCraneCameraBase:GetSpringCameraEndLocation()
  local CameraActorPos = self.curLookPos
  local ArmRot = self.CurSprintArmRotation
  ArmRot:Normalize()
  local result
  local curCamTag = self.confData:GetCurCameraTag()
  if _G.NRCEditorEntranceEnable and curCamTag == UE4.EBattleCameraTags.A1FBPerformSkill then
    result = CameraActorPos - ArmRot:ToVector() * 2800
    result.Z = result.Z + 300
  else
    result = CameraActorPos - ArmRot:ToVector() * self.CurSpringArmLength
  end
  return result
end

function BattleCraneCameraBase:Abs_GetSpringCameraEndLocation()
  if not self.CameraActor then
    Log.Error("BattleCraneCameraBase:Abs_GetSpringCameraEndLocation, \230\136\152\230\150\151\231\155\184\230\156\186\228\184\186\231\169\186\239\188\140\231\155\184\230\156\186\229\183\178\232\162\171\233\148\128\230\175\129\239\188\140\230\136\152\229\156\186\228\184\141\229\173\152\229\156\168\239\188\140\230\163\128\230\159\165\233\128\187\232\190\145\228\184\141\229\186\148\232\175\165\229\156\168\230\136\152\229\156\186\228\185\139\229\164\150\228\189\191\231\148\168\230\136\152\229\156\186\231\155\184\230\156\186\233\128\187\232\190\145")
    return nil
  end
  local CameraActorPos = self.CameraActor:K2_GetActorLocation()
  local ArmRot = self.CurSprintArmRotation
  ArmRot:Normalize()
  local result = CameraActorPos - ArmRot:ToVector() * self.CurSpringArmLength
  return result
end

function BattleCraneCameraBase:GetCamComponentTransform()
  local location = self:Abs_GetSpringCameraEndLocation()
  local camTransform
  if not location then
    Log.Error("BattleCraneCameraBase:GetCamComponentTransform, \230\136\152\230\150\151\231\155\184\230\156\186\228\184\186\231\169\186\239\188\140\231\155\184\230\156\186\229\183\178\232\162\171\233\148\128\230\175\129\239\188\140\230\136\152\229\156\186\228\184\141\229\173\152\229\156\168\239\188\140\230\163\128\230\159\165\233\128\187\232\190\145\228\184\141\229\186\148\232\175\165\229\156\168\230\136\152\229\156\186\228\185\139\229\164\150\228\189\191\231\148\168\230\136\152\229\156\186\231\155\184\230\156\186\233\128\187\232\190\145")
    camTransform = UE4.UKismetMathLibrary.MakeTransform(location, UE4.FRotator(0, 0, 0), UE4.FVector(1, 1, 1))
    return camTransform
  end
  if not self.CameraComponent then
    Log.Error("BattleCraneCameraBase:GetCamComponentTransform, \230\136\152\230\150\151\231\155\184\230\156\186\228\184\186\231\169\186\239\188\140\231\155\184\230\156\186self.CameraComponent\229\183\178\232\162\171\233\148\128\230\175\129\239\188\140\230\136\152\229\156\186\228\184\141\229\173\152\229\156\168\239\188\140\230\163\128\230\159\165\233\128\187\232\190\145\228\184\141\229\186\148\232\175\165\229\156\168\230\136\152\229\156\186\228\185\139\229\164\150\228\189\191\231\148\168\230\136\152\229\156\186\231\155\184\230\156\186\233\128\187\232\190\145")
    camTransform = UE4.UKismetMathLibrary.MakeTransform(location, UE4.FRotator(0, 0, 0), UE4.FVector(1, 1, 1))
    return camTransform
  end
  local rot = self.CameraComponent:K2_GetComponentRotation()
  camTransform = UE4.UKismetMathLibrary.MakeTransform(location, rot, UE4.FVector(1, 1, 1))
  return camTransform
end

function BattleCraneCameraBase:ModifySpringArmLengthByNewPos(NewPos)
  local CurLookPos = self.curLookPos
  local newArmLength = NewPos:Dist(CurLookPos)
  self.CurSpringArmLength = newArmLength
  local newRot = UE4.UKismetMathLibrary.FindLookAtRotation(NewPos, CurLookPos)
  newRot:Normalize()
  self.CurSprintArmRotation = newRot
end

function BattleCraneCameraBase:ModifyCameraComponentRot()
  local SprintArmEndPos = self:GetSpringCameraEndLocation()
  local rot = (self.curLookPos - SprintArmEndPos):ToRotator()
  self.CameraComponent:K2_SetWorldRotation(rot, false, nil, false)
end

function BattleCraneCameraBase:IsControlEnabled()
  return self.KontrolEnabled
end

function BattleCraneCameraBase:SetControlEnabled(enable)
  self.KontrolEnabled = enable
  if not enable then
    self.SetControlEnabledTimer = false
    self:ChangeCamParent(false, true)
  end
end

function BattleCraneCameraBase:RecordFormDataCameraByCurveParam()
  local Position = UE.FVector()
  local Rotation = UE.FRotator()
  local FOV
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerController = localPlayer:GetUEController()
  local curCamActor = playerController:GetViewTarget()
  if curCamActor then
    local curCamComponent = curCamActor:GetComponentByClass(UE4.UCameraComponent)
    if curCamComponent then
      Rotation = curCamComponent:K2_GetComponentRotation()
      Position = curCamComponent:K2_GetComponentLocation()
      FOV = curCamComponent.FieldOfView
      self.CameraComponent:K2_SetWorldLocationAndRotation(Position, Rotation, false, nil, false)
      self.CameraComponent.FieldOfView = FOV
      self.lastCameraComponentRotation = Rotation
      self.lastCameraComponentLocation = Position
      self.lastFov = FOV
    end
  end
end

function BattleCraneCameraBase:RestoreCameraFromData()
  if self.CameraComponent then
    self.CameraComponent:K2_SetWorldLocationAndRotation(self.lastCameraComponentLocation, self.lastCameraComponentRotation, false, nil, false)
    self.CameraComponent.FieldOfView = self.lastFov
  end
end

function BattleCraneCameraBase:ResetCameraByCurveBase()
  if not (self.CameraActor and UE4.UObject.IsValid(self.CameraActor) and self.SpringArmComponent and UE4.UObject.IsValid(self.SpringArmComponent) and self.CameraComponent) or not UE4.UObject.IsValid(self.CameraComponent) then
    return
  end
  self.lastLookPos = self.CameraActor:Abs_K2_GetActorLocation()
  self.lastSpringArmRotation = self.SpringArmComponent:K2_GetComponentRotation()
  self.lastTargetArmLength = self.SpringArmComponent.TargetArmLength
  local lastCameraRelativeTrans = self.CameraComponent:GetRelativeTransform()
  self.lastCameraComponentRotation = lastCameraRelativeTrans.Rotation:ToRotator()
  self.lastCameraComponentLocation = UE4.FVector(lastCameraRelativeTrans.Translation.X, lastCameraRelativeTrans.Translation.Y, lastCameraRelativeTrans.Translation.Z)
  self.lastFov = self.CameraComponent.FieldOfView
end

function BattleCraneCameraBase:SprintCameraErrorInfo(type, paramL, paramR)
  Log.Warning("type=", type, "paramL=", paramL, "paramR=", paramR, "CameraActor=", self.CameraActor, "CameraComponent=", self.CameraComponent, "SpringArmComponent=", self.SpringArmComponent)
end

function BattleCraneCameraBase:OnTick(DeltaTime)
  if not (self.CameraBlendFunc and self.BlendDuration) or 0 == self.BlendDuration then
    return
  end
  if self.lastTime and self.lastTime + DeltaTime <= self.BlendDuration then
    self.lastTime = self.lastTime + DeltaTime
    local ratio = self.lastTime / self.BlendDuration
    if self.cameraBlendParam then
      self:CameraCurveMove(ratio)
    else
      self:CameraLinearMove(ratio)
    end
  else
    self:BlendFuncFinish()
  end
end

function BattleCraneCameraBase:LerpWithVector(Start, End, Alpha)
  local StartForwardVector = End - Start
  StartForwardVector:Normalize()
  
  local function CrossProduct(A, B)
    return UE4.FVector(A.Y * B.Z - A.Z * B.Y, A.Z * B.X - A.X * B.Z, A.X * B.Y - A.Y * B.X)
  end
  
  local StartRightVector = CrossProduct(UE4Helper.UpVector, StartForwardVector)
  StartRightVector:Normalize()
  local StartUpVector = CrossProduct(StartForwardVector, StartRightVector)
  StartUpVector:Normalize()
  local CurrentPositionBase = Start + (End - Start) * Alpha.X
  local AdditiveAmountY = StartRightVector * Alpha.Y
  local AdditiveAmountZ = StartUpVector * Alpha.Z
  local AdditiveAmount = AdditiveAmountY + AdditiveAmountZ
  return CurrentPositionBase + AdditiveAmount
end

function BattleCraneCameraBase:LerpWithRotator(A, B, AlphaVector)
  local retRotator = UE4.FRotator()
  retRotator.Roll = _G.LuaMathUtils.LerpWithAlpha(A.Roll, B.Roll, AlphaVector.X)
  retRotator.Pitch = _G.LuaMathUtils.LerpWithAlpha(A.Pitch, B.Pitch, AlphaVector.Y)
  retRotator.Yaw = _G.LuaMathUtils.LerpWithAlpha(A.Yaw, B.Yaw, AlphaVector.Z)
  return retRotator
end

function BattleCraneCameraBase:CameraCurveMove(MoveFraction)
  local CurveData = self.cameraBlendParam
  local LerpVector = UE4.FVector(MoveFraction, MoveFraction, MoveFraction)
  local RotatorVector = UE4.FVector(MoveFraction, MoveFraction, MoveFraction)
  local FovLerpValue = MoveFraction
  if 0 == CurveData.MoveAxis then
    if CurveData.TweenCurveVector then
      LerpVector = CurveData.TweenCurveVector:GetVectorValue(MoveFraction)
    end
  elseif CurveData.TweenCurveFloat then
    local floatValue = CurveData.TweenCurveFloat:GetFloatValue(MoveFraction)
    LerpVector = UE4.FVector(floatValue, floatValue, floatValue)
  end
  if 0 == CurveData.MoveAxis1 then
    if CurveData.RotatorCurveVector then
      RotatorVector = CurveData.RotatorCurveVector:GetVectorValue(MoveFraction)
    end
  elseif CurveData.RotatorCurveFloat then
    local floatValue = CurveData.RotatorCurveFloat:GetFloatValue(MoveFraction)
    RotatorVector = UE4.FVector(floatValue, floatValue, floatValue)
  end
  if CurveData.FovCurveFloat then
    FovLerpValue = CurveData.FovCurveFloat:GetFloatValue(MoveFraction)
  end
  self.blendCameraState = true
  if not self.lastCameraComponentRotation or not self.curCameraRotation then
    return
  end
  if not self.lastCameraComponentLocation or not self.curCameraLocation then
    return
  end
  local cameraLoc = self:LerpWithVector(self.lastCameraComponentLocation, self.curCameraLocation, LerpVector)
  local cameraRot = self:LerpWithQuat(self.lastCameraComponentRotation, self.curCameraRotation, RotatorVector)
  local fov = _G.LuaMathUtils.LerpWithAlpha(self.lastFov, self.curFov, FovLerpValue)
  self.CameraComponent.FieldOfView = fov
  self.CameraComponent:K2_SetWorldLocationAndRotation(cameraLoc, cameraRot, false, nil, false)
end

function BattleCraneCameraBase:LerpWithQuat(rot1, rot2, RotatorVector)
  local delta = rot2 - rot1
  delta:Normalize()
  local interpRot = UE.FRotator()
  interpRot.Pitch = rot1.Pitch + RotatorVector.Y * delta.Pitch
  interpRot.Yaw = rot1.Yaw + RotatorVector.Z * delta.Yaw
  interpRot.Roll = rot1.Roll + RotatorVector.X * delta.Roll
  return interpRot
end

function BattleCraneCameraBase:CameraLinearMove(ratio)
  ratio = self.confData:GetRatioByCameraCurve(ratio)
  if not ratio then
    Log.Warning("BattleCraneCameraBase ratio is nil, self.BlendDuration = ", self.BlendDuration, "self.lastTime=", self.lastTime)
    ratio = 1
  end
  if not self.lastLookPos or not self.curLookPos then
    self:BlendFuncFinish()
    self:SprintCameraErrorInfo(1, self.lastLookPos, self.curLookPos)
    return
  end
  if not self.lastSpringArmRotation or not self.CurSprintArmRotation then
    self:BlendFuncFinish()
    self:SprintCameraErrorInfo(2, self.lastSpringArmRotation, self.CurSprintArmRotation)
    return
  end
  if not self.lastTargetArmLength or not self.CurSpringArmLength then
    self:SprintCameraErrorInfo(3, self.lastTargetArmLength, self.CurSpringArmLength)
    self:BlendFuncFinish()
    return
  end
  if not self.lastFov or not self.curFov then
    self:SprintCameraErrorInfo(4, self.lastFov, self.curFov)
    self:BlendFuncFinish()
    return
  end
  if not self.lastCameraComponentRotation or not self.curCameraRotation then
    self:SprintCameraErrorInfo(5, self.lastCameraComponentRotation, self.curCameraRotation)
    self:BlendFuncFinish()
    return
  end
  if not self.lastCameraComponentLocation or not self.curCameraLocation then
    self:SprintCameraErrorInfo(6, self.lastCameraComponentLocation, self.curCameraLocation)
    self:BlendFuncFinish()
    return
  end
  local lookPos = (self.curLookPos - self.lastLookPos) * ratio + self.lastLookPos
  local springArmRot = UE4.FQuat.Slerp(self.lastSpringArmRotation:ToQuat(), self.CurSprintArmRotation:ToQuat(), ratio):ToRotator()
  local springArmLen = _G.LuaMathUtils.LerpWithAlpha(self.lastTargetArmLength, self.CurSpringArmLength, ratio)
  local fov = _G.LuaMathUtils.LerpWithAlpha(self.lastFov, self.curFov, ratio)
  self.CameraComponent.FieldOfView = fov
  self.blendCameraState = true
  self:SetCameraActorLocation(lookPos)
  self:SetSpringArmRotAndLength(springArmRot, springArmLen)
  local cameraRot = UE4.FQuat.Slerp(self.lastCameraComponentRotation:ToQuat(), self.curCameraRotation:ToQuat(), ratio):ToRotator()
  local cameraLoc = (self.curCameraLocation - self.lastCameraComponentLocation) * ratio + self.lastCameraComponentLocation
  self:SetCamComponentLocation(cameraRot, cameraLoc)
end

function BattleCraneCameraBase:BlendFuncStart(BlendFunc, Duration)
  if not (self.CameraActor and self.SpringArmComponent) or not self.CameraComponent then
    return
  end
  self.lastTime = 0
  self.CameraBlendFunc = BlendFunc
  self.BlendDuration = Duration
end

function BattleCraneCameraBase:BlendFuncFinish()
  self:SetControlEnabled(true)
  self.CameraBlendFunc = nil
  self.blendCameraState = false
  self.lastTime = 0
  self.BlendDuration = 0
  if self.curLookPos then
    self:SetCameraActorLocation(self.curLookPos)
  end
  if self.CurSprintArmRotation and self.CurSpringArmLength then
    self:SetSpringArmRotAndLength(self.CurSprintArmRotation, self.CurSpringArmLength)
  end
  self:SetCamComponentLocation(FRotatorZero, FVectorZero)
  if self.curFov then
    self.CameraComponent.FieldOfView = self.curFov
  end
  _G.NRCEventCenter:DispatchEvent(BattleCraneCameraEvent.BlendFuncFinish)
  _G.BattleCraneCameraHost.InitCameraForRotation()
  self:TryInitBaseCamRelativeRot()
  _G.BattleCraneCameraHost.SendEnvParamToUmg()
  _G.BattleCraneCameraHost.SendInputParamToUmg()
  _G.BattleCraneCameraHost.SendCameraParamToUmg()
  _G.BattleCraneCameraHost.SendCameraAdditionalToUmg()
  self.confData:ClearCamCurveInfo()
end

function BattleCraneCameraBase:ChangeToSkill(DeltaTime, BlendFunc, Callback)
end

function BattleCraneCameraBase:ChangeCamera(Camera, DeltaTime, BlendFunc, Callback)
end

function BattleCraneCameraBase:StopAllShakes(immediately)
  Log.Debug("Stop All Camera Shakes...")
  BattleUtils.SafeCallUObject(self.PlayerCameraManager, "StopAllCameraShakes", immediately)
  self.HandheldShakeInstance = nil
  self.HandheldWaterShakeInstance = nil
end

function BattleCraneCameraBase:ClearCurrentCamera()
end

function BattleCraneCameraBase:ChangeToEnemy(DeltaTime, BlendFunc, Callback)
end

function BattleCraneCameraBase:SwitchCameraMode(mode)
  self.confData:SwitchCameraMode(mode)
end

return BattleCraneCameraBase

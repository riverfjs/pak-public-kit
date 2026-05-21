local BattleCraneCameraDefine = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraDefine")
local BattleCraneCameraHost = {}

function BattleCraneCameraHost.InitCameraBaseInfo()
  BattleCraneCameraHost.SendCameraCfgToUmg()
  BattleCraneCameraHost.SendEnvParamToUmg()
  BattleCraneCameraHost.SendInputParamToUmg()
  BattleCraneCameraHost.SendCameraParamToUmg()
  BattleCraneCameraHost.SendCameraAdditionalToUmg()
end

function BattleCraneCameraHost.SendEnvParamToUmg()
  if _G.RocoEnv.IS_EDITOR then
    local BattleCraneCamera = BattleManager.vBattleField.battleCraneCamera
    local info = BattleCraneCamera.confData:GetEnvParam()
    UE4.UCraneCameraEditorUserSettings.SendEnvParamToUmg(info.slope, info.slopeClamp, info.TeamPetHeight, info.TeamPetHeightClamp, info.EnemyPetHeight, info.EnemyPetHeightClamp, info.TeamEnemyRatio, info.TeamEnemyRatioClamp, info.DirectPitchAngle, info.DirectPitchAngleClamp, info.slope2, info.slope2Clamp, info.TeamPet1Pet2HeightRatio, info.TeamPet1Pet2HeightRatioClamp)
  end
end

function BattleCraneCameraHost.SendInputParamToUmg()
  if _G.RocoEnv.IS_EDITOR then
    local BattleCraneCamera = BattleManager.vBattleField.battleCraneCamera
    local XOffset, YOffset = BattleCraneCamera:GetInputOffset()
    UE4.UCraneCameraEditorUserSettings.SendInputParamToUmg(XOffset, YOffset)
  end
end

function BattleCraneCameraHost.SendCameraParamToUmg()
  if _G.RocoEnv.IS_EDITOR then
    local BattleCraneCamera = BattleManager.vBattleField.battleCraneCamera
    if BattleCraneCamera then
      local CameraLocation = BattleCraneCamera.CameraActor:K2_GetActorLocation()
      local TargetArmLength = BattleCraneCamera.SpringArmComponent.TargetArmLength
      local SpringArmRotation = BattleCraneCamera.SpringArmComponent:K2_GetComponentRotation()
      UE4.UCraneCameraEditorUserSettings.SendCameraParamToUmg(CameraLocation, TargetArmLength, SpringArmRotation)
    end
  end
end

function BattleCraneCameraHost.SendCameraAdditionalToUmg()
  if _G.RocoEnv.IS_EDITOR then
    local BattleCraneCamera = BattleManager.vBattleField.battleCraneCamera
    if BattleCraneCamera then
      local LookPosAdditional = BattleCraneCamera:GetLookPosAdditional()
      local RotationAdditional = BattleCraneCamera:GetSpringArmRotationAdditional()
      UE4.UCraneCameraEditorUserSettings.SendCameraAdditionalToUmg(LookPosAdditional, RotationAdditional)
    end
  end
end

function BattleCraneCameraHost.SendCameraCfgToUmg()
  if _G.RocoEnv.IS_EDITOR then
    local BattleCraneCamera = BattleManager.vBattleField.battleCraneCamera
    if BattleCraneCamera then
      local CurCameraTag = BattleCraneCamera.confData:GetCurCameraTag()
      local CameraJsonName = BattleCraneCamera.confData:GetJsonNameByCameraTag(CurCameraTag)
      local GlobalJsonName = BattleCraneCameraDefine.CameraJsonGlobalName
      UE4.UCraneCameraEditorUserSettings.SendCameraCfgToUmg(CurCameraTag, CameraJsonName, GlobalJsonName)
    end
  end
end

function BattleCraneCameraHost.SendCameraBaseInfoToGame(TargetA, TargetB, TargetOffset, SpringRot, SpringArmLen, Fov, ISOpenDepth, DepthOfFieldScale)
  if not TargetOffset then
    Log.Debug("SendCameraBaseInfoToGame. TargetOffset error")
    return
  end
  if not SpringRot then
    Log.Debug("SendCameraBaseInfoToGame. SpringRot error")
    return
  end
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera then
    local rot = {}
    rot.X = SpringRot.Pitch
    rot.Y = SpringRot.Yaw
    rot.Z = SpringRot.Roll
    battleCraneCamera.confData:ResetCameraBaseInfo(TargetA, TargetB, TargetOffset, rot, SpringArmLen, Fov)
    battleCraneCamera:ResetCamera()
  end
end

function BattleCraneCameraHost.SendGlobalCfgToGame(SlopeX, SlopeY, TeamPetHeightX, TeamPetHeightY, EnemyPetHeightX, EnemyPetHeightY, HeightRatioX, HeightRatioY, PitchX, PitchY, YawX, YawY, XSpeed, YSpeed, PitchAngleX, PitchAngleY)
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera then
    battleCraneCamera.confData:ResetGlobalInfo(SlopeX, SlopeY, TeamPetHeightX, TeamPetHeightY, EnemyPetHeightX, EnemyPetHeightY, HeightRatioX, HeightRatioY, PitchX, PitchY, YawX, YawY, XSpeed, YSpeed, PitchAngleX, PitchAngleY)
  end
end

function BattleCraneCameraHost.SendGlobalCfg2ToGame(Slope2X, Slope2Y, MyPet1Pet2HeightRatioX, MyPet1Pet2HeightRatioY)
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera then
    battleCraneCamera.confData:ResetGlobalInfoTwo(Slope2X, Slope2Y, MyPet1Pet2HeightRatioX, MyPet1Pet2HeightRatioY)
    battleCraneCamera:ResetCamera()
  end
end

function BattleCraneCameraHost.SendControlArray(ControlArray)
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera then
    battleCraneCamera.confData:ResetControlArray(ControlArray)
    battleCraneCamera:ResetCamera()
  end
end

function BattleCraneCameraHost.SendCurvesArray(CurvesArray)
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera and CurvesArray then
    local result = {}
    local len = CurvesArray:Length()
    for i = 1, len do
      local cfg = CurvesArray:Get(i)
      table.insert(result, {
        IsEnable = cfg.IsEnable,
        CurveId = cfg.CurveId,
        TargetCameraId = cfg.TargetCameraId
      })
    end
    battleCraneCamera.confData:ResetCameraCurveMap(result)
  end
end

function BattleCraneCameraHost.ChangeCameraComponentParent(OldSpringArmComponent, NewSpringArmComponent, CameraComponent, isOpen)
  UE4.UNRCStatics.ChangeCameraComponentParent(OldSpringArmComponent, NewSpringArmComponent, CameraComponent, isOpen)
end

function BattleCraneCameraHost.InitCameraForRotation()
  local AidRotationCam = _G.BattleManager:GetAidRotationCam()
  if AidRotationCam and UE4.UObject.IsValid(AidRotationCam) then
    local battleCraneCamera = BattleManager.vBattleField.battleCraneCamera
    local SpringArmComponent = AidRotationCam:GetComponentByClass(UE4.URocoSpringArmComponent)
    local targetPos1, _ = battleCraneCamera.confData:GetTargetPos()
    if not targetPos1 then
      Log.Error("BattleCraneCameraHost.InitCameraForRotation error,G CurCameraTag=", battleCraneCamera.confData:GetCurCameraTag(), "SpringArmComponent=", SpringArmComponent, "AidRotationCam=", AidRotationCam)
      return
    end
    local camTransform = UE4.UKismetMathLibrary.MakeTransform(targetPos1, _G.FRotatorZero, UE4.FVector(1, 1, 1))
    battleCraneCamera:SetAidRotationCamInitState()
    AidRotationCam:Abs_K2_SetActorTransform_WithoutHit(camTransform, false, false)
    local SprintArmEndPos = battleCraneCamera:GetSpringCameraEndLocation()
    local newArmLength = SprintArmEndPos:Dist(targetPos1)
    if SpringArmComponent then
      SpringArmComponent.TargetArmLength = newArmLength
      local newRot = UE4.UKismetMathLibrary.FindLookAtRotation(SprintArmEndPos, targetPos1)
      SpringArmComponent:K2_SetRelativeRotation(newRot, false, nil, false)
      UE4.UNRCStatics.UpdateSpringArmComponent(SpringArmComponent)
    else
      Log.Warning("\230\136\152\230\150\151\229\134\133AidRotationCam\231\155\184\230\156\186\232\142\183\229\143\150\229\188\185\231\176\167\232\135\130\231\187\132\228\187\182\229\164\177\232\180\165")
    end
  end
end

function BattleCraneCameraHost.SendCameraTagToGame(CameraTag)
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if battleCraneCamera then
    battleCraneCamera.confData:ReloadCameraTag(CameraTag)
    battleCraneCamera:ChangeCameraTag(CameraTag, 0, nil)
    BattleCraneCameraHost.SendCameraCfgToUmg()
  end
end

return BattleCraneCameraHost

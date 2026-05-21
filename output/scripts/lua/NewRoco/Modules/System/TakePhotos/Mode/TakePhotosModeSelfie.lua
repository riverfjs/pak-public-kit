local TakePhotosModeBasic = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosModeBasic")
local TakePhotosModeSelfie = TakePhotosModeBasic:Extend("TakePhotosModeSelfie")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SelfieCameraControl = require("NewRoco.Modules.System.TakePhotos.Controller.SelfieCameraControl")

function TakePhotosModeSelfie:OnConstruct()
  self.SelfieCameraControl = SelfieCameraControl(self)
end

function TakePhotosModeSelfie:OnInitFov()
  local FovList = TakePhotosEnum.TPGlobalNumList("takephoto_myself_FOV", {5000, 10000})
  self.MinFovScale = FovList[1] / 10000
  self.MaxFovScale = FovList[2] / 10000
  self.SavedFov = self:GetBaseFov()
  self.MinFov = self.SavedFov * self.MinFovScale
  self.MaxFov = self.SavedFov * self.MaxFovScale
end

function TakePhotosModeSelfie:OnSelfieConfigChangedEd()
  self.SelfieCameraControl:OnSelfieConfigChangedEd()
end

function TakePhotosModeSelfie:PreCheck()
  return self.SelfieCameraControl:Precheck()
end

function TakePhotosModeSelfie:ConsumeHandActionChangeRequest()
  return self.SelfieCameraControl:ConsumeHandActionChangeRequest()
end

function TakePhotosModeSelfie:GetCamera()
  return self.SelfieCameraControl:GetCamera()
end

function TakePhotosModeSelfie:AttachIgnoreActors(IgnoreActors)
  if self.Mgr:IsTripodMode() then
    local Camera = self.Mgr.CurrMode:GetCamera()
    if Camera and UE.UObject.IsValid(Camera) then
      table.insert(IgnoreActors, Camera)
    end
  end
end

function TakePhotosModeSelfie:GetRenderTarget2D()
  local Camera = self.SelfieCameraControl:GetCamera()
  local bValidCamera = Camera and UE.UObject.IsValid(Camera)
  if bValidCamera then
    local RT = NRCModuleManager:GetModule("TakePhotosModule").data:RequestRT()
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local cameraManager = player:GetUEController().playerCameraManager
    local Rotation = cameraManager:GetCameraRotation()
    local SceneCaptureComponent2D = Camera.SceneCaptureComponent2D
    SceneCaptureComponent2D:K2_SetWorldRotation(Rotation, false, nil, false)
    SceneCaptureComponent2D.FOVAngle = self.SavedFov
    SceneCaptureComponent2D.bDisableFlipCopyGLES = true
    UE4.UNRCStatics.SetCapturePostProcessing(SceneCaptureComponent2D)
    UE.UPlatformImageLibrary.CaptureSceneFinalImmediately(SceneCaptureComponent2D, RT)
    return RT
  elseif self.SelfieCameraControl.AttachParams and self.SelfieCameraControl.AttachParams.b2PRider then
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local cameraManager = player:GetUEController().playerCameraManager
    local RT = NRCModuleManager:GetModule("TakePhotosModule").data:RequestRT()
    cameraManager:StartCaptureImmediately(RT)
    return RT
  end
  if not bValidCamera then
    Log.Error("Invalid Camera")
  end
end

function TakePhotosModeSelfie:HasCameraEntered()
  return not self.SelfieCameraControl:GetCamera() and self.SelfieCameraControl.AttachParams and self.SelfieCameraControl.AttachParams.b2PRider
end

function TakePhotosModeSelfie:GetCameraRotationLocation()
  local Camera = self.SelfieCameraControl:GetCamera()
  if Camera and UE4.UObject.IsValid(Camera) then
    local Component = Camera:GetComponentByClass(UE.UCameraComponent)
    return Component:K2_GetComponentRotation(), Component:Abs_K2_GetComponentLocation()
  else
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local cameraManager = player:GetUEController().playerCameraManager
    return cameraManager:GetCameraRotation(), cameraManager:Abs_GetCameraLocation()
  end
end

function TakePhotosModeSelfie:GetPlayerConditionType()
  return Enum.PlayerConditionType.PCT_TAKE_PHOTO_MYSELF
end

function TakePhotosModeSelfie:OnShowEnterTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_open_myself_camera_tips, nil, nil, self.Mgr.ToggleTipsSeconds)
end

function TakePhotosModeSelfie:OnEnter()
  TakePhotosModeBasic.OnEnter(self)
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
    MainUIModule:DispatchEvent(MainUIModuleEvent.SetWidgetDisplayConstraints, "TakePhotos", true)
  end
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
  end
  self.SelfieCameraControl:Enter()
  TakePhotosUtils.ToggleSelfieStatus(true)
end

function TakePhotosModeSelfie:OnExit(bExitTakePhoto)
  TakePhotosModeBasic.OnExit(self)
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
    MainUIModule:DispatchEvent(MainUIModuleEvent.SetWidgetDisplayConstraints, "TakePhotos", false)
  end
  self.SavedFov = self:GetBaseFov()
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
  end
  self.SelfieCameraControl:Exit()
  TakePhotosUtils.ToggleSelfieStatus(false)
end

function TakePhotosModeSelfie:ResetCameraView()
  self.SavedFov = self:GetBaseFov()
  self.SelfieCameraControl:ResetCameraView()
end

function TakePhotosModeSelfie:GetSettings()
  return self.Mgr:GetModule().Controller.TakePhotoSettings
end

function TakePhotosModeSelfie:OnInputTurn(Dir, RawInput)
  self.SelfieCameraControl:InputTurn(Dir, RawInput)
end

function TakePhotosModeSelfie:OnToggleMouseMoveStatus(bMoving)
  self.SelfieCameraControl:OnToggleMouseMoveStatus(bMoving)
end

function TakePhotosModeSelfie:IsEnablePlayerLookLensFeature()
  return true
end

function TakePhotosModeSelfie:GetBaseFov()
  return TakePhotosEnum.TPGlobalNum("takephoto_myself_FOV_initial", 90)
end

function TakePhotosModeSelfie:OnTick(Dt)
  self.SelfieCameraControl:OnTick(Dt)
end

return TakePhotosModeSelfie

local TakePhotosMode1P = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosMode1P")
local TakePhotosModeTripod = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosModeTripod")
local TakePhotosModeWorld = require("NewRoco/Modules/System/TakePhotos/Mode/TakePhotosModeWorld")
local TakePhotosModeSelfie = require("NewRoco.Modules.System.TakePhotos.Mode.TakePhotosModeSelfie")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TakePhotosModeMgr = Class()

function TakePhotosModeMgr:Ctor()
  self.TakePhotosMode1P = TakePhotosMode1P(self, "1P")
  self.TakePhotosModeTripod = TakePhotosModeTripod(self, "Tripod")
  self.TakePhotosModeWorld = TakePhotosModeWorld(self, "TripodWorld")
  self.TakePhotosModeSelfie = TakePhotosModeSelfie(self, "Selfie")
  self.CurrMode = nil
  self.disableDis = TakePhotosEnum.TPGlobalNum("takephoto_coercive_esc_distance")
  self.disableDisSeconds = TakePhotosEnum.TPGlobalNum("takephoto_coercive_esc_time", 10000) / 10000
  self.disableFallSeconds = TakePhotosEnum.TPGlobalNum("takephoto_coercive_esc_height", 10000) / 10000
  self.warnSeconds = TakePhotosEnum.TPGlobalNum("takephoto_coercive_esc_tips_keeptime", 10000) / 10000
  self.warnTips = LuaText.takephoto_coercive_esc_tips
  self.ToggleTipsSeconds = TakePhotosEnum.TPGlobalNum("takephoto_change_camera_tips_time", 10000) / 10000
  self.waterSurfaceNotifyTips = LuaText.takephoto_watersurface_esc_tips
end

function TakePhotosModeMgr:GetModule()
  return NRCModuleManager:GetModule("TakePhotosModule")
end

function TakePhotosModeMgr:Is1PMode()
  return self.CurrMode == self.TakePhotosMode1P
end

function TakePhotosModeMgr:IsSelfieMode()
  return self.CurrMode == self.TakePhotosModeSelfie
end

function TakePhotosModeMgr:IsTripodAvailableMode(Mode)
  if Mode then
    return Mode == self.TakePhotosModeTripod or Mode == self.TakePhotosModeWorld
  end
  return self:IsTripodMode() or self:IsWorldMode()
end

function TakePhotosModeMgr:IsNoneMode()
  return self.CurrMode == nil
end

function TakePhotosModeMgr:IsTripodMode()
  return self.CurrMode == self.TakePhotosModeTripod
end

function TakePhotosModeMgr:IsWorldMode()
  return self.CurrMode == self.TakePhotosModeWorld
end

function TakePhotosModeMgr:IsFromTripodToWorld()
  return self:IsTripodMode() and self.PrevMode == self.TakePhotosModeWorld
end

function TakePhotosModeMgr:IsFromWorldToTripod()
  return self:IsWorldMode() and self.PrevMode == self.TakePhotosModeTripod
end

function TakePhotosModeMgr:OnEnterMode(Target)
  self.pendingMode = Target
  local OldMode = self.CurrMode
  Target:OnEnter()
  self.pendingMode = nil
  assert(OldMode == self.CurrMode, string.format("Invalid Mode (%s) -> (%s), Desired (%s)", OldMode and OldMode.Name, self.CurrMode and self.CurrMode.Name, Target.Name))
  self.PrevMode = OldMode
  self.CurrMode = Target
  self:GetModule():DispatchEvent(TakePhotosModuleEvent.OnToggleMode, Target, OldMode)
  if Target == self.TakePhotosModeSelfie then
    _G.NRCEventCenter:DispatchEvent(TakePhotosModuleEvent.OnToggleSelfieCameraMode)
  elseif Target == self.TakePhotosMode1P then
    _G.NRCEventCenter:DispatchEvent(TakePhotosModuleEvent.OnToggleFirstPersonCameraMode)
  elseif Target == self.TakePhotosModeTripod then
    _G.NRCEventCenter:DispatchEvent(TakePhotosModuleEvent.OnToggleTripodCameraMode)
  elseif Target == self.TakePhotosModeWorld then
    _G.NRCEventCenter:DispatchEvent(TakePhotosModuleEvent.OnToggleTripodWorldMode)
  end
end

function TakePhotosModeMgr:TryEnter1PMode()
  local bSuc, Msg = self.TakePhotosMode1P:PreCheck()
  if not bSuc then
    return false, Msg
  end
  self:OnEnterMode(self.TakePhotosMode1P)
  return true
end

function TakePhotosModeMgr:TakePhotosInCurrMode()
  if self.CurrMode then
    if self.CurrMode == self.TakePhotosModeWorld then
      self.TakePhotosModeTripod:TakePhotos()
    else
      self.CurrMode:TakePhotos()
    end
  end
end

function TakePhotosModeMgr:CleanupTakePhotos()
  if not self.CurrMode then
    return
  end
  Log.Info("[TakePhoto] CleanupTakePhotos", self.CurrMode.Name)
  local CurrMode = self.CurrMode
  self.CurrMode = nil
  self.PrevMode = nil
  CurrMode:OnExit(true)
end

function TakePhotosModeMgr:SetTipsEnabled(bEnable)
  if bEnable then
    NRCModuleManager:DoCmd(TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.TakePhoto)
  else
    NRCModuleManager:DoCmd(TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.TakePhoto)
  end
end

return TakePhotosModeMgr

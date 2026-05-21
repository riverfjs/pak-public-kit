local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local EnterExitContext = Class("EnterExitContext")
local EnmStatus = {
  None = 0,
  PreEnter = 1,
  Entering = 2,
  Entered = 3,
  Established = 4,
  PendingExit = 5,
  Exiting = 6
}

function EnterExitContext:Ctor(Module, Controller)
  self.Controller = Controller
  self.Status = EnmStatus.None
  self.Module = Module
  self.bTickEnabled = false
end

function EnterExitContext:CheckPreEnter()
  local bSuc, PoppedMsg = self.Module.ModeMgr.TakePhotosMode1P:PreCheck()
  if not bSuc then
    if not PoppedMsg then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_open_fail_tips)
    end
    _G.NRCAudioManager:PlaySound2DAuto(1329, "TakePhotosModule:TryOpenMainPanel")
    return false
  elseif not self.Controller:CanSwitchMode() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_open_fail_tips)
    _G.NRCAudioManager:PlaySound2DAuto(1329, "TakePhotosModule:TryOpenMainPanel")
    Log.Error("[TakePhoto] cannot switch mode")
    return false
  end
  _G.NRCAudioManager:PlaySound2DAuto(40009003, "TakePhotosModule:TryOpenMainPanel")
  return true
end

function EnterExitContext:TryEnter()
  local bSuc, PoppedMsg = self.Module.ModeMgr:TryEnter1PMode()
  if not bSuc then
    if not PoppedMsg then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_open_fail_tips)
    end
    return false
  end
  return true
end

function EnterExitContext:OnExit()
  self.Status = EnmStatus.None
  self.Module:SetForbidRelation(nil)
  self.Module:DispatchEvent(TakePhotosModuleEvent.OnExitTakePhotos)
  self.Controller:OnExit()
end

function EnterExitContext:OnEnterFailed()
  self.Status = EnmStatus.None
  self.Module:ClosePanel("TakePhotosMainUI")
  self.Module:SetForbidRelation(nil)
  self.Module:DispatchEvent(TakePhotosModuleEvent.OnExitTakePhotos)
  self.Controller:OnExit()
end

function EnterExitContext:OnPreEnterSuccess()
  self.Module:SetForbidRelation(true)
  self.Module:DispatchEvent(TakePhotosModuleEvent.OnEnterTakePhotos)
  self.Controller:OnEnter()
end

function EnterExitContext:OnEnterEstablished()
  self.Status = EnmStatus.Established
  self.Module.data:Preload()
  self.Module:DispatchEvent(TakePhotosModuleEvent.OnPostEnterTakePhotos)
  self.Controller:OnPostEnter()
end

function EnterExitContext:SetTickEnabled(bEnable)
  if bEnable ~= self.bTickEnabled then
    self.bTickEnabled = bEnable
    if bEnable then
      UpdateManager:Register(self)
    else
      UpdateManager:UnRegister(self)
    end
  end
end

function EnterExitContext:OnTick()
  if self.Status == EnmStatus.Entered then
    if not NRCPanelManager:IsLoadingPanel("TakePhotosModule", "TakePhotosMainUI") then
      self:SetTickEnabled(false)
      if not self.Module:HasPanel("TakePhotosMainUI") then
        Log.Warning("[TakePhoto] cannot found main ui panel")
        self:OnExit()
      else
        self:OnEnterEstablished()
      end
    end
  elseif self.Status == EnmStatus.PendingExit then
    self:SetTickEnabled(false)
    if self.bImmediatelyExit then
      if self.Module:HasPanel("TakePhotosMainUI") then
        self.Module:ClosePanel("TakePhotosMainUI")
      end
      self:OnExit()
    else
      self.Status = EnmStatus.Exiting
      self.Module:InternalOpenPhotoFrame("Switch", function()
        if self.Status == EnmStatus.Exiting then
          if self.Module:HasPanel("TakePhotosMainUI") then
            self.Module:ClosePanel("TakePhotosMainUI")
          end
          self:OnExit()
        end
      end)
    end
  end
end

function EnterExitContext:BeginEnter()
  if self.Status ~= EnmStatus.None then
    return false
  end
  self.Status = EnmStatus.PreEnter
  if not self:CheckPreEnter() then
    Log.Warning("[TakePhoto] pre enter failed")
    self.Status = EnmStatus.None
    return false
  end
  self.bImmediatelyExit = false
  self:OnPreEnterSuccess()
  self.Status = EnmStatus.Entering
  self.Module:InternalOpenPhotoFrame("Enter", function()
    if self.Status ~= EnmStatus.Entering then
      Log.Warning("[TakePhoto] entering animation finish, but status changed, status=", self.Status)
      return
    end
    self.Module:OpenPanel("TakePhotosMainUI")
    if not NRCPanelManager:IsLoadingPanel("TakePhotosModule", "TakePhotosMainUI") then
      Log.Warning("[TakePhoto] entering failed, cannot open main ui")
      self:OnEnterFailed()
      return
    end
    if self:TryEnter() then
      self.Status = EnmStatus.Entered
      self:SetTickEnabled(true)
    else
      Log.Warning("[TakePhoto] post enter failed")
      self:OnEnterFailed()
    end
  end)
  return true
end

function EnterExitContext:BeginExit(bImmediately)
  if self.Status == EnmStatus.None then
    return false
  end
  return self:DoExit(bImmediately)
end

function EnterExitContext:DoExit(bImmediately)
  if self.Status == EnmStatus.Entering or self.Status == EnmStatus.Entered then
    self.Module:ClosePanel("TakePhotosMainUI")
    self.Status = EnmStatus.None
    self:OnExit()
    return true
  elseif self.Status == EnmStatus.Established then
    Log.Debug("[TakePhoto] pending exit", bImmediately)
    self.Status = EnmStatus.PendingExit
    self.bImmediatelyExit = bImmediately
    self:SetTickEnabled(true)
    return true
  end
end

return EnterExitContext

local VisibilityMutex = require("NewRoco.Modules.System.TakePhotos.Helper.VisibilityMutex")
local Delegate = require("Utils.Delegate")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local TakePhotoProxy = Class("TakePhotoProxy")
local EnumTakePhotoStatus = {
  None = 0,
  Delaying = 1,
  TriggerTaking = 2
}

function TakePhotoProxy:Ctor(Panel)
  self.Panel = Panel
  Panel.OnDestroyMultiDelegate:Add(self, self.OnDestroy)
  Panel.OnTickMultiDelegate:Add(self, self.OnTick)
  self.Settings = Panel:GetPhotoController().TakePhotoSettings
  self.PhotoManager = Panel:GetPhotoController().PhotoManager
  self.Status = EnumTakePhotoStatus.None
  self.PhotoListThisSection = {}
  self.PhotoDesiredNumThisSection = 0
  self.BurstDuration = math.max(0.05, 1.0 / TakePhotosEnum.TPGlobalNum("takephoto_burst_speed", 1))
  self._CountDownSecondsText = Panel.Text_CountDown
  self.Settings.BurstGroup.OnOptionChanged:Add(self, self.OnBurstOptionChanged)
  self.Settings.CountDownGroup.OnOptionChanged:Add(self, self.OnCountDownOptionChanged)
  self.BurstNumText = self.Panel.ContinuousShot
  self.Panel.OnModeChangedDelegate:Add(self, self.OnTakePhotoModeChanged)
  self.OnStatusChanged = Delegate()
end

function TakePhotoProxy:OnDestroy()
  self:ClearTempPhotoList()
  self.Settings.BurstGroup.OnOptionChanged:Remove(self, self.OnBurstOptionChanged)
  self.Settings.CountDownGroup.OnOptionChanged:Remove(self, self.OnCountDownOptionChanged)
end

function TakePhotoProxy:OnBurstOptionChanged()
  local SettingNum = self.Settings:GetTakePhotoBurstNum()
  local DesiredNum = self:GetDesiredPhotoBurstNum()
  if SettingNum > 0 then
    self.Panel._BurstNumCanvasVisibilityMutex:SetVisible(true, "SettingControl")
    self.BurstNumText:SetText(string.format(LuaText.takephoto_burst_num_text, DesiredNum))
  else
    self.Panel._BurstNumCanvasVisibilityMutex:SetVisible(false, "SettingControl")
  end
end

function TakePhotoProxy:RefreshBurstDesc()
  local SettingNum = self.Settings:GetTakePhotoBurstNum()
  local DesiredNum = self:GetDesiredPhotoBurstNum()
  if SettingNum > 0 then
    self.BurstNumText:SetText(string.format(LuaText.takephoto_burst_num_text, DesiredNum))
  end
end

function TakePhotoProxy:OnCountDownOptionChanged()
  local DelaySeconds = self.Settings:GetTakePhotoCountDownSeconds()
  if DelaySeconds > 0 then
    self.Panel._Text_CountDownVisibilityMutex:SetVisible(true)
    self._CountDownSecondsText:SetText(DelaySeconds)
  else
    self.Panel._Text_CountDownVisibilityMutex:SetVisible(false)
  end
end

function TakePhotoProxy:OnTakePhotoModeChanged(CurrMode)
  if CurrMode.Mgr:IsFromTripodToWorld() or CurrMode.Mgr:IsFromWorldToTripod() then
    return
  end
  self:StopTakePhoto()
end

function TakePhotoProxy:IsTakingPhoto()
  return self.Status == EnumTakePhotoStatus.TriggerTaking or self.Status == EnumTakePhotoStatus.Delaying
end

function TakePhotoProxy:GetDesiredPhotoBurstNum()
  local Num = self.Settings:GetTakePhotoBurstNum()
  return math.min(Num, self.PhotoManager:GetRemainingLocalPhotoSlots())
end

function TakePhotoProxy:UpdateStatus(Status)
  if Status ~= self.Status then
    local bPrevTakingPhoto = self:IsTakingPhoto()
    self.Status = Status
    self.OnStatusChanged:Invoke(bPrevTakingPhoto)
  end
end

function TakePhotoProxy:StopTakePhoto()
  if self:IsTakingPhoto() then
    if self.DelayTakingTimer then
      self.Panel:CancelDelayByID(self.DelayTakingTimer)
      self.DelayTakingTimer = nil
    end
    self:UpdateStatus(EnumTakePhotoStatus.None)
  end
end

function TakePhotoProxy:IsDisplayingPhotoFile()
  local bLoading = NRCPanelManager:IsLoadingPanel("TakePhotosModule", "PhotoFileViewUI")
  if bLoading then
    return true
  end
  local bHasPanel = NRCModuleManager:GetModule("TakePhotosModule"):HasPanel("PhotoFileViewUI")
  if bHasPanel then
    return true
  end
  return false
end

function TakePhotoProxy:TakePhotoByMode()
  local Mode = self.Panel.CurrMode
  if not Mode then
    return
  end
  if self:IsDisplayingPhotoFile() then
    return
  end
  if self:IsTakingPhoto() then
    return
  end
  if self.PhotoManager:IsLocalPhotosFull() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_storage_max_tips)
    return
  end
  self:InternalStartTakePhoto()
end

function TakePhotoProxy:ClearTempPhotoList()
  for i, Data in ipairs(self.PhotoListThisSection) do
    Data:DetachSection()
  end
  self.PhotoListThisSection = {}
end

function TakePhotoProxy:InternalStartTakePhoto()
  local BurstNum = self:GetDesiredPhotoBurstNum()
  local DelaySeconds = self.Settings:GetTakePhotoCountDownSeconds()
  self:ClearTempPhotoList()
  self.PhotoDesiredNumThisSection = BurstNum
  
  local function OnTakePhoto()
    local Module = NRCModuleManager:GetModule("TakePhotosModule")
    local Mode = self.Panel.CurrMode
    if Module and Mode then
      Module:ReportTLog(BurstNum)
    end
    return self:InternalTakePhoto()
  end
  
  if DelaySeconds > 0 then
    self:UpdateStatus(EnumTakePhotoStatus.Delaying)
    local RemainingSeconds = DelaySeconds
    self:DisplayCountDownNum(RemainingSeconds)
    local OnCountDown = function()
      RemainingSeconds = RemainingSeconds - 1
      self:DisplayCountDownNum(RemainingSeconds)
      if RemainingSeconds > 0 then
        _G.NRCAudioManager:PlaySound2DAuto(40009002, "UMG_TakePhotos_C:CountDown")
        self.DelayTakingTimer = self.Panel:DelaySeconds(1, OnCountDown)
      else
        self.DelayTakingTimer = nil
        OnTakePhoto()
      end
    end
    self.DelayTakingTimer = self.Panel:DelaySeconds(1, OnCountDown)
  else
    OnTakePhoto()
  end
end

function TakePhotoProxy:ResetCountDownSetting()
  self.Settings.CountDownGroup:Reset()
end

function TakePhotoProxy:ResetBurstSetting()
  self.Settings.BurstGroup:Reset()
end

function TakePhotoProxy:InternalTakePhoto()
  self:ResetCountDownSetting()
  self:UpdateStatus(EnumTakePhotoStatus.TriggerTaking)
  local Mode = self.Panel.CurrMode
  if not Mode then
    self:InternalEndSection()
    return
  end
  self.Panel:DispatchEvent(TakePhotosModuleEvent.OnBeginTakingPhotos)
  local RenderTarget2D = Mode:GetRenderTarget2D()
  if RenderTarget2D then
    _G.NRCAudioManager:PlaySound2DAuto(40009004, "TakePhotoProxy:InternalTakePhoto")
    self.Panel:PlayAnimation(self.Panel.take)
    self.DelayTakingTimer = self.Panel:DelaySeconds(0.2, function()
      local PhotoData = self.PhotoManager:AddPhotoByTakingPhoto(RenderTarget2D)
      if PhotoData then
        self:OnPhotosTaken(PhotoData)
        self.Panel:DispatchEvent(TakePhotosModuleEvent.OnPhotosTaken, PhotoData, Mode.Mgr:IsTripodMode())
      elseif self.Status == EnumTakePhotoStatus.TriggerTaking then
        self:InternalEndSection()
      end
      self.Panel:DispatchEvent(TakePhotosModuleEvent.OnFinishTakingPhotos)
    end)
  else
    self.Panel:DispatchEvent(TakePhotosModuleEvent.OnFinishTakingPhotos)
    self:InternalEndSection()
    return
  end
end

function TakePhotoProxy:OnPhotosTaken(Data)
  self.DelayTakingTimer = nil
  if self.Status ~= EnumTakePhotoStatus.TriggerTaking then
    return
  end
  Data:AttachSection(self.PhotoListThisSection)
  if self.PhotoManager:IsLocalPhotosFull() then
    self:InternalEndSection()
    return
  end
  if #self.PhotoListThisSection < self.PhotoDesiredNumThisSection then
    self.DelayTakingTimer = self.Panel:DelaySeconds(self.BurstDuration, function()
      return self:InternalTakePhoto()
    end)
  else
    self:InternalEndSection()
  end
end

function TakePhotoProxy:InternalEndSection()
  self:ResetBurstSetting()
  self:UpdateStatus(EnumTakePhotoStatus.None)
  self:DisplayPhotos()
end

function TakePhotoProxy:DisplayCountDownNum(Num)
  self._CountDownSecondsText:SetText(string.format("%s", Num))
end

function TakePhotoProxy:DisplayPhotos()
  local PhotoData = self.PhotoListThisSection[1]
  if PhotoData then
    self.Panel.Adapter:ResetKeys()
    self.Panel:GetModule():PopupTakingPhotoFileView(PhotoData)
  end
end

function TakePhotoProxy:OnTick(Dt)
end

return TakePhotoProxy

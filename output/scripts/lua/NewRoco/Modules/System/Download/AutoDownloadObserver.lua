local PreDownloadEvent = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadEvent")
local AutoDownloadObserver = NRCClass("AutoDownloadObserver")
local BackgroundAutoRetryTimes = 3

function AutoDownloadObserver:Init()
  Log.Debug("AutoDownloadObserver:Init")
  self:ResetValues()
  self:RegistEvents()
end

function AutoDownloadObserver:Uninit()
  Log.Debug("AutoDownloadObserver:Uninit")
  self:UnregistEvents()
end

function AutoDownloadObserver:ResetValues()
  self.bPreDownloadAutoRetryTimes = 0
end

function AutoDownloadObserver:RegistEvents()
  _G.NRCEventCenter:RegisterEvent("AutoDownloadObserver", self, PreDownloadEvent.PreDownloadPanelActive, self.OnPreDownloadPanelActive)
  _G.NRCEventCenter:RegisterEvent("AutoDownloadObserver", self, PreDownloadEvent.PreDownloadAutoRetry, self.OnPreDownloadAutoRetry)
  _G.NRCEventCenter:RegisterEvent("AutoDownloadObserver", self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
  _G.NRCEventCenter:RegisterEvent("AutoDownloadObserver", self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
end

function AutoDownloadObserver:UnregistEvents()
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadPanelActive, self.OnPreDownloadPanelActive)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadAutoRetry, self.OnPreDownloadAutoRetry)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
end

function AutoDownloadObserver:OnPreDownloadAutoRetry()
  if self.bPreDownloadAutoRetryTimes < BackgroundAutoRetryTimes then
    self.bPreDownloadAutoRetryTimes = self.bPreDownloadAutoRetryTimes + 1
    Log.Debug("[AutoDownloadObserver:OnPreDownloadAutoRetry] ", self.bPreDownloadAutoRetryTimes)
    _G.NRCPreDownloadManager:StartDownload()
  end
end

function AutoDownloadObserver:OnPreDownloadPanelActive()
  self.bPreDownloadAutoRetryTimes = 0
end

function AutoDownloadObserver:OnEnterForeground()
  Log.Debug("[AutoDownloadObserver:OnEnterForeground]")
  if self.bNeedToRecoverPreDownloadSpeedLimitMode then
    _G.NRCPreDownloadManager:SetSpeedLimitMode()
    self.bNeedToRecoverPreDownloadSpeedLimitMode = false
  elseif self.bNeedToRecoverAutoDownloadSpeedLimitMode then
    _G.NRCAutoDownloadManager:SetSpeedLimitMode()
    self.bNeedToRecoverAutoDownloadSpeedLimitMode = false
  end
end

function AutoDownloadObserver:OnEnterBackground()
  Log.Debug("[AutoDownloadObserver:OnEnterBackground]")
  if _G.NRCPreDownloadManager:IsDownloading() then
    Log.Debug("[AutoDownloadObserver:OnEnterBackground] Predownload Is Downloading")
    if _G.NRCPreDownloadManager:IsSpeedLimitMode() then
      self.bNeedToRecoverPreDownloadSpeedLimitMode = true
      _G.NRCPreDownloadManager:SetMaxSpeedMode()
    end
  elseif _G.NRCAutoDownloadManager:IsAnyTaskDownloading() then
    Log.Debug("[AutoDownloadObserver:OnEnterBackground] AutoDownload Is Downloading")
    if _G.NRCAutoDownloadManager:IsSpeedLimitMode() then
      self.bNeedToRecoverAutoDownloadSpeedLimitMode = true
      _G.NRCAutoDownloadManager:SetMaxSpeedMode()
    end
  end
end

return AutoDownloadObserver

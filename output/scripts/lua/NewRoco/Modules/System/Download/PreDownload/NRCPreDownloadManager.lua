local PreDownloadEvents = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadEvent")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local UpdateStageLocalText = require("NewRoco.Modules.System.UpdateUIModule.UpdateStageLocalText")
local LoginModuleEvent = require("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local JsonUtils = require("Common.JsonUtils")
local PreDownloadEnum = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local NoWifiNotciceMBThreshold = 20
local NRCPreDownloadManager = _G.Singleton:Extend("NRCPreDownloadManager")

function NRCPreDownloadManager:Ctor()
  Log.Debug("NRCPreDownloadManager:Ctor")
  self.bEnabled = not RocoEnv.IS_EDITOR and not RocoEnv.PLATFORM_WINDOWS
end

function NRCPreDownloadManager:ResetValues()
  self.bIsPreDownloadResEnabled = false
  self.DolphinTask = nil
  self.PufferTask = nil
  self.PufferTaskID = nil
  self.LocalPreDownloadConfig = nil
  self.bEnableNetworkListener = true
  self.bIfNeedToDownload = nil
  self.bPreDownloadPanelActive = false
  self.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Idle
end

function NRCPreDownloadManager:Init()
  if not self.bEnabled then
    return
  end
  if self.bInited then
    Log.Error("[NRCPreDownloadManager:Init] Reinit, call Uninit first")
    self:UnInit()
  end
  self:ResetValues()
  self.bInited = true
end

function NRCPreDownloadManager:UnInit()
  self:ReleaseUpdateTask()
  self:ResetValues()
  self:UnregisterEvents()
  self.bInited = false
end

function NRCPreDownloadManager:ReleaseUpdateTask()
  self:ReleaseDolphinTask()
  self:ReleasePufferTask()
end

function NRCPreDownloadManager:ReleaseDolphinTask()
  if self.DolphinTask then
    self.DolphinTask:Uninit()
    self.DolphinTask = nil
  end
end

function NRCPreDownloadManager:ReleasePufferTask()
  if self.PufferTask then
    self.PufferTask:Uninit()
    self.PufferTask = nil
  end
end

function NRCPreDownloadManager:RegisterEvents()
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, NRCSDKManagerEvent.OnBackToLogin, self.OnBackToLogin)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, NRCGlobalEvent.OnPufferInitReturn, self.OnPufferInitReturn)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, NRCGlobalEvent.OnPufferInitProgress, self.OnPufferInitProgress)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnDownloadBatchProgress)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, PreDownloadEvents.PreDownloadPanelActive, self.OnPreDownloadPanelActive)
  _G.NRCEventCenter:RegisterEvent("NRCPreDownloadManager", self, PreDownloadEvents.PreDownloadPanelDeactive, self.OnPreDownloadPanelDeactive)
end

function NRCPreDownloadManager:UnregisterEvents()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCSDKManagerEvent.OnBackToLogin, self.OnBackToLogin)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferInitReturn, self.OnPufferInitReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferInitProgress, self.OnPufferInitProgress)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnDownloadBatchProgress)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvents.PreDownloadPanelActive, self.OnPreDownloadPanelActive)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvents.PreDownloadPanelDeactive, self.OnPreDownloadPanelDeactive)
end

function NRCPreDownloadManager:DisablePreDownload()
  self.bIsPreDownloadResEnabled = false
end

function NRCPreDownloadManager:OnBackToLogin()
  Log.Debug("[NRCPreDownloadManager:OnBackToLogin]")
  if self.PufferTask then
    self.PufferTask:RemoveTaskByID(self.PufferTaskID)
  end
  self:UnInit()
end

function NRCPreDownloadManager:GetLocalPreDownloadConfigPath()
  return UE.UBlueprintPathsLibrary.Combine({
    self:GetPreDownloadRootPath(),
    "LocalPreDownloadConfig.json"
  })
end

function NRCPreDownloadManager:CheckLocalPreDownloadConfig()
  local LocalPreDownloadConfigPath = self:GetLocalPreDownloadConfigPath()
  if not UE.UNRCStatics.FileExists(LocalPreDownloadConfigPath) then
    Log.Debug("[NRCPreDownloadManager:CheckLocalPreDownloadConfig] LocalPreDownloadConfigPath is not exists, path:", LocalPreDownloadConfigPath)
    self:DeleteAllPreloadDownloadDir()
    self:OnLocalConfigCheckDone()
    return
  end
  local JsonObject = JsonUtils.LoadSpecifiedPath(LocalPreDownloadConfigPath)
  if JsonObject then
    local AppVersion = AppMain.GetAppVersion()
    if JsonObject.TargetAppVersion and AppVersion == JsonObject.TargetAppVersion then
      self:CopyPreloadDownloadResToTargetDir()
    elseif JsonObject.BaseAppVersion and AppVersion == JsonObject.BaseAppVersion then
      self.LocalPreDownloadConfig = JsonObject
      self:OnLocalConfigCheckDone()
    else
      self:OnLocalConfigCheckFailed("[predownload] CheckLocalPreDownloadConfig failed, AppVersion is not match")
    end
  else
    self:OnLocalConfigCheckFailed("[predownload] CheckLocalPreDownloadConfig failed, JsonObj is nil")
  end
end

function NRCPreDownloadManager:OnLocalConfigCheckDone()
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.LocalPreDownloadConfigCheckDone)
end

function NRCPreDownloadManager:OnLocalConfigCheckFailed(FailedReason)
  self:DeleteAllPreloadDownloadDir()
  self:UnInit()
  self:DisablePreDownload()
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PreDownloadFail, FailedReason)
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.LocalPreDownloadConfigCheckFailed)
end

function NRCPreDownloadManager:DeleteAllPreloadDownloadDir()
  local PreDownloadRootPath = self:GetPreDownloadRootPath()
  if not UE.UNRCStatics.DirectoryExists(PreDownloadRootPath) then
    Log.Debug("[NRCPreDownloadManager:DeleteAllPreloadDownloadDir] PreDownloadRootPath is not exists, path:", PreDownloadRootPath)
    return
  end
  local bSuccess = UE.UNRCStatics.RemoveFolder(PreDownloadRootPath)
  if not bSuccess then
    Log.Error("[NRCPreDownloadManager:DeleteAllPreloadDownloadDir] DeleteAllPreloadDownloadDir failed, path:", PreDownloadRootPath)
  else
    Log.Debug("[NRCPreDownloadManager:DeleteAllPreloadDownloadDir] DeleteAllPreloadDownloadDir success, path:", PreDownloadRootPath)
  end
end

function NRCPreDownloadManager:DeletePreloadPufferDownloadDir()
  local PreDownloadRootPath = self:GetPufferRootDir()
  if not UE.UNRCStatics.DirectoryExists(PreDownloadRootPath) then
    Log.Debug("[NRCPreDownloadManager:DeletePreloadPufferDownloadDir] dir is not exists, path:", PreDownloadRootPath)
    return
  end
  local bSuccess = UE.UNRCStatics.RemoveFolder(PreDownloadRootPath)
  if not bSuccess then
    Log.Error("[NRCPreDownloadManager:DeletePreloadPufferDownloadDir] failed, path:", PreDownloadRootPath)
  else
    Log.Debug("[NRCPreDownloadManager:DeletePreloadPufferDownloadDir] success, path:", PreDownloadRootPath)
  end
end

function NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir()
  Log.Debug("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] start")
  local SrcDir = self:GetPufferRootDir() .. "/"
  Log.Debug("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] SrcDir ", SrcDir)
  local DestDir = _G.PufferUpdateResTask:GetPufferRootDir()
  Log.Debug("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] DestDir ", DestDir)
  local FoundFiles = UE.UNRCStatics.ListFiles(SrcDir, "*.*")
  local FoundFilesList = FoundFiles:ToTable()
  local FileCount = #FoundFilesList
  for Index, SrcPath in ipairs(FoundFilesList) do
    if not string.find(SrcPath, "puffer_temp") then
      local Name = UE.UBlueprintPathsLibrary.GetCleanFilename(SrcPath)
      Log.Debug(string.format("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] found path:%s, name:%s", SrcPath, Name))
      if "puffer_res.eifs" ~= Name then
        local RelativePath, bMakeRelativeSuccess = UE.UBlueprintPathsLibrary.MakePathRelativeTo(SrcPath, SrcDir)
        if bMakeRelativeSuccess then
          local DestPath = UE.UBlueprintPathsLibrary.Combine({DestDir, RelativePath})
          local bSuccess = UE.UNRCStatics.MoveFile(SrcPath, DestPath)
          if not bSuccess then
            Log.Error("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] MoveFile failed, path:", SrcPath, " dest:", DestPath)
          else
            Log.Debug("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] MoveFile success, path:", SrcPath, " dest:", DestPath)
          end
        else
          Log.Error("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] MakePathRelativeTo failed, RelativePath:", RelativePath)
        end
      end
    else
      Log.Debug("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] skip puffer_temp file:", SrcPath)
    end
    local Progress = 0
    if 0 ~= FileCount then
      Progress = Index / FileCount
      Log.Debug("[NRCPreDownloadManager:CopyPreloadDownloadResToTargetDir] progress:", Progress)
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PufferInitProgress, Progress, UpdateStageLocalText.PreDownloadResMoving)
    end
  end
  self:DeleteAllPreloadDownloadDir()
  self:OnLocalConfigCheckDone()
end

function NRCPreDownloadManager:GetPreDownloadConfigName()
  local AppVersion = AppMain.GetAppVersion()
  return string.format("PreDownloadConfig_%s.json", AppVersion)
end

function NRCPreDownloadManager:GetLocalDownloadedConfigPath()
  return UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    self:GetPreDownloadConfigName()
  })
end

function NRCPreDownloadManager:DownloadPreDownloadConfig()
  if not self.bEnabled then
    Log.Debug("[NRCPreDownloadManager:DownloadPreDownloadConfig] pre download is disabled")
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.UpdateUIModuleCmd.SetProgress, 0, UpdateStageLocalText.DonwloadPreDownloadConfig)
  local bRelease = AppMain:IsReleaseFormalEnv()
  local FileName = self:GetPreDownloadConfigName()
  local BranchName = AppMain.GetProjectBranch()
  local URL = UE.UHotUpdateUtils.GetUpdateConfigFileURL(bRelease, FileName, BranchName)
  local URLWithTS = URL .. "?t=" .. UE4.UNRCStatics.GetUTCTimestampMS()
  Log.Debug("[NRCPreDownloadManager:DownloadPreDownloadConfig] download ", URLWithTS)
  local LocalFilePath = self:GetLocalDownloadedConfigPath()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    Log.Error("[NRCPreDownloadManager:DownloadPreDownloadConfig] GameInstance is nil")
    self:DisablePreDownload()
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
    return
  end
  GameInstance.OnDownloadFileResult:Clear()
  GameInstance.OnDownloadFileResult:Add(GameInstance, function(this, InURL, bSuccess, ErrorCode)
    Log.Debug(string.format("[NRCPreDownloadManager:DownloadPreDownloadConfig] download %s result: %s ErrorCode:%s", InURL, bSuccess, ErrorCode or "nil"))
    if InURL == URLWithTS then
      if bSuccess then
        Log.Debug("[NRCPreDownloadManager:DownloadPreDownloadConfig] download success")
        self:OnDownloadPreDownloadConfigSuccess()
      else
        Log.Error("[NRCPreDownloadManager:DownloadPreDownloadConfig] download failed")
        self:OnDownloadPreDownloadConfigFailed()
      end
    end
  end)
  self.bGetPreDownloadConfigResult = false
  self.PreDownloadConfigTimeOutTimer = _G.TimerManager:CreateTimer(self, "PreDownloadConfigTimeOutTimer", 3, nil, self.OnDownloadUpdateConfigTimeOut, 9999)
  UE4.UNRCStatics.HttpDownloadFile(URLWithTS, LocalFilePath)
end

function NRCPreDownloadManager:ClearPreDownloadConfigTimerAndDelegate()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance.OnDownloadFileResult:Clear()
  end
  _G.TimerManager:RemoveTimer(self.PreDownloadConfigTimeOutTimer)
  self.PreDownloadConfigTimeOutTimer = nil
end

function NRCPreDownloadManager:OnDownloadPreDownloadConfigTimeOut()
  if self.bGetPreDownloadConfigResult then
    Log.Error("[NRCPreDownloadManager:OnDownloadPreDownloadConfigTimeOut] invalid callback")
    return
  end
  self.bGetPreDownloadConfigResult = true
  Log.Error("[NRCPreDownloadManager:OnDownloadPreDownloadConfigTimeOut] download timeout")
  self:ClearPreDownloadConfigTimerAndDelegate()
  self:SendEventToLoginFsmAndReportFailed("[predownload]Download predownload config timeout")
end

function NRCPreDownloadManager:OnDownloadPreDownloadConfigFailed()
  if self.bGetPreDownloadConfigResult then
    Log.Error("[NRCPreDownloadManager:OnDownloadPreDownloadConfigFailed] invalid callback")
    return
  end
  self.bGetPreDownloadConfigResult = true
  self:ClearPreDownloadConfigTimerAndDelegate()
  self:SendEventToLoginFsmAndReportFailed("[predownload]Download predownload config failed")
end

function NRCPreDownloadManager:OnDownloadPreDownloadConfigSuccess()
  if self.bGetPreDownloadConfigResult then
    Log.Error("[NRCPreDownloadManager:OnDownloadPreDownloadConfigSuccess] invalid callback")
    return
  end
  self.bGetPreDownloadConfigResult = true
  self:ClearPreDownloadConfigTimerAndDelegate()
  self:ApplyPreDownloadConfig()
end

function NRCPreDownloadManager:SendEventToLoginFsmAndReportFailed(FailedReason)
  Log.Error("[NRCPreDownloadManager:SendEventToLoginFsmAndReportFailed] " .. FailedReason)
  DelayManager:DelayFrames(1, function()
    self:UnInit()
    self:DisablePreDownload()
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PreDownloadFail, FailedReason)
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
  end)
end

function NRCPreDownloadManager:ApplyPreDownloadConfig()
  local LocalConfigPath = self:GetLocalDownloadedConfigPath()
  if not UE.UNRCStatics.FileExists(LocalConfigPath) then
    self:SendEventToLoginFsmAndReportFailed("[predownload]Local config file not exists")
    return
  end
  local JsonData, bSuccess = UE4.UHotUpdateUtils.ReadEncryptedJsonData(LocalConfigPath)
  if bSuccess then
    Log.Debug("[NRCPreDownloadManager:ApplyPreDownloadConfig] JsonData: " .. JsonData)
    local JsonObject = JsonUtils.StringToJson(JsonData)
    if JsonObject then
      if self:SetPreDownloadVersion(JsonObject.TargetAppVersion, JsonObject.TargetResVersion) then
        self:InitDolphin()
      else
        self:SendEventToLoginFsmAndReportFailed("[predownload]parse predownload config failed")
      end
    else
      self:SendEventToLoginFsmAndReportFailed("[predownload]JsonObject is nil")
    end
  else
    self:SendEventToLoginFsmAndReportFailed("[predownload]ReadEncryptedJsonData failed")
  end
end

function NRCPreDownloadManager:SetPreDownloadVersion(AppVersion, ResVersion)
  if AppVersion and ResVersion and type(AppVersion) == "string" and type(ResVersion) == "string" then
    self.PreDownloadAppVersion = AppVersion
    self.PreDownloadResVersion = ResVersion
    Log.Debug(string.format("[NRCPreDownloadManager:SetPreDownloadVersion] AppVersion: %s, ResVersion: %s", AppVersion, ResVersion))
    return true
  end
  Log.Error(string.format("[NRCPreDownloadManager:SetPreDownloadVersion] AppVersion: %s, ResVersion: %s", AppVersion or "nil", ResVersion or "nil"))
  return false
end

function NRCPreDownloadManager:InitDolphin()
  self.DolphinSuccess = false
  local PreDownloadDolphinResTask = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadDolphinResTask")
  self.DolphinTask = PreDownloadDolphinResTask()
  self.DolphinTask.NewVersionDelegate:Add(self, self.OnDolphinResNewResVersion)
  self.DolphinTask.ProgressDelegate:Add(self, self.OnDolphinResUpdateProgress)
  self.DolphinTask.SuccessDelegate:Add(self, self.OnDolphinResUpdateResSuccess)
  self.DolphinTask.ErrorDelegate:Add(self, self.OnDolphinResUpdateResError)
  if self.DolphinTask:Init() then
    self.DolphinTask:StartCheck()
  else
    self:SendEventToLoginFsmAndReportFailed("[predownload]DolphinTask Init failed")
  end
end

function NRCPreDownloadManager:OnDolphinResNewResVersion(UpdateTask, NewVersion)
  if not NewVersion.isNeedUpdating then
    Log.Debug("[NRCPreDownloadManager:OnDolphinResNewResVersion] isNeedUpdating is false")
    self:OnDolphinResUpdateFinish(true)
  else
    if NewVersion.needDownloadSize then
      Log.Warning("NewVersion.needDownloadSize -- ", NewVersion.needDownloadSize)
      Log.Warning("UpdateTask:FormatBytes(NewVersion.needDownloadSize) -- ", UpdateTask:FormatBytes(NewVersion.needDownloadSize))
    end
    if 0 == NewVersion.needDownloadSize then
      NewVersion.isForcedUpdating = true
    end
    if NewVersion.isForcedUpdating then
      if self.DolphinTask then
        self.DolphinTask:ContinueUpdate(true)
      else
        self:SendEventToLoginFsmAndReportFailed("[predownload]DolphinTask is nil")
      end
    else
      Log.Debug("[NRCPreDownloadManager:OnDolphinResNewResVersion] isForcedUpdating is false")
      self:OnDolphinResUpdateFinish(true)
    end
  end
end

function NRCPreDownloadManager:OnDolphinResUpdateProgress(UpdateTask, Stage, Total, Now)
  local Percent = 0
  if 0 ~= Total then
    Percent = Now / Total
  end
  if Stage == UE.DolphinUpdateStage.VS_SourceExtract then
    Log.Debug("Source extract...")
    self.SourceExtract = true
  end
  local HintContent = UpdateStageLocalText.DolphinAppCheckVersion
  Log.Debug("NRCPreDownloadManager:SetProgress...", Stage, Percent, UpdateTask:GetAverageSpeed(), UpdateTask:GetCurrentSpeed())
  NRCModuleManager:DoCmd(UpdateUIModuleCmd.SetProgress, Percent, HintContent, UpdateTask:FormatBytes(Total), UpdateTask:FormatBytes(Now), UpdateTask:GetCurrentSpeed())
end

function NRCPreDownloadManager:OnDolphinResUpdateResSuccess(Task, bHasNewResouce)
  Log.Debug("NRCPreDownloadManager:OnDolphinResUpdateResSuccess", bHasNewResouce)
  self.DolphinSuccess = true
  self:OnDolphinResUpdateFinish(true)
end

function NRCPreDownloadManager:OnDolphinResUpdateResError(UpdateTask, CurVersionStage, ErrorCode)
  Log.Error(string.format("[NRCPreDownloadManager:OnDolphinResUpdateResError] ErrorCode: %s, CurVersionStage: %s", ErrorCode, CurVersionStage))
  self:SendEventToLoginFsmAndReportFailed("[predownload]Dolphin update error")
end

function NRCPreDownloadManager:OnDolphinResUpdateFinish(bExcuteNextFrame)
  Log.Debug("NRCPreDownloadManager:OnDolphinResUpdateFinish")
  if bExcuteNextFrame then
    _G.DelayManager:DelayFrames(1, function()
      self:ReleaseDolphinTask()
      _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
    end)
  else
    self:ReleaseDolphinTask()
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
  end
end

function NRCPreDownloadManager:InitPuffer()
  if not self.bEnabled then
    Log.Debug("[NRCPreDownloadManager:InitPuffer] bEnabled is false")
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
    return
  end
  if not self.DolphinSuccess then
    Log.Error("[NRCPreDownloadManager:InitPuffer] Dolphin is not success")
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
    return
  end
  if self.PufferInited then
    Log.Error("[NRCPreDownloadManager:InitPuffer] PufferInited is true")
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
    return
  end
  local bWriteSuccess, ErrorMsg = self:TryWriteLocalConfig()
  if not bWriteSuccess then
    self:SendEventToLoginFsmAndReportFailed(ErrorMsg)
    return
  end
  self:RegisterEvents()
  local PufferTask = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadPufferTask")
  self.PufferTask = PufferTask()
  if not self.PufferTask:Init() then
    self:SendEventToLoginFsmAndReportFailed("[predownload]Puffer init failed")
  end
end

function NRCPreDownloadManager:TryWriteLocalConfig()
  local LocalConfig = {
    TargetAppVersion = self:GetPreDownloadAppVersion(),
    TargetResVersion = self:GetPreDownloadResVersion(),
    BaseAppVersion = AppMain.GetAppVersion()
  }
  if LocalConfig.TargetAppVersion and LocalConfig.BaseAppVersion then
    local bNeedToWriteNewConfig = false
    local LocalPreDownloadConfigPath = self:GetLocalPreDownloadConfigPath()
    if UE.UNRCStatics.FileExists(LocalPreDownloadConfigPath) then
      if self.LocalPreDownloadConfig and self.LocalPreDownloadConfig.TargetAppVersion == LocalConfig.TargetAppVersion and self.LocalPreDownloadConfig.TargetResVersion == LocalConfig.TargetResVersion and self.LocalPreDownloadConfig.BaseAppVersion == LocalConfig.BaseAppVersion then
        Log.Debug("[NRCPreDownloadManager:CheckLocalConfigIfNeedToWrite] LocalPreDownloadConfig is same")
      else
        Log.Error("[NRCPreDownloadManager:CheckLocalConfigIfNeedToWrite] LocalPreDownloadConfig is not same")
        bNeedToWriteNewConfig = true
      end
    else
      bNeedToWriteNewConfig = true
    end
    if bNeedToWriteNewConfig and not JsonUtils.DumpSpecifiedPath(LocalPreDownloadConfigPath, LocalConfig) then
      return false, "[predownload]write local config failed"
    end
  else
    return false, "[predownload]LocalConfig is invalid"
  end
  return true
end

function NRCPreDownloadManager:OnPufferInitReturn(TaskInstance, IsSuccess, ErrorCode)
  if not self.PufferTask then
    Log.Error("[NRCPreDownloadManager:OnPufferInitReturn] PufferTask is nil")
    return
  end
  if self.PufferTask ~= TaskInstance then
    Log.Debug("[NRCPreDownloadManager:OnPufferInitReturn] TaskInstance is not same")
    return
  end
  if self.PufferInited then
    Log.Error("[NRCPreDownloadManager:OnPufferInitReturn] PufferInited is true")
    return
  end
  if IsSuccess then
    self.PufferInited = true
    _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferInitReturn, self.OnPufferInitReturn)
    _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferInitProgress, self.OnPufferInitProgress)
    self.bIsPreDownloadResEnabled = true
    self:IfNeedToDownload()
    self:SetSpeedLimitMode()
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadPreDownloadConfigDone)
  else
    self:SendEventToLoginFsmAndReportFailed(string.format("[predownload]Puffer init failed, ErrorCode: %s", ErrorCode))
  end
end

function NRCPreDownloadManager:OnPufferInitProgress(Stage, NowSize, TotalSize)
  if self.PufferInited then
    Log.Error("[NRCPreDownloadManager:OnPufferInitProgress] PufferInited is true")
    return
  end
  local Percent = 0
  if 0 ~= TotalSize then
    Percent = NowSize / TotalSize
  end
  _G.NRCModuleManager:DoCmd(_G.UpdateUIModuleCmd.SetProgress, Percent, UpdateStageLocalText.PufferInit)
end

function NRCPreDownloadManager:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize, bNeedPopupWindowTip)
  Log.Debug(string.format("[NRCPreDownloadManager:CheckPufferFreeDiskSpace] get total file size:%s largestSize:%s ", SizeNeedToDownload, LargestSize))
  local FreeDiskSpace = UE.UNRCStatics.GetFreeDiskSpace()
  Log.Debug("[NRCPreDownloadManager:CheckPufferFreeDiskSpace] FreeDiskSpace:", FreeDiskSpace)
  local BytesRequired = SizeNeedToDownload + LargestSize * 2
  local RealLimitSpace = BytesRequired / 1024 / 1024
  Log.Debug("[NRCPreDownloadManager:CheckPufferFreeDiskSpace] RealLimitSpace:", RealLimitSpace)
  if FreeDiskSpace >= 0 and FreeDiskSpace < RealLimitSpace then
    if bNeedPopupWindowTip then
      local LimitSpace = BytesRequired / 1000 / 1000 / 1000
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(string.format(LuaText.free_disk_space_check_tips, LimitSpace)):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
        if result then
          self:StartDownload(true)
        end
      end):SetButtonText(LuaText.RETRY, LuaText.updateuimodule_42)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return false
  end
  return true
end

function NRCPreDownloadManager:CheckInternetConnectionPuffer(Callback, SizeNeedToDownload, bNeedPopupWindowTip)
  local NetworkType = UE.UNetworkStatics.GetNetworkState()
  if 1 == NetworkType and not self.bIgnoreNoWifiNotice then
    self.CurrentNetworkStatus = 1
    if SizeNeedToDownload then
      local SizeNeedToDownloadMB = SizeNeedToDownload / 1024 / 1024
      if SizeNeedToDownloadMB <= NoWifiNotciceMBThreshold then
        Log.Debug("[NRCPreDownloadManager:CheckInternetConnectionPuffer] skip no wifi notice")
        Callback(self)
        return
      end
    end
    if bNeedPopupWindowTip then
      Log.Debug("[NRCPreDownloadManager:CheckInternetConnectionPuffer] need to show no wifi notice")
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
        if result then
          self.bIgnoreNoWifiNotice = true
          Callback(self)
        end
      end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return false
  else
    self.CurrentNetworkStatus = NetworkType
    Callback(self)
    return true
  end
end

function NRCPreDownloadManager:GetPreDownloadAppVersion()
  return self.PreDownloadAppVersion
end

function NRCPreDownloadManager:GetPreDownloadResVersion()
  return self.PreDownloadResVersion
end

function NRCPreDownloadManager:IsPreDownloadResEnabled()
  local bIsPreDownloadResEnabled = self.bEnabled and self.bIsPreDownloadResEnabled
  if not bIsPreDownloadResEnabled then
    Log.Error("[NRCPreDownloadManager:IsPreDownloadResEnabled] bIsPreDownloadResEnabled is false")
  end
  return bIsPreDownloadResEnabled
end

function NRCPreDownloadManager:GetTotalSize(bGetBytesNumber)
  local DefaultSize = 0
  if not self:IsPreDownloadResEnabled() then
    return DefaultSize
  end
  if self.PufferTask then
    return self.PufferTask:GetTotalSize(bGetBytesNumber)
  else
    Log.Error("[NRCPreDownloadManager:GetTotalSize] PufferTask is nil")
    return DefaultSize
  end
end

function NRCPreDownloadManager:GetLocalDownloadedSize(bGetBytesNumber)
  local DefaultSize = 0
  if not self:IsPreDownloadResEnabled() then
    return DefaultSize
  end
  if self.PufferTask then
    if self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Success then
      return self.PufferTask:GetTotalSize(bGetBytesNumber)
    end
    local bReturnCache = false
    if self.DownloadedSize and self.DownloadedSize > 0 then
      bReturnCache = true
    end
    if not bReturnCache then
      self.DownloadedSize = self.PufferTask:GetLocalDownloadedSize()
    end
    if bGetBytesNumber then
      return self.DownloadedSize
    else
      return self.PufferTask:FormatBytes(self.DownloadedSize)
    end
  else
    Log.Error("[NRCPreDownloadManager:GetLocalDownloadedSize] PufferTask is nil")
    return DefaultSize
  end
end

function NRCPreDownloadManager:StartDownload(bNeedPopupWindowTip)
  if not self:IsPreDownloadResEnabled() then
    return false
  end
  if not self.PufferTask then
    Log.Error("[NRCPreDownloadManager:StartDownload] PufferTask is nil")
    return false
  end
  if bNeedPopupWindowTip then
    self.bPauseManually = false
  end
  if self.bPauseManually then
    Log.Error("[NRCPreDownloadManager:StartDownload] bPauseManually is true, can not start download")
    return false
  end
  if self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Downloading then
    Log.Error("[NRCPreDownloadManager:StartDownload] DownloadStatus is Downloading")
    return false
  elseif self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Paused then
    Log.Debug("[NRCPreDownloadManager:StartDownload] DownloadStatus is Paused, ResumeDownload")
    return self:ResumeDownload(bNeedPopupWindowTip)
  end
  local ResNeedToDownloadList, SizeNeedToDownload, LargestSize = self.PufferTask:GetPreDownloadResListNeedToDownload()
  if ResNeedToDownloadList and #ResNeedToDownloadList > 0 then
    if self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize, bNeedPopupWindowTip) then
      return self:CheckInternetConnectionPuffer(function(this)
        this.PufferTaskID = this.PufferTask:DownloadBatchListByPakList(ResNeedToDownloadList)
        if this.PufferTaskID then
          Log.Debug("[NRCPreDownloadManager:StartDownload] PufferTaskID: ", this.PufferTaskID)
          this.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Downloading
          _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
          _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadStart)
        end
      end, SizeNeedToDownload, bNeedPopupWindowTip)
    else
      return false
    end
  else
    Log.Error("[NRCPreDownloadManager:StartDownload] ResNeedToDownloadList is nil or empty")
    return false
  end
end

function NRCPreDownloadManager:PauseDownload(bPauseManually)
  if not self:IsPreDownloadResEnabled() then
    return
  end
  if bPauseManually then
    self.bPauseManually = true
  end
  if self.DownloadStatus ~= PreDownloadEnum.EPreDownloadStatus.Downloading then
    Log.Error("[NRCPreDownloadManager:PauseDownload] DownloadStatus is not Downloading")
    return
  end
  if self.PufferTask:PauseTask(self.PufferTaskID) then
    Log.Debug("[NRCPreDownloadManager:PauseDownload] PauseTask success, taskid:", self.PufferTaskID)
    self.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Paused
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
    _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadPaused)
    return true
  else
    Log.Error("[NRCPreDownloadManager:PauseDownload] PauseTask failed")
    return false
  end
end

function NRCPreDownloadManager:ResumeDownload(bNeedPopupWindowTip)
  if not self:IsPreDownloadResEnabled() then
    return
  end
  if self.DownloadStatus ~= PreDownloadEnum.EPreDownloadStatus.Paused then
    Log.Error("[NRCPreDownloadManager:ResumeDownload] DownloadStatus is not Paused")
    return
  end
  if self.bPauseManually then
    Log.Error("[NRCPreDownloadManager:ResumeDownload] bPauseManually is true, can not start download")
    return false
  end
  local ResNeedToDownloadList, SizeNeedToDownload, LargestSize = self.PufferTask:GetPreDownloadResListNeedToDownload()
  if ResNeedToDownloadList and #ResNeedToDownloadList > 0 then
    if self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize, bNeedPopupWindowTip) then
      return self:CheckInternetConnectionPuffer(function(this)
        if this.PufferTask:ResumeTask(this.PufferTaskID) then
          Log.Debug("[NRCPreDownloadManager:ResumeDownload] ResumeTask success, taskid:", this.PufferTaskID)
          this.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Downloading
          _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
          _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadStart)
        else
          Log.Error("[NRCPreDownloadManager:ResumeDownload] ResumeTask failed")
        end
      end, SizeNeedToDownload, bNeedPopupWindowTip)
    else
      return false
    end
  else
    Log.Error("[NRCPreDownloadManager:ResumeDownload] ResNeedToDownloadList is nil or empty")
    return false
  end
end

function NRCPreDownloadManager:GetDownloadProgress()
  if not self:IsPreDownloadResEnabled() then
    return 0
  end
  if self.PufferTask then
    if self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Idle then
      local TotalSize = self:GetTotalSize(true)
      if 0 == TotalSize then
        return 0
      end
      local DownloadedSize = self:GetLocalDownloadedSize(true)
      return DownloadedSize / TotalSize
    elseif self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Success then
      return 1
    else
      return self.PufferTask:GetCurrentDownloadProgress()
    end
  else
    Log.Error("[NRCPreDownloadManager:GetDownloadProgress] PufferTask is nil")
  end
  return 0
end

function NRCPreDownloadManager:IsDownloading()
  if not self:IsPreDownloadResEnabled() then
    return
  end
  Log.Debug("[NRCPreDownloadManager:IsDownloading] DownloadStatus: ", self.DownloadStatus)
  return self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Downloading
end

function NRCPreDownloadManager:IfNeedToDownload()
  if not self:IsPreDownloadResEnabled() then
    return false
  end
  if self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Idle then
    if self.bIfNeedToDownload ~= nil then
      return self.bIfNeedToDownload
    end
    local ResNeedToDownloadList, SizeNeedToDownload, LargestSize = self.PufferTask:GetPreDownloadResListNeedToDownload()
    self.bIfNeedToDownload = #ResNeedToDownloadList > 0
    if self.bIfNeedToDownload == false then
      Log.Debug("[NRCPreDownloadManager:IfNeedToDownload] no need to download")
      self.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Success
    end
    return self.bIfNeedToDownload
  else
    return self.DownloadStatus ~= PreDownloadEnum.EPreDownloadStatus.Success
  end
end

function NRCPreDownloadManager:GetDownloadSpeedText()
  local DefaultSpeedText = "0B/S"
  if not self:IsPreDownloadResEnabled() then
    return DefaultSpeedText
  end
  if self.PufferTask then
    return self.PufferTask:GetCurrentSpeed()
  end
  Log.Error("[NRCPreDownloadManager:GetDownloadSpeedText] PufferTask is nil")
  return DefaultSpeedText
end

function NRCPreDownloadManager:SetEnableNetworkListener(bEnable)
  if not self:IsPreDownloadResEnabled() then
    return
  end
  self.bEnableNetworkListener = bEnable
end

function NRCPreDownloadManager:OnDownloadBatchProgress(BatchTaskId, NowSize, TotalSize)
  if not self:IsPreDownloadResEnabled() then
    Log.Error("[NRCPreDownloadManager:OnDownloadBatchProgress] PreDownloadRes is not enabled")
    self:UnregisterEvents()
    return
  end
  if self.PufferTaskID and BatchTaskId == self.PufferTaskID then
    if self.PufferTask then
      local Percent = 0
      if 0 ~= TotalSize then
        Percent = NowSize / TotalSize
      end
      Log.Debug("UpdateUIModule:OnDownloadBatchProgress...", BatchTaskId, Percent, self.PufferTask:GetCurrentSpeed())
      self.DownloadedSize = NowSize
      if self.DownloadStatus ~= PreDownloadEnum.EPreDownloadStatus.Downloading then
        Log.Debug("[NRCPreDownloadManager:OnDownloadBatchProgress] DownloadStatus is not Downloading, do not update UI")
        return
      end
      _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadBatchProgress, Percent, self.PufferTask:FormatBytes(TotalSize), self.PufferTask:FormatBytes(NowSize), self:GetDownloadSpeedText())
    else
      Log.Error("[NRCPreDownloadManager:OnDownloadBatchProgress]PufferTask is nil")
    end
  end
end

function NRCPreDownloadManager:OnPufferDownloadBatchReturn(BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, SingleFileErrorCode)
  if not self:IsPreDownloadResEnabled() then
    Log.Error("[NRCPreDownloadManager:OnPufferDownloadBatchReturn] PreDownloadRes is not enabled")
    self:UnregisterEvents()
    return
  end
  if self.PufferTaskID and BatchTaskId == self.PufferTaskID then
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
    Log.Debug(string.format("[NRCPreDownloadManager:OnPufferDownloadBatchReturn] BatchTaskId:%s, FiledId:%s, IsSuccess:%s, ErrorCode:%s, BatchType:%s, SingleFileErrorCode:%s", BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, SingleFileErrorCode))
    if BatchType == UE.PufferBatchDownloadType.PBT_BatchTask then
      self.PufferTaskID = nil
      if IsSuccess then
        self.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Success
      else
        self.DownloadStatus = PreDownloadEnum.EPreDownloadStatus.Failed
        if self.bPreDownloadPanelActive then
          self:ShowPreDownloadFailedDialog(ErrorCode, SingleFileErrorCode)
        else
          _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadBatchReturn, IsSuccess)
          _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadAutoRetry)
          return
        end
      end
      _G.NRCEventCenter:DispatchEvent(PreDownloadEvents.PreDownloadBatchReturn, IsSuccess)
    end
  end
end

function NRCPreDownloadManager:ShowPreDownloadFailedDialog(ErrorCode, SingleFileErrorCode)
  local PufferErrorCodeDesc = require("Core.Service.GCloud.PufferErrorCodeDesc")
  local ErrorCodeDescContent = PufferErrorCodeDesc:GetDesc(ErrorCode)
  Log.Debug("[NRCPreDownloadManager:ShowPreDownloadFailedDialog] Batch ErrorCodeDesc:", ErrorCodeDescContent)
  if SingleFileErrorCode and 0 ~= SingleFileErrorCode then
    ErrorCodeDescContent = PufferErrorCodeDesc:GetDesc(SingleFileErrorCode)
    Log.Debug("[NRCPreDownloadManager:ShowPreDownloadFailedDialog] File ErrorCodeDesc:", ErrorCodeDescContent)
  end
  local ReportErrorCode
  if SingleFileErrorCode and 0 ~= SingleFileErrorCode then
    ReportErrorCode = SingleFileErrorCode
  else
    ReportErrorCode = ErrorCode
  end
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(ErrorCodeDescContent):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
    if result then
      self:StartDownload(true)
    end
  end):SetButtonText(LuaText.RETRY, LuaText.updateuimodule_42)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function NRCPreDownloadManager:OnPufferNetworkStatusChanged(NewStatus)
  if not self:IsPreDownloadResEnabled() then
    Log.Error("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] PreDownloadRes is not enabled")
    self:UnregisterEvents()
    return
  end
  Log.Debug("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] Receiving network change callback", NewStatus, self.CurrentNetworkStatus or 0)
  if not self.CurrentNetworkStatus then
    self.CurrentNetworkStatus = 0
    Log.Debug("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] set CurrentNetworkStatus to 0")
  end
  local LastNetworkStatus = self.CurrentNetworkStatus
  self.CurrentNetworkStatus = NewStatus
  if not self.bEnableNetworkListener then
    Log.Debug("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] bEnableNetworkListener is false")
    return
  end
  if 0 ~= LastNetworkStatus and 0 == NewStatus then
  elseif 1 ~= LastNetworkStatus and 1 == NewStatus then
    if self.bIgnoreNoWifiNotice then
      Log.Debug("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] bIgnoreNoWifiNotice is true")
      return
    end
    local NetworkType = UE.UNetworkStatics.GetNetworkState()
    if 1 ~= NetworkType then
      Log.Debug("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] network status is already not WWAN")
      return
    end
    if self:PauseDownload() then
      Log.Debug("[NRCPreDownloadManager:OnPufferNetworkStatusChanged] PauseDownload success")
    end
  elseif self.DownloadStatus == PreDownloadEnum.EPreDownloadStatus.Paused then
    self:ResumeDownload()
  end
end

function NRCPreDownloadManager:PufferOpenNoWifiNoticeDialog()
  if self.bPufferOpenNoWifiNoticeDialog then
    return
  end
  self.bPufferOpenNoWifiNoticeDialog = true
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
    self.bPufferOpenNoWifiNoticeDialog = false
    if result then
      self.bIgnoreNoWifiNotice = true
      self:StartDownload(true)
    end
  end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnNetworkStatusTurnToWifi(Context.EAutoCloseOnWifiBtnHandlerType.OK)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function NRCPreDownloadManager:OnPreDownloadPanelActive()
  Log.Debug("[NRCPreDownloadManager:OnPreDownloadPanelActive]")
  self.bPreDownloadPanelActive = true
  self.PufferTask:RestoreSettings()
end

function NRCPreDownloadManager:OnPreDownloadPanelDeactive()
  Log.Debug("[NRCPreDownloadManager:OnPreDownloadPanelDeactive]")
  self.bPreDownloadPanelActive = false
  self:SetSpeedLimitMode()
end

function NRCPreDownloadManager:SetMaxSpeedMode()
  self.PufferTask:RestoreSettings()
end

function NRCPreDownloadManager:IsSpeedLimitMode()
  return self.PufferTask:IsSpeedLimitMode()
end

function NRCPreDownloadManager:SetSpeedLimitMode()
  self.PufferTask:SetSpeedLimitMode()
end

function NRCPreDownloadManager:GetPreDownloadRootPath()
  local PathSegs
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" then
    PathSegs = {
      UE.UNRCStatics.GetFilePathBase(),
      "PreDownload"
    }
  elseif RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    PathSegs = {
      UE.UNRCStatics.GetFilePathBase(),
      "PreDownload"
    }
  else
    PathSegs = {
      UE.UBlueprintPathsLibrary.ProjectDir(),
      "PreDownload"
    }
  end
  local Path = UE.UBlueprintPathsLibrary.Combine(PathSegs)
  if RocoEnv.PLATFORM ~= "PLATFORM_ANDROID" and RocoEnv.PLATFORM ~= "PLATFORM_OPENHARMONY" then
    Path = UE.UNRCStatics.ConvertToAbsolutePath(Path, false)
  end
  if not UE.UNRCStatics.DirectoryExists(Path) then
    UE.UNRCStatics.MakeDirectory(Path)
    Log.Debug("[NRCPreDownloadManager:GetPreDownloadRootPath]MakeDirectory ", Path)
  end
  return Path
end

function NRCPreDownloadManager:GetDolphinRootDir()
  local RootDir = self:GetPreDownloadRootPath()
  local DolphinRootDir = UE.UBlueprintPathsLibrary.Combine({RootDir, "Dolphin"})
  if not UE.UNRCStatics.DirectoryExists(DolphinRootDir) then
    UE.UNRCStatics.MakeDirectory(DolphinRootDir)
    Log.Debug("[NRCPreDownloadManager:GetDolphinRootDir]MakeDirectory ", DolphinRootDir)
  end
  return DolphinRootDir
end

function NRCPreDownloadManager:GetPufferRootDir()
  local RootDir = self:GetPreDownloadRootPath()
  local PufferRootDir = UE.UBlueprintPathsLibrary.Combine({RootDir, "Puffer"})
  if not UE.UNRCStatics.FileExists(PufferRootDir) then
    UE.UNRCStatics.MakeDirectory(PufferRootDir)
    Log.Debug("[NRCPreDownloadManager:GetPufferRootDir]MakeDirectory ", PufferRootDir)
  end
  return PufferRootDir
end

function NRCPreDownloadManager:GetRelativePathToPuffer(Sub)
  return UE.UBlueprintPathsLibrary.Combine({
    self:GetPufferRootDir(),
    Sub
  })
end

return NRCPreDownloadManager

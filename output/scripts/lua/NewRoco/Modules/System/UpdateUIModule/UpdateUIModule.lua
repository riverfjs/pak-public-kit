local UpdateUIModule = NRCModuleBase:Extend("UpdateUIModule")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local NavigationComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.NavigationComponent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local UpdateFsm = require("NewRoco.Modules.System.UpdateUIModule.UpdateFsm")
local UpdateResTask = require("Core.Service.GCloud.Tasks.UpdateResTask")
local UpdateAppTask = require("Core.Service.GCloud.Tasks.UpdateAppTask")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local JsonUtils = require("Common.JsonUtils")
local FsmEnum = require("NewRoco.Modules.Core.Fsm.FsmEnum")
local UpdateStageLocalText = require("NewRoco.Modules.System.UpdateUIModule.UpdateStageLocalText")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")
local CloudGameUtil = require("NewRoco.Modules.System.UpdateUIModule.CloudGameUtil")
local _SoundConfigFilename = "NrcSoundConfig"
local _DLSSConfigFilename = "NrcDLSSConfig"
local PufferPakMountOrder = 1
local NoWifiNotciceMBThreshold = 20
local WhiteListDownloadURL = "https://config.nrc.qq.com/config/WhiteList.txt"
local WhiteListDownloadURLDev = "https://config.nrc.qq.com/config/WhiteListDev.txt"
local PatchRestartReasonCode = {
  GameInstanceIsNil = 0,
  CreatePakReaderFailed = 1,
  WrongDolphinUpdateConfig = 2,
  WrongPatchConfig = 3,
  DownloadPatchConfigTimeOut = 4,
  ReloadError = 5,
  MountPatchFailed = 6,
  LoadShaderPatchFailed = 7,
  PufferTaskTypeError = 8
}

local function GetLastNameFromDotPath(fileName)
  if string.IsNilOrEmpty(fileName) then
    return
  end
  local revStr = string.reverse(fileName)
  local index = string.find(revStr, ".", 1, true)
  if not index then
    return fileName
  elseif 1 == index then
    return
  end
  return string.sub(fileName, -index + 1)
end

local function GetLastNameFromSlashPath(path)
  if string.IsNilOrEmpty(path) then
    return
  end
  local revStr = string.reverse(path)
  local index = string.find(revStr, "/")
  if not index then
    index = string.find(revStr, "\\")
    if not index then
      return path
    end
  end
  if 1 == index then
    return
  end
  return string.sub(path, -index + 1)
end

local function GetRemoveFileNameSuffix(fileName)
  if string.IsNilOrEmpty(fileName) then
    return ""
  end
  local idx = fileName:match(".+()%.%w+$")
  if idx then
    fileName = fileName:sub(1, idx - 1)
  end
  return fileName
end

local EPufferTaskType = {
  None = "None",
  Patch = "Patch",
  EarlyContent = "EarlyContent",
  Base = "Base",
  EarlyContentWithBase = "EarlyContentWithBase"
}

function UpdateUIModule:OnConstruct()
  _G.UpdateUIModuleCmd = reload("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleCmd")
  self.data = self:SetData("UpdateUIModuleData", "NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleData")
  local MainPanelData = _G.NRCPanelRegisterData()
  MainPanelData.panelName = LoginEnum.PanelNames.VideoBackground
  MainPanelData.panelPath = "/Game/NewRoco/Modules/System/UpdateUIModule/Res/UMG_Update_Video"
  MainPanelData.enablePcEsc = false
  self:RegisterPanel(MainPanelData)
  local UIPanelData = _G.NRCPanelRegisterData()
  UIPanelData.panelName = LoginEnum.PanelNames.PreNRCPanel
  UIPanelData.panelPath = "/Game/NewRoco/Modules/System/UpdateUIModule/Res/UMG_Update_UI"
  UIPanelData.enablePcEsc = false
  self:RegisterPanel(UIPanelData)
  local AccountInfoPanelData = _G.NRCPanelRegisterData()
  AccountInfoPanelData.panelName = LoginEnum.PanelNames.AccountInfo
  AccountInfoPanelData.panelPath = "/Game/NewRoco/Modules/System/UpdateUIModule/Res/UMG_Login_AccountInfo.UMG_Login_AccountInfo"
  AccountInfoPanelData.panelLayer = _G.Enum.UILayerType.UI_LAYER_TOP_MARK
  AccountInfoPanelData.enablePcEsc = false
  self:RegisterPanel(AccountInfoPanelData)
  local RepairToolsPanelData = _G.NRCPanelRegisterData()
  RepairToolsPanelData.panelName = "RepairToolsPanel"
  RepairToolsPanelData.panelPath = "/Game/NewRoco/Modules/System/LoginModule/Res/UMG_RepairTools"
  RepairToolsPanelData.panelLayer = _G.Enum.UILayerType.UI_LAYER_POPUP
  RepairToolsPanelData.openAnimName = "In"
  RepairToolsPanelData.closeAnimName = "Out"
  self:RegisterPanel(RepairToolsPanelData)
  self:RegisterCmd(_G.UpdateUIModuleCmd.SetSvrTime, self.SetSvrTime)
  self:RegisterCmd(_G.UpdateUIModuleCmd.SetLocation, self.SetLocation)
  self:RegisterCmd(_G.UpdateUIModuleCmd.SetBattleId, self.SetBattleId)
  self:RegisterCmd(_G.UpdateUIModuleCmd.DebugPlayVideo, self.DebugPlayVideo)
  self:RegisterCmd(_G.UpdateUIModuleCmd.StopPlayVideo, self.StopPlayVideo)
  self.UpdateObserver = require("NewRoco.Modules.System.UpdateUIModule.UpdateObserver")
  self.UpdateObserver:Init()
end

function UpdateUIModule:OnDestruct()
  Log.Warning("UpdateUIModule:OnDestruct")
  if self.UpdateObserver then
    self.UpdateObserver:Uninit()
  end
end

function UpdateUIModule:PlayBGM()
  _G.NRCAudioManager:SetStateByName("Login_Game", "Login", "LoginPanel")
  _G.NRCAudioManager:PlaySound2DAuto(9012, "LoginPanel")
end

function UpdateUIModule:OpenRepairToolsPanel()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  self:OpenPanel("RepairToolsPanel")
end

function UpdateUIModule:OpenUpdateUIPanel()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  self:OpenPanel(LoginEnum.PanelNames.PreNRCPanel)
end

function UpdateUIModule:OnOpenMainPanel(TurnOn)
  if LoadingUIModuleCmd then
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseLoadingUI, 0.5)
  end
  if TurnOn then
    if self:HasPanel(LoginEnum.PanelNames.VideoBackground) then
      _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.UIOpened)
    end
    self:OpenPanel(LoginEnum.PanelNames.VideoBackground)
  else
    self:ClosePanel(LoginEnum.PanelNames.VideoBackground)
  end
end

function UpdateUIModule:ShowUid(TurnOn)
  if self:HasPanel(LoginEnum.PanelNames.AccountInfo) then
    local Panel = self:GetPanel(LoginEnum.PanelNames.AccountInfo)
    if TurnOn then
      Panel:Enable()
      Panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      Panel:RefreshUID()
    else
      Panel:Disable()
    end
  elseif TurnOn then
    self:OpenPanel(LoginEnum.PanelNames.AccountInfo)
    Log.Warning("account info panel not opened")
  end
end

function UpdateUIModule:CleanUp()
  self:ClosePanel(LoginEnum.PanelNames.VideoBackground)
  self:ClosePanel(LoginEnum.PanelNames.PreNRCPanel)
end

function UpdateUIModule:PlayVideo(VideoPath, bLoop, ...)
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  return Panel:PlayVideo(VideoPath, bLoop, ...)
end

function UpdateUIModule:PlayVideoList()
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  return Panel:PlayVideoList()
end

function UpdateUIModule:StartPlayVideoList()
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  Panel:StartPlayVideo()
  local Panel2 = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
  if Panel2 then
    Panel2:HideFixedFrame()
  end
end

function UpdateUIModule:PauseVideoList()
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  Panel:PauseVideo()
end

function UpdateUIModule:StopVideoListMode()
  local panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if panel then
    panel.VideoListMode = false
  end
end

function UpdateUIModule:OnActive()
  self.UpdateFsm = UpdateFsm(self)
  self:InitAudioConfig()
  if RocoEnv.PLATFORM_WINDOWS then
    self:InitDLSSConfig()
  end
  _G.NRCEventCenter:RegisterEvent("UpdateUIModule", self, _G.NRCGlobalEvent.WINDOW_ACTIVATION_CHANGED, self.OnWindowActivationChanged)
end

function UpdateUIModule:InitDLSSConfig()
  local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
  local apiSelectValue = UE4.UNRCQualityLibrary.IsPreferD3D12() and 1 or 0
  if 0 == apiSelectValue then
    DLSSConfig.Type = 0
    DLSSConfig.Graphic = 1
    DLSSConfig.FrameGenerate = 0
    JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
  end
  local DLSSSelectIndex = DLSSConfig.Type or 0
  if 0 == DLSSSelectIndex then
    UE4.UNRCStatics.ExecConsoleCommand("r.Mobile.RenderVelocity 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.Enabled 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 100")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Enable 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.UpscalerOnly 0")
  elseif 1 == DLSSSelectIndex then
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.Enabled 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 100")
    UE4.UNRCStatics.ExecConsoleCommand("r.Mobile.RenderVelocity 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Enable 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.UpscalerOnly 1")
  elseif 2 == DLSSSelectIndex then
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Enable 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.UpscalerOnly 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.Mobile.RenderVelocity 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.Enabled 1")
  end
  local DLSSSelectIndex1 = DLSSConfig.Graphic or 1
  if 0 == DLSSSelectIndex1 then
    if 1 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Quality -1")
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Preset 6")
    elseif 2 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 50")
    end
  elseif 1 == DLSSSelectIndex1 then
    if 1 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Quality 0")
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Preset 6")
    elseif 2 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 57")
    end
  elseif 2 == DLSSSelectIndex1 then
    if 1 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Quality 1")
      UE4.UNRCStatics.ExecConsoleCommand("r.NGX.DLSS.Preset 6")
    elseif 2 == DLSSSelectIndex then
      UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FSR3.ScreenPercentage 67")
    end
  end
  local frameGenerate = DLSSConfig.FrameGenerate or 0
  if 0 == frameGenerate then
    UE4.UNRCStatics.ExecConsoleCommand("r.Upscale.CombineInSlate 1")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FI.Enabled 0")
  elseif 1 == frameGenerate then
    UE4.UNRCStatics.ExecConsoleCommand("r.Upscale.CombineInSlate 0")
    UE4.UNRCStatics.ExecConsoleCommand("r.FidelityFX.FI.Enabled 1")
  end
  local antiAliasing = DLSSConfig.AntiAliasing or 0
  if 1 == antiAliasing then
    UE4.UNRCStatics.ExecConsoleCommand("r.MobileMSAA 1")
  end
end

function UpdateUIModule:InitAudioConfig()
  local soundConfig = JsonUtils.LoadSaved(_SoundConfigFilename, {})
  local value = soundConfig.Backstage_Master_RTPC or 8
  self:SetSoundValue("Backstage_Master_RTPC", value)
  value = soundConfig.Backstage_Music_RTPC or 8
  self:SetSoundValue("Backstage_Music_RTPC", value)
  value = soundConfig.Backstage_SFX_RTPC or 8
  self:SetSoundValue("Backstage_SFX_RTPC", value)
  value = soundConfig.Backstage_Pet_RTPC or 8
  self:SetSoundValue("Backstage_Pet_RTPC", value)
  value = soundConfig.SoundMute or 1
  if 0 == value then
    _G.GlobalConfig.SoundMuteMode = true
  elseif 1 == value then
    _G.GlobalConfig.SoundMuteMode = false
  end
end

function UpdateUIModule:SetSoundValue(soundName, value)
  Log.Debug("UpdateUIModule:SetSoundValue", soundName, value)
  _G.NRCAudioManager:SetGlobalRTPC(soundName, value, 0, "UMG_SystemSettingMain_C:SetSoundValue")
end

function UpdateUIModule:GetReportBeginTypeByDownloadType()
  local TaskType = self.data:GetDownloadingPufferTaskType()
  local ReportType
  if TaskType then
    if TaskType == EPufferTaskType.Patch then
      ReportType = LoginEnum.DownloadReportType.PatchDownloadBegin
    elseif TaskType == EPufferTaskType.EarlyContent then
      ReportType = LoginEnum.DownloadReportType.EarlyContentDownloadBegin
    elseif TaskType == EPufferTaskType.Base then
      ReportType = LoginEnum.DownloadReportType.BaseDownloadBegin
    elseif TaskType == EPufferTaskType.EarlyContentWithBase then
      ReportType = LoginEnum.DownloadReportType.EarlyWithBaseDownloadBegin
    else
      Log.Warning("PufferTaskType has not been implemented:", TaskType)
    end
  end
  return ReportType
end

function UpdateUIModule:GetReportFailTypeByDownloadType()
  local TaskType = self.data:GetDownloadingPufferTaskType()
  local ReportType
  if TaskType then
    if TaskType == EPufferTaskType.Patch then
      ReportType = LoginEnum.DownloadReportType.PatchDownloadFail
    elseif TaskType == EPufferTaskType.EarlyContent then
      ReportType = LoginEnum.DownloadReportType.EarlyContentDownloadFail
    elseif TaskType == EPufferTaskType.Base then
      ReportType = LoginEnum.DownloadReportType.BaseDownloadFail
    elseif TaskType == EPufferTaskType.EarlyContentWithBase then
      ReportType = LoginEnum.DownloadReportType.EarlyWithBaseDownloadFail
    else
      Log.Warning("PufferTaskType has not been implemented:", TaskType)
    end
  end
  return ReportType
end

function UpdateUIModule:CheckInternetConnection(Callback, Caller, SizeNeedToDownload)
  local NetworkType = UE.UNetworkStatics.GetNetworkState()
  if 1 == NetworkType then
    self.CurrentNetworkStatus = 1
    local Module = _G.NRCModuleManager:GetModule("LoginModule")
    if not Module then
      NRCEventCenter:DispatchEvent(LoginModuleEvent.ConnectionPermitted)
      return
    end
    local TargetConditionValue = Module:GetData("LoginData"):GetCondition(LoginEnum.Conditions.IsOnPc)
    if TargetConditionValue then
      NRCEventCenter:DispatchEvent(LoginModuleEvent.ConnectionPermitted)
      return
    end
    if SizeNeedToDownload then
      local SizeNeedToDownloadMB = SizeNeedToDownload / 1024 / 1024
      if SizeNeedToDownloadMB <= NoWifiNotciceMBThreshold then
        Log.Debug("[UpdateUIModule:CheckInternetConnection skip no wifi notice")
        Callback(self)
        return
      end
    end
    local Context = DialogContext()
    Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
      if result then
        Callback(self)
      else
        Log.Warning("Cancel Update")
        local ReportType = self:GetReportFailTypeByDownloadType()
        if ReportType then
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, ReportType, "Reject download because no wifi")
        end
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateSuspend)
      end
    end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    self.CurrentNetworkStatus = NetworkType
    Callback(self)
  end
end

function UpdateUIModule:CheckInternetConnectionPuffer(Callback, Caller, SizeNeedToDownload)
  local NetworkType = UE.UNetworkStatics.GetNetworkState()
  if 1 == NetworkType then
    self.CurrentNetworkStatus = 1
    local Module = _G.NRCModuleManager:GetModule("LoginModule")
    if not Module then
      NRCEventCenter:DispatchEvent(LoginModuleEvent.ConnectionPermitted)
      return
    end
    local TargetConditionValue = Module:GetData("LoginData"):GetCondition(LoginEnum.Conditions.IsOnPc)
    if TargetConditionValue then
      NRCEventCenter:DispatchEvent(LoginModuleEvent.ConnectionPermitted)
      return
    end
    if SizeNeedToDownload then
      local SizeNeedToDownloadMB = SizeNeedToDownload / 1024 / 1024
      if SizeNeedToDownloadMB <= NoWifiNotciceMBThreshold then
        Log.Debug("[UpdateUIModule:CheckInternetConnectionPuffer] skip no wifi notice")
        Callback(self)
        return
      end
    end
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PopWindow)
    local Context = DialogContext()
    Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.CloseWindow)
      if result then
        Callback(self)
      else
        Log.Warning("Cancel Update")
        local ReportType = self:GetReportFailTypeByDownloadType()
        if ReportType then
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, ReportType, "Reject download because no wifi")
        end
        self:SendRetryEventByTaskType(self.data:GetDownloadingPufferTaskType())
      end
    end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    self.CurrentNetworkStatus = NetworkType
    Callback(self)
  end
end

function UpdateUIModule:StartUpdateFsm()
  self.UpdateFsm:Play()
  self:AddEventListener()
end

function UpdateUIModule:AddEventListener()
  self.UpdateFsm:RegisterEvent(FsmEnum.Events.EnterAction, self, self.OnUpdateActionEnter)
  self.UpdateFsm:RegisterEvent(FsmEnum.Events.Stop, self, self.OnUpdateActionExist)
end

function UpdateUIModule:RemoveEventListener()
  self.UpdateFsm:RemoveEvent(FsmEnum.Events.EnterAction, self, self.OnUpdateActionEnter)
  self.UpdateFsm:RemoveEvent(FsmEnum.Events.Stop, self, self.OnUpdateActionExist)
end

function UpdateUIModule:OnUpdateActionEnter(fsm, fsmAction)
  _G.GEMPostManager:GEMPostStepEvent(fsmAction.name)
end

function UpdateUIModule:OnUpdateActionExist(fsmAction)
end

function UpdateUIModule:OnRelogin()
end

function UpdateUIModule:ShowBanner(...)
  LoginUtils.ShowBanner(self, ...)
end

function UpdateUIModule:CloseApp()
  Log.Debug("UpdateUIModule:ClosingApp")
  UE4.UNRCStatics.QuitGame()
end

function UpdateUIModule:RestartApp()
  Log.Debug("UpdateUIModule:Restart")
  UE.UNRCStatics.RestartApp()
end

function UpdateUIModule:ShowPanel(PanelName, TurnOn, Caller, Callback)
  if TurnOn then
    if not self:GetPanelData(PanelName) then
      Log.Error("somehow \230\137\147\229\188\128\228\186\134", PanelName, "\229\143\175\228\187\165\230\138\138\232\191\153\228\184\170\230\138\165\233\148\153\230\136\170\228\184\170\229\155\190\231\187\153\229\188\128\229\143\145\231\156\139\231\156\139")
      Callback(Caller)
      return
    end
    LoginUtils.RegisterCallback(self, Caller, Callback)
    if self:HasPanel(PanelName) then
      LoginUtils.CallAndRemoveCallback(self)
    else
      self:OpenPanel(PanelName, TurnOn, Caller, Callback)
      self.CurrentPanelName = PanelName
    end
  else
    self:ClosePanel(PanelName)
    Callback(Caller)
  end
end

function UpdateUIModule:OnOpenPanelCallback(panelName, panelIndex, isSucc)
  NRCModuleBase.OnOpenPanelCallback(self, panelName, panelIndex, isSucc)
  if panelName == self.CurrentPanelName then
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.UIOpened)
    LoginUtils.CallAndRemoveCallback(self)
  end
end

function UpdateUIModule:ShowRestartGameWindow(ErrorCode)
  local Content = LuaText.updateuimodule_27
  if ErrorCode then
    Content = string.format("%s(%s)", Content, ErrorCode)
  end
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(Content):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK):SetCallback(self, self.RestartApp):SetCloseOnCancel(false):SetButtonText(LuaText.updateuimodule_28, "")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:IsReleaseFormalEnv()
  local bRelease = true
  if not AppMain.launchParams then
    Log.Error("AppMain.launchParams is nil")
  elseif AppMain.launchParams.dolphin_url_key and AppMain.launchParams.dolphin_url_key == "TestPre" then
    bRelease = false
  end
  return bRelease
end

function UpdateUIModule:DownloadUpdateConfig()
  local bRelease = self:IsReleaseFormalEnv()
  local FileName = "CDNUpdateConfig.json"
  local BranchName = AppMain.GetProjectBranch()
  local URL = UE.UHotUpdateUtils.GetUpdateConfigFileURL(bRelease, FileName, BranchName)
  local URLWithTS = URL .. "?t=" .. UE4.UNRCStatics.GetUTCTimestampMS()
  Log.Debug("[UpdateUIModule:DownloadUpdateConfig] download ", URLWithTS)
  local LocalFilePath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    FileName
  })
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    Log.Error("[UpdateUIModule:DownloadUpdateConfig] GameInstance is nil")
    self:SetDefaultUpdateConfig()
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DownloadUpdateConfigDone)
    return
  end
  GameInstance.OnDownloadFileResult:Clear()
  GameInstance.OnDownloadFileResult:Add(GameInstance, function(this, InURL, bSuccess, ErrorCode)
    Log.Debug(string.format("[UpdateUIModule:DownloadUpdateConfig] download %s result: %s ErrorCode:%s", InURL, bSuccess, ErrorCode or "nil"))
    if InURL == URLWithTS then
      self:ApplyCDNUpdateConfig()
    end
  end)
  self.bGetCDNUpdateConfigResult = false
  self.DownloadConfigTimeOutTimer = _G.TimerManager:CreateTimer(self, "DownloadConfigTimeOutTimer", 3, nil, self.OnDownloadUpdateConfigTimeOut, 9999)
  UE4.UNRCStatics.HttpDownloadFile(URLWithTS, LocalFilePath)
end

function UpdateUIModule:OnDownloadUpdateConfigTimeOut()
  Log.Error("[UpdateUIModule:OnDownloadUpdateConfigTimeOut] download timeout")
  self:ApplyCDNUpdateConfig()
end

function UpdateUIModule:SetDefaultUpdateConfig()
  Log.Warning("[UpdateUIModule:SetDefaultUpdateConfig] set default Update config")
  self.data:SetEnableBackgroundDownload(true)
  self.data:SetEnablePreDownloadBasePaks(false)
end

function UpdateUIModule:ApplyCDNUpdateConfig()
  if self.bGetCDNUpdateConfigResult then
    Log.Error("[UpdateUIModule:ApplyCDNUpdateConfig] Invalid Callback")
    return
  end
  self.bGetCDNUpdateConfigResult = true
  _G.TimerManager:RemoveTimer(self.DownloadConfigTimeOutTimer)
  self.DownloadConfigTimeOutTimer = nil
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance.OnDownloadFileResult:Clear()
  end
  Log.Debug("[UpdateUIModule:ApplyCDNUpdateConfig]")
  local UpdateConfig = JsonUtils.LoadSaved("CDNUpdateConfig", nil)
  if UpdateConfig then
    if nil ~= UpdateConfig.EnableBackgroundDownload then
      Log.Debug("[UpdateUIModule:ApplyCDNUpdateConfig] EnableBackgroundDownload: ", UpdateConfig.EnableBackgroundDownload)
      self.data:SetEnableBackgroundDownload(UpdateConfig.EnableBackgroundDownload)
    else
      Log.Warning("[UpdateUIModule:ApplyCDNUpdateConfig] EnableBackgroundDownload is nil, set to true")
      self.data:SetEnableBackgroundDownload(true)
    end
    if nil ~= UpdateConfig.PreDownloadBasePaksEndTimestamp then
      local CurTimeStamp = UE4.UNRCStatics.GetUTCTimestampMS()
      Log.Debug(string.format("[UpdateUIModule:ApplyCDNUpdateConfig] PreDownloadBasePaksEndTimestamp: %s, CurTimeStamp: %s", UpdateConfig.PreDownloadBasePaksEndTimestamp, CurTimeStamp))
      if CurTimeStamp > UpdateConfig.PreDownloadBasePaksEndTimestamp then
        Log.Debug("[UpdateUIModule:ApplyCDNUpdateConfig] SetEnablePreDownloadBasePaks to false")
        self.data:SetEnablePreDownloadBasePaks(false)
      else
        Log.Debug("[UpdateUIModule:ApplyCDNUpdateConfig] SetEnablePreDownloadBasePaks to true")
        self.data:SetEnablePreDownloadBasePaks(true)
      end
    else
      Log.Warning("[UpdateUIModule:ApplyCDNUpdateConfig] PreDownloadBasePaksEndTimestamp is nil, set to false")
      self.data:SetEnablePreDownloadBasePaks(false)
    end
  else
    self:SetDefaultUpdateConfig()
  end
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadUpdateConfigDone)
end

function UpdateUIModule:CheckIfEnableBackgroundDownload()
  if RocoEnv.PLATFORM_WINDOWS or RocoEnv.PLATFORM_OPENHARMONY then
    _G.NRCBackgroundDownloadMgr:SetIsEnableBackgroundDownload(false)
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.RequestPermissionDone)
    return
  end
  local bEnableFromCDN = self.data:GetEnableBackgroundDownload()
  _G.NRCBackgroundDownloadMgr:SetIsEnableBackgroundDownload(bEnableFromCDN)
  if bEnableFromCDN then
    _G.NRCBackgroundDownloadMgr:InitLocalTexts()
  end
  if RocoEnv.PLATFORM_IOS then
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.RequestPermissionDone)
    return
  end
  self:RequestNotificationPermission()
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.RequestPermissionDone)
end

function UpdateUIModule:RequestNotificationPermission()
  if RocoEnv.PLATFORM_ANDROID then
    if UE.UNRCPermissionMgr.IfPermissionGranted(UE4.ENRCPermissionType.Notifications) then
      Log.Debug("[UpdateUIModule:RequestNotificationPermission] permission granted")
    elseif UE.UNRCPermissionMgr.IsFirstTimeRequest(UE4.ENRCPermissionType.Notifications) then
      Log.Debug("[UpdateUIModule:RequestNotificationPermission] first time request, try request")
      UE.UNRCPermissionMgr.AddPermissionRequestRecord(UE4.ENRCPermissionType.Notifications)
      UE.UNRCPermissionMgr.NRCCreateNotificationChannelForPermissionPrompt()
    else
      Log.Debug("[UpdateUIModule:RequestNotificationPermission] not first time request, skip request")
    end
  end
end

function UpdateUIModule:TryRequestNotificationPermission()
  if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
    if UE.UNRCPermissionMgr.IfPermissionGranted(UE4.ENRCPermissionType.Notifications) then
      Log.Debug("[UpdateEIModule:TryRequestNotificationPermission] permission granted")
      _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.RequestPermissionDone)
    elseif UE.UNRCPermissionMgr.IsFirstTimeRequest(UE4.ENRCPermissionType.Notifications) then
      self.RequestPermissionTimeOutTimer = _G.TimerManager:CreateTimer(self, "LoginRequestNotificationPermissionTimeOutTimer", 3, nil, self.OnRequestNotificationPermissionTimeOut, 9999)
      self.NotificationPermissionRequestCode = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.Notifications, SimpleDelegateFactory:CreateCallback(self, self.OnRequestPermissionCallback))
    else
      Log.Debug("[UpdateUIModule:TryRequestNotificationPermission] not first time request, skip request")
      local Panel = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
      if Panel then
        Panel:ShowNotificationButton()
      end
      self:OnRequestNotificationPermissionFinish()
    end
  else
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.RequestPermissionDone)
  end
end

function UpdateUIModule:OnRequestPermissionCallback(bGranted)
  Log.Debug("[UpdateUIModule:TryRequestNotificationPermission] request permission result: ", bGranted)
  self.NotificationPermissionRequestCode = nil
  if not bGranted then
    local Panel = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
    if Panel then
      Panel:ShowNotificationButton()
    end
  end
  self:OnRequestNotificationPermissionFinish()
end

function UpdateUIModule:OnRequestNotificationPermissionTimeOut()
  Log.Error("[UpdateUIModule:TryRequestNotificationPermission] OnRequestNotificationPermissionTimeOut")
  if self.NotificationPermissionRequestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.NotificationPermissionRequestCode)
    self.NotificationPermissionRequestCode = nil
  end
  self:OnRequestNotificationPermissionFinish()
end

function UpdateUIModule:ClearRequestNotificationPermissionTimeOutTimer()
  if self.RequestPermissionTimeOutTimer then
    Log.Debug("[UpdateUIModule:TryRequestNotificationPermission] clear request permission time out timer")
    _G.TimerManager:RemoveTimer(self.RequestPermissionTimeOutTimer)
    self.RequestPermissionTimeOutTimer = nil
  end
end

function UpdateUIModule:OnRequestNotificationPermissionFinish()
  self:ClearRequestNotificationPermissionTimeOutTimer()
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.RequestPermissionDone)
end

function UpdateUIModule:CheckIfResUpdateIsNeeded()
  self.ResUpdateTask = UpdateResTask()
  self.ResUpdateTask.NewVersionDelegate:Add(self, self.OnNewResVersion)
  self.ResUpdateTask.NetworkChangedDelegate:Add(self, self.OnNetworkStatusChanged)
  self.ResUpdateTask.ProgressDelegate:Add(self, self.OnUpdateProgress)
  self.ResUpdateTask.SuccessDelegate:Add(self, self.OnUpdateResSuccess)
  self.ResUpdateTask.ErrorDelegate:Add(self, self.OnUpdateResError)
  self.ResUpdateTask:Init()
  _G.GEMPostManager:GEMPostStepEvent("CheckResUpdate")
  self.ResUpdateTask:StartCheck()
end

function UpdateUIModule:SetProgress(Percent, Hint, Total, Now, Speed, PSOAppendMsg)
  self:ShowCanvas(LoginEnum.CanvasNames.UpdateProgressPanel, true)
  local Panel = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
  if Panel then
    if Hint then
      if string.find(Hint, LuaText.updateuimodule_29) then
        if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
          Hint = Hint .. " (" .. LuaText.Download_All_tips3 .. ")"
        end
        if Speed then
          Hint = Hint .. " " .. tostring(Speed)
        end
        if Now then
          Hint = Hint .. " " .. tostring(Now)
        end
        if Total then
          Hint = Hint .. "/" .. tostring(Total)
        end
      end
      self.LastPercent = math.clamp(Percent, 0, 1)
      self.LastProgressContent = Hint
      if self.PSOAppendMsg then
        Hint = self.PSOAppendMsg .. "\t\t" .. Hint
      end
      Panel:SetProgress(self.LastPercent, Hint)
    else
      self.PSOAppendMsg = PSOAppendMsg
      if self.PSOAppendMsg and self.LastPercent and self.LastProgressContent then
        local HintContent = self.PSOAppendMsg .. "\t\t" .. self.LastProgressContent
        Panel:SetProgress(self.LastPercent, HintContent)
      end
    end
  end
end

function UpdateUIModule:OnUpdateResSuccess(Task, bHasNewResouce)
  Log.Debug("UpdateUIModule:OnUpdateResSuccess", bHasNewResouce)
  _G.GEMPostManager:GEMPostStepEvent("UpdateDolphinRes")
  if self.ResUpdateTask:GetIfVersionRollback() then
    Log.Error("[UpdateUIModule:OnUpdateResSuccess] version rollback, show restart game window")
    self:ShowRestartGameWindow()
    return
  end
  if self.ResUpdateTask:GetIfVersionUpdate() then
    self.bIfVersionUpdate = true
  end
  self.ResUpdateTask:Uninit()
  self.ResUpdateTask = nil
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.UpdateDone)
end

function UpdateUIModule:ResHashCheck()
  if UE.UResVerifyConfigStatics.FilterInvalidFile(true) then
    Log.Debug("[UpdateUIModule:ResHashCheck] ResVerify Success")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.ResVerifySuccess)
  else
    Log.Error("[UpdateUIModule:ResHashCheck] ResVerify Failed")
    local DolphinErrorCodeDesc = require("Core.Service.GCloud.DolphinErrorCodeDesc")
    local ErrorCode = -2
    _G.GEMPostManager:GEMPostStepEvent("UpdateAppSuccess", DolphinErrorCodeDesc:GetDesc(ErrorCode))
    local Context = DialogContext()
    Context:SetTitle(LuaText.updateuimodule_26):SetContent(DolphinErrorCodeDesc:GetDesc(ErrorCode)):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
      if not result then
        self.CloseApp()
      else
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.ResVerifyFailed)
      end
    end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UpdateUIModule:SetPufferDownloadTaskType(Type)
  self.data:ResetDownloadingTaskId()
  self.data:SetDownloadingPufferTaskType(Type)
end

function UpdateUIModule:CheckIfPatchDownloadIsNeeded()
  self:SetPufferDownloadTaskType(EPufferTaskType.None)
  self:RegisterPufferEvents()
  if not _G.PufferUpdateResTask:Init() then
    self:OnPufferInitFailed(-1)
  end
end

function UpdateUIModule:OnNetworkStatusChanged(NewStatus)
  Log.Error("[UpdateUIModule:OnNetworkStatusChanged] Receiving network change callback", NewStatus, self.CurrentNetworkStatus or 0)
  if not self.CurrentNetworkStatus then
    self.CurrentNetworkStatus = 0
    Log.Debug("[UpdateUIModule:OnNetworkStatusChanged] set CurrentNetworkStatus to 0")
  end
  local LastNetworkStatus = self.CurrentNetworkStatus
  self.CurrentNetworkStatus = NewStatus
  if 0 ~= LastNetworkStatus and 0 == NewStatus then
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateInterrupted)
  elseif 2 == LastNetworkStatus and 1 == NewStatus then
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateInterrupted)
  end
end

function UpdateUIModule:OnPufferNetworkStatusChanged(NewStatus)
  Log.Error("[UpdateUIModule:OnPufferNetworkStatusChanged] Receiving network change callback", NewStatus, self.CurrentNetworkStatus or 0)
  if not self.CurrentNetworkStatus then
    self.CurrentNetworkStatus = 0
    Log.Debug("[UpdateUIModule:OnPufferNetworkStatusChanged] set CurrentNetworkStatus to 0")
  end
  local LastNetworkStatus = self.CurrentNetworkStatus
  self.CurrentNetworkStatus = NewStatus
  if self.bPufferOpenNoWifiNoticeDialog then
    Log.Warning("[UpdateUIModule:OnPufferNetworkStatusChanged] self.bPufferOpenNoWifiNoticeDialog = true")
    return
  end
  if 0 ~= LastNetworkStatus and 0 == NewStatus then
  elseif 1 ~= LastNetworkStatus and 1 == NewStatus then
    local NetworkType = UE.UNetworkStatics.GetNetworkState()
    if 1 ~= NetworkType then
      Log.Debug("[UpdateUIModule:OnPufferNetworkStatusChanged] network status is already not WWAN")
      return
    end
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
    local TaskId = self.data:GetDownloadingTaskId()
    if not _G.PufferUpdateResTask:IsTaskDownloading(TaskId) then
      Log.Warning("[UpdateUIModule:OnPufferNetworkStatusChanged] Task is not downloading")
      return
    end
    local ReportType = self:GetReportFailTypeByDownloadType()
    if ReportType then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, ReportType, "Pause download because no wifi", TaskId)
    end
    local TaskType = self.data:GetDownloadingPufferTaskType()
    if TaskType and TaskType ~= EPufferTaskType.None then
      Log.Debug("[UpdateUIModule:OnPufferNetworkStatusChanged] Pause download puffer task, type:", TaskType)
      local bPuaseSuccess = _G.PufferUpdateResTask:PauseTask(TaskId)
      if bPuaseSuccess then
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PufferNoWifi)
      else
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateInterrupted)
      end
    else
      Log.Error("[UpdateUIModule:OnPufferNetworkStatusChanged] get task id failed, retry update")
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateInterrupted)
    end
  end
end

function UpdateUIModule:PufferOpenNoWifiNoticeDialog()
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PopWindow)
  self.bPufferOpenNoWifiNoticeDialog = true
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.CloseWindow)
    self.bPufferOpenNoWifiNoticeDialog = false
    if result then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.ContinuePufferUpdate)
    else
      Log.Warning("Cancel Update")
      self:SendRetryEventByTaskType(self.data:GetDownloadingPufferTaskType())
    end
  end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnNetworkStatusTurnToWifi(Context.EAutoCloseOnWifiBtnHandlerType.OK)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:PufferResumeDownload()
  Log.Debug("[UpdateUIModule:PufferResumeDownload]")
  local TaskType = self.data:GetDownloadingPufferTaskType()
  if TaskType and TaskType ~= EPufferTaskType.None then
    Log.Debug("[UpdateUIModule:PufferOpenNoWifiNoticeDialog] Resume puffer download, type:", TaskType)
    local bSuccess = _G.PufferUpdateResTask:ResumeTask(self.data:GetDownloadingTaskId())
    if bSuccess then
      local ReportType = self:GetReportBeginTypeByDownloadType()
      if ReportType then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, ReportType, self.data:GetDownloadingTaskId())
      end
      _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
      Log.Debug("[UpdateUIModule:PufferOpenNoWifiNoticeDialog] Resume puffer download success, type:", TaskType)
    else
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateInterrupted)
    end
  else
    Log.Error("[UpdateUIModule:PufferOpenNoWifiNoticeDialog] get task id failed, retry update")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateInterrupted)
  end
end

function UpdateUIModule:OnUpdateResError(UpdateTask, CurVersionStage, ErrorCode)
  Log.Error("OnUpdateResError", CurVersionStage, ErrorCode)
  local DolphinErrorCodeDesc = require("Core.Service.GCloud.DolphinErrorCodeDesc")
  _G.GEMPostManager:GEMPostStepEvent("UpdateDolphinRes", DolphinErrorCodeDesc:GetDesc(ErrorCode))
  _G.DelayManager:DelayFrames(1, function()
    self:CancelUpdates()
  end)
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(DolphinErrorCodeDesc:GetDesc(ErrorCode)):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
    if not result then
      self.CloseApp()
    else
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
    end
  end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:OnNewResVersion(UpdateTask, NewVersion)
  if not NewVersion.isNeedUpdating then
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.NoNewVersion)
  else
    self.needDownloadSize = NewVersion.needDownloadSize
    if NewVersion.needDownloadSize then
      Log.Warning("NewVersion.needDownloadSize -- ", NewVersion.needDownloadSize)
      Log.Warning("UpdateTask:FormatBytes(NewVersion.needDownloadSize) -- ", UpdateTask:FormatBytes(NewVersion.needDownloadSize))
      if not self:CheckFreeDiskSpace(NewVersion.needDownloadSize / 1024 / 1024 / 1024) then
        return
      end
    end
    if 0 == NewVersion.needDownloadSize then
      NewVersion.isForcedUpdating = true
    end
    if NewVersion.isForcedUpdating then
      if self.needDownloadSize > 0 then
        self:CheckInternetConnection(function(this)
          if this.ResUpdateTask then
            this.ResUpdateTask:ContinueUpdate(true)
          end
        end, self, self.needDownloadSize)
      elseif self.ResUpdateTask then
        self.ResUpdateTask:ContinueUpdate(true)
      end
    else
      local Title = LuaText.updateuimodule_31
      local Content = LuaText.updateuimodule_32
      local Mode = DialogContext.Mode.OK_CANCEL
      Content = string.format(LuaText.updateuimodule_33, Content, NewVersion.versionNumberOne, NewVersion.versionNumberTwo, NewVersion.versionNumberThree, NewVersion.versionNumberFour)
      Content = string.format(LuaText.updateuimodule_34, Content, UpdateTask:FormatBytes(NewVersion.needDownloadSize))
      local Context = DialogContext()
      Context:SetTitle(Title):SetContent(Content):SetMode(Mode):SetCallback(self, self.OnResUpdateDialogueResult):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
end

function UpdateUIModule:CheckLocalPreDownloadConfig()
  _G.NRCPreDownloadManager:Init()
  _G.NRCPreDownloadManager:CheckLocalPreDownloadConfig()
end

function UpdateUIModule:DownloadPreDownloadConfig()
  _G.NRCPreDownloadManager:DownloadPreDownloadConfig()
end

function UpdateUIModule:DownloadNecessaryPatch()
  self:SetPufferDownloadTaskType(EPufferTaskType.Patch)
  self.NeedToMountPatchList = {}
  self.bNeedToRestartApp = false
  local bHasPatch = _G.PufferDownloadInfo:HasAnyPatch()
  if bHasPatch then
    local NeedToCheckPatchList = {}
    local NeedToDownloadPatchList = {}
    local LargestSize = 0
    local SizeNeedToDownload = 0
    local NonPakPatchList = _G.PufferDownloadInfo:GetNonPakPatchList()
    if NonPakPatchList then
      for _, Path in ipairs(NonPakPatchList) do
        table.insert(NeedToCheckPatchList, Path)
        Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] add non pak patch:", Path)
      end
    end
    local ContentChunkPatchList = _G.PufferDownloadInfo:GetContentChunkPatchList()
    if ContentChunkPatchList then
      for _, Path in ipairs(ContentChunkPatchList) do
        table.insert(NeedToCheckPatchList, Path)
        Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] add content chunk patch:", Path)
        local FullPath = _G.PufferUpdateResTask:GetRelativePathToPuffer(Path)
        if not UE4.UHotUpdateUtils.IsPakMounted(FullPath) then
          table.insert(self.NeedToMountPatchList, FullPath)
          Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] add patch need to mount: ", FullPath)
        end
      end
    end
    for _, FilePath in ipairs(NeedToCheckPatchList) do
      Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] Check File: ", FilePath)
      local Extension = GetLastNameFromDotPath(FilePath)
      local FileId = _G.PufferUpdateResTask:GetFileId(FilePath)
      if FileId then
        local FullPath = _G.PufferUpdateResTask:GetRelativePathToPuffer(FilePath)
        if not _G.PufferUpdateResTask:IsFileReadyByFullPath(FullPath) then
          Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] File Need To Download: ", FilePath)
          if "upipelinecache" == Extension then
            Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] Found PSOPatch, skip downloading because dolphin has been downloaded")
          else
            local FileSize = _G.PufferUpdateResTask:GetFileSizeCompressed(FileId)
            Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] get file size: ", FileSize)
            if FileSize > 0 then
              SizeNeedToDownload = SizeNeedToDownload + FileSize
              if LargestSize < FileSize then
                LargestSize = FileSize
              end
              table.insert(NeedToDownloadPatchList, FilePath)
            else
              Log.Error("[UpdateUIModule:DownloadNecessaryPatch] FileSize is 0: ", FilePath)
            end
          end
        else
          Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] File is ready: ", FilePath)
        end
      else
        Log.Error("[UpdateUIModule:DownloadNecessaryPatch] GetFileId failed: ", FilePath)
        if "upipelinecache" == Extension then
          Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] Found PSOPatch, skip downloading because dolphin has been downloaded")
        else
          table.insert(NeedToDownloadPatchList, FilePath)
        end
      end
    end
    if #NeedToDownloadPatchList > 0 then
      if not self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize) then
        return
      end
      self:CheckInternetConnectionPuffer(function(this)
        local PatchTaskId = _G.PufferUpdateResTask:DownloadBatchListByPakList(NeedToDownloadPatchList)
        if PatchTaskId then
          _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
          _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.Patch, PatchTaskId)
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, LoginEnum.DownloadReportType.PatchDownloadBegin, PatchTaskId)
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "Create Puffer Task Failed")
        end
        this.data:SetDownloadingTaskId(PatchTaskId)
      end, self, SizeNeedToDownload)
    else
      Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] No Patch Need To Download")
      if self.NeedToMountPatchList and #self.NeedToMountPatchList > 0 then
        Log.Error("[UpdateUIModule:DownloadNecessaryPatch] No Patch Need To Download But Need To Mount, it is a bug")
        self:OnPatchUpdateSuccess()
      else
        self:OnPatchUpdateDone()
      end
    end
  else
    if self.bIfVersionUpdate then
      Log.Error("[UpdateUIModule:DownloadNecessaryPatch] No Patch Need To Download But Version Update")
      self:OnPufferInitFailed(-2)
      return
    end
    Log.Debug("[UpdateUIModule:DownloadNecessaryPatch] PatchList is empty")
    self:OnPatchUpdateDone()
  end
end

function UpdateUIModule:InitPSOIfNeed()
  if not self.PSOInitTask then
    self.PSOInitTask = require("NewRoco.Modules.System.UpdateUIModule.PSOInitTask")
  end
  if self.PSOInitTask:IsInited() then
    Log.Debug("[UpdateUIModule:InitPSO] PSOInitTask is inited")
  else
    self.PSOInitTask:StartInitPSO()
  end
end

function UpdateUIModule:CheckIfPreDownloadBasePaksIsNeeded()
  if self.data:GetEnablePreDownloadBasePaks() then
    Log.Debug("[UpdateUIModule:CheckIfPreDownloadBasePaksIsNeeded] EnablePreDownloadBasePaks")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.EnablePreDownloadBasePaks)
  else
    Log.Debug("[UpdateUIModule:CheckIfPreDownloadBasePaksIsNeeded] DisablePreDownloadBasePaks")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DisablePreDownloadBasePaks)
  end
end

function UpdateUIModule:StartPreDownloadBasePaks()
  self:SetPufferDownloadTaskType(EPufferTaskType.EarlyContentWithBase)
  self:InitPSOIfNeed()
  local EarlyContentPakList = _G.PufferDownloadInfo:GetEarlyContentPakList()
  local BasePakList = _G.PufferDownloadInfo:GetBasePakList()
  local AllPakList = {}
  for _, Path in ipairs(EarlyContentPakList) do
    table.insert(AllPakList, Path)
  end
  for _, Path in ipairs(BasePakList) do
    table.insert(AllPakList, Path)
  end
  if AllPakList and #AllPakList > 0 then
    local NeedToDownloadList = {}
    local LargestSize = 0
    local SizeNeedToDownload = 0
    for _, FilePath in ipairs(AllPakList) do
      Log.Debug("[UpdateUIModule:StartPreDownloadBasePaks] Check File: ", FilePath)
      local FileId = _G.PufferUpdateResTask:GetFileId(FilePath)
      if FileId then
        local FullPath = _G.PufferUpdateResTask:GetRelativePathToPuffer(FilePath)
        if not _G.PufferUpdateResTask:IsFileReadyByFullPath(FullPath) then
          Log.Debug("[UpdateUIModule:StartPreDownloadBasePaks] File Need To Download: ", FilePath)
          local FileSize = _G.PufferUpdateResTask:GetFileSizeCompressed(FileId)
          Log.Debug("[UpdateUIModule:StartPreDownloadBasePaks] get file size: ", FileSize)
          if FileSize > 0 then
            SizeNeedToDownload = SizeNeedToDownload + FileSize
            if LargestSize < FileSize then
              LargestSize = FileSize
            end
            table.insert(NeedToDownloadList, FilePath)
          else
            Log.Error("[UpdateUIModule:StartPreDownloadBasePaks] FileSize is 0: ", FilePath)
          end
        else
          Log.Debug("[UpdateUIModule:StartPreDownloadBasePaks] File is ready: ", FilePath)
        end
      else
        Log.Error("[UpdateUIModule:StartPreDownloadBasePaks] GetFileId failed: ", FilePath)
        table.insert(NeedToDownloadList, FilePath)
      end
    end
    if #NeedToDownloadList > 0 then
      if not self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize) then
        return
      end
      self:CheckInternetConnectionPuffer(function(this)
        local EarlyContengWithBasePakTaskId = _G.PufferUpdateResTask:DownloadBatchListByPakList(NeedToDownloadList)
        if EarlyContengWithBasePakTaskId then
          _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.EarlyContentWithBase, EarlyContengWithBasePakTaskId)
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, LoginEnum.DownloadReportType.EarlyWithBaseDownloadBegin, EarlyContengWithBasePakTaskId)
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.EarlyWithBaseDownloadFail, "Create Puffer Task Failed")
        end
        this.data:SetDownloadingTaskId(EarlyContengWithBasePakTaskId)
      end, self, SizeNeedToDownload)
    else
      Log.Debug("[UpdateUIModule:StartPreDownloadBasePaks] No early content Need To Download")
      self:OnEarlyContentWithBasePakUpdateDone()
    end
  else
    Log.Error("[UpdateUIModule:StartPreDownloadBasePaks] No early content Need To Download")
    self:OnPufferInitFailed(-2)
  end
end

function UpdateUIModule:OnEarlyContentWithBasePakUpdateDone()
  Log.Debug("[UpdateUIModule:OnEarlyContentWithBasePakUpdateDone]")
  if not RocoEnv.IS_EDITOR then
    local PakList = _G.PufferDownloadInfo:GetEarlyContentPakListWithPatch()
    if not _G.PufferUpdateResTask:MountPakList(PakList) then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.EarlyWithBaseDownloadFail, "Mount failed")
      Log.Error("[UpdateUIModule:OnEarlyContentWithBasePakUpdateDone] mount failed")
      LoginUtils.ShowPufferGenericErrorDailog(-3, self.CloseApp, function()
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryEarlyContentWithBaseUpdate)
      end)
      return
    end
  end
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PreDownloadBasePaksDone)
end

function UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded()
  self:SetPufferDownloadTaskType(EPufferTaskType.EarlyContent)
  self:InitPSOIfNeed()
  local EarlyContentPakListWithPatch = _G.PufferDownloadInfo:GetEarlyContentPakListWithPatch()
  local bIsNewPlayer = _G.PufferUpdateResTask:IsNeedDownloadBasePaks()
  local ResList
  if bIsNewPlayer then
    ResList = EarlyContentPakListWithPatch
  else
    ResList = {}
    for _, Path in ipairs(EarlyContentPakListWithPatch) do
      table.insert(ResList, Path)
      Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] add early content pak:", Path)
    end
    local BasePakPatch = _G.PufferDownloadInfo:GetBasePatchList()
    for _, Path in ipairs(BasePakPatch) do
      table.insert(ResList, Path)
      Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] add base pak:", Path)
    end
  end
  if ResList and #ResList > 0 then
    local NeedToDownloadList = {}
    local LargestSize = 0
    local SizeNeedToDownload = 0
    for _, FilePath in ipairs(ResList) do
      Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] Check File: ", FilePath)
      local FileId = _G.PufferUpdateResTask:GetFileId(FilePath)
      if FileId then
        local FullPath = _G.PufferUpdateResTask:GetRelativePathToPuffer(FilePath)
        if not _G.PufferUpdateResTask:IsFileReadyByFullPath(FullPath) then
          Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] File Need To Download: ", FilePath)
          local FileSize = _G.PufferUpdateResTask:GetFileSizeCompressed(FileId)
          Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] get file size: ", FileSize)
          if FileSize > 0 then
            SizeNeedToDownload = SizeNeedToDownload + FileSize
            if LargestSize < FileSize then
              LargestSize = FileSize
            end
            table.insert(NeedToDownloadList, FilePath)
          else
            Log.Error("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] FileSize is 0: ", FilePath)
          end
        else
          Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] File is ready: ", FilePath)
        end
      else
        Log.Error("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] GetFileId failed: ", FilePath)
        table.insert(NeedToDownloadList, FilePath)
      end
    end
    if #NeedToDownloadList > 0 then
      if not self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize) then
        return
      end
      self:CheckInternetConnectionPuffer(function(this)
        local EarlyContentTaskId = _G.PufferUpdateResTask:DownloadBatchListByPakList(NeedToDownloadList)
        if EarlyContentTaskId then
          _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
          _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.EarlyContent, EarlyContentTaskId)
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, LoginEnum.DownloadReportType.EarlyContentDownloadBegin, EarlyContentTaskId)
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.EarlyContentDownloadFail, "Create Puffer Task Failed")
        end
        this.data:SetDownloadingTaskId(EarlyContentTaskId)
      end, self, SizeNeedToDownload)
    else
      Log.Debug("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] No early content Need To Download")
      self:OnEarlyContentUpdateDone()
    end
  else
    Log.Error("[UpdateUIModule:CheckIfEarlyContentDownloadIsNeeded] ResList is empty")
    self:OnEarlyContentUpdateDone()
  end
end

function UpdateUIModule:CheckIfBaseResDownloadIsNeeded()
  local bDownloadBaseResAfterLogin = UE4.UNRCStatics.GetBoolFromGGameIni("/Script/NRC.PufferSettings", "DownloadBaseResAfterLogin")
  if bDownloadBaseResAfterLogin then
    self:SetPufferDownloadTaskType(EPufferTaskType.None)
    self:UnRegisterPufferEvents()
    Log.Debug("[UpdateUIModule:CheckIfBaseResDownloadIsNeeded] DownloadBaseResAfterLogin")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DownloadBaseResAfterLogin)
  else
    self:DownloadBasePak()
  end
end

function UpdateUIModule:DownloadBasePak()
  self:SetPufferDownloadTaskType(EPufferTaskType.Base)
  local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListNeedToDownload()
  if NeedToDownloadBasePakList then
    if #NeedToDownloadBasePakList > 0 then
      Log.Debug("[UpdateUIModule:DownloadBasePak] get total file size: ", SizeNeedToDownload)
      if not self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize) then
        return
      end
      self:CheckInternetConnectionPuffer(function(this)
        local BasePakTaskId = _G.PufferUpdateResTask:DownloadBatchListByPakList(NeedToDownloadBasePakList)
        if BasePakTaskId then
          _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.Base, BasePakTaskId)
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, LoginEnum.DownloadReportType.BaseDownloadBegin, BasePakTaskId)
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Create Puffer Task Failed")
        end
        this.data:SetDownloadingTaskId(BasePakTaskId)
      end, self, SizeNeedToDownload)
    else
      Log.Debug("[UpdateUIModule:DownloadBasePak] No Base Pak Need To Download")
      self:PostPufferResAllUpdateDoneEvent()
    end
  else
    self:OnPufferInitFailed(-2)
  end
end

function UpdateUIModule:OnPufferInitProgress(Stage, NowSize, TotalSize)
  local Percent = 0
  if 0 ~= TotalSize then
    Percent = NowSize / TotalSize
  end
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PufferInitProgress, Percent, UpdateStageLocalText.PufferInit)
end

function UpdateUIModule:OnInitReturn(TaskInstance, IsSuccess, ErrorCode)
  if TaskInstance ~= _G.PufferUpdateResTask then
    Log.Error("[UpdateUIModule:OnInitReturn] TaskInstance is not equal to _G.PufferUpdateResTask")
    return
  end
  if IsSuccess then
    self:DownloadNecessaryPatch()
  else
    self:OnPufferInitFailed(ErrorCode)
  end
end

function UpdateUIModule:OnPufferInitFailed(ErrorCode)
  Log.Error("[UpdateUIModule:OnPufferInitFailed] Puffer init error: ", ErrorCode)
  if self.bShowPufferInitFailedDialog then
    Log.Error("Show Puffer Init Failed Dialog Repeatly")
    return
  end
  self.bShowPufferInitFailedDialog = true
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateError)
  local PufferErrorCodeDesc = require("Core.Service.GCloud.PufferErrorCodeDesc")
  _G.GEMPostManager:GEMPostStepEvent("UpdateResSuccess", PufferErrorCodeDesc:GetDesc(ErrorCode))
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(PufferErrorCodeDesc:GetDesc(ErrorCode)):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
    self.bShowPufferInitFailedDialog = false
    if not result then
      self.CloseApp()
    else
      _G.DelayManager:DelayFrames(1, function()
        self:CancelUpdates()
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
      end)
    end
  end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:OnDownloadBatchProgress(BatchTaskId, NowSize, TotalSize)
  local Percent = 0
  if 0 ~= TotalSize then
    Percent = NowSize / TotalSize
  end
  local UpdateTask = _G.PufferUpdateResTask
  Log.Debug("UpdateUIModule:OnDownloadBatchProgress...", BatchTaskId, Percent, UpdateTask:GetCurrentSpeed())
  local LocalText
  local TaskType = self.data:GetDownloadingPufferTaskType()
  if TaskType == EPufferTaskType.Patch then
    LocalText = UpdateStageLocalText.PufferPatchDownloading
  elseif TaskType == EPufferTaskType.EarlyContent then
    LocalText = UpdateStageLocalText.PufferEarlyContentDownloading
  else
    LocalText = UpdateStageLocalText.PufferBasePaksDownloading
  end
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PufferDownloadBatchProgress, Percent, LocalText, UpdateTask:FormatBytes(TotalSize), UpdateTask:FormatBytes(NowSize), UpdateTask:GetCurrentSpeed())
end

function UpdateUIModule:OnPufferDownloadReturn(UpdateTask, TaskId, FiledId, IsSuccess, ErrorCode)
  Log.Error("[UpdateUIModule:OnPufferDownloadReturn] has not been implemented")
  Log.Debug(string.format("[UpdateUIModule:OnPufferDownloadReturn] IsSuccess:%s, ErrorCode:%s", tostring(IsSuccess), ErrorCode))
end

function UpdateUIModule:PostPufferResAllUpdateDoneEvent()
  self:SetPufferDownloadTaskType(EPufferTaskType.None)
  self:UnRegisterPufferEvents()
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.BaseResDownloadDone)
end

function UpdateUIModule:OnPufferDownloadBatchReturn(BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, SingleFileErrorCode)
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  local TaskType = self.data:GetDownloadingPufferTaskType()
  if IsSuccess then
    if TaskType then
      if TaskType == EPufferTaskType.Patch then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadEnd, LoginEnum.DownloadReportType.PatchDownloadEnd, BatchTaskId)
        self:OnPatchUpdateSuccess()
      elseif TaskType == EPufferTaskType.EarlyContent then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadEnd, LoginEnum.DownloadReportType.EarlyContentDownloadEnd, BatchTaskId)
        self:OnEarlyContentUpdateDone()
      elseif TaskType == EPufferTaskType.Base then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadEnd, LoginEnum.DownloadReportType.BaseDownloadEnd, BatchTaskId)
        Log.Warning("[UpdateUIModule:OnPufferDownloadBatchReturn] Base pak download finish")
        self:PostPufferResAllUpdateDoneEvent()
      elseif TaskType == EPufferTaskType.EarlyContentWithBase then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadEnd, LoginEnum.DownloadReportType.EarlyWithBaseDownloadEnd, BatchTaskId)
        self:OnEarlyContentWithBasePakUpdateDone()
      else
        Log.Error("PufferTaskType has not been implemented:", TaskType)
        self:ShowRestartGameWindow(PatchRestartReasonCode.PufferTaskTypeError)
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, string.format("PufferTaskType has not been implemented:%s", TaskType), BatchTaskId)
      end
    else
      Log.Error("PufferTaskType can not be nil!")
      self:ShowRestartGameWindow(PatchRestartReasonCode.PufferTaskTypeError)
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "PufferTaskType can not be nil!", BatchTaskId)
    end
  else
    Log.Error(string.format("[UpdateUIModule:OnPufferDownloadBatchReturn] ErrorCode:%s, BatchType:%s, FiledId:%s", ErrorCode, BatchType, FiledId))
    if BatchType == UE.PufferBatchDownloadType.PBT_BatchTask then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateError)
      local PufferErrorCodeDesc = require("Core.Service.GCloud.PufferErrorCodeDesc")
      local ErrorCodeDescContent = PufferErrorCodeDesc:GetDesc(ErrorCode)
      local ReportErrorCode
      Log.Debug("[UpdateUIModule:OnPufferDownloadBatchReturn] Batch ErrorCodeDesc:", ErrorCodeDescContent)
      if SingleFileErrorCode and 0 ~= SingleFileErrorCode then
        ReportErrorCode = SingleFileErrorCode
        ErrorCodeDescContent = PufferErrorCodeDesc:GetDesc(SingleFileErrorCode)
        Log.Debug("[UpdateUIModule:OnPufferDownloadBatchReturn] File ErrorCodeDesc:", ErrorCodeDescContent)
      else
        ReportErrorCode = ErrorCode
      end
      local ReportErrorReason = string.format("ErrorCode:%s", ReportErrorCode)
      if TaskType and TaskType ~= EPufferTaskType.Patch and TaskType ~= EPufferTaskType.None then
        _G.GEMPostManager:GEMPostStepEvent("PSOAndDownloadStart", ReportErrorReason)
      end
      local ReportType = self:GetReportFailTypeByDownloadType()
      if ReportType then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, ReportType, ReportErrorReason, BatchTaskId)
      end
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PopWindow)
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(ErrorCodeDescContent):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
        if not result then
          self.CloseApp()
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.CloseWindow)
          self:SendRetryEventByTaskType(TaskType)
        end
      end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
end

function UpdateUIModule:SendRetryEventByTaskType(TaskType)
  if TaskType then
    if TaskType == EPufferTaskType.Patch then
      _G.DelayManager:DelayFrames(1, function()
        self:CancelUpdates()
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
      end)
    else
      _G.PufferUpdateResTask:RemoveAllTasks()
      _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
      if TaskType == EPufferTaskType.EarlyContent then
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryEarlyContentUpdate)
      elseif TaskType == EPufferTaskType.Base then
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryBaseUpdate)
      elseif TaskType == EPufferTaskType.EarlyContentWithBase then
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryEarlyContentWithBaseUpdate)
      else
        Log.Error("PufferTaskType has not been implemented:", TaskType)
      end
    end
  end
end

function UpdateUIModule:PopupErrorTipsDialog()
  Log.Debug("\229\141\160\228\189\141\231\148\168Action\239\188\140\231\148\168\228\186\142\233\154\148\231\166\187UpdateError\231\138\182\230\128\129")
end

function UpdateUIModule:MountDownloadedPaks()
  if not RocoEnv.IS_EDITOR then
    local BasePakList = _G.PufferDownloadInfo:GetBasePakListWithPatch()
    if not _G.PufferUpdateResTask:MountPakList(BasePakList) then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Mount Failed")
      Log.Error("[UpdateUIModule:MountDownloadedPaks] mount failed")
      LoginUtils.ShowPufferGenericErrorDailog(-3, self.CloseApp, function()
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryBaseUpdate)
      end)
      return
    end
  end
  _G.GEMPostManager:GEMPostStepEvent("UpdateEndState")
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.MountDownloadedPakDone)
end

function UpdateUIModule:WaitForAllProgressEnd()
  _G.GEMPostManager:GEMPostStepEvent("ResDownloadEnd")
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  self:InitPSOIfNeed()
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.PufferDownloadFinish)
  _G.DataConfigManager:PreLoadBinData()
end

function UpdateUIModule:CheckIfNeedRestratApp()
  if self.bNeedToRestartApp then
    self:ShowRestartGameWindow()
  else
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.NoNeedToRestartApp)
  end
end

function UpdateUIModule:InitPreDownloadPufferTask()
  _G.NRCPreDownloadManager:InitPuffer()
end

function UpdateUIModule:DownloadPatchConfig()
  local bRelease = self:IsReleaseFormalEnv()
  local FileName = "PatchConfig.json"
  local BranchName = AppMain.GetProjectBranch()
  local URL = UE.UHotUpdateUtils.GetUpdateConfigFileURL(bRelease, FileName, BranchName)
  local URLWithTS = URL .. "?t=" .. UE4.UNRCStatics.GetUTCTimestampMS()
  Log.Debug("[UpdateUIModule:DownloadPatchConfig] download ", URLWithTS)
  local LocalFilePath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    FileName
  })
  if not UE.UNRCStatics.DeleteToFile(LocalFilePath) then
    Log.Error("[UpdateUIModule:DownloadPatchConfig] delete local file failed")
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    Log.Error("[UpdateUIModule:DownloadPatchConfig] GameInstance is nil, now ready to restart game")
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "GameInstance is nil, now ready to restart game")
    self:ShowRestartGameWindow(PatchRestartReasonCode.GameInstanceIsNil)
    return
  end
  GameInstance.OnDownloadFileResult:Clear()
  GameInstance.OnDownloadFileResult:Add(GameInstance, function(this, InURL, bSuccess, ErrorCode)
    Log.Debug(string.format("[UpdateUIModule:DownloadPatchConfig] download %s result: %s ErrorCode:%s", InURL, bSuccess, ErrorCode or "nil"))
    if InURL == URLWithTS then
      self:ApplyPatchConfig()
    end
  end)
  self.bGetPatchConfigResult = false
  self.DelayTimeoutTimerId = _G.DelayManager:DelayFrames(1, function()
    self.DownloadPatchConfigTimeOutTimer = _G.TimerManager:CreateTimer(self, "DownloadConfigTimeOutTimer", 10, nil, self.OnDownloadPatchConfigTimeOut, 9999)
  end)
  UE4.UNRCStatics.HttpDownloadFile(URLWithTS, LocalFilePath)
end

function UpdateUIModule:OnDownloadPatchConfigTimeOut()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance.OnDownloadFileResult:Clear()
  end
  Log.Error("[UpdateUIModule:OnDownloadPatchConfigTimeOut] download patch config timeout")
  self.bGetPatchConfigResult = true
  _G.TimerManager:RemoveTimer(self.DownloadPatchConfigTimeOutTimer)
  self.DownloadPatchConfigTimeOutTimer = nil
  self:ShowRestartGameWindow(PatchRestartReasonCode.DownloadPatchConfigTimeOut)
  _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "Download patch config timeout")
end

function UpdateUIModule:ApplyPatchConfig()
  if self.bGetPatchConfigResult then
    Log.Error("[UpdateUIModule:ApplyPatchConfig] Invalid Callback")
    return
  end
  self.bGetPatchConfigResult = true
  if self.DelayTimeoutTimerId then
    Log.Debug("[UpdateUIModule:ApplyPatchConfig] Cancel DelayTimeoutTimer ", self.DelayTimeoutTimerId)
    _G.DelayManager:CancelDelayById(self.DelayTimeoutTimerId)
    self.DelayTimeoutTimerId = nil
  end
  _G.TimerManager:RemoveTimer(self.DownloadPatchConfigTimeOutTimer)
  self.DownloadPatchConfigTimeOutTimer = nil
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance.OnDownloadFileResult:Clear()
  end
  Log.Debug("[UpdateUIModule:ApplyPatchConfig]")
  local PatchConfig = JsonUtils.LoadSaved("PatchConfig", nil)
  if PatchConfig then
    if not string.IsNilOrEmpty(PatchConfig.ForceRestartAppVersion) then
      if PatchConfig.ForceRestartAppVersion == "-1" then
        Log.Debug("[UpdateUIModule:ApplyPatchConfig] ForceRestartAppVersion is -1, no need to restart game")
      else
        local LocalRestartAppVersionRecordFileName = "PatchRestartAppVersionRecord"
        local RestartAppVersionRecord = JsonUtils.LoadSaved(LocalRestartAppVersionRecordFileName, nil)
        if not RestartAppVersionRecord or string.IsNilOrEmpty(RestartAppVersionRecord.RestartAppVersion) then
          JsonUtils.DumpSaved(LocalRestartAppVersionRecordFileName, {
            RestartAppVersion = PatchConfig.ForceRestartAppVersion
          })
          Log.Debug(string.format("[UpdateUIModule:ApplyPatchConfig] Write RestartAppVersionRecord to %s, then ready to restart game", PatchConfig.ForceRestartAppVersion))
          self.bNeedToRestartApp = true
        elseif RestartAppVersionRecord.RestartAppVersion == PatchConfig.ForceRestartAppVersion then
          Log.Debug("[UpdateUIModule:ApplyPatchConfig] RestartAppVersion is the same, no need to restart game")
        else
          JsonUtils.DumpSaved(LocalRestartAppVersionRecordFileName, {
            RestartAppVersion = PatchConfig.ForceRestartAppVersion
          })
          Log.Debug(string.format("[UpdateUIModule:ApplyPatchConfig] Update RestartAppVersionRecord from %s to %s, then ready to restart game", RestartAppVersionRecord.RestartAppVersion, PatchConfig.ForceRestartAppVersion))
          self.bNeedToRestartApp = true
        end
      end
    end
    if _G.AppMain:IsBackToLogin() then
      Log.Error("[UpdateUIModule:ApplyPatchConfig] BackToLogion ForceRestartGame")
      self:ShowRestartGameWindow()
      return
    end
    if PatchConfig.RestartAppRightNow then
      Log.Debug("[UpdateUIModule:ApplyPatchConfig] RestartAppRightNow, then ready to restart game")
      if self.bNeedToRestartApp then
        self:ShowRestartGameWindow()
        return
      else
        Log.Warning("[UpdateUIModule:ApplyPatchConfig] RestartAppRightNow is true but bNeedToRestartApp is false, no need to restart game")
      end
    end
    self.data:SetReloadLuaNeedToRestartApp(PatchConfig.ReloadLuaNeedToRestartApp)
    Log.Debug("[UpdateUIModule:ApplyPatchConfig] ReloadLuaNeedToRestartApp:", PatchConfig.ReloadLuaNeedToRestartApp or "nil")
    if self.bNeedToRestartApp then
      if self:TryMountShaderPatchPak() then
        if not self:LoadShaderPatch() then
          Log.Error("[UpdateUIModule:ApplyPatchConfig] LoadShaderPatch failed")
          self:ShowRestartGameWindow(PatchRestartReasonCode.LoadShaderPatchFailed)
          return
        end
        self:OnPatchUpdateDone()
      end
    else
      self:ProcessingPatch()
    end
  else
    self:ShowRestartGameWindow(PatchRestartReasonCode.WrongPatchConfig)
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "PatchConfig is nil")
  end
end

function UpdateUIModule:TryMountShaderPatchPak()
  Log.Debug("[UpdateUIModule:TryMountShaderPatchPak]")
  local ShaderPatchPakList = _G.PufferDownloadInfo:GetShaderPatchPakList()
  if not _G.PufferUpdateResTask:MountPakList(ShaderPatchPakList) then
    Log.Error("[UpdateUIModule:TryMountShaderPatchPak] mount pak failed, now ready to restart game")
    self:ShowRestartGameWindow(PatchRestartReasonCode.MountPatchFailed)
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "Mount Failed")
    return false
  end
  return true
end

function UpdateUIModule:OnPatchUpdateSuccess()
  Log.Warning("[UpdateUIModule:OnPatchUpdateSuccess]")
  local LatestResVersion = _G.AppMain:GetResVersion()
  JsonUtils.DumpSaved("DolphinVersion", {ResVersion = LatestResVersion})
  Log.Debug("[UpdateUIModule:OnPatchUpdateSuccess] Write LocalResVersion:", LatestResVersion)
  if self.NeedToMountPatchList then
    local DolphinHotUpdateConfig = JsonUtils.LoadSaved("HotUpdateConfig", {RestartAppVersion = ""})
    if not DolphinHotUpdateConfig or string.IsNilOrEmpty(DolphinHotUpdateConfig.RestartAppVersion) then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "RestartAppVersion is nil, now ready to restart game")
      Log.Error("[UpdateUIModule:OnPatchUpdateSuccess] RestartAppVersion is nil, now ready to restart game")
      self:ShowRestartGameWindow(PatchRestartReasonCode.WrongDolphinUpdateConfig)
      return
    elseif DolphinHotUpdateConfig.RestartAppVersion == "-1" then
      Log.Debug("[UpdateUIModule:OnPatchUpdateSuccess] RestartAppVersion is -1, no need to restart game")
    else
      local LocalRestartAppVersionRecordFileName = "RestartAppVersionRecord"
      local RestartAppVersionRecord = JsonUtils.LoadSaved(LocalRestartAppVersionRecordFileName, {RestartAppVersion = ""})
      if not RestartAppVersionRecord or string.IsNilOrEmpty(RestartAppVersionRecord.RestartAppVersion) then
        JsonUtils.DumpSaved(LocalRestartAppVersionRecordFileName, {
          RestartAppVersion = DolphinHotUpdateConfig.RestartAppVersion
        })
        Log.Debug(string.format("[UpdateUIModule:OnPatchUpdateSuccess] Write RestartAppVersionRecord to %s, then ready to restart game", DolphinHotUpdateConfig.RestartAppVersion))
        self.bNeedToRestartApp = true
      elseif RestartAppVersionRecord.RestartAppVersion == DolphinHotUpdateConfig.RestartAppVersion then
        Log.Debug("[UpdateUIModule:OnPatchUpdateSuccess] RestartAppVersion is the same, no need to restart game")
      else
        JsonUtils.DumpSaved(LocalRestartAppVersionRecordFileName, {
          RestartAppVersion = DolphinHotUpdateConfig.RestartAppVersion
        })
        Log.Debug(string.format("[UpdateUIModule:OnPatchUpdateSuccess] Update RestartAppVersionRecord from %s to %s, then ready to restart game", RestartAppVersionRecord.RestartAppVersion, DolphinHotUpdateConfig.RestartAppVersion))
        self.bNeedToRestartApp = true
      end
    end
    self:DownloadPatchConfig()
  else
    Log.Warning("[UpdateUIModule:OnPatchUpdateSuccess] did not find any content patch, go ahead")
    self:OnPatchUpdateDone()
  end
end

function UpdateUIModule:ProcessingPatch()
  local bReloadLuaNeedToRestartApp = self.data:GetReloadLuaNeedToRestartApp()
  local bHasLoadedAsset, bHasError = self:IsPatchHasLoadedAsset(self.NeedToMountPatchList, bReloadLuaNeedToRestartApp)
  if bHasError or bHasLoadedAsset then
    if bHasError then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "CreatePakReader failed")
      Log.Error("[UpdateUIModule:ProcessingPatch] CreatePakReader failed")
      self:ShowRestartGameWindow(PatchRestartReasonCode.CreatePakReaderFailed)
      return
    end
    Log.Error("[UpdateUIModule:ProcessingPatch] update the loaded asset, now ready to restart game")
    self:ShowRestartGameWindow()
  else
    if not _G.PufferUpdateResTask:MountPakList(self.NeedToMountPatchList) then
      Log.Error("[UpdateUIModule:ProcessingPatch] mount pak failed, now ready to restart game")
      self:ShowRestartGameWindow(PatchRestartReasonCode.MountPatchFailed)
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "Mount Failed")
      return
    end
    if table.len(self.FileNameToLoadedLuaPath) > 0 then
      if not self:LoadShaderPatch() then
        Log.Error("[UpdateUIModule:ProcessingPatch] LoadShaderPatch failed")
        self:ShowRestartGameWindow(PatchRestartReasonCode.LoadShaderPatchFailed)
        return
      end
      _G.DelayManager:DelayFrames(1, function()
        Log.Debug("[UpdateUIModule:ProcessingPatch] found loaded lua, now ready to restart lua vm and reload update level")
        self:CancelUpdates(true)
        local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
        if GameInstance then
          local bNeedToReverseImage = true
          local UpdatePanel = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
          if UpdatePanel then
            if RocoEnv.PLATFORM_IOS then
              bNeedToReverseImage = false
              Log.Debug("[UpdateUIModule:ProcessingPatch] bNeedToReverseImage is false")
            end
            GameInstance:LoadAndShowRestartGameMaskUI(UpdatePanel, bNeedToReverseImage, 5, 99999)
          else
            Log.Error("[UpdateUIModule:ProcessingPatch] UpdatePanel is nil, now ready to restart game")
          end
        else
          Log.Error("[UpdateUIModule:ProcessingPatch] GameInstance is nil, now ready to restart game")
        end
        _G.AppMain:BackToLogin(true)
      end)
    else
      self:ReloadUpdatedFiles()
    end
  end
end

function UpdateUIModule:ReloadUpdatedFiles()
  self.bReloadError = false
  self:ReloadConfigTable(self.ToReloadTableList)
  self:LoadShaderPatch()
  if self.bReloadError then
    Log.Error("[UpdateUIModule:ReloadUpdatedFiles] reload error, now ready to restart game")
    self:ShowRestartGameWindow(PatchRestartReasonCode.ReloadError)
  else
    Log.Debug("[UpdateUIModule:ReloadUpdatedFiles] Reload all files done, ready to download base paks if need")
    self:OnPatchUpdateDone()
  end
end

function UpdateUIModule:OnPatchUpdateDone()
  Log.Debug("UpdateUIModule:OnPatchUpdateDone")
  local LocalResVersion = _G.AppMain:GetLocalVersion()
  local CurResVersion = _G.AppMain:GetResVersion()
  if LocalResVersion ~= CurResVersion then
    Log.Debug("[UpdateUIModule:OnPatchUpdateDone] LocalResVersion ~= CurResVersion, rewrite LocalResVersion to ", CurResVersion or "nil")
    JsonUtils.DumpSaved("DolphinVersion", {ResVersion = CurResVersion})
  end
  if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
    _G.NRCBackgroundDownloadMgr:InitLocalTexts()
  end
  require("Hotfix.Patch")
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PatchUpdateDone)
end

function UpdateUIModule:ReloadConfigTable(ToReloadTableList)
  if self.bReloadError then
    return
  end
  if ToReloadTableList then
    for FilePath, _ in pairs(ToReloadTableList) do
      local FileName = GetLastNameFromSlashPath(FilePath)
      local TableFileName = GetRemoveFileNameSuffix(FileName)
      Log.Warning(string.format("[UpdateUIModule:ReloadConfigTable] to reload data config FilePath = %s, FileName = %s, TableFileName = %s", FilePath, FileName, TableFileName))
      local bSuccess = _G.DataConfigManager:ReloadTable(TableFileName)
      if not bSuccess then
        Log.Error("[UpdateUIModule:ReloadConfigTable] Reload table failed. Reason: invalid table name:", TableFileName)
        self.bReloadError = true
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, string.format("Reload table failed: %s", TableFileName))
        return
      end
    end
  else
    Log.Error("[UpdateUIModule:ReloadConfigTable] Reload table failed. Reason: list is nil.")
  end
end

function UpdateUIModule:ReloadIniConfig(IniConfigPathList)
  if self.bReloadError then
    return
  end
  if IniConfigPathList then
    Log.Debug("[UpdateUIModule:ReloadIniConfig] ReloadIniConfig")
    if table.len(IniConfigPathList) > 0 then
      local hasEngine, hasDeviceProfiles, hasGameUserSettings
      for filePath, _ in pairs(IniConfigPathList) do
        local fileName = GetLastNameFromSlashPath(filePath)
        local iniName = GetRemoveFileNameSuffix(fileName)
        Log.Debug(string.format("[UpdateUIModule:ReloadIniConfig] to reload ini filePath = %s, fileName = %s, iniName = %s", filePath, fileName, iniName))
        local strippedConfigFileName = UE4.UHotUpdateUtils.GetStrippedConfigFileName(iniName)
        local result = UE4.UHotUpdateUtils.ReloadIniFile(strippedConfigFileName, filePath)
        Log.Debug(string.format("[UpdateUIModule:ReloadIniConfig] %s ReloadResult = %s", fileName, tostring(result)))
        if not result then
          self.bReloadError = true
          Log.Error("[UpdateUIModule:ReloadIniConfig] reload config error %s", filePath)
          return
        end
        if not hasEngine and "Engine" == strippedConfigFileName then
          hasEngine = true
        elseif not hasDeviceProfiles and "DeviceProfiles" == strippedConfigFileName then
          hasDeviceProfiles = true
        elseif not hasGameUserSettings and "GameUserSettings" == strippedConfigFileName then
          hasGameUserSettings = true
        end
      end
      if hasEngine then
        Log.Warning("[UpdateUIModule:ReloadIniConfig] ReloadCVarSettingsFromIni")
        UE4.UHotUpdateUtils.ReloadCVarSettingsFromIni()
      end
      if hasDeviceProfiles then
        Log.Warning("[UpdateUIModule:ReloadIniConfig] ReloadDeviceProfiles")
        UE4.UHotUpdateUtils.ReloadDeviceProfiles()
      end
      if hasGameUserSettings then
        Log.Warning("[UpdateUIModule:ReloadIniConfig] ReloadGameUserSettings")
        UE4.UHotUpdateUtils.ReloadGameUserSettings()
      end
      if UE.UNRCQualityLibrary.HotReload then
        Log.Debug("[UpdateUIModule:ReloadIniConfig] ReloadQualitySettings")
        UE.UNRCQualityLibrary.HotReload()
      end
    else
      Log.Warning("[UpdateUIModule:ReloadConfigTable] no ini files need to reload")
    end
  else
    Log.Error("[UpdateUIModule:ReloadIniConfig] Reload config failed. Reason: list is nil.")
  end
end

function UpdateUIModule:LoadShaderPatch()
  if self.bReloadError then
    Log.Error("[UpdateUIModule:LoadShaderPatch] bReloadError is true, skip load shader patch")
    return false
  end
  local ShaderFolder
  if RocoEnv.PLATFORM_IOS then
    ShaderFolder = UE.UBlueprintPathsLibrary.Combine({
      UE.UBlueprintPathsLibrary.ProjectSavedDir(),
      "Puffer",
      "Metal"
    })
  else
    ShaderFolder = UE.UBlueprintPathsLibrary.ProjectContentDir()
  end
  local NRCResult = UE.UHotUpdateUtils.OpenShaderPatchLibrary("NRC", ShaderFolder)
  Log.Warning("Open NRC", NRCResult and "Success" or "Failed")
  if not NRCResult then
    self.bReloadError = true
  end
  local ShaderPatches = _G.PufferDownloadInfo:GetShaderPatchList()
  if ShaderPatches then
    for k, v in ipairs(ShaderPatches) do
      NRCResult = UE.UHotUpdateUtils.OpenShaderPatchLibrary(v, ShaderFolder)
      Log.Warning("Open " .. v, NRCResult and "Success" or "Failed")
      if not NRCResult then
        self.bReloadError = true
        break
      end
    end
  end
  if self.bReloadError then
    Log.Error("[UpdateUIModule:LoadShaderPatch] load shader patch failed")
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.PatchDownloadFail, "Reload shader patch failed")
    return false
  end
  return true
end

function UpdateUIModule:MountPatchManually(PakPathList)
  if not PakPathList then
    return false
  end
  for _, Path in ipairs(PakPathList) do
    local bSuccess = UE4.UHotUpdateUtils.MountPak(Path, PufferPakMountOrder)
    Log.Debug(string.format("[UpdateUIModule:MountPatchManually] Mount %s, bSuccess: %s", Path, tostring(bSuccess)))
    if not bSuccess then
      Log.Error(string.format("[UpdateUIModule:MountPatchManually] Mount patch %s failed", Path))
      return false
    end
  end
  return true
end

function UpdateUIModule:IsPatchHasLoadedAsset(PakPathList, bReloadLuaNeedToRestartApp)
  if not PakPathList then
    Log.Error("[UpdateUIModule:IsPatchHasLoadedAsset] PakPathList is nil")
    return true
  end
  self.ToReloadTableList = {}
  self.ToReloadConfigList = {}
  self.FileNameToLoadedLuaPath = {}
  local ExtensionVisitSet = {}
  local bHasLoadedAsset = false
  local bHasError = false
  for _, Path in ipairs(PakPathList) do
    Log.Debug(string.format("[UpdateUIModule:IsPatchHasLoadedAsset] start checking pakName: %s", Path))
    local Reader = UE4.UHotUpdateUtils.CreatePakReader(Path)
    if Reader then
      local EntryInfoArray = Reader:GetPakIndex()
      local MountPoint = Reader:GetMountPoint()
      Log.Debug("[UpdateUIModule:IsPatchHasLoadedAsset] GetMountPoint:", MountPoint)
      Reader:Close()
      for i = 1, EntryInfoArray:Length() do
        local EntryInfo = EntryInfoArray:GetRef(i)
        local FilePath = EntryInfo.FileName or "nil"
        local bDeleteRecord = EntryInfo.bIsDeleteRecord
        if bDeleteRecord then
          Log.Debug(string.format("[UpdateUIModule:IsPatchHasLoadedAsset] %s is a delete record.", FilePath))
        else
          local Extension = GetLastNameFromDotPath(FilePath)
          Log.Debug("[UpdateUIModule:IsPatchHasLoadedAsset] FilePath:", FilePath)
          Log.Debug("[UpdateUIModule:IsPatchHasLoadedAsset] GetLastNameFromDotPath: ", Extension)
          if "lua" == Extension or "luac" == Extension then
            local SysPath = MountPoint .. EntryInfo.FileName
            local PureSysPath = GetRemoveFileNameSuffix(SysPath)
            
            local function ExtractPathAfterScriptFunc(fullPath)
              local patterns = {"ScriptC/", "Script/"}
              for _, pattern in ipairs(patterns) do
                local startPos, endPos = string.find(fullPath, pattern)
                if startPos then
                  return string.sub(fullPath, endPos + 1)
                end
              end
              return fullPath
            end
            
            local FileName = ExtractPathAfterScriptFunc(PureSysPath)
            if self:IsLuaLoaded(FileName) then
              Log.Debug("[UpdateUIModule][IsPatchHasLoadedAsset] found loaded lua file, FullPath = ", SysPath)
              if bReloadLuaNeedToRestartApp then
                bHasLoadedAsset = true
                Log.Debug("[UpdateUIModule][IsPatchHasLoadedAsset] update loaded lua need to restart app.")
                return bHasLoadedAsset, bHasError
              end
            end
          elseif "bytes" == Extension then
            local FileName = GetLastNameFromSlashPath(FilePath)
            FileName = GetRemoveFileNameSuffix(FileName)
            if not self.ToReloadTableList[FileName] then
              self.ToReloadTableList[FileName] = 1
              Log.Debug("[UpdateUIModule][IsPatchHasLoadedAsset] add config table to reload, FilePath = ", FilePath)
            end
          elseif "ini" == Extension then
          elseif "upipelinecache" == Extension then
            Log.Warning("[UpdateUIModule][IsPatchHasLoadedAsset] Found PSO Patch ", FilePath)
          elseif "ushaderbytecode" == Extension then
            Log.Debug("[UpdateUIModule][IsPatchHasLoadedAsset] Found Shader Patch ", FilePath)
            local FileName = GetLastNameFromSlashPath(FilePath)
            if string.find(FileName, "Global") then
              Log.Warning("[UpdateUIModule][IsPatchHasLoadedAsset] Found Global Shader Patch ", FilePath)
              bHasLoadedAsset = true
              return bHasLoadedAsset, bHasError
            end
          elseif string.sub(Extension, 1, 1) == "u" then
          elseif not ExtensionVisitSet[Extension] then
            ExtensionVisitSet[Extension] = 1
            Log.Warning(string.format("[UpdateUIModule][IsPatchHasLoadedAsset] %s reload is not implemented", Extension))
          end
        end
      end
    else
      bHasError = true
      Log.Error(string.format("[UpdateUIModule][IsPatchHasLoadedAsset] CreatePakReader failed! pakName: %s", Path))
      break
    end
  end
  return bHasLoadedAsset, bHasError
end

function UpdateUIModule:CheckHasBuildLoadedLuaMap()
  if not self.bHasLoadedLuaTable then
    self.bHasLoadedLuaTable = true
    self.LoadedLuaNames = {}
    for Path, _ in pairs(package.loaded) do
      local FileName = GetLastNameFromSlashPath(Path)
      if string.IsNilOrEmpty(FileName) or FileName == Path then
        FileName = GetLastNameFromDotPath(Path)
      end
      if string.IsNilOrEmpty(FileName) then
        Log.Warning(string.format("[UpdateUIModule:CheckHasBuildLoadedLuaMap] invalid path: %s", Path))
        self.LoadedLuaNames[Path] = Path
      else
        Log.Warning(string.format("[UpdateUIModule:CheckHasBuildLoadedLuaMap] %s has been Loaded, path: %s", FileName, Path))
        self.LoadedLuaNames[FileName] = Path
      end
    end
  end
end

function UpdateUIModule:IsLuaLoaded(FileName)
  if not string.IsNilOrEmpty(FileName) then
    if package.loaded[FileName] then
      self.FileNameToLoadedLuaPath[FileName] = FileName
      Log.Debug(string.format("[UpdateUIModule][IsLuaLoaded] %s has been Loaded", FileName))
      return true
    else
      local FileNameReplaceDot = string.gsub(FileName, "/", ".")
      if package.loaded[FileNameReplaceDot] then
        self.FileNameToLoadedLuaPath[FileName] = FileNameReplaceDot
        Log.Debug(string.format("[UpdateUIModule][IsLuaLoaded] %s has been Loaded", FileNameReplaceDot))
        return true
      else
        Log.Debug(string.format("[UpdateUIModule][IsLuaLoaded] %s hasn't yet been loaded", FileNameReplaceDot))
      end
    end
  end
  return false
end

function UpdateUIModule:CheckHasBuildLoadedUPackageMap()
  if not self.bHasLoadedUPackageMap then
    self.bHasLoadedUPackageMap = true
    self.LoadedUPackagesPath = {}
    local LoadedPackagesPath = UE4.UNRCStatics.GetAllLoadedPackagesPath()
    if LoadedPackagesPath then
      local PreloadAssetsWhiteListMap = require("NewRoco/Modules/System/UpdateUIModule/PreloadAssetsWhiteList")
      for path, _ in pairs(PreloadAssetsWhiteListMap) do
        Log.Debug("[UpdateUIModule][CheckHasBuildLoadedUPackageMap] PreloadAssetsWhiteList: path = ", path)
      end
      for i = 1, LoadedPackagesPath:Length() do
        local Path = LoadedPackagesPath:GetRef(i)
        if not string.IsNilOrEmpty(Path) and not PreloadAssetsWhiteListMap[Path] then
          self.LoadedUPackagesPath[Path] = 1
          Log.Debug(string.format("[UpdateUIModule][CheckHasBuildLoadedUPackageMap] %s has been Loaded", Path))
        end
      end
    end
  end
end

function UpdateUIModule:IsAssetLoaded(AssetPath)
  if not string.IsNilOrEmpty(AssetPath) then
    if self.LoadedUPackagesPath and self.LoadedUPackagesPath[AssetPath] then
      Log.Warning(string.format("[UpdateUIModule][IsAssetLoaded] %s has been Loaded", AssetPath))
      return true
    else
      Log.Warning(string.format("[UpdateUIModule][IsAssetLoaded] %s hasn't yet been loaded", AssetPath))
    end
  end
  return false
end

function UpdateUIModule:WriteLoadedPackagesJson()
  self:CheckHasBuildLoadedUPackageMap()
  local AllPackageList = {}
  for path, _ in pairs(self.LoadedUPackagesPath) do
    table.insert(AllPackageList, path)
  end
  JsonUtils.DumpSaved("LoadedUPackages.json", AllPackageList)
end

function UpdateUIModule:OnEarlyContentUpdateDone()
  if not RocoEnv.IS_EDITOR then
    local PakList = _G.PufferDownloadInfo:GetEarlyContentPakListWithPatch()
    if not _G.PufferUpdateResTask:MountPakList(PakList) then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.EarlyContentDownloadFail, "Mount Failed")
      Log.Error("[UpdateUIModule:OnEarlyContentUpdateDone] mount failed")
      LoginUtils.ShowPufferGenericErrorDailog(-3, self.CloseApp, function()
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryEarlyContentUpdate)
      end)
      return
    end
  end
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.EarlyContentUpdateDone)
end

function UpdateUIModule:CheckFreeDiskSpace(LimitSpace)
  Log.Warning("CheckFreeDiskSpace -- ", LimitSpace)
  local FreeDiskSpace = UE.UNRCStatics.GetFreeDiskSpace()
  if FreeDiskSpace >= 0 and FreeDiskSpace < 2 * LimitSpace * 1024 then
    self:CancelUpdates()
    local ShowRet = CloudGameUtil:TryShowCloudGameDialog(LuaText.cloudgame_disk_space_tips, true)
    if not ShowRet then
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(string.format(LuaText.free_disk_space_check_tips, 2 * LimitSpace)):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
        if not result then
          self.CloseApp()
        else
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
        end
      end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return false
  end
  return true
end

function UpdateUIModule:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize)
  Log.Debug(string.format("[UpdateUIModule:CheckPufferFreeDiskSpace] get total file size:%s largestSize:%s ", SizeNeedToDownload, LargestSize))
  local FreeDiskSpace = UE.UNRCStatics.GetFreeDiskSpace()
  Log.Debug("[UpdateUIModule:CheckPufferFreeDiskSpace] FreeDiskSpace:", FreeDiskSpace)
  local BytesRequired = SizeNeedToDownload + LargestSize * 2
  local RealLimitSpace = BytesRequired / 1024 / 1024
  Log.Debug("[UpdateUIModule:CheckPufferFreeDiskSpace] RealLimitSpace:", RealLimitSpace)
  if FreeDiskSpace >= 0 and FreeDiskSpace < RealLimitSpace then
    local ReportType = self:GetReportFailTypeByDownloadType()
    if ReportType then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, ReportType, "No Free Disk Space")
    end
    local LimitSpace = BytesRequired / 1000 / 1000 / 1000
    local ShowRet = CloudGameUtil:TryShowCloudGameDialog(LuaText.cloudgame_disk_space_tips, true)
    if not ShowRet then
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(string.format(LuaText.free_disk_space_check_tips, LimitSpace)):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
        if not result then
          self.CloseApp()
        else
          self:SendRetryEventByTaskType(self.data:GetDownloadingPufferTaskType())
        end
      end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return false
  end
  return true
end

function UpdateUIModule:OnResUpdateDialogueResult(result)
  if result then
    if self.needDownloadSize > 0 then
      self:CheckInternetConnection(function(this)
        _G.GEMPostManager:GEMPostStepEvent("BeginResUpdate")
        if this.ResUpdateTask then
          this.ResUpdateTask:ContinueUpdate(true)
        end
      end, self, self.needDownloadSize)
    else
      self.ResUpdateTask:ContinueUpdate(true)
    end
  else
    NRCEventCenter:DispatchEvent(LoginModuleEvent.NoNewVersion)
  end
end

function UpdateUIModule:CancelUpdates(bReleasePuffer)
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  self:SetPufferDownloadTaskType(EPufferTaskType.None)
  if self.AppUpdateTask then
    self.AppUpdateTask:Uninit()
    self.AppUpdateTask = nil
  end
  if self.ResUpdateTask then
    self.ResUpdateTask:Uninit()
    self.ResUpdateTask = nil
    self.SourceExtract = false
  end
  if _G.PufferUpdateResTask then
    self:UnRegisterPufferEvents()
    _G.PufferUpdateResTask:RemoveAllTasks()
    if bReleasePuffer then
      Log.Debug("[UpdateUIModule:CancelUpdates] release puffer")
      _G.PufferUpdateResTask:Uninit()
    end
  end
end

function UpdateUIModule:RegisterPufferEvents()
  _G.NRCEventCenter:RegisterEvent("UpdateUIModule", self, NRCGlobalEvent.OnPufferInitReturn, self.OnInitReturn)
  _G.NRCEventCenter:RegisterEvent("UpdateUIModule", self, NRCGlobalEvent.OnPufferInitProgress, self.OnPufferInitProgress)
  _G.NRCEventCenter:RegisterEvent("UpdateUIModule", self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnDownloadBatchProgress)
  _G.NRCEventCenter:RegisterEvent("UpdateUIModule", self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:RegisterEvent("UpdateUIModule", self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
end

function UpdateUIModule:UnRegisterPufferEvents()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferInitReturn, self.OnInitReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferInitProgress, self.OnPufferInitProgress)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnDownloadBatchProgress)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
end

function UpdateUIModule:CheckIfAppUpdateIsNeeded()
  if RocoEnv.PLATFORM_ANDROID and _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
    local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE4.ENRCPermissionType.Notifications)
    if bGranted then
      Log.Debug("[UpdateUIModule:CheckIfAppUpdateIsNeeded] permission granted")
    else
      Log.Debug("[UpdateUIModule:CheckIfAppUpdateIsNeeded] permission not granted")
      local Panel = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
      if Panel then
        Panel:ShowNotificationButton()
      end
    end
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance:UnloadRestartMaskUI()
  end
  _G.GEMPostManager:GEMPostStepEvent("UpdateAppAndRes")
  self.AppUpdateTask = UpdateAppTask()
  self.AppUpdateTask.NewVersionDelegate:Add(self, self.OnNewAppVersion)
  self.AppUpdateTask.ProgressDelegate:Add(self, self.OnUpdateProgress)
  self.AppUpdateTask.NetworkChangedDelegate:Add(self, self.OnNetworkStatusChanged)
  self.AppUpdateTask.SuccessDelegate:Add(self, self.OnUpdateAppSuccess)
  self.AppUpdateTask.ErrorDelegate:Add(self, self.OnUpdateAppError)
  self.AppUpdateTask:Init()
  _G.GEMPostManager:GEMPostStepEvent("CheckAppUpdate")
  self.AppUpdateTask:StartCheck()
end

function UpdateUIModule:OnNewAppVersion(UpdateTask, NewVersion)
  Log.Warning("App\230\156\137\230\150\176\231\137\136\230\156\172", NewVersion.versionNumberOne, NewVersion.versionNumberTwo, NewVersion.versionNumberThree, NewVersion.versionNumberFour, NewVersion.needDownloadSize)
  if not NewVersion.isNeedUpdating then
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.NoNewVersion)
  else
    if NewVersion.needDownloadSize then
      Log.Warning("NewVersion.needDownloadSize -- ", NewVersion.needDownloadSize)
      Log.Warning("UpdateTask:FormatBytes(NewVersion.needDownloadSize) -- ", UpdateTask:FormatBytes(NewVersion.needDownloadSize))
      if not self:CheckFreeDiskSpace(NewVersion.needDownloadSize / 1024 / 1024 / 1024) then
        return
      end
    end
    self.AppNeedDownloadSize = NewVersion.needDownloadSize
    if NewVersion.isForcedUpdating then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.AppNeedUpdate)
    elseif _G.AppMain:GetFormalPipeline() then
      local Title = LuaText.updateuimodule_35
      local Content = LuaText.updateuimodule_36
      local Mode = DialogContext.Mode.OK_CANCEL
      Content = string.format(LuaText.updateuimodule_33, Content, NewVersion.versionNumberOne, NewVersion.versionNumberTwo, NewVersion.versionNumberThree, NewVersion.versionNumberFour)
      if NewVersion.needDownloadSize > 0 then
        Content = string.format(LuaText.updateuimodule_34, Content, UpdateTask:FormatBytes(NewVersion.needDownloadSize))
      end
      local Context = DialogContext()
      Context:SetTitle(Title):SetContent(Content):SetMode(Mode):SetCallback(self, self.OnAppUpdateDialogueResult):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    else
      Log.Debug("[UpdateUIModule:OnNewAppVersion] App is not formal pipeline, skip app update")
      NRCEventCenter:DispatchEvent(LoginModuleEvent.NoNewVersion)
    end
  end
end

function UpdateUIModule:OnAppUpdateDialogueResult(result)
  if result then
    _G.GEMPostManager:GEMPostStepEvent("BeginAppUpdate")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.AppNeedUpdate)
  else
    Log.Debug("app update false")
    NRCEventCenter:DispatchEvent(LoginModuleEvent.NoNewVersion)
  end
end

function UpdateUIModule:OnUpdateProgress(UpdateTask, Stage, Total, Now)
  local Percent = 0
  if 0 ~= Total then
    Percent = Now / Total
  end
  if Stage == UE.DolphinUpdateStage.VS_SourceExtract then
    Log.Debug("Source extract...")
    self.SourceExtract = true
  end
  local HintContent = UpdateStageLocalText.DolphinAppCheckVersion
  if 72 == Stage then
    _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.App, -1)
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
    HintContent = UpdateStageLocalText.DolphinDiffApkDownloading
  elseif 73 == Stage then
    _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.App, -1)
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
    HintContent = UpdateStageLocalText.DolphinApkDownloading
  elseif 78 == Stage then
    HintContent = UpdateStageLocalText.DolphinDiffApkMerge
  end
  Log.Debug("UpdateUIModule:SetProgress...", Stage, Percent, UpdateTask:GetAverageSpeed(), UpdateTask:GetCurrentSpeed())
  self:SetProgress(Percent, HintContent, UpdateTask:FormatBytes(Total), UpdateTask:FormatBytes(Now), UpdateTask:GetCurrentSpeed())
end

function UpdateUIModule:ShowInstallAndroidApkConfirmPopUpWindow()
  local Title = LuaText.updateuimodule_37
  local Content = LuaText.updateuimodule_38
  local Mode = DialogContext.Mode.OK
  local Context = DialogContext()
  Context:SetTitle(Title):SetContent(Content):SetMode(Mode):SetCallback(self, self.InstallAndroidAPK):SetCloseOnOK(false):SetButtonText(LuaText.YES, LuaText.NO)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:InstallAndroidAPK()
  self:ShowInstallAndroidApkConfirmPopUpWindow()
  if self.AppUpdateTask then
    self.AppUpdateTask:InstallAPK()
  end
end

function UpdateUIModule:OnUpdateAppSuccess(Task, NeedReinstallApp)
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  Log.Warning("UpdateUIModule:OnUpdateAppSuccess", NeedReinstallApp)
  _G.GEMPostManager:GEMPostStepEvent("UpdateAppSuccess")
  if NeedReinstallApp then
    self.AppUpdateTask = Task
    self:ShowInstallAndroidApkConfirmPopUpWindow()
  else
    if self.AppUpdateTask then
      self.AppUpdateTask:Uninit()
      self.AppUpdateTask = nil
    end
    NRCEventCenter:DispatchEvent(LoginModuleEvent.NoNewVersion)
  end
end

function UpdateUIModule:OnUpdateAppError(UpdateTask, CurVersionStage, ErrorCode)
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  Log.Error("OnUpdateAppError", CurVersionStage, ErrorCode)
  local DolphinErrorCodeDesc = require("Core.Service.GCloud.DolphinErrorCodeDesc")
  _G.GEMPostManager:GEMPostStepEvent("UpdateAppSuccess", DolphinErrorCodeDesc:GetDesc(ErrorCode))
  _G.DelayManager:DelayFrames(1, function()
    self:CancelUpdates()
  end)
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(DolphinErrorCodeDesc:GetDesc(ErrorCode)):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
    if not result then
      self.CloseApp()
    else
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
    end
  end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:StartUpdate()
  if self.UpdateTask then
    UpdateTask:ContinueUpdate(true)
  else
  end
end

function UpdateUIModule:ShowBlackBackground(InAlpha)
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  Panel:SetBlackScreenAlpha(InAlpha)
end

function UpdateUIModule:ShowPopUpWindow(OnlyConfirm, Title, Content, BtnRight, BtnLeft)
  local Mode = DialogContext.Mode.OK_CANCEL
  if OnlyConfirm then
    Mode = DialogContext.Mode.OK
  end
  local Context = DialogContext()
  Context:SetTitle(Title):SetContent(Content):SetMode(Mode):SetCallback(self, function(this, result)
    if result then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PopUpWindowConfirm)
    else
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PopUpWindowCancel)
    end
  end):SetButtonText(BtnRight or LuaText.YES, BtnLeft or LuaText.NO):SetCloseOnCancel(true)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:GetMainLoginFsm()
  return self.UpdateFsm
end

function UpdateUIModule:EnterLoginMode()
  Log.Debug("UpdateUIModule:EnterLoginMode")
  xpcall(function()
    if self:HasPanel("RepairToolsPanel") or self:IsPanelInOpening("RepairToolsPanel") then
      self:ClosePanel("RepairToolsPanel")
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
    end
  end, function(err)
    self:LogError(err)
  end)
  _G.NRCModeManager:ActiveMode("LoginMode")
end

function UpdateUIModule:ShowCanvas(CanvasName, TurnOn, CompleteEvent)
  local Panel = self:GetPanel(LoginEnum.PanelNames.PreNRCPanel)
  if Panel then
    Panel:ShowCanvas(CanvasName, TurnOn, CompleteEvent)
  end
end

function UpdateUIModule:UpdateIOSApp()
  Log.Debug("UpdateIOSApp")
  local Error = UE4.UNRCStatics.LaunchURL("https://apps.apple.com/app/id6478654994")
  Log.Debug("[UpdateUIModule:UpdateIOSApp] Error: " .. Error or "nil")
end

function UpdateUIModule:UpdateAndroidApp()
  Log.Warning("UpdateAndroidApp")
  self:CheckInternetConnection(function(this)
    this.AppUpdateTask:ContinueUpdate(true)
  end, self, self.AppNeedDownloadSize)
end

function UpdateUIModule.UpdateOpenHarmonyApp()
  Log.Warning("UpdateOpenHarmonyApp")
  local BundleName = UE4.UNRCStatics.GetOpenHarmonyPackageName()
  Log.Warning("URL : " .. string.format("https://appgallery.huawei.com/app/detail?id=%s", BundleName))
  UE4.UKismetSystemLibrary.LaunchURL(string.format("https://appgallery.huawei.com/app/detail?id=%s", BundleName))
end

function UpdateUIModule:SetSvrTime(svr_time)
  self:DispatchEvent(UpdateUIModuleEvent.UpdateSvrTime, svr_time)
end

function UpdateUIModule:UpdateWaterMark(notify)
  self:DispatchEvent(UpdateUIModuleEvent.UpdateWaterMark, notify)
end

function UpdateUIModule:SetLocation(player)
  self:DispatchEvent(UpdateUIModuleEvent.UpdateLocation, player)
end

function UpdateUIModule:SetBattleId(battleId)
  self:DispatchEvent(UpdateUIModuleEvent.SetBattleId, battleId)
end

function UpdateUIModule:DebugPlayVideo(video_path)
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  return Panel:DebugPlayVideo(video_path)
end

function UpdateUIModule:StopPlayVideo()
  local Panel = self:GetPanel(LoginEnum.PanelNames.VideoBackground)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  return Panel:StopPlayVideo()
end

function UpdateUIModule:WriteLoadedUPackagesJson(FileName)
  Log.Debug("[WriteLoadedPackagesJson] Enter ", FileName)
  local LoadedUPackagesPathList = {}
  local LoadedPackagesPath = UE.UNRCStatics.GetAllLoadedPackagesPath()
  if LoadedPackagesPath then
    for i = 1, LoadedPackagesPath:Length() do
      local path = LoadedPackagesPath:GetRef(i)
      if not string.IsNilOrEmpty(path) then
        local GameDir = "/Game/"
        local bIsGameAsset = string.find(path, GameDir)
        if bIsGameAsset then
          table.insert(LoadedUPackagesPathList, path)
        end
      end
    end
    local bSuccess = JsonUtils.DumpSaved(FileName, LoadedUPackagesPathList)
    Log.Debug("[WriteLoadedPackagesJson] DumpSaved ", bSuccess)
  end
end

function UpdateUIModule:WaitForVideoReady()
  if self.bEnterDelayShowUpdateUI then
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.VideoReady)
    return
  end
  self.bEnterDelayShowUpdateUI = false
  NRCEventCenter:RegisterEvent("UpdateUIModule", self, LoginModuleEvent.VideoOpened, self.DelayShowUpdateUI)
  _G.DelayManager:DelaySeconds(1, function()
    self:DelayShowUpdateUI()
  end)
end

function UpdateUIModule:DelayShowUpdateUI()
  if self.bEnterDelayShowUpdateUI then
    return
  end
  self.bEnterDelayShowUpdateUI = true
  _G.DelayManager:DelaySeconds(1.5, function()
    NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.VideoOpened, self.DelayShowUpdateUI)
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.VideoReady)
  end)
end

function UpdateUIModule:ShowDeviceBlockedTipsDialog()
  local deviceInfo = DeviceUtils.GetDeviceDetailInfo() or "nil"
  _G.GEMPostManager:GEMPostStepEvent("BlackListLimit", deviceInfo)
  local Context = DialogContext()
  NRCEventCenter:DispatchEvent(LoginModuleEvent.WhiteListBlocked)
  local IsSimulator, simuName = _G.NRCSDKManager:IsSimulator()
  if IsSimulator then
    Context:SetTitle(LuaText.onlinemodule_1):SetContent(LuaText.simulator_block or ""):SetMode(DialogContext.Mode.OK):SetButtonText(LuaText.onlinemodule_6):SetCallback(self, function(this, result)
      UE4.UNRCStatics.QuitGame()
    end)
  elseif DeviceUtils.IsIntegratedGraphics() then
    Context:SetTitle(LuaText.onlinemodule_1 ~= nil and LuaText.onlinemodule_1 or ""):SetContent(nil ~= LuaText.onlinemodule_4 and LuaText.onlinemodule_4 or ""):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnCancel(false):SetButtonText(LuaText.onlinemodule_6 ~= nil and LuaText.onlinemodule_6 or "", nil ~= LuaText.onlinemodule_5 and LuaText.onlinemodule_5 or ""):SetCallback(self, function(this, result)
      if result then
        UE4.UNRCStatics.QuitGame()
      else
        _G.NRCSDKManager:OpenWebView("https://kf.qq.com/touch/sy/prod/A10878/v2/index.html?scene_id=CSCE20250317153900rqOczPHU")
      end
    end)
    Log.Error("IsIntegratedGraphics return true")
  elseif RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    Context:SetTitle(LuaText.onlinemodule_1):SetContent(LuaText.onlinemodule_3 or ""):SetMode(DialogContext.Mode.OK):SetButtonText(LuaText.onlinemodule_6):SetCallback(self, function(this, result)
      UE4.UNRCStatics.QuitGame()
    end)
  else
    local ShowRet = CloudGameUtil:TryShowCloudGameDialog(LuaText.cloudgame_device_blocked_tips, true)
    if not ShowRet then
      local CPUBrand = UE4.UNRCQualityLibrary.GetCPUBrand()
      if nil ~= CPUBrand and "" ~= CPUBrand and nil ~= LuaText.onlinemodule_3_Detail then
        Context:SetTitle(LuaText.onlinemodule_1):SetContent(string.format(LuaText.onlinemodule_3_Detail, CPUBrand)):SetMode(DialogContext.Mode.OK):SetButtonText(LuaText.onlinemodule_6):SetCallback(self, function(this, result)
          UE4.UNRCStatics.QuitGame()
        end)
      else
        Context:SetTitle(LuaText.onlinemodule_1):SetContent(LuaText.onlinemodule_3 or ""):SetMode(DialogContext.Mode.OK):SetButtonText(LuaText.onlinemodule_6):SetCallback(self, function(this, result)
          UE4.UNRCStatics.QuitGame()
        end)
      end
    end
  end
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UpdateUIModule:CheckIfDeviceBlocked()
  Log.Debug("[UpdateUIModule:CheckIfDeviceBlocked]")
  local deviceInfo = DeviceUtils.GetDeviceDetailInfo() or "nil"
  _G.GEMPostManager:GEMPostStepEvent("DeviceInfoReport", deviceInfo)
  if self.bIsDeviceInWhiteListCDN and not self.bIsDeviceInBlackListCDN then
    Log.Debug("[UpdateUIModule:CheckIfDeviceBlocked] use cache result")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
  else
    self:CheckIfDeviceBlockedByCDNWhiteList()
  end
end

function UpdateUIModule:OnWindowActivationChanged(bActivate)
  if _G.GlobalConfig.SoundMuteMode then
    if bActivate then
      _G.NRCAudioManager:SetOutputVolume(1)
    else
      _G.NRCAudioManager:SetOutputVolume(0)
    end
  end
end

function UpdateUIModule:CheckIfDeviceBlockedByCDNWhiteList()
  Log.Debug("[UpdateUIModule:CheckIfDeviceBlockedByCDNWhiteList]")
  self.bGetWhiteListDownloadResult = false
  local WhiteListDownloadURLWithTS
  if RocoEnv.IS_SHIPPING then
    WhiteListDownloadURLWithTS = WhiteListDownloadURL .. "?t=" .. UE4.UNRCStatics.GetTimestampMicroseconds()
  else
    WhiteListDownloadURLWithTS = WhiteListDownloadURLDev .. "?t=" .. UE4.UNRCStatics.GetTimestampMicroseconds()
  end
  local LocalFilePath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "WhiteList.txt"
  })
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    Log.Error("[UpdateUIModule:CheckIfDeviceBlockedByCDNWhiteList] GameInstance is nil")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
    return
  end
  GameInstance.OnDownloadFileResult:Clear()
  GameInstance.OnDownloadFileResult:Add(GameInstance, function(this, InURL, bSuccess, ErrorCode)
    Log.Debug(string.format("[UpdateUIModule:CheckIfDeviceBlockedByCDNWhiteList] download %s result: %s ErrorCode:%s", InURL, bSuccess, ErrorCode or "nil"))
    if InURL == WhiteListDownloadURLWithTS then
      self:CheckIfDeviceBlockedAfterDownloadWhiteList()
    end
  end)
  self.DownloadWhitListTimeOutTimer = _G.TimerManager:CreateTimer(self, "DownloadWhitListTimeOutTimer", 5, nil, self.OnDownloadWhitListTimeOut, 9999)
  UE4.UNRCStatics.HttpDownloadFile(WhiteListDownloadURLWithTS, LocalFilePath)
end

function UpdateUIModule:OnDownloadWhitListTimeOut()
  Log.Error("[UpdateUIModule:OnDownloadWhitListTimeOut] download file timeout")
  self:CheckIfDeviceBlockedAfterDownloadWhiteList(true)
end

function UpdateUIModule:CheckIfEnvWarningAfterWhiteList()
  Log.Debug("UpdateUIModule:CheckIfEnvWarningAfterWhiteList")
  local bShouldOpenDialog = false
  local DialogContent
  local curIndex = 1
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" and not DeviceUtils.bClosePCEnv then
    if 0 == UE4.UNRCPlatformStatics.GetPCEnvWarningHistory() then
      Log.Debug("GetPCEnvWarningHistory 0, go to check")
      if not DeviceUtils.bClosePCOSVersionCheck and UE4.UNRCPlatformStatics.IsWindowsOSVersionLimit() then
        local Version = UE4.UNRCQualityLibrary.GetOSVersion()
        local WinOSVersionContent = string.format(LuaText.WindowsOSVersionLow_Message_Detail, Version)
        if DialogContent then
          DialogContent = string.format([[
%s
%d.%s]], DialogContent, curIndex, WinOSVersionContent)
        else
          DialogContent = string.format([[

%d.%s]], curIndex, WinOSVersionContent)
        end
        curIndex = curIndex + 1
        bShouldOpenDialog = true
      end
      if not DeviceUtils.bClosePCIntel1314Check and UE4.UNRCPlatformStatics.IsIntel1314KShrinkRisk() then
        local MicrocodeVersion = UE4.UNRCPlatformStatics.GetMicrocodeVersion()
        if MicrocodeVersion < 299 then
          local Intel1314Content = string.format(LuaText.intel1314_Message_Detail, MicrocodeVersion)
          if DialogContent then
            DialogContent = string.format([[
%s
%d.%s]], DialogContent, curIndex, Intel1314Content)
          else
            DialogContent = string.format([[

%d.%s]], curIndex, Intel1314Content)
          end
          curIndex = curIndex + 1
          bShouldOpenDialog = true
        end
      end
      if not DeviceUtils.bClosePCGPUDriverCheck and UE4.UNRCPlatformStatics.IsWindowsGPUDriverVersionLimit() then
        local Version = UE4.UNRCQualityLibrary.GetGPUDriverVersion()
        local GPUDriverContent = string.format(LuaText.GPUDriverVersionLow_Message_Detail, Version)
        if DialogContent then
          DialogContent = string.format([[
%s
%d.%s]], DialogContent, curIndex, GPUDriverContent)
        else
          DialogContent = string.format([[

%d.%s]], curIndex, GPUDriverContent)
        end
        curIndex = curIndex + 1
        bShouldOpenDialog = true
      end
    else
      Log.Debug("GetPCEnvWarningHistory not zero")
    end
  end
  if not bShouldOpenDialog then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
  else
    local Context = DialogContext()
    Context:SetTitle(LuaText.onlinemodule_1):SetContent(string.format(LuaText.PCEnvWarning_Message, DialogContent)):SetMode(DialogContext.Mode.OK):SetButtonText(LuaText.onlinemodule_11):SetCallback(self, function(this, result)
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
    end)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    UE4.UNRCPlatformStatics.SetPCEnvWarningHistory(1)
  end
end

function UpdateUIModule:CheckIfDeviceBlockedAfterDownloadWhiteList(bTimeOut)
  if self.bGetWhiteListDownloadResult then
    Log.Error("[UpdateUIModule:CheckIfDeviceBlockedAfterDownloadWhiteList] Invalid Callback")
    return
  end
  self.bGetWhiteListDownloadResult = true
  _G.TimerManager:RemoveTimer(self.DownloadWhitListTimeOutTimer)
  self.DownloadWhitListTimeOutTimer = nil
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance.OnDownloadFileResult:Clear()
  end
  if bTimeOut then
    Log.Error("[OnlineModule:CheckIfDeviceBlockedAfterDownloadWhiteList] Do not read white list while timeout")
    if DeviceUtils.IsDeviceInBlackList() or not DeviceUtils.IsDeviceInWhiteList() then
      self:ShowDeviceBlockedTipsDialog()
    else
      self:CheckIfEnvWarningAfterWhiteList()
    end
    return
  end
  Log.Debug("[UpdateUIModule:CheckIfDeviceBlockedAfterDownloadWhiteList]")
  DeviceUtils.RunCDNOperate()
  DeviceUtils.RunEnvConfig()
  self.bIsDeviceInWhiteListCDN = DeviceUtils.IsDeviceInWhiteListCDN()
  self.bIsDeviceInBlackListCDN = DeviceUtils.IsDeviceInBlackListCDN()
  if self.bIsDeviceInWhiteListCDN and not self.bIsDeviceInBlackListCDN then
    self:CheckIfEnvWarningAfterWhiteList()
  else
    Log.Debug("[UpdateUIModule:CheckIfDeviceBlockedAfterDownloadWhiteList] Device not in CDN white list")
    if DeviceUtils.IsDeviceInBlackList() or not DeviceUtils.IsDeviceInWhiteList() then
      self:ShowDeviceBlockedTipsDialog()
    elseif self.bIsDeviceInBlackListCDN then
      Log.Debug("[UpdateUIModule:CheckIfDeviceBlockedAfterDownloadWhiteList] Device not in CDN black list")
      self:ShowDeviceBlockedTipsDialog()
    else
      self:CheckIfEnvWarningAfterWhiteList()
    end
  end
end

function UpdateUIModule:OnDeactive()
  Log.Debug("[UpdateUIModule:OnDeactive]")
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.WINDOW_ACTIVATION_CHANGED, self.OnWindowActivationChanged)
  self:RemoveEventListener()
end

function UpdateUIModule:DownloadCloudGameConfig()
  Log.Debug("[UpdateUIModule:DownloadCloudGameConfig]")
  if RocoEnv.PLATFORM_ANDROID then
    CloudGameUtil:DownloadCloudGameConfig()
  end
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.DownloadCloudGameConfigDone)
end

return UpdateUIModule

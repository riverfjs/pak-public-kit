local NRCSDKManager = _G.Singleton:Extend("NRCSDKManager")
local EventDispatcher = require("Common.EventDispatcher")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local NRCSDKManagerEnum = require("Core.Service.SDKManager.NRCSDKManagerEnum")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local JsonUtils = require("Common.JsonUtils")
local GameletImpl = require("Core.Service.Pandora.GameletImpl")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local rapidjson = require("rapidjson")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")

function NRCSDKManager.CrashSightReportExceptionWithReasonGlobal(errorString, errorReason, stackTrace)
  NRCSDKManager:CrashSightReportExceptionWithReason(errorString, errorReason, stackTrace)
end

function NRCSDKManager:Ctor()
  EventDispatcher():Attach(self)
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance and RocoEnv.IS_EDITOR then
    Log.Error("GameInstance is nil")
    return
  end
  Log.Debug("NRCSDKManager:Ctor")
  self.bind = GameInstance:GetSDKManager()
  if self.bind then
    Log.Debug("self.bind not nil, add gamelet message handler")
    UE.UGameletImpl.GetInstance().OnGameletMessage:Bind(self.bind, self.HandleGameletStrMsg)
    UE.UGameletImpl.GetInstance().OnGameletWidgetMessage:Bind(self.bind, self.HandleGameletWidgetMsg)
  end
  if self.bind then
    self.WebViewObserver = NewObject(UE.UWebViewObserver, GameInstance, "WebViewObserver", "Core.Service.GCloud.WebViewObserver")
    UE.UWebViewStatics.SetObserver(self.WebViewObserver)
    self:AddObserverCache("WebViewObserver", self.WebViewObserver)
    self.WebViewObserver:ListenPermissionRequest()
    if RocoEnv.PLATFORM_WINDOWS then
      self.WeGameObserver = NewObject(UE.UWeGameObserver, GameInstance, "WeGameObserver", "Core.Service.WeGame.WeGameObserver")
      local WeGameManager = UE4.UNRCPlatformGameInstance.GetInstance():GetSDKManager().WeGameManager
      WeGameManager:InitRailCallBacks(self.WeGameObserver)
      self:AddObserverCache("WeGameObserver", self.WeGameObserver)
      self.bEnableACESDK = UE.UACESDKStatics.ACEEnable()
      self.bInitACESuccess = not self.bEnableACESDK or UE.UACESDKStatics.ACEInit()
      self.NetBarObserver = NewObject(UE.UNetBarObserver, GameInstance, "NetBarObserver", "Core.Service.NetBar.NetBarObserver")
      UE.UNetBarStatics.SetObserver(self.NetBarObserver)
      self:AddObserverCache("NetBarObserver", self.NetBarObserver)
    else
      self.bEnableTssSDK = self.bind:EnableTssSDK()
    end
    if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
      self.MidasObserver = NewObject(UE.UMidasObserver, GameInstance, "MidasObserver", "Core.Service.GCloud.MidasObserver")
      self:AddObserverCache("MidasObserver", self.MidasObserver)
    end
    if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS then
      self.GRobotObserver = NewObject(UE.UGRobotObserver, GameInstance, "GRobotObserver", "Core.Service.GCloud.GRobotObserver")
      self:AddObserverCache("GRobotObserver", self.GRobotObserver)
      UE.UGRobotStatics.Init()
      UE.UGRobotStatics.SetObserver(self.GRobotObserver)
    end
  end
  _G.TimerManager:CreateTimer(self, "PostNetworkLatency", math.maxinteger, self.PostNetworkLatency, nil, 10)
  self.DoMarkLevelFinTimer = _G.TimerManager:CreateTimer(self, "DoMarkLevelFin", math.maxinteger, self.OnTimerDoMarkLevelFin, nil, 1200)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.Shutdown, self.OnShutdown)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.LoadMapStart, self.OnLoadMapStartHandler)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.LoadPanel, self.OnLoadPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.LoadPanelSucc, self.OnLoadPanelFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.LoadPanelFail, self.OnLoadPanelFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClosed)
  _G.NRCEventCenter:RegisterEvent(self.name, self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_LOGIN, self.OnPlayerLogin)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCSDKManagerEvent.OnBackToLogin, self.OnBackToLogin)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationWillDeactivate, self.OnAppWillDeactivate)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationHasReactivated, self.OnAppHasReactivated)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCSDKManagerEvent.OnNewGameletAppReady, self.OnNewGameletAppPrepared)
  if self.bEnableTssSDK or self.bEnableACESDK then
    _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_REPORT_DATA_SEND_2_CLIENT, self.OnRecvServerTssReportData)
    _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
    _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
    if self.bEnableTssSDK then
      _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
      _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
    end
  end
  self.whiteListAppId = {}
  self.bNeedOpenActivityPage = false
  self.ActivityPageParams = {}
  self:TssSDKUserAgreement()
  self.bSendTssData2ThisTime = false
  if self.bind and (RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY) then
    UE.UNativeExtensionUtils.GetInstance().OnDeeplinkSetEvent:Bind(self.bind, self.ParseDeepLinkParam)
  end
  if not _G.RocoEnv.PLATFORM_WINDOWS and not _G.RocoEnv.IS_EDITOR then
    UE.UTDMStatics.EnableDeviceInfo(true)
    UE.UTDMStatics.EnableReport(true)
  end
end

function NRCSDKManager:OnShutdown()
  if self.bind and self.bEnableACESDK then
    UE.UACESDKStatics.ACEFinalize()
  end
  if self.WebViewObserver then
    self.WebViewObserver:UnRegister()
  end
  self:PostStutter()
  UE4.UGPMStatics.MarkLevelFin()
end

function NRCSDKManager:CrashSightReportException(errorString, stackTrace)
  if self.bind then
    self.bind:CrashSightReportException(errorString, stackTrace)
  end
end

function NRCSDKManager:GetIpFromHttpDns(domainName, openId)
  if self.bind then
    return self.bind:GetIpFromHttpDns(domainName, openId)
  end
  return false
end

function NRCSDKManager:CrashSightReportExceptionWithReason(errorString, errorReason, stackTrace)
  if self.bind then
    self.bind:CrashSightReportExceptionWithReason(errorString, errorReason, stackTrace)
  end
end

function NRCSDKManager:CloseCrashSight()
  if self.bind then
    self.bind:CloseCrashSight()
  end
end

function NRCSDKManager:AddObserverCache(key, observer)
  if self.bind then
    self.bind:AddObserverCache(key, observer)
  end
end

function NRCSDKManager:RemoveObserverCache(key)
  if self.bind then
    self.bind:RemoveObserverCache(key)
  end
end

function NRCSDKManager:ReportExtraCrashData(type, data)
  if self.bind then
    self.bind:ReportCrashData(type, data)
  end
end

function NRCSDKManager:SetUserValue(Key, Value)
  if self.bind then
    self.bind:SetUserValue(Key, Value)
  end
end

function NRCSDKManager:MarkLevelLoad(sceneName, restoreTagAndExclude)
  restoreTagAndExclude = restoreTagAndExclude or false
  UE4.UGPMStatics.MarkLevelLoad(sceneName, restoreTagAndExclude)
  self:StartCustomStutter(restoreTagAndExclude)
  if _G.GameSetting then
    self:SetUploadLogTag(_G.GameSetting:GetUploadLogTag(), true)
  end
end

function NRCSDKManager:PerfBeginMark(tag)
  UE4.UGPMStatics.BeginExtTag(tag)
end

function NRCSDKManager:PerfEndMark(tag)
  UE4.UGPMStatics.EndExtTag(tag)
end

function NRCSDKManager:PerfBeginExclude(tag)
  UE4.UGPMStatics.BeginExclude(tag)
  UE4.UGPMStatics.PerfBeginMarkSkip(tag)
end

function NRCSDKManager:PerfEndExclude(tag)
  UE4.UGPMStatics.EndExclude(tag)
  UE4.UGPMStatics.PerfEndMarkSkip(tag)
end

function NRCSDKManager:StartCustomStutter(restoreMarkSkips)
  UE4.UGPMStatics.PerfStartProfile("", not not restoreMarkSkips)
end

function NRCSDKManager:StopCustomStutter()
  local stutter = self:PostStutter() or 0
  UE4.UGPMStatics.PerfEndProfile()
  Log.Info("StopCustomStutter:", stutter)
  return stutter
end

function NRCSDKManager:SetQualityToApm()
  local reportQualityData = {}
  reportQualityData.deviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel(true)
  reportQualityData.frameQuality = UE4.UNRCQualityLibrary.GetFrameQuality()
  reportQualityData.imageQuality = UE4.UNRCQualityLibrary.GetImageQuality()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    reportQualityData.resolutionIndex = 0
    local reportPCResolutions = {
      [1] = {3840, 2160},
      [2] = {2560, 1600},
      [3] = {2560, 1440},
      [4] = {2560, 1080},
      [5] = {2048, 1536},
      [6] = {2048, 1152},
      [7] = {1920, 1440},
      [8] = {1920, 1200},
      [9] = {1920, 1080}
    }
    local resX, resY = UE4.UNRCQualityLibrary.GetPCResolution()
    for _index, _resConf in ipairs(reportPCResolutions) do
      if _resConf[1] == resX and _resConf[2] == resY then
        reportQualityData.resolutionIndex = _index
        break
      end
    end
  else
    reportQualityData.resolutionIndex = UE4.UNRCQualityLibrary.GetMobileResolutionQuality()
    if reportQualityData.resolutionIndex >= 5 then
      reportQualityData.resolutionIndex = reportQualityData.resolutionIndex - 5
    end
    if 1 == reportQualityData.resolutionIndex then
      reportQualityData.resolutionIndex = 2
    end
  end
  reportQualityData.shadowQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "ShadowQuality")
  reportQualityData.postProcessQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "PostProcessQuality")
  reportQualityData.sceneDetailQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "SceneDetailQuality")
  reportQualityData.shadingQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "ShadingQuality")
  reportQualityData.viewDistanceQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "ViewDistanceQuality")
  reportQualityData.lightQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "LightQuality")
  reportQualityData.effectsQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "EffectsQuality")
  reportQualityData.reflectionQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "ReflectionQuality")
  reportQualityData.bloomQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "BloomQuality")
  reportQualityData.antiAliasingQuality = UE4.UNRCQualityLibrary.GetImageGroupQualityValue(reportQualityData.imageQuality, "AntiAliasingQuality")
  reportQualityData.shadowQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.shadowQuality)
  reportQualityData.postProcessQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.postProcessQuality)
  reportQualityData.sceneDetailQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.sceneDetailQuality)
  reportQualityData.shadingQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.shadingQuality)
  reportQualityData.viewDistanceQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.viewDistanceQuality)
  reportQualityData.lightQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.lightQuality)
  if 5 == reportQualityData.effectsQuality then
    reportQualityData.effectsQuality = 2
  elseif 3 == reportQualityData.effectsQuality or 4 == reportQualityData.effectsQuality then
    reportQualityData.effectsQuality = 1
  else
    reportQualityData.effectsQuality = 0
  end
  if 5 == reportQualityData.reflectionQuality or 4 == reportQualityData.reflectionQuality then
    reportQualityData.reflectionQuality = 2
  else
    reportQualityData.reflectionQuality = 0
  end
  reportQualityData.bloomQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.bloomQuality)
  reportQualityData.antiAliasingQuality = UE4.UNRCQualityLibrary.ConvertLevelToUserImage(reportQualityData.antiAliasingQuality)
  Log.InfoFormat("\232\174\190\229\164\135\229\136\134\230\161\163[%d], \229\184\167\231\142\135[%d], \230\152\190\231\164\186\230\168\161\229\188\143[%d], \231\148\187\233\157\162\229\147\129\232\180\168[%d], \233\152\180\229\189\177\232\180\168\233\135\143[%d], \229\144\142\230\156\159\230\149\136\230\158\156[%d], \229\135\160\228\189\149\231\187\134\232\138\130[%d], \230\157\144\232\180\168\231\178\190\229\186\166[%d], \229\138\160\232\189\189\232\183\157\231\166\187[%d], \229\133\137\231\133\167\232\180\168\233\135\143[%d], \231\137\185\230\149\136\232\180\168\233\135\143[%d], \229\143\141\229\176\132\232\180\168\233\135\143[%d], \230\179\155\229\133\137\230\149\136\230\158\156[%d], \230\138\151\233\148\175\233\189\191[%d]", reportQualityData.deviceLevel, reportQualityData.frameQuality, reportQualityData.resolutionIndex, reportQualityData.imageQuality, reportQualityData.shadowQuality, reportQualityData.postProcessQuality, reportQualityData.sceneDetailQuality, reportQualityData.shadingQuality, reportQualityData.viewDistanceQuality, reportQualityData.lightQuality, reportQualityData.effectsQuality, reportQualityData.reflectionQuality, reportQualityData.bloomQuality, reportQualityData.antiAliasingQuality)
  local MaxImageGroupQualityValue = 3
  if 0 ~= reportQualityData.reflectionQuality then
    reportQualityData.reflectionQuality = 2
  end
  local qualityValue = string.format("%d%d%d%d%d%d%d%d%d%d%d%d%d%d", math.min(reportQualityData.deviceLevel, 6), math.min(reportQualityData.frameQuality, 6), math.min(reportQualityData.resolutionIndex, 9), math.min(reportQualityData.imageQuality, 4), math.min(reportQualityData.shadowQuality, MaxImageGroupQualityValue), math.min(reportQualityData.postProcessQuality, MaxImageGroupQualityValue), math.min(reportQualityData.sceneDetailQuality, MaxImageGroupQualityValue), math.min(reportQualityData.shadingQuality, MaxImageGroupQualityValue), math.min(reportQualityData.viewDistanceQuality, MaxImageGroupQualityValue), math.min(reportQualityData.lightQuality, MaxImageGroupQualityValue), math.min(reportQualityData.effectsQuality, 2), math.min(reportQualityData.reflectionQuality, 2), math.min(reportQualityData.bloomQuality, MaxImageGroupQualityValue), math.min(reportQualityData.antiAliasingQuality, MaxImageGroupQualityValue))
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    local value = UE4.UNRCQualityLibrary.IsPreferD3D12() and 1 or 0
    qualityValue = qualityValue .. value
  end
  UE4.UGPMStatics.PostEvent(700, qualityValue)
  self.isQualityReported = true
  return qualityValue
end

function NRCSDKManager:SetUploadLogTag(logTag, newLevelStart)
  local isOpen = "High" == logTag
  if isOpen then
    self:PerfBeginMark("LogUpload")
  else
    self:PerfEndMark("LogUpload")
  end
  if isOpen or newLevelStart then
    UE4.UGPMStatics.PostValueI_OneValue("CustomPerfData", "OpenLogUpload", isOpen and 1 or 0)
  end
end

function NRCSDKManager:SetEnterDialogue()
  self:PerfBeginMark("dialogue")
  self:PerfBeginExclude("dialogue")
end

function NRCSDKManager:SetEnterBattle()
  self:PerfBeginMark("battle")
  self:PerfBeginExclude("enter battle")
end

function NRCSDKManager:SetLeaveBattle()
  self:PerfBeginExclude("leave battle")
end

function NRCSDKManager:SetGC()
  self:PerfBeginMark("gc")
  self:PerfBeginExclude("gc")
end

function NRCSDKManager:EndGC()
  self:PerfEndExclude("gc")
  self:PerfEndMark("gc")
end

function NRCSDKManager:PostNetworkLatency()
  local rtt = _G.NRCNetworkManager:GetTConndRTT()
  if rtt and rtt > 0 then
    UE4.UGPMStatics.PostNetworkLatency(rtt)
  end
end

function NRCSDKManager:PostStutter()
  if not UE4.UGPMStatics.IsPerfStart() then
    return
  end
  local stutter = UE4.UGPMStatics.PerfGetStutter()
  UE4.UGPMStatics.PostValueF_OneValue("CustomPerfData", "Stutter", stutter)
  return stutter
end

function NRCSDKManager:OnLoadMapStartHandler(sameSceneRes, bReconnecting, mapId, mapResId)
  if sameSceneRes then
    return
  end
  self:PostStutter()
  local sceneName
  if mapResId then
    local mapResConf = _G.DataConfigManager:GetSceneResConf(mapResId)
    if mapResConf and not string.IsNilOrEmpty(mapResConf.scene_res_name) then
      sceneName = mapResConf.scene_res_name
    end
  end
  if not sceneName then
    local mapConf = _G.DataConfigManager:GetSceneConf(mapId)
    if mapConf then
      sceneName = mapConf.scene_name
    end
  end
  self.markLevelName = sceneName and sceneName or mapId and tostring(mapId) or "unknow"
  self:MarkLevelLoad(self.markLevelName, false)
  if self.markInLoading then
    self:PerfBeginMark("loading")
    self:PerfBeginExclude("loading")
  end
  if self.DoMarkLevelFinTimer then
    self.DoMarkLevelFinTimer:Restart()
  end
end

function NRCSDKManager:OnTimerDoMarkLevelFin()
  if not self.markLevelName then
    return
  end
  self:PostStutter()
  self:MarkLevelLoad(self.markLevelName, true)
end

function NRCSDKManager:OnOpenPanel(panelData)
  if panelData and panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    self:PerfBeginMark(panelData.panelName)
  end
end

function NRCSDKManager:OnLoadPanel(panelData)
  if panelData and panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    self:PerfBeginExclude(panelData.panelName)
  end
end

function NRCSDKManager:OnLoadPanelFinish(panelData)
  if panelData and panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    self:PerfEndExclude(panelData.panelName)
  end
end

function NRCSDKManager:OnClosePanel(panelData)
  if panelData and panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    self:PerfEndMark(panelData.panelName)
  end
end

function NRCSDKManager:OnLoadingUIOpen()
  self.markInLoading = true
  self:PerfBeginMark("loading")
  self:PerfBeginExclude("loading")
  if not self.isQualityReported then
    self:SetQualityToApm()
  end
end

function NRCSDKManager:OnLoadingUIClosed()
  self.markInLoading = false
  self:PerfEndExclude("loading")
  self:PerfEndMark("loading")
end

function NRCSDKManager:OnEnterScene()
  local statusChecker = StatusCheckerGroup({
    StatusCheckerEnum.Scene,
    StatusCheckerEnum.Loading,
    StatusCheckerEnum.FastLoading
  }, Log.LOG_LEVEL.ELogDebug, "NRCSDKManager")
  if statusChecker then
    statusChecker:Check(self, self.OpenActivityPage)
  end
end

function NRCSDKManager:OnDelayOpenActivityPage(activityParam)
  self.activityDelayId = nil
  if table.isNotEmpty(activityParam) then
    UE4.UWebViewStatics.OpenURL(activityParam.urlParam, activityParam.pageDirectionParam, activityParam.pageFullScreenParam, true)
  else
    Log.Error("[NRCSDKManager:OnLoadingUIClosed] self.ActivityPageParams is invalid")
  end
end

function NRCSDKManager:OpenActivityPage()
  if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
    if self.bNeedOpenActivityPage then
      self.activityDelayId = _G.DelayManager:DelayFrames(10, self.OnDelayOpenActivityPage, self, self.ActivityPageParams)
      self.ActivityPageParams = nil
      self.bNeedOpenActivityPage = nil
      _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterScene)
    else
      Log.Debug("[NRCSDKManager:OnLoadingUIClosed] self.bNeedOpenActivityPage is false")
    end
  end
end

function NRCSDKManager:OnDialogueEnded()
  self:PerfEndExclude("dialogue")
  self:PerfEndMark("dialogue")
end

function NRCSDKManager:OnLeaveBattle()
  self:PerfEndExclude("leave battle")
  self:PerfEndMark("battle")
end

function NRCSDKManager:OnAppWillDeactivate()
  self:PerfBeginMark("background")
  UE4.UGPMStatics.PerfBeginMarkSkip("background")
end

function NRCSDKManager:OnAppHasReactivated()
  UE4.UGPMStatics.PerfEndMarkSkip("background")
  self:PerfEndMark("background")
  UE4.UGPMStatics.PerfMarkSkipFrame(4, "background_2")
end

function NRCSDKManager:PostLoginStepEvent(eventCategory, stepId, status, code, msg, extraKey, authorize, finish)
  eventCategory = "login"
  UE4.UGPMStatics.PostStepEvent(eventCategory, stepId, status, code, msg, extraKey, authorize, finish)
end

function NRCSDKManager:SendACEDataToSvrIfNecessary()
  if self.bEnableACESDK then
    local AntiData = UE.UACESDKStatics.ACEGetClientSDKPacket()
    if not string.IsNilOrEmpty(AntiData) then
      Log.Debug("[NRCSDKManager:SendACEDataToSvrIfNecessary]")
      local Request = _G.ProtoMessage:newZoneClientReportDataReq()
      Request.report_data = AntiData
      Request.type = 1
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_REPORT_DATA_REQ, Request, self, function(rsp)
        Log.Debug("ZONE_CLIENT_REPORT_DATA_REQ send req with rsp", rsp)
      end)
    end
  end
end

function NRCSDKManager:OpenWebView(url, screen_type, bIsFullScreen, bIsBrowser, extraJson, bIsUseURLEncode)
  if not RocoEnv.IS_SHIPPING then
    Log.Error("[NRCSDKManager:OpenWebView] OpenUrl", url, screen_type)
  end
  local extraJsonTable = {}
  if not screen_type then
    if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
      extraJsonTable = {isEmbedWebView = true, withDialog = true}
      screen_type = 3
    else
      extraJsonTable = {
        isEmbedWebView = true,
        webview_window_scale = 0.9,
        withDialog = true
      }
      screen_type = 1
    end
  end
  local extraJsonStr = ""
  if nil ~= extraJson and not table.isEmpty(extraJson) then
    if not table.isEmpty(extraJsonTable) then
      for key, value in pairs(extraJsonTable) do
        extraJson[key] = value
      end
    end
    extraJsonStr = not table.isEmpty(extraJson) and JsonUtils.EncodeTable(extraJson) or ""
  else
    extraJsonStr = not table.isEmpty(extraJsonTable) and JsonUtils.EncodeTable(extraJsonTable) or ""
  end
  bIsFullScreen = bIsFullScreen or false
  bIsBrowser = bIsBrowser or false
  if nil == bIsUseURLEncode then
    bIsUseURLEncode = true
  end
  UE4.UWebViewStatics.OpenURL(url, screen_type, bIsFullScreen, bIsUseURLEncode, extraJsonStr, bIsBrowser)
end

function NRCSDKManager:OpenQQGameCenterDetail()
  if not _G.RocoEnv.IS_EDITOR then
    if _G.RocoEnv.PLATFORM_WINDOWS then
      return
    end
    local url_ios = "https://static.gamecenter.qq.com/xgame/gc-assets/pages/game-detail/index.html?page_name=QQGameCenterGameDetail&open_kuikly_info=%7B%22url%22%3A%22%3FFFROMSCHEMA%3D%26appid%3D1110613799%26adtag%3Dgameclient%22%2C%22page_name%22%3A%22QQGameCenterGameDetail%22%2C%22bundle_name%22%3A%22gamecenter_detail%22%7D"
    local url_android = "https://static.gamecenter.qq.com/xgame/gc-assets/pages/game-detail/index.html?page_name=QQGameCenterGameDetail&open_kuikly_info=%7B%22url%22%3A%22%3FFFROMSCHEMA%3D%26appid%3D1110613799%26adtag%3Dgameclient%22%2C%22page_name%22%3A%22QQGameCenterGameDetail%22%2C%22bundle_name%22%3A%22gamecenter_detail%22%7D"
    local url_openharmony = "https://static.gamecenter.qq.com/xgame/gc-assets/pages/game-detail/index.html?page_name=QQGameCenterGameDetail&open_kuikly_info=%7B%22url%22%3A%22%3FFFROMSCHEMA%3D%26appid%3D1110613799%26adtag%3Dgameclient%22%2C%22page_name%22%3A%22QQGameCenterGameDetail%22%2C%22bundle_name%22%3A%22gamecenter_detail%22%7D"
    local url = RocoEnv.PLATFORM_IOS and url_ios or RocoEnv.PLATFORM_ANDROID and url_android or RocoEnv.PLATFORM_OPENHARMONY and url_openharmony or ""
    if string.IsNilOrEmpty(url) then
      return
    end
    self:OpenWebView(url, 1, true, true)
  else
    local url = "https://static.gamecenter.qq.com/xgame/gc-assets/pages/game-detail/index.html?page_name=QQGameCenterGameDetail&open_kuikly_info=%7B%22url%22%3A%22%3FFFROMSCHEMA%3D%26appid%3D1110613799%26adtag%3Dgameclient%22%2C%22page_name%22%3A%22QQGameCenterGameDetail%22%2C%22bundle_name%22%3A%22gamecenter_detail%22%7D"
    self:OpenWebView(url, 1, true, true)
  end
end

function NRCSDKManager:CustomerService(type)
  local url = ""
  if 1 == type then
    url = "https://kf.qq.com/touch/sy/prod/A10878/v2/index.html?scene_id=CSCE20250102160026KVXUPLkN"
  elseif 2 == type then
    url = "https://kf.qq.com/touch/sy/prod/A10878/v2/index.html?scene_id=CSCE20250102160054CJvLMMmj"
  elseif 3 == type then
    url = "https://kf.qq.com/touch/sy/prod/A10878/v2/index.html?scene_id=CSCE20250102160121gmPqLfQv"
  elseif 4 == type then
    url = "https://kf.qq.com/touch/sy/prod/A10878/v2/index.html?scene_id=CSCE20250102160155BGfiKDTD"
  elseif 5 == type then
    url = "https://kf.qq.com/touch/sy/prod/A10878/v2/index.html?scene_id=CSCE20250102160054CJvLMMmj"
  else
    Log.Error("\232\175\183\232\190\147\229\133\165\232\166\129\230\137\147\229\188\128\229\174\162\230\156\141\231\177\187\229\158\139")
    return
  end
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo()
  local TempRole = ""
  local TempRoleId = ""
  if PlayerInfo then
    TempRole = self:urlEncode(_G.DataModelMgr.PlayerDataModel:GetPlayerName())
    TempRoleId = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  end
  local TempAppId = ""
  local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
  local TempAppChannel
  local LoginModule = _G.NRCModuleManager:GetModule("LoginModule")
  if LoginModule and LoginUtils.GetLoginData() and LoginUtils.GetLoginData():GetChannel() then
    TempAppChannel = LoginUtils.GetLoginData():GetChannel()
  end
  if TempAppChannel then
    if TempAppChannel == LoginEnum.ChannelNames.WeChat then
      TempAppId = "wxdca9f9a612d43085"
    elseif TempAppChannel == LoginEnum.ChannelNames.QQ then
      TempAppId = "1110613799"
    end
  else
    local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
    if not OnlineModule then
      OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
      if not OnlineModule then
        Log.Error("OnlineModule not found")
        return
      end
    end
    local onlineModuleData = OnlineModule.data
    if onlineModuleData then
      if onlineModuleData.loginChannelType == Enum.CliLoginChannel.CLC_WX then
        TempAppId = "wxdca9f9a612d43085"
      elseif onlineModuleData.loginChannelType == Enum.CliLoginChannel.CLC_QQ then
        TempAppId = "1110613799"
      end
    end
  end
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local TempOpenId = ""
  if playerInfoData and playerInfoData.openid then
    TempOpenId = playerInfoData.openid
  end
  if "" == TempOpenId then
    TempOpenId = LoginUtils.GetLoginData():GetOpenID()
  end
  local platid = (not RocoEnv.PLATFORM_ANDROID or not 1) and (not RocoEnv.PLATFORM_IOS or not 0) and (not RocoEnv.PLATFORM_WINDOWS or not 2) and RocoEnv.PLATFORM_OPENHARMONY and 12
  local paramsTable = {}
  if 2 == platid then
    paramsTable.loginType = "1"
    paramsTable.appid = TempAppId
    paramsTable.gopenid = TempOpenId
    paramsTable.z = ""
    paramsTable.zn = ""
    paramsTable.role = TempRole
    paramsTable.roleid = TempRoleId
  else
    paramsTable.platid = platid
    paramsTable.appid = TempAppId
    paramsTable.gopenid = TempOpenId
    paramsTable.qi = UE4.ULoginStatics.IsQQInstalled() and 1 or 0
    paramsTable.wi = UE4.ULoginStatics.IsVxInstalled() and 1 or 0
    paramsTable.z = ""
    paramsTable.zn = ""
    paramsTable.role = TempRole
    paramsTable.roleid = TempRoleId
  end
  if 2 == platid then
    url = "https://kf.qq.com/touch/kfgames/A10878/v2/PClient/conf/index.html?scene_id=CSCE20250102160555vwffPTrJ"
  end
  for key, value in pairs(paramsTable) do
    if "" ~= url then
      url = string.format("%s%s", url, "&")
    end
    url = string.format("%s%s%s%s", url, key, "=", value)
  end
  if url then
    Log.Debug("OpenCustomerService with url:%s", url)
    if 2 == platid then
      self:OpenWebView(url, 1, true, false)
    elseif 1 == platid then
      self:OpenWebView(url, 3, true, false, {isEmbedWebView = true, withDialog = true})
    else
      self:OpenWebView(url, 3, false, false, {isEmbedWebView = true, withDialog = true})
    end
  end
end

function NRCSDKManager:urlEncode(str)
  if str then
    str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    return str
  end
  return ""
end

function NRCSDKManager:TssSDKUserAgreement()
  if self.bEnableTssSDK and self.bind then
    Log.Debug("[NRCSDKManager:TssSDKUserAgreement]")
    self.bind:TssSDKUserAgreement()
  end
end

function NRCSDKManager:IsSimulator()
  if self.bEnableTssSDK and self.bind then
    local str = ""
    local simuName, bIsSimulator = self.bind:IsSimulator(str)
    Log.Debug("[NRCSDKManager:IsSimulator] bIsSimulator:", bIsSimulator, simuName)
    return bIsSimulator, simuName
  end
  return false, simuName
end

function NRCSDKManager:SendTssDataToSvrIfNecessary()
  Log.Debug("[NRCSDKManager:SendTssDataToSvrIfNecessary]")
  if self.bEnableTssSDK and not self.bPauseReportNextAntiData and self.bind then
    local AntiData = self.bind:GetTssSDKReportData()
    if not string.IsNilOrEmpty(AntiData) then
      local Request = _G.ProtoMessage:newZoneClientReportDataReq()
      Request.report_data = AntiData
      Request.type = 1
      Request.send_type = NRCSDKManagerEnum.AntiCheatSendType.Default
      self.LastTssReportData = AntiData
      self.bPauseReportNextAntiData = true
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_REPORT_DATA_REQ, Request, self, self.OnTssReportDataRsp)
    else
      Log.Debug("[NRCSDKManager:SendTssDataToSvrIfNecessary] AntiData is nil or empty.")
    end
  end
end

function NRCSDKManager:OnTssReportDataRsp(Rsp)
  if Rsp and Rsp.ret_info and Rsp.ret_info.ret_code then
    local ErrorCode = Rsp.ret_info.ret_code
    if 0 ~= ErrorCode then
      Log.Error(string.format("[OnTssReportDataRsp] ErrorCode:%d Msg:%s", ErrorCode, Rsp.ret_info.ret_msg))
      self:TssReportFailedData()
    else
      self.bPauseReportNextAntiData = false
    end
  else
    Log.Error("[OnTssReportDataRsp] Invalid rsp")
  end
end

function NRCSDKManager:TssReportFailedData()
  if self.LastTssReportData then
    local Request = _G.ProtoMessage:newZoneClientReportDataReq()
    Request.report_data = self.LastTssReportData
    Request.type = 1
    Log.Debug("[TssReportFailedData] AntiData:", Request.report_data)
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_REPORT_DATA_REQ, Request, self, self.OnTssReportDataRsp)
  end
end

function NRCSDKManager:GetTssSdkCoreDataAndReport(SendType, BattleId)
  if self.bEnableTssSDK and self.bind then
    local AntiData = self.bind:GetTssSdkCoreData()
    if not string.IsNilOrEmpty(AntiData) then
      Log.Debug("[GetTssSdkCoreData] AntiData:", AntiData)
      local Request = _G.ProtoMessage:newZoneClientReportDataReq()
      Request.report_data = AntiData
      Request.type = 2
      Request.send_type = SendType
      Request.battle_id = BattleId
      _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_REPORT_DATA_REQ, Request)
    else
      Log.Warning("[NRCSDKManager:GetTssSdkCoreDataAndReport] AntiData is nil or empty.")
    end
  end
end

function NRCSDKManager:CheckFeartureDataVaild(Name, Data, Length, Crc)
  if string.IsNilOrEmpty(Name) then
    Log.Error("[NRCSDKManager:CheckFeartureDataVaild] Name is nil or empty.")
    return false
  end
  if string.IsNilOrEmpty(Data) then
    Log.Error("[NRCSDKManager:CheckFeartureDataVaild] Data is nil or empty.")
    return false
  end
  if not Length or 0 == Length then
    Log.Error("[NRCSDKManager:CheckFeartureDataVaild] Length is nil or empty.")
    return false
  end
  if not Crc or 0 == Crc then
    Log.Error("[NRCSDKManager:CheckFeartureDataVaild] Crc is nil or empty.")
    return false
  end
  return true
end

function NRCSDKManager:OnLightFeatureReceived(Name, Data, Length, Crc)
  Log.Debug("[NRCSDKManager:OnLightFeatureReceived]")
  if not self:CheckFeartureDataVaild(Name, Data, Length, Crc) then
    Log.Error("[OnLightFeatureReceived] Invalid data")
    return
  end
  if RocoEnv.PLATFORM_WINDOWS then
    if self.bEnableACESDK then
      UE.UACESDKStatics.ACEOnLightFeatureReceived(Name, Data, Length, Crc)
    end
  elseif self.bEnableTssSDK and self.bind then
    self.bind:TssOnLightFeatureReceived(Name, Data, Length, Crc)
  end
end

function NRCSDKManager:GetLightFeaturePacket()
  Log.Debug("[NRCSDKManager:GetLightFeaturePacket]")
  if RocoEnv.PLATFORM_WINDOWS then
    if self.bEnableACESDK then
      return UE.UACESDKStatics.AceGetLightFeaturePacket()
    end
  elseif self.bEnableTssSDK and self.bind then
    self.bSendTssData2ThisTime = not self.bSendTssData2ThisTime
    if self.bSendTssData2ThisTime then
      local AntiData = self.bind:GetTssSdkCoreData()
      return AntiData
    else
      return self.bind:TssGetLightFeaturePacket()
    end
  end
  return nil
end

function NRCSDKManager:SendLightFeatureReportData()
  if self.bEnableACESDK or self.bEnableTssSDK then
    Log.Debug("[NRCSDKManager:SendLightFeatureReportData]")
    local Data = self:GetLightFeaturePacket()
    if string.IsNilOrEmpty(Data) then
      Log.Error("[NRCSDKManager:SendLightFeatureReportData] Data is nil or empty.")
      return
    end
    local Req = _G.ProtoMessage:newZoneClientReportLightFeatureReq()
    Req.report_data = Data
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_REPORT_LIGHT_FEATURE_REQ, Req)
  end
end

function NRCSDKManager:OnRecvServerTssReportData(ZoneReportDataSend2Client)
  if ZoneReportDataSend2Client and not string.IsNilOrEmpty(ZoneReportDataSend2Client.report_data) then
    local AntiData = ZoneReportDataSend2Client.report_data
    local Length = string.len(AntiData)
    Log.Debug("[NRCSDKManager:OnRecvServerTssReportData] AntiData:", AntiData)
    if RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_OPENHARMONY then
      if self.bind then
        self.bind:OnRecvTssSvrDataToTssClient(AntiData, Length)
      end
    elseif RocoEnv.PLATFORM_WINDOWS then
      if not self.bEnableACESDK then
        return
      end
      UE.UACESDKStatics.ACEReceiveGameServerPacket(AntiData, Length)
    end
  else
    Log.Warning("[NRCSDKManager:OnRecvServerTssReportData] report_data is nil or empty.")
  end
end

function NRCSDKManager:CallTssSDKSetUserInfo(EntryId, OpenId)
  if self.bEnableTssSDK and self.bind then
    local OpenIdStr = tostring(OpenId)
    Log.Error(string.format("[NRCSDKManager:CallTssSDKSetUserInfo] EntryId:%s, OpenId:%s ", EntryId, OpenIdStr))
    self.bind:CallTssSDKSetUserInfo(EntryId, OpenIdStr)
  end
end

function NRCSDKManager:OnEnterForeground()
  Log.Debug("[NRCSDKManager:OnEnterForeground]")
  if self.bind then
    self.bind:CallTssSDKOnResume()
  end
end

function NRCSDKManager:OnEnterBackground()
  Log.Debug("[NRCSDKManager:OnEnterBackground]")
  if self.bind then
    self.bind:CallTssSDKOnPause()
  end
end

function NRCSDKManager:OnConnected()
  Log.Debug("[NRCSDKManager:OnConnected]")
  if (self.bEnableACESDK or self.bEnableTssSDK) and not self.LoopLightFeatureReportTimer then
    Log.Debug("[NRCSDKManager:OnConnected] Add LoopLightFeatureReportTimer timer")
    self.LoopLightFeatureReportTimer = _G.TimerManager:CreateTimer(self, "SendLightFeatureReportData", math.maxinteger, self.SendLightFeatureReportData, nil, 15)
  end
  if self.bEnableTssSDK and not self.LoopTssReportTimer then
    Log.Debug("[NRCSDKManager:OnConnected] Add LoopTssReportTimer timer")
    self.LoopTssReportTimer = _G.TimerManager:CreateTimer(self, "SendTssDataToSvrIfNecessary", math.maxinteger, self.SendTssDataToSvrIfNecessary, nil, 5)
  end
  if self.bEnableACESDK then
    Log.Debug("ACERecordClientLogIn invoked")
    local AccountID = tostring(_G.NRCModuleManager:GetModule("OnlineModule"):GetData("OnlineModuleData").openid)
    if not self.bRecordConnected then
      UE.UACESDKStatics.ACERecordClientLogIn(AccountID, "null")
      self.bRecordConnected = true
    end
    if not self.LoopAceReportTimer then
      Log.Debug("[NRCSDKManager:OnConnected] Add LoopAceReportTimer")
      self.LoopAceReportTimer = _G.TimerManager:CreateTimer(self, "SendACEDataToSvrIfNecessary", math.maxinteger, self.SendACEDataToSvrIfNecessary, nil, 0.1)
    end
  end
end

function NRCSDKManager:OnDisconnect()
  Log.Debug("[NRCSDKManager:OnDisconnect]")
  if self.bEnableACESDK or self.bEnableTssSDK then
    _G.TimerManager:RemoveTimer(self.LoopLightFeatureReportTimer)
    self.LoopLightFeatureReportTimer = nil
  end
  if self.bEnableTssSDK then
    _G.TimerManager:RemoveTimer(self.LoopTssReportTimer)
    self.LoopTssReportTimer = nil
  end
  if self.bEnableACESDK then
    _G.TimerManager:RemoveTimer(self.LoopAceReportTimer)
    self.LoopAceReportTimer = nil
    if self.bRecordConnected then
      UE.UACESDKStatics.ACERecordClientLogout()
      self.bRecordConnected = false
    end
  end
end

function NRCSDKManager:OpenCreditScoreWebView()
  local url_windows = _G.DataConfigManager:GetGlobalConfigStrByKeyType("credit_score_web_view_windows_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  local url_mobile = _G.DataConfigManager:GetGlobalConfigStrByKeyType("credit_score_web_view_mobile_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  if RocoEnv.PLATFORM_WINDOWS then
    local url = url_windows
    self:OpenWebView(url, 1, true)
  else
    local Url = url_mobile
    local PlayerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
    if PlayerName then
      Url = Url .. "?rolename=" .. PlayerName
    end
    self:OpenWebView(Url)
  end
end

function NRCSDKManager:ShowCreditScoreNotEnoughDialog(CreditScoreNotEnoughType)
  local ContentText
  if CreditScoreNotEnoughType == NRCSDKManagerEnum.CreditScoreNotEnoughType.Chat then
    ContentText = LuaText.Credit_Score_Description1
  elseif CreditScoreNotEnoughType == NRCSDKManagerEnum.CreditScoreNotEnoughType.AddFriend then
    ContentText = LuaText.Credit_Score_Description2
  elseif CreditScoreNotEnoughType == NRCSDKManagerEnum.CreditScoreNotEnoughType.GetQualificationCode then
    ContentText = LuaText.Credit_Score_Description3
  end
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.Credit_Score_Description4):SetContent(ContentText):SetCallback(self, function(this, result)
    if not result then
      this:OpenCreditScoreWebView()
    end
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function NRCSDKManager:OpenPrivacyHelper()
  local baseUrl = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_helper_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  if RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    self:ShowGRobotH5(NRCSDKManagerEnum.GRobot.SOURCE_PRIVACY, baseUrl, NRCSDKManagerEnum.ScreenType.Landscape)
  elseif RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    self:ShowGRobotH5(NRCSDKManagerEnum.GRobot.SOURCE_PRIVACY, baseUrl, NRCSDKManagerEnum.ScreenType.Default)
  else
    self:ShowGRobotH5(NRCSDKManagerEnum.GRobot.SOURCE_PRIVACY, baseUrl, NRCSDKManagerEnum.ScreenType.Landscape)
  end
end

function NRCSDKManager:GetMidasObserver()
  if self.MidasObserver ~= nil then
    return self.MidasObserver
  end
end

function NRCSDKManager:UpdateTGPAInfo(uin)
  if not RocoEnv.IS_EDITOR then
    UE.UGPMStatics.UpdateGameInfoIntInt(7, math.tointeger(UE4.UNRCStatics.GetConsoleVarFloat("t.MaxFPS")))
  end
  if not RocoEnv.PLATFORM_IOS and not RocoEnv.PLATFORM_ANDROID and not RocoEnv.PLATFORM_OPENHARMONY then
    return
  end
  local xid = UE.UNRCDeviceInfoHelper.GetDeviceInfo("XID", "")
  if string.IsNilOrEmpty(xid) then
    Log.Error("empty xid when update tgpa info")
    return
  end
  if RocoEnv.PLATFORM_IOS and 44 ~= string.len(xid) or RocoEnv.PLATFORM_ANDROID and 64 ~= string.len(xid) or RocoEnv.PLATFORM_OPENHARMONY and 58 ~= string.len(xid) then
    Log.Error("invalid xid length " .. xid)
  end
  Log.Debug("UpdateTGPAInfo with xid: " .. xid)
  local playerInfoMap = UE.TMap("", "")
  local userAccountInfo = _G.NRCModuleManager:GetModule("OnlineModule") and _G.NRCModuleManager:GetModule("OnlineModule"):GetUserAccountInfo()
  if not userAccountInfo then
    Log.Error("nil userAccountInfo when update TGPA info")
    return
  end
  local appId = ""
  local platId = ""
  if userAccountInfo.loginChannelType == _G.Enum.CliLoginChannel.CLC_QQ then
    appId = "1110613799"
    platId = "QQ"
  elseif userAccountInfo.loginChannelType == _G.Enum.CliLoginChannel.CLC_WX then
    appId = "wxdca9f9a612d43085"
    platId = "Wechat"
  else
    Log.Error("invalid login channel when update TGPA info")
    return
  end
  local openId = userAccountInfo and userAccountInfo.openid or 0
  local areaid = 1
  local mainVersion = _G.AppMain:GetAppVersion()
  local subVersion = _G.AppMain:GetResVersion()
  playerInfoMap:Add("openid", openId)
  playerInfoMap:Add("roleid", uin or 0)
  playerInfoMap:Add("areaid", areaid)
  playerInfoMap:Add("appid", appId)
  playerInfoMap:Add("platid", platId)
  playerInfoMap:Add("mainversion", mainVersion)
  playerInfoMap:Add("subversion", subVersion)
  playerInfoMap:Add("gopenid", openId)
  UE.UGPMStatics.UpdateGameInfoMap("DeviceBind", playerInfoMap)
end

function NRCSDKManager:OnPlayerLogin(_, uin)
  self:UpdateTGPAInfo(uin)
  self:OpenGameletSDK()
  if (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY) and _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.playerInfo then
    local playerBriefInfo = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info
    if playerBriefInfo and playerBriefInfo.sex ~= ProtoEnum.ESexValue.SEX_NOT_SEL and playerBriefInfo.sex ~= ProtoEnum.ESexValue.SEX_NOT_SHOW then
      self:ParseDeepLinkParam(nil)
    end
  end
end

function NRCSDKManager:OpenGameletSDK()
  Log.Debug("[NRCSDKManager:OnPlayerLogin]")
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if playerInfoData.loginChannel == nil then
    Log.Debug("no valid playerInfoData")
    return
  end
  local userData = UE4.TMap("", "")
  local accountType = ""
  local appID = ""
  local area = 1
  userData:Add("sOpenId", playerInfoData.openid)
  if RocoEnv.PLATFORM_WINDOWS then
    if not RocoEnv.IS_EDITOR then
      accountType = "wegame"
      appID = "2002304"
      area = string.lower(playerInfoData.loginChannel) == "wechat" and 1 or string.lower(playerInfoData.loginChannel) == "qq" and 2
      userData:Add("sPartition", area)
    else
      accountType = string.lower(playerInfoData.loginChannel) == "wechat" and "wx" or "qq"
      appID = string.lower(playerInfoData.loginChannel) == "wechat" and "wxdca9f9a612d43085" or "1110613799"
      area = string.lower(playerInfoData.loginChannel) == "wechat" and 1 or 2
      userData:Add("sPlatID", "1")
    end
  elseif string.lower(playerInfoData.loginChannel) == "wechat" then
    appID = "wxdca9f9a612d43085"
    accountType = "wx"
    area = 1
  elseif string.lower(playerInfoData.loginChannel) == "qq" then
    appID = "1110613799"
    accountType = "qq"
    area = 2
  end
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
  userData:Add("sPlatID", (not RocoEnv.IS_EDITOR or not "1") and (not RocoEnv.PLATFORM_WINDOWS or not "2") and (not RocoEnv.PLATFORM_ANDROID or not "1") and (not RocoEnv.PLATFORM_IOS or not "0") and RocoEnv.PLATFORM_OPENHARMONY and "12")
  userData:Add("sServerPlatID", (not RocoEnv.PLATFORM_WINDOWS or not "2") and not RocoEnv.PLATFORM_ANDROID and (not RocoEnv.PLATFORM_OPENHARMONY or not "1") and RocoEnv.PLATFORM_IOS and "0")
  userData:Add("sRoleId", nil ~= roleName and roleName or "")
  userData:Add("sAccountType", accountType)
  userData:Add("sAppId", appID)
  userData:Add("sArea", area)
  userData:Add("sAccessToken", nil ~= playerInfoData.accessToken and playerInfoData.accessToken or "")
  userData:Add("sGameVer", nil ~= _G.AppMain:GetAppVersion() and _G.AppMain:GetAppVersion() or "")
  userData:Add("sServiceType", "rocom")
  Log.Debug("[NRCSDKManager:OnPlayerLogin] before Open Gamelet")
  UE.UGamelet.Get():Open(RocoEnv.IS_SHIPPING and UE.EGameletEnvironment.Gamelet_Product or UE.EGameletEnvironment.Gamelet_Test, userData)
  Log.Debug("[NRCSDKManager:OnPlayerLogin] before After Gamelet")
end

function NRCSDKManager:OnBackToLogin()
  self:CloseGamelet()
end

function NRCSDKManager:CloseGamelet()
  Log.Debug("[NRCSDKManager:CloseGamelet]")
  UE.UGamelet.Get():Close()
end

function NRCSDKManager:OnNewGameletAppPrepared(appId, appName)
  table.insert(self.whiteListAppId, appId)
end

function NRCSDKManager:HandleGameletStrMsg(funcName, str1, str2)
  if "OnGameletSDKMessage" == funcName then
    GameletImpl.OnGameletSDKMessage(self, str1)
  elseif "OnGameletRefreshUserData" == funcName then
    GameletImpl.OnGameletRefreshUserData(self)
  elseif "OnGameletReportData" == funcName then
    GameletImpl.OnGameletReportData(self, str1, str2)
  end
end

function NRCSDKManager:HandleGameletWidgetMsg(funcName, widget, str)
  if "OnGameViewCreated" == funcName then
    GameletImpl.OnGameViewCreated(self, widget, str)
  elseif "OnGameletViewDestroyed" == funcName then
    GameletImpl.OnGameletViewDestroyed(self, widget, str)
  end
end

function NRCSDKManager:GetChannelInfoOnPC()
  if self.bind and UE4.UObject.IsValid(self.bind.WeGameManager) then
    return self.bind.WeGameManager:GetChannelInfo()
  else
    Log.Error("invalid WegameManager")
    return ""
  end
end

function NRCSDKManager:CouldQueryWeGameFriend()
  return self.bind.WeGameManager and self.bind.WeGameManager:IsUseNormalWeGame()
end

function NRCSDKManager:GetWeGameFriendsInfo()
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if not self:CouldQueryWeGameFriend() then
    return
  end
  local userAccountInfo = _G.NRCModuleManager:GetModule("OnlineModule") and _G.NRCModuleManager:GetModule("OnlineModule"):GetUserAccountInfo()
  if not userAccountInfo or string.IsNilOrEmpty(userAccountInfo.loginChannel) then
    Log.Error("make sure use this function with wegame env")
    return
  end
  local curPlayerOpenId = userAccountInfo.openid
  if curPlayerOpenId and self.bind and UE4.UObject.IsValid(self.bind.WeGameManager) then
    self.bind.WeGameManager:AsyncQueryFriendsListResult(curPlayerOpenId, "")
  end
end

function NRCSDKManager:GetWeGameFriendsOnlineInfo(openIds, extInfo)
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  local userAccountInfo = _G.NRCModuleManager:GetModule("OnlineModule") and _G.NRCModuleManager:GetModule("OnlineModule"):GetUserAccountInfo()
  if not userAccountInfo or string.IsNilOrEmpty(userAccountInfo.loginChannel) then
    Log.Error("make sure use this function with wegame env")
    return
  end
  if self.bind and UE4.UObject.IsValid(self.bind.WeGameManager) then
    local openIdArray = UE.TArray("")
    if openIds and type(openIds) == "table" and "string" == type(extInfo) then
      local length = table.len(openIds)
      local lengthLimit = self.bind.WeGameManager.MaxQueryFriendsLimit
      if length > lengthLimit then
        Log.Error("GetWeGameFriendsInfo openIds length exceeds limit")
        return
      end
      for i = 1, length do
        openIdArray:Add(openIds[i])
      end
    else
      Log.Error("GetWeGameFriendsInfo with invalid param")
      return
    end
    self.bind.WeGameManager:AsyncQueryFriendsOnlineState(openIdArray, extInfo)
  else
    Log.Error("No valid wegameManager")
  end
end

function NRCSDKManager:InviteWeGameFriend(targetOpenId)
  if not RocoEnv.PLATFORM_WINDOWS then
    return math.mininteger
  end
  local userAccountInfo = _G.NRCModuleManager:GetModule("OnlineModule") and _G.NRCModuleManager:GetModule("OnlineModule"):GetUserAccountInfo()
  if not userAccountInfo or string.IsNilOrEmpty(userAccountInfo.loginChannel) then
    Log.Error("make sure use this function with wegame env")
    return math.mininteger
  end
  local extraAccountInfo = userAccountInfo.extraAccountInfo
  if extraAccountInfo then
    local avatarUrl = extraAccountInfo.avatarUrl
    local nickName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
    if self.bind and UE4.UObject.IsValid(self.bind.WeGameManager) then
      return self.bind.WeGameManager:InviteWeGameFriend(userAccountInfo.openid, nickName, avatarUrl, targetOpenId)
    end
  else
    Log.Error("No valid extraAccountInfo")
  end
  return math.mininteger
end

function NRCSDKManager:GetBranchInfo()
  if self.WeGameObserver ~= nil then
    UE4.UNRCPlatformGameInstance.GetInstance():GetSDKManager().WeGameManager:GetBranchInfo(self.WeGameObserver)
  else
    Log.Error("WeGameObserver in NRCSDKManager is nil")
  end
end

function NRCSDKManager:ParseDeepLinkParam(launchQuery)
  if not NRCModuleManager:GetModule("OnlineModule") or not _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetLoginState) then
    Log.Debug("not isLogin when ParseDeepLinkParam invoked with launchQuery: " .. launchQuery)
    return
  end
  
  local function NotifyPandora(contentTable)
    if table.containsKey(contentTable, "tlk-token-params") then
      local tokenLinkTable = {
        type = "pandoraGetTokenLinkInfo",
        content = contentTable["tlk-token-params"]
      }
      local tokenLinkStr = JsonUtils.EncodeTable(tokenLinkTable)
      local res = UE.UGamelet.Get():SendMessageToApp("*", tokenLinkStr)
      Log.Debug("deepLink SendMessageToApp to Pandora tokenLinkStr is " .. tokenLinkStr .. ", send res:" .. res)
    end
  end
  
  local dpLaunchParam = not string.IsNilOrEmpty(launchQuery) and launchQuery or UE.UNativeExtensionUtils.GetDeepLinkLaunchParam()
  Log.Debug("DPLaunchParam is ", dpLaunchParam)
  if string.IsNilOrEmpty(dpLaunchParam) then
    Log.Debug("DPLaunchParam empty")
    return
  end
  UE.UNativeExtensionUtils.GetInstance():SetDeepLinkLaunchParam("")
  local dpLaunchParamTable = {}
  if string.find(dpLaunchParam, "&") then
    dpLaunchParamTable = string.Split(dpLaunchParam, "&")
  elseif string.find(dpLaunchParam, "=") then
    table.insert(dpLaunchParamTable, dpLaunchParam)
  end
  if #dpLaunchParamTable < 1 then
    Log.Error("dpLaunchParamTable length < 1")
    return
  end
  local notifyTable = {}
  for _, query in ipairs(dpLaunchParamTable) do
    local pos = string.find(query, "=")
    if pos ~= #query then
      notifyTable[string.sub(query, 1, pos - 1)] = string.sub(query, pos + 1)
    end
  end
  if table.len(notifyTable) < 1 then
    Log.Error("notifyTable length < 1")
    return
  end
  NotifyPandora(notifyTable)
  local gameData = notifyTable.gamedata
  if string.IsNilOrEmpty(gameData) then
    Log.Debug("gameData empty")
    return
  end
  if not _G.BattleManager or _G.BattleManager:IsInBattle(true) then
    Log.Error("player status invalid")
    return
  end
  if string.StartsWith(gameData, "JUMPOPEx") then
    if RocoEnv.PLATFORM_OPENHARMONY or RocoEnv.PLATFORM_WINDOWS then
      return
    end
    local jumpParam = string.Split(gameData, "_")
    if #jumpParam < 3 then
      Log.Debug("invalid gameData:", gameData)
      return
    end
    Log.Dump(jumpParam, 2, "jump param for deep link")
    local jumpType = jumpParam[2]
    if 1 == jumpType or "1" == jumpType then
      local function UrlDecode(str)
        if str then
          str = string.gsub(str, "%%(%x%x)", function(h)
            return string.char(tonumber(h, 16))
          end)
          str = string.gsub(str, "+", " ")
          return str
        end
        return ""
      end
      
      local url = jumpParam[3]
      url = UrlDecode(url)
      local pageDirection, pageFullScreen
      local landScapeFlag = 1
      local portraitFlag = 2
      local fullScreenFlag = 4
      if #jumpParam >= 4 then
        local pageDirParam = jumpParam[4]
        if pageDirParam | landScapeFlag then
          pageDirection = NRCSDKManagerEnum.WebViewDirectionType.LandScape
        elseif pageDirParam | portraitFlag then
          pageDirection = NRCSDKManagerEnum.WebViewDirectionType.Portrait
        else
          pageDirection = NRCSDKManagerEnum.WebViewDirectionType.Auto
        end
        pageFullScreen = pageDirParam | fullScreenFlag
      end
      local gopenId = _G.NRCModuleManager:GetModule("OnlineModule"):GetData():GetOpenID() ~= nil and _G.NRCModuleManager:GetModule("OnlineModule"):GetData():GetOpenID() or 0
      local uin = nil ~= _G.DataModelMgr.PlayerDataModel:GetPlayerUin() and _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
      if string.find(url, "?") then
        url = url .. "&"
      else
        url = url .. "?"
      end
      local plat_id = RocoEnv.PLATFORM_IOS and 0 or 1
      url = url .. "openid=" .. gopenId .. "&area=" .. (_G.AppMain:GetFormalPipeline() and 137 or 60) .. "&platid=" .. plat_id .. "&partition=0&roleid=" .. uin
      self.bNeedOpenActivityPage = true
      self.ActivityPageParams = {
        urlParam = url,
        pageDirectionParam = nil ~= pageDirection and pageDirection or NRCSDKManagerEnum.WebViewDirectionType.Auto,
        pageFullScreenParam = nil ~= pageFullScreen and pageFullScreen or false
      }
      local statusChecker = StatusCheckerGroup({
        StatusCheckerEnum.Scene,
        StatusCheckerEnum.Loading,
        StatusCheckerEnum.FastLoading
      }, Log.LOG_LEVEL.ELogDebug, "NRCSDKManager")
      if statusChecker and statusChecker:CheckPass() then
        UE4.UWebViewStatics.OpenURL(url, nil ~= pageDirection or NRCSDKManagerEnum.WebViewDirectionType.Auto, nil ~= pageFullScreen and pageFullScreen or false, true)
        return
      end
      _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterScene)
    elseif 2 == jumpType or "2" == jumpType then
      local umgID = jumpParam[3]
      local activityId = jumpParam[4]
      if not string.IsNilOrEmpty(activityId) and _G.DataConfigManager:GetActivityConf(activityId) then
        _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenMainPanel, activityId)
      end
    end
  else
    _G.NRCEventCenter:DispatchEvent(NRCSDKManagerEvent.OnDeepLinkMessageNotify, dpLaunchParam)
  end
end

function NRCSDKManager:StartShowBgDownloadNotification()
  if self.bind then
    Log.Debug("StartShowBgDownloadNotification")
    self.bind:StartShowBgDownloadNotification()
  end
end

function NRCSDKManager:UpdateBgDownloadNotificationTitle(Title)
  if self.bind then
    self.bind:UpdateBgDownloadNotificationTitle(Title)
  end
end

function NRCSDKManager:EndShowBgDownloadNotification()
  if self.bind then
    Log.Debug("EndShowBgDownloadNotification")
    self.bind:EndShowBgDownloadNotification()
  end
end

function NRCSDKManager:UpdateBgDownloadProgress(ProgressStr)
  if self.bind then
    self.bind:UpdateBgDownloadProgress(ProgressStr)
  end
end

function NRCSDKManager:ShowGRobotH5(xy_source, base_url, screen_type)
  local baseUrl = base_url
  if xy_source == NRCSDKManagerEnum.GRobot.SOURCE_PC or xy_source == NRCSDKManagerEnum.GRobot.SOURCE_GAMES then
    baseUrl = base_url .. string.format(NRCSDKManagerEnum.GRobot.GAMES_H5_URL_PATH, NRCSDKManagerEnum.GRobot.GAME_ID)
  end
  Log.Info("NRCSDKManager:ShowGRobotH5 ", base_url, xy_source, screen_type)
  local userAccountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if not userAccountInfo then
    Log.Error("NRCSDKManager:ShowGRobot no valid userAccountInfo")
    return
  end
  local platId
  if xy_source == NRCSDKManagerEnum.GRobot.SOURCE_PRIVACY then
    if RocoEnv.PLATFORM_ANDROID then
      platId = NRCSDKManagerEnum.GRobot.PRIVACY_PLAT_ID_ANDROID
    elseif RocoEnv.PLATFORM_IOS then
      platId = NRCSDKManagerEnum.GRobot.PRIVACY_PLAT_ID_IOS
    elseif RocoEnv.PLATFORM_WINDOWS then
      platId = NRCSDKManagerEnum.GRobot.PRIVACY_PLAT_ID_WINDOWS
    elseif RocoEnv.PLATFORM_OPENHARMONY then
      platId = NRCSDKManagerEnum.GRobot.PRIVACY_PLAT_ID_HARMONY_NEXT
    end
  elseif xy_source == NRCSDKManagerEnum.GRobot.SOURCE_GAMES or xy_source == NRCSDKManagerEnum.GRobot.SOURCE_PC then
    local channelName = userAccountInfo.loginChannel
    if channelName == LoginEnum.ChannelNames.QQ then
      platId = NRCSDKManagerEnum.GRobot.GAMES_H5_PLAT_ID_QQ
    elseif channelName == LoginEnum.ChannelNames.WeChat then
      platId = NRCSDKManagerEnum.GRobot.GAMES_H5_PLAT_ID_WX
    else
      platId = NRCSDKManagerEnum.GRobot.GAMES_H5_PLAT_ID_VISITOR
    end
  else
    Log.Error("NRCSDKManager:ShowGRobot no valid xy_source ", xy_source)
    return
  end
  if nil == platId then
    Log.Error("NRCSDKManager:ShowGRobot no valid platId")
    return
  end
  local systemId
  local channelName = userAccountInfo.loginChannel
  if xy_source == NRCSDKManagerEnum.GRobot.SOURCE_PRIVACY then
    if channelName == LoginEnum.ChannelNames.QQ then
      systemId = NRCSDKManagerEnum.GRobot.PRIVACY_SYSTEM_ID_QQ
    elseif channelName == LoginEnum.ChannelNames.WeChat then
      systemId = NRCSDKManagerEnum.GRobot.PRIVACY_SYSTEM_ID_WX
    end
  elseif xy_source == NRCSDKManagerEnum.GRobot.SOURCE_GAMES or xy_source == NRCSDKManagerEnum.GRobot.SOURCE_PC then
    if RocoEnv.PLATFORM_ANDROID then
      systemId = NRCSDKManagerEnum.GRobot.GAMES_H5_SYSTEM_ID_ANDROID
    elseif RocoEnv.PLATFORM_IOS then
      systemId = NRCSDKManagerEnum.GRobot.GAMES_H5_SYSTEM_ID_IOS
    elseif RocoEnv.PLATFORM_WINDOWS then
      systemId = NRCSDKManagerEnum.GRobot.GAMES_H5_SYSTEM_ID_WINDOWS
    elseif RocoEnv.PLATFORM_OPENHARMONY then
      systemId = NRCSDKManagerEnum.GRobot.GAMES_H5_SYSTEM_ID_HARMONY_NEXT
    end
  end
  if nil == systemId then
    Log.Error("NRCSDKManager:ShowGRobot no valid systemId")
    return
  end
  local appId = ""
  if channelName == LoginEnum.ChannelNames.QQ then
    appId = NRCSDKManagerEnum.Common.APP_ID_QQ
  elseif channelName == LoginEnum.ChannelNames.WeChat then
    appId = NRCSDKManagerEnum.Common.APP_ID_WX
  end
  local msdkEnv = NRCSDKManagerEnum.GRobot.MSDK_ENV_PUB
  if RocoEnv.IS_SHIPPING then
    msdkEnv = NRCSDKManagerEnum.GRobot.MSDK_ENV_PUB
  else
    msdkEnv = NRCSDKManagerEnum.GRobot.MSDK_ENV_DEV
  end
  local paramTable = {
    [1] = {
      game_id = NRCSDKManagerEnum.GRobot.GAME_ID
    },
    [2] = {source = xy_source},
    [3] = {
      login_type = NRCSDKManagerEnum.GRobot.LOGIN_TYPE
    },
    [4] = {system_id = systemId},
    [5] = {plat_id = platId},
    [6] = {
      role_id = tostring(userAccountInfo.openid)
    },
    [7] = {appid = appId},
    [8] = {area_id = 0},
    [9] = {partition_id = "0"},
    [10] = {msdkenv = msdkEnv}
  }
  if xy_source == NRCSDKManagerEnum.GRobot.SOURCE_GAMES or xy_source == NRCSDKManagerEnum.GRobot.SOURCE_PC then
    table.insert(paramTable, {
      open_id = tostring(userAccountInfo.openid)
    })
  end
  if RocoEnv.PLATFORM_WINDOWS then
    table.insert(paramTable, {
      msdktype = NRCSDKManagerEnum.GRobot.PC_MSDK_TYPE
    })
  end
  Log.Dump(paramTable, 99, "NRCSDKManager:ShowGRobot paramTable")
  local paramStr = ""
  local isFirstParam = true
  for index, valTable in ipairs(paramTable) do
    for key, value in pairs(valTable) do
      if isFirstParam then
        paramStr = string.format("%s=%s", key, value)
      else
        paramStr = string.format("%s&%s=%s", paramStr, key, value)
      end
      isFirstParam = false
    end
  end
  local encodedBaseUrl = UE4.UWebViewStatics.GetEncodeURL(baseUrl)
  Log.Info("NRCSDKManager:ShowGRobot encodedBaseUrl: ", encodedBaseUrl)
  local url = string.format("%s&%s", encodedBaseUrl, paramStr)
  Log.Info("ShowGRobotH5: url: ", url)
  self:OpenWebView(url, screen_type, true)
end

function NRCSDKManager:ShowGRobot()
  Log.Info("NRCSDKManager:ShowGRobot use H5 version")
  local baseUrl
  if RocoEnv.IS_SHIPPING then
    baseUrl = _G.DataConfigManager:GetGlobalConfigStrByKeyType("zhiji_wbe", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  else
    baseUrl = _G.DataConfigManager:GetGlobalConfigStrByKeyType("zhiji_wbe_test", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  end
  Log.Info("baseUrl = " .. baseUrl)
  if not baseUrl then
    Log.Error("NRCSDKManager:ShowGRobot no valid baseUrl")
    return
  end
  if RocoEnv.PLATFORM_WINDOWS then
    self:ShowGRobotH5(NRCSDKManagerEnum.GRobot.SOURCE_PC, baseUrl, NRCSDKManagerEnum.ScreenType.Default)
  else
    self:ShowGRobotH5(NRCSDKManagerEnum.GRobot.SOURCE_GAMES, baseUrl, NRCSDKManagerEnum.ScreenType.Landscape)
  end
end

function NRCSDKManager:CloseGRobot()
  if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS then
    Log.Info("NRCSDKManager:CloseGRobot")
    UE.UGRobotStatics.CloseGRobot()
  end
end

function NRCSDKManager:CallReLogin(errorCode)
  if errorCode ~= ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PAY_TOKEN_INVALID then
    return
  end
  local content = string.format(LuaText.charge_tips_19, tostring(errorCode))
  
  local function ReLogin()
    if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
      local userAccountInfo = NRCModuleManager:DoCmd(OnlineModuleCmd.GetUserAccountInfo)
      local loginChannel = userAccountInfo.loginChannel
      if table.contains(LoginEnum.ChannelNames, loginChannel) then
        Log.Debug("LoginStatics.Login invoked")
        local loginExtraParam = ""
        if string.lower(loginChannel) == "wechat" and not UE.ULoginStatics.IsVxInstalled() then
          loginExtraParam = "{\"QRCode\":true}"
        end
        UE.ULoginStatics.Login(loginChannel, "", "", loginExtraParam)
      else
        Log.Error("invalid channel")
        return
      end
    elseif RocoEnv.PLATFORM_WINDOWS then
      UE.UNRCStatics.QuitGame()
    end
  end
  
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(LuaText.umg_login_new_2):SetContent(content):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.charge_tips_21, LuaText.charge_tips_20):SetCallbackOkOnly(self, ReLogin)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

return NRCSDKManager

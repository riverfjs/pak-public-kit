UEPrintLog("NRC Init------------APPMaineInit-------------")
local JsonUtils = require("Common.JsonUtils")
local rapidjson = require("rapidjson")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local AppMain = {}
local this = AppMain
this.hasSetup = false
this.isPause = false
this.TotalShaderPrecompiles = 0
this.launchParams = {}
this.isEnterBackground = false
this.isPIEEnded = false
this.enableScreenSaver = true
this.isAuditVersion = false
this.userDefineStr = ""
this.AppleASA = nil
this.desireReleaseCursorCapture = false
UEPrintLog("------------AppMain-------------")

local function SetEnv()
  Log.Debug("AppMain RocoEnv.IS_EDITOR", RocoEnv.IS_EDITOR)
  if RocoEnv.IS_EDITOR then
    _G.USE_LUA_RELOAD = true
  else
    _G.USE_LUA_RELOAD = false
  end
end

local function HookDebug()
  require("debugger.mobdebug").start()
end

function AppMain.Setup()
  if AppMain.hasSetup then
    return this
  end
  AppMain.hasSetup = true
  SetEnv()
  _G.NRCGlobalEvent = require("Common.NRCGlobalEvent")
  _G.Log.SetPrintCallback(_G.Log.LOG_LEVEL.ELogDebug, UEPrintWithTime)
  _G.Log.SetPrintCallback(_G.Log.LOG_LEVEL.ELogTrace, UEPrintWithTime)
  _G.Log.SetPrintCallback(_G.Log.LOG_LEVEL.ELogInfo, UEPrintWithTime)
  _G.Log.SetPrintCallback(_G.Log.LOG_LEVEL.ELogWarn, UEPrintWarningWithTime)
  _G.Log.SetPrintCallback(_G.Log.LOG_LEVEL.ELogError, UEPrintErrorWithTime)
  _G.Log.SetPrintCallback(_G.Log.LOG_LEVEL.ELogFatal, UEPrintFatalWithTime)
  if RocoEnv.IS_EDITOR and _G.NRCEditorEntranceEnable then
    return
  end
  this.DecodeLaunchParams()
  this.InitVersion()
  return this
end

function AppMain.OnStart()
  UE4.UNRCStatics.SetEnableRocoPreInputProcessor(true)
  UE4.UNRCTUIStatics.SetEnableCustomUIAsyncLoader(true)
  UE4.UNRCTUIStatics.SetEnableCustomTUIUtils(true)
  UE4.UNRCTUIStatics.SetLongPressGesture(false)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" and not this.hasInitHardwareCursors then
    this.hasInitHardwareCursors = UE4.UNRCTUIStatics.ReplaceWithHardwareCursors(_G.UE4Helper.GetCurrentWorld())
  end
  UE.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.NRCAvatarWaitForStreamInWhenLoadSuit 0")
end

function AppMain.BackToLogin(forceCleanupLua)
  local curMode = _G.NRCModeManager:GetCurMode()
  if curMode.modeName ~= "LoginMode" or forceCleanupLua then
    NRCEventCenter:DispatchEvent(NRCSDKManagerEvent.OnBackToLogin)
    local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
    if RocoEnv.PLATFORM_WINDOWS then
      if RocoEnv.IS_EDITOR then
        GameInstance:BackToLogin("/Game/Levels/Login")
      else
        local userAccountInfo = NRCModuleManager:GetModule("OnlineModule"):GetUserAccountInfo()
        if userAccountInfo then
          if not string.IsNilOrEmpty(userAccountInfo.loginChannel) then
            UE4.UNRCStatics.QuitGame()
          else
            GameInstance:BackToLogin("/Game/Levels/UpdateLevel")
          end
        end
      end
    else
      GameInstance:BackToLogin("/Game/Levels/UpdateLevel")
    end
  else
    _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.RestartLogin)
  end
end

function AppMain:IsBackToLogin()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    return GameInstance:IsBackToLogin()
  end
  return false
end

function AppMain:GetAppVersion()
  return this.AppVersion
end

function AppMain:GetAppRevision()
  return this.AppRevision
end

function AppMain:GetResVersion()
  return this.ResVersion
end

function AppMain:SetResVersion(NewResVersion)
  this.ResVersion = NewResVersion
end

function AppMain:GetResRevision()
  return this.ResRevision
end

function AppMain:GetDolphinChannel()
  local OverrideChannel = this.launchParams.dolphin_channel
  if not string.IsNilOrEmpty(OverrideChannel) then
    Log.Debug("[AppMain:GetDolphinChannel] OverrideChannel:", OverrideChannel)
    return OverrideChannel
  end
  return this.DolphinChannel
end

function AppMain:GetPreDownloadDolphinChannel()
  local OverrideChannel = this.launchParams.predownload_dolphin_channel
  if not string.IsNilOrEmpty(OverrideChannel) then
    Log.Debug("[AppMain:GetPreDownloadDolphinChannel] OverrideChannel:", OverrideChannel)
    return OverrideChannel
  end
  return this.DolphinChannel
end

function AppMain:GetPufferChannel()
  return this.PufferChannel
end

function AppMain:GetBuildStartTime()
  return this.BuildStartTime
end

function AppMain:GetFormalPipeline()
  return this.FormalPipeline
end

function AppMain:HasDebug()
  return not this.FormalPipeline
end

function AppMain:GetProjectBranch()
  return this.ProjectBranch
end

function AppMain:IsReleaseFormalEnv()
  local bRelease = true
  if not this.launchParams then
    Log.Error("AppMain.launchParams is nil")
  elseif this.launchParams.dolphin_url_key and this.launchParams.dolphin_url_key == "TestPre" then
    bRelease = false
  end
  return bRelease
end

function AppMain:GetDeviceId()
  if not this.DeviceId then
    if RocoEnv.PLATFORM_WINDOWS then
      this.DeviceId = RocoEnv.MAC_ADDR
    else
      this.DeviceId = UE4.UKismetSystemLibrary.GetDeviceId()
    end
  end
  return this.DeviceId
end

function AppMain.ReportDeviceCode(callback)
  local deviceCode = AppMain:GetDeviceId()
  if not deviceCode or "" == deviceCode then
    Log.Warning("[ReportDeviceCode] Device code is empty or nil.")
    if callback then
      callback(false, "device code is empty")
    end
    return
  end
  local url = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=9ac9d51e-d1bf-4be7-9068-c88903c47bd5"
  local appVersion = AppMain:GetAppVersion() or "unknown"
  local dataContent = string.format("version: %s, deviceId: %s", appVersion, deviceCode)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  AppMain.ReportDeviceCodeServiceRef = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:SetUrl(url)
  HttpService:SetVerb("POST")
  HttpService:SetHeader("Content-Type", "application/json")
  local jsonContent = JsonUtils.EncodeTable({
    msgtype = "text",
    text = {content = dataContent}
  })
  HttpService:SetContentAsString(jsonContent)
  HttpService:Request({
    HttpService,
    function(Service, Status)
      local success = Status == UE4.EHttpServiceStatus.RspSuccess
      local response = Service:GetRspContent()
      if success then
        Log.DebugFormat("[ReportDeviceCode] \228\184\138\230\138\165\230\136\144\229\138\159: %s", response)
      else
        Log.WarningFormat("[ReportDeviceCode] \228\184\138\230\138\165\229\164\177\232\180\165, Status: %d", Status)
      end
      if callback then
        callback(success, response or "")
      end
      AppMain.ReportDeviceCodeServiceRef = nil
    end
  })
end

function AppMain:GetPlatId()
  if not this.PlatId then
    if RocoEnv.PLATFORM_IOS then
      this.PlatId = ProtoEnum.PlatType.PT_IOS
    elseif RocoEnv.PLATFORM_ANDROID then
      this.PlatId = ProtoEnum.PlatType.PT_ANDROID
    elseif RocoEnv.PLATFORM_OPENHARMONY then
      this.PlatId = ProtoEnum.PlatType.PT_HARMONY_OS
    elseif RocoEnv.PLATFORM_WINDOWS then
      if RocoEnv.IS_EDITOR then
        this.PlatId = ProtoEnum.PlatType.PT_EDITOR
      else
        this.PlatId = ProtoEnum.PlatType.PT_PC
      end
    end
  end
  return this.PlatId
end

function AppMain:GetCAID()
  if not this.CAID then
    local TDMInfo = UE.UTDMStatics.PullDeviceInfo()
    if RocoEnv.PLATFORM_IOS then
      this.CAID = TDMInfo.CAID
    end
  end
  return this.CAID
end

function AppMain:GetOAID()
  if not this.OAID then
    local TDMInfo = UE.UTDMStatics.PullDeviceInfo()
    if RocoEnv.PLATFORM_ANDROID then
      this.OAID = TDMInfo.OAID
    end
    if RocoEnv.PLATFORM_OPENHARMONY then
      this.OAID = UE.UNRCDeviceInfoHelper.GetOAID()
    end
  end
  return this.OAID
end

function AppMain:GetAppleASA()
  if not this.AppleASA then
    local TDMInfo = UE.UTDMStatics.PullDeviceInfo()
    if RocoEnv.PLATFORM_IOS then
      Log.Dump(TDMInfo, 4, "AppMain:GetAppleASA: TDMInfo ")
      this.AppleASA = TDMInfo.AppleASA or nil
    end
  end
  return this.AppleASA
end

function AppMain:HasLaunchParams()
  return table.len(this.launchParams) > 0
end

function AppMain:SetIfDownloadBasePaksWithoutLogin(value)
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance:SetIsDownloadBasePaksWithoutLogin(value)
  else
    Log.Error("AppMain:SetIfDownloadBasePaksWithoutLogin: GameInstance is nil")
  end
end

function AppMain:GetIfDownloadBasePaksWithoutLogin()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    return GameInstance:IsDownloadBasePaksWithoutLogin()
  else
    Log.Error("AppMain:SetIfDownloadBasePaksWithoutLogin: GameInstance is nil")
  end
  return false
end

function AppMain.Shutdown(bFullPurge)
  if _G and _G.NRCSDKManager then
    _G.NRCSDKManager:CloseCrashSight()
    if bFullPurge and not this.isPIEEnded then
      Log.Error("AppMain.Shutdown")
      _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.Shutdown)
    end
  end
  UE4.UNRCStatics.SetOnLyShowLogicSkill(false)
  _G.UE4Helper.SetEnableWorldRendering(true)
  if _G.LoadingProfiler then
    _G.LoadingProfiler:Stop()
  end
end

function AppMain.OnApplicationWillEnterBackground()
  Log.Debug("AppMain.OnApplicationWillEnterBackground")
  AppMain.isEnterBackground = true
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnApplicationWillEnterBackground)
end

function AppMain.OnApplicationHasEnteredForeground()
  Log.Debug("AppMain.OnApplicationHasEnteredForeground")
  AppMain.isEnterBackground = false
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnApplicationHasEnteredForeground)
end

function AppMain.OnApplicationWillDeactivate()
  Log.Debug("AppMain.OnApplicationWillDeactivate")
  AppMain.isAppDeactivate = true
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnApplicationWillDeactivate)
end

function AppMain.OnApplicationHasReactivated()
  Log.Debug("AppMain.OnApplicationHasReactivated")
  AppMain.isAppDeactivate = false
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnApplicationHasReactivated)
end

function AppMain.OnApplicationWillTerminate()
end

function AppMain.SetEnableScreenSaver(bEnable)
  if this.enableScreenSaver ~= bEnable then
    Log.Debug("[SetEnableScreenSaver] SetEnableScreenSaver", bEnable)
    this.enableScreenSaver = bEnable
    UE4.UNRCStatics.AllowScreenSaver(bEnable)
  end
end

function AppMain:SetAuditVersion(InIsAuditVersion)
  Log.Debug("AppMain.SetAuditVersion(InIsAuditVersion)  :  ", InIsAuditVersion)
  this.isAuditVersion = InIsAuditVersion
end

function AppMain:SetUserDefineStr(InUserDefineStr)
  Log.Debug("AppMain.SetUserDefineStr(InUserDefineStr)  :  ", InUserDefineStr)
  this.userDefineStr = InUserDefineStr
end

function AppMain:IsAuditVersion()
  return this.isAuditVersion
end

function AppMain:GetUserDefineStr()
  return this.userDefineStr
end

function AppMain.OnWindowActivationChanged(Activate)
  _G.do_wait_until(function()
    return not UE4.NRCLuaUtils.IsRoutingPostLoad()
  end, function()
    return _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.WINDOW_ACTIVATION_CHANGED, Activate)
  end)
end

function AppMain.OnVirtualKeyboardShowOrHide(Show)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnVirtualKeyboardShowOrHide, Show)
end

function AppMain.PreLoadMap(MapName)
  Log.Debug("AppMain.PreLoadMap", MapName)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.PreLoadMap, MapName)
end

function AppMain.PostLoadMapWithWorld(World)
  Log.Debug("AppMain.PostLoadMapWithWorld", World and World:GetName() or "nil")
  UE4.UNRCStatics.BlockTillLevelStreamingCompleted(UE4Helper.GetCurrentWorld())
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.PostLoadMapWithWorld, World)
end

function AppMain.OnLevelAddedToWorld(level, world)
  local LevelPackageName = UE4.UNRCStatics.GetLevelPackageName(level)
  Log.Debug("AppMain.OnLevelAddedToWorld", LevelPackageName)
  if string.find(LevelPackageName, "Cave") then
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnCaveAddedToWorld, level, world)
  end
end

function AppMain.OnLevelRemoveFromWorld(level, world)
  local LevelPackageName = UE4.UNRCStatics.GetLevelPackageName(level)
  Log.Debug("AppMain.OnLevelRemoveFromWorld", LevelPackageName)
  if string.find(LevelPackageName, "Cave") then
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnCaveRemoveFromWorld, level, world)
  end
end

function AppMain.HandleScreenClick(location)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnScreenClick, location)
end

function AppMain.OnRocoTouchStart(touchIndex, location)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnRocoTouchStart, touchIndex, location)
end

function AppMain.OnRocoTouchMove(touchIndex, location)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnRocoTouchMove, touchIndex, location)
end

function AppMain.OnRocoTouchEnd(touchIndex, inputLimitFlag)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnRocoTouchEnd, touchIndex, inputLimitFlag)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    this.desireReleaseCursorCapture = true
    UE4.UNRCTUIStatics.EnableThisFrameFinishedInputEvent()
  end
end

function AppMain.OnRocoFinishedInputThisFrame()
  if this.desireReleaseCursorCapture then
    this.desireReleaseCursorCapture = false
    if UE4.UNRCEnhancedInputHelper.ShouldShowCursor() then
      UE4.UNRCTUIStatics.ReleaseCursorCapture(0)
    end
  end
end

function AppMain.OnPrePIEEnded(isSimulating)
  Log.Debug("AppMain.OnPrePIEEnded")
  this.isPIEEnded = true
  UE4.UNRCStatics.SetEnableRocoPreInputProcessor(false)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPrePIEEnded, isSimulating)
end

function AppMain.OnActiveEditor()
  HotFix.AutoHotFixFile()
end

function AppMain.OnThundering()
  _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.OnThundering)
end

function AppMain.OnBeginShaderPrecompile(Count)
  Log.Debug("AppMain.OnBeginShaderPrecompile", Count)
  this.TotalShaderPrecompiles = Count
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnShaderBeginPrecompile, Count)
end

function AppMain.OnEndShaderPrecompile(Count, Time)
  Log.Debug("AppMain.OnEndShaderPrecompile", Count, Time)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnShaderEndPrecompile, Count, Time)
end

function AppMain.OnTravelFailure(World, TravelType, TravelResult)
  Log.Error("AppMain.OnTravelFailure", TravelType, TravelResult)
  if _G.TipsModuleCmd.Dialog_OpenDialog then
    local Context = _G.DialogContext()
    Context:SetTitle(LuaText.failed_to_open_map_title)
    Context:SetContent(LuaText.failed_to_open_map_content)
    Context:SetMode(_G.DialogContext.Mode.OK)
    Context:SetClickAnywhereClose(true)
    Context:SetCallbackOkOnly(nil, function()
      AppMain.BackToLogin(true)
    end)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    AppMain.BackToLogin(true)
  end
end

function AppMain.OnDisplayMetricsChanged()
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnDisplayMetricsChanged)
end

local function SplitVersion(Version)
  local Spat = string.Split(Version, ".")
  if not Spat then
    return 0, 0, 0, 0
  end
  return tonumber(Spat[1] or "0"), tonumber(Spat[2] or "0"), tonumber(Spat[3] or "0"), tonumber(Spat[4] or "0")
end

function AppMain.LoadVersionInfo()
  local File = string.format("%sNewRoco/DataConfig/appinfo.json", UE4.UBlueprintPathsLibrary.ProjectContentDir())
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if not Success then
    Result = {}
  end
  local AppInfo = rapidjson.decode(Result)
  this.AppVersion = UE.UNRCStatics.GetProjectVersion() or "1.0.0.1"
  this.AppRevision = AppInfo.app_revision or 0
  this.ResVersion = AppInfo.res_version or "1.0.1.1"
  this.ResRevision = AppInfo.res_revision or 0
  this.DolphinChannel = AppInfo.update_channel or 4491
  this.PufferChannel = AppInfo.puffer_update_channel or 4491
  this.FormalPipeline = AppInfo.formal_pipeline
  this.BuildStartTime = AppInfo.build_start_time
  this.BanOpenUAV = AppInfo.ban_open_uav
  this.ShowTopMark = AppInfo.show_top_mark
  this.ProjectBranch = AppInfo.project_branch
  this.EngineBranch = AppInfo.engine_branch
  if this.FormalPipeline == nil then
    this.FormalPipeline = true
  end
  Log.DumpSingleLine(RocoEnv, 2, "RocoEnv:Json", true)
  Log.DumpSingleLine(AppMain, 4, "AppMain:Json", true)
end

function AppMain.DecodeLaunchParams()
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local Map
  if Instance and Instance.LaunchParams then
    Log.Debug("[AppMain.DecodeLaunchParams] Get LaunchParam from Instance.LaunchParams")
    Map = Instance.LaunchParams
  elseif not _G.RocoEnv.IS_SHIPPING or _G.RocoEnv.PLATFORM_WINDOWS then
    Log.Debug("[AppMain.DecodeLaunchParams] Get LaunchParam from Clipboard")
    Map = UE.UNRCStatics.DecodeClipboardParams()
  end
  local Table = Map:ToTable()
  this.launchParams = Table
  local TimeBucket = tonumber(this.launchParams.t or 0) or 0
  if TimeBucket then
    Log.Dump(this.launchParams, 3, "Show Launch Params Raw!!!")
    local UnixTimeStampInMS = UE.UNRCStatics.GetUTCTimestampMS()
    local UnixTimeStampInS = math.floor(UnixTimeStampInMS / 1000)
    local Bucket = math.floor(UnixTimeStampInS / 7200)
    if Bucket == TimeBucket then
      this.launchParams.t = nil
    else
      this.launchParams = {}
    end
  else
    this.launchParams = {}
  end
  Log.Dump(this.launchParams, 3, "Show Launch Params")
  if Table.lua_debugger == "true" then
    UE.UNRCStatics.EnableLuaDebugger(5067)
  end
  if RocoEnv.IS_EDITOR then
    return
  end
  if not string.IsNilOrEmpty(Table.cosId) then
    this.DownloadCosFile(Table.cosId)
    return
  end
  if string.IsNilOrEmpty(Table.lua) then
    return
  end
  Log.Debug("override lua", Table.lua)
  UE.UNRCStatics.UnzipLuaZipFile(Table.lua)
end

function AppMain.IfMountPaksInAdvance()
  if not RocoEnv.PLATFORM_WINDOWS and not this.GetFormalPipeline() and this.launchParams and this.launchParams.mount_pak and this.launchParams.mount_pak == "true" then
    return true
  end
  return false
end

function AppMain.DownloadCosFile(CosId)
  local DecodedCosId = UE.UMoreFunPlatformKits.UrlDecode(CosId)
  local FullUrl = DecodedCosId
  if string.StartsWith(DecodedCosId, "https://") then
    FullUrl = DecodedCosId
  else
    FullUrl = string.format("https://nrc-server-log-1258344700.cos.ap-nanjing.myqcloud.com%s", DecodedCosId)
  end
  local FileName = FullUrl:match(".*/([^/?]+)")
  local SaveFilePath = string.format("%s%s", UE.UBlueprintPathsLibrary.ProjectSavedDir(), FileName)
  if UE.UNRCStatics.FileExists(SaveFilePath) then
    Log.Debug("[AppMain] file exists already, skip download", SaveFilePath)
    return
  end
  Log.Debug("[AppMain] Start Download File", CosId, FileName, SaveFilePath)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  AppMain.ServiceRef = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetUrl(FullUrl)
  HttpService:SetVerb("GET")
  HttpService:Request({
    HttpService,
    function(Service, Status)
      if Status == UE4.EHttpServiceStatus.RspSuccess then
        Service:SaveToFile(SaveFilePath)
        Log.Debug("[AppMain] DownloadFile Success", SaveFilePath)
        UE.UNRCStatics.UnzipLuaZipFile(FileName)
        Log.Debug("[AppMain] Unzip Success", FileName)
      else
        Log.Debug("[AppMain] DownloadFile Failed", SaveFilePath)
      end
      AppMain.ServiceRef = nil
    end
  })
end

function AppMain.EnableDebugLog()
  Log.Debug("EnableDebug")
  Log.SetLogLevel(Log.LOG_LEVEL.ELogTrace)
  UE4.UNRCStatics.SetLogLevel(8)
  Log.Debug("EnableDebug 1")
end

function AppMain.GetLocalVersion()
  local LocalResInfo = JsonUtils.LoadSaved("DolphinVersion", {})
  local LocalResVersion = LocalResInfo and LocalResInfo.ResVersion
  return LocalResVersion
end

function AppMain.GetAssetType()
  local LocalResInfo = JsonUtils.LoadSaved("DolphinVersion", {})
  local AssetType = LocalResInfo and LocalResInfo.AssetType
  return AssetType
end

function AppMain.InitVersion()
  this.LoadVersionInfo()
  if RocoEnv.IS_EDITOR then
    return
  end
  local LocalResVersion = this.GetLocalVersion()
  if string.IsNilOrEmpty(LocalResVersion) then
    return
  end
  this:SetResVersion(LocalResVersion)
end

function AppMain.ClearUpdatedRes()
  local ShaderFolder = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "Puffer/Metal"
  })
  local PakFolder = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "Puffer/Paks"
  })
  local MovieFolder = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "Puffer/Movies"
  })
  local APKDownloadFolder = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "UE4Game",
    "NRC",
    "NRC",
    "Saved",
    "Dolphin"
  })
  if UE.UNRCStatics.RemoveFolder(APKDownloadFolder) then
    Log.Debug("\231\167\187\233\153\164APKDownloadFolder\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164APKDownloadFolder\229\164\177\232\180\165")
  end
  if UE.UNRCStatics.RemoveFolder(ShaderFolder) then
    Log.Debug("\231\167\187\233\153\164Shader\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164Shader\229\164\177\232\180\165")
  end
  if UE.UNRCStatics.RemoveFolder(PakFolder) then
    Log.Debug("\231\167\187\233\153\164Paks\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164Paks\229\164\177\232\180\165")
  end
  if UE.UNRCStatics.RemoveFolder(MovieFolder) then
    Log.Debug("\231\167\187\233\153\164Movies\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164Movies\229\164\177\232\180\165")
  end
  local FileListFile = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "filelist.json"
  })
  if UE.UNRCStatics.DeleteToFile(FileListFile) then
    Log.Debug("\231\167\187\233\153\164filelist.json\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164filelist.json\229\164\177\232\180\165")
  end
  local Apollo = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "apollo_reslist.flist"
  })
  if UE.UNRCStatics.DeleteToFile(Apollo) then
    Log.Debug("\231\167\187\233\153\164apollo_reslist.flist\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164apollo_reslist.flist\229\164\177\232\180\165")
  end
  local LocalVersionFile = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "DolphinVersion.json"
  })
  if UE.UNRCStatics.DeleteToFile(LocalVersionFile) then
    Log.Debug("\231\167\187\233\153\164DolphinVersion.json\230\136\144\229\138\159")
  else
    Log.Debug("\231\167\187\233\153\164DolphinVersion.json\229\164\177\232\180\165")
  end
end

function AppMain.RepairCleanup()
  AppMain.ClearUpdatedRes()
  local SavedFolder = UE.UBlueprintPathsLibrary.ProjectSavedDir()
  local Files = UE.UNRCStatics.ListFiles(SavedFolder, "*.*")
  if Files then
    for _, File in tpairs(Files) do
      UE.UNRCStatics.DeleteToFile(File)
    end
    if not UE.UNRCStatics.RemoveFolder(SavedFolder) then
      Log.Error("Failed to remove saved")
    end
  end
end

function AppMain.TryReload()
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local HasMounted = Instance.bPakMounted
  if HasMounted then
    Log.Debug("resources has been mounted, no need to re-mount")
    return
  end
  Log.Debug("try re-mount paks")
  Instance.bPakMounted = true
end

function AppMain.DisableWritePSO()
  local ShouldEnablePSO = UE.UNRCStatics.ReadSavePSOLogFlag()
  if ShouldEnablePSO then
    UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.LogPSO 0")
  end
end

function AppMain.ReapplyWritePSO()
  local ShouldEnablePSO = UE.UNRCStatics.ReadSavePSOLogFlag()
  if ShouldEnablePSO then
    UE.UNRCStatics.ExecConsoleCommand("r.ShaderPipelineCache.LogPSO 1")
  end
end

function AppMain.ReloadPipelineCache()
  local Result = UE.UNRCStatics.ReloadShaderPipelineCache()
  Log.Debug("Reload Pipeline Cache", Result and "Success" or "Failed")
end

function AppMain.UnmountPaks()
  local Array = UE.UNRCStatics.GetMountedPakFileNames()
  local Paks = Array:ToTable()
  for Index, Path in ipairs(Paks) do
    local Result = UE.UNRCStatics.Unmount(Path)
    Log.Debug("Unmount", Path, Result and "Success" or "Failed")
  end
end

function AppMain.IsFullPackage()
  local PakFolder = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectContentDir(),
    "Paks"
  })
  local PakFiles = UE.UNRCStatics.ListFiles(PakFolder, "*.pak")
  local Table = PakFiles:ToTable()
  for Index, Path in ipairs(Table) do
    local Name = UE.UBlueprintPathsLibrary.GetBaseFilename(Path, true)
    if string.StartsWith(Name, "pakchunk9000-") or string.StartsWith(Name, "pakchunk25-") then
      Log.Debug("Content\228\184\173\229\140\133\229\144\171\230\156\1379000 or 25\231\154\132\229\140\133\239\188\140\232\174\164\228\184\186\230\152\175\230\149\180\229\140\133\239\188\140\232\183\179\232\191\135\229\138\160\232\189\189\230\149\176\230\141\174")
      return true
    end
  end
  return false
end

function AppMain.IsLocalSavedHasBasePaks()
  if not this.GetFormalPipeline() then
    local PakFolder = UE.UBlueprintPathsLibrary.Combine({
      UE.UBlueprintPathsLibrary.ProjectSavedDir(),
      "Paks"
    })
    local PakFiles = UE.UNRCStatics.ListFiles(PakFolder, "*.pak")
    local Table = PakFiles:ToTable()
    for Index, Path in ipairs(Table) do
      local Name = UE.UBlueprintPathsLibrary.GetBaseFilename(Path, true)
      if string.StartsWith(Name, "pakchunk9000-") or string.StartsWith(Name, "pakchunk25-") then
        Log.Debug("Saved\228\184\173\229\140\133\229\144\171\230\156\1379000 or 25\231\154\132\229\140\133\239\188\140\232\174\164\228\184\186\230\152\175\232\135\170\232\161\140\229\164\141\229\136\182\231\154\132\232\181\132\230\186\144\239\188\140\232\183\179\232\191\135\229\138\160\232\189\189\230\149\176\230\141\174")
        return true
      end
    end
  end
  return false
end

function AppMain.IsMobilePlatform()
  return RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY
end

function AppMain:GetIsEnterBackground()
  return this.isEnterBackground
end

function AppMain:GetIsAppDeactivate()
  return AppMain.isAppDeactivate
end

Log.Debug("Run AppMain")
return AppMain

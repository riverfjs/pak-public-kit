print("NRC Init------------NRCLuaEntrance-------------")
print("requireC:", requireC)

local function EnableLuaState()
  require("UnLuaEx")
  require("Utils.StringExtend")
  require("Utils.Extend")
  require("Common.Utils")
  require("Common.UE4Helper")
  require("Common.LevelHelper")
  _G.Array = require("Utils.Array")
  _G.Queue = require("Utils.Queue")
  _G.Log = require("Libs.Log.Log")
end

local function FixRequirePath()
  if not RocoEnv.IS_LUAC then
    return
  end
  local requireOri = require
  
  function require(path)
    local filename = string.gsub(path, ".lua", ".luac")
    if RocoEnv.IS_EDITOR then
      filename = string.gsub(filename, "Script", "ScriptC")
    end
    return requireOri(filename)
  end
end

local function HookRequire()
  _G.HotFix = require("Utils.NRCHotFixBeta1")
  require = HotFix.RequireFile
  loadfile = UELoadLuaFile
  if _G.USE_LUA_RELOAD then
    function _G.reload(filename)
      if not HotFix.IsMouduleInPackage(filename) then
        return require(filename)
      end
      return HotFix.ReloadFile(filename)
    end
  else
    _G.reload = HotFix.RequireFile
  end
  
  function _G.unload(filename)
    for key, _ in pairs(package.preload) do
      if 1 == string.find(tostring(key), filename) then
        package.preload[key] = nil
      end
    end
    for key, _ in pairs(package.loaded) do
      if 1 == string.find(tostring(key), filename) then
        package.loaded[key] = nil
      end
    end
  end
end

local function InitEnv()
  HookRequire()
  EnableLuaState()
  _G.globalRef = {}
  _G.UEPath = require("UEPath")
  _G.UIIconPath = require("UIIconPath")
  _G.SingletonMgr = require("Common.Singleton.SingletonMgr").Setup()
  _G.CreateSingleton = _G.SingletonMgr.CreateSingleton
  _G.Singleton = require("Common.Singleton.Singleton")
  _G.NRCUtils = require("Core.NRCUtils")
  _G.ProtoEnum = require("Data.PB.ProtoEnum")
  _G.Enum = require("Data.Config.Enum")
  _G.ProtoCMD = require("Data.PB.ProtoCMD")
  _G.ProtoMessage = require("Data.PB.ProtoMessage")
  _G.ProtoMgr = require("Data.PB.ProtoMgr")
  _G.ProtoMgr:Init()
  _G.BinDataUtils = require("Common.BinDataUtils")
  local AppMain = require("NewRoco.Modules.Core.App.AppMain")
  _G.App = AppMain.Setup()
  _G.AppMain = _G.App
  AppMain.SetEnableScreenSaver(false)
  _G.NRCEnv = _G.CreateSingleton("NRCEnv", "Common.NRCEnv")
  _G.CppLuaLibrary = require("NRCCppLuaLibrary")
  _G.FVectorZero = UE4.FVector(0, 0, 0)
  _G.FVectorOne = UE4.FVector(1, 1, 1)
  _G.FVectorUp = UE4.FVector(0, 0, 1)
  _G.FVectorDown = UE4.FVector(0, 0, -1)
  LockFVector(_G.FVectorZero)
  LockFVector(_G.FVectorOne)
  LockFVector(_G.FVectorUp)
  LockFVector(_G.FVectorDown)
  _G.FRotatorZero = UE4.FRotator(0, 0, 0)
  _G.CycleCounter = _G.CreateSingleton("CycleCounter", "Common.CycleCounter")
end

local function InitMode()
  local NRCLoginMode = require("NewRoco.Modes.LoginMode.NRCLoginMode")
  NRCModeManager:RegisterMode("LoginMode", NRCLoginMode)
  local NRCCreatePlayerMode = require("NewRoco.Modes.CreatePlayerMode.NRCCreatePlayerMode")
  NRCModeManager:RegisterMode("CreatePlayerMode", NRCCreatePlayerMode)
  local NRCBigWorldMode = require("NewRoco.Modes.BigWorldMode.NRCBigWorldMode")
  NRCModeManager:RegisterMode("BigWorldMode", NRCBigWorldMode)
  local NRCLocalMode = require("NewRoco.Modes.LocalMode.NRCLocalMode")
  NRCModeManager:RegisterMode("LocalMode", NRCLocalMode)
  local NRCUpdateMode = require("NewRoco.Modes.UpdateMode.NRCUpdateMode")
  NRCModeManager:RegisterMode("UpdateMode", NRCUpdateMode)
  local NRCBattleTestMapMode = require("NewRoco.Modes.BattleCraneTestMode.NRCBattleTestMapMode")
  NRCModeManager:RegisterMode("BattleTestMapMode", NRCBattleTestMapMode)
end

local function InitGC()
  local config = _G.GlobalConfig
  if config.GCAlgorithm == "incremental" then
    collectgarbage("incremental", config.GCIncPause, config.GCIncStepMultiplier, config.GCIncStep)
    Log.DebugFormat("Use incremental GC with [Pause:%d], [StepMultiplier:%d], [Step:%d]", config.GCIncPause, config.GCIncStepMultiplier, config.GCIncStep)
  elseif config.GCAlgorithm == "generational" then
    collectgarbage("generational", config.GCGenMinorMultiplier, config.GCGenMajorMultiplier)
    Log.DebugFormat("Use generational GC with [MinorMultiplier:%d], [MajorMultiplier:%d]", config.GCGenMinorMultiplier, config.GCGenMajorMultiplier)
  else
    Log.Error("Unknown GCAlgorithm:" .. config.GCAlgorithm)
  end
end

local function InitManager()
  _G.TimerManager = _G.CreateSingleton("TimerManager", "Common.TimerManager")
  if RocoEnv.IS_EDITOR and _G.NRCEditorEntranceEnable then
    _G.PriorityEnum = require("PriorityEnum")
    _G.DataConfigManager = _G.CreateSingleton("DataConfigManager", "Common.DataConfigManagerNew")
    reload("Common.DataConfigManagerEx")
    _G.BattleEventCenter = _G.CreateSingleton("BattleEventCenter", "NewRoco.Modules.Core.Battle.BattleCore.BattleEventCenter")
    _G.RocoSkillEventCenter = _G.CreateSingleton("BattleSkillManager", "NewRoco.Modules.Core.Battle.BattleCore.Skill.RocoSkillEventCenter")
    _G.BattleActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleActionBase")
    _G.LuaText = require("LuaText")
    _G.BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
    _G.BattleProfiler = _G.CreateSingleton("BattleProfiler", "NewRoco.Modules.Core.Battle.BattleCore.Utils.BattleProfiler")
    _G.BattleManager = require("NewRoco.Modules.Core.Battle.BattleManager")()
    _G.BattleSkillManager = _G.CreateSingleton("BattleSkillManager", "NewRoco.Modules.Core.Battle.BattleCore.Skill.BattleSkillManager")
    _G.NRCResourceManager = _G.CreateSingleton("AssetManager", "Core.Service.ResourceManager.NRCResourceManager")
    Log.Debug("InitManager")
    return
  end
  _G.PriorityEnum = require("PriorityEnum")
  _G.DataConfigManager = _G.CreateSingleton("DataConfigManager", "Common.DataConfigManagerNew")
  reload("Common.DataConfigManagerEx")
  _G.UserSettingManager = _G.CreateSingleton("UserSettingManager", "Common.UserSettingManager")
  _G.NRCResourceManager = _G.CreateSingleton("AssetManager", "Core.Service.ResourceManager.NRCResourceManager")
  _G.NRCAudioManager = _G.CreateSingleton("AssetManager", "Core.Service.Audio.NRCAudioManager")
  _G.NRCNetworkManager = _G.CreateSingleton("NRCNetworkManager", "Core.Service.NetManager.NRCNetworkManager")
  _G.ZoneServer = _G.CreateSingleton("ZoneServer", "Core.Service.NetManager.ZoneServer")
  _G.NRCSDKManager = _G.CreateSingleton("NRCSDKManager", "Core.Service.SDKManager.NRCSDKManager")
  _G.GVoiceManager = _G.CreateSingleton("GVoiceManager", "Core.Service.SDKManager.GVoiceManager")
  _G.PufferUpdateResTask = _G.CreateSingleton("PufferUpdateResTask", "Core.Service.GCloud.Tasks.PufferUpdateResTask")
  _G.NRCAutoDownloadManager = _G.CreateSingleton("NRCAutoDownloadManager", "NewRoco.Modules.System.Download.NRCAutoDownloadManager")
  _G.NRCBackgroundDownloadMgr = _G.CreateSingleton("NRCBackgroundManager", "NewRoco.Modules.System.BackgroundDownload.NRCBackgroundDownloadMgr")
  _G.FsmManager = _G.CreateSingleton("FsmManager", "NewRoco.Modules.Core.Fsm.FsmManager")
  _G.DataModelMgr = _G.CreateSingleton("DataModelMgr", "Data.Global.DataModelMgr")
  _G.LuaText = require("LuaText")
  _G.LuaText:Init()
  _G.DataModelMgr:Init()
  _G.NRCPreDownloadManager = _G.CreateSingleton("NRCPreDownloadManager", "NewRoco.Modules.System.Download.PreDownload.NRCPreDownloadManager")
  _G.BattleProfiler = _G.CreateSingleton("BattleProfiler", "NewRoco.Modules.Core.Battle.BattleCore.Utils.BattleProfiler")
  _G.LoadingProfiler = _G.CreateSingleton("LoadingProfiler", "NewRoco.Utils.LoadingProfiler")
  _G.BattleActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleActionBase")
  _G.BattlePiecesManager = require("NewRoco.Modules.Core.Battle.BattleCore.Pieces.BattlePiecesManager")
  _G.BattleEventCenter = _G.CreateSingleton("BattleEventCenter", "NewRoco.Modules.Core.Battle.BattleCore.BattleEventCenter")
  _G.BattleSkillManager = _G.CreateSingleton("BattleSkillManager", "NewRoco.Modules.Core.Battle.BattleCore.Skill.BattleSkillManager")
  _G.RocoSkillEventCenter = _G.CreateSingleton("BattleSkillManager", "NewRoco.Modules.Core.Battle.BattleCore.Skill.RocoSkillEventCenter")
  _G.BattleResourceManager = _G.CreateSingleton("BattleResourceManager", "NewRoco.Modules.Core.Battle.BattleCore.BattleResourceManager")
  _G.ProtoRecorder = require("Core.Service.NetManager.ProtocolRecorder")(false)
  _G.SkillPerformAutoBattleUtils = require("Common.LocalServer.SkillPerformAutoBattleUtils")
  _G.BattleCraneCameraHost = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraHost")
  _G.SkillUtils = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.SkillUtils")
  _G.BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
  _G.BattleDataCenter = _G.CreateSingleton("BattleDataCenter", "NewRoco.Modules.Core.Battle.BattleCore.BattleDataCenter")
  _G.BattlePlayerPool = _G.CreateSingleton("BattlePlayerPool", "NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerPool")
  _G.BattleNetManager = _G.CreateSingleton("BattleNetManager", "NewRoco.Modules.Core.Battle.BattleNetManager")
  _G.BattleReplayServer = _G.CreateSingleton("BattleReplayServer", "NewRoco.Modules.Core.Battle.BattleCore.Replay.BattleReplayServer")
  _G.BattleReplayManager = _G.CreateSingleton("BattleReplayManager", "NewRoco.Modules.Core.Battle.BattleCore.Replay.BattleReplayManager")
  _G.BattleReplayCachePool = _G.CreateSingleton("BattleReplayCachePool", "NewRoco.Modules.Core.Battle.BattleCore.Replay.BattleReplayCachePool")
  _G.BattleAutoTest = _G.CreateSingleton("BattleAutoTest", "NewRoco.Modules.Core.Battle.BattleCore.AutoTest.BattleAutoTest")
  _G.BattleLogger = _G.CreateSingleton("BattleLogger", "NewRoco.Modules.Core.Battle.BattleCore.Utils.BattleLogger")
  _G.BattleBulletTimeManager = _G.CreateSingleton("BattleBulletTimeManager", "NewRoco.Modules.Core.Battle.BattleBulletTimeManager")
  _G.BattleCoreEnv = require("NewRoco.Modules.Core.Battle.BattleCore.Datas.BattleCoreEnv")()
  _G.BattlePerformNodePool = _G.CreateSingleton("BattlePerformNodePool", "NewRoco.Modules.Core.Battle.BattleCore.BattlePerformNodePool")
  _G.BattleBudget = _G.CreateSingleton("BattleBudget", "NewRoco.Modules.Core.Battle.BattleCore.Utils.BattleBudget")
  _G.BattleBudget:Init()
  _G.BattleManager = require("NewRoco.Modules.Core.Battle.BattleManager")()
  _G.BattleManager:Init()
  _G.BattleLevelHelper = require("NewRoco.Modules.Core.Battle.Common.BattleLevelHelper")()
  _G.BattleLevelHelper:Init()
  _G.BattleLog = require("NewRoco.Modules.Core.Battle.Common.BattleLog")()
  _G.BattleLog:Init()
  _G.NRCPanelBlocker = _G.CreateSingleton("NRCPanelBlocker", "Core.NRCModule.Optimize.NRCPanelBlocker")
  _G.BattleAIManager = _G.CreateSingleton("BattleAIManager", "NewRoco.Modules.Core.Battle.AI.BattleAIManager")
  _G.FunctionBanManager = _G.CreateSingleton("FunctionBanManager", "Common.FunctionBanManager")
  _G.GEMPostManager = _G.CreateSingleton("GEMPostManager", "Common.GEMPostManager")
  _G.PlayerResourceManager = _G.CreateSingleton("PlayerResourceManager", "NewRoco.Modules.Core.PlayerModule.PlayerResourceManager")
  _G.SignificanceTagManager = _G.CreateSingleton("SignificanceTagManager", "Common.SignificanceTagManager")
  _G.BattlePerformDebug = _G.CreateSingleton("BattlePerformDebug", "NewRoco.Modules.Core.Battle.BattleCore.BattlePerformDebug")
  _G.NRCSDKManager:SetUserValue("ResVersion", _G.AppMain:GetResVersion())
  local Preloader = require("NewRoco.Modes.BigWorldMode.Actions.NRCBigWorldPreloader")
  _G.NRCBigWorldPreloader = Preloader()
  if RocoEnv.IS_EDITOR and UE4.UMockUtils.IsMockEnabled() then
    _G.MockManager = _G.CreateSingleton("MockManager", "Mock.MockManager")
  end
  local AreaQueryManager = UE4.UAreaQueryManager.Get(_G.UE4Helper.GetCurrentWorld())
  if AreaQueryManager then
    AreaQueryManager:InitializeAreaData()
  end
end

local function RegisterLooper()
  _G.NRCLooper = require("Common.NRCLooper")
  _G.UpdateManager = require("Common.UpdateManager")
end

function NRCMain()
  Log.Debug("NRCLuaEntrance NRCMain 1")
  _G.GlobalConfig = require("GlobalConfig")
  if _G.GlobalConfig.EnableLuaPandaDebugger and RocoEnv.IS_EDITOR then
    local ok, LuaPanda = pcall(require, "Libs.Debugger.LuaPanda.LuaPanda")
    if ok and LuaPanda then
      LuaPanda.start("127.0.0.1", 50515)
    end
  end
  local LoginConfig = require("NewRoco.Modes.LoginMode.LoginConfig")
  local config = LoginConfig.GetRecord("LoginConf.non")
  if config.OpenMemoryAutoTest == "1" then
    _G.GlobalConfig.MemoryAutoTest = true
  end
  UE4.UNRCStatics.EditorRevertPCConfig()
  if _G.GlobalConfig.MemoryAutoTest then
    if config.LocationX and config.LocationY and config.LocationZ and config.LocationX ~= "None" and config.LocationY ~= "None" and config.LocationZ ~= "None" then
      local BornLocationXCommand = "NRCCustomPlayerStartX " .. config.LocationX
      local BornLocationYCommand = "NRCCustomPlayerStartY " .. config.LocationY
      local BornLocationZCommand = "NRCCustomPlayerStartZ " .. config.LocationZ
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, BornLocationXCommand)
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, BornLocationYCommand)
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, BornLocationZCommand)
    end
    if "1" == config.EngineTestMode then
      _G.GlobalConfig.EngineTestMode = true
    else
      _G.GlobalConfig.EngineTestMode = false
    end
    if "1" == config.DisableGameplayMode then
      _G.GlobalConfig.DisableGameplayMode = true
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "SMC.FreezeSocketLogs 1")
    else
      _G.GlobalConfig.DisableGameplayMode = false
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "SMC.FreezeSocketLogs 0")
    end
    if "1" == config.FreezeAllLevels then
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeAllLevels 1")
    else
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeAllLevels 0")
    end
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeLevelName None")
    if "None" ~= config.FreezeLevelName then
      local FreezeLevelCommand = "WorldTileTool.FreezeLevelName " .. config.FreezeLevelName
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, FreezeLevelCommand)
    end
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeLayers None")
    if "None" ~= config.FreezeLayers then
      local FreezeLayerCommand = "WorldTileTool.FreezeLayers " .. config.FreezeLayers
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, FreezeLayerCommand)
    end
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.RetainLayers None")
    if "None" ~= config.RetainLayers then
      local RetainLayerCommand = "WorldTileTool.RetainLayers " .. config.RetainLayers
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, RetainLayerCommand)
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "CaveStreaming.Freeze 1")
    end
    if config.World == "NothingWorld" then
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.LoadLevelPath /Game/ArtRes/Level/Game/BigWorld/L_Bigworld_01_Release/NothingWorld")
    elseif config.World == "MagicAcademy" then
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.LoadLevelPath /Game/ArtRes/Level/Game/MagicAcademy/Release/MA_Release")
    elseif config.World == "EcosystemRoom" then
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.LoadLevelPath /Game/ArtRes/Level/Game/Indoor/B1/Indoor_B1_10/Indoor_B1_10_Release")
    elseif "None" ~= config.World then
      local Command = "WorldTileTool.LoadLevelPath " .. config.World
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, Command)
    end
    if "1" == config.FreezeTextureStreaming then
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "r.TextureStreaming 0")
    end
    if config.Quality == "Low" then
      UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Low)
    elseif config.Quality == "Medium" then
      UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Medium)
    elseif config.Quality == "High" then
      UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.High)
    elseif config.Quality == "Epic" then
      UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Epic)
    end
  end
  InitEnv()
  RegisterLooper()
  Log.Debug("NRCLuaEntrance NRCMain 2")
  _G.NRCClass = require("Core.NRCClass")
  _G.NRCUmgClass = require("Core.NRCUmgClass")
  _G.NRCModuleCmd = require("Core.NRCModule.NRCModuleCmd")
  _G.NRCModuleTypeDef = require("Core.NRCModule.NRCModuleTypeDef")
  _G.NRCData = require("Core.NRCModule.NRCData")
  _G.NRCModeBase = require("Core.NRCMode.NRCModeBase")
  _G.NRCModeManager = _G.CreateSingleton("NRCModeManager", "Core.NRCMode.NRCModeManager")
  _G.NRCPhaseBase = require("Core.NRCPhase.NRCPhaseBase")
  _G.NRCPhaseManager = _G.CreateSingleton("NRCPhaseManager", "Core.NRCPhase.NRCPhaseManager")
  _G.EventDispatcher = require("Common.EventDispatcher")
  _G.NRCEventCenter = _G.CreateSingleton("NRCEventCenter", "Common.NRCEventCenter")
  _G.NRCViewBase = require("Core.NRCModule.NRCViewBase")
  _G.NRCPanelBase = require("Core.NRCModule.NRCPanelBase")
  _G.NRCBattleView = require("NewRoco.Modules.System.BattleUI.Res.NRCBattleView")
  _G.NRCModuleBase = require("Core.NRCModule.NRCModuleBase")
  _G.NRCModuleHeadBase = require("Core.NRCModule.NRCModuleHeadBase")
  _G.NRCModuleManager = _G.CreateSingleton("NRCModuleManager", "Core.NRCModule.NRCModuleManager")
  _G.UILayerCtrlCenter = require("Core.NRCPanelLayer.UILayerCtrlCenter")
  _G.NRCGCManager = _G.CreateSingleton("NRCGCManager", "Core.NRCGCManager")
  _G.NRCPanelManager = _G.CreateSingleton("NRCPanelManager", "Core.NRCPanelManager")
  _G.NRCPanelRegisterData = require("Core.NRCModule.NRCPanelRegisterData")
  _G.SimpleDelegateFactory = nil
  _G.SimpleDelegateFactory = _G.CreateSingleton("SimpleDelegateFactory", "Common.SimpleDelegateFactory")
  _G.DelayManager = _G.CreateSingleton("DelayManager", "Common.DelayManager")
  _G.GameSetting = require("Common.GameSetting")
  _G.GameSetting:Init()
  _G.LevelHelper = require("Common.LevelHelper")
  _G.LuaParamType = require("NewRoco.AI.BehaviorTree.LuaParams.LuaParamType")
  _G.MFBTTemplate = _G.CreateSingleton("MFBTTemplate", "NewRoco.AI.BehaviorTree.MFBT.MFBTTemplate")
  _G.ColorDefine = require("NewRoco.Utils.ColorDefine")
  _G.LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
  _G.LuaBTUtils = require("NewRoco.AI.BehaviorTree.Utils.LuaBTUtils")
  _G.AIDefines = require("NewRoco.AI.AIDefines")
  _G.SceneAIUtils = require("NewRoco.AI.SceneAIUtils")
  _G.DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  _G.NRCProfilerLog = _G.CreateSingleton("NRCProfilerLog", "Common.NRCProfilerLog")
  _G.LocalText = require("NewRoco.Utils.LocalText")
  _G.NRCPanelOpenReqData = require("Core.NRCPanel.NRCPanelOpenReqData")
  _G.NRCPanelEnum = require("Core.NRCPanel.NRCPanelEnum")
  _G.NRCPanelOpenOptions = require("Core.NRCPanel.NRCPanelOpenOptions")
  _G.NRCCommonItemIconData = require("NewRoco.Modules.System.Common.NRCCommonItemIconData")
  _G.NRCCommonAddSubtractData = require("NewRoco.Modules.System.Common.NRCCommonAddSubtractData")
  _G.NRCCommonPopUpData = require("NewRoco.Modules.System.CommonPopUp.Res.NRCCommonPopUpData")
  _G.NRCCommonDropDownListData = require("NewRoco.Modules.System.CommonDropDownList.Res.NRCCommonDropDownListData")
  _G.NRCPanelResLoadData = require("Core.NRCPanel.NRCPanelResLoadData")
  _G.MultiTouchModuleCmd = require("NewRoco.Modules.Core.MultiTouch.MultiTouchModuleCmd")
  _G.MediaUtils = require("Common.MediaUtils")
  _G.CommonUtils = require("NewRoco.Utils.CommonUtils")
  _G.MemoryUtils = require("NewRoco.Utils.MemoryUtils")
  
  function _G.MakeAutoIndex()
    local index = 0
    return function()
      index = index + 1
      return index
    end
  end
  
  Log.Debug("LuaEntrance init complete")
  InitManager()
  InitMode()
  _G.LoadingProfiler:Start()
  local NRCModeEntrance = require("NRCModeEntrance")
  NRCModeEntrance():ActiveMode()
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
  end
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" and not RocoEnv.IS_EDITOR then
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.NRCDynamicSwitchForceCrash 1")
  end
  if not RocoEnv.IS_SHIPPING then
    UE4.UNRCStatics.EmptyNRCTypeActorNameMatchRule()
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(0, {
      "WorldLocalPlayer"
    }, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(1, {
      "WorldPlayer"
    }, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(2, {"BP_Ride"}, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(3, {
      "BP_Scene_NPC"
    }, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(4, {"BP_NPC"}, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(5, {
      "BP_Scene_Miaomiao"
    }, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(6, {}, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(7, {"Tree"}, {"Stree"}, true)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(8, {"Grass"}, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(9, {"Rock"}, {}, true)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(10, {"Landscape"}, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(11, {"HLOD"}, {}, false)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(12, {"Flower"}, {}, true)
    UE4.UNRCStatics.SetNRCTypeActorNameMatchRule(13, {"Bush"}, {}, true)
    local PrintNames = {
      "LocalPlayer",
      "Player",
      "BP_Ride",
      "BP_Scene_NPC",
      "BP_NPC",
      "Miaomiao",
      "NPCPet",
      "Tree",
      "Grass",
      "Rock",
      "Landscape",
      "HLOD",
      "Flower",
      "Bush"
    }
    UE4.UNRCStatics.SetNRCTypePrintName(PrintNames)
  end
  InitGC()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    local deviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel()
    Log.Debug("DeviceLevel: " .. deviceLevel .. "")
    if deviceLevel < 4 then
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.SwitchAvatarGCThreshold 10")
    end
  end
  return 0
end

NRCMain()

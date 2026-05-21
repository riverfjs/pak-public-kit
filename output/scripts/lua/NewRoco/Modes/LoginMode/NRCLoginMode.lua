local NRCLoginMode = NRCModeBase:Extend("NRCLoginMode")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local LoginConfig = require("NewRoco.Modes.LoginMode.LoginConfig")
if not _G.AppMain:HasDebug() then
  _G.DebugModuleCmd = reload("NewRoco.Modules.System.Debug.DebugModuleCmd")
end

function NRCLoginMode:OnConstruct()
  BattleNetManager:ShutDown()
  self.Handler = -1
  Log.Debug("NRCLoginMode OnConstruct")
  if GlobalConfig.AutoEnableLuaDebug then
    UE.UNRCStatics.EnableLuaDebugger(5067)
  end
  if _G.AppMain:IfMountPaksInAdvance() and not _G.AppMain.IsFullPackage() and not _G.AppMain.IsLocalSavedHasBasePaks() then
    local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
    if NeedToDownloadBasePakList then
      if #NeedToDownloadBasePakList > 0 then
        Log.Debug("[NRCLoginMode:OnConstruct]\230\178\161\228\184\139\232\189\189\229\174\140\229\174\140\230\149\180\229\140\133\239\188\140\228\184\141\230\143\144\229\137\141mount")
      else
        Log.Debug("[NRCLoginMode:OnConstruct]\229\183\178\231\187\143\228\184\139\232\189\189\229\174\140\229\174\140\230\149\180\229\140\133\239\188\140\230\143\144\229\137\141mount")
        local BasePakList = _G.PufferDownloadInfo:GetBasePakListWithPatch()
        if not _G.PufferUpdateResTask:MountPakList(BasePakList) then
          Log.Error("[NRCLoginMode:OnConstruct]mount\229\164\177\232\180\165")
        end
      end
    end
  end
  if _G.GlobalConfig.MemoryAutoTest then
    self.config = LoginConfig.GetRecord("LoginConf.non")
  end
  local bMemoryTest = false
  if _G.GlobalConfig.MemoryAutoTest then
    bMemoryTest = _G.GlobalConfig.DisableGameplayMode or _G.GlobalConfig.EngineTestMode
  end
  if not bMemoryTest then
    self:RegisterModule("UpdateUIModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleHead", "NewRoco.Modules.System.UpdateUIModule.UpdateUIModule")
    self:RegisterModule("ScreenClickModule", "Type_System", "NewRoco.Modules.System.ScreenClick.ScreenClickModuleHead", "NewRoco.Modules.System.ScreenClick.ScreenClickModule")
    self:RegisterModule("OnlineModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.Core.Online.OnlineModuleHead", "NewRoco.Modules.Core.Online.OnlineModule")
    self:RegisterModule("LoginModule", "Type_System", "NewRoco.Modules.System.LoginModule.LoginModuleHead", "NewRoco.Modules.System.LoginModule.LoginModule")
    self:RegisterModule("TipsModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.System.TipsModule.TipsModuleHead", "NewRoco.Modules.System.TipsModule.TipsModule")
    self:RegisterModule("LoadingUIModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleHead", "NewRoco.Modules.System.LoadingUIModule.LoadingUIModule")
    self:RegisterModule("LoginCacheNotifyModule", "Type_System", nil, "NewRoco.Modules.System.LoginCacheNotify.LoginCacheNotifyModule")
    self:RegisterModule("ResTrackerModule", NRCModuleTypeDef.Donnt_Destroy, nil, "NewRoco.Modules.System.ResTracker.ResTrackerModule")
    self:RegisterModule("TUIModule", "Type_System", nil, "NewRoco.Modules.System.TUI.TUIModule")
    self:RegisterModule("AppearanceLoginModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.System.AppearanceLogin.AppearanceLoginModuleHead", "NewRoco.Modules.System.AppearanceLogin.AppearanceLoginModule")
    self:RegisterModule("RedPointModule", NRCModuleTypeDef.Donnt_Destroy, nil, "NewRoco.Modules.System.RedPoint.RedPointModule")
    if _G.AppMain:HasDebug() then
      self:RegisterModule("DebugModule", NRCModuleTypeDef.Donnt_Destroy, nil, "NewRoco.Modules.System.Debug.DebugModule")
    end
    self:RegisterModule("MultiTouchModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.Core.MultiTouch.MultiTouchModuleHead", "NewRoco.Modules.Core.MultiTouch.MultiTouchModule")
    self:RegisterModule("PayModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.System.ChargePay.PayModuleHead", "NewRoco.Modules.System.ChargePay.PayModule")
    self:RegisterModule("CosUploadModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.Core.CosUpload.CosUploadModuleHead", "NewRoco.Modules.Core.CosUpload.CosUploadModule")
    self:RegisterModule("EnhancedInputModule", NRCModuleTypeDef.Donnt_Destroy, "NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleHead", "NewRoco.Modules.Core.EnhancedInput.EnhancedInputModule")
    self:RegisterModule("FunctionBanModule", NRCModuleTypeDef.Donnt_Destroy, nil, "NewRoco.Modules.System.FunctionBan.FunctionBanModule")
    self:RegisterModule("PGCModule", "Type_System", "NewRoco.Modules.System.PGC.PGCModuleHead", "NewRoco.Modules.System.PGC.PGCModule")
  end
end

function NRCLoginMode:OnDestruct()
end

function NRCLoginMode:OnActive()
  local CurLevelName = LevelHelper:GetLevelName()
  if "Login" == CurLevelName then
    self:ActivateModules()
  else
    NRCEventCenter:RegisterEvent("OnMapLoaded", self, NRCGlobalEvent.PostLoadMapWithWorld, self.OnMapLoaded)
    if _G.GlobalConfig.HasEnteredLoginMode then
      _G.GlobalConfig.UserKickedOutFromGame = true
      LevelHelper:OpenLevel("/Game/Levels/UpdateLevel")
    else
      LevelHelper:OpenLevel("/Game/Levels/Login")
    end
  end
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeWorldComposition 0")
  _G.GlobalConfig.HasEnteredLoginMode = true
  _G.NRCSDKManager:MarkLevelLoad("Login")
  if _G.GlobalConfig.MemoryAutoTest then
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeAllLevels 0")
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.CustomGameModePath None")
    _G.GlobalConfig.DisableNPCModule = false
    _G.GlobalConfig.DisableSystemModule = false
    _G.GlobalConfig.DisableNetPlayer = false
    _G.GlobalConfig.DisablePlayerModule = false
    _G.GlobalConfig.DisableCoreModule = false
    _G.GlobalConfig.BigWorldModuleTest = false
    _G.GlobalConfig.DisablePreLoadAsset = false
    if self.config.DisablePreLoadAsset == "1" then
      _G.GlobalConfig.DisablePreLoadAsset = true
      _G.GlobalConfig.DisableSystemModule = true
      _G.GlobalConfig.DisableNPCModule = true
      _G.GlobalConfig.DisablePlayerModule = true
      _G.GlobalConfig.DisableCoreModule = true
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeAllLevels 1")
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.CustomGameModePath /Game/Game/NRC/GameMode/AutoTest/DefaultGM.DefaultGM_C")
    end
    if self.config.BigWorldModuleTest == "1" then
      _G.GlobalConfig.BigWorldModuleTest = true
      _G.GlobalConfig.DisableSystemModule = true
      _G.GlobalConfig.DisableNPCModule = true
      _G.GlobalConfig.DisablePlayerModule = true
      _G.GlobalConfig.DisableCoreModule = true
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeAllLevels 1")
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.CustomGameModePath /Game/Game/NRC/GameMode/AutoTest/DefaultGM.DefaultGM_C")
    end
    if "1" == self.config.SystemModuleTest then
      _G.GlobalConfig.DisableNetPlayer = true
      _G.GlobalConfig.DisableSystemModule = true
      _G.GlobalConfig.DisableNPCModule = true
    end
    if "1" == self.config.PlayerModuleTest then
      _G.GlobalConfig.DisableSystemModule = true
      _G.GlobalConfig.DisableNPCModule = true
      _G.GlobalConfig.DisableNetPlayer = true
      UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeAllLevels 1")
    end
    if "1" == self.config.NetCreateModuleTest then
      _G.GlobalConfig.DisableNetPlayer = true
      _G.GlobalConfig.DisableNPCModule = true
    end
    if "1" == self.config.NetPlayerModuleTest then
      _G.GlobalConfig.DisableNPCModule = true
    end
    if "1" == self.config.NPCModuleTest then
      _G.GlobalConfig.DisableNetPlayer = true
    end
  end
end

function NRCLoginMode:OnMapLoaded()
  self.Handler = _G.DelayManager:DelayFrames(1, function()
    NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.PostLoadMapWithWorld, self.OnMapLoaded)
    self:ActivateModules()
  end)
end

function NRCLoginMode:ActivateModules()
  if not _G.GlobalConfig.bEnteredHotUpdateFinish then
    UE4.UNRCPlatformGameInstance.OnHotUpdateFinish()
    _G.GlobalConfig.bEnteredHotUpdateFinish = true
  end
  self:ActiveModule("MultiTouchModule")
  if not _G.GlobalConfig.DisableGameplayMode then
    self:ActiveModule("ScreenClickModule")
    self:ActiveModule("OnlineModule")
    self:ActiveModule("TipsModule")
    self:ActiveModule("LoadingUIModule")
    self:ActiveModule("LoginCacheNotifyModule")
    self:ActiveModule("ResTrackerModule")
    self:ActiveModule("UpdateUIModule")
    self:ActiveModule("LoginModule")
    self:GetModule("LoginModule"):StartLoginFsm()
    self:ActiveModule("TUIModule")
    self:ActiveModule("CosUploadModule")
  end
  self:ActiveModule("DebugModule")
  self:ActiveModule("RedPointModule")
  self:ActiveModule("AppearanceLoginModule")
  self:ActiveModule("PayModule")
  self:ActiveModule("EnhancedInputModule")
  self:ActiveModule("FunctionBanModule")
  self:ActiveModule("PGCModule")
  if not _G.GlobalConfig.DisablePreLoadAsset then
    _G.NRCModuleManager:PreloadModulePanel()
  end
  NRCModuleManager:DoCmd(UpdateUIModuleCmd.ShowUid, false)
end

function NRCLoginMode:OnAllGroupFinished()
end

function NRCLoginMode:OnDeactive()
  BattleNetManager:Init()
  BattleNetManager:GetNotifyCache()
  if not _G.GlobalConfig.DisableGameplayMode then
    self:GetModule("UpdateUIModule"):CleanUp()
  end
  if self.Handler > 0 then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = -1
  end
  DataModelMgr.LoginNotifyModel:ClearCache()
  NRCModuleManager:DoCmd(UpdateUIModuleCmd.ShowUid, true)
  collectgarbage("collect")
  UE4.UNRCStatics.ForceGarbageCollection(true)
end

return NRCLoginMode

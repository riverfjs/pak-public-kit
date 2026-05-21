local LockWeatherReason = require("NewRoco.Modules.System.EnvSystem.LockWeatherReason")
local EnvSystemTimeScheduler = require("NewRoco.Modules.System.EnvSystem.EnvSystemTimeScheduler")
local EnvSystemModuleEvent = reload("NewRoco.Modules.System.EnvSystem.EnvSystemModuleEvent")
local LinearTimeSetter = require("NewRoco.Modules.System.EnvSystem.LinearTimeSetter")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
_G.EnvSystemModuleCmd = require("NewRoco.Modules.System.EnvSystem.EnvSystemModuleCmd")
local FadeConf = _G.DataConfigManager:GetMapGlobalConfig("fadetime")
local FadeOutTime = FadeConf and FadeConf.num or 2.0
local EnvSystemModule = NRCModuleBase:Extend("EnvSystemModule")
local TimeType = {Day = 1, Night = 2}

function EnvSystemModule:OnConstruct()
  self.isInit = false
  self.paused = false
  self.maxTime = 86400
  self.SmoothChange = true
  self.timeScale = DataConfigManager:GetGlobalConfigNumByKeyType("tod_time_accelerate", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1)
  self.timeScheduler = EnvSystemTimeScheduler()
  self.timeScheduler:Init()
  self.timeSchedulerCallback = self.timeScheduler:RegisterTime(0)
  self.timeRegisterArray = Array()
  self.tokenId = 1
  self.RefGameTime = nil
  self.RefRealTime = nil
  self.lastUpdateTime = 0
  self.LockWeatherNightmare = Enum.WeatherType.WT_NONE
  self.LockWeatherBattle = Enum.WeatherType.WT_NONE
  self.LockWeatherGM = Enum.WeatherType.WT_NONE
  self.CurrentWeather = Enum.WeatherType.WT_NONE
  self.WeatherFromServer = Enum.WeatherType.WT_SUNNY
  self.CurrentAbnormal = nil
  self.LastTeleportTime = 0
  self.bFirstWeatherChange = true
  self.bSwitchWeather = false
  self.bChangeResult = true
  self.TimeType = TimeType.Day
  self.bloomOwners = Array()
  self:RegisterCmd(EnvSystemModuleCmd.ChangeGameTime, self.OnCmdChangeTime)
  self:RegisterCmd(EnvSystemModuleCmd.GMChangeGameTime, self.OnCmdGMChangeTime)
  self:RegisterCmd(EnvSystemModuleCmd.ChangeGameTimeLocal, self.OnCmdChangeTimeLocal)
  self:RegisterCmd(EnvSystemModuleCmd.ChangeTimeScale, self.ChangeTimeScale)
  self:RegisterCmd(EnvSystemModuleCmd.ChangeWeather, self.OnChangeWeatherFromServer)
  self:RegisterCmd(EnvSystemModuleCmd.PrintCurrentTime, self.OnCmdPrintCurrentTime)
  self:RegisterCmd(EnvSystemModuleCmd.TogglePause, self.OnTogglePause)
  self:RegisterCmd(EnvSystemModuleCmd.RegisterTimeCallback, self.RegisterTimeCallback)
  self:RegisterCmd(EnvSystemModuleCmd.UnRegisterTimeCallback, self.UnRegisterTimeCallback)
  self:RegisterCmd(EnvSystemModuleCmd.ShowRegisterArray, self.ShowRegisterArray)
  self:RegisterCmd(EnvSystemModuleCmd.GetCurrentTime, self.GetCurrentTime)
  self:RegisterCmd(EnvSystemModuleCmd.SkipOneDay, self.SkipOneDay)
  self:RegisterCmd(EnvSystemModuleCmd.RegisterTime, self.RegisterTime)
  self:RegisterCmd(EnvSystemModuleCmd.ReleaseTime, self.ReleaseTime)
  self:RegisterCmd(EnvSystemModuleCmd.OnThundering, self.OnThundering)
  self:RegisterCmd(EnvSystemModuleCmd.GetCachedMFEnvSystem, self.OnGetCachedMFEnvSystem)
  self:RegisterCmd(EnvSystemModuleCmd.OnEnterBattle, self.OnEnterBattle)
  self:RegisterCmd(EnvSystemModuleCmd.OnLeaveBattle, self.OnLeaveBattle)
  self:RegisterCmd(EnvSystemModuleCmd.OnSyncTimeAction, self.OnSyncTimeAction)
  self:RegisterCmd(EnvSystemModuleCmd.GetCurrentWeatherType, self.OnCmdGetCurrentWeatherType)
  self:RegisterCmd(EnvSystemModuleCmd.UpdateAbnormal, self.OnUpdateAbnormal)
  self:RegisterCmd(EnvSystemModuleCmd.CustomBloom, self.CustomBloom)
  self:RegisterCmd(EnvSystemModuleCmd.LockWeather, self.OnLockWeather)
  self:RegisterCmd(EnvSystemModuleCmd.IsNightType, self.IsNightType)
  self:RegisterCmd(EnvSystemModuleCmd.CollectSceneData, self.OnCollectSceneData)
  self:RegisterCmd(EnvSystemModuleCmd.GetTimestampWithInfo, self.GetTimestampWithInfo)
  self:RegisterCmd(EnvSystemModuleCmd.ForceSetLensFlaresActorVisibility, self.OnCmdForceSetLensFlaresActorVisibility)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnPostEnterScene)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.OnWorldMapLoaded)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.LoadMapStart, self.OnPlayerTeleportStart)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
end

function EnvSystemModule:OnWorldMapLoaded(World)
end

function EnvSystemModule:OnPlayerTeleportStart()
  Log.Debug("Mark Teleport!!!")
  self.LastTeleportTime = _G.UpdateManager.Timestamp
end

function EnvSystemModule:OnPlayerTeleportFinish()
end

function EnvSystemModule:OnGetCachedMFEnvSystem()
  return nil
end

function EnvSystemModule:OnEnterBattle()
  self:CustomBattleBloom()
end

function EnvSystemModule:CustomBattleBloom()
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  self.restoreBloom = {}
  self.restoreBloom.bloomState = EnvSys:GetBloomState()
  local InBloomIntensity, InBloomThreshold, Interval = EnvSys:GetBloomSettings()
  self.restoreBloom.bloomIntensity = InBloomIntensity
  self.restoreBloom.bloomThreshold = InBloomThreshold
  self.restoreBloom.bloomInterval = Interval
  local BloomTint3, BloomTint4, BloomTint5, TintInterval = EnvSys:GetBloomAdditionalSettings()
  self.restoreBloom.BloomTint3 = BloomTint3
  self.restoreBloom.BloomTint4 = BloomTint4
  self.restoreBloom.BloomTint5 = BloomTint5
  self.restoreBloom.TintInterval = TintInterval
  local InBloomCombineParameter, CombineParameterInterval = EnvSys:GetNRCBloomCombineParameter()
  self.restoreBloom.InBloomCombineParameter = InBloomCombineParameter
  self.restoreBloom.CombineParameterInterval = CombineParameterInterval
  EnvSys:SetIsBattle(true)
  EnvSys:SetBloomState(true)
  EnvSys:SetBloomSettings(0.75, 0.5, 0.0)
  EnvSys:SetBloomAdditionalSettings(UE4.FLinearColor(0.1176, 0.1176, 0.1176, 0), UE4.FLinearColor(0.066, 0.066, 0.066, 0), UE4.FLinearColor(0.066, 0.066, 0.066, 0), 0.1)
  EnvSys:SetNRCBloomCombineParameter(UE4.FLinearColor(0.5, 0.3, 0.4, 0.5), 0.0)
end

function EnvSystemModule:OnLeaveBattle()
  self:RestoreBattleCustomBloom()
end

function EnvSystemModule:RestoreBattleCustomBloom()
  if not self.restoreBloom then
    return
  end
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  EnvSys:SetBloomState(self.restoreBloom.bloomState)
  EnvSys:SetBloomSettings(self.restoreBloom.bloomIntensity, self.restoreBloom.bloomThreshold, self.restoreBloom.bloomInterval)
  EnvSys:SetBloomAdditionalSettings(self.restoreBloom.BloomTint3, self.restoreBloom.BloomTint4, self.restoreBloom.BloomTint5, self.restoreBloom.TintInterval)
  EnvSys:SetNRCBloomCombineParameter(self.restoreBloom.InBloomCombineParameter, self.restoreBloom.CombineParameterInterval)
  EnvSys:SetIsBattle(false)
  self.restoreBloom = nil
end

function EnvSystemModule:OnDestruct()
  self.isInit = false
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.OnWorldMapLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnPostEnterScene)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.OnPlayerTeleportStart)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
end

function EnvSystemModule:OnActive()
  self:InitGameTime(36000)
  if not NRCEnv:IsLocalMode() or not UE4.UNRCStatics.IsRenderingMovie() then
  end
end

function EnvSystemModule:OnDeactive()
  self.isInit = false
end

function EnvSystemModule:OnCmdChangeTime(_timeValue, SmoothChange, NpcId)
  Log.Debug("EnvSystemModule OnCmdChangeTime ", _timeValue, SmoothChange, NpcId)
  self.SmoothChange = true == SmoothChange
  local req = _G.ProtoMessage:newZoneSceneModGameTimeReq()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Now = self:GetTimestampWithInfo(localPlayer.serverData.game_time_infos)
  Now = Now / 1000
  local Today = math.floor(Now / 86400) * 86400
  local DesiredTime = Today + _timeValue
  if Now > DesiredTime then
    DesiredTime = DesiredTime + 86400
  end
  req.time_stamp = math.round(DesiredTime)
  req.npc_id = NpcId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MOD_GAME_TIME_REQ, req, self, self.OnGameTimeChange)
end

function EnvSystemModule:OnCmdGMChangeTime(_timeValue, SmoothChange)
  self.SmoothChange = true == SmoothChange
  local Req = _G.ProtoMessage:newZoneGmExecCommGmCmdReq()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Now = self:GetTimestampWithInfo(localPlayer.serverData.game_time_infos)
  Now = Now / 1000
  local Today = math.floor(Now / 86400) * 86400
  local DesiredTime = Today + _timeValue
  if Now > DesiredTime then
    DesiredTime = DesiredTime + 86400
  end
  Req.cmd.cmd_id = "mod_game_time"
  Req.cmd.cmd_name = "\228\191\174\230\148\185\230\184\184\230\136\143\230\151\182\233\151\180"
  Req.cmd.cmd_desc = "\228\191\174\230\148\185\230\184\184\230\136\143\230\151\182\233\151\180(\228\187\165\228\184\139\229\143\130\230\149\176\228\186\140\233\128\137\228\184\128)"
  Req.cmd.params = {}
  table.insert(Req.cmd.params, {
    key = "addi_time",
    require = false,
    type = 101,
    param_str = nil,
    param_desc = "\229\144\145\229\137\141\230\142\168\232\191\155\231\154\132\231\167\146\230\149\176"
  })
  table.insert(Req.cmd.params, {
    key = "time_stamp",
    require = false,
    type = 101,
    param_str = {
      tostring(DesiredTime)
    },
    param_desc = "\232\166\129\232\174\190\231\189\174\231\154\132\230\151\182\233\151\180\230\136\179(\231\167\146)"
  })
  if _G.AppMain:HasDebug() then
    _G.NRCModuleManager:DoCmd(DebugModuleCmd.GMExecCommGmCmd, Req.cmd)
  end
end

function EnvSystemModule:OnCmdChangeTimeLocal(_timeValue, SmoothChange)
  Log.Debug("EnvSystemModule OnCmdChangeTimeLocal ", _timeValue, SmoothChange)
  self.SmoothChange = true == SmoothChange
  if SmoothChange then
    local Setter = LinearTimeSetter()
    Setter:Start(_timeValue, 3)
  end
  self:UpdateClientTime(_timeValue)
end

function EnvSystemModule:OnGameTimeChange(rsp)
  self.SmoothChange = true
end

function EnvSystemModule:UpdateClientTime(_timeValue)
  self:InitGameTime(_timeValue or 0)
  if AreaAndZoneModuleCmd then
    _G.NRCModuleManager:DoCmd(AreaAndZoneModuleCmd.OnTimeGoBack, self.gameBeginTime)
  end
  self:DispatchEvent(EnvSystemModuleEvent.TimeChangeEvent)
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if not EnvSys then
    Log.Error("\230\137\190\228\184\141\229\136\176\229\164\169\230\176\148\229\173\144\231\179\187\231\187\159")
    return
  end
  EnvSys.OnSetGameTimeDelegate:Broadcast()
end

function EnvSystemModule:OnPostEnterScene()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:ApplyGameTimeInfo(localPlayer.serverData.game_time_infos, false)
end

function EnvSystemModule:OnSyncTimeAction(Action)
  local Info = Action.game_time_info
  self:ApplyGameTimeInfo(Info, self.SmoothChange)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer.serverData.game_time_infos = Info
  end
end

function EnvSystemModule:GetTimestampWithInfo(Info)
  if not Info then
    return 0
  end
  local CurrentTimestamp = 0
  if Info.paused then
    CurrentTimestamp = Info.ref_game_time
  else
    local ServerTime = _G.ZoneServer:GetServerTime()
    Log.Debug("Show ServerTime", ServerTime, Info.ref_game_time, Info.ref_real_time)
    CurrentTimestamp = Info.ref_game_time + math.max(0, (ServerTime - Info.ref_real_time) * Info.accelerative_ratio)
    self.RefGameTime = Info.ref_game_time
    self.RefRealTime = Info.ref_real_time
  end
  return CurrentTimestamp
end

function EnvSystemModule:ApplyGameTimeInfo(DestInfo, SmoothChange)
  Log.Dump(DestInfo, 6, "EnvSystemModule:ApplyGameTimeInfo")
  if not DestInfo then
    return
  end
  if DestInfo.paused ~= nil then
    self.paused = DestInfo.paused
    if self.paused then
      SmoothChange = false
    end
  end
  self:ChangeTimeScale(DestInfo.accelerative_ratio)
  self:UpdateTimeType(DestInfo.accelerative_ratio)
  local DestTimestamp = self:GetTimestampWithInfo(DestInfo) / 1000
  if SmoothChange then
    local Setter = LinearTimeSetter()
    Setter:Start(DestTimestamp, 3)
  end
  self:UpdateClientTime(DestTimestamp)
end

function EnvSystemModule:UpdateTimeType(Ratio)
  if Ratio <= 1 then
    self.TimeType = TimeType.Night
  else
    self.TimeType = TimeType.Day
  end
  Log.Debug("EnvSystemModule:UpdateTimeType: ", self.TimeType)
end

function EnvSystemModule:IsNightType()
  return self.TimeType == TimeType.Night
end

function EnvSystemModule:OnChangeWeatherFromServer(weather, update)
  self.WeatherFromServer = weather
  self:OnChangeWeather(weather, update)
end

local WeatherTypeMapping = {
  [Enum.WeatherType.WT_CLOUDY] = {
    State = UE4.EWeatherStateEnum.Cloudy,
    Audio = "Cloudy"
  },
  [Enum.WeatherType.WT_HEAVYRAIN] = {
    State = UE4.EWeatherStateEnum.HeavyRain,
    Audio = "HeavyRain"
  },
  [Enum.WeatherType.WT_LIGHTRAIN] = {
    State = UE4.EWeatherStateEnum.LightRain,
    Audio = "LightRain"
  },
  [Enum.WeatherType.WT_SUNNY] = {
    State = UE4.EWeatherStateEnum.Sunny,
    Audio = "Sunny"
  },
  [Enum.WeatherType.WT_DUNGNONE] = {
    State = UE4.EWeatherStateEnum.Sunny,
    Audio = "Sunny"
  },
  [Enum.WeatherType.WT_SNOWSTORM] = {
    State = UE4.EWeatherStateEnum.SnowStorm,
    Audio = "SnowStorm"
  },
  [Enum.WeatherType.WT_SANDSTORM] = {
    State = UE4.EWeatherStateEnum.SandStorm,
    Audio = "SandStorm"
  },
  [Enum.WeatherType.WT_FOGGY] = {
    State = UE4.EWeatherStateEnum.Foggy,
    Audio = "Foggy"
  },
  [Enum.WeatherType.WT_ABNORMAL] = {
    State = UE4.EWeatherStateEnum.Abnormal,
    Audio = "Abnormal"
  },
  [Enum.WeatherType.WT_SNOW] = {
    State = UE4.EWeatherStateEnum.Snow,
    Audio = "Snow"
  },
  [Enum.WeatherType.WT_NIGHTMARE] = {
    State = UE4.EWeatherStateEnum.Nightmare,
    Audio = "Nightmare"
  },
  [Enum.WeatherType.WT_NIGHTMARE_LITE] = {
    State = UE4.EWeatherStateEnum.NightmareLite,
    Audio = "NightmareLite"
  },
  [Enum.WeatherType.WT_NIGHTMARE_SP] = {
    State = UE4.EWeatherStateEnum.NightmareSpecial,
    Audio = "NightmareSpecial"
  }
}
local DefaultWeatherMapping = {
  State = UE4.EWeatherStateEnum.Sunny,
  Audio = "Sunny"
}

function EnvSystemModule:OnChangeWeather(weather, update)
  if self.LockWeatherBattle ~= Enum.WeatherType.WT_NONE then
    weather = self.LockWeatherBattle
    Log.DebugFormat("[EnvSystemModule]\228\189\191\231\148\168\228\186\134\229\188\186\229\136\182\233\148\129\229\174\154\229\164\169\230\176\148\239\188\136\230\136\152\230\150\151\239\188\137:%s", table.getKeyName(Enum.WeatherType, weather))
  elseif self.LockWeatherNightmare ~= Enum.WeatherType.WT_NONE then
    weather = self.LockWeatherNightmare
    Log.DebugFormat("[EnvSystemModule]\228\189\191\231\148\168\228\186\134\229\188\186\229\136\182\233\148\129\229\174\154\229\164\169\230\176\148\239\188\136\229\176\143\230\184\184\230\136\143\229\153\169\230\162\166\229\164\169\230\176\148\239\188\137:%s", table.getKeyName(Enum.WeatherType, weather))
  elseif self.LockWeatherGM ~= Enum.WeatherType.WT_NONE then
    weather = self.LockWeatherGM
    Log.DebugFormat("[EnvSystemModule]\228\189\191\231\148\168\228\186\134\229\188\186\229\136\182\233\148\129\229\174\154\229\164\169\230\176\148\239\188\136GM\239\188\137:%s", table.getKeyName(Enum.WeatherType, weather))
  end
  Log.Debug("[EnvSystemModule]Setting Weather ", table.getKeyName(Enum.WeatherType, weather), update, _G.UpdateManager.Timestamp - self.LastTeleportTime)
  if weather == self.CurrentWeather and not update then
    Log.Debug("[EnvSystemModule]Skip update weather", table.getKeyName(Enum.WeatherType, weather))
    return
  end
  local prevWeather = self.CurrentWeather
  local FadeOut = _G.UpdateManager.Timestamp - self.LastTeleportTime > 10
  if self.bFirstWeatherChange then
    FadeOut = false
    self.bFirstWeatherChange = false
  end
  if not FadeOut then
    Log.Debug("Set Climate Directly!!!", table.getKeyName(Enum.WeatherType, weather))
  end
  if self.bSwitchWeather then
    FadeOut = true
    self.bSwitchWeather = false
  end
  if self.bIsIgnoreFadeOut then
    FadeOut = false
    self.bIsIgnoreFadeOut = nil
  end
  if _G.GlobalConfig.OpenTestUIScene then
    self.CurrentWeather = weather
    self.bChangeResult = true
    return
  end
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if not EnvSys then
    Log.Error("\230\137\190\228\184\141\229\136\176\229\164\169\230\176\148\229\173\144\231\179\187\231\187\159")
    return
  end
  self.CurrentWeather = weather
  local Mapping = WeatherTypeMapping[weather] or DefaultWeatherMapping
  self.bChangeResult = EnvSys:SetWeatherStat(Mapping.State, FadeOut, update)
  _G.NRCAudioManager:SetStateByName("Amb_Weather", Mapping.Audio)
  Log.Debug("Update Weather To", table.getKeyName(Enum.WeatherType, self.CurrentWeather))
  if _G.AppMain:HasDebug() then
    _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.RefreshWeather, weather)
  end
  self:DispatchEvent(EnvSystemModuleEvent.WeatherChangeEvent, weather, prevWeather)
  UE4.UDotsLuaProxy.AddEvent_WeatherChange(UE4Helper.GetCurrentWorld(), weather)
end

function EnvSystemModule:OnLockWeather(weather, reason, bIsIgnoreFadeOut)
  reason = reason or LockWeatherReason.None
  weather = weather or Enum.WeatherType.WT_NONE
  Log.Debug("[EnvSystemModule]OnLockWeather", table.getKeyName(Enum.WeatherType, weather), table.getKeyName(LockWeatherReason, reason))
  if reason == LockWeatherReason.None then
    Log.Error("\228\184\141\230\148\175\230\140\129\233\148\129\229\174\154\229\164\169\230\176\148\231\154\132reason\228\184\186none")
    return
  end
  if weather == Enum.WeatherType.WT_NONE then
    if reason == LockWeatherReason.Battle then
      self.LockWeatherBattle = Enum.WeatherType.WT_NONE
    elseif reason == LockWeatherReason.MiniGameNightmare then
      self.LockWeatherNightmare = Enum.WeatherType.WT_NONE
    elseif reason == LockWeatherReason.GM then
      self.LockWeatherGM = Enum.WeatherType.WT_NONE
    end
    self:OnChangeWeather(self.WeatherFromServer)
    return
  end
  self.bSwitchWeather = true
  self.bIsIgnoreFadeOut = bIsIgnoreFadeOut
  if reason == LockWeatherReason.Battle then
    self.LockWeatherBattle = weather
  elseif reason == LockWeatherReason.MiniGameNightmare then
    self.LockWeatherNightmare = weather
  elseif reason == LockWeatherReason.GM then
    self.LockWeatherGM = weather
  end
  self:OnChangeWeather(weather, true)
end

function EnvSystemModule:OnUpdateAbnormal(bIsAbnormal)
  if self.CurrentAbnormal == bIsAbnormal then
    return
  end
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if not EnvSys then
    Log.Error("\230\137\190\228\184\141\229\136\176\229\164\169\230\176\148\229\173\144\231\179\187\231\187\159")
    return
  end
  EnvSys:SetTODStat(bIsAbnormal, FadeOutTime, true)
  self.CurrentAbnormal = bIsAbnormal
end

function EnvSystemModule:OnTogglePause()
  if self.paused then
    self.paused = false
  else
    self.paused = true
  end
end

function EnvSystemModule:ChangeTimeScale(timeScale)
  Log.Debug("EnvSystemModule:ChangeTimeScale:", timeScale)
  if nil ~= timeScale then
    self.timeScale = timeScale
  end
end

function EnvSystemModule:OnCmdPrintCurrentTime()
  if self.isInit then
    Log.Debug("EnvSystemModule:PrintCurrentTime:", self.gameBeginTime, self.gameBeginTime / 3600)
  else
    Log.Debug("EnvSystemModule:PrintCurrentTime: time not init!")
  end
end

function EnvSystemModule:InitGameTime(_gameTime)
  if nil == _gameTime then
    return
  end
  self.isInit = true
  self.gameBeginTime = _gameTime
  if self.gameBeginTime > self.maxTime or self.gameBeginTime < 0 then
    self.gameBeginTime = self.gameBeginTime % self.maxTime
    self:UpdateRegisterTimer()
  end
  self.timeSchedulerCallback:UpdateTime(self.gameBeginTime / 3600)
  self:NotifyRegister()
  self.timeScheduler:OnTick()
end

function EnvSystemModule:OnTick(DeltaTime)
  if self.isInit then
    if not self.paused then
      self.gameBeginTime = self.gameBeginTime + DeltaTime * self.timeScale
      if self.gameBeginTime > self.maxTime or self.gameBeginTime < 0 then
        self.gameBeginTime = self.gameBeginTime % self.maxTime
        self.lastUpdateTime = 0
        self:UpdateRegisterTimer()
      end
      if self.gameBeginTime - self.lastUpdateTime > 10 or self.gameBeginTime - self.lastUpdateTime < -10 then
        self.timeSchedulerCallback:UpdateTime(self.gameBeginTime / 3600)
        self.lastUpdateTime = self.gameBeginTime
        self:NotifyRegister()
      end
    end
    if 0 ~= self.timeScale then
      self.timeScheduler:OnTick()
      if not self.bChangeResult then
        self:OnChangeWeather(self.CurrentWeather, true)
      end
    end
  end
end

function EnvSystemModule:NotifyRegister()
  while not self.timeRegisterArray:IsEmpty() and self.timeRegisterArray:Last().callbackTime < self.gameBeginTime do
    local callback = self.timeRegisterArray:Last()
    if callback.cmd then
      _G.NRCModuleManager:DoCmd(callback.cmd, callback)
    elseif callback.caller and callback.callback then
      callback.callback(callback.caller)
    end
    self.timeRegisterArray:Pop()
    if callback.bLoop then
      callback.callbackTime = callback.callbackTime + self.maxTime
      self:InsertTimeRegister(callback)
    end
  end
end

function EnvSystemModule:UpdateRegisterTimer()
  local timeRegisterArrayToRefresh = Array()
  for i, item in ipairs(self.timeRegisterArray:Items()) do
    item.callbackTime = item.callbackTime - self.maxTime
    timeRegisterArrayToRefresh:Add(item)
  end
  for i, item in ipairs(timeRegisterArrayToRefresh:Items()) do
    self.timeRegisterArray:Remove(item)
  end
  for i, item in ipairs(timeRegisterArrayToRefresh:Items()) do
    self:InsertTimeRegister(item)
  end
end

function EnvSystemModule:RegisterTimeCallback(Cmd, CallBackTime, bLoop, callback, caller)
  self:Log("EnvSystemModuleCmd:RegisterTimeCallback", Cmd, CallBackTime)
  local newCallBackTime = CallBackTime
  if CallBackTime < self.gameBeginTime then
    newCallBackTime = CallBackTime + self.maxTime
  end
  local timeRegister = {
    tokenId = self.tokenId,
    callbackTime = newCallBackTime,
    cmd = Cmd,
    bLoop = bLoop,
    callback = callback,
    caller = caller
  }
  self.tokenId = self.tokenId + 1
  self:InsertTimeRegister(timeRegister)
  return timeRegister
end

function EnvSystemModule:UnRegisterTimeCallback(Req)
  self:Log("EnvSystemModuleCmd:UnRegisterTimeCallback", Req.tokenId)
  for i, item in ipairs(self.timeRegisterArray:Items()) do
    if Req == item then
      self.timeRegisterArray:Remove(item)
      return 0
    end
  end
  self:Log("EnvSystemModule:UnRegisterTimeCallback: Try to remove a not exist item")
  return -1
end

function EnvSystemModule:InsertTimeRegister(timeRegister)
  if 0 == #self.timeRegisterArray:Items() then
    self.timeRegisterArray:Push(timeRegister)
    return
  else
    for i, item in ipairs(self.timeRegisterArray:Items()) do
      if item.callbackTime < timeRegister.callbackTime then
        self.timeRegisterArray:Insert(i, timeRegister)
        return
      end
    end
    self.timeRegisterArray:Push(timeRegister)
  end
end

function EnvSystemModule:ShowRegisterArray()
  self:Log("EnvSystemModule ShowRegisterArray start")
  for i, item in ipairs(self.timeRegisterArray:Items()) do
    self:Log("EnvSystemModule ShowRegisterArray", item.tokenId, item.callbackTime / 3600, item.cmd, item.bLoop)
  end
end

function EnvSystemModule:GetCurrentTime()
  return self.gameBeginTime, self.RefGameTime, self.RefRealTime
end

function EnvSystemModule:SkipOneDay()
  self:OnCmdChangeTime(86400)
end

function EnvSystemModule:RegisterTime(time)
  return self.timeScheduler:RegisterTime(time)
end

function EnvSystemModule:ReleaseTime(callback)
  self.timeScheduler:ReleaseTime(callback)
end

function EnvSystemModule:OnThundering()
  local random_num = math.random(0, 100)
  if random_num < 50 then
    _G.NRCAudioManager:PlaySound2DAuto(3008, "EnvSystemModule:OnThundering")
  else
    _G.NRCAudioManager:PlaySound2DAuto(3009, "EnvSystemModule:OnThundering")
  end
end

function EnvSystemModule:OnCmdGetCurrentWeatherType()
  return self.CurrentWeather
end

function EnvSystemModule:CustomBloom(ownerName, bCustom, interval, intensity, threshold)
  self:Log("CustomBloom ", ownerName, bCustom, interval, intensity, threshold)
  if nil == ownerName or "" == ownerName then
    self:LogError("CustomBloom owner is empty")
    return
  end
  local find = false
  for i, item in ipairs(self.bloomOwners:Items()) do
    if ownerName == item.owner then
      find = true
      if not bCustom then
        self.bloomOwners:Remove(item)
      end
    end
  end
  if bCustom then
    self.bloomOwners:Add({
      owner = ownerName,
      InBloomInterval = interval,
      InBloomIntensity = intensity,
      InBloomThreshold = threshold
    })
  end
  self:UpdateBloomStateToEnvSystem(interval)
end

function EnvSystemModule:UpdateBloomStateToEnvSystem(interval)
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if self.bloomOwners:IsEmpty() then
    self:Log("UpdateBloomStateToEnvSystem false")
    EnvSys:SetBloomSettings(2, 1, interval)
    EnvSys:SetBloomState(false)
  else
    local item = self.bloomOwners:Last()
    self:Log("UpdateBloomStateToEnvSystem true", item.owner, item.InBloomInterval, item.InBloomIntensity, item.InBloomThreshold)
    EnvSys:SetBloomState(true)
    EnvSys:SetBloomSettings(item.InBloomIntensity, item.InBloomThreshold, interval)
  end
end

function EnvSystemModule:OnCollectSceneData(zoneInfo)
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if not EnvSys then
    Log.Error("\230\137\190\228\184\141\229\136\176\229\164\169\230\176\148\229\173\144\231\179\187\231\187\159")
    return
  end
  EnvSys:SetZoneInfo(zoneInfo.id, zoneInfo.name)
end

function EnvSystemModule:OnCmdForceSetLensFlaresActorVisibility(bVisible)
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  if not EnvSys then
    Log.Error("\230\137\190\228\184\141\229\136\176\229\164\169\230\176\148\229\173\144\231\179\187\231\187\159")
    return
  end
  EnvSys:ForceSetLensFlaresActorVisibility(not not bVisible)
end

return EnvSystemModule

local EnvSystemModuleCmd = require("NewRoco.Modules.System.EnvSystem.EnvSystemModuleCmd")
local MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AreaInfo = require("NewRoco.Modules.Core.Scene.Map.AreaInfo")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AreaStack = require("NewRoco.Modules.Core.Scene.Map.AreaStack")
local StoryFlagModuleEvent = require("NewRoco.Modules.System.StoryFlag.StoryFlagModuleEvent")
local LoopAudioPlayer = require("Core.Service.Audio.LoopAudioPlayer")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local AbilityBanManager = require("NewRoco.Modules.Core.Scene.Map.AbilityBanManager")
local AreaAndZoneModule = NRCModuleBase:Extend("AreaAndZoneModule")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")

function AreaAndZoneModule:OnConstruct()
  self._needShowTip = false
  self.areaBgm = Array()
  self.currentPriorityChange = false
  self.areaId = 0
  self.bgmId = 0
  self.ambienceId = 0
  self.bgmSessionId = -1
  self.ambSessionId = -1
  self.envSession = LoopAudioPlayer(41600104)
  self.bgmStateGroup = ""
  self.currentTimeState = ""
  self.playerZoneInfo = nil
  self.action = nil
  self.zoneInfoArray = Array()
  self.bgmAreaStack = AreaStack("bgm_priority")
  self.ambAreaStack = AreaStack("amb_switch_priority")
  self.CachedTemperature = 0
  self.CachedEffectType = Enum.SceneEffect.SE_CHANGE_TEMP
  self.CachedAreaID = -1
  self.CurrentWeather = Enum.WeatherType.WT_NONE
  self.zoneInfoArrayNew = {}
  self.activityInfoInitialized = false
  _G.NRCEventCenter:RegisterEvent("NPCModuelInterComp", self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIOpen)
  _G.NRCEventCenter:RegisterEvent("NPCModuelInterComp", self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, _G.TaskModuleEvent.TaskChangeNotify, self.OnTaskChangeNotify)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, StoryFlagModuleEvent.OnStoryFlagChange, self.OnStoryFlagChange)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, ActivityModuleEvent.OnDropNPCChange, self.OnFuncAreaUpdate)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, ActivityModuleEvent.OnSpecificTimeActivityDropUpperLimit, self.ClearStarlightTimer)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, ActivityModuleEvent.OnActivityObjectsUpdateFinish, self.OnActivityObjectsUpdateFinish)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, ActivityModuleEvent.ActivitySvrStateChanged, self.OnActivitySvrStateChanged)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  _G.NRCEventCenter:RegisterEvent("AreaAndZoneModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  self.alert_session = _G.NRCAudioManager:PlaySound2DAuto(3044, "AlertAmb")
  self.thunderstorm_session = _G.NRCAudioManager:PlaySound2DAuto(3045, "thunderstorm")
  self.amb_area_session_map = {}
  self.StoryBgm = "Task_Music;None"
  self.InfluencedAreaFuncId = {}
  self.StoryFlagBgm = nil
  self.AbilityBanManager = AbilityBanManager()
  self.nightActivityStartTime = DataConfigManager:GetActivityGlobalConfig("nighttime_activities_begintime").num
  self.nightActivityEndTime = DataConfigManager:GetActivityGlobalConfig("nighttime_activities_endtime").num
end

function AreaAndZoneModule:OnDestruct()
  if self.bgmSessionId then
    _G.NRCAudioManager:RemoveSessionFinishCallback(self.bgmSessionId)
  end
  _G.NRCAudioManager:ReleaseSession(self.bgmSessionId, true)
  self.bgmSessionId = -1
  _G.NRCAudioManager:ReleaseSession(self.ambSessionId, true)
  self.ambSessionId = -1
  self.envSession:Stop()
  _G.NRCAudioManager:ReleaseSession(self.alert_session, true)
  self.alert_session = -1
  _G.NRCAudioManager:ReleaseSession(self.thunderstorm_session, true)
  self.thunderstorm_session = -1
  _G.NRCAudioManager:ReleaseSession(self.amb_area_session, true)
  self.amb_area_session = -1
  for key, value in pairs(self.amb_area_session_map) do
    _G.NRCAudioManager:ReleaseSession(value, true)
  end
  self.amb_area_session_map = {}
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.TaskModuleEvent.TaskChangeNotify, self.OnTaskChangeNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, StoryFlagModuleEvent.OnStoryFlagChange, self.OnStoryFlagChange)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnDropNPCChange, self.OnFuncAreaUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnSpecificTimeActivityDropUpperLimit, self.ClearStarlightTimer)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnActivityObjectsUpdateFinish, self.OnActivityObjectsUpdateFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.ActivitySvrStateChanged, self.OnActivitySvrStateChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  self.AbilityBanManager:Destruct()
end

function AreaAndZoneModule:OnLogin(isRelogin)
  self.zoneInfoArray:Clear()
  self.bgmAreaStack:Clear()
  self.ambAreaStack:Clear()
  self.zoneInfoArrayNew = {}
end

function AreaAndZoneModule:UpdateTrackTask()
  local TrackingTask = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.GetTrackTask)
  if not TrackingTask then
    self.StoryBgm = "Task_Music;None"
    self.InfluencedAreaFuncId = {}
    return
  end
  self.TrackingTaskID = TrackingTask and TrackingTask.Info.id or 0
  local story_bgm_id = TrackingTask.Config.story_bgm_id or 0
  local story_bgm_conf
  if 0 ~= story_bgm_id then
    story_bgm_conf = _G.DataConfigManager:GetStoryBgmConf(story_bgm_id)
  end
  if story_bgm_conf then
    self.StoryBgm = string.format("Task_Music;Task_Music;%s", story_bgm_conf.story_bgm_state)
  else
    self.StoryBgm = "Task_Music;None"
  end
  self.InfluencedAreaFuncId = TrackingTask.Config.influence_area_func_id or {}
end

function AreaAndZoneModule:OnTaskChangeNotify()
  self:UpdateTrackTask()
  self:UpdateStoryBgm()
end

function AreaAndZoneModule:OnStoryFlagChange()
  self:UpdateStoryBgm()
end

function AreaAndZoneModule:UpdateStoryBgm()
  for i, area_func_id in ipairs(self.InfluencedAreaFuncId) do
    if self.bgmAreaStack:IsInArea(area_func_id) then
      _G.NRCAudioManager:BatchSetState(self.StoryBgm)
      return
    end
  end
  local currentAreaFuncID = self:GetCurrentAreaFuncId()
  self.StoryFlagBgm = _G.NRCModuleManager:DoCmd(_G.StoryFlagModuleCmd.GetCurrentStoryBgmState, currentAreaFuncID)
  if not string.IsNilOrEmpty(self.StoryFlagBgm) then
    _G.NRCAudioManager:BatchSetState(self.StoryFlagBgm)
    return
  end
  _G.NRCAudioManager:BatchSetState("Task_Music;None")
end

function AreaAndZoneModule:OnOnlineStateChanged(oldOnlineState, newOnlineState, disOnlineState)
  Log.Debug("AreaAndZoneModule:OnOnlineStateChanged", newOnlineState)
end

function AreaAndZoneModule:OnReconnectFinish()
  Log.Debug("AreaAndZoneModule:OnReconnectFinish")
  self.playerZoneInfo = nil
  self.zoneInfoArrayNew = {}
end

function AreaAndZoneModule:OnCatcherEnter(action)
  self.AbilityBanManager:OnEnterArea(action and action.entered_area_id)
  local funcConf = _G.DataConfigManager:GetAreaFuncConf(action.area_func_conf_id)
  if not funcConf then
    Log.Error("AreaConf\228\184\141\229\173\152\229\156\168\239\188\140\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\227\128\130\227\128\130\227\128\130", action.area_func_conf_id)
    return
  end
  local area_func_id = funcConf.id
  self.zoneInfoArrayNew[area_func_id] = (self.zoneInfoArrayNew[area_func_id] or 0) + 1
  local index = 1
  local already_exist = false
  for i, info in ipairs(self.zoneInfoArray:Items()) do
    local item = info.Conf
    if funcConf.name_priority < item.name_priority then
      index = i + 1
    end
    if funcConf.id == item.id then
      info.bIsUnlocked = action.area_camp_unlock
      already_exist = true
    end
  end
  if not already_exist then
    self.zoneInfoArray:Insert(index, AreaInfo(funcConf, action.area_camp_unlock))
  end
  index = 1
  already_exist = false
  local bgm_index, bgm_already_exist = self.bgmAreaStack:EnterArea(funcConf)
  local amb_index, amb_already_exist = self.ambAreaStack:EnterArea(funcConf)
  if not bgm_already_exist and 1 == bgm_index then
    self:UpdateAreaBgm(true)
  end
  if not amb_already_exist and 1 == amb_index then
    self:UpdateAmb(true)
  end
  self:UpdateStoryBgm()
  if already_exist and 1 == index then
    if not self.currentPriorityChange then
      self:UpdateTemperature()
      self:UpdateAbnormal()
      return
    else
      self.currentPriorityChange = false
    end
  end
  if not self.zoneInfoArray:IsEmpty() then
    local newPlayerAreaInfo = self.zoneInfoArray:Get(1)
    local heightAreaInfo, caveAreaInfo, activityAreaInfo
    for i, info in ipairs(self.zoneInfoArray:Items()) do
      if info:IsCave() then
        caveAreaInfo = info
      end
      if not heightAreaInfo and info:GetHeight() > 0 then
        heightAreaInfo = info
      end
      if info:IsActivity() then
        activityAreaInfo = info
      end
    end
    if heightAreaInfo then
      newPlayerAreaInfo = heightAreaInfo
    end
    if activityAreaInfo and self:CheckShowActivityNameByNPCAndId(activityAreaInfo.Conf.id) then
      newPlayerAreaInfo = activityAreaInfo
    end
    local newPlayerZoneInfo = newPlayerAreaInfo.Conf
    if string.IsNilOrEmpty(newPlayerZoneInfo.name) and self:PlayPlaceName() then
      newPlayerZoneInfo = self:PlayPlaceName()
    end
    if self.playerZoneInfo then
      self:Log("Enter, self.playerZoneInfo", self.playerZoneInfo.id, "newPlayerZoneInfo", newPlayerZoneInfo.id)
    else
      self:Log("Enter, no playerZoneInfo")
    end
    if not self.playerZoneInfo or newPlayerZoneInfo.id ~= self.playerZoneInfo.id then
      self.playerZoneInfo = newPlayerZoneInfo
      if self._isMainUIOpened then
        self.action = action
        local playerZoneInfo = self:PlayPlaceName()
        self:DoEnterZone(playerZoneInfo)
      else
        self.Log("AreaAndZoneModule:OnCatcherEnter MainUI not open")
        self._needShowTip = true
      end
      local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
      if mainUIModule then
        mainUIModule:DispatchEvent(MainUIModuleEvent.ZoneInfoChange)
      end
      _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.CollectSceneData, self.playerZoneInfo)
    end
    self.playerZoneInfo = newPlayerZoneInfo
    local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
    if mainUIModule then
      mainUIModule:DispatchEvent(MainUIModuleEvent.UpdateMinimapShow)
    end
  end
  local areaVisibleConf = _G.DataConfigManager:GetAreaVisibleConf(action.entered_area_id, true)
  if areaVisibleConf then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.EntranceVisibleZone, action.entered_area_id)
  end
  if self:IsActivityDrop(action.area_func_conf_id) then
    self:CreateStarlightTimer(action.area_func_conf_id)
    Log.DebugFormat("StartDropStar:%d", action.area_func_conf_id)
  end
  self:UpdateSafeZone()
  self:UpdateTemperature()
  self:UpdateAbnormal()
  self:UpdateCave()
  self:UpdateCanMessage()
end

function AreaAndZoneModule:OnCatcherLeave(action)
  self:Log("OnCatcherLeave", action.area_func_conf_id)
  self.AbilityBanManager:OnExitArea(action and action.left_area_id)
  local funcConf = _G.DataConfigManager:GetAreaFuncConf(action.area_func_conf_id)
  if not funcConf then
    Log.Error("\229\144\142\229\143\176\228\184\139\229\143\145\231\154\132area_func_conf_id\230\160\185\230\156\172\228\184\141\229\173\152\229\156\168\239\188\140\229\156\176\229\144\141\231\155\184\229\133\179\233\128\187\232\190\145\229\164\167\230\166\130\231\142\135\228\188\154\230\156\137\233\151\174\233\162\152\239\188\140\232\175\183\228\189\191\231\148\168\229\146\140\229\174\162\230\136\183\231\171\175\229\140\185\233\133\141\231\154\132\230\156\141\229\138\161\229\153\168", action.left_area_id, action.area_func_conf_id)
    return
  end
  local area_func_id = funcConf.id
  local ref_count = self.zoneInfoArrayNew[area_func_id] or 0
  ref_count = ref_count - 1
  if ref_count > 0 then
    self.zoneInfoArrayNew[area_func_id] = ref_count
    self:Log("OnCatcherLeave refCount still > 0, skip remove", area_func_id, ref_count)
    return
  end
  self.zoneInfoArrayNew[area_func_id] = nil
  local index = 0
  for i, info in ipairs(self.zoneInfoArray:Items()) do
    local item = info.Conf
    self:Log(i, funcConf.id, funcConf.name_priority, item.id, item.name_priority)
    if funcConf.id == item.id then
      index = i
    end
  end
  if 0 ~= index then
    self.zoneInfoArray:RemoveAt(index)
    if not self.zoneInfoArray:IsEmpty() then
      local playerAreaInfo = self.zoneInfoArray:Get(1)
      self.playerZoneInfo = playerAreaInfo.Conf
      self.currentPriorityChange = true
    else
      self.playerZoneInfo = nil
    end
    if nil ~= self.playerZoneInfo then
      self:OnAreaChange(self.playerZoneInfo.id, false)
      local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
      if mainUIModule then
        mainUIModule:DispatchEvent(MainUIModuleEvent.ZoneInfoChange)
      end
    end
    local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
    if mainUIModule then
      mainUIModule:DispatchEvent(MainUIModuleEvent.UpdateMinimapShow)
    end
    self:UpdateSafeZone()
    self:UpdateTemperature()
    self:UpdateAbnormal()
    self:UpdateCave()
    self:UpdateCanMessage()
  end
  local bgm_index = self.bgmAreaStack:ExitArea(funcConf)
  local amb_index = self.ambAreaStack:ExitArea(funcConf)
  if 1 == bgm_index then
    self:UpdateAreaBgm(true)
  end
  if 1 == amb_index then
    self:UpdateAmb()
  end
  self:UpdateStoryBgm()
  if self:IsActivityDrop(action.area_func_conf_id) then
    self:ClearStarlightTimer()
    Log.DebugFormat("EndDropStar:%d", action.area_func_conf_id)
  end
end

function AreaAndZoneModule:OnTeleportClearAreaInfo()
  self.zoneInfoArrayNew = {}
  for i, info in ipairs(self.zoneInfoArray:Items()) do
    if info:IsCave() then
      local funcConf = _G.DataConfigManager:GetAreaFuncConf(info.Conf.id)
      local index = i
      if 0 ~= index then
        self.zoneInfoArray:RemoveAt(index)
      end
      local bgm_index = self.bgmAreaStack:ExitArea(funcConf)
      local amb_index = self.ambAreaStack:ExitArea(funcConf)
      if 1 == bgm_index then
        self:UpdateAreaBgm(true)
      end
      if 1 == amb_index then
        self:UpdateAmb()
      end
      self:UpdateStoryBgm()
    end
  end
  if not self.zoneInfoArray:IsEmpty() then
    local playerAreaInfo = self.zoneInfoArray:Get(1)
    self.playerZoneInfo = playerAreaInfo.Conf
    self.currentPriorityChange = true
  end
  if self.playerZoneInfo ~= nil then
    self:OnAreaChange(self.playerZoneInfo.id, false)
  end
  self:UpdateSafeZone()
  self:UpdateTemperature()
  self:UpdateAbnormal()
  self:UpdateCave()
  self:UpdateCanMessage()
  self.AbilityBanManager:OnPlayerTeleport()
end

function AreaAndZoneModule:OnWeatherChange(Action, Tag)
  Log.Debug("Weather Change!", Action and Action.weather or -1)
  if not Action then
    return
  end
  self.CurrentWeather = Action.weather
  _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.ChangeWeather, self.CurrentWeather, (Tag and Tag.battle_tag) ~= nil)
end

function AreaAndZoneModule:UpdateSafeZone()
  self:Log("UpdateSafeZone", self.isSaveZone)
  self.isSaveZone = false
  for _, info in ipairs(self.zoneInfoArray:Items()) do
    if info:IsSafe() then
      self.isSaveZone = true
      break
    end
  end
end

function AreaAndZoneModule:UpdateCave()
  local oldFlag = self.isCave
  self.isCave = false
  self.CaveConf = nil
  for _, info in ipairs(self.zoneInfoArray:Items()) do
    if info:IsCave() then
      self.isCave = true
      self.CaveConf = info.Conf
      break
    end
  end
  if oldFlag ~= self.isCave then
    self:Log("UpdateCave change flag ", self.isCave)
  end
end

function AreaAndZoneModule:UpdateCanMessage()
end

function AreaAndZoneModule:GetCaveInfo()
  return self.CaveConf
end

function AreaAndZoneModule:UpdateTemperature()
  self.CachedTemperature, self.CachedEffectType, self.CachedAreaID = self:CalculateTemperature()
end

function AreaAndZoneModule:UpdateAbnormal()
  local bIsAbnormal = false
  if not self.zoneInfoArray:IsEmpty() then
    local Info = self.zoneInfoArray:First()
    if Info then
      bIsAbnormal = Info:IsAbnormal()
    end
  end
  _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.UpdateAbnormal, bIsAbnormal)
end

function AreaAndZoneModule:GetTemperature()
  return self.CachedTemperature, self.CachedEffectType, self.CachedAreaID
end

function AreaAndZoneModule:GetZoneWeather()
  return self.CurrentWeather
end

function AreaAndZoneModule:CalculateTemperature()
  local Temperature = 0
  local Count = 0
  for _, Info in ipairs(self.zoneInfoArray:Items()) do
    local scene_effect = Info.Conf.scene_effect
    for _, effect in ipairs(scene_effect) do
      if effect.effect_type == _G.Enum.SceneEffect.SE_SET_TEMP then
        return effect.effect_param1, effect.effect_type, Info.id
      elseif effect.effect_type == _G.Enum.SceneEffect.SE_CHANGE_TEMP then
        Temperature = Temperature + (effect.effect_param1 or 0)
        Count = Count + 1
        break
      end
    end
  end
  if 0 == Count then
    return 0, _G.Enum.SceneEffect.SE_CHANGE_TEMP, -1
  end
  return Temperature / Count, _G.Enum.SceneEffect.SE_CHANGE_TEMP, -1
end

function AreaAndZoneModule:DoEnterZone(playerZoneInfo)
  self:Log("DoEnterZone")
  if self.playerZoneInfo then
    local zoneId
    if playerZoneInfo then
      zoneId = playerZoneInfo.id
    else
      zoneId = self.playerZoneInfo.id
    end
    if zoneId then
      if self.action then
        self:Log("ShowZoneTip", zoneId, self.action.bIsUnlocked)
        self:OnAreaChange(self.playerZoneInfo.id, true)
        if playerZoneInfo then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ShowZoneTip, zoneId, self.action)
        end
        if _G.GlobalConfig.bShouldShowRevivePointInfo then
          self:SendGetDungeonCurStageReq()
        end
        if _G.AppMain:HasDebug() then
          _G.NRCModuleManager:DoCmd(DebugModuleCmd.Tips_ShowZoneTip, zoneId)
        end
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.MainUIBlockByArea, zoneId)
      end
    else
      self:LogError("DoEnterZone no zoneId")
    end
  end
end

function AreaAndZoneModule:IsSafeZone()
  return self.isSaveZone
end

function AreaAndZoneModule:IsCave()
  return self.isCave
end

function AreaAndZoneModule:CanSetMessage()
  return self.CanMessage
end

function AreaAndZoneModule:OnMainUIOpen()
  local MainUIIsShow = _G.NRCModeManager:DoCmd(MainUIModuleCmd.MainUIIsShow)
  if not MainUIIsShow then
    return
  end
  self._isMainUIOpened = true
  if self._needShowTip then
    local playerZoneInfo = self:PlayPlaceName()
    self:DoEnterZone(playerZoneInfo)
    self._needShowTip = false
  end
  self:UpdateSafeZone()
  self:UpdateTemperature()
  self:UpdateAbnormal()
  self:UpdateCave()
end

function AreaAndZoneModule:PlayPlaceName()
  local playerZoneInfo
  for _, info in ipairs(self.zoneInfoArray:Items()) do
    if info.Conf.name and info.Conf.broadcast_type and info.Conf.broadcast_type ~= _G.Enum.AreaBroadcastType.ABT_NONE then
      if info.Conf.broadcast_type == Enum.AreaBroadcastType.ABT_ACTIVITY then
        if self:CheckShowActivityNameByNPCAndId(info.Conf.id) then
          playerZoneInfo = info.Conf
          self.action = info
          break
        end
      else
        playerZoneInfo = info.Conf
        self.action = info
        break
      end
    end
  end
  return playerZoneInfo
end

function AreaAndZoneModule:CheckShowActivityName(funcId)
  local worldMapActivityConf = NRCModuleManager:DoCmd(BigMapModuleCmd.GetWorldMapActivityConfByAreaFuncId, funcId)
  if worldMapActivityConf then
    local npcInfo = NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcDataByWorldMapConfId, worldMapActivityConf.world_map_id)
    if npcInfo then
      return true
    end
  end
  return false
end

function AreaAndZoneModule:CheckShowActivityNameByNPCAndId(funcId)
  local hasNpc = false
  local hasActivity = false
  local worldMapActivityConf = NRCModuleManager:DoCmd(BigMapModuleCmd.GetWorldMapActivityConfByAreaFuncId, funcId)
  if worldMapActivityConf then
    local npcInfo = NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcDataByWorldMapConfId, worldMapActivityConf.world_map_id)
    if npcInfo then
      hasNpc = true
    end
  end
  local activityId = worldMapActivityConf.activity_id
  if activityId and activityId > 0 then
    local activityInst = NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstById, activityId, true)
    if activityInst then
      hasActivity = true
    end
  else
    local timeStamp = ActivityUtils.GetSvrTimestamp()
    local timeDetailData = ActivityUtils.ToTimeDetailData(timeStamp)
    if timeDetailData.hour >= self.nightActivityStartTime or timeDetailData.hour < self.nightActivityEndTime then
      hasActivity = true
    end
  end
  if hasNpc and hasActivity then
    return true
  end
  return false
end

function AreaAndZoneModule:OnMainUIClose()
  self.Log("OnMainUIClose")
  self._isMainUIOpened = false
end

function AreaAndZoneModule:GetPlayerZoneInfo()
  return self.playerZoneInfo
end

function AreaAndZoneModule:GetPlayerZoneArray()
  return self.zoneInfoArray
end

function AreaAndZoneModule:IfPlayerInArea(InterAreaId)
  if type(InterAreaId) == "table" then
    local HashTable = {}
    for _, AreaId in ipairs(InterAreaId) do
      HashTable[AreaId] = true
    end
    for i, AreaId in ipairs(self.playerZoneInfo.area_id) do
      if HashTable[AreaId] then
        return true
      end
    end
    return false
  end
  for i, AreaId in ipairs(self.playerZoneInfo.area_id) do
    if AreaId == InterAreaId then
      return true
    end
  end
  return false
end

function AreaAndZoneModule:IfPlayerInInterArea()
  if not self.playerZoneInfo then
    return false
  end
  local scene_effect = self.playerZoneInfo.scene_effect
  for _, effect in ipairs(scene_effect) do
    if effect.effect_type == Enum.SceneEffect.SE_INTER_AREA then
      return true
    end
  end
  return false
end

function AreaAndZoneModule:OnZoneChange()
end

function AreaAndZoneModule:LoadBank()
  return _G.NRCAudioManager:LoadBankByName("BGM")
end

function AreaAndZoneModule:UnLoadBank(id)
  _G.NRCAudioManager:ReleaseSession(id, false, "AreaAndZoneModule")
end

function AreaAndZoneModule:OnAreaChange(areaId, bEnter)
  self:Log("OnAreaChange", areaId, bEnter)
  self:UpdateSafeZone()
  self:UpdateTemperature()
  self:UpdateAbnormal()
  self:UpdateCave()
end

function AreaAndZoneModule:DumpBGMArea()
  Log.Error("Current Area BGM Data:", table.tostring(self.bgmAreaStack.ZoneInfoArray:Items()))
  Log.Error("Current Area BGM Data:", table.tostring(self.ambAreaStack.ZoneInfoArray:Items()))
end

function AreaAndZoneModule:UpdateAmb()
  local ambData = self.ambAreaStack:GetFirstItem()
  if nil == ambData then
    return
  end
  local area_func_id = ambData.area_func_id
  local area_func_conf = _G.DataConfigManager:GetAreaFuncConf(area_func_id)
  local amb_switch = area_func_conf.amb_switch
  _G.NRCAudioManager:SetGlobalSwitch("Amb_2D", amb_switch)
  local event_map = {}
  for i, info in ipairs(self.ambAreaStack:GetAreaArray():Items()) do
    area_func_conf = _G.DataConfigManager:GetAreaFuncConf(info.area_func_id)
    local amb_events = area_func_conf.amb_events
    if amb_events then
      local event_array = string.split(amb_events, ";")
      for _, event in ipairs(event_array) do
        if not table.contains(self.amb_area_session_map, event) then
          self.amb_area_session_map[event] = _G.NRCAudioManager:PlaySound2DAuto(tonumber(event))
          Log.Debug("UpdateAmb Play Sound 2D: ", tonumber(event), amb_events, event, self.amb_area_session_map[event])
        end
        event_map[event] = true
      end
    end
  end
  local remove_event = {}
  for key, value in pairs(self.amb_area_session_map) do
    if not event_map[key] then
      remove_event[key] = true
    end
  end
  for key, value in pairs(remove_event) do
    if self.amb_area_session_map[key] then
      Log.Debug("UpdateAmb Stop Sound 2D: ", key, self.amb_area_session_map[key])
      _G.NRCAudioManager:ReleaseSession(self.amb_area_session_map[key], true)
      self.amb_area_session_map[key] = nil
    end
  end
end

function AreaAndZoneModule:UpdateAreaBgm(bEnter)
  local bgmData = self.bgmAreaStack:GetFirstItem()
  if nil == bgmData then
    return
  end
  local areaId = bgmData.area_func_id
  if bEnter then
    local data = _G.DataConfigManager:GetAreaFuncConf(areaId)
    self.bgmStateGroup = data.switch_group_name
    self.areaId = areaId
    self.currentTimeState = ""
    local currentTime = _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.GetCurrentTime)
    self:UpdateTOD(data.area_bgm, currentTime)
    if -1 == self.bgmSessionId then
      self.bgmSessionId = _G.NRCAudioManager:PlaySound2DAuto(9031, "AreaAndZoneModule:OnAreaChange")
      Log.Debug("Play BGM: ", self.bgmSessionId)
      _G.NRCAudioManager:AddSessionFinishCallback(self.bgmSessionId, self, self.OnBgmEnd)
      _G.NRCAudioManager:SetStateByName("Alive_Death", "Alive", "ActiveBGM")
      _G.NRCAudioManager:SetStateByName("Scene", "Scene", "AreaAndZoneModule:OnAreaChange")
    end
    if -1 == self.ambSessionId then
      self.ambSessionId = _G.NRCAudioManager:PlaySound2DAuto(41600101, "")
      _G.NRCAudioManager:AddSessionFinishCallback(self.ambSessionId, self, self.OnAmbEnd)
      Log.Debug("Play BGM: ", self.ambSessionId)
    end
    self.envSession:Play()
    self.current_bgm_area = data.bgm_area_state
    if self.current_bgm_area then
      local current_bgm_key_list = string.split(self.current_bgm_area, ";")
      if #current_bgm_key_list > 1 then
        local region_name = current_bgm_key_list[1]
        _G.NRCAudioManager:BatchSetState(string.format("Area;%s;%s", region_name, self.current_bgm_area))
      end
    end
    self:RegisterNotify(data)
  else
  end
end

function AreaAndZoneModule:OnBgmEnd()
  Log.Debug("BGM\232\162\171\229\185\178\230\142\137\228\186\134\227\128\130\227\128\130\227\128\130\233\135\141\229\144\175\228\184\128\228\184\139\229\144\167")
  self.bgmSessionId = _G.NRCAudioManager:PlaySound2DAuto(9031, "AreaAndZoneModule:OnAreaChange")
  _G.NRCAudioManager:AddSessionFinishCallback(self.bgmSessionId, self, self.OnBgmEnd)
end

function AreaAndZoneModule:OnAmbEnd()
  Log.Error("\231\187\157\228\186\134\227\128\130\227\128\130\227\128\130Amb\228\184\186\229\149\165\232\131\189\232\162\171\229\185\178\230\142\137\229\149\138\227\128\130\227\128\130\227\128\130")
end

function AreaAndZoneModule:UpdateTOD(area_bgm, currentTime)
  self:Log("UpdateTOD", currentTime)
  for i, item in ipairs(area_bgm) do
    if currentTime and item.start_time and item.end_time and type(currentTime) == type(item.start_time) and type(currentTime) == type(item.end_time) then
      if currentTime > item.start_time and currentTime < item.end_time or item.end_time < item.start_time and currentTime > item.start_time or currentTime < item.end_time and item.end_time < item.start_time then
        self:Log("get time span", item.start_time, item.end_time, currentTime)
        self:SetBGMTODState(item.switch)
        break
      end
    else
      Log.Error("AreaAndZoneModule\228\184\186\229\149\165\230\139\191\229\136\176\228\186\134\230\156\137\233\151\174\233\162\152\231\154\132\230\151\182\233\151\180\229\149\138\239\188\140\232\191\153\229\144\136\231\144\134\229\144\151\239\188\140\230\152\175\228\184\141\230\152\175\231\173\150\229\136\146\233\133\141\231\189\174\233\148\153\228\186\134\229\149\138\239\188\129\239\188\129\239\188\129", currentTime, item.start_time, item.end_time, "\230\156\137\233\151\174\233\162\152\231\154\132id\230\152\175", item.id)
    end
  end
end

function AreaAndZoneModule:RegisterNotify(data)
  self:Log("RegisterNotify")
  if self.areaBgm:IsEmpty() then
  elseif self.areaBgm:Size() == #data.area_bgm and self:CompareAreaBgm(self.areaBgm:Items(), data.area_bgm) then
    self:Log("RegisterNotify same area bgm")
    self:UpdateAreaBgmItem(data.area_bgm)
    return
  else
    self:Log("RegisterNotify update area bgm")
    self:ClearAreaBgm()
  end
  self:RegisterNotifies(data.area_bgm)
end

function AreaAndZoneModule:RegisterNotifies(area_bgm)
  for i, item in ipairs(area_bgm) do
    local req = _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.RegisterTimeCallback, AreaAndZoneModuleCmd.OnTimeChange, item.start_time, true)
    if type(req) == "table" then
      self.areaBgm:Push({item = item, req = req})
      self:Log("AreaAndZoneModule:RegisterNotify", req.tokenId, req.callbackTime / 3600, item.switch)
    else
      Log.Error("\228\184\186\228\187\128\228\185\136\229\149\138\227\128\130\227\128\130\227\128\130\229\136\176\229\186\149\232\176\129\230\152\175magic_wood_memory\229\149\138\239\188\140\230\177\130\230\177\130\228\189\160\231\156\139\229\136\176\232\191\153\228\184\170\230\138\165\233\148\153\228\185\139\229\144\142\230\137\190marvynwang\233\151\174\233\151\174\229\144\167\239\188\140\232\191\153\229\164\170\229\165\135\230\128\170\228\186\134\227\128\130\227\128\130\227\128\130")
    end
  end
end

function AreaAndZoneModule:CompareAreaBgm(AreaBgm1, AreaBgm2)
  for i, item in ipairs(AreaBgm1) do
    if item.item.start_time ~= AreaBgm2[i].start_time or item.item.end_time ~= AreaBgm2[i].end_time then
      return false
    end
  end
  return true
end

function AreaAndZoneModule:UpdateAreaBgmItem(AreaBgm)
  for i, item in ipairs(self.areaBgm:Items()) do
    item.item = AreaBgm[i]
  end
end

function AreaAndZoneModule:ClearAreaBgm()
  for i, item in ipairs(self.areaBgm:Items()) do
    _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.UnRegisterTimeCallback, item.req)
  end
  self.areaBgm:Clear()
end

function AreaAndZoneModule:OnTimeChange(req)
  self:Log("OnTimeChange", req.bLoop, req.tokenId, req.callbackTime / 3600)
  for i, item in ipairs(self.areaBgm:Items()) do
    if item.req == req then
      self:SetBGMTODState(item.item.switch)
      return
    end
  end
end

function AreaAndZoneModule:SetBGMTODState(newState)
  if self.currentTimeState ~= newState then
    self.currentTimeState = newState
    self:Log("SetBGMTODState", self.bgmStateGroup, self.currentTimeState, newState)
    UE4.UAudioManager.SetStateByName(self.bgmStateGroup, self.currentTimeState, "AreaAndZoneModule:SetBGMTODSwitch")
  end
end

function AreaAndZoneModule:OnTimeGoBack(newTime)
  if not self.areaId then
    return
  end
  if 0 == self.areaId then
    return
  end
  local data = _G.DataConfigManager:GetAreaFuncConf(self.areaId)
  self:UpdateTOD(data.area_bgm, newTime)
  for i, item in ipairs(self.areaBgm:Items()) do
    _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.UnRegisterTimeCallback, item.req)
    local req = _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.RegisterTimeCallback, AreaAndZoneModuleCmd.OnTimeChange, item.item.start_time, true)
    item.req = req
  end
end

function AreaAndZoneModule:SendGetDungeonCurStageReq()
  local req = _G.ProtoMessage:newZoneGmGetDungeonCurStageReq()
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrGmCmd.ZONE_GM_GET_DUNGEON_CUR_STAGE_REQ, req)
end

function AreaAndZoneModule:PlayStarlightG6()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.viewObj then
    local caster = player.viewObj
    local skillComponent = caster.RocoSkill
    if skillComponent then
      local skillProxy = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/Activities/G6_Activities_guaji.G6_Activities_guaji", skillComponent)
      if skillProxy then
        skillProxy:SetCaster(caster)
        skillProxy:SetPassive(true)
        skillProxy:PlaySkill()
      end
    end
  end
end

function AreaAndZoneModule:IsActivityDrop(area_func_id)
  local activityObjects = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_DROP, true)
  if activityObjects then
    for _, dropObject in ipairs(activityObjects) do
      local dropConf = _G.DataConfigManager:GetActivityDropConf(dropObject:GetSinglePartId())
      local drop_id = dropConf.drop_id
      for _, id in ipairs(drop_id) do
        local activityDropMethodConf = _G.DataConfigManager:GetActivityDropMethodConf(id)
        if activityDropMethodConf.area_show == _G.Enum.AcitivityDropAreaShow.ADAS_STAR then
          local activity_area_id = activityDropMethodConf.world_map_activity_conf_id
          local worldMapActivityConf = _G.DataConfigManager:GetWorldMapActivityConf(activity_area_id, true)
          if worldMapActivityConf and area_func_id == worldMapActivityConf.area_func_id then
            local curTime = ActivityUtils.GetSvrTimestamp()
            local starTime = ActivityUtils.ToTimestamp(activityDropMethodConf.begin_time)
            local endTime = ActivityUtils.ToTimestamp(activityDropMethodConf.end_time)
            if curTime >= starTime and curTime < endTime then
              local daily_get = dropObject:GetAlreadyGetNum()
              if daily_get < dropConf.day_got_limit then
                return true
              end
            end
          end
        end
      end
    end
  end
  return false
end

function AreaAndZoneModule:OnFuncAreaUpdate(area_func_id, bCreate)
  if bCreate then
    if not self.starlightTimer and self.zoneInfoArray then
      for _, area in ipairs(self.zoneInfoArray:Items()) do
        if area.Conf.id == area_func_id and self:IsActivityDrop(area_func_id) then
          self:CreateStarlightTimer(area_func_id)
          break
        end
      end
    end
  elseif area_func_id == self.dropAreaFuncId then
    self:ClearStarlightTimer()
  end
end

function AreaAndZoneModule:CreateStarlightTimer(area_func_id)
  if not self.starlightTimer then
    self.starlightTimer = _G.TimerManager:CreateTimer(self, "PlayStarlight", 86400, self.PlayStarlightG6, nil, 10)
    self.dropAreaFuncId = area_func_id
  end
end

function AreaAndZoneModule:ClearStarlightTimer()
  if self.starlightTimer then
    _G.TimerManager:RemoveTimer(self.starlightTimer)
    self.starlightTimer = nil
    self.dropAreaFuncId = nil
  end
end

function AreaAndZoneModule:CheckStarPlay()
  if not self.starlightTimer and self.zoneInfoArray then
    Log.Debug("\232\191\155\229\133\165CheckStarPlay\229\136\164\230\150\173\230\152\175\229\144\166\231\153\187\229\189\149\229\188\128\229\144\175\231\137\185\230\149\136")
    for _, area in ipairs(self.zoneInfoArray:Items()) do
      if self:IsActivityDrop(area.Conf.id) then
        self:CreateStarlightTimer(area.Conf.id)
        break
      end
    end
  end
end

function AreaAndZoneModule:CheckRolePlayPropsIsBan(propId)
  if self.AbilityBanManager then
    return self.AbilityBanManager:GetRolePlayPropsIsBan(propId)
  end
  return false
end

function AreaAndZoneModule:GetAbilityBanManager()
  return self.AbilityBanManager
end

function AreaAndZoneModule:GetCurrentAreaFuncId()
  if self.bgmAreaStack and self.bgmAreaStack.ZoneInfoArray then
    local firstItem = self.bgmAreaStack:GetFirstItem()
    return firstItem and firstItem.area_func_id
  end
  return nil
end

function AreaAndZoneModule:OnActivityMapNpcDataChanged(npcInfo)
  local worldMapConfId = npcInfo.world_map_cfg_id
  self:PlayActivityAreaName()
end

function AreaAndZoneModule:OnActivityObjectsUpdateFinish()
  if self.activityInfoInitialized == false then
    self:PlayActivityAreaName()
    self.activityInfoInitialized = true
  end
end

function AreaAndZoneModule:OnActivitySvrStateChanged()
end

function AreaAndZoneModule:PlayActivityAreaName()
end

return AreaAndZoneModule

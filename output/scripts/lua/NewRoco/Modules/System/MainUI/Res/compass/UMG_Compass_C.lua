local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local CompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.CompassUIData")
local NPCCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.NPCCompassUIData")
local AreaCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.AreaCompassUIData")
local MarkCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.MarkCompassUIData")
local TaskCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.TaskCompassUIData")
local VisitCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.VisitCompassUIData")
local PetSenseCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.PetSenseCompassUIData")
local CatchePetCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.CatchePetCompassUIData")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local AcceptableTaskCompassUIData = require("NewRoco.Modules.System.MainUI.Res.compass.AcceptableTaskCompassUIData")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local UMG_Compass_C = _G.NRCPanelBase:Extend("UMG_Compass_C")
local math_abs = math.abs
local tInsert = table.insert
UMG_Compass_C.State = {
  NORMAL = 1,
  LEAKAGE = 2,
  HIDE = 3,
  PERCEIVE = 4
}
UMG_Compass_C.HideState = {
  Normal = 1,
  Hidden = 2,
  Hidden_Exposed = 3,
  Hidden_Attacked = 4
}

function UMG_Compass_C.ConvertMinimapOrCompassStateToHideState(minimapOrCompassState)
  if minimapOrCompassState == MainUIModuleEnum.MinimapOrCompassState.Hidden then
    return UMG_Compass_C.HideState.Hidden
  elseif minimapOrCompassState == MainUIModuleEnum.MinimapOrCompassState.Hidden_Exposed then
    return UMG_Compass_C.HideState.Hidden_Exposed
  elseif minimapOrCompassState == MainUIModuleEnum.MinimapOrCompassState.Hidden_Attacked then
    return UMG_Compass_C.HideState.Hidden_Attacked
  end
  return UMG_Compass_C.HideState.Normal
end

UMG_Compass_C.UpdateType = {
  UpdateHeroPos = 1,
  UpdateCameraDir = 2,
  UpdateShowDistance = 3,
  Max = 4
}
UMG_Compass_C.OptimizeMode = {
  None = 1,
  EnableMainOptimize = 2,
  EnableSubOptimize = 3,
  Max = 4
}
local log2 = math.log(2)
local DisLayerUpdateNum = 0
local UpdateNpcDataNumPerFrame = 1
local UpdateMapAreaDataNumPerFrame = 20
local CacheNpcUpdateVersion = 0
local CacheMapAreaUpdateVersion = 0

function UMG_Compass_C:OnConstruct()
  self.DistanceInZ = UMG_Compass_C.DistanceInZ
  self.DistanceSquareInXY = UMG_Compass_C.DistanceSquareInXY
  self.ComputeUIItemShow = UMG_Compass_C.ComputeUIItemShow
  self.CompassParts = {}
  self.EnableDistanceItem = {}
  self.willChangeItems = {}
  self.WorldMap2SceneId = {}
  self.WorldMap2SceneResId = {}
  self.CurShowNpcKeys = {}
  self.CurShowAreaKeys = {}
  self.NpcIcons = {}
  self.MarkIcons = {}
  self.TaskIcons = {}
  self.AcceptableTaskIcons = {}
  self.AcceptableTaskDisLevelKeys = {}
  self.VisitIcons = {}
  self.PetSensing = {}
  self.MapAreaIcons = {}
  self.CompItemCircle = {}
  self.RightMiniAngleItems = {}
  self.SpecialAngleItems = {}
  self.OrderItems = {}
  self.LeftMiniAngleItems = {}
  self.DistanceLevelInitPos = {}
  self.NpcDisLeveKeys = {}
  self.MoveNpcDisLeveKey = {}
  self.MapAreaIcons = {}
  self.MapAreaDisLeveKeys = {}
  self.MarkDisLeveKeys = {}
  self.CompassCatchPetIcon = nil
  self.LayerUpdatePerTick = 5
  self.DisUpdatePerTick = 3
  self.DetectLimitH = {}
  self.DetectLimitH.h_drange_a = self:GetSquare(_G.DataConfigManager:GetMapGlobalConfig("h_drange_a").num)
  self.DetectLimitH.h_drange_b = self:GetSquare(_G.DataConfigManager:GetMapGlobalConfig("h_drange_b").num)
  self.DetectLimitH.h_drange_c = self:GetSquare(_G.DataConfigManager:GetMapGlobalConfig("h_drange_c").num)
  self.DetectLimitV = {}
  self.DetectLimitV.v_drange_a = _G.DataConfigManager:GetMapGlobalConfig("v_drange_a").num
  self.DetectLimitV.v_drange_b = _G.DataConfigManager:GetMapGlobalConfig("v_drange_b").num
  self.DetectLimitV.v_drange_c = _G.DataConfigManager:GetMapGlobalConfig("v_drange_c").num
  self.ShowDisDistance = self:GetSquare(_G.DataConfigManager:GetMapGlobalConfig("compass_show_distance_detection").num)
  self.ShowDisAngle = _G.DataConfigManager:GetMapGlobalConfig("compass_show_distance_angle").num
  self.NPCRefreshConfig = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_REFRESH_BONUS_CONF):GetAllDatas()
  self.ZeroVector = UE4.FVector(0, 0, 0)
  self.UpVector = UE4.FVector(0, 0, 1)
  self.NowHeroPos = self.ZeroVector
  self.NorthVector = UE4.FVector(0, -1, 0)
  self:SetForceUpdatePos(true)
  self.IsForceUpdateDir = false
  self.IsShow = true
  self.IsEnable = true
  self.bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  self.bigMapModuleData = self.bigMapModule and self.bigMapModule.data or nil
  self.ViewField = _G.DataConfigManager:GetMapGlobalConfig("detection_angle").num
  self.SizeChangeDis = _G.DataConfigManager:GetMapGlobalConfig("icon_size").num
  self.SizeChangeDisSquare = self.SizeChangeDis * self.SizeChangeDis
  self.ShowHighAngle = _G.DataConfigManager:GetMapGlobalConfig("high_divide_angle").num
  self.ShowHighDis = self:GetSquare(_G.DataConfigManager:GetMapGlobalConfig("min_divide_range").num)
  self.AngleConvertString = {
    LuaText.umg_compass_1,
    LuaText.umg_compass_2,
    LuaText.umg_compass_3,
    LuaText.umg_compass_4
  }
  self.AngleLength = 90
  self.SpacePerAngle = self.CompassRoot.Slot:GetOffsets().Right / (self.ViewField * 2)
  self.TaskDistance = _G.DataConfigManager:GetMapGlobalConfig("task_distance").num
  self.IsUpdateTraceInfo = true
  self.bTaskClicked = false
  self.compassTraceInfo = {}
  self.limitNumTrackTypeToListMap = {}
  self.limitNumTrackTypeToMapIndexMap = {}
  self.forceTrackTypeMap = {}
  self.limitNumTrackTypeSortDirtyMap = {}
  self.limitNumTrackTypeSortedMap = {}
  self._defaultTrackNpcDataChangePending = false
  self.mapDefaultTrackConfCache = {}
  self:InitMapDefaultTrackConfCache()
  self.vector2DZero = UE4.FVector2D(0, 0)
  self.Deviation = {X = 70, Y = 60}
  self.screenPos = nil
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 1000
  self.EndTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn").num / 1000
  self.IconScale = _G.DataConfigManager:GetMapGlobalConfig("main_compass_icon_resource_scale").num / 10000
  self:GetWorldMapData()
  for i = 1, 4 do
    self.CompassParts[i] = self:CreateCompassPartWidget(i)
  end
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, SceneEvent.LoadMapStart, self.LoadMapStart)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, SceneEvent.PlayerBornFinish, self.OnMapLoaded)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, TaskModuleEvent.TASK_DATA_CHANGE, self.UpdateTraceTask)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, MainUIModuleEvent.OnPlayCompassAnimation, self.OnPlayCompassAnimation)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, SceneEvent.PlayerTeleportFinish, self.PlayerTeleportFinish)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, BigMapModuleEvent.OnTraceNpcDataChanged, self.OnTraceNpcDataChanged)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, BigMapModuleEvent.AcceptTaskRefresh, self.UpdateAcceptableTaskData)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, BigMapModuleEvent.TraceAcceptTaskRefresh, self.OnTraceAcceptTaskRefresh)
  NRCEventCenter:RegisterEvent("UMG_Compass_C", self, BigMapModuleEvent.DefaultTrackNpcChange, self.OnDefaultTrackTypeNpcDataChange)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.STORY_FLAG_ADDED, self.OnStoryFlagAdded)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  self:OnNavigationModeUpdate(_G.DataModelMgr.PlayerDataModel:GetNavigationMode(), true)
  self:OnMapLoaded()
  self.ShowDisItem = false
  self.EnableOptimizeMode = UMG_Compass_C.OptimizeMode.None
  self.CurrentUpdateStep = 0
end

function UMG_Compass_C:OnEnable()
  self.IsEnable = true
  self:SetForceUpdatePos(true)
  self.IsForceUpdateDir = true
end

function UMG_Compass_C:OnDisable()
  self.IsEnable = false
end

function UMG_Compass_C:Hide()
  self.IsShow = false
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Compass_C:Show(mode)
  if self.NavigationMode ~= ProtoEnum.NavigationModeType.NMT_COMPASS and self.CurCompassState == UMG_Compass_C.State.NORMAL then
    return
  end
  self.IsShow = true
  self:SetForceUpdatePos(true)
  self.IsForceUpdateDir = true
  self:UpdateUIBan(mode)
end

function UMG_Compass_C:UpdateUIBan(mode)
  if self.IsShow then
    if self.CurCompassState == UMG_Compass_C.State.NORMAL then
      local NavigationMode = mode or _G.DataModelMgr.PlayerDataModel:GetNavigationMode()
      local isHide = NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAP_TOP) or not NavigationMode or NavigationMode ~= ProtoEnum.NavigationModeType.NMT_COMPASS
      if isHide then
        self.SneakTop:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.SneakRound:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateSneak()
      end
    else
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:UpdateSneak()
    end
  end
end

function UMG_Compass_C:UpdateSneak()
  if self.CurCompassState == UMG_Compass_C.State.HIDE then
    self.SneakTop:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SneakRound:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Compass_C:LoadMapStart()
  self.PlayerCameraManager = nil
  self.LocalPlayer = nil
end

function UMG_Compass_C:SetForceUpdatePos(value)
  self.IsForceUpdatePos = value
  if not value then
    self.ForceUpdateFrame = self.ForceUpdateFrame - 1
  end
end

function UMG_Compass_C:GetUpdateFrameCount(DisLeveKeys)
  local frame = 0
  for k, v in pairs(DisLeveKeys or {}) do
    if k < 0 then
      frame = math.max(1, frame)
    else
      frame = math.max(math.ceil(v.ItemNumber / self.LayerUpdatePerTick), frame)
    end
  end
  return frame
end

function UMG_Compass_C:ChangeCompassState(state, childState)
  local convertedChildState = UMG_Compass_C.ConvertMinimapOrCompassStateToHideState(childState)
  if self.CurCompassState ~= state then
    if state == UMG_Compass_C.State.NORMAL then
      self.NpcLayer:SetRenderOpacity(1)
      self.TraceNpcLayer:SetRenderOpacity(1)
      self.TaskLayer:SetRenderOpacity(1)
      self:StopAnimation(self.Eye_In)
      self:PlayAnimation(self.Eye_Out)
      self.Compass_Sneak:ChangeTo(state)
      self:SetForceUpdatePos(true)
    else
      self.NpcLayer:SetRenderOpacity(0)
      self.TraceNpcLayer:SetRenderOpacity(0)
      self.TaskLayer:SetRenderOpacity(0)
      self:StopAnimation(self.Eye_Out)
      self:PlayAnimation(self.Eye_In)
      self.Compass_Sneak:ChangeTo(state, convertedChildState)
      if state == UMG_Compass_C.State.HIDE then
        self:StopAnimation(self.Mas_kOut)
        self:PlayAnimation(self.Mask_In)
      end
    end
    if self.CurCompassState == UMG_Compass_C.State.HIDE then
      self:StopAnimation(self.Mask_In)
      self:PlayAnimation(self.Mas_kOut)
    end
    self.CurCompassState = state
    if state == UMG_Compass_C.State.NORMAL then
      local PreNavigationMode = self.NavigationMode
      self.NavigationMode = nil
      self:OnNavigationModeUpdate(PreNavigationMode)
    elseif self.NavigationMode == ProtoEnum.NavigationModeType.NMT_COMPASS then
      self:Show()
    end
  elseif nil ~= convertedChildState then
    self.Compass_Sneak:ChangeTo(state, convertedChildState)
  end
end

function UMG_Compass_C:OnAnimationFinished(Animation)
  if Animation == self.Eye_Out then
    self.Compass_Sneak:SetRenderOpacity(0)
  elseif Animation == self.Eye_In then
    self.Compass_Sneak:SetRenderOpacity(1)
  end
end

function UMG_Compass_C:OnMapLoaded()
  self.PlayerCameraManager = self:GetOwningPlayerCameraManager()
  self.LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:ChangeCompassState(self.CurCompassState or UMG_Compass_C.State.NORMAL)
  self.CurSceneID = SceneUtils.GetSceneID() or 103
  self.CurSceneResID = SceneUtils.GetSceneResId()
  if 103 ~= self.CurSceneID then
    self:UpdateMarkInfo()
  end
  self:UpdateVisitIcons()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetCompassUpdateTrace, true)
end

function UMG_Compass_C:GetWorldMapData()
end

function UMG_Compass_C:GetWorldMapById(id)
  return _G.DataConfigManager:GetWorldMapConf(id, true)
end

function UMG_Compass_C:GetWorldMapByConfId(confId)
  return _G.DataConfigManager:GetWorldMapConf(confId, true)
end

function UMG_Compass_C:GetSquare(num)
  return num * num
end

function UMG_Compass_C:GetGetBelongSceneIdByNpcRefresh(npcRefreshId)
  local sceneId = 103
  local npc_refresh = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshId)
  if npc_refresh then
    local refresh_param = npc_refresh.refresh_param or 0
    if npc_refresh.refresh_type == Enum.RefreshType.RFT_AREA then
      local area_conf = _G.DataConfigManager:GetAreaConf(refresh_param, true)
      if area_conf then
        sceneId = area_conf.scene_id or sceneId
      end
    elseif npc_refresh.refresh_type == Enum.RefreshType.RFT_NPC or npc_refresh.refresh_type == Enum.RefreshType.RFT_RELY then
      sceneId = self:GetGetBelongSceneIdByNpcRefresh(refresh_param)
    elseif npc_refresh.refresh_type == Enum.RefreshType.RFT_BYTAGID or npc_refresh.refresh_type == Enum.RefreshType.RFT_BYTAG then
      local scene_conf = _G.DataConfigManager:GetSceneObjectConf(refresh_param, true)
      if scene_conf then
        sceneId = scene_conf.scene_cfg_id or sceneId
      end
    else
      sceneId = npc_refresh.refresh_type == Enum.RefreshType.RFT_BONUS and SceneUtils.GetSceneID() or sceneId
    end
  end
  return sceneId
end

function UMG_Compass_C:GetGetBelongSceneResIdByNpcRefresh(npcRefreshId, npcInfo)
  local sceneId = 10003
  local npc_refresh = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshId)
  if npc_refresh then
    local refresh_param = npc_refresh.refresh_param or 0
    if npc_refresh.refresh_type == Enum.RefreshType.RFT_AREA then
      local area_conf = _G.DataConfigManager:GetAreaConf(refresh_param, true)
      if area_conf then
        sceneId = area_conf.scene_res_id or sceneId
      end
    elseif npc_refresh.refresh_type == Enum.RefreshType.RFT_NPC or npc_refresh.refresh_type == Enum.RefreshType.RFT_RELY then
      sceneId = self:GetGetBelongSceneResIdByNpcRefresh(refresh_param)
    elseif npc_refresh.refresh_type == Enum.RefreshType.RFT_BYTAGID or npc_refresh.refresh_type == Enum.RefreshType.RFT_BYTAG then
      local scene_conf = _G.DataConfigManager:GetSceneObjectConf(refresh_param, true)
      if scene_conf then
        sceneId = BigMapUtils.GetSceneResIdByPos(scene_conf.position_xyz[1], scene_conf.position_xyz[2])
      end
    elseif npc_refresh.refresh_type == Enum.RefreshType.RFT_BONUS then
      sceneId = SceneUtils.GetSceneResId() or sceneId
    elseif npcInfo and npcInfo.npc_pos then
      sceneId = BigMapUtils.GetSceneResIdByPos(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
    end
  end
  return sceneId
end

function UMG_Compass_C:GetBelongSceneId(worldMap)
  if self.WorldMap2SceneId[worldMap.id] then
    return self.WorldMap2SceneId[worldMap.id]
  end
  local sceneId = 103
  if worldMap.npc_refresh_ids and #worldMap.npc_refresh_ids > 0 then
    local npc_refresh_id = worldMap.npc_refresh_ids[1]
    sceneId = self:GetGetBelongSceneIdByNpcRefresh(npc_refresh_id)
  elseif worldMap.name_area_id and worldMap.name_area_id > 0 then
    local area_conf = _G.DataConfigManager:GetAreaConf(worldMap.name_area_id, true)
    if area_conf then
      sceneId = area_conf.scene_id or 103
    end
  end
  self.WorldMap2SceneId[worldMap.id] = sceneId
  return sceneId
end

function UMG_Compass_C:GetBelongSceneResId(worldMap)
  if self.WorldMap2SceneResId[worldMap.id] then
    return self.WorldMap2SceneResId[worldMap.id]
  end
  local sceneId = 10003
  if worldMap.npc_refresh_ids and #worldMap.npc_refresh_ids > 0 then
    local npc_refresh_id = worldMap.npc_refresh_ids[1]
    sceneId = self:GetGetBelongSceneResIdByNpcRefresh(npc_refresh_id)
  elseif worldMap.name_area_id and worldMap.name_area_id > 0 then
    local area_conf = _G.DataConfigManager:GetAreaConf(worldMap.name_area_id, true)
    if area_conf then
      sceneId = area_conf.scene_res_id or 10003
    end
  end
  self.WorldMap2SceneResId[worldMap.id] = sceneId
  return sceneId
end

function UMG_Compass_C:IsShowNpc(compassData, worldMap, isManualTracing)
  local model
  if compassData and compassData.NpcConfig then
    model = _G.DataConfigManager:GetModelConf(compassData.NpcConfig.model_conf, true)
  end
  if compassData and worldMap then
    if worldMap.is_hide_init then
      if isManualTracing then
        return true
      else
        return false
      end
    end
    if compassData.IsUnLock then
      if worldMap.dungeon_id and worldMap.dungeon_id > 0 then
        if compassData.IsFinish then
          return 1 == worldMap.explored_in_compass and (worldMap.npcicon_unlock or model and model.ui_icon)
        else
          return 1 == worldMap.unfinished_in_compass and (worldMap.npcicon_unfinished or model and model.ui_icon)
        end
      elseif worldMap.storyflag_id and worldMap.storyflag_id > 0 then
        if _G.DataModelMgr.PlayerDataModel:HasStoryFlag(worldMap.storyflag_id) then
          return 1 == worldMap.explored_in_compass and (worldMap.npcicon_unlock or model and model.ui_icon)
        end
      else
        return 1 == worldMap.explored_in_compass and (worldMap.npcicon_unlock or model and model.ui_icon)
      end
    else
      return 1 == worldMap.unexplored_in_compass and (worldMap.npcicon_lock or model and model.ui_icon)
    end
  end
  return false
end

function UMG_Compass_C:IsShowMapArea(compassData, worldMap, ignoreHideInit)
  if compassData and worldMap then
    if not ignoreHideInit and worldMap.is_hide_init then
      return false
    end
    if compassData.IsUnLock then
      return 1 == worldMap.explored_in_compass and worldMap.areaicon_explore
    else
      return 1 == worldMap.unexplored_in_compass and worldMap.areaicon_unexplore
    end
  end
  return false
end

function UMG_Compass_C:PreUpdateNpcInfo(npcInfos)
  if not self.NpcUpdateCommon then
    self.NpcUpdateCommon = {}
    self.NpcUpdateCommon.CurUpdateVersion = CacheNpcUpdateVersion
  end
  self.NpcUpdateCommon.RemoveIds = {}
  self.NpcUpdateCommon.CurUpdateKey = nil
  self.NpcUpdateCommon.Data = npcInfos or {}
  self.NpcUpdateCommon.IsValueChange = false
  self.NpcUpdateCommon.NeedUpdateCount = UpdateNpcDataNumPerFrame
  self.NpcUpdateCommon.CurUpdateVersion = self.NpcUpdateCommon.CurUpdateVersion + 1
  CacheNpcUpdateVersion = self.NpcUpdateCommon.CurUpdateVersion
end

function UMG_Compass_C:CheckBelongToSameSceneId(npcInfo)
  if not npcInfo then
    return false
  end
  local worldMap = self:GetWorldMapByConfId(npcInfo.world_map_cfg_id)
  if not worldMap then
    return false
  end
  if npcInfo.npc_src_refresh_content_id and npcInfo.npc_src_refresh_content_id > 0 then
    return self.CurSceneID == self:GetGetBelongSceneIdByNpcRefresh(npcInfo.npc_src_refresh_content_id) and self.CurSceneResID == self:GetGetBelongSceneResIdByNpcRefresh(npcInfo.npc_src_refresh_content_id, npcInfo)
  end
  if npcInfo.npc_refresh_id and npcInfo.npc_refresh_id > 0 then
    return self.CurSceneID == self:GetGetBelongSceneIdByNpcRefresh(npcInfo.npc_refresh_id) and self.CurSceneResID == self:GetGetBelongSceneResIdByNpcRefresh(npcInfo.npc_refresh_id, npcInfo)
  end
  if not (worldMap.npc_refresh_ids and not (#worldMap.npc_refresh_ids <= 0) and worldMap.name_area_id) or worldMap.name_area_id <= 0 then
    return true
  end
  return self.CurSceneID == self:GetBelongSceneId(worldMap) and self.CurSceneResID == self:GetBelongSceneResId(worldMap)
end

function UMG_Compass_C:UpdateNpcInfo()
  if not self.bigMapModuleData then
    Log.Warning("UMG_Compass_C:UpdateNpcInfo bigMapModuleData is nil")
    return
  end
  if not self.NpcUpdateCommon then
    return
  end
  local compassData = {}
  self.CurSceneID = SceneUtils.GetSceneID()
  self.CurSceneResID = SceneUtils.GetSceneResId()
  local serveTime = _G.ZoneServer:GetServerTime() / 1000
  local isPlayCatchSound = false
  while self.NpcUpdateCommon.NeedUpdateCount > 0 do
    local areaNps
    self.NpcUpdateCommon.CurUpdateKey, areaNps = next(self.NpcUpdateCommon.Data, self.NpcUpdateCommon.CurUpdateKey)
    if not self.NpcUpdateCommon.CurUpdateKey then
      break
    end
    self.NpcUpdateCommon.NeedUpdateCount = self.NpcUpdateCommon.NeedUpdateCount - 1
    for _entryId, npcInfoList in pairs(areaNps) do
      for keyLogicId, item in pairs(npcInfoList) do
        local npcInfo = item
        if (npcInfo.logic_id or npcInfo.world_map_cfg_id) and npcInfo.npcCfg then
          local logic_id = npcInfo.logic_id or npcInfo.world_map_cfg_id
          local worldMap = self:GetWorldMapByConfId(npcInfo.world_map_cfg_id)
          if not self:CheckBelongToSameSceneId(npcInfo) or npcInfo.next_npc_refresh_time and serveTime < npcInfo.next_npc_refresh_time then
          else
            self.NpcUpdateCommon.IsValueChange = true
            local showCathPet = self:IsShowCatchPet(npcInfo.npc_refresh_id)
            compassData.IsCathPetNpc = showCathPet
            compassData.Position = UE4.FVector(npcInfo.npc_pos.x, npcInfo.npc_pos.y, npcInfo.npc_pos.z)
            compassData.IsUnLock = npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH
            compassData.IsFinish = npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH
            compassData.NpcConfig = npcInfo.npcCfg
            compassData.IsOwlStarNpc = compassData.NpcConfig and compassData.NpcConfig.min_map_disappear and compassData.NpcConfig.min_map_disappear > 0
            compassData.NPC_Level = npcInfo.npc_level
            compassData.Id = logic_id
            compassData.LogicId = logic_id
            compassData.petInfo = npcInfo.petInfo
            compassData.glass_info = npcInfo.glass_info
            compassData.mutation_type = npcInfo.mutation_type
            compassData.npc_refresh_id = npcInfo.npc_refresh_id
            compassData.ownerId = npcInfo.ownerId
            if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
              compassData.worldMapActivityConf = self.bigMapModuleData:GetMapActivityConfByMapId(worldMap.id)
            else
              compassData.worldMapActivityConf = nil
            end
            compassData.layer_id = npcInfo.layerId
            local npcUI = self.NpcIcons[logic_id]
            local isTrackingNpc = npcInfo == self.curTraceNpcInfo
            local isShowNpc = self:IsShowNpc(compassData, worldMap, isTrackingNpc)
            if npcInfo == self.curTraceNpcInfo and not isShowNpc then
              self.curTraceNpcInfo = nil
            end
            if npcUI then
              npcUI.UpdateVersion = self.NpcUpdateCommon.CurUpdateVersion
              if isShowNpc then
                local needResetUClass = false
                if npcUI.WorldMapConfig and npcUI.WorldMapConfig.id ~= worldMap.id then
                  Log.InfoFormat("UMG_Compass_C:UpdateNpcInfo worldMap change, needResetUClass = true, oldWorldMapId=%s, npcInfo.entry_id=%s, npcInfo.logic_id=%s, newWorldMapId=%s", tostring(npcUI.WorldMapConfig.id), tostring(npcInfo.entry_id), tostring(logic_id), tostring(worldMap.id))
                  needResetUClass = true
                  if compassData.NpcConfig and compassData.NpcConfig.genre == Enum.ClientNpcType.CNT_OUTDOOR_CHALLENGE then
                    local oldNpcConfigType = npcUI.NpcConfig and npcUI.NpcConfig.genre or -1
                    Log.ErrorFormat("UMG_Compass_C:UpdateNpcInfo worldMap change, oldNpcConfigType=%s, npcInfo.entry_id=%s, npcInfo.logic_id=%s, newNpcConfigType=Enum.ClientNpcType.CNT_OUTDOOR_CHALLENGE", tostring(oldNpcConfigType), tostring(npcInfo.entry_id), tostring(logic_id))
                  end
                end
                npcUI:UpdateData(compassData, worldMap)
                if needResetUClass then
                  npcUI:SetIsShow(false)
                  self:SetNpcItemUClass(npcUI)
                end
              else
                self.NpcUpdateCommon.RemoveIds[#self.NpcUpdateCommon.RemoveIds + 1] = logic_id
              end
            elseif isShowNpc then
              self:CreateNpcHelper(npcInfo, compassData, worldMap, logic_id)
              if showCathPet then
                isPlayCatchSound = true
              end
            end
          end
        end
      end
    end
  end
  if not self.NpcUpdateCommon.CurUpdateKey then
    for i, v in pairs(self.NpcIcons) do
      if v and v.UpdateVersion < self.NpcUpdateCommon.CurUpdateVersion then
        self.NpcUpdateCommon.RemoveIds[#self.NpcUpdateCommon.RemoveIds + 1] = i
      end
    end
    self:RemoveUIById(self.NpcUpdateCommon.RemoveIds, self.NpcIcons)
    if self.NpcUpdateCommon.IsValueChange then
      self:SetForceUpdatePos(true)
    end
    self.NpcUpdateCommon = nil
  end
  if self.compassTraceInfo then
    NRCModuleManager:DoCmd(BigMapModuleCmd.StartOrCancelTempTrace, self.compassTraceInfo)
  end
  if isPlayCatchSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1382, "UMG_Compass_C:UpdateNpcInfo")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1383, "UMG_Compass_C:UpdateNpcInfo")
  end
end

function UMG_Compass_C:CreateNpcHelper(npcInfo, compassData, worldMap, logic_id)
  local curFrameNum = UE4.UNRCStatics.GetCurGFrameNumber()
  if not npcInfo then
    Log.ErrorFormat("UMG_Compass_C:CreateNpcHelper npcInfo is nil, logic_id=%s", tostring(logic_id))
    return
  end
  if not compassData then
    Log.ErrorFormat("UMG_Compass_C:CreateNpcHelper compassData is nil, logic_id=%s", tostring(logic_id))
    return
  end
  if not worldMap then
    Log.ErrorFormat("UMG_Compass_C:CreateNpcHelper worldMap is nil, logic_id=%s", tostring(logic_id))
    return
  end
  if not logic_id then
    Log.ErrorFormat("UMG_Compass_C:CreateNpcHelper logic_id is nil, npcInfo.entry_id=%s", tostring(npcInfo.entry_id))
    return
  end
  local defaultTrackType = worldMap and worldMap.default_track_type or 0
  if defaultTrackType > 0 then
    local isForceTrack = self:IsForceTrackNpc(logic_id, defaultTrackType)
    if isForceTrack then
      self.NpcIcons[logic_id] = self:CreateNpcData(compassData, worldMap, self.TraceNpcLayer)
      self.NpcIcons[logic_id]:SetTrace(true, nil, 1, false)
      self:AddToForceTrackMap(logic_id, defaultTrackType)
      local traceInfo = {
        traceType = BigMapModuleEnum.TraceType.TempTrace,
        npcInfo = npcInfo
      }
      table.insert(self.compassTraceInfo, traceInfo)
    else
      self.NpcIcons[logic_id] = self:CreateNpcData(compassData, worldMap)
      self:AddToLimitNumTrackTypeCache(logic_id, defaultTrackType, curFrameNum)
    end
  elseif worldMap.default_track then
    self.NpcIcons[logic_id] = self:CreateNpcData(compassData, worldMap, self.TraceNpcLayer)
    local npcCompassUIData = self.NpcIcons[logic_id]
    if worldMap.default_track_loop then
      npcCompassUIData:SetTrace(true, nil, 1, true)
      local traceInfo = {
        traceType = BigMapModuleEnum.TraceType.TempTrace,
        npcInfo = npcInfo
      }
      table.insert(self.compassTraceInfo, traceInfo)
    else
      npcCompassUIData:SetTrace(true, nil, 0, true)
    end
  else
    self.NpcIcons[logic_id] = self:CreateNpcData(compassData, worldMap)
  end
end

function UMG_Compass_C:RemoveUIById(removeIds, tables)
  local curFrameNum = UE4.UNRCStatics.GetCurGFrameNumber()
  for i = 1, #removeIds do
    local ui = tables[removeIds[i]]
    if ui then
      if ui.WorldMapConfig.default_track_loop and self.compassTraceInfo and #self.compassTraceInfo > 0 then
        for k, traceInfo in ipairs(self.compassTraceInfo) do
          local logicId = traceInfo.npcInfo.logic_id
          if logicId and logicId == removeIds[i] then
            table.remove(self.compassTraceInfo, k)
            break
          end
        end
      end
      local defaultTrackType = ui.WorldMapConfig and ui.WorldMapConfig.default_track_type or 0
      if defaultTrackType and defaultTrackType > 0 then
        self:RemoveFromTrackTypeCache(removeIds[i], defaultTrackType, curFrameNum)
      end
      self:RemoveUIData(ui)
      tables[removeIds[i]] = nil
    end
  end
end

function UMG_Compass_C:RemoveUIData(uiData)
  uiData:ChangeDisArrayValue(nil)
  uiData.DistanceLevelArray = nil
  uiData:SetIsShow(false)
  uiData:SetShowArray(nil)
end

function UMG_Compass_C:PreUpdateMapAreaInfo(mapAreaInfos)
  if not mapAreaInfos then
    return
  end
  if not self.MapAreaUpdateCommon then
    self.MapAreaUpdateCommon = {}
    self.MapAreaUpdateCommon.CurUpdateVersion = CacheMapAreaUpdateVersion
  end
  self.MapAreaUpdateCommon.RemoveIds = {}
  self.MapAreaUpdateCommon.CurUpdateKey = nil
  self.MapAreaUpdateCommon.IsValueChange = false
  self.MapAreaUpdateCommon.Data = mapAreaInfos or {}
  self.MapAreaUpdateCommon.NeedUpdateCount = UpdateMapAreaDataNumPerFrame
  self.MapAreaUpdateCommon.CurUpdateVersion = self.MapAreaUpdateCommon.CurUpdateVersion + 1
  CacheMapAreaUpdateVersion = self.MapAreaUpdateCommon.CurUpdateVersion
end

function UMG_Compass_C:UpdateMapAreaInfo()
  if not self.MapAreaUpdateCommon then
    return
  end
  self.CurSceneID = SceneUtils.GetSceneID()
  self.CurSceneResID = SceneUtils.GetSceneResId()
  local compassData = {}
  while self.MapAreaUpdateCommon.NeedUpdateCount > 0 do
    local mapArea
    self.MapAreaUpdateCommon.CurUpdateKey, mapArea = next(self.MapAreaUpdateCommon.Data, self.MapAreaUpdateCommon.CurUpdateKey)
    if self.MapAreaUpdateCommon.CurUpdateKey then
      self.MapAreaUpdateCommon.NeedUpdateCount = self.MapAreaUpdateCommon.NeedUpdateCount - 1
      local worldMap = self:GetWorldMapById(mapArea.world_map_cfg_id)
      if worldMap and mapArea.IsValid and self.CurSceneID == self:GetBelongSceneId(worldMap) and self.CurSceneResID == self:GetBelongSceneResId(worldMap) then
        compassData.IsUnLock = mapArea.unlocked
        compassData.Position = mapArea.area_pos
        compassData.Id = mapArea.world_map_cfg_id
        self.MapAreaUpdateCommon.IsValueChange = true
        local areaUI = self.MapAreaIcons[mapArea.world_map_cfg_id]
        local isShowArea = self:IsShowMapArea(compassData, worldMap)
        local shouldShowNpc = false
        local refreshId
        if not isShowArea and mapArea.npcList then
          for i = 1, #mapArea.npcList do
            local npc = mapArea.npcList[i]
            compassData.IsUnLock = npc.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
            compassData.NpcConfig = _G.DataConfigManager:GetNpcConf(npc.npc_cfg_id)
            compassData.IsOwlStarNpc = compassData.NpcConfig.min_map_disappear and compassData.NpcConfig.min_map_disappear > 0
            shouldShowNpc = self:IsShowNpc(compassData, worldMap)
            if shouldShowNpc then
              refreshId = mapArea.npcId
              break
            end
          end
        end
        if areaUI then
          areaUI.UpdateVersion = self.MapAreaUpdateCommon.CurUpdateVersion
          if isShowArea then
            areaUI:UpdateData(compassData, worldMap)
          elseif shouldShowNpc and refreshId then
            if self.NpcIcons[refreshId] then
              Log.ErrorFormat("zgx map Area error ,\229\143\175\232\131\189\230\152\175\233\133\141\231\189\174\233\148\153\232\175\175  WorldMapConfigId : %s ,  npcrefreshId :%s", refreshId, mapArea.world_map_cfg_id)
              self:RemoveUIById({refreshId}, self.NpcIcons)
            end
            compassData.Id = refreshId
            self.NpcIcons[refreshId] = areaUI
            areaUI:MapAreaChangeToNpc(compassData, worldMap, self.NpcDisLeveKeys, self.CurShowNpcKeys)
            self.MapAreaIcons[mapArea.world_map_cfg_id] = nil
          else
            self.MapAreaUpdateCommon.RemoveIds[#self.MapAreaUpdateCommon.RemoveIds + 1] = mapArea.world_map_cfg_id
          end
        elseif isShowArea then
          self.MapAreaIcons[mapArea.world_map_cfg_id] = self:CreateAreaData(compassData, worldMap)
          areaUI = self.MapAreaIcons[mapArea.world_map_cfg_id]
        end
        if mapArea == self.curTraceNpcInfo and areaUI and areaUI.UpdateVersion < self.MapAreaUpdateCommon.CurUpdateVersion then
          self.curTraceNpcInfo = nil
        end
      end
    else
      break
    end
  end
  if not self.MapAreaUpdateCommon.CurUpdateKey then
    for i, v in pairs(self.MapAreaIcons) do
      if v and v.UpdateVersion < self.MapAreaUpdateCommon.CurUpdateVersion then
        self.MapAreaUpdateCommon.RemoveIds[#self.MapAreaUpdateCommon.RemoveIds + 1] = i
      end
    end
    self:RemoveUIById(self.MapAreaUpdateCommon.RemoveIds, self.MapAreaIcons)
    if self.MapAreaUpdateCommon.IsValueChange then
      self:SetForceUpdatePos(true)
    end
    self.MapAreaUpdateCommon = nil
  end
end

function UMG_Compass_C:UpdateMarkInfo(markInfos)
  self.CurSceneID = SceneUtils.GetSceneID() or 103
  self.CurSceneResID = SceneUtils.GetSceneResId()
  if not markInfos or 103 ~= self.CurSceneID then
    markInfos = {}
  end
  self.ItemsByDistance = nil
  local traceChangeIds = {}
  for _, mark in pairs(markInfos) do
    if mark.pos and BigMapUtils.GetSceneResIdByPos(mark.pos.x, mark.pos.y) == self.CurSceneResID then
      local markUI = self.MarkIcons[mark.mark_id]
      if markUI then
        local isTrace = markUI.fatherLayer == self.TraceNpcLayer and true or false
        local newTrace = mark.is_track and true or false
        if isTrace ~= newTrace then
          traceChangeIds[#traceChangeIds + 1] = mark.mark_id
        end
      end
    end
  end
  self:RemoveUIById(traceChangeIds, self.MarkIcons)
  local removeIds = {}
  for i, _ in pairs(self.MarkIcons) do
    removeIds[#removeIds + 1] = i
  end
  local compassData = {}
  local isValueChange = false
  for _, mark in pairs(markInfos) do
    if mark.pos and BigMapUtils.GetSceneResIdByPos(mark.pos.x, mark.pos.y) == self.CurSceneResID then
      compassData.IsUnLock = true
      compassData.Position = UE4.FVector(mark.pos.x, mark.pos.y, mark.pos.z)
      compassData.Id = mark.mark_id
      compassData.layer_id = mark.layer_id
      isValueChange = true
      local worldMap = self:GetWorldMapByConfId(mark.world_map_cfg_id)
      local markUI = self.MarkIcons[mark.mark_id]
      table.removeValue(removeIds, mark.mark_id)
      if markUI then
        markUI:UpdateData(compassData, worldMap)
      elseif mark.is_track then
        self.MarkIcons[mark.mark_id] = self:CreateMarkData(compassData, worldMap, self.TraceNpcLayer)
        self.MarkIcons[mark.mark_id]:SetTrace(true, true)
      else
        self.MarkIcons[mark.mark_id] = self:CreateMarkData(compassData, worldMap)
      end
    end
  end
  self:RemoveUIById(removeIds, self.MarkIcons)
  if isValueChange then
    self:SetForceUpdatePos(true)
  end
end

function UMG_Compass_C:UpdateAcceptableTaskData()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if nil == bigMapModule then
    return
  end
  local removeIds = {}
  for i, _ in pairs(self.AcceptableTaskIcons) do
    removeIds[#removeIds + 1] = i
  end
  local acceptableTaskList = bigMapModule.data:GetAccessTaskInfoList()
  local sceneResId = SceneUtils.GetSceneResId()
  local compassData = {}
  local isValueChange = false
  for _, taskInfo in pairs(acceptableTaskList) do
    if not taskInfo.NpcPosition or not taskInfo.TaskConf then
    else
      local taskId = taskInfo.TaskConf.id
      if taskInfo.TaskSceneResId ~= sceneResId then
      else
        local worldMap = TaskUtils.GetWorldMapConfigForAcceptableTaskByTaskID(taskInfo.TaskConf)
        if not worldMap then
          Log.ErrorFormat("UMG_Compass_C:UpdateAcceptableTaskData worldMapConfig is nil for taskId=%s", tostring(taskId))
        else
          table.removeValue(removeIds, taskId)
          compassData.IsUnLock = true
          compassData.Position = UE4.FVector(taskInfo.NpcPosition[1].pos.x, taskInfo.NpcPosition[1].pos.y, taskInfo.NpcPosition[1].pos.z)
          compassData.Id = taskId
          isValueChange = true
          local compassUIData = self.AcceptableTaskIcons[taskId]
          if compassUIData then
            compassUIData:UpdateData(compassData, worldMap)
          else
            self.AcceptableTaskIcons[taskId] = self:CreateAcceptableTaskData(compassData, worldMap)
          end
        end
      end
    end
  end
  self:RemoveUIById(removeIds, self.AcceptableTaskIcons)
  if isValueChange then
    self:SetForceUpdatePos(true)
  end
end

function UMG_Compass_C:OnTraceAcceptTaskRefresh(TaskID, IsTrace)
  if self.AcceptableTaskIcons[TaskID] then
    self.AcceptableTaskIcons[TaskID]:SetTrace(IsTrace, false)
  end
end

function UMG_Compass_C:CreateAcceptableTaskData(info, worldMap)
  local acceptableTaskCompassUIData = AcceptableTaskCompassUIData(self.TaskLayer, self, self.SpacePerAngle, self.AcceptableTaskDisLevelKeys)
  acceptableTaskCompassUIData.itemUClass = self.CompassAcceptableTaskTemplate
  acceptableTaskCompassUIData:InitData(info, worldMap, self.ViewField)
  return acceptableTaskCompassUIData
end

function UMG_Compass_C:UpdateNpc()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    self:PreUpdateMapAreaInfo(bigMapModule.data:GetMapAreaDatas())
    self:PreUpdateNpcInfo(bigMapModule.data:GetNpcDatas(self.CurSceneResID))
    self:UpdateMarkInfo(bigMapModule.data:GetNewCustomPointInfo())
    self:UpdateAcceptableTaskData()
  end
end

function UMG_Compass_C:CreateCompassPartWidget(index)
  local compassPart = UE4.UWidgetBlueprintLibrary.Create(self, self.CompassPartTemplate)
  if compassPart then
    compassPart:InitUI((index - 1) * self.AngleLength, self.SpacePerAngle, self.AngleConvertString[index])
    local widgetSlot = self.CompassRoot:AddChild(compassPart)
    local Achors = UE4.FAnchors()
    Achors.Minimum = UE4.FVector2D(0.5, 0)
    Achors.Maximum = UE4.FVector2D(0.5, 0)
    widgetSlot:SetPosition(UE4.FVector2D(0, 50))
    widgetSlot:SetAnchors(Achors)
    widgetSlot:SetAlignment(UE4.FVector2D(0.5, 0))
    widgetSlot:SetAutoSize(true)
  end
  return compassPart
end

function UMG_Compass_C:CreateCompItemWidget(fatherLayer, uclass)
  self.IsForceUpdateDir = true
  uclass = uclass or self.CompassFunctionTemplate
  local CompItem
  for i, v in ipairs(self.CompItemCircle) do
    CompItem = self.CompItemCircle[i]
    if fatherLayer == CompItem:GetParent() then
      table.remove(self.CompItemCircle, i)
      return CompItem
    end
  end
  CompItem = UE4.UWidgetBlueprintLibrary.Create(self, uclass)
  if CompItem then
    local widgetSlot = fatherLayer:AddChild(CompItem)
    local Achors = UE4.FAnchors()
    Achors.Minimum = UE4.FVector2D(0.5, 0)
    Achors.Maximum = UE4.FVector2D(0.5, 0)
    widgetSlot:SetAnchors(Achors)
    widgetSlot:SetAlignment(UE4.FVector2D(0.5, 0.5))
    widgetSlot:SetPosition(UE4.FVector2D(1000, 53))
    CompItem:SetRenderScale(UE4.FVector2D(self.IconScale, self.IconScale))
  end
  return CompItem
end

function UMG_Compass_C:CreateCatchPetData(info, worldMap, fatherLayer)
  local catchIcon = CatchePetCompassUIData(fatherLayer or self.NpcLayer, self, self.SpacePerAngle, self.NpcDisLeveKeys)
  catchIcon:InitData(info, worldMap, self.ViewField)
  catchIcon.itemUClass = self.CompassFunctionTemplate
  catchIcon:SetShowArray(self.CurShowNpcKeys)
  catchIcon.UpdateVersion = self.NpcUpdateCommon and self.NpcUpdateCommon.CurUpdateVersion or CacheNpcUpdateVersion
  catchIcon.DistanceSquare = self:DistanceSquare(catchIcon.WorldPos, self.NowHeroPos)
  return catchIcon
end

function UMG_Compass_C:CreateNpcData(info, worldMap, fatherLayer)
  local NpcIcon = NPCCompassUIData(fatherLayer or self.NpcLayer, self, self.SpacePerAngle, self.NpcDisLeveKeys, self.MoveNpcDisLeveKey)
  NpcIcon:InitData(info, worldMap, self.ViewField)
  self:SetNpcItemUClass(NpcIcon)
  NpcIcon:SetShowArray(self.CurShowNpcKeys)
  NpcIcon.UpdateVersion = self.NpcUpdateCommon and self.NpcUpdateCommon.CurUpdateVersion or CacheNpcUpdateVersion
  NpcIcon.DistanceSquare = self:DistanceSquare(NpcIcon.WorldPos, self.NowHeroPos)
  return NpcIcon
end

function UMG_Compass_C:SetNpcItemUClass(NpcIcon)
  if NpcIcon.IsCathPetNpc then
    NpcIcon.itemUClass = self.CompassFunctionTemplate
  elseif NpcIcon.NpcConfig then
    if NpcIcon.NpcConfig.genre == Enum.ClientNpcType.CNT_PETBOSS or NpcIcon.NpcConfig.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT or NpcIcon.NpcConfig.genre == Enum.ClientNpcType.CNT_HOME_NPC then
      NpcIcon.itemUClass = self.CompassPetTemplate
    elseif NpcIcon.NpcConfig.genre == Enum.ClientNpcType.CNT_TELEPORT or NpcIcon.NpcConfig.genre == Enum.ClientNpcType.CNT_FLOWER_SEED or NpcIcon.NpcConfig.genre == Enum.ClientNpcType.CNT_CAMP or NpcIcon.WorldMapConfig.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
      NpcIcon.itemUClass = self.CompassFunctionTemplate
    elseif NpcIcon.WorldMapConfig.map_func_icon_group and NpcIcon.WorldMapConfig.map_func_icon_group == _G.Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
      NpcIcon.itemUClass = self.CompassFunctionTemplate
    else
      NpcIcon.itemUClass = self.CompassRoleTemplate
    end
  else
    local worldMapId = NpcIcon.WorldMapConfig and NpcIcon.WorldMapConfig.id or 0
    Log.ErrorFormat("[UMG_Compass_C:SetNpcItemUClass] unexpected, npc config is nil! use default umg. worldMapId = %s", tostring(worldMapId))
    NpcIcon.itemUClass = self.CompassFunctionTemplate
  end
end

function UMG_Compass_C:CreatePetSense(info, iconPath, sceneNpc)
  local petSense = PetSenseCompassUIData(self.TaskLayer, self, self.SpacePerAngle)
  petSense.itemUClass = self.CompassSenseTemplate
  petSense:InitData(info, iconPath, self.ViewField, sceneNpc)
  return petSense
end

function UMG_Compass_C:CreateTaskData(taskItem)
  local TaskIcon = TaskCompassUIData(self.TaskLayer, self, self.SpacePerAngle)
  TaskIcon.itemUClass = self.CompassTaskTemplate
  TaskIcon:InitData(taskItem, self.ViewField)
  local iconShowData = _G.DataConfigManager:GetGlobalConfigByKeyType("main_compass_task_icon_show", _G.DataConfigManager.ConfigTableId.MAP_GLOBAL_CONFIG)
  local main_compass_task_icon_show
  if iconShowData then
    main_compass_task_icon_show = iconShowData.num
  end
  if main_compass_task_icon_show and 1 == main_compass_task_icon_show then
    TaskIcon:SetIsShow(false)
  else
    TaskIcon:SetIsShow(true)
  end
  return TaskIcon
end

function UMG_Compass_C:CreateVisitData(VisitorInfo, index)
  local VisitIcon = VisitCompassUIData(self.TraceNpcLayer, self, self.SpacePerAngle)
  VisitIcon.itemUClass = self.CompassVisitTemplate
  VisitIcon:InitData(VisitorInfo, self.ViewField, index)
  VisitIcon:SetIsShow(true)
  VisitIcon:SetIndex()
  return VisitIcon
end

function UMG_Compass_C:CreateAreaData(info, worldMap, fatherLayer)
  local MapArea = AreaCompassUIData(fatherLayer or self.NpcLayer, self, self.SpacePerAngle, self.MapAreaDisLeveKeys)
  MapArea:InitData(info, worldMap, self.ViewField)
  MapArea.itemUClass = self.CompassFunctionTemplate
  MapArea:SetShowArray(self.CurShowAreaKeys)
  MapArea.UpdateVersion = self.MapAreaUpdateCommon and self.MapAreaUpdateCommon.CurUpdateVersion or CacheMapAreaUpdateVersion
  return MapArea
end

function UMG_Compass_C:CreateMarkData(info, worldMap, fatherLayer)
  local Mark = MarkCompassUIData(fatherLayer or self.NpcLayer, self, self.SpacePerAngle, self.MarkDisLeveKeys)
  Mark.itemUClass = self.CompassMarkTemplate
  Mark:InitData(info, worldMap, self.ViewField)
  return Mark
end

function UMG_Compass_C:ShowPetSense(sceneNpc, iconPath)
  if sceneNpc and sceneNpc:GetActorLocation() then
    local compassData = {}
    compassData.IsUnLock = true
    local newTraceUI = self.PetSensing[1]
    compassData.Position = sceneNpc:GetActorLocation()
    if not newTraceUI then
      self.PetSensing[1] = self:CreatePetSense(compassData, iconPath, sceneNpc)
    else
      newTraceUI.SceneTarget = sceneNpc
      newTraceUI:UpdateData(compassData, iconPath)
    end
    self:SetForceUpdatePos(true)
  end
end

function UMG_Compass_C:DistanceSquare(a, b)
  return UE4.FVector.DistSquared(a, b) / 10000
end

function UMG_Compass_C:DistanceSquareInXY(a, b)
  return UE4.FVector.DistSquared2D(a, b) / 10000
end

function UMG_Compass_C:DistanceInZ(a, b)
  return (b.Z - a.Z) / 100
end

function UMG_Compass_C:AngleWithNorthInXY(a)
  local cosine = a:CosineAngle2D(self.NorthVector)
  local angle = math.deg(math.acos(cosine))
  if a.X >= 0 then
    return angle
  else
    return 360 - angle
  end
end

function UMG_Compass_C:AngleWithUpIn3D(a)
  local cosine = a.Z / a:Size()
  local angle = math.deg(math.acos(cosine))
  if a.X >= 0 then
    return angle
  else
    return 360 - angle
  end
end

function UMG_Compass_C:GetDetectLimit(array, key, needSquare)
  if key and array then
    if array[key] then
      return array[key]
    else
      local data = _G.DataConfigManager:GetMapGlobalConfig(key)
      if data then
        if needSquare then
          array[key] = self:GetSquare(data.num)
        else
          array[key] = data.num
        end
        return array[key]
      end
    end
  end
  Log.Error("GetDetectLimit error key is ", key or "nil")
  return 0
end

local ComputeUIItemShowTempVector = UE4.FVector()

function UMG_Compass_C:ComputeUIItemShow(uiItem, curFrameNum)
  local disSquareInXY = self:DistanceSquareInXY(self.NowHeroPos, uiItem.WorldPos)
  uiItem.DistanceInXYSquare = disSquareInXY
  local disSquare
  local defaultTrackType = uiItem.WorldMapConfig and uiItem.WorldMapConfig.default_track_type
  if defaultTrackType and defaultTrackType > 0 then
    disSquare = self:DistanceSquare(self.NowHeroPos, uiItem.WorldPos)
    uiItem.DistanceSquare = disSquare
    self:_SetTrackTypeSortDirty(defaultTrackType, curFrameNum + 1, curFrameNum)
  end
  if not self.DistanceLevelInitPos[uiItem.DistanceLevel] then
    self.DistanceLevelInitPos[uiItem.DistanceLevel] = self.NowHeroPos
  end
  if not uiItem.WorldMapConfig then
    uiItem:SetIsShow(false)
    return
  end
  if (not uiItem.IsTrace or uiItem.IsTraceInHVDistance) and disSquareInXY > self:GetDetectLimit(self.DetectLimitH, uiItem.WorldMapConfig.h_detection_range, true) then
    uiItem:SetIsShow(false)
    return
  end
  local disInZ = self:DistanceInZ(self.NowHeroPos, uiItem.WorldPos)
  if (not uiItem.IsTrace or uiItem.IsTraceInHVDistance) and math_abs(disInZ) > self:GetDetectLimit(self.DetectLimitV, uiItem.WorldMapConfig.v_detection_range) then
    uiItem:SetIsShow(false)
    return
  end
  if uiItem.worldMapActivityConf and uiItem.worldMapActivityConf.radius and not self:CheckShowCircleActivityNpc(uiItem.WorldPos.X, uiItem.WorldPos.Y, uiItem.worldMapActivityConf.radius) then
    uiItem:SetIsShow(false)
    return
  end
  self.IsUpdateIconPos = true
  if not disSquare then
    disSquare = self:DistanceSquare(self.NowHeroPos, uiItem.WorldPos)
    uiItem.DistanceSquare = disSquare
  end
  if defaultTrackType and defaultTrackType > 0 and not self:CanShowByTrackTypeLimit(uiItem, curFrameNum) then
    uiItem:SetIsShow(false)
    return
  end
  uiItem:SetIsShow(true)
  uiItem:SetIsBig(disSquare < self.SizeChangeDisSquare)
  if uiItem.CurState == uiItem.MapAreaState.MAP_NPC and uiItem.DistanceSquare <= 10000 then
    uiItem:UpdateWorldPos()
  end
  if disSquare > self.ShowHighDis then
    uiItem.WorldPos:SubInto(self.NowHeroPos, ComputeUIItemShowTempVector)
    local angleInZX = self:AngleWithUpIn3D(ComputeUIItemShowTempVector)
    if angleInZX <= 90 - self.ShowHighAngle or angleInZX >= 270 + self.ShowHighAngle then
      uiItem:SetUpOrDown(1)
    elseif angleInZX >= 90 + self.ShowHighAngle and angleInZX <= 270 - self.ShowHighAngle then
      uiItem:SetUpOrDown(2)
    else
      uiItem:SetUpOrDown(0)
    end
  else
    uiItem:SetUpOrDown(0)
  end
  uiItem.WorldPos:SubInto(self.NowHeroPos, ComputeUIItemShowTempVector)
  local angleInXY = self:AngleWithNorthInXY(ComputeUIItemShowTempVector)
  uiItem.ComPassAngle = angleInXY
end

function UMG_Compass_C:CheckShowCircleActivityNpc(posX, posY, radius)
  local dis = self:GetDistance2D(posX, posY)
  if radius < dis then
    return true
  else
    return false
  end
end

function UMG_Compass_C:GetDistance2D(posX, posY)
  local deltaX = posX - self.NowHeroPos.X
  local deltaY = posY - self.NowHeroPos.Y
  return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function UMG_Compass_C:IsNeedUpdate(distanceLevel)
  if self.CheckDistance[distanceLevel] == nil then
    local intiPos = self.DistanceLevelInitPos[distanceLevel]
    if intiPos then
      local levelDistanceSquare = 2 ^ (2 * distanceLevel)
      local distance = self:DistanceSquareInXY(self.NowHeroPos, intiPos)
      if distance > levelDistanceSquare * 0.01 or levelDistanceSquare < self.SizeChangeDisSquare then
        self.CheckDistance[distanceLevel] = true
      else
        self.CheckDistance[distanceLevel] = false
      end
    else
      self.CheckDistance[distanceLevel] = true
    end
    if self.CheckDistance[distanceLevel] then
      self.DistanceLevelInitPos[distanceLevel] = self.NowHeroPos
    end
  end
  if -1 == distanceLevel or self.ForceUpdateFrame > 0 then
    return true
  end
  return self.CheckDistance[distanceLevel]
end

function UMG_Compass_C:UpdateDisLayer(Layers, KeyDatas)
  local curFrameNum = UE4.UNRCStatics.GetCurGFrameNumber()
  if self.IsForceUpdatePos or self.IsShouldUpdatePos then
    Layers.WillUpdateFrame = Layers.NeedUpdateFrame or 1
    self.ForceUpdateFrame = math.max(self.ForceUpdateFrame or 1, Layers.WillUpdateFrame)
    Layers.CurUpdateLayer = Layers.CurUpdateLayer or -1
    Layers.MaxLayer = Layers.MaxLayer or 0
    Layers.UpdateLayerCount = math.min(self.DisUpdatePerTick, Layers.MaxLayer + 1)
  end
  if Layers.WillUpdateFrame and Layers.WillUpdateFrame <= 0 then
    return
  end
  local updateLayers = {-1}
  for i = 1, Layers.UpdateLayerCount do
    local layerId = Layers.CurUpdateLayer + i
    if layerId > Layers.MaxLayer then
      layerId = layerId - 1 - Layers.MaxLayer
    end
    updateLayers[i + 1] = layerId
  end
  Layers.CurUpdateLayer = updateLayers[Layers.UpdateLayerCount + 1]
  Layers.WillUpdateFrame = Layers.WillUpdateFrame - 1
  for _, i in ipairs(updateLayers) do
    local layer = Layers[i]
    if layer and layer.KeysList then
      if self:IsNeedUpdate(i) then
        layer.NeedUpdateCount = layer.ItemNumber
      end
      DisLayerUpdateNum = math.min(self.LayerUpdatePerTick, layer.NeedUpdateCount)
      if -1 == i then
        DisLayerUpdateNum = layer.ItemNumber
      end
      if DisLayerUpdateNum > 0 then
        layer.NeedUpdateCount = layer.NeedUpdateCount - DisLayerUpdateNum
        local ErrorKeys
        while DisLayerUpdateNum > 0 do
          if layer.CurUpdateKey then
            local item = KeyDatas[layer.CurUpdateKey]
            if item then
              self:ComputeUIItemShow(item, curFrameNum)
              self.willChangeItems[#self.willChangeItems + 1] = item
              if layer.KeysList[layer.CurUpdateKey] then
                local integerId = math.tointeger(layer.CurUpdateKey)
                local nextKey = integerId or layer.CurUpdateKey
                layer.CurUpdateKey = next(layer.KeysList, nextKey)
              else
                Log.Error("zgx no key!!", layer.CurUpdateKey)
              end
              if not layer.CurUpdateKey then
                layer.CurUpdateKey = next(layer.KeysList)
              end
            else
              Log.Error("zgx no item!!", layer.CurUpdateKey)
              ErrorKeys = ErrorKeys or {}
              ErrorKeys[#ErrorKeys + 1] = layer.CurUpdateKey
              layer.CurUpdateKey = next(layer.KeysList)
            end
          else
            Log.Error("zgx there is no UpdateKey")
            layer.CurUpdateKey = next(layer.KeysList)
          end
          DisLayerUpdateNum = layer.CurUpdateKey and DisLayerUpdateNum - 1 or 0
        end
        if ErrorKeys then
          for _, v in ipairs(ErrorKeys) do
            layer.KeysList[v] = nil
          end
        end
      end
    end
  end
end

function UMG_Compass_C:UpdateHeroPosition()
  self.NowHeroPos = self.LocalPlayer:GetActorLocationFrameCache()
  if self.CurCompassState ~= UMG_Compass_C.State.NORMAL then
    return
  end
  self.CheckDistance = {}
  table.clear(self.willChangeItems)
  self:UpdateDisLayer(self.NpcDisLeveKeys, self.NpcIcons)
  self:UpdateDisLayer(self.MapAreaDisLeveKeys, self.MapAreaIcons)
  self:UpdateDisLayer(self.MarkDisLeveKeys, self.MarkIcons)
  self:UpdateDisLayer(self.AcceptableTaskDisLevelKeys, self.AcceptableTaskIcons)
  for _, v in ipairs(self.willChangeItems) do
    v:CalDistanceLevel(log2)
  end
  self:SetForceUpdatePos(false)
  self.IsUpdateHeroPos = true
  self.IsShouldUpdatePos = false
end

function UMG_Compass_C:UpdateMoveNpc(KeyDatas)
  local curFrameNum = UE4.UNRCStatics.GetCurGFrameNumber()
  if self.MoveNpcDisLeveKey and self.MoveNpcDisLeveKey.KeysList then
    DisLayerUpdateNum = math.min(self.LayerUpdatePerTick, self.MoveNpcDisLeveKey.ItemNumber)
    if DisLayerUpdateNum > 0 then
      local ErrorKeys
      while DisLayerUpdateNum > 0 do
        if self.MoveNpcDisLeveKey.CurUpdateKey then
          local item = KeyDatas[self.MoveNpcDisLeveKey.CurUpdateKey]
          if item then
            self:ComputeUIItemShow(item, curFrameNum)
            item:SetPosByCamera(self.CurCameraDir)
            if self.ShowDisItem == item then
              local distance = math.sqrt(self.ShowDisItem.DistanceSquare)
              self.ShowDisItem:DisableDistanceLevel()
              self.ShowDisItem:SetDistance(distance)
            end
            self.MoveNpcDisLeveKey.CurUpdateKey = next(self.MoveNpcDisLeveKey.KeysList, self.MoveNpcDisLeveKey.CurUpdateKey)
            if not self.MoveNpcDisLeveKey.CurUpdateKey then
              self.MoveNpcDisLeveKey.CurUpdateKey = next(self.MoveNpcDisLeveKey.KeysList)
            end
          else
            Log.Error("zgx no item!!", self.MoveNpcDisLeveKey.CurUpdateKey)
            ErrorKeys = ErrorKeys or {}
            ErrorKeys[#ErrorKeys + 1] = self.MoveNpcDisLeveKey.CurUpdateKey
            self.MoveNpcDisLeveKey.CurUpdateKey = next(self.MoveNpcDisLeveKey.KeysList)
          end
        else
          Log.Error("zgx there is no UpdateKey")
          self.MoveNpcDisLeveKey.CurUpdateKey = next(self.MoveNpcDisLeveKey.KeysList)
        end
        DisLayerUpdateNum = self.MoveNpcDisLeveKey.CurUpdateKey and DisLayerUpdateNum - 1 or 0
      end
      if ErrorKeys then
        for _, v in ipairs(ErrorKeys) do
          self.MoveNpcDisLeveKey.KeysList[v] = nil
        end
      end
    end
  end
end

local UpdateTraceTaskTempVector = UE4.FVector()

function UMG_Compass_C:UpdateTraceTask()
  do return end
  if self.CurCompassState ~= UMG_Compass_C.State.NORMAL then
    return
  end
  local TaskMap = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskMap)
  local TaskIds = {}
  if TaskMap then
    for taskId, to in pairs(TaskMap) do
      if to.Trackers then
        local traceCount = 0
        local needUpdate = self.IsUpdateHeroPos
        if not self.TaskIcons[taskId] then
          self.TaskIcons[taskId] = {}
        end
        table.insert(TaskIds, taskId)
        for _, tracker in ipairs(to.Trackers) do
          if tracker.Valid and tracker.TargetInSameSceneGroup then
            traceCount = traceCount + 1
            local trackUI = self.TaskIcons[taskId][traceCount]
            if not trackUI then
              needUpdate = true
              trackUI = self:CreateTaskData(tracker)
              self.TaskIcons[taskId][traceCount] = trackUI
              if self.CurCameraDir then
                trackUI:SetPosByCamera(self.CurCameraDir)
              end
            else
              trackUI:UpdateData(tracker)
            end
            trackUI.WorldPos:SubInto(self.NowHeroPos, UpdateTraceTaskTempVector)
            local angleInXY = self:AngleWithNorthInXY(UpdateTraceTaskTempVector)
            trackUI.ComPassAngle = angleInXY
            trackUI.DistanceSquare = self:DistanceSquare(trackUI.WorldPos, self.NowHeroPos)
            if self.bTaskClicked == true and trackUI.CompWidget then
              trackUI.CompWidget:OnTaskClicked()
            end
            trackUI:SetIsBig(trackUI.DistanceSquare < self.SizeChangeDisSquare)
            self.bTaskClicked = false
          end
        end
        if traceCount < #self.TaskIcons[taskId] then
          for i = #self.TaskIcons[taskId], traceCount + 1, -1 do
            local item = self.TaskIcons[taskId][i]
            table.remove(self.TaskIcons[taskId], i)
            self:RemoveUIData(item)
          end
        end
      end
    end
  end
  for id, v in pairs(self.TaskIcons) do
    if not table.contains(TaskIds, id) then
      for i = #v, 1, -1 do
        local item = v[i]
        table.remove(v, i)
        self:RemoveUIData(item)
      end
    end
  end
end

function UMG_Compass_C:UpdateVisitIcons()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  local ShowTraceVisit = 1 == _G.DataConfigManager:GetOnlineGlobalConfig(22).num
  if not (nil ~= bigMapModule and ShowTraceVisit) or 103 ~= self.CurSceneID then
    return
  end
  local VisitListChangeInfo = {}
  if not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    VisitListChangeInfo = {}
  else
    VisitListChangeInfo = _G.NRCModuleManager:DoCmd(FriendModuleCmd.GetOnlineVisitorList)
  end
  local VisitPointInfo = bigMapModule.data:GetVisitPointInfo() or {}
  if VisitPointInfo and VisitListChangeInfo then
    local UIN = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    for i, Point in ipairs(VisitPointInfo) do
      if Point.pos and Point.uin ~= UIN then
        local _SceneResId, iconSceneResId = BigMapUtils.GetVisitorIconSceneResIdAndPos(Point)
        local SceneResId = iconSceneResId
        if not BigMapUtils.IsBigWorldMap(SceneUtils.GetSceneResId()) then
          SceneResId = _SceneResId
        end
        local IsADD = false
        for _, v in pairs(VisitListChangeInfo) do
          if type(v) == "table" and v.uin == Point.uin and SceneResId == SceneUtils.GetSceneResId() then
            IsADD = true
            break
          end
        end
        for j, v in pairs(self.VisitIcons) do
          if v.UIN == Point.uin then
            local VisitIcon = self.VisitIcons[j]
            VisitIcon:UpdateData(Point, i)
            local angleInXY = self:AngleWithNorthInXY(VisitIcon.WorldPos - self.NowHeroPos)
            VisitIcon.ComPassAngle = angleInXY
            VisitIcon.DistanceSquare = self:DistanceSquare(VisitIcon.WorldPos, self.NowHeroPos)
            VisitIcon:SetIsBig(VisitIcon.DistanceSquare < self.SizeChangeDisSquare)
            IsADD = false
            break
          end
        end
        if IsADD then
          local VisitIcon = self:CreateVisitData(Point, i)
          if self.CurCameraDir then
            VisitIcon:SetPosByCamera(self.CurCameraDir)
          end
          local angleInXY = self:AngleWithNorthInXY(VisitIcon.WorldPos - self.NowHeroPos)
          VisitIcon.ComPassAngle = angleInXY
          VisitIcon.DistanceSquare = self:DistanceSquare(VisitIcon.WorldPos, self.NowHeroPos)
          VisitIcon:SetIsBig(VisitIcon.DistanceSquare < self.SizeChangeDisSquare)
          table.insert(self.VisitIcons, VisitIcon)
        end
      end
    end
    for i = #self.VisitIcons, 1, -1 do
      local isRemove = true
      local VisitorInfo
      for j, point in ipairs(VisitPointInfo) do
        if point.uin == self.VisitIcons[i].UIN then
          isRemove = false
          VisitorInfo = point
          break
        end
      end
      if isRemove then
      else
        local _SceneResId, iconSceneResId = BigMapUtils.GetVisitorIconSceneResIdAndPos(VisitorInfo)
        local SceneResId = iconSceneResId
        if not BigMapUtils.IsBigWorldMap(SceneUtils.GetSceneResId()) then
          SceneResId = _SceneResId
        end
        isRemove = VisitorInfo and self.CurSceneResID ~= SceneResId
        if not isRemove then
          for _, v in pairs(VisitListChangeInfo) do
            if type(v) == "table" and v.uin == self.VisitIcons[i].UIN and SceneResId ~= SceneUtils.GetSceneResId() then
              isRemove = true
              break
            end
          end
        end
      end
      if isRemove then
        local item = self.VisitIcons[i]
        table.remove(self.VisitIcons, i)
        self:RemoveUIData(item)
      end
    end
  end
end

function UMG_Compass_C:UpdatePetSense(InDeltaTime)
  for _, uiItem in pairs(self.PetSensing) do
    if uiItem:BurnSenseTime(InDeltaTime) then
      if uiItem.SceneTarget then
        uiItem:SetPos(uiItem.SceneTarget:GetActorLocation())
      end
      local angleInXY = self:AngleWithNorthInXY(uiItem.WorldPos - self.NowHeroPos)
      uiItem.ComPassAngle = angleInXY
      uiItem.DistanceSquare = self:DistanceSquare(uiItem.WorldPos, self.NowHeroPos)
      uiItem:SetIsShow(true)
    end
  end
end

function UMG_Compass_C:OnTaskClicked()
  self.bTaskClicked = true
end

function UMG_Compass_C:UpdateTraceNpc(bForceUpdate)
  if not self.IsUpdateTraceInfo then
    return
  end
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if nil == bigMapModule then
    return
  end
  local npcData, newIsNpc = bigMapModule:GetTraceNpcData(SceneUtils.GetSceneResId())
  if npcData and not self:CheckBelongToSameSceneId(npcData) then
    return
  end
  local isChangeValue = false
  if self.curTraceNpcInfo and (bForceUpdate or self.curTraceNpcInfo ~= npcData) then
    local refreshId = self.curTraceNpcInfo.logic_id or self.curTraceNpcInfo.world_map_cfg_id
    local oldIsNpc = true
    local oldTraceData
    if not refreshId then
      refreshId = self.curTraceNpcInfo.world_map_cfg_id
      oldTraceData = self.MapAreaIcons[refreshId]
      if oldTraceData then
        self:RemoveUIById({refreshId}, self.MapAreaIcons)
      end
      oldIsNpc = false
    else
      oldTraceData = self.NpcIcons[refreshId]
      if oldTraceData then
        self:RemoveUIById({refreshId}, self.NpcIcons)
      end
    end
    isChangeValue = true
    if oldTraceData then
      local compassData = {}
      compassData.IsUnLock = self.curTraceNpcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
      local worldMap = self:GetWorldMapByConfId(self.curTraceNpcInfo.world_map_cfg_id)
      local isShowNpc = oldIsNpc and self:IsShowNpc(compassData, worldMap) or self:IsShowMapArea(compassData, worldMap)
      if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
        compassData.worldMapActivityConf = self.bigMapModuleData:GetMapActivityConfByMapId(worldMap.id)
      else
        compassData.worldMapActivityConf = nil
      end
      if isShowNpc then
        compassData.Id = refreshId
        compassData.NpcConfig = self.curTraceNpcInfo.npcCfg
        compassData.IsOwlStarNpc = compassData.NpcConfig and compassData.NpcConfig.min_map_disappear and compassData.NpcConfig.min_map_disappear > 0
        compassData.LogicId = refreshId
        compassData.npc_refresh_id = self.curTraceNpcInfo.npc_refresh_id
        compassData.ownerId = self.curTraceNpcInfo.ownerId
        if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
          compassData.worldMapActivityConf = self.bigMapModuleData:GetMapActivityConfByMapId(worldMap.id)
        else
          compassData.worldMapActivityConf = nil
        end
        compassData.layer_id = self.curTraceNpcInfo.layerId
        if oldIsNpc then
          local showCathPet = self:IsShowCatchPet(self.curTraceNpcInfo.npc_refresh_id)
          compassData.IsCathPetNpc = showCathPet
          compassData.NPC_Level = self.curTraceNpcInfo.npc_level
          compassData.Position = UE4.FVector(self.curTraceNpcInfo.npc_pos.x, self.curTraceNpcInfo.npc_pos.y, self.curTraceNpcInfo.npc_pos.z)
          self:CreateNpcHelper(self.curTraceNpcInfo, compassData, worldMap, refreshId)
        else
          compassData.Position = UE4.FVector(self.curTraceNpcInfo.area_pos.x, self.curTraceNpcInfo.area_pos.y, self.curTraceNpcInfo.area_pos.z)
          self.MapAreaIcons[refreshId] = self:CreateAreaData(compassData, worldMap, self.NpcLayer)
        end
      end
    end
    self.curTraceNpcInfo = nil
  end
  if npcData and (bForceUpdate or self.curTraceNpcInfo ~= npcData) then
    local refreshId = newIsNpc and npcData.logic_id or npcData.world_map_cfg_id
    if not refreshId then
      Log.Warning("TraceNpc No npc_refresh_id or world_map_cfg_id")
      return
    end
    self.curTraceNpcInfo = npcData
    isChangeValue = true
    local isPlayAni = true
    local compassData = {}
    compassData.IsUnLock = npcData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
    compassData.Id = refreshId
    compassData.state = npcData.state
    compassData.isFound = npcData.isFound
    local worldMap = self:GetWorldMapByConfId(npcData.world_map_cfg_id)
    local newTraceUI
    if newIsNpc then
      compassData.Position = UE4.FVector(npcData.npc_pos.x, npcData.npc_pos.y, npcData.npc_pos.z)
      compassData.NpcConfig = npcData.npcCfg
      compassData.IsOwlStarNpc = compassData.NpcConfig and compassData.NpcConfig.min_map_disappear and compassData.NpcConfig.min_map_disappear > 0
      newTraceUI = self.NpcIcons[refreshId]
      if newTraceUI then
        isPlayAni = not newTraceUI.IsShow or newTraceUI.Gap >= self.ViewField
        self:RemoveUIById({refreshId}, self.NpcIcons)
      end
    else
      newTraceUI = self.MapAreaIcons[refreshId]
      if newTraceUI then
        isPlayAni = not newTraceUI.IsShow or newTraceUI.Gap >= self.ViewField
        self:RemoveUIById({refreshId}, self.MapAreaIcons)
      end
      compassData.Position = UE4.FVector(npcData.area_pos.x, npcData.area_pos.y, npcData.area_pos.z)
    end
    if newIsNpc then
      local showCathPet = self:IsShowCatchPet(npcData.npc_refresh_id)
      compassData.IsCathPetNpc = showCathPet
      compassData.IsFinish = npcData.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH
      compassData.NPC_Level = npcData.npc_level
      compassData.LogicId = refreshId
      compassData.npc_refresh_id = npcData.npc_refresh_id
      compassData.ownerId = npcData.ownerId
      compassData.layer_id = npcData.layerId
      if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
        compassData.worldMapActivityConf = self.bigMapModuleData:GetMapActivityConfByMapId(worldMap.id)
      else
        compassData.worldMapActivityConf = nil
      end
      if self:IsShowNpc(compassData, worldMap, true) then
        compassData.NPC_Level = self.curTraceNpcInfo.npc_level
        self.NpcIcons[refreshId] = self:CreateNpcData(compassData, worldMap, self.TraceNpcLayer)
        self.NpcIcons[refreshId]:SetTrace(true, isPlayAni)
      else
        self.curTraceNpcInfo = nil
      end
    elseif self:IsShowMapArea(compassData, worldMap, true) then
      self.MapAreaIcons[refreshId] = self:CreateAreaData(compassData, worldMap, self.TraceNpcLayer)
      self.MapAreaIcons[refreshId]:SetTrace(true, isPlayAni)
    else
      self.curTraceNpcInfo = nil
    end
  end
  if isChangeValue then
    self:SetForceUpdatePos(true)
  end
end

function UMG_Compass_C:UpdateZOrder()
  if self.OrderItems then
    table.sort(self.OrderItems, function(a, b)
      if nil == a or nil == b then
        return false
      end
      if a.CurState and b.CurState and a.CurState ~= b.CurState then
        local priorityA = CompassUIData.MapAreaStatePriority[a.CurState]
        local priorityB = CompassUIData.MapAreaStatePriority[b.CurState]
        if not priorityA then
          return false
        end
        if not priorityB then
          return true
        end
        if priorityA ~= priorityB then
          return priorityA < priorityB
        end
      end
      local aValue = a:GetZOrderSort()
      local bValue = b:GetZOrderSort()
      if aValue == bValue then
        return false
      else
        return aValue < bValue
      end
    end)
    for i, v in ipairs(self.OrderItems) do
      v:SetZOrder(10000 - i)
    end
  end
end

function UMG_Compass_C:UpdateCameraDir(CameraDir)
  local needUpdate = self.IsUpdateIconPos or self.IsUpdateHeroPos or self.CurCameraDir ~= CameraDir or self.IsForceUpdateDir
  if needUpdate then
    self.IsForceUpdateDir = false
    self.CurCameraDir = CameraDir
    table.clear(self.RightMiniAngleItems)
    table.clear(self.LeftMiniAngleItems)
    table.clear(self.SpecialAngleItems)
    table.clear(self.OrderItems)
    for i = 1, 4 do
      self.CompassParts[i]:SetPosByCamera(self.CurCameraDir)
    end
    if self.CurCompassState == UMG_Compass_C.State.NORMAL then
      local ErrorKeys = {}
      for key, _ in pairs(self.CurShowNpcKeys) do
        local v = self.NpcIcons[key]
        if v then
          v:SetPosByCamera(self.CurCameraDir)
          self:AddInMinAngleArray(v)
          self.OrderItems[#self.OrderItems + 1] = v
        else
          Log.Error("zgx showNpcArray is nil ", key)
          ErrorKeys[#ErrorKeys + 1] = key
        end
      end
      for i, v in ipairs(ErrorKeys) do
        self.CurShowNpcKeys[v] = nil
      end
      ErrorKeys = {}
      for key, _ in pairs(self.CurShowAreaKeys) do
        local v = self.MapAreaIcons[key]
        if v then
          v:SetPosByCamera(self.CurCameraDir)
          self:AddInMinAngleArray(v)
          self.OrderItems[#self.OrderItems + 1] = v
        else
          Log.Error("zgx showMapAreaArray is nil ", key)
          ErrorKeys[#ErrorKeys + 1] = key
        end
      end
      for i, v in ipairs(ErrorKeys) do
        self.CurShowAreaKeys[v] = nil
      end
      for _, v in pairs(self.TaskIcons) do
        if v then
          for i = 1, #v do
            v[i]:SetPosByCamera(self.CurCameraDir)
            if not v[i].HasArrived then
              self:AddInMinAngleArray(v)
            end
          end
        end
      end
      for _, v in pairs(self.VisitIcons) do
        if v then
          v:SetPosByCamera(self.CurCameraDir)
          if not v.HasArrived then
            self:AddInMinAngleArray(v)
          end
        end
      end
      for _, v in pairs(self.PetSensing) do
        if v.PetSenseTime > 0 then
          v:SetPosByCamera(self.CurCameraDir)
          self:AddInMinAngleArray(v)
        end
      end
      for _, v in pairs(self.MarkIcons) do
        if v.IsShow then
          v:SetPosByCamera(self.CurCameraDir)
          self:AddInMinAngleArray(v)
          self.OrderItems[#self.OrderItems + 1] = v
        end
      end
      for _, v in pairs(self.AcceptableTaskIcons) do
        if v.IsShow then
          v:SetPosByCamera(self.CurCameraDir)
          self:AddInMinAngleArray(v)
          self.OrderItems[#self.OrderItems + 1] = v
        end
      end
      self:UpdateZOrder()
    end
  end
end

function UMG_Compass_C:CanShowDistance(v, ignoreDis)
  if not v.DistanceSquare then
    Log.Error("CanShowDistance DistanceSquare is nil ", v.Id)
    return false
  end
  if v.IsShow and (ignoreDis or v.DistanceSquare <= self.ShowDisDistance) and math_abs(v.Gap) <= self.ShowDisAngle then
    return true
  end
  return false
end

function UMG_Compass_C:ShowItemDistance()
  table.clear(self.EnableDistanceItem)
  if 0 == #self.EnableDistanceItem then
    if self.LeftMiniAngleItems then
      for _, v in ipairs(self.LeftMiniAngleItems) do
        if self:CanShowDistance(v) then
          self.EnableDistanceItem[#self.EnableDistanceItem + 1] = v
        end
      end
    end
    if self.RightMiniAngleItems then
      for _, v in ipairs(self.RightMiniAngleItems) do
        if self:CanShowDistance(v) then
          self.EnableDistanceItem[#self.EnableDistanceItem + 1] = v
        end
      end
    end
  end
  local target = false
  for _, v in ipairs(self.EnableDistanceItem) do
    if not target then
      target = v
    else
      local targetGap = math_abs(target.Gap)
      local vGap = math_abs(v.Gap)
      if targetGap > vGap then
        target = v
      elseif targetGap == vGap then
        if target.Gap * v.Gap >= 0 then
          if v.DistanceSquare < target.DistanceSquare then
            target = v
          end
        elseif v.Gap > 0 then
          target = v
        end
      end
    end
  end
  if self.ShowDisItem and self.ShowDisItem ~= target then
    self.ShowDisItem:EnableDistanceLevel()
    if target then
      local checkTarget = not self.ShowDisItem.IsShow or math_abs(self.ShowDisItem.Gap - target.Gap) > 1 and math_abs(self.ShowDisItem.DistanceSquare - target.DistanceSquare) > 1
      if checkTarget then
        self.ShowDisItem:SetDistance()
      else
        target = self.ShowDisItem
      end
    else
      self.ShowDisItem:SetDistance()
    end
  end
  self.ShowDisItem = target
  if self.ShowDisItem then
    local distance = math.sqrt(self.ShowDisItem.DistanceSquare)
    self.ShowDisItem:DisableDistanceLevel()
    self.ShowDisItem:SetDistance(distance)
  end
end

function UMG_Compass_C:AddSpecialAngleArray(item)
  if item.IsShow then
    tInsert(self.SpecialAngleItems, item)
  end
end

function UMG_Compass_C:AddInMinAngleArray(item)
  if item.CompWidget and item.IsShow then
    local array
    if item.Gap > 0 then
      array = self.RightMiniAngleItems
    else
      array = self.LeftMiniAngleItems
    end
    if array[1] then
      if math_abs(array[1].Gap) > math_abs(item.Gap) then
        table.clear(array)
        array[1] = item
      elseif math_abs(array[1].Gap) == math_abs(item.Gap) then
        tInsert(array, item)
      end
    else
      array[1] = item
    end
  end
end

function UMG_Compass_C:TransformDir(CameraDir)
  CameraDir = CameraDir + 90
  while CameraDir < 0 do
    CameraDir = CameraDir + 360
  end
  while CameraDir > 360 do
    CameraDir = CameraDir - 360
  end
  return CameraDir
end

function UMG_Compass_C:CheckNeedUpdatePreData()
  if self.CurCompassState ~= UMG_Compass_C.State.NORMAL then
    return
  end
  if self.NpcUpdateCommon then
    self.NpcUpdateCommon.NeedUpdateCount = UpdateNpcDataNumPerFrame
    self:UpdateNpcInfo()
  end
  if self.MapAreaUpdateCommon then
    self.MapAreaUpdateCommon.NeedUpdateCount = UpdateMapAreaDataNumPerFrame
    self:UpdateMapAreaInfo()
  end
end

function UMG_Compass_C:OnTick(InDeltaTime)
  if self.IsShow and self.IsEnable then
    if not self.LocalPlayer then
      return
    end
    if not self.PlayerCameraManager then
      return
    end
    self:CheckNeedUpdatePreData()
    local bUpdatePosOrDir = false
    self.IsShouldUpdatePos = 1 == ARocoPlayerCameraManager_NeedUpdateCompassPos(self.PlayerCameraManager)
    if self.IsForceUpdatePos or self.IsShouldUpdatePos or self.ForceUpdateFrame > 0 then
      bUpdatePosOrDir = true
      self.IsUpdateHeroPos = false
      self.IsUpdateIconPos = false
      self:UpdateHeroPosition()
      if self.CurCompassState == UMG_Compass_C.State.NORMAL then
        self:UpdateTraceTask()
        self:UpdateVisitIcons()
        self:UpdatePetSense(InDeltaTime)
      end
    end
    if self.IsForceUpdateDir or 1 == ARocoPlayerCameraManager_NeedUpdateCompassRotation(self.PlayerCameraManager) or bUpdatePosOrDir then
      bUpdatePosOrDir = true
      self:UpdateCameraDir(self:TransformDir(self.LocalPlayer:GetCameraRotationYFrameCache()))
    end
    if bUpdatePosOrDir then
      self:ShowItemDistance()
    else
      self:UpdateMoveNpc(self.NpcIcons)
    end
    if self._defaultTrackNpcDataChangePending then
      self._defaultTrackNpcDataChangePending = false
      self:_ProcessDefaultTrackTypeNpcDataChange()
    end
  end
end

function UMG_Compass_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if self.CurCompassState ~= UMG_Compass_C.State.NORMAL then
    Log.Debug("UMG_Compass_C:OnTouchStarted not noraml state, can not open map")
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, false)
  if not isBan and BigMapModuleCmd then
    NRCProfilerLog:NRCClickBtn(true, "MainBigMap")
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap)
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Compass_C:UpdatePress(InDeltaTime)
  if not self.IsOnClick then
    return
  end
  self.StartPressTime = self.StartPressTime + InDeltaTime
  if self.StartPressTime >= self.LongPressTime and not self.IsLongPress then
    self.IsLongPress = true
    self.StartPressTime = 0
    _G.NRCAudioManager:PlaySound2DAuto(1377, "UMG_EquipItem_C:Tick")
  end
  if self.IsLongPress then
    self.StartTime = self.StartTime + InDeltaTime
    self.Progress:showAni(self.ScreenPos, self.StartTime, self.EndTime)
    if self.StartTime >= self.EndTime then
      self:LongPressBreak()
      local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BAG, true)
      if not isBan then
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap)
      end
    end
  end
end

function UMG_Compass_C:LongPressBreak()
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.Progress:showEndAni()
end

function UMG_Compass_C:OnClickOpenMap()
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap)
end

function UMG_Compass_C:IsShowCatchPet(npcRefreshId)
  return _G.NRCModuleManager:DoCmd(BigMapModuleCmd.IsShowCatchPet, npcRefreshId)
end

function UMG_Compass_C:OnReLoginUpdate()
  self:UpdateNpc()
end

function UMG_Compass_C:OnPlayCompassAnimation(event_info)
  self.CompassRoot:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.CompassCatchPetIcon == nil then
    self.CompassCatchPetIcon = self:CreateCompItemWidget(self.NpcLayer, self.CompassCatchPetTemplate)
    self.CompassCatchPetIcon:SetIcon()
  end
  if self.CompassCatchPetIcon and event_info.status ~= _G.ProtoEnum.SceneEventStatus.SES_BONUS then
    self.CompassCatchPetIcon:InitData()
    self.CompassCatchPetIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.CompassCatchPetIcon.Slot:SetPosition(UE4.FVector2D(0, 53))
    self.CompassCatchPetIcon:PlayCatchPetEffect(event_info)
  else
    for i, v in pairs(self.NpcIcons) do
      if v:IsCathPet() == true and v:FinshCatchAnimation() == false then
        v:PlayCatchPetEffect(event_info)
      end
    end
  end
end

function UMG_Compass_C:PlayerTeleportFinish()
  self:SetForceUpdatePos(true)
end

function UMG_Compass_C:OnDestruct()
  self.PlayerCameraManager = nil
  self.CompassParts = {}
  self.NpcIcons = {}
  self.MapAreaIcons = {}
  self.MarkIcons = {}
  self.AcceptableTaskIcons = {}
  self.TaskIcons = {}
  self.VisitIcons = {}
  self.CompItemCircle = {}
  self.PetSensing = {}
  self.DistanceLevelInitPos = {}
  self.limitNumTrackTypeToListMap = {}
  self.limitNumTrackTypeToMapIndexMap = {}
  self.forceTrackTypeMap = {}
  self.limitNumTrackTypeSortDirtyMap = {}
  self.limitNumTrackTypeSortedMap = {}
  self._defaultTrackNpcDataChangePending = false
  self:RemoveAllButtonListener()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.LoadMapStart)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnMapLoaded)
  NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnPlayCompassAnimation, self.OnPlayCompassAnimation)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.TASK_DATA_CHANGE, self.UpdateTraceTask)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportFinish, self.PlayerTeleportFinish)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.OnTraceNpcDataChanged, self.OnTraceNpcDataChanged)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.AcceptTaskRefresh, self.UpdateAcceptableTaskData)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.DefaultTrackNpcChange, self.OnDefaultTrackTypeNpcDataChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.STORY_FLAG_ADDED, self.OnStoryFlagAdded)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
end

function UMG_Compass_C:OnNavigationModeUpdate(mode, init)
  if init and not mode then
    self:Hide()
    return
  end
  if self.NavigationMode ~= mode then
    self.NavigationMode = mode
    if self.NavigationMode == ProtoEnum.NavigationModeType.NMT_COMPASS then
      local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_COMPASS, false)
      if not isBan then
        self:Show(mode)
      else
        self:Hide()
      end
    elseif self.NavigationMode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
      self:Hide()
    end
  end
end

function UMG_Compass_C:OnStoryFlagAdded(flag, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flag)
  if bIsHomeOwner == UseSelf then
    return
  end
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule.data then
    local mapStoryFlagList = bigMapModule.data.mapUnlockStoryFlagList
    if mapStoryFlagList and #mapStoryFlagList > 0 then
      for k, v in ipairs(mapStoryFlagList) do
        if flag == v then
          self:UpdateNpc()
          break
        end
      end
    end
  end
end

function UMG_Compass_C:CheckNeedTick(UpdateStep)
  if self.EnableOptimizeMode >= UMG_Compass_C.OptimizeMode.EnableMainOptimize and self.CurrentUpdateStep ~= UpdateStep then
    return false
  end
  return true
end

function UMG_Compass_C:OnTraceNpcDataChanged()
  self:UpdateTraceNpc(true)
end

function UMG_Compass_C:AddToLimitNumTrackTypeCache(logicId, defaultTrackType, curFrameNum)
  if not defaultTrackType or 0 == defaultTrackType then
    return
  end
  if not self.limitNumTrackTypeToListMap[defaultTrackType] then
    self.limitNumTrackTypeToListMap[defaultTrackType] = {}
  end
  if not self.limitNumTrackTypeToMapIndexMap[defaultTrackType] then
    self.limitNumTrackTypeToMapIndexMap[defaultTrackType] = {}
  end
  local list = self.limitNumTrackTypeToListMap[defaultTrackType]
  local map = self.limitNumTrackTypeToMapIndexMap[defaultTrackType]
  if not map[logicId] then
    list[#list + 1] = logicId
    map[logicId] = #list
    self:_SetTrackTypeSortDirty(defaultTrackType, curFrameNum, curFrameNum)
  else
    Log.ErrorFormat("UMG_Compass_C:AddToLimitNumTrackTypeCache unexpected, duplicate logicId: %s, defaultTrackType: %s", tostring(logicId), tostring(defaultTrackType))
  end
end

function UMG_Compass_C:RemoveFromTrackTypeCache(logicId, defaultTrackType, curFrameNum)
  if not defaultTrackType or 0 == defaultTrackType then
    return
  end
  local list = self.limitNumTrackTypeToListMap[defaultTrackType]
  local map = self.limitNumTrackTypeToMapIndexMap[defaultTrackType]
  if not list or not map then
    return
  end
  local idx = map[logicId]
  if not idx or idx <= 0 then
    return
  end
  local lastIdx = #list
  map[logicId] = nil
  if idx < lastIdx then
    local lastLogicId = list[lastIdx]
    list[idx] = lastLogicId
    map[lastLogicId] = idx
  end
  table.remove(list, lastIdx)
  self:_SetTrackTypeSortDirty(defaultTrackType, curFrameNum, curFrameNum)
end

function UMG_Compass_C:_SetTrackTypeSortDirty(trackType, sortFrame, curFrame)
  local oriTargetFrame = self.limitNumTrackTypeSortDirtyMap[trackType]
  if oriTargetFrame and sortFrame <= oriTargetFrame then
    return
  end
  if oriTargetFrame and not self.limitNumTrackTypeSortedMap[trackType] and curFrame < sortFrame and curFrame >= oriTargetFrame then
    self:_SortTrackTypeList(trackType)
  end
  self.limitNumTrackTypeSortDirtyMap[trackType] = sortFrame
  self.limitNumTrackTypeSortedMap[trackType] = nil
end

function UMG_Compass_C:_SortTrackTypeList(trackType)
  self.limitNumTrackTypeSortedMap[trackType] = true
  local list = self.limitNumTrackTypeToListMap[trackType]
  local map = self.limitNumTrackTypeToMapIndexMap[trackType]
  if not list or not map then
    return
  end
  for i = #list, 1, -1 do
    local logicId = list[i]
    if not self.NpcIcons[logicId] then
      local lastIdx = #list
      if i < lastIdx and lastIdx > 0 then
        local lastLogicId = list[lastIdx]
        list[i] = lastLogicId
        map[lastLogicId] = i
      end
      table.remove(list, lastIdx)
      map[logicId] = nil
    end
  end
  if #list > 0 then
    table.sort(list, function(a, b)
      local npcA = self.NpcIcons[a]
      local npcB = self.NpcIcons[b]
      if not npcA then
        return false
      end
      if not npcB then
        return true
      end
      return (npcA.DistanceSquare or math.huge) < (npcB.DistanceSquare or math.huge)
    end)
    for i, logicId in ipairs(list) do
      map[logicId] = i
    end
  end
end

function UMG_Compass_C:IsForceTrackNpc(logicId, defaultTrackType)
  if not defaultTrackType or 0 == defaultTrackType then
    return false
  end
  local conf = self:GetDefaultTrackConf(defaultTrackType)
  if not conf then
    return false
  end
  local npcList = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetDefaultTrackNpcList, defaultTrackType)
  if not npcList or 0 == #npcList then
    return false
  end
  local trackNum = conf.track_num
  local startIdx = math.max(1, #npcList - trackNum + 1)
  for i = startIdx, #npcList do
    if npcList[i].logic_id == logicId then
      return true
    end
  end
  return false
end

function UMG_Compass_C:CanShowByTrackTypeLimit(uiItem, curFrameNum)
  if uiItem.IsTrace then
    return true
  end
  local trackType = uiItem.WorldMapConfig and uiItem.WorldMapConfig.default_track_type or 0
  if trackType <= 0 then
    return true
  end
  local conf = self:GetDefaultTrackConf(trackType)
  if not conf then
    return true
  end
  local showNum = conf.minmap_num - conf.track_num
  if showNum <= 0 then
    return false
  end
  local dirtyFrame = self.limitNumTrackTypeSortDirtyMap[trackType]
  if dirtyFrame and curFrameNum >= dirtyFrame and not self.limitNumTrackTypeSortedMap[trackType] then
    self:_SortTrackTypeList(trackType)
  end
  local map = self.limitNumTrackTypeToMapIndexMap[trackType]
  if not map then
    return false
  end
  local idx = map[uiItem.LogicId]
  if not idx then
    return false
  end
  return showNum >= idx
end

function UMG_Compass_C:OnDefaultTrackTypeNpcDataChange()
  self._defaultTrackNpcDataChangePending = true
end

function UMG_Compass_C:_ProcessDefaultTrackTypeNpcDataChange()
  local curFrameNum = UE4.UNRCStatics.GetCurGFrameNumber()
  for trackType, conf in pairs(self.mapDefaultTrackConfCache) do
    local npcList = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetDefaultTrackNpcList, trackType)
    if not npcList then
    else
      local trackNum = conf.track_num
      local startIdx = math.max(1, #npcList - trackNum + 1)
      local newForceSet = {}
      for i = startIdx, #npcList do
        newForceSet[npcList[i].logic_id] = true
      end
      local oldForceSet = self.forceTrackTypeMap[trackType]
      if oldForceSet then
        for logicId, _ in pairs(oldForceSet) do
          if not newForceSet[logicId] then
            local npcUI = self.NpcIcons[logicId]
            if npcUI then
              npcUI:SetIsShow(false)
              npcUI.fatherLayer = self.NpcLayer
              npcUI:SetTrace(false)
              self:AddToLimitNumTrackTypeCache(logicId, trackType, curFrameNum)
            end
          end
        end
      end
      for logicId, _ in pairs(newForceSet) do
        if not oldForceSet or not oldForceSet[logicId] then
          local npcUI = self.NpcIcons[logicId]
          if npcUI then
            npcUI:SetIsShow(false)
            npcUI.fatherLayer = self.TraceNpcLayer
            npcUI:SetTrace(true, nil, 1, false)
            self:RemoveFromTrackTypeCache(logicId, trackType, curFrameNum)
          end
        end
      end
      self.forceTrackTypeMap[trackType] = newForceSet
    end
  end
end

function UMG_Compass_C:AddToForceTrackMap(logicId, defaultTrackType)
  if not defaultTrackType or 0 == defaultTrackType then
    return
  end
  if not self.forceTrackTypeMap[defaultTrackType] then
    self.forceTrackTypeMap[defaultTrackType] = {}
  end
  self.forceTrackTypeMap[defaultTrackType][logicId] = true
end

function UMG_Compass_C:InitMapDefaultTrackConfCache()
  local allConfs = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.WORLD_MAP_DEFAULT_TRACK):GetAllDatas()
  for _, conf in pairs(allConfs) do
    if conf.track_type and conf.track_type > 0 then
      self.mapDefaultTrackConfCache[conf.track_type] = conf
    end
  end
end

function UMG_Compass_C:GetDefaultTrackConf(defaultTrackType)
  if not defaultTrackType or 0 == defaultTrackType then
    return nil
  end
  return self.mapDefaultTrackConfCache[defaultTrackType]
end

return UMG_Compass_C

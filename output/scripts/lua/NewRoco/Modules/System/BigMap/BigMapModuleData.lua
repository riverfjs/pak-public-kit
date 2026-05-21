local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local bigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local BigMapModuleData = _G.NRCData:Extend("BigMapModuleData")
BigMapModuleData.TotalPieceCount = 16

function BigMapModuleData:Ctor()
  NRCData.Ctor(self)
  self.cachedSceneIdsForSetUnlockDeadwoodList = {}
end

function BigMapModuleData:InitData()
  self.ShopRspData = nil
  self.npcTipsShowType = nil
  self.mapConstData = {}
  self.AreaIdToRefreshId = {}
  self.RefreshIdToAreaIds = {}
  self.npcIdToExploreInfo = {}
  self.owlRefreshIdToMapEntryId = nil
  self.mapUnlockStoryFlagList = {}
  self.worldExploredInfo = {}
  self.campChallengeNpcInfo = {}
  self.layerIdToIcons = {}
  self.curShowLayerId = 0
  local areaDatas = {}
  local MapDatas = {}
  self.checkDeadWoodList = {}
  self.clientNpcList = {}
  self.sceneResIdToBlockConf = {}
  self.refreshIdToWorldMapConfId = {}
  self:BuildSceneResIdToBlockMap()
  self:SetMapConstData()
  local bigMapDatas = {}
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_CONF)
  local cfgDatas = cfgTable:GetAllDatas()
  for _, dataInfo in pairs(cfgDatas) do
    if 0 ~= dataInfo.id then
      if dataInfo.npc_refresh_ids and #dataInfo.npc_refresh_ids > 0 then
        for key, _refreshId in ipairs(dataInfo.npc_refresh_ids) do
          self.refreshIdToWorldMapConfId[_refreshId] = dataInfo.id
        end
      end
      if dataInfo.unlock_zone and #dataInfo.unlock_zone > 0 and dataInfo.unlock_zone[1] > 0 then
        if dataInfo.npc_refresh_ids and #dataInfo.npc_refresh_ids > 0 then
          for k, v in ipairs(dataInfo.npc_refresh_ids) do
            self.RefreshIdToAreaIds[v] = dataInfo.unlock_zone
          end
        end
        for k, v in ipairs(dataInfo.unlock_zone) do
          self.AreaIdToRefreshId[v] = dataInfo.npc_refresh_ids[1]
          local areaConf = _G.DataConfigManager:GetAreaConf(v)
          if areaConf and areaConf.scene_res_id > 0 then
            if nil == self.checkDeadWoodList[areaConf.scene_res_id] then
              self.checkDeadWoodList[areaConf.scene_res_id] = {}
            end
            table.insert(self.checkDeadWoodList[areaConf.scene_res_id], v)
          end
        end
      end
      if dataInfo.storyflag_id and dataInfo.storyflag_id > 0 then
        table.insert(self.mapUnlockStoryFlagList, dataInfo.storyflag_id)
      end
      local showLocationType = dataInfo.map_show_location
      if showLocationType and showLocationType ~= Enum.MapIconShowLocation.MISL_BIGWORLD then
        if nil == self.clientNpcList[showLocationType] then
          self.clientNpcList[showLocationType] = {}
        end
        table.insert(self.clientNpcList[showLocationType], dataInfo)
      end
      if not dataInfo.is_invisible or 0 == dataInfo.is_invisible then
        if dataInfo.map_show_type == Enum.MapIconShowType.MAP_NPC or dataInfo.map_show_type == Enum.MapIconShowType.MAP_NPC_DAZZLING or dataInfo.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING or dataInfo.map_show_type == Enum.MapIconShowType.MAP_NPC_SHINING or dataInfo.map_show_type == Enum.MapIconShowType.MAP_NPC_SHINING_DAZZLING or dataInfo.map_show_type == Enum.MapIconShowType.MAP_SHINING_SEASON_DAZZLING or dataInfo.map_show_type == Enum.MapIconShowType.MAP_SHINING_CHAOS or dataInfo.map_show_type == Enum.MapIconShowType.MAP_HOME_PET_TRACK then
          bigMapDatas[dataInfo.id] = dataInfo
          if dataInfo.npc_refresh_ids and #dataInfo.npc_refresh_ids > 0 then
            for _, v in ipairs(dataInfo.npc_refresh_ids) do
              bigMapDatas[v] = dataInfo
              MapDatas[v] = dataInfo
            end
          elseif dataInfo.npc_conf_id then
            MapDatas[dataInfo.npc_conf_id] = dataInfo
          end
        elseif dataInfo.map_show_type == Enum.MapIconShowType.MAP_HOME_PET_TRACK then
          bigMapDatas[dataInfo.id] = dataInfo
        elseif dataInfo.map_show_type == Enum.MapIconShowType.MAP_AREA then
          bigMapDatas[dataInfo.id] = dataInfo
          MapDatas[dataInfo.id] = dataInfo
        elseif dataInfo.map_show_type == Enum.MapIconShowType.MAP_AREA_NPC then
          bigMapDatas[dataInfo.id] = dataInfo
          if dataInfo.npc_refresh_ids and #dataInfo.npc_refresh_ids > 0 then
            for _, v in ipairs(dataInfo.npc_refresh_ids) do
              bigMapDatas[v] = dataInfo
              MapDatas[v] = dataInfo
            end
          elseif dataInfo.npc_conf_id then
            MapDatas[dataInfo.npc_conf_id] = dataInfo
          end
        elseif dataInfo.map_show_type == Enum.MapIconShowType.MAP_BTEXT then
          local areaCfg = _G.DataConfigManager:GetAreaConf(dataInfo.name_area_id)
          if areaCfg and areaCfg.pos[1] then
            local cfgPosX = areaCfg.pos[1].position_xyz[1]
            local cfgPosY = areaCfg.pos[1].position_xyz[2]
            local sceneResId = BigMapUtils.GetSceneResIdByPos(cfgPosX, cfgPosY)
            local mapPieceId = BigMapUtils.GetMapPieceIdByPos(cfgPosX, cfgPosY, sceneResId)
            if nil == areaDatas[sceneResId] then
              areaDatas[sceneResId] = {}
            end
            if nil == areaDatas[sceneResId][mapPieceId] then
              areaDatas[sceneResId][mapPieceId] = {}
            end
            areaDatas[sceneResId][mapPieceId][dataInfo.id] = {
              config = dataInfo,
              cfgPosX = areaCfg.pos[1].position_xyz[1],
              cfgPosY = areaCfg.pos[1].position_xyz[2]
            }
          end
        elseif dataInfo.map_show_type == Enum.MapIconShowType.MAP_CREATE_MAGIC or dataInfo.map_show_type == Enum.MapIconShowType.MAP_HANDBOOK_TRACK or dataInfo.map_show_type == Enum.MapIconShowType.MAP_ACTIVITY_AREA then
          bigMapDatas[dataInfo.id] = dataInfo
        else
          Log.Debug("\233\156\128\232\166\129\230\139\147\229\177\149\229\175\185\229\186\148\233\128\187\232\190\145")
        end
      end
    end
  end
  self.infoBarTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.MAP_INFO_BAR_CONF):GetAllDatas()
  self.bReceivedSyncBeginRsp = false
  self.areaDatas = areaDatas
  self.bigMapDatas = bigMapDatas
  self.AllMapDatas = MapDatas
  self.traceNpcInfo = {}
  self.traceInfoList = {}
  self.mapShowDatas = {}
  self.unlockNpcArea = {}
  self.mapAreaDatas = {}
  self.unlockMapAreaDatas = {}
  self.npcDatas = {}
  self.npcDatasByWorldMapCfgId = {}
  self.curSelectIconInfo = {
    type = 0,
    iconInfo = {}
  }
  self.autoTrackNpcList = {}
  self.VisitPlayerInfo = {}
  self.homePetInfo = {}
  self.unLockMapBlockId = {}
  self.MapShowList = {}
  self.lastShowSceneResId = 10003
  self.curShowSceneResId = 10003
  self.lastDrawMaskSceneResId = 0
  self.SceneResIdToIndex = {}
  self:InitSceneResIdToIndex()
  self.AreaToMapIndex = {}
  self.behindSquare = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.WORLD_MAP_AREA_GUIDE):GetAllDatas()
  self.AccessTaskInfoList = {}
  self.JourneyTaskInfo = {}
  self.showTaskInfo = {}
  self.ShowTaskPanelInfo = {}
  self.OpenTaskId = nil
  self.SelectTaskId = nil
  self.CampFruitNpcsInfoList = {}
  self.TotalCampSpriteList = {}
  self.ParentTaskList = {}
  self.HandBookTraceInfo = nil
  self.CustomPointInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMarkInfo() or {}
  self.NewCustomPointInfo = {}
  self.SelectMarkerType = nil
  self.changed_entries = {}
  self.CompassShowDistance = _G.DataConfigManager:GetMapGlobalConfig("oneself_mark_delete_distance").num
  self.npcRefreshContentDatas = {}
  local npcRefreshContentTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NPC_REFRESH_CONTENT_CONF)
  if npcRefreshContentTable then
    self.npcRefreshContentDatas = npcRefreshContentTable:GetAllDatas()
  end
  local owlSanctuaryTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.OWL_SANCTUARY_CONF)
  if owlSanctuaryTable then
    self.owlSanctuaryDatas = owlSanctuaryTable:GetAllDatas()
  end
  self.GuideBooksRedDot = {}
  self.UnlockDeadwoodList = {}
  self.DrawList = {}
  self.isOpenTravel = false
  self.PlayerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
  self:SetRedDotByGuideBooks()
  self.FullMaskRunTime = nil
  self:LoadMaskTexture()
  self.sanctuaryChildItemDic = {}
  self.mapShowNpc = {}
  self.miniMapShowNpc = {}
  self.mapShowAreaNpc = {}
  self.miniMapShowAreaNpc = {}
  self.AreaFuncIdToLayerInfo = {}
  self.LayerGroupIdToLayerMapIds = {}
  self.AreaIdToAreaFuncId = {}
  self.LogicIdToNpcInfo = {}
  self.MapIdToMapActivityConf = {}
  self.areaFuncIdToMapActivityConf = {}
  self:BuildAreaFuncIdToLayerMapInfo()
  self:BuildLayerGroupIdToLayerMapIds()
  self:BuildAreaIdToAreaFuncIdMap()
  self:BuildNpcIdToExploreInfo()
  self:BuildMapIdToMapActivityConf()
  self.bNeedClearFakeData = false
  self.entryIdToSceneResIdAndPieceId = {}
  self.defaultTrackNpcMap = {}
end

function BigMapModuleData:LoadMaskTexture()
  if self.FullMaskRunTime == nil then
    self.FullMaskRunTime = LoadObject("/Game/NewRoco/Modules/System/BigMap/Raw/AreaMask/FullMaskRunTime.FullMaskRunTime")
    self.DrawList = {}
    UE4.UNRCStatics.AddToRoot(self.FullMaskRunTime)
  end
end

function BigMapModuleData:ClearMaskTexture()
  if self.FullMaskRunTime then
    UE4.UNRCStatics.RemoveFromRoot(self.FullMaskRunTime)
    self.FullMaskRunTime:Release()
    self.FullMaskRunTime = nil
    self.DrawList = {}
  end
end

function BigMapModuleData:SetRedDotByGuideBooks()
  local GuideBooksRedDotInfo = JsonUtils.LoadSaved(self.PlayerName, {})
  local guidebookInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerGuide_BooksInfo()
  if guidebookInfo and #guidebookInfo > 0 then
    for i, guidbook in ipairs(guidebookInfo) do
      local WorldMapAreaGuide = _G.DataConfigManager:GetWorldMapAreaGuide(guidbook.id)
      if GuideBooksRedDotInfo[WorldMapAreaGuide.area_func_id[1]] == nil then
        GuideBooksRedDotInfo[WorldMapAreaGuide.area_func_id[1]] = {IsShowRedDot = true}
      end
    end
  end
  self.GuideBooksRedDot = GuideBooksRedDotInfo
end

function BigMapModuleData:DumpRedDotByGuideBooks()
  JsonUtils.DumpSaved(self.PlayerName, self.GuideBooksRedDot)
end

function BigMapModuleData:InitSceneResIdToIndex()
  local table = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_BLOCK_CONF)
  local data = table:GetAllDatas()
  for _, conf in pairs(data) do
    self.SceneResIdToIndex[conf.scene_res_id] = conf.list_order
  end
end

function BigMapModuleData:GetWorldMapDatas()
  return self.bigMapDatas
end

function BigMapModuleData:ClearMapAreaDatas()
  self.mapAreaDatas = {}
end

function BigMapModuleData:GetMapAreaDatas(sceneResId)
  return self.mapAreaDatas
end

function BigMapModuleData:GetAreaDatas(sceneResId)
  return self.areaDatas[sceneResId]
end

function BigMapModuleData:ClearNpcDatas()
  self.npcDatas = {}
  self.npcDatasByWorldMapCfgId = {}
  self.mapShowNpc = {}
  self.miniMapShowNpc = {}
  self.mapShowAreaNpc = {}
  self.miniMapShowAreaNpc = {}
  self.defaultTrackNpcMap = {}
  self:ClearEntryIdMap()
end

function BigMapModuleData:GetNpcDatas(sceneResId)
  sceneResId = sceneResId or self.curShowSceneResId
  return self.npcDatas[sceneResId]
end

function BigMapModuleData:GetNpcData(sceneResId, mapPieceId, entryId, logicId)
  if self.npcDatas[sceneResId] and self.npcDatas[sceneResId][mapPieceId] and self.npcDatas[sceneResId][mapPieceId][entryId] then
    return self.npcDatas[sceneResId][mapPieceId][entryId][logicId]
  end
end

function BigMapModuleData:AddNpcData(sceneResId, mapPieceId, entryId, logicId, npcInfo)
  if self.npcDatas[sceneResId] == nil then
    self.npcDatas[sceneResId] = {}
  end
  if self.npcDatas[mapPieceId] == nil then
    self.npcDatas[sceneResId][mapPieceId] = {}
  end
  if self.npcDatas[sceneResId][mapPieceId][entryId] == nil then
    self.npcDatas[sceneResId][mapPieceId][entryId] = {}
  end
  self.npcDatas[sceneResId][mapPieceId][entryId][logicId] = npcInfo
end

function BigMapModuleData:GetNpcDatasByWorldMapCfgId(worldMapCfgId)
  return self.npcDatasByWorldMapCfgId[worldMapCfgId]
end

function BigMapModuleData:AddNpcDataByWorldMapCfgId(npcData)
  if not npcData or not npcData.world_map_cfg_id then
    return
  end
  local worldMapCfgId = npcData.world_map_cfg_id
  if not self.npcDatasByWorldMapCfgId[worldMapCfgId] then
    self.npcDatasByWorldMapCfgId[worldMapCfgId] = {}
  end
  table.insert(self.npcDatasByWorldMapCfgId[worldMapCfgId], npcData)
end

function BigMapModuleData:RemoveNpcDataByWorldMapCfgId(npcData)
  if not npcData or not npcData.world_map_cfg_id then
    return
  end
  local worldMapCfgId = npcData.world_map_cfg_id
  local dataList = self.npcDatasByWorldMapCfgId[worldMapCfgId]
  if dataList then
    for i = #dataList, 1, -1 do
      if dataList[i].entry_id == npcData.entry_id then
        table.remove(dataList, i)
        break
      end
    end
    if 0 == #dataList then
      self.npcDatasByWorldMapCfgId[worldMapCfgId] = nil
    end
  end
end

function BigMapModuleData:ClearNpcDatasByWorldMapCfgId(worldMapCfgId)
  if worldMapCfgId then
    self.npcDatasByWorldMapCfgId[worldMapCfgId] = nil
  end
end

function BigMapModuleData:SetCurSelectedIconInfo(type, iconInfo)
  self.curSelectIconInfo.type = type
  self.curSelectIconInfo.iconInfo = iconInfo
end

function BigMapModuleData:GetCurSelectedIconInfo()
  return self.curSelectIconInfo
end

function BigMapModuleData:SetAutoTrackNpcList(npcList)
  if npcList and #npcList > 0 then
    for k, v in ipairs(npcList) do
      self.autoTrackNpcList[v.npc_logic_id] = v
    end
  end
end

function BigMapModuleData:OnAutoTrackNpcListChanged(bAdd, npcData)
  if bAdd then
    local logicId = npcData.npc_logic_id or npcData.logic_id
    if logicId then
      self.autoTrackNpcList[logicId] = npcData
    end
  else
    table.removeKey(self.autoTrackNpcList, npcData)
  end
end

function BigMapModuleData:CheckAutoTrackingByLogicId(logicId)
  if self.autoTrackNpcList[logicId] then
    return true
  end
  return false
end

function BigMapModuleData:GetVisitPointInfo()
  if not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    return {}
  else
    return self.VisitPlayerInfo
  end
end

function BigMapModuleData:GetHomePetNpcInfo()
  return self.homePetInfo
end

function BigMapModuleData:SetVisitPointInfo(list)
  self.VisitPlayerInfo = list
end

function BigMapModuleData:UpdateMapShowNpc(sceneResId, mapPieceId, bShow, npcInfo, entryId, logicId)
  sceneResId = sceneResId or SceneUtils.GetSceneResId()
  local mapPiece = mapPieceId or 0
  if npcInfo then
    logicId = logicId or npcInfo.logic_id or entryId or logicId or npcInfo.entry_id
  else
    logicId = entryId
  end
  if bShow then
    local _entryId = npcInfo.entry_id
    local _logicId = npcInfo.logic_id or _entryId
    if self:CheckShouldShowNpc(npcInfo) then
      if self.mapShowNpc[sceneResId] == nil then
        self.mapShowNpc[sceneResId] = {}
      end
      if self.mapShowNpc[sceneResId][mapPiece] == nil then
        self.mapShowNpc[sceneResId][mapPiece] = {}
      end
      if self.mapShowNpc[sceneResId][mapPiece][_entryId] == nil then
        self.mapShowNpc[sceneResId][mapPiece][_entryId] = {}
      end
      self.mapShowNpc[sceneResId][mapPiece][_entryId][_logicId] = npcInfo
    end
  elseif self.mapShowNpc[sceneResId] and self.mapShowNpc[sceneResId][mapPiece] and 0 ~= entryId then
    local tempNpcInfos = self.mapShowNpc[sceneResId][mapPiece][entryId]
    if tempNpcInfos then
      local tempNpcInfo = tempNpcInfos[logicId]
      if tempNpcInfo then
        table.removeKey(self.mapShowNpc[sceneResId][mapPiece][entryId], logicId)
        if table.isEmpty(tempNpcInfo) then
          table.removeKey(self.mapShowNpc[sceneResId][mapPiece], entryId)
        end
      end
    end
  end
end

function BigMapModuleData:SetAllMapShowNpcs()
  self:ClearLayerIdToIconsByType(bigMapModuleEnum.CreatorPriority.NpcIcons)
  for sceneResId, npcInfos in pairs(self.npcDatas) do
    self:SetAllShowNpcs(sceneResId)
  end
end

function BigMapModuleData:SetAllMapShowAreaNpcs()
  self:SetAllShowAreaNpcs()
end

function BigMapModuleData:SetAllShowNpcs(sceneResId)
  local _npcInfos = self:GetNpcDatas(sceneResId)
  local npcInfo = {}
  if not _npcInfos then
    return nil
  end
  for mapPieceId, j in pairs(_npcInfos) do
    for entryId, entryList in pairs(j) do
      if nil == npcInfo[mapPieceId] then
        npcInfo[mapPieceId] = {}
      end
      for logicId, _npcInfo in pairs(entryList) do
        local shouldShow = self:CheckShouldShowNpc(_npcInfo)
        if shouldShow then
          if nil == npcInfo[mapPieceId][entryId] then
            npcInfo[mapPieceId][entryId] = {}
          end
          npcInfo[mapPieceId][entryId][logicId] = _npcInfo
        end
      end
    end
  end
  self.mapShowNpc[sceneResId] = npcInfo
end

function BigMapModuleData:SetAllShowAreaNpcs()
  local mapArea = {}
  local mapAreaInfos = self:GetMapAreaDatas()
  for i, v in pairs(mapAreaInfos) do
    local worldMap = self.bigMapDatas[v.world_map_cfg_id]
    local shouldShow = false
    if worldMap then
      if v.unlocked then
        shouldShow = 1 == worldMap.explored_in_map and worldMap.areaicon_explore
      else
        shouldShow = 1 == worldMap.unexplored_in_map and worldMap.areaicon_unexplore
      end
      if shouldShow then
        mapArea[i] = v
      end
    end
  end
  self.mapShowAreaNpc = mapArea
end

function BigMapModuleData:GetAllShowNpcs(sceneResId)
  return self.mapShowNpc[sceneResId]
end

function BigMapModuleData:GetAllShowAreaNpcs()
  return self.mapShowAreaNpc
end

function BigMapModuleData:CheckShouldShowNpc(npcInfo)
  local WorldMapConfigs = self:GetWorldMapDatas()
  local worldMap = WorldMapConfigs[npcInfo.world_map_cfg_id] or WorldMapConfigs[npcInfo.npc_refresh_id]
  local shouldShow = false
  local model
  local confLayerId = 0
  local refreshId = npcInfo.npc_refresh_id
  if npcInfo.npcCfg and npcInfo.npcCfg.model_conf > 0 then
    model = _G.DataConfigManager:GetModelConf(npcInfo.npcCfg.model_conf)
  end
  if worldMap then
    local bTracing = self.module:CheckIsTracing(bigMapModuleEnum.TraceType.NPC, npcInfo.entry_id, npcInfo.logic_id)
    if worldMap.is_hide_init then
      if bTracing then
        shouldShow = true
      else
        shouldShow = false
      end
    elseif worldMap.map_show_type == _G.ProtoEnum.MapIconShowType.MAP_AREA_NPC then
      if self.unlockMapAreaDatas[npcInfo.world_map_cfg_id] == true and npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        shouldShow = 1 == worldMap.explored_in_map
      else
        shouldShow = 1 == worldMap.unexplored_in_map
      end
    elseif npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
      shouldShow = 1 == worldMap.explored_in_map and model.ui_icon
    else
      shouldShow = 1 == worldMap.unexplored_in_map and model.ui_icon
    end
  else
    local worldMap1 = WorldMapConfigs[npcInfo.world_map_cfg_id]
    if worldMap1 then
      local bTracing = self.module:CheckIsTracing(bigMapModuleEnum.TraceType.NPC, npcInfo.entry_id, npcInfo.logic_id)
      if worldMap.is_hide_init then
        if bTracing then
          shouldShow = true
        else
          shouldShow = false
        end
      elseif npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
        shouldShow = 1 == worldMap1.explored_in_map and model.ui_icon
      else
        shouldShow = 1 == worldMap1.unexplored_in_map and (worldMap1.npcicon_lock or model and model.ui_icon)
      end
    end
  end
  if shouldShow then
    local layerId = self:GetLayerId(confLayerId, refreshId, npcInfo)
    self:SetLayerIdToIcons(layerId, bigMapModuleEnum.CreatorPriority.NpcIcons, npcInfo.entry_id, npcInfo.logic_id)
  end
  return shouldShow
end

function BigMapModuleData:AddUnlockMapBlockId(blockId)
  if type(blockId) == "table" then
    self.unLockMapBlockId = blockId
  else
    local hasSame = false
    for k, v in ipairs(self.unLockMapBlockId) do
      if v == blockId then
        hasSame = true
      end
    end
    if false == hasSame then
      table.insert(self.unLockMapBlockId, blockId)
      DataModelMgr.PlayerDataModel:UpdateNewUnlockMapInfo(blockId)
    end
  end
  _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.OnNewMapUnlocked)
end

function BigMapModuleData:SetMapShowList()
  self.MapShowList = {}
  local mapBlockCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_BLOCK_CONF):GetAllDatas()
  if self.unLockMapBlockId and #self.unLockMapBlockId > 0 then
    for k, v in ipairs(self.unLockMapBlockId) do
      local blockConf = mapBlockCfg[v]
      local centerAreaId = self:GetMapCenterAreaIdByBlockId(v)
      table.insert(self.MapShowList, {
        name = blockConf.list_name,
        sceneResId = blockConf.scene_res_id,
        minScale = blockConf.min_scale,
        maxScale = blockConf.max_scale,
        initScale = blockConf.switch_map_fix_scale,
        centerAreaId = centerAreaId,
        tableId = k,
        ComType = CommonBtnEnum.ComboBoxType.BigMap,
        Conf = blockConf,
        mapRedDotExtraKey = v
      })
    end
  else
    for k, v in ipairs(mapBlockCfg) do
      if 1 == v.is_initial_unlock then
        local centerAreaId = self:GetMapCenterAreaIdByBlockId(v.id)
        table.insert(self.MapShowList, {
          name = v.list_name,
          sceneResId = v.scene_res_id,
          minScale = v.min_scale,
          maxScale = v.max_scale,
          initScale = v.switch_map_fix_scale,
          centerAreaId = centerAreaId,
          tableId = k,
          ComType = CommonBtnEnum.ComboBoxType.BigMap,
          Conf = v
        })
      end
    end
  end
end

function BigMapModuleData:GetMapCenterAreaIdByBlockId(blockId)
  if blockId and blockId > 0 then
    local mapBlockConf = DataConfigManager:GetWorldMapBlockConf(blockId)
    if mapBlockConf then
      local switchType = mapBlockConf.map_switch_fix_point
      if switchType then
        if switchType == Enum.MapSwitchFixPoint.MSFP_POINT then
          if mapBlockConf.para1 and #mapBlockConf.para1 > 0 then
            return mapBlockConf.para1[1]
          end
        elseif switchType == Enum.MapSwitchFixPoint.MSFP_HOME then
          local roomLevel = _G.HomeIndoorSandbox.Server:GetHomeRoomLevel()
          if mapBlockConf.para2 and roomLevel <= #mapBlockConf.para2 and roomLevel > 0 then
            return mapBlockConf.para2[roomLevel]
          end
        end
      end
    end
  end
  return nil
end

function BigMapModuleData:UpdateHeroInfo(_heroInfo)
end

function BigMapModuleData:UpdateAreaInfo(_areaInfo)
  if not _areaInfo then
    return
  end
  local areaData = self.areaDatas[_areaInfo.world_map_cfg_id]
  for sceneResId, areaDatas in pairs(self.areaDatas) do
    for mapPieceId, areaNameData in pairs(areaDatas) do
      if areaNameData[_areaInfo.world_map_cfg_id] then
        areaData = areaNameData[_areaInfo.world_map_cfg_id]
      end
    end
  end
  if not areaData then
    return
  end
  local curCount = 0
  local collectionRate = 0
  local npcList = {}
  local WorldMapNpcStatusCaught = ProtoEnum.WorldMapPetStatus.ENUM.Caught
  local maxCount = _areaInfo.pet_infos and #_areaInfo.pet_infos or 0
  for i = 1, maxCount do
    local npcId = _areaInfo.pet_infos[i].petbase_cfg_id or 0
    local npcStatus = _areaInfo.pet_infos[i].pet_status or ProtoEnum.WorldMapPetStatus.ENUM.NotMet
    if npcStatus == WorldMapNpcStatusCaught then
      curCount = curCount + 1
    end
    table.insert(npcList, {npcId = npcId, npcStatus = npcStatus})
  end
  if maxCount > 0 then
    collectionRate = math.floor(curCount / maxCount * 100)
  end
  areaData.npcList = npcList
  areaData.collectionRate = collectionRate
end

function BigMapModuleData:SeperatedBySceneResId(info)
  local tempSceneResId = 0
  if info.world_map_npc_infos and #info.world_map_npc_infos > 0 then
    local npcPosX = info.world_map_npc_infos[1].npc_pos.x
    local npcPosY = info.world_map_npc_infos[1].npc_pos.y
    local npcRefreshId = info.world_map_npc_infos[1].npc_refresh_id
    if npcRefreshId and npcRefreshId > 0 then
      tempSceneResId = BigMapUtils.GetSceneResIdByRefreshId(npcRefreshId)
    end
    local sceneResId = BigMapUtils.GetSceneResIdByPos(npcPosX, npcPosY, tempSceneResId)
    local mapPieceId = BigMapUtils.GetMapPieceIdByPos(npcPosX, npcPosY, sceneResId)
    return sceneResId, mapPieceId
  elseif info.npc_pos then
    local npcPosX = info.npc_pos.x
    local npcPosY = info.npc_pos.y
    local npcRefreshId = info.npc_refresh_id
    if npcRefreshId and npcRefreshId > 0 then
      tempSceneResId = BigMapUtils.GetSceneResIdByRefreshId(npcRefreshId)
    end
    local sceneResId = BigMapUtils.GetSceneResIdByPos(npcPosX, npcPosY, tempSceneResId)
    local mapPieceId = BigMapUtils.GetMapPieceIdByPos(npcPosX, npcPosY, sceneResId)
    return sceneResId, mapPieceId
  elseif info.pos then
    local npcPosX = info.pos.x
    local npcPosY = info.pos.y
    local sceneResId = BigMapUtils.GetSceneResIdByPos(npcPosX, npcPosY)
    local mapPieceId = BigMapUtils.GetMapPieceIdByPos(npcPosX, npcPosY, sceneResId)
    return sceneResId, mapPieceId
  end
  return 10003, 0
end

function BigMapModuleData:GetLayerId(confLayerId, refreshId, npcInfo)
  local mapConfLayerId = 0
  if confLayerId and confLayerId > 0 then
    mapConfLayerId = confLayerId
  else
    local worldMapConf = npcInfo.worldMapConf
    if worldMapConf and worldMapConf.layered_id and #worldMapConf.layered_id > 0 then
      mapConfLayerId = worldMapConf.layered_id[1]
    end
    if 0 == mapConfLayerId and refreshId and refreshId > 0 then
      local refreshContentConf = DataConfigManager:GetNpcRefreshContentConf(refreshId)
      if refreshContentConf then
        local areaId = refreshContentConf.refresh_param
        if areaId and areaId > 0 then
          local areaFuncId = self.AreaIdToAreaFuncId[areaId]
          if areaFuncId and areaFuncId > 0 then
            local layerInfo = self.AreaFuncIdToLayerInfo[areaFuncId]
            if layerInfo then
              mapConfLayerId = layerInfo.id
            end
          end
        end
      end
    end
  end
  return mapConfLayerId
end

function BigMapModuleData:ClearLayerIdToIconsByType(type)
  if self.layerIdToIcons then
    for layerId, layerIconInfo in pairs(self.layerIdToIcons) do
      table.clear(layerIconInfo[type])
    end
  end
end

function BigMapModuleData:SetLayerIdToIcons(layerId, type, iconKey, extraKey)
  if self.layerIdToIcons[layerId] == nil then
    self.layerIdToIcons[layerId] = {}
  end
  if self.layerIdToIcons[layerId][type] == nil then
    self.layerIdToIcons[layerId][type] = {}
  end
  if self.layerIdToIcons[layerId][type][iconKey] == nil then
    self.layerIdToIcons[layerId][type][iconKey] = {}
  end
  extraKey = extraKey or iconKey
  table.insert(self.layerIdToIcons[layerId][type][iconKey], extraKey)
end

function BigMapModuleData:SeparatedTaskBySceneResId(taskInfo)
  if taskInfo.NpcPosition and #taskInfo.NpcPosition > 0 then
    local taskPosX = taskInfo.NpcPosition[1].pos.x
    local taskPosY = taskInfo.NpcPosition[1].pos.y
    return BigMapUtils.GetSceneResIdByPos(taskPosX, taskPosY)
  end
  return 10003
end

function BigMapModuleData:SeparatedTaskByGuideList(TaskSceneResId, CurSceneResId, TaskShowType)
  if TaskShowType == bigMapModuleEnum.TaskShowType.UNDO then
    return false
  end
  if TaskSceneResId and CurSceneResId and TaskSceneResId == CurSceneResId then
    return true
  end
  return false
end

function BigMapModuleData:UpdateMapAreaInfo(_areaInfo)
  if _areaInfo then
    if self.unlockMapAreaDatas[_areaInfo.world_map_cfg_id] == nil then
      self.unlockMapAreaDatas[_areaInfo.world_map_cfg_id] = {}
    end
    self.unlockMapAreaDatas[_areaInfo.world_map_cfg_id] = true
    local mapArea = self.mapAreaDatas[_areaInfo.world_map_cfg_id]
    local pos
    local validPos = false
    local worldMap = self.bigMapDatas[_areaInfo.world_map_cfg_id]
    if worldMap then
      if mapArea and mapArea.area_pos then
        pos = mapArea.area_pos
        validPos = mapArea.IsValid
      elseif worldMap.map_show_type == Enum.MapIconShowType.MAP_AREA_NPC or worldMap.map_show_type == Enum.MapIconShowType.MAP_NPC then
        pos = _G.FVectorZero
        for _, v in pairs(self.npcDatas) do
          for i = 1, #worldMap.npc_refresh_ids do
            if v.npc_refresh_id == worldMap.npc_refresh_ids[i] then
              pos = UE4.FVector(v.npc_pos.x, v.npc_pos.y, v.npc_pos.z)
              validPos = true
            end
          end
        end
      else
        local area = _G.DataConfigManager:GetAreaConf(worldMap.name_area_id)
        if area and area.pos[1] then
          pos = UE4.FVector(area.pos[1].position_xyz[1], area.pos[1].position_xyz[2], area.pos[1].position_xyz[3])
          validPos = true
        end
      end
    end
    if pos then
      if not mapArea then
        mapArea = {}
        self.mapAreaDatas[_areaInfo.world_map_cfg_id] = mapArea
      elseif _areaInfo.have_explored and not mapArea.unlocked then
        mapArea.isNewUnLock = true
      end
      mapArea.world_map_cfg_id = _areaInfo.world_map_cfg_id
      mapArea.area_pos = pos
      mapArea.IsValid = validPos
      mapArea.unlocked = _areaInfo.have_explored
      if mapArea.npcList and #mapArea.npcList > 0 then
        local sceneResId, mapPieceId = self:SeperatedBySceneResId(mapArea.npcList[1])
        if mapArea.unlocked and mapArea.npcList then
          local npcData = self:UpdateSingleNpcInfo(mapArea.npcId, mapArea.npcList[1], worldMap, sceneResId, mapPieceId)
          if nil == npcData.isNewUnLock then
            npcData.isNewUnLock = false
          end
        end
      end
    end
  end
end

function BigMapModuleData:UpdateNpcInfo(_entryId, npcInfos, bAll)
  if npcInfos and npcInfos.world_map_npc_infos and #npcInfos.world_map_npc_infos > 0 then
    local worldMap = self.bigMapDatas[npcInfos.world_map_cfg_id]
    local mapArea = self.mapAreaDatas[npcInfos.world_map_cfg_id]
    if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
      if self.owlRefreshIdToMapEntryId == nil then
        self.owlRefreshIdToMapEntryId = {}
      end
      if npcInfos.world_map_npc_infos and #npcInfos.world_map_npc_infos > 0 then
        local refreshContentId = 0
        refreshContentId = npcInfos.world_map_npc_infos[1].npc_refresh_id
        if self.owlRefreshIdToMapEntryId[refreshContentId] == nil then
          self.owlRefreshIdToMapEntryId[refreshContentId] = {}
        end
        self.owlRefreshIdToMapEntryId[refreshContentId] = _entryId
      end
      return
    end
    if worldMap and worldMap.map_show_type == Enum.MapIconShowType.MAP_HANDBOOK_TRACK then
      return
    end
    local bUnlocked = false
    if mapArea then
      if mapArea.unlocked then
        bUnlocked = mapArea.unlocked
      else
        bUnlocked = true
      end
    end
    if not (not mapArea or bUnlocked) or not mapArea and worldMap and worldMap.map_show_type == Enum.MapIconShowType.MAP_AREA_NPC then
      if not mapArea then
        mapArea = {}
        self.mapAreaDatas[npcInfos.world_map_cfg_id] = mapArea
      end
      if npcInfos.world_map_npc_infos and #npcInfos.world_map_npc_infos > 0 then
        local npc = npcInfos.world_map_npc_infos[1]
        mapArea.area_pos = UE4.FVector(npc.npc_pos.x, npc.npc_pos.y, npc.npc_pos.z)
        mapArea.IsValid = true
      end
    else
      local entryIdMap = self:GetEntryIdMap(_entryId)
      if entryIdMap and #entryIdMap > 0 then
        for k, v in ipairs(entryIdMap) do
          local npcSceneResId = v.sceneResId
          local mapPieceId = v.mapPieceId
          if self.npcDatas[npcSceneResId] and self.npcDatas[npcSceneResId][mapPieceId] then
            local _npcData = self.npcDatas[npcSceneResId][mapPieceId][_entryId]
            local delList = {}
            if _npcData then
              for _logicId, _npcInfo in pairs(_npcData) do
                local bExist = false
                for key, val in ipairs(npcInfos.world_map_npc_infos) do
                  if _logicId == val.npc_logic_id then
                    bExist = true
                  end
                end
                if false == bExist then
                  table.insertUnique(delList, _logicId)
                end
              end
              if delList and #delList > 0 then
                for key, _logicId in ipairs(delList) do
                  self.module:OnCmdRemoveNpcIconByNpcId(_entryId, _logicId)
                  self:UpdateMapShowNpc(npcSceneResId, mapPieceId, false, nil, _entryId, _logicId)
                  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, false, nil, _entryId, _logicId)
                  local defaultTrackType = _npcData[_logicId] and _npcData[_logicId].worldMapConf and _npcData[_logicId].worldMapConf.default_track_type or Enum.defaultTrackType.DTT_NONE
                  self:RemoveFromDefaultTrackNpcMap(defaultTrackType, _logicId)
                  table.removeKey(_npcData, _logicId)
                end
              end
            end
          end
        end
      end
      local npcSceneResId = 0
      local mapPieceId = 0
      for key, val in ipairs(npcInfos.world_map_npc_infos) do
        local glass_info, mutation_type
        glass_info = val.glass_info
        mutation_type = val.mutation_type
        if npcInfos then
          npcSceneResId, mapPieceId = self:SeperatedBySceneResId(val)
        end
        self:UpdateSingleNpcInfo(_entryId, val, worldMap, npcSceneResId, mapPieceId, mutation_type, glass_info, bAll)
        self:AddEntryIdMap(_entryId, npcSceneResId, mapPieceId)
      end
    end
    if mapArea then
      mapArea.npcList = npcInfos.world_map_npc_infos
      if mapArea.npcList and #mapArea.npcList > 0 then
        mapArea.npcList[1].entry_id = _entryId
        mapArea.npcList[1].npcCfg = _G.DataConfigManager:GetNpcConf(mapArea.npcList[1].npc_cfg_id)
        mapArea.npcList[1].world_map_cfg_id = npcInfos.world_map_cfg_id
      end
      mapArea.npcId = _entryId
      mapArea.world_map_cfg_id = npcInfos.world_map_cfg_id
      mapArea.unlocked = true
    end
  elseif npcInfos and npcInfos.world_map_npc_infos == nil and npcInfos.next_npc_refresh_time then
    local npcSceneResId = 0
    local mapPieceId = 0
    npcSceneResId, mapPieceId = self:SeperatedBySceneResId(npcInfos)
    local worldMap = self.bigMapDatas[npcInfos.world_map_cfg_id]
    self:UpdateSingleRefreshNpcInfo(_entryId, npcInfos, worldMap, npcSceneResId, mapPieceId)
    local CurTraceNpcId = self:GetCurTraceNpcId()
    if _entryId and _entryId == CurTraceNpcId then
      self:SetCurTraceNpc(-1)
    end
  else
    self:RemoveEntryIdMap(_entryId)
    local CurTraceNpcId = self:GetCurTraceNpcId()
    if _entryId and _entryId == CurTraceNpcId then
      self:SetCurTraceNpc(-1)
    end
    if npcInfos and npcInfos.world_map_cfg_id then
      local mapArea = self.mapAreaDatas[npcInfos.world_map_cfg_id]
      if mapArea then
        table.removeKey(self.mapAreaDatas, npcInfos.world_map_cfg_id)
        self:SetAllMiniMapShowAreaNpcs()
      end
    else
      do
        local npcSceneResId = 0
        local mapPieceId = 0
        if npcInfos then
          npcSceneResId, mapPieceId = self:SeperatedBySceneResId(npcInfos)
        end
        if self.npcDatas[npcSceneResId] and self.npcDatas[npcSceneResId][mapPieceId] and self.npcDatas[npcSceneResId][mapPieceId][_entryId] then
          local npcData = self.npcDatas[npcSceneResId][mapPieceId][_entryId]
          local mapArea = self.mapAreaDatas[npcData.world_map_cfg_id]
          if mapArea then
            table.removeKey(self.mapAreaDatas, npcData.world_map_cfg_id)
          end
        end
      end
    end
    for sceneResId, pieceList in pairs(self.npcDatas) do
      for pieceId, npcList in pairs(pieceList) do
        local entryIdMap = npcList[_entryId]
        if entryIdMap then
          for logicId, npcInfo in pairs(entryIdMap) do
            local npcWorldMapCfgId = npcInfo.world_map_cfg_id
            if npcInfo.worldMapConf.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP and npcInfo.worldMapActivityConf then
              self.module:RemoveCircleByTypeAndKey(bigMapModuleEnum.CircleIconType.Activity, npcInfo.worldMapActivityConf.id)
              _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnDropNPCChange, npcInfo.worldMapActivityConf.area_func_id, false)
            end
            self:RemoveNpcDataByWorldMapCfgId(npcInfo)
            self.module:OnCmdRemoveNpcIconByNpcId(_entryId, logicId)
            if npcWorldMapCfgId then
              local worldMap = self.bigMapDatas[npcWorldMapCfgId]
              if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_TEAM_BATTLE then
                _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.ClosePreWarInfoPanel)
              end
            end
            self:UpdateMapShowNpc(sceneResId, pieceId, false, nil, _entryId, logicId)
            self:UpdateMiniMapShowNpc(sceneResId, pieceId, false, nil, _entryId, logicId)
            local defaultTrackType = npcInfo.worldMapConf and npcInfo.worldMapConf.default_track_type or Enum.defaultTrackType.DTT_NONE
            self:RemoveFromDefaultTrackNpcMap(defaultTrackType, logicId)
          end
          table.removeKey(npcList, _entryId)
          break
        end
      end
    end
  end
  if npcInfos and npcInfos.world_map_cfg_id then
    local worldMap = self.bigMapDatas[npcInfos.world_map_cfg_id]
    if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
      NRCModuleManager:DoCmd(AreaAndZoneModuleCmd.OnActivityMapNpcDataChanged, npcInfos)
    end
  end
end

function BigMapModuleData:UpdateSingleNpcInfo(_npcId, _npcInfo, worldMap, npcSceneResId, mapPieceId, mutation_type, glass_info, bAll)
  if nil == _npcId then
    Log.Error("BigMapModuleData:UpdateSingleNpcInfo npc is nil")
    return
  end
  npcSceneResId = npcSceneResId or SceneUtils.GetSceneResId()
  local npcModuleCfg
  if nil == self.npcDatas[npcSceneResId] then
    self.npcDatas[npcSceneResId] = {}
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId] then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId][_npcId] then
    self.npcDatas[npcSceneResId][mapPieceId][_npcId] = {}
  end
  local logicId = _npcInfo.npc_logic_id or _npcId
  if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_BOSS_BATTLE then
    logicId = _npcId
  end
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][_npcId][logicId]
  local npcCfg = _G.DataConfigManager:GetNpcConf(_npcInfo.npc_cfg_id)
  if npcCfg then
    if npcCfg.model_conf > 0 then
      npcModuleCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
    else
      Log.Error("npc model conf == 0", npcCfg.id)
    end
  end
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][_npcId][logicId] = npcData
    isNewNpcData = true
  elseif _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED and not npcData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
    npcData.isNewUnLock = true
  end
  if worldMap then
    if worldMap.teleport_id and worldMap.teleport_id > 0 and npcData.entry_id == self:GetCurTraceNpcId() and npcData.status ~= _npcInfo.status then
      self:SetCurTraceNpc(-1)
    end
    if worldMap.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_CAMP and _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
      local TraceNpcRefreshId = self:GetCurTraceNpcRefreshId()
      local MagicManualFlowerInfo = _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.CmdGetMagicManualFlowerInfoByNpcRefreshId, TraceNpcRefreshId)
      if MagicManualFlowerInfo and MagicManualFlowerInfo.camp_cfg_id == _npcInfo.npc_refresh_id then
        self:SetCurTraceNpc(-1)
      end
      local MagicManualBossInfo = _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.CmdGetMagicManualBossInfoByNpcRefreshId, TraceNpcRefreshId)
      if MagicManualBossInfo and MagicManualBossInfo.camp_cfg_id == _npcInfo.npc_refresh_id then
        self:SetCurTraceNpc(-1)
      end
    end
    if worldMap.map_show_type == Enum.MapIconShowType.MAP_NPC_DAZZLING or worldMap.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING or worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_AUTO_TRACK then
      npcData.ownerId = _npcInfo.create_avatar_id
      npcData.ownerName = _npcInfo.create_avatar_name
    end
    local npcCfgId = _npcInfo.npc_cfg_id
    if npcCfgId and self:GetExploreTypeByNpcConfId(npcCfgId) == Enum.WorldExploringStatisticType.WEST_CHALLENGER then
      self.campChallengeNpcInfo[npcCfgId] = _npcInfo.status
    end
    if worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
      npcData.worldMapActivityConf = self.MapIdToMapActivityConf[worldMap.id]
      _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnDropNPCChange, npcData.worldMapActivityConf.area_func_id, true)
    end
  end
  npcData.entry_id = _npcId
  npcData.npc_cfg_id = _npcInfo.npc_cfg_id
  npcData.npc_refresh_id = _npcInfo.npc_refresh_id
  npcData.unlocked = _npcInfo.unlocked
  npcData.npc_pos.x = _npcInfo.npc_pos.x
  npcData.npc_pos.y = _npcInfo.npc_pos.y
  npcData.npc_pos.z = _npcInfo.npc_pos.z
  npcData.npcCfg = npcCfg
  npcData.moduleCfg = npcModuleCfg
  npcData.npc_level = _npcInfo.npc_level
  npcData.npc_remain_time = _npcInfo.npc_remain_time
  npcData.status = _npcInfo.status
  npcData.logic_id = _npcInfo.npc_logic_id
  if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_BOSS_BATTLE then
    npcData.logic_id = _npcId
  end
  npcData.glass_info = glass_info
  npcData.mutation_type = mutation_type
  npcData.layerId = _npcInfo.layer_id
  npcData.bornTimeStamp = _npcInfo.npc_born_time
  if npcData.npc_remain_time and npcData.npc_remain_time > 0 then
    npcData.CreateTime = os.time()
  end
  worldMap = worldMap or self.bigMapDatas[npcData.npc_refresh_id]
  if worldMap then
    npcData.world_map_cfg_id = worldMap.id
    local mapArea = self.mapAreaDatas[worldMap.id]
    if mapArea and mapArea.area_pos == _G.FVectorZero then
      mapArea.area_pos = UE4.FVector(npcData.npc_pos.x, npcData.npc_pos.y, npcData.npc_pos.z)
      mapArea.IsValid = true
    end
  end
  npcData.worldMapConf = worldMap
  self:_SetUnlockDeadwoodList(npcSceneResId, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
  self:DispatchEvent(BigMapModuleEvent.NpcRefreshTimeChange, npcData)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
  self:BuildLogicIdToNpcInfo(_npcInfo.npc_logic_id, npcData)
  if worldMap and worldMap.default_track_type ~= Enum.DefaultTrackType.DTT_NONE then
    self:AddToDefaultTrackNpcMap(npcData, bAll)
  end
  return npcData
end

function BigMapModuleData:UpdateSingleRefreshNpcInfo(_npcId, _npcInfo, worldMap, npcSceneResId, mapPieceId)
  local npcModuleCfg
  if self.npcDatas[npcSceneResId] == nil then
    self.npcDatas[npcSceneResId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId][_npcId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId][_npcId] = {}
  end
  local logicId = _npcInfo.npc_logic_id or _npcId
  if worldMap and worldMap.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_BOSS_BATTLE then
    logicId = _npcId
  end
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][_npcId][logicId]
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][_npcId][logicId] = npcData
    isNewNpcData = true
  elseif _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED and not npcData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
    npcData.isNewUnLock = true
  end
  Log.Debug(_npcInfo.npc_remain_time, _npcInfo.npc_cfg_id, "BigMapModuleData:UpdateSingleNpcInfo")
  npcData.entry_id = _npcId
  npcData.npc_pos.x = _npcInfo.pos.x
  npcData.npc_pos.y = _npcInfo.pos.y
  npcData.npc_pos.z = _npcInfo.pos.z
  npcData.next_npc_refresh_time = _npcInfo.next_npc_refresh_time
  if npcData.npc_remain_time and npcData.npc_remain_time > 0 then
    npcData.CreateTime = os.time()
  end
  worldMap = worldMap or self.bigMapDatas[npcData.npc_refresh_id]
  if worldMap then
    local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(worldMap.npc_refresh_ids[1])
    local npcId = refreshConf.npc_id
    local npcCfg = _G.DataConfigManager:GetNpcConf(npcId)
    npcData.npcCfg = npcCfg
    npcData.world_map_cfg_id = worldMap.id
    npcData.worldMapConf = worldMap
    local mapArea = self.mapAreaDatas[worldMap.id]
    if mapArea and mapArea.area_pos == _G.FVectorZero then
      mapArea.area_pos = UE4.FVector(npcData.npc_pos.x, npcData.npc_pos.y, npcData.npc_pos.z)
      mapArea.IsValid = true
    end
    if worldMap.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING then
      npcData.glass_info = _npcInfo.glass_info
      npcData.mutation_type = _npcInfo.mutation_type
    end
  end
  self:DispatchEvent(BigMapModuleEvent.NpcRefreshTimeChange, npcData)
  _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.CmdRefreshChallengeItemBtn, npcData.npc_refresh_id or worldMap.npc_refresh_ids[1], npcData.next_npc_refresh_time)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
  self:BuildLogicIdToNpcInfo(_npcInfo.npc_logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
  return npcData
end

function BigMapModuleData:UpdateMagicCreateNpcInfo(npcInfo)
  local npcSceneResId = 0
  local mapPieceId = 0
  if npcInfo then
    npcSceneResId, mapPieceId = self:SeperatedBySceneResId(npcInfo)
  end
  npcSceneResId = npcSceneResId or SceneUtils.GetSceneResId()
  local npcModuleCfg
  if self.npcDatas[npcSceneResId] == nil then
    self.npcDatas[npcSceneResId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id] then
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id] = {}
  end
  local logicId = npcInfo.npc_logic_id or npcInfo.npc_obj_id
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id][logicId]
  local npcCfg = _G.DataConfigManager:GetNpcConf(npcInfo.npc_cfg_id)
  if npcCfg then
    npcModuleCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
  end
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id][logicId] = npcData
    isNewNpcData = true
  else
    npcData.isNewUnLock = true
  end
  local worldMap = self.bigMapDatas[npcInfo.world_map_cfg_id]
  if worldMap and worldMap.teleport_id and worldMap.teleport_id > 0 and npcData.entry_id == self:GetCurTraceNpcId() and npcData.status ~= npcInfo.status then
    self:SetCurTraceNpc(-1)
  end
  npcData.entry_id = npcInfo.npc_obj_id
  npcData.npc_cfg_id = npcInfo.npc_cfg_id
  npcData.npc_refresh_id = npcInfo.npc_refresh_id
  npcData.unlocked = npcInfo.unlocked
  if npcInfo.npc_pos then
    npcData.npc_pos.x = npcInfo.npc_pos.x
    npcData.npc_pos.y = npcInfo.npc_pos.y
    npcData.npc_pos.z = npcInfo.npc_pos.z
  else
    npcData.npc_pos.x = 0
    npcData.npc_pos.y = 0
    npcData.npc_pos.z = 0
  end
  npcData.npcCfg = npcCfg
  npcData.moduleCfg = npcModuleCfg
  npcData.npc_level = npcInfo.npc_level
  npcData.npc_remain_time = npcInfo.npc_remain_time
  npcData.status = npcInfo.status or _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
  npcData.logic_id = npcInfo.npc_logic_id
  npcData.world_map_cfg_id = npcInfo.world_map_cfg_id
  npcData.worldMapConf = _G.DataConfigManager:GetWorldMapConf(npcData.world_map_cfg_id)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
  self:BuildLogicIdToNpcInfo(npcInfo.npc_logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
end

function BigMapModuleData:UpdateOwlStarData(owlStarInfo)
  local npcSceneResId = 0
  local mapPieceId = 0
  owlStarInfo.world_map_npc_infos = {
    [1] = {
      npc_pos = owlStarInfo.npc_pos,
      npc_refresh_id = nil
    }
  }
  if owlStarInfo.npc_content_id and owlStarInfo.npc_content_id > 0 then
    owlStarInfo.world_map_npc_infos[1].npc_refresh_id = owlStarInfo.npc_content_id
  else
    owlStarInfo.world_map_npc_infos[1].npc_refresh_id = owlStarInfo.npc_src_refresh_content_id
  end
  npcSceneResId, mapPieceId = self:SeperatedBySceneResId(owlStarInfo)
  npcSceneResId = npcSceneResId or SceneUtils.GetSceneResId()
  if nil == self.npcDatas[npcSceneResId] then
    self.npcDatas[npcSceneResId] = {}
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId] then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  local entryId = owlStarInfo.npc_obj_id
  local logicId = owlStarInfo.logic_id or entryId
  local npcModelCfg
  local npcCfg = _G.DataConfigManager:GetNpcConf(owlStarInfo.npc_cfg_id)
  if nil == npcCfg then
    self:LogError("empty npc cfg for ", owlStarInfo.npc_cfg_id)
    return
  end
  if npcCfg then
    npcModelCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId][entryId] then
    self.npcDatas[npcSceneResId][mapPieceId][entryId] = {}
  end
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][entryId][logicId]
  local isNewNpcData = false
  npcData = nil
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][entryId][logicId] = npcData
    isNewNpcData = true
  end
  local npc_cfg_id = owlStarInfo.npc_cfg_id
  npcData.entry_id = entryId
  npcData.npc_cfg_id = npc_cfg_id
  npcData.logic_id = owlStarInfo.logic_id
  npcData.npc_refresh_id = owlStarInfo.npc_content_id
  npcData.npc_src_refresh_content_id = owlStarInfo.npc_src_refresh_content_id
  npcData.unlocked = true
  if owlStarInfo.npc_pos then
    npcData.npc_pos.x = owlStarInfo.npc_pos.x or 0
    npcData.npc_pos.y = owlStarInfo.npc_pos.y or 0
    npcData.npc_pos.z = owlStarInfo.npc_pos.z or 0
  else
    npcData.npc_pos.x = 0
    npcData.npc_pos.y = 0
    npcData.npc_pos.z = 0
  end
  npcData.npcCfg = npcCfg
  npcData.moduleCfg = npcModelCfg
  npcData.npc_level = 1
  npcData.npc_remain_time = nil
  npcData.status = _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
  npcData.world_map_cfg_id = npcCfg.min_map_disappear or 0
  npcData.worldMapConf = _G.DataConfigManager:GetWorldMapConf(npcData.world_map_cfg_id)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
  self:BuildLogicIdToNpcInfo(owlStarInfo.npc_logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
end

function BigMapModuleData:UpdateHomePetOutputIcon(petGid)
  if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InHomeIndoor() then
    return true
  else
    if not petGid then
      return false
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not player then
      return false
    end
    local curStealNum = player.serverData.steal_home_info and player.serverData.steal_home_info.total_steal_num or 0
    local stealTotalLimit = _G.DataConfigManager:GetHomeGlobalConfig("home_daily_steal_reward_max") and _G.DataConfigManager:GetHomeGlobalConfig("home_daily_steal_reward_max").num or 99999
    if curStealNum >= stealTotalLimit then
      return false
    end
    return not HomeUtils.IsPetHasBeenSteal(petGid)
  end
end

function BigMapModuleData:UpdateHomePetInfo(npcInfo, reason)
  local npcSceneResId = 30001
  local mapPieceId = 0
  if npcInfo and npcInfo.base and npcInfo.base.born_pt and npcInfo.base.born_pt.pos then
    mapPieceId = BigMapUtils.GetMapPieceIdByPos(npcInfo.base.born_pt.pos.x or 0, npcInfo.base.born_pt.pos.y or 0, npcSceneResId)
  end
  if reason == Enum.MapModuleDataUpdateReason.HOME_PET_TRIGGER_NUM_LIMIT then
    if not npcInfo then
      if not self.npcDatas or not self.npcDatas[npcSceneResId] then
        return
      end
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      local stealHomeInfo = player.serverData.steal_home_info
      local totalStealMax = _G.DataConfigManager:GetHomeGlobalConfig("home_daily_steal_reward_max") and _G.DataConfigManager:GetHomeGlobalConfig("home_daily_steal_reward_max").num or 99999
      if stealHomeInfo.total_steal_num and totalStealMax <= stealHomeInfo.total_steal_num then
        for _, mapPiece in pairs(self.npcDatas[npcSceneResId]) do
          for _, homePet in pairs(mapPiece) do
            if homePet.petInfo then
              homePet.petInfo.productionInfo = nil
            end
          end
        end
      else
        for _, mapPiece in pairs(self.npcDatas[npcSceneResId]) do
          for _, homePet in pairs(mapPiece) do
            if homePet and homePet.petInfo and homePet.petInfo.pet_gid then
              homePet.petInfo.productionInfo = self:UpdateHomePetOutputIcon(homePet.petInfo.pet_gid) and homePet.petInfo.productionInfo or nil
            end
          end
        end
      end
    else
      if not (self.npcDatas and self.npcDatas[npcSceneResId]) or not self.npcDatas[npcSceneResId][mapPieceId] then
        return
      end
      local actorId = npcInfo.base.actor_id
      local logicId = npcInfo.base.logic_id or actorId
      if self.npcDatas[npcSceneResId][mapPieceId][actorId] and self.npcDatas[npcSceneResId][mapPieceId][actorId][logicId] and self.npcDatas[npcSceneResId][mapPieceId][actorId][logicId].petInfo then
        self.npcDatas[npcSceneResId][mapPieceId][actorId][logicId].petInfo.productionInfo = nil
      end
    end
    return
  elseif not npcInfo then
    Log.Error("UpdateHomePetInfo with nil npcInfo")
    return
  end
  local petGid = npcInfo and npcInfo.home_pet.home_pet_info.pet_gid
  if self.npcDatas[npcSceneResId] == nil then
    self.npcDatas[npcSceneResId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  local entryId = npcInfo.base.actor_id
  if self.npcDatas[npcSceneResId][mapPieceId][entryId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId][entryId] = {}
  end
  local logicId = npcInfo.base.logic_id or entryId
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][entryId][logicId]
  local petModelCfg
  local npcCfg = _G.DataConfigManager:GetNpcConf(npcInfo.npc_base.npc_cfg_id)
  if petGid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
    if petData and petData.base_conf_id then
      local petCfg = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
      if petCfg then
        petModelCfg = petCfg.model_conf
      end
    end
  end
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.base.actor_id][logicId] = npcData
    isNewNpcData = true
  elseif reason == _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE then
    self:RemoveNpcDataByWorldMapCfgId(npcData)
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.base.actor_id][logicId] = nil
  elseif reason == _G.Enum.MapModuleDataUpdateReason.HOME_PET_CLEAR_PRODUCTION then
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.base.actor_id][logicId].petInfo.productionInfo = nil
  elseif reason == _G.Enum.MapModuleDataUpdateReason.HOME_PET_REFRESH_PRODUCTION and self:UpdateHomePetOutputIcon(petGid) then
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.base.actor_id][logicId].petInfo.productionInfo = npcInfo.home_pet.home_pet_info.awards_info
  end
  local worldMap
  npcData.entry_id = npcInfo.base.actor_id
  npcData.npc_cfg_id = npcInfo.npc_base.npc_cfg_id
  if npcInfo.base.born_pt then
    npcData.npc_pos.x = npcInfo.base.born_pt.pos.x
    npcData.npc_pos.y = npcInfo.base.born_pt.pos.y
    npcData.npc_pos.z = npcInfo.base.born_pt.pos.z
  else
    npcData.npc_pos.x = 0
    npcData.npc_pos.y = 0
    npcData.npc_pos.z = 0
  end
  npcData.npcCfg = npcCfg
  npcData.petInfo = {
    pet_gid = petGid,
    productionInfo = self:UpdateHomePetOutputIcon(petGid) and npcInfo.home_pet.home_pet_info.awards_info and npcInfo.home_pet.home_pet_info.awards_info.goods_infos or nil,
    base_conf_id = npcInfo.base_conf_id,
    mutation_type = npcInfo.mutation_type,
    glass_info = npcInfo.glass_info
  }
  npcData.moduleCfg = petModelCfg
  npcData.npc_level = npcInfo.base.lv
  npcData.npc_remain_time = 9.0E9
  npcData.status = reason == ProtoEnum.MapModuleDataUpdateReason.HOME_PET_LEAVE and _G.ProtoEnum.LockStatus.ENUM.NONE or _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
  npcData.logic_id = npcInfo.base.logic_id
  npcData.world_map_cfg_id = 10002
  worldMap = _G.DataConfigManager:GetWorldMapConf(npcData.world_map_cfg_id)
  npcData.worldMapConf = worldMap
  if reason == _G.Enum.MapModuleDataUpdateReason.HOME_PET_SHOW_NPC_OUT_OF_RANGE then
    if not self.fakeHomeNpcData then
      self.fakeHomeNpcData = {}
    end
    table.insert(self.fakeHomeNpcData, npcInfo)
  end
  npcData.need_clear_when_close = npcInfo.need_clear_when_close
  if reason == _G.Enum.MapModuleDataUpdateReason.HOME_PET_ENTER then
    if not self.homePetInfo then
      self.homePetInfo = {}
    end
    for _, homePet in ipairs(self.homePetInfo) do
      if homePet and homePet.entry_id == npcData.entry_id then
        table.removeValue(self.homePetInfo, homePet)
        break
      end
    end
    table.insert(self.homePetInfo, npcData)
  elseif reason == _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE then
    if self.homePetInfo then
      for _, homePet in ipairs(self.homePetInfo) do
        if homePet and homePet.entry_id == npcData.entry_id then
          table.removeValue(self.homePetInfo, homePet)
          break
        end
      end
    end
    if self.fakeHomeNpcData then
      for _, fakeHomePet in ipairs(self.fakeHomeNpcData) do
        if fakeHomePet and fakeHomePet.entry_id == npcData.entry_id then
          table.removeValue(self.fakeHomeNpcData, fakeHomePet)
          break
        end
      end
    end
  else
    for _, homePet in ipairs(self.homePetInfo) do
      if homePet and homePet.entry_id == npcData.entry_id then
        homePet.petInfo = npcData.petInfo
        break
      end
    end
  end
  self:UpdateMapShowNpc(npcSceneResId, mapPieceId, reason ~= _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE, npcData, npcData.entry_id, logicId)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, reason ~= _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE, npcData, npcData.entry_id, logicId)
  self:BuildLogicIdToNpcInfo(npcInfo.base.logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
end

function BigMapModuleData:UpdateOwlSanctuaryNpcData(npcInfo)
  local npcSceneResId = 0
  local mapPieceId = 0
  if npcInfo then
    npcSceneResId, mapPieceId = self:SeperatedBySceneResId(npcInfo)
  end
  npcSceneResId = npcSceneResId or SceneUtils.GetSceneResId()
  local npcModuleCfg
  if self.npcDatas[npcSceneResId] == nil then
    self.npcDatas[npcSceneResId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  local entryId = npcInfo.npc_obj_id
  if self.owlRefreshIdToMapEntryId and self.owlRefreshIdToMapEntryId[npcInfo.npc_content_id] then
    entryId = self.owlRefreshIdToMapEntryId[npcInfo.npc_content_id]
  end
  if nil == entryId then
    Log.Error("BigMapModuleData:UpdateOwlSanctuaryNpcData invalid entryId!!", npcInfo.npc_content_id, #(self.owlRefreshIdToMapEntryId or {}), (npcInfo.npc_pos or {}).x, (npcInfo.npc_pos or {}).y, (npcInfo.npc_pos or {}).z)
    return
  end
  local logicId = npcInfo.npc_logic_id or entryId
  if self.npcDatas[npcSceneResId][mapPieceId][entryId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId][entryId] = {}
  end
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][entryId][logicId]
  local npcRefreshContentConf = DataConfigManager:GetNpcRefreshContentConf(npcInfo.npc_content_id)
  local npc_cfg_id
  if not npcRefreshContentConf then
    Log.Error("Invalid npcRefreshContentId", npcInfo.npc_content_id)
    return
  end
  local owlSanctuaryConf = DataConfigManager:GetOwlSanctuaryConf(npcInfo.npc_content_id)
  if not owlSanctuaryConf then
    Log.Error("Invalid owlSanctuaryConf", npcInfo.npc_content_id)
    return
  end
  local npcLevel = 1
  local allOwlSanctuaryNpcInfo = _G.DataModelMgr.PlayerDataModel:GetOwlSanctuaryNpcInfo()
  if nil ~= allOwlSanctuaryNpcInfo and nil ~= allOwlSanctuaryNpcInfo.owl_sanctuarys then
    for _, v in pairs(allOwlSanctuaryNpcInfo.owl_sanctuarys) do
      if v.npc_content_id == npcInfo.npc_content_id then
        if v.is_upgrade then
          npcLevel = npcLevel + 1
        end
        if v.fruit_brief_infos then
          for i = 1, #v.fruit_brief_infos do
            if 0 ~= v.fruit_brief_infos[i].fruit_id then
              npcLevel = npcLevel + 1
            end
          end
          break
        end
        v.fruit_brief_infos = {}
        table.insert(v.fruit_brief_infos, {fruit_id = 0})
        table.insert(v.fruit_brief_infos, {fruit_id = 0})
        break
      end
    end
  end
  npc_cfg_id = npcRefreshContentConf.npc_id
  local npcCfg = _G.DataConfigManager:GetNpcConf(npcRefreshContentConf.npc_id)
  if npcCfg then
    npcModuleCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
  end
  if entryId == self:GetCurTraceNpcId() and npcLevel > 1 then
    self:SetCurTraceNpc(-1)
  end
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][entryId][logicId] = npcData
    isNewNpcData = true
  end
  local worldMap = self.bigMapDatas[npcInfo.npc_content_id]
  if worldMap then
    npcData.world_map_cfg_id = worldMap.id
  end
  npcData.entry_id = entryId
  npcData.npc_cfg_id = npc_cfg_id
  npcData.npc_refresh_id = npcInfo.npc_content_id
  npcData.unlocked = npcInfo.unlocked
  npcData.npc_pos.x = npcInfo.npc_pos.x
  npcData.npc_pos.y = npcInfo.npc_pos.y
  npcData.npc_pos.z = npcInfo.npc_pos.z
  npcData.npcCfg = npcCfg
  npcData.moduleCfg = npcModuleCfg
  npcData.npc_level = npcLevel
  npcData.npc_remain_time = nil
  npcData.worldMapConf = worldMap
  local AllPlayerOwlInfo = _G.DataModelMgr.PlayerDataModel:GetAllPlayerOwlSanctuaryNpcInfo()
  local DetectFlag = false
  local OwlIndex = 0
  if AllPlayerOwlInfo and next(AllPlayerOwlInfo) then
    for _, value in ipairs(AllPlayerOwlInfo) do
      if 0 ~= OwlIndex then
        local owlInfo = value.owl_sanctuarys[OwlIndex]
        if owlInfo and owlInfo.is_detected then
          DetectFlag = true
        end
      else
        for i, owlsanc in ipairs(value.owl_sanctuarys) do
          if owlsanc.npc_content_id == npcInfo.npc_content_id then
            if owlsanc.is_detected then
              DetectFlag = true
            end
            OwlIndex = i
            break
          end
        end
      end
      if DetectFlag then
        break
      end
    end
  end
  if DetectFlag then
    npcData.status = _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
  else
    npcData.status = _G.ProtoEnum.LockStatus.ENUM.LOCKED
  end
  npcData.logic_id = logicId
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
  self:BuildLogicIdToNpcInfo(npcInfo.npc_logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
end

function BigMapModuleData:UpdateHandBookTraceNpcData(npcInfo)
  local npcSceneResId = 0
  local mapPieceId = 0
  local posX = 0
  local posY = 0
  local posZ = 0
  if npcInfo and npcInfo.pt and npcInfo.pt.pos then
    posX = npcInfo.pt.pos.x or 0
    posY = npcInfo.pt.pos.y or 0
    posZ = npcInfo.pt.pos.z or 0
    npcSceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
    mapPieceId = BigMapUtils.GetMapPieceIdByPos(posX, posY, npcSceneResId)
  end
  local npcModuleCfg
  if self.npcDatas[npcSceneResId] == nil then
    self.npcDatas[npcSceneResId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  if nil == npcInfo.npc_obj_id then
    npcInfo.npc_obj_id = npcInfo.content_id
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id] then
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id] = {}
  end
  local logicId = npcInfo.npc_logic_id or npcInfo.npc_obj_id
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id][logicId]
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id][logicId] = npcData
    isNewNpcData = true
  end
  local npcCfgId = npcInfo.npc_cfg_id
  local npcCfg = _G.DataConfigManager:GetNpcConf(npcCfgId)
  if npcCfg then
    npcModuleCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
  end
  local worldMapCfgId = _G.DataConfigManager:GetPetGlobalConfig("hd_track_world_map_id").num
  local worldMap = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
  if worldMap then
    npcData.world_map_cfg_id = worldMap.id
  end
  npcData.entry_id = npcInfo.npc_obj_id
  npcData.npc_cfg_id = npcInfo.npc_conf_id
  npcData.npc_refresh_id = npcInfo.content_id
  npcData.unlocked = true
  npcData.npc_pos.x = npcInfo.pt.pos.x or 0
  npcData.npc_pos.y = npcInfo.pt.pos.y or 0
  npcData.npc_pos.z = npcInfo.pt.pos.z or 0
  npcData.npcCfg = npcCfg
  npcData.moduleCfg = npcModuleCfg
  npcData.npc_level = 1
  npcData.npc_remain_time = nil
  npcData.status = _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
  npcData.logic_id = npcInfo.npc_logic_id or npcInfo.npc_obj_id
  npcData.petBase_id = npcInfo.pet_base_id
  npcData.worldMapConf = worldMap
  local recordData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandbookRecordDataByPetBaseID, npcData.petBase_id)
  if recordData then
    npcData.state = recordData.State
    npcData.isFound = false
    if recordData.Record and recordData.Record.caught_camp then
      npcData.isFound = self:CheckIsFound(recordData.Record.caught_camp, npcData.npc_refresh_id)
    end
  else
    npcData.state = _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
    npcData.isFound = false
  end
  self:UpdateMapShowNpc(npcSceneResId, mapPieceId, true, npcData, npcData.entry_id, logicId)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData, npcData.entry_id, logicId)
  _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.OnTraceNpcDataChanged)
  self:BuildLogicIdToNpcInfo(npcInfo.npc_logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
end

function BigMapModuleData:UpdateHomeClientNpcInfo(npcInfo)
  local npcSceneResId = 0
  local mapPieceId = 0
  local posX = 0
  local posY = 0
  local posZ = 0
  if npcInfo and npcInfo.npc_pos then
    posX = npcInfo.npc_pos.x or 0
    posY = npcInfo.npc_pos.y or 0
    posZ = npcInfo.npc_pos.z or 0
    npcSceneResId = BigMapUtils.GetSceneResIdByRefreshId(npcInfo.npc_refresh_id)
    mapPieceId = BigMapUtils.GetMapPieceIdByPos(posX, posY, npcSceneResId)
  end
  local npcModuleCfg
  if self.npcDatas[npcSceneResId] == nil then
    self.npcDatas[npcSceneResId] = {}
  end
  if self.npcDatas[npcSceneResId][mapPieceId] == nil then
    self.npcDatas[npcSceneResId][mapPieceId] = {}
  end
  if nil == self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id] then
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id] = {}
  end
  local logicId = npcInfo.logic_id or npcInfo.entry_id
  local npcData = self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id][logicId]
  local isNewNpcData = false
  if not npcData then
    npcData = {
      npc_pos = {}
    }
    self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id][logicId] = npcData
    isNewNpcData = true
  end
  local npcCfgId = npcInfo.npc_cfg_id
  local npcCfg = _G.DataConfigManager:GetNpcConf(npcCfgId)
  if npcCfg then
    npcModuleCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
  end
  npcData.world_map_cfg_id = npcInfo.world_map_cfg_id
  npcData.entry_id = npcInfo.entry_id
  npcData.npc_cfg_id = npcInfo.npc_cfg_id
  npcData.npc_refresh_id = npcInfo.npc_refresh_id
  npcData.unlocked = npcInfo.unlocked
  npcData.npc_pos.x = npcInfo.npc_pos.x or 0
  npcData.npc_pos.y = npcInfo.npc_pos.y or 0
  npcData.npc_pos.z = npcInfo.npc_pos.z or 0
  npcData.npcCfg = npcCfg
  npcData.moduleCfg = npcModuleCfg
  npcData.npc_level = 1
  npcData.npc_remain_time = nil
  npcData.status = _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
  npcData.worldMapConf = npcInfo.worldMapConf
  self:_SetUnlockDeadwoodList(npcSceneResId, npcData)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
  self:BuildLogicIdToNpcInfo(npcInfo.logic_id, npcData)
  if isNewNpcData then
    self:AddNpcDataByWorldMapCfgId(npcData)
  end
end

function BigMapModuleData:UpdateDropMethodInfo(npcInfo, bRemove)
  if bRemove then
  else
    local npcSceneResId = 0
    local mapPieceId = 0
    local posX = 0
    local posY = 0
    local posZ = 0
    if npcInfo and npcInfo.npc_pos then
      posX = npcInfo.npc_pos.x or 0
      posY = npcInfo.npc_pos.y or 0
      posZ = npcInfo.npc_pos.z or 0
      npcSceneResId = BigMapUtils.GetSceneResIdByRefreshId(npcInfo.npc_refresh_id)
      mapPieceId = BigMapUtils.GetMapPieceIdByPos(posX, posY, npcSceneResId)
    end
    local npcModuleCfg
    if self.npcDatas[npcSceneResId] == nil then
      self.npcDatas[npcSceneResId] = {}
    end
    if self.npcDatas[npcSceneResId][mapPieceId] == nil then
      self.npcDatas[npcSceneResId][mapPieceId] = {}
    end
    if nil == self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id] then
      self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id] = {}
    end
    local logicId = npcInfo.logic_id or npcInfo.entry_id
    local npcData = self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id][logicId]
    local isNewNpcData = false
    if not npcData then
      npcData = {
        npc_pos = {}
      }
      self.npcDatas[npcSceneResId][mapPieceId][npcInfo.entry_id][logicId] = npcData
      isNewNpcData = true
    end
    local npcCfgId = npcInfo.npc_cfg_id
    local npcCfg = _G.DataConfigManager:GetNpcConf(npcCfgId)
    if npcCfg then
      npcModuleCfg = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
    end
    npcData.world_map_cfg_id = npcInfo.world_map_cfg_id
    npcData.entry_id = npcInfo.entry_id
    npcData.npc_cfg_id = npcInfo.npc_cfg_id
    npcData.npc_refresh_id = npcInfo.npc_refresh_id
    npcData.unlocked = npcInfo.unlocked
    npcData.npc_pos.x = npcInfo.npc_pos.x or 0
    npcData.npc_pos.y = npcInfo.npc_pos.y or 0
    npcData.npc_pos.z = npcInfo.npc_pos.z or 0
    npcData.npcCfg = npcCfg
    npcData.moduleCfg = npcModuleCfg
    npcData.npc_level = 1
    npcData.npc_remain_time = nil
    npcData.status = _G.ProtoEnum.LockStatus.ENUM.UNLOCKED
    npcData.worldMapConf = npcInfo.worldMapConf
    npcData.worldMapActivityConf = npcInfo.worldMapActivityConf
    self:UpdateMapShowNpc(npcSceneResId, mapPieceId, true, npcData, npcData.entry_id)
    self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, true, npcData)
    self:BuildLogicIdToNpcInfo(npcInfo.logic_id, npcData)
    if isNewNpcData then
      self:AddNpcDataByWorldMapCfgId(npcData)
    end
  end
end

function BigMapModuleData:CheckIsFound(caught_camp, content_id)
  local bCommonPet = false
  local npcRefreshContent = _G.DataConfigManager:GetNpcRefreshContentConf(content_id)
  if npcRefreshContent then
    local belong_camp = npcRefreshContent.belong_camp
    if belong_camp and 0 ~= belong_camp then
      bCommonPet = true
      for _, camp in pairs(caught_camp or {}) do
        if camp == belong_camp then
          return true
        end
      end
    end
  end
  if caught_camp and not bCommonPet then
    local campNum = #caught_camp
    if campNum > 0 then
      return true
    end
  end
  return false
end

function BigMapModuleData:CheckTracingPet(petBaseID)
  if self.HandBookTraceInfo and self.HandBookTraceInfo.npc_trace_info and self.HandBookTraceInfo.npc_trace_info.pet_base_id == petBaseID then
    self:UpdateHandBookTraceNpcData(self.HandBookTraceInfo.npc_trace_info)
  end
end

function BigMapModuleData:RemoveHandBookNpcData(npcInfo)
  if nil == npcInfo then
    return
  end
  local npcSceneResId = 0
  local mapPieceId = 0
  if npcInfo.pt and npcInfo.pt.pos then
    local posX = npcInfo.pt.pos.x or 0
    local posY = npcInfo.pt.pos.y or 0
    npcSceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
    mapPieceId = BigMapUtils.GetMapPieceIdByPos(posX, posY, npcSceneResId)
  end
  if npcInfo.npc_obj_id and 0 ~= npcInfo.npc_obj_id and self.npcDatas[npcSceneResId] and self.npcDatas[npcSceneResId][mapPieceId] then
    local npcData = self.npcDatas[npcSceneResId][mapPieceId][npcInfo.npc_obj_id]
    if npcData then
      self:RemoveNpcDataByWorldMapCfgId(npcData)
      table.removeKey(self.npcDatas[npcSceneResId][mapPieceId], npcInfo.npc_obj_id)
    end
  end
  self:UpdateMapShowNpc(npcSceneResId, mapPieceId, false, nil, npcInfo.npc_obj_id, npcInfo.npc_logic_id)
  self:UpdateMiniMapShowNpc(npcSceneResId, mapPieceId, false, nil, npcInfo.npc_obj_id, npcInfo.npc_logic_id)
  self.HandBookTraceInfo = nil
end

function BigMapModuleData:DrawAllUnlockMapMaskTexture()
  if not self.unLockMapBlockId or #self.unLockMapBlockId > 0 then
  end
end

function BigMapModuleData:DrawMaskTexture(sceneResId)
  if self.module:OnCmdIsMapUnlock(sceneResId) then
    if sceneResId ~= self.lastDrawMaskSceneResId then
      self:DrawWorldMapTexture(true, sceneResId)
    else
      self:DrawWorldMapTexture(false, sceneResId)
    end
  end
end

function BigMapModuleData:DrawWorldMapTexture(clear, sceneResId)
  if self.DrawList[sceneResId] == nil then
    self.DrawList[sceneResId] = {}
  end
  Log.DebugFormat("DrawWorldMapTexture clear=%s %d", tostring(clear), #self.DrawList[sceneResId])
  local addList = {}
  local delList = {}
  local sceneOffsetX, sceneOffsetY, sceneWidth, sceneHeight = BigMapUtils.GetConstData(sceneResId)
  if clear then
    table.clear(self.DrawList[sceneResId])
    if self.UnlockDeadwoodList[sceneResId] then
      for key, areaId in pairs(self.UnlockDeadwoodList[sceneResId]) do
        table.insert(addList, areaId)
        table.insert(self.DrawList[sceneResId], areaId)
      end
    end
  else
    addList, delList = table.diff(self.UnlockDeadwoodList[sceneResId], self.DrawList[sceneResId])
    table.clear(self.DrawList[sceneResId])
    for key, areaId in pairs(self.UnlockDeadwoodList[sceneResId]) do
      table.insert(self.DrawList[sceneResId], areaId)
    end
  end
  if self.FullMaskRunTime then
    if clear then
      UE4.UNRCTUIStatics.DrawWorldMapTextureFromBytesFiles(clear, self.FullMaskRunTime, sceneOffsetX, sceneOffsetY, sceneHeight, self.DrawList[sceneResId])
    elseif #delList > 0 then
      UE4.UNRCTUIStatics.DrawWorldMapTextureFromBytesFiles(true, self.FullMaskRunTime, sceneOffsetX, sceneOffsetY, sceneHeight, self.DrawList[sceneResId])
    elseif #addList > 0 then
      UE4.UNRCTUIStatics.DrawWorldMapTextureFromBytesFiles(clear, self.FullMaskRunTime, sceneOffsetX, sceneOffsetY, sceneHeight, addList)
    else
      Log.Debug("No need DrawWorldMapTexture")
    end
    self.lastDrawMaskSceneResId = sceneResId
  end
  Log.Dump(self.DrawList, 3, "BigMapModuleData:LoadMaskTexture")
end

function BigMapModuleData:GetUnlockDeadwoodList()
  return self.UnlockDeadwoodList
end

function BigMapModuleData:_SetUnlockDeadwoodList(sceneResId, npcInfo)
  if self.UnlockDeadwoodList[sceneResId] == nil then
    self.UnlockDeadwoodList[sceneResId] = {}
  end
  local worldMap = npcInfo.worldMapConf
  if worldMap and worldMap.unlock_zone and #worldMap.unlock_zone and npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
    for i, unlock_zone in ipairs(worldMap.unlock_zone) do
      local IsExist = false
      for j, UnlockDeadwood in pairs(self.UnlockDeadwoodList[sceneResId]) do
        if unlock_zone == UnlockDeadwood then
          IsExist = true
          break
        end
      end
      if not IsExist then
        self:AddUnlockDeadwoodList(sceneResId, unlock_zone)
      end
    end
  end
end

function BigMapModuleData:AddUnlockDeadwoodList(sceneResId, unlockZone)
  if self.UnlockDeadwoodList[sceneResId] == nil then
    self.UnlockDeadwoodList[sceneResId] = {}
  end
  table.insert(self.UnlockDeadwoodList[sceneResId], unlockZone)
end

function BigMapModuleData:SaveTextureAsImageFile(texture, sceneResId)
  local filePath = string.format("%sNewRoco/Modules/System/BigMap/Raw/Texture/Maps/%d/MapMask.png", UE4.UBlueprintPathsLibrary.ProjectContentDir(), sceneResId)
  local fileFullPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(filePath)
  UE4.UNRCTUIStatics.SaveTextureAsImageFile(texture, fileFullPath)
end

function BigMapModuleData:DrawTextureFromImageFile(texture, sceneResId)
  local filePath = string.format("%sNewRoco/Modules/System/BigMap/Raw/Texture/Maps/%d/MapMask.png", UE4.UBlueprintPathsLibrary.ProjectContentDir(), sceneResId)
  local fileFullPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(filePath)
  UE4.UNRCTUIStatics.DrawTextureFromImageFile(texture, fileFullPath)
end

function BigMapModuleData:DeleteNpcInfo(_delNpcIds)
  if _delNpcIds then
    for i = 1, #_delNpcIds do
      table.removeKey(self.npcDatas, _delNpcIds[i])
    end
  end
end

function BigMapModuleData:GetLastMapSliderScale(sceneResId)
  local curShowSceneResId = self:GetCurSceneResId()
  if sceneResId then
    curShowSceneResId = sceneResId
  end
  local initScale = 0.31
  for k, v in ipairs(self.MapShowList) do
    if v.sceneResId == curShowSceneResId then
      initScale = v.initScale / 100
    end
  end
  return self.lastMapSliderScale or initScale
end

function BigMapModuleData:GetCurSceneResId()
  return SceneUtils.GetSceneResId()
end

function BigMapModuleData:SetCurShowSceneResId(curResId)
  self.curShowSceneResId = curResId
end

function BigMapModuleData:GetCurShowSceneResId()
  return self.curShowSceneResId
end

function BigMapModuleData:SetLastMapSliderScale(_sliderScale)
  self.lastMapSliderScale = _sliderScale
end

function BigMapModuleData:GetCurTraceNpcData(sceneResId)
  sceneResId = sceneResId or self.curShowSceneResId
  local curTraceNpcId, curTraceLogicId = self:GetCurTraceNpcIdAndLogicId()
  if curTraceNpcId and -1 ~= curTraceNpcId and 0 ~= curTraceNpcId then
    if self.npcDatas[sceneResId] then
      for k, v in pairs(self.npcDatas[sceneResId]) do
        if v[curTraceNpcId] then
          for logicId, npcInfo in pairs(v[curTraceNpcId]) do
            if curTraceLogicId == logicId then
              return npcInfo, true
            end
          end
        end
      end
    else
      for k, v in pairs(self.mapAreaDatas) do
        if v.npcId and v.npcId == curTraceNpcId then
          return v, false
        end
      end
    end
  end
  return nil
end

function BigMapModuleData:ClearTraceInfoByType(traceType)
  if self.traceInfoList then
    table.removeKey(self.traceInfoList, traceType)
  end
end

function BigMapModuleData:GetTraceInfoByType(traceType)
  if self.traceInfoList then
    return self.traceInfoList[traceType]
  end
  return nil
end

function BigMapModuleData:GetCurTraceNpcId()
  local traceType = bigMapModuleEnum.TraceType.NPC
  if self.traceInfoList[traceType] then
    return self.traceInfoList[traceType].npcInfo.entry_id or 0
  end
  return 0
end

function BigMapModuleData:GetCurTraceNpcIdAndLogicId()
  local traceType = bigMapModuleEnum.TraceType.NPC
  if self.traceInfoList[traceType] then
    return self.traceInfoList[traceType].npcInfo.entry_id or 0, self.traceInfoList[traceType].npcInfo.logic_id or 0
  end
  return 0, 0
end

function BigMapModuleData:GetCurTraceNpcRefreshId()
  local traceType = bigMapModuleEnum.TraceType.NPC
  if self.traceInfoList[traceType] then
    return self.traceInfoList[traceType].npcInfo.npc_refresh_id or 0
  end
  return 0
end

function BigMapModuleData:GetSceneResId()
  return self.traceNpcInfo.sceneResId
end

function BigMapModuleData:SetSceneResId(sceneResId)
  self.traceNpcInfo.sceneResId = sceneResId
end

function BigMapModuleData:SetTraceInfoList(traceInfo)
  local traceType = traceInfo.traceType
  if self.traceInfoList[traceType] == nil then
    self.traceInfoList[traceType] = {}
  end
  if traceType == bigMapModuleEnum.TraceType.Task then
    if traceInfo then
      local taskInfo = traceInfo.taskInfo
      if taskInfo then
        local taskId = taskInfo.taskId
        local goIndex = taskInfo.go_index or 1
        if self.traceInfoList[traceType][taskId] == nil then
          self.traceInfoList[traceType][taskId] = {}
        end
        self.traceInfoList[traceType][taskId][goIndex] = traceInfo
      end
    end
  elseif traceType == bigMapModuleEnum.TraceType.Visitor then
    if traceInfo and _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      local index = traceInfo.visitorInfo.visitorIndex
      self.traceInfoList[traceType][index] = traceInfo
    end
  elseif traceType == bigMapModuleEnum.TraceType.TempTrace then
    if traceInfo then
      local logicId = traceInfo.npcInfo.logic_id
      if logicId then
        self.traceInfoList[traceType][logicId] = traceInfo
      end
    end
  elseif traceType == bigMapModuleEnum.TraceType.ForceTrace then
    if traceInfo then
      if self.traceInfoList[traceType] == nil then
        self.traceInfoList[traceType] = {}
      end
      local trackType = traceInfo.npcInfo and traceInfo.npcInfo.worldMapConf and traceInfo.npcInfo.worldMapConf.default_track_type
      if self.traceInfoList[traceType][trackType] == nil then
        self.traceInfoList[traceType][trackType] = {}
      end
      if #self.traceInfoList[traceType][trackType] > 0 then
        for k, val in ipairs(self.traceInfoList[traceType][trackType]) do
          if val.npcInfo.logic_id == traceInfo.npcInfo.logic_id then
            table.remove(self.traceInfoList[traceType][trackType], k)
            goto lbl_135
          end
        end
      end
      ::lbl_135::
      if self.traceInfoList[traceType][trackType] == nil then
        self.traceInfoList[traceType][trackType] = {}
      end
      table.insert(self.traceInfoList[traceType][trackType], traceInfo)
    end
  elseif traceInfo then
    self.traceInfoList[traceType] = traceInfo
  else
    self.traceInfoList[traceType] = nil
  end
end

function BigMapModuleData:SetCurTraceNpc(entryId, logicId, sceneResId, needTraceOnFogArea)
  local traceInfo = {}
  traceInfo.traceType = bigMapModuleEnum.TraceType.NPC
  traceInfo.sceneResId = sceneResId
  self.module.TraceOnFogArea = needTraceOnFogArea
  if -1 == entryId or nil == entryId then
    if self.HandBookTraceInfo and self.HandBookTraceInfo.npc_trace_info then
      local traceNpcCfgId = self.HandBookTraceInfo.npc_trace_info.npc_cfg_id
      if traceNpcCfgId then
        self.module:OnCmdSendZoneNpcTraceQueryReq({traceNpcCfgId}, true)
      end
      self:RemoveHandBookNpcData(self.HandBookTraceInfo.npc_trace_info)
    end
    self.module:OnCmdStartOrCancelTrace(false, traceInfo)
  else
    for resId, v in pairs(self.npcDatas) do
      for pieceId, npcDatas in pairs(v) do
        if npcDatas[entryId] and npcDatas[entryId][logicId] then
          traceInfo.npcInfo = npcDatas[entryId][logicId]
          local posX = traceInfo.npcInfo.npc_pos.x
          local posY = traceInfo.npcInfo.npc_pos.y
          posX, posY = BigMapUtils.ScenePosToImagePos(resId, posX, posY)
          traceInfo.iconImagePos = {x = posX, y = posY}
          self.module:OnCmdStartOrCancelTrace(true, traceInfo)
          break
        end
      end
    end
  end
  self.traceNpcInfo.npcId = entryId
  self.traceNpcInfo.sceneResId = sceneResId
  local npcData = self:GetCurTraceNpcData(sceneResId)
  if npcData then
    self.traceNpcInfo.refreshId = npcData.npc_refresh_id or 0
    self.traceNpcInfo.worldMapCfgId = npcData.world_map_cfg_id or 0
    self.module.TraceOnFogArea = needTraceOnFogArea
    if npcData.world_map_cfg_id and npcData.world_map_cfg_id > 0 then
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(npcData.world_map_cfg_id)
      if worldMapConf and worldMapConf.map_show_type ~= _G.Enum.MapIconShowType.MAP_HANDBOOK_TRACK and self.HandBookTraceInfo and self.HandBookTraceInfo.npc_trace_info then
        local traceNpcCfgId = self.HandBookTraceInfo.npc_trace_info.npc_cfg_id
        if traceNpcCfgId then
          self.module:OnCmdSendZoneNpcTraceQueryReq({traceNpcCfgId}, true)
        end
        self:RemoveHandBookNpcData(self.HandBookTraceInfo.npc_trace_info)
      end
    end
  else
    self.module.TraceOnFogArea = false
    self.traceNpcInfo.refreshId = 0
  end
  _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.CmdRefreshChallengeItemBtn, self.traceNpcInfo.refreshId)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapTraceNpcState)
end

function BigMapModuleData:SetCurTraceAcceptTask(InTaskId, bFlag)
  if not self.CurTraceAcceptTaskList then
    self.CurTraceAcceptTaskList = {}
  end
  self.CurTraceAcceptTaskList[InTaskId] = bFlag
  _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.TraceAcceptTaskRefresh, InTaskId, bFlag)
end

function BigMapModuleData:GetCurTraceAcceptableTask(InTaskId)
  if not self.CurTraceAcceptTaskList then
    return false
  end
  return self.CurTraceAcceptTaskList[InTaskId] or false
end

function BigMapModuleData:GetAllCurTraceAcceptableTask()
  return self.CurTraceAcceptTaskList or {}
end

function BigMapModuleData:SetCurTraceNpcByRefreshID(_npcRefreshId, sceneResId, needTraceOnFogArea)
  if nil == sceneResId then
    local npcRefreshContent = _G.DataConfigManager:GetNpcRefreshContentConf(_npcRefreshId)
    if npcRefreshContent then
      if npcRefreshContent.refresh_type == Enum.RefreshType.RFT_AREA then
        local areaConf = _G.DataConfigManager:GetAreaConf(npcRefreshContent.refresh_param)
        sceneResId = areaConf.scene_res_id
      elseif npcRefreshContent.refresh_type == Enum.RefreshType.RFT_BYTAGID or npcRefreshContent.refresh_type == Enum.RefreshType.RFT_BYTAG then
        local scene_conf = _G.DataConfigManager:GetSceneObjectConf(npcRefreshContent.refresh_param, true)
        if scene_conf then
          sceneResId = _G.DataConfigManager:GetSceneConf(scene_conf.scene_cfg_id).scene_res_id
        end
      end
    end
  end
  if nil == sceneResId or nil == self.npcDatas[sceneResId] or nil == _npcRefreshId then
    self.module.TraceOnFogArea = false
    return
  end
  for mapPieceId, v in pairs(self.npcDatas[sceneResId]) do
    for entryId, j in pairs(v) do
      for logicId, k in pairs(j) do
        if _npcRefreshId == k.npc_refresh_id then
          local npcId = k.entry_id
          self:SetCurTraceNpc(npcId, logicId, sceneResId, needTraceOnFogArea)
          Log.Debug("BigMapModuleData:SetCurTraceNpcByRefreshID", npcId)
          return k
        end
      end
    end
  end
end

function BigMapModuleData:GetNpcInfoByRefreshId(refreshId, sceneResId)
  if nil == sceneResId then
    local npcRefreshContent = _G.DataConfigManager:GetNpcRefreshContentConf(refreshId)
    if npcRefreshContent then
      if npcRefreshContent.refresh_type == Enum.RefreshType.RFT_AREA then
        local areaConf = _G.DataConfigManager:GetAreaConf(npcRefreshContent.refresh_param)
        sceneResId = areaConf.scene_res_id
      elseif npcRefreshContent.refresh_type == Enum.RefreshType.RFT_BYTAGID or npcRefreshContent.refresh_type == Enum.RefreshType.RFT_BYTAG then
        local scene_conf = _G.DataConfigManager:GetSceneObjectConf(npcRefreshContent.refresh_param, true)
        if scene_conf then
          sceneResId = _G.DataConfigManager:GetSceneConf(scene_conf.scene_cfg_id).scene_res_id
        end
      end
      if nil == refreshId then
        return
      end
      if nil == self.npcDatas[sceneResId] then
        for resId, val in pairs(self.npcDatas) do
          for mapPieceId, val1 in pairs(val) do
            for entryId, val2 in pairs(val1) do
              for logicId, val3 in pairs(val2) do
                if refreshId == val3.npc_refresh_id then
                  return val3, resId
                end
              end
            end
          end
        end
        return
      end
      for mapPieceId, v in pairs(self.npcDatas[sceneResId]) do
        for entryId, j in pairs(v) do
          for logicId, k in pairs(j) do
            if refreshId == k.npc_refresh_id then
              return k
            end
          end
        end
      end
    else
      for resId, val in pairs(self.npcDatas) do
        for mapPieceId, val1 in pairs(val) do
          for npcId, val2 in pairs(val1) do
            for logicId, val3 in pairs(val2) do
              if refreshId == val3.npc_refresh_id then
                return val3
              end
            end
          end
        end
      end
    end
  else
    if nil == refreshId then
      return
    end
    if nil == self.npcDatas[sceneResId] then
    else
      for mapPieceId, v in pairs(self.npcDatas[sceneResId]) do
        for entryId, j in pairs(v) do
          for logicId, k in pairs(j) do
            if refreshId == k.npc_refresh_id then
              return k, sceneResId
            end
          end
        end
      end
    end
    for resId, val in pairs(self.npcDatas) do
      for mapPieceId, val1 in pairs(val) do
        for entryId, val2 in pairs(val1) do
          for logicId, val3 in pairs(val2) do
            if refreshId == val3.npc_refresh_id then
              return val3, resId
            end
          end
        end
      end
    end
  end
end

function BigMapModuleData:GetNpcInfoByConfigId(configId, sceneResId)
  sceneResId = sceneResId or self.curShowSceneResId
  if self.npcDatas[sceneResId] == nil or nil == configId then
    return
  end
  for mapPieceId, v in pairs(self.npcDatas[sceneResId]) do
    for entryId, j in pairs(v) do
      for logicId, k in pairs(j) do
        if configId == k.npc_cfg_id then
          return k
        end
      end
    end
  end
end

function BigMapModuleData:GetNPCInfoByEntryId(entryId, logicId)
  if entryId > 0 then
    for sceneResId, pieceNpcInfos in pairs(self.npcDatas) do
      for mapPiece, npcInfos in pairs(pieceNpcInfos) do
        if npcInfos[entryId] then
          return npcInfos[entryId][logicId]
        end
      end
    end
  end
  return
end

function BigMapModuleData:GetAreaCollectionRate()
  local areaCfg = _G.NRCModuleManager:DoCmd(AreaAndZoneModuleCmd.GetPlayerZoneInfo)
  if nil ~= areaCfg then
    local enteredAreaId = areaCfg.area_id[1]
    for sceneResId, areaDatas in pairs(self.areaDatas) do
      for mapPieceId, areaNameDatas in pairs(areaDatas) do
        for mapConfId, areaData in pairs(areaNameDatas) do
          local areaIds = areaData.config.area_id
          if areaIds and #areaIds > 0 then
            for i = 1, #areaIds do
              if areaIds[i] == enteredAreaId then
                self.mapShowDatas = {
                  collectionRate = areaData.collectionRate,
                  mapName = areaData.config.zone_name
                }
              end
            end
          end
        end
      end
    end
  end
end

function BigMapModuleData:IsGetAreaManual()
  local guidebookInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerGuide_BooksInfo()
  local atlasId = self:GetSecondAreaConf()
  if nil == atlasId then
    return nil
  end
  if guidebookInfo and #guidebookInfo > 0 then
    for i, bookInfo in ipairs(guidebookInfo) do
      local WorldMapAreaGuide = _G.DataConfigManager:GetWorldMapAreaGuide(bookInfo.id)
      for j, WorldMapArea in ipairs(WorldMapAreaGuide.area_func_id) do
        if atlasId == WorldMapArea then
          return WorldMapAreaGuide, atlasId
        end
      end
    end
    return nil
  end
end

function BigMapModuleData:GetSecondAreaConf()
  local PlayerZoneArray = _G.NRCModeManager:DoCmd(AreaAndZoneModuleCmd.GetPlayerZoneArray)
  if not PlayerZoneArray._items then
    return nil
  end
  if PlayerZoneArray._items[1] == nil then
    return nil
  end
  local PlayPlaceNameId = PlayerZoneArray._items[1].id
  local CampConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CAMP_CONF):GetAllDatas()
  local WeatherAreaId, AreaConfId
  for j, Levelup in pairs(CampConf) do
    if PlayPlaceNameId == Levelup.broadcast_name_func_id then
      WeatherAreaId = Levelup.weather_area_id
    end
  end
  if WeatherAreaId then
    local AreaFuncConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.AREA_FUNC_CONF):GetAllDatas()
    for j, FuncConf in pairs(AreaFuncConf) do
      if WeatherAreaId == FuncConf.area_id[1] then
        AreaConfId = FuncConf.id
      end
    end
  else
    local WorldMapAreaGuide = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.WORLD_MAP_AREA_GUIDE):GetAllDatas()
    for i, item in ipairs(PlayerZoneArray._items) do
      for j, WorldMapArea in ipairs(WorldMapAreaGuide) do
        if item.id == WorldMapArea.area_func_id[1] then
          return WorldMapArea.area_func_id[1]
        end
      end
    end
  end
  return AreaConfId
end

function BigMapModuleData:GetCurMapLayerId()
  local PlayerZoneArray = _G.NRCModeManager:DoCmd(AreaAndZoneModuleCmd.GetPlayerZoneArray)
  if not PlayerZoneArray._items then
    return nil
  end
  if #PlayerZoneArray._items > 0 then
    for k, areaInfo in ipairs(PlayerZoneArray._items) do
      if areaInfo.id and areaInfo.id > 0 and self.AreaFuncIdToLayerInfo[areaInfo.id] then
        return self.AreaFuncIdToLayerInfo[areaInfo.id].id
      end
    end
  end
  return 0
end

function BigMapModuleData:GetAreaManualInfo()
  local atlasId = self:GetSecondAreaConf()
  if nil == atlasId then
    return nil
  end
  local MapAreaGuide = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_AREA_GUIDE):GetAllDatas()
  for i, AreaGuide in ipairs(MapAreaGuide) do
    for j, Area_Guide in ipairs(AreaGuide.area_func_id) do
      if atlasId == Area_Guide then
        return AreaGuide
      end
    end
  end
  return nil
end

function BigMapModuleData:GetBroadcastArea()
  local PlayerZoneArray = _G.NRCModeManager:DoCmd(AreaAndZoneModuleCmd.GetPlayerZoneArray)
  if not PlayerZoneArray._items then
    return nil
  end
  local CampConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CAMP_CONF):GetAllDatas()
  for i, item in ipairs(PlayerZoneArray._items) do
    for j, Levelup in pairs(CampConf) do
      if item.id == Levelup.broadcast_name_func_id then
        return item.id
      end
    end
  end
end

function BigMapModuleData:SetHandBookTrackInfo(traceInfo)
  local traceNpcInfo = traceInfo.npc_trace_info
  if nil == traceNpcInfo then
    return
  end
  if self.HandBookTraceInfo and self.HandBookTraceInfo.npc_trace_info then
    self:RemoveHandBookNpcData(self.HandBookTraceInfo.npc_trace_info)
  end
  if nil == traceNpcInfo.content_id and nil == traceNpcInfo.npc_obj_id then
    local handBookMapCfgId = _G.DataConfigManager:GetPetGlobalConfig("hd_track_world_map_id").num
    if self.traceNpcInfo.worldMapCfgId and self.traceNpcInfo.worldMapCfgId == handBookMapCfgId then
      self:SetCurTraceNpc(-1)
    end
    return
  end
  self.HandBookTraceInfo = traceInfo
  self:UpdateHandBookTraceNpcData(traceNpcInfo)
  local posX = traceNpcInfo.pt.pos.x or 0
  local posY = traceNpcInfo.pt.pos.y or 0
  local npcSceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
  self:SetCurTraceNpcByRefreshID(traceNpcInfo.content_id, npcSceneResId, true)
end

function BigMapModuleData:SetAccessTaskInfo(_AcceptTaskList)
  local AccessTaskInfo = {}
  for i, TaskInfo in pairs(_AcceptTaskList) do
    local Position = {}
    table.insert(Position, {
      pos = TaskInfo:GetServerPosition()
    })
    if TaskInfo.TaskConfig and Position and #Position > 0 then
      table.insert(AccessTaskInfo, {
        NpcPosition = Position,
        TaskConf = TaskInfo.TaskConfig,
        TaskShowType = bigMapModuleEnum.TaskShowType.UNDO,
        TaskSceneResId = TaskInfo:GetSceneID()
      })
    end
  end
  self.AccessTaskInfoList = AccessTaskInfo
  if self.CurTraceAcceptTaskList then
    for taskId, _ in pairs(self.CurTraceAcceptTaskList) do
      local bFound = false
      for i, taskInfo in pairs(self.AccessTaskInfoList) do
        if taskInfo.TaskConf and taskInfo.TaskConf.id == taskId then
          bFound = true
          break
        end
      end
      if not bFound then
        self.CurTraceAcceptTaskList[taskId] = nil
      end
    end
  end
  _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.AcceptTaskRefresh)
end

function BigMapModuleData:GetAccessTaskInfoList()
  return self.AccessTaskInfoList
end

function BigMapModuleData:SetJourneyTaskInfo(taskList)
  self.JourneyTaskInfo = taskList
end

function BigMapModuleData:SetParentTaskList(_ParentTaskList)
  self.ParentTaskList = _ParentTaskList
end

function BigMapModuleData:GetParentTaskList()
  return self.ParentTaskList
end

function BigMapModuleData:GenerateActivityTaskInfo(_position, _taskConf, _wordMapConfId)
  if self.showTaskInfo and _position and _taskConf then
    for k, v in pairs(self.showTaskInfo) do
      if v.TaskConf and v.TaskConf == _taskConf then
        return
      end
    end
    table.insert(self.showTaskInfo, {
      NpcPosition = {
        {
          pos = {
            x = _position[1],
            y = _position[2],
            z = _position[3]
          }
        }
      },
      TaskConf = _taskConf,
      TaskShowType = bigMapModuleEnum.TaskShowType.UNDO,
      SpecialTaskType = "TreasureDig",
      world_map_cfg_id = _wordMapConfId,
      TaskSceneResId = self:GetCurSceneResId()
    })
  end
end

function BigMapModuleData:GenerateActivityTaskPanelInfo(_position, _taskConf)
  if self.ShowTaskPanelInfo and _position and _taskConf then
    for k, v in pairs(self.ShowTaskPanelInfo) do
      if v.TaskConf and v.TaskConf == _taskConf then
        return
      end
    end
    table.insert(self.ShowTaskPanelInfo, {
      NpcPosition = {
        {
          pos = {
            x = _position[1],
            y = _position[2],
            z = _position[3]
          }
        }
      },
      TaskConf = _taskConf,
      TaskShowType = bigMapModuleEnum.TaskShowType.ACCEPTED
    })
  end
end

function BigMapModuleData:CreateShowTaskInfo()
  local showTaskInfo = {}
  local MapTaskList = NRCModeManager:DoCmd(TaskModuleCmd.GetMapTaskList)
  for i, Task in pairs(MapTaskList) do
    if Task.Trackers and #Task.Trackers > 0 then
      for j, Tracker in ipairs(Task.Trackers) do
        local TaskShowType = Tracker.TaskObject.isTrack and bigMapModuleEnum.TaskShowType.TRACING or bigMapModuleEnum.TaskShowType.ACCEPTED
        local Position = {}
        local TaskSceneList = {}
        if Tracker.TargetMapID and 0 ~= Tracker.TargetMapID then
          TaskSceneList[Tracker.TargetMapID] = true
        end
        if Tracker.DestMapID and 0 ~= Tracker.DestMapID then
          TaskSceneList[Tracker.DestMapID] = true
        end
        if Tracker.MapID and 0 ~= Tracker.MapID then
          TaskSceneList[Tracker.MapID] = true
        end
        for TaskSceneResId, _ in pairs(TaskSceneList) do
          local PosList = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetTrackerPosBySceneID, Tracker.TaskObject.Config.id, TaskSceneResId)
          if PosList and #PosList > 0 then
            local pos = PosList[Tracker.go_index]
            if pos then
              local _pos = {
                x = pos.X,
                y = pos.Y,
                z = pos.Z
              }
              table.insert(Position, {pos = _pos})
            else
              pos = PosList[1]
              if pos then
                local _pos = {
                  x = pos.X,
                  y = pos.Y,
                  z = pos.Z
                }
                table.insert(Position, {pos = _pos})
              end
            end
          end
          if Tracker.TaskObject.TrackParentTask then
            if Tracker.TaskObject.TrackParentTask.isTrack then
              TaskShowType = bigMapModuleEnum.TaskShowType.TRACING
            end
            local TrackTask = NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
            if TrackTask then
              if Tracker.TaskObject.Config.id == TrackTask.Config.id then
                if Position and #Position > 0 then
                  table.insert(showTaskInfo, {
                    NpcPosition = Position,
                    TaskConf = Tracker.TaskObject.Config,
                    TaskShowType = TaskShowType,
                    SubTaskId = Tracker.TaskObject.Config.id,
                    go_index = Tracker.go_index,
                    TaskSceneResId = TaskSceneResId
                  })
                end
              elseif Position and #Position > 0 then
                table.insert(showTaskInfo, {
                  NpcPosition = Position,
                  TaskConf = Tracker.TaskObject.TrackParentTask.Config,
                  TaskShowType = TaskShowType,
                  SubTaskId = Tracker.TaskObject.Config.id,
                  go_index = Tracker.go_index,
                  TaskSceneResId = TaskSceneResId
                })
              end
            elseif Position and #Position > 0 then
              table.insert(showTaskInfo, {
                NpcPosition = Position,
                TaskConf = Tracker.TaskObject.TrackParentTask.Config,
                TaskShowType = TaskShowType,
                SubTaskId = Tracker.TaskObject.Config.id,
                go_index = Tracker.go_index,
                TaskSceneResId = TaskSceneResId
              })
            end
          elseif Position and #Position > 0 then
            table.insert(showTaskInfo, {
              NpcPosition = Position,
              TaskConf = Tracker.TaskObject.Config,
              TaskShowType = TaskShowType,
              SubTaskId = Tracker.TaskObject.Config.id,
              go_index = Tracker.go_index,
              TaskSceneResId = TaskSceneResId
            })
          end
          if not Position or #Position > 0 then
          end
        end
      end
    end
  end
  if self.AccessTaskInfoList and #self.AccessTaskInfoList > 0 then
    for k, v in ipairs(self.AccessTaskInfoList) do
      table.insert(showTaskInfo, {
        NpcPosition = v.NpcPosition,
        TaskConf = v.TaskConf,
        TaskShowType = bigMapModuleEnum.TaskShowType.UNDO,
        TaskSceneResId = v.TaskSceneResId
      })
    end
  end
  self.showTaskInfo = showTaskInfo
end

function BigMapModuleData:UpdateTaskPos()
  if self.showTaskInfo and #self.showTaskInfo > 0 then
    for i, Task in ipairs(self.showTaskInfo) do
      local Position = {}
      local TaskPos = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetTrackerPosBySceneID, Task.SubTaskId, self.curShowSceneResId)
      if TaskPos and #TaskPos > 0 then
        local pos = TaskPos[Task.go_index]
        if pos then
          local _pos = {
            x = pos.X,
            y = pos.Y,
            z = pos.Z
          }
          table.insert(Position, {pos = _pos})
          Task.NpcPosition = Position
        else
          pos = TaskPos[1]
          if pos then
            local _pos = {
              x = pos.X,
              y = pos.Y,
              z = pos.Z
            }
            table.insert(Position, {pos = _pos})
            Task.NpcPosition = Position
          end
        end
      end
    end
  end
end

function BigMapModuleData:IsInScene(TargetMapID)
  if #self.MapShowList > 0 then
    local realShowMapList = {}
    local showList = {}
    for k, v in pairs(self.MapShowList) do
      if v.sceneResId == self:GetCurSceneResId() then
        showList = v.Conf.map_same_group
        break
      end
    end
    if showList and #showList > 0 then
      for k, v in ipairs(showList) do
        for key, listData in pairs(self.MapShowList) do
          if listData.Conf.id == v then
            table.insert(realShowMapList, listData)
          end
        end
      end
    end
    if realShowMapList and #realShowMapList > 0 then
      for i, realShowMap in ipairs(realShowMapList) do
        if TargetMapID == realShowMap.sceneResId then
          return true
        end
      end
    else
      Log.Error("\232\175\183\230\163\128\230\159\165\228\184\139\230\137\147\229\188\128\229\156\176\229\155\190\229\175\185\229\186\148\231\154\132sceneResId\229\156\176\229\155\190\230\152\175\229\144\166\232\167\163\233\148\129")
    end
  else
    Log.Error("\231\142\169\229\174\182\230\178\161\230\156\137\229\143\175\231\148\168\229\156\176\229\155\190\229\143\175\228\187\165\230\137\147\229\188\128")
  end
  return false
end

function BigMapModuleData:IsTrackSubTasks(parent_list, task_id)
  if parent_list and #parent_list > 0 then
    for k, v in ipairs(parent_list) do
      if v.task_id == task_id then
        local TaskConf = _G.DataConfigManager:GetTaskConf(v.parent_task_id)
        return TaskConf
      end
    end
  end
  return nil
end

function BigMapModuleData:IsTrackTask(task_id, Config)
  local TaskObject = NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskObjectByTaskId, task_id)
  local TaskMapTrack = NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
  if TaskObject and TaskObject.Info and TaskObject.Info.is_track then
    return true, TaskObject.Config
  elseif self.ParentTaskList then
    for i, Task in ipairs(self.ParentTaskList) do
      if Task.task_id == task_id then
        if TaskMapTrack and TaskMapTrack.Config.id == Task.parent_task_id then
          return true, TaskMapTrack.Config, task_id
        else
          local TaskConf = _G.DataConfigManager:GetTaskConf(Task.parent_task_id)
          return false, TaskConf, task_id
        end
      end
    end
  end
  return false, Config
end

function BigMapModuleData:IsHasTask(task_id, go_index)
  for i, ShowTask in ipairs(self.showTaskInfo) do
    if ShowTask.go_index and go_index then
      if task_id == ShowTask.TaskConf.id and ShowTask.go_index == go_index then
        return true
      end
    elseif task_id == ShowTask.TaskConf.id then
      return true
    end
  end
  return false
end

function BigMapModuleData:SetOpenTaskId(_param)
  if _param and _param.TaskId then
    self.SelectTaskId = _param.TaskId
    self.OpenTaskId = _param.TaskId
  else
    local TaskMapTrack = NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
    self.OpenTaskId = TaskMapTrack and TaskMapTrack.Config and TaskMapTrack.Config.id
    self.SelectTaskId = nil
  end
end

function BigMapModuleData:GetSelectTaskId()
  return self.SelectTaskId
end

function BigMapModuleData:GetOpenTaskId()
  return self.OpenTaskId
end

function BigMapModuleData:GetShowTaskInfo()
  return self.showTaskInfo
end

function BigMapModuleData:SetShowTaskInfo(_showTaskInfo)
  self.showTaskInfo = _showTaskInfo or {}
end

function BigMapModuleData:GetShowTaskPanelInfo()
  return self.ShowTaskPanelInfo
end

function BigMapModuleData:SetCustomPointInfo(_CustomPointInfo, IsPlayRemoveSound)
  if nil == _CustomPointInfo then
    self.CustomPointInfo = {}
  else
    self.CustomPointInfo = _CustomPointInfo
  end
end

function BigMapModuleData:GetCustomPointInfo()
  return self.CustomPointInfo
end

function BigMapModuleData:SetNewCustomPointInfo(_NewCustomPointInfo)
  local IsHasMark = self:GetNewCustomPointById(_NewCustomPointInfo.mark_id)
  if IsHasMark then
    self:SetNewCustomPointByWorldMapEntryMark(_NewCustomPointInfo)
  else
    _NewCustomPointInfo.is_track = false
    table.insert(self.NewCustomPointInfo, _NewCustomPointInfo)
  end
  self:SetLayerIdToIcons(_NewCustomPointInfo.layer_id or 0, bigMapModuleEnum.CreatorPriority.MarkerIcons, _NewCustomPointInfo.mark_id)
end

function BigMapModuleData:GetNewCustomPointInfo()
  return self.NewCustomPointInfo
end

function BigMapModuleData:GetNewCustomPointById(_mark_id)
  for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
    if NewCustomPoint.mark_id == _mark_id then
      return NewCustomPoint
    end
  end
  return nil
end

function BigMapModuleData:GetNewCustomPointNumByMapCfgId(MapCfgId)
  local Num = 0
  for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
    if NewCustomPoint.world_map_cfg_id == MapCfgId then
      Num = Num + 1
    end
  end
  return Num
end

function BigMapModuleData:GetNewCustomPointListByType(type)
  local NewCustomPointList = {}
  for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
    if NewCustomPoint.type == type then
      table.insert(NewCustomPointList, NewCustomPoint)
    end
  end
  return NewCustomPointList
end

function BigMapModuleData:SetNewCustomPointByWorldMapEntryMark(_NewCustomPointInfo)
  for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
    if NewCustomPoint.mark_id == _NewCustomPointInfo.mark_id then
      local is_track = self.NewCustomPointInfo[i].is_track
      self.NewCustomPointInfo[i] = _NewCustomPointInfo
      self.NewCustomPointInfo[i].is_track = is_track
      break
    end
  end
end

function BigMapModuleData:SetNewCustomPointBTrack()
  for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
    if NewCustomPoint.is_track then
      NewCustomPoint.is_track = not NewCustomPoint.is_track
    end
  end
end

function BigMapModuleData:SetNewCustomPointTrackByMarkId(MarkId, is_track)
  for i = #self.NewCustomPointInfo, 1, -1 do
    if self.NewCustomPointInfo[i].mark_id == MarkId then
      if not is_track then
        self:CanNpcCelTrack()
      end
      self.NewCustomPointInfo[i].is_track = not self.NewCustomPointInfo[i].is_track
      _G.DataModelMgr.PlayerDataModel:UpdateWorldMapMarkEntryInfo(self.NewCustomPointInfo[i], false)
    elseif not is_track then
      self.NewCustomPointInfo[i].is_track = false
    end
  end
end

function BigMapModuleData:CanNpcCelTrack()
  local traceNpcId = self:GetCurTraceNpcId()
  if traceNpcId then
    self:DispatchEvent(BigMapModuleEvent.CancelTraceNpcEvent, traceNpcId, true)
  end
end

function BigMapModuleData:RemoveNewCustomPointByMarkId(MarkId)
  for i = #self.NewCustomPointInfo, 1, -1 do
    if self.NewCustomPointInfo[i].mark_id == MarkId then
      _G.DataModelMgr.PlayerDataModel:UpdateWorldMapMarkEntryInfo(self.NewCustomPointInfo[i], true)
      table.remove(self.NewCustomPointInfo, i)
      break
    end
  end
end

function BigMapModuleData:updateNewCustomPoint(mark_entrys)
  if mark_entrys and #mark_entrys > 0 then
    local traceMarkId
    for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
      if NewCustomPoint.is_track then
        traceMarkId = NewCustomPoint.mark_id
        break
      end
    end
    self.NewCustomPointInfo = {}
    for _, v in pairs(mark_entrys) do
      self:SetNewCustomPointInfo(v)
    end
    for i, NewCustomPoint in ipairs(self.NewCustomPointInfo) do
      if NewCustomPoint.mark_id == traceMarkId then
        self.NewCustomPointInfo[i].is_track = true
        break
      end
    end
  else
    self.NewCustomPointInfo = {}
  end
end

function BigMapModuleData:SetSelectMarkerType(SelectMarkerType)
  self.SelectMarkerType = SelectMarkerType
end

function BigMapModuleData:GetSelectMarkerType()
  return self.SelectMarkerType
end

function BigMapModuleData:AddChanged_entries(_MapInfo)
  table.insert(self.changed_entries, _MapInfo)
end

function BigMapModuleData:ClearChanged_entries()
  table.clear(self.changed_entries)
end

function BigMapModuleData:GetChanged_entries()
  return self.changed_entries
end

function BigMapModuleData:GetCompassShowDistance()
  return self.CompassShowDistance
end

function BigMapModuleData:GetGuideBooksRedDot()
  return self.GuideBooksRedDot
end

function BigMapModuleData:SetGuideBooksRedDot(_GuideBooksRedDot)
  self.GuideBooksRedDot = _GuideBooksRedDot
end

function BigMapModuleData:IsOpenTravel()
  return self.isOpenTravel
end

function BigMapModuleData:SetCampFruitNpcsInfo(fruitNpcsInfo)
  local allPlayerFruitInfo = {}
  local TempAllPlayerFruitInfo = _G.DataModelMgr.PlayerDataModel:GetAllPlayerOwlSanctuaryNpcInfo()
  if nil == TempAllPlayerFruitInfo or nil == next(TempAllPlayerFruitInfo) then
    self.CampFruitNpcsInfoList = fruitNpcsInfo
    self:DispatchEvent(BigMapModuleEvent.CampFruitNpcsInfoListSetFinish, fruitNpcsInfo)
    return
  else
    for _, OwlSanctuary in pairs(TempAllPlayerFruitInfo) do
      local uin = OwlSanctuary.uin
      for _, OwlSanctuaryInfo in pairs(OwlSanctuary.owl_sanctuarys) do
        allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id] = allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id] or {}
        allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id][uin] = {
          owl_content_id = OwlSanctuaryInfo.npc_content_id,
          uin = uin,
          fruit_infos = {},
          npc_pos = OwlSanctuaryInfo.npc_pos
        }
        if nil ~= next(OwlSanctuaryInfo.fruit_brief_infos) then
          for key, value in ipairs(OwlSanctuaryInfo.fruit_brief_infos) do
            allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id][uin].fruit_infos[key] = value
          end
        end
      end
    end
  end
  for idx1, campFruitNpcInfo in pairs(fruitNpcsInfo) do
    if nil == campFruitNpcInfo.owl_sanctuary_fruit_npc_info then
    else
      for idx2, campLinkOwlInfo in pairs(campFruitNpcInfo.owl_sanctuary_fruit_npc_info) do
        campLinkOwlInfo.NpcInfo = {}
        if nil == allPlayerFruitInfo[campLinkOwlInfo.owl_sanctuary_content_id] or nil == next(allPlayerFruitInfo[campLinkOwlInfo.owl_sanctuary_content_id]) then
        else
          for uin, owlSanctuaryInfo in pairs(allPlayerFruitInfo[campLinkOwlInfo.owl_sanctuary_content_id]) do
            if owlSanctuaryInfo.owl_content_id ~= campLinkOwlInfo.owl_sanctuary_content_id or nil == owlSanctuaryInfo.fruit_infos then
            else
              local temp = 0
              for idx4, fruitInfo in pairs(owlSanctuaryInfo.fruit_infos) do
                if 0 ~= fruitInfo.fruit_id then
                  if nil == fruitInfo.npc_id or 0 == #fruitInfo.npc_id then
                    local petBaseId = _G.NRCModuleManager:DoCmd(SleepingOwlModuleCmd.GetPetbaseIdByFruitId, fruitInfo.fruit_id, owlSanctuaryInfo.owl_content_id)
                    local petBaseConf = DataConfigManager:GetPetbaseConf(petBaseId, true)
                    if petBaseConf and petBaseConf.npc_id then
                      local NpcInfo = {
                        npc_id = petBaseConf.npc_id,
                        uin = uin,
                        fruit_active_timestamp = fruitInfo.fruit_active_timestamp,
                        slot_active_timestamp = fruitInfo.slot_active_timestamp
                      }
                      table.insert(campLinkOwlInfo.NpcInfo, NpcInfo)
                    end
                  else
                    local NpcInfo = {
                      npc_id = fruitInfo.npc_id,
                      uin = uin,
                      fruit_active_timestamp = fruitInfo.fruit_active_timestamp,
                      slot_active_timestamp = fruitInfo.slot_active_timestamp
                    }
                    table.insert(campLinkOwlInfo.NpcInfo, 1 + temp, NpcInfo)
                    temp = temp + 1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  self.CampFruitNpcsInfoList = fruitNpcsInfo
  self:DispatchEvent(BigMapModuleEvent.CampFruitNpcsInfoListSetFinish, fruitNpcsInfo)
end

function BigMapModuleData:GetCampFruitNpcInfoByCampcontentId(camp_content_id)
  if self.CampFruitNpcsInfoList == nil then
    return nil
  end
  for key, value in pairs(self.CampFruitNpcsInfoList) do
    if value.camp_content_id == camp_content_id then
      return value
    end
  end
end

function BigMapModuleData:CalcCampFruitTotalSpriteNum()
  local npcRefreshContentDatas = self.npcRefreshContentDatas
  local mapShowPetList = {}
  for k, npcRefreshContentData in pairs(npcRefreshContentDatas) do
    if npcRefreshContentData.belong_camp and npcRefreshContentData.belong_camp > 0 then
      local npcID = npcRefreshContentData.npc_id
      local campId = npcRefreshContentData.belong_camp
      if nil == mapShowPetList[campId] then
        mapShowPetList[campId] = {}
      end
      local npcInfoDatas = _G.DataConfigManager:GetNpcConf(npcID)
      if npcInfoDatas.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_PETBASE then
        local petBaseId = npcInfoDatas.traverse_data_param[1]
        if not self:HasPetBaseId(petBaseId, mapShowPetList[campId]) and self:ShowInNPCInfoList(npcRefreshContentData.id) and self:GetPetItemData(petBaseId) then
          table.insert(mapShowPetList[campId], self:GetPetItemData(petBaseId))
        end
      end
    end
  end
  self.TotalCampSpriteList = mapShowPetList
end

function BigMapModuleData:SetCurDropMethodInfo()
  self.curDropMethodInfo = {}
end

function BigMapModuleData:GetCurDropMethodInfo()
  return self.curDropMethodInfo
end

function BigMapModuleData:GetPetItemData(petBaseId)
  local data = {}
  local evoDatas = {}
  if nil == petBaseId then
    Log.Error("petBaseId is nil")
    return
  end
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  local evoId = petbaseConf.pet_evolution_id[1]
  local evoConf = _G.DataConfigManager:GetPetEvolutionConf(evoId)
  local evoIds = {}
  if nil == evoConf then
    Log.Error("id:", evoId, "\229\156\168PetEvolutionConf\228\184\173\230\178\161\230\156\137\233\133\141\231\189\174")
    return
  else
    local evoInfos = evoConf.evolution_chain
    for i = 1, #evoInfos do
      table.insert(evoIds, evoInfos[i].petbase_id)
    end
  end
  for i = 1, #evoIds do
    local baseId = evoIds[i]
    local evoData = {}
    evoData.petBaseConfId = baseId
    evoData.state = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetState, baseId)
    local FirstStageBaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
    if FirstStageBaseConf and FirstStageBaseConf.pictorial_book_id then
      evoData.handbookId = FirstStageBaseConf.pictorial_book_id
    else
      evoData.handbookId = 0
    end
    if 1 == FirstStageBaseConf.stage then
      data.FirstStageBaseConf = baseId
    end
    table.insert(evoDatas, evoData)
  end
  data.evoDatas = evoDatas
  data.petBaseConfId = petBaseId
  data.handbookId = _G.DataConfigManager:GetPetbaseConf(petBaseId).pictorial_book_id
  return data
end

function BigMapModuleData:HasPetBaseId(baseId, table)
  local BaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
  if not BaseConf then
    return false
  end
  local bookid = BaseConf.pictorial_book_id
  if 0 == bookid then
    return true
  end
  if 0 == #table then
    return false
  end
  for i = 1, #table do
    local evoDatas = table[i].evoDatas or {}
    for j = 1, #evoDatas do
      if evoDatas[j].petBaseConfId == baseId then
        return true
      end
    end
  end
  return false
end

function BigMapModuleData:ShowInNPCInfoList(npcContentId)
  self:GetContentIdToRuleMap()
  local playerLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local ruleCfg = self.ContentIdToRuleMap[npcContentId]
  if nil == ruleCfg then
    return true
  end
  if #ruleCfg.condition > 0 and ruleCfg.condition[1].condition_type == _G.Enum.TriggerConditionType.TRCT_ROLE_LEVEL then
    local lvLimit = string.split(ruleCfg.condition[1].condition_param, ";")
    if 2 == #lvLimit then
      if playerLv >= tonumber(lvLimit[1]) and playerLv <= tonumber(lvLimit[2]) then
        return true
      else
        return false
      end
    elseif playerLv >= tonumber(lvLimit[1]) then
      return true
    else
      return false
    end
  else
  end
  return true
end

function BigMapModuleData:BuildRefreshContentIdToRulesMap()
  local ruleTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.NPC_REFRESH_RULE_CONF)
  local ruleConfs = ruleTable:GetAllDatas()
  self.ContentIdToRuleMap = {}
  for _, conf in pairs(ruleConfs) do
    for _, content in ipairs(conf.contents) do
      self.ContentIdToRuleMap[content.content_id] = conf
    end
  end
end

function BigMapModuleData:GetContentIdToRuleMap()
  if self.ContentIdToRuleMap == nil then
    self:BuildRefreshContentIdToRulesMap()
  end
  return self.ContentIdToRuleMap
end

function BigMapModuleData:BuildAreaFuncIdToLayerMapInfo()
  local layerMapInfos = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LAYERED_WORLD_MAP_CONF):GetAllDatas()
  if layerMapInfos then
    for k, v in pairs(layerMapInfos) do
      if v.area_func_id and v.area_func_id > 0 then
        self.AreaFuncIdToLayerInfo[v.area_func_id] = v
      end
    end
  end
end

function BigMapModuleData:BuildLayerGroupIdToLayerMapIds()
  local layerMapInfos = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LAYERED_WORLD_MAP_CONF):GetAllDatas()
  if layerMapInfos then
    for k, v in pairs(layerMapInfos) do
      if self.LayerGroupIdToLayerMapIds[tonumber(v.map_layer_group)] == nil then
        self.LayerGroupIdToLayerMapIds[tonumber(v.map_layer_group)] = {}
      end
      table.insert(self.LayerGroupIdToLayerMapIds[tonumber(v.map_layer_group)], v)
    end
  end
  for k, v in ipairs(self.LayerGroupIdToLayerMapIds) do
    table.sort(v, function(a, b)
      return a.map_sort_order < b.map_sort_order
    end)
  end
end

function BigMapModuleData:BuildAreaIdToAreaFuncIdMap()
  local areaFuncIdTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.AREA_FUNC_CONF):GetAllDatas()
  for k, v in pairs(areaFuncIdTable) do
    for key, areaId in ipairs(v.area_id) do
      if areaId > 0 then
        self.AreaIdToAreaFuncId[areaId] = k
      end
    end
  end
end

function BigMapModuleData:BuildNpcIdToExploreInfo()
  local worldExploreTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_EXPLORING_STATISTIC_CONF):GetAllDatas()
  for k, v in pairs(worldExploreTable) do
    if v.option and #v.option > 0 then
      for key, info in ipairs(v.option) do
        for i, npcId in ipairs(info.npc_id) do
          self.npcIdToExploreInfo[npcId] = v.Type
        end
      end
    end
  end
end

function BigMapModuleData:BuildSceneResIdToBlockMap()
  local blockConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_BLOCK_CONF):GetAllDatas()
  for k, v in ipairs(blockConf) do
    if self.sceneResIdToBlockConf[v.scene_res_id] == nil then
      self.sceneResIdToBlockConf[v.scene_res_id] = {}
    end
    self.sceneResIdToBlockConf[v.scene_res_id] = v
  end
end

function BigMapModuleData:SetMapConstData()
  local sceneOffsetX = 306000.0
  local sceneOffsetY = 408000.0
  local sceneWidth = 408000.0
  local sceneHeight = 408000.0
  if self.sceneResIdToBlockConf then
    for sceneResId, blockConf in pairs(self.sceneResIdToBlockConf) do
      if self.mapConstData[sceneResId] == nil then
        self.mapConstData[sceneResId] = {}
      end
      if blockConf.map_center_position_xyz then
        local centerPos = string.Split(blockConf.map_center_position_xyz, ";")
        if centerPos and #centerPos > 2 then
          local centerPosX = tonumber(centerPos[1])
          local centerPosY = tonumber(centerPos[2])
          sceneWidth = blockConf.side_length
          sceneHeight = blockConf.side_length
          if sceneWidth > 0 and sceneHeight > 0 then
            sceneOffsetX = centerPosX - sceneWidth / 2
            sceneOffsetY = centerPosY - sceneHeight / 2
          end
        end
      end
      self.mapConstData[sceneResId].sceneWidth = sceneWidth
      self.mapConstData[sceneResId].sceneHeight = sceneHeight
      self.mapConstData[sceneResId].sceneOffsetX = sceneOffsetX
      self.mapConstData[sceneResId].sceneOffsetY = sceneOffsetY
    end
  end
end

function BigMapModuleData:BuildLogicIdToNpcInfo(logicId, npcInfo)
  if logicId then
    self.LogicIdToNpcInfo[logicId] = npcInfo
    if self:CheckAutoTrackingByLogicId(logicId) then
      self:OnAutoTrackNpcListChanged(true, npcInfo)
    end
  end
end

function BigMapModuleData:AddToDefaultTrackNpcMap(npcData, bAll)
  if not npcData or not npcData.logic_id then
    return
  end
  local worldMapConf = npcData.worldMapConf
  if worldMapConf then
    local defaultTrackType = worldMapConf.default_track_type
    if self.defaultTrackNpcMap[defaultTrackType] == nil then
      self.defaultTrackNpcMap[defaultTrackType] = {}
    end
    local defaultTrackNpcList = self.defaultTrackNpcMap[defaultTrackType]
    if defaultTrackNpcList then
      if #defaultTrackNpcList > 0 then
        for i = #defaultTrackNpcList, 1, -1 do
          if defaultTrackNpcList[i].logic_id == npcData.logic_id then
            return
          end
        end
      end
      table.insert(defaultTrackNpcList, npcData)
      if not bAll then
        _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.DefaultTrackNpcChange)
        self.module:SetForceTrace(npcData)
      end
    end
  end
end

function BigMapModuleData:RemoveFromDefaultTrackNpcMap(defaultTrackType, logicId)
  if not logicId then
    return
  end
  local defaultTrackList = self.defaultTrackNpcMap[defaultTrackType]
  if defaultTrackList and #defaultTrackList > 0 then
    for i = #defaultTrackList, 1, -1 do
      if defaultTrackList[i].logic_id == logicId then
        table.remove(self.defaultTrackNpcMap[defaultTrackType], i)
        _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.DefaultTrackNpcChange)
        break
      end
    end
  end
  if defaultTrackList and #defaultTrackList > 0 then
    self.module:SetForceTrace(defaultTrackList[#defaultTrackList])
  end
end

function BigMapModuleData:GetDefaultTrackNpcList(defaultTrackType)
  if defaultTrackType then
    return self.defaultTrackNpcMap[defaultTrackType]
  else
    return self.defaultTrackNpcMap
  end
end

function BigMapModuleData:SortDefaultTrackNpcList()
  if self.defaultTrackNpcMap then
    for defaultTrackType, defaultTrackList in pairs(self.defaultTrackNpcMap) do
      if defaultTrackList and #defaultTrackList > 1 then
        table.sort(defaultTrackList, function(a, b)
          return a.bornTimeStamp < b.bornTimeStamp
        end)
      end
      local limitNum = self.module:GetForceTrackLimit(defaultTrackType)
      local limitNo = #defaultTrackList - limitNum > 0 and #defaultTrackList - limitNum or 0
      local startNo = limitNo + 1
      if startNo > 0 and startNo <= #defaultTrackList then
        for i = #defaultTrackList, startNo, -1 do
          self.module:SetForceTrace(defaultTrackList[i])
        end
      end
    end
  end
  _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.DefaultTrackNpcChange)
end

function BigMapModuleData:BuildMapIdToMapActivityConf()
  local worldMapActivityConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.WORLD_MAP_ACTIVITY_CONF):GetAllDatas()
  if worldMapActivityConf then
    for k, v in pairs(worldMapActivityConf) do
      self.MapIdToMapActivityConf[v.world_map_id] = v
      self.areaFuncIdToMapActivityConf[v.area_func_id] = v
    end
  end
end

function BigMapModuleData:GetMapActivityConfByMapId(mapId)
  return self.MapIdToMapActivityConf[mapId]
end

function BigMapModuleData:GetNpcInfoByLogicId(logicId)
  if logicId then
    return self.LogicIdToNpcInfo[logicId]
  end
  return nil
end

function BigMapModuleData:GetExploreTypeByNpcConfId(npcConfId)
  return self.npcIdToExploreInfo[npcConfId]
end

function BigMapModuleData:CalcHandbookUnLockNum(refreshId, fruitNpcList)
  local handbookUnlockNum = 0
  local spriteList = self.TotalCampSpriteList[refreshId]
  if spriteList then
    for k, v in ipairs(spriteList) do
      if v.evoDatas and #v.evoDatas > 0 then
        for i = 1, #v.evoDatas do
          local notFound = true
          local isVisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
          local isVisitOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
          if isVisitState and false == isVisitOwner then
            local accessHandbookPetDic = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetAccessHandbookData)
            if accessHandbookPetDic then
              local record = accessHandbookPetDic[v.evoDatas[i].petBaseConfId]
              local CaughtCamp = nil ~= record and record.caught_camp or nil
              if CaughtCamp and #CaughtCamp > 0 then
                for j = 1, #CaughtCamp do
                  if CaughtCamp[j] == refreshId then
                    notFound = false
                    local hasSame = false
                    for _, value in ipairs(fruitNpcList) do
                      if value == self:GetFirstStageBaseId(v.evoDatas[i].petBaseConfId) then
                        hasSame = true
                        break
                      end
                    end
                    if not hasSame then
                      handbookUnlockNum = handbookUnlockNum + 1
                    end
                    break
                  end
                end
              end
            end
            if not notFound then
              break
            end
          else
            local HandBookData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, v.evoDatas[i].handbookId)
            if HandBookData and HandBookData.Collection and HandBookData.Collection.record then
              local record = HandBookData.Collection.record
              for k = 1, #record do
                local CaughtCamp = record[k].caught_camp
                if CaughtCamp and #CaughtCamp > 0 then
                  for j = 1, #CaughtCamp do
                    if CaughtCamp[j] == refreshId and record[k].pet_base_id == v.evoDatas[i].petBaseConfId then
                      notFound = false
                      local hasSame = false
                      for _, value in ipairs(fruitNpcList) do
                        if value == self:GetFirstStageBaseId(v.evoDatas[i].petBaseConfId) then
                          hasSame = true
                          break
                        end
                      end
                      if not hasSame then
                        handbookUnlockNum = handbookUnlockNum + 1
                      end
                      break
                    end
                  end
                end
                if not notFound then
                  break
                end
              end
            end
            if not notFound then
              break
            end
          end
        end
      end
    end
  end
  return handbookUnlockNum
end

function BigMapModuleData:GetTeleportCDTimeSec()
  local cdConfig = _G.DataConfigManager:GetOnlineGlobalConfig(38)
  return cdConfig and cdConfig.num or 0
end

function BigMapModuleData:GetTeleportLastTimeStampSec()
  return self.teleportLastTimeStampSec or 0
end

function BigMapModuleData:SetTeleportLastTimeStampSec(timeStampSec)
  self.teleportLastTimeStampSec = timeStampSec
end

function BigMapModuleData:GetFirstStageBaseId(baseId)
  local conf = _G.DataConfigManager:GetPetbaseConf(baseId)
  if conf.stage > 1 then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(conf.degenerate_pet_id)
    if nil == petBaseConf then
      return nil
    end
    return self:GetFirstStageBaseId(petBaseConf.id)
  else
    return baseId
  end
end

function BigMapModuleData:GetGatherRate(refreshId)
  local unlockNum = 0
  local totalNum = 0
  local campSpriteList = {}
  local fruitNpcList = {}
  if self.CampFruitNpcsInfoList and #self.CampFruitNpcsInfoList > 0 then
    local markFruitDic = {}
    for k, v in ipairs(self.CampFruitNpcsInfoList) do
      if v.camp_content_id == refreshId and v.owl_sanctuary_fruit_npc_info and #v.owl_sanctuary_fruit_npc_info > 0 then
        for _, value in ipairs(v.owl_sanctuary_fruit_npc_info) do
          if value.npc_id then
            local npcList = value.npc_id
            for i, npcId in pairs(npcList) do
              local npcInfoDatas = _G.DataConfigManager:GetNpcConf(npcId)
              if npcInfoDatas and npcInfoDatas.traverse_data_type == _G.Enum.Traverse_Data_Type.TDT_PETBASE then
                local baseId = npcInfoDatas.traverse_data_param[1]
                local petBaseId = self:GetFirstStageBaseId(baseId)
                if nil ~= petBaseId and nil == markFruitDic[petBaseId] then
                  if not self:HasPetBaseId(petBaseId, campSpriteList) then
                    table.insert(campSpriteList, self:GetPetItemData(petBaseId))
                  end
                  markFruitDic[petBaseId] = true
                  unlockNum = unlockNum + 1
                  table.insert(fruitNpcList, petBaseId)
                end
              end
            end
          end
        end
      end
    end
  end
  if self.TotalCampSpriteList[refreshId] and #self.TotalCampSpriteList[refreshId] > 0 then
    for k, v in ipairs(self.TotalCampSpriteList[refreshId]) do
      local hasSame = false
      table.insert(campSpriteList, v)
      for j, value in ipairs(fruitNpcList) do
        if self:GetFirstStageBaseId(v.petBaseConfId) == value then
          hasSame = true
          break
        end
      end
      if false == hasSame then
        totalNum = totalNum + 1
      end
    end
  end
  local handbookUnlockNum = self:CalcHandbookUnLockNum(refreshId, fruitNpcList)
  totalNum = totalNum + unlockNum
  unlockNum = unlockNum + handbookUnlockNum
  return unlockNum, totalNum
end

function BigMapModuleData:GetMapShowSceneResId()
  local showSceneResId = SceneUtils.GetSceneResId()
  local bInDungeon = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.IsInDungeon)
  if bInDungeon then
    local DungeonInfo = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.GetDungeonInfo)
    if DungeonInfo then
      local dungeonConf = _G.DataConfigManager:GetDungeonConf(DungeonInfo.dungeon_id)
      if dungeonConf then
        local worldSceneId = dungeonConf.world_scene_id
        local SceneConf = _G.DataConfigManager:GetSceneConf(worldSceneId)
        if SceneConf then
          local sceneResId1 = SceneConf.scene_res_id
          showSceneResId = sceneResId1
        end
      end
    end
  end
  return showSceneResId
end

function BigMapModuleData:GetNpcDataByWorldMapConfId(WorldMapConfId)
  local npcList = self.npcDatas
  for npc, NpcDataS in pairs(npcList) do
    for mapPieceId, npcInfos in pairs(NpcDataS) do
      for npcId, _npcInfos in pairs(npcInfos) do
        for logicId, npcInfo in pairs(_npcInfos) do
          Log.Debug(npcInfo.world_map_cfg_id, WorldMapConfId, "BigMapModuleData:GetNpcDataByWorldMapConfId")
          if npcInfo.world_map_cfg_id == WorldMapConfId then
            return npcInfo
          end
        end
      end
    end
  end
  return nil
end

function BigMapModuleData:GetSanctuaryListDatas()
  local allOwlSanctuaryNpcInfos = {}
  local AllTempInfos = _G.DataModelMgr.PlayerDataModel:GetAllPlayerOwlSanctuaryNpcInfo()
  if nil ~= AllTempInfos and nil ~= next(AllTempInfos) then
    for i, TempInfos in pairs(AllTempInfos) do
      for _, AllOwlInfo in pairs(TempInfos.owl_sanctuarys) do
        local AOwlSanctuary = ProtoMessage:newActorInfo_AOwlSanctuary()
        AOwlSanctuary.uin = TempInfos.uin
        AOwlSanctuary.owl_sanctuarys = {}
        local OwlSanctuaryInfo = ProtoMessage:newAvatarOwlSanctuaryInfo()
        OwlSanctuaryInfo.npc_content_id = AllOwlInfo.npc_content_id
        OwlSanctuaryInfo.is_upgrade = AllOwlInfo.is_upgrade
        OwlSanctuaryInfo.is_detected = AllOwlInfo.is_detected
        OwlSanctuaryInfo.npc_pos = AllOwlInfo.npc_pos
        OwlSanctuaryInfo.fruit_brief_infos = {}
        if nil ~= next(AllOwlInfo.fruit_brief_infos) then
          for key, value in ipairs(AllOwlInfo.fruit_brief_infos) do
            OwlSanctuaryInfo.fruit_brief_infos[key] = value
          end
        end
        table.insert(AOwlSanctuary.owl_sanctuarys, OwlSanctuaryInfo)
        table.insert(allOwlSanctuaryNpcInfos, AOwlSanctuary)
      end
    end
  else
    return nil
  end
  local worldMapConfigs = self:GetWorldMapDatas()
  local npcDatas = self:GetNpcDatas()
  local campStateDic = {}
  if npcDatas then
    for i, npcInfos in pairs(npcDatas) do
      for npcId, npcInfo in pairs(npcInfos) do
        local worldMapCfg = worldMapConfigs[npcInfo.world_map_cfg_id] or worldMapConfigs[npcInfo.npc_refresh_id]
        if npcInfo.npcCfg and npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_CAMP then
          campStateDic[npcInfo.npc_refresh_id] = npcInfo.status
        end
      end
    end
  end
  local owlSanctuaryDic = {}
  for i, allOwlSanctuaryNpcInfo in pairs(allOwlSanctuaryNpcInfos) do
    for k, v in pairs(allOwlSanctuaryNpcInfo.owl_sanctuarys) do
      if v.npc_content_id then
        local conf = _G.DataConfigManager:GetOwlSanctuaryConf(v.npc_content_id)
        if conf.first_area_name and conf.second_area_name and 0 ~= conf.owl_sanctuary_order and v.fruit_brief_infos then
          if nil == owlSanctuaryDic[conf.owl_sanctuary_order] then
            owlSanctuaryDic[conf.owl_sanctuary_order] = {}
          end
          if nil == owlSanctuaryDic[conf.owl_sanctuary_order][v.npc_content_id] then
            owlSanctuaryDic[conf.owl_sanctuary_order][v.npc_content_id] = {}
          end
          local info = {}
          info.conf = conf
          info.fruits = v.fruit_brief_infos
          info.unlock = v.is_detected and 1 or 0
          info.pos = v.npc_pos
          info.is_upgrade = v.is_upgrade
          info.uin = allOwlSanctuaryNpcInfo.uin
          info.contentId = v.npc_content_id
          owlSanctuaryDic[conf.owl_sanctuary_order][v.npc_content_id][allOwlSanctuaryNpcInfo.uin] = info
        end
      end
    end
  end
  return owlSanctuaryDic
end

function BigMapModuleData:GetFruitFristPetBaseId(fruit_id)
  if nil == fruit_id or 0 == fruit_id then
    return 0
  end
  local petFruitConf = _G.DataConfigManager:GetOwlPetFruitConf(fruit_id)
  if nil == petFruitConf or nil == petFruitConf.pet_refresh then
    return 0
  end
  for i, v in pairs(petFruitConf.pet_refresh) do
    if v.pet_form_factor_tag and v.pet_form_factor_tag == _G.Enum.PetFormFacto.PFF_NORMAL then
      for j = 1, #v.npc_id do
        local npc_id = v.npc_id[j]
        local BaseId = _G.DataConfigManager:GetNpcConf(npc_id).traverse_data_param[1]
        local baseConf = _G.DataConfigManager:GetPetbaseConf(BaseId)
        if nil ~= baseConf then
          local evoId = baseConf.pet_evolution_id[1]
          local evoConf = _G.DataConfigManager:GetPetEvolutionConf(evoId, true)
          if nil ~= evoConf and nil ~= evoConf.evolution_chain then
            for k = 1, #evoConf.evolution_chain do
              if 1 == evoConf.evolution_chain[k].stage then
                return evoConf.evolution_chain[k].petbase_id
              end
            end
          end
        end
      end
    end
  end
  return 0
end

function BigMapModuleData:LoadSantuaryListOpenState()
  local playerId = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local redJson = JsonUtils.LoadSaved(string.format("Sanctuary/SanctuaryList_State_%s", playerId), {})
  if nil == redJson or nil == redJson.state then
    return nil
  else
    return self:ParseSantuaryState(redJson.state)
  end
  return nil
end

function BigMapModuleData:SaveSantuaryListOpenState(datas)
  local playerId = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local saveStr = self:SplicingSantuaryState(datas)
  JsonUtils.DumpSaved(string.format("Sanctuary/SanctuaryList_State_%s", playerId), {state = saveStr})
end

function BigMapModuleData:LoadSantuaryListOpenOffset()
  local playerId = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local redJson = JsonUtils.LoadSaved(string.format("Sanctuary/SanctuaryList_Offset_%s", playerId), {})
  if nil == redJson or nil == redJson.offset then
    return 0
  else
    return redJson.offset
  end
  return 0
end

function BigMapModuleData:SaveSantuaryListOpenOffset(listOffset)
  local playerId = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  JsonUtils.DumpSaved(string.format("Sanctuary/SanctuaryList_Offset_%s", playerId), {offset = listOffset})
end

function BigMapModuleData:SplicingSantuaryState(datas)
  local str = ""
  for _, item in ipairs(datas) do
    str = str .. string.format("name=%s,state=%s;", item.name, item.state)
  end
  return str
end

function BigMapModuleData:ParseSantuaryState(str)
  local result = {}
  for group in str:gmatch("([^;]+)") do
    local name, state = group:match("name=(.-),state=(.+)")
    if name and state then
      table.insert(result, {
        name = name,
        state = tonumber(state) or state
      })
    end
  end
  return result
end

function BigMapModuleData:GetSantuaryState(name)
  local datas = self:LoadSantuaryListOpenState()
  if nil == datas then
    return true
  end
  for _, item in ipairs(datas) do
    if item.name == name then
      return 0 == item.state
    end
  end
  return true
end

function BigMapModuleData:SetSantuaryState(name, state)
  local datas = self:LoadSantuaryListOpenState()
  if nil == datas or 0 == #datas then
    datas = {}
    table.insert(datas, {name = name, state = state})
  end
  local isSave = false
  for _, item in ipairs(datas) do
    if item.name == name then
      item.state = state
      isSave = true
      break
    end
  end
  if false == isSave then
    table.insert(datas, {name = name, state = state})
  end
  self:SaveSantuaryListOpenState(datas)
end

function BigMapModuleData:RegisterSanctuaryChildItem(id, umg_item)
  self.sanctuaryChildItemDic[id] = umg_item
end

function BigMapModuleData:UnRegisterSanctuaryChildItem(id)
  if self.sanctuaryChildItemDic == nil then
    return
  end
  self.sanctuaryChildItemDic[id] = nil
end

function BigMapModuleData:GetAllOwlSanctuaryConfs()
  return self.owlSanctuaryDatas
end

function BigMapModuleData:CancelTraceOnNpcRemoved(entryId, logicId)
  if self.module:CheckIsTracing(bigMapModuleEnum.TraceType.NPC, entryId, logicId) then
    local traceInfo = {}
    traceInfo.traceType = bigMapModuleEnum.TraceType.NPC
    self.module:OnCmdStartOrCancelTrace(false, traceInfo)
  end
  if self.module:CheckIsTracing(bigMapModuleEnum.TraceType.TempTrace, logicId) then
    local traceInfo = {}
    traceInfo.traceType = bigMapModuleEnum.TraceType.TempTrace
    traceInfo.npcInfo = {}
    traceInfo.npcInfo.logic_id = logicId
    self.module:OnCmdStartOrCancelTrace(false, traceInfo)
  end
  if self.module:CheckIsTracing(bigMapModuleEnum.TraceType.ForceTrace, nil, logicId) then
    local traceInfo = {}
    traceInfo.traceType = bigMapModuleEnum.TraceType.ForceTrace
    traceInfo.npcInfo = {}
    traceInfo.npcInfo.logic_id = logicId
    self.module:OnCmdStartOrCancelTrace(false, traceInfo)
  end
end

function BigMapModuleData:UpdateMiniMapShowNpc(sceneResId, mapPieceId, bShow, npcInfo, entryId, logicId)
  sceneResId = sceneResId or SceneUtils.GetSceneResId()
  local mapPiece = mapPieceId or 0
  if npcInfo then
    logicId = logicId or npcInfo.logic_id or entryId or logicId or npcInfo.entry_id
  else
    logicId = entryId
  end
  if bShow then
    local _entryId = npcInfo.entry_id
    if self:CheckMiniMapShouldShowNpc(npcInfo) then
      if self.miniMapShowNpc[sceneResId] == nil then
        self.miniMapShowNpc[sceneResId] = {}
      end
      if self.miniMapShowNpc[sceneResId][mapPiece] == nil then
        self.miniMapShowNpc[sceneResId][mapPiece] = {}
      end
      if self.miniMapShowNpc[sceneResId][mapPiece][_entryId] == nil then
        self.miniMapShowNpc[sceneResId][mapPiece][_entryId] = {}
      end
      self.miniMapShowNpc[sceneResId][mapPiece][_entryId][logicId] = npcInfo
      _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.OnMapInfoChange, false, npcInfo, entryId, logicId)
    else
      local _logicId = npcInfo.logic_id or _entryId
      if self.miniMapShowNpc[sceneResId] and self.miniMapShowNpc[sceneResId][mapPiece] and 0 ~= _entryId then
        if self.miniMapShowNpc[sceneResId][mapPiece][_entryId] and self.miniMapShowNpc[sceneResId][mapPiece][_entryId][_logicId] then
          table.removeKey(self.miniMapShowNpc[sceneResId][mapPiece][_entryId], _logicId)
        end
        _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.OnMapInfoChange, true, npcInfo, _entryId, logicId)
        self:CancelTraceOnNpcRemoved(_entryId, logicId)
      end
    end
  elseif self.miniMapShowNpc[sceneResId] and self.miniMapShowNpc[sceneResId][mapPiece] and 0 ~= entryId then
    local logicIdMap = self.miniMapShowNpc[sceneResId][mapPiece][entryId]
    if logicIdMap then
      local tempNpcInfo = logicIdMap[logicId]
      if tempNpcInfo then
        _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.OnMapInfoChange, true, tempNpcInfo, entryId, logicId)
        self:CancelTraceOnNpcRemoved(entryId, logicId)
      end
      table.removeKey(self.miniMapShowNpc[sceneResId][mapPiece][entryId], logicId)
    end
  end
end

function BigMapModuleData:SetAllMiniMapShowNpcs()
  for sceneResId, npcInfos in pairs(self.npcDatas) do
    self:SetMiniMapShowNpcs(sceneResId)
  end
end

function BigMapModuleData:SetAllMiniMapShowAreaNpcs()
  self:SetMiniMapShowAreaNpcs()
end

function BigMapModuleData:SetMiniMapShowNpcs(sceneResId)
  local WorldMapConfigs = self:GetWorldMapDatas()
  local _npcInfos = self:GetNpcDatas(sceneResId)
  local npcInfo = {}
  WorldMapConfigs = WorldMapConfigs or {}
  if not _npcInfos then
    return nil
  end
  for mapPieceId, j in pairs(_npcInfos) do
    for entryId, entryList in pairs(j) do
      if nil == npcInfo[mapPieceId] then
        npcInfo[mapPieceId] = {}
      end
      for logicId, _npcInfo in pairs(entryList) do
        local shouldShow = self:CheckMiniMapShouldShowNpc(_npcInfo)
        if shouldShow then
          if nil == npcInfo[mapPieceId][entryId] then
            npcInfo[mapPieceId][entryId] = {}
          end
          npcInfo[mapPieceId][entryId][logicId] = _npcInfo
        end
      end
    end
  end
  self.miniMapShowNpc[sceneResId] = npcInfo
end

function BigMapModuleData:SetMiniMapShowAreaNpcs()
  local mapArea = {}
  local mapAreaInfos = self:GetMapAreaDatas()
  for i, v in pairs(mapAreaInfos) do
    if v.npcList and #v.npcList > 0 then
      local worldMap = self.bigMapDatas[v.world_map_cfg_id]
      local shouldShow = false
      if worldMap then
        if v.unlocked then
          shouldShow = 1 == worldMap.explored_in_minimap and worldMap.areaicon_explore
        else
          shouldShow = 1 == worldMap.unexplored_in_minimap and worldMap.areaicon_unexplore
        end
        if shouldShow then
          mapArea[i] = v
        end
      end
    end
  end
  self.miniMapShowAreaNpc = mapArea
end

function BigMapModuleData:GetAllShowNpcsMinimap(sceneResId)
  return self.miniMapShowNpc[sceneResId]
end

function BigMapModuleData:GetAllShowAreaNpcsMinimap()
  return self.miniMapShowAreaNpc
end

function BigMapModuleData:CheckMiniMapShouldShowNpc(npcInfo)
  local WorldMapConfigs = self:GetWorldMapDatas()
  local worldMap = WorldMapConfigs[npcInfo.world_map_cfg_id] or WorldMapConfigs[npcInfo.npc_refresh_id]
  local shouldShow = false
  local model
  if npcInfo.npcCfg and npcInfo.npcCfg.model_conf > 0 then
    model = _G.DataConfigManager:GetModelConf(npcInfo.npcCfg.model_conf, true)
  end
  if worldMap then
    local bTracing = self.module:CheckIsTracing(bigMapModuleEnum.TraceType.NPC, npcInfo.entry_id, npcInfo.logic_id)
    if worldMap.is_hide_init then
      if bTracing then
        shouldShow = true
      else
        shouldShow = false
      end
    elseif worldMap.map_show_type == _G.ProtoEnum.MapIconShowType.MAP_AREA_NPC then
      if npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        shouldShow = 1 == worldMap.explored_in_minimap
      else
        shouldShow = 1 == worldMap.unexplored_in_minimap
      end
    elseif npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
      if worldMap.dungeon_id and worldMap.dungeon_id > 0 then
        if npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
          shouldShow = 1 == worldMap.unfinished_in_minimap and model.ui_icon
        elseif npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
          shouldShow = 1 == worldMap.explored_in_minimap and model.ui_icon
        end
      elseif worldMap.storyflag_id and worldMap.storyflag_id > 0 then
        if _G.DataModelMgr.PlayerDataModel:HasStoryFlag(worldMap.storyflag_id) then
          shouldShow = 1 == worldMap.explored_in_minimap and model.ui_icon
        end
      else
        shouldShow = 1 == worldMap.explored_in_minimap and model.ui_icon
      end
    else
      shouldShow = 1 == worldMap.unexplored_in_minimap and (worldMap.npcicon_lock or model and model.ui_icon)
    end
  end
  return shouldShow
end

function BigMapModuleData:GetRandomShopNpcRefreshId()
  local worldMapInfo = _G.DataModelMgr.PlayerDataModel:GetWorldMapActorInfo()
  if not worldMapInfo then
    return nil
  end
  local npcRefreshIdList = {}
  if worldMapInfo.entries and worldMapInfo.entries.entry_infos then
    for _, entryInfo in ipairs(worldMapInfo.entries.entry_infos) do
      if entryInfo.npc_entry_info then
        local mapid = entryInfo.npc_entry_info.world_map_cfg_id
        if nil ~= mapid then
          local worldMapConf = _G.DataConfigManager:GetWorldMapConf(mapid)
          if worldMapConf then
            if worldMapConf.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP then
              if worldMapConf.npc_refresh_ids and #worldMapConf.npc_refresh_ids > 0 then
                for _, npcRefreshId in ipairs(worldMapConf.npc_refresh_ids) do
                  table.insert(npcRefreshIdList, npcRefreshId)
                  Log.Debug("BigMapModuleData:GetRandomShopNpcRefreshId npcRefreshId", npcRefreshId)
                end
              else
                Log.Warning("BigMapModuleData:GetRandomShopNpcRefreshId worldMapConf.npc_refresh_ids is nil", mapid)
              end
            else
              Log.Debug("BigMapModuleData:GetRandomShopNpcRefreshId worldMapConf.map_tips_show_type is  ", worldMapConf.map_tips_show_type, "mapcfgid", mapid)
            end
          else
            Log.Warning("BigMapModuleData:GetRandomShopNpcRefreshId worldMapConf is nil", mapid)
          end
        end
      end
    end
  end
  if #npcRefreshIdList > 0 then
    return npcRefreshIdList[1]
  end
  return nil
end

function BigMapModuleData:GetShopIDByNpcCfg(npcCfg)
  local optionID
  if npcCfg and npcCfg.option_id and #npcCfg.option_id > 0 then
    optionID = npcCfg.option_id[1]
  else
    Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo] npcCfg.option_id is nil or empty! npcCfg:", npcCfg)
    return nil
  end
  local shopID
  local optionConf = _G.DataConfigManager:GetNpcOptionConf(optionID)
  if not optionConf then
    Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo] optionConf is nil! optionID:", optionID)
  elseif optionConf.action and optionConf.action.action_type == _G.Enum.ActionType.ACT_DIALOG then
    local actionParam = optionConf.action.action_param1
    local actionNum = tonumber(actionParam)
    if not actionNum then
      Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo] actionNum is nil! actionParam:", actionParam)
    else
      local dialogConf = _G.DataConfigManager:GetDialogueConf(actionNum)
      if not dialogConf then
        Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo] dialogConf is nil! actionNum:", actionNum)
      else
        local selectID = dialogConf.select_ids
        if not selectID or 0 == #selectID then
          Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo] selectID is nil or empty! dialogConf:", actionNum)
        else
          for i = 1, #selectID do
            local selectDialogConf = _G.DataConfigManager:GetSelectConf(selectID[i])
            if not selectDialogConf then
              Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo] selectDialogConf is nil! selectID:", selectID[i])
            else
              local nextDialogueID = selectDialogConf.select_next_dialogue
              if nextDialogueID then
                local nextDialogueConf = _G.DataConfigManager:GetDialogueConf(nextDialogueID)
                if nextDialogueConf.action ~= nil and nextDialogueConf.action.action_type == _G.Enum.ActionType.ACT_OPENSHOP then
                  shopID = tonumber(nextDialogueConf.action.action_param1)
                end
              end
            end
          end
        end
      end
    end
  end
  return shopID
end

function BigMapModuleData:CanShowRandomShopHint(npcRefreshId)
  local npcRefreshContentConf = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshId)
  if not npcRefreshContentConf then
    Log.Warning("[BigMapModuleData:CanShowRandomShopHint] npcRefreshContentConf is nil, npcRefreshId:", npcRefreshId)
    return false
  end
  local refreshRule = npcRefreshContentConf.refresh_rule
  if not refreshRule then
    Log.Warning("[BigMapModuleData:CanShowRandomShopHint] refreshRule is nil, npcRefreshId:", npcRefreshId, "npcRefreshContentConf:", npcRefreshContentConf)
    return false
  end
  local refreshRuleConf = _G.DataConfigManager:GetNpcRefreshRuleConf(refreshRule)
  if not refreshRuleConf then
    Log.Warning("[BigMapModuleData:CanShowRandomShopHint] refreshRuleConf is nil, refreshRule:", refreshRule, "npcRefreshId:", npcRefreshId)
    return false
  end
  local availableTimeEnum = refreshRuleConf.available_time_enum
  if not availableTimeEnum then
    Log.Warning("[BigMapModuleData:CanShowRandomShopHint] available_time_enum is nil, refreshRuleConf:", refreshRuleConf, "npcRefreshId:", npcRefreshId)
    return false
  end
  local timeConf = _G.DataConfigManager:GetNpcRefreshTimeConf(availableTimeEnum)
  if not timeConf then
    Log.Warning("[BigMapModuleData:CanShowRandomShopHint] timeConf is nil, availableTimeEnum:", availableTimeEnum, "npcRefreshId:", npcRefreshId)
    return false
  end
  local availableTime = timeConf.available_time
  if not availableTime or 0 == #availableTime then
    Log.Warning("[BigMapModuleData:CanShowRandomShopHint] availableTime is nil or empty, timeConf:", timeConf, "npcRefreshId:", npcRefreshId)
    return false
  end
  local currentGameTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  local isInTimeRange = false
  for i, timeRange in ipairs(availableTime) do
    if timeRange.available_time_type == _G.Enum.AvailableTimeType.ATT_DAY_TIME then
      local startTimeStr = timeRange.available_time_param1
      local endTimeStr = timeRange.available_time_param2
      if startTimeStr and endTimeStr then
        local startTime = UIUtils.GetSecondsFromTimeString(startTimeStr)
        local endTime = UIUtils.GetSecondsFromTimeString(endTimeStr)
        if startTime and endTime then
          local serverTimezoneOffset = UIUtils.GetTimezoneOffset() or 0
          local utcTimeTable = os.date("!*t", currentGameTime)
          local utcSeconds = utcTimeTable.hour * 3600 + utcTimeTable.min * 60 + utcTimeTable.sec
          local severUtcSeconds = utcSeconds - serverTimezoneOffset
          local currentDaySeconds = severUtcSeconds
          if currentDaySeconds < 0 then
            currentDaySeconds = currentDaySeconds + 86400
          end
          local tempStr = UIUtils.FormatTimeStringToDay(currentDaySeconds)
          Log.Debug("[BigMapModuleData:CanShowRandomShopHint] tempStr:", tempStr, "serverTimezoneOffset:", serverTimezoneOffset, "utcDaySeconds:", utcDaySeconds, "currentDaySeconds:", currentDaySeconds)
          local isInThisTimeRange = false
          if startTime <= endTime then
            isInThisTimeRange = startTime <= currentDaySeconds and endTime >= currentDaySeconds
          else
            isInThisTimeRange = startTime <= currentDaySeconds or endTime >= currentDaySeconds
          end
          if isInThisTimeRange then
            isInTimeRange = true
            Log.Debug("[BigMapModuleData:CanShowRandomShopHint] in time range, currentDaySeconds:", currentDaySeconds, "startTime:", startTime, "endTime:", endTime, "startTimeStr:", startTimeStr, "endTimeStr:", endTimeStr, "serverTimezoneOffset:", serverTimezoneOffset, "npcRefreshId:", npcRefreshId)
            break
          else
            Log.Debug("[BigMapModuleData:CanShowRandomShopHint] not in time range, currentDaySeconds:", currentDaySeconds, "startTime:", startTime, "endTime:", endTime, "startTimeStr:", startTimeStr, "endTimeStr:", endTimeStr, "serverTimezoneOffset:", serverTimezoneOffset, "npcRefreshId:", npcRefreshId)
          end
        else
          Log.Warning("[BigMapModuleData:CanShowRandomShopHint] failed to parse time strings, startTimeStr:", startTimeStr, "endTimeStr:", endTimeStr, "npcRefreshId:", npcRefreshId)
        end
      else
        Log.Warning("[BigMapModuleData:CanShowRandomShopHint] time strings are nil, startTimeStr:", startTimeStr, "endTimeStr:", endTimeStr, "npcRefreshId:", npcRefreshId)
      end
    end
  end
  if not isInTimeRange then
    Log.Debug("[BigMapModuleData:CanShowRandomShopHint] not in any time range, npcRefreshId:", npcRefreshId, "currentGameTime:", currentGameTime, "availableTime:", availableTime)
    return false
  end
  Log.Debug("[BigMapModuleData:CanShowRandomShopHint] success, npcRefreshId:", npcRefreshId, "currentGameTime:", currentGameTime)
  return true
end

function BigMapModuleData:SetNpcTipShowType(showType)
  self.npcTipsShowType = showType
end

function BigMapModuleData:GetNpcTipShowType()
  return self.npcTipsShowType
end

function BigMapModuleData:SetShopData(rsp)
  self.ShopRspData = rsp
end

function BigMapModuleData:GetShopData()
  return self.ShopRspData
end

function BigMapModuleData:SetCurShowLayerId(layerId)
  self.curShowLayerId = layerId
end

function BigMapModuleData:AddEntryIdMap(entryId, sceneResId, mapPieceId)
  if self.entryIdToSceneResIdAndPieceId[entryId] == nil then
    self.entryIdToSceneResIdAndPieceId[entryId] = {}
  end
  local entryIdMap = self.entryIdToSceneResIdAndPieceId[entryId]
  if #entryIdMap > 0 then
    for k, v in ipairs(entryIdMap) do
      if v.sceneResId == sceneResId and mapPieceId == v.mapPieceId then
        return
      end
    end
  end
  table.insert(self.entryIdToSceneResIdAndPieceId[entryId], {sceneResId = sceneResId, mapPieceId = mapPieceId})
end

function BigMapModuleData:RemoveEntryIdMap(entryId)
  self.entryIdToSceneResIdAndPieceId[entryId] = nil
end

function BigMapModuleData:GetEntryIdMap(entryId)
  return self.entryIdToSceneResIdAndPieceId[entryId]
end

function BigMapModuleData:ClearEntryIdMap()
  table.clear(self.entryIdToSceneResIdAndPieceId)
end

return BigMapModuleData

local BigMapModule = NRCModuleBase:Extend("BigMapModule")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local TaskModuleEvent = reload("NewRoco.Modules.Core.Task.TaskModuleEvent")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")

function BigMapModule:OnConstruct()
  _G.BigMapModuleCmd = reload("NewRoco.Modules.System.BigMap.BigMapModuleCmd")
  self.data = self:SetData("BigMapModuleData", "NewRoco.Modules.System.BigMap.BigMapModuleData")
  self.data:InitData()
  NRCEventCenter:RegisterEvent("BigMapModule", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.AfterEnterScene)
  NRCEventCenter:RegisterEvent("BigMapModule", self, TaskModuleEvent.ON_ACCEPT_TASK_REFRESH, self.OnCmdUpdateGuideTask)
end

function BigMapModule:OnDestruct()
  table.clear(self.data.layerIdToIcons)
  self.data:ClearMaskTexture()
end

function BigMapModule:OnActive()
  self:RegisterCmd(BigMapModuleCmd.OpenWorldMap, self.OnCmdOpenWorldMap)
  self:RegisterCmd(BigMapModuleCmd.OpenWorldMapDebug, self.OnCmdOpenWorldMapDebug)
  self:RegisterCmd(BigMapModuleCmd.EnableWorldMap, self.EnableWorldMap)
  self:RegisterCmd(BigMapModuleCmd.PreLoadWorldMap, self.PreLoadWorldMap)
  self:RegisterCmd(BigMapModuleCmd.CloseWorldMap, self.OnCmdCloseWorldMap)
  self:RegisterCmd(BigMapModuleCmd.SendWorldMapTeleportReq, self.OnCmdSendWorldMapTeleportReq)
  self:RegisterCmd(BigMapModuleCmd.SendWorldMapNpcTeleportReq, self.OnCmdSendSceneWorldMapTeleportToNpcReq)
  self:RegisterCmd(BigMapModuleCmd.OnCmdTeleportToPlayerReq, self.OnCmdTeleportToPlayerReq)
  self:RegisterCmd(BigMapModuleCmd.TraceNpcByRefreshID, self.OnCmdTraceNpcByRefreshID)
  self:RegisterCmd(BigMapModuleCmd.TraceNpcByID, self.OnCmdTraceNpcByID)
  self:RegisterCmd(BigMapModuleCmd.GetTraceNpcID, self.GetTraceNpcId)
  self:RegisterCmd(BigMapModuleCmd.GetTraceNpcRefreshID, self.GetTraceNpcRefreshId)
  self:RegisterCmd(BigMapModuleCmd.SetMapCenterPos, self.OnCmdSetMapCenterPos)
  self:RegisterCmd(BigMapModuleCmd.AddMapActivityIconByWorldMapConf, self.OnCmdAddMapActivityIconByWorldMapConf)
  self:RegisterCmd(BigMapModuleCmd.RemoveMapActivityIconByWorldMapConf, self.OnCmdRemoveMapActivityIconByWorldMapConf)
  self:RegisterCmd(BigMapModuleCmd.BehaviorOpenWorldMap, self.OnCmdBehaviorOpenWorldMap)
  self:RegisterCmd(BigMapModuleCmd.SelectMarker, self.OnCmdSelectMarker)
  self:RegisterCmd(BigMapModuleCmd.MapMarkOperate, self.OnCmdMapMarkOperate)
  self:RegisterCmd(BigMapModuleCmd.BonfireFinishNotify, self.OnCmdBonfireFinishNotify)
  self:RegisterCmd(_G.FunctionBanModuleCmd.DebugCatchPetToggle, self.OnDebugCatchPetToggle)
  self:RegisterCmd(BigMapModuleCmd.SetVisitListInfo, self.UpdatePlayerVisitInfo)
  self:RegisterCmd(BigMapModuleCmd.GetAreaFuncInfo, self.OnGetAreaFuncInfo)
  self:RegisterCmd(BigMapModuleCmd.GetBroadcastArea, self.OnCmdGetBroadcastArea)
  self:RegisterCmd(BigMapModuleCmd.ZoneSceneGetCampFruitInfoReq, self.CmdZoneGetCampFruitInfoReq)
  self:RegisterCmd(BigMapModuleCmd.OpenNourishBigMapTips, self.CmdOpenNourishBigMapTips)
  self:RegisterCmd(BigMapModuleCmd.HideMainMapMask, self.HideMask)
  self:RegisterCmd(BigMapModuleCmd.OpenBigManualPanel, self.OnCmdOpenBigManualPanel)
  self:RegisterCmd(BigMapModuleCmd.OpenMapRightPanel, self.OnCmdOpenMapRightPanel)
  self:RegisterCmd(BigMapModuleCmd.CloseMapRightPanel, self.OnCmdCloseMapRightPanel)
  self:RegisterCmd(BigMapModuleCmd.GetAllMapDatas, self.OnCmdGetAllMapDatas)
  self:RegisterCmd(BigMapModuleCmd.UpdateWorldMapDatas, self.WorldMapInfoChanged)
  self:RegisterCmd(BigMapModuleCmd.OnCmdCheckShouldShowNpc, self.CheckShouldShowNpc)
  self:RegisterCmd(BigMapModuleCmd.UpdateMagicCreateNpcInfo, self.MagicCreateNpcInfoChanged)
  self:RegisterCmd(BigMapModuleCmd.OpenTravelMainMap, self.OnCmdOpenTravelMainMap)
  self:RegisterCmd(BigMapModuleCmd.CloseTravelMainMap, self.OnCmdCloseTravelMainMap)
  self:RegisterCmd(BigMapModuleCmd.GetIsTravelMap, self.OnCmdIsTravelMap)
  self:RegisterCmd(BigMapModuleCmd.OpenTravelPanel, self.OnCmdOpenTravelPanel)
  self:RegisterCmd(BigMapModuleCmd.SetSliderVisible, self.OnCmdSetSliderVisible)
  self:RegisterCmd(BigMapModuleCmd.GetNpcInfoByConfigId, self.OnCmdGetNpcInfoByConfigId)
  self:RegisterCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, self.OnCmdGetNpcInfoByRefreshId)
  self:RegisterCmd(BigMapModuleCmd.GetPetGatherRate, self.OnCmdGetPetGatherRate)
  self:RegisterCmd(BigMapModuleCmd.ChangeSelectedScene, self.OnCmdChangeSelectedScene)
  self:RegisterCmd(BigMapModuleCmd.ChangeMapScene, self.OnCmdChangeMapScene)
  self:RegisterCmd(BigMapModuleCmd.OpenMapMagicPanel, self.OnCmdOpenMapMagicPanel)
  self:RegisterCmd(BigMapModuleCmd.SetIsTravel, self.OnCmdSetIsTravel)
  self:RegisterCmd(BigMapModuleCmd.OnUpdateTravelInfos, self.OnCmdUpdateTravelInfos)
  self:RegisterCmd(BigMapModuleCmd.SyncWorldMapInfo, self.SyncWorldMapInfo)
  self:RegisterCmd(BigMapModuleCmd.MarkerTypeSelect, self.OnCmdMarkerTypeSelect)
  self:RegisterCmd(BigMapModuleCmd.MarkerSelect, self.OnCmdMarkerSelect)
  self:RegisterCmd(BigMapModuleCmd.GetSelectMarkerType, self.OnCmdGetSelectMarkerType)
  self:RegisterCmd(BigMapModuleCmd.GetNewCustomPointNumByMapCfgId, self.OnCmdGetNewCustomPointNumByMapCfgId)
  self:RegisterCmd(BigMapModuleCmd.UpdateOwlSanctuaryNpcData, self.OnCmdUpdateOwlSanctuaryNpcData)
  self:RegisterCmd(BigMapModuleCmd.SetMapCenterByNPC, self.SetMapCenterByNPC)
  self:RegisterCmd(BigMapModuleCmd.OnCmdRemoveNpcIconByNpcId, self.OnCmdRemoveNpcIconByNpcId)
  self:RegisterCmd(BigMapModuleCmd.GetNpcDataByWorldMapConfId, self.OnCmdGetNpcDataByWorldMapConfId)
  self:RegisterCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, self.CheckNpcInFogAreaByRefreshId)
  self:RegisterCmd(BigMapModuleCmd.SetHomePetNpcData, self.OnCmdUpdateHomeNpcInfo)
  self:RegisterCmd(BigMapModuleCmd.OnTraceNearAlchemyNpc, self.OnCmdTraceNearAlchemyNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceNearUnLockAlchemyNpc, self.OnCmdTraceNearUnlockAlchemyNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceNearLockCampNpc, self.OnCmdTraceNearLockCampNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceNearUnLockCampNpc, self.OnCmdTraceNearUnLockCampNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceCampNpc, self.OnCmdTraceCampNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceSpecificNpc, self.OnCmdTraceSpecificNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceBossByEggItemId, self.OnCmdTraceBossByEggItemId)
  self:RegisterCmd(BigMapModuleCmd.OnTraceForceShowNpc, self.OnCmdTraceForceShowNpc)
  self:RegisterCmd(BigMapModuleCmd.OnTraceNearOutDoorChallengeNpc, self.OnCmdTraceNearOutDoorChallengeNpc)
  self:RegisterCmd(BigMapModuleCmd.GetAllRefreshContentConfs, self.OnCmdGetAllRefreshContentConfs)
  self:RegisterCmd(BigMapModuleCmd.SendZoneNpcTraceQueryReq, self.OnCmdSendZoneNpcTraceQueryReq)
  self:RegisterCmd(BigMapModuleCmd.SendZoneSelectTrackContentsReq, self.OnCmdSendZoneSelectTrackContentsReq)
  self:RegisterCmd(BigMapModuleCmd.TracePetFamily, self.OnCmdTracePet)
  self:RegisterCmd(BigMapModuleCmd.UpdateNpcTraceInfo, self.OnCmdUpdateNpcTraceInfo)
  self:RegisterCmd(BigMapModuleCmd.NpcTraceQueryByPetBaseId, self.OnCmdNpcTraceQueryByPetBaseId)
  self:RegisterCmd(BigMapModuleCmd.SendZoneNpcTraceCollectibles, self.OnCmdSendZoneNpcTraceCollectibles)
  self:RegisterCmd(BigMapModuleCmd.GetPlayerToNpcDistance, self.OnCmdGetPlayerToNpcDistance)
  self:RegisterCmd(BigMapModuleCmd.OnToggleOwlSanctuaryNpcListPanel, self.OnCmdToggleOwlSanctuaryNpcListPanel)
  self:RegisterCmd(BigMapModuleCmd.OnCloseOwlSanctuaryNpcListPanel, self.OnCloseOwlSanctuaryNpcListPanel)
  self:RegisterCmd(BigMapModuleCmd.GetSantuaryListState, self.OnCmdGetSantuaryListState)
  self:RegisterCmd(BigMapModuleCmd.SetSantuaryListState, self.OnCmdSetSantuaryListState)
  self:RegisterCmd(BigMapModuleCmd.GetSantuaryListOffset, self.OnCmdGetSantuaryListOffset)
  self:RegisterCmd(BigMapModuleCmd.SetSantuaryListOffset, self.OnCmdSetSantuaryListOffset)
  self:RegisterCmd(BigMapModuleCmd.GetPetItemData, self.OnCmdGetPetItemData)
  self:RegisterCmd(BigMapModuleCmd.SwitchSelectIcon, self.OnCmdSwitchSelectIcon)
  self:RegisterCmd(BigMapModuleCmd.SwitchSelectItem, self.OnCmdSwitchSelectItem)
  self:RegisterCmd(BigMapModuleCmd.RegisterSanctuaryChildItem, self.OnCmdRegisterSanctuaryChildItem)
  self:RegisterCmd(BigMapModuleCmd.UnRegisterSanctuaryChildItem, self.OnCmdUnRegisterSanctuaryChildItem)
  self:RegisterCmd(BigMapModuleCmd.GetAllOwlSanctuaryConfs, self.OnCmdGetAllOwlSanctuaryConfs)
  self:RegisterCmd(BigMapModuleCmd.LeaveOwlSanctuaryRigthPanel, self.OnCmdLeaveOwlSanctuaryRigthPanel)
  self:RegisterCmd(BigMapModuleCmd.OnCmdGetFruitFristPetBaseId, self.OnCmdGetFruitFristPetBaseId)
  self:RegisterCmd(BigMapModuleCmd.OnOwlStarInfoCreate, self.OnCmdAddOwlStarInfo)
  self:RegisterCmd(BigMapModuleCmd.OnOwlStarInfoDestroy, self.OnCmdRemoveOwlStarInfo)
  self:RegisterCmd(BigMapModuleCmd.OnOwlStarInfoUpdate, self.OnCmdUpdateOwlStarInfo)
  self:RegisterCmd(BigMapModuleCmd.StartOrCancelTrace, self.OnCmdStartOrCancelTrace)
  self:RegisterCmd(BigMapModuleCmd.StartOrCancelTempTrace, self.OnCmdStartOrCancelTempTrace)
  self:RegisterCmd(BigMapModuleCmd.GetAreaFuncIdByAreaId, self.OnCmdGetAreaFuncIdByAreaId)
  self:RegisterCmd(BigMapModuleCmd.GetMapTraceItemData, self.GetMapTraceItemData)
  self:RegisterCmd(BigMapModuleCmd.GetCurUnlockMapBlockIds, self.OnCmdGetCurUnlockMapBlockIds)
  self:RegisterCmd(BigMapModuleCmd.SetCurShowLayerMap, self.OnCmdSetCurShowLayerMap)
  self:RegisterCmd(BigMapModuleCmd.GetMapCenterPos, self.OnCmdGetMapCenterPos)
  self:RegisterCmd(BigMapModuleCmd.IsShowCatchPet, self.IsShowCatchPet)
  self:RegisterCmd(BigMapModuleCmd.GetCatchPetIconPath, self.GetCatchPetIconPath)
  self:RegisterCmd(BigMapModuleCmd.OnTravelShowMouseIcon, self.OnCmdOnTravelShowMouseIcon)
  self:RegisterCmd(BigMapModuleCmd.IsMapUnlock, self.OnCmdIsMapUnlock)
  self:RegisterCmd(BigMapModuleCmd.GetCurShowSceneResId, self.OnCmdGetCurShowSceneResId)
  self:RegisterCmd(BigMapModuleCmd.GetCurTraceAcceptableTask, self.GetCurTraceAcceptableTask)
  self:RegisterCmd(BigMapModuleCmd.GetAllCurTraceAcceptableTask, self.GetAllCurTraceAcceptableTask)
  self:RegisterCmd(BigMapModuleCmd.OnZoneSceneWorldMapSyncAutoTrackNpcReq, self.OnCmdZoneSceneWorldMapSyncAutoTrackNpcReq)
  self:RegisterCmd(BigMapModuleCmd.CheckAutoTracking, self.OnCmdCheckAutoTracking)
  self:RegisterCmd(BigMapModuleCmd.GetCheckDeadWoodList, self.GetCheckDeadWoodList)
  self:RegisterCmd(BigMapModuleCmd.GetLayerInfoByAreaFuncId, self.OnCmdGetLayerInfoByAreaFuncId)
  self:RegisterCmd(BigMapModuleCmd.GetWorldMapActivityConfByAreaFuncId, self.GetWorldMapActivityConfByAreaFuncId)
  self:RegisterCmd(BigMapModuleCmd.GetCurShowLayerId, self.GetCurShowLayerId)
  self:RegisterCmd(BigMapModuleCmd.DoCommonTransfer, self.DoCommonTransfer)
  self:RegisterCmd(BigMapModuleCmd.SetTempTraceTickEnable, self.SetTempTraceTickEnable)
  self:RegisterCmd(BigMapModuleCmd.GetDefaultTrackNpcList, self.OnCmdGetDefaultTrackNpcList)
  self:RegisterCmd(BigMapModuleCmd.ClearTraceInfoByType, self.OnCmdClearTraceInfoByType)
  self.miniMapTickable = false
  self.compassTickable = false
  self.debugCatchPetToggle = false
  self:RegPanel("MainBigMap", "UMG_MainMap", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, 2, 100, nil, true)
  self:RegPanel("NourishBigMapTips", "UMG_Nourish_BigMapTips", Enum.UILayerType.UI_LAYER_POPUP, false, nil, nil)
  self:RegPanel("BigManual", "UMG_BigManual", Enum.UILayerType.UI_LAYER_POPUP, true)
  self:RegPanel("MapRightPanel", "UMG_MapRightPanel", Enum.UILayerType.UI_LAYER_POPUP, true)
  self:RegPanel("SanctuaryTips", "UMG_Sanctuary_Tips", Enum.UILayerType.UI_LAYER_POPUP, true)
  self:RegTravelPanel("TravelPanel", "UMG_Travel", Enum.UILayerType.UI_LAYER_POPUP, true)
  self:RegPanel("CollectTips", "UMG_Map_CollectTips", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, nil, true)
  self:RegPanel("MapLayerTip", "UMG_MapLayerTip", Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCEventCenter:RegisterEvent("BigMapModule", self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
  _G.NRCEventCenter:RegisterEvent("BigMapModule", self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
  _G.NRCEventCenter:RegisterEvent("BigMapModule", self, ActivityModuleEvent.OnSpecificTimeActivityDropUpperLimit, self.OnActivityDropUpperLimit)
  _G.NRCEventCenter:RegisterEvent("BigMapModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  self.curTickTime = 0.0
  self.maxTickTime = _G.DataConfigManager:GetWorldGlobalConfigByKey("world_map_info_sync_tick_interval").num or 15
  self.frameCount = 0
  self.SkipFrame = 1
  self.dungeonNPCInfo = nil
  self.teamBattleNPCInfo = nil
  self.legendaryBattleNPCInfo = nil
  self.HomeNPCInfo = nil
  self.PlantNPCInfo = nil
  self.bReceiveBeginRsp = false
  self.TraceOnFogArea = false
  self.lastSceneResId = 0
  NRCEventCenter:RegisterEvent("BigMapModule", self, SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
  NRCEventCenter:RegisterEvent("BigMapModule", self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.AppEnteredForeground)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:RegisterEvent("BigMapModule", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  _G.NRCEventCenter:RegisterEvent("BigMapModule", self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  self.needRefresh = true
  self.data:CalcCampFruitTotalSpriteNum()
  NRCEventCenter:RegisterEvent("BigMapModule", self, HandbookModuleEvent.OnHandbookPetStateChange, self.OnHandbookPetStateChange)
  self.forceTraceLimit = {}
  self:SetForceTraceLimit()
end

function BigMapModule:OnDeactive()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportStart, self.OnPlayerTeleportStart)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.AfterEnterScene)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.ON_ACCEPT_TASK_REFRESH, self.OnCmdUpdateGuideTask)
  NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.AppEnteredForeground)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.OnReLoginUdate)
  if _G.DataModelMgr.PlayerDataModel:HasListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_PET_HP, self.OnPlayerPetHPChange) then
    _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.OnLoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  NRCEventCenter:UnRegisterEvent(self, HandbookModuleEvent.OnHandbookPetStateChange, self.OnHandbookPetStateChange)
end

function BigMapModule:OnEnterSceneFinishNtyAckEnd()
  if self.needRefresh == true then
    self:AfterEnterScene()
  end
end

function BigMapModule:OnEnterOrLeaveVisit()
end

function BigMapModule:OnTeleportNotify(notify)
end

function BigMapModule:OnLoadMapStart()
  self:OnCmdCloseWorldMap()
  self:ClosePanel("MapRightPanel")
end

function BigMapModule:OnActivityDropUpperLimit(activityId, methodId)
  local activityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstById, activityId, true)
  local methodDropConf = DataConfigManager:GetActivityDropConf(activityObject and activityObject:GetSinglePartId() or 0, true) or {}
  if methodId and methodId > 0 then
    local dropMethodConf = DataConfigManager:GetActivityDropMethodConf(methodId)
    if dropMethodConf and ActivityUtils.IsActivityMonitorEventOnline(dropMethodConf.drop_behavior) then
      local worldMapActivityConf = DataConfigManager:GetWorldMapActivityConf(dropMethodConf.world_map_activity_conf_id)
      if worldMapActivityConf then
        self.data:UpdateDropMethodInfo(false, methodId)
        local bShowMethodTips = not methodDropConf.no_method_tips or 1 ~= methodDropConf.no_method_tips
        if bShowMethodTips then
          local activityLimitData = {
            activityId = activityId,
            methodId = methodId,
            titleText = LuaText.activity_drop_tips_finish,
            effectText = worldMapActivityConf.activity_name,
            effectIcon = methodDropConf.finish_area_tips
          }
          _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPurchaseSuccessfulTips, activityLimitData)
        end
      end
    end
  elseif activityId and activityId > 0 then
    local activityConf = DataConfigManager:GetActivityConf(activityId)
    local allActivityDropId = activityConf and activityConf.base_id or {}
    local bShowTips = true
    for idx, activityDropId in ipairs(allActivityDropId) do
      local activityMethodConf = DataConfigManager:GetActivityDropConf(activityDropId)
      if activityMethodConf then
        local methodList = activityMethodConf.drop_id
        local limitDropIdNum = 0
        if methodList and #methodList > 0 then
          for i, _methodId in ipairs(methodList) do
            if _methodId and _methodId > 0 then
              local dropMethodConf = DataConfigManager:GetActivityDropMethodConf(_methodId)
              if dropMethodConf and ActivityUtils.IsActivityMonitorEventOnline(dropMethodConf.drop_behavior) then
                limitDropIdNum = limitDropIdNum + 1
              end
            end
            self.data:UpdateDropMethodInfo(false, _methodId)
          end
          if limitDropIdNum ~= #methodList then
            bShowTips = false
          end
        end
      end
    end
    if bShowTips and activityConf then
      local activityLimitData = {
        activityId = activityId,
        methodId = methodId,
        titleText = LuaText.activity_drop_tips_finish,
        effectText = activityConf.activity_name,
        effectIcon = methodDropConf.finish_area_tips
      }
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPurchaseSuccessfulTips, activityLimitData)
    end
  end
end

function BigMapModule:OnCmdGetNpcDataByWorldMapConfId(WorldMapConfId)
  return self.data:GetNpcDataByWorldMapConfId(WorldMapConfId)
end

function BigMapModule:SetMapCenterByNPC(refreshId, scaleValue, bSanctuary, notOpenRightPanel, sceneResId)
  local hasPanel = self:HasPanel("MainBigMap")
  if hasPanel then
    local panel = self:GetPanel("MainBigMap")
    panel:SetMapCenterByNPC(refreshId, scaleValue, bSanctuary, notOpenRightPanel, sceneResId)
  end
end

function BigMapModule:SetTempTraceTickEnable(bEnable, bMinimap)
  if bMinimap then
    self.miniMapTickable = bEnable
  else
    self.compassTickable = bEnable
  end
end

function BigMapModule:OnCmdGetDefaultTrackNpcList(defaultTrackType)
  return self.data:GetDefaultTrackNpcList(defaultTrackType)
end

function BigMapModule:OnCmdClearTraceInfoByType(traceType)
  self.data:ClearTraceInfoByType(traceType)
end

function BigMapModule:OnTick(deltaTime)
  self.curTickTime = self.curTickTime + deltaTime
  self.frameCount = self.frameCount + deltaTime
  if self.curTickTime > self.maxTickTime then
    self.curTickTime = 0
  end
  if self.frameCount > self.SkipFrame then
    self.frameCount = 0
    self:DetectionMarker()
  end
end

function BigMapModule:DetectionMarker()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local PlayerPos = Player:GetActorLocation()
  local CompassShowDistance = self.data:GetCompassShowDistance()
  local CustomPointInfo = self.data:GetCustomPointInfo()
  for i = #CustomPointInfo, 1, -1 do
    local Distance = (PlayerPos.X - CustomPointInfo[i].pos.x) * (PlayerPos.X - CustomPointInfo[i].pos.x) + (PlayerPos.Y - CustomPointInfo[i].pos.y) * (PlayerPos.Y - CustomPointInfo[i].pos.y)
    if Distance <= CompassShowDistance * CompassShowDistance then
      self:OnCmdMapMarkOperate(_G.ProtoEnum.MapMarkOpType.MMOT_DELETE_MARK, CustomPointInfo[i].mark_number)
      table.remove(CustomPointInfo, i)
      self.data:SetCustomPointInfo(CustomPointInfo, true)
    end
  end
end

function BigMapModule:OnPlayerDataUpdate()
  self:DispatchEvent(BigMapModuleEvent.StarNumChange)
end

function BigMapModule:OnReLoginUpdate()
  if self:HasPanel("MainBigMap") and self.data.isOpenTravel == true then
    self:ClosePanel("MainBigMap")
  end
  self.data:SetCustomPointInfo(_G.DataModelMgr.PlayerDataModel:GetPlayerMarkInfo())
  self:DispatchEvent(BigMapModuleEvent.MapMarkOperateChangeEvent)
end

function BigMapModule:OnCmdOpenWorldMap(_param)
  self.data:SetShowTaskInfo(nil)
  self.data:SetOpenTaskId(_param)
  local needMsg = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, needMsg)
  local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
  local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MAP
  if isBan then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType1)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
    return
  end
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
  if isSelectBtn then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType1)
    return
  end
  local bInDungeon = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.IsInDungeon)
  if bInDungeon then
    local DungeonInfo = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.GetDungeonInfo)
    if DungeonInfo then
      local dungeonId = DungeonInfo.dungeon_id
      if dungeonId > 0 then
        local dungeonConf = _G.DataConfigManager:GetDungeonConf(dungeonId)
        if nil == dungeonConf or 0 == dungeonConf.world_scene_id then
          local tips = _G.DataConfigManager:GetLocalizationConf("ban_openmap_tips").msg
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
          return
        end
      end
    end
  end
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType2)
  self.data.isOpenTravel = false
  local isOpening, _ = self:HasPanel("MainBigMap")
  if isOpening then
    local mainMap = self:GetPanel("MainBigMap")
    if mainMap then
      mainMap:InitPanelInfo(_param)
    end
  else
    self:OpenMainMapPanel(_param)
  end
  if _param and _param.TaskId then
  else
    if not (_param and _param.focusPos) or not _param.hideRightPanel then
    else
    end
  end
  self:OpenMainMapPanel(_param)
  return true
end

function BigMapModule:OpenMainMapPanel(param)
  local isOpening, _ = self:HasPanel("MainBigMap")
  if isOpening then
    self:OpenPanel("MainBigMap", param)
  else
    self:OpenPanel("MainBigMap", param)
    self.data:GetAreaCollectionRate()
  end
end

function BigMapModule:OnCmdOpenWorldMapDebug()
  local isOpening, _ = self:HasPanel("MainBigMap")
  if isOpening then
    self:OpenPanel("MainBigMap")
  else
    self:OpenPanel("MainBigMap")
  end
end

function BigMapModule:EnableWorldMap()
  if self.updateTraceDelayId then
    DelayManager:CancelDelayById(self.updateTraceDelayId)
    self.updateTraceDelayId = nil
  end
  if self:HasPanel("MainBigMap") then
    local Panel = self:GetPanel("MainBigMap")
    Panel:EnableAndShouldBanWorldRendering()
    self.updateTraceDelayId = DelayManager:DelayFrames(1, function()
      if Panel then
        Panel:UpdateTraceIconPositionAndVisible()
      end
      self.updateTraceDelayId = nil
    end)
  end
end

function BigMapModule:PreLoadWorldMap()
  self:PreLoadPanel("MainBigMap", 10)
end

function BigMapModule:OnCmdCloseWorldMap()
  self:ClosePanel("MainBigMap")
end

function BigMapModule:GetTraceNpcId()
  return self.data:GetCurTraceNpcId()
end

function BigMapModule:GetTraceNpcRefreshId()
  return self.data:GetCurTraceNpcRefreshId()
end

function BigMapModule:GetTraceNpcData(sceneResId)
  return self.data:GetCurTraceNpcData(sceneResId)
end

function BigMapModule:GetCurTraceInfoList()
  return self.data.traceInfoList
end

function BigMapModule:GetMapTraceItemData(traceType)
  if traceType <= 0 then
    return self.data.traceInfoList
  else
    return self.data.traceInfoList[traceType]
  end
end

function BigMapModule:OnCmdGetCurUnlockMapBlockIds()
  return self.data.MapShowList
end

function BigMapModule:OnCmdSetCurShowLayerMap(layerId)
  local hasPanel = self:HasPanel("MainBigMap")
  if hasPanel then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      local layerConf = _G.DataConfigManager:GetLayeredWorldMapConf(layerId)
      if layerConf and layerConf.area_func_id > 0 then
        panel:ShowLayerMap(true, layerId)
      else
        panel:ShowLayerMap(false, layerId, true)
      end
    end
  end
end

function BigMapModule:OnCmdGetMapCenterPos()
  local mapCenterPos = {
    x = 0,
    y = 0,
    z = 0
  }
  local mapSliderScale = 1
  local hasPanel = self:HasPanel("MainBigMap")
  if hasPanel then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      mapCenterPos, mapSliderScale = panel:GetMapCenterPos()
    end
  end
  return mapCenterPos, mapSliderScale
end

function BigMapModule:GetUnlockPortNum()
  local unlockPortNum = 0
  local npcInfos = self.data:GetNpcDatas()
  if nil == npcInfos then
    return 1
  end
  for npcId, npcinfo in pairs(npcInfos) do
    if npcinfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED and npcinfo.npcCfg.genre == _G.Enum.ClientNpcType.CNT_UNLOCKPORT then
      unlockPortNum = unlockPortNum + 1
    end
  end
  return unlockPortNum
end

function BigMapModule:CmdZoneGetCampFruitInfoReq(camp_content_id)
  local req = _G.ProtoMessage:newZoneSceneGetCampFruitNpcInfoReq()
  req.camp_content_id = camp_content_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_GET_CAMP_FRUIT_NPC_INFO_REQ, req, self, self.CmdZoneGetCampFruitInfoRsp, true, false)
end

function BigMapModule:CmdZoneGetCampFruitInfoRsp(rsp)
  self:DispatchEvent(BigMapModuleEvent.UpdateCampFruitInfo, rsp)
end

function BigMapModule:CmdZoneGetCampFruitNpcInfosReq(refreshIds)
  local camp_fruit_npc_infos = {}
  local allPlayerFruitInfo = {}
  local TempAllPlayerFruitInfo = _G.DataModelMgr.PlayerDataModel:GetAllPlayerOwlSanctuaryNpcInfo()
  if nil ~= TempAllPlayerFruitInfo and nil ~= next(TempAllPlayerFruitInfo) then
    for _, OwlSanctuary in pairs(TempAllPlayerFruitInfo) do
      local uin = OwlSanctuary.uin
      for _, OwlSanctuaryInfo in pairs(OwlSanctuary.owl_sanctuarys) do
        local FruitInfo = ProtoMessage:newSpaceAct_OwlSanctuaryFruitInfoUpdate()
        FruitInfo.owl_content_id = OwlSanctuaryInfo.npc_content_id
        FruitInfo.fruit_infos = {}
        if nil ~= next(OwlSanctuaryInfo.fruit_brief_infos) then
          for key, value in ipairs(OwlSanctuaryInfo.fruit_brief_infos) do
            FruitInfo.fruit_infos[key] = value
          end
        end
        FruitInfo.uin = uin
        allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id] = allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id] or {}
        allPlayerFruitInfo[OwlSanctuaryInfo.npc_content_id][uin] = FruitInfo
      end
    end
  end
  local owlSanctuaryTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.OWL_SANCTUARY_CONF)
  if not owlSanctuaryTable then
    self:CmdZoneGetCampFruitNpcInfosRsp(camp_fruit_npc_infos)
    return
  end
  for _, refreshId in pairs(refreshIds) do
    local campFruitNpcInfo = ProtoMessage:newCampFruitNpcInfo()
    campFruitNpcInfo.camp_content_id = refreshId
    campFruitNpcInfo.owl_sanctuary_fruit_npc_info = {}
    local allOwlSanctuaryConfs = owlSanctuaryTable:GetAllDatas()
    for _, owlSanctuaryConf in pairs(allOwlSanctuaryConfs) do
      if owlSanctuaryConf.camp_content_id == refreshId then
        local owlSanctuaryContentId = owlSanctuaryConf.id
        local owlSanctuaryFruitNpcInfo = ProtoMessage:newOwlSanctuaryFruitNpcInfo()
        owlSanctuaryFruitNpcInfo.owl_sanctuary_content_id = owlSanctuaryContentId
        owlSanctuaryFruitNpcInfo.npc_id = {}
        if allPlayerFruitInfo and allPlayerFruitInfo[owlSanctuaryContentId] then
          local sanctuaryData = allPlayerFruitInfo[owlSanctuaryContentId]
          for uin, playerData in pairs(sanctuaryData) do
            if playerData.fruit_infos then
              for _, fruitData in pairs(playerData.fruit_infos) do
                if fruitData.npc_id and next(fruitData.npc_id) then
                  for _, npcId in pairs(fruitData.npc_id) do
                    table.insert(owlSanctuaryFruitNpcInfo.npc_id, npcId)
                  end
                end
              end
            end
          end
        end
        table.insert(campFruitNpcInfo.owl_sanctuary_fruit_npc_info, owlSanctuaryFruitNpcInfo)
      end
    end
    table.insert(camp_fruit_npc_infos, campFruitNpcInfo)
  end
  self:CmdZoneGetCampFruitNpcInfosRsp(camp_fruit_npc_infos)
end

function BigMapModule:CmdZoneGetCampFruitNpcInfosRsp(camp_fruit_npc_infos)
  self.data:SetCampFruitNpcsInfo(camp_fruit_npc_infos)
  local HasPanel = self:HasPanel("MainBigMap")
  if HasPanel then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:RefreshAreaGatherInfo()
    end
  end
end

function BigMapModule:OnCmdGetPetGatherRate(refreshId)
  local x, y = self.data:GetGatherRate(refreshId)
  local text = string.format(_G.DataConfigManager:GetLocalizationConf("worldmap_area_exploration").msg, x, y)
  self:UpdateExploredInfo(Enum.WorldExploringStatisticType.WEST_ELF_TRACE, {
    npc_id = 0,
    belong_camp = refreshId,
    explore_num = x,
    total_num = y
  })
  return x, y
end

function BigMapModule:OnCmdChangeSelectedScene(sceneId)
  if self.data.bNeedClearFakeData then
    if self.data.fakeHomeNpcData then
      for _, fakeHomeNpcData in ipairs(self.data.fakeHomeNpcData) do
        self.data:UpdateHomePetInfo(fakeHomeNpcData, _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE)
      end
    end
    self.data.bNeedClearFakeData = false
  end
  self:DispatchEvent(BigMapModuleEvent.ChangeSelectedScene, sceneId)
  if 30001 == sceneId and _G.HomeIndoorSandbox and not _G.HomeIndoorSandbox:InHomeIndoor() then
    local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
    local playerUinDisplayHome = homeBriefInfo.home_owner_id or 0
    local req = _G.ProtoMessage:newZoneHomeQueryFriendHomeInfoReq()
    req.uin = playerUinDisplayHome
    req.query_info_type = _G.ProtoEnum.QueryFriendHomeInfoType.HOME_PET_INFO
    self.asyncSceneId = sceneId
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_QUERY_FRIEND_HOME_INFO_REQ, req, self, self.OnQueryNpcOutOfRange)
  end
end

function BigMapModule:OnCmdChangeMapScene(sceneResId)
  local HasPanel = self:HasPanel("MainBigMap")
  if HasPanel then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:ChangeMapScene(sceneResId)
    end
  end
end

function BigMapModule:OnQueryNpcOutOfRange(rsp)
  Log.Dump(rsp, 3, "query npc out of range")
  if 0 == rsp.ret_info.ret_code and rsp.friend_cell_home_brief_info and rsp.friend_cell_home_brief_info.home_pets and #rsp.friend_cell_home_brief_info.home_pets > 0 then
    for _, homePet in ipairs(rsp.friend_cell_home_brief_info.home_pets) do
      if homePet.home_pet_info then
        local petCfgId = homePet.home_pet_info.pet_cfg_id
        local petCfg = _G.DataConfigManager:GetPetbaseConf(petCfgId)
        if petCfg then
          local npcModule = NRCModuleManager:GetModule("NPCModule")
          local actorId = npcModule:AcquireFakeID()
          local fakeNpcInfo = {
            base = {
              born_pt = {
                pos = homePet.home_pet_info.pos
              },
              actor_id = actorId,
              lv = homePet.display_info.level
            },
            home_pet = {
              home_pet_info = homePet.home_pet_info
            },
            npc_base = {
              npc_cfg_id = petCfg.home_npc_id
            },
            need_clear_when_close = true
          }
          if homePet.display_info then
            fakeNpcInfo.base_conf_id = homePet.display_info.base_conf_id
            fakeNpcInfo.glass_info = homePet.display_info.glass_info
            fakeNpcInfo.mutation_type = homePet.display_info.mutation_type
          end
          self.data:UpdateHomePetInfo(fakeNpcInfo, _G.Enum.MapModuleDataUpdateReason.HOME_PET_SHOW_NPC_OUT_OF_RANGE)
        end
      end
    end
  end
  self.data.bNeedClearFakeData = true
  self.asyncSceneId = false
end

function BigMapModule:OnCmdOpenBigManualPanel(AreaManualData, atlasId)
  self:OpenPanel("BigManual", AreaManualData, atlasId)
end

function BigMapModule:OnCmdOpenMapRightPanel(Type, _info, worldMapCfg, rspInfo)
  if worldMapCfg and worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_NONE then
    return
  end
  local HasPanel = self:HasPanel("MapRightPanel")
  self:SetMapPanelCanTouchMove(false)
  if not HasPanel then
    self:OpenPanel("MapRightPanel", Type, _info, worldMapCfg, rspInfo)
  else
    local Panel = self:GetPanel("MapRightPanel")
    Panel:ShowPanel(Type, _info, worldMapCfg, rspInfo)
    local HasMainPanel = self:HasPanel("MainBigMap")
    if HasMainPanel then
      local MainPanel = self:GetPanel("MainBigMap")
      MainPanel:OnShowMarker(nil, nil, self.data.curShowSceneResId)
    end
  end
  local HasPanel_1 = self:HasPanel("MainBigMap")
  if HasPanel_1 then
    local Panel = self:GetPanel("MainBigMap")
    Panel:ShowOrHideMoneyBtn(false)
  end
end

function BigMapModule:SetMapPanelCanTouchMove(CanMove)
  local HasPanel = self:HasPanel("MainBigMap")
  if HasPanel then
    local Panel = self:GetPanel("MainBigMap")
    Panel.IsCanMove = CanMove
  end
end

function BigMapModule:OnCmdCloseMapRightPanel()
  local HasPanel = self:HasPanel("MapRightPanel")
  if HasPanel then
    local Panel = self:GetPanel("MapRightPanel")
    Panel:HiddenPanel()
  end
end

function BigMapModule:CheckMapRightPanelOpened()
  return self:HasPanel("MapRightPanel")
end

function BigMapModule:OnCmdSelectMarker(_SelectMarkerInfo)
  self:DispatchEvent(BigMapModuleEvent.UpdateSelectMarkerInfo, _SelectMarkerInfo)
end

function BigMapModule:UpdatePlayerVisitInfo(List)
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    self.data:SetVisitPointInfo(List)
    if self:HasPanel("MainBigMap") then
      local panel = self:GetPanel("MainBigMap")
      panel:UpdateVisitPoint(List)
    end
    local visitorPointInfo = self.data:GetVisitPointInfo()
    local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if visitorPointInfo then
      for k, v in pairs(visitorPointInfo) do
        if v.uin ~= myUin then
          local visitorTraceInfo = {}
          local _sceneResId, iconSceneResId, posX, posY = BigMapUtils.GetVisitorIconSceneResIdAndPos(v)
          local visitorImagePosX, visitorImagePosY = BigMapUtils.ScenePosToImagePosF(iconSceneResId, posX, posY)
          visitorTraceInfo.visitorInfo = {visitorIndex = k, visitorInfo = v}
          visitorTraceInfo.traceType = BigMapModuleEnum.TraceType.Visitor
          visitorTraceInfo.iconImagePos = {x = visitorImagePosX, y = visitorImagePosY}
          visitorTraceInfo.sceneResId = iconSceneResId
          _G.NRCModuleManager:DoCmd(BigMapModuleCmd.StartOrCancelTrace, true, visitorTraceInfo)
        end
      end
    end
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateVisitListInfo)
  end
end

function BigMapModule:OnVisitorChanged(notify)
  local curVisitorList = notify.visitors
  if curVisitorList then
    local traceVisitorInfo = self.data:GetTraceInfoByType(BigMapModuleEnum.TraceType.Visitor)
    local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if traceVisitorInfo then
      for key, _visitor in pairs(traceVisitorInfo) do
        local hasSame = false
        local visitor = _visitor.visitorInfo
        if visitor.visitorInfo and visitor.visitorInfo.uin ~= myUin and #curVisitorList > 0 then
          for k, v in ipairs(curVisitorList) do
            if v.uin == visitor.visitorInfo.uin then
              hasSame = true
              break
            end
          end
        end
        if false == hasSame then
          local traceInfo = {}
          traceInfo.visitorInfo = {
            visitorIndex = visitor.visitorIndex,
            visitorInfo = visitor.visitorInfo
          }
          traceInfo.traceType = BigMapModuleEnum.TraceType.Visitor
          self:OnCmdStartOrCancelTrace(false, traceInfo)
        end
      end
    end
  end
end

function BigMapModule:OnDisconnect()
  local traceNpcInfo = {
    npc_trace_info = {}
  }
  self:OnCmdUpdateNpcTraceInfo(traceNpcInfo)
end

function BigMapModule:OnGetAreaFuncInfo()
  return self.data:GetAreaManualInfo()
end

function BigMapModule:OnCmdGetBroadcastArea()
  return self.data:GetBroadcastArea()
end

function BigMapModule:RefreshData()
  local worldMapInfo = _G.DataModelMgr.PlayerDataModel:GetWorldMapActorInfo()
  self.data:ClearNpcDatas()
  if worldMapInfo then
    self.data:AddUnlockMapBlockId(worldMapInfo.unlocked_world_map_block_cfg_ids)
    self.data:SetMapShowList()
    if worldMapInfo.entries.entry_infos then
      self:UpdateMapEntries(worldMapInfo.entries.entry_infos, true)
    end
    local exploreInfos = worldMapInfo.layered_world_map_explore_info
    if exploreInfos and exploreInfos.explore_infos and #exploreInfos.explore_infos > 0 then
      for k, exploreInfo in ipairs(exploreInfos.explore_infos) do
        local exploreType = self.data.npcIdToExploreInfo[exploreInfo.npc_id]
        if exploreType then
          self:UpdateExploredInfo(exploreType, exploreInfo)
        end
      end
    end
  end
  local magicCreateNpcInfos = _G.DataModelMgr.PlayerDataModel:GetMagicCreateNpcInfo()
  if magicCreateNpcInfos then
    self:UpdateMapEntries(magicCreateNpcInfos)
  end
  local owlSanctuaryNpcInfo = _G.DataModelMgr.PlayerDataModel:GetOwlSanctuaryNpcInfo()
  if owlSanctuaryNpcInfo then
    self:UpdateMapEntries(owlSanctuaryNpcInfo)
  end
  local handBookNpcInfo = self.data.HandBookTraceInfo
  if handBookNpcInfo then
    self:UpdateMapEntries(handBookNpcInfo)
  end
  local homePetInfos = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePetInfo)
  if homePetInfos then
    local homePetInfoEntries = {home_pets = homePetInfos}
    self:UpdateMapEntries(homePetInfoEntries)
  end
  local owlStarBornPointInfos = _G.DataModelMgr.PlayerDataModel:GetOwlStarInfos()
  if owlStarBornPointInfos then
    local t = {npc_owlstar_infos = owlStarBornPointInfos}
    self:UpdateMapEntries(t)
  end
  local MapMarkInfos = _G.DataModelMgr.PlayerDataModel:GetMapMarkInfos()
  self.data:updateNewCustomPoint(MapMarkInfos)
  if not BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) then
    local homeNpcClientData = self:GetHomeNpcClientData()
    if homeNpcClientData then
      local homeNpcClientEntries = {home_npc_client_entries = homeNpcClientData}
      self:UpdateMapEntries(homeNpcClientEntries)
    end
  end
  self:InvalidDisabledMapRedPoint()
  self.data:SetAllMapShowNpcs()
  self.data:SetAllMapShowAreaNpcs()
  self.data:SetAllMiniMapShowNpcs()
  self.data:SetAllMiniMapShowAreaNpcs()
  local TraceInfo = self.data:GetTraceInfoByType(BigMapModuleEnum.TraceType.NPC)
  local TraceNpcData = TraceInfo and TraceInfo.npcInfo
  if TraceNpcData then
    local NPCInfo = self.data:GetNPCInfoByEntryId(TraceNpcData.entry_id, TraceNpcData.logic_id)
    if not NPCInfo then
      Log.Debug("BigMapModule:RefreshData", "TraceNpcData not found", TraceNpcData.entry_id, TraceNpcData.logic_id)
      self.data:CancelTraceOnNpcRemoved(TraceNpcData.entry_id, TraceNpcData.logic_id)
    end
  end
  self:OnCmdClearTraceInfoByType(BigMapModuleEnum.TraceType.ForceTrace)
  _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.OnMapDataRefreshed)
  self.data:SetAutoTrackNpcList(worldMapInfo.auto_track_npc_infos)
  self.data:SortDefaultTrackNpcList()
end

function BigMapModule:DeleteForceTraceInfo()
  local needDeleteList = {}
  local forceTraceInfo = self.data:GetTraceInfoByType(BigMapModuleEnum.TraceType.ForceTrace)
  if forceTraceInfo then
    for trackType, traceInfoList in pairs(forceTraceInfo) do
      if traceInfoList and #traceInfoList > 0 then
        for _, traceInfo in ipairs(traceInfoList) do
          local bExit = false
          if self.data.defaultTrackNpcMap then
            do
              local defaultTrackNpcMap = self.data.defaultTrackNpcMap[trackType]
              if defaultTrackNpcMap and #defaultTrackNpcMap > 0 then
                for _, defaultTrackNpc in ipairs(defaultTrackNpcMap) do
                  if traceInfo.npcInfo and defaultTrackNpc.logic_id == traceInfo.npcInfo.logic_id then
                    bExit = true
                    goto lbl_67
                  end
                end
              end
            end
          end
          if not bExit then
            table.insert(needDeleteList, {
              entryId = traceInfo.npcInfo.entry_id,
              logicId = traceInfo.npcInfo.logic_id
            })
          end
          ::lbl_67::
        end
      end
    end
  end
  if #needDeleteList > 0 then
    for _, deleteInfo in ipairs(needDeleteList) do
      self.data:CancelTraceOnNpcRemoved(0, deleteInfo.entryId, deleteInfo.logicId)
    end
  end
end

function BigMapModule:SetDropMethodInfo()
  local curDropMethodInfos = self:GetActivityDropNpcClientData(Enum.ActivityMonitorEvent.AME_PLAYER_ONLINE_TIME)
  if curDropMethodInfos then
    local dropMethodEntries = {cur_drop_method_infos = curDropMethodInfos}
  end
end

function BigMapModule:SyncWorldMapInfo()
  self:RefreshData()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapAll)
end

function BigMapModule:RefreshExploreInfo()
  local worldMapInfo = _G.DataModelMgr.PlayerDataModel:GetWorldMapActorInfo()
  if worldMapInfo then
    local exploreInfos = worldMapInfo.layered_world_map_explore_info
    if exploreInfos and exploreInfos.explore_infos and #exploreInfos.explore_infos > 0 then
      for k, exploreInfo in ipairs(exploreInfos.explore_infos) do
        local exploreType = self.data.npcIdToExploreInfo[exploreInfo.npc_id]
        if exploreType then
          self:UpdateExploredInfo(exploreType, exploreInfo)
        end
      end
    end
  end
end

function BigMapModule:UpdateMapEntries(entryInfos, bAll)
  if entryInfos.magic_create_npcs and #entryInfos.magic_create_npcs > 0 then
    for _, entry in ipairs(entryInfos.magic_create_npcs) do
      self.data:UpdateMagicCreateNpcInfo(entry)
    end
  elseif entryInfos.owl_sanctuarys and #entryInfos.owl_sanctuarys > 0 then
    for _, entry in ipairs(entryInfos.owl_sanctuarys) do
      self.data:UpdateOwlSanctuaryNpcData(entry)
    end
  elseif entryInfos.npc_trace_info then
    self.data:SetHandBookTrackInfo(entryInfos)
  elseif entryInfos.npc_owlstar_infos then
    for _, info in ipairs(entryInfos.npc_owlstar_infos) do
      self.data:UpdateOwlStarData(info)
    end
  elseif entryInfos.home_pets then
    for _, entry in ipairs(entryInfos.home_pets) do
      self.data:UpdateHomePetInfo(entry, _G.ProtoEnum.MapModuleDataUpdateReason.HOME_PET_ENTER)
    end
  elseif entryInfos.home_npc_client_entries then
    for _, entry in ipairs(entryInfos.home_npc_client_entries) do
      self.data:UpdateHomeClientNpcInfo(entry)
    end
  elseif entryInfos.cur_drop_method_infos then
    for _, entry in ipairs(entryInfos.cur_drop_method_infos) do
      self.data:UpdateDropMethodInfo(entry)
    end
  else
    for _, entry in ipairs(entryInfos) do
      if entry.entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.MySelf then
        self.data:UpdateHeroInfo(entry.myself_entry_info)
      elseif entry.entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.BText then
        self.data:UpdateAreaInfo(entry.btext_entry_info)
      elseif entry.entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.Npc then
        self.data:UpdateNpcInfo(entry.entry_id, entry.npc_entry_info, bAll)
      elseif entry.entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.Area then
        self.data:UpdateMapAreaInfo(entry.area_entry_info)
      elseif entry.entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.SceneEvent then
        if entry.npc_entry_info then
          self.data:UpdateNpcInfo(entry.entry_id, entry.npc_entry_info)
        end
        local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        if nil ~= player then
          player:AddPlayCathPetEffect(entry.scene_event.event_info)
        end
        if self.debugCatchPetToggle then
          self:LogError("\228\186\139\228\187\182\229\145\189\228\184\173\230\172\161\230\149\176", entry.scene_event.event_info.hit_times)
          self:LogError("\228\186\139\228\187\182\231\138\182\230\128\129", entry.scene_event.event_info.status)
          self:LogError("\228\186\139\228\187\182\233\133\141\231\189\174id", entry.scene_event.event_info.id)
          self:LogError("bonus_type", entry.scene_event.bonus_type)
          self:LogError("bonus_event_pool_cfg_id", entry.scene_event.bonus_event_pool_cfg_id)
        end
        entry.scene_event.event_info = {}
      elseif entry.entry_type == _G.ProtoEnum.WorldMapEntryType.ENUM.Mark then
        self.data:SetNewCustomPointInfo(entry.mark_entry_info)
      else
        Log.Error("unknown entry type!!", entry.entry_type)
      end
    end
  end
end

function BigMapModule:GetHomeNpcClientData()
  local homeClientNpcInfos = {}
  if self.data.clientNpcList then
    for showLocationType, npcList in pairs(self.data.clientNpcList) do
      if (showLocationType == Enum.MapIconShowLocation.MISL_HOME_INDOOR or showLocationType == Enum.MapIconShowLocation.MISL_HOME_PLANT) and npcList and #npcList > 0 then
        for key, npcWorldMapConf in ipairs(npcList) do
          local homeClientNpcInfo = {}
          local refreshIds = npcWorldMapConf.npc_refresh_ids
          if refreshIds and #refreshIds > 0 then
            for k, refreshId in ipairs(refreshIds) do
              local npcRefreshConf = DataConfigManager:GetNpcRefreshContentConf(refreshId)
              homeClientNpcInfo.entry_id = ProtoEnum.WorldMapEntryType.ENUM.Npc * 2.81474976710656E14 - refreshId
              homeClientNpcInfo.npc_refresh_id = refreshId
              homeClientNpcInfo.worldMapConf = npcWorldMapConf
              homeClientNpcInfo.world_map_cfg_id = npcWorldMapConf.id
              homeClientNpcInfo.status = ProtoEnum.LockStatus.ENUM.UNLOCKED
              homeClientNpcInfo.npc_cfg_id = npcRefreshConf.npc_id
              homeClientNpcInfo.unlocked = true
              homeClientNpcInfo.npc_pos = self:GetPosByRefreshType(npcRefreshConf.refresh_type, npcRefreshConf.refresh_param)
              table.insert(homeClientNpcInfos, homeClientNpcInfo)
            end
          end
        end
      end
    end
  end
  return homeClientNpcInfos
end

function BigMapModule:GetPosByRefreshType(refreshType, refreshParam)
  local pos = {
    x = 0,
    y = 0,
    z = 0
  }
  if refreshType == Enum.RefreshType.RFT_AREA then
    pos = self:GetPosByAreaId(refreshParam)
  end
  return pos
end

function BigMapModule:GetPosByAreaId(areaId)
  local pos = {
    x = 0,
    y = 0,
    z = 0
  }
  local areaConf = DataConfigManager:GetAreaConf(areaId)
  if areaConf.area_type == Enum.AreaType.AREAT_POINT then
    local pointPos = areaConf.pos[1]
    if pointPos and pointPos.position_xyz and #pointPos.position_xyz >= 3 then
      pos.x = pointPos.position_xyz[1]
      pos.y = pointPos.position_xyz[2]
      pos.z = pointPos.position_xyz[3]
    end
  end
  return pos
end

function BigMapModule:GetActivityDropNpcClientData(behaviorType)
  local dropActivities = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_DROP, true)
  local dropNpcInfos = {}
  for k, dropActivity in pairs(dropActivities) do
    local activityDropConf = DataConfigManager:GetActivityDropConf(dropActivity.activityConf.id)
    if activityDropConf then
      local dropIdList = activityDropConf.drop_id
      for key, dropId in ipairs(dropIdList) do
        local dropMethodConf = DataConfigManager:GetActivityDropMethodConf(dropId)
        if dropMethodConf and dropMethodConf.drop_behavior == behaviorType then
          local worldMapActivityConf = DataConfigManager:GetWorldMapActivityConf(dropMethodConf.world_map_activity_conf_id)
          if worldMapActivityConf then
            local npcWorldMapConf = DataConfigManager:GetWorldMapConf(worldMapActivityConf.world_map_id)
            local dropNpcInfo = {}
            local showAreaId = npcWorldMapConf.name_area_id
            local refreshIds = npcWorldMapConf.npc_refresh_ids
            if refreshIds and #refreshIds > 0 then
              for _key, refreshId in ipairs(refreshIds) do
                local npcRefreshConf = DataConfigManager:GetNpcRefreshContentConf(refreshId)
                dropNpcInfo.entry_id = ProtoEnum.WorldMapEntryType.ENUM.Npc * 2.81474976710656E14 - refreshId
                dropNpcInfo.npc_refresh_id = refreshId
                dropNpcInfo.worldMapConf = npcWorldMapConf
                dropNpcInfo.worldMapActivityConf = worldMapActivityConf
                dropNpcInfo.world_map_cfg_id = npcWorldMapConf.id
                dropNpcInfo.status = ProtoEnum.LockStatus.ENUM.UNLOCKED
                dropNpcInfo.npc_cfg_id = npcRefreshConf.npc_id
                dropNpcInfo.unlocked = true
                dropNpcInfo.npc_pos = self:GetPosByAreaId(showAreaId)
                table.insert(dropNpcInfos, dropNpcInfo)
              end
            end
          end
        end
      end
    end
  end
  return dropNpcInfos
end

function BigMapModule:OnCmdRemoveNpcIconByNpcId(npcId, logicId)
  local hasPanel = self:HasPanel("MainBigMap")
  if hasPanel then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:RemoveNpcIconByNpcId(npcId, logicId)
    end
  end
end

function BigMapModule:RemoveCircleByTypeAndKey(type, key, extraKey)
  local hasPanel = self:HasPanel("MainBigMap")
  if hasPanel then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:RemoveCircleIcon(type, key, extraKey)
    end
  end
end

function BigMapModule:OnCmdUpdateGuideTask(notify)
  if not notify then
    self.data:SetAccessTaskInfo({})
    return
  end
  self.data:SetAccessTaskInfo(notify)
end

function BigMapModule:OnCmdUpdateNpcTraceInfo(notify)
  self.data:SetHandBookTrackInfo(notify)
  Log.Debug("BigMapModule:OnCmdUpdateNpcTraceInfo!!")
  local npcDatas = self.data:GetNpcDatas()
  local mapAreaDatas = self.data:GetMapAreaDatas()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetCompassUpdateTrace, true)
end

function BigMapModule:OnTickWorldMapInfoSyncRsp(_rsp)
  Log.Debug("BigMapModule:OnTickWorldMapInfoSyncRsp!!")
end

function BigMapModule:OnCmdSendWorldMapTeleportReq(_npcId, bUseSpecial)
  local req = _G.ProtoMessage:newZoneSceneWorldMapTeleportReq()
  req.entry_id = _npcId
  req.use_special_teleport = bUseSpecial
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_TELEPORT_REQ, req, self, self.OnWorldMapTeleportRsp, true)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
  end
end

function BigMapModule:OnWorldMapTeleportRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
  end
end

function BigMapModule:OnCmdSendSceneWorldMapTeleportToNpcReq(npcObjId)
  local req = _G.ProtoMessage:newZoneSceneWorldMapTeleportToNpcReq()
  req.npc_obj_id = npcObjId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_TELEPORT_TO_NPC_REQ, req, self, self.OnWorldMapNpcTeleportRsp, true)
end

function BigMapModule:OnWorldMapNpcTeleportRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:OnCmdCloseWorldMap()
    self:ClosePanel("MapRightPanel")
  end
end

function BigMapModule:OnCmdZoneSceneWorldMapTeleportToPlayerReq(uin)
  local req = _G.ProtoMessage:newZoneSceneWorldMapTeleportToPlayerReq()
  req.uin = uin
  Log.DebugFormat("BigMapModule:OnCmdZoneSceneWorldMapTeleportToPlayerReq uin = %s", tostring(uin))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_TELEPORT_TO_PLAYER_REQ, req, self, self.OnWorldMapTeleportToPlayerRsp, true)
end

function BigMapModule:OnWorldMapTeleportToPlayerRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    Log.DebugFormat("BigMapModule:OnWorldMapTeleportToPlayerRsp success, uin = %s, posX = %s, posY = %s, posZ = %s", tostring(_rsp.uin), tostring(_rsp.target_pt.pos.x), tostring(_rsp.target_pt.pos.y), tostring(_rsp.target_pt.pos.z))
    self:OnCmdCloseWorldMap()
    self:ClosePanel("MapRightPanel")
  else
    Log.ErrorFormat("BigMapModule:OnWorldMapTeleportToPlayerRsp failed, ret_code = %s", tostring(_rsp.ret_info.ret_code))
  end
end

function BigMapModule:OnCmdZoneSceneTeleportToPlayerReq(uin)
  local req = _G.ProtoMessage:newZoneSceneTeleportToPlayerReq()
  req.uin = uin
  req.tele_reason = ProtoEnum.TeleportToPlayerReason.TTPR_VISIBLE_CIRCLE
  Log.DebugFormat("BigMapModule:OnCmdZoneSceneTeleportToPlayerReq uin = %s, tele_reason=%s", tostring(uin), tostring(req.tele_reason))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TELEPORT_TO_PLAYER_REQ, req, self, self.OnWorldMapTeleportToPlayerRsp, true)
end

function BigMapModule:OnWorldMapTeleportToPlayerRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    Log.Debug("BigMapModule:OnWorldMapTeleportToPlayerRsp success!!")
  else
    Log.ErrorFormat("BigMapModule:OnWorldMapTeleportToPlayerRsp failed, ret_code = %s", tostring(_rsp.ret_info.ret_code))
  end
end

function BigMapModule:OnCmdTeleportToPlayerReq(Uin)
  local isUIFunctionBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_TELEPORT_ROLE, true)
  if isUIFunctionBan then
    Log.Warning("BigMapModule:OnCmdTeleportToPlayerReq function baned FE_TELEPORT_ROLE")
    return
  end
  if _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.CheckInFightingOrObserver) then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.battle_chat_not_teleport)
    return
  end
  local bBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, _G.Enum.PlayerFunctionBanType.PFBT_TELEPORT_FEIEND)
  if bBan then
    Log.Warning("BigMapModule:OnCmdTeleportToPlayerReq function baned PFBT_TELEPORT_FEIEND")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.visible_circle_list_btn_func_ban_tips)
    return
  end
  local curSecTime = os.msTime() / 1000
  local teleportLastTimeSec = self.data:GetTeleportLastTimeStampSec()
  local CDTime = self.data:GetTeleportCDTimeSec()
  if CDTime > curSecTime - teleportLastTimeSec then
    Log.WarningFormat("BigMapModule:OnCmdTeleportToPlayerReq in CD time, curSecTime=%s, teleportLastTimeSec=%s, CDTime=%s", tostring(curSecTime), tostring(teleportLastTimeSec), tostring(CDTime))
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.visible_circle_list_btn_CD_tips)
    return
  end
  self.data:SetTeleportLastTimeStampSec(curSecTime)
  local isVisitor = false
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if visitorList then
      for _, visitor in ipairs(visitorList) do
        if visitor.uin == Uin then
          isVisitor = true
          break
        end
      end
    end
  end
  Log.DebugFormat("BigMapModule:OnCmdTeleportToPlayerReq try close chat panel. isVisitor=%s, Uin=%s", tostring(isVisitor), tostring(Uin))
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseChatMainPanel)
  if isVisitor then
    self:OnCmdZoneSceneWorldMapTeleportToPlayerReq(Uin)
  else
    self:OnCmdZoneSceneTeleportToPlayerReq(Uin)
  end
end

function BigMapModule:OnCmdSendZoneDungeonInfoQueryReq(dungeonNpcInfo, dungeonId)
  local req = _G.ProtoMessage:newZoneSceneDungeonInfoQueryReq()
  self.dungeonNPCInfo = dungeonNpcInfo
  req.dungeon_cfg_id = dungeonId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_DUNGEON_INFO_QUERY_REQ, req, self, self.OnZoneDungeonInfoQueryRsp)
end

function BigMapModule:OnZoneDungeonInfoQueryRsp(_rsp)
  if not self:HasPanel("MainBigMap") then
    return
  end
  local panel = self:GetPanel("MainBigMap")
  panel:OnShowNormalNpcEventDungeon(self.dungeonNPCInfo, _rsp)
end

function BigMapModule:OnCmdGetPlayerToNpcDistance(npc_refresh_id)
  local NpcDatas = self.data.npcDatas
  if not NpcDatas then
    Log.Error("BigMapModule:OnCmdGetPlayerToNpcDistance invalid")
    return false
  end
  for i, v in pairs(NpcDatas) do
    local Datas
    Datas = self.data:GetAllShowNpcs(i)
    if Datas then
      for _, datas in pairs(Datas) do
        for _, _datas in pairs(datas) do
          for j, k in pairs(_datas) do
            if k.npc_refresh_id and k.npc_refresh_id == npc_refresh_id then
              local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
              if not player then
                return 0
              end
              local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), k.npc_pos)
              return math.floor((tempDist / 10000) ^ 0.5)
            end
          end
        end
      end
    end
  end
  return 0
end

function BigMapModule:OnCmdSendZoneTeamBattleInfoQueryReq(npcInfo, entrance)
  local req = _G.ProtoMessage:newZoneSceneTeamBattleInfoQueryReq()
  self.teamBattleNPCInfo = npcInfo
  req.npc_logic_id = npcInfo.logic_id
  req.query_source = entrance
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INFO_QUERY_REQ, req, self, self.OnZoneTeamBattleInfoQueryRsp)
end

function BigMapModule:OnZoneTeamBattleInfoQueryRsp(rsp)
  if not self:HasPanel("MainBigMap") then
    return
  end
  if 0 == rsp.ret_info.ret_code then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:OnShowNormalNpcEventTeamBattleTips(self.teamBattleNPCInfo, rsp)
    end
  end
end

function BigMapModule:OnCmdSendZoneSceneQueryBeastChallengeReq(npcInfo)
  self.legendaryBattleNPCInfo = npcInfo
  local req = _G.ProtoMessage:newZoneSceneQueryBeastChallengeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUERY_BEAST_CHALLENGE_REQ, req, self, self.OnZoneQueryBeastChallengeRsp)
end

function BigMapModule:OnZoneQueryBeastChallengeRsp(rsp)
  local panel = self:GetPanel("MainBigMap")
  if panel then
    panel:OnShowNormalNpcEventLegendaryBattle(self.legendaryBattleNPCInfo, rsp)
  end
end

function BigMapModule:OnCmdTracePet(npc_refresh_id)
  local npcCfgId = {}
  if npc_refresh_id and type(npc_refresh_id) == "number" then
    local evoConf = _G.DataConfigManager:GetPetEvolutionConf(npc_refresh_id)
    local evo_chain = evoConf and evoConf.evolution_chain
    if evo_chain then
      for i, v in ipairs(evo_chain) do
        local baseId = v.petbase_id
        local BaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
        if BaseConf and BaseConf.pet_track_npc_id then
          for _, track_npc_id in ipairs(BaseConf.pet_track_npc_id) do
            table.insert(npcCfgId, track_npc_id)
          end
        end
      end
    end
  elseif npc_refresh_id and type(npc_refresh_id) == "table" then
    for i, v in pairs(npc_refresh_id) do
      local evoConf = _G.DataConfigManager:GetPetEvolutionConf(v)
      local evo_chain = evoConf and evoConf.evolution_chain
      if evo_chain then
        for _, j in ipairs(evo_chain) do
          local baseId = j.petbase_id
          local BaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
          if BaseConf and BaseConf.pet_track_npc_id then
            for _, track_npc_id in ipairs(BaseConf.pet_track_npc_id) do
              table.insert(npcCfgId, track_npc_id)
            end
          end
        end
      end
    end
  end
  self:OnCmdSendZoneNpcTraceQueryReq(npcCfgId)
end

function BigMapModule:OnCmdSendZoneNpcTraceQueryReq(npcCfgId, cancelTrace)
  if true == cancelTrace then
  else
    local bMapUnlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, SceneUtils.GetSceneResId())
    if not bMapUnlock then
      if self.TraceErrorTips then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.TraceErrorTips)
        self.TraceErrorTips = nil
      else
        local tips = _G.DataConfigManager:GetLocalizationConf("handbook_nomap_track_fail_text").msg
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
      end
      return
    end
  end
  local req = _G.ProtoMessage:newZoneNpcTraceQueryReq()
  req.npc_cfg_id = npcCfgId
  req.cancel_trace = cancelTrace
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_NPC_TRACE_QUERY_REQ, req, self, self.ZoneNpcTraceQueryRsp, false, true)
end

function BigMapModule:OnCmdSendZoneSelectTrackContentsReq(firstTrackContentIds, petBaseIds, cancelTrace)
  if true == cancelTrace then
  else
    local bMapUnlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, SceneUtils.GetSceneResId())
    if not bMapUnlock then
      if self.TraceErrorTips then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.TraceErrorTips)
        self.TraceErrorTips = nil
      else
        local tips = _G.DataConfigManager:GetLocalizationConf("handbook_nomap_track_fail_text").msg
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
      end
      return
    end
  end
  local req = _G.ProtoMessage:newZoneActivitySelectTrackContentsReq()
  req.pet_base_id = petBaseIds
  req.track_content_ids = firstTrackContentIds
  req.cancel_trace = cancelTrace
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_SELECT_TRACK_CONTENTS_REQ, req, self, self.ZoneNpcTraceQueryRsp, false, true)
end

function BigMapModule:OnCmdSendZoneNpcTraceCollectibles(npc_id, ItemId)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(ItemId)
  if bagItemConf then
    self.TraceErrorTips = string.format(LuaText.trace_collectibles_not_found, bagItemConf.name)
    self:OnCmdSendZoneNpcTraceQueryReq(npc_id)
  else
    self.TraceErrorTips = nil
  end
end

function BigMapModule:OnCmdNpcTraceQueryByPetBaseId(petBaseId)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if petBaseConf and petBaseConf.pet_track_npc_id and #petBaseConf.pet_track_npc_id > 0 then
    self:OnCmdSendZoneNpcTraceQueryReq(petBaseConf.pet_track_npc_id)
  end
end

function BigMapModule:ZoneNpcTraceQueryRsp(rsp)
  local ErrorCode = rsp.ret_info.ret_code
  if 0 == ErrorCode then
    if rsp.npc_trace_info and rsp.npc_trace_info.content_id then
      self:OnCmdOpenWorldMap({
        centerNPCRefreshId = rsp.npc_trace_info.content_id,
        bNotRightPanel = true
      })
      self.data:SetHandBookTrackInfo(rsp)
    else
      self:OnCmdUpdateNpcTraceInfo(rsp)
    end
  elseif self.TraceErrorTips then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.TraceErrorTips)
    self.TraceErrorTips = nil
  else
    local errorTips = _G.DataConfigManager:GetLocalizationConf("handbook_track_fail_text").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, errorTips)
  end
  if self.TraceErrorTips then
    self.TraceErrorTips = nil
  end
end

function BigMapModule:OnCmdGetAllMapDatas()
  return self.data.MapDatas
end

function BigMapModule:DistSquared2D(a, b)
  if not a or not b then
    return math.maxinteger
  end
  local X = (a.X or a.x) - (b.X or b.x)
  local Y = (a.Y or a.y) - (b.Y or b.y)
  return X * X + Y * Y
end

function BigMapModule:OnCmdTraceNpcByRefreshID(_npcRefreshId, needTraceOnFogArea)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local data = self.data:SetCurTraceNpcByRefreshID(_npcRefreshId, nil, needTraceOnFogArea)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapTraceNpcState)
  return data
end

function BigMapModule:OnCmdTraceNearAlchemyNpc(tips)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local success = self:OnFindNearTargetNpcByClientNpcType(Enum.ClientNpcType.CNT_ALCHEMY, true, true, false)
  if not success then
    if tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
    end
  end
end

function BigMapModule:OnCmdTraceNearLockCampNpc()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local success = self:OnFindNearTargetNpcByClientNpcType(Enum.ClientNpcType.CNT_CAMP, false, true, false)
  if not success then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
  end
end

function BigMapModule:OnCmdTraceSpecificNpc(RefreshId, args2)
  if RefreshId and type(RefreshId) == "number" then
    local success = self:OnFindNpcByRefreshId(RefreshId, true, false, false, nil, nil, 1 == args2)
    if not success then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error3)
    end
  elseif RefreshId and type(RefreshId) == "table" then
    local FindNpcRefreshId
    local DistSquared = -1
    for i, v in pairs(RefreshId) do
      local refresh_id = tonumber(v)
      local npcInfo = self.data:GetNpcInfoByRefreshId(refresh_id)
      local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      if not player then
        return
      end
      if npcInfo and self:CheckShouldShowNpc(npcInfo) then
        local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), npcInfo.npc_pos)
        if DistSquared > tempDist or -1 == DistSquared then
          DistSquared = tempDist
          FindNpcRefreshId = refresh_id
        end
      end
    end
    if DistSquared > -1 and FindNpcRefreshId then
      local success = self:OnFindNpcByRefreshId(FindNpcRefreshId, true, true, false, nil, nil, 1 == args2)
      if success then
        return
      end
    end
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error3)
  end
end

function BigMapModule:OnCmdTraceForceShowNpc(npc_refresh_id, args2)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  if npc_refresh_id and type(npc_refresh_id) == "number" then
    local success = self:OnFindNpcByRefreshId(npc_refresh_id, false, false, true, nil, true, 1 == args2)
    if success then
    end
  elseif npc_refresh_id and type(npc_refresh_id) == "table" then
    local FindNpcRefreshId
    local DistSquared = -1
    for i, v in pairs(npc_refresh_id) do
      local refresh_id = tonumber(v)
      local npcInfo = self.data:GetNpcInfoByRefreshId(refresh_id)
      local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      if not player then
        return
      end
      if npcInfo then
        local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), npcInfo.npc_pos)
        if DistSquared > tempDist or -1 == DistSquared then
          DistSquared = tempDist
          FindNpcRefreshId = refresh_id
        end
      end
    end
    if DistSquared > -1 and FindNpcRefreshId then
      local success = self:OnFindNpcByRefreshId(FindNpcRefreshId, false, false, true, nil, true, 1 == args2)
      if success then
        return
      end
    end
  end
end

function BigMapModule:OnCmdTraceCampNpc(campid)
  if campid and type(campid) == "number" then
    local success = self:OnFindNpcByRefreshId(campid, false, false, true, nil, true)
    if not success then
      self:OnCmdTraceNearUnLockCampNpc()
    end
  elseif campid and type(campid) == "table" then
    for i, v in pairs(campid) do
      local success = self:OnFindNpcByRefreshId(tonumber(v), false, false, true, nil, true)
      if success then
        return
      end
    end
    self:OnCmdTraceNearUnLockCampNpc()
  end
end

function BigMapModule:OnCmdTraceNearUnLockCampNpc(tips)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local success = self:OnFindNearTargetNpcByClientNpcType(Enum.ClientNpcType.CNT_CAMP, false, false, false)
  if not success and tips then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
  end
end

function BigMapModule:OnCmdTraceBossByEggItemId(tips, param)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local success, IsHasRefreshTime = self:OnFindNpcByRefreshId(param, true, true, true)
  if not success then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      if IsHasRefreshTime then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.jump_to_respawn_boss)
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip3)
      end
    elseif tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
    end
  end
end

function BigMapModule:OnCmdTraceNearOutDoorChallengeNpc()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local success = self:OnFindNearTargetNpcByClientNpcType(Enum.ClientNpcType.CNT_OUTDOOR_CHALLENGE, false, false)
  if not success then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error3)
  end
end

function BigMapModule:OnCmdGetAllRefreshContentConfs()
  return self.data.npcRefreshContentDatas
end

function BigMapModule:OnCmdTraceNearUnlockAlchemyNpc(tips)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP)
  if isBan then
    if _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.IsPlaying) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2331)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip8)
    end
    return
  end
  local success = self:OnFindNearTargetNpcByClientNpcType(Enum.ClientNpcType.CNT_ALCHEMY, true, false, false)
  if not success then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip1)
    elseif tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
    end
  end
end

function BigMapModule:GetNearestAlchemyRefreshId(ClientNpcType, CheckInFog, NeedLock)
  local NpcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return 140002
  end
  if not NpcDatas then
    return 140002
  end
  local FindNpcRefreshId
  local DistSquared = -1
  for i, k in pairs(NpcDatas) do
    for _, _datas in pairs(k) do
      for j, v in pairs(_datas) do
        local npcCfg = v.npcCfg
        if npcCfg and npcCfg.genre == ClientNpcType then
          if NeedLock then
            if v.status and v.status == _G.ProtoEnum.LockStatus.ENUM.LOCKED then
              if CheckInFog then
                if v.npc_pos and self:CheckNpcInFogArea(v.npc_pos) then
                  local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                  if DistSquared > tempDist or -1 == DistSquared then
                    DistSquared = tempDist
                    FindNpcRefreshId = v.npc_refresh_id
                  end
                end
              else
                local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                if DistSquared > tempDist or -1 == DistSquared then
                  DistSquared = tempDist
                  FindNpcRefreshId = v.npc_refresh_id
                end
              end
            elseif ClientNpcType == Enum.ClientNpcType.CNT_ALCHEMY and v.npc_pos and self:CheckNpcInFogArea(v.npc_pos) then
              local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
              if DistSquared > tempDist or -1 == DistSquared then
                DistSquared = tempDist
                FindNpcRefreshId = v.npc_refresh_id
              end
            end
          elseif v.status and v.status ~= _G.ProtoEnum.LockStatus.ENUM.LOCKED then
            if CheckInFog and ClientNpcType ~= Enum.ClientNpcType.CNT_ALCHEMY then
              if v.npc_pos and self:CheckNpcInFogArea(v.npc_pos) then
                local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                if DistSquared > tempDist or -1 == DistSquared then
                  DistSquared = tempDist
                  FindNpcRefreshId = v.npc_refresh_id
                end
              end
            else
              local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
              if DistSquared > tempDist or -1 == DistSquared then
                DistSquared = tempDist
                FindNpcRefreshId = v.npc_refresh_id
              end
            end
          end
        end
      end
    end
  end
  return FindNpcRefreshId
end

function BigMapModule:OnFindNearTargetNpcByClientNpcType(ClientNpcType, CheckInFog, NeedLock, NeedTrace, CustomMapSliderScale)
  local NpcDatas = self.data.npcDatas
  if not NpcDatas then
    Log.Error("BigMapModule:OnFindNpcByRefreshId NPC data is invalid")
    return false
  end
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  if not NpcDatas then
    return
  end
  local FindNpcRefreshId, FindWorldMapConfId
  local DistSquared = -1
  for i, k in pairs(NpcDatas) do
    local Datas
    if not CheckInFog then
      Datas = k
    else
      Datas = self.data:GetAllShowNpcs(i)
    end
    if Datas then
      for _, datas in pairs(Datas) do
        for _, _datas in pairs(datas) do
          for j, v in pairs(_datas) do
            local npcCfg = v.npcCfg
            if npcCfg and npcCfg.genre == ClientNpcType then
              if NeedLock then
                if v.status and v.status == _G.ProtoEnum.LockStatus.ENUM.LOCKED then
                  if CheckInFog then
                    if v.npc_pos and self:CheckNpcInFogArea(v.npc_pos) then
                      local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                      if DistSquared > tempDist or -1 == DistSquared then
                        DistSquared = tempDist
                        FindNpcRefreshId = v.npc_refresh_id
                        FindWorldMapConfId = v.world_map_cfg_id
                      end
                    end
                  else
                    local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                    if DistSquared > tempDist or -1 == DistSquared then
                      DistSquared = tempDist
                      FindNpcRefreshId = v.npc_refresh_id
                      FindWorldMapConfId = v.world_map_cfg_id
                    end
                  end
                elseif ClientNpcType == Enum.ClientNpcType.CNT_ALCHEMY and v.npc_pos and self:CheckNpcInFogArea(v.npc_pos) then
                  local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                  if DistSquared > tempDist or -1 == DistSquared then
                    DistSquared = tempDist
                    FindNpcRefreshId = v.npc_refresh_id
                    FindWorldMapConfId = v.world_map_cfg_id
                  end
                end
              elseif v.status and v.status ~= _G.ProtoEnum.LockStatus.ENUM.LOCKED then
                if CheckInFog and ClientNpcType ~= Enum.ClientNpcType.CNT_ALCHEMY then
                  if v.npc_pos and self:CheckNpcInFogArea(v.npc_pos) then
                    local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                    if DistSquared > tempDist or -1 == DistSquared then
                      DistSquared = tempDist
                      FindNpcRefreshId = v.npc_refresh_id
                      FindWorldMapConfId = v.world_map_cfg_id
                    end
                  end
                else
                  if SceneUtils.GetSceneResId() == 30002 and 30002 == i then
                    local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                    if DistSquared > tempDist or -1 == DistSquared then
                      DistSquared = tempDist
                      FindNpcRefreshId = v.npc_refresh_id
                      FindWorldMapConfId = v.world_map_cfg_id
                    end
                  end
                  if BigMapUtils.IsBigWorldMap(i) then
                    local tempDist = self:DistSquared2D(player:GetActorLocationFrameCache(), v.npc_pos)
                    if DistSquared > tempDist or -1 == DistSquared then
                      DistSquared = tempDist
                      FindNpcRefreshId = v.npc_refresh_id
                      FindWorldMapConfId = v.world_map_cfg_id
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  if DistSquared > -1 and FindNpcRefreshId and FindWorldMapConfId then
    if self:HasPanel("MainBigMap") then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
      self:DispatchEvent(BigMapModuleEvent.SwitchSelectIconEvent, FindNpcRefreshId)
      return true
    end
    if NeedTrace then
      self:OnCmdTraceNpcByRefreshID(FindNpcRefreshId)
    end
    self:TraceNpcOpenMapCenter(FindWorldMapConfId, CustomMapSliderScale, FindNpcRefreshId)
    return true
  else
    return false
  end
end

function BigMapModule:IsShowMaskMap(sceneResId)
  if self.data.sceneResIdToBlockConf then
    local blockConf = self.data.sceneResIdToBlockConf[sceneResId]
    if blockConf then
      if 1 == blockConf.not_foggy then
        return false
      else
        return true
      end
    end
  end
  return false
end

function BigMapModule:CheckNpcInFogArea(npc_pos, sceneResId)
  local actualSceneResId = BigMapUtils.GetDefaultSceneResId()
  if nil == sceneResId then
    actualSceneResId = BigMapUtils.GetSceneResIdByPos(npc_pos.x, npc_pos.y)
  end
  sceneResId = sceneResId or actualSceneResId
  if self:IsShowMaskMap(sceneResId) then
    local imageWidth = 6144
    local imageHeight = 6144
    local posX, posY = BigMapUtils.ScenePosToImagePos(sceneResId, npc_pos.x, npc_pos.y)
    local posU = posX / imageWidth * 1024
    local posV = posY / imageHeight * 1024
    local unlockDeadWoodList = self.data.UnlockDeadwoodList
    if unlockDeadWoodList then
      local curUnlockDeadWoodList = self.data.UnlockDeadwoodList[sceneResId]
      local areaIdArray = UE4.UNRCTUIStatics.GetPointAreaId(posU, posV, curUnlockDeadWoodList)
      local areaIds = areaIdArray:ToTable()
      Log.Dump(areaIds, 5, "BigMapModule:CheckInFogAreaByPos")
      if areaIds and #areaIds > 0 then
        return true
      end
    end
    return false
  end
  return true
end

function BigMapModule:CheckShowMaskTop(npcInfo)
  if npcInfo and npcInfo.worldMapConf then
    local worldMapConf = npcInfo.worldMapConf
    if npcInfo.status == ProtoEnum.LockStatus.ENUM.LOCKED then
      return 1 == worldMapConf.lock_element_show_top
    else
      return 1 == worldMapConf.unlock_element_show_top
    end
  end
  return false
end

function BigMapModule:CheckShouldShowNpc(npcInfo)
  return self.data:CheckShouldShowNpc(npcInfo)
end

function BigMapModule:CheckShowTempIcon(npcInfo)
  if not self:CheckShowMaskTop(npcInfo) and not self:CheckNpcInFogArea(npcInfo.npc_pos) then
    return true
  end
  if not self.data:CheckShouldShowNpc(npcInfo) then
    return true
  end
  return false
end

function BigMapModule:CheckNpcInFogAreaByRefreshId(RefreshId)
  local NpcDatas = self.data.npcDatas
  if not NpcDatas then
    Log.Error("BigMapModule:OnFindNpcByRefreshId NPC data is invalid")
    return false
  end
  for i, v in pairs(NpcDatas) do
    local Datas
    Datas = v
    if Datas then
      for _, datas in pairs(Datas) do
        for _, _datas in pairs(datas) do
          for j, k in pairs(_datas) do
            local BossRefreshID = k.npc_refresh_id
            if not BossRefreshID and k.world_map_cfg_id then
              local worldCfg = _G.DataConfigManager:GetWorldMapConf(k.world_map_cfg_id)
              if worldCfg then
                BossRefreshID = worldCfg.npc_refresh_ids[1]
              end
            end
            if BossRefreshID and BossRefreshID == RefreshId then
              local InFogArea = self:CheckNpcInFogArea(k.npc_pos, i)
              return InFogArea
            end
          end
        end
      end
    end
  end
  return false
end

function BigMapModule:OnFindNpcByRefreshId(_npcRefreshId, CheckInFog, CheckLock, NeedTrace, CustomMapSliderScale, needTraceOnFogArea, bNotRightPanel)
  local NpcDatas = self.data.npcDatas
  if not NpcDatas then
    Log.Error("BigMapModule:OnFindNpcByRefreshId NPC data is invalid")
    return false
  end
  for i, v in pairs(NpcDatas) do
    local Datas
    if needTraceOnFogArea then
      Datas = v
    else
      Datas = self.data:GetAllShowNpcs(i)
    end
    if Datas then
      for _, datas in pairs(Datas) do
        for _, _datas in pairs(datas) do
          for j, k in pairs(_datas) do
            if k.world_map_cfg_id then
              local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(k.world_map_cfg_id)
              if worldMapCfg and worldMapCfg.npc_refresh_ids[1] == _npcRefreshId then
                Log.Debug(k.next_npc_refresh_time, _G.ZoneServer:GetServerTime() / 1000, "BigMapModule:OnFindNpcByRefreshId")
                if k.next_npc_refresh_time and k.next_npc_refresh_time > _G.ZoneServer:GetServerTime() / 1000 then
                  return false, true
                end
              end
            end
            if k.npc_refresh_id and k.npc_refresh_id == _npcRefreshId then
              if CheckLock and k.status and k.status == _G.ProtoEnum.LockStatus.ENUM.LOCKED then
                return false
              end
              if CheckInFog and k.npc_pos and not self:CheckNpcInFogArea(k.npc_pos, i) then
                return false
              end
              if self:HasPanel("MainBigMap") then
                _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
                self:DispatchEvent(BigMapModuleEvent.SwitchSelectIconEvent, _npcRefreshId)
                return true
              end
              if NeedTrace then
                local _NeedTrace = true
                local worldMap = k.worldMapConf or {}
                if self:GetTransferBtnNum(worldMap) > 0 and k.status and k.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
                  _NeedTrace = false
                end
                local npcCfg = k.npcCfg
                if npcCfg then
                  if npcCfg.genre == Enum.ClientNpcType.CNT_ALCHEMY and k.status and k.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
                    _NeedTrace = false
                  end
                  if npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS and self:CheckNpcInFogArea(k.npc_pos, i) then
                    _NeedTrace = false
                  end
                end
                if _NeedTrace then
                  self:OnCmdTraceNpcByRefreshID(_npcRefreshId, needTraceOnFogArea)
                  self.data:SetNewCustomPointBTrack()
                end
              end
              self:TraceNpcOpenMapCenter(k.world_map_cfg_id, CustomMapSliderScale, _npcRefreshId, bNotRightPanel)
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function BigMapModule:TraceNpcOpenMapCenter(worldMapConfId, CustomMapSliderScale, FindNpcRefreshId, bNotRightPanel)
  local worldMapId = worldMapConfId
  local MapSliderScale = CustomMapSliderScale
  if worldMapId then
    local worldMapConf = _G.DataConfigManager:GetWorldMapConf(worldMapId)
    local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(worldMapConf.element_show_scale)
    MapSliderScale = scaleConf.max_scale / 100.0 + 0.005
    MapSliderScale = MapSliderScale - MapSliderScale % 0.01
  end
  self:OpenPanel("MainBigMap", {
    scaleSliderValue = MapSliderScale,
    centerNPCRefreshId = FindNpcRefreshId,
    bNotRightPanel = bNotRightPanel
  })
end

function BigMapModule:OnCmdTraceNpcByID(_npcId)
  self.data:SetCurTraceNpc(_npcId)
end

function BigMapModule:OnCmdSetMapCenterPos(posX, posY)
  self:DispatchEvent(BigMapModuleEvent.SetMapCenterPosEvent, posX, posY)
end

function BigMapModule:SetForceTraceLimit()
  local worldMapDefaultTrackData = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.WORLD_MAP_DEFAULT_TRACK):GetAllDatas()
  if worldMapDefaultTrackData then
    for k, val in pairs(worldMapDefaultTrackData) do
      local trackType = val.track_type
      if trackType then
        self.forceTraceLimit[trackType] = {
          trackNum = val.track_num,
          showNum = val.minmap_num
        }
      end
    end
  end
end

function BigMapModule:GetForceTraceLimit(trackType, extraKey)
  if trackType then
    if extraKey then
      return self.forceTraceLimit[trackType] and self.forceTraceLimit[trackType][extraKey]
    else
      return self.forceTraceLimit[trackType]
    end
  else
    return self.forceTraceLimit
  end
end

function BigMapModule:GetForceTrackLimit(trackType)
  if self.forceTraceLimit[trackType] then
    return self.forceTraceLimit[trackType].trackNum or 0
  end
  return 0
end

function BigMapModule:CheckForceTrackLimit(trackType)
  local limitNum = self.forceTraceLimit[trackType].trackNum
  local curForceTraceList = self.data:GetTraceInfoByType(BigMapModuleEnum.TraceType.ForceTrace)
  if curForceTraceList and curForceTraceList[trackType] and limitNum <= #curForceTraceList[trackType] then
    return true
  end
  return false
end

function BigMapModule:SetForceTrace(npcInfo)
  local traceInfo = {}
  traceInfo.npcInfo = npcInfo
  traceInfo.sceneResId = BigMapUtils.GetSceneResIdByPos(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
  traceInfo.traceType = BigMapModuleEnum.TraceType.ForceTrace
  if npcInfo.worldMapConf then
    traceInfo.extraType = npcInfo.worldMapConf.default_track_type
    if self:CheckForceTrackLimit(npcInfo.worldMapConf.default_track_type) then
      local cancelTraceInfo = {}
      cancelTraceInfo.traceType = BigMapModuleEnum.TraceType.ForceTrace
      cancelTraceInfo.extraType = npcInfo.worldMapConf.default_track_type
      self:OnCmdStartOrCancelTrace(false, cancelTraceInfo)
    end
  end
  self:OnCmdStartOrCancelTrace(true, traceInfo)
  if self:CheckIsTracing(BigMapModuleEnum.TraceType.NPC, npcInfo.entry_id, npcInfo.logic_id) then
    local cancelTraceInfo = {
      traceType = BigMapModuleEnum.TraceType.NPC
    }
    self:OnCmdStartOrCancelTrace(false, cancelTraceInfo)
  end
end

function BigMapModule:OnCmdStartOrCancelTrace(bTrace, traceInfo)
  if not traceInfo then
    Log.Error("BigMapModule trace info is nil")
    return
  end
  local traceType = traceInfo.traceType
  if bTrace then
    if self.data.traceInfoList[traceType] then
      if traceType ~= BigMapModuleEnum.TraceType.Visitor and traceType ~= BigMapModuleEnum.TraceType.ForceTrace then
        self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, self.data.traceInfoList[traceType])
      end
      self.data:SetTraceInfoList(traceInfo)
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, true, traceInfo)
    else
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, true, traceInfo)
      self.data:SetTraceInfoList(traceInfo)
    end
    if traceType == BigMapModuleEnum.TraceType.NPC then
      if self.data.traceInfoList[BigMapModuleEnum.TraceType.Marker] then
        local tempTraceInfo = self.data.traceInfoList[BigMapModuleEnum.TraceType.Marker]
        self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, tempTraceInfo)
        self.data.traceInfoList[BigMapModuleEnum.TraceType.Marker] = nil
        if tempTraceInfo.markInfo then
          _G.NRCModuleManager:DoCmd(BigMapModuleCmd.MapMarkOperate, tempTraceInfo.markInfo.mark_id, 4, tempTraceInfo.markInfo, nil, nil, tempTraceInfo.markInfo.is_track)
        end
      end
    elseif traceType == BigMapModuleEnum.TraceType.Marker and self.data.traceInfoList[BigMapModuleEnum.TraceType.NPC] then
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, self.data.traceInfoList[BigMapModuleEnum.TraceType.NPC])
      self.data.traceInfoList[BigMapModuleEnum.TraceType.NPC] = nil
    end
  elseif self.data.traceInfoList[traceType] then
    if traceType == BigMapModuleEnum.TraceType.Visitor then
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, traceInfo)
      local visitTraceInfo = self.data.traceInfoList[traceType]
      local RemoveIndex = 0
      for i, v in pairs(visitTraceInfo) do
        if v.visitorInfo.uin == traceInfo.visitorInfo.uin then
          RemoveIndex = i
        end
      end
      table.removeKey(self.data.traceInfoList[traceType], RemoveIndex)
    elseif traceType == BigMapModuleEnum.TraceType.TempTrace then
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, traceInfo)
      table.removeKey(self.data.traceInfoList[traceType], traceInfo.npcInfo.logic_id)
      if table.isEmpty(self.data.traceInfoList[traceType]) then
        table.removeKey(self.data.traceInfoList, traceType)
      end
    elseif traceType == BigMapModuleEnum.TraceType.ForceTrace then
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, traceInfo)
      if traceInfo.npcInfo and traceInfo.npcInfo.logic_id then
        local trackType = traceInfo.extraType
        if self.data.traceInfoList[traceType] then
          local traceList = {}
          if trackType then
            traceList = self.data.traceInfoList[traceType][trackType]
            if traceList and #traceList > 0 then
              for k, npcInfo in ipairs(traceList) do
                if npcInfo.logic_id == traceInfo.npcInfo.logic_id then
                  table.remove(traceList, k)
                  break
                end
              end
            end
          else
            for _trackType, _traceList in pairs(self.data.traceInfoList[traceType]) do
              if _traceList and #_traceList > 0 then
                for key, _traceInfo in ipairs(_traceList) do
                  if _traceInfo.npcInfo.logic_id == traceInfo.npcInfo.logic_id then
                    table.remove(_traceList, key)
                    break
                  end
                end
              end
            end
          end
        end
      elseif self.data.traceInfoList[traceType] then
        local trackType = traceInfo.extraType or 0
        local traceList = self.data.traceInfoList[traceType][trackType]
        if traceList and #traceList > 0 then
          table.remove(traceList, 1)
          if table.isEmpty(traceList) then
            table.removeKey(self.data.traceInfoList[traceType], trackType)
          end
        end
      end
    else
      self:DispatchEvent(BigMapModuleEvent.StartOrCancelTraceEvent, false, self.data.traceInfoList[traceType])
      self.data.traceInfoList[traceType] = nil
    end
  end
end

function BigMapModule:OnCmdStartOrCancelTempTrace(curTraceList)
  local moduleTraceList = self.data:GetTraceInfoByType(BigMapModuleEnum.TraceType.TempTrace)
  if curTraceList then
    for key, _traceInfo in pairs(curTraceList) do
      local logicId = _traceInfo.npcInfo.logic_id
      if logicId and (nil == moduleTraceList or nil == moduleTraceList[logicId]) then
        self:OnCmdStartOrCancelTrace(true, _traceInfo)
      end
    end
    if moduleTraceList then
      for logicId, traceInfo in pairs(moduleTraceList) do
        local needRemove = true
        if curTraceList then
          for key, _traceInfo in pairs(curTraceList) do
            local _logicId = _traceInfo.npcInfo.logic_id
            if _logicId == logicId then
              needRemove = false
            end
          end
        end
        if true == needRemove then
          self:OnCmdStartOrCancelTrace(false, traceInfo)
        end
      end
    end
  end
end

function BigMapModule:OnCmdGetAreaFuncIdByAreaId(areaId)
  if self.data.AreaIdToAreaFuncId[areaId] then
    return self.data.AreaIdToAreaFuncId[areaId]
  end
  return 0
end

function BigMapModule:OnCmdGetLayerInfoByAreaFuncId(areaFuncId)
  if self.data.AreaFuncIdToLayerInfo[areaFuncId] then
    return self.data.AreaFuncIdToLayerInfo[areaFuncId]
  end
  return nil
end

function BigMapModule:GetCurShowLayerId()
  return self.data.curShowLayerId
end

function BigMapModule:GetWorldMapActivityConfByAreaFuncId(areaFuncId)
  return self.data.areaFuncIdToMapActivityConf[areaFuncId]
end

function BigMapModule:OnCmdAddMapActivityIconByWorldMapConf(_groupID, _WorldMapConf, _taskID, _worldMapActivityConf)
end

function BigMapModule:OnCmdRemoveMapActivityIconByWorldMapConf(_groupID, _taskID)
end

function BigMapModule:OnCmdBehaviorOpenWorldMap(_npcInfo)
  self:OnCmdOpenWorldMap(_npcInfo)
end

function BigMapModule:WorldMapInfoChanged(notify)
  if notify.unlocked_world_map_block_cfg_id then
    self.data:AddUnlockMapBlockId(notify.unlocked_world_map_block_cfg_id)
  end
  if notify.changed_layered_explore_info then
    local exploreInfo = notify.changed_layered_explore_info
    local exploreType = self.data.npcIdToExploreInfo[exploreInfo.npc_id]
    if exploreType then
      self:UpdateExploredInfo(exploreType, exploreInfo)
    end
  end
  if notify.changed_entries and notify.changed_entries.entry_infos then
    self:UpdateMapEntries(notify.changed_entries.entry_infos)
    for i = 1, #notify.changed_entries.entry_infos do
      local entryInfos = notify.changed_entries.entry_infos[i]
      if entryInfos.npc_entry_info and entryInfos.npc_entry_info.world_map_cfg_id and entryInfos.npc_entry_info.world_map_npc_infos and #entryInfos.npc_entry_info.world_map_npc_infos > 0 then
        local worldMapConf = _G.DataConfigManager:GetWorldMapConf(entryInfos.npc_entry_info.world_map_cfg_id)
        if worldMapConf and #worldMapConf.unlock_zone > 0 and (entryInfos.npc_entry_info.world_map_npc_infos[1].status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or entryInfos.npc_entry_info.world_map_npc_infos[1].status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH) then
          local mapnpcInfo = {
            npcRefreshId = entryInfos.npc_entry_info.world_map_npc_infos[1].npc_refresh_id
          }
          Log.Debug(entryInfos.npc_entry_info.world_map_npc_infos[1].npc_refresh_id, "BigMapModule:WorldMapInfoChangedAddChanged_entries")
          self.data:AddChanged_entries(mapnpcInfo)
          self.data:DrawMaskTexture(SceneUtils.GetSceneResId())
        end
      end
      local npcInfo = entryInfos.npc_entry_info
      if nil == npcInfo or npcInfo.world_map_npc_infos and 0 == #npcInfo.world_map_npc_infos or npcInfo.world_map_npc_infos == nil and (not npcInfo.next_npc_refresh_time or 0 == npcInfo.next_npc_refresh_time) then
        _G.DataModelMgr.PlayerDataModel:UpdateWorldMapActorInfo(entryInfos, true)
      else
        _G.DataModelMgr.PlayerDataModel:UpdateWorldMapActorInfo(entryInfos, false)
      end
    end
  end
  if notify.delete_entry_ids then
    self.data:DeleteNpcInfo(notify.delete_entry_ids)
  end
  local npcDatas = self.data:GetNpcDatas()
  local mapAreaDatas = self.data:GetMapAreaDatas()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
  if self:HasPanel("MainBigMap") then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:UpdateRandomShopHint()
    end
  end
  if notify.del_auto_track_npc_logic_id then
    self.data:OnAutoTrackNpcListChanged(false, notify.del_auto_track_npc_logic_id)
  end
end

function BigMapModule:MagicCreateNpcInfoChanged(notify)
  if notify.add_or_delete == true then
    _G.DataModelMgr.PlayerDataModel:UpdateMagicCreateNpcInfo(notify.npc_info, false)
    self.data:UpdateMagicCreateNpcInfo(notify.npc_info)
    local npcDatas = self.data:GetNpcDatas(self.data.curShowSceneResId)
    NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas)
  elseif notify.npc_info.npc_obj_id then
    _G.DataModelMgr.PlayerDataModel:UpdateMagicCreateNpcInfo(notify.npc_info, true)
    self.data:UpdateNpcInfo(notify.npc_info.npc_obj_id, notify.npc_info)
    local npcDatas = self.data:GetNpcDatas(self.data.curShowSceneResId)
    NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas)
  end
  if self:HasPanel("MainBigMap") then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:UpdateHint()
    end
  end
end

function BigMapModule:OnCmdBonfireFinishNotify()
  local bInDungeon = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.IsInDungeon)
  if not bInDungeon then
    self:OnCmdOpenWorldMap()
  end
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if mainUIModule then
    mainUIModule:DispatchEvent(MainUIModuleEvent.UpdateMinimapShow)
  end
end

function BigMapModule:OnDebugCatchPetToggle()
  self.debugCatchPetToggle = not self.debugCatchPetToggle
end

function BigMapModule:CmdOpenNourishBigMapTips(arg)
  if self:HasPanel("NourishBigMapTips") then
    local panel = self:GetPanel("NourishBigMapTips")
    panel:UpdateData(arg)
  else
    self:OpenPanel("NourishBigMapTips", arg)
  end
end

function BigMapModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, touchCount, closeGCWeight, enablePcEsc, autoSetDesiredCursor)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/BigMap/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  if closeGCWeight then
    registerData.closeGCWeight = closeGCWeight
  end
  registerData.touchCount = touchCount
  registerData.enablePcEsc = enablePcEsc or false
  registerData.autoSetDesiredCursor = autoSetDesiredCursor
  self:RegisterPanel(registerData)
end

function BigMapModule:RegTravelPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Travel/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  self:RegisterPanel(registerData)
end

function BigMapModule:OnPlayerTeleportStart()
  self:Log("OnPlayerTeleportStart")
  self:OnCmdCloseWorldMap()
end

function BigMapModule:AfterEnterScene()
  self.data.bReceivedSyncBeginRsp = false
  table.clear(self.data.UnlockDeadwoodList)
  self:SyncWorldMapInfo()
  self.data:DrawMaskTexture(self:GetShowMapBySceneResId(SceneUtils.GetSceneResId()))
  self.lastSceneResId = SceneUtils.GetSceneResId()
end

function BigMapModule:AppEnteredForeground()
  if self.data.bReceivedSyncBeginRsp then
    self:AfterEnterScene()
  end
end

function BigMapModule:IsFullPath(path)
  local param = string.split(path, "/")
  if #param > 1 then
    return true
  end
  return false
end

function BigMapModule:GetCompassIconRes(IconName)
  return string.format("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/CompassIcon/Frames/%s'", IconName)
end

function BigMapModule:GetBigMapIconRes(IconName)
  if BigMapUtils.IsFullPath(IconName) then
    return IconName
  else
    return string.format("PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/WorldMapNpc/Frames/%s'", IconName)
  end
end

function BigMapModule:GetMainUIStaticIconRes(IconName)
  return string.format("PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/%s'", IconName)
end

function BigMapModule:HideMask(bHide)
  if self:HasPanel("MainBigMap") then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:HideMask(bHide)
    end
  end
end

function BigMapModule:InvalidDisabledMapRedPoint()
  local realShowMapList = {}
  if #self.data.MapShowList > 0 then
    local showList = {}
    for k, v in pairs(self.data.MapShowList) do
      if v.sceneResId == SceneUtils.GetSceneResId() then
        showList = v.Conf.map_same_group
        break
      end
    end
    if showList and #showList > 0 then
      for k, v in ipairs(showList) do
        for key, listData in pairs(self.data.MapShowList) do
          if listData.Conf.id == v then
            table.insert(realShowMapList, listData)
          end
        end
      end
    end
  end
  local redDotData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_WORLD_MAP_NEW)
  local module = _G.NRCModuleManager:GetModule("CommonPopUpModule")
  if module.HiddenRedPointList then
    for i, OldHiddenRedPoint in ipairs(module.HiddenRedPointList) do
      _G.NRCModeManager:DoCmd(RedPointModuleCmd.RecoverPointData, 243, {OldHiddenRedPoint})
    end
  else
    module.HiddenRedPointList = {}
  end
  local curHiddenRedPointList = {}
  if redDotData then
    local keys = {}
    for i in pairs(redDotData) do
      table.insert(keys, i)
    end
    table.sort(keys, function(a, b)
      return b < a
    end)
    for _, l in ipairs(keys) do
      local find = false
      for k, v in pairs(realShowMapList) do
        if tonumber(redDotData[l]) == v.mapRedDotExtraKey then
          find = true
          break
        end
      end
      if not find then
        table.insert(curHiddenRedPointList, tonumber(redDotData[l]))
      end
    end
  end
  if #module.HiddenRedPointList > 0 then
    for i, NewHiddenRedPoint in ipairs(curHiddenRedPointList) do
      _G.NRCModeManager:DoCmd(RedPointModuleCmd.InvalidPointData, 243, {NewHiddenRedPoint})
    end
    for i, OldHiddenRedPoint in ipairs(module.HiddenRedPointList) do
      local find = false
      for _, NewHiddenRedPoint in ipairs(curHiddenRedPointList) do
        if OldHiddenRedPoint == NewHiddenRedPoint then
          find = true
          break
        end
      end
      if not find then
        _G.NRCModeManager:DoCmd(RedPointModuleCmd.RecoverPointData, 243, {OldHiddenRedPoint})
      end
    end
  else
    for _, NewHiddenRedPoint in ipairs(curHiddenRedPointList) do
      _G.NRCModeManager:DoCmd(RedPointModuleCmd.InvalidPointData, 243, {NewHiddenRedPoint})
    end
  end
  module.HiddenRedPointList = curHiddenRedPointList
end

function BigMapModule:OnCmdOpenMapMagicPanel(info, worldMapCfg)
  local value = self.data:GetCampFruitNpcInfoByCampcontentId(info.npc_refresh_id)
  _G.NRCModeManager:DoCmd(BigMapModuleCmd.OpenMapRightPanel, 0, info, worldMapCfg)
  self:DispatchEvent(BigMapModuleEvent.UpdateCampFruitInfo, value)
end

function BigMapModule:UpdateExploredInfo(type, exploredInfo)
  local campId = exploredInfo.belong_camp
  local cfgId = exploredInfo.npc_id
  if campId and campId > 0 then
    if self.data.worldExploredInfo[campId] == nil then
      self.data.worldExploredInfo[campId] = {}
    end
    if self.data.worldExploredInfo[campId][type] == nil then
      self.data.worldExploredInfo[campId][type] = {}
    end
    self.data.worldExploredInfo[campId][type][cfgId] = exploredInfo
  end
end

function BigMapModule:CalcPetExploredInfo(campRefreshId)
  local x, y = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetPetGatherRate, campRefreshId)
  self:UpdateExploredInfo(Enum.WorldExploringStatisticType.WEST_ELF_TRACE, {
    npc_id = 0,
    belong_camp = campRefreshId,
    explore_num = x,
    total_num = y
  })
end

function BigMapModule:CalcNpcChallengeInfo(campRefreshId)
  local finishNum = 0
  local totalNum = 0
  local challengeInfo = self.data.worldExploredInfo[campRefreshId][Enum.WorldExploringStatisticType.WEST_CHALLENGER]
  if challengeInfo then
    for k, val in pairs(challengeInfo) do
      local status = self.data.campChallengeNpcInfo[val.npc_id]
      if status == ProtoEnum.LockStatus.ENUM.LOCKED then
        finishNum = finishNum + 1
      end
      totalNum = totalNum + 1
    end
  end
  self:UpdateExploredInfo(Enum.WorldExploringStatisticType.WEST_CHALLENGER, {
    npc_id = -1,
    belong_camp = campRefreshId,
    explore_num = finishNum,
    total_num = totalNum
  })
end

function BigMapModule:CheckNpcChallengeStatus(npcCfgId)
  local npcStatus = ProtoEnum.LockStatus.ENUM.NONE
  if self.data.campChallengeNpcInfo[npcCfgId] then
    npcStatus = self.data.campChallengeNpcInfo[npcCfgId]
  end
  return npcStatus
end

function BigMapModule:GetExploredInfo(campId, type)
  if self.data.worldExploredInfo == nil then
    return
  end
  local exploreInfo = {}
  if type then
    if self.data.worldExploredInfo[campId] then
      if type ~= Enum.WorldExploringStatisticType.WEST_CHALLENGER then
        local exploreList = self.data.worldExploredInfo[campId][type]
        local totalNum = 0
        local exploreNum = 0
        local npcId = 0
        if exploreList then
          for k, v in pairs(exploreList) do
            totalNum = totalNum + v.total_num
            exploreNum = exploreNum + v.explore_num
            npcId = v.npc_id
          end
        end
        exploreInfo = {
          npc_id = npcId,
          belong_camp = campId,
          explore_num = exploreNum,
          total_num = totalNum
        }
      else
        exploreInfo = self.data.worldExploredInfo[campId][type]
      end
    end
  else
    exploreInfo = self.data.worldExploredInfo[campId]
  end
  return exploreInfo
end

function BigMapModule:OnCmdCloseTravelMainMap()
  if self.CacheAction then
    self.CacheAction:EndAction()
    self.CacheAction = nil
  end
  self.IsTraceOpen = false
end

function BigMapModule:OnCmdUpdateTravelInfos(travelInfos)
  self:DispatchEvent(BigMapModuleEvent.OnUpdateTravelInfos, travelInfos)
end

function BigMapModule:OnCmdSetIsTravel(isTravel)
  self.data.isOpenTravel = isTravel
  self:DispatchEvent(BigMapModuleEvent.ChangeIsTravel, isTravel)
end

function BigMapModule:OnCmdOpenTravelMainMap(action, IsTraceOpen)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, true)
  if isBan then
    return
  end
  isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FT_MAP_PET_TRAVEL, true)
  if isBan then
    return
  end
  self.data.isOpenTravel = true
  local req = _G.ProtoMessage:newZoneGetPetTravelInfoReq()
  self.CacheAction = action
  self.IsTraceOpen = IsTraceOpen
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PET_TRAVEL_INFO_REQ, req, self, self.OnZoneGetPetTravelInfoRsp)
end

function BigMapModule:OnZoneGetPetTravelInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local travelData = _G.NRCModuleManager:GetModule("TravelModule").data
    travelData:SetTravelInfo(rsp.travel_info)
    local isOpening, _ = self:HasPanel("MainBigMap")
    if isOpening then
      local mainMap = self:GetPanel("MainBigMap")
      if mainMap then
        self:EnablePanel("MainBigMap")
      end
    else
      _G.NRCProfilerLog:NRCPanelProfilerLog(true, true, "MainBigMap")
      self:OpenPanel("MainBigMap")
      self.data:GetAreaCollectionRate()
    end
  end
end

function BigMapModule:OnCmdIsTravelMap()
  return self.data:IsOpenTravel()
end

function BigMapModule:OnCmdOpenCollectTips(areaId)
  self:OpenPanel("CollectTips", areaId)
end

function BigMapModule:OnCmdOpenMapLayerTip(bOpen, layerMapInfo)
  if bOpen then
    local isOpening, _ = self:HasPanel("MapLayerTip")
    if not isOpening then
      self:OpenPanel("MapLayerTip", layerMapInfo)
    else
      local panel = self:GetPanel("MapLayerTip")
      self:EnablePanel("MapLayerTip")
      panel:UpdatePanel(layerMapInfo)
    end
  else
    local isOpening, _ = self:HasPanel("MapLayerTip")
    if isOpening then
      self:DisablePanel("MapLayerTip")
    end
  end
end

function BigMapModule:OnCmdOpenTravelPanel(info, downTime, isMax)
  self:OpenPanel("TravelPanel", info, downTime, isMax)
end

function BigMapModule:OnCloseOwlSanctuaryNpcListPanel()
  if self:HasPanel("SanctuaryTips") then
    self:ClosePanel("SanctuaryTips")
  end
end

function BigMapModule:OnCmdToggleOwlSanctuaryNpcListPanel(arg)
  if arg then
    if self:HasPanel("SanctuaryTips") then
      local panel = self:GetPanel("SanctuaryTips")
      panel:OnTooglePanel()
    else
      self:OpenPanel("SanctuaryTips", arg)
    end
  elseif self:HasPanel("SanctuaryTips") then
    local panel = self:GetPanel("SanctuaryTips")
    panel:OnTooglePanel()
  end
end

function BigMapModule:OnCmdGetSantuaryListState(name)
  return self.data:GetSantuaryState(name)
end

function BigMapModule:OnCmdSetSantuaryListState(name, state)
  self.data:SetSantuaryState(name, state)
end

function BigMapModule:OnCmdGetSantuaryListOffset()
  return self.data:LoadSantuaryListOpenOffset()
end

function BigMapModule:OnCmdSetSantuaryListOffset(offset)
  self.data:SaveSantuaryListOpenOffset(offset)
end

function BigMapModule:OnCmdGetPetItemData(baseId)
  return self.data:GetPetItemData(baseId)
end

function BigMapModule:SwitchSelect(npcId)
  if self.data.sanctuaryChildItemDic[npcId] then
    self.data.sanctuaryChildItemDic[npcId]:OnSelectAnim()
  end
  if self.lastSelectId ~= nil and self.lastSelectId ~= npcId and self.data.sanctuaryChildItemDic[self.lastSelectId] then
    self.data.sanctuaryChildItemDic[self.lastSelectId]:OnUnselectAnim()
  end
  self.lastSelectId = npcId
end

function BigMapModule:OnCmdSwitchSelectItem(npcId, bSanctuary)
  if self:HasPanel("MainBigMap") then
    self:SwitchSelect(npcId)
    self:DispatchEvent(BigMapModuleEvent.SwitchSelectIconEvent, npcId, bSanctuary)
  end
end

function BigMapModule:OnCmdSwitchSelectIcon(npcId, isOffset)
  if self:HasPanel("MainBigMap") then
    if isOffset then
      self:DispatchEvent(BigMapModuleEvent.SwitchSelectIconOffsetEvent, npcId)
    end
    self:SwitchSelect(npcId)
  end
end

function BigMapModule:OnCmdLeaveOwlSanctuaryRigthPanel()
  if self.lastSelectId and self.data.sanctuaryChildItemDic[self.lastSelectId] then
    self.data.sanctuaryChildItemDic[self.lastSelectId]:OnUnselectAnim()
    self.lastSelectId = nil
  else
    for i, item in pairs(self.data.sanctuaryChildItemDic) do
      if item.isSelect then
        item:OnUnselectAnim()
      end
    end
  end
end

function BigMapModule:OnCmdGetFruitFristPetBaseId(fruit_id)
  return self.data:GetFruitFristPetBaseId(fruit_id)
end

function BigMapModule:OnSelectLastItem()
  if self.lastSelectId and self.data.sanctuaryChildItemDic[self.lastSelectId] then
    self.data.sanctuaryChildItemDic[self.lastSelectId]:OnSelectAnim()
  end
end

function BigMapModule:OnCmdRegisterSanctuaryChildItem(id, umg)
  self.data:RegisterSanctuaryChildItem(id, umg)
end

function BigMapModule:OnCmdUnRegisterSanctuaryChildItem(id, umg)
  self.data:UnRegisterSanctuaryChildItem(id)
end

function BigMapModule:OnCmdGetAllOwlSanctuaryConfs()
  return self.data:GetAllOwlSanctuaryConfs()
end

function BigMapModule:OnCmdSetSliderVisible()
  local isOpening, _ = self:HasPanel("MainBigMap")
  if isOpening then
    local mainMap = self:GetPanel("MainBigMap")
    if mainMap then
      mainMap:OnSetSliderVisible(true)
    end
  end
end

function BigMapModule:OnCmdGetNpcInfoByConfigId(configId)
  return self.data:GetNpcInfoByConfigId(configId)
end

function BigMapModule:OnCmdGetNpcInfoByRefreshId(RefreshId)
  return self.data:GetNpcInfoByRefreshId(RefreshId)
end

function BigMapModule:OnCmdMarkerTypeSelect(Data)
  self.data:SetSelectMarkerType(Data)
  self:DispatchEvent(BigMapModuleEvent.MarkerTypeSelectEvent, Data)
end

function BigMapModule:OnCmdMarkerSelect(_data)
  self:DispatchEvent(BigMapModuleEvent.MarkerSelectEvent, _data)
end

function BigMapModule:OnCmdGetSelectMarkerType()
  return self.data:GetSelectMarkerType()
end

function BigMapModule:OnCmdGetNewCustomPointNumByMapCfgId(MapCfgId)
  return self.data:GetNewCustomPointNumByMapCfgId(MapCfgId)
end

function BigMapModule:OnCmdMapMarkOperate(mark_id, Type, SelectMarker, name, _pos, is_track)
  self.Op_Type = Type
  self.mark_id = mark_id
  self.is_track = is_track
  local posLayerId = 0
  local req = _G.ProtoMessage:newZoneMapMarkOperateReq()
  if Type == _G.ProtoEnum.MapMarkOpType.MMOT_ADD_MARK then
    req.world_map_cfg_id = SelectMarker.id
    req.name = name
    req.pos = _pos
    if SelectMarker.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_NORMAL_POINT then
      req.type = ProtoEnum.WorldMapMarkType.ENUM.NormalMark
    elseif SelectMarker.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_PET_POINT then
      req.type = ProtoEnum.WorldMapMarkType.ENUM.PetMark
    end
    posLayerId = BigMapUtils.GetLayerIdByPos(_pos.x, _pos.y, self.data.curShowSceneResId)
  elseif Type == _G.ProtoEnum.MapMarkOpType.MMOT_REMOVE_MARK then
    req.mark_id = mark_id
    local traceMarkInfo = self.data:GetTraceInfoByType(BigMapModuleEnum.TraceType.Marker)
    if traceMarkInfo and traceMarkInfo.markInfo and traceMarkInfo.markInfo.mark_id == mark_id then
      local traceInfo = {}
      traceInfo.traceType = BigMapModuleEnum.TraceType.Marker
      posLayerId = BigMapUtils.GetLayerIdByPos(traceMarkInfo.markInfo.pos.x, traceMarkInfo.markInfo.pos.y, self.data.curShowSceneResId)
      self:OnCmdStartOrCancelTrace(false, traceInfo)
    end
  elseif Type == _G.ProtoEnum.MapMarkOpType.MMOT_MODIFY_MARK then
    req.world_map_cfg_id = SelectMarker.id
    req.name = name
    req.pos = _pos
    if SelectMarker.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_NORMAL_POINT then
      req.type = ProtoEnum.WorldMapMarkType.ENUM.NormalMark
    elseif SelectMarker.map_show_type == Enum.MapIconShowType.MAP_CUSTOMIZED_PET_POINT then
      req.type = ProtoEnum.WorldMapMarkType.ENUM.PetMark
    end
    req.mark_id = mark_id
    posLayerId = BigMapUtils.GetLayerIdByPos(_pos.x, _pos.y, self.data.curShowSceneResId)
  else
    self.data:SetNewCustomPointTrackByMarkId(self.mark_id, self.is_track)
    local traceInfo = {}
    traceInfo.traceType = BigMapModuleEnum.TraceType.Marker
    traceInfo.markInfo = SelectMarker
    local sceneResId = BigMapUtils.GetSceneResIdByPos(SelectMarker.pos.x, SelectMarker.pos.y)
    local posX, posY = BigMapUtils.ScenePosToImagePos(sceneResId, SelectMarker.pos.x, SelectMarker.pos.y)
    traceInfo.iconImagePos = {x = posX, y = posY}
    traceInfo.sceneResId = sceneResId
    if false == is_track then
      self.data:SetCurTraceNpc(-1)
    end
    self:OnCmdStartOrCancelTrace(not is_track, traceInfo)
    return
  end
  req.op_type = Type
  req.scene_id = BigMapUtils.GetSceneIdBySceneResId(self.data.curShowSceneResId)
  req.layer_id = self:CheckMarkerMapLayerId(self.data.curShowLayerId, posLayerId)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAP_MARK_OPERATE_REQ, req, self, self.MapMarkOperateChange, false, false)
end

function BigMapModule:CheckMarkerMapLayerId(curShowLayerId, posLayerId)
  local markLayerId = 0
  if curShowLayerId > 0 then
    if posLayerId > 0 then
      markLayerId = curShowLayerId
    else
      markLayerId = 0
    end
  else
    markLayerId = 0
  end
  return markLayerId
end

function BigMapModule:MapMarkOperateChange(_rsp)
  if 0 ~= _rsp.ret_info.ret_code then
    Log.Error("BigMapModule:MapMarkOperateChange", _rsp.ret_info.ret_code)
    self:ShowErrorText(_rsp.ret_info.ret_code)
    if _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_NOT_FOUND then
      local localMarkerInfo = self.data:GetNewCustomPointById(self.mark_id)
      if localMarkerInfo then
        local removeMarkerInfo = {}
        removeMarkerInfo.mark_id = self.mark_id
        removeMarkerInfo.type = localMarkerInfo.type
        self:DispatchEvent(BigMapModuleEvent.MapMarkOperateChangeEvent, removeMarkerInfo, ProtoEnum.MapMarkOpType.MMOT_REMOVE_MARK)
        self.data:RemoveNewCustomPointByMarkId(self.mark_id)
      end
    end
    self:DispatchEvent(BigMapModuleEvent.SetLockBtn, false)
    return
  end
  if self.Op_Type == _G.ProtoEnum.MapMarkOpType.MMOT_ADD_MARK or self.Op_Type == _G.ProtoEnum.MapMarkOpType.MMOT_MODIFY_MARK then
    self.data:SetNewCustomPointInfo(_rsp.mark_entry)
    _G.DataModelMgr.PlayerDataModel:UpdateWorldMapMarkEntryInfo(_rsp.mark_entry, false)
    if self.Op_Type == _G.ProtoEnum.MapMarkOpType.MMOT_MODIFY_MARK then
      local markerEntry = _rsp.mark_entry
      if markerEntry and markerEntry.is_track then
        local traceInfo = {}
        traceInfo.traceType = BigMapModuleEnum.TraceType.Marker
        traceInfo.markInfo = markerEntry
        local sceneResId = BigMapUtils.GetSceneResIdByPos(markerEntry.pos.x, markerEntry.pos.y)
        local posX, posY = BigMapUtils.ScenePosToImagePos(sceneResId, markerEntry.pos.x, markerEntry.pos.y)
        traceInfo.iconImagePos = {x = posX, y = posY}
        traceInfo.sceneResId = sceneResId
        self:OnCmdStartOrCancelTrace(true, traceInfo)
      end
    end
  elseif self.Op_Type == _G.ProtoEnum.MapMarkOpType.MMOT_REMOVE_MARK then
    self.data:RemoveNewCustomPointByMarkId(self.mark_id)
  end
  local markerEntry = _rsp.mark_entry
  local markerInfo = {}
  if markerEntry then
    markerInfo.mark_id = markerEntry.mark_id
    markerInfo.type = markerEntry.type
    if _rsp.op_type ~= ProtoEnum.MapMarkOpType.MMOT_REMOVE_MARK then
      markerInfo.name = markerEntry.name
      markerInfo.world_map_cfg_id = markerEntry.world_map_cfg_id
      markerInfo.pos = markerEntry.pos
    end
    markerInfo.layer_id = _rsp.mark_entry.layer_id
  end
  self:DispatchEvent(BigMapModuleEvent.MapMarkOperateChangeEvent, markerInfo, _rsp.op_type)
end

function BigMapModule:GetCustomPos_Z(_pos)
  local WorldLocation = UE4.FVector()
  WorldLocation.x = _pos.x
  WorldLocation.y = _pos.y
  WorldLocation.z = 100000
  local endPos = UE4.FVector()
  endPos.x = _pos.x
  endPos.y = _pos.y
  endPos.z = -100000
  local OutHit, Res = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), WorldLocation, endPos, UE.ETraceTypeQuery.Visibility, false, nil, 0, nil, true)
  if OutHit then
    return math.ceil(OutHit.Location.Z)
  else
    Log.Error("\232\135\170\229\174\154\228\185\137\230\160\135\231\130\185\231\154\132\229\176\132\231\186\191\230\178\161\230\156\137\230\163\128\230\181\139\229\136\176\229\175\185\232\177\161,\232\175\183\230\163\128\230\159\165\230\149\176\230\141\174")
  end
end

function BigMapModule:ShowErrorText(ret_code)
  if ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_STR_TOO_LONG then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\160\135\232\174\176\229\144\141\231\167\176\229\164\170\233\149\191\228\186\134")
  elseif ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_LIMITED then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\229\189\147\229\137\141\230\160\135\232\174\176\230\149\176\233\135\143\229\183\178\232\190\190\228\184\138\233\153\144")
  elseif ret_code == ProtoEnum.MOBA_RET.TssJudgeErr.ERR_JUDGE_MSG_EVIL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Map_Mark_Illegal_word)
  elseif ret_code == ProtoEnum.MOBA_RET.TssJudgeErr.ERR_JUDGE_MSG_DIRTY then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Map_Mark_Illegal_word)
  end
end

function BigMapModule:OnCmdUpdateOwlSanctuaryNpcData(entry)
  if self.data and entry then
    self.data:UpdateOwlSanctuaryNpcData(entry)
    local npcDatas = self.data:GetNpcDatas()
    local mapAreaDatas = self.data:GetMapAreaDatas()
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
  end
end

function BigMapModule:OnCmdUpdateHomeNpcInfo(entry, reason)
  if self.data then
    self.data:UpdateHomePetInfo(entry, reason)
    local npcDatas = self.data:GetNpcDatas()
    local mapAreaDatas = self.data:GetMapAreaDatas()
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
  end
end

function BigMapModule:OnCmdUpdateOwlStarInfo(owlStarInfo)
  Log.Info("BigMapModule:OnCmdUpdateOwlStarInfo ", owlStarInfo.npc_obj_id, owlStarInfo.npc_cfg_id)
  self.data:UpdateOwlStarData(owlStarInfo)
  local npcDatas = self.data:GetNpcDatas()
  local mapAreaDatas = self.data:GetMapAreaDatas()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
end

function BigMapModule:OnCmdAddOwlStarInfo(owlStarInfo)
  Log.Info("BigMapModule:OnCmdAddOwlStarBornPointInfo ", owlStarInfo.npc_obj_id, owlStarInfo.npc_cfg_id)
  self.data:UpdateOwlStarData(owlStarInfo)
  local npcDatas = self.data:GetNpcDatas()
  local mapAreaDatas = self.data:GetMapAreaDatas()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
end

function BigMapModule:OnCmdRemoveOwlStarInfo(npc_obj_id, npc_cfg_id)
  Log.Info("BigMapModule:OnCmdRemoveOwlStarBornPointInfo ", npc_obj_id, npc_cfg_id)
  local npcCfg = _G.DataConfigManager:GetNpcConf(npc_cfg_id)
  local world_map_cfg_id = 0
  if npcCfg then
    world_map_cfg_id = npcCfg.min_map_disappear
  end
  local t = {world_map_cfg_id = world_map_cfg_id}
  self.data:UpdateNpcInfo(npc_obj_id, t)
  local npcDatas = self.data:GetNpcDatas()
  local mapAreaDatas = self.data:GetMapAreaDatas()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapNpcInfo, npcDatas, mapAreaDatas)
end

function BigMapModule:OnCmdSendZoneHomeQueryFriendHomeInfoReq(npcInfo, playerUin)
  if not playerUin then
    Log.Warning("igMapModule:OnCmdSendZoneHomeQueryFriendHomeInfoReq invalid uin", playerUin)
    return
  end
  self.HomeNPCInfo = npcInfo
  local req = _G.ProtoMessage:newZoneHomeQueryFriendHomeInfoReq()
  req.uin = playerUin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_QUERY_FRIEND_HOME_INFO_REQ, req, self, self.OnZoneHomeQueryFriendHomeInfoRsp, true, true)
end

function BigMapModule:OnZoneHomeQueryFriendHomeInfoRsp(rsp)
  local panel = self:GetPanel("MainBigMap")
  if self.HomeNPCInfo and panel then
    panel:OnShowNormalNpcEventHome(self.HomeNPCInfo, rsp)
  else
    Log.Warning("BigMapModule:OnZoneHomeQueryFriendHomeInfoRsp miss context", self.HomeNPCInfo, panel)
  end
  if 0 ~= rsp.ret_info.ret_code then
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function BigMapModule:OnCmdSendZoneHomeQueryFriendHomeInfoReq_Plant(npcInfo, playerUin)
  if not playerUin then
    Log.Warning("igMapModule:OnCmdSendZoneHomeQueryFriendHomeInfoReq invalid uin", playerUin)
    return
  end
  self.PlantNPCInfo = npcInfo
  local req = _G.ProtoMessage:newZoneHomeQueryFriendHomeInfoReq()
  req.uin = playerUin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_QUERY_FRIEND_HOME_INFO_REQ, req, self, self.OnZoneHomeQueryFriendHomeInfoRsp_Plant, true, true)
end

function BigMapModule:OnZoneHomeQueryFriendHomeInfoRsp_Plant(rsp)
  local panel = self:GetPanel("MainBigMap")
  if self.PlantNPCInfo and panel then
    panel:OnShowNormalNpcEventPlant(self.PlantNPCInfo, rsp)
  else
    Log.Warning("BigMapModule:OnZoneHomeQueryFriendHomeInfoRsp miss context", self.PlantNPCInfo, panel)
  end
  if 0 ~= rsp.ret_info.ret_code then
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function BigMapModule:OnCmdZoneSceneWorldMapSyncAutoTrackNpcReq(logicId)
  local req = _G.ProtoMessage:newZoneSceneWorldMapSyncAutoTrackNpcReq()
  req.npc_logic_id = logicId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_SYNC_AUTO_TRACK_NPC_REQ, req, self, self.OnZoneSceneWorldMapSyncAutoTrackNpcRsp, false, true)
end

function BigMapModule:OnZoneSceneWorldMapSyncAutoTrackNpcRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.auto_track_npc_info.npc_logic_id then
    self.data:OnAutoTrackNpcListChanged(true, rsp.auto_track_npc_info)
  end
end

function BigMapModule:GetMinimapShowNpc()
  return self.data.miniMapShowNpc
end

function BigMapModule:GetMinimapShowAreaNpc()
  return self.data.miniMapShowAreaNpc
end

function BigMapModule:IsShowCatchPet(npcRefreshId)
  if nil == npcRefreshId or 0 == npcRefreshId then
    return false
  end
  local conf = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshId)
  if conf and conf.refresh_type then
    return conf.refresh_type == Enum.RefreshType.RFT_BONUS
  end
  return false
end

function BigMapModule:GetCatchPetIconPath(npcRefreshId)
  if self.allBonusEventPoolConf == nil then
    self.allBonusEventPoolConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BONUS_EVENT_POOL_CONF):GetAllDatas()
  end
  for _, bonusConf in pairs(self.allBonusEventPoolConf) do
    if bonusConf.bonus_type == _G.Enum.BonusEventResultType.BOERT_NPC_CONTENT and bonusConf.bonus_param[1] == npcRefreshId then
      return bonusConf.show_icon
    end
  end
end

function BigMapModule:OnCmdOnTravelShowMouseIcon(npcInfo)
  if self:HasPanel("MainBigMap") then
    local panel = self:GetPanel("MainBigMap")
    if panel then
      panel:OnTravelShowMouseIcon(npcInfo)
    end
  end
end

function BigMapModule:OnCmdIsMapUnlock(sceneResId)
  if not (sceneResId and self.data) or not self.data.unLockMapBlockId then
    return false
  end
  for k, v in pairs(self.data.unLockMapBlockId) do
    local worldMapBlockConf = _G.DataConfigManager:GetWorldMapBlockConf(v, true)
    if worldMapBlockConf and worldMapBlockConf.scene_res_id == sceneResId then
      return true
    end
  end
  return false
end

function BigMapModule:OnHandbookPetStateChange(petBaseID)
  if self.data then
    self.data:CheckTracingPet(petBaseID)
  end
end

function BigMapModule:OnCmdGetCurShowSceneResId()
  return self.data:GetCurShowSceneResId()
end

function BigMapModule:GetTransferBtnNum(worldMapConf)
  local transferBtnCnt = 0
  if worldMapConf then
    if worldMapConf.teleport_rule_id > 0 or worldMapConf.teleport_id > 0 then
      local storyFlag = worldMapConf.teleport_flag
      if storyFlag and storyFlag > 0 then
        local hasStoryFlag = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(storyFlag)
        if hasStoryFlag then
          transferBtnCnt = transferBtnCnt + 1
        end
      else
        transferBtnCnt = transferBtnCnt + 1
      end
    end
    if worldMapConf.special_teleport > 0 then
      local storyFlag = worldMapConf.special_teleport_flag
      if storyFlag and storyFlag > 0 then
        local hasStoryFlag = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(storyFlag)
        if hasStoryFlag then
          transferBtnCnt = transferBtnCnt + 1
        end
      else
        transferBtnCnt = transferBtnCnt + 1
      end
    end
  end
  return transferBtnCnt
end

function BigMapModule:DoCommonTransfer(entryId, worldMapConf, visitorInfo, bSpecial)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveUnlockUIShowByEnum, _G.Enum.FunctionEntrance.FE_MAP)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_NpcInfo_C:OnBtnTransferClick")
  local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_UI_TELEPORT, true, true)
  if bBan then
    return
  end
  if not BattleManager:IsInBattle() then
    if entryId and 0 ~= entryId and self:GetTransferBtnNum(worldMapConf) > 0 then
      if entryId > 0 then
        if worldMapConf.map_show_location == Enum.MapIconShowLocation.MISL_BIGWORLD then
          if _G.DataModelMgr.PlayerDataModel.playerInfo.common_info.in_dungeon_id then
            _G.DataModelMgr.PlayerDataModel.playerInfo.common_info.in_dungeon_id = nil
          end
          _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.CloseMagicManual)
          self:OnCmdSendWorldMapTeleportReq(entryId, bSpecial)
        elseif worldMapConf.map_show_location == Enum.MapIconShowLocation.MISL_HOME_PLANT or worldMapConf.map_show_location == Enum.MapIconShowLocation.MISL_HOME_INDOOR then
          self:DoHomeTransfer(nil, worldMapConf.map_show_location, worldMapConf.id)
        end
      elseif worldMapConf.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
        self:OnCmdSendWorldMapTeleportReq(entryId, bSpecial)
      end
    else
      Log.Error("[UMG_NpcInfo_C:OnBtnTransferClick]:npc id error!", entryId)
    end
    if worldMapConf.map_show_type == _G.Enum.MapIconShowType.MAP_CREATE_MAGIC then
      _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SendWorldMapNpcTeleportReq, entryId)
    elseif worldMapConf.map_show_type == _G.Enum.MapIconShowType.MAP_ONLINE_TEAM and visitorInfo and visitorInfo.uin then
      self:OnCmdZoneSceneWorldMapTeleportToPlayerReq(visitorInfo.uin)
    end
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcinfo_8)
  end
end

function BigMapModule:DoHomeTransfer(playerUin, homeSceneType, worldMapConfId)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_HOME, true)
  if isBan then
    return
  end
  local isBan1 = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_UI_TELEPORT, true, true)
  if isBan1 then
    return
  end
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer:IsInTogetherMove() then
    local banConf = _G.DataConfigManager:GetFunctionBanConf(106)
    if banConf then
      NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, banConf.ban_desc)
    end
    return
  end
  if homeSceneType == ProtoEnum.ZoneSceneHomeEnterReq.HomeSceneType.HomeSceneType_Plant then
    local bCheckPlantMapUnlock = true
    local OwnerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or 0
    if 0 ~= OwnerUin then
      local PlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      if OwnerUin ~= PlayerUin then
        bCheckPlantMapUnlock = false
      end
    end
    if bCheckPlantMapUnlock then
      local bAbleToHomePlant = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_HOME_START) and _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_PLANT_LAND) and NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, 30002)
      if not bAbleToHomePlant then
        NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_50295)
        return
      end
    end
  end
  local OwnerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or 0
  if 0 ~= OwnerUin and nil == playerUin then
    playerUin = OwnerUin
  end
  if BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) then
    local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
    local homeOwnerId = homeBriefInfo.home_owner_id or 0
    playerUin = homeOwnerId
  end
  NRCModuleManager:DoCmd(HomeModuleCmd.ReqEnterPlayerHomeIndoor, playerUin, nil, nil, nil, nil, homeSceneType, worldMapConfId)
end

function BigMapModule:DoLeaveHomeTransfer(entryId, worldMapConf)
  local bSpecial = worldMapConf.special_teleport > 0 and true or false
  
  local function OnSingleLeave()
    self:DoCommonTransfer(entryId, worldMapConf, nil, bSpecial)
  end
  
  _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnZoneSceneHomeTeamQueryReq, OnSingleLeave, nil, entryId, bSpecial)
end

function BigMapModule:GetAllCurTraceAcceptableTask()
  return self.data:GetAllCurTraceAcceptableTask()
end

function BigMapModule:GetCurTraceAcceptableTask(InTaskID)
  return self.data:GetCurTraceAcceptableTask(InTaskID)
end

function BigMapModule:OnCmdCheckAutoTracking(logicId)
  return self.data:CheckAutoTrackingByLogicId(logicId)
end

function BigMapModule:CheckIsTracing(traceType, key, extraKey)
  if self.data.traceInfoList and self.data.traceInfoList[traceType] then
    if traceType == BigMapModuleEnum.TraceType.NPC then
      local npcInfo = self.data.traceInfoList[traceType].npcInfo
      if npcInfo.entry_id == key and npcInfo.logic_id == extraKey then
        return true
      end
    elseif traceType == BigMapModuleEnum.TraceType.Marker then
      if self.data.traceInfoList[traceType].markInfo.mark_id == key then
        return true
      end
    elseif traceType == BigMapModuleEnum.TraceType.ForceTrace then
      local traceInfoList = self.data.traceInfoList[traceType]
      if traceInfoList then
        for k, traceList in pairs(traceInfoList) do
          if traceList and #traceList > 0 then
            for _k, traceInfo in ipairs(traceList) do
              if traceInfo.npcInfo.logic_id == extraKey then
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

function BigMapModule:GetInfoBarList()
  local infoBarList = {}
  if self.data.infoBarTable then
    for key, val in pairs(self.data.infoBarTable) do
      local bShow = true
      local conditionList = val.display_condition
      if conditionList and #conditionList > 0 then
        for k, condition in ipairs(conditionList) do
          if self:CheckShowOnInfoBar(condition.display_type, condition.display_data) == false then
            bShow = false
            break
          end
        end
      end
      if bShow then
        local tempNpcList = {}
        local mapElementList = val.map_element
        if mapElementList and #mapElementList > 0 then
          for k, worldMapConfId in ipairs(mapElementList) do
            local npcInfos = self.data:GetNpcDatasByWorldMapCfgId(worldMapConfId)
            if npcInfos and #npcInfos > 0 then
              for _k, npcInfo in ipairs(npcInfos) do
                table.insert(tempNpcList, npcInfo)
              end
            end
          end
        end
        local trackNpcList = self:GetInfoBarTrackNpcList(tempNpcList)
        if trackNpcList and #trackNpcList > 0 then
          local infoBarInfo = {}
          infoBarInfo.icon = val.icon
          infoBarInfo.title = val.text
          infoBarInfo.refreshId = trackNpcList[1].npc_refresh_id
          infoBarInfo.redDotKey = val.red_point_key
          table.insert(infoBarList, infoBarInfo)
        end
      end
    end
  end
  return infoBarList
end

function BigMapModule:CheckShowOnInfoBar(displayType, displayParams)
  if displayType == Enum.DisplayMapInfo.DMI_CHECK_UI_ENTER_BAN then
    if displayParams and #displayParams > 0 then
      for k, banEntrance in ipairs(displayParams) do
        local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, banEntrance, false)
        if true == isBan then
          return false
        end
      end
    end
    return true
  elseif displayType == Enum.DisplayMapInfo.DMI_ACTIVITY_UNLOCK then
    if displayParams and #displayParams > 0 then
      for k, activityType in ipairs(displayParams) do
        local pikaActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, activityType)
        if pikaActivityInst and #pikaActivityInst > 0 then
          return true
        end
      end
    end
    return false
  elseif displayType == Enum.DisplayMapInfo.DMI_CAN_UPGRADE then
    if _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsBottleTimeUpgradeEnable) or _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRolePowerUpgradeEnable) or _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRoleHpUpgradeEnable) then
      return true
    end
    return false
  end
  return true
end

function BigMapModule:GetInfoBarTrackNpcList(npcInfoList)
  local bInFog = false
  local bUnlock = false
  if not npcInfoList or 0 == #npcInfoList then
    return {}
  end
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerPos
  if player then
    playerPos = player:GetActorLocationFrameCache()
  end
  local filteredList = {}
  for _, npcInfo in ipairs(npcInfoList) do
    local isNpcUnlocked = npcInfo.status and npcInfo.status ~= _G.ProtoEnum.LockStatus.ENUM.LOCKED
    if not isNpcUnlocked then
    else
      table.insert(filteredList, npcInfo)
    end
  end
  if #filteredList > 0 then
    local filteredList1 = {}
    bUnlock = true
    for _, npcInfo in ipairs(filteredList) do
      local isTileUnlocked = npcInfo.npc_pos and self:CheckNpcInFogArea(npcInfo.npc_pos)
      if not isTileUnlocked then
      else
        table.insert(filteredList1, npcInfo)
      end
    end
    if #filteredList1 > 0 then
      bInFog = false
      table.sort(filteredList1, function(a, b)
        local aDistSq = a.npc_pos and self:DistSquared2D(playerPos, a.npc_pos) or math.maxinteger
        local bDistSq = b.npc_pos and self:DistSquared2D(playerPos, b.npc_pos) or math.maxinteger
        return aDistSq < bDistSq
      end)
      return filteredList1, bInFog, bUnlock
    else
      bInFog = true
      table.sort(filteredList, function(a, b)
        local aDistSq = a.npc_pos and self:DistSquared2D(playerPos, a.npc_pos) or math.maxinteger
        local bDistSq = b.npc_pos and self:DistSquared2D(playerPos, b.npc_pos) or math.maxinteger
        return aDistSq < bDistSq
      end)
      return filteredList, bInFog, bUnlock
    end
  else
    local filteredList1 = {}
    bUnlock = false
    for _, npcInfo in ipairs(npcInfoList) do
      local isTileUnlocked = npcInfo.npc_pos and self:CheckNpcInFogArea(npcInfo.npc_pos)
      if not isTileUnlocked then
      else
        table.insert(filteredList1, npcInfo)
      end
    end
    if #filteredList1 > 0 then
      bInFog = false
      table.sort(filteredList1, function(a, b)
        local aDistSq = a.npc_pos and self:DistSquared2D(playerPos, a.npc_pos) or math.maxinteger
        local bDistSq = b.npc_pos and self:DistSquared2D(playerPos, b.npc_pos) or math.maxinteger
        return aDistSq < bDistSq
      end)
      return filteredList1, bInFog, bUnlock
    else
      bInFog = true
      table.sort(npcInfoList, function(a, b)
        local aDistSq = a.npc_pos and self:DistSquared2D(playerPos, a.npc_pos) or math.maxinteger
        local bDistSq = b.npc_pos and self:DistSquared2D(playerPos, b.npc_pos) or math.maxinteger
        return aDistSq < bDistSq
      end)
      return npcInfoList, bInFog, bUnlock
    end
  end
  return npcInfoList, bInFog, bUnlock
end

function BigMapModule:GetCheckDeadWoodList()
  return self.data.checkDeadWoodList
end

function BigMapModule:GetShowMapBySceneResId(sceneResId, bHasScene)
  local worldMapInfo = _G.DataModelMgr.PlayerDataModel:GetWorldMapActorInfo()
  local showSceneResId = sceneResId
  local bInDungeon = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.IsInDungeon)
  if nil == bHasScene then
    bHasScene = false
    local centerAreaId = 0
    for k, v in ipairs(self.data.MapShowList) do
      if v.sceneResId == sceneResId then
        centerAreaId = v.centerAreaId
        bHasScene = true
        break
      end
    end
  end
  if false == bHasScene then
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
      else
        showSceneResId = 10003
      end
    elseif worldMapInfo.main_scene_pt then
      local Point = worldMapInfo.main_scene_pt.pos
      local ResId = BigMapUtils.GetSceneResIdByPos(Point.x, Point.y)
      showSceneResId = ResId
      for k, v in ipairs(self.data.MapShowList) do
        if v.sceneResId == showSceneResId then
          self.mapListIndex = k
          break
        end
      end
    else
      showSceneResId = 10003
    end
  end
  return showSceneResId
end

function BigMapModule:CheckLayerDeadWoodIsUnlock(layerId)
  local layerMapConf = _G.DataConfigManager:GetLayeredWorldMapConf(layerId)
  if layerMapConf then
    local campRefreshId = layerMapConf.belong_camp
    if nil == campRefreshId or 0 == campRefreshId then
      return true
    end
    if self.data.DrawList and self.data.DrawList[self.data.curShowSceneResId] then
      for k, v in pairs(self.data.DrawList[self.data.curShowSceneResId]) do
        local refreshId = self.data.AreaIdToRefreshId[v]
        if campRefreshId == refreshId then
          return true
        end
      end
    end
  end
  return false
end

return BigMapModule

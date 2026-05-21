local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local MapItemNPC = require("NewRoco/Modules/System/BigMap/Res/MapItemNPC")
local MapItemTask = require("NewRoco/Modules/System/BigMap/Res/MapItemTask")
local MapItemMarker = require("NewRoco/Modules/System/BigMap/Res/MapItemMarker")
local MapItemVisitor = require("NewRoco/Modules/System/BigMap/Res/MapItemVisitor")
local MapItemAreaName = require("NewRoco/Modules/System/BigMap/Res/MapItemAreaName")
local MapItemLayerMap = require("NewRoco/Modules/System/BigMap/Res/MapItemLayerMap")
local MapItemCircle = require("NewRoco/Modules/System/BigMap/Res/MapItemCircle")
local BigMapModuleEvent = require("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local FVector2DUtils = require("NewRoco.Utils.FVector2DUtils")
local UMG_Minimap_C = _G.NRCPanelBase:Extend("UMG_Minimap_C")
local TaskPosCache = UE4.FVector2D(0, 0)

function UMG_Minimap_C:OnConstruct()
  self.playerPos = UE4.FVector()
  self.playerImagePos = UE4.FVector2D()
  self.centerPosX = 0
  self.centerPosY = 0
  self.mapImageScale = 1
  self.imageScale = UE4.FVector2D()
  self.bShow = false
  self.lastShowPieceIdList = {}
  self.curShowPieceIdList = {}
  self.lastShowLayerId = 0
  self.disPlayRadius = 0
  self.curWndSize = UE4.FVector2D(227, 227)
  self.mapList = {
    self.Map_01,
    self.Map_02,
    self.Map_03,
    self.Map_04,
    self.Map_05,
    self.Map_06,
    self.Map_07,
    self.Map_08,
    self.Map_09,
    self.Map_10,
    self.Map_11,
    self.Map_12,
    self.Map_13,
    self.Map_14,
    self.Map_15,
    self.Map_16
  }
  self.bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if self.bigMapModule then
    self.showNpc = self.bigMapModule:GetMinimapShowNpc()
    self.showAreaNpc = self.bigMapModule:GetMinimapShowAreaNpc()
    self.showMapList = self.bigMapModule:OnCmdGetCurUnlockMapBlockIds()
    self.data = self.bigMapModule.data
    self.forceTraceLimit = self.bigMapModule:GetForceTraceLimit()
  end
  self.innerRadius = 0
  self.outerRadius = 0
  self.maxTraceDis = UE4.FVector2D()
  self:SetMapShowRadius()
  self.curShowTaskList = {}
  self.tracingTaskList = {}
  self.acceptTaskList = {}
  self.normalTaskList = {}
  self.delTaskList = {}
  self.miniMapTraceInfo = {}
  self.curShowNpc = {}
  self.defaultTrackNpcList = {}
  self.defaultTrackNpcLogicIdList = {}
  self.npc = nil
  self.curTraceInfoList = {}
  self.ShowHighAngle = _G.DataConfigManager:GetMapGlobalConfig("high_divide_angle").num
  self.ShowHighDis = _G.DataConfigManager:GetMapGlobalConfig("min_divide_range").num
  self.iconScale = _G.DataConfigManager:GetMapGlobalConfig("main_map_icon_resource_scale").num / 10000
  self.tracePixel = _G.DataConfigManager:GetMapGlobalConfig("main_map_inner_outer_dif").num
  self.DetectLimitH = {}
  self.DetectLimitH.h_drange_DoSearch = DataConfigManager:GetMapGlobalConfig("h_drange_DoSearch").num
  self.DetectLimitH.h_drange_InTown = DataConfigManager:GetMapGlobalConfig("h_drange_InTown").num
  self.DetectLimitH.h_drange_DropBy = DataConfigManager:GetMapGlobalConfig("h_drange_DropBy").num
  self.DetectLimitH.h_drange_Waypoint = DataConfigManager:GetMapGlobalConfig("h_drange_Waypoint").num
  self.DetectLimitH.h_drange_Destination = DataConfigManager:GetMapGlobalConfig("h_drange_Destination").num
  self.DetectLimitV = {}
  self.DetectLimitV.v_drange_DoSearch = DataConfigManager:GetMapGlobalConfig("v_drange_DoSearch").num
  self.DetectLimitV.v_drange_InTown = DataConfigManager:GetMapGlobalConfig("v_drange_InTown").num
  self.DetectLimitV.v_drange_DropBy = DataConfigManager:GetMapGlobalConfig("v_drange_DropBy").num
  self.DetectLimitV.v_drange_Waypoint = DataConfigManager:GetMapGlobalConfig("v_drange_Waypoint").num
  self.DetectLimitV.v_drange_Destination = DataConfigManager:GetMapGlobalConfig("v_drange_Destination").num
  self:UpdateScaleData()
  self.iconLayerList = {
    self.iconLayer1,
    self.iconLayer2,
    self.Customdot,
    self.layerTrace
  }
  self.iconNPCTemplate = {
    self.iconNpcPet,
    self.iconNpcFunction,
    self.iconNpcRole
  }
  self.iconTaskTemplate = {
    self.iconTaskTemple
  }
  self.iconMarkerTemplate = {
    self.MarkerIcon
  }
  self.iconVisitorTemplate = {
    self.IconVisit
  }
  self.iconCircleTemplate = {
    self.iconCircle
  }
  self.npcIconCreator = MapItemNPC(self, self.iconLayerList, self.iconNPCTemplate)
  self.taskIconCreator = MapItemTask(self, self.iconLayerList, self.iconTaskTemplate)
  self.markerIconCreator = MapItemMarker(self, self.iconLayerList, self.iconMarkerTemplate)
  self.visitorIconCreator = MapItemVisitor(self, self.iconLayerList, self.iconVisitorTemplate)
  self.areaNameIconCreator = MapItemAreaName(self, self.iconLayerList, self.iconNPCTemplate)
  self.mapLayerCreator = MapItemLayerMap(self, self.layerMapLayer, self.mapLayerTemplate)
  self.iconCircleCreator = MapItemCircle(self, self.iconLayerList, self.iconCircleTemplate)
  self.creatorList = {
    self.npcIconCreator,
    self.taskIconCreator,
    self.markerIconCreator,
    self.visitorIconCreator,
    self.areaNameIconCreator,
    self.mapLayerCreator,
    self.iconCircleCreator
  }
  self:CalcMapImageScale()
  self:SetMapMaskVisible()
  self.heroIcon:SetRenderScale(UE4.FVector2D(self.iconScale, self.iconScale))
  self:OnAddEventListener()
  self:OnZoneInfoChange()
  self.tickInterval = 0
  self.calcDisInterval = 0
  self.CurTrackIconCircleList = {}
  self.preTeleporting = false
  self.CurrentTrackingTaskId = nil
end

function UMG_Minimap_C:OnActive()
end

function UMG_Minimap_C:OnDeactive()
end

function UMG_Minimap_C:OnAddEventListener()
  self:AddButtonListener(self.OpenBtn, self.OnOpenBtnClick)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY, self.OnPreTeleportNotify)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, BigMapModuleEvent.OnMapDataRefreshed, self.OnSceneLoaded)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIEnabled)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIDisabled)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.STORY_FLAG_ADDED, self.OnStoryFlagAdded)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, BigMapModuleEvent.AcceptTaskRefresh, self.OnAcceptTaskChanged)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, BigMapModuleEvent.OnMapInfoChange, self.OnMapInfoChanged)
  NRCModuleManager:GetModule("MainUIModule"):RegisterEvent(self, MainUIModuleEvent.UpdateMinimapShow, self.OnZoneInfoChange)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, BigMapModuleEvent.OnNewMapUnlocked, self.SetMapMaskVisible)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  NRCEventCenter:RegisterEvent("UMG_Minimap_C", self, BigMapModuleEvent.DefaultTrackNpcChange, self.OnDefaultTrackNpcChange)
end

function UMG_Minimap_C:OnRemoveEventListener()
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY, self.OnPreTeleportNotify)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnMapDataRefreshed, self.OnSceneLoaded)
  NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIEnabled)
  NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIDisabled)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.STORY_FLAG_ADDED, self.OnStoryFlagAdded)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.AcceptTaskRefresh, self.OnAcceptTaskChanged)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.OnMapInfoChange, self.OnMapInfoChanged)
  NRCModuleManager:GetModule("MainUIModule"):UnRegisterEvent(self, MainUIModuleEvent.UpdateMinimapShow, self.OnZoneInfoChange)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.OnNewMapUnlocked, self.SetMapMaskVisible)
  NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  NRCEventCenter:UnRegisterEvent(self, BigMapModuleEvent.DefaultTrackNpcChange, self.OnDefaultTrackNpcChange)
end

function UMG_Minimap_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_Minimap_C:UpdateScaleData()
  local sceneOffsetX, sceneOffsetY, sceneWidth, sceneHeight = BigMapUtils.GetConstData(SceneUtils.GetSceneResId())
  self.imageToSceneScale = 6144 / sceneWidth
  self.sceneWidth = sceneWidth
end

function UMG_Minimap_C:OnNavigationModeUpdate(mode)
  Log.Debug(self.bShow, mode, "UMG_Minimap_C:OnNavigationModeUpdate")
  if mode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
    self.bShow = true
  else
    self.bShow = false
  end
end

function UMG_Minimap_C:OnPreTeleportNotify(notify)
  self.preTeleporting = true
end

function UMG_Minimap_C:OnTeleportNotify(notify)
  self.preTeleporting = false
end

function UMG_Minimap_C:OnStoryFlagAdded(flag, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flag)
  if bIsHomeOwner == UseSelf then
    return
  end
  if flag == Enum.PlayerStoryFlagEnum.PSF_FUNC_MAP then
    self:SetMapMaskVisible()
  end
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule.data then
    local mapStoryFlagList = bigMapModule.data.mapUnlockStoryFlagList
    if mapStoryFlagList and #mapStoryFlagList > 0 then
      for k, v in ipairs(mapStoryFlagList) do
        if flag == v then
          bigMapModule.data:SetMiniMapShowNpcs(SceneUtils.GetSceneResId())
          break
        end
      end
    end
  end
end

function UMG_Minimap_C:OnMainUIEnabled()
  if _G.DataModelMgr.PlayerDataModel:GetNavigationMode() == ProtoEnum.NavigationModeType.NMT_MINIMAP then
    self.bShow = true
  end
end

function UMG_Minimap_C:OnMainUIDisabled()
  self.bShow = false
end

function UMG_Minimap_C:OnOpenBtnClick()
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap)
end

function UMG_Minimap_C:OnSceneLoaded()
  self:DelayFrames(1, function()
    self:OnSceneLoaded_Impl()
  end)
end

function UMG_Minimap_C:OnSceneLoaded_Impl()
  self:ClearCache()
  self:UpdateScaleData()
  self:SetMapShowRadius()
  self:CalcMapImageScale()
  self:UpdateIconScale()
  self:SetMapAndMaskBySceneResId()
  self:SetMapMaskVisible()
  self:UpdateTaskInfo()
  self:UpdateMarkInfo()
  self:OnZoneInfoChange()
  self:ChangeMinimapState(MainUIModuleEnum.MinimapOrCompassState.Normal)
  local sceneResId = SceneUtils.GetSceneResId()
  if sceneResId and sceneResId > 0 then
    self:SetMiniMapBg(sceneResId)
  end
  self.defaultTrackNpcList = table.deepCopy(NRCModuleManager:DoCmd(BigMapModuleCmd.GetDefaultTrackNpcList))
end

function UMG_Minimap_C:SetMiniMapBg(sceneResId)
  local sceneResConf = DataConfigManager:GetSceneResConf(sceneResId)
  if sceneResConf then
    local bgPath = sceneResConf.main_map_res_path
    local mapIsUnlock = NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, sceneResId)
    if not (not string.IsNilOrEmpty(bgPath) and self:CheckHasMapStoryFlag()) or not mapIsUnlock and BigMapUtils.IsBigWorldMap(sceneResId) then
      self.MapBg:SetPath(UEPath.DefaultMinimapBackground)
    else
      self.MapBg:SetPath(bgPath)
    end
  end
end

function UMG_Minimap_C:OnZoneInfoChange()
  if self.preTeleporting then
    return
  end
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule.data then
    local layerId = bigMapModule.data:GetCurMapLayerId()
    self:ShowLayerMap(layerId)
  end
end

function UMG_Minimap_C:ShowLayerMap(layerId)
  if layerId > 0 then
    self.Image_zhezhao:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Image_zhezhao:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.lastShowLayerId ~= layerId then
    self.mapLayerCreator:Destroy(self.lastShowLayerId)
    if layerId > 0 then
      self:CreateLayerMap(layerId)
    end
    if layerId > 0 then
      self:SetIconLayerColor(layerId, BigMapModuleEnum.CreatorPriority.NpcIcons, true)
      self:SetIconLayerColor(layerId, BigMapModuleEnum.CreatorPriority.MarkerIcons, true)
    end
    if self.lastShowLayerId > 0 and self.lastShowLayerId ~= layerId then
      self:SetIconLayerColor(self.lastShowLayerId, BigMapModuleEnum.CreatorPriority.NpcIcons, false)
      self:SetIconLayerColor(self.lastShowLayerId, BigMapModuleEnum.CreatorPriority.MarkerIcons, false)
    end
  end
  self.lastShowLayerId = layerId
end

function UMG_Minimap_C:SetIconLayerColor(layerId, iconType, bColorful)
  if self.data.layerIdToIcons[layerId] == nil then
    return
  end
  if iconType == BigMapModuleEnum.CreatorPriority.NpcIcons then
    local layerNpcInfo = self.data.layerIdToIcons[layerId][iconType]
    if layerNpcInfo then
      for entryId, npcList in pairs(layerNpcInfo) do
        if npcList and #npcList > 0 then
          for k, logicId in ipairs(npcList) do
            if self.npcIconCreator and self.npcIconCreator:Get(entryId, logicId) then
              self.npcIconCreator:Get(entryId, logicId):SetLayerMapIcon(bColorful)
            end
          end
        end
      end
    end
  elseif iconType == BigMapModuleEnum.CreatorPriority.MarkerIcons then
    local layerMarkInfo = self.data.layerIdToIcons[layerId][iconType]
    if layerMarkInfo then
      for markId, markList in pairs(layerMarkInfo) do
        if self.markerIconCreator and self.markerIconCreator:Get(markId) then
          self.markerIconCreator:Get(markId):SetLayerMapIcon(bColorful)
        end
      end
    end
  end
end

function UMG_Minimap_C:CreateLayerMap(layerId)
  local iconData = {}
  local imageData = {}
  local posX = 0
  local posY = 0
  local layerConf = _G.DataConfigManager:GetLayeredWorldMapConf(layerId)
  if layerConf then
    local orthoWidth = layerConf.Ortho_width
    if layerConf.camera_center and #layerConf.camera_center >= 2 then
      local centerPos = UE4.FVector(layerConf.camera_center[1], layerConf.camera_center[2], layerConf.camera_center[3])
      local startPos = centerPos - UE4.FVector(orthoWidth / 2, orthoWidth / 2, 0)
      posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), startPos.X, startPos.Y)
    end
    iconData.iconImagePos = {x = posX, y = posY}
    local imageWidth = orthoWidth * self.imageToSceneScale
    imageData.imageScale = UE4.FVector2D(imageWidth, imageWidth)
    imageData.imagePath = BigMapUtils.GetLayerMapImagePath(layerId)
    imageData.layerMapId = layerId
  end
  self.mapLayerCreator:Create({iconData = iconData, imageInfo = imageData})
end

function UMG_Minimap_C:OnMapInfoChanged(bDelete, npcInfo, entryId, logicId)
  Log.Debug("UMG_Minimap_C:OnMapInfoChanged", bDelete, entryId, logicId)
  Log.Dump(npcInfo, 4, "UMG_Minimap_C:OnMapInfoChanged")
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    self.showNpc = bigMapModule:GetMinimapShowNpc()
    self.showAreaNpc = bigMapModule:GetMinimapShowAreaNpc()
  end
  if npcInfo and npcInfo.entry_id and npcInfo.logic_id then
    if true == bDelete then
      self.npcIconCreator:Recycle(npcInfo.entry_id, npcInfo.logic_id)
      if npcInfo.worldMapActivityConf then
        local activityMapId = npcInfo.worldMapActivityConf.id
        self.iconCircleCreator:Destroy(BigMapModuleEnum.CircleIconType.Activity, activityMapId, activityMapId)
      end
    else
      local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), npcInfo.npc_pos.x, npcInfo.npc_pos.y)
      local iconData = {}
      iconData.iconImagePos = {x = posX, y = posY}
      iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
      iconData.curMapSliderScale = 1
      if self.npcIconCreator:Get(npcInfo.entry_id, npcInfo.logic_id) then
        self.npcIconCreator:Refresh({iconData = iconData, npcInfo = npcInfo})
      end
    end
  elseif entryId and entryId > 0 and logicId and logicId > 0 and true == bDelete then
    self.npcIconCreator:Recycle(entryId, logicId)
    if npcInfo and npcInfo.worldMapActivityConf then
      local activityMapId = npcInfo.worldMapActivityConf.id
      self.iconCircleCreator:Destroy(BigMapModuleEnum.CircleIconType.Activity, activityMapId, activityMapId)
    end
  end
end

function UMG_Minimap_C:OnTaskChanged()
  self:RecycleTaskIcon()
end

function UMG_Minimap_C:OnAcceptTaskChanged()
  self:UpdateTaskInfo()
end

function UMG_Minimap_C:SetMapShowRadius()
  local sceneResId = SceneUtils.GetSceneResId()
  local blockConf = self.data.sceneResIdToBlockConf[sceneResId]
  if blockConf then
    self.innerRadius = blockConf.main_map_small_radius
    self.outerRadius = blockConf.main_map_big_radius
  else
    local commonBlockConf = DataConfigManager:GetWorldMapBlockConf(999)
    if commonBlockConf then
      self.innerRadius = commonBlockConf.main_map_small_radius
      self.outerRadius = commonBlockConf.main_map_big_radius
    end
  end
end

function UMG_Minimap_C:GetTraceK(dis)
  return self.disPlayRadius / dis
end

function UMG_Minimap_C:SetMapMaskVisible()
  local mapIsUnlock = NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, SceneUtils.GetSceneResId())
  if self:CheckHasMapStoryFlag() and mapIsUnlock then
    self:ShowMap(true)
    local sceneResId = SceneUtils.GetSceneResId()
    local blockConf = self.data.sceneResIdToBlockConf[sceneResId]
    if blockConf then
      if blockConf.not_foggy and blockConf.not_foggy > 0 then
        self:ShowMask(false)
      else
        self:ShowMask(true)
      end
    end
  else
    self:ShowMap(false)
    self:ShowMask(false)
  end
end

function UMG_Minimap_C:OnVisitorChanged(notify)
  self:UpdateVisitorInfo()
end

function UMG_Minimap_C:OnDefaultTrackNpcChange()
  self.defaultTrackNpcList = table.deepCopy(NRCModuleManager:DoCmd(BigMapModuleCmd.GetDefaultTrackNpcList))
  self:UpdateDefaultNpcInfo()
end

function UMG_Minimap_C:OnTick(deltaTime)
  if self.bShow then
    self:UpdatePlayerAndMapPos()
    self:SetMapAndMaskBySceneResId()
    self:UpdateMarkInfo()
    self:UpdateNpcAndTrace(deltaTime)
    self:UpdateTraceTask()
    self:UpdateTreasureActivityInfo()
    self:UpdateIconVisible()
  end
end

function UMG_Minimap_C:UpdateNpcAndTrace(deltaTime)
  self.tickInterval = self.tickInterval + deltaTime
  if self.tickInterval > 0.3 then
    self:UpdateNpcInfo()
    self:UpdateAreaNpcInfo()
    self:UpdateHomePetInfo()
    self.tickInterval = 0
  end
  self.calcDisInterval = self.calcDisInterval + deltaTime
  if self.calcDisInterval > 1 then
    self:UpdateDefaultNpcInfo()
    self.calcDisInterval = 0
  end
  self:UpdateTraceIconPosition()
end

function UMG_Minimap_C:UpdateIconVisible()
end

function UMG_Minimap_C:ShowMap(bShow)
  if bShow then
    self.mapLayer1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.mapLayer1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Minimap_C:ShowMask(bShow)
  if bShow then
    self.MapMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.MapMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Minimap_C:CheckHasMapStoryFlag()
  return _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAP)
end

function UMG_Minimap_C:UpdatePlayerAndMapPos()
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    self.playerPos = localPlayer:GetActorLocationFrameCache()
    self.centerPosX, self.centerPosY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), self.playerPos.X, self.playerPos.Y)
    local playerCameraManager = self:GetOwningPlayerCameraManager()
    if playerCameraManager then
      local TempRotation = self:GetTempRotation()
      UE4.UNRCStatics.K2_GetActorRotationInplace(playerCameraManager, TempRotation)
      local playerAng = TempRotation.Yaw + 135
      UE4.UNRCStatics.K2_GetActorRotationInplace(localPlayer:GetViewObject(), TempRotation)
      local playerDir = TempRotation.Yaw + 90
      local x = self.centerPosX / 6144 or 0
      local y = self.centerPosY / 6144 or 0
      self.mapLayer1:SetRenderTranslation(self:GetTempVector2(-self.centerPosX, -self.centerPosY))
      self.mapLayer:SetRenderTranslation(self:GetTempVector2(-self.centerPosX, -self.centerPosY))
      self.layerMapLayer:SetRenderTranslation(self:GetTempVector2(-self.centerPosX, -self.centerPosY))
      self.layerTrace:SetRenderTranslation(self:GetTempVector2(-self.centerPosX, -self.centerPosY))
      self.mapLayer1:SetRenderTransformPivot(self:GetTempVector2(x, y))
      self.mapLayer:SetRenderTransformPivot(self:GetTempVector2(x, y))
      self.layerMapLayer:SetRenderTransformPivot(self:GetTempVector2(x, y))
      self.layerTrace:SetRenderTransformPivot(self:GetTempVector2(x, y))
      self.Sector:SetRenderTransformAngle(playerAng or 0)
      self.heroIcon:SetRenderTransformAngle(playerDir or 0)
    end
  end
end

function UMG_Minimap_C:SetMapAndMaskBySceneResId(sceneResId)
  sceneResId = sceneResId or SceneUtils.GetSceneResId()
  local centerPos = self:GetTempVector2(self.centerPosX, self.centerPosY)
  local mapPieceList = BigMapUtils.GetLoadPiecesByImagePosition(1024, self.curWndSize, centerPos, self.imageScale.X)
  self.curShowPieceIdList = mapPieceList
  local newPieceList, oldPieceList
  if self.lastShowPieceIdList == nil or 0 == #self.lastShowPieceIdList then
    newPieceList = mapPieceList
  else
    newPieceList, oldPieceList = self:CheckMapPieceChange(mapPieceList)
  end
  self:SetMapBySceneResId(sceneResId, newPieceList, oldPieceList)
  self.lastShowPieceIdList = self.curShowPieceIdList
end

function UMG_Minimap_C:CheckMapPieceChange(curPieceList)
  local newPieceList = {}
  local oldPieceList = {}
  for k, v in ipairs(self.lastShowPieceIdList) do
    local hasOld = false
    for i, j in ipairs(curPieceList) do
      if v == j then
        hasOld = true
      end
    end
    if false == hasOld then
      table.insert(oldPieceList, v)
    end
  end
  for k, v in ipairs(curPieceList) do
    local hasNew = false
    for i, j in ipairs(self.lastShowPieceIdList) do
      if v == j then
        hasNew = true
      end
    end
    if false == hasNew then
      table.insert(newPieceList, v)
    end
  end
  return newPieceList, oldPieceList
end

function UMG_Minimap_C:SetMapBySceneResId(sceneResId, newPieceList, oldPieceList)
  if self.mapList and #self.mapList > 0 then
    for i = 1, #self.mapList do
      if newPieceList and #newPieceList > 0 then
        for k, v in ipairs(newPieceList) do
          if i == v then
            local assetPath = BigMapUtils.GetMapPicPath(sceneResId, i)
            if assetPath then
              self.mapList[i]:SetPath(assetPath)
            end
          end
        end
      end
      if oldPieceList and #oldPieceList > 0 then
        for k, v in ipairs(oldPieceList) do
          if i == v then
            self.mapList[i]:SetPath("")
          end
        end
      end
    end
  end
end

function UMG_Minimap_C:CalcMapImageScale()
  self.imageScale = self.curWndSize / 2 * self.sceneWidth / (self.outerRadius * 6144)
  self.mapLayer1:SetRenderScale(self.imageScale)
  self.mapLayer:SetRenderScale(self.imageScale)
  self.layerMapLayer:SetRenderScale(self.imageScale)
  self.layerTrace:SetRenderScale(self.imageScale)
  self.disPlayRadius = (self.curWndSize.X / 2 + self.tracePixel) / self.imageScale.X
end

function UMG_Minimap_C:CreateNpcIcon(iconData, npcInfo)
  self.npcIconCreator:Create({iconData = iconData, npcInfo = npcInfo})
end

function UMG_Minimap_C:CreateTaskIcon(iconData, taskInfo)
  self.taskIconCreator:Create(iconData, taskInfo)
end

function UMG_Minimap_C:CreateMarkerIcon(iconData, markerInfo)
  self.markerIconCreator:Create({iconData = iconData, markerInfo = markerInfo})
end

function UMG_Minimap_C:CreateVisitorIcon(iconData, visitorInfo)
  self.visitorIconCreator:Create({iconData = iconData, visitorInfo = visitorInfo})
end

function UMG_Minimap_C:CreateMapAreaNameIcon(iconData, areaInfo)
  self.areaNameIconCreator:Create({iconData = iconData, areaInfo = areaInfo})
end

function UMG_Minimap_C:CreateCircleIcon(iconData, npcInfo)
  if npcInfo.worldMapActivityConf then
    iconData.iconTemplateIndex = 1
    iconData.layerIndex = 1
    local circleInfo = {}
    circleInfo.showType = BigMapModuleEnum.CircleIconType.Activity
    circleInfo.typeId = npcInfo.worldMapActivityConf.id
    circleInfo.circleRadius = npcInfo.worldMapActivityConf.radius
    circleInfo.showScale = npcInfo.worldMapConf.element_show_scale
    self.iconCircleCreator:Create(iconData, circleInfo)
  end
end

function UMG_Minimap_C:ClearTreasureIcon(iconList)
  self.areaNameIconCreator:ClearTreasureIcon(iconList)
end

function UMG_Minimap_C:SetCurShowTaskList(taskInfo)
  if taskInfo.SubTaskId == nil then
    taskInfo.SubTaskId = taskInfo.taskId
  end
  local taskId = taskInfo.taskId
  local subTaskId = taskInfo.SubTaskId
  if nil == self.curShowTaskList[subTaskId] then
    self.curShowTaskList[subTaskId] = {}
  end
  self.curShowTaskList[subTaskId] = taskId
end

function UMG_Minimap_C:CheckUseRealNpcPos(worldMapConf)
  if not worldMapConf then
    return
  end
  if worldMapConf.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING then
    return true
  end
  if worldMapConf.map_show_type == Enum.MapIconShowType.MAP_NPC_DAZZLING then
    return true
  end
  if worldMapConf.map_show_type == Enum.MapIconShowType.MAP_HANDBOOK_TRACK then
    return true
  end
  if worldMapConf.default_track_type ~= Enum.DefaultTrackType.DTT_NONE then
    return true
  end
  return false
end

function UMG_Minimap_C:UpdateNpcInfo()
  table.clear(self.miniMapTraceInfo)
  table.clear(self.curShowNpc)
  local sceneResId = SceneUtils.GetSceneResId()
  if self.curShowPieceIdList and self.showNpc then
    if self.data.sceneResIdToBlockConf[sceneResId] then
      for k, showPieceId in pairs(self.curShowPieceIdList) do
        if self.showNpc[sceneResId] then
          local npcList = self.showNpc[sceneResId][showPieceId]
          if npcList and self.npcIconCreator then
            for npcId, _npcInfo in pairs(npcList) do
              for logicId, npcInfo in pairs(_npcInfo) do
                local bForceTrace = self:CheckIsTracing(BigMapModuleEnum.TraceType.ForceTrace, npcInfo)
                local bCommonTrace = self:CheckIsTracing(BigMapModuleEnum.TraceType.NPC, npcInfo)
                local trackType = npcInfo.worldMapConf and npcInfo.worldMapConf.default_track_type
                if trackType ~= Enum.DefaultTrackType.DTT_NONE and self:CheckIsShowDefaultNpc(trackType, npcInfo.logic_id) ~= true and not bForceTrace and not bCommonTrace then
                else
                  if npcInfo.npcCfg and npcInfo.npcCfg.genre and npcInfo.npcCfg.genre == _G.Enum.ClientNpcType.CNT_HOME_NPC then
                    local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcInfo.entry_id)
                    if npc and npc.viewObj then
                      local pos = npc:GetActorLocation()
                      npcInfo.npc_pos.x = pos.X
                      npcInfo.npc_pos.y = pos.Y
                      npcInfo.npc_pos.z = pos.Z
                    end
                  end
                  if self:CheckUseRealNpcPos(npcInfo.worldMapConf) then
                    self.npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByLogicID, npcInfo.logic_id or -1)
                    if self.npc and self.npc.viewObj then
                      local pos = self.npc:GetActorLocation()
                      npcInfo.npc_pos.x = pos.X
                      npcInfo.npc_pos.y = pos.Y
                      npcInfo.npc_pos.z = pos.Z
                    end
                  end
                  if npcInfo.npc_pos then
                    local npcPosX = npcInfo.npc_pos.x
                    local npcPosY = npcInfo.npc_pos.y
                    local npcPosZ = npcInfo.npc_pos.z
                    local bShowNpc = self:CheckShowIcon(npcPosX, npcPosY, npcPosZ, npcInfo.worldMapConf)
                    local distance = self:GetDistance3D(npcPosX, npcPosY, npcPosZ)
                    local bTracing = bCommonTrace or bForceTrace
                    local bShow = bShowNpc or bTracing
                    if bShow then
                      local entryId = npcInfo.entry_id
                      if self.npcIconCreator:Get(entryId, logicId) then
                        local itemData = self.npcIconCreator:GetItemData(entryId, logicId)
                        if itemData then
                          local curLayerIndex = itemData.iconData.layerIndex
                          if bTracing and self:CheckShowNpcTraceEffect(npcInfo.worldMapConf) then
                            self.npcIconCreator:SetTraceEffect(true, entryId, logicId)
                          else
                            self.npcIconCreator:SetTraceEffect(false, entryId, logicId)
                          end
                          if bTracing then
                            if 4 ~= curLayerIndex then
                              self.npcIconCreator:SetIconLayer(entryId, logicId, 4)
                            end
                          else
                            local layerIndex = BigMapUtils.GetNpcIconLayer(npcInfo, true)
                            if curLayerIndex ~= layerIndex then
                              self.npcIconCreator:SetIconLayer(entryId, logicId, layerIndex)
                            end
                          end
                        end
                      else
                        local iconData = {}
                        local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), npcPosX, npcPosY)
                        iconData.iconImagePos = {x = posX, y = posY}
                        iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
                        iconData.curMapSliderScale = 1
                        if bTracing then
                          iconData.layerIndex = 4
                        else
                          iconData.layerIndex = nil
                        end
                        iconData.bMiniMap = true
                        self:CreateNpcIcon(iconData, npcInfo)
                      end
                      if npcInfo.worldMapActivityConf then
                        local radius = npcInfo.worldMapActivityConf.radius
                        self.npcIconCreator:SetItemVisibility(self:CheckShowCircleActivityNpc(npcPosX, npcPosY, radius), BigMapModuleEnum.CreatorPriority.NpcIcons, entryId, logicId)
                      else
                        self.npcIconCreator:SetItemVisibility(true, BigMapModuleEnum.CreatorPriority.NpcIcons, entryId, logicId)
                      end
                      table.insert(self.curShowNpc, logicId)
                      self:ShowDirectionFlag(BigMapModuleEnum.CreatorPriority.NpcIcons, distance, npcInfo.entry_id, self:GetTempVector(npcPosX, npcPosY, npcPosZ), logicId)
                    elseif self.npcIconCreator:Get(npcInfo.entry_id, npcInfo.logic_id) then
                      self.npcIconCreator:Recycle(npcInfo.entry_id, npcInfo.logic_id)
                    end
                    if npcInfo.worldMapActivityConf then
                      local bShowCircle = self:CheckShowDropActivityCircle(npcPosX, npcPosY, npcInfo)
                      local activityId = npcInfo.worldMapActivityConf.id
                      if bShowCircle then
                        if not self.iconCircleCreator:Get(BigMapModuleEnum.CircleIconType.Activity, activityId) then
                          local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), npcPosX, npcPosY)
                          local iconData = {}
                          iconData.iconImagePos = {x = posX, y = posY}
                          iconData.curMapImageScale = self.imageScale.X
                          iconData.curMapSliderScale = 1
                          self:CreateCircleIcon(iconData, npcInfo)
                        end
                      else
                        self.iconCircleCreator:Destroy(BigMapModuleEnum.CircleIconType.Activity, activityId)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    else
      local npcList = self.showNpc[sceneResId]
      if npcList then
        for pieceId, npcInfos in pairs(npcList) do
          if npcInfos then
            for entryId, _npcInfo in pairs(npcInfos) do
              for logicId, npcInfo in pairs(_npcInfo) do
                if npcInfo.npc_pos then
                  local npcPosX = npcInfo.npc_pos.x
                  local npcPosY = npcInfo.npc_pos.y
                  local npcPosZ = npcInfo.npc_pos.z
                  local bShowNpc = self:CheckShowIcon(npcPosX, npcPosY, npcPosZ, npcInfo.worldMapConf)
                  local distance = self:GetDistance3D(npcPosX, npcPosY, npcPosZ)
                  local bTracing = self:CheckIsTracing(BigMapModuleEnum.TraceType.NPC, npcInfo) or self:CheckIsTracing(BigMapModuleEnum.TraceType.ForceTrace, npcInfo)
                  local bShow = bShowNpc or bTracing
                  if bShow then
                    if self.npcIconCreator:Get(npcInfo.entry_id, logicId) then
                      if npcInfo.worldMapActivityConf then
                        local radius = npcInfo.worldMapActivityConf.radius
                        self.npcIconCreator:SetItemVisibility(self:CheckShowCircleActivityNpc(npcPosX, npcPosY, radius), BigMapModuleEnum.CreatorPriority.NpcIcons, entryId, logicId)
                      else
                        self.npcIconCreator:SetItemVisibility(true, BigMapModuleEnum.CreatorPriority.NpcIcons, entryId, logicId)
                      end
                    else
                      local iconData = {}
                      local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), npcPosX, npcPosY)
                      iconData.iconImagePos = {x = posX, y = posY}
                      iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
                      iconData.curMapSliderScale = 1
                      self:CreateNpcIcon(iconData, npcInfo)
                    end
                    table.insert(self.curShowNpc, logicId)
                    self:ShowDirectionFlag(BigMapModuleEnum.CreatorPriority.NpcIcons, distance, npcInfo.entry_id, self:GetTempVector(npcPosX, npcPosY, npcPosZ), logicId)
                  else
                    self.npcIconCreator:Recycle(npcInfo.entry_id, logicId)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  if self.miniMapTraceInfo then
    NRCModuleManager:DoCmd(BigMapModuleCmd.StartOrCancelTempTrace, self.miniMapTraceInfo)
  end
end

function UMG_Minimap_C:CheckIsShowDefaultNpc(trackType, logicId)
  if self.defaultTrackNpcLogicIdList then
    return self.defaultTrackNpcLogicIdList[trackType] and self.defaultTrackNpcLogicIdList[trackType][logicId]
  end
  return false
end

function UMG_Minimap_C:UpdateDefaultNpcInfo()
  table.clear(self.defaultTrackNpcLogicIdList)
  if not self.defaultTrackNpcList then
    return
  end
  if self.defaultTrackNpcList then
    for trackType, trackList in pairs(self.defaultTrackNpcList) do
      for key, npcInfo in ipairs(trackList) do
        if npcInfo.npc_pos then
          local distance = self:GetDistance3D(npcInfo.npc_pos.x, npcInfo.npc_pos.y, npcInfo.npc_pos.z)
          npcInfo.playerDis = distance
        end
      end
    end
    for trackType, trackList in pairs(self.defaultTrackNpcList) do
      table.sort(trackList, function(leftNpcInfo, rightNpcInfo)
        if leftNpcInfo.playerDis ~= rightNpcInfo.playerDis then
          return leftNpcInfo.playerDis < rightNpcInfo.playerDis
        end
      end)
      if self.defaultTrackNpcLogicIdList[trackType] == nil then
        self.defaultTrackNpcLogicIdList[trackType] = {}
      end
      local limitNum = self.forceTraceLimit[trackType] and self.forceTraceLimit[trackType].showNum or 0
      if limitNum > 0 then
        for i = 1, limitNum - 1 do
          if trackList[i] and trackList[i].logic_id then
            self.defaultTrackNpcLogicIdList[trackType][trackList[i].logic_id] = true
          end
        end
      end
    end
  end
end

function UMG_Minimap_C:UpdateHomePetInfo()
  if self.bigMapModule == nil then
    self.bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  end
  if self.bigMapModule == nil then
    return
  end
  local homePetInfos = self.bigMapModule.data:GetHomePetNpcInfo() or {}
  if homePetInfos and #homePetInfos > 0 then
    for _, homePetInfo in ipairs(homePetInfos) do
      local entryId = homePetInfo.entry_id
      local logicId = homePetInfo.logic_id
      table.insert(self.curShowNpc, logicId)
      if self.npcIconCreator then
        local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, entryId)
        local pos = npc and npc:GetActorLocation()
        if pos then
          local iconWidget = self.npcIconCreator:Get(entryId, logicId)
          if iconWidget and UE4.UObject.IsValid(iconWidget) then
            local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), pos.x, pos.y)
            local showPos = self:GetTempVector2(posX, posY)
            self.npcIconCreator:SetIconPos(BigMapModuleEnum.CreatorPriority.NpcIcons, entryId, showPos, logicId)
          else
            local iconData = {}
            iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
            iconData.curMapSliderScale = 1
            iconData.iconTemplateIndex = 1
            iconData.layerIndex = 1
            iconData.bMiniMap = true
            local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), pos.x, pos.y)
            iconData.iconImagePos = {x = posX, y = posY}
            homePetInfo.npc_pos.x = pos.x
            homePetInfo.npc_pos.y = pos.y
            homePetInfo.npc_pos.z = pos.z
            self:CreateNpcIcon(iconData, homePetInfo)
          end
        end
      end
    end
  end
end

function UMG_Minimap_C:UpdateAreaNpcInfo()
  if self.bigMapModule == nil then
    self.bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  end
  self.showAreaNpc = self.bigMapModule:GetMinimapShowAreaNpc()
  if self.showAreaNpc and self.npcIconCreator then
    for confId, areaNpcInfo in pairs(self.showAreaNpc) do
      if areaNpcInfo and areaNpcInfo.npcList and #areaNpcInfo.npcList > 0 then
        local npcInfo = areaNpcInfo.npcList[1]
        if npcInfo.npc_pos then
          local npcPosX = npcInfo.npc_pos.x
          local npcPosY = npcInfo.npc_pos.y
          local npcPosZ = npcInfo.npc_pos.z
          local bShowNpc = self:CheckShowIcon(npcPosX, npcPosY, npcPosZ)
          local distance = self:GetDistance3D(npcPosX, npcPosY, npcPosZ)
          local bTracing = self:CheckIsTracing(BigMapModuleEnum.TraceType.NPC, npcInfo) or self:CheckIsTracing(BigMapModuleEnum.TraceType.ForceTrace, npcInfo)
          local bShow = bShowNpc or bTracing
          if bShow then
            table.insert(self.curShowNpc, npcInfo.logic_id)
            if self.npcIconCreator:Get(npcInfo.entry_id) then
              self.npcIconCreator:SetItemVisibility(true, BigMapModuleEnum.CreatorPriority.NpcIcons, npcInfo.entry_id)
            else
              local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), npcPosX, npcPosY)
              local iconData = {}
              iconData.iconImagePos = {x = posX, y = posY}
              iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
              iconData.curMapSliderScale = 1
              self:CreateNpcIcon(iconData, npcInfo)
            end
            self:ShowDirectionFlag(BigMapModuleEnum.CreatorPriority.NpcIcons, distance, npcInfo.entry_id, self:GetTempVector(npcPosX, npcPosY, npcPosZ), npcInfo.logic_id)
          else
            self.npcIconCreator:Recycle(npcInfo.entry_id)
          end
        end
      end
    end
  end
end

local ComputeItemShowTempVector = UE4.FVector()

function UMG_Minimap_C:GetTempVector(X, Y, Z)
  self.TempVector = self.TempVector or UE4.FVector(0, 0, 0)
  self.TempVector.X = X
  self.TempVector.Y = Y
  self.TempVector.Z = Z
  return self.TempVector
end

function UMG_Minimap_C:GetTempVector2(X, Y)
  self.TempVector2 = self.TempVector2 or UE4.FVector2D(0, 0)
  self.TempVector2.X = X
  self.TempVector2.Y = Y
  return self.TempVector2
end

function UMG_Minimap_C:GetTempRotation()
  self.TempRotation = self.TempRotation or UE4.FRotator(0, 0, 0)
  return self.TempRotation
end

function UMG_Minimap_C:ShowDirectionFlag(type, distance, key, iconWorldPos, extraKey)
  if distance > self.ShowHighDis then
    iconWorldPos:SubInto(self.playerPos, ComputeItemShowTempVector)
    local angleInZX = self:AngleWithUpIn3D(ComputeItemShowTempVector)
    if angleInZX <= 90 - self.ShowHighAngle or angleInZX >= 270 + self.ShowHighAngle then
      if type == BigMapModuleEnum.CreatorPriority.NpcIcons then
        self.npcIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.Up, key, extraKey)
      elseif type == BigMapModuleEnum.CreatorPriority.MarkerIcons then
        self.markerIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.Up, key)
      end
    elseif angleInZX >= 90 + self.ShowHighAngle and angleInZX <= 270 - self.ShowHighAngle then
      if type == BigMapModuleEnum.CreatorPriority.NpcIcons then
        self.npcIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.Down, key, extraKey)
      elseif type == BigMapModuleEnum.CreatorPriority.MarkerIcons then
        self.markerIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.Down, key)
      end
    elseif type == BigMapModuleEnum.CreatorPriority.NpcIcons then
      self.npcIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.None, key, extraKey)
    elseif type == BigMapModuleEnum.CreatorPriority.MarkerIcons then
      self.markerIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.None, key)
    end
  elseif type == BigMapModuleEnum.CreatorPriority.NpcIcons then
    self.npcIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.None, key, extraKey)
  elseif type == BigMapModuleEnum.CreatorPriority.MarkerIcons then
    self.markerIconCreator:SetUpOrDown(type, BigMapModuleEnum.IconDirection.None, key)
  end
end

function UMG_Minimap_C:AngleWithUpIn3D(a)
  local cosine = a.Z / a:Size()
  local angle = math.deg(math.acos(cosine))
  if a.X >= 0 then
    return angle
  else
    return 360 - angle
  end
end

function UMG_Minimap_C:CheckShowIcon(posX, posY, posZ, worldMapConf)
  local dis = self:GetDistance2D(posX, posY)
  local showhDis = 0
  local showvDis = 0
  if worldMapConf then
    local hDis = (self.DetectLimitH[worldMapConf.h_detection_range] or DataConfigManager:GetMapGlobalConfig(worldMapConf.h_detection_range).num) * 100
    local vDis = (self.DetectLimitV[worldMapConf.v_detection_range] or DataConfigManager:GetMapGlobalConfig(worldMapConf.v_detection_range).num) * 100
    if hDis > 0 then
      showhDis = math.min(hDis, self.innerRadius)
    else
      showhDis = self.innerRadius
    end
    if vDis > 0 then
      showvDis = vDis
    end
  else
    showhDis = self.innerRadius
  end
  if showvDis > 0 then
    if dis <= showhDis and showvDis >= math.abs(posZ - self.playerPos.Z) then
      return true
    end
  elseif dis <= showhDis then
    return true
  end
  return false
end

function UMG_Minimap_C:CheckIsTracing(type, typeInfo)
  if not typeInfo then
    return false
  end
  if type == BigMapModuleEnum.TraceType.NPC then
    if self.curTraceInfoList and self.curTraceInfoList[type] and self.curTraceInfoList[type].npcInfo.entry_id == typeInfo.entry_id and self.curTraceInfoList[type].npcInfo.logic_id == typeInfo.logic_id then
      return true
    end
    if typeInfo.worldMapConf and typeInfo.worldMapConf.default_track_type == Enum.DefaultTrackType.DTT_NONE and typeInfo.worldMapConf.default_track and self:CheckDefaultTrackShow(typeInfo) then
      local hasSameNPC = false
      for _, traceInfo in pairs(self.miniMapTraceInfo) do
        if traceInfo.traceType == BigMapModuleEnum.TraceType.NPC and traceInfo.npcInfo.entry_id == typeInfo.entry_id then
          hasSameNPC = true
          break
        end
      end
      if false == hasSameNPC then
        local traceInfo = {
          traceType = BigMapModuleEnum.TraceType.TempTrace,
          npcInfo = typeInfo
        }
        table.insert(self.miniMapTraceInfo, traceInfo)
        if typeInfo.worldMapConf.default_track_worldmap then
          local logicId = traceInfo.npcInfo.logic_id
          if logicId then
            local has = NRCModuleManager:DoCmd(BigMapModuleCmd.CheckAutoTracking, logicId)
            if not has then
              NRCModuleManager:DoCmd(BigMapModuleCmd.OnZoneSceneWorldMapSyncAutoTrackNpcReq, traceInfo.npcInfo.logic_id)
            end
          end
        end
      end
      return true
    end
    return false
  elseif type == BigMapModuleEnum.TraceType.Marker then
    if self.curTraceInfoList and self.curTraceInfoList[type] and self.curTraceInfoList[type].markInfo.mark_id == typeInfo.mark_id then
      return true
    end
    return false
  elseif type == BigMapModuleEnum.TraceType.Task then
    if typeInfo.taskShowType == BigMapModuleEnum.TaskShowType.TRACING then
      return true
    end
    return false
  elseif type == BigMapModuleEnum.TraceType.ForceTrace then
    local trackType = typeInfo.worldMapConf and typeInfo.worldMapConf.default_track_type or 0
    if self.curTraceInfoList and self.curTraceInfoList[type] and self.curTraceInfoList[type][trackType] and #self.curTraceInfoList[type][trackType] > 0 then
      for k, traceInfo in ipairs(self.curTraceInfoList[type][trackType]) do
        if traceInfo.npcInfo.logic_id == typeInfo.logic_id then
          return true
        end
      end
    end
  else
    return false
  end
end

function UMG_Minimap_C:CheckShowNpcTraceEffect(worldMapConf)
  if worldMapConf and worldMapConf.default_track_type == Enum.DefaultTrackType.DTT_NONE and worldMapConf.default_track then
    return worldMapConf.default_track_loop
  end
  return true
end

function UMG_Minimap_C:CheckShowDropActivityCircle(posX, posY, npcInfo)
  if npcInfo.worldMapActivityConf then
    local dis = self:GetDistance2D(posX, posY)
    local showDistance = self.innerRadius + npcInfo.worldMapActivityConf.radius
    if dis <= showDistance then
      return true
    else
      return false
    end
  end
  return false
end

function UMG_Minimap_C:CheckDefaultTrackShow(npcInfo)
  local vDis = (self.DetectLimitV[npcInfo.worldMapConf.v_detection_range] or DataConfigManager:GetMapGlobalConfig(npcInfo.worldMapConf.v_detection_range).num) * 100
  local hDis = (self.DetectLimitH[npcInfo.worldMapConf.h_detection_range] or DataConfigManager:GetMapGlobalConfig(npcInfo.worldMapConf.h_detection_range).num) * 100
  local posX = npcInfo.npc_pos.x
  local posY = npcInfo.npc_pos.y
  local posZ = npcInfo.npc_pos.z
  local dis = self:GetDistance2D(posX, posY)
  if hDis > 0 then
    if hDis >= dis then
      if vDis > 0 then
        if vDis >= math.abs(posZ - self.playerPos.Z) then
          return true
        else
          return false
        end
      end
      return true
    else
      return false
    end
  end
  return false
end

local curTaskList = {}

function UMG_Minimap_C:RecycleTaskIcon(taskObject)
  if taskObject then
    if self.taskIconCreator then
      local Icons = self.taskIconCreator:Get(taskObject.Config.id)
      if Icons then
        for k, v in pairs(Icons) do
          if v and UE4.UObject.IsValid(v) and taskObject:CheckConditionDone(k) then
            self.taskIconCreator:DestroyBySubTaskId(taskObject.Config.id, k)
          end
        end
      end
    end
  else
    if self.taskIconCreator then
      curTaskList = self.taskIconCreator:GetAllTaskId()
      if curTaskList then
        for subTaskId, goIndexList in pairs(curTaskList) do
          for key, goIndex in pairs(goIndexList) do
            local bShow = false
            for k, taskInfo in pairs(self.tracingTaskList) do
              if taskInfo.subTaskId == subTaskId and taskInfo.goIndex == goIndex then
                bShow = true
                goto lbl_93
              end
            end
            if self.acceptTaskList[subTaskId] then
              bShow = true
            end
            if false == bShow then
              Log.Debug("UMG_Minimap_C:RecycleTaskIcon Recycle ", subTaskId, goIndex)
              self.taskIconCreator:DestroyBySubTaskId(subTaskId, goIndex)
            end
            ::lbl_93::
          end
        end
      end
    end
    table.clear(curTaskList)
    table.clear(self.curShowTaskList)
  end
end

function UMG_Minimap_C:RecycleNpcIcon()
  if self.npcIconCreator then
    local curNpcIconList = self.npcIconCreator:GetAllLogicId()
    local list1, needDelList = table.diff(self.curShowNpc, curNpcIconList)
    if needDelList then
      for k, logicId in pairs(needDelList) do
        self.npcIconCreator:Recycle(self.npcIconCreator:GetEntryIdByLogicId(logicId), logicId)
      end
    end
  end
end

function UMG_Minimap_C:GetDistance2D(posX, posY)
  local deltaX = posX - self.playerPos.X
  local deltaY = posY - self.playerPos.Y
  return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function UMG_Minimap_C:GetDistance3D(posX, posY, posZ)
  local deltaX = (posX - self.playerPos.X) / 100
  local deltaY = (posY - self.playerPos.Y) / 100
  local deltaZ = (posZ - self.playerPos.Z) / 100
  return (deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ) ^ 1 / 3
end

function UMG_Minimap_C:GetImageDistance(imagePosX, imagePosY)
  local deltaX = imagePosX - self.centerPosX
  local deltaY = imagePosY - self.centerPosY
  return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function UMG_Minimap_C:UpdateTraceNpc()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if nil == bigMapModule then
    return
  end
  self.curTraceInfoList = bigMapModule:GetCurTraceInfoList()
end

function UMG_Minimap_C:UpdateMarkInfo(markerInfo)
  if self.bigMapModule == nil then
    self.bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  end
  if self.bigMapModule and self.data then
    local CustomPointInfo = self.data:GetNewCustomPointInfo()
    for k, point in ipairs(CustomPointInfo) do
      local pointX = point.pos.x
      local pointY = point.pos.y
      local pointZ = point.pos.z
      local markerSceneResId = BigMapUtils.GetSceneResIdByPos(pointX, pointY)
      local bInRange = self:CheckShowIcon(pointX, pointY, pointZ)
      local bTracing = self:CheckIsTracing(BigMapModuleEnum.TraceType.Marker, point)
      if markerSceneResId == SceneUtils.GetSceneResId() then
        if bInRange or bTracing then
          point.index = k
          local markId = point.mark_id
          if self.markerIconCreator then
            if self.markerIconCreator:Get(markId) then
              local itemData = self.markerIconCreator:GetItemData(markId)
              if itemData then
                local curLayerIndex = itemData.iconData.layerIndex
                if bTracing then
                  self.markerIconCreator:SetTraceEffect(bTracing, markId)
                  if 4 ~= curLayerIndex then
                    self.markerIconCreator:SetIconLayer(markId, 4)
                  end
                else
                  local layerIndex = 3
                  if curLayerIndex ~= layerIndex then
                    self.markerIconCreator:SetIconLayer(markId, layerIndex)
                  end
                end
              end
            else
              local iconData = {}
              iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
              iconData.curMapSliderScale = 1
              iconData.iconTemplateIndex = 1
              if bTracing then
                iconData.layerIndex = 4
              else
                iconData.layerIndex = 3
              end
              iconData.bTracing = bTracing
              self:CreateMarkerIcon(iconData, point)
            end
          end
          local distance = self:GetDistance3D(pointX, pointY, pointZ)
          self:ShowDirectionFlag(BigMapModuleEnum.CreatorPriority.MarkerIcons, distance, markId, self:GetTempVector(pointX, pointY, pointZ))
        else
          self.markerIconCreator:Recycle(point.mark_id)
        end
      end
    end
  end
end

local visitorIconData = {}

function UMG_Minimap_C:UpdateVisitorInfo()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if nil == bigMapModule then
    return
  end
  local VisitPointInfo = bigMapModule.data:GetVisitPointInfo() or {}
  if VisitPointInfo then
    visitorIconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
    visitorIconData.curMapSliderScale = 1
    visitorIconData.iconTemplateIndex = 1
    visitorIconData.layerIndex = 4
    visitorIconData.bMiniMap = true
    self:CreateVisitorIcon(visitorIconData, VisitPointInfo)
  end
end

local TempIconData = {
  iconImagePos = {}
}
local TempTaskInfo = {}

function UMG_Minimap_C:GetTempIconData()
  return TempIconData
end

function UMG_Minimap_C:GetTempTaskInfo(taskId, taskShowType, SubTaskId, goIndex)
  TempTaskInfo.taskId = taskId
  TempTaskInfo.taskShowType = taskShowType
  TempTaskInfo.SubTaskId = SubTaskId
  TempTaskInfo.go_index = goIndex
  return TempTaskInfo
end

function UMG_Minimap_C:UpdateTaskInfo()
  if self.acceptTaskList == nil then
    self.acceptTaskList = {}
  end
  table.clear(self.acceptTaskList)
  local sceneResId = SceneUtils.GetSceneResId()
  local showTaskList = self.data:GetAccessTaskInfoList()
  if showTaskList and #showTaskList > 0 then
    for k, v in ipairs(showTaskList) do
      if v.TaskSceneResId ~= sceneResId or v.TaskShowType == BigMapModuleEnum.TaskShowType.TRACING then
      elseif v.TaskShowType == BigMapModuleEnum.TaskShowType.ACCEPTED then
      elseif v.TaskShowType == BigMapModuleEnum.TaskShowType.UNDO then
        local iconData = {}
        iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
        iconData.curMapSliderScale = 1
        iconData.iconTemplateIndex = 1
        iconData.layerIndex = 2
        iconData.showTaskType = BigMapModuleEnum.TaskShowType.UNDO
        local taskPosX, taskPosY = BigMapUtils.ScenePosToImagePosF(sceneResId, v.NpcPosition[1].pos.x, v.NpcPosition[1].pos.y)
        iconData.iconImagePos = {x = taskPosX, y = taskPosY}
        local taskInfo = {
          taskId = v.TaskConf.id,
          taskShowType = v.TaskShowType,
          SubTaskId = v.TaskConf.id,
          go_index = 1
        }
        taskInfo.iconImagePos = iconData.iconImagePos
        self.acceptTaskList[v.TaskConf.id] = taskInfo
        self:SetCurShowTaskList(taskInfo)
        self:CreateTaskIcon(iconData, taskInfo)
      end
    end
  end
end

function UMG_Minimap_C:UpdateTreasureActivityInfo()
  local treasureIconList = {}
  if self.data and self.data.MapActivityInfoMap then
    for group, mapActivityInfoMap in pairs(self.data.MapActivityInfoMap) do
      for i, mapActivityInfo in ipairs(mapActivityInfoMap) do
        local iconData = {}
        iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
        iconData.curMapSliderScale = 1
        iconData.iconTemplateIndex = 2
        iconData.layerIndex = 1
        local activityConf = mapActivityInfo.WorldMapConf
        local areaCfg = _G.DataConfigManager:GetAreaConf(activityConf.name_area_id)
        local posX, posY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), areaCfg.center_xyz[1], areaCfg.center_xyz[2])
        iconData.iconImagePos = {x = posX, y = posY}
        local areaInfo = {}
        areaInfo.config = activityConf
        areaInfo.cfgPosX = areaCfg.center_xyz[1]
        areaInfo.cfgPosY = areaCfg.center_xyz[2]
        areaInfo.bActivity = true
        self:CreateMapAreaNameIcon(iconData, areaInfo)
        local areaID = areaInfo.config.name_area_id
        if areaID then
          table.insert(treasureIconList, areaID)
        end
      end
    end
  end
  self:ClearTreasureIcon(treasureIconList)
end

function UMG_Minimap_C:UpdateTraceIconPosition()
  self:UpdateTraceNpc()
  if self.curTraceInfoList then
    for traceType, traceInfo in pairs(self.curTraceInfoList) do
      if traceType == BigMapModuleEnum.TraceType.Task or traceType == BigMapModuleEnum.TraceType.Visitor then
        if traceInfo then
          for k, v in pairs(traceInfo) do
            self:SetTraceIconPos(traceType, v, true)
          end
        end
      elseif traceType == BigMapModuleEnum.TraceType.ForceTrace then
        if traceInfo then
          for trackType, traceList in pairs(traceInfo) do
            if traceList and #traceList > 0 then
              for _, v in ipairs(traceList) do
                self:SetTraceIconPos(traceType, v, true)
              end
            end
          end
        end
      else
        self:SetTraceIconPos(traceType, traceInfo, true)
      end
    end
  end
  if self.miniMapTraceInfo then
    for k, traceInfo in ipairs(self.miniMapTraceInfo) do
      if (traceInfo.traceType == BigMapModuleEnum.TraceType.NPC or traceInfo.traceType == BigMapModuleEnum.TraceType.TempTrace) and traceInfo.npcInfo then
        local worldMapConf = traceInfo.npcInfo.worldMapConf
        if worldMapConf then
          self:SetTraceIconPos(traceInfo.traceType, traceInfo, worldMapConf.default_track_loop)
        end
      else
        self:SetTraceIconPos(traceInfo.traceType, traceInfo, false)
      end
    end
  end
  self:RecycleNpcIcon()
end

function UMG_Minimap_C:UpdateTraceTask()
  if self.tracingTaskList == nil then
    self.tracingTaskList = {}
  end
  table.clear(self.tracingTaskList)
  local TrackingTask = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.GetDataTrackTask)
  local CurTaskIconCircleList = {}
  local bDiffTraceTask = false
  if TrackingTask and TrackingTask.Trackers then
    local taskId = TrackingTask.Config.id
    if self.CurrentTrackingTaskId ~= taskId then
      bDiffTraceTask = true
      self.CurrentTrackingTaskId = taskId
    end
    for key, trackItem in pairs(TrackingTask.Trackers) do
      if trackItem.TargetInSameSceneGroup and trackItem:GetMinimapValid() == true and trackItem:NeedTrackInMiniGame() then
        local taskPosX, taskPosY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), trackItem.Position.X, trackItem.Position.Y)
        local subTaskId = trackItem.TaskConfig.id
        local goIndex = trackItem.go_index or 1
        table.insert(self.tracingTaskList, {
          taskId = taskId,
          subTaskId = subTaskId,
          goIndex = goIndex
        })
        if self.taskIconCreator then
          local taskInfo = self:GetTempTaskInfo(taskId, BigMapModuleEnum.TaskShowType.TRACING, subTaskId, goIndex)
          local taskIcon = self.taskIconCreator:GetMap(taskId, subTaskId, goIndex)
          if not taskInfo or not UE4.UObject.IsValid(taskIcon) then
            taskIcon = self.taskIconCreator:Get(subTaskId, goIndex)
          end
          local taskImagePosX = taskPosX
          local taskImagePosY = taskPosY
          local dis = self:GetImageDistance(taskImagePosX, taskImagePosY)
          local dirX = taskImagePosX - self.centerPosX
          local dirY = taskImagePosY - self.centerPosY
          if dis > 0 then
            dirX = dirX / dis
            dirY = dirY / dis
          end
          local displayRadius = (self.curWndSize.X / 2 + self.tracePixel) / self.imageScale.X
          local showPosX, showPosY
          if dis <= displayRadius then
            showPosX = taskImagePosX
            showPosY = taskImagePosY
          else
            showPosX = self.centerPosX + dirX * displayRadius
            showPosY = self.centerPosY + dirY * displayRadius
          end
          TaskPosCache.X = showPosX
          TaskPosCache.Y = showPosY
          local showPos = TaskPosCache
          if taskIcon and UE4.UObject.IsValid(taskIcon) then
            self.taskIconCreator:SetIconPosNew(taskId, subTaskId, goIndex, showPos)
            local itemData = self.taskIconCreator:GetItemData(taskId, subTaskId, goIndex)
            if itemData then
              if itemData.iconData.showTaskType ~= BigMapModuleEnum.TaskShowType.TRACING then
                local iconData = {}
                iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
                iconData.curMapSliderScale = 1
                iconData.iconTemplateIndex = 1
                iconData.iconImagePos = {x = taskPosX, y = taskPosY}
                iconData.layerIndex = 4
                iconData.showTaskType = BigMapModuleEnum.TaskShowType.TRACING
                self.taskIconCreator:Refresh(iconData, taskInfo)
              end
              local curLayerIndex = itemData.iconData.layerIndex
              if 4 ~= curLayerIndex then
                self.taskIconCreator:SetIconLayer(taskId, subTaskId, goIndex, 4)
              end
            end
          else
            do
              local iconData = {}
              iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
              iconData.curMapSliderScale = 1
              iconData.iconTemplateIndex = 1
              iconData.iconImagePos = {
                x = TaskPosCache.X,
                y = TaskPosCache.Y
              }
              iconData.layerIndex = 4
              iconData.showTaskType = BigMapModuleEnum.TaskShowType.TRACING
              self:CreateTaskIcon(iconData, taskInfo)
            end
          end
          for Index, Value in ipairs(trackItem.TaskConfig.go_guide) do
            if Value.type == _G.Enum.TaskGoActionType.TGAT_NPC_CIRCLE and trackItem.HasArrived then
              local Finish = trackItem:IsCheckConditionDone(Index)
              if not Finish then
                local IconCircle = self.iconCircleCreator:Get(BigMapModuleEnum.CircleIconType.Task, trackItem.TaskConfig.id, Index)
                if not IconCircle then
                  local IconData = {}
                  IconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
                  IconData.curMapSliderScale = 1
                  IconData.iconTemplateIndex = 1
                  IconData.iconImagePos = {x = taskPosX, y = taskPosY}
                  IconData.layerIndex = 3
                  local CircleInfo = {}
                  CircleInfo.showType = BigMapModuleEnum.CircleIconType.Task
                  CircleInfo.typeId = trackItem.TaskConfig.id
                  CircleInfo.circleRadius = Value.data2[1]
                  CircleInfo.showScale = _G.Enum.MapElementScale.ESCALE_ALL
                  CircleInfo.extraId = Index
                  self.iconCircleCreator:Create(IconData, CircleInfo)
                  if self:GetImageDistance(taskPosX, taskPosY) <= CircleInfo.circleRadius * self.imageToSceneScale * self.imageScale.X then
                    self.taskIconCreator:SetItemVisibility(false, BigMapModuleEnum.CreatorPriority.TaskIcons, trackItem.TaskConfig.id)
                  else
                    self.taskIconCreator:SetItemVisibility(true, BigMapModuleEnum.CreatorPriority.TaskIcons, trackItem.TaskConfig.id)
                  end
                else
                  local IconCircleData = self.iconCircleCreator:GetData(BigMapModuleEnum.CircleIconType.Task, trackItem.TaskConfig.id, Index)
                  if IconCircleData and IconCircleData.iconImagePos then
                    local DeltaX = taskPosX - IconCircleData.iconImagePos.x
                    local DeltaY = taskPosY - IconCircleData.iconImagePos.y
                    if DeltaX * DeltaX + DeltaY * DeltaY >= 10000 then
                      self.iconCircleCreator:RefreshIconPos({x = taskPosX, y = taskPosY}, BigMapModuleEnum.CircleIconType.Task, trackItem.TaskConfig.id, Index)
                      local TaskPos = UE4.FVector2D(taskPosX, taskPosY)
                      if IconCircle.Slot then
                        IconCircle.Slot:SetPosition(TaskPos)
                      end
                    end
                  end
                  if self:GetImageDistance(taskPosX, taskPosY) <= Value.data2[1] * self.imageToSceneScale * self.imageScale.X then
                    self.taskIconCreator:SetItemVisibility(false, BigMapModuleEnum.CreatorPriority.TaskIcons, trackItem.TaskConfig.id)
                  else
                    self.taskIconCreator:SetItemVisibility(true, BigMapModuleEnum.CreatorPriority.TaskIcons, trackItem.TaskConfig.id)
                  end
                end
                if not self.CurTrackIconCircleList[trackItem.TaskConfig.id] then
                  self.CurTrackIconCircleList[trackItem.TaskConfig.id] = {}
                end
                self.CurTrackIconCircleList[trackItem.TaskConfig.id][Index] = true
                if not CurTaskIconCircleList[trackItem.TaskConfig.id] then
                  CurTaskIconCircleList[trackItem.TaskConfig.id] = {}
                end
                CurTaskIconCircleList[trackItem.TaskConfig.id][Index] = true
              end
            end
          end
        end
      else
        local subTaskId = trackItem.TaskConfig.id
        local goIndex = trackItem.go_index or 1
        self.taskIconCreator:DestroyBySubTaskId(subTaskId, goIndex)
      end
    end
  else
    if self.CurrentTrackingTaskId then
      bDiffTraceTask = true
    end
    self.CurrentTrackingTaskId = nil
  end
  for taskId, indexList in pairs(self.CurTrackIconCircleList) do
    for index, _ in pairs(indexList) do
      if not CurTaskIconCircleList[taskId] or not CurTaskIconCircleList[taskId][index] then
        self.iconCircleCreator:Destroy(BigMapModuleEnum.CircleIconType.Task, taskId, index)
        self.CurTrackIconCircleList[taskId][index] = nil
      end
    end
  end
  if bDiffTraceTask then
    self:RecycleTaskIcon()
  end
end

function UMG_Minimap_C:SetTraceIconPos(traceType, traceInfo, bShowEffect)
  if traceType ~= BigMapModuleEnum.TraceType.Visitor then
    if traceInfo.sceneResId and traceInfo.sceneResId > 0 and traceInfo.sceneResId ~= SceneUtils.GetSceneResId() then
      return
    end
  else
    local sceneResId = 0
    if BigMapUtils.IsBigWorldMap(SceneUtils.GetSceneResId()) then
      sceneResId = traceInfo.sceneResId
    else
      sceneResId = traceInfo.visitorInfo.visitorInfo.scene_res_id or traceInfo.sceneResId
    end
    if sceneResId and sceneResId > 0 and sceneResId ~= SceneUtils.GetSceneResId() then
      if self.visitorIconCreator and traceInfo.visitorInfo and traceInfo.visitorInfo.visitorInfo then
        self.visitorIconCreator:Destroy(traceInfo.visitorInfo.visitorInfo.uin)
      end
      return
    end
  end
  if traceType == BigMapModuleEnum.TraceType.NPC or traceType == BigMapModuleEnum.TraceType.TempTrace or traceType == BigMapModuleEnum.TraceType.ForceTrace then
    if traceInfo.npcInfo then
      local entryId = traceInfo.npcInfo.entry_id
      local logicId = traceInfo.npcInfo.logic_id
      if self.npcIconCreator and 0 ~= entryId then
        table.insert(self.curShowNpc, logicId)
        local npcImagePosX, npcImagePosY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), traceInfo.npcInfo.npc_pos.x, traceInfo.npcInfo.npc_pos.y)
        local dis = self:GetImageDistance(npcImagePosX, npcImagePosY)
        local k = self:GetTraceK(dis)
        local showPos = FVector2DUtils.Lerp(UE4.FVector2D(self.centerPosX, self.centerPosY), UE4.FVector2D(npcImagePosX, npcImagePosY), k)
        if self.npcIconCreator:Get(entryId, logicId) then
          self.npcIconCreator:SetIconPos(BigMapModuleEnum.CreatorPriority.NpcIcons, entryId, showPos, logicId)
          self.npcIconCreator:UpdateItemDataImagePos(entryId, logicId, showPos.X, showPos.Y)
          if bShowEffect then
            self.npcIconCreator:SetTraceEffect(true, entryId, logicId)
          end
        else
          local iconData = {}
          iconData.iconImagePos = {
            x = showPos.X,
            y = showPos.Y
          }
          iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
          iconData.curMapSliderScale = 1
          iconData.layerIndex = 4
          self:CreateNpcIcon(iconData, traceInfo.npcInfo)
          if bShowEffect then
            self.npcIconCreator:SetTraceEffect(true, entryId, logicId)
          end
        end
      end
    end
  elseif traceType == BigMapModuleEnum.TraceType.Marker then
    if traceInfo.markInfo then
      local markId = traceInfo.markInfo.mark_id
      if self.markerIconCreator then
        local markImagePosX, markImagePosY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), traceInfo.markInfo.pos.x, traceInfo.markInfo.pos.y)
        local dis = self:GetImageDistance(markImagePosX, markImagePosY)
        local k = (self.curWndSize.X / 2 - 20) / dis / self.imageScale.X
        local showPos = FVector2DUtils.Lerp(UE4.FVector2D(self.centerPosX, self.centerPosY), UE4.FVector2D(markImagePosX, markImagePosY), k)
        if self.markerIconCreator:Get(markId) then
          self.markerIconCreator:SetIconPos(BigMapModuleEnum.CreatorPriority.MarkerIcons, markId, showPos)
          self.markerIconCreator:SetTraceEffect(true, markId)
        else
          local iconData = {}
          iconData.iconImagePos = {
            x = showPos.X,
            y = showPos.Y
          }
          iconData.curMapImageScale = 1 / self.iconScale * self.imageScale.X
          iconData.curMapSliderScale = 1
          iconData.layerIndex = 3
          iconData.iconTemplateIndex = 1
          self:CreateMarkerIcon(iconData, traceInfo.markInfo)
          self.markerIconCreator:SetTraceEffect(true, markId)
        end
      end
    end
  elseif traceType == BigMapModuleEnum.TraceType.Task then
    local taskInfo = traceInfo.taskInfo
    local taskId = traceInfo.taskId
    if taskId then
      local goIndex = taskInfo.go_index
      if self.taskIconCreator and taskId > 0 and self:GetTaskType(taskId) == BigMapModuleEnum.TaskShowType.ACCEPTED then
        local taskIcon = self.taskIconCreator:Get(taskId, goIndex)
        if taskIcon and UE4.UObject.IsValid(taskIcon) then
          local taskImagePosX = traceInfo.iconImagePos.x
          local taskImagePosY = traceInfo.iconImagePos.y
          local dis = self:GetImageDistance(taskImagePosX, taskImagePosY)
          local k = (self.curWndSize.X / 2 - 20) / dis / self.imageScale.X
          local showPos = FVector2DUtils.Lerp(UE4.FVector2D(self.centerPosX, self.centerPosY), UE4.FVector2D(taskImagePosX, taskImagePosY), k)
          self.taskIconCreator:SetIconPos(BigMapModuleEnum.CreatorPriority.TaskIcons, taskId, showPos)
        end
      end
    end
  elseif traceType == BigMapModuleEnum.TraceType.Visitor then
    local _visitorInfo = traceInfo.visitorInfo
    if _visitorInfo then
      local uin = _visitorInfo.visitorInfo.uin or 0
      if self.visitorIconCreator and uin > 0 then
        local sceneResId = _visitorInfo.visitorInfo.scene_res_id or SceneUtils.GetSceneResId()
        local bUnlock = NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, sceneResId)
        local posX = 0
        local posY = 0
        if bUnlock or sceneResId == SceneUtils.GetSceneResId() then
          if _visitorInfo.visitorInfo.pos then
            posX = _visitorInfo.visitorInfo.pos.pos.x
            posY = _visitorInfo.visitorInfo.pos.pos.y
          end
        elseif _visitorInfo.visitorInfo.main_scene_pt then
          posX = _visitorInfo.visitorInfo.main_scene_pt.pos.x
          posY = _visitorInfo.visitorInfo.main_scene_pt.pos.y
        end
        if _visitorInfo.visitorInfo.pos then
          local visitorImagePosX, visitorImagePosY = BigMapUtils.ScenePosToImagePosF(SceneUtils.GetSceneResId(), posX, posY)
          local dis = self:GetImageDistance(visitorImagePosX, visitorImagePosY)
          local k = self:GetTraceK(dis)
          local showPos = FVector2DUtils.Lerp(UE4.FVector2D(self.centerPosX, self.centerPosY), UE4.FVector2D(visitorImagePosX, visitorImagePosY), k)
          if self.visitorIconCreator:Get(uin) then
            self.visitorIconCreator:SetIconPos(BigMapModuleEnum.CreatorPriority.VisitorIcons, uin, showPos)
          else
            self:UpdateVisitorInfo()
          end
        end
      end
    end
  end
end

function UMG_Minimap_C:UpdateIconScale()
  local curMapImageScale = 1 / self.iconScale * self.imageScale.X
  local renderScale = 1.0 / (curMapImageScale or 1)
  if self.taskIconCreator then
    self.taskIconCreator:UpdateIconScale(self:GetTempVector2(renderScale, renderScale))
  end
  if self.visitorIconCreator then
    self.visitorIconCreator:UpdateIconScale(self:GetTempVector2(renderScale, renderScale))
  end
  if self.npcIconCreator then
    self.npcIconCreator:UpdateIconScale(self:GetTempVector2(renderScale, renderScale))
  end
  if self.markerIconCreator then
    self.markerIconCreator:UpdateIconScale(self:GetTempVector2(renderScale, renderScale))
  end
  if self.mapLayerCreator then
  end
end

function UMG_Minimap_C:ClearMapImage()
  if self.mapList and #self.mapList > 0 then
    for k, v in ipairs(self.mapList) do
      v:SetPath("")
    end
  end
end

function UMG_Minimap_C:ClearMarkerIcon()
  if self.markerIconCreator then
    self.markerIconCreator:ClearAll()
  end
end

function UMG_Minimap_C:ClearIcons()
  for k, v in pairs(self.creatorList) do
    if v.ClearAll then
      v:ClearAll()
    end
  end
end

function UMG_Minimap_C:ClearCache()
  self:ClearMapImage()
  self:ClearIcons()
  self.lastShowPieceIdList = {}
  self.curShowPieceIdList = {}
  self.lastShowLayerId = 0
end

function UMG_Minimap_C:GetTaskType(taskId)
  local TrackingTask = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.GetTrackTask)
  if TrackingTask and TrackingTask.Trackers then
    for key, trackItem in pairs(TrackingTask.Trackers) do
      if trackItem.TargetInSameSceneGroup and trackItem.TaskConfig.id == taskId then
        return BigMapModuleEnum.TaskShowType.TRACING
      end
    end
  end
  return BigMapModuleEnum.TaskShowType.ACCEPTED
end

function UMG_Minimap_C:CheckShowCircleActivityNpc(posX, posY, radius)
  local dis = self:GetDistance2D(posX, posY)
  if radius < dis then
    return true
  else
    return false
  end
end

function UMG_Minimap_C:ChangeMinimapState(state)
  if state == MainUIModuleEnum.MinimapOrCompassState.Normal then
    self:SetHiddenSwitcherVisible(false)
    self:StopAnimation(self.Stealth)
  elseif state == MainUIModuleEnum.MinimapOrCompassState.Hidden then
    self:SetHiddenSwitcherVisible(true)
    self.Switcher_Stealth:SetActiveWidgetIndex(2)
    self:StopAnimation(self.Stealth)
  elseif state == MainUIModuleEnum.MinimapOrCompassState.Hidden_Exposed then
    self:SetHiddenSwitcherVisible(true)
    self.Switcher_Stealth:SetActiveWidgetIndex(1)
    self:PlayAnimation(self.Stealth, 0, 0)
  elseif state == MainUIModuleEnum.MinimapOrCompassState.Hidden_Attacked then
    self:SetHiddenSwitcherVisible(true)
    self.Switcher_Stealth:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.Stealth, 0, 0)
  else
    self:SetHiddenSwitcherVisible(false)
    self:StopAnimation(self.Stealth)
  end
end

function UMG_Minimap_C:SetHiddenSwitcherVisible(bVisible)
  if bVisible then
    self.Switcher_Stealth:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Switcher_Stealth:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Minimap_C

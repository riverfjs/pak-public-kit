local FVector2DUtils = require("NewRoco.Utils.FVector2DUtils")
local TeamBattleModuleEnum = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEnum")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local bigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local GetFrameCount = _ENV.GetFrameCount
local FPointerEvent_GetCursorDelta = _ENV.FPointerEvent_GetCursorDelta
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local MapItemNPC = require("NewRoco/Modules/System/BigMap/Res/MapItemNPC")
local MapItemAreaName = require("NewRoco/Modules/System/BigMap/Res/MapItemAreaName")
local MapItemTask = require("NewRoco/Modules/System/BigMap/Res/MapItemTask")
local MapItemMarker = require("NewRoco/Modules/System/BigMap/Res/MapItemMarker")
local MapItemTrace = require("NewRoco/Modules/System/BigMap/Res/MapItemTrace")
local MapItemVisitor = require("NewRoco/Modules/System/BigMap/Res/MapItemVisitor")
local MapItemPic = require("NewRoco/Modules/System/BigMap/Res/MapItemPic")
local MapItemMask = require("NewRoco/Modules/System/BigMap/Res/MapItemMask")
local MapItemLayerMap = require("NewRoco/Modules/System/BigMap/Res/MapItemLayerMap")
local MapItemCircle = require("NewRoco/Modules/System/BigMap/Res/MapItemCircle")
local MapItemCreator = require("NewRoco/Modules/System/BigMap/Res/MapItemCreator")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local UMG_MainMap_C = _G.NRCPanelBase:Extend("UMG_MainMap_C")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local TravelModuleEvent = reload("NewRoco.Modules.System.Travel.TravelModuleEvent")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")

function UMG_MainMap_C:OnConstruct()
  self.traceCount = 0
  self.bOpen = true
  self.bMouseInMapScope = false
  self.CurTrackTaskPosList = {}
  self.data = self.module:GetData("BigMapModuleData")
  self.data:CreateShowTaskInfo()
  self.uiData = {}
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.World = _G.UE4Helper.GetCurrentWorld()
  self.DpiScaleY = 1
  self.bClosing = false
  self:SetTargetPos(0, 0)
  self:SetRenderOpacity(0)
  self.curWndSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.NPCRefreshConfig = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_REFRESH_BONUS_CONF):GetAllDatas()
  self:SetChildViews(self.npcList)
  local db = _G.DataConfigManager:GetGlobalConfigByKeyType("ui_audio_reduction_db", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  UE4.UNRCAudioManager.SetWorldListenerVolumeOffset(db)
  self:InitDataBySceneResId(SceneUtils.GetSceneResId(), true)
  self.iconScale = _G.DataConfigManager:GetMapGlobalConfig("main_map_icon_resource_scale").num / 10000
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
  self.mapMaskList = {
    self.Mask1,
    self.Mask2,
    self.Mask3,
    self.Mask4,
    self.Mask5,
    self.Mask6,
    self.Mask7,
    self.Mask8,
    self.Mask9,
    self.Mask10,
    self.Mask11,
    self.Mask12,
    self.Mask13,
    self.Mask14,
    self.Mask15,
    self.Mask16
  }
  self.maskDynamicMaterialList = {
    self.Mask1Material,
    self.Mask2Material,
    self.Mask3Material,
    self.Mask4Material,
    self.Mask5Material,
    self.Mask6Material,
    self.Mask7Material,
    self.Mask8Material,
    self.Mask9Material,
    self.Mask10Material,
    self.Mask11Material,
    self.Mask12Material,
    self.Mask13Material,
    self.Mask14Material,
    self.Mask15Material,
    self.Mask16Material
  }
  self.uiItem = {
    taskIcons = {},
    kingIcons = {},
    npcIcons = {},
    npcIconPool = {},
    mapAreaIcons = {},
    CustomMarker = {},
    VisitPoint = {},
    habitatIcons = {},
    TempTraceIcons = {}
  }
  self.vector2DZero = UE4.FVector2D(0, 0)
  self.tempVector2D = UE4.FVector2D(0, 0)
  self.coordinateAxis = UE4.FVector2D(1, 0)
  self.imageScale = UE4.FVector2D(1.0, 1.0)
  self.ScreenPos = nil
  self.isTouchScale = false
  self.OpenFlag = false
  self.oldTwoTouchDistance = 0
  self.curTickTime = 0.0
  self.curMapShowLevel = 0
  self.DeltaTimer = 0.0
  self.FinishTime = 0.3
  self.MaxTileCount = 16
  local moveTimeData = _G.DataConfigManager:GetMapGlobalConfig("map_move_time")
  if moveTimeData then
    self.FinishTime = moveTimeData.num / 1000.0 or 0.3
  end
  self.isPlayFogAni = false
  self.curFogScale = 0.0
  self.SelectTaskId = nil
  self.IsClickBigManualBtn = false
  self.IsCanMove = true
  self.MoveTime = 0
  self.EndPos = {}
  self.OldmapCenter = {}
  self.SelectBonfire = nil
  self.IsFirstOnclick = false
  self.IsFirstOpen = true
  self.bMoveable = true
  self.consumedTouchMoveFrameCount = 0
  self.deltaXSinceLastFrame = 0
  self.deltaYSinceLastFrame = 0
  self.travelToggle = false
  self.bIsOpenByManual = false
  self.mapCutRangeList = _G.DataConfigManager:GetMapGlobalConfig("map_slide_range_cut").numList
  self.topRangePercent = self.mapCutRangeList[1] / 100
  self.bottomRangePercent = self.mapCutRangeList[2] / 100
  self.leftRangePercent = self.mapCutRangeList[3] / 100
  self.rightRangePercent = self.mapCutRangeList[4] / 100
  self.travelInfos = {}
  self.mapListIndex = 1
  self.npcIconNum = 0
  self.npcInViewportList = {}
  self.npcNotInViewportList = {}
  self.ContentToEntryIdDic = {}
  self.mapRange = {
    leftTopX = 0,
    leftTopY = 0,
    rightBottomX = 0,
    rightBottomY = 0
  }
  self.curShowPieceIdList = nil
  self.lastShowPieceIdList = nil
  self.showNpcDatas = nil
  self.showAreaNpcDatas = nil
  self.leftPieceIdList = nil
  self.showNpcList = nil
  self.MarkerPanelInfo = nil
  self.bUsePlayerLayerId = true
  self.bUseCenterLayerId = false
  self.openLayerId = 0
  self.lastShowLayerId = 0
  self.curCenterAreaId = 0
  self.mainSceneAreaIds = {}
  self.mouseScaleParam = 1.0
  if _G.AppMain:HasDebug() then
    local widgetClass = "WidgetBlueprint'/Game/NewRoco/Modules/System/BigMap/Res/UMG_DebugGrid.UMG_DebugGrid'"
    local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(widgetClass)
    self.NRCWidgetLoader_83:SetWidgetClass(softClassPath)
    self.NRCWidgetLoader_83:LoadPanelSync(self)
  end
  self._mapTileLoadStatus = {}
  self._pendingMapTiles = {}
  self._currentMapSceneResId = nil
  self.iconDataTemplate = {
    layerIndex = 1,
    iconTemplateIndex = 1,
    ZOrder = 0
  }
  self.traceInfo = {}
  self.iconLayerList = {
    self.iconLayer1,
    self.iconLayer2,
    self.Customdot,
    self.traceLayer,
    self.areaNameLayer,
    self.TaskLayer,
    self.OpenBattle
  }
  self.iconNPCTemplate = {
    self.iconNpcPet,
    self.iconNpcFunction,
    self.iconNpcRole
  }
  self.iconAreaNameTemplate = {
    self.areaInfoTemple,
    self.iconNpcFunction
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
  self.iconTraceTemplate = {
    self.traceIconHeroTemplate,
    self.traceIconNpcTemplate,
    self.traceIconTaskTemplate,
    self.traceIconMarkerTemplate,
    self.traceIconVisitTemplate,
    self.traceIconNpcTemplate,
    self.traceIconNpcTemplate,
    self.traceIconNpcTemplate,
    self.traceIconTravelTemplate
  }
  self.isTravel = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetIsTravelMap)
  self.creatorList = {}
  self.npcIconCreator = MapItemNPC(self, self.iconLayerList, self.iconNPCTemplate)
  self.areaNameCreator = MapItemAreaName(self, self.iconLayerList, self.iconAreaNameTemplate)
  self.taskIconCreator = MapItemTask(self, self.iconLayerList, self.iconTaskTemplate)
  self.markerIconCreator = MapItemMarker(self, self.iconLayerList, self.iconMarkerTemplate)
  self.visitorIconCreator = MapItemVisitor(self, self.iconLayerList, self.iconVisitorTemplate)
  self.traceIconCreator = MapItemTrace(self, self.iconLayerList, self.iconTraceTemplate)
  self.layerMapCreator = MapItemLayerMap(self, self.layerMapLayer, self.mapLayerTemplate)
  self.iconCircleCreator = MapItemCircle(self, self.iconLayerList, self.iconCircleTemplate)
  self.picCreator = MapItemPic(self, self.iconLayerList)
  self.maskCreator = MapItemMask(self, self.iconLayerList)
  self.mapItemCreator = MapItemCreator(30)
  self.creatorList = {
    self.npcIconCreator,
    self.areaNameCreator,
    self.taskIconCreator,
    self.markerIconCreator,
    self.visitorIconCreator,
    self.traceIconCreator,
    self.picCreator,
    self.maskCreator,
    self.layerMapCreator,
    self.iconCircleCreator
  }
  self.tempIconInfoList = {}
  if _G.GlobalConfig.bShowMapScale then
    Log.Error("\228\184\138\228\184\139\229\183\166\229\143\179\239\188\154", self.topRangePercent, self.bottomRangePercent, self.leftRangePercent, self.rightRangePercent)
  end
  self.onceChangeCount = _G.DataConfigManager:GetGlobalConfigByKeyType("mouse_wheel_scroll_map_scale", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  self.uiData.spriteHeadMaterials = {
    self.materialSpriteHead3,
    self.materialSpriteHead2,
    self.materialSpriteHead1
  }
  local MarkInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMarkInfo()
  self.data:SetCustomPointInfo(MarkInfo)
  self:GetMaskDynamicMaterial()
  self:GetWorldMapData()
  self.Hint.RedDot:SetupKey(92)
  self.BtnClaimfull.RedDot:SetupKey(201)
  local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
  local WorldOwnerUin = homeBriefInfo.home_owner_id or 0
  local BriefInfo = HomeIndoorSandbox.Server:GetLocalHomeBriefInfo() or {}
  local LoacalPlayerUin = BriefInfo.home_owner_id or 0
  if WorldOwnerUin == LoacalPlayerUin then
    self.BtnHome.RedDot:SetupKey(438)
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSuitPopupPanel, nil, true, false)
  self:HideMask(_G.GlobalConfig.bHideMainMapMask)
  self:BindInputAction()
  if self.isTravel then
    self.IsTravelMusic = true
    local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAP)
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAP)
    if StateGroup then
      _G.NRCAudioManager:BatchSetState(StateGroup)
    end
  else
    self.IsTravelMusic = false
    local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAP)
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAP)
    if StateGroup then
      _G.NRCAudioManager:BatchSetState(StateGroup)
    end
  end
end

function UMG_MainMap_C:GetWorldMapData()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    self.WorldMapConfigs = bigMapModule.data:GetWorldMapDatas()
  end
end

function UMG_MainMap_C:ClearCreators()
  if self.creatorList and #self.creatorList > 0 then
    local creatorList = self.creatorList
    for i = #creatorList, 1, -1 do
      if creatorList[i] and creatorList[i].DestroyAll then
        creatorList[i]:DestroyAll()
        table.remove(creatorList, i)
      end
    end
    self.creatorList = nil
  end
  if self.mapItemCreator then
    self.mapItemCreator:DestroyAll()
    self.mapItemCreator = nil
  end
end

function UMG_MainMap_C:OnDestruct()
  self:DrawMask(SceneUtils.GetSceneResId())
  self:UnRegisterEvent(self, BigMapModuleEvent.ChangeIsTravel, self.OnChangeIsTravel)
  if self.isTravel then
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OnZoneQueryInvestTaskReq)
    _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SetIsTravel, false)
  end
  if self.IsTravelMusic then
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAP)
  else
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAP)
  end
  if self.DelayCreateVisibleNpc then
    self:CancelDelayByID(self.DelayCreateVisibleNpc)
    self.DelayCreateVisibleNpc = nil
  end
  if self.UpdateAreaNameDelay then
    self:CancelDelayByID(self.UpdateAreaNameDelay)
    self.UpdateAreaNameDelay = nil
  end
  self:CancelDelay()
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.CloseInputBlocker, "UMG_MainMap_C")
  UE4.UNRCAudioManager.ResetWorldListenerVolumeOffset()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule.data then
    if not self.bIsOpenByManual then
      bigMapModule.data:SetLastMapSliderScale(self.uiData.mapSliderScale)
    else
      bigMapModule.data:SetLastMapSliderScale(0.4)
      self.bIsOpenByManual = not self.bIsOpenByManual
    end
  end
  self.data:SetCurShowSceneResId(0)
  self:ClearCreators()
  self._currentMapSceneResId = nil
  table.clear(self._mapTileLoadStatus)
  table.clear(self._pendingMapTiles)
  table.clear(self.uiData)
  table.clear(self.uiItem)
  table.clear(self.tempIconInfoList)
  self.uiData = nil
  self.uiItem = nil
  self.maskDynamicMaterialList = nil
  self.mapMaskList = nil
  self.bOpen = true
  self:OnRemoveEventListener()
  if self.data.bNeedClearFakeData then
    if self.data.fakeHomeNpcData then
      for _, fakeHomeNpcData in ipairs(self.data.fakeHomeNpcData) do
        self.data:UpdateHomePetInfo(fakeHomeNpcData, _G.Enum.MapModuleDataUpdateReason.HOME_PET_LEAVE)
      end
    end
    self.data.bNeedClearFakeData = false
  end
end

function UMG_MainMap_C:GetTempVector2D(x, y)
  self.tempVector2D = self.tempVector2D or UE4.FVector2D(0, 0)
  self.tempVector2D.X = x
  self.tempVector2D.y = y
  return self.tempVector2D
end

function UMG_MainMap_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title2:Set_MainTitle(self.titleConf.title)
  self.Title2:SetBg(self.titleConf.head_icon)
  self.Title2:SetSubtitle(self.titleConf.subtitle[2].subtitle)
end

function UMG_MainMap_C:RefreshTitleInfo(bIsTravel)
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if bIsTravel then
    local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/img_lvxing_png.img_lvxing_png'"
    if self.titleConf.subtitle then
      self.Title2:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
    self.Title2:SetBg(iconPath)
  else
    for i = 1, #self.data.MapShowList do
      if self.data.MapShowList[i].sceneResId == self.data:GetCurSceneResId() then
        self.Title2:SetSubtitle(self.data.MapShowList[i].name)
        break
      end
    end
    if self.titleConf.head_icon then
      self.Title2:SetBg(self.titleConf.head_icon)
    end
  end
end

function UMG_MainMap_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_MapUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseMapUI", self, "OnPcClose")
    mappingContext:BindAction("IA_MapScaleUp", self, "OnPcScaleUp")
    mappingContext:BindAction("IA_MapScaleDown", self, "OnPcScaleDown")
    mappingContext:BindAction("IA_CloseMapQuick", self, "OnPcQuickClose")
  end
end

function UMG_MainMap_C:OnPcScaleDown()
  if not self.bMouseInMapScope then
    return
  end
  local scale = self.uiData.mapSliderScale - 1 / (self.onceChangeCount * 2)
  scale = scale < 0 and 0 or scale
  self:ChangeMapScaleSliderValue(scale - self.uiData.mapSliderScale)
  self:OnMapScaleValueChanged(scale)
end

function UMG_MainMap_C:OnPcScaleUp()
  if not self.bMouseInMapScope then
    return
  end
  local scale = self.uiData.mapSliderScale + 1 / (self.onceChangeCount * 2)
  scale = scale > 1 and 1 or scale
  self:ChangeMapScaleSliderValue(scale - self.uiData.mapSliderScale)
  self:OnMapScaleValueChanged(scale)
end

function UMG_MainMap_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  if self.module:CheckMapRightPanelOpened() then
    self.module:OnCmdCloseMapRightPanel()
  else
    self:OnCloseButtonClicked()
  end
end

function UMG_MainMap_C:OnPcQuickClose()
  if not self.module:CheckMapRightPanelOpened() then
    self:OnCloseButtonClicked()
  end
end

function UMG_MainMap_C:InitDataBySceneResId(sceneResId, bInit)
  local sceneOffsetX = 254650.0
  local sceneOffsetY = 510000.0
  local imageWidth = 6144
  local imageHeight = 6144
  local sceneWidth = 460500
  local sceneHeight = 460500
  sceneOffsetX, sceneOffsetY, sceneWidth, sceneHeight = BigMapUtils.GetConstData(sceneResId)
  local imageToSceneScale = imageWidth / sceneWidth
  if bInit then
    self.uiData = {
      mapSliderScale = 0,
      mapImageScale = 1.0,
      originalMapWidth = imageWidth,
      originalMapHeight = imageHeight,
      sceneOffsetX = sceneOffsetX,
      sceneOffsetY = sceneOffsetY,
      imageToSceneScale = imageToSceneScale
    }
  else
    self.uiData.originalMapWidth = imageWidth
    self.uiData.originalMapHeight = imageHeight
    self.uiData.sceneOffsetX = sceneOffsetX
    self.uiData.sceneOffsetY = sceneOffsetY
    self.uiData.imageToSceneScale = imageToSceneScale
  end
end

function UMG_MainMap_C:OnActive(_param, bIsOpenByManual, rsp, ...)
  self:ResetConsumedTouchMoveFrameCount()
  self.data:SetMapShowList()
  _G.NRCAudioManager:PlaySound2DAuto(40008018, "UMG_MainMap_C:OnActive")
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_CLOSE_MAP)
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.uiData.uiOpenParam = _param
  self.uiData.StarRecoverTime = rsp
  if bIsOpenByManual then
    self.bIsOpenByManual = bIsOpenByManual
  end
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  self.DelayShowIcon = {}
  self.npcListData = {}
  self.playAniNpcRefreshId = _param or {}
  if not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    local traceVisitorInfo = self.data.traceInfoList and self.data.traceInfoList[bigMapModuleEnum.TraceType.Visitor]
    if traceVisitorInfo then
      self.data.traceInfoList[bigMapModuleEnum.TraceType.Visitor] = nil
    end
  end
  self:InitPanelInfo(self.uiData.uiOpenParam)
  self.uiData.uiOpenParam = nil
  self.dot_2Pos = nil
  self.dot_2HasMapMask = false
  self.dot_2HasMark = false
  self.playOpenAnimation = true
  self:InitTravelData()
  if self.isTravel then
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_1:InitNum(#self.travelInfos, self.MaxTravelNum, LuaText.travel_text)
    self.CanvasPanel_Plot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ComboBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local isVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    if isVisit then
      local sharedIconPath = "PaperSprite'/Game/NewRoco/Modules/System/SleepingOwl/Raw/Frames/img_SharedWithFriendsBtn_png.img_SharedWithFriendsBtn_png'"
      self.Sanctuary:SetPath(sharedIconPath, sharedIconPath, sharedIconPath)
    end
  end
  self:RefreshTitleInfo(self.isTravel)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetCompassUpdateTrace, false)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1365, "UMG_MainMap_C:OnCloseButtonClicked")
  local bHasCompass = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.HasCompass)
  if not bHasCompass then
    NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  end
  local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType1)
  local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MAP
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType2)
  self:OnGetTravelTaskState()
  self.bMouseInMapScope = true
  self:ShowVisitPlayer()
  self:ShowLayerMapInHome()
  self:NotifyHomeServerRedDotRefresh()
  self:ShowSanctuary(true)
end

function UMG_MainMap_C:UpdateHomeBtn()
  self.Home:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.bHomeUnLocked and BigMapUtils.IsBigWorldMap(self.data.curShowSceneResId) then
    self.Home:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_MainMap_C:OnClickBtnHome()
  local HomeRefreshId = 5200191
  self:SetMapCenterByNPC(HomeRefreshId, 0.5)
end

function UMG_MainMap_C:NotifyHomeServerRedDotRefresh()
  if HomeIndoorSandbox then
    local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
    self.WorldOwnerUin = homeBriefInfo.home_owner_id or 0
    local req = _G.ProtoMessage:newZoneHomeQueryFriendHomeInfoReq()
    req.uin = self.WorldOwnerUin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_QUERY_FRIEND_HOME_INFO_REQ, req, self, self.OnZoneHomeQueryWorldOwnerHomeInfoRsp, true)
  end
end

function UMG_MainMap_C:OnZoneHomeQueryWorldOwnerHomeInfoRsp(Rsp)
  local BriefInfo = HomeIndoorSandbox.Server:GetLocalHomeBriefInfo() or {}
  self.LoacalPlayerUin = BriefInfo.home_owner_id or 0
  if self.LoacalPlayerUin == self.WorldOwnerUin then
    local SelfHomeUnLock = Rsp.home_feature_opened or false
    self.bHomeUnLocked = SelfHomeUnLock
  else
    local WorldOwnerHomeUnLock = Rsp.home_feature_opened or false
    local SelfHomeUnLock = _G.NRCModuleManager:DoCmd(HomeModuleCmd.IsOpenHomeFunction)
    self.bHomeUnLocked = WorldOwnerHomeUnLock and SelfHomeUnLock
  end
  self:UpdateHint()
  self:UpdateHomeBtn()
end

function UMG_MainMap_C:OnEnable()
  if self.shouldShowForNextEnable then
    self.shouldShowForNextEnable = false
    self:StopAnimation(self.open)
    self:PlayAnimation(self.open, 0, 1, 0, 1)
  end
end

function UMG_MainMap_C:OnDeactive()
  self.bMouseInMapScope = false
  self.checkMapCenterPosition = false
  if self.DelayShowIcon then
    for _, v in ipairs(self.DelayShowIcon) do
      _G.DelayManager:CancelDelayById(v)
    end
  end
  self.DelayShowIcon = {}
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetCompassUpdateTrace, true)
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.CloseHabitTips)
  if self.data then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateMiniMapMarkInfo, self.data:GetNewCustomPointInfo())
  end
end

function UMG_MainMap_C:SetTargetPos(posX, posY)
  self.targetPosX = posX
  self.targetPosY = posY
end

function UMG_MainMap_C:InitPanelInfo(_param)
  if _param then
    if _param.scaleSliderValue then
      self.uiData.mapSliderScale = _param.scaleSliderValue
    end
    if _param.TaskId then
      self.SelectTaskId = _param.TaskId
      if self.data:GetSelectTaskId() then
        self.bUsePlayerLayerId = false
        self:ChangeMapByTaskId()
        self:OnShowTaskIcon()
    end
    elseif _param.entry_id then
      self:OnShowNormalNpcEvent(_param)
    else
      if _param.centerNPCRefreshId then
        self.bUsePlayerLayerId = false
        local npcInfo = self.data:GetNpcInfoByRefreshId(_param.centerNPCRefreshId)
        if npcInfo then
          self:SetMapCenterByNPC(_param.centerNPCRefreshId, nil, nil, true)
          if not _param.bNotRightPanel then
            self:DelaySeconds(0.4, self.OnSingleIconClicked, self, npcInfo)
          end
          goto lbl_105
        else
          Log.Error(string.format("centerNPCRefreshId%d No Found NpcInfo", _param.centerNPCRefreshId))
        end
      end
      local ResId = SceneUtils.GetSceneResId()
      if self.data.isOpenTravel and 10018 == ResId then
        ResId = 10003
      end
      self:ChangeMapBySceneId(ResId, _param)
      self:SetMapShowList()
      self.data:SetSceneResId(nil)
    end
  else
    local ResId = SceneUtils.GetSceneResId()
    if self.data.isOpenTravel and 10018 == ResId then
      ResId = 10003
    end
    self:ChangeMapBySceneId(ResId, _param)
    self:SetMapShowList()
    self.data:SetSceneResId(nil)
  end
  ::lbl_105::
  if (nil == _param or _param.scaleSliderValue == nil) and self.module.IsTraceOpen and self.uiData and self.uiData.mapSliderScale then
    self:ChangeMapScaleSliderValue(0 - self.uiData.mapSliderScale)
  end
  self.npcListLayer:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.checkMapCenterPosition = true
  self:UpdateHealth()
end

function UMG_MainMap_C:ShowExploredInfo()
  local UnlockDeadwoodList = self.data:GetUnlockDeadwoodList()
  local showExplore = false
  local blockConf = self.data.sceneResIdToBlockConf[self.data.curShowSceneResId]
  if blockConf then
    showExplore = blockConf.IS_EXPLORING_STATISTIC
  end
  if UnlockDeadwoodList[self.data.curShowSceneResId] and #UnlockDeadwoodList[self.data.curShowSceneResId] > 0 and BigMapUtils.IsBigWorldMap(self.data.curShowSceneResId) and showExplore then
    self.CanvasPanel_Plot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CanvasPanel_Plot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:UpdateInfoBarList()
end

function UMG_MainMap_C:UpdateHint()
  self.shouldShowHint = false
  local hintTable = self.module:GetInfoBarList()
  self.NRCGridView_62:InitGridView(hintTable)
  self.NRCGridView_62:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PromptBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if hintTable and #hintTable > 0 then
    if not self.bIsTravel and BigMapUtils.IsBigWorldMap(self.data.curShowSceneResId) then
      self.shouldShowHint = true
      self:ShowHint(true)
    else
      self:ShowHint(false)
    end
  else
    self:ShowHint(false)
  end
end

function UMG_MainMap_C:OnHintDetailsClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002002, "UMG_MainMap_C:OnHintDetailsClicked")
  local showState = self.PromptBg:GetVisibility()
  if showState ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    self.NRCGridView_62:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PromptBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCGridView_62:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PromptBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:ShowHint(bShow)
  if bShow and BigMapUtils.IsBigWorldMap(self.data.curShowSceneResId) and self.shouldShowHint then
    self.Hint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:ShowSanctuary(bShow)
  if not bShow then
    self.Sanctuary:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local isBanOwl = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_OWL_LIST, false)
  local isHome = BigMapUtils.IsHomeMap(self.data.curShowSceneResId)
  if not isBanOwl and not isHome then
    self.Sanctuary:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local isVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    if isVisit then
      local sharedIconPath = "PaperSprite'/Game/NewRoco/Modules/System/SleepingOwl/Raw/Frames/img_SharedWithFriendsBtn_png.img_SharedWithFriendsBtn_png'"
      self.Sanctuary:SetPath(sharedIconPath, sharedIconPath, sharedIconPath)
    end
  else
    self.Sanctuary:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:CreateGroupLayerMap(layerId)
  local layerMapConf = _G.DataConfigManager:GetLayeredWorldMapConf(layerId)
  local layerIds
  if layerMapConf then
    local groupId = layerMapConf.map_layer_group
    if groupId > 0 then
      layerIds = self.data.LayerGroupIdToLayerMapIds[groupId]
    end
  end
  if layerIds and #layerIds > 0 then
    for k, v in ipairs(layerIds) do
      if v.id and v.area_func_id > 0 and BigMapUtils.CheckLayerIdUnlocked(v.id) then
        self:CreateLayerMap(v.id)
      end
    end
  end
  self.layerMapCreator:SetTopLayer(layerId)
end

function UMG_MainMap_C:CreateLayerMap(layerId)
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
      posX, posY = self:ScenePositionToImagePosition(startPos.X, startPos.Y)
    end
    iconData.iconImagePos = {x = posX, y = posY}
    local imageWidth = orthoWidth * self.uiData.imageToSceneScale
    imageData.imageScale = UE4.FVector2D(imageWidth, imageWidth)
    imageData.imagePath = BigMapUtils.GetLayerMapImagePath(layerId)
    imageData.layerMapId = layerId
  end
  self.layerMapCreator:Create({iconData = iconData, imageInfo = imageData})
end

function UMG_MainMap_C:ShowLayerMapInHome()
  if self.data.curShowSceneResId == 30001 then
    local showLayerId = 0
    if 30001 == SceneUtils.GetSceneResId() then
      showLayerId = self.data:GetCurMapLayerId()
    end
    if showLayerId > 0 then
      self:SetLayerMapList(showLayerId)
    else
      self:SetLayerMapList(14)
    end
  elseif self.data.curShowSceneResId == 30002 then
    self:SetLayerMapList(0)
  end
end

function UMG_MainMap_C:SetLayerMapList(layerId, bShowSurface)
  if layerId > 0 then
    local layerMapConf = _G.DataConfigManager:GetLayeredWorldMapConf(layerId)
    local bLocked = true
    if layerMapConf then
      local campRefreshId = layerMapConf.belong_camp
      if nil == campRefreshId or 0 == campRefreshId then
        bLocked = false
      elseif self.data.DrawList and self.data.DrawList[self.data.curShowSceneResId] then
        for k, v in pairs(self.data.DrawList[self.data.curShowSceneResId]) do
          local refreshId = self.data.AreaIdToRefreshId[v]
          if campRefreshId == refreshId then
            bLocked = false
            goto lbl_47
          end
        end
      end
      ::lbl_47::
    end
    if true == bLocked then
      return
    end
    if layerMapConf then
      local groupId = layerMapConf.map_layer_group
      local layerMapInfo = self.data.LayerGroupIdToLayerMapIds[groupId]
      local actualShowLayerInfo = {}
      if layerMapInfo and #layerMapInfo > 0 then
        for key, info in ipairs(layerMapInfo) do
          if BigMapUtils.CheckLayerIdUnlocked(info.id) then
            table.insert(actualShowLayerInfo, info)
          end
          if bShowSurface and (nil == info.area_func_id or 0 == info.area_func_id) then
            layerId = info.id
          end
        end
      end
      if #actualShowLayerInfo > 1 then
        if layerId ~= self.lastShowLayerId then
          self.module:OnCmdOpenMapLayerTip(true, {layerInfo = actualShowLayerInfo, selectedLayerId = layerId})
        end
      else
        self.module:OnCmdOpenMapLayerTip(false)
        self:ShowLayerMap(false, 0)
      end
    end
  else
    self.module:OnCmdOpenMapLayerTip(false)
    self:ShowLayerMap(false, 0)
  end
  self.bUsePlayerLayerId = true
end

function UMG_MainMap_C:ShowLayerMap(bShow, layerId, bShowLayerTip)
  self.layerMapCreator:SetLayerMapVisible(bShow, layerId)
  if bShow then
    self.Image_zhezhao:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:CreateGroupLayerMap(layerId)
    local layerConf = DataConfigManager:GetLayeredWorldMapConf(layerId)
    if layerConf then
      local campRefreshId = layerConf.belong_camp
      if campRefreshId > 0 then
        local areaIds = self.data.RefreshIdToAreaIds[campRefreshId]
        if areaIds and #areaIds > 0 then
          self:SetExploredInfo(areaIds[1])
        end
      end
    end
    if layerId > 0 then
      self:SetIconLayerColor(layerId, bigMapModuleEnum.CreatorPriority.NpcIcons, true)
      self:SetIconLayerColor(layerId, bigMapModuleEnum.CreatorPriority.MarkerIcons, true)
    end
    if self.lastShowLayerId > 0 and self.lastShowLayerId ~= layerId then
      self:SetIconLayerColor(self.lastShowLayerId, bigMapModuleEnum.CreatorPriority.NpcIcons, false)
      self:SetIconLayerColor(self.lastShowLayerId, bigMapModuleEnum.CreatorPriority.MarkerIcons, false)
    end
    self.bUseCenterLayerId = false
  else
    self.Image_zhezhao:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.lastShowLayerId > 0 then
      self:SetIconLayerColor(self.lastShowLayerId, bigMapModuleEnum.CreatorPriority.NpcIcons, false)
      self:SetIconLayerColor(self.lastShowLayerId, bigMapModuleEnum.CreatorPriority.MarkerIcons, false)
    end
    self.bUseCenterLayerId = true
  end
  self.lastShowLayerId = layerId or 0
  self.data.curShowLayerId = self.lastShowLayerId
end

function UMG_MainMap_C:SetIconLayerColor(layerId, iconType, bColorful)
  if self.data.layerIdToIcons[layerId] == nil then
    return
  end
  if iconType == bigMapModuleEnum.CreatorPriority.NpcIcons then
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
  elseif iconType == bigMapModuleEnum.CreatorPriority.MarkerIcons then
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

function UMG_MainMap_C:SetCollectionInfo(areaId)
  self.Text:SetText()
  self.Text_1:SetText()
  self.Text_2:SetText()
end

function UMG_MainMap_C:OnCollectionBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40003001, "UMG_MainMap_C:OnCollectionBtnClicked")
  self.module:OnCmdOpenCollectTips(self.curCenterAreaId)
end

function UMG_MainMap_C:SetMapScaleBySliderScale(sliderScale, bForce)
  self.mapScaleSlider:SetValue(sliderScale)
  self:SetMapScale(self:GetMapImageScale(sliderScale), bForce, sliderScale)
end

function UMG_MainMap_C:ChangeMapBySceneId(sceneResId, param)
  local changeNewMap = self.lastOpenMapId ~= sceneResId or self.lastOpenMapId == nil
  if changeNewMap then
    self.lastOpenMapId = sceneResId
    UE4Helper.SetEnableWorldRendering(true)
    self:HideNPCList()
    self.mouseIcon:showEndAni()
  end
  if not self.shouldShowForNextEnable and changeNewMap then
    self:SetPanelHasCustomOpenAnim()
    self:PlayAnimation(self.open)
  end
  self:UpdateNPCInfoByChangeShowMap()
  local bHasScene = false
  local centerAreaId = 0
  for k, v in ipairs(self.data.MapShowList) do
    if v.sceneResId == sceneResId then
      centerAreaId = v.centerAreaId
      bHasScene = true
      self.mapListIndex = k
      break
    end
  end
  local showSceneResId = self.module:GetShowMapBySceneResId(sceneResId, bHasScene)
  self.data:SetCurShowSceneResId(showSceneResId)
  self:UpdateBg(sceneResId)
  self:InitDataBySceneResId(showSceneResId, false)
  self:ShowTravelBtn()
  for i = 1, #self.data.MapShowList do
    if self.data.MapShowList[i].sceneResId == showSceneResId then
      self.Title2:SetSubtitle(self.data.MapShowList[i].name)
      break
    end
  end
  self:GetMapScaleBySceneResId(showSceneResId)
  self:SetMapScaleBySliderScale(self.uiData.mapSliderScale, true)
  self:ShowLayerMapInHome()
  self:SetPlayerPosAndVisibility(showSceneResId, param, changeNewMap, centerAreaId, sceneResId)
  if self.data.curShowSceneResId == SceneUtils.GetSceneResId() then
    if self.bUsePlayerLayerId == true then
      local showLayerId = self.data:GetCurMapLayerId()
      if showLayerId > 0 then
        self.bUseCenterLayerId = false
      else
        self.bUseCenterLayerId = true
      end
      self:SetLayerMapList(showLayerId)
    end
  else
    local layerId = 0
    if self.data.curShowSceneResId == self.data.lastShowSceneResId and self.mainSceneAreaIds and #self.mainSceneAreaIds > 0 then
      layerId = self:GetLayerId(self.mainSceneAreaIds)
    end
    if not BigMapUtils.IsHomeMap(self.data.curShowSceneResId) then
      self:SetLayerMapList(layerId)
    end
  end
  self:UpDateTempTraceIconsVisible()
  self:OnWorldMapInfoUpdateEvent(self.data:GetNpcDatas(showSceneResId), self.data:GetMapAreaDatas())
  self:UpdateVisitPoint(self.data:GetVisitPointInfo())
  self:SetMaskBySceneResId(showSceneResId)
  self:ShowExploredInfo()
  self:ShowTempTraceIcons()
  self:SetTargetPos(0, 0)
end

function UMG_MainMap_C:IsShowSceneResOrSubSceneRes(showSceneResId)
  local CurSceneRes = SceneUtils.GetSceneResId()
  if CurSceneRes == showSceneResId then
    return true
  else
    local showSceneResConf = _G.DataConfigManager:GetSceneResConf(showSceneResId)
    if showSceneResConf and showSceneResConf.sub_scene_res_list and #showSceneResConf.sub_scene_res_list > 0 then
      local sub_scene_res_list = showSceneResConf.sub_scene_res_list
      for i, v in pairs(sub_scene_res_list) do
        if v == CurSceneRes then
          return true
        end
      end
    end
  end
  return false
end

function UMG_MainMap_C:GetMapScaleBySceneResId(showSceneResId)
  local bInDungeon = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.IsInDungeon)
  if showSceneResId ~= self.data.lastShowSceneResId and false == bInDungeon then
    self.data:SetLastMapSliderScale(nil)
  end
  if self.playAniNpcRefreshId and #self.playAniNpcRefreshId > 0 then
    self.uiData.mapSliderScale = 0.5
  elseif self.uiData.uiOpenParam and self.uiData.uiOpenParam.scaleSliderValue then
    local openScaleSliderValue = self.uiData.uiOpenParam.scaleSliderValue
    if openScaleSliderValue and openScaleSliderValue >= 0 then
      self.uiData.mapSliderScale = openScaleSliderValue
    end
  elseif self.bIsOpenByManual then
    self.uiData.mapSliderScale = 0.4
  else
    self.uiData.mapSliderScale = self.data:GetLastMapSliderScale(showSceneResId)
  end
end

function UMG_MainMap_C:SetDefaultCenterAndShowHero(param, bLerp)
  self:SetDefaultCenterPos(param, bLerp)
  self.heroIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_MainMap_C:UpdateHeroPositionAndCenter(posX, posY, bLerp)
  local sceneCenterX, sceneCenterY = self:ScenePositionToImagePosition(posX, posY)
  self.uiData.heroPosX = sceneCenterX
  self.uiData.heroPosY = sceneCenterY
  local _, heroDir = self:GetPlayerLocation()
  self.uiData.heroDir = heroDir
  self:UpdateHeroInfo()
  self:SetMapCenterPosition(sceneCenterX, sceneCenterY, bLerp)
  self.heroIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_MainMap_C:IsSubSceneWithoutMap()
  local currentSceneResId = SceneUtils.GetSceneResId()
  for _, v in ipairs(self.data.MapShowList) do
    if v.sceneResId == currentSceneResId then
      return false
    end
  end
  return true
end

function UMG_MainMap_C:SetPlayerPosAndVisibility(showSceneResId, param, changeNewMap, centerAreaId, sceneResId)
  local worldMapInfo = _G.DataModelMgr.PlayerDataModel:GetWorldMapActorInfo()
  if worldMapInfo then
    self.mainSceneAreaIds = worldMapInfo.main_scene_pt_effect_areas
  end
  local bLerp = not changeNewMap
  local currentSceneResId = SceneUtils.GetSceneResId()
  local bShowAtTargetPos = currentSceneResId == showSceneResId or self:IsShowSceneResOrSubSceneRes(showSceneResId) and self.targetPosX > 0 and self.targetPosY > 0 or 0 ~= self.targetPosX and 0 ~= self.targetPosY
  if bShowAtTargetPos then
    self:SetDefaultCenterAndShowHero(param, bLerp)
    return
  end
  if self:IsSubSceneWithoutMap() then
    local shouldShowSceneResId = self.module:GetShowMapBySceneResId(SceneUtils.GetSceneResId(), false)
    if shouldShowSceneResId == self.data.curShowSceneResId then
      if worldMapInfo and worldMapInfo.main_scene_pt then
        local point = worldMapInfo.main_scene_pt.pos
        self:UpdateHeroPositionAndCenter(point.x, point.y, bLerp)
      end
    elseif 0 ~= centerAreaId then
      self:_HandleNonStaticSubScene(worldMapInfo, param, bLerp, centerAreaId, sceneResId)
    end
    return
  end
  if 0 ~= centerAreaId then
    self:_HandleNonStaticSubScene(worldMapInfo, param, bLerp, centerAreaId, sceneResId)
  end
end

function UMG_MainMap_C:_HandleNonStaticSubScene(worldMapInfo, param, bLerp, centerAreaId, sceneResId)
  local areaConf = _G.DataConfigManager:GetAreaConf(centerAreaId)
  if not (areaConf and areaConf.pos) or 0 == #areaConf.pos then
    self:SetDefaultCenterAndShowHero(param, bLerp)
    return
  end
  local areaPoint = areaConf.pos[1].position_xyz
  local sceneCenterX, sceneCenterY = self:ScenePositionToImagePosition(areaPoint[1], areaPoint[2])
  self:SetMapCenterPosition(sceneCenterX, sceneCenterY, bLerp)
  self.heroIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MainMap_C:UpdateMapByPosition()
  if self.bOpen == true then
    self.bOpen = false
  else
    if self.DelayCreateVisibleNpc then
      self:CancelDelayByID(self.DelayCreateVisibleNpc)
      self.DelayCreateVisibleNpc = nil
    end
    self.DelayCreateVisibleNpc = self:DelaySeconds(0.1, self.CreateVisibleNpc, self)
  end
  self:SetMapAndMaskBySceneResId(self.data.curShowSceneResId)
end

function UMG_MainMap_C:SetMapAndMaskBySceneResId(sceneResId)
  local centerPos = self:GetTempVector2D(self.uiData.mapCenterX, self.uiData.mapCenterY)
  local mapPieceList = BigMapUtils.GetLoadPiecesByImagePosition(1024, self.curWndSize, centerPos, self.uiData.mapImageScale)
  local newPieceList, oldPieceList
  if self.lastShowPieceIdList == nil or 0 == #self.lastShowPieceIdList or self.data.lastShowSceneResId ~= sceneResId then
    newPieceList = mapPieceList
  else
    newPieceList, oldPieceList = self:CheckMapPieceChange(mapPieceList)
  end
  self:SetMapBySceneResId(sceneResId, newPieceList, oldPieceList, mapPieceList)
  self.lastShowPieceIdList = self.curShowPieceIdList
end

function UMG_MainMap_C:SetCenterPosBySceneResId(sceneResId)
end

function UMG_MainMap_C:SetMapBySceneResId(sceneResId, newPieceList, oldPieceList, curPieceList)
  if not newPieceList or 0 == #newPieceList then
    return
  end
  if self._currentMapSceneResId ~= sceneResId then
    if self._currentMapSceneResId then
      self:ReleaseResLoadRequest()
      table.clear(self._mapTileLoadStatus)
      table.clear(self._pendingMapTiles)
    end
    for i = 1, self.MaxTileCount do
      self.mapList[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    newPieceList = curPieceList
  end
  self._currentMapSceneResId = sceneResId
  self:PreloadMapTiles(sceneResId, newPieceList)
  self:PreloadRemainingTiles(sceneResId, newPieceList)
end

function UMG_MainMap_C:PreloadMapTiles(sceneResId, pieceList)
  if not sceneResId then
    return
  end
  local LoadStatus = bigMapModuleEnum.MapTileLoadStatus
  local loadPieceList = pieceList or {
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16
  }
  for _, pieceNo in ipairs(loadPieceList) do
    local assetPath = BigMapUtils.GetMapPicPath(sceneResId, pieceNo)
    if assetPath and self._pendingMapTiles[pieceNo] ~= assetPath then
      local status = self._mapTileLoadStatus[assetPath]
      self._pendingMapTiles[pieceNo] = assetPath
      if status == LoadStatus.Loaded or status == LoadStatus.Failed then
      elseif status == LoadStatus.Loading then
      else
        self._mapTileLoadStatus[assetPath] = LoadStatus.Loading
        self:LoadPanelRes(assetPath, 255, function(caller, request, asset)
          self:OnMapTileLoaded(request.assetPath, true)
        end, function(caller, request, err)
          self:OnMapTileLoaded(request.assetPath, false)
        end, nil)
      end
    end
  end
  self:TryApplyPendingTiles()
end

function UMG_MainMap_C:OnMapTileLoaded(assetPath, success)
  local LoadStatus = bigMapModuleEnum.MapTileLoadStatus
  self._mapTileLoadStatus[assetPath] = success and LoadStatus.Loaded or LoadStatus.Failed
  self:TryApplyPendingTiles()
end

function UMG_MainMap_C:IsAllPendingMapTilesLoaded()
  local LoadStatus = bigMapModuleEnum.MapTileLoadStatus
  for _, assetPath in pairs(self._pendingMapTiles) do
    if self._mapTileLoadStatus[assetPath] ~= LoadStatus.Loaded and self._mapTileLoadStatus[assetPath] ~= LoadStatus.Failed then
      return false
    end
  end
  return true
end

function UMG_MainMap_C:SetMapTilePath(i, Path)
  local mapTile = self.mapList[i]
  if mapTile then
    mapTile:SetPath(Path)
    mapTile:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_MainMap_C:TryApplyPendingTiles()
  if not self:IsAllPendingMapTilesLoaded() then
    return
  end
  local LoadStatus = bigMapModuleEnum.MapTileLoadStatus
  for pieceNo, assetPath in pairs(self._pendingMapTiles) do
    if self.mapList[pieceNo] then
      local status = self._mapTileLoadStatus[assetPath]
      if status == LoadStatus.Loaded then
        self:SetMapTilePath(pieceNo, assetPath)
      else
        self:SetMapTilePath(pieceNo, "")
        if status == LoadStatus.Failed then
        end
      end
    end
  end
  table.clear(self._pendingMapTiles)
end

function UMG_MainMap_C:ResetPendingTiles()
  table.clear(self._pendingMapTiles)
end

function UMG_MainMap_C:PreloadRemainingTiles(sceneResId, excludePieceList)
  local LoadStatus = bigMapModuleEnum.MapTileLoadStatus
  local excludeSet = {}
  if excludePieceList then
    for _, pieceNo in ipairs(excludePieceList) do
      excludeSet[pieceNo] = true
    end
  end
  for i = 1, self.MaxTileCount do
    if not excludeSet[i] then
      local assetPath = BigMapUtils.GetMapPicPath(sceneResId, i)
      local status = self._mapTileLoadStatus[assetPath]
      if assetPath and not status then
        self._mapTileLoadStatus[assetPath] = LoadStatus.Loading
        self:LoadPanelRes(assetPath, 200, function(caller, request, asset)
          self:OnMapTileLoaded(request.assetPath, true)
        end, function(caller, request, err)
          self:OnMapTileLoaded(request.assetPath, false)
        end, nil)
      end
    end
  end
end

function UMG_MainMap_C:ShowAllMap(sceneResId)
  for i = 1, self.MaxTileCount do
    local assetPath = BigMapUtils.GetMapPicPath(sceneResId, i)
    if assetPath then
      self:SetMapTilePath(i, assetPath)
    end
  end
end

function UMG_MainMap_C:SetMapShowList(sceneResId)
  if #self.data.MapShowList > 0 then
    self.ComboBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.realShowMapList = {}
    local showList = {}
    for k, v in pairs(self.data.MapShowList) do
      if v.sceneResId == self.data.curShowSceneResId then
        local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
        local homeOwnerId = homeBriefInfo.home_owner_id or 0
        local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
        if BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) and homeOwnerId ~= playerUin then
          showList = v.Conf.map_same_group_home_visitor
          break
        end
        showList = v.Conf.map_same_group
        break
      end
    end
    if showList and #showList > 0 then
      for k, v in ipairs(showList) do
        for key, listData in pairs(self.data.MapShowList) do
          if listData.Conf.id == v then
            table.insert(self.realShowMapList, listData)
          end
        end
      end
    end
    if self.realShowMapList and #self.realShowMapList > 0 then
      self.data.MapShowList = self.realShowMapList
    else
      Log.Error("\232\175\183\230\163\128\230\159\165\228\184\139\230\137\147\229\188\128\229\156\176\229\155\190\229\175\185\229\186\148\231\154\132sceneResId\229\156\176\229\155\190\230\152\175\229\144\166\232\167\163\233\148\129")
    end
    for k, v in ipairs(self.data.MapShowList) do
      if v.sceneResId == self.data.curShowSceneResId then
        self.mapListIndex = k
        break
      end
    end
    if self.mapListIndex <= #self.data.MapShowList then
      self:SetCommonComboBoxInfo(self.ComboBox, self.data.MapShowList, self.mapListIndex, self.data.MapShowList[self.mapListIndex].name)
    end
  else
    self.ComboBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:SetCommonComboBoxInfo(ComboBox, DropDownListInfo, DropDownListIndex, DropDownListText)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if DropDownListInfo then
    CommonDropDownListData.DropDownListInfo = DropDownListInfo
  end
  if DropDownListIndex then
    CommonDropDownListData.DropDownListIndex = DropDownListIndex
  end
  if DropDownListText then
    CommonDropDownListData.DropDownListText = DropDownListText
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.ComType = CommonBtnEnum.ComboBoxType.BigMap
  self.ComboBoxData = CommonDropDownListData
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_MainMap_C:HideMapShowList()
  self.ComboBox:SetPopupVisible(false)
end

function UMG_MainMap_C:UpdateNPCInfoByChangeShowMap()
  self:ClearMapIcons()
end

function UMG_MainMap_C:SetDefaultCenterPos(param, bLerp)
  local heroPos, heroDir = self.data.curShowSceneResId == SceneUtils.GetSceneResId() and self:GetPlayerLocation() or nil
  local CameraDir = self:GetPlayerCameraDir()
  local heroPosX, heroPosY
  if heroPos then
    heroPosX, heroPosY = self:ScenePositionToImagePosition(heroPos.X, heroPos.Y)
    self.uiData.heroPosX = heroPosX
    self.uiData.heroPosY = heroPosY
    self.uiData.heroDir = heroDir
    self:UpdateHeroInfo()
  end
  if CameraDir then
    self.uiData.CameraDir = CameraDir
    self:UpdateCameraInfo()
  end
  local posX, posY
  if 0 ~= self.targetPosX and 0 ~= self.targetPosY then
    posX, posY = self:ScenePositionToImagePosition(self.targetPosX, self.targetPosY)
  elseif heroPos then
    posX = self.uiData.heroPosX
    posY = self.uiData.heroPosY
  else
    posX = self.uiData.originalMapWidth / 2
    posY = self.uiData.originalMapHeight / 2
  end
  self:SetMapCenterPosition(posX, posY, bLerp)
end

function UMG_MainMap_C:CreateHeroTrace(heroPosX, heroPosY, heroDir, sceneResId)
  local traceInfo = {}
  traceInfo.traceType = bigMapModuleEnum.TraceType.Self
  traceInfo.iconImagePos = {x = heroPosX, y = heroPosY}
  traceInfo.dir = heroDir
  traceInfo.sceneResId = sceneResId or BigMapUtils.GetDefaultSceneResId()
  self.data:SetTraceInfoList(traceInfo)
  self.traceIconCreator:Create({traceInfo = traceInfo})
end

function UMG_MainMap_C:RemoveNpcIconByNpcId(npcId, logicId)
  if self.npcIconCreator and self.npcIconCreator:Get(npcId, logicId) then
    self.npcIconCreator:Destroy(npcId, logicId)
    self:AddOrRemoveTempIconInfo(false, nil, npcId, logicId)
  end
end

function UMG_MainMap_C:RemoveCircleIcon(type, key, extraKey)
  extraKey = extraKey or key
  if self.iconCircleCreator and self.iconCircleCreator:Get(type, key, extraKey) then
    self.iconCircleCreator:Destroy(type, key, extraKey)
  end
end

function UMG_MainMap_C:SetMapCenterByNPC(npcRefreshId, scaleValue, bSanctuary, notOpenRightPanel, sceneResId)
  if scaleValue and scaleValue > 0 then
    self.mapScaleSlider:SetValue(scaleValue)
    self:OnMapScaleValueChanged(scaleValue)
  end
  local npcInfo, sceneId = self.data:GetNpcInfoByRefreshId(npcRefreshId, sceneResId)
  if npcInfo then
    local changeSceneId = sceneId
    if changeSceneId and changeSceneId > 0 then
    else
      changeSceneId = BigMapUtils.GetSceneResIdByRefreshId(npcRefreshId)
    end
    if changeSceneId then
      if changeSceneId ~= self.lastOpenMapId then
        if changeSceneId > 0 then
          self:ChangeMapScene(changeSceneId)
        else
          self:ChangeMapScene(BigMapUtils.GetDefaultSceneResId())
        end
      end
    else
      self:ChangeMapScene(BigMapUtils.GetDefaultSceneResId())
      changeSceneId = BigMapUtils.GetDefaultSceneResId()
    end
    if changeSceneId == self.lastOpenMapId then
      local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
      self:SetMapCenterPosition(posX, posY)
      local mousePos = self:GetTempVector2D(posX, posY)
      self.mouseIcon:showAni(mousePos)
      self.mouseIcon:setShowPosition(mousePos)
    end
    local curTraceData = self.data:GetCurTraceNpcData()
    if curTraceData and npcInfo.entry_id == curTraceData.entry_id then
    else
      self:CreateTempIcon(npcInfo, false)
    end
    if npcInfo and not self.module:CheckNpcInFogArea(npcInfo.npc_pos) then
      self.mouseIcon.Slot:SetZOrder(12)
    end
    if not notOpenRightPanel then
      self:OnSingleIconClicked(npcInfo, false, bSanctuary)
    end
  end
end

function UMG_MainMap_C:ChangeMapScene(sceneResId)
  self.data:SetCurShowSceneResId(sceneResId)
  self:SetMapShowList()
  self:UpdateBg(sceneResId)
end

function UMG_MainMap_C:UpdateBg(sceneResId)
  self.BGSwitcher:SetActiveWidgetIndex(self.module:IsShowMaskMap(sceneResId) and 0 or 1)
end

function UMG_MainMap_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.btnScaleMin, self.OnBtnScaleMinClick)
  self:AddButtonListener(self.btnScaleMax, self.OnBtnScaleMaxClick)
  self:AddButtonListener(self.btnClose1, self.OnBtnClose1Click)
  self:AddButtonListener(self.BtnHome.btnLevelUp, self.OnClickBtnHome)
  self:AddButtonListener(self.BtnClaimfull.btnLevelUp, self.OnBtnClaimfull)
  self:AddButtonListener(self.Sanctuary.btnLevelUp, self.OnOpenSanctuaryTips)
  self:AddDelegateListener(self.mapScaleSlider.OnValueChanged, self.OnMapScaleValueChanged)
  self:AddButtonListener(self.Hint.btnLevelUp, self.OnHintDetailsClicked)
  self:AddButtonListener(self.Btn_ComboBox, self.OnCollectionBtnClicked)
  self:RegisterEvent(self, BigMapModuleEvent.ShowNormalNpcEvent, self.OnSingleIconClicked)
  self:RegisterEvent(self, BigMapModuleEvent.WorldMapInfoUpateEvent, self.OnWorldMapInfoUpdateEvent)
  self:RegisterEvent(self, BigMapModuleEvent.WorldMapInfoChangeEvent, self.OnWorldMapInfoChangeEvent)
  self:RegisterEvent(self, BigMapModuleEvent.ClickTraceIconEvent, self.OnClickTraceIconEvent)
  self:RegisterEvent(self, BigMapModuleEvent.TraceNpcEvent, self.OnTraceNpcEvent)
  self:RegisterEvent(self, BigMapModuleEvent.CancelTraceNpcEvent, self.OnCancelTraceNpcEvent)
  self:RegisterEvent(self, BigMapModuleEvent.ClearNPCListSelectedState, self.ClearNPCListSelectedState)
  self:RegisterEvent(self, BigMapModuleEvent.ShowNPCList, self.ShowNPCList)
  self:RegisterEvent(self, BigMapModuleEvent.HideNPCList, self.OnHideNPCList)
  self:RegisterEvent(self, BigMapModuleEvent.SetMapCenterPosEvent, self.SetMapCenterPosition)
  self:RegisterEvent(self, BigMapModuleEvent.MainMapRightPanelHide, self.OnMainMapRightPanelHideEvent)
  self:RegisterEvent(self, BigMapModuleEvent.StarNumChange, self.UpdateHealth)
  self:RegisterEvent(self, BigMapModuleEvent.MarkerSelectEvent, self.UpdateSelectMarker)
  self:RegisterEvent(self, BigMapModuleEvent.MapMarkOperateChangeEvent, self.OnMapMarkOperateChange)
  self:RegisterEvent(self, BigMapModuleEvent.SetMarkerEvent, self.SetMarkerEvent)
  self:RegisterEvent(self, BigMapModuleEvent.SetSliderVisible, self.OnSetSliderVisible)
  self:RegisterEvent(self, BigMapModuleEvent.ChangeIsTravel, self.OnChangeIsTravel)
  self:RegisterEvent(self, BigMapModuleEvent.OnUpdateTravelInfos, self.OnUpdateTravelInfos)
  self:RegisterEvent(self, BigMapModuleEvent.SwitchSelectIconEvent, self.SwitchSelectIconEvent)
  self:RegisterEvent(self, BigMapModuleEvent.StartOrCancelTraceEvent, self.OnStartOrCancelTraceEvent)
  self:RegisterEvent(self, BigMapModuleEvent.ShowTaskIconInfo, self.OnShowTaskIconInfo)
  self:RegisterEvent(self, BigMapModuleEvent.UpdateTraceEffect, self.OnUpdateTraceEffect)
  self:RegisterEvent(self, BigMapModuleEvent.ChangeSelectedScene, self.OnChangeSelectedScene)
  self:RegisterEvent(self, BigMapModuleEvent.CampFruitNpcsInfoListSetFinish, self.OnFruitNpcsInfoListSetFinish)
  self:RegisterEvent(self, BigMapModuleEvent.ShowMapHint, self.ShowHint)
  self:RegisterEvent(self, BigMapModuleEvent.ShowSanctuary, self.ShowSanctuary)
  _G.NRCEventCenter:RegisterEvent("UMG_MainMap_C", self, TaskModuleEvent.TASK_DATA_CHANGE, self.OnUpdateShowTaskInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_MainMap_C", self, TravelModuleEvent.OnOutTravel, self.OnOutTravel)
  _G.NRCEventCenter:RegisterEvent("UMG_MainMap_C", self, TravelModuleEvent.OnCloseTravelPanel, self.OnCloseTravelPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_MainMap_C", self, TravelModuleEvent.HideMainMapLoupe, self.OnHideMainMapLoupe)
end

function UMG_MainMap_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, TravelModuleEvent.OnOutTravel, self.OnOutTravel)
  _G.NRCEventCenter:UnRegisterEvent(self, TravelModuleEvent.OnCloseTravelPanel, self.OnCloseTravelPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, TravelModuleEvent.HideMainMapLoupe, self.OnHideMainMapLoupe)
  _G.NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.TASK_DATA_CHANGE, self.OnUpdateShowTaskInfo)
end

function UMG_MainMap_C:HidePanel()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_BIGMAP_CLOSE)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  if not self.playAniNpcRefreshId or self.playAniNpcRefreshId.WorldFast then
  end
  self.bClosing = false
  self:DoClose()
end

function UMG_MainMap_C:OnCloseButtonClicked()
  if self:CheckIsSelectBtn() then
    return
  end
  self.bClosing = true
  self:ShowAllMap(self.data.curShowSceneResId)
  local mappingContext = self:GetInputMappingContext("IMC_MapUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseMapQuick")
    mappingContext:UnBindAction("IA_CloseMapUI")
  end
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.PlayUnlockUIShowByEnum, _G.Enum.FunctionEntrance.FE_MAP)
  Log.Debug("[TxTest]UMG_MainMap_C:OnCloseButtonClicked")
  UE4Helper.SetEnableWorldRendering(true)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401010, "UMG_MainMap_C:OnCloseButtonClicked")
  self.data:DumpRedDotByGuideBooks()
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.CloseHabitTips)
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CloseTravelMainMap)
  self:SetPanelReadyToClosed()
  if not self:IsAnimationPlaying(self.close) or not self:IsAnimationPlaying(self.close2) then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1248, "UMG_MainMap_C:OnCloseButtonClicked")
    Log.Debug("Play close Anim ")
    self:PlayAnimation(self.close)
  end
  self.btnClose:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  if self.module then
    self.module:OnCloseOwlSanctuaryNpcListPanel()
  end
end

function UMG_MainMap_C:OnBtnClose1Click(bStraight)
  self:HideNPCList()
  if bStraight then
    self.mouseIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.mouseIcon:showEndAni()
  end
end

function UMG_MainMap_C:OnBtnClaimfull()
  if self:CheckIsSelectBtn() or self.bClosing then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "MainBigMap").GETALL
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BigMapModule", "MainBigMap", touchReasonType)
  for i = 1, #self.travelInfos do
    if self.travelInfos[i].travel_complete then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_MainMap_C:OnBtnClaimfull")
      _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.OnCmdZoneCompleteAllPetTravelReq)
      return
    end
  end
end

function UMG_MainMap_C:OnOpenSanctuaryTips()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_OWL_LIST, true)
  if isBan then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "MainBigMap").SWITCH
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BigMapModule", "MainBigMap", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(40002001, "UMG_MainMap_C:OnOpenSanctuaryTips")
  if self.OpenFlag then
    self.OpenFlag = false
  else
    self.OpenFlag = true
  end
  _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.OnToggleOwlSanctuaryNpcListPanel, self.OpenFlag)
end

function UMG_MainMap_C:SetNPCListDatas()
  local npcDatas = self.data:GetCurTraceNpcData()
  local itemNum = math.random(1, 5)
  for i = 1, itemNum do
    table.insert(self.npcListData, npcDatas)
  end
  if self.npcListData ~= nil then
    self.npcListLayer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.npcList:SetDatas(self.npcListData)
  end
end

function UMG_MainMap_C:ShowNPCList(_datas)
  _G.NRCModeManager:DoCmd(BigMapModuleCmd.CloseMapRightPanel)
  if not self.module:CheckMapRightPanelOpened() then
    self.npcListData = _datas
    self.npcListLayer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.npcList:SetDatas(_datas)
    self.npcList:PlayOpenAnim()
    self.module:SetMapPanelCanTouchMove(false)
  end
end

function UMG_MainMap_C:HideNPCList()
  self.npcListLayer:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.npcList:ClearSelectedState()
  self.npcListData = {}
  self.module:SetMapPanelCanTouchMove(true)
end

function UMG_MainMap_C:OnHideNPCList()
  self:HideNPCList()
end

function UMG_MainMap_C:ClearNPCListSelectedState()
  self.npcList:ClearSelectedState()
end

function UMG_MainMap_C:OnBtnScaleMinClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401008, "UMG_MainMap_C:OnBtnScaleMinClick")
  self:ChangeMapScaleSliderValue(-0.1)
end

function UMG_MainMap_C:OnBtnScaleMaxClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401007, "UMG_MainMap_C:OnBtnScaleMaxClick")
  self:ChangeMapScaleSliderValue(0.1)
end

function UMG_MainMap_C:OnMapScaleValueChanged(_value)
  if self.uiData.mapSliderScale == _value then
    return
  end
  self:SetMapScale(self:GetMapImageScale(_value), false, _value)
  self:UpdateMapByPosition()
  if _G.GlobalConfig.bShowMapScale then
    Log.Error("\229\156\176\229\155\190\229\189\147\229\137\141\231\188\169\230\148\190\230\175\148\228\190\139\228\184\186:" .. self.imageScale.X)
  end
end

function UMG_MainMap_C:OnTravelToggleBtn()
  self.travelToggle = not self.travelToggle
  if self.travelToggle then
    self:PlayAnimation(self.Pop_ups_In)
    self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self:PlayAnimation(self.Pop_ups_Out)
  end
end

function UMG_MainMap_C:InitTravelData()
  if _G.TravelModuleCmd then
    self.travelInfos = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetTravelInfos)
  end
  self:ShowTravelRewardBtn()
  self.MaxTravelNum = _G.DataConfigManager:GetPetGlobalConfig("travel_times").num
end

function UMG_MainMap_C:OpenTravelPanel(info)
  local isMax = self.travelInfos ~= nil and #self.travelInfos >= self.MaxTravelNum
  if _G.TravelModuleCmd then
    local downTime = self:GetTravelDownTime(info.npc_refresh_id)
    _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.OpenTravelPanel, info, downTime, isMax)
  end
end

function UMG_MainMap_C:GetTravelDownTime(npc_refresh_id)
  local entryId = self.ContentToEntryIdDic[npc_refresh_id]
  local icon = self.npcIconCreator:Get(entryId)
  if UE4.UObject.IsValid(icon) then
    return icon:GetTravelDownTime()
  end
  return 0
end

function UMG_MainMap_C:OnCloseTravelPanel()
  self.left_buttons:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self:OnMainMapRightPanelHideEvent()
end

function UMG_MainMap_C:OnHideMainMapLoupe()
  self.left_buttons:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MainMap_C:OnUpdateTravelInfos(travelInfos)
  for k, v in ipairs(self.creatorList) do
    if v.OnTravelInfoUpdated then
      v:OnTravelInfoUpdated(travelInfos)
    end
    if v.OnTravelStateChanged then
      v:OnTravelStateChanged(true)
    end
  end
  self.travelInfos = travelInfos
  if self.travelInfos then
    self.CanvasPanel_1:InitNum(#travelInfos, self.MaxTravelNum, LuaText.travel_text)
  else
    self.CanvasPanel_1:InitNum(0, self.MaxTravelNum, LuaText.travel_text)
  end
  if self.module == nil then
    self.module = _G.NRCModeManager:GetModule("BigMapModule")
  end
  self:ShowTravelRewardBtn()
  self:ResetTraceTravelIcon()
  self:UpdateTraceIconPositionAndVisible()
end

function UMG_MainMap_C:OnOutTravel(camp_content_id)
  local entryId = self.ContentToEntryIdDic[camp_content_id]
  local icon = self.npcIconCreator:Get(entryId)
  icon:PlayOutTravel()
  for i = 1, #self.travelInfos do
    if self.travelInfos[i] and self.travelInfos[i].camp_content_id == camp_content_id then
      table.remove(self.travelInfos, i)
    end
  end
  self:RemoveTravelIconByID(camp_content_id)
end

function UMG_MainMap_C:RemoveTravelIconByID(camp_content_id)
  self.traceIconCreator:CancelTraceByID(bigMapModuleEnum.TraceType.Travel, camp_content_id)
end

function UMG_MainMap_C:CreateTraceTravelIcon(refresh_id, travelInfo, _posX, _posY)
  local travelTraceInfo = {}
  travelTraceInfo.traceType = bigMapModuleEnum.TraceType.Travel
  travelTraceInfo.travelInfo = travelInfo
  travelTraceInfo.iconImagePos = {x = _posX, y = _posY}
  self.traceIconCreator:Create({traceInfo = travelTraceInfo})
end

function UMG_MainMap_C:ResetTraceTravelIcon()
  self.traceIconCreator:CancelTrace(bigMapModuleEnum.TraceType.Travel)
  self:CreateAllTraceTravelIcon()
end

function UMG_MainMap_C:CreateAllTraceTravelIcon()
  if not self.isTravel then
    return
  end
  if self.travelInfos == nil or 0 == #self.travelInfos then
    return
  end
  self.showNpcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
  if self.showNpcDatas then
    for k, v in pairs(self.showNpcDatas) do
      for i, j in pairs(v) do
        local posX, posY = self:ScenePositionToImagePosition(j.npc_pos.x, j.npc_pos.y)
        for index = 1, #self.travelInfos do
          local travelInfo = self.travelInfos[index]
          if travelInfo.camp_content_id == j.npc_refresh_id then
            self:CreateTraceTravelIcon(j.npc_refresh_id, travelInfo, posX, posY)
            break
          end
        end
      end
    end
  end
end

function UMG_MainMap_C:GetLayerIdByIconTypeAndKey(type, _Info)
  local showLayerId = 0
  if type == bigMapModuleEnum.CreatorPriority.NpcIcons then
    local iconWidget = self.npcIconCreator:Get(_Info.entry_id, _Info.logic_id)
    if iconWidget and UE4.UObject.IsValid(iconWidget) then
      showLayerId = iconWidget.mapLayerId
    elseif _Info.world_map_cfg_id then
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(_Info.world_map_cfg_id)
      if worldMapConf and worldMapConf.layered_id and #worldMapConf.layered_id > 0 then
        showLayerId = worldMapConf.layered_id[1]
      end
    end
  elseif type == bigMapModuleEnum.CreatorPriority.MarkerIcons then
    local iconWidget = self.markerIconCreator:Get(_Info.mark_id)
    if iconWidget and UE4.UObject.IsValid(iconWidget) then
      showLayerId = iconWidget.mapLayerId
    end
  elseif type == bigMapModuleEnum.CreatorPriority.TaskIcons then
    showLayerId = 0
  end
  return showLayerId
end

function UMG_MainMap_C:SetLayerMapListByClickIcon(showLayerId)
  if showLayerId and showLayerId > 0 then
    self:SetLayerMapList(showLayerId)
  elseif self.data.curShowSceneResId ~= 30001 then
    self:SetLayerMapList(0)
  else
    self:SetLayerMapList(14)
  end
end

function UMG_MainMap_C:OnSingleIconClicked(_Info, type, bSanctuary)
  local showLayerId = self:GetLayerIdByIconTypeAndKey(bigMapModuleEnum.CreatorPriority.NpcIcons, _Info) or 0
  self:SetLayerMapListByClickIcon(showLayerId)
  self:ShowNpcRightPanel(_Info, false, bSanctuary)
end

function UMG_MainMap_C:SetLayerByTask(_Info)
  local showLayerId = self:GetLayerIdByIconTypeAndKey(bigMapModuleEnum.CreatorPriority.TaskIcons, _Info) or 0
  self:SetLayerMapListByClickIcon(showLayerId)
end

function UMG_MainMap_C:OnShowNormalNpcEvent(_info, bSanctuary)
  self.NRCGridView_62:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PromptBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.isTravel then
    return
  end
  if not bSanctuary then
    self:ShowHint(false)
    self:ShowSanctuary(false)
    _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.ExcludeUmgPanelEvent, "NpcInfo")
  end
  if _info.npcCfg then
    local worldMapCfg = self.WorldMapConfigs[_info.world_map_cfg_id]
    if worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_DUNGEON then
      self.module:OnCmdSendZoneDungeonInfoQueryReq(_info, worldMapCfg.dungeon_id)
    elseif worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_TEAM_BATTLE then
      self.module:OnCmdSendZoneTeamBattleInfoQueryReq(_info, TeamBattleModuleEnum.EntranceType.Map)
    elseif worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_LEGENDARY_BATTLE then
      self.module:OnCmdSendZoneSceneQueryBeastChallengeReq(_info)
    elseif worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_HOME then
      local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
      local PlayerUinDisplayHome = homeBriefInfo.home_owner_id or 0
      self.module:OnCmdSendZoneHomeQueryFriendHomeInfoReq(_info, PlayerUinDisplayHome)
    elseif worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_PLANT and not _G.NRCModeManager:DoCmd(_G.HomeModuleCmd.IsInHomeScene) then
      local homeBriefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo() or {}
      local PlayerUinDisplayHome = homeBriefInfo.home_owner_id or 0
      self.module:OnCmdSendZoneHomeQueryFriendHomeInfoReq_Plant(_info, PlayerUinDisplayHome)
    else
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenMapMagicPanel, _info, worldMapCfg)
    end
  elseif _info.MarksType and _info.MarksType == bigMapModuleEnum.MarksType.CustomMark then
    self:NewMarkerEvent(_info.imageCenterPos, 35, _info.mark_id)
  elseif _info.visitorIndex and _info.visitorIndex > 0 then
    local worldMapConf = _G.DataConfigManager:GetWorldMapConf(60000001)
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenMapRightPanel, 0, _info, worldMapConf)
  else
    local worldMapConf = self.WorldMapConfigs[_info.world_map_cfg_id]
    _G.NRCModeManager:DoCmd(BigMapModuleCmd.OpenMapRightPanel, 0, _info, worldMapConf)
  end
end

function UMG_MainMap_C:OnShowNormalNpcEventDungeon(_info, rspInfo)
  local worldMapConf = self.WorldMapConfigs[_info.world_map_cfg_id]
  self.module:OnCmdOpenMapRightPanel(0, _info, worldMapConf, rspInfo)
end

function UMG_MainMap_C:OnShowNormalNpcEventTeamBattleTips(_info, rspInfo)
  local worldMapConf = self.WorldMapConfigs[_info.world_map_cfg_id]
  self.module:OnCmdOpenMapRightPanel(0, _info, worldMapConf, rspInfo)
end

function UMG_MainMap_C:OnShowNormalNpcEventLegendaryBattle(_info, rspInfo)
  local worldMapConf = self.WorldMapConfigs[_info.world_map_cfg_id]
  self.module:OnCmdOpenMapRightPanel(0, _info, worldMapConf, rspInfo)
end

function UMG_MainMap_C:OnShowNormalNpcEventHome(_info, rspInfo)
  local worldMapConf = self.WorldMapConfigs[_info.world_map_cfg_id]
  self.module:OnCmdOpenMapRightPanel(0, _info, worldMapConf, rspInfo)
end

function UMG_MainMap_C:OnShowNormalNpcEventPlant(_info, rspInfo)
  local worldMapConf = self.WorldMapConfigs[_info.world_map_cfg_id]
  self.module:OnCmdOpenMapRightPanel(0, _info, worldMapConf, rspInfo)
end

function UMG_MainMap_C:UpdateHealth()
  if self.enableView then
    local moneyInfo = {}
    local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
    StarDebrisNum = StarDebrisNum or 0
    local staminaA = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit")
    local StaminaProportionA = ""
    if StarDebrisNum >= staminaA.num then
      StaminaProportionA = string.format("%s", staminaA.num)
    elseif StarDebrisNum >= 0 and StarDebrisNum < staminaA.num then
      StaminaProportionA = string.format("%s", StarDebrisNum)
    end
    local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    local staminaB = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
    local StaminaProportionB = string.format("%s%s%s", StarNum, "/", staminaB.num)
    table.insert(moneyInfo, {
      moneyType = _G.Enum.VisualItem.VI_STAR,
      sum = StaminaProportionB,
      IsShowBuyIcon = true,
      Call = self,
      Handler = self.HideMoneyBtn,
      SourceReturnFlag = self,
      SourceReturnFunc = self.ShowMoneyBtn
    })
    table.insert(moneyInfo, {
      moneyType = _G.Enum.VisualItem.VI_STAR_DEBRIS,
      sum = StaminaProportionA,
      IsShowBuyIcon = true,
      Call = self,
      Handler = self.HideMoneyBtn,
      SourceReturnFlag = self,
      SourceReturnFunc = self.ShowMoneyBtn
    })
    self.MoneyBtn:InitGridView(moneyInfo)
    if StarDebrisNum >= staminaA.num then
      self.MoneyBtn:GetItemByIndex(1).Full:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif StarDebrisNum >= 0 and StarDebrisNum < staminaA.num then
      self.MoneyBtn:GetItemByIndex(1).Full:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MainMap_C:ShowMoneyBtn()
  if self.MoneyBtn and UE4.UObject.IsValid(self.MoneyBtn) then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_MainMap_C:HideMoneyBtn()
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MainMap_C:OnWorldMapInfoUpdateEvent(npcDatas, mapAreaDatas)
  self:ShowMapFogInfo(npcDatas)
  self.showAreaNpcDatas = self.data:GetAllShowAreaNpcs()
  self:UpdateNPCInfoByChangeShowMap()
  self:ShowMapAreaInfo()
  self:DelayFrames(1, function()
    self:OnWorldMapInfoUpdateEvent_DelayFunc()
    if self.data:GetSelectTaskId() then
      self:OnShowTaskIcon(self.data.curShowSceneResId)
    end
  end)
end

function UMG_MainMap_C:OnWorldMapInfoUpdateEvent_DelayFunc()
  self.data:SetAllMapShowNpcs()
  self.data:SetAllMapShowAreaNpcs()
  self.showNpcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
  self.showAreaNpcDatas = self.data:GetAllShowAreaNpcs()
  self:OnShowMarker(nil, nil, self.data.curShowSceneResId)
  local curWndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.traceLayer:GetCachedGeometry())
  if 0 ~= curWndSize.X and 0 ~= curWndSize.Y then
    self.curWndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.traceLayer:GetCachedGeometry())
  end
  self:UpdateMapByPosition()
  self:UpdateTraceIconPositionAndVisible()
  if self.showNpcDatas then
    for _, datas in pairs(self.showNpcDatas) do
      for _, npcInfo in pairs(datas) do
        if npcInfo.npc_refresh_id and npcInfo.entry_id then
          self.ContentToEntryIdDic[npcInfo.npc_refresh_id] = npcInfo.entry_id
        end
      end
    end
  end
  if self.playOpenAnimation then
    self:SetRenderOpacity(1)
    _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
    self.playOpenAnimation = false
  end
  self.module:DeleteForceTraceInfo()
  self:CreateTraceIcon()
  self.data.lastShowSceneResId = self.data.curShowSceneResId
end

function UMG_MainMap_C:OnWorldMapInfoChangeEvent()
  local npcDatas = self.data:GetNpcDatas()
  self:ShowMapFogInfo(npcDatas)
  npcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
  self.showNpcDatas = npcDatas
  self.showAreaNpcDatas = self.data:GetAllShowAreaNpcs()
  self:UpdateNPCInfoByChangeShowMap()
  self:ShowMapAreaInfo()
end

function UMG_MainMap_C:OnClickTraceIconEvent(_traceIcon)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_MainMap_C:OnClickTraceIconEvent")
  if _traceIcon and _traceIcon:IsUsable() then
    local posX, posY = _traceIcon:GetImagePosition()
    self.EndPos = {X = posX, Y = posY}
    self.LerpToNewMapCenterPos = true
    self.isTouchClick = false
  end
end

function UMG_MainMap_C:SwitchSelectIconEvent(id, bSanctuary)
  if nil == id then
    return
  end
  local npcInfo = self.data:GetNpcInfoByRefreshId(id)
  local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
  local sceneResId = BigMapUtils.GetSceneResIdByPos(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
  if sceneResId == self.data.curShowSceneResId then
    self.EndPos = {X = posX, Y = posY}
    self.LerpToNewMapCenterPos = true
    self.endPosLayerId = self:GetLayerIdByIconTypeAndKey(bigMapModuleEnum.CreatorPriority.NpcIcons, npcInfo) or 0
  else
    self:SetTargetPos(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
    local MapShowList = self.ComboBox.ComboBox_Popup.List_title:GetItemCount()
    for i = 1, MapShowList do
      local item = self.ComboBox.ComboBox_Popup.List_title:GetItemByIndex(i - 1)
      if item then
        local _sceneResId = item.uiData and item.uiData.sceneResId
        if _sceneResId == sceneResId then
          self.ComboBox.ComboBox_Popup:SelectListItem(i - 1)
          break
        end
      end
    end
  end
  self.isTouchClick = false
  self.mouseIcon:showEndAni()
  self.mapScaleSlider:SetValue(0.5)
  self:OnMapScaleValueChanged(0.5)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_MainMap_C:SwitchSelectIconEvent")
  local mousePos = self:GetTempVector2D(posX, posY)
  self.mouseIcon:showAni(mousePos)
  self.mouseIcon:setShowPosition(mousePos)
  self:DelayFrames(10, function()
    self:OnSingleIconClicked(npcInfo, nil, bSanctuary)
  end)
end

function UMG_MainMap_C:OnStartOrCancelTraceEvent(bStart, traceInfo)
  local traceType = traceInfo.traceType
  for k, v in ipairs(self.creatorList) do
    if v and v.SetTraceEffect then
      if traceType == bigMapModuleEnum.TraceType.Marker then
        v:SetTraceEffect(bStart, traceInfo.markInfo.mark_id)
      elseif traceType == bigMapModuleEnum.TraceType.NPC then
        v:SetTraceEffect(bStart, traceInfo.npcInfo.entry_id, traceInfo.npcInfo.logic_id)
      elseif traceType == bigMapModuleEnum.TraceType.AutoTrace then
        v:SetTraceEffect(bStart, traceInfo.npcInfo.entry_id, traceInfo.npcInfo.logic_id)
      end
    end
  end
  if self.traceIconCreator then
    local itemData = {traceInfo = traceInfo}
    if bStart then
      self.traceIconCreator:StartTrace(itemData)
    else
      self.traceIconCreator:CancelTrace(traceType)
    end
  end
  if traceType == bigMapModuleEnum.TraceType.NPC then
    if bStart then
      self:OnTraceNpcEvent(traceInfo.npcInfo.entry_id, traceInfo.npcInfo.logic_id)
    else
      self:OnCancelTraceNpcEvent(traceInfo.npcInfo.entry_id, nil, traceInfo.npcInfo.logic_id)
    end
    if self.module:CheckMapRightPanelOpened() then
      self.module:OnCmdCloseMapRightPanel()
    end
  end
end

function UMG_MainMap_C:OnTraceNpcEvent(_npcId, logic_id)
  self:UpdateTraceIconPositionAndVisible()
  if 0 ~= _npcId then
    local npcIcon = self.npcIconCreator:Get(_npcId, logic_id)
    if npcIcon then
      npcIcon:UpdateMapShowLevel(self.uiData.mapSliderScale, true)
    end
  end
  self:ShowTempTraceIcons()
end

function UMG_MainMap_C:OnCancelTraceNpcEvent(_npcId, _isNpc, _logic_id)
  self:PlayNpcTraceEffect(_npcId, false, true)
  self:PlayNpcTraceEffect(_npcId, false, false)
  if 0 ~= _npcId then
    local npcIcon = self.npcIconCreator:Get(_npcId, _logic_id)
    if npcIcon and npcIcon.WorldMapConfig then
      local npcInfo = npcIcon.uiData
      local sceneResId, CanShowMap
      if npcInfo and npcInfo.npc_pos then
        sceneResId = BigMapUtils.GetSceneResIdByPos(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
        CanShowMap = self.data:CheckShouldShowNpc(npcInfo)
      end
      npcIcon:UpdateMapShowLevel(self.uiData.mapSliderScale, true)
      if npcIcon.WorldMapConfig.map_show_type == _G.Enum.MapIconShowType.MAP_HANDBOOK_TRACK then
        self:RemoveTempIconWithRightPanel(_npcId, _logic_id)
      elseif self:CheckIsTempIcon(_npcId, _logic_id) then
        self:RemoveTempIconWithRightPanel(_npcId, _logic_id)
      end
    end
  end
  self.showNpcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
end

function UMG_MainMap_C:RemoveTempIconWithRightPanel(entryId, logicId)
  self:RemoveNpcIconByNpcId(entryId, logicId)
  if self.module:CheckMapRightPanelOpened() then
    self.module:OnCmdCloseMapRightPanel()
  end
end

function UMG_MainMap_C:CheckIsTempIcon(entryId, logicId)
  local itemData = self.npcIconCreator:GetItemData(entryId, logicId)
  if itemData and itemData.iconData then
    return itemData.iconData.bTemp
  end
  return false
end

function UMG_MainMap_C:OnMainMapRightPanelHideEvent(map_show_tip_type, npc_refresh_id)
  self:ShowOrHideMoneyBtn(true)
  self:UndoSelectIconScale()
  if self.mouseIcon.isShow then
    self.mouseIcon:showEndAni()
    self.Customdot_2:SetIsVisible(false)
  end
  local curTraceData = self.data:GetCurTraceNpcData()
  if curTraceData and npc_refresh_id == curTraceData.npc_refresh_id then
    return
  end
  local npcInfo = self.data:GetNpcInfoByRefreshId(npc_refresh_id)
  if npcInfo and self:CheckIsTempIcon(npcInfo.entry_id, npcInfo.logic_id) then
    self:RemoveNpcIconByNpcId(npcInfo.entry_id, npcInfo.logic_id)
  end
  if map_show_tip_type and map_show_tip_type == _G.Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP and npc_refresh_id and npcInfo and npcInfo.npc_pos and (not self.module:CheckNpcInFogArea(npcInfo.npc_pos) or not self.data:CheckShouldShowNpc(npcInfo)) then
    local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
    local iconData = {}
    iconData.layerIndex = 1
    iconData.iconImagePos = {x = posX, y = posY}
    iconData.curMapSliderScale = self.uiData.mapSliderScale
    iconData.curMapImageScale = self.uiData.mapImageScale
    iconData.bTracing = false
    if self.npcIconCreator then
      self.npcIconCreator:Create({iconData = iconData, npcInfo = npcInfo})
    end
  end
end

function UMG_MainMap_C:GetMapCenterPos()
  return {
    x = self.uiData.mapCenterX,
    y = self.uiData.mapCenterY,
    z = 0
  }, self.uiData.mapSliderScale
end

function UMG_MainMap_C:OnTouchStarted(_MyGeometry, _InTouchEvent)
  self.isTouchScale = false
  self.isTouchClick = true
  self.TouchStartTime = 0
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainMap_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self.NRCGridView_62:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PromptBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:HideMapShowList()
  self.TouchStartTime = 0
  self.isTouchScale = false
  self.bMoveable = true
  local pointerIndex = UE4.UKismetInputLibrary.PointerEvent_GetPointerIndex(_InTouchEvent)
  if 0 ~= pointerIndex then
    Log.Debug("pointerIndex\233\151\174\233\162\152--UMG_MainMap_C:OnTouchEnded")
    pointerIndex = 0
  end
  if self.isTouchClick and 0 == pointerIndex then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40003001, "UMG_IconNpcTemple_C:ShowSelectState")
    local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.traceLayer:GetCachedGeometry())
    if wndSize.X <= 0 or wndSize.Y <= 0 then
      Log.Debug("traceLayer\233\151\174\233\162\152--UMG_MainMap_C:OnTouchEnded")
      return UE4.UWidgetBlueprintLibrary.Unhandled()
    end
    local a = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_InTouchEvent)
    local b = UE4.USlateBlueprintLibrary.LocalToAbsolute(_MyGeometry, self.vector2DZero)
    local screenPos = a - b
    UE4.USlateBlueprintLibrary.ScreenToViewportConsiderBorder(_G.UE4Helper.GetCurrentWorld(), screenPos, screenPos)
    self.ScreenPos = screenPos
    self.ScreenPos.X = self.ScreenPos.X * self.DpiScaleY
    self.ScreenPos.Y = self.ScreenPos.Y * self.DpiScaleY
    local pos = {}
    pos.X = screenPos.X - wndSize.X / 2
    pos.Y = screenPos.Y - wndSize.Y / 2
    local uiData = self.uiData
    pos.X = pos.X / uiData.mapImageScale + (uiData.mapCenterX or 0)
    pos.Y = pos.Y / uiData.mapImageScale + (uiData.mapCenterY or 0)
    local tX, tY = self:ScenePositionToImagePosition(self:ImagePositionToScenePosition(pos.X, pos.Y))
    Log.Debug("[Map] [Marker] pos.X,pos.Y =>", pos.X, pos.Y, tX, tY)
    pos.X = tX
    pos.Y = tY
    local mousePos = UE4.FVector2D(pos.X, pos.Y)
    self.dot_2HasMapMask = false
    self.dot_2HasMark = false
    if not self.isTravel then
      self.mouseIcon.Slot:SetZOrder(12)
      self.Customdot_2.Slot:SetZOrder(2)
      self.dot_2Pos = UE4.FVector2D(mousePos.X, mousePos.Y)
      local posU = pos.X / self.uiData.originalMapWidth
      local posV = pos.Y / self.uiData.originalMapHeight
      local RValue = UE4.UNRCTUIStatics.GetTexture2DPixelColorFromUV(self.data.FullMaskRunTime, UE4.FVector2D(posU, posV))
      if RValue.R <= 125 and BigMapUtils.CheckShowMapMask(self.data.curShowSceneResId) then
        self.mouseIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.mouseIcon.Slot:SetZOrder(12)
        self.Customdot_2.Slot:SetZOrder(4)
        self.dot_2Pos = mousePos
        self.dot_2HasMapMask = true
      end
    end
    Log.Debug(pos.X, pos.Y, "--UMG_MainMap_C:OnTouchEnded")
    self:ShowNpcListForRange(pos, 50)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_MainMap_C:GetTouchScaleInfo()
  local locationX0, locationY0, bPressed0 = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(0)
  local locationX1, locationY1, bPressed1 = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(1)
  if bPressed0 and bPressed1 then
    local p0 = UE4.FVector2D(locationX0, locationY0)
    local p1 = UE4.FVector2D(locationX1, locationY1)
    return true, (p1 - p0):Size()
  else
    return false, 0
  end
end

function UMG_MainMap_C:ResetConsumedTouchMoveFrameCount()
  self.consumedTouchMoveFrameCount = 0
  self.deltaXSinceLastFrame = 0
  self.deltaYSinceLastFrame = 0
end

function UMG_MainMap_C:OnTouchMoved(_MyGeometry, _InTouchEvent)
  local deltaX, deltaY = FPointerEvent_GetCursorDelta(_InTouchEvent)
  local viewportScale = UE4.UWidgetLayoutLibrary.GetViewportScaleConsiderBorder(_G.UE4Helper.GetCurrentWorld())
  if viewportScale and viewportScale > 0 then
    deltaX = deltaX / viewportScale
    deltaY = deltaY / viewportScale
  end
  local currentFrameCount = GetFrameCount()
  if self.consumedTouchMoveFrameCount ~= currentFrameCount then
    local bConsumed = self:TryConsumeTouchMoved(self.deltaXSinceLastFrame, self.deltaYSinceLastFrame)
    if bConsumed then
      self.consumedTouchMoveFrameCount = currentFrameCount
      self.deltaXSinceLastFrame = 0
      self.deltaYSinceLastFrame = 0
    end
  end
  self.deltaXSinceLastFrame = self.deltaXSinceLastFrame + deltaX
  self.deltaYSinceLastFrame = self.deltaYSinceLastFrame + deltaY
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainMap_C:TryConsumeTouchMoved(deltaX, deltaY)
  self.bMoveable = true
  if not _G.FPointerEvent_GetCursorDelta or self.IsCanMove == false or self.LerpToNewMapCenterPos then
    return false
  end
  if self.TouchStartTime and self.TouchStartTime < 0.075 then
    return false
  end
  local isTwoTouch, touchDistance = self:GetTouchScaleInfo()
  if isTwoTouch then
    if self.isTouchScale then
      local distance = touchDistance - self.oldTwoTouchDistance
      self:ChangeMapScaleSliderValue(0.005 * distance)
    else
      self.isTouchScale = true
    end
    self.oldTwoTouchDistance = touchDistance
  else
    local uiData = self.uiData
    self.bMoveable = true
    self:SetMapCenterPosition(uiData.mapCenterX - deltaX / self.imageScale.X, uiData.mapCenterY - deltaY / self.imageScale.Y)
    self.isTouchScale = false
  end
  self.lastShowPieceIdList = self.curShowPieceIdList
  return true
end

function UMG_MainMap_C:ShowOrHideMoneyBtn(show)
  if show then
    if self.isTravel == false then
      self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.btnClose:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Customdot_2:SetIsVisible(false)
  end
end

function UMG_MainMap_C:CheckMapPieceChange(curPieceList)
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

function UMG_MainMap_C:CreateVisibleNpc()
  if not self.showNpcDatas then
    self.showNpcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
  end
  if self.showNpcDatas then
    self:GetWndShowMapRange()
    if self.curShowPieceIdList and #self.curShowPieceIdList > 0 then
      for key, mapPieceId in ipairs(self.curShowPieceIdList) do
        if self.showNpcDatas[mapPieceId] then
          for entryId, npcInfos in pairs(self.showNpcDatas[mapPieceId]) do
            for logicId, npcInfo in pairs(npcInfos) do
              if self:CheckNpcShowInMap(npcInfo) then
                self:ShowNpcInfoSingle(npcInfo)
              end
            end
          end
        end
        local showAreaNames = self.data.areaDatas[self.data.curShowSceneResId]
        if showAreaNames and showAreaNames[mapPieceId] then
          self:ShowAreaInfo(showAreaNames[mapPieceId])
        end
      end
    end
  end
  if self.isTravel and self.IsFirstOpen then
    self:OnUpdateTravelInfos(self.travelInfos)
  end
  self.IsFirstOpen = false
end

function UMG_MainMap_C:CheckNpcShowInMap(npcInfo)
  if npcInfo.npc_pos == nil then
    Log.Error("npcInfo.npc_pos is nil")
    Log.Dump(npcInfo, 4, "UMG_MainMap_C:CheckNpcShowInMap")
    return false
  end
  local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
  if not self:CheckNpcIsInViewport(posX, posY) then
    return false
  end
  local curTraceData = self.data:GetCurTraceNpcData()
  if curTraceData and npcInfo.entry_id == curTraceData.entry_id then
    return true
  end
  local worldMapCfg = self.WorldMapConfigs[npcInfo.world_map_cfg_id]
  if not worldMapCfg then
    return false
  end
  local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(worldMapCfg.element_show_scale)
  if not scaleConf then
    return false
  end
  local currentScale = self.uiData.mapSliderScale
  local minScaleThreshold = scaleConf.min_scale / 100.0
  local maxScaleThreshold = scaleConf.max_scale / 100.0
  return currentScale >= minScaleThreshold and currentScale <= maxScaleThreshold
end

function UMG_MainMap_C:CheckOutOfRange()
  local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.layerParent:GetCachedGeometry())
  local centerXMin = 2048 * self.leftRangePercent + wndSize.X / 2 / self.imageScale.X
  local centerXMax = 6144.0 - 2048 * self.rightRangePercent * 1.5 - wndSize.X / 2 / self.imageScale.X
  local centerYMin = 2048 * self.topRangePercent + wndSize.Y / 2 / self.imageScale.Y
  local centerYMax = 6144.0 - 2048 * self.bottomRangePercent * 1.5 - wndSize.Y / 2 / self.imageScale.Y
  if centerXMin < self.uiData.mapCenterX and centerXMax > self.uiData.mapCenterX and centerYMin < self.uiData.mapCenterY and centerYMax > self.uiData.mapCenterY then
    return false
  else
    return true
  end
end

function UMG_MainMap_C:Tick(MyGeometry, InDeltaTime)
  if self.TouchStartTime then
    self.TouchStartTime = self.TouchStartTime + InDeltaTime
  end
  self:OnFogTick(InDeltaTime)
  if self.checkMapCenterPosition then
    local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.layerParent:GetCachedGeometry())
    if wndSize.X > 0 and wndSize.Y > 0 then
      local uiData = self.uiData
      self:SetMapCenterPosition(uiData.mapCenterX, uiData.mapCenterY)
      self.checkMapCenterPosition = false
    end
  end
  if self.IsClickBigManualBtn and self.uiData.mapCenterX and self.uiData.mapCenterY and self.EndPos.X and self.EndPos.Y then
    self.MoveTime = self.MoveTime + InDeltaTime
    local CurrentPosition = {
      X = self.uiData.mapCenterX,
      Y = self.uiData.mapCenterY
    }
    local EndPosition = {
      X = self.EndPos.X,
      Y = self.EndPos.Y
    }
    local pos = FVector2DUtils.Lerp(CurrentPosition, EndPosition, self.MoveTime)
    if math.abs(pos.X - EndPosition.X) < 0.01 and math.abs(pos.Y - EndPosition.Y) < 0.01 then
      self.IsClickBigManualBtn = false
      self.MoveTime = 0
      pos.X = EndPosition.X
      pos.Y = EndPosition.Y
      self.IsCanMove = true
    end
    self:SetMapCenterPosition(pos.X, pos.Y)
    self.isTouchScale = false
  end
  if self.LerpToNewMapCenterPos and self.uiData.mapCenterX and self.uiData.mapCenterY and self.EndPos.X and self.EndPos.Y then
    self.DeltaTimer = self.DeltaTimer + InDeltaTime
    local ratio = self.DeltaTimer / self.FinishTime
    local CurrentPosition = {
      X = self.uiData.mapCenterX,
      Y = self.uiData.mapCenterY
    }
    local EndPosition = {
      X = self.EndPos.X,
      Y = self.EndPos.Y
    }
    local pos = FVector2DUtils.Lerp(CurrentPosition, EndPosition, ratio)
    if math.abs(pos.X - EndPosition.X) < 0.01 and math.abs(pos.Y - EndPosition.Y) < 0.01 then
      pos.X = EndPosition.X
      pos.Y = EndPosition.Y
      self.LerpToNewMapCenterPos = false
      self.DeltaTimer = 0
    end
    self:SetMapCenterPosition(pos.X, pos.Y, nil, self.endPosLayerId)
  end
end

function UMG_MainMap_C:SetMarkerEvent(scenePos, imageRadius)
  local posX, posY = self:ScenePositionToImagePosition(scenePos[1].pos.x, scenePos[1].pos.y)
  self:NewMarkerEvent({X = posX, Y = posY}, imageRadius)
end

function UMG_MainMap_C:OnSetSliderVisible(_IsEnabled)
  self.mapScaleSlider:SetIsEnabled(_IsEnabled)
end

function UMG_MainMap_C:MarkerEvent(_imageCenterPos, _imageRadius)
  if self.isTravel then
    return
  end
  self:OnBtnClose1Click()
  self.IsFirstOnclick = true
  local sceneCenterX, sceneCenterY = self:ImagePositionToScenePosition(_imageCenterPos.X, _imageCenterPos.Y)
  local sceneRadius = math.ceil(_imageRadius / self.uiData.imageToSceneScale / self.uiData.mapImageScale)
  local radius2 = sceneRadius * sceneRadius
  local CustomPointInfo = self.data:GetCustomPointInfo()
  local IsOnClickCustomMarker = false
  local IsHasMarker = false
  local MarkerPanelInfo = {}
  MarkerPanelInfo.DotList = {}
  MarkerPanelInfo.IsOnClickCustomMarker = IsOnClickCustomMarker
  MarkerPanelInfo.SelectScenePos = {x = sceneCenterX, y = sceneCenterY}
  MarkerPanelInfo.SelectImagePos = self.ScreenPos
  Log.Debug("[Map] [Marker] UMG_MainMap_C MarkerEvent0 SelectImagePos", MarkerPanelInfo, MarkerPanelInfo.SelectImagePos)
  local MarkerMaxCount = _G.DataConfigManager:GetMapGlobalConfig("worldmap_fix_point_num").num
  for i = 1, MarkerMaxCount do
    for j, Point in ipairs(CustomPointInfo) do
      local x = Point.pos.x - sceneCenterX
      local y = Point.pos.y - sceneCenterY
      if radius2 >= x * x + y * y then
        IsOnClickCustomMarker = true
        MarkerPanelInfo.CustomMarkerIndex = Point.mark_number
        MarkerPanelInfo.SelectPos = Point.pos
        MarkerPanelInfo.IsOnClickCustomMarker = IsOnClickCustomMarker
        self.dot_2HasMark = true
        local posX, posY = self:ScenePositionToImagePosition(Point.pos.x, Point.pos.y)
        local mousePos = self:GetTempVector2D(posX, posY)
        self.mouseIcon:setShowPosition(mousePos)
        MarkerPanelInfo.SelectImagePos = mousePos
        self.IsFirstOnclick = false
        Log.Debug("[Map] [Marker] UMG_MainMap_C MarkerEvent1 SelectImagePos", MarkerPanelInfo, MarkerPanelInfo.SelectImagePos)
      end
      if CustomPointInfo[j].mark_number == i then
        IsHasMarker = true
        table.insert(MarkerPanelInfo.DotList, {
          IsMarker = true,
          pos = Point.pos,
          Index = Point.mark_number,
          SelectScenePos = MarkerPanelInfo.SelectScenePos
        })
      end
    end
    if false == IsHasMarker then
      table.insert(MarkerPanelInfo.DotList, {
        IsMarker = false,
        Index = i,
        SelectScenePos = MarkerPanelInfo.SelectScenePos
      })
    end
    MarkerPanelInfo.DotList[i].IsOnClickCustomMarker = MarkerPanelInfo.IsOnClickCustomMarker
    MarkerPanelInfo.DotList[i].SelectImagePos = MarkerPanelInfo.SelectImagePos
    IsHasMarker = false
    Log.Debug("[Map] [Marker] UMG_MainMap_C MarkerEvent2 SelectImagePos", MarkerPanelInfo, MarkerPanelInfo.SelectImagePos)
  end
  if IsOnClickCustomMarker then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401006, "UMG_MainMap_C:MarkerEvent")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400002, "UMG_MainMap_C:MarkerEvent")
  end
  _G.NRCModeManager:DoCmd(BigMapModuleCmd.OpenMapRightPanel, 2, MarkerPanelInfo)
  self.IsFirstOnclick = false
end

function UMG_MainMap_C:NewMarkerEvent(_imageCenterPos, _imageRadius, mark_id)
  if self.isTravel then
    return
  end
  local mapShowLevel = self.uiData.mapSliderScale
  local sceneCenterX, sceneCenterY = self:ImagePositionToScenePosition(_imageCenterPos.X, _imageCenterPos.Y)
  local sceneRadius = math.ceil(_imageRadius / self.uiData.imageToSceneScale / self.uiData.mapImageScale)
  local radius2 = sceneRadius * sceneRadius
  local CustomPointInfo = self.data:GetNewCustomPointInfo()
  local MarkerPanelInfo = {}
  MarkerPanelInfo.IsOnClickCustomMarker = false
  MarkerPanelInfo.SelectScenePos = {
    x = sceneCenterX,
    y = sceneCenterY,
    z = 0
  }
  MarkerPanelInfo.SelectImagePos = self.ScreenPos
  Log.Debug("[Map] [Marker] UMG_MainMap_C NewMarkerEvent SelectImagePos", MarkerPanelInfo, MarkerPanelInfo.SelectImagePos)
  for j, Point in ipairs(CustomPointInfo) do
    local isShow = false
    if Point.is_track then
      isShow = true
    else
      local element_show_scale = _G.DataConfigManager:GetMapGlobalConfig("oneself_mark_scale").num
      local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(element_show_scale)
      if mapShowLevel <= scaleConf.max_scale / 100.0 and mapShowLevel >= scaleConf.min_scale / 100.0 then
        isShow = true
      else
        isShow = true
      end
    end
    if mark_id then
      if mark_id == Point.mark_id and isShow then
        self:SetMarkerPanelInfo(MarkerPanelInfo, Point)
        break
      end
    else
      local x = Point.pos.x - sceneCenterX
      local y = Point.pos.y - sceneCenterY
      if radius2 >= x * x + y * y and isShow then
        self:SetMarkerPanelInfo(MarkerPanelInfo, Point)
        break
      end
    end
  end
  if MarkerPanelInfo.IsOnClickCustomMarker then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401006, "UMG_MainMap_C:MarkerEvent")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400002, "UMG_MainMap_C:MarkerEvent")
  end
  self.MarkerPanelInfo = MarkerPanelInfo
  if not MarkerPanelInfo.IsOnClickCustomMarker and self:MarkerIsFull() then
    local Text = _G.DataConfigManager:GetMapGlobalConfig("Map_Mark_Is_Full_Tips").str
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    self.mouseIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if self.MarkerPanelInfo.MarkerData then
    local showLayerId = self:GetLayerIdByIconTypeAndKey(bigMapModuleEnum.CreatorPriority.MarkerIcons, self.MarkerPanelInfo.MarkerData)
    self:SetLayerMapListByClickIcon(showLayerId)
  end
  _G.NRCModeManager:DoCmd(BigMapModuleCmd.OpenMapRightPanel, 3, MarkerPanelInfo)
end

function UMG_MainMap_C:SetMarkerPanelInfo(MarkerPanelInfo, Point)
  MarkerPanelInfo.IsOnClickCustomMarker = true
  MarkerPanelInfo.MarkerData = Point
  local posX, posY = self:ScenePositionToImagePosition(Point.pos.x, Point.pos.y)
  local mousePos = self:GetTempVector2D(posX, posY)
  self.mouseIcon:setShowPosition(mousePos)
  MarkerPanelInfo.SelectImagePos = mousePos
  MarkerPanelInfo.SelectScenePos = {
    x = Point.pos.x,
    y = Point.pos.y,
    z = 0
  }
  Log.Debug("[Map] [Marker] UMG_MainMap_C SetMarkerPanelInfo SelectImagePos", MarkerPanelInfo, MarkerPanelInfo.SelectImagePos)
  return MarkerPanelInfo
end

function UMG_MainMap_C:IsHasCustomMarker(_imageCenterPos, _imageRadius)
  local sceneCenterX, sceneCenterY = self:ImagePositionToScenePosition(_imageCenterPos.X, _imageCenterPos.Y)
  local sceneRadius = math.ceil(_imageRadius / self.uiData.imageToSceneScale / self.uiData.mapImageScale)
  local radius2 = sceneRadius * sceneRadius
  local CustomPointInfo = self.data:GetNewCustomPointInfo()
  for j, Point in ipairs(CustomPointInfo) do
    local x = Point.pos.x - sceneCenterX
    local y = Point.pos.y - sceneCenterY
    if radius2 >= x * x + y * y then
      return true
    end
  end
  return false
end

function UMG_MainMap_C:MarkerIsFull()
  local CustomPointInfo = self.data:GetNewCustomPointInfo()
  local NorMalPointMaxNum = _G.DataConfigManager:GetMapGlobalConfig("max_normal_point_num").num
  local PetPointMaxNum = _G.DataConfigManager:GetMapGlobalConfig("max_pet_point_num").num
  local NorMalPointNum = 0
  local PetPointNum = 0
  for j, Point in ipairs(CustomPointInfo) do
    if Point.type == ProtoEnum.WorldMapMarkType.ENUM.NormalMark then
      NorMalPointNum = NorMalPointNum + 1
    elseif Point.type == ProtoEnum.WorldMapMarkType.ENUM.PetMark then
      PetPointNum = PetPointNum + 1
    end
  end
  if NorMalPointNum == NorMalPointMaxNum and PetPointNum == PetPointMaxNum then
    return true
  end
  return false
end

function UMG_MainMap_C:OnFogTick(_deltaTime)
  if self.isPlayFogAni then
    if self:IsAnimationPlaying(self.open) then
      return
    end
    self.curFogScale = self.curFogScale + _deltaTime * self.FogAnimSpeedParam
    if self.curFogScale >= 1.0 then
      self.curFogScale = 1.0
      self.isPlayFogAni = false
      self:OnFogAniPlayEnd()
    end
    self:SetMaterialParam(self.curFogScale)
  end
end

function UMG_MainMap_C:ChangeMapByTaskId()
  if self.isTravel then
    return
  end
  local ShowTaskInfo = self.data:GetShowTaskInfo()
  if ShowTaskInfo and #ShowTaskInfo > 0 then
    local ResIdList = {}
    local ResIdSet = {}
    for i, TaskInfo in ipairs(ShowTaskInfo) do
      if self.SelectTaskId == TaskInfo.TaskConf.id then
        ResIdSet[TaskInfo.TaskSceneResId] = true
      end
    end
    for k, v in ipairs(self.data.MapShowList) do
      if ResIdSet[v.sceneResId] then
        table.insert(ResIdList, v.sceneResId)
        break
      end
    end
    if self.SelectTaskId then
      if #ResIdList > 0 then
        Log.Info("[Map] CreateTaskPanelTaskIcon with select task", self.SelectTaskId, "from", self.lastOpenMapId, "res\239\188\154", table.concat(ResIdList, ","))
        self:ChangeMapScene(ResIdList[#ResIdList])
      else
        Log.Info("[Map] CreateTaskPanelTaskIcon cannot found any res id with task", self.SelectTaskId)
        local ResId = SceneUtils.GetSceneResId()
        self:ChangeMapScene(ResId)
        self.data:SetSceneResId(nil)
      end
    end
  elseif self.SelectTaskId then
    local ResId = SceneUtils.GetSceneResId()
    self:ChangeMapScene(ResId)
    self.data:SetSceneResId(nil)
  end
  self:OpenRightTaskInfo()
end

function UMG_MainMap_C:OpenRightTaskInfo()
  local ChildTaskId, OpenTaskId, TaskConf
  local ParentTaskList = self.data:GetParentTaskList()
  if ParentTaskList then
    for i, Task in ipairs(ParentTaskList) do
      if Task.parent_task_id == self.SelectTaskId then
        if ChildTaskId then
          if ChildTaskId > Task.task_id then
            ChildTaskId = Task.task_id
          end
        else
          ChildTaskId = Task.task_id
        end
      end
    end
  end
  if ChildTaskId then
    OpenTaskId = ChildTaskId
  else
    OpenTaskId = self.SelectTaskId
  end
  local taskIndex = 0
  local ShowTaskInfo = self.data:GetShowTaskInfo()
  for i, TaskInfo in ipairs(ShowTaskInfo) do
    if OpenTaskId and OpenTaskId == TaskInfo.TaskConf.id then
      local showTaskInfo = {}
      local Position = {}
      local taskConf = _G.DataConfigManager:GetTaskConf(TaskInfo.TaskConf.id)
      if TaskInfo.NpcPosition[1] then
        if TaskInfo.NpcPosition[1].map_pos then
          table.insert(Position, {
            pos = TaskInfo.NpcPosition[1].map_pos
          })
        else
          table.insert(Position, {
            pos = TaskInfo.NpcPosition[1].pos
          })
        end
        table.insert(showTaskInfo, {
          NpcPosition = Position,
          TaskConf = taskConf,
          TaskShowType = bigMapModuleEnum.TaskShowType.ACCEPTED
        })
        if self.playAniNpcRefreshId.IsOpenRightPanel then
          _G.NRCModeManager:DoCmd(BigMapModuleCmd.OpenMapRightPanel, 0, showTaskInfo[1], nil)
        end
        local posX, posY = self:ScenePositionToImagePosition(Position[1].pos.x, Position[1].pos.y)
        self.LerpToNewMapCenterPos = false
        self:SetMapCenterPosition(posX, posY)
        self:SetLayerByTask(TaskInfo)
        self:SetMouseSelectTask()
        break
      end
    end
  end
end

function UMG_MainMap_C:SetMouseSelectTask()
  local ShowTaskInfo = self.data:GetShowTaskInfo()
  for k, v in ipairs(ShowTaskInfo) do
    if v.TaskConf and self.SelectTaskId and self.SelectTaskId == v.TaskConf.id and v.NpcPosition[1] then
      local pos
      if v.NpcPosition[1].map_pos then
        pos = v.NpcPosition[1].map_pos
      else
        pos = v.NpcPosition[1].pos
      end
      local X, Y = self:ScenePositionToImagePosition(pos.x, pos.y)
      local posU = X / self.uiData.originalMapWidth
      local posV = Y / self.uiData.originalMapHeight
      local RValue = UE4.UNRCTUIStatics.GetTexture2DPixelColorFromUV(self.data.FullMaskRunTime, self:GetTempVector2D(posU, posV))
      if RValue.R > 125 then
        self.mouseIcon.Slot:SetZOrder(12)
      else
        self.mouseIcon.Slot:SetZOrder(12)
      end
      local mousePos = self:GetTempVector2D(X, Y)
      self.mouseIcon:showAni(mousePos)
      break
    end
  end
end

function UMG_MainMap_C:CreateTaskIcon(_posX, _posY, taskConf, taskShowType, SubTaskId, go_index, ShowTask, bIsAddTrace)
  self.iconDataTemplate.curMapImageScale = self.uiData.mapImageScale
  self.iconDataTemplate.curMapSliderScale = self.uiData.mapSliderScale
  self.iconDataTemplate.iconImagePos = {x = _posX, y = _posY}
  self.iconDataTemplate.layerIndex = 6
  self.taskIconCreator:Create(self.iconDataTemplate, {
    taskId = taskConf.id,
    taskShowType = taskShowType,
    SubTaskId = SubTaskId,
    go_index = go_index or 0
  })
  if SubTaskId and SubTaskId > 0 then
    taskConf = _G.DataConfigManager:GetTaskConf(SubTaskId)
  end
  if bIsAddTrace then
    self:AddTraceTask(_posX, _posY, taskConf, go_index, ShowTask)
  end
end

function UMG_MainMap_C:OnUpdateTraceEffect(taskId)
  self.taskIconCreator:UpdateTraceEffect(taskId)
end

function UMG_MainMap_C:OnUpdateShowTaskInfo()
  self.data:CreateShowTaskInfo()
  local ShowTaskInfo = self.data:GetShowTaskInfo()
  self.taskIconCreator:UpdateShowTaskInfo(ShowTaskInfo)
end

function UMG_MainMap_C:OnChangeSelectedScene(sceneId)
  self:ChangeMapBySceneId(sceneId)
  self.data:UpdateTaskPos()
  self:OnShowTaskIcon(sceneId)
  self:UpdateHint()
  self:ShowSanctuary(true)
  self:UpdateHomeBtn()
end

function UMG_MainMap_C:OnFruitNpcsInfoListSetFinish(fruitNpcsInfo)
  local areaId = self.curCenterAreaId
  local campRefreshId = self.data.AreaIdToRefreshId[areaId]
  if campRefreshId and campRefreshId > 0 then
    local campConf = _G.DataConfigManager:GetCampConf(campRefreshId)
    if campConf then
      self.Text:SetText(campConf.camp_name)
      local x, y = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetPetGatherRate, campRefreshId)
      local text = string.format(_G.DataConfigManager:GetLocalizationConf("worldmap_area_exploration").msg, x, y)
      self.Text_1:SetText(text)
      self.Text_2:SetText(text)
    end
  end
end

function UMG_MainMap_C:CreateNpcIcon(_npcId, _posX, _posY, _npcInfo)
  if self.npcIconCreator:Get(_npcInfo.entry_id, _npcInfo.logic_id) then
  else
    local iconData = {}
    local iconCircleData = {}
    iconCircleData.iconImagePos = {x = _posX, y = _posY}
    iconCircleData.curMapImageScale = self.uiData.mapImageScale
    iconCircleData.curMapSliderScale = self.uiData.mapSliderScale
    iconCircleData.curShowLayerId = self.lastShowLayerId
    iconData.iconImagePos = {x = _posX, y = _posY}
    iconData.curMapImageScale = self.uiData.mapImageScale
    iconData.curMapSliderScale = self.uiData.mapSliderScale
    iconData.curShowLayerId = self.lastShowLayerId
    if self:CheckIsTracing(bigMapModuleEnum.TraceType.NPC, _npcInfo) or self:CheckIsTracing(bigMapModuleEnum.TraceType.TempTrace, _npcInfo) or self:CheckIsTracing(bigMapModuleEnum.TraceType.ForceTrace, _npcInfo) then
      iconData.bTracing = true
      iconCircleData.bTracing = true
    end
    self.mapItemCreator:Create(self.npcIconCreator, bigMapModuleEnum.CreatorPriority.NpcIcons, nil, {iconData = iconData, npcInfo = _npcInfo})
    if _npcInfo.worldMapActivityConf then
      iconCircleData.iconTemplateIndex = 1
      if iconCircleData.layerIndex and iconCircleData.layerIndex > 0 then
      else
        iconCircleData.layerIndex = BigMapUtils.GetNpcIconLayer(_npcInfo)
      end
      iconCircleData.curMapImageScale = self.uiData.imageToSceneScale * 100
      iconCircleData.layerIndex = 1
      local circleInfo = {}
      circleInfo.showType = bigMapModuleEnum.CircleIconType.Activity
      circleInfo.typeId = _npcInfo.worldMapActivityConf.id
      circleInfo.circleRadius = _npcInfo.worldMapActivityConf.radius
      circleInfo.showScale = _npcInfo.worldMapConf.element_show_scale
      self.iconCircleCreator:Create(iconCircleData, circleInfo)
    end
  end
end

function UMG_MainMap_C:CreateMapAreaIcon(_key, _posX, _posY, _Info)
  Log.Dump(_Info, 5, "UMG_MainMap_C:CreateMapAreaIcon")
  self.iconDataTemplate.curMapImageScale = self.uiData.mapImageScale
  self.iconDataTemplate.curMapSliderScale = self.uiData.mapSliderScale
  self.iconDataTemplate.iconImagePos = {x = _posX, y = _posY}
  self.npcIconCreator:Create({
    iconData = self.iconDataTemplate,
    npcInfo = _Info
  })
end

function UMG_MainMap_C:CreateTraceIcon()
  if self.data.traceInfoList and #self.data.traceInfoList > 0 then
    for traceType, traceInfo in pairs(self.data.traceInfoList) do
      if traceType ~= bigMapModuleEnum.TraceType.Task then
        if traceType ~= bigMapModuleEnum.TraceType.Visitor and traceType ~= bigMapModuleEnum.TraceType.TempTrace and traceType ~= bigMapModuleEnum.TraceType.ForceTrace then
          self.traceIconCreator:Create({traceInfo = traceInfo})
        elseif traceInfo then
          if traceType == bigMapModuleEnum.TraceType.TempTrace then
            for k, v in pairs(traceInfo) do
              local npcInfo = v.npcInfo
              if npcInfo and npcInfo.worldMapConf and 1 == npcInfo.worldMapConf.explored_in_map then
                self.mapItemCreator:Create(self.traceIconCreator, bigMapModuleEnum.CreatorPriority.TraceIcons, nil, {traceInfo = v})
              end
            end
          elseif traceType == bigMapModuleEnum.TraceType.ForceTrace then
            for trackType, traceList in pairs(traceInfo) do
              if traceList and #traceList > 0 then
                for key, v in ipairs(traceList) do
                  local npcInfo = v.npcInfo
                  if npcInfo and npcInfo.worldMapConf and 1 == npcInfo.worldMapConf.explored_in_map then
                    self.mapItemCreator:Create(self.traceIconCreator, bigMapModuleEnum.CreatorPriority.TraceIcons, nil, {traceInfo = v})
                  end
                end
              end
            end
          else
            for k, v in pairs(traceInfo) do
              self.mapItemCreator:Create(self.traceIconCreator, bigMapModuleEnum.CreatorPriority.TraceIcons, nil, {traceInfo = v})
            end
          end
        end
      end
    end
  end
end

function UMG_MainMap_C:OnShowTaskIconInfo()
  self:ChangeMapByTaskId()
  self:OnShowTaskIcon(self.data.curShowSceneResId)
end

function UMG_MainMap_C:OnShowTaskIcon(sceneResId)
  if self.isTravel then
    return
  end
  local CurSceneResId = self:GetCurSceneResId()
  sceneResId = sceneResId or self:GetCurSceneResId()
  local showTaskList = self.data:GetShowTaskInfo()
  local TrackList = {}
  local CurTrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetDataTrackTask)
  local TaskMap = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskMap)
  if CurTrackTask and CurTrackTask.Trackers then
    for _, TrackItem in pairs(CurTrackTask.Trackers) do
      TrackList[TrackItem.TaskInfo.id] = TrackItem
    end
  end
  for k, v in ipairs(showTaskList) do
    local IsShow = self.data:SeparatedTaskByGuideList(v.TaskSceneResId, sceneResId, v.TaskShowType)
    if IsShow then
      if v.TaskShowType == bigMapModuleEnum.TaskShowType.TRACING then
        local taskPosX, taskPosY = self:ScenePositionToImagePosition(v.NpcPosition[1].pos.x, v.NpcPosition[1].pos.y)
        if TrackList[v.TaskConf.id] and sceneResId == CurSceneResId then
          local TaskObject = TaskMap[v.TaskConf.id]
          local AllTrackers = TaskObject.Trackers
          if AllTrackers and #AllTrackers > 0 then
            for _, TrackItem in pairs(AllTrackers) do
              if TrackItem.go_index == v.go_index and not TrackItem:IsCheckConditionDone(TrackItem.go_index) then
                local Pos = TrackItem:GetPosition()
                if Pos then
                  taskPosX, taskPosY = self:ScenePositionToImagePosition(Pos.X, Pos.Y)
                  break
                end
              end
            end
          end
        end
        self:CreateTaskIcon(taskPosX, taskPosY, v.TaskConf, v.TaskShowType, v.SubTaskId, v.go_index, v, true)
        if CurTrackTask and CurTrackTask.Trackers then
          for _, TrackItem in pairs(CurTrackTask.Trackers) do
            for Index, Value in ipairs(TrackItem.TaskConfig.go_guide) do
              if Value.type == _G.Enum.TaskGoActionType.TGAT_NPC_CIRCLE then
                local Finish = TrackItem:IsCheckConditionDone(Index)
                if not Finish then
                  local IconCircle = self.iconCircleCreator:Get(bigMapModuleEnum.CircleIconType.Task, TrackItem.TaskConfig.id, Index)
                  if not IconCircle then
                    local IconData = {}
                    IconData.iconImagePos = {x = taskPosX, y = taskPosY}
                    IconData.curMapImageScale = 1 / self.iconScale * self.uiData.imageToSceneScale * 100
                    IconData.curMapSliderScale = 1
                    IconData.iconTemplateIndex = 1
                    IconData.layerIndex = 6
                    local CircleInfo = {}
                    CircleInfo.showType = bigMapModuleEnum.CircleIconType.Task
                    CircleInfo.typeId = TrackItem.TaskConfig.id
                    CircleInfo.circleRadius = Value.data2[1]
                    CircleInfo.showScale = _G.Enum.MapElementScale.ESCALE_ALL
                    CircleInfo.extraId = Index
                    self.iconCircleCreator:Create(IconData, CircleInfo)
                  end
                end
              end
            end
          end
        end
      elseif v.TaskShowType == bigMapModuleEnum.TaskShowType.ACCEPTED then
        local taskPosX, taskPosY = self:ScenePositionToImagePosition(v.NpcPosition[1].pos.x, v.NpcPosition[1].pos.y)
        self:CreateTaskIcon(taskPosX, taskPosY, v.TaskConf, v.TaskShowType, v.SubTaskId, v.go_index, v, true)
      end
    else
      self.TaskCircle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:UpdateTraceIconPositionAndVisible()
end

function UMG_MainMap_C:AddTraceTask(taskPosX, taskPosY, _taskConf, goIndex, ShowTask)
  if self.bIsOpenByManual then
    local showTaskConf = _taskConf
    local TaskMapTrack = NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
    if TaskMapTrack and TaskMapTrack.Config.id == showTaskConf.id then
      local traceInfo = {}
      traceInfo.traceType = bigMapModuleEnum.TraceType.Task
      traceInfo.taskInfo = {}
      traceInfo.taskInfo.taskId = TaskMapTrack.Config.id
      traceInfo.taskInfo.go_index = goIndex or 1
      traceInfo.iconImagePos = {x = taskPosX, y = taskPosY}
      traceInfo.sceneResId = ShowTask and ShowTask.TaskSceneResId
      self.data:SetTraceInfoList(traceInfo)
      self.mapItemCreator:Create(self.traceIconCreator, bigMapModuleEnum.CreatorPriority.TraceIcons, nil, {traceInfo = traceInfo})
    end
  else
    local showTaskConf = _taskConf
    local traceInfo = {}
    traceInfo.traceType = bigMapModuleEnum.TraceType.Task
    traceInfo.taskInfo = {}
    traceInfo.taskInfo.taskId = showTaskConf.id
    traceInfo.taskInfo.go_index = goIndex or 1
    traceInfo.iconImagePos = {x = taskPosX, y = taskPosY}
    traceInfo.sceneResId = ShowTask and ShowTask.TaskSceneResId
    self.data:SetTraceInfoList(traceInfo)
    self.mapItemCreator:Create(self.traceIconCreator, bigMapModuleEnum.CreatorPriority.TraceIcons, nil, {traceInfo = traceInfo})
  end
end

function UMG_MainMap_C:AddTraceNpc(posX, posY, npcInfo)
  local traceInfo = {}
  traceInfo.traceType = bigMapModuleEnum.TraceType.NPC
  traceInfo.npcInfo = npcInfo
  traceInfo.iconImagePos = {x = posX, y = posY}
  self.mapItemCreator:Create(self.traceIconCreator, bigMapModuleEnum.CreatorPriority.TraceIcons, nil, {traceInfo = traceInfo})
end

function UMG_MainMap_C:OnMapMarkOperateChange(markerInfo, opType)
  self:OnShowMarker(markerInfo, opType, self.data.curShowSceneResId)
  if not self.isTravel then
    self.markerIconCreator:UpdateMapShowLevel(self.uiData.mapSliderScale)
  end
  _G.NRCModeManager:DoCmd(BigMapModuleCmd.CloseMapRightPanel)
end

function UMG_MainMap_C:OnChangeMarkerIcon(_SelectMarker)
  local markIcon = self.markerIconCreator:Get(self.MarkerPanelInfo.MarkerData.mark_id)
  if markIcon and UE4.UObject.IsValid(markIcon) and markIcon.SelectMarkerInfo then
    markIcon:SetPath(_SelectMarker.id)
  end
end

function UMG_MainMap_C:OnShowMarker(markerInfo, opType, showSceneResId)
  if self.isTravel then
    return
  end
  if nil == markerInfo then
    local CustomPointInfo = self.data:GetNewCustomPointInfo()
    for k, point in ipairs(CustomPointInfo) do
      if point.pos and point.pos.x and point.pos.y then
        local markerSceneResId = BigMapUtils.GetSceneResIdByPos(point.pos.x, point.pos.y)
        if markerSceneResId == showSceneResId then
          point.index = k
          local iconData = {}
          iconData.curMapImageScale = self.uiData.mapImageScale
          iconData.curMapSliderScale = self.uiData.mapSliderScale
          iconData.iconTemplateIndex = 1
          iconData.layerIndex = 3
          if self:CheckIsTracing(bigMapModuleEnum.TraceType.Marker, point) then
            iconData.bTracing = true
          end
          if self.markerIconCreator:Get(point.mark_id) then
            self.markerIconCreator:Refresh({iconData = iconData, markerInfo = point})
          else
            self.mapItemCreator:Create(self.markerIconCreator, bigMapModuleEnum.CreatorPriority.MarkerIcons, nil, {iconData = iconData, markerInfo = point})
          end
        end
      end
    end
  elseif opType then
    local iconData = {}
    iconData.curMapImageScale = self.uiData.mapImageScale
    iconData.curMapSliderScale = self.uiData.mapSliderScale
    iconData.iconTemplateIndex = 1
    iconData.layerIndex = 3
    if self:CheckIsTracing(bigMapModuleEnum.TraceType.Marker, markerInfo) then
      iconData.bTracing = true
    end
    if opType <= ProtoEnum.MapMarkOpType.MMOT_MODIFY_MARK then
      if opType == ProtoEnum.MapMarkOpType.MMOT_REMOVE_MARK then
        self.markerIconCreator:Destroy(markerInfo.mark_id)
      elseif self.markerIconCreator:Get(markerInfo.mark_id) then
        self.markerIconCreator:Refresh({iconData = iconData, markerInfo = markerInfo})
      else
        local markerSceneResId = BigMapUtils.GetSceneResIdByPos(markerInfo.pos.x, markerInfo.pos.y)
        if markerSceneResId == showSceneResId then
          self.mapItemCreator:Create(self.markerIconCreator, bigMapModuleEnum.CreatorPriority.MarkerIcons, nil, {iconData = iconData, markerInfo = markerInfo})
        end
      end
    else
      local traceInfo = {}
      traceInfo.traceType = bigMapModuleEnum.TraceType.Marker
      traceInfo.iconImagePos = {
        x = markerInfo.pos.x,
        y = markerInfo.pos.y
      }
      traceInfo.markInfo = markerInfo
      self.markerIconCreator:Refresh({iconData = iconData, markerInfo = markerInfo})
    end
  end
end

function UMG_MainMap_C:AddOrRemoveTempIconInfo(isAdd, npcInfo, entryId, logicId)
  if isAdd then
    entryId = entryId or npcInfo.entry_id
    logicId = logicId or npcInfo.logic_id or entryId
    self.tempIconInfoList[entryId] = self.tempIconInfoList[entryId] or {}
    self.tempIconInfoList[entryId][logicId] = npcInfo
    return
  end
  local entryList = self.tempIconInfoList[entryId]
  if not entryList or not entryList[logicId] then
    return
  end
  entryList[logicId] = nil
  if not table.isEmpty(entryList) then
    self.tempIconInfoList[entryId] = nil
  end
end

function UMG_MainMap_C:CreateTempIcon(npcInfo, bTracing)
  if npcInfo and npcInfo.npc_pos and self.module:CheckShowTempIcon(npcInfo) then
    self:AddOrRemoveTempIconInfo(true, npcInfo)
    if self.npcIconCreator then
      local _entryId = npcInfo.entry_id
      local _logicId = npcInfo.logic_id
      local npcIcon = self.npcIconCreator:Get(_entryId, _logicId)
      if npcInfo and UE4.UObject.IsValid(npcIcon) then
        self.npcIconCreator:SetIconTempFlag(_entryId, _logicId, true)
        self.npcIconCreator:SetIconLayer(_entryId, _logicId, 3)
        self.npcIconCreator:SetTraceEffect(bTracing, _entryId, _logicId)
      else
        local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
        local iconData = {}
        iconData.layerIndex = 3
        iconData.iconImagePos = {x = posX, y = posY}
        iconData.curMapSliderScale = self.uiData.mapSliderScale
        iconData.curMapImageScale = self.uiData.mapImageScale
        iconData.bTracing = bTracing
        iconData.bTemp = true
        self.npcIconCreator:Create({iconData = iconData, npcInfo = npcInfo})
      end
    end
    self.mouseIcon.Slot:SetZOrder(12)
  end
end

function UMG_MainMap_C:ShowTempTraceIcons()
  local npcInfo = self.data:GetCurTraceNpcData()
  if npcInfo and npcInfo.npc_pos then
    local worldMapCfg = self.WorldMapConfigs[npcInfo.world_map_cfg_id]
    if (npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS or npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_FLOWER_SEED or npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT or worldMapCfg and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP) and not self.module:CheckNpcInFogArea(npcInfo.npc_pos) then
      self:CreateTempIcon(npcInfo, true)
      self:UpdateTraceIconPositionAndVisible()
    elseif self.module:CheckShowTempIcon(npcInfo) then
      self:CreateTempIcon(npcInfo, true)
      self:UpdateTraceIconPositionAndVisible()
    end
  end
end

function UMG_MainMap_C:CreateVisitorIcon(visitorInfos)
  local iconData = {}
  iconData.layerIndex = 2
  iconData.curMapImageScale = self.uiData.mapImageScale
  iconData.curMapSliderScale = self.uiData.mapSliderScale
  iconData.iconTemplateIndex = 1
  self.visitorIconCreator:Create({iconData = iconData, visitorInfo = visitorInfos})
  self:UpdateTraceIconPositionAndVisible()
end

function UMG_MainMap_C:ShowVisitPlayer()
  local VisitPointInfo = self.data:GetVisitPointInfo()
  self:CreateVisitorIcon(VisitPointInfo)
end

function UMG_MainMap_C:UpdateVisitPoint(VisitPlayerInfo)
  self:CreateVisitorIcon(VisitPlayerInfo)
end

function UMG_MainMap_C:UpdateSelectMarker(_SelectMarker)
  if self.MarkerPanelInfo.IsOnClickCustomMarker then
    self:OnChangeMarkerIcon(_SelectMarker)
  else
    if self.MarkerPanelInfo then
      self.MarkerPanelInfo.SelectImagePos = self.dot_2Pos
      Log.Debug("[Map] [Marker] UMG_MainMap_C UpdateSelectMarker SelectImagePos", self.MarkerPanelInfo, self.MarkerPanelInfo.SelectImagePos)
    end
    local PointInfo = {}
    local posLayerId = BigMapUtils.GetLayerIdByPos(self.dot_2Pos.x, self.dot_2Pos.y, self.data.curShowSceneResId, true)
    PointInfo.layer_id = self.module:CheckMarkerMapLayerId(self.data.curShowLayerId, posLayerId)
    self.Customdot_2:SetSelectMarkerInfo(PointInfo)
    self.Customdot_2:SetMapLayerIconVisible(bigMapModuleEnum.CreatorPriority.MarkerIcons)
    self.Customdot_2:showAni(self.MarkerPanelInfo, _SelectMarker, self.IsFirstOnclick)
    if self.dot_2Pos then
      if self.dot_2HasMapMask then
        self.Customdot_2.Slot:SetPosition(self.dot_2Pos)
      end
      if self.dot_2HasMark then
        self.Customdot_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_MainMap_C:InternalRefreshIconRelativeArea(IconWidget)
  if UE.UObject.IsValid(IconWidget) then
    local WorldMapConfig = IconWidget.WorldMapConfig
    local EntranceCave = IconWidget.EntranceCave
    if EntranceCave then
      EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if not IconWidget.SetDottedEdgeEnabled then
      Log.Info("[BigMap] cannot apply dotted edge with", IconWidget:GetFullName())
      return
    end
    if WorldMapConfig then
      local bEnableMapVirtualIconShow = ENABLE_DEBUG_MAP_VIRTUAL_ICON or 1 == DataConfigManager:GetMapGlobalConfig("map_show_inter").num
      if WorldMapConfig.area_func_id_inter and 0 ~= WorldMapConfig.area_func_id_inter then
        if EntranceCave then
          EntranceCave:SetVisibility(UE4.ESlateVisibility.Visible)
        end
        if bEnableMapVirtualIconShow then
          local ZoneInfo = _G.NRCModuleManager:DoCmd(AreaAndZoneModuleCmd.GetPlayerZoneInfo)
          local bInThisInterArea = ZoneInfo.id == WorldMapConfig.area_func_id_inter
          if bInThisInterArea then
            IconWidget:SetDottedEdgeEnabled(false)
          else
            IconWidget:SetDottedEdgeEnabled(true)
          end
        end
      elseif bEnableMapVirtualIconShow then
        local bInOtherInterArea = _G.NRCModuleManager:DoCmd(AreaAndZoneModuleCmd.IfPlayerInInterArea)
        if bInOtherInterArea then
          IconWidget:SetDottedEdgeEnabled(true)
        else
          IconWidget:SetDottedEdgeEnabled(false)
        end
      end
    end
  end
end

function UMG_MainMap_C:GetScaleParam()
  local scale = 1.0 / self.uiData.mapImageScale
  local scaleParam = self:GetTempVector2D(scale, scale)
  return scaleParam
end

function UMG_MainMap_C:UpdateIconScale(_scale, _force, _scaleRatio)
  local scale = 1.0 / self.uiData.mapImageScale
  local scaleParam = self:GetTempVector2D(scale, scale)
  self.heroIcon:SetRenderScale(scaleParam)
  self.taskIconCreator:UpdateIconScale(scaleParam)
  self.npcIconCreator:UpdateIconScale(scaleParam)
  self.markerIconCreator:UpdateIconScale(scaleParam)
  self.visitorIconCreator:UpdateIconScale(scaleParam)
  self.iconCircleCreator:UpdateIconScale(scaleParam)
  self.mouseIcon:SetRenderScale(scaleParam * self.mouseScaleParam)
  self.Customdot_2:SetRenderScale(scaleParam)
  if self.UpdateAreaNameDelay then
    self:CancelDelayByID(self.UpdateAreaNameDelay)
    self.UpdateAreaNameDelay = nil
  end
  self.UpdateAreaNameDelay = self:DelayFrames(2, self.UpdateAreaNameScale, self, scaleParam, _scale, _scaleRatio)
end

function UMG_MainMap_C:UpdateAreaNameScale(scaleParam, _scale, _scaleRatio)
  self.areaNameCreator:UpdateIconScale(scaleParam)
  self.areaNameCreator:UpdateMapShowLevel(self.uiData.mapSliderScale, _scale, _scaleRatio)
  self:UpdateTraceIconPositionAndVisible()
end

function UMG_MainMap_C:UpdateHeroInfo()
  local uiData = self.uiData
  if uiData.heroPosX then
    local scale = 1.0 / self.uiData.mapImageScale
    local scaleParam = self:GetTempVector2D(scale, scale)
    self.heroIcon:SetRenderScale(scaleParam)
    self.heroIcon.Slot:SetPosition(self:GetTempVector2D(uiData.heroPosX, uiData.heroPosY))
    local dirMat = self.heroIcon.HeroIcon1:GetDynamicMaterial()
    if dirMat then
      dirMat:SetScalarParameterValue("Angle", uiData.heroDir or 0)
    end
    local heroPos, heroDir = self:GetPlayerLocation()
    self.heroIcon.HeroIcon1:SetRenderTransformAngle(heroDir or 0)
    Log.Debug(scaleParam, uiData.heroPosX, uiData.heroPosY, uiData.heroDir, "UMG_MainMap_C:UpdateCameraInfo")
    self:CreateHeroTrace(uiData.heroPosX, uiData.heroPosY, heroDir, self.data.curShowSceneResId)
  end
end

function UMG_MainMap_C:UpdateCameraInfo()
  local uiData = self.uiData
  if uiData.CameraDir then
    self.heroIcon.CameraIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.heroIcon.CameraIcon:SetRenderTransformAngle(uiData.CameraDir or 0)
  end
end

function UMG_MainMap_C:UpdateAreaCollectionRate()
  local uiItem = self.uiItem
  if uiItem.areaInfos then
    for _, areaWidget in pairs(uiItem.areaInfos) do
      areaWidget:UpdateCollectionRate()
    end
  end
end

function UMG_MainMap_C:GetWndShowMapRange()
  local wndSize = self.curWndSize
  if wndSize.X <= 0 or wndSize.Y <= 0 then
    return 1, 1, 1, 1
  end
  local uiData = self.uiData
  if uiData.mapCenterX == nil then
    Log.Error("UMG_MainMap_C:GetWndShowMapRange: uiData.mapCenterX is nil")
  end
  local mapCenterX = uiData.mapCenterX or 2048
  local mapCenterY = uiData.mapCenterY or 2048
  local mapImageScale = uiData.mapImageScale or 1
  local viewSizeHalfX = wndSize.X / mapImageScale / 2
  local viewSizeHalfY = wndSize.Y / mapImageScale / 2
  local posLeftTopX = mapCenterX - viewSizeHalfX
  local posLeftTopY = mapCenterY - viewSizeHalfY
  local posRightBottomX = mapCenterX + viewSizeHalfX
  local posRightBottomY = mapCenterY + viewSizeHalfY
  self.mapRange.leftTopX = posLeftTopX
  self.mapRange.leftTopY = posLeftTopY
  self.mapRange.rightBottomX = posRightBottomX
  self.mapRange.rightBottomY = posRightBottomY
  return posLeftTopX, posLeftTopY, posRightBottomX, posRightBottomY
end

function UMG_MainMap_C:CheckNpcIsInViewportInternal(imgPosX, imgPosY)
  if imgPosX >= self.mapRange.leftTopX and imgPosX <= self.mapRange.rightBottomX and imgPosY >= self.mapRange.leftTopY and imgPosY <= self.mapRange.rightBottomY then
    return true
  end
  return false
end

function UMG_MainMap_C:CheckNpcIsInViewport(imgPosX, imgPosY)
  self:GetWndShowMapRange()
  return self:CheckNpcIsInViewportInternal(imgPosX, imgPosY)
end

function UMG_MainMap_C:UpdateTraceIconPositionAndVisible()
  if self.traceIconCreator then
    self.traceIconCreator:UpdateTracePosAndVisible(self.uiData.mapCenterX, self.uiData.mapCenterY, self.uiData.mapImageScale)
  else
    Log.Error("UMG_MainMap_C, traceIconCreator is nil")
  end
end

function UMG_MainMap_C:UpdateNpcTraceIcon()
  if self.data.traceInfoList then
    local traceNpcInfo = self.data.traceInfoList[bigMapModuleEnum.TraceType.NPC]
    if traceNpcInfo and self.npcIconCreator then
      local iconData = {}
      iconData.bTracing = true
      iconData.iconImagePos = {
        x = traceNpcInfo.iconImagePos.x,
        y = traceNpcInfo.iconImagePos.y
      }
      iconData.curMapSliderScale = self.uiData.mapSliderScale
      iconData.curMapImageScale = self.uiData.mapImageScale
      self.npcIconCreator:Refresh({
        iconData = iconData,
        npcInfo = traceNpcInfo.npcInfo
      })
    end
  end
  return false
end

function UMG_MainMap_C:ShowAreaInfo(_areaInfos, _scale)
  if _areaInfos then
    for areaId, _areaInfo in pairs(_areaInfos) do
      if self.areaNameCreator:Get(_areaInfo.config.name_area_id) then
      else
        local posX, posY = self:ScenePositionToImagePosition(_areaInfo.cfgPosX, _areaInfo.cfgPosY)
        self.iconDataTemplate.iconImagePos = {x = posX, y = posY}
        local iconData = {}
        iconData.iconImagePos = {x = posX, y = posY}
        iconData.curMapSliderScale = self.uiData.mapSliderScale
        iconData.curMapImageScale = self.uiData.mapImageScale
        iconData.layerIndex = 5
        iconData.iconTemplateIndex = 1
        iconData.scale = self:GetMapImageScale(self.uiData.mapSliderScale)
        iconData.scaleRatio = 1
        self.mapItemCreator:Create(self.areaNameCreator, bigMapModuleEnum.CreatorPriority.AreaIcons, nil, {iconData = iconData, areaInfo = _areaInfo})
      end
    end
  end
end

function UMG_MainMap_C:RefreshAreaGatherInfo()
  if self.areaNameCreator then
    self.areaNameCreator:RefreshAllAreaGatherInfo()
  end
end

function UMG_MainMap_C:ShowMapFogInfo(_npcInfos, _aniArea)
  if not _npcInfos then
    return
  end
  if self.WorldMapConfigs == nil then
    self.WorldMapConfigs = {}
  end
  local aniAreaInfo = {}
  local UnlockDeadwoodList = self.data:GetUnlockDeadwoodList()
  for mapCfgId, npcInfo in pairs(_npcInfos) do
    local worldMapCfg = self.WorldMapConfigs[npcInfo.world_map_cfg_id]
    if nil == worldMapCfg then
      return
    end
    local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
    local hasplayAniNpc = false
    for i = 1, #self.playAniNpcRefreshId do
      if self.playAniNpcRefreshId[i].npcRefreshId == npcInfo.npc_refresh_id then
        hasplayAniNpc = true
        break
      end
    end
    if hasplayAniNpc then
      if worldMapCfg.unlock_zone and #worldMapCfg.unlock_zone > 0 then
        for i, unlockInfo in ipairs(worldMapCfg.unlock_zone) do
          local IsExist = false
          for j, UnlockDeadwood in pairs(UnlockDeadwoodList) do
            if unlockInfo == UnlockDeadwood then
              IsExist = true
              break
            end
          end
          if not IsExist then
            self.data:AddUnlockDeadwoodList(unlockInfo)
            table.insert(aniAreaInfo, unlockInfo)
          end
        end
      end
      self:SetMapCenterPosition(posX, posY)
    end
  end
  if aniAreaInfo and #aniAreaInfo > 0 then
    for i, areainfo in ipairs(aniAreaInfo) do
      local Conf = _G.DataConfigManager:GetAreaConf(tonumber(areainfo))
      local confTable = {}
      table.insert(confTable, Conf)
      self.data:DrawWorldMapTexture(false, confTable)
      self:BeginPlayFogAni(0)
    end
  end
  if self.playAniNpcRefreshId and #self.playAniNpcRefreshId > 0 then
    self.playAniNpcRefreshId = {}
  end
end

function UMG_MainMap_C:GetMaskDynamicMaterial()
  for i = 1, #self.mapMaskList do
    self.maskDynamicMaterialList[i] = self.mapMaskList[i]:GetDynamicMaterial()
  end
end

function UMG_MainMap_C:SetMaterialParam(param)
  for k, v in ipairs(self.maskDynamicMaterialList) do
    v:SetScalarParameterValue("Exp", param)
  end
end

function UMG_MainMap_C:SetMaskBySceneResId(sceneResId, newPieceList, oldPieceList)
  local blockConf = self.data.sceneResIdToBlockConf[sceneResId]
  if blockConf then
    if blockConf.not_foggy and blockConf.not_foggy > 0 then
      self.MapMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    else
      self.MapMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  
  local function OnMaskResLoaded(caller, resRequest, asset)
    local assetPath = resRequest.assetPath
    local splitList = string.Split(assetPath, "_")
    local index = tonumber(splitList[#splitList])
    self.maskDynamicMaterialList[index]:SetTextureParameterValue("MaskMap", asset)
  end
  
  for i = 1, self.MaxTileCount do
    local id = ""
    if i < 10 then
      id = string.format("%s%d", "0", i)
    else
      id = tostring(i)
    end
    local fileName = string.format("T_BigMap_Mask_%s", id)
    local path = string.format("%s%d%s%s%s%s", "/Game/NewRoco/Modules/System/BigMap/Raw/Texture/Masks/", sceneResId or 10003, "/", fileName, ".", fileName)
    self:LoadPanelRes(path, 255, OnMaskResLoaded, nil, nil)
  end
  self:DrawMask(sceneResId)
end

function UMG_MainMap_C:DrawMask(sceneResId)
  if sceneResId ~= self.data.lastDrawMaskSceneResId then
    if not BigMapUtils.IsBigWorldMap(sceneResId) and 30002 ~= sceneResId then
      return
    end
    self.data:DrawMaskTexture(sceneResId)
  end
end

function UMG_MainMap_C:ShowMapAreaInfo()
  if not self.showAreaNpcDatas then
    return
  end
  for id, info in pairs(self.showAreaNpcDatas) do
    local posX, posY = self:ScenePositionToImagePosition(info.area_pos.X, info.area_pos.Y)
    if info.isNewUnLock then
      local delayId = _G.DelayManager:DelaySeconds(1, self.CreateMapAreaIcon, self, id, posX, posY, info)
      table.insert(self.DelayShowIcon, delayId)
    else
      self:CreateMapAreaIcon(id, posX, posY, info)
    end
  end
end

function UMG_MainMap_C:ClearAllNpc()
  self.npcIconCreator:ClearAll()
end

function UMG_MainMap_C:ClearMapIcons()
  self.mapItemCreator:Interrupt()
  self.npcIconCreator:ClearAll()
  self.iconCircleCreator:ClearAll()
  self.areaNameCreator:ClearAll()
  self.taskIconCreator:ClearAll()
  self.markerIconCreator:ClearAll()
  self.visitorIconCreator:ClearAll()
end

function UMG_MainMap_C:ClearAllItems()
  for k, v in ipairs(self.creatorList) do
    if v and v.ClearAll() then
      v:ClearAll()
    end
  end
end

function UMG_MainMap_C:ShowNpcInfoSingle(npcInfo)
  if not npcInfo then
    Log.Error("UMG_MainMap_C:ShowNpcInfoSingle npcInfo is nil")
    return
  end
  if self.data:GetCurTraceNpcData() and npcInfo.entry_id ~= self.data:GetCurTraceNpcData().entry_id then
    local worldMapCfg = self.WorldMapConfigs[npcInfo.world_map_cfg_id]
    if not worldMapCfg then
      return
    end
    local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(worldMapCfg.element_show_scale)
    if not scaleConf then
      return
    end
    if self.uiData.mapSliderScale <= scaleConf.max_scale / 100.0 and self.uiData.mapSliderScale >= scaleConf.min_scale / 100.0 then
    else
      return
    end
  else
  end
  if self.uiItem.npcIcons[npcInfo.entry_id] then
    return
  end
  local areaDatas = self.showAreaNpcDatas
  if areaDatas and areaDatas[npcInfo.world_map_cfg_id] then
    return
  end
  if npcInfo.npcCfg == nil then
    Log.Dump(npcInfo, 4, "UMG_MainMap_C:ShowNpcInfoSingle")
  end
  if npcInfo.npcCfg and npcInfo.npcCfg.genre and npcInfo.npcCfg.genre == _G.Enum.ClientNpcType.CNT_HOME_NPC then
    local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcInfo.entry_id)
    if npc and npc.viewObj then
      local pos = npc:GetActorLocation()
      npcInfo.npc_pos.x = pos.X
      npcInfo.npc_pos.y = pos.Y
    end
  end
  if npcInfo.worldMapConf and (npcInfo.worldMapConf.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING or npcInfo.worldMapConf.map_show_type == Enum.MapIconShowType.MAP_NPC_DAZZLING or npcInfo.worldMapConf.map_show_type == Enum.MapIconShowType.MAP_HANDBOOK_TRACK) then
    local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByLogicID, npcInfo.logic_id or -1)
    if npc and npc.viewObj then
      local pos = npc:GetActorLocation()
      npcInfo.npc_pos.x = pos.X
      npcInfo.npc_pos.y = pos.Y
    end
  end
  local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
  if self.isTravel then
    if npcInfo.npcCfg and npcInfo.npcCfg.genre == _G.Enum.ClientNpcType.CNT_CAMP then
      self:CreateNpcIcon(npcInfo.entry_id, posX, posY, npcInfo)
    end
  elseif npcInfo.isNewUnLock then
    self:DelaySeconds(1, self.CreateNpcIcon, self, npcInfo.entry_id, posX, posY, npcInfo)
  else
    self:CreateNpcIcon(npcInfo.entry_id, posX, posY, npcInfo)
  end
end

function UMG_MainMap_C:GetAreaSceneId(worldMapCfgId)
  if worldMapCfgId then
    local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
    local areaFunCfg = _G.DataConfigManager:GetAreaFuncConf(worldMapCfg.area_func_ids[1])
    local areaData = _G.DataConfigManager:GetAreaConf(areaFunCfg.area_id[1])
    return areaData.scene_id
  end
  return 0
end

function UMG_MainMap_C:GetCurSceneResId()
  return SceneUtils.GetSceneResId()
end

function UMG_MainMap_C:PlayNpcTraceEffect(_npcId, _isPlay, _isNpc)
  if _isNpc then
    if _npcId then
      local npcIcon = self.uiItem.npcIcons[_npcId]
      if npcIcon then
        npcIcon:PlayTraceEffect(_isPlay)
      end
    end
  elseif _npcId then
    local npcIcon = self.uiItem.mapAreaIcons[_npcId]
    if npcIcon then
      npcIcon:PlayTraceEffect(_isPlay)
    end
  end
end

function UMG_MainMap_C:GetMapShowLevel()
  local mapSliderScale = self.uiData.mapSliderScale or 0
  if mapSliderScale < 0.4 then
    return 1
  else
    return 2
  end
end

function UMG_MainMap_C:ScenePositionToImagePosition(_scenePosX, _scenePosY)
  local x = (_scenePosX - self.uiData.sceneOffsetX) * self.uiData.imageToSceneScale
  local y = (_scenePosY - self.uiData.sceneOffsetY) * self.uiData.imageToSceneScale
  return math.floor(x + 0.5), math.floor(y + 0.5)
end

function UMG_MainMap_C:ImagePositionToScenePosition(_imagePosX, _imagePosY)
  local x = _imagePosX / self.uiData.imageToSceneScale + self.uiData.sceneOffsetX
  local y = _imagePosY / self.uiData.imageToSceneScale + self.uiData.sceneOffsetY
  return math.floor(x + 0.5), math.floor(y + 0.5)
end

function UMG_MainMap_C:GetPlayerLocation()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local pos = player:GetActorLocationFrameCache()
    local dir = player.viewObj and player.viewObj:K2_GetActorRotation().Yaw + 90 or 0
    return pos, dir
  end
end

function UMG_MainMap_C:GetPlayerCameraDir()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerCameraManager = player:GetUEController().playerCameraManager
  if player then
    local dir = playerCameraManager and playerCameraManager:K2_GetActorRotation().Yaw + 90 or 0
    return dir
  end
end

function UMG_MainMap_C:SetMapCenterPosition(_posX, _posY, _bLerp, endPosLayerId)
  if true == _bLerp then
    self.EndPos = {X = _posX, Y = _posY}
    self.LerpToNewMapCenterPos = true
    return
  end
  local uiData = self.uiData
  local imagePosX = _posX or 0
  local imagePosY = _posY or 0
  local imageSizeX = uiData.originalMapWidth * self.imageScale.X
  local imageSizeY = uiData.originalMapHeight * self.imageScale.Y
  local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.layerParent:GetCachedGeometry())
  if imageSizeX <= wndSize.X then
    imagePosX = uiData.originalMapWidth / 2
  else
    local minValue = wndSize.X / 2
    local maxValue = imageSizeX - minValue
    minValue = minValue / self.imageScale.X
    maxValue = maxValue / self.imageScale.X
    if imagePosX < minValue then
      imagePosX = minValue
    elseif maxValue < imagePosX then
      imagePosX = maxValue
    end
  end
  if imageSizeY <= wndSize.Y then
    imagePosY = uiData.originalMapHeight / 2
  else
    local minValue = wndSize.Y / 2
    local maxValue = imageSizeY - minValue
    minValue = minValue / self.imageScale.Y
    maxValue = maxValue / self.imageScale.Y
    if imagePosY < minValue then
      imagePosY = minValue
    elseif maxValue < imagePosY then
      imagePosY = maxValue
    end
  end
  if UE4.UKismetMathLibrary.NearlyEqual_FloatFloat(uiData.mapCenterX, imagePosX) and UE4.UKismetMathLibrary.NearlyEqual_FloatFloat(uiData.mapCenterY, imagePosY) then
    return
  end
  uiData.mapCenterX = imagePosX
  uiData.mapCenterY = imagePosY
  local x = uiData.mapCenterX / uiData.originalMapWidth
  local y = uiData.mapCenterY / uiData.originalMapHeight
  self.mapLayer1:SetRenderTranslation(self:GetTempVector2D(-uiData.mapCenterX, -uiData.mapCenterY))
  self.mapLayer1:SetRenderTransformPivot(self:GetTempVector2D(x, y))
  self.mapLayer2:SetRenderTranslation(self:GetTempVector2D(-uiData.mapCenterX, -uiData.mapCenterY))
  self.mapLayer3:SetRenderTranslation(self:GetTempVector2D(-uiData.mapCenterX, -uiData.mapCenterY))
  self.mapLayer2:SetRenderTransformPivot(self:GetTempVector2D(x, y))
  self.mapLayer3:SetRenderTransformPivot(self:GetTempVector2D(x, y))
  self.layerMapLayer:SetRenderTranslation(self:GetTempVector2D(-uiData.mapCenterX, -uiData.mapCenterY))
  self.layerMapLayer:SetRenderTransformPivot(self:GetTempVector2D(x, y))
  self.isTouchClick = false
  self:UpdateTraceIconPositionAndVisible()
  self.curShowPieceIdList = BigMapUtils.GetLoadPiecesByImagePosition(1024, self.curWndSize, self:GetTempVector2D(uiData.mapCenterX, uiData.mapCenterY), self.uiData.mapImageScale)
  self:UpdateMapByPosition()
  self:SetCenterAreaId(endPosLayerId)
end

function UMG_MainMap_C:SetCenterAreaId(endPosLayerId)
  local curShowDeadWoodList = self.data.checkDeadWoodList[self.data.curShowSceneResId]
  if curShowDeadWoodList and #curShowDeadWoodList > 0 then
    local posU = self.uiData.mapCenterX / self.uiData.originalMapWidth * 1024
    local posV = self.uiData.mapCenterY / self.uiData.originalMapHeight * 1024
    local areaIdArray = UE4.UNRCTUIStatics.GetPointAreaId(posU, posV, curShowDeadWoodList)
    local areaIds = areaIdArray:ToTable()
    if areaIds and #areaIds > 0 then
      if self.bUseCenterLayerId == true then
        local layerId = self:GetLayerId(areaIds)
        if layerId > 0 then
          self:SetLayerMapList(layerId, not endPosLayerId)
        else
          self:SetLayerMapList(0)
        end
      end
      self:SetExploredInfo(areaIds[1])
    end
  end
end

function UMG_MainMap_C:GetLayerId(areaIds)
  local layerId = 0
  for k, v in ipairs(areaIds) do
    local areaFunId = self.data.AreaIdToAreaFuncId[v]
    if areaFunId then
      local mapLayerConf = self.data.AreaFuncIdToLayerInfo[areaFunId]
      if mapLayerConf then
        layerId = mapLayerConf.id
      end
    end
  end
  return layerId
end

function UMG_MainMap_C:SetExploredInfo(areaId)
  if areaId and areaId > 0 and areaId ~= self.curCenterAreaId then
    local campRefreshId = self.data.AreaIdToRefreshId[areaId]
    self.curCenterAreaId = areaId
    if campRefreshId and campRefreshId > 0 then
      local campConf = _G.DataConfigManager:GetCampConf(campRefreshId)
      if campConf then
        self.Text:SetText(campConf.camp_name)
        local x, y = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetPetGatherRate, campRefreshId)
        local text = string.format(_G.DataConfigManager:GetLocalizationConf("worldmap_area_exploration").msg, x, y)
        self.Text_1:SetText(text)
        self.Text_2:SetText(text)
      end
    end
  end
end

function UMG_MainMap_C:SetMapScale(_scale, _force, _scaleRatio)
  if not _scale then
    return
  end
  if self.uiData.originalMapHeight * _scale <= self.curWndSize.Y or self.uiData.originalMapHeight * _scale <= self.curWndSize.X then
    return
  end
  self.uiData.mapSliderScale = _scaleRatio
  local uiData = self.uiData
  local isLessen = _scale < uiData.mapImageScale
  if _scale ~= uiData.mapImageScale or _force then
    self.mapItemCreator:Interrupt()
    uiData.mapImageScale = _scale
    self.imageScale.X = _scale
    self.imageScale.Y = _scale
    self.mapLayer1:SetRenderScale(self.imageScale)
    self.mapLayer2:SetRenderScale(self.imageScale)
    self.mapLayer3:SetRenderScale(self.imageScale)
    self.layerMapLayer:SetRenderScale(self.imageScale)
    self:UpdateIconScale(_scale, _force, _scaleRatio)
    if isLessen then
      self:SetMapCenterPosition(uiData.mapCenterX, uiData.mapCenterY)
    end
    local mapShowLevel = self:GetMapShowLevel()
    self.curMapShowLevel = mapShowLevel
    self.npcIconCreator:UpdateMapShowLevel(self.uiData.mapSliderScale)
    self.visitorIconCreator:UpdateMapShowLevel(self.uiData.mapSliderScale)
    self.traceIconCreator:UpdateMapShowLevel(self.uiData.mapSliderScale)
    self.iconCircleCreator:UpdateMapShowLevel(self.uiData.mapSliderScale)
    if not self.isTravel then
      self.markerIconCreator:UpdateMapShowLevel(self.uiData.mapSliderScale)
    end
  end
end

function UMG_MainMap_C:ChangeMapScaleSliderValue(_delta)
  local value = self.uiData.mapSliderScale + _delta
  if value > 1 then
    value = 1
  elseif value < 0 then
    value = 0
  end
  if not UE4.UKismetMathLibrary.NearlyEqual_FloatFloat(value, self.uiData.mapSliderScale) then
    self.isTouchClick = false
    self.mapScaleSlider:SetValue(value)
    self:OnMapScaleValueChanged(value)
  end
end

function UMG_MainMap_C:GetMapImageScale(_sliderScale)
  local minScale = 0.64
  local maxScale = 2.5
  for k, v in ipairs(self.data.MapShowList) do
    if v.sceneResId == self.data.curShowSceneResId then
      minScale = v.minScale / 100
      maxScale = v.maxScale / 100
    end
  end
  return minScale + (maxScale - minScale) * _sliderScale
end

function UMG_MainMap_C:SetIconScaleBySelected(_info)
  local scaleParam = self:GetScaleParam()
  self:UndoSelectIconScale()
  if _info.npcCfg then
    self.data:SetCurSelectedIconInfo(bigMapModuleEnum.CreatorPriority.NpcIcons, _info)
    self:UpdateSelectIconScale(bigMapModuleEnum.CreatorPriority.NpcIcons, _info, scaleParam, true)
  elseif _info.MarksType and _info.MarksType == bigMapModuleEnum.MarksType.CustomMark then
    self.data:SetCurSelectedIconInfo(bigMapModuleEnum.CreatorPriority.MarkerIcons, _info)
    self:UpdateSelectIconScale(bigMapModuleEnum.CreatorPriority.MarkerIcons, _info, scaleParam, true)
  elseif _info.visitorIndex and _info.visitorIndex > 0 then
    self.data:SetCurSelectedIconInfo(bigMapModuleEnum.CreatorPriority.VisitorIcons, _info)
    self:UpdateSelectIconScale(bigMapModuleEnum.CreatorPriority.VisitorIcons, _info, scaleParam, true)
  elseif _info.TaskConf then
    self.data:SetCurSelectedIconInfo(bigMapModuleEnum.CreatorPriority.TaskIcons, _info)
    self:UpdateSelectIconScale(bigMapModuleEnum.CreatorPriority.TaskIcons, _info, scaleParam, true)
  else
    Log.Dump(_info, 5, "UMG_MainMap_C:SetIconScaleBySelected")
  end
end

function UMG_MainMap_C:UpdateSelectIconScale(type, iconInfo, _scaleParam, bZoomIn)
  local kValue = bZoomIn and 1.2 or 1
  if type > 0 and iconInfo then
    if type == bigMapModuleEnum.CreatorPriority.NpcIcons then
      self.npcIconCreator:UpdateIconScaleById(iconInfo.entry_id, iconInfo.logic_id, _scaleParam * kValue)
    elseif type == bigMapModuleEnum.CreatorPriority.MarkerIcons then
      self.markerIconCreator:UpdateIconScaleByMarkId(iconInfo.mark_id, _scaleParam * kValue)
    elseif type == bigMapModuleEnum.CreatorPriority.VisitorIcons then
      self.visitorIconCreator:UpdateIconScaleByUin(iconInfo.visitorInfo.uin, _scaleParam * kValue)
    elseif type == bigMapModuleEnum.CreatorPriority.TaskIcons then
      self.taskIconCreator:UpdateIconScaleByParam(iconInfo.TaskConf.id, iconInfo.SubTaskId, iconInfo.go_index, _scaleParam * kValue)
    end
  end
end

function UMG_MainMap_C:UndoSelectIconScale()
  local curSelectIconInfo = self.data:GetCurSelectedIconInfo()
  if curSelectIconInfo then
    local scaleParam = self:GetScaleParam()
    local type = curSelectIconInfo.type
    local iconInfo = curSelectIconInfo.iconInfo
    self:UpdateSelectIconScale(type, iconInfo, scaleParam, false)
  end
end

local FOG_THRESHOLD = 125
local MOUSE_ICON_ZORDER = 12

function UMG_MainMap_C:IsInScaleRange(mapShowLevel, scaleConf)
  if not scaleConf then
    return true
  end
  return mapShowLevel <= scaleConf.max_scale / 100.0 and mapShowLevel >= scaleConf.min_scale / 100.0
end

function UMG_MainMap_C:IsNotInFog(sceneX, sceneY, threshold)
  threshold = threshold or FOG_THRESHOLD
  if not BigMapUtils.IsBigWorldMap(self.data.curShowSceneResId) then
    return true
  end
  local posX, posY = self:ScenePositionToImagePosition(sceneX, sceneY)
  local posU = posX / self.uiData.originalMapWidth
  local posV = posY / self.uiData.originalMapHeight
  local RValue = UE4.UNRCTUIStatics.GetTexture2DPixelColorFromUV(self.data.FullMaskRunTime, self:GetTempVector2D(posU, posV))
  return threshold < RValue.R
end

function UMG_MainMap_C:IsInRange(x, y, radius2)
  return radius2 >= x * x + y * y
end

function UMG_MainMap_C:GetNpcShowTopAndFogCheck(npcInfo, worldMapCfg, traceNpcInfo)
  local showTop = 0
  if npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.LOCKED then
    if worldMapCfg and 1 == worldMapCfg.lock_element_show_top then
      showTop = 1
    end
  elseif worldMapCfg and 1 == worldMapCfg.unlock_element_show_top then
    showTop = 1
  end
  if traceNpcInfo and traceNpcInfo.npc_refresh_id == npcInfo.npc_refresh_id then
    local npcCfg = npcInfo.npcCfg
    local isSpecialNpc = npcCfg and (npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS or npcCfg.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT or npcCfg.genre == Enum.ClientNpcType.CNT_FLOWER_SEED)
    local isRandomShop = worldMapCfg and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP
    if isSpecialNpc or isRandomShop or self.module.TraceOnFogArea then
      showTop = 1
    end
  end
  return 1 == showTop, 1 ~= showTop
end

function UMG_MainMap_C:ShouldShowNpc(npcInfo, worldMapCfg, mapShowLevel, traceNpcInfo)
  local isShow = true
  local npcShowScale = worldMapCfg and worldMapCfg.element_show_scale
  if npcShowScale then
    local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(npcShowScale)
    isShow = self:IsInScaleRange(mapShowLevel, scaleConf)
  end
  if traceNpcInfo and npcInfo.entry_id == traceNpcInfo.entry_id then
    isShow = true
  end
  if npcInfo.npc_remain_time and npcInfo.npc_remain_time > 0 then
    isShow = false
  end
  if self.isTravel then
    if worldMapCfg and worldMapCfg.map_tips_show_type ~= Enum.MapTipsShowType.MAP_TIPS_CAMP then
      isShow = false
    end
  elseif self.module.TraceOnFogArea then
    if traceNpcInfo and traceNpcInfo.npc_refresh_id == npcInfo.npc_refresh_id then
      isShow = true
    elseif not self.data:CheckShouldShowNpc(npcInfo) then
      isShow = false
    end
  end
  local isCatchPet = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.IsShowCatchPet, npcInfo.npc_refresh_id)
  if isCatchPet then
    isShow = true
  end
  if isShow and worldMapCfg and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_NONE then
    isShow = false
  end
  return isShow
end

function UMG_MainMap_C:FilterNpcsInRange(npcList, radius2, sceneCenterX, sceneCenterY, mapShowLevel)
  local npcDatas = self.module.TraceOnFogArea and self.data:GetNpcDatas() or self.showNpcDatas
  if not npcDatas then
    return
  end
  local traceNpcInfo = self.data:GetCurTraceNpcData()
  for _, npcInfos in pairs(npcDatas) do
    for _, _npcInfos in pairs(npcInfos) do
      for _, npcInfo in pairs(_npcInfos) do
        local worldMapCfg = self.WorldMapConfigs[npcInfo.world_map_cfg_id] or self.WorldMapConfigs[npcInfo.npc_refresh_id]
        if not self:ShouldShowNpc(npcInfo, worldMapCfg, mapShowLevel, traceNpcInfo) then
        else
          local x = npcInfo.npc_pos.x - sceneCenterX
          local y = npcInfo.npc_pos.y - sceneCenterY
          if not self:IsInRange(x, y, radius2) then
          else
            local _, checkFog = self:GetNpcShowTopAndFogCheck(npcInfo, worldMapCfg)
            if checkFog then
              if self:IsNotInFog(npcInfo.npc_pos.x, npcInfo.npc_pos.y) then
                npcInfo.orderPos = {
                  x = npcInfo.npc_pos.x,
                  y = npcInfo.npc_pos.y
                }
                table.insert(npcList, npcInfo)
              else
                Log.Debug("[UMG_MainMap_C:ShowNpcListForRange]npc in fog area:", npcInfo.npc_cfg_id)
              end
            elseif worldMapCfg then
              npcInfo.orderPos = {
                x = npcInfo.npc_pos.x,
                y = npcInfo.npc_pos.y
              }
              table.insert(npcList, npcInfo)
            end
          end
        end
      end
    end
  end
end

function UMG_MainMap_C:FilterAreaNpcsInRange(npcList, radius2, sceneCenterX, sceneCenterY, mapShowLevel)
  local areaDatas = self.showAreaNpcDatas
  if not areaDatas then
    return
  end
  for _, areaInfo in pairs(areaDatas) do
    local worldMapCfg = self.WorldMapConfigs[areaInfo.world_map_cfg_id]
    if not worldMapCfg then
    else
      local isShow = true
      local npcShowScale = worldMapCfg.element_show_scale
      if npcShowScale then
        local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(npcShowScale)
        isShow = self:IsInScaleRange(mapShowLevel, scaleConf)
      end
      if worldMapCfg.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_NONE then
        isShow = false
      end
      if not isShow or not areaInfo.npcList then
      else
        local x = areaInfo.npcList[1].npc_pos.x - sceneCenterX
        local y = areaInfo.npcList[1].npc_pos.y - sceneCenterY
        if not self:IsInRange(x, y, radius2) then
        else
          local showTop = areaInfo.unlocked and worldMapCfg.unlock_element_show_top or worldMapCfg.lock_element_show_top
          local checkFog = 1 ~= showTop
          if checkFog then
            if worldMapCfg then
              local hasSame = false
              for i = 1, #npcList do
                if npcList[i].world_map_cfg_id == areaInfo.world_map_cfg_id then
                  hasSame = true
                  break
                end
              end
              if not hasSame then
                areaInfo.orderPos = {
                  x = areaInfo.npcList[1].npc_pos.x,
                  y = areaInfo.npcList[1].npc_pos.y
                }
                table.insert(npcList, areaInfo)
              end
            end
          elseif worldMapCfg then
            areaInfo.orderPos = {
              x = areaInfo.npcList[1].npc_pos.x,
              y = areaInfo.npcList[1].npc_pos.y
            }
            table.insert(npcList, areaInfo)
          end
        end
      end
    end
  end
end

function UMG_MainMap_C:FilterTasksInRange(npcList, radius2, sceneCenterX, sceneCenterY)
  if self.isTravel then
    return
  end
  local taskDatas = self.data:GetShowTaskInfo()
  if not taskDatas or 0 == #taskDatas then
    return
  end
  local TrackList = {}
  local CurTrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetDataTrackTask)
  if CurTrackTask and CurTrackTask.Trackers then
    for _, TrackItem in pairs(CurTrackTask.Trackers) do
      TrackList[TrackItem.TaskInfo.id] = TrackItem
    end
  end
  local CurSceneResId = self:GetCurSceneResId()
  local preAddTaskInfoDic = {}
  for _, taskInfo in ipairs(taskDatas) do
    local isShow = self.data:SeparatedTaskByGuideList(taskInfo.TaskSceneResId, self.data.curShowSceneResId, taskInfo.TaskShowType)
    if isShow and taskInfo.NpcPosition and #taskInfo.NpcPosition > 0 then
      local x = taskInfo.NpcPosition[1].pos.x - sceneCenterX
      local y = taskInfo.NpcPosition[1].pos.y - sceneCenterY
      if taskInfo.TaskShowType == bigMapModuleEnum.TaskShowType.TRACING and TrackList[taskInfo.TaskConf.id] and self.data.curShowSceneResId == CurSceneResId then
        if not self.CurTrackTaskPosList[taskInfo.TaskConf.id] then
          local TrackItem = TrackList[taskInfo.TaskConf.id]
          local Pos = TrackItem:GetPosition()
          if Pos then
            self.CurTrackTaskPosList[taskInfo.TaskConf.id] = Pos
          end
        end
        local TrackPos = self.CurTrackTaskPosList[taskInfo.TaskConf.id]
        if TrackPos then
          x = TrackPos.X - sceneCenterX
          y = TrackPos.Y - sceneCenterY
        end
      end
      if self:IsInRange(x, y, radius2) then
        self.mouseIcon.Slot:SetZOrder(MOUSE_ICON_ZORDER)
        local paragraphId = taskInfo.TaskConf.paragraph_id
        preAddTaskInfoDic[paragraphId] = preAddTaskInfoDic[paragraphId] or {}
        table.insert(preAddTaskInfoDic[paragraphId], taskInfo)
      end
    end
  end
  for _, preAddTaskInfos in pairs(preAddTaskInfoDic) do
    local winItem = preAddTaskInfos[1]
    if #preAddTaskInfos > 1 then
      for _, taskInfo in ipairs(preAddTaskInfos) do
        if 1 == #taskInfo.NpcPosition then
          winItem = taskInfo
          break
        end
      end
    end
    winItem.orderPos = {
      x = winItem.NpcPosition[1].pos.x,
      y = winItem.NpcPosition[1].pos.y
    }
    if self.CurTrackTaskPosList and self.CurTrackTaskPosList[winItem.TaskConf.id] then
      local TrackPos = self.CurTrackTaskPosList[winItem.TaskConf.id]
      winItem.orderPos = {
        x = TrackPos.X,
        y = TrackPos.Y
      }
    end
    table.insert(npcList, winItem)
  end
end

function UMG_MainMap_C:FilterCustomMarksInRange(npcList, radius2, sceneCenterX, sceneCenterY, mapShowLevel)
  if self.isTravel then
    return
  end
  local customPointInfo = self.data:GetNewCustomPointInfo()
  for _, point in ipairs(customPointInfo) do
    local isShow = point.is_track
    if not isShow then
      local elementShowScale = _G.DataConfigManager:GetMapGlobalConfig("oneself_mark_scale").num
      local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(elementShowScale)
      isShow = self:IsInScaleRange(mapShowLevel, scaleConf)
    end
    if isShow then
      local x = point.pos.x - sceneCenterX
      local y = point.pos.y - sceneCenterY
      if self:IsInRange(x, y, radius2) then
        local posX, posY = self:ScenePositionToImagePosition(point.pos.x, point.pos.y)
        table.insert(npcList, {
          MarksType = bigMapModuleEnum.MarksType.CustomMark,
          imageCenterPos = {X = posX, Y = posY},
          name = point.name,
          mapCfgId = point.world_map_cfg_id,
          mark_id = point.mark_id,
          orderPos = {
            x = point.pos.x,
            y = point.pos.y
          }
        })
      end
    end
  end
end

function UMG_MainMap_C:FilterVisitorPointsInRange(npcList, radius2, sceneCenterX, sceneCenterY)
  local visitPointList = self.data:GetVisitPointInfo()
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  for key, visitInfo in pairs(visitPointList) do
    if visitInfo and visitInfo.uin ~= playerUin and visitInfo.pos and visitInfo.pos.pos then
      local _, _, posX, posY = BigMapUtils.GetVisitorIconSceneResIdAndPos(visitInfo)
      local x = posX - sceneCenterX
      local y = posY - sceneCenterY
      if self:IsInRange(x, y, radius2) then
        table.insert(npcList, {
          visitorIndex = key,
          visitorInfo = visitInfo,
          orderPos = {
            x = visitInfo.pos.pos.x,
            y = visitInfo.pos.pos.y
          }
        })
      end
    end
  end
end

function UMG_MainMap_C:FilterTempNpcInRange(npcList, radius2, sceneCenterX, sceneCenterY)
  for entryId, val in pairs(self.tempIconInfoList) do
    for logicId, v in pairs(val) do
      if v and v.worldMapConf then
        local x = v.npc_pos.x - sceneCenterX
        local y = v.npc_pos.y - sceneCenterY
        if self:IsInRange(x, y, radius2) then
          v.orderPos = {
            x = v.npc_pos.x,
            y = v.npc_pos.y
          }
          table.insert(npcList, v)
        end
      end
    end
  end
end

function UMG_MainMap_C:HandleEmptyNpcList(_imageCenterPos)
  if self.module:CheckMapRightPanelOpened() then
    self.module:OnCmdCloseMapRightPanel()
    return
  end
  self:SetMouseScale(1)
  if self.npcListLayer:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self:HideNPCList()
    self.mouseIcon:showEndAni()
  elseif self:IsCanMarker() and not self.isTravel then
    self:ShowMouseIcon()
    self:NewMarkerEvent(_imageCenterPos, 35)
  end
end

function UMG_MainMap_C:HandleSingleNpc(npcInfo, _imageCenterPos)
  self:SetMouseScale(1)
  self:HideNPCList()
  self:ShowMouseIcon()
  if npcInfo.npc_pos then
    self.mouseIcon.Slot:SetZOrder(MOUSE_ICON_ZORDER)
    local worldMapCfg = self.WorldMapConfigs[npcInfo.world_map_cfg_id]
    if worldMapCfg and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
      _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SwitchSelectIcon, npcInfo.npc_refresh_id, true)
    end
    self:OnSingleIconClicked(npcInfo)
  elseif npcInfo.MarksType == bigMapModuleEnum.MarksType.CustomMark then
    self:NewMarkerEvent(_imageCenterPos, 35)
  else
    self:OnSingleIconClicked(npcInfo)
  end
end

function UMG_MainMap_C:HandleMultipleNpcs(npcList, _imageCenterPos)
  self:SetMouseScale(1.5)
  self:ShowMouseIcon()
  if not self.isTravel then
    for _, showInfo in ipairs(npcList) do
      if showInfo.orderPos then
        local posX, posY = BigMapUtils.ScenePosToImagePosF(self.data.curShowSceneResId, showInfo.orderPos.x, showInfo.orderPos.y)
        showInfo.orderDis = (posX - _imageCenterPos.X) ^ 2 + (posY - _imageCenterPos.Y) ^ 2
      end
    end
    table.sort(npcList, function(a, b)
      return a.orderDis < b.orderDis
    end)
    self:ShowNPCList(npcList)
    self:ShowNpcRightPanel(npcList[1], true)
  else
    self:HideNPCList()
    for _, npcInfo in ipairs(npcList) do
      if npcInfo.npcCfg and self:IsCampRefreshId(npcInfo.npc_refresh_id) then
        self:OnSingleIconClicked(npcInfo)
        break
      end
    end
  end
end

function UMG_MainMap_C:ShowNpcListForRange(_imageCenterPos, _imageRadius)
  self:UndoSelectIconScale()
  self.showNpcDatas = self.data:GetAllShowNpcs(self.data.curShowSceneResId)
  local sceneCenterX, sceneCenterY = self:ImagePositionToScenePosition(_imageCenterPos.X, _imageCenterPos.Y)
  local sceneRadius = math.ceil(_imageRadius / self.uiData.imageToSceneScale / self.uiData.mapImageScale)
  local npcList = {}
  local radius2 = sceneRadius * sceneRadius
  local mapShowLevel = self.uiData.mapSliderScale
  self:FilterNpcsInRange(npcList, radius2, sceneCenterX, sceneCenterY, mapShowLevel)
  self:FilterAreaNpcsInRange(npcList, radius2, sceneCenterX, sceneCenterY, mapShowLevel)
  self:FilterTasksInRange(npcList, radius2, sceneCenterX, sceneCenterY)
  self:FilterCustomMarksInRange(npcList, radius2, sceneCenterX, sceneCenterY, mapShowLevel)
  self:FilterVisitorPointsInRange(npcList, radius2, sceneCenterX, sceneCenterY)
  self:FilterTempNpcInRange(npcList, radius2, sceneCenterX, sceneCenterY)
  local npcCount = #npcList
  if npcCount <= 0 then
    self:HandleEmptyNpcList(_imageCenterPos)
  elseif 1 == npcCount then
    self:HandleSingleNpc(npcList[1], _imageCenterPos)
  else
    self:HandleMultipleNpcs(npcList, _imageCenterPos)
  end
end

function UMG_MainMap_C:ShowMouseIcon()
  if not self.module:CheckMapRightPanelOpened() and self.npcListLayer:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    self.mouseIcon:showAni(self.dot_2Pos)
  end
  self.mouseIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_MainMap_C:SetMousePosition(showPos)
  self.mouseIcon:showAni(showPos)
end

function UMG_MainMap_C:SetMouseScale(scale)
  local _scale = 1.0 / self.uiData.mapImageScale
  local scaleParam = self:GetTempVector2D(_scale, _scale)
  self.mouseIcon:SetRenderScale(scaleParam * scale)
  self.mouseScaleParam = scale
end

function UMG_MainMap_C:IsCanMarker()
  return not BigMapUtils.IsHomeMap(self.data.curShowSceneResId)
end

function UMG_MainMap_C:IsCampRefreshId(npc_refresh_id)
  local isCamp = false
  local campConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CAMP_CONF):GetAllDatas()
  for index, campConf in pairs(campConfs) do
    if campConf and campConf.area_id > 0 and campConf.id == npc_refresh_id then
      isCamp = true
      break
    end
  end
  return isCamp
end

function UMG_MainMap_C:ShowNpcRightPanel(npcInfo, bOnlySelect, bSanctuary)
  if not npcInfo then
    return
  end
  if self.isTravel and self:IsCampRefreshId(npcInfo.npc_refresh_id) == false then
    return
  end
  local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.traceLayer:GetCachedGeometry())
  if wndSize.X >= 0 and wndSize.Y >= 0 then
    local posX, posY, posX_1, posY_1
    if npcInfo.area_pos == nil then
      if npcInfo.visitorInfo and npcInfo.visitorInfo.pos and npcInfo.visitorInfo.pos.pos then
        do
          local visitorPos = npcInfo.visitorInfo.pos.pos
          posX, posY = self:ScenePositionToImagePosition(visitorPos.x, visitorPos.y)
        end
      elseif nil == npcInfo.npc_pos then
        if npcInfo.NpcPosition and #npcInfo.NpcPosition > 0 then
          if npcInfo.orderPos then
            posX, posY = self:ScenePositionToImagePosition(npcInfo.orderPos.x, npcInfo.orderPos.y)
            posX_1, posY_1 = self:GetViewPos(npcInfo.orderPos.x, npcInfo.orderPos.y)
          else
            posX, posY = self:ScenePositionToImagePosition(npcInfo.NpcPosition[1].pos.x, npcInfo.NpcPosition[1].pos.y)
            posX_1, posY_1 = self:GetViewPos(npcInfo.NpcPosition[1].pos.x, npcInfo.NpcPosition[1].pos.y)
          end
        elseif npcInfo.imageCenterPos then
          posX = npcInfo.imageCenterPos.X
          posY = npcInfo.imageCenterPos.Y
        end
      else
        posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
        posX_1, posY_1 = self:GetViewPos(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
      end
    elseif npcInfo.npcList and #npcInfo.npcList > 0 then
      posX, posY = self:ScenePositionToImagePosition(npcInfo.npcList[1].npc_pos.x, npcInfo.npcList[1].npc_pos.y)
      posX_1, posY_1 = self:GetViewPos(npcInfo.npcList[1].npc_pos.x, npcInfo.npcList[1].npc_pos.y)
    end
    local mousePos = self:GetTempVector2D(posX, posY)
    if self.isTravel and npcInfo.npcCfg and not self:CheckIsSelectBtn() and self:IsCampRefreshId(npcInfo.npc_refresh_id) then
      local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "MainBigMap").TELEPORT
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BigMapModule", "MainBigMap", touchReasonType)
      self:OpenTravelPanel(npcInfo)
      self.mouseIcon:showAni(mousePos)
    end
    if self.mouseIcon.isShow then
      self.mouseIcon:setShowPosition(mousePos)
    else
      self.mouseIcon:showAni(mousePos)
    end
    self:SetIconScaleBySelected(npcInfo)
  end
  if not bOnlySelect then
    self:OnShowNormalNpcEvent(npcInfo, bSanctuary)
  end
end

function UMG_MainMap_C:GetViewPos(_PosX, _PosY)
  local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.traceLayer:GetCachedGeometry())
  local posX, posY = self:ScenePositionToImagePosition(_PosX, _PosY)
  posX = (posX - (self.uiData.mapCenterX or 0)) * self.uiData.mapImageScale
  posY = (posY - (self.uiData.mapCenterY or 0)) * self.uiData.mapImageScale
  posX = posX + wndSize.X / 2
  posY = posY + wndSize.Y / 2
  return posX, posY
end

function UMG_MainMap_C:BeginPlayFogAni(_curScale)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1256, "UMG_MainMap_C:BeginPlayFogAni")
  self.curFogScale = _curScale or 0
  self.isPlayFogAni = true
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.OpenInputBlocker, "UMG_MainMap_C")
  if self.playAniWorldMapCfgId and self.playAniWorldMapCfgId > 0 then
    local areaItem = self.uiItem.areaInfos[self.playAniWorldMapCfgId]
    if areaItem then
      areaItem:PlayShowAnimation(false)
    end
  end
end

function UMG_MainMap_C:OnFogAniPlayEnd()
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.CloseInputBlocker, "UMG_MainMap_C")
  if self.playAniWorldMapCfgId and self.playAniWorldMapCfgId > 0 then
    local areaItem = self.uiItem.areaInfos[self.playAniWorldMapCfgId]
    if areaItem then
      areaItem:PlayShowAnimation(true)
    end
  end
  self.playAniWorldMapCfgId = nil
end

function UMG_MainMap_C:OnAnimationFinished(Animation)
  if Animation == self.open then
    UE4Helper.SetEnableWorldRendering(false)
    local refreshIds = {}
    if self.data.UnlockDeadwoodList[self.data.curShowSceneResId] and #self.data.UnlockDeadwoodList[self.data.curShowSceneResId] > 0 then
      for k, v in ipairs(self.data.UnlockDeadwoodList[self.data.curShowSceneResId]) do
        if self.data.AreaIdToRefreshId[v] and self.data.AreaIdToRefreshId[v] > 0 then
          table.insert(refreshIds, self.data.AreaIdToRefreshId[v])
        end
      end
      self.module:CmdZoneGetCampFruitNpcInfosReq(refreshIds)
    end
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_BIGMAP_OPEN)
    local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local playerController = player:GetUEController()
    if not UE4Helper.IsPCMode() and playerController then
      playerController:DisableInput(playerController)
      playerController:ClearTouches()
      playerController:EnableInput(playerController)
    end
    self:SetPanelAlreadyVisible()
    self:UpdateTraceIconPositionAndVisible()
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.CloseTaskMainPanel)
  elseif Animation == self.close or Animation == self.close2 then
    self:HidePanel()
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1385, "UMG_MainMap_C:OnAnimationFinished")
  end
end

function UMG_MainMap_C:HideMask(bHide)
  if bHide then
    self.MapMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.MapMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_MainMap_C:InitMapSwitchTable()
  self.TravelSwitchBtn1:Init(1)
  self.TravelSwitchBtn2:Init(2)
  self.TravelSwitchBtn1:OnChangeAim(not self.isTravel)
  self.TravelSwitchBtn2:OnChangeAim(self.isTravel)
  if self.isTravel and self.travelInfos and #self.travelInfos > 0 then
    self:CreateAllTraceTravelIcon()
  end
end

function UMG_MainMap_C:OnGetTravelTaskState()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TRAVEL, false)
  if false == isBan then
    self:InitMapSwitchTable()
    self.TravelButton:SetVisibility(self.data.curShowSceneResId == 10003 and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  else
    self.TravelButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:ShowTravelBtn()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TRAVEL, false)
  if isBan then
    return
  end
  local isShow = self.data.curShowSceneResId == 10003
  if isShow then
    self.TravelButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TravelButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainMap_C:ShowTravelRewardBtn()
  local isShow = false
  if self.travelInfos then
    for i, info in ipairs(self.travelInfos) do
      if info.travel_complete then
        isShow = self.isTravel
        break
      end
    end
  end
  self.BtnClaimfull:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_MainMap_C:OnChangeIsTravel(isTravel)
  _G.NRCAudioManager:PlaySound2DAuto(40008018, "UMG_MainMap_C:OnChangeIsTravel")
  for k, v in ipairs(self.creatorList) do
    if v.OnTravelStateChanged then
      v:OnTravelStateChanged(isTravel)
    end
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "MainBigMap").SWITCH
  if self.isTravel == isTravel then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BigMapModule", "MainBigMap", touchReasonType)
    return
  end
  self.data.isOpenTravel = isTravel
  self.isTravel = isTravel
  self.TravelSwitchBtn1:OnChangeAim(not self.isTravel)
  self.TravelSwitchBtn2:OnChangeAim(self.isTravel)
  self:OnBtnClose1Click(true)
  self.mapItemCreator:Interrupt()
  self:UpdateMapByPosition()
  if self.isTravel then
    _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.ExcludeUmgPanelEvent, "TravelSwitchBtn2")
    self:CreateAllTraceTravelIcon()
    _G.NRCModeManager:DoCmd(_G.TravelModuleCmd.UpdateTravelInfos)
    self.ComboBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self:ShowOrHideMoneyBtn(false)
    self.btnClose:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:ShowTravelRewardBtn()
    if self.travelInfos then
      self.CanvasPanel_1:InitNum(#self.travelInfos, self.MaxTravelNum, LuaText.travel_text)
    end
    self.Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_Plot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.traceIconCreator:CancelTrace(bigMapModuleEnum.TraceType.Travel)
    self:OnShowTaskIcon(self.data.curShowSceneResId)
    self:OnShowMarker()
    self:ShowOrHideMoneyBtn(true)
    self.ComboBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BtnClaimfull:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local isVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    if isVisit then
      self.Sanctuary:SetPath("PaperSprite'/Game/NewRoco/Modules/System/SleepingOwl/Raw/Frames/img_SharedWithFriendsBtn_png.img_SharedWithFriendsBtn_png'")
    end
    self.Hint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_Plot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:RefreshTitleInfo(self.isTravel)
  self:UpDateTempTraceIconsVisible()
  self:ShowHint(not self.isTravel)
  self:UpdateTraceIconPositionAndVisible()
  self:RefreshAreaGatherInfo()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BigMapModule", "MainBigMap", touchReasonType)
end

function UMG_MainMap_C:UpDateTempTraceIconsVisible()
  if self.isTravel then
    for key, v in pairs(self.uiItem.TempTraceIcons) do
      v:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    for key, v in pairs(self.uiItem.TempTraceIcons) do
      local posX = v.uiData.npc_pos.x
      local posY = v.uiData.npc_pos.y
      local tempIconResId = UIUtils.GetNpcSceneResIdByPosXY(posX, posY)
      if tempIconResId == self.data.curShowSceneResId then
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        v:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_MainMap_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "BigMapModule", "MainBigMap")
end

function UMG_MainMap_C:OnMouseEnter(MyGeometry, MouseEvent)
  self.bMouseInMapScope = true
end

function UMG_MainMap_C:OnMouseLeave(MyGeometry, MouseEvent)
  self.bMouseInMapScope = false
end

function UMG_MainMap_C:CheckIsTracing(traceType, info)
  if self.data.traceInfoList and self.data.traceInfoList[traceType] then
    if traceType == bigMapModuleEnum.TraceType.NPC then
      if self.data.traceInfoList[traceType].npcInfo.entry_id == info.entry_id and self.data.traceInfoList[traceType].npcInfo.logic_id == info.logic_id then
        return true
      end
    elseif traceType == bigMapModuleEnum.TraceType.Marker then
      if self.data.traceInfoList[traceType].markInfo.mark_id == info.mark_id then
        return true
      end
    elseif traceType == bigMapModuleEnum.TraceType.TempTrace then
      if self.data.traceInfoList[traceType] and self.data.traceInfoList[traceType][info.logic_id] then
        return true
      end
    elseif traceType == bigMapModuleEnum.TraceType.ForceTrace then
      local extraType = info.worldMapConf and info.worldMapConf.default_track_type or 0
      local traceList = self.data.traceInfoList[traceType] and self.data.traceInfoList[traceType][extraType]
      if traceList and #traceList > 0 then
        for k, traceInfo in ipairs(traceList) do
          if traceInfo.npcInfo and traceInfo.npcInfo.logic_id == info.logic_id then
            return true
          end
        end
      end
    end
  end
  return false
end

function UMG_MainMap_C:UpdateRandomShopHint()
  Log.Debug("UMG_MainMap_C:UpdateRandomShopHint")
  local npcRefreshId = self.module.data:GetRandomShopNpcRefreshId()
  if not npcRefreshId then
    Log.Debug("UMG_MainMap_C:UpdateRandomShopHint npcRefreshId is nil")
    self:UpdateHint()
    local showType = self.module.data:GetNpcTipShowType()
    if showType == _G.Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP and self.module:CheckMapRightPanelOpened() then
      Log.Debug("UMG_MainMap_C:UpdateRandomShopHint close right panel")
      self.module:OnCmdCloseMapRightPanel()
    end
  end
end

function UMG_MainMap_C:OnTravelShowMouseIcon(npcInfo)
  if npcInfo and npcInfo.npc_pos and npcInfo.npc_pos.x and npcInfo.npc_pos.y then
    local posX, posY = self:ScenePositionToImagePosition(npcInfo.npc_pos.x, npcInfo.npc_pos.y)
    if posX and posY then
      local mousePos = self:GetTempVector2D(posX, posY)
      if mousePos then
        self.mouseIcon:showAni(mousePos)
      end
    end
  end
end

return UMG_MainMap_C

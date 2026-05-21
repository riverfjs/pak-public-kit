local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local CreationFurnitureManager = require("NewRoco.Modules.System.Home.Res.FurnitureCreation.FurnitureManager")
local TouchEmptyHide = require("NewRoco.Modules.System.Home.Res.Helpers.TouchEmptyHide")
local HomeEnum = require("NewRoco.Modules.System.Home.HomeEnum")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local UMG_FurnitureCreation_C = _G.NRCPanelBase:Extend("UMG_FurnitureCreation_C")

function UMG_FurnitureCreation_C:OnConstruct()
  self.FurnitureManager = CreationFurnitureManager(self)
  self.TouchEmptyHideComboBox = TouchEmptyHide(self)
  self.FullScreenBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  self:OnAddEventListener()
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  self:SetCommonTitle()
  self.TabIconPathOverride = {
    [-1] = {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_IconRecommend_png.img_IconRecommend_png'",
      icon_selected = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_IconRecommend_Select_png.img_IconRecommend_Select_png'"
    }
  }
  self.Text_TimeRemaining_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.DebugCacheOffsetMap = {}
  self.DebugCacheRotationMap = {}
  self.DebugCacheScaleMap = {}
  if self.EmptyState then
    self.EmptyState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  self.SelfRoomLevel = HomeIndoorSandbox.Server:GetLocalHomeBriefInfo().room_level or 0
  if self.PromptText then
    self.PromptText:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.DisplayNumInTab = {}
end

function UMG_FurnitureCreation_C:OnDestruct()
  if _G.HomeModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CloseFurnitureFilterPanel)
  end
end

function UMG_FurnitureCreation_C:ReqClose()
  if self.bPendingClose then
    return
  end
  self.bPendingClose = true
  self:PlayAnimation(self.Out)
end

function UMG_FurnitureCreation_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:OnClose()
  end
end

function UMG_FurnitureCreation_C:OnActive(BuildListRsp, ExtraInfo)
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  self.BuildListRsp = BuildListRsp
  local BoxNpc = ExtraInfo and ExtraInfo.BoxNpc
  self.FurnitureManager:InitBasingBox(BoxNpc, "Socket_Furniture")
  if ExtraInfo and ExtraInfo.FurniturePointLight then
    self.PointLight = ExtraInfo.FurniturePointLight
  end
  if BuildListRsp then
    self:Init(BuildListRsp)
  end
  UpdateManager:Register(self)
end

function UMG_FurnitureCreation_C:OnDeactive()
  self.TouchEmptyHideComboBox:UnBind()
  self.FurnitureManager:Release()
  if self.RefreshTimer then
    DelayManager:CancelDelayById(self.RefreshTimer)
    self.RefreshTimer = nil
  end
  UpdateManager:UnRegister(self)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
end

function UMG_FurnitureCreation_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.ReqClose)
  self:AddButtonListener(self.Btn5.btnLevelUp, self.OnReqBuild)
  self:AddButtonListener(self.Btn3.btnLevelUp, self.OnNotifyLocked)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnFurnitureCreateSortTitleSelected, self.OnSortItemChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_FurnitureCreation_C", self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnRspPlayWorkAnimEnd, self.OnRspPlayWorkAnimEnd)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnPreEnterWorkAnimEnd, self.OnPreEnterWorkAnimEnd)
  self:RegisterEvent(self, HomeIndoorSandbox.Event.OnUserConfirmBuildFinish, self.OnUserConfirmBuildFinish)
  self:RegisterEvent(self, HomeModuleEvent.UpdateFurnitureFilter, self.OnFilterUpdate)
  self.TouchEmptyHideComboBox:Bind()
  self.TouchEmptyHideComboBox.OnTouchEmpty:Add(self, self.OnReqCloseSortPopup)
end

function UMG_FurnitureCreation_C:OnReqBuild()
  if self.bPendingReqBuilding then
    HomeIndoorSandbox:DebugTips("\231\173\137\229\190\133\230\137\147\233\128\160\230\182\136\230\129\175\232\191\148\229\155\158..")
    return
  end
  if not self.bCanCreateThis then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.furniture_build_text_3)
    return
  end
  local TargetFurnitureData = self.SelectedFurnitureData
  self.PerformFurnitureData = TargetFurnitureData
  if TargetFurnitureData then
    self.bPendingReqBuilding = true
    HomeIndoorSandbox.Server:ReqCreateFurniture(function(bSuccess, Proto)
      self.bPendingReqBuilding = false
      if not self.enableView then
        return
      end
      if bSuccess then
        self.BuildListRsp.self_map[TargetFurnitureData.FurnitureItemConf.id] = true
        HomeIndoorSandbox.Module.data:EvalCollectBagFurnitureItemInfo()
        self:RefreshByTabId()
        self:InitMoney()
        HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnReqPlayWorkAnimStart)
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.FurnitureManager:OnFurnitureWorkStart()
      end
      HomeIndoorSandbox:DebugTips(string.format("\230\137\147\233\128\160\231\187\147\230\157\159\239\188\140\231\187\147\230\158\156\239\188\154%s", bSuccess))
    end, TargetFurnitureData.FurnitureItemConf.id, 1)
  end
end

function UMG_FurnitureCreation_C:OnNotifyLocked()
  if self.bLockedThis then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.furniture_build_unlock_text)
    return
  end
  if not self.bCanCreateThis then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.furniture_build_text_3)
    return
  end
  if not self.bCanCreateThisRoomLevelThis then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, self.Text_Conditions:GetText())
    return
  end
end

function UMG_FurnitureCreation_C:OnPreEnterWorkAnimEnd()
  self.FurnitureManager:OnFurnitureWorkEnd()
end

function UMG_FurnitureCreation_C:OnUserConfirmBuildFinish()
  self.FurnitureManager:OnFurnitureCreateFinishConfirm()
end

function UMG_FurnitureCreation_C:OnRspPlayWorkAnimEnd()
  if UE.UObject.IsValid(self) then
    HomeIndoorSandbox.Module:OpenHomeFurnitureCreationResult(self.SelectedFurnitureData.FurnitureItemConf)
  end
end

function UMG_FurnitureCreation_C:OnClosePanel(panelData)
  local Name = panelData.panelName
  if "HomeCreationSuccess" == Name then
    if _G.ZoneServer:GetConnectState() ~= UE4.ENetConnectState.CONNECTED then
      return
    end
    HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnReqStopEndWork)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.In)
    self.PerformFurnitureData = nil
  end
end

function UMG_FurnitureCreation_C:TryRefreshModel(bFromClickManual)
  if bFromClickManual then
  end
  if self.SelectedFurnitureData then
    self:InternalRefreshModel()
  end
end

function UMG_FurnitureCreation_C:InitTabList()
  local TabIdList = HomeIndoorSandbox.Module.data:GetCreationFirstTabIdList()
  local DataList = {}
  local TabData = {
    icon = self.TabIconPathOverride[-1].icon,
    icon_selected = self.TabIconPathOverride[-1].icon_selected,
    recommend_flag = true,
    onClicked = FPartial(self.OnClickTab, self, -1)
  }
  table.insert(DataList, TabData)
  for i, tabId in ipairs(TabIdList) do
    local Conf = DataConfigManager:GetFurnitureClassificationConf(tabId)
    if Conf and Conf.tab_icon_build_1 then
      local ThisTabData = {
        icon = Conf.tab_icon_build_1,
        icon_selected = Conf.tab_icon_build_2,
        onClicked = FPartial(self.OnClickTab, self, tabId)
      }
      table.insert(DataList, ThisTabData)
    end
  end
  self.SeedList.OnFurnitureItemClicked = FPartial(self.OnFurnitureItemClicked, self)
  self.AllSecondTabFilterCache = {}
  self.Tab:InitGridView(DataList)
  self.Tab:SelectItemByIndex(0)
end

function UMG_FurnitureCreation_C:OnClickTab(TabId)
  self.CurTabId = TabId
  self:RefreshCommonTitle(TabId)
  self:RefreshByTabId()
  if -1 == self.CurTabId then
    self.White:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.White:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_FurnitureCreation_C:GetFurnitureListByTabId(TabId)
  if -1 == TabId then
    local ding_list = self.BuildListRsp and self.BuildListRsp.ding_list or {}
    local DataList = {}
    local HomeModuleData = HomeIndoorSandbox.Module:GetData()
    for i, v in ipairs(ding_list) do
      local Data = HomeModuleData:GetFurnitureDataByConfId(v)
      if Data then
        if Data.FurnitureItemConf and DataConfigManager:GetExchangeConf(Data.FurnitureItemConf.id, true) then
          table.insert(DataList, Data)
        end
      else
        HomeIndoorSandbox:Ensure(false, "cannot found furniture data", v)
      end
    end
    return DataList
  else
    local DataList = {}
    local DataListRef = HomeIndoorSandbox.Module.data:GetFurnitureListByTabId(TabId) or {}
    for i, Data in ipairs(DataListRef) do
      if Data.FurnitureItemConf and DataConfigManager:GetExchangeConf(Data.FurnitureItemConf.id, true) then
        table.insert(DataList, Data)
      end
    end
    return DataList
  end
end

function UMG_FurnitureCreation_C:RefreshCommonTitle(index)
  if index then
    if -1 == index then
      self:SetCommonTitle()
    elseif self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[index + 1] then
      self.Title1:SetSubtitle(self.titleConf.subtitle[index + 1].subtitle)
    end
  end
end

function UMG_FurnitureCreation_C:RefreshByTabId()
  if not self.CurTabId then
    return
  end
  local FurnitureDataList = self:GetFurnitureListByTabId(self.CurTabId)
  local DataList = {}
  local ding_map = self.BuildListRsp and self.BuildListRsp.ding_map or {}
  local home_map = self.BuildListRsp and self.BuildListRsp.home_map or {}
  local self_map = self.BuildListRsp and self.BuildListRsp.self_map or {}
  local HomeModuleData = HomeIndoorSandbox.Module:GetData()
  
  local function RefreshSelfCreateCondStatus(Data)
    if Data then
      local id = Data.FurnitureItemConf.id
      if not Data.ExchangeConf then
        Data.ExchangeConf = DataConfigManager:GetExchangeConf(id)
      end
      local ExchangeConf = Data.ExchangeConf
      Data.BagItemConf = DataConfigManager:GetBagItemConf(id)
      Data.ScrollingCreateLocked = not self_map[id]
      Data.ScrollingCreateCondLocked = not Data.ExchangeConf or not (AlchemyUtils.GetCanExchangeNum(Data.ExchangeConf) > 0)
      Data.ScrollingSpecialGray = Data.ScrollingCreateLocked and -1 ~= self.CurTabId
      Data.ScrollingRoomLevelLocked = ExchangeConf and not (ExchangeConf.furniture_build_level <= self.SelfRoomLevel)
      Data.ScrollingRoomLevel = Data.ScrollingRoomLevelLocked and ExchangeConf.furniture_build_level or 0
      Data.SortWeight = 0
      local bRoomLevelUnLocked = not Data.ScrollingRoomLevelLocked
      local bMaterialUnLocked = not Data.ScrollingCreateCondLocked
      local bBlueprintUnLocked = not Data.ScrollingCreateLocked
      if bRoomLevelUnLocked then
        Data.SortWeight = Data.SortWeight | 4
      end
      if bMaterialUnLocked then
        Data.SortWeight = Data.SortWeight | 2
      end
      if not bBlueprintUnLocked then
        Data.SortWeight = Data.SortWeight | 1
      end
    end
  end
  
  local bDoFilter, SecondTabFilterToShow = self:GetFilterTable(self.CurTabId)
  self.DisplayNumInTab = {}
  for i, v in ipairs(FurnitureDataList) do
    v.ScrollingCreateLocked = nil
    v.ScrollingCreateCondLocked = nil
    v.RefreshSelfCreateCondStatus = RefreshSelfCreateCondStatus
    RefreshSelfCreateCondStatus(v)
    local bEnableBuild = v.ExchangeConf
    if bEnableBuild and HomeIndoorSandbox:InOtherHomeIndoor() and not v.ExchangeConf.Ban_Other_Home_Build then
      bEnableBuild = false
    end
    local tabId = v.FurnitureItemConf and v.FurnitureItemConf.classification
    local firstTabId = HomeModuleData:GetFirstTabId(tabId)
    local bFilterToShow = not bDoFilter
    if bDoFilter and bEnableBuild then
      bFilterToShow = SecondTabFilterToShow[tabId]
      if not bFilterToShow and firstTabId then
        bFilterToShow = SecondTabFilterToShow[firstTabId]
      end
    end
    if bEnableBuild and (-1 == self.CurTabId or home_map[v.FurnitureItemConf.id]) then
      if tabId and firstTabId then
        if self.DisplayNumInTab[tabId] == nil then
          self.DisplayNumInTab[tabId] = 0
        end
        if self.DisplayNumInTab[firstTabId] == nil then
          self.DisplayNumInTab[firstTabId] = 0
        end
        self.DisplayNumInTab[tabId] = self.DisplayNumInTab[tabId] + 1
        if firstTabId ~= tabId then
          self.DisplayNumInTab[firstTabId] = self.DisplayNumInTab[firstTabId] + 1
        end
      end
      if bFilterToShow then
        table.insert(DataList, v)
      end
    end
  end
  
  local function SortById(a, b)
    if a.ScrollingRoomLevel ~= b.ScrollingRoomLevel then
      if self.ComboSequenceUp then
        return a.ScrollingRoomLevel < b.ScrollingRoomLevel
      else
        return b.ScrollingRoomLevel < a.ScrollingRoomLevel
      end
    end
    if a.BagItemConf.sort_id ~= b.BagItemConf.sort_id then
      if self.ComboSequenceUp then
        return a.BagItemConf.sort_id < b.BagItemConf.sort_id
      else
        return b.BagItemConf.sort_id < a.BagItemConf.sort_id
      end
    elseif self.ComboSequenceUp then
      return a.FurnitureItemConf.id < b.FurnitureItemConf.id
    else
      return b.FurnitureItemConf.id < a.FurnitureItemConf.id
    end
  end
  
  local function SortByQuality(a, b)
    if a.BagItemConf.item_quality ~= b.BagItemConf.item_quality then
      if self.ComboSequenceUp then
        return b.BagItemConf.item_quality < a.BagItemConf.item_quality
      else
        return a.BagItemConf.item_quality < b.BagItemConf.item_quality
      end
    else
      return SortById(a, b)
    end
  end
  
  local SorterByBranch = SortById
  local SortInfo = self.SortList[self.SelectedComboIndex]
  if SortInfo then
    local sequence = SortInfo.sequence
    if Enum.Sequence.SEQUENCE_QUALITY_DOWN == sequence then
      SorterByBranch = SortByQuality
    end
  end
  
  local function Sorter(a, b)
    if a.SortWeight ~= b.SortWeight then
      if self.ComboSequenceUp then
        return b.SortWeight < a.SortWeight
      else
        return a.SortWeight < b.SortWeight
      end
    end
    return SorterByBranch(a, b)
  end
  
  table.sort(DataList, Sorter)
  local DesiredSelectIndex = 0
  for i, v in pairs(DataList) do
    Log.Debug("\227\128\144\229\174\182\229\133\183\227\128\145", v.FurnitureItemConf.name, "\230\152\175\229\144\166\232\167\163\233\148\129:", not v.ScrollingCreateLocked, "\230\152\175\229\144\166\230\137\147\233\128\160\230\157\161\228\187\182\232\190\190\230\136\144:", not v.ScrollingCreateCondLocked, "\230\152\175\229\144\166\233\166\150\230\172\161\230\137\147\233\128\160\239\188\154", not home_map[v.FurnitureItemConf.id])
    if v == self.PerformFurnitureData then
      DesiredSelectIndex = i - 1
    end
  end
  self.SeedList:ClearSelection()
  self.SeedList:InitList(DataList)
  self.SeedList:SelectItemByIndex(DesiredSelectIndex)
  if 0 == #DataList then
    self.SelectedFurnitureData = nil
    self.FurnitureManager:ToggleFurnitureView(nil)
    if self.Switcher then
      self.Switcher:SetActiveWidgetIndex(1)
    end
    self.FurniturePreview:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:DispatchEvent(HomeIndoorSandbox.Event.OnReqToggleFurnitureBoxShadow, false)
  else
    if self.Switcher then
      self.Switcher:SetActiveWidgetIndex(0)
    end
    self.FurniturePreview:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:DispatchEvent(HomeIndoorSandbox.Event.OnReqToggleFurnitureBoxShadow, true)
  end
  if -1 == self.CurTabId then
    self.ComboBox_White:ShowOrHideBtnLeft(false, true)
  else
    self.ComboBox_White:ShowOrHideBtnLeft(true, false)
  end
  local bDoFilter = self:GetFilterTable(self.CurTabId)
  if bDoFilter then
    self.ComboBox_White.ScreeningBtn:ChangeIconSelectState(2)
  else
    self.ComboBox_White.ScreeningBtn:ChangeIconSelectState(1)
  end
end

function UMG_FurnitureCreation_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_FurnitureCreation_C:OnFurnitureItemClicked(FurnitureData)
  local bModelChanged = self.SelectedFurnitureData ~= FurnitureData
  if bModelChanged then
    self.SelectedFurnitureData = FurnitureData
  end
  self.SelectedFurnitureData = FurnitureData
  Log.Debug("\229\174\182\229\133\183\233\128\137\228\184\173\229\136\183\230\150\176\239\188\154", self.SelectedFurnitureData.FurnitureItemConf.name, self.SelectedFurnitureData.FurnitureItemConf.id)
  self:OnRefreshContent()
  if bModelChanged then
    self:TryRefreshModel(true)
  end
end

function UMG_FurnitureCreation_C:OnRefreshContent()
  Log.Debug("\229\174\182\229\133\183\229\134\133\229\174\185\229\136\183\230\150\176\239\188\154", self.SelectedFurnitureData.FurnitureItemConf.name)
  self.Text_Title_1:SetText(self.SelectedFurnitureData.FurnitureItemConf.name)
  local ItemConf = DataConfigManager:GetBagItemConf(self.SelectedFurnitureData.FurnitureItemConf.id)
  self.Text_Describe:SetText(ItemConf and ItemConf.description or "")
  local HasItem = self.SelectedFurnitureData.BagItem
  self.Lock:SetVisibility(HasItem and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
  local ExchangeConf = DataConfigManager:GetExchangeConf(ItemConf and ItemConf.id)
  local IconPath = ""
  local bCanCreate = ExchangeConf and AlchemyUtils.GetItemCanExchangeNum(ExchangeConf) > 0
  if ExchangeConf then
    local Type = ExchangeConf.cost_item[1].cost_goods_type
    if Type == Enum.GoodsType.GT_BAGITEM then
      local CostItem = DataConfigManager:GetBagItemConf(ExchangeConf.cost_item[1].cost_goods_id[1])
      if CostItem then
        IconPath = CostItem.icon
      end
    elseif Type == Enum.GoodsType.GT_VITEM then
      local CostItem = DataConfigManager:GetVisualItemConf(ExchangeConf.cost_item[1].cost_goods_id[1])
      if CostItem then
        IconPath = CostItem.iconPath
      end
    end
  end
  local bCanCreateThisRoomLevel = ExchangeConf and ExchangeConf.furniture_build_level <= self.SelfRoomLevel
  local ding_map = self.BuildListRsp and self.BuildListRsp.ding_map or {}
  local home_map = self.BuildListRsp and self.BuildListRsp.home_map or {}
  local bLocked = not home_map[ItemConf.id] and (-1 ~= self.CurTabId or not ding_map[ItemConf.id])
  if false then
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.NRCSwitcher_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.NRCSwitcher_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local BagItemNum = self.SelectedFurnitureData.BagItem and self.SelectedFurnitureData.BagItem.num or 0
    local ItemNum = ItemConf and HomeIndoorSandbox.Server.WorldData:GetFurnitureNumByConfigId(ItemConf.id) or 0
    self.Text_TimeRemaining_1:SetText(tostring(BagItemNum + ItemNum))
  end
  if not self.BuildListRsp.self_map[ItemConf.id] then
    self.Text_Conditions:SetText(LuaText.Furniture_build_text_1)
  else
    self.Text_Conditions:SetText("")
  end
  self.bCanCreateThis = bCanCreate
  self.bLockedThis = bLocked
  self.bCanCreateThisRoomLevelThis = bCanCreateThisRoomLevel
  if bLocked or not bCanCreate then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self.Btn3:SetClickAble(true)
    self.Btn3:SetTitleTextAndIcon(nil, "")
    if not bLocked then
      self.Btn3.Quantity_1:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.Btn3:SetTitleTextAndIcon(IconPath, ExchangeConf.cost_item[1].cost_goods_num)
      self.Btn3.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
      self.Btn3.Title_1:SetText(LuaText.furniture_build_button)
      self.Btn3:SetShowLockIcon(false)
    else
      self.Btn3.Quantity_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.Btn3.Title_1:SetText(LuaText.furniture_build_button)
      self.Btn3:SetShowLockIcon(true)
    end
  elseif not self.bCanCreateThisRoomLevelThis then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self.Btn3:SetClickAble(true)
    self.Btn3:SetTitleTextAndIcon(IconPath, ExchangeConf.cost_item[1].cost_goods_num)
    self.Btn3.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE0FF"))
    self.Btn3:SetShowLockIcon(false)
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
    self.Btn5:SetTitleTextAndIcon(IconPath, ExchangeConf.cost_item[1].cost_goods_num)
    self.Btn5.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE0FF"))
  end
  if not bCanCreateThisRoomLevel then
    local RoomConf = ExchangeConf and DataConfigManager:GetRoomConf(ExchangeConf.furniture_build_level)
    local RoomName = RoomConf.name or ""
    local Display = string.format(LuaText.furniture_home_level_low, RoomName)
    self.Text_Conditions:SetText(Display)
  end
  if self.SelectedFurnitureData then
    local Config = self.SelectedFurnitureData.FurnitureItemConf or self.SelectedFurnitureData.InteriorFinishConf
    self.SumNum:SetText(string.format("%d", Config.comfort))
  else
    self.SumNum:SetText("0")
  end
end

function UMG_FurnitureCreation_C:InternalRefreshModel()
  if not self.SelectedFurnitureData or not self.SelectedFurnitureData.FurnitureItemConf then
    self.FurnitureManager:ToggleFurnitureView(nil)
    return
  end
  self.FurnitureManager:ToggleFurnitureView(self.SelectedFurnitureData.FurnitureItemConf)
end

function UMG_FurnitureCreation_C:LuaOnTouchStarted(Finger, Pos)
  self.StartTouchedPos = Pos
  self.ElapsedMoveInput = nil
  self.ElapsedPitchInput = nil
  self.FurnitureManager:OnTouchStart()
end

function UMG_FurnitureCreation_C:LuaOnTouchMoved(Finger, Dir)
  if not self.ElapsedMoveInput then
    self.ElapsedMoveInput = Dir.X
  else
    self.ElapsedMoveInput = self.ElapsedMoveInput + Dir.X
  end
  if not self.ElapsedPitchInput then
    self.ElapsedPitchInput = Dir.Y
  else
    self.ElapsedPitchInput = self.ElapsedPitchInput + Dir.Y
  end
end

function UMG_FurnitureCreation_C:LuaOnTouchEnded(Finger)
  self.FurnitureManager:OnTouchEnd()
end

function UMG_FurnitureCreation_C:OnTick(dt)
  if self.ElapsedMoveInput then
    local MoveInput = self.ElapsedMoveInput
    local z = MoveInput * dt
    local r = 5 / (REAL_FURNITURE_ROTATE_SCALAR or 1)
    local a = 180 * z / (math.pi * r)
    self.ElapsedMoveInput = nil
    self.FurnitureManager:RotateFurniture(-a)
  end
end

function UMG_FurnitureCreation_C:GetSortList()
  local conf = _G.DataConfigManager:GetItemLableTypeConf(1012)
  local sortList = conf and conf.sequence or {
    Enum.Sequence.SEQUENCE_DEFAULT,
    Enum.Sequence.SEQUENCE_QUALITY_DOWN
  }
  local list = {}
  for i = 1, #sortList do
    local sortInfo = {}
    local sortId = sortList[i]
    local name = _G.DataConfigManager:GetBagItemSequence(sortId + 1).sequence_desc
    sortInfo.text = name
    sortInfo.sequence = sortId
    table.insert(list, sortInfo)
    Log.Debug("\229\174\182\229\133\183\230\142\146\229\186\143\229\136\151\232\161\168\239\188\154", name, sortId)
  end
  return list
end

function UMG_FurnitureCreation_C:OnSortItemChanged(Index)
  Log.Debug("\229\174\182\229\133\183\230\142\146\229\186\143\233\128\137\233\161\185\230\148\185\229\143\152\239\188\154", Index)
  self.SelectedComboIndex = Index
  self:RefreshByTabId()
end

function UMG_FurnitureCreation_C:OnToggleSequence()
  Log.Debug("\229\174\182\229\133\183\230\142\146\229\186\143\233\161\186\229\186\143\231\191\187\232\189\172\239\188\154", self.ComboSequenceUp)
  self.ComboSequenceUp = not self.ComboSequenceUp
  if not self.ComboSequenceUp then
    self.ComboBox_White.SortingBtn:SetRenderScale(UE4.FVector2D(-1, 1))
  else
    self.ComboBox_White.SortingBtn:SetRenderScale(UE4.FVector2D(-1, -1))
  end
  self:RefreshByTabId()
end

function UMG_FurnitureCreation_C:InitComboBox()
  self.SelectedComboIndex = 1
  self.ComboSequenceUp = true
  local SortList = self:GetSortList()
  self.SortList = SortList
  local DropDownListInfo = {}
  for i = 1, #SortList do
    table.insert(DropDownListInfo, {
      ComType = CommonBtnEnum.ComboBoxType.FurnitureCreation,
      name = SortList[i].text,
      sortList = SortList,
      isHideRedDot = true
    })
  end
  self:SetCommonComboBoxInfo(self.ComboBox_White, DropDownListInfo, self.SelectedComboIndex, SortList[self.SelectedComboIndex].text)
  self.ComboBox_White:ShowOrHideBtnLeft(false, true)
  self.ComboBox_White.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ComboBox_White.RedDot:SetupKey(0)
  self.ComboBox_White.OnPopupVisibilityChanged = FPartial(self.OnPopupVisibilityChanged, self)
  self:OnPopupVisibilityChanged(false)
end

function UMG_FurnitureCreation_C:OnPopupVisibilityChanged(bShow)
  Log.Debug("UMG_FurnitureCreation_C:OnPopupVisibilityChanged", bShow)
  self.TouchEmptyHideComboBox:NotifyTouched()
end

function UMG_FurnitureCreation_C:OnReqCloseSortPopup()
  Log.Debug("UMG_FurnitureCreation_C:OnReqCloseSortPopup")
  self.ComboBox_White:SetPopupVisible(false)
end

function UMG_FurnitureCreation_C:SetCommonComboBoxInfo(ComboBox, DropDownListInfo, DropDownListIndex, DropDownListText, ComboBoxText, ComboBoxIcon)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if DropDownListInfo then
    CommonDropDownListData.DropDownListInfo = DropDownListInfo
  end
  CommonDropDownListData.ComType = CommonBtnEnum.ComboBoxType.FurnitureCreation
  if DropDownListIndex then
    CommonDropDownListData.DropDownListIndex = DropDownListIndex
  end
  if DropDownListText then
    CommonDropDownListData.DropDownListText = DropDownListText
  end
  if ComboBoxText then
    CommonDropDownListData.DropDownListText = ComboBoxText
  end
  if ComboBoxIcon then
    CommonDropDownListData.DropDownListIcon = ComboBoxIcon
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_LeftHandler = self.OpenFilterPanel
  CommonDropDownListData.Btn_RightHandler = self.OnToggleSequence
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_FurnitureCreation_C:InitMoney()
  local Types = {}
  local Data = {
    moneyType = Enum.VisualItem.VI_FURNITURE_COIN,
    sum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(Enum.VisualItem.VI_FURNITURE_COIN),
    IsShowBuyIcon = false
  }
  table.insert(Types, Data)
  table.sort(Types, function(a, b)
    return a.moneyType < b.moneyType
  end)
  self.MoneyBtn:InitGridView(Types)
end

function UMG_FurnitureCreation_C:OnRspFurnitureCreationList(bSuccess, BuildListRsp)
  if not self.enableView then
    return
  end
  self.bPendingReqBuildList = false
  if self.RefreshTimer then
    DelayManager:CancelDelayById(self.RefreshTimer)
    self.RefreshTimer = nil
  end
  
  local function WaitForRequest()
    self.RefreshTimer = _G.DelayManager:DelaySeconds(1, function()
      if not self.enableView then
        return
      end
      HomeIndoorSandbox.Server:ReqFurnitureCreationList(FPartial(self.OnRspFurnitureCreationList, self))
    end)
  end
  
  if bSuccess then
    if self:IfNeedRefresh(BuildListRsp) then
      HomeIndoorSandbox:Ensure(false, "server logic error, update refresh time", BuildListRsp.next_update_timestamp, "current", ZoneServer:GetServerTime())
      WaitForRequest()
      return
    end
    self.BuildListRsp = BuildListRsp
    self:InitRefreshTime()
    if -1 == self.CurTabId then
      self:RefreshByTabId()
    end
  else
    HomeIndoorSandbox:Ensure(false, "request furniture build list failed!")
    WaitForRequest()
  end
end

function UMG_FurnitureCreation_C:IfNeedRefresh(BuildListRsp)
  local CurrTime = ZoneServer:GetServerTime()
  local NextRefresh = BuildListRsp and BuildListRsp.next_update_timestamp or CurrTime
  if 0 ~= NextRefresh and BuildListRsp and CurrTime >= NextRefresh then
    return true
  end
  return false
end

function UMG_FurnitureCreation_C:InitRefreshTime()
  self.RefreshTimer = nil
  if not self.enableView then
    return
  end
  if self.bPendingReqBuildList then
    return
  end
  local CurrTime = ZoneServer:GetServerTime()
  local NextRefresh = self.BuildListRsp and self.BuildListRsp.next_update_timestamp or CurrTime
  if 0 ~= NextRefresh and self.BuildListRsp and CurrTime >= NextRefresh then
    self.bPendingReqBuildList = true
    HomeIndoorSandbox.Server:ReqFurnitureCreationList(FPartial(self.OnRspFurnitureCreationList, self))
  end
  CurrTime = math.floor(CurrTime / 1000)
  NextRefresh = math.floor(NextRefresh / 1000)
  local RemainingSeconds = math.floor(os.difftime(NextRefresh, CurrTime))
  if RemainingSeconds < 0 then
    RemainingSeconds = 0
  end
  self.TimeRemaining:SetText(string.format("%s", self:GetTimeDisplayString(RemainingSeconds)))
  self.RefreshTimer = _G.DelayManager:DelaySeconds(1, FPartial(self.InitRefreshTime, self))
end

function UMG_FurnitureCreation_C:GetTimeDisplayString(Time)
  local Days = Time // 86400
  Time = Time - Days * 86400
  local Hours = Time // 3600
  Time = Time - Hours * 3600
  local Minus = Time // 60
  local Desc = ""
  if Days > 0 then
    Desc = Desc .. string.format(LuaText.room_expend_need_time_day, Days)
  end
  if Hours > 0 then
    Desc = Desc .. string.format(LuaText.room_expend_need_time_hour, Hours)
  end
  if Minus > 0 then
    Desc = Desc .. string.format(LuaText.room_expend_need_time_min, Minus)
  end
  if "" == Desc then
    Desc = string.format(LuaText.room_expend_need_time_min, 1)
  end
  return Desc
end

function UMG_FurnitureCreation_C:Init(BuildListRsp)
  self:InitComboBox()
  self:InitTabList()
  self:InitMoney()
  self:InitRefreshTime()
end

function UMG_FurnitureCreation_C:OpenFilterPanel()
  if not self.CurTabId then
    return
  end
  if _G.HomeModuleCmd then
    local cacheKey = tostring(self.CurTabId)
    if self.AllSecondTabFilterCache[cacheKey] == nil then
      self.AllSecondTabFilterCache[cacheKey] = {}
    end
    _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenFurnitureFilterPanel, self.AllSecondTabFilterCache[cacheKey], HomeEnum.FurnitureFilterMode.Craft, self.CurTabId, self.DisplayNumInTab)
  end
end

function UMG_FurnitureCreation_C:OnFilterUpdate()
  if not self.enableView then
    return
  end
  self:RefreshByTabId()
end

function UMG_FurnitureCreation_C:GetFilterTable(TabId)
  if not TabId then
    return false, {}
  end
  local SecondTabFilterToShow
  if TabId then
    local cacheKey = tostring(TabId)
    if self.AllSecondTabFilterCache[cacheKey] == nil then
      self.AllSecondTabFilterCache[cacheKey] = {}
    end
    SecondTabFilterToShow = self.AllSecondTabFilterCache[cacheKey]
  end
  local bDoFilter = SecondTabFilterToShow and next(SecondTabFilterToShow)
  return bDoFilter, SecondTabFilterToShow
end

return UMG_FurnitureCreation_C

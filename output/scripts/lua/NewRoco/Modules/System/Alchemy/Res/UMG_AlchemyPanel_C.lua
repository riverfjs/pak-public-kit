local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local BagModuleCmd = require("NewRoco.Modules.System.Bag.BagModuleCmd")
local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local CountDownHandler = require("NewRoco.Modules.System.Misc.CountDownHandler")
local UMG_AlchemyPanel_C = _G.NRCPanelBase:Extend("UMG_AlchemyPanel_C")

local function _SortExchangeFunc(a, b)
  local appearTimestampA = a.appear_time or math.maxinteger
  local appearTimestampB = b.appear_time or math.maxinteger
  if appearTimestampA ~= appearTimestampB then
    return appearTimestampA < appearTimestampB
  end
  local canExchangeA = a.canExchange and 1 or 0
  local canExchangeB = b.canExchange and 1 or 0
  if canExchangeA ~= canExchangeB then
    return canExchangeA > canExchangeB
  end
  local exchangeSortIdA = a.exchangeConf and a.exchangeConf.sort_id or math.maxinteger
  local exchangeSortIdB = b.exchangeConf and b.exchangeConf.sort_id or math.maxinteger
  if exchangeSortIdA ~= exchangeSortIdB then
    return exchangeSortIdA < exchangeSortIdB
  end
  if a.refreshType ~= b.refreshType then
    return a.refreshType > b.refreshType
  end
  local sortIdA = a.BagItemConf and a.BagItemConf.sort_id or 0
  local sortIdB = b.BagItemConf and b.BagItemConf.sort_id or 0
  return sortIdA < sortIdB
end

local function _SortExchangesFunc(a, b)
  local a1 = a.DataList[1]
  local b1 = b.DataList[1]
  return _SortExchangeFunc(a1, b1)
end

local function _SortRecipeFunc(a, b)
  local canExchangeA = a.canExchange and 1 or 0
  local canExchangeB = b.canExchange and 1 or 0
  if canExchangeA ~= canExchangeB then
    return canExchangeA > canExchangeB
  end
  local exchangeSortIdA = a.exchangeConf and a.exchangeConf.sort_id or math.maxinteger
  local exchangeSortIdB = b.exchangeConf and b.exchangeConf.sort_id or math.maxinteger
  if exchangeSortIdA ~= exchangeSortIdB then
    return exchangeSortIdA < exchangeSortIdB
  end
  return a.exchangeId < b.exchangeId
end

function UMG_AlchemyPanel_C:OnConstruct()
  self.currentExchangeItemCounterDown = CountDownHandler.CreateCountDownObjectByTimeFunction(self.GetCurrentExchangeLeftTime, self)
  self.currentExchangeItemCounterDown:BindCtrl(self.ContentText, self.FormatterExchangeLeftTime, self, self.OnExchangeLeftTimeChanged, self)
end

function UMG_AlchemyPanel_C:OnActive(action)
  _G.NRCProfilerLog:NRCPanelRequireRes(false, "UMG_AlchemyPanel_C")
  self:OnAddEventListener()
  self.current_index = 1
  self.MetallurgicalSwitcher:SetActiveWidgetIndex(0)
  self.exchangeGroupInfoTable = {}
  self.unlockExchangeData = {}
  local tabDataList = {
    {
      index = 1,
      normal_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__tabIcon1_png.img__tabIcon1_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__tabIcon1_select_png.img__tabIcon1_select_png'",
      exchange_type = _G.Enum.ExchangeUseType.EUT_MANUFACTURE_BASIC_COMPOUND,
      title = _G.LuaText.alchemy_basic_compound_title,
      titleIndex = 1
    },
    {
      index = 2,
      normal_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__jiangpaiIcon1_png.img__jiangpaiIcon1_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__jiangpaiIcon2_png.img__jiangpaiIcon2_png'",
      exchange_type = _G.Enum.ExchangeUseType.EUT_MANUFACTURE_PET_USE,
      title = _G.LuaText.alchemy_pet_item_title,
      titleIndex = 5
    },
    {
      index = 3,
      normal_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__tabIcon6_png.img__tabIcon6_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__tabIcon6_select_png.img__tabIcon6_select_png'",
      exchange_type = _G.Enum.ExchangeUseType.EUT_MANUFACTURE_SKILL_MACHINE,
      title = _G.LuaText.alchemy_skill_machine_title,
      titleIndex = 2
    },
    {
      index = 4,
      normal_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__tabIcon5_png.img__tabIcon5_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img__tabIcon5_select_png.img__tabIcon5_select_png'",
      exchange_type = _G.Enum.ExchangeUseType.EUT_MANUFACTURE_CONVERSE,
      title = _G.LuaText.alchemy_converse_title,
      titleIndex = 3
    }
  }
  local bEnableHomeFoodTab = not _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_ALCHEMY_PANEL_HOME)
  if bEnableHomeFoodTab then
    table.insert(tabDataList, {
      index = #tabDataList + 1,
      normal_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_CookingIcon_png.img_CookingIcon_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_CookingIcon_select_png.img_CookingIcon_select_png'",
      exchange_type = _G.Enum.ExchangeUseType.EUT_PROCESSING_PRODUCTS,
      title = _G.LuaText.plant_home_tab,
      titleIndex = 4
    })
  end
  self.panelDataList = tabDataList
  self.CloseBtn:SetStyle(1)
  local coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
  local moneyInfo = {}
  self.bIsScreening = false
  table.insert(moneyInfo, {
    moneyType = _G.Enum.VisualItem.VI_COIN,
    sum = coin_num,
    IsShowBuyIcon = false
  })
  self.MoneyBtn:InitGridView(moneyInfo)
  self.itemInsufficientText = _G.LuaText.alchemy_make_item_short
  self.coinInsufficientText = _G.LuaText.exchange_no_enough_currency
  self.timeLimitText = _G.LuaText.exchange_no_times_left
  self.makeItemText = _G.LuaText.alchemy_make_item
  self.UMG_CoinButton:SetClickAble(true)
  self.UMG_CoinButton:SetBtnText(self.makeItemText)
  self.UnselectedItemTip = _G.LuaText.Unselected_Item_Tips
  local vItemConf = _G.DataConfigManager:GetVisualItemConf(Enum.VisualItem.VI_FURNITURE_COIN, true)
  if vItemConf then
    self.Icon_1:SetPath(vItemConf.iconPath)
  end
  vItemConf = _G.DataConfigManager:GetVisualItemConf(Enum.VisualItem.VI_HOME_EXP, true)
  if vItemConf then
    self.Icon:SetPath(vItemConf.iconPath)
  end
  self.ExchangeValueCheckFailedTip_BI_PET_BALL = _G.LuaText.Error_Code_2285
  self.ExchangeValueCheckFailedTip_BI_OTHERS = _G.LuaText.Error_Code_2288
  self.NoUnlockFormulaText:SetText(_G.LuaText.exchange_no_unlock_formula)
  self.BuildNumHint:SetText(_G.LuaText.exchange_alchemy_num)
  self.isRefreshing = false
  self.isClosing = false
  self.finish = false
  self.normalMode = false
  self.action = action
  self.buildItems = {}
  self.selectedIndex = 0
  self.recipeIndex = 0
  self.exchangeId = 0
  self.exchangeConf = nil
  self.condition = nil
  self.basicCondition = nil
  self.lastBuildValue = -1
  self.firstSelectTab = true
  self.firstSelectItem = true
  self.MetallurgicalSwitcher:SetActiveWidgetIndex(0)
  self.BuildButtonPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SliderPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.FilterPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetCommonTitle()
  self:SetCommonComboBoxInfo(self.ComboBox, "\233\187\152\232\174\164\230\142\146\229\186\143")
  self:AlchemyItemChanged(0, 0, 0)
  local SliderInfo = {
    num1 = self.MinValue,
    num2 = self.MaxValue
  }
  local ProgressBarInfo = {
    num1 = self.MinValue,
    num2 = self.MaxValue
  }
  self:SetCommonAddSubtractInfo(self.SliderPanel, SliderInfo, ProgressBarInfo)
  self:ShowOpen()
  self:BindInputAction()
end

function UMG_AlchemyPanel_C:OnAlchemyPanelChanged(panel_index, reset)
  if self.firstSelectTab then
    self.firstSelectTab = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_AlchemyPanel_C:OnAlchemyPanelChanged")
  end
  if self.current_index ~= panel_index and reset then
    self.View_List:EndInertialScrolling()
    self.View_List:NRCScrollToStart()
    self.exchangeConf = nil
    self.exchangeId = 0
  end
  self.firstSelectItem = true
  if self.current_index ~= panel_index then
    self.condition = nil
  end
  self.current_index = panel_index
  local panelData = self.panelDataList[panel_index]
  self:RefreshCommonTitle(panelData and panelData.titleIndex)
  self.basicCondition = nil
  self:RefreshUI()
  self:SwitchToNormalPanel()
end

function UMG_AlchemyPanel_C:RefreshCommonTitle(titleIndex)
  if not titleIndex then
    return
  end
  if self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[titleIndex] then
    self.Title1:SetSubtitle(self.titleConf.subtitle[titleIndex].subtitle)
  end
end

function UMG_AlchemyPanel_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_AlchemyPanel_C:OnAnimationFinished(Animation)
  if Animation == self.open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  elseif Animation == self.close then
    if self.finish then
      if self.action then
        self.action:EndAction()
      end
      if self.module.TestOpen then
        self.module.TestOpen = false
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenPanelLobbyMain)
      end
      self:DoClose()
    end
  elseif Animation == self.ExchangeButtonPanel_Loop then
    self:PlayAnimation(self.ExchangeButtonPanel_Loop)
  end
end

function UMG_AlchemyPanel_C:OnDeactive()
  self:OnRemoveEventListener()
  self:UnBindInputAction()
end

function UMG_AlchemyPanel_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_NpcShop")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseNpcShopUI")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_AlchemyPanel_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseNpcShopUI")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_NpcShop")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_AlchemyPanel_C:OnPcClose()
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  self:OnClose()
end

function UMG_AlchemyPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClose)
  self:AddButtonListener(self.UMG_CoinButton.btnLevelUp, self.OnBtnBuildItemsClick)
  self:AddButtonListener(self.Exchange, self.ExchangeFormula)
  self:AddButtonListener(self.ReturnButton, self.ReturnToNormal)
  self:AddButtonListener(self.IconButton, self.ClickInfoIcon)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, _G.AlchemyModuleEvent.AlchemyItemChanged, self.AlchemyItemChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, DialogueModuleEvent.DialogueEnded, self.ForceClose)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.ForceClose)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, _G.AlchemyModuleEvent.AlchemyPanelChanged, self.OnAlchemyPanelChanged)
end

function UMG_AlchemyPanel_C:OnAddPressed()
  self:StopAnimation(self.Add_up)
  self:PlayAnimation(self.Add_press)
end

function UMG_AlchemyPanel_C:OnAddReleased()
  self:StopAnimation(self.Add_press)
  self:PlayAnimation(self.Add_up)
end

function UMG_AlchemyPanel_C:OnReducePressed()
  self:StopAnimation(self.Reduce_up)
  self:PlayAnimation(self.Reduce_press)
end

function UMG_AlchemyPanel_C:OnReduceReleased()
  self:StopAnimation(self.Reduce_press)
  self:PlayAnimation(self.Reduce_up)
end

function UMG_AlchemyPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnFilter, self.OnFilter)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.AlchemyModuleEvent.AlchemyItemChanged, self.AlchemyItemChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.ForceClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.ForceClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.AlchemyModuleEvent.AlchemyPanelChanged, self.OnAlchemyPanelChanged)
end

function UMG_AlchemyPanel_C:ExchangeFormula()
  local ActiveIndex = self.MetallurgicalSwitcher:GetActiveWidgetIndex()
  if 0 == ActiveIndex then
    if self.View_List and self.selectedIndex then
      _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_AlchemyPanel_C:ExchangeFormula")
      local exchangeItems = self.View_List:GetDataByIndex(self.selectedIndex).DataList
      local _, _, recipeIndex = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetAlchemyItem)
      local selectIndex = 0
      if recipeIndex > 0 then
        selectIndex = recipeIndex - 1
      end
      _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.OpenAlternativeFormula, exchangeItems, selectIndex)
    end
  else
    _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_AlchemyPanel_C:ExchangeFormula")
    self:SwitchToNormalPanel()
  end
end

function UMG_AlchemyPanel_C:SwitchToNormalPanel(immediate, FilterList)
  if immediate then
  else
    self:PlayAnimation(self.Change_Icon)
  end
  self.Switcher:SetActiveWidgetIndex(0)
  local ItemList = FilterList or self.buildItems
  if #ItemList > 0 then
    self.MetallurgicalSwitcher:SetActiveWidgetIndex(0)
    self.BuildButtonPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SliderPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.MetallurgicalSwitcher:SetActiveWidgetIndex(2)
    self.BuildButtonPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SliderPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.BtnSwitcher:SetActiveWidgetIndex(0)
  local SkipAudio = true
  self.SwitchToNormalItemChange = true
  self:AlchemyItemChanged(self.exchangeId, self.selectedIndex, self.recipeIndex, SkipAudio)
end

function UMG_AlchemyPanel_C:ReturnToNormal()
  self:SwitchToNormalPanel()
end

function UMG_AlchemyPanel_C:OnFilterButtonClick()
  local panelData = self.panelDataList[self.current_index]
  if panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_SKILL_MACHINE then
    local data = self:GetFilterData()
    if not _G.NRCModuleManager:GetModule("BagModule"):HasPanel("BagScreen") then
      _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, BagModuleEvent.OnFilter, self.OnFilter)
      _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, BagModuleEvent.OnBagScreenClose, self.OnBagScreenClose)
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, data, _G.DataConfigManager.ConfigTableId.SKILLMACHINE_FILTER_CONF, self.condition)
    end
  elseif panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_BASIC_COMPOUND then
    local data = self:GetFilterData()
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.OpenAlchemySort, data, _G.DataConfigManager.ConfigTableId.EXCHANGE_NORMAL_FILTER_CONF, self.basicCondition)
  end
end

function UMG_AlchemyPanel_C:OnFilter(FilterList, condition)
  self.condition = condition
  table.sort(FilterList, _SortExchangesFunc)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnFilter, self.OnFilter)
  self:AlchemyItemChanged(0, 0, 0)
  self.View_List:EndInertialScrolling()
  self.View_List:NRCScrollToStart()
  self:RefreshUI(FilterList)
  self:SwitchToNormalPanel(true, FilterList)
end

function UMG_AlchemyPanel_C:OnBagScreenClose()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnFilter, self.OnFilter)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnBagScreenClose, self.OnBagScreenClose)
end

function UMG_AlchemyPanel_C:SetCommonComboBoxInfo(ComboBox, ComboBoxText, ComboBoxIcon)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if ComboBoxText then
    CommonDropDownListData.DropDownListText = ComboBoxText
  end
  if ComboBoxIcon then
    CommonDropDownListData.DropDownListIcon = ComboBoxIcon
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_LeftHandler = self.OnFilterButtonClick
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_AlchemyPanel_C:SetCommonAddSubtractInfo(AddSubtract, SliderInfo, ProgressBarInfo, MultipleAddBtnText, MultipleSubtractBtnText, SelectNum)
  local CommonAddSubtractData = _G.NRCCommonAddSubtractData()
  if MultipleAddBtnText then
    CommonAddSubtractData.MultipleAddBtnText = MultipleAddBtnText
  end
  if MultipleSubtractBtnText then
    CommonAddSubtractData.MultipleSubtractBtnText = MultipleSubtractBtnText
  end
  CommonAddSubtractData.SliderInfo = SliderInfo
  CommonAddSubtractData.ProgressBarInfo = ProgressBarInfo
  CommonAddSubtractData.AddBtnHandler = self.OnBtnAddItemClick
  CommonAddSubtractData.SubtractBtnHandler = self.OnBtnDelItemClick
  CommonAddSubtractData.SliderHandler = self.OnSliderValueChanged
  CommonAddSubtractData.SelectNum = SelectNum
  CommonAddSubtractData.Call = self
  AddSubtract:SetPanelInfo(CommonAddSubtractData)
end

function UMG_AlchemyPanel_C:AlchemyItemChanged(exchangeId, index, recipeIndex, SkipAudio)
  Log.Debug("UMG_AlchemyPanel_C:AlchemyItemChanged", exchangeId)
  if not SkipAudio then
    if self.firstSelectItem then
      self.firstSelectItem = false
    else
      _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_AlchemyPanel_C:AlchemyItemChanged")
    end
  end
  if self.SwitchToNormalItemChange then
    self.SwitchToNormalItemChange = false
    return
  end
  self.exchangeId = exchangeId
  if -1 ~= index then
    self.selectedIndex = index
  end
  self.recipeIndex = recipeIndex
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.SetAlchemyItem, self.exchangeId, self.selectedIndex, self.recipeIndex)
  self.exchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchangeId, true)
  if self.exchangeConf then
    local remainExchangeTime = AlchemyUtils.GetRemainExchangeTimes(self.exchangeConf.exchange_time_limit_group, self.exchangeGroupInfoTable)
    self.canExchangeNum = AlchemyUtils.GetCanExchangeNum(self.exchangeConf, remainExchangeTime)
  end
  if self.buildItems[self.selectedIndex] and #self.buildItems[self.selectedIndex].DataList > 1 then
    self.ExchangeButtonPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ExchangeButtonPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local panelData = self.panelDataList[self.current_index]
  if panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_SKILL_MACHINE then
    local skillLearnList = {}
    if self.exchangeConf then
      skillLearnList = _G.BagModuleUtils.GetPetSkillLearnList(_G.DataConfigManager:GetBagItemConf(self.exchangeConf.get_item[1].get_goods_id))
    else
      skillLearnList = _G.BagModuleUtils.GetPetSkillLearnList()
    end
    self.List:InitGridView(skillLearnList)
  end
  self:SetupSlier()
  self:UpdateAll()
end

function UMG_AlchemyPanel_C:RequestUIDataUpdate()
  if self.isClosing then
    return
  end
  local req_unlock = _G.ProtoMessage:newZoneGetUnlockedExchangeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_GET_UNLOCKED_EXCHANGE_REQ, req_unlock, self, self.OnGetUnlockedExchangeRsp, true, true)
end

function UMG_AlchemyPanel_C:RefreshUI(newItems)
  if newItems then
    self:ShowRefreshUI(newItems)
  else
    self.buildItems = self:FilterExchangeByType(self.panelDataList[self.current_index].exchange_type)
    local items
    local panelData = self.panelDataList[self.current_index]
    if panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_SKILL_MACHINE then
      if self.condition then
        items = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterSkillStone, self.condition, self:GetFilterData())
      end
    elseif panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_BASIC_COMPOUND and self.basicCondition and self.basicCondition.FilterBasicCondition then
      items = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetFilterBasicList, self.basicCondition.FilterBasicCondition, self:GetFilterData())
    end
    self.buildItems = items and items or self.buildItems
    self.DelayHandler = _G.DelayManager:DelayFrames(2, self.ShowRefreshUI, self)
  end
end

function UMG_AlchemyPanel_C:ShowRefreshUI(newItems)
  self.View_List:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:RefreshExchangeList(newItems)
  self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  local panelData = self.panelDataList[self.current_index]
  if panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_SKILL_MACHINE then
    self.FilterPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.List:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.condition and (self.condition.FilterPetCondition and #self.condition.FilterPetCondition > 0 or self.condition.FilterDepartCondition and #self.condition.FilterDepartCondition > 0 or self.condition.FilterClassifyCondition and #self.condition.FilterClassifyCondition > 0) then
      if not self.bIsScreening then
        self.bIsScreening = true
        self.ComboBox.ScreeningBtn:ChangeIconSelectState()
      end
      self.ComboBox.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      if self.bIsScreening then
        self.bIsScreening = false
        self.ComboBox.ScreeningBtn:ChangeIconSelectState()
      end
      self.ComboBox.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_BASIC_COMPOUND then
    self.FilterPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.basicCondition and self.basicCondition.FilterBasicCondition and #self.basicCondition.FilterBasicCondition > 0 then
      self.ComboBox.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.ComboBox.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif panelData.exchange_type == _G.Enum.ExchangeUseType.EUT_PROCESSING_PRODUCTS then
    self.FilterPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
  else
    self.FilterPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
  local moneyInfo = {}
  table.insert(moneyInfo, {
    moneyType = _G.Enum.VisualItem.VI_COIN,
    sum = coin_num,
    IsShowBuyIcon = false
  })
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_AlchemyPanel_C:OnGetUnlockedExchangeRsp(rsp)
  if self.isClosing then
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.exchangeGroupInfoTable = {}
  self.unlockExchangeData = {}
  if 0 == rsp.ret_info.ret_code then
    for i, data in ipairs(rsp.exchange_list or {}) do
      local exchange_group_info = {}
      exchange_group_info.exchange_times = data.exchange_times
      exchange_group_info.next_refresh_time = data.next_refresh_time
      self.exchangeGroupInfoTable[data.exchange_group] = exchange_group_info
    end
    for _, data in ipairs(rsp.recipes and rsp.recipes.recipes or {}) do
      local unlock_exchange_data = {}
      unlock_exchange_data.exchange_id = data.exchange_id
      unlock_exchange_data.is_online_shared = data.is_online_shared
      table.insert(self.unlockExchangeData, unlock_exchange_data)
    end
  else
    Log.Error("\231\130\188\233\135\145\232\167\163\233\148\129\228\191\161\230\129\175\229\155\158\229\140\133\233\148\153\232\175\175: ", table.tostring(rsp))
  end
  self.TabList:SelectItemByIndex(math.max(self.current_index - 1, 0))
  local ActiveIndex = self.MetallurgicalSwitcher:GetActiveWidgetIndex()
  if 1 == ActiveIndex then
    self:SwitchToExchangeSelectionPanel()
  end
end

function UMG_AlchemyPanel_C:FilterExchangeByType(filterType)
  local datas = {}
  local svrTimeStamp = ActivityUtils.GetSvrTimestamp()
  local exchangeIdMap = {}
  for _, unlock_exchange_data in ipairs(self.unlockExchangeData) do
    local cfg = _G.DataConfigManager:GetExchangeConf(unlock_exchange_data.exchange_id, true)
    if cfg and cfg.use_type == filterType then
      local item = {}
      if not string.IsNilOrEmpty(cfg.disapper_time) then
        item.disappear_time = ActivityUtils.ToTimestamp(cfg.disapper_time)
        if svrTimeStamp > item.disappear_time then
          return
        end
      end
      if cfg.unlock_type == Enum.ExchangeFormulaUnlockType.EFUT_ACTIVITY then
        local activityCfg = _G.DataConfigManager:GetActivityConf(cfg.unlock_data, true)
        if activityCfg then
          item.appear_time = ActivityUtils.ToTimestamp(activityCfg.appear_time)
          if svrTimeStamp < item.appear_time then
            return
          end
        end
      end
      local get_item = cfg.get_item[1]
      item.exchangeId = cfg.id
      item.exchangeConf = cfg
      item.get_item = get_item
      item.is_online_shared = unlock_exchange_data.is_online_shared
      item.refreshType = 0
      local groupId = cfg.exchange_time_limit_group
      if 0 ~= groupId then
        local exchangeTimeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(groupId)
        if exchangeTimeLimitConf then
          item.refreshType = exchangeTimeLimitConf.refresh_reset_type
        end
      end
      if get_item.get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
        item.BagItemConf = _G.DataConfigManager:GetBagItemConf(get_item.get_goods_id)
      end
      item.canExchange = AlchemyUtils.GetCanExchange(cfg, self.exchangeGroupInfoTable)
      if exchangeIdMap[get_item.get_goods_id] == nil then
        exchangeIdMap[get_item.get_goods_id] = {}
      end
      table.insert(exchangeIdMap[get_item.get_goods_id], item)
    end
  end
  for _, exchange_datas in pairs(exchangeIdMap) do
    table.sort(exchange_datas, _SortRecipeFunc)
    if #exchange_datas > 0 then
      table.insert(datas, {DataList = exchange_datas})
    else
      Log.Error("\231\166\187\232\176\177\239\188\140\228\184\186\228\187\128\228\185\136\228\188\154\230\156\137\231\169\186\233\133\141\230\150\185")
    end
  end
  table.sort(datas, _SortExchangesFunc)
  return datas
end

function UMG_AlchemyPanel_C:RefreshExchangeList(newItems)
  newItems = newItems or self.buildItems
  self.View_List:InitList(newItems)
  self.TabList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local index = 0
  if self.exchangeConf then
    local get_good_id = self.exchangeConf.get_item[1].get_goods_id
    for i, item in ipairs(newItems) do
      if item.DataList[1].get_item.get_goods_id == get_good_id then
        index = i
        break
      end
    end
  else
  end
  if index and index > 0 then
    self.View_List:SelectItemByIndex(index - 1)
    local item = self.View_List:GetItemByIndex(index - 1)
  elseif #newItems > 0 then
    self.View_List:SelectItemByIndex(0)
  else
    self:AlchemyItemChanged(0, 0, 0)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, 0, 0)
  end
end

function UMG_AlchemyPanel_C:OnClose()
  if self:IsAnimationPlaying(self.Change_Icon) or self:IsAnimationPlaying(self.open) or self:IsAnimationPlaying(self.close) then
    return
  end
  self.finish = true
  self.isClosing = true
  self.normalMode = false
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_AlchemyPanel_C:OnClose")
  self:PlayAnimation(self.close)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CloseMaterialItems)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.ResetAlternateMaterials)
  if self.DelayHandler then
    _G.DelayManager:CancelDelay(self.DelayHandler)
    self.DelayHandler = nil
  end
end

function UMG_AlchemyPanel_C:ForceClose()
  self.finish = true
  self.isClosing = true
  self.normalMode = false
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CloseMaterialItems)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.ResetAlternateMaterials)
  if self.DelayHandler then
    _G.DelayManager:CancelDelay(self.DelayHandler)
    self.DelayHandler = nil
  end
  if self.action then
    self.action:EndAction()
  end
  if self.module and self.module.TestOpen then
    self.module.TestOpen = false
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenPanelLobbyMain)
  end
  self:DoClose()
end

function UMG_AlchemyPanel_C:SetupSlier()
  local minValue = 0
  local maxValue = 0
  if self.exchangeConf then
    minValue = math.max(1, self.exchangeConf.exchange_time_lower_limit)
    maxValue = math.min(self.canExchangeNum, self.exchangeConf.exchange_time_upper_limit)
  end
  local newMaxValue = maxValue
  local newMinValue = minValue
  if 0 == maxValue then
    newMaxValue = 1
    newMinValue = 0
  end
  self.MaxValue = newMaxValue
  self.MinValue = newMinValue
  self.SliderPanel:SetSliderStepSize(1)
  self.SliderPanel:SetSliderMinValue(newMinValue)
  self.SliderPanel:SetSliderMaxValue(newMaxValue)
  if 0 == maxValue then
    self.SliderPanel:SetSliderLocked(true)
    self:SetSliderNum(0)
  else
    self.SliderPanel:SetSliderLocked(false)
    self:SetSliderNum(1)
  end
  self.SliderPanel.Digital:SetText(newMinValue)
  self.SliderPanel.Digital_1:SetText(newMaxValue)
end

function UMG_AlchemyPanel_C:SetSliderNum(value)
  self.SliderPanel:SetSliderValue(value)
  self.lastBuildValue = value
end

function UMG_AlchemyPanel_C:GetItemCount(_itemId, _itemType)
  if _itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local itemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, _itemId)
    if itemData then
      return itemData.num or 0
    end
    return 0
  elseif _itemType == _G.Enum.GoodsType.GT_VITEM then
    local VItemNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(16)
    return VItemNum
  end
end

function UMG_AlchemyPanel_C:ShowClose()
  self.normalMode = false
  self:StopAllAnimations()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.finish = false
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_NpcShop")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_AlchemyPanel_C:ShowOpen()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.normalMode = true
  self.canExchangeNum = 0
  self.View_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TabList:InitGridView(self.panelDataList)
  self.TabList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:StopAllAnimations()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.open)
  self:PlayAnimation(self.ExchangeButtonPanel_Loop)
  self:RequestUIDataUpdate()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_NpcShop")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
end

function UMG_AlchemyPanel_C:OnBtnBuildItemsClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_ALCHEMY_PANEL, true)
  if isBan then
    return
  end
  if self:IsAnimationPlaying(self.Change_Icon) or self:IsAnimationPlaying(self.open) or self:IsAnimationPlaying(self.close) then
    return
  end
  if 0 == self.exchangeId then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.UnselectedItemTip)
    return
  end
  local exchangeCfg = self.exchangeConf
  if exchangeCfg and not string.IsNilOrEmpty(exchangeCfg.disapper_time) and ActivityUtils.GetSvrTimestamp() >= ActivityUtils.ToTimestamp(exchangeCfg.disapper_time) then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.ERR_ZONE_EXCHANGE_IS_DISAPPER)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.DisableClick)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_CampingBuild_Info_C:OnBtnBuildItemsClick")
  local exchangeId = self.exchangeId
  local num = math.floor(self.SliderPanel:GetSliderValue())
  local costItemList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetCostMaterialItems, exchangeId, num)
  local bagModuleData = _G.NRCModuleManager:GetModule("BagModule"):GetData("BagModuleData")
  if bagModuleData and self.exchangeConf then
    local netIncomeMap = {}
    local netSingleItemIncomeMap = {}
    for i, get_item in ipairs(self.exchangeConf.get_item or {}) do
      local GoodsConf = _G.DataConfigManager:GetBagItemConf(get_item.get_goods_id, true)
      if GoodsConf then
        if not netIncomeMap[GoodsConf.type] then
          netIncomeMap[GoodsConf.type] = 0
        end
        netIncomeMap[GoodsConf.type] = netIncomeMap[GoodsConf.type] + get_item.get_goods_num
        if not netSingleItemIncomeMap[GoodsConf.id] then
          netSingleItemIncomeMap[GoodsConf.id] = 0
        end
        netSingleItemIncomeMap[GoodsConf.id] = netSingleItemIncomeMap[GoodsConf.id] + get_item.get_goods_num
      end
    end
    for i, cost_item in ipairs(costItemList or {}) do
      local GoodsConf = _G.DataConfigManager:GetBagItemConf(cost_item.goods_id, true)
      if GoodsConf then
        if not netIncomeMap[GoodsConf.type] then
          netIncomeMap[GoodsConf.type] = 0
        end
        netIncomeMap[GoodsConf.type] = netIncomeMap[GoodsConf.type] - cost_item.goods_num
        if not netSingleItemIncomeMap[GoodsConf.id] then
          netSingleItemIncomeMap[GoodsConf.id] = 0
        end
        netSingleItemIncomeMap[GoodsConf.id] = netSingleItemIncomeMap[GoodsConf.id] - cost_item.goods_num
      end
    end
    for type, income in pairs(netIncomeMap) do
      local TypeConf = _G.DataConfigManager:GetBagItemTypeConf(type)
      local type_number_limit = TypeConf and TypeConf.type_number_limit
      if type_number_limit and 0 ~= type_number_limit then
        local bagTypeNum = bagModuleData:GetBagItemNumByType(type)
        if income > 0 and type_number_limit < bagTypeNum + income * num then
          if type == Enum.BagItemType.BI_PET_BALL then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.ExchangeValueCheckFailedTip_BI_PET_BALL)
          else
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.ExchangeValueCheckFailedTip_BI_OTHERS)
          end
          return
        end
      end
    end
    for id, income in pairs(netSingleItemIncomeMap) do
      local GoodsConf = _G.DataConfigManager:GetBagItemConf(id)
      if GoodsConf and GoodsConf.type then
        local TypeConf = _G.DataConfigManager:GetBagItemTypeConf(GoodsConf.type)
        local item_number_limit = TypeConf and TypeConf.single_item_limit_max
        if item_number_limit and 0 ~= item_number_limit then
          local bagItem = bagModuleData:GetBagItemByID(id)
          if bagItem and bagItem.num and income > 0 and item_number_limit < bagItem.num + income * num then
            if GoodsConf.type == Enum.BagItemType.BI_PET_BALL then
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.ExchangeValueCheckFailedTip_BI_PET_BALL)
            else
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.ExchangeValueCheckFailedTip_BI_OTHERS)
            end
            return
          end
        end
      end
    end
  end
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RequestForExchange, exchangeId, num, costItemList)
end

function UMG_AlchemyPanel_C:OnBtnAddItemClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_CampingBuild_Info_C:OnBtnAddItemClick")
  self:ChangeBuildTimes(true)
end

function UMG_AlchemyPanel_C:OnBtnDelItemClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401008, "UMG_CampingBuild_Info_C:OnBtnDelItemClick")
  self:ChangeBuildTimes(false)
end

function UMG_AlchemyPanel_C:OnSliderValueChanged()
  if 0 == self.SliderPanel:GetSliderMinValue() then
    self:SetSliderNum(0)
    return
  end
  Log.Debug("UMG_CampingBuild_Info_C:OnSliderValueChanged")
  self:SetupAddOrDecBtnState()
  self:SetupBuildNumText()
  self:UpdateScheduleBar()
  local curValue = math.floor(self.SliderPanel:GetSliderValue())
  if self.lastBuildValue ~= curValue then
    self.lastBuildValue = curValue
    _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_CampingBuild_Info_C:OnBtnDelItemClick")
  end
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.exchangeId, curValue)
end

function UMG_AlchemyPanel_C:ChangeBuildTimes(_isAddItem)
  Log.Debug("UMG_CampingBuild_Info_C:ChangeBuildTimes")
  local curValue = self.SliderPanel:GetSliderValue()
  local minValue = self.SliderPanel:GetSliderMinValue()
  local maxValue = self.SliderPanel:GetSliderMaxValue()
  if _isAddItem then
    curValue = curValue + 1
  else
    curValue = curValue - 1
  end
  curValue = math.clamp(curValue, minValue, maxValue)
  curValue = math.floor(curValue)
  self:SetSliderNum(curValue)
  self:UpdateAll()
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.exchangeId, curValue)
end

function UMG_AlchemyPanel_C:UpdateAll()
  self:SetupAddOrDecBtnState()
  self:SetupBuildNumText()
  self:UpdateButton()
  self:UpdateScheduleBar()
  self:UpdateInfoPanel()
end

function UMG_AlchemyPanel_C:UpdateScheduleBar()
  local minValue = self.SliderPanel:GetSliderMinValue()
  local maxValue = self.SliderPanel:GetSliderMaxValue()
  local currentValue = self.SliderPanel:GetSliderValue()
  if 0 == maxValue - minValue then
    if currentValue > 0 then
      self.SliderPanel:SetProgressBarPercent(1)
    else
      self.SliderPanel:SetProgressBarPercent(0)
    end
  else
    self.SliderPanel:SetProgressBarPercent((self.SliderPanel:GetSliderValue() - self.SliderPanel:GetSliderMinValue()) / (self.SliderPanel:GetSliderMaxValue() - self.SliderPanel:GetSliderMinValue()))
  end
end

function UMG_AlchemyPanel_C:UpdateInfoPanel()
  local get_items = self.exchangeConf and self.exchangeConf.get_item
  local get_item = get_items and get_items[1]
  if not get_item then
    return
  end
  local itemCfg
  local itemName = ""
  local itemDesc = ""
  if get_item.get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
    itemCfg = _G.DataConfigManager:GetBagItemConf(get_item.get_goods_id)
    if itemCfg then
      itemName = itemCfg.name
      itemDesc = itemCfg.description
    end
  elseif get_item.get_goods_type == _G.Enum.GoodsType.GT_VITEM then
    itemCfg = _G.DataConfigManager:GetVisualItemConf(get_item.get_goods_id)
    if itemCfg then
      itemName = itemCfg.displayName
      itemDesc = itemCfg.discription
    end
  end
  if not itemCfg then
    Log.Error("\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168", get_item.get_goods_id)
    self.InfoPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.InfoPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UMG_AlchemyItem:UpdateInfoIcon(get_item)
  self.TxtName:SetText(itemName)
  self.Desc:SetText(itemDesc)
  self.currentExchangeItemDisappearTimestamp = ActivityUtils.ToTimestamp(self.exchangeConf.disapper_time)
  self.currentExchangeItemCounterDown:ForceRefreshLeftTime()
  local panelData = self.panelDataList[self.current_index]
  local exchange_type = panelData and panelData.exchange_type
  if exchange_type == _G.Enum.ExchangeUseType.EUT_MANUFACTURE_SKILL_MACHINE and get_item.get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
    self.SkillPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    local skillMachineId = itemCfg.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineId)
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    local damage_value = "-"
    if skillConf.damage_type ~= _G.Enum.DamageType.DT_NONE then
      damage_value = tostring(skillConf.dam_para[1])
    end
    local AttrData = {}
    table.insert(AttrData, {
      Path = typeDic.tips_res,
      Name = damage_value
    })
    self.Attr:InitGridView(AttrData)
    local text, iconPath = BattleUtils.GetSkillTypePath(skillConf.Skill_Type, skillConf.damage_type)
    self.SkillTypeIcon:SetPath(iconPath)
    self.SkillTypeText:SetText(text)
    self.SkillNengNum:SetText(skillConf.energy_cost[1])
  elseif exchange_type == _G.Enum.ExchangeUseType.EUT_PROCESSING_PRODUCTS then
    self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local homePetFeedConf = _G.DataConfigManager:GetHomePetFeedConf(get_item.get_goods_id, true)
    if homePetFeedConf and homePetFeedConf.need_time and homePetFeedConf.furniture_coin_num and homePetFeedConf.home_exp_num then
      local timeStr = self:GetCostTimeStr(homePetFeedConf.need_time * 60)
      self.GrowthTextTime:SetText(timeStr)
      self.OutputText_1:SetText(homePetFeedConf.furniture_coin_num)
      self.OutputText:SetText(homePetFeedConf.home_exp_num)
    end
  else
    self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_AlchemyPanel_C:SetupAddOrDecBtnState()
  local curValue = self.SliderPanel:GetSliderValue()
  local minValue = self.SliderPanel:GetSliderMinValue()
  local maxValue = self.SliderPanel:GetSliderMaxValue()
  if 0 == self.SliderPanel:GetSliderMinValue() then
    self.SliderPanel:SetAddBtnIsEnabledNewStyle(false)
    self.SliderPanel:SetSubtractBtnIsEnabledNewStyle(false)
  else
    self.SliderPanel:SetAddBtnIsEnabledNewStyle(curValue ~= maxValue)
    self.SliderPanel:SetSubtractBtnIsEnabledNewStyle(curValue ~= minValue)
  end
end

function UMG_AlchemyPanel_C:SetupBuildNumText()
  if self.exchangeConf then
    self.BuildTimePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.BuildTimePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.exchangeConf == nil then
    self.BuildTimeBox:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BuildTimeText:SetText(string.format("%d", 0))
  elseif 0 == self.canExchangeNum then
    self.BuildTimeBox:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BuildTimeText:SetText(string.format("%d", 0))
  else
    self.BuildTimeBox:SetVisibility(UE4.ESlateVisibility.Visible)
    local curValue = math.floor(self.SliderPanel:GetSliderValue())
    self.BuildTimeText:SetText(string.format("%d", curValue))
  end
  local isShowSurplus = false
  if self.exchangeConf then
    local exchangeLimitId = self.exchangeConf.exchange_time_limit_group
    if exchangeLimitId and 0 ~= exchangeLimitId then
      local exchangeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(exchangeLimitId)
      if exchangeLimitConf then
        self.ImposeRestrictionsOn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.ImposeRestrictionsOn_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.ImposeRestrictionsOn:SetText(exchangeLimitConf.refresh_limit_text or "\232\175\183\231\173\150\229\136\146\233\133\141\231\189\174\228\184\128\228\184\139\230\141\143")
        local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(exchangeLimitId, self.exchangeGroupInfoTable)
        self.ImposeRestrictionsOn_1:SetText(string.format("%d", remainExchangeTimes))
        if 0 == remainExchangeTimes then
          self.ImposeRestrictionsOn_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
        else
          self.ImposeRestrictionsOn_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
        end
        isShowSurplus = true
      end
    end
  end
  if not isShowSurplus then
    self.ImposeRestrictionsOn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImposeRestrictionsOn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local isExchangeStarDebris = false
  if self.exchangeConf and self.exchangeConf.get_item and #self.exchangeConf.get_item > 0 then
    local Item = self.exchangeConf.get_item[1]
    if Item and Item.get_goods_type == _G.Enum.GoodsType.GT_VITEM and Item.get_goods_id == _G.Enum.VisualItem.VI_STAR_DEBRIS then
      local hasNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(Item.get_goods_id) or 0
      local limitNum = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit").num
      local vItemsConf = _G.DataConfigManager:GetVisualItemConf(Item.get_goods_id)
      if vItemsConf then
        self.ContractSealIcon:SetPath(vItemsConf.iconPath)
      end
      self.TextContractSeal:SetText(string.format("%d/%d", hasNum, limitNum))
      isExchangeStarDebris = true
    end
  end
  self.ContractSeal:SetVisibility(isExchangeStarDebris and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  local num = math.floor(self.SliderPanel:GetSliderValue())
  self:UpdateCostIcon(self.exchangeId, num)
end

function UMG_AlchemyPanel_C:UpdateCostIcon(exchangeId, item_num)
  if 0 == exchangeId then
    self.UMG_CoinButton.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local currencyIcon
    if exchangeConf and exchangeConf.visual_item_cost_num and 0 ~= exchangeConf.visual_item_cost_num then
      self.UMG_CoinButton.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_CoinButton2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local CostCoinNum = exchangeConf.visual_item_cost_num
      if item_num and 0 ~= item_num then
        CostCoinNum = CostCoinNum * item_num
      end
      local current_coin_num = 0
      if exchangeConf.visual_item_cost_type == _G.Enum.VisualItem.VI_COIN then
        current_coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_COIN) or 0
        currencyIcon = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BagItem/1.1'"
      else
        Log.Error("\232\191\153\228\184\170\230\149\176\230\141\174\230\156\137\233\151\174\233\162\152\239\188\140\231\155\174\229\137\141\229\143\170\230\148\175\230\140\129\230\180\155\229\133\139\232\180\157\239\188\140\230\156\137\230\150\176\232\180\167\229\184\129\230\182\136\232\128\151\232\175\183\230\143\144\230\150\176\233\156\128\230\177\130")
      end
      self.UMG_CoinButton:SetClickAble(true)
      self.UMG_CoinButton:SetTitleTextAndIcon(currencyIcon, CostCoinNum)
      self.UMG_CoinButton2:SetTitleTextAndIcon(currencyIcon, CostCoinNum)
      if CostCoinNum > current_coin_num then
        self.UMG_CoinButton.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
        self.UMG_CoinButton2.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
      else
        self.UMG_CoinButton.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
        self.UMG_CoinButton2.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
      end
    else
      self.UMG_CoinButton.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_CoinButton2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_AlchemyPanel_C:UpdateButton()
  if 0 ~= self.exchangeId and 0 == self.canExchangeNum then
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local ExchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchangeId)
    if ExchangeConf then
      local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(ExchangeConf.exchange_time_limit_group, self.exchangeGroupInfoTable)
      if remainExchangeTimes and 0 == remainExchangeTimes then
        self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
        self.UMG_CoinButton2.Title_1:SetText(self.makeItemText)
      elseif 0 == AlchemyUtils.GetItemCanExchangeNum(ExchangeConf) then
        self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
        self.UMG_CoinButton2.Title_1:SetText(self.makeItemText)
      else
        self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
        self.UMG_CoinButton2.Title_1:SetText(self.makeItemText)
      end
    end
  else
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_AlchemyPanel_C:GetFilterData()
  local data = {}
  for _, buildItem in ipairs(self.buildItems) do
    local bagItemId = buildItem.DataList[1].get_item.get_goods_id
    local bagItem = AlchemyUtils.GetBagItemByID(bagItemId)
    local bagItemGid = bagItem and bagItem.gid or 0
    buildItem.filterData = {bagitem_id = bagItemId, gid = bagItemGid}
    table.insert(data, buildItem)
  end
  return data
end

function UMG_AlchemyPanel_C:OnBasicFilter(FilterList, condition)
  self.basicCondition = condition
  self:AlchemyItemChanged(0, 0, 0)
  self.View_List:EndInertialScrolling()
  self.View_List:NRCScrollToStart()
  self:RefreshUI(FilterList)
  self:SwitchToNormalPanel(true, FilterList)
end

function UMG_AlchemyPanel_C:OnChangeMaterialUpdate()
  local curValue = math.floor(self.SliderPanel:GetSliderValue())
  self.exchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchangeId, true)
  if self.exchangeConf then
    local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(self.exchangeConf.exchange_time_limit_group, self.exchangeGroupInfoTable)
    self.canExchangeNum = AlchemyUtils.GetCanExchangeNum(self.exchangeConf, remainExchangeTimes)
    local curExchangeNum = AlchemyUtils.GetCurrentExchangeNum(self.exchangeConf)
    curValue = math.min(curValue, curExchangeNum)
  end
  self:SetupSlier()
  if curValue < self.canExchangeNum then
    self.SliderPanel:SetSliderValue(curValue)
  end
  self:SetSliderNum(curValue)
  self:OnSliderValueChanged()
  self:UpdateAll()
end

function UMG_AlchemyPanel_C:ClickInfoIcon()
  local get_items = self.exchangeConf and self.exchangeConf.get_item
  local get_item = get_items and get_items[1]
  if not get_item then
    return
  end
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, get_item.get_goods_id, _G.Enum.GoodsType.GT_BAGITEM, false)
end

function UMG_AlchemyPanel_C:UpdateViewItemSelectIndex(exchangeId)
  for i = 1, self.View_List:GetItemCount() do
    local item = self.View_List:GetItemByIndex(i - 1)
    if item then
      for k, v in ipairs(item.data.DataList) do
        if v.exchangeId == exchangeId then
          item:SetSelectIndex(k)
          return
        end
      end
    end
  end
end

function UMG_AlchemyPanel_C:GetCostTimeStr(costTime)
  local day = math.floor(costTime / 86400)
  local hour = math.floor((costTime - day * 86400) / 3600)
  local min = math.floor((costTime - day * 86400 - hour * 3600) / 60)
  local btnText = 0
  if day > 0 then
    btnText = string.format(LuaText.activity_RTS1, day, hour)
  elseif hour > 0 then
    btnText = string.format(LuaText.activity_RTS2, hour, min)
  elseif min > 0 then
    btnText = min .. LuaText.umg_pass_awardmain_5
  else
    btnText = LuaText.activity_RTS3
  end
  return btnText
end

function UMG_AlchemyPanel_C:GetCurrentExchangeLeftTime()
  return self.currentExchangeItemDisappearTimestamp or 0
end

function UMG_AlchemyPanel_C:FormatterExchangeLeftTime(leftSeconds)
  if leftSeconds > 0 then
    local day = math.floor(leftSeconds / 86400)
    local hour = math.floor(leftSeconds % 86400 / 3600)
    local minute = math.floor(leftSeconds % 3600 / 60)
    local second = leftSeconds % 60
    if day > 0 then
      return string.safeFormat(_G.LuaText.furnace_limitedtime_recipe_tips1, day, hour)
    elseif hour > 0 then
      return string.safeFormat(_G.LuaText.furnace_limitedtime_recipe_tips2, hour, minute)
    else
      return string.safeFormat(_G.LuaText.furnace_limitedtime_recipe_tips3, minute, second)
    end
  else
    return _G.LuaText.item_expired_text04
  end
end

function UMG_AlchemyPanel_C:OnExchangeLeftTimeChanged(_ctrl, _leftTimeStr, _endTimeStamp)
  self.Countdown:SetVisibility(not string.IsNilOrEmpty(_leftTimeStr) and 0 ~= _endTimeStamp and UE4.ESlateVisibility.HitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

return UMG_AlchemyPanel_C

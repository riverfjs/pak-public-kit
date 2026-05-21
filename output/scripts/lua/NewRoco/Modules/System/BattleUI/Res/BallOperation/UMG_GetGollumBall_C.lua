local UMG_GetGollumBall_C = _G.NRCPanelBase:Extend("UMG_GetGollumBall_C")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")

function UMG_GetGollumBall_C:OnActive()
  self:OnAddEventListener()
  self:SetCommonPopUpInfo(self.PopUp)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:AlchemyItemChanged(0, 0, 0)
  local SliderInfo = {
    num1 = self.MinValue,
    num2 = self.MaxValue
  }
  local ProgressBarInfo = {
    num1 = self.MinValue,
    num2 = self.MaxValue
  }
  self:SetCommonAddSubtractInfo(self.AddSubtract_White, SliderInfo, ProgressBarInfo)
  self:RequestUIDataUpdate()
  local title = _G.DataConfigManager:GetLocalizationConf("battle_get_ball_jump_to_mall").msg
  self.NRCText_63:SetText(title)
end

function UMG_GetGollumBall_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CloseAlternateMaterial)
  if self.Context then
    self.Context:Close()
  end
  self:OnRemoveEventListener()
end

function UMG_GetGollumBall_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.AlchemyModuleEvent.AlchemyItemChanged, self.AlchemyItemChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.AlchemyModuleEvent.SetExchangeMaterial, self.OnSetExchangeMaterial)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.RefreshList)
  _G.BattleEventCenter:UnBind(self)
end

function UMG_GetGollumBall_C:OnAddEventListener()
  self:AddButtonListener(self.Synthesis_Btn1.btnLevelUp, self.OnBtnBuildItemsClick)
  self:AddButtonListener(self.ShopPurchaseBtn, self.OnOpenStore)
  _G.NRCEventCenter:RegisterEvent("UMG_GetGollumBall_C", self, _G.AlchemyModuleEvent.AlchemyItemChanged, self.AlchemyItemChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_GetGollumBall_C", self, _G.AlchemyModuleEvent.SetExchangeMaterial, self.OnSetExchangeMaterial)
  _G.NRCEventCenter:RegisterEvent("UMG_GetGollumBall_C", self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.RefreshList)
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_START, BattleEvent.UI_INSTANT_UPDATE_ITEM, _G.BattlePerformEvent.TurnPlayStart)
end

function UMG_GetGollumBall_C:TryClosePanel()
  self:OnClickClose()
end

function UMG_GetGollumBall_C:OnPcClose()
  self:TryClosePanel()
end

function UMG_GetGollumBall_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_BattleGollumBall")
  if mappingContext then
    mappingContext:BindAction("IA_BattleCloseGollumBall", self, "TryClosePanel")
    mappingContext:BindAction("IA_BattleMoreQuickClose", self, "TryClosePanel")
    self.extraKey = _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.GetMappingKey, "IA_BattleMoreQuickClose")
    if self.extraKey then
      mappingContext:AddKey("IA_BattleMoreQuickClose", self.extraKey)
    end
  end
end

function UMG_GetGollumBall_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_BattleMoreQuickClose")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_BattleGollumBall")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_GetGollumBall_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.ROUND_START or eventName == _G.BattlePerformEvent.TurnPlayStart then
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.CloseNPCShopItemRewardsPanel)
    self:DoClose()
  elseif eventName == BattleEvent.UI_INSTANT_UPDATE_ITEM then
    self:RefreshList()
  end
end

function UMG_GetGollumBall_C:OnSetExchangeMaterial()
  local curValue = math.floor(self.AddSubtract_White:GetSliderValue())
  self.exchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchangeId, true)
  if self.exchangeConf then
    local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(self.exchangeConf.exchange_time_limit_group, self.exchangeGroupInfoTable)
    self.canExchangeNum = AlchemyUtils.GetCanExchangeNum(self.exchangeConf, remainExchangeTimes)
    local curExchangeNum = AlchemyUtils.GetCurrentExchangeNum(self.exchangeConf)
    curValue = math.min(curValue, curExchangeNum)
  end
  self:SetupSlier()
  if curValue < self.canExchangeNum then
    self.AddSubtract_White:SetSliderValue(curValue)
  end
  self:SetSliderNum(curValue)
  self:OnSliderValueChanged()
  self:UpdateAll()
  if 0 == curValue then
    curValue = 1
  end
  self:UpdateItems(self.exchangeId, curValue)
end

function UMG_GetGollumBall_C:OnBtnBuildItemsClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BATTLE_GET_BALL, true)
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
  local num = math.floor(self.AddSubtract_White:GetSliderValue())
  if 0 == num or 0 == self.canExchangeNum then
    self:PopupExChangeFailed()
    return
  end
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
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RequestExchangeInBattle, exchangeId, num, costItemList)
end

function UMG_GetGollumBall_C:PopupExChangeFailed()
  if self.Context then
    self.Context:Close()
  end
  local Context = DialogContext()
  local ContentText = _G.DataConfigManager:GetLocalizationConf("battle_get_ball_jump_mall").msg
  Context:SetTitle(LuaText.umg_pass_purchase_1):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.OnOpenStore):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_login_new_3, LuaText.umg_login_new_4):SetForceEnableFullScreenBtn()
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  self.Context = Context
end

function UMG_GetGollumBall_C:OnOpenStore()
  NRCProfilerLog:NRCClickBtn(true, "Shop")
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OpenMainPanel, nil, nil, "MT_CREDIT")
  self:DoClose()
end

function UMG_GetGollumBall_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.PopUpType = 2
  CommonPopUpData.ClosePanelHandler = self.OnClickClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_GetGollumBall_C:OnClickClose()
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CloseAlternateMaterial)
  if self.Context then
    self.Context:Close()
  end
  self:LoadAnimation(2)
end

function UMG_GetGollumBall_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_GetGollumBall_C:OnLogin()
end

function UMG_GetGollumBall_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:BindInputAction()
end

function UMG_GetGollumBall_C:OnDestruct()
  self:UnBindInputAction()
end

function UMG_GetGollumBall_C:SetCommonAddSubtractInfo(AddSubtract, SliderInfo, ProgressBarInfo, MultipleAddBtnText, MultipleSubtractBtnText, SelectNum)
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

function UMG_GetGollumBall_C:RequestUIDataUpdate()
  if self.isClosing then
    return
  end
  local req_unlock = _G.ProtoMessage:newZoneGetUnlockedExchangeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_GET_UNLOCKED_EXCHANGE_REQ, req_unlock, self, self.OnGetUnlockedExchangeRsp, true, true)
end

function UMG_GetGollumBall_C:OnGetUnlockedExchangeRsp(rsp)
  if self.isClosing then
    return
  end
  self:LoadAnimation(0)
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
  self:RefreshUI()
end

function UMG_GetGollumBall_C:RefreshList()
  local itemCount = self.GollumBallList:GetItemCount()
  if itemCount > 0 then
    for i = 1, itemCount do
      local item = self.GollumBallList:GetItemByIndex(i - 1)
      if item then
        item:RefreshCount()
      end
    end
  end
  local coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
  local moneyInfo = {}
  table.insert(moneyInfo, {
    moneyType = _G.Enum.VisualItem.VI_COIN,
    sum = coin_num,
    IsShowBuyIcon = false
  })
  self.MoneyBtn:InitGridView(moneyInfo)
  if self.exchangeConf then
    local remainExchangeTime = AlchemyUtils.GetRemainExchangeTimes(self.exchangeConf.exchange_time_limit_group, self.exchangeGroupInfoTable)
    self.canExchangeNum = AlchemyUtils.GetCanExchangeNum(self.exchangeConf, remainExchangeTime)
  end
  self:OnSetExchangeMaterial()
end

function UMG_GetGollumBall_C:RefreshUI(newItems)
  if newItems then
    self.GollumBallList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:RefreshExchangeList(newItems)
  else
    self.buildItems = self:FilterExchangeByType(_G.Enum.ExchangeUseType.EUT_MANUFACTURE_BASIC_COMPOUND)
    local items
    if self.basicCondition and self.basicCondition.FilterBasicCondition then
      items = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetFilterBasicList, self.basicCondition.FilterBasicCondition, self:GetFilterData())
    end
    self.GollumBallList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:RefreshExchangeList(items and items or self.buildItems)
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

function UMG_GetGollumBall_C:RefreshExchangeList(newItems)
  newItems = newItems or self.buildItems
  self.GollumBallList:InitList(newItems)
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
    self.GollumBallList:SelectItemByIndex(index - 1)
    local item = self.GollumBallList:GetItemByIndex(index - 1)
  elseif #newItems > 0 then
    self.GollumBallList:SelectItemByIndex(0)
  else
    self:AlchemyItemChanged(0, 0, 0)
  end
end

local function _SortExchangeFunc(a, b)
  local appearTimestampA = a.appear_time or math.maxinteger
  local appearTimestampB = b.appear_time or math.maxinteger
  if appearTimestampA ~= appearTimestampB then
    return appearTimestampA < appearTimestampB
  end
  local canExchangeA = a.canExchangeNum > 0 and 1 or 0
  local canExchangeB = b.canExchangeNum > 0 and 1 or 0
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

function UMG_GetGollumBall_C:FilterExchangeByType(filterType)
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
      if get_item.get_goods_type ~= _G.Enum.GoodsType.GT_BAGITEM then
      else
        local BagItemConf = _G.DataConfigManager:GetBagItemConf(get_item.get_goods_id)
        if BagItemConf.type ~= Enum.BagItemType.BI_PET_BALL then
        else
          item.exchangeId = cfg.id
          item.exchangeConf = cfg
          item.exchange_time_lower_limit = cfg.exchange_time_lower_limit
          item.exchange_time_upper_limit = cfg.exchange_time_upper_limit
          item.get_item = get_item
          item.cost_item = {}
          item.num = 0
          item.IsRefresh = self.IsRefresh
          if self.exchangeGroupInfoTable[cfg.exchange_time_limit_group] then
            item.exchange_times = self.exchangeGroupInfoTable[cfg.exchange_time_limit_group].exchange_times
            item.next_refresh_time = self.exchangeGroupInfoTable[cfg.exchange_time_limit_group].next_refresh_time
          else
            item.exchange_times = 0
            item.next_refresh_time = nil
          end
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
          for i, cost_item in ipairs(cfg.cost_item) do
            local bagItemData = AlchemyUtils.GetBagItemByID(cost_item.cost_goods_id)
            local new_cost_item = {}
            new_cost_item.cost_goods_id = cost_item.cost_goods_id
            new_cost_item.cost_goods_type = cost_item.cost_goods_type
            new_cost_item.cost_goods_num = cost_item.cost_goods_num
            if bagItemData then
              new_cost_item.num = bagItemData.num
            else
              new_cost_item.num = 0
            end
            table.insert(item.cost_item, new_cost_item)
          end
          if get_item.get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
            local bagItemData = AlchemyUtils.GetBagItemByID(get_item.get_goods_id)
            if bagItemData then
              item.num = bagItemData.num
            end
          end
          local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(cfg.exchange_time_limit_group, self.exchangeGroupInfoTable)
          item.canExchangeNum = AlchemyUtils.GetCanExchangeNum(cfg, remainExchangeTimes)
          if exchangeIdMap[get_item.get_goods_id] == nil then
            exchangeIdMap[get_item.get_goods_id] = {}
          end
          table.insert(exchangeIdMap[get_item.get_goods_id], item)
        end
      end
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

function UMG_GetGollumBall_C:AlchemyItemChanged(exchangeId, index, recipeIndex, SkipAudio)
  Log.Debug("UMG_GetGollumBall_C:AlchemyItemChanged", exchangeId)
  if not SkipAudio then
    if self.firstSelectItem then
      self.firstSelectItem = false
    else
      _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_GetGollumBall_C:AlchemyItemChanged")
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
  self:SetupSlier()
  self:UpdateAll()
end

function UMG_GetGollumBall_C:SetupSlier()
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
  self.AddSubtract_White:SetSliderStepSize(1)
  self.AddSubtract_White:SetSliderMinValue(newMinValue)
  self.AddSubtract_White:SetSliderMaxValue(newMaxValue)
  if 0 == maxValue then
    self.AddSubtract_White:SetSliderLocked(true)
    self:SetSliderNum(0)
  else
    self.AddSubtract_White:SetSliderLocked(false)
    self:SetSliderNum(1)
  end
  self.AddSubtract_White.Digital:SetText(newMinValue)
  self.AddSubtract_White.Digital_1:SetText(newMaxValue)
end

function UMG_GetGollumBall_C:SetSliderNum(value)
  self.AddSubtract_White:SetSliderValue(value)
  self.lastBuildValue = value
end

function UMG_GetGollumBall_C:OnBtnAddItemClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_CampingBuild_Info_C:OnBtnAddItemClick")
  self:ChangeBuildTimes(true)
end

function UMG_GetGollumBall_C:OnBtnDelItemClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401008, "UMG_CampingBuild_Info_C:OnBtnDelItemClick")
  self:ChangeBuildTimes(false)
end

function UMG_GetGollumBall_C:ChangeBuildTimes(_isAddItem)
  Log.Debug("UMG_CampingBuild_Info_C:ChangeBuildTimes")
  local curValue = self.AddSubtract_White:GetSliderValue()
  local minValue = self.AddSubtract_White:GetSliderMinValue()
  local maxValue = self.AddSubtract_White:GetSliderMaxValue()
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
  self:UpdateItems(self.exchangeId, curValue)
end

function UMG_GetGollumBall_C:OnSliderValueChanged()
  if 0 == self.AddSubtract_White:GetSliderMinValue() then
    self:SetSliderNum(0)
    return
  end
  Log.Debug("UMG_CampingBuild_Info_C:OnSliderValueChanged")
  self:SetupAddOrDecBtnState()
  self:SetupBuildNumText()
  self:UpdateScheduleBar()
  local curValue = math.floor(self.AddSubtract_White:GetSliderValue())
  if self.lastBuildValue ~= curValue then
    self.lastBuildValue = curValue
    _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_CampingBuild_Info_C:OnBtnDelItemClick")
  end
  self:UpdateItems(self.exchangeId, curValue)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.exchangeId, curValue)
end

function UMG_GetGollumBall_C:SetupAddOrDecBtnState()
  local curValue = self.AddSubtract_White:GetSliderValue()
  local minValue = self.AddSubtract_White:GetSliderMinValue()
  local maxValue = self.AddSubtract_White:GetSliderMaxValue()
  if 0 == self.AddSubtract_White:GetSliderMinValue() then
    self.AddSubtract_White:SetAddBtnIsEnabledNewStyle(false)
    self.AddSubtract_White:SetSubtractBtnIsEnabledNewStyle(false)
  else
    self.AddSubtract_White:SetAddBtnIsEnabledNewStyle(curValue ~= maxValue)
    self.AddSubtract_White:SetSubtractBtnIsEnabledNewStyle(curValue ~= minValue)
  end
end

function UMG_GetGollumBall_C:UpdateCostIcon(exchangeId, item_num)
  if 0 == exchangeId then
    self.Synthesis_Btn1.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Synthesis_Btn2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local currencyIcon
    if exchangeConf and exchangeConf.visual_item_cost_num and 0 ~= exchangeConf.visual_item_cost_num then
      self.Synthesis_Btn1.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Synthesis_Btn2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
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
      self.Synthesis_Btn1:SetClickAble(true)
      self.Synthesis_Btn1:SetTitleTextAndIcon(currencyIcon, CostCoinNum)
      self.Synthesis_Btn2:SetTitleTextAndIcon(currencyIcon, CostCoinNum)
      if CostCoinNum > current_coin_num then
        self.Synthesis_Btn1.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
        self.Synthesis_Btn2.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
      else
        self.Synthesis_Btn1.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
        self.Synthesis_Btn2.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
      end
    else
      self.Synthesis_Btn1.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Synthesis_Btn2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_GetGollumBall_C:UpdateButton()
  if 0 ~= self.exchangeId and 0 == self.canExchangeNum then
    local ExchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchangeId)
    if ExchangeConf then
      local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(ExchangeConf.exchange_time_limit_group, self.exchangeGroupInfoTable)
      if remainExchangeTimes and 0 == remainExchangeTimes then
        self.Synthesis_Btn2.btnLevelUp:SetIsEnabled(false)
        self.Synthesis_Btn2.Title_1:SetText(self.makeItemText)
      elseif 0 == AlchemyUtils.GetItemCanExchangeNum(ExchangeConf) then
        self.Synthesis_Btn2.btnLevelUp:SetIsEnabled(false)
        self.Synthesis_Btn2.Title_1:SetText(self.makeItemText)
      else
        self.Synthesis_Btn2.btnLevelUp:SetIsEnabled(false)
        self.Synthesis_Btn2.Title_1:SetText(self.makeItemText)
      end
    end
  end
end

function UMG_GetGollumBall_C:SetupBuildNumText()
  if self.exchangeConf then
  else
  end
  if self.exchangeConf == nil then
    self:UpdateItems(self.exchangeId, 1)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.exchangeId, 1)
    self.SyntheticQuantityText:SetText(string.format("%d", 0))
  elseif 0 == self.canExchangeNum then
    self:UpdateItems(self.exchangeId, 1)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.exchangeId, 1)
    self.SyntheticQuantityText:SetText(string.format("%d", 0))
  else
    local curValue = math.floor(self.AddSubtract_White:GetSliderValue())
    self.SyntheticQuantityText:SetText(string.format("%d", curValue))
    self:UpdateItems(self.exchangeId, curValue)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.exchangeId, curValue)
  end
  local isShowSurplus = false
  if self.exchangeConf then
    local exchangeLimitId = self.exchangeConf.exchange_time_limit_group
    if exchangeLimitId and 0 ~= exchangeLimitId then
      local exchangeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(exchangeLimitId)
      if exchangeLimitConf then
        local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(exchangeLimitId, self.exchangeGroupInfoTable)
        isShowSurplus = true
      end
    end
  end
  local isExchangeStarDebris = false
  if self.exchangeConf and self.exchangeConf.get_item and #self.exchangeConf.get_item > 0 then
    local Item = self.exchangeConf.get_item[1]
    if Item and Item.get_goods_type == _G.Enum.GoodsType.GT_VITEM and Item.get_goods_id == _G.Enum.VisualItem.VI_STAR_DEBRIS then
      local hasNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(Item.get_goods_id) or 0
      local limitNum = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit").num
      local vItemsConf = _G.DataConfigManager:GetVisualItemConf(Item.get_goods_id)
      if vItemsConf then
      end
      isExchangeStarDebris = true
    end
  end
  local num = math.floor(self.AddSubtract_White:GetSliderValue())
  self:UpdateCostIcon(self.exchangeId, num)
end

function UMG_GetGollumBall_C:UpdateScheduleBar()
  local minValue = self.AddSubtract_White:GetSliderMinValue()
  local maxValue = self.AddSubtract_White:GetSliderMaxValue()
  local currentValue = self.AddSubtract_White:GetSliderValue()
  if 0 == maxValue - minValue then
    if currentValue > 0 then
      self.AddSubtract_White:SetProgressBarPercent(1)
    else
      self.AddSubtract_White:SetProgressBarPercent(0)
    end
  else
    self.AddSubtract_White:SetProgressBarPercent((self.AddSubtract_White:GetSliderValue() - self.AddSubtract_White:GetSliderMinValue()) / (self.AddSubtract_White:GetSliderMaxValue() - self.AddSubtract_White:GetSliderMinValue()))
  end
end

function UMG_GetGollumBall_C:UpdateAll()
  self:SetupAddOrDecBtnState()
  self:SetupBuildNumText()
  self:UpdateButton()
  self:UpdateScheduleBar()
  self:UpdateInfoPanel()
end

function UMG_GetGollumBall_C:UpdateItems(exchange_id, item_num)
  self.exchange_id = exchange_id
  local answer = {}
  if 0 == self.exchange_id then
    self.ConsumptionItem:InitGridView(answer)
    return
  end
  local costMaterials = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetCostMaterialItems, exchange_id, item_num)
  for i = 1, 4 do
    if i <= #costMaterials and (costMaterials[i].goods_type ~= _G.Enum.GoodsType.GT_VITEM or costMaterials[i].goods_id ~= _G.Enum.VisualItem.VI_COIN) then
      table.insert(answer, costMaterials[i])
    end
  end
  self.ConsumptionItem:InitGridView(answer)
end

function UMG_GetGollumBall_C:UpdateInfoPanel()
  local get_items = self.exchangeConf and self.exchangeConf.get_item
  local get_item = get_items and get_items[1]
  if not get_item then
    return
  end
  local itemCfg
  local itemName = ""
  local itemDesc = ""
  local itemTypeDesc = ""
  if get_item.get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
    itemCfg = _G.DataConfigManager:GetBagItemConf(get_item.get_goods_id)
    if itemCfg then
      itemName = itemCfg.name
      itemDesc = itemCfg.description
      itemTypeDesc = itemCfg.type_desc
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
    return
  end
  self.GollumBallTitle:SetText(itemName)
  self.GollumBallText:SetText(itemTypeDesc)
  self.GollumBallDescription:SetText(itemDesc)
end

return UMG_GetGollumBall_C

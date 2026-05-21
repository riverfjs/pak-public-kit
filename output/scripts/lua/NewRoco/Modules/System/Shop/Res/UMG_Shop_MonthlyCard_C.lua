local UMG_Shop_MonthlyCard_C = _G.NRCPanelBase:Extend("UMG_Shop_MonthlyCard_C")
local ShopModuleEvent = require("NewRoco.Modules.System.Shop.ShopModuleEvent")

function UMG_Shop_MonthlyCard_C:OnConstruct()
  self:AddButtonListener(self.ParticularsBtn, self.OnClickShowDescTips)
  self:AddButtonListener(self.ReorderBtn.btnLevelUp, self.OnClickPurchaseOrRenewal)
  self:AddButtonListener(self.Button_Schedule, self.OnClickButton_Schedule)
  self.SignDesc:SetText(_G.LuaText.YueKa_Accumulated_Login_Tips)
  self.rewardTitle1:SetText(_G.LuaText.YueKa_Reward_Buy)
  self.rewardTitle2:SetText(_G.LuaText.YueKa_Reward_Accumulated_Login)
  self.ReceivedText:SetText(_G.LuaText.YueKa_Reward_Got)
  local clientMonthCardConf = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetClientMonthCardConf)
  do
    local _rewardConf = clientMonthCardConf.buyRewardId and _G.DataConfigManager:GetRewardConf(clientMonthCardConf.buyRewardId)
    if _rewardConf and _rewardConf.RewardItem and #_rewardConf.RewardItem > 0 then
      local itemList = {}
      for k, v in ipairs(_rewardConf.RewardItem) do
        local itemData = {}
        itemData.itemType = v.Type
        itemData.itemId = v.Id
        itemData.itemNum = v.Count
        itemData.bShowNum = true
        itemData.bShowTip = true
        table.insert(itemList, itemData)
      end
      self.RewardList_1.m_colCount = #_rewardConf.RewardItem
      self.RewardList_1:InitGridView(itemList)
    else
      self.RewardList_1:InitGridView({})
    end
  end
  do
    local _rewardConf = clientMonthCardConf.buyRewardId and _G.DataConfigManager:GetRewardConf(clientMonthCardConf.dayRewardId)
    if _rewardConf and _rewardConf.RewardItem and #_rewardConf.RewardItem > 0 then
      local itemList = {}
      for k, v in ipairs(_rewardConf.RewardItem) do
        local itemData = {}
        itemData.itemType = v.Type
        itemData.itemId = v.Id
        itemData.itemNum = v.Count * 30
        itemData.bShowNum = true
        itemData.bShowTip = true
        table.insert(itemList, itemData)
      end
      self.RewardList.m_colCount = #_rewardConf.RewardItem
      self.RewardList:InitGridView(itemList)
    else
      self.RewardList:InitGridView({})
    end
  end
  do
    local signRewardsTotal = {}
    for _needDays, _rewardId in pairs(clientMonthCardConf.signRewards) do
      if signRewardsTotal[_rewardId] then
        signRewardsTotal[_rewardId] = signRewardsTotal[_rewardId] + 1
      else
        signRewardsTotal[_rewardId] = 1
      end
    end
    local rewardListItems = {}
    for i, _rewardId in pairs(clientMonthCardConf.previewSlot2Ids) do
      local _rewardConf = _G.DataConfigManager:GetRewardConf(_rewardId)
      local _rewardItem = _rewardConf and _rewardConf.RewardItem[1]
      if _rewardItem then
        local itemData = {}
        itemData.itemType = _rewardItem.Type
        itemData.itemId = _rewardItem.Id
        itemData.itemNum = _rewardItem.Count
        itemData.bShowNum = true
        itemData.bShowTip = true
        table.insert(rewardListItems, itemData)
        itemData.monthCardSortQuality = -1
        itemData.monthCardSortId = -1
        if _rewardItem.Type == _G.Enum.GoodsType.GT_BAGITEM then
          local _bagItemConf = _G.DataConfigManager:GetBagItemConf(_rewardItem.Id)
          itemData.monthCardSortQuality = _bagItemConf and _bagItemConf.item_quality
          itemData.monthCardSortId = _bagItemConf and _bagItemConf.sort_id
        end
      end
    end
    table.sort(rewardListItems, function(a, b)
      if a.monthCardSortQuality == b.monthCardSortQuality then
        return a.monthCardSortId < b.monthCardSortId
      end
      return a.monthCardSortQuality > b.monthCardSortQuality
    end)
    self.RewardList_2:InitGridView(rewardListItems)
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_REQ, _G.ProtoMessage:newZoneMonthCardGetInfoReq())
end

function UMG_Shop_MonthlyCard_C:OnDestruct()
end

function UMG_Shop_MonthlyCard_C:OnActive(_shopId, _itemList)
  self.shopId = _shopId
  self:RegisterEvent(self, ShopModuleEvent.RefreshMonthCardData, self.OnRefreshMonthCardData)
  local goodsItem = _itemList and _itemList[1]
  local goodsId = goodsItem and goodsItem.shopItemId
  local goodsConf = goodsId and _G.DataConfigManager:GetNormalShopConf(goodsId)
  if goodsConf then
    self.monthCardGoodsConf = goodsConf
    self.Title:SetText(goodsConf.goods_name)
  end
  self.goodsShopId = goodsItem and goodsItem.shopId
  self.goodsId = goodsId
  local monthCardData = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetMonthCardData)
  self:OnRefreshMonthCardData(monthCardData)
  self:PlayAnimation(self.In)
end

function UMG_Shop_MonthlyCard_C:OnDeactive()
  self:UnRegisterEvent(self, ShopModuleEvent.RefreshMonthCardData)
end

function UMG_Shop_MonthlyCard_C:OnEnable()
end

function UMG_Shop_MonthlyCard_C:OnDisable()
end

function UMG_Shop_MonthlyCard_C:OnRefreshMonthCardData(_monthCardData)
  if not _monthCardData then
    return
  end
  local clientMonthCardConf = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetClientMonthCardConf)
  local signDays = _monthCardData.sign_days or 0
  local maxSignDay = clientMonthCardConf.maxSignDay
  if 0 == maxSignDay then
    self.ProgressBar:SetPercent(0)
  else
    if signDays > maxSignDay then
      signDays = (signDays - 1) % maxSignDay + 1
    end
    self.ProgressBar:SetPercent(signDays / maxSignDay)
  end
  self.Received:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local leftDays = _monthCardData.left_days or 0
  if leftDays >= 1 then
    self.Countdown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DayLeft:SetText(string.format(_G.LuaText.YueKa_Reward_Day, leftDays - 1))
    if _monthCardData.daily_rewards and 1 == _monthCardData.daily_rewards then
      self.Received:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Received:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.Countdown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.SignDesc:SetText(string.format(_G.LuaText.yueka_star_tips, clientMonthCardConf.StarRatio) .. "%")
  local goodsConf = self.monthCardGoodsConf
  if goodsConf then
    local goodsSevData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.goodsShopId, self.monthCardGoodsConf.id)
    local price = goodsConf.origin_price
    if goodsSevData then
      price = goodsSevData.real_price.num
    end
    if leftDays > 1 then
      self.ReorderBtn:SetBtnText(string.format(_G.LuaText.YueKa_Button_Purchased, price))
    else
      self.ReorderBtn:SetBtnText(string.format(_G.LuaText.YueKa_Button_CanPurchase, price))
    end
  end
end

function UMG_Shop_MonthlyCard_C:OnClickShowDescTips()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(self.Title:GetText()):SetContent(_G.LuaText.YueKa_Tips):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Shop_MonthlyCard_C:OnClickPurchaseOrRenewal()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHARGE_MONTHLY_CARD, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1220002023, "UMG_Shop_MonthlyCard_C:OnClickPurchaseOrRenewal")
  if _G.NRCModuleManager:DoCmd(_G.PayModuleCmd.IfLimitPay, self.goodsId) then
    return
  end
  if not _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdCanBuyMonthCard) then
    return
  end
  local goodsConf = self.monthCardGoodsConf
  if goodsConf and goodsConf.buy_cond_type == Enum.BuyLimited.BL_YK_MAX_DAYS and goodsConf.buy_cond_param then
    local monthCardData = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetMonthCardData)
    local leftDays = monthCardData.left_days or 0
    if leftDays - 1 >= goodsConf.buy_cond_param then
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local Context = DialogContext()
      Context:SetTitle(self.Title:GetText()):SetContent(_G.LuaText.YueKa_Greater_Than_Or_Equal_To_179_Tips):SetContentTextJustify(UE4.ETextJustify.Center):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
      return
    end
  end
  local goodsShopId = self.goodsShopId
  if goodsShopId then
    _G.NRCModuleManager:DoCmd(_G.PayModuleCmd.PayForItem, self.goodsId, self.goodsShopId)
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdSetBuyingMonthCard)
  end
end

function UMG_Shop_MonthlyCard_C:OnClickButton_Schedule()
  _G.NRCAudioManager:PlaySound2DAuto(1220002026, "UMG_Shop_MonthlyCard_C:OnClickButton_Schedule")
  _G.NRCModuleManager:DoCmd(ShopModuleCmd.OnCmdOpenMonthlyCardCheckInProgress)
end

function UMG_Shop_MonthlyCard_C:OnAnimationFinished(anim)
  if anim == self.In then
    UE4Helper.SetEnableWorldRendering(false)
  end
end

return UMG_Shop_MonthlyCard_C

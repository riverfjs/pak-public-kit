local UMG_MonthlyCard_Tips_C = _G.NRCPanelBase:Extend("UMG_MonthlyCard_Tips_C")

function UMG_MonthlyCard_Tips_C:OnConstruct()
  self:AddButtonListener(self.BtnClose, self.OnClose)
  self:AddButtonListener(self.ReorderBtn.btnLevelUp, self.OnClickPurchaseOrRenewal)
  self.Title:SetText(_G.LuaText.YueKa_Login_Title)
  local _monthCardData = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetMonthCardData)
  local clientMonthCardConf = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetClientMonthCardConf)
  local goodsConf = clientMonthCardConf.GoodsId and _G.DataConfigManager:GetNormalShopConf(clientMonthCardConf.GoodsId)
  if goodsConf then
    self.monthCardGoodsConf = goodsConf
  end
  self.goodsShopId = clientMonthCardConf.ShopId
  self.goodsId = clientMonthCardConf.GoodsId
  local leftDays = _monthCardData.left_days or 0
  local severTime = _G.ZoneServer:GetServerTime()
  severTime = math.floor(severTime / 1000)
  if leftDays >= 1 and severTime - (_monthCardData.continue_time + 86400) < 0 then
    self.Countdown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DayLeft:SetText(string.format(_G.LuaText.YueKa_Reward_Day, leftDays - 1))
    local signDaysOneRound = clientMonthCardConf.maxSignDay
    local signDays = _monthCardData.sign_days or 0
    if 0 ~= signDaysOneRound and signDaysOneRound < signDays then
      signDays = (signDays - 1) % signDaysOneRound + 1
    end
    local nextRewardNeedDays = 0
    local nextRewardId = 0
    if signDaysOneRound <= signDays then
      local firstNeedDays = clientMonthCardConf.signDays[1]
      if firstNeedDays then
        nextRewardNeedDays = signDays - signDaysOneRound + firstNeedDays
        nextRewardId = clientMonthCardConf.signRewards[firstNeedDays]
      end
    else
      for _, _needDays in ipairs(clientMonthCardConf.signDays) do
        if _needDays > signDays then
          nextRewardNeedDays = _needDays - signDays
          nextRewardId = clientMonthCardConf.signRewards[_needDays]
          break
        end
      end
    end
    local _rewardConf = 0 ~= nextRewardId and _G.DataConfigManager:GetRewardConf(nextRewardId)
    local _rewardItem = _rewardConf and _rewardConf.RewardItem[1]
    if _rewardItem then
      do
        local _itemName = ""
        if _rewardItem.Type == _G.Enum.GoodsType.GT_VITEM then
          local _vItemsConf = _G.DataConfigManager:GetVisualItemConf(_rewardItem.Id)
          if _vItemsConf then
            _itemName = _vItemsConf.displayName
          end
        elseif _rewardItem.Type == _G.Enum.GoodsType.GT_BAGITEM then
          local _bagItemConf = _G.DataConfigManager:GetBagItemConf(_rewardItem.Id)
          if _bagItemConf then
            _itemName = _bagItemConf.name
          else
          end
        end
      end
    end
  else
    self.IsExpired = true
  end
  local renewDayNum = _G.DataConfigManager:GetGlobalConfigNumByKey("yueka_tips_param1", 1)
  local RepeatDayNum = _G.DataConfigManager:GetGlobalConfigNumByKey("yueka_tips_param2", 1)
  local price = clientMonthCardConf.Price
  if leftDays >= 1 and severTime - (_monthCardData.continue_time + 86400) < 0 then
    self.CanvasPanel_31:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.rewardTitle2:SetText(LuaText.YueKa_Login_SubTitle)
    if leftDays > renewDayNum then
      self.PetIcon:SetActiveWidgetIndex(2)
      self.ReorderBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Hourglass:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC755FF"))
      self.DayLeft:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFC755FF"))
    else
      self.PetIcon:SetActiveWidgetIndex(1)
      self.ReorderBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ReorderBtn:SetBtnText(string.format(_G.LuaText.YueKa_Button_Purchased, price))
      self.Hourglass:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#AF3D3EFF"))
      self.DayLeft:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AF3D3EFF"))
    end
  else
    self.PetIcon:SetActiveWidgetIndex(0)
    self.CanvasPanel_31:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.rewardTitle2:SetText(_G.LuaText.YueKa_Reward_Accumulated_Login)
    local _rewardConf = _G.DataConfigManager:GetRewardConf(clientMonthCardConf.buyRewardId)
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
    local outOfDay = (_G.ZoneServer:GetServerTime() / 1000 - (_monthCardData.continue_time + 86400 or 0)) / 86400
    if RepeatDayNum < outOfDay then
      Log.Error("No Need Card Tips")
    else
      self.ReorderBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ReorderBtn:SetBtnText(string.format(_G.LuaText.YueKa_Button_CanPurchase, price))
      self.Hourglass:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#AF3D3EFF"))
      self.DayLeft:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AF3D3EFF"))
      self.DayLeft:SetText(LuaText.activity_expired_show_tip)
    end
  end
  self.SignDesc:SetText(string.format(_G.LuaText.yueka_star_tips, clientMonthCardConf.StarRatio) .. "%")
end

function UMG_MonthlyCard_Tips_C:BindUIElements()
  local uiElements = {}
  uiElements.openAnimName = "In"
  uiElements.closeAnimName = "Out"
  return uiElements
end

function UMG_MonthlyCard_Tips_C:OnAnimationFinished(Anim)
  if self.panelData == nil then
    return
  end
  if self.panelData.openAnimName and Anim == self[self.panelData.openAnimName] and not self.IsExpired then
    _G.NRCAudioManager:PlaySound2DAuto(1220002049, "UMG_MonthlyCard_Tips_C:OnAnimationFinished")
    self.Seal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.rewardList:GetItemCount() > 1 then
      self:PlayAnimation(self.Receive_2)
    else
      self:PlayAnimation(self.Receive)
    end
  end
  NRCPanelBase.OnAnimationFinished(self, Anim)
end

function UMG_MonthlyCard_Tips_C:OnAnimationStarted(Anim)
  if self.panelData.openAnimName and Anim == self[self.panelData.openAnimName] then
    _G.NRCAudioManager:PlaySound2DAuto(1322, "UMG_MonthlyCard_Tips_C:OnAnimationStarted")
  end
  if self.panelData.closeAnimName and Anim == self[self.panelData.closeAnimName] then
    _G.NRCAudioManager:PlaySound2DAuto(1322, "UMG_MonthlyCard_Tips_C:OnAnimationStarted")
  end
  NRCPanelBase.OnAnimationStarted(self, Anim)
end

function UMG_MonthlyCard_Tips_C:OnDestruct()
  local tip = self.tip
  if tip then
    tip:MarkFinished()
  end
end

function UMG_MonthlyCard_Tips_C:OnActive(_tip)
  self.tip = _tip
  if self.IsExpired then
    local clientMonthCardConf = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetClientMonthCardConf)
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
  else
    local itemList = {}
    local tipsData = _tip and _tip.customData
    if tipsData then
      local clientMonthCardConf = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetClientMonthCardConf)
      for _type, _itemsData in pairs(tipsData) do
        for _id, _num in pairs(_itemsData) do
          local _itemData = {}
          _itemData.itemType = _type
          _itemData.itemId = _id
          _itemData.itemNum = _num[1]
          _itemData.order = _num[2]
          _itemData.bShowNum = true
          _itemData.bShowTip = true
          _itemData.bShowGetTag = true
          _itemData.bShowAdditional = false
          for _day, _confRewardId in pairs(clientMonthCardConf.signRewards) do
            local rewardConf = _G.DataConfigManager:GetRewardConf(_confRewardId)
            local rewardItem = rewardConf and rewardConf.RewardItem[1]
            if rewardItem and rewardItem.Id == _id then
              _itemData.bShowAdditional = true
              break
            end
          end
          table.insert(itemList, _itemData)
        end
      end
    end
    table.stableSort(itemList, function(a, b)
      if not a.order then
        a.order = 999
      end
      if not b.order then
        b.order = 999
      end
      return a.order < b.order
    end)
    self.RewardList:InitGridView(itemList)
  end
end

function UMG_MonthlyCard_Tips_C:OnClickPurchaseOrRenewal()
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

return UMG_MonthlyCard_Tips_C

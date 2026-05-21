local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local UMG_NPCShopItem_1_C = Base:Extend("UMG_NPCShopItem_1_C")

function UMG_NPCShopItem_1_C:OnConstruct()
end

function UMG_NPCShopItem_1_C:OnDestruct()
  self.uiData = nil
  _G.UpdateManager:UnRegister(self)
end

function UMG_NPCShopItem_1_C:Construct()
  Base.Construct(self)
  self.reqMaxCount = 10
  self.reqCount = 0
  self.uiData = {}
  self.startAddFrame = 0
  self.EndAddFrame = 8
  self.startDelFrame = 0
  self.EndDelFrame = 8
  self.IsAdd = false
  self.IsDelItem = false
  self.IsAddClick = false
  self.IsDelClick = false
  self.SoldOut = false
  self.isUnlock = true
  self.CountDownText = ""
  self.btnAddItem.OnPressed:Add(self, self.OnBtnAddPressed)
  self.btnAddItem.OnReleased:Add(self, self.OnBtnAddReleased)
  self.btnSubItem.OnPressed:Add(self, self.OnBtnDelPressed)
  self.btnSubItem.OnReleased:Add(self, self.OnBtnDelReleased)
  self.SizeBox_ju:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_NPCShopItem_1_C:ChangeItemCount(_isAddItem)
  local itemID = self.uiData.shopItemId
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(itemID)
  if nil == goodsConf then
    return
  end
  local limitBuyNum = self.uiData.limitNum - self.uiData.boughtNum
  local leftMoney = 0
  local hasMoney = 0
  local limitCostNum = 0
  if nil ~= self.uiData.priceNum and 0 ~= self.uiData.priceNum then
    limitCostNum = math.floor(hasMoney / self.uiData.priceNum)
  end
  if _isAddItem then
    if self.uiData.limitNum > 0 then
      if limitBuyNum > self.uiData.selectedNum and limitCostNum >= 1 then
        self.uiData.selectedNum = self.uiData.selectedNum + 1
        local moneycost = self.uiData.priceNum
        self:updateMoneyCost(self.uiData.shopItemId, self.uiData.selectedNum)
      elseif limitBuyNum >= self.uiData.selectedNum + limitCostNum then
        self.itemUseCount:SetText(tostring(limitCostNum))
        Log.Error("\232\180\167\229\184\129\228\184\141\232\182\1791", hasMoney, "xx", limitBuyNum, "xx", limitCostNum)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_1)
      else
        self.itemUseCount:SetText(tostring(limitBuyNum))
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_2)
      end
    elseif limitCostNum >= 1 then
      if self.uiData.selectedNum < self.uiData.selectedNum + limitCostNum then
        self.uiData.selectedNum = self.uiData.selectedNum + 1
      end
      local moneycost = self.uiData.priceNum
      self:updateMoneyCost(self.uiData.shopItemId, self.uiData.selectedNum)
    else
      self.itemUseCount:SetText(tostring(limitCostNum))
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_1)
    end
  else
    self.uiData.selectedNum = self.uiData.selectedNum - 1
    if self.uiData.selectedNum < 0 then
      self.uiData.selectedNum = 0
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_12)
    else
      local moneycost = self.uiData.priceNum
      self:updateMoneyCost(self.uiData.shopItemId, self.uiData.selectedNum)
    end
  end
  local itemcnt = self.uiData.selectedNum
  self.itemUseCount:SetText(tostring(itemcnt))
end

function UMG_NPCShopItem_1_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self:UpdateInfo()
end

function UMG_NPCShopItem_1_C:SetDataUnShow(_data)
  self.uiData.npcBuyCoinCost = _data[1]
  self.uiData.npcBuyDiamondCost = _data[2]
end

function UMG_NPCShopItem_1_C:updateTimeCountDown(svr_time)
  if not self.uiData then
    return
  end
  local next_refresh_time = self.uiData.next_refresh_time
  if nil == next_refresh_time or 0 == next_refresh_time then
    return
  end
  local IsNeedRefresh = self.uiData.ShopResetType
  if nil == next_refresh_time or 0 == IsNeedRefresh then
    return
  end
  if self.uiData.next_refresh_time == self.uiData.last_refresh_time then
    return
  end
  self.deltaTime = next_refresh_time - svr_time
  if self.deltaTime then
    if self.deltaTime > 0 then
      local days = math.floor(self.deltaTime / 60 / 60 / 24)
      local hours = math.floor((self.deltaTime - days * 24 * 3600) / 3600)
      local minutes = math.floor((self.deltaTime - days * 24 * 3600 - hours * 3600) / 60)
      self:SetTimeCountDown(days, hours, minutes)
    else
      local ShopConf = _G.DataConfigManager:GetShopConf(self.uiData.npcShopId)
      if ShopConf and ShopConf.shop_type == Enum.ShopType.ST_RANDOM_SHOP then
        local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
        local npcshopModule = _G.NRCModuleManager:GetModule("NPCShopUIModule")
        if bigMapModule and npcshopModule then
          local npcRefreshId = npcshopModule.data:GetNPCContentID(self.uiData.npcShopId)
          local CanBuy = bigMapModule.data:CanShowRandomShopHint(npcRefreshId)
          if not CanBuy then
            npcshopModule:CloseNPCShopPanel()
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.random_shop_timeout_tips_1)
            return
          end
        end
      end
      if self.reqCount < self.reqMaxCount then
        self:timeOutGetStoreListReq()
        self.reqCount = self.reqCount + 1
      else
        Log.Warning("\229\149\134\229\186\151\230\149\176\230\141\174\232\175\183\230\177\130\230\172\161\230\149\176\232\182\133\232\191\13510\230\172\161\239\188\140\233\156\128\232\166\129\230\159\165\231\156\139\230\149\176\230\141\174\230\152\175\229\144\166\230\173\163\229\184\184")
      end
    end
  end
end

function UMG_NPCShopItem_1_C:timeOutGetStoreListReq()
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdSetUpdateTimeOut)
end

function UMG_NPCShopItem_1_C:OnBtnAddPressed()
  self.IsAddClick = true
  self.IsAdd = true
  _G.UpdateManager:Register(self)
end

function UMG_NPCShopItem_1_C:SetTimeCountDown(days, hours, minutes)
  local shopConf = _G.DataConfigManager:GetShopConf(self.uiData.npcShopId)
  if shopConf and shopConf.shop_type == _G.Enum.ShopType.ST_RANDOM_SHOP then
    self:TickMysteriousStoreItemCountDown()
    return
  end
  local text = ""
  if days > 0 then
    text = string.format("%d\229\164\169%d\229\176\143\230\151\182", days, hours)
  elseif hours > 0 then
    text = string.format("%d\229\176\143\230\151\182%d\229\136\134\233\146\159", hours, minutes)
  elseif minutes > 0 then
    text = string.format("0\229\176\143\230\151\182%d\229\136\134\233\146\159", minutes)
  else
    text = "\229\176\143\228\186\1421\229\136\134\233\146\159"
  end
  if self.CountDownText ~= text then
    self.CountDownText = text
    self.Time:SetText(text)
  end
end

function UMG_NPCShopItem_1_C:OnBtnAddReleased()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsAdd = false
  if self.IsAddClick then
    self:OnBtnAddItemClick()
  end
end

function UMG_NPCShopItem_1_C:ReleasedBtn()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsAdd = false
  self.IsDelItem = false
end

function UMG_NPCShopItem_1_C:OnBtnDelPressed()
  self.IsDelClick = true
  self.IsDelItem = true
  _G.UpdateManager:Register(self)
end

function UMG_NPCShopItem_1_C:OnBtnDelReleased()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsDelItem = false
  if self.IsDelClick then
    self:OnBtnDelItemClick()
  end
end

function UMG_NPCShopItem_1_C:OnTick(InDeltaTime)
  self.startAddFrame = self.startAddFrame + 1
  if self.startAddFrame >= self.EndAddFrame and self.IsAdd then
    self.IsAddClick = false
    self.startAddFrame = 0
    self.startDelFrame = 0
    self:OnBtnAddItemClick()
  end
  self.startDelFrame = self.startDelFrame + 1
  if self.startDelFrame >= self.EndDelFrame and self.IsDelItem then
    self.IsDelClick = false
    self.startAddFrame = 0
    self.startDelFrame = 0
    self:OnBtnDelItemClick()
  end
end

function UMG_NPCShopItem_1_C:setChangeNum(bool)
  if bool then
    self.Image_40:SetVisibility(UE4.ESlateVisibility.Visible)
    self.itemUseCount:SetVisibility(UE4.ESlateVisibility.Visible)
    self.btnSubItem:SetVisibility(UE4.ESlateVisibility.Visible)
    self.btnAddItem:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Image_40:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.itemUseCount:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.btnSubItem:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.btnAddItem:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_NPCShopItem_1_C:isSoldOut(bool)
  if bool then
    if 0 == self.uiData.limitNum then
      self.isUnlock = true
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif 0 == self.uiData.limitNum then
      self.isUnlock = true
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCSwitcher_0:SetActiveWidgetIndex(2)
    else
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      self.SoldOut = true
      self.Text_MaiWan:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif 0 == self.uiData.limitNum then
    self.isUnlock = true
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 0 == self.uiData.limitNum then
    self.isUnlock = true
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_0:SetActiveWidgetIndex(2)
    self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.SoldOut = false
    self.isUnlock = true
    self.Text_MaiWan:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NPCShopItem_1_C:UpdateInfo()
  local itemID = self.uiData.shopItemId
  local shopConf = _G.DataConfigManager:GetShopConf(self.uiData.npcShopId)
  local goodsConf = NPCShopUtils:GetAdjustGoodConf(itemID, self.uiData.npcShopId)
  if nil == goodsConf then
    return
  end
  self.itemUseCount:SetText(self.uiData.selectedNum)
  if self.uiData.AlreadyHasItem then
    self.Text_MaiWan:SetText(LuaText.tailor_owned_btn)
  else
    self.Text_MaiWan:SetText(LuaText.goods_soldout)
  end
  local isLimit = 0
  local limitLevel = 0
  isLimit = goodsConf.buy_cond_type or 0
  limitLevel = goodsConf.buy_cond_param or 0
  if isLimit == _G.Enum.BuyLimited.BL_PLAYER_LEVEL then
    if self.uiData.can_buy then
      local limit = math.floor(tonumber(limitLevel))
      if limit > DataModelMgr.PlayerDataModel:GetPlayerLevel() then
        self:setChangeNum(false)
        self:isSoldOut(false)
      elseif self.uiData.limitNum > 0 and self.uiData.limitNum <= self.uiData.boughtNum then
        self:setChangeNum(false)
        self:isSoldOut(true)
      else
        self:setChangeNum(true)
        self:isSoldOut(false)
      end
    elseif self.uiData.limitNum > 0 and self.uiData.limitNum <= self.uiData.boughtNum then
      self:setChangeNum(false)
      self:isSoldOut(true)
    else
      if self.uiData.AlreadyHasItem then
        self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      else
        self.NRCSwitcher_0:SetActiveWidgetIndex(2)
      end
      self:setChangeNum(false)
      self.isUnlock = false
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_MaiWan:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif not self.uiData.can_buy then
    if self.uiData.limitNum > 0 and self.uiData.limitNum <= self.uiData.boughtNum then
      self:setChangeNum(false)
      self:isSoldOut(true)
    else
      if self.uiData.AlreadyHasItem then
        self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      else
        self.NRCSwitcher_0:SetActiveWidgetIndex(2)
      end
      self:setChangeNum(false)
      self.isUnlock = false
      self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_MaiWan:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif self.uiData.limitNum > 0 and self.uiData.limitNum <= self.uiData.boughtNum then
    self:setChangeNum(false)
    self:isSoldOut(true)
  else
    self:setChangeNum(true)
    self:isSoldOut(false)
  end
  local refreshType = shopConf.shop_type ~= Enum.ShopType.ST_RANDOM_SHOP and goodsConf.reset_type or -1
  local leftBuyNum = self.uiData.limitNum - self.uiData.boughtNum
  if self.uiData.limitNum > 0 then
    self.Purchaselimit:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if refreshType == _G.Enum.TimeResetType.TRE_MINUTLY then
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_7)
      self.ItemPurchaselimit:SetText(leftBuyNum)
    elseif refreshType == _G.Enum.TimeResetType.TRE_HOURLY then
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_8)
      self.ItemPurchaselimit:SetText(leftBuyNum)
    elseif refreshType == _G.Enum.TimeResetType.TRE_DAILY then
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_9)
      self.ItemPurchaselimit:SetText(leftBuyNum)
    elseif refreshType == _G.Enum.TimeResetType.TRE_WEEKLY then
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_10)
      self.ItemPurchaselimit:SetText(leftBuyNum)
    elseif refreshType == _G.Enum.TimeResetType.TRE_MONTHLY then
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_11)
      self.ItemPurchaselimit:SetText(leftBuyNum)
    elseif refreshType == _G.Enum.TimeResetType.TRE_DAILY_FROM then
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_9)
      self.ItemPurchaselimit:SetText(self.uiData.limitNum)
    else
      self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_5)
      self.ItemPurchaselimit:SetText(leftBuyNum)
    end
  else
    self.Purchaselimit:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemPurchaselimit1:SetText(LuaText.umg_npcshopitem_1_6)
  end
  self.CostNum:SetText(tostring(self.uiData.priceNum))
  self.IconSwitcher:SetActiveWidgetIndex(0)
  if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
    if bagItemConf and nil ~= bagItemConf.big_icon then
      local path = NRCUtils:FormatConfIconPath(bagItemConf.big_icon, _G.UIIconPath.BagItemPath)
      self:SetIcon(path, bagItemConf)
    end
    self:getQuality(bagItemConf and bagItemConf.item_quality or 0)
  elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsConf.item_id)
    if vItemConf and nil ~= vItemConf.bigIcon then
      self.ItemIcon:SetPath(vItemConf.bigIcon)
      self:getQuality(vItemConf and vItemConf.item_quality or 0)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(goodsConf.item_id)
    if cardSkinConf then
      self:getQuality(cardSkinConf.card_quality)
      local path = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
      self.ItemIcon:SetPath(path)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_CARD_ICON then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(goodsConf.item_id)
    if cardIconConf then
      self:getQuality(cardIconConf.card_quality)
      local path = string.format("%s%s.%s", UEPath.CARD_HEAD_PATH, cardIconConf.icon_resource_path, cardIconConf.icon_resource_path)
      self.ItemIcon:SetPath(path)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_CARD_LABEL then
    local cardLabelConf = _G.DataConfigManager:GetCardLabelConf(goodsConf.item_id)
    if cardLabelConf then
      self:getQuality(cardLabelConf.card_quality)
      self.ItemIcon:SetPath(cardLabelConf.label_icon or UEPath.CARD_LABEL_PATH)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(goodsConf.item_id)
    if fashionConf then
      local grade = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
      self:getQuality(grade)
      self.ItemIcon:SetPath(fashionConf.suits_icon)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(goodsConf.item_id)
    if fashionConf then
      self:getQuality(fashionConf.item_quality)
      self.ItemIcon:SetPath(fashionConf.icon)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(goodsConf.item_id)
    if salonConf then
      self:getQuality(salonConf.item_quality)
      self.ItemIcon:SetPath(salonConf.icon)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_SHARE_FORM then
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(goodsConf.item_id)
    if shareConf then
      self:getQuality(shareConf.item_quality)
      self.ItemIcon:SetPath(shareConf.item_icon)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(goodsConf.item_id)
    if itemConf then
      self:getQuality(5)
      self.ItemIcon:SetPath(itemConf.icon_path)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_EMOJI then
    local chatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(goodsConf.item_id)
    if chatEmojiConf then
      self:getQuality(chatEmojiConf.card_quality)
      self.ItemIcon:SetPath(chatEmojiConf.emoji_goods_icon)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_PACKAGE then
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(goodsConf.item_id)
    if fashionPackageConf then
      self:getQuality(5)
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_BOND then
    local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(goodsConf.item_id)
    if fashionBondConf then
      self:getQuality(5)
      self.ItemIcon:SetPath(fashionBondConf.fashion_bond_icon)
    end
  end
  self.ItemName:SetText(goodsConf.goods_name)
  local icon = NPCShopUtils:GetGoodsCurrencyIconPath(self.uiData.npcShopId, itemID)
  if icon then
    self.CostIcon:SetPath(icon)
  else
    Log.Warning("UMG_NPCShopItem_1_C:UpdateInfo", "icon not found", self.uiData.npcShopId, itemID)
  end
  if self.uiData.RefreshResetType then
    local next_refresh_time = self.uiData.next_refresh_time
    if next_refresh_time then
      local CurServerTime = _G.ZoneServer:GetServerTime()
      if type(CurServerTime) == "number" then
        CurServerTime = math.floor(CurServerTime / 1000)
      end
      next_refresh_time = next_refresh_time - CurServerTime
      if next_refresh_time then
        if next_refresh_time > 0 then
          local days = math.floor(next_refresh_time / 60 / 60 / 24)
          local hours = math.floor((next_refresh_time - days * 24 * 3600) / 3600)
          local minutes = math.floor((next_refresh_time - days * 24 * 3600 - hours * 3600) / 60)
          self:SetTimeCountDown(days, hours, minutes)
        end
      else
        self:timeOutGetStoreListReq()
      end
    end
    self.HorizontalBox_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.HorizontalBox_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdataMysteriousStoreItem()
end

function UMG_NPCShopItem_1_C:getQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_NPCShopItem_1_C:OnBtnAddItemClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1072, "UMG_NPCShopItem_1_C:OnBtnAddItemClick")
  self.uiData.longpress = 0
  self:ClickBtnSelect()
  self:ChangeItemCount(true)
end

function UMG_NPCShopItem_1_C:OnBtnDelItemClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401008, "UMG_NPCShopItem_1_C:OnBtnDelItemClick")
  self.uiData.longpress = 0
  self:ClickBtnSelect()
  self:ChangeItemCount(false)
end

function UMG_NPCShopItem_1_C:OnBtnAddLongPress()
  self.uiData.longpress = 1
end

function UMG_NPCShopItem_1_C:OnBtnSubLongPress()
  self.uiData.longpress = 2
end

function UMG_NPCShopItem_1_C:changeLongPressAddItemNum()
  self.uiData.selectedNum = self.uiData.selectedNum + 1
  local itemID = self.uiData.shopItemId
  local goodsConf = NPCShopUtils:GetAdjustGoodConf(itemID, self.uiData.npcShopId)
  if nil == goodsConf then
    return
  end
  local limitBuyNum = self.uiData.limitNum - self.uiData.boughtNum
  local leftMoney = 0
  local hasMoney = 0
  local limitCostNum = 0
  if nil ~= self.uiData.priceNum and 0 ~= self.uiData.priceNum then
    limitCostNum = math.floor(hasMoney / self.uiData.priceNum)
  end
  if self.uiData.limitNum > 0 then
    if limitBuyNum >= self.uiData.selectedNum + limitCostNum then
      if self.uiData.selectedNum < self.uiData.selectedNum + limitCostNum - 1 then
        self.itemUseCount:SetText(self.uiData.selectedNum + 1)
      else
        self.uiData.selectedNum = self.uiData.selectedNum + limitCostNum - 1
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_1)
      end
    elseif limitBuyNum > self.uiData.selectedNum then
      self.itemUseCount:SetText(self.uiData.selectedNum + 1)
    else
      self.uiData.selectedNum = limitBuyNum
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_2)
    end
  elseif self.uiData.selectedNum < self.uiData.selectedNum + limitCostNum - 1 then
    Log.Debug("self.uiData.selectedNum", self.uiData.selectedNum, "xx", limitCostNum)
    self.itemUseCount:SetText(self.uiData.selectedNum + 1)
  else
    self.uiData.selectedNum = self.uiData.selectedNum + limitCostNum - 1
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_1)
  end
  local moneycost = self.uiData.selectedNum * self.uiData.priceNum
  self:updateMoneyCost(self.uiData.shopItemId, self.uiData.selectedNum)
end

function UMG_NPCShopItem_1_C:changeLongPressSubItemNum()
  self.uiData.selectedNum = self.uiData.selectedNum - 1
  if self.uiData.selectedNum >= 0 then
    self.itemUseCount:SetText(self.uiData.selectedNum)
  else
    self.itemUseCount:SetText("0")
    self.uiData.selectedNum = 0
  end
  self:updateMoneyCost(self.uiData.shopItemId, self.uiData.selectedNum)
end

function UMG_NPCShopItem_1_C:updateMoneyCost(itemID, selectedNum)
  NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.NPCSHOP_UI_REFRESH_MONEY_COST, itemID, selectedNum)
end

function UMG_NPCShopItem_1_C:OnAnimationFinished(Animation)
  if Animation == self.change1 then
    self:PlayAnimation(self.select)
  elseif Animation == self.chang2 then
    self:PlayAnimation(self.normal)
  end
end

function UMG_NPCShopItem_1_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_NPCShopItem_1_C:OnSelectionChange")
    if self.uiData.callbackCaller and self.uiData.callbackFunc then
      tcall(self.uiData.callbackCaller, self.uiData.callbackFunc, self, self.index)
    end
    self:PlayAnimation(self.change1)
    self.isSelected = true
    self:OnBtnState(true)
    if not self.SoldOut then
      if not self.uiData.can_buy then
        self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
        self.ItemBG_SelectedMI_1:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
        NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.SoldOutBtnState, false, self.isUnlock, self.uiData.SoldOut_goodsNameList, {
          limitType = self.uiData.limitType,
          limitBuyParam = self.uiData.limitBuyParam,
          buy_cond_param = self.uiData.buy_cond_param
        }, self.uiData.AlreadyHasItem)
        return
      end
      self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ItemBG_SelectedMI_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.SoldOutBtnState, false, self.isUnlock)
    else
      self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      self.ItemBG_SelectedMI_1:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.SoldOutBtnState, true, self.isUnlock)
    end
  else
    self:PlayAnimation(self.chang2)
    self.isSelected = false
    self:OnBtnState(false)
  end
end

function UMG_NPCShopItem_1_C:ChangeCostMoney(coin, diamond)
  self.uiData.sumCoinCost = coin
  self.uiData.sumDiamondCost = diamond
end

function UMG_NPCShopItem_1_C:ClickBtnSelect()
  if self.uiData and self.uiData.callbackCaller and self.uiData.callbackFuncClcikBtn then
    tcall(self.uiData.callbackCaller, self.uiData.callbackFuncClcikBtn, self.index)
  else
    Log.Error("self.uiData\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_NPCShopItem_1_C:OnBtnState(select)
  if select then
    self.NRCImageasubNor:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImageAddNor:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImagesubDis:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.NRCImageAddDis:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    self.NRCImageasubNor:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.NRCImageAddNor:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.NRCImagesubDis:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImageAddDis:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_NPCShopItem_1_C:OnDeactive()
end

function UMG_NPCShopItem_1_C:UpdataMysteriousStoreItem()
  local shopConf = _G.DataConfigManager:GetShopConf(self.uiData.npcShopId)
  if shopConf and shopConf.shop_type ~= _G.Enum.ShopType.ST_RANDOM_SHOP then
    return
  end
  local IsSpecial = self.uiData.isSpecial
  if IsSpecial then
    self.HotSelling:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.HotSelling:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.uiData.limitNum then
    self.Purchaselimit:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.uiData.limitNum == self.uiData.boughtNum then
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    end
  else
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdataMysteriousStoreItemCountDown()
end

function UMG_NPCShopItem_1_C:UpdataMysteriousStoreItemCountDown()
  local shopConf = _G.DataConfigManager:GetShopConf(self.uiData.npcShopId)
  if shopConf and shopConf.shop_type ~= _G.Enum.ShopType.ST_RANDOM_SHOP then
    return
  end
  self.HorizontalBox_3:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.uiData.next_refresh_time and 0 == self.uiData.next_refresh_time and self.uiData.disable_time and 0 ~= self.uiData.disable_time then
    self.uiData.next_refresh_time = self.uiData.disable_time
  end
  self:TickMysteriousStoreItemCountDown()
end

function UMG_NPCShopItem_1_C:TickMysteriousStoreItemCountDown()
  local shopConf = _G.DataConfigManager:GetShopConf(self.uiData.npcShopId)
  if shopConf and shopConf.shop_type ~= _G.Enum.ShopType.ST_RANDOM_SHOP then
    return
  end
  local nowTime = _G.ZoneServer:GetServerTime() / 1000
  local next_refresh_time = self.uiData.next_refresh_time
  if next_refresh_time then
    local leftTime = next_refresh_time - nowTime
    self.Time:SetText(UIUtils.FormatTimeStringToDay(leftTime))
  end
end

function UMG_NPCShopItem_1_C:SetIcon(icon_path, bag_item_conf)
  if icon_path and bag_item_conf and bag_item_conf.type == _G.Enum.BagItemType.BI_PET_EGG and bag_item_conf.item_behavior and bag_item_conf.item_behavior[1] and bag_item_conf.item_behavior[1].ratio2 and bag_item_conf.item_behavior[1].ratio2[1] then
    local eggInfo = {}
    eggInfo.random_egg_conf = bag_item_conf.item_behavior[1].ratio2[1]
    self.IconSwitcher:SetActiveWidgetIndex(1)
    self.PetEggIcon:SetEggIcon(eggInfo, icon_path)
    return
  end
  if icon_path then
    self.IconSwitcher:SetActiveWidgetIndex(0)
    self.ItemIcon:SetPath(icon_path)
  end
end

return UMG_NPCShopItem_1_C

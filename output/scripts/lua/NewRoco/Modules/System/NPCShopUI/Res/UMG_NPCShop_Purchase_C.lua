local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local UMG_NPCShop_Purchase_C = _G.NRCPanelBase:Extend("UMG_NPCShop_Purchase_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")

function UMG_NPCShop_Purchase_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
  self.uiData = {}
  self.shopUiData = {}
  self.data = {}
  self.curSelectedIndex = nil
  self.buyCount = 1
  self.startAddFrame = 0
  self.EndAddFrame = 8
  self.startDelFrame = 0
  self.EndDelFrame = 8
  self.IsAdd = false
  self.IsDelItem = false
  self.IsAddClick = false
  self.IsDelClick = false
  self.SoldOut = false
  self.hasShownLimitTip = false
  self.hasShownMinTip = false
  self.isButtonProcessing = false
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOPPURCHASE_CLOSE, self.BuySuccess)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOPCONFIRM_OPEN, self.DoClose)
  self:RegisterEvent(self, NPCShopUIModuleEvent.OnReceiveMallBuyItemRspHandler, self.OnReceiveMallBuyItemRspHandler)
end

function UMG_NPCShop_Purchase_C:OnDestruct()
  _G.UpdateManager:UnRegister(self)
end

function UMG_NPCShop_Purchase_C:OnActive(_param, _param1, _param2, _param3, ...)
  if nil == _param then
    Log.Info("UMG_NPCShop_Purchase_C:OnActive _param is nil")
    return
  end
  local shopConf = _G.DataConfigManager:GetShopConf(_param.npcShopId)
  if nil == shopConf then
    return
  end
  self.uiData = _param
  self.shopUiData = _param1
  local NPCShopUIModule = _G.NRCModuleManager:GetModule("NPCShopUIModule")
  self.module = NPCShopUIModule
  self.moduleData = self.module:GetData("NPCShopUIModuleData")
  self.data = _param2
  self.curSelectedIndex = _param3
  self.uiData.ShopType = shopConf.shop_type
  self.lastBuildValue = -1
  self:OnAddEventListener()
  self:SetCommonPopUpInfo()
  self:SetCommonAddSubtractInfo()
  self:SetUpInfos(shopConf.shop_type)
  self:LoadAnimation(0)
end

function UMG_NPCShop_Purchase_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = _G.DataConfigManager:GetLocalizationConf("shop_purchase_title").msg
  CommonPopUpData.Btn_LeftText = _G.DataConfigManager:GetLocalizationConf("shop_cancel").msg
  CommonPopUpData.Btn_RightText = _G.DataConfigManager:GetLocalizationConf("shop_confirm").msg
  CommonPopUpData.ClosePanelHandler = self.OnBtnCloseClick
  CommonPopUpData.Btn_LeftHandler = self.OnBtnCloseClick
  CommonPopUpData.Btn_RightHandler = self.OnBtnBuyClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_NPCShop_Purchase_C:SetCommonAddSubtractInfo()
  local SliderInfo = {num1 = 0, num2 = 0}
  local ProgressBarInfo = {num1 = 0, num2 = 0}
  local CommonAddSubtractData = _G.NRCCommonAddSubtractData()
  CommonAddSubtractData.SliderInfo = SliderInfo
  CommonAddSubtractData.ProgressBarInfo = ProgressBarInfo
  CommonAddSubtractData.AddBtnPressedHandler = self.OnBtnAddPressed
  CommonAddSubtractData.AddBtnReleasedHandler = self.OnBtnAddReleased
  CommonAddSubtractData.SubtractBtnPressedHandler = self.OnBtnDelPressed
  CommonAddSubtractData.SubtractBtnReleasedHandler = self.OnBtnDelReleased
  CommonAddSubtractData.SliderHandler = self.OnSliderValueChanged
  CommonAddSubtractData.Call = self
  self.AddSubtract_White:SetPanelInfo(CommonAddSubtractData)
end

function UMG_NPCShop_Purchase_C:OnDeactive()
end

function UMG_NPCShop_Purchase_C:OnPcClose()
  self:OnBtnCloseClick()
end

function UMG_NPCShop_Purchase_C:SetUpInfos(shopType)
  local itemID = self.uiData.shopItemId
  self.BuyText:SetText(_G.DataConfigManager:GetLocalizationConf("shop_purchase_num").msg)
  self.CostTotalText:SetText(_G.DataConfigManager:GetLocalizationConf("shop_cost_total").msg)
  local goodsCurrencyType, goodsCurrencyId = NPCShopUtils:GetGoodsCurrencyTypeAndId(self.uiData.npcShopId, itemID)
  local moneyNum = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, itemID)
  moneyNum = moneyNum or 0
  local MoneyDatas = {
    {
      moneyType = goodsCurrencyId,
      sum = moneyNum,
      currencyType = goodsCurrencyType,
      currencyId = goodsCurrencyId
    }
  }
  self.MoneyBtn:InitGridView(MoneyDatas)
  local ownedNum = 0
  local color, iconPath
  local name = ""
  local desc = ""
  local typeName = ""
  local bagItemConf
  if shopType == Enum.ShopType.ST_FASHION_TAILOR then
    local suitConf = DataConfigManager:GetFashionSuitsConf(self.uiData.itemId)
    if nil == suitConf then
      return
    end
    name = suitConf.name
    iconPath = suitConf.suits_icon
    color = AppearanceUtils:GetSuitGradeColor(suitConf.suit_grade)
    desc = suitConf.flavor_text
    self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local goodsConf = NPCShopUtils:GetAdjustGoodConf(itemID, self.uiData.npcShopId)
    if nil == goodsConf then
      return
    end
    if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
      local itemData = NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, goodsConf.item_id)
      if nil ~= itemData then
        ownedNum = itemData.num
      end
      bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
      if bagItemConf and nil ~= bagItemConf.big_icon then
        iconPath = NRCUtils:FormatConfIconPath(bagItemConf.big_icon, _G.UIIconPath.BagItemPath)
      end
      typeName = bagItemConf.type_desc
      name = bagItemConf.name
      desc = bagItemConf.description
      color = self:GetQualityColor(bagItemConf and bagItemConf.item_quality or 0)
      self.hasCount:SetText(ownedNum)
    elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsConf.item_id)
      local vItemNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(vItemConf.id)
      if vItemConf and nil ~= vItemConf.bigIcon then
        iconPath = vItemConf.bigIcon
      end
      typeName = vItemConf.type_desc
      name = goodsConf.goods_name
      desc = vItemConf.discription
      color = self:GetQualityColor(vItemConf and vItemConf.item_quality or 0)
      self.hasCount:SetText(vItemNum)
    elseif goodsConf.Type == Enum.GoodsType.GT_CARD_SKIN then
      local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(goodsConf.item_id)
      if cardSkinConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
        color = self:GetQualityColor(cardSkinConf.card_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_CARD_ICON then
      local cardIconConf = _G.DataConfigManager:GetCardIconConf(goodsConf.item_id)
      if cardIconConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = string.format("%s%s.%s", UEPath.CARD_HEAD_PATH, cardIconConf.icon_resource_path, cardIconConf.icon_resource_path)
        color = self:GetQualityColor(cardIconConf.card_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_CARD_LABEL then
      local cardLabelConf = _G.DataConfigManager:GetCardLabelConf(goodsConf.item_id)
      if cardLabelConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = cardLabelConf.label_icon or UEPath.CARD_LABEL_PATH
        color = self:GetQualityColor(cardLabelConf.card_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_SUITS then
      local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(goodsConf.item_id)
      if fashionConf then
        typeName = fashionConf.grade_name
        name = goodsConf.goods_name
        desc = fashionConf.flavor_text
        iconPath = fashionConf.suits_icon
        color = AppearanceUtils:GetSuitGradeColor(fashionConf.suit_grade)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if desc and "" ~= desc then
        self.NRCImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    elseif goodsConf.Type == Enum.GoodsType.GT_FASHION then
      local fashionConf = _G.DataConfigManager:GetFashionItemConf(goodsConf.item_id)
      if fashionConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = fashionConf.icon
        color = self:GetQualityColor(fashionConf.item_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_SALON then
      local salonConf = _G.DataConfigManager:GetSalonItemConf(goodsConf.item_id)
      if salonConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = salonConf.icon
        color = self:GetQualityColor(salonConf.item_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_SHARE_FORM then
      local shareConf = _G.DataConfigManager:GetPetShareItemConf(goodsConf.item_id)
      if shareConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = shareConf.item_icon
        color = self:GetQualityColor(shareConf.item_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_RP_BEHAVIOR then
      local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(goodsConf.item_id)
      if itemConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = itemConf.icon_path
        color = self:GetQualityColor(5)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_EMOJI then
      local chatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(goodsConf.item_id)
      if chatEmojiConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = chatEmojiConf.emoji_goods_icon
        color = self:GetQualityColor(chatEmojiConf.card_quality)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_PACKAGE then
      local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(goodsConf.item_id)
      if fashionPackageConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        color = self:GetQualityColor(5)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_BOND then
      local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(goodsConf.item_id)
      if fashionBondConf then
        typeName = ""
        name = goodsConf.goods_name
        desc = ""
        iconPath = fashionBondConf.fashion_bond_icon
        color = self:GetQualityColor(5)
      end
      self.BackpackQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if shopType == Enum.ShopType.ST_FASHION_TAILOR then
    self.IconSwitcher:SetActiveWidgetIndex(1)
    self.ClothingIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ClothingIcon:SetPath(iconPath)
  else
    self.ClothingIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetIcon(iconPath, bagItemConf)
  end
  self.TimerTest:SetText(typeName)
  self.Title_1:SetText(name)
  self.ItemDesc_1:SetText(desc)
  if color then
    self.QualityColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
    self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.QualityColor:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local icon = NPCShopUtils:GetGoodsCurrencyIconPath(self.uiData.npcShopId, itemID)
  if icon then
    self.Gold_Icon:SetPath(icon)
  else
    Log.Warning("UMG_NPCShop_Purchase_C:SetCostNum", "icon not found", self.uiData.npcShopId, itemID)
  end
  self:SetCostNum()
end

function UMG_NPCShop_Purchase_C:SetCostNum()
  local moneyNum = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, self.uiData.shopItemId)
  moneyNum = moneyNum or 0
  if 0 == self.uiData.limitNum then
    local num1 = 1
    local num2 = 99
    local canBuyCount = math.floor(moneyNum / self.uiData.priceNum)
    if 0 ~= canBuyCount then
      self.AddSubtract_White:SetMultipleAddBtnText(num1)
      if num2 > canBuyCount then
        num2 = canBuyCount
      end
      self.AddSubtract_White:SetSelectNumText(num2)
      self:MySetProgressPercent(num1 - 1, num2 - 1)
      self.AddSubtract_White:SetSliderStepSize(1)
      self.AddSubtract_White:SetSliderValue(1)
      self.AddSubtract_White:SetSliderMinValue(num1)
      self.AddSubtract_White:SetSliderMaxValue(num2)
      self.BuildTimeText:SetText(1)
      self:AddSubtractDisableCheck()
    else
      self.AddSubtract_White:SetMultipleAddBtnText(0)
      self.AddSubtract_White:SetSelectNumText(1)
      self:MySetProgressPercent(0, 1)
      self.AddSubtract_White:SetSliderStepSize(1)
      self.AddSubtract_White:SetSliderValue(0)
      self.AddSubtract_White:SetSliderMinValue(0)
      self.AddSubtract_White:SetSliderMaxValue(1)
      self.AddSubtract_White:SetSliderVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BuildTimeText:SetText(0)
      self:AddSubtractDisableCheck()
      self.AddSubtract_White:SetSubtractBtnIsEnabledNewStyle(false)
    end
  else
    local num1 = 1
    local num2 = self.uiData.limitNum - self.uiData.boughtNum
    local canBuyCount = math.floor(moneyNum / self.uiData.priceNum)
    if 0 ~= canBuyCount then
      self.AddSubtract_White:SetMultipleAddBtnText(num1)
      if num2 > canBuyCount then
        num2 = canBuyCount
      end
      if 1 == canBuyCount or 1 == num2 then
        self.AddSubtract_White:SetSliderVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self.AddSubtract_White:SetSelectNumText(num2)
      self:MySetProgressPercent(num1 - 1, num2 - 1)
      self.AddSubtract_White:SetSliderStepSize(num1 / num2)
      self.AddSubtract_White:SetSliderValue(1)
      self.AddSubtract_White:SetSliderMinValue(num1)
      self.AddSubtract_White:SetSliderMaxValue(num2)
      self.BuildTimeText:SetText(1)
      self:AddSubtractDisableCheck()
    else
      self.AddSubtract_White:SetMultipleAddBtnText(0)
      self.AddSubtract_White:SetSelectNumText(1)
      self:MySetProgressPercent(0, 1)
      self.AddSubtract_White:SetSliderStepSize(1)
      self.AddSubtract_White:SetSliderValue(0)
      self.AddSubtract_White:SetSliderMinValue(0)
      self.AddSubtract_White:SetSliderMaxValue(1)
      self.AddSubtract_White:SetSliderVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BuildTimeText:SetText(0)
      self:AddSubtractDisableCheck()
      self.AddSubtract_White:SetSubtractBtnIsEnabledNewStyle(false)
    end
  end
  local costNum = self.uiData.priceNum * self.buyCount
  local hasMoney = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, self.uiData.shopItemId)
  if costNum <= hasMoney then
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("050505FF"))
    self.Money_1:SetText(costNum)
  else
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
    self.Money_1:SetText(costNum)
  end
end

function UMG_NPCShop_Purchase_C:GetQualityColor(quality)
  if 0 == quality then
  elseif 1 == quality then
    return UEPath.Color_QUALITY_1
  elseif 2 == quality then
    return UEPath.Color_QUALITY_2
  elseif 3 == quality then
    return UEPath.Color_QUALITY_3
  elseif 4 == quality then
    return UEPath.Color_QUALITY_4
  elseif 5 == quality then
    return UEPath.Color_QUALITY_5
  end
end

function UMG_NPCShop_Purchase_C:OnAddEventListener()
end

function UMG_NPCShop_Purchase_C:OnBtnAddPressed()
  self.IsAddClick = true
  self.IsAdd = true
  _G.UpdateManager:Register(self)
end

function UMG_NPCShop_Purchase_C:OnBtnAddReleased()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsAdd = false
  if self.IsAddClick then
    self:OnBtnAddItemClick()
  end
end

function UMG_NPCShop_Purchase_C:OnBtnDelPressed()
  self.IsDelClick = true
  self.IsDelItem = true
  _G.UpdateManager:Register(self)
end

function UMG_NPCShop_Purchase_C:OnBtnDelReleased()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsDelItem = false
  if self.IsDelClick then
    self:OnBtnDelItemClick()
  end
end

function UMG_NPCShop_Purchase_C:OnTick(InDeltaTime)
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

function UMG_NPCShop_Purchase_C:OnBtnAddItemClick()
  self.uiData.longpress = 0
  self:ChangeItemCount(true)
end

function UMG_NPCShop_Purchase_C:OnBtnDelItemClick()
  self.uiData.longpress = 0
  self:ChangeItemCount(false)
end

function UMG_NPCShop_Purchase_C:ChangeItemCount(_isAddItem)
  local itemID = self.uiData.shopItemId
  local limitBuyNum
  if 0 == self.uiData.limitNum then
    limitBuyNum = 99
  else
    limitBuyNum = self.uiData.limitNum - self.uiData.boughtNum
  end
  local hasMoney = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, self.uiData.shopItemId)
  local canBuyCount = math.floor(hasMoney / self.uiData.priceNum)
  if 0 ~= canBuyCount then
    if limitBuyNum > canBuyCount then
      limitBuyNum = canBuyCount
    end
    if _isAddItem then
      if limitBuyNum > self.buyCount then
        self.buyCount = self.buyCount + 1
        self.hasShownLimitTip = false
      else
        if not self.hasShownLimitTip then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_2)
          self.hasShownLimitTip = true
        end
        return
      end
      local costMoney = self.uiData.priceNum * self.buyCount
      if hasMoney >= costMoney then
        self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("050505FF"))
        self.Money_1:SetText(costMoney)
      else
        self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
        self.Money_1:SetText(costMoney)
      end
      if self.lastBuildValue ~= self.buyCount then
        UE4.UNRCAudioManager.Get():PlaySound2DAuto(1072, "UMG_NPCShopItem_1_C:OnBtnAddItemClick")
      end
      self.BuildTimeText:SetText(self.buyCount)
      self:AddSubtractDisableCheck()
      self:MySetProgressPercent(self.buyCount - 1, limitBuyNum - 1)
      self:SetSliderNum(self.buyCount)
    else
      if self.buyCount - 1 >= 1 then
        self.buyCount = self.buyCount - 1
        self.hasShownMinTip = false
      else
        if not self.hasShownMinTip then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_12)
          self.hasShownMinTip = true
        end
        return
      end
      local costMoney = self.uiData.priceNum * self.buyCount
      if hasMoney >= costMoney then
        self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("050505FF"))
        self.Money_1:SetText(costMoney)
      else
        self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
        self.Money_1:SetText(costMoney)
      end
      if self.lastBuildValue ~= self.buyCount then
        UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401008, "UMG_NPCShopItem_1_C:OnBtnDelItemClick")
      end
      self.BuildTimeText:SetText(self.buyCount)
      self:AddSubtractDisableCheck()
      self:MySetProgressPercent(self.buyCount - 1, limitBuyNum - 1)
      self:SetSliderNum(self.buyCount)
    end
  elseif _isAddItem then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_2)
    local costMoney = self.uiData.priceNum
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
    self.Money_1:SetText(costMoney)
    self.BuildTimeText:SetText(0)
    self:AddSubtractDisableCheck()
    self:MySetProgressPercent(0, 1)
    self:SetSliderNum(0)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_12)
    local costMoney = self.uiData.priceNum
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
    self.Money_1:SetText(costMoney)
    self.BuildTimeText:SetText(0)
    self:AddSubtractDisableCheck()
    self:MySetProgressPercent(0, 1)
    self:SetSliderNum(0)
  end
end

function UMG_NPCShop_Purchase_C:AddSubtractDisableCheck()
  if self.buyCount <= self.AddSubtract_White:GetSliderMinValue() then
    self.AddSubtract_White:SetSubtractBtnIsEnabledNewStyle(false)
  else
    self.AddSubtract_White:SetSubtractBtnIsEnabledNewStyle(true)
  end
  if self.buyCount >= self.AddSubtract_White:GetSliderMaxValue() then
    self.AddSubtract_White:SetAddBtnIsEnabledNewStyle(false)
  else
    self.AddSubtract_White:SetAddBtnIsEnabledNewStyle(true)
  end
end

function UMG_NPCShop_Purchase_C:OnSliderValueChanged(value)
  local progressValue = value
  value = math.floor(value)
  if self.lastBuildValue ~= value then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40007002, "UMG_NPCShop_Purchase_C:OnSliderValueChanged")
  end
  self.buyCount = value
  local limitBuyNum
  if 0 == self.uiData.limitNum then
    limitBuyNum = 99
  else
    limitBuyNum = self.uiData.limitNum - self.uiData.boughtNum
  end
  local moneyNum = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, self.uiData.shopItemId)
  moneyNum = moneyNum or 0
  local costMoney = self.uiData.priceNum * self.buyCount
  local canBuyCount = math.floor(moneyNum / self.uiData.priceNum)
  if 0 ~= canBuyCount then
    if limitBuyNum > canBuyCount then
      limitBuyNum = canBuyCount
    end
    self.Money_1:SetText(costMoney)
    self.BuildTimeText:SetText(self.buyCount)
    self:AddSubtractDisableCheck()
    self:SetSliderNum(self.buyCount)
    self:MySetProgressPercent(self.buyCount - 1, limitBuyNum - 1)
    local hasMoney = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, self.uiData.shopItemId)
    if costMoney <= hasMoney then
      self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("050505FF"))
    else
      self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
    end
  else
    self.Money_1:SetText(self.uiData.priceNum)
    self.BuildTimeText:SetText(0)
    self:AddSubtractDisableCheck()
    self:MySetProgressPercent(0, 1)
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("c7494a"))
    self:SetSliderNum(0)
  end
end

function UMG_NPCShop_Purchase_C:SetSliderNum(value)
  self.AddSubtract_White:SetSliderValue(value)
  self.lastBuildValue = value
end

function UMG_NPCShop_Purchase_C:OnBtnCloseClick()
  if self.isButtonProcessing or self.WaitMallBuyItemRsp then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_NPCShop_Purchase_C:OnBtnCloseClick")
  self.isButtonProcessing = true
  if self.uiData then
    local shopConf = DataConfigManager:GetShopConf(self.uiData.npcShopId)
    if shopConf and shopConf.shop_type == Enum.ShopType.ST_FASHION_TAILOR then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1179, "UMG_NPCShop_Purchase_C:OnBtnCloseClick")
    else
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1061, "UMG_NPCShop_Purchase_C:OnBtnCloseClick")
    end
  end
  local _closeAnim = self:GetAnimByIndex(2)
  if nil ~= _closeAnim then
    if not self:IsAnimationPlaying(_closeAnim) then
      self:LoadAnimation(2)
    end
  else
    self:DoClose()
  end
  self.hasShownLimitTip = false
  self.hasShownMinTip = false
end

function UMG_NPCShop_Purchase_C:BuySuccess()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1220002049, "UMG_NPCShop_Purchase_C:BuySuccess")
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopConfirm, self.shopUiData, self.data)
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.HideOrShowNPCShopMoneyBtn, true)
  _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.HideOrShowTailorShopMoneyBtn, true)
  self.WaitMallBuyItemRsp = false
end

function UMG_NPCShop_Purchase_C:OnBtnBuyClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_NPCShop_Purchase_C:OnBtnBuyClick")
  if self.isButtonProcessing or self.WaitMallBuyItemRsp then
    return
  end
  self.isButtonProcessing = true
  local itemID = self.uiData.shopItemId
  if self.uiData.ShopType == Enum.ShopType.ST_RANDOM_SHOP then
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      local npcRefreshId = self.module.data:GetNPCContentID(self.uiData.npcShopId)
      local CanBuy = bigMapModule.data:CanShowRandomShopHint(npcRefreshId)
      if not CanBuy then
        self:DoClose()
        local npcshopModule = _G.NRCModuleManager:GetModule("NPCShopUIModule")
        if npcshopModule then
          npcshopModule:CloseNPCShopPanel()
        end
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.random_shop_timeout_tips_1)
        self.isButtonProcessing = false
        return
      end
      local goodsData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.uiData.npcShopId, itemID)
      if not goodsData then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2046)
        self.isButtonProcessing = false
        return
      end
    end
  end
  local hasMoney = NPCShopUtils:GetGoodsCurrencyNum(self.uiData.npcShopId, itemID)
  local costMoney = self.uiData.priceNum * self.buyCount
  if hasMoney >= costMoney then
    local itemList = {}
    self.uiData.selectedNum = self.buyCount
    self.shopUiData.itemList1[self.curSelectedIndex].selectedNum = self.buyCount
    table.insert(itemList, self.uiData)
    self.WaitMallBuyItemRsp = true
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.MallBuyItemReq, self.uiData.npcShopId, itemList)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_npcshopitem_1_1)
    self.isButtonProcessing = false
  end
end

function UMG_NPCShop_Purchase_C:OnReceiveMallBuyItemRspHandler()
  self.WaitMallBuyItemRsp = false
  self.isButtonProcessing = false
end

function UMG_NPCShop_Purchase_C:MySetProgressPercent(num1, num2)
  if 0 == num2 then
    self.AddSubtract_White:SetProgressBarPercent(1)
  else
    self.AddSubtract_White:SetProgressBarPercent(num1 / num2)
  end
end

function UMG_NPCShop_Purchase_C:OnAnimationFinished(aim)
  local _openAnim = self:GetAnimByIndex(0)
  if aim == _openAnim then
    self:PlayAnimation(self:GetAnimByIndex(1), 0, 0)
  elseif aim == self:GetAnimByIndex(2) then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.HideOrShowNPCShopMoneyBtn, true)
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.HideOrShowTailorShopMoneyBtn, true)
    self.isButtonProcessing = false
    self:DoClose()
  end
end

function UMG_NPCShop_Purchase_C:SetIcon(icon_path, bag_item_conf)
  if icon_path and bag_item_conf and bag_item_conf.type == _G.Enum.BagItemType.BI_PET_EGG and bag_item_conf.item_behavior and bag_item_conf.item_behavior[1] and bag_item_conf.item_behavior[1].ratio2 and bag_item_conf.item_behavior[1].ratio2[1] then
    local eggInfo = {}
    eggInfo.random_egg_conf = bag_item_conf.item_behavior[1].ratio2[1]
    self.IconSwitcher:SetActiveWidgetIndex(2)
    self.PetEggIcon:SetEggIcon(eggInfo, icon_path)
    return
  end
  if icon_path then
    self.IconSwitcher:SetActiveWidgetIndex(0)
    self.Icon:SetPath(icon_path)
  end
end

return UMG_NPCShop_Purchase_C

local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ShopModuleEvent = reload("NewRoco.Modules.System.Shop.ShopModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local UMG_ShopItemTemplate_C = Base:Extend("UMG_ShopItemTemplate_C")
local ShopItemFilename = "ShopItem"

function UMG_ShopItemTemplate_C:OnConstruct()
end

function UMG_ShopItemTemplate_C:OnDestruct()
end

function UMG_ShopItemTemplate_C:OnItemUpdate(_data, datalist, index)
  if self.ParticleSystemWidget then
    self.ParticleSystemWidget:SetActivate(false)
    if 0 ~= math.fmod(index, 2) or 1 == index then
      self.ParticleSystemWidget:SetActivate(true)
    end
  end
  local Rand = math.random(1, 3)
  self.CanvasPanel_180:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self["open_" .. Rand] then
    self.CanvasPanel_180:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self["open_" .. Rand])
  end
  self.uiData = _data
  self.index = index
  self.TitleSwitcher:SetActiveWidgetIndex(0)
  self.LevelPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Image_zhegai_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCImage_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Text_MaiWan:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.MoneyBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PromotionCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.LimitStockCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.DownCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
  local GoodsShopConf = GoodsConf
  self.GoodsShopConf = GoodsShopConf
  local GoodsData = self.uiData.originalGoodsData
  local GoodsType = GoodsConf.Type
  local ItemId = GoodsConf.item_id
  local ShowIcon = GoodsConf.icon
  if GoodsShopConf.shop_id == 8070 then
    local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and 2 == localPlayer.gender then
      local globalConfigKey = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGlobalConfigKeyByNum, GoodsConf.id)
      if globalConfigKey then
        local globalConfig = _G.DataConfigManager:GetGlobalConfig(globalConfigKey)
        if globalConfig and globalConfig.str and globalConfig.str ~= "" then
          ShowIcon = globalConfig.str
        end
      end
    end
  end
  local ShowBg = GoodsConf.background
  local ShowName = GoodsConf.goods_name
  local CostType = 0
  local CostGoodType = Enum.GoodsType.GT_NONE
  local Price = 0
  if GoodsData.real_price ~= nil then
    CostType = GoodsData.real_price.goods_id or 0
    CostGoodType = GoodsData.real_price.goods_type or Enum.GoodsType.GT_NONE
    Price = GoodsData.real_price.num or 0
  else
    Log.Error("UMG_ShopItemTemplate_C:OnItemUpdate GoodsData.real_price is nil")
  end
  local quantity = GoodsConf.item_num
  local LimitBuyNum = GoodsData.limit_buy_num or 0
  local shoplist = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MALL_FRAME_CONF):GetAllDatas()
  local PromotionShopType
  for i = 1, #shoplist do
    if shoplist[i].shop_id == GoodsShopConf.shop_id then
      PromotionShopType = shoplist[i].mall_type
    end
  end
  if not ShowBg and CostGoodType == Enum.GoodsType.GT_VITEM and CostType == Enum.VisualItem.VI_MONEY then
    ShowBg = UEPath.SHOPM_QUALITY_5
  end
  local goodsCurrencyType, goodsCurrencyId = NPCShopUtils:GetGoodsCurrencyTypeAndId(self.GoodsShopConf.shop_id, GoodsConf.id)
  local ViCount = NPCShopUtils:GetGoodsCurrencyNum(self.GoodsShopConf.shop_id, GoodsConf.id)
  local CyIcon = NPCShopUtils:GetGoodsCurrencyIconPath(self.GoodsShopConf.shop_id, GoodsConf.id, true)
  CostType = goodsCurrencyId
  self:SetIconAndQualityAndName(GoodsType, ItemId, ShowIcon, ShowBg, ShowName, CostType, Price, PromotionShopType, CyIcon, ViCount, CostGoodType)
  local canBuy = self.uiData.canBuy
  local limitBuyType = self.uiData.limitBuyType
  local limitParam = GoodsConf.buy_cond_param
  local PurchaseLimit = self.uiData.PurchaseLimit
  local RemainNum = LimitBuyNum - self.uiData.boughtNum
  local LimitStockString
  if PurchaseLimit then
    LimitStockString = tostring(RemainNum) .. "/" .. tostring(LimitBuyNum)
  end
  local PromotionType = GoodsConf.promotion_type
  local PromotionParam = GoodsConf.type_param
  local discount = GoodsConf.price ~= GoodsConf.origin_price
  self:SetPromotionInfo(discount, PromotionType, PromotionParam, GoodsConf.origin_price, CostType, CostGoodType)
  self:SetLimitBuyBg(canBuy, limitBuyType, LimitStockString, limitParam)
  self:updateTimeCountDown(_G.ZoneServer:GetServerTime() / 1000)
  local isShowRed = GoodsShopConf.add_red_point
  if isShowRed then
    local ShopItemFile = JsonUtils.LoadSaved(ShopItemFilename, {})
    local isClickShowRed = ShopItemFile[tostring(self.uiData.shopLibId)]
    if not isClickShowRed then
      local ShopModule = _G.NRCModuleManager:GetModule("ShopModule")
      local shopId = ShopModule:GetData("ShopModuleData"):GetShopId()
      self.RedDot:SetupKey(378, {
        shopId,
        self.uiData.shopLibId
      })
    else
      self.RedDot:SetupKey(0)
    end
  else
    self.RedDot:SetupKey(0)
  end
end

function UMG_ShopItemTemplate_C:SetIconAndQualityAndName(Type, ID, IconPath, BgPath, Name, CostType, Price, PromotionShopType, CyIcon, ViCount, CostGoodType)
  local _IconPath, _BgQuality
  self.Money_1:SetText(Name)
  self.Money_11:SetText(Name)
  local nameLen = Name and #Name or 0
  local targetFontSize = nameLen > 21 and 22 or 28
  local fontInfo1 = UE4.FSlateFontInfo()
  fontInfo1.Size = targetFontSize
  fontInfo1.FontMaterial = self.Money_1.Font.FontMaterial
  fontInfo1.FontObject = self.Money_1.Font.FontObject
  fontInfo1.LetterSpacing = self.Money_1.Font.LetterSpacing
  fontInfo1.OutlineSettings = self.Money_1.Font.OutlineSettings
  fontInfo1.TypefaceFontName = self.Money_1.Font.TypefaceFontName
  self.Money_1:SetFont(fontInfo1)
  local fontInfo11 = UE4.FSlateFontInfo()
  fontInfo11.Size = targetFontSize
  fontInfo11.FontMaterial = self.Money_11.Font.FontMaterial
  fontInfo11.FontObject = self.Money_11.Font.FontObject
  fontInfo11.LetterSpacing = self.Money_11.Font.LetterSpacing
  fontInfo11.OutlineSettings = self.Money_11.Font.OutlineSettings
  fontInfo11.TypefaceFontName = self.Money_11.Font.TypefaceFontName
  self.Money_11:SetFont(fontInfo11)
  if Type == Enum.GoodsType.GT_REWARD then
    local RewardConf = _G.DataConfigManager:GetRewardConf(ID)
    local quality = 2
    if RewardConf then
      for i = 1, #RewardConf.RewardItem do
        local icon, _quality = NPCShopUtils:GetRewardIconAndQuality(RewardConf.RewardItem[i].Type, RewardConf.RewardItem[i].Id)
        if icon and _quality then
          _IconPath = icon
          quality = _quality
          break
        end
      end
    end
    _BgQuality = quality
  elseif Type == Enum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(ID)
    _IconPath = BagItemConf.big_icon
    _BgQuality = BagItemConf.item_quality
  elseif Type == Enum.GoodsType.GT_VITEM then
    local VIItemConf = _G.DataConfigManager:GetVisualItemConf(ID)
    self.Icon:SetRenderScale(UE4.FVector2D(1, 1))
    if VIItemConf then
      _IconPath = VIItemConf.bigIcon
      _BgQuality = VIItemConf.item_quality
    end
  end
  if IconPath then
    if Type == Enum.GoodsType.GT_REWARD then
      self.Icon:SetRenderScale(UE4.FVector2D(1, 1))
      self.Icon:SwitchToSetBrushFromMaterialInstanceMode(true)
    else
      self.Icon:SetRenderScale(UE4.FVector2D(0.86, 0.86))
      self.Icon:SwitchToSetBrushFromMaterialInstanceMode(false)
    end
    self.Icon:SetPath(IconPath)
  else
    self.Icon:SwitchToSetBrushFromMaterialInstanceMode(false)
    self.Icon:SetPath(_IconPath)
  end
  if BgPath then
    self:SetQuality(_BgQuality)
  else
    self:SetQuality(_BgQuality)
  end
  if CostGoodType == Enum.GoodsType.GT_VITEM and CostType == Enum.VisualItem.VI_MONEY and Type ~= Enum.GoodsType.GT_BAGITEM then
    local bgColor = _G.DataConfigManager:GetGlobalConfig("mall_money_bg_color").str
    local bgTextColor = _G.DataConfigManager:GetGlobalConfig("mall_money_word_color").str
    self.Gold_Buy:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgColor))
    self.Gold_Buy_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgTextColor))
  end
  if CostGoodType == Enum.GoodsType.GT_VITEM and CostType ~= Enum.VisualItem.VI_MONEY then
    local _ViCount = ViCount or 0
    if Price > _ViCount then
      self.Money:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
    else
      self.Money:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    end
  else
    self.Money:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
  end
  if CyIcon then
    self.Gold_Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Gold_Icon:SetPath(CyIcon)
  end
  if CostGoodType == Enum.GoodsType.GT_VITEM and CostType == Enum.VisualItem.VI_MONEY then
    self.MoneyTextSwitcher:SetActiveWidgetIndex(1)
  else
    self.MoneyTextSwitcher:SetActiveWidgetIndex(0)
  end
  if Price <= 0 then
    local text = LuaText.umg_shopitemtemplate_free
    self.Money:SetText(text)
    self.Money_3:SetText(text)
  else
    self.Money:SetText(Price)
    self.Money_3:SetText(Price)
  end
end

function UMG_ShopItemTemplate_C:OnBtnChooseReleased()
end

function UMG_ShopItemTemplate_C:OnBtnChoosePressed()
end

function UMG_ShopItemTemplate_C:OnItemSelected(_bSelected)
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_ShopItemTemplate_C:OnItemSelected")
    local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
    self:StopAnimation(self.Change2)
    if self.uiData.canBuy then
      self.SelectBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.change1)
    end
    if self.GoodsShopConf and not self.GoodsShopConf.show_details and (self.GoodsShopConf.id_midas or "") ~= "" then
      NRCModuleManager:DoCmd(PayModuleCmd.PayForCharge, self.GoodsShopConf.id, self.uiData.shopId)
      return
    end
    local GoodsData = self.uiData.originalGoodsData
    local CostType = 0
    local CostGoodType = Enum.GoodsType.GT_NONE
    local Price = 0
    if GoodsData.real_price ~= nil then
      CostType = GoodsData.real_price.goods_id or 0
      CostGoodType = GoodsData.real_price.goods_type or Enum.GoodsType.GT_NONE
      Price = GoodsData.real_price.num or 0
    end
    if self.uiData.canBuy then
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenShopTips, self.uiData)
      self.RedDot:SetupKey(0)
      local isShowRed = self.GoodsShopConf.add_red_point
      if isShowRed then
        local ShopItemFile = JsonUtils.LoadSaved(ShopItemFilename, {})
        ShopItemFile[tostring(self.uiData.shopLibId)] = true
        JsonUtils.DumpSaved(ShopItemFilename, ShopItemFile)
      end
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.HideOrShowMoneyBtn, true)
    else
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenShopTips, self.uiData)
    end
  end
end

function UMG_ShopItemTemplate_C:SetTopUpTips(_rsp)
  Log.Dump(_rsp, 6, "UMG_ShopItemTemplate_C:SetTopUpTips")
  if _rsp then
    if _rsp.instruction.msg then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _rsp.instruction.msg)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetGlobalConfig("topup_forbidden_notice_text").str)
    end
  end
end

function UMG_ShopItemTemplate_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    local bgColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_bg_color_1").str
    local bgTextColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_word_color_1").str
    self.Gold_Buy:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgColor))
    self.Gold_Buy_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgTextColor))
  elseif 2 == quality then
    local bgColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_bg_color_2").str
    local bgTextColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_word_color_2").str
    self.Gold_Buy:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgColor))
    self.Gold_Buy_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgTextColor))
  elseif 3 == quality then
    local bgColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_bg_color_3").str
    local bgTextColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_word_color_3").str
    self.Gold_Buy:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgColor))
    self.Gold_Buy_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgTextColor))
  elseif 4 == quality then
    local bgColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_bg_color_4").str
    local bgTextColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_word_color_4").str
    self.Gold_Buy:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgColor))
    self.Gold_Buy_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgTextColor))
  elseif 5 == quality then
    local bgColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_bg_color_5").str
    local bgTextColor = _G.DataConfigManager:GetGlobalConfig("mall_quality_word_color_5").str
    self.Gold_Buy:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgColor))
    self.Gold_Buy_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(bgTextColor))
  end
end

function UMG_ShopItemTemplate_C:SetLimitBuyBg(CanBuy, LimitBuyType, LimitStockString, limitParam)
  if self.Lock then
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if CanBuy then
    if LimitStockString then
      self.LimitStockCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text2_1:SetText(LimitStockString)
      self.DownCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Image_zhegai_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.DownCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 1 == LimitBuyType then
      self.LevelPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.LevelText:SetText(LuaText.umg_shopitemtemplate_4 .. limitParam)
      if self.Lock then
        self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
    if 2 == LimitBuyType then
      self.Text_MaiWan:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.PromotionTypeSwitcher:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
        self.Image_zhegai_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self.NRCImage_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.Image_zhegai:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_ShopItemTemplate_C:SetPromotionInfo(discount, Type, Param, origin_price, CostType, CostGoodType)
  if (Type or discount) and Param then
    self.PromotionTypeSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if Type == Enum.PromotionType.PT_DISCOUNT or discount then
      self.PromotionTypeSwitcher:SetActiveWidgetIndex(1)
      self.Text1_1:SetText(Param)
      self.Money_2:SetText(origin_price)
      self.PromotionCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.MoneyBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif Type == Enum.PromotionType.PT_ADD then
      self.PromotionTypeSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if self.TitleText_5 then
        local Texts = string.split(Param, "+")
        if #Texts > 1 then
          local Addition = Texts[2]
          self.TitleText_5:SetText(Addition)
          self.TitleText_5:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
          self.TitleText_5:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        self.TitleText_4:SetText(Texts[1])
      else
        self.TitleText_4:SetText(Param)
      end
      if CostGoodType == Enum.GoodsType.GT_VITEM and CostType == Enum.VisualItem.VI_MONEY then
        self.TitleSwitcher:SetActiveWidgetIndex(2)
      end
      self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif Type == Enum.PromotionType.PT_MULTIPLY then
      self.PromotionTypeSwitcher:SetActiveWidgetIndex(0)
      self.Text1:SetText(Param)
      self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif Type == Enum.PromotionType.PT_RETURN then
      self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PromotionTypeSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CanvasPanel_5:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PromotionTypeSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ShopItemTemplate_C:OnDeactive()
end

function UMG_ShopItemTemplate_C:PlayAnimIn()
end

function UMG_ShopItemTemplate_C:PlayAnimUp()
  self:PlayAnimation(self.Change2)
end

function UMG_ShopItemTemplate_C:updateTimeCountDown(svr_time)
  if not self.uiData then
    return
  end
  local _disable_time = self.uiData.disable_time or 0
  local _next_refresh_time = self.uiData.next_refresh_time or 0
  local next_refresh_time = 0
  if 0 == _disable_time then
    next_refresh_time = _next_refresh_time
  elseif 0 == _next_refresh_time then
    next_refresh_time = _disable_time
  else
    next_refresh_time = _disable_time < _next_refresh_time and _disable_time or _next_refresh_time
  end
  if nil == next_refresh_time then
    return
  end
  if 0 == next_refresh_time then
    return
  end
  if next_refresh_time == self.uiData.last_refresh_time then
    return
  end
  self.deltaTime = next_refresh_time - svr_time
  if self.deltaTime then
    self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.deltaTime > 0 then
      local days = math.floor(self.deltaTime / 60 / 60 / 24)
      local hours = math.floor((self.deltaTime - days * 24 * 3600) / 3600)
      local minutes = math.floor((self.deltaTime - days * 24 * 3600 - hours * 3600) / 60)
      if days > 0 then
        self.TitleText:SetText(days .. LuaText.umg_shopitemtemplate_5 .. hours .. LuaText.umg_shopitemtemplate_7)
      else
        if 0 == hours and 0 == minutes then
          minutes = 1
        end
        self.TitleText:SetText(hours .. LuaText.umg_shopitemtemplate_7 .. minutes .. LuaText.umg_shopitemtemplate_8)
      end
    else
      self:timeOutGetStoreListReq()
      self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ShopItemTemplate_C:timeOutGetStoreListReq()
  Log.Debug("UMG_ShopItemTemplate_C:timeOutGetStoreListReq", self.deltaTime, self.uiData.disable_time, self.uiData.next_refresh_time, self.uiData.shopItemId)
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdSetUpdateTimeOut)
end

function UMG_ShopItemTemplate_C:OnAnimationFinished(anim)
  if anim == self.Change2 then
    self.SelectBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.change1 then
    local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
    if GoodsConf.price_goods_type == Enum.GoodsType.GT_VITEM and GoodsConf.price_goods_id == Enum.VisualItem.VI_MONEY then
      self:PlayAnimUp()
    end
  end
end

return UMG_ShopItemTemplate_C

local ShopModuleEvent = reload("NewRoco.Modules.System.Shop.ShopModuleEvent")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_Shop_Tips_C = _G.NRCPanelBase:Extend("UMG_Shop_Tips_C")

function UMG_Shop_Tips_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
end

function UMG_Shop_Tips_C:OnDestruct()
end

function UMG_Shop_Tips_C:OnActive(data)
  if _G.GlobalConfig.DebugOpenUI then
    self:OnAddEventListener()
    return
  end
  self.ModuleData = self.module:GetData("ShopModuleData")
  self.data = data
  self.price = 0
  self.CostType = -1
  self.CostGoodType = Enum.GoodsType.GT_NONE
  self.MoneyEnough = true
  self.MoneyLack = 0
  self.startAddFrame = 0
  self.EndAddFrame = 8
  self.startDelFrame = 0
  self.EndDelFrame = 8
  self.IsAdd = false
  self.IsDelItem = false
  self.IsAddClick = false
  self.IsDelClick = false
  self.bNeedAnimOnDisable = false
  self.AllPrice = nil
  self:SetCommonAddSubtractData()
  self.SliderPanel:SetSliderStepSize(1)
  self:OnAddEventListener()
  if self.data then
    self:InitPanel()
    self:updateTimeCountDown(_G.ZoneServer:GetServerTime() / 1000)
  end
  self:InitMoneyTypeList()
  self:LoadAnimation(0)
  self:BindInputAction()
  self:SetCommonPopUpInfo()
  self:UpdateTips()
end

function UMG_Shop_Tips_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCancel
  CommonPopUpData.FullScreen_Close = false
  CommonPopUpData.Desc = ""
  CommonPopUpData.Btn_LeftHandler = self.OnCancel
  CommonPopUpData.Btn_RightHandler = self.OnOK
  CommonPopUpData.Btn_LeftText = LuaText.mall_goods_tips_2
  CommonPopUpData.Btn_RightText = LuaText.mall_goods_tips_1
  CommonPopUpData.TitleText = LuaText.recall_bp_buy_window
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp3:SetPanelInfo(CommonPopUpData)
end

function UMG_Shop_Tips_C:SetCommonAddSubtractData()
  local SliderInfo = {num1 = 1, num2 = 1}
  local ProgressBarInfo = {num1 = 1, num2 = 1}
  local CommonPopUpData = _G.NRCCommonAddSubtractData()
  CommonPopUpData.Call = self
  CommonPopUpData.SliderInfo = SliderInfo
  CommonPopUpData.ProgressBarInfo = ProgressBarInfo
  CommonPopUpData.AddBtnPressedHandler = self.OnBtnAddPressed
  CommonPopUpData.AddBtnReleasedHandler = self.OnBtnAddReleased
  CommonPopUpData.SubtractBtnPressedHandler = self.OnBtnDelPressed
  CommonPopUpData.SubtractBtnReleasedHandler = self.OnBtnDelReleased
  CommonPopUpData.SliderHandler = self.OnSliderValueChanged
  self.SliderPanel:SetPanelInfo(CommonPopUpData)
end

function UMG_Shop_Tips_C:InitMoneyTypeList()
  local shopid = self.ModuleData:GetShopId()
  local showType = _G.DataConfigManager:GetShopConf(shopid)
  local showTypeNum = showType.goods
  local ShowSumMoneyInfo = {}
  if showTypeNum then
    for i, v in ipairs(showTypeNum) do
      local sumMoneyNum = 0
      if v.goods_type == _G.Enum.GoodsType.GT_VITEM then
        sumMoneyNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(v.goods_id) or 0
      elseif v.goods_type == _G.Enum.GoodsType.GT_BAGITEM then
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, v.goods_id)
        if bagItem then
          sumMoneyNum = bagItem.num or 0
        end
      end
      table.insert(ShowSumMoneyInfo, {
        currencyType = v.goods_type,
        currencyId = v.goods_id,
        num = sumMoneyNum,
        showColor = 0,
        showbg = true,
        bigIcon = true
      })
    end
  end
  self:ShowTopMoney(ShowSumMoneyInfo)
end

function UMG_Shop_Tips_C:Enable()
  self:LoadAnimation(0)
end

function UMG_Shop_Tips_C:Disable()
  if self.bNeedAnimOnDisable then
    self:LoadAnimation(2)
  end
end

function UMG_Shop_Tips_C:SetNeedAnimOnDisable(bNeedAnimOnDisable)
  self.bNeedAnimOnDisable = bNeedAnimOnDisable
end

function UMG_Shop_Tips_C:ShowTopMoney(DataList)
  local moneyInfo = {}
  for i = 1, #DataList do
    if DataList[i].currencyType == Enum.VisualItem.VI_DIAMOND then
      table.insert(moneyInfo, {
        moneyType = DataList[i].currencyType,
        sum = DataList[i].num,
        IsShowBuyIcon = true,
        currencyType = DataList[i].currencyType,
        currencyId = DataList[i].currencyId
      })
    else
      table.insert(moneyInfo, {
        moneyType = DataList[i].currencyType,
        sum = DataList[i].num,
        IsShowBuyIcon = false,
        currencyType = DataList[i].currencyType,
        currencyId = DataList[i].currencyId
      })
    end
  end
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_Shop_Tips_C:InitPanel()
  local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.data.shopItemId)
  local overrideIcon
  if GoodsConf.shop_id == 8070 then
    local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and 2 == localPlayer.gender then
      local globalConfigKey = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGlobalConfigKeyByNum, GoodsConf.id)
      if globalConfigKey then
        local globalConfig = _G.DataConfigManager:GetGlobalConfig(globalConfigKey)
        if globalConfig and globalConfig.str and globalConfig.str ~= "" then
          overrideIcon = globalConfig.str
        end
      end
    end
  end
  local GoodsSeverData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.data.shopId, self.data.shopItemId)
  local MaxBoughtNum = GoodsSeverData.limit_buy_num
  local PurchaseLimit = self.data.PurchaseLimit
  local maxValue = 99
  if PurchaseLimit then
    maxValue = MaxBoughtNum - self.data.boughtNum
    self.Shopping_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Shopping_1:SetText("(" .. LuaText.umg_shop_tips_1 .. " " .. tostring(maxValue) .. "/" .. tostring(MaxBoughtNum .. ")"))
  else
    self.Shopping_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.CostGoodType = GoodsSeverData.real_price.goods_type
  self.CostType = GoodsSeverData.real_price.goods_id
  self.price = GoodsSeverData.real_price.num
  local CyIcon = NPCShopUtils:GetGoodsCurrencyIconPath(GoodsConf.shop_id, GoodsConf.id)
  local sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNum(GoodsConf.shop_id, GoodsConf.id)
  self.Gold_Icon:SetPath(CyIcon)
  self:IsMoneyEnough(1)
  if self.data.canBuy and self.data.originalGoodsConf.buy_cond_type == _G.Enum.BuyLimited.BL_NONE then
    self:UpdateReturnText()
  end
  if GoodsConf.Type == Enum.GoodsType.GT_REWARD then
    self.Switcher:SetActiveWidgetIndex(1)
    local rewardconf = _G.DataConfigManager:GetRewardConf(GoodsConf.item_id)
    local quality = 2
    for i = 1, #rewardconf.RewardItem do
      local icon, _quality = NPCShopUtils:GetRewardIconAndQuality(rewardconf.RewardItem[i].Type, rewardconf.RewardItem[i].Id)
      if icon and _quality then
        self.Icon:SetPath(icon)
        quality = _quality
        break
      end
    end
    if overrideIcon then
      self.Icon:SetPath(overrideIcon)
    elseif GoodsConf.icon then
      self.Icon:SetPath(GoodsConf.icon)
    end
    self:SetQuality(quality)
    self.ItemView:InitList(rewardconf.RewardItem)
    if #rewardconf.RewardItem > 3 then
      self.ItemView:SetAlwaysShowScrollbar(true)
    else
      self.ItemView:SetAlwaysShowScrollbar(false)
    end
    self.MoneyEnough = self:IsMoneyEnough(1)
  elseif GoodsConf.Type == Enum.GoodsType.GT_BAGITEM then
    self.Switcher:SetActiveWidgetIndex(0)
    self.BuildTimeText:SetText(1)
    self.MoneyEnough = self:IsMoneyEnough(1)
    if maxValue > 1 then
      for i = 1, maxValue do
        local Price = self.price * i
        if sumMoneyNum < Price then
          if i > 1 then
            maxValue = i - 1
            break
          end
          maxValue = 1
          break
        end
      end
    end
    self.SliderPanel:SetSelectNumText(maxValue)
    self.SliderPanel:SetMultipleAddBtnText(1)
    self.SliderPanel:SetSliderMinValue(1)
    self.SliderPanel:SetSliderMaxValue(maxValue)
    if 0 == maxValue then
      self.SliderPanel:SetSliderLocked(true)
      self.SliderPanel:SetSliderValue(0)
      self.SliderPanel:SetProgressBarPercent(0)
    else
      self.SliderPanel:SetSliderLocked(false)
      self.SliderPanel:SetSliderValue(1)
      if 1 == maxValue then
        self.SliderPanel:SetProgressBarPercent(1)
      else
        self.SliderPanel:SetProgressBarPercent(0 / maxValue)
      end
    end
    self:SetupAddOrDecBtnState()
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(GoodsConf.item_id)
    if BagItemConf.icon then
      local sub_str = string.sub(BagItemConf.icon, string.find(BagItemConf.icon, ".[^.]*$") + 1)
      local sub_str1 = string.match(sub_str, "(.-)_[^_]*$")
      local path
      local Table = {
        "100301",
        "100302",
        "100303",
        "100304",
        "100305",
        "100306",
        "100307",
        "100308",
        "100309",
        "1003010",
        "1003011",
        "1003012",
        "1003013",
        "1003014",
        "1003015",
        "1003016",
        "1003017",
        "1003019"
      }
      for i = 1, #Table do
        if sub_str1 == Table[i] then
          path = self:GetPath(sub_str1)
          self.Icon:SetPath(BagItemConf.big_icon)
        else
          self.Icon:SetPath(BagItemConf.big_icon)
        end
      end
    end
    self.Title_1:SetText(GoodsConf.goods_name)
    self.ItemDesc:InitText(BagItemConf.description)
    self:SetQuality(BagItemConf.item_quality)
  elseif GoodsConf.Type == Enum.GoodsType.GT_VITEM then
    self.Switcher:SetActiveWidgetIndex(0)
    self.BuildTimeText:SetText(1)
    self.MoneyEnough = self:IsMoneyEnough(1)
    if maxValue > 1 then
      for i = 1, maxValue do
        local Price = self.price * i
        if sumMoneyNum < Price then
          if i > 1 then
            maxValue = i - 1
            break
          end
          maxValue = 1
          break
        end
      end
    end
    self.SliderPanel:SetSelectNumText(maxValue)
    self.SliderPanel:SetSliderMinValue(1)
    self.SliderPanel:SetMultipleAddBtnText(1)
    self.SliderPanel:SetSliderMaxValue(maxValue)
    if 0 == maxValue then
      self.SliderPanel:SetSliderLocked(true)
      self.SliderPanel:SetSliderValue(0)
      self.SliderPanel:SetProgressBarPercent(0)
    else
      self.SliderPanel:SetSliderLocked(false)
      self.SliderPanel:SetSliderValue(1)
      if 1 == maxValue then
        self.SliderPanel:SetProgressBarPercent(1)
      else
        self.SliderPanel:SetProgressBarPercent(0 / maxValue)
      end
    end
    self:SetupAddOrDecBtnState()
    local ViItemConf = _G.DataConfigManager:GetVisualItemConf(GoodsConf.item_id)
    if ViItemConf then
      if overrideIcon then
        self.Icon:SetPath(overrideIcon)
      elseif GoodsConf.icon then
        self.Icon:SetPath(GoodsConf.icon)
      else
        self.Icon:SetPath(ViItemConf.bigIcon)
      end
      self.Title_1:SetText(ViItemConf.displayName)
      self.ItemDesc:InitText(ViItemConf.discription)
      self:SetQuality(ViItemConf.item_quality)
    end
  end
end

function UMG_Shop_Tips_C:SetQuality(quality)
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

function UMG_Shop_Tips_C:GetUnsoldGoodsNameList(goodsConf, shopId, currentGoodsId)
  local goodsNameList = {}
  local param1 = tonumber(goodsConf.buy_cond_param) or 0
  if 1 == param1 then
    local requiredGoodsIds = goodsConf.buy_cond_param1 or {}
    if type(requiredGoodsIds) == "table" then
      for _, goodsId in ipairs(requiredGoodsIds) do
        local goodsSeverData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, goodsId)
        if goodsSeverData then
          local isSoldOut = goodsSeverData.limit_buy_num and goodsSeverData.limit_buy_num > 0 and goodsSeverData.buy_num and goodsSeverData.buy_num >= goodsSeverData.limit_buy_num
          if not isSoldOut then
            local requiredGoodsConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
            if requiredGoodsConf and requiredGoodsConf.goods_name then
              table.insert(goodsNameList, requiredGoodsConf.goods_name)
            end
          end
        end
      end
    end
  else
    local shopData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetCachedShopData, shopId)
    if shopData and shopData.goods_data then
      for _, otherGoodsData in ipairs(shopData.goods_data) do
        if otherGoodsData.goods_id ~= currentGoodsId then
          local isSoldOut = otherGoodsData.limit_buy_num and otherGoodsData.limit_buy_num > 0 and otherGoodsData.buy_num and otherGoodsData.buy_num >= otherGoodsData.limit_buy_num
          if not isSoldOut then
            local otherGoodsConf = _G.DataConfigManager:GetNormalShopConf(otherGoodsData.goods_id)
            if otherGoodsConf and otherGoodsConf.goods_name then
              table.insert(goodsNameList, otherGoodsConf.goods_name)
            end
          end
        end
      end
    end
  end
  return goodsNameList
end

function UMG_Shop_Tips_C:UpdateTips()
  if self.data == nil then
    return
  end
  Log.Dump(self.data, 6, "UMG_Shop_Tips_C:UpdateTips")
  if self.data.canBuy then
    self.TextSwitcher:SetActiveWidgetIndex(0)
    self.PopUp3.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp3.Btn_Right:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TextSwitcher:SetActiveWidgetIndex(1)
    local goodsConf = self.data.originalGoodsConf
    local limitWorldLevel = tonumber(self.data.originalGoodsConf.buy_cond_param)
    Log.Info("UMG_Shop_Tips_C:UpdateTips, type", goodsConf.buy_cond_type)
    if goodsConf.buy_cond_type == Enum.BuyLimited.BL_WORLD_LEVEL then
      local WorldLevelConf = _G.DataConfigManager:GetWorldLevelConf(limitWorldLevel + 1)
      self.Desc:SetText(string.format(LuaText.buy_cond_world_level, WorldLevelConf and WorldLevelConf.title))
    elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_PLAYER_LEVEL then
      self.Desc:SetText(string.format(LuaText.buy_cond_player_level, limitWorldLevel))
    elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_PLAYER_BP_LEVEL then
      self.Desc:SetText(string.format(LuaText.buy_cond_player_bp_level, limitWorldLevel))
    elseif goodsConf.buy_cond_type == Enum.BuyLimited.BL_SOLDOUT then
      local goodsNameList = self:GetUnsoldGoodsNameList(goodsConf, self.data.shopId, self.data.shopItemId)
      if #goodsNameList > 0 then
        local goodsNames = table.concat(goodsNameList, "\227\128\129")
        self.Desc:SetText(string.format(LuaText.buy_cond_soldout_1, goodsNames))
      else
        Log.Info("UMG_Shop_Tips_C:UpdateTips, no unsold goods")
      end
      if goodsConf.buy_cond_type == Enum.BuyLimited.BL_SOLDOUT and 0 == goodsConf.buy_cond_param then
        self.Desc:SetText(LuaText.buy_cond_soldout_0)
      else
        Log.Info("UMG_Shop_Tips_C:UpdateTips, condtype not soldout ")
      end
    else
      self.Desc:SetText(LuaText.umg_shopitemtemplate_3)
      Log.Info("UMG_Shop_Tips_C:UpdateTips, limittype =", self.data.limitBuyType)
    end
    self.PopUp3.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PopUp3.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp3.Btn_Right_GrayState:SetBtnText(LuaText.bl_buy_confirm_button)
  end
end

function UMG_Shop_Tips_C:GetPath(name)
  local path = "PaperSprite'/Game/NewRoco/Modules/System/Common/Icon/Item190/" .. name .. "." .. name
  return path
end

function UMG_Shop_Tips_C:OnDeactive()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_Shop_Tips_C:OnAddEventListener()
  self:RegisterEvent(self, ShopModuleEvent.OpenGetRewardPanel, self.BuyItemOk)
  self:RegisterEvent(self, ShopModuleEvent.updateTipsTimeCountDown, self.updateTimeCountDown)
  self:AddButtonListener(self.NRCButton_66, self.OnItemIconButtonClicked)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_Shop_Tips_C:OnPlayerDataUpdate()
  local itemNum = math.floor(self.SliderPanel:GetSliderValue())
  self.MoneyEnough = self:IsMoneyEnough(itemNum)
  self:InitMoneyTypeList()
end

function UMG_Shop_Tips_C:updateTimeCountDown(svr_time)
  local _disable_time = self.data.disable_time or 0
  local _next_refresh_time = self.data.next_refresh_time or 0
  local next_refresh_time = 0
  if 0 == _disable_time then
    next_refresh_time = _next_refresh_time
  elseif 0 == _next_refresh_time then
    next_refresh_time = _disable_time
  else
    next_refresh_time = _disable_time < _next_refresh_time and _disable_time or _next_refresh_time
  end
  if nil ~= next_refresh_time then
    self.deltaTime = next_refresh_time - svr_time
    if self.deltaTime then
      self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.deltaTime > 0 then
        local days = math.floor(self.deltaTime / 60 / 60 / 24)
        local hours = math.floor((self.deltaTime - days * 24 * 3600) / 3600)
        local minutes = math.floor((self.deltaTime - days * 24 * 3600 - hours * 3600) / 60)
        if days > 0 then
          self.TimerTest:SetText(days .. LuaText.umg_shop_tips_2 .. hours .. LuaText.umg_shop_tips_4)
        else
          if 0 == hours and 0 == minutes then
            minutes = 1
          end
          self.TimerTest:SetText(hours .. LuaText.umg_shop_tips_4 .. minutes .. LuaText.umg_shop_tips_5)
        end
      else
        self:timeOutGetStoreListReq()
        self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TimerCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Shop_Tips_C:timeOutGetStoreListReq()
end

function UMG_Shop_Tips_C:SetupAddOrDecBtnState()
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

function UMG_Shop_Tips_C:OnBtnAddPressed()
  self.IsAddClick = true
  self.IsAdd = true
  _G.UpdateManager:Register(self)
end

function UMG_Shop_Tips_C:OnBtnAddReleased()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsAdd = false
  if self.IsAddClick then
    self:OnBtnAddItemClick()
  end
end

function UMG_Shop_Tips_C:OnBtnDelPressed()
  self.IsDelClick = true
  self.IsDelItem = true
  _G.UpdateManager:Register(self)
end

function UMG_Shop_Tips_C:OnBtnDelReleased()
  _G.UpdateManager:UnRegister(self)
  self.startAddFrame = 0
  self.startDelFrame = 0
  self.IsDelItem = false
  if self.IsDelClick then
    self:OnBtnDelItemClick()
  end
end

function UMG_Shop_Tips_C:OnTick(InDeltaTime)
  self.startAddFrame = self.startAddFrame or 1
  if self.startAddFrame and self.IsAdd and self.startAddFrame >= self.EndAddFrame then
    self.IsAddClick = false
    self.startAddFrame = 0
    self.startDelFrame = 0
    self:OnBtnAddItemClick()
  end
  self.startDelFrame = self.startDelFrame or 1
  if self.IsDelItem and self.startDelFrame >= self.EndDelFrame then
    self.IsDelClick = false
    self.startAddFrame = 0
    self.startDelFrame = 0
    self:OnBtnDelItemClick()
  end
end

function UMG_Shop_Tips_C:OnBtnAddItemClick()
  self:ChangeBuildTimes(true)
end

function UMG_Shop_Tips_C:OnBtnDelItemClick()
  self:ChangeBuildTimes(false)
end

function UMG_Shop_Tips_C:OnSliderValueChanged(value)
  if 0 == self.SliderPanel:GetSliderMinValue() then
    self.SliderPanel:SetSliderValue(0)
    self.SliderPanel:SetProgressBarPercent(0)
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_Shop_Tips_C:OnSliderValueChanged")
  local itemNum = value
  self.BuildTimeText:SetText(itemNum)
  self.SliderPanel:SetProgressBarPercent((value - 1) / (self.SliderPanel:GetSliderMaxValue() - 1))
  self.SliderPanel:SetSliderValue(itemNum)
  self.MoneyEnough = self:IsMoneyEnough(itemNum)
  self:SetupAddOrDecBtnState()
end

function UMG_Shop_Tips_C:ChangeBuildTimes(_isAddItem)
  local curValue = self.SliderPanel:GetSliderValue()
  local minValue = self.SliderPanel:GetSliderMinValue()
  local maxValue = self.SliderPanel:GetSliderMaxValue()
  _G.NRCAudioManager:PlaySound2DAuto(1084, "UMG_Shop_Tips_C:ChangeBuildTimes")
  if _isAddItem then
    curValue = curValue + 1
  else
    curValue = curValue - 1
  end
  curValue = math.clamp(curValue, minValue, maxValue)
  self.SliderPanel:SetSliderValue(curValue)
  local itemNum = math.floor(curValue)
  self.BuildTimeText:SetText(string.format("%d", itemNum))
  self.SliderPanel:SetProgressBarPercent((curValue - 1) / (maxValue - 1))
  self.MoneyEnough = self:IsMoneyEnough(itemNum)
  self:SetupAddOrDecBtnState()
end

function UMG_Shop_Tips_C:IsMoneyEnough(num)
  local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.data.shopItemId)
  if not GoodsConf then
    return
  end
  local sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNum(GoodsConf.shop_id, GoodsConf.id)
  local Price = self.price * num
  self.AllPrice = Price
  if sumMoneyNum < Price then
    self.Money_1:SetText(Price)
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
    self.MoneyLack = Price - sumMoneyNum
    return false
  else
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    self.Money_1:SetText(Price)
    return true
  end
end

function UMG_Shop_Tips_C:OnCancel()
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Shop_Tips_C:OnCancel")
  self:LoadAnimation(2)
end

function UMG_Shop_Tips_C:OnOK()
  _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Shop_Tips_C:OnOK")
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  if self.CostGoodType == Enum.GoodsType.GT_VITEM and self.CostType == Enum.VisualItem.VI_MONEY then
    if self.data and self.data.shopItemId and self.data.shopId then
      local goodsId = self.data.shopItemId
      local shopId = self.data.shopId
      Log.Info("UMG_Shop_Tips_C:OnOK PayForItem", goodsId, shopId)
      _G.NRCModuleManager:DoCmd(_G.PayModuleCmd.PayForItem, goodsId, shopId)
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.HideOrShowMoneyBtn, false)
      self:DoClose()
    else
      Log.Error("UMG_Shop_Tips_C:OnOK data is nil")
    end
    return
  end
  if not self.MoneyEnough and self.CostGoodType == Enum.GoodsType.GT_VITEM and self.CostType == Enum.VisualItem.VI_DIAMOND then
    if self.AllPrice then
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.JudgeBuyDiamondGiftItem, self.AllPrice)
    end
  elseif not self.MoneyEnough and self.CostGoodType == Enum.GoodsType.GT_VITEM and self.CostType == Enum.VisualItem.VI_COUPON then
    if self.AllPrice then
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.JudgeBuyCouponGiftItem, self.AllPrice)
    end
  else
    self.IsBuy = true
    self:LoadAnimation(2)
  end
end

function UMG_Shop_Tips_C:GoTOPUPShop()
  self:DispatchEvent(ShopModuleEvent.GoTOPUPInShop)
  self:DispatchEvent(ShopModuleEvent.SetItemPlayAnimUp)
  self:DoClose()
end

function UMG_Shop_Tips_C:BuyItemOk()
end

function UMG_Shop_Tips_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if self.pendingPackageId then
      local packageId = self.pendingPackageId
      self.pendingPackageId = nil
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionMallPopupByPackageId, packageId, function()
        self:OnFashionMallPopupClosed()
      end)
      return
    end
    if self.IsBuy then
      local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.data.shopItemId)
      if GoodsConf.Type == Enum.GoodsType.GT_REWARD then
        self.data.selectedNum = 1
      else
        self.data.selectedNum = math.floor(self.SliderPanel:GetSliderValue())
      end
      _G.NRCModuleManager:DoCmd(ShopModuleCmd.OnCmdMallBuyItemReq, self.data)
    end
    self:DispatchEvent(ShopModuleEvent.SetItemPlayAnimUp)
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.HideOrShowMoneyBtn, false)
    if not self.bNeedAnimOnDisable then
      self:DoClose()
    end
  end
end

function UMG_Shop_Tips_C:BindInputAction()
end

function UMG_Shop_Tips_C:OnPcClose()
  self:OnCancel()
end

function UMG_Shop_Tips_C:UpdateReturnText()
  local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.data.shopItemId)
  if not GoodsConf then
    return
  end
  if GoodsConf.promotion_type ~= Enum.PromotionType.PT_RETURN then
    return
  end
  local playerGender = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.sex
  local totalReturnNum = self:CalculateTotalReturnAmount(GoodsConf, playerGender)
  if totalReturnNum > 0 then
    local returnTextTemplate = GoodsConf.type_param or ""
    if "" ~= returnTextTemplate then
      local returnText = string.format(returnTextTemplate, totalReturnNum)
      self.Shopping_1:SetText(returnText)
      self.Shopping_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Shop_Tips_C:CalculateTotalReturnAmount(GoodsConf, playerGender)
  local totalReturnNum = 0
  if GoodsConf.Type ~= Enum.GoodsType.GT_REWARD then
    return 0
  end
  local rewardConf = _G.DataConfigManager:GetRewardConf(GoodsConf.item_id)
  if not rewardConf or not rewardConf.RewardItem then
    return 0
  end
  for i = 1, #rewardConf.RewardItem do
    local rewardItem = rewardConf.RewardItem[i]
    local itemType = rewardItem.Type
    local itemId = rewardItem.Id
    if itemType == Enum.GoodsType.GT_FASHION_SUITS or itemType == Enum.GoodsType.GT_FASHION then
      local returnNum = self:GetReturnAmountForItem(itemType, itemId, playerGender)
      totalReturnNum = totalReturnNum + returnNum
    elseif itemType == Enum.GoodsType.GT_BAGITEM then
      local returnNum = self:GetReturnAmountFromVoucher(itemId, playerGender)
      totalReturnNum = totalReturnNum + returnNum
    end
  end
  return totalReturnNum
end

function UMG_Shop_Tips_C:GetReturnAmountFromVoucher(bagItemId, playerGender)
  local totalReturnNum = 0
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItemId)
  if not bagItemConf or not bagItemConf.item_behavior then
    return 0
  end
  local itemBehavior = bagItemConf.item_behavior[1]
  if not itemBehavior then
    return 0
  end
  if itemBehavior.use_action ~= Enum.ItemBehavior.IB_GET_AWARD then
    return 0
  end
  local rewardId = itemBehavior.ratio and itemBehavior.ratio[1]
  if not rewardId then
    return 0
  end
  local voucherRewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
  if not voucherRewardConf or not voucherRewardConf.RewardItem then
    return 0
  end
  for j = 1, #voucherRewardConf.RewardItem do
    local fashionItem = voucherRewardConf.RewardItem[j]
    local fashionType = fashionItem.Type
    local fashionId = fashionItem.Id
    if fashionType == Enum.GoodsType.GT_FASHION_SUITS or fashionType == Enum.GoodsType.GT_FASHION then
      local returnNum = self:GetReturnAmountForItem(fashionType, fashionId, playerGender)
      totalReturnNum = totalReturnNum + returnNum
    end
  end
  return totalReturnNum
end

function UMG_Shop_Tips_C:GetReturnAmountForItem(itemType, itemId, playerGender)
  if itemType == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionOwned, fashionNotOwned = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetFashionOwnedBySuitId, itemId)
    if fashionOwned and #fashionOwned > 0 then
      local totalReturnNum = 0
      for _, fashionId in ipairs(fashionOwned) do
        local returnNum = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGoodsReturnAmount, _G.Enum.GoodsType.GT_FASHION, fashionId, playerGender)
        totalReturnNum = totalReturnNum + returnNum
      end
      return totalReturnNum
    end
    return 0
  elseif itemType == Enum.GoodsType.GT_FASHION then
    local hasOwned = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasOwned, Enum.GoodsType.GT_FASHION, itemId)
    if not hasOwned then
      return 0
    end
    return _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGoodsReturnAmount, _G.Enum.GoodsType.GT_FASHION, itemId, playerGender)
  end
  return 0
end

function UMG_Shop_Tips_C:GetReturnItemName(goodsType, goodsId)
  if goodsType == Enum.GoodsType.GT_VITEM then
    local conf = _G.DataConfigManager:GetVisualItemConf(goodsId)
    return conf and conf.displayName or ""
  elseif goodsType == Enum.GoodsType.GT_BAGITEM then
    local conf = _G.DataConfigManager:GetBagItemConf(goodsId)
    return conf and conf.item_name or ""
  end
  return ""
end

function UMG_Shop_Tips_C:OnItemIconButtonClicked()
  if not self.data then
    return
  end
  local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.data.shopItemId)
  if not GoodsConf then
    return
  end
  local packageId
  if GoodsConf.Type == Enum.GoodsType.GT_FASHION_PACKAGE then
    packageId = GoodsConf.item_id
  else
    packageId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetPackageIdByGoodsId, self.data.shopItemId)
  end
  if packageId then
    self.pendingPackageId = packageId
    self:LoadAnimation(2)
    if self.PopUp3 and self.PopUp3.GetAnimByIndex and self.PopUp3:GetAnimByIndex(2) then
      self.PopUp3:LoadAnimation(2)
    end
  end
end

function UMG_Shop_Tips_C:OnFashionMallPopupClosed()
  self:LoadAnimation(0)
  if self.PopUp3 and self.PopUp3.GetAnimByIndex and self.PopUp3:GetAnimByIndex(0) then
    self.PopUp3:LoadAnimation(0)
  end
end

return UMG_Shop_Tips_C

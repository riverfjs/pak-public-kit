local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local UMG_UpgradeSuitLevel_C = _G.NRCPanelBase:Extend("UMG_UpgradeSuitLevel_C")
local MAX_SHOW_NUM = 6
local MAX_SHOW_NUM_EVEN = 6
local MAX_SHOW_NUM_ODD = 5
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")

function UMG_UpgradeSuitLevel_C:OnConstruct()
  self:AddButtonListener(self.ConfirmBtn.btnLevelUp, self.OnClickConfirmButton)
  self:AddButtonListener(self.BackBtn.btnLevelUp, self.OnClickBackButton)
  self.allItemWidgetsForEvenCount = {
    self.Item1,
    self.Item2,
    self.Item3,
    self.Item4,
    self.Item5,
    self.Item6
  }
  self.allItemWidgetsForOddCount = {
    self.Item1_2,
    self.Item2_1,
    self.Item3_1,
    self.Item4_1,
    self.Item5_1
  }
end

function UMG_UpgradeSuitLevel_C:OnActive(rsp)
  if nil == rsp or nil == rsp.ret_info or nil == rsp.ret_info.ret_code or 0 ~= rsp.ret_info.ret_code or nil == rsp.ret_info.goods_reward or nil == rsp.ret_info.goods_reward.rewards then
    return
  end
  self.ShopID = rsp.shop_id
  local shopItemArray = self:GenerateShowItemArray(rsp)
  self.itemArray = shopItemArray
  local itemNum = #shopItemArray
  if itemNum > MAX_SHOW_NUM then
    Log.Warning("UMG_UpgradeSuitLevel_C:OnActive \229\143\170\230\148\175\230\140\1291~6\228\184\170\229\165\150\229\138\177\229\177\149\231\164\186")
    Log.Dump(rsp, 6, "UMG_UpgradeSuitLevel_C:OnActive rsp")
    Log.Dump(shopItemArray, 6, "UMG_UpgradeSuitLevel_C:OnActive shopItemArray")
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, "AppearanceTryOn", "UMG_UpgradeSuitLevel_C")
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, "SeasonalCombinationBagShop", "UMG_UpgradeSuitLevel_C")
  local bTotalCountOdd = 1 == itemNum & 1
  if bTotalCountOdd then
    local offset = (MAX_SHOW_NUM_ODD - itemNum) / 2
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    for i = 1, #self.allItemWidgetsForOddCount do
      local itemWidget = self.allItemWidgetsForOddCount[i]
      if itemWidget then
        itemWidget:OnActive(rsp.shop_id, shopItemArray[i - offset])
      end
    end
  else
    local offset = (MAX_SHOW_NUM_EVEN - itemNum) / 2
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    for i = 1, #self.allItemWidgetsForEvenCount do
      local itemWidget = self.allItemWidgetsForEvenCount[i]
      if itemWidget then
        itemWidget:OnActive(rsp.shop_id, shopItemArray[i - offset])
      end
    end
  end
  self.bIsSingle = 1 == itemNum and shopItemArray[1].type == _G.Enum.GoodsType.GT_FASHION_SUITS
  if self.bIsSingle then
    self.BackBtn.Title_1:SetText(_G.LuaText.get_suits_btn_wear)
  else
    self.BackBtn.Title_1:SetTExt(_G.LuaText.get_suits_btn_quick_dressup)
  end
  self:PlayAnimation(self.In)
  _G.NRCAudioManager:PlaySound2DAuto(40010011, "UMG_UpgradeSuitLevel_C:OnActive")
  local shopConf = rsp.shop_id and DataConfigManager:GetShopConf(rsp.shop_id)
  if shopConf and shopConf.shop_type == Enum.ShopType.ST_FASHION_RANDOM then
    self.ConfirmBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BackBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ConfirmBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BackBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.onCloseCallback = rsp.onCloseCallback
  if shopConf and shopConf.shop_type == Enum.ShopType.ST_FASHION_PIKA then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    local pikaPointIncreaseAmount = 0
    if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards then
      local rewards = rsp.ret_info.goods_reward.rewards
      for i, goodsItem in ipairs(rewards) do
        if goodsItem.type == _G.Enum.GoodsType.GT_VITEM and goodsItem.id == _G.Enum.VisualItem.VI_PIKA_POINT then
          pikaPointIncreaseAmount = goodsItem.num or 0
        end
      end
    end
    local currentOwnCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PIKA_POINT) or 0
    local previousOwnBeforeThisChange = currentOwnCount - pikaPointIncreaseAmount
    local moneyBtnData = {
      {
        moneyType = _G.Enum.VisualItem.VI_PIKA_POINT,
        sum = previousOwnBeforeThisChange,
        IsShowBuyIcon = true
      }
    }
    self.MoneyBtn:InitGridView(moneyBtnData)
    self:SetPikaPointIncreaseProcess(previousOwnBeforeThisChange, currentOwnCount, 1)
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_UpgradeSuitLevel_C:OnDeactive()
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnUpgradeSuitLevelPanelClose)
  if self.onCloseCallback then
    self.onCloseCallback()
    self.onCloseCallback = nil
  end
  if self.PikaPointIncreaseTimer then
    _G.TimerManager:RemoveTimer(self.PikaPointIncreaseTimer)
    self.PikaPointIncreaseTimer = nil
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, "AppearanceTryOn", "UMG_UpgradeSuitLevel_C", true)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, "SeasonalCombinationBagShop", "UMG_UpgradeSuitLevel_C", true)
end

function UMG_UpgradeSuitLevel_C:OnDestruct()
  if self.PikaPointIncreaseTimer then
    _G.TimerManager:RemoveTimer(self.PikaPointIncreaseTimer)
    self.PikaPointIncreaseTimer = nil
  end
end

function UMG_UpgradeSuitLevel_C:OnClickConfirmButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_UpgradeSuitLevel_C:OnClickConfirmButton")
  self:PlayAnimation(self.Out)
  self.ConfirmBtn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.BackBtn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_UpgradeSuitLevel_C:OnClickBackButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_UpgradeSuitLevel_C:OnClickBackButton")
  self.bOpenClosetPanelWhenClose = false
  if self.bIsSingle then
    local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(self.itemArray[1].id)
    if not suitsConf then
      return
    end
    local curSelectedIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().current_wardrobe_index
    curSelectedIndex = curSelectedIndex and curSelectedIndex + 1
    local salonIds
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo and fashionInfo.wardrobe_data and fashionInfo.wardrobe_data[curSelectedIndex] and fashionInfo.wardrobe_data[curSelectedIndex].salon_item_wear_id and 0 ~= #fashionInfo.wardrobe_data[curSelectedIndex].salon_item_wear_id then
      salonIds = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().wardrobe_data[curSelectedIndex].salon_item_wear_id
    end
    if not salonIds then
      local curSalonIds = _G.DataModelMgr.PlayerDataModel:GetPlayerSalonInfo().item_wear_data
      if curSalonIds and 0 ~= #curSalonIds then
        salonIds = {}
        for k, v in ipairs(curSalonIds) do
          table.insert(salonIds, v.item_wear_id)
        end
      else
        local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        local gender = 1
        if localPlayer then
          gender = localPlayer.gender
        end
        salonIds = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetAvatarDefaultSalonIdsByGender, gender)
      end
    end
    local fashionIds = suitsConf and suitsConf.item_id or {}
    local wandId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId)
    table.insert(fashionIds, wandId)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.BuyAndWearSuitReq, curSelectedIndex - 1, fashionIds, salonIds)
  else
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
    if not isBan then
      self.bOpenClosetPanelWhenClose = true
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.umg_gameinfomain_1)
    end
  end
  self:PlayAnimation(self.Out)
  self.ConfirmBtn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.BackBtn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_UpgradeSuitLevel_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    if self.bOpenClosetPanelWhenClose then
      if self:IsClosetOpened() then
        if self.module then
          self.module:BringPanelToFront("AppearanceCloset")
        else
          Log.Error("Module\228\184\141\229\173\152\229\156\168")
        end
      else
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true)
      end
    end
    self:DoClose()
  end
  if Anim == self.In and self.ShopID then
    local shopConf = DataConfigManager:GetShopConf(self.ShopID)
    if shopConf.shop_type == Enum.ShopType.ST_FASHION_RANDOM then
      self:OpenCollectProgressPanel()
      self:DoClose()
    elseif shopConf.shop_type == Enum.ShopType.ST_FASHION_PIKA then
      self:StartPikaPointIncreaseProcess()
    end
  end
end

function UMG_UpgradeSuitLevel_C:OpenCollectProgressPanel()
  if not self.ShopID then
    return
  end
  local shopConf = DataConfigManager:GetShopConf(self.ShopID)
  if shopConf.shop_type == Enum.ShopType.ST_FASHION_RANDOM then
    if self.itemArray and #self.itemArray > 0 then
      local goodsType = self.itemArray[1].type
      if goodsType == Enum.GoodsType.GT_FASHION_SUITS then
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenShopCollectProgressPanel, self.ShopID, self.itemArray, true)
      else
        local SuitItemConf = _G.DataConfigManager:GetFashionItemConf(self.itemArray[1].id)
        if not SuitItemConf then
          return
        end
        if SuitItemConf.type == Enum.FashionLabelType.FLT_PENDANTA or SuitItemConf.type == Enum.FashionLabelType.FLT_WAND then
          return
        end
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenShopCollectProgressPanel, self.ShopID, self.itemArray, false)
      end
    else
      Log.Warning("UMG_UpgradeSuitLevel_C:OpenCollectProgressPanel", "itemArray is empty", self.ShopID)
    end
  end
end

function UMG_UpgradeSuitLevel_C:GenerateShowItemArray(rsp)
  local showItemArray = {}
  local shopConf = _G.DataConfigManager:GetShopConf(rsp.shop_id)
  local shopType
  if shopConf and shopConf.shop_type then
    shopType = shopConf.shop_type
  end
  local rewards = rsp.ret_info.goods_reward.rewards
  local SuitDataHadFake = {}
  for idx, rewardItem in ipairs(rewards) do
    if rewardItem.type == _G.Enum.GoodsType.GT_VITEM then
    elseif rewardItem.type == _G.Enum.GoodsType.GT_FASHION then
      local bShouldTransToSuitData = false
      local suitId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetSuitIdFromFashionId, rewardItem.id)
      if suitId then
        if shopType == Enum.ShopType.ST_FASHION_PIKA then
          bShouldTransToSuitData = true
        elseif shopType == Enum.ShopType.ST_FASHION_RANDOM then
          local goodsId = rsp.buy_item_info and rsp.buy_item_info[1] and rsp.buy_item_info[1].goods_id
          local normalShopConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
          if normalShopConf and normalShopConf.Type == Enum.GoodsType.GT_FASHION_SUITS then
            bShouldTransToSuitData = true
          end
        end
      end
      if bShouldTransToSuitData then
        if not SuitDataHadFake[suitId] then
          SuitDataHadFake[suitId] = true
          table.insert(showItemArray, {
            id = suitId,
            type = Enum.GoodsType.GT_FASHION_SUITS
          })
        end
      else
        table.insert(showItemArray, {
          id = rewardItem.id,
          type = rewardItem.type
        })
      end
    else
      table.insert(showItemArray, {
        id = rewardItem.id,
        type = rewardItem.type
      })
    end
  end
  table.sort(showItemArray, function(a, b)
    local goodsTypeA = a and a.type or _G.Enum.GoodsType.GT_NONE
    local goodsTypeB = b and b.type or _G.Enum.GoodsType.GT_NONE
    if goodsTypeA == goodsTypeB and goodsTypeA == _G.Enum.GoodsType.GT_FASHION then
      local fashionItemConfA = _G.DataConfigManager:GetFashionItemConf(a and a.type, true)
      local fashionItemConfB = _G.DataConfigManager:GetFashionItemConf(b and b.type, true)
      local fashionTypeA = fashionItemConfA and fashionItemConfA.type or _G.Enum.FashionLabelType.FLT_BEGIN
      local fashionTypeB = fashionItemConfB and fashionItemConfB.type or _G.Enum.FashionLabelType.FLT_BEGIN
      return (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeB] or math.maxinteger)
    elseif goodsTypeA and goodsTypeB then
      return (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeB] or math.maxinteger)
    else
      return nil ~= goodsTypeA
    end
  end)
  return showItemArray
end

function UMG_UpgradeSuitLevel_C:OnPcClose()
end

function UMG_UpgradeSuitLevel_C:GetPikaMoneyButton()
  if self.MoneyBtn then
    return self.MoneyBtn:GetItemByIndex(0)
  end
end

function UMG_UpgradeSuitLevel_C:StartPikaPointIncreaseProcess()
  if not (self.pikaIncreaseBeginValue and self.pikaIncreaseEndValue) or not self.pikaIncreaseDuration then
    return
  end
  local pikaMoneyButton = self:GetPikaMoneyButton()
  if not pikaMoneyButton then
    return
  end
  if self.PikaPointIncreaseTimer then
    _G.TimerManager:RemoveTimer(self.PikaPointIncreaseTimer)
    self.PikaPointIncreaseTimer = nil
  end
  pikaMoneyButton:PlayAnimation(pikaMoneyButton.Add_In)
  pikaMoneyButton:PlayAnimation(pikaMoneyButton.ADD_Loop)
  self.PikaPointIncreaseTimer = _G.TimerManager:CreateTimer(self, "UMG_UpgradeSuitLevel_C", self.pikaIncreaseDuration, self.UpdatePikaPointValue, self.OnPikaIncreaseProcessComplete, 0)
end

function UMG_UpgradeSuitLevel_C:SetPikaPointIncreaseProcess(beginValue, endValue, duration)
  if not (beginValue and endValue and not (endValue <= 0) and not (endValue <= beginValue) and duration) or duration <= 0 then
    return
  end
  self.pikaIncreaseBeginValue = beginValue
  self.pikaIncreaseEndValue = endValue
  self.pikaIncreaseDuration = duration
  if self.PikaPointIncreaseTimer then
    _G.TimerManager:RemoveTimer(self.PikaPointIncreaseTimer)
    self.PikaPointIncreaseTimer = nil
  end
end

function UMG_UpgradeSuitLevel_C:UpdatePikaPointValue()
  if not self.PikaPointIncreaseTimer then
    return
  end
  local pikaMoneyButton = self:GetPikaMoneyButton()
  if pikaMoneyButton then
    pikaMoneyButton:SetSumText(math.round(self.pikaIncreaseBeginValue + (self.pikaIncreaseEndValue - self.pikaIncreaseBeginValue) * (1 - self.PikaPointIncreaseTimer.leftTime / self.PikaPointIncreaseTimer.duration)), false)
  end
end

function UMG_UpgradeSuitLevel_C:OnPikaIncreaseProcessComplete()
  local pikaMoneyButton = self:GetPikaMoneyButton()
  if pikaMoneyButton then
    pikaMoneyButton:SetSumText(self.pikaIncreaseEndValue, false)
    pikaMoneyButton:PlayAnimation(pikaMoneyButton.Add_Out)
  end
end

function UMG_UpgradeSuitLevel_C:GetSuitCount(itemList)
  if not itemList or 0 == #itemList then
    return
  end
  local suitCount = 0
  for k, v in ipairs(itemList) do
    if v.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      suitCount = suitCount + 1
    end
  end
  return 1 == suitCount
end

function UMG_UpgradeSuitLevel_C:IsClosetOpened()
  if not self.module then
    return false
  end
  local closetPanel = self.module:GetPanel("AppearanceCloset")
  if closetPanel then
    return true
  end
  return false
end

return UMG_UpgradeSuitLevel_C

local UIUtils = require("NewRoco.Utils.UIUtils")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_UpgradeList_Item3_C = Base:Extend("UMG_UpgradeList_Item3_C")

function UMG_UpgradeList_Item3_C:OnItemUpdate(data, datalist, index)
  _G.UpdateManager:Register(self)
  self.bDidMarqueeDetect = false
  self.marqueeSpeed = 0.05
  self.startMarquee = false
  self.accumulateMoveWidth = 0.0
  self.bEnableSound = true
  self.itemData = data
  self.parent = data.parent
  self.itemIndex = -1
  self.bIsSelected = false
  self.originalWoreId = nil
  self.bIsWoreComponent = false
  self.selectedHeteroChromeSuitIndex = -1
  self.suitHelmetId = nil
  local vItemsConf = _G.DataConfigManager:GetVisualItemConf(self.itemData.componentData.lv_cost_type)
  self.NRCImage_228:SetPath(vItemsConf.bigIcon)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if 1 == player.gender then
    self.defaultSalonIds = {
      153,
      1,
      33,
      58,
      157,
      64
    }
  else
    self.defaultSalonIds = {
      153,
      77,
      109,
      134,
      157,
      140
    }
  end
  if self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_SALON then
    local salonItemConf = _G.DataConfigManager:GetSalonItemConf(self.itemData.componentData.lv_item_id, true)
    local curTempSalonData = self.parent.parent:GetDefaultSalonData()
    if curTempSalonData then
      for k, v in pairs(curTempSalonData) do
        if salonItemConf and salonItemConf.type == v.SalonType then
          self.originalWoreId = v.SalonId
        end
      end
    end
    curTempSalonData = self.parent.module:OnCmdGetTempAppearOrBeautyData(_G.Enum.GoodsType.GT_SALON)
    if curTempSalonData then
      for k, v in pairs(curTempSalonData) do
        if salonItemConf and salonItemConf.type == v.SalonType and v.SalonId == salonItemConf.id then
          self.bIsWoreComponent = true
        end
      end
    end
  elseif self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_FASHION then
    local curTempFashionData = self.parent.parent:GetDefaultFashionData()
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(self.itemData.componentData.lv_item_id, true)
    for k, v in pairs(curTempFashionData) do
      if fashionItemConf and fashionItemConf.type == v.FashionType then
        self.originalWoreId = v.FashionId
      end
    end
    curTempFashionData = self.parent.module:OnCmdGetTempAppearOrBeautyData(_G.Enum.GoodsType.GT_FASHION)
    if curTempFashionData then
      for k, v in pairs(curTempFashionData) do
        if fashionItemConf and fashionItemConf.type == v.FashionType and v.FashionId == fashionItemConf.id then
          self.bIsWoreComponent = true
        end
      end
    end
  elseif self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    self.originalWoreId = self:_FindWoreSuitIdForHeteroChromeSuit()
    self.bIsWoreComponent = self.originalWoreId == self.itemData.componentData.lv_item_id
  end
  self:UpdateItemInfo()
  self.itemIndex = index
end

function UMG_UpgradeList_Item3_C:OnConstruct()
end

function UMG_UpgradeList_Item3_C:OnDestruct()
  _G.UpdateManager:UnRegister(self)
end

function UMG_UpgradeList_Item3_C:OnDeactive()
  _G.UpdateManager:UnRegister(self)
end

function UMG_UpgradeList_Item3_C:UpdateItemInfoByNewData(data)
  self.itemData.buy_num = data.buy_num
  self:UpdateItemInfo()
end

function UMG_UpgradeList_Item3_C:UpdateItemInfo()
  local Type = self.itemData.componentData.lv_item_type
  local itemId = self.itemData.componentData.lv_item_id
  self:SetWorePrompt(self.bIsWoreComponent)
  self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if Type == _G.Enum.GoodsType.GT_SALON then
    self.TypeSwitcher:SetActiveWidgetIndex(0)
    local salonConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    local icon = salonConf.icon
    self.Icon:SetPath(icon)
    UIUtils.SetIconQualityColor(self.QualityColor, salonConf.item_quality)
    UIUtils.SetIconQuality(self.Bg_QualityColor, salonConf.item_quality)
    if salonConf.type == _G.Enum.SalonLabelType.SLT_HAIR then
      self.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Text_Title:SetText(salonConf.name)
  elseif Type == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionConf then
      if fashionConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
        self.TypeSwitcher:SetActiveWidgetIndex(2)
        local icon = fashionConf.icon
        self.Icon_BaoHang:SetPath(icon)
      else
        self.TypeSwitcher:SetActiveWidgetIndex(0)
        local icon = fashionConf.icon
        self.Icon:SetPath(icon)
      end
      UIUtils.SetIconQualityColor(self.QualityColor, fashionConf.item_quality)
      UIUtils.SetIconQuality(self.Bg_QualityColor, fashionConf.item_quality)
      self.Text_Title:SetText(fashionConf.name)
    end
  elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    self.TypeSwitcher:SetActiveWidgetIndex(0)
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    local icon = suitConf.suits_icon
    self.Icon:SetPath(icon)
    UIUtils.SetIconQualityColor(self.QualityColor, AppearanceUtils.GetSuitQuality(suitConf.suit_grade))
    UIUtils.SetIconQuality(self.Bg_QualityColor, AppearanceUtils.GetSuitQuality(suitConf.suit_grade))
    self.Text_Title:SetText(suitConf.name)
  elseif Type == _G.Enum.GoodsType.GT_FASHION_BOND then
    self.TypeSwitcher:SetActiveWidgetIndex(1)
    local bondConf = _G.DataConfigManager:GetFashionBondConf(itemId)
    if bondConf then
      local icon = bondConf.fashion_bond_icon
      self.Icon_Badge:SetPath(icon)
      local grade = _G.DataConfigManager:GetFashionSuitsConf(bondConf.suits_id[1]).suit_grade
      local quality = 4
      if grade and grade == Enum.SuitGrade.SG_BOND then
        quality = 5
      end
      UIUtils.SetIconQualityColor(self.QualityColor, quality)
      UIUtils.SetIconQuality(self.Bg_QualityColor, quality)
      self.Text_Title:SetText(bondConf.name)
    end
  end
  _G.NRCViewBase:DelayFrames(1, function()
    self:CheckIfTextTooLong()
  end)
  self:UpdateCurrency()
end

function UMG_UpgradeList_Item3_C:OnItemSelected(bIsSelected, bScrolled)
  if not (self and self.itemData) or not self.itemData.componentData then
    return
  end
  local Type = self.itemData.componentData.lv_item_type
  local ItemId = self.itemData.componentData.lv_item_id
  self:StopAllAnimations()
  if bIsSelected then
    self.bIsSelected = true
    if self.Selected_bg then
      self.Selected_bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Select then
      self:PlayAnimation(self.Select)
    end
    if self.bEnableSound then
      _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_UpgradeList_Item3_C:OnItemSelected")
    end
    if self.parent then
      self.parent:OnItemSelectedCallback(self.itemIndex)
      if Type ~= _G.Enum.GoodsType.GT_FASHION_BOND then
        if Type == _G.Enum.GoodsType.GT_SALON then
          local salonConf = _G.DataConfigManager:GetSalonItemConf(ItemId, true)
          if salonConf and salonConf.type == _G.Enum.SalonLabelType.SLT_HAIR then
            self:_DetectSuitHelmet()
          end
        end
        if not self or not self.itemData then
          return
        end
        if Type == _G.Enum.GoodsType.GT_FASHION then
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, true, {ItemId}, true)
        elseif Type == _G.Enum.GoodsType.GT_SALON then
          if self.suitHelmetId then
            _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, _G.Enum.FashionLabelType.FLT_HATS, self.suitHelmetId, nil, nil, false)
          end
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {ItemId}, true)
        elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
          self:_ChangeSuit(ItemId, true)
        end
      end
    end
    if self.parent and self.parent.OnUpgradeItemClicked then
      self.parent:OnUpgradeItemClicked(self.itemData, self.itemIndex)
    end
  else
    self.bIsSelected = false
    if self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      self:DemountComponent()
    elseif not self.bIsWoreComponent then
      self:DemountComponent()
    end
    if self.parent and self.parent.OnUpgradeItemCanceled then
      self.parent:OnUpgradeItemCanceled(self.itemData, self.itemIndex)
    end
    if self.Cancel then
      self:PlayAnimation(self.Cancel)
    end
  end
end

function UMG_UpgradeList_Item3_C:MountComponent(bIgnoreRotate)
  local Type = self.itemData.componentData.lv_item_type
  local ItemId = self.itemData.componentData.lv_item_id
  local suitId = self.parent.suitInfo.suitId
  if Type == _G.Enum.GoodsType.GT_FASHION then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, true, {ItemId}, true, bIgnoreRotate)
    self.parent.data:SetSuitWearComponent(suitId, true, ItemId)
  elseif Type == _G.Enum.GoodsType.GT_SALON then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {ItemId}, true, bIgnoreRotate)
    self.parent.data:SetSuitWearComponent(suitId, false, ItemId)
  elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    self.parent:OnSuitChanged(self.itemIndex, ItemId)
    self:_ChangeSuit(ItemId, true)
  end
end

function UMG_UpgradeList_Item3_C:DemountComponent()
  if not self.itemData then
    return
  end
  local Type = self.itemData.componentData.lv_item_type
  local ItemId = self.itemData.componentData.lv_item_id
  local suitId = self.parent.suitInfo.suitId
  if Type == _G.Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(ItemId)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, fashionItemConf.type, ItemId, nil, nil, false)
    self.parent.data:RemoveWearComponentFromSuit(suitId, true, ItemId)
  elseif Type == _G.Enum.GoodsType.GT_SALON then
    local itemConf = _G.DataConfigManager:GetSalonItemConf(ItemId)
    local bHasHelmet = false
    if itemConf and itemConf.type == _G.Enum.SalonLabelType.SLT_HAIR and self.suitHelmetId then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {
        self.originalWoreId
      }, true)
      bHasHelmet = true
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, true, {
        self.suitHelmetId
      }, true)
    end
    if not bHasHelmet then
      if self.originalWoreId == ItemId then
        if itemConf then
          local id = self.defaultSalonIds[itemConf.type + 1]
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {id}, true)
        end
      else
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {
          self.originalWoreId
        }, true)
      end
    end
    self.parent.data:RemoveWearComponentFromSuit(suitId, false, ItemId)
  elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(self.ItemId, true)
    self.parent:OnSuitChanged(-1, ItemId)
    self.originalWoreId = self.parent.parent.lastTryOnId
    self:_ChangeSuit(self.originalWoreId, true)
  end
end

function UMG_UpgradeList_Item3_C:RestoreComponent()
  local Type = self.itemData.componentData.lv_item_type
  if Type == _G.Enum.GoodsType.GT_FASHION or Type == _G.Enum.GoodsType.GT_SALON then
    self:DemountComponent()
  elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS and self.bIsSelected then
    self:_ChangeSuit(self.originalWoreId, true)
  end
end

function UMG_UpgradeList_Item3_C:CheckIfTextTooLong()
  local textComp = self.Text_Title
  if not textComp or not UE.UObject.IsValid(textComp) then
    return
  end
  local textContent = textComp:GetText()
  self.bShouldEnableMarquee = self:CalculateTextWidth(textComp, textContent)
end

function UMG_UpgradeList_Item3_C:CalculateTextWidth(textComp, textContent)
  local textWidth = textComp:GetDesiredSize().X
  local scrollBoxWidth = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox_51):GetSize().x
  if textWidth >= scrollBoxWidth then
    textComp:SetText(string.format("%s    %s    ", textContent, textContent))
    _G.NRCViewBase:DelayFrames(1, function()
      self.totalScrollEnd = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox_51):GetSize().x + self.ScrollBox_51:GetScrollOffsetOfEnd()
      self.startMarquee = true
    end)
    return true
  end
  return false
end

function UMG_UpgradeList_Item3_C:SetWorePrompt(bIsWore)
  self.bIsWoreComponent = bIsWore
  if bIsWore and self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
    self.CanvasPanel_CornerMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Adorn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CornerMarkText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CornerMarkText:SetText(_G.LuaText.fashion_bond_working_text)
  else
    self.CanvasPanel_CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Adorn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CornerMarkText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_UpgradeList_Item3_C:OnAnimationFinished(Anim)
  if Anim == self.Cancel then
    self.Selected_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Bg_QualityColor:SetRenderOpacity(0.0)
  end
end

function UMG_UpgradeList_Item3_C:_ChangeSuit(suitItemId, bShouldPlayEffect)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitItemId)
  if not suitConf then
    return
  end
  local fashionItems = {}
  for k, v in ipairs(suitConf.item_id) do
    local temp = {wearing_item_id = v}
    table.insert(fashionItems, temp)
  end
  self.parent.module:SetDefaultSuitAvatar(true, fashionItems, nil, self.parent.module.closetAvatarPlayer, function()
    if bShouldPlayEffect and self.parent.module then
      self.parent.module:PlayReloadingSkill(self.parent.module.closetAvatarPlayer)
    end
  end)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, true, nil, self.parent.module.closetAvatarPlayer)
end

function UMG_UpgradeList_Item3_C:OnHeteroChromeMount(index, itemId)
  self.selectedHeteroChromeSuitIndex = index
  if self.itemIndex ~= index and self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local suitId = self.parent.suitInfo.suitId
    local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(self.itemData.componentData.lv_item_id, true)
    if suitsConf and suitsConf.item_id then
      for k, v in ipairs(suitsConf.item_id) do
        self.parent.data:RemoveWearComponentFromSuit(suitId, true, v)
      end
    end
  end
end

function UMG_UpgradeList_Item3_C:_FindWoreSuitIdForHeteroChromeSuit()
  local closetPanel = self.parent.parent
  local result = closetPanel.lastTryOnId
  local curTempFashionData = closetPanel.module.data.TempAppearData
  local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(closetPanel.lastTryOnId, true)
  for k, v in ipairs(suitsConf.lv_up_closet) do
    local heteroChromeSuitConf = _G.DataConfigManager:GetFashionSuitsConf(v.lv_item_id)
    if heteroChromeSuitConf and heteroChromeSuitConf.item_id then
      local bIsSameSuit = true
      for k1, v1 in ipairs(heteroChromeSuitConf.item_id) do
        local bIsFound = false
        for k2, v2 in ipairs(curTempFashionData) do
          if v2.FashionId == v1 then
            bIsFound = true
            break
          end
        end
        if not bIsFound then
          bIsSameSuit = false
          break
        end
      end
      if bIsSameSuit then
        return v.lv_item_id
      end
    end
  end
  return result
end

function UMG_UpgradeList_Item3_C:UpdateCurrency()
  if self.itemData.buy_num > 0 then
    self.Switcher_0:SetActiveWidgetIndex(1)
    self.NRCSwitcher_Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local Type = self.itemData.componentData.lv_item_type
    if Type == _G.Enum.GoodsType.GT_FASHION_BOND then
      self:SetWorePrompt(true)
    end
  else
    self.Switcher_0:SetActiveWidgetIndex(0)
    local costNum = self.itemData.componentData.lv_cost_price
    local hasCostMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(self.itemData.componentData.lv_cost_type) or 0
    if costNum > hasCostMoney then
      self.UnlockQuantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
    else
      self.UnlockQuantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("000000FF"))
    end
    self.UnlockQuantity:SetText(costNum)
    if self.itemData.componentData.lv_item_type == _G.Enum.GoodsType.GT_SALON then
      self.NRCSwitcher_Lock:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_Lock:SetActiveWidgetIndex(0)
    end
  end
end

function UMG_UpgradeList_Item3_C:OnTick(DeltaTime)
  if self.bShouldEnableMarquee and self.startMarquee then
    local nextProgress = self.marqueeSpeed * DeltaTime * self.totalScrollEnd + self.ScrollBox_51:GetScrollOffset()
    if nextProgress > self.totalScrollEnd / 2 then
      nextProgress = nextProgress - self.totalScrollEnd / 2
    end
    self.ScrollBox_51:SetScrollOffset(nextProgress)
  end
end

function UMG_UpgradeList_Item3_C:_DetectSuitHelmet()
  self.suitHelmetId = nil
  if not self.parent or not self.parent.suitInfo then
    return
  end
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.parent.suitInfo.suitId, true)
  if not suitConf then
    return
  end
  for _, v in ipairs(suitConf.item_id) do
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(v)
    if fashionConf and fashionConf.type == _G.Enum.FashionLabelType.FLT_HATS then
      local _, _, avatarEnum = self.parent.module:GetConfigEnumFromFashionId(v)
      if avatarEnum == UE4.EAvatarBodyType.Hg or avatarEnum == UE4.EAvatarBodyType.Hp then
        self.suitHelmetId = v
        return
      end
    end
  end
end

function UMG_UpgradeList_Item3_C:GetItemType()
  return self.itemData.componentData.lv_item_type
end

function UMG_UpgradeList_Item3_C:GetItemId()
  return self.itemData.componentData.lv_item_id
end

function UMG_UpgradeList_Item3_C:GetItemPrice()
  return self.itemData.componentData.lv_cost_price
end

function UMG_UpgradeList_Item3_C:GetItemCostType()
  return self.itemData.componentData.lv_cost_type
end

function UMG_UpgradeList_Item3_C:IsComponentWorn()
  return self.bIsWoreComponent
end

function UMG_UpgradeList_Item3_C:SetEnableSound(bEnableSound)
  self.bEnableSound = bEnableSound
end

return UMG_UpgradeList_Item3_C

local UIUtils = require("NewRoco.Utils.UIUtils")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_UpgradeList_Item1_C = Base:Extend("UMG_UpgradeList_Item1_C")

function UMG_UpgradeList_Item1_C:OnConstruct()
end

function UMG_UpgradeList_Item1_C:OnDestruct()
  if self.uiData then
    self.uiData.newPanel = false
  end
end

function UMG_UpgradeList_Item1_C:OnItemUpdate(_data, datalist, index)
  Log.Dump(_data, 3, "UMG_UpgradeList_Item1_C:OnItemUpdate")
  self.uiData = _data.data
  self.bIsUnlocked = 0 ~= datalist[index].data.buy_num
  self.parent = _data.parent
  self.belongToSuit = _data.belongToSuit
  self.index = index
  self.totalNum = #datalist
  self:UpdateItemInfo()
end

function UMG_UpgradeList_Item1_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  self.uiData.item_id = self.uiData.componentData.lv_item_id
  local Type = self.uiData.componentData.lv_item_type
  local ItemId = self.uiData.componentData.lv_item_id
  if _bSelected then
    self:PlayAnimation(self.Select)
    if self.uiData then
      self.parent:HandleMutualExclusiveChoice(true, self, Type, false)
      if self.uiData.newPanel == true then
        if true == self.uiData.skipClickSound then
          self.uiData.skipClickSound = false
        else
          _G.NRCAudioManager:PlaySound2DAuto(1281, "UMG_UpgradeList_Item1_C:OnItemSelected1")
        end
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SelectUpgradeItem, self.index)
      else
        if true == self.uiData.skipClickSound then
          self.uiData.skipClickSound = false
        else
          _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_UpgradeList_Item1_C:OnItemSelected2")
        end
        if Type == _G.Enum.GoodsType.GT_SALON then
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {ItemId}, false)
        elseif Type == _G.Enum.GoodsType.GT_FASHION then
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, true, {ItemId}, false)
          local fashionConf = _G.DataConfigManager:GetFashionItemConf(ItemId)
          if fashionConf and fashionConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
            self.parent.TryOnImage:SetPendantaFromUpgrade(true)
          end
        elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
          local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(ItemId)
          for k, v in ipairs(fashionSuitConf.item_id) do
            _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, true, {v}, false)
          end
        elseif Type == _G.Enum.GoodsType.GT_FASHION_BOND then
          local conf = _G.DataConfigManager:GetFashionBondConf(ItemId)
          if conf then
            local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
            local context = {
              bIsShiningMedal = true,
              title = LuaText.popup_magic_award,
              image = player and player.gender == Enum.ESexValue.SEX_MALE and conf.fashion_bond_album_male or conf.fashion_bond_album_female,
              leftImage = conf.fashion_bond_icon,
              desc = conf.popup_text,
              deselectContainer = self.parent.SuitUnlockList,
              deselectItemIndex = self.index,
              bondId = ItemId
            }
            _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenShiningMedalDetailPanel, context)
          end
        end
      end
      self:HandleUpgradeItemSelectionOnTryOn()
    end
  else
    self.parent:HandleMutualExclusiveChoice(false, self, Type, false)
    self.parent:HandleSuitNameRecover(ItemId)
    self.parent:DemountUpgradeComponent(Type, ItemId)
    self:PlayAnimation(self.Cancel)
  end
end

function UMG_UpgradeList_Item1_C:OnDeactive()
end

function UMG_UpgradeList_Item1_C:UpdateItemInfoByData(data)
  self.uiData = data.data
  self.bIsUnlocked = 0 ~= data.data.buy_num
  self.parent = data.parent
  self:UpdateItemInfo()
end

function UMG_UpgradeList_Item1_C:UpdateLockState(isUnlocked)
  self.bIsUnlocked = isUnlocked
  self.Lock_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.bIsUnlocked then
    self.Lock_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_UpgradeList_Item1_C:UpdateItemInfo()
  self.Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal_png.img_daojukuangnormal_png'")
  self.Switcher:SetActiveWidgetIndex(1)
  self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Lock_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.bIsUnlocked then
    self.Lock_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Arrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.uiData.newPanel == false then
    self.ProgressBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UnLockSwitcher:SetActiveWidgetIndex(0)
    self.ShowText:SetText(self.uiData.text)
  else
    self.Arrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ProgressBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if 0 == self.index % 2 then
      self.Line_L:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Line_R:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif 1 == self.index then
      self.Line_L:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.index == self.totalNum then
      self.Line_R:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.UnLockSwitcher:SetActiveWidgetIndex(1)
    local lvText = string.format(LuaText.umg_petskilltemple2_1, self.index)
    self.LvText:SetText(lvText)
  end
  local Type = self.uiData.componentData.lv_item_type
  local itemId = self.uiData.componentData.lv_item_id
  local bShowSelectBg = true
  if Type == _G.Enum.GoodsType.GT_SALON then
    self.TypeSwitcher:SetActiveWidgetIndex(0)
    local salonConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    local icon = salonConf.icon
    self.Icon:SetPath(icon)
    UIUtils.SetIconQualityColor(self.QualityColor, salonConf.item_quality)
    UIUtils.SetIconQuality(self.Bg_QualityColor, salonConf.item_quality)
    if salonConf.type == Enum.SalonLabelType.SLT_HAIR then
      self.Closet:OnItemUpdate({salonConfId = itemId, lockState = true})
      self.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif Type == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    local icon = fashionConf.icon
    if fashionConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
      bShowSelectBg = false
      self.TypeSwitcher:SetActiveWidgetIndex(2)
      self.Icon_BaoHang:SetPath(icon)
    else
      self.TypeSwitcher:SetActiveWidgetIndex(0)
      self.Icon:SetPath(icon)
      UIUtils.SetIconQuality(self.Bg_QualityColor, fashionConf.item_quality)
    end
    UIUtils.SetIconQualityColor(self.QualityColor, fashionConf.item_quality)
  elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    self.TypeSwitcher:SetActiveWidgetIndex(0)
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    local icon = suitConf.suits_icon
    self.Icon:SetPath(icon)
    UIUtils.SetIconQualityColor(self.QualityColor, AppearanceUtils.GetSuitQuality(suitConf.suit_grade))
    UIUtils.SetIconQuality(self.Bg_QualityColor, AppearanceUtils.GetSuitQuality(suitConf.suit_grade))
  elseif Type == _G.Enum.GoodsType.GT_FASHION_BOND then
    bShowSelectBg = false
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
    end
  end
  local arrowPos = self.Arrow.Slot:GetPosition()
  if 3 == self.index then
    arrowPos.X = 92
  else
    arrowPos.X = 101
  end
  self.Arrow.Slot:SetPosition(arrowPos)
  if self.Selected_bg then
    if bShowSelectBg then
      self.Selected_bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Selected_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if 0 == self.uiData.buy_num then
    self.LockPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Line_L:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("C4C2B6FF"))
    self.Bg_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("C4C2B6FF"))
    self.Arrow:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("C4C2B6FF"))
  else
    self.LockPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Line_L:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FFC65FFF"))
    self.Bg_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FFC65FFF"))
    self.Arrow:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FFC65FFF"))
  end
end

function UMG_UpgradeList_Item1_C:HandleUpgradeItemSelectionOnTryOn()
  local title = ""
  local packageTitle = self.belongToSuit.name
  local bShowDetailBtn = false
  local bShowGorgeousBtn = false
  local context = {}
  context.context = self.uiData
  context.bIsShopItem = false
  local itemId = self.uiData.componentData.lv_item_id
  local Type = self.uiData.componentData.lv_item_type
  if Type == _G.Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if salonConf then
      title = salonConf.name
    end
  elseif Type == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionConf then
      title = fashionConf.name
      if fashionConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
        bShowGorgeousBtn = true
      end
    end
  elseif Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    if suitConf then
      title = suitConf.name
    end
  elseif Type == _G.Enum.GoodsType.GT_FASHION_BOND then
    local bondConf = _G.DataConfigManager:GetFashionBondConf(itemId)
    if bondConf then
      title = bondConf.name
    end
  end
  self.parent:PushNewSelectedElementToStack(title, packageTitle, bShowDetailBtn, bShowGorgeousBtn, context, itemId)
end

function UMG_UpgradeList_Item1_C:OpItem(opType, ...)
  if 1 == opType then
    local firstArg = select(1, ...)
    self:UpdateLockState(firstArg)
  end
end

function UMG_UpgradeList_Item1_C:GetItemType()
  return self.uiData.componentData.lv_item_type
end

function UMG_UpgradeList_Item1_C:GetItemId()
  return self.uiData.componentData.lv_item_id
end

return UMG_UpgradeList_Item1_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_TryOn_Item_C = Base:Extend("UMG_TryOn_Item_C")

function UMG_TryOn_Item_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_TryOn_Item_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_TryOn_Item_C:OnAddEventListener()
end

function UMG_TryOn_Item_C:OnRemoveEventListener()
end

function UMG_TryOn_Item_C:OnItemUpdate(_data, datalist, index)
  Log.Dump(_data, 3, "UMG_TryOn_Item_C:OnItemUpdate")
  self.uiData = _data.data
  self.parent = _data.parent
  self.bIsMaxLevel = _data.bIsMaxLevel
  self.bIsFree = _data.bIsFree
  self.fashionPackageId = _data.fashionPackageId
  self.index = index
  self.hasGorgeous = false
  self.bPreviewMode = _data.bIsPreview
  self:UpdateItemInfo()
end

function UMG_TryOn_Item_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  self._bSelected = _bSelected
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TryOn_Item_C:OnItemSelected")
    local title = ""
    local packageTitle = ""
    local bShouldShowDetailButton = false
    local bShouldShowGorgeousButton = false
    local gorgeousButtonIconPath = ""
    local gorgeousButtonText = ""
    self.parent:HandleMutualExclusiveChoice(true, self, self.uiData.Type, true)
    if self.uiData == nil then
      Log.Error("self.uiData is nil")
      return
    end
    if self.uiData.Type ~= _G.Enum.GoodsType.GT_CARD_SKIN then
      local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.item_id, true)
      local bIsWand = false
      if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) then
        bIsWand = true
      end
      self:PlayAnimation(self:_GetSelectAnimByQuality(self.itemQuality, self.hasGorgeous, bIsWand))
    end
    if self.uiData.Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.uiData.item_id)
      local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, self.uiData.item_id)
      if suitId then
        bShouldShowGorgeousButton = true
      end
      bShouldShowDetailButton = true
      local packageId = suitConf and suitConf.package_id
      if packageId then
        local packageConf = _G.DataConfigManager:GetFashionPackageConf(packageId, true)
        if packageConf then
          packageTitle = packageConf.name
        end
      end
      local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(self.uiData.item_id, true)
      if fashionSuitConf then
        title = fashionSuitConf.name
      end
      self.Switcher_bg:SetActiveWidgetIndex(0)
      if self.bIsMaxLevel then
        self.Switcher_bg:SetActiveWidgetIndex(1)
      end
      self.parent:SetSingleBuyBtnState(self.bOwned)
    elseif self.uiData.Type == _G.Enum.GoodsType.GT_FASHION then
      local packageConf = _G.DataConfigManager:GetFashionPackageConf(self.fashionPackageId, true)
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.item_id, true)
      if fashionItemConf then
        title = fashionItemConf.name
        if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
          bShouldShowGorgeousButton = true
        end
      end
      packageTitle = packageConf.name
      if packageConf then
        local itemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.item_id, true)
        local wandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.item_id, true)
        if itemConf and itemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
          if wandConf and wandConf.magic_name and not string.IsNilOrEmpty(wandConf.magic_name) then
            bShouldShowGorgeousButton = true
            packageTitle = wandConf.magic_dress_text
            gorgeousButtonIconPath = wandConf.magic_btn_icon
            gorgeousButtonText = wandConf.magic_name
          end
        else
          bShouldShowDetailButton = false
        end
      end
    elseif self.uiData.Type == _G.Enum.GoodsType.GT_CARD_SKIN then
      packageTitle, title = self:_ShowNameCardPopUp(self.fashionPackageId, self.uiData.item_id)
    end
    local detailContext = {}
    detailContext.bIsShopItem = true
    detailContext.context = self.uiData
    detailContext.gorgeousBtnIconPath = gorgeousButtonIconPath
    detailContext.gorgeousBtnText = gorgeousButtonText
    self.parent:PushNewSelectedElementToStack(title, packageTitle, bShouldShowDetailButton, bShouldShowGorgeousButton, detailContext, self.uiData.item_id)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, self.uiData.Type, self.uiData.item_id, self.uiData.id, nil, nil, true)
  elseif self.uiData.Type and self.uiData.Type == _G.Enum.GoodsType.GT_CARD_SKIN then
    local packageTitle, title = self:_ShowNameCardPopUp(self.fashionPackageId, self.uiData.item_id)
    local detailContext = {}
    detailContext.bIsShopItem = true
    detailContext.context = self.uiData
    self.parent:PushNewSelectedElementToStack(title, packageTitle, false, false, detailContext, self.uiData.item_id)
  else
    self.parent:HandleMutualExclusiveChoice(false, self, self.uiData.Type, true)
    self.parent:HandleSuitNameRecover(self.uiData.item_id)
    self.parent:DemountUpgradeComponent(self.uiData.Type, self.uiData.item_id)
    local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.item_id)
    local bIsWand = false
    if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) then
      bIsWand = true
    end
    self:PlayAnimation(self:_GetUnselectAnimByQuality(self.itemQuality, self.hasGorgeous, bIsWand))
  end
end

function UMG_TryOn_Item_C:OnDeactive()
end

function UMG_TryOn_Item_C:UpdateItemInfoWithData(data)
  self.uiData = data.data
  self.parent = data.parent
  self.bIsMaxLevel = data.bIsMaxLevel
  self.bIsFree = data.bIsFree
  self.fashionPackageId = data.fashionPackageId
  self:UpdateItemInfo()
  self:UpdateParentButtonState()
end

function UMG_TryOn_Item_C:UpdateItemInfo()
  self.Btn_Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bOwned = false
  self.itemQuality = 1
  local type
  if self.uiData.Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.uiData.item_id)
    if suitConf then
      self.Icon:SetPath(suitConf.suits_icon)
      self.itemQuality = suitConf.suit_grade + 4
      if suitConf.suit_grade == _G.Enum.SuitGrade.SG_UNIBOND then
        self.itemQuality = _G.Enum.SuitGrade.SG_DAILY + 4
      end
      self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(self.itemQuality))
      self.Bg:SetPath(AppearanceUtils:GetPIKABackgroundPath(true))
      UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
      self.bOwned = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckHasSuit, self.uiData.item_id)
    end
    if suitConf and #suitConf.petbase_id > 0 then
      self:_SetShouldShowPetIcon(true, AppearanceUtils:GetPetIconById(suitConf.petbase_id[1]))
    else
      self:_SetShouldShowPetIcon(false)
    end
  elseif self.uiData.Type == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.item_id)
    type = fashionConf.type
    if fashionConf then
      self.itemQuality = fashionConf.item_quality
      self.Icon:SetPath(fashionConf.icon)
      self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(fashionConf.item_quality))
      UIUtils.SetIconQualityColor(self.QualityColor, fashionConf.item_quality)
      self.bOwned = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckHasOwned, self.uiData.Type, self.uiData.item_id)
    end
    self:_SetShouldShowPetIcon(false)
  elseif self.uiData.Type == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(self.uiData.item_id)
    if cardSkinConf then
      self.itemQuality = cardSkinConf.card_quality
      self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(cardSkinConf.card_quality))
      UIUtils.SetIconQualityColor(self.QualityColor, cardSkinConf.card_quality)
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(cardSkinConf.bagitem_id)
      if bagItemConf then
        self.Icon:SetPath(bagItemConf.big_icon)
      end
      self.bOwned = _G.NRCModuleManager:DoCmd(FriendModuleCmd.HasCardSkin, self.uiData.item_id)
    end
    self:_SetShouldShowPetIcon(false)
  end
  local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.item_id)
  local bIsWand = false
  if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) then
    bIsWand = true
  end
  if bIsWand and type == _G.Enum.FashionLabelType.FLT_WAND then
    self:PlayAnimation(self.FaZhang_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  else
    local sgSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, self.uiData.item_id)
    if sgSuitId then
      self.itemQuality = 6
      self.Bg:SetPath(AppearanceUtils:GetPIKABackgroundPath(true))
      self:PlayAnimation(self.Orange_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    else
      self.Bg:SetPath(AppearanceUtils:GetPIKABackgroundPath(false))
      if 4 == itemQuality then
        self:PlayAnimation(self.Purple_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
      end
    end
  end
  if self.bOwned then
    self.AlreadyOwned_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Presenter:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if self.bIsFree and not self.parent:IsPreviewMode() then
      self.Presenter:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Presenter:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.AlreadyOwned_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TryOn_Item_C:UpdatePetIconBackground(bIsMaxLevel)
  if bIsMaxLevel then
    self.Switcher_bg:SetActiveWidgetIndex(1)
  else
    self.Switcher_bg:SetActiveWidgetIndex(0)
  end
end

function UMG_TryOn_Item_C:ShowSuitIcon(bShow)
  if bShow then
    self.Btn_Suit:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Btn_Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TryOn_Item_C:_SetShouldShowPetIcon(bShouldShow, path)
  self.PetIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if bShouldShow then
    self.PetIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PetIcon:SetPath(path)
  end
end

function UMG_TryOn_Item_C:OnAnimationFinished(Anim)
  if Anim == self.Purple_selcet then
    self:PlayAnimation(self.Purple_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.Orange_selcet then
    self:PlayAnimation(self.Orange_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.Orange_unselect then
    self:PlayAnimation(self.Orange_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.Purple_unselect then
    self:PlayAnimation(self.Purple_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.FaZhang_selcet then
    self:PlayAnimation(self.FaZhang_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.FaZhang_unselect then
    self:PlayAnimation(self.FaZhang_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
end

function UMG_TryOn_Item_C:_GetSelectAnimByQuality(quality, hasGorgeous, bIsWand)
  if bIsWand then
    return self.FaZhang_selcet
  end
  if hasGorgeous then
    if 4 == quality then
      return self.Purple_selcet
    elseif 5 == quality or 6 == quality then
      return self.Orange_selcet
    end
  end
  return self.change1
end

function UMG_TryOn_Item_C:_GetUnselectAnimByQuality(quality, hasGorgeous, bIsWand)
  if bIsWand then
    return self.FaZhang_unselect
  end
  if hasGorgeous then
    if 4 == quality then
      return self.Purple_unselect
    elseif 5 == quality or 6 == quality then
      return self.Orange_unselect
    end
  end
  return self.change1_unselect
end

function UMG_TryOn_Item_C:_ShowNameCardPopUp(packageId, itemId)
  local packageTitle, title
  local packageConf = _G.DataConfigManager:GetFashionPackageConf(packageId, true)
  if packageConf then
    packageTitle = packageConf.name
  end
  local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(itemId)
  if cardSkinConf.bagitem_id > 0 then
    title = cardSkinConf.skin_resource_name
    local playerGender = 1
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      playerGender = localPlayer.gender
    end
    local context = {
      bIsNameCard = true,
      gender = playerGender,
      desc = _G.LuaText.popup_card_details,
      nameCardPanelBackground = string.format(_G.UEPath.CARD_COMMON_PATH, cardSkinConf.skin_resource_path, "Fram", cardSkinConf.skin_resource_path, "Fram")
    }
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenCardSkinDetailPanel, context)
  else
    Log.Error("card skin \230\156\170\233\133\141\231\189\174\229\175\185\229\186\148bagItem id")
  end
  return packageTitle, title
end

function UMG_TryOn_Item_C:UpdateParentButtonState()
  if self._bSelected and self.bOwned and self.parent.SetSingleBuyBtnState and self.parent.UpdateSingleOwnedState then
    self.parent:SetSingleBuyBtnState(self.bOwned)
    self.parent:UpdateSingleOwnedState()
  end
end

return UMG_TryOn_Item_C

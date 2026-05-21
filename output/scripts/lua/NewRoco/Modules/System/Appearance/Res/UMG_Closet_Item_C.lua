local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Closet_Item_C = Base:Extend("UMG_Closet_Item_C")

function UMG_Closet_Item_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Closet_Item_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_Closet_Item_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Suit, self.OnBtnSuitClicked)
end

function UMG_Closet_Item_C:OnRemoveEventListener()
end

function UMG_Closet_Item_C:OnItemUpdate(_data, datalist, index)
  self.ignoreWear = false
  self.bChose = false
  self.bEnableSound = true
  self.bEnableUpgradeButtonAnim = true
  self.uiData = _data
  self.index = index
  self.bIsTeQuanPendanta = false
  self.parent = _data.ownedPanel
  self.hasGorgeous = false
  self.itemQuality = 0
  self.bIsInit = true
  self:ResetItemState()
  self:UpdateItemInfo()
  self.bIsInit = false
end

function UMG_Closet_Item_C:UpdateItemInfo()
  self.CanvasPanel_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Dazzling:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RedDot:SetupKey(0)
  self.RedDot_1:SetupKey(0)
  self.RedDot:Refresh()
  self.RedDot_1:Refresh()
  local bFashion = self.uiData.bFashion
  local chooseType = self.uiData.typeEnum
  local chooseId = self.uiData.id
  local iconPath = ""
  self.IsUnlockAllComponents = false
  self.Bg:SetPath(AppearanceUtils:GetPIKABackgroundPath(false))
  self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if bFashion then
    if chooseType == _G.Enum.FashionLabelType.FLT_SUIT then
      self.IsUnlockAllComponents = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, chooseId)
      local confData = _G.DataConfigManager:GetFashionSuitsConf(chooseId)
      if confData then
        iconPath = confData.suits_icon
        if self.parent and self.parent.data then
          local overrideIcon = self.parent.data:GetInitialSuitIconByCurBottom(chooseId)
          if overrideIcon then
            iconPath = overrideIcon
          end
        end
        self.itemQuality = AppearanceUtils.GetSuitQuality(confData.suit_grade)
        self.hasGorgeous = false
        self:SetPetIconBackground(self.IsUnlockAllComponents, self.uiData.bHas)
        local sgSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, chooseId)
        if sgSuitId then
          self.hasGorgeous = true
          if 5 == self.itemQuality then
            self.itemQuality = 6
            self.Bg:SetPath(AppearanceUtils:GetPIKABackgroundPath(true))
            self:PlayAnimation(self.Orange_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
          elseif 4 == self.itemQuality then
            self:PlayAnimation(self.Purple_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
          end
        else
          self.Bg:SetPath(AppearanceUtils:GetPIKABackgroundPath(false))
        end
        self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(self.itemQuality))
        UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
        self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if 0 ~= #confData.petbase_id then
          self.CanvasPanel_Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          if 0 ~= confData.suits_original_id then
            local id = string.format("%s_1", confData.petbase_id[1])
            self.PetIcon:SetPath(AppearanceUtils:GetPetIconById(id))
            self.PetIcon_Mask:SetPath(AppearanceUtils:GetPetIconById(id))
          else
            self.PetIcon:SetPath(AppearanceUtils:GetPetIconById(confData.petbase_id[1]))
            self.PetIcon_Mask:SetPath(AppearanceUtils:GetPetIconById(confData.petbase_id[1]))
          end
        end
        if 0 ~= confData.suits_original_id then
          self.RedDot_1:SetupKey(467, confData.bond_id)
          self.RedDot_1:Refresh()
        end
      end
    elseif chooseType == _G.Enum.FashionLabelType.FLT_PENDANTA then
      local confData = _G.DataConfigManager:GetFashionItemConf(chooseId)
      local pendantaConf = _G.DataConfigManager:GetFashionBagcharmConf(chooseId)
      if confData then
        iconPath = confData.icon
      end
      self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.itemQuality = confData.item_quality
      self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(self.itemQuality))
      UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
      if pendantaConf and pendantaConf.charm_kind == _G.Enum.BagCharm.BGC_PETCHARM and 0 ~= pendantaConf.privilege_effect then
        self.bIsTeQuanPendanta = true
        self:PlayAnimation(self.tequan_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
        self.Bg_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Bg_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
      end
    elseif chooseType == _G.Enum.FashionLabelType.FLT_WAND then
      local confData = _G.DataConfigManager:GetFashionItemConf(chooseId)
      if confData then
        iconPath = confData.icon
      end
      self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.itemQuality = confData.item_quality
      self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(self.itemQuality))
      UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
      local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(chooseId)
      if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) and fashionWandConf.wand_source == _G.Enum.FashionWandSource.FWSO_PACKAGE then
        self:PlayAnimation(self.FaZhang_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
        self.Bg_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Bg_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      local confData = _G.DataConfigManager:GetFashionItemConf(chooseId)
      if confData then
        iconPath = confData.icon
      end
      self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.itemQuality = confData.item_quality
      self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(self.itemQuality))
      UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
      if chooseType == _G.Enum.FashionLabelType.FLT_TOPS or chooseType == _G.Enum.FashionLabelType.FLT_HATS or chooseType == _G.Enum.FashionLabelType.FLT_DRESSES then
        local bClaimable = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckPetGlassTintIsClaimableByItemID, self.uiData.id)
        if bClaimable then
          self.RedDot_1:SetupKey(459, {
            self.uiData.id
          })
          self.RedDot_1:Refresh()
        else
          self.RedDot_1:SetupKey(463, {
            self.uiData.id
          })
          self.RedDot_1:Refresh()
        end
      end
    end
    self:HasItem(self.uiData.bHas)
    self:RefreshConflictUIShow(chooseType)
  else
    self.QualityColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local confData = _G.DataConfigManager:GetSalonItemConf(chooseId[1])
    if confData then
      iconPath = confData.icon
    end
    self.itemQuality = confData.item_quality
    self.Selected:SetPath(AppearanceUtils.GetPIKAQualityPath(self.itemQuality))
    UIUtils.SetIconQualityColor(self.QualityColor, self.itemQuality)
    self:HasItem(true)
    self:RefreshSalonConflictUIShow(confData)
  end
  self.Icon:SetPath(iconPath)
  self:SetSuitBtnVisible()
  if self.uiData.redDotKey and 0 ~= self.uiData.redDotKey and self.uiData.redDotExtra then
    self.RedDot:SetupKey(self.uiData.redDotKey, self.uiData.redDotExtra)
    self.RedDot:Refresh()
    if self.uiData.needToErase then
      self.RedDot:EraseRedPoint(true)
    end
  end
  if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
    self:UpdateRedDotMutex()
  end
  if self.uiData and self.uiData.isGlassItem then
    local selectedGlassInfo = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSelectedItemGlassMap, self.uiData.id)
    self.Dazzling:UpdateState(self.uiData.isGlassItem, selectedGlassInfo or self.uiData.wearingGlassInfo)
  end
end

function UMG_Closet_Item_C:HasItem(bOwned)
  if bOwned then
    self.Bg_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Bg_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Closet_Item_C:OnItemSelected(_bSelected)
  if _bSelected and self.bChose and not self.uiData.bFashion then
    return
  end
  self:StopAllAnimations()
  if _bSelected then
    local bIsRed = self.RedDot_1:IsRed()
    local key = self.RedDot_1:GetKey()
    if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      self.IsUnlockAllComponents = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, self.uiData.id)
    end
    if self.bEnableSound then
      _G.NRCAudioManager:PlaySound2DAuto(1078, "UMG_Closet_Item_C:OnItemSelected")
    end
    self.RedDot:EraseRedPoint(true)
    if self.bChose == false then
      local itemInfo = {
        itemID = self.uiData.id,
        wearingGlassInfo = self.uiData.wearingGlassInfo,
        unlockedGlassInfo = self.uiData.unlockedGlassInfo,
        claimableGlassInfo = self.uiData.claimableGlassInfo
      }
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurrentSelectItemInfo, itemInfo)
      local suitConf
      if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
        suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.uiData.id, true)
        self.parent.lastTryOnId = self.uiData.id
        self.parent:OnUncancelableItemSelected(self.index)
      elseif self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_PENDANTA then
        if not self:IsHasBag() then
          local tips = _G.DataConfigManager:GetLocalizationConf("fashion_bag_pendanta_remind1").msg
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
          return
        end
      elseif self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_WAND or self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_DRESSES or self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_TOPS or self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_BOTTOMS or self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SHOES then
        self.parent:OnUncancelableItemSelected(self.index)
      end
      self:HandleDressConflict()
      self:_UpdateItemTitleAndDetailOnCloset(suitConf)
      self:_UpdateCanPurchasableButton(suitConf)
      if self.uiData.typeEnum ~= _G.Enum.FashionLabelType.FLT_SUIT and self.uiData.bFashion and self.uiData.typeEnum ~= _G.Enum.FashionLabelType.FLT_SUIT then
        suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.parent.lastTryOnId, true)
        local bIsContainInSuit = false
        if suitConf then
          for k, v in ipairs(suitConf.item_id) do
            if v == self.uiData.id then
              bIsContainInSuit = true
              break
            end
          end
        end
        if not bIsContainInSuit and self.uiData.typeEnum ~= _G.Enum.FashionLabelType.FLT_WAND then
          self.parent.lastTryOnId = 0
        end
      end
      local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.id)
      local bIsWand = false
      if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) and fashionWandConf.wand_source == _G.Enum.FashionWandSource.FWSO_PACKAGE then
        bIsWand = true
      end
      self:PlayAnimation(self:_GetSelectAnimByQuality(self.itemQuality, self.hasGorgeous, bIsWand))
      self.bChose = true
      if not self.ignoreWear then
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, self.uiData.typeEnum, self.uiData.id, nil, nil, true, nil, true)
      else
        self.parent:SetConfirmBtnState(self.uiData.bHas)
      end
      self.ignoreWear = false
      self:RefreshAllConflictUIShow()
    else
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurrentSelectItemInfo, nil)
      if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_BAGS then
        local TempAppearData = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetTempAppearOrBeautyData, _G.Enum.GoodsType.GT_FASHION)
        if TempAppearData and #TempAppearData > 0 then
          for i, j in ipairs(TempAppearData) do
            if j.FashionType == _G.Enum.FashionLabelType.FLT_PENDANTA then
              _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetClosetAvatar, true, j.FashionType, j.FashionId, nil, false)
              local tips = _G.DataConfigManager:GetLocalizationConf("fashion_bag_pendanta_remind2").msg
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
              break
            end
          end
        end
        self.bChose = false
      end
      self.parent:UpdateViewButtonState(false, false)
      if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
        self.parent.lastTryOnId = 0
      end
      if self.uiData.bFashion and self.uiData.typeEnum ~= _G.Enum.FashionLabelType.FLT_SUIT then
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.parent.lastTryOnId, true)
        local bIsContainInSuit = false
        if suitConf and suitConf.item_id then
          for k, v in ipairs(suitConf.item_id) do
            if v == self.uiData.id then
              bIsContainInSuit = true
              break
            end
          end
        end
        if bIsContainInSuit and self.uiData.typeEnum ~= _G.Enum.FashionLabelType.FLT_WAND then
          self.parent.lastTryOnId = 0
        end
      end
      if self.uiData.bFashion == true then
        local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.id)
        local bIsWand = false
        if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) and fashionWandConf.wand_source == _G.Enum.FashionWandSource.FWSO_PACKAGE then
          bIsWand = true
        end
        self:PlayAnimation(self:_GetUnselectAnimByQuality(self.itemQuality, self.hasGorgeous, bIsWand))
        self.bChose = false
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, self.uiData.typeEnum, self.uiData.id, nil, nil, false, nil, true)
      end
      self.parent:UpdateTitlesAndCurrentDetailId(nil, nil, nil, false)
      self.parent:UpdateGorgeousMagicBtnVisible(false)
    end
  else
    if not self.bChose then
      return
    end
    self.bChose = false
    local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.id)
    local bIsWand = false
    if fashionWandConf and not string.IsNilOrEmpty(fashionWandConf.magic_name) and fashionWandConf.wand_source == _G.Enum.FashionWandSource.FWSO_PACKAGE then
      bIsWand = true
    end
    self:PlayAnimation(self:_GetUnselectAnimByQuality(self.itemQuality, self.hasGorgeous, bIsWand))
  end
end

function UMG_Closet_Item_C:IsHasBag()
  local hasBag = false
  local TempAppearData = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetTempAppearOrBeautyData, _G.Enum.GoodsType.GT_FASHION)
  if TempAppearData and #TempAppearData > 0 then
    for i, j in ipairs(TempAppearData) do
      if j.FashionType == _G.Enum.FashionLabelType.FLT_BAGS then
        hasBag = true
        break
      end
    end
  end
  return hasBag
end

function UMG_Closet_Item_C:OnDeactive()
end

function UMG_Closet_Item_C:OnBtnSuitClicked()
  if self.uiData.bFashion then
    if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.uiData.id)
    else
      local suitId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetSuitIdFromFashionId, self.uiData.id)
      if suitId then
        _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, suitId, self.uiData.id)
      end
    end
  end
end

function UMG_Closet_Item_C:SetSuitBtnVisible()
  self.Btn_Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Closet_Item_C:UpdatePetIconBackground()
  local IsUnlockedAllComponents = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, self.uiData.id)
  self:SetPetIconBackground(IsUnlockedAllComponents, self.uiData.bHas)
end

function UMG_Closet_Item_C:OnAnimationFinished(Anim)
  if self.bIsResetting then
    return
  end
  if Anim == self.Purple_selcet then
    self:PlayAnimation(self.Purple_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.Orange_selcet then
    self:PlayAnimation(self.Orange_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.Purple_unselect then
    self:PlayAnimation(self.Purple_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.Orange_unselect then
    self:PlayAnimation(self.Orange_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.tequan_selcet then
    self:PlayAnimation(self.tequan_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.tequan_unselect then
    self:PlayAnimation(self.tequan_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.FaZhang_selcet then
    self:PlayAnimation(self.FaZhang_selcet_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  if Anim == self.FaZhang_unselect then
    self:PlayAnimation(self.FaZhang_unselect_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    self.Bg_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Closet_Item_C:SetPetIconBackground(bShouldShow, bHas)
  self.Switcher_bg:SetActiveWidgetIndex(0)
  self:PlayAnimation(self.Normallevel, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self.PetIcon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if bShouldShow then
    self:StopAnimation(self.MaxLevel)
    self:StopAnimation(self.Normallevel)
    self:PlayAnimation(self.MaxLevel, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    self.Switcher_bg:SetActiveWidgetIndex(1)
  elseif not bHas and self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.uiData.id)
    if suitConf and suitConf.petbase_id and #suitConf.petbase_id > 0 then
      self.PetIcon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Closet_Item_C:IgnoreNextWear()
  self.ignoreWear = true
end

function UMG_Closet_Item_C:_GetSelectAnimByQuality(quality, bHasGorgeous, bIsWand)
  if bIsWand then
    self.Bg_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return self.FaZhang_selcet
  end
  if self.bIsTeQuanPendanta then
    return self.tequan_selcet
  elseif bHasGorgeous then
    if 4 == quality then
      return self.Purple_selcet
    elseif 5 == quality or 6 == quality then
      return self.Orange_selcet
    end
  end
  return self.change1
end

function UMG_Closet_Item_C:_GetUnselectAnimByQuality(quality, bHasGorgeous, bIsWand)
  if bIsWand then
    return self.FaZhang_unselect
  end
  if self.bIsTeQuanPendanta then
    return self.tequan_unselect
  elseif bHasGorgeous then
    if 4 == quality then
      return self.Purple_unselect
    elseif 5 == quality or 6 == quality then
      return self.Orange_unselect
    end
  end
  return self.change1_unselect
end

function UMG_Closet_Item_C:SetEnableSound(bEnableSound)
  self.bEnableSound = bEnableSound
end

function UMG_Closet_Item_C:SetEnableUpgradeButtonAnim(bEnableUpgradeButtonAnim)
  self.bEnableUpgradeButtonAnim = bEnableUpgradeButtonAnim
end

function UMG_Closet_Item_C:_UpdateItemTitleAndDetailOnCloset(suitConf)
  if self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
    local bIsHeterochrome = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsSuitHeterochrome, suitConf.id)
    if not bIsHeterochrome then
      local packageId = suitConf and suitConf.package_id
      local packageConf = DataConfigManager:GetFashionPackageConf(packageId, true)
      if packageConf then
        self.parent:UpdateTitlesAndCurrentDetailId(suitConf.name, packageConf.name, self.uiData, true)
      else
        self.parent:UpdateTitlesAndCurrentDetailId(suitConf.name, nil, self.uiData, true)
      end
      local shouldShowGorgeous = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, self.uiData.id)
      if shouldShowGorgeous then
        self.parent:UpdateGorgeousMagicBtnVisible(true, 0)
      else
        self.parent:UpdateGorgeousMagicBtnVisible(false)
      end
    else
      self.parent:UpdateTitlesAndCurrentDetailId(suitConf.name, _G.LuaText.suits_petgiving, self.uiData, true)
      local sgSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, self.uiData.id)
      local bShouShowGorgeous = false
      if sgSuitId and 0 ~= sgSuitId then
        bShouShowGorgeous = true
      end
      self.parent:UpdateGorgeousMagicBtnVisible(bShouShowGorgeous)
    end
  elseif self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_PENDANTA then
    local itemName = ""
    local suitName
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.id, true)
    local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromLevelUpItemId, true, self.uiData.id)
    if fashionItemConf then
      itemName = fashionItemConf.name
      if suitId then
        local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId, true)
        if fashionSuitConf then
          suitName = fashionSuitConf.name
        end
      else
        local packageId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetPackageIdFromGiftId, self.uiData.id)
        if packageId then
          local packageConf = _G.DataConfigManager:GetFashionPackageConf(packageId, true)
          if packageConf then
            suitName = packageConf.name
          end
        end
      end
    end
    self.parent:UpdateTitlesAndCurrentDetailId(itemName, suitName, nil, true)
    local bagCharmConf = _G.DataConfigManager:GetFashionBagcharmConf(self.uiData.id, true)
    if bagCharmConf then
      if bagCharmConf.charm_kind == _G.Enum.BagCharm.BGC_PETCHARM then
        if 0 ~= bagCharmConf.privilege_effect then
          self.parent:UpdateGorgeousMagicBtnVisible(true, 1, self.uiData.id)
        else
          self.parent:UpdateGorgeousMagicBtnVisible(true, 2, self.uiData.id)
        end
      elseif bagCharmConf.charm_kind == _G.Enum.BagCharm.BGC_PACKAGECHARM then
        self.parent:UpdateGorgeousMagicBtnVisible(true, 2, self.uiData.id)
      else
        self.parent:UpdateGorgeousMagicBtnVisible(false)
      end
    else
      self.parent:UpdateGorgeousMagicBtnVisible(false)
    end
  elseif self.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_WAND then
    local itemName = ""
    local packageName
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.id, true)
    local icon = ""
    local btnText = ""
    local bShouldShowBtn = false
    if fashionItemConf then
      itemName = fashionItemConf.name
      local goodsConf = self.parent.module.data.FashionIdToGoodsIdMap[self.uiData.id]
      if goodsConf and 103 == goodsConf.shop_id then
        local packageId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetPackageIdFromGiftId, self.uiData.id)
        if packageId then
          local packageConf = _G.DataConfigManager:GetFashionPackageConf(packageId, true)
          if packageConf then
            packageName = packageConf.name
          end
        end
      end
      local fashionWandConf = _G.DataConfigManager:GetFashionWandConf(self.uiData.id)
      if fashionWandConf and fashionWandConf.magic_name and not string.IsNilOrEmpty(fashionWandConf.magic_name) then
        packageName = fashionWandConf.magic_dress_text
        icon = fashionWandConf.magic_btn_icon
        btnText = fashionWandConf.magic_name
        bShouldShowBtn = true
      end
    end
    self.parent:UpdateTitlesAndCurrentDetailId(itemName, packageName, nil, true, icon, btnText)
    self.parent:UpdateGorgeousMagicBtnVisible(bShouldShowBtn, 3, nil, self.uiData.id)
  else
    local itemName = ""
    if self.uiData.bFashion then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.id, true)
      if fashionItemConf then
        itemName = fashionItemConf.name
      end
    else
      local salonConf = _G.DataConfigManager:GetSalonItemConf(self.uiData.id[1], true)
      if salonConf then
        itemName = salonConf.name
      end
    end
    self.parent:UpdateTitlesAndCurrentDetailId(itemName, nil, nil, true)
    self.parent:UpdateGorgeousMagicBtnVisible(false)
  end
end

function UMG_Closet_Item_C:_UpdateCanPurchasableButton(suitConf)
  if (self.uiData.bHas or self.parent:IsSuitPurchasable(self.uiData.id)) and suitConf then
    if self.uiData and self.uiData.claimableGlassInfo and #self.uiData.claimableGlassInfo > 0 then
      self.parent:UpdateViewButtonState()
    elseif suitConf.lv_up_closet and 0 == #suitConf.lv_up_closet then
      self.parent:UpdateViewButtonState(false, false)
    else
      local iconPath, bIsGoods, bFashion, itemType = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetNextLockedItemIconPath, self.uiData.id)
      if self.IsUnlockAllComponents then
        self.parent:UpdateViewButtonState(true, false, iconPath, bIsGoods, bFashion, itemType, self.bEnableUpgradeButtonAnim)
      else
        self.parent:UpdateViewButtonState(true, true, iconPath, bIsGoods, bFashion, itemType, self.bEnableUpgradeButtonAnim)
      end
    end
  elseif suitConf then
    local bIsHeterochrome = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsSuitHeterochrome, suitConf.id)
    if not bIsHeterochrome then
      if suitConf.lv_up_closet and #suitConf.lv_up_closet > 0 then
        local iconPath, bIsGoods, bFashion, itemType = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetNextLockedItemIconPath, self.uiData.id)
        if self.IsUnlockAllComponents then
          self.parent:UpdateViewButtonState(true, false, iconPath, bIsGoods, bFashion, itemType, self.bEnableUpgradeButtonAnim)
        else
          self.parent:UpdateViewButtonState(true, true, iconPath, bIsGoods, bFashion, itemType, self.bEnableUpgradeButtonAnim)
        end
      else
        self.parent:UpdateViewButtonState(false, false)
      end
    else
      self.parent:UpdateViewButtonState(false, false)
    end
  else
    self.parent:UpdateViewButtonState(false, false)
  end
end

function UMG_Closet_Item_C:HandleDressConflict()
  local itemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.id, true)
  if itemConf then
    local tag = AppearanceUtils.BuildTagArrayFromConf(itemConf)
    local bConflict, conflictIds, conflictTypes = self.parent:HasFashionConflict(self.uiData.typeEnum, tag, self.uiData.id)
    if bConflict then
      for index, id in ipairs(conflictIds) do
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, conflictTypes[index], id, nil, nil, false, nil, true)
      end
      self.MutualExclusivity:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:HandleBodyTypeConflict()
end

function UMG_Closet_Item_C:HandleBodyTypeConflict()
  if not self.uiData.bFashion then
    return
  end
  local newAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(self.uiData.id)
  if not newAvatarEnum then
    return
  end
  local conflictBodyTypes = AppearanceUtils.GetConflictBodyTypes(newAvatarEnum)
  if not conflictBodyTypes or 0 == #conflictBodyTypes then
    return
  end
  local TempAppearData = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetTempAppearOrBeautyData, _G.Enum.GoodsType.GT_FASHION)
  if not TempAppearData then
    return
  end
  for _, data in ipairs(TempAppearData) do
    if data.FashionId ~= self.uiData.id then
      local existAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(data.FashionId)
      if existAvatarEnum then
        for _, conflictType in ipairs(conflictBodyTypes) do
          if existAvatarEnum == conflictType then
            _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, data.FashionType, data.FashionId, nil, nil, false, nil, true)
            break
          end
        end
      end
    end
  end
end

function UMG_Closet_Item_C:RefreshConflictUIShow(chooseType)
  if chooseType == _G.Enum.FashionLabelType.FLT_SUIT then
    self.MutualExclusivity:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local itemConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.id)
  if itemConf and itemConf.type ~= _G.Enum.FashionLabelType.FLT_SUIT then
    local tag = AppearanceUtils.BuildTagArrayFromConf(itemConf)
    local bConflict, conflictIds, conflictTypes = self.parent:HasFashionConflict(self.uiData.typeEnum, tag, self.uiData.id, false)
    self.MutualExclusivity:SetVisibility(bConflict and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Closet_Item_C:RefreshSalonConflictUIShow(confData)
  self.MutualExclusivity:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Closet_Item_C:RefreshAllConflictUIShow()
  self.parent:RefreshCurrentConflictUIShow()
end

function UMG_Closet_Item_C:UpdateRedDotMutex()
  if not self.RedDot or not self.RedDot_1 then
    return
  end
  local isRedDotActive = self.RedDot:IsRed()
  local isRedDot1Active = self.RedDot_1:IsRed()
  if isRedDotActive and isRedDot1Active then
    self.RedDot_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RedDot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif isRedDot1Active then
    self.RedDot_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif isRedDotActive then
    self.RedDot_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RedDot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.RedDot_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Closet_Item_C:PlayNewCardAnim()
  self:StopAnimation(self.NewCard)
  self:PlayAnimation(self.NewCard)
end

function UMG_Closet_Item_C:OpItem(opType, ...)
  if 1 == opType then
    local firstArg = select(1, ...)
    self:SetEnableSound(firstArg)
  elseif 2 == opType then
    if self.uiData.bFashion then
      self:RefreshConflictUIShow(self.uiData.typeEnum)
    else
      local salonItemConf = _G.DataConfigManager:GetSalonItemConf(self.uiData.id, true)
      self:RefreshSalonConflictUIShow(salonItemConf)
    end
  end
end

function UMG_Closet_Item_C:ResetItemState()
  self.bIsResetting = true
  self:StopAllAnimations()
  self:PlayAnimation(self.Reset)
  self.Selected:SetRenderOpacity(0)
  self.Bg_Selected_Orange:SetRenderOpacity(0)
  self.Bg_Selected_Purple:SetRenderOpacity(0)
  self.QualityColor:SetRenderOpacity(1)
  self.Bg:SetRenderOpacity(1)
  self.Bg_1:SetRenderOpacity(0)
  self.Bg_2:SetRenderOpacity(0)
  self.Bg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Bg_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local defaultTransform = UE4.FWidgetTransform()
  self.Bg:SetRenderTransform(defaultTransform)
  self.Bg_1:SetRenderTransform(defaultTransform)
  self.Bg_2:SetRenderTransform(defaultTransform)
  self.Bg_Mask:SetRenderTransform(defaultTransform)
  self.Fx_tequan:SetRenderOpacity(0)
  self.Fx_tequan_2:SetRenderOpacity(0)
  self.Fx_COLOR_Orange:SetRenderOpacity(0)
  self.Fx_COLOR_Purple:SetRenderOpacity(0)
  self.RedDot:SetupKey(0)
  self.RedDot_1:SetupKey(0)
  self.RedDot:Refresh()
  self.RedDot_1:Refresh()
  self.MutualExclusivity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bIsResetting = false
end

return UMG_Closet_Item_C

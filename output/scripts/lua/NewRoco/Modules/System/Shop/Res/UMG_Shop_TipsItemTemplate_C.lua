local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Shop_TipsItemTemplate_C = Base:Extend("UMG_Shop_TipsItemTemplate_C")

function UMG_Shop_TipsItemTemplate_C:OnConstruct()
end

function UMG_Shop_TipsItemTemplate_C:OnDestruct()
end

function UMG_Shop_TipsItemTemplate_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  self:InitItem()
end

function UMG_Shop_TipsItemTemplate_C:OnItemSelected(_bSelected)
  if _bSelected then
    self:PlayAnimation(self.Tips_press)
    local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdByExchangeVoucherId, self.uiData.Id)
    if suitId then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, suitId, nil, {
        Caller = self,
        CallBack = self.CancelSelect
      })
    else
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.Id, self.uiData.Type, false, nil, nil, nil, nil, nil, self, self.CancelSelect)
    end
  end
end

function UMG_Shop_TipsItemTemplate_C:CancelSelect()
  self:StopAllAnimations()
  self:PlayAnimationReverse(self.Tips_press)
end

function UMG_Shop_TipsItemTemplate_C:InitItem()
  self.BagCiuntText:SetText("x" .. tostring(self.uiData.Count))
  if self.uiData.Type == Enum.GoodsType.GT_BAGITEM then
    local bagitemconf = _G.DataConfigManager:GetBagItemConf(self.uiData.Id)
    self.Icon:SetPath(bagitemconf.big_icon)
    self.BagText:SetText(bagitemconf.name)
    self:SetQuality(bagitemconf.item_quality)
    if bagitemconf and bagitemconf.item_behavior and bagitemconf.item_behavior[1] and bagitemconf.is_auto_use then
      local itemBehavior = bagitemconf.item_behavior[1]
      if itemBehavior and itemBehavior.use_action and itemBehavior.use_action == Enum.ItemBehavior.IB_GET_AWARD and itemBehavior.ratio and itemBehavior.ratio[1] then
        local awardConf = _G.DataConfigManager:GetRewardConf(itemBehavior.ratio[1])
        if awardConf and awardConf.RewardItem and awardConf.RewardItem[1] then
          local awardItem = awardConf.RewardItem[1]
          if awardItem.Type == Enum.GoodsType.GT_CARD_SKIN then
            local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(awardItem.Id)
            self:SetQuality(cardSkinConf.card_quality)
          end
        end
      end
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_VITEM then
    local Vitemconf = _G.DataConfigManager:GetVisualItemConf(self.uiData.Id)
    self.Icon:SetPath(Vitemconf.bigIcon)
    self.BagText:SetText(Vitemconf.displayName)
    self:SetQuality(Vitemconf.item_quality)
  elseif self.uiData.Type == Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(self.uiData.Id)
    if cardSkinConf then
      self:SetQuality(cardSkinConf.card_quality)
      self.Icon:SetPath(string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path))
      self.BagText:SetText(cardSkinConf.skin_resource_name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_CARD_ICON then
    local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(self.uiData.Id)
    if GetCardIconConf then
      self:SetQuality(GetCardIconConf.card_quality)
      self.Icon:SetPath(string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, GetCardIconConf.icon_resource_path, GetCardIconConf.icon_resource_path))
      self.BagText:SetText(GetCardIconConf.icon_resource_name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_CARD_LABEL then
    local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(self.uiData.Id)
    if CardLabelConf then
      self:SetQuality(CardLabelConf.card_quality)
      self.Icon:SetPath(CardLabelConf.label_icon or UEPath.CARD_LABEL_PATH)
      self.BagText:SetText(CardLabelConf.label_text)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(self.uiData.Id)
    if fashionConf then
      local grade = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
      self:SetQuality(grade)
      self.Icon:SetPath(fashionConf.suits_icon)
      self.BagText:SetText(fashionConf.name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(self.uiData.Id)
    if fashionConf then
      local grade = fashionConf.item_quality
      self:SetQuality(grade)
      self.Icon:SetPath(fashionConf.icon)
      self.BagText:SetText(fashionConf.name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(self.uiData.Id)
    if salonConf then
      local grade = salonConf.item_quality
      self:SetQuality(grade)
      self.Icon:SetPath(salonConf.icon)
      self.BagText:SetText(salonConf.name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_SHARE_FORM then
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(self.uiData.Id)
    if shareConf then
      self:SetQuality(shareConf.item_quality)
      self.Icon:SetPath(shareConf.item_icon)
      self.BagText:SetText(shareConf.item_name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(self.uiData.Id)
    if itemConf then
      self:SetQuality(5)
      self.Icon:SetPath(itemConf.icon_path)
      self.BagText:SetText(itemConf.name_text)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_EMOJI then
    local ChatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(self.uiData.Id)
    if ChatEmojiConf then
      self:SetQuality(ChatEmojiConf.card_quality)
      self.Icon:SetPath(ChatEmojiConf.emoji_goods_icon)
      self.BagText:SetText(ChatEmojiConf.emoji_resource_name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_FASHION_PACKAGE then
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(self.uiData.Id)
    if fashionPackageConf then
      self:SetQuality(5)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BagText:SetText(fashionPackageConf.name)
    end
  elseif self.uiData.Type == Enum.GoodsType.GT_FASHION_BOND then
    local FashionBondConf = _G.DataConfigManager:GetFashionBondConf(self.uiData.Id)
    if FashionBondConf then
      self:SetQuality(5)
      self.Icon:SetPath(FashionBondConf.fashion_bond_icon)
      self.BagText:SetText(FashionBondConf.name)
    end
  end
end

function UMG_Shop_TipsItemTemplate_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.IconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.IconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.IconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.IconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.IconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_Shop_TipsItemTemplate_C:OnDeactive()
end

return UMG_Shop_TipsItemTemplate_C

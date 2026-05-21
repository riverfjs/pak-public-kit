local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Pet_GetItems_Item_C = Base:Extend("UMG_Pet_GetItems_Item_C")

function UMG_Pet_GetItems_Item_C:OnConstruct()
end

function UMG_Pet_GetItems_Item_C:OnDestruct()
end

function UMG_Pet_GetItems_Item_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self:updateItemInfo()
end

function UMG_Pet_GetItems_Item_C:updateItemInfo()
  local itemId = self.uiData.id
  local itemType = self.uiData.type
  local tag = self.uiData.tag
  local quality
  if itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(itemId)
    if vItemsConf then
      quality = vItemsConf.item_quality
      self.Icon:SetPath(NRCUtils:FormatConfIconPath(vItemsConf.bigIcon, _G.UIIconPath.BagItemPath))
      self.Text_Quantity:SetText(self.uiData.num)
    else
      self:LogError("VisualItemConf\228\184\173\228\184\141\229\173\152\229\156\168ID" .. itemId .. "\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174")
    end
  elseif itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
    quality = bagItemConf.item_quality
    self.Icon:SetPath(NRCUtils:FormatConfIconPath(bagItemConf.icon, _G.UIIconPath.BagItemPath))
    self.Text_Quantity:SetText(self.uiData.num)
  elseif itemType == _G.Enum.GoodsType.GT_PET then
    local petData = self.uiData.pet_data
    if petData then
      itemId = petData.conf_id
    end
    local petInfo = _G.DataConfigManager:GetPetConf(itemId)
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        quality = petBaseConf.quality
        self.Icon:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
        self.Text_Quantity:SetText(self.uiData.num)
      end
    end
  end
  if quality then
    self:SetQuality(quality)
  end
  if 0 ~= tag then
    self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if 6 == tag then
      self.Switcher_33:SetActiveWidgetIndex(0)
    elseif tag == Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST then
      self.Switcher_33:SetActiveWidgetIndex(2)
    end
  end
  if tag == Enum.RewardTag.RTA_SHINYDOUBLE or tag == Enum.RewardTag.RTA_ACTIVITY then
    self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher_33:SetActiveWidgetIndex(1)
  end
end

function UMG_Pet_GetItems_Item_C:SetQuality(quality)
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

function UMG_Pet_GetItems_Item_C:getQuality(quality)
  self.BGColor:SetVisibility(UE4.ESlateVisibility.Visible)
  if 0 == quality then
    self.BGColor:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_5)
  end
end

function UMG_Pet_GetItems_Item_C:SetPetQuality(quality)
  self.BGColor:SetVisibility(UE4.ESlateVisibility.Visible)
  if quality == _G.Enum.PetQuality.PQ_BLUE then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_3)
  elseif quality == _G.Enum.PetQuality.PQ_PURPLE then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_4)
  elseif quality == _G.Enum.PetQuality.PQ_ORANGE then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_5)
  else
    self.BGColor:SetPath(UEPath.PROP_QUALITY_NONE)
  end
end

function UMG_Pet_GetItems_Item_C:SelectItem()
  if self.uiData.type == _G.Enum.GoodsType.GT_BAGITEM then
    local Itemdata = _G.DataConfigManager:GetBagItemConf(self.uiData.id)
    if Itemdata.lable_type == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
      local skillMachineid = Itemdata.item_behavior[1].ratio[1]
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillMachineid, true, Itemdata.id)
    else
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.id, self.uiData.type, false)
    end
  elseif self.uiData.type == _G.Enum.GoodsType.GT_PET then
    local petId = self.uiData.id
    local petData = self.uiData.pet_data
    if petData then
      petId = petData.conf_id
    end
    local pet_conf = _G.DataConfigManager:GetPetConf(petId)
    local param = {
      petbaseId = pet_conf.base_id,
      needBlur = false,
      notAcquired = false,
      isSketch = true
    }
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_OpenMagicDetailTips, param)
    _G.NRCAudioManager:PlaySound2DAuto(1284, "UMG_ItemRewardsTemple_C:OnClick")
  else
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.id, self.uiData.type, false)
  end
end

function UMG_Pet_GetItems_Item_C:OnItemSelected(_bSelected)
  if _bSelected then
    self:SelectItem()
  end
end

function UMG_Pet_GetItems_Item_C:OnDeactive()
end

return UMG_Pet_GetItems_Item_C

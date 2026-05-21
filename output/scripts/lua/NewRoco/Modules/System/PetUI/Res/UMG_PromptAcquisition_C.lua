local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PromptAcquisition_C = Base:Extend("UMG_PromptAcquisition_C")

function UMG_PromptAcquisition_C:OnConstruct()
end

function UMG_PromptAcquisition_C:OnDestruct()
end

function UMG_PromptAcquisition_C:OnItemUpdate(_data, datalist, index)
  self.petNeedChangeBloodAndLevelDeficiency = false
  self.data = _data
  if not self.data then
    Log.Error("UMG_PromptAcquisition_C:OnItemUpdate --> _data is nil")
    return
  end
  if _data.MaxDesiredWidth and self.TextSize then
    self.TextSize:SetMaxDesiredWidth(_data.MaxDesiredWidth)
  end
  self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemIcon2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PetIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
    local petData
    if self.data.petGid then
      petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
      if petData then
        self.PetIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
      end
    else
      self.PetIcon:SetIconPathAndMaterial(self.data.petBaseId)
    end
    self.PetIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local nCanLock = self:CheckCanLockByLevelUp(petData, tonumber(self.data.text))
    self:SetUnlockImageColor(nCanLock)
    if nCanLock then
      self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_1, self.data.text))
    else
      self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_4, self.data.text))
    end
  elseif self.data.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK then
    self.ItemIcon2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemIcon2:SetPath(self.data.icon)
    local nCanLock = self:CheckCanLockByCostItem(self.data.bagItemIds[1])
    self:SetUnlockImageColor(nCanLock)
    if nCanLock then
      self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_2, self.data.text))
    else
      self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_5, self.data.text))
    end
  elseif self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemIcon:SetPath(self.data.icon)
    local needLevel = 0
    local petCurLevel = 0
    local petData
    local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.data.petBaseId)
    if levelSkillConf then
      needLevel = levelSkillConf.blood_skill_level_point
    end
    if self.data.petGid then
      petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
    end
    if petData then
      petCurLevel = petData.level
    end
    local nCanLock = self:CheckCanLockByCostItems(self.data.bagItemIds)
    if needLevel > petCurLevel and petData and nCanLock then
      nCanLock = self:CheckCanLockByLevelUp(petData, needLevel)
    end
    self:SetUnlockImageColor(nCanLock)
    self.petNeedChangeBloodAndLevelDeficiency = needLevel > petCurLevel
    if needLevel > petCurLevel then
      if self.data.shrinkTextSize then
        if nCanLock then
          self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_7, self.data.text, needLevel))
        else
          self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_8, self.data.text, needLevel))
        end
      elseif nCanLock then
        self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_9, self.data.text, needLevel))
      else
        self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_10, self.data.text, needLevel))
      end
    elseif nCanLock then
      self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_3, self.data.text))
    else
      self.MaxLevelHint_2:SetText(string.format(LuaText.skill_source_desc_6, self.data.text))
    end
  elseif self.data.type == Enum.PetNewSkillSrc.PNSS_LEGENDARY then
    self.PetIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.data.petGid then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
      if petData then
        self.PetIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
      end
    else
      self.PetIcon:SetIconPathAndMaterial(self.data.petBaseId)
    end
    self.MaxLevelHint_2:SetText(string.format(LuaText.legendary_tips_1, self.data.text))
  else
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemIcon:SetPath(self.data.icon)
    self.MaxLevelHint_2:SetText(self.data.text)
    self:SetUnlockImageColor(false)
  end
  if self.data.bQuickUnlock and self.data.type ~= Enum.PetNewSkillSrc.PNSS_LEGENDARY then
    self.NRCImage_58:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.NRCImage_58:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PromptAcquisition_C:SetUnlockImageColor(nCanLock)
  if nCanLock then
    self.NRCImage_58:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
  else
    self.NRCImage_58:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#929086FF"))
  end
end

function UMG_PromptAcquisition_C:OnItemSelected(_bSelected)
  if _bSelected and self.data.bQuickUnlock and (self.data.type == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP or self.data.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK or self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD) then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
    if self.petNeedChangeBloodAndLevelDeficiency then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenUnlockSkillsPanel, self.data)
    else
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenSkillLearningPanel, self.data)
    end
  end
end

function UMG_PromptAcquisition_C:OnDeactive()
end

function UMG_PromptAcquisition_C:CheckCanLockByLevelUp(petData, unLockLv)
  if not self.data.bQuickUnlock then
    return true
  end
  local maxLevel, MaxLevelInfo = PetUtils.GetPetMaxLevel()
  if unLockLv > maxLevel then
    return false
  end
  if petData then
    local petInfo = PetUtils.GetPetBaseInfoByUseItemVisualType(nil, petData)
    local petLevelConf = _G.DataConfigManager:GetPetLevelConf(unLockLv - 1)
    local goalNeedExp = petLevelConf and petLevelConf.pet_exp or 0
    local curNeedExp = goalNeedExp - petInfo.curPetExp
    local itemList = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetCanFeedItem)
    local haveExp = 0
    for i, v in ipairs(itemList) do
      local PetInfo = PetUtils.GetPetBaseInfoByUseItemVisualType(v, petData)
      local num = v.Item and v.Item.num or 0
      haveExp = haveExp + num * PetInfo.itemPetExp
      if curNeedExp <= haveExp then
        return true
      end
    end
  end
  return false
end

function UMG_PromptAcquisition_C:CheckCanLockByCostItem(bagItemId)
  if not self.data.bQuickUnlock then
    return true
  end
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
  if bagItem and bagItem.num > 0 then
    return true
  end
  local allExchangeConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.EXCHANGE_CONF)
  for i, v in pairs(allExchangeConf) do
    for j, item in ipairs(v.get_item) do
      if item.get_goods_id == bagItemId then
        local result = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CheckExchangeAvailable, v.id)
        if result then
          return true
        else
          break
        end
      end
    end
  end
  return false
end

function UMG_PromptAcquisition_C:CheckCanLockByCostItems(bagItemIds)
  if not self.data.bQuickUnlock then
    return true
  end
  for i, v in ipairs(bagItemIds) do
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, v)
    if bagItem and bagItem.num > 0 then
      return true, v
    end
  end
  for k, bagItemId in ipairs(bagItemIds) do
    local allExchangeConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.EXCHANGE_CONF)
    for i, v in pairs(allExchangeConf) do
      for j, item in ipairs(v.get_item) do
        if item.get_goods_id == bagItemId then
          local result = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CheckExchangeAvailable, v.id)
          if result then
            return true
          else
            break
          end
        end
      end
    end
  end
end

return UMG_PromptAcquisition_C

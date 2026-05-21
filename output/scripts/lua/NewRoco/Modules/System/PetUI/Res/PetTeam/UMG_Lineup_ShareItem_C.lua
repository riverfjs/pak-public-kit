local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Lineup_ShareItem_C = Base:Extend("UMG_Lineup_ShareItem_C")

function UMG_Lineup_ShareItem_C:OnConstruct()
end

function UMG_Lineup_ShareItem_C:OnDestruct()
end

function UMG_Lineup_ShareItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.petID = self.data.base_conf_id
  if _data.empty then
    self:UpdateEmptyUI()
  else
    self:UpdateUI()
  end
end

function UMG_Lineup_ShareItem_C:UpdateEmptyUI()
  self.NRCSwitcher1:SetActiveWidgetIndex(1)
end

function UMG_Lineup_ShareItem_C:UpdateUI()
  self.petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petID, true)
  local data = self.data
  local PetBaseConf = self.petBaseConf
  local isRandomPet = data and data.isRandomPet
  local name = PetBaseConf and PetBaseConf.name
  local nrcSwitcherActiveIndex = 0
  local unit_type = PetBaseConf and PetBaseConf.unit_type or {}
  if isRandomPet then
    nrcSwitcherActiveIndex = 2
  else
    nrcSwitcherActiveIndex = 0
    if PetBaseConf then
      self.PetIcon:SetPath(PetBaseConf.JL_small_res)
      self.Name:SetText(name)
    end
    self:updatePetTypeIcon(unit_type)
    self.PersonalityIndividualValue:InitGridView(self.data.NatureDataList)
    local NatureDataList1 = {}
    local SharePetNatureConf = _G.DataConfigManager:GetNatureConf(self.data.nature, true)
    if not SharePetNatureConf then
      Log.Info("UMG_Lineup_ShareItem_C:UpdateUI SharePetNatureConf is nil")
    end
    local share_pos_effect = SharePetNatureConf and SharePetNatureConf.positive_effect
    local share_neg_effect = SharePetNatureConf and SharePetNatureConf.negative_effect
    local natureName = SharePetNatureConf and SharePetNatureConf.name or ""
    if self.data.changed_nature_pos_attr_type and self.data.changed_nature_pos_attr_type > 0 then
      share_pos_effect = self:GetChangeAttrReqEnum(self.data.changed_nature_pos_attr_type)
    end
    if self.data.changed_nature_neg_attr_type and self.data.changed_nature_neg_attr_type > 0 then
      share_neg_effect = self:GetChangeAttrReqEnum(self.data.changed_nature_neg_attr_type)
    end
    if SharePetNatureConf then
      table.insert(NatureDataList1, {
        share_pos_effect = share_pos_effect,
        share_neg_effect = share_neg_effect,
        natureName = natureName,
        type = 0
      })
    end
    self.PersonalityIndividualValue1:InitGridView(NatureDataList1)
    local skills = data and data.skills
    self.SkillList_1:InitGridView(skills)
  end
  self.NRCSwitcher1:SetActiveWidgetIndex(nrcSwitcherActiveIndex)
  self.Attr_1:InitGridView(unit_type)
end

function UMG_Lineup_ShareItem_C:updatePetTypeIcon(_dicTypes)
  local typeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  local petDataInfoBloodId = self.petDataInfo and self.petDataInfo.blood_id
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.data.blood_id or petDataInfoBloodId, true)
  if PetBloodConf then
    table.insert(typeList, PetBloodConf.icon)
  end
  self.Attr:InitGridView(typeList)
end

function UMG_Lineup_ShareItem_C:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX then
    return Enum.AttributeType.AT_HPMAX_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYATK then
    return Enum.AttributeType.AT_PHYATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEATK then
    return Enum.AttributeType.AT_SPEATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYDEF then
    return Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEDEF then
    return Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEED then
    return Enum.AttributeType.AT_SPEED_PERCENT
  end
end

return UMG_Lineup_ShareItem_C

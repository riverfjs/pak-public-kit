local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_FriendTeamItem_Details_C = Base:Extend("UMG_FriendTeamItem_Details_C")

function UMG_FriendTeamItem_Details_C:OnConstruct()
end

function UMG_FriendTeamItem_Details_C:OnDestruct()
end

function UMG_FriendTeamItem_Details_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self:UpdateUI()
end

function UMG_FriendTeamItem_Details_C:GetChangeAttrReqEnum(attribute)
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

function UMG_FriendTeamItem_Details_C:UpdatePetTypeIcon(_dicTypes)
  local petDataInfo = self.data.PetData
  if not petDataInfo then
    return
  end
  local typeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petDataInfo.blood_id)
  if PetBloodConf then
    table.insert(typeList, PetBloodConf.icon)
  end
  self.Attr:InitGridView(typeList)
end

function UMG_FriendTeamItem_Details_C:OnItemSelected(_bSelected)
end

function UMG_FriendTeamItem_Details_C:UpdateUI()
  local petDataInfo = self.data.PetData
  local petGid = petDataInfo and petDataInfo.gid
  local isRandomPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
  local nrcSwitcherActiveIndex = 0
  if isRandomPet then
    nrcSwitcherActiveIndex = 1
    self:UpdateUIForRandomPet()
  else
    self:UpdateUIForCommonPet()
  end
  self.NRCSwitcher_0:SetActiveWidgetIndex(nrcSwitcherActiveIndex)
end

function UMG_FriendTeamItem_Details_C:UpdateUIForRandomPet()
  local petDataInfo = self.data.PetData
  local petBaseConfId = petDataInfo and petDataInfo.base_conf_id
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId)
  local unitType = petBaseConf and petBaseConf.unit_type or {}
  local DepartmentVisibility = UE.ESlateVisibility.SelfHitTestInvisible
  self.Attr_1:InitGridView(unitType)
  self.Department:SetVisibility(DepartmentVisibility)
end

function UMG_FriendTeamItem_Details_C:UpdateUIForCommonPet()
  local petDataInfo = self.data.PetData
  if not petDataInfo then
    return
  end
  self.PetLevel:SetText(petDataInfo.level)
  self.PetLevel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.petBaseConf = _G.DataConfigManager:GetPetbaseConf(petDataInfo.base_conf_id)
  self.Name:SetText(self.petBaseConf.name)
  self.HeadIcon:SetIconPathAndMaterial(petDataInfo.base_conf_id, petDataInfo.mutation_type, petDataInfo.glass_info)
  self:UpdatePetTypeIcon(self.petBaseConf.unit_type)
  local texingID = self.petBaseConf.pet_feature
  local texingCfg = _G.DataConfigManager:GetSkillConf(texingID)
  if texingCfg then
    self.SkillIcon_1:SetPath(texingCfg.icon)
    self.SkillNameTxt_1:SetText(texingCfg.name)
  end
  local NatureDataList = {}
  if petDataInfo.attribute_info.attack.talent and 0 ~= petDataInfo.attribute_info.attack.talent then
    table.insert(NatureDataList, {
      type = 1,
      attribute = Enum.AttributeType.AT_PHYATK_PERCENT
    })
  end
  if petDataInfo.attribute_info.defense.talent and 0 ~= petDataInfo.attribute_info.defense.talent then
    table.insert(NatureDataList, {
      type = 1,
      attribute = Enum.AttributeType.AT_PHYDEF_PERCENT
    })
  end
  if petDataInfo.attribute_info.hp.talent and 0 ~= petDataInfo.attribute_info.hp.talent then
    table.insert(NatureDataList, {
      type = 1,
      attribute = Enum.AttributeType.AT_HPMAX_PERCENT
    })
  end
  if petDataInfo.attribute_info.special_attack.talent and 0 ~= petDataInfo.attribute_info.special_attack.talent then
    table.insert(NatureDataList, {
      type = 1,
      attribute = Enum.AttributeType.AT_SPEATK_PERCENT
    })
  end
  if petDataInfo.attribute_info.special_defense.talent and 0 ~= petDataInfo.attribute_info.special_defense.talent then
    table.insert(NatureDataList, {
      type = 1,
      attribute = Enum.AttributeType.AT_SPEDEF_PERCENT
    })
  end
  if petDataInfo.attribute_info.speed.talent and 0 ~= petDataInfo.attribute_info.speed.talent then
    table.insert(NatureDataList, {
      type = 1,
      attribute = Enum.AttributeType.AT_SPEED_PERCENT
    })
  end
  self.PersonalityIndividualValue1:InitGridView(NatureDataList)
  local NatureDataList1 = {}
  local SharePetNatureConf = _G.DataConfigManager:GetNatureConf(petDataInfo.nature)
  local share_pos_effect = SharePetNatureConf.positive_effect
  local share_neg_effect = SharePetNatureConf.negative_effect
  if petDataInfo.changed_nature_pos_attr_type and petDataInfo.changed_nature_pos_attr_type > 0 then
    share_pos_effect = self:GetChangeAttrReqEnum(petDataInfo.changed_nature_pos_attr_type)
  end
  if petDataInfo.changed_nature_neg_attr_type and petDataInfo.changed_nature_neg_attr_type > 0 then
    share_neg_effect = self:GetChangeAttrReqEnum(petDataInfo.changed_nature_neg_attr_type)
  end
  table.insert(NatureDataList1, {
    share_pos_effect = share_pos_effect,
    share_neg_effect = share_neg_effect,
    natureName = SharePetNatureConf.name,
    type = 0
  })
  self.PersonalityIndividualValue:InitGridView(NatureDataList1)
  local petSkillEquipInfoList = self:GetPetSkillEquipInfoList(self.data)
  if petDataInfo.blood_id == Enum.PetBloodType.PBT_FANTASTIC or petDataInfo.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    for _, v in ipairs(petSkillEquipInfoList) do
      if v.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
        v.bFantastic = true
        local data = self.data
        local skillId = v and v.id
        local petData = data and data.PetData
        local petGid = petData and petData.gid
        local seasonId = PetUtils.TryGetPetSkillSeasonId(petGid, skillId)
        v.fantasticSeasonId = seasonId
        break
      end
    end
  end
  self.SkillList_1:InitGridView(petSkillEquipInfoList)
end

function UMG_FriendTeamItem_Details_C:GetPetSkillEquipInfoList(friendTeamDetailsItemData)
  if not friendTeamDetailsItemData then
    return {}
  end
  if friendTeamDetailsItemData.SkillEquipList and #friendTeamDetailsItemData.SkillEquipList > 0 and friendTeamDetailsItemData.PetData.blood_id ~= Enum.PetBloodType.PBT_FANTASTIC and friendTeamDetailsItemData.PetData.blood_id ~= Enum.PetBloodType.PBT_NIGHTMARE then
    return friendTeamDetailsItemData.SkillEquipList
  end
  local petData = friendTeamDetailsItemData.PetData
  local petEquipSkills = {}
  if petData and petData.skill and petData.skill.skill_data then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  return petEquipSkills
end

return UMG_FriendTeamItem_Details_C

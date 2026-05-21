local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_SquadList_C = Base:Extend("UMG_SquadList_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")

function UMG_SquadList_C:OnConstruct()
  self:AddButtonListener(self.PetAlternativeBtn, self.OpenPetAlternative)
  NRCEventCenter:RegisterEvent("UMG_SquadList", self, PetUIModuleEvent.ChangePetSkill, self.ChangePetSkill)
  NRCEventCenter:RegisterEvent("UMG_SquadList", self, PetUIModuleEvent.IgnoreBloodDiff, self.IgnoreBloodDiff)
end

function UMG_SquadList_C:OnDestruct()
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ChangePetSkill, self.ChangePetSkill)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.IgnoreBloodDiff, self.IgnoreBloodDiff)
end

function UMG_SquadList_C:OnItemUpdate(_data, datalist, index)
  local data = _data
  local petData = data and data.petData
  if petData then
    local sharedPetData = data and data.sharedPetData
    local petBaseConfId = sharedPetData and sharedPetData.base_conf_id
    local isRandomPet = PetUtils.CheckIsRandomPetBase(petBaseConfId)
    if isRandomPet then
      self:RefreshForRandomPetData(_data, datalist, index)
    else
      self:RefreshForCommonPetData(_data, datalist, index)
    end
  else
    self:RefreshForEmpty(_data, datalist, index)
  end
end

function UMG_SquadList_C:RefreshForEmpty(_data, datalist, index)
  self:SetClickable(false)
  self.NRCSwitcher_2:SetActiveWidgetIndex(1)
end

function UMG_SquadList_C:RefreshForRandomPetData(_data, datalist, index)
  local switcherActiveIndex = 2
  local clickable = false
  local departmentVisibility = UE.ESlateVisibility.SelfHitTestInvisible
  self.data = _data
  self.index = index
  local data = _data
  local adjustedPet = data and data.petData
  local petGid = adjustedPet and adjustedPet.gid
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  local sharedPetData = data and data.sharedPetData
  local petBaseConfId = sharedPetData and sharedPetData.base_conf_id
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId, true)
  local unitTypeList = petBaseConf and petBaseConf.unit_type or {}
  local skillDamType = unitTypeList and unitTypeList[1] or 0
  local attrList = {}
  table.insert(attrList, skillDamType)
  self.Attr_1:InitGridView(attrList)
  self:SetClickable(clickable)
  self.NRCSwitcher_2:SetActiveWidgetIndex(switcherActiveIndex)
  self.Department:SetVisibility(departmentVisibility)
end

function UMG_SquadList_C:RefreshForCommonPetData(_data, datalist, index)
  self.NRCSwitcher_2:SetActiveWidgetIndex(0)
  self:SetClickable(true)
  self.data = _data
  self.index = index
  self.petData = self.data.petData
  self.checkTalentList = self.data.checkTalentList.checkList
  self.checkNatureList = self.data.checkNatureList.checkList
  self.needBloodItemList = self.data.needBloodItemList
  if 0 == self.data.petData.gid then
    self.petLost = true
  else
    self.petLost = false
  end
  self.ExclamationMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petData.gid)
  if self.petDataInfo and (self.petDataInfo.blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or self.petDataInfo.blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE) then
    for _, skill in ipairs(self.petDataInfo.skill.skill_data) do
      if skill.skill_src == _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
        self.fantasticId = skill.id
        break
      end
    end
  end
  self.sharedPetData = self.data.sharedPetData
  if self.petData and true == self.petData.AdjustCompleted then
    self.petID = self.petDataInfo.base_conf_id
    self.bloodID = self.petDataInfo.blood_id
    self.natureID = self.petDataInfo.nature
    self.HeadIcon:SetIconPathAndMaterial(self.petID, self.petDataInfo.mutation_type, self.petDataInfo.glass_info)
    self.ExclamationMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.skillData = self.petData.skills
  else
    self.petID = self.sharedPetData.base_conf_id
    self.bloodID = self.sharedPetData.blood_id
    self.natureID = self.sharedPetData.nature
    if self.sharedPetData.blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or self.sharedPetData.blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.sharedPetData.base_conf_id)
      for _, skill in ipairs(self.sharedPetData.skills) do
        local skillId = skill.id
        for _, v in ipairs(levelSkillConf.level) do
          if v.param == skillId then
            goto lbl_241
          end
        end
        for _, v in ipairs(levelSkillConf.machine_skill_group) do
          if v.machine_skill_id == skillId then
            goto lbl_241
          end
        end
        if levelSkillConf.blood_skill_COMMON == skillId or levelSkillConf.blood_skill_GRASS == skillId or levelSkillConf.blood_skill_FIRE == skillId or levelSkillConf.blood_skill_WATER == skillId or levelSkillConf.blood_skill_LIGHT == skillId or levelSkillConf.blood_skill_STONE == skillId or levelSkillConf.blood_skill_ICE == skillId or levelSkillConf.blood_skill_DRAGON == skillId or levelSkillConf.blood_skill_ELECTRIC == skillId or levelSkillConf.blood_skill_TOXIC == skillId or levelSkillConf.blood_skill_INSECT == skillId or levelSkillConf.blood_skill_FIGHT == skillId or levelSkillConf.blood_skill_WING == skillId or levelSkillConf.blood_skill_MOE == skillId or levelSkillConf.blood_skill_GHOST == skillId or levelSkillConf.blood_skill_DEMON == skillId or levelSkillConf.blood_skill_MECHANIC == skillId or levelSkillConf.blood_skill_PHANTOM == skillId then
        else
          self.shareFantasticId = skillId
          break
        end
        ::lbl_241::
      end
    end
    local fullSkillData = {}
    if 0 == self.petData.gid then
      self.skillData = self.sharedPetData.skills
      self.HeadIcon:SetIconPathAndMaterial(self.petID)
    else
      self.HeadIcon:SetIconPathAndMaterial(self.petID, self.petDataInfo.mutation_type, self.petDataInfo.glass_info)
      if self.sharedPetData.skills then
        for i, skill in pairs(self.sharedPetData.skills) do
          fullSkillData[i] = {}
          fullSkillData[i].sharedPetSkillData = skill
          if not self.petData.skills[i] then
            local data = {}
            data.pos = i
            data.id = 0
            self.petData.skills[i] = data
          end
          fullSkillData[i].petSkillData = self.petData.skills[i]
          fullSkillData[i].petIndex = self.index
          fullSkillData[i].petGid = self.data.petData.gid
          fullSkillData[i].fullPetSkillData = self.petData.skills
        end
        self.skillData = fullSkillData
      else
        Log.Error("UMG_SquadList_C", "sharedPetData.skills is nil")
      end
    end
  end
  self.petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petID)
  self:UpdateUI()
end

function UMG_SquadList_C:UpdateUI()
  if self.petBaseConf then
    self.Name:SetText(self.petBaseConf.name)
    self:updatePetTypeIcon(self.petBaseConf.unit_type)
    local texingID = self.petBaseConf.pet_feature
    local texingCfg = _G.DataConfigManager:GetSkillConf(texingID)
    if texingCfg then
      self.SkillIcon_1:SetPath(texingCfg.icon)
      self.SkillNameTxt_1:SetText(texingCfg.name)
    end
  end
  if self.fantasticId or self.shareFantasticId then
    for _, skill in ipairs(self.skillData) do
      if skill.sharedPetSkillData and skill.sharedPetSkillData.id == self.shareFantasticId and 0 == skill.petSkillData.id or skill.petSkillData and skill.petSkillData.id == self.fantasticId or skill.id and skill.id == self.shareFantasticId and 0 == self.petData.gid then
        skill.bFantastic = true
        local data = self.data
        local skillId = skill and skill.id
        local petData = self.petData
        local petGid = petData and petData.gid
        local seasonId = PetUtils.TryGetPetSkillSeasonId(petGid, skillId)
        skill.fantasticSeasonId = seasonId
        break
      end
    end
  end
  self.SkillList_1:InitGridView(self.skillData)
  if self.petDataInfo then
    self.PetLevel:SetText(self.petDataInfo.level)
  else
    self.PetLevel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.petLost then
    self.ExclamationMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local NatureDataList = {}
    if self.sharedPetData.attack_talent and 0 ~= self.sharedPetData.attack_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_PHYATK_PERCENT
      })
    end
    if self.sharedPetData.defense_talent and 0 ~= self.sharedPetData.defense_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_PHYDEF_PERCENT
      })
    end
    if self.sharedPetData.hp_talent and 0 ~= self.sharedPetData.hp_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_HPMAX_PERCENT
      })
    end
    if self.sharedPetData.special_attack_talent and 0 ~= self.sharedPetData.special_attack_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEATK_PERCENT
      })
    end
    if self.sharedPetData.special_defense_talent and 0 ~= self.sharedPetData.special_defense_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEDEF_PERCENT
      })
    end
    if self.sharedPetData.speed_talent and 0 ~= self.sharedPetData.speed_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEED_PERCENT
      })
    end
    self.PersonalityIndividualValue1:InitGridView(NatureDataList)
    local NatureDataList1 = {}
    local SharePetNatureConf = _G.DataConfigManager:GetNatureConf(self.natureID)
    local share_pos_effect = SharePetNatureConf and SharePetNatureConf.positive_effect
    local share_neg_effect = SharePetNatureConf and SharePetNatureConf.negative_effect
    if self.sharedPetData.changed_nature_pos_attr_type and self.sharedPetData.changed_nature_pos_attr_type > 0 then
      share_pos_effect = self:GetChangeAttrReqEnum(self.sharedPetData.changed_nature_pos_attr_type)
    end
    if self.sharedPetData.changed_nature_neg_attr_type and self.sharedPetData.changed_nature_neg_attr_type > 0 then
      share_neg_effect = self:GetChangeAttrReqEnum(self.sharedPetData.changed_nature_neg_attr_type)
    end
    table.insert(NatureDataList1, {
      share_pos_effect = share_pos_effect,
      share_neg_effect = share_neg_effect,
      natureName = SharePetNatureConf and SharePetNatureConf.name,
      type = 0
    })
    self.PersonalityIndividualValue:InitGridView(NatureDataList1)
  else
    if self.checkNatureList and #self.checkNatureList > 0 then
      self.PersonalityIndividualValue:InitGridView(self.checkNatureList)
    else
      local NatureDataList1 = {}
      local PetNatureConf = _G.DataConfigManager:GetNatureConf(self.petDataInfo.nature)
      local pos_effect = PetNatureConf.positive_effect
      local neg_effect = PetNatureConf.negative_effect
      if self.petDataInfo.changed_nature_pos_attr_type and self.petDataInfo.changed_nature_pos_attr_type > 0 then
        pos_effect = self:GetChangeAttrReqEnum(self.petDataInfo.changed_nature_pos_attr_type)
      end
      if self.petDataInfo.changed_nature_neg_attr_type and self.petDataInfo.changed_nature_neg_attr_type > 0 then
        neg_effect = self:GetChangeAttrReqEnum(self.petDataInfo.changed_nature_neg_attr_type)
      end
      table.insert(NatureDataList1, {
        share_pos_effect = pos_effect,
        share_neg_effect = neg_effect,
        natureName = PetNatureConf.name,
        type = 0
      })
      self.PersonalityIndividualValue:InitGridView(NatureDataList1)
    end
    if self.checkTalentList and #self.checkTalentList > 0 then
      self.PersonalityIndividualValue1:InitGridView(self.checkTalentList)
    else
      local NatureDataList = {}
      local attribute_info = self.petDataInfo.attribute_info
      if attribute_info.attack.talent and 0 ~= attribute_info.attack.talent then
        table.insert(NatureDataList, {
          type = 1,
          attribute = Enum.AttributeType.AT_PHYATK_PERCENT
        })
      end
      if attribute_info.defense.talent and 0 ~= attribute_info.defense.talent then
        table.insert(NatureDataList, {
          type = 1,
          attribute = Enum.AttributeType.AT_PHYDEF_PERCENT
        })
      end
      if attribute_info.hp.talent and 0 ~= attribute_info.hp.talent then
        table.insert(NatureDataList, {
          type = 1,
          attribute = Enum.AttributeType.AT_HPMAX_PERCENT
        })
      end
      if attribute_info.special_attack.talent and 0 ~= attribute_info.special_attack.talent then
        table.insert(NatureDataList, {
          type = 1,
          attribute = Enum.AttributeType.AT_SPEATK_PERCENT
        })
      end
      if attribute_info.special_defense.talent and 0 ~= attribute_info.special_defense.talent then
        table.insert(NatureDataList, {
          type = 1,
          attribute = Enum.AttributeType.AT_SPEDEF_PERCENT
        })
      end
      if attribute_info.speed.talent and 0 ~= attribute_info.speed.talent then
        table.insert(NatureDataList, {
          type = 1,
          attribute = Enum.AttributeType.AT_SPEED_PERCENT
        })
      end
      self.PersonalityIndividualValue1:InitGridView(NatureDataList)
    end
  end
end

function UMG_SquadList_C:GetChangeAttrReqEnum(attribute)
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

function UMG_SquadList_C:updatePetTypeIcon(unit_type)
  local unitTable = {}
  for k, v in ipairs(unit_type) do
    if v then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(v)
      table.insert(unitTable, {
        Name = typeDic.short_name,
        Path = typeDic.type_icon
      })
    end
  end
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.bloodID)
  if self.needBloodItemList and PetBloodConf then
    if self.needBloodItemList.IsIgnore or 23 == self.bloodID then
      PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petDataInfo.blood_id)
      table.insert(unitTable, {
        Name = PetBloodConf.blood_name,
        Path = PetBloodConf.icon,
        needBloodItemList = self.needBloodItemList
      })
    else
      table.insert(unitTable, {
        Name = PetBloodConf.blood_name,
        Path = PetBloodConf.icon,
        needBloodItemList = self.needBloodItemList
      })
    end
  elseif PetBloodConf then
    table.insert(unitTable, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  self.Attr:InitGridView(unitTable)
end

function UMG_SquadList_C:OnItemSelected(_bSelected)
end

function UMG_SquadList_C:OnDeactive()
end

function UMG_SquadList_C:OpenPetAlternative()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_SquadList_C:OpenPetAlternative")
  local req = ProtoMessage:newZonePetGetAlternativePetsReq()
  req.shared_pet = self.sharedPetData
  req.team_type = self.data.teamType
  local petGidList = self.data and self.data.PetGidList or {}
  local teamMates = {}
  for i, petGid in ipairs(petGidList) do
    local isRandomPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
    if not isRandomPet then
      table.insert(teamMates, petGid)
    end
  end
  req.team_mates = teamMates
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_PET_GET_ALTERNATIVE_PETS_REQ, req, self, self.OpenGetPetAlternativeRsp, false, false)
end

function UMG_SquadList_C:OpenGetPetAlternativeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.pets and #rsp.pets > 0 then
      NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetAlternative, rsp.pets, self.index)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_no_recommend_pet)
    end
  end
end

function UMG_SquadList_C:ChangePetSkill(startIndex, skillIndex, skillID)
  if startIndex == self.index then
    self.skillData[skillIndex].petSkillData.id = skillID
    self.skillData[skillIndex].petSkillData.pos = skillIndex
    if self.fantasticId and self.fantasticId == skillID then
      self.skillData[skillIndex].bFantastic = true
      local petData = self.petData
      local petGid = petData and petData.gid
      local seasonId = PetUtils.TryGetPetSkillSeasonId(petGid, skillID)
      self.skillData[skillIndex].fantasticSeasonId = seasonId
    else
      self.skillData[skillIndex].bFantastic = false
    end
  end
  self.SkillList_1:InitGridView(self.skillData)
end

function UMG_SquadList_C:IgnoreBloodDiff(petGid)
  if self.data and petGid == self.data.petData.gid then
    for i = 1, self.Attr:GetItemCount() do
      local item = self.Attr:GetItemByIndex(i - 1)
      item:HideDiffMark()
    end
  end
end

return UMG_SquadList_C

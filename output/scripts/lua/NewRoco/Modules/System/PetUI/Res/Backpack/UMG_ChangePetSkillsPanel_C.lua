local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_ChangePetSkillsPanel_C = _G.NRCPanelBase:Extend("UMG_ChangePetSkillsPanel_C")

function UMG_ChangePetSkillsPanel_C:SetHerbologyBadgeMode(bEnable, initialSkillId, lockedSkillId)
  self.bHerbologyBadgeMode = bEnable
  self.herbologyBadgeSelectedSkillId = initialSkillId
  self.herbologyBadgeLockedSkillId = lockedSkillId
end

function UMG_ChangePetSkillsPanel_C:GetHerbologyBadgeSelectedSkillId()
  return self.herbologyBadgeSelectedSkillId
end

function UMG_ChangePetSkillsPanel_C:OnEnable(petData)
  self.petMaxLevelLimit = (_G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit") or {}).num or 60
  if not self.petUIModule then
    self.petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  end
  if not self.ModuleData then
    self.ModuleData = self.petUIModule.data
  end
  self.NeedOpenAnim = NeedOpenAnim
  self:InitFilterAndSort()
  self:RefreshUI(petData)
  if self.NeedOpenAnim then
    self:PlayAnimation(self.In)
  else
    self:PlayAnimation(self.Change)
  end
  self:OnAddEventListener()
end

function UMG_ChangePetSkillsPanel_C:ReSetEquipSkillEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.EquipSkill, self.OnEquipSkill)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnEquipAssumptionSkill, self.ShowPetSkill)
  _G.NRCEventCenter:RegisterEvent("UMG_ChangePetSkillsPanel_C", self, PetUIModuleEvent.EquipSkill, self.OnEquipSkill)
  _G.NRCEventCenter:RegisterEvent("UMG_ChangePetSkillsPanel_C", self, PetUIModuleEvent.OnEquipAssumptionSkill, self.ShowPetSkill)
  self.ItemList:SetItemSelectedCallback(self.OnSkillItemSelected, self)
end

function UMG_ChangePetSkillsPanel_C:OnDisable()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, nil)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.EquipSkill, self.OnEquipSkill)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnEquipAssumptionSkill, self.ShowPetSkill)
  self.bHerbologyBadgeMode = false
  self.herbologyBadgeSelectedSkillId = nil
  self.herbologyBadgeLockedSkillId = nil
end

function UMG_ChangePetSkillsPanel_C:OnSkillItemSelected(item, rawIndex, userClick)
  if userClick then
    item:OnItemSelectedByClick()
  end
end

function UMG_ChangePetSkillsPanel_C:RefreshUI(petData)
  if not self.petData or self.petData.gid ~= petData.gid then
    self:InitFilterAndSort()
    if self.bHerbologyBadgeMode then
      local posToIdDic = {}
      if self.herbologyBadgeSelectedSkillId then
        posToIdDic[1] = self.herbologyBadgeSelectedSkillId
      end
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, petData.gid, posToIdDic)
    else
      local posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, petData.gid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, petData.gid, posToIdDic)
    end
  end
  self.petData = petData
  if petData then
    self.petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  end
  self:ShowPetSkill()
end

function UMG_ChangePetSkillsPanel_C:InitFilterAndSort()
  self.filterRule = nil
  self.sortRule = _G.DataConfigManager:GetSkillSequenceConf(1)
  self.skillSortReverse = false
  self.SkillIdToSourceMap = {}
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
end

function UMG_ChangePetSkillsPanel_C:SetFromWeeklyChallengeBattle(bFromWeeklyChallengeBattle)
  self.bFromWeeklyChallengeBattle = bFromWeeklyChallengeBattle
  self:RefreshUI(self.petData)
end

function UMG_ChangePetSkillsPanel_C:GetAllSkills(_petData)
  local skills = {}
  local skillIds = {}
  if _petData and _petData.skill and _petData.skill.skill_data then
    for _, skillData in ipairs(_petData.skill.skill_data) do
      local skillId = skillData.id or 0
      if (skillData.type == Enum.SkillActiveType.SAT_NORMAL or skillData.type == Enum.SkillActiveType.SAT_LEGENDARY) and (skillData.is_learned or self.showLockSkill) then
        local filterResult = self.cacheCurEquipSkillDic[skillData.id] or self:SkillFilter(skillData.id)
        if filterResult and not skillIds[skillId] then
          local _skillData = table.deepCopy(skillData, false)
          local _pos = self.cacheCurEquipSkillDic[skillData.id]
          _skillData.is_equipped = nil ~= _pos
          _skillData.pos = _pos
          local itemData = {
            skillData = _skillData,
            mode = 1,
            petData = self.petData,
            delayPlayAnim = self.delayPlaySkillItemAnim
          }
          if self.bHerbologyBadgeMode and self.herbologyBadgeLockedSkillId then
            itemData.herbologyBadgeLockedSkillId = self.herbologyBadgeLockedSkillId
          end
          table.insert(skills, itemData)
          skillIds[skillId] = true
        end
      end
    end
    local notUnLockSkillIds = self:GetLockSkillList(_petData.base_conf_id)
    for i, skillId in ipairs(notUnLockSkillIds) do
      if not skillIds[skillId] then
        local filterResult = self:SkillFilter(skillId)
        if filterResult then
          local skillData = {}
          skillData.id = skillId
          skillData.is_learned = false
          table.insert(skills, {
            skillData = skillData,
            mode = 1,
            petData = self.petData,
            delayPlayAnim = self.delayPlaySkillItemAnim
          })
          skillIds[skillId] = true
        end
      end
    end
  end
  return skills
end

function UMG_ChangePetSkillsPanel_C:GetLockSkillList(base_conf_id)
  if self.showLockSkill then
    local skillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, base_conf_id)
    if skillConf then
      local notUnLockSkillIds = {}
      for _, val in pairs(skillConf.machine_skill_group) do
        if val.machine_skill_id > 0 then
          table.insert(notUnLockSkillIds, val.machine_skill_id)
        end
      end
      if 0 ~= skillConf.blood_skill_COMMON then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_COMMON)
      end
      if 0 ~= skillConf.blood_skill_GRASS then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_GRASS)
      end
      if 0 ~= skillConf.blood_skill_FIRE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_FIRE)
      end
      if 0 ~= skillConf.blood_skill_WATER then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_WATER)
      end
      if 0 ~= skillConf.blood_skill_LIGHT then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_LIGHT)
      end
      if 0 ~= skillConf.blood_skill_STONE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_STONE)
      end
      if 0 ~= skillConf.blood_skill_ICE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_ICE)
      end
      if 0 ~= skillConf.blood_skill_DRAGON then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_DRAGON)
      end
      if 0 ~= skillConf.blood_skill_ELECTRIC then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_ELECTRIC)
      end
      if 0 ~= skillConf.blood_skill_TOXIC then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_TOXIC)
      end
      if 0 ~= skillConf.blood_skill_INSECT then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_INSECT)
      end
      if 0 ~= skillConf.blood_skill_FIGHT then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_FIGHT)
      end
      if 0 ~= skillConf.blood_skill_WING then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_WING)
      end
      if 0 ~= skillConf.blood_skill_MOE then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_MOE)
      end
      if 0 ~= skillConf.blood_skill_GHOST then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_GHOST)
      end
      if 0 ~= skillConf.blood_skill_DEMON then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_DEMON)
      end
      if 0 ~= skillConf.blood_skill_MECHANIC then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_MECHANIC)
      end
      if 0 ~= skillConf.blood_skill_PHANTOM then
        table.insert(notUnLockSkillIds, skillConf.blood_skill_PHANTOM)
      end
      return notUnLockSkillIds
    end
  end
  return {}
end

function UMG_ChangePetSkillsPanel_C:ShowPetSkill()
  self:ReSetEquipSkillEventListener()
  local posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid)
  local IdToPosDic = {}
  if posToIdDic then
    for pos, skillId in pairs(posToIdDic) do
      IdToPosDic[skillId] = pos
    end
  end
  self.cacheCurEquipSkillDic = IdToPosDic
  local skills = self:GetAllSkills(self.petData)
  if self.sortRule then
    self:SkillRuleSortHandle(skills)
  end
  if self.petData then
    self.petData.skill.skillData = skills
  end
  if #skills < 8 then
    for i = #skills + 1, 8 do
      skills[i] = {
        mode = i == #skills + 1 and -1 or nil
      }
    end
  elseif math.floor(#skills / 2) ~= #skills / 2 then
    skills[#skills + 1] = {
      mode = -1 or nil
    }
  end
  local nightmareSkillList = {}
  if #skills > 4 and self.petData and self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    for i = 1, 4 do
      skills[i].isNightmare = true
      table.insert(nightmareSkillList, skills[i])
    end
    self.ItemList:InitList(nightmareSkillList)
    self.curSkillList = nightmareSkillList
    return
  end
  self.ItemList:InitList(skills)
  self.curSkillList = skills
  self:CheckCloseSkillTips()
end

function UMG_ChangePetSkillsPanel_C:CheckCloseSkillTips()
  local curSkillTipsId = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetSKillTipsCurShowSkillId)
  local closeSkillTips = curSkillTipsId > 0
  if closeSkillTips then
    for i, v in ipairs(self.curSkillList) do
      if v.skillData and v.skillData.id == curSkillTipsId then
        closeSkillTips = false
        break
      end
    end
  end
  if closeSkillTips then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetSkillTipsPanel)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CloseBagSKillTips)
  end
end

function UMG_ChangePetSkillsPanel_C:OnChangeButtonClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_EQUIP_SKILL, true)
  if isBan then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  self.ItemList:ScrollToStart()
  local posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid)
  if nil == posToIdDic or 0 == #posToIdDic then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_4)
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002007, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
  local skillIds = {}
  for i = 1, 4 do
    if posToIdDic[i] then
      table.insert(skillIds, posToIdDic[i])
    end
  end
  if #posToIdDic > 0 then
    local saveDataType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetCurEquipSkillType, self.petData.gid, PetUIModuleEnum.PetEquipSkillType.Assumption)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, self.petData.gid, posToIdDic, saveDataType)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, nil)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_4)
    return
  end
  self:OnErasePetSkillRedPoint()
end

function UMG_ChangePetSkillsPanel_C:OnErasePetSkillRedPoint()
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 133, {
    tostring(self.petData.gid)
  }, true)
end

function UMG_ChangePetSkillsPanel_C:OnEquipSkill(skillData, index)
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetRightPanelIsOpen) then
    return
  end
  if skillData.is_learned then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, skillData.id, false, -1, nil, nil, nil, true)
  else
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, skillData.id, false, -1, self.petData.base_conf_id, true, self.petData.gid, true)
    return
  end
  if self.bHerbologyBadgeMode then
    if self.herbologyBadgeSelectedSkillId == skillData.id then
      self.herbologyBadgeSelectedSkillId = nil
    else
      self.herbologyBadgeSelectedSkillId = skillData.id
    end
    local posToIdDic = {}
    if self.herbologyBadgeSelectedSkillId then
      posToIdDic[1] = self.herbologyBadgeSelectedSkillId
    end
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetAssumptionEquipSkill, self.petData.gid, posToIdDic, nil)
    return
  end
  if self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.nightmare_cannot_change_skill)
    return
  end
  
  local function EquipCount(posToIdDic)
    local count = 0
    for i = 1, 4 do
      if posToIdDic[i] then
        count = count + 1
      end
    end
    return count
  end
  
  local posToIdDic, IdToPosDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetAssumptionEquipSkill, self.petData.gid)
  posToIdDic = posToIdDic or {}
  IdToPosDic = IdToPosDic or {}
  if IdToPosDic[skillData.id] then
    for i = 1, 4 do
      if posToIdDic[i] == skillData.id then
        posToIdDic[i] = nil
      end
    end
    IdToPosDic[skillData.id] = nil
  elseif 4 == EquipCount(posToIdDic) then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petskillmain_5)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002003, "UMG_ChangePetSkillsPanel_C:OnEquipSkill isFull")
    return
  else
    for i = 1, 4 do
      if nil == posToIdDic[i] then
        posToIdDic[i] = skillData.id
        IdToPosDic[skillData.id] = i
        break
      end
    end
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401004, "UMG_ChangePetSkillsPanel_C:OnEquipSkill")
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetAssumptionEquipSkill, self.petData.gid, posToIdDic, index)
end

function UMG_ChangePetSkillsPanel_C:OnAddEventListener()
  self:ReSetEquipSkillEventListener()
end

function UMG_ChangePetSkillsPanel_C:OnPetSkillFilterRuleChange(filterRule)
  self.filterRule = filterRule
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_ChangePetSkillsPanel_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRule = nil ~= id and _G.DataConfigManager:GetSkillSequenceConf(id) or nil
  self.skillSortReverse = skillSortReverse
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_ChangePetSkillsPanel_C:OnShowLockSkillChange(bShowLockSkill)
  self.showLockSkill = bShowLockSkill
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_ChangePetSkillsPanel_C:SkillFilter(skillId)
  if self.filterRule then
    if self.filterRule[_G.Enum.FilterRule.FIL_SKILL_SOURCE] then
      local skillSourceList = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetSkillSource, skillId, self.petBaseConf.id)
      local haveType = false
      for i, v in ipairs(skillSourceList) do
        if self.filterRule[_G.Enum.FilterRule.FIL_SKILL_SOURCE][v] then
          haveType = true
          break
        end
      end
      if not haveType then
        return false
      end
    end
    local skillConf = _G.DataConfigManager:GetSkillConf(skillId)
    if skillConf then
      if self.filterRule[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE] and not self.filterRule[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE][skillConf.skill_dam_type] then
        return false
      end
      if self.filterRule[_G.Enum.FilterRule.FIL_SKILL_TYPE] and not self.filterRule[_G.Enum.FilterRule.FIL_SKILL_TYPE][skillConf.Skill_Type] then
        return false
      end
    end
  end
  return true
end

function UMG_ChangePetSkillsPanel_C:SkillRuleSortHandle(skillList)
  if not (self.sortRule and skillList) or 0 == #skillList then
    return
  end
  local isReverse = self.skillSortReverse
  local sortType = isReverse and self.sortRule.sequence_switch or self.sortRule.sequence_default
  local sortFunc
  if isReverse then
    if sortType == Enum.SkillSequenceSwitch.SSS_DAM_TYPE_DOWN then
      function sortFunc(a, b)
        return self:CompareSkills(a, b, "damType", "cost", "default")
      end
    elseif sortType == Enum.SkillSequenceSwitch.SSS_ENERGY_DOWN then
      function sortFunc(a, b)
        return self:CompareSkills(a, b, "cost", "damType", "default")
      end
    elseif sortType == Enum.SkillSequenceSwitch.SSS_LEARN_SEQUENCE_DOWN then
      function sortFunc(a, b)
        return self:CompareSkills(a, b, "default", "damType", "cost")
      end
    end
  elseif sortType == Enum.SkillSequenceDefault.SSD_DAM_TYPE_UP then
    function sortFunc(a, b)
      return self:CompareSkills(a, b, "damType", "cost", "default")
    end
  elseif sortType == Enum.SkillSequenceDefault.SSD_ENERGY_UP then
    function sortFunc(a, b)
      return self:CompareSkills(a, b, "cost", "damType", "default")
    end
  elseif sortType == Enum.SkillSequenceDefault.SSD_LEARN_SEQUENCE_UP then
    function sortFunc(a, b)
      return self:CompareSkills(a, b, "default", "damType", "cost")
    end
  end
  if sortFunc then
    self:StableSort(skillList, sortFunc)
  end
end

function UMG_ChangePetSkillsPanel_C:StableSort(list, compareFunc)
  for i = 2, #list do
    local j = i
    while j > 1 and compareFunc(list[j], list[j - 1]) do
      list[j], list[j - 1] = list[j - 1], list[j]
      j = j - 1
    end
  end
end

function UMG_ChangePetSkillsPanel_C:CompareSkills(a, b, primaryKey, secondaryKey, tertiaryKey)
  local confA = a._sortCache or _G.DataConfigManager:GetSkillConf(a.skillData.id)
  local confB = b._sortCache or _G.DataConfigManager:GetSkillConf(b.skillData.id)
  a._sortCache = confA
  b._sortCache = confB
  if not confA or not confB then
    return false
  end
  local a_pos = self.cacheCurEquipSkillDic[a.skillData.id]
  local b_pos = self.cacheCurEquipSkillDic[b.skillData.id]
  if a_pos and not b_pos then
    return true
  end
  if not a_pos and b_pos then
    return false
  end
  if a_pos and b_pos and a_pos ~= b_pos then
    return a_pos < b_pos
  end
  if a.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    if a.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      return true
    elseif b.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      return false
    end
  end
  local primaryA = self:GetCompareValue(confA, primaryKey, 3)
  local primaryB = self:GetCompareValue(confB, primaryKey, 3)
  if primaryA ~= primaryB then
    if self.skillSortReverse and "default" ~= primaryKey then
      return primaryA > primaryB
    else
      return primaryA < primaryB
    end
  end
  if "default" ~= primaryKey then
    local secondaryA = self:GetCompareValue(confA, secondaryKey)
    local secondaryB = self:GetCompareValue(confB, secondaryKey)
    if secondaryA ~= secondaryB then
      return secondaryA < secondaryB
    end
    local tertiaryA = self:GetCompareValue(confA, tertiaryKey)
    local tertiaryB = self:GetCompareValue(confB, tertiaryKey)
    if tertiaryA ~= tertiaryB then
      return tertiaryA < tertiaryB
    end
  end
  return a.skillData.id < b.skillData.id
end

function UMG_ChangePetSkillsPanel_C:GetCompareValue(conf, key, level)
  if not conf then
    Log.Error("CompareSkills: conf is nil")
    return nil
  end
  if "damType" == key then
    return self:GetSkillDamTypeOrderFromConf(conf, level)
  elseif "cost" == key then
    return conf.energy_cost[1]
  elseif "default" == key then
    return self:GetDefaultSortWeighting(conf)
  end
end

function UMG_ChangePetSkillsPanel_C:GetSkillDamTypeOrderFromConf(skillConf, level)
  if not skillConf then
    return 9999
  end
  if 3 ~= level then
    return skillConf.skill_dam_type
  end
  if skillConf.skill_dam_type == self.petBaseConf.unit_type[1] then
    return 1
  elseif skillConf.skill_dam_type == self.petBaseConf.unit_type[2] then
    return 2
  else
    return skillConf.skill_dam_type + 10
  end
end

function UMG_ChangePetSkillsPanel_C:GetDefaultSortWeighting(skillConf)
  local Weighting = 9999
  if not skillConf then
    return Weighting
  end
  local skillSourceList = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetSkillSource, skillConf.id, self.petBaseConf.id)
  if #skillSourceList > 0 then
    if skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
      local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.petBaseConf.id)
      if levelSkillConf then
        if self.skillSortReverse then
          for i, v in ipairs(levelSkillConf.level) do
            if v.param == skillConf.id then
              Weighting = self.petMaxLevelLimit - v.level_point
              break
            end
          end
        else
          for i, v in ipairs(levelSkillConf.level) do
            if v.param == skillConf.id then
              Weighting = v.level_point
              break
            end
          end
        end
      end
    elseif skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_LEGENDARY then
      Weighting = self.petMaxLevelLimit + 1
    elseif skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK then
      Weighting = self.petMaxLevelLimit + 2
    elseif skillSourceList[1] == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      Weighting = self.petMaxLevelLimit + 3
    end
  end
  return Weighting
end

function UMG_ChangePetSkillsPanel_C:ClearSkillListSelection()
  self.ItemList:ClearSelection()
end

function UMG_ChangePetSkillsPanel_C:OpenSkillFilteringPanelByCurShowSkillList()
  if self.petBaseConf and self.petData and self.petBaseConf then
    local skillList = {}
    local skillIds = {}
    for i, v in ipairs(self.petData.skill.skill_data) do
      if (v.type == Enum.SkillActiveType.SAT_NORMAL or v.type == Enum.SkillActiveType.SAT_LEGENDARY) and (v.is_learned or self.showLockSkill) then
        table.insert(skillList, v)
        skillIds[v.id] = true
      end
    end
    local notUnLockSkillIds = self:GetLockSkillList(self.petBaseConf.id)
    for i, skillId in ipairs(notUnLockSkillIds) do
      if not skillIds[skillId] then
        local skillData = {}
        skillData.id = skillId
        skillData.is_learned = false
        table.insert(skillList, skillData)
        skillIds[skillId] = true
      end
    end
    local skillCountTab = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CalculationSkillNumByType, skillList, self.petBaseConf.id)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetFilteringPanel, self.filterRule, skillCountTab, skillList, self.petBaseConf.id)
  end
end

return UMG_ChangePetSkillsPanel_C

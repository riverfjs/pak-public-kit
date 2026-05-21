local UMG_Pass_PetSkillMain_C = _G.NRCViewBase:Extend("UMG_Pass_PetSkillMain_C")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BattlePassModuleEvent = reload("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_Pass_PetSkillMain_C:OnConstruct()
  self.descText = ""
  self:OnAddEventListener()
  self.Text:SetText(LuaText.skill_filter_tips_3)
  self.petMaxLevelLimit = (_G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit") or {}).num or 60
end

function UMG_Pass_PetSkillMain_C:OnDeactive()
end

function UMG_Pass_PetSkillMain_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_ShutDown, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_1, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_2, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_3, self.ResetDescText)
  self:AddButtonListener(self.ViewPet.btnLevelUp, self.OnSelectSkillClick)
  self:AddButtonListener(self.ViewPet_2.btnLevelUp, self.OnSortSkillClick)
  self:RegisterEvent(self, PetUIModuleEvent.SelectEmptySkill, self.OnSelectEmptySkill)
  self:RegisterEvent(self, BattlePassModuleEvent.ShowBtnClosePanel, self.ShowBtnClosePanel)
  self:RegisterEvent(self, BattlePassModuleEvent.HideBtnClosePanel, self.HideBtnClosePanel)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_PetSkillMain_C", self, PetUIModuleEvent.SelectSkill, self.OnSelectSkill)
  self.ItemList:SetItemSelectedCallback(self.OnSkillItemSelected, self)
end

function UMG_Pass_PetSkillMain_C:OnSkillItemSelected(item, rawIndex, userClick)
  if userClick then
    item:OnItemSelectedByClick()
  end
end

function UMG_Pass_PetSkillMain_C:UpdatePanel(petBaseId)
  self:ResetDescText()
  self.petBaseId = petBaseId
  self.petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petBaseId)
  self:InitFilterAndSort()
  self.allShowSkills = self:InitShowSkills()
  if #self.allShowSkills > 0 then
    self:ShowPetSkill()
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.ViewPet:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ViewPet_2:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.Text:SetText(LuaText.skill_filter_tips_3)
    self.ViewPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ViewPet_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.petBaseConf then
    self:ShowPetFeature(self.petBaseConf)
  end
end

function UMG_Pass_PetSkillMain_C:InitFilterAndSort()
  self.filterRule = nil
  self.sortRule = _G.DataConfigManager:GetSkillSequenceConf(1)
  self.skillSortReverse = false
  self.SkillIdToSourceMap = {}
  local path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  self.ViewPet:SetPath(path, path, path)
end

function UMG_Pass_PetSkillMain_C:ShowPetSkill()
  local skillDataList = {}
  for _, data in ipairs(self.allShowSkills) do
    local filterResult = self:SkillFilter(data.skillData.id)
    if filterResult then
      local itemData = table.deepCopy(data, false)
      itemData.delayPlayAnim = self.delayPlaySkillItemAnim
      table.insert(skillDataList, itemData)
    end
  end
  if self.sortRule then
    self:SkillRuleSortHandle(skillDataList)
  end
  self.ItemList:InitList(skillDataList)
  self:CheckCloseSkillTips(skillDataList)
  if #skillDataList > 0 then
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
  end
end

function UMG_Pass_PetSkillMain_C:CheckCloseSkillTips(skillDataList)
  local curSkillTipsId = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetSKillTipsCurShowSkillId)
  local closeSkillTips = curSkillTipsId > 0
  local index = -1
  if closeSkillTips then
    for i, v in ipairs(skillDataList) do
      if v.skillData and v.skillData.id == curSkillTipsId then
        closeSkillTips = false
        index = i
        break
      end
    end
  end
  if closeSkillTips then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetSkillTipsPanel)
  elseif index > 0 then
    self.ItemList:SelectItemByIndex(index - 1)
    self.ItemList:ScrollToIndex(index - 1, false)
  end
end

function UMG_Pass_PetSkillMain_C:InitShowSkills()
  local skillIds = {}
  local addSkillIds = {}
  local skillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.petBaseId)
  if nil == skillConf or nil == skillConf.legendary_skill then
    return {}
  end
  if 0 ~= skillConf.legendary_skill then
    table.insert(skillIds, skillConf.legendary_skill)
  end
  for _, val in pairs(skillConf.level) do
    table.insert(skillIds, val.param)
  end
  for _, val in pairs(skillConf.machine_skill_group) do
    if val.machine_skill_id > 0 then
      table.insert(skillIds, val.machine_skill_id)
    end
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petBaseId)
  if petBaseConf and petBaseConf.unit_type and petBaseConf.unit_type[1] then
    local skConf = PetUtils.GetSkillBloodData(petBaseConf.unit_type[1], skillConf)
    if skConf then
      table.insert(skillIds, skConf.id)
    end
  end
  if 0 ~= skillConf.blood_skill_COMMON then
    table.insert(skillIds, skillConf.blood_skill_COMMON)
  end
  if 0 ~= skillConf.blood_skill_GRASS then
    table.insert(skillIds, skillConf.blood_skill_GRASS)
  end
  if 0 ~= skillConf.blood_skill_FIRE then
    table.insert(skillIds, skillConf.blood_skill_FIRE)
  end
  if 0 ~= skillConf.blood_skill_WATER then
    table.insert(skillIds, skillConf.blood_skill_WATER)
  end
  if 0 ~= skillConf.blood_skill_LIGHT then
    table.insert(skillIds, skillConf.blood_skill_LIGHT)
  end
  if 0 ~= skillConf.blood_skill_STONE then
    table.insert(skillIds, skillConf.blood_skill_STONE)
  end
  if 0 ~= skillConf.blood_skill_ICE then
    table.insert(skillIds, skillConf.blood_skill_ICE)
  end
  if 0 ~= skillConf.blood_skill_DRAGON then
    table.insert(skillIds, skillConf.blood_skill_DRAGON)
  end
  if 0 ~= skillConf.blood_skill_ELECTRIC then
    table.insert(skillIds, skillConf.blood_skill_ELECTRIC)
  end
  if 0 ~= skillConf.blood_skill_TOXIC then
    table.insert(skillIds, skillConf.blood_skill_TOXIC)
  end
  if 0 ~= skillConf.blood_skill_INSECT then
    table.insert(skillIds, skillConf.blood_skill_INSECT)
  end
  if 0 ~= skillConf.blood_skill_FIGHT then
    table.insert(skillIds, skillConf.blood_skill_FIGHT)
  end
  if 0 ~= skillConf.blood_skill_WING then
    table.insert(skillIds, skillConf.blood_skill_WING)
  end
  if 0 ~= skillConf.blood_skill_MOE then
    table.insert(skillIds, skillConf.blood_skill_MOE)
  end
  if 0 ~= skillConf.blood_skill_GHOST then
    table.insert(skillIds, skillConf.blood_skill_GHOST)
  end
  if 0 ~= skillConf.blood_skill_DEMON then
    table.insert(skillIds, skillConf.blood_skill_DEMON)
  end
  if 0 ~= skillConf.blood_skill_MECHANIC then
    table.insert(skillIds, skillConf.blood_skill_MECHANIC)
  end
  if 0 ~= skillConf.blood_skill_PHANTOM then
    table.insert(skillIds, skillConf.blood_skill_PHANTOM)
  end
  local skillDataList = {}
  for _, id in pairs(skillIds) do
    if 7000010 ~= id and not addSkillIds[id] then
      local data = {}
      local skillData = {}
      skillData.id = id
      skillData.onlyShow = true
      data.skillData = skillData
      skillData.is_learned = true
      data.mode = 0
      table.insert(skillDataList, data)
      addSkillIds[id] = true
    end
  end
  return skillDataList
end

function UMG_Pass_PetSkillMain_C:PlayInAnimation()
  if self.petBaseConf then
    self:ShowPetFeature(self.petBaseConf)
  end
end

function UMG_Pass_PetSkillMain_C:OnSelectSkill(skillData)
  if not skillData then
    Log.Error("\230\138\128\232\131\189\230\149\176\230\141\174\228\184\186\231\169\186,\230\181\139\232\175\149\229\143\175\230\138\138Log\229\143\145\231\187\153\231\168\139\229\186\143\230\159\165\232\175\162")
    return
  end
  local mode = 0
  if self.panel then
    self.panel:PlayAnimation(self.panel.HeadPortrait_out)
  end
  self:ResetDescText()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillData.id, false, mode, self.petBaseConf.id)
end

function UMG_Pass_PetSkillMain_C:ShowPetFeature(petBaseConf)
  local skillId, lock = self:GetPetFeatrueSkillId(petBaseConf)
  if 0 ~= skillId then
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
    if skillCfg then
      local skillDesc = skillCfg.desc
      if skillCfg.icon then
        self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Visible)
        self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Visible)
        self.SkillIcon:SetPath(NRCUtils:FormatConfIconPath(skillCfg.icon, _G.UIIconPath.SkillIconPath))
      else
        self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.SkillNameTxt:SetText(skillCfg.name)
      if lock then
        self.descText = skillDesc
        self.NRCTextDes:SetText(skillDesc)
      else
        self.descText = skillDesc
        self.NRCTextDes:SetText(skillDesc)
        self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self:PlayAnimation(self.state)
      self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self:PlayAnimation(self.state)
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pass_PetSkillMain_C:GetPetFeatrueSkillId(petBaseConf)
  local skillId = petBaseConf.pet_feature
  if 0 ~= skillId then
    return skillId, false
  elseif #petBaseConf.evolution_pet_id > 0 then
    local evolution_pet_id = petBaseConf.evolution_pet_id[1]
    local evoPetbaseCfg = _G.DataConfigManager:GetPetbaseConf(evolution_pet_id)
    if evolution_pet_id then
      skillId = evoPetbaseCfg.pet_feature
      if 0 ~= skillId then
        return skillId, true
      end
    end
  end
  return 0
end

function UMG_Pass_PetSkillMain_C:ShowDescRightPanel(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Pass_PetSkillMain_C:SetDescText(descText)
  table.insert(self.descText, descText)
  _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.SetDescTextTable, self.descText)
end

function UMG_Pass_PetSkillMain_C:ClearDescText()
  table.clear(self.descText)
end

function UMG_Pass_PetSkillMain_C:ShowBtnClosePanel()
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Pass_PetSkillMain_C:HideBtnClosePanel()
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pass_PetSkillMain_C:ResetDescText()
  _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.ResetDescText)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
end

function UMG_Pass_PetSkillMain_C:OnSelectEmptySkill()
  self:ResetDescText()
end

function UMG_Pass_PetSkillMain_C:GetAllSkillConfs(skillIds)
  local skills = {}
  for i, skillID in pairs(skillIds) do
    local skillConf = _G.DataConfigManager:GetSkillConf(skillID)
    table.insert(skills, skillConf)
  end
  return skills
end

function UMG_Pass_PetSkillMain_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.SelectSkill, self.OnSelectSkill)
end

function UMG_Pass_PetSkillMain_C:OnAnimationFinished(anim)
end

function UMG_Pass_PetSkillMain_C:OnClickbackBtn()
end

function UMG_Pass_PetSkillMain_C:OnClickbackBtn_1()
end

function UMG_Pass_PetSkillMain_C:PlayOutAnimation()
  self:PlayAnimation(self.Out)
end

function UMG_Pass_PetSkillMain_C:OnSelectSkillClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Pass_PetSkillMain_C:OnSelectSkillClick")
  self:ResetDescText()
  if self.petBaseConf then
    local skillList = {}
    for i, v in ipairs(self.allShowSkills) do
      if v.skillData then
        table.insert(skillList, v.skillData)
      end
    end
    local skillCountTab = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CalculationSkillNumByType, skillList, self.petBaseConf.id)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetFilteringPanel, self.filterRule, skillCountTab, skillList, self.petBaseConf.id)
  end
end

function UMG_Pass_PetSkillMain_C:OnSortSkillClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Pass_PetSkillMain_C:OnSelectSkillClick")
  self:ResetDescText()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetSortPanel, self.sortRule and self.sortRule.id or nil, self.skillSortReverse)
end

function UMG_Pass_PetSkillMain_C:OnPetSkillFilterRuleChange(filterRule)
  self.filterRule = filterRule
  local path
  if self.filterRule then
    path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen3_png.img_Screen3_png'"
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  end
  self.ViewPet:SetPath(path, path, path)
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_Pass_PetSkillMain_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRule = nil ~= id and _G.DataConfigManager:GetSkillSequenceConf(id) or nil
  self.skillSortReverse = skillSortReverse
  self.delayPlaySkillItemAnim = true
  self:ShowPetSkill()
  self.delayPlaySkillItemAnim = false
end

function UMG_Pass_PetSkillMain_C:SkillFilter(skillId)
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

function UMG_Pass_PetSkillMain_C:SkillRuleSortHandle(skillList)
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

function UMG_Pass_PetSkillMain_C:StableSort(list, compareFunc)
  for i = 2, #list do
    local j = i
    while j > 1 and compareFunc(list[j], list[j - 1]) do
      list[j], list[j - 1] = list[j - 1], list[j]
      j = j - 1
    end
  end
end

function UMG_Pass_PetSkillMain_C:CompareSkills(a, b, primaryKey, secondaryKey, tertiaryKey)
  local confA = a._sortCache or _G.DataConfigManager:GetSkillConf(a.skillData.id)
  local confB = b._sortCache or _G.DataConfigManager:GetSkillConf(b.skillData.id)
  a._sortCache = confA
  b._sortCache = confB
  if not confA or not confB then
    return false
  end
  
  local function getValue(conf, key, level)
    if "damType" == key then
      return self:GetSkillDamTypeOrderFromConf(conf, level)
    elseif "cost" == key then
      return conf.energy_cost[1]
    elseif "default" == key then
      return self:GetDefaultSortWeighting(conf)
    end
  end
  
  local primaryA = getValue(confA, primaryKey, 3)
  local primaryB = getValue(confB, primaryKey, 3)
  if primaryA ~= primaryB then
    if self.skillSortReverse and "default" ~= primaryKey then
      return primaryA > primaryB
    else
      return primaryA < primaryB
    end
  end
  if "default" ~= primaryKey then
    local secondaryA = getValue(confA, secondaryKey)
    local secondaryB = getValue(confB, secondaryKey)
    if secondaryA ~= secondaryB then
      return secondaryA < secondaryB
    end
    local tertiaryA = getValue(confA, tertiaryKey)
    local tertiaryB = getValue(confB, tertiaryKey)
    if tertiaryA ~= tertiaryB then
      return tertiaryA < tertiaryB
    end
  end
  return a.skillData.id < b.skillData.id
end

function UMG_Pass_PetSkillMain_C:GetSkillDamTypeOrderFromConf(skillConf, level)
  if not skillConf then
    return 20
  end
  if 3 ~= level then
    return skillConf.skill_dam_type
  end
  if skillConf.skill_dam_type == self.petBaseConf.unit_type[1] then
    return 1
  elseif skillConf.skill_dam_type == self.petBaseConf.unit_type[2] then
    return 2
  else
    return skillConf.skill_dam_type + 1
  end
end

function UMG_Pass_PetSkillMain_C:GetDefaultSortWeighting(skillConf)
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

return UMG_Pass_PetSkillMain_C

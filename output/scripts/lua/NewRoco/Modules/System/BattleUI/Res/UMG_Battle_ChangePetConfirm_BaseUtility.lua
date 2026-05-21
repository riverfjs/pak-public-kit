local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local Enum = require("Data.Config.Enum")
local Base = _G.NRCPanelBase
local UMG_Battle_ChangePetConfirm_BaseUtility = Base:Extend("UMG_Battle_ChangePetConfirm_BaseUtility")
local EUsageEnum = {
  AsPetData = 1,
  AsBattleCard = 2,
  AsBattlePetInfo = 3,
  AsTable_CardData = 4,
  AsTable_PetInfo = 5,
  AsTable_InfoData = 6,
  AsTable_BattlePetInfo = 7,
  AsTable_ShowRestrainAndResist_PetInfo = 8
}
local EConditionalShowContent = {
  Speed = 1,
  SpeedCompare = 2,
  PetTypeAdvantage = 3,
  SkillList = 4
}

function UMG_Battle_ChangePetConfirm_BaseUtility:ConditionalShow(EContent, card)
  if not card or not EContent then
    return false
  end
  return self:ConditionalShow_Class4(EContent, card:IsInBattle(), card:IsMyself())
end

function UMG_Battle_ChangePetConfirm_BaseUtility:ConditionalShow_EnemeyReversePet(EContent, info)
  if not info or not EContent then
    return false
  end
  return self:ConditionalShow_Class4(EContent, false, false)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:ConditionalShow_Class4(EContent, bInBattle, bIsMyself)
  if bIsMyself then
    if bInBattle then
      if EContent == EConditionalShowContent.Speed then
        return BattleUtils.CheckConditionSpeed()
      elseif EContent == EConditionalShowContent.SpeedCompare then
        return false
      elseif EContent == EConditionalShowContent.PetTypeAdvantage then
        return true
      elseif EContent == EConditionalShowContent.SkillList then
        return false
      end
    elseif EContent == EConditionalShowContent.Speed then
      return BattleUtils.CheckConditionSpeed()
    elseif EContent == EConditionalShowContent.SpeedCompare then
      return BattleUtils.CheckCondition_126282472()
    elseif EContent == EConditionalShowContent.PetTypeAdvantage then
      return BattleUtils.CheckCondition_128223171()
    elseif EContent == EConditionalShowContent.SkillList then
      return true
    end
  elseif EContent == EConditionalShowContent.Speed then
    return BattleUtils.CheckConditionSpeed()
  elseif EContent == EConditionalShowContent.SpeedCompare then
    return false
  elseif EContent == EConditionalShowContent.PetTypeAdvantage then
    return true
  elseif EContent == EConditionalShowContent.SkillList then
    return true
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnConstruct()
  self:SafeSet(self.SkillList, "parentPanel", self)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnDestruct()
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnActive(data)
  self.data = data
  self.resonance_desc_text = ""
  local usage = EUsageEnum.AsPetData
  if data.cardData and data.petData then
    usage = EUsageEnum.AsTable_CardData
  elseif data.owner and data.petInfo and data.petState then
    usage = EUsageEnum.AsBattleCard
  elseif data.PetData and data.IsShowHp then
    usage = EUsageEnum.AsTable_PetInfo
  elseif data.petBaseId then
    usage = EUsageEnum.AsTable_InfoData
  elseif data.pet_id and data.role_uin then
    usage = EUsageEnum.AsBattlePetInfo
  elseif data.battlePetInfo then
    usage = EUsageEnum.AsTable_BattlePetInfo
  end
  if usage == EUsageEnum.AsPetData then
    self:OnActiveAsPetData(usage, data)
  elseif usage == EUsageEnum.AsBattleCard then
    self:OnActiveAsBattleCard(usage, data)
  elseif usage == EUsageEnum.AsBattlePetInfo then
    self:OnActiveAsBattlePetInfo(usage, data)
  elseif usage == EUsageEnum.AsTable_CardData then
    self:OnActiveAsBattleCard(usage, data.cardData)
  elseif usage == EUsageEnum.AsTable_PetInfo then
    self:OnActiveAsPetData(usage, data.PetData)
  elseif usage == EUsageEnum.AsTable_InfoData then
    self:OnActiveAsTable_InfoData(usage, {
      base_conf_id = data.petBaseId,
      levelSkillId = data.levelSkillId,
      lv = data.level,
      curBattleBaseId = data.curBattleBaseId,
      bloodId = data.bloodId,
      hideCompatInfo = data.hideCompatInfo,
      showSeasonBattleRule = data.showSeasonBattleRule,
      seasonBattleRuleList = data.seasonBattleRuleList
    })
  elseif usage == EUsageEnum.AsTable_BattlePetInfo then
    self:OnActiveAsBattlePetInfo(usage, data.battlePetInfo)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnDeactive()
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnActiveAsBattleCard(usage, card)
  local petData = card.petInfo.battle_common_pet_info
  self:DoOnActiveAnywhere(usage, petData)
  self:DoOnActiveInCombat(usage, card)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnActiveAsTable_InfoData(usage, infoData)
  self:SafeCall(self.SkillNameTxt_1, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  self:DoOnActiveAnywhere_Class4(usage)
  if infoData.levelSkillId then
    self:UpdateSkillListByLevelSkillConf_Class4(infoData)
  elseif not infoData.hideCompatInfo then
    self:UpdatePropertyInfoInCombat_Class4(infoData)
  end
  if infoData.showSeasonBattleRule then
    self:UpdateSeasonBattleRuleInfo(infoData.seasonBattleRuleList)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateSkillListByLevelSkillConf_Class4(infoData)
  local levelSkillId = infoData.levelSkillId
  local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(levelSkillId)
  local petEquipSkills = PetUtils.GetHelpPetEquipSkills(LevelSkillConf, infoData.bloodId, infoData.lv, infoData.curBattleBaseId)
  if #petEquipSkills > 0 then
    self:SafeCall(self.Line1_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.SkillList, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.SkillList, "InitGridView", petEquipSkills)
    self:DelaySeconds(0.01, function()
      self:SafeCall(self.SkillList, "RefreshGridViewLayout")
    end)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnActiveAsPetData(usage, petData)
  self:DoOnActiveAnywhere(usage, petData)
  self:DoOnActiveInPeace(usage, petData)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnActiveAsBattlePetInfo(usage, info)
  local petData = info.battle_common_pet_info
  self:DoOnActiveAnywhere(usage, petData)
  self:DoOnActiveInCombat_EnemeyReversePet(usage, info)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:DoOnActiveAnywhere(usage, petData)
  self:DoOnActiveAnywhere_Class4(usage)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:DoOnActiveAnywhere_Class4(usage)
  local Invisible = UE4.ESlateVisibility.Collapsed
  self:SafeCall(self.NRCGridView, "SetVisibility", Invisible)
  self:SafeCall(self.PinnedPanel, "SetVisibility", Invisible)
  self:SafeCall(self.PinnedPanel2, "SetVisibility", Invisible)
  self:SafeCall(self.NRCGridView_0, "SetVisibility", Invisible)
  self:SafeCall(self.resistPanel, "SetVisibility", Invisible)
  self:SafeCall(self.resistPanel2, "SetVisibility", Invisible)
  self:SafeCall(self.SkillList, "SetVisibility", Invisible)
  self:SafeCall(self.GainCanvas_1, "SetVisibility", Invisible)
  self:SafeCall(self.CanvasStrongPoint, "SetVisibility", Invisible)
  self:SafeCall(self.Divider_1, "SetVisibility", Invisible)
  self:SafeCall(self.CatchHardLv, "SetVisibility", Invisible)
  self:SafeCall(self.Divider, "SetVisibility", Invisible)
  self:SafeCall(self.Line1_1, "SetVisibility", Invisible)
  self:SafeCall(self.PetTypeAdvantagePanel, "SetVisibility", Invisible)
  self:SafeCall(self.SeasonBattleRuleList, "SetVisibility", Invisible)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:DoOnActiveInPeace(usage, petData)
  self:UpdatePetSpeedValue(petData)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:DoOnActiveInCombat(usage, card)
  self:UpdatePetSpeedValueInCombat(card)
  self:UpdatePropertyInfoInCombat(card)
  self:UpdateBreakThroughStarsListInCombat(card)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:DoOnActiveInCombat_EnemeyReversePet(usage, info)
  self:UpdatePetSpeedValueInCombat_EnemeyReversePet(info)
  self:UpdatePropertyInfoInCombat_EnemeyReversePet(info)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePetSpeedValue(petData)
  if not petData then
    return
  end
  self:SafeCall(self.CanvasStrongPoint, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SafeCall(self.Divider_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  local text_title = _G.LuaText.pet_speed_value
  local speed = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_SPEED)
  local text_value = tostring(speed)
  self:SafeCall(self.SkillNameTxt_2, "SetText", text_title)
  self:SafeCall(self.SkillNameTxt_3, "SetText", text_value)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePetSpeedValueInCombat(card)
  if not self:ConditionalShow(EConditionalShowContent.Speed, card) then
    return
  end
  if card:IsEnemy() then
    self:UpdatePetSpeedValueInCombat_Class4(card:GetSpeedMinMax())
  else
    self:UpdatePetSpeedValueInCombat_Class4(card:GetSpeed())
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePetSpeedValueInCombat_EnemeyReversePet(info)
  if not self:ConditionalShow_EnemeyReversePet(EConditionalShowContent.Speed, info) then
    return
  end
  self:UpdatePetSpeedValueInCombat_Class4(PetUtils.GetSpeedMinMax(info.battle_inside_pet_info))
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePetSpeedValueInCombat_Class4(speedMin, speedMax)
  self:SafeCall(self.CanvasStrongPoint, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SafeCall(self.Divider_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  local text_title, text_value
  text_title = _G.LuaText.pet_speed_value
  text_value = ""
  self:SafeCall(self.SkillNameTxt_2, "SetText", text_title)
  self:SafeCall(self.SkillNameTxt_3, "SetText", text_value)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePetSpeedCompareInCombat(card)
  if not self:ConditionalShow(EConditionalShowContent.SpeedCompare, card) then
    return
  end
  local cardToCompare
  do
    local enemyBattleTeams = _G.BattleManager.battlePawnManager:GetAllEnemyTeam(BattleEnum.Team.ENUM_TEAM)
    local foundCardNum = 0
    local foundCard
    for i = 1, #enemyBattleTeams do
      local team = enemyBattleTeams[i]
      local cards = team:GetInBattleCards()
      for iCard = 1, #cards do
        local cardTemp = cards[iCard]
        if cardTemp:IsAlive() then
          if not foundCard and 0 == foundCardNum then
            foundCard = cardTemp
            foundCardNum = 1
          else
            foundCardNum = foundCardNum + 1
            break
          end
        end
      end
      if foundCardNum > 1 then
        foundCard = nil
        break
      end
    end
    if not foundCard then
      return
    else
      cardToCompare = foundCard
    end
  end
  if nil == not cardToCompare then
    return
  end
  self:SafeCall(self.GainCanvas_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  local my_speed = card:GetSpeed()
  local speed_min, speed_max = cardToCompare:GetSpeedMinMax()
  local result = BattleEnum.SpeedCompare.ENUM_NOTSURE
  if my_speed < speed_min then
    result = BattleEnum.SpeedCompare.ENUM_SLOWER
  elseif my_speed > speed_max then
    result = BattleEnum.SpeedCompare.ENUM_FASTER
  end
  local index = result + 1
  local switcherMapping = {
    1,
    0,
    2
  }
  self:SafeCall(self.EffectSwitcher_1, "SetActiveWidgetIndex", switcherMapping[index])
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePropertyInfoInCombat(card)
  self:SafeCall(self.SizeBox_77, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  if BattleUtils.IsPartialShow(card) then
    return
  end
  if not self:ConditionalShow(EConditionalShowContent.PetTypeAdvantage, card) then
    return
  end
  self:UpdatePropertyInfoInCombat_Class4(card.petInfo.battle_inside_pet_info)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePropertyInfoInCombat_EnemeyReversePet(info)
  self:SafeCall(self.SizeBox_77, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  if PetUtils.IsPartialShow(info) then
    return
  end
  if not self:ConditionalShow_EnemeyReversePet(EConditionalShowContent.PetTypeAdvantage, info) then
    return
  end
  self:UpdatePropertyInfoInCombat_Class4(info.battle_inside_pet_info)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdatePropertyInfoInCombat_Class4(battle_inside_pet_info)
  self:SafeCall(self.NRCGridView, "Clear")
  self:SafeCall(self.NRCGridView_0, "Clear")
  local RestainTypeList, ResistTypeList = NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetRestrainAndResistType, battle_inside_pet_info)
  if #RestainTypeList > 0 then
    self:SafeCall(self.NRCGridView, "InitGridView", RestainTypeList)
    self:SafeCall(self.NRCGridView, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.PinnedPanel, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.PinnedPanel2, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if #ResistTypeList > 0 then
    self:SafeCall(self.NRCGridView_0, "InitGridView", ResistTypeList)
    self:SafeCall(self.NRCGridView_0, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.resistPanel, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.resistPanel2, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local bHasContent = #RestainTypeList > 0 or #ResistTypeList > 0
  if bHasContent then
    self:SafeCall(self.Divider, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateSeasonBattleRuleInfo(seasonBattleRuleList)
  self:SafeCall(self.SeasonBattleRuleList, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SafeCall(self.SeasonBattleRuleList, "Clear")
  if seasonBattleRuleList and #seasonBattleRuleList > 0 then
    self:SafeCall(self.SeasonBattleRuleList, "InitGridView", seasonBattleRuleList)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:ShowPetTypeAdvantageTip(card)
  if self.PetTypeAdvantagePanel and (self.PetTypeAdvantagePanel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible or self.PetTypeAdvantagePanel:GetVisibility() == UE4.ESlateVisibility.Visible) then
    self.PetTypeAdvantagePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if nil == card then
    return
  end
  local RestainTypeList, ResistTypeList = NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetRestrainAndResistType, card.petInfo.battle_inside_pet_info)
  if #ResistTypeList > 0 then
    self:SafeCall(self.PetTypeAdvantagePanel.NRCGridView_0, "InitGridView", ResistTypeList)
  end
  if #RestainTypeList > 0 then
    self:SafeCall(self.PetTypeAdvantagePanel.NRCGridView, "InitGridView", RestainTypeList)
  end
  if #RestainTypeList > 0 or #ResistTypeList > 0 then
    self:SafeCall(self.PetTypeAdvantagePanel, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.PetTypeAdvantagePanel, "PlayAnimation", self.PetTypeAdvantagePanel.Appear)
    self:SafeCall(self.SpeedComparison, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  end
  if self.data.cardData then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.cardData.petInfo.battle_inside_pet_info.base_conf_id)
    local petTypeIcons = {
      self.PetTypeAdvantagePanel.petTypeIcon1,
      self.PetTypeAdvantagePanel.petTypeIcon2
    }
    for i, uiIcon in ipairs(petTypeIcons) do
      uiIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
      local petType = petBaseConf.unit_type[#petBaseConf.unit_type - i + 1]
      if petType then
        local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
        if typeDic then
          uiIcon:SetPath(typeDic.type_icon)
          uiIcon:SetVisibility(UE4.ESlateVisibility.Visible)
        end
      end
    end
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateSkillListInCombat(card)
  if not self:ConditionalShow(EConditionalShowContent.SkillList, card) then
    return
  end
  local skills = card:IsEnemy() and self:GetDisplaySkillsForEnemy(card) or self:GetDisplaySkills(card)
  local petGuid = card and card.guid
  self:UpdateSkillListInCombat_Class4(skills, petGuid)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateSkillListInCombat_EnemyReversePet(info)
  if not self:ConditionalShow_EnemeyReversePet(EConditionalShowContent.SkillList, info) then
    return
  end
  local insidePetInfo = info and info.battle_inside_pet_info
  local skills = PetUtils.GetBattleSkills(info.battle_inside_pet_info, false)
  local petGuid = insidePetInfo and insidePetInfo.pet_id
  self:UpdateSkillListInCombat_Class4(skills, petGuid)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateSkillListInCombat_Class4(skills, petGuid)
  if #skills > 0 then
    self:SafeCall(self.Line1_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.SkillList, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    local dataList = {}
    for i, skill in ipairs(skills) do
      local data = {}
      table.copy(skill, data)
      data.petGuid = petGuid
      table.insert(dataList, data)
    end
    self:SafeCall(self.SkillList, "InitGridView", dataList)
    self:DelaySeconds(0.01, function()
      self:SafeCall(self.SkillList, "RefreshGridViewLayout")
    end)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetDisplaySkills(card)
  local skills_rule1 = card:GetDisplaySkillsForShowPetInfo()
  for i = #skills_rule1, 1, -1 do
    if not skills_rule1[i].priority_display and (skills_rule1[i].state == ProtoEnum.SkillState.SKILL_DISABLED or 0 == skills_rule1[i].pos) then
      table.remove(skills_rule1, i)
    end
  end
  local skills_rule2 = {}
  for _, skillData in pairs(skills_rule1) do
    if not skills_rule2[skillData.pos] or skillData.priority_display then
      skills_rule2[skillData.pos] = skillData
    end
  end
  local skills_rule3 = {}
  for i, v in pairs(skills_rule2) do
    table.insert(skills_rule3, v)
  end
  return skills_rule3
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetDisplaySkillsForEnemy(card)
  return card:GetDisplaySkillsForEnemy(false)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateBreakThroughStarsList(petData)
  self:SafeCall(self.CatchHardLv, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
  local PetStarsList
  if BattleUtils.IsPvp() or BattleUtils.IsWeeklyChallenge() then
    PetStarsList = PetUtils.GetBreakThroughStarsList(petData)
  else
    PetStarsList = PetUtils.GetPetStarsListByPetGID(petData.gid, petData)
  end
  if PetStarsList then
    self:SafeCall(self.CatchHardLv, "InitGridView", PetStarsList)
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:UpdateBreakThroughStarsListInCombat(card)
  if card:IsEnemy() then
    return
  end
  local petData = card.petInfo.battle_common_pet_info
  self:UpdateBreakThroughStarsList(petData)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetPetFeatrueSkillId_Class4(battle_commmon_pet_info, battle_inside_pet_info)
  if PetUtils.DoCheckIsMimic(battle_inside_pet_info) then
    return 0, false
  end
  if battle_inside_pet_info and battle_inside_pet_info.cur_passive_skill and battle_inside_pet_info.cur_passive_skill > 0 then
    return battle_inside_pet_info.cur_passive_skill, false
  end
  if battle_commmon_pet_info then
    local baseConfId = battle_commmon_pet_info.base_conf_id
    local featureSkillUsage = 0
    if battle_inside_pet_info then
      baseConfId = battle_inside_pet_info.base_conf_id
      local buffBaseConf = PetUtils.FindFirstBuffBaseConfByBuffType(battle_inside_pet_info, Enum.BuffType.BFT_O_TWO)
      if buffBaseConf then
        featureSkillUsage = buffBaseConf.buffbase_param and buffBaseConf.buffbase_param[5]
        if 1 == featureSkillUsage then
          baseConfId = battle_commmon_pet_info.base_conf_id
        elseif 2 == featureSkillUsage then
          baseConfId = battle_inside_pet_info.base_conf_id
        end
      end
    end
    if baseConfId > 0 then
      local basePetConf = _G.DataConfigManager:GetPetbaseConf(baseConfId)
      if basePetConf then
        return self:GetPetFeatrueSkillId(basePetConf)
      end
    end
  end
  return 0, false
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetPetFeatrueSkillId(baseConf)
  if baseConf then
    local skillId = baseConf.pet_feature
    if 0 ~= skillId then
      return skillId, false
    else
      local evolution_pet_id = baseConf.evolution_pet_id[1]
      if evolution_pet_id then
        local evoPetbaseCfg = _G.DataConfigManager:GetPetbaseConf(evolution_pet_id)
        if evolution_pet_id then
          skillId = evoPetbaseCfg.pet_feature
          if 0 ~= skillId then
            return skillId, true
          end
        end
      end
    end
  end
  return 0, false
end

function UMG_Battle_ChangePetConfirm_BaseUtility:SetTypes(base_conf_id, blood_id, bIsPartialShow, bIsMyself)
  local typeAndBloodList = {}
  local Types = not bIsPartialShow and BattleUtils.GetPetDefaultTypes(base_conf_id) or nil
  if Types then
    local attr1 = Types[1]
    local attr2 = Types[2]
    local attr3 = Types[3]
    local petTypes = {
      attr1,
      attr2,
      attr3
    }
    if petTypes then
      for i = 1, 3 do
        local petType = petTypes[i]
        if petType and petType > 0 then
          table.insert(typeAndBloodList, {
            Type = petType,
            Callback = function()
              self:OnAttrClicked()
            end
          })
        end
      end
    end
  end
  if bIsMyself and blood_id then
    local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(blood_id)
    if PetBloodConf then
      table.insert(typeAndBloodList, {
        Name = PetBloodConf.blood_name,
        Path = PetBloodConf.icon
      })
    end
  end
  self.Attr:InitGridView(typeAndBloodList)
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetAllTeam(b_is_enemy)
  local teams = {}
  if b_is_enemy then
    teams = _G.BattleManager.battlePawnManager:GetAllEnemyTeam(BattleEnum.Team.ENUM_TEAM)
  else
    teams = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  end
  return teams
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetBattleCards(b_is_enemy)
  local teams = self:GetAllTeam(b_is_enemy)
  local cards = {}
  for i = 1, #teams do
    local team = teams[i]
    local battle_cards = team:GetInBattleCards()
    for j = 1, #battle_cards do
      local card = battle_cards[j]
      if b_is_enemy then
        local isNotPrepare = card and not card:IsPetInPrepareZone()
        if isNotPrepare then
          table.insert(cards, {
            card,
            BattleEnum.SpeedCompare.ENUM_NOTSURE
          })
        end
      else
        table.insert(cards, {
          card,
          BattleEnum.SpeedCompare.ENUM_NOTSURE
        })
      end
    end
  end
  return cards
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetBattleCard(b_is_enemy, pet_id)
  local teams = self:GetAllTeam(b_is_enemy)
  local card
  for i = 1, #teams do
    local team = teams[i]
    local cards = team:GetInBattleCards()
    for j = 1, #cards do
      local b_card = cards[j]
      if b_card.guid == pet_id then
        card = b_card
        return card
      end
    end
  end
  return card
end

function UMG_Battle_ChangePetConfirm_BaseUtility:GetReservesCard(b_is_enemy, pet_id)
  local teams = self:GetAllTeam(b_is_enemy)
  local card
  for i = 1, #teams do
    local team = teams[i]
    local reserves_cards = team:GetReservesPetCards()
    for j = 1, #reserves_cards do
      local r_card = reserves_cards[j]
      if r_card.guid == pet_id then
        card = r_card
        return card
      end
    end
  end
  return card
end

function UMG_Battle_ChangePetConfirm_BaseUtility:PlayTypeAnimation()
  if self.NRCGridView then
    for i = 1, self.NRCGridView:GetItemCount() do
      local item = self.NRCGridView:GetItemByIndex(i - 1)
      item:PlayAnimation(item.shake)
    end
  end
  if self.NRCGridView_0 then
    for i = 1, self.NRCGridView_0:GetItemCount() do
      local item = self.NRCGridView_0:GetItemByIndex(i - 1)
      item:PlayAnimation(item.shake)
    end
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:OnAttrClicked()
  if not self.data then
    return
  end
  local card_data = self.data.cardData
  if card_data then
    if card_data:IsInBattle() then
      self:PlayTypeAnimation()
    elseif card_data:IsMyself() then
      self:ShowPetTypeAdvantageTip(card_data)
    else
      self:PlayTypeAnimation()
    end
  else
    self:PlayTypeAnimation()
  end
end

function UMG_Battle_ChangePetConfirm_BaseUtility:InitResonance()
  local card_data = self.data.cardData
  if not card_data or not card_data.BattlePet then
    return
  end
  if not card_data.petInfo or not card_data.petInfo.battle_inside_pet_info.feature_resonance then
    return
  end
  if not card_data:IsInBattle() then
    return
  end
  if BattleUtils.IsResonance() then
    local player_cards = self:GetBattleCards(false)
    for _, card in ipairs(player_cards) do
      if card[1].BattlePet and card[1].BattlePet:IsDead() then
        return
      end
    end
  end
  local skill_id = card_data.petInfo.battle_inside_pet_info.feature_resonance.skill_id
  if skill_id and skill_id > 0 then
    local skill_cfg = SkillUtils.GetSkillConf(skill_id)
    if skill_cfg then
      self.resonance_desc_text = skill_cfg.desc
      if skill_cfg.icon then
        self:SafeCall(self.ResonanceIcon, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
        self:SafeCall(self.ResonanceIcon, "SetPath", skill_cfg.icon)
      else
        self:SafeCall(self.ResonanceIcon, "SetVisibility", UE4.ESlateVisibility.Collapsed)
      end
      self:SafeCall(self.ResonanceTxt, "SetText", skill_cfg.name)
      self:SafeCall(self.NRCTextDes_1, "SetText", skill_cfg.desc)
      self:SafeCall(self.ResonancePlane, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

return UMG_Battle_ChangePetConfirm_BaseUtility

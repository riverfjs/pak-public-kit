local DummyTable = require("Common.DummyTable")
local RogueModuleUtils = {}

function RogueModuleUtils.GetMonsterConfByEventID(EventID)
  local EventConf = _G.DataConfigManager:GetGrassTrialEventConf(EventID)
  local BattleConf = _G.DataConfigManager:GetBattleConf(EventConf.param1)
  local MonsterID = BattleConf.npc_battle_list[1].pos1_1st[1]
  return _G.DataConfigManager:GetMonsterConf(MonsterID)
end

function RogueModuleUtils.GetBaseConfIDByEventID(EventID)
  local BattleID = _G.DataConfigManager:GetGrassTrialEventConf(EventID).param1
  local MonsterID = _G.DataConfigManager:GetBattleConf(BattleID).npc_battle_list[1].pos1_1st[1]
  return _G.DataConfigManager:GetMonsterConf(MonsterID).base_id
end

function RogueModuleUtils.FuseSkill(RawFusedSkillData, NormalSkillID, Rule)
  if not RawFusedSkillData then
    Log.Error("FuseSkill: RawFusedSkillData is nil")
  end
  local NormalSkillConf = _G.DataConfigManager:GetSkillConf(NormalSkillID)
  if not NormalSkillConf then
    return RawFusedSkillData
  end
  local NormalPower = NormalSkillConf.dam_para and NormalSkillConf.dam_para[1] or 0
  local NormalEnergyCost = NormalSkillConf.energy_cost and NormalSkillConf.energy_cost[1] or 0
  if RawFusedSkillData.fusion_count >= RawFusedSkillData.fusion_max then
    return RawFusedSkillData
  end
  for _, MergedId in ipairs(RawFusedSkillData.merged_skill_ids or DummyTable) do
    if MergedId == NormalSkillID then
      return RawFusedSkillData
    end
  end
  local CurrentPower = RawFusedSkillData.fused_power or 0
  local CurrentEnergyCost = RawFusedSkillData.fused_energy_cost or 0
  local NewPower, NewEnergyCost
  if Rule == Enum.GrassTrialFusionType.GTFT_TYPE1_0 then
    NewPower = CurrentPower + NormalPower
    NewEnergyCost = CurrentEnergyCost + NormalEnergyCost
  elseif Rule == Enum.GrassTrialFusionType.GTFT_TYPE1_1 then
    NewPower = CurrentPower + NormalPower
    NewEnergyCost = math.max(CurrentEnergyCost, NormalEnergyCost)
  elseif Rule == Enum.GrassTrialFusionType.GTFT_TYPE1_2 then
    NewPower = CurrentPower + NormalPower
    NewEnergyCost = math.ceil((CurrentEnergyCost + NormalEnergyCost) / 2)
  elseif Rule == Enum.GrassTrialFusionType.GTFT_TYPE2_0 then
    NewPower = math.max(CurrentPower, NormalPower)
    NewEnergyCost = math.max(CurrentEnergyCost, NormalEnergyCost)
  elseif Rule == Enum.GrassTrialFusionType.GTFT_TYPE2_1 then
    NewPower = math.max(CurrentPower, NormalPower)
    NewEnergyCost = math.ceil((CurrentEnergyCost + NormalEnergyCost) / 2)
  elseif Rule == Enum.GrassTrialFusionType.GTFT_TYPE2_2 then
    NewPower = math.max(CurrentPower, NormalPower)
    NewEnergyCost = math.ceil((CurrentEnergyCost + NormalEnergyCost) / 2)
  else
    NewPower = CurrentPower + NormalPower
    NewEnergyCost = CurrentEnergyCost + NormalEnergyCost
  end
  local MergedIds = {}
  for _, Id in ipairs(RawFusedSkillData.merged_skill_ids or DummyTable) do
    table.insert(MergedIds, Id)
  end
  table.insert(MergedIds, NormalSkillID)
  local FusedResults = {}
  for _, Result in ipairs(NormalSkillConf.skill_result or DummyTable) do
    table.insert(FusedResults, Result)
  end
  local Result = _G.ProtoMessage:newGrassTrialFusedSkillData()
  Result.base_skill_id = RawFusedSkillData.base_skill_id
  Result.fused_power = NewPower
  Result.fused_energy_cost = NewEnergyCost
  Result.fusion_count = (RawFusedSkillData.fusion_count or 0) + 1
  Result.fusion_max = RawFusedSkillData.fusion_max
  Result.skill_type = RawFusedSkillData.skill_type
  Result.merged_skill_ids = MergedIds
  Result.slot_pos = RawFusedSkillData.slot_pos
  Result.fused_skill_results = FusedResults
  return Result
end

return RogueModuleUtils

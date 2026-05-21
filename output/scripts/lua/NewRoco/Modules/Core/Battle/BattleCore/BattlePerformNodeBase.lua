local Class = _G.MakeSimpleClass
local BattlePiecesData = require("NewRoco.Modules.Core.Battle.BattleCore.Pieces.BattlePiecesData")
local BattlePiecesNpcAIPerform = require("NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePiecesNpcAIPerform")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local LockWeatherReason = require("NewRoco.Modules.System.EnvSystem.LockWeatherReason")
local BattlePerformNodeBase = Class("BattlePerformNodeBase")
BattlePerformNodeBase.LogicCastType = {ON_PLAYING = 0, ON_BE_COUNTER = 1}
BattlePerformNodeBase:SetMemberCount(32)

function BattlePerformNodeBase:Ctor(performPlayer)
  self:ResetData()
  self:Init(performPlayer)
end

function BattlePerformNodeBase:Init(performPlayer)
  self.performPlayer = performPlayer
  self.playerPool = BattlePlayerPool
  self.dataCenter = BattleDataCenter
  self:TryBuildHandler()
  self.performHandler = BattlePerformNodeBase.performHandler
  self.performFastHandler = BattlePerformNodeBase.performFastHandler
  self.performTypeToWord = BattlePerformNodeBase.performTypeToWord
  self.castmomentToWord = BattlePerformNodeBase.castmomentToWord
end

function BattlePerformNodeBase:TryBuildHandler()
  if not BattlePerformNodeBase.performHandler then
    BattlePerformNodeBase.performHandler = {
      [ProtoEnum.BattlePerformType.BPT_SKILL_CAST] = self.PerformSkill,
      [ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER] = self.PerformBuff,
      [ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER] = self.PerformEffect,
      [ProtoEnum.BattlePerformType.BPT_ENERGY] = self.ToDoFuncEnergy,
      [ProtoEnum.BattlePerformType.BPT_DEATH] = self.PerformDeath,
      [ProtoEnum.BattlePerformType.BPT_REVIVE] = self.PerformRevive,
      [ProtoEnum.BattlePerformType.BPT_SHOW_LETTERS] = self.PerformShowLetter,
      [ProtoEnum.BattlePerformType.BPT_SP_ENERGY_TRIGGER] = self.PerformSpEnergy,
      [ProtoEnum.BattlePerformType.BPT_USE_ITEM] = self.PerformUseItem,
      [ProtoEnum.BattlePerformType.BPT_CHANGE_PET] = self.PerformChangePet,
      [ProtoEnum.BattlePerformType.BPT_IDLE] = self.PerformIdle,
      [ProtoEnum.BattlePerformType.BPT_MONSTER_CATCH_CHANGE] = self.PerformCatchChange,
      [ProtoEnum.BattlePerformType.BPT_MONSTER_ESCAPE_CHANGE] = self.PerformEscapeChange,
      [ProtoEnum.BattlePerformType.BPT_SKILL_STATE] = self.PerformSkillState,
      [ProtoEnum.BattlePerformType.BPT_CATCH_PET] = self.PerformCatchPet,
      [ProtoEnum.BattlePerformType.BPT_PET_EVOLUTION] = self.PerformEvolution,
      [ProtoEnum.BattlePerformType.BPT_SKILL_AURA] = self.PerformAura,
      [ProtoEnum.BattlePerformType.BPT_WEATHER_CHANGE] = self.PerformWeather,
      [ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL] = self.PerformChangeModel,
      [ProtoEnum.BattlePerformType.BPT_BOX_SHIELD_BREAK] = self.PerformBoxShieldBreak,
      [ProtoEnum.BattlePerformType.BPT_AI] = self.PerformNPCAI,
      [ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH] = self.PerformCheersSwitch,
      [ProtoEnum.BattlePerformType.BPT_PET_ESCAPE] = self.PerformCheersEscape,
      [ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST] = self.PerformPlayerSkill,
      [ProtoEnum.BattlePerformType.BPT_COMBO_SKILL] = self.PerformComboSkill,
      [ProtoEnum.BattlePerformType.BPT_BATTLER_ESCAPE] = self.PerformPlayerSkillEscape,
      [ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE] = self.PerformBuffChange,
      [ProtoEnum.BattlePerformType.BPT_BATTLER_HEAL] = self.PerformIncreaseBlood,
      [ProtoEnum.BattlePerformType.BPT_DAMAGE] = self.PerformDamage,
      [ProtoEnum.BattlePerformType.BPT_BATTLER_TASK_UPDATE] = self.PerformBattleTaskUpdate,
      [ProtoEnum.BattlePerformType.BPT_SUPPLY_PET] = self.PerformSupplyPet,
      [ProtoEnum.BattlePerformType.BPT_SKILL_POS_CHANGE] = self.PerformChangeSkillPosition,
      [ProtoEnum.BattlePerformType.BPT_NOTIFY_PERFORM] = self.PerformNotifyTips,
      [ProtoEnum.BattlePerformType.BPT_RUNAWAY_INFO] = self.PerformPlayerRunaway,
      [ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE] = self.PerformPrepareToBattle,
      [ProtoEnum.BattlePerformType.BPT_BAG_TO_PREPARE] = self.PerformBagToPrepare,
      [ProtoEnum.BattlePerformType.BPT_FEATURE_RESONANCE] = self.PerformResonance,
      [ProtoEnum.BattlePerformType.BPT_VC_FINISH_PERFORM] = self.PerformFinishPerform
    }
  end
  if not BattlePerformNodeBase.performFastHandler then
    BattlePerformNodeBase.performFastHandler = {
      [ProtoEnum.BattlePerformType.BPT_SKILL_CAST] = self.PerformFastSkill,
      [ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER] = self.PerformFastEffect,
      [ProtoEnum.BattlePerformType.BPT_DEATH] = self.PerformDeath,
      [ProtoEnum.BattlePerformType.BPT_REVIVE] = self.PerformRevive,
      [ProtoEnum.BattlePerformType.BPT_USE_ITEM] = self.PerformFastUseItem,
      [ProtoEnum.BattlePerformType.BPT_MONSTER_ESCAPE_CHANGE] = self.PerformEscapeChange,
      [ProtoEnum.BattlePerformType.BPT_CHANGE_PET] = self.PerformChangePet,
      [ProtoEnum.BattlePerformType.BPT_CATCH_PET] = self.PerformCatchPet,
      [ProtoEnum.BattlePerformType.BPT_PET_EVOLUTION] = self.PerformEvolution,
      [ProtoEnum.BattlePerformType.BPT_SKILL_AURA] = self.PerformAura,
      [ProtoEnum.BattlePerformType.BPT_WEATHER_CHANGE] = self.PerformWeather,
      [ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL] = self.PerformChangeModel,
      [ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH] = self.PerformCheersSwitch,
      [ProtoEnum.BattlePerformType.BPT_PET_ESCAPE] = self.PerformFastCheersEscape,
      [ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST] = self.PerformPlayerSkill,
      [ProtoEnum.BattlePerformType.BPT_COMBO_SKILL] = self.PerformFastSkill,
      [ProtoEnum.BattlePerformType.BPT_BATTLER_ESCAPE] = self.PerformPlayerSkillEscape,
      [ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE] = self.PerformBuffChange,
      [ProtoEnum.BattlePerformType.BPT_AI] = self.PerformNPCAI
    }
  end
  if not BattlePerformNodeBase.performTypeToWord then
    BattlePerformNodeBase.performTypeToWord = {
      [ProtoEnum.BattlePerformType.BPT_SKILL_CAST] = "BPT_SKILL_CAST",
      [ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER] = "BPT_BUFF_TRIGGER",
      [ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE] = "BPT_BUFF_CHANGE",
      [ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER] = "BPT_EFFECT_TRIGGER",
      [ProtoEnum.BattlePerformType.BPT_DAMAGE] = "BPT_DAMAGE",
      [ProtoEnum.BattlePerformType.BPT_HEAL] = "BPT_HEAL",
      [ProtoEnum.BattlePerformType.BPT_ENERGY] = "BPT_ENERGY",
      [ProtoEnum.BattlePerformType.BPT_DEATH] = "BPT_DEATH",
      [ProtoEnum.BattlePerformType.BPT_REVIVE] = "BPT_REVIVE",
      [ProtoEnum.BattlePerformType.BPT_SHOW_LETTERS] = "BPT_SHOW_LETTERS",
      [ProtoEnum.BattlePerformType.BPT_SP_ENERGY_CHANGE] = "BPT_SP_ENERGY_CHANGE",
      [ProtoEnum.BattlePerformType.BPT_SP_ENERGY_TRIGGER] = "BPT_SP_ENERGY_TRIGGER",
      [ProtoEnum.BattlePerformType.BPT_USE_ITEM] = "BPT_USE_ITEM",
      [ProtoEnum.BattlePerformType.BPT_CHANGE_PET] = "BPT_CHANGE_PET",
      [ProtoEnum.BattlePerformType.BPT_IDLE] = "BPT_IDLE",
      [ProtoEnum.BattlePerformType.BPT_MONSTER_CATCH_CHANGE] = "BPT_MONSTER_CATCH_CHANGE",
      [ProtoEnum.BattlePerformType.BPT_MONSTER_ESCAPE_CHANGE] = "BPT_MONSTER_ESCAPE_CHANGE",
      [ProtoEnum.BattlePerformType.BPT_SKILL_STATE] = "BPT_SKILL_STATE",
      [ProtoEnum.BattlePerformType.BPT_CATCH_PET] = "BPT_CATCH_PET",
      [ProtoEnum.BattlePerformType.BPT_PET_EVOLUTION] = "BPT_PET_EVOLUTION",
      [ProtoEnum.BattlePerformType.BPT_SKILL_AURA] = "BPT_SKILL_AURA",
      [ProtoEnum.BattlePerformType.BPT_WEATHER_CHANGE] = "BPT_WEATHER_CHANGE",
      [ProtoEnum.BattlePerformType.BPT_NOTIFY_PERFORM] = "BPT_NOTIFY_PERFORM",
      [ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL] = "BPT_CHANGE_MODEL",
      [ProtoEnum.BattlePerformType.BPT_AI] = "BPT_AI",
      [ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH] = "BPT_CHEERS_SWITCH",
      [ProtoEnum.BattlePerformType.BPT_PET_ESCAPE] = "BPT_PET_ESCAPE",
      [ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST] = "BPT_ROLE_SKILL_CAST",
      [ProtoEnum.BattlePerformType.BPT_COMBO_SKILL] = "BPT_COMBO_SKILL",
      [ProtoEnum.BattlePerformType.BPT_BATTLER_ESCAPE] = "BPT_BATTLER_ESCAPE",
      [ProtoEnum.BattlePerformType.BPT_SUPPLY_PET] = "BPT_SUPPLY_PET",
      [ProtoEnum.BattlePerformType.BPT_RUNAWAY_INFO] = "BPT_RUNAWAY_INFO",
      [ProtoEnum.BattlePerformType.BPT_SKILL_POS_CHANGE] = "BPT_SKILL_POS_CHANGE",
      [ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE] = "BPT_PREPARE_TO_BATTLE",
      [ProtoEnum.BattlePerformType.BPT_BAG_TO_PREPARE] = "BPT_BAG_TO_PREPARE",
      [ProtoEnum.BattlePerformType.BPT_VC_FINISH_PERFORM] = "BPT_VC_FINISH_PERFORM"
    }
  end
  if not BattlePerformNodeBase.castmomentToWord then
    BattlePerformNodeBase.castmomentToWord = {
      [ProtoEnum.Buffbasetrigger_type.OnAnimationHit] = "OnAnimationHit",
      [ProtoEnum.Buffbasetrigger_type.OnBeforeAttack] = "OnBeforeAttack",
      [ProtoEnum.Buffbasetrigger_type.OnHit] = "OnHit",
      [ProtoEnum.Buffbasetrigger_type.OnAfterAttack] = "OnAfterAttack",
      [ProtoEnum.Buffbasetrigger_type.OnBeforePetDead] = "OnBeforePetDead",
      [ProtoEnum.Buffbasetrigger_type.OnRoundEnd] = "OnRoundEnd",
      [ProtoEnum.Buffbasetrigger_type.OnCounter] = "OnCounter",
      [ProtoEnum.Buffbasetrigger_type.OnInterrupt] = "OnInterrupt",
      [ProtoEnum.Buffbasetrigger_type.OnCounterEnd] = "OnCounterEnd",
      [ProtoEnum.Buffbasetrigger_type.OnAttackHit] = "OnAttackHit"
    }
  end
end

function BattlePerformNodeBase:ResetData()
  self.groupID = -1
  self.performNodeIdx = -1
  self.performPlayer = nil
  self.IsLastHitNode = false
  self.IsLastDeadNode = false
  self.performHandler = nil
  self.performFastHandler = nil
  self.OwnerGroup = nil
  self.IsLogicOver = false
  self.IsPerformOver = false
  self.counterPerformNode = nil
  self.beCounterPerformNode = nil
  self.logicCastMoment = BattlePerformNodeBase.LogicCastType.ON_PLAYING
  self.EnergyQueue = Queue()
  self.parallel_nodes = {}
end

function BattlePerformNodeBase:ClearData()
  self.groupID = -1
  self.performNodeIdx = -1
  self.performPlayer = nil
  self.IsLastHitNode = false
  self.IsLastDeadNode = false
  self.playerPool = nil
  self.dataCenter = nil
  self.performHandler = nil
  self.performFastHandler = nil
  self.performTypeToWord = nil
  self.castmomentToWord = nil
  self.OwnerGroup = nil
  self.IsLogicOver = false
  self.IsPerformOver = false
  self.counterPerformNode = nil
  self.beCounterPerformNode = nil
  self.EnergyQueue = nil
  self.logicCastMoment = BattlePerformNodeBase.LogicCastType.ON_PLAYING
end

function BattlePerformNodeBase:PreProcess(performInfo, performNodeIdx)
  self.groupID = performInfo.group_id
  self.performNodeIdx = performNodeIdx
  self.performInfo = performInfo
  self.performNodeType = performInfo.type
  self:InitPlayer(performInfo)
  self:InitMultiDamage()
end

function BattlePerformNodeBase:AddParallelNode(node)
  table.insert(self.parallel_nodes, node)
end

function BattlePerformNodeBase:GetParallelNodes()
  return self.parallel_nodes
end

function BattlePerformNodeBase:InitMultiDamage()
  if self:IsDamageInfoNode() then
    local damageInfo = self:GetPerformData()
    damageInfo.totalDamageNumber = 1
    damageInfo.curDamageNumber = 0
    damageInfo.performDamageNumber = 0
  end
end

function BattlePerformNodeBase:SetTotalDamageNumber(totalDamageNumber)
  if self:IsDamageInfoNode() then
    local damageInfo = self:GetPerformData()
    damageInfo.totalDamageNumber = totalDamageNumber
  end
end

function BattlePerformNodeBase:SetPerformDamageNumber(number)
  if self:IsDamageInfoNode() then
    local damageInfo = self:GetPerformData()
    damageInfo.performDamageNumber = number
  end
end

function BattlePerformNodeBase:IsMultiAttackType()
  return self.isMultiAttackType
end

function BattlePerformNodeBase:SetIsMultiAttackType(isMultiAttack)
  self.isMultiAttackType = isMultiAttack
end

function BattlePerformNodeBase:SetMultiAttackNumber(multiAttackNumber)
  if self:IsDamageInfoNode() and SkillUtils.IsMultiAttackType(self:GetCastMoment()) then
    local damageInfo = self:GetPerformData()
    damageInfo.multiAttackNumber = multiAttackNumber
  end
  self.multiAttackNumber = multiAttackNumber
end

function BattlePerformNodeBase:ModifyCastMoment(cm)
  self.performInfo.cast_moment = cm
end

function BattlePerformNodeBase:SetCounterNode(counterNode)
  self.counterPerformNode = counterNode
end

function BattlePerformNodeBase:SetBeCounterNode(beCounterNode)
  self.beCounterPerformNode = beCounterNode
end

function BattlePerformNodeBase:GetCounterNode()
  return self.counterPerformNode
end

function BattlePerformNodeBase:GetBeCounterNode()
  return self.beCounterPerformNode
end

function BattlePerformNodeBase:GetMultiAttackNumber()
  return self.multiAttackNumber or 0
end

function BattlePerformNodeBase:GetInfo()
  return self.performInfo
end

function BattlePerformNodeBase:GetCastMoment()
  return self.performInfo.cast_moment
end

function BattlePerformNodeBase:SetLogicCastMoment(value)
  self.logicCastMoment = value or BattlePerformNodeBase.LogicCastType.ON_PLAYING
end

function BattlePerformNodeBase:GetLogicCastMoment()
  return self.logicCastMoment or BattlePerformNodeBase.LogicCastType.ON_PLAYING
end

function BattlePerformNodeBase:GetPerformType()
  return self.performNodeType
end

function BattlePerformNodeBase:GetPlayer()
  return self.player
end

function BattlePerformNodeBase:GetClusterID()
  return self.OwnerGroup.OwnerCluster.ClusterId
end

function BattlePerformNodeBase:GetGroupID()
  return self.groupID
end

function BattlePerformNodeBase:SetGroupID(groupId)
  self.groupID = groupId
end

function BattlePerformNodeBase:GetNodeIdx()
  return self.performNodeIdx
end

function BattlePerformNodeBase:GetSyncData()
  return self:GetInfo().sync_data
end

function BattlePerformNodeBase:GetPerformData()
  if self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    return self:GetInfo().skill_cast
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
    return self:GetInfo().buff_change
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    return self:GetInfo().buff_trigger
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
    return self:GetInfo().effect_trigger
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_DAMAGE then
    return self:GetInfo().damage_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_HEAL then
    return self:GetInfo().heal_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_ENERGY then
    return self:GetInfo().energy_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH then
    return self:GetInfo().dead_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_REVIVE then
    return self:GetInfo().revive_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SHOW_LETTERS then
    return self:GetInfo().show_letters
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SP_ENERGY_TRIGGER then
    return self:GetInfo().sp_energy_trigger
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SP_ENERGY_CHANGE then
    return self:GetInfo().sp_energy_change
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_USE_ITEM then
    return self:GetInfo().use_item
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
    return self:GetInfo().change_pet
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_IDLE then
    return self:GetInfo().idle_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_MONSTER_CATCH_CHANGE then
    return self:GetInfo().monster_catch_change
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_MONSTER_ESCAPE_CHANGE then
    return self:GetInfo().monster_escape_change
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_STATE then
    return self:GetInfo().skill_state
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CATCH_PET then
    return self:GetInfo().catch_pet_info
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL then
    return self:GetInfo().change_model
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BOX_SHIELD_BREAK then
    return self:GetInfo().box_shield_break
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_AI then
    return self:GetInfo().ai_perform
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH then
    return self:GetInfo().cheers_switch
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_PET_ESCAPE then
    return self:GetInfo().pet_escape
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
    return self:GetInfo().role_skill_cast, self:GetInfo().change_model
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    return self:GetInfo().combo_skill_cast
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BATTLER_ESCAPE then
    return self:GetInfo().battler_escape
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_NOTIFY_PERFORM then
    return self:GetInfo().notify_perform
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_RUNAWAY_INFO then
    return self:GetInfo().runaway
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE then
    return self:GetInfo().prepare_to_battle
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BAG_TO_PREPARE then
    return self:GetInfo().bag_to_prepare
  end
end

function BattlePerformNodeBase:GetGroupRef()
  if not self.performInfo.group_ref or 0 == self.performInfo.group_ref then
    return nil
  else
    return self.performInfo.group_ref
  end
end

function BattlePerformNodeBase:SetGroupRef(group_ref)
  self.performInfo.group_ref = group_ref
end

function BattlePerformNodeBase:GetPerformPlayer()
  return self.performPlayer
end

function BattlePerformNodeBase:IsClusterNodeHead()
  return not self:HasGroupRef() and self:IsGroupHead()
end

function BattlePerformNodeBase:HasGroupRef()
  return self:GetGroupRef() ~= nil
end

function BattlePerformNodeBase:IsMatchHeadGroupRef(groupID)
  return self:GetGroupRef() == groupID
end

function BattlePerformNodeBase:IsMatchGroup(groupID)
  return self:GetGroupID() == groupID
end

function BattlePerformNodeBase:IsMatchCastMoment(castMoment)
  return self:GetCastMoment() == castMoment
end

function BattlePerformNodeBase:IsGroupHead()
  return self.performInfo.is_group_head
end

function BattlePerformNodeBase:IsTriggerNode()
  return self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST or self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER or self.performNodeType == ProtoEnum.BattlePerformType.BPT_SP_ENERGY_TRIGGER or self.performNodeType == ProtoEnum.BattlePerformType.BPT_USE_ITEM or self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_PET or self.performNodeType == ProtoEnum.BattlePerformType.BPT_IDLE or self.performNodeType == ProtoEnum.BattlePerformType.BPT_MONSTER_CATCH_CHANGE or self.performNodeType == ProtoEnum.BattlePerformType.BPT_MONSTER_ESCAPE_CHANGE or self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_STATE or self.performNodeType == ProtoEnum.BattlePerformType.BPT_CATCH_PET or self.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH or self.performNodeType == ProtoEnum.BattlePerformType.BPT_PET_EVOLUTION or self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL or self.performNodeType == ProtoEnum.BattlePerformType.BPT_PET_TURN_BACK or self.performNodeType == ProtoEnum.BattlePerformType.BPT_AI or self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH or self.performNodeType == ProtoEnum.BattlePerformType.BPT_PET_ESCAPE or self.performNodeType == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST or self.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL or self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE
end

function BattlePerformNodeBase:IsLetterNode()
  return self.performNodeType == ProtoEnum.BattlePerformType.BPT_SHOW_LETTERS and self:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnBeforeAttack
end

function BattlePerformNodeBase:IsDamageInfoNode()
  return self.performNodeType == ProtoEnum.BattlePerformType.BPT_DAMAGE
end

function BattlePerformNodeBase:IsBuffChangeInfoNode()
  return self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE
end

function BattlePerformNodeBase:IsCopeSkill()
  return self:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnCounter or self:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnInterrupt or self:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnCounterEnd
end

function BattlePerformNodeBase:InitPlayer(performInfo)
  if self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    if self:GetInfo().skill_cast.perform_flag == ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_RESONANCE then
      self.player = self.playerPool:GetResonancePlayer()
    else
      self.player = self.playerPool:GetAttackPlayer()
    end
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    self.player = self.playerPool:GetBuffPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
    self.player = self.playerPool:GetBuffChangePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
    self.player = self.playerPool:GetEffectPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_DAMAGE then
    self.player = self.playerPool:GetDamagePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_HEAL then
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_ENERGY then
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH then
    self.player = self.playerPool:GetDeathPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_REVIVE then
    self.player = self.playerPool:GetRevivePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SHOW_LETTERS then
    self.player = self.playerPool:GetPopupPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SP_ENERGY_CHANGE then
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SP_ENERGY_TRIGGER then
    self.player = self.playerPool:GetSpEnergyPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_USE_ITEM then
    self.player = self.playerPool:GetUseItemPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
    self.player = self.playerPool:GetChangePetPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_IDLE then
    self.player = self.playerPool:GetIdlePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_MONSTER_CATCH_CHANGE then
    self.player = self.playerPool:GetCatchChangePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_MONSTER_ESCAPE_CHANGE then
    self.player = self.playerPool:GetEscapeChangePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_STATE then
    self.player = self.playerPool:GetSkillStatePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CATCH_PET then
    self.player = self.playerPool:GetCatchPetPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_PET_EVOLUTION then
    self.player = self.playerPool:GetEvolutionPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL then
    self.player = self.playerPool:GetChangeModelPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BOX_SHIELD_BREAK then
    self.player = self.playerPool:GetSurpriseBoxShieldBreakPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_CHEERS_SWITCH then
    self.player = self.playerPool:GetCheersSwitchPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_PET_ESCAPE then
    self.player = self.playerPool:GetCheersEscapePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
    self.player = self.playerPool:GetPlayerSkillPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    self.player = self.playerPool:GetComboSkillPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BATTLER_ESCAPE then
    self.player = self.playerPool:GetPlayerSkillEscapePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BATTLER_HEAL then
    self.player = self.playerPool:GetIncreaseBloodPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BATTLER_TASK_UPDATE then
    self.player = self.playerPool:GetBattleTaskStatePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SUPPLY_PET then
    self.player = self.playerPool:GetSupplyPetPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_POS_CHANGE then
    self.player = self.playerPool:GetChangeSkillPositionPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_NOTIFY_PERFORM then
    self.player = self.playerPool:GetNotifyPerformPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_RUNAWAY_INFO then
    self.player = self.playerPool:GetPlayerRunawayPerformPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE then
    self.player = self.playerPool:GetPrepareToBattlePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BAG_TO_PREPARE then
    self.player = self.playerPool:GetBagToPreparePlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_FEATURE_RESONANCE then
    self.player = self.playerPool:GetParallelPlayer()
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_VC_FINISH_PERFORM then
    self.player = self.playerPool:GetFinishPerformPlayer()
  end
end

function BattlePerformNodeBase:ToDoFuncEnergy()
  Log.Debug("BattlePerformNodeBase DoPerform ToDoFuncEnergy:")
  if self:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnFlyEnergy then
    self:GetPerformData().isFly = true
  else
    self:GetPerformData().isFly = false
  end
  self:PerformComplete()
end

function BattlePerformNodeBase:ToDoFuncDeath()
  Log.Debug("BattlePerformNodeBase DoPerform ToDoFuncDeath:")
  self:PerformComplete()
end

function BattlePerformNodeBase:PerformSkill(performInfo)
  local skillCast = performInfo.skill_cast
  if skillCast then
    Log.Debug("BattlePerformNodeBase DoPerform PerformSkill:", skillCast.skill_id)
    local casterPet = BattleManager.battlePawnManager:GetPetByGuid(skillCast.caster_id)
    if not casterPet then
      local petInfo = _G.DataConfigManager:GetPetbaseConf(BattleManager.battleRuntimeData:GetPetConfIDByGuid(skillCast.caster_id))
      Log.Warning("\230\137\190\228\184\141\229\136\176\230\150\189\230\179\149\229\174\160\231\137\169 ", skillCast.caster_id, petInfo and petInfo.name or "\230\137\190\228\184\141\229\136\176PetBaseConf")
    end
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformResonance(performInfo)
  self.player:Play(self)
end

function BattlePerformNodeBase:PerformFinishPerform(performInfo)
  self.player:Play(self)
end

function BattlePerformNodeBase:PerformBoxShieldBreak(performInfo)
  local box_shield_break = performInfo.box_shield_break
  if box_shield_break then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformComboSkill(performInfo)
  local comboSkillCast = performInfo.combo_skill_cast
  if comboSkillCast then
    Log.Debug("BattlePerformNodeBase DoPerform PerformComboSkill:", comboSkillCast.skill_id)
    local casterPet = BattleManager.battlePawnManager:GetPetByGuid(comboSkillCast.caster_id)
    if not casterPet then
      local petInfo = _G.DataConfigManager:GetPetbaseConf(BattleManager.battleRuntimeData:GetPetConfIDByGuid(comboSkillCast.caster_id))
      Log.Warning("\230\137\190\228\184\141\229\136\176\230\150\189\230\179\149\229\174\160\231\137\169 ", comboSkillCast.caster_id, petInfo and petInfo.name or "\230\137\190\228\184\141\229\136\176PetBaseConf")
    end
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformPlayerSkillEscape(performInfo)
  local battler_escape = performInfo.battler_escape
  if battler_escape then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformBuff(performInfo)
  local buffTrigger = performInfo.buff_trigger
  if buffTrigger then
    Log.Debug("BattlePerformNodeBase DoPerform PerformBuff:", buffTrigger.buff_id)
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformIncreaseBlood(performInfo)
  local battler_heal_info = performInfo.battler_heal_info
  if battler_heal_info then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformBattleTaskUpdate(performInfo)
  local taskInfo = performInfo.sync_data and performInfo.sync_data.task_infos or nil
  if taskInfo then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformSupplyPet(performInfo)
  local supplyInfo = performInfo.supply_pet
  if supplyInfo then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformChangeSkillPosition(performInfo)
  local skill_pos_change = performInfo.skill_pos_change
  if skill_pos_change then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformNotifyTips(performInfo)
  local notify_perform = performInfo.notify_perform
  if notify_perform then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformPlayerRunaway(performInfo)
  local runaway = performInfo.runaway
  if runaway then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformDamage(performInfo)
  local damage_info = performInfo.damage_info
  if damage_info then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformBuffChange(performInfo)
  local buffChange = performInfo.buff_change
  if buffChange then
    Log.Debug("BattlePerformNodeBase DoPerform PerformBuffChange:", buffChange.buff_id)
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformSpEnergy(performInfo)
  local spEnergy = performInfo.sp_energy_trigger
  if spEnergy then
    Log.Debug("BattlePerformNodeBase DoPerform PerformSpEnergy:", spEnergy.dam_type)
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformUseItem(performInfo)
  local use_Item = performInfo.use_item
  if use_Item then
    Log.Debug("BattlePerformNodeBase DoPerform perform use item:", use_Item.item_id)
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformChangePet(performInfo)
  local change_pet = performInfo.change_pet
  if change_pet then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformIdle(performInfo)
  local idle_info = performInfo.idle_info
  if idle_info then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformCatchChange(performInfo)
  local monster_catch_change = performInfo.monster_catch_change
  if monster_catch_change then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformEscapeChange(performInfo)
  local monster_escape_change = performInfo.monster_escape_change
  if monster_escape_change then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformSkillState(performInfo)
  local skill_state = performInfo.skill_state
  if skill_state then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformCatchPet(performInfo)
  local catch_pet_info = performInfo.catch_pet_info
  if catch_pet_info then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformDeath(performInfo)
  local dead_info = performInfo.dead_info
  if dead_info then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformRevive(performInfo)
  local revive_info = performInfo.revive_info
  if revive_info then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformEvolution(performInfo)
  local petEvolution = performInfo.pet_evolution
  if petEvolution then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformChangeModel(performInfo)
  local changeModel = performInfo.change_model
  if changeModel then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformNPCAI(performInfo)
  local data = BattlePiecesData()
  data.performInfo = performInfo
  local piece = BattlePiecesNpcAIPerform(data, self)
  piece:Play()
end

function BattlePerformNodeBase:PerformAura(performInfo)
  local auraInfo = performInfo.skill_aura
  local battle_tag = ProtoMessage:newSpaceActionTag_Battle()
  battle_tag.battle_id = BattleManager.battleRuntimeData.battle_id
  battle_tag.round = BattleManager.battleRuntimeData.roundIndex
  battle_tag.group_id = performInfo.group_id
  battle_tag.skill_id = auraInfo.skill_id
  battle_tag.cast_moment = auraInfo.cast_moment
  Log.Debug("BattlePerformNodeBase PerformAura:", table.tostring(battle_tag))
  NRCModuleManager:DoCmd(SceneModuleCmd.ConsumeCachedBattleTag, battle_tag)
  self:PerformComplete()
end

function BattlePerformNodeBase:PerformWeather(performInfo)
  local weatherInfo = performInfo.weather_change
  local battle_tag = ProtoMessage:newSpaceActionTag_Battle()
  battle_tag.battle_id = BattleManager.battleRuntimeData.battle_id
  battle_tag.round = BattleManager.battleRuntimeData.roundIndex
  battle_tag.group_id = performInfo.group_id
  battle_tag.skill_id = weatherInfo.skill_id
  battle_tag.cast_moment = weatherInfo.cast_moment
  Log.Debug("BattlePerformNodeBase PerformWeather:", table.tostring(battle_tag))
  local weather_id = weatherInfo.weather_id
  local weather_expire_round = weatherInfo.weather_expire_round
  _G.BattleManager.battleRuntimeData:UpdateWeatherInfo(weather_id, weather_expire_round)
  local weatherCfg = _G.DataConfigManager:GetWeatherConf(weather_id)
  local tip = weatherCfg.report_tip
  if not weatherInfo.hide_tips then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip)
  end
  _G.NRCModuleManager:DoCmd(_G.EnvSystemModuleCmd.LockWeather, weather_id, LockWeatherReason.Battle)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowBattleMainWeatherUi)
  self:PerformComplete()
end

function BattlePerformNodeBase:PerformCheersSwitch(performInfo)
  local cheers_switch = performInfo.cheers_switch
  if cheers_switch then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformCheersEscape(performInfo)
  local pet_escape = performInfo.pet_escape
  if pet_escape then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformPlayerSkill(performInfo)
  local role_skill_cast = performInfo.role_skill_cast
  if role_skill_cast then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformEffect(performInfo)
  Log.Debug("BattlePerformNodeBase DoPerform PerformEffect:", self:GetNodeIdx(), performInfo.effect_id)
  local effectTrigger = performInfo.effect_trigger
  if effectTrigger then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformShowLetter(performInfo)
  Log.Debug("BattlePerformNodeBase DoPerform PerformShowLetter:")
  self.player:Play(self)
end

function BattlePerformNodeBase:PerformFastSkill(performInfo)
  local skillCast = performInfo.skill_cast
  if skillCast then
    self:SyncEnergyForSkillPlayer(SkillUtils.InstSkillIdToCfgId(skillCast.skill_id), performInfo.sync_data)
    if BattleUtils.IsTeam() then
      _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_PERFORM_SKILL, skillCast)
    end
  end
  if self:GetCounterNode() then
    self:DispatchPerformCallback(self:GetCounterNode():GetCastMoment())
  end
  self:PerformComplete()
end

function BattlePerformNodeBase:DispatchPerformCallback(castMoment, LimitType)
end

function BattlePerformNodeBase:SyncEnergyForSkillPlayer(sourceId, syncData, isFly)
  if self.IsLogicOver then
    BattleDataCenter:SyncEnergy(sourceId, syncData, isFly)
  else
    self.EnergyQueue:Enqueue({
      sourceId = sourceId,
      syncData = syncData,
      isFly = isFly
    })
  end
end

function BattlePerformNodeBase:ProcessAllEnergyQueue()
  local energyQueue = self.EnergyQueue
  if energyQueue and energyQueue:Size() > 0 then
    local energyData = energyQueue:Dequeue()
    while energyData do
      BattleDataCenter:SyncEnergy(energyData.sourceId, energyData.syncData, energyData.isFly)
      energyData = energyQueue:Size() > 0 and energyQueue:Dequeue()
    end
  end
end

function BattlePerformNodeBase:PerformFastCheersEscape(performInfo)
  local pet_escape = performInfo.pet_escape
  if pet_escape then
    local escapePet = BattleManager.battlePawnManager:GetPetByGuid(pet_escape.pet_id)
    if escapePet then
      escapePet.card:SetInBattleField(false)
      _G.BattleEventCenter:Dispatch(BattleEvent.CHEER_ESCAPE, escapePet)
      escapePet:Destroy()
    end
  end
  self:PerformComplete()
end

function BattlePerformNodeBase:PerformFastEffect(performInfo)
  Log.Debug("BattlePerformNodeBase DoPerform PerformEffect:", performInfo.effect_id)
  local effectTrigger = performInfo.effect_trigger
  if effectTrigger and effectTrigger.result == ProtoEnum.BattleEffectResultType.BERT_MONSTER_ESCAPE then
    BattleExitHelper.SetEnemyEscape(self.Caster, nil)
  end
  self:PerformComplete()
end

function BattlePerformNodeBase:PerformFastUseItem(performInfo)
  local use_Item = performInfo.use_item
  if use_Item then
    local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(use_Item.player_id)
    if player then
      local IsPartnerPerform = player.teamEnm == BattleEnum.Team.ENUM_TEAM and player ~= BattleManager.battlePawnManager:GetPlayerMyTeam()
      if not IsPartnerPerform then
        _G.BattleManager.battleRuntimeData.backOperateType = BattleEnum.Operation.ENUM_ITEM
      end
    end
  end
  self:PerformComplete()
end

function BattlePerformNodeBase:PerformPrepareToBattle(performInfo)
  local prepare_to_battle = performInfo.prepare_to_battle
  if prepare_to_battle then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformBagToPrepare(performInfo)
  local bag_to_prepare = performInfo.bag_to_prepare
  if bag_to_prepare then
    self.player:Play(self)
  else
    self:PerformComplete()
  end
end

function BattlePerformNodeBase:PerformComplete()
end

function BattlePerformNodeBase:ReleaseRes()
end

function BattlePerformNodeBase:Release()
  self:ReleaseRes()
end

function BattlePerformNodeBase:GetPerformTypeTostring()
  return (self.performTypeToWord[self.performNodeType] or "UnknowType" .. "(" .. self.performNodeType .. ")") .. " " .. (self:GetNodeIdx() or "UnknowIdx")
end

function BattlePerformNodeBase:GetCastMomentToString()
  return self.castmomentToWord[self:GetCastMoment()] or tostring(self:GetCastMoment())
end

function BattlePerformNodeBase:GetCasterIDToName()
  Log.Debug("BattlePerformNode GetCasterIDToName:", self:GetCasterID())
  local battleCard = BattleManager.battlePawnManager:GetCardByGuid(self:GetCasterID())
  return battleCard and battleCard:GetName() .. "(" .. self:GetCasterID() .. ")"
end

function BattlePerformNodeBase:GetCasterID()
  Log.Dump(self:GetPerformData(), 3, "self:GetPerformData():")
  return self:GetPerformData() and self:GetPerformData().caster_id or 0
end

function BattlePerformNodeBase:GetPerformID()
  if self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    return self:GetPerformData().skill_id
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    return self:GetPerformData().buff_id
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
    return self:GetPerformData().effect_id
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
    return self:GetPerformData().buff_id
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    return self:GetPerformData().skill_id
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
    local roleSkillCast, _ = self:GetPerformData()
    return roleSkillCast.skill_id
  else
    return "nil"
  end
end

function BattlePerformNodeBase:GetPerformIDToName()
  local performId = self:GetPerformID()
  if self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_SKILL_CAST or self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    local skillData = _G.SkillUtils.GetSkillConf(performId)
    return (skillData and skillData.name or "") .. "(" .. performId .. ")"
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    return (_G.DataConfigManager:GetBuffConf(performId) and _G.DataConfigManager:GetBuffConf(performId).name or "") .. "(" .. performId .. ")"
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
    return (_G.DataConfigManager:GetEffectConf(performId) and _G.DataConfigManager:GetEffectConf(performId).name or "") .. "(" .. performId .. ")"
  elseif self:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
    local buffCfg = _G.DataConfigManager:GetBuffConf(performId)
    if self:GetPerformData().buff_info then
      return (buffCfg and buffCfg.name or "") .. "(" .. performId .. ")" .. "  change to " .. self:GetPerformData().buff_info.stack
    else
      return (buffCfg and buffCfg.name or "") .. "(" .. performId .. ")" .. "  is removed"
    end
  else
    return "Nil" .. "(" .. self:GetPerformID() .. ")"
  end
end

function BattlePerformNodeBase:Dump()
  local performInfo = self:GetInfo()
  local data = self:GetInfo()
  Log.Debug([[
BattlePerformNode Dump 
Idx:]], self:GetNodeIdx(), self:GetPerformTypeTostring(), self:GetCastMomentToString(), self:IsPerforming(), self:IsPerformed(), "\n", "skill:", performInfo.skill_cast and 0 ~= performInfo.skill_cast.caster_id and table.tostring(performInfo.skill_cast), "buff:", performInfo.buff_change and 0 ~= performInfo.buff_change.caster_id and table.tostring(performInfo.buff_change), "bufftrigger:", performInfo.buff_trigger and 0 ~= performInfo.buff_trigger.caster_id and table.tostring(performInfo.buff_trigger), "dmg:", performInfo.damage_info and 0 ~= performInfo.damage_info.caster_id and table.tostring(performInfo.damage_info), "heal:", performInfo.heal_info and 0 ~= performInfo.heal_info.caster_id and table.tostring(performInfo.heal_info), "energy:", performInfo.energy_info and 0 ~= performInfo.energy_info.caster_id and table.tostring(performInfo.energy_info), "dead:", performInfo.dead_info and 0 ~= performInfo.dead_info.caster_id and table.tostring(performInfo.dead_info), "revive:", performInfo.revive_info and 0 ~= performInfo.revive_info.caster_id and table.tostring(performInfo.revive_info), "sync:", performInfo.sync_data and table.tostring(performInfo.sync_data))
end

function BattlePerformNodeBase:GetProfilerInfo()
  if self.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
    return "BPT_SKILL_CAST skillId:" .. (self:GetInfo().skill_cast.skill_id or "nil") .. " " .. (self:GetNodeIdx() or "UnknowIdx")
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    return "BPT_BUFF_TRIGGER buffid:" .. (self:GetInfo().buff_trigger.buff_id or "nil") .. " " .. (self:GetNodeIdx() or "UnknowIdx")
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
    return "BPT_ROLE_SKILL_CAST skillid:" .. (self:GetInfo().role_skill_cast.skill_id or "nil") .. " " .. (self:GetNodeIdx() or "UnknowIdx")
  elseif self.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    return "BPT_COMBO_SKILL skillid:" .. (self:GetInfo().combo_skill_cast.skill_id or "nil") .. " " .. (self:GetNodeIdx() or "UnknowIdx")
  else
    return self:GetPerformTypeTostring()
  end
end

return BattlePerformNodeBase

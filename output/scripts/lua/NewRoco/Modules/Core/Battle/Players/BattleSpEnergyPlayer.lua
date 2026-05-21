local BattleAsyncChain = require("NewRoco.Modules.Core.Battle.Common.BattleAsyncChain")
local EventDispatcher = require("Common.EventDispatcher")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleSpEnergyPlayer = BattlePlayerBase:Extend()

function BattleSpEnergyPlayer:Ctor(owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
  self.Caster = nil
end

function BattleSpEnergyPlayer:Reset()
  self.Caster = nil
  self.performNode = nil
  self.performInfo = nil
end

function BattleSpEnergyPlayer:Play(performNode)
  self:Reset()
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.performInfo = performInfo
  self.SpEnergyInfo = performInfo.sp_energy_trigger
  self.Target = self.BattleManager.battlePawnManager:GetPetByGuid(self.SpEnergyInfo.caster_id)
  self.Caster = self.Target
  self.Team = self.Caster.team
  self.Player = self.Team.player
  self:ShowPopup()
  local CastSkillParam = CastSkillObject.FromPerformInfoToSpEnergyTrigger(performInfo.sp_energy_trigger)
  if not CastSkillParam then
    self:Finish()
    return
  end
  local DontAcceptPreEnd = false
  CastSkillParam:SetCaster(self.Caster.model):SetCompleteCallback(self.OnSkillComplete):SetSkillBreakCallback(self.OnSkillComplete):SetStartFailedCallback(self.OnSkillComplete):SetOnHitCallback(self.OnHit):SetCallbackOwner(self):SetInterrupt(true):SetAcceptPreEnd(not DontAcceptPreEnd):SetTargetPets(self:GetTargetPets()):SetDamageType(Enum.DamageType.DT_NONE):SetIsPassive(false):SetSpType(self.SpEnergyInfo.dam_type)
  self.Target:CommonCast(CastSkillParam)
  self.CastSkillParam = CastSkillParam
  _G.BattleEventCenter:Dispatch(BattleEvent.SP_ENERGY_TRIGGER, self.SpEnergyInfo.dam_type)
end

function BattleSpEnergyPlayer:ShowPopup()
  if self.SpEnergyInfo.trigger_type == ProtoEnum.BattleSpEnergyTrigger.SP_TRIGGER_TYPE.SP_TRIGGER_SKILL then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
      BattleEnum.InfoPopupType.UseSpEnergy,
      self.Caster.player,
      self.SpEnergyInfo.old_skill_id,
      self.SpEnergyInfo.new_skill_id
    }, self.Caster)
  end
end

function BattleSpEnergyPlayer:Finish()
  self:OnSkillComplete()
end

function BattleSpEnergyPlayer:OnSkillComplete()
  Log.Debug("BattleSpEnergyPlayer Play OnSkillComplete:", self.performNode:GetNodeIdx())
  self.performNode:PerformComplete()
end

function BattleSpEnergyPlayer:OnHit()
end

function BattleSpEnergyPlayer:GetTargetPets()
  local pets = {}
  local pet = self.Target
  if pet then
    table.insert(pets, pet)
  end
  return pets
end

return BattleSpEnergyPlayer

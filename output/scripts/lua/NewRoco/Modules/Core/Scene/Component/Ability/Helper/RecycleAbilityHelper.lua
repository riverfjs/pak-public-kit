local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local RecycleAbilityHelper = Base:Extend("RecycleAbilityHelper")

function RecycleAbilityHelper:HandleStatus(caster, ...)
  local ability = caster.abilityComponent:GetAbilityFromPool(AbilityID.RECYCLE_THROW)
  local success = caster.inputComponent:CastAbility(ability, nil, ...)
  caster.abilityComponent:ReturnAbilityToPool(ability)
  return success
end

function RecycleAbilityHelper:CanCastAbility(caster)
  local gid = NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  local rideComp = caster.viewObj.BP_RideComponent
  local buffComp = caster.buffComponent
  local RideAllBuff = buffComp:GetBuff("RideAll_Main_Buff")
  if rideComp and rideComp.ScenePet and rideComp.ScenePet.gid == gid and RideAllBuff and RideAllBuff.CanOffPet and not RideAllBuff:CanOffPet() then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  local session = ThrowSession.GetWithGID(gid)
  if not session then
    return Base.CanCastAbility(self, caster)
  end
  if session.canBeRecycle == false then
    return AbilityErrorCode.INPUT_DISABLED
  end
  return Base.CanCastAbility(self, caster)
end

function RecycleAbilityHelper:IsBlock(caster, pet)
  if self:CanCastAbility(caster, pet) ~= AbilityErrorCode.NO_ERROR then
    return true
  end
  return Base.IsBlock(self, caster)
end

return RecycleAbilityHelper

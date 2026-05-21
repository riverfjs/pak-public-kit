local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ThrowAbilityHelper = Base:Extend("ThrowAbilityHelper")

function ThrowAbilityHelper:CanCastAbility(caster, pet)
  local buffComp = caster.buffComponent
  if buffComp:HasBuff("ThrowBuff") or buffComp:HasBuff("MagicBuff") then
    return AbilityErrorCode.ABILITY_IS_CASTING
  end
  local RideAllBuff = buffComp:GetBuff("RideAll_Main_Buff")
  if RideAllBuff and RideAllBuff.CanThrowBall and not RideAllBuff:CanThrowBall() then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  if caster.viewObj == nil then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  local petData = pet and pet:GetPetData()
  if petData and 0 ~= petData.pet_status_flags & ProtoEnum.PetStatusFlag.TASK_TOGETHER_IN_PROGRESS then
    return AbilityErrorCode.TASK_LOCK
  end
  return Base.CanCastAbility(self, caster)
end

function ThrowAbilityHelper:HandleStatus(caster, ...)
  local statusComponent = caster.statusComponent
  if statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    caster:SendEvent(PlayerModuleEvent.ON_END_THROW, true)
  end
  Base.HandleStatus(self, caster, self:GetThrowStat(caster), ...)
end

function ThrowAbilityHelper:GetThrowStat(caster)
  local throwStat = ProtoEnum.SceneThrowAbilityType.STAT_NORMAL
  if caster.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_RIDEALL) then
    throwStat = ProtoEnum.SceneThrowAbilityType.STAT_RIDE_WOLF
  end
  return throwStat
end

function ThrowAbilityHelper:IsBlock(caster, pet)
  if self:CanCastAbility(caster, pet) ~= AbilityErrorCode.NO_ERROR then
    return true
  end
  return Base.IsBlock(self, caster)
end

return ThrowAbilityHelper

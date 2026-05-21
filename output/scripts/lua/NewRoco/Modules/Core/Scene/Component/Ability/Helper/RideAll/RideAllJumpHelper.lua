local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local RideAllJumpHelper = Base:Extend("RideAllJumpHelper")
local ActiveTypeEnum = ProtoEnum.SceneRideAllActiveType
local EnableActiveMap = {
  [ActiveTypeEnum.SRAA_DASH] = true,
  [ActiveTypeEnum.SRAA_FASTSWIM] = true,
  [ActiveTypeEnum.SRAA_SCOPE] = true,
  [ActiveTypeEnum.SRAA_PERCEPTION] = true
}
local InVisibleActiveMap = {
  [ActiveTypeEnum.SRAA_JUMP] = true,
  [ActiveTypeEnum.SRAA_CLIMB_WATER_JUMP] = true,
  [ActiveTypeEnum.SRAA_CLIMBUP] = true,
  [ActiveTypeEnum.SRAA_FLYUP] = true
}
local RideAllMainHelper = AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL_MAIN)

function RideAllJumpHelper:CanCastAbility(caster)
  local MainSkillConf = DataConfigManager:GetRideBasicMovement(RideAllMainHelper:GetRideMainAbility(caster), true)
  if MainSkillConf then
    local skillType = MainSkillConf.active_type
    if InVisibleActiveMap[skillType] then
      return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
    end
  end
  local SkillId = self:GetRideJumpAbility(caster)
  if nil == SkillId or 0 == SkillId then
    return AbilityErrorCode.CAN_NOT_FIND_ABILITY
  end
  return Base.CanCastAbility(self, caster)
end

function RideAllJumpHelper:GetRideJumpAbility(caster)
  local rideComponent = caster.viewObj.BP_RideComponent
  if rideComponent.ScenePet == nil then
    return nil
  end
  if rideComponent.bIsLoading then
    return nil
  end
  if not rideComponent.RidePet or not rideComponent.ScenePet.config then
    return nil
  end
  local moveId = rideComponent.RideMovementId
  if 0 == moveId then
    return self.lastRidePetSkillId or nil
  end
  local RideConf = DataConfigManager:GetAllRidePet(rideComponent.ScenePet.config.id)
  local abilityId
  for index, value in pairs(RideConf.second_active_skill__list) do
    local skillMovementId = RideConf.basic_movement_list[index]
    if moveId == skillMovementId then
      abilityId = value
      break
    end
  end
  if nil == abilityId then
    self.lastRidePetSkillId = nil
    return nil
  end
  local SkillConf = DataConfigManager:GetRideBasicMovement(abilityId, true)
  if nil == SkillConf then
    self.lastRidePetSkillId = nil
    return nil
  end
  self.lastRidePetId = rideComponent.ScenePet.config.id
  self.lastRidePetSkillId = abilityId
  self.lastRidePetSkillConf = SkillConf
  self.lastUIconf = DataConfigManager:GetAllRideUiConf(10000 + tonumber(SkillConf.active_type))
  return abilityId
end

function RideAllJumpHelper:GetIcon(caster, isBlock)
  local rideComponent = caster.viewObj.BP_RideComponent
  local SkillId = self:GetRideJumpAbility(caster)
  if nil == SkillId then
    return nil
  end
  local SkillConf = self.lastRidePetSkillConf
  local UIconf = self.lastUIconf
  if not UIconf then
    return nil
  end
  if self:CanCastAbility(caster) ~= AbilityErrorCode.NO_ERROR and nil ~= rideComponent.RidePet then
    return nil
  end
  isBlock = self:IsBlock(caster)
  if (SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_JUMP or SkillConf.active_type == Enum.SceneRideAllActiveType.SRAA_SWIMJUMP) and not isBlock and rideComponent.RidePet and rideComponent.RidePet.CharacterMovement and not rideComponent.RidePet.CharacterMovement:CanJump() then
    isBlock = true
  end
  if isBlock then
    return UIconf.button_block_icon
  end
  return UIconf.button_icon
end

function RideAllJumpHelper:GetPressIcon(caster)
  local SkillId = self:GetRideJumpAbility(caster)
  if nil == SkillId then
    return nil
  end
  local UIconf = self.lastUIconf
  if not UIconf then
    return nil
  end
  return UIconf.button_press_icon
end

function RideAllJumpHelper:IsBlock(caster)
  local rideComponent = caster.viewObj.BP_RideComponent
  if 0 == rideComponent.RideMovementId then
    return true
  end
  if caster.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) then
    local buff = caster.buffComponent:GetBuff("RideAll_Main_Buff")
    if not buff then
      return false
    end
    local curSkillType = buff.RideType
    if curSkillType and not EnableActiveMap[curSkillType] then
      return true
    end
  end
  return Base.IsBlock(self, caster)
end

function RideAllJumpHelper:HandleStatus(caster, ...)
  Base.HandleStatus(self, caster, self.lastRidePetSkillId, ...)
  caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_JUMP)
end

return RideAllJumpHelper

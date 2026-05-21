require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local RideAllMainAbility = Base:Extend("RideAllMainAbility")
local RideTypeMap = {
  [ProtoEnum.SceneRideAllActiveType.SRAA_DASH] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Dash",
  [ProtoEnum.SceneRideAllActiveType.SRAA_JUMP] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Jump",
  [ProtoEnum.SceneRideAllActiveType.SRAA_PERCEPTION] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Perception",
  [ProtoEnum.SceneRideAllActiveType.SRAA_FLYUP] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Fly",
  [ProtoEnum.SceneRideAllActiveType.SRAA_CLIMBUP] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_ClimbUp",
  [ProtoEnum.SceneRideAllActiveType.SRAA_POWERDASH] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_PowerDash",
  [ProtoEnum.SceneRideAllActiveType.SRAA_SCOPE] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Scope",
  [ProtoEnum.SceneRideAllActiveType.SRAA_FASTSWIM] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_FastSwim",
  [ProtoEnum.SceneRideAllActiveType.SRAA_LEAP] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Leap",
  [ProtoEnum.SceneRideAllActiveType.SRAA_GRAPPLE] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Grapple",
  [ProtoEnum.SceneRideAllActiveType.SRAA_SWIMJUMP] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Jump",
  [ProtoEnum.SceneRideAllActiveType.SRAA_DOUBLERIDE] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_DoubleRide",
  [ProtoEnum.SceneRideAllActiveType.SRAA_CLIMB_WATER_JUMP] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_ClimbWaterJump",
  [ProtoEnum.SceneRideAllActiveType.SRAA_KEEP_BALANCE] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_KeepBalance",
  [ProtoEnum.SceneRideAllActiveType.SRAA_DASH_WITHOUT_VITALITY] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_DashWithoutVitality",
  [ProtoEnum.SceneRideAllActiveType.SRAA_DASH_DASHFORWARD] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_DashForward",
  [ProtoEnum.SceneRideAllActiveType.SRAA_SMASH] = "NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_Smash"
}

function RideAllMainAbility:AwakeFromPool(owner)
  Base.AwakeFromPool(self, owner)
  self._buffName = "RideAll_Main_Buff"
end

function RideAllMainAbility:Start(onFinished, ...)
  if not self:TryStartSkill(...) and self.caster.isLocal then
    self.caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
  end
end

function RideAllMainAbility:TryStartSkill(customParams)
  local comp = self.caster.viewObj.BP_RideComponent
  if comp and comp.RidePet and comp.RidePet.InLeap then
    return false
  end
  if self.caster.buffComponent:HasBuff(self._buffName) or not customParams then
    return false
  end
  local SkillId = customParams.ride_skill_param.skill_id
  if nil == SkillId then
    return false
  end
  local SkillConf = DataConfigManager:GetRideBasicMovement(SkillId, true)
  if nil == SkillConf then
    return false
  end
  self.caster.abilityComponent:StopAbility(true, AbilityID.END_THROW)
  local RideType = SkillConf.active_type
  local RideBuff = require(RideTypeMap[RideType])
  self.caster.buffComponent:AddBuff(self._buffName, RideBuff, self.caster, SkillConf)
  return true
end

function RideAllMainAbility:Interrupt()
  self:Finish()
end

function RideAllMainAbility:Recover()
  if self.caster.isLocal then
    self.caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
  else
    self:Start()
  end
end

function RideAllMainAbility:Finish(Force)
  Base.Finish(self, Force)
end

function RideAllMainAbility.GetSceneRideAllActiveTypeByPath(_path)
  for key, path in pairs(RideTypeMap) do
    if path == _path then
      return key
    end
  end
  return 0
end

return RideAllMainAbility

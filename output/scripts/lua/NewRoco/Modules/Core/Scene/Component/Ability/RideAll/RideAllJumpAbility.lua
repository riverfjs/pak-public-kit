require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PetUtils = require("NewRoco.Utils.PetUtils")
local RideAllJumpAbility = Base:Extend("RideAllMainAbility")

function RideAllJumpAbility:AwakeFromPool(owner)
  Base.AwakeFromPool(self, owner)
end

function RideAllJumpAbility:Start(onFinished, SkillId, ...)
  Log.Debug("RideAllJumpAbility:Start")
  if not self.caster.isLocal then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(1220003273, self.caster.viewObj, "RideAllJump")
    local RidePet = self.caster.viewObj.RidePet
    if RidePet and RidePet.RocoMoveFx.PlayWaterJumpFx then
      RidePet.RocoMoveFx:PlayWaterJumpFx()
    end
    return
  end
  self.SkillId = SkillId
  self.SkillConf = DataConfigManager:GetRideBasicMovement(SkillId, true)
  self.RideType = self.SkillConf.active_type
  self.RideComp = self.caster.viewObj.BP_RideComponent
  self.RidePet = self.RideComp.RidePet
  self.SceneRidePet = self.RideComp.ScenePet
  self:DoJump()
end

function RideAllJumpAbility:DoJump()
  local RidePet = self.caster.viewObj.RidePet
  if not RidePet then
    return
  end
  local FxPlayer = RidePet.RocoMoveFx.CurrentPlayer
  if FxPlayer and FxPlayer.PlayWaterJumpFx then
    FxPlayer:PlayWaterJumpFx()
  end
  local SkillConf = self.SkillConf
  self:AnalyPropertyModify(SkillConf)
  local JumpZSpeed = tonumber(SkillConf.move_param_5)
  local SkillJumpZSpeed = self.caster.statComponent:GetValue(StatType.SKILL_JUMP_Z_SPEED)
  if self.propertyModify[5] then
    if 0 == self.modifyMode then
      JumpZSpeed = JumpZSpeed * SkillJumpZSpeed + self.modifyValue
    elseif 1 == self.modifyMode then
      JumpZSpeed = JumpZSpeed * SkillJumpZSpeed + JumpZSpeed * self.modifyValue / 10000
    else
      JumpZSpeed = JumpZSpeed * SkillJumpZSpeed
    end
  else
    JumpZSpeed = JumpZSpeed * SkillJumpZSpeed
  end
  local JumpXYSpeed = tonumber(SkillConf.move_param_6)
  local AllJumpXYSpeed = JumpXYSpeed
  local SkillJumpXSpeed = self.caster.statComponent:GetValue(StatType.SKILL_JUMP_X_SPEED)
  if self.propertyModify[6] then
    if 0 == self.modifyMode then
      AllJumpXYSpeed = AllJumpXYSpeed * SkillJumpXSpeed + self.modifyValue
    elseif 1 == self.modifyMode then
      AllJumpXYSpeed = AllJumpXYSpeed * SkillJumpXSpeed + AllJumpXYSpeed * self.modifyValue / 10000
    else
      AllJumpXYSpeed = AllJumpXYSpeed * SkillJumpXSpeed
    end
  else
    AllJumpXYSpeed = AllJumpXYSpeed * SkillJumpXSpeed
  end
  RidePet.CharacterMovement:Jump(tonumber(SkillConf.move_param_7), tonumber(SkillConf.move_param_8), JumpZSpeed, JumpXYSpeed, AllJumpXYSpeed - JumpXYSpeed)
  RidePet.BP_RidePetRoleHpComponent:ResetFalling()
  RidePet.BP_RidePetRoleHpComponent.lastMovementMode = UE.EMovementMode.MOVE_Falling
  self.caster.viewObj:OnJumped()
end

function RideAllJumpAbility:AnalyPropertyModify(SkillConf)
  local param1 = SkillConf.property_modify_speed_param_1
  local param2 = SkillConf.property_modify_speed_param_2
  local param3 = SkillConf.property_modify_speed_param_3
  self.propertyModify = {}
  local petData = self.SceneRidePet:GetPetData()
  if param1 and param1[1] and 0 ~= param1[1] and petData then
    local petLevel = petData.level
    local petSpeedEffort = petData.attribute_info.speed.effort_add or 0
    local petSpeetAllTalent = petData.attribute_info.speed.talent or 0
    local petSpeetBaseTalent = petData.attribute_info.speed.talent_add_value or 0
    local natureSpeedPercent = 1
    local petNatureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
    if petData.changed_nature_pos_attr_type == Enum.AttributeType.AT_SPEED then
      local _, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(petData)
      local addSpeedValuePercent = (petNatureConf.positive_effect_proportion + petNatureConf.positive_effect_grow * (GrowOrder - 1)) / 10000
      natureSpeedPercent = natureSpeedPercent + addSpeedValuePercent
    end
    if petData.changed_nature_neg_attr_type == Enum.AttributeType.AT_SPEED then
      local removeSpeedValuePercent = petNatureConf.negative_effect_proportion / 10000
      natureSpeedPercent = natureSpeedPercent - removeSpeedValuePercent
    end
    local petName = self.SceneRidePet.config.name or ""
    local petID = self.SceneRidePet.config.id or 0
    Log.Debug("PropertyModifySpeed skill -> PetName = " .. petName .. " -PetID = " .. petID .. " -PetLevel = " .. petLevel .. " -PetSpeedEffort = " .. petSpeedEffort .. " -PetSpeetAllTalent = " .. petSpeetAllTalent .. " -PetSpeetBaseTalent = " .. petSpeetBaseTalent .. " -natureSpeedPercent = " .. natureSpeedPercent)
    local temp = (param2[1] * (petLevel - 1) / 59 + param2[2] * petSpeedEffort / 50 + param2[3] * (petSpeetAllTalent - petSpeetBaseTalent) / 50 + param2[4] * (natureSpeedPercent - 0.9) / 0.2 + param2[5] * petSpeetBaseTalent / 10) / 10000
    local value = param2[6] * temp * temp + param2[7] * temp + param2[8]
    local modifyList = {}
    for _, v in ipairs(param1) do
      modifyList[v] = true
    end
    self.propertyModify = modifyList
    self.modifyMode = param3
    self.modifyValue = value
    Log.Debug("PropertyModifySpeed skill -> ModifyValue = " .. value)
  end
end

function RideAllJumpAbility:Interrupt()
  self:Finish()
end

function RideAllJumpAbility:Recover()
  self:Start()
end

function RideAllJumpAbility:Finish()
end

return RideAllJumpAbility

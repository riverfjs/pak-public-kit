local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_SkillBase")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RideAllBuff_Smash = Base:Extend("RideAllBuff_Smash")
local SmashStage = {Falling = 1, Landing = 2}
local LANDING_ANIM_DURATION = 0.5
local INTERACTION_DELAY = 0.3

function RideAllBuff_Smash:OnBuffBegin(Owner, SkillConf)
  Base.OnBuffBegin(self, Owner, SkillConf, false)
  self._smashStage = nil
  self._interactionTriggered = false
  self._landingTimer = 0
  self._interactionRadius = tonumber(SkillConf.move_param_1) or 500
  self._gravityRatio = tonumber(SkillConf.move_param_2) or 8
  self._oldGravityScale = tonumber(self.RidePet.CharacterMovement:GetMovementParamByName(3, "GravityScale"))
  self.owner.inputComponent:SetMoveEnable(self, false)
  self:StartCostVitality()
end

function RideAllBuff_Smash:OnStartCostVitalityFinish(StartCostSuccess)
  if not StartCostSuccess then
    self:StartFail()
    return
  end
  local isFalling = self.RideComp.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Falling
  if isFalling then
    self._smashStage = SmashStage.Falling
    self:EnterFallingStage()
  else
    self:EnterLandingStage()
  end
end

function RideAllBuff_Smash:EnterFallingStage()
  self.RidePet.BP_RidePetRoleHpComponent:IgnoreFallingDamage()
  if self._oldGravityScale and self._gravityRatio then
    self.RidePet.CharacterMovement:SetMovementParamByName(3, "GravityScale", tostring(self._oldGravityScale * self._gravityRatio))
  end
  self:OnRefreshRideallAbilityPlayerStatus(SmashStage.Falling)
end

function RideAllBuff_Smash:EnterLandingStage()
  self._smashStage = SmashStage.Landing
  self._landingTimer = 0
  self._interactionTriggered = false
  Log.Error("\230\146\173\230\148\190\232\144\189\229\156\176\229\138\168\231\148\187")
  self:OnRefreshRideallAbilityPlayerStatus(SmashStage.Landing)
end

function RideAllBuff_Smash:TriggerAreaInteraction()
  if self._interactionTriggered then
    return
  end
  self._interactionTriggered = true
  local petLocation = self.RidePet:K2_GetActorLocation()
  Log.Debug("RideAllBuff_Smash:TriggerAreaInteraction at (%s, %s, %s), radius = %s", tostring(petLocation.X), tostring(petLocation.Y), tostring(petLocation.Z), tostring(self._interactionRadius))
  Log.Error("\232\167\166\229\143\145\232\140\131\229\155\180NPC\228\186\164\228\186\146")
end

function RideAllBuff_Smash:OnBuffUpdate(deltaTime)
  if self._smashStage == SmashStage.Landing then
    self._landingTimer = self._landingTimer + deltaTime
    if not self._interactionTriggered and self._landingTimer >= INTERACTION_DELAY then
      self:TriggerAreaInteraction()
    end
    if self._landingTimer >= LANDING_ANIM_DURATION then
      self:StopActiveSKill()
    end
  end
end

function RideAllBuff_Smash:OnRidePetChangeMoveType()
  if self._smashStage == SmashStage.Falling then
    if self.RideComp.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
      self:StopActiveSKill()
      return
    end
    if self.RideComp.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_FLY or 0 == self.RideComp.RideMoveType and self.RideComp.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Falling then
      return
    end
    if self.RideComp.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_GROUND then
      self:EnterLandingStage()
      return
    end
    self:StopActiveSKill()
  elseif self._smashStage == SmashStage.Landing and self.RideComp.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
    self:StopActiveSKill()
  end
end

function RideAllBuff_Smash:HandleRePress()
  return true
end

function RideAllBuff_Smash:OnRemotePlayerBuffBegin(Owner, SkillConf)
  Base.OnRemotePlayerBuffBegin(self, Owner, SkillConf, false)
end

function RideAllBuff_Smash:OnRemotePlayEffect(stage)
  if stage == SmashStage.Landing then
  end
end

function RideAllBuff_Smash:OnPlayerStatusRefresh(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    self:OnRemotePlayEffect(customParams.ride_skill_param.skill_stage)
  end
end

function RideAllBuff_Smash:OnRemotePlayerBuffFinish(param)
  Base.OnRemotePlayerBuffFinish(self, param)
end

function RideAllBuff_Smash:OnBuffFinish(param)
  Log.Debug("RideAllBuff_Smash End!")
  if self._oldGravityScale then
    self.RidePet.CharacterMovement:SetMovementParamByName(3, "GravityScale", tostring(self._oldGravityScale))
  end
  self.owner.inputComponent:SetMoveEnable(self, true)
  Base.OnBuffFinish(self, param)
end

return RideAllBuff_Smash

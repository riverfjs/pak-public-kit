local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_SkillBase")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local RideAllMainAbilityHelper = require("NewRoco.Modules.Core.Scene.Component.Ability.Helper.RideAll.RideAllMainAbilityHelper")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local RideAllBuff_DashWithoutVitality = Base:Extend("RideAllBuff_DashWithoutVitality")
local DEFAULT_DASH_DURATION = 2.0
local DEFAULT_DASH_SPEED_BOOST = 0.5

function RideAllBuff_DashWithoutVitality:OnBuffBegin(Owner, SkillConf)
  Base.OnBuffBegin(self, Owner, SkillConf, false)
  self._dashTime = 0
  self._dashDuration = tonumber(SkillConf.move_param_1) or DEFAULT_DASH_DURATION
  self._speedBoost = tonumber(SkillConf.move_param_2) or DEFAULT_DASH_SPEED_BOOST
  self._oldMaxSpeed = nil
  self._isPlayingDashFx = false
  if self.RidePet and self.RidePet.VehicleWalkMovement then
    self.WalkComp = self.RidePet.VehicleWalkMovement
    self.moveComp = self.RidePet.CharacterMovement
    self._oldMaxSpeed = self.WalkComp.BaseMaxSpeed
    local newSpeed = self._oldMaxSpeed * (1 + self._speedBoost)
    self.WalkComp.OverrideMaxSpeed = newSpeed
  end
  self:StartOrStopDashFx(true)
  self.owner.abilityComponent:SendEvent(AbilityEvent.ON_BUFF_LOOP_BEGIN, self._abilityID, self._dashDuration)
  local cooldownTime = self.SkillConf and self.SkillConf.move_param_5
  RideAllMainAbilityHelper.StartSkillCooldown(self.owner, ProtoEnum.SceneRideAllActiveType.SRAA_DASH_WITHOUT_VITALITY, cooldownTime)
  self.NormalEnd = false
end

function RideAllBuff_DashWithoutVitality:OnRemotePlayerBuffBegin(Owner, SkillConf)
  Base.OnRemotePlayerBuffBegin(self, Owner, SkillConf)
  self._dashTime = 0
  self._dashDuration = tonumber(SkillConf.move_param_1) or DEFAULT_DASH_DURATION
  self._speedBoost = tonumber(SkillConf.move_param_2) or DEFAULT_DASH_SPEED_BOOST
  self._oldMaxSpeed = nil
  self._remote_isPlayingDashFx = false
  if self.RidePet and self.RidePet.VehicleWalkMovement then
    self.WalkComp = self.RidePet.VehicleWalkMovement
    self._oldMaxSpeed = self.WalkComp.BaseMaxSpeed
  end
  self:StartOrStopDashFx(true)
end

function RideAllBuff_DashWithoutVitality:OnRemotePlayEffect(playFx)
  if playFx then
    self:StartOrStopDashFx(true)
    self._remote_isPlayingDashFx = true
  else
    self:StartOrStopDashFx(false)
    self._remote_isPlayingDashFx = false
  end
end

function RideAllBuff_DashWithoutVitality:OnPlayerStatusRefresh(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    if customParams and customParams.ride_skill_param then
      self:OnRemotePlayEffect(1 == customParams.ride_skill_param.skill_stage)
    end
  end
end

function RideAllBuff_DashWithoutVitality:OnBuffUpdate(deltaTime)
  self._dashTime = self._dashTime + deltaTime
  if self._dashTime >= self._dashDuration then
    self:StopActiveSKill()
    return
  end
end

function RideAllBuff_DashWithoutVitality:OnBuffFinish()
  if self.WalkComp then
    self.WalkComp.OverrideMaxSpeed = 0
  end
  self:StartOrStopDashFx(false)
  self.owner.abilityComponent:SendEvent(AbilityEvent.ON_BUFF_LOOP_END, self._abilityID)
  Base.OnBuffFinish(self)
end

function RideAllBuff_DashWithoutVitality:StopActiveSKill()
  self.NormalEnd = true
  Base.StopActiveSKill(self)
end

function RideAllBuff_DashWithoutVitality:OnRemotePlayerBuffUpdate(deltaTime)
  if not UE.UObject.IsValid(self.RidePet) or not self.RidePet.CharacterMovement then
    return
  end
  self._dashTime = self._dashTime + deltaTime
  local curSpeed = self.RidePet.CharacterMovement.Velocity:Size()
  local shouldPlayFx = curSpeed > (self._oldMaxSpeed or 0)
  if self._remote_isPlayingDashFx ~= shouldPlayFx then
    self:StartOrStopDashFx(shouldPlayFx)
    self._remote_isPlayingDashFx = shouldPlayFx
  end
end

function RideAllBuff_DashWithoutVitality:OnRemotePlayerBuffFinish(param)
  Base.OnRemotePlayerBuffFinish(self, param)
  self:StartOrStopDashFx(false)
end

function RideAllBuff_DashWithoutVitality:StartOrStopDashFx(bStart)
  if not UE.UObject.IsValid(self.RidePet) then
    if not bStart and self.DashFxs then
      for i, fx in ipairs(self.DashFxs:ToTable()) do
        fx:K2_DestroyActor()
      end
    end
    return
  end
  local Comp = self.RidePet.RocoMoveFx
  if bStart then
    if not self.DashFxs then
      self.DashFxs = UE4.TArray(UE4.AActor)
      Comp:LuaPlayMoveFxByStatus("Ground_Spurt", self.DashFxs)
    end
  elseif self.DashFxs then
    for i, fx in ipairs(self.DashFxs:ToTable()) do
      Comp:LuaStopMoveFx(fx, 0.5)
    end
    self.DashFxs:Clear()
    self.DashFxs = nil
  end
end

return RideAllBuff_DashWithoutVitality

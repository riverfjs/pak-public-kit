local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_SkillBase")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RidePetEvent = require("NewRoco.Modules.Core.Scene.Component.RidePet.RidePetEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local VitalityUtil = require("NewRoco.Modules.Core.Scene.Component.Vitality.VitalityUtil")
local CameraAdditiveParamType = require("NewRoco.Modules.Core.Character.WorldCamera.CameraAdditiveParamType")
local RideAllBuff_PowerDash = Base:Extend("RideAllBuff_PowerDash")
local PowerDashStatus = {
  None = 0,
  PreCharging = 1,
  InCharging = 2,
  MaxCharging = 3,
  InDashing = 4
}
local PowerDashActionSyncBanList = {
  [Enum.ActionType.ACT_SHAKETREE] = true
}

function RideAllBuff_PowerDash:OnBuffBegin(Owner, SkillConf)
  Base.OnBuffBegin(self, Owner, SkillConf, false)
  self.LastHitActor = false
  self._costVitality = 0
  self.vitalityComp = self.owner.vitalityComponent
  self._status = 0
  if not self.owner.vitalityComponent:IsVitalityEnough(SkillConf.vitality_cost.min_start) then
    self:StartFail()
    return
  end
  self:AnalyPropertyModify(SkillConf)
  self._status = PowerDashStatus.PreCharging
  self.MoveComp = self.RidePet.CharacterMovement
  self.WalkComp = self.RidePet.VehicleWalkMovement
  self.WalkComp.bIsPowerDashing = true
  self._curChargingTime = 0
  self._curDashingTime = 0
  self._chargePrecent = 1
  self._baseSpeedMapPercent = 1
  self._speedAdjust = 1
  self._dashForwardDir = FVectorZero
  self._baseSpeedMappingCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_4)
  self._chargePercentCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_2)
  self._dashSpeedCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_3)
  local _min
  _min, self._maxChargingTime = self._chargePercentCurve:GetTimeRange()
  _min, self._maxDashingTime = self._dashSpeedCurve:GetTimeRange()
  self._holdTime = tonumber(SkillConf.move_param_5) or 0.2
  self._maxChargingSpeedPercent = tonumber(SkillConf.move_param_1)
  self._maxChargingSpeed = self._maxChargingSpeedPercent * self.WalkComp.BaseMaxSpeed
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_AIM_JOYSTICK_RELEASED, self.OnAimJoystickReleased)
  self.owner:AddEventListener(self, MainUIModuleEvent.PCCancelChargeBtnClicked, self.OnCancel)
  self.RidePet:AddEventListener(self, RidePetEvent.HANDLE_IMPACT, self.HandleImpact)
  _G.NRCEventCenter:RegisterEvent("RideAllBuff_PowerDash", self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  Log.Debug("PowerDash Begin!")
  self.NormalEnd = false
  self.bMaxPower = false
end

function RideAllBuff_PowerDash:OnRemotePlayerBuffBegin(Owner, SkillConf)
  Base.OnRemotePlayerBuffBegin(self, Owner, SkillConf, false)
end

function RideAllBuff_PowerDash:OnRemotePlayEffect(stage)
  if stage == PowerDashStatus.InCharging then
    self:StartOrStopChargingFx(true)
    _G.NRCAudioManager:PlaySound3DWithActorAuto(3530065, self.owner.viewObj, "RideAllBuff_PowerDash")
  elseif stage == PowerDashStatus.InDashing then
    self:StartOrStopChargingFx(false)
    self:StartOrStopDashFx(true)
    _G.NRCAudioManager:PlaySound3DWithActorAuto(3530067, self.owner.viewObj, "RideAllBuff_PowerDash")
  elseif stage == PowerDashStatus.MaxCharging then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(3530066, self.owner.viewObj, "RideAllBuff_PowerDash")
  end
end

function RideAllBuff_PowerDash:OnRemotePlayerBuffFinish(param)
  Base.OnRemotePlayerBuffFinish(self, param)
  self:StartOrStopChargingFx(false)
  self:StartOrStopDashFx(false)
end

function RideAllBuff_PowerDash:OnPlayerStatusRefresh(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    self:OnRemotePlayEffect(customParams.ride_skill_param.skill_stage)
  end
end

function RideAllBuff_PowerDash:OnBuffUpdate(deltaTime)
  if self._status <= 0 then
    return
  end
  local MaxChargTime = self._maxChargingTime + self._holdTime
  if self._status < PowerDashStatus.InDashing and not self.bMaxPower then
    if not self.bMaxPower then
      local BeforeCost = self.vitalityComp:GetCurVitality()
      local Cost = self.SkillConf.vitality_cost.start_cost * deltaTime / MaxChargTime
      local CostSuccess = self.vitalityComp:CostVitality(Cost, nil, false, VitalityUtil.VitalityCostType.Duration)
      if CostSuccess then
        local AfterCost = self.vitalityComp:GetCurVitality()
        self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_COST, BeforeCost - AfterCost)
        self._costVitality = self._costVitality + BeforeCost - AfterCost
        self._curChargingTime = self._curChargingTime + deltaTime
        if MaxChargTime <= self._curChargingTime then
          self.bMaxPower = true
          self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_FULL)
          self._curChargingTime = MaxChargTime
          if self.owner.isLocal then
            self:OnRefreshRideallAbilityPlayerStatus(PowerDashStatus.MaxCharging)
            _G.NRCAudioManager:PlaySound2DAuto(3530066, "RideAllBuff_PowerDash")
          else
          end
        end
      end
    end
    if self._status == PowerDashStatus.PreCharging and self._curChargingTime >= self._holdTime then
      self:StartCharging()
      return
    end
  end
  if self._status == PowerDashStatus.InCharging then
    local Rotation = self.RidePet:K2_GetActorRotation()
    Rotation.Yaw = self.owner:GetUEController().PlayerCameraManager:GetCameraRotation().Yaw
    self.RidePet:K2_SetActorRotation(Rotation, false)
  end
  if self._status == PowerDashStatus.InDashing then
    self._curDashingTime = math.min(self._curDashingTime + deltaTime, self._maxDashingTime)
    if self._curDashingTime == self._maxDashingTime then
      self:StopActiveSKill()
      return
    end
    self:UpdateDashing()
  end
end

function RideAllBuff_PowerDash:StartCharging()
  self._status = PowerDashStatus.InCharging
  self.owner.movementComponent:SetIsMoving(true, "PowerDash")
  self.WalkComp.OverrideMaxSpeed = self._maxChargingSpeed
  self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_BEGIN)
  self:StartOrStopChargingFx(true)
  self.WalkComp.bOrientToVelocity = false
  local Rotation = self.RidePet:K2_GetActorRotation()
  Rotation.Yaw = self.owner:GetUEController().PlayerCameraManager:GetCameraRotation().Yaw
  self.RidePet:K2_SetActorRotation(Rotation, false)
  if not UE4Helper.IsPCMode() then
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, true)
  else
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, true)
  end
  if self.owner.isLocal then
    _G.NRCAudioManager:PlaySound2DAuto(3530065, "RideAllBuff_PowerDash")
  else
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.PowerDashChargingStart, self._maxChargingTime)
  self:OnRefreshRideallAbilityPlayerStatus(PowerDashStatus.InCharging)
end

function RideAllBuff_PowerDash:StartDashing()
  local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.PowerDashChargingEnd)
  self._curChargingTime = self._curChargingTime - self._holdTime
  self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_END, true)
  if 0 ~= self._maxChargingSpeed then
    local lastVelocity = self.MoveComp.Velocity
    self._dashForwardDir = self.RidePet:GetActorForwardVector()
    local mapTime = UE.UKismetMathLibrary.Dot_VectorVector(lastVelocity, self._dashForwardDir) / self._maxChargingSpeed
    self._baseSpeedMapPercent = self._baseSpeedMappingCurve:GetFloatValue(mapTime)
  else
    self._baseSpeedMapPercent = 1
  end
  self.WalkComp.OverrideMaxSpeed = 0
  self._chargePrecent = self._chargePercentCurve:GetFloatValue(self._curChargingTime)
  self._speedAdjust = self._baseSpeedMapPercent * self._chargePrecent
  self.WalkComp = self.RidePet.VehicleWalkMovement
  self._oldAccelerateCurve = self.WalkComp.AccelerateCurve
  self._oldDeAccelerateCurve = self.WalkComp.DeAccelerateCurve
  self._oldBrakingFriction = self.WalkComp.BrakingFriction
  self._oldBrakingDecelerationWalking = self.WalkComp.BrakingDecelerationWalking
  self._oldGroundFriction = self.WalkComp.GroundFriction
  self._oldMaxSpeedDeacc = self.WalkComp.MaxSpeedDeAcceleration
  self.WalkComp.AccelerateCurve = nil
  self.WalkComp.DeAccelerateCurve = nil
  self.WalkComp.BrakingFriction = 0
  self.WalkComp.BrakingDecelerationWalking = 0
  self.WalkComp.GroundFriction = 0
  self.WalkComp.MaxSpeedDeAcceleration = 99999
  self.WalkComp.LastAcceleration = self._dashForwardDir
  self.owner.abilityComponent:SendEvent(AbilityEvent.ON_BUFF_LOOP_BEGIN, self._abilityID, self._maxDashingTime)
  self._status = PowerDashStatus.InDashing
  self:StartOrStopChargingFx(false)
  self:StartOrStopDashFx(true)
  self:OnRefreshRideallAbilityPlayerStatus(PowerDashStatus.InDashing)
  if self.owner.isLocal then
    _G.NRCAudioManager:PlaySound2DAuto(3530067, "RideAllBuff_PowerDash")
  else
  end
end

function RideAllBuff_PowerDash:UpdateDashing()
  local DashSpeed = self._dashSpeedCurve:GetFloatValue(self._curDashingTime)
  if self.propertyModify[3] then
    if 0 == self.modifyMode then
      DashSpeed = DashSpeed * self._speedAdjust * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED) + self.modifyValue
    elseif 1 == self.modifyMode then
      DashSpeed = DashSpeed * self._speedAdjust * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED) + DashSpeed * self.modifyValue / 10000
    else
      DashSpeed = DashSpeed * self._speedAdjust * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED)
    end
  else
    DashSpeed = DashSpeed * self._speedAdjust * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED)
  end
  local DashVelocity = UE.UKismetMathLibrary.Multiply_VectorFloat(self._dashForwardDir, DashSpeed)
  self.WalkComp.OverrideMaxSpeed = DashSpeed
  self.MoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, DashVelocity)
end

function RideAllBuff_PowerDash:OnMainAbilityReleased()
  if self._status == PowerDashStatus.PreCharging then
    self:StopActiveSKill()
  elseif self._status == PowerDashStatus.InCharging and UE4Helper.IsPCMode() then
    self:StartDashing()
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
  end
end

function RideAllBuff_PowerDash:HandleImpact(Hit)
  local npcActor = Hit and Hit.Actor
  local sceneNpc = npcActor and npcActor.sceneCharacter
  if not sceneNpc then
    return
  end
  if self._status ~= PowerDashStatus.InDashing then
    return
  end
  if self.LastHitActor == sceneNpc then
    return
  end
  self.LastHitActor = sceneNpc
  if not sceneNpc.InteractionComponent then
    return
  end
  local Option = sceneNpc.InteractionComponent:GetPowerDashOption()
  if Option then
    local PowerDashActionType = Option.config.action.action_type
    if not PowerDashActionSyncBanList[PowerDashActionType] then
      Option:SendPowerDashInfoSync(self.owner, self.RidePet)
    end
    Option:SendPowerDashReq(self, self.RidePet)
  end
  if not npcActor:ActorHasTag("IgnoreDash") then
    self.owner:SendEvent(PlayerModuleEvent.ON_ADDITIVE_CAMERA_PARAM, CameraAdditiveParamType.InteractionBlock)
    self:StopActiveSKill()
  end
end

function RideAllBuff_PowerDash:OnAimJoystickReleased(Success)
  if Success then
    self:StartDashing()
  else
    self:OnCancel()
  end
end

function RideAllBuff_PowerDash:OnCancel()
  self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_END, false)
  self:StopActiveSKill()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
  self._status = 0
end

function RideAllBuff_PowerDash:OnEnterBackground()
  if self._status ~= PowerDashStatus.None then
    Log.Debug("PowerDash: \232\191\155\229\133\165\229\144\142\229\143\176\239\188\140\229\188\186\229\136\182\231\187\147\230\157\159\229\134\178\229\136\186\230\138\128\232\131\189")
    self:StopActiveSKill()
  end
end

function RideAllBuff_PowerDash:OnBuffFinish(param)
  Log.Debug("PowerDash End!")
  Base.OnBuffFinish(self, param)
  self.owner.movementComponent:SetIsMoving(false, "PowerDash")
  self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_END, false)
  if UE4Helper.IsPCMode() then
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
  end
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_AIM_JOYSTICK_RELEASED, self.OnAimJoystickReleased)
  self.RidePet:RemoveEventListener(self, RidePetEvent.HANDLE_IMPACT, self.HandleImpact)
  self.owner:RemoveEventListener(self, MainUIModuleEvent.PCCancelChargeBtnClicked, self.OnCancel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  self.LastHitActor = false
  if self._status == PowerDashStatus.InDashing then
    self.WalkComp.AccelerateCurve = self._oldAccelerateCurve
    self.WalkComp.DeAccelerateCurve = self._oldDeAccelerateCurve
    self.WalkComp.BrakingFriction = self._oldBrakingFriction
    self.WalkComp.BrakingDecelerationWalking = self._oldBrakingDecelerationWalking
    self.WalkComp.GroundFriction = self._oldGroundFriction
    self.WalkComp.MaxSpeedDeAcceleration = self._oldMaxSpeedDeacc
    self.MoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, FVectorZero)
  elseif self._costVitality > 0 then
    self.vitalityComp:RecoverVitalityByValue(self._costVitalit)
  end
  if self.WalkComp then
    self.WalkComp.bOrientToVelocity = true
    self.WalkComp.OverrideMaxSpeed = 0
    self.WalkComp.bIsPowerDashing = false
  end
  local stopFxImmediate = not self.NormalEnd
  self:StartOrStopChargingFx(false)
  self:StartOrStopDashFx(false)
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.PowerDashChargingEnd)
  self.owner.abilityComponent:SendEvent(AbilityEvent.ON_BUFF_LOOP_END, self._abilityID)
  self._status = PowerDashStatus.None
end

function RideAllBuff_PowerDash:InitTestCurveInfo()
  self._baseSpeedMappingCurve = {
    GetFloatValue = function(self, time)
      return 1 + time * 0.2
    end
  }
  self._chargePercentCurve = {
    GetTimeRange = function(self)
      return 0, 1
    end,
    GetFloatValue = function(self, time)
      return 0.25 + 0.75 * time
    end
  }
  self._dashSpeedCurve = {
    GetTimeRange = function(self)
      return 0, 2
    end,
    GetFloatValue = function(self, time)
      if time < 0.3 then
        return 200 + time * 6000
      end
      if time >= 0.3 and time < 1.5 then
        return 2000
      end
      if time >= 1.5 and time <= 2 then
        return 4500 - time * 1000
      end
    end
  }
end

function RideAllBuff_PowerDash:StopActiveSKill()
  self.NormalEnd = true
  Base.StopActiveSKill(self)
end

function RideAllBuff_PowerDash:StartOrStopChargingFx(bStart)
  if not UE.UObject.IsValid(self.RidePet) then
    Log.Warning("RideAllBuff_PowerDash:StartOrStopChargingFx No RidePet")
    if not bStart and self.ChargingFx then
      for i, fx in ipairs(self.ChargingFx:ToTable()) do
        fx:K2_DestroyActor()
      end
    end
    return
  end
  local Comp = self.RidePet.RocoMoveFx
  if bStart then
    if not self.ChargingFx then
      self.ChargingFx = UE4.TArray(UE4.AActor)
      Comp:LuaPlayMoveFxByStatus("Ground_Stamina", self.ChargingFx)
    end
  elseif self.ChargingFx then
    for i, fx in ipairs(self.ChargingFx:ToTable()) do
      Comp:LuaStopMoveFx(fx, 0.5)
    end
    self.ChargingFx:Clear()
    self.ChargingFx = nil
  end
end

function RideAllBuff_PowerDash:StartOrStopDashFx(bStart)
  if not UE.UObject.IsValid(self.RidePet) then
    Log.Warning("RideAllBuff_PowerDash:StartOrStopDashFx No RidePet")
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

return RideAllBuff_PowerDash

local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_SkillBase")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local RideAllMainAbilityHelper = require("NewRoco.Modules.Core.Scene.Component.Ability.Helper.RideAll.RideAllMainAbilityHelper")
local RideAllBuff_DashForward = Base:Extend("RideAllBuff_DashForward")
local EAGLE_DASH_ANIM_PATH = "AnimSequence'/Game/ArtRes/Effects/G6Skill/SceneEffect/Activities/G6_Fanying_chongci.G6_Fanying_chongci'"
local EAGLE_DASH_SPEED_CURVE_PATH = "/Game/NewRoco/Modules/Core/Character/Rides/RideAll/RideCurve/PowerDash/powerdash_speed_curve_3.powerdash_speed_curve_3"
local BLEND_IN_TIME = 0.1
local BLEND_OUT_TIME = 0.1
local PLAY_RATE = 1.0
local LOOP_COUNT = 1
local SLOT_NAME = "DefaultSlot"
local CANCEL_THRESHOLD = 0.5

function RideAllBuff_DashForward:OnBuffBegin(Owner, SkillConf)
  Base.OnBuffBegin(self, Owner, SkillConf, false)
  self.dashForwardAnimPath = SkillConf.move_param_1 or EAGLE_DASH_ANIM_PATH
  self.dashForwardSpeedCurvePath = SkillConf.move_param_2 or EAGLE_DASH_SPEED_CURVE_PATH
  self._playingMontage = nilride_basic_move
  self._dashDuration = 0
  self._isPlayingAnim = false
  self.NormalEnd = false
  self.ResReq = nil
  self._curDashingTime = 0
  self._dashForwardDir = FVectorZero
  self._canCancel = false
  self.MoveComp = self.RidePet.CharacterMovement
  self.WalkComp = self.RidePet.VehicleWalkMovement
  local cooldownTime = SkillConf.move_param_5
  RideAllMainAbilityHelper.StartSkillCooldown(self.owner, ProtoEnum.SceneRideAllActiveType.SRAA_DASH_DASHFORWARD, cooldownTime)
  local AnimInstance = self:GetAnimInstance()
  if not AnimInstance then
    Log.Warning("RideAllBuff_DashForward: AnimInstance is nil, stopping skill")
    self:StartFail()
    return
  end
  self.ResReq = _G.NRCResourceManager:LoadResAsync(self, self.dashForwardAnimPath, self.owner.isLocal and _G.PriorityEnum.Local_Player_Logic or _G.PriorityEnum.Other_Player_Logic, 10, self.OnAnimLoadSuccess, self.OnAnimLoadFailed)
  self._dashSpeedCurve = _G.PlayerResourceManager:GetStaticResource(self.dashForwardSpeedCurvePath)
  if not self._dashSpeedCurve then
    self._dashSpeedCurve = LoadObject(self.dashForwardSpeedCurvePath)
    Log.Warning("RideAllBuff_DashForward: Speed curve is nil, using default speed")
  end
  local minTime
  minTime, self._maxDashingTime = self._dashSpeedCurve:GetTimeRange()
end

function RideAllBuff_DashForward:GetAnimInstance()
  if not self.RidePet or not UE.UObject.IsValid(self.RidePet) then
    return nil
  end
  if not self.RidePet.Mesh then
    return nil
  end
  return self.RidePet.Mesh:GetAnimInstance()
end

function RideAllBuff_DashForward:OnAnimLoadSuccess(req, Anim)
  if not Anim or not UE.UObject.IsValid(Anim) then
    self:StartFail()
    return
  end
  local AnimInstance = self:GetAnimInstance()
  if not AnimInstance or not UE.UObject.IsValid(AnimInstance) then
    self:StartFail()
    return
  end
  self._dashDuration = Anim:GetPlayLength() / PLAY_RATE
  AnimInstance:SetRootMotionMode(UE.ERootMotionMode.RootMotionFromNothing)
  self._playingMontage = AnimInstance:PlaySlotAnimationAsDynamicMontage(Anim, SLOT_NAME, BLEND_IN_TIME, BLEND_OUT_TIME, PLAY_RATE, LOOP_COUNT, -1, 0)
  if self._playingMontage then
    self._isPlayingAnim = true
    self._dashForwardDir = self.RidePet:GetActorForwardVector()
    self:SetupMontageEndCallback(AnimInstance)
    self.owner.inputComponent:SetMoveEnable(self, false)
    self:OnRefreshRideallAbilityPlayerStatus(1)
  else
    self:StartFail()
  end
end

function RideAllBuff_DashForward:OnAnimLoadFailed()
  self:StartFail()
end

function RideAllBuff_DashForward:SetupMontageEndCallback(AnimInstance)
  local This = self
  
  function self._onMontageEnded(_, montage, bInterrupted)
    if montage == This._playingMontage then
      This:OnAnimationFinished(bInterrupted)
    end
  end
  
  AnimInstance.OnMontageEnded:Add(self.RidePet, self._onMontageEnded)
end

function RideAllBuff_DashForward:CleanupMontageEndCallback()
  local AnimInstance = self:GetAnimInstance()
  if AnimInstance and UE.UObject.IsValid(AnimInstance) and self._onMontageEnded then
    AnimInstance.OnMontageEnded:Remove(self.RidePet, self._onMontageEnded)
  end
  self._onMontageEnded = nil
end

function RideAllBuff_DashForward:OnAnimationFinished(bInterrupted)
  if bInterrupted and self._isPlayingAnim and self._playingMontage then
    local AnimInstance = self:GetAnimInstance()
    if AnimInstance and UE.UObject.IsValid(AnimInstance) then
      AnimInstance:Montage_Stop(BLEND_OUT_TIME, self._playingMontage)
    end
  end
  self._isPlayingAnim = false
  if not bInterrupted then
    self.NormalEnd = true
  end
  self:StopActiveSKill()
end

function RideAllBuff_DashForward:UpdateDashing(deltaTime)
  if not self.WalkComp or not UE.UObject.IsValid(self.WalkComp) then
    return
  end
  if not self.MoveComp or not UE.UObject.IsValid(self.MoveComp) then
    return
  end
  if not self._dashSpeedCurve then
    return
  end
  self._curDashingTime = math.min(self._curDashingTime + deltaTime, self._maxDashingTime)
  local DashSpeed = self._dashSpeedCurve:GetFloatValue(self._curDashingTime)
  if self.propertyModify and self.propertyModify[3] then
    if 0 == self.modifyMode then
      DashSpeed = DashSpeed * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED) + self.modifyValue
    elseif 1 == self.modifyMode then
      DashSpeed = DashSpeed * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED) + DashSpeed * self.modifyValue / 10000
    else
      DashSpeed = DashSpeed * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED)
    end
  else
    DashSpeed = DashSpeed * self.owner.statComponent:GetValue(StatType.SKILL_RUN_SPEED)
  end
  local DashVelocity = UE.UKismetMathLibrary.Multiply_VectorFloat(self._dashForwardDir, DashSpeed)
  self.WalkComp.OverrideMaxSpeed = DashSpeed
  self.MoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, DashVelocity)
end

function RideAllBuff_DashForward:OnBuffUpdate(deltaTime)
  if self._isPlayingAnim then
    self:UpdateDashing(deltaTime)
    if not self._canCancel and self._dashDuration > 0 then
      local progress = self._curDashingTime / self._dashDuration
      if progress >= CANCEL_THRESHOLD then
        self._canCancel = true
        self.owner.inputComponent:SetMoveEnable(self, true)
      end
    end
    if self._canCancel and self:HasInput() then
      self:OnAnimationFinished(true)
    end
  end
end

function RideAllBuff_DashForward:OnBuffFinish(param)
  self:CleanupMontageEndCallback()
  local AnimInstance = self:GetAnimInstance()
  if AnimInstance and UE.UObject.IsValid(AnimInstance) then
    AnimInstance:SetRootMotionMode(UE.ERootMotionMode.RootMotionFromNothing)
    if self._playingMontage and self._isPlayingAnim then
      AnimInstance:Montage_Stop(BLEND_OUT_TIME, self._playingMontage)
    end
  end
  if self.WalkComp and UE.UObject.IsValid(self.WalkComp) then
    self.WalkComp.OverrideMaxSpeed = 0
  end
  if self.MoveComp and UE.UObject.IsValid(self.MoveComp) then
    self.MoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, FVectorZero)
  end
  if self.ResReq then
    _G.NRCResourceManager:UnLoadRes(self.ResReq)
    self.ResReq = nil
  end
  self.owner.inputComponent:SetMoveEnable(self, true)
  self:OnRefreshRideallAbilityPlayerStatus(0)
  self._playingMontage = nil
  self._dashSpeedCurve = nil
  self._curDashingTime = 0
  self._dashForwardDir = nil
  self._canCancel = false
  Base.OnBuffFinish(self, param)
end

function RideAllBuff_DashForward:StopActiveSKill()
  Base.StopActiveSKill(self)
end

function RideAllBuff_DashForward:OnRemotePlayerBuffBegin(Owner, SkillConf)
  Base.OnRemotePlayerBuffBegin(self, Owner, SkillConf)
  self.dashForwardAnimPath = SkillConf.move_param_1 or EAGLE_DASH_ANIM_PATH
  self.dashForwardSpeedCurvePath = SkillConf.move_param_2 or EAGLE_DASH_SPEED_CURVE_PATH
  self._remote_isPlayingAnim = false
  self._remote_animSequence = nil
  self._playingMontage = nil
  self._remote_ResReq = nil
  self._remote_curDashingTime = 0
  self._remote_dashForwardDir = FVectorZero
  self.MoveComp = self.RidePet.CharacterMovement
  self.WalkComp = self.RidePet.VehicleWalkMovement
  self._remote_ResReq = _G.NRCResourceManager:LoadResAsync(self, self.dashForwardAnimPath, _G.PriorityEnum.Other_Player_Logic, 10, self.OnRemoteAnimLoadSuccess, self.OnRemoteAnimLoadFailed)
end

function RideAllBuff_DashForward:OnRemoteAnimLoadSuccess(req, Anim)
  self._remote_animSequence = Anim
  local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
  if customParams and customParams.ride_skill_param and 1 == customParams.ride_skill_param.skill_stage then
    self:OnRemotePlayAnimation(true)
  end
end

function RideAllBuff_DashForward:OnRemoteAnimLoadFailed()
end

function RideAllBuff_DashForward:OnRemotePlayAnimation(bPlay)
  local AnimInstance = self:GetAnimInstance()
  if not AnimInstance or not UE.UObject.IsValid(AnimInstance) then
    return
  end
  if bPlay then
    if not self._remote_isPlayingAnim and self._remote_animSequence then
      AnimInstance:SetRootMotionMode(UE.ERootMotionMode.RootMotionFromNothing)
      self._remote_dashForwardDir = self.RidePet:GetActorForwardVector()
      self._remote_curDashingTime = 0
      self._playingMontage = AnimInstance:PlaySlotAnimationAsDynamicMontage(self._remote_animSequence, SLOT_NAME, BLEND_IN_TIME, BLEND_OUT_TIME, PLAY_RATE, LOOP_COUNT, -1, 0)
      self._remote_isPlayingAnim = true
    end
  elseif self._remote_isPlayingAnim then
    AnimInstance:SetRootMotionMode(UE.ERootMotionMode.RootMotionFromNothing)
    if self._playingMontage then
      AnimInstance:Montage_Stop(BLEND_OUT_TIME, self._playingMontage)
    end
    self._remote_isPlayingAnim = false
  end
end

function RideAllBuff_DashForward:OnPlayerStatusRefresh(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    if customParams and customParams.ride_skill_param then
      local skillStage = customParams.ride_skill_param.skill_stage
      self:OnRemotePlayAnimation(1 == skillStage)
    end
  end
end

function RideAllBuff_DashForward:OnRemotePlayerBuffUpdate(deltaTime)
  if self._remote_isPlayingAnim then
    if not self._remote_dashSpeedCurve then
      self._remote_dashSpeedCurve = _G.PlayerResourceManager:GetStaticResource(self.dashForwardSpeedCurvePath)
      if self._remote_dashSpeedCurve then
        local minTime
        minTime, self._remote_maxDashingTime = self._remote_dashSpeedCurve:GetTimeRange()
      end
    end
    if self._remote_dashSpeedCurve then
      self:UpdateRemoteDashing(deltaTime)
    end
  end
end

function RideAllBuff_DashForward:UpdateRemoteDashing(deltaTime)
  if not self.WalkComp or not UE.UObject.IsValid(self.WalkComp) then
    return
  end
  if not self.MoveComp or not UE.UObject.IsValid(self.MoveComp) then
    return
  end
  self._remote_curDashingTime = (self._remote_curDashingTime or 0) + deltaTime
  self._remote_curDashingTime = math.min(self._remote_curDashingTime, self._remote_maxDashingTime)
  local DashSpeed = self._remote_dashSpeedCurve:GetFloatValue(self._remote_curDashingTime)
  local DashVelocity = UE.UKismetMathLibrary.Multiply_VectorFloat(self._remote_dashForwardDir or self.RidePet:GetActorForwardVector(), DashSpeed)
  self.WalkComp.OverrideMaxSpeed = DashSpeed
  self.MoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, DashVelocity)
end

function RideAllBuff_DashForward:OnRemotePlayerBuffFinish(param)
  Base.OnRemotePlayerBuffFinish(self, param)
  self:OnRemotePlayAnimation(false)
  if self.WalkComp and UE.UObject.IsValid(self.WalkComp) then
    self.WalkComp.OverrideMaxSpeed = 0
  end
  if self.MoveComp and UE.UObject.IsValid(self.MoveComp) then
    self.MoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, FVectorZero)
  end
  if self._remote_ResReq then
    _G.NRCResourceManager:UnLoadRes(self._remote_ResReq)
    self._remote_ResReq = nil
  end
  self._remote_animSequence = nil
  self._playingMontage = nil
  self._remote_dashSpeedCurve = nil
  self._remote_curDashingTime = 0
  self._remote_dashForwardDir = nil
end

return RideAllBuff_DashForward

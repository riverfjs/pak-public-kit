local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_SkillBase")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local KeepBalanceStage = {
  None = 0,
  Balance = 1,
  Fail = 2,
  Success = 3
}
local RideAllBuff_KeepBalance = Base:Extend("RideAllBuff_KeepBalance")

function RideAllBuff_KeepBalance:OnBuffBegin(Owner, SkillConf, needStartCost)
  Base.OnBuffBegin(self, Owner, SkillConf)
  Log.Debug("Keep Balance Start!")
  self._keepBalanceComp = self.RidePet.CharacterKeepBalanceMovement
  self._keepTime = 0
  self._syncTime = 0
  self._stage = KeepBalanceStage.Balance
  self._lastIsFalling = self._keepBalanceComp.bIsFalling
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_VITALITY_OVER, self.OnVitalityOver)
  _G.NRCEventCenter:RegisterEvent("RideAllBuff_KeepBalance", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  self.RidePet.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, UE.ERocoCustomMovementMode.MOVE_KeepBalance)
  local PetID = self.SceneRidePet.config.id
  local SocketConf = DataConfigManager:GetRideSocket(PetID, true)
  self._sourceSocketName = self.RideComp.RideSocketName
  if SocketConf then
    if self.owner.viewObj.Male then
      self.RideComp:ChangeSocketWhileRiding(SocketConf.circus_socket_pc1)
    else
      self.RideComp:ChangeSocketWhileRiding(SocketConf.circus_socket_pc2)
    end
  end
  self._keepBalanceComp.AccelerationCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_1)
  self._keepBalanceComp.DecelerationCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_2)
  self.MaxBalanceSpeed = tonumber(SkillConf.move_param_3)
  self._keepBalanceComp.MaxBalanceSpeed = self.MaxBalanceSpeed
  self._keepBalanceComp.AngularSpeed_VelocityCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_4)
  self._keepBalanceComp.GravityCoefficient = tonumber(SkillConf.move_param_5)
  self._keepBalanceComp.FrictionCoefficient_VelocityCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_6)
  self._keepBalanceComp.CentrifugalForceCoefficient = tonumber(SkillConf.move_param_7)
  self._keepBalanceComp.TiltForceCoefficient = tonumber(SkillConf.move_param_8)
  self._keepBalanceComp.RecoverCoefficient = tonumber(SkillConf.move_param_9)
  self._keepBalanceComp.TiltAngleThreshold = tonumber(SkillConf.move_param_10)
  self._keepBalanceComp.MaxBalanceAngle = tonumber(SkillConf.move_param_11)
  self._successfulTime = self._keepBalanceComp.SuccessfulTime
  self:SyncBalanceAngle(true)
  local uePlayer = self.owner.viewObj
  if UE4.UObject.IsValid(uePlayer) then
    local AnimInstance = uePlayer.Mesh and uePlayer.Mesh:GetAnimInstance()
    if AnimInstance then
      self.RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
      self.RideAllAnimInstance.bInKeepBalance = true
    end
  end
  self:SetAnimationSuccess(false)
  self:StartOrStopBalanceFx(true)
  self:StartOrStopSound(true)
end

function RideAllBuff_KeepBalance:OnBuffUpdate(deltaTime)
  if self._stage == KeepBalanceStage.None then
    return
  end
  self._syncTime = self._syncTime + deltaTime
  if self._syncTime >= 0.2 then
    self._syncTime = self._syncTime - 0.2
    self:SyncBalanceAngle()
  end
  if self._stage == KeepBalanceStage.Fail then
    return
  end
  if self._keepBalanceComp.CurrentGroundTiltAngle >= self._keepBalanceComp.MaxBalanceAngle then
    self:OnBalanceFail()
    return
  end
  self:StartOrStopBalanceWarning(self._keepBalanceComp.CurrentGroundTiltAngle >= self._keepBalanceComp.DangerousAngle)
  local isFallingNow = self._keepBalanceComp.bIsFalling
  if isFallingNow and not self._lastIsFalling then
    self.RidePet.BP_RidePetRoleHpComponent:ResetFalling()
  end
  if not isFallingNow and self._lastIsFalling then
    self.RidePet.BP_RidePetRoleHpComponent:EndFalling()
  end
  self._lastIsFalling = isFallingNow
  if self._stage == KeepBalanceStage.Success then
    return
  end
  if self._keepBalanceComp:IsExceedingMaxSpeed(self.MaxBalanceSpeed * 0.98) then
    self._keepTime = self._keepTime + deltaTime
    if self._keepTime >= self._successfulTime then
      self:OnBalanceSuccess()
    end
  else
    self._keepTime = 0
  end
end

function RideAllBuff_KeepBalance:OnBuffFinish(param)
  Log.Debug("Keep Balance Finish!")
  self:SetAnimationSuccess(false)
  self:StartOrStopBalanceFx(false)
  self:StartOrStopSound(false)
  self:StartOrStopBalanceWarning(false)
  self.RideAllAnimInstance.bInKeepBalance = false
  self.RidePet.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
  self.RideComp:ChangeSocketWhileRiding(self._sourceSocketName)
  self.RideComp:RefreshPose()
  self.RideComp:RefreshPose()
  self.RideComp:RefreshPose()
  self.RideComp:RefreshPose()
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_VITALITY_OVER, self.OnVitalityOver)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  Base.OnBuffFinish(self, param)
end

function RideAllBuff_KeepBalance:OnVitalityOver()
  Log.Debug("Keep Balance: Vitality Over!")
  self:OnBalanceFail()
end

function RideAllBuff_KeepBalance:OnRidePetChangeMoveType()
  if self.RideComp.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
    self:StopActiveSKill()
  end
end

function RideAllBuff_KeepBalance:HandleRePress()
  return true
end

function RideAllBuff_KeepBalance:OnBalanceFail()
  if self._stage == KeepBalanceStage.None or self._stage == KeepBalanceStage.Fail then
    return
  end
  Log.Debug("Keep Balance Fail...")
  self._stage = KeepBalanceStage.Fail
  self:SyncBalanceAngle(true)
  self._keepTime = 0
  self:SetAnimationSuccess(false)
  self:StartOrStopBalanceFx(false)
  self:StartOrStopSound(false)
  self:StartOrStopBalanceWarning(false)
  self.RideAllAnimInstance.bInKeepBalance = false
  local isFalling = self._keepBalanceComp.bIsFalling
  self.owner:OnFallOff()
  if not isFalling then
    self.owner.playerAttackedInteractionComponent:PerformAttacked(ProtoEnum.PlayerAttackPerformType.PAPT_Normal, -self.owner.viewObj:GetActorForwardVector())
  end
end

function RideAllBuff_KeepBalance:OnBalanceSuccess()
  if self._stage ~= KeepBalanceStage.Balance then
    return
  end
  Log.Debug("Keep Balance Success!")
  self._stage = KeepBalanceStage.Success
  self:SyncBalanceAngle(true)
  self:SetAnimationSuccess(true)
end

function RideAllBuff_KeepBalance:SetAnimationSuccess(bSuccess)
  if self.RideAllAnimInstance then
    Log.Debug("RideAllBuff_KeepBalance:SetAnimationSuccess: " .. tostring(bSuccess))
    self.RideAllAnimInstance.bIsKeepBalanceSuccess = bSuccess
  end
end

function RideAllBuff_KeepBalance:OnDisconnect()
  if self._stage == KeepBalanceStage.Fail then
    self.owner.buffComponent:RemoveBuff("RideAll_Main_Buff")
  elseif self._stage ~= KeepBalanceStage.None then
    self:StopActiveSKill()
    self:OnBuffFinish()
  end
end

function RideAllBuff_KeepBalance:GetBalanceProgress()
  if self._keepBalanceComp then
    return self._keepBalanceComp:GetBalanceProgress()
  end
  return 0
end

function RideAllBuff_KeepBalance:SyncBalanceAngle(stage_updated)
  local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  local circus_param = customParams.ride_skill_param.circus_pet_params
  if stage_updated then
    circus_param.balance_stage = self._stage
  end
  circus_param.balance_roll = math.round(self.RidePet.ShakeRoll * 1000)
  circus_param.balance_pitch = math.round(self.RidePet.ShakePitch * 1000)
  circus_param.is_moving_on_ground = not self._keepBalanceComp.bIsFalling
  self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
end

function RideAllBuff_KeepBalance:StartOrStopBalanceFx(bStart)
  if not UE.UObject.IsValid(self.RidePet) then
    Log.Warning("RideAllBuff_KeepBalance:StartOrStopBalanceFx No RidePet")
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
      Comp:LuaPlayMoveFxByStatus("Keep_Balance", self.ChargingFx)
    end
  elseif self.ChargingFx then
    for i, fx in ipairs(self.ChargingFx:ToTable()) do
      Comp:LuaStopMoveFx(fx, 0.5)
    end
    self.ChargingFx:Clear()
    self.ChargingFx = nil
  end
end

function RideAllBuff_KeepBalance:StartOrStopBalanceWarning(bWarning)
  if bWarning == self._lastWarning then
    return
  end
  self._lastWarning = bWarning
  self.owner:SendEvent(PlayerModuleEvent.ON_VITALITY_SHAKE, bWarning)
end

function RideAllBuff_KeepBalance:StartOrStopSound(bStart)
  if bStart then
    self.LoopSoundSessionID = NRCAudioManager:PlaySound2D(4000000, "RideAllBuff_KeepBalance:StartSound", false, true)
  elseif self.LoopSoundSessionID then
    NRCAudioManager:ReleaseSession(self.LoopSoundSessionID, true, "RideAllBuff_KeepBalance:StartSound")
    self.LoopSoundSessionID = nil
  end
end

function RideAllBuff_KeepBalance:OnPlayerStatusRefresh(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    self:OnRemotePlayEffect(customParams.ride_skill_param.circus_pet_params)
  end
end

function RideAllBuff_KeepBalance:OnRemotePlayerBuffBegin(Owner, SkillConf)
  Base.OnRemotePlayerBuffBegin(self, Owner, SkillConf, false)
  self.RidePet.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, UE.ERocoCustomMovementMode.MOVE_KeepBalance)
  local PetID = self.RideComp.ScenePet.config.id
  local SocketConf = DataConfigManager:GetRideSocket(PetID, true)
  self._sourceSocketName = self.RideComp.RideSocketName
  if SocketConf then
    if self.owner.viewObj.Male then
      self.RideComp:ChangeSocketWhileRiding(SocketConf.circus_socket_pc1)
    else
      self.RideComp:ChangeSocketWhileRiding(SocketConf.circus_socket_pc2)
    end
  end
  local uePlayer = self.owner.viewObj
  if UE4.UObject.IsValid(uePlayer) then
    local AnimInstance = uePlayer.Mesh and uePlayer.Mesh:GetAnimInstance()
    if AnimInstance then
      self.RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
      self.RideAllAnimInstance.bInKeepBalance = true
    end
  end
  self:SetAnimationSuccess(false)
end

function RideAllBuff_KeepBalance:OnRemotePlayEffect(circus_param)
  if not circus_param then
    return
  end
  local stage = circus_param.balance_stage
  if stage == KeepBalanceStage.Balance then
    self:StartOrStopBalanceFx(true)
  elseif stage == KeepBalanceStage.Fail then
    self:SetAnimationSuccess(false)
    self:StartOrStopBalanceFx(false)
  elseif stage == KeepBalanceStage.Success then
    self:SetAnimationSuccess(true)
    self:StartOrStopBalanceFx(false)
  end
  local TargetRoll = circus_param.balance_roll / 1000
  local TargetPitch = circus_param.balance_pitch / 1000
  self.RidePet.ShakeRoll = LuaMathUtils.ExpLerp(self.RidePet.ShakeRoll, TargetRoll, 0.2, self.RidePet.ShakeInterpSpeed)
  self.RidePet.ShakePitch = LuaMathUtils.ExpLerp(self.RidePet.ShakePitch, TargetPitch, 0.2, self.RidePet.ShakeInterpSpeed)
  self.RidePet.bKeepBalanceMovingOnGround = circus_param.is_moving_on_ground
end

function RideAllBuff_KeepBalance:OnRemotePlayerBuffFinish(param)
  self:SetAnimationSuccess(false)
  self.RideAllAnimInstance.bInKeepBalance = false
  self.RidePet.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
  self.RideComp:ChangeSocketWhileRiding(self._sourceSocketName)
  Base.OnRemotePlayerBuffFinish(self, param)
end

function RideAllBuff_KeepBalance:CanOffPet()
  return false
end

function RideAllBuff_KeepBalance:CanThrowBall()
  return false
end

return RideAllBuff_KeepBalance

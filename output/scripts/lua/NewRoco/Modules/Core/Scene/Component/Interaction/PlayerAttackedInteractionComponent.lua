local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local PlayerAttackedInteractionComponent = Base:Extend("PlayerAttackedInteractionComponent")

function PlayerAttackedInteractionComponent:Ctor()
  self._inRagDoll = false
  self._afterAttackTime = 0
  self._getUpCd = 0.6
  self._protectTime = 0
  self._perceivable = true
  self._inCastingThrow = false
  self._exposedFrom = {}
  self._exposedNoAlertFrom = {}
  self._afterExposedTime = 0
  self._exposedCd = 0
  self._perceivedFrom = {}
  self.updatePerceiveState = false
  self._CompassState = 0
  self.nextCanLaunchTimeStamp = 0
end

PlayerAttackedInteractionComponent.STATE = {
  Normal = 0,
  EXPOESD = 1,
  OUTEXPOSED = 2,
  HIDDEN = 3,
  HIDDEN_EXPOSED = 4,
  HIDDEN_ATTACKED = 5
}

function PlayerAttackedInteractionComponent:Attach(owner)
  Base.Attach(self, owner)
  if self.owner.isLocal then
    owner:AddEventListener(self, PlayerModuleEvent.ON_THROW_EXPOSED, self.OnThrowExposed)
    owner:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, self.OnAttacked)
    owner:AddEventListener(self, PlayerModuleEvent.ON_STOP_PASSIVE_FALLING, self.OnTeleport)
    owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    owner:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_PERCEPED_BY_NPC, self.OnPlayerPerceptedByNPC)
    owner:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_LOST_PERCEPED_BY_NPC, self.OnPlayerLostPerceptedByNPC)
    owner:AddEventListener(self, PlayerModuleEvent.ON_PERCEIVED_STATE_CHANGED, self.OnPerceivedStateChanged)
    _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_PAUSE_NPC_PERCEPT, self, self.OnPerceptiveChanged)
    local BannedPerceptive = _G.FunctionBanModuleCmd and _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_PAUSE_NPC_PERCEPT, false, false)
    self:OnPerceptiveChanged(BannedPerceptive)
  end
end

function PlayerAttackedInteractionComponent:DeAttach()
  if self.owner.isLocal then
    _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_PAUSE_NPC_PERCEPT, self, self.OnPerceptiveChanged)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_THROW_EXPOSED, self.OnThrowExposed)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, self.OnAttacked)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STOP_PASSIVE_FALLING, self.OnTeleport)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_PERCEPED_BY_NPC, self.OnPlayerPerceptedByNPC)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_LOST_PERCEPED_BY_NPC, self.OnPlayerLostPerceptedByNPC)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PERCEIVED_STATE_CHANGED, self.OnPerceivedStateChanged)
    self:CleanUpPerception()
    if MainUIModuleCmd then
      NRCModuleManager:DoCmd(MainUIModuleCmd.CompassChangeToNormal)
    end
  end
  Base.DeAttach(self)
end

function PlayerAttackedInteractionComponent:Update(deltaTime)
  if not self.owner.isLocal then
    return
  end
  if self._inRagDoll and self._afterAttackTime < self._getUpCd then
    self._afterAttackTime = self._afterAttackTime + deltaTime
    if self._afterAttackTime >= self._getUpCd then
      self:GetUP()
    end
  end
  if self._protectTime > 0 then
    self._protectTime = self._protectTime - deltaTime
  end
  local newStat = self.STATE.Normal
  if #self._exposedFrom > 0 then
    newStat = self.STATE.EXPOESD
  else
    if self._afterExposedTime > 0 then
      self._afterExposedTime = self._afterExposedTime - deltaTime
      newStat = self.STATE.OUTEXPOSED
    end
    if self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING) then
      newStat = self.STATE.HIDDEN
    end
  end
  if self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING) then
    if self.updatePerceiveState == true then
      newStat = self.STATE.HIDDEN_EXPOSED
    end
    if self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_EXPOSED) then
      newStat = self.STATE.HIDDEN_ATTACKED
    end
  end
  if self._CompassState ~= newStat then
    self._CompassState = newStat
    if self._CompassState == self.STATE.Normal then
      NRCModuleManager:DoCmd(MainUIModuleCmd.CompassChangeToNormal)
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetMiniMapOrCompassState, MainUIModuleEnum.MinimapOrCompassState.Normal)
    elseif self._CompassState == self.STATE.HIDDEN then
      NRCModuleManager:DoCmd(MainUIModuleCmd.CompassChangeToHidde, MainUIModuleEnum.MinimapOrCompassState.Hidden)
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetMiniMapOrCompassState, MainUIModuleEnum.MinimapOrCompassState.Hidden)
    elseif self._CompassState == self.STATE.HIDDEN_EXPOSED then
      NRCModuleManager:DoCmd(MainUIModuleCmd.CompassChangeToHidde, MainUIModuleEnum.MinimapOrCompassState.Hidden_Exposed)
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetMiniMapOrCompassState, MainUIModuleEnum.MinimapOrCompassState.Hidden_Exposed)
    elseif self._CompassState == self.STATE.HIDDEN_ATTACKED then
      NRCModuleManager:DoCmd(MainUIModuleCmd.CompassChangeToHidde, MainUIModuleEnum.MinimapOrCompassState.Hidden_Attacked)
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetMiniMapOrCompassState, MainUIModuleEnum.MinimapOrCompassState.Hidden_Attacked)
    else
      NRCModuleManager:DoCmd(MainUIModuleCmd.CompassChangeToLeakage)
      NRCModuleManager:DoCmd(MainUIModuleCmd.SetMiniMapOrCompassState, MainUIModuleEnum.MinimapOrCompassState.Normal)
    end
  end
end

function PlayerAttackedInteractionComponent:OnThrowExposed(value)
  self._inCastingThrow = value
end

function PlayerAttackedInteractionComponent:DispatchPreAttackedEvents()
  UE4.FCycleCounter.Create("DispatchPreAttackedEvents")
  UE4.FCycleCounter.Start("DispatchPreAttackedEvents")
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass, false)
  _G.NRCEventCenter:DispatchEvent(_G.SceneEvent.OnPlayerAttacked)
  UE4.FCycleCounter.Stop()
end

function PlayerAttackedInteractionComponent:OnAttacked(Damage, Direction, isHeavy, forcePerform, AttackPerformType, AdditionParams, ...)
  if GlobalConfig.IgnorePlayerHit or not NRCEnv:IsLocalMode() and self.owner.roleHPComponent:GetLocalRoleHP() <= 0 and not forcePerform then
    return
  end
  Damage = Damage or 1
  self:DispatchPreAttackedEvents()
  self.owner:StopTransformStatus()
  local HasHalfInjure = AdditionParams and AdditionParams[1]
  local OverrideReason = AdditionParams and AdditionParams[2]
  local statusComponent = self.owner.statusComponent
  if statusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND, ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P, ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO, ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF) then
    isHeavy = false
    AttackPerformType = ProtoEnum.PlayerAttackPerformType.PAPT_Light
  end
  if self.owner.viewObj.RidePet ~= nil then
    if self.owner.serverData.attrs.hp and (0 ~= Damage or HasHalfInjure) then
      if Damage >= self.owner.roleHPComponent:GetLocalRoleHP() and self.owner.roleHPComponent:GetLocalRoleHP() > 0 then
        self.owner.roleHPComponent:SetCustomDeathPerformTime(0.7)
        self.owner:StopRide()
        local AnimInstance = self.owner.viewObj.Mesh:GetAnimInstance()
        local Montage = self.owner.viewObj:GetAnimComponent():GetAnimSequenceByName("NormalDead")
        AnimInstance:PlaySlotAnimation(Montage, "DefaultSlot", 0.1, 0.1)
        if self.owner.inputComponent then
          self.owner.inputComponent:SetInputEnable(self, false, "DeathPerform")
        end
      end
      self.owner.roleHPComponent:ReduceRoleHP(Damage, OverrideReason or ProtoEnum.RoleHpReduceReason.HP_REDUCE_REASON_AI_ATTACKING, HasHalfInjure)
    end
    return
  end
  self.owner.viewObj.Mesh:GetAnimInstance():Montage_Stop(0)
  Direction = Direction or UE4.FVector(0, 0, 0)
  if nil == AttackPerformType then
    if true == isHeavy then
      AttackPerformType = ProtoEnum.PlayerAttackPerformType.PAPT_Heavy
    else
      AttackPerformType = ProtoEnum.PlayerAttackPerformType.PAPT_Light
    end
  end
  if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING) then
    statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
  end
  if NRCEnv:IsLocalMode() then
    self:PerformAttacked(AttackPerformType, Direction)
    return
  end
  if 0 ~= Damage or HasHalfInjure then
    local forceHeavy = false
    if self._inRagDoll then
      forceHeavy = true
    end
    local TotalDamage = Damage * 2
    if HasHalfInjure then
      TotalDamage = TotalDamage + 1
    end
    if self.owner.serverData.attrs.hp then
      local CurHp = self.owner.roleHPComponent:GetLocalRoleHP() * 2 - self.owner.roleHPComponent._localHalfInjure
      if TotalDamage >= CurHp then
        forceHeavy = true
      end
    end
    if forceHeavy then
      AttackPerformType = ProtoEnum.PlayerAttackPerformType.PAPT_Heavy
    end
  end
  self:PerformAttacked(AttackPerformType, Direction)
  if self.owner.serverData.attrs.hp and (0 ~= Damage or HasHalfInjure) then
    self.owner.roleHPComponent:SetCustomDeathPerformTime(1.5)
    self.owner.roleHPComponent:ReduceRoleHP(Damage, OverrideReason or ProtoEnum.RoleHpReduceReason.HP_REDUCE_REASON_AI_ATTACKING, HasHalfInjure)
  end
end

function PlayerAttackedInteractionComponent:PerformAttacked(AttackPerformType, Direction)
  if AttackPerformType == ProtoEnum.PlayerAttackPerformType.PAPT_Heavy or AttackPerformType == ProtoEnum.PlayerAttackPerformType.PAPT_Normal then
    if Direction.Z < -0.1 then
      Direction.Z = -0.1
    end
    local player = self.owner.viewObj
    local ALSComp = player.BP_ALSComponent
    ALSComp.DamageDirection = Direction
    local dir = UE.UKismetMathLibrary.Dot_VectorVector(player:GetActorForwardVector(), Direction)
    local localDirection = UE.UKismetMathLibrary.Vector_Normal2D(Direction)
    if dir < 0 or AttackPerformType == ProtoEnum.PlayerAttackPerformType.PAPT_Normal then
      localDirection = localDirection * -1
    end
    local ActorRotation = UE.UKismetMathLibrary.MakeRotFromX(localDirection)
    local animName = "HitNormalF"
    if AttackPerformType == ProtoEnum.PlayerAttackPerformType.PAPT_Heavy then
      animName = dir < 0 and "HitHeavyF" or "HitHeavyB"
    end
    local Animation = player:GetAnimComponent():GetAnimSequenceByName(animName)
    player.CharacterMovement:ConsumeInputVector()
    player.CharacterMovement:ConsumeInputVector()
    player.CharacterMovement:StopMovementImmediately()
    if self.owner.isLocal and self.owner.movementComponent then
      self.owner.movementComponent:ClearMoveInput()
    end
    ALSComp:GetHeavyAttacked(ActorRotation, Animation)
    local statusComponent = self.owner.statusComponent
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
    statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING, Enum.WPST_OpCode.WPST_OPCODE_REMOVE)
    statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC, Enum.WPST_OpCode.WPST_OPCODE_REMOVE)
    statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB, Enum.WPST_OpCode.WPST_OPCODE_REMOVE)
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ClearThrowCacheData)
  else
    local statusComponent = self.owner.statusComponent
    if not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
      Direction.Z = 0
      Direction:Normalize()
      self.owner.viewObj.BP_ALSComponent:GetAttacked(Direction)
    end
  end
  if NRCEnv:IsLocalMode() then
    return
  end
  local req = _G.ProtoMessage:newZoneClientOperationReq()
  req.operation.operator_id = self.owner.serverData.base.actor_id
  req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
  req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_HIT
  req.operation.player_perform_info.hit_type = AttackPerformType
  req.operation.player_perform_info.hit_direction = SceneUtils.ClientPos2ServerPos(Direction, 10000)
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
end

function PlayerAttackedInteractionComponent:GetUP()
  if self._inRagDoll and self._afterAttackTime > self._getUpCd and (not (self.owner.serverData.attrs.hp and self.owner.serverData.attrs.hp < 1) or not not GlobalConfig.EnableDeahTeleport) then
    self._inRagDoll = false
    self._protectTime = 0
    self.owner.viewObj.BP_ALSComponent:RagdollEnd()
  end
end

function PlayerAttackedInteractionComponent:OnTeleport()
  if self._inRagDoll then
    self._inRagDoll = false
    self._protectTime = 0
    self._afterAttackTime = self._getUpCd
    self.owner.viewObj.BP_ALSComponent:RagdollEnd()
    self._exposedFrom = {}
    self:OnPlayerLostPerceptedByNPC(-1)
  end
end

function PlayerAttackedInteractionComponent:IsInRagdoll()
  return self._inRagDoll
end

function PlayerAttackedInteractionComponent:OnStatusChanged(status, value, opCode)
  self:CheckPerceivableChange()
  if status == ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING then
    self:UpdatePerceiveState()
  end
end

function PlayerAttackedInteractionComponent:CheckPerceivableChange()
  if self.owner.statusComponent then
    local bPerceivable = not self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_BATTLE) and not self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) and not self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
    bPerceivable = bPerceivable or self._inCastingThrow
    if self._perceivable ~= bPerceivable then
      if bPerceivable then
        self.owner:GetUEController():OnDotsExposed()
      end
      self._perceivable = bPerceivable
      if not bPerceivable then
        self._afterExposedTime = 0
      end
    end
  end
end

function PlayerAttackedInteractionComponent:OnPlayerPerceptedByNPC(id, withoutAlert)
  if withoutAlert then
    if not table.contains(self._exposedNoAlertFrom, id) then
      table.insert(self._exposedNoAlertFrom, id)
    end
  else
    if not table.contains(self._exposedFrom, id) then
      table.insert(self._exposedFrom, id)
    end
    NRCAudioManager:SetStateByName("Alert_State", "Alert", "PlayerPerception")
  end
  if not self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_EXPOSED) then
    self.owner.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_EXPOSED)
    self._afterExposedTime = self._exposedCd
  end
end

function PlayerAttackedInteractionComponent:OnPlayerLostPerceptedByNPC(id, withoutAlert)
  if withoutAlert then
    if table.contains(self._exposedNoAlertFrom, id) then
      table.removeValue(self._exposedNoAlertFrom, id)
    end
  elseif table.contains(self._exposedFrom, id) then
    table.removeValue(self._exposedFrom, id)
  end
  if 0 == #self._exposedFrom then
    NRCAudioManager:SetStateByName("Alert_State", "Normal", "PlayerPerception")
    if 0 == #self._exposedNoAlertFrom and self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_EXPOSED) then
      self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_EXPOSED)
    end
  end
end

function PlayerAttackedInteractionComponent:CleanUpPerception()
  NRCAudioManager:SetStateByName("Alert_State", "Normal", "PlayerPerception")
  self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_EXPOSED)
end

function PlayerAttackedInteractionComponent:OnPerceivedStateChanged(id, bState)
  local bShouldUpdateState = false
  if bState then
    local prevPerceived = #self._perceivedFrom > 0
    if table.contains(self._perceivedFrom, id) then
      return
    end
    table.insert(self._perceivedFrom, id)
    if not prevPerceived then
      bShouldUpdateState = true
    end
  elseif table.contains(self._perceivedFrom, id) then
    table.removeValue(self._perceivedFrom, id)
    if 0 == #self._perceivedFrom then
      bShouldUpdateState = true
    end
  end
  if bShouldUpdateState then
    self:UpdatePerceiveState()
  end
end

function PlayerAttackedInteractionComponent:UpdatePerceiveState()
  if self.owner and self.owner.statusComponent then
    if #self._perceivedFrom > 0 then
      self.updatePerceiveState = true
    else
      self.updatePerceiveState = false
    end
  end
end

function PlayerAttackedInteractionComponent:OnPerceptiveChanged(Banned, Type)
  Log.Debug("[PlayerAttackedInteractionComponent] \232\174\190\231\189\174\231\142\169\229\174\182\232\131\189\229\164\159\232\162\171\231\178\190\231\129\181\231\156\139\232\167\129", not Banned)
  local controller = self.owner:GetUEController()
  if controller and UE4.UObject.IsValid(controller) then
    controller:SetDotsPerceptible(not Banned)
  else
    Log.PrintScreenMsg("PlayerAttackedInteractionComponent:OnPerceptiveChanged: No controller")
  end
end

function PlayerAttackedInteractionComponent:CanLaunchByNpc()
  local serverTime = ZoneServer:GetServerTime()
  return self.nextCanLaunchTimeStamp < (0 ~= serverTime and serverTime or os.msTime())
end

function PlayerAttackedInteractionComponent:OnLaunchByNpc(sourceNpc, Force, Cooldown, SkipCheckCooldown)
  if GlobalConfig.IgnorePlayerHit or not NRCEnv:IsLocalMode() and self.owner.roleHPComponent:GetLocalRoleHP() <= 0 then
    return
  end
  local isAttackBan = _G.FunctionBanModuleCmd and _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_BT_ATTACK, false, false)
  if isAttackBan then
    return
  end
  if not SkipCheckCooldown and not self:CanLaunchByNpc() then
    return
  end
  self:DispatchPreAttackedEvents()
  if self.owner.viewObj.RidePet == nil then
    self.owner:Stop()
    local AnimInstance = self.owner.viewObj.Mesh:GetAnimInstance()
    if AnimInstance then
      AnimInstance:SetRootMotionMode(UE.ERootMotionMode.RootMotionFromMontagesOnly)
    end
    self.owner.viewObj:LaunchCharacter(Force, true, true)
  end
  local serverTime = ZoneServer:GetServerTime()
  self.nextCanLaunchTimeStamp = (0 ~= serverTime and serverTime or os.msTime()) + math.round(Cooldown * 1000)
end

return PlayerAttackedInteractionComponent

local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ThrowBuff = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerThrowBuff")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local CameraAdditiveParamType = require("NewRoco.Modules.Core.Character.WorldCamera.CameraAdditiveParamType")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local EndThrowAbility = Base:Extend("EndThrowAbility")

function EndThrowAbility:Init(AbilityConf)
  Base.Init(self, AbilityConf)
  self._buffName = "ThrowBuff"
end

function EndThrowAbility:AwakeFromPool(owner)
  Base.AwakeFromPool(self, owner)
  Log.TraceFormat("EndThrowAbility AwakeFromPool")
end

function EndThrowAbility:Start(OnFinished, Success)
  Log.Debug("EndThrowAbility Start")
  Base.Start(self, OnFinished)
  self.SkillTime = 0
  self.hasOnThrow = false
  self.rideAllFastThrow = false
  local player = self.caster
  self.buff = player.buffComponent:GetBuff(self._buffName)
  if self.buff == nil then
    return
  end
  self.Caster = self.caster.viewObj
  self:EnterState(ABEnum.AbilityState.Casting)
  self.caster:SendEvent(PlayerModuleEvent.ON_THROW_EXPOSED, true)
  if not self.caster.isLocal then
    if self.buff.Success then
      self:Throw()
    else
      Log.Debug("\230\168\161\230\139\159\231\142\169\229\174\182\229\143\150\230\182\136\230\138\149\230\142\183")
      self:Interrupt()
    end
    return
  end
  if Success then
    if self:IsLocmotionThrow() then
      if self.buff.isFast then
        self:FastThrow()
      else
        self:Throw()
      end
    else
      self:Throw()
    end
  else
    self:Interrupt()
  end
end

function EndThrowAbility:FastThrow()
  if self.buff == nil then
    return
  end
  self.Anim = self.Caster:GetAnimComponent():GetAnimSequenceByName(self.buff.SkillInfo.ThrowBallLight)
  self:PlayAnimAndSkill()
end

function EndThrowAbility:Throw()
  if self.buff == nil then
    return
  end
  if not self:IsLocmotionThrow() then
    self._rideThrowBallCachedStartPos = self.buff:GetStartPos()
  end
  if not self.caster.isLocal then
    self:PlaySyncSkill()
    return
  end
  local pitch = self.buff:GetThrowAngle()
  if pitch > self.buff.SkillInfo.HeavyThrowAngle then
    self.Anim = self.Caster:GetAnimComponent():GetAnimSequenceByName(self.buff.SkillInfo.ThrowBallHeavy)
  else
    self.Anim = self.Caster:GetAnimComponent():GetAnimSequenceByName(self.buff.SkillInfo.ThrowBallLight)
  end
  self:PlayAnimAndSkill()
  self.buff:GetController():ChangeThrowAimStat(false)
end

function EndThrowAbility:PlayAnimAndSkill()
  if self.buff == nil then
    return
  end
  _G.UpdateManager:Register(self)
  if self:IsLocmotionThrow() then
    local AnimInstance = self.Caster.Mesh and self.Caster.Mesh:GetAnimInstance()
    if AnimInstance then
      local ThrowAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("Locomotion"):GetLinkedAnimGraphInstanceByTag("Aim")
      if ThrowAnimInstance then
        ThrowAnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
      else
        AnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
      end
    end
  else
    local AnimInstance = self.Caster.Mesh and self.Caster.Mesh:GetAnimInstance()
    if AnimInstance then
      local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
      if RideAllAnimInstance then
        if self.Caster and self.Caster.RidePet then
          local CameraYaw = self.buff:GetController().PlayerCameraManager:GetCameraRotation().Yaw
          local PetYaw = self.Caster.RidePet:K2_GetActorRotation().Yaw
          local YawDiff = (CameraYaw - PetYaw + 180.0) % 360 - 180.0
          RideAllAnimInstance.Angle = YawDiff / 90.0
          if RideAllAnimInstance.Angle <= 67.5 and RideAllAnimInstance.Angle >= -67.5 then
            RideAllAnimInstance.FB = 1
          elseif RideAllAnimInstance.Angle >= 157.5 and RideAllAnimInstance.Angle <= -157.5 then
            RideAllAnimInstance.FB = -1
          else
            RideAllAnimInstance.FB = 0
          end
          if RideAllAnimInstance.Angle >= 22.5 and RideAllAnimInstance.Angle <= 157.5 then
            RideAllAnimInstance.LR = 1
          elseif RideAllAnimInstance.Angle <= -22.5 and RideAllAnimInstance.Angle >= -157.5 then
            RideAllAnimInstance.LR = -1
          else
            RideAllAnimInstance.LR = 0
          end
          RideAllAnimInstance.IsInterrupt = false
          if not self.buff.isFast then
            RideAllAnimInstance.IsAiming = false
          end
        end
      else
        AnimInstance.PlayThrow = false
      end
    end
  end
end

function EndThrowAbility:PlaySyncSkill()
  if self.buff == nil then
    return
  end
  if nil == self.Caster then
    self:Finish()
    return
  end
  self.Anim = self.Caster:GetAnimComponent():GetAnimSequenceByName(self.buff.ThrowBallAnim)
  _G.UpdateManager:Register(self)
  if nil == self.Caster then
    self:CancelThrow()
    self:Finish()
    return
  end
  if self:IsLocmotionThrow() then
    local AnimInstance = self.Caster.Mesh and self.Caster.Mesh:GetAnimInstance()
    if AnimInstance then
      local ThrowAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("Locomotion"):GetLinkedAnimGraphInstanceByTag("Aim")
      if ThrowAnimInstance then
        ThrowAnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
      else
        AnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
      end
    end
  else
    local AnimInstance = self.Caster.Mesh and self.Caster.Mesh:GetAnimInstance()
    if AnimInstance then
      local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
      if RideAllAnimInstance then
        if self.Caster and self.Caster.RidePet then
          RideAllAnimInstance.IsInterrupt = true
          RideAllAnimInstance.IsAiming = false
        end
      else
        AnimInstance.PlayThrow = false
      end
    end
  end
end

function EndThrowAbility:OnTick(DeltaTime)
  self.SkillTime = self.SkillTime + DeltaTime
  if not self.hasOnThrow then
    if not self:IsLocmotionThrow() then
      if self.buff.isFast then
        if not self.rideAllFastThrow and self.SkillTime > 0.24 then
          local AnimInstance = self.Caster.Mesh and self.Caster.Mesh:GetAnimInstance()
          if AnimInstance then
            local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
            if RideAllAnimInstance then
              RideAllAnimInstance.IsAiming = false
            end
          end
          self.rideAllFastThrow = true
        end
        if self.SkillTime > 0.36 then
          self.hasOnThrow = true
          self:OnThrow()
        end
      elseif self.SkillTime > 0.12 then
        self.hasOnThrow = true
        self:OnThrow()
      end
    else
      self.hasOnThrow = true
      self:OnThrow()
    end
  end
  if self.SkillTime > 0.67 then
    self:Finish()
    return
  end
end

function EndThrowAbility:OnSkillEvent(event)
  Base.OnSkillEvent(self, event)
  if "OnThrow" == event then
    self:OnThrow()
  end
  if "End" == event then
    self:Finish()
  end
  if "Interrupt" == event then
    self:Interrupt()
  end
end

function EndThrowAbility:OnThrow()
  if self.buff == nil then
    return
  end
  if not self.caster.isLocal then
    self:OnSyncThrow()
    return
  end
  if self.buff.SkillInfo and self.buff.SkillInfo.BallLua and self.buff.SkillInfo.BallLua.viewObj then
    self.buff:UpdateDirection()
    self.ballNPC = self.buff.SkillInfo.BallLua.viewObj
    self.ballNPC:K2_DetachFromActor(UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative)
    self.ballNPC:Abs_K2_SetActorTransform_WithoutHit(UE4.UKismetMathLibrary.Conv_VectorToTransform(self:IsLocmotionThrow() and self.buff:GetStartPos() or self._rideThrowBallCachedStartPos))
    local ProjectileMovement = self.ballNPC:GetComponentByClass(UE4.UProjectileMovementComponent)
    if SceneUtils.GetAutoHoming() then
      local TargetNPC = SceneUtils.QueryNPCInRange(self.ballNPC:Abs_K2_GetActorLocation())
      if TargetNPC then
        ProjectileMovement.Velocity = _G.FVectorZero
        ProjectileMovement.bIsHomingProjectile = true
        ProjectileMovement.HomingTargetComponent = TargetNPC:K2_GetRootComponent()
        ProjectileMovement.HomingAccelerationMagnitude = 1000000.0
      else
        ProjectileMovement.bIsHomingProjectile = false
        ProjectileMovement.HomingTargetComponent = nil
        ProjectileMovement.HomingAccelerationMagnitude = 0
        Log.Error("\230\159\165\232\175\162\228\184\141\229\136\176\233\153\132\232\191\145\231\154\132NPC\239\188\140\229\143\150\230\182\136\232\135\170\229\138\168\229\175\187\230\137\190")
      end
    else
      ProjectileMovement.bIsHomingProjectile = false
      ProjectileMovement.HomingTargetComponent = nil
      ProjectileMovement.HomingAccelerationMagnitude = 0
      ProjectileMovement.Velocity = self.buff:CalculateVelocity()
    end
    ProjectileMovement:SetActive(true)
    self.buff.SkillInfo.BallLua:OnThrowStart()
    self.buff.SkillInfo.BallLua = nil
    local currThrowSession = self.ballNPC.ThrowSession
    self.ballNPC = nil
    local protectTime = _G.DataConfigManager:GetGlobalConfigByKeyType("throw_recycle_protect_time", _G.DataConfigManager.ConfigTableId.ROLE_GLOBAL_CONFIG).num
    if protectTime and protectTime > 0 then
      if self.switchTimerId then
        _G.DelayManager:CancelDelayById(self.switchTimerId)
        self.switchTimerId = nil
      end
      self.switchTimerId = _G.DelayManager:DelaySeconds(protectTime / 1000.0, self.OnSwitchThrowCanRecycle, self, currThrowSession)
    end
  end
end

function EndThrowAbility:OnSwitchThrowCanRecycle(currThrowSession)
  if currThrowSession then
    currThrowSession:ForceSetCanBeRecycle(true)
  end
  self.switchTimerId = nil
end

function EndThrowAbility:OnSyncThrow()
  if self.buff.SkillInfo.BallLua and self.buff.SkillInfo.BallLua.viewObj then
    self.ballNPC = self.buff.SkillInfo.BallLua.viewObj
    self.ballNPC:K2_DetachFromActor(UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative)
    self.ballNPC:Abs_K2_SetActorTransform_WithoutHit(UE4.UKismetMathLibrary.Conv_VectorToTransform(self:IsLocmotionThrow() and self.buff:GetStartPos() or self._rideThrowBallCachedStartPos))
    self.ballNPC:K2_GetRootComponent():IgnoreActorWhenMoving(self.caster.viewObj, true)
    local ProjectileMovement = self.ballNPC:GetComponentByClass(UE4.UProjectileMovementComponent)
    if ProjectileMovement then
      ProjectileMovement.bIsHomingProjectile = false
      ProjectileMovement.HomingTargetComponent = nil
      ProjectileMovement.HomingAccelerationMagnitude = 0
      ProjectileMovement.Velocity = self.buff.ThrowVelocity
      ProjectileMovement:SetActive(true)
    else
      Log.Error("EndThrowAbility:OnSyncThrow ProjectileMovement is missing")
    end
    self.buff.SkillInfo.BallLua:OnThrowStart()
    self.buff.SkillInfo.BallLua = nil
    self.ballNPC = nil
  end
end

function EndThrowAbility:Interrupt()
  Log.Debug("EndThrowAbility:Interrupt")
  if self.buff == nil then
    return
  end
  if nil == self.Caster then
    return
  end
  if nil == self.caster then
    Log.Error("\232\167\166\229\143\145\228\186\134\230\138\149\230\142\183\239\188\140\228\189\134\228\184\141\229\173\152\229\156\168\230\138\149\230\142\183\232\167\146\232\137\178\239\188\129")
    return
  end
  self:CancelThrow()
  self:Finish()
end

function EndThrowAbility:CancelThrow()
  if self.buff.SkillInfo and self.buff.SkillInfo.BallLua then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, self.buff.SkillInfo.BallLua.viewObj)
    self.buff.SkillInfo.BallLua = nil
  end
  if not self:IsLocmotionThrow() then
    local AnimInstance = self.Caster.Mesh and self.Caster.Mesh:GetAnimInstance()
    if AnimInstance then
      local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
      if RideAllAnimInstance then
        RideAllAnimInstance.IsInterrupt = true
        RideAllAnimInstance.IsAiming = false
      else
        AnimInstance.PlayThrow = false
      end
    end
  end
  self.caster:SendEvent(PlayerModuleEvent.ON_INTERRUPT_THROW)
  if self.caster and self.caster.isLocal and self.buff.GetController then
    self.buff:GetController().PlayerCameraManager:Reset()
  end
  self:CancelG6Ability()
end

function EndThrowAbility:Recover()
  Log.Debug("EndThrowAbility:Recover")
  local player = self.caster
  self.buff = player.buffComponent:GetBuff(self._buffName)
  if self.buff == nil then
    return
  end
  self.Caster = self.caster.viewObj
  self:Interrupt()
end

function EndThrowAbility:Finish(Force)
  Log.Debug("EndThrowAbility:Finish")
  _G.UpdateManager:UnRegister(self)
  if self.buff == nil then
    return
  end
  if nil == self.Caster then
    local player = self.caster
    if player then
      player.buffComponent:RemoveBuff(self._buffName)
    end
    return
  end
  if nil == self.buff.SkillInfo then
    local player = self.caster
    player.buffComponent:RemoveBuff(self._buffName)
    Base.Finish(self)
    return
  end
  self.caster:SendEvent(PlayerModuleEvent.ON_THROW_EXPOSED, false)
  if self.buff.SkillInfo.BallLua then
    self:CancelThrow()
  end
  self.Caster = nil
  self.buff = nil
  local player = self.caster
  player.buffComponent:RemoveBuff(self._buffName)
  if self.switchTimerId then
    _G.DelayManager:CancelDelayById(self.switchTimerId)
    self.switchTimerId = nil
  end
  Base.Finish(self)
end

function EndThrowAbility:IsLocmotionThrow()
  return self.buff.SkillInfo and self.buff.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_NORMAL
end

function EndThrowAbility:SendCameraAdditiveEvent()
  if self.buff.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_NORMAL then
    self.caster:SendEvent(PlayerModuleEvent.ON_ADDITIVE_CAMERA_PARAM, CameraAdditiveParamType.AimThrow)
  elseif self.buff.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_RIDE_WOLF then
    self.caster:SendEvent(PlayerModuleEvent.ON_ADDITIVE_CAMERA_PARAM, CameraAdditiveParamType.RideThrow)
  elseif self.buff.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_RIDE_LANNIAO or self.buff.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_RIDE_LANNIAO3 or self.buff.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_RIDE_BALLON then
    self.caster:SendEvent(PlayerModuleEvent.ON_ADDITIVE_CAMERA_PARAM, CameraAdditiveParamType.FlyThrow)
  end
end

return EndThrowAbility

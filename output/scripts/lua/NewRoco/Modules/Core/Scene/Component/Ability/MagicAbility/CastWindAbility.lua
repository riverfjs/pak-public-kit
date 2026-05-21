local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.MagicAbility.CastMagicAbilityBase")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local WindBuff = require("NewRoco.Modules.Core.Scene.Component.Buff.Magic.ScenePlayerWindBuff")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local CastWindAbility = Base:Extend("CastWindAbility")

function CastWindAbility:Init(abilityConf)
  Base.Init(self, abilityConf)
end

local WIND_BUFF_NAME = "WindBuff"

function CastWindAbility:Start(OnFinished, Success)
  Log.DebugFormat("WindTest: Cast Wind Ability")
  local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_WIND)
  local buff = self.caster.buffComponent:GetBuff(helper:GetBuffName())
  if self.caster.isLocal then
    if not Success and not NRCEnv:IsLocalMode() then
      self:Recover()
      return
    end
  elseif not buff.SyncCastSuccess then
    self:Recover()
    return
  end
  if not string.IsNilOrEmpty(buff.errorStr) then
    NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, buff.errorStr)
    self.caster.buffComponent:RemoveBuff(helper:GetBuffName())
    return
  end
  self:EnterState(ABEnum.AbilityState.Casting)
  self.caster:SendEvent(PlayerModuleEvent.ON_THROW_EXPOSED, true)
  self:PlayAnimAndSkill()
  if self.caster.isLocal then
    buff:GetController():ChangeThrowAimStat(false)
  end
  self.caster:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_END, true)
end

function CastWindAbility:PlayAnimAndSkill()
  if self.helper.g6SkillClass then
    if not self:CastG6Ability(self.caster.viewObj, {}, {}, true) then
      self:CreateWind()
      return
    end
    self.Anim = self.caster.viewObj:GetAnimComponent():GetAnimSequenceByName("MagicWindCast")
    local AnimInstance = self.caster.viewObj.Mesh:GetAnimInstance()
    local ThrowAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("Locomotion"):GetLinkedAnimGraphInstanceByTag("Aim")
    if nil == ThrowAnimInstance then
      AnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
    else
      ThrowAnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
    end
  else
    self:CreateWind()
  end
end

function CastWindAbility:OnThrow()
  local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_WIND)
  local buff = self.caster.buffComponent:GetBuff(helper:GetBuffName())
  if buff then
    if buff.magicInfo.WindXuli then
      _G.NRCAudioManager:ReleaseSession(buff.magicInfo.WindXuli, true, "PrepareWindAbility")
    end
    self:CreateWind()
    if self.caster.isLocal then
      self.caster.viewObj:K2_SetActorRotation(UE4.FRotator(0, buff:GetController():GetControlRotation().Yaw, 0), false)
    end
  end
end

function CastWindAbility:OnMozhangDisappear()
  if not self.caster then
    return
  end
  local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_WIND)
  local buff = self.caster.buffComponent:GetBuff(helper:GetBuffName())
  if buff and buff.magicInfo.mozhangBP then
    buff.magicInfo.mozhangBP:ClearFX()
    buff.magicInfo.mozhangBP:OnDisappear()
    buff.magicInfo.mozhangBP = nil
  end
end

function CastWindAbility:CreateWind()
  if not self.caster.isLocal then
    return
  end
  local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_WIND)
  local buff = self.caster.buffComponent:GetBuff(helper:GetBuffName())
  buff.magicInfo.mozhangBP.inCasting = true
  buff.magicInfo.mozhangBP:ClearFX()
  local windBuff = self.caster.buffComponent:GetBuff(WIND_BUFF_NAME)
  if not windBuff then
    self.caster.buffComponent:AddBuff(WIND_BUFF_NAME, WindBuff)
    windBuff = self.caster.buffComponent:GetBuff(WIND_BUFF_NAME)
  end
  windBuff:AddWind(buff.pos, buff.radius, buff.lifeTime, buff.windAcc, buff.chargedLevel, buff.currentLevelProcess)
end

function CastWindAbility:OnSkillEvent(event)
  Base.OnSkillEvent(self, event)
  if "OnThrow" == event then
    self:OnThrow()
  end
  if "OnMozhangDisappear" == event then
    self:OnMozhangDisappear()
  end
  if "End" == event then
    self:Finish()
  end
end

function CastWindAbility:Interrupt()
  Log.Debug("CastWindAbility:Recover")
  self:Recover()
end

function CastWindAbility:Recover()
  Log.Debug("CastWindAbility:Recover")
  self:CancelThrow()
  self:Finish()
end

function CastWindAbility:CancelThrow()
  local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_WIND)
  local windBuff = self.caster.buffComponent:GetBuff(helper:GetBuffName())
  if windBuff and not windBuff.is_magic_cancel then
    windBuff:GetController().PlayerCameraManager:Reset()
  end
  if windBuff and windBuff.magicInfo.WindXuli then
    _G.NRCAudioManager:ReleaseSession(windBuff.magicInfo.WindXuli, true, "PrepareWindAbility")
  end
  self:CancelG6Ability()
  if self.caster.isLocal then
    self.caster.viewObj:ChangeThrowAnim(0)
  else
    self.caster.viewObj:SetAimMode(false, 0)
  end
  self.caster:SendEvent(PlayerModuleEvent.ON_INTERRUPT_THROW)
  self.caster:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_END, false)
end

function CastWindAbility:Finish(Force)
  if not self.caster then
    return
  end
  if self.caster.isLocal then
    self.caster.viewObj:ChangeThrowAnim(0)
  else
    self.caster.viewObj:SetAimMode(false, 0)
  end
  self:OnMozhangDisappear()
  local helper = AbilityHelperManager.GetHelper(AbilityID.MAGIC_WIND)
  self.caster.buffComponent:RemoveBuff(helper:GetBuffName())
  self:EnterState(ABEnum.AbilityState.Finished)
  self.caster:SendEvent(PlayerModuleEvent.ON_THROW_EXPOSED, false)
end

return CastWindAbility

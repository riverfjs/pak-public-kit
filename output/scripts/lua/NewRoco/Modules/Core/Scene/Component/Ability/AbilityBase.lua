require("UnLuaEx")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local EventDispatcher = require("Common.EventDispatcher")
local HelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local AbilityBase = Class()

function AbilityBase:Init(AbilityConf)
  self.state = ABEnum.AbilityState.None
  self.helper = HelperManager.GetHelper(AbilityConf.id)
  EventDispatcher():Attach(self)
end

function AbilityBase:UnInit()
end

function AbilityBase:AwakeFromPool(owner)
  self.caster = owner
  self.isInPool = false
end

function AbilityBase:Start(OnFinished, ...)
  if OnFinished then
    self.onFinished = OnFinished
  end
  if self.caster.isLocal and self.helper.config.cooldown > 0 and self.helper.config.cooldown_type == ProtoEnum.SceneAbilityCooldownType.SCDT_FROMAHEAD then
    local abilityCD = self.caster.abilityComponent:GetAbilityCD(self.helper.config.id, true)
    abilityCD:StartCD()
  end
end

function AbilityBase:Tick(DeltaTime)
end

function AbilityBase:ReActive()
end

function AbilityBase:Interrupt()
  self:EnterState(ABEnum.AbilityState.Finished)
  if self.onFinished then
    self.onFinished()
    self.onFinished = nil
  end
end

function AbilityBase:Recover(owner)
end

function AbilityBase:Finish(Force)
  if not self:IsCasting() then
    return
  end
  self:EnterState(ABEnum.AbilityState.Finished)
  if self.onFinished then
    self.onFinished()
    self.onFinished = nil
  end
  if self.caster.isLocal and self.helper.config.cooldown > 0 and self.helper.config.cooldown_type == ProtoEnum.SceneAbilityCooldownType.SCDT_FROMEND then
    local abilityCD = self.caster.abilityComponent:GetAbilityCD(self.helper.config.id, true)
    abilityCD:StartCD()
  end
end

function AbilityBase:ReturnToPool()
  self.caster = nil
  self.isInPool = true
end

function AbilityBase:ReceiveTick(DeltaSeconds)
  if type(self) == "table" then
    self:Tick(DeltaSeconds)
  end
end

function AbilityBase:ReceiveDestroyed()
  self:UnInit()
end

function AbilityBase:IsPreCasting()
  return self.state == ABEnum.AbilityState.PreCasting
end

function AbilityBase:IsCasting()
  return self.state and self.state > ABEnum.AbilityState.None and self.state < ABEnum.AbilityState.Finished
end

function AbilityBase:IsAfterCasting()
  return self.state == ABEnum.AbilityState.AfterCasting
end

function AbilityBase:IsFinished()
  return self.state == ABEnum.AbilityState.Finished
end

function AbilityBase:EnterState(state)
  self.state = state
  self:SendEvent(PlayerModuleEvent.ON_ABILITY_STATE_CHANGE, state)
end

function AbilityBase:OnNoMoveInput()
end

function AbilityBase:SetInputEnable(Enable, flag)
  local player = self.caster
  if player and player.inputComponent then
    player.inputComponent:SetInputEnable(self, Enable, flag)
  end
end

function AbilityBase:CastG6Ability(Caster, Characters, Targets, isPassive)
  local caster = self.caster.viewObj
  isPassive = isPassive or false
  if self.helper.g6SkillClass then
    local skillComponent = caster.RocoSkill
    if not skillComponent then
      return
    end
    local skillObj = skillComponent:FindOrAddSkillObj(self.helper.g6SkillClass)
    if not skillObj and not _G.bShutDownSafeReload then
      local skillPath = self.helper.config.skill_path
      if not string.IsNilOrEmpty(skillPath) then
        local g6SkillClass = UE4.UNRCStatics.ResolveClass(skillPath)
        self.helper.g6SkillClass = g6SkillClass
      end
      skillObj = skillComponent:FindOrAddSkillObj(self.helper.g6SkillClass)
      Log.Warning("AbilityBase try reload skill obj ", skillObj and "true" or "false")
    end
    if _G.bShutDownSafeReload and not skillObj then
      Log.Error("AbilityBase try reload skill obj ", skillObj and "true" or "false")
    end
    if skillObj or _G.bShutDownSafeReload then
      self._skillObj = skillObj
      self._skillObj.CanInterrupt = true
      skillObj:SetPassive(isPassive)
      skillObj:SetCaster(Caster)
      skillObj:SetCharacters(Characters)
      skillObj:SetTargets(Targets)
      skillObj:RegisterRawCallback(self, self.OnSkillEvent)
      local result = skillComponent:PlaySkill(skillObj)
      return result == UE4.ESkillStartResult.Success
    end
  end
  return false
end

function AbilityBase:CastCustomG6Ability(Caster, Characters, Targets, skillPath)
  local caster = self.caster.viewObj
  local skillComponent = caster.RocoSkill
  if not skillComponent then
    return
  end
  local skillObj, g6SkillClass
  if not string.IsNilOrEmpty(skillPath) then
    g6SkillClass = UE4.UNRCStatics.ResolveClass(skillPath)
  end
  skillObj = skillComponent:FindOrAddSkillObj(g6SkillClass)
  if _G.bShutDownSafeReload and not skillObj then
    Log.Error("AbilityBase try reload skill obj ", skillObj and "true" or "false")
  end
  if skillObj or _G.bShutDownSafeReload then
    self._skillObj = skillObj
    self._skillObj.CanInterrupt = true
    skillObj:SetCaster(Caster)
    skillObj:SetCharacters(Characters)
    skillObj:SetTargets(Targets)
    skillObj:RegisterRawCallback(self, self.OnSkillEvent)
    local result = skillComponent:PlaySkill(skillObj)
    return result == UE4.ESkillStartResult.Success
  end
  return false
end

function AbilityBase:OnSkillEvent(event)
end

function AbilityBase:CancelG6Ability()
  if self._skillObj then
    local skillObj = self._skillObj
    self._skillObj = nil
    local caster = self.caster.viewObj
    local skillComponent = caster.RocoSkill
    if not skillComponent then
      return
    end
    skillComponent:CancelSkill(skillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
    skillObj:UnregisterRawCallback(self, self.OnSkillEvent)
  end
end

function AbilityBase:FinishG6Ability()
  if self._skillObj then
    self._skillObj:UnregisterRawCallback(self, self.OnSkillEvent)
    self._skillObj = nil
  end
end

function AbilityBase:CastG6AbilityAsync(characters, targets, skillPath)
  local casterActor = self.caster.viewObj
  local skillComponent = casterActor.RocoSkill
  self:CancelAsyncG6Ability()
  self.skillProxy = RocoSkillProxy.Create(skillPath, skillComponent, PriorityEnum.Active_Player_CastSkill)
  if not self.skillProxy then
    return
  end
  local priority = _G.PriorityEnum.Local_Player_Logic
  if not self.caster.isLocal then
    priority = _G.PriorityEnum.Other_Player_Logic
  end
  self.skillProxy.Priority = priority
  self.skillProxy:SetCaster(casterActor)
  self.skillProxy:SetCharacters(characters)
  self.skillProxy:SetTargets(targets)
  local serverDataBase = self.caster.serverData and self.caster.serverData.base
  self.skillProxy.BattleGenderType = serverDataBase and serverDataBase.gender or 0
  self.skillProxy:RegisterRawCallback(self, self.OnSkillEvent)
  self.skillProxy:RegisterEventCallback("ActionStart", self, self.OnActionStart)
  self.skillProxy:RegisterEventCallback("PreStart", self, self.OnG6PreStart)
  self.skillProxy:RegisterEventCallback("ActivateSuccess", self, self.OnCastG6Success)
  self.skillProxy:RegisterEventCallback("ActivateFailed", self, self.OnCastG6Failed)
  self.skillProxy:PlaySkill(self, self.OnG6AbilityAsync)
end

function AbilityBase:OnActionStart()
end

function AbilityBase:OnG6PreStart()
end

function AbilityBase:OnG6AbilityAsync(skillProxy, result)
  self._skillObj = skillProxy.SkillObject
  self.skillProxy = nil
end

function AbilityBase:OnCastG6Success()
end

function AbilityBase:OnCastG6Failed()
end

function AbilityBase:CancelAsyncG6Ability()
  if self.skillProxy then
    self.skillProxy:CancelSkill(UE.ESkillActionResult.SkillActionResultInterrupted)
    self.skillProxy:Destroy()
    self.skillProxy = nil
  else
    self:CancelG6Ability()
  end
end

return AbilityBase

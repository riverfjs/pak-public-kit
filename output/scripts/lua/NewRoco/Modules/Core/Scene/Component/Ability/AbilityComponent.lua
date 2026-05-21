local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local EventDispatcher = require("Common.EventDispatcher")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local AbilityCD = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityCD")
local SuitPerformAbility = require("NewRoco.Modules.Core.Scene.Component.Ability.Perform.SuitPerformAbility")
local AbilityComponent = Base:Extend("AbilityComponent")
local CHECK_RECYCLE_INTERVAL = 1

function AbilityComponent:Ctor()
  self._abilities = {}
  self._abilityCDs = {}
  self._updateAbilities = {}
  EventDispatcher():Attach(self)
  self._remainRecycleTime = CHECK_RECYCLE_INTERVAL
end

function AbilityComponent:Destroy()
  for _, v in pairs(self._abilities) do
    local ability = v
    self:ReturnAbilityToPoolInternal(ability)
  end
  self._abilities = {}
  self._abilityCDs = {}
  self._updateAbilities = {}
  self._suitPerformAbility = nil
end

function AbilityComponent:Attach(owner)
  Base.Attach(self, owner)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self._suitPerformAbility = SuitPerformAbility(self.owner)
end

function AbilityComponent:DeAttach()
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self._suitPerformAbility = nil
  Base.DeAttach(self)
end

function AbilityComponent:Update(deltaTime)
  self._remainRecycleTime = self._remainRecycleTime - deltaTime
  if self._remainRecycleTime <= 0 then
    for k, v in pairs(self._abilities) do
      if not v:IsCasting() then
        self:ReturnAbilityToPoolInternal(v)
        self._abilities[k] = nil
      end
    end
    self._remainRecycleTime = self._remainRecycleTime + CHECK_RECYCLE_INTERVAL
  end
  self:TickCD(deltaTime)
  for k, v in pairs(self._updateAbilities) do
    if v:IsCasting() then
      v:Update(deltaTime)
    else
      self._updateAbilities[k] = nil
    end
  end
  if self._suitPerformAbility and self._suitPerformAbility:IsCasting() then
    self._suitPerformAbility:Update(deltaTime)
  end
end

function AbilityComponent:TempCheckIsRideThrow(abilityHelper)
  if abilityHelper.config.id == AbilityID.RIDE_THROW or abilityHelper.config.id == AbilityID.DANDELION_THROW or abilityHelper.config.id == AbilityID.GLIDING_THROW or abilityHelper.config.id == AbilityID.THROW_ENTRY then
    return true
  end
  return false
end

function AbilityComponent:CastAbility(ability, onFinished, ...)
  local errorCode = AbilityErrorCode.NO_ERROR
  local targetAbility = type(ability) == "number" and self:GetAbilityInternal(ability) or ability
  if not targetAbility then
    return AbilityErrorCode.CAN_NOT_FIND_ABILITY
  end
  if not targetAbility.helper.config.is_passive then
    if self._currentAbility and not self:TempCheckIsRideThrow(targetAbility.helper) and self._currentAbility:IsCasting() and targetAbility == self._currentAbility then
      if self._currentAbility.ReActive then
        self._currentAbility:ReActive()
      end
      return
    else
    end
    self._currentAbility = targetAbility
  end
  targetAbility:Start(onFinished, ...)
  if targetAbility.Update then
    table.insert(self._updateAbilities, targetAbility)
  end
  Log.DebugFormat("Cast Ability %s", targetAbility.name)
  return errorCode
end

function AbilityComponent:StopAbility(force, id)
  local ability
  if id then
    ability = self._abilities[id]
  else
    ability = self._currentAbility
  end
  if ability and not ability.isInPool then
    if ability.Finish then
      ability:Finish(force)
    else
      Log.ErrorFormat("ability %d no Finish function", ability.helper and ability.helper.config.id or 0)
    end
  end
end

function AbilityComponent:GetAbility(id)
  if not id then
    return
  end
  return self._abilities[id]
end

function AbilityComponent:GetAbilityInternal(id)
  local ability = self:GetAbility(id)
  if not ability then
    ability = self:GetAbilityFromPool(id)
    self._abilities[id] = ability
  end
  return ability
end

function AbilityComponent:GetAbilityFromPool(id)
  local playerModule = self.owner.module
  return playerModule.abilityPool:GetFromPool(id, self.owner)
end

function AbilityComponent:ReturnAbilityToPool(ability)
  if not ability or ability.isInPool then
    return
  end
  if not ability:IsCasting() then
    local playerModule = self.owner.module
    playerModule.abilityPool:ReturnToPool(ability)
    return
  end
  table.insert(self._abilities, ability)
end

function AbilityComponent:ReturnAbilityToPoolInternal(ability)
  if not ability or ability.isInPool then
    return
  end
  if ability:IsCasting() then
    ability:Interrupt()
  end
  local playerModule = self.owner.module
  playerModule.abilityPool:ReturnToPool(ability)
end

function AbilityComponent:GetAbilityByStatus(status, isAdd, subStatus)
  local abilityID = self:GetAbilityIDByStatus(status, isAdd, subStatus)
  if abilityID then
    return self:GetAbilityInternal(abilityID)
  end
  return nil
end

function AbilityComponent:GetAbilityIDByStatus(status, isAdd, subStatus)
  local abilities = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SCENE_ABILITY_CONF):GetAllDatas()
  for _, v in pairs(abilities) do
    local curConfig = v
    if isAdd then
      for _, curV in pairs(curConfig.add_status) do
        if curV == status and (0 == curConfig.add_sub_status or subStatus == curConfig.add_sub_status) then
          return curConfig.id
        end
      end
    else
      for _, curV in pairs(curConfig.remove_status) do
        if curV == status and (0 == curConfig.remove_sub_status or subStatus == curConfig.remove_sub_status) then
          return curConfig.id
        end
      end
    end
  end
  return nil
end

function AbilityComponent:OnStatusChanged(status, value, opCode, ...)
  local subStatus = value
  if opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD then
    local ability = self:GetAbilityByStatus(status, true, subStatus)
    if ability then
      self:CastAbility(ability, nil, ...)
    end
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE or opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_REMOVE then
    local ability = self:GetAbilityByStatus(status, true, subStatus)
    if ability and ability:IsCasting() then
      ability:Interrupt(...)
    else
      ability = self:GetAbilityByStatus(status, false, subStatus)
      if ability then
        self:CastAbility(ability, nil, ...)
      end
    end
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_OVERRIDE then
    local ability = self:GetAbilityByStatus(status, true, subStatus)
    if ability and ability:IsCasting() then
      ability:Interrupt(...)
    else
      ability = self:GetAbilityByStatus(status, false, subStatus)
      if ability then
        ability:Recover(self.owner, ...)
      end
    end
  elseif opCode == ProtoEnum.WPST_OpCode.WPST_OPCODE_RECOVER then
    local ability = self:GetAbilityByStatus(status, true, subStatus)
    if ability then
      ability:Recover(self.owner, ...)
    end
  end
end

function AbilityComponent:CanCastAbility(abilityHelper)
  if abilityHelper and self._currentAbility and not self:TempCheckIsRideThrow(abilityHelper) and self._currentAbility:IsCasting() and abilityHelper.config.priority >= self._currentAbility.helper.config.priority then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  return AbilityErrorCode.NO_ERROR
end

function AbilityComponent:GetAbilityCD(id, create)
  local cd = self._abilityCDs[id]
  if not cd and create then
    cd = AbilityCD(id)
    self._abilityCDs[id] = cd
  end
  return cd
end

function AbilityComponent:TickCD(deltaTime)
  for k, v in pairs(self._abilityCDs) do
    local cd = v
    cd:TickCD(deltaTime)
  end
end

function AbilityComponent:StartSuitPerform(skillId, petBaseId, petServerId, mutationType, glassInfo, nature, ball_id)
  if self._suitPerformAbility then
    self._suitPerformAbility:StartPerform(skillId, petBaseId, petServerId, mutationType, glassInfo, nature, ball_id)
  end
end

function AbilityComponent:StopSuitPerform()
  if self._suitPerformAbility then
    self._suitPerformAbility:InterruptPerform()
  end
end

function AbilityComponent:IsSuitPerforming()
  if self._suitPerformAbility then
    return self._suitPerformAbility:IsCasting()
  end
end

return AbilityComponent

local Base = require("NewRoco.AI.BehaviorTree.LuaServiceBase")
local MutualPerformComponent = require("NewRoco.Modules.Core.Scene.Component.AI.MutualPerformComponent")
local LuaServiceGlobalMutualExclusionPerformState = Base:Extend("LuaServiceGlobalMutualExclusionPerformState")

function LuaServiceGlobalMutualExclusionPerformState:OnStart(controller)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local owner = controller
  local npc = owner.Npc
  local serverId = npc:GetServerId()
  local mutualId = self.MutualId:GetValue(owner)
  local mutComp = player:EnsureComponent(MutualPerformComponent)
  local success, occupierObjId = mutComp:TryOccupy(mutualId, serverId)
  self.OutMutualSuccess:SetValue(owner, success)
  self.OutAlreadyMutualObject:SetValueById(owner, not success and occupierObjId or 0)
  self._mutualId = mutualId
  self._serverId = serverId
  
  function self._onMutualChangedHandler(_, changedMutualId, newOccupierObjId)
    self:OnMutualStateChanged(owner, changedMutualId, newOccupierObjId)
  end
  
  mutComp.OnMutualStateChanged:Add(self, self._onMutualChangedHandler)
end

function LuaServiceGlobalMutualExclusionPerformState:OnMutualStateChanged(owner, changedMutualId, newOccupierObjId)
  if changedMutualId ~= self._mutualId then
    return
  end
  if 0 == newOccupierObjId then
    self.OutAlreadyMutualObject:SetValueById(owner, 0)
  elseif newOccupierObjId ~= self._serverId then
    self.OutMutualSuccess:SetValue(owner, false)
    self.OutAlreadyMutualObject:SetValueById(owner, newOccupierObjId)
  end
end

function LuaServiceGlobalMutualExclusionPerformState:OnEnd(controller, Finalizing)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local mutComp = player:EnsureComponent(MutualPerformComponent)
  if self._onMutualChangedHandler then
    mutComp.OnMutualStateChanged:Remove(self, self._onMutualChangedHandler)
    self._onMutualChangedHandler = nil
  end
  if self._mutualId and self._serverId then
    mutComp:Release(self._mutualId, self._serverId)
  end
  self._mutualId = nil
  self._serverId = nil
  if not Finalizing then
    local owner = controller
    self.OutMutualSuccess:SetValue(owner, false)
    self.OutAlreadyMutualObject:SetValueById(owner, 0)
  end
end

return LuaServiceGlobalMutualExclusionPerformState

local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local Delegate = require("Utils.Delegate")
local MutualPerformComponent = Base:Extend("MutualPerformComponent")

function MutualPerformComponent:Attach(owner)
  Base.Attach(self, owner)
  self.mutualMap = {}
  self.OnMutualStateChanged = Delegate()
  self:UpdateData(self.owner.serverData)
end

function MutualPerformComponent:DeAttach()
  if self.OnMutualStateChanged then
    self.OnMutualStateChanged:Clear()
  end
  self.mutualMap = nil
  Base.DeAttach(self)
end

function MutualPerformComponent:UpdateData(ServerData, isReconnect)
  if not ServerData or not ServerData.avatar_ai_info then
    return
  end
  local mutualList = ServerData.avatar_ai_info.mutual_changed_list
  if not mutualList then
    return
  end
  for _, info in ipairs(mutualList) do
    self:ApplyMutualState(info.mutual_perform_id, info.npc_obj_id)
  end
end

function MutualPerformComponent:OnStateUpdate(action)
  if not action or not action.mutual_changed_list then
    return
  end
  for _, info in ipairs(action.mutual_changed_list) do
    self:ApplyMutualState(info.mutual_perform_id, info.npc_obj_id)
  end
end

function MutualPerformComponent:ApplyMutualState(mutualId, npcObjId)
  if not mutualId then
    return
  end
  local oldObjId = self.mutualMap[mutualId]
  if npcObjId and 0 ~= npcObjId then
    self.mutualMap[mutualId] = npcObjId
  else
    self.mutualMap[mutualId] = nil
  end
  if oldObjId ~= self.mutualMap[mutualId] then
    self.OnMutualStateChanged:Invoke(mutualId, self.mutualMap[mutualId] or 0)
  end
end

function MutualPerformComponent:TryOccupy(mutualId, npcObjId)
  local existingObjId = self.mutualMap[mutualId]
  if existingObjId and 0 ~= existingObjId then
    if existingObjId == npcObjId then
      return true, nil
    end
    return false, existingObjId
  end
  self.mutualMap[mutualId] = npcObjId
  return true, nil
end

function MutualPerformComponent:Release(mutualId, npcObjId)
  local existingObjId = self.mutualMap[mutualId]
  if existingObjId and existingObjId == npcObjId then
    self.mutualMap[mutualId] = nil
    self.OnMutualStateChanged:Invoke(mutualId, 0)
  end
end

function MutualPerformComponent:IsOccupied(mutualId)
  local existingObjId = self.mutualMap[mutualId]
  return nil ~= existingObjId and 0 ~= existingObjId
end

function MutualPerformComponent:GetOccupier(mutualId)
  return self.mutualMap[mutualId]
end

function MutualPerformComponent:IsOccupiedBy(mutualId, npcObjId)
  return self.mutualMap[mutualId] == npcObjId
end

return MutualPerformComponent

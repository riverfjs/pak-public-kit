local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ResQueue = require("NewRoco.Utils.ResQueue")
local Base = ActorComponent
local HoldingItemComponent = Base:Extend("HoldingItemComponent")

function HoldingItemComponent:Ctor()
  Base.Ctor(self)
  self.blackboard = {}
  self.loading_blackboard = {}
  self.request_map = {}
  self.wait_load_map = {}
  self.order_map = {}
end

function HoldingItemComponent:Attach(owner)
  Base.Attach(self, owner)
end

function HoldingItemComponent:DeAttach()
  self:ClearAllItem()
  Base.DeAttach(self)
end

function HoldingItemComponent:ClearAllItem()
  for key, value in pairs(self.blackboard) do
    self:DestroyItem(key)
  end
end

function HoldingItemComponent:Destroy()
  Base.Destroy(self)
end

function HoldingItemComponent:GetItemByKey(key)
  if self.blackboard[key] then
    return self.blackboard[key].item
  end
  return nil
end

function HoldingItemComponent:DestroyItem(key)
  local blackboard_info = self.blackboard[key]
  if blackboard_info then
    local item = blackboard_info.item
    if not blackboard_info.not_destroy and item and item.K2_DestroyActor and UE4.UObject.IsValid(item) then
      item:K2_DestroyActor()
    end
    blackboard_info.item = nil
    self.blackboard[key] = false
  end
end

function HoldingItemComponent:AddOrder(performers, caller, callback, priority)
  local order = ResQueue(30, ResQueue.RunMode.Concurrent, priority)
  for _, performer in ipairs(performers) do
    if not self:GetItemByKey(performer.key) then
      local position = _G.ProtoMessage:newPosition()
      position.x = -1000
      position.y = -1000
      position.z = -1000
      order:InsertNPC(performer.key, performer.npc_id, position, 0, nil)
    end
  end
  order.show_caller = caller
  order.show_callback = callback
  order:StartLoad(self, self.OnLoadFinished)
  self.order_map[order] = true
end

function HoldingItemComponent:OnLoadFinished(order, success)
  table.removeKey(self.order_map, order)
  if not success then
    Log.Error("\228\184\186\228\187\128\228\185\13630\231\167\146\232\191\152\229\138\160\232\189\189\228\184\141\229\135\186\230\157\165\229\149\138\229\149\138\229\149\138\229\149\138\229\149\138\229\149\138\239\188\140\232\191\153\229\144\136\231\144\134\229\144\151\239\188\140\232\191\153\228\184\128\231\130\185\228\185\159\228\184\141\229\144\136\231\144\134\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129")
  end
  for key, value in pairs(order.ResMap) do
    self.blackboard[key] = {
      item = value:Get().viewObj,
      key = key,
      id = value.ConfID
    }
  end
  local caller = order.show_caller
  local callback = order.show_callback
  order.show_caller = nil
  order.show_callback = nil
  order:Release()
  if caller and callback then
    callback(caller)
  end
end

function HoldingItemComponent:RegisterItem(key, value, modelId, not_destroy)
  self.blackboard[key] = {
    request = nil,
    item = value,
    key = key,
    id = 0,
    modelId = modelId,
    not_destroy = not_destroy
  }
end

function HoldingItemComponent:UnRegisterItem(key)
  self.blackboard[key] = false
end

function HoldingItemComponent:CancelAllOrder()
  local order, _ = next(self.order_map)
  while order do
    order:Release()
    self.order_map[order] = nil
    order, _ = next(self.order_map)
  end
end

return HoldingItemComponent

local LinkedList = require("Utils.LinkedList")
local Delegate = {}
Delegate.__index = Delegate
setmetatable(Delegate, {
  __call = function(class, ...)
    local instance = {List = nil}
    setmetatable(instance, Delegate)
    instance:New(...)
    return instance
  end
})

function Delegate:New(...)
  self.List = false
end

function Delegate:CompareItem(Item, Caller, Handler)
  return Item.caller == Caller and Item.handler == Handler
end

function Delegate:Add(caller, handler)
  if not self.List then
    self.List = LinkedList("Delegate")
  end
  local ExistingItem = self.List:FindValue(self, self.CompareItem, caller, handler)
  if ExistingItem then
    return
  end
  self.List:Insert({caller = caller, handler = handler})
end

function Delegate:Remove(caller, handler)
  if not self.List then
    return
  end
  local ExistingItem = self.List:FindValue(self, self.CompareItem, caller, handler)
  if not ExistingItem then
    return
  end
  self.List:Remove(ExistingItem)
end

function Delegate:Has(caller, handler)
  if not self.List then
    return false
  end
  local ExistingItem = self.List:FindValue(self, self.CompareItem, caller, handler)
  return nil ~= ExistingItem
end

function Delegate:Invoke(...)
  if not self.List then
    return
  end
  self.List:Iterate(self, self.InvokeItem, ...)
end

function Delegate:InvokeItem(Item, ...)
  if Item.caller then
    Item.handler(Item.caller, ...)
  else
    Item.handler(...)
  end
end

function Delegate:Clear()
  if not self.List then
    return
  end
  self.List:RemoveAll()
end

function Delegate:HasAny()
  if not self.List then
    return false
  end
  return self.List:HasAny()
end

return Delegate

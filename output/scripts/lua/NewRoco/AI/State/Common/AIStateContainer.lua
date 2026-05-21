local AIStateContainer = Class("AIStateContainer")

function AIStateContainer:StateOnInit(StateInstId, StateId, ScriptPath, Data)
  if not self.States then
    self.States = {}
  end
  local Clazz = require(string.format("NewRoco.AI.State.%s", ScriptPath))
  if not Clazz then
    Log.Error("AIStateContainer:StateInit failed, Clazz is nil")
    return
  end
  local StateInst = Clazz()
  if not StateInst then
    Log.Error("AIStateContainer:StateInit failed, StateInst is nil")
    return
  end
  StateInst.StateId = StateId
  StateInst.Container = self
  StateInst.Data = Data and Data:Unwrap()
  self.States[StateInstId] = StateInst
end

function AIStateContainer:StateOnReset(StateInstId)
  self.States[StateInstId] = nil
end

function AIStateContainer:StateOnLeave(StateInstId, Reason)
  local StateInst = self.States[StateInstId]
  if StateInst and StateInst.OnLeave then
    StateInst:OnLeave(Reason)
  end
end

function AIStateContainer:StateOnEnter(StateInstId)
  local StateInst = self.States[StateInstId]
  if StateInst and StateInst.OnEnter then
    StateInst:OnEnter()
  end
end

function AIStateContainer:StateOnEvent(StateInstId, EventId, Any)
  local StateInst = self.States[StateInstId]
  if StateInst and StateInst.OnEvent then
    StateInst:OnEvent(EventId, Any and Any:Unwrap())
  end
end

function AIStateContainer:FinishState(StateInst)
  if StateInst then
    self:LuaFinishState(StateInst.StateId)
  end
end

local ScopeLockMetatable = {
  __call = function(self)
    self.Container:LuaBeginScopeModify()
    return self
  end,
  __close = function(self)
    self.Container:LuaEndScopeModify()
    self.Container = nil
  end
}

function AIStateContainer:StateScopeLock()
  return setmetatable({Container = self, closed = false}, ScopeLockMetatable)()
end

local AIStateSpecBase = {}

function AIStateSpecBase:OnEnter()
end

function AIStateSpecBase:OnLeave(reason)
end

function AIStateSpecBase:OnEvent(event, any)
end

return AIStateContainer

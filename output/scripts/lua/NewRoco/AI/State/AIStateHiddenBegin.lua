local AIStateHiddenBegin = NRCClass()

function AIStateHiddenBegin:OnEnter()
  print("AIStateHiddenBegin:OnEnter")
  self.d = DelayManager:DelaySeconds(1, function()
    self.d = nil
    local Container = self.Container
    Container:LuaAddState(3002, AIDefines.DummyInstData)
  end)
end

function AIStateHiddenBegin:OnLeave()
  print("AIStateHiddenBegin:OnLeave")
  if self.d then
    DelayManager:CancelDelayById(self.d)
  end
end

function AIStateHiddenBegin:OnEvent(eventId, any)
  print("AIStateHiddenBegin:OnEvent", eventId, any)
end

return AIStateHiddenBegin

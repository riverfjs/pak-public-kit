local AIStateTestTranWithDelay = MakeSimpleClass("AIStateTestTranWithDelay")

function AIStateTestTranWithDelay:OnEnter()
  local time = self.Container:GetParamInt(self.StateId, 0)
  local next_state = self.Container:GetParamInt(self.StateId, 1)
  self.d_timer = DelayManager:DelaySeconds(time / 1000.0, function()
    self.d_timer = nil
    if next_state > 0 then
      self.Container:LuaAddState(next_state, AIDefines.DummyInstData)
    else
      self.Container:FinishState(self)
    end
  end)
end

function AIStateTestTranWithDelay:OnLeave()
  if self.d_timer then
    DelayManager:CancelDelay(self.d_timer)
    self.d_timer = nil
  end
end

return AIStateTestTranWithDelay

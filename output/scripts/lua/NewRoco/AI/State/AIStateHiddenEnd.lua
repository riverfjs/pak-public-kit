local AIStateHiddenEnd = MakeSimpleClass("AIStateHiddenEnd")

function AIStateHiddenEnd:Ctor()
  self.d_expire = nil
end

function AIStateHiddenEnd:OnEnter()
  print("AIStateHiddenEnd:OnEnter")
  self.d_expire = DelayManager:DelaySeconds(1, function()
    self.d_expire = nil
    self.Container:FinishState(self)
  end)
end

function AIStateHiddenEnd:OnLeave()
  print("AIStateHiddenEnd:OnLeave")
  if self.d_expire then
    DelayManager:CancelDelayById(self.d_expire)
    self.d_expire = nil
  end
end

return AIStateHiddenEnd

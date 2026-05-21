local AIStateStun = MakeSimpleClass("AIStateStun")

function AIStateStun:OnEnter()
  print("AIStateStun:OnEnter")
  self.Container:FinishState(self)
end

function AIStateStun:OnLeave()
  print("AIStateStun:OnLeave")
end

return AIStateStun

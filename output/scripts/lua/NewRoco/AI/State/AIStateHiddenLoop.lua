local AIStateHiddenLoop = MakeSimpleClass("AIStateHiddenLoop")

function AIStateHiddenLoop:OnEnter()
  print("AIStateHiddenLoop:OnEnter")
end

function AIStateHiddenLoop:OnLeave()
  print("AIStateHiddenLoop:OnLeave")
end

return AIStateHiddenLoop

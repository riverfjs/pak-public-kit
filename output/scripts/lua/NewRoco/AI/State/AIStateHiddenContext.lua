local AIStateHiddenContext = MakeSimpleClass("AIStateHiddenBegin")

function AIStateHiddenContext:OnEnter()
  print("AIStateHiddenContext:OnEnter")
end

function AIStateHiddenContext:OnLeave()
  print("AIStateHiddenContext:OnLeave")
end

return AIStateHiddenContext

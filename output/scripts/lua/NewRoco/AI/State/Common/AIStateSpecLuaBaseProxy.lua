require("UnLuaEx")
local AIStateSpecLuaBaseProxy = NRCClass()

function AIStateSpecLuaBaseProxy:Init()
  local Clazz = require(string.format("NewRoco.AI.State.%s", self.ScriptPath))
  if not Clazz then
    return
  end
  self.bind = Clazz()
  if self.bind then
    self.bind.proxy = self
  end
end

function AIStateSpecLuaBaseProxy:OnEnter()
  if self.bind and self.bind.OnEnter then
    self.bind:OnEnter()
  end
end

function AIStateSpecLuaBaseProxy:OnLeave(reason)
  if self.bind and self.bind.OnLeave then
    self.bind:OnLeave(reason)
  end
end

function AIStateSpecLuaBaseProxy:OnEvent(event, any)
  if self.bind and self.bind.OnEvent then
    self.bind:OnEvent(event, any.Data)
  end
end

return AIStateSpecLuaBaseProxy

local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionUpdateSensedPlayer = Base:Extend("LuaActionUpdateSensedPlayer")

function LuaActionUpdateSensedPlayer:OnStart(AIController, ...)
  self:Finish(true)
end

return LuaActionUpdateSensedPlayer

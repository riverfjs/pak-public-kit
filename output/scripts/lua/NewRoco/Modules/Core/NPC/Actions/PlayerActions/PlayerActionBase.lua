local Base = require("NewRoco.Modules.Core.NPC.Actions.CommonActionBase")
local PlayerActionBase = Base:Extend("PlayerActionBase")

function PlayerActionBase:Ctor(Owner, Config)
  Base.Ctor(self, Owner, Config)
end

function PlayerActionBase:Execute()
  self:RegisterThisActionToPlayer()
end

function PlayerActionBase:Finish()
  self:UnregisterThisActionToPlayer()
end

return PlayerActionBase

local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local M = Base:Extend("NPCActionGashaponMachine")

function M:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  local owner = self:GetOwnerNPC()
  if owner then
  end
  if not owner or owner.InteractionComponent then
  end
end

return M

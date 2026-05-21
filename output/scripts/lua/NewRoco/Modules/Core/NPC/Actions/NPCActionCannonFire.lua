require("UnLua")
local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCActionCannonFire = Base:Extend("NPCActionCannonFire")

function NPCActionCannonFire:Ctor(Owner, Config, Info, view)
  Base.Ctor(self, Owner, Config, Info, view)
end

function NPCActionCannonFire:Execute(npc)
  Base.Execute(self, nil, false)
  if npc then
    npc:OnActionFire()
  end
end

return NPCActionCannonFire

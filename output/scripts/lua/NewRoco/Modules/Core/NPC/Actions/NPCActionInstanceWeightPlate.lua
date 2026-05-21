local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCActionInstanceWeightPlate = Base:Extend("NPCActionBattle")

function NPCActionInstanceWeightPlate:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function NPCActionInstanceWeightPlate:Execute()
  Log.Error("NPCActionInstanceWeightPlate \229\183\178\231\187\143\229\186\159\229\188\131\239\188\140\229\166\130\233\156\128\229\144\175\231\148\168\232\175\183\230\143\144\233\156\128\230\177\130")
  Base.Execute(self)
end

return NPCActionInstanceWeightPlate

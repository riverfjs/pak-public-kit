local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionAsyncBase")
local NPCActionGrassTrialNode = Base:Extend("NPCActionGrassTrialNode")

function NPCActionGrassTrialNode:OnPerformReady(_, _)
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.OpenChooseEnemyPanel, self)
end

return NPCActionGrassTrialNode

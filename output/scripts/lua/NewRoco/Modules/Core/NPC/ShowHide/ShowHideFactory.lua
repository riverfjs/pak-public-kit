local ShowHideFactory = {}
ShowHideFactory.Registry = {
  [Enum.PlayerConditionType.PCT_OPTION] = require("NewRoco.Modules.Core.NPC.ShowHide.DialogueShowHide"),
  [Enum.PlayerConditionType.PCT_MINI_GAME] = require("NewRoco.Modules.Core.NPC.ShowHide.MiniGameShowHide"),
  [Enum.PlayerConditionType.PCT_BATTLE] = require("NewRoco.Modules.Core.NPC.ShowHide.BattleShowHide"),
  [Enum.PlayerConditionType.PCT_CG] = require("NewRoco.Modules.Core.NPC.ShowHide.CinematicShowHide"),
  [Enum.PlayerConditionType.PCT_MATCHING] = require("NewRoco.Modules.Core.NPC.ShowHide.BattlePvpRankMatchingShowHide"),
  [Enum.PlayerConditionType.PCT_LEGENDARY_BATTLE_ENTRENCE] = require("NewRoco.Modules.Core.NPC.ShowHide.LegendaryBattleHide"),
  [Enum.PlayerConditionType.PCT_EDITING_HOME] = require("NewRoco.Modules.Core.NPC.ShowHide.HomeEditShowHide"),
  [Enum.PlayerConditionType.PCT_PVP_RANK_MAIN_UI] = require("NewRoco.Modules.Core.NPC.ShowHide.BattlePvpRankMatchingShowHide"),
  [Enum.PlayerConditionType.PCT_WORLD_COMBATING] = require("NewRoco.Modules.Core.NPC.ShowHide.WorldCombatShowHide")
}
ShowHideFactory.Instances = {}

function ShowHideFactory.Get(Status)
  if ShowHideFactory.Instances[Status] then
    return ShowHideFactory.Instances[Status]
  end
  if not ShowHideFactory.Registry[Status] then
    return nil
  end
  local Instance = ShowHideFactory.Registry[Status]()
  ShowHideFactory.Instances[Status] = Instance
  return Instance
end

function ShowHideFactory.GetInstances()
  return ShowHideFactory.Instances
end

return ShowHideFactory

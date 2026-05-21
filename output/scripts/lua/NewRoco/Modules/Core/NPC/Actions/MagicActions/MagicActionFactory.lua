local MagicActionBase = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase")
local MagicActionFactory = {}
MagicActionFactory.Registry = {
  [Enum.ActionType.ACT_STAR_HIT_PET] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_ITEM_BURST] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionItemBurst"),
  [Enum.ActionType.ACT_STAR_HIT_FRUITTREE] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionStarHitFruitTree"),
  [Enum.ActionType.ACT_STAR_HIT_SHRUB] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionStarHitShrub"),
  [Enum.ActionType.ACT_STAR_UNLOCK_OWL] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_STAR_UNLOCK_SANCTUARY] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_WIND_TUNNEL] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionWindTunnel"),
  [Enum.ActionType.ACT_WIND_UNLOCK_OWL] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_STAR_HIT_DIRECTION] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_MAGIC_STAR] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_WORLD_COMBAT_BEGIN] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase"),
  [Enum.ActionType.ACT_STAR_DESTROY_NIGHTMARE] = require("NewRoco.Modules.Core.NPC.Actions.MagicActionCleanNightmare"),
  [Enum.ActionType.ACT_TIMER_STAR_MAGIC] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionTimerStarMagic"),
  [Enum.ActionType.ACT_TRIGGER_OPTION_ACTION] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionTriggerOption"),
  [Enum.ActionType.ACT_MAGIC_REVEAL] = require("NewRoco.Modules.Core.NPC.Actions.NPCActionMagicReveal"),
  [Enum.ActionType.ACT_MAGIC_REVEAL_FAILED] = require("NewRoco.Modules.Core.NPC.Actions.NPCActionMagicRevealFailed"),
  [Enum.ActionType.ACT_STAR_DESTROY_NIGHTMARE_BIGWORLD] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionCleanNightmareBigWorld"),
  [Enum.ActionType.ACT_CAGE_BREAK] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBreakCage"),
  [Enum.ActionType.ACT_WORLD_COMBAT_BOSS] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionWorldCombatBossShield"),
  [Enum.ActionType.ACT_HOME_PLANT_UNLOCK_NPC_ENTRANCE] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionHomePlantUnlockEntrance"),
  [Enum.ActionType.ACT_CHANGE_CONTENT_SIZE_EFFECT] = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionChangeContentSizeEffect")
}

function MagicActionFactory:Get(Option, Action, Info, DontCreate)
  local ActionType = Action.action_type
  local ActionKlass = MagicActionFactory.Registry[ActionType]
  ActionKlass = ActionKlass or MagicActionBase
  return ActionKlass(Option, Action, Option.optionInfo.cur_action_info)
end

return MagicActionFactory

local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineHideUIEvent = Base:Extend("DialogueTimelineHidUIEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineHideUIEvent, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = -100,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = -1,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  }
})

function DialogueTimelineHideUIEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineHideUIEvent:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue or BattleAutoTest and BattleAutoTest.IsAutoBattle then
    self:Finish()
    return
  end
  _G.NRCModeManager:DoCmd(DialogueModuleCmd.CloseMainPanel)
  self:Finish()
end

function DialogueTimelineHideUIEvent:OnFinish()
  Base.OnFinish(self)
end

return DialogueTimelineHideUIEvent

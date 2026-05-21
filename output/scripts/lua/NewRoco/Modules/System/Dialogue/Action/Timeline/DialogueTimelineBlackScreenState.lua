local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineBlackScreenState = Base:Extend("DialogueTimelineBlackScreenState")
FsmUtils.MergeMembers(Base, DialogueTimelineBlackScreenState, {
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

function DialogueTimelineBlackScreenState:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineBlackScreenState:OnEnter()
  Base.OnEnter(self)
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  NRCModuleManager:DoCmd(DialogueModuleCmd.FadeInDialogueCameraBlack)
end

function DialogueTimelineBlackScreenState:OnFinish()
  NRCModuleManager:DoCmd(DialogueModuleCmd.FadeOutDialogueCameraBlack)
  Base.OnFinish(self)
end

return DialogueTimelineBlackScreenState

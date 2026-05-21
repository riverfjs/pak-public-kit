local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineB1FinalBattleTwoCameraEvent = Base:Extend("DialogueTimelineHidUIEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineB1FinalBattleTwoCameraEvent, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = -101,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = -1,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  }
})

function DialogueTimelineB1FinalBattleTwoCameraEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineB1FinalBattleTwoCameraEvent:OnEnter()
  self:InjectProperties()
  _G.NRCModuleManager:DoCmd(_G.B1FinalBattleModuleCmd.OpenTwoPetDialogueCamera)
  Log.Info("DialogueTimelineB1FinalBattleTwoCameraEvent:OnEnter, start at ", self.state.execTime)
end

function DialogueTimelineB1FinalBattleTwoCameraEvent:OnFinish()
  Base.OnFinish(self)
end

return DialogueTimelineB1FinalBattleTwoCameraEvent

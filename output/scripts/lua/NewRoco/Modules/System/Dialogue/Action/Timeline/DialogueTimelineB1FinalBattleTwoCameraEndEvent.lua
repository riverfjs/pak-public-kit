local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineB1FinalBattleTwoCameraEndEvent = Base:Extend("DialogueTimelineHidUIEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineB1FinalBattleTwoCameraEndEvent, {
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

function DialogueTimelineB1FinalBattleTwoCameraEndEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineB1FinalBattleTwoCameraEndEvent:OnEnter()
  self:InjectProperties()
  _G.NRCModuleManager:DoCmd(_G.B1FinalBattleModuleCmd.CloseTwoScreenDialogue)
  _G.NRCModuleManager:DoCmd(_G.B1FinalBattleModuleCmd.ClearDialogueCamera)
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPet(nil, nil, nil, nil, nil, true)
  Log.Info("DialogueTimelineB1FinalBattleTwoCameraEndEvent:OnEnter, end at ", self.state.execTime)
end

function DialogueTimelineB1FinalBattleTwoCameraEndEvent:OnFinish()
  Base.OnFinish(self)
end

return DialogueTimelineB1FinalBattleTwoCameraEndEvent

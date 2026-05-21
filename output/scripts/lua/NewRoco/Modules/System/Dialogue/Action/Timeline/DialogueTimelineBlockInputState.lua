local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineBlockInputState = Base:Extend("DialogueTimelineBlockInputState")
FsmUtils.MergeMembers(Base, DialogueTimelineBlockInputState, {
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

function DialogueTimelineBlockInputState:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.bIsNeedCheckInputBlocker = true
end

function DialogueTimelineBlockInputState:OnEnter()
  Base.OnEnter(self)
  Log.Debug("DialogueTimelineBlockInputState:OnEnter")
  if DialogueUtils.SkipDialogue then
    Log.Debug("DialogueTimelineBlockInputState:OnEnter SkipDialogue")
    self:Finish()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "DialogueModule.TimelineBlockInputAction")
end

function DialogueTimelineBlockInputState:OnFinish()
  Log.Debug("DialogueTimelineBlockInputState:OnFinish")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "DialogueModule.TimelineBlockInputAction")
  self.bIsNeedCheckInputBlocker = false
  Base.OnFinish(self)
end

function DialogueTimelineBlockInputState:OnExit()
  if self.bIsNeedCheckInputBlocker then
    Log.Debug("DialogueTimelineBlockInputState:OnExit")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "DialogueModule.TimelineBlockInputAction")
  end
  Base.OnExit(self)
end

return DialogueTimelineBlockInputState

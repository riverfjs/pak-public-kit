local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueTimelineActionEvent = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local Base = DialogueTimelineActionEvent
local DialogueTimelineStopLookAtEvent = Base:Extend("DialogueTimelineStopLookAtEvent")

function DialogueTimelineStopLookAtEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineStopLookAtEvent:OnEnter()
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  DialogueUtils.StopLookAt(Actor)
end

return DialogueTimelineStopLookAtEvent

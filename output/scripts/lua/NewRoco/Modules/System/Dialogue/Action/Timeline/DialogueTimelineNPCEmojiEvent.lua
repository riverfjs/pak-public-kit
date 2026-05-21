local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BubbleComponent = require("NewRoco.Modules.Core.Scene.Component.Bubble.BubbleComponent")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCEmojiEvent = Base:Extend("DialogueTimelineNPCEmojiEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCEmojiEvent, {
  {
    name = "Emotion",
    type = "Enum.EmotionType",
    default = Enum.EmotionType.EMT_NONE,
    display_name = "\232\161\168\230\131\133"
  }
})

function DialogueTimelineNPCEmojiEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCEmojiEvent:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if actor then
    local Comp = actor:EnsureComponent(BubbleComponent)
    if self.Emotion then
      if Comp:IsPlaying() then
        Comp:StopAll()
      end
      Comp:Play(nil, self.Emotion)
    end
  end
end

return DialogueTimelineNPCEmojiEvent

local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCPerformAnimAction = Base:Extend("DialogueTimelineNPCPerformAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCPerformAnimAction, {
  {
    name = "PerformID",
    type = "SheetRef.PERFORM_CONF",
    default = 0,
    display_name = "PerformID"
  }
})

function DialogueTimelineNPCPerformAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCPerformAnimAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  local View = DialogueUtils.ExtraActorView(Actor)
  if View then
    actor.DialogueTimelineTransformCache = View:GetTransform()
  end
  self:ConsumeActorPerform(actor)
end

function DialogueTimelineNPCPerformAnimAction:ConsumeActorPerform(Actor)
  if not Actor then
    return
  end
  if not Actor.PlayShowById then
    return
  end
  local performConf = _G.DataConfigManager:GetPerformConf(self.PerformID)
  if performConf then
    Actor:PlayShowById(performConf)
  end
end

function DialogueTimelineNPCPerformAnimAction:OnFinish()
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if actor then
    actor.DialogueTimelineTransformCache = nil
  end
  Base.OnFinish(self)
end

return DialogueTimelineNPCPerformAnimAction

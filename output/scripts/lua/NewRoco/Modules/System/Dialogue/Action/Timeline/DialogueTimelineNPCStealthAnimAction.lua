local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCStealthAnimAction = Base:Extend("DialogueTimelineNPCStealthAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCStealthAnimAction, {
  {
    name = "ToggleStealth",
    type = "bool",
    default = true,
    display_name = "true=\229\188\128\229\167\139\229\140\191\232\184\170 or false=\232\167\163\233\153\164\229\140\191\232\184\170"
  }
})

function DialogueTimelineNPCStealthAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCStealthAnimAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  self:ConsumeActorPerform(actor)
end

function DialogueTimelineNPCStealthAnimAction:ConsumeActorPerform(Actor)
  if not Actor then
    return
  end
  local HidComp = Actor:GetComponent(HiddenComponent)
  if not HidComp then
    return
  end
  if not HidComp:CanHide() then
    return
  end
  if self.ToggleStealth then
    HidComp:BeginHide()
  else
    HidComp:EndHide(self, function()
    end)
  end
  if Actor.AIComponent then
    self.DialogueConf = self.fsm:GetProperty("DialogueConf")
    Actor.AIComponent:OnHiddenStatusChangedInDialogue(self.ToggleStealth, self.DialogueConf and self.DialogueConf.id or 0)
  end
end

return DialogueTimelineNPCStealthAnimAction

local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCHideAnimAction = Base:Extend("DialogueTimelineNPCHideAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCHideAnimAction, {
  {
    name = "ToggleHidden",
    type = "bool",
    default = true,
    display_name = "true=\233\154\144\232\151\143 or false=\230\152\190\231\164\186"
  }
})

function DialogueTimelineNPCHideAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCHideAnimAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    return
  end
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    Log.Warning("\230\136\152\230\150\151\228\184\173\230\151\160\230\179\149\228\189\191\231\148\168\232\167\146\232\137\178\233\154\144\232\151\143\229\138\159\232\131\189")
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  self:ConsumeActorPerform(actor)
end

function DialogueTimelineNPCHideAnimAction:ConsumeActorPerform(Actor)
  if not Actor then
    return
  end
  if Actor.SetHidden then
    Actor:SetHidden(self.ToggleHidden, NPCModuleEnum.NpcReasonFlags.DIALOGUE)
  else
    Actor:SetVisible(not self.ToggleHidden)
  end
end

return DialogueTimelineNPCHideAnimAction

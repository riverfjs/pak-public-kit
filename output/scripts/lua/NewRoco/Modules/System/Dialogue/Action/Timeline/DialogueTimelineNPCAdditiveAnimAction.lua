local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineNPCAdditiveAnimAction = Base:Extend("DialogueTimelineNPCAdditiveAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCAdditiveAnimAction, {
  {
    name = "Action",
    type = "string",
    default = "",
    display_name = "\229\138\168\231\148\187"
  },
  {
    name = "Rate",
    type = "float",
    default = 1.0,
    display_name = "\230\146\173\230\148\190\233\128\159\231\142\135"
  },
  {
    name = "BlendInTime",
    type = "float",
    default = 0.2,
    display_name = "\230\183\161\229\133\165\230\151\182\233\151\180"
  },
  {
    name = "BlendOutTime",
    type = "float",
    default = 0.2,
    display_name = "\230\183\161\229\135\186\230\151\182\233\151\180"
  },
  {
    name = "StopAnimAtEnd",
    type = "bool",
    default = true,
    display_name = "\231\187\147\230\157\159\230\151\182\229\129\156\230\173\162"
  }
})

function DialogueTimelineNPCAdditiveAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCAdditiveAnimAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if not Actor then
    self:Finish()
    return
  end
  if string.IsNilOrEmpty(self.Action) then
    self:Finish()
    return
  end
  local AnimComp = Actor.GetAnimComponent and Actor:GetAnimComponent()
  if not AnimComp then
    self:Finish()
    return
  end
  if Actor.PlayAdditiveAnim then
    Actor:PlayAdditiveAnim(self.Action, self.Rate, self.BlendInTime, self.BlendOutTime)
  end
end

function DialogueTimelineNPCAdditiveAnimAction:OnFinish()
  if not self.StopAnimAtEnd then
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if actor.StopAdditiveAnim then
    actor:StopAdditiveAnim(self.Action, self.BlendOutTime)
  end
end

return DialogueTimelineNPCAdditiveAnimAction

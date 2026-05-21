local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCShakeHeadAnimAction = Base:Extend("DialogueTimelineNPCShakeHeadAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCShakeHeadAnimAction, {
  {
    name = "ShakeHead",
    type = "Enum.HeadMotion",
    default = Enum.HeadMotion.NoHeadMotion,
    display_name = "\230\152\175\229\144\166\230\145\135\229\164\180"
  }
})

function DialogueTimelineNPCShakeHeadAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCShakeHeadAnimAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    return
  end
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    Log.Warning("\230\136\152\230\150\151\229\143\175\232\131\189\230\178\161\230\156\137\231\130\185\229\164\180\230\145\135\229\164\180\229\138\159\232\131\189\239\188\140\229\166\130\230\158\156\232\161\168\231\142\176\230\156\137\233\151\174\233\162\152\232\175\183\231\187\153\229\188\128\229\143\145\230\143\144\233\156\128\230\177\130\239\188\140\232\176\162\232\176\162")
  end
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if Actor then
    Actor:DoHeadMotion(self.ShakeHead or Enum.HeadMotion.Shake)
  end
end

return DialogueTimelineNPCShakeHeadAnimAction

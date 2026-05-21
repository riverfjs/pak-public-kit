local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineNPCActorAnimAction = Base:Extend("DialogueTimelineNPCActorAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCActorAnimAction, {
  {
    name = "Action",
    type = "AnimName",
    default = "",
    display_name = "\229\138\168\231\148\187"
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
    name = "LoopCount",
    type = "int",
    default = 1,
    display_name = "\229\190\170\231\142\175\230\172\161\230\149\176"
  },
  {
    name = "StartPoint",
    type = "float",
    default = 0,
    display_name = "\232\181\183\231\130\185"
  },
  {
    name = "EndPoint",
    type = "float",
    default = 0,
    display_name = "\231\155\184\229\175\185\231\187\136\231\130\185\230\143\144\229\137\141\231\187\147\230\157\159\230\151\182\233\151\180)"
  },
  {
    name = "StopAnimAtEnd",
    type = "bool",
    default = false,
    display_name = "\231\187\147\230\157\159\230\151\182\229\129\156\230\173\162\229\138\168\231\148\187"
  },
  {
    name = "StopAnimAtTimelineEnd",
    type = "bool",
    default = false,
    display_name = "\231\187\147\230\157\159\230\137\128\229\156\168Timeline\230\151\182\229\129\156\230\173\162\229\138\168\231\148\187"
  }
})

function DialogueTimelineNPCActorAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCActorAnimAction:OnEnter()
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
  local AnimLength = AnimComp:GetAnimLengthByName(self.Action)
  local StartPos = self.StartPoint
  local EndPos = self.EndPoint
  StartPos = math.max(StartPos, 0)
  EndPos = math.max(EndPos, 0)
  if EndPos >= 0 and AnimLength > 0.0 then
    EndPos = math.max(AnimLength - EndPos, 0.0)
  end
  local Rate = 1.0
  if StartPos < EndPos and self:GetEndTime() > self:GetStartTime() then
    Rate = math.max((EndPos - StartPos) / (self:GetEndTime() - self:GetStartTime()), 0.0)
  end
  if StartPos < 0.0 and EndPos < 0.0 and AnimLength > 0.0 then
    Rate = math.max(AnimLength / (self:GetEndTime() - self:GetStartTime()), 0.0)
  end
  if self.properties.Rate then
    Rate = self.properties.Rate
  end
  local LinkTag = Actor.name == "SceneLocalPlayer" and "Locomotion" or "None"
  if Actor.PlayAnim then
    Actor:PlayAnim(self.Action, Rate, StartPos, self.BlendInTime, self.BlendOutTime, self.LoopCount, EndPos, LinkTag)
    if self.StopAnimAtTimelineEnd then
      local ActorsToStopAnim = self.fsm:GetProperty("ActorsToStopAnim") or {}
      table.insert(ActorsToStopAnim, Actor)
      self.fsm:SetProperty("ActorsToStopAnim", ActorsToStopAnim)
    end
  end
end

function DialogueTimelineNPCActorAnimAction:OnFinish()
  if not self.StopAnimAtEnd then
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  DialogueUtils.StopAnim(actor, self.BlendOutTime)
end

return DialogueTimelineNPCActorAnimAction

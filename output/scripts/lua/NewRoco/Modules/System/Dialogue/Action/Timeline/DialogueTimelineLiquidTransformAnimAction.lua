local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineLiquidTransformAnimAction = Base:Extend("DialogueTimelineLiquidTransformAnimAction")
FsmUtils.MergeMembers(Base, DialogueTimelineLiquidTransformAnimAction, {
  {
    name = "Action",
    type = "PetAnimName",
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
    default = true,
    display_name = "\231\187\147\230\157\159\230\151\182\229\129\156\230\173\162\229\138\168\231\148\187"
  }
})

function DialogueTimelineLiquidTransformAnimAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineLiquidTransformAnimAction:OnEnter()
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
  local AsPet = Actor.viewObj.BP_RideComponent and Actor.viewObj.BP_RideComponent.RidePet
  if not AsPet then
    if Actor.GetName then
      Log.WarningFormat("Actor %s have not transform into pet, skip pet anim!", Actor:GetName())
    end
    self:Finish()
    return
  end
  local AnimComp = AsPet.RocoAnim
  if not AnimComp then
    self:Finish()
    return
  end
  if not AnimComp:HasAnimation(self.Action) then
    Log.WarningFormat("Liquid transform pet of actor %s has no animation %s!", Actor:GetName(), self.Action)
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
  local LinkTag = "None"
  if Actor.PlayAnim then
    AnimComp:PlayAnimByName(self.Action, Rate, StartPos, self.BlendInTime, self.BlendOutTime, self.LoopCount, EndPos, LinkTag)
  end
end

function DialogueTimelineLiquidTransformAnimAction:OnFinish()
  if not self.StopAnimAtEnd then
    return
  end
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if not Actor then
    return
  end
  local AsPet = Actor.viewObj.BP_RideComponent and Actor.viewObj.BP_RideComponent.RidePet
  if not AsPet then
    return
  end
  local AnimComp = AsPet.RocoAnim
  if not AnimComp then
    return
  end
  AnimComp:StopAllMontage(self.BlendOutTime or 0.1)
end

return DialogueTimelineLiquidTransformAnimAction

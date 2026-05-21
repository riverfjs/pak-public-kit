local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCSetLocationEvent = Base:Extend("DialogueTimelineNPCSetLocationEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCSetLocationEvent, {
  {
    name = "TargetLocation",
    type = "ActorLocation",
    display_name = "\231\155\174\230\160\135\228\189\141\231\189\174"
  },
  {
    name = "TargetRotation",
    type = "ActorRotation",
    display_name = "\231\155\174\230\160\135\230\156\157\229\144\145"
  },
  {
    name = "ReportLocation",
    type = "bool",
    display_name = "\230\152\175\229\144\166\228\184\138\230\138\165\228\189\141\231\189\174\229\143\152\229\140\150",
    default = false
  },
  {
    name = "PinOnGround",
    type = "bool",
    display_name = "\230\152\175\229\144\166\232\180\180\229\156\176",
    default = true
  }
})

function DialogueTimelineNPCSetLocationEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

local TempExclude = {}

function DialogueTimelineNPCSetLocationEvent:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    return
  end
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if nil == Actor then
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  local UERotation = DialogueUtils.ParseActorRotation(self.TargetRotation, Actor)
  local UELocation = DialogueUtils.ParseActorLocation(self.TargetLocation, Actor)
  if nil == UERotation or nil == UELocation then
    return
  end
  local Transform = self.fsm:GetProperty("BornTransform", Actor:GetActorTransform())
  local RelativeTransform = UE4.FTransform(UERotation:ToQuat(), UELocation)
  local WorldTransform = RelativeTransform * Transform
  local Location
  if self.PinOnGround then
    local Name = ""
    if Actor.className == "SceneNpc" and Actor.DebugNPCNameAndID then
      Name = Actor:DebugNPCNameAndID()
    elseif Actor.className == "BattlePet" and Actor.GetName then
      Name = Actor:GetName()
    else
      Name = Actor.className
    end
    local HalfHeight = Actor:GetHalfHeight()
    local WorldContext = View or _G.UE4Helper.GetCurrentWorld()
    table.insert(TempExclude, View)
    Location = UE.UNRCStatics.GetPosInNearLand(WorldContext, WorldTransform.Translation, HalfHeight, TempExclude)
    table.clear(TempExclude)
    if Location then
      Log.DebugFormat("%s\232\191\155\232\161\140\232\180\180\229\156\176,\229\141\138\233\171\152:%f,\229\137\141:%f,\229\144\142:%f,\229\183\174:%f", Name, HalfHeight, WorldTransform.Translation.Z, Location.Z, Location.Z - WorldTransform.Translation.Z)
    else
      Location = WorldTransform.Translation
      Log.DebugFormat("%s\232\191\155\232\161\140\232\180\180\229\156\176,\229\141\138\233\171\152:%f,\229\164\177\232\180\165%s", Name, HalfHeight, tostring(Location))
    end
  else
    Location = WorldTransform.Translation
  end
  Actor:SetActorLocation(Location)
  local TargetRotator = WorldTransform.Rotation:ToRotator()
  Actor:SetActorRotation(TargetRotator)
  if self.ReportLocation then
    if Actor.name == "SceneLocalPlayer" then
      if Actor.ForceSendMoveReq and not self.fsm:GetProperty("PlayerPosSyncBlocker") then
        Actor:ForceSendMoveReq(true)
      end
    elseif Actor.ReportPosition and not self.fsm:GetProperty("PlayerPosSyncBlocker") then
      Actor:ReportPosition(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE, false)
    end
  end
end

return DialogueTimelineNPCSetLocationEvent

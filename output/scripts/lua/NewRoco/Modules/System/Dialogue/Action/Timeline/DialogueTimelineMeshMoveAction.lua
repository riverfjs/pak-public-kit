local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineMeshMoveAction = Base:Extend("DialogueTimelineMeshMoveAction")
FsmUtils.MergeMembers(Base, DialogueTimelineMeshMoveAction, {
  {
    name = "bMove",
    type = "bool",
    display_name = "\230\152\175\229\144\166\231\167\187\229\138\168",
    default = true
  },
  {
    name = "TargetLocation",
    type = "ActorLocation",
    display_name = "\231\155\174\230\160\135\228\189\141\231\189\174"
  },
  {
    name = "bRotate",
    type = "bool",
    display_name = "\230\152\175\229\144\166\230\151\139\232\189\172",
    default = false
  },
  {
    name = "TargetRotation",
    type = "ActorRotation",
    display_name = "\231\155\174\230\160\135\230\156\157\229\144\145"
  },
  {
    name = "bReportPos",
    type = "bool",
    display_name = "\230\152\175\229\144\166\228\184\138\230\138\165\228\189\141\231\189\174\230\148\185\229\143\152",
    default = true
  }
})

function DialogueTimelineMeshMoveAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineMeshMoveAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    Log.Debug("DialogueTimelineMeshMoveAction:OnEnter, skip")
    self:Finish()
    return
  end
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    Log.Warning("\230\136\152\230\150\151\228\184\173\230\151\160\230\179\149\228\189\191\231\148\168\232\167\146\232\137\178\231\167\187\229\138\168\229\138\159\232\131\189")
    self:Finish()
    return
  end
  if not self.bMove and not self.bRotate then
    Log.Debug("DialogueTimelineMeshMoveAction:OnEnter, no move or rotate")
    self:Finish()
    return
  end
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if not Actor then
    Log.Debug("DialogueTimelineMeshMoveAction:OnEnter, no actor")
    self:Finish()
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if View then
    Actor.DialogueTimelineTransformCache = View:GetTransform()
  end
  local UERotation = DialogueUtils.ParseActorRotation(self.TargetRotation, Actor)
  local UELocation = DialogueUtils.ParseActorLocation(self.TargetLocation, Actor)
  if nil == UERotation or nil == UELocation then
    Log.Debug("DialogueTimelineMeshMoveAction:OnEnter, no location or rotation")
    self:Finish()
    return
  end
  local Transform = self.fsm:GetProperty("BornTransform")
  local RelativeTransform = UE4.FTransform(UERotation:ToQuat(), UELocation)
  self.TargetTransform = RelativeTransform * Transform
  self.TargetTransform.Translation = SceneUtils.ConvertAbsoluteToRelative(self.TargetTransform.Translation)
  self:OnTick(0.0)
end

function DialogueTimelineMeshMoveAction:OnTick(DeltaTime)
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if not Actor then
    Log.Debug("DialogueTimelineMeshMoveAction:OnTick, no actor")
    self:Finish()
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if not View then
    Log.Debug("DialogueTimelineMeshMoveAction:OnTick, no view")
    self:Finish()
    return
  end
  if not self.TargetTransform then
    Log.Debug("DialogueTimelineMeshMoveAction:OnTick, no target transform")
    self:Finish()
    return
  end
  local RemainingTime = self.EndTime - self.state.execTime
  if RemainingTime < 0.0 then
    Log.Debug("DialogueTimelineMeshMoveAction:OnTick, no remaining time", self.EndTime, self.state.execTime)
    self:Finish()
    return
  end
  if DeltaTime > RemainingTime then
    DeltaTime = RemainingTime
  end
  if DeltaTime < 0.001 then
    Log.Debug("DialogueTimelineMeshMoveAction:OnTick, no delta time")
    return
  end
  if self.bMove then
    local ViewLocation = View:K2_GetActorLocation()
    local NextLocation = UE4.UKismetMathLibrary.VLerp(ViewLocation, self.TargetTransform.Translation, DeltaTime / RemainingTime)
    local HitResult = UE4.FHitResult()
    View:K2_SetActorLocation(NextLocation, false, HitResult, true)
  end
  if self.bRotate then
    local ViewRotation = View:K2_GetActorRotation()
    local NextRotation = UE4.UKismetMathLibrary.RLerp(ViewRotation, self.TargetTransform.Rotation:ToRotator(), DeltaTime / RemainingTime, true)
    View:K2_SetActorRotation(NextRotation, true)
  end
  Log.InfoFormat("DialogueTimelineMeshMoveAction:OnTick, move mesh %f", DeltaTime)
  if RemainingTime - DeltaTime <= 0.0 then
    Log.InfoFormat("DialogueTimelineMeshMoveAction:OnTick, finish")
    self:Finish()
    return
  end
end

function DialogueTimelineMeshMoveAction:OnFinish()
  local Actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if Actor then
    Actor.DialogueTimelineTransformCache = nil
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if View and self.TargetTransform then
    if self.bMove then
      local NextLocation = self.TargetTransform.Translation
      local HitResult = UE4.FHitResult()
      View:K2_SetActorLocation(NextLocation, false, HitResult, true)
    end
    if self.bRotate then
      local NextRotation = self.TargetTransform.Rotation:ToRotator()
      View:K2_SetActorRotation(NextRotation, true)
    end
    if self.bReportPos and Actor.ReportPosition and not self.fsm:GetProperty("PlayerPosSyncBlocker") then
      Actor:ReportPosition(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE, false)
    end
  end
  Base.OnFinish(self)
end

return DialogueTimelineMeshMoveAction

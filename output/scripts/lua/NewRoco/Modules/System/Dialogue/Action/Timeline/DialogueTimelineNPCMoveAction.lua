local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")

local function MakeMoveData(Character, Transform)
  return {
    Character = Character,
    Location = Transform.Translation,
    bStartMoveSuccess = false,
    bTurnFinished = false,
    Transform = Transform
  }
end

local DialogueTimelineNPCMoveAction = Base:Extend("DialogueTimelineNPCMoveAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCMoveAction, {
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
    name = "UseCustomStartLocation",
    type = "bool",
    default = false,
    display_name = "\230\152\175\229\144\166\230\140\135\229\174\154\232\181\183\229\167\139\228\189\141\231\189\174"
  },
  {
    name = "StartLocation",
    type = "ActorLocation",
    display_name = "\232\181\183\229\167\139\228\189\141\231\189\174"
  },
  {
    name = "StartRotation",
    type = "ActorRotation",
    display_name = "\232\181\183\229\167\139\230\156\157\229\144\145"
  }
})

function DialogueTimelineNPCMoveAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.Handler = -1
end

function DialogueTimelineNPCMoveAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    return
  end
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    Log.Warning("\230\136\152\230\150\151\228\184\173\230\151\160\230\179\149\228\189\191\231\148\168\232\167\146\232\137\178\231\167\187\229\138\168\229\138\159\232\131\189")
    return
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  local View = DialogueUtils.ExtraActorView(Actor)
  if View then
    actor.DialogueTimelineTransformCache = View:GetTransform()
  end
  self:ConsumeActorPerform(actor)
  if not self.CurrentMoveData then
    return
  end
  self:TurnNPC(self.CurrentMoveData)
  if self.Handler > 0 then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = -1
  end
  self.Handler = _G.DelayManager:DelaySeconds(0.6, self.MoveAll, self)
end

function DialogueTimelineNPCMoveAction:ConsumeActorPerform(Actor)
  if not self.TargetLocation or not self.TargetRotation then
    return
  end
  local Transform = self.fsm:GetProperty("BornTransform")
  if not Actor then
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if not View then
    return
  end
  local UERotation = DialogueUtils.ParseActorRotation(self.TargetRotation, Actor)
  local UELocation = DialogueUtils.ParseActorLocation(self.TargetLocation, Actor)
  if nil == UERotation or nil == UELocation then
    return
  end
  if self.UseCustomStartLocation then
    local UEStartRotation = DialogueUtils.ParseActorRotation(self.StartRotation, Actor)
    local UEStartLocation = DialogueUtils.ParseActorLocation(self.StartLocation, Actor)
    if UEStartRotation and UEStartLocation then
      local StartRelativeTransform = UE4.FTransform(UEStartRotation:ToQuat(), UEStartLocation)
      local StartTransform = StartRelativeTransform * Transform
      View:Abs_K2_SetActorTransform_WithoutHit(StartTransform, false, false)
    end
  end
  self.CurrentMoveData = nil
  local RelativeTransform = UE4.FTransform(UERotation:ToQuat(), UELocation)
  local Location = RelativeTransform * Transform
  DialogueUtils.ToggleAI(Actor, false)
  DialogueUtils.StopTurn(Actor)
  Location.Translation = SceneUtils.ConvertAbsoluteToRelative(Location.Translation)
  self.CurrentMoveData = MakeMoveData(Actor, Location)
end

function DialogueTimelineNPCMoveAction:TurnNPC(Data)
  local NPC = Data.Character
  local View = NPC and NPC.viewObj
  if not View or not Data.Location then
    return
  end
  Log.Info("Direct Turn", UE.UObject.GetName(NPC.viewObj))
  local Direction = Data.Location - View:K2_GetActorLocation()
  Direction.Z = 0
  if _G.GlobalConfig.DrawDebugLookAt then
    local Origin = View:K2_GetActorLocation()
    UE.UKismetSystemLibrary.DrawDebugArrow(View, Origin, Origin + View:GetActorForwardVector() * 100, 20, UE.FLinearColor(0, 1, 0, 1), 30, 3)
    UE.UKismetSystemLibrary.DrawDebugArrow(View, Origin, Origin + Direction * 100, 20, UE.FLinearColor(0, 0, 1, 1), 30, 3)
  end
  local Rotator = Direction:ToRotator()
  local TurnComp = NPC.TurnComponent
  if TurnComp then
    TurnComp:StartTurn_S(Rotator.Yaw, 0.5, true)
  else
    NPC:SetActorRotation(Rotator)
  end
end

function DialogueTimelineNPCMoveAction:MoveAll()
  self.CurrentMoveData.bStartMoveSuccess = self:MoveSinglePerson(self.CurrentMoveData)
  if not self.CurrentMoveData.bStartMoveSuccess then
    self.CurrentMoveData = nil
  end
  self:OnRequestMoveFinish()
end

function DialogueTimelineNPCMoveAction:OnMoveResult(NPC, bBlocked)
  if self.CurrentMoveData then
    self.CurrentMoveData.Character = nil
    self.CurrentMoveData.Transform = nil
    self.CurrentMoveData.Location = nil
  end
  self.CurrentMoveData = nil
  if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
    DialogueUtils.ToggleMovement(NPC, false)
  end
end

function DialogueTimelineNPCMoveAction:MoveSinglePerson(Data)
  local NPC = Data.Character
  local Location = Data.Location
  local View = NPC.viewObj
  if not View then
    return false
  end
  local ViewLocation = View:K2_GetActorLocation()
  local Distance = UE4.FVector.Dist(ViewLocation, Location)
  if Distance <= 20 then
    Log.Error("\229\183\178\231\187\143\229\136\176\232\190\190\230\140\135\229\174\154\228\189\141\231\189\174!", UE.UObject.GetName(View))
    return false
  end
  local MoveComp = View:GetComponentByClass(UE.UCharacterMovementComponentBase)
  if not MoveComp then
    return false
  end
  local Speed = Distance / math.max(1.0E-5, self.EndTime - self.StartTime)
  
  local function ArrivedCallback(Object, bHasBlock)
    self:OnMoveResult(NPC, bHasBlock)
  end
  
  if _G.GlobalConfig.DrawDebugLookAt then
    UE.UKismetSystemLibrary.DrawDebugSphere(View, View:K2_GetActorLocation(), 30, 8, UE.FLinearColor(0, 1, 0, 1), 30, 2)
    UE.UKismetSystemLibrary.DrawDebugSphere(View, Location, 30, 8, UE.FLinearColor(0, 0, 1, 1), 30, 2)
    UE.UKismetSystemLibrary.DrawDebugLine(View, View:K2_GetActorLocation(), Location, UE.FLinearColor(1, 1, 0, 1), 30, 4)
  end
  DialogueUtils.ToggleMovement(NPC, true)
  MoveComp:SetComponentTickEnabled(true)
  MoveComp.bRunPhysicsWithNoController = true
  MoveComp:SetMovementMode(UE.EMovementMode.MOVE_Walking)
  MoveComp.OnDirectGoalMoveFinish:Bind(View, ArrivedCallback)
  local Success = MoveComp:RequestDirectGoalMove(Speed, Location, 20)
  if not Success then
    Log.Warning("DialogueTimelineNPCMoveAction:MoveSinglePerson ", UE.UObject.GetName(View), " fail")
    MoveComp.OnDirectGoalMoveFinish:Unbind()
    DialogueUtils.ToggleMovement(NPC, false)
  end
  return Success
end

function DialogueTimelineNPCMoveAction:OnRequestMoveFinish()
  if self.Handler > 0 then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = -1
  end
  table.clear(self.MovingNPCs)
end

function DialogueTimelineNPCMoveAction:OnFinish()
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if actor then
    actor.DialogueTimelineTransformCache = nil
  end
  Base.OnFinish(self)
end

function DialogueTimelineNPCMoveAction:OnExit()
  if self.CurrentMoveData and self.CurrentMoveData.bStartMoveSuccess then
    local NPC = self.CurrentMoveData.Character
    local FinalTrans = self.CurrentMoveData and self.CurrentMoveData.Transform
    local View = DialogueUtils.ExtraActorView(NPC)
    if View and UE.UObject.IsValid(View) then
      local MoveComp = View:GetComponentByClass(UE.UCharacterMovementComponentBase)
      if MoveComp and UE.UObject.IsValid(MoveComp) then
        MoveComp.OnDirectGoalMoveFinish:Unbind()
        MoveComp:FinishDirectGoalMove(false)
      end
      if FinalTrans then
        View:K2_SetActorLocationAndRotation(FinalTrans.Translation, FinalTrans.Rotation:ToRotator(), false, nil, true)
      end
    end
    self:OnMoveResult(NPC, false)
    if _G.DialogueModuleCmd and not _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
      DialogueUtils.ToggleMovement(NPC, true)
    end
  end
end

return DialogueTimelineNPCMoveAction

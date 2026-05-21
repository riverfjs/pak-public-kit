local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialoguePrevTimelineWaitNPCSpawnAction = Base:Extend("FsmWaitNPCSpawnAction")
FsmUtils.MergeMembers(Base, DialoguePrevTimelineWaitNPCSpawnAction, {
  {
    name = "CurrentTimeline",
    type = "var"
  },
  {
    name = "DialogueConf",
    type = "var"
  },
  {name = "TargetNPC", type = "var"},
  {name = "NpcIDs", type = "var"}
})

function DialoguePrevTimelineWaitNPCSpawnAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialoguePrevTimelineWaitNPCSpawnAction:OnEnter()
  self:InjectProperties()
  self.timeout = 2
  self:OnTick(0)
  self:Finish()
end

function DialoguePrevTimelineWaitNPCSpawnAction:OnTick(DeltaTime)
  if self:Check(false) then
    self:Finish()
  end
end

function DialoguePrevTimelineWaitNPCSpawnAction:Check(ThrowError)
  if self.CurrentTimeline and self.CurrentTimeline.actions then
    for _, action in ipairs(self.CurrentTimeline.actions) do
      if action.OwnerActorID == nil or 0 == action.OwnerActorID and 0 == self.NPCContentID or -100 == action.OwnerActorID or -101 == action.OwnerActorID then
      else
        local Actor = self:GetActor(action.OwnerActorID, action.NPCContentID)
        if not Actor then
          if ThrowError then
            Log.Error("\231\173\137\229\190\133\232\161\168\230\188\148\232\128\133\231\148\159\230\136\144", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
          else
            Log.Debug("\231\173\137\229\190\133\232\161\168\230\188\148\232\128\133\231\148\159\230\136\144", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
          end
          return false
        end
        if Actor.isDestroy then
          if ThrowError then
            Log.Error("\229\143\130\228\184\142\232\161\168\230\188\148\231\154\132NPC\229\173\152\229\156\168\239\188\140\228\189\134\230\152\175\232\162\171\229\136\160\228\186\134\239\188\140\232\175\183\230\163\128\230\159\165\229\175\185\232\175\157\233\128\187\232\190\145", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
          else
            Log.Warning("\229\143\130\228\184\142\232\161\168\230\188\148\231\154\132NPC\229\173\152\229\156\168\239\188\140\228\189\134\230\152\175\232\162\171\229\136\160\228\186\134\239\188\140\232\175\183\230\163\128\230\159\165\229\175\185\232\175\157\233\128\187\232\190\145", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
          end
        else
          local View = Actor.viewObj
          if not View then
            if ThrowError then
              Log.Error("\231\173\137\229\190\133\232\161\168\230\188\148\232\128\133\230\168\161\229\158\139", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
            else
              Log.Debug("\231\173\137\229\190\133\232\161\168\230\188\148\232\128\133\230\168\161\229\158\139", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
            end
            return false
          end
          if -1 ~= action.OwnerActorID and (UE.UObject.IsA(View, UE.ANPCBaseActor) or UE.UObject.IsA(View, UE.ANPCBaseCharacter)) and not View.resourceLoaded then
            if ThrowError then
              Log.Error("\231\173\137\229\190\133NPC\230\168\161\229\158\139\229\138\160\232\189\189\229\174\140\230\136\144", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
            else
              Log.Debug("\231\173\137\229\190\133NPC\230\168\161\229\158\139\229\138\160\232\189\189\229\174\140\230\136\144", action.OwnerActorID, DialogueUtils.ActorToString(Actor))
            end
            return false
          end
        end
      end
    end
  end
  return true
end

function DialoguePrevTimelineWaitNPCSpawnAction:OnTimeout()
  Log.Error("\231\173\137\229\190\133\229\143\130\228\184\142\229\175\185\232\175\157\232\161\168\230\188\148\231\154\132NPC\231\148\159\230\136\144\232\182\133\230\151\182\228\186\134...\232\175\183\230\163\128\230\159\165\229\175\185\232\175\157\233\133\141\231\189\174")
  self:Check(true)
  Base.OnTimeout(self)
end

function DialoguePrevTimelineWaitNPCSpawnAction:OnExit()
  Base.OnExit(self)
end

function DialoguePrevTimelineWaitNPCSpawnAction:OnFinish()
  local NpcIDs = {
    {-1, 0},
    {-2, 0}
  }
  if self.CurrentTimeline.actions then
    for _, action in ipairs(self.CurrentTimeline.actions) do
      if action.OwnerActorID == nil or 0 == action.OwnerActorID and 0 == action.NPCContentID or -100 == action.OwnerActorID or -101 == action.OwnerActorID then
      else
        table.insert(NpcIDs, {
          action.OwnerActorID,
          action.NPCContentID
        })
      end
    end
  end
  local ActorSet = {}
  for _, IDPair in ipairs(NpcIDs) do
    local Actor = self:GetActor(IDPair[1], IDPair[2])
    if not Actor or table.contains(ActorSet, Actor) then
    else
      table.insert(ActorSet, Actor)
      local ServerID = Actor:GetServerId()
      if not table.contains(self.NpcIDs, ServerID) then
        table.insert(self.NpcIDs, ServerID)
      end
      DialogueUtils.ToggleAI(Actor, false)
      DialogueUtils.ToggleLOD(Actor, true)
      DialogueUtils.ToggleSignificance(Actor, true)
      DialogueUtils.StopTurn(Actor)
      if DialogueUtils.IsEntryDialogue(self.fsm) then
        DialogueUtils.ClearLookAt(Actor)
      end
      local LastTimeline = self.fsm:GetProperty("LastTimeline")
      if LastTimeline and LastTimeline.clear_look_at_at_end then
        DialogueUtils.ClearLookAt(Actor)
      end
      if self.fsm:GetProperty("bIsDebugging") then
        DialogueUtils.StopLookAt(Actor)
      end
      DialogueUtils.ToggleMovement(Actor, false)
    end
  end
end

return DialoguePrevTimelineWaitNPCSpawnAction

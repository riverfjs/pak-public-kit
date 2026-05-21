local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueNPCSetupAction = Base:Extend("DialogueNPCSetupAction")
FsmUtils.MergeMembers(Base, DialogueNPCSetupAction, {
  {name = "TargetNPC", type = "var"},
  {
    name = "DialogueConf",
    type = "var"
  },
  {name = "NpcIDs", type = "var"}
})

function DialogueNPCSetupAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.TurnArrays = {}
  self.Handler = -1
end

function DialogueNPCSetupAction:OnEnter()
  Log.Debug("DialogueNPCSetupAction:OnEnter")
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    Log.Warning("\230\136\152\230\150\151\228\184\173\228\184\141\230\148\175\230\140\129\232\189\172\229\144\145")
    self:Finish()
    return
  end
  self:InjectProperties()
  table.clear(self.TurnArrays)
  if not self.DialogueConf then
    self:Finish()
    return
  end
  local Participants = self.fsm:GetProperty("Participants", nil)
  if Participants then
    local Speaker = self:GetActor(self.DialogueConf.speaker)
    local SpeakerView = self:GetActorView(self.DialogueConf.speaker)
    if Speaker and SpeakerView then
      local ValidParticipants = {
        DialogueUtils.GetHero()
      }
      for ID, Participant in pairs(Participants) do
        if not Participant then
          Participant = DialogueUtils.FindNPC(ID) or false
          Participants[ID] = Participant
        end
        if Participant and not Participant.isDestroy then
          if Participant.config then
            if 1 ~= Participant.config.not_turn_face then
              table.insert(ValidParticipants, Participant)
            end
          else
            table.insert(ValidParticipants, Participant)
          end
        end
      end
      for _, Participant in ipairs(ValidParticipants) do
        DialogueUtils.ToggleAI(Participant, false)
        self:Record(Participant)
        local HeadComp = Participant:GetHeadLookAtComponent()
        if HeadComp and Participant ~= Speaker then
          DialogueUtils.StopTurn(Participant)
          if DialogueUtils.IsEntryDialogue(self.fsm) then
            DialogueUtils.ClearLookAt(Participant)
          end
          HeadComp:SetAutoLookAtParam(UE4.ELookAtParamType.Target, Speaker.viewObj)
          HeadComp:ActiveAutoLookAt(false, "Bip001-Neck", true)
          HeadComp:CalculateAutoLookAt(true)
          if 0 ~= HeadComp.TargetBodyYaw then
            table.insert(self.TurnArrays, Participant)
          end
        end
      end
    elseif 0 ~= self.DialogueConf.speaker then
      Log.Error("\232\191\155\232\161\140\229\133\168\232\135\170\229\138\168\232\189\172\229\144\145\231\154\132\230\151\182\229\128\153,\230\151\160\230\179\149\232\142\183\229\143\150\232\175\180\232\175\157\232\128\133", self.DialogueConf.speaker)
    end
  else
    local Performs = self.DialogueConf.actor_perform
    if not Performs or 0 == #Performs then
      self:Finish()
      return
    end
    for _, Perform in ipairs(Performs) do
      self:ConsumeActorPerform(Perform)
    end
  end
  if table.len(self.TurnArrays) > 0 then
    self.Handler = _G.DelayManager:DelaySeconds(0.5, self.Finish, self)
  else
    self:Finish()
  end
end

function DialogueNPCSetupAction:Record(actor)
  if not actor.serverData then
    return
  end
  local ID = actor.serverData.base.actor_id
  if not table.contains(self.NpcIDs, ID) then
    table.insert(self.NpcIDs, ID)
  end
end

function DialogueNPCSetupAction:IsValid(ID)
  return ID and 0 ~= ID
end

function DialogueNPCSetupAction:ConsumeActorPerform(Perform)
  if not Perform then
    return
  end
  local Actor = self:GetActor(Perform.actor)
  if not Actor or Actor.isDestroy then
    return
  end
  if Actor.config and 1 == Actor.config.not_turn_face then
    return
  end
  local HeadLookAt = Actor:GetHeadLookAtComponent()
  if not HeadLookAt then
    return
  end
  DialogueUtils.ToggleAI(Actor, false)
  DialogueUtils.ToggleLOD(Actor, true)
  DialogueUtils.ToggleSignificance(Actor, true)
  DialogueUtils.StopTurn(Actor)
  self:Record(Actor)
  local bEnableLookAt = false
  if Perform.body_turn_to < 0 or Perform.body_turn_to > 360 then
    local NPCView = self:GetActorView(Perform.body_turn_to)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Body, NPCView)
      bEnableLookAt = true
    end
  elseif Perform.body_turn_to > 0 then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Body, nil, nil, nil, 0, math.fmod(Perform.body_turn_to, 360))
    bEnableLookAt = true
  end
  if Perform.turn_to < 0 or Perform.turn_to > 360 then
    local NPCView = self:GetActorView(Perform.turn_to)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Head, NPCView)
      bEnableLookAt = true
    end
  elseif Perform.turn_to > 0 then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Head, nil, nil, nil, 0, math.fmod(Perform.turn_to, 360))
    bEnableLookAt = true
  end
  if Perform.eye_turn_to < 0 or Perform.eye_turn_to > 360 then
    local NPCView = self:GetActorView(Perform.eye_turn_to)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Eye, NPCView)
      bEnableLookAt = true
    end
  elseif Perform.eye_turn_to > 0 then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Eye, nil, nil, nil, 0, math.fmod(Perform.eye_turn_to, 360))
    bEnableLookAt = true
  end
  if bEnableLookAt then
    HeadLookAt:ActiveAutoLookAt(false, nil, true)
    HeadLookAt:CalculateAutoLookAt(true)
  end
  if 0 ~= HeadLookAt.TargetBodyYaw then
    table.insert(self.TurnArrays, Actor)
  end
  DialogueUtils.ToggleMovement(Actor, false)
end

function DialogueNPCSetupAction:Clear()
  if self.Handler > 0 then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = -1
  end
  table.clear(self.TurnArrays)
end

function DialogueNPCSetupAction:OnFinish()
  self:Clear()
end

function DialogueNPCSetupAction:OnExit()
  self:Clear()
end

function DialogueNPCSetupAction:OnFinalize()
  self:Clear()
end

return DialogueNPCSetupAction

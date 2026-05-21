local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCSetupAction = Base:Extend("DialogueTimelineNPCSetupAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCSetupAction, {
  {
    name = "BodyTargetActorID",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\232\186\171\228\189\147\231\155\174\230\160\135\232\167\146\232\137\178ID"
  },
  {
    name = "BodyTurnTo",
    type = "float",
    default = 0.0,
    display_name = "\232\186\171\228\189\147\230\156\157\229\144\145\232\167\146\229\186\166"
  },
  {
    name = "BodyTurnSpeedScale",
    type = "float",
    default = 1.0,
    display_name = "\232\186\171\228\189\147\232\189\172\229\144\145\233\128\159\229\186\166\229\128\141\231\142\135"
  },
  {
    name = "HeadTargetActorID",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\229\164\180\230\156\157\229\144\145\231\155\174\230\160\135\232\167\146\232\137\178ID"
  },
  {
    name = "HeadTurnTo",
    type = "float",
    default = 0.0,
    display_name = "\229\164\180\230\156\157\229\144\145\230\176\180\229\185\179\232\167\146\229\186\166"
  },
  {
    name = "HeadTurnToY",
    type = "float",
    default = 0.0,
    display_name = "\229\164\180\230\156\157\229\144\145\229\158\130\231\155\180\232\167\146\229\186\166"
  },
  {
    name = "HeadTurnSpeedScale",
    type = "float",
    default = 1.0,
    display_name = "\229\164\180\232\189\172\229\144\145\233\128\159\229\186\166\229\128\141\231\142\135"
  },
  {
    name = "EyeTargetActorID",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\231\156\188\231\157\155\231\155\174\230\160\135\232\167\146\232\137\178ID"
  },
  {
    name = "EyeTurnToHorizontal",
    default = 0.0,
    type = "float",
    display_name = "\231\156\188\231\157\155\230\176\180\229\185\179\232\167\146\229\186\166"
  },
  {
    name = "EyeTurnToVertical",
    default = 0.0,
    type = "float",
    display_name = "\231\156\188\231\157\155\229\158\130\231\155\180\232\167\146\229\186\166"
  },
  {
    name = "EyeTurnSpeedScale",
    type = "float",
    default = 1.0,
    display_name = "\231\156\188\231\157\155\232\189\172\229\144\145\233\128\159\229\186\166\229\128\141\231\142\135"
  }
})

function DialogueTimelineNPCSetupAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCSetupAction:OnEnter()
  Log.Debug("DialogueTimelineNPCSetupAction:OnEnter")
  if DialogueUtils.SkipDialogue then
    return
  end
  self:InjectProperties()
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    Log.Warning("\230\136\152\230\150\151\229\164\167\230\166\130\230\178\161\230\156\137\229\164\180\230\156\157\229\144\145\229\138\159\232\131\189\239\188\140\229\166\130\230\158\156\232\161\168\231\142\176\230\156\137\233\151\174\233\162\152\232\175\183\231\187\153\229\188\128\229\143\145\230\143\144\233\156\128\230\177\130\239\188\140\232\176\162\232\176\162")
  end
  local actor = self:GetActor(self.OwnerActorID, self.NPCContentID)
  self:ConsumeActorPerform(actor)
end

function DialogueTimelineNPCSetupAction:ConsumeActorPerform(Actor)
  if not Actor or Actor.isDestroy then
    return
  end
  if Actor.config and 1 == Actor.config.not_turn_face then
    return
  end
  local HeadLookAt = Actor.GetHeadLookAtComponent and Actor:GetHeadLookAtComponent()
  if not HeadLookAt then
    return
  end
  local bEnableLookAt = false
  if 0 ~= self.BodyTargetActorID then
    local NPCView = self:GetActorView(self.BodyTargetActorID)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Body, NPCView, nil, nil, 0.0, 0.0, self.BodyTurnSpeedScale)
      bEnableLookAt = true
    end
  elseif 0.0 ~= self.BodyTurnTo then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Body, nil, nil, nil, 0, math.fmod(self.BodyTurnTo, 360), self.BodyTurnSpeedScale)
    bEnableLookAt = true
  end
  if 0 ~= self.HeadTargetActorID then
    local NPCView = self:GetActorView(self.HeadTargetActorID)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Head, NPCView, nil, nil, 0.0, 0.0, self.HeadTurnSpeedScale)
      bEnableLookAt = true
    end
  elseif 0.0 ~= self.HeadTurnToY or 0.0 ~= self.HeadTurnTo then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Head, nil, nil, nil, math.fmod(self.HeadTurnToY, 360), math.fmod(self.HeadTurnTo, 360), self.HeadTurnSpeedScale)
    bEnableLookAt = true
  end
  if 0 ~= self.EyeTargetActorID then
    local NPCView = self:GetActorView(self.EyeTargetActorID)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Eye, NPCView, nil, nil, 0.0, 0.0, self.EyeTurnSpeedScale)
      bEnableLookAt = true
    end
  elseif 0.0 ~= self.EyeTurnToVertical or 0.0 ~= self.EyeTurnToHorizontal then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Eye, nil, nil, nil, math.fmod(self.EyeTurnToVertical, 360), math.fmod(self.EyeTurnToHorizontal, 360), self.EyeTurnSpeedScale)
    bEnableLookAt = true
  end
  if bEnableLookAt then
    local NotTurn = self.fsm:GetProperty("bInBattle", false)
    HeadLookAt:ActiveAutoLookAt(false, nil, true, NotTurn)
    HeadLookAt:CalculateAutoLookAt(true)
  end
end

return DialogueTimelineNPCSetupAction

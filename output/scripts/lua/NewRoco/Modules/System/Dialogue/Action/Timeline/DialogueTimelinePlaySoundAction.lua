local DialogueTimelineActionState = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = DialogueTimelineActionState
local DialogueTimelinePlaySoundAction = Base:Extend("DialogueTimelinePlaySoundAction")
FsmUtils.MergeMembers(Base, DialogueTimelinePlaySoundAction, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = 0,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "SoundEvent",
    type = "string",
    default = "",
    display_name = "\229\163\176\233\159\179\228\186\139\228\187\182"
  },
  {
    name = "StopType",
    type = "Enum.AudioStopType",
    default = "",
    display_name = "\229\129\156\230\173\162\229\163\176\233\159\179"
  }
})

function DialogueTimelinePlaySoundAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.Handler = -1
end

function DialogueTimelinePlaySoundAction:OnEnter()
  self:InjectProperties()
  if string.IsNilOrEmpty(self.SoundEvent) then
    self:Finish()
    return
  end
  if 0 == self.OwnerActorID and 0 == self.NPCContentID then
    self.Handler = _G.NRCAudioManager:PlaySound2DByEventNameAuto(self.SoundEvent, "DialogueTimelinePlaySoundAction")
  else
    local ActorView = self:GetActorView(self.OwnerActorID, self.NPCContentID)
    if ActorView and UE.UObject.IsValid(ActorView) then
      self.Handler = _G.NRCAudioManager:PlaySound3DWithActorByEventNameAuto(self.SoundEvent, ActorView, "DialogueTimelinePlaySoundAction")
    else
      self.Handler = _G.NRCAudioManager:PlaySound2DByEventNameAuto(self.SoundEvent, "DialogueTimelinePlaySoundAction")
    end
  end
  if not self.Handler then
    Log.Warning("DialogueTimelinePlaySoundAction:OnEnter, fail to play sound ", self.SoundEvent)
  end
  if self.Handler and self.StopType == Enum.AudioStopType.AST_ON_DIALOGUE_END then
    local Handlers = self.fsm:GetProperty("StopAudioHandlers")
    if not Handlers then
      Handlers = {}
      self.fsm:SetProperty("StopAudioHandlers", Handlers)
    end
    Handlers[self.Handler] = true
    self.Handler = -1
  end
end

function DialogueTimelinePlaySoundAction:StopSound()
  if -1 == self.Handler then
    return
  end
  _G.NRCAudioManager:ReleaseSession(self.Handler, true, "DialogueTimelinePlaySoundAction", false, 0.0)
  self.Handler = -1
end

function DialogueTimelinePlaySoundAction:OnFinish()
  if self.StopType ~= Enum.AudioStopType.AST_ON_ACTION_END then
    return
  end
  self:StopSound()
end

function DialogueTimelinePlaySoundAction:OnExit()
  if self.StopType ~= Enum.AudioStopType.AST_ON_STATE_END then
    return
  end
  self:StopSound()
end

return DialogueTimelinePlaySoundAction

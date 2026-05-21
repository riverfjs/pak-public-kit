local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineNPCFacialEmotionAction = Base:Extend("DialogueTimelineNPCFacialEmotionAction")
FsmUtils.MergeMembers(Base, DialogueTimelineNPCFacialEmotionAction, {
  {
    name = "FacialEmotionFile",
    type = "string",
    default = "",
    display_name = "\232\161\168\230\131\133\230\150\135\228\187\182"
  }
})

function DialogueTimelineNPCFacialEmotionAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineNPCFacialEmotionAction:OnPreload()
  Base.OnPreload(self)
  self:InjectProperties()
  self.AudioData = nil
  self.AudioDataRef = nil
  self.ResRequest = nil
  local SpeakContent = self.FacialEmotionFile
  if string.IsNilOrEmpty(SpeakContent) then
    return
  end
  local Speaker = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if not Speaker then
    return
  end
  if not _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.CheckLipSyncExists, SpeakContent) then
    Log.Debug("\229\143\163\229\158\139\232\181\132\230\186\144\228\184\141\229\173\152\229\156\168...", SpeakContent)
    return
  end
  local AssetPath = string.format("/Game/ArtRes/BP/Lipsync/%s.%s", SpeakContent, SpeakContent)
  self.ResRequest = _G.NRCResourceManager:LoadResAsync(self, AssetPath, 1, 0, self.OnPreloadFinish, self.OnPreloadFailed)
  self.state:AddPreloadingAction(self)
end

function DialogueTimelineNPCFacialEmotionAction:OnPreloadFinish(resRequest, asset)
  self.AudioData = asset
  self.AudioDataRef = asset and UnLua.Ref(asset)
  if self.state.RemovePreloadingAction then
    self.state:RemovePreloadingAction(self)
  end
end

function DialogueTimelineNPCFacialEmotionAction:OnPreloadFailed()
  self.ResRequest = nil
  self.AudioData = nil
  self.AudioDataRef = nil
  if self.state.RemovePreloadingAction then
    self.state:RemovePreloadingAction(self)
  end
end

function DialogueTimelineNPCFacialEmotionAction:OnEnter()
  Base.OnEnter(self)
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  if string.IsNilOrEmpty(self.FacialEmotionFile) then
    return
  end
  if not self.ResRequest then
    return
  end
  if not self.AudioData then
    return
  end
  local Speaker = self:GetActor(self.OwnerActorID, self.NPCContentID)
  if not Speaker then
    return
  end
  local View = DialogueUtils.ExtraActorView(Speaker)
  local MeshComp = View and View.Mesh
  local AnimInstance = MeshComp and MeshComp:GetAnimInstance()
  if not AnimInstance then
    Log.Error("\230\151\160\230\179\149\230\137\190\229\136\176\232\167\146\232\137\178\232\186\171\228\184\138\231\154\132AnimInstance", View and UE.UObject.GetName(View) or "\230\178\161\230\156\137ViewObject")
    return
  end
  if not AnimInstance:IsA(UE.UCharacterEmotionAnimInstance) then
    Log.Error("\232\191\153\228\184\170NPC\232\174\178\228\184\141\228\186\134\232\175\157 ", View and UE.UObject.GetName(View) or "\230\178\161\230\156\137ViewObject")
    return
  end
  Log.Debug(UE.UObject.GetName(View), "\232\166\129\229\188\128\229\167\139\230\146\173\230\148\190\232\161\168\230\131\133\228\186\134", UE.UObject.GetName(self.AudioData))
  self.fsm.LastSpeaker = Speaker
  AnimInstance:PlayEmotion(self.AudioData, 0.1)
end

function DialogueTimelineNPCFacialEmotionAction:OnFinish()
  if self.Request then
    _G.NRCResourceManager:UnLoadRes(self.Request)
    self.Request = nil
  end
  self.AudioDataRef = nil
  Base.OnFinish(self)
end

return DialogueTimelineNPCFacialEmotionAction

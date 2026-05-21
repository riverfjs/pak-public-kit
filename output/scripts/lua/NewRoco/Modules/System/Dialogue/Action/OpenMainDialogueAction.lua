local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local OpenMainDialogueAction = Base:Extend("OpenMainDialogueAction")
FsmUtils.MergeMembers(Base, OpenMainDialogueAction, {
  {
    name = "DialogueConf",
    type = "var"
  },
  {
    name = "ParentModule",
    type = "var"
  }
})

function OpenMainDialogueAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.Request = nil
  self.DelayHandler = -1
end

function OpenMainDialogueAction:OnPreload()
  self.AudioData = nil
  self.AudioDataRef = nil
  local Conf = self.fsm:GetProperty("CurrentDialogue")
  local SpeakContent = Conf and Conf.dialogue_sound
  if string.IsNilOrEmpty(SpeakContent) then
    return
  end
  local Speaker = Conf and Conf.speaker or 0
  if 0 == Speaker then
    Log.Debug("\229\175\185\232\175\157\233\133\141\231\189\174Speaker\228\184\1860", Conf and Conf.id or "\230\137\190\228\184\141\229\136\176\229\175\185\232\175\157\233\133\141\231\189\174")
    return
  end
  if not _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.CheckLipSyncExists, SpeakContent) then
    Log.Debug("\229\143\163\229\158\139\232\181\132\230\186\144\228\184\141\229\173\152\229\156\168...", SpeakContent)
    return
  end
  local AssetPath = string.format("/Game/ArtRes/BP/Lipsync/%s.%s", SpeakContent, SpeakContent)
  self.Request = _G.NRCResourceManager:LoadResAsync(self, AssetPath, 1, 0, self.OnPreloadFinish, self.OnPreloadFailed)
  self.state:AddPreloadingAction(self)
end

function OpenMainDialogueAction:OnPreloadFinish(resRequest, asset)
  self.AudioData = asset
  self.AudioDataRef = asset and UnLua.Ref(asset)
  if self.state.RemovePreloadingAction then
    self.state:RemovePreloadingAction(self)
  end
end

function OpenMainDialogueAction:OnPreloadFailed()
  self.Request = nil
  self.AudioData = nil
  self.AudioDataRef = nil
  if self.state.RemovePreloadingAction then
    self.state:RemovePreloadingAction(self)
  end
end

function OpenMainDialogueAction:PlayAudioAnim()
  local LastSpeaker = self.fsm:GetProperty("LastSpeaker", nil)
  if LastSpeaker then
    DialogueUtils.StopTalk(LastSpeaker, 0.1)
  end
  if not self.Request then
    return
  end
  if not self.AudioData then
    return
  end
  local Speaker = self:GetSpeaker()
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
  if not AnimInstance.PlayEmotion then
    Log.Error("\232\167\146\232\137\178\232\186\171\228\184\138\231\154\132AnimInstance\230\151\160\230\179\149\230\146\173\230\148\190\232\161\168\230\131\133", View and UE.UObject.GetName(View) or "\230\178\161\230\156\137ViewObject")
    return
  end
  Log.Debug(UE.UObject.GetName(View), "\232\166\129\229\188\128\229\167\139\232\174\178\232\175\157\228\186\134", UE.UObject.GetName(self.AudioData))
  AnimInstance:PlayEmotion(self.AudioData, 0.1)
  self.fsm:SetProperty("LastSpeaker", Speaker)
  local SpeakerID = Speaker.GetServerId and Speaker:GetServerId() or 0
  if SpeakerID > 0 then
    local IDs = self.fsm:GetProperty("NpcIDs")
    if IDs and table.contains(IDs, SpeakerID) then
      table.insert(IDs, SpeakerID)
    end
  end
end

function OpenMainDialogueAction:OnEnter()
  Log.Debug("OpenMainDialogueAction:OnEnter", DialogueUtils.SkipDialogue, self.fsm.name, self.name)
  self:InjectProperties()
  if DialogueUtils.SkipDialogue or BattleAutoTest.IsAutoBattle then
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.ShowMainPanel, self.AutoSkipCallback, self)
    return
  end
  if self.DialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK_ENTER or self.DialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK then
    self:PlayAudioAnim()
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.ShowMainPanel, self.Finish, self)
    self:AddListener()
  elseif string.IsNilOrEmpty(self.DialogueConf.text) then
    self:OnDialogueFinish(self.DialogueConf)
    self:Finish()
    self.ParentModule.PreUIType = self.DialogueConf.ui_source_type
    self.ParentModule._currentMainPanel = "None"
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.CloseMainPanel)
  else
    self:PlayAudioAnim()
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.ShowMainPanel)
    self:AddListener()
    self:Finish()
  end
end

function OpenMainDialogueAction:AutoSkipCallback()
  if self.DialogueConf.select_ids and 0 ~= #self.DialogueConf.select_ids then
    if self.DelayHandler and self.DelayHandler > 0 then
      _G.DelayManager:CancelDelayById(self.DelayHandler)
      self.DelayHandler = -1
    end
    self.DelayHandler = _G.DelayManager:DelayFrames(1, self.OnDialogueFinish, self)
  else
    self:OnDialogueFinish()
  end
  self:Finish()
end

function OpenMainDialogueAction:OnDialogueFinish(Dialogue)
  if self.DelayHandler and self.DelayHandler > 0 then
    self.DelayHandler = -1
  end
  Log.Debug("OpenMainDialogueAction:OnDialogueFinish", self.DialogueConf.id, Dialogue and Dialogue.id or "\230\178\161\230\156\137Dialogue")
  if Dialogue and self.DialogueConf.id ~= Dialogue.id then
    return
  end
  self:RemoveListener()
  self.fsm:SendEvent(DialogueModuleEvent.EnterDispatchState)
end

function OpenMainDialogueAction:AddListener()
  local ParentModule = self:GetProperty("ParentModule")
  if ParentModule then
    ParentModule:RegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished, self.OnDialogueFinish)
    local Conf = ParentModule:GetLastTalkedDialogue()
    if Conf and Conf.id == self.DialogueConf.id then
      Log.Error("Disaster recovered")
      self:OnDialogueFinish(Conf)
    end
  end
end

function OpenMainDialogueAction:RemoveListener()
  local ParentModule = self:GetProperty("ParentModule")
  if ParentModule then
    ParentModule:UnRegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished)
  end
end

function OpenMainDialogueAction:GetSpeaker()
  local Conf = self.fsm:GetProperty("CurrentDialogue")
  local SpeakContent = Conf.dialogue_sound
  if string.IsNilOrEmpty(SpeakContent) then
    return nil
  end
  local SpeakerID = Conf and Conf.speaker
  local Speaker = self:GetActor(SpeakerID)
  if Speaker and Speaker.config then
    Log.Debug("our speaker tonight is", Speaker.config.name)
  end
  return Speaker
end

function OpenMainDialogueAction:OnFinish()
  if self.Request then
    _G.NRCResourceManager:UnLoadRes(self.Request)
    self.Request = nil
  end
  if self.DelayHandler and self.DelayHandler > 0 then
    _G.DelayManager:CancelDelayById(self.DelayHandler)
    self.DelayHandler = -1
  end
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
end

function OpenMainDialogueAction:OnExit()
  self:RemoveListener()
end

return OpenMainDialogueAction

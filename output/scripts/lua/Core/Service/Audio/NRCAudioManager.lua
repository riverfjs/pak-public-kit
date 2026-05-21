local NRCAudioManager = _G.Singleton:Extend("NRCAudioManager")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")

function NRCAudioManager:Ctor()
  self.AudioManager = UE4.UNRCAudioManager.Get()
  self.AudioManager:Init()
  _G.NRCEventCenter:RegisterEvent("NRCAudioManager", self, SceneEvent.PostLoadMapStart, self.ClearAllAudioSession)
  _G.NRCEventCenter:RegisterEvent("NRCAudioManager", self, _G.NRCGlobalEvent.Shutdown, self.ClearAllAudioSessionTotally)
  self:ResetAudioState()
  self:SetPetSoundLimit(30, 1, 1)
  self:SetCommonRandomCoolDown(3, 10)
  self:SetCoolDownOffset(0, 0)
  self.AudioManager:SetDisableMuteSwitch("Pet_Switch", "Pet_Battle")
  self.AudioManager:SetDisableMuteSwitch("Pet_Switch", "Pet_Show")
  self.AudioManager:SetDisableMuteSwitch("Boss_Switch", "Boss")
  self.AudioManager:SetDisableMuteSwitch("Mute_Switch", "Unmute")
  self:AddEventListener()
  self.EventFinishCallback = {}
  self.DelayLerpRTPCMap = {}
  _G.NRCEventCenter:RegisterEvent("NRCAudioManager", self, NRCSDKManagerEvent.OnBackToLogin, self.OnBackToLogin)
  _G.NRCEventCenter:RegisterEvent("NRCAudioManager", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:RegisterEvent("NPCModule", self, NPCModuleEvent.OnPlayerPetNumChanged, self.OnPlayerPetNumChanged)
  self.CaveSessionId = nil
  self.CaveStateDelayHandler = nil
  if _G.RocoEnv.USE_LOCALIZATION then
    local curCulture = UE4.UNRCStatics.GetCurrentCulture()
    if "zh-Hans-CN" == curCulture then
      self:ChangeLanguage("Chinese")
    elseif "en" == curCulture then
      self:ChangeLanguage("English")
    end
  else
    self:ChangeLanguage("Chinese")
  end
end

function NRCAudioManager:OnEnterSceneFinishNtyAckEnd(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  if 301 == mapID then
    self:SetIsInHome(true)
  else
    self:SetIsInHome(false)
  end
  self:SetPetSoundLimit(1, 30, 30)
  local AudioDungeonConf = _G.DataConfigManager:GetAudioFubenConf(mapID, true)
  if AudioDungeonConf and AudioDungeonConf.scene_state_name then
    _G.NRCAudioManager:SetStateByName("Scene_State", AudioDungeonConf.scene_state_name)
  else
    _G.NRCAudioManager:SetStateByName("Scene_State", "World")
  end
end

function NRCAudioManager:SetPetSoundLimit(Duration, TypeLimit, PetLimit)
  Log.Debug("NRCAudioManager:SetPetSoundLimit", Duration, TypeLimit, PetLimit)
  self.AudioManager:SetPetSoundLimit(Duration, TypeLimit or 1, PetLimit or 1)
end

function NRCAudioManager:SetCommonRandomCoolDown(CoolDownMin, CoolDownMax)
  self.AudioManager:SetCommonRandomCoolDown(CoolDownMin, CoolDownMax)
end

function NRCAudioManager:SetCoolDownOffset(OffsetLower, OffsetUpper)
  self.AudioManager:SetCoolDownOffset(OffsetLower, OffsetUpper)
end

function NRCAudioManager:Free()
  self:RemoveEventListener()
  self.EventFinishCallback = {}
  if self.CaveStateDelayHandler then
    _G.DelayManager:CancelDelay(self.CaveStateDelayHandler)
    self.CaveStateDelayHandler = nil
  end
end

function NRCAudioManager:OnBackToLogin()
  self:ResetAudioState()
end

function NRCAudioManager:ResetAudioState()
  self:SetStateByName("Alert_State", "Normal", "InitState")
  self:SetStateByName("Task_Music", "None", "InitState")
  self:SetStateByName("Battle", "None", "InitState")
  self:SetStateByName("UI_Music", "None", "InitState")
  self:SetStateByName("World_Combat", "None", "InitState")
  self:SetStateByName("MiniGame", "None", "InitState")
  self:SetStateByName("Thunderstorm", "Leave", "InitState")
  self:SetStateByName("Main_UI", "Hidden", "InitState")
  self:SetStateByName("Story", "None", "InitState")
  self:SetStateByName("Prologue_Compress", "OFF", "InitState")
  self:SetStateByName("Story_Movie", "None", "InitState")
  self:SetStateByName("Scene_State", "World", "InitState")
  self:SetStateByName("Fullscreen", "Close", "InitState")
  self:SetGlobalSwitch("Pet_Switch", "Pet_World", "InitState")
  self:SetGlobalSwitch("Amb_Area", "No", "InitState")
  self:SetGlobalRTPC("Seq_Ducking", 1, 0, "InitState")
  self:SetGlobalRTPC("GameObj_Volume", 100, 0, "InitState")
  self:SetGlobalRTPC("GameObj_Volume_Raw", 100, 0, "InitState")
  self.LobbyMainInnerOpen = false
  self.MainUIOpen = false
  self.CreatingPlayer = false
  self.DialogueDelayHandler = nil
  self.DialogueOpen = false
end

function NRCAudioManager:AddEventListener()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if self.AudioManager and self.AudioManager.AudioEventFinishedDelegate then
    local handlerWarp = _G.SimpleDelegateFactory:CreateCallback(self, self.OnEventFinished)
    self.AudioManager.AudioEventFinishedDelegate:Add(GameInstance, handlerWarp)
  end
  if self.AudioManager and self.AudioManager.OnCurrentCaveChanged then
    local handlerWarp = _G.SimpleDelegateFactory:CreateCallback(self, self.OnCurrentCaveChanged)
    self.AudioManager.OnCurrentCaveChanged:Add(GameInstance, handlerWarp)
  end
end

function NRCAudioManager:RemoveEventListener()
  if self.AudioManager and self.AudioManager.AudioEventFinishedDelegate then
    self.AudioManager.AudioEventFinishedDelegate:Clear()
  end
end

function NRCAudioManager:ResetWorldListenerVolumeOffset()
  return self.AudioManager.ResetWorldListenerVolumeOffset()
end

function NRCAudioManager:SetWorldListenerVolumeOffset(Offset)
  return self.AudioManager.SetWorldListenerVolumeOffset(Offset)
end

function NRCAudioManager:RemoveDefaultListener(GameObjectId)
  return self.AudioManager.RemoveDefaultListener(GameObjectId)
end

function NRCAudioManager:RemoveDefaultListenerWithActor(Actor)
  return self.AudioManager.RemoveDefaultListenerWithActor(Actor)
end

function NRCAudioManager:AddDefaultListenerWithActor(Actor, Source)
  return self.AudioManager.AddDefaultListenerWithActor(Actor, Source)
end

function NRCAudioManager:AddDefaultListener(Location, Source)
  return self.AudioManager.AddDefaultListener(Location, Source)
end

function NRCAudioManager:SetListenerToSelf(Actor, Source)
  return self.AudioManager.SetListenerToSelf(Actor, Source)
end

function NRCAudioManager:Resume()
  return self.AudioManager:Resume()
end

function NRCAudioManager:Suspend()
  return self.AudioManager:Suspend()
end

function NRCAudioManager:ChangeLanguage(Language)
  return self.AudioManager:ChangeLanguage(Language)
end

function NRCAudioManager:ClearVoiceBank()
  return self.AudioManager:ClearVoiceBank()
end

function NRCAudioManager:SetOutputVolume(Volume)
  return self.AudioManager:SetOutputVolume(Volume)
end

function NRCAudioManager:PostTrigger(TriggerName, TargetActor, ComponentName)
  return self.AudioManager:PostTrigger(TriggerName, TargetActor, ComponentName)
end

function NRCAudioManager:GetEmitterRTPC(ParameterName, Emitter, ComponentName, Source)
  return self.AudioManager:GetEmitterRTPC(ParameterName, Emitter, ComponentName, Source)
end

function NRCAudioManager:ResetEmitterRTPC(ParameterName, Emitter, InterpolateTime, ComponentName, Source)
  return self.AudioManager:ResetEmitterRTPC(ParameterName, Emitter, InterpolateTime, ComponentName, Source)
end

function NRCAudioManager:SetEmitterRTPC(ParameterName, Value, Emitter, InterpolateTime, ComponentName, Source)
  return self.AudioManager:SetEmitterRTPC(ParameterName, Value, Emitter, InterpolateTime, ComponentName, Source)
end

function NRCAudioManager:ResetGlobalRTPC(ParameterName, InterpolateTime, Source)
  return self.AudioManager:ResetGlobalRTPC(ParameterName, InterpolateTime, Source)
end

function NRCAudioManager:GetGlobalRTPC(ParameterName, Source)
  return self.AudioManager:GetGlobalRTPC(ParameterName, Source)
end

function NRCAudioManager:SetGlobalRTPC(ParameterName, Value, InterpolateTime, Source)
  return self.AudioManager:SetGlobalRTPC(ParameterName, Value, InterpolateTime, Source)
end

function NRCAudioManager:SetGlobalSwitch(SwitchGroupName, SwitchName)
  return self.AudioManager:SetGlobalSwitch(SwitchGroupName, SwitchName)
end

function NRCAudioManager:SetEmitterSwitch(SwitchGroupName, SwitchName, Emitter, ComponentName)
  return self.AudioManager:SetEmitterSwitch(SwitchGroupName, SwitchName, Emitter, ComponentName)
end

function NRCAudioManager:IsSwitchAt(SwitchGroupName, SwitchName, TargetActor, ComponentName)
  return self.AudioManager:IsSwitchAt(SwitchGroupName, SwitchName, TargetActor, ComponentName)
end

function NRCAudioManager:IsStateAt(StateGroupName, State)
  return self.AudioManager:IsStateAt(StateGroupName, State)
end

function NRCAudioManager:SetStateByName(StateGroup, State, Source)
  if "Dialogue" == StateGroup then
    self:SetDialogueState(State)
  end
  return self.AudioManager:SetStateByName(StateGroup, State, Source)
end

function NRCAudioManager:BankRequestCallback(Result, SessionId)
  return self.AudioManager:BankRequestCallback(Result, SessionId)
end

function NRCAudioManager:StopWwiseEventForActor(EventId, Emitter, FadeOutTime)
  return self.AudioManager:StopWwiseEventForActor(EventId, Emitter, FadeOutTime)
end

function NRCAudioManager:PlaySound3DWithActorAuto(SoundId, Emitter, Source, bIgnorePlayLimit)
  return self.AudioManager:PlaySound3DWithActorAuto(SoundId, Emitter, Source, bIgnorePlayLimit)
end

function NRCAudioManager:PlaySound3DWithActorByEventNameAuto(EventName, Emitter, Source)
  return self.AudioManager:PlaySound3DWithActorByEventNameAuto(EventName, Emitter, Source)
end

function NRCAudioManager:PlaySound3DWithActor(SoundId, Emitter, Source, bAutoEnd, bStopOnDestroy, ComponentName, bInterrupt)
  return self.AudioManager:PlaySound3DWithActor(SoundId, Emitter, Source, bAutoEnd, bStopOnDestroy, ComponentName, bInterrupt)
end

function NRCAudioManager:PlaySound3DAtLocationAuto(SoundId, Location, Source)
  return self.AudioManager:PlaySound3DAtLocationAuto(SoundId, Location, Source)
end

function NRCAudioManager:PlaySound3DAtLocationByEventNameAuto(EventName, Location, Source)
  return self.AudioManager:PlaySound3DAtLocationByEventNameAuto(EventName, Location, Source)
end

function NRCAudioManager:PlaySound3DAtLocation(SoundId, Location, SourceObject, Source, bAutoEnd, bInterrupt)
  return self.AudioManager:PlaySound3DAtLocation(SoundId, Location, SourceObject, Source, bAutoEnd, bInterrupt)
end

function NRCAudioManager:PlaySound2DAuto(SoundId, Source)
  return self.AudioManager:PlaySound2DAuto(SoundId, Source)
end

function NRCAudioManager:PlaySound2DByEventNameAuto(EventName, Source)
  return self.AudioManager:PlaySound2DByEventNameAuto(EventName, Source)
end

function NRCAudioManager:PlaySound2D(SoundId, Source, bAutoEnd, bInterrupt)
  return self.AudioManager:PlaySound2D(SoundId, Source, bAutoEnd, bInterrupt)
end

function NRCAudioManager:PlayBattleBgm(SoundId, Source)
  return self.AudioManager:PlayBattleBgm(SoundId, Source)
end

function NRCAudioManager:PlayAreaAmbience(SoundId, Source)
  return self.AudioManager:PlayAreaAmbience(SoundId, Source)
end

function NRCAudioManager:PlayBgm(SoundId, StopId, Source)
  return self.AudioManager:PlayBgm(SoundId, StopId, Source)
end

function NRCAudioManager:ReleaseSession(SessionId, bStopEvent, Source, bForceBurn, FadeOutTime)
  if not SessionId then
    return
  end
  return self.AudioManager:ReleaseSession(SessionId, bStopEvent, Source, bForceBurn, FadeOutTime)
end

function NRCAudioManager:LoadBankByName(BankName, Source)
  return self.AudioManager:LoadBankByName(BankName, Source)
end

function NRCAudioManager:StartRegisterSpecialPet()
  return self.AudioManager:StartRegisterSpecialPet()
end

function NRCAudioManager:RegisterSpecialPet(SpecialToken, PetActor)
  self.AudioManager:RegisterSpecialPet(SpecialToken, PetActor)
end

function NRCAudioManager:EndRegisterSpecialPet(SpecialToken)
  self.AudioManager:EndRegisterSpecialPet(SpecialToken)
end

function NRCAudioManager:BatchSetState(states)
  if not states then
    return
  end
  local state_pair = string.split(states, ";")
  local reversed_pairs = {}
  for i = #state_pair - 1, 1, -2 do
    local stateName = state_pair[i + 1]
    local stateGroupName = state_pair[i]
    if stateGroupName and stateName then
      table.insert(reversed_pairs, {stateGroupName, stateName})
    end
  end
  for _, pair in ipairs(reversed_pairs) do
    local stateGroupName = pair[1]
    local stateName = pair[2]
    if stateGroupName and stateName then
      self:SetStateByName(stateGroupName, stateName, "NRCAudioManager:BatchSetState")
    end
  end
end

function NRCAudioManager:BatchSetStateInMap(states, state_map)
  if not states then
    return
  end
  local state_pair = string.split(states, ";")
  for i, str in ipairs(state_pair) do
    if 0 == i % 2 then
      local stateGroupName = state_pair[i - 1]
      local stateName = state_pair[i]
      if stateGroupName and stateName then
        state_map[stateGroupName] = stateName
      end
    end
  end
end

function NRCAudioManager:ClearAllAudioSession(bSameSceneRes, bReconnecting, id)
  if not bSameSceneRes then
    self.AudioManager:ClearAllAudioSession(false)
  end
end

function NRCAudioManager:ClearAllAudioSessionTotally()
  self.AudioManager:ClearAllAudioSession(true)
end

function NRCAudioManager:SetAudioSessionEnable(enable)
  self.AudioManager:SetAudioSessionEnable(enable)
end

function NRCAudioManager:SetAttenuationScalingFactor(Emitter, Scale)
  self.AudioManager:SetAttenuationScalingFactor(Emitter, Scale)
end

function NRCAudioManager:StopAllForActor(actor)
  self.AudioManager:StopAllForActor(actor)
end

function NRCAudioManager:SetAudioLogEnable(enable)
  self.AudioManager:SetAudioLogEnable(enable)
end

function NRCAudioManager:GetMaxTimeFromEventName(EventName)
  return self.AudioManager:GetMaxTimeFromEventName(EventName)
end

function NRCAudioManager:GetPlayPositionInMs(sessionId)
  return self.AudioManager:GetPlayPositionInMs(sessionId)
end

function NRCAudioManager:SeekOnEventBySession(sessionId, percent, soundId)
  self.AudioManager:SeekOnEventBySession(sessionId, percent, soundId)
end

function NRCAudioManager:GetMaxTimeFromID(soundId)
  return self.AudioManager:GetMaxTimeFromID(soundId)
end

function NRCAudioManager:CheckSessionValidAndNotFinished(sessionId)
  return self.AudioManager:CheckSessionValidAndNotFinished(sessionId)
end

function NRCAudioManager:SetCreatingPlayer(isCreating)
  self.CreatingPlayer = isCreating
  self:UpdateMainUIState()
end

function NRCAudioManager:SetMainUIOpen(isOpen)
  self.MainUIOpen = isOpen
  self:UpdateMainUIState()
end

function NRCAudioManager:SetLobbyMainInnerOpen(isOpen)
  self.LobbyMainInnerOpen = isOpen
  self:UpdateMainUIState()
end

function NRCAudioManager:SetDialogueState(State)
  if self.DialogueDelayHandler then
    _G.DelayManager:CancelDelayById(self.DialogueDelayHandler)
    self.DialogueDelayHandler = nil
  end
  if "Open" == State then
    self:SetDialogueOpen(true)
  elseif "Close" == State then
    self.DialogueDelayHandler = _G.DelayManager:DelaySeconds(1, self.SetDialogueOpen, self, false)
  else
    Log.Error("SetDialogue State Invalid Name: ", State)
    self:SetDialogueOpen(false)
  end
end

function NRCAudioManager:SetDialogueOpen(isOpen)
  if self.DialogueDelayHandler then
    _G.DelayManager:CancelDelayById(self.DialogueDelayHandler)
    self.DialogueDelayHandler = nil
  end
  self.DialogueOpen = isOpen
  self:UpdateMainUIState()
end

function NRCAudioManager:UpdateMainUIState()
  if self.MainUIOpen or self.CreatingPlayer then
    self:SetStateByName("Main_UI", "Visible")
  elseif self.LobbyMainInnerOpen then
    self:SetStateByName("Main_UI", "Compass")
  elseif self.DialogueOpen then
    self:SetStateByName("Main_UI", "Dialog")
  else
    self:SetStateByName("Main_UI", "Hidden")
  end
end

function NRCAudioManager:OnEventFinished(sessionId)
  local callbackInfo = self.EventFinishCallback[sessionId]
  self.EventFinishCallback[sessionId] = nil
  if callbackInfo then
    local caller = callbackInfo.caller
    local callback = callbackInfo.callback
    callbackInfo.caller = nil
    callbackInfo.callback = nil
    if callback then
      callback(caller, sessionId)
    end
  end
end

function NRCAudioManager:AddSessionFinishCallback(sessionId, caller, callback)
  if sessionId then
    self.EventFinishCallback[sessionId] = {caller = caller, callback = callback}
  end
end

function NRCAudioManager:RemoveSessionFinishCallback(sessionId)
  if sessionId then
    self.EventFinishCallback[sessionId] = nil
  end
end

function NRCAudioManager:LerpGlobalRTPC(ParameterName, SrcValue, TarValue, InterpolateTime)
  Log.Debug("NRCAudioManager:LerpGlobalRTPC", ParameterName, SrcValue, TarValue, InterpolateTime)
  if ParameterName and self.DelayLerpRTPCMap[ParameterName] then
    _G.DelayManager:CancelDelayById(self.DelayLerpRTPCMap[ParameterName])
    self.DelayLerpRTPCMap[ParameterName] = nil
  end
  self:SetGlobalRTPC(ParameterName, SrcValue, 0)
  local DelayLerpRTPCHandler = _G.DelayManager:DelayFrames(1, function()
    self:SetGlobalRTPC(ParameterName, TarValue, InterpolateTime)
    self.DelayLerpRTPCMap[ParameterName] = nil
  end)
  self.DelayLerpRTPCMap[ParameterName] = DelayLerpRTPCHandler
end

function NRCAudioManager:SetEmitterMute(Emitter, bMute)
  self.AudioManager:SetEmitterMute(Emitter, bMute)
end

function NRCAudioManager:OnCurrentCaveChanged(CurrentCaveName)
  Log.Debug("NRCAudioManager:OnCurrentCaveChanged", CurrentCaveName)
  if self.CaveStateDelayHandler then
    _G.DelayManager:CancelDelay(self.CaveStateDelayHandler)
    self.CaveStateDelayHandler = nil
  end
  self.CaveStateDelayHandler = _G.DelayManager:DelaySeconds(1, self.OnSetCaveState, self, CurrentCaveName)
end

function NRCAudioManager:OnSetCaveState(CurrentCaveName)
  local bExitCave = "" == CurrentCaveName
  if self.bExitCave == bExitCave then
    return
  end
  self.bExitCave = bExitCave
  if bExitCave then
    self:SetStateByName("Cave_State", "Exit")
    self:ReleaseSession(self.CaveSessionId, true)
    self.CaveSessionId = nil
  else
    local Conf = _G.DataConfigManager:GetAudioCaveConf(CurrentCaveName)
    if Conf then
      self:SetStateByName("Cave_State", Conf.state_name)
      self.CaveSessionId = self:PlaySound2DAuto(Conf.sound_id)
    else
      self:SetStateByName("Cave_State", "Enter")
      self.CaveSessionId = self:PlaySound2DAuto(41700389)
    end
  end
end

function NRCAudioManager:SetIsInHome(bIsInHome)
  self.bIsInHome = bIsInHome
end

function NRCAudioManager:GetIsInHome()
  return self.bIsInHome
end

function NRCAudioManager:OnPlayerPetNumChanged(totalPlayerPetNum)
  if not self:GetIsInHome() then
    return
  end
  local allPetHomeLimitConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.PET_HOME_LIMIT_CONF)
  local limitLower = 0
  for k, v in ipairs(allPetHomeLimitConf) do
    if totalPlayerPetNum > limitLower and totalPlayerPetNum <= v.pet_limit then
      self:SetCoolDownOffset(v.cool_down_offset_lower, v.cool_down_offset_upper)
      break
    end
    limitLower = v.pet_limit
  end
end

return NRCAudioManager

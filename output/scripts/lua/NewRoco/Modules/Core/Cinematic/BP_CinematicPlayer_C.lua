require("UnLuaEx")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local CinematicModuleEvent = require("NewRoco.Modules.Core.Cinematic.CinematicModuleEvent")
local BP_CinematicPlayer_C = NRCClass("BP_CinematicPlayer_C")

function BP_CinematicPlayer_C:ReceiveBeginPlay()
  _G.NRCEventCenter:RegisterEvent("BP_CinematicPlayer_C", self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnAppEnterBackground)
  _G.NRCEventCenter:RegisterEvent("BP_CinematicPlayer_C", self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnAppEnterForeground)
end

function BP_CinematicPlayer_C:ReceiveEndPlay(EndPlayReason)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnAppEnterBackground)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnAppEnterForeground)
end

function BP_CinematicPlayer_C:ReceiveTick(DeltaSeconds)
  if not self.isPlaying then
    return
  end
  if not self.Module then
    return
  end
  if GlobalConfig.SkipCG then
    Log.Debug("CinematicModule: Skipping Cinematic ", self.SeqConf.id)
    self.SequencePlayer:Stop()
    self.isPlaying = false
  end
  local CurrentTime = self.SequencePlayer:GetCurrentTime().Time.FrameNumber.Value
  local TimeLeft = self.StopFrame - CurrentTime
  if TimeLeft > 0 then
    return
  elseif DeltaSeconds + TimeLeft >= 0 and false then
    Log.Error("set control rotation", self.Controller:GetViewTarget())
    local EndControlRotation = self.Controller:GetViewTarget():K2_GetActorRotation()
    self.Controller:SetControlRotation(EndControlRotation)
  end
  if self.SeqConf.end_black > 0 then
    self.Module:DispatchEvent(CinematicModuleEvent.OpenBlackScreen, true)
  else
    self.Module:DispatchEvent(CinematicModuleEvent.OpenBlackScreen, false)
  end
  local Player = self:GetCinematicHero()
  self.PlayerTrans = Player.viewObj:GetTransform()
  self.isPlaying = false
end

function BP_CinematicPlayer_C:PreparePlayerForCG(Player)
end

function BP_CinematicPlayer_C:ReleasePlayerFromCG(Player)
end

function BP_CinematicPlayer_C:Play(path, sequence_conf, fsm)
  self.isFailed = false
  if not UE.UObject.IsValid(self) then
    self:FireFinishCallback(true)
    return
  end
  if type(path) ~= "string" then
    self:FireFinishCallback(true)
    Log.Error("BP_CinematicPlayer_C:Play \228\188\160\229\133\165\231\154\132\229\143\130\230\149\176path\228\184\141\230\152\175\228\184\128\228\184\170string", path)
    return
  end
  if self.PendingStop then
    self.PendingStop = nil
    self:FireFinishCallback(true)
    return
  end
  self.Module = _G.NRCModuleManager:GetModule("CinematicModule")
  UE4.UGPMStatics.PerfMarkSkipFrame(1, "SyncLoadSequence")
  Log.Debug("BP_CinematicPlayer_C:Play, start load seqeunce ", path)
  local LevelSequence = LoadObject(path)
  if not LevelSequence then
    Log.Error("Can't find Sequence ", path)
    self:FireFinishCallback(true)
    return
  end
  if GlobalConfig.SkipCG then
    Log.Debug("BP_CinematicPlayer_C:Play, skip by global var SkipCG, return!")
    self:FireFinishCallback(true)
    return
  end
  UE4Helper.ToggleInput(self, false, "Cinematic")
  UE4Helper.SetDesiredShowCursor(false, "BP_CinematicPlayer_C")
  self.isPlaying = false
  self.FSM = fsm
  self:SetSequence(LevelSequence)
  local Setting = UE4.FMovieSceneSequencePlaybackSettings()
  Setting.bAutoPlay = true
  Setting.bDisableMovementInput = self.settings.Disable_MovementInput
  Setting.bDisableLookAtInput = self.settings.Disable_Look_At_Input
  Setting.LoopCount = 0
  Setting.bDisableCameraCuts = self.settings.Disable_Camera_Cuts
  Setting.bHideHud = self.settings.Hide_Hud
  Setting.bHidePlayer = false
  self.PlaybackSettings = Setting
  self.SeqConf = sequence_conf
  self:StopRide()
  UE.UNRCStatics.ToggleRuntimeClipmapCenter(_G.UE4Helper.GetCurrentWorld(), true)
  local CurrentWorld = _G.UE4Helper.GetCurrentWorld()
  self.Hider = CurrentWorld:Abs_SpawnActor(UE4.AActor, self:Abs_GetTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, CurrentWorld)
  Log.Debug("BP_CinematicPlayer_C:Play, start runtime binding")
  self.HiderRef = UnLua.Ref(self.Hider)
  self.Hider:SetActorHiddenInGame(true)
  local Player = self:GetCinematicHero()
  local View = Player and Player.viewObj
  if Player and View then
    DialogueUtils.StopLookAt(Player)
    local MeshComp = View.Mesh
    self.CachedPlayerBoundsScale = MeshComp.BoundsScale
    MeshComp.BoundsScale = 999
    Player:SetVisible(false)
    self:ToggleFadeComp(false)
    _G.GlobalConfig.SyncMovement = false
    if Player.isLocal and Player.movementComponent then
      Player.movementComponent:SetSyncMove(false)
    end
    local MeshBasedPlayerBinding = self:FindNamedBindings("NewBP")
    if self:IsMale() then
      local PlayerBinding = self:FindNamedBindings("Player1")
      if PlayerBinding:Length() > 0 then
        Player:SetVisible(true)
        self:TryUseMeshBasedPlayerBinding(PlayerBinding, MeshBasedPlayerBinding, View)
        self:AddBindingByTag("Player1", View)
        View.CinematicMode = true
      end
      self:AddBindingByTag("Player2", self.Hider)
      self:AddBindingByTag("Mesh2", self.Hider)
      self:AddBindingByTag("Item2", self.Hider)
      self:AddBindingByTag("CopyPlayer2", self.Hider)
    else
      local PlayerBinding = self:FindNamedBindings("Player2")
      if PlayerBinding:Length() > 0 then
        Player:SetVisible(true)
        self:TryUseMeshBasedPlayerBinding(PlayerBinding, MeshBasedPlayerBinding, View)
        self:AddBindingByTag("Player2", View)
        View.CinematicMode = true
      end
      self:AddBindingByTag("Player1", self.Hider)
      self:AddBindingByTag("Item1", self.Hider)
      self:AddBindingByTag("Mesh1", self.Hider)
      self:AddBindingByTag("CopyPlayer1", self.Hider)
    end
    Player:SetCharacterMovementTickEnable(self, false)
  else
    Log.Error("BP_CinematicPlayer_C:Play can't find player view")
  end
  self.SequencePlayer.OnPlay:Add(self, self.OnPlay)
  self.SequencePlayer.OnStop:Add(self, self.OnFinished)
  self.SequencePlayer.OnFinished:Add(self, self.OnFinished)
  self.SequencePlayer.OnSequenceObjectSpawned:Add(self, self.OnObjectSpawned)
  local Duration = self.SequencePlayer:GetDuration()
  local FrameRate = self.SequencePlayer:GetFrameRate()
  self.LastFrame = self.SequencePlayer:GetEndTime().Time.FrameNumber.Value
  self.StopFrame = self.LastFrame - FrameRate.Numerator * 0.75
  self.FSM:SetProperty("Duration", Duration.Time.FrameNumber.Value / Duration.Rate.Numerator)
  self.Controller = _G.UE4Helper.GetPlayerCharacter(0):GetController()
  Log.Debug("BP_CinematicPlayer_C:Play, Sequence Started Playing ", self.SeqConf.id)
  local EnableRebasing = UE4.UNRCStatics.IsEnabledWorldRebasing(CurrentWorld)
  if true == EnableRebasing then
    self:ApplyWorldOffsetToSequence()
  end
  self.SequencePlayer:Play()
  self.isPlaying = true
end

function BP_CinematicPlayer_C:TryUseMeshBasedPlayerBinding(PlayerBindings, MeshBasedPlayerBindings, PlayerView)
  local bMeshBasedPlayerBinding = false
  for i = 1, PlayerBindings:Length() do
    local BindingA = PlayerBindings:Get(i)
    for j = 1, MeshBasedPlayerBindings:Length() do
      local BindingB = MeshBasedPlayerBindings:Get(j)
      if BindingA.Guid == BindingB.Guid then
        bMeshBasedPlayerBinding = true
      end
    end
  end
  if bMeshBasedPlayerBinding and PlayerView then
    self.CachedPlayerMeshTrans = PlayerView.Mesh:GetRelativeTransform()
    PlayerView.Mesh:ResetRelativeTransform()
  end
end

function BP_CinematicPlayer_C:HasTag(Tag)
  local Bindings = self:FindNamedBindings(Tag)
  return Bindings:Length() > 0
end

function BP_CinematicPlayer_C:StopRide()
  local Player = self:GetPlayer()
  if Player then
    Player:StopRide(true)
    if Player.viewObj and Player.viewObj.RocoSkill then
      Player.viewObj.RocoSkill:StopCurrentSkill()
    end
  end
end

function BP_CinematicPlayer_C:OnPlay()
  if self.SeqConf.id == 1610101 then
    _G.GEMPostManager:GEMPostStepEvent("PlayEnterSequence")
  end
  Log.Debug("seq OnPlay, ", self.SeqConf.id)
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeWorldComposition 1")
  local CurrentWorld = UE4Helper.GetCurrentWorld()
  local BindingsKam = self:FindNamedBindings("Camera")
  if BindingsKam:Length() > 0 then
    local CameraBinding = self:FindNamedBinding("Camera")
    if CameraBinding then
      local foundActors = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(CurrentWorld, UE4.ACineCameraActor, "SequencerActor")
      if foundActors:Length() > 0 then
        self.Camera = foundActors:Get(1)
      end
      if not self.Camera then
        self.Camera = CurrentWorld:SpawnActor(UE4.ACineCameraActor, self:GetTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, CurrentWorld)
        self:SetBinding(CameraBinding, {
          self.Camera
        })
      end
    end
    self.Controller:SetViewTargetWithBlend(self.Camera)
  end
  if not self.Camera then
    self.Controller:SetViewTargetWithBlend(self)
  end
  self.OnFinishedTriggered = false
end

function BP_CinematicPlayer_C:IsMale()
  local Player = self:GetCinematicHero()
  return Player and 1 == Player.gender
end

function BP_CinematicPlayer_C:OnFinished()
  Log.Debug("seq finished, ", self.SeqConf.id)
  if self.isPlaying then
    self.Module:DispatchEvent(CinematicModuleEvent.OpenBlackScreen, false)
    local Player = self:GetCinematicHero()
    self.PlayerTrans = Player.viewObj:GetTransform()
    self.isPlaying = false
  end
  if self.OnFinishedTriggered then
    Log.Debug("\229\164\154\230\174\181sequence\228\188\154\232\167\166\229\143\145\229\164\154\228\184\170OnFinish\239\188\140\229\142\187\233\135\141")
    return
  end
  self.OnFinishedTriggered = true
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "WorldTileTool.FreezeWorldComposition 0")
  UE.UNRCStatics.ToggleRuntimeClipmapCenter(_G.UE4Helper.GetCurrentWorld(), false)
  UE4Helper.ToggleInput(self, true, "Cinematic")
  UE4Helper.ReleaseDesiredShowCursor("BP_CinematicPlayer_C")
  self:ResetBindings()
  local Player = self:GetCinematicHero()
  if Player then
    Player.viewObj.CinematicMode = false
    Player.viewObj:OnSequenceEnd()
    self:ToggleFadeComp(true)
    Player:SetVisible(true)
    local View = Player.viewObj
    if self.CachedPlayerMeshTrans then
      View.Mesh:K2_SetRelativeTransform(self.CachedPlayerMeshTrans, false, nil, true)
      self.CachedPlayerMeshTrans = nil
    end
    local MeshComp = View.Mesh
    MeshComp.BoundsScale = self.CachedPlayerBoundsScale
    Player:SetCharacterMovementTickEnable(self, true)
  end
  if self.Camera and UE.UObject.IsValid(self.Camera) then
    self.Camera:K2_DestroyActor()
  end
  self.Camera = nil
  if self.Hider and UE.UObject.IsValid(self.Hider) then
    self.Hider:K2_DestroyActor()
  end
  self.Hider = nil
  self.HiderRef = nil
  _G.GlobalConfig.SyncMovement = true
  if Player.isLocal and Player.movementComponent then
    Player.movementComponent:SetSyncMove(true)
  end
  self:FireFinishCallback(not self.isFailed)
  self.isFailed = false
  if self.SeqConf.id == 1610101 then
    _G.GEMPostManager:GEMPostStepEvent("EnterSequenceEnd")
    _G.GEMPostManager:GEMPostStepEvent("EnterBigWorld")
  end
end

function BP_CinematicPlayer_C:Stop()
  if self.isPlaying then
    self.SequencePlayer:Stop()
    if UE4.URocoSequenceDlcLibrary then
      UE4.URocoSequenceDlcLibrary.ReleaseAudioAndBgmSession()
    end
  else
    self.PendingStop = true
  end
end

function BP_CinematicPlayer_C:Interrupt()
  if self.isPlaying then
    self.isFailed = true
    self.SequencePlayer:Stop()
  end
end

function BP_CinematicPlayer_C:Pause()
  if self.isPlaying then
    self.SequencePlayer:Pause()
  end
end

function BP_CinematicPlayer_C:Resume()
  if self.isPlaying then
    self.SequencePlayer:Play()
  end
end

function BP_CinematicPlayer_C:OnEvent(EventName, IntValue, StringValue)
  local Callback = self.EventCallback
  local Owner = self.CallbackOwner
  if Callback then
    Callback(Owner, EventName, IntValue, StringValue)
  end
end

function BP_CinematicPlayer_C:FireFinishCallback(Success)
  if UE.UObject.IsValid(self) and self.RemoveSequence then
    self:RemoveSequence()
  end
  local Callback = self.FinishCallback
  self.FinishCallback = nil
  self.EventCallback = nil
  local Owner = self.CallbackOwner
  self.CallbackOwner = nil
  if Callback then
    Callback(Owner, Success)
  end
end

function BP_CinematicPlayer_C:SetCallbackOwner(owner)
  self.CallbackOwner = owner
  return self
end

function BP_CinematicPlayer_C:SetFinishCallback(Callback)
  self.FinishCallback = Callback
  return self
end

function BP_CinematicPlayer_C:SetEventCallback(Callback)
  self.EventCallback = Callback
  return self
end

function BP_CinematicPlayer_C:GetPlayer()
  local Player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  return Player
end

function BP_CinematicPlayer_C:GetCinematicHero()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and player:IsTogetherMove2P() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    return other_player
  end
  return player
end

function BP_CinematicPlayer_C:ToggleFadeComp(Enable)
  local Player = self:GetPlayer()
  if not Player then
    return
  end
  local Controller = Player:GetUEController()
  if not Controller or not UE4.UObject.IsValid(Controller) then
    return
  end
  local CameraManager = Controller.PlayerCameraManager
  if not CameraManager then
    return
  end
end

function BP_CinematicPlayer_C:ProcessSubtitleStart(SubtitleID)
  Log.Debug("BP_CinematicPlayer_C:ProcessSubtitleStart", SubtitleID)
  _G.NRCEventCenter:DispatchEvent(CinematicModuleEvent.OnMovieSequenceSubtitleStart, SubtitleID)
end

function BP_CinematicPlayer_C:ProcessSubtitleEnd()
  Log.Debug("BP_CinematicPlayer_C:ProcessSubtitleEnd")
  _G.NRCEventCenter:DispatchEvent(CinematicModuleEvent.OnMovieSequenceSubtitleEnd)
end

function BP_CinematicPlayer_C:OnAppEnterBackground()
  if not UE4.URocoSequenceDlcLibrary then
    Log.Warning("BP_CinematicPlayer_C:OnAppEnterBackground not URocoSequenceDlcLibrary")
    return
  end
  local audioId = UE4.URocoSequenceDlcLibrary.GetSequenceAudioId()
  if audioId > 0 then
    local audioSessionId = UE4.URocoSequenceDlcLibrary.GetSequenceAudioSessionId()
    local audioLength = UE4.URocoSequenceDlcLibrary.GetSequenceAudioLength()
    local audioPosition = UE4.URocoSequenceDlcLibrary.GetPlayPositionInMS(audioSessionId)
    self.SequenceAudioRecord = {
      Id = audioId,
      SessionId = audioSessionId,
      Length = audioLength,
      Position = audioPosition / 1000
    }
    if _G.RocoEnv.PLATFORM_IOS then
      _G.NRCAudioManager:ReleaseSession(audioId, true, self.name)
    end
    Log.Debug("BP_CinematicPlayer_C:OnAppEnterBackground audio", audioId, audioSessionId, audioLength, audioPosition)
  else
    self.SequenceAudioRecord = nil
    Log.Debug("BP_CinematicPlayer_C:OnAppEnterBackground audio not set")
  end
  local bgmId = UE4.URocoSequenceDlcLibrary.GetSequenceBgmId()
  if bgmId > 0 then
    local bgmSessionId = UE4.URocoSequenceDlcLibrary.GetSequenceBgmSessionId()
    local bgmLength = UE4.URocoSequenceDlcLibrary.GetSequenceBgmLength()
    local bgmPosition = UE4.URocoSequenceDlcLibrary.GetPlayPositionInMS(bgmSessionId)
    self.SequenceBgmRecord = {
      Id = bgmId,
      SessionId = bgmSessionId,
      Length = bgmLength,
      Position = bgmPosition / 1000
    }
    if _G.RocoEnv.PLATFORM_IOS then
      _G.NRCAudioManager:ReleaseSession(bgmId, true, self.name)
    end
    Log.Debug("BP_CinematicPlayer_C:OnAppEnterBackground bgm", bgmId, bgmSessionId, bgmLength, bgmPosition)
  else
    self.SequenceBgmRecord = nil
    Log.Debug("BP_CinematicPlayer_C:OnAppEnterBackground bgm not set")
  end
  local CurrentTime = self.SequencePlayer:GetCurrentTime().Time.FrameNumber.Value
  Log.Debug(" BP_CinematicPlayer_C:OnAppEnterBackground", CurrentTime, self.LastFrame)
end

function BP_CinematicPlayer_C:OnAppEnterForeground()
  local CurrentTime = self.SequencePlayer:GetCurrentTime().Time.FrameNumber.Value
  Log.Debug("BP_CinematicPlayer_C:OnAppEnterForeground", self.isPlaying, CurrentTime, self.LastFrame, self.SequenceAudioRecord, self.SequenceBgmRecord)
  if not _G.RocoEnv.IS_SHIPPING then
    local audioSessionId = UE4.URocoSequenceDlcLibrary.GetSequenceAudioSessionId()
    local audioLength = UE4.URocoSequenceDlcLibrary.GetSequenceAudioLength()
    local audioPosition = UE4.URocoSequenceDlcLibrary.GetPlayPositionInMS(audioSessionId)
    local bgmSessionId = UE4.URocoSequenceDlcLibrary.GetSequenceBgmSessionId()
    local bgmLength = UE4.URocoSequenceDlcLibrary.GetSequenceBgmLength()
    local bgmPosition = UE4.URocoSequenceDlcLibrary.GetPlayPositionInMS(bgmSessionId)
    Log.Debug("BP_CinematicPlayer_C:OnAppEnterForeground", audioSessionId, audioLength, audioPosition, bgmSessionId, bgmLength, bgmPosition)
  end
  self:SeekSequenceAudioAndBgm(self.SequenceAudioRecord, true)
  self:SeekSequenceAudioAndBgm(self.SequenceBgmRecord, false)
  self.SequenceAudioRecord = nil
  self.SequenceBgmRecord = nil
end

function BP_CinematicPlayer_C:SeekSequenceAudioAndBgm(record, isAudio)
  if not record then
    return
  end
  if not _G.RocoEnv.PLATFORM_IOS then
    return
  end
  if not self.isPlaying then
    return
  end
  local id = record.Id
  local length = record.Length
  local position = record.Position
  local playFunction, getSessionFunction
  if isAudio then
    playFunction = UE4.URocoSequenceDlcLibrary.PlaySequenceAudio
    getSessionFunction = UE4.URocoSequenceDlcLibrary.GetSequenceAudioSessionId
  else
    playFunction = UE4.URocoSequenceDlcLibrary.PlaySequenceBgm
    getSessionFunction = UE4.URocoSequenceDlcLibrary.GetSequenceBgmSessionId
  end
  if not UE4.URocoSequenceDlcLibrary then
    Log.Warning("BP_CinematicPlayer_C:SeekSequenceAudioAndBgm not URocoSequenceDlcLibrary")
    return
  end
  if position > 0 and length > 0 and playFunction and getSessionFunction then
    playFunction(id)
    local sessionId = getSessionFunction()
    _G.NRCAudioManager:SeekOnEventBySession(sessionId, position / length, id)
    Log.Debug("BP_CinematicPlayer_C:SeekSequenceAudioAndBgm", id, sessionId, position, length, position / length, isAudio)
  end
end

function BP_CinematicPlayer_C:OnObjectSpawned(InObject, InBindingID)
  if not InObject:IsA(UE.ARocoCharacter) then
    return
  end
  local CopyPlayerBindings
  if self:IsMale() then
    CopyPlayerBindings = self:FindNamedBindings("CopyPlayer1")
  else
    CopyPlayerBindings = self:FindNamedBindings("CopyPlayer2")
  end
  if CopyPlayerBindings then
    for i = 1, CopyPlayerBindings:Length() do
      local Binding = CopyPlayerBindings:Get(i)
      if Binding.Guid == InBindingID then
        local Player = self:GetCinematicHero()
        InObject:CopyAppearance(Player.viewObj)
      end
    end
  end
end

return BP_CinematicPlayer_C

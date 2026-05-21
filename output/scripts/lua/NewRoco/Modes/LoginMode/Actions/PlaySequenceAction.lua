local NRCModeAction = require("Core.NRCMode.NRCModeAction")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local Base = NRCModeAction
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")
local CreatePlayerUtils = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerUtils")
local PlaySequenceAction = Base:Extend("PlaySequenceAction")

function PlaySequenceAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.SequenceProperties = properties
  if properties.path == nil then
    Log.Error("Sequence path invalid")
  end
end

function PlaySequenceAction:OnEnter()
  Log.Debug("PlaySequenceAction OnEnter")
  local SystemSettingModule = _G.NRCModuleManager:GetModule("SystemSettingModule")
  if SystemSettingModule and SystemSettingModule:HasPanel("SystemSettingMain") then
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.CloseMainPanel)
  end
  self:InjectProperties()
  self.playerActor = NRCModuleManager:DoCmd(CreatePlayerModuleCmd.GetPlayerActor)
  self:CheckShouldStopDimoMove()
  self.ActorHolder = LoginUtils.GetUObjectHolder()
  if self.SequenceProperties.path == UEPath.LOGIN_ENTER then
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local mesh = localPlayer.viewObj.Mesh.SkeletalMesh
    UE4.UNRCStatics.ForceUpdateStreamingAssets(mesh, 20)
  end
  if not self.ActorHolder.LevelSequenceActor or not UE4.UObject.IsValid(self.ActorHolder.LevelSequenceActor) then
    Log.Warning("LevelSequenceActor\228\184\141\229\173\152\229\156\168\230\136\150\230\151\160\230\149\136\239\188\140\232\183\179\232\191\135Sequence\230\146\173\230\148\190\239\188\140\232\183\175\229\190\132:", self.SequenceProperties.path)
    if self.SequenceProperties.path == UEPath.CREATEPLAYER_ENTER then
      NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadLevelInfo, 1, 0, 0, 0, 0, 0)
      NRCModuleManager:DoCmd(CreatePlayerModuleCmd.RevertCameraToPlayer)
    end
    self:OnSequenceComplete()
    return
  end
  if self.SequenceProperties.PlayRate then
    self.ActorHolder.LevelSequenceActor:SetPlayRate(self.SequenceProperties.PlayRate)
  else
    self.ActorHolder.LevelSequenceActor:SetPlayRate(1.0)
  end
  if self.SequenceProperties.bLoop == true then
    self.ActorHolder.LevelSequenceActor.PlaybackSettings = self.ActorHolder.LevelSequenceActor.LoopSetting
  else
    self.ActorHolder.LevelSequenceActor.PlaybackSettings = self.ActorHolder.LevelSequenceActor.NonLoopSetting
  end
  local curLevelName = LevelHelper:GetLevelName()
  local SequenceToPlay
  if "Login" == curLevelName then
    SequenceToPlay = LoadObject(self.SequenceProperties.path)
  else
    SequenceToPlay = NRCModuleManager:DoCmd(CreatePlayerModuleCmd.GetAsset, self.SequenceProperties.path)
  end
  Log.Debug("PlaySequenceAction Play ", SequenceToPlay)
  if nil == SequenceToPlay then
    Log.Error("Load Sequence fail, check path")
    self:OnSequenceComplete()
  else
    self.ActorHolder.LevelSequenceActor:SetSequence(SequenceToPlay)
  end
  self.ActorHolder.LevelSequenceActor:SetBindingByTag("Player1", {
    self.ActorHolder.Player1
  }, false)
  self.ActorHolder.LevelSequenceActor:SetBindingByTag("Player2", {
    self.ActorHolder.Player2
  }, false)
  self.ActorHolder.LevelSequenceActor:SetBindingByTag("PlayerCenter", {
    self.ActorHolder.PlayerCenter
  }, false)
  self.ActorHolder.LevelSequenceActor:SetBindingByTag("PlayerPet", {
    self.playerActor
  }, false)
  local world = _G.UE4Helper.GetCurrentWorld()
  if not self.ActorHolder.ThePC_Actor then
    local ThePC_Actors = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(world, UE4.AActor, "ThePC_Actor"):ToTable()
    local ThePC_Actor = ThePC_Actors[1]
    self.ActorHolder.ThePC_Actor = ThePC_Actor
  end
  if not self.ActorHolder.ThePlotActor then
    local ThePlotActors = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(world, UE4.AActor, "ThePlotActor"):ToTable()
    local ThePlotActor = ThePlotActors[1]
    self.ActorHolder.ThePlotActor = ThePlotActor
  end
  if not self.ActorHolder.TheCamera_Actor then
    local TheCamera_Actors = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(world, UE4.AActor, "TheCamera_Actor"):ToTable()
    local TheCamera_Actor = TheCamera_Actors[1]
    self.ActorHolder.TheCamera_Actor = TheCamera_Actor
  end
  if not self.ActorHolder.TheCamera then
    local TheCameras = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(world, UE4.AActor, "TheCamera"):ToTable()
    local TheCamera = TheCameras[1]
    self.ActorHolder.TheCamera = TheCamera
  end
  self.ActorHolder.LevelSequenceActor:SetBindingByTag("ThePC_Actor", {
    self.ActorHolder.ThePC_Actor
  }, false)
  local CurLevelName = LevelHelper:GetLevelName()
  if "Login" ~= CurLevelName then
    self.ActorHolder.LevelSequenceActor:SetBindingByTag("ThePlotActor", {
      self.ActorHolder.ThePlotActor
    }, false)
    self.ActorHolder.LevelSequenceActor:SetBindingByTag("TheCamera_Actor", {
      self.ActorHolder.TheCamera_Actor
    }, false)
    self.ActorHolder.LevelSequenceActor:SetBindingByTag("TheCamera", {
      self.ActorHolder.TheCamera
    }, false)
  end
  if self.SequenceProperties.endEvent then
    if nil == self.SequenceProperties.endEvent then
      Log.Error("Sequence endevent is not set")
    end
    NRCEventCenter:RegisterEvent("PlaySequenceAction", self, self.SequenceProperties.endEvent, self.StopSequence)
  else
    self.ActorHolder.LevelSequenceActor:BindDelegateToSequence(self.ActorHolder.LevelSequenceActor.SequencePlayer.OnFinished, self, self.OnSequenceComplete)
  end
  if self.ActorHolder.LevelSequenceActor.SequencePlayer and self.ActorHolder.LevelSequenceActor.SequencePlayer:IsPlaying() then
    self.ActorHolder.LevelSequenceActor.SequencePlayer:GoToEndAndStop()
  end
  if self.SequenceProperties.bPlayReverse then
    self.ActorHolder.LevelSequenceActor.SequencePlayer:PlayReverse()
  else
    self.ActorHolder.LevelSequenceActor.SequencePlayer:Play()
    if _G.GlobalConfig.SkipCG and not self.SequenceProperties.bLoop then
      if self.SequenceProperties.endEvent then
        self:OnSequenceComplete(self.SequenceProperties.endEvent)
      else
        self.ActorHolder.LevelSequenceActor.SequencePlayer:GoToEndAndStop()
        self:OnSequenceComplete()
      end
    end
  end
  UE4Helper.SetDesiredShowCursor(false, "PlaySequenceAction")
  if self.SequenceProperties.bPlayAndContinue then
    self:Finish()
  end
end

function PlaySequenceAction:StopSequence(inEvent)
  Log.Debug("PlaySequenceAction Receive End Event, together with ", inEvent)
  if self.SequenceProperties.blockEndEvent ~= nil and inEvent == self.SequenceProperties.blockEndEvent then
    return
  end
  if self.ActorHolder and self.ActorHolder.LevelSequenceActor and UE4.UObject.IsValid(self.ActorHolder.LevelSequenceActor) and self.ActorHolder.LevelSequenceActor.SequencePlayer then
    self.ActorHolder.LevelSequenceActor.SequencePlayer:GoToEndAndStop()
  end
  UE4Helper.ReleaseDesiredShowCursor("PlaySequenceAction")
  if nil ~= inEvent then
    self.fsm:SendEvent(inEvent, self)
  else
    self:Finish()
  end
end

function PlaySequenceAction:OnSequenceComplete()
  Log.Debug("PlaySequenceAction OnSequenceComplete")
  UE4Helper.ReleaseDesiredShowCursor("PlaySequenceAction")
  if self.ActorHolder and self.ActorHolder.LevelSequenceActor and UE4.UObject.IsValid(self.ActorHolder.LevelSequenceActor) then
    self.ActorHolder.LevelSequenceActor:UnbindDelegateToSequence(self, self.OnSequenceComplete)
  end
  if self.SequenceProperties.path == UEPath.CREATEPLAYER_ENTER then
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadLevelInfo, 1, 0, 0, 0, 0, 0)
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.RevertCameraToPlayer)
  end
  if self.SequenceProperties.path == UEPath.LOGIN_ENTER then
    local Controller = CreatePlayerUtils.GetLoginController()
    self.ActorHolder.Player1:K2_AttachToActor(self.ActorHolder.ThePC_Actor, nil, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, false)
    self.ActorHolder.Player2:K2_AttachToActor(self.ActorHolder.ThePC_Actor, nil, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, false)
    self.ActorHolder.TheCamera:K2_AttachToActor(self.ActorHolder.TheCamera_Actor, nil, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, false)
  end
  if self.SequenceProperties.path == UEPath.NAME_CONFIRM_END_FEMALE then
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenCreatePlayerLoadingUI, true)
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 1)
    self.delayID2 = DelayManager:DelaySeconds(0.5, function()
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.EnterLoginEndVideoFemale)
    end)
  elseif self.SequenceProperties.path == UEPath.NAME_CONFIRM_END_MALE then
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenCreatePlayerLoadingUI, true)
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 1)
    self.delayID3 = DelayManager:DelaySeconds(0.5, function()
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.EnterLoginEndVideoMale)
    end)
  end
  self:Finish()
end

function PlaySequenceAction:OnFinish()
  self:CheckShouldStartDimoMove()
  UE4Helper.ReleaseDesiredShowCursor("PlaySequenceAction")
  NRCEventCenter:UnRegisterEvent(self, self.SequenceProperties.endEvent, self.StopSequence)
end

function PlaySequenceAction:OnExit()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
  UE4Helper.ReleaseDesiredShowCursor("PlaySequenceAction")
  Log.Debug("PlaySequenceAction OnExit:", self.name)
end

function PlaySequenceAction:CheckShouldStopDimoMove()
  if (self.SequenceProperties.path == UEPath.CREATEPLAYER_ENTER or self.SequenceProperties.path == UEPath.LOGIN_ENTER or self.SequenceProperties.path == UEPath.GENDER_CONFIRM_ENTER_FEMALE or self.SequenceProperties.path == UEPath.GENDER_CONFIRM_IDLE_FEMALE or self.SequenceProperties.path == UEPath.GENDER_CONFIRM_ENTER_MALESetMovementMode or self.SequenceProperties.path == UEPath.GENDER_CONFIRM_IDLE_MALE) and self.playerActor then
    if not self.controller then
      self.controller = LoginUtils.GetLoginController()
    end
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.inputComponent then
      localPlayer.inputComponent:SetIgnoreMoveInput(self, true)
    end
    if not _G.GlobalConfig.SkipCG then
      self.delayHandler = DelayManager:DelaySeconds(1, function()
        if self.playerActor and UE4.UObject.IsValid(self.playerActor) and self.playerActor.CharacterMovement and UE4.UObject.IsValid(self.playerActor.CharacterMovement) then
          self.playerActor:SetCharacterMovementTickEnabled(false, "PlaySequenceAction")
          self.playerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
        end
        _G.DelayManager:CancelDelayById(self.delayHandler)
        self.delayHandler = nil
      end)
    elseif self.playerActor and UE4.UObject.IsValid(self.playerActor) and self.playerActor.CharacterMovement and UE4.UObject.IsValid(self.playerActor.CharacterMovement) then
      self.playerActor:SetCharacterMovementTickEnabled(false, "PlaySequenceAction")
      self.playerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    end
  end
end

function PlaySequenceAction:CheckShouldStartDimoMove()
  if self.SequenceProperties.path == UEPath.CREATEPLAYER_ENTER and self.playerActor then
    if not self.controller then
      self.controller = LoginUtils.GetLoginController()
    end
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.inputComponent then
      localPlayer.inputComponent:SetIgnoreMoveInput(self, false)
    end
    if UE4.UObject.IsValid(self.playerActor) and UE4.UObject.IsValid(self.playerActor.CharacterMovement) then
      self.playerActor:SetCharacterMovementTickEnabled(true, "PlaySequenceAction")
      self.playerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    elseif not UE4.UObject.IsValid(self.playerActor) or not UE4.UObject.IsValid(self.playerActor.CharacterMovement) then
      Log.Error("Player is not valid")
    end
  end
end

function PlaySequenceAction:GetSequenceCameraInfo(path)
  if self.SequenceProperties.path == path then
    self.delayId = _G.DelayManager:DelayFrames(1, function()
      if self.ActorHolder.LevelSequenceActor and self.ActorHolder.LevelSequenceActor.SequencePlayer then
        local SequencePlayer = self.ActorHolder.LevelSequenceActor.SequencePlayer
        local bindinggId = self.ActorHolder.LevelSequenceActor:FindNamedBinding("Camera")
        local objs = SequencePlayer:GetBoundObjects(bindinggId)
        if objs:Length() > 0 then
          local camActor = objs:Get(1)
          if camActor:GetCineCameraComponent() then
            local location = camActor:Abs_K2_GetActorLocation()
            local rotation = camActor:Abs_GetTransform().Rotation:ToRotator()
            local CineCameraComponent = camActor:GetCineCameraComponent()
            Log.Error("PlaySequenceAction:GetSequenceCameraInfo:", UE.UObject.GetName(camActor), location, rotation, CineCameraComponent.Filmback.SensorHeight, CineCameraComponent.Filmback.SensorWidth, CineCameraComponent.Filmback.SensorAspectRatio, CineCameraComponent.CurrentFocalLength, CineCameraComponent.bConstrainAspectRatio)
          end
        end
      end
    end)
  end
end

return PlaySequenceAction

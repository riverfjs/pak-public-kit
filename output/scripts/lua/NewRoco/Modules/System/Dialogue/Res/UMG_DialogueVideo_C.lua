local TimeoutEventListener = require("Common.TimeoutEventListener")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local OnlineModuleEvent = require("NewRoco.Modules.Core.Online.OnlineModuleEvent")
local UMG_DialogueVideo_C = _G.NRCPanelBase:Extend("UMG_DialogueVideo_C")

function UMG_DialogueVideo_C:OnConstruct()
  self.EventListener = TimeoutEventListener()
  self.UMG_NRCMedia:OnConstruct(self)
  self.UMG_NRCMedia.bAutoPlay = false
  self.UMG_NRCMedia.MediaPlayer.NativeAudioOut = true
  self.SyncMap = {}
  self.CurrentAudioSyncPoints = {}
  self.ButtonSkip:PlayAnimation(self.ButtonSkip.LightOut, 0.0, 1, UE4.EUMGSequencePlayMode.Forward, 999)
  self:BindInputAction()
  self:BindToAnimationStarted(self.Appear, {
    self,
    function(caller)
      self:SetInputEnable(false)
    end
  })
  self:BindToAnimationFinished(self.Appear, {
    self,
    function(caller)
      self:SetInputEnable(true)
    end
  })
  self:BindToAnimationStarted(self.Disappear, {
    self,
    function(caller)
      self:SetInputEnable(false)
    end
  })
  self:BindToAnimationFinished(self.Disappear, {
    self,
    function(caller)
      self:SetInputEnable(true)
    end
  })
  self.UMG_NRCMedia:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_DialogueVideo_C:SetInputEnable(enabled)
  _G.UE4Helper.ToggleInput(self, enabled, "DialogueVideoBlackScreen")
end

function UMG_DialogueVideo_C:OnDestruct()
  self:SetInputEnable(true)
  self:UnbindAllFromAnimationStarted(self.Appear)
  self:UnbindAllFromAnimationFinished(self.Appear)
  self:UnbindAllFromAnimationStarted(self.Disappear)
  self:UnbindAllFromAnimationFinished(self.Disappear)
  self.UMG_NRCMedia:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  self.SkipMessageOn = nil
  if self.Conf and self.Conf.close_player_tick then
    self:TogglePlayerMovement(true)
  end
  self:TogglePlayerMovementSync(true)
  _G.DelayManager:CancelDelayById(self.WakeUpUITimer)
  self.WakeUpUITimer = nil
end

function UMG_DialogueVideo_C:BindInputAction()
  self:AddButtonListener(self.ButtonSkip.Button, self.OnButtonSkip)
  local mappingContext = self:AddInputMappingContext("IMC_Cinematic")
  if mappingContext then
    mappingContext:BindAction("IA_Cinematic_WakeupUI", self, "OnWakeupUI")
  end
end

function UMG_DialogueVideo_C:OnDeactive()
  Log.Debug("UMG_DialogueVideo_C:OnDeactive")
  if self.ResetActionAfterBlack then
    self.ResetActionAfterBlack = false
    self:ResetAction()
  end
  self.UMG_NRCMedia:OnDeactive()
  _G.NRCAudioManager:SetStateByName("Story_Movie", "None", "UMG_DialogueVideo:OnActive")
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  self:CancelDelay()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.Video)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.inputComponent then
    player.inputComponent:PlayDialogueVideo(false)
  end
  if self.Conf and self.Conf.close_player_tick then
    self:TogglePlayerMovement(true)
  end
  self:TogglePlayerMovementSync(true)
end

function UMG_DialogueVideo_C:ResetAction()
  if self.Action and self.Action.Owner then
    self.Action.Owner.inActionArea = false
    if self.Action.Lock then
      self.Action:Lock(false)
    end
  end
end

function UMG_DialogueVideo_C:OnConnected(errorCode)
  Log.Warning("OnConnected during video", errorCode)
  if 0 == errorCode and (self.UMG_NRCMedia.MediaPlayer:IsPlaying() or self.UMG_NRCMedia.MediaPlayer:IsPaused()) then
    self.ResetActionAfterBlack = true
    UE4Helper.SetEnableWorldRendering(nil, false, "UMG_DialogueVideo_C")
    self:CancelDelay()
    self:CloseMovie()
    self:SendFinishEvent(false)
    self:DoClose()
  end
end

function UMG_DialogueVideo_C:OnDisconnect()
  self.UMG_NRCMedia:Pause()
  if self.Action and self.Action.Lock then
    self.Action:Lock(true)
  end
end

function UMG_DialogueVideo_C:DebugAddVideo(_param)
  local conf = _param.Conf
  if conf then
    local isFile = not _param.Conf.isUrl
    local NextVideoFilePath = ""
    NextVideoFilePath = conf.movie_path
    local NextSoundID = conf.sound_id
    local NextSubtitleTrackID = conf.subtitle_track_id
    self:Log("UMG_DialogueVideo_C:DebugAddVideo ", NextVideoFilePath, NextSoundID, NextSubtitleTrackID)
    self.UMG_NRCMedia:AddNextVideo(NextVideoFilePath, false, NextSoundID, NextSubtitleTrackID)
  end
end

function UMG_DialogueVideo_C:OnActive(_param)
  self.RetryTimes = 10
  self.IsRetrying = false
  NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  if _param.From == "VideoShare" then
    local viewport = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
    self.UMG_NRCMedia:SetNRCMediaImageSize(viewport.X, viewport.Y)
    NRCModuleManager:DoCmd(FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_MARK_VIDEO_SOCIAL_SHARE)
    self.IsVideoShare = true
  else
    NRCModuleManager:DoCmd(FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_CG)
  end
  self.Action = _param.Action
  self.Caller = _param.Caller
  self.Callback = _param.Callback
  self.bIsSync = _param.bIsSync
  self.BeginFadeOutCallback = _param.BeginFadeOutCallback
  self.MediaOpenCallback = _param.MediaOpenCallback
  self.Conf = _param.Conf
  self.CustomBlackScreen = _param.CustomBlackScreen
  self.bPendingDone = false
  if self.Conf then
    self.VideoFilePath = self.Conf.movie_path
    self.SoundID = self.Conf.sound_id
    self.SubtitleTrackID = self.Conf.subtitle_track_id
    if self.Conf and self.Conf.audio_state and self.Conf.audio_state ~= "" then
      _G.NRCAudioManager:SetStateByName("Story_Movie", self.Conf.audio_state, "UMG_DialogueVideo:OnActive")
      Log.DebugFormat("UMG_DialogueVideo_C:OnActive Set Audio State %s", self.Conf.audio_state)
    else
      _G.NRCAudioManager:SetStateByName("Story_Movie", "Story", "UMG_DialogueVideo:OnActive")
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.PauseTip, TipEnum.TipsPauseReason.Video)
    if self.UMG_NRCMedia then
      self.UMG_NRCMedia:OnActive()
      self.UMG_NRCMedia:SetNRCMediaImageSize(MediaUtils.DIALOGUE_VIDEO_RESOLUTION.X, MediaUtils.DIALOGUE_VIDEO_RESOLUTION.Y)
      self.UMG_NRCMedia:SetEnableOpenFailedDialogue(true)
    end
    if self.Conf.begin_black_fade_in > 0 then
      self:PlayAnimation(self.Appear)
    else
      self:PreStartMovie()
      self:StartPlayMovie()
    end
    if self.Conf and self.Conf.close_player_tick then
      self:TogglePlayerMovement(false)
    end
    self:TogglePlayerMovementSync(false)
  end
end

function UMG_DialogueVideo_C:TogglePlayerMovement(Enable)
  Enable = true == Enable
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local View = Player.viewObj
  if not View then
    return
  end
  if View.BP_RideComponent and View.BP_RideComponent.RidePet then
    View = View.BP_RideComponent.RidePet
  end
  Player:SetCharacterMovementTickEnable(self, Enable)
  self:Log("Toggle player movement component tick enable", Enable)
end

function UMG_DialogueVideo_C:TogglePlayerMovementSync(Enable)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  if Player.isLocal and Player.movementComponent and Player.movementComponent.SetSyncMove then
    Player.movementComponent:SetSyncMove(Enable)
  end
end

function UMG_DialogueVideo_C:OnAnimationFinished(Animation)
  if Animation == self.Appear then
    self:PreStartMovie()
    self:StartPlayMovie()
  elseif Animation == self.Disappear then
    self:SendFinishEvent(true)
    self:DoClose()
  end
end

function UMG_DialogueVideo_C:PreStartMovie()
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_WHITE_SCREEN)
  _G.UE4Helper.SetEnableWorldRendering(false, false, "UMG_DialogueVideo_C")
  collectgarbage("collect")
  UE4.UNRCStatics.ForceGarbageCollection(true)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local movie_id = self.Conf and self.Conf.id
  if player and player:IsInTogetherMove() and not player:IsTogetherMove2P() and movie_id and movie_id > 0 and self.Conf and not self.Conf.not_project then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player then
      local other_player_id = other_player:GetServerId()
      local req = _G.ProtoMessage:newZoneClientOperationReq()
      req.operation.operator_id = player:GetServerId()
      req.operation.operator_type = ProtoEnum.ClientOperationType.COT_TOGETHER_MOVIE
      req.operation.aim_info = nil
      req.operation.npc_action_info = nil
      req.operation.catch_info = nil
      req.operation.player_perform_info = nil
      req.operation.cinematic_info = nil
      req.operation.movie_info.target_npc_id = other_player_id
      req.operation.movie_info.movie_id = movie_id
      req.operation.movie_info.sync_type = ProtoEnum.PlayerOperationSyncType.POST_START
      Log.Debug("UMG_DialogueVideo_C:PreStartMovie, send client operation start", movie_id)
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req, self, self.OnSyncReqRsp)
    end
  end
end

function UMG_DialogueVideo_C:OnSyncReqRsp(rsp)
  Log.Debug("DialogueModule:OnSyncReqRsp, on client operation req rsp", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
end

function UMG_DialogueVideo_C:StartPlayMovie()
  if _G.GlobalConfig.SkipVideo then
    if _G.GlobalConfig.PrepareForCE then
      _G.GlobalConfig.SkipVideo = false
    end
    self:MovieDone()
    return
  end
  Log.Debug("UMG_DialogueVideo_C:StartPlayMovie", self.VideoFilePath)
  self.UMG_NRCMedia:AddOnEndReached(self, self.MovieDone)
  self.UMG_NRCMedia:AddOnMediaOpenFailed(self, self.MovieFailed)
  self.UMG_NRCMedia:AddOnMediaOpened(self, self.MediaOpened)
  self.UMG_NRCMedia:AddOnMediaClosed(self, self.MediaClosed)
  self.UMG_NRCMedia:SetVisibility(UE4.ESlateVisibility.Hidden)
  local paramTable = {
    source = self.VideoFilePath,
    needAutoPlay = true,
    isLoop = false,
    OpenResultCaller = self,
    OpenResultCallback = self.MovieFailed,
    soundID = self.SoundID,
    videoSubtitleTrackID = self.SubtitleTrackID,
    forceStopAudioWhenClose = false
  }
  self.UMG_NRCMedia:OpenMediaPanelByParamTable(paramTable)
  self.bIsOpeningMediaPanel = true
  _G.NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnMediaEnterBackground)
  _G.NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnMediaEnterForeground)
  _G.NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, DialogueModuleEvent.HaltVideo, self.OnHaltVideo)
  _G.NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, DialogueModuleEvent.PauseVideo, self.OnPauseVideo)
  _G.NRCEventCenter:RegisterEvent("UMG_DialogueVideo_C", self, DialogueModuleEvent.ResumeVideo, self.OnResumeVideo)
end

function UMG_DialogueVideo_C:OnResumeVideo()
  Log.Debug("UMG_DialogueVideo_C:OnResumeVideo")
  self.UMG_NRCMedia:Play()
end

function UMG_DialogueVideo_C:OnPauseVideo()
  Log.Debug("UMG_DialogueVideo_C:OnPauseVideo")
  self.UMG_NRCMedia:Pause()
end

function UMG_DialogueVideo_C:OnHaltVideo()
  if self.UMG_NRCMedia.MediaPlayer:IsPlaying() then
    self:CloseMovie()
    self:MovieDone()
  end
end

function UMG_DialogueVideo_C:CloseMovie(bForceStop)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnMediaEnterBackground)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnMediaEnterForeground)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.HaltVideo, self.OnHaltVideo)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.PauseVideo, self.OnPauseVideo)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.ResumeVideo, self.OnResumeVideo)
  self.UMG_NRCMedia:RemoveOnEndReached(self, self.MovieDone)
  self.UMG_NRCMedia:RemoveOnMediaOpenFailed(self, self.MovieFailed)
  self.UMG_NRCMedia:RemoveOnMediaOpened(self, self.MediaOpened)
  self.UMG_NRCMedia:RemoveOnMediaClosed(self, self.MediaClosed)
  self.UMG_NRCMedia:CloseMedia(bForceStop)
end

function UMG_DialogueVideo_C:OnMediaEnterBackground()
  Log.Warning("UMG_DialogueVideo_C:OnMediaEnterBackground pause video")
  self.UMG_NRCMedia:Pause()
  self.CurrentSpan = self.UMG_NRCMedia.MediaPlayer:GetTime()
end

function UMG_DialogueVideo_C:OnMediaEnterForeground()
  Log.Warning("OnMediaEnterForeground resume video")
  if self.CurrentSpan then
    self.UMG_NRCMedia:Seek(self.CurrentSpan)
    self.UMG_NRCMedia:Play()
  end
end

function UMG_DialogueVideo_C:MovieFailed()
  if self.IsRetrying then
    Log.Debug("UMG_DialogueVideo_C:MovieFailed already retrying, ignore")
    return
  end
  self.bIsOpeningMediaPanel = false
  self:CancelDelay()
  self:CloseMovie()
  if self.RetryTimes > 0 then
    self.IsRetrying = true
    self.RetryTimes = self.RetryTimes - 1
    Log.Error("\232\167\134\233\162\145\230\137\147\229\188\128\229\164\177\232\180\165\239\188\1400.5\231\167\146\229\144\142\233\135\141\232\175\149", self.VideoFilePath, self.RetryTimes)
    if self.UMG_NRCMedia then
      self.UMG_NRCMedia:SetEnableOpenFailedDialogue(false)
    end
    self:DelaySeconds(0.5, function()
      self.IsRetrying = false
      self:StartPlayMovie()
    end, self)
  else
    Log.Error("\232\167\134\233\162\145\230\137\147\229\188\128\229\164\177\232\180\165", self.VideoFilePath, self.RetryTimes)
    UE4Helper.SetEnableWorldRendering(nil, false, "UMG_DialogueVideo_C")
    self:SendFinishEvent(true)
    self:WaitFadeOut()
  end
end

function UMG_DialogueVideo_C:MovieDone(bForceStop)
  Log.Debug("UMG_DialogueVideo_C:MovieDone", self.VideoFilePath)
  self.bIsOpeningMediaPanel = false
  if self.bPendingDone then
    return
  end
  self.bPendingDone = true
  UE4Helper.SetEnableWorldRendering(nil, false, "UMG_DialogueVideo_C")
  self:CancelDelay()
  self:CloseMovie(bForceStop)
  self:PostDialogueVideoDone()
  self:WaitFadeOut(bForceStop)
end

function UMG_DialogueVideo_C:MediaOpened()
  Log.Debug("UMG_DialogueVideo_C:MediaOpened", self.VideoFilePath)
  self.bIsOpeningMediaPanel = false
  self:CancelDelay()
  self.IsRetrying = false
  self.UMG_NRCMedia:SetVisibility(UE4.ESlateVisibility.Visible)
  self.UMG_NRCMedia:Play()
  if self.MediaOpenCallback then
    local callback = self.MediaOpenCallback
    self.MediaOpenCallback = nil
    callback(self.Caller)
  end
end

function UMG_DialogueVideo_C:LatentPlay()
  self.UMG_NRCMedia:Seek(UE.UKismetMathLibrary.FromSeconds(0))
  self.UMG_NRCMedia:Play()
end

function UMG_DialogueVideo_C:MediaClosed()
  Log.Debug("UMG_DialogueVideo_C:MediaClosed", self.VideoFilePath)
end

function UMG_DialogueVideo_C:WaitFadeOut(bForceStop)
  if self.BeginFadeOutCallback then
    if self.Caller then
      self.BeginFadeOutCallback(self.Caller)
    else
      self.BeginFadeOutCallback()
    end
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  self.SkipMessageOn = nil
  if self.ButtonSkip:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
    self.ButtonSkip:PlayAnimation(self.ButtonSkip.LightOut)
  end
  _G.DelayManager:CancelDelayById(self.WakeUpUITimer)
  self.WakeUpUITimer = nil
  Log.Debug("UMG_DialogueVideo_C:WaitFadeOut", self.VideoFilePath)
  if self.CustomBlackScreen then
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OPEN_BLACK_SCREEN, false)
  end
  if self.Conf and self.Conf.id then
    local TaskIDs = _G.DataConfigManager:GetMovieUsedByTaskConf(self.Conf.id, true)
    if TaskIDs and #TaskIDs.task_id > 0 then
      for _, TaskID in ipairs(TaskIDs.task_id) do
        local Task = NRCModuleManager:DoCmd(TaskModuleCmd.getTaskByID, TaskID)
        local bValidTask = nil ~= Task
        if bValidTask then
          NRCModuleManager:DoCmd(BlackScreenModuleCmd.OpenGlobalBlackScreenIfNeed, TaskID, false)
        end
      end
    end
  end
  self:FadeOut(not bForceStop)
end

function UMG_DialogueVideo_C:FadeOut(bIsTimeout)
  if bIsTimeout then
    Log.Debug("UMG_DialogueVideo_C:FadeOut timeout", self.VideoFilePath)
    self:PlayAnimation(self.Disappear)
  else
    Log.Debug("UMG_DialogueVideo_C:FadeOut", self.VideoFilePath)
    self:SendFinishEvent(true)
    self:DoClose()
  end
end

function UMG_DialogueVideo_C:SendFinishEvent(bSuccess)
  Log.Debug("UMG_DialogueVideo_C:SendFinishEvent", bSuccess)
  if self.IsVideoShare then
    NRCModuleManager:DoCmd(FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MARK_VIDEO_SOCIAL_SHARE)
    self.IsVideoShare = nil
  else
    NRCModuleManager:DoCmd(FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_CG)
  end
  if self.Action then
    self.Action:EndAction()
  end
  self:FireCallback(bSuccess)
end

function UMG_DialogueVideo_C:FireCallback(...)
  local Caller = self.Caller
  local Callback = self.Callback
  self.Caller = nil
  self.Callback = nil
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.VideoOnlyDialogueOver)
  if not Callback then
    return
  end
  if Caller then
    Callback(Caller, ...)
  else
    Callback(...)
  end
end

function UMG_DialogueVideo_C:PostDialogueVideoDone()
  local restart_bgm = self.Conf and self.Conf.restart_bgm
  if restart_bgm then
    _G.NRCAudioManager:StopWwiseEventForActor(9031, nil)
  end
  local mute_time = self.Conf and self.Conf.mute_time
  if mute_time and 0 ~= mute_time then
    _G.NRCAudioManager:LerpGlobalRTPC("Seq_Ducking", 0, 1, mute_time / 1000)
  end
  Log.Debug("UMG_DialogueVideo_C:PostDialogueVideoDone", restart_bgm, mute_time)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local movie_id = self.Conf and self.Conf.id
  if player and player:IsInTogetherMove() and not player:IsTogetherMove2P() and movie_id and movie_id > 0 and self.Conf and not self.Conf.not_project then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player then
      local other_player_id = other_player:GetServerId()
      local req = _G.ProtoMessage:newZoneClientOperationReq()
      req.operation.operator_id = player:GetServerId()
      req.operation.operator_type = ProtoEnum.ClientOperationType.COT_TOGETHER_MOVIE
      req.operation.aim_info = nil
      req.operation.npc_action_info = nil
      req.operation.catch_info = nil
      req.operation.player_perform_info = nil
      req.operation.cinematic_info = nil
      req.operation.movie_info.target_npc_id = other_player_id
      req.operation.movie_info.movie_id = movie_id
      req.operation.movie_info.sync_type = ProtoEnum.PlayerOperationSyncType.POST_END
      Log.Debug("UMG_DialogueVideo_C:PostDialogueVideoDone, send client operation end", movie_id)
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req, self, self.OnSyncReqRsp)
    end
  end
end

function UMG_DialogueVideo_C:OnButtonSkip()
  if self.bIsOpeningMediaPanel then
    return
  end
  if self:IsAnimationPlaying(self.Appear) or self:IsAnimationPlaying(self.Disappear) then
    return
  end
  if not self.Conf or not self.Conf.skippable then
    return
  end
  if self.SkipMessageOn then
    return
  end
  if self.Conf and self.Conf.not_skip_check then
    self:OnConfirmSkipClick(true)
    return
  end
  self.SkipMessageOn = true
  OpenMessageBoxWthCaller(LuaText.Title_CinematicSkip, LuaText.Msg_CinematicSkip, LuaText.CONFIRM, LuaText.CANCEL, DialogContext.Mode.OK_CANCEL, self.OnConfirmSkipClick, self, nil, true)
end

function UMG_DialogueVideo_C:OnConfirmSkipClick(bResult)
  self.SkipMessageOn = nil
  if bResult then
    self:MovieDone(true)
  end
end

function UMG_DialogueVideo_C:OnWakeupUI()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.isDestruct then
    return
  end
  if self.bPendingDone then
    return
  end
  if self.bIsOpeningMediaPanel then
    return
  end
  if self:IsAnimationPlaying(self.Appear) or self:IsAnimationPlaying(self.Disappear) then
    return
  end
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and self.bIsSync and player:IsInTogetherMove() and player:IsTogetherMove2P() then
    return
  end
  if not self.Conf or not self.Conf.skippable then
    return
  end
  if self.ButtonSkip:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self.ButtonSkip:PlayAnimation(self.ButtonSkip.FadeIn)
  end
  _G.DelayManager:CancelDelayById(self.WakeUpUITimer)
  local DelayTime = _G.DataConfigManager:GetTaskGlobalConfig("movie_skippable_time", false)
  DelayTime = (DelayTime and DelayTime.num or 15000) / 1000.0
  self.WakeUpUITimer = _G.DelayManager:DelaySeconds(DelayTime, function()
    self.WakeUpUITimer = nil
    if self.ButtonSkip and self.ButtonSkip:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
      self.ButtonSkip:PlayAnimation(self.ButtonSkip.LightOut)
    end
  end)
end

function UMG_DialogueVideo_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if self.bPendingDone then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  Log.Info("UMG_DialogueVideo_C:OnTouchStarted, on touch started")
  self:OnWakeupUI()
  return UE4.UWidgetBlueprintLibrary.Handled()
end

return UMG_DialogueVideo_C

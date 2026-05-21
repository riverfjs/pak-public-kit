local PandoraVideoPlayerWidget_C = _G.NRCViewBase:Extend("PandoraVideoPlayerWidget_C")
local FFP_MSG_CODE = {
  FFP_MSG_ERROR = 100,
  FFP_MSG_PREPARED = 200,
  FFP_MSG_COMPLETED = 300,
  FFP_MSG_LOOP_COMPLETED = 301,
  FFP_MSG_PROGRESS = 310,
  FFP_MSG_VIDEO_SIZE_CHANGED = 400,
  FFP_MSG_VIDEO_RENDERING_START = 402,
  FFP_MSG_AUDIO_RENDERING_START = 403,
  FFP_MSG_BUFFERING_START = 500,
  FFP_MSG_BUFFERING_END = 501,
  FFP_MSG_BUFFERING_UPDATE = 502,
  FFP_MSG_BUFFERING_BYTES_UPDATE = 503,
  FFP_MSG_BUFFERING_TIME_UPDATE = 504,
  FFP_MSG_SEEK_COMPLETE = 600,
  FFP_MSG_PLAYBACK_STATE_CHANGED = 700,
  FFP_MSG_TIMED_TEXT = 800,
  FFP_MSG_ACCURATE_SEEK_COMPLETE = 900,
  FFP_MSG_BUFFER_FAIL_WEAK_NETWORK = 1010,
  FFP_MSG_OPEN_URL_ERROR = 1020,
  FFP_MSG_RECONNECT_FAIL_AND_EXIT = 1030,
  FFP_MSG_OPEN_CACHE_FILE_ERROR = 1040,
  FFP_MSG_DECODEC_OVERLOAD = 1200,
  PDR_MSG_APP_PAUSED = 2000,
  PDR_MSG_APP_FOCUS = 2001,
  PDR_ASSIGN_FIRST_TEXTURE = 5001,
  PDR_SET_NEXT_VIDEO_SUCC = 5002,
  PDR_SET_NEXT_VIDEO_FAIL = 5003,
  PDR_PLAY_NEXT_VIDEO_SUCC = 5004,
  PDR_LOAD_VIDEO_DLL_FAIL = 11000,
  MEDIACODEC_COLOR_FORMAT_ERROR = 1717869,
  MEDIACODEC_QUEUEINPUTBUFFER_ERROR = 1717870,
  MEDIACODEC_CREATE_CODEC_ERROR = 1717871,
  MEDIACODEC_CONFIG_ERROR = 1717872,
  MEDIACODEC_START_ERROR = 1717873,
  MEDIACODEC_DELETE_ERROR = 1717874,
  MEDIACODEC_FLUSH_ERROR = 1717875,
  MEDIACODEC_CODEC_ENABLE = 1717876,
  FFMPEG_CODEC_ENABLE = 1717877
}
local PMediaStatus = {
  NoPlay = 0,
  PreParing = 1,
  Playing = 2,
  Pause = 3,
  Completed = 4
}
local MediaPlayer_Event = {
  OnEndReached = "OnEndReached",
  OnMediaOpenFailed = "OnMediaOpenFailed",
  OnMediaOpened = "OnMediaOpened",
  OnMediaClosed = "OnMediaClosed",
  OnSeekCompleted = "OnSeekCompleted",
  OnPlaybackSuspended = "OnPlaybackSuspended",
  OnPlaybackResumed = "OnPlaybackResumed",
  OnPlaybackStateChanged = "OnPlaybackStateChanged",
  OnSetNextVideoFail = "OnSetNextVideoFail",
  OnSetNextVideoSucc = "OnSetNextVideoSucc",
  OnPlayNextVideoSuccess = "OnPlayNextVideoSuccess",
  OnVideoRenderingStart = "OnVideoRenderingStart"
}

function PandoraVideoPlayerWidget_C:Construct()
  self.Overridden.Construct(self)
  _G.NRCViewBase.Construct(self)
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:Play("", false)
    self.PVideoImage_Instance:Close()
    if RocoEnv.IS_EDITOR or RocoEnv.PLATFORM_WINDOWS then
      self.PVideoImage_Instance:SetHardwareDecodec(false)
    end
  end
  _G.UE4.UNRCStatics:SetPandoraVideoPlayerWidgetFileDelegate()
end

function PandoraVideoPlayerWidget_C:OnConstruct()
  self:AddDelegateListener(self.OnPlayerEventDelegate, self.LuaOnPlayerEvent)
  self._eventDispatcher = {}
  EventDispatcher():Attach(self._eventDispatcher)
  self:UseFileDelegate(true)
  self._resReqCoverTexture = nil
  self:PrePlayReset()
end

function PandoraVideoPlayerWidget_C:OnDestruct()
  self:RemoveDelegateListener(self.OnPlayerEventDelegate)
  if self._eventDispatcher then
    self._eventDispatcher:RemoveAllListeners()
  end
  if self._resReqCoverTexture then
    _G.NRCResourceManager:UnLoadRes(self._resReqCoverTexture)
  end
  self._resReqCoverTexture = nil
end

function PandoraVideoPlayerWidget_C:OnActive()
end

function PandoraVideoPlayerWidget_C:OnDeactive()
end

function PandoraVideoPlayerWidget_C:SetNextVideo(isFile, nextVideoUrl, bLoop)
  self:Log("PandoraVideoPlayerWidget_C:SetNextVideo ", nextVideoUrl, bLoop)
  self:UseFileDelegate(isFile and true or false)
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:SetNextVideo(nextVideoUrl, bLoop)
  end
end

function PandoraVideoPlayerWidget_C:EnableCacheResource(bEnable, cachePath)
  self:Log("PandoraVideoPlayerWidget_C:EnableCacheResource ", bEnable, cachePath)
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:EnableCacheResource(bEnable, cachePath)
  end
end

function PandoraVideoPlayerWidget_C:ClearCacheResource(cachePath)
  self:Log("PandoraVideoPlayerWidget_C:ClearCacheResource ", cachePath)
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:ClearCacheResource(cachePath)
  end
end

function PandoraVideoPlayerWidget_C:GetTime()
  if self.PVideoImage_Instance then
    local currentTime = self.PVideoImage_Instance:GetCurrentPosition() / 1000.0
    return UE.UKismetMathLibrary.FromSeconds(currentTime)
  end
  return nil
end

function PandoraVideoPlayerWidget_C:GetDuration()
  if self.PVideoImage_Instance then
    local duration = self.PVideoImage_Instance:GetDuration() / 1000.0
    return UE.UKismetMathLibrary.FromSeconds(duration)
  end
  return nil
end

function PandoraVideoPlayerWidget_C:GetTimeMilliseconds()
  if self.PVideoImage_Instance then
    return self.PVideoImage_Instance:GetCurrentPosition()
  end
  return 0.0
end

function PandoraVideoPlayerWidget_C:GetDurationMilliseconds()
  if self.PVideoImage_Instance then
    return self.PVideoImage_Instance:GetDuration()
  end
  return 0.0
end

function PandoraVideoPlayerWidget_C:SetAutoPlay(bAutoPlay)
  self._bAutoPlay = bAutoPlay
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:SetAutoPlay(bAutoPlay)
  end
end

function PandoraVideoPlayerWidget_C:SetLooping(bLoop)
  self._bLoop = bLoop
end

function PandoraVideoPlayerWidget_C:SetDecryptionKey(decryptionKey)
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:SetDecryptionKey(decryptionKey)
  end
end

function PandoraVideoPlayerWidget_C:SetMediaTextureSize(imageSizeX, imageSizeY)
  self.PVideoImage_Instance.Brush.ImageSize = UE4.FVector2D(imageSizeX, imageSizeY)
end

local function PlayInternal(self)
  local rt = self.Overridden.Play(self, self._strUrl, self._bLoop)
  Log.Info("PandoraVideoPlayerWidget_C:Play", self._strUrl, self._bLoop, " rt ", rt)
  if not rt or rt < 0 then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnMediaOpenFailed)
  end
  return rt
end

function PandoraVideoPlayerWidget_C:GetMediaFileOrURL()
  return self._strUrl
end

function PandoraVideoPlayerWidget_C:PrePlayReset()
  self.Overridden.PrePlayReset(self)
end

function PandoraVideoPlayerWidget_C:OpenUrl(strUrl)
  self._strUrl = strUrl
  self:UseFileDelegate(false)
  if self._bAutoPlay then
    return PlayInternal(self)
  end
  return true
end

function PandoraVideoPlayerWidget_C:OpenFile(filePath)
  self._strUrl = filePath
  self:UseFileDelegate(true)
  if self._bAutoPlay then
    return PlayInternal(self)
  end
  return true
end

function PandoraVideoPlayerWidget_C:SetCoverTexture(coverImageFilePath)
  self:Log("PandoraVideoPlayerWidget_C:SetCoverTexture ", coverImageFilePath)
  if not coverImageFilePath or "" == coverImageFilePath then
    return
  end
  if self._resReqCoverTexture then
    _G.NRCResourceManager:UnLoadRes(self._resReqCoverTexture)
  end
  self._resReqCoverTexture = _G.NRCResourceManager:LoadResAsync(self, coverImageFilePath, 0, 0, function(Self, Request, Res)
    self:Log("PandoraVideoPlayerWidget_C:SetCoverTexture LoadResAsync Succeed ", coverImageFilePath)
    if self and self.PVideoImage_Instance then
      local status = self:GetPlayStatus()
      self:Log("status ", status)
      if status == PMediaStatus.NoPlay or status == PMediaStatus.PreParing then
        self.Overridden.SetCoverTexture(self, Res)
      end
      _G.NRCResourceManager:UnLoadRes(Request)
    end
  end, function(Self, Request, ErrMsg)
    self:LogWarning("PandoraVideoPlayerWidget_C:SetCoverTexture LoadResAsync Failed ", ErrMsg)
    _G.NRCResourceManager:UnLoadRes(Request)
  end)
end

function PandoraVideoPlayerWidget_C:Pause()
  self._isPaused = true
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:Pause()
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnPlaybackSuspended)
  end
end

function PandoraVideoPlayerWidget_C:Play()
  if self.PVideoImage_Instance and self._strUrl then
    local status = self:GetPlayStatus()
    if status == PMediaStatus.NoPlay or status == PMediaStatus.Completed then
      return PlayInternal(self)
    else
      if status == PMediaStatus.Pause then
        self.PVideoImage_Instance:Resume()
        return true
      else
      end
    end
  end
  return false
end

function PandoraVideoPlayerWidget_C:Seek(timeSpan)
  if timeSpan and self.PVideoImage_Instance then
    local fTimeSpanInMS = UE.UKismetMathLibrary.GetTotalMilliseconds(timeSpan)
    self.PVideoImage_Instance:SeekMs(math.floor(fTimeSpanInMS))
  end
end

function PandoraVideoPlayerWidget_C:Close()
  if self.PVideoImage_Instance then
    self.PVideoImage_Instance:Close()
  end
end

function PandoraVideoPlayerWidget_C:IsPlaying()
  local status = self:GetPlayStatus()
  return status == PMediaStatus.Playing or status == PMediaStatus.PreParing
end

function PandoraVideoPlayerWidget_C:IsPaused()
  local status = self:GetPlayStatus()
  return self._isPaused or status == PMediaStatus.Pause
end

function PandoraVideoPlayerWidget_C:LuaOnPlayerEvent(EventCode, nParam1, nParam2, strMsg)
  if EventCode == FFP_MSG_CODE.FFP_MSG_PROGRESS or EventCode == FFP_MSG_CODE.FFP_MSG_BUFFERING_UPDATE then
    return
  end
  self:Log("LuaOnPlayerEvent", EventCode, nParam1, nParam2, strMsg)
  if EventCode == FFP_MSG_CODE.FFP_MSG_PREPARED then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnMediaOpened)
  elseif EventCode == FFP_MSG_CODE.FFP_MSG_ERROR then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnMediaOpenFailed)
  elseif EventCode == FFP_MSG_CODE.FFP_MSG_COMPLETED then
    if self._eventDispatcher then
      self._eventDispatcher:SendEvent(MediaPlayer_Event.OnEndReached)
    end
    if self._eventDispatcher then
      self._eventDispatcher:SendEvent(MediaPlayer_Event.OnMediaClosed)
    end
  elseif EventCode == FFP_MSG_CODE.FFP_MSG_SEEK_COMPLETE then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnSeekCompleted)
  elseif EventCode == FFP_MSG_CODE.FFP_MSG_PLAYBACK_STATE_CHANGED then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnPlaybackStateChanged)
  elseif EventCode == FFP_MSG_CODE.PDR_PLAY_NEXT_VIDEO_SUCC then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnPlayNextVideoSuccess)
  elseif EventCode == FFP_MSG_CODE.FFP_MSG_VIDEO_RENDERING_START then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnVideoRenderingStart)
  elseif EventCode == FFP_MSG_CODE.PDR_SET_NEXT_VIDEO_FAIL then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnSetNextVideoFail)
  elseif EventCode == FFP_MSG_CODE.PDR_SET_NEXT_VIDEO_SUCC then
    self._eventDispatcher:SendEvent(MediaPlayer_Event.OnSetNextVideoSucc)
  end
end

function PandoraVideoPlayerWidget_C:AddOnMediaOpened(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnMediaOpened, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnEndReached(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnEndReached, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnMediaClosed(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnMediaClosed, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnMediaOpenFailed(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnMediaOpenFailed, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnSeekCompleted(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnSeekCompleted, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnPlaybackSuspended(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnPlaybackSuspended, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnPlaybackResumed(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnPlaybackResumed, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnPlaybackStateChanged(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnPlaybackStateChanged, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnPlayNextVideoSuccess(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnPlayNextVideoSuccess, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnVideoRenderingStart(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnVideoRenderingStart, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnSetNextVideoFail(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnSetNextVideoFail, Delegate)
end

function PandoraVideoPlayerWidget_C:AddOnSetNextVideoSucc(Caller, Delegate)
  self._eventDispatcher:AddEventListener(Caller, MediaPlayer_Event.OnSetNextVideoSucc, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnMediaOpened(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnMediaOpened, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnEndReached(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnEndReached, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnMediaClosed(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnMediaClosed, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnMediaOpenFailed(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnMediaOpenFailed, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnSeekCompleted(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnSeekCompleted, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnPlaybackSuspended(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnPlaybackSuspended, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnPlaybackResumed(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnPlaybackResumed, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnPlaybackStateChanged(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnPlaybackStateChanged, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnPlayNextVideoSuccess(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnPlayNextVideoSuccess, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnVideoRenderingStart(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnVideoRenderingStart, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnSetNextVideoFail(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnSetNextVideoFail, Delegate)
end

function PandoraVideoPlayerWidget_C:RemoveOnSetNextVideoSucc(Caller, Delegate)
  self._eventDispatcher:RemoveEventListener(Caller, MediaPlayer_Event.OnSetNextVideoSucc, Delegate)
end

return PandoraVideoPlayerWidget_C

local NRCVideoPlayerWidget_C = _G.NRCViewBase:Extend("UMGVideoPlayerWidget_C")

function NRCVideoPlayerWidget_C:OnConstruct()
  self._bIsLoop = false
end

function NRCVideoPlayerWidget_C:PrePlayReset()
end

function NRCVideoPlayerWidget_C:OnDestruct()
end

function NRCVideoPlayerWidget_C:OnActive()
end

function NRCVideoPlayerWidget_C:OnDeactive()
end

function NRCVideoPlayerWidget_C:GetTime()
  if self.MediaPlayer then
    return self.MediaPlayer:GetTime()
  end
  return nil
end

function NRCVideoPlayerWidget_C:GetDuration()
  if self.MediaPlayer then
    return self.MediaPlayer:GetDuration()
  end
  return nil
end

function NRCVideoPlayerWidget_C:GetTimeMilliseconds()
  return UE4.UNRCStatics.GetTotalMillisecondsFromMediaPlayerTime(self.MediaPlayer)
end

function NRCVideoPlayerWidget_C:GetDurationMilliseconds()
  return UE4.UNRCStatics.GetTotalMillisecondsFromMediaPlayerDuration(self.MediaPlayer)
end

function NRCVideoPlayerWidget_C:SetNextVideo(isFile, strNextUrl, bLoop)
end

function NRCVideoPlayerWidget_C:SetDecryptionKey(decryptionKey)
end

function NRCVideoPlayerWidget_C:SetAutoPlay(bAutoPlay)
  self._bAutoPlay = bAutoPlay
  if self.MediaPlayer then
    self.MediaPlayer.PlayOnOpen = bAutoPlay
  end
end

function NRCVideoPlayerWidget_C:OpenUrl(url)
  if not self.MediaPlayer then
    return nil
  end
  if not url then
    return false
  end
  local NewSource = UE4.UNRCStatics.CreateMediaSourceFromUrl(url)
  local mediaOptions = UE4.FMediaPlayerOptions()
  mediaOptions.PlayOnOpen = self._bAutoPlay
  mediaOptions.Loop = self._bIsLoop
  self.MediaPlayer:SetMediaOptions(mediaOptions)
  return self.MediaPlayer:OpenSource(NewSource)
end

function NRCVideoPlayerWidget_C:OpenFile(filePath)
  if not self.MediaPlayer then
    return nil
  end
  if not filePath then
    return false
  end
  local NewSource = UE4.UNRCStatics.CreateMediaSourceFromFilePath(filePath)
  local mediaOptions = UE4.FMediaPlayerOptions()
  mediaOptions.PlayOnOpen = self._bAutoPlay
  mediaOptions.Loop = self._bIsLoop
  self.MediaPlayer:SetMediaOptions(mediaOptions)
  return self.MediaPlayer:OpenSource(NewSource)
end

function NRCVideoPlayerWidget_C:GetMediaFileOrURL()
  return nil
end

function NRCVideoPlayerWidget_C:SetCoverTexture(coverTextureFilePath)
end

function NRCVideoPlayerWidget_C:SetMediaTextureSize(imageSizeX, imageSizeY)
  self.Image_Instance.Brush.ImageSize = UE4.FVector2D(imageSizeX, imageSizeY)
end

function NRCVideoPlayerWidget_C:SetLooping(bLoop)
  self._bIsLoop = bLoop
  if self.MediaPlayer then
    self.MediaPlayer:SetLooping(bLoop)
  end
end

function NRCVideoPlayerWidget_C:Pause()
  if self.MediaPlayer then
    self.MediaPlayer:Pause()
  end
end

function NRCVideoPlayerWidget_C:Play()
  if self.MediaPlayer then
    self.MediaPlayer:Play()
  end
end

function NRCVideoPlayerWidget_C:Seek(timeSpan)
  if self.MediaPlayer then
    self.MediaPlayer:Seek(timeSpan)
  end
end

function NRCVideoPlayerWidget_C:Close()
  if self.MediaPlayer then
    self.MediaPlayer:Close()
  end
end

function NRCVideoPlayerWidget_C:IsPlaying()
  if not self.MediaPlayer then
    return false
  end
  return self.MediaPlayer:IsPlaying()
end

function NRCVideoPlayerWidget_C:IsPaused()
  if not self.MediaPlayer then
    return false
  end
  return self.MediaPlayer:IsPaused()
end

function NRCVideoPlayerWidget_C:AddOnSetNextVideoFail(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:AddOnPlayNextVideoSuccess(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:AddOnVideoRenderingStart(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:AddOnMediaOpened(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnMediaOpened:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnMediaClosed(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnMediaClosed:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnMediaOpenFailed(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnMediaOpenFailed:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnEndReached(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnEndReached:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnPlaybackSuspended(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnPlaybackSuspended:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnPlaybackResumed(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnPlaybackResumed:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnSeekCompleted(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnSeekCompleted:Add(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:AddOnSetNextVideoSucc(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:RemoveOnMediaOpened(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnMediaOpened:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnMediaClosed(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnMediaClosed:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnMediaOpenFailed(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnMediaOpenFailed:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnEndReached(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnEndReached:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnPlaybackSuspended(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnPlaybackSuspended:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnPlaybackResumed(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnPlaybackResumed:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnSeekCompleted(Caller, Delegate)
  if self.MediaPlayer then
    self.MediaPlayer.OnSeekCompleted:Remove(Caller, Delegate)
  end
end

function NRCVideoPlayerWidget_C:RemoveOnPlayNextVideoSuccess(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:RemoveOnVideoRenderingStart(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:RemoveOnSetNextVideoFail(Caller, Delegate)
end

function NRCVideoPlayerWidget_C:RemoveOnSetNextVideoSucc(Caller, Delegate)
end

return NRCVideoPlayerWidget_C

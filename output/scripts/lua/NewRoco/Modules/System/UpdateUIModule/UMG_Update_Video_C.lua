local UMG_Update_Video_C = _G.NRCPanelBase:Extend("UMG_Update_Video_C")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local PlayVideoMode = {BlackScreen = 1, Fade = 2}

function UMG_Update_Video_C:Ctor()
  _G.NRCPanelBase.Ctor(self)
end

function UMG_Update_Video_C:OnConstruct()
  self.VideoMap = {}
  self.AudioMap = {}
  if UE4.UNRCStatics.IsRunningOnWindows() then
    self.AudioMap[UEPath.TENCENT_OPENING] = 1387
    self.AudioMap[UEPath.MOREFUN_OPENING] = 1388
  end
  self.AudioStateMap = {}
  self.AudioStateMap[UEPath.LOGIN_CLOUD_LOOP] = "Login"
  self.AudioStateMap[UEPath.LOGIN_CLOUD_COMP] = "Create_Animation"
  self.CurrentVideo = nil
  self.UMG_NRCMedia:OnConstruct(self)
  self.UMG_NRCMedia:SetVisibility(UE4.ESlateVisibility.Visible)
  self.BlackScreen:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.UMG_NRCMedia:SetNRCMediaImageSize(MediaUtils.COMMON_VIDEO_RESOLUTION.X, MediaUtils.COMMON_VIDEO_RESOLUTION.Y)
end

function UMG_Update_Video_C:OnMediaEnterBackground()
  Log.Debug("UMG_Update_Video_C:OnMediaEnterBackground")
  if self.bForcePause then
    return
  end
  self:RecordTime()
  self.Pausing = true
end

function UMG_Update_Video_C:OnMediaEnterForeground()
  Log.Debug("UMG_Update_Video_C:OnMediaEnterForeground")
  if self.bForcePause then
    return
  end
  self.Pausing = false
  self:SetTime()
end

function UMG_Update_Video_C:RegisterVideoEvents()
  self.VideoMap[UEPath.TENCENT_OPENING] = "Movies/tengxunyouxikaichangCG.mp4"
  self.VideoMap[UEPath.MOREFUN_OPENING] = "Movies/logozuizhongban.mp4"
  self.VideoMap[UEPath.LOGIN_CLOUD_LOOP] = "Movies/Male/White/1.mp4"
  self.VideoMap[UEPath.LOGIN_CLOUD_COMP] = "Movies/Male/White/1.mp4"
  self.VideoMap[UEPath.COMPLIANCE_VIDEO] = "Movies/Compliance.mp4"
  self.VideoMap[UEPath.FULL_OPENING] = "Movies/StartUpMovie.mp4"
  self.VideoMap[UEPath.LOGIN_END_MALE] = "Movies/cg001_m.mp4"
  self.VideoMap[UEPath.LOGIN_END_FEMALE] = "Movies/cg001_f.mp4"
  _G.NRCEventCenter:RegisterEvent("UMG_Update_Video_C", self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnMediaEnterBackground)
  _G.NRCEventCenter:RegisterEvent("UMG_Update_Video_C", self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnMediaEnterForeground)
  _G.NRCEventCenter:RegisterEvent("UMG_Update_Video_C", self, LoginModuleEvent.SkipLoginMovie, self.SkipLoginMovie)
  self.UMG_NRCMedia:AddOnMediaOpened(self, self.OnMediaOpened)
  self.UMG_NRCMedia:AddOnEndReached(self, self.OnMediaEnded)
  self.UMG_NRCMedia:AddOnPlaybackSuspended(self, self.OnMediaPaused)
  self.UMG_NRCMedia:AddOnMediaOpenFailed(self, self.OnMediaOpenFailed)
end

function UMG_Update_Video_C:SkipLoginMovie()
  self.UMG_NRCMedia:Pause()
  self:OnMediaEnded()
end

function UMG_Update_Video_C:UnregisterVideoEvents()
  table.clear(self.VideoMap)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnMediaEnterBackground)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnMediaEnterForeground)
  _G.NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.SkipLoginMovie, self.SkipLoginMovie)
  self.UMG_NRCMedia:RemoveOnMediaOpened(self, self.OnMediaOpened)
  self.UMG_NRCMedia:RemoveOnEndReached(self, self.OnMediaEnded)
  self.UMG_NRCMedia:RemoveOnPlaybackSuspended(self, self.OnMediaPaused)
  self.UMG_NRCMedia:RemoveOnMediaOpenFailed(self, self.OnMediaOpenFailed)
end

function UMG_Update_Video_C:OnMediaPaused()
  if self.PlayVideoMode then
    return
  end
  Log.Debug("OnMediaPaused", self.Pausing, self.Playing)
  if not self.Pausing and self.Playing then
    Log.Debug("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Unexpected Pausing", self.CurrentVideo)
    self.UMG_NRCMedia:CloseMedia()
    self:OnMediaEnded()
  end
end

function UMG_Update_Video_C:SetTime()
  Log.Warning("SetTime", self.CurrentSpan or "No Span", self.CurrentVideo)
  if self.CurrentSpan and self.UMG_NRCMedia then
    self.UMG_NRCMedia:Seek(self.CurrentSpan)
    self.UMG_NRCMedia:Play()
  end
end

function UMG_Update_Video_C:StartPlayVideo()
  if self.UMG_NRCMedia then
    self.UMG_NRCMedia:Play()
  end
  self.bForcePause = false
end

function UMG_Update_Video_C:PauseVideo()
  if self.UMG_NRCMedia then
    self.UMG_NRCMedia:Pause()
  end
  self.bForcePause = true
end

function UMG_Update_Video_C:RecordTime()
  if self.UMG_NRCMedia then
    self.UMG_NRCMedia:Pause()
    self.CurrentSpan = self.UMG_NRCMedia:GetTime()
  end
  Log.WarningFormat("RecordTime+++, %f", self.CurrentSpan:GetTotalMilliseconds())
  Log.Warning("RecordTime", self.CurrentSpan, self.CurrentVideo)
end

function UMG_Update_Video_C:GetNewPlayer()
  if self.UMG_NRCMedia then
    self.UMG_NRCMedia:CloseMedia()
  end
  self:CreateNewPlayer()
  self:CreateNewPlayer2()
end

function UMG_Update_Video_C:TryPlayVideo()
  Log.Debug("TryPlayVideo")
  self.BlackSpeed = 5
  self:UnregisterVideoEvents()
  self:CancelDelay()
  self:RegisterVideoEvents()
  self.UMG_NRCMedia:CloseMedia()
  if self.VideoMap[self.CurrentVideo] then
    local VideoSource = self.VideoMap[self.CurrentVideo]
    local bUseDecrypt = true
    local checkGPUDriverVersion = true
    if self.CurrentVideo == UEPath.FULL_OPENING then
      Log.Info("TryPlayVideo CurrentVideo ", self.CurrentVideo, " UEPath.FULL_OPENING", UEPath.FULL_OPENING, " UseDecrypt = false", "checkGPUDriverVersion = false")
      bUseDecrypt = false
      checkGPUDriverVersion = false
    end
    local paramTable = {
      source = VideoSource,
      needAutoPlay = true,
      isLoop = self.bLoop,
      bEncryptVideo = bUseDecrypt,
      useDefaultCoverTexture = false,
      checkGPUDriverVersion = checkGPUDriverVersion
    }
    self.UMG_NRCMedia:OpenMediaPanelByParamTable(paramTable)
    self:DelaySeconds(3, self.OnOpenMediaTimeout, self)
  else
    Log.Error("\232\181\132\230\186\144\232\183\175\229\190\132\228\184\141\229\175\185\239\188\129\239\188\129\239\188\129")
    LoginUtils.CallAndRemoveCallback(self)
  end
end

function UMG_Update_Video_C:DebugPlayVideo(video_path)
  Log.Debug("DebugPlayVideo")
  self.VideoListMode = false
  self.BlackSpeed = 5
  self:UnregisterVideoEvents()
  self:CancelDelay()
  self:RegisterVideoEvents()
  video_path = string.format("%s%s", UE4.UBlueprintPathsLibrary.ProjectContentDir(), video_path)
  self.UMG_NRCMedia:CloseMedia()
  local paramTable = {
    source = video_path,
    needAutoPlay = true,
    isLoop = self.bLoop,
    useDefaultCoverTexture = false
  }
  self.UMG_NRCMedia:OpenMediaPanelByParamTable(paramTable)
end

function UMG_Update_Video_C:StopPlayVideo()
  Log.Debug("StopPlayVideo")
  self.VideoListMode = false
  self:UnregisterVideoEvents()
  self:CancelDelay()
  self.UMG_NRCMedia:CloseMedia()
end

function UMG_Update_Video_C:OnOpenMediaTimeout()
  Log.Error("\230\137\147\229\188\128\232\181\132\230\186\144\232\182\133\230\151\182\239\188\129\239\188\129\239\188\129", self.CurrentVideo)
  if self.RetryTimes > 0 then
    self.RetryTimes = self.RetryTimes - 1
    self:DelaySeconds(0.5, self.TryPlayVideo, self)
  else
    Log.Error("\232\167\134\233\162\145\230\137\147\229\188\128\229\164\177\232\180\165")
    LoginUtils.CallAndRemoveCallback(self)
  end
end

function UMG_Update_Video_C:OnOpenMediaTimeout1()
  Log.Error("\230\137\147\229\188\128\232\181\132\230\186\144\232\182\133\230\151\182\239\188\129\239\188\129\239\188\129", self.CurrentVideo)
  if (self.RetryTimes or 0) > 0 then
    self.RetryTimes = self.RetryTimes - 1
    self:DelaySeconds(0.5, self.PlayVideo1, self)
  else
    Log.Error("\232\167\134\233\162\145\230\137\147\229\188\128\229\164\177\232\180\165")
  end
end

function UMG_Update_Video_C:OnActive()
  self.UMG_NRCMedia:OnActive()
  self:RegisterVideoEvents()
  if self.UMG_NRCMedia then
    self.UMG_NRCMedia:SetEnableOpenFailedDialogue(false)
  end
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.UIOpened)
  self:GetNewPlayer()
  self.BackgroundAlpha = 1
  self.TargetBackgroundAlpha = 1
  if AppMain:GetFormalPipeline() then
    self.Text:SetText("")
  else
    self.Text:SetText("\231\160\148\229\143\145\228\184\173\231\137\136\230\156\172 \228\184\141\228\187\163\232\161\168\230\184\184\230\136\143\230\156\128\231\187\136\229\147\129\232\180\168")
  end
  self:LoadVideoList()
end

function UMG_Update_Video_C:OnDeactive()
  self:UnregisterVideoEvents()
  self.CurrentVideo = nil
  self.UMG_NRCMedia:OnDeactive()
end

function UMG_Update_Video_C:OnDestruct()
  self.UMG_NRCMedia:OnDestruct()
end

function UMG_Update_Video_C:OnMediaOpenFailed()
  if self.UMG_NRCMedia then
    self.UMG_NRCMedia:SetEnableOpenFailedDialogue(false)
  end
end

function UMG_Update_Video_C:OnMediaOpened()
  Log.Debug("UMG_Update_Video_C:OnMediaOpened")
  if self.VideoListMode and self.PlayVideoMode == PlayVideoMode.Fade and not self.hasFirstPlayed then
    self.hasFirstPlayed = true
  else
  end
  self.Playing = true
  self:CancelDelay()
  if not self.AudioMap or not self.AudioStateMap then
    Log.Error("UMG_Update_Video: media opened but umg not init")
    return
  end
  NRCEventCenter:DispatchEvent(LoginModuleEvent.VideoOpened)
  if self.AudioMap[self.CurrentVideo] then
    _G.NRCAudioManager:PlaySound2DAuto(self.AudioMap[self.CurrentVideo], "UMG_Update_Video_C:OnMediaOpened")
  elseif self.AudioStateMap[self.CurrentVideo] then
    _G.NRCAudioManager:SetStateByName("Login_Game", self.AudioStateMap[self.CurrentVideo], "UMG_Update_Video")
  end
end

function UMG_Update_Video_C:OnMediaEnded()
  if self.VideoListMode then
    return
  end
  self.Playing = false
  Log.Debug("UMG_Update_Video_C:OnMediaEnded")
  self.CurrentVideo = nil
  self.UMG_NRCMedia:CloseMedia()
  LoginUtils.CallAndRemoveCallback(self)
end

function UMG_Update_Video_C:PlayVideo(VideoPath, bLoop, Caller, EndCallback)
  if self.CurrentVideo == VideoPath then
    return
  end
  local VideoSource = self.VideoMap[VideoPath]
  if not VideoSource then
    Log.Error("VideoSource invalid", VideoPath, self.FullStartMovie, self.VideoMap[VideoPath], #self.VideoMap)
    if EndCallback then
      EndCallback(Caller)
    end
    return
  end
  self.CurrentVideo = VideoPath
  if not bLoop then
    LoginUtils.RegisterCallback(self, Caller, EndCallback)
  end
  self.bLoop = bLoop
  self.RetryTimes = 10
  self:TryPlayVideo()
  self:ShowPlayerInfo()
end

function UMG_Update_Video_C:SetBlackScreenAlpha(InAlpha)
  self.TargetBackgroundAlpha = InAlpha
  self.SumTime = 0
end

function UMG_Update_Video_C:ShowPlayerInfo()
  if self.CurrentVideo == "/Game/NewRoco/Modules/System/LoginModule/RawRes/Video/loop_v01.loop_v01" or self.CurrentVideo == "/Game/NewRoco/Modules/System/LoginModule/RawRes/Video/comp_v01.comp_v01" then
    self.Canvas_InfoRight:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Canvas_Info:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.Canvas_InfoRight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Canvas_Info:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local PayerInfo = _G.DataModelMgr.PlayerDataModel.playerInfo
  if PayerInfo then
    local LoginModule = _G.NRCModuleManager:GetModule("LoginModule")
    self.UIDtext:SetText("" .. tostring(PayerInfo.brief_info.uin))
    if LoginModule then
      self.Text_SettingID:SetText(LoginModule.data:GetServer().id)
    end
    self.Text_UIN:SetText(PayerInfo.brief_info.uin)
    self.Text_Gopenid:SetText(PayerInfo.brief_info.openid)
  end
end

function UMG_Update_Video_C:OnAddEventListener()
end

function UMG_Update_Video_C:PlayVideoList()
  self:Log("PlayVideoList VideoListMode ", self.VideoListMode)
  if self.VideoListMode then
    return
  end
  self:SwitchPlayMode()
  self:ShowPlayerInfo()
  self.RetryTimes = 10
  self:PlayVideo1()
  _G.NRCAudioManager:SetStateByName("Login_Game", "Login", "UMG_Update_Video")
end

function UMG_Update_Video_C:PlayVideo1()
  self:UnregisterVideoEvents()
  self:CancelDelay()
  self:RegisterVideoEvents()
  self.UMG_NRCMedia:CloseMedia()
  local VideoSource = self.VideoList[self.videoIndex]
  if VideoSource then
    local paramTable = {
      source = VideoSource,
      needAutoPlay = true,
      isLoop = true,
      bEncryptVideo = true,
      useDefaultCoverTexture = false
    }
    self.UMG_NRCMedia:OpenMediaPanelByParamTable(paramTable)
    self:DelaySeconds(3, self.OnOpenMediaTimeout1, self)
  else
    Log.Error("\232\181\132\230\186\144\232\183\175\229\190\132\228\184\141\229\175\185\239\188\129\239\188\129\239\188\129")
  end
end

function UMG_Update_Video_C:SaveVideoList()
  local VideoData = {}
  local sex = 1
  local skin = 1
  table.insert(VideoData, sex)
  table.insert(VideoData, skin)
  for i = 1, 1 do
    table.insert(VideoData, i)
  end
  JsonUtils.DumpSaved("VideoData", VideoData)
end

function UMG_Update_Video_C:LoadVideoList()
  local VideoDataInfo = JsonUtils.LoadSaved("VideoData", {})
  local sexData, skinData
  if VideoDataInfo and VideoDataInfo[1] and VideoDataInfo[2] then
    sexData = VideoDataInfo[1]
    skinData = VideoDataInfo[2]
  else
    sexData = 1
    skinData = 1
  end
  local videoNum = 1
  local sex = "Male"
  if 1 == sexData then
    sex = "Male"
  elseif 2 == sexData then
    sex = "Female"
  end
  local skin = "White"
  if 1 == skinData then
    skin = "White"
  elseif 2 == skinData then
  end
  self.VideoList = {}
  if not sex or not skin then
    Log.Error("\231\142\169\229\174\182\230\151\160\230\149\176\230\141\174 \229\144\175\231\148\168\233\187\152\232\174\164VideoList")
    table.insert(self.VideoList, self.CloudLoopVideo)
  else
    self.videoRef = {}
    for i = 1, videoNum do
      local fileName = tostring(i)
      local path = "Movies/" .. sex .. "/" .. skin .. "/" .. fileName .. ".mp4"
      Log.DebugFormat("UMG_Update_Video_C: path %s pathWithDeviceLevel %s", path, pathWithDeviceLevel)
      table.insert(self.VideoList, path)
    end
  end
  self.MaxVideoIndex = #self.VideoList
  self.videoIndex = 1
end

function UMG_Update_Video_C:SwitchPlayMode()
  self.VideoListMode = true
  local level = UE4.UNRCQualityLibrary.GetDeviceLevel()
  local Low_end_Phone
  if level > 1 then
    Low_end_Phone = false
  else
    Low_end_Phone = true
  end
  if Low_end_Phone then
    self.PlayVideoMode = PlayVideoMode.BlackScreen
  else
    self.PlayVideoMode = PlayVideoMode.Fade
  end
end

function UMG_Update_Video_C:AddVideoIndex()
  self.videoIndex = self.videoIndex + 1
  if self.videoIndex > self.MaxVideoIndex then
    self.videoIndex = 1
  end
end

function UMG_Update_Video_C:OnAnimationFinished(anim)
  if anim == self.BlackScreenFade then
  elseif anim == self.Video2FadeIn then
    self.MediaTexture:SetForceClearFlag(true)
  elseif anim == self.Video2FadeOut then
    self.MediaTexture2:SetForceClearFlag(true)
  end
end

function UMG_Update_Video_C:OnMediaTimeChanged()
  Log.Error("OnMediaTimeChanged")
end

return UMG_Update_Video_C

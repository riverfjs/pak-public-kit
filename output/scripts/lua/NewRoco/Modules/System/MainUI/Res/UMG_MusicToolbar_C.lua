local UMG_MusicToolbar_C = _G.NRCPanelBase:Extend("UMG_MusicToolbar_C")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")

function UMG_MusicToolbar_C:OnActive(feedDetail, SoundSession)
  self.feedDetail = feedDetail
  self.feedInfo = self.feedDetail.feed_info
  self.SoundSession = SoundSession
  if -1 ~= self.SoundSession then
    self.NRCSwitcher_Play:SetActiveWidgetIndex(1)
    self.PlayingProgress:SetFillAmount(0)
    self.PlayingProgress:SetFillStartPercent(0.5)
    local musicConf = _G.DataConfigManager:GetMusicConf(self.feedInfo.music_id)
    if musicConf then
      self.MusicTitle:SetText(musicConf.music_name)
      self.musicTime = _G.NRCAudioManager:GetMaxTimeFromEventName(musicConf.mark_event_name)
      local playPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
      local playTime = math.floor(playPositionMs / 1000)
      self.playingTimer = _G.TimerManager:CreateTimer(self, "UMG_MusicToolbar_C:OnActive", self.musicTime - playTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
    end
  end
  self:UpdateLikeState()
  self:RefreshVisibility()
end

function UMG_MusicToolbar_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_MusicToolbar_C:OnAddEventListener()
  self:AddButtonListener(self.StartBtn.btnLevelUp, self.OnClickPlayBtn)
  self:AddButtonListener(self.StopBtn.btnLevelUp, self.OnClickStopBtn)
  self:AddButtonListener(self.MessageBtn.btnLevelUp, self.OnClickMessageBtn)
  self:AddButtonListener(self.LikeBtn.btnLevelUp, self.OnClickLikeBtn)
  self:AddButtonListener(self.CloseBtn.btnLevelUp, self.OnClickCloseBtn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ExitMusicMessage, self.ExitMusicMessage)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_MUSIC_PLAY_BREAK_OFF, self, self.CheckMusicPlayBreakOff)
end

function UMG_MusicToolbar_C:OnDeactive()
end

function UMG_MusicToolbar_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ExitMusicMessage, self.ExitMusicMessage)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_MUSIC_PLAY_BREAK_OFF, self, self.CheckMusicPlayBreakOff)
  if self.playingTimer then
    _G.TimerManager:RemoveTimer(self.playingTimer)
  end
end

function UMG_MusicToolbar_C:OnAnimationFinished(anim)
end

function UMG_MusicToolbar_C:OnTick()
  self:RefreshVisibility()
end

function UMG_MusicToolbar_C:RefreshVisibility()
  local bHasBottomTips = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.HasDisplayingTip, TipEnum.TipDisplayArea.Bottom)
  if self.module:IsPanelEnabled("MagicMessageMusicToolbar") and not bHasBottomTips then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MusicToolbar_C:OnClickPlayBtn()
  if -1 == self.SoundSession then
    self.NRCSwitcher_Play:SetActiveWidgetIndex(1)
    self.PlayingProgress:SetFillAmount(0)
    self.PlayingProgress:SetFillStartPercent(0.5)
    if self.playingTimer then
      _G.TimerManager:RemoveTimer(self.playingTimer)
    end
    local musicConf = _G.DataConfigManager:GetMusicConf(self.feedInfo.music_id)
    if musicConf then
      self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(musicConf.mark_event_name, "UMG_MusicToolbar_C")
      self.playingTimer = _G.TimerManager:CreateTimer(self, "UMG_MusicToolbar_C:OnClickPlayBtn", self.musicTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
      local messageNpc = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetNpcByGridAndFeedId, self.feedInfo.grid_id, self.feedInfo.feed_id, self.feedInfo.category)
      if messageNpc and messageNpc.viewObj and messageNpc.viewObj.SetTickStart then
        messageNpc.viewObj:SetTickStart(true)
      end
    end
  end
end

function UMG_MusicToolbar_C:OnTimerUpdate()
  if self.SoundSession and -1 ~= self.SoundSession then
    local playPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
    local playTime = math.floor(playPositionMs / 1000)
    local progress = playTime / self.musicTime
    self.PlayingProgress:SetFillAmount(progress)
  end
end

function UMG_MusicToolbar_C:OnTimerEnd()
  self:StopMusic()
end

function UMG_MusicToolbar_C:OnClickStopBtn()
  if -1 ~= self.SoundSession then
    self:StopMusic()
  end
end

function UMG_MusicToolbar_C:StopMusic(fadeOutTime)
  self.NRCSwitcher_Play:SetActiveWidgetIndex(0)
  _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, "UMG_MusicToolbar_C", false, fadeOutTime)
  self.SoundSession = -1
  if self.playingTimer then
    _G.TimerManager:RemoveTimer(self.playingTimer)
  end
end

function UMG_MusicToolbar_C:OnClickMessageBtn()
  self.feedDetail.feed_info = self.feedInfo
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenShowMagicMessage, self.feedDetail, nil, self.SoundSession)
  self:DoClose()
end

function UMG_MusicToolbar_C:UpdateLikeState()
  local iconPath
  if self.feedInfo and self.feedInfo.attitude == ProtoEnum.FeedAttitudeType.FEED_ATTITUDE_TYPE_LIKE then
    self.LikeBtn.btnLevelUp:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    iconPath = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_Upvote2_png.img_Upvote2_png"
  else
    self.LikeBtn.btnLevelUp:SetVisibility(UE4.ESlateVisibility.Visible)
    iconPath = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_Upvote_png.img_Upvote_png"
  end
  self.LikeBtn:SetPath(iconPath, iconPath, iconPath)
end

function UMG_MusicToolbar_C:OnClickLikeBtn()
  if self.bReqAttitude then
    return
  end
  self.bReqAttitude = true
  local reqMsg = _G.ProtoMessage:newZoneFeedMagicAttitudeReq()
  reqMsg.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  reqMsg.feed_id = self.feedInfo.feed_id
  reqMsg.attitude = ProtoEnum.FeedAttitudeType.FEED_ATTITUDE_TYPE_LIKE
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_MAGIC_ATTITUDE_REQ, reqMsg, self, self.OnFeedMagicAttitudeRsp, nil, false)
  self:DelaySeconds(2, function()
    self.bReqAttitude = false
  end)
end

function UMG_MusicToolbar_C:OnFeedMagicAttitudeRsp(rsp)
  self.bReqAttitude = false
  if 0 == rsp.ret_info.ret_code then
    self.feedInfo = rsp.feed
    self:UpdateLikeState()
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, self.feedInfo.grid_id, self.feedInfo.feed_id, self.feedInfo)
  end
end

function UMG_MusicToolbar_C:OnClickCloseBtn()
  self:ExitMusicMessage()
end

function UMG_MusicToolbar_C:CheckMusicPlayBreakOff(newState, functionType, Reason)
  if newState then
    Log.Info("UMG_MusicToolbar_C:CheckMusicPlayBreakOff True Reason", Reason)
    self:ExitMusicMessage()
  end
end

function UMG_MusicToolbar_C:ExitMusicMessage()
  local messageNpc = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetNpcByGridAndFeedId, self.feedInfo.grid_id, self.feedInfo.feed_id, self.feedInfo.category)
  if messageNpc and messageNpc.viewObj and messageNpc.viewObj.SetTickStart then
    messageNpc.viewObj:SetTickStart(false)
  end
  if -1 ~= self.SoundSession then
    self:StopMusic(0.4)
  end
  self:DoClose()
end

return UMG_MusicToolbar_C

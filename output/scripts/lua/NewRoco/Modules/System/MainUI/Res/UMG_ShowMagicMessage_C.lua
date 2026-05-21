local UMG_ShowMagicMessage_C = _G.NRCPanelBase:Extend("UMG_ShowMagicMessage_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local CommentNumPerPage = 100

function UMG_ShowMagicMessage_C:OnActive(param)
  self.feedDetail = param.feedDetail
  self.feedInfo = self.feedDetail.feed_info
  self.grid_id = self.feedInfo.grid_id or 0
  self.feed_id = self.feedInfo.feed_id or 0
  self.Action = param.Action
  self.SoundSession = param.SoundSession
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE or self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_UI, "ShowMagicMessage")
  end
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:SetJoystickEnabled(false)
  end
  self:PlayAnimation(self.In)
  self:InitUI()
end

function UMG_ShowMagicMessage_C:OnConstruct()
  self:OnAddEventListener()
  self.attitudeBtnList = {
    [self.Btn_Like] = 1,
    [self.Btn_Hug] = 2,
    [self.Btn_Inspire] = 3,
    [self.Btn_Incomprehension] = 4
  }
  self.attitudeSwitcherList = {
    [self.Switcher_Like] = 1,
    [self.Switcher_Hug] = 2,
    [self.Switcher_Inspire] = 3,
    [self.Switcher_Incomprehension] = 4
  }
  self.PlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
end

function UMG_ShowMagicMessage_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.Close_Message_Panel, self.OnMagicMessageExpiredEvent)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.ClickMagicMessageCommentMoreContentEvent, self.OnClickCommentMoreContentEvent)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.UpdateMagicMessageCommentInfoEvent, self.OnUpdateMagicMessageCommentInfoEvent)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.ForceExitPanel)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, self.ForceExitPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnEnterVisit, self.ForceExitPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnReportSuccessEvent, self.OnReportSuccess)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_MUSIC_PLAY_BREAK_OFF, self, self.CheckMusicPlayBreakOff)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_WATCH_BREAK_OFF, self, self.CheckVideoWatchBreakOff)
  self:AddButtonListener(self.Btn_Close.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.BtnMore.btnLevelUp, self.OnClickMoreBtn)
  self:AddButtonListener(self.TeleportNearbyBtn, self.OnClickTeleportNearbyBtn)
  self:AddButtonListener(self.ReportBtn, self.OnClickReportBtn)
  self:AddButtonListener(self.Enhance.btnLevelUp, self.OnClickEnhanceBtn)
  self:AddButtonListener(self.PlayMusic.btnLevelUp, self.OnClickPlayMusicBtn)
  self:AddButtonListener(self.StopMusic.btnLevelUp, self.OnClickStopMusicBtn)
  self:AddButtonListener(self.Btn_Delete.btnLevelUp, self.OnClickDeleteBtn)
  self:AddButtonListener(self.Btn_Comment.btnLevelUp, self.OnClickCommentBtn)
  self:AddButtonListener(self.Btn_Comment_Grey.btnLevelUp, self.OnClickCommentGreyBtn)
  self:AddButtonListener(self.Btn_Sort, self.OnClickSortBtn)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnClickShareBtn)
  self.Btn_Like.OnPressed:Add(self, self.OnBtnLikePressed)
  self.Btn_Like.OnReleased:Add(self, self.OnBtnLikeReleased)
  self.Btn_Like.OnClicked:Add(self, self.OnBtnLikeClicked)
  self.Btn_Hug.OnPressed:Add(self, self.OnBtnHugPressed)
  self.Btn_Hug.OnReleased:Add(self, self.OnBtnHugReleased)
  self.Btn_Hug.OnClicked:Add(self, self.OnBtnHugClicked)
  self.Btn_Inspire.OnPressed:Add(self, self.OnBtnInspirePressed)
  self.Btn_Inspire.OnReleased:Add(self, self.OnBtnInspireReleased)
  self.Btn_Inspire.OnClicked:Add(self, self.OnBtnInspireClicked)
  self.Btn_Incomprehension.OnPressed:Add(self, self.OnBtnIncomprehensionPressed)
  self.Btn_Incomprehension.OnReleased:Add(self, self.OnBtnIncomprehensionReleased)
  self.Btn_Incomprehension.OnClicked:Add(self, self.OnBtnIncomprehensionClicked)
  self.ScrollBox_Content.OnUserScrolled:Add(self, self.OnScrollBoxScrolled)
  self.NRCScrollView_CommentList.OnUserScrolled:Add(self, self.OnCommentListScrolled)
end

function UMG_ShowMagicMessage_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.Close_Message_Panel, self.OnMagicMessageExpiredEvent)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.ClickMagicMessageCommentMoreContentEvent, self.OnClickCommentMoreContentEvent)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.UpdateMagicMessageCommentInfoEvent, self.OnUpdateMagicMessageCommentInfoEvent)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.ForceExitPanel)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, self.ForceExitPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.ForceExitPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnReportSuccessEvent, self.OnReportSuccess)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_MUSIC_PLAY_BREAK_OFF, self, self.CheckMusicPlayBreakOff)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_WATCH_BREAK_OFF, self, self.CheckVideoWatchBreakOff)
  self:RemoveButtonListener(self.ShareBtn.btnLevelUp)
  self.Btn_Like.OnPressed:Remove(self, self.OnBtnLikePressed)
  self.Btn_Like.OnReleased:Remove(self, self.OnBtnLikeReleased)
  self.Btn_Hug.OnPressed:Remove(self, self.OnBtnHugPressed)
  self.Btn_Hug.OnReleased:Remove(self, self.OnBtnHugReleased)
  self.Btn_Inspire.OnPressed:Remove(self, self.OnBtnInspirePressed)
  self.Btn_Inspire.OnReleased:Remove(self, self.OnBtnInspireReleased)
  self.Btn_Incomprehension.OnPressed:Remove(self, self.OnBtnIncomprehensionPressed)
  self.Btn_Incomprehension.OnReleased:Remove(self, self.OnBtnIncomprehensionReleased)
  self.attitudeBtnList = {}
  self.attitudeSwitcherList = {}
  if self.Action then
    self.Action:Finish(true, nil)
  end
  self.Action = nil
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE or self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_UI, "ShowMagicMessage")
  end
  local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    MainUIModule:SetJoystickEnabled(true)
  end
  if -1 ~= self.SoundSession then
    self:DoStopMusic()
  end
  self.grid_id = nil
  self.feed_id = nil
  self.feedInfo = nil
end

function UMG_ShowMagicMessage_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:CloseUI()
  end
end

function UMG_ShowMagicMessage_C:OnMagicMessageExpiredEvent(grid_id, feed_id)
  if self.grid_id == grid_id and self.feed_id == feed_id then
    self:ForceExitPanel()
  end
end

function UMG_ShowMagicMessage_C:ForceExitPanel()
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
  end
  if 0 ~= self.feedInfo.music_id and -1 ~= self.SoundSession then
    self:DoStopMusic()
  end
  self:PlayAnimation(self.Out)
end

function UMG_ShowMagicMessage_C:DeleteCurFeed()
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
  end
  if 0 ~= self.feedInfo.music_id and -1 ~= self.SoundSession then
    self:DoStopMusic()
  end
  _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo.category)
  self:PlayAnimation(self.Out)
end

function UMG_ShowMagicMessage_C:CheckMusicPlayBreakOff(newState, functionType, Reason)
  if newState and self.feedInfo and 0 ~= self.feedInfo.music_id then
    Log.Info("UMG_ShowMagicMessage_C MusicPlayBreakOff, Reason music_id", Reason, self.feedInfo.music_id)
    if -1 ~= self.SoundSession then
      self:DoStopMusic()
    end
    self:PlayAnimation(self.Out)
  end
end

function UMG_ShowMagicMessage_C:CheckVideoWatchBreakOff(newState, functionType, Reason)
  if newState and self.feedInfo and self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    Log.Info("UMG_ShowMagicMessage_C VideoWatchBreakOff, Reason", Reason)
    self:PlayAnimation(self.Out)
  end
end

function UMG_ShowMagicMessage_C:CloseUI()
  self:DoClose()
  local friendModule = _G.NRCModuleManager:GetModule("FriendModule")
  if friendModule:HasPanel("Friend_Report") then
    local panel = friendModule:GetPanel("Friend_Report")
    if panel then
      panel:DoClose()
    end
  end
  local commonPopUpModule = _G.NRCModuleManager:GetModule("CommonPopUpModule")
  if commonPopUpModule:HasPanel("CommonPopUp_WithItem") then
    local panel = commonPopUpModule:GetPanel("CommonPopUp_WithItem")
    if panel then
      panel:DoClose()
    end
  end
  if commonPopUpModule:HasPanel("Common_Remind") then
    local panel = commonPopUpModule:GetPanel("Common_Remind")
    if panel then
      panel:DoClose()
    end
  end
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if mainUIModule:HasPanel("MagicMessageCommentPopUp") then
    local panel = mainUIModule:GetPanel("MagicMessageCommentPopUp")
    if panel then
      panel:DoClose()
    end
  end
end

function UMG_ShowMagicMessage_C:OnPcClose()
  self:OnClickCloseBtn()
end

function UMG_ShowMagicMessage_C:OnReportSuccess(reportScene)
  if reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_DYNAMIC_POSTS_SCENE then
    local reqMsg = _G.ProtoMessage:newZoneFeedPlayerUninterestedReq()
    reqMsg.uin = self.PlayerUin
    reqMsg.feed_id = self.feed_id
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_PLAYER_UNINTERESTED_REQ, reqMsg, self, self.OnFeedPlayerUnInterestedRsp, nil, false)
  end
end

function UMG_ShowMagicMessage_C:InitUI()
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE or self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    self.Text_Title:SetText(LuaText.magic_message_share_title)
  elseif self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    self.Text_Title:SetText(LuaText.mark_video_share_title)
  end
  if self.feedInfo.music_id and 0 ~= self.feedInfo.music_id then
    self.HorizontalBox_Music:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local musicConf = _G.DataConfigManager:GetMusicConf(self.feedInfo.music_id)
    if musicConf then
      local musicName = musicConf.music_name
      if string.len(musicConf.music_name) > 15 then
        musicName = string.sub(musicConf.music_name, 1, 15) .. "..."
      end
      self.Text_MusicName:SetText(musicName)
      if self.SoundSession then
        if -1 ~= self.SoundSession then
          self.BtnSwitcher:SetActiveWidgetIndex(1)
          self.Progress:SetFillAmount(0)
          self.Progress:SetFillStartPercent(0.5)
          self.musicTime = _G.NRCAudioManager:GetMaxTimeFromEventName(musicConf.mark_event_name)
          local playPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
          local playTime = math.floor(playPositionMs / 1000)
          self.playingTimer = _G.TimerManager:CreateTimer(self, "UMG_ShowMagicMessage_C:InitUI", self.musicTime - playTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
        else
          self:DoPlayMusic()
        end
      else
        local magicReplayModule = _G.NRCModuleManager:GetModule("MagicReplayModule")
        if magicReplayModule:HasPanel("ReplayPanel") then
          _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
        end
        local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
        if mainUIModule:HasPanel("MagicMessageMusicToolbar") then
          local musicToolbar = mainUIModule:GetPanel("MagicMessageMusicToolbar")
          if musicToolbar then
            if musicToolbar.feedInfo.feed_id ~= self.feed_id then
              musicToolbar:OnClickCloseBtn()
              self:DoPlayMusic()
            elseif -1 ~= musicToolbar.SoundSession then
              self.SoundSession = musicToolbar.SoundSession
              self.BtnSwitcher:SetActiveWidgetIndex(1)
              self.Progress:SetFillAmount(0)
              self.Progress:SetFillStartPercent(0.5)
              self.musicTime = _G.NRCAudioManager:GetMaxTimeFromEventName(musicConf.mark_event_name)
              local playPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
              local playTime = math.floor(playPositionMs / 1000)
              self.playingTimer = _G.TimerManager:CreateTimer(self, "UMG_ShowMagicMessage_C:InitUI", self.musicTime - playTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
              musicToolbar:DoClose()
            else
              musicToolbar:OnClickCloseBtn()
              self:DoPlayMusic()
            end
          end
        else
          self:DoPlayMusic()
        end
      end
    end
  else
    self.HorizontalBox_Music:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE or self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    self:SetFeedPlayerInfo()
  elseif self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    self:SetHeadIcon(self.feedInfo.card_icon_selected)
    self.Text_RoleName:SetText(self.feedInfo.name)
    self.OnlineStatus:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local currentSec = _G.ZoneServer:GetServerTime() / 1000
  local remainSec = self.feedInfo.expire_timestamp - currentSec
  self.Text_CountDown:SetText(ActivityUtils.GetTimeFormatStr(remainSec))
  local content = self.feedInfo.content
  if self.feedInfo.sub_type and 0 ~= self.feedInfo.sub_type then
    content = string.ConvertToRichText(content)
  end
  self.Text_Message:SetText(content)
  local curAttitudeType = self.feedInfo.attitude
  for switcher, attitude in pairs(self.attitudeSwitcherList) do
    switcher:SetActiveWidgetIndex(attitude == curAttitudeType and 1 or 0)
  end
  if self.feedInfo.attitude_like_num > 9999 then
    self.Text_LikeCnt:SetText("9999+")
  else
    self.Text_LikeCnt:SetText(self.feedInfo.attitude_like_num)
  end
  if self.feedInfo.attitude_hug_num > 9999 then
    self.Text_HugCnt:SetText("9999+")
  else
    self.Text_HugCnt:SetText(self.feedInfo.attitude_hug_num)
  end
  if self.feedInfo.attitude_inspiration_num > 9999 then
    self.Text_InspireCnt:SetText("9999+")
  else
    self.Text_InspireCnt:SetText(self.feedInfo.attitude_inspiration_num)
  end
  if self.feedInfo.comment_num > 9999 then
    self.Text_Comment:SetText(LuaText.mark_magic_message_comment_hot)
  else
    self.Text_Comment:SetText(string.format(LuaText.umg_mark_magic_message_comment, self.feedInfo.comment_num))
  end
  self.curReqPage = -1
  self.maxPageNum = math.ceil(self.feedInfo.comment_num / CommentNumPerPage) - 1
  self:SetComboBox()
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    self.Delete:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Delete:SetVisibility(UE4.ESlateVisibility.Visible)
    local curPlayerUni = self.PlayerUin
    if curPlayerUni == self.feedInfo.uin then
      if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
        self.Btn_Delete.Title_1:SetText(LuaText.umg_mark_magic_message_delete)
      elseif self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
        self.Btn_Delete.Title_1:SetText(LuaText.mark_video_delete_button)
      end
    else
      self.Btn_Delete:SetCommonText(LuaText.umg_mark_magic_message_unlike)
    end
  end
  self.Text_Transmitting:SetText(LuaText.visible_circle_teleport_btn_text)
  self.Text_Report:SetText(LuaText.magic_message_comment_report)
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    self.CanvasPanel_More:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local curPlayerUni = self.PlayerUin
    if curPlayerUni == self.feedInfo.uin then
      self.CanvasPanel_More:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.CanvasPanel_More:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.bClickMore = false
  end
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO and self.feedInfo.uin == self.PlayerUin then
    local platid = (not RocoEnv.PLATFORM_ANDROID or not 1) and (not RocoEnv.PLATFORM_IOS or not 0) and (not RocoEnv.PLATFORM_WINDOWS or not 2) and RocoEnv.PLATFORM_OPENHARMONY and 12
    if 2 ~= platid and 12 ~= platid then
      self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
  local checkBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_COMMENT_MESSAGE_MESSAGE, false)
  self.WidgetSwitcher_Comment:SetActiveWidgetIndex(checkBan and 1 or 0)
  self.lastOffset = 0
  self.topContentHeight = 0
  self:SetEnableCommentListScroll(false)
  self:DelayFrames(1, function()
    local canvasPanel_0 = self.VerticalBox_Content:GetChildAt(0)
    local canvasPanelHeight_0 = canvasPanel_0:GetDesiredSize().Y
    local canvasPanel_1 = self.VerticalBox_Content:GetChildAt(1)
    local canvasPanelHeight_1 = canvasPanel_1:GetDesiredSize().Y
    self.topContentHeight = canvasPanelHeight_0 + canvasPanelHeight_1
    Log.Info("[ScrollTest]\232\175\132\232\174\186\229\136\151\232\161\168\228\184\138\230\150\185\229\134\133\229\174\185\233\171\152\229\186\166", self.topContentHeight)
    self:SetCommentListSize(0)
  end)
end

function UMG_ShowMagicMessage_C:DoPlayMusic()
  local musicConf = _G.DataConfigManager:GetMusicConf(self.feedInfo.music_id)
  if musicConf then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.Progress:SetFillAmount(0)
    self.Progress:SetFillStartPercent(0.5)
    if self.playingTimer then
      _G.TimerManager:RemoveTimer(self.playingTimer)
    end
    self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(musicConf.mark_event_name, "UMG_ShowMagicMessage_C")
    self.musicTime = _G.NRCAudioManager:GetMaxTimeFromEventName(musicConf.mark_event_name)
    self.playingTimer = _G.TimerManager:CreateTimer(self, "UMG_ShowMagicMessage_C:DoPlayMusic", self.musicTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
    local messageNpc = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo.category)
    if messageNpc and messageNpc.viewObj and messageNpc.viewObj.SetTickStart then
      messageNpc.viewObj:SetTickStart(true)
    end
  end
end

function UMG_ShowMagicMessage_C:OnTimerUpdate()
  if self.SoundSession and -1 ~= self.SoundSession then
    local playPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
    local playTime = math.floor(playPositionMs / 1000)
    local progress = playTime / self.musicTime
    self.Progress:SetFillAmount(progress)
  end
end

function UMG_ShowMagicMessage_C:OnTimerEnd()
  self:DoStopMusic()
end

function UMG_ShowMagicMessage_C:DoStopMusic()
  self.BtnSwitcher:SetActiveWidgetIndex(0)
  _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, "UMG_ShowMagicMessage_C")
  self.SoundSession = -1
  if self.playingTimer then
    _G.TimerManager:RemoveTimer(self.playingTimer)
  end
  local messageNpc = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo.category)
  if messageNpc and messageNpc.viewObj and messageNpc.viewObj.SetTickStart then
    messageNpc.viewObj:SetTickStart(false)
  end
end

function UMG_ShowMagicMessage_C:SetCommentListSize(scrolledOffset)
  Log.Info("[ScrollTest]SetCommentListSize scrolledOffset", scrolledOffset)
  if scrolledOffset < 0 then
    scrolledOffset = 0
  end
  local size = self.NRCScrollView_CommentList.Slot:GetSize()
  local endScrollOffset = self.ScrollBox_Content:GetScrollOffsetOfEnd()
  local addY = math.ceil(self.topContentHeight - endScrollOffset)
  local commentContentHeight = math.min(self.feedInfo.comment_num, CommentNumPerPage) * 172
  Log.Info("[ScrollTest] \232\175\132\232\174\186\229\136\151\232\161\168\229\189\147\229\137\141\233\171\152\229\186\166\239\188\140\229\164\150\233\131\168scrollBox\229\143\175\230\187\145\229\138\168\232\183\157\231\166\187\239\188\140\233\156\128\232\166\129\232\161\165\229\183\174\231\154\132\233\171\152\229\186\166\239\188\140\229\136\151\232\161\168\229\134\133\229\174\185\229\174\158\233\153\133\233\171\152\229\186\166", size.Y, endScrollOffset, addY, commentContentHeight)
  size.Y = math.min(size.Y + addY, commentContentHeight)
  self.NRCScrollView_CommentList.Slot:SetSize(size)
  Log.Info("[ScrollTest] \232\175\132\232\174\186\229\136\151\232\161\168\230\156\128\231\187\136\233\171\152\229\186\166", size.Y)
  self.NRCScrollView_CommentList:GetSubCanvasPanel():SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:DelayFrames(1, function()
    self.NRCScrollView_CommentList:NRCSetScrollOffset(scrolledOffset)
  end)
end

function UMG_ShowMagicMessage_C:SetComboBox()
  local sortTypeList = {}
  local sortStr = _G.DataConfigManager:GetGlobalConfig("mark_magic_message_order").str
  local sortStrList = string.Split(sortStr, ";")
  if sortStrList then
    for i, v in pairs(sortStrList) do
      local sortType, sortName
      if "umg_mark_magic_message_hot_order" == v then
        sortType = 1
        sortName = LuaText.umg_mark_magic_message_hot_order
      end
      if "umg_mark_magic_message_time_order" == v then
        sortType = 2
        sortName = LuaText.umg_mark_magic_message_time_order
      end
      table.insert(sortTypeList, {
        ComType = CommonBtnEnum.ComboBoxType.ShowMagicMessage,
        Type = sortType,
        isNotChangColor = true,
        name = sortName,
        isHideRedDot = true,
        OnSelectDelegate = function(data)
          self:OnComboBoxSelect(data.Type)
        end
      })
    end
  end
  self.ComboBox_Popup:SetListTitle(sortTypeList)
  self.ComboBox_Popup:SelectListItem(0)
end

function UMG_ShowMagicMessage_C:OnComboBoxSelect(sortType)
  self.bComBoxExpand = false
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Image_Expand:SetRenderTransformAngle(self.bComBoxExpand == true and 180 or 0)
  self:PlayAnimation(self.bComBoxExpand == true and self.AccessAuthority_Down or self.AccessAuthority_Up)
  self.sortType = sortType
  if 1 == self.sortType then
    self.Text_SortName:SetText(LuaText.umg_mark_magic_message_hot_order)
  elseif 2 == self.sortType then
    self.Text_SortName:SetText(LuaText.umg_mark_magic_message_time_order)
  end
  if self.feedInfo.comment_num and self.feedInfo.comment_num > 0 then
    self.curReqPage = 0
    self.commentList = {}
    self:ReqGetFeedComment()
  end
end

function UMG_ShowMagicMessage_C:OnScrollBoxScrolled(offset)
  if self.topContentHeight <= 0 then
    return
  end
  if offset >= self.topContentHeight then
    if not self.bEnableCommentScroll then
      self:SetEnableCommentListScroll(true)
    end
  elseif self.bEnableCommentScroll then
    self:SetEnableCommentListScroll(false)
  end
end

function UMG_ShowMagicMessage_C:OnCommentListScrolled(offset)
  if not self.bEnableCommentScroll then
    local scrollBoxOffset = self.ScrollBox_Content:GetScrollOffset()
    local newOffsetScrollBox = scrollBoxOffset + offset
    self.ScrollBox_Content:SetScrollOffset(newOffsetScrollBox)
    self.NRCScrollView_CommentList:SetScrollOffset(0)
  end
  if offset < 5 and offset - self.lastOffset < 0 then
    if self.bEnableCommentScroll then
      self:SetEnableCommentListScroll(false)
    end
    self.ScrollBox_Content:SetScrollOffset(self.topContentHeight)
    self.NRCScrollView_CommentList:SetScrollOffset(0)
  end
  self.lastOffset = offset
  local endScrollOffset = self.NRCScrollView_CommentList:GetScrollOffsetOfEnd()
  if not self.bReqComment and self.curReqPage < self.maxPageNum and offset == endScrollOffset then
    self.bReqComment = true
    self.curReqPage = self.curReqPage + 1
    self:ReqGetFeedComment()
  end
end

function UMG_ShowMagicMessage_C:SetEnableCommentListScroll(bEnable)
  self.bEnableCommentScroll = bEnable
  if self.bEnableCommentScroll then
    Log.Info("[ScrollTest]SetEnableCommentListScroll \229\144\175\231\148\168\232\175\132\232\174\186\229\136\151\232\161\168ScrollView")
    self.NRCScrollView_CommentList:SetScrollOffset(0)
    self.NRCScrollView_CommentList:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ScrollBox_Content:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    Log.Info("[ScrollTest]SetEnableCommentListScroll \231\166\129\231\148\168\232\175\132\232\174\186\229\136\151\232\161\168ScrollView")
    self.NRCScrollView_CommentList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ScrollBox_Content:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_ShowMagicMessage_C:ReqGetFeedComment()
  local reqMsg = _G.ProtoMessage:newZoneFeedGetFeedCommentReq()
  reqMsg.uin = self.PlayerUin
  reqMsg.feed_id = self.feed_id
  reqMsg.type = self.sortType
  reqMsg.page_num = self.curReqPage
  Log.InfoFormat("[Comment]UMG_ShowMagicMessage_C:ReqGetFeedComment feed_id=%d, type=%d, page_num=%d", self.feed_id, self.sortType, self.curReqPage)
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_GET_FEED_COMMENT_REQ, reqMsg, self, self.OnGetFeedCommentRsp, nil, false)
end

function UMG_ShowMagicMessage_C:SetFeedPlayerInfo()
  local curPlayerUni = self.PlayerUin
  if curPlayerUni == self.feedInfo.uin then
    local card_brief_info = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
    if card_brief_info then
      local card_icon_selected = card_brief_info.card_icon_selected
      self:SetHeadIcon(card_icon_selected)
      local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
      self.Text_RoleName:SetText(playerName)
      self.OnlineStatus:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.feedInfo.card_icon_selected = card_icon_selected
      self.feedInfo.name = playerName
      _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo)
    end
  else
    local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
    req.uin = self.feedInfo.uin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnSearchPlayerRsp, false, true)
  end
end

function UMG_ShowMagicMessage_C:OnSearchPlayerRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    self.searchPlayerRsp = rsp
    local card_icon_selected = rsp.player_info.card_icon_selected
    self:SetHeadIcon(card_icon_selected)
    local playerName = rsp.player_info.name
    self.Text_RoleName:SetText(playerName)
    if rsp.player_info.online then
      self.OnlineStatus:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.Text_OnlineStatus:SetText(LuaText.friend_list_online_text)
    else
      self.OnlineStatus:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.feedInfo.card_icon_selected = card_icon_selected
    self.feedInfo.name = playerName
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo)
  end
end

function UMG_ShowMagicMessage_C:SetHeadIcon(card_icon_selected)
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  if card_icon_selected and 0 ~= card_icon_selected then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    local avatarPath = cardIconConf.icon_resource_path
    avatarPath = string.format("%s%s.%s'", path, avatarPath, avatarPath)
    self.Image_Head:SetPath(avatarPath)
  end
end

function UMG_ShowMagicMessage_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickCloseBtn")
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    local MagicAlive = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetMagicAlive)
    if MagicAlive then
      self.feedDetail.feed_info = self.feedInfo
      _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.OpenReplayPanel, self.feedDetail)
    end
  end
  if 0 ~= self.feedInfo.music_id then
    local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
    if -1 ~= self.SoundSession then
      self.feedDetail.feed_info = self.feedInfo
      mainUIModule:OpenPanel("MagicMessageMusicToolbar", self.feedDetail, self.SoundSession)
      self.SoundSession = -1
      if self.playingTimer then
        _G.TimerManager:RemoveTimer(self.playingTimer)
      end
    end
  end
  self:PlayAnimation(self.Out)
end

function UMG_ShowMagicMessage_C:OnClickHeadBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickHeadBtn")
  if self.feedInfo == nil then
    return
  end
  local curPlayerUni = self.PlayerUin
  if curPlayerUni == self.feedInfo.uin then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, nil, FriendEnum.AdminFriendType.Own, FriendEnum.Source.Friend, nil)
  elseif self.searchPlayerRsp then
    local source = self.searchPlayerRsp.is_friend and FriendEnum.Source.Friend or FriendEnum.Source.Scene
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, self.searchPlayerRsp.player_info, FriendEnum.AdminFriendType.Others, source, nil)
  end
end

function UMG_ShowMagicMessage_C:OnClickMoreBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickMoreBtn")
  self.bClickMore = not self.bClickMore
  if self.bClickMore then
    self.CanvasPanel_298:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.More_In)
  else
    self.CanvasPanel_298:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.More_Out)
  end
end

function UMG_ShowMagicMessage_C:OnClickTeleportNearbyBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickTeleportNearbyBtn")
  self.CanvasPanel_298:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.More_Out)
  self.bClickMore = false
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OnCmdTeleportToPlayerReq, self.feedInfo.uin)
end

function UMG_ShowMagicMessage_C:OnClickReportBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickReportBtn")
  self.CanvasPanel_298:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.More_Out)
  self.bClickMore = false
  if self.feedInfo == nil then
    return
  end
  local reportData = {}
  reportData.uin = self.feedInfo.uin
  reportData.business_data = {}
  reportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_DYNAMIC_POSTS_SCENE
  reportData.business_data.report_content = self.feedInfo.content
  if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
    reportData.business_data.callback = "{\"postid\":" .. "\"" .. self.feedInfo.feed_id .. "\"" .. "}"
    reportData.business_data.report_entrance = 1
  elseif self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    reportData.business_data.callback = "{\"liuying_id\":" .. "\"" .. self.feedInfo.feed_id .. "\"" .. "}"
    reportData.business_data.report_entrance = 2
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenFriendReport, reportData)
end

function UMG_ShowMagicMessage_C:OnClickEnhanceBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickEnhanceBtn")
  if self.feedInfo == nil then
    return
  end
  local feedInfo = self.feedInfo
  local numList = _G.DataConfigManager:GetGlobalConfig("magic_message_steady").numList
  if 2 == #numList then
    local itemID = numList[1]
    local needNum = numList[2]
    local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, itemID)
    local bagNum = itemData and itemData.num or 0
    
    local function OnPopUpOk()
      if bagNum < needNum then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_18322)
        return
      end
      local reqMsg = _G.ProtoMessage:newZoneFeedHandWritingEnhanceReq()
      reqMsg.uin = self.PlayerUin
      reqMsg.feed_id = feedInfo.feed_id
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_HAND_WRITING_ENHANCE_REQ, reqMsg, self, self.OnHandWritingEnhanceRsp, nil, false)
    end
    
    local popUpData = _G.NRCCommonPopUpData()
    popUpData.Desc = LuaText.mark_message_ask_for_add_life
    popUpData.Call = self
    popUpData.Btn_RightHandler = OnPopUpOk
    popUpData.ItemList = {
      [1] = {
        itemType = _G.Enum.GoodsType.GT_BAGITEM,
        itemId = itemID,
        itemNum = bagNum,
        BagNum = bagNum,
        ConsumeNum = needNum,
        bShowNum = true
      }
    }
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenCommonPopUpWithItem, popUpData)
  end
end

function UMG_ShowMagicMessage_C:OnClickPlayMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickPlayMusicBtn")
  if -1 == self.SoundSession then
    self:DoPlayMusic()
  end
end

function UMG_ShowMagicMessage_C:OnClickStopMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickStopMusicBtn")
  if -1 ~= self.SoundSession then
    self:DoStopMusic()
  end
end

function UMG_ShowMagicMessage_C:OnClickDeleteBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickDeleteBtn")
  if self.feedInfo == nil then
    return
  end
  local feedInfo = self.feedInfo
  local curPlayerUni = self.PlayerUin
  if curPlayerUni == self.feedInfo.uin then
    local function ConfirmDelete()
      local reqMsg = _G.ProtoMessage:newZoneFeedMagicDeleteReq()
      
      reqMsg.uin = self.PlayerUin
      reqMsg.feed_id = feedInfo.feed_id
      reqMsg.category = feedInfo.category
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_MAGIC_DELETE_REQ, reqMsg, self, self.OnFeedMagicDeleteRsp, nil, false)
    end
    
    local titleText = ""
    local contentText = ""
    if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
      titleText = LuaText.umg_mark_magic_message_delete
      contentText = LuaText.mark_magic_message_delete_warning
    elseif self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
      titleText = LuaText.mark_video_delete_button
      contentText = LuaText.mark_video_delete_tips
    end
    local popUpData = _G.NRCCommonPopUpData()
    popUpData.Call = self
    popUpData.Btn_LeftText = LuaText.CANCEL
    popUpData.Btn_RightText = LuaText.umg_bag_11
    popUpData.TitleText = titleText
    popUpData.RemindSwitch = 0
    popUpData.ContentText = contentText
    popUpData.Btn_RightHandler = ConfirmDelete
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
  else
    if self.bReqUnInterested then
      return
    end
    self.bReqUnInterested = true
    local reqMsg = _G.ProtoMessage:newZoneFeedPlayerUninterestedReq()
    reqMsg.uin = self.PlayerUin
    reqMsg.feed_id = self.feed_id
    reqMsg.category = self.feedInfo.category
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_PLAYER_UNINTERESTED_REQ, reqMsg, self, self.OnFeedPlayerUnInterestedRsp, nil, false)
    self:DelaySeconds(2, function()
      self.bReqUnInterested = false
    end)
  end
end

function UMG_ShowMagicMessage_C:OnClickCommentBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickCommentBtn")
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenMagicMessageCommentPopUp, self.feedInfo)
end

function UMG_ShowMagicMessage_C:OnClickCommentGreyBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickCommentBtn")
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_COMMENT_MESSAGE_MESSAGE, true)
end

function UMG_ShowMagicMessage_C:OnChangeAttitude(attitude)
  if self.feedInfo == nil then
    return
  end
  if attitude == self.feedInfo.attitude then
    return
  end
  for btn, attitude in pairs(self.attitudeBtnList) do
    btn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  local reqMsg = _G.ProtoMessage:newZoneFeedMagicAttitudeReq()
  reqMsg.uin = self.PlayerUin
  reqMsg.feed_id = self.feed_id
  reqMsg.attitude = attitude
  reqMsg.category = self.feedInfo.category
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_MAGIC_ATTITUDE_REQ, reqMsg, self, self.OnFeedMagicAttitudeRsp, nil, false)
end

function UMG_ShowMagicMessage_C:OnClickSortBtn()
  self.bComBoxExpand = not self.bComBoxExpand
  self.ComboBox_Popup:SetVisibility(self.bComBoxExpand and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Image_Expand:SetRenderTransformAngle(self.bComBoxExpand == true and 180 or 0)
  self:PlayAnimation(self.bComBoxExpand == true and self.AccessAuthority_Down or self.AccessAuthority_Up)
end

function UMG_ShowMagicMessage_C:OnBtnLikePressed()
  self:PlayAnimation(self.Like_Press)
end

function UMG_ShowMagicMessage_C:OnBtnLikeReleased()
  self:PlayAnimation(self.Like_Up)
end

function UMG_ShowMagicMessage_C:OnBtnLikeClicked()
  self:OnChangeAttitude(ProtoEnum.FeedAttitudeType.FEED_ATTITUDE_TYPE_LIKE)
end

function UMG_ShowMagicMessage_C:OnBtnHugPressed()
  self:PlayAnimation(self.Hug_Press)
end

function UMG_ShowMagicMessage_C:OnBtnHugReleased()
  self:PlayAnimation(self.Hug_Up)
end

function UMG_ShowMagicMessage_C:OnBtnHugClicked()
  self:OnChangeAttitude(ProtoEnum.FeedAttitudeType.FEED_ATTITUDE_TYPE_HUG)
end

function UMG_ShowMagicMessage_C:OnBtnInspirePressed()
  self:PlayAnimation(self.Inspiring_Press)
end

function UMG_ShowMagicMessage_C:OnBtnInspireReleased()
  self:PlayAnimation(self.Inspiring_Up)
end

function UMG_ShowMagicMessage_C:OnBtnInspireClicked()
  self:OnChangeAttitude(ProtoEnum.FeedAttitudeType.FEED_ATTITUDE_TYPE_INSPIRATION)
end

function UMG_ShowMagicMessage_C:OnBtnIncomprehensionPressed()
  self:PlayAnimation(self.Incomprehension_Press)
end

function UMG_ShowMagicMessage_C:OnBtnIncomprehensionReleased()
  self:PlayAnimation(self.Incomprehension_Up)
end

function UMG_ShowMagicMessage_C:OnBtnIncomprehensionClicked()
  self:OnChangeAttitude(ProtoEnum.FeedAttitudeType.FEED_ATTITUDE_TYPE_PERPLEXITY)
end

function UMG_ShowMagicMessage_C:OnGetFeedCommentRsp(rsp)
  self.bReqComment = false
  if 0 == rsp.ret_info.ret_code then
    local comment_num = rsp.comment_info.comment_list and #rsp.comment_info.comment_list or 0
    Log.InfoFormat("[Comment]UMG_ShowMagicMessage_C:OnGetFeedCommentRsp feed_id=%d, page_num=%d, comment_num=%d", rsp.comment_info.feed_id, rsp.comment_info.page_num, comment_num)
    if rsp.comment_info.page_num == self.curReqPage then
      if 1 == self:GetCommentEncryptFlag() and rsp.comment_info.comment_list then
        for i = 1, #rsp.comment_info.comment_list do
          local originStr = rsp.comment_info.comment_list[i].comment
          rsp.comment_info.comment_list[i].comment = string.CipherTextEncode(originStr)
        end
      end
      if self.commentList == nil then
        self.commentList = {}
      end
      if rsp.comment_info.comment_list then
        self.commentList[self.curReqPage + 1] = rsp.comment_info.comment_list
      end
      local tempList = {}
      for i = 1, #self.commentList do
        local pageCommentList = self.commentList[i]
        for j = 1, #pageCommentList do
          table.insert(tempList, pageCommentList[j])
        end
      end
      local offset = self.NRCScrollView_CommentList:GetScrollOffset()
      self.NRCScrollView_CommentList:InitList(tempList)
      self:SetCommentListSize(offset)
    else
      Log.Error("[Comment]UMG_ShowMagicMessage_C:OnGetFeedCommentRsp page_num\228\184\141\228\184\128\232\135\180 feed_id, CPage, SPage", self.feed_id, self.curReqPage, rsp.comment_info.page_num)
    end
  end
end

function UMG_ShowMagicMessage_C:OnHandWritingEnhanceRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.mark_magic_message_steady_succeed)
    self.feedInfo = rsp.feed
    local currentSec = _G.ZoneServer:GetServerTime() / 1000
    local remainSec = self.feedInfo.expire_timestamp - currentSec
    self.Text_CountDown:SetText(ActivityUtils.GetTimeFormatStr(remainSec))
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo)
  end
end

function UMG_ShowMagicMessage_C:OnFeedMagicAttitudeRsp(rsp)
  if rsp.ret_info.ret_code == 18306 then
    self:DeleteCurFeed()
    return
  end
  for btn, attitude in pairs(self.attitudeBtnList) do
    btn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if 0 == rsp.ret_info.ret_code then
    self.feedInfo = rsp.feed
    for switcher, attitude in pairs(self.attitudeSwitcherList) do
      local curAttitudeType = self.feedInfo.attitude
      switcher:SetActiveWidgetIndex(attitude == curAttitudeType and 1 or 0)
    end
    if self.feedInfo.attitude_like_num > 9999 then
      self.Text_LikeCnt:SetText("9999+")
    else
      self.Text_LikeCnt:SetText(self.feedInfo.attitude_like_num)
    end
    if self.feedInfo.attitude_hug_num > 9999 then
      self.Text_HugCnt:SetText("9999+")
    else
      self.Text_HugCnt:SetText(self.feedInfo.attitude_hug_num)
    end
    if self.feedInfo.attitude_inspiration_num > 9999 then
      self.Text_InspireCnt:SetText("9999+")
    else
      self.Text_InspireCnt:SetText(self.feedInfo.attitude_inspiration_num)
    end
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo)
  end
end

function UMG_ShowMagicMessage_C:OnFeedMagicDeleteRsp(rsp)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:DeleteCurFeed()
end

function UMG_ShowMagicMessage_C:OnFeedPlayerUnInterestedRsp(rsp)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:DeleteCurFeed()
end

function UMG_ShowMagicMessage_C:OnFeedBackSuccess(rsp)
  if rsp.feed.feed_id ~= self.feedInfo.feed_id then
    return
  end
  self.feedInfo = rsp.feed
  self.Text_Comment:SetText(string.format(LuaText.umg_mark_magic_message_comment, self.feedInfo.comment_num))
  self.maxPageNum = math.ceil(self.feedInfo.comment_num / CommentNumPerPage) - 1
  if 1 == self:GetCommentEncryptFlag() then
    local originStr = rsp.comment_info.comment
    rsp.comment_info.comment = string.CipherTextEncode(originStr)
  end
  if self.commentList == nil then
    self.commentList = {}
  end
  local pageCommentList = self.commentList[1] or {}
  table.insert(pageCommentList, 1, rsp.comment_info)
  self.commentList[1] = pageCommentList
  local tempList = {}
  for i = 1, #self.commentList do
    local pageCommentList = self.commentList[i]
    for j = 1, #pageCommentList do
      table.insert(tempList, pageCommentList[j])
    end
  end
  local offset = self.NRCScrollView_CommentList:GetScrollOffset()
  self.NRCScrollView_CommentList:InitList(tempList)
  self:SetCommentListSize(offset)
end

function UMG_ShowMagicMessage_C:OnMagicCommentDeleteRsp(rsp)
  if rsp.ret_info.ret_code == 18306 then
    self:DeleteCurFeed()
    return
  end
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.magic_message_comment_delete_success)
    self.feedInfo = rsp.feed
    self.Text_Comment:SetText(string.format(LuaText.umg_mark_magic_message_comment, self.feedInfo.comment_num))
    local deletePage
    for i = 1, #self.commentList do
      local pageCommentList = self.commentList[i]
      for j = 1, #pageCommentList do
        local comment = pageCommentList[j]
        if comment.feedback_id == rsp.feedback_id then
          deletePage = i - 1
          break
        end
      end
    end
    if deletePage then
      for i = deletePage, self.maxPageNum do
        if self.commentList[i + 1] then
          self.commentList[i + 1] = nil
        end
      end
      self.maxPageNum = math.ceil(self.feedInfo.comment_num / CommentNumPerPage) - 1
      if -1 == self.maxPageNum then
        self.NRCScrollView_CommentList:InitList({})
        self:SetCommentListSize(0)
      else
        self.curReqPage = deletePage
        self:ReqGetFeedComment()
      end
    end
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, self.grid_id, self.feed_id, self.feedInfo)
  end
end

function UMG_ShowMagicMessage_C:OnClickCommentMoreContentEvent(commentInfo)
  if self.feedInfo == nil then
    return
  end
  if nil == commentInfo then
    return
  end
  local feedInfo = self.feedInfo
  local curPlayerUni = self.PlayerUin
  if curPlayerUni == commentInfo.uin then
    local function ConfirmDeleteComment()
      local req = _G.ProtoMessage:newZoneFeedMagicCommentDeleteReq()
      
      req.uin = feedInfo.uin
      req.feed_id = feedInfo.feed_id
      req.feedback_id = commentInfo.feedback_id
      req.category = feedInfo.category
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FEED_MAGIC_COMMENT_DELETE_REQ, req, self, self.OnMagicCommentDeleteRsp, false, false)
    end
    
    local popUpData = _G.NRCCommonPopUpData()
    popUpData.Call = self
    popUpData.Btn_LeftText = LuaText.CANCEL
    popUpData.Btn_RightText = LuaText.umg_bag_11
    popUpData.TitleText = LuaText.TIPS
    popUpData.ContentText = LuaText.magic_message_comment_delete_warning
    popUpData.Btn_RightHandler = ConfirmDeleteComment
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
  else
    local reportData = {}
    reportData.uin = commentInfo.uin
    reportData.business_data = {}
    reportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_COMMENT_AND_MESSAGE_SCENE
    reportData.business_data.report_content = commentInfo.comment
    if feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
      reportData.business_data.callback = "{\"postid\":" .. "\"" .. self.feedInfo.feed_id .. "\"," .. "\"commentid\":" .. "\"" .. commentInfo.feedback_id .. "\"" .. "}"
      reportData.business_data.report_entrance = 1
    elseif feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
      reportData.business_data.callback = "{\"liuying_comment_id\":" .. "\"" .. commentInfo.feedback_id .. "\"," .. "\"liuying_id\":" .. "\"" .. self.feedInfo.feed_id .. "\"" .. "}"
      reportData.business_data.report_entrance = 2
    end
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenFriendReport, reportData)
  end
end

function UMG_ShowMagicMessage_C:OnUpdateMagicMessageCommentInfoEvent(commentInfo)
  for i = 1, #self.commentList do
    local pageCommentList = self.commentList[i]
    for j = 1, #pageCommentList do
      local comment = pageCommentList[j]
      if comment.feedback_id == commentInfo.feedback_id then
        pageCommentList[j] = commentInfo
        break
      end
    end
  end
end

function UMG_ShowMagicMessage_C:GetCommentEncryptFlag()
  if self.encryptCommentFlag == nil then
    self.encryptCommentFlag = 0
    if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
      local fakeMessageId = self.feedInfo.feed_id & 16777215
      local fakeMessageConf = _G.DataConfigManager:GetMarkFakeMagicMessageConf(fakeMessageId, true)
      if fakeMessageConf then
        local decrypCondition = fakeMessageConf.fake_feed_decrypt_condition
        if decrypCondition == Enum.FakeFeedDecryptCondition.FAKE_FEED_DUNGEON_FINISH then
          local bFinish = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.GetDungeonStageDone, fakeMessageConf.decrypt_condition_param)
          if not bFinish then
            self.encryptCommentFlag = 1
          end
        end
      end
    end
  end
  return self.encryptCommentFlag
end

function UMG_ShowMagicMessage_C:OnClickShareBtn()
  local replaySeqInfo = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetReplaySeqInfo)
  if replaySeqInfo and replaySeqInfo.time and replaySeqInfo.time > 1 then
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.OnEnterShareVideoState)
  else
    local str = _G.DataConfigManager:GetLocalizationConf("mark_video_lesstime_tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
  end
end

function UMG_ShowMagicMessage_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  Log.Debug("UMG_ShowMagicMessage_C:OnTouchEnded")
  if self.bComBoxExpand then
    self:OnClickSortBtn()
  end
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.ClickMagicMessageCommentMoreEvent, 0)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_ShowMagicMessage_C

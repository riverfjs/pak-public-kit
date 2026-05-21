local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local TakePhotosUtils = require("NewRoco.Modules.System.TakePhotos.TakePhotosUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_TakePhotoCompetition_Vote_C = _G.NRCPanelBase:Extend("UMG_Activity_TakePhotoCompetition_Vote_C")

function UMG_Activity_TakePhotoCompetition_Vote_C:OnConstruct()
  self:SetChildViews(self.PhotoFile, self.PhotoFile_1)
  self.VoteBtn:SetBtnText(LuaText.pic_game_judge_button_left)
  self.VoteBtn_1:SetBtnText(LuaText.pic_game_judge_button_right)
  self.shuliang_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnActive(activityInst)
  _G.NRCAudioManager:PlaySound2DAuto(40006004, "UMG_Activity_TakePhotoCompetition_Vote_C:OnActive")
  self:OnAddEventListener()
  self.activityInst = activityInst
  self.activityInst:GetPhotoEvaluationInfo(false)
  self.photoData = nil
  self.likeData = nil
  self.voteIndex = 1
  self.winnerIndex = 1
  self.progressBarA = {}
  self.progressBarB = {}
  self.recommendCount = 0
  self.timerId = nil
  self:Init()
  self.percentRolling = false
  self.accuracyRolling = false
  self.accuracyFrom = 0
  self.accuracyTo = 0
  self.accuracyElapsed = 0
  self.accuracyRollDuration = 1
  self.currentSwitcherIndex = 0
  self.progressBarTargetTime = 0.1
  self.progressBarSpeedA = 0
  self.progressBarSpeedB = 0
  self.progressBarRolling = false
  self.progressBarNext = false
  self.noVoteCloseTimerId = nil
  self:RefreshCloseTimer()
  self.Btn_Report_A:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_Report_B:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnDeactive()
  self:OnRemoveEventListener()
  if self.timerId then
    _G.DelayManager:CancelDelayById(self.timerId)
  end
  if self.noVoteCloseTimerId then
    _G.DelayManager:CancelDelayById(self.noVoteCloseTimerId)
  end
  self:CancelDelay()
end

function UMG_Activity_TakePhotoCompetition_Vote_C:RefreshCloseTimer()
  if self.noVoteCloseTimerId then
    _G.DelayManager:CancelDelayById(self.noVoteCloseTimerId)
  end
  self.noVoteCloseTimerId = _G.DelayManager:DelaySeconds(_G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_vote_overtime").num or 600, function()
    if 0 == self.currentSwitcherIndex then
      self:PlayAnimation(self.Vote_Out)
    else
      self:PlayAnimation(self.RunOut_Out)
    end
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pic_game_judge_timeout)
    self.noVoteCloseTimerId = nil
  end)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_EVALUATION_NOTIFY, self.OnActivityPhotoContestEvaluationNty)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_LIKE_NOTIFY, self.OnActivityPhotoContestLikeNty)
  self:AddButtonListener(self.BackBtn.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.VoteBtn.btnLevelUp, self.OnVoteBtnClick)
  self:AddButtonListener(self.VoteBtn_1.btnLevelUp, self.OnVoteBtn1Click)
  self:AddButtonListener(self.RefreshBtn, self.OnRefreshBtnClick)
  self:AddButtonListener(self.BtnClickA, self.OnBtnClickAClick)
  self:AddButtonListener(self.BtnClickB, self.OnBtnClickBClick)
  self:AddButtonListener(self.Btnjiangbei, self.OnRewardBtnClick)
  self:AddButtonListener(self.Btn_Report_A.btnLevelUp, self.OnClickReportBtnA)
  self:AddButtonListener(self.Btn_Report_B.btnLevelUp, self.OnClickReportBtnB)
  self:AddButtonListener(self.Btn_details.btnLevelUp, self.OnDescBtnClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_TakePhotoCompetition_Vote_C", self, ActivityModuleEvent.TakePhotoCompetitionActivityVoteErrorEvent, self.TakePhotoCompetitionActivityVoteErrorEvent)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnRemoveEventListener()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_EVALUATION_NOTIFY, self.OnActivityPhotoContestEvaluationNty)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_LIKE_NOTIFY, self.OnActivityPhotoContestLikeNty)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.TakePhotoCompetitionActivityVoteErrorEvent, self.TakePhotoCompetitionActivityVoteErrorEvent)
  self:RemoveAllButtonListener()
end

function UMG_Activity_TakePhotoCompetition_Vote_C:Init()
  local titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if titleConf then
    self.Title1:SetBaseInfo(titleConf.head_icon, titleConf.subtitle[1].subtitle, titleConf.title)
  end
  local conf = self.activityInst:GetCurrentPhaseConf()
  if conf then
    local num = conf.id % 10
    if UEPath.ActivityPeriodImagePath[num] then
      self.Numbers:SetPath(UEPath.ActivityPeriodImagePath[num])
    end
    self.Text_Title:SetText(conf.name)
    self.Text_Describe:SetText(LuaText.pic_game_judge_tips)
    if num >= 1 and num <= 7 then
      self.CardSwitcher:SetActiveWidgetIndex(num - 1)
    end
  end
  local activityData = self.activityInst:GetActivityData()
  self.shuliang_1:SetText(LuaText.pic_game_accuracy)
  if activityData then
    self.Accuracy:SetText(activityData.accuracy_score or "0")
    self.Dot:SetupKey(215, {
      self.activityInst:GetActivityId(),
      activityData.current_phase_id
    })
    local recommendCount = activityData.recommend_count or 0
    self.Text_Push:SetText(string.format(LuaText.pic_game_judge_push_times, recommendCount))
    self.recommendCount = recommendCount
    if recommendCount > 0 then
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
      self:PlayAnimation(self.Vote_In)
      self.PhotoFile:ToggleLoadingProgressMask(true)
      self.PhotoFile_1:ToggleLoadingProgressMask(true)
      self.currentSwitcherIndex = 0
    else
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      self:OnRefreshRecommendFinishPanel()
      self:PlayAnimation(self.RunOut_In_Menu)
      self.currentSwitcherIndex = 1
    end
  end
  self.CanvasPanel_165:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnCloseBtnClick()
  if 0 == self.currentSwitcherIndex then
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local title = LuaText.pic_game_judge_giveup_title
    local Content = LuaText.pic_game_judge_giveup_text
    Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetClickAnywhereClose(true):SetButtonText(LuaText.YES, LuaText.NO):SetCallbackOkOnly(self, function(caller, isOK)
      self:PlayAnimation(self.Vote_Out)
    end)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  elseif not self:IsAnimationPlaying(self.RunOut_Out) then
    self:PlayAnimation(self.RunOut_Out)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnPcClose()
  self:OnCloseBtnClick()
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnDescBtnClick()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local conf = self.activityInst:GetCurrentPhaseConf()
  local Content = conf and conf.desc or ""
  local title = conf and conf.name or ""
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetClickAnywhereClose(true):SetCloseOnOK(true)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:TakePhotoCompetitionActivityVoteErrorEvent(errCode)
  local activityData = self.activityInst:GetActivityData()
  if activityData then
    self.Accuracy:SetText(activityData.accuracy_score or "0")
    local recommendCount = activityData.recommend_count or 0
    if recommendCount > 0 then
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
      self.PhotoFile:ToggleLoadingProgressMask(true)
      self.PhotoFile_1:ToggleLoadingProgressMask(true)
      self.HeadPortrait_A:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.HeadPortrait_B:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Text_Name_A:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Text_Name_B:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.currentSwitcherIndex = 0
    else
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      self:OnRefreshRecommendFinishPanel()
      self.currentSwitcherIndex = 1
    end
  end
  self.CanvasPanel_165:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnActivityPhotoContestEvaluationNty(rsp)
  if rsp then
    self.photoData = rsp
    if self.recommendCount > 0 then
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
      self:OnRefreshRecommendPanel()
      self.currentSwitcherIndex = 0
    else
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      self:OnRefreshRecommendFinishPanel()
      self.currentSwitcherIndex = 1
    end
    self.Text_Push:SetText(string.format(LuaText.pic_game_judge_push_times, self.photoData.recommend_count))
    self.recommendCount = rsp.recommend_count
    self.activityInst:OnUpdateActivityDataRecommendCount(rsp.recommend_count)
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local photoList = self.photoData.photos
    if photoList[1] and photoList[1].uin ~= playerUin then
      self.Btn_Report_A:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if photoList[2] and photoList[2].uin ~= playerUin then
      self.Btn_Report_B:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnRefreshRecommendFinishPanel()
  local currentPhaseConf = self.activityInst:GetCurrentPhaseConf()
  if not currentPhaseConf then
    return
  end
  local tips = LuaText.pic_game_judge_no_times_totally
  local currentTime = ActivityUtils.GetSvrTimestamp()
  local compEndTime = ActivityUtils.ToTimestamp(currentPhaseConf.competition_end_time)
  if compEndTime - currentTime > 86400 then
    tips = LuaText.pic_game_judge_no_times
  end
  local pushNum = _G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_push_num").num
  self.shuliang_3:SetText(string.format(tips, "0", tostring(pushNum)))
  self.BackBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnRefreshRecommendPanel()
  if not self.photoData then
    return
  end
  local skipNum = _G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_skip_num").num
  local num = skipNum - (self.photoData.skip_count or 0)
  if num < 0 then
    num = 0
  end
  if 0 == num then
    self.RefreshBtn:SetIsEnabled(false)
  else
    self.RefreshBtn:SetIsEnabled(true)
  end
  self.shuliang:SetText(string.format("%s%d/%d", LuaText.pic_game_judge_skip_button, num, skipNum))
  self.PhotoFile:DisplayFixedFramePhotoMiniMode(self.photoData.photos[1].mini_photo_url, self.photoData.photos[1].mini_photo_md5)
  self.PhotoFile_1:DisplayFixedFramePhotoMiniMode(self.photoData.photos[2].mini_photo_url, self.photoData.photos[2].mini_photo_md5)
  self:OnPhotoInfoUpdate(self.HeadPortrait_A, self.Text_Name_A, self.photoData.photos[1].uin, self, self.OnLeftPhotoInfoUpdateRsp)
  self:OnPhotoInfoUpdate(self.HeadPortrait_B, self.Text_Name_B, self.photoData.photos[2].uin, self, self.OnRightPhotoInfoUpdateRsp)
  self.CanvasPanel_165:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NumberLikesA:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AccuracyBonus_A:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NumberLikesB:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AccuracyBonus_B:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PhotoMaskA:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PhotoMaskB:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.VoteBtn:SetRenderOpacity(1)
  self.VoteBtn_1:SetRenderOpacity(1)
  if self.HorizontalBox_2 then
    self.HorizontalBox_2:SetRenderOpacity(1)
  end
  self.BackBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CloseBtn:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnPhotoInfoUpdate(headNode, nameNode, uin, caller, callback)
  local friendData = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendByUin, uin)
  if friendData then
    local card_icon_selected = friendData.card_icon_selected
    self:SetHeadIcon(headNode, card_icon_selected)
    local playerName = friendData.name
    nameNode:SetText(playerName)
  else
    local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
    req.uin = uin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, caller, callback, false, true)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnLeftPhotoInfoUpdateRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    local card_icon_selected = rsp.player_info.card_icon_selected
    self:SetHeadIcon(self.HeadPortrait_A, card_icon_selected)
    local playerName = rsp.player_info.name
    self.Text_Name_A:SetText(playerName)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnRightPhotoInfoUpdateRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    local card_icon_selected = rsp.player_info.card_icon_selected
    self:SetHeadIcon(self.HeadPortrait_B, card_icon_selected)
    local playerName = rsp.player_info.name
    self.Text_Name_B:SetText(playerName)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:SetHeadIcon(headNode, card_icon_selected)
  if card_icon_selected and 0 ~= card_icon_selected then
    local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    local avatarPath = cardIconConf.icon_resource_path
    avatarPath = string.format("%s%s.%s'", path, avatarPath, avatarPath)
    headNode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    headNode:SetPath(avatarPath)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnRewardBtnClick()
  if not self.activityInst then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_Vote_C:OnRewardBtnClick")
  _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionVoteRewardPanel, self.activityInst)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnVoteBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Activity_TakePhotoCompetition_Vote_C:OnVoteBtnClick")
  if not self.photoData or not self.photoData.photos then
    return
  end
  if not self.activityInst then
    return
  end
  if #self.photoData.photos < 1 then
    return
  end
  self.voteIndex = 1
  self.activityInst:SendPlayerLike(self.photoData.photos[self.voteIndex].uin)
  self:HideRewardRedPoint()
  self:RefreshCloseTimer()
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnVoteBtn1Click()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Activity_TakePhotoCompetition_Vote_C:OnVoteBtn1Click")
  if not self.photoData or not self.photoData.photos then
    return
  end
  if not self.activityInst then
    return
  end
  if #self.photoData.photos < 2 then
    return
  end
  self.voteIndex = 2
  self.activityInst:SendPlayerLike(self.photoData.photos[self.voteIndex].uin)
  self:HideRewardRedPoint()
  self:RefreshCloseTimer()
end

function UMG_Activity_TakePhotoCompetition_Vote_C:HideRewardRedPoint()
  if not self.Dot:IsRed() then
    self.RedDotParent:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnRefreshBtnClick()
  if not self.activityInst then
    return
  end
  if not self.photoData then
    return
  end
  if self.photoData.skip_count >= _G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_skip_num").num then
    return
  end
  self:PlayAnimation(self.Vote_ChangePhoto_Refresh)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnBtnClickAClick()
  if not self.photoData then
    return
  end
  if not self.photoData.photos then
    return
  end
  if #self.photoData.photos < 1 then
    return
  end
  local BigPhotoData = {
    bigPhotoType = ActivityEnum.TakePhotoCompetitionBigPhotoType.VotePhoto,
    sourcePhoto = self.PhotoFile,
    uin = self.photoData.photos[1].uin,
    photo_url = self.photoData.photos[1].photo_url,
    photo_md5 = self.photoData.photos[1].photo_md5,
    mini_photo_url = self.photoData.photos[1].mini_photo_url,
    mini_photo_md5 = self.photoData.photos[1].mini_photo_md5,
    hot_value = 0,
    activity_sub_id = self.photoData.activity_sub_id
  }
  _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionBigPhoto, BigPhotoData)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnBtnClickBClick()
  if not self.photoData then
    return
  end
  if not self.photoData.photos then
    return
  end
  if #self.photoData.photos < 2 then
    return
  end
  local BigPhotoData = {
    bigPhotoType = ActivityEnum.TakePhotoCompetitionBigPhotoType.VotePhoto,
    sourcePhoto = self.PhotoFile,
    uin = self.photoData.photos[2].uin,
    photo_url = self.photoData.photos[2].photo_url,
    photo_md5 = self.photoData.photos[2].photo_md5,
    mini_photo_url = self.photoData.photos[2].mini_photo_url,
    mini_photo_md5 = self.photoData.photos[2].mini_photo_md5,
    hot_value = 0,
    activity_sub_id = self.photoData.activity_sub_id
  }
  _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionBigPhoto, BigPhotoData)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnClickReportBtnA()
  local photoList = self.photoData and self.photoData.photos
  local photoInfo = photoList and photoList[1]
  if photoInfo then
    local activity_sub_id = self.photoData.activity_sub_id
    TakePhotosUtils.ReportPhoto(photoInfo.uin, photoInfo.mini_photo_url, photoInfo.photo_url, activity_sub_id)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnClickReportBtnB()
  local photoList = self.photoData and self.photoData.photos
  local photoInfo = photoList and photoList[2]
  if photoInfo then
    local activity_sub_id = self.photoData.activity_sub_id
    TakePhotosUtils.ReportPhoto(photoInfo.uin, photoInfo.mini_photo_url, photoInfo.photo_url, activity_sub_id)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnActivityPhotoContestLikeNty(rsp)
  if rsp then
    self.likeData = rsp
    if not (self.likeData and self.likeData.photos) or #self.likeData.photos < 2 then
      Log.Error("UMG_Activity_TakePhotoCompetition_Vote_C:OnActivityPhotoContestLikeNty likeData photos is invalid")
      return
    end
    if self.activityInst then
      self.activityInst:OnUpdateActivityDataAccuracy(rsp.accuracy_score)
    end
    self:PlayLikeEffect()
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:PlayLikeEffect()
  self.CanvasPanel_165:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if not self.photoData then
    return
  end
  if not self.photoData.photos then
    return
  end
  if #self.photoData.photos < 2 then
    return
  end
  local photoAData, photoBData
  for _k, _v in ipairs(self.likeData.photos) do
    if _v.uin == self.photoData.photos[1].uin then
      photoAData = _v
    end
    if _v.uin == self.photoData.photos[2].uin then
      photoBData = _v
    end
  end
  if photoAData and photoBData then
    local totalLikeCount = photoAData.like_count + photoBData.like_count
    if 0 == totalLikeCount then
      totalLikeCount = 1
      Log.Error("UMG_Activity_TakePhotoCompetition_Vote_C:PlayLikeEffect totalLikeCount is 0")
    end
    if photoAData.like_count > photoBData.like_count then
      self.winnerIndex = 1
    elseif photoAData.like_count < photoBData.like_count then
      self.winnerIndex = 2
    else
      self.winnerIndex = 0
    end
    local percentA = photoAData.like_count / totalLikeCount
    local percentB = photoBData.like_count / totalLikeCount
    self.progressBarA = {
      percent = percentA,
      likeCount = photoAData.like_count
    }
    self.progressBarB = {
      percent = percentB,
      likeCount = photoBData.like_count
    }
    self.Text_Describe_1:SetText(tostring(self.progressBarA.likeCount))
    self.Text_Describe_2:SetText(tostring(self.progressBarB.likeCount))
  end
  local numberLikesNode = self.NumberLikesA
  local numberLikesNumText = self.NumberLikes
  local accuracyNode = self.AccuracyBonus_A
  local accuracyText = self.shuliang_4
  local accuracyNumText = self.Accuracy_A
  if 2 == self.voteIndex then
    numberLikesNode = self.NumberLikesB
    numberLikesNumText = self.NumberLikes_1
    accuracyNode = self.AccuracyBonus_B
    accuracyText = self.shuliang_5
    accuracyNumText = self.Accuracy_B
  end
  numberLikesNode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  numberLikesNumText:SetText(tostring(_G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_popularity").num))
  if 0 == self.winnerIndex or self.winnerIndex == self.voteIndex then
    accuracyNode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    accuracyText:SetText(LuaText.pic_game_accuracy)
    accuracyNumText:SetText("+" .. tostring(_G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_accuracy").num))
  end
  if 1 == self.voteIndex then
    self:PlayAnimation(self.NumberLikesA_1)
  else
    self:PlayAnimation(self.NumberLikesB_1)
  end
  _G.NRCAudioManager:PlaySound2DAuto(1183, "UMG_Activity_TakePhotoCompetition_Vote_C:Vote_Start")
  self:PlayAnimation(self.Vote_Start)
  self.Text_Describe_A:SetText("0%")
  self.Text_Describe_B:SetText("0%")
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnAfterLikeEffectFinishedResult()
  if not self.likeData then
    return
  end
  local oldScore = tonumber(self.Accuracy:GetText()) or 0
  local newScore = self.likeData.accuracy_score or 0
  if newScore ~= oldScore then
    self.accuracyFrom = oldScore
    self.accuracyTo = newScore
    self.accuracyElapsed = 0
    self.accuracyRolling = true
  else
    self.Accuracy:SetText(tostring(newScore))
  end
  if self.AddText then
    self.AddText:SetText("+" .. tostring(_G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_accuracy").num))
  end
  self.PhotoMaskA:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PhotoMaskB:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if 1 == self.winnerIndex then
    if 1 == self.voteIndex then
      self:PlayAnimation(self.Vote_Win_A)
    end
    self:PlayAnimation(self.Vote_Lose_B)
  elseif 2 == self.winnerIndex then
    if 2 == self.voteIndex then
      self:PlayAnimation(self.Vote_Win_B)
    end
    self:PlayAnimation(self.Vote_Lose_A)
  elseif 0 == self.winnerIndex then
    if 1 == self.voteIndex then
      self:PlayAnimation(self.Vote_Win_A)
    else
      self:PlayAnimation(self.Vote_Win_B)
    end
  end
  self.ProgressBar_A:SetPercent(self.progressBarA.percent or 0)
  self.ProgressBar_B:SetPercent(self.progressBarB.percent or 0)
  self.Text_Describe_A:SetText(string.format("%d", math.round((self.progressBarA.percent or 0) * 100)) .. "%")
  self.Text_Describe_B:SetText(string.format("%d", math.round((self.progressBarB.percent or 0) * 100)) .. "%")
  if self.timerId then
    _G.DelayManager:CancelDelayById(self.timerId)
  end
  self.timerId = _G.DelayManager:DelaySeconds(2, function()
    if self.recommendCount <= 0 then
      self:OnRefreshRecommendFinishPanel()
      self:PlayAnimation(self.RunOut_In)
      self.currentSwitcherIndex = 1
    else
      self:PlayAnimation(self.Vote_ChangePhoto_Next)
    end
    self.timerId = nil
  end)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:AnimateProgressBarPercent(progressBar, speed, targetPercent, dt)
  if not progressBar then
    return
  end
  local currentPercent = progressBar.Percent
  if math.abs(currentPercent - targetPercent) < 0.001 then
    progressBar:SetPercent(targetPercent)
    self.progressBarRolling = false
    self.progressBarNext = true
    return
  end
  local step = speed * dt
  local newPercent = currentPercent + step
  if step > 0 then
    newPercent = math.min(newPercent, targetPercent)
  else
    newPercent = math.max(newPercent, targetPercent)
  end
  progressBar:SetPercent(newPercent)
  Log.Debug("AnimateProgressBarPercent newPercent", newPercent)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:Tick(MyGeometry, Dt)
  if self.progressBarRolling then
    self:AnimateProgressBarPercent(self.ProgressBar_A, self.progressBarSpeedA, self.progressBarA.percent or 0, Dt)
    self:AnimateProgressBarPercent(self.ProgressBar_B, self.progressBarSpeedB, self.progressBarB.percent or 0, Dt)
    if self.progressBarNext then
      self:ProgressBarReachTarget()
      self.progressBarNext = false
    end
  end
  if self.percentRolling then
    local percentA = self.ProgressBar_A.Percent
    local percentB = self.ProgressBar_B.Percent
    self.Text_Describe_A:SetText(string.format("%d", math.round(percentA * 100)) .. "%")
    self.Text_Describe_B:SetText(string.format("%d", math.round(percentB * 100)) .. "%")
  end
  if self.accuracyRolling then
    self.accuracyElapsed = self.accuracyElapsed + Dt
    local t = math.min(self.accuracyElapsed / self.accuracyRollDuration, 1)
    local easedT = 1 - (1 - t) * (1 - t)
    local currentValue = math.floor(self.accuracyFrom + (self.accuracyTo - self.accuracyFrom) * easedT)
    self.Accuracy:SetText(tostring(currentValue))
    if t >= 1 then
      self.Accuracy:SetText(tostring(self.accuracyTo))
      self.accuracyRolling = false
    end
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:ChangePhotoRefresh()
  if self.activityInst then
    self.activityInst:GetPhotoEvaluationInfo(true)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:ChangePhotoNext()
  if self.activityInst then
    self.activityInst:GetPhotoEvaluationInfo(false)
  end
end

function UMG_Activity_TakePhotoCompetition_Vote_C:ProgressBarReachTarget()
  self.percentRolling = false
  local totalX = 1843
  if self.ProgressBar_Particle then
    local offsetX = ((self.progressBarA.percent or 0) - 0.5) * totalX
    local slot = self.ProgressBar_Particle.Slot
    if slot then
      slot:SetPosition(UE4.FVector2D(offsetX, 474))
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(1276, "UMG_Activity_TakePhotoCompetition_Vote_C:ProgressBarReachTarget")
  self:OnAfterLikeEffectFinishedResult()
  self:PlayAnimation(self.Vote_ProgressBar_Particle)
end

function UMG_Activity_TakePhotoCompetition_Vote_C:OnAnimationFinished(anim)
  if anim == self.Vote_In then
  elseif anim == self.Vote_Start then
    self:PlayAnimation(self.Vote_ProgressBar)
    self.percentRolling = true
  elseif anim == self.Vote_ProgressBar then
    self.progressBarRolling = true
    self.progressBarSpeedA = ((self.progressBarA.percent or 0) - self.ProgressBar_A.Percent) / self.progressBarTargetTime
    self.progressBarSpeedB = ((self.progressBarB.percent or 0) - self.ProgressBar_B.Percent) / self.progressBarTargetTime
  elseif anim == self.Vote_Win_A or anim == self.Vote_Win_B then
    self:PlayAnimation(self.Vote_Win_End)
    self.RedDotParent:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif anim == self.RunOut_Out or anim == self.Vote_Out then
    self:DoClose()
  end
end

return UMG_Activity_TakePhotoCompetition_Vote_C

local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local CountDownHandler = require("NewRoco.Modules.System.Misc.CountDownHandler")
local UMG_Activity_TakePhotoCompetition_C = Base:Extend("UMG_Activity_TakePhotoCompetition_C")
local ActivityModuleCmd = require("NewRoco.Modules.System.Activity.ActivityModuleCmd")

function UMG_Activity_TakePhotoCompetition_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION
  uiElements.particularsBtn = self.BtnParticulars
  return uiElements
end

function UMG_Activity_TakePhotoCompetition_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
  self.leftTimeCountDown = CountDownHandler.CreateCountDownObjectByTimeFunction(self.GetCurrentLeftTime, self)
  self.leftTimeCountDown:BindCtrl(self.Text_TimeRemaining, self.FormatterLeftTime, self)
end

function UMG_Activity_TakePhotoCompetition_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_HotPhoto.btnLevelUp, self.OnClickHotPhotoBtn)
  self:AddButtonListener(self.SubmissionPeriodBtn.btnLevelUp, self.OnClickSubmissionBtn)
  self:AddButtonListener(self.VoteBtn.btnLevelUp, self.OnClickVoteBtn)
  self:AddButtonListener(self.EndBtn.btnLevelUp, self.OnClickEndBtn)
  self:AddButtonListener(self.BtnRewardPreview, self.OnClickRewardPreviewBtn)
  self:AddButtonListener(self.BtnMySubmission, self.OnClickMySubmissionBtn)
  self:AddButtonListener(self.ToShopBtn, self.OnClickToShopBtn)
  self:AddButtonListener(self.PreviousReviewBtn, self.OnClickPreviousReviewBtn)
  self:AddButtonListener(self.RankBtn.btnLevelUp, self.OnClickRankBtn)
  self:SetChildViews(self.HotActivityPhotoFile, self.MyActivityPhotoFile)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ActivityModuleEvent.RefreshTakePhotoCompetitionActivityDataEvent, self.OnRefreshActivityData)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ActivityModuleEvent.TakePhotoCompetitionActivityHotPhotoEvent, self.SetHotPhoto)
  _G.NRCEventCenter:RegisterEvent(self.name, self, TakePhotosModuleEvent.OnPhotoActivitySubmit, self.OnPhotoActivitySubmit)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ActivityModuleEvent.TakePhotoCompetitionActivityUpdateRecommendCountEvent, self.OnUpdateRecommendCount)
end

function UMG_Activity_TakePhotoCompetition_C:OnDestruct()
  Base.OnDestruct(self)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.RefreshTakePhotoCompetitionActivityDataEvent, self.OnRefreshActivityData)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.TakePhotoCompetitionActivityHotPhotoEvent, self.SetHotPhoto)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnPhotoActivitySubmit, self.OnPhotoActivitySubmit)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.TakePhotoCompetitionActivityUpdateRecommendCountEvent, self.OnUpdateRecommendCount)
  if self.leftTimeCountDown then
    self.leftTimeCountDown:UnbindCtrl(self.Text_TimeRemaining)
    self.leftTimeCountDown = nil
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnEnable(firstLoad)
  Log.Info("UMG_Activity_TakePhotoCompetition_C:OnEnable firstLoad", firstLoad)
  Base.OnEnable(self, firstLoad)
  local activityInst = self.activityInst
  if not activityInst then
    Log.Error("UMG_Activity_TakePhotoCompetition_C:OnEnable activityInst not found")
    return
  end
  activityInst:ReqGetHotPhoto()
  self.bPlayingAnim = false
  if firstLoad then
    self:RefreshPanel()
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnDisable()
  Base.OnDisable(self)
  if self.photoCheckTimer then
    _G.TimerManager:RemoveTimer(self.photoCheckTimer)
    self.photoCheckTimer = nil
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnRefreshActivityData()
  Log.Info("UMG_Activity_TakePhotoCompetition_C:OnRefreshActivityData")
  self.activityInst:CheckSubmissionReward()
  self:RefreshPanel()
end

function UMG_Activity_TakePhotoCompetition_C:RefreshPanel()
  Log.Info("UMG_Activity_TakePhotoCompetition_C:RefreshPanel")
  local activityInst = self.activityInst
  if not activityInst then
    Log.Error("UMG_Activity_TakePhotoCompetition_C:RefreshPanel activityInst not found")
    return
  end
  local activity_data = activityInst:GetActivityData()
  if not activity_data then
    Log.Error("UMG_Activity_TakePhotoCompetition_C:RefreshPanel activity_data not found")
    return
  end
  self.activity_data = activity_data
  local currentPhaseConf = activityInst:GetCurrentPhaseConf()
  if not currentPhaseConf then
    Log.Error("UMG_Activity_TakePhotoCompetition_C:RefreshPanel currentPhaseConf not found")
    return
  end
  self.NRCText_PreviousReview:SetText(LuaText.pic_game_rankboard_before_button)
  self.ToShopBtn_Text:SetText(LuaText.pic_game_shop)
  self.RewardPreview_Text:SetText(LuaText.pic_game_submit_reward_preview)
  self.RankBtn.Title_1:SetText(LuaText.pic_game_rankboard_now_button)
  if activityInst:IsRestPhase() then
    self.Text_Title:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Text_Title:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local lastDigit = string.format("%02d", (currentPhaseConf.id or 0) % 10)
    self.Text_Title:SetText(string.format(LuaText.pic_game_submit_them, lastDigit))
  end
  if currentPhaseConf.name then
    self.Text_Title_1:SetText(currentPhaseConf.name)
  end
  if currentPhaseConf.desc then
    self.Text_Describe:SetText(currentPhaseConf.desc)
  end
  local lastDigit = currentPhaseConf.id % 10
  if 1 == lastDigit then
    self.CanvasPanel_PreviousReview:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.CanvasPanel_PreviousReview:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if currentPhaseConf and currentPhaseConf.poster then
    self.BG_Theme:SetPath(currentPhaseConf.poster)
    self.CardBg:SetPath(currentPhaseConf.card)
  end
  local playingAnim
  if activityInst:IsRestPhase() then
    playingAnim = self.Intermission_In
    self.SabbaticalCard:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_Stage:SetText(LuaText.pic_game_rest_time)
    self.endTimeStamp = ActivityUtils.ToTimestamp(currentPhaseConf.end_time)
    self.BtnRewardPreview:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.SabbaticalCard:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnRewardPreview:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
    local curStage = activityInst:GetCurrentStage()
    if curStage == ActivityEnum.TakePhotoCompetitionStage.Preparation then
      playingAnim = self.Submission_In
      self.timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_Stage:SetText(LuaText.pic_game_submit_time)
      self.endTimeStamp = ActivityUtils.ToTimestamp(currentPhaseConf.preparation_end_time)
      self.BtnSwitcher:SetActiveWidgetIndex(0)
      local mySubmission = activityInst:GetMySubmission()
      if mySubmission then
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Visible)
        self.NRCText_MySubmission:SetText(LuaText.pic_game_submit_mine)
        self.MyActivityPhotoFile:DisplayFixedFramePhotoMiniMode(mySubmission.mini_photo_url, mySubmission.mini_photo_md5)
        self.SubmissionPeriodBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.pic_game_submit_done_desc)
        self.SubmissionPeriodBtn.Title_1:SetText(LuaText.pic_game_submit_view_button)
      else
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.SubmissionPeriodBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.pic_game_submit_desc)
        self.SubmissionPeriodBtn.Title_1:SetText(LuaText.pic_game_submit_button)
      end
    elseif curStage == ActivityEnum.TakePhotoCompetitionStage.PhotoCheck then
      playingAnim = self.Submission_In
      self.timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.endTimeStamp = ActivityUtils.ToTimestamp(currentPhaseConf.competition_start_time)
      self.BtnSwitcher:SetActiveWidgetIndex(2)
      local mySubmission = activityInst:GetMySubmission()
      if mySubmission then
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Visible)
        self.NRCText_MySubmission:SetText(LuaText.pic_game_submit_mine)
        self.MyActivityPhotoFile:DisplayFixedFramePhotoMiniMode(mySubmission.mini_photo_url, mySubmission.mini_photo_md5)
      else
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      local currentSec = ActivityUtils.GetSvrTimestamp()
      local leftSec = self.endTimeStamp - currentSec
      if not self.photoCheckTimer then
        self.photoCheckTimer = _G.TimerManager:CreateTimer(self, "UMG_Activity_TakePhotoCompetition_C:RefreshPanel", leftSec, self.OnTimerUpdate, self.OnTimerEnd, 0.5)
        self:OnTimerUpdate()
      end
    elseif curStage == ActivityEnum.TakePhotoCompetitionStage.Competition then
      playingAnim = self.Voting_In
      self.timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_Stage:SetText(LuaText.pic_game_judge_time)
      self.endTimeStamp = ActivityUtils.ToTimestamp(currentPhaseConf.competition_end_time)
      self.BtnSwitcher:SetActiveWidgetIndex(1)
      self.NRCSwitcher_participate:SetActiveWidgetIndex(0)
      local mySubmission = activityInst:GetMySubmission()
      if mySubmission then
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Visible)
        self.NRCText_MySubmission:SetText(LuaText.pic_game_submit_mine)
        self.MyActivityPhotoFile:DisplayFixedFramePhotoMiniMode(mySubmission.mini_photo_url, mySubmission.mini_photo_md5)
      else
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      local tipsText = string.format(LuaText.pic_game_judge_push_times, self.activity_data.recommend_count or 0)
      self.VoteBtn:SetTitleTextAndIcon(nil, nil, nil, nil, tipsText)
      self.VoteBtn.Title_1:SetText(LuaText.pic_game_judge_button)
    elseif curStage == ActivityEnum.TakePhotoCompetitionStage.CurPhaseEnd then
      playingAnim = self.Ended_In
      self.timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_Stage:SetText(LuaText.pic_game_settlement_time)
      self.endTimeStamp = ActivityUtils.ToTimestamp(currentPhaseConf.end_time)
      self.BtnSwitcher:SetActiveWidgetIndex(1)
      self.NRCSwitcher_participate:SetActiveWidgetIndex(1)
      local mySubmission = activityInst:GetMySubmission()
      if mySubmission then
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Visible)
        self.NRCText_MySubmission:SetText(LuaText.pic_game_submit_mine)
        self.MyActivityPhotoFile:DisplayFixedFramePhotoMiniMode(mySubmission.mini_photo_url, mySubmission.mini_photo_md5)
      else
        self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.EndBtn:SetShowLockIcon(false)
      self.EndBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.pic_game_settlement_desc)
      self.EndBtn.Title_1:SetText(LuaText.pic_game_settlement_button)
    end
  end
  if playingAnim and not self.bPlayingAnim then
    self:PlayAnimation(playingAnim)
    self.bPlayingAnim = true
  end
  self.leftTimeCountDown:ForceRefreshLeftTime()
  self.VoteBtn.RedDot:SetupKey(215, {
    activityInst:GetActivityId(),
    self.activity_data.current_phase_id
  })
  self.VoteBtn.RedDot:SetRedStatusChangeListener(self, self.OnAccuracyRewardRedPointStatusChange, self.VoteBtn.RedDot)
  self:OnAccuracyRewardRedPointStatusChange(self.VoteBtn.RedDot)
end

function UMG_Activity_TakePhotoCompetition_C:FormatterLeftTime(leftSeconds)
  return ActivityUtils.GetTimeFormatStr(leftSeconds)
end

function UMG_Activity_TakePhotoCompetition_C:GetCurrentLeftTime()
  return self.endTimeStamp or 0
end

function UMG_Activity_TakePhotoCompetition_C:OnTimerUpdate()
  local currentSec = ActivityUtils.GetSvrTimestamp()
  local leftSec = self.endTimeStamp - currentSec
  local hours = leftSec // 3600
  local minutes = (leftSec - 3600 * hours) // 60
  local seconds = leftSec - 3600 * hours - 60 * minutes
  local hourString = hours < 10 and "0" .. tostring(hours) or tostring(hours)
  local minuteString = minutes < 10 and "0" .. tostring(minutes) or tostring(minutes)
  local secondString = seconds < 10 and "0" .. tostring(seconds) or tostring(seconds)
  self.SelectionPeriodCountdownBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.pic_game_judge_countdown .. "  " .. hourString .. ":" .. minuteString .. ":" .. secondString)
end

function UMG_Activity_TakePhotoCompetition_C:OnTimerEnd()
  if self.photoCheckTimer then
    _G.TimerManager:RemoveTimer(self.photoCheckTimer)
    self.photoCheckTimer = nil
  end
  if self.activityInst then
    self.activityInst:SyncActivityDataOnAvailable()
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnUpdateRecommendCount()
  local activityData = self.activityInst:GetActivityData()
  if activityData then
    local tipsText = string.format(LuaText.pic_game_judge_push_times, activityData.recommend_count or 0)
    self.VoteBtn:SetTitleTextAndIcon(nil, nil, nil, nil, tipsText)
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnAccuracyRewardRedPointStatusChange(redPoint)
  if redPoint:IsRed() then
    self.RedDot_ClickVote:SetupKey(0)
  else
    self.RedDot_ClickVote:SetupKey(473, self.activityInst:GetActivityId())
  end
end

function UMG_Activity_TakePhotoCompetition_C:SetHotPhoto()
  local activityInst = self.activityInst
  self.hotPhoto = activityInst:GetHotPhoto()
  
  local function SetTopic()
    local lastDigit = self.hotPhoto.activity_sub_id % 10
    local iconName = string.format("img_%sLittle_png", lastDigit)
    local path = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/"
    path = string.format("%s%s.%s'", path, iconName, iconName)
    self.NumbersImage:SetPath(path)
    local phaseConf = _G.DataConfigManager:GetTakephotoCompetitionConf(self.hotPhoto.activity_sub_id)
    if phaseConf then
      self.Name:SetText(phaseConf.name)
    end
  end
  
  if 0 == self.hotPhoto.ret_info.ret_code then
    if self.hotPhoto.uin and 0 ~= self.hotPhoto.uin then
      self.CanvasPanel_Photo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:SetIconAndName(self.hotPhoto.uin)
      local photoScore = self:GetHotPhotoScore()
      self.Hot_Text:SetText(photoScore)
      self.HotActivityPhotoFile:DisplayFixedFramePhotoMiniMode(self.hotPhoto.mini_photo_url, self.hotPhoto.mini_photo_md5, self.CanvasPanel_3.Slot:GetSize())
      self.Btn_HotPhoto:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if activityInst:IsRestPhase() then
        self.Topic:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        SetTopic()
      else
        self.Topic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    elseif activityInst:IsRestPhase() then
      self.CanvasPanel_Photo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasProfilePicture:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.HotActivityPhotoFile:OnPhotoMissing()
      self.Btn_HotPhoto:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Topic:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      SetTopic()
    else
      self.CanvasPanel_Photo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CanvasPanel_Photo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasProfilePicture:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HotActivityPhotoFile:OnPhotoMissing()
    self.Btn_HotPhoto:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if activityInst:IsRestPhase() then
      self.Topic:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      SetTopic()
    else
      self.Topic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnPhotoActivitySubmit()
  local activityInst = self.activityInst
  if activityInst then
    local mySubmission = activityInst:GetMySubmission()
    if mySubmission then
      self.BtnMySubmission:SetVisibility(UE4.ESlateVisibility.Visible)
      self.NRCText_MySubmission:SetText(LuaText.pic_game_submit_mine)
      self.MyActivityPhotoFile:DisplayFixedFramePhotoMiniMode(mySubmission.mini_photo_url, mySubmission.mini_photo_md5)
    end
  end
  if self.SubmissionPeriodBtn then
    self.SubmissionPeriodBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.pic_game_submit_done_desc)
    self.SubmissionPeriodBtn.Title_1:SetText(LuaText.pic_game_submit_view_button)
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnClickHotPhotoBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_Activity_TakePhotoCompetition_C:OnClickHotPhotoBtn")
  if not self.hotPhoto then
    Log.Info("UMG_Activity_TakePhotoCompetition_C:OnClickHotPhotoBtn hotPhoto is nil")
    return
  end
  if self:IsActivityValid() then
    local bigPhotoData = {}
    bigPhotoData.bigPhotoType = ActivityEnum.TakePhotoCompetitionBigPhotoType.HotPhoto
    bigPhotoData.sourcePhoto = self.HotActivityPhotoFile
    bigPhotoData.uin = self.hotPhoto.uin
    bigPhotoData.photo_url = self.hotPhoto.photo_url
    bigPhotoData.photo_md5 = self.hotPhoto.photo_md5
    bigPhotoData.mini_photo_url = self.hotPhoto.mini_photo_url
    bigPhotoData.mini_photo_md5 = self.hotPhoto.mini_photo_md5
    bigPhotoData.hot_value = self:GetHotPhotoScore()
    bigPhotoData.activity_sub_id = self.hotPhoto.activity_sub_id
    bigPhotoData.rank = self.hotPhoto.rank_no
    _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionBigPhoto, bigPhotoData)
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnClickSubmissionBtn()
  local activityInst = self.activityInst
  if activityInst then
    local curStage = activityInst:GetCurrentStage()
    if curStage == ActivityEnum.TakePhotoCompetitionStage.Preparation then
      _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_TakePhotoCompetition_C:OnClickSubmissionBtn")
      if activityInst:GetMySubmission() then
        self:OpenMySubmission()
      else
        _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.OpenPhotosActivityAlbumPanel)
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_3200)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnClickVoteBtn()
  local activityInst = self.activityInst
  if activityInst then
    local curStage = activityInst:GetCurrentStage()
    if curStage == ActivityEnum.TakePhotoCompetitionStage.Competition then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_C:OnClickVoteBtn")
      _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionVotePanel, activityInst)
      self.RedDot_ClickVote:EraseRedPoint()
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_3201)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnClickEndBtn()
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pic_game_settlement_tips)
end

function UMG_Activity_TakePhotoCompetition_C:OnClickRewardPreviewBtn()
  _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionRewardPreview)
end

function UMG_Activity_TakePhotoCompetition_C:OnClickMySubmissionBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Activity_TakePhotoCompetition_C:OnClickMySubmissionBtn")
  self:OpenMySubmission()
end

function UMG_Activity_TakePhotoCompetition_C:OpenMySubmission()
  local activityInst = self.activityInst
  local mySubmission = activityInst:GetMySubmission()
  if mySubmission then
    Log.Info("UMG_Activity_TakePhotoCompetition_C:OpenMySubmission hot_count = ", mySubmission.total_hot_count)
    local rankScore = 0
    Log.Info("UMG_Activity_TakePhotoCompetition_C:OpenMySubmission current_phase_id = ", self.activity_data.current_phase_id)
    local rankDataObject = activityInst:GetRankDataObject(self.activity_data.current_phase_id, false)
    if rankDataObject then
      local rankData = rankDataObject:GetPlayerRankData()
      if rankData then
        Log.Info("UMG_Activity_TakePhotoCompetition_C:OpenMySubmission rankData score = ", rankData.user_info.score)
        rankScore = rankData.user_info.score
      end
    end
    local bigPhotoData = {}
    bigPhotoData.bigPhotoType = ActivityEnum.TakePhotoCompetitionBigPhotoType.MySubmission
    bigPhotoData.sourcePhoto = nil
    bigPhotoData.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    bigPhotoData.photo_url = mySubmission.photo_url
    bigPhotoData.photo_md5 = mySubmission.photo_md5
    bigPhotoData.mini_photo_url = mySubmission.mini_photo_url
    bigPhotoData.mini_photo_md5 = mySubmission.mini_photo_md5
    bigPhotoData.hot_value = math.max(rankScore, mySubmission.total_hot_count)
    bigPhotoData.activity_sub_id = activityInst:GetActivityData().current_phase_id
    _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionBigPhoto, bigPhotoData)
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnClickToShopBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_C:OnClickToShopBtn")
  if self:IsActivityValid() then
    local shop_id = self.activityInst:GetActivityTypeParam()[1]
    if shop_id then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenShopById, shop_id)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnClickPreviousReviewBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_C:OnClickPreviousReviewBtn")
  if self:IsActivityValid() then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionPreviousReviewPanel, self.activityInst)
  end
end

function UMG_Activity_TakePhotoCompetition_C:IsActivityValid()
  local activityInst
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if takePhotoActivityInst then
    activityInst = takePhotoActivityInst[1]
  end
  if nil == activityInst then
    Log.Info("UMG_Activity_TakePhotoCompetition_C:IsActivityValid activityInst is nil")
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return false
  end
  if activityInst and activityInst:IsActivityInactive() then
    Log.Info("UMG_Activity_TakePhotoCompetition_C:IsActivityValid activityInactive")
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return false
  end
  return true
end

function UMG_Activity_TakePhotoCompetition_C:OnClickRankBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_C:OnClickRankBtn")
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionRankingsPanel, self.activityInst)
end

function UMG_Activity_TakePhotoCompetition_C:GetHotPhotoScore()
  if self.activityInst then
    self.hotPhoto = self.activityInst:GetHotPhoto()
    if self.hotPhoto and self.hotPhoto.uin then
      Log.Info("UMG_Activity_TakePhotoCompetition_C:GetHotPhotoScore hot_count = ", self.hotPhoto.hot_count)
      local rankScore = 0
      local activity_data = self.activityInst:GetActivityData()
      if activity_data then
        Log.Info("UMG_Activity_TakePhotoCompetition_C:GetHotPhotoScore current_phase_id = ", activity_data.current_phase_id)
        local rankDataObject = self.activityInst:GetRankDataObject(activity_data.current_phase_id, false)
        if rankDataObject then
          local rankData = rankDataObject:GetUserRankData(self.hotPhoto.uin)
          if rankData then
            Log.Info("UMG_Activity_TakePhotoCompetition_C:GetHotPhotoScore rankData score = ", rankData.user_info.score)
            rankScore = rankData.user_info.score
          end
        end
      end
      return math.max(rankScore, self.hotPhoto.hot_count)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_C:SetIconAndName(uin)
  self:Log("SetIconAndName", uin)
  local curPlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if curPlayerUin == uin then
    self:Log("SetIconAndName LocalPlayer", curPlayerUin)
    self.CanvasProfilePicture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local card_brief_info = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
    if card_brief_info then
      local card_icon_selected = card_brief_info.card_icon_selected
      self:SetHeadIcon(card_icon_selected)
      local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
      self.Text_PlayerName:SetText(playerName)
    end
  else
    local friendData = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendByUin, uin)
    if friendData then
      self:Log("SetIconAndName GetFriendByUin", friendData)
      self.CanvasProfilePicture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local card_icon_selected = friendData.card_icon_selected
      self:SetHeadIcon(card_icon_selected)
      local playerName = friendData.name
      self.Text_PlayerName:SetText(playerName)
    else
      self:Log("SetIconAndName ZONE_FRIEND_SEARCH_PLAYER_REQ", uin)
      local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
      req.uin = uin
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnSearchPlayerRsp, false, true)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_C:OnSearchPlayerRsp(rsp)
  self:Log("SetIconAndName ZoneFriendSearchPlayerRsp", rsp.ret_info.ret_code, rsp.player_info and rsp.player_info.name)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    self.CanvasProfilePicture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local card_icon_selected = rsp.player_info.card_icon_selected
    self:SetHeadIcon(card_icon_selected)
    local playerName = rsp.player_info.name
    self.Text_PlayerName:SetText(playerName)
  else
    self.CanvasProfilePicture:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_TakePhotoCompetition_C:SetHeadIcon(card_icon_selected)
  if card_icon_selected and 0 ~= card_icon_selected then
    local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    local avatarPath = cardIconConf.icon_resource_path
    avatarPath = string.format("%s%s.%s'", path, avatarPath, avatarPath)
    self.Image_Head:SetPath(avatarPath)
  end
end

return UMG_Activity_TakePhotoCompetition_C

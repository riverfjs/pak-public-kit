local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local TakePhotoCompetitionActivityObject = Base:Extend("TakePhotoCompetitionActivityObject")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local RankDataHandler = require("NewRoco.Modules.System.Misc.RankDataHandler")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")

function TakePhotoCompetitionActivityObject:OnConstruct(_conf)
  self.rankDataObjects = {}
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_SUBMIT_REWARD_NOTIFY, self.OnActivityPhotoContestSubmitRewardNotify)
end

function TakePhotoCompetitionActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    Log.Info("TakePhotoCompetitionActivityObject:OnSvrUpdateActivityData current_phase_id = ", _updateData.photo_contest_data.current_phase_id)
    if _updateData.photo_contest_data then
      self.activity_data = _updateData.photo_contest_data
      if self.activity_data.phases == nil then
        self.activity_data.phases = {}
      end
      for i = 1, #self.activity_data.phases do
        local phase = self.activity_data.phases[i]
        if not phase.total_like_count then
          phase.total_like_count = 0
        end
        if not phase.is_disposable_reward_taken then
          phase.is_disposable_reward_taken = false
        end
        if not phase.total_hot_count then
          phase.total_hot_count = 0
        end
      end
      local currentPhaseId = _updateData.photo_contest_data.current_phase_id
      if self.currentPhaseId ~= currentPhaseId then
        self.currentPhaseId = currentPhaseId
        local partIds = self:GetPartIds()
        if partIds and #partIds > 0 then
          self.pastPhaseIds = table.new(#partIds, 0)
          for i = #partIds, 1, -1 do
            if currentPhaseId > partIds[i] then
              table.insert(self.pastPhaseIds, partIds[i])
            end
          end
        end
      end
      _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TakePhotoCompetitionActivityVoteRewardEvent)
    end
    Log.Info("TakePhotoCompetitionActivityObject:OnSvrUpdateActivityData DispatchEvent")
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.RefreshTakePhotoCompetitionActivityDataEvent)
  end
end

function TakePhotoCompetitionActivityObject:GetActivityData()
  return self.activity_data or {}
end

function TakePhotoCompetitionActivityObject:SyncActivityDataOnAvailable()
  Log.Info(string.format("TakePhotoCompetitionActivityObject:SyncActivityDataOnAvailable \232\175\183\230\177\130\230\180\187\229\138\168\230\149\176\230\141\174 id: %s", self:GetActivityId()))
  self:ReqGetPlayerActivityData()
end

function TakePhotoCompetitionActivityObject:GetActivityDesc()
  local pushNum = _G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_push_num").num
  return string.format(self.activityConf.activity_txt, pushNum)
end

function TakePhotoCompetitionActivityObject:GetCurrentPhaseConf()
  local activity_data = self:GetActivityData()
  if not activity_data or not activity_data.current_phase_id then
    return
  end
  local currentPhaseConf = _G.DataConfigManager:GetTakephotoCompetitionConf(activity_data.current_phase_id)
  if currentPhaseConf then
    return currentPhaseConf
  end
end

function TakePhotoCompetitionActivityObject:IsRestPhase()
  local currentPhaseConf = self:GetCurrentPhaseConf()
  if not currentPhaseConf then
    Log.Error("TakePhotoCompetitionActivityObject:IsRestPhase activity_data currentPhaseConf is nil")
    return false
  end
  return string.IsNilOrEmpty(currentPhaseConf.preparation_start_time)
end

function TakePhotoCompetitionActivityObject:GetCurrentStage()
  local currentPhaseConf = self:GetCurrentPhaseConf()
  if not currentPhaseConf then
    Log.Error("TakePhotoCompetitionActivityObject:GetCurrentStage currentPhaseConf is nil")
    return ActivityEnum.TakePhotoCompetitionStage.None
  end
  local currentTime = ActivityUtils.GetSvrTimestamp()
  local prepStartTime = ActivityUtils.ToTimestamp(currentPhaseConf.preparation_start_time)
  local prepEndTime = ActivityUtils.ToTimestamp(currentPhaseConf.preparation_end_time)
  if currentTime >= prepStartTime and currentTime < prepEndTime then
    return ActivityEnum.TakePhotoCompetitionStage.Preparation
  end
  local compStartTime = ActivityUtils.ToTimestamp(currentPhaseConf.competition_start_time)
  if currentTime >= prepEndTime and currentTime < compStartTime then
    return ActivityEnum.TakePhotoCompetitionStage.PhotoCheck
  end
  local compEndTime = ActivityUtils.ToTimestamp(currentPhaseConf.competition_end_time)
  if currentTime >= compStartTime and currentTime < compEndTime then
    return ActivityEnum.TakePhotoCompetitionStage.Competition
  end
  if currentTime >= compEndTime then
    return ActivityEnum.TakePhotoCompetitionStage.CurPhaseEnd
  end
end

function TakePhotoCompetitionActivityObject:ReqGetHotPhoto()
  local currentTime = ActivityUtils.GetSvrTimestamp()
  if self.hotPhotoTimeStamp == nil or currentTime - self.hotPhotoTimeStamp >= 120 then
    local reqMsg = _G.ProtoMessage:newZoneActivityPhotoContestHotReq()
    reqMsg.activity_id = self:GetActivityId()
    if self:IsRestPhase() then
      local totalPhases = self:GetPartIds()
      local randomPhaseIndex = math.random(1, #totalPhases - 1)
      reqMsg.activity_sub_id = totalPhases[randomPhaseIndex]
    else
      reqMsg.activity_sub_id = self:GetActivityData().current_phase_id
    end
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_HOT_REQ, reqMsg, self, self.OnActivityPhotoContestHotRsp, nil, false)
  else
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TakePhotoCompetitionActivityHotPhotoEvent)
  end
end

function TakePhotoCompetitionActivityObject:OnActivityPhotoContestHotRsp(rsp)
  self.hotPhotoRsp = rsp
  if 0 == rsp.ret_info.ret_code then
    if rsp.uin and 0 ~= rsp.uin then
      self.hotPhotoTimeStamp = ActivityUtils.GetSvrTimestamp()
    else
      Log.Info("TakePhotoCompetitionActivityObject:OnActivityPhotoContestHotRsp \229\189\147\229\137\141\230\151\160\231\131\173\233\151\168\231\133\167\231\137\135")
    end
  else
    Log.Info("TakePhotoCompetitionActivityObject:OnActivityPhotoContestHotRsp ret_code = ", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_3207)
  end
  _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TakePhotoCompetitionActivityHotPhotoEvent)
end

function TakePhotoCompetitionActivityObject:GetHotPhoto()
  return self.hotPhotoRsp
end

function TakePhotoCompetitionActivityObject:GetMySubmission(phase_id)
  local activity_data = self:GetActivityData()
  if not activity_data or not activity_data.phases then
    Log.Error("TakePhotoCompetitionActivityObject:GetMySubmission activity_data is nil or phases is nil")
    return
  end
  if activity_data and activity_data.phases then
    phase_id = phase_id or activity_data.current_phase_id
    for i, v in pairs(self.activity_data.phases) do
      if v.phase_id == phase_id then
        return v
      end
    end
  end
end

function TakePhotoCompetitionActivityObject:GetRankDataObject(rankId, isImageRank)
  isImageRank = isImageRank or false
  local rankDataObject = self.rankDataObjects[rankId]
  if not rankDataObject or rankDataObject:IsImage() ~= isImageRank then
    rankDataObject = RankDataHandler.CreateRankDataObject(_G.ProtoEnum.RankListType.RANK_LIST_TYPE_PHOTO_CONTEST, rankId, isImageRank, 50)
    self.rankDataObjects[rankId] = rankDataObject
  end
  return rankDataObject
end

function TakePhotoCompetitionActivityObject:GetPastPhases()
  return self.pastPhaseIds
end

function TakePhotoCompetitionActivityObject:ShowTakePhotoCompetitionActivityBanInfo(ban_info)
  if ban_info and ban_info.uin and ban_info.ban_reason then
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", ban_info.ban_time)
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = ban_info.uin
    local contentText = string.format(banConfig.str, uin, ban_time, ban_info.ban_reason)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contentText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function TakePhotoCompetitionActivityObject:GetPhotoEvaluationInfo(isSkipLike)
  local req = _G.ProtoMessage:newZoneActivityPhotoContestEvaluationReq()
  req.activity_id = self:GetActivityId()
  req.activity_sub_id = self:GetActivityData().current_phase_id
  req.skip_like = isSkipLike
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_EVALUATION_REQ, req, self, self.OnPhotoEvaluationInfoRsp, nil, false)
end

function TakePhotoCompetitionActivityObject:OnPhotoEvaluationInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
  else
    Log.Error("TakePhotoCompetitionActivityObject:OnPhotoEvaluationInfoRsp failed", rsp.ret_info.ret_code)
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TakePhotoCompetitionActivityVoteErrorEvent, rsp.ret_info.ret_code)
    if rsp.ban_info then
      self:ShowTakePhotoCompetitionActivityBanInfo(rsp.ban_info)
    end
  end
end

function TakePhotoCompetitionActivityObject:SendPlayerLike(playerId)
  local req = _G.ProtoMessage:newZoneActivityPhotoContestLikeReq()
  req.activity_id = self:GetActivityId()
  req.activity_sub_id = self:GetActivityData().current_phase_id
  req.like_photo_uin = playerId
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_LIKE_REQ, req, self, self.OnPlayerLikeRsp, nil, false)
end

function TakePhotoCompetitionActivityObject:OnPlayerLikeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
  else
    Log.Error("TakePhotoCompetitionActivityObject:OnPlayerLikeRsp failed", rsp.ret_info.ret_code)
    if rsp.ban_info then
      self:ShowTakePhotoCompetitionActivityBanInfo(rsp.ban_info)
    end
  end
end

function TakePhotoCompetitionActivityObject:OnUpdateActivityDataAccuracy(accuracy)
  if self.activity_data then
    self.activity_data.accuracy_score = accuracy
  end
end

function TakePhotoCompetitionActivityObject:OnUpdateActivityDataRecommendCount(recommendCount)
  if self.activity_data then
    self.activity_data.recommend_count = recommendCount
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TakePhotoCompetitionActivityUpdateRecommendCountEvent)
  end
end

function TakePhotoCompetitionActivityObject:SendTakeAccuracyReward(rewardList)
  local req = _G.ProtoMessage:newZoneActivityCommonRewardsReq()
  req.activity_id = self:GetActivityId()
  req.activity_sub_id = self:GetActivityData().current_phase_id
  req.params = {2}
  for _, rewardId in ipairs(rewardList) do
    table.insert(req.params, rewardId)
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ, req, self, self.OnTakeAccuracyRewardRsp, nil, false)
end

function TakePhotoCompetitionActivityObject:OnTakeAccuracyRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.params and #rsp.params >= 2 and 2 == rsp.params[1] and self.activity_data then
      if not self.activity_data.reward_ids then
        self.activity_data.reward_ids = {}
      end
      for i = 2, #rsp.params do
        table.insert(self.activity_data.reward_ids, rsp.params[i])
      end
      if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, table.deepCopy(rsp.ret_info.goods_reward.rewards))
      end
      _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.TakePhotoCompetitionActivityVoteRewardEvent)
    end
  else
    Log.Error("TakePhotoCompetitionActivityObject:OnTakeAccuracyRewardRsp failed", rsp.ret_info.ret_code)
  end
end

function TakePhotoCompetitionActivityObject:CheckSubmissionReward()
  Log.Info("TakePhotoCompetitionActivityObject:CheckSubmissionReward")
  if self.activity_data == nil then
    Log.Info("TakePhotoCompetitionActivityObject:CheckSubmissionReward activity_data = nil")
    return
  end
  for i = #self.activity_data.phases, 1, -1 do
    local phase = self.activity_data.phases[i]
    if phase.photo_url ~= "" and not phase.is_disposable_reward_taken then
      local phaseConf = _G.DataConfigManager:GetTakephotoCompetitionConf(phase.phase_id)
      if phaseConf then
        local endTime = ActivityUtils.ToTimestamp(phaseConf.end_time)
        local currentTime = ActivityUtils.GetSvrTimestamp()
        if endTime <= currentTime then
          _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdTakeReward, self:GetActivityId(), phase.phase_id, {1, 1}, function(bSuccess)
            if bSuccess then
            end
          end, true)
          break
        end
      end
    end
  end
end

function TakePhotoCompetitionActivityObject:OnActivityPhotoContestSubmitRewardNotify(rsp)
  if rsp and rsp.activity_sub_id and rsp.hot_value then
    local currPhase = self:GetMySubmission(rsp.activity_sub_id)
    if currPhase then
      currPhase.total_hot_count = rsp.hot_value
    end
  end
  _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionSubmissionReward, rsp)
end

return TakePhotoCompetitionActivityObject

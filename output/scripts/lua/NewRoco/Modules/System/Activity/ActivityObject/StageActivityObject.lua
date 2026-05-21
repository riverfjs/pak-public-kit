local Base = require("NewRoco.Modules.System.Activity.ActivityObject.RecallActivityObject")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local StageActivityObject = Base:Extend("StageActivityObject")

function StageActivityObject:OnConstruct(_conf)
  self.stageRewardsCfg = {}
  local partIds = self:GetPartIds()
  for _, partId in ipairs(partIds) do
    local stageCfg = _G.DataConfigManager:GetActivityRewardByStageConf(partId)
    table.insert(self.stageRewardsCfg, stageCfg or {})
  end
  self.stageStatus = {}
end

function StageActivityObject:GetStagePartId(_stage)
  local stageId, stageIndex
  local partIds = self:GetPartIds()
  if #partIds > 1 then
    stageId = partIds[_stage]
    stageIndex = 1
  else
    stageId = partIds[1]
    stageIndex = _stage
  end
  return stageId, stageIndex
end

function StageActivityObject:GetSignStages()
  local stageNum = #self.stageRewardsCfg
  if 1 == stageNum then
    local stageCfg = self.stageRewardsCfg[1]
    local rewardGroup = stageCfg.reward_group
    stageNum = rewardGroup and #rewardGroup or 0
  end
  if stageNum > 0 then
    local stages = table.new(stageNum, 0)
    for index = 1, stageNum do
      table.insert(stages, index)
    end
    return stages
  end
  return {}
end

function StageActivityObject:UpdateStageStatus(_stageId, _stageIndex, _rewardGet, _userOperation)
  local _stage
  local partIds = self:GetPartIds()
  if #partIds > 1 then
    for index, partId in ipairs(partIds) do
      if partId == _stageId then
        _stage = index
        break
      end
    end
  elseif partIds[1] == _stageId then
    _stage = _stageIndex
  end
  if _stage and self.stageStatus[_stage] ~= _rewardGet then
    self.stageStatus[_stage] = _rewardGet
    self:SendEvent(ActivityModuleEvent.StageRewardStatusChange, self, _stage, _rewardGet and ActivityEnum.RewardStatus.Received or ActivityEnum.RewardStatus.Available, _userOperation)
  end
end

function StageActivityObject:GetStageRewardStatus(_stage)
  local rewardGet = self.stageStatus[_stage]
  if nil ~= rewardGet then
    return rewardGet and ActivityEnum.RewardStatus.Received or ActivityEnum.RewardStatus.Available
  end
  return ActivityEnum.RewardStatus.UnAvailable
end

function StageActivityObject:GetStageRewardId(_stage, _multiRewards)
  local rewardsId = {}
  local stageDataList = self:GetStageData(_stage)
  if stageDataList then
    for _, stageData in ipairs(stageDataList) do
      table.insert(rewardsId, stageData.reward_id)
    end
  end
  return _multiRewards and rewardsId or rewardsId[1]
end

function StageActivityObject:GetStageRewardData(_stage, _multiRewards)
  local rewardsData = {}
  local stageDataList = self:GetStageData(_stage)
  if stageDataList then
    for _, stageData in ipairs(stageDataList) do
      local activityRewardData = ActivityUtils.GetActivityRewardData(stageData.reward_id, true)
      iconPath = activityRewardData.showIcon
      rewardNum = activityRewardData.itemNum
      rewardQuality = activityRewardData.itemQuality
      rewardItemType = activityRewardData.itemType
      rewardItemID = activityRewardData.itemId
      if not string.IsNilOrEmpty(stageData.lock_icon) and self:GetStageRewardStatus(_stage) == ActivityEnum.RewardStatus.UnAvailable then
        activityRewardData.showIcon = stageData.lock_icon
      end
      table.insert(rewardsData, activityRewardData)
    end
  end
  return _multiRewards and rewardsData or rewardsData[1]
end

function StageActivityObject:GetRewardRedPointData(_stage)
  local stageId, stageIndex = self:GetStagePartId(_stage)
  local RedPointKey
  if self:GetActivityBelongSystem() == _G.Enum.BelongSystem.BS_RECALL_ACTIVITY then
    RedPointKey = 475
  else
    RedPointKey = ActivityEnum.RedPointKey.DetailReward
  end
  return RedPointKey, {
    self:GetActivityId(),
    stageId,
    stageIndex
  }
end

function StageActivityObject:GetStageRewardsCfg(_stage)
  if _stage and #self.stageRewardsCfg > 1 then
    return self.stageRewardsCfg[_stage]
  else
    return self.stageRewardsCfg[1]
  end
end

function StageActivityObject:IsRewardExpired(_stage)
  local stageCfg = self:GetStageRewardsCfg(_stage)
  if not string.IsNilOrEmpty(stageCfg.end_time) then
    local serverTimestamp = ActivityUtils.GetSvrTimestamp()
    local endTimeStamp = ActivityUtils.ToTimestamp(stageCfg.end_time)
    if serverTimestamp > endTimeStamp then
      return true
    end
  end
  return false
end

function StageActivityObject:ExistsAvailableReward()
  for _, _rewardGet in ipairs(self.stageStatus) do
    if not _rewardGet then
      return true
    end
  end
  return false
end

function StageActivityObject:SyncActivityDataOnAvailable()
  Base.SyncActivityDataOnAvailable(self)
end

function StageActivityObject:GetActivityShowStatus()
  local stageCfg = self:GetStageRewardsCfg()
  if stageCfg and stageCfg.bIsRecallActivity then
    if not self.returnActivityData then
      return ActivityEnum.ActivityShowStatus.Disable_AdditionalCond
    elseif self.returnActivityData and not self.returnActivityData.active then
      return ActivityEnum.ActivityShowStatus.Disable_Expired
    else
      return Base.GetActivityShowStatus(self)
    end
  else
    return Base.GetActivityShowStatus(self)
  end
end

function StageActivityObject:GetActivityTimeLeft()
  local stageCfg = self:GetStageRewardsCfg()
  if stageCfg and stageCfg.bIsRecallActivity and self.returnActivityData then
    local svrTimeStamp = ActivityUtils.GetSvrTimestamp()
    local timeOpenStamp = self.returnActivityData.open_timestamp
    local timeOpenDetailData = ActivityUtils.ToTimeDetailData(timeOpenStamp)
    local timeCloseStamp
    if timeOpenDetailData.hour < 4 then
      timeCloseStamp = timeOpenStamp + 1209600
    else
      timeCloseStamp = timeOpenStamp + 1296000
    end
    timeCloseStamp = os.date("*t", timeCloseStamp)
    timeCloseStamp.hour = 4
    timeCloseStamp.min = 0
    timeCloseStamp.sec = 0
    timeCloseStamp = os.time(timeCloseStamp)
    if 0 == timeCloseStamp then
      return math.maxinteger
    end
    if Base.IsActivityInactive(self) then
      return 0
    end
    return math.max(timeCloseStamp - svrTimeStamp, 0)
  else
    return Base.GetActivityTimeLeft(self)
  end
end

function StageActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local _activityData = _updateData
    local stageData = _activityData and _activityData.stage_data
    if not stageData then
      Log.Error("something must be wrong. not valid stage_data for activity: ", _activityData and _activityData.activity_id)
      return
    end
    local stageCfg = self:GetStageRewardsCfg()
    if stageCfg and stageCfg.bIsRecallActivity then
      local subStageData = stageData.sub_stage_data and stageData.sub_stage_data[1]
      local isActive = false
      local isRewardTaken = false
      if subStageData then
        isActive = subStageData.active
        isRewardTaken = subStageData.is_disposable_reward_taken
      end
      if isActive and not isRewardTaken then
        _G.NRCModuleManager:DoCmd(TaskModuleCmd.CreateReturnRewardTips)
        self.returnActivityData = subStageData
      elseif isActive and isRewardTaken then
        self.returnActivityData = subStageData
      elseif not isActive then
        self.returnActivityData = subStageData
      end
    end
    if stageData.sub_stage_data then
      for _, _subStageData in ipairs(stageData.sub_stage_data) do
        for _, _rewardData in ipairs(_subStageData.reward_data or {}) do
          self:UpdateStageStatus(_subStageData.activity_stage_id, _rewardData.stage_index, _rewardData.is_reward_taken, false)
        end
      end
    end
  elseif _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_NEW_ACTIVITY_REWARD_NOTIFY then
    local _rewardData = _updateData
    if _rewardData then
      self:UpdateStageStatus(_rewardData.activity_stage_id, _rewardData.activity_reward_id, false, false)
    end
  end
end

function StageActivityObject:OnTryGetReward(_stage)
  local rewardStatus = self:GetStageRewardStatus(_stage)
  if rewardStatus == ActivityEnum.RewardStatus.Available then
    local stageId, stageIndex = self:GetStagePartId(_stage)
    local req = _G.ProtoMessage:newZoneReceivePlayerActivityStageRewardReq()
    req.activity_id = self:GetActivityId()
    req.activity_stage_id = stageId
    req.stage_index = {stageIndex}
    ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_STAGE_REWARD_REQ, req, self, self.OnZoneReceivePlayerActivityStageRewardRsp)
  end
  return rewardStatus
end

function StageActivityObject:OnReconnectFinish()
  if self.svrStatus == ActivityEnum.ActivitySvrStatus.Available then
    local stageCfg = self:GetStageRewardsCfg()
    if stageCfg and stageCfg.bIsRecallActivity then
      self:ReqGetPlayerActivityData()
      return true
    end
  end
  return Base.OnReconnectFinish(self)
end

function StageActivityObject:GetStageData(_stage)
  if #self:GetPartIds() > 1 then
    local stageCfg = _stage and self:GetStageRewardsCfg(_stage)
    return stageCfg and stageCfg.reward_group
  else
    local stageCfg = self:GetStageRewardsCfg()
    local rewardGroup = stageCfg and stageCfg.reward_group
    if rewardGroup then
      return _stage and {
        rewardGroup[_stage]
      }
    end
  end
end

function StageActivityObject:OnZoneReceivePlayerActivityStageRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if not _req or _req.activity_id ~= self:GetActivityId() then
    Log.Error("parameter error!")
    return
  end
  for _, _stageIndex in ipairs(_req.stage_index) do
    self:UpdateStageStatus(_req.activity_stage_id, _stageIndex, true, true)
  end
  ActivityUtils.ShowRewardGetTips(nil, _protoData.ret_info)
end

return StageActivityObject

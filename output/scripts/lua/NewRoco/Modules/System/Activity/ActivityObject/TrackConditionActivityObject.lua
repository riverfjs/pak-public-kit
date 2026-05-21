local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityConditionRewardHandler = require("NewRoco.Modules.System.Activity.ActivityObject.ConditionRewardHandler")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local TrackConditionActivityObject = Base:Extend("TrackConditionActivityObject")

function TrackConditionActivityObject:OnConstruct(_conf)
  self.trackConditionConf = _G.DataConfigManager:GetActivityTrackConditionConf(self:GetSinglePartId())
  if self.trackConditionConf and self.trackConditionConf.stage_reward_group_id and self.trackConditionConf.stage_reward_group_id > 0 then
    self.stageRewardConfList = {}
    local groupConf = _G.DataConfigManager:GetAllByName("ACTIVITY_STAGE_REWARD_CONF")
    for base_id, conf in pairs(groupConf) do
      if conf.group_id == self.trackConditionConf.stage_reward_group_id then
        table.insert(self.stageRewardConfList, conf)
      end
    end
    table.sort(self.stageRewardConfList, function(a, b)
      return a.id < b.id
    end)
    self.SeasonCheckinConf = self.stageRewardConfList and self.stageRewardConfList[1]
  end
  self.receivedRewardsIndex = {}
  self.conditionRewardMap = {}
  local partIds = self:GetConditionIdList()
  if partIds and #partIds > 0 then
    for _, partId in pairs(partIds) do
      local itemObject = ActivityConditionRewardHandler.CreateConditionRewardItemObject(self, _G.DataConfigManager:GetActivityConditionRewardConf(partId))
      self.conditionRewardMap[partId] = itemObject
    end
  end
end

function TrackConditionActivityObject:GetPetBaseId()
  return self.trackConditionConf and self.trackConditionConf.petbase_id
end

function TrackConditionActivityObject:GetBtnText()
  return self.trackConditionConf and self.trackConditionConf.option_txt
end

function TrackConditionActivityObject:GetTrackType()
  return self.trackConditionConf and self.trackConditionConf.track_type
end

function TrackConditionActivityObject:GetTrackParam()
  return self.trackConditionConf and self.trackConditionConf.track_type_param1 and self.trackConditionConf.track_type_param1[1]
end

function TrackConditionActivityObject:GetConditionIdList()
  local condition_id = {}
  if self.trackConditionConf and self.trackConditionConf.star_rewards then
    for i, v in ipairs(self.trackConditionConf.star_rewards) do
      if v.condition_reward_id then
        table.insert(condition_id, v.condition_reward_id)
      end
    end
  end
  return condition_id
end

function TrackConditionActivityObject:GetItemObjectMap()
  return self.conditionRewardMap
end

function TrackConditionActivityObject:GetRewardItem(_partId)
  return self.conditionRewardMap[_partId]
end

function TrackConditionActivityObject:IsLotteryTimeOpen()
  if not (self.trackConditionConf and self.trackConditionConf.option_open_time) or 0 == self.trackConditionConf.option_open_time then
    return false
  end
  local srvTime = ActivityUtils.GetSvrTimestamp()
  local openTime = ActivityUtils.ToTimestamp(self.trackConditionConf.option_open_time)
  return srvTime >= openTime
end

function TrackConditionActivityObject:GetLotteryCloseText()
  return self.trackConditionConf and self.trackConditionConf.unopen_option_txt
end

function TrackConditionActivityObject:GetLotteryState()
  if self.svrActivityData and self.svrActivityData.lottery_result then
    return self.svrActivityData.lottery_result
  end
  return 0
end

function TrackConditionActivityObject:GetActivityRewardsIndex()
  local received_rewards_index = {}
  for index, RewardConfList in ipairs(self.stageRewardConfList) do
    for i, v in ipairs(self.receivedRewardsIndex) do
      if v == RewardConfList.id then
        table.insert(received_rewards_index, index)
        break
      end
    end
  end
  return received_rewards_index
end

function TrackConditionActivityObject:OnRewardItemStatusChange(_itemObj, _userOperation)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.TrackConditionRewardItemProgressChange, self, _itemObj)
  end
end

function TrackConditionActivityObject:OnRewardItemProgressChange(_itemObj)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.TrackConditionRewardItemProgressChange, self, _itemObj)
  end
end

function TrackConditionActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.svrActivityData = _updateData
    Log.Dump(_updateData, 6, "TrackConditionActivityObject:OnSvrUpdateActivityData")
    local _activityData = _updateData
    local partData = _activityData.part_data
    self.season_checkin_data = _activityData.score_reward_comp_data
    self.task_data = _activityData.part_data
    self.activity_open_time = _activityData.activity_open_time
    if _activityData.score_reward_comp_data and _activityData.score_reward_comp_data.reward_data then
      self:SendEvent(ActivityModuleEvent.RefreshSeasonSignData, self, true)
      local received_rewards_index = {}
      for i, v in ipairs(_activityData.score_reward_comp_data.reward_data) do
        if v.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          for index, RewardConfList in ipairs(self.stageRewardConfList) do
            if RewardConfList.id == v.activity_rewards_index then
              table.insert(received_rewards_index, index - 1)
            end
          end
        end
      end
      self:UpdateReceivedRewardsIndex(received_rewards_index, false, nil)
    end
    if partData then
      for _, _partDataEntry in ipairs(partData) do
        local _itemObj = self:GetRewardItem(_partDataEntry.activity_part_id)
        if _itemObj then
          if _partDataEntry.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
            _itemObj:SetCompleted(false)
          elseif _partDataEntry.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
            _itemObj:SetRewardReceived(false)
          else
            _itemObj:ResetStatus()
          end
        end
      end
    end
  elseif _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_ADD_PLAYER_ACTIVITY_PART_REWARD_NTY then
    local _partId = _updateData
    local itemObj = self:GetRewardItem(_partId)
    if itemObj then
      itemObj:SetCompleted(true)
    end
  end
end

function TrackConditionActivityObject:OnTryGetReward(_itemObj)
  if _itemObj then
    local rewardStatus = _itemObj:GetRewardStatus()
    if rewardStatus == ActivityEnum.RewardStatus.Available then
      local req = _G.ProtoMessage:newZoneReceivePlayerActivityConditionRewardReq()
      req.activity_id = self:GetActivityId()
      req.activity_part_id = _itemObj:GetRewardItemId()
      ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_CONDITION_REWARD_REQ, req, self, self.OnZoneReceivePlayerActivityConditionRewardRsp)
    end
    return rewardStatus
  end
end

function TrackConditionActivityObject:OnZoneReceivePlayerActivityConditionRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if not _req or _req.activity_id ~= self:GetActivityId() then
    Log.Error("parameter error!")
    return
  end
  local itemObj = self:GetRewardItem(_req.activity_part_id)
  if itemObj then
    itemObj:SetRewardReceived(true)
    local rewardGroup = itemObj:GetRewardGroup()
    if rewardGroup then
      local rewardsList = {}
      for _, rewardItem in ipairs(rewardGroup) do
        local activityRewardData = ActivityUtils.ParseActivityRewardData(rewardItem.goods_type, rewardItem.goods_id, rewardItem.goods_count)
        local rewardsItemData = {}
        rewardsItemData.type = activityRewardData.itemType
        rewardsItemData.id = activityRewardData.itemId
        rewardsItemData.num = activityRewardData.itemNum
        table.insert(rewardsList, rewardsItemData)
      end
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardsList, "")
    end
  else
    Log.Error("Can not find reward item: part_id=", _req.activity_part_id)
  end
end

function TrackConditionActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function TrackConditionActivityObject:IsRewardGet(pointIndex)
  return table.contains(self.receivedRewardsIndex, pointIndex)
end

function TrackConditionActivityObject:GetPoints()
  local SeasonCheckinConf = self.stageRewardConfList and self.stageRewardConfList[1]
  local curNum = 0
  if SeasonCheckinConf then
    if SeasonCheckinConf.change_goods_type == Enum.GoodsType.GT_VITEM then
      curNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(SeasonCheckinConf.change_goods_id)
    elseif SeasonCheckinConf.change_goods_type == Enum.GoodsType.GT_BAGITEM then
      local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, SeasonCheckinConf.change_goods_id)
      curNum = BagItem and BagItem.num or 0
    end
  end
  return curNum
end

function TrackConditionActivityObject:GetPointsRewards()
  return self.stageRewardConfList
end

function TrackConditionActivityObject:GetPointsMax()
  local targetNum = 0
  local reward_group = self.stageRewardConfList
  for i, v in ipairs(reward_group) do
    if v.points_condition and v.points_condition > 0 and targetNum < v.points_condition then
      targetNum = v.points_condition
    end
  end
  return targetNum
end

function TrackConditionActivityObject:ReqGetRewards(pointIndexGroup)
  if not pointIndexGroup or #pointIndexGroup <= 0 then
    return
  end
  if self:IsActivityInactive() then
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  local received_rewards_index = {}
  for index, RewardConfList in ipairs(self.stageRewardConfList) do
    for i, v in ipairs(pointIndexGroup) do
      if v == index - 1 then
        table.insert(received_rewards_index, RewardConfList.id)
        break
      end
    end
  end
  local req = _G.ProtoMessage:newZoneReceivePlayerActivitySeasonCheckinRewardReq()
  req.activity_id = self:GetActivityId()
  req.activity_reward_indexs = received_rewards_index
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_SEASON_CHECKIN_REWARD_REQ, req, self, self.OnZoneReceivePlayerActivityPetCatchRewardRsp)
end

function TrackConditionActivityObject:OnZoneReceivePlayerActivityPetCatchRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if not _req or _req.activity_id ~= self:GetActivityId() then
    Log.ErrorFormat("parameter error! req[%d] != cur[%d]", _req and _req.activity_id or 0, self:GetActivityId())
    return
  end
  local received_rewards_index = {}
  for index, RewardConfList in ipairs(self.stageRewardConfList) do
    for i, v in ipairs(_req.activity_reward_indexs) do
      if v == RewardConfList.id then
        table.insert(received_rewards_index, index - 1)
        break
      end
    end
  end
  self:UpdateReceivedRewardsIndex(received_rewards_index, true, _protoData)
end

function TrackConditionActivityObject:UpdateReceivedRewardsIndex(_receivedRewardsIndex, _userOperation, _protoData)
  if not _receivedRewardsIndex then
    return
  end
  for _, _index in ipairs(_receivedRewardsIndex) do
    if not table.contains(self.receivedRewardsIndex, _index) then
      table.insert(self.receivedRewardsIndex, _index)
    end
  end
  self:SendEvent(ActivityModuleEvent.RefreshReceivePetCatchRewards, self, _receivedRewardsIndex, _userOperation, _protoData)
end

return TrackConditionActivityObject

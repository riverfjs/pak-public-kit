local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local LimitTimeAppearActivityObject = Base:Extend("CommonShowActivityObject")
local ActivityConditionRewardHandler = require("NewRoco.Modules.System.Activity.ActivityObject.ConditionRewardHandler")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function LimitTimeAppearActivityObject:OnConstruct(_conf)
  self.limitTimeAppearConf = _G.DataConfigManager:GetActLimittimeAppear(self:GetSinglePartId())
  self.rewardItemMap = {}
  local conditionIds = self:GetConditionIds()
  if conditionIds then
    for j, v in ipairs(conditionIds) do
      local itemObject = ActivityConditionRewardHandler.CreateConditionRewardItemObject(self, _G.DataConfigManager:GetActivityConditionRewardConf(v))
      self.rewardItemMap[v] = itemObject
    end
  end
end

function LimitTimeAppearActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local _activityData = _updateData
    self.partData = _activityData.part_data
    self:SendEvent(ActivityModuleEvent.RefreshLimitTimeAppearActivityData, self:GetActivityId(), self.partData)
  end
end

function LimitTimeAppearActivityObject:GetPetBaseId()
  return self.limitTimeAppearConf and self.limitTimeAppearConf.petbase_id
end

function LimitTimeAppearActivityObject:GetTrackConditions()
  return self.limitTimeAppearConf and self.limitTimeAppearConf.condition_group
end

function LimitTimeAppearActivityObject:GetTrackTypeAndParams()
  if self.limitTimeAppearConf then
    return self.limitTimeAppearConf.track_type, self.limitTimeAppearConf.track_type_param1
  end
end

function LimitTimeAppearActivityObject:GetTrackContentIds()
  return self.limitTimeAppearConf and self.limitTimeAppearConf.track_refresh_id_priority
end

function LimitTimeAppearActivityObject:GetConditionIds()
  return self.limitTimeAppearConf and self.limitTimeAppearConf.condition_id
end

function LimitTimeAppearActivityObject:GetActivityConf()
  return self.limitTimeAppearConf
end

function LimitTimeAppearActivityObject:GetConditionProgress(conditionId)
  if self.rewardItemMap[conditionId] then
    return self.rewardItemMap[conditionId]:GetProgress()
  end
  return nil
end

function LimitTimeAppearActivityObject:GetConditionState(conditionId)
  if self.partData then
    for i, v in ipairs(self.partData) do
      if v.activity_part_id == conditionId then
        return v.state
      end
    end
  end
  return nil
end

function LimitTimeAppearActivityObject:CanGetReward()
  if not self:IsInProgress() then
    return false
  end
  local ids = self:GetConditionIds()
  if ids then
    for i, v in ipairs(ids) do
      local state = self:GetConditionState(v)
      if state and state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
        return true
      end
    end
  end
  return false
end

function LimitTimeAppearActivityObject:GetReward(conditionId)
  local req = _G.ProtoMessage:newZoneReceivePlayerActivityPartRewardReq()
  req.activity_id = self:GetActivityId()
  req.activity_part_id = conditionId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_PART_REWARD_REQ, req, self, self.OnGetRewardResponse)
end

function LimitTimeAppearActivityObject:OnGetRewardResponse(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:ReqGetPlayerActivityData()
    if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rsp.ret_info.goods_reward.rewards)
    end
  end
end

function LimitTimeAppearActivityObject:RefreshAllConditionProgress()
  if self.rewardItemMap then
    for i, v in pairs(self.rewardItemMap) do
      v:UpdateProgress()
    end
  end
end

return LimitTimeAppearActivityObject

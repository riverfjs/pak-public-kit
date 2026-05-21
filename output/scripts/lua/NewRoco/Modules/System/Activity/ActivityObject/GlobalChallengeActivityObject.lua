local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local GlobalChallengeActivityObject = Base:Extend("GlobalChallengeActivityObject")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function GlobalChallengeActivityObject:OnConstruct(_conf)
  self.signRewardData = nil
  self.globalChallengeData = {}
end

function GlobalChallengeActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.globalChallengeData = _updateData.global_challenge_data.challenge_progress[1]
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.GlobalChallengeActivityDataRefresh)
  end
end

function GlobalChallengeActivityObject:GetGlobalChallengeData()
  return self.globalChallengeData
end

function GlobalChallengeActivityObject:GetSinglePartStatus(partId)
  local curProgress = self:GetCurProgress()
  local conf = _G.DataConfigManager:GetActivityGlobalChallenge(partId)
  if conf and curProgress >= conf.require_count then
    local globalChallengeData = self:GetGlobalChallengeData()
    if globalChallengeData and globalChallengeData.received_challenge_ids and #globalChallengeData.received_challenge_ids > 0 then
      for k, v in ipairs(globalChallengeData.received_challenge_ids) do
        if v == partId then
          return ActivityEnum.RewardStatus.Received
        end
      end
    end
    return ActivityEnum.RewardStatus.Available
  end
  return ActivityEnum.RewardStatus.UnAvailable
end

function GlobalChallengeActivityObject:GetShowPartConf()
  local partIds = self:GetPartIds()
  if partIds and #partIds then
    for i, v in ipairs(partIds) do
      local conf = _G.DataConfigManager:GetActivityGlobalChallenge(v)
      if conf and conf.is_show_count then
        return conf
      end
    end
  end
  return nil
end

function GlobalChallengeActivityObject:GetCurProgress()
  if self.globalChallengeData then
    return self.globalChallengeData.progress or 0
  end
  return 0
end

function GlobalChallengeActivityObject:HaveCanGetReward()
  for i, v in ipairs(self:GetPartIds()) do
    if self:GetSinglePartStatus(v) == ActivityEnum.RewardStatus.Available then
      return true
    end
  end
  return false
end

function GlobalChallengeActivityObject:GetReward(partId)
  local req = _G.ProtoMessage:newZoneActivityCommonRewardsReq()
  req.activity_id = self:GetActivityId()
  req.activity_sub_id = partId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ, req, self, self.OnGetRewardResponse)
end

function GlobalChallengeActivityObject:OnGetRewardResponse(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  self:ReqGetPlayerActivityData()
  _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.GlobalChallengeActivityGetReward)
  if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, table.deepCopy(rsp.ret_info.goods_reward.rewards))
  end
end

return GlobalChallengeActivityObject

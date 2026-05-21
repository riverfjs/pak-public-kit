local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local PeriodicLoginActivityObject = Base:Extend("PeriodicLoginActivityObject")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function PeriodicLoginActivityObject:OnConstruct(_conf)
  self.signRewardData = nil
end

function PeriodicLoginActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.signRewardData = _updateData.sign_reward_data
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.PeriodicLoginActivityDataRefresh)
  end
end

function PeriodicLoginActivityObject:CanGetReward()
  if self.signRewardData then
    return self.signRewardData.reward_obtainable or false, self.signRewardData.next_refresh_time or 0
  end
  return false, 0
end

function PeriodicLoginActivityObject:GetReward()
  local req = _G.ProtoMessage:newZoneActivityCommonRewardsReq()
  req.activity_id = self:GetActivityId()
  req.activity_sub_id = self:GetSinglePartId()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ, req, self, self.OnGetRewardResponse)
end

function PeriodicLoginActivityObject:OnGetRewardResponse(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.PeriodicLoginActivityGetReward)
  if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, table.deepCopy(rsp.ret_info.goods_reward.rewards))
  end
end

return PeriodicLoginActivityObject

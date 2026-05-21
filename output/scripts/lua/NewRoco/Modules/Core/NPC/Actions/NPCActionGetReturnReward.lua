local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local NPCActionGetReturnReward = Base:Extend("NPCActionGetReturnReward")

function NPCActionGetReturnReward:ExecuteWithModel()
  local activityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
  if activityObjects and #activityObjects > 0 then
    local activityObject
    for _, object in ipairs(activityObjects) do
      local recall_data = object:GetActivityData()
      if recall_data and recall_data.active then
        activityObject = object
        break
      end
    end
    if activityObject then
      local req = _G.ProtoMessage:newZoneReceivePlayerActivityDisposableRewardReq()
      req.activity_id = activityObject:GetActivityId()
      req.activity_stage_id = activityObject:GetSinglePartId()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_DISPOSABLE_REWARD_REQ, req, self, self.GetReward)
    end
  end
end

function NPCActionGetReturnReward:GetReward(rsp)
  if 0 == rsp.ret_info.ret_code then
    local activityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
    if activityObjects and #activityObjects > 0 then
      local activityObject
      for _, object in ipairs(activityObjects) do
        local recall_data = object:GetActivityData()
        if recall_data and recall_data.active then
          activityObject = object
          break
        end
      end
      if activityObject then
        local recall_class = activityObject:GetActivityData().recall_class
        local reward_id = _G.DataConfigManager:GetActivityRecallClassConf(recall_class).disposable_reward_id
        local rewardData = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem
        local popupInitData = {}
        for i = 1, #rewardData do
          local popupData = _G.ProtoMessage:newGoodsItem()
          popupData.id = rewardData[i].Id
          popupData.num = rewardData[i].Count
          popupData.type = rewardData[i].Type
          table.insert(popupInitData, popupData)
        end
        local commonPopUpData = _G.NRCCommonPopUpData()
        commonPopUpData.Call = self
        commonPopUpData.ClosePanelHandler = self.Finish
        commonPopUpData.HideBtn = true
        _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData, nil, nil, nil, nil, nil, nil, commonPopUpData)
      end
    end
  else
    self:Finish(false)
  end
end

return NPCActionGetReturnReward

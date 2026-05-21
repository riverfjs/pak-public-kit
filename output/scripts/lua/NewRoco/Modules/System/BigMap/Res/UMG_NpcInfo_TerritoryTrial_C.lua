local UMG_NpcInfo_TerritoryTrial_C = _G.NRCPanelBase:Extend("UMG_NpcInfo_TerritoryTrial_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_NpcInfo_TerritoryTrial_C:OnActive()
  self.NRCText_60:SetText(_G.LuaText.territory_trial_tips1)
  self.NRCText_2:SetText(_G.LuaText.territory_trial_tips2)
end

function UMG_NpcInfo_TerritoryTrial_C:OnEnable(props)
  self.NRCText:SetText(props.highest_score or _G.LuaText.territory_trial_battle_tips7)
  self.NRCText_1:SetText(props.least_finish_round and string.format(_G.LuaText.territory_trial_tips3, props.least_finish_round) or _G.LuaText.territory_trial_battle_tips7)
  if props.base_id then
    local territoryTrialConf = _G.DataConfigManager:GetTerritoryTrialConf(props.base_id)
    local trialChallengeConf = _G.DataConfigManager:GetTerritoryTrialChallengeConf(territoryTrialConf.challenge_id[1])
    local bossConf = _G.DataConfigManager:GetMonsterConf(trialChallengeConf.boss)
    self.npcName_5:SetText(territoryTrialConf.topic)
    self.PetIcon:SetIconPathAndMaterial(bossConf.base_id)
    self.PetName:SetText(trialChallengeConf.topic)
    local rewardData = {}
    if territoryTrialConf.play_reward and 0 ~= territoryTrialConf.play_reward then
      local rewardItems = _G.DataConfigManager:GetRewardConf(territoryTrialConf.play_reward).RewardItem
      for _, v in ipairs(rewardItems) do
        local item = _G.NRCCommonItemIconData()
        item.itemType = v.Type
        item.itemId = v.Id
        item.itemNum = v.Count
        item.bShowNum = true
        _, item.quality = ActivityUtils.GetItemIconAndQuality(v.Type, v.Id)
        table.insert(rewardData, item)
      end
    end
    for _, v in ipairs(territoryTrialConf.point_reward) do
      rewardItems = _G.DataConfigManager:GetRewardConf(v.reward).RewardItem
      for _, reward in ipairs(rewardItems) do
        for _, item in ipairs(rewardData) do
          if item.itemType == reward.Type and item.itemId == reward.Id then
            item.itemNum = item.itemNum + reward.Count
            goto lbl_158
          end
        end
        local item = _G.NRCCommonItemIconData()
        item.itemType = reward.Type
        item.itemId = reward.Id
        item.itemNum = reward.Count
        item.bShowNum = true
        _, item.quality = ActivityUtils.GetItemIconAndQuality(reward.Type, reward.Id)
        table.insert(rewardData, item)
        ::lbl_158::
      end
    end
    table.sort(rewardData, function(a, b)
      return a.quality > b.quality
    end)
    local initData = {}
    if #rewardData > 3 then
      for i = 1, 3 do
        table.insert(initData, rewardData[i])
      end
    else
      initData = rewardData
    end
    self.TaskAwardList:InitGridView(initData)
  end
  if props.desc then
    self.TaskDesc:SetText(props.desc)
  end
end

function UMG_NpcInfo_TerritoryTrial_C:SetCloseTimestamp(closeTimestamp)
  self.closeTimestamp = closeTimestamp
  self:TickActivityLeftTime()
end

function UMG_NpcInfo_TerritoryTrial_C:TickActivityLeftTime()
  local serverTimestamp = ActivityUtils.GetSvrTimestamp()
  local leftTime = self.closeTimestamp - serverTimestamp
  self.Text_Time:SetText(ActivityUtils.GetTimeFormatStr(math.max(leftTime, 0)))
  if leftTime > 0 then
    self.UpdateActivityLeftTimeId = _G.DelayManager:DelaySeconds(math.min(leftTime, 60), self.TickActivityLeftTime, self)
  end
end

function UMG_NpcInfo_TerritoryTrial_C:OnDisable()
  if self.UpdateActivityLeftTimeId then
    _G.DelayManager:CancelDelayById(self.UpdateActivityLeftTimeId)
  end
end

return UMG_NpcInfo_TerritoryTrial_C

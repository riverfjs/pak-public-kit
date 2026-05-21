local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_TakePhotoCompetition_RewardPreview_Item_C = Base:Extend("UMG_Activity_TakePhotoCompetition_RewardPreview_Item_C")

function UMG_Activity_TakePhotoCompetition_RewardPreview_Item_C:OnConstruct()
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  local rewardId
  if 1 == _data.tabIndex then
    local contestantReward = _data.reward
    rewardId = contestantReward.reward_id
    self.Title:SetText(contestantReward.list)
    self.SubTitle:SetText(contestantReward.desc)
    if contestantReward.is_percent or contestantReward.rank_min >= 4 then
      self.ImgSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.ImgSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ImgSwitcher:SetActiveWidgetIndex(contestantReward.rank_min - 1)
    end
  elseif 2 == _data.tabIndex then
    local judgeReward = _data.reward
    rewardId = judgeReward.reward_id
    self.Title:SetText(LuaText.pic_game_accuracy_reward_list .. judgeReward.accuracy_max)
    self.SubTitle:SetText("")
    self.ImgSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if rewardId and 0 ~= rewardId then
    local rewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
    if rewardConf then
      local rewards = rewardConf.RewardItem
      local itemList = {}
      for i = 1, #rewards do
        local itemQuality
        local itemId = rewards[i].Id
        local itemType = rewards[i].Type
        if itemType == ProtoEnum.GoodsType.GT_BAGITEM then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
          if bagItemConf then
            itemQuality = bagItemConf.item_quality
          end
        elseif itemType == ProtoEnum.GoodsType.GT_VITEM then
          local visualItemConf = _G.DataConfigManager:GetVisualItemConf(itemId)
          if visualItemConf then
            itemQuality = visualItemConf.item_quality
          end
        end
        table.insert(itemList, {
          itemId = itemId,
          itemType = rewards[i].Type,
          itemNum = rewards[i].Count,
          bShowNum = true,
          itemQuality = itemQuality,
          index = i
        })
      end
      table.sort(itemList, function(a, b)
        if a.itemQuality == b.itemQuality then
          return a.index < b.index
        else
          return a.itemQuality > b.itemQuality
        end
      end)
      self.NRCGridView_Reward:InitGridView(itemList)
    end
  end
end

return UMG_Activity_TakePhotoCompetition_RewardPreview_Item_C

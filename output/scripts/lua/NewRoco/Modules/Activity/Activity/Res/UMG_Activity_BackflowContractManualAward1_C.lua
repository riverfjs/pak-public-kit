local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_BackflowContractManualAward1_C = Base:Extend("UMG_Activity_BackflowContractManualAward1_C")

function UMG_Activity_BackflowContractManualAward1_C:OnConstruct()
end

function UMG_Activity_BackflowContractManualAward1_C:OnDestruct()
end

function UMG_Activity_BackflowContractManualAward1_C:OnItemUpdate(_data, datalist, index)
  self.Text_Class:SetText(_data.bp_level)
  local rewardItem = _G.DataConfigManager:GetRewardConf(_data.reward_id).RewardItem[1]
  local rewardData = {
    {
      itemCount = rewardItem.Count,
      itemType = rewardItem.Type,
      itemId = rewardItem.Id,
      state = _data.state,
      activity_id = _data.activity_id,
      bp_level = _data.bp_level,
      item_index = 1,
      bStageScroll = -1 == index
    }
  }
  self.Icon:InitGridView(rewardData)
  if 0 ~= _data.reward_id2 then
    self.CanvasAdvance:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local rewardItem2 = _G.DataConfigManager:GetRewardConf(_data.reward_id2).RewardItem[1]
    local rewardData2 = {
      {
        itemCount = rewardItem2.Count,
        itemType = rewardItem2.Type,
        itemId = rewardItem2.Id,
        state = _data.state2,
        activity_id = _data.activity_id,
        bp_level = _data.bp_level,
        item_index = 2,
        bStageScroll = -1 == index
      }
    }
    self.Icon_Advance:InitGridView(rewardData2)
  end
  if _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE and (0 == _data.reward_id2 or _data.state2 == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE) then
    if self.TopMask:GetVisibility() == UE4.ESlateVisibility.Collapsed and -1 ~= index then
      self.TopMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Reward_get)
    else
      self.TopMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.TopMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _data.is_paid then
    self.CanvasAdvance1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if not _data.is_paid2 then
    self.Advance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Activity_BackflowContractManualAward1_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C = Base:Extend("UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C")

function UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C:OnConstruct()
  self:AddButtonListener(self.UMG_Btn6.btnLevelUp, self.OnRewardBtnClick)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C:OnDestruct()
  self:RemoveAllButtonListener()
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.Title:SetText(LuaText.pic_game_accuracy_reward_list)
  self.RankText:SetText(string.format("%d/%d", math.min(_data.currAccuracy, _data.totalAccuracy), _data.totalAccuracy))
  if _data.isReceived then
    self.NRCSwitcher_93:SetActiveWidgetIndex(2)
    self.RankMarker:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif _data.currAccuracy < _data.totalAccuracy then
    self.NRCSwitcher_93:SetActiveWidgetIndex(0)
    self.TaskProgress:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TaskProgress:SetText(LuaText.task_in_progress)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCSwitcher_93:SetActiveWidgetIndex(1)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.data.activityInst then
    local activityData = self.data.activityInst:GetActivityData()
    local current_phase_id = activityData and activityData.current_phase_id or 0
    self.UMG_Btn6.RedDot:SetupKey(215, {
      self.data.activityInst:GetActivityId(),
      current_phase_id,
      self.data.id
    })
  end
  self.NRCGridView_98:InitGridView(_data.rewardItems)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C:OnItemSelected(_bSelected)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C:OnDeactive()
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C:OnRewardBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnClose")
  if self.data and self.data.parentPanel then
    self.data.parentPanel:OnRewardBtnClick(self.data.id)
  end
end

return UMG_Activity_TakePhotoCompetition_ClaimReward_Item_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_NoviceAchievement_Item1_C = Base:Extend("UMG_Activity_NoviceAchievement_Item1_C")

function UMG_Activity_NoviceAchievement_Item1_C:OnConstruct()
  self.ButtonClaim.OnClicked:Add(self, self.OnButtonClaimClick)
end

function UMG_Activity_NoviceAchievement_Item1_C:OnDestruct()
end

function UMG_Activity_NoviceAchievement_Item1_C:OnItemUpdate(_data, datalist, index)
  if not _data then
    Log.Error("UMG_Activity_NoviceAchievement_Item1_C:OnItemUpdate _data is nil")
    return
  end
  local bPlayGetAnim = false
  self.reward = _data
  local parentCustomData = self:GetParentCustomData()
  if parentCustomData then
    if self.bigRewardState and self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT and parentCustomData.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
      bPlayGetAnim = true
    end
    self.activityInst = parentCustomData.activityInst
    self.bigRewardState = parentCustomData.bigRewardState
  end
  self.ListItemIcon:OnItemUpdate(_data, nil, 1)
  self.redPointNew:ShowRedPoint(self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT)
  self.Completed:SetVisibility(self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.lingqu:SetVisibility(self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Completed:SetRenderOpacity(self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE and 1 or 0)
  self:StopAllAnimations()
  if self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    self:PlayAnimation(self.Reward_ready_loop)
  elseif self.bigRewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
    if bPlayGetAnim then
      self:PlayAnimation(self.Reward_get)
    end
  else
    self:PlayAnimation(self.In)
  end
end

function UMG_Activity_NoviceAchievement_Item1_C:OnButtonClaimClick()
  if self.activityInst and self.activityInst.condGroupData and self.activityInst.condGroupData.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    self.activityInst:GetReward()
  elseif self.reward then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, self.reward.itemId, self.reward.itemType)
  end
end

function UMG_Activity_NoviceAchievement_Item1_C:OnItemSelected(_bSelected)
end

function UMG_Activity_NoviceAchievement_Item1_C:OnDeactive()
end

function UMG_Activity_NoviceAchievement_Item1_C:OnAnimationFinished(Anim)
  if Anim == self.Reward_ready_loop then
    self:PlayAnimation(self.Reward_ready_loop)
  end
end

return UMG_Activity_NoviceAchievement_Item1_C

local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Activity_ElfParadiseRewards_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfParadiseRewards_C")

function UMG_Activity_ElfParadiseRewards_C:OnActive()
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    self.activityInst = PetTripActivityInst[1]
  end
  if self.activityInst then
    self.activityData = self.activityInst:GetActivityData()
    self:UpdateUI()
  else
    self:DoClose()
    return
  end
  self:OnAddEventListener()
end

function UMG_Activity_ElfParadiseRewards_C:UpdateUI()
  if self.activityData.lottery_result then
    if self.activityData.lottery_result.recieved_award then
      self.ReceiveReward:SetBtnText(LuaText.general_confirm)
      self.btnCloseRenamePanel:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ReceiveReward:SetBtnText(LuaText.Role_Award_Lv_Conform)
      self.btnCloseRenamePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local index = self.activityData.lottery_result.result > 4 and 4 or self.activityData.lottery_result.result
    self.RewardIndex = index - 1
    self.NRCSwitcher_BG:SetActiveWidgetIndex(index - 1)
    self.Switcher_Ribbons:SetActiveWidgetIndex(index - 1)
    self.Switch_Status:SetActiveWidgetIndex(index - 1)
    local icon, quality, name = UIUtils.GetIconAndQualityByItemIDAndItemType(self.activityData.lottery_result.goods_id, self.activityData.lottery_result.goods_type)
    local reward = self.activityInst:GetPetTripAwardConf()
    local rewardConf = reward and reward.condition_group and reward.condition_group[self.activityData.lottery_result.result]
    self.TextDesc:SetText(rewardConf and rewardConf.goods_describe)
    self.Icon:SetPath(icon)
    if self["Name" .. index] then
      self["Name" .. index]:SetText(rewardConf.goods_name)
    end
    if self["Text0" .. index] then
      self["Text0" .. index]:SetText(rewardConf.goods_tag)
    end
    if 0 == self.RewardIndex then
      self:PlayAnimation(self.XianDing_In)
    elseif 1 == self.RewardIndex then
      self:PlayAnimation(self.JingXi_In)
    elseif 2 == self.RewardIndex then
      self:PlayAnimation(self.JiNian_In)
    elseif 3 == self.RewardIndex then
      self:PlayAnimation(self.Anwei_In)
    else
      self:PlayAnimation(self.JiNian_In)
    end
    _G.NRCAudioManager:PlaySound2DAuto(40006007, "UMG_Activity_ElfParadiseRewards_C:UpdateUI")
  end
end

function UMG_Activity_ElfParadiseRewards_C:OnDeactive()
end

function UMG_Activity_ElfParadiseRewards_C:ItemButtonClick()
  UIUtils.OpenItemTipsByItemIDAndItemType(self.activityData.lottery_result.goods_id, self.activityData.lottery_result.goods_type)
end

function UMG_Activity_ElfParadiseRewards_C:ReceiveRewardBtnClick()
  if self.activityData.lottery_result.recieved_award then
  else
    self.activityInst:SendReceiveLotteryRewardReq()
  end
  if 0 == self.RewardIndex then
    self:PlayAnimation(self.XianDing_Out)
  elseif 1 == self.RewardIndex then
    self:PlayAnimation(self.JingXi_Out)
  elseif 2 == self.RewardIndex then
    self:PlayAnimation(self.JiNian_Out)
  elseif 3 == self.RewardIndex then
    self:PlayAnimation(self.Anwei_Out)
  else
    self:PlayAnimation(self.JiNian_Out)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_ElfParadiseRewards_C:ReceiveRewardBtnClick")
  _G.NRCAudioManager:PlaySound2DAuto(40007009, "UMG_Activity_ElfParadiseRewards_C:ReceiveRewardBtnClick")
end

function UMG_Activity_ElfParadiseRewards_C:OnBtnClose()
  if self:IsAnyAnimationPlaying() then
    return
  end
  if 0 == self.RewardIndex then
    self:PlayAnimation(self.XianDing_Out)
  elseif 1 == self.RewardIndex then
    self:PlayAnimation(self.JingXi_Out)
  elseif 2 == self.RewardIndex then
    self:PlayAnimation(self.JiNian_Out)
  elseif 3 == self.RewardIndex then
    self:PlayAnimation(self.Anwei_Out)
  else
    self:PlayAnimation(self.JiNian_Out)
  end
  _G.NRCAudioManager:PlaySound2DAuto(40007009, "UMG_Activity_ElfParadiseRewards_C:OnBtnClose")
end

function UMG_Activity_ElfParadiseRewards_C:OnAnimationFinished(aim)
  if aim == self.JingXi_Out or aim == self.XianDing_Out or aim == self.JiNian_Out or aim == self.Anwei_Out then
    self:DoClose()
  elseif aim == self.XianDing_In then
    self:PlayAnimation(self.XianDing_Loop)
  elseif aim == self.XianDing_Loop then
    self:PlayAnimation(self.XianDing_Loop)
  end
end

function UMG_Activity_ElfParadiseRewards_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseRenamePanel, self.OnBtnClose)
  self:AddButtonListener(self.Button, self.ItemButtonClick)
  self:AddButtonListener(self.ReceiveReward.btnLevelUp, self.ReceiveRewardBtnClick)
end

return UMG_Activity_ElfParadiseRewards_C

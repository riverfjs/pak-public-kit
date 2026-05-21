local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_PersonalChallengeItem_C = Base:Extend("UMG_Activity_PersonalChallengeItem_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_PersonalChallengeItem_C:OnConstruct()
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnTraceBtnClick)
  self:AddButtonListener(self.Btn6.btnLevelUp, self.OnGetRewardBtnClick)
end

function UMG_Activity_PersonalChallengeItem_C:OnDestruct()
  self:CancelDelay()
end

function UMG_Activity_PersonalChallengeItem_C:CancelDelay()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
end

function UMG_Activity_PersonalChallengeItem_C:SetVisibility(InVisibility, bInitiative)
  if bInitiative then
    self.Overridden.SetVisibility(self, InVisibility)
    if InVisibility == UE4.ESlateVisibility.Collapsed then
      self:CancelDelay()
    end
  else
    self.Overridden.SetVisibility(self, UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_PersonalChallengeItem_C:OnItemUpdate(_data, datalist, index)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed, true)
  self.index = index
  self.data = _data
  local waitTime = (index - 1) * 0.1
  self.delayId = _G.DelayManager:DelaySeconds(waitTime, function()
    if self and UE4.UObject.IsValid(self) then
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible, true)
      self:PlayAnimation(self.In)
    end
  end)
  local rewards = {}
  local taskDesc = ""
  self.go_guide = nil
  local parentCustomData = self:GetParentCustomData()
  self.activityObject = parentCustomData.activityInst
  self.challengeType = parentCustomData.challengeType
  if 1 == parentCustomData.challengeType then
    local conf = _G.DataConfigManager:GetActivityConditionRewardConf(_data.partId)
    if conf then
      taskDesc = conf.part_desc
      if conf.reward_group then
        for i, v in ipairs(conf.reward_group) do
          table.insert(rewards, {
            itemId = v.goods_id,
            itemType = v.goods_type,
            itemNum = v.goods_count,
            isDone = _data.rewardState == ActivityEnum.RewardStatus.Received,
            bShowNum = true
          })
        end
      end
      local conditionConf = conf.condition_group and conf.condition_group[1] or nil
      if conditionConf and conditionConf.condition_enum == Enum.RequiredType.ACTRT_TASK then
        local taskConf = _G.DataConfigManager:GetTaskConf(conditionConf.condition_param)
        if taskConf and taskConf.go_guide then
          self.go_guide = taskConf.go_guide[1]
        end
      end
    end
  elseif 2 == parentCustomData.challengeType then
    local conf = _G.DataConfigManager:GetActivityGlobalChallenge(_data.partId)
    if conf then
      taskDesc = conf.des
      local rewardConf = _G.DataConfigManager:GetRewardConf(conf.reward_id)
      if rewardConf and rewardConf.RewardItem then
        for i, v in ipairs(rewardConf.RewardItem) do
          table.insert(rewards, {
            itemId = v.Id,
            itemType = v.Type,
            itemNum = v.Count,
            isDone = _data.rewardState == ActivityEnum.RewardStatus.Received,
            bShowNum = true
          })
        end
      end
    end
  end
  self.Text_Describe:SetText(taskDesc)
  self.AwardList:Clear()
  self.AwardList:InitGridView(rewards)
  self.redPointNew:SetVisibility(_data.rewardState == ActivityEnum.RewardStatus.Available and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if _data.rewardState == ActivityEnum.RewardStatus.Available then
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  elseif _data.rewardState == ActivityEnum.RewardStatus.Received then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
  elseif self.go_guide and self.go_guide.text then
    self.BtnSwitcher:SetActiveWidgetIndex(2)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(3)
  end
end

function UMG_Activity_PersonalChallengeItem_C:OnGetRewardBtnClick()
  if self.activityObject then
    if 1 == self.challengeType then
      local rewardObj = self.activityObject:GetRewardItem(self.data.partId)
      if rewardObj then
        self.activityObject:OnTryGetReward(rewardObj, 0)
      end
    elseif 2 == self.challengeType then
      self.activityObject:GetReward(0)
    end
  end
end

function UMG_Activity_PersonalChallengeItem_C:OnTraceBtnClick()
  if self.go_guide and self.go_guide.text then
    _G.NRCModuleManager:DoCmd(self.go_guide.text, self.go_guide.args, self.go_guide.args2)
  end
end

return UMG_Activity_PersonalChallengeItem_C

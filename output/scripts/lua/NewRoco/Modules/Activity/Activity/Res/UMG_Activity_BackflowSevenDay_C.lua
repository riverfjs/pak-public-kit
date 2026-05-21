local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_SignInTemplate_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local UMG_Activity_BackflowSevenDay_C = Base:Extend("UMG_Activity_BackflowSevenDay_C")

function UMG_Activity_BackflowSevenDay_C:BindUIElements()
  local uiElements = {}
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.BG
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.signStages = {}
  if self.List then
    uiElements.signStages[self.List] = {
      1,
      2,
      3,
      4,
      5,
      6
    }
  end
  if self.List1 then
    uiElements.signStages[self.List1] = {7}
  end
  return uiElements
end

function UMG_Activity_BackflowSevenDay_C:OnConstruct()
  Base.OnConstruct(self)
  local mainActivityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
  if mainActivityObjects and #mainActivityObjects > 0 then
    local mainActivityObject
    for _, object in ipairs(mainActivityObjects) do
      local recall_data = object:GetActivityData()
      if recall_data and recall_data.active then
        mainActivityObject = object
        break
      end
    end
    if mainActivityObject then
      local mainActivityData = mainActivityObject:GetActivityData()
      if mainActivityData then
        local textStr = _G.DataConfigManager:GetActivityRecallClassConf(mainActivityData.recall_class).sign_in_txt
        self.Text_Dialogue:SetText(textStr)
      end
    end
  end
end

function UMG_Activity_BackflowSevenDay_C:OnItemSelected(_itemInst, _index, _stage, _bSelected)
  local _activityInst = self.activityInst
  if _bSelected and _activityInst then
    local handled = _activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.Auto, _stage)
    if not handled then
      ActivityUtils.ShowRewardTips(_activityInst:GetStageRewardId(_stage))
    end
  end
end

function UMG_Activity_BackflowSevenDay_C:OnItemUpdate(_itemInst, _index, _stage)
  local _itemObject = self.activityInst
  if not _itemObject then
    return
  end
  if _itemInst then
    local rewardData = _itemObject:GetStageRewardData(_stage) or {}
    _itemInst:SetRewardIcon(rewardData.showIcon, rewardData.itemType, rewardData.itemId)
    _itemInst:SetRewardNum(rewardData.itemNum)
    _itemInst:SetQuality(rewardData.itemQuality)
    _itemInst:SetSignStage(_stage)
    _itemInst:SetupRedPoint(_itemObject:GetRewardRedPointData(_stage))
    _itemInst:PlayRewardUnAvailableAnimation()
  end
  self:OnItemRefreshView(_itemInst, _index, _stage)
end

function UMG_Activity_BackflowSevenDay_C:OnItemRefreshView(_itemInst, _index, _stage)
  local _itemObject = self.activityInst
  if not _itemObject then
    return
  end
  if _itemInst then
    local rewardStatus = _itemObject:GetStageRewardStatus(_stage)
    if rewardStatus == ActivityEnum.RewardStatus.UnAvailable then
      _itemInst:PlayRewardUnAvailableAnimation()
    elseif rewardStatus == ActivityEnum.RewardStatus.Available then
      _itemInst:PlayRewardAvailableAnimation()
    elseif rewardStatus == ActivityEnum.RewardStatus.Received then
      _itemInst:PlayRewardReceivedAnimation()
    end
  end
end

return UMG_Activity_BackflowSevenDay_C

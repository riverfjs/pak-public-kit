local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_TakePhotoCompetition_ClaimReward_C = _G.NRCPanelBase:Extend("UMG_Activity_TakePhotoCompetition_ClaimReward_C")

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnActive(activityInst)
  self.activityInst = activityInst
  self.rewardData = {}
  self:OnAddEventListener()
  self:InitPanel()
  self:RefreshPanel()
  self:LoadAnimation(0)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.TakePhotoCompetitionActivityVoteRewardEvent, self.RefreshPanel)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_TakePhotoCompetition_ClaimReward_C", self, ActivityModuleEvent.TakePhotoCompetitionActivityVoteRewardEvent, self.RefreshPanel)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnClose")
  self:LoadAnimation(2)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:InitPanel()
  local commonPopUpData = _G.NRCCommonPopUpData()
  commonPopUpData.Call = self
  commonPopUpData.btnClose = true
  commonPopUpData.ClosePanelHandler = self.OnClose
  commonPopUpData.FullScreen_Close = true
  commonPopUpData.TitleText = _G.LuaText.pic_game_accuracy_reward_title
  self.PopUp:SetPanelInfo(commonPopUpData)
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:RefreshPanel()
  if not self.activityInst then
    return
  end
  local ActivityData = self.activityInst:GetActivityData()
  if not ActivityData then
    return
  end
  local receivedRewardIds = ActivityData.reward_ids or {}
  local phaseConf = self.activityInst:GetCurrentPhaseConf()
  if not phaseConf then
    return
  end
  local rewardTable = {}
  self.rewardData = {}
  local rewardList = phaseConf.judge_reward_id
  for i = 1, #rewardList do
    local judgeRewardConf = _G.DataConfigManager:GetJudgeRewardConf(rewardList[i])
    if judgeRewardConf then
      local rewardConf = _G.DataConfigManager:GetRewardConf(judgeRewardConf.reward_id)
      if rewardConf then
        local rewardItems = {}
        for _, rewardItem in ipairs(rewardConf.RewardItem) do
          local item = {}
          item.itemType = rewardItem.Type
          item.itemId = rewardItem.Id
          item.itemNum = rewardItem.Count
          item.bShowNum = true
          item.bShowTip = true
          table.insert(rewardItems, item)
        end
        local isReceived = false
        for _, rewardId in ipairs(receivedRewardIds) do
          if rewardId == rewardList[i] then
            isReceived = true
            break
          end
        end
        table.insert(rewardTable, {
          id = rewardList[i],
          rewardItems = rewardItems,
          currAccuracy = ActivityData.accuracy_score or 0,
          totalAccuracy = judgeRewardConf.accuracy_max,
          isReceived = isReceived,
          parentPanel = self,
          activityInst = self.activityInst
        })
      end
    end
  end
  table.sort(rewardTable, function(a, b)
    if a.isReceived and not b.isReceived then
      return false
    elseif not a.isReceived and b.isReceived then
      return true
    elseif not a.isReceived and not b.isReceived then
      if a.currAccuracy >= a.totalAccuracy and b.currAccuracy < b.totalAccuracy then
        return true
      elseif a.currAccuracy < a.totalAccuracy and b.currAccuracy >= b.totalAccuracy then
        return false
      else
        return a.id < b.id
      end
    else
      return a.id < b.id
    end
  end)
  self.ItemView:InitList(rewardTable)
  self.rewardData = rewardTable
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnRewardBtnClick(rewardId)
  if self.activityInst then
    local rewardIdList = {}
    for _, rewardData in ipairs(self.rewardData) do
      if not rewardData.isReceived and rewardData.currAccuracy >= rewardData.totalAccuracy then
        table.insert(rewardIdList, rewardData.id)
      end
    end
    self.activityInst:SendTakeAccuracyReward(rewardIdList)
  end
end

function UMG_Activity_TakePhotoCompetition_ClaimReward_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_Activity_TakePhotoCompetition_ClaimReward_C

local UMG_Activity_TakePhotoCompetition_RewardPreview_C = _G.NRCPanelBase:Extend("UMG_Activity_TakePhotoCompetition_RewardPreview_C")
local ActivityModuleCmd = require("NewRoco.Modules.System.Activity.ActivityModuleCmd")

function UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnActive()
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if not takePhotoActivityInst then
    Log.Error("UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnActive takePhotoActivityInst is nil")
    return
  end
  local activity_data = takePhotoActivityInst[1]:GetActivityData()
  if not activity_data then
    return
  end
  self.activity_data = activity_data
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = LuaText.pic_game_submit_reward_tittle
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClickCloseBtn
  self.PopUp:SetPanelInfo(CommonPopUpData)
  local tabList = {}
  table.insert(tabList, {
    tabName = LuaText.pic_game_submit_reward_tab
  })
  table.insert(tabList, {
    tabName = LuaText.pic_game_judge_reward_tab
  })
  self.ListTab:InitList(tabList)
  self.ListTab:SelectItemByIndex(0)
  self:LoadAnimation(0)
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnTabItemSelected(tabIndex)
  self.ItemView:InitList({})
  self.ItemView:ScrollToStart()
  local rewardList = {}
  if 1 == tabIndex then
    self.ContentDetails:SetText(LuaText.pic_game_submit_reward_tips)
    local phaseConf = _G.DataConfigManager:GetTakephotoCompetitionConf(self.activity_data.current_phase_id)
    local rewardId = phaseConf and phaseConf.contestant_reward_id or 0
    local contestantRewardConf = _G.DataConfigManager:GetAllByName("CONTESTANT_REWARD_CONF")
    for _, v in pairs(contestantRewardConf) do
      local contestantReward = v
      if contestantReward.takephoto_competition_id == rewardId then
        local rewardData = {tabIndex = 1, reward = contestantReward}
        table.insert(rewardList, rewardData)
      end
    end
    table.sort(rewardList, function(a, b)
      return a.reward.id < b.reward.id
    end)
  elseif 2 == tabIndex then
    self.ContentDetails:SetText(LuaText.pic_game_judge_reward_tips)
    local judgeRewardConf = _G.DataConfigManager:GetAllByName("JUDGE_REWARD_CONF")
    for _, v in pairs(judgeRewardConf) do
      local rewardData = {tabIndex = 2, reward = v}
      table.insert(rewardList, rewardData)
    end
    table.sort(rewardList, function(a, b)
      return a.reward.id < b.reward.id
    end)
  end
  if #rewardList > 0 then
    self.ItemView:InitList(rewardList)
  end
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnClickCloseBtn()
  self:LoadAnimation(2)
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_TakePhotoCompetition_RewardPreview_C:OnPcClose()
  self:LoadAnimation(2)
end

return UMG_Activity_TakePhotoCompetition_RewardPreview_C

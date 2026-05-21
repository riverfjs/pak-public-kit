local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local redDotPath = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_hongdian_png.img_hongdian_png'"
local UMG_Activity_DigForTreasure_C = Base:Extend("UMG_Activity_DigForTreasure_C")

function UMG_Activity_DigForTreasure_C:BindUIElements()
  local uiElements = {}
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.closeAnimName = "Out"
  return uiElements
end

function UMG_Activity_DigForTreasure_C:OnConstruct()
  Base.OnConstruct(self)
  local _activityInst = self.activityInst
  self.Text_Title:SetText(_activityInst:GetActivityName())
  self.Text_Describe:SetText(_activityInst:GetActivityPromptText())
  self.cluePath = ActivityUtils.GetActivityGlobalConfig("Treasure_hunt_previewed_image").str
  self.activityInst.DigForTreasure = self
  self:OnAddEventListener()
  self:InitReward()
end

function UMG_Activity_DigForTreasure_C:OnDestruct()
  if self.activityInst then
    self.activityInst.DigForTreasure = nil
  end
  Base.OnDestruct(self)
end

function UMG_Activity_DigForTreasure_C:OnAddEventListener()
  local _activityInst = self.activityInst
  if _activityInst and not _activityInst.hasEverBeenReceiveServerUpdate then
    self:DelayFrames(1, self.OnAddEventListener, self)
    return
  end
  local BtnText = {}
  local taskID = tonumber(ActivityUtils.GetActivityGlobalConfig("activity_treasure_hunt_guide_task").numList[2])
  local TaskMap = NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskMap)
  for k, v in pairs(TaskMap) do
    if v.Config.id == taskID then
      self.prepareTask = v.Config
      break
    end
  end
  local isTaskFinished = _activityInst.isPrepareTaskFinished
  if _activityInst:IsInProgress() then
    if not isTaskFinished then
      self.Switcher_Btn.ActiveWidgetIndex = 0
      BtnText = _G.LuaText.treasure_hunt_tips
      self:AddButtonListener(self.RewardBtn.btnLevelUp, self.OnClickHomeBtn)
    else
      self.Switcher_Btn.ActiveWidgetIndex = 0
      BtnText = _G.LuaText.treasure_hunt_participate_tips
      self.RewardBtn.RedDot:SetupKey(384, self.activityInst:GetActivityId())
      if self.activityInst.treasureHuntDataSRV then
        for i, v in pairs(self.activityInst.treasureHuntDataSRV.treasure_data) do
          if v.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
            self.RewardBtn.RedDot:SetupKey(492, self.activityInst:GetActivityId())
            break
          end
        end
      end
      self:AddButtonListener(self.RewardBtn.btnLevelUp, self.OnClickRewardBtn)
    end
    self.RewardBtn:SetBtnText(BtnText)
  else
    self.Switcher_Btn:SetActiveWidgetIndex(1)
    self.HOMEBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self:AddButtonListener(self.HOMEBtn, self.OpenPhotographPanel)
  end
end

function UMG_Activity_DigForTreasure_C:OnClickHomeBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1077, "UMG_Activity_DigForTreasure_C:OnClickHomeBtn")
  if self.activityInst and self.activityInst:IsInProgress() and self.prepareTask ~= nil then
    _G.NRCModeManager:DoCmd(_G.TaskModuleCmd.setTrack, self.prepareTask.id, true)
    if self.prepareTask then
      _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap, {
        TaskId = self.prepareTask.id,
        IsOpenRightPanel = false
      })
    end
  end
end

function UMG_Activity_DigForTreasure_C:OnClickRewardBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1077, "UMG_Activity_DigForTreasure_C:OnClickHomeBtn")
  if self.RewardBtn.RedDot:IsRed() and self.RewardBtn.RedDot:GetKey() == 384 then
    self.RewardBtn.RedDot:EraseRedPoint()
  end
  if self.activityInst and self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenActivityTreasureSpot, self.activityInst)
  end
end

function UMG_Activity_DigForTreasure_C:OpenPhotographPanel()
  _G.NRCAudioManager:PlaySound2DAuto(1078, "UMG_Activity_DigForTreasure_C:OnClickHomeBtn")
  self.module:OpenPhotographPanel(self.cluePath)
end

function UMG_Activity_DigForTreasure_C:InitReward()
  local rewardData = {}
  rewardData.itemDataTemplate = {}
  rewardData.itemDataTemplate.bShowNum = true
  rewardData.itemDataTemplate.bShowTip = true
  rewardData.itemList = {}
  
  local function AddReward(rewardId)
    local _data = {}
    _data.itemType = _G.Enum.GoodsType.GT_REWARD
    _data.itemId = rewardId
    _data.itemNum = 1
    table.insert(rewardData.itemList, _data)
  end
  
  local _activityInst = self.activityInst
  if _activityInst then
    local partIds = _activityInst:GetPartIds()
    for _, partId in ipairs(partIds) do
      local treasureConf = _activityInst:getTreasureConf(partId)
      if treasureConf then
        if treasureConf.reward and 0 ~= treasureConf.reward then
          AddReward(treasureConf.reward)
        end
        local contentRewards = _activityInst:GetRewardsFromContent(treasureConf)
        if contentRewards then
          for _, contentReward in ipairs(contentRewards) do
            AddReward(contentReward)
          end
        end
      end
    end
  end
  self.GeneralReward:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.GeneralReward:SetData(rewardData)
end

return UMG_Activity_DigForTreasure_C

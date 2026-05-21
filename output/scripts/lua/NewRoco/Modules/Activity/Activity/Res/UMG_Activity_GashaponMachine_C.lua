local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_GashaponMachine_C = Base:Extend("UMG_Activity_GashaponMachine_C")
local UIUtils = require("NewRoco.Utils.UIUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_GashaponMachine_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = _G.Enum.ActivityType.ATP_BASE_MIX
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.BG
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  return uiElements
end

function UMG_Activity_GashaponMachine_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
end

function UMG_Activity_GashaponMachine_C:OnAddEventListener()
  self:AddButtonListener(self.ChallengeBtn, self.OnChallengeBtnClick)
  self:AddButtonListener(self.leaveForBtn, self.OnleaveForBtnClick)
  self:AddButtonListener(self.DailySupplyBtn, self.OnDailySupplyBtnClick)
  self:AddButtonListener(self.PlayingMethodBtn, self.OnPlayingMethodBtnClick)
  self:AddButtonListener(self.ScrimmageBtn, self.OnScrimmageBtnClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_GashaponMachine_C", self, ActivityModuleEvent.PeriodicLoginActivityGetReward, self.OnPeriodicLoginActivityGetReward)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_GashaponMachine_C", self, ActivityModuleEvent.PeriodicLoginActivityDataRefresh, self.RefreshView)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_GashaponMachine_C", self, ActivityModuleEvent.GlobalChallengeActivityGetReward, self.RefreshView)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_GashaponMachine_C", self, ActivityModuleEvent.GlobalChallengeActivityDataRefresh, self.RefreshView)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_GashaponMachine_C", self, ActivityModuleEvent.GetConditionRewardItemRewardSuccess, self.RefreshView)
end

function UMG_Activity_GashaponMachine_C:OnDestruct()
  self:ClearCountdown()
  self:RemoveAllButtonListener()
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.PeriodicLoginActivityGetReward, self.OnPeriodicLoginActivityGetReward)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.PeriodicLoginActivityDataRefresh, self.RefreshView)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.GlobalChallengeActivityGetReward, self.RefreshView)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.GlobalChallengeActivityDataRefresh, self.RefreshView)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.GetConditionRewardItemRewardSuccess, self.RefreshView)
end

function UMG_Activity_GashaponMachine_C:OnEnable(firstLoad)
  self:PlayAnimation(self.In)
  self.signRewardActivityObj = nil
  self.selfChallengeObject = nil
  self.serverChallengeObjectList = {}
  self:RefreshOtherSubActivityData()
  if firstLoad then
    self:RefreshFixedView()
  end
  self:RefreshView()
end

function UMG_Activity_GashaponMachine_C:RefreshOtherSubActivityData()
  local selfChallengeActivityId = 0
  local activityInst = self.activityInst
  local mixCfg = activityInst:GetMixCfg()
  if mixCfg and mixCfg.slot_group and mixCfg.slot_group[5] then
    local redPointId, redPointExtraKey = activityInst:GetSlotRedPointData(mixCfg.slot_group[5])
    if redPointId and next(redPointExtraKey) then
      for i, v in pairs(redPointExtraKey) do
        local _extraKeyList = string.Split(v, ";")
        for _, extraKey in ipairs(_extraKeyList) do
          selfChallengeActivityId = tonumber(extraKey)
          break
        end
      end
    end
  end
  local ActiveObjectList_SignReward = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_SIGN_REWARD, true)
  local ActivityObjectList_Condition = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_CONDITION_REWARD, true)
  local ActiveObjectList_Challenge = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_GLOBAL_CHALLENGE, true)
  if ActiveObjectList_SignReward then
    for i, v in ipairs(ActiveObjectList_SignReward) do
      v:ReqGetPlayerActivityData()
      self.signRewardActivityObj = v
    end
  end
  if ActivityObjectList_Condition then
    for i, v in ipairs(ActivityObjectList_Condition) do
      if selfChallengeActivityId == v:GetActivityId() then
        v:ReqGetPlayerActivityData()
        self.selfChallengeObject = v
      end
    end
  end
  if ActiveObjectList_Challenge then
    for i, v in ipairs(ActiveObjectList_Challenge) do
      v:ReqGetPlayerActivityData()
    end
  end
  self.serverChallengeObjectList = ActiveObjectList_Challenge
end

function UMG_Activity_GashaponMachine_C:RefreshFixedView()
  local activityInst = self.activityInst
  local mixCfg = activityInst:GetMixCfg()
  if not mixCfg then
    Log.Error("UMG_Activity_GashaponMachine_C:RefreshFixedView mixCfg is nil")
    return
  end
  local slot1Data = mixCfg.slot_group and mixCfg.slot_group[1] or nil
  local slot2Data = mixCfg.slot_group and mixCfg.slot_group[2] or nil
  local slot3Data = mixCfg.slot_group and mixCfg.slot_group[3] or nil
  local slot4Data = mixCfg.slot_group and mixCfg.slot_group[4] or nil
  local slot5Data = mixCfg.slot_group and mixCfg.slot_group[5] or nil
  if slot1Data then
    local slotName = self.activityInst:GetSlotName(slot1Data.option_id)
    local itemNum, itemType = activityInst:DoOperate(1)
    self.NRCText_2:SetText(slotName)
    UIUtils.SetItemIcon(slot1Data.param, itemType, itemNum, self.Icon_2, nil, self.QuantityText_1)
  end
  if slot2Data then
    local slotName = self.activityInst:GetSlotName(slot2Data.option_id)
    local rewardNum = 1
    local activityObjectList = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_SIGN_REWARD, true)
    if activityObjectList and #activityObjectList > 0 then
      local activityId = activityObjectList[1]:GetActivityId()
      local rewardConf = _G.DataConfigManager:GetActivitySignReward(activityId)
      if rewardConf and rewardConf.reward_id then
        local rewardConf2 = _G.DataConfigManager:GetRewardConf(rewardConf.reward_id)
        if rewardConf2 and rewardConf2.RewardItem and rewardConf2.RewardItem[1] then
          rewardNum = rewardConf2.RewardItem[1].Count or 1
          UIUtils.SetItemIcon(rewardConf2.RewardItem[1].Id, rewardConf2.RewardItem[1].Type, nil, self.NRCImage_Icon)
          self.signReward = {}
          self.signReward.itemId = rewardConf2.RewardItem[1].Id
          self.signReward.itemType = rewardConf2.RewardItem[1].Type
        end
      end
    end
    self.NRCText_5:SetText(slotName)
    self.DailySupplyRedDot:SetRedPointUIType(Enum.RedPointType.RPT_AWARD, true)
    self.NRCText_Quantity:SetText("x" .. rewardNum)
    self.CanvasPanel_247:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_192:SetText("")
  end
  if slot3Data then
    local slotName = self.activityInst:GetSlotName(slot3Data.option_id)
    self.NRCText_3:SetText(slotName)
  end
  if slot4Data then
    local slotName = self.activityInst:GetSlotName(slot4Data.option_id)
    self.NRCText_4:SetText(slotName)
  end
  if slot5Data then
    local slotName = self.activityInst:GetSlotName(slot5Data.option_id)
    local redPointId, redPointExtraKey = self.activityInst:GetSlotRedPointData(slot5Data)
    self.NRCText_1:SetText(slotName)
    self.RedDot_1:SetRedPointUIType(Enum.RedPointType.RPT_AWARD, true)
  end
  self.RedDot_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_GashaponMachine_C:RefreshView()
  if not self.activityInst then
    return
  end
  local itemNum, itemType = self.activityInst:DoOperate(1)
  self.QuantityText_1:SetText(itemNum or 0)
  self:RefreshSignRewardView()
  self.RedDot_1:SetVisibility(self:HaveCanGetReward() and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_GashaponMachine_C:HaveCanGetReward()
  if self.selfChallengeObject then
    local itemList = self.selfChallengeObject:GetRewardItems()
    if itemList then
      for i, v in ipairs(itemList) do
        v:UpdateProgress()
        if v:GetRewardStatus() == ActivityEnum.RewardStatus.Available then
          return true
        end
      end
    end
  end
  if self.serverChallengeObjectList then
    for i, v in pairs(self.serverChallengeObjectList) do
      if v:HaveCanGetReward() then
        return true
      end
    end
  end
  return false
end

function UMG_Activity_GashaponMachine_C:RefreshSignRewardView()
  self:ClearCountdown()
  local bTimeUIShow, bCompletedUIShow, bDayRewardRedPointShow = false
  if self.signRewardActivityObj then
    local canGetReward, nextRefreshTime = self.signRewardActivityObj:CanGetReward()
    if canGetReward then
      bDayRewardRedPointShow = true
    else
      if nextRefreshTime > 0 then
        bCompletedUIShow = true
      end
      local currentTime = _G.ZoneServer:GetServerTime() / 1000
      self.Countdown = math.floor(nextRefreshTime - currentTime)
      if self.Countdown > 0 then
        self.DelayId = _G.TimerManager:CreateTimer(self, "Countdown", self.Countdown, self.OnTimerUpdate, self.OnTimeComplete, 1)
        bTimeUIShow = true
      end
    end
  end
  self.CanvasPanel_247:SetVisibility(bTimeUIShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.CanvasCompleted:SetVisibility(bCompletedUIShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.DailySupplyRedDot:SetVisibility(bDayRewardRedPointShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_GashaponMachine_C:ClearCountdown()
  if self.DelayId then
    _G.TimerManager:RemoveTimer(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Activity_GashaponMachine_C:OnTimerUpdate()
  if self and UE4.UObject.IsValid(self) then
    self.Countdown = self.Countdown - 1
    if self.Countdown >= 0 then
      self.NRCText_192:SetText(string.format(LuaText.Activity_sign_reward_time, ActivityUtils.GetTimeFormatStr(self.Countdown)))
    end
  end
end

function UMG_Activity_GashaponMachine_C:OnTimeComplete()
  if self.signRewardActivityObj then
    self.signRewardActivityObj:ReqGetPlayerActivityData()
  end
end

function UMG_Activity_GashaponMachine_C:OnRefreshCountdown()
  self.Countdown = self.Countdown - 1
  if self.Countdown >= 0 then
    self.NRCText_192:SetText(string.format(LuaText.Activity_sign_reward_time, self.Countdown))
  else
    self.CanvasPanel_247:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.signRewardActivityObj then
      self.signRewardActivityObj:ReqGetPlayerActivityData()
    end
  end
end

function UMG_Activity_GashaponMachine_C:OnPeriodicLoginActivityGetReward()
  self.CanvasCompleted:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.DailySupplyRedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.Get)
  if self.signRewardActivityObj then
    self.signRewardActivityObj:ReqGetPlayerActivityData()
  end
end

function UMG_Activity_GashaponMachine_C:OnleaveForBtnClick()
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  self.activityInst:DoOperate(1, true)
end

function UMG_Activity_GashaponMachine_C:OnDailySupplyBtnClick()
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  if self.signRewardActivityObj then
    local canGetReward, _ = self.signRewardActivityObj:CanGetReward()
    if canGetReward then
      self.signRewardActivityObj:GetReward()
      return
    end
  end
  if self.signReward then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, self.signReward.itemId, self.signReward.itemType)
  end
end

function UMG_Activity_GashaponMachine_C:OnPlayingMethodBtnClick()
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  self.activityInst:DoOperate(3, true)
end

function UMG_Activity_GashaponMachine_C:OnScrimmageBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_GashaponMachine_C:OnScrimmageBtnClick")
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  self.activityInst:DoOperate(4, true)
end

function UMG_Activity_GashaponMachine_C:OnChallengeBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40006003, "UMG_Activity_GashaponMachine_C:OnScrimmageBtnClick")
  if not self.activityInst:IsInProgress() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    return
  end
  self.activityInst:DoOperate(5, true)
end

return UMG_Activity_GashaponMachine_C

local UMG_ChallengeSettlement_C = _G.NRCPanelBase:Extend("UMG_ChallengeSettlement_C")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")

function UMG_ChallengeSettlement_C:OnActive(SettleData, isTest)
  self.SettleData = SettleData
  self.isTest = isTest
  self:OnAddEventListener()
  if not isTest then
    self:InitDataByFinishData(self.SettleData)
  end
  self:RefreshUI()
  self:SendReceivePhotoReward()
end

function UMG_ChallengeSettlement_C:InitDataByFinishData(param)
  local pve_add_info = param.pve_add_info
  self.challenge_level_id = pve_add_info.challenge_level_id
  self.activityId = pve_add_info.activity_id
  self.activityConf = _G.DataConfigManager:GetActivityConf(self.activityId)
end

function UMG_ChallengeSettlement_C:RefreshUI()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetBgmToTheater)
  if self.isTest or _G.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin() then
    _G.NRCAudioManager:PlaySound2DAuto(1501, "UMG_ChallengeSettlement_C:RefreshUI")
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.Win_In)
  else
    _G.NRCAudioManager:PlaySound2DAuto(1026, "UMG_ChallengeSettlement_C:RefreshUI")
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self:PlayAnimation(self.Failure_IN)
  end
  self.getPoint = self.SettleData.pve_add_info.cheer_point or 0
  self.curPoint = self.SettleData.pve_add_info.cheer_point_this_week or 0
  local canTakePhoto = self.SettleData.pve_add_info.can_take_photo
  self.targetPoint = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetWeeklyChallengeDataTargetPoint)
  self.photoPoint = self.targetPoint
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  if rewardList and #rewardList > 0 then
    for k, v in ipairs(rewardList) do
      if v.bIsTakingPhoto then
        self.photoPoint = v.star_required_num
        break
      end
    end
  end
  local showPoint = self.curPoint
  if showPoint > self.targetPoint then
    showPoint = self.targetPoint
  end
  self.Headline:SetText(string.format("x%d", self.getPoint))
  self.Headline_1:SetText(string.format("%d/%d", showPoint, self.targetPoint))
  local textStr = _G.LuaText.weekly_challenge_text_1
  self.Text_4:SetText(string.format(textStr, self.photoPoint))
  self.lastPercent = (self.curPoint - self.getPoint) / self.photoPoint
  self.targetPercent = self.curPoint / self.photoPoint
  if canTakePhoto then
    self.Go:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.FullScreenBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PromptText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Go:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.FullScreenBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PromptText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local textStr = _G.LuaText.weekly_challenge_text_19
    self.PromptText:SetText(textStr)
  end
  if self.lastPercent >= 1 and self.targetPercent >= 1 then
    self.hasUnLocked = true
  else
    self.hasUnLocked = false
  end
  self.Schedule:SetPercent(self.lastPercent)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local initList = {}
  for i = 1, worldLevel do
    table.insert(initList, {bShow = true})
  end
  self.GridView_Difficulty:InitGridView(initList)
end

function UMG_ChallengeSettlement_C:ShowPercentEvent()
  if not self.hasUnLocked then
    self:StarScheduleAnim()
  end
end

function UMG_ChallengeSettlement_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_ChallengeSettlement_C:ScheduleAnimFinished()
end

function UMG_ChallengeSettlement_C:StarScheduleAnim()
  self.animTime = 1.5
  self.lastTime = 0
  self.tickState = true
end

function UMG_ChallengeSettlement_C:ShowCameraAnim()
  self:PlayAnimation(self.Camera)
end

function UMG_ChallengeSettlement_C:OnAddEventListener()
  self:AddButtonListener(self.StartTheShow_1.btnLevelUp, self.OnClickStartTheShow)
  self:AddButtonListener(self.Btn_Return.btnLevelUp, self.OnClickReturn)
  self:AddButtonListener(self.Btn_FightAgain.btnLevelUp, self.ChallengeAgain)
  self:AddButtonListener(self.FullScreenBtn, self.OnClickReturn)
  _G.NRCEventCenter:RegisterEvent("UMG_ChallengeSettlement_C", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function UMG_ChallengeSettlement_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.StartTheShow_1.btnLevelUp, self.OnClickStartTheShow)
  self:RemoveButtonListener(self.Btn_Return.btnLevelUp, self.OnClickReturn)
  self:RemoveButtonListener(self.Btn_FightAgain.btnLevelUp, self.ChallengeAgain)
  self:RemoveButtonListener(self.FullScreenBtn, self.OnClickReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function UMG_ChallengeSettlement_C:OnConnected()
  self:DoClose()
end

function UMG_ChallengeSettlement_C:OnClickReturn()
  if self.isTest then
    self:DoClose()
  else
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CmdTryOpenStarlightUmg)
    self:OnClickClose()
  end
end

function UMG_ChallengeSettlement_C:OnClickStartTheShow()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ChallengeSettlement_C:OnClickStartTheShow")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CmdTryOpenPhotoUmg)
  self:SendReceivePhotoReward()
  self:OnClickClose()
end

function UMG_ChallengeSettlement_C:OnClickClose()
  _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
end

function UMG_ChallengeSettlement_C:ChallengeAgain()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.WeeklyChallengeBattleAgain, self.activityId, self.challenge_level_id)
end

function UMG_ChallengeSettlement_C:OnTick(deltaTime)
  if not self.tickState then
    return
  end
  local curPercent = self.targetPercent
  if self.lastTime + deltaTime <= self.animTime then
    self.lastTime = self.lastTime + deltaTime
    local ratio = self.lastTime / self.animTime
    curPercent = self.lastPercent + (self.targetPercent - self.lastPercent) * ratio
    self.Schedule:SetPercent(curPercent)
  else
    self.tickState = false
    self.Schedule:SetPercent(curPercent)
    if 1 == curPercent then
      self:ShowCameraAnim()
    end
  end
end

function UMG_ChallengeSettlement_C:OnLogin()
end

function UMG_ChallengeSettlement_C:OnConstruct()
end

function UMG_ChallengeSettlement_C:OnDestruct()
end

function UMG_ChallengeSettlement_C:OnAnimationFinished(anim)
end

function UMG_ChallengeSettlement_C:SendReceivePhotoReward()
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  local photoReward
  for k, v in ipairs(rewardList) do
    if v.bIsTakingPhoto then
      photoReward = v
    end
  end
  if not photoReward then
    return
  end
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("UMG_ChallengeSettlement_C:SendReceivePhotoReward \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetActivityId()
  if photoReward.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendReceiveRewardReq, activityId, photoReward.star_required_num, nil, ProtoEnum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  end
end

return UMG_ChallengeSettlement_C

local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local AICoachModuleEvent = require("NewRoco.Modules.System.AICoachModule.AICoachModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local UMG_Activity_ShiningWeekend_C = Base:Extend("UMG_Activity_ShiningWeekend_C")

function UMG_Activity_ShiningWeekend_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_PET_WEEKEND_CHALLENGE
  uiElements.title = self.Text_Title
  uiElements.titleLabelIcon = self.Label
  uiElements.titleLabelText = self.NRCText_61
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.BG
  uiElements.timeRemainingRoot = self.time
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_ShiningWeekend_C:OnConstruct()
  Base.OnConstruct(self)
  local activity_id = self.activityInst:GetActivityId()
  local weekendChallengeConf = _G.DataConfigManager:GetActivityWeekendChallengeConf(activity_id)
  self.isShowAIEntry = true
  if 0 == weekendChallengeConf.entry_a then
    self.BtnRecommendedlineup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.isShowAIEntry = false
  end
  if 0 == weekendChallengeConf.entry_b then
    self.BtnTimePet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:OnAddEventListener()
  self.RedDot:SetupKey(214, {activity_id, 1})
  self.redPointNew:SetupKey(214, {activity_id, 2})
  self.NRCText_1:SetText(_G.LuaText.weekend_challenge_1)
  self.NRCText_166:SetText(_G.LuaText.weekend_challenge_2)
  local isAIInWhiteList = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsPlayerInWhiteList)
  local isSystemOpen = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetSysAICoachSceneIsOpen, Enum.FunctionEntrance.FE_AI_COACH_TEAM)
  local isAIOpen = _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.GetIsCurrAICoachOpen)
  self.isShowAIEntry = self.isShowAIEntry and isSystemOpen
  self:OnUpdateAICoachStatus(isAIInWhiteList, isAIOpen)
  self.BtnAIOn.RedDot:SetupKey(490, {activity_id})
  if not isAIInWhiteList then
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnRequestPlayerInWhiteList)
  end
end

function UMG_Activity_ShiningWeekend_C:OnAddEventListener()
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OpenBattleManual)
  self:AddButtonListener(self.BtnRecommendedlineup, self.OpenRecommendedTeam)
  self:AddButtonListener(self.BtnTimePet, self.OpenTimePet)
  self:AddButtonListener(self.BtnAIOn.btnLevelUp, self.OpenAICoach)
  self:AddButtonListener(self.BtnAIOff.btnLevelUp, self.OpenRecommendedTeam)
  self:AddButtonListener(self.ShutDownBtn, self.CloseAICoach)
  self:AddButtonListener(self.MoreBtn.btnLevelUp, self.ShowShutDown)
  self.BtnAIOn.btnLevelUp.OnPressed:Add(self, self.OnOpenBtnPressed)
  self.BtnAIOn.btnLevelUp.OnReleased:Add(self, self.OnOpenBtnReleased)
  self.BtnAIOff.btnLevelUp.OnPressed:Add(self, self.OnCloseBtnPressed)
  self.BtnAIOff.btnLevelUp.OnReleased:Add(self, self.OnCloseBtnReleased)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_ShiningWeekend_C", self, PVPRankedMatchModuleEvent.ShiningWeekendGetTrialPet, self.OpenPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_ShiningWeekend_C", self, ActivityModuleEvent.SendShiningWeekendTLog, self.SendTLog)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_ShiningWeekend_C", self, AICoachModuleEvent.OnNotifyAICoachStateChange, self.OnUpdateAICoachStatus)
end

function UMG_Activity_ShiningWeekend_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.TraceBtn.btnLevelUp)
  self:RemoveButtonListener(self.BtnRecommendedlineup)
  self:RemoveButtonListener(self.BtnTimePet)
  self:RemoveButtonListener(self.BtnAIOn.btnLevelUp)
  self:RemoveButtonListener(self.BtnAIOff.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.ShiningWeekendGetTrialPet, self.OpenPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.SendShiningWeekendTLog, self.SendTLog)
  _G.NRCEventCenter:UnRegisterEvent(self, AICoachModuleEvent.OnNotifyAICoachStateChange, self.OnUpdateAICoachStatus)
end

function UMG_Activity_ShiningWeekend_C:OpenBattleManual()
  _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManualByIndex, "MMT_PVP")
  self:SendTLog(3)
end

function UMG_Activity_ShiningWeekend_C:OpenRecommendedTeam()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_ShiningWeekend_C:OpenAICoach")
  local trialPets = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  if trialPets then
    self:OpenRecommendedTeamPanel()
  else
    self.openIndex = 1
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ShiningWeekendGetTrialPet)
  end
  self:CheckAndEraseRedPoint(1)
end

function UMG_Activity_ShiningWeekend_C:OnOpenBtnPressed()
  self.BtnAIOn:PlayAnimation(self.BtnAIOn.Press)
end

function UMG_Activity_ShiningWeekend_C:OnOpenBtnReleased()
  self.BtnAIOn:PlayAnimation(self.BtnAIOn.Up)
end

function UMG_Activity_ShiningWeekend_C:OnCloseBtnPressed()
  self.BtnAIOff:PlayAnimation(self.BtnAIOff.Press)
end

function UMG_Activity_ShiningWeekend_C:OnCloseBtnReleased()
  self.BtnAIOff:PlayAnimation(self.BtnAIOff.Up)
end

function UMG_Activity_ShiningWeekend_C:OnUpdateAICoachStatus(isWhiteList, isOpen)
  if isWhiteList and self.isShowAIEntry then
    self.AICoachPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if isOpen then
      self.BtnAIOn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BtnAIOff:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.MoreBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AICoach:SetPath("Texture2D'/Game/NewRoco/Modules/System/Activity/Raw/Textures/img_AICoach2.img_AICoach2'")
    else
      self.BtnAIOn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BtnAIOff:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.MoreBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.AICoach:SetPath("Texture2D'/Game/NewRoco/Modules/System/Activity/Raw/Textures/img_AICoach1.img_AICoach1'")
    end
    if self.ShutDownBtn:GetVisibility() == UE4.ESlateVisibility.Visible then
      self.ShutDownBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:PlayAnimation(self.ShutDownBtn_Close)
    end
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnReportEvent, "weekend_page_expo")
  else
    self.AICoachPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.AIDesc:SetText(_G.LuaText.ai_coach_1 .. "\n" .. _G.LuaText.ai_coach_2)
  self.BtnAIOn:SetBtnText(_G.LuaText.ai_coach_4)
  self.BtnAIOff:SetBtnText(_G.LuaText.head_to)
end

function UMG_Activity_ShiningWeekend_C:ShowShutDown()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ShiningWeekend_C:CloseAICoach")
  if self.ShutDownBtn:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self.ShutDownBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.ShutDownBtn_Open)
  else
    self.ShutDownBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.ShutDownBtn_Close)
  end
end

function UMG_Activity_ShiningWeekend_C:OpenAICoach()
  _G.NRCAudioManager:PlaySound2DAuto(40002021, "UMG_Activity_ShiningWeekend_C:OpenAICoach")
  if self.BtnAIOn.RedDot:IsRed() then
    self.BtnAIOn.RedDot:EraseRedPoint()
  end
  local playerInfo = DataModelMgr.PlayerDataModel:GetPlayerInfo()
  local key = "AICoachAgreeRecode" .. tostring(playerInfo.brief_info.uin)
  local CacheFile = JsonUtils.LoadSaved(key, {}) or {}
  if CacheFile and CacheFile.Agree then
    _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnSetAICoachState, ProtoEnum.AiCoachStatus.ACS_QA)
  else
    self.module:OnOpenAICoachProtocolPanel()
  end
end

function UMG_Activity_ShiningWeekend_C:CloseAICoach()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Activity_ShiningWeekend_C:CloseAICoach")
  _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnSetAICoachState, ProtoEnum.AiCoachStatus.ACS_CLOSED)
end

function UMG_Activity_ShiningWeekend_C:OpenPanel()
  if 1 == self.openIndex then
    self:OpenRecommendedTeamPanel()
  elseif 2 == self.openIndex then
    self:OpenTimePetPanel()
  end
end

function UMG_Activity_ShiningWeekend_C:OpenRecommendedTeamPanel()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenFriendPetTeamPanel, Enum.PlayerTeamType.PTT_PVP_BATTLE_4, self.activityInst:GetActivityId())
  self:SendTLog(1)
end

function UMG_Activity_ShiningWeekend_C:OpenTimePet()
  local trialPets = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  if trialPets then
    self:OpenTimePetPanel()
  else
    self.openIndex = 2
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ShiningWeekendGetTrialPet)
  end
  self:CheckAndEraseRedPoint(2)
end

function UMG_Activity_ShiningWeekend_C:OpenTimePetPanel()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenTrialPVPPet)
  self:SendTLog(2)
end

function UMG_Activity_ShiningWeekend_C:OnDisable()
  Base.OnDisable(self)
  self:CheckAndEraseRedPoint(0)
end

function UMG_Activity_ShiningWeekend_C:CheckAndEraseRedPoint(index)
  if (1 == index or 0 == index) and self.RedDot:IsRed() then
    self.RedDot:EraseRedPoint(false)
  end
  if (2 == index or 0 == index) and self.redPointNew:IsRed() then
    self.redPointNew:EraseRedPoint(false)
  end
end

function UMG_Activity_ShiningWeekend_C:SendTLog(InteractionID)
  local key = "WeekendChallengeInteractionLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local RankStar = PVPRankedMatchModuleUtils.GetSelfRankStar()
  if not RankStar then
    return
  end
  local curRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
  local RankName = curRankConf.id
  local value = string.format("%s|%s|%d|%d", key, roleDataStr, RankName, InteractionID)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function UMG_Activity_ShiningWeekend_C:OnDestruct()
  self:OnRemoveEventListener()
end

return UMG_Activity_ShiningWeekend_C

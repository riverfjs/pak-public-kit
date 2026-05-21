local ModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_HerbologyBadge_Entrance_C = _G.NRCPanelBase:Extend("UMG_HerbologyBadge_Entrance_C")

function UMG_HerbologyBadge_Entrance_C:OnActive()
  UE4Helper.SetEnableWorldRendering(true, nil, "Entrance")
  self:OnAddEventListener()
  self:_InitPanel()
end

function UMG_HerbologyBadge_Entrance_C:OnDeactive()
  UE4Helper.SetEnableWorldRendering(nil, nil, "Entrance")
  self:OnRemoveEventListener()
end

function UMG_HerbologyBadge_Entrance_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnDetailButtonClicked)
  self:AddButtonListener(self.StartAdventure_Btn.btnLevelUp, self.OnStartAdventureButtonClicked)
  self:AddButtonListener(self.Btnjiangbei, self.OnAwardCupButtonClicked)
  self:AddButtonListener(self.ConclusionBtn.btnLevelUp, self.OnConclusionButtonClicked)
  self:AddButtonListener(self.continueBtn.btnLevelUp, self.OnContinueButtonClicked)
end

function UMG_HerbologyBadge_Entrance_C:OnRemoveEventListener()
end

function UMG_HerbologyBadge_Entrance_C:OnCloseButtonClicked()
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.Exit)
end

function UMG_HerbologyBadge_Entrance_C:OnDetailButtonClicked()
  local titleText = "\232\191\153\230\152\175\230\160\135\233\162\152"
  local contentStr = "\232\191\153\230\152\175\229\134\133\229\174\185"
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_HerbologyBadge_Entrance_C:OnStartAdventureButtonClicked()
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.ChooseLevel)
end

function UMG_HerbologyBadge_Entrance_C:OnAwardCupButtonClicked()
end

function UMG_HerbologyBadge_Entrance_C:OnConclusionButtonClicked()
  self.module:OpenAbandonChallengeTip()
end

function UMG_HerbologyBadge_Entrance_C:OnContinueButtonClicked()
  self.module:ResumeTrialSceneReq()
end

function UMG_HerbologyBadge_Entrance_C:OnConstruct()
end

function UMG_HerbologyBadge_Entrance_C:OnDestruct()
end

function UMG_HerbologyBadge_Entrance_C:_InitPanel()
  self.shuliang:SetText("\229\134\146\233\153\169\230\137\139\229\134\140")
  self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
  local trialData = self.module.Data:GetCacheTrialData()
  local periodData = trialData.period_data
  local currentScore = 0
  if periodData then
    currentScore = periodData.current_period_score or 0
  end
  self:UpdatePoint(currentScore, 1500)
  self:_InitCountdown(periodData)
  local challengeData
  if trialData and trialData.challenge_data then
    challengeData = trialData.challenge_data
  end
  if challengeData and challengeData.state == _G.Enum.GrassTrialState.GTS_PAUSE then
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
    local ChapterConf = _G.DataConfigManager:GetGrassTrialChapterConf(challengeData.current_chapter_id)
    if ChapterConf then
      self.NRCTextDes:SetText(string.format("\230\173\163\229\156\168\232\191\155\232\161\140\239\188\154%s", ChapterConf.name))
    else
      self.NRCTextDes:SetText("")
    end
  end
end

function UMG_HerbologyBadge_Entrance_C:_InitCountdown(periodData)
  local svrTimestamp = ActivityUtils.GetSvrTimestamp()
  local remainSeconds = 0
  if periodData and periodData.period_conf_id then
    local periodConf = _G.DataConfigManager:GetGrassTrailPeriodConf(periodData.period_conf_id)
    if periodConf then
      local endTimestamp = periodConf.start_time + parsePeriod(periodConf.period)
      remainSeconds = math.max(endTimestamp - svrTimestamp, 0)
    end
  else
    local svrTimeLocal = svrTimestamp + 28800
    local timeTable = os.date("!*t", svrTimeLocal)
    local wday = timeTable.wday
    local daysUntilMonday
    if 1 == wday then
      daysUntilMonday = 1
    else
      daysUntilMonday = 9 - wday
    end
    local todayStart = svrTimeLocal - timeTable.hour * 3600 - timeTable.min * 60 - timeTable.sec
    local nextMondayFourAM = todayStart + daysUntilMonday * 86400 + 14400
    local nextMondayTimestamp = nextMondayFourAM - 28800
    remainSeconds = math.max(nextMondayTimestamp - svrTimestamp, 0)
  end
  self.Time:InitializeData(remainSeconds, nil, true)
  self.Time:ShowCountDown()
end

function UMG_HerbologyBadge_Entrance_C:OnAnimationFinished(anim)
end

function UMG_HerbologyBadge_Entrance_C:UpdatePoint(current, limit)
  self.PetalMoney:InitNum(current, limit, "\230\156\172\229\145\168\231\167\175\229\136\134", false, nil, true, nil, true)
end

return UMG_HerbologyBadge_Entrance_C

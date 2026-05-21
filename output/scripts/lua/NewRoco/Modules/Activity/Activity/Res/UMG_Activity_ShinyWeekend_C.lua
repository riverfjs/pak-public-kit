local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_ShinyWeekend_C = Base:Extend("UMG_Activity_ShinyWeekend_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_Activity_ShinyWeekend_C:BindUIElements()
  local _activityInst = self.activityInst
  local uiElements = {}
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.promptText = self.Text_Describe
  if _activityInst:IsPreviewActivity() then
    uiElements.desireActivityType = Enum.ActivityType.ATP_SHINY_WEEKEND_PREVIEW
    uiElements.openAnimName = "In"
    uiElements.changeAnimName = "In"
  else
    uiElements.desireActivityType = Enum.ActivityType.ATP_SHINY_WEEKEND_START
    uiElements.openAnimName = "In_disappear"
    uiElements.changeAnimName = "In_show"
  end
  return uiElements
end

function UMG_Activity_ShinyWeekend_C:OnConstruct()
  if GlobalConfig.DebugOpenUI == true and self.CanvasPanel_152 then
    self.CanvasPanel_152:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  Base.OnConstruct(self)
  local _activityInst = self.activityInst
  if self.PastActivityBtn then
    self.PastActivityBtn:SetBtnText(_G.LuaText.ShinyWeekend_past_activities)
    self.PastActivityBtn:SetRedDotKey(300)
  end
  if _activityInst:IsPreviewActivity() then
    self.CanvasName:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RewardsPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.Foreshow then
      self.Foreshow:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.leaveForBtn:SetBtnText(_G.LuaText.ShinyWeekend_forecast)
    self.Text_Title_1:SetText(_G.LuaText.ShinyWeekend_title_unknow)
    self.PetImage:SetPath(_activityInst:GetShinyPetSecret())
    self.PetImage_2:SetPath(_activityInst:GetShinyPetSecret())
    self.PetImage_3:SetPath(_activityInst:GetShinyPetSecret())
  else
    self.CanvasName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RewardsPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.Foreshow then
      self.Foreshow:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.leaveForBtn:SetBtnText(_G.LuaText.ShinyWeekend_skip)
    local petName = ""
    local petBaseData = _G.DataConfigManager:GetPetbaseConf(_activityInst:GetPetBaseId())
    if petBaseData then
      petName = petBaseData.name
    end
    self.Text_Title_1:SetText(string.format(_G.LuaText.ShinyWeekend_title_know, petName))
    self.PetImage:SetPath(_activityInst:GetShinyPetShow())
    self.PetImage_2:SetPath(_activityInst:GetShinyPetShow())
    self.PetImage_3:SetPath(_activityInst:GetShinyPetShow())
    self.TextName:SetText(petName)
    self.RewardText:SetText(_G.LuaText.ShinyWeekend_HeadReward_title)
    self.Attr:InitGridView(ActivityUtils.CreatePetCommonAttrListData(petBaseData and petBaseData.unit_type, _activityInst:GetPetBloodId(), nil, PetUtils.CreateFakePetData(petBaseData and petBaseData.id)))
    self.AwardList:InitList(ActivityUtils.CreateActivityItemBaseDataForList(self, {
      _activityInst:GetIconRewardId()
    }))
    ActivityUtils.AdjustCtrlSize(self.BG, {
      175,
      326,
      477,
      627,
      702
    }, 1)
    self:OnRefreshPlayerShinyPetDayDataInfo(_activityInst)
  end
  self:AddButtonListener(self.ExamineBtn, self.OnClickShowPetData)
  if self.PastActivityBtn then
    self:AddButtonListener(self.PastActivityBtn.btnLevelUp, self.OnClickShowPreActivity)
  end
  self:AddButtonListener(self.leaveForBtn.btnLevelUp, self.OnClickJoinActivity)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshPlayerShinyPetDayDataInfo, self.OnRefreshPlayerShinyPetDayDataInfo)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshActivityShinyPetDayData, self.OnRefreshActivityShinyPetDayData)
  self:RegisterEvent(self, ActivityModuleEvent.ShinyWeekendActivityRewardReceived, self.OnShinyWeekendActivityRewardReceived)
end

function UMG_Activity_ShinyWeekend_C:OnDestruct()
  Base.OnDestruct(self)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshPlayerShinyPetDayDataInfo)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshActivityShinyPetDayData)
  self:UnRegisterEvent(self, ActivityModuleEvent.ShinyWeekendActivityRewardReceived)
end

function UMG_Activity_ShinyWeekend_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  if firstLoad then
    self.activityInst:SendZoneGetPlayerShinyPetDayInfoReq()
    self.activityInst:ReqGetPlayerActivityHistoryData(Enum.ActivityType.ATP_SHINY_WEEKEND_START)
  end
end

function UMG_Activity_ShinyWeekend_C:OnClickShowPetData()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_ShinyWeekend_C:OnClickShowPetData")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, self.activityInst:GetPetBaseId(), true, true)
end

function UMG_Activity_ShinyWeekend_C:OnClickShowPreActivity()
  _G.NRCAudioManager:PlaySound2DAuto(1001, "UMG_Activity_ShinyWeekend_C:OnClickShowPreActivity")
  local _activityInst = self.activityInst
  local historyData = _activityInst:GetActivityHistoryData()
  if historyData and #historyData > 0 then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenPastActivity, _activityInst)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.ShinyWeekend_no_content_tip)
  end
end

function UMG_Activity_ShinyWeekend_C:OnClickJoinActivity()
  local _activityInst = self.activityInst
  if _activityInst:IsPreviewActivity() then
    _G.NRCAudioManager:PlaySound2DAuto(1253, "UMG_Activity_ShinyWeekend_C:OnClickJoinActivity")
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenPastActivityHearsay, _activityInst:GetTeaserText())
  else
    _G.NRCAudioManager:PlaySound2DAuto(1077, "UMG_Activity_ShinyWeekend_C:OnClickJoinActivity")
    _activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.Join)
  end
end

function UMG_Activity_ShinyWeekend_C:OnRefreshPlayerShinyPetDayDataInfo(_activityInst)
  if not _activityInst or _activityInst ~= self.activityInst then
    return
  end
  local doubleRewardRemain = 0
  local doubleRewardStorage = 0
  local playerShinyPetDayInfo = _activityInst:GetPlayerShinyPetDayInfo()
  if playerShinyPetDayInfo then
    doubleRewardRemain = playerShinyPetDayInfo.remaining_doule_times or 0
    doubleRewardStorage = playerShinyPetDayInfo.total_double_times or 0
  end
  self.Desc:SetText(string.format(_G.LuaText.ShinyWeekend_DoubleStock_tip, doubleRewardRemain, doubleRewardStorage))
end

function UMG_Activity_ShinyWeekend_C:OnRefreshActivityShinyPetDayData(_activityInst, _activityId, _shinyPetDayData)
  if not _activityInst or _activityInst ~= self.activityInst then
    return
  end
  if _activityInst:GetActivityId() == _activityId then
    self.AwardList:OpItemByIndex(1)
  end
end

function UMG_Activity_ShinyWeekend_C:OnShinyWeekendActivityRewardReceived(_activityInst, _activityId, _shinyPetDayData)
  if not _activityInst or _activityInst ~= self.activityInst then
    return
  end
  if _activityInst:GetActivityId() == _activityId then
  end
end

function UMG_Activity_ShinyWeekend_C:OnItemUpdate(_itemInst, _index, _rewardId)
  local _activityInst = self.activityInst
  if _activityInst and _itemInst then
    local rewardData = ActivityUtils.GetActivityRewardData(_rewardId, true)
    _itemInst:SetImage(rewardData.showIcon)
    _itemInst:SetRedPoint(ActivityEnum.RedPointKey.DetailReward, {
      _activityInst:GetActivityId()
    })
  end
  self:OnItemOp(_itemInst, _index, _rewardId)
end

function UMG_Activity_ShinyWeekend_C:OnItemSelected(_itemInst, _index, _rewardId, _bSelected)
  if _bSelected then
    local _activityInst = self.activityInst
    if _activityInst then
      local activityShinyPetDayData = _activityInst:GetActivityShinyPetDayData()
      if activityShinyPetDayData and 1 == activityShinyPetDayData.received_reward then
        _G.NRCAudioManager:PlaySound2DAuto(1144, "UMG_Activity_ShinyWeekend_C:OnItemSelected")
        _activityInst:SendZoneReceivePlayerActivityShinyPetDayRewardReq(_activityInst:GetActivityId())
      else
        ActivityUtils.ShowRewardTips(_activityInst:GetIconRewardId())
      end
    end
  end
end

function UMG_Activity_ShinyWeekend_C:OnItemOp(_itemInst, _index, _rewardId, _opType)
  local completed = false
  if _itemInst then
    local _activityInst = self.activityInst
    if _activityInst then
      local activityShinyPetDayData = _activityInst:GetActivityShinyPetDayData()
      if activityShinyPetDayData then
        completed = 2 == activityShinyPetDayData.received_reward
      end
    end
    _itemInst:SetCompleteStatus(completed)
  end
end

return UMG_Activity_ShinyWeekend_C

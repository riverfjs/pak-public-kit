local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_ElfParadise_C = Base:Extend("UMG_Activity_ElfParadise_C")

function UMG_Activity_ElfParadise_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_PET_TRIP
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.timeRemainingRoot = self.time
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_ElfParadise_C:OnConstruct()
  Base.OnConstruct(self)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshActivityPetTripData, self.InitPanel)
  self:RegisterEvent(self, ActivityModuleEvent.GetActivityPetTripDataRewardSuccess, self.GetRewardSuccess)
  self:AddButtonListener(self.BtnTimePet, self.OnClickTimePet)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnClickTrace)
end

function UMG_Activity_ElfParadise_C:GetRewardSuccess()
end

function UMG_Activity_ElfParadise_C:OnClickTrace()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ElfParadise_C:OnClickTrace")
  if self.ShowType == self.activityInst.ActivityShowStatus.TripIng then
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenElfAdventure)
  else
    if self.activityInst:IsActivityInactive() then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.activity_drop_tips_takeoff)
      return
    end
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenElfParadiseRewards)
  end
end

function UMG_Activity_ElfParadise_C:OnClickTimePet()
  _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenElfParadiseEventReview, self.activityInst:GetPetTripLotteryResult())
end

function UMG_Activity_ElfParadise_C:OnDestruct()
  if self.DrawTheWinnerTimer then
    _G.TimerManager:RemoveTimer(self.DrawTheWinnerTimer)
    self.DrawTheWinnerTimer = nil
  end
  Base.OnDestruct(self)
end

function UMG_Activity_ElfParadise_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  self:PlayAnimation(self.In)
  self.FirstTime = true
  self:InitPanel()
end

function UMG_Activity_ElfParadise_C:SetBtnClick(Enable, text)
  self.TraceBtn:SetClickAble(Enable)
  if Enable then
    self.TraceBtn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
  else
    self.TraceBtn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
  end
  self.TraceBtn:SetBtnText(text)
end

function UMG_Activity_ElfParadise_C:OnDisable()
  Base.OnDisable(self)
end

function UMG_Activity_ElfParadise_C:SetRewardList(ShowType, wish_choice, PetTripAwardConf, List)
  if 0 == wish_choice then
    local rewardList = {}
    local reward = {}
    reward.type = ShowType
    reward.data = nil
    reward.MeetStandard = true
    table.insert(rewardList, reward)
    List:InitGridView(rewardList)
  else
    local rewardGroup = PetTripAwardConf and PetTripAwardConf.condition_group or {}
    local rewardList = {}
    local reward = {}
    reward.type = ShowType
    reward.data = rewardGroup[wish_choice]
    reward.MeetStandard = true
    table.insert(rewardList, reward)
    List:InitGridView(rewardList)
  end
end

function UMG_Activity_ElfParadise_C:InitPanel()
  local ShowType, activityShowTime = self.activityInst:GetShowActivityTime()
  self.ShowType = ShowType
  local petTripConf = self.activityInst:GetActivityPetTripConf()
  self.activityData = self.activityInst:GetActivityData()
  if self.activityInst:GetPetTripLotteryResult() then
    self.BtnTimePet:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BtnTimePet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local PetTripAwardConf = self.activityInst:GetPetTripAwardConf()
  if not petTripConf then
    Log.Error("UMG_Activity_ElfParadise_C:InitPanel petTripConf is nil")
    return
  end
  if not self.activityData then
    Log.Error("UMG_Activity_ElfParadise_C:InitPanel activityData is nil")
    return
  end
  if not PetTripAwardConf then
    Log.Error("UMG_Activity_ElfParadise_C:InitPanel PetTripAwardConf is nil")
    return
  end
  local happy_value = self.activityData.happy_value or 0
  self.List1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.List2:SetVisibility(UE4.ESlateVisibility.Visible)
  if ShowType == self.activityInst.ActivityShowStatus.TripIng then
    local SvrTime = ActivityUtils.GetSvrTimestamp()
    local stop_time = ActivityUtils.ToTimestamp(activityShowTime)
    local day = math.floor((stop_time - SvrTime) / 86400) + 1
    self.TraceBtn:SetTitleTextAndIcon(nil, nil, nil, nil, string.format(LuaText.pet_trip_3, day), nil)
    self.Time_Tips:SetText(petTripConf.condition)
    self.ProgressText:SetText(string.format("%d/%d", happy_value, petTripConf.condition))
    self.TaskProgress:SetPercent(happy_value / petTripConf.condition)
    if happy_value >= petTripConf.condition then
      self.RewardsSwitche:SetActiveWidgetIndex(1)
      self:SetRewardList(ShowType, self.activityData.wish_choice or 0, PetTripAwardConf, self.List2)
    else
      self.RewardsSwitche:SetActiveWidgetIndex(0)
      local rewardGroup = PetTripAwardConf and PetTripAwardConf.condition_group or {}
      local rewardList = {}
      for i, v in pairs(rewardGroup) do
        if i <= 3 then
          local reward = {}
          reward.type = ShowType
          reward.MeetStandard = false
          reward.data = v
          table.insert(rewardList, reward)
        end
      end
      self.List1:InitGridView(rewardList)
    end
    self:SetBtnClick(true, LuaText.pet_trip_4)
    self.TraceBtn.RedDot:SetupKey(481)
    self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
    if not self.DrawTheWinnerTimer then
      self.DrawTheWinnerTimer = _G.TimerManager:CreateTimer(self, "DrawTheWinnerTimer", math.maxinteger, self.DrawTheWinnerTimeUpdate, self.DrawTheWinnerTimeFinished, 1)
    end
  elseif ShowType == self.activityInst.ActivityShowStatus.DrawTheWinner then
    if happy_value < petTripConf.condition then
      self.TraceBtn:SetTitleTextAndIcon()
      self.Time_Tips:SetText(petTripConf.condition)
      self.ProgressText:SetText(string.format("%d/%d", happy_value, petTripConf.condition))
      self.TaskProgress:SetPercent(happy_value / petTripConf.condition)
      self.RewardsSwitche:SetActiveWidgetIndex(0)
      local rewardGroup = PetTripAwardConf and PetTripAwardConf.condition_group or {}
      local rewardList = {}
      for i, v in pairs(rewardGroup) do
        if i <= 3 then
          local reward = {}
          reward.type = ShowType
          reward.MeetStandard = false
          reward.data = v
          table.insert(rewardList, reward)
        end
      end
      self.List1:InitGridView(rewardList)
      self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
      self:SetBtnClick(false, LuaText.pet_trip_55)
    else
      self.FirstTime = false
      local SvrTime = ActivityUtils.GetSvrTimestamp()
      local stop_time = ActivityUtils.ToTimestamp(activityShowTime)
      local leftTime = stop_time - SvrTime
      local hour = math.floor(leftTime / 3600)
      local minute = math.floor((leftTime - 3600 * hour) / 60)
      local sec = math.floor(leftTime - 3600 * hour - 60 * minute)
      local timeStr = string.format("%02d:%02d:%02d", hour, minute, sec)
      self.RewardsSwitche:SetActiveWidgetIndex(1)
      local wish_choice = self.activityData.wish_choice and 0 ~= self.activityData.wish_choice and self.activityData.wish_choice or 4
      self.TraceBtn:SetTitleTextAndIcon(nil, nil, nil, nil, string.format(LuaText.pet_trip_7, timeStr), nil)
      self:SetRewardList(ShowType, wish_choice, PetTripAwardConf, self.List2)
      self:SetBtnClick(false, LuaText.pet_trip_8)
      self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
      if not self.DrawTheWinnerTimer then
        self.DrawTheWinnerTimer = _G.TimerManager:CreateTimer(self, "DrawTheWinnerTimer", math.maxinteger, self.DrawTheWinnerTimeUpdate, self.DrawTheWinnerTimeFinished, 1)
      end
    end
    self.TraceBtn.RedDot:SetupKey(482)
  elseif (not self.activityData.lottery_result or not self.activityData.lottery_result.goods_id) and happy_value < petTripConf.condition then
    self.TraceBtn:SetTitleTextAndIcon()
    self.Time_Tips:SetText(petTripConf.condition)
    self.ProgressText:SetText(string.format("%d/%d", happy_value, petTripConf.condition))
    self.TaskProgress:SetPercent(happy_value / petTripConf.condition)
    self.RewardsSwitche:SetActiveWidgetIndex(0)
    local rewardGroup = PetTripAwardConf and PetTripAwardConf.condition_group or {}
    local rewardList = {}
    for i, v in pairs(rewardGroup) do
      if i <= 3 then
        local reward = {}
        reward.type = ShowType
        reward.MeetStandard = false
        reward.data = v
        table.insert(rewardList, reward)
      end
    end
    self.List1:InitGridView(rewardList)
    self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self:SetBtnClick(false, LuaText.pet_trip_55)
    if self.DrawTheWinnerTimer then
      _G.TimerManager:RemoveTimer(self.DrawTheWinnerTimer)
      self.DrawTheWinnerTimer = nil
    end
  else
    if self.activityData.lottery_result and self.activityData.lottery_result.recieved_award then
      self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
      self:SetBtnClick(true, LuaText.Role_Info_Right_Btn)
    elseif not self.activityData.lottery_result then
      self:SetBtnClick(false, LuaText.pet_trip_8)
      self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
    else
      self:SetBtnClick(true, LuaText.pet_trip_8)
      self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(1)
    end
    self.RewardsSwitche:SetActiveWidgetIndex(1)
    local wish_choice = self.activityData.wish_choice and 0 ~= self.activityData.wish_choice and self.activityData.wish_choice or 4
    self:SetRewardList(ShowType, wish_choice, PetTripAwardConf, self.List2)
    self.TraceBtn.RedDot:SetupKey(482)
    self.TraceBtn:SetTitleTextAndIcon(nil, nil, nil, nil, nil, nil)
    if not self.activityData.lottery_result then
      if not self.DrawTheWinnerTimer then
        self.DrawTheWinnerTimer = _G.TimerManager:CreateTimer(self, "DrawTheWinnerTimer", math.maxinteger, self.DrawTheWinnerTimeUpdate, self.DrawTheWinnerTimeFinished, 1)
      end
    elseif self.DrawTheWinnerTimer then
      _G.TimerManager:RemoveTimer(self.DrawTheWinnerTimer)
      self.DrawTheWinnerTimer = nil
    end
  end
  self.waitForSyncRsp = false
end

function UMG_Activity_ElfParadise_C:DrawTheWinnerTimeUpdate()
  local ShowType, activityShowTime = self.activityInst:GetShowActivityTime()
  if ShowType == self.activityInst.ActivityShowStatus.TripIng then
  elseif ShowType == self.activityInst.ActivityShowStatus.DrawTheWinner then
    local happy_value = self.activityData.happy_value or 0
    local petTripConf = self.activityInst:GetActivityPetTripConf()
    if happy_value < petTripConf.condition then
      if self.activityInst then
        self.activityInst:SyncActivityDataOnAvailable()
      end
      if self.DrawTheWinnerTimer then
        _G.TimerManager:RemoveTimer(self.DrawTheWinnerTimer)
        self.DrawTheWinnerTimer = nil
      end
    else
      if self.FirstTime then
        self.FirstTime = false
        self.RewardsSwitche:SetActiveWidgetIndex(1)
        local PetTripAwardConf = self.activityInst:GetPetTripAwardConf()
        local wish_choice = self.activityData.wish_choice and 0 ~= self.activityData.wish_choice and self.activityData.wish_choice or 4
        self:SetRewardList(ShowType, wish_choice, PetTripAwardConf, self.List2)
        self:SetBtnClick(false, LuaText.pet_trip_8)
        self.TraceBtn.NRCSwitcher_0:SetActiveWidgetIndex(0)
      end
      local SvrTime = ActivityUtils.GetSvrTimestamp()
      local stop_time = ActivityUtils.ToTimestamp(activityShowTime)
      local leftTime = stop_time - SvrTime
      local hour = math.floor(leftTime / 3600)
      local minute = math.floor((leftTime - 3600 * hour) / 60)
      local sec = math.floor(leftTime - 3600 * hour - 60 * minute)
      local timeStr = string.format("%02d:%02d:%02d", hour, minute, sec)
      self.TraceBtn:SetTitleTextAndIcon(nil, nil, nil, nil, string.format(LuaText.pet_trip_7, timeStr), nil)
    end
  else
    if self.waitForSyncRsp then
      return
    end
    if self.activityInst then
      self.waitForSyncRsp = true
      self.activityInst:SyncActivityDataOnAvailable()
    end
  end
end

function UMG_Activity_ElfParadise_C:DrawTheWinnerTimeFinished()
end

return UMG_Activity_ElfParadise_C

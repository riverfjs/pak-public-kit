local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_CollegeGlory_C = Base:Extend("UMG_Activity_CollegeGlory_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local SwitchPanelShowType = {Init = 1, Normal = 2}

function UMG_Activity_CollegeGlory_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_MIX
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.BG
  uiElements.timeRemainingRoot = self.shijian
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  local activityInst = self.activityInst
  if activityInst and activityInst:GetJoinStatus() ~= ActivityEnum.MixActivityJoinStatus.Init and self.panelShowType ~= SwitchPanelShowType.Init then
    uiElements.openAnimName = "TeachingTasks_In"
    uiElements.changeAnimName = "TeachingTasks_In"
  else
    uiElements.openAnimName = "Initial_In"
    uiElements.changeAnimName = "Initial_In"
    uiElements.closeAnimName = "Initial_Out"
  end
  return uiElements
end

function UMG_Activity_CollegeGlory_C:OnConstruct()
  Base.OnConstruct(self)
  self:AddButtonListener(self.ChooseCollegeBtn.btnLevelUp, self.OnChooseCollegeBtnClick)
  self:AddButtonListener(self.RecommendedTasksBtn, self.OnRecommendedTasksBtnClick)
  self:AddButtonListener(self.BtnExchangeCollege, self.OnExchangeCollegeBtnClick)
  self:AddButtonListener(self.JumpButton, self.OnJumpButtonClick)
  self:AddButtonListener(self.ClassRepresentativeBtn, self.OnClickSlot1)
  self:AddButtonListener(self.ChallengeBtn, self.OnClickSlot2)
  self:AddButtonListener(self.LimitedTimeTaskBtn, self.OnClickSlot3)
  self:AddButtonListener(self.CreditStoreBtn, self.OnClickSlot4)
  self:AddButtonListener(self.BtnCollegeRanking, self.OnClickSlot5)
  self.ClassRepresentativeBtn.OnPressed:Add(self, self.OnSlot1Pressed)
  self.ClassRepresentativeBtn.OnReleased:Add(self, self.OnSlot1Released)
  self.ChallengeBtn.OnPressed:Add(self, self.OnSlot2Pressed)
  self.ChallengeBtn.OnReleased:Add(self, self.OnSlot2Released)
  self.LimitedTimeTaskBtn.OnPressed:Add(self, self.OnSlot3Pressed)
  self.LimitedTimeTaskBtn.OnReleased:Add(self, self.OnSlot3Released)
  self.CreditStoreBtn.OnPressed:Add(self, self.OnSlot4Pressed)
  self.CreditStoreBtn.OnReleased:Add(self, self.OnSlot4Released)
  self:RegisterEvent(self, ActivityModuleEvent.MixActivitySvrDataChanged, self.OnMixActivitySvrDataChanged)
  self:RegisterEvent(self, ActivityModuleEvent.MixActivityJoinStatusChanged, self.OnMixActivityJoinStatusChanged)
  self:RegisterEvent(self, ActivityModuleEvent.MixActivitySelectFactionChanged, self.OnSelectFactionChanged)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnProgressVItemChanged)
  local activityInst = self.activityInst
  local mixConf = activityInst:GetMixConf()
  self.ChooseCollegeBtn:SetBtnText(mixConf and mixConf.go_faction_option_name or "")
  self.TextTitle:SetText(_G.LuaText.activity_mix_CollegeGlory_des1)
  self.TextDetails:SetText(_G.LuaText.activity_mix_CollegeGlory_des2)
  self.slotTitle:SetText(_G.LuaText.activity_CollegeGlory_exchange_option_name)
  self.RedDot_1:SetupKey(452, nil, {
    {
      tostring(activityInst:GetActivityId())
    }
  })
  local slotCtrlGroup = {
    self.ClassRepresentativeBtn,
    self.ChallengeBtn,
    self.LimitedTimeTaskBtn,
    self.CreditStoreBtn,
    self.BtnCollegeRanking
  }
  for index, slotCtrl in ipairs(slotCtrlGroup) do
    local slotData = mixConf and mixConf.slot_group[index]
    if slotData then
      self:SetSlotData(index, slotData)
    else
      slotCtrl:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local classScheduleCountDownObject = activityInst:GetClassScheduleCountDownObject()
  if classScheduleCountDownObject then
    classScheduleCountDownObject:BindCtrl(self.RemainingTime, function(leftSeconds)
      if leftSeconds > 0 then
        return string.format(_G.LuaText.Activity_CollegeGlory_schedule_RefreshRule_txt3, ActivityUtils.GetTimeFormatStr(leftSeconds))
      end
    end, nil, self.OnClassScheduleCountDown, self)
  end
  local recommendTaskQuery = activityInst:GetRecommendTaskQueryHandler()
  self.RecommendedTasksBtn:SetVisibility(recommendTaskQuery and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self:OnRecommendTaskStatusChanged(recommendTaskQuery and recommendTaskQuery:CheckAllTaskDone() or false)
  self:OnMixActivitySvrDataChanged(activityInst)
  self:OnSelectFactionChanged()
end

function UMG_Activity_CollegeGlory_C:OnDestruct()
  Base.OnDestruct(self)
  self:UnRegisterEvent(self, ActivityModuleEvent.MixActivitySvrDataChanged)
  self:UnRegisterEvent(self, ActivityModuleEvent.MixActivityJoinStatusChanged)
  self:UnRegisterEvent(self, ActivityModuleEvent.MixActivitySelectFactionChanged)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnProgressVItemChanged)
  local activityInst = self.activityInst
  if activityInst then
    local classScheduleCountDownObject = activityInst:GetClassScheduleCountDownObject()
    if classScheduleCountDownObject then
      classScheduleCountDownObject:UnbindCtrl(self.RemainingTime)
    end
  end
  self.ClassRepresentativeBtn.OnPressed:Clear()
  self.ClassRepresentativeBtn.OnReleased:Clear()
  self.ChallengeBtn.OnPressed:Clear()
  self.ChallengeBtn.OnReleased:Clear()
  self.LimitedTimeTaskBtn.OnPressed:Clear()
  self.LimitedTimeTaskBtn.OnReleased:Clear()
  self.CreditStoreBtn.OnPressed:Clear()
  self.CreditStoreBtn.OnReleased:Clear()
end

function UMG_Activity_CollegeGlory_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  local activityInst = self.activityInst
  local recommendTaskQuery = activityInst and activityInst:GetRecommendTaskQueryHandler()
  if recommendTaskQuery then
    recommendTaskQuery:QueryTaskStatus(self, self.OnRecommendTaskStatusChanged)
  end
  local activityId = activityInst and activityInst:GetActivityId()
  if activityId then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 417, tostring(activityId), true)
  end
  if not firstLoad then
    self:SwitchPanelShowByStatus()
  end
end

function UMG_Activity_CollegeGlory_C:IsSlotLocked(slotData)
  if slotData.initial_unlock then
    return false
  end
  return self.activityInst:GetJoinStatus() ~= ActivityEnum.MixActivityJoinStatus.Normal
end

function UMG_Activity_CollegeGlory_C:UpdateSlotData(index, slotData)
  local unlockImg = self["slotNotUnlocked_" .. index]
  if unlockImg then
    local isLocked = self:IsSlotLocked(slotData)
    unlockImg:SetVisibility(isLocked and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
  local activityInst = self.activityInst
  if activityInst and 1 == index and self.slotTitle_1 then
    local joinStatus = activityInst:GetJoinStatus()
    local mixConf = activityInst:GetMixConf()
    if joinStatus ~= ActivityEnum.MixActivityJoinStatus.Normal then
      self.slotTitle_1:SetText(mixConf and mixConf.go_task_option_name or "")
    else
      local _, slotName = ActivityUtils.GetActivityOptionData(slotData.option_id)
      self.slotTitle_1:SetText(slotName)
    end
  end
end

function UMG_Activity_CollegeGlory_C:SetSlotData(index, slotData)
  local title = self["slotTitle_" .. index]
  if title then
    local _, slotName = ActivityUtils.GetActivityOptionData(slotData.option_id)
    title:SetText(slotName or "")
  end
  self:UpdateSlotData(index, slotData)
  local activityInst = self.activityInst
  if 1 == index then
    self.slotHint_1:SetText(slotData.slot_des)
    self.RedDot:SetupKey(454, nil, {
      {
        tostring(activityInst:GetActivityId())
      }
    })
  elseif 4 == index then
    if slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_CHECK_VITEM and slotData.params and 0 ~= slotData.params[1] then
      local iconPath = ActivityUtils.GetItemIconAndQuality(_G.Enum.GoodsType.GT_VITEM, slotData.params[1])
      local vItemCnt = _G.DataModelMgr.PlayerDataModel:GetVItemCount(slotData.params[1])
      self.CurrencyIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CurrencyIcon:SetPath(iconPath)
      self.CurrencyText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CurrencyText:SetText(vItemCnt)
    else
      self.CurrencyIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CurrencyText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Activity_CollegeGlory_C:OnSlotClick(slotIndex)
  local realClickSlot = false
  local activityInst = self.activityInst
  if activityInst and not activityInst:IsUnlockAdvance() and ActivityUtils.OpenActivityRecommendTaskList(activityInst) then
    return realClickSlot
  end
  realClickSlot = true
  local mixConf = activityInst and activityInst:GetMixConf()
  if mixConf then
    local slotData = mixConf.slot_group and mixConf.slot_group[slotIndex]
    if slotData then
      if self:IsSlotLocked(slotData) then
        if 1 == slotIndex then
          activityInst:TrackCurrentMustDoTask()
        else
          _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, mixConf.unlock_tips)
        end
      else
        ActivityUtils.DoActivityOptionCmd(slotData.option_id)
      end
    end
  end
  return realClickSlot
end

function UMG_Activity_CollegeGlory_C:RefreshCollegeItems()
  local collegeItems = {}
  local activityInst = self.activityInst
  if activityInst then
    local factionCfg = activityInst:GetFactionConf()
    if factionCfg then
      for _, factionGroup in ipairs(factionCfg.faction_group) do
        local item = {}
        item.name = factionGroup.name
        item.badge = factionGroup.faction_icon
        local finishTimestamp = activityInst:GetFactionFinishedTimestamp(factionGroup.faction_type)
        if finishTimestamp and finishTimestamp > 0 then
          item.finished = true
          local timeDetailData = ActivityUtils.ToTimeDetailData(finishTimestamp)
          item.finishedTime = string.safeFormat(_G.LuaText.Activity_CollegeGlory_faction_finish, timeDetailData.year, timeDetailData.month, timeDetailData.day)
        end
        table.insert(collegeItems, item)
      end
    end
  end
  self.CollegeList:InitGridView(collegeItems)
end

function UMG_Activity_CollegeGlory_C:SwitchPanelShow(showType)
  local panelChanged = self.panelShowType ~= showType
  self.panelShowType = showType
  if showType == SwitchPanelShowType.Init then
    self:RefreshCollegeItems()
    self.NRCSwitcher_35:SetActiveWidgetIndex(0)
  elseif showType == SwitchPanelShowType.Normal then
    self.NRCSwitcher_35:SetActiveWidgetIndex(1)
  end
  if panelChanged then
    self:ReBindUIElements(true)
  end
end

function UMG_Activity_CollegeGlory_C:SwitchPanelShowByStatus()
  local activityInst = self.activityInst
  if not activityInst then
    return
  end
  local joinStatus = activityInst:GetJoinStatus()
  if joinStatus == ActivityEnum.MixActivityJoinStatus.Init then
    self:SwitchPanelShow(SwitchPanelShowType.Init)
  else
    local mixData = activityInst:GetMixData()
    if mixData and mixData.experience_card_popup then
      self:SwitchPanelShow(SwitchPanelShowType.Init)
      activityInst:SendZoneFinishExperienceCardPopupReq()
    else
      self:SwitchPanelShow(SwitchPanelShowType.Normal)
    end
  end
end

function UMG_Activity_CollegeGlory_C:OnChooseCollegeBtnClick()
  local activityInst = self.activityInst
  local factionConf = activityInst and activityInst:GetFactionConf()
  if factionConf then
    local collegeCampPanelData = {}
    collegeCampPanelData.defaultTips = factionConf.select_des
    collegeCampPanelData.leftBtnText = _G.LuaText.umg_dialog_1
    collegeCampPanelData.rightBtnText = _G.LuaText.umg_dialog_2
    collegeCampPanelData.clickOkCallback = _G.MakeWeakFunctor(self, self.OnSelectCollegeCamp)
    if factionConf.faction_group then
      collegeCampPanelData.itemData = {}
      for _, factionGroup in ipairs(factionConf.faction_group) do
        local item = {}
        item.imagePath = _G.DataModelMgr.PlayerDataModel:IsMale() and factionGroup.select_img or factionGroup.select_img_female
        item.selectTips = factionGroup.select_tips
        item.customData = factionGroup.faction_type
        item.extraDataIcon = factionGroup.faction_icon
        item.extraDataDesc = factionGroup.name
        local finishTimestamp = activityInst:GetFactionFinishedTimestamp(factionGroup.faction_type)
        if finishTimestamp and finishTimestamp > 0 then
          item.isCollected = true
          item.disableChoose = true
        end
        table.insert(collegeCampPanelData.itemData, item)
      end
    end
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    collegeCampPanelData.cxt = DialogContext()
    collegeCampPanelData.cxt:SetTitle(_G.LuaText.Activity_CollegeGlory_faction_DoubleCheck_title):SetContent(_G.LuaText.Activity_CollegeGlory_faction_DoubleCheck):SetContentTextJustify(UE4.ETextJustify.Center):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(_G.LuaText.YES, _G.LuaText.NO):SetClickAnywhereClose(true):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenCampSelectPanel, collegeCampPanelData)
  end
end

function UMG_Activity_CollegeGlory_C:OnSelectCollegeCamp(selectItem)
  if not selectItem or not selectItem.customData then
    return
  end
  local activityInst = self.activityInst
  if activityInst then
    activityInst:SendZoneChooseActivityFactionReq(selectItem.customData)
  end
end

function UMG_Activity_CollegeGlory_C:OnRecommendedTasksBtnClick()
  ActivityUtils.OpenActivityRecommendTaskList(self.activityInst)
end

function UMG_Activity_CollegeGlory_C:OnExchangeCollegeBtnClick()
  self:SwitchPanelShow(SwitchPanelShowType.Init)
  local activityInst = self.activityInst
  local activityId = activityInst and activityInst:GetActivityId()
  if activityId then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 450, tostring(activityId), true)
  end
end

function UMG_Activity_CollegeGlory_C:OnJumpButtonClick()
  local activityInst = self.activityInst
  if activityInst and activityInst:GetJoinStatus() == ActivityEnum.MixActivityJoinStatus.Init then
    return
  end
  self:SwitchPanelShow(SwitchPanelShowType.Normal)
end

function UMG_Activity_CollegeGlory_C:OnMixActivitySvrDataChanged(activityInst)
  if not activityInst or self.activityInst ~= activityInst then
    return
  end
  local initFactionConf = activityInst and activityInst:GetInitialFactionConf()
  self.SelectDescription:SetText(initFactionConf and initFactionConf.name or "")
  local mixData = activityInst:GetMixData()
  if mixData then
    if mixData.can_choose_new_faction then
      self.BtnExchangeCollege:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BtnExchangeCollege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if mixData.experience_card_popup then
      self:SwitchPanelShowByStatus()
    end
  end
end

function UMG_Activity_CollegeGlory_C:OnMixActivityJoinStatusChanged(activityInst)
  if not activityInst or self.activityInst ~= activityInst then
    return
  end
  self:SwitchPanelShowByStatus()
  local mixConf = activityInst:GetMixConf()
  if mixConf then
    for index, slotData in ipairs(mixConf.slot_group) do
      self:UpdateSlotData(index, slotData)
    end
  end
  local classScheduleCountDownObject = activityInst:GetClassScheduleCountDownObject()
  if classScheduleCountDownObject then
    classScheduleCountDownObject:ForceRefreshLeftTime()
  end
end

function UMG_Activity_CollegeGlory_C:OnRecommendTaskStatusChanged(allFinished)
  self.RecommendedTasks:SetVisibility(allFinished and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Activity_CollegeGlory_C:OnSelectFactionChanged()
  local activityInst = self.activityInst
  if activityInst and activityInst:GetSelectFaction() ~= ProtoEnum.ActivityFaction.FACTION_NONE then
    local selectFactionConf = activityInst:GetSelectFactionConf()
    local initFactionConf = activityInst:GetInitialFactionConf()
    if selectFactionConf == initFactionConf or nil == selectFactionConf then
      self.CanvasExchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.CanvasExchange:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.ExchangeCollege:SetText(selectFactionConf and selectFactionConf.name or "")
    end
    if selectFactionConf then
      self.CharacterIllustration:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CharacterIllustration:SetPath(_G.DataModelMgr.PlayerDataModel:IsMale() and selectFactionConf.add_img_male or selectFactionConf.add_img_female)
    else
      self.CharacterIllustration:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if selectFactionConf and not activityInst:GetFactionFinishedTimestamp(selectFactionConf.faction_type) then
      self.BtnExchangeCollege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local classScheduleCountDownObject = activityInst:GetClassScheduleCountDownObject()
    if classScheduleCountDownObject then
      classScheduleCountDownObject:ForceRefreshLeftTime()
    end
  end
  self:SwitchPanelShowByStatus()
end

function UMG_Activity_CollegeGlory_C:OnProgressVItemChanged()
  local activityInst = self.activityInst
  local mixCfg = activityInst and activityInst:GetMixConf()
  if mixCfg then
    for _, slotData in ipairs(mixCfg.slot_group or {}) do
      if slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_CHECK_VITEM and slotData.params and 0 ~= slotData.params[1] then
        local vItemCnt = _G.DataModelMgr.PlayerDataModel:GetVItemCount(slotData.params[1])
        self.CurrencyText:SetText(vItemCnt)
        break
      end
    end
  end
end

function UMG_Activity_CollegeGlory_C:OnClassScheduleCountDown(_ctrl, _leftTimeStr)
  if _ctrl == self.RemainingTime then
    self.RemainingTimeRoot:SetVisibility(not string.IsNilOrEmpty(_leftTimeStr) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_CollegeGlory_C:OnClickSlot1()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_NPCShop_Temp_C:OnTitleBtnClick")
  if self:OnSlotClick(1) then
    local activityInst = self.activityInst
    local activityId = activityInst and activityInst:GetActivityId()
    if activityId then
      _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 416, tostring(activityId), true)
      _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 449, tostring(activityId), true)
    end
  end
end

function UMG_Activity_CollegeGlory_C:OnClickSlot2()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_NPCShop_Temp_C:OnTitleBtnClick")
  self:OnSlotClick(2)
end

function UMG_Activity_CollegeGlory_C:OnClickSlot3()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_NPCShop_Temp_C:OnTitleBtnClick")
  self:OnSlotClick(3)
end

function UMG_Activity_CollegeGlory_C:OnClickSlot4()
  self:OnSlotClick(4)
end

function UMG_Activity_CollegeGlory_C:OnClickSlot5()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_Activity_CollegeCamp_Item_C:OnClickChoose")
  self:OnSlotClick(5)
end

function UMG_Activity_CollegeGlory_C:OnSlot1Pressed()
  self:PlayPressedOrReleasedAnimation(true, self.Press_1, self.Up_1)
end

function UMG_Activity_CollegeGlory_C:OnSlot1Released()
  self:PlayPressedOrReleasedAnimation(false, self.Press_1, self.Up_1)
end

function UMG_Activity_CollegeGlory_C:OnSlot2Pressed()
  self:PlayPressedOrReleasedAnimation(true, self.Press_2, self.Up_2)
end

function UMG_Activity_CollegeGlory_C:OnSlot2Released()
  self:PlayPressedOrReleasedAnimation(false, self.Press_2, self.Up_2)
end

function UMG_Activity_CollegeGlory_C:OnSlot3Pressed()
  self:PlayPressedOrReleasedAnimation(true, self.Press_3, self.Up_3)
end

function UMG_Activity_CollegeGlory_C:OnSlot3Released()
  self:PlayPressedOrReleasedAnimation(false, self.Press_3, self.Up_3)
end

function UMG_Activity_CollegeGlory_C:OnSlot4Pressed()
  self:PlayPressedOrReleasedAnimation(true, self.Press_4, self.Up_4)
end

function UMG_Activity_CollegeGlory_C:OnSlot4Released()
  self:PlayPressedOrReleasedAnimation(false, self.Press_4, self.Up_4)
end

return UMG_Activity_CollegeGlory_C

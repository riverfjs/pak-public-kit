local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local UMG_Activity_ElvenAmbassador_C = Base:Extend("UMG_Activity_ElvenAmbassador_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_ElvenAmbassador_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_BASE_MIX
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.BG
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.closeAnimName = "Out"
  return uiElements
end

function UMG_Activity_ElvenAmbassador_C:OnConstruct()
  Base.OnConstruct(self)
  self:AddButtonListener(self.Button1, self.OnClickSlot1)
  self:AddButtonListener(self.Button2, self.OnClickSlot2)
  self:AddButtonListener(self.Button3, self.OnClickSlot3)
  self:AddButtonListener(self.Button2_1, self.OnClickTaskSlot)
  self:AddButtonListener(self.ViewPropsBtn, self.OnClickRewardBtn)
  self.mixCfg = self.activityInst:GetMixCfg()
  self.PreTaskFinishSlotData = nil
  self.RedPointData = {}
  self.SlotTaskData = nil
  self.SlotEggRewardData = nil
end

function UMG_Activity_ElvenAmbassador_C:OnEnable(firstLoad)
  Base.OnEnable(self)
  if self.mixCfg and self.mixCfg.slot_group then
    for slot, slotData in ipairs(self.mixCfg.slot_group or {}) do
      if 4 == slot then
        self.PreTaskFinishSlotData = slotData
        self:SetRedPoint(slot, slotData)
      else
        self:SetSlotData(slot, slotData)
      end
    end
  end
  self.activityInst.judgeTaskQuery:QueryTaskStatus(self, self.PreTaskCheckCallback)
  local titleIcon = self.activityInst:GetTitleIcon()
  if not string.IsNilOrEmpty(titleIcon) then
    self.NRCImage_92:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_92:SetPath(titleIcon)
  else
    self.NRCImage_92:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local title = self.activityInst:GetTitleIconText()
  if not string.IsNilOrEmpty(titleIcon) then
    self.NRCText_61:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_61:SetText(title)
  else
    self.NRCText_61:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:CheckEggRewardTaskState()
  if self.RedPointData and self.RedPointData[4] and self.RedDot4 and self.RedDot4:GetVisibility() == UE4.ESlateVisibility.HitTestInvisible then
    if self.activityInst.HasLookTabRedPoint then
      self:EraseSlotRedPoint(4)
    else
      self.activityInst.HasLookTabRedPoint = true
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:OnDestruct()
  Base.OnDestruct(self)
  self:RemoveButtonListener(self.Button1)
  self:RemoveButtonListener(self.Button2)
  self:RemoveButtonListener(self.Button3)
  self:RemoveButtonListener(self.Button2_1)
  self.RedPointData = {}
end

function UMG_Activity_ElvenAmbassador_C:SetForbidClickSlot(slot, tips)
  local forbidClickSlots = self.forbidClickSlots
  if not forbidClickSlots then
    forbidClickSlots = {}
    self.forbidClickSlots = forbidClickSlots
  end
  forbidClickSlots[slot] = tips
end

function UMG_Activity_ElvenAmbassador_C:CheckSlotForbidClickTips(slot)
  local forbidClickSlots = self.forbidClickSlots
  if forbidClickSlots then
    return forbidClickSlots[slot]
  end
end

function UMG_Activity_ElvenAmbassador_C:UpdateSlotData(slotActivityInst, slot, slotData)
  if self.isDestruct then
    return
  end
  local iconDescCtrl = self["iconDesc_" .. slot]
  if not slotActivityInst or slotActivityInst:IsActivityInactive() then
    self:SetForbidClickSlot(slot, _G.LuaText.activity_drop_tips_takeoff_popup)
    if iconDescCtrl then
      iconDescCtrl:SetText(_G.LuaText.activity_drop_tips_takeoff)
    end
  elseif slotActivityInst:GetActivityType() == Enum.ActivityType.ATP_DROP then
    local specificTimeActivityInst = slotActivityInst
    local dailyAlreadyGet, totalAlreadyGet = specificTimeActivityInst:GetAlreadyGetNum()
    local dailyLimit = 0
    local totalLimit = 0
    local dropCfg = specificTimeActivityInst:GetActivityDropConf()
    if dropCfg then
      dailyLimit = dropCfg.day_got_limit or 0
      totalLimit = dropCfg.total_got_limit or 0
    end
    if totalAlreadyGet >= totalLimit then
      self:SetForbidClickSlot(slot, _G.LuaText.activity_drop_tips_total_finish_popup)
      if iconDescCtrl then
        iconDescCtrl:SetText(_G.LuaText.activity_drop_tips_total_finish)
      end
    else
      self:SetForbidClickSlot(slot, nil)
      if iconDescCtrl then
        iconDescCtrl:SetText(string.safeFormat("%d/%d", dailyAlreadyGet, dailyLimit))
      end
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:SetSlotData(slot, slotData)
  if not slotData then
    return
  end
  local nameCtrl = self["name_" .. slot]
  if nameCtrl then
    nameCtrl:SetText(slotData.slot_des)
  end
  local iconCtrl = self["icon_" .. slot]
  if iconCtrl then
    iconCtrl:SetPath("")
  end
  local iconDescCtrl = self["iconDesc_" .. slot]
  if iconDescCtrl then
    iconDescCtrl:SetText("")
  end
  if slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_TASK then
    self.SlotTaskData = slotData
  elseif slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_TASK_REAWAD then
    self.SlotEggRewardData = slotData
    if slotData.params and slotData.params[1] then
      local taskId = slotData.params[1]
      local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
      if taskConf and taskConf.Reward then
        local rewardId = taskConf.Reward
        local rewardData = ActivityUtils.GetActivityRewardData(rewardId, true)
        self.RewardItemData = _G.DataConfigManager:GetRewardConf(rewardId).RewardItem[1]
        if rewardData then
          if self.EggImage_Icon then
            self.EggImage_Icon:SetPath(rewardData.showIcon)
          end
          if self.EggImage_Icon_1 then
            self.EggImage_Icon_1:SetPath(rewardData.showIcon)
          end
          if self.EggImage_Icon_2 then
            self.EggImage_Icon_2:SetPath(rewardData.showIcon)
          end
        end
      end
    end
  elseif slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_CHECK_BAGITEM and slotData.params and slotData.params[1] then
    local iconPath = ActivityUtils.GetItemIconAndQuality(_G.Enum.GoodsType.GT_BAGITEM, slotData.params[1])
    self.NRCImage_Currency:SetPath(iconPath)
  end
  if self.NRCText_1 then
    self.NRCText_1:SetText(_G.LuaText.activity_pet_information_reward_tips)
  end
  if self.NRCText_9 then
    self.NRCText_9:SetText(_G.LuaText.activity_pet_information_reward_tips)
  end
  if self.NRCText_2 then
    self.NRCText_2:SetText(_G.LuaText.activity_pet_information_reward_tips)
  end
  self:SetRedPoint(slot, slotData)
end

function UMG_Activity_ElvenAmbassador_C:SetRedPoint(slot, slotData)
  local activityInst = self.activityInst
  if activityInst then
    local redPointId, redPointExtraKey = activityInst:GetSlotRedPointData(slotData, "[^%;]+")
    if redPointId and 0 ~= redPointId then
      local redPointCtrl = self["RedDot" .. slot]
      if redPointCtrl then
        self.RedPointData[slot] = {redPointId = redPointId, redPointExtraKey = redPointExtraKey}
        redPointCtrl:SetupKey(redPointId, redPointExtraKey)
      end
      if slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_PET_INFORMATION and self.RedDotSpec then
        local activityId = activityInst:GetActivityId()
        self.RedDotSpec:SetupKey(215, {
          tostring(activityId),
          tostring(slot)
        })
      end
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:OnClickSlot(slot)
  local tips = self:CheckSlotForbidClickTips(slot)
  if not string.IsNilOrEmpty(tips) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
    return
  end
  local activityInst = self.activityInst
  if activityInst then
    if activityInst:IsActivityInactive() then
      ActivityUtils.ShowActivityExpiredTips()
      return
    end
    if self.mixCfg then
      local slotData = self.mixCfg.slot_group and self.mixCfg.slot_group[slot]
      if slotData then
        if slotData.slot_function_type ~= Enum.ActiviyMixSlotFunciton.AMSF_PET_INFORMATION then
          ActivityUtils.SendTLogActivityButtonAction(activityInst:GetActivityId(), slot)
        end
        local isInitUnLock = slotData.initial_unlock
        if not isInitUnLock and not self.PreTaskIsFinish then
          local preTaskLockTips = self.mixCfg.unlock_tips
          if preTaskLockTips and "" ~= preTaskLockTips then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, preTaskLockTips)
          end
          _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_ElvenAmbassador_C:OnClickSlot")
          return
        end
        _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ElvenAmbassador_C:OnClickSlot")
        if slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_TASK then
          local redPointId, redPointExtraKey = activityInst:GetSlotRedPointData(slotData, "[^%;]+")
          local data = {
            taskSlotData = self.SlotTaskData.params,
            redPointId = redPointId,
            redPointExtraKey = redPointExtraKey
          }
          _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenSurveyTasksPanel, data)
        elseif slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_TASK_REAWAD then
          if 0 == self.NRCSwitcher_881:GetActiveWidgetIndex() then
            ActivityUtils.DoActivityOptionCmd(slotData.option_id)
          elseif 1 == self.NRCSwitcher_881:GetActiveWidgetIndex() then
            self:OnGetEggReward()
          end
        else
          ActivityUtils.DoActivityOptionCmd(slotData.option_id)
        end
      end
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:OnClickSlot1()
  self:OnClickSlot(1)
end

function UMG_Activity_ElvenAmbassador_C:OnClickSlot2()
  self:OnClickSlot(2)
end

function UMG_Activity_ElvenAmbassador_C:OnClickSlot3()
  self:OnClickSlot(3)
end

function UMG_Activity_ElvenAmbassador_C:OnClickTaskSlot()
  local isInitUnLock = self.PreTaskFinishSlotData.initial_unlock
  if isInitUnLock or not isInitUnLock and self.PreTaskIsFinish then
    self:EraseSlotRedPoint(4)
    self:ErasePhotoLockRedPoint()
    self:OnClickSlot(4)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ElvenAmbassador_C:OnClickTaskSlot")
    if self.mixCfg and self.mixCfg.must_do_task_judg and self.mixCfg.must_do_task_judg[1] then
      local preTaskId = self.mixCfg.must_do_task_judg[1]
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.SelectTrackTask, preTaskId)
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:InitPreTaskSlot()
  local isInitUnLock = self.PreTaskFinishSlotData.initial_unlock
  if isInitUnLock or not isInitUnLock and self.PreTaskIsFinish then
    self.name_4:SetText(self.PreTaskFinishSlotData.slot_des)
    self.NRCSwitcher_611:SetActiveWidgetIndex(1)
  else
    self.name_5:SetText(self.mixCfg.go_task_option_name)
    self.NRCSwitcher_611:SetActiveWidgetIndex(0)
  end
end

function UMG_Activity_ElvenAmbassador_C:PreTaskCheckCallback(allFinished)
  self.PreTaskIsFinish = allFinished
  self:InitPreTaskSlot()
  if self.mixCfg.slot_group then
    for slot, slotData in ipairs(self.mixCfg.slot_group or {}) do
      self:CheckSlotLockState(slot, slotData)
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:CheckSlotLockState(slot, slotData)
  local lockBg = self["CanvasNotUnlocked" .. slot]
  if lockBg then
    local isInitUnLock = slotData.initial_unlock
    if isInitUnLock or not isInitUnLock and self.PreTaskIsFinish then
      lockBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      lockBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Activity_ElvenAmbassador_C:EraseSlotRedPoint(slot)
  if self.RedPointData and self.RedPointData[slot] then
    local redPointId = self.RedPointData[slot].redPointId
    local redPointExtraKey = self.RedPointData[slot].redPointExtraKey
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, redPointId, redPointExtraKey, true)
  end
end

function UMG_Activity_ElvenAmbassador_C:ErasePhotoLockRedPoint()
  if self.RedDotSpec then
    local activityId = self.activityInst:GetActivityId()
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 215, {
      tostring(activityId),
      "4"
    }, true)
  end
end

function UMG_Activity_ElvenAmbassador_C:OnGetEggReward()
  if self.IsWaitGetRewardRsp then
    return
  end
  if 1 == self.NRCSwitcher_881:GetActiveWidgetIndex() and self.activityInst and self.SlotEggRewardData and self.SlotEggRewardData.params and self.SlotEggRewardData.params[1] then
    self.IsWaitGetRewardRsp = true
    local taskId = self.SlotEggRewardData.params[1]
    local req = _G.ProtoMessage:newZoneTaskRewardReq()
    req.task_list = {taskId}
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.OnZoneTaskRewardRsp)
  end
end

function UMG_Activity_ElvenAmbassador_C:OnZoneTaskRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if self.RewardItemData then
      local itemType = self.RewardItemData.Type
      local itemId = self.RewardItemData.Id
      local itemCount = self.RewardItemData.Count
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, {
        {
          id = itemId,
          type = itemType,
          num = itemCount
        }
      }, "")
    end
    self.NRCSwitcher_881:SetActiveWidgetIndex(2)
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
  self.IsWaitGetRewardRsp = false
end

function UMG_Activity_ElvenAmbassador_C:CheckEggRewardTaskState()
  if self.SlotEggRewardData and self.SlotEggRewardData.params and self.SlotEggRewardData.params[1] then
    local taskId = self.SlotEggRewardData.params[1]
    local req = _G.ProtoMessage:newZoneTaskQueryReq()
    req.task_list = {taskId}
    req.task_state = 0
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.EggRewardTaskCheckCallback, false, true)
  end
end

function UMG_Activity_ElvenAmbassador_C:EggRewardTaskCheckCallback(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if rsp.task_info_list and rsp.task_info_list[1] then
      local state = rsp.task_info_list[1].state
      if state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
        self.NRCSwitcher_881:SetActiveWidgetIndex(0)
      elseif state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        self.NRCSwitcher_881:SetActiveWidgetIndex(1)
      elseif state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        self.NRCSwitcher_881:SetActiveWidgetIndex(2)
      end
    else
      self.NRCSwitcher_881:SetActiveWidgetIndex(0)
    end
  else
    self.NRCSwitcher_881:SetActiveWidgetIndex(0)
  end
end

function UMG_Activity_ElvenAmbassador_C:OnClickRewardBtn()
  if 1 == self.NRCSwitcher_881:GetActiveWidgetIndex() then
    self:OnGetEggReward()
  else
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.RewardItemData.Id, self.RewardItemData.Type)
  end
end

return UMG_Activity_ElvenAmbassador_C

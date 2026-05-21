local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_BackSchoolSeason_C = Base:Extend("UMG_Activity_BackSchoolSeason_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_BackSchoolSeason_C:BindUIElements()
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

function UMG_Activity_BackSchoolSeason_C:OnConstruct()
  Base.OnConstruct(self)
  self:AddButtonListener(self.Button1, self.OnClickSlot1)
  self:AddButtonListener(self.Button2, self.OnClickSlot2)
  self:AddButtonListener(self.Button3, self.OnClickSlot3)
  local activityInst = self.activityInst
  local mixCfg = activityInst:GetMixCfg()
  if mixCfg and mixCfg.slot_group then
    for slot, slotData in ipairs(mixCfg.slot_group or {}) do
      self:SetSlotData(slot, slotData)
    end
  end
end

function UMG_Activity_BackSchoolSeason_C:OnDestruct()
  Base.OnDestruct(self)
end

function UMG_Activity_BackSchoolSeason_C:SetForbidClickSlot(slot, tips)
  local forbidClickSlots = self.forbidClickSlots
  if not forbidClickSlots then
    forbidClickSlots = {}
    self.forbidClickSlots = forbidClickSlots
  end
  forbidClickSlots[slot] = tips
end

function UMG_Activity_BackSchoolSeason_C:CheckSlotForbidClickTips(slot)
  local forbidClickSlots = self.forbidClickSlots
  if forbidClickSlots then
    return forbidClickSlots[slot]
  end
end

function UMG_Activity_BackSchoolSeason_C:UpdateSlotData(slotActivityInst, slot, slotData)
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

function UMG_Activity_BackSchoolSeason_C:SetSlotData(slot, slotData)
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
  if slotData.slot_function_type == Enum.ActiviyMixSlotFunciton.AMSF_ACTIVITY then
    local slotActivityInst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, slotData.params[1], true)
    if slotActivityInst then
      if iconCtrl and slotActivityInst:GetActivityType() == Enum.ActivityType.ATP_DROP then
        local specificTimeActivityInst = slotActivityInst
        local dropCfg = specificTimeActivityInst:GetActivityDropConf()
        if dropCfg then
          local iconPath = ActivityUtils.GetItemIconAndQuality(dropCfg.goods_type, dropCfg.goods_id)
          iconCtrl:SetPath(iconPath)
        end
      end
      slotActivityInst:ReqGetPlayerActivityData(_G.MakeWeakFunctor(self, self.UpdateSlotData, slotActivityInst, slot, slotData))
      slotActivityInst:AddActivityExpiredCallback("UMG_Activity_BackSchoolSeason_C", self, self.UpdateSlotData, slotActivityInst, slot, slotData)
    end
    self:UpdateSlotData(slotActivityInst, slot, slotData)
  end
  local activityInst = self.activityInst
  if activityInst then
    local redPointId, redPointExtraKey = activityInst:GetSlotRedPointData(slotData)
    if redPointId then
      local redPointCtrl = self["RedDot" .. slot]
      if redPointCtrl then
        redPointCtrl:SetupKey(redPointId, redPointExtraKey)
      end
    end
  end
end

function UMG_Activity_BackSchoolSeason_C:OnClickSlot(slot)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_BackSchoolSeason_C:OnClickSlot")
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
    local mixCfg = activityInst:GetMixCfg()
    if mixCfg then
      local slotData = mixCfg.slot_group and mixCfg.slot_group[slot]
      if slotData then
        ActivityUtils.DoActivityOptionCmd(slotData.option_id)
      end
    end
  end
end

function UMG_Activity_BackSchoolSeason_C:OnClickSlot1()
  self:OnClickSlot(1)
end

function UMG_Activity_BackSchoolSeason_C:OnClickSlot2()
  self:OnClickSlot(2)
end

function UMG_Activity_BackSchoolSeason_C:OnClickSlot3()
  self:OnClickSlot(3)
end

return UMG_Activity_BackSchoolSeason_C

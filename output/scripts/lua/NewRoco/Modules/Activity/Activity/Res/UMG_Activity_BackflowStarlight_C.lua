local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_BackflowStarlight_C = Base:Extend("UMG_Activity_BackflowStarlight_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_BackflowStarlight_C:BindUIElements()
  local uiElements = {}
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.bgImage = self.BG
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_BackflowStarlight_C:OnConstruct()
  Base.OnConstruct(self)
  self:AddButtonListener(self.Button, self.OnButtonClick)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OpenDetailPanel)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshStarLightActivityData, self.InitPanel)
  self:InitPanel(self.activityInst:GetActivityData())
  local starlightbuffConf = _G.DataConfigManager:GetActivityRecallStarlightbuff(self.activityInst:GetSinglePartId())
  self.Time_Tips:SetText(tostring(starlightbuffConf.starlight_buff) .. "%")
end

function UMG_Activity_BackflowStarlight_C:InitPanel(activity_data)
  if activity_data then
    self.bShowTag = activity_data.is_show_recall_tag
    if self.bShowTag then
      self:PlayAnimation(self.Choose, self.Choose:GetEndTime() - 0.01)
    else
      self:PlayAnimation(self.Cancel, self.Cancel:GetEndTime() - 0.01)
    end
  end
end

function UMG_Activity_BackflowStarlight_C:OnButtonClick()
  if self.bShowTag ~= nil and not self.bWaitChange then
    self.bWaitChange = true
    local req = _G.ProtoMessage:newZoneActivityRecallTagSwitchReq()
    req.activity_id = self.activityInst:GetActivityId()
    req.is_show = not self.bShowTag
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_RECALL_TAG_SWITCH_REQ, req, self, self.ChangeShowState)
  end
end

function UMG_Activity_BackflowStarlight_C:ChangeShowState(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.bShowTag = not self.bShowTag
    if self.bShowTag then
      _G.NRCAudioManager:PlaySound2DAuto(40007001, "UMG_Activity_BackflowStarlight_C:ChangeShowState")
      self:StopAnimation(self.Cancel)
      self:PlayAnimation(self.Choose)
    else
      _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_BackflowStarlight_C:ChangeShowState")
      self:StopAnimation(self.Choose)
      self:PlayAnimation(self.Cancel)
    end
    self:SendTLog()
  end
  self.bWaitChange = false
end

function UMG_Activity_BackflowStarlight_C:OpenDetailPanel()
  local Context = _G.DialogContext()
  local starlightbuffConf = _G.DataConfigManager:GetActivityRecallStarlightbuff(self.activityInst:GetSinglePartId())
  Context:SetTitle(starlightbuffConf.starlight_buff_describe):SetContent(starlightbuffConf.starlight_buff_text):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Activity_BackflowStarlight_C:SendTLog()
  local key = "ActivityButtonInteraction"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local value = string.format("%s|%s|%d|%d|%d", key, roleDataStr, self.activityInst:GetActivityId(), 1, self.bShowTag and 1 or 0)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function UMG_Activity_BackflowStarlight_C:OnDestruct()
  self:RemoveButtonListener(self.Button)
  self:RemoveButtonListener(self.Particulars.btnLevelUp)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshStarLightActivityData)
end

return UMG_Activity_BackflowStarlight_C

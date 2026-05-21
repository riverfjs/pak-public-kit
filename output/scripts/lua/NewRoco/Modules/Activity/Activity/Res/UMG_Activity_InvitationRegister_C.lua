local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_InvitationRegister_C = Base:Extend("UMG_Activity_InvitationRegister_C")

function UMG_Activity_InvitationRegister_C:BindUIElements()
  local uiElements = {}
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.Image_Bg
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_InvitationRegister_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
  self:InitPanel(self.activityInst:GetActivityData())
end

function UMG_Activity_InvitationRegister_C:InitPanel(part_data)
  if part_data then
    local initData = {}
    local reward_icon
    for _, task_data in ipairs(part_data) do
      local inviteRegisterConf = _G.DataConfigManager:GetActivityInviteRegisterConf(task_data.activity_part_id)
      local data = {}
      local task_name = inviteRegisterConf.part_name
      local reward = inviteRegisterConf.reward_group[1]
      local reward_num = reward.goods_count
      if nil == reward_icon then
        reward_icon, _ = ActivityUtils.GetItemIconAndQuality(reward.goods_type, reward.goods_id)
      end
      data.reward_state = task_data.state
      if task_data.param and task_data.param.param1 then
        data.get_num = task_data.param.param1 * reward_num
      else
        data.get_num = 0
      end
      data.task_name = task_name
      data.reward_num = reward_num
      data.reward_icon = reward_icon
      data.activity_id = self.activityInst:GetActivityId()
      data.max_reward_num = inviteRegisterConf.max_reward_count * reward_num
      data.base_id = task_data.activity_part_id
      data.share_part_conf_id = inviteRegisterConf.share_part_conf_id
      table.insert(initData, data)
    end
    local inviteList = self.activityInst:GetInviteData().invitee_list
    local inviteNum = inviteList and #inviteList or 0
    self.InvitedNum:SetText(string.format(_G.LuaText.invite_friend_time_tips, inviteNum))
    self.Icon:SetPath(reward_icon)
    self.List:InitList(initData)
    self.List:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.InvitedNum:SetText(string.format(_G.LuaText.invite_friend_time_tips, 0))
    self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_InvitationRegister_C:OnAddEventListener()
  self:AddButtonListener(self.ExchangeStoreBtn, self.GotoShop)
  self:AddButtonListener(self.InvitationRecordBtn, self.OpenRecordPanel)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshInviteRegisterActivityData, self.InitPanel)
end

function UMG_Activity_InvitationRegister_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.ExchangeStoreBtn)
  self:RemoveButtonListener(self.InvitationRecordBtn)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshInviteRegisterActivityData)
end

function UMG_Activity_InvitationRegister_C:GotoShop()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_InvitationRegister_C:GotoShop")
  local activity_option_id = self.activityInst:GetActivityTypeParam()
  ActivityUtils.DoActivityOptionCmd(activity_option_id[1])
end

function UMG_Activity_InvitationRegister_C:OpenRecordPanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_InvitationRegister_C:OpenRecordPanel")
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenInvitationRecord, self.activityInst:GetActivityId())
end

function UMG_Activity_InvitationRegister_C:OnDestruct()
  self:OnRemoveEventListener()
end

return UMG_Activity_InvitationRegister_C

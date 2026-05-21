local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_BackflowContractManualTaskItem_C = Base:Extend("UMG_Activity_BackflowContractManualTaskItem_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_BackflowContractManualTaskItem_C:OnConstruct()
  self:AddButtonListener(self.Get_Btn.btnLevelUp, self.ReqGetExp)
  self:AddButtonListener(self.LeaveFor_Btn.btnLevelUp, self.GotoTarget)
end

function UMG_Activity_BackflowContractManualTaskItem_C:OnDestruct()
  self:RemoveButtonListener(self.Get_Btn.btnLevelUp)
  self:RemoveButtonListener(self.LeaveFor_Btn.btnLevelUp)
end

function UMG_Activity_BackflowContractManualTaskItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.Desc:SetText(_data.taskText)
  self.QuantityText:SetText(string.format(_G.LuaText.report_ratio, tostring(_data.exp_num)))
  self:StopAllAnimations()
  if _data.bMaxLevel then
    self:StopAllAnimations()
    self:PlayAnimation(self.Get, self.Get:GetEndTime() - 0.01)
    self.Switcher:SetActiveWidgetIndex(2)
    self.NRCText_1:SetText(_G.LuaText.recallbp_maxlevel_button_text)
  elseif _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH then
    if 0 == _data.option_id then
      self.Switcher:SetActiveWidgetIndex(0)
    else
      self.Switcher:SetActiveWidgetIndex(3)
    end
  elseif _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    self:PlayAnimation(self.Available, nil, 0)
    self.Switcher:SetActiveWidgetIndex(1)
  elseif _data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
    self.Switcher:SetActiveWidgetIndex(2)
  end
end

function UMG_Activity_BackflowContractManualTaskItem_C:ReqGetExp()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_BackflowContractManualTaskItem_C:ReqGetExp")
  local req = _G.ProtoMessage:newZoneReceiveActivityRecallBpExpReq()
  req.activity_id = self.uiData.activity_id
  req.task_id = self.uiData.task_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_ACTIVITY_RECALL_BP_EXP_REQ, req, self, self.GetExp)
end

function UMG_Activity_BackflowContractManualTaskItem_C:GotoTarget()
  ActivityUtils.DoActivityOptionCmd(self.uiData.option_id)
end

function UMG_Activity_BackflowContractManualTaskItem_C:GetExp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.uiData.state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
    self:StopAllAnimations()
    self:PlayAnimation(self.Get)
    self.Switcher:SetActiveWidgetIndex(2)
    self.uiData.callBack(self.uiData.caller, self.uiData.exp_num)
  end
end

function UMG_Activity_BackflowContractManualTaskItem_C:OnItemSelected(_bSelected)
end

function UMG_Activity_BackflowContractManualTaskItem_C:OnDeactive()
end

return UMG_Activity_BackflowContractManualTaskItem_C

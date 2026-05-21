local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local UMG_Activity_SurveyTasks_Item1_C = Base:Extend("UMG_Activity_SurveyTasks_Item1_C")

function UMG_Activity_SurveyTasks_Item1_C:OnConstruct()
  self:AddButtonListener(self.Btn_Get.btnLevelUp, self.OnGetAward)
  self:AddButtonListener(self.Btn_LeaveFor.btnLevelUp, self.OnTrace)
end

function UMG_Activity_SurveyTasks_Item1_C:OnDestruct()
  self:RemoveButtonListener(self.Btn_Get.btnLevelUp, self.OnGetAward)
  self:RemoveButtonListener(self.Btn_LeaveFor.btnLevelUp, self.OnTrace)
end

function UMG_Activity_SurveyTasks_Item1_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self:InitTaskInfo()
  self:SetRedPoint()
end

function UMG_Activity_SurveyTasks_Item1_C:OnItemSelected(_bSelected)
end

function UMG_Activity_SurveyTasks_Item1_C:OnDeactive()
end

function UMG_Activity_SurveyTasks_Item1_C:InitTaskInfo()
  local taskId = self.data.taskData.id
  local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
  self:ShowTaskDesc(false)
  local RewardId = taskConf.Reward
  if not RewardId or 0 == RewardId then
    self.NRCGridView_95:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCGridView_95:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local RewardList = {}
  if RewardId and 0 ~= RewardId then
    local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId)
    local RewardItem = RewardConf.RewardItem
    for i, _RewardConf in ipairs(RewardItem) do
      if (_RewardConf.Type ~= _G.Enum.GoodsType.GT_CARD_ICON or _RewardConf.Type ~= _G.Enum.Enum.GoodsType.GT_CARD_SKIN or _RewardConf.Type ~= _G.Enum.Enum.GoodsType.GT_CARD_LABEL) and _RewardConf.Type ~= _G.Enum.GoodsType.GT_REWARD then
        table.insert(RewardList, {
          RewardConf = _RewardConf,
          state = self.data.taskData.state
        })
      end
    end
  end
  local rewardsTable = {}
  for k, v in ipairs(RewardList) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.RewardConf.Type
    rewards.itemId = v.RewardConf.Id
    rewards.itemNum = v.RewardConf.Count
    rewards.bShowNum = true
    rewards.bShowTip = true
    rewards.openTipsSoundId = 40008005
    if v.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      rewards.bShowGetTag = true
    else
      rewards.bShowGetTag = false
    end
    table.insert(rewardsTable, rewards)
  end
  self.NRCGridView_95:InitGridView(rewardsTable)
  if self.data.taskData.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  elseif self.data.taskData.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    self.NRCSwitcher_1:SetActiveWidgetIndex(3)
  elseif self.data.taskData.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    self.go_guide = nil
    for i, v in pairs(taskConf.go_guide) do
      if v.type and v.type == Enum.TaskGoActionType.TGAT_UI and v.text then
        self.go_guide = v
      end
    end
    if self.go_guide and self.go_guide.type and self.go_guide.type == Enum.TaskGoActionType.TGAT_UI and self.go_guide.text then
      self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_1:SetActiveWidgetIndex(2)
    end
  end
end

function UMG_Activity_SurveyTasks_Item1_C:ShowTaskDesc(isFinish)
  local taskId = self.data.taskData.id
  local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
  local title = taskConf.name
  local targetNum = taskConf.task_condition[1].count
  local curNum = self.data.taskData.task_target_list[1] or 0
  local progress
  if isFinish then
    progress = string.format("%s/%s", targetNum, targetNum)
  else
    progress = string.format("%s/%s", curNum, targetNum)
  end
  self.Describe:SetText(title)
  self.Describe_1:SetText(progress)
end

function UMG_Activity_SurveyTasks_Item1_C:OnGetAward()
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  req.task_list = {
    self.data.taskData.id
  }
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.ZoneTaskRewardRsp, false, true)
end

function UMG_Activity_SurveyTasks_Item1_C:ZoneTaskRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local CurRewardConf = rsp.ret_info.goods_reward
    if #CurRewardConf.rewards > 0 then
      local newRewards = self:MergeRewards(CurRewardConf.rewards)
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, newRewards, "")
      if rsp.rewarded_task_list and #rsp.rewarded_task_list > 0 then
        self:FinishTask()
      end
    end
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function UMG_Activity_SurveyTasks_Item1_C:MergeRewards(_rspRewards)
  local newRewards = {}
  for _, goodsItem in ipairs(_rspRewards) do
    if goodsItem.reward_reason ~= _G.ProtoEnum.FlowReason.FLOW_REASON_LEVEL_REWARD then
      table.insert(newRewards, goodsItem)
    end
  end
  return newRewards
end

function UMG_Activity_SurveyTasks_Item1_C:FinishTask()
  self.NRCSwitcher_1:SetActiveWidgetIndex(3)
  self:ShowTaskDesc(true)
end

function UMG_Activity_SurveyTasks_Item1_C:OnTrace()
  self.Btn_LeaveFor.btnLevelUp:SetIsEnabled(false)
  self:CancelAllDelay()
  self.Handler = _G.DelayManager:DelaySeconds(0.1, function()
    self.Btn_LeaveFor.btnLevelUp:SetIsEnabled(true)
  end)
  if self.go_guide and self.go_guide.type and self.go_guide.type == Enum.TaskGoActionType.TGAT_UI and self.go_guide.text then
    local args1, args2
    if self.go_guide.args then
      args1 = UIUtils.GetSplit(self.go_guide.args, ";")
      if args1 and #args1 > 1 then
      else
        args1 = tonumber(self.go_guide.args)
        if nil == args1 then
          args1 = self.go_guide.args
        end
      end
    end
    if self.go_guide.args2 then
      args2 = UIUtils.GetSplit(self.go_guide.args2, ";")
      if args2 and #args2 > 1 then
      else
        args2 = tonumber(self.go_guide.args2)
        if nil == args2 then
          args2 = self.go_guide.args2
        end
      end
    end
    _G.NRCModuleManager:DoCmdWithArgs(self.go_guide.text, args1, args2)
  end
end

function UMG_Activity_SurveyTasks_Item1_C:CancelAllDelay()
  if self.Handler then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = nil
  end
end

function UMG_Activity_SurveyTasks_Item1_C:SetRedPoint()
  self.Btn_Get.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_Get.redPointNew:SetupKey(self.data.redPointId, self.data.redPointExtraKey)
end

return UMG_Activity_SurveyTasks_Item1_C

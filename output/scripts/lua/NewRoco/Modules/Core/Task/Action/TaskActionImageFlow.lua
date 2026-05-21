local TaskActionBase = require("NewRoco.Modules.Core.Task.TaskActionBase")
local Base = TaskActionBase
local TaskActionImageFlow = Base:Extend("TaskActionImageFlow")

function TaskActionImageFlow:Ctor(Task, ActionGroup, ActionIndex, Conf)
  Base.Ctor(self, Task, ActionGroup, ActionIndex, Conf)
  self.ImageFlowID = tonumber(Conf.data1[1] or 0) or 0
  self.bExecuted = false
end

function TaskActionImageFlow:ShouldExecute()
  if self.bExecuted then
    return false
  end
  local State = self.Task.Info.state
  return State == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN or State == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN_PLAY or State == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE or State == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE_PLAY
end

function TaskActionImageFlow:OnExecute()
  self.bExecuted = true
  local Param = {}
  Param.ImageFlowID = self.ImageFlowID
  Param.Caller = self
  Param.Callback = self.OnImageFlowFinish
  Param.Style = 1
  NRCModeManager:DoCmd(TaskModuleCmd.PlayTaskImageFlow, Param)
end

function TaskActionImageFlow:OnImageFlowFinish(bSuccess)
  if bSuccess then
    self:Finish()
  else
    Log.Debug("[TaskActionImageFlow:OnImageFlowFinish] ImageFlow Finish Failed")
  end
end

function TaskActionImageFlow:SendFinishReq()
  if self.Task.Config.task_structure_type == ProtoEnum.TaskStructureType.TSCAT_SLIDE then
    local InfoList = self:GetClientConditionInfo()
    if #InfoList > 0 then
      local Info = InfoList[1]
      local Req = ProtoMessage:newZoneTaskConditionTriggerReq()
      Req.taskid = Info.taskid
      Req.condition_type = Info.condition_type
      Req.task_condition_idx = Info.task_condition_idx
      Log.Debug("[TaskActionImageFlow:SendFinishReq] Send Finish Req", Info.taskid, Info.condition_type, Info.task_condition_idx)
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_CONDITION_TRIGGER_REQ, Req, self, self.OnSendFinish, false, false)
    end
  else
    Base.SendFinishReq(self)
  end
end

function TaskActionImageFlow:OnSendFinish(Rsp)
  self:Finish()
end

function TaskActionImageFlow:Destroy()
end

return TaskActionImageFlow

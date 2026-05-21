local Class = _G.MakeSimpleClass
local ProtoEnum = require("Data.PB.ProtoEnum")
local TaskActionGroupEnum = require("NewRoco.Modules.Core.Task.TaskActionGroupEnum")
local TaskActionGroupConf = {
  [TaskActionGroupEnum.Accept] = {
    Name = TaskActionGroupEnum.Accept,
    AllowStatus = ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN_PLAY,
    NextStatus = ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN
  },
  [TaskActionGroupEnum.Finish] = {
    Name = TaskActionGroupEnum.Finish,
    AllowStatus = ProtoEnum.EMTaskState.EM_TASK_STATE_DONE_PLAY,
    NextStatus = ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
  },
  [TaskActionGroupEnum.Condition] = {
    Name = TaskActionGroupEnum.Condition,
    AllowStatus = ProtoEnum.EMTaskState.EM_TASK_STATE_DONE_PLAY,
    NextStatus = ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
  }
}
local TaskActionBase = Class("TaskActionBase")
TaskActionBase:SetMemberCount(8)

function TaskActionBase:Ctor(Task, ActionGroup, ActionIndex, Conf)
  self.Task = Task
  self.ActionGroup = ActionGroup
  self.ActionIndex = ActionIndex
  self.Conf = Conf
  self.GroupConf = TaskActionGroupConf[self.ActionGroup]
  self.bIsPlaying = false
end

function TaskActionBase:ShouldExecute()
  return self.Task.Info.state == self.GroupConf.AllowStatus
end

function TaskActionBase:CanExecute()
  return self:ShouldExecute() and not self.bIsPlaying
end

function TaskActionBase:GetIsPlaying()
  return self.bIsPlaying
end

function TaskActionBase:Execute()
  self:Log("Execute")
  self.bIsPlaying = true
  self.Task:MarkPendingTask()
  self:OnExecute()
end

function TaskActionBase:Finish()
  self:Log("Finish")
  self.Task:ClearPendingTask()
  self.bIsPlaying = false
  self:OnFinish()
end

function TaskActionBase:OnExecute()
  self:SendFinishReq()
end

function TaskActionBase:OnFinish()
end

function TaskActionBase:SendFinishReq()
  self:Log("SendFinishReq")
  local Req = _G.ProtoMessage:newZoneTaskStateReq()
  Req.task_id = self.Task.Info.id
  Req.new_state = self.GroupConf.NextStatus
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_STATE_REQ, Req, self, self.OnSendFinish, false, false)
end

function TaskActionBase:OnSendFinish(rsp)
  self:Finish()
end

function TaskActionBase:Destroy()
end

function TaskActionBase:GetDesc(Level)
  Level = Level or Log.LOG_LEVEL.ELogDebug
  if Level <= Log.GetLogLevel() then
    return "[TaskFlow]"
  end
  local TO = self.Task
  local Conf = TO and TO.Config
  local ID = Conf and Conf.id or 0
  local Info = TO and TO.Info
  local State = table.getKeyName(ProtoEnum.EMTaskState, Info.state)
  return string.format("[TaskFlow][%s]Task=%d,State=%s", self.className, ID, State)
end

function TaskActionBase:Log(...)
  Log.Debug(self:GetDesc(Log.LOG_LEVEL.ELogDebug), ...)
end

function TaskActionBase:LogWarning(...)
  Log.Warning(self:GetDesc(Log.LOG_LEVEL.ELogWarn), ...)
end

function TaskActionBase:LogError(...)
  Log.Error(self:GetDesc(Log.LOG_LEVEL.ELogError), ...)
end

function TaskActionBase:GetClientConditionInfo()
  local InfoList = {}
  local Conds = self.Task.Config.task_condition
  for Index, Cond in ipairs(Conds) do
    if Cond.type == ProtoEnum.TaskKeyType.TKT_CLIENT_CINEMA_FINISHED or Cond.type == ProtoEnum.TaskKeyType.TKT_CAMERA or Cond.type == ProtoEnum.TaskKeyType.TKT_STATE_PATH_FINISH or Cond.type == ProtoEnum.TaskKeyType.TKT_MINI_PACKAGE_DONE then
      local Info = {}
      Info.taskid = self.Task.Config.id
      Info.task_condition_idx = Index
      Info.condition_type = Cond.type
      table.insert(InfoList, Info)
    end
  end
  return InfoList
end

return TaskActionBase

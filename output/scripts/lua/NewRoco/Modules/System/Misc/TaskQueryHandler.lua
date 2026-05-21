local Class = _G.MakeSimpleClass
local TaskQueryHandler = Class("TaskQueryHandler")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local EventDispatcher = require("Common.EventDispatcher")
TaskQueryHandler.Event = {
  TaskStatusChanged = "TaskStatusChanged"
}

local function IsTaskDone(taskStatus)
  return taskStatus == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
end

function TaskQueryHandler:Ctor(_taskList)
  EventDispatcher():Attach(self)
  self.taskList = _taskList and table.copy(_taskList) or {}
  self.taskStatusData = {}
  self:RefreshAllTaskStatusByTaskSystemData(true)
end

function TaskQueryHandler:GetTaskList()
  return self.taskList
end

function TaskQueryHandler:CheckAllTaskDone()
  for _, taskStatus in pairs(self.taskStatusData) do
    if not IsTaskDone(taskStatus) then
      return false
    end
  end
  return true
end

function TaskQueryHandler:TrackTask(failedTips)
  for _, taskId in ipairs(self.taskList) do
    if ActivityUtils.SetTraceTask(taskId) then
      return true
    end
  end
  if not string.IsNilOrEmpty(failedTips) then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, failedTips)
  end
  return false
end

function TaskQueryHandler:GetTaskByStatus(taskStatus)
  local statusList = type(taskStatus) == "table" and taskStatus or {taskStatus}
  for _, taskId in ipairs(self.taskList) do
    local status = self.taskStatusData[taskId]
    if table.contains(statusList, status) then
      return taskId
    end
  end
end

function TaskQueryHandler:GetTaskListByStatus(taskStatus)
  local taskList = table.new(#self.taskList, 0)
  if taskStatus then
    local statusList = "table" == type(taskStatus) and taskStatus or {taskStatus}
    for _, taskId in ipairs(self.taskList) do
      local status = self.taskStatusData[taskId]
      if table.contains(statusList, status) then
        table.insert(taskList, taskId)
      end
    end
  end
  return taskList
end

function TaskQueryHandler:GetTaskStatus(taskId)
  return self.taskStatusData[taskId]
end

function TaskQueryHandler:QueryTaskStatus(caller, callback, ...)
  local rspData = self:CreateRspData(caller, callback, ...)
  
  local function OnZoneTaskQueryRsp(_rspData, _protoData)
    if _rspData then
      local isAllFinished = false
      if _protoData then
        local taskInfoList = _protoData.task_info_list or {}
        if #taskInfoList > 0 then
          isAllFinished = true
        end
        for _, taskInfo in ipairs(taskInfoList) do
          if _rspData.refreshTaskStatus then
            _rspData.refreshTaskStatus(taskInfo.id, taskInfo.state)
          end
          if not IsTaskDone(taskInfo.state) then
            isAllFinished = false
          end
        end
      end
      if _rspData.callback then
        _rspData.callback(isAllFinished)
      end
    end
  end
  
  self:RefreshAllTaskStatusByTaskSystemData(false)
  if not self:CheckAllTaskDone() then
    local req = _G.ProtoMessage:newZoneTaskQueryReq()
    req.task_list = self.taskList
    req.task_state = 0
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, rspData, OnZoneTaskQueryRsp)
  elseif rspData.callback then
    rspData.callback(true)
  end
end

function TaskQueryHandler:RequestGetTaskReward(taskId, showRewardGetTips, caller, callback, ...)
  local taskStatus = self:GetTaskStatus(taskId)
  if taskStatus == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
    local rspData = self:CreateRspData(caller, callback, ...)
    
    local function OnZoneTaskRewardRsp(_rspData, _protoData)
      if _rspData then
        if _protoData then
          if _rspData.refreshTaskStatus then
            for _, taskInfo in ipairs(_protoData.rewarded_task_list or {}) do
              _rspData.refreshTaskStatus(taskInfo.id, taskInfo.state)
            end
          end
          if showRewardGetTips then
            ActivityUtils.ShowRewardGetTips(nil, _protoData.ret_info)
          end
        end
        if _rspData.callback then
          _rspData.callback()
        end
      end
    end
    
    local req = _G.ProtoMessage:newZoneTaskRewardReq()
    req.task_list = {taskId}
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, rspData, OnZoneTaskRewardRsp)
  end
end

function TaskQueryHandler:CreateRspData(caller, callback, ...)
  local rspData = {}
  rspData.refreshTaskStatus = _G.MakeWeakFunctor(self, self.SetTaskStatus)
  rspData.callback = callback and _G.MakeWeakFunctor(caller, callback, ...)
  return rspData
end

function TaskQueryHandler:SetTaskStatus(taskId, taskStatus)
  if self.taskStatusData[taskId] == taskStatus then
    return
  end
  self.taskStatusData[taskId] = taskStatus
  self:SendEvent(TaskQueryHandler.Event.TaskStatusChanged, taskId, taskStatus)
end

function TaskQueryHandler:RefreshTaskStatusByTaskSystemData(taskId)
  local taskObj = _G.TaskModuleCmd and _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.getTaskByID, taskId)
  if taskObj then
    self:SetTaskStatus(taskId, taskObj.state)
    return taskObj.state
  end
end

function TaskQueryHandler:RefreshAllTaskStatusByTaskSystemData(initFlag)
  for _, taskId in ipairs(self.taskList) do
    if not self:RefreshTaskStatusByTaskSystemData(taskId) and initFlag then
      self:SetTaskStatus(taskId, ProtoEnum.EMTaskState.EM_TASK_STATE_INIT)
    end
  end
end

return TaskQueryHandler

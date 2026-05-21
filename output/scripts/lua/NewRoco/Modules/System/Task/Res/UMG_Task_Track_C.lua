require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local DisplayTaskTypeEnum = require("NewRoco.Modules.Core.Task.DisplayTaskTypeEnum")
local DisplayTaskObject = require("NewRoco.Modules.Core.Task.DisplayTaskObject")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipsModuleEvent = reload("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local TaskModuleEvent = reload("NewRoco.Modules.Core.Task.TaskModuleEvent")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local UMG_Task_Track_C = _G.NRCViewBase:Extend("UMG_Task_Track_C")
local state_value = {
  [ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT] = 1
}
local mt = {
  __index = function()
    return 2
  end
}
setmetatable(state_value, mt)
local class_value = {
  [Enum.TaskClassType.TCT_DUNGEON] = 0,
  [Enum.TaskClassType.TCT_EVOLUTION] = 1,
  [Enum.TaskClassType.TCT_MAIN] = 2,
  [Enum.TaskClassType.TCT_JOURNEY] = 3,
  [Enum.TaskClassType.TCT_SUB] = 4,
  [Enum.TaskClassType.TCT_ACTIVE] = 5
}
setmetatable(class_value, {
  __index = function()
    return 4
  end
})
local BanSceneList = {
  [10021] = true
}

local function cmp(a, b)
  local AState = a.Info.state
  local BState = b.Info.state
  local ATrack = a.isTrack and 0 or 1
  local BTrack = b.isTrack and 0 or 1
  if AState ~= BState then
    return state_value[AState] < state_value[BState]
  elseif a.isTrack ~= b.isTrack then
    return ATrack < BTrack
  elseif class_value[a.Config.task_class] == class_value[b.Config.task_class] then
    return a.Info.id < b.Info.id
  else
    return class_value[a.Config.task_class] < class_value[b.Config.task_class]
  end
end

function UMG_Task_Track_C:FilterTask(List)
  local NewList = {}
  for Index, Task in ipairs(List) do
    if Task.Config.task_class ~= Enum.TaskClassType.TCT_BP then
      table.insert(NewList, Task)
    end
  end
  return NewList
end

function UMG_Task_Track_C:GetTaskList()
  local trackTaskInfos = NRCModuleManager:DoCmd(_G.TaskModuleCmd.getAllTraceTask, true)
  trackTaskInfos = self:FilterTask(trackTaskInfos)
  table.sort(trackTaskInfos, cmp)
  return trackTaskInfos
end

function UMG_Task_Track_C:DoubleCheckTracking(List)
  for i, Data in ipairs(List) do
    if Data.Info.is_track then
      return
    end
  end
  for i, Data in ipairs(List) do
    if Data.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      NRCModuleManager:GetModule("TaskModule"):SetTrack(List[i].Info.id, true, true)
      break
    end
  end
end

function UMG_Task_Track_C:UpdateTaskList(tip)
  self:CancelTimeoutDelay()
  if self.PushTaskTimestamp and self.PushTaskTimestamp > 0 then
    local Now = os.msTime()
    local DeltaTime = Now - self.PushTaskTimestamp
    if DeltaTime > 30000 then
      Log.Error("\228\187\187\229\138\161\230\148\182\229\136\176\230\182\136\230\129\175\229\136\176\229\177\149\231\164\186\229\135\186\230\157\165\230\151\182\233\151\180\232\191\135\233\149\191", DeltaTime)
    end
  else
    Log.Error("\228\187\187\229\138\161\230\160\143\231\138\182\230\128\129\229\136\183\230\150\176\232\161\168\230\188\148\233\148\153\232\175\175\239\188\129\239\188\129\239\188\129")
  end
  self.PushTaskTimestamp = -1
  if self.CurrentTip then
    if self.CurrentDisplayActivityTask ~= nil then
      return
    end
    if tip then
      self.HasIgnoredTips = true
      tip:MarkFinished()
      Log.Debug("\229\191\189\231\149\165\228\187\187\229\138\161\232\161\168\230\188\148", tostring(self.CurrentTip))
    end
    return
  end
  if self.PendingUpdate then
    self.PendingUpdate = false
    self.TheItem:OnTaskUpdate(self.CurrentDisplayTask, true)
    if tip then
      tip:MarkFinished()
    end
    return
  end
  self.CurrentTip = tip
  self.CurrentTip:MarkDisplaying()
  self:StartTaskItemAnimations()
end

function UMG_Task_Track_C:StartTaskItemAnimations()
  local HasPendingTasks = self.PendingTasks and #self.PendingTasks > 0
  local HasNextTask = self.NextTask ~= nil
  local HasCurrentTask = nil ~= self.CurrentDisplayTask
  if HasCurrentTask then
    if HasNextTask then
      self:ReplaceTask()
    elseif HasPendingTasks then
      self.CurrentDisplayTask = nil
      self:PlayPendingTask()
    else
      self:RemoveCurrentTask()
    end
  elseif HasNextTask then
    self:ShowTask()
  elseif HasPendingTasks then
    self.CurrentDisplayTask = nil
    self:PlayPendingTask()
  else
    self:ClearCallback()
  end
end

function UMG_Task_Track_C:OnSwitchActivityTraceTask(_on, _taskId)
  local TaskMap = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.GetTaskMap)
  for k, v in pairs(TaskMap) do
    if v.Config.id == _taskId then
      self.CurrentDisplayActivityTask = v
      break
    end
  end
  if _on and self.CurrentDisplayActivityTask then
    if not self.CurrentDisplayActivityTask.UseStaticPosition and (self.CurrentDisplayTask == nil or self.CurrentDisplayTask.Config == nil or self.CurrentDisplayActivityTask.Config.id ~= self.CurrentDisplayTask.Config.id) then
      self.NextTask = self.CurrentDisplayActivityTask
      self:ReplaceTask()
    end
    self.CurrentDisplayActivityTask = nil
  elseif not _on then
    if self.CurrentDisplayTask == nil or self.CurrentDisplayTask.Config == nil or self.CurrentDisplayActivityTask.Config.id ~= self.CurrentDisplayTask.Config.id then
      self.CurrentDisplayActivityTask = nil
    else
      self:ActivitySafeSwitch()
    end
  end
end

function UMG_Task_Track_C:ActivitySafeSwitch()
  if self.CurrentDisplayTask == nil or nil == self.CurrentDisplayTask.Config or nil == self.CurrentDisplayActivityTask or self.CurrentDisplayTask.Config.id ~= self.CurrentDisplayActivityTask.Config.id then
    self.CurrentDisplayActivityTask = nil
    return
  end
  _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.setTrack, self.CurrentDisplayTask.Config.id, false)
  self:DelayFrames(30, self.ActivitySafeSwitch, self)
end

function UMG_Task_Track_C:OnDelayTrack(_taskObjectId, _track)
  _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.setTrack, _taskObjectId, _track)
end

function UMG_Task_Track_C:ShowTask()
  self:OnWidgetRemove()
end

function UMG_Task_Track_C:IsSameTask(TaskA, TaskB)
  if TaskA == TaskB then
    return true
  end
  if TaskA and not TaskB then
    return false
  end
  if not TaskA and TaskB then
    return false
  end
  local InfoA = TaskA and TaskA.Info
  local InfoB = TaskB and TaskB.Info
  if InfoA == InfoB then
    return true
  end
  if not InfoA and InfoB then
    return false
  end
  if InfoA and not InfoB then
    return false
  end
  return InfoA.id == InfoB.id
end

function UMG_Task_Track_C:ReplaceTask()
  local RealDisplayTask = self.TheItem.data
  if self:IsSameTask(RealDisplayTask, self.NextTask) then
    self.TheItem:SetData(self.NextTask)
    self.CurrentDisplayTask = self.NextTask
    self.NextTask = nil
    self:StopPendingPerform()
    self:ClearCallback()
  else
    self.TheItem:ConsumeRemove(self, self.OnWidgetRemove)
  end
end

function UMG_Task_Track_C:RemoveCurrentTask()
  self.TheItem:ConsumeRemove(self, self.OnRemoveLast)
end

function UMG_Task_Track_C:PlayPendingTask()
  self.PendingPlaying = true
  self.PendingIndex = 1
  self:PlayPending()
end

function UMG_Task_Track_C:StopPendingPerform()
  self.PendingPlaying = false
  self.PendingTasks = nil
end

function UMG_Task_Track_C:OnWidgetRemove()
  self.TheItem:SetData(self.NextTask)
  self.CurrentDisplayTask = self.NextTask
  self.NextTask = nil
  self.TheItem:ConsumeShow(self, self.ClearCallback)
end

function UMG_Task_Track_C:OnRemoveLast()
  self.TheItem:SetTask(nil)
  self.CurrentDisplayTask = nil
  self:ClearCallback()
end

function UMG_Task_Track_C:PlayPending()
  if not self.PendingPlaying then
    return
  end
  self.TheItem:ConsumeRemove(self, self.OnPendingRemove)
end

function UMG_Task_Track_C:OnPendingRemove()
  if not self.PendingPlaying then
    return
  end
  if not self.PendingTasks or self.PendingIndex > #self.PendingTasks then
    self.PendingPlaying = false
    self.PendingTasks = nil
    self.PendingIndex = 0
    local FirstTask, PendingTasks = self:GetDisplayTasks()
    if #PendingTasks > 0 then
      self.PendingTasks = PendingTasks
      self:StartTaskItemAnimations()
    elseif FirstTask ~= self.CurrentDisplayTask then
      self.NextTask = FirstTask
      self:StartTaskItemAnimations()
    elseif self.CurrentDisplayTask then
      self.TheItem:OnTaskUpdate(self.CurrentDisplayTask, true)
      self:ClearCallback()
    else
      self:ClearCallback()
    end
    return
  end
  local CurrentPendingTask = self.PendingTasks[self.PendingIndex]
  self.TheItem:SetData(CurrentPendingTask)
  self.TheItem:ConsumeShow(self, self.OnPendingShow)
end

function UMG_Task_Track_C:OnPendingShow()
  if not UE.UObject.IsValid(self) then
    Log.Error("UMG_Task_Track_C.OnPendingShow: \230\151\160\230\149\136\231\154\132UMG\229\175\185\232\177\161")
    return
  end
  if not self then
    Log.Error("UMG_Task_Track_C.OnPendingShow: \229\174\140\229\133\168\230\151\160\230\179\149\231\144\134\232\167\163\227\128\130\227\128\130\227\128\130self\228\185\159\232\131\189\230\152\175\231\169\186")
    return
  end
  if not self.PendingPlaying then
    return
  end
  if not self.PendingTasks then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150\228\187\187\229\138\161\232\161\168\230\188\148\230\149\176\230\141\174\239\188\140\232\175\183\229\176\134\229\164\141\231\142\176\230\150\185\229\188\143\229\145\138\232\175\137poanshen")
    return
  end
  if not self.PendingIndex then
    Log.Error("PendingIndex \228\184\186\231\169\186\239\188\140\232\175\183\229\176\134\229\164\141\231\142\176\230\150\185\229\188\143\229\145\138\232\175\137poanshen")
    return
  end
  local CurrentPendingTask = self.PendingTasks[self.PendingIndex]
  local CountdownTime = CurrentPendingTask and CurrentPendingTask:GetCountdown() or -1
  self.PendingIndex = self.PendingIndex + 1
  if CountdownTime > 0 then
    self.TheItem:StartTraceCountdown(CountdownTime, self.PlayPending, self)
  else
    self:PlayPending()
  end
end

function UMG_Task_Track_C:ClearCallback()
  if self.CurrentTip then
    self.CurrentTip:MarkFinished()
    self.CurrentTip = nil
  end
  if self.HasIgnoredTips then
    self.HasIgnoredTips = false
    Log.Debug("\231\148\177\228\186\142\229\137\141\233\157\162\230\156\137\232\162\171\229\191\189\231\149\165\231\154\132tips\239\188\140\230\137\128\228\187\165\232\191\153\233\135\140\232\161\165\228\184\128\228\184\170")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ProcessRetInfo, _G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY, _G.ProtoMessage:newRetInfo())
  end
end

function UMG_Task_Track_C:GetFirstTrackingTask()
  local TaskList = self:GetTaskList()
  for _, task in ipairs(TaskList) do
    if task.Info.is_track then
      return task
    end
  end
  return nil
end

function UMG_Task_Track_C:GetDisplayTasks()
  local FirstTask
  local PendingTrack = {}
  local TaskModule = _G.NRCModuleManager:GetModule("TaskModule")
  local TaskList = self:GetTaskList()
  for _, task in ipairs(TaskList) do
    if task.Info.is_track and not FirstTask then
      FirstTask = task
    end
    if task:IsNewTask() and task.ShouldShow and not self:CheckBanScene() then
      table.insert(PendingTrack, task)
    end
  end
  if PendingTrack and #PendingTrack > 0 then
    for i = 1, #PendingTrack do
      local Task = PendingTrack[i]
      PendingTrack[i] = DisplayTaskObject(TaskModule, DisplayTaskTypeEnum.NEW_TASK, Task.Info.id)
    end
  else
    FirstTask = FirstTask or self.NoTrackingFakeTask
  end
  return FirstTask, PendingTrack
end

function UMG_Task_Track_C:CheckBanScene()
  local SceneModule = TaskUtils:getSceneModule()
  if not SceneModule then
    return false
  end
  local CurrentMapID = SceneModule.mapResId
  if BanSceneList[CurrentMapID] then
    return true
  end
  return false
end

function UMG_Task_Track_C:PushTaskItem(CmdID, Coordinator)
  if CmdID ~= ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY and CmdID ~= ProtoCMD.ZoneSvrCmd.ZONE_RANDOM_SUB_TASK_NOTIFY then
    return
  end
  local FirstTask, PendingTrack = self:GetDisplayTasks()
  self.PendingUpdate = false
  self.PushTaskTimestamp = os.msTime()
  self.HasIgnoredTips = false
  if #PendingTrack > 0 then
    local Tip = TipObject.FromTaskUpdate()
    Log.Debug("\233\156\128\232\166\129\229\177\149\231\164\186\228\184\180\230\151\182\229\128\146\232\174\161\230\151\182\228\187\187\229\138\161", tostring(Tip))
    self.PendingTasks = PendingTrack
    Coordinator:AddTip(Tip, CmdID)
  elseif FirstTask ~= self.CurrentDisplayTask then
    self.NextTask = FirstTask
    local Tip = TipObject.FromTaskUpdate()
    Log.Debug("\233\156\128\232\166\129\230\155\191\230\141\162\228\187\187\229\138\161", FirstTask and FirstTask.Config and FirstTask.Config.name or "nil", tostring(Tip))
    Coordinator:AddTip(Tip, CmdID)
  else
    local Tip = TipObject.FromTaskUpdate()
    self.PendingUpdate = true
    Coordinator:AddTip(Tip, CmdID)
  end
  self:RestartTimeoutDelay()
end

function UMG_Task_Track_C:RestartTimeoutDelay()
  self:CancelTimeoutDelay()
  self.TimeoutHandler = _G.DelayManager:DelaySeconds(30.0, self.TaskDisplayTimeout, self)
end

function UMG_Task_Track_C:TaskDisplayTimeout()
  Log.Debug("\230\148\182\229\136\176\228\187\187\229\138\161\230\155\180\230\150\176\233\128\154\231\159\16530\231\167\146\228\186\134\239\188\140\228\189\134\230\152\175\232\191\152\230\178\161\230\156\137\229\156\176\230\150\185\232\167\166\229\143\145\230\146\173\230\148\190\228\187\187\229\138\161\230\160\143\229\136\183\230\150\176\231\154\132\232\161\168\230\188\148")
  self:CancelTimeoutDelay()
end

function UMG_Task_Track_C:CancelTimeoutDelay()
  if not self.TimeoutHandler then
    return
  end
  if self.TimeoutHandler <= 0 then
    return
  end
  _G.DelayManager:CancelDelayById(self.TimeoutHandler)
  self.TimeoutHandler = -1
end

function UMG_Task_Track_C:StopTaskAnimation()
end

function UMG_Task_Track_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:BindAction("IA_TaskDetailsStart", self, "OpenTaskDetailsUIStart", UE.ETriggerEvent.Triggered)
    mappingContext:BindAction("IA_TaskDetailsEnd", self, "OpenTaskDetailsUIEnd", UE.ETriggerEvent.Triggered)
  end
end

function UMG_Task_Track_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:UnBindAction("IA_TaskDetailsStart")
    mappingContext:UnBindAction("IA_TaskDetailsEnd")
  end
end

function UMG_Task_Track_C:UpdateBindInputAction()
  self:BindInputAction()
end

function UMG_Task_Track_C:OpenTaskDetailsUIStart()
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenTaskUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_TASK_TEXT, true)
  if isBan then
    return
  else
    isBan, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_WORLD_TASK_UI, false, false)
    if isBan then
      Log.Debug("UMG_Task_Track_C.OpenTaskDetailsUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
      return
    end
    local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
    if not bHadGotCompass then
      return
    end
    self.TheItem:OnTouchStarted()
  end
end

function UMG_Task_Track_C:CancelPcInput()
  if self.TheItem and (self.TheItem.IsLongPress or self.TheItem.IsOnClick) then
    self.TheItem:OnTouchEnded()
  end
end

function UMG_Task_Track_C:OpenTaskDetailsUIEnd()
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenTaskUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_TASK_TEXT, true)
  if isBan then
    return
  else
    isBan, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_WORLD_TASK_UI, false, false)
    if isBan then
      Log.Debug("UMG_Task_Track_C.OpenTaskDetailsUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
      return
    end
    local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
    if not bHadGotCompass then
      return
    end
    self.TheItem:OnTouchEnded()
  end
end

function UMG_Task_Track_C:OnToggleShowEditorTaskID()
  self.TheItem:SetupContent()
end

function UMG_Task_Track_C:OnConstruct()
  self:SetChildViews(self.TheItem)
  self.PushTaskTimestamp = -1
  self.TimeoutHandler = -1
  self.PendingPlaying = false
  self.PendingTasks = nil
  self.PendingIndex = 0
  self.PendingUpdate = false
  self.CurrentTip = nil
  self.HasIgnoredTips = false
  self.NoTrackingFakeTask = DisplayTaskObject(nil, DisplayTaskTypeEnum.NO_TRACKING_TASK, 0)
  NRCEventCenter:RegisterEvent("UMG_Task_Track_C", self, MainUIModuleEvent.MAINUICLOSE, self.StopTaskAnimation)
  NRCEventCenter:RegisterEvent("UMG_Task_Track_C", self, TipsModuleEvent.Tips_LobbyRegionPreUpdate, self.PushTaskItem)
  NRCEventCenter:RegisterEvent("UMG_Task_Track_C", self, TipsModuleEvent.Tips_LobbyMainTaskUpdate, self.UpdateTaskList)
  NRCEventCenter:RegisterEvent("UMG_Task_Track_C", self, TaskModuleEvent.OnActivityTraceTask, self.UpdateTaskList)
  NRCEventCenter:RegisterEvent("UMG_Task_Track_C", self, TaskModuleEvent.SwitchActivityTraceTask, self.OnSwitchActivityTraceTask)
  NRCEventCenter:RegisterEvent("UMG_Task_Track_C", self, TaskModuleEvent.ToggleShowEditorTaskID, self.OnToggleShowEditorTaskID)
  self:BindInputAction()
end

function UMG_Task_Track_C:OnDestruct()
  self:CancelTimeoutDelay()
  self.CurrentTip = nil
  self.PendingIndex = 0
  self.PendingTasks = nil
  NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.StopAnimation)
  NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_LobbyRegionPreUpdate, self.PushTaskItem)
  NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_LobbyMainTaskUpdate, self.UpdateTaskList)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.SwitchActivityTraceTask, self.OnSwitchActivityTraceTask)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.OnActivityTraceTask, self.UpdateTaskList)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.ToggleShowEditorTaskID, self.OnToggleShowEditorTaskID)
  self:UnBindInputAction()
end

return UMG_Task_Track_C

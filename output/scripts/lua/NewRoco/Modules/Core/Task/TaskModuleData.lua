local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local TaskModuleEvent = reload("NewRoco.Modules.Core.Task.TaskModuleEvent")
local TaskObject = require("NewRoco.Modules.Core.Task.TaskObject")
local TaskEnum = require("NewRoco.Modules.Core.Battle.Common.TaskEnum")
local AcceptableTaskTrackItem = require("NewRoco.Modules.Core.Task.AcceptableTaskTrackItem")
local TaskModuleData = _G.NRCData:Extend("TaskModuleData")
TaskModuleData.TaskSortType = {
  Task_Journey = 1,
  Task_Legendary = 2,
  Task_Gleanings = 3
}
TaskModuleData.SkipTaskMap = {
  [81000002] = true
}
local Private = {}
Private.TaskConfFindingCache = {}
Private.TaskConfFindingCache.ParagraphStartTasks = {}
Private.TaskConfFindingCache.ParagraphAllTasks = {}

function TaskModuleData:OverwriteTrackingActivityTask(_taskId)
  local activityTask = self.TaskMap[_taskId]
  if activityTask then
    self.ActivityTraceTask = activityTask
  else
    self.ActivityTraceTask = nil
  end
end

function TaskModuleData:GetActivityTraceTask()
  return self.ActivityTraceTask
end

function TaskModuleData:Ctor()
  NRCData.Ctor(self)
  self:FindTaskOpt_Init()
  self.TaskMap = {}
  self.HiddenTaskMap = {}
  self.first = true
  self.dirty = false
  self.UpdateTaskList = false
  self.OpenTaskCount = 0
  self.GuideTaskCount = 0
  self.MailTask = nil
  self.AcceptTaskList = {}
  self.TaskParagraphIdList = {}
  self.TaskPanelInfo = {}
  self.SelectTaskParagraphInfo = {}
  self.TaskTypeList = {}
  self.Task_Next = {}
  self.SelectIndex = 0
  self.MainTaskTraceParagraph = nil
  self.RandomSubTask = nil
  self.ParagraphStarTask = nil
  self.SelectGleaningParagraphId = nil
  self.AllParagraphList = {}
  self.TrackTaskMap = {}
  self.TaskParagraphId = nil
  self.SelectTokenInfo = nil
  self.CurrentSelectParagraphToken = nil
  self.TokenLocked = nil
  self.TaskList = nil
  self.SubTaskTokenTriggeredInfo = nil
  self.BaseTaskList = nil
  self.SelectTaskTabIndex = -1
  self.ParagraphInfo = nil
  self.OpenTask = nil
  self.OpenParagraph = nil
  self.SelectMagicStampIndex = -1
  self.BaDgeList = {}
  self.MaxPos = 0
  self.ActivityTimeTaskMap = {}
  self:SetBaDgeList()
  self.MagicExtractList = {}
  self.NightmareList = {}
  self.ScrapBookList = {}
  self.MapTaskList = {}
  self.IsOpenTips = false
  self.DelayHandler = -1
end

function TaskModuleData:FindTaskOpt_Init()
  local TaskConfAllDatas = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  self:SetParagraphStarTaskOpt_Init(TaskConfAllDatas)
  self:GetParagraphAllTaskOpt_Init(TaskConfAllDatas)
end

function TaskModuleData:SetSelectTaskParagraphIdList(_data, _SelectTaskTab)
  local data = _data
  local SelectTaskTab = _SelectTaskTab
  if SelectTaskTab.paragraph == nil then
    Log.Error("\231\171\160\232\138\130\228\184\186\231\169\186,\232\175\183\230\163\128\230\159\165\229\188\128\229\167\139\231\171\160\232\138\130\228\184\186\229\164\154\229\176\145")
    return
  end
  self.TaskPanelInfo.TypeInfo = data
  local TaskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  local TaskParagraphIdList = {}
  for i, _TaskConf in pairs(TaskConf) do
    if _TaskConf.task_class == data.task_type and _TaskConf.paragraph_id == SelectTaskTab.paragraph then
      table.insert(TaskParagraphIdList, _TaskConf.id)
      if _TaskConf.is_para_start then
        Log.Debug(_TaskConf.name, _TaskConf.id, "TaskModuleData:SetSelectTaskParagraphIdList")
        self.ParagraphStarTask = _TaskConf.id
      end
    end
  end
  self.TaskParagraphIdList = TaskParagraphIdList
  return TaskParagraphIdList
end

function TaskModuleData:GetParagraphAllTask(ParagraphData)
  return self:OPT_GetParagraphAllTask(ParagraphData)
end

function TaskModuleData:OPT_GetParagraphAllTask(ParagraphData)
  if ParagraphData then
    local TaskParagraphIdList = self:GetParagraphAllTaskOpt_Get(ParagraphData.paragraph)
    return TaskParagraphIdList or {}
  end
  return {}
end

function TaskModuleData:GetParagraphAllTaskOpt_Init(TaskConfAllDatas)
  local Cache = Private.TaskConfFindingCache.ParagraphAllTasks
  for i, TaskConf in pairs(TaskConfAllDatas) do
    local paragraph_id = TaskConf.paragraph_id
    if paragraph_id then
      local AllSameParagraphIdTasks = Private.TaskConfFindingCache.ParagraphAllTasks[paragraph_id]
      if not AllSameParagraphIdTasks then
        AllSameParagraphIdTasks = {}
        Private.TaskConfFindingCache.ParagraphAllTasks[paragraph_id] = AllSameParagraphIdTasks
      end
      table.insert(AllSameParagraphIdTasks, TaskConf.id)
    end
  end
end

function TaskModuleData:GetParagraphAllTaskOpt_Get(paragraph_id)
  local Cache = Private.TaskConfFindingCache.ParagraphAllTasks
  return Cache[paragraph_id]
end

function TaskModuleData:SetCurrentTaskParagraphInfo(task_info_list)
  if not task_info_list then
    return
  end
  local LeftPanelInfo = {}
  local RightPanelInfo = {}
  local FindTaskInfo = {}
  local TaskConf, StartPara
  self.MailTask = nil
  local TaskList = task_info_list
  self.TaskList = task_info_list
  for i, Task in ipairs(TaskList) do
    TaskConf = _G.DataConfigManager:GetTaskConf(Task.id)
    if TaskConf.is_para_start == true then
      StartPara = TaskConf
      table.insert(RightPanelInfo, {PlayerTaskInfo = Task, TaskConf = TaskConf})
      LeftPanelInfo = self:SetLeftInfo(TaskConf.paragraph_id)
    end
    if Task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      self.TaskPanelInfo.StateOpen = Task
    end
    FindTaskInfo[Task.id] = Task
    if Task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      self.MailTask = TaskConf
    end
  end
  if nil == StartPara then
    local TaskConfInfo = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
    for i, _TaskConf in pairs(TaskConfInfo) do
      if _TaskConf and TaskConf and _TaskConf.task_class == TaskConf.task_class and _TaskConf.paragraph_id == TaskConf.paragraph_id and _TaskConf.is_para_start == true then
        StartPara = _TaskConf
        table.insert(RightPanelInfo, {TaskConf = _TaskConf})
        LeftPanelInfo = self:SetLeftInfo(_TaskConf.paragraph_id)
        local _, next_task = self:GetNotHiddenTask(StartPara.next_task, StartPara)
        while _ and next_task ~= TaskConf.id do
          local NextTaskConf = _G.DataConfigManager:GetTaskConf(next_task)
          table.insert(RightPanelInfo, {TaskConf = NextTaskConf})
          StartPara = NextTaskConf
          _, next_task = self:GetNotHiddenTask(StartPara.next_task, StartPara)
        end
      end
    end
  end
  if StartPara then
    local IsShowExTraTask, TaskInfo = self:ShowExtraTaskByTokenInfo()
    local _, next_task = self:IsHasTask(TaskInfo, StartPara, FindTaskInfo)
    while _ do
      local NextTaskConf = _G.DataConfigManager:GetTaskConf(next_task)
      table.insert(RightPanelInfo, {
        PlayerTaskInfo = FindTaskInfo[next_task],
        TaskConf = NextTaskConf
      })
      if TaskInfo and TaskInfo.id == StartPara.id then
        TaskInfo = nil
      end
      StartPara = NextTaskConf
      _, next_task = self:IsHasTask(TaskInfo, StartPara, FindTaskInfo)
    end
    if self.TaskPanelInfo.TypeInfo.task_type == Enum.TaskClassType.TCT_MAIN or self.TaskPanelInfo.TypeInfo.task_type == Enum.TaskClassType.TCT_SUB then
      RightPanelInfo = self:Reverse(RightPanelInfo)
    end
  end
  self.TaskPanelInfo.LeftPanelInfo = LeftPanelInfo
  self.TaskPanelInfo.RightPanelInfo = RightPanelInfo
end

function TaskModuleData:IsHasTask(TaskInfo, StartPara, FindTaskInfo)
  local next_task = {}
  if StartPara.task_class == Enum.TaskClassType.TCT_JOURNEY then
    if not StartPara.next_task or 0 == #StartPara.next_task then
      if StartPara.task_flag and #StartPara.task_flag > 0 then
        local hasFlag = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(tonumber(StartPara.task_flag[2]))
        if hasFlag then
          table.insert(next_task, StartPara.task_flag[1])
        end
        hasFlag = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(tonumber(StartPara.task_flag[4]))
        if hasFlag then
          table.insert(next_task, StartPara.task_flag[3])
        end
      end
    else
      next_task = StartPara.next_task
    end
  else
    next_task = TaskInfo and TaskInfo.id == StartPara.id and {
      TaskInfo.token_next_task[1].next_task
    } or StartPara.next_task
  end
  for i, task in ipairs(next_task) do
    if FindTaskInfo[task] then
      return true, task
    end
  end
  return false, nil
end

function TaskModuleData:GetNotHiddenTask(next_task, StartPara)
  for i, task in ipairs(next_task) do
    local TaskConf = _G.DataConfigManager:GetTaskConf(task)
    if TaskConf and StartPara and TaskConf.task_class == StartPara.task_class and TaskConf.paragraph_id == StartPara.paragraph_id then
      return true, task
    end
  end
  return false, nil
end

function TaskModuleData:Reverse(num)
  for i = 0, (#num - 1) / 2 do
    local temp = num[i + 1]
    num[i + 1] = num[#num - i]
    num[#num - i] = temp
  end
  local TrackTask, index
  for i, _ in ipairs(num) do
    if _.PlayerTaskInfo and _.PlayerTaskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      TrackTask = _
      index = i
    end
  end
  if TrackTask and index then
    table.remove(num, index)
    table.insert(num, 1, TrackTask)
  end
  return num
end

function TaskModuleData:SetLeftInfo(_paragraph_id)
  local paragraph_id = _paragraph_id
  local ParagraphConf = _G.DataConfigManager:GetParagraphConf(paragraph_id)
  return ParagraphConf
end

function TaskModuleData:SetTaskTypeList(_task_type_list)
  local task_type_list = _task_type_list
  local Icon, Icon1, Sort, PanelIndex, TaksTypeName
  for i, Item in ipairs(task_type_list) do
    if Item.task_type == Enum.TaskClassType.TCT_JOURNEY then
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask/Frames/img_lvtu2_png.img_lvtu2_png'"
      Icon1 = "PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask/Frames/img_lvtu_png.img_lvtu_png'"
      Sort = self.TaskSortType.Task_Journey
      PanelIndex = 0
      TaksTypeName = LuaText.taskmoduledata_1
      Item = self:SetTaskType(Item, Icon, Icon1, Sort, PanelIndex, TaksTypeName)
    elseif Item.task_type == Enum.TaskClassType.TCT_MAIN then
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask/Frames/img_qitan2_png.img_qitan2_png'"
      Icon1 = "PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask/Frames/img_qitan1_png.img_qitan1_png'"
      Sort = self.TaskSortType.Task_Legendary
      PanelIndex = 1
      TaksTypeName = LuaText.taskmoduledata_2
      Item = self:SetTaskType(Item, Icon, Icon1, Sort, PanelIndex, TaksTypeName)
    elseif Item.task_type == Enum.TaskClassType.TCT_SUB then
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask/Frames/img_shiyi1_png.img_shiyi1_png'"
      Icon1 = "PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask/Frames/img_shiyi_png.img_shiyi_png'"
      Sort = self.TaskSortType.Task_Gleanings
      PanelIndex = 2
      TaksTypeName = LuaText.taskmoduledata_3
      Item = self:SetTaskType(Item, Icon, Icon1, Sort, PanelIndex, TaksTypeName)
    end
  end
  self.TaskTypeList = task_type_list
  table.sort(self.TaskTypeList, function(a, b)
    return a.Sort < b.Sort
  end)
end

function TaskModuleData:UpdateTaskTypeList(_TaskId)
  local TaskConf = _G.DataConfigManager:GetTaskConf(_TaskId)
  Log.Debug(TaskConf.paragraph_id, "TaskModuleData:UpdateTaskTypeList")
  for i, TaskType in ipairs(self.TaskTypeList) do
    if TaskType.task_type == Enum.TaskClassType.TCT_SUB then
      local nowTimePoke = math.floor(_G.ZoneServer:GetServerTime() / 1000)
      self:UpdateTaskOpenState(TaskType.LeftList, TaskConf.paragraph_id, false)
      self:UpdateTaskOpenState(TaskType.LeftList, TaskConf.paragraph_id, true, nowTimePoke, 1)
      self:UpdateTaskOpenState(TaskType.open_paragraph, TaskConf.paragraph_id, true, nowTimePoke)
      self:UpdateTaskOpenState(TaskType.will_paragraph, TaskConf.paragraph_id, false)
    end
  end
end

function TaskModuleData:FindTaskTypeInfo(PredicateFunc)
  for i, taskTypeInfo in ipairs(self.TaskTypeList) do
    local bMatched = PredicateFunc(taskTypeInfo)
    if bMatched then
      return taskTypeInfo
    end
  end
  return nil
end

function TaskModuleData:UpdateTaskOpenState(TaskTypeList, Paragraph, IsAdd, nowTimePoke, Pos)
  local IsHasParagraph = false
  local RemoveIndex
  for i, TaskType in ipairs(TaskTypeList) do
    if TaskType.paragraph == Paragraph then
      IsHasParagraph = true
      RemoveIndex = i
      break
    end
  end
  Log.Debug(IsHasParagraph, RemoveIndex, Paragraph, nowTimePoke, "TaskModuleData:UpdateTaskOpenState")
  if not IsHasParagraph then
    if IsAdd then
      if Pos then
        table.insert(TaskTypeList, Pos, {
          paragraph = Paragraph,
          time = nowTimePoke,
          Type = 0
        })
      else
        table.insert(TaskTypeList, {paragraph = Paragraph, time = nowTimePoke})
      end
    end
  elseif not IsAdd then
    table.remove(TaskTypeList, RemoveIndex)
  end
end

function TaskModuleData:SetTaskType(_Item, _Icon, _Icon1, _Sort, _PanelIndex, _TaksTypeName)
  local function SortByTime(a, b)
    return a.time > b.time
  end
  
  local Item = _Item
  Item.Icon = _Icon
  Item.Icon1 = _Icon1
  Item.Sort = _Sort
  Item.PanelIndex = _PanelIndex
  Item.TaksTypeName = _TaksTypeName
  if Item.open_paragraph and #Item.open_paragraph > 0 then
    table.sort(Item.open_paragraph, SortByTime)
    Item.open_paragraph = self:SetTaskFinishType(Item.open_paragraph, 0)
    Item.open_paragraph = self:FiltrationParagraphList(Item.open_paragraph)
    Item.LeftList = Item.open_paragraph
  end
  if Item.done_paragraph and #Item.done_paragraph > 0 then
    table.sort(Item.done_paragraph, SortByTime)
    Item.done_paragraph = self:SetTaskFinishType(Item.done_paragraph, 1)
    Item.done_paragraph = self:FiltrationParagraphList(Item.done_paragraph)
    Item.LeftList = self:MergeParagraphList(Item.LeftList, Item.done_paragraph)
  end
  if Item.will_paragraph and #Item.will_paragraph > 0 then
    Item.will_paragraph = self:SetTaskFinishType(Item.will_paragraph, -1, true)
    Item.will_paragraph = self:FiltrationParagraphList(Item.will_paragraph)
    if Item.LeftList then
      Item.LeftList = self:MergeParagraphList(Item.LeftList, Item.will_paragraph)
    else
      Item.LeftList = self:MergeParagraphList(Item.open_paragraph, Item.will_paragraph)
    end
  end
  if Item.LeftList == nil then
    Item.open = false
  end
  return Item
end

function TaskModuleData:SetTaskFinishType(_TypeList, _Type, _will_paragraph)
  local will_paragraph = _will_paragraph
  local TypeList = _TypeList
  if true == will_paragraph then
    local TypeInfoList = {}
    for i, List in ipairs(TypeList) do
      table.insert(TypeInfoList, {paragraph = List, Type = _Type})
    end
    TypeList = TypeInfoList
  else
    for i, List in ipairs(TypeList) do
      List.Type = _Type
    end
  end
  return TypeList
end

function TaskModuleData:MergeParagraphList(ParagraghStart, paragraph)
  local List = ParagraghStart
  if nil == List and nil == paragraph then
    return nil
  end
  if nil == List then
    List = {}
  end
  if nil == paragraph then
    return List
  end
  for j, paragraphInfo in ipairs(paragraph) do
    table.insert(List, paragraphInfo)
  end
  return List
end

function TaskModuleData:FiltrationParagraphList(_ParagraghList)
  local ParagraghList = _ParagraghList
  local List = {}
  for i, v in ipairs(ParagraghList) do
    local ParagraphConf = _G.DataConfigManager:GetParagraphConf(v.paragraph)
    if not v.is_hide and 0 ~= v.paragraph and ParagraphConf and not ParagraphConf.is_hide_paragraph then
      table.insert(List, v)
    end
  end
  if nil == List[1] then
    return nil
  end
  return List
end

function TaskModuleData:SetSelectTaskParagraphInfo(_data)
  self.SelectTaskParagraphInfo = _data
end

local ErrorIDs = {}

function TaskModuleData:_UpdateTaskInfos(taskInfos, full)
  if not taskInfos then
    return false
  end
  table.clear(ErrorIDs)
  local UpdatedTaskIDs
  local hasAnyUpdate = false
  local bIsRefreshParagraph = false
  for _, taskInfo in ipairs(taskInfos) do
    if not taskInfo then
    elseif not taskInfo.id then
    elseif 0 == taskInfo.id then
    elseif taskInfo.hide then
      do
        local Old = self.HiddenTaskMap[taskInfo.id]
        if not Old or Old ~= taskInfo.state then
          Log.Debug("[TaskFlow]\233\154\144\232\151\143\228\187\187\229\138\161\231\138\182\230\128\129\230\155\180\230\150\176", taskInfo.id, Old and table.getKeyName(ProtoEnum.EMTaskState, Old) or "\230\151\160", "=>", table.getKeyName(ProtoEnum.EMTaskState, taskInfo.state))
        end
        self.HiddenTaskMap[taskInfo.id] = taskInfo.state
        _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.OnHiddenTaskUpdated, taskInfo)
      end
    else
      local TO = self.TaskMap[taskInfo.id]
      if TO and taskInfo then
        TO:UpdateTask(taskInfo, true)
        hasAnyUpdate = true
        if self.TrackTaskMap[taskInfo.id] and (TO:IsFinish() or taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSEING) then
          self.TrackTaskMap[taskInfo.id] = nil
          TO:RemoveTrackers(taskInfo)
        end
        self:UpdateMapTaskList(TO)
        if TO.Config and TO.Config.paragraph_id and self.AllParagraphList[TO.Config.paragraph_id] and (TO.Config.is_para_done and TO:IsFinish() or taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSEING) then
          bIsRefreshParagraph = true
        end
      elseif taskInfo and not TO then
        self.UpdateTaskList = true
        local Conf = _G.DataConfigManager:GetTaskConf(taskInfo.id)
        if Conf then
          TO = TaskObject(self.TaskModule, taskInfo)
          TO:UpdateTask(taskInfo, not full)
          self.TaskMap[taskInfo.id] = TO
          hasAnyUpdate = true
          if not TO:IsFinish() and taskInfo.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSEING then
            self.TrackTaskMap[taskInfo.id] = TO
            self:AddMapTaskList(TO)
          end
          if TO.Config and TO.Config.paragraph_id and not self.AllParagraphList[TO.Config.paragraph_id] then
            bIsRefreshParagraph = true
          end
        else
          table.insert(ErrorIDs, taskInfo.id)
        end
      end
      if full then
        UpdatedTaskIDs = UpdatedTaskIDs or {}
        table.insert(UpdatedTaskIDs, taskInfo.id)
      end
    end
  end
  if full and UpdatedTaskIDs then
    local RemovedTaskIDs = {}
    for ID, _ in pairs(self.TaskMap) do
      if not table.contains(UpdatedTaskIDs, ID) then
        table.insert(RemovedTaskIDs, ID)
      end
    end
    hasAnyUpdate = self:_RemoveTaskInfos(RemovedTaskIDs)
  end
  if hasAnyUpdate or full then
    self:UpdateCurTrackTask()
  end
  if bIsRefreshParagraph then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.OnCmdTaskPanelAllInfoReq, true)
  end
  if not RocoEnv.IS_SHIPPING and #ErrorIDs > 0 then
    local IDs = ""
    for _, ID in ipairs(ErrorIDs) do
      IDs = string.format("%s;%d", IDs, ID)
    end
    local Context = DialogContext()
    Context:SetCloseOnOK(true)
    Context:SetButtonText(LuaText.general_confirm)
    Context:SetMode(DialogContext.Mode.OK)
    Context:SetContent(string.format(LuaText.task_conf_not_found, IDs))
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  end
  self.first = false
  return hasAnyUpdate
end

function TaskModuleData:_RemoveTaskInfos(removeList)
  if not removeList then
    return false
  end
  local hasAnyUpdate = false
  for _, remove in ipairs(removeList) do
    local TO = self.TaskMap[remove]
    if TO then
      hasAnyUpdate = true
      self.UpdateTaskList = true
      TO:RemoveTrackers()
      TO:OnRemove()
      TO.MarkedFinished = true
      TO:Destroy()
    end
    self.TaskMap[remove] = nil
    self.TrackTaskMap[remove] = nil
    self.MapTaskList[remove] = nil
    local Hidden = self.HiddenTaskMap[remove]
    if Hidden then
      _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.OnHiddenTaskRemoved, remove, Hidden)
      Log.Debug("\231\167\187\233\153\164\233\154\144\232\151\143\228\187\187\229\138\161", remove)
    end
    self.HiddenTaskMap[remove] = nil
  end
  return hasAnyUpdate
end

function TaskModuleData:AddMapTaskList(InTaskObject)
  if InTaskObject and InTaskObject.Info and InTaskObject.Info.id and (InTaskObject.Config.task_class == Enum.TaskClassType.TCT_JOURNEY or InTaskObject:IsTrack()) and not InTaskObject:IsFinish() and InTaskObject.Info.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSEING then
    self.MapTaskList[InTaskObject.Info.id] = InTaskObject
  end
end

function TaskModuleData:UpdateMapTaskList(InTaskObject)
  if InTaskObject and InTaskObject.Info and InTaskObject.Info.id then
    if InTaskObject.Config.task_class == Enum.TaskClassType.TCT_JOURNEY then
      if not InTaskObject:IsFinish() and InTaskObject.Info.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSEING then
        self.MapTaskList[InTaskObject.Info.id] = InTaskObject
      else
        self.MapTaskList[InTaskObject.Info.id] = nil
      end
    elseif InTaskObject:IsTrack() then
      self.MapTaskList[InTaskObject.Info.id] = InTaskObject
    elseif not InTaskObject:IsTrack() then
      self.MapTaskList[InTaskObject.Info.id] = nil
    end
  end
end

function TaskModuleData:CalcSubTrackTasks()
  for _, Task in pairs(self.TaskMap) do
    local RelativeTasks = Task:CollectRelativeTasks()
    Task:SetSubTrackTasks(RelativeTasks)
  end
end

function TaskModuleData:MakeDirty()
  self.dirty = true
  if self.DelayHandler > 0 then
    _G.DelayManager:CancelDelayById(self.DelayHandler)
    self.DelayHandler = -1
  end
  self.DelayHandler = _G.DelayManager:DelayFrames(1, self.Update, self)
end

function TaskModuleData:OnUpdate()
  NRCEventCenter:DispatchEvent(TaskModuleEvent.TASK_DATA_CHANGE)
end

function TaskModuleData:Update()
  if self.dirty then
    self.dirty = false
    self:OnUpdate()
  end
end

function TaskModuleData:UpdateCurTrackTask()
  for _, task in pairs(self.TaskMap) do
    if task.TrackParentTask and task.TrackParentTask.Info and task.TrackParentTask.Info.is_track then
      self:SetTrackTask(task.TrackParentTask)
      return
    elseif task.Info and task.Info.is_track then
      self:SetTrackTask(task)
      return
    end
  end
  self:SetTrackTask(nil)
end

function TaskModuleData:Clear()
  self.first = true
  self.AllParagraphList = {}
  for _, task in pairs(self.TaskMap) do
    task:Destroy()
  end
  table.clear(self.TaskMap)
  for _, task in pairs(self.AcceptTaskList) do
    task:Destroy()
  end
  table.clear(self.AcceptTaskList)
end

function TaskModuleData:GetTaskInfo()
  return self.TaskInfo
end

function TaskModuleData:GetTaskTypeList()
  return self.TaskTypeList
end

function TaskModuleData:GetSelectIndex()
  return self.SelectIndex
end

function TaskModuleData:SetSelectIndex(_Index)
  self.SelectIndex = _Index
end

function TaskModuleData:SetMainTaskTraceParagraph(TraceParagraph)
  self.MainTaskTraceParagraph = TraceParagraph
end

function TaskModuleData:GetMainTaskTraceParagraph()
  return self.MainTaskTraceParagraph
end

function TaskModuleData:GetTaskPanelInfo()
  return self.TaskPanelInfo
end

function TaskModuleData:GetSelectTaskParagraphInfo()
  return self.SelectTaskParagraphInfo
end

function TaskModuleData:GetRandomSubTask()
  return self.RandomSubTask
end

function TaskModuleData:SetRandomSubTask(_RandomSubTask)
  self.RandomSubTask = _RandomSubTask
end

function TaskModuleData:GetTaskParagraphId()
  return self.TaskParagraphId
end

function TaskModuleData:SavaTaskParagraphId(_TaskId)
  if not _TaskId then
    self.TaskParagraphId = nil
    return
  end
  local TaskConf = _G.DataConfigManager:GetTaskConf(_TaskId)
  self.TaskParagraphId = TaskConf.paragraph_id
end

function TaskModuleData:IsShowEnvelope(last_get_time)
  if not last_get_time then
    return true
  end
  local nowTimePoke = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  local nowTime = os.date("*t", nowTimePoke)
  local EnvelopeTime = os.date("*t", last_get_time)
  if nowTime.year == EnvelopeTime.year and nowTime.month == EnvelopeTime.month and nowTime.day == EnvelopeTime.day then
    return false
  end
  return true
end

function TaskModuleData:GetLacquerIsUnLockByParagraph(_Paragraph)
  local TaskConfInfo = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  local StartTask
  for i, _TaskConf in pairs(TaskConfInfo) do
    if _TaskConf.paragraph_id == _Paragraph and _TaskConf.is_para_start then
      StartTask = _TaskConf.id
      break
    end
  end
  if StartTask then
    local SubTaskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SUB_TASK_CONF):GetAllDatas()
    for i, SubTask in pairs(SubTaskConf) do
      if StartTask == SubTask.id and SubTask.token_slot_num > 0 then
        return true, StartTask
      end
    end
  end
  return false
end

function TaskModuleData:GetRewardByIsUnLockLacquer()
  Log.Debug(self.ParagraphStarTask, self.CurrentSelectParagraphToken, "TaskModuleData:GetRewardByIsUnLockLacquer")
  if not self.ParagraphStarTask then
    Log.Warning("\232\181\183\229\167\139\228\187\187\229\138\161\228\184\186\231\169\186,\230\163\128\230\181\139\229\137\141\231\171\175\230\149\176\230\141\174\233\151\174\233\162\152")
    return 0
  end
  local TaskConf = _G.DataConfigManager:GetTaskConf(self.ParagraphStarTask)
  local _, next_task = true, TaskConf.id
  if next_task then
    local FindTask = {}
    FindTask[next_task] = {next_task}
    while _ and next_task do
      local IsSucceed = false
      local NextTaskConf = _G.DataConfigManager:GetTaskConf(next_task)
      if self.CurrentSelectParagraphToken and self.CurrentSelectParagraphToken.task_token_info and self.CurrentSelectParagraphToken.task_token_info[1].task_token_id then
        if NextTaskConf.token_next_task[1] and NextTaskConf.token_next_task[1].token_required == self.CurrentSelectParagraphToken.task_token_info[1].task_token_id and not self:IsFinishTokenTask() then
          IsSucceed = true
          next_task = NextTaskConf.token_next_task[1].next_task
        elseif NextTaskConf.next_task == nil or 0 == #NextTaskConf.next_task then
          return NextTaskConf.Reward
        end
      elseif NextTaskConf.next_task == nil or 0 == #NextTaskConf.next_task then
        return NextTaskConf.Reward
      end
      if not IsSucceed then
        _, next_task = self:GetNotHiddenTask(NextTaskConf.next_task, NextTaskConf)
      end
      if FindTask[next_task] then
        Log.Warning("\231\173\150\229\136\146\233\133\141\231\189\174\230\156\137\230\173\187\229\190\170\231\142\175\228\187\187\229\138\161\239\188\129\239\188\129\239\188\129", table.tostring(FindTask[next_task]))
        return
      end
      if next_task then
        FindTask[next_task] = {next_task}
      else
        return NextTaskConf.Reward
      end
    end
  end
  return 0
end

function TaskModuleData:ShowExtraTaskByTokenInfo()
  local LacquerIsUnLock, StartTaskId = self:GetLacquerIsUnLockByParagraph(self.SelectGleaningParagraphId)
  Log.Debug(LacquerIsUnLock, self.CurrentSelectParagraphToken, self.TokenLocked, self.SelectGleaningParagraphId, "TaskModuleData:ShowExtraTaskByTokenInfo")
  if not LacquerIsUnLock then
    return false
  end
  if not (self.CurrentSelectParagraphToken and self.CurrentSelectParagraphToken.task_token_info) or not self.CurrentSelectParagraphToken.task_token_info[1].task_token_id then
    return false
  end
  local TaskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  local TaskInfo
  for i, _TaskConf in pairs(TaskConf) do
    if _TaskConf.task_class == Enum.TaskClassType.TCT_SUB and _TaskConf.paragraph_id == self.SelectGleaningParagraphId and _TaskConf.token_next_task[1] and _TaskConf.token_next_task[1].token_required == self.CurrentSelectParagraphToken.task_token_info[1].task_token_id and not self:IsFinishTokenTask() then
      TaskInfo = _TaskConf
    end
  end
  if self.TokenLocked and 0 ~= self.TokenLocked then
    return false, TaskInfo
  end
  if TaskInfo then
    return true, TaskInfo
  end
  return false
end

function TaskModuleData:ParagraphFinishShowContent(Content)
  local TaskConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TASK_CONF):GetAllDatas()
  local TaskList = self.TaskList
  for i, _TaskConf in pairs(TaskConf) do
    if _TaskConf.task_class == Enum.TaskClassType.TCT_SUB and _TaskConf.paragraph_id == self.SelectGleaningParagraphId and _TaskConf.extra_des then
      local IsSucceed = false
      for j, TaskData in ipairs(TaskList) do
        if TaskData.id == _TaskConf.id then
          IsSucceed = true
          table.insert(Content, {
            Text = _TaskConf.extra_des,
            Type = TaskEnum.ContentType.Exist,
            IsFinish = true
          })
        end
      end
      if not IsSucceed then
        table.insert(Content, {
          Type = TaskEnum.ContentType.Null,
          IsFinish = true
        })
      end
    end
  end
  return Content
end

function TaskModuleData:SetCurrentSelectParagraphToken(_CurrentSelectParagraphToken)
  self.CurrentSelectParagraphToken = _CurrentSelectParagraphToken
end

function TaskModuleData:SetEquipmentParagraphTokenToken(SelectTokenInfo, ParagraphStarTask)
  if not self.CurrentSelectParagraphToken or not self.CurrentSelectParagraphToken.task_token_info then
    self.CurrentSelectParagraphToken = _G.ProtoMessage:newOngoingSubTaskInfo()
    self.CurrentSelectParagraphToken.task_token_info[1] = {}
  end
  self.CurrentSelectParagraphToken.sub_task_id = ParagraphStarTask
  self.CurrentSelectParagraphToken.task_token_info[1].task_token_get_time = SelectTokenInfo.task_token_get_time
  self.CurrentSelectParagraphToken.task_token_info[1].task_token_id = SelectTokenInfo.task_token_id
  self.CurrentSelectParagraphToken.task_token_info[1].task_token_state = 0
end

function TaskModuleData:GetCurrentSelectParagraphToken()
  return self.CurrentSelectParagraphToken
end

function TaskModuleData:SetSelectTokenInfo(_SelectTokenInfo)
  self.SelectTokenInfo = _SelectTokenInfo
end

function TaskModuleData:GetSelectTokenInfo()
  return self.SelectTokenInfo
end

function TaskModuleData:GetParagraphStarTask()
  return self.ParagraphStarTask
end

function TaskModuleData:SetParagraphStarTask(ParagraphData)
  self:OPT_SetParagraphStarTask(ParagraphData)
end

function TaskModuleData:OPT_SetParagraphStarTask(ParagraphData)
  if ParagraphData then
    self.ParagraphStarTask = self:SetParagraphStarTaskOpt_Get(ParagraphData.paragraph)
    if not self.ParagraphStarTask then
      Log.WarningFormat("\232\175\165\231\171\160\232\138\130(%s)\228\187\187\229\138\161\230\178\161\230\156\137\232\181\183\229\167\139\228\187\187\229\138\161\239\188\129\239\188\129\239\188\129", tostring(ParagraphData.paragraph))
    end
  end
end

function TaskModuleData:SetParagraphStarTaskOpt_Init(TaskConfAllDatas)
  local Cache = Private.TaskConfFindingCache.ParagraphStartTasks
  for i, TaskConf in pairs(TaskConfAllDatas) do
    if TaskConf.paragraph_id and TaskConf.is_para_start then
      Cache[TaskConf.paragraph_id] = TaskConf.id
    end
  end
end

function TaskModuleData:SetParagraphStarTaskOpt_Get(paragraph_id)
  local Cache = Private.TaskConfFindingCache.ParagraphStartTasks
  return Cache[paragraph_id]
end

function TaskModuleData:SetTokenLocked(_TokenLocked)
  self.TokenLocked = _TokenLocked
end

function TaskModuleData:GetTokenLocked()
  return self.TokenLocked
end

function TaskModuleData:SetSelectGleaningParagraphId(_SelectGleaningParagraphId)
  self.SelectGleaningParagraphId = _SelectGleaningParagraphId
end

function TaskModuleData:GetSelectGleaningParagraphId()
  return self.SelectGleaningParagraphId
end

function TaskModuleData:IsFinishTokenTask()
  if not (self.CurrentSelectParagraphToken and self.CurrentSelectParagraphToken.task_token_info) or not self.CurrentSelectParagraphToken.task_token_info[1].task_token_id then
    return false
  end
  local TokenFinishedQueue = self.SubTaskTokenTriggeredInfo
  for i, TokenId in ipairs(TokenFinishedQueue) do
    if TokenId.triggered_sub_task_token_id == self.CurrentSelectParagraphToken.task_token_info[1].task_token_id then
      return true
    end
  end
  return false
end

function TaskModuleData:SetSubTaskTokenTriggeredInfo(_SubTaskTokenTriggeredInfo)
  self.SubTaskTokenTriggeredInfo = _SubTaskTokenTriggeredInfo or {}
end

function TaskModuleData:GetSubTaskTokenTriggeredInfo()
  return self.SubTaskTokenTriggeredInfo
end

function TaskModuleData:GetMailTask()
  return self.MailTask
end

function TaskModuleData:SetMailTask(_MailTask)
  self.MailTask = _MailTask
end

function TaskModuleData:SetParagraphData(_task_type_list)
  local task_type_list = _task_type_list
  local PanelIndex
  local BaseTaskList = {}
  for i, Item in ipairs(task_type_list) do
    table.insert(BaseTaskList, Item)
    if Item.task_type == Enum.TaskClassType.TCT_JOURNEY then
      PanelIndex = TaskEnum.TaskTab.journey
    elseif Item.task_type == Enum.TaskClassType.TCT_MAIN then
      PanelIndex = TaskEnum.TaskTab.Legendary
    elseif Item.task_type == Enum.TaskClassType.TCT_SUB then
      PanelIndex = TaskEnum.TaskTab.Gleanings
    end
    BaseTaskList[i] = self:SetParagraphBaseData(BaseTaskList[i], PanelIndex)
  end
  table.sort(BaseTaskList, function(a, b)
    return a.PanelIndex < b.PanelIndex
  end)
  self.BaseTaskList = BaseTaskList
end

function TaskModuleData:SetAllParagraph()
end

function TaskModuleData:SetParagraphBaseData(_Item, _PanelIndex)
  local function SortByTime(a, b)
    return a.time > b.time
  end
  
  local function SortByUnitId(a, b)
    return a.UnitConf.id < b.UnitConf.id
  end
  
  local Item = _Item
  Item.PanelIndex = _PanelIndex
  Item.UnitList = {}
  Item.AllParagraph = nil
  local ParagraphInfo = {}
  if Item.open_paragraph and #Item.open_paragraph > 0 then
    table.sort(Item.open_paragraph, SortByTime)
    Item.open_paragraph = self:SetTaskFinishType(Item.open_paragraph, TaskEnum.TaskParagraphFinishState.open)
    Item.open_paragraph = self:FiltrationParagraphList(Item.open_paragraph)
    Item.AllParagraph = Item.open_paragraph
  end
  if Item.done_paragraph and #Item.done_paragraph > 0 then
    table.sort(Item.done_paragraph, SortByTime)
    Item.done_paragraph = self:SetTaskFinishType(Item.done_paragraph, TaskEnum.TaskParagraphFinishState.done)
    Item.done_paragraph = self:FiltrationParagraphList(Item.done_paragraph)
    Item.AllParagraph = self:MergeParagraphList(Item.AllParagraph, Item.done_paragraph)
  end
  if Item.AllParagraph and #Item.AllParagraph > 0 then
    local UnitList = {}
    for i, Paragraph in ipairs(Item.AllParagraph) do
      local ParagraphConf = _G.DataConfigManager:GetParagraphConf(Paragraph.paragraph)
      self.AllParagraphList[Paragraph.paragraph] = true
      if not ParagraphConf.is_hide_paragraph then
        local UnitConf
        local IsHasUnit = false
        local IsSeasonTask = false
        if ParagraphConf.unit_id and 0 ~= ParagraphConf.unit_id then
          UnitConf = _G.DataConfigManager:GetUnitConf(ParagraphConf.unit_id)
          IsHasUnit = true
        end
        if ParagraphConf.season_task then
          IsSeasonTask = true
        end
        if IsHasUnit then
          if UnitList[UnitConf.id] then
            table.insert(UnitList[UnitConf.id].ParagraphList, {ParagraphInfo = Paragraph})
          else
            UnitList[UnitConf.id] = {}
            UnitList[UnitConf.id].UnitConf = UnitConf
            UnitList[UnitConf.id].IsHasUnit = IsHasUnit
            UnitList[UnitConf.id].IsSeasonTask = IsSeasonTask
            UnitList[UnitConf.id].ParagraphList = {}
            table.insert(UnitList[UnitConf.id].ParagraphList, {ParagraphInfo = Paragraph})
          end
        else
          table.insert(ParagraphInfo, {ParagraphInfo = Paragraph, IsHasUnit = IsHasUnit})
        end
      end
    end
    table.sort(UnitList, SortByUnitId)
    self:SortUnitParagraph(UnitList)
    Item.UnitList = self:MergeUnit(UnitList, Item.UnitList)
    Item.UnitList = self:MergeUnit(ParagraphInfo, Item.UnitList)
  end
  return Item
end

function TaskModuleData:MergeUnit(List, UnitList)
  for i, _ in pairs(List) do
    table.insert(UnitList, _)
  end
  return UnitList
end

function TaskModuleData:SortUnitParagraph(UnitList)
  for i, _ in pairs(UnitList) do
    table.sort(_.ParagraphList, function(a, b)
      return a.ParagraphInfo.time > b.ParagraphInfo.time
    end)
  end
end

function TaskModuleData:GetSelectTaskTabIndex()
  return self.SelectTaskTabIndex
end

function TaskModuleData:SetSelectTaskTabIndex(_SelectTaskTabIndex)
  self.SelectTaskTabIndex = _SelectTaskTabIndex
end

function TaskModuleData:GetSelectMagicStampIndex()
  return self.SelectMagicStampIndex
end

function TaskModuleData:SetSelectMagicStampIndex(_SelectMagicStampIndex)
  self.SelectMagicStampIndex = _SelectMagicStampIndex
end

function TaskModuleData:GetBaseTaskList()
  return self.BaseTaskList
end

function TaskModuleData:SetParagraphInfo(_ParagraphInfo)
  self.ParagraphInfo = _ParagraphInfo
end

function TaskModuleData:GetParagraphInfo()
  return self.ParagraphInfo
end

function TaskModuleData:SetOpenTask(_OpenTask)
  self.OpenTask = _OpenTask
end

function TaskModuleData:GetOpenTask()
  return self.OpenTask
end

function TaskModuleData:SetOpenParagraph(_OpenParagraph)
  self.OpenParagraph = _OpenParagraph
end

function TaskModuleData:GetOpenParagraph()
  return self.OpenParagraph
end

function TaskModuleData:SetTaskList(_TaskList)
  self.TaskList = _TaskList
end

function TaskModuleData:FindTask(PredicateFunc)
  for i, taskInfo in ipairs(self.TaskList) do
    local bMatched = PredicateFunc(taskInfo)
    if bMatched then
      return taskInfo
    end
  end
  return nil
end

function TaskModuleData:FindTaskInTaskMap(PredicateFuncOrId)
  if type(PredicateFuncOrId) == "number" then
    return self.TaskMap[PredicateFuncOrId]
  end
  for taskId, taskInfo in pairs(self.TaskMap) do
    local bMatched = PredicateFuncOrId(taskInfo)
    if bMatched then
      return taskInfo
    end
  end
  return nil
end

function TaskModuleData:SetBaDgeList()
  local BagItemList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
  local BadgeData = {}
  if BagItemList and #BagItemList > 0 then
    for i, List in pairs(BagItemList) do
      if List.type == Enum.BagItemType.BI_BADGE_MAGIC then
        if List.badge_pos > self.MaxPos then
          self.MaxPos = List.badge_pos
        end
        BadgeData[List.badge_pos] = List
      end
    end
    for i = 1, self.MaxPos do
      if BadgeData[i] then
        table.insert(self.BaDgeList, {
          BagItem = BadgeData[i],
          IsHas = false
        })
      else
        table.insert(self.BaDgeList, {IsHas = false})
      end
    end
  end
end

function TaskModuleData:GetBaDgeList()
  return self.BaDgeList
end

function TaskModuleData:GetTaskRedPointList()
  local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.PRP_COMMON_TASK)
  return pointData
end

function TaskModuleData:SetTrackTask(_TrackTask)
  self.TrackTask = _TrackTask
end

function TaskModuleData:GetTrackTask()
  return self.TrackTask
end

function TaskModuleData:SetIsOpenTips(_IsOpenTips)
  self.IsOpenTips = _IsOpenTips
end

function TaskModuleData:GetIsOpenTips()
  return self.IsOpenTips
end

function TaskModuleData:UpdateAcceptTaskList(_guide_list)
  local CurGuideList = {}
  local Changed = false
  if not _guide_list or 0 == #_guide_list then
    for TaskID, Item in pairs(self.AcceptTaskList) do
      if Item and Item.Destroy then
        Item:Destroy()
      end
      self.AcceptTaskList[TaskID] = nil
      Changed = true
    end
    table.clear(self.AcceptTaskList)
    Log.Debug("TaskModuleData:UpdateAcceptTaskList ON_ACCEPT_TASK_REFRESH No GuideList")
    _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_ACCEPT_TASK_REFRESH, self.AcceptTaskList)
    return Changed
  end
  for _, Guide in ipairs(_guide_list) do
    if Guide.task_id and not self.AcceptTaskList[Guide.task_id] then
      local TaskConfig = _G.DataConfigManager:GetTaskConf(Guide.task_id)
      if TaskConfig then
        local AcceptTask = AcceptableTaskTrackItem(TaskConfig, Guide)
        self.AcceptTaskList[Guide.task_id] = AcceptTask
      end
    end
    CurGuideList[Guide.task_id] = true
  end
  for TaskID, Item in pairs(self.AcceptTaskList) do
    if not CurGuideList[TaskID] then
      if Item and Item.Destroy then
        Item:Destroy()
      end
      self.AcceptTaskList[TaskID] = nil
      Changed = true
    end
  end
  Log.Debug("TaskModuleData:UpdateAcceptTaskList ON_ACCEPT_TASK_REFRESH")
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_ACCEPT_TASK_REFRESH, self.AcceptTaskList)
  return Changed
end

function TaskModuleData:GetAcceptTaskList()
  return self.AcceptTaskList
end

function TaskModuleData:IsSkipTask(InTaskID)
  return self.SkipTaskMap[InTaskID]
end

function TaskModuleData:UpdateTaskTips()
  for k, v in pairs(self.TaskMap) do
    if v.ShouldRemove then
      Log.Debug("TaskModuleData:UpdateTaskTips Remove", k)
      v:ConsumeRemove()
    end
  end
end

return TaskModuleData

local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local JsonUtils = require("Common.JsonUtils")
local _ChapterBeginCacheFilename = "ChapterBeginCache"
local MagicManualModuleData = _G.NRCData:Extend("MagicManualModuleData")
local _RankPvpAgreementFileName = "NrcRankPvpAgreement"
MagicManualModuleData.TaskSortType = {
  Task_Adventure = 1,
  Task_Daily = 2,
  Task_Challenge = 3,
  PVP_Challenge = 4,
  PVE_Challenge = 5,
  Teach = 7
}
MagicManualModuleData.ManualTaskType = {NormalManual = 1, SeasonManual = 2}
MagicManualModuleData.DailyTaskType = {
  CluemTask = 1,
  DailyTask = 2,
  PermanentTask = 3
}
MagicManualModuleData.ChallengeTaskType = {
  XiShou = 1,
  Boss = 2,
  Legend = 3
}
MagicManualModuleData.TeachType = {Restraint = 4, Battle = 5}
MagicManualModuleData.BattlePlayTaskType = {
  BattleSilhouette = 1,
  Chieftain = 2,
  StarlightDuel = 3
}

function MagicManualModuleData:Ctor()
  NRCData.Ctor(self)
  self.IsInitPet = false
  self.SelectIndex = 0
  self.CurChapterId = 0
  self.CurChapterName = nil
  self.NextChapterId = {}
  self.NextChapterName = nil
  self.NextChapterTips = false
  self.MagicManualTaskTypeList = {}
  self.MagicManualTaskParagraphIdList = {}
  self.MagicManualTaskPanelInfo = {}
  self.InitPetConf = {}
  self.HasNextChatChapter = true
  self.HasNextRegion = false
  self.PreTaskInfo = nil
  self.TaskDic = {}
  self.DailyRemainTime = 0
  self.DailySpecialRewardItem = 0
  self.DailyTaskDic = {}
  self.CluemTaskDic = {}
  self.PermanentTaskDic = {}
  self.XiShouRemainTime = 0
  self.XiShouRemainTimeHour = 0
  self.XiShouRemainTimeMin = 0
  self.OldXiShouRemainTimeMin = 0
  self.XiShouFlowerList = {}
  self.BossList = {}
  self.LegendChallengeNum = 0
  self.LegendRemainTime = 0
  self.LegendList = {}
  self.InvalidTasks = {}
  self.InvalidPointKeyList = {}
  self.RankPvpTeleportAgreement = {}
  self.TeachingTabInfo = {}
  self.CompletedTaskMap = {}
  self.SeasonChapterData = {}
  self.SeasonProbAdd = {}
end

function MagicManualModuleData:SetInitPetConfInfo(Region_id, chapter_id, rewarded)
  self.IsTakeNewChapterReward = rewarded
  self.Finally_chapter_id = chapter_id
  local CurInitPetConf = {}
  for j, RegionId in pairs(Region_id) do
    local RegionConf = _G.DataConfigManager:GetRegionConf(RegionId)
    local ChapterConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ADVENTURE_CONF):GetAllDatas()
    local tempChapterConf = {}
    local ChapterId = RegionConf.region_start_chapter
    while ChapterId and 0 ~= ChapterId do
      for i, v in pairs(ChapterConf) do
        if ChapterId and v.id == ChapterId then
          local IsCurShowChapter = false
          if v.id == chapter_id then
            IsCurShowChapter = true
          end
          table.insert(tempChapterConf, {
            ChapterConf = v,
            IsCurShowChapter = IsCurShowChapter,
            IsLock = chapter_id < v.id
          })
          ChapterId = v.next_chapter
        end
      end
    end
    local IsCurShowRegion = false
    if j == #Region_id then
      self.HasNextRegion = false
      self.CurRegionId = RegionId
      IsCurShowRegion = true
      self.StartChapter = RegionConf.region_start_chapter
    end
    table.insert(CurInitPetConf, {
      IsCurShowRegion = IsCurShowRegion,
      RegionChapter = tempChapterConf,
      id = RegionId,
      name = RegionConf.name
    })
  end
  self.CurChapterId = chapter_id
  self.InitPetConf = CurInitPetConf
  return CurInitPetConf
end

function MagicManualModuleData:GetShowRegion()
  local RegionList = {}
  local CurSelect = 0
  if self.AllTaskRegionList then
    for i, v in pairs(self.AllTaskRegionList) do
      if v.RegionId == self.CurRegionId then
        CurSelect = i
      end
      local state = 0
      local ChapterList = v.ChapterList
      for _, Chapter in pairs(ChapterList) do
        state = 2
        local ChapterState = 0
        if #Chapter.taskList > 0 then
          ChapterState = 2
          for _, task in pairs(Chapter.taskList) do
            local taskConf = _G.DataConfigManager:GetTaskConf(task.id)
            if taskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE and task.state < ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
              ChapterState = 0
              break
            elseif taskConf.task_class ~= Enum.TaskClassType.TCT_ADVENTURE_CORE and task.state < ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
              ChapterState = 1
            end
          end
        end
        if 0 == ChapterState then
          state = 0
          break
        elseif 1 == ChapterState then
          state = 1
          break
        end
      end
      table.insert(RegionList, {
        ComType = CommonBtnEnum.ComboBoxType.MagicManual,
        RegionId = v.RegionId,
        name = v.name,
        state = state
      })
    end
  end
  return RegionList, CurSelect
end

function MagicManualModuleData:GetShowChapter()
  local ChapterList = {}
  local CurSelect = 0
  local CurState = 0
  for i, v in pairs(self.TaskRegionList) do
    local state = 0
    if #v.taskList > 0 then
      state = 2
      for j, task in pairs(v.taskList) do
        local taskConf = _G.DataConfigManager:GetTaskConf(task.id)
        if taskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE and task.state < ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          state = 0
          break
        elseif taskConf.task_class ~= Enum.TaskClassType.TCT_ADVENTURE_CORE and task.state < ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          state = 1
        end
      end
    else
      state = 3
    end
    if v.ChapterId == self.CurChapterId then
      CurSelect = i
      CurState = state
    end
    table.insert(ChapterList, {
      id = v.ChapterId,
      state = state
    })
  end
  return ChapterList, CurSelect, CurState
end

function MagicManualModuleData:UpdateMagicManualTaskTypeInfo()
end

function MagicManualModuleData:SetMagicManualTaskRegionId(RegionId)
  for i, v in pairs(self.InitPetConf) do
    if v.id ~= RegionId then
      v.IsCurShowRegion = false
    else
      local RegionConf = _G.DataConfigManager:GetRegionConf(RegionId)
      self.StartChapter = RegionConf.region_start_chapter
      v.IsCurShowRegion = true
      if i == #self.InitPetConf then
        self.HasNextRegion = false
      else
        self.HasNextRegion = true
      end
    end
  end
  self.CurRegionId = RegionId
  for i, v in pairs(self.AllTaskRegionList) do
    if v.RegionId == self.CurRegionId then
      self.TaskRegionList = v.ChapterList
      break
    end
  end
  local selectChapter = self.StartChapter
  for i, v in ipairs(self.TaskRegionList) do
    local hasRewardRedPoint = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, 165, {
      v.ChapterId
    })
    if hasRewardRedPoint then
      selectChapter = v.ChapterId
      break
    end
  end
  self:SetMagicManualTaskChapterId(selectChapter)
end

function MagicManualModuleData:SetMagicManualTaskChapterId(ChapterId)
  if self.CurChapterId == ChapterId then
    return
  end
  self.CurChapterId = ChapterId
  for i, v in pairs(self.InitPetConf) do
    if v.IsCurShowRegion then
      for j, Chapter in pairs(v.RegionChapter) do
        if Chapter.ChapterConf.id == ChapterId then
          Chapter.IsCurShowChapter = true
        else
          Chapter.IsCurShowChapter = false
        end
      end
    end
  end
  for i, v in pairs(self.TaskRegionList) do
    if v.ChapterId == self.CurChapterId then
      self:SetCurrentTaskParagraphInfo(v.taskList, v.PreTaskInfo, v.HideCoreTask, v.HideElectiveTask, v.PreTaskCoreNum, v.PreTaskElectiveNum)
      break
    end
  end
end

function MagicManualModuleData:GetMagicManualTaskParagraphIdList()
  for i, v in pairs(self.InitPetConf) do
    if v.IsCurShowRegion then
      for j, Chapter in pairs(v.RegionChapter) do
        if Chapter.IsCurShowChapter then
          return Chapter.ChapterConf.tasks
        end
      end
    end
  end
end

function MagicManualModuleData:GetMagicManualTaskRegionIdList()
  local taskList = {}
  for i, v in pairs(self.InitPetConf) do
    for j, Chapter in pairs(v.RegionChapter) do
      if not Chapter.IsLock then
        local tasks = Chapter.ChapterConf.tasks
        local PreTask = Chapter.ChapterConf.pre_task
        for k, task in pairs(tasks) do
          table.insert(taskList, task)
        end
        if PreTask and 0 ~= PreTask and type(PreTask) == "number" then
          table.insert(taskList, PreTask)
        end
      end
    end
  end
  return taskList
end

function MagicManualModuleData:SetAllTaskRegionInfo(task_info_list)
  local AllTaskRegionList = {}
  local needInvTaskList = {}
  local needReTaskList = {}
  for j, Region in pairs(self.InitPetConf) do
    local ChapterList = {}
    for i, v in pairs(Region.RegionChapter) do
      local PreTaskInfo
      local tasks = v.ChapterConf.tasks
      local PreTask = v.ChapterConf.pre_task
      local hide_tasks_core = {}
      local hide_tasks_elective = {}
      local pre_task_core_num = v.ChapterConf.pre_task_core_num
      local pre_task_elective_num = v.ChapterConf.pre_task_elective_num
      local DoneCoreTaskNum = 0
      local DoneElectiveTaskNum = 0
      if PreTask and 0 ~= PreTask and type(PreTask) == "number" then
        PreTaskInfo = {state = 1, id = PreTask}
        for _, taskInfo in pairs(task_info_list) do
          if PreTask == taskInfo.id then
            PreTaskInfo = taskInfo
            break
          end
        end
      end
      local taskList = {}
      if not v.IsLock then
        for _, task in pairs(tasks) do
          for _, taskInfo in pairs(task_info_list) do
            if task == taskInfo.id then
              local TaskConf = _G.DataConfigManager:GetTaskConf(task)
              if TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
                DoneCoreTaskNum = DoneCoreTaskNum + 1
              elseif TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_ELECTIVE and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
                DoneElectiveTaskNum = DoneElectiveTaskNum + 1
              end
              table.insert(taskList, taskInfo)
              break
            end
          end
        end
        if v.ChapterConf.hide_tasks_core and #v.ChapterConf.hide_tasks_core > 0 and pre_task_core_num and pre_task_core_num > DoneCoreTaskNum then
          hide_tasks_core = v.ChapterConf.hide_tasks_core
          for _, task in ipairs(hide_tasks_core) do
            needInvTaskList[task] = true
          end
        else
          for _, task in ipairs(v.ChapterConf.hide_tasks_core) do
            needReTaskList[task] = true
          end
        end
        if v.ChapterConf.hide_tasks_elective and #v.ChapterConf.hide_tasks_elective > 0 and pre_task_elective_num and pre_task_elective_num > DoneElectiveTaskNum then
          hide_tasks_elective = v.ChapterConf.hide_tasks_elective
          for _, task in ipairs(hide_tasks_elective) do
            needInvTaskList[task] = true
          end
        else
          for _, task in ipairs(v.ChapterConf.hide_tasks_elective) do
            needReTaskList[task] = true
          end
        end
        if v.IsCurShowChapter then
          self:SetCurrentTaskParagraphInfo(taskList, PreTaskInfo, hide_tasks_core, hide_tasks_elective, pre_task_core_num, pre_task_elective_num)
        end
      end
      table.insert(ChapterList, {
        ChapterId = v.ChapterConf.id,
        taskList = taskList,
        PreTaskInfo = PreTaskInfo,
        HideCoreTask = hide_tasks_core,
        PreTaskCoreNum = pre_task_core_num,
        HideElectiveTask = hide_tasks_elective,
        PreTaskElectiveNum = pre_task_elective_num
      })
    end
    table.insert(AllTaskRegionList, {
      RegionId = Region.id,
      ChapterList = ChapterList,
      name = Region.name
    })
    if Region.IsCurShowRegion then
      self.TaskRegionList = ChapterList
    end
  end
  for task, v in pairs(needReTaskList) do
    for _, taskInfo in pairs(task_info_list) do
      if task == taskInfo.id and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        needReTaskList[task] = false
      end
    end
  end
  self.AllTaskRegionList = AllTaskRegionList
  self:CheckRecoverRedPoint()
  for i, v in pairs(needReTaskList) do
    self:TryRecoverRedPoint(i)
    if v then
      Log.Debug("TryRecoverPointData", 161, i)
      _G.NRCModuleManager:DoCmd(RedPointModuleCmd.RecoverPointData, 161, {i})
    end
  end
  for i, v in pairs(needInvTaskList) do
    self:TryInvalidRedPoint(i)
    Log.Debug("TryInvalidRedPoint", 161, i)
    _G.NRCModuleManager:DoCmd(RedPointModuleCmd.InvalidPointData, 161, {i})
  end
end

function MagicManualModuleData:GetMagicManualTaskTypeList()
  return self.MagicManualTaskTypeList
end

function MagicManualModuleData:SetSelectIndex(_Index)
  self.SelectIndex = _Index
end

function MagicManualModuleData:GetSelectIndex()
  return self.SelectIndex
end

function MagicManualModuleData:GetMagicManualTaskPanelInfo()
  return self.MagicManualTaskPanelInfo
end

function MagicManualModuleData:UpDateCurrentTaskParagraphInfo(task_info_list, IsRefreshHideTask)
  for i, v in pairs(self.TaskRegionList) do
    if v.ChapterId == self.CurChapterId then
      v.taskList = task_info_list
      local hide_tasks_core = v.HideCoreTask
      local hide_tasks_elective = v.HideElectiveTask
      local pre_task_core_num = v.PreTaskCoreNum
      local pre_task_elective_num = v.PreTaskElectiveNum
      local DoneCoreTaskNum = 0
      local DoneElectiveTaskNum = 0
      for _, taskInfo in pairs(task_info_list) do
        local TaskConf = _G.DataConfigManager:GetTaskConf(taskInfo.id)
        if TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          DoneCoreTaskNum = DoneCoreTaskNum + 1
        elseif TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_ELECTIVE and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          DoneElectiveTaskNum = DoneElectiveTaskNum + 1
        end
      end
      if v.HideCoreTask and #v.HideCoreTask > 0 then
        if pre_task_core_num and pre_task_core_num > DoneCoreTaskNum then
          if IsRefreshHideTask and self.TaskRegionList[i].HideCoreTask then
            for _, taskId in ipairs(self.TaskRegionList[i].HideCoreTask) do
              self:TryInvalidRedPoint(taskId)
            end
          end
        else
          hide_tasks_core = {}
          for _, taskId in ipairs(self.TaskRegionList[i].HideCoreTask) do
            self:TryRecoverRedPoint(taskId)
          end
        end
      end
      if v.HideElectiveTask and #v.HideElectiveTask > 0 then
        if pre_task_elective_num and pre_task_elective_num > DoneElectiveTaskNum then
          if IsRefreshHideTask and self.TaskRegionList[i].HideElectiveTask then
            for _, taskId in ipairs(self.TaskRegionList[i].HideElectiveTask) do
              self:TryInvalidRedPoint(taskId)
            end
          end
        else
          hide_tasks_elective = {}
          for _, taskId in ipairs(self.TaskRegionList[i].HideElectiveTask) do
            self:TryRecoverRedPoint(taskId)
          end
        end
      end
      self.TaskRegionList[i].HideElectiveTask = hide_tasks_elective
      self.TaskRegionList[i].HideCoreTask = hide_tasks_core
      for j, k in pairs(self.AllTaskRegionList) do
        if k.RegionId == self.CurRegionId then
          local TaskRegionList = k.ChapterList
          TaskRegionList[i].HideElectiveTask = hide_tasks_elective
          TaskRegionList[i].HideCoreTask = hide_tasks_core
          break
        end
      end
      self:SetCurrentTaskParagraphInfo(v.taskList, v.PreTaskInfo, hide_tasks_core, hide_tasks_elective, pre_task_core_num, pre_task_elective_num)
      break
    end
  end
end

function MagicManualModuleData:SetCurrentTaskParagraphInfo(task_info_list, PreTaskInfo, _HideCoreTask, _HideElectiveTask, PreTaskCoreNum, PreTaskElectiveNum)
  local LeftPanelInfo = {}
  local RightPanelInfo = {}
  local HideCoreTask = {}
  local HideElectiveTask = {}
  if _HideCoreTask then
    HideCoreTask = _HideCoreTask
  end
  if _HideElectiveTask then
    HideElectiveTask = _HideElectiveTask
  end
  self.PreTaskInfo = PreTaskInfo
  local Paragraph_Id = self.CurChapterId
  LeftPanelInfo = self:SetLeftInfo(Paragraph_Id)
  local TaskConf
  local TaskList = task_info_list
  local DoneCoreTaskNum = 0
  local DoneElectiveTaskNum = 0
  for _, taskInfo in pairs(task_info_list) do
    TaskConf = _G.DataConfigManager:GetTaskConf(taskInfo.id)
    if TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      DoneCoreTaskNum = DoneCoreTaskNum + 1
    elseif TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_ELECTIVE and taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      DoneElectiveTaskNum = DoneElectiveTaskNum + 1
    end
  end
  for i, Task in ipairs(TaskList) do
    TaskConf = _G.DataConfigManager:GetTaskConf(Task.id)
    local IsHide = false
    local NeedUnlockNum = 0
    local DoneTaskNum = 0
    if #HideCoreTask > 0 then
      for _, HideTaskId in ipairs(HideCoreTask) do
        if HideTaskId == Task.id then
          IsHide = true
          NeedUnlockNum = PreTaskCoreNum
          DoneTaskNum = DoneCoreTaskNum
        end
      end
    end
    if #HideElectiveTask > 0 and not IsHide then
      for _, HideTaskId in ipairs(HideElectiveTask) do
        if HideTaskId == Task.id then
          IsHide = true
          NeedUnlockNum = PreTaskElectiveNum
          DoneTaskNum = DoneElectiveTaskNum
        end
      end
    end
    table.insert(RightPanelInfo, {
      PlayerTaskInfo = Task,
      TaskConf = TaskConf,
      IsHide = IsHide,
      NeedUnlockNum = NeedUnlockNum,
      DoneTaskNum = DoneTaskNum
    })
  end
  self.MagicManualTaskPanelInfo.LeftPanelInfo = LeftPanelInfo
  if self.MagicManualTaskPanelInfo.LeftPanelInfo then
    if not (not self.MagicManualTaskPanelInfo.LeftPanelInfo.next_chapter or 0 == self.MagicManualTaskPanelInfo.LeftPanelInfo.next_chapter or self:GetChapterIsLock(self.MagicManualTaskPanelInfo.LeftPanelInfo.next_chapter)) or self.HasNextRegion then
      self.HasNextChatChapter = true
    else
      self.HasNextChatChapter = false
    end
  else
    self.HasNextChatChapter = false
  end
  self.MagicManualTaskPanelInfo.RightPanelInfo = RightPanelInfo
  if not PreTaskInfo or PreTaskInfo.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
  else
    local cacheChapterBeginData = {}
    local NextParagraphConf = _G.DataConfigManager:GetAdventureConf(Paragraph_Id)
    cacheChapterBeginData.chapterNumber = self:TranslateCurChapterName(NextParagraphConf.chapter_num)
    cacheChapterBeginData.chapterName = NextParagraphConf.chapter_name
    cacheChapterBeginData.chapterRibbon = NextParagraphConf.chapter_new_anim_comp
    cacheChapterBeginData.id = Paragraph_Id
    cacheChapterBeginData.panelName = "ChapterBegin"
    self.module.cacheChapterBeginData = cacheChapterBeginData
    local CacheFile = JsonUtils.LoadSaved(_ChapterBeginCacheFilename, {}) or {}
    if self.module.cacheChapterBeginData then
      CacheFile.cache = self.module.cacheChapterBeginData
      JsonUtils.DumpSaved(_ChapterBeginCacheFilename, CacheFile)
    end
  end
end

function MagicManualModuleData:GetChapterIsLock(chapterId)
  for i, v in pairs(self.InitPetConf) do
    if v.id == self.CurRegionId then
      local chapterList = v.RegionChapter
      for j, Chapter in pairs(chapterList) do
        if Chapter.ChapterConf.id == chapterId then
          return Chapter.IsLock
        end
      end
    end
  end
end

function MagicManualModuleData:CheckRecoverRedPoint()
  if self.InvalidTasks then
    for j, InvalidItem in pairs(self.InvalidTasks) do
      local InvalidPointData = {}
      local AllTaskRegionReward = false
      local AllHideTaskRegionRewardNum = 0
      local AllTaskRegionRewardNum = 0
      for i, v in pairs(self.AllTaskRegionList) do
        local InvalidTaskConf = _G.DataConfigManager:GetTaskConf(j)
        local HideTaskClassType = InvalidTaskConf.task_class
        local ChapterList = v.ChapterList
        local WaitRewardChapterNum = 0
        local HideTaskRegionReward = false
        local HideTaskRegionRewardNum = 0
        for _, Chapter in pairs(ChapterList) do
          if #Chapter.taskList > 0 then
            local WaitRewardTaskNum = 0
            local HideTaskWaitReward = false
            local CoreTaskNum = 0
            local CoreTaskDoneNum = 0
            local HideTaskList = HideTaskClassType == Enum.TaskClassType.TCT_ADVENTURE_CORE and Chapter.HideCoreTask or Chapter.HideElectiveTask
            for _, task in pairs(Chapter.taskList) do
              if task.id == j and task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
                HideTaskWaitReward = true
              end
              if task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
                local IsInHide = false
                if HideTaskList and #HideTaskList > 0 then
                  for _, hideTask in ipairs(HideTaskList) do
                    if hideTask == task.id then
                      IsInHide = true
                      break
                    end
                  end
                end
                if not IsInHide then
                  WaitRewardTaskNum = WaitRewardTaskNum + 1
                end
              end
              local TaskConf = _G.DataConfigManager:GetTaskConf(task.id)
              if TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE then
                CoreTaskNum = CoreTaskNum + 1
                if task.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
                  CoreTaskDoneNum = CoreTaskDoneNum + 1
                end
              end
            end
            if HideTaskWaitReward and WaitRewardTaskNum < 1 and (CoreTaskDoneNum ~= CoreTaskNum or self.IsTakeNewChapterReward or Chapter.ChapterId ~= self.Finally_chapter_id) then
              local key = 165
              local extraKey = Chapter.ChapterId
              local data = {key = key, extraKey = extraKey}
              table.insert(InvalidPointData, data)
              HideTaskRegionReward = true
              HideTaskRegionRewardNum = HideTaskRegionRewardNum + 1
            elseif WaitRewardTaskNum > 0 then
              local key = 165
              local extraKey = Chapter.ChapterId
              if self.InvalidPointKeyList[key] and self.InvalidPointKeyList[key][extraKey] then
                Log.Debug("TryRecoverPointData", key, extraKey)
                _G.NRCModuleManager:DoCmd(RedPointModuleCmd.RecoverPointData, key, {extraKey})
                self.InvalidPointKeyList[key][extraKey] = nil
              end
              WaitRewardChapterNum = WaitRewardChapterNum + 1
            end
          end
        end
        if HideTaskRegionReward and HideTaskRegionRewardNum > WaitRewardChapterNum then
          local key = 166
          local extraKey = v.RegionId
          local data = {key = key, extraKey = extraKey}
          table.insert(InvalidPointData, data)
          AllTaskRegionReward = true
          AllHideTaskRegionRewardNum = AllHideTaskRegionRewardNum + 1
        elseif WaitRewardChapterNum > 0 then
          local key = 166
          local extraKey = v.RegionId
          if self.InvalidPointKeyList[key] and self.InvalidPointKeyList[key][extraKey] then
            Log.Debug("TryRecoverPointData", key, extraKey)
            _G.NRCModuleManager:DoCmd(RedPointModuleCmd.RecoverPointData, key, {extraKey})
            self.InvalidPointKeyList[key][extraKey] = nil
          end
          AllTaskRegionRewardNum = AllTaskRegionRewardNum + 1
        end
      end
      if AllTaskRegionReward and AllHideTaskRegionRewardNum > AllTaskRegionRewardNum then
        local key = 167
        local data = {key = key}
        table.insert(InvalidPointData, data)
      else
        local key = 167
        if self.InvalidPointKeyList[key] then
          Log.Debug("TryRecoverPointData", key)
          _G.NRCModuleManager:DoCmd(RedPointModuleCmd.RecoverPointData, key)
          self.InvalidPointKeyList[key] = nil
        end
      end
      self.InvalidTasks[j] = InvalidPointData
    end
  end
end

function MagicManualModuleData:TryInvalidRedPoint(TaskId)
  local InvalidPointData = {}
  local AllTaskRegionReward = false
  local AllTaskRegionRewardNum = 0
  local AllHideTaskRegionRewardNum = 0
  for i, v in pairs(self.AllTaskRegionList) do
    local InvalidTaskConf = _G.DataConfigManager:GetTaskConf(TaskId)
    local HideTaskClassType = InvalidTaskConf.task_class
    local ChapterList = v.ChapterList
    local WaitRewardChapterNum = 0
    local HideTaskRegionReward = false
    local HideTaskRegionRewardNum = 0
    for _, Chapter in pairs(ChapterList) do
      if #Chapter.taskList > 0 then
        local WaitRewardTaskNum = 0
        local HideTaskWaitReward = false
        local CoreTaskNum = 0
        local CoreTaskDoneNum = 0
        local HideTaskList = HideTaskClassType == Enum.TaskClassType.TCT_ADVENTURE_CORE and Chapter.HideCoreTask or Chapter.HideElectiveTask
        for _, task in pairs(Chapter.taskList) do
          if task.id == TaskId and task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
            HideTaskWaitReward = true
          end
          if task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
            local IsInHide = false
            if HideTaskList and #HideTaskList > 0 then
              for _, hideTask in ipairs(HideTaskList) do
                if hideTask == task.id then
                  IsInHide = true
                  break
                end
              end
            end
            if not IsInHide then
              WaitRewardTaskNum = WaitRewardTaskNum + 1
            end
          end
          local TaskConf = _G.DataConfigManager:GetTaskConf(task.id)
          if TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE then
            CoreTaskNum = CoreTaskNum + 1
            if task.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
              CoreTaskDoneNum = CoreTaskDoneNum + 1
            end
          end
        end
        if HideTaskWaitReward and WaitRewardTaskNum < 1 and (CoreTaskDoneNum ~= CoreTaskNum or self.IsTakeNewChapterReward or Chapter.ChapterId ~= self.Finally_chapter_id) then
          local key = 165
          local extraKey = Chapter.ChapterId
          local data = {key = key, extraKey = extraKey}
          local InvalidPointExtraKeyList = self.InvalidPointKeyList[key] or {}
          InvalidPointExtraKeyList[extraKey] = data
          self.InvalidPointKeyList[key] = InvalidPointExtraKeyList
          table.insert(InvalidPointData, data)
          Log.Debug("TryInvalidRedPoint", key, extraKey)
          _G.NRCModuleManager:DoCmd(RedPointModuleCmd.InvalidPointData, key, {extraKey})
          HideTaskRegionReward = true
          HideTaskRegionRewardNum = HideTaskRegionRewardNum + 1
        elseif WaitRewardTaskNum > 0 then
          WaitRewardChapterNum = WaitRewardChapterNum + 1
        end
      end
    end
    if HideTaskRegionReward and HideTaskRegionRewardNum > WaitRewardChapterNum then
      local key = 166
      local extraKey = v.RegionId
      local data = {key = key, extraKey = extraKey}
      local InvalidPointExtraKeyList = self.InvalidPointKeyList[key] or {}
      InvalidPointExtraKeyList[extraKey] = data
      self.InvalidPointKeyList[key] = InvalidPointExtraKeyList
      table.insert(InvalidPointData, data)
      Log.Debug("TryInvalidRedPoint", key, extraKey)
      _G.NRCModuleManager:DoCmd(RedPointModuleCmd.InvalidPointData, key, {extraKey})
      AllTaskRegionReward = true
      AllHideTaskRegionRewardNum = AllHideTaskRegionRewardNum + 1
    elseif WaitRewardChapterNum > 0 then
      AllTaskRegionRewardNum = AllTaskRegionRewardNum + 1
    end
  end
  if AllTaskRegionReward and AllHideTaskRegionRewardNum > AllTaskRegionRewardNum then
    local key = 167
    local data = {key = key}
    local InvalidPointExtraKeyList = self.InvalidPointKeyList[key] or {}
    self.InvalidPointKeyList[key] = InvalidPointExtraKeyList
    table.insert(InvalidPointData, data)
    Log.Debug("TryInvalidRedPoint", key)
    _G.NRCModuleManager:DoCmd(RedPointModuleCmd.InvalidPointData, key)
  end
  self.InvalidTasks[TaskId] = InvalidPointData
end

function MagicManualModuleData:TryRecoverRedPoint(TaskId)
  if self.InvalidTasks[TaskId] then
    local InvalidPointData = self.InvalidTasks[TaskId]
    for i, v in ipairs(InvalidPointData) do
      if self.InvalidPointKeyList[v.key] and self.InvalidPointKeyList[v.key][v.extraKey] then
        Log.Debug("TryRecoverPointData", v.key, v.extraKey)
        _G.NRCModuleManager:DoCmd(RedPointModuleCmd.RecoverPointData, v.key, v.extraKey)
        self.InvalidPointKeyList[v.key][v.extraKey] = nil
      elseif self.InvalidPointKeyList[v.key] then
        self.InvalidPointKeyList[v.key] = nil
        Log.Debug("TryRecoverPointData", v.key)
        _G.NRCModuleManager:DoCmd(RedPointModuleCmd.RecoverPointData, v.key)
      end
    end
    self.InvalidTasks[TaskId] = nil
  end
end

function MagicManualModuleData:SetLeftInfo(_paragraph_id)
  local paragraph_id = _paragraph_id
  local ParagraphConf = _G.DataConfigManager:GetAdventureConf(paragraph_id)
  return ParagraphConf
end

function MagicManualModuleData:SetMagicManualTaskDic(task)
  local taskConf = _G.DataConfigManager:GetTaskConf(task.id)
  if self.TaskDic[taskConf.paragraph_id] == nil then
    self.TaskDic[taskConf.paragraph_id] = {}
  end
  if taskConf.task_class == _G.Enum.TaskClassType.TCT_ADVENTURE then
    self.TaskDic[taskConf.paragraph_id][task.id] = task
  end
end

function MagicManualModuleData:GetChapterTasks(paragraph_id)
  if self.TaskDic[paragraph_id] == nil then
    return {}
  end
end

function MagicManualModuleData:SetCurChapterName(_Text)
  self.CurChapterName = _Text
  return self.CurChapterName
end

function MagicManualModuleData:SetNextChapterName(_Text)
  if _Text then
    self.NextChapterName = _Text
  else
    return
  end
  return self.NextChapterName
end

function MagicManualModuleData:GetNextChapterName()
  return self.NextChapterName
end

function MagicManualModuleData:GetCurChapterName()
  return self.CurChapterName
end

function MagicManualModuleData:SetNextChapterInfo()
  local NextChapterInfo = self.MagicManualTaskPanelInfo.LeftPanelInfo
  local NextChapterId
  if NextChapterInfo.next_chapter and 0 ~= NextChapterInfo.next_chapter then
    NextChapterId = NextChapterInfo.next_chapter
    local NextParagraphConf = _G.DataConfigManager:GetAdventureConf(NextChapterId)
    self.NextChapterId.ChapterIdName = self:TranslateCurChapterName(NextParagraphConf.chapter_num)
    self.NextChapterId.ChapterName = NextParagraphConf.chapter_name
    self.NextChapterId.ChapterRibbon = NextParagraphConf.chapter_new_anim_comp
    self.NextChapterId.id = NextChapterId
  elseif self.CurRegionId and _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id then
    local Region_id_list = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id
    local NextRegionId = Region_id_list[#Region_id_list]
    Log.Debug("MagicManualModuleData:SetNextChapterInfo", NextRegionId)
    if NextRegionId then
      if NextRegionId ~= self.CurRegionId then
        local NextRegionConf = _G.DataConfigManager:GetRegionConf(NextRegionId)
        NextChapterId = NextRegionConf.region_start_chapter
        local NextParagraphConf = _G.DataConfigManager:GetAdventureConf(NextChapterId)
        self.NextChapterId.ChapterIdName = self:TranslateCurChapterName(NextParagraphConf.chapter_num)
        self.NextChapterId.ChapterName = NextParagraphConf.chapter_name
        self.NextChapterId.ChapterRibbon = NextParagraphConf.chapter_new_anim_comp
        self.NextChapterId.id = NextChapterId
      else
        return nil
      end
    end
  else
    return nil
  end
  return self.NextChapterId
end

function MagicManualModuleData:TranslateCurChapterName(chapterNum)
  local ChapterId = chapterNum or 0
  if ChapterId then
    if 1 == ChapterId then
      ChapterId = LuaText.upper_number_one
    elseif 2 == ChapterId then
      ChapterId = LuaText.upper_number_two
    elseif 3 == ChapterId then
      ChapterId = LuaText.upper_number_three
    elseif 4 == ChapterId then
      ChapterId = LuaText.upper_number_four
    elseif 5 == ChapterId then
      ChapterId = LuaText.upper_number_five
    elseif 6 == ChapterId then
      ChapterId = LuaText.upper_number_six
    elseif 7 == ChapterId then
      ChapterId = LuaText.upper_number_seven
    elseif 8 == ChapterId then
      ChapterId = LuaText.upper_number_eight
    elseif 9 == ChapterId then
      ChapterId = LuaText.upper_number_nine
    end
  else
    Log.Error("\230\178\161\230\156\137\229\175\185\229\186\148\231\171\160\232\138\130Id\239\188\140\232\175\183\230\163\128\230\159\165")
  end
  local CurChapterText = string.format(LuaText.magic_manual_chapter, ChapterId)
  return CurChapterText
end

function MagicManualModuleData:SetTasksDic(dic, taskList, dicType)
  for i, task in pairs(taskList) do
    local taskConf = _G.DataConfigManager:GetTaskConf(task.id)
    if dic[task.id] == nil then
      dic[task.id] = {}
    end
    if taskConf.task_class == _G.Enum.TaskClassType.TCT_DAILY then
      local isChange = false
      if dic[task.id] and dic[task.id].state ~= task.state then
        isChange = true
      end
      dic[task.id] = task
      if isChange then
        if dicType == self.DailyTaskType.DailyTask then
          _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.ChangeDailyTaskInfo, task)
        elseif dicType == self.DailyTaskType.CluemTask then
          _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.ChangeCluemTaskInfo, task)
        elseif dicType == self.DailyTaskType.PermanentTask then
          _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.ChangePermanentTaskInfo, task)
        end
      end
    end
  end
  return dic
end

function MagicManualModuleData:SetTaskDic(dic, taskInfo)
  local taskConf = _G.DataConfigManager:GetTaskConf(taskInfo.id)
  if dic[taskInfo.id] == nil then
    dic[taskInfo.id] = {}
  end
  if taskConf.task_class == _G.Enum.TaskClassType.TCT_DAILY then
    dic[taskInfo.id] = taskInfo
  end
  return dic
end

function MagicManualModuleData:GetTaskList(taskDic)
  local taskList = {}
  for key, task in pairs(taskDic) do
    table.insert(taskList, task)
  end
  return taskList
end

function MagicManualModuleData:SortTaskList(taskList)
  table.sort(taskList, function(a, b)
    return self:GetDailySortIndex(a.id) < self:GetDailySortIndex(b.id)
  end)
  return taskList
end

function MagicManualModuleData:GetDailySortIndex(taskId)
  local taskModuleConf = _G.DataConfigManager:GetTaskModuleConf(taskId)
  if nil == taskModuleConf then
    return 999
  end
  local module_id = taskModuleConf.moduel_id
  local numList = _G.DataConfigManager:GetDailyGlobalConfig(5).numList
  local moduleIds = {}
  for i = 1, #numList do
    local num1, num2 = math.modf(i / 2)
    if 0 == num2 and 1 ~= i then
    else
      table.insert(moduleIds, numList[i])
    end
  end
  for i, moduleId in pairs(moduleIds) do
    if moduleId == module_id then
      return i
    end
  end
  return 999
end

function MagicManualModuleData:SetDailyTaskDic(taskList)
  self.DailyTaskDic = {}
  self:SetTasksDic(self.DailyTaskDic, taskList, self.DailyTaskType.DailyTask)
end

function MagicManualModuleData:SetCluemTaskDic(taskList)
  self.CluemTaskDic = {}
  self:SetTasksDic(self.CluemTaskDic, taskList, self.DailyTaskType.CluemTask)
end

function MagicManualModuleData:SetPermanentTaskDic(taskList)
  self.PermanentTaskDic = {}
  self:SetTasksDic(self.PermanentTaskDic, taskList, self.DailyTaskType.PermanentTask)
end

function MagicManualModuleData:GetDailTaskList()
  local list = self:GetTaskList(self.DailyTaskDic)
  local sortList = self:SortTaskList(list)
  return sortList
end

function MagicManualModuleData:GetCluemTaskList()
  return self:GetTaskList(self.CluemTaskDic)
end

function MagicManualModuleData:GetPermanentTaskList()
  return self:GetTaskList(self.PermanentTaskDic)
end

function MagicManualModuleData:LoadRankPvpTeleportAgreement()
  self.RankPvpTeleportAgreement = JsonUtils.LoadSaved(_RankPvpAgreementFileName, {}) or {}
end

function MagicManualModuleData:SaveRankPvpTeleportAgreement()
  return JsonUtils.DumpSaved(_RankPvpAgreementFileName, self.RankPvpTeleportAgreement)
end

function MagicManualModuleData:OnUpdateSeasonManualData(ZoneData)
  if self.SeasonChapterData.currSeasonID and self.SeasonChapterData.currSeasonID ~= ZoneData.season_id then
    self.SeasonChapterData = {}
  end
  self.SeasonChapterData.currSeasonID = ZoneData.season_id
  self.SeasonChapterData.currSeasonChapterID = ZoneData.chapter_id
  local seasonConf = _G.DataConfigManager:GetSeasonConf(ZoneData.season_id)
  local seasonManualConf = _G.DataConfigManager:GetSeasonAdventureConf(seasonConf.season_adventure)
  local seasonUICfg = _G.DataConfigManager:GetSeasonAdventureUi(seasonManualConf.ui_id)
  self.SeasonChapterData.seasonManualConf = seasonManualConf
  self.SeasonChapterData.seasonUICfg = seasonUICfg
  self.SeasonChapterData.badgeInfo = {}
  if ZoneData.badge_info then
    local badgeConf = self:GetSeasonBadgeConfByLevel(ZoneData.badge_info.badge_lvl)
    self.SeasonChapterData.badgeInfo.badgeInfo = ZoneData.badge_info
    self.SeasonChapterData.badgeInfo.badgeConfData = badgeConf
  end
  self.SeasonChapterData.allChapterData = {}
  local chapterList = self:GetSeasonChapterConfList()
  for i, v in pairs(chapterList) do
    local chapterState, tasklist
    local state = 3
    for _k, _v in pairs(ZoneData.chapter_base_infos) do
      if v.id == _v.chapter_id then
        chapterState = _v
        break
      end
    end
    if v.id == ZoneData.chapter_id then
      tasklist = ZoneData.chapter_task_list
    end
    if chapterState then
      if chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.REWARED then
        if chapterState.normal_progress + chapterState.challenge_progress >= #v.tasks then
          state = 2
        else
          state = 1
        end
      elseif chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.UNLOCK then
        state = 0
      end
    end
    table.insert(self.SeasonChapterData.allChapterData, {
      chapterConfData = v,
      chapterState = chapterState,
      taskList = tasklist,
      state = state
    })
  end
  table.sort(self.SeasonChapterData.allChapterData, function(a, b)
    return a.chapterConfData.chapter_num < b.chapterConfData.chapter_num
  end)
end

function MagicManualModuleData:GetSeasonChapterConfList()
  local seasonChapterTab = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SEASON_ADVENTURE_CHAPTER):GetAllDatas()
  local seasonChapterList = {}
  for i, v in pairs(seasonChapterTab) do
    if self.SeasonChapterData.seasonManualConf and v.group_id == self.SeasonChapterData.seasonManualConf.chapter_group_id then
      table.insert(seasonChapterList, v)
    end
  end
  return seasonChapterList
end

function MagicManualModuleData:GetSeasonBadgeConfByLevel(level)
  local badgeConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SEASON_ADVENTURE_BADGE_LEVEL):GetAllDatas()
  local groudID = self.SeasonChapterData.seasonManualConf.badge_group_id
  for i, v in pairs(badgeConf) do
    if groudID and v.group_id == groudID and v.id == level then
      return v
    end
  end
  return nil
end

function MagicManualModuleData:GetCurrentChapterData(chapterID)
  if not self.SeasonChapterData.allChapterData then
    return nil
  end
  local findId = chapterID or self.SeasonChapterData.currSeasonChapterID
  for i, v in pairs(self.SeasonChapterData.allChapterData) do
    if v.chapterConfData.id == findId then
      return v
    end
  end
  return nil
end

function MagicManualModuleData:GetNextSeasonManaulChapterData()
  local currChapter = self:GetCurrentChapterData()
  if currChapter and currChapter.chapterConfData and currChapter.chapterConfData.next_chapter and currChapter.chapterConfData.next_chapter > 0 then
    return self:GetCurrentChapterData(currChapter.chapterConfData.next_chapter)
  end
  return nil
end

function MagicManualModuleData:GetSeasonChapterData()
  return self.SeasonChapterData
end

function MagicManualModuleData:GetCurrSeasonShowChapterID()
  return self.SeasonChapterData and self.SeasonChapterData.currSeasonChapterID or 0
end

function MagicManualModuleData:GetSeasonChapterList()
  if self.SeasonChapterData.allChapterData then
    return self.SeasonChapterData.allChapterData
  end
  return nil
end

function MagicManualModuleData:GetSeasonBadgeInfo()
  return self.SeasonChapterData.badgeInfo
end

function MagicManualModuleData:GetAllSeasonBadgeConf()
  local badgeConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SEASON_ADVENTURE_BADGE_LEVEL):GetAllDatas()
  local groudID = self.SeasonChapterData.seasonManualConf.badge_group_id
  local badgeList = {}
  for i, v in pairs(badgeConf) do
    if groudID and v.group_id == groudID and v.level_num > 1 then
      table.insert(badgeList, v)
    end
  end
  table.sort(badgeList, function(a, b)
    return a.level_num < b.level_num
  end)
  return badgeList
end

function MagicManualModuleData:OnUpdataTaskStateInfo(tasklist)
  if not tasklist or 0 == #tasklist then
    return
  end
  local currChapterData = self:GetCurrentChapterData()
  if currChapterData and currChapterData.taskList then
    local badgeInfo = self:GetSeasonBadgeInfo()
    for i, v in pairs(tasklist) do
      for j, k in pairs(currChapterData.taskList) do
        if v.id == k.id then
          table.remove(currChapterData.taskList, j)
          table.insert(currChapterData.taskList, v)
          break
        end
      end
      local taskConf = _G.DataConfigManager:GetTaskConf(v.id)
      if taskConf and v.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE and (taskConf.task_class == Enum.TaskClassType.TCT_SADV_NORMAL or taskConf.task_class == Enum.TaskClassType.TCT_SADV_CHALLENGE) then
        currChapterData.chapterState.normal_progress = taskConf.task_class == Enum.TaskClassType.TCT_SADV_NORMAL and currChapterData.chapterState.normal_progress + 1 or currChapterData.chapterState.normal_progress
        currChapterData.chapterState.challenge_progress = taskConf.task_class == Enum.TaskClassType.TCT_SADV_CHALLENGE and currChapterData.chapterState.challenge_progress + 1 or currChapterData.chapterState.challenge_progress
        if badgeInfo and badgeInfo.badgeInfo then
          badgeInfo.badgeInfo.cur_progress = badgeInfo.badgeInfo.cur_progress + 1
        end
      end
      if currChapterData.chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.REWARED then
        if currChapterData.chapterState.normal_progress + currChapterData.chapterState.challenge_progress >= #currChapterData.chapterConfData.tasks then
          currChapterData.state = 2
        else
          currChapterData.state = 1
        end
      elseif currChapterData.chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.UNLOCK then
        currChapterData.state = 0
      end
    end
  end
end

function MagicManualModuleData:OnUpdataChapterRewardState(chapterID, rewardState)
  local currChapterData = self:GetCurrentChapterData(chapterID)
  if currChapterData then
    currChapterData.chapterState.status = rewardState
    if currChapterData.chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.REWARED then
      if currChapterData.chapterState.normal_progress + currChapterData.chapterState.challenge_progress >= #currChapterData.chapterConfData.tasks then
        currChapterData.state = 2
      else
        currChapterData.state = 1
      end
    elseif currChapterData.chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.UNLOCK then
      currChapterData.state = 0
    end
  end
end

function MagicManualModuleData:OnUpdataBadgeInfo(badgeInfo)
  local badgeConf = self:GetSeasonBadgeConfByLevel(badgeInfo.badge_lvl)
  self.SeasonChapterData.badgeInfo = {badgeInfo = badgeInfo, badgeConfData = badgeConf}
end

function MagicManualModuleData:OnUpdateSeasonManualProbAddition(additionInfo)
  self.SeasonProbAdd = additionInfo
end

function MagicManualModuleData:GetSeasonProbAdd()
  return self.SeasonProbAdd
end

return MagicManualModuleData

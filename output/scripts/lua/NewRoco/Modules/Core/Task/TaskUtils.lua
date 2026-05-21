local TaskUtils = {}

function TaskUtils.pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do
    table.insert(a, n)
  end
  table.sort(a, f)
  local i = 0
  
  local function iter()
    i = i + 1
    if nil == a[i] then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  
  return iter
end

function TaskUtils.MakeSlateColor(r, g, b, a)
  local color = UE4.FSlateColor()
  local fColor = UE4.FColor(r, g, b, a)
  color.SpecifiedColor = fColor:ToLinearColor()
  return color
end

function TaskUtils.SetupTaskStateColor(task, text)
  if task and task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    text:SetColorAndOpacity(TaskUtils.FinishColor)
  else
    text:SetColorAndOpacity(TaskUtils.OtherColor)
  end
end

function TaskUtils.SetupTaskStateIcon(task, icon)
  if not icon then
    return
  end
  if not task then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  local Path = TaskUtils.GetTaskStateIcon(task)
  if string.IsNilOrEmpty(Path) then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    icon:SetVisibility(UE4.ESlateVisibility.Visible)
    icon:SetPath(Path)
  end
end

function TaskUtils.GetTaskStateIcon(task)
  local Conf = task.Config
  if task.TrackParentTask and task.TrackParentTask.isTrack then
    Conf = task.TrackParentTask.Config
  end
  if task.ActivityTaskIcon and Conf and Conf.task_class == Enum.TaskClassType.TCT_CAMPAIGN then
    return task.ActivityTaskIcon
  end
  if not Conf then
    return ""
  end
  local Style = _G.DataConfigManager:GetTaskStyleConf(Conf.task_class, true)
  Style = Style or _G.DataConfigManager:GetTaskStyleConf(Enum.TaskClassType.TCT_NONE)
  local State = task.Info.state
  if State == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    return Style.icon_open
  elseif State == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
    return Style.icon_wait
  elseif State == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    return Style.icon_done
  else
    return ""
  end
end

function TaskUtils.GetTaskAcceptIcon(TaskConf)
  local IconPath = ""
  if not TaskConf then
    return IconPath
  end
  local _taskClass = TaskConf.task_class
  if _taskClass == Enum.TaskClassType.TCT_MAIN then
    IconPath = UEPath.TASK_ICON_MAIN_WENHAO
  elseif _taskClass == Enum.TaskClassType.TCT_SUB or _taskClass == Enum.TaskClassType.TCT_EVOLUTION or _taskClass == Enum.TaskClassType.TCT_CAMPAIGN then
    IconPath = UEPath.TASK_ICON_SUB_WENHAO
  elseif _taskClass == Enum.TaskClassType.TCT_DUNGEON or _taskClass == Enum.TaskClassType.TCT_JOURNEY then
    IconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
  else
    IconPath = UEPath.TASK_ICON_WENHAO
  end
  return IconPath
end

function TaskUtils.GetTaskAcceptIconByTaskID(TaskID)
  local IconPath = ""
  local TaskConf = _G.DataConfigManager:GetTaskConf(TaskID)
  if not TaskConf then
    return IconPath
  end
  local _taskClass = TaskConf.task_class
  if _taskClass == Enum.TaskClassType.TCT_MAIN then
    IconPath = UEPath.TASK_ICON_MAIN_WENHAO
  elseif _taskClass == Enum.TaskClassType.TCT_SUB or _taskClass == Enum.TaskClassType.TCT_EVOLUTION or _taskClass == Enum.TaskClassType.TCT_CAMPAIGN then
    IconPath = UEPath.TASK_ICON_SUB_WENHAO
  elseif _taskClass == Enum.TaskClassType.TCT_DUNGEON or _taskClass == Enum.TaskClassType.TCT_JOURNEY then
    IconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
  else
    IconPath = UEPath.TASK_ICON_WENHAO
  end
  return IconPath
end

function TaskUtils.GetWorldMapConfigForAcceptableTaskByTaskID(TaskConf)
  local globalConfKey = ""
  local _taskClass = TaskConf.task_class
  if _taskClass == Enum.TaskClassType.TCT_MAIN then
    globalConfKey = "MAP_MAINQUEST"
  elseif _taskClass == Enum.TaskClassType.TCT_SUB or _taskClass == Enum.TaskClassType.TCT_EVOLUTION or _taskClass == Enum.TaskClassType.TCT_CAMPAIGN then
    globalConfKey = "MAP_SUBQUEST"
  elseif _taskClass == Enum.TaskClassType.TCT_DUNGEON or _taskClass == Enum.TaskClassType.TCT_JOURNEY then
    globalConfKey = "MAP_JOURNEYQUEST"
  else
    globalConfKey = "MAP_JOURNEYQUEST"
  end
  local globalConf = _G.DataConfigManager:GetGlobalConfig(globalConfKey)
  if not globalConf or not globalConf.num then
    return nil
  end
  local worldMapConf = _G.DataConfigManager:GetWorldMapConf(globalConf.num)
  return worldMapConf
end

function TaskUtils.SetupGoalStateIcon(task, finished, icon)
  if not icon then
    return
  end
  if not task then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  local Path = TaskUtils.GetGoalStateIcon(task, finished)
  if string.IsNilOrEmpty(Path) then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    icon:SetVisibility(UE4.ESlateVisibility.Visible)
    icon:SetPath(Path)
  end
end

function TaskUtils.GetGoalStateIcon(task, finished)
  local Conf = _G.DataConfigManager:GetTaskConf(task.id)
  if not Conf then
    return ""
  end
  local Style = _G.DataConfigManager:GetTaskStyleConf(Conf.task_class, true)
  Style = Style or _G.DataConfigManager:GetTaskStyleConf(Enum.TaskClassType.TCT_NONE)
  if finished then
    return Style.icon_done
  else
    return Style.icon_open
  end
end

function TaskUtils.SetupGoalStateIconSub(task, finished, icon)
  if not icon then
    return
  end
  if not task then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  local Path = TaskUtils.GetGoalStateIconSub(task, finished)
  if string.IsNilOrEmpty(Path) then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    icon:SetVisibility(UE4.ESlateVisibility.Visible)
    icon:SetPath(Path)
  end
end

function TaskUtils.GetGoalStateIconSub(task, finished)
  local Conf = _G.DataConfigManager:GetTaskConf(task.id)
  if not Conf then
    return ""
  end
  local Style = _G.DataConfigManager:GetTaskStyleConf(Conf.task_class, true)
  Style = Style or _G.DataConfigManager:GetTaskStyleConf(Enum.TaskClassType.TCT_NONE)
  if finished then
    return Style.sub_icon_done
  else
    return Style.sub_icon_open
  end
end

function TaskUtils.GetPoiIcon(POIClass)
  if 1 == POIClass or 4 == POIClass then
    return "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/Lobby/Frames/img_icon_jiemi_1_png.img_icon_jiemi_1_png'"
  elseif 2 == POIClass then
    return "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/Lobby/Frames/img_icon_jiemi_0_png.img_icon_jiemi_0_png'"
  else
    return ""
  end
end

function TaskUtils.SetupPoiIcon(POIClass, icon)
  if not icon then
    return
  end
  if not POIClass then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  local Path = TaskUtils.GetPoiIcon(POIClass)
  if string.IsNilOrEmpty(Path) then
    icon:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    icon:SetVisibility(UE4.ESlateVisibility.Visible)
    icon:SetPath(Path)
  end
end

function TaskUtils.GetTaskStateIndex(task)
  local Conf = _G.DataConfigManager:GetTaskConf(task.id)
  if not Conf then
    return 0
  end
  local Style = _G.DataConfigManager:GetTaskStyleConf(Conf.task_class)
  Style = Style or _G.DataConfigManager:GetTaskStyleConf(Enum.TaskClassType.TCT_NONE)
  if task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    return Style.minimap_open
  elseif task.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
    return Style.minimap_wait
  else
    return 0
  end
end

function TaskUtils.DiffTargetList(tl1, tl2)
  if tl1 and tl2 then
    if #tl1 == #tl2 then
      for i = 1, #tl1 do
        if tl1[i] ~= tl2[i] then
          return false
        end
      end
      return true
    else
      return false
    end
  elseif not tl1 and tl2 then
    return false
  elseif tl1 and not tl2 then
    return false
  else
    return true
  end
end

function TaskUtils.DiffTask(taskInfo1, taskInfo2)
  if taskInfo1 and taskInfo2 then
    if taskInfo1.id == taskInfo2.id then
      if taskInfo2.state_change then
        return 5
      else
        return 0
      end
    else
      return 1
    end
  elseif taskInfo1 and not taskInfo2 then
    return 2
  elseif not taskInfo1 and taskInfo2 then
    return 3
  end
  return 4
end

function TaskUtils.MergeTaskList(taskList1, taskList2)
  local ret = {}
  if not taskList1 and taskList2 then
    for _, task in ipairs(taskList2) do
      table.insert(ret, {
        Old = task,
        New = task,
        Diff = 0
      })
    end
    return ret
  end
  taskList1 = taskList1 or {}
  taskList2 = taskList2 or {}
  local count = math.max(#taskList1, #taskList2)
  for i = 1, count do
    local O = taskList1[i]
    local N = taskList2[i]
    local D = TaskUtils.DiffTask(O, N)
    if 2 ~= D and 4 ~= D then
      local taskPair = {
        Old = O,
        New = N,
        Diff = D
      }
      table.insert(ret, taskPair)
    end
  end
  return ret
end

TaskUtils.FinishColor = TaskUtils.MakeSlateColor(247, 234, 114, 255)
TaskUtils.OtherColor = TaskUtils.MakeSlateColor(247, 234, 114, 255)

function TaskUtils:getPlayerModule()
  return NRCModuleManager:GetModule("PlayerModule")
end

function TaskUtils:getSceneModule()
  return NRCModuleManager:GetModule("SceneModule")
end

function TaskUtils:getNpcModule()
  return NRCModuleManager:GetModule("NPCModule")
end

function TaskUtils:getTaskModule()
  return NRCModuleManager:GetModule("TaskModule")
end

function TaskUtils:GetNearestNPCDistance(ids, player)
  if nil == ids then
    return nil
  end
  if not player then
    return nil
  end
  local Module = TaskUtils:getNpcModule()
  if not Module then
    return nil
  end
  local AllNPC = Module._npcDic
  if not AllNPC then
    return nil
  end
  local PlayerPos = player:GetActorLocation()
  local Near = math.maxinteger
  for _, npc in pairs(AllNPC) do
    if table.contains(ids, npc.config.id) then
      local NpcPos = npc:GetActorLocation()
      if NpcPos then
        local Dist = UE4.FVector.DistSquared2D(NpcPos, PlayerPos)
        if Near > Dist then
          Near = Dist
        end
      end
    end
  end
  if Near ~= math.maxinteger then
    return Near
  else
    return nil
  end
end

function TaskUtils:GetNearestNPCLocation(ids, player)
  if nil == ids then
    return nil
  end
  if not player then
    return nil
  end
  local Module = TaskUtils:getNpcModule()
  if not Module then
    return nil
  end
  local AllNPC = Module._npcDic
  if not AllNPC then
    return nil
  end
  local PlayerPos = player:GetActorLocation()
  local Near = math.maxinteger
  local DaNPC
  for _, npc in pairs(AllNPC) do
    if table.contains(ids, npc.config.id) then
      local NpcPos = npc:GetActorLocation()
      if NpcPos then
        local Dist = UE4.FVector.DistSquared2D(NpcPos, PlayerPos)
        if Near > Dist then
          Near = Dist
          DaNPC = NpcPos
        end
      end
    end
  end
  if Near ~= math.maxinteger then
    return DaNPC
  else
    return nil
  end
end

function TaskUtils:GetTaskPosition(config, player)
  if not config then
    return nil
  end
  local Condition = config.go_guide
  if not Condition then
    return nil
  end
  if 0 == #Condition then
    return nil
  end
  local Near = math.maxinteger
  for _, Cond in ipairs(Condition) do
    if Cond.type == ProtoEnum.TaskGoActionType.TGAT_BASE_NPC then
      local Pos = TaskUtils:GetNearestNPCDistance(Cond.go_data1, player)
      if Pos and Near > Pos then
        Near = Pos
      end
    elseif Cond.type == ProtoEnum.TaskGoActionType.TGAT_AREA then
    end
  end
  if Near ~= math.maxinteger then
    return math.sqrt(Near) / 100
  else
    return Near
  end
end

function TaskUtils:GetTaskPositionLocal(config, player)
  if not config then
    return nil
  end
  local Condition = config.go_guide
  if not Condition then
    return nil
  end
  if 0 == #Condition then
    return nil
  end
  local Near = math.maxinteger
  for _, Cond in ipairs(Condition) do
    if Cond.type == ProtoEnum.TaskGoActionType.TGAT_BASE_NPC then
      local Pos = TaskUtils:GetNearestNPCDistance(Cond.go_data1, player)
      if Pos and Near > Pos then
        Near = Pos
      end
    elseif Cond.type == ProtoEnum.TaskGoActionType.TGAT_AREA then
    end
  end
  if Near ~= math.maxinteger then
    return math.sqrt(Near) / 100
  else
    return Near
  end
end

function TaskUtils:GetTaskNPCPosition(task_config)
  if not task_config then
    return nil
  end
  local Condition = task_config.go_guide
  if not Condition then
    return nil
  end
  if 0 == #Condition then
    return nil
  end
  for _, Cond in ipairs(Condition) do
    if Cond.type == ProtoEnum.TaskGoActionType.TGAT_BASE_NPC then
      local ids = Cond.go_data1
      if nil == ids then
        return nil
      end
      local Module = TaskUtils:getNpcModule()
      if not Module then
        return nil
      end
      local AllNPC = Module._npcDic
      if not AllNPC then
        return nil
      end
      for _, npc in pairs(AllNPC) do
        if table.contains(ids, npc.config.id) then
          return npc:GetActorLocation()
        end
      end
    end
  end
end

function TaskUtils:GetPlayer()
  return NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function TaskUtils:is_empty(t)
  for _, _ in pairs(t) do
    return false
  end
  return true
end

function TaskUtils.ShowTips(content)
  NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, content or "empty")
end

function TaskUtils.GetStateName(state)
  for name, id in pairs(ProtoEnum.EMTaskState) do
    if state == id then
      return name
    end
  end
  return "EMTaskState Not Found"
end

function TaskUtils.HasDialogue()
  return _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue)
end

function TaskUtils.CollectRelativeTasks(Task, Map)
  if not Task then
    return nil
  end
  if not Task:IsOpenOrWait() then
    return nil
  end
  local Conf = Task.Config
  if not Conf then
    return nil
  end
  if not Map then
    return nil
  end
  local Relatives
  local TotalTaskMap = Map
  for Index, Guide in ipairs(Conf.go_guide) do
    if Guide.type ~= Enum.TaskGoActionType.TGAT_TRACK_TASK then
    else
      local SearchType = Guide.data1[1]
      if not SearchType then
      elseif 1 == SearchType then
        for _, ParagraphID in ipairs(Guide.data2) do
          for _, SearchTask in pairs(TotalTaskMap) do
            if SearchTask.Config.paragraph_id == ParagraphID and not SearchTask:IsFinish() then
              Relatives = Relatives or {}
              SearchTask.ParentGoIndex = Index
              table.insert(Relatives, SearchTask)
            end
          end
        end
      elseif 2 == SearchType then
        for _, TargetID in ipairs(Guide.data2) do
          local SearchTask = TotalTaskMap[TargetID]
          if SearchTask and not SearchTask:IsFinish() then
            Relatives = Relatives or {}
            SearchTask.ParentGoIndex = Index
            table.insert(Relatives, SearchTask)
          end
        end
      end
    end
  end
  return Relatives
end

return TaskUtils

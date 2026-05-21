local Class = _G.MakeSimpleClass
local rapidjson = require("rapidjson")
local ResObject = require("NewRoco.Utils.ResObject")
local EventDispatcher = require("Common.EventDispatcher")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local TaskTrackItem = require("NewRoco.Modules.Core.Task.TaskTrackItem")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local StaticCircleArea = require("NewRoco.Modules.Core.Task.StaticCircleArea")
local TaskActionFactory = require("NewRoco.Modules.Core.Task.TaskActionFactory")
local PointTaskTrackItem = require("NewRoco.Modules.Core.Task.PointTaskTrackItem")
local CircleTaskTrackItem = require("NewRoco.Modules.Core.Task.CircleTaskTrackItem")
local TaskActionGroupEnum = require("NewRoco.Modules.Core.Task.TaskActionGroupEnum")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local ReachPointTrackItem = require("NewRoco.Modules.Core.Task.ReachPointTrackItem")
local WildTrackItem = require("NewRoco.Modules.Core.Task.WildTrackItem")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")

local function GetNum(Key, Default)
  local Conf = _G.DataConfigManager:GetTaskGlobalConfig(Key)
  if not Conf then
    return Default
  end
  return Conf.num or Default
end

local SkipSendingRequest = false
local TrackClass = {
  [ProtoEnum.TaskGoActionType.TGAT_BASE_NPC] = TaskTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_CONTENT] = TaskTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_AREA] = TaskTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_NPC_PRIORITY] = TaskTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_NPC_CIRCLE] = CircleTaskTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_POINT_SET] = PointTaskTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_TELE_STRUCTURE] = ReachPointTrackItem,
  [ProtoEnum.TaskGoActionType.TGAT_WILD_CREATURE] = WildTrackItem
}
local BeginRange = GetNum("tele_structure_begin", 1000)
local EndRange = GetNum("tele_structure_end", 1000)
BeginRange = BeginRange * 100.0
EndRange = EndRange * 100.0
local TaskObject = Class("TaskObject")
EventDispatcher.BindClass(TaskObject)
TaskObject:SetMemberCount(32)

function TaskObject:PreCtor()
  self.Info = nil
  self.isTrack = false
  self.ShouldShow = false
  self.ShouldRemove = false
  self.MarkedFinished = false
  self.ShouldDestroy = false
  self.GuideFinished = false
  self.GuideTimeout = false
  self.HasGuideActor = true
  self.SplineGuideActor = nil
  self.SplineGuideActorRef = nil
  self.Res = nil
  self.isNew = true
  self.StaticPosition = nil
  self.UseStaticPosition = false
  self.LastSceneGroupFlag = nil
  self.ActivityTaskIcon = nil
  self.TrackParentTask = nil
  self.ParentGoIndex = 0
  self.CreateTime = os.msTime()
  self.TriggerAcceptActionArea = false
  self.TriggerFinishActionArea = false
  self.StatusChecker = false
  self.Action = nil
  self.ServerIsTrack = false
end

function TaskObject:Ctor(Module, Info)
  EventDispatcher():Attach(self)
  self.ENTERS = {
    [ProtoEnum.EMTaskState.EM_TASK_STATE_INIT] = self.EnterInit,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN_PLAY] = self.EnterOpenPlay,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN] = self.EnterOpen,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_WAITING] = self.EnterWaiting,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT] = self.EnterWait,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_DONE_PLAY] = self.EnterDonePlay,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_DONE] = self.EnterDone,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSED] = self.EnterClose
  }
  self.LEAVES = {
    [ProtoEnum.EMTaskState.EM_TASK_STATE_INIT] = self.LeaveInit,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN_PLAY] = self.LeaveOpenPlay,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN] = self.LeaveOpen,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_WAITING] = self.LeaveWaiting,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT] = self.LeaveWait,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_DONE_PLAY] = self.LeaveDonePlay,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_DONE] = self.LeaveDone,
    [ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSED] = self.LeaveClose
  }
  self.Module = Module
  self.Config = _G.DataConfigManager:GetTaskConf(Info.id)
  self.Conditions = self.Config.task_condition
  self.ParagraphConf = 0 ~= self.Config.paragraph_id and _G.DataConfigManager:GetParagraphConf(self.Config.paragraph_id) or nil
  self.bCanRefreshEnter = true
end

function TaskObject:UpdateTask(Info, TriggerStateChange)
  local New = Info
  local Old = self.Info
  self.Info = Info
  TriggerStateChange = TriggerStateChange or Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN_PLAY
  TriggerStateChange = TriggerStateChange or Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN
  TriggerStateChange = TriggerStateChange or Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE_PLAY
  if TriggerStateChange then
    if Old and New then
      if Old.state ~= New.state then
        self:ChangeState(New, Old)
      else
        self:UpdateContent(New, Old)
      end
    elseif not Old and New then
      self:ChangeState(New, Old)
    end
  elseif self.Info.new_task then
    self.ShouldShow = false
    self.isNew = false
  end
  self:UpdateTrack(New)
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.OnTaskUpdated, Info)
end

local function PrintTaskChangeStateLog(Info)
  if Log.GetLogLevel() > Log.LOG_LEVEL.ELogDebug then
    return
  end
  Log.DebugFormat("[TaskFlow] \228\187\187\229\138\161\231\138\182\230\128\129\229\143\152\229\140\150 taskchangestate;%d;%s", Info.id, TaskUtils.GetStateName(Info.state))
end

function TaskObject:ChangeState(New, Old)
  self:Leave(Old and Old.state, New, Old)
  self:Enter(New and New.state, New, Old)
  PrintTaskChangeStateLog(New)
end

function TaskObject:UpdateContent(New, Old)
  if New.is_trace ~= Old.is_trace then
    self:OnTraceChanged()
  end
  if not TaskUtils.DiffTargetList(New.task_target_list, Old.task_target_list) then
    self:OnTargetListChanged()
  end
end

function TaskObject:Leave(state, New, Old)
  if not state then
    return
  end
  local Func = self.LEAVES[state]
  if Func then
    Func(self, New)
  else
    Log.Error("Not implemented...", state)
  end
end

function TaskObject:Enter(state, New, Old)
  if not state then
    return
  end
  local Func = self.ENTERS[state]
  if Func then
    Func(self, New, Old)
  else
    Log.Error("Not implemented...", state)
  end
end

function TaskObject:OnRemove()
  Log.DebugFormat("[TaskFlow] \229\174\162\230\136\183\231\171\175\231\167\187\233\153\164\228\187\187\229\138\161:%d", self.Info.id)
  self.ShouldShow = false
  self.ShouldRemove = true
  self:TryRemoveCompletedGuide(self.Info.id)
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.OnTaskRemoved, self.Info)
end

function TaskObject:OnTraceChanged(New)
end

function TaskObject:SetTrack(isTrack, New, UserOperate)
  New = New or self.Info
  local Changed = false
  if self.isTrack ~= isTrack then
    Changed = true
  end
  self.isTrack = isTrack
  isTrack = self:IsTrack()
  local isCampaignActivity = self.Config.task_class == Enum.TaskClassType.TCT_CAMPAIGN
  if UserOperate then
    self.Info.is_track = self.isTrack
  end
  local TrackIsExist = self.Trackers and #self.Trackers > 0
  if TrackIsExist then
    self:UpdateTrackers(New)
  elseif not TrackIsExist then
    self:AddTrackers(New)
  elseif TrackIsExist and not isTrack and (not isCampaignActivity or not not UserOperate) then
    self:StopTraceTaskItem(New)
  end
  if self.TrackSubTasks then
    for _, Sub in ipairs(self.TrackSubTasks) do
      Sub:SetParentTrackTask(self)
    end
  end
  if Changed then
    Log.DebugFormat("[TaskFlow]\232\174\190\231\189\174\228\187\187\229\138\161\232\191\189\232\184\170\231\138\182\230\128\129:%d;%s,%s", self.Config.id, isTrack and "\232\191\189\232\184\170" or "\228\184\141\232\191\189\232\184\170", UserOperate and "\230\137\139\229\138\168\232\167\166\229\143\145" or "\232\135\170\229\138\168\232\167\166\229\143\145")
  end
  self:SendEvent(TaskModuleEvent.ON_TASK_UPDATE, self)
  return Changed
end

function TaskObject:UpdateTrack(New)
  self.ServerIsTrack = New.is_track
  self:SetTrack(New.is_track and self:IsOpenOrWait() or false, New, false)
end

function TaskObject:RemovePerform()
end

function TaskObject:AddTrackers(New)
  if not self.Trackers then
    self.Trackers = {}
  end
  if self:IsFinish() then
    return
  end
  for index, go in ipairs(self.Config.go_guide) do
    local Klass = TrackClass[go.type]
    if Klass then
      local bIsExist = false
      for __, Tracker in ipairs(self.Trackers) do
        if Tracker.TaskInfo.id == self.Config.id and Tracker.go_index == index then
          bIsExist = true
          break
        end
      end
      if not bIsExist then
        local Item = Klass(self.Config, New, go, self, index)
        if Item then
          table.insert(self.Trackers, Item)
          Item:AddEventListener(self, TaskModuleEvent.ON_UPDATE_TRACK, self.OnTrackUpdate)
        end
      end
    end
  end
  self:SendEvent(TaskModuleEvent.ON_START_TRACK, self)
end

function TaskObject:UpdateTrackers(New)
  if self.Trackers then
    for _, TrackItem in ipairs(self.Trackers) do
      TrackItem:UpdateTaskInfo(New)
      if self:IsTrack() then
        _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_UPDATE_TRACK, TrackItem)
      end
    end
  else
    self:AddTrackers(New)
  end
end

function TaskObject:RemoveTrackers(New)
  if not self.Trackers then
    return
  end
  for _, TrackItem in ipairs(self.Trackers) do
    TrackItem:RemoveEventListener(self, TaskModuleEvent.ON_UPDATE_TRACK, self.OnTrackUpdate)
    TrackItem:Destroy()
    NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_STOP_TRACK, TrackItem)
  end
  table.clear(self.Trackers)
  self:SendEvent(TaskModuleEvent.ON_STOP_TRACK, self)
end

function TaskObject:StopTraceTaskItem(New)
  if not self.Trackers then
    return
  end
  for _, TrackItem in ipairs(self.Trackers) do
    NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_STOP_TRACK_TASK_ITEM, TrackItem)
  end
end

function TaskObject:GetTracker(Index, bCheckValid)
  if not self.Trackers then
    return nil
  end
  for _, Tracker in ipairs(self.Trackers) do
    if Tracker.TaskObject:IsFinish() then
    else
      local GoalIndex
      if Tracker.TaskObject == self then
        GoalIndex = Tracker.go_index
      else
        GoalIndex = Tracker.TaskObject.ParentGoIndex
      end
      if bCheckValid then
        if GoalIndex == Index and (Tracker.Valid or Tracker.MinimapValid) then
          return Tracker
        end
      elseif GoalIndex == Index then
        return Tracker
      end
    end
  end
  return nil
end

function TaskObject:OnTargetListChanged(New)
  self:SendEvent(TaskModuleEvent.ON_TASK_PROGRESS_CHANGED, self)
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_TASK_PROGRESS_CHANGED, self)
end

function TaskObject:EnterInit(New, Old)
end

function TaskObject:LeaveInit(New, Old)
end

function TaskObject:UpdateActions(ActionGroup)
  local PendingAction
  for Index, Action in ipairs(self.Config[ActionGroup]) do
    local ActionInst = TaskActionFactory.TryMakeAction(self, ActionGroup, Index, Action)
    if ActionInst then
      PendingAction = ActionInst
      break
    end
  end
  self:SetPendingAction(PendingAction)
end

function TaskObject:UpdateActionsByCond(TaskCondition)
  local PendingAction
  for Index, Action in ipairs(self.Config.task_condition) do
    local ActionInst = TaskActionFactory.TryMakeActionByCond(self, TaskCondition, Index, Action)
    if ActionInst then
      PendingAction = ActionInst
      break
    end
  end
  self:SetPendingAction(PendingAction)
end

function TaskObject:CloseActions(ActionGroup)
  if self.Action and self.Action.ActionGroup == ActionGroup then
    self.Action:Destroy()
    self.Action = nil
  end
end

function TaskObject:EnterOpenPlay(New, Old)
  self:CreateTriggerAcceptArea()
  self.ShouldShow = false
  self.ShouldRemove = false
  self:UpdateActions(TaskActionGroupEnum.Accept)
end

function TaskObject:LeaveOpenPlay(New, Old)
  self:CloseActions(TaskActionGroupEnum.Accept)
  self:DestroyTriggerAcceptArea()
end

function TaskObject:ShouldProcessActionWhenOpen()
  if self.Config.task_structure_type == ProtoEnum.TaskStructureType.TSTT_CINEMA then
    return true
  end
  for _, Action in ipairs(self.Config.accept_action) do
    if Action.type == ProtoEnum.TaskStateChangeActionType.TSCAT_GO_CMD or Action.type == ProtoEnum.TaskStateChangeActionType.TSCAT_SLIDE then
      return true
    end
  end
  return false
end

function TaskObject:EnterOpen(New, Old)
  self:CreateTriggerAcceptArea()
  self:CreateTriggerFinishArea()
  if self:ShouldProcessActionWhenOpen() then
    self:UpdateActions(TaskActionGroupEnum.Accept)
  end
  if self:ShouldProcessTaskCondActionWhenOpen() then
    self:UpdateActionsByCond(TaskActionGroupEnum.Condition)
  end
  self.ShouldShow = true
  self.ShouldRemove = false
end

function TaskObject:ShouldProcessTaskCondActionWhenOpen()
  for _, Cond in ipairs(self.Config.task_condition) do
    if Cond.type == ProtoEnum.TaskKeyType.TKT_MINI_PACKAGE_DONE then
      return true
    end
  end
  return false
end

function TaskObject:EnterWaiting(New, Old)
end

function TaskObject:LeaveOpen(New, Old)
  self:DestroyTriggerAcceptArea()
  self:DestroyTriggerFinishArea()
end

function TaskObject:EnterWait(New, Old)
  self:CreateTriggerFinishArea()
end

function TaskObject:LeaveWaiting(New, Old)
end

function TaskObject:LeaveWait(New, Old)
  self:DestroyTriggerFinishArea()
end

function TaskObject:EnterDonePlay(New, Old)
  self.ShouldShow = false
  self.ShouldRemove = false
  self:UpdateActions(TaskActionGroupEnum.Finish)
end

function TaskObject:OnDonePlayFinishRsp(rsp)
  self.Module:ClearPendingTask(self)
end

function TaskObject:LeaveDonePlay(New, Old)
  self:CloseActions(TaskActionGroupEnum.Finish)
end

function TaskObject:ShouldProcessActionWhenDone()
  for _, Action in ipairs(self.Config.finish_action) do
    if Action.type == ProtoEnum.TaskStateChangeActionType.TSCAT_GO_CMD or Action.type == ProtoEnum.TaskStateChangeActionType.TSCAT_SLIDE then
      return true
    end
  end
  return false
end

function TaskObject:EnterDone(New, Old)
  self:OnRemove()
  if self:ShouldProcessActionWhenDone() then
    self:UpdateActions(TaskActionGroupEnum.Finish)
  end
  for _, Condition in ipairs(self.Config.finish_action) do
    if Condition.type == Enum.TaskStateChangeActionType.TSCAT_TASK_SUMMARY then
      _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskSummaryData, self.Config.id)
    end
  end
end

function TaskObject:LeaveDone(New, Old)
end

function TaskObject:EnterClose(New, Old)
end

function TaskObject:LeaveClose(New, Old)
end

function TaskObject:ConsumeShow()
  if not self.ShouldShow then
    return
  end
  Log.DebugFormat("[TaskFlow] \228\187\187\229\138\161\229\135\186\231\142\176\232\161\168\230\188\148\230\146\173\230\148\190\229\174\140\230\136\144:%d", self.Config.id)
  self.ShouldShow = false
  self:OnShowConsumed()
end

function TaskObject:ConsumeRemove()
  if not self.ShouldRemove then
    return
  end
  Log.DebugFormat("[TaskFlow] \228\187\187\229\138\161\230\182\136\229\164\177\232\161\168\230\188\148\230\146\173\230\148\190\229\174\140\230\136\144:%d", self.Config.id)
  self.ShouldRemove = false
  self.MarkedFinished = true
  self:OnRemoveConsumed()
end

function TaskObject:HasNextTasks()
  return not self.Config.is_para_done
end

function TaskObject:IsStartOfParagraph()
  if not self.Config.is_para_start then
    return false
  end
  if self.ParagraphConf then
    return self.ParagraphConf.show_task_start
  else
    Log.Error("\230\156\137\228\184\128\228\184\170\228\187\187\229\138\161", self.Config.id, "\229\161\171\228\186\134is_para_start\228\189\134\230\152\175\230\178\161\230\156\137\233\133\141\231\171\160\232\138\130id", self.Config.paragraph_id)
    return false
  end
end

function TaskObject:OnShowConsumed()
  if self:IsStartOfParagraph() and self.isTrack then
    Log.DebugFormat("[TaskFlow] \229\135\134\229\164\135\229\188\185\229\135\186\228\187\187\229\138\161\229\188\128\229\167\139\230\143\144\231\164\186,\228\187\187\229\138\161ID:%d", self.Config.id)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.FromTaskAccept(self.Info))
  else
    NRCEventCenter:DispatchEvent(TaskModuleEvent.TipsPerformFinished)
  end
end

function TaskObject:OnRemoveConsumed()
  if self:HasNextTasks() then
    NRCEventCenter:DispatchEvent(TaskModuleEvent.TipsPerformFinished)
  else
    Log.DebugFormat("[TaskFlow] \229\135\134\229\164\135\229\188\185\229\135\186\228\187\187\229\138\161\229\174\140\230\136\144\230\143\144\231\164\186,\228\187\187\229\138\161ID:%d", self.Config.id)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.FromTaskComplete(self.Info))
  end
end

function TaskObject:ShouldDisplay()
  if self.ShouldShow then
    return true
  end
  if self.ShouldRemove then
    return true
  end
  return self.Info.is_track
end

function TaskObject:IsOpenOrWait()
  local State = self.Info.state
  return State == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN or State == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT
end

function TaskObject:ShowInTaskPanel()
  if 1 == self.Config.show then
    return false
  end
  if not self:IsOpenOrWait() then
    return false
  end
  if self.ShouldRemove then
    return false
  end
  return true
end

function TaskObject:CheckConditionDone(Index)
  local TargetList = self.Info and self.Info.task_target_list
  local Current = TargetList and TargetList[Index] or 0 or 0
  local Cond = self.Conditions[Index]
  local Need = Cond and Cond.count or 0
  return Current >= Need
end

function TaskObject:GetGuideActor(Create)
  if self.GuideFinished then
    return nil
  end
  if not Create and self.GuideTimeout then
    return nil
  end
  if not Create and not self.HasGuideActor then
    return nil
  end
  if self.SplineGuideActor then
    if UE.UObject.IsValid(self.SplineGuideActor) then
      if Create then
        self.SplineGuideActor.CurrentLifeTime = 0
      end
      return self.SplineGuideActor
    end
    self.SplineGuideActor = nil
    self.SplineGuideActorRef = nil
  end
  local GuideConf = _G.DataConfigManager:GetGuideConf(self.Config.id, true)
  if not GuideConf then
    self.HasGuideActor = false
    return nil
  end
  if not Create and not GuideConf.auto_create then
    self.HasGuideActor = false
    return nil
  end
  self:MakeGuideActor(GuideConf)
end

function TaskObject:MakeGuideActor(GuideConf)
  if not GuideConf then
    GuideConf = _G.DataConfigManager:GetGuideConf(self.Config.id, true)
    if not GuideConf then
      self.HasGuideActor = false
      return
    end
  end
  if not self.Res then
    self.Res = ResObject.MakeUClass("/Game/NewRoco/Modules/Core/Task/BP_TaskGuideSpline.BP_TaskGuideSpline_C", 255)
  end
  local Klass = self.Res:Get()
  if not Klass then
    return
  end
  if self.Res then
    self.Res:Release()
    self.Res = nil
  end
  self.GuideFinished = false
  self.GuideTimeout = false
  local Pos = GuideConf.position
  local Rot = GuideConf.rotation
  local Scale = GuideConf.scale
  local FPos = UE.FVector(Pos[1], Pos[2], Pos[3])
  local FRot = UE.FRotator(Rot[2], Rot[3], Rot[1])
  local FQuat = FRot:ToQuat()
  local FScale = UE.FVector(Scale[1], Scale[2], Scale[3])
  local Transform = UE.FTransform(FQuat, FPos, FScale)
  local Always = UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
  self.SplineGuideActor = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(Klass, Transform, Always, nil, nil, nil, GuideConf)
  if self.SplineGuideActor then
    self.SplineGuideActorRef = UnLua.Ref(self.SplineGuideActor)
    self.SplineGuideActor.Task = self
  else
    Log.Error("TaskObject:Fail to load spline guide actor")
  end
  self.HasGuideActor = true
  _G.NRCAudioManager:PlaySound2DAuto(1294, "TaskModule:PlaySpawnSplineSound")
end

function TaskObject:RemoveGuide(MarkFinished, MarkTimeout)
  self.GuideFinished = true == MarkFinished
  self.GuideTimeout = true == MarkTimeout
  if self.Res then
    self.Res:Release()
    self.Res = nil
  end
  if UE.UObject.IsValid(self.SplineGuideActor) then
    _G.NRCAudioManager:PlaySound2DAuto(1295, "TaskModule:PlayKillSplineSound")
    self.SplineGuideActor:K2_DestroyActor()
  end
  self.SplineGuideActor = nil
  self.SplineGuideActorRef = nil
end

local MoveCMD = _G.ProtoCMD.ZoneSvrCmd.ZONE_MOVE_FINISH_TASK_REQ
local MoveReq = _G.ProtoMessage:newZoneMoveFinishTaskReq()

function TaskObject:ReportPlayerPosition()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local MoveComp = Player.movementComponent
  if MoveComp then
    MoveComp:SendMoveReq(true, false)
  end
  Log.DebugFormat("[TaskFlow] \229\144\145\229\144\142\229\143\176\229\143\145\233\128\129\228\187\187\229\138\161\229\174\140\230\136\144\229\141\143\232\174\174,\228\187\187\229\138\161ID:%d,\228\187\187\229\138\161\231\138\182\230\128\129:%s", self.Config.id, TaskUtils.GetStateName(self.Info.state))
  Player:GetServerPosition(MoveReq.to_pos)
  MoveReq.scene_cfg_id = SceneUtils.GetSceneID()
  MoveReq.time_stamp = _G.ZoneServer:GetServerTime()
  _G.ZoneServer:SendWithHandler(MoveCMD, MoveReq, self, self.OnReportPlayerPosition, false, true)
end

function TaskObject:OnReportPlayerPosition(rsp)
  Log.DebugFormat("[TaskFlow] \228\187\187\229\138\161\229\174\140\230\136\144\229\141\143\232\174\174\229\155\158\229\140\133,\228\187\187\229\138\161ID:%d", self.Config.id)
  if self.TriggerAcceptActionArea then
    self.TriggerAcceptActionArea.bPreviouslyInArea = false
  end
  if self.TriggerFinishActionArea then
    self.TriggerFinishActionArea.bPreviouslyInArea = false
  end
end

function TaskObject:EnterArea(Area, X, Y, Z, PlayerRadius, PlayerHalfHeight)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local bVisiting = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local bVisitOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
  local bTogether = player:IsInTogetherMove()
  local bTogether2P = player:IsTogetherMove2P()
  Log.DebugFormat("[TaskFlow] \232\191\155\229\133\165\228\187\187\229\138\161\232\167\166\229\143\145\229\140\186\229\159\159,\228\187\187\229\138\161ID:%d,\229\189\147\229\137\141\228\187\187\229\138\161\231\138\182\230\128\129:%s,\232\129\148\230\156\186\231\138\182\230\128\129:%s,\229\144\140\232\161\140\231\138\182\230\128\129:%s", self.Config.id, TaskUtils.GetStateName(self.Info.state), bVisiting and (bVisiting and "Owner" or "Visitor") or "Single", bTogether and (bTogether2P and "2P" or "1P") or "No")
  local bIsDungeonTask = false
  if self.Config.task_structure_type == Enum.TaskStructureType.TSTT_TELEPORT then
    for _, Action in ipairs(self.Config.accept_action) do
      if Action.type == Enum.TaskStateChangeActionType.TSCAT_ENTER_DUNGEON then
        bIsDungeonTask = true
        break
      end
    end
    if not bIsDungeonTask then
      for _, Action in ipairs(self.Config.finish_action) do
        if Action.type == Enum.TaskStateChangeActionType.TSCAT_ENTER_DUNGEON then
          bIsDungeonTask = true
          break
        end
      end
    end
  end
  if bVisiting and bIsDungeonTask then
    if self.bCanRefreshEnter then
      self.bCanRefreshEnter = false
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local Context = DialogContext()
      local Content = LuaText.task_enter_dungeon_note or ""
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
        if result then
          _G.NRCModuleManager:DoCmd(FriendModuleCmd.CmdZoneDisbandVisitReq)
        else
          self.RefreshEnterHandleID = _G.DelayManager:DelaySeconds(10, function()
            self.bCanRefreshEnter = true
          end)
        end
      end):SetButtonText(LuaText.worldcombatmodule_1, LuaText.worldcombatmodule_2)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return
  end
  if bTogether and bTogether2P then
    Log.Debug("[TaskFlow] \231\137\181\230\137\1392P\231\138\182\230\128\129\228\184\139\231\166\129\230\173\162\232\167\166\229\143\145\228\187\187\229\138\161")
    return
  end
  if bVisiting and not bVisitOwner and self.Config and not self.Config.peer_available then
    Log.Debug("[TaskFlow] \228\187\187\229\138\161\230\151\160\230\179\149\231\148\177\232\174\191\229\174\162\232\167\166\229\143\145(peer_available == false)")
    return
  end
  if self.Config.task_structure_type == Enum.TaskStructureType.TSTT_CINEMA then
    if self.StatusChecker then
      self.StatusChecker:FireCallback()
    else
      self.Module:TriggerSequences()
    end
  else
    if self.Config.task_structure_type == Enum.TaskStructureType.TSTT_TELEPORT and Area == self.TriggerAcceptActionArea then
      self.Module:MarkAsTeleportingTask(self)
    end
    self:ReportPlayerPosition()
  end
end

function TaskObject:ExitArea(Area, X, Y, Z, PlayerRadius, PlayerHalfHeight)
  Log.DebugFormat("[TaskFlow] \231\166\187\229\188\128\228\187\187\229\138\161\232\167\166\229\143\145\229\140\186\229\159\159,\228\187\187\229\138\161ID:%d,\229\189\147\229\137\141\228\187\187\229\138\161\231\138\182\230\128\129:%s", self.Config.id, TaskUtils.GetStateName(self.Info.state))
end

function TaskObject:CreateTriggerAcceptArea()
  if self.TriggerAcceptActionArea then
    return
  end
  local PosCheckData = self.Config.task_special_structure_area
  if self.Config.task_structure_type ~= Enum.TaskStructureType.TSTT_TELEPORT and self.Config.task_structure_type ~= Enum.TaskStructureType.TSTT_CINEMA then
    return
  end
  if not PosCheckData then
    return
  end
  if #PosCheckData < 4 then
    return
  end
  local SceneID = PosCheckData[1]
  local X = PosCheckData[2] or 0
  local Y = PosCheckData[3] or 0
  local Z = PosCheckData[4] or 0
  local Range = PosCheckData[5]
  if Range then
    Range = Range * 100
  else
    Range = BeginRange
  end
  self.TriggerAcceptActionArea = StaticCircleArea.MakePoint3D(string.format("TaskAccept%d", self.Info.id), SceneID, X, Y, Z, Range, 50, self, self.EnterArea, self.ExitArea)
  self.TriggerAcceptActionArea.bRevokeOnDisconnect = true
  self.TriggerAcceptActionArea:StartDetect()
end

function TaskObject:DestroyTriggerAcceptArea()
  self.StatusChecker = false
  if not self.TriggerAcceptActionArea then
    return
  end
  self.TriggerAcceptActionArea:StopDetect()
  self.TriggerAcceptActionArea = false
end

function TaskObject:CreateTriggerFinishArea()
  if self.TriggerFinishActionArea then
    return
  end
  local PosCheckData, Range
  for Index, Cond in ipairs(self.Config.task_condition) do
    if Cond.type == ProtoEnum.TaskKeyType.TKT_REACH_POINT then
      PosCheckData = Cond.data1
      Range = (Cond.data2[1] or 0) * 100
      break
    end
  end
  if not PosCheckData then
    return
  end
  if #PosCheckData < 4 then
    return
  end
  local SceneID = PosCheckData[1]
  local X = PosCheckData[2] or 0
  local Y = PosCheckData[3] or 0
  local Z = PosCheckData[4] or 0
  Range = Range and 0 ~= Range and Range or EndRange
  self.TriggerFinishActionArea = StaticCircleArea.MakePoint3D(string.format("TaskFinish%d", self.Info.id), SceneID, X, Y, Z, Range, 50, self, self.EnterArea, self.ExitArea)
  self.TriggerFinishActionArea.bRevokeOnDisconnect = true
  self.TriggerFinishActionArea:StartDetect()
end

function TaskObject:DestroyTriggerFinishArea()
  if not self.TriggerFinishActionArea then
    return
  end
  self.TriggerFinishActionArea:StopDetect()
  self.TriggerFinishActionArea = false
end

function TaskObject:OnVisitOwnerChanged()
end

function TaskObject:IsInActionArea()
  if not self.TriggerAcceptActionArea then
    return true
  end
  return self.TriggerAcceptActionArea.bPreviouslyInArea
end

function TaskObject:RevokeActionArea(StatusChecker)
  if self.TriggerAcceptActionArea then
    Log.DebugFormat("[TaskFlow]TaskObject:RevokeActionArea: %d %s", self.Info.id, StatusChecker and StatusChecker.LogPrefix or "\230\151\160StatusChecker")
    if StatusChecker then
      self.StatusChecker = StatusChecker
    end
    self.TriggerAcceptActionArea.bPreviouslyInArea = false
  end
end

function TaskObject:SetPendingAction(Action)
  if self.Action then
    Log.ErrorFormat("[TaskFlow]TaskObject:SetPendingAction: Action already exists!! %s %s", self.Action.ActionGroup, self.Action.name)
    self.Action:Destroy()
  end
  self.Action = Action
end

function TaskObject:HasPendingAction()
  if not self.Action then
    return false
  end
  local ShouldExecute = self.Action:ShouldExecute()
  return ShouldExecute
end

function TaskObject:ExecutePendingAction()
  if not self.Action then
    return false
  end
  self.Action:Execute()
end

function TaskObject:MarkPendingTask()
  if not self.Module then
    Log.ErrorFormat("[TaskFlow]TaskObject:MarkPendingTask: Module not found!! %d", self.Config.id)
    return
  end
  self.Module:MarkPendingTask(self)
end

function TaskObject:ClearPendingTask()
  if not self.Module then
    Log.ErrorFormat("[TaskFlow]TaskObject:ClearPendingTask: Module not found!! %d", self.Config.id)
    return
  end
  self.Module:ClearPendingTask(self)
end

function TaskObject:Destroy()
  self:CleanTimerHandle()
  self:DestroyTriggerAcceptArea()
  self:DestroyTriggerFinishArea()
  if self.Action then
    self.Action:Destroy()
    self.Action = nil
  end
  if self.Trackers then
    for _, t in ipairs(self.Trackers) do
      t:Destroy()
    end
    table.clear(self.Trackers)
  end
  self:RemoveGuide()
  self.Module.ExtraTrackingInfo[self.Info.id] = nil
  self.Module = nil
end

function TaskObject:GetTargetFromDifferentSceneGroup()
  if not self.Trackers then
    return nil
  end
  if 0 == #self.Trackers then
    return nil
  end
  for _, Tracker in ipairs(self.Trackers) do
    if Tracker.Valid and not Tracker.TargetInSameSceneGroup and not Tracker:IsCheckConditionDone(Tracker.go_index) then
      return Tracker
    end
  end
  return nil
end

function TaskObject:HasAnyTargetInDifferentSceneGroup()
  if not self.Trackers then
    return false
  end
  if 0 == #self.Trackers then
    return false
  end
  for _, Tracker in ipairs(self.Trackers) do
    if Tracker.Valid and not Tracker.TargetInSameSceneGroup then
      return true
    end
  end
  return false
end

function TaskObject:ExecuteGoAction()
  local Info = self.Info.task_target_list
  local Conditions = self.Conditions
  if not Conditions or 0 == #Conditions then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.check_task_info)
    return
  end
  local GoGuides = self.Config.go_guide
  if not GoGuides or 0 == #GoGuides then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.check_task_info)
    return
  end
  local Found = false
  local InDifferentSceneGroup = false
  for Index, Condition in ipairs(GoGuides) do
    local InfoCount = Info and Info[Index] or 0
    local Current = InfoCount or 0
    local Cond = Conditions[Index]
    local Count = Cond and Cond.count or 0
    if Current >= Count then
    else
      local Tracker = self:GetTracker(Index)
      if Tracker and not Tracker.TargetInSameSceneGroup then
        InDifferentSceneGroup = true
      end
      Found = self:RunSingleGoAction(Condition, Index)
      break
    end
  end
  if not Found then
    if InDifferentSceneGroup then
      if self:GetTaskClickLimit() then
        return
      end
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, {
        TaskId = self.Config.id,
        IsOpenRightPanel = true
      })
    elseif self.Trackers and #self.Trackers > 0 then
      self:Focus()
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.check_task_info)
    end
  end
  self:GetGuideActor(true)
end

function TaskObject:RunSingleGoAction(GoGuideConf)
  if GoGuideConf.type == ProtoEnum.TaskGoActionType.TGAT_TELE_STRUCTURE then
    _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.SwitchScene, self.Config.id)
    return true
  end
  if string.IsNilOrEmpty(GoGuideConf.text) then
    return false
  end
  if self:GetTaskClickLimit() then
    return false
  end
  local Args, Args2
  if not string.IsNilOrEmpty(GoGuideConf.args) then
    Args = rapidjson.decode(GoGuideConf.args)
    if not Args then
      Args = self:SplitString(GoGuideConf.args, ";")
      if 1 == #Args then
        Args = Args[1]
      end
    end
  end
  if not string.IsNilOrEmpty(GoGuideConf.args2) then
    Args2 = rapidjson.decode(GoGuideConf.args2)
    if not Args2 then
      Args2 = self:SplitString(GoGuideConf.args2, ";")
      if 1 == #Args2 then
        Args2 = Args2[1]
      end
    end
  end
  _G.NRCModuleManager:DoCmdWithArgs(GoGuideConf.text, Args, Args2)
  return true
end

function TaskObject:SplitString(input, delimiter)
  if not input or not delimiter then
    return {}
  end
  local result = {}
  for str in string.gmatch(input, "([^" .. delimiter .. "]+)") do
    table.insert(result, str)
  end
  return result
end

function TaskObject:Focus()
  local Trackers = self.Trackers or {}
  if Trackers then
    for _, Tracker in ipairs(Trackers) do
      Tracker:Focus()
    end
  end
end

function TaskObject:CollectRelativeTasks()
  return TaskUtils.CollectRelativeTasks(self, self.Module.data.TaskMap)
end

function TaskObject:SetParentTrackTask(ParentTask)
  local parentIsTrack = ParentTask and ParentTask:IsTrack() or false
  local isTrack
  if self.ServerIsTrack then
    isTrack = self.isTrack or parentIsTrack
  else
    isTrack = parentIsTrack
  end
  isTrack = isTrack and self:IsOpenOrWait()
  self.isTrack = isTrack
  local TrackIsExist = self.Trackers and #self.Trackers > 0
  self.TrackParentTask = ParentTask
  if TrackIsExist then
    self:UpdateTrackers(self.Info)
  elseif not TrackIsExist then
    self:AddTrackers(self.Info)
  elseif TrackIsExist and not isTrack then
    self:StopTraceTaskItem(self.Info)
  end
  if ParentTask and self.Trackers then
    if not ParentTask.Trackers then
      ParentTask.Trackers = {}
    end
    for _, tracker in ipairs(self.Trackers) do
      local bIsExist = false
      for _, parentTracker in ipairs(ParentTask.Trackers) do
        if parentTracker.TaskConfig.id == tracker.TaskConfig.id and parentTracker.go_index == tracker.go_index then
          bIsExist = true
          break
        end
      end
      if not bIsExist then
        table.insert(ParentTask.Trackers, tracker)
      end
    end
  end
end

function TaskObject:SetSubTrackTasks(SubTasks)
  local New = SubTasks
  local Old = self.TrackSubTasks
  if New and Old then
    local RemoveTasks
    for _, OldTask in ipairs(Old) do
      local FoundInNew
      for _, NewTask in ipairs(New) do
        if NewTask.Info.id == OldTask.Info.id then
          FoundInNew = true
        end
      end
      if not FoundInNew then
        RemoveTasks = RemoveTasks or {}
        table.insert(RemoveTasks, OldTask)
      end
    end
    local AddTasks
    for _, NewTask in ipairs(New) do
      local FoundInOld
      for _, OldTask in ipairs(Old) do
        if NewTask.Info.id == OldTask.Info.id then
          FoundInOld = true
        end
      end
      if not FoundInOld then
        AddTasks = AddTasks or {}
        table.insert(AddTasks, NewTask)
      end
    end
    if RemoveTasks then
      for _, Remove in ipairs(RemoveTasks) do
        Remove:SetParentTrackTask(nil)
      end
    end
    if AddTasks then
      for _, Add in ipairs(AddTasks) do
        Add:SetParentTrackTask(self)
      end
    end
  elseif not New and Old then
    for _, Task in ipairs(Old) do
      Task:SetParentTrackTask(nil)
    end
  else
    if New and not Old then
      for _, Task in ipairs(New) do
        Task:SetParentTrackTask(self)
      end
    else
    end
  end
  self.TrackSubTasks = New
end

function TaskObject:CalcRelativeTasks()
  local RelativeTasks = self:CollectRelativeTasks()
  self:SetSubTrackTasks(RelativeTasks)
end

function TaskObject:TaskTitle()
  return self.Config.name
end

function TaskObject:GetDescText(Index)
  if not self.Conditions or 0 == #self.Conditions then
    return nil
  end
  Index = Index or 1
  local Cond = self.Conditions[Index]
  if not Cond then
    return nil
  end
  return Cond.text
end

function TaskObject:GetGoalDetail(Index)
  Index = Index or 1
  if Index > #self.Conditions then
    Log.Dump(self.Config, 5, "Task Config Error")
    return "???", 0, 0
  end
  local Cond = self.Conditions[Index]
  local need = Cond.count or 0
  local desc = Cond.text
  local targetList = self.Info.task_target_list
  local data = targetList and targetList[Index] or 0
  if need <= data then
    local DoneText = Cond.done_text
    if not string.IsNilOrEmpty(DoneText) then
      desc = DoneText
    end
  end
  if need > 1 then
    desc = string.format("%s(%d/%d)", desc, data, need)
  end
  local GoGuides = self.Config.go_guide
  if GoGuides and Index <= #GoGuides then
    local GoGuide = GoGuides[Index]
    if GoGuide.type == ProtoEnum.TaskGoActionType.TGAT_TRACK_TASK and 2 == GoGuide.data1[1] then
      local CurTracker = self:GetTracker(Index)
      if CurTracker and CurTracker.TaskObject and CurTracker.TaskObject.Config and #CurTracker.TaskObject.Config.task_condition > 0 then
        if 1 == #CurTracker.TaskObject.Config.task_condition then
          desc = CurTracker.TaskObject.Config.task_condition[1].text or ""
        elseif #CurTracker.TaskObject.Trackers > 0 then
          for _, Tracker in ipairs(CurTracker.TaskObject.Trackers) do
            if not Tracker.TaskObject:CheckConditionDone(Tracker.go_index) then
              desc = Tracker.TaskObject.Config.task_condition[Tracker.go_index] and Tracker.TaskObject.Config.task_condition[Tracker.go_index].text or ""
              break
            end
          end
        end
        return desc, data, need
      end
      for i, sub_task_id in ipairs(GoGuide.data2) do
        if self.TrackSubTasks then
          for _, sub_task_obj in ipairs(self.TrackSubTasks) do
            if sub_task_obj.Config.id == sub_task_id and (not sub_task_obj.Info or not (sub_task_obj.Info.done_count >= #sub_task_obj.Info.task_target_list)) then
              desc = sub_task_obj.Config.task_condition[1].text
              goto lbl_215
            end
          end
        end
        if i == #GoGuide.data2 then
          local sub_task_config = _G.DataConfigManager:GetTaskConf(sub_task_id)
          if not string.IsNilOrEmpty(sub_task_config.task_condition[1].done_text) then
            desc = sub_task_config.task_condition[1].done_text
            do break end
            break
          end
          if not string.IsNilOrEmpty(sub_task_config.task_condition[1].text) then
            desc = sub_task_config.task_condition[1].text
            break
          end
          break
        end
      end
    end
  end
  ::lbl_215::
  return desc, data, need
end

function TaskObject:GetCountdownText()
  return ""
end

function TaskObject:GetCountdown()
  return -1
end

function TaskObject:MarkTrackersSynced()
  if self.Trackers then
    for _, Tracker in ipairs(self.Trackers) do
      Tracker:MarkSynced()
    end
  end
  if self.TrackSubTasks then
    for _, Task in ipairs(self.TrackSubTasks) do
      Task:MarkTrackersSynced()
    end
  end
end

function TaskObject:IsNewTask()
  return self.Info.new_task and self.isNew
end

function TaskObject:ConsumeNewTask()
  self.isNew = false
  self.Info.new_task = false
  local Req = _G.ProtoMessage:newZoneTaskReadedReq()
  Req.task_id = self.Info.id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_READED_REQ, Req, self, self.OnTaskReaded, false, false)
end

function TaskObject:OnTaskReaded(Rsp)
end

function TaskObject:IsFinish()
  local State = self.Info.state
  return State == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE or State == ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSED
end

function TaskObject:ShouldHaveTrackers()
  for _, go in ipairs(self.Config.go_guide) do
    local HasClass = TrackClass[go.type]
    if HasClass then
      return true
    end
  end
  return false
end

function TaskObject:HasTrackInfo()
  if not self.Trackers then
    return false
  end
  if 0 == #self.Trackers then
    return false
  end
  for _, Tracker in ipairs(self.Trackers) do
    if not Tracker.Valid then
      return false
    end
  end
  return true
end

function TaskObject:OnTrackUpdate(_)
  if not self.Trackers then
    return
  end
  if 0 == #self.Trackers then
    return
  end
  local SceneGroupFlag = self:HasAnyTargetInDifferentSceneGroup()
  if self.LastSceneGroupFlag == nil or self.LastSceneGroupFlag ~= SceneGroupFlag then
    self.LastSceneGroupFlag = SceneGroupFlag
    self:SendEvent(TaskModuleEvent.ON_SCENE_GROUP_CHANGED, self)
  end
  for _, Tracker in ipairs(self.Trackers) do
    if not Tracker.Valid and Tracker.SpecialType == "TreasureDig" then
      self:SendEvent(TaskModuleEvent.ON_UPDATE_TRACK, self)
      return
    end
  end
  self:SendEvent(TaskModuleEvent.ON_UPDATE_TRACK, self)
  if self.TrackParentTask then
    if self.TrackParentTask.Trackers then
      for _, Tracker in ipairs(self.TrackParentTask.Trackers) do
        if not Tracker.Valid then
          return
        end
      end
    end
    self.TrackParentTask:SendEvent(TaskModuleEvent.ON_UPDATE_TRACK, self.TrackParentTask)
  end
end

function TaskObject.SetShouldSkipSendRequest(Skip)
  SkipSendingRequest = Skip
end

function TaskObject.GetShouldSkipSendRequest()
  return SkipSendingRequest
end

function TaskObject:GetTaskClickLimit()
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
  if isSelectBtn then
    return true
  end
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return true
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, true)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  return false
end

function TaskObject:TryRemoveCompletedGuide(taskId)
  if not self.SplineGuideActor then
    return
  end
  if not self.SplineGuideActor.Guide then
    Log.Warning("HasGuideActor but Guide is invalid!")
    return
  end
  if self.SplineGuideActor.Guide.id == taskId then
    self:RemoveGuide(true, false)
  end
end

function TaskObject:IsOldEnough(MinAge)
  if not self.CreateTime then
    return false
  end
  local Now = os.msTime()
  return MinAge <= Now - self.CreateTime
end

function TaskObject:IsTrack()
  return self.isTrack or self.TrackParentTask and self.TrackParentTask.isTrack or false
end

function TaskObject:GetTrackerPosBySceneID(SceneID)
  local TrackerPos = {}
  if not self.Trackers then
    return TrackerPos
  end
  for _, Tracker in pairs(self.Trackers) do
    local Pos = Tracker:GetPosBySceneID(SceneID)
    if Pos then
      table.insert(TrackerPos, Pos)
    end
  end
  return TrackerPos
end

function TaskObject:GetTrackerPos()
  local TrackerPos = {}
  if not self.Trackers then
    return TrackerPos
  end
  for _, Tracker in ipairs(self.Trackers) do
    local Position = Tracker:GetTargetPosition()
    if Position then
      table.insert(TrackerPos, Position)
    end
  end
  return TrackerPos
end

function TaskObject:GetExtraTrackingInfo()
  local Module = self.Module
  if not Module then
    return nil
  end
  if not self:IsOpenOrWait() then
    return nil
  end
  local TrackingItems = Module:GetTaskNPCInfo(self.Info.id)
  return TrackingItems and TrackingItems.guide_list or nil
end

function TaskObject:CleanTimerHandle()
  if self.RefreshEnterHandleID then
    _G.DelayManager:CancelDelayById(self.RefreshEnterHandleID)
    self.RefreshEnterHandleID = nil
  end
end

return TaskObject

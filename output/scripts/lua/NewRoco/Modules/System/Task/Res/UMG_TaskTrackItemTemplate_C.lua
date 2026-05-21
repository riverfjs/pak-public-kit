local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local DisplayTaskObject = require("NewRoco.Modules.Core.Task.DisplayTaskObject")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local Base = _G.NRCViewBase
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local DisplayTaskTypeEnum = require("NewRoco.Modules.Core.Task.DisplayTaskTypeEnum")
local UMG_TaskTrackItemTemplate_C = Base:Extend("UMG_TaskTrackItemTemplate_C")

function UMG_TaskTrackItemTemplate_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  local WidthWidget = self.TaskDetail
  if WidthWidget and UE.UObject.IsValid(WidthWidget) then
    local Visibility = WidthWidget:GetVisibility()
    if Visibility == UE.ESlateVisibility.Collapsed then
      WidthWidget = self.Targets:GetChildAt(0)
      WidthWidget = WidthWidget and WidthWidget.MainStyle
    end
    WidthWidget:ForceLayoutPrepass()
    local Geometry = WidthWidget:GetPaintSpaceGeometry()
    local PCModeOffset = UE4Helper.IsPCMode() and 0 or 20
    self.RenderSize = UE4.USlateBlueprintLibrary.GetLocalSize(Geometry)
    self.RenderSize.X = -self.RenderSize.X + PCModeOffset
    if WidthWidget == self.TaskDetail then
      self.RenderSize.Y = 40
    else
      self.RenderSize.Y = 30
    end
    self.Progress.Slot:SetPosition(self.RenderSize)
  else
    self.Progress.Slot:SetPosition(UE.FVector2D(-260, 40))
  end
  self.IsOnClick = true
  self.NeedTick = true
  Log.Debug("UMG_TaskTrackItemTemplate_C:OnTouchStarted")
  return self.Overridden.OnTouchStarted(self, MyGeometry, InTouchEvent)
end

function UMG_TaskTrackItemTemplate_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if MiniGameModuleCmd and self:IsInMiniGamePerform() then
    return
  end
  local longPressCheck = self.IsLongPress or not self.NeedTick
  if self.data and not self:ShouldRemove() and not self:ShouldShow() and not longPressCheck then
    if self.data:InstanceOf(DisplayTaskObject) then
      self.data:ExecuteGoAction()
    elseif self.data.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      if 0 ~= self.data.Config.auto_finish then
        Log.Warning("\232\135\170\229\138\168\231\187\147\231\174\151\231\154\132\228\187\187\229\138\161\231\142\169\229\174\182\231\130\185\231\154\132\229\190\136\229\191\171\229\143\175\232\131\189\232\131\189\231\156\139\232\167\129\232\191\153\228\184\170warning")
      else
        _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.TaskRewardReq, self.data.Config.id)
      end
    else
      self.data:ExecuteGoAction()
    end
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TaskTrackItemTemplate_C:OnTouchEnded")
  end
  self.NeedTick = false
  self:LongPressBreak()
  Log.Debug("UMG_TaskTrackItemTemplate_C:OnTouchStarted2")
  return self.Overridden.OnTouchEnded(self, MyGeometry, InTouchEvent)
end

function UMG_TaskTrackItemTemplate_C:OnMouseLeave(MyGeometry, MouseEvent)
  self:LongPressBreak()
  Log.Debug("UMG_TaskTrackItemTemplate_C:OnTouchStarted1")
end

function UMG_TaskTrackItemTemplate_C:OnTick(InDeltaTime)
  if not self.data then
    return
  end
  if 0 == self.data.ID then
    return
  end
  local CurTrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetDataTrackTask)
  if self.CurrentTraceCountdown > 0 then
    if CurTrackTask and self.CurTrackTaskID ~= CurTrackTask.Info.id then
      self.Trace:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.CurrentTraceCountdown = 0
      self.data:ConsumeNewTask()
      self:FireCountdownCallback()
    elseif self.data:GetCountdown() <= 0 then
      self.Trace:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.CurrentTraceCountdown = 0
      self.data:ConsumeNewTask()
      self:FireCountdownCallback()
    else
      self.CurrentTraceCountdown = math.max(self.CurrentTraceCountdown - InDeltaTime, 0)
      local RemainTime = math.ceil(self.CurrentTraceCountdown)
      self.Text_Time:SetText(string.format(self.data:GetCountdownText(), RemainTime))
      if 0 == RemainTime then
        self.data:ConsumeNewTask()
        self:FireCountdownCallback()
      end
    end
  end
  if CurTrackTask and self.CurTrackTaskID ~= CurTrackTask.Info.id then
    self.CurTrackTaskID = CurTrackTask.Info.id
  end
  if self.IsOnClick then
    self.StartPressTime = self.StartPressTime + InDeltaTime
  end
  if self.StartPressTime >= self.LongPressTime then
    self.IsLongPress = true
    self.StartPressTime = 0
  end
  if self.IsLongPress then
    if self.IsOnClick then
      _G.NRCAudioManager:PlaySound2DAuto(1377, "UMG_EquipItem_C:Tick")
      self.IsOnClick = false
    end
    self.StartTime = self.StartTime + InDeltaTime
    local isCompassAppear = _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
    if isCompassAppear then
      self.Progress:showAni(self.ScreenPos, self.StartTime, self.EndTime)
      if self.StartTime >= self.EndTime then
        self:LongPressBreak()
        local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TASK, true)
        if isBan then
          return
        end
        local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
        if isSelectBtn then
          return
        end
        local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
        if isLockOpen then
          return
        end
        local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        if player then
          if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\230\138\149\230\142\183\231\158\132\229\135\134\228\184\173\239\188\140\230\151\160\230\179\149\232\191\155\232\161\140\232\175\165\230\147\141\228\189\156\227\128\130")
            return
          elseif player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\230\138\149\230\142\183\231\158\132\229\135\134\228\184\173\239\188\140\230\151\160\230\179\149\232\191\155\232\161\140\232\175\165\230\147\141\228\189\156\227\128\130")
            return
          end
        end
        if MiniGameModuleCmd and self:IsInMiniGamePerform() then
          return
        end
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
        local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
        _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
        _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.OpenTaskPanel)
      end
    end
  end
end

function UMG_TaskTrackItemTemplate_C:IsInMiniGamePerform()
  local status = _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.GetState)
  local miniGameStage = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.GetMiniGameStage)
  if "Perform" == miniGameStage or status == ProtoEnum.MinigameStatus.MS_FINISH then
    return true
  end
  return false
end

function UMG_TaskTrackItemTemplate_C:LongPressBreak()
  self.NeedTick = false
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.Progress:showEndAni()
end

function UMG_TaskTrackItemTemplate_C:FireCountdownCallback()
  local Callback = self.CountdownCallback
  local Caller = self.CountdownCaller
  self.CountdownCaller = nil
  self.CountdownCallback = nil
  self.ExpectingAnim = nil
  if Callback then
    Callback(Caller)
  end
end

function UMG_TaskTrackItemTemplate_C:ShouldShow()
  if not self.data then
    return false
  end
  return self.data.ShouldShow
end

function UMG_TaskTrackItemTemplate_C:ShouldRemove()
  if not self.data then
    return false
  end
  return self.data.ShouldRemove
end

function UMG_TaskTrackItemTemplate_C:ConsumeShow(owner, callback)
  if self.data then
    Log.Debug("UMG_TaskTrackItemTemplate_C:ConsumeShow", self.data.Info and self.data.Info.id or "\230\178\161\230\156\137\228\187\187\229\138\161ID")
  end
  self.CallbackOwner = owner
  self.Callback = callback
  self.ExpectingAnim = self.NewTask
  self:SetupContent()
  self:StopAllAnimations()
  self:PlayAnimation(self.NewTask)
  self:PlayTargetShow()
  _G.NRCAudioManager:PlaySound2DAuto(1041, "UMG_TaskTrackItemTemplate_C:SetData")
end

function UMG_TaskTrackItemTemplate_C:ConsumeRemove(owner, callback)
  if not self.data then
    if callback then
      callback(owner)
    end
    return
  end
  Log.Debug("UMG_TaskTrackItemTemplate_C:ConsumeRemove", self.data.Info and self.data.Info.id or "\230\178\161\230\156\137\228\187\187\229\138\161ID")
  self.CallbackOwner = owner
  self.Callback = callback
  self.ExpectingAnim = self.Taskcomplete
  self:SetupContent()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self:StopAllAnimations()
  self:PlayAnimation(self.Taskcomplete)
  self:PlayTargetRemove()
  _G.NRCAudioManager:PlaySound2DAuto(1040, "UMG_TaskTrackItemTemplate_C:SetData")
end

function UMG_TaskTrackItemTemplate_C:SetupWidgetByIndex(Index, Style)
  local Widget = self:GetItem(Index - 1)
  if not Widget then
    return
  end
  Widget._index = Index
  if Widget.SetData then
    Widget:SetData(self.data, Style)
  else
    Log.Error("Widget\230\178\161\230\156\137SetData\230\150\185\230\179\149!!", UE.UObject.GetName(Widget))
  end
  Widget:SetVisibility(UE4.ESlateVisibility.Visible)
  if self:ShouldShow() then
    Widget.HBOX:SetRenderOpacity(0)
  else
    Widget.HBOX:SetRenderOpacity(1.0)
  end
end

function UMG_TaskTrackItemTemplate_C:ShowTargetList()
  for _, Widget in wpairs(self.Targets) do
    Widget:OnDespawn()
    Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.data:InstanceOf(DisplayTaskObject) then
    self:SetupWidgetByIndex(1, 1)
    return
  end
  local TaskList = self.data.Info.task_target_list
  local GoalCount = TaskList and #TaskList or 0
  if 0 == GoalCount then
    return
  end
  local InDifferentSceneGroup = self.data:HasAnyTargetInDifferentSceneGroup()
  local TargetFromDifferentSceneGroup = InDifferentSceneGroup and self.data:GetTargetFromDifferentSceneGroup() or false
  if TargetFromDifferentSceneGroup then
    if 1 == GoalCount then
      self:SetupWidgetByIndex(1, 1)
      return
    end
    self:SetupWidgetByIndex(TargetFromDifferentSceneGroup.go_index, 3)
    return
  end
  for i, _ in ipairs(TaskList) do
    if i > 3 then
    else
      self:SetupWidgetByIndex(i, 1 == GoalCount and 1 or 2)
    end
  end
end

function UMG_TaskTrackItemTemplate_C:OnSceneGroupChanged(Task)
  if self.data ~= Task then
    return
  end
  self:SetupContent()
end

function UMG_TaskTrackItemTemplate_C:SetupPCKey()
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  self:ShowPCKey()
end

function UMG_TaskTrackItemTemplate_C:PlayTargetShow()
  for _, Widget in wpairs(self.Targets) do
    Widget:PlayAnimation(Widget.NewTask)
  end
end

function UMG_TaskTrackItemTemplate_C:ShowPCKey()
  local Widget = self.Targets:GetChildAt(self.Targets:GetChildrenCount() - 1)
  if not Widget then
    return
  end
  local Info = self.data and self.data.Info
  local TaskList = Info and Info.task_target_list
  local GoalCount = TaskList and #TaskList or 0
  if GoalCount > 0 then
    Widget:ShowPCKey()
  elseif Widget.PCKey then
    if Widget._data and Widget._data:InstanceOf(DisplayTaskObject) and Widget._data.Type == DisplayTaskTypeEnum.NEW_TASK then
      Widget:ShowPCKey()
    else
      Widget.PCKey:SetKeyVisibility(false)
    end
  end
end

function UMG_TaskTrackItemTemplate_C:PlayTargetRemove()
  if self.data.isTrack then
    return
  end
  for _, Widget in wpairs(self.Targets) do
    Widget:PlayAnimation(Widget.Taskcomplete)
  end
end

function UMG_TaskTrackItemTemplate_C:GetItem(Index)
  local Count = self.Targets:GetChildrenCount()
  if Index < Count then
    return self.Targets:GetChildAt(Index)
  else
    local Klass = UE4.UClass.Load("WidgetBlueprint'/Game/NewRoco/Modules/System/Task/Res/UMG_TaskTrackGoalItem.UMG_TaskTrackGoalItem_C'")
    if not Klass then
      return
    end
    local Widget = UE4.UWidgetBlueprintLibrary.Create(self, Klass)
    self.Targets:AddChild(Widget)
    return Widget
  end
end

function UMG_TaskTrackItemTemplate_C:OnAnimationFinished(Animation)
  Log.Debug("Animation Finished", self.data and self.data.Info and self.data.Info.id or "\230\178\161\230\156\137\228\187\187\229\138\161ID")
  if Animation ~= self.ExpectingAnim then
    Log.Error("We have serious problem", self.ExpectingAnim and self.ExpectingAnim:GetName() or "No Expecting Animation", Animation and Animation:GetName() or "No Finish Animation")
    return
  end
  if Animation == self.Taskcomplete then
    self:MarkRemoved()
  elseif Animation == self.NewTask then
    self:MarkShown()
  end
end

function UMG_TaskTrackItemTemplate_C:MarkRemoved()
  if self.data then
    Log.Debug("UMG_TaskTrackItemTemplate_C:MarkRemoved", self.data.Info and self.data.Info.id or "\230\178\161\230\156\137\228\187\187\229\138\161ID")
  end
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.data:ConsumeRemove()
  self:FireCallback()
end

function UMG_TaskTrackItemTemplate_C:MarkShown()
  if self.data then
    Log.Debug("UMG_TaskTrackItemTemplate_C:MarkShown", self.data.Info and self.data.Info.id or "\230\178\161\230\156\137\228\187\187\229\138\161ID")
  end
  if self.data then
    _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.UpdateTaskTips)
    self.data:ConsumeShow()
  else
    Log.Error("\232\175\165\230\152\190\231\164\186\228\187\187\229\138\161\231\154\132\230\151\182\229\128\153\239\188\140\228\187\187\229\138\161\230\149\176\230\141\174\229\183\178\231\187\143\228\184\162\229\164\177\239\188\140\232\175\183\230\138\138\229\164\141\231\142\176\230\150\185\229\188\143\229\145\138\232\175\137poanshen")
  end
  self:FireCallback()
end

function UMG_TaskTrackItemTemplate_C:SkipShowAnimation()
  self:StopAllAnimations()
  local TotalTime = self.NewTask:GetEndTime()
  self:PlayAnimationTimeRange(self.NewTask, TotalTime - 0.01, TotalTime, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  for _, Widget in wpairs(self.Targets) do
    Widget:SkipShowAnimation()
  end
end

function UMG_TaskTrackItemTemplate_C:SkipRemoveAnimation()
  self:StopAllAnimations()
  local TotalTime = self.Taskcomplete:GetEndTime()
  self:PlayAnimationTimeRange(self.Taskcomplete, TotalTime - 0.01, TotalTime, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  for _, Widget in wpairs(self.Targets) do
    Widget:SkipRemoveAnimation()
  end
end

function UMG_TaskTrackItemTemplate_C:ConsumeDisplayState()
  if self:ShouldShow() then
    self:SkipShowAnimation()
  elseif self:ShouldRemove() then
    self:SkipRemoveAnimation()
  end
end

function UMG_TaskTrackItemTemplate_C:SetupContent()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  local taskInfo = self.data
  if nil == taskInfo then
    Log.Error("\228\187\187\229\138\161\230\160\143\230\159\165\232\175\162\228\184\141\229\136\176\229\144\136\231\144\134\231\154\132\228\187\187\229\138\161\230\149\176\230\141\174\239\188\140\232\175\183\230\138\138\229\164\141\231\142\176\230\150\185\229\188\143\229\145\138\232\175\137poanshen")
    return
  end
  local Info = self.data and self.data.Info
  local TaskList = Info and Info.task_target_list
  local GoalCount = TaskList and #TaskList or 0
  local InDifferentSceneGroup = self.data:HasAnyTargetInDifferentSceneGroup()
  local TargetFromDifferentSceneGroup = InDifferentSceneGroup and self.data:GetTargetFromDifferentSceneGroup() or false
  if GoalCount > 1 and not TargetFromDifferentSceneGroup then
    local Finished = taskInfo:IsFinish()
    if Finished then
      self.TxtTaskDesc:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.TxtTargetDesc_Finish:SetVisibility(UE.ESlateVisibility.Visible)
      self.TxtTargetDesc_Finish:SetText(taskInfo:TaskTitle())
      self:ShowPCKeySelf(false)
      if _G.RocoEnv.IS_EDITOR then
        self.TaskID:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    else
      self.TxtTargetDesc_Finish:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.TxtTaskDesc:SetVisibility(UE.ESlateVisibility.Visible)
      self.TxtTaskDesc:SetText(taskInfo:TaskTitle())
      self:ShowPCKeySelf(true)
      if _G.RocoEnv.IS_EDITOR and _G.GlobalConfig.bIsEditorShowTaskID and taskInfo.Info then
        self.TaskID:SetVisibility(UE.ESlateVisibility.Visible)
        local ShowTaskID = string.format("%s%s", "\228\187\187\229\138\161ID:", taskInfo.Info.id)
        self.TaskID:SetText(ShowTaskID)
      else
        self.TaskID:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    TaskUtils.SetupGoalStateIcon(taskInfo.Info, Finished, self.StateIcon)
    self.TaskDetail:SetVisibility(UE.ESlateVisibility.Visible)
    self.MapTips:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.TaskDetail:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.MapTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    if _G.RocoEnv.IS_EDITOR then
      self.TaskID:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
  if self:ShouldShow() then
    self.HBOX:SetRenderOpacity(0)
  else
    self.HBOX:SetRenderOpacity(1.0)
  end
  self:ShowTargetList()
  self:SetupPCKey()
end

function UMG_TaskTrackItemTemplate_C:SetData(data)
  self:ClearListener()
  self.data = data
  self:AddListener()
  self:SetTask(data)
  if not data then
    Log.Warning("set task data to nil")
    return
  end
  if data.isTrack then
    self.Trace:SetVisibility(UE.ESlateVisibility.Collapsed)
  elseif data.ShouldRemove then
    self.Trace:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    local Text = self.data:GetCountdownText()
    if string.IsNilOrEmpty(Text) then
      self.Trace:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      local Countdown = self.data:GetCountdown()
      if Countdown > 0 then
        self.Text_Time:SetText(string.format(self.data:GetCountdownText(), self.data:GetCountdown()))
      else
        self.Text_Time:SetText(Text)
      end
      self.Trace:SetVisibility(UE.ESlateVisibility.Visible)
    end
  end
end

function UMG_TaskTrackItemTemplate_C:StartTraceCountdown(Time, Callback, Caller)
  self.CurrentTraceCountdown = Time or -1
  self.CountdownCallback = Callback
  self.CountdownCaller = Caller
  if self.data then
    self.data:ConsumeShow()
  end
end

function UMG_TaskTrackItemTemplate_C:SetTask(taskInfo)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  if not taskInfo then
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    return
  end
  taskInfo:MarkTrackersSynced()
  local CanDisplay = taskInfo:ShouldDisplay()
  if CanDisplay then
    if taskInfo.ShouldShow then
      self:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self:SetupContent()
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskTrackItemTemplate_C:OnTaskUpdate(task)
  self:SetTask(task)
end

function UMG_TaskTrackItemTemplate_C:FireCallback()
  local Owner = self.CallbackOwner
  local Func = self.Callback
  self.CallbackOwner = nil
  self.Callback = nil
  if not Func then
    return
  end
  Func(Owner)
end

function UMG_TaskTrackItemTemplate_C:AddListener()
  if not self.data then
    return
  end
  self.data:AddEventListener(self, TaskModuleEvent.ON_SCENE_GROUP_CHANGED, self.OnSceneGroupChanged)
end

function UMG_TaskTrackItemTemplate_C:ClearListener()
  if not self.data then
    return
  end
  self.data:RemoveEventListener(self, TaskModuleEvent.ON_SCENE_GROUP_CHANGED, self.OnSceneGroupChanged)
end

function UMG_TaskTrackItemTemplate_C:OnConstruct()
  self.NeedTick = false
  self.data = nil
  self.CachedTrackState = true
  self.vector2DZero = UE4.FVector2D(0, 0)
  self.Deviation = {X = 60, Y = 40}
  self.screenPos = nil
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 1000
  self.EndTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn").num / 1000
  self.CurrentTraceCountdown = -1
  _G.NRCEventCenter:RegisterEvent(self.name, self, EnhancedInputModuleEvent.KeyMappingsChanged, self.ShowPCKey)
end

function UMG_TaskTrackItemTemplate_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.ShowPCKey)
  Log.Debug("UMG_TaskTrackItemTemplate_C:Destruct", UE.UObject.GetName(self))
  self:ClearListener()
  self:FireCallback()
  self.data = nil
  self.Callback = nil
  self.CallbackOwner = nil
end

function UMG_TaskTrackItemTemplate_C:ShowPCKeySelf(bIsShow)
  if bIsShow then
    if SystemSettingModuleCmd and self.PCKey then
      self.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_TaskDetailsStart")
      if "" ~= image then
        self.PCKey:SetImageMode(image)
      else
        self.PCKey:SetText(text)
      end
    end
  else
    self.PCKey:SetKeyVisibility(false)
  end
end

return UMG_TaskTrackItemTemplate_C

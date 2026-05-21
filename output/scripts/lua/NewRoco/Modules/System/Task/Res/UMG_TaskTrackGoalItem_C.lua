local DisplayTaskObject = require("NewRoco.Modules.Core.Task.DisplayTaskObject")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local DisplayTaskTypeEnum = require("NewRoco.Modules.Core.Task.DisplayTaskTypeEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local Base = require("NewRoco.TUI.BP_ScrollViewItemBase_C")
local GoalStyle = {
  Main = 1,
  Sub = 2,
  Other = 3
}
local UMG_TaskTrackGoalItem_C = Base:Extend("UMG_TaskTrackGoalItem_C")
local ArrowUpDir = UE4.FVector2D(1, 1)
local ArrowDownDir = UE4.FVector2D(1, -1)

function UMG_TaskTrackGoalItem_C:Construct()
  Base.Construct(self)
  self.Style = GoalStyle.Main
  _G.NRCEventCenter:RegisterEvent("UMG_TaskTrackGoalItem_C", self, FriendModuleEvent.QuickChatOpen, self.OnQuickChatOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_TaskTrackGoalItem_C", self, FriendModuleEvent.QuickChatClose, self.OnQuickChatClose)
end

function UMG_TaskTrackGoalItem_C:Destruct()
  self.currentTxtDesc = nil
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.QuickChatOpen, self.OnQuickChatOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.QuickChatClose, self.OnQuickChatClose)
end

function UMG_TaskTrackGoalItem_C:ToggleFinish(taskInfo, finish)
  if finish then
    self.TxtTargetDesc_Normal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TxtTargetDesc_Finish:SetVisibility(UE4.ESlateVisibility.Visible)
    self.currentTxtDesc = self.TxtTargetDesc_Finish
    if _G.RocoEnv.IS_EDITOR then
      self.TaskID:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TxtTargetDesc_Normal:SetVisibility(UE4.ESlateVisibility.Visible)
    self.TxtTargetDesc_Finish:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.currentTxtDesc = self.TxtTargetDesc_Normal
    if _G.RocoEnv.IS_EDITOR and _G.GlobalConfig.bIsEditorShowTaskID then
      self.TaskID:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
  TaskUtils.SetupGoalStateIcon(taskInfo, finish, self.StateIcon)
end

function UMG_TaskTrackGoalItem_C:FinishTask(taskInfo)
  self:ToggleFinish(taskInfo, true)
  self.currentTxtDesc = self.TxtTargetDesc_Finish
end

function UMG_TaskTrackGoalItem_C:SetData(data, Style)
  self:UnregisterTracker()
  Base.SetData(self, data)
  if data:InstanceOf(DisplayTaskObject) then
    self:SetDisplayTask(data)
  else
    self:SetTask(data, Style)
    self:RegisterTracker()
    self:UpdateTrackerInfo()
  end
end

function UMG_TaskTrackGoalItem_C:ShowPCKey()
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  if SystemSettingModuleCmd and self.PCKey then
    self.PCKey:SetKeyVisibility(true)
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_TaskDetailsStart")
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
  end
end

function UMG_TaskTrackGoalItem_C:GetTracker(bCheckValid)
  local Data = self._data
  if not Data then
    return nil
  end
  local Tracker = Data:GetTracker(self._index, bCheckValid)
  if Tracker then
    return Tracker
  end
  return Tracker
end

function UMG_TaskTrackGoalItem_C:RegisterTracker()
  local Tracker = self:GetTracker()
  if not Tracker then
    local Data = self._data
    if not Data then
      return
    end
    Data:AddEventListener(self, TaskModuleEvent.ON_START_TRACK, self.OnTrackerReady)
    return
  end
  Tracker:AddEventListener(self, TaskModuleEvent.ON_UPDATE_TRACK, self.UpdateTrackerInfo)
  Tracker:AddEventListener(self, TaskModuleEvent.ON_TRACK_DISTANCE_CHANGE, self.UpdateTrackerInfo)
  self.OldTracker = Tracker
end

function UMG_TaskTrackGoalItem_C:UnregisterTracker()
  local Data = self._data
  if Data then
    Data:RemoveEventListener(self, TaskModuleEvent.ON_START_TRACK, self.OnTrackerReady)
  end
  local Tracker = self.OldTracker
  if not Tracker then
    return
  end
  Tracker:RemoveEventListener(self, TaskModuleEvent.ON_UPDATE_TRACK, self.UpdateTrackerInfo)
  Tracker:RemoveEventListener(self, TaskModuleEvent.ON_TRACK_DISTANCE_CHANGE, self.UpdateTrackerInfo)
  self.OldTracker = nil
end

function UMG_TaskTrackGoalItem_C:OnTrackerReady()
  if not UE.UObject.IsValid(self) then
    return
  end
  if not UE.UObject.IsValid(self.MapTips) then
    return
  end
  local Data = self._data
  if Data then
    Data:RemoveEventListener(self, TaskModuleEvent.ON_START_TRACK, self.OnTrackerReady)
  end
  self:RegisterTracker()
  self:UpdateTrackerInfo()
end

function UMG_TaskTrackGoalItem_C:UpdateTrackerInfo()
  if not UE.UObject.IsValid(self) then
    return
  end
  if not UE.UObject.IsValid(self.MapTips) then
    return
  end
  self:UpdateMapTips()
end

function UMG_TaskTrackGoalItem_C:SetTask(task, Style)
  self.Style = Style
  self.VisitText:SetVisibility(UE.ESlateVisibility.Collapsed)
  if GoalStyle.Main == Style then
    self.MainStyle:SetVisibility(UE.ESlateVisibility.Visible)
    self.SubStyle:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Envelope:SetVisibility(UE.ESlateVisibility.Collapsed)
    local desc, now, need = self:GetGoalDetail(task, self._index)
    local taskInfo = task.Info
    self:ToggleFinish(taskInfo, false)
    if need <= now then
      self:FinishTask(taskInfo)
    end
    local TaskConfig = _G.DataConfigManager:GetTaskConf(task.Info.id)
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() and task.Config and task.Config.peer_available then
      local ShowText = string.format("%s%s", LuaText.TASK_VISITER_TRACK_BAR, desc)
      desc = ShowText
    end
    if self.currentTxtDesc then
      self.currentTxtDesc:SetText(desc)
    end
    if _G.RocoEnv.IS_EDITOR and _G.GlobalConfig.bIsEditorShowTaskID and taskInfo then
      local ShowTaskID = string.format("%s%s", "\228\187\187\229\138\161ID:", taskInfo.id)
      self.TaskID:SetText(ShowTaskID)
    else
      self.TaskID:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif GoalStyle.Sub == Style then
    self.MainStyle:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SubStyle:SetVisibility(UE.ESlateVisibility.Visible)
    local desc, now, need = self:GetSubGoalDetail(task, self._index)
    self.GoalText:SetText(desc)
    self.GoalText:SetVisibility(UE.ESlateVisibility.Visible)
    self.PosTips:SetVisibility(UE.ESlateVisibility.Visible)
    self.PosTips:SetText("")
    TaskUtils.SetupGoalStateIconSub(task.Info, need <= now, self.CheckIcon)
  else
    self.MainStyle:SetVisibility(UE.ESlateVisibility.Visible)
    self.SubStyle:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Envelope:SetVisibility(UE.ESlateVisibility.Collapsed)
    local _, now, need = self:GetGoalDetail(task, self._index)
    local taskInfo = task.Info
    self:ToggleFinish(taskInfo, false)
    if need <= now then
      self:FinishTask(taskInfo)
    end
    local desc = task:TaskTitle()
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() and task.Config and task.Config.peer_available then
      local ShowText = string.format("%s%s", LuaText.TASK_VISITER_TRACK_BAR, desc)
      desc = ShowText
    end
    if self.currentTxtDesc then
      self.currentTxtDesc:SetText(desc)
    end
    if _G.RocoEnv.IS_EDITOR and _G.GlobalConfig.bIsEditorShowTaskID and taskInfo then
      local ShowTaskID = string.format("%s%s", "\228\187\187\229\138\161ID:", taskInfo.id)
      self.TaskID:SetText(ShowTaskID)
    else
      self.TaskID:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TaskTrackGoalItem_C:UpdateMapTips()
  local Tracker = self:GetTracker(true)
  if GoalStyle.Main == self.Style or GoalStyle.Other == self.Style then
    local Data = self._data
    local Text
    if Tracker then
      if Tracker:HasDisplayText() then
        Text = Tracker:GetDisplayText()
      end
      if Tracker.DirectionSign == "" then
        self.Arrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
      elseif Tracker.DirectionSign == "\226\150\178" then
        self.Arrow:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Arrow:SetRenderScale(ArrowUpDir)
      elseif Tracker.DirectionSign == "\226\150\188" then
        self.Arrow:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Arrow:SetRenderScale(ArrowDownDir)
      end
    elseif Data then
      local Index = self._index
      local GoGuide = Data.Config.go_guide[Index]
      if GoGuide and GoGuide.type ~= Enum.TaskGoActionType.TGAT_NPC_CIRCLE then
        Text = GoGuide.show_text
      end
    end
    self.MapTips:SetText(Text)
    if string.IsNilOrEmpty(Text) then
      self.MapTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      self.MapTips:SetVisibility(UE.ESlateVisibility.Visible)
    end
  elseif Tracker then
    self.PosTips:SetText(Tracker:GetDistanceText())
  else
    self.PosTips:SetText("")
  end
end

function UMG_TaskTrackGoalItem_C:SetDisplayTask(Task)
  if Task and Task:IsNewTask() and Task.Config and Task.Config.message_id > 0 then
    self.Envelope:SetVisibility(UE.ESlateVisibility.Visible)
  else
    self.Envelope:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.TxtTargetDesc_Normal:SetVisibility(UE4.ESlateVisibility.Visible)
  self.TxtTargetDesc_Finish:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.VisitText:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.currentTxtDesc = self.TxtTargetDesc_Normal
  if self.currentTxtDesc then
    local Desc = Task:GetMainText()
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      if Task.Config and Task.Config.peer_available then
        local ShowText = string.format("%s%s", LuaText.TASK_VISITER_TRACK_BAR, Task:GetMainText())
        Desc = ShowText
      end
      if not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() and Task.Type == DisplayTaskTypeEnum.NO_TRACKING_TASK then
        self.VisitText:SetVisibility(UE.ESlateVisibility.Visible)
        local Text = _G.DataConfigManager:GetLocalizationConf("task_tracking_visit_hyperlink").msg
        self.VisitText:SetText(Text)
      end
    end
    self.currentTxtDesc:SetText(Desc)
  end
  if _G.RocoEnv.IS_EDITOR and _G.GlobalConfig.bIsEditorShowTaskID and Task then
    local ShowTaskID = string.format("%s%s", "\228\187\187\229\138\161ID:", Task.ID)
    self.TaskID:SetText(ShowTaskID)
  else
    self.TaskID:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskTrackGoalItem_C:GetGoalDetail(taskInfo, index)
  return taskInfo:GetGoalDetail(index)
end

function UMG_TaskTrackGoalItem_C:GetSubGoalDetail(taskInfo, index)
  return taskInfo:GetGoalDetail(index)
end

function UMG_TaskTrackGoalItem_C:SkipShowAnimation()
  if not self:IsAnimationPlaying(self.NewTask) then
    return
  end
  local EndTime = self.NewTask:GetEndTime() - 0.01
  self:PlayAnimation(self.NewTask, EndTime)
end

function UMG_TaskTrackGoalItem_C:SkipRemoveAnimation()
  if not self:IsAnimationPlaying(self.Taskcomplete) then
    return
  end
  local EndTime = self.Taskcomplete:GetEndTime() - 0.01
  self:PlayAnimation(self.Taskcomplete, EndTime)
end

function UMG_TaskTrackGoalItem_C:OnQuickChatOpen()
  if self.PCKey then
    self._cachedPCKeyVisible = self.PCKey:GetVisibility() ~= UE4.ESlateVisibility.Collapsed
    self.PCKey:SetKeyVisibility(false)
  end
end

function UMG_TaskTrackGoalItem_C:OnQuickChatClose()
  if self.PCKey and self._cachedPCKeyVisible then
    self:ShowPCKey()
  end
end

function UMG_TaskTrackGoalItem_C:OnDespawn()
  self:UnregisterTracker()
  self.OldTracker = nil
  self.Style = GoalStyle.Main
  self.currentTxtDesc = nil
  self.MainStyle:SetVisibility(UE.ESlateVisibility.Visible)
  self.SubStyle:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.Envelope:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.TxtTargetDesc_Normal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TxtTargetDesc_Finish:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.VisitText:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.MapTips:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.Arrow:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.StateIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
  if _G.RocoEnv.IS_EDITOR then
    self.TaskID:SetText("")
  else
    self.TaskID:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_TaskTrackGoalItem_C

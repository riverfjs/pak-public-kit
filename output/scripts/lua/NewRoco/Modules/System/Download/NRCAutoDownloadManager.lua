local NRCAutoDownloadManager = _G.Singleton:Extend("NRCAutoDownloadManager")
local NRCAutoDownloadTaskFactory = require("NewRoco.Modules.System.Download.NRCAutoDownloadTask")
local PufferDownloadTag = require("NewRoco.Modules.System.Download.PufferDownloadTag")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local Queue = require("Utils.Queue")

function NRCAutoDownloadManager:Ctor()
  Log.Debug("NRCAutoDownloadManager:Ctor")
  self.bEnabled = not RocoEnv.IS_EDITOR and not RocoEnv.PLATFORM_WINDOWS
  self.DownloadTaskTagToIDMap = {}
  self.DownloadTaskIDMap = {}
  self.WaitingForWifiQueue = Queue()
  self.bActiveObserver = false
  self.bEnableNetworkListener = true
  self:SetIfPrintToScreen(false)
  self.AutoDownloadObserver = require("NewRoco.Modules.System.Download.AutoDownloadObserver")
  self.AutoDownloadObserver:Init()
end

function NRCAutoDownloadManager:SetIfPrintToScreen(bFlag)
  self.bPrintToScreen = bFlag
end

function NRCAutoDownloadManager:EnableAutoDownload(bEnable)
  self.bEnabled = bEnable
end

function NRCAutoDownloadManager:RegisterEvents()
  if not self.bEnabled then
    Log.Debug("NRCAutoDownloadManager:RegisterEvents: bEnabled is false")
    return
  end
  if self.bActiveObserver then
    return
  end
  local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCSDKManagerEvent.OnBackToLogin, self.OnBackToLogin)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnPufferDownloadBatchProgress)
  self:SetEnableNetworkListener(true)
  self.bActiveObserver = true
end

function NRCAutoDownloadManager:UnRegisterEvents()
  if not self.bActiveObserver then
    return
  end
  local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
  _G.NRCEventCenter:UnRegisterEvent(self, NRCSDKManagerEvent.OnBackToLogin, self.OnBackToLogin)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnPufferDownloadBatchProgress)
  self.CurrentNetworkStatus = 0
  self.bActiveObserver = false
end

function NRCAutoDownloadManager:OnPufferNetworkStatusChanged(NewStatus)
  Log.Debug("[NRCAutoDownloadManager:OnPufferNetworkStatusChanged] Receiving network change callback", NewStatus, self.CurrentNetworkStatus or 0)
  if not self.CurrentNetworkStatus then
    self.CurrentNetworkStatus = 0
    Log.Debug("[NRCAutoDownloadManager:OnPufferNetworkStatusChanged] set CurrentNetworkStatus to 0")
  end
  local LastNetworkStatus = self.CurrentNetworkStatus
  self.CurrentNetworkStatus = NewStatus
  if not self.bEnableNetworkListener then
    Log.Debug("[NRCAutoDownloadManager:OnPufferNetworkStatusChanged] bEnableNetworkListener is false")
    return
  end
  if 0 ~= LastNetworkStatus and 0 == NewStatus then
  elseif 1 ~= LastNetworkStatus and 1 == NewStatus then
    local NetworkType = UE.UNetworkStatics.GetNetworkState()
    if 1 ~= NetworkType then
      Log.Debug("[NRCAutoDownloadManager:OnPufferNetworkStatusChanged] network status is already not WWAN")
      return
    end
    self:PauseAllDownloadTasks()
  elseif 2 ~= LastNetworkStatus and 2 == NewStatus then
    self:ResumeAllDownloadTasks()
  end
end

function NRCAutoDownloadManager:CreateTaskQueueItem(Tag, PakList)
  local QueueItem = {Tag = Tag, PakList = PakList}
  return QueueItem
end

function NRCAutoDownloadManager:HasTask()
  if self.DownloadTaskIDMap and next(self.DownloadTaskIDMap) then
    return true
  elseif self.WaitingForWifiQueue and self.WaitingForWifiQueue:Size() > 0 then
    return true
  end
  return false
end

function NRCAutoDownloadManager:IsAnyTaskDownloading()
  for _, Task in pairs(self.DownloadTaskIDMap) do
    if Task and Task:IsDownloading() then
      Log.Debug("[NRCAutoDownloadManager:IsAnyTaskDownloading] Task is downloading:", Task:GetTag())
      return true
    end
  end
  return false
end

function NRCAutoDownloadManager:StartDownloadBasePaks()
  if not self.bEnabled then
    Log.Debug("NRCAutoDownloadManager:StartDownloadBasePaks: bEnabled is false")
    return
  end
  if not _G.PufferUpdateResTask:IsNeedDownloadBasePaksWithPatch() then
    Log.Debug("[NRCAutoDownloadManager:StartDownloadBasePaks] no need to download base paks")
    return
  end
  local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
  if NeedToDownloadBasePakList and #NeedToDownloadBasePakList > 0 then
    self:LaunchDownloadTask(PufferDownloadTag.Base, NeedToDownloadBasePakList)
  else
    Log.Error("BasePakList is empty")
  end
end

function NRCAutoDownloadManager:LaunchDownloadTask(Tag, PakList)
  if not self.bEnabled then
    Log.Debug("NRCAutoDownloadManager:LaunchDownloadTask: bEnabled is false")
    return
  end
  if not PakList or 0 == #PakList then
    Log.Error("PakList is empty")
    return
  end
  if string.IsNilOrEmpty(Tag) then
    Log.Error("Tag is empty")
    return
  end
  if self.DownloadTaskTagToIDMap[Tag] then
    Log.Error("Task is already exist")
    return
  end
  self:RegisterEvents()
  local NetworkType = UE.UNetworkStatics.GetNetworkState()
  if 2 == NetworkType then
    self:CreateTaskAndStartDownload(Tag, PakList)
  else
    Log.Debug("[NRCAutoDownloadManager:LaunchDownloadTask] add into WaitingForWifiQueue:", Tag)
    self.WaitingForWifiQueue:Enqueue(self:CreateTaskQueueItem(Tag, PakList))
  end
end

function NRCAutoDownloadManager:SetMaxSpeedMode()
  _G.PufferUpdateResTask:RestoreSettings()
end

function NRCAutoDownloadManager:IsSpeedLimitMode()
  return _G.PufferUpdateResTask:IsSpeedLimitMode()
end

function NRCAutoDownloadManager:SetSpeedLimitMode()
  _G.PufferUpdateResTask:SetSpeedLimitMode()
end

function NRCAutoDownloadManager:CreateTaskAndStartDownload(Tag, PakList)
  if self.DownloadTaskTagToIDMap[Tag] then
    Log.Error("Task is already exist")
    return
  end
  local Task = NRCAutoDownloadTaskFactory:NewTask(Tag, PakList)
  if Task:StartDownload() then
    local TaskID = Task:GetTaskID()
    self.DownloadTaskIDMap[TaskID] = Task
    self.DownloadTaskTagToIDMap[Tag] = TaskID
  end
end

function NRCAutoDownloadManager:OnPufferDownloadBatchReturn(BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, StrRet, SingleFileErrorCode)
  local Task = self:GetTask(BatchTaskId)
  if not Task then
    Log.Error("[NRCAutoDownloadManager:OnPufferDownloadBatchReturn] Task is not exist, BatchTaskId:", BatchTaskId)
    return
  end
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  local TaskTag = Task:GetTag()
  if IsSuccess then
    Log.Debug("[NRCAutoDownloadManager:OnPufferDownloadBatchReturn] Download Success ", TaskTag)
    if TaskTag ~= PufferDownloadTag.Base then
      _G.PufferUpdateResTask:MountPakList(Task:GetDownloadList())
    else
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadEnd, LoginEnum.DownloadReportType.BaseDownloadEnd, BatchTaskId)
      Log.Debug("[NRCAutoDownloadManager:OnPufferDownloadBatchReturn] Delay Mount BasePak")
    end
    self:RemoveDownloadTaskInternal(TaskTag, BatchTaskId)
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnAutoDownloadFinish, IsSuccess, TaskTag)
  else
    Log.Error(string.format("[NRCAutoDownloadManager:OnPufferDownloadBatchReturn] Tag:%s, ErrorCode:%s, SingleFileErrorCode:%s BatchType:%s, FiledId:%s", TaskTag, ErrorCode, SingleFileErrorCode or -1, BatchType, FiledId))
    if BatchType == UE.PufferBatchDownloadType.PBT_BatchTask then
      if TaskTag == PufferDownloadTag.Base then
        local ReportErrorCode
        if SingleFileErrorCode and 0 ~= SingleFileErrorCode then
          ReportErrorCode = SingleFileErrorCode
        else
          ReportErrorCode = ErrorCode
        end
        local ReportErrorReason = string.format("ErrorCode:%s", ReportErrorCode)
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, ReportErrorReason, BatchTaskId)
      end
      self:RemoveDownloadTaskInternal(TaskTag, BatchTaskId)
      _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnAutoDownloadFinish, IsSuccess, TaskTag)
    end
  end
end

function NRCAutoDownloadManager:OnPufferDownloadBatchProgress(BatchTaskId, NowSize, TotalSize)
  if not self.bPrintToScreen then
    return
  end
  local Task = self:GetTask(BatchTaskId)
  if Task then
    local TaskTag = Task:GetTag()
    local Progress = NowSize / TotalSize
    local DownloadedSize = _G.PufferUpdateResTask:FormatBytes(NowSize)
    local TotalSizeBytes = _G.PufferUpdateResTask:FormatBytes(TotalSize)
    local Speed = _G.PufferUpdateResTask:GetCurrentSpeed()
    Log.PrintScreenMsg(string.format("[NRCAutoDownloadManager] Tag:%s, \232\191\155\229\186\166:%.2f   %s/%s   \233\128\159\229\186\166: %s", TaskTag, Progress, DownloadedSize, TotalSizeBytes, Speed))
  end
end

function NRCAutoDownloadManager:PauseAllDownloadTasks()
  Log.Debug("[NRCAutoDownloadManager:PauseAllDownloadTasks] Pause All Download Tasks")
  for TaskID, Task in pairs(self.DownloadTaskIDMap) do
    if not Task:Pause() then
      self:RemoveDownloadTaskByID(TaskID)
    end
  end
end

function NRCAutoDownloadManager:ResumeAllDownloadTasks()
  Log.Debug("[NRCAutoDownloadManager:ResumeAllDownloadTasks] Resume All Download Tasks")
  for TaskID, Task in pairs(self.DownloadTaskIDMap) do
    if not Task:Resume() then
      self:RemoveDownloadTaskByID(TaskID)
    end
  end
  self:LaunchWaitForWifiTasks()
end

function NRCAutoDownloadManager:LaunchWaitForWifiTasks()
  while self.WaitingForWifiQueue:Size() > 0 do
    local TaskItem = self.WaitingForWifiQueue:Dequeue()
    if TaskItem and TaskItem.Tag and TaskItem.PakList then
      Log.Debug("[NRCAutoDownloadManager:LaunchWaitForWifiTasks] Launch WaitForWifiTask, ", TaskItem.Tag)
      self:CreateTaskAndStartDownload(TaskItem.Tag, TaskItem.PakList)
    end
  end
end

function NRCAutoDownloadManager:ResumeAllDownloadTasksOnWifi()
  local NetworkType = UE.UNetworkStatics.GetNetworkState()
  if 2 == NetworkType then
    self:ResumeAllDownloadTasks()
  else
    Log.Debug("[NRCAutoDownloadManager:ResumeAllDownloadTasksOnWifi] Network is not wifi")
  end
end

function NRCAutoDownloadManager:SetEnableNetworkListener(bEnable)
  self.bEnableNetworkListener = bEnable
end

function NRCAutoDownloadManager:OnBackToLogin()
  for TaskID, Task in pairs(self.DownloadTaskIDMap) do
    if Task:GetTag() == PufferDownloadTag.Base then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Back to login", TaskID)
      break
    end
  end
  self:RemoveAllDownloadTasks()
  _G.PufferUpdateResTask:Uninit()
  self.AutoDownloadObserver:Uninit()
end

function NRCAutoDownloadManager:RemoveAllDownloadTasks()
  Log.Debug("[NRCAutoDownloadManager:RemoveAllDownloadTasks] Remove All Download Tasks")
  _G.PufferUpdateResTask:RestoreSettings()
  for Tag, TaskID in pairs(self.DownloadTaskTagToIDMap) do
    self:RemoveDownloadTaskByTag(Tag)
  end
  self.DownloadTaskTagToIDMap = {}
  self.DownloadTaskIDMap = {}
  self.WaitingForWifiQueue:Clear()
  self:UnRegisterEvents()
end

function NRCAutoDownloadManager:RemoveDownloadTaskByTag(Tag)
  Log.Debug("[NRCAutoDownloadManager:RemoveDownloadTaskByTag] Tag ", Tag)
  local TaskID = self:GetTaskID(Tag)
  local Task = self:GetTask(TaskID)
  if Task then
    Task:Stop()
  end
  self:RemoveDownloadTaskInternal(Tag, TaskID)
end

function NRCAutoDownloadManager:RemoveDownloadTaskByID(TaskID)
  local Task = self:GetTask(TaskID)
  if Task then
    local Tag = Task:GetTag()
    Log.Debug("[NRCAutoDownloadManager:RemoveDownloadTaskByID] Tag ", Tag)
    Task:Stop()
    self:RemoveDownloadTaskInternal(Tag, TaskID)
  else
    Log.Error("[NRCAutoDownloadManager:RemoveDownloadTaskByID] Task is not exist, TaskID:", TaskID)
  end
end

function NRCAutoDownloadManager:GetTaskID(Tag)
  return self.DownloadTaskTagToIDMap[Tag]
end

function NRCAutoDownloadManager:GetTask(TaskID)
  return self.DownloadTaskIDMap[TaskID]
end

function NRCAutoDownloadManager:RemoveDownloadTaskInternal(Tag, TaskID)
  self.DownloadTaskTagToIDMap[Tag] = nil
  self.DownloadTaskIDMap[TaskID] = nil
end

return NRCAutoDownloadManager

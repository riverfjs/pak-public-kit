local NRCAutoDownloadTask = Class("NRCAutoDownloadTask")
local PufferDownloadTag = require("NewRoco.Modules.System.Download.PufferDownloadTag")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
NRCAutoDownloadTask.EDownloadStatus = {
  None = 1,
  Downloading = 2,
  Paused = 3,
  Finished = 4
}

function NRCAutoDownloadTask:NewTask(TaskTag, DownloadList)
  local Task = {}
  setmetatable(Task, {__index = self, __newindex = self})
  Task.TaskID = -1
  Task.TaskTag = TaskTag or "nil"
  Task.DownloadList = DownloadList
  Task.DownloadStatus = NRCAutoDownloadTask.EDownloadStatus.None
  Task.name = "NRCAutoDownloadTask_" .. self.TaskTag
  return Task
end

function NRCAutoDownloadTask:StartDownload()
  self.TaskID = _G.PufferUpdateResTask:DownloadBatchListByPakList(self.DownloadList)
  if self.TaskID and self.TaskID > 0 then
    if self.TaskTag == PufferDownloadTag.Base then
      _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
    end
    local ReportType = self:GetReportBeginTypeByTag()
    if ReportType then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, ReportType, self.TaskID)
    end
    self.DownloadStatus = NRCAutoDownloadTask.EDownloadStatus.Downloading
    Log.Debug("[NRCAutoDownloadTask:StartDownload] Launch Download Task:", self.TaskTag)
    return true
  end
  Log.Error("[NRCAutoDownloadTask:StartDownload] Launch Download Task Failed:", self.TaskTag)
  return false
end

function NRCAutoDownloadTask:Pause()
  local bSuccess = false
  if _G.PufferUpdateResTask:IsTaskDownloading(self.TaskID) then
    local ReportType = self:GetReportFailedTypeByTag()
    if ReportType then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, ReportType, "Pause download because no wifi", self.TaskID)
    end
    bSuccess = _G.PufferUpdateResTask:PauseTask(self.TaskID)
    if bSuccess then
      if self.TaskTag == PufferDownloadTag.Base then
        _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
      end
      self.DownloadStatus = NRCAutoDownloadTask.EDownloadStatus.Paused
      Log.Debug("[NRCAutoDownloadTask:Pause] Pause Download Task: ", self.TaskTag)
    else
      Log.Error("[NRCAutoDownloadTask:Pause] Pause Download Task Failed:", self.TaskTag)
    end
  end
  return bSuccess
end

function NRCAutoDownloadTask:Resume()
  local bSuccess = false
  if _G.PufferUpdateResTask:IsTaskDownloading(self.TaskID) then
    bSuccess = _G.PufferUpdateResTask:ResumeTask(self.TaskID)
    if bSuccess then
      if self.TaskTag == PufferDownloadTag.Base then
        _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
      end
      local ReportType = self:GetReportBeginTypeByTag()
      if ReportType then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, ReportType, self.TaskID)
      end
      self.DownloadStatus = NRCAutoDownloadTask.EDownloadStatus.Downloading
      Log.Debug("[NRCAutoDownloadTask:Pause] Resume Download Task: ", self.TaskTag)
    else
      Log.Error("[NRCAutoDownloadTask:Pause] Resume Download Task Failed:", self.TaskTag)
    end
  end
  return bSuccess
end

function NRCAutoDownloadTask:Stop()
  if _G.PufferUpdateResTask:IsTaskDownloading(self.TaskID) then
    Log.Debug("[NRCAutoDownloadTask:Stop] Stop Download Task:", self.TaskTag)
    _G.PufferUpdateResTask:RemoveTaskByID(self.TaskID)
  end
  self.DownloadStatus = NRCAutoDownloadTask.EDownloadStatus.None
end

function NRCAutoDownloadTask:GetReportBeginTypeByTag()
  if self.TaskTag then
    if self.TaskTag == PufferDownloadTag.Base then
      return LoginEnum.DownloadReportType.BaseDownloadBegin
    else
      Log.Error("[NRCAutoDownloadTask:GetReportTypeByTag] Get Report Type Failed:", self.TaskTag)
    end
  end
  return nil
end

function NRCAutoDownloadTask:GetReportFailedTypeByTag()
  if self.TaskTag then
    if self.TaskTag == PufferDownloadTag.Base then
      return LoginEnum.DownloadReportType.BaseDownloadFail
    else
      Log.Error("[NRCAutoDownloadTask:GetReportTypeByTag] Get Report Type Failed:", self.TaskTag)
    end
  end
  return nil
end

function NRCAutoDownloadTask:GetDownloadList()
  return self.DownloadList
end

function NRCAutoDownloadTask:GetDownloadStatus()
  return self.DownloadStatus
end

function NRCAutoDownloadTask:IsDownloading()
  return self.DownloadStatus == NRCAutoDownloadTask.EDownloadStatus.Downloading
end

function NRCAutoDownloadTask:GetTaskID()
  return self.TaskID
end

function NRCAutoDownloadTask:GetTag()
  return self.TaskTag
end

return NRCAutoDownloadTask

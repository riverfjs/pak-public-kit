local GCloudEndPoints = require("Core.Service.GCloud.GCloudEndPoints")
local rapidjson = require("rapidjson")
local PufferPakMountOrder = 1
local PufferUpdateResTask = Class("PufferUpdateResTask")

function PufferUpdateResTask:Ctor()
  self:ResetValues()
  _G.PufferDownloadInfo = require("NewRoco.Modules.System.UpdateUIModule.PufferDownloadInfo")
  _G.PufferDownloadInfo:Ctor()
  self.UpdateDataReporter = require("NewRoco.Modules.System.UpdateUIModule.UpdateDataReporter")
end

function PufferUpdateResTask:ResetValues()
  self.PufferDownloadTaskMap = {}
  self.TaskIdToFileListMap = {}
  self.bInited = false
end

function PufferUpdateResTask:Init(bForce)
  if bForce or not self.bInited then
    return self:InitInternal()
  elseif self:IsVersionChanged() then
    Log.Debug("[PufferUpdateResTask:Init] Version changed, puffer need to reinit")
    return self:InitInternal()
  else
    Log.Warning("[PufferUpdateResTask:Init] Repeat initialization")
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferInitReturn, self, true, 0)
    return true
  end
end

function PufferUpdateResTask:PreInit()
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    Log.Error("[PufferUpdateResTask:PreInit] GameInstance is nil")
    return
  end
  self.PufferInstance = NewObject(UE.UPufferImpl, GameInstance)
  self.PufferInstance_Ref = UnLua.Ref(self.PufferInstance)
  self.Observer = NewObject(UE.UPufferObserver, GameInstance, "", "Core.Service.GCloud.PufferObserver", self)
  self.Observer_Ref = UnLua.Ref(self.Observer)
end

function PufferUpdateResTask:CreateInfo()
  local AppInfo = _G.App
  self.MaxDownloadSpeed = UE4.UNRCStatics.GetIntFromGGameIni("/Script/NRC.PufferSettings", "MaxDownloadSpeed") * 1024 * 1024
  self.MaxDownTask = UE4.UNRCStatics.GetIntFromGGameIni("/Script/NRC.PufferSettings", "MaxDownTask")
  self.MaxDownloadsPerTask = UE4.UNRCStatics.GetIntFromGGameIni("/Script/NRC.PufferSettings", "MaxDownloadsPerTask")
  local InitInfo = UE.PufferInitConfig()
  InitInfo.nPufferGameId = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.GCloudSettings", "GCloudGameId")
  InitInfo.uMaxDownloadSpeed = self.MaxDownloadSpeed
  InitInfo.uMaxDownTask = self.MaxDownTask
  InitInfo.uMaxDownloadsPerTask = self.MaxDownloadsPerTask
  InitInfo.removeOldWhenUpdate = UE4.UNRCStatics.GetBoolFromGGameIni("/Script/NRC.PufferSettings", "RemoveOldWhenUpdate")
  InitInfo.uPufferProductId = AppInfo:GetPufferChannel()
  InitInfo.uShowFileList = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.PufferSettings", "ShowFileList")
  InitInfo.uPufferUpdateType = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.PufferSettings", "PufferUpdateType")
  InitInfo.uPufferDolphinProductId = AppInfo:GetDolphinChannel()
  InitInfo.needFileRestore = false
  InitInfo.connectorType = 2
  InitInfo.uNeedCheck = true
  InitInfo:SetStrSourceDir(self:GetPufferRootDir())
  InitInfo:SetStrPufferServerUrl(GCloudEndPoints:GetPufferUrl())
  self.AppVersion = AppInfo:GetAppVersion()
  self.ResVersion = AppInfo:GetResVersion()
  InitInfo:SetStrDolphinAppVersion(self.AppVersion)
  InitInfo:SetStrDolphinResVersion(self.ResVersion)
  return InitInfo
end

function PufferUpdateResTask:RestoreSettings()
  if not self.bInited then
    Log.Error("[PufferUpdateResTask:RestoreSettings] Puffer is not inited")
    return
  end
  self.bIsSetSpeedLimitMode = false
  self:SetDownloadMaxSpeed(self.MaxDownloadSpeed)
  self:SetDLMaxTask(self.MaxDownTask)
  self:SetImmDLMaxDownloadsPerTask(self.MaxDownloadsPerTask)
  Log.Debug("[PufferUpdateResTask:RestoreSettings] RestoreSettings")
end

function PufferUpdateResTask:IsSpeedLimitMode()
  return self.bIsSetSpeedLimitMode
end

function PufferUpdateResTask:SetSpeedLimitMode()
  if not self.bInited then
    Log.Error("[PufferUpdateResTask:SetSpeedLimitMode] Puffer is not inited")
    return
  end
  self.bIsSetSpeedLimitMode = true
  local AutoDownloadConfig = require("NewRoco.Modules.System.Download.AutoDownloadConfig")
  self:SetDLMaxTask(AutoDownloadConfig.MaxDownloadTaskCount)
  self:SetImmDLMaxDownloadsPerTask(AutoDownloadConfig.MaxDownloadsPerTask)
  local DeviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel()
  local DownloadMaxSpeed
  if DeviceLevel <= 2 then
    DownloadMaxSpeed = AutoDownloadConfig.MaxDownloadSpeedLowLevel
  elseif 3 == DeviceLevel then
    DownloadMaxSpeed = AutoDownloadConfig.MaxDownloadSpeedMediumLevel
  else
    DownloadMaxSpeed = AutoDownloadConfig.MaxDownloadSpeedHighLevel
  end
  Log.Debug("[PufferUpdateResTask:SetSpeedLimitMode] set DownloadMaxSpeed:", DownloadMaxSpeed)
  self:SetDownloadMaxSpeed(DownloadMaxSpeed)
end

function PufferUpdateResTask:RegisterEvents()
  _G.NRCEventCenter:RegisterEvent("PufferUpdateResTask", self, _G.NRCGlobalEvent.OnPrePIEEnded, self.Uninit)
  _G.NRCEventCenter:RegisterEvent("PufferUpdateResTask", self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.OnMapLoaded)
end

function PufferUpdateResTask:UnRegisterEvents()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnPrePIEEnded, self.Uninit)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.PostLoadMapWithWorld, self.OnMapLoaded)
end

function PufferUpdateResTask:InitInternal()
  self.UpdateDataReporter:Init()
  if self.bInited or self.PufferInstance then
    Log.Warning("[PufferUpdateResTask:InitInternal] Reinit, call Uninit first")
    self:Uninit()
  end
  self:PreInit()
  if not self.PufferInstance then
    self:Uninit()
    return false
  end
  if not self.Observer then
    self:Uninit()
    return false
  end
  local InitInfo = self:CreateInfo()
  self:FillInfo(InitInfo)
  local PufferConfigPath = self:MakeSavedPath("PufferPakInfo.json")
  local Result = self.PufferInstance:Init(self.Observer, InitInfo, PufferConfigPath)
  if not Result then
    Log.Error("Puffer\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\129")
    self:Uninit()
    return false
  end
  self:RegisterEvents()
  self:CreateNetworkObserver()
  local ResVerifyPath = self:MakeSavedPath("ResVerifyConfig.json")
  local bSuccess = _G.PufferDownloadInfo:Init(self.PufferInstance, PufferConfigPath, ResVerifyPath)
  if not bSuccess then
    Log.Error("[PufferUpdateResTask:InitInternal] Init PufferDownloadInfo failed")
    self:Uninit()
    return false
  end
  self.bInited = true
  Log.Debug("[PufferUpdateResTask:InitInternal] Init success")
  return Result
end

function PufferUpdateResTask:IsVersionChanged()
  local CurAppVer = _G.AppMain:GetAppVersion()
  local CurResVer = _G.AppMain:GetResVersion()
  return CurAppVer ~= self.AppVersion or CurResVer ~= self.ResVersion
end

function PufferUpdateResTask:FillInfo(InitInfo)
end

function PufferUpdateResTask:StartCheck()
  if not self.PufferInstance then
    return
  end
  self.PufferInstance:CheckAppUpdate()
end

function PufferUpdateResTask:IsTaskDownloading(TaskID)
  if self.PufferInstance and TaskID and self.PufferDownloadTaskMap[TaskID] then
    return true
  end
  return false
end

function PufferUpdateResTask:RemoveTaskByID(TaskID)
  if self.PufferInstance and TaskID then
    if not self:PauseTask(TaskID) then
      Log.Error("[PufferUpdateResTask:RemoveAllTasks] Pause task failed " .. TaskID)
    end
    self.PufferInstance:RemoveTask(TaskID)
    Log.Debug("[PufferUpdateResTask:RemoveTaskByID] Remove task " .. TaskID)
    if self.PufferDownloadTaskMap[TaskID] then
      self.PufferDownloadTaskMap[TaskID] = nil
    end
  end
end

function PufferUpdateResTask:RemoveAllTasks()
  if self.PufferInstance then
    for TaskId, PakFileList in pairs(self.PufferDownloadTaskMap) do
      if PakFileList then
        if not self:PauseTask(TaskId) then
          Log.Error("[PufferUpdateResTask:RemoveAllTasks] Pause task failed " .. TaskId)
        end
        self.PufferInstance:RemoveTask(TaskId)
        Log.Debug("[PufferUpdateResTask:RemoveAllTasks] Remove task id from PufferDownloadTaskMap " .. TaskId)
      end
    end
  end
  self.PufferDownloadTaskMap = {}
end

function PufferUpdateResTask:Uninit()
  Log.Debug("[PufferUpdateResTask:Uninit]")
  _G.PufferDownloadInfo:Clear()
  self:UnRegisterEvents()
  self:DestroyNetworkObserver()
  if self.PufferInstance and UE.UObject.IsValid(self.PufferInstance) then
    Log.Debug("[PufferUpdateResTask:Uninit] Uninit PufferInstance")
    self:RemoveAllTasks()
    self.PufferInstance:UnInit()
    self.PufferInstance = nil
    self.PufferInstance_Ref = nil
  end
  self.Observer = nil
  self.Observer_Ref = nil
  self:ResetValues()
  self.UpdateDataReporter:Uninit()
end

function PufferUpdateResTask:OnInitReturn(IsSuccess, ErrorCode)
  if not IsSuccess then
    Log.Error("[PufferUpdateResTask:OnInitReturn] Init failed")
    _G.DelayManager:DelayFrames(1, function()
      self:Uninit()
    end)
  elseif self.PufferInstance then
    self.PufferInstance:EnableHighSpeedCDN()
  end
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferInitReturn, self, IsSuccess, ErrorCode)
end

function PufferUpdateResTask:OnInitProgress(Stage, NowSize, TotalSize)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferInitProgress, Stage, NowSize, TotalSize)
end

function PufferUpdateResTask:OnDownloadReturn(TaskId, FileId, IsSuccess, ErrorCode)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferDownloadReturn, TaskId, FileId, IsSuccess, ErrorCode)
end

function PufferUpdateResTask:OnDownloadProgress(TaskId, NowSize, TotalSize)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferDownloadProgress, TaskId, NowSize, TotalSize)
end

function PufferUpdateResTask:OnRestoreReturn(IsSuccess, ErrorCode)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferRestoreReturn, IsSuccess, ErrorCode)
end

function PufferUpdateResTask:OnRestoreProgress(Stage, NowSize, TotalSize)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferRestoreProgress, Stage, NowSize, TotalSize)
end

function PufferUpdateResTask:OnDownloadBatchReturn(BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, StrRet)
  Log.Debug(string.format("[PufferUpdateResTask:OnDownloadBatchReturn] BatchTaskId:%s FiledId:%s BatchType:%s ErrorCode:%s StrRet:%s", BatchTaskId, FiledId, BatchType, ErrorCode, StrRet))
  local SingleFileErrorCode = 0
  if BatchType == UE.PufferBatchDownloadType.PBT_BatchTask then
    if self.PufferDownloadTaskMap[BatchTaskId] then
      Log.Debug("[PufferUpdateResTask:OnDownloadBatchReturn] Remove task id from PufferDownloadTaskMap " .. BatchTaskId)
      self.PufferDownloadTaskMap[BatchTaskId] = nil
      self.PufferInstance:RemoveTask(BatchTaskId)
    end
    SingleFileErrorCode = self.SingleFileErrorCode or 0
    self.SingleFileErrorCode = 0
  elseif BatchType == UE.PufferBatchDownloadType.PBT_FileTask then
    Log.Debug("[PufferUpdateResTask:OnDownloadBatchReturn] File download failed, Update errorCode to:" .. ErrorCode)
    self.SingleFileErrorCode = ErrorCode
  elseif BatchType == UE.PufferBatchDownloadType.PBT_FileTask_Retry then
    Log.Debug("[PufferUpdateResTask:OnDownloadBatchReturn] File download failed, ErrorCode:" .. ErrorCode)
    return
  end
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferDownloadBatchReturn, BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, SingleFileErrorCode)
end

function PufferUpdateResTask:OnDownloadBatchProgress(BatchTaskId, NowSize, TotalSize)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferDownloadBatchProgress, BatchTaskId, NowSize, TotalSize)
end

function PufferUpdateResTask:OnDownloadIOSBackgroundDone()
end

function PufferUpdateResTask:OnPufferFileListItem(FileName, St)
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferFileListItem, FileName, St)
end

function PufferUpdateResTask:OnMapLoaded(World)
  if not self.PufferInstance then
    return
  end
  if World then
    local WorldName = World:GetName()
    if WorldName and "UpdateLevel" ~= WorldName then
      Log.Debug("[PufferUpdateResTask:OnMapLoaded] OnMapLoaded " .. WorldName)
      self:ResetNetworkObserver()
    end
  end
end

function PufferUpdateResTask:SetDLMaxTask(MaxTask)
  if not self.PufferInstance then
    return
  end
  return self.PufferInstance:SetDLMaxTask(MaxTask)
end

function PufferUpdateResTask:SetImmDLMaxDownloadsPerTask(MaxDownloadsPerTask)
  if not self.PufferInstance then
    return
  end
  return self.PufferInstance:SetImmDLMaxDownloadsPerTask(MaxDownloadsPerTask)
end

function PufferUpdateResTask:IsNeedDownloadBasePaks()
  if not self:IsNeedDownloadRes() then
    return false
  end
  local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListNeedToDownload()
  if NeedToDownloadBasePakList and #NeedToDownloadBasePakList > 0 then
    return true
  end
  return false
end

function PufferUpdateResTask:IsNeedDownloadBasePaksWithPatch()
  if not self:IsNeedDownloadRes() then
    return false
  end
  local NeedToDownloadPakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
  if NeedToDownloadPakList and #NeedToDownloadPakList > 0 then
    return true
  end
  return false
end

function PufferUpdateResTask:IsNeedDownloadRes()
  if RocoEnv.IS_EDITOR or AppMain.IsFullPackage() or AppMain.IsLocalSavedHasBasePaks() then
    return false
  end
  return true
end

function PufferUpdateResTask:GetFileId(FilePath)
  if not self.PufferInstance then
    return
  end
  return self.PufferInstance:GetFileId(FilePath)
end

function PufferUpdateResTask:IsFileReady(FileId)
  Log.Error("[PufferUpdateResTask:IsFileReady] deprecated")
  if not self.PufferInstance then
    return false
  end
  return self.PufferInstance:IsFileReady(FileId)
end

function PufferUpdateResTask:IsFileReadyByFullPath(FullFilePath)
  if not self.PufferInstance then
    return false
  end
  if string.IsNilOrEmpty(FullFilePath) then
    return false
  end
  local bExists = UE.UNRCStatics.FileExists(FullFilePath)
  Log.Debug(string.format("[PufferUpdateResTask:IsFileReadyByFullPath] FullFilePath:%s, bExists:%s", FullFilePath, bExists))
  return bExists
end

function PufferUpdateResTask:IsFileReadyByFilePath(FilePath)
  Log.Error("[PufferUpdateResTask:IsFileReadyByFilePath] deprecated")
  if not self.PufferInstance then
    return false
  end
  return self.PufferInstance:IsFileReadyByFilePath(FilePath)
end

function PufferUpdateResTask:GetFileSizeCompressed(FileId)
  if not self.PufferInstance then
    return -1
  end
  return self.PufferInstance:GetFileSizeCompressed(FileId)
end

function PufferUpdateResTask:GetFileSizeDownloaded(FileId)
  if not self.PufferInstance then
    return 0
  end
  return self.PufferInstance:GetFileSizeDownloaded(FileId)
end

function PufferUpdateResTask:SetCurrentDownloadProgress(Progress)
  if not self.PufferInstance then
    Log.Error("[PufferUpdateResTask:SetCurrentDownloadProgress] PufferInstance is nil")
    return
  end
  self.PufferInstance:SetCurrentDownloadProgress(Progress)
end

function PufferUpdateResTask:GetCurrentDownloadProgress()
  if not self.PufferInstance then
    Log.Error("[PufferUpdateResTask:SetCurrentDownloadProgress] PufferInstance is nil")
    return
  end
  return self.PufferInstance:GetCurrentDownloadProgress()
end

function PufferUpdateResTask:DownloadFile(FileId, ForceDownload, Priority)
  if not self.PufferInstance then
    return
  end
  self.PufferInstance:DownloadFile(FileId, ForceDownload, Priority)
end

function PufferUpdateResTask:PauseTask(TaskId)
  if not self.PufferInstance then
    return false
  end
  if not TaskId then
    Log.Error("[PufferUpdateResTask:PauseTask] TaskId is nil")
    return false
  end
  local bPauseSuccess = self.PufferInstance:PauseTask(TaskId)
  Log.Debug(string.format("[PufferUpdateResTask:PauseTask] Pause task id:%s, bPauseSuccess:%s", TaskId, bPauseSuccess))
  return bPauseSuccess
end

function PufferUpdateResTask:ResumeTask(TaskId)
  if not self.PufferInstance then
    return
  end
  if not TaskId then
    Log.Error("[PufferUpdateResTask:ResumeTask] TaskId is nil")
    return false
  end
  local bResumeSuccess = self.PufferInstance:ResumeTask(TaskId)
  Log.Debug(string.format("[PufferUpdateResTask:ResumeTask] Resume task id:%s, bResumeSuccess:%s", TaskId, bResumeSuccess))
  return bResumeSuccess
end

function PufferUpdateResTask:DispatchClientFailureBatchReturnEvent()
  local BatchTaskId = -1
  local FiledId = -1
  local IsSuccess = false
  local ErrorCode = -1
  local BatchType = UE.PufferBatchDownloadType.PBT_BatchTask
  local StrRet = ""
  local SingleFileErrorCode = 0
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnPufferDownloadBatchReturn, BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, StrRet, SingleFileErrorCode)
end

function PufferUpdateResTask:DownloadBatchListByPakList(PakList)
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    self:DispatchClientFailureBatchReturnEvent()
    return
  end
  local PakFileListJsonStr = rapidjson.encode(PakList)
  Log.Debug("PakFileListJsonStr:" .. PakFileListJsonStr)
  local TaskId = self.PufferInstance:DownloadBatchList(PakFileListJsonStr, false, 10)
  if TaskId <= 0 then
    Log.Error("TaskId is invalid  " .. TaskId)
    self:DispatchClientFailureBatchReturnEvent()
    return
  end
  if self.PufferDownloadTaskMap[TaskId] then
    Log.Error("Puffer download task id is repeated")
  end
  Log.Debug("DownloadBatchListByPakList TaskId:" .. TaskId)
  self.PufferDownloadTaskMap[TaskId] = 1
  self.TaskIdToFileListMap[TaskId] = PakList
  return TaskId
end

function PufferUpdateResTask:GetLocalDownloadedSizeByTaskID(TaskID)
  if TaskID then
    local PakList = self.TaskIdToFileListMap[TaskID]
    if PakList and #PakList > 0 then
      local LocalDownloadedSize = 0
      for _, FilePath in ipairs(PakList) do
        local FileId = self:GetFileId(FilePath)
        if FileId then
          local DownloadedSize = self:GetFileSizeDownloaded(FileId)
          Log.Debug("[PufferUpdateResTask:GetLocalDownloadedSizeByTaskID] get downloaded size: ", DownloadedSize)
          local FileSize = self:GetFileSizeCompressed(FileId)
          local FullPath = self:GetRelativePathToPuffer(FilePath)
          if not self:IsFileReadyByFullPath(FullPath) and DownloadedSize == FileSize then
            Log.Error("[PufferUpdateResTask:GetLocalDownloadedSizeByTaskID] DownloadedSize is equal to FileSize")
            DownloadedSize = 0
          end
          if DownloadedSize > 0 then
            LocalDownloadedSize = LocalDownloadedSize + DownloadedSize
          end
        else
          Log.Error("[PufferUpdateResTask:GetLocalDownloadedSizeByTaskID] GetFileId failed: ", FilePath)
        end
      end
      return LocalDownloadedSize
    else
      Log.Error("[[PufferUpdateResTask:GetLocalDownloadedSizeByTaskID] PakList is nil or empty")
    end
  else
    Log.Error("[PufferUpdateResTask:GetLocalDownloadedSizeByTaskID] TaskID is nil")
    return nil
  end
end

function PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
  local PakList = _G.PufferDownloadInfo:GetBasePakListWithPatch()
  return self:GetPakListNeedToDownload(PakList)
end

function PufferUpdateResTask:GetBasePakListNeedToDownload()
  local PakList = _G.PufferDownloadInfo:GetBasePakList()
  return self:GetPakListNeedToDownload(PakList)
end

function PufferUpdateResTask:GetPakListNeedToDownload(PakList)
  local NeedToDownloadBasePakList = {}
  local SizeNeedToDownload = 0
  local SizeLocalDownloaded = 0
  local LargestSize = 0
  if PakList and #PakList > 0 then
    for _, FilePath in ipairs(PakList) do
      Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] Check File: ", FilePath)
      local FileId = self:GetFileId(FilePath)
      if FileId then
        local FullPath = self:GetRelativePathToPuffer(FilePath)
        if not self:IsFileReadyByFullPath(FullPath) then
          Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] File Need To Download: ", FilePath)
          local FileSize = self:GetFileSizeCompressed(FileId)
          Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] get file size: ", FileSize)
          if FileSize > 0 then
            SizeNeedToDownload = SizeNeedToDownload + FileSize
            if LargestSize < FileSize then
              LargestSize = FileSize
            end
            table.insert(NeedToDownloadBasePakList, FilePath)
          else
            Log.Error("[PufferUpdateResTask:GetBasePakListNeedToDownload] FileSize is 0: ", FilePath)
          end
          local DownloadedSize = self:GetFileSizeDownloaded(FileId)
          Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] get downloaded size: ", DownloadedSize)
          if DownloadedSize == FileSize then
            Log.Error("[PufferUpdateResTask:GetBasePakListNeedToDownload] DownloadedSize is equal to FileSize")
            DownloadedSize = 0
          end
          if DownloadedSize > 0 then
            SizeLocalDownloaded = SizeLocalDownloaded + DownloadedSize
          end
        else
          Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] File is ready: ", FilePath)
        end
      else
        Log.Error("[PufferUpdateResTask:GetBasePakListNeedToDownload] GetFileId failed: ", FilePath)
        table.insert(NeedToDownloadBasePakList, FilePath)
      end
    end
  else
    NeedToDownloadBasePakList = nil
    Log.Error("[PufferUpdateResTask:GetBasePakListNeedToDownload] Base Pak List Is Empty")
  end
  if SizeNeedToDownload > SizeLocalDownloaded then
    SizeNeedToDownload = SizeNeedToDownload - SizeLocalDownloaded
    Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] SizeNeedToDownload: ", SizeNeedToDownload)
  end
  return NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize
end

function PufferUpdateResTask:SetDownloadMaxSpeed(MaxSpeed)
  if not self.PufferInstance then
    Log.Error("PufferInstance is invalid")
    return
  end
  if not MaxSpeed then
    Log.Error("MaxSpeed is nil")
    return
  end
  return self.PufferInstance:SetDLMaxSpeed(MaxSpeed)
end

function PufferUpdateResTask:MountPakList(PakList)
  if not PakList then
    Log.Error("[PufferUpdateResTask:MountPakList] PakList is nil")
    return false
  end
  local bMountSuccess = true
  if not RocoEnv.IS_EDITOR then
    local FullPath
    local SavedPath = UE.UBlueprintPathsLibrary.ProjectSavedDir()
    for _, Path in ipairs(PakList) do
      if string.find(Path, SavedPath) then
        FullPath = Path
      else
        FullPath = self:GetRelativePathToPuffer(Path)
      end
      if not UE4.UHotUpdateUtils.IsPakMounted(FullPath) then
        local bSuccess = UE4.UHotUpdateUtils.MountPak(FullPath, PufferPakMountOrder)
        Log.Debug(string.format("[PufferUpdateResTask:MountPakList] mount local downloaded pak:%s bSuccess:%s", FullPath, tostring(bSuccess)))
        if not bSuccess then
          bMountSuccess = false
          local bDeleteSuccesss = UE.UNRCStatics.DeleteToFile(FullPath)
          Log.Error(string.format("[PufferUpdateResTask:MountPakList] mount failed, will delete pak:%s result:%s", FullPath, tostring(bDeleteSuccesss)))
        end
      end
    end
  end
  return bMountSuccess
end

function PufferUpdateResTask:IsPakListAllReady(PakList)
  if not self:IsNeedDownloadRes() then
    return true
  end
  if PakList then
    local FullPath
    for _, Path in ipairs(PakList) do
      FullPath = self:GetRelativePathToPuffer(Path)
      if not UE4.UHotUpdateUtils.IsPakMounted(FullPath) then
        Log.Error("[PufferUpdateResTask:IsPakListAllReady] pak not mounted:%s", FullPath)
        return false
      end
    end
    return true
  end
  return false
end

function PufferUpdateResTask:FormatBytes(Bytes)
  local units = {
    "B",
    "KB",
    "MB",
    "GB",
    "TB"
  }
  local i = 1
  while Bytes >= 1024 and i < #units do
    Bytes = Bytes / 1024
    i = i + 1
  end
  return string.format("%.1f %s", Bytes, units[i])
end

function PufferUpdateResTask:GetCurrentSpeed()
  if not self.PufferInstance then
    return "0B/S"
  end
  return string.format("%s/S", self:FormatBytes(self.PufferInstance:GetCurrentPufferSpeed()))
end

function PufferUpdateResTask:CreateNetworkObserver()
  if RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if self.NetworkObserver then
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  self.NetworkObserver = NewObject(UE.UNetworkStatusObserver, World, "", "Core.Service.GCloud.NetworkStatusObserver", self)
  self.NetworkObserver_Ref = UnLua.Ref(self.NetworkObserver)
  UE.UNetworkStatics.AddObserver(self.NetworkObserver)
end

function PufferUpdateResTask:DestroyNetworkObserver()
  if RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if not self.NetworkObserver then
    return
  end
  UE.UNetworkStatics.RemoveObserver(self.NetworkObserver)
  self.NetworkObserver = nil
  self.NetworkObserver_Ref = nil
end

function PufferUpdateResTask:ResetNetworkObserver()
  Log.Debug("[PufferUpdateResTask:ResetNetworkObserver] Reset Network Observer")
  self:DestroyNetworkObserver()
  self:CreateNetworkObserver()
end

function PufferUpdateResTask:MakePath(SavedOrContent, Sub)
  local PathSegs
  local Prefix = SavedOrContent and "Saved" or "Content"
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" then
    PathSegs = {
      UE.UNRCStatics.GetFilePathBase(),
      "UE4Game",
      "NRC",
      "NRC",
      Prefix
    }
  elseif RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    PathSegs = {
      UE.UNRCStatics.GetFilePathBase(),
      "UE4Game",
      "NRC",
      "NRC",
      Prefix
    }
  else
    PathSegs = {
      UE.UBlueprintPathsLibrary.ProjectDir(),
      Prefix
    }
  end
  if not string.IsNilOrEmpty(Sub) then
    table.insert(PathSegs, Sub)
  end
  local Path = UE.UBlueprintPathsLibrary.Combine(PathSegs)
  if RocoEnv.PLATFORM ~= "PLATFORM_ANDROID" and RocoEnv.PLATFORM ~= "PLATFORM_OPENHARMONY" then
    Path = UE.UNRCStatics.ConvertToAbsolutePath(Path, false)
  end
  UE.UNRCStatics.MakeDirectory(Path)
  return Path
end

function PufferUpdateResTask:GetPufferRootDir()
  return self:MakeSavedPath("Puffer")
end

function PufferUpdateResTask:GetFullPathByPufferRelativePath(Sub)
  return UE.UBlueprintPathsLibrary.Combine({
    self:GetPufferRootDir(),
    Sub
  })
end

function PufferUpdateResTask:GetRelativePathToPuffer(Sub)
  return UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "Puffer",
    Sub
  })
end

function PufferUpdateResTask:MakeSavedPath(Sub)
  return self:MakePath(true, Sub)
end

function PufferUpdateResTask:MakeContentPath(Sub)
  return self:MakePath(false, Sub)
end

function PufferUpdateResTask:SplitVersion(Version)
  local Spat = string.Split(Version, ".")
  if not Spat then
    return 0, 0, 0, 0
  end
  return tonumber(Spat[1] or "0"), tonumber(Spat[2] or "0"), tonumber(Spat[3] or "0"), tonumber(Spat[4] or "0")
end

function PufferUpdateResTask:CompareVersion(One, Two)
  local O1, O2, O3, O4 = self:SplitVersion(One)
  local T1, T2, T3, T4 = self:SplitVersion(Two)
  if O1 ~= T1 then
    return O1 > T1
  end
  if O2 ~= T2 then
    return O2 > T2
  end
  if O3 ~= T3 then
    return O3 > T3
  end
  return O4 >= T4
end

return PufferUpdateResTask

local GCloudEndPoints = require("Core.Service.GCloud.GCloudEndPoints")
local Base = require("Core.Service.GCloud.Tasks.PufferUpdateResTask")
local PreDownloadPufferTask = Base:Extend("PreDownloadPufferTask")

function PreDownloadPufferTask:Ctor()
  Log.Debug("PreDownloadPufferTask:Ctor")
  self:ResetValues()
  self.PufferDownloadInfo = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadPufferInfo")
  self.PufferDownloadInfo:Ctor()
end

function PreDownloadPufferTask:ResetValues()
  Base.ResetValues(self)
  self.TotalSizeText = nil
  self.TotalSize = nil
end

function PreDownloadPufferTask:Init()
  if self.bInited or self.PufferInstance then
    Log.Warning("[PreDownloadPufferTask:Init] Reinit, call Uninit first")
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
  local DolphinRootPath = _G.NRCPreDownloadManager:GetDolphinRootDir()
  local PufferConfigPath = UE.UBlueprintPathsLibrary.Combine({
    DolphinRootPath,
    "PufferPakInfo.json"
  })
  local Result = self.PufferInstance:Init(self.Observer, InitInfo, PufferConfigPath)
  if not Result then
    Log.Error("Puffer\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\129")
    self:Uninit()
    return false
  end
  self:RegisterEvents()
  self:CreateNetworkObserver()
  local PufferResVerifyPath = UE.UBlueprintPathsLibrary.Combine({
    DolphinRootPath,
    "ResVerifyConfig.json"
  })
  local bSuccess = self.PufferDownloadInfo:Init(self.PufferInstance, PufferConfigPath, PufferResVerifyPath)
  if not bSuccess then
    Log.Error("[PufferUpdateResTask:InitInternal] Init PufferDownloadInfo failed")
    self:Uninit()
    return false
  end
  self.bInited = true
  Log.Debug("[PufferUpdateResTask:InitInternal] Init success")
  return Result
end

function PreDownloadPufferTask:FillInfo(InitInfo)
  InitInfo:SetStrSourceDir(_G.NRCPreDownloadManager:GetPufferRootDir())
  self.AppVersion = _G.NRCPreDownloadManager:GetPreDownloadAppVersion()
  self.ResVersion = _G.NRCPreDownloadManager:GetPreDownloadResVersion()
  InitInfo:SetStrDolphinAppVersion(self.AppVersion)
  InitInfo:SetStrDolphinResVersion(self.ResVersion)
  InitInfo.uPufferDolphinProductId = _G.AppMain:GetPreDownloadDolphinChannel()
end

function PreDownloadPufferTask:Uninit()
  Log.Debug("[PreDownloadPufferTask:Uninit]")
  self.PufferDownloadInfo:Clear()
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
end

function PreDownloadPufferTask:GetPreDownloadResListNeedToDownload()
  local ResNeedToDownloadList = {}
  local AllResList = self.PufferDownloadInfo:GetAllResList()
  local SizeNeedToDownload = 0
  local SizeLocalDownloaded = 0
  local LargestSize = 0
  if AllResList and #AllResList > 0 then
    for _, FilePath in ipairs(AllResList) do
      Log.Debug("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] Check File: ", FilePath)
      local FileId = self:GetFileId(FilePath)
      if FileId then
        if not self:IsFileReady(FileId) then
          Log.Debug("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] File Need To Download: ", FilePath)
          local FileSize = self:GetFileSizeCompressed(FileId)
          Log.Debug("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] get file size: ", FileSize)
          if FileSize > 0 then
            SizeNeedToDownload = SizeNeedToDownload + FileSize
            if LargestSize < FileSize then
              LargestSize = FileSize
            end
            table.insert(ResNeedToDownloadList, FilePath)
          else
            Log.Error("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] FileSize is 0: ", FilePath)
          end
          local DownloadedSize = self:GetFileSizeDownloaded(FileId)
          Log.Debug("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] get downloaded size: ", DownloadedSize)
          if DownloadedSize == FileSize then
            Log.Error("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] DownloadedSize is equal to FileSize")
            DownloadedSize = 0
          end
          if DownloadedSize > 0 then
            SizeLocalDownloaded = SizeLocalDownloaded + DownloadedSize
          end
        else
          Log.Debug("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] File is ready: ", FilePath)
        end
      else
        Log.Error("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] GetFileId failed: ", FilePath)
        table.insert(ResNeedToDownloadList, FilePath)
      end
    end
  else
    ResNeedToDownloadList = nil
    Log.Error("[PreDownloadPufferTask:GetPreDownloadResListNeedToDownload] Res List Is Empty")
  end
  if SizeNeedToDownload > SizeLocalDownloaded then
    SizeNeedToDownload = SizeNeedToDownload - SizeLocalDownloaded
    Log.Debug("[PufferUpdateResTask:GetBasePakListNeedToDownload] SizeNeedToDownload: ", SizeNeedToDownload)
  end
  return ResNeedToDownloadList, SizeNeedToDownload, LargestSize
end

function PreDownloadPufferTask:GetTotalSize(bGetBytesNumber)
  if bGetBytesNumber and self.TotalSize then
    return self.TotalSize
  end
  if self.TotalSizeText then
    return self.TotalSizeText
  end
  local TotalSize = 0
  local AllResList = self.PufferDownloadInfo:GetAllResList()
  if AllResList and #AllResList > 0 then
    for _, FilePath in ipairs(AllResList) do
      local FileId = self:GetFileId(FilePath)
      if FileId then
        local FileSize = self:GetFileSizeCompressed(FileId)
        TotalSize = TotalSize + FileSize
      else
        Log.Error("[PreDownloadPufferTask:GetTotalSizeText] GetFileId failed: ", FilePath)
      end
    end
  else
    Log.Error("[PreDownloadPufferTask:GetTotalSizeText] Res List Is Empty")
  end
  if TotalSize > 0 then
    self.TotalSize = TotalSize
  end
  if bGetBytesNumber then
    return TotalSize
  end
  local TotalSizeText = self:FormatBytes(TotalSize)
  if TotalSize > 0 then
    self.TotalSizeText = TotalSizeText
  end
  return TotalSizeText
end

function PreDownloadPufferTask:GetLocalDownloadedSize()
  local LocalDownloadedSize = 0
  local AllResList = self.PufferDownloadInfo:GetAllResList()
  if AllResList and #AllResList > 0 then
    for _, FilePath in ipairs(AllResList) do
      local FileId = self:GetFileId(FilePath)
      if FileId then
        local DownloadedSize = self:GetFileSizeDownloaded(FileId)
        Log.Debug("[PreDownloadPufferTask:GetLocalDownloadedSizeText] get downloaded size: ", DownloadedSize)
        local FileSize = self:GetFileSizeCompressed(FileId)
        if not self:IsFileReady(FileId) and DownloadedSize == FileSize then
          Log.Error("[PreDownloadPufferTask:GetLocalDownloadedSizeText] DownloadedSize is equal to FileSize", FilePath)
          DownloadedSize = 0
        end
        if DownloadedSize > 0 then
          LocalDownloadedSize = LocalDownloadedSize + DownloadedSize
        end
      else
        Log.Error("[PreDownloadPufferTask:GetLocalDownloadedSizeText] GetFileId failed: ", FilePath)
      end
    end
  else
    Log.Error("[PreDownloadPufferTask:GetTotalSizeText] Res List Is Empty")
  end
  return LocalDownloadedSize
end

function PreDownloadPufferTask:GetPufferRootDir()
  return _G.NRCPreDownloadManager:GetPufferRootDir()
end

function PreDownloadPufferTask:IsFileReady(FileId)
  if not self.PufferInstance then
    return false
  end
  return self.PufferInstance:IsFileReady(FileId)
end

return PreDownloadPufferTask

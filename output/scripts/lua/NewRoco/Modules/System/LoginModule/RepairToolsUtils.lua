local RepairToolsUtils = {}

function RepairToolsUtils.CleanPlatformCache()
  local bHasContents = false
  bHasContents = RepairToolsUtils.CleanFolder(UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempVideos"
  })) or bHasContents
  bHasContents = RepairToolsUtils.CleanFolder(UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempPhotos"
  })) or bHasContents
  bHasContents = RepairToolsUtils.CleanFolder(UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "CardPhotos"
  })) or bHasContents
  bHasContents = RepairToolsUtils.CleanFolder(UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "RemotePhotos"
  })) or bHasContents
  bHasContents = RepairToolsUtils.CleanFolder(UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "CommonUrlImages"
  })) or bHasContents
  if RocoEnv.PLATFORM_WINDOWS then
    if RocoEnv.IS_EDITOR then
      bHasContents = RepairToolsUtils.CleanFolder(UE.UBlueprintPathsLibrary.Combine({
        UE4.UBlueprintPathsLibrary.ProjectSavedDir(),
        "PhotoScreenshots"
      })) or bHasContents
    else
      local RootDir = UE.UBlueprintPathsLibrary.RootDir()
      local RootPath = UE.UNRCStatics.GetPath(RootDir)
      local DstScreenShotDirPath = UE.UBlueprintPathsLibrary.Combine({
        RootPath,
        "Screenshots"
      })
      bHasContents = RepairToolsUtils.CleanFolder(DstScreenShotDirPath) or bHasContents
    end
  end
  bHasContents = RepairToolsUtils.CleanLogs() or bHasContents
  Log.Debug("CleanPlatformCache", bHasContents)
  return bHasContents
end

function RepairToolsUtils.CleanLogs()
  local bHasContents = false
  local Files = UE.UNRCStatics.ListFiles(UE4.UBlueprintPathsLibrary.ProjectSavedDir(), "*.log")
  for _, File in tpairs(Files) do
    local bNRCLog = string.find(File, "NRC%.log")
    if not bNRCLog then
      Log.Debug("DeleteToFile", File)
      bHasContents = UE.UNRCStatics.DeleteToFile(File)
    end
  end
  Files = UE.UNRCStatics.ListFiles(UE4.UBlueprintPathsLibrary.ProjectSavedDir(), "*.logcompr")
  if RocoEnv.PLATFORM_WINDOWS then
    for _, File in tpairs(Files) do
      Log.Debug("DeleteToFile", File)
      bHasContents = UE.UNRCStatics.DeleteToFile(File)
    end
  else
    Files = Files:ToTable()
    local GetFileStamp = UEGetFileDateTime
    table.sort(Files, function(a, b)
      return GetFileStamp(a) > GetFileStamp(b)
    end)
    for i = 2, #Files do
      Log.Debug("DeleteToFile", Files[i])
      bHasContents = UE.UNRCStatics.DeleteToFile(Files[i])
    end
  end
  return bHasContents
end

function RepairToolsUtils.CleanFolder(Folder)
  local bHasContents = false
  if UE.UNRCStatics.DirectoryExists(Folder) then
    local Files = UE.UNRCStatics.ListFiles(Folder, "*.*")
    if Files:Num() > 0 then
      bHasContents = true
    end
    Log.Debug("RemoveFolder", Folder, "Files:", Files:Num())
    UE4.UNRCStatics.RemoveFolder(Folder)
  end
  return bHasContents
end

return RepairToolsUtils

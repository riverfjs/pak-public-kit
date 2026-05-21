local PhotoCacheDefine = {}
PhotoCacheDefine.Tags = {
  PhotoActivity = "PhotoActivity",
  CardPhotos = "CardPhotos"
}
PhotoCacheDefine.MaxiPhotoRecently = {
  [PhotoCacheDefine.Tags.PhotoActivity] = _G.DEBUG_PHOTO_CACHE_NUM or 40,
  [PhotoCacheDefine.Tags.CardPhotos] = 10
}

function PhotoCacheDefine.GetTagFileFullPath(Tag, FileName)
  local FullPath = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "CommonUrlImages",
    Tag,
    FileName
  })
  FullPath = UE.UBlueprintPathsLibrary.ConvertRelativePathToFull(FullPath)
  return FullPath
end

function PhotoCacheDefine.UpdateFileCaches()
  local CardPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "CardPhotos"
  })
  if UE.UNRCStatics.DirectoryExists(CardPhotos) then
    UE.UNRCStatics.RemoveFolder(CardPhotos)
  end
  local GetFileStamp = UEGetFileDateTime
  local CommonUrlImages = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "CommonUrlImages"
  })
  for Tag, CacheNum in pairs(PhotoCacheDefine.MaxiPhotoRecently) do
    local FullPath = UE.UBlueprintPathsLibrary.Combine({CommonUrlImages, Tag})
    FullPath = UE.UBlueprintPathsLibrary.ConvertRelativePathToFull(FullPath)
    local Files = UE.UNRCStatics.ListFiles(FullPath, "*.*")
    if CacheNum < Files:Num() then
      Files = Files:ToTable()
      table.sort(Files, function(a, b)
        return GetFileStamp(a) > GetFileStamp(b)
      end)
      for i = CacheNum + 1, #Files do
        local PhotoFile = Files[i]
        UE.UNRCStatics.DeleteToFile(PhotoFile)
        Log.Debug("[PhotoCacheDefine] UpdateFileCache Delete", PhotoFile, "By", Tag, CacheNum)
      end
    end
  end
end

return PhotoCacheDefine

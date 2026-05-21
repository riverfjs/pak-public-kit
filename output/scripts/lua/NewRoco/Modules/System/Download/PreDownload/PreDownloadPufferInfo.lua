local PreDownloadPufferInfo = Class("PreDownloadPufferInfo")
local JsonUtils = require("Common.JsonUtils")
local VideoEnum = require("Common.VideoEnum")
local PakSourceType = require("NewRoco.Modules.System.UpdateUIModule.PakSourceType")

function PreDownloadPufferInfo:Ctor()
  self.bInited = false
  self:Clear()
  self.bLowEnd = _G.MediaUtils.ComputeVideoLevelByDeviceLevel() == VideoEnum.VideoLevel.SD
  Log.Debug("[PreDownloadPufferInfo:Ctor] bLowEnd:", self.bLowEnd)
end

function PreDownloadPufferInfo:Init(PufferImpl, PufferConfigPath, ResVerifyPath)
  self.PufferInstance = PufferImpl
  if not self:InitPufferPakInfoJson(PufferConfigPath) then
    return false
  end
  if not self:InitResVerifyJson(ResVerifyPath) then
    return false
  end
  self:CacheDownloadInfo()
  self.bInited = true
  return true
end

function PreDownloadPufferInfo:InitPufferPakInfoJson(PufferConfigPath)
  local JsonData, bSuccess = UE4.UHotUpdateUtils.ReadEncryptedJsonData(PufferConfigPath)
  if bSuccess then
    local JsonObject = JsonUtils.StringToJson(JsonData)
    if JsonObject then
      return self:InitPufferPakInfoList(JsonObject)
    else
      Log.Error("[PreDownloadPufferInfo:InitPufferPakInfoJson] JsonObject is nil")
      return false
    end
  else
    Log.Error("[PreDownloadPufferInfo:InitPufferPakInfoJson] ReadEncryptedJsonData failed")
    return false
  end
end

function PreDownloadPufferInfo:InitResVerifyJson(ResVerifyPath)
  local JsonData, bSuccess = UE4.UHotUpdateUtils.ReadEncryptedJsonData(ResVerifyPath)
  if bSuccess then
    local JsonObject = JsonUtils.StringToJson(JsonData)
    if JsonObject then
      return self:InitResVerifyMap(JsonObject)
    else
      Log.Error("[PreDownloadPufferInfo:InitResVerifyJson] JsonObject is nil")
      return false
    end
  else
    Log.Error("[PreDownloadPufferInfo:InitResVerifyJson] ReadEncryptedJsonData failed")
    return false
  end
end

function PreDownloadPufferInfo:InitPufferPakInfoList(JsonObject)
  local bSuccess = false
  if JsonObject then
    if JsonObject.Content then
      local PakInfoList = JsonObject.Content.PakInfoList
      if PakInfoList then
        if type(PakInfoList) == "table" then
          self.PufferPakInfoList = PakInfoList
          self:NormalizeAllPufferPath(self.PufferPakInfoList)
          bSuccess = self:InitHDChunkMap()
        else
          Log.Error("[PreDownloadPufferInfo:InitPufferPakInfoList] PakInfoList is not table")
        end
      else
        Log.Error("[PreDownloadPufferInfo:InitPufferPakInfoList] PakInfoList is nil")
      end
    else
      Log.Error("[PreDownloadPufferInfo:InitPufferPakInfoList] Content is nil")
    end
  else
    Log.Error("[PreDownloadPufferInfo:InitPufferPakInfoList] JsonObject is nil")
  end
  return bSuccess
end

function PreDownloadPufferInfo:NormalizeAllPufferPath(PakInfoList)
  if PakInfoList then
    for _, PakInfo in ipairs(PakInfoList) do
      if PakInfo then
        if not string.IsNilOrEmpty(PakInfo.PakName) then
          PakInfo.PakName = self:NormalizeFilename(PakInfo.PakName)
        end
        if not string.IsNilOrEmpty(PakInfo.HDPakName) then
          PakInfo.HDPakName = self:NormalizeFilename(PakInfo.HDPakName)
        end
      end
    end
  end
end

function PreDownloadPufferInfo:InitResVerifyMap(JsonObject)
  local bSuccess = false
  self.ResVerifyMap = {}
  if JsonObject then
    if JsonObject.Content then
      local ResVerifyList = JsonObject.Content.Paks
      if ResVerifyList then
        if type(ResVerifyList) == "table" then
          for _, PakInfo in ipairs(ResVerifyList) do
            self.ResVerifyMap[PakInfo.Name] = PakInfo
          end
          bSuccess = true
        else
          Log.Error("[PreDownloadPufferInfo:InitResVerifyMap] ResVerifyList is not table")
        end
      else
        Log.Error("[PreDownloadPufferInfo:InitResVerifyMap] ResVerifyList is nil")
      end
    else
      Log.Error("[PreDownloadPufferInfo:InitResVerifyMap] Content is nil")
    end
  else
    Log.Error("[PreDownloadPufferInfo:InitResVerifyMap] JsonObject is nil")
  end
  return bSuccess
end

function PreDownloadPufferInfo:GetHashByName(Name)
  if self.ResVerifyMap then
    local PakInfo = self.ResVerifyMap[Name]
    if PakInfo then
      return PakInfo.Hash
    end
  end
end

function PreDownloadPufferInfo:NormalizeFilename(Name)
  return string.gsub(Name, "\\", "/")
end

function PreDownloadPufferInfo:InitHDChunkMap()
  if not self.PufferPakInfoList then
    return
  end
  local bSuccess = false
  self.HDChunkMap = {}
  self.SDChunkMap = {}
  for _, PakInfo in ipairs(self.PufferPakInfoList) do
    if PakInfo and PakInfo.HDPakName and PakInfo.ChunkID then
      bSuccess = true
      local SDChunk = PakInfo.ChunkID
      local HDChunk = self:GetChunkIDByPakFileName(PakInfo.HDPakName)
      Log.Debug(string.format("[PreDownloadPufferInfo:InitHDChunkMap] Add HDChunk:%s SDChunk:%s", HDChunk, SDChunk))
      self.SDChunkMap[SDChunk] = 1
      self.HDChunkMap[HDChunk] = 1
    end
  end
  Log.Debug("[PreDownloadPufferInfo:InitHDChunkMap] InitHDChunkMap ", bSuccess)
  return bSuccess
end

function PreDownloadPufferInfo:CacheDownloadInfo()
  local PakPatchList, NonPakPatchList = self:CacheAllPatchList()
  local DifferentBasePakList = self:CacheDifferentBasePakList()
  self.AllResList = {}
  if NonPakPatchList then
    for _, Path in ipairs(NonPakPatchList) do
      table.insert(self.AllResList, Path)
      Log.Debug("[PreDownloadPufferInfo:CacheDownloadInfo] add non pak patch:", Path)
    end
  end
  if PakPatchList then
    for _, Path in ipairs(PakPatchList) do
      table.insert(self.AllResList, Path)
      Log.Debug("[PreDownloadPufferInfo:CacheDownloadInfo] add pak patch:", Path)
    end
  end
  if DifferentBasePakList then
    for _, Path in ipairs(DifferentBasePakList) do
      table.insert(self.AllResList, Path)
      Log.Debug("[PreDownloadPufferInfo:CacheDownloadInfo] add different base pak:", Path)
    end
  end
end

function PreDownloadPufferInfo:Clear()
  Log.Debug("[PreDownloadPufferInfo:Clear]")
  self.bInited = false
  self.PufferInstance = nil
  self.AllResList = nil
  self.HDChunkMap = nil
  self.SDChunkMap = nil
  self.ResVerifyMap = nil
  self.PufferPakInfoList = nil
end

function PreDownloadPufferInfo:CacheAllPatchList()
  local PakPatchList = {}
  local NonPakPatchList = {}
  local AllPatchList = self:GetPakListByPakType(PakSourceType.NecessaryPatch)
  if AllPatchList and #AllPatchList > 0 then
    for _, Path in ipairs(AllPatchList) do
      local bIsPak = string.match(Path, "%.pak$") ~= nil
      if bIsPak then
        local ChunkID = self:GetChunkIDByPakFileName(Path)
        Log.Debug("[PreDownloadPufferInfo:CacheAllPatchList] ChunkID:", ChunkID)
        if self:IsHDChunk(ChunkID) and not self.bLowEnd then
          table.insert(PakPatchList, Path)
          Log.Debug("[PreDownloadPufferInfo:CacheAllPatchList] add HD patch pak:", Path)
        elseif self:IsSDChunk(ChunkID) and self.bLowEnd then
          table.insert(PakPatchList, Path)
          Log.Debug("[PreDownloadPufferInfo:CacheAllPatchList] add SD patch pak:", Path)
        else
          table.insert(PakPatchList, Path)
          Log.Debug("[PreDownloadPufferInfo:CacheAllPatchList] add patch pak:", Path)
        end
      else
        table.insert(NonPakPatchList, Path)
        Log.Debug("[PreDownloadPufferInfo:CacheAllPatchList] add non pak patch:", Path)
      end
    end
  end
  return PakPatchList, NonPakPatchList
end

function PreDownloadPufferInfo:CacheDifferentBasePakList()
  local DifferentBasePakList = {}
  if self.PufferPakInfoList then
    for _, PakInfo in ipairs(self.PufferPakInfoList) do
      if PakInfo.SourceType ~= PakSourceType.NecessaryPatch then
        local LatestPakName = PakInfo.PakName
        if LatestPakName then
          local CleanFileName = UE.UBlueprintPathsLibrary.GetCleanFilename(LatestPakName)
          local CurrentHash = _G.PufferDownloadInfo:GetHashByName(CleanFileName)
          Log.Debug(string.format("[PreDownloadPufferInfo:CacheDifferentBasePakList] %s, CurrentHash:%s", CleanFileName, CurrentHash))
          if CurrentHash then
            local NewHash = self:GetHashByName(CleanFileName)
            Log.Debug(string.format("[PreDownloadPufferInfo:CacheDifferentBasePakList] %s, CurrentHash:%s, NewHash:%s", CleanFileName, CurrentHash, NewHash))
            if NewHash ~= CurrentHash then
              table.insert(DifferentBasePakList, LatestPakName)
              Log.Debug("[PreDownloadPufferInfo:CacheDifferentBasePakList] add different pak:", LatestPakName)
            end
          else
            table.insert(DifferentBasePakList, LatestPakName)
            Log.Debug("[PreDownloadPufferInfo:CacheDifferentBasePakList] add new pak:", LatestPakName)
          end
        else
          Log.Error("[PreDownloadPufferInfo:CacheDifferentBasePakList] PakInfo.PakName is nil")
        end
      end
    end
  else
    Log.Error("[PreDownloadPufferInfo:CacheDifferentBasePakList] PufferPakInfoList is nil")
  end
  return DifferentBasePakList
end

function PreDownloadPufferInfo:IsHDChunk(ChunkID)
  if self.HDChunkMap then
    return self.HDChunkMap[ChunkID]
  end
  return false
end

function PreDownloadPufferInfo:IsSDChunk(ChunkID)
  if self.SDChunkMap then
    return self.SDChunkMap[ChunkID]
  end
  return false
end

function PreDownloadPufferInfo:GetAllResList()
  if not self.bInited then
    Log.Error("PreDownloadPufferInfo is not inited")
    return
  end
  return self.AllResList
end

function PreDownloadPufferInfo:GetChunkIDByPakFileName(PufferFileName)
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  return self.PufferInstance:GetChunkIDByPakFileName(PufferFileName)
end

function PreDownloadPufferInfo:GetPakListByPakType(PakType)
  if not self.PufferInstance then
    Log.Error("PufferInstance is invalid")
    return
  end
  local PakFileList = self.PufferInstance:GetPakFileList(PakType)
  if not PakFileList then
    Log.Error("PakFileList is invalid")
    return
  end
  Log.Debug("[PreDownloadPufferInfo:GetPakListByPakType] Type: ", PakType)
  local PakFileArray = {}
  for _, PakFile in tpairs(PakFileList) do
    Log.Debug("[PreDownloadPufferInfo:GetPakListByPakType] PakFile: ", PakFile)
    table.insert(PakFileArray, PakFile)
  end
  return PakFileArray
end

return PreDownloadPufferInfo

local PufferDownloadInfo = Class("PufferDownloadInfo")
local JsonUtils = require("Common.JsonUtils")
local VideoEnum = require("Common.VideoEnum")
local PakSourceType = require("NewRoco.Modules.System.UpdateUIModule.PakSourceType")

function PufferDownloadInfo:Ctor()
  self.bInited = false
  self:Clear()
  self.bLowEnd = _G.MediaUtils.ComputeVideoLevelByDeviceLevel() == VideoEnum.VideoLevel.SD
  Log.Debug("[PufferDownloadInfo:Ctor] bLowEnd:", self.bLowEnd)
end

function PufferDownloadInfo:Init(PufferImpl, PufferConfigPath, ResVerifyPath)
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

function PufferDownloadInfo:InitPufferPakInfoJson(PufferConfigPath)
  local JsonData, bSuccess = UE4.UHotUpdateUtils.ReadEncryptedJsonData(PufferConfigPath)
  if bSuccess then
    local JsonObject = JsonUtils.StringToJson(JsonData)
    if JsonObject then
      self:InitPufferPakInfoList(JsonObject)
      return true
    else
      Log.Error("[PufferDownloadInfo:InitPufferPakInfoJson] JsonObject is nil")
      return false
    end
  else
    Log.Error("[PufferDownloadInfo:InitPufferPakInfoJson] ReadEncryptedJsonData failed")
    return false
  end
end

function PufferDownloadInfo:InitResVerifyJson(ResVerifyPath)
  local JsonData, bSuccess = UE4.UHotUpdateUtils.ReadEncryptedJsonData(ResVerifyPath)
  if bSuccess then
    local JsonObject = JsonUtils.StringToJson(JsonData)
    if JsonObject then
      self:InitResVerifyMap(JsonObject)
      return true
    else
      Log.Error("[PufferDownloadInfo:InitResVerifyJson] JsonObject is nil")
      return false
    end
  else
    Log.Error("[PufferDownloadInfo:InitResVerifyJson] ReadEncryptedJsonData failed")
    return false
  end
end

function PufferDownloadInfo:InitPufferPakInfoList(JsonObject)
  if JsonObject then
    if JsonObject.Content then
      local PakInfoList = JsonObject.Content.PakInfoList
      if PakInfoList then
        if type(PakInfoList) == "table" then
          self.PufferPakInfoList = PakInfoList
          self:NormalizeAllPufferPath(self.PufferPakInfoList)
          self:InitHDMap()
        else
          Log.Error("[PufferDownloadInfo:InitPufferPakInfoList] PakInfoList is not table")
        end
      else
        Log.Error("[PufferDownloadInfo:InitPufferPakInfoList] PakInfoList is nil")
      end
      self:CacheShaderPatchList(JsonObject.Content.ShaderPatchList)
    else
      Log.Error("[PufferDownloadInfo:InitPufferPakInfoList] Content is nil")
    end
  else
    Log.Error("[PufferDownloadInfo:InitPufferPakInfoList] JsonObject is nil")
  end
end

function PufferDownloadInfo:InitResVerifyMap(JsonObject)
  self.ResVerifyMap = {}
  if JsonObject then
    if JsonObject.Content then
      local ResVerifyList = JsonObject.Content.Paks
      if ResVerifyList then
        if type(ResVerifyList) == "table" then
          for _, PakInfo in ipairs(ResVerifyList) do
            self.ResVerifyMap[PakInfo.Name] = PakInfo
            Log.Debug(string.format("[PufferDownloadInfo:InitResVerifyMap] Add PakName:%s Hash:%s", PakInfo.Name, PakInfo.Hash))
          end
        else
          Log.Error("[PufferDownloadInfo:InitResVerifyMap] ResVerifyList is not table")
        end
      else
        Log.Error("[PufferDownloadInfo:InitResVerifyMap] ResVerifyList is nil")
      end
    else
      Log.Error("[PufferDownloadInfo:InitResVerifyMap] Content is nil")
    end
  else
    Log.Error("[PufferDownloadInfo:InitResVerifyMap] JsonObject is nil")
  end
end

function PufferDownloadInfo:GetHashByName(Name)
  if self.ResVerifyMap then
    local PakInfo = self.ResVerifyMap[Name]
    if PakInfo then
      return PakInfo.Hash
    end
  end
end

function PufferDownloadInfo:NormalizeAllPufferPath(PakInfoList)
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

function PufferDownloadInfo:NormalizeFilename(Name)
  return string.gsub(Name, "\\", "/")
end

function PufferDownloadInfo:InitHDMap()
  if not self.PufferPakInfoList then
    return
  end
  self.PakNameToHDNameMap = {}
  for _, PakInfo in ipairs(self.PufferPakInfoList) do
    if PakInfo and PakInfo.HDPakName and PakInfo.PakName then
      local PakName = PakInfo.PakName
      local HDPakName = PakInfo.HDPakName
      Log.Debug(string.format("[PufferDownloadInfo:InitHDMap] Add PakName:%s HDPakName:%s", PakName, HDPakName))
      self.PakNameToHDNameMap[PakName] = HDPakName
    end
  end
end

function PufferDownloadInfo:CacheShaderPatchList(ShaderPatchList)
  if not ShaderPatchList then
    Log.Debug("[PufferDownloadInfo:CacheShaderPatchList] ShaderPatchList is nil")
    return
  end
  self.ShaderPatchList = ShaderPatchList
end

function PufferDownloadInfo:GetShaderPatchList()
  return self.ShaderPatchList
end

function PufferDownloadInfo:CacheDownloadInfo()
  self:CacheNonPakPatchList()
  self:CacheContentChunkPatchList()
  self:CacheEarlyContentPakList()
  self:CacheEarlyContentPatchList()
  self:CacheBasePakList()
  self:CacheBasePatchList()
end

function PufferDownloadInfo:Clear()
  Log.Debug("[PufferDownloadInfo:Clear]")
  self.bInited = false
  self.PufferInstance = nil
  self.bHasPatch = false
  self.NonPakPatchList = nil
  self.ContentChunkPatchList = nil
  self.EarlyContentPakList = nil
  self.EarlyContentPatchList = nil
  self.BasePakList = nil
  self.BasePatchList = nil
  self.PakNameToHDNameMap = nil
  self.ShaderPatchList = nil
  self.PufferPakInfoList = nil
  self.ResVerifyMap = nil
end

function PufferDownloadInfo:HasAnyPatch()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.bHasPatch
end

function PufferDownloadInfo:CacheNonPakPatchList()
  local AllPatchList = self:GetPakListByPakType(PakSourceType.NecessaryPatch)
  if AllPatchList and #AllPatchList > 0 then
    self.bHasPatch = true
    self.NonPakPatchList = {}
    for _, Path in ipairs(AllPatchList) do
      local bIsPak = string.match(Path, "%.pak$") ~= nil
      if not bIsPak then
        Log.Debug("[PufferDownloadInfo:CacheNonPakPatchList] add non pak patch:", Path)
        table.insert(self.NonPakPatchList, Path)
      end
    end
  end
end

function PufferDownloadInfo:CacheContentChunkPatchList()
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  local ChunkPatchTarray = self.PufferInstance:GetContentChunkPatchList()
  if ChunkPatchTarray then
    self.ContentChunkPatchList = {}
    for _, PatchFile in tpairs(ChunkPatchTarray) do
      table.insert(self.ContentChunkPatchList, PatchFile)
      Log.Debug("[PufferDownloadInfo:CacheContentChunkPatchList] add content chunk patch:", PatchFile)
    end
  else
    Log.Debug("[PufferDownloadInfo:CacheContentChunkPatchList] ChunkPatchTarray is nil")
  end
end

function PufferDownloadInfo:CacheEarlyContentPakList()
  local OriPakList = self:GetPakListByPakType(PakSourceType.EarlyContent)
  self.EarlyContentPakList = {}
  if OriPakList then
    for _, PufferFileName in pairs(OriPakList) do
      if self.bLowEnd then
        table.insert(self.EarlyContentPakList, PufferFileName)
        Log.Debug("[PufferDownloadInfo:CacheEarlyContentPakList] add earlycontent pak:", PufferFileName)
      else
        local HDPakName = self:GetHDPakName(PufferFileName)
        if HDPakName then
          table.insert(self.EarlyContentPakList, HDPakName)
          Log.Debug("[PufferDownloadInfo:CacheEarlyContentPakList] add earlycontent HD pak:", HDPakName)
        else
          table.insert(self.EarlyContentPakList, PufferFileName)
          Log.Debug("[PufferDownloadInfo:CacheEarlyContentPakList] add earlycontent pak:", PufferFileName)
        end
      end
    end
  else
    Log.Error("[PufferDownloadInfo:CacheEarlyContentPakList] OriPakList is nil")
  end
end

function PufferDownloadInfo:CacheEarlyContentPatchList()
  if not self.EarlyContentPakList then
    Log.Error("EarlyContentPakList is nil")
    return
  end
  self.EarlyContentPatchList = {}
  local ChunkIDSet = {}
  for _, PufferFileName in pairs(self.EarlyContentPakList) do
    local ChunkID = self:GetChunkIDByPakFileName(PufferFileName)
    if ChunkID and ChunkID >= 0 then
      if not ChunkIDSet[ChunkID] then
        ChunkIDSet[ChunkID] = 1
        local ChunkPatchTarray = self:GetPatchListByChunkID(ChunkID)
        if ChunkPatchTarray then
          for _, PatchFile in tpairs(ChunkPatchTarray) do
            table.insert(self.EarlyContentPatchList, PatchFile)
            Log.Debug("[PufferDownloadInfo:CacheEarlyContentPatchList] add early content patch:", PatchFile)
          end
        else
          Log.Error("[PufferDownloadInfo:CacheEarlyContentPatchList] ChunkPatchTarray is nil")
        end
      end
    else
      Log.Error("[PufferDownloadInfo:CacheEarlyContentPatchList] ChunkID is invalid:", PufferFileName or "nil")
    end
  end
end

function PufferDownloadInfo:CacheBasePakList()
  local OriBasePakList = self:GetPakListByPakType(PakSourceType.Base)
  self.BasePakList = {}
  if OriBasePakList then
    for _, PufferFileName in pairs(OriBasePakList) do
      if self.bLowEnd then
        table.insert(self.BasePakList, PufferFileName)
        Log.Debug("[PufferDownloadInfo:CacheBasePakList] add base pak:", PufferFileName)
      else
        local HDPakName = self:GetHDPakName(PufferFileName)
        if HDPakName then
          table.insert(self.BasePakList, HDPakName)
          Log.Debug("[PufferDownloadInfo:CacheBasePakList] add base HD pak:", HDPakName)
        else
          table.insert(self.BasePakList, PufferFileName)
          Log.Debug("[PufferDownloadInfo:CacheBasePakList] add base pak:", PufferFileName)
        end
      end
    end
  else
    Log.Error("[PufferDownloadInfo:CacheBasePakList] OriBasePakList is nil")
  end
end

function PufferDownloadInfo:CacheBasePatchList()
  if not self.BasePakList then
    Log.Error("BasePakList is nil")
    return
  end
  local ChunkIDSet = {}
  self.BasePatchList = {}
  for _, PufferFileName in pairs(self.BasePakList) do
    local ChunkID = self:GetChunkIDByPakFileName(PufferFileName)
    if ChunkID and ChunkID >= 0 then
      if not ChunkIDSet[ChunkID] then
        ChunkIDSet[ChunkID] = 1
        local ChunkPatchTarray = self:GetPatchListByChunkID(ChunkID)
        if ChunkPatchTarray then
          for _, PatchFile in tpairs(ChunkPatchTarray) do
            table.insert(self.BasePatchList, PatchFile)
            Log.Debug("[PufferDownloadInfo:CacheBasePatchList] add base patch:", PatchFile)
          end
        else
          Log.Error("[PufferDownloadInfo:CacheBasePatchList] ChunkPatchTarray is nil")
        end
      end
    else
      Log.Error("[PufferDownloadInfo:CacheBasePatchList] ChunkID is invalid:", PufferFileName or "nil")
    end
  end
end

function PufferDownloadInfo:GetHDPakName(PakName)
  if not self.PakNameToHDNameMap then
    Log.Error("PakNameToHDNameMap is nil")
    return nil
  end
  return self.PakNameToHDNameMap[PakName]
end

function PufferDownloadInfo:GetAllPatchList()
  return self:GetPakListByPakType(PakSourceType.NecessaryPatch)
end

function PufferDownloadInfo:GetNonPakPatchList()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.NonPakPatchList
end

function PufferDownloadInfo:GetContentChunkPatchList()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.ContentChunkPatchList
end

function PufferDownloadInfo:GetEarlyContentPakList()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.EarlyContentPakList
end

function PufferDownloadInfo:GetEarlyContentPatchList()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.EarlyContentPatchList
end

function PufferDownloadInfo:GetEarlyContentPakListWithPatch()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  local BasePakList = self:GetEarlyContentPakList()
  local PatchList = self:GetEarlyContentPatchList()
  local ReturnList = {}
  if BasePakList then
    for _, PakFile in pairs(BasePakList) do
      table.insert(ReturnList, PakFile)
    end
  end
  if PatchList then
    for _, PatchFile in pairs(PatchList) do
      table.insert(ReturnList, PatchFile)
    end
  end
  return ReturnList
end

function PufferDownloadInfo:GetBasePakList()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.BasePakList
end

function PufferDownloadInfo:GetBasePatchList()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  return self.BasePatchList
end

function PufferDownloadInfo:GetBasePakListWithPatch()
  if not self.bInited then
    Log.Error("PufferDownloadInfo is not inited")
  end
  local BasePakList = self:GetBasePakList()
  local PatchList = self:GetBasePatchList()
  local ReturnList = {}
  if PatchList then
    for _, PatchFile in pairs(PatchList) do
      table.insert(ReturnList, PatchFile)
    end
  end
  if BasePakList then
    for _, PakFile in pairs(BasePakList) do
      table.insert(ReturnList, PakFile)
    end
  end
  return ReturnList
end

function PufferDownloadInfo:GetLocalDownloadedChunkPatchList()
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  local ChunkIDSet = self:GetDownloadedChunkIDList()
  local PakFileList = {}
  local ChunkPatchTarray
  for ChunkID, _ in pairs(ChunkIDSet) do
    ChunkPatchTarray = self:GetPatchListByChunkID(ChunkID)
    for _, File in tpairs(ChunkPatchTarray) do
      table.insert(PakFileList, File)
      Log.Debug(string.format("[PufferDownloadInfo:GetLocalDownloadedChunkPatchList] [%d]File:%s", ChunkID, File))
    end
  end
  return PakFileList
end

function PufferDownloadInfo:GetDownloadedChunkIDList()
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  local PufferPakDir = self:GetRelativePufferPakDir()
  local LocalPakTArray = UE.UNRCStatics.FindFiles(PufferPakDir, "*.pak")
  local ChunkIDSet = {}
  for _, PakFile in tpairs(LocalPakTArray) do
    local lowerName = string.lower(PakFile)
    local ChunkID = string.match(lowerName, "pakchunk(%d+)")
    if ChunkID then
      ChunkIDSet[ChunkID] = 1
      Log.Debug(string.format("[PufferDownloadInfo:GetDownloadedChunkIDList] %s get chunkID:%s", PakFile, ChunkID))
    else
      Log.Error("[PufferDownloadInfo:GetDownloadedChunkIDList] ChunkID match failed:", PakFile)
    end
  end
  return ChunkIDSet
end

function PufferDownloadInfo:GetAllPakFileList()
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  return self.PufferInstance:GetAllPakFileList()
end

function PufferDownloadInfo:GetPatchListByChunkID(ChunkID)
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  return self.PufferInstance:GetPatchListByChunkID(ChunkID)
end

function PufferDownloadInfo:GetShaderPatchPakList()
  local ChunkPatchTarray = self:GetPatchListByChunkID(2)
  local ShaderPatchPakList = {}
  if ChunkPatchTarray then
    for _, PatchFile in tpairs(ChunkPatchTarray) do
      table.insert(ShaderPatchPakList, PatchFile)
      Log.Debug("[PufferDownloadInfo:GetShaderPatchPakList] add shader patch:", PatchFile)
    end
  else
    Log.Error("[PufferDownloadInfo:CacheEarlyContentPatchList] ChunkPatchTarray is nil")
  end
  return ShaderPatchPakList
end

function PufferDownloadInfo:GetChunkIDByPakFileName(PufferFileName)
  if not self.PufferInstance then
    Log.Error("PufferInstance is nil")
    return
  end
  return self.PufferInstance:GetChunkIDByPakFileName(PufferFileName)
end

function PufferDownloadInfo:GetPakListByPakType(PakType)
  if not self.PufferInstance then
    Log.Error("PufferInstance is invalid")
    return
  end
  local PakFileList = self.PufferInstance:GetPakFileList(PakType)
  if not PakFileList then
    Log.Error("PakFileList is invalid")
    return
  end
  Log.Debug("[PufferDownloadInfo:GetPakListByPakType] Type: ", PakType)
  local PakFileArray = {}
  for _, PakFile in tpairs(PakFileList) do
    Log.Debug("[PufferDownloadInfo:GetPakListByPakType] PakFile: ", PakFile)
    table.insert(PakFileArray, PakFile)
  end
  return PakFileArray
end

function PufferDownloadInfo:GetRelativePufferPakDir()
  return UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    "Puffer",
    "Paks"
  })
end

return PufferDownloadInfo

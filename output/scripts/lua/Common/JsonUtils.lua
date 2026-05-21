local rapidjson = require("rapidjson")
local JsonUtils = {}

function JsonUtils.StringToJson(stringData)
  if stringData then
    return rapidjson.decode(stringData)
  end
end

function JsonUtils.LoadSaved(FileName, Default)
  local File = string.format("%s%s.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result) or Default
  else
    return Default
  end
end

function JsonUtils.LoadSpecifiedPath(Path, Default)
  local File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(Path)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result) or Default
  else
    return Default
  end
end

function JsonUtils.DumpSpecifiedPath(Path, Table, MaxiLimit)
  local File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(Path)
  Table = JsonUtils.ExtractTable(Table, nil, MaxiLimit)
  local Content = rapidjson.encode(Table)
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success
end

function JsonUtils.LoadSavedFromAutoBattle(FileName, Default)
  local File = string.format("%sScript/Data/AutoBattle/%s.non", UE4.UBlueprintPathsLibrary.ProjectContentDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result) or Default
  else
    Log.Error("LoadSavedFromAutoBattle error ", File)
    return Default
  end
end

JsonUtils.IgnoreKeys = {
  "class",
  "_eventDispatcher",
  "Super",
  "InstanceOf",
  "__call",
  "__index",
  "__newindex",
  "SubclassOf",
  "New",
  "Extend",
  "Initialize",
  "SendEvent",
  "AddEventListener",
  "RemoveEventListener",
  "RemoveAllListeners",
  "RemoveListeners"
}

function JsonUtils.ExtractTable(Anything, Visited, Limit, IgnoreFunction)
  Visited = Visited or {}
  Limit = Limit or 10
  if 0 == Limit then
    return "** too deep **"
  end
  if nil == IgnoreFunction then
    IgnoreFunction = false
  end
  local Type = type(Anything)
  if "table" == Type then
    local Key = tostring(Anything)
    if Visited[Key] then
      return Key
    end
    Visited[tostring(Anything)] = Anything
    Anything = _G.BinDataUtils.BinDataUnboxing(Anything, true)
    Limit = Limit - 1
    local New = {}
    for K, V in pairs(Anything) do
      if table.contains(JsonUtils.IgnoreKeys, K) then
      else
        New[K] = JsonUtils.ExtractTable(V, Visited, Limit, IgnoreFunction)
      end
    end
    return New
  elseif "userdata" == Type then
    return tostring(Anything)
  elseif "function" == Type then
    if IgnoreFunction then
      return nil
    else
      return tostring(Anything)
    end
  else
    return Anything
  end
end

function JsonUtils.DumpSaved(FileName, Table, MaxiLimit)
  local File = string.format("%s%s.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  Table = JsonUtils.ExtractTable(Table, nil, MaxiLimit)
  local Content = rapidjson.encode(Table)
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success
end

function JsonUtils.DumpSavedSortKey(FileName, Table, Limit)
  local File = string.format("%s%s.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  Table = JsonUtils.ExtractTable(Table, {}, Limit)
  local Content = rapidjson.encode(Table, {pretty = true, sort_keys = true})
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success, File
end

function JsonUtils.EncodeTable(InTable)
  if InTable and (type(InTable) == "table" or type(InTable) == "userdata") then
    return rapidjson.encode(InTable)
  end
  return InTable
end

function JsonUtils.DumpCameraSettings(FileName, Table)
  local File = string.format("%sData/BattleCamera/%s.json", UE4.URocoBlueprintPathsLibrary.ProjectScriptDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Content = rapidjson.encode(Table)
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success
end

function JsonUtils.LoadCameraSettings(FileName, Default)
  local File = string.format("%sData/BattleCamera/%s.cam", UE4.UNRCStatics.ProjectScriptDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result)
  else
    Log.Error("JsonUtils.LoadCameraSettings\239\188\154Success=false, File=", File)
    return Default
  end
end

function JsonUtils.DumpDefaultServerList(Table)
  local File = string.format("%sDefaultServerList.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir())
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Content = rapidjson.encode(Table)
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success
end

function JsonUtils.LoadDefaultServerList(Default)
  local File = string.format("%sDefaultServerList.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir())
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result) or Default
  else
    local BackUpFile = string.format("%sNewRoco/DataConfig/DefaultServerList.json", UE4.UBlueprintPathsLibrary.ProjectContentDir())
    File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(BackUpFile)
    Result, Success = UE4.UNRCStatics.LoadToString(BackUpFile)
    if Success then
      return rapidjson.decode(Result) or Default
    else
      return Default
    end
  end
end

function JsonUtils.DeleteFile(FileName)
  local File = string.format("%s%s.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Success = UE4.UNRCStatics.DeleteToFile(File)
  return Success
end

function JsonUtils.LoadSavedFromBattleFsm(FileName, Default)
  local File = string.format("%sScript/Data/BattleFsm/%s.json", UE4.UBlueprintPathsLibrary.ProjectContentDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result)
  else
    return Default
  end
end

function JsonUtils.DumpBattleFsmSaved(FileName, Table)
  local File = string.format("%sScript/Data/BattleFsm/%s.json", UE4.UBlueprintPathsLibrary.ProjectContentDir(), FileName)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Content = rapidjson.encode(Table)
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success
end

function JsonUtils.LoadAllDebugBattleTemp(dirName)
  local dirPath = string.format("%s%s", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), dirName)
  local temps = UE.UNRCStatics.ListFiles(dirPath, "*.json")
  local filePaths = temps:ToTable()
  local fileList = {}
  for i, v in pairs(filePaths) do
    local Result, Success = UE4.UNRCStatics.LoadToString(v)
    if Success then
      table.insert(fileList, rapidjson.decode(Result))
    end
  end
  return fileList
end

function JsonUtils.LoadBinMD5Non(Default)
  Default = Default or {}
  local File = string.format("%sScript/Data/Bin/md5.non", UE4.UBlueprintPathsLibrary.ProjectContentDir())
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result)
  else
    return Default
  end
end

function JsonUtils.LoadSavedFromStarLight(FileName, Default)
  local File = string.format("%sNewRoco/DataConfig/StarLight/%s.json", UE4.UBlueprintPathsLibrary.ProjectContentDir(), FileName)
  local Result, Success = UE4.UNRCStatics.LoadToString(File)
  if Success then
    return rapidjson.decode(Result) or Default
  else
    Log.Error("LoadSavedFromStarLight error ", File)
    return Default
  end
end

function JsonUtils.DumpStarLightSaved(FileName, Table)
  local File = string.format("%sNewRoco/DataConfig/StarLight/%s.json", UE4.UBlueprintPathsLibrary.ProjectContentDir(), FileName)
  local Content = rapidjson.encode(Table)
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  return Success
end

return JsonUtils

local Log = _G.Log
local BattleLog = NRCClass()
BattleLog.LogType = {
  Fsm = "BattleFsm",
  Flow = "BattleFlow",
  Buff = "BattleBuff",
  Player = "BattlePlayer",
  Anim = "BattleAnim",
  Skill = "BattleSkill",
  WJF = "BattleWJF"
}
local _logLevel
local _subSwitches = {
  [BattleLog.LogType.Fsm] = true,
  [BattleLog.LogType.Flow] = true,
  [BattleLog.LogType.Buff] = false,
  [BattleLog.LogType.Player] = false,
  [BattleLog.LogType.Anim] = false,
  [BattleLog.LogType.Skill] = false,
  [BattleLog.LogType.WJF] = false
}
local _cache = {}
local _cacheMaxSize = 1000
local _cacheCount = 0
local _cacheableTypes = {
  [BattleLog.LogType.Fsm] = true,
  [BattleLog.LogType.Flow] = true
}
local _isEventRegistered = false
local IS_SHIPPING = _G.RocoEnv.IS_SHIPPING
local StrFormat = string.format
local OsDate = os.date
local tInsert = table.insert
local tConcat = table.concat

local function IsSubSwitchEnabled(logType)
  local switch = _subSwitches[logType]
  if nil == switch then
    return true
  end
  return switch
end

local function WriteToCache(logType, level, content)
  if not IS_SHIPPING then
    return
  end
  local shouldCache = false
  if "Warning" == level or "Error" == level then
    shouldCache = true
  elseif _cacheableTypes[logType] then
    shouldCache = true
  end
  if not shouldCache then
    return
  end
  local timestamp = OsDate("%Y-%m-%d %H:%M:%S")
  local entry = StrFormat("[%s][%s][%s] %s", timestamp, level, logType, content)
  if _cacheCount < _cacheMaxSize then
    _cacheCount = _cacheCount + 1
    _cache[_cacheCount] = entry
  else
    table.remove(_cache, 1)
    table.insert(_cache, entry)
  end
end

local function ConcatArgs(...)
  local params = {
    ...
  }
  local parts = {}
  for i = 1, #params do
    parts[i] = tostring(params[i])
  end
  return tConcat(parts, " ")
end

function BattleLog.SetLogLevel(level)
  _logLevel = level
  Log.SetLogLevel(level)
end

function BattleLog.GetLogLevel()
  return _logLevel or Log.GetLogLevel()
end

function BattleLog.SetSubSwitch(logType, enabled)
  _subSwitches[logType] = enabled
end

local function InternalLog(logType, logFunc, logLevel, levelName, ...)
  local content = ConcatArgs(...)
  WriteToCache(logType, levelName, content)
  if logLevel < BattleLog.GetLogLevel() then
    return
  end
  if not IsSubSwitchEnabled(logType) then
    return
  end
  if logFunc == Log.Debug then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogDebug, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Warning then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogWarn, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Error then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogError, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Info then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogInfo, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Trace then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogTrace, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Fatal then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogFatal, 5, StrFormat("[%s] %s", logType, content))
  else
    logFunc(StrFormat("[%s] %s", logType, content))
  end
end

local function InternalLogBrief(logType, logFunc, logLevel, content)
  if logLevel < BattleLog.GetLogLevel() then
    return
  end
  if not IsSubSwitchEnabled(logType) then
    return
  end
  if logFunc == Log.Debug then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogDebug, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Warning then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogWarn, 5, StrFormat("[%s] %s", logType, content))
  elseif logFunc == Log.Error then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogError, 5, StrFormat("[%s] %s", logType, content))
  else
    logFunc(StrFormat("[%s] %s", logType, content))
  end
end

function BattleLog.FsmDebug(...)
  InternalLog(BattleLog.LogType.Fsm, Log.Debug, Log.LOG_LEVEL.ELogDebug, "Debug", ...)
end

function BattleLog.FsmWarning(...)
  InternalLog(BattleLog.LogType.Fsm, Log.Warning, Log.LOG_LEVEL.ELogWarn, "Warning", ...)
end

function BattleLog.FsmError(...)
  InternalLog(BattleLog.LogType.Fsm, Log.Error, Log.LOG_LEVEL.ELogError, "Error", ...)
end

function BattleLog.FlowDebug(...)
  InternalLog(BattleLog.LogType.Flow, Log.Debug, Log.LOG_LEVEL.ELogDebug, "Debug", ...)
end

function BattleLog.FlowWarning(...)
  InternalLog(BattleLog.LogType.Flow, Log.Warning, Log.LOG_LEVEL.ELogWarn, "Warning", ...)
end

function BattleLog.FlowError(...)
  InternalLog(BattleLog.LogType.Flow, Log.Error, Log.LOG_LEVEL.ELogError, "Error", ...)
end

function BattleLog.BuffDebug(...)
  InternalLog(BattleLog.LogType.Buff, Log.Debug, Log.LOG_LEVEL.ELogDebug, "Debug", ...)
end

function BattleLog.BuffWarning(...)
  InternalLog(BattleLog.LogType.Buff, Log.Warning, Log.LOG_LEVEL.ELogWarn, "Warning", ...)
end

function BattleLog.BuffError(...)
  InternalLog(BattleLog.LogType.Buff, Log.Error, Log.LOG_LEVEL.ELogError, "Error", ...)
end

function BattleLog.PlayerDebug(...)
  InternalLog(BattleLog.LogType.Player, Log.Debug, Log.LOG_LEVEL.ELogDebug, "Debug", ...)
end

function BattleLog.PlayerWarning(...)
  InternalLog(BattleLog.LogType.Player, Log.Warning, Log.LOG_LEVEL.ELogWarn, "Warning", ...)
end

function BattleLog.PlayerError(...)
  InternalLog(BattleLog.LogType.Player, Log.Error, Log.LOG_LEVEL.ELogError, "Error", ...)
end

function BattleLog.AnimDebug(...)
  InternalLog(BattleLog.LogType.Anim, Log.Debug, Log.LOG_LEVEL.ELogDebug, "Debug", ...)
end

function BattleLog.AnimWarning(...)
  InternalLog(BattleLog.LogType.Anim, Log.Warning, Log.LOG_LEVEL.ELogWarn, "Warning", ...)
end

function BattleLog.AnimError(...)
  InternalLog(BattleLog.LogType.Anim, Log.Error, Log.LOG_LEVEL.ELogError, "Error", ...)
end

function BattleLog.SkillDebug(...)
  InternalLog(BattleLog.LogType.Skill, Log.Debug, Log.LOG_LEVEL.ELogDebug, "Debug", ...)
end

function BattleLog.SkillWarning(...)
  InternalLog(BattleLog.LogType.Skill, Log.Warning, Log.LOG_LEVEL.ELogWarn, "Warning", ...)
end

function BattleLog.SkillError(...)
  InternalLog(BattleLog.LogType.Skill, Log.Error, Log.LOG_LEVEL.ELogError, "Error", ...)
end

function BattleLog.WJFDebug(...)
  local content = ConcatArgs(...)
  local coloredContent = StrFormat("[%s] %s", BattleLog.LogType.WJF, content)
  InternalLogBrief(BattleLog.LogType.WJF, Log.Debug, Log.LOG_LEVEL.ELogDebug, coloredContent)
end

function BattleLog.WJFWarning(...)
  local content = ConcatArgs(...)
  local coloredContent = StrFormat("[%s] %s", BattleLog.LogType.WJF, content)
  InternalLogBrief(BattleLog.LogType.WJF, Log.Warning, Log.LOG_LEVEL.ELogWarn, coloredContent)
end

function BattleLog.WJFError(...)
  local content = ConcatArgs(...)
  local coloredContent = StrFormat("[%s] %s", BattleLog.LogType.WJF, content)
  InternalLogBrief(BattleLog.LogType.WJF, Log.Error, Log.LOG_LEVEL.ELogError, coloredContent)
end

function BattleLog.Debug(...)
  if BattleLog.GetLogLevel() > Log.LOG_LEVEL.ELogDebug then
    return
  end
  local content = ConcatArgs(...)
  Log.LogWithLevel(Log.LOG_LEVEL.ELogDebug, 4, StrFormat("[Battle] %s", content))
end

function BattleLog.Warning(...)
  local content = ConcatArgs(...)
  WriteToCache("Battle", "Warning", content)
  if BattleLog.GetLogLevel() <= Log.LOG_LEVEL.ELogWarn then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogWarn, 4, StrFormat("[Battle] %s", content))
  end
end

function BattleLog.Error(...)
  local content = ConcatArgs(...)
  WriteToCache("Battle", "Error", content)
  if BattleLog.GetLogLevel() <= Log.LOG_LEVEL.ELogError then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogError, 4, StrFormat("[Battle] %s", content))
  end
end

function BattleLog.ClearCache()
  _cache = {}
  _cacheCount = 0
end

function BattleLog.GetCacheEntries()
  if 0 == _cacheCount then
    return {}
  end
  local entries = {}
  for i = 1, _cacheCount do
    tInsert(entries, _cache[i])
  end
  return entries
end

function BattleLog.GetCacheText()
  local entries = BattleLog.GetCacheEntries()
  return tConcat(entries, "\n")
end

function BattleLog.GetCacheCount()
  return _cacheCount
end

function BattleLog.UploadCacheToCos()
  if 0 == _cacheCount then
    Log.Warning("[BattleLog] \231\188\147\229\173\152\228\184\186\231\169\186\239\188\140\232\183\179\232\191\135\228\184\138\228\188\160")
    return
  end
  local battleId = _G.BattleManager.battleRuntimeData.battle_id
  local roleName = "Unknown"
  local OnlineModule = _G.NRCModuleManager and _G.NRCModuleManager:GetModule("OnlineModule")
  if OnlineModule and OnlineModule.data then
    roleName = OnlineModule.data.userName or "Unknown"
  end
  local timestamp = OsDate("%Y%m%d_%H%M%S")
  local fileName = StrFormat("BattleLog_%d_%s_%s.log", battleId, roleName, timestamp)
  local projectSavedDir = UE4.UBlueprintPathsLibrary.ProjectSavedDir()
  local pathSeparator = package.config:sub(1, 1)
  if not string.match(projectSavedDir, "[\\/]$") then
    projectSavedDir = projectSavedDir .. pathSeparator
  end
  local filePath = projectSavedDir .. fileName
  filePath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(filePath)
  local content = BattleLog.GetCacheText()
  local success = UE4.UNRCStatics.WriteToFile(filePath, content)
  if not success then
    Log.Error("[BattleLog] \229\134\153\229\133\165\228\184\180\230\151\182\230\151\165\229\191\151\230\150\135\228\187\182\229\164\177\232\180\165:", filePath)
    return
  end
  if _G.NRCModuleManager then
    local uploadSuccess = _G.NRCModuleManager:DoCmd(CosUploadModuleCmd.ReqCosUploadUrlForBattle, battleId, filePath, function(serverRemotePath)
      Log.Debug("[BattleLog] \230\151\165\229\191\151\228\184\138\228\188\160\230\136\144\229\138\159, \232\191\156\231\168\139\232\183\175\229\190\132:", serverRemotePath)
      local deleteSuccess = UE4.UNRCStatics.DeleteToFile(filePath)
      if not deleteSuccess then
        Log.Warning("[BattleLog] \229\136\160\233\153\164\228\184\180\230\151\182\230\150\135\228\187\182\229\164\177\232\180\165\239\188\140\230\150\135\228\187\182\228\187\141\228\191\157\231\149\153\229\156\168:", filePath)
      end
    end)
    if not uploadSuccess then
      Log.Error("[BattleLog] COS\228\184\138\228\188\160\232\175\183\230\177\130\229\164\177\232\180\165:", filePath)
    end
  else
    Log.Error("[BattleLog] NRCModuleManager\230\156\170\230\137\190\229\136\176\239\188\140\230\151\160\230\179\149\228\184\138\228\188\160\230\151\165\229\191\151")
  end
end

function BattleLog.Init()
  BattleLog.ClearCache()
  _logLevel = Log.GetLogLevel()
end

function BattleLog.OnExitBattle()
  BattleLog.ClearCache()
end

function BattleLog.OnAntiStuck()
  if IS_SHIPPING then
    BattleLog.UploadCacheToCos()
  end
end

return BattleLog

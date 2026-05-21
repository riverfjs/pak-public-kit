local Base = require("Common.Singleton.Singleton")
local GameSetting = Base:Extend("GameSetting")
local SaveName = "RocoSetting"
local SaveData

local function OverriderIndex(t, k)
  if SaveData then
    return SaveData[k]
  end
  return nil
end

local function OverriderNewIndex(t, k, v)
  if SaveData then
    SaveData[k] = v
  end
end

local metatable = {__index = OverriderIndex, __newindex = OverriderNewIndex}
GameSetting.__newindex = OverriderNewIndex

function GameSetting:Ctor(name)
  Base.Ctor(self, name)
  self.__newindex = OverriderNewIndex
end

function GameSetting:Init()
  Log.Debug("GameSetting:Init")
  if not RocoEnv.IS_EDITOR then
    self:SetupLogLevel()
  else
  end
  setmetatable(GameSetting, metatable)
  SaveData = UE4.UGameplayStatics.LoadGameFromSlot(SaveName, 0)
  if SaveData then
    Log.Debug("Load GameSetting", SaveData.LastLogin)
  else
    Log.Debug("Create GameSetting")
    SaveData = UE4.UGameplayStatics.CreateSaveGameObject(UE4.UClass.Load(UEPath.BP_GameSetting))
  end
  UE4.UNRCStatics.AddToRoot(SaveData)
  print("GameSetting check index", self.__index == OverriderIndex, self.__newindex == OverriderNewIndex)
  local screen = UE4.UNRCStatics.GetGameUserSettings():GetScreenResolution()
  local resolution = UE4.UNRCStatics.GetGSystemResolution()
  local viewportsize = UE4.UNRCStatics.GetGameUserSettings():GetDesktopResolution()
  UE4Helper.PrintScreenMsg("ScreenResolution:" .. screen.X .. "x" .. screen.Y .. " " .. resolution.X .. "x" .. resolution.Y .. " " .. viewportsize.X .. "x" .. viewportsize.Y)
  if not RocoEnv.IS_EDITOR and RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    screen = UE4.UNRCStatics.GetGameUserSettings():GetScreenResolution()
    resolution = UE4.UNRCStatics.GetGSystemResolution()
    UE4Helper.PrintScreenMsg("ScreenResolution after:" .. screen.X .. "x" .. screen.Y .. " " .. resolution.X .. "x" .. resolution.Y .. " " .. viewportsize.X .. "x" .. viewportsize.Y)
  end
  if RocoEnv.IS_SHIPPING then
    _G.EnableLogInfo = false
  else
    _G.EnableLogInfo = true
  end
  if not RocoEnv.IS_EDITOR and SaveData.UploadLogLevel and SaveData.UploadLogLevel >= 0 then
    self:SetLogLevel(SaveData.UploadLogLevel)
  end
  if not UE.UNRCStatics.IsOpenLuaDebug() then
    self:DisableTraceBack()
  end
end

function GameSetting:SetLogLevel(logLevel)
  Log.Error("GameSetting:SetLogLevel", logLevel)
  UE4.UNRCStatics.SetLogLevel(logLevel)
  if 0 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogFatal)
    self:SetCategoryLogLevel("off")
    UE4.UNRCStatics.ExecConsoleCommand("DisableAllScreenMessages")
  elseif 1 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogFatal)
    self:SetCategoryLogLevel("none")
    UE4.UNRCStatics.ExecConsoleCommand("DisableAllScreenMessages")
  elseif 2 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogError)
    self:SetCategoryLogLevel("error")
  elseif 3 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogWarn)
    self:SetCategoryLogLevel("warning")
  elseif 4 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogInfo)
    self:SetCategoryLogLevel("display")
  elseif 5 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogTrace)
    self:SetCategoryLogLevel("log")
  elseif 6 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogTrace)
    self:SetCategoryLogLevel("verbose")
  elseif 7 == logLevel then
    Log.SetLogLevel(Log.LOG_LEVEL.ELogTrace)
    self:SetCategoryLogLevel("all")
  end
  if SaveData then
    SaveData.UploadLogLevel = logLevel
  end
end

function GameSetting:SetCategoryLogLevel(level)
end

function GameSetting:SetupLogLevel()
  local LogLevel = AppMain.launchParams.log_level
  if "0" == LogLevel then
    self:SetupDefaultLogLevel()
  elseif "1" == LogLevel then
    self:SetLogLevel(5)
  elseif "2" == LogLevel then
    self:SetLogLevel(3)
  elseif "3" == LogLevel then
    self:SetLogLevel(2)
  elseif "4" == LogLevel then
    self:SetLogLevel(0)
  else
    self:SetupDefaultLogLevel()
  end
end

function GameSetting:SetupDefaultLogLevel()
  if RocoEnv.IS_SHIPPING then
    self:SetLogLevel(0)
    self:DisableUselessLogs()
  else
    self:SetLogLevel(4)
    self:EnableUselessLogs("log")
  end
end

local UselessShippingLog = {
  "LogStreaming",
  "LogTexture",
  "LogMaterial"
}

function GameSetting:DisableUselessLogs()
  if RocoEnv.IS_EDITOR then
    return
  end
  Log.Debug("AllenPee:DisableUselessLogs")
  for _, Cat in ipairs(UselessShippingLog) do
    UE4.UNRCStatics.ExecConsoleCommand(string.format("log %s off", Cat))
  end
end

function GameSetting:EnableUselessLogs(level)
  if RocoEnv.IS_EDITOR then
    return
  end
  Log.Debug("AllenPee:EnableUselessLogs", level)
  for _, Cat in ipairs(UselessShippingLog) do
    UE4.UNRCStatics.ExecConsoleCommand(string.format("log %s %s", Cat, level))
  end
end

function GameSetting:CheckDevice()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    return
  end
  Log.Debug("\230\154\130\230\151\182\229\177\143\232\148\189\228\186\134\230\163\128\230\181\139\232\174\190\229\164\135")
end

function GameSetting:DisableTraceBack()
  function debug.traceback()
    return ""
  end
end

function GameSetting:SyncUploadLogTag(LogTag)
  if SaveData then
    SaveData.UploadLogTag = LogTag
  end
  if _G.NRCSDKManager then
    _G.NRCSDKManager:SetUploadLogTag(LogTag)
  end
end

function GameSetting:GetUploadLogTag()
  local Tag = "Low"
  if SaveData then
    return SaveData.UploadLogTag or Tag
  end
  return Tag
end

function GameSetting:Save()
  if SaveData then
    local result = UE4.UGameplayStatics.SaveGameToSlot(SaveData, SaveName, 0)
    Log.Debug("Save GameSetting", SaveData, SaveData.LastLogin, result)
  end
end

return GameSetting

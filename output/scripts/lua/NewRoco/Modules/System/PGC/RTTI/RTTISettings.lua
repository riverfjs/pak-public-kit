local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local DefaultSettings = {
  Core = {StrictMode = true, MaxNestingLevel = 20},
  Validation = {
    EnableCustomRules = true,
    StopOnFirstError = false,
    EnableBlacklist = true,
    EnableWhitelist = false
  },
  Cache = {
    TTL = 300,
    MaxSize = 1000,
    EnableAutoCleanup = true,
    CleanupInterval = 60,
    EvictionRatio = 0.25
  },
  Statistics = {
    EnableCollection = true,
    ReportInterval = 300,
    MaxHistorySize = 1000
  },
  DataProvider = {
    EnableValidation = true,
    CacheResults = true,
    MaxQueryDepth = 10,
    TimeoutMs = 5000
  },
  Reflection = {
    EnablePropertyCache = true,
    EnableSerialization = true,
    MaxPathDepth = 15,
    YamlRootDir = "Tools/DataConfigTools/DataConfig/",
    RegionFile = "Tools/DataConfigTools/config/region.yaml",
    RulesFile = "Tools/DataConfigTools/config/rules.yaml"
  }
}
local RTTISettings = {
  Settings = RTTIBase.DeepCopy(DefaultSettings)
}

function RTTISettings:Initialize(UserSettings)
  if RTTIBase.IsValidTableValue(UserSettings) then
    RTTIBase.MergeTable(self.Settings, UserSettings, true)
  end
end

function RTTISettings:Reset()
  self.Settings = RTTIBase.DeepCopy(DefaultSettings)
end

function RTTISettings:Get(Path, DefaultValue)
  local Keys = RTTIBase.Split(Path, ".")
  local Current = self.Settings
  for _, Key in ipairs(Keys) do
    if RTTIBase.IsValidTableValue(Current) and nil ~= Current[Key] then
      Current = Current[Key]
    else
      return DefaultValue
    end
  end
  return Current
end

function RTTISettings:Set(Path, Value)
  local Keys = RTTIBase.Split(Path, ".")
  if 0 == #Keys then
    return false
  end
  local Current = self.Settings
  for i = 1, #Keys - 1 do
    local Key = Keys[i]
    if not RTTIBase.IsValidTableValue(Current[Key]) then
      Current[Key] = {}
    end
    Current = Current[Key]
  end
  local FinalKey = Keys[#Keys]
  Current[FinalKey] = Value
  return true
end

function RTTISettings:Reset(Path)
  if nil == Path then
    self.Settings = RTTIBase.DeepCopy(DefaultSettings)
  else
    local Keys = RTTIBase.Split(Path, ".")
    if 0 == #Keys then
      return
    end
    local DefaultCurrent = DefaultSettings
    local Current = self.Settings
    for i = 1, #Keys - 1 do
      local Key = Keys[i]
      if RTTIBase.IsValidTableValue(DefaultCurrent) and nil ~= DefaultCurrent[Key] then
        DefaultCurrent = DefaultCurrent[Key]
      else
        return
      end
      if not RTTIBase.IsValidTableValue(Current[Key]) then
        Current[Key] = {}
      end
      Current = Current[Key]
    end
    local FinalKey = Keys[#Keys]
    if RTTIBase.IsValidTableValue(DefaultCurrent) and nil ~= DefaultCurrent[FinalKey] then
      Current[FinalKey] = RTTIBase.DeepCopy(DefaultCurrent[FinalKey])
    end
  end
end

function RTTISettings:Export(Path)
  if nil == Path then
    return RTTIBase.DeepCopy(self.Settings)
  else
    local Keys = RTTIBase.Split(Path, ".")
    local Current = self.Settings
    for _, Key in ipairs(Keys) do
      if RTTIBase.IsValidTableValue(Current) and nil ~= Current[Key] then
        Current = Current[Key]
      else
        return nil
      end
    end
    return RTTIBase.DeepCopy(Current)
  end
end

function RTTISettings:Import(SettingsData, Path, Merge)
  if not RTTIBase.IsValidTableValue(SettingsData) then
    return false
  end
  Merge = false ~= Merge
  if nil == Path then
    if Merge then
      RTTIBase.MergeTable(self.Settings, SettingsData, true)
    else
      self.Settings = RTTIBase.DeepCopy(SettingsData)
    end
  else
    local Keys = RTTIBase.Split(Path, ".")
    if 0 == #Keys then
      return false
    end
    local Current = self.Settings
    for i = 1, #Keys - 1 do
      local Key = Keys[i]
      if not RTTIBase.IsValidTableValue(Current[Key]) then
        Current[Key] = {}
      end
      Current = Current[Key]
    end
    local FinalKey = Keys[#Keys]
    if Merge and RTTIBase.IsValidTableValue(Current[FinalKey]) and RTTIBase.IsValidTableValue(SettingsData) then
      RTTIBase.MergeTable(Current[FinalKey], SettingsData, true)
    else
      Current[FinalKey] = RTTIBase.DeepCopy(SettingsData)
    end
  end
  return true
end

function RTTISettings:GetAllSettings()
  return self.Settings
end

return RTTISettings

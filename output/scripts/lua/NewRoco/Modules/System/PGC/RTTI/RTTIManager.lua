local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTIValidator = require("NewRoco.Modules.System.PGC.RTTI.RTTIValidator")
local RTTIReflection = require("NewRoco.Modules.System.PGC.RTTI.RTTIReflection")
local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
local RTTICache = require("NewRoco.Modules.System.PGC.RTTI.RTTICache")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTIManager = {Initialized = false}

function RTTIManager:Initialize(UserSettings)
  if self.Initialized then
    return
  end
  RTTISettings:Initialize(UserSettings)
  RTTIStatistics:Initialize()
  RTTICache:Initialize()
  RTTIDataProvider:Initialize()
  RTTICore:Initialize()
  RTTIValidator:Initialize()
  RTTIReflection:Initialize()
  self.Initialized = true
end

function RTTIManager:Shutdown()
  if not self.Initialized then
    return
  end
  self:ResetSystemStatus()
  self.Initialized = false
end

function RTTIManager:RegisterEnum(EnumName, EnumDefine)
  return RTTICore:RegisterEnum(EnumName, EnumDefine)
end

function RTTIManager:UnregisterEnum(EnumName)
  return RTTICore:UnregisterEnum(EnumName)
end

function RTTIManager:GetEnumInfo(EnumName)
  return RTTICore:GetEnumInfo(EnumName)
end

function RTTIManager:GetEnumNames()
  return RTTICore:GetRegisteredEnums()
end

function RTTIManager:HasEnum(EnumName)
  return RTTICore:GetEnumInfo(EnumName) ~= nil
end

function RTTIManager:RegisterType(TypeName, TypeDefine)
  return RTTICore:RegisterType(TypeName, TypeDefine)
end

function RTTIManager:GetTypeInfo(TypeName)
  return RTTICore:GetTypeInfo(TypeName)
end

function RTTIManager:GetTypeNames()
  return RTTICore:GetRegisteredTypes()
end

function RTTIManager:GetPrimaryKeyName(TypeName)
  return RTTICore:GetPrimaryKeyName(TypeName)
end

function RTTIManager:GetPrimaryKeyValue(TypeName, Data)
  local _, PrimaryKeyValue = RTTICore:GetPrimaryKeyValue(TypeName, Data)
  return PrimaryKeyValue
end

function RTTIManager:HasType(TypeName)
  return RTTICore:GetTypeInfo(TypeName) ~= nil
end

function RTTIManager:RegisterPrimaryKeyGenerateHook(TypeName, Hook)
  return RTTIReflection:RegisterPrimaryKeyGenerateHook(TypeName, Hook)
end

function RTTIManager:UnregisterPrimaryKeyGenerateHook(TypeName)
  return RTTIReflection:UnregisterPrimaryKeyGenerateHook(TypeName)
end

function RTTIManager:CreateInstance(TypeName)
  return RTTIReflection:CreateInstance(TypeName)
end

function RTTIManager:DestroyInstance(TypeName, KeyValue)
  return RTTIReflection:DestroyInstance(TypeName, KeyValue)
end

function RTTIManager:DuplicateInstance(TypeName, Source, Force)
  local SafeForce = true == Force
  local Instance, InvalidFields = RTTIReflection:DuplicateInstance(TypeName, Source, SafeForce)
  return Instance, InvalidFields or {}
end

function RTTIManager:DeepEquals(Left, Right)
  return RTTIReflection:DeepEquals(Left, Right)
end

function RTTIManager:GetProperty(TypeName, Data, Path)
  return RTTIReflection:GetProperty(TypeName, Data, Path)
end

function RTTIManager:SetProperty(TypeName, Data, Path, Value)
  return RTTIReflection:SetProperty(TypeName, Data, Path, Value)
end

function RTTIManager:SaveDirtyBucket(TypeName, ForceCreate)
  return RTTIReflection:SaveDirtyBucket(TypeName, ForceCreate)
end

function RTTIManager:Serialize(TypeName, Data, Format)
  return RTTIReflection:Serialize(TypeName, Data, Format)
end

function RTTIManager:Deserialize(TypeName, Serialized, Format)
  return RTTIReflection:Deserialize(TypeName, Serialized, Format)
end

function RTTIManager:RegisterConfig(TypeName, Config)
  return RTTIDataProvider:RegisterConfig(TypeName, Config)
end

function RTTIManager:GetAllPrimaryKeyValues(TypeName)
  return RTTIDataProvider:GetAllPrimaryKeyValues(TypeName)
end

function RTTIManager:QueryByFieldName(TypeName, OnlyOne, FieldName, FieldValue)
  return RTTIDataProvider:QueryByFieldName(TypeName, OnlyOne, FieldName, FieldValue)
end

function RTTIManager:QueryByPrimaryKey(TypeName, KeyValue)
  return RTTIDataProvider:QueryByPrimaryKey(TypeName, KeyValue)
end

function RTTIManager:RegisterCustomRule(RuleName, Callback)
  return RTTIValidator:RegisterCustomRule(RuleName, Callback)
end

function RTTIManager:RegisterBusinessRule(RuleName, Callback, ApplicableTypeNames)
  return RTTIValidator:RegisterBusinessRule(RuleName, Callback, ApplicableTypeNames)
end

function RTTIManager:RegisterSecurityRule(RuleName, Callback)
  return RTTIValidator:RegisterSecurityRule(RuleName, Callback)
end

function RTTIManager:RegisterBlacklistRegexp(RuleName, Regexp)
  return RTTIValidator:RegisterBlacklistRegexp(RuleName, Regexp)
end

function RTTIManager:RegisterWhitelistRegexp(RuleName, Regexp)
  return RTTIValidator:RegisterWhitelistRegexp(RuleName, Regexp)
end

function RTTIManager:ValidateRecord(TypeName, Data)
  return RTTIValidator:ValidateRecord(TypeName, Data)
end

function RTTIManager:ValidateBatch(TypeName, DataList)
  return RTTIValidator:ValidateBatch(TypeName, DataList)
end

function RTTIManager:GetLastValidationResult()
  return RTTIStatistics:GetLastValidationResult()
end

function RTTIManager:GetLastError()
  return RTTIStatistics:GetLastError()
end

function RTTIManager:GetSetting(Path, DefaultValue)
  return RTTISettings:Get(Path, DefaultValue)
end

function RTTIManager:SetSetting(Path, Value)
  return RTTISettings:Set(Path, Value)
end

function RTTIManager:ResetSystemStatus()
  RTTICache:Reset()
  RTTIStatistics:Reset()
  RTTISettings:Reset()
end

function RTTIManager:GetSystemStatus()
  local SystemStatus = {
    Initialized = self.Initialized,
    RegisteredTypes = RTTICore:GetRegisteredTypes(),
    Statistics = RTTIStatistics:GetReport(),
    Settings = RTTISettings:GetAllSettings()
  }
  return SystemStatus
end

return RTTIManager

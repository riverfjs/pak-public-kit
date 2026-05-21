local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTICache = require("NewRoco.Modules.System.PGC.RTTI.RTTICache")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTIReflection = require("NewRoco.Modules.System.PGC.RTTI.RTTIReflection")
local RTTIDataProvider = {
  ConfigRegistry = {}
}

local function BuildQueryCacheOptions(TypeName, OnlyOne, ...)
  return {
    BucketKey = TypeName,
    OnlyOne = OnlyOne,
    Args = {
      ...
    }
  }
end

local function ValidateConfig(TypeName, Config)
  local Success = true
  if RTTIBase.IsValidTableValue(Config) then
    local ConfigContent = {
      GetAllDatas = "function",
      GetData = "function",
      SaveData = "function",
      InsertData = "function",
      DeleteData = "function"
    }
    for FieldName, FieldType in pairs(ConfigContent) do
      local ConfigField = Config[FieldName]
      if nil == ConfigField then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145Config.%s\230\178\161\230\156\137\229\174\158\231\142\176", TypeName, FieldName)
        Success = false
      elseif type(ConfigField) ~= FieldType then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145Config.%s\231\177\187\229\158\139\228\184\141\229\175\185\239\188\140\229\186\148\228\184\186%s", TypeName, FieldName, FieldType)
        Success = false
      end
    end
  else
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145Config\229\191\133\233\161\187\230\152\175table\231\177\187\229\158\139", TypeName)
    Success = false
  end
  return Success
end

local function GetConfig(self, TypeName)
  local Config = self.ConfigRegistry[TypeName]
  if nil == Config then
    local ConfigTableId = DataConfigManager.ConfigTableId[TypeName]
    if ConfigTableId then
      local TargetConfig = DataConfigManager:GetTable(ConfigTableId)
      if TargetConfig and self:RegisterConfig(TypeName, TargetConfig) then
        Config = TargetConfig
      end
    end
    if nil == Config then
      RTTIStatistics:RecordError(false, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\230\141\174\230\186\144\229\176\154\230\156\170\230\179\168\229\134\140\239\188\140\232\175\183\232\176\131\231\148\168RTTIManager:RegisterConfig()\230\179\168\229\134\140", TypeName)
    end
  end
  return Config
end

local function QueryRecords(self, TypeName, MapReduce, ...)
  local StartTime = os.clock()
  RTTIStatistics:RecordProviderQuery()
  local CacheResults = RTTISettings:Get("DataProvider.CacheResults")
  if CacheResults then
    local CacheOptions = BuildQueryCacheOptions(TypeName, ...)
    local CachedResult = RTTICache:GetCache(RTTIBase.CacheType.QUERY, CacheOptions)
    if CachedResult then
      local OperationName = select(2, ...)
      if not RTTIBase.IsValidStringValue(OperationName) then
        OperationName = "QueryRecords"
      end
      local Duration = os.clock() - StartTime
      RTTIStatistics:RecordOperation(OperationName, {
        TypeName = TypeName,
        CacheHit = true,
        Duration = Duration
      })
      return CachedResult
    end
  end
  local QueryResult
  local Config = GetConfig(self, TypeName)
  if Config and MapReduce and type(MapReduce) == "function" then
    QueryResult = MapReduce(Config)
    if CacheResults then
      local CacheOptions = BuildQueryCacheOptions(TypeName, ...)
      RTTICache:SetCache(RTTIBase.CacheType.QUERY, QueryResult, CacheOptions)
    end
  end
  local OperationName = select(2, ...)
  if not RTTIBase.IsValidStringValue(OperationName) then
    OperationName = "QueryRecords"
  end
  local Duration = os.clock() - StartTime
  RTTIStatistics:RecordOperation(OperationName, {
    TypeName = TypeName,
    CacheHit = false,
    Duration = Duration
  })
  return QueryResult
end

function RTTIDataProvider:Initialize()
  self:Reset()
end

function RTTIDataProvider:Reset()
  self.ConfigRegistry = {}
end

function RTTIDataProvider:RegisterConfig(TypeName, Config)
  if not RTTIBase.IsValidStringValue(TypeName) then
    RTTIStatistics:RecordError(true, "\230\179\168\229\134\140\233\133\141\231\189\174\231\177\187\229\158\139\227\128\144%s\227\128\145\230\151\160\230\149\136", TypeName)
    return false
  end
  if not RTTIBase.IsValidTableValue(Config) then
    RTTIStatistics:RecordError(true, "\230\179\168\229\134\140\233\133\141\231\189\174\231\177\187\229\158\139\227\128\144%s\227\128\145\239\188\140Config\229\191\133\233\161\187\230\152\175\232\161\168", TypeName)
    return false
  end
  if RTTISettings:Get("DataProvider.EnableValidation") and not ValidateConfig(TypeName, Config) then
    RTTIStatistics:RecordError(true, "\233\133\141\231\189\174\230\149\176\230\141\174\233\170\140\232\175\129\229\164\177\232\180\165: %s", TypeName)
    return false
  end
  self.ConfigRegistry[TypeName] = Config
  RTTICache:ClearQueryBucket(TypeName)
  RTTIStatistics:RecordProviderRegister()
  return true
end

function RTTIDataProvider:GetAllPrimaryKeyValues(TypeName)
  local PrimaryKeyValues = {}
  local Config = GetConfig(self, TypeName)
  if Config then
    local Records = Config:GetAllDatas()
    for PrimaryKey in pairs(Records) do
      table.insert(PrimaryKeyValues, PrimaryKey)
    end
    table.sort(PrimaryKeyValues)
  end
  return PrimaryKeyValues
end

function RTTIDataProvider:QueryRecordsByPredicate(TypeName, OnlyOne, Predicate, ...)
  local Args = {
    ...
  }
  local QueryResult = QueryRecords(self, TypeName, function(Config)
    local Result
    local QueryDepth = 0
    local MaxDepth = RTTISettings:Get("DataProvider.MaxQueryDepth", 10)
    local StartTime = os.clock()
    local TimeoutSeconds = RTTISettings:Get("DataProvider.TimeoutMs", 5000) / 1000.0
    local Records = Config:GetAllDatas()
    for PrimaryKey, Record in pairs(Records) do
      QueryDepth = QueryDepth + 1
      if -1 ~= MaxDepth and MaxDepth < QueryDepth then
        RTTIStatistics:RecordError(false, "\230\159\165\232\175\162\231\177\187\229\158\139\233\133\141\231\189\174\227\128\144%s\227\128\145\230\183\177\229\186\166\232\182\133\233\153\144:%d>%d", TypeName, QueryDepth, MaxDepth)
        break
      end
      local CostTime = os.clock() - StartTime
      if TimeoutSeconds < CostTime then
        RTTIStatistics:RecordError(false, "\230\159\165\232\175\162\231\177\187\229\158\139\233\133\141\231\189\174\227\128\144%s\227\128\145\232\182\133\230\151\182:%f>%f", TypeName, CostTime, TimeoutSeconds)
        break
      end
      if Predicate(Record, PrimaryKey) then
        local OverrideRecord
        if getmetatable(Record) == nil then
          OverrideRecord = Record
        else
          OverrideRecord = RTTIReflection:DuplicateInstance(TypeName, Record, false)
          if OverrideRecord then
            Config:SaveData(PrimaryKey, OverrideRecord)
          end
        end
        if nil ~= OverrideRecord then
          RTTIStatistics:RecordOperation("QueryRecordsByPredicate", {TypeName = TypeName, Args = Args})
          Result = Result or {}
          table.insert(Result, OverrideRecord)
          if OnlyOne then
            break
          end
        end
      end
    end
    return Result
  end, OnlyOne, ...)
  if OnlyOne then
    return QueryResult and QueryResult[1]
  else
    return QueryResult
  end
end

function RTTIDataProvider:QueryByFieldName(TypeName, OnlyOne, FieldName, FieldValue)
  local QueryResult = self:QueryRecordsByPredicate(TypeName, OnlyOne, function(Record, _)
    local ResultValue = Record[FieldName]
    return ResultValue == FieldValue
  end, "QueryByFieldName", FieldName, FieldValue)
  return QueryResult
end

function RTTIDataProvider:QueryByPrimaryKey(TypeName, KeyValue)
  local QueryResult = QueryRecords(self, TypeName, function(Config)
    local Result
    local Record = Config:GetData(KeyValue)
    if Record then
      local OverrideRecord
      if getmetatable(Record) == nil then
        OverrideRecord = Record
      else
        OverrideRecord = RTTIReflection:DuplicateInstance(TypeName, Record, false)
        if OverrideRecord then
          Config:SaveData(KeyValue, OverrideRecord)
        end
      end
      if nil ~= OverrideRecord then
        Result = {}
        table.insert(Result, OverrideRecord)
      end
    end
    return Result
  end, true, "QueryByPrimaryKey", KeyValue)
  return QueryResult and QueryResult[1]
end

function RTTIDataProvider:InsertRecord(TypeName, Record)
  local Config = GetConfig(self, TypeName)
  if nil == Config then
    return false
  end
  local _, PrimaryKeyValue = RTTICore:GetPrimaryKeyValue(TypeName, Record)
  if nil == PrimaryKeyValue then
    return false
  end
  local Success = Config:InsertData(PrimaryKeyValue, Record)
  if Success then
    RTTICache:ClearQueryBucket(TypeName)
  end
  return Success
end

function RTTIDataProvider:DeleteRecord(TypeName, KeyValue)
  local Config = GetConfig(self, TypeName)
  if nil == Config then
    return false
  end
  local Success = Config:DeleteData(KeyValue)
  if Success then
    RTTICache:ClearQueryBucket(TypeName)
  end
  return Success
end

return RTTIDataProvider

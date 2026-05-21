local RTTIBase = {}
RTTIBase.FieldType = {
  BOOL = "bool",
  INT32 = "int32",
  UINT32 = "uint32",
  INT64 = "int64",
  UINT64 = "uint64",
  FLOAT = "float",
  DOUBLE = "double",
  STRING = "string",
  ENUM = "enum",
  STRUCT = "struct",
  ARRAY = "array"
}
RTTIBase.ConstraintType = {
  LIMIT_VALUE = "value_limit",
  LIMIT_SIZE = "size_limit",
  LIMIT_LENGTH = "length_limit",
  LIMIT_NOEMPTY = "not_empty",
  INDEX = "index",
  UNIQUE = "unique",
  TYPE = "type",
  ENUM = "enum",
  ARRAY = "array",
  PRIMARY_KEY = "primary_key",
  FOREIGN_KEY = "foreign_key",
  CONDITION_KEY = "condition_key",
  SMART_FOREIGN_KEY = "smart_foreign_key",
  LOCALE_NAME = "locale_name",
  CUSTOM = "custom"
}
RTTIBase.ScopeType = {
  Default = "",
  Client = "c",
  Server = "s",
  Both = "b",
  Edit = "e"
}
RTTIBase.CacheType = {QUERY = "query", PROPERTY = "property"}
local FlagIndex = 0

local function AutoFlag()
  local FlagValue = 1 << FlagIndex
  FlagIndex = FlagIndex + 1
  return FlagValue
end

local function ResetFlag()
  FlagIndex = 0
  return 0
end

local function NormalizeFlagValue(Value)
  if type(Value) ~= "number" then
    return 0
  end
  if math.tointeger then
    return math.tointeger(Value) or 0
  end
  if Value == math.floor(Value) then
    return Value
  end
  return 0
end

local function AddFlag(FlagValue, FlagEnum)
  local SafeFlagValue = NormalizeFlagValue(FlagValue)
  local SafeFlagEnum = NormalizeFlagValue(FlagEnum)
  return SafeFlagValue | SafeFlagEnum
end

local function RemoveFlag(FlagValue, FlagEnum)
  local SafeFlagValue = NormalizeFlagValue(FlagValue)
  local SafeFlagEnum = NormalizeFlagValue(FlagEnum)
  return SafeFlagValue & ~SafeFlagEnum
end

local function HasFlag(FlagValue, FlagEnum)
  local SafeFlagValue = NormalizeFlagValue(FlagValue)
  local SafeFlagEnum = NormalizeFlagValue(FlagEnum)
  if 0 == SafeFlagEnum then
    return false
  end
  return 0 ~= SafeFlagValue & SafeFlagEnum
end

ResetFlag()
RTTIBase.DataFlagType = {
  None = ResetFlag(),
  Dirty = AutoFlag(),
  Create = AutoFlag(),
  Duplicate = AutoFlag(),
  Destroy = AutoFlag(),
  InEdit = AutoFlag()
}

function RTTIBase.Class(Name)
  local Maker = _G.MakeSimpleClass
  return Maker(Name)
end

function RTTIBase.IsValidTableValue(TableValue)
  return type(TableValue) == "table"
end

function RTTIBase.IsValidNumberValue(NumberValue, RequireInteger)
  if type(NumberValue) ~= "number" then
    return false
  end
  if NumberValue ~= NumberValue then
    return false
  end
  if NumberValue == math.huge or NumberValue == -math.huge then
    return false
  end
  if RequireInteger then
    if math.tointeger then
      return math.tointeger(NumberValue) ~= nil
    end
    return NumberValue == math.floor(NumberValue)
  end
  return true
end

function RTTIBase.IsValidStringValue(StringValue, NotCheckEmpty)
  if type(StringValue) ~= "string" then
    return false
  end
  if NotCheckEmpty then
    return true
  end
  if "" == StringValue then
    return false
  end
  return string.match(StringValue, "%S") ~= nil
end

function RTTIBase.IsValidFieldName(FieldName)
  if not RTTIBase.IsValidStringValue(FieldName) then
    return false
  end
  return string.match(FieldName, "^[A-Za-z_][A-Za-z0-9_]*$") ~= nil
end

function RTTIBase.IsValidFieldType(FieldType)
  if not RTTIBase.IsValidStringValue(FieldType) then
    return false
  end
  for _, Value in pairs(RTTIBase.FieldType) do
    if Value == FieldType then
      return true
    end
  end
  return false
end

function RTTIBase.IsIntegerType(FieldType)
  return FieldType == RTTIBase.FieldType.INT32 or FieldType == RTTIBase.FieldType.UINT32 or FieldType == RTTIBase.FieldType.INT64 or FieldType == RTTIBase.FieldType.UINT64
end

function RTTIBase.IsFloatType(FieldType)
  return FieldType == RTTIBase.FieldType.FLOAT or FieldType == RTTIBase.FieldType.DOUBLE
end

function RTTIBase.IsNumberType(FieldType)
  return RTTIBase.IsIntegerType(FieldType) or RTTIBase.IsFloatType(FieldType)
end

function RTTIBase.IsComplexType(FieldType)
  return FieldType == RTTIBase.FieldType.STRUCT or FieldType == RTTIBase.FieldType.ARRAY
end

function RTTIBase.IsPrimitiveType(FieldType)
  return not RTTIBase.IsComplexType(FieldType)
end

function RTTIBase.FilterFieldName(FieldName)
  return "DataFlag" ~= FieldName and "UserData" ~= FieldName
end

function RTTIBase.AddDataFlag(Data, FlagEnum)
  if type(Data) ~= "table" then
    return
  end
  local DataFlag = Data.DataFlag or RTTIBase.DataFlagType.None
  DataFlag = AddFlag(DataFlag, FlagEnum)
  Data.DataFlag = DataFlag
end

function RTTIBase.RemoveDataFlag(Data, FlagEnum)
  if type(Data) ~= "table" then
    return
  end
  local DataFlag = Data.DataFlag or RTTIBase.DataFlagType.None
  DataFlag = RemoveFlag(DataFlag, FlagEnum)
  Data.DataFlag = DataFlag
end

function RTTIBase.HasDataFlag(Data, FlagEnum)
  if type(Data) ~= "table" then
    return false
  end
  local DataFlag = Data.DataFlag or RTTIBase.DataFlagType.None
  return HasFlag(DataFlag, FlagEnum)
end

function RTTIBase.SetUserData(Data, KeyName, DataValue)
  if RTTIBase.IsValidStringValue(KeyName) and RTTIBase.IsValidTableValue(Data) then
    local UserData = Data.UserData
    if not UserData then
      UserData = {}
      Data.UserData = UserData
    end
    UserData[KeyName] = DataValue
    return true
  end
  return false
end

function RTTIBase.GetUserData(Data, KeyName)
  if RTTIBase.IsValidStringValue(KeyName) and RTTIBase.IsValidTableValue(Data) then
    local UserData = Data.UserData
    if RTTIBase.IsValidTableValue(UserData) then
      return UserData[KeyName]
    end
  end
  return nil
end

function RTTIBase.TableSize(Target)
  if type(Target) ~= "table" then
    return 0
  end
  local Count = 0
  for _ in pairs(Target) do
    Count = Count + 1
  end
  return Count
end

function RTTIBase.ArrayContains(Array, Value)
  if type(Array) ~= "table" then
    return false
  end
  for _, Item in ipairs(Array) do
    if Item == Value then
      return true
    end
  end
  return false
end

function RTTIBase.Split(Text, Delimiter)
  local Result = {}
  if not (type(Text) == "string" and Delimiter) or "" == Delimiter then
    return Result
  end
  for Token in string.gmatch(Text, "[^" .. Delimiter .. "]+") do
    table.insert(Result, Token)
  end
  return Result
end

function RTTIBase.DeepCopy(Object, Seen)
  if type(Object) ~= "table" then
    return Object
  end
  if Seen and Seen[Object] then
    return Seen[Object]
  end
  local Visited = Seen or {}
  local Result = {}
  Visited[Object] = Result
  for Key, Value in pairs(Object) do
    Result[RTTIBase.DeepCopy(Key, Visited)] = RTTIBase.DeepCopy(Value, Visited)
  end
  return setmetatable(Result, getmetatable(Object))
end

function RTTIBase.MergeTable(Target, Source, Deep)
  if type(Target) ~= "table" or type(Source) ~= "table" then
    return Target
  end
  for Key, Value in pairs(Source) do
    if Deep and type(Value) == "table" then
      Target[Key] = RTTIBase.MergeTable(type(Target[Key]) == "table" and Target[Key] or {}, Value, true)
    else
      Target[Key] = Value
    end
  end
  return Target
end

function RTTIBase.TableToString(TableData, MaxDepth, CurrentDepth)
  if type(TableData) ~= "table" then
    return tostring(TableData)
  end
  MaxDepth = MaxDepth or 4
  CurrentDepth = CurrentDepth or 1
  if MaxDepth < CurrentDepth then
    return "..."
  end
  local Parts = {"{"}
  local IsFirst = true
  for Key, Value in pairs(TableData) do
    if not IsFirst then
      table.insert(Parts, ", ")
    end
    IsFirst = false
    table.insert(Parts, tostring(Key) .. ":" .. RTTIBase.TableToString(Value, MaxDepth, CurrentDepth + 1))
  end
  table.insert(Parts, "}")
  return table.concat(Parts)
end

return RTTIBase

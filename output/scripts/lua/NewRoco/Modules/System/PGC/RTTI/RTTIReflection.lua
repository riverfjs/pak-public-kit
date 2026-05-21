local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTICache = require("NewRoco.Modules.System.PGC.RTTI.RTTICache")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local JsonSerializer = require("NewRoco.Modules.System.PGC.RTTI.Serializers.JsonSerializer")
local LuaSerializer = require("NewRoco.Modules.System.PGC.RTTI.Serializers.LuaSerializer")
local RTTIYamlStore = require("NewRoco.Modules.System.PGC.RTTI.RTTIYamlStore")
local RTTIReflection = {
  Serializers = {
    json = JsonSerializer(),
    lua = LuaSerializer()
  },
  DirtyBucketByTypeName = {},
  PrimaryKeyGenerateHooks = {},
  PrimaryKeyMaxValues = {},
  NewKeyRuleCache = {},
  PrimaryKeyMaxValuesByUser = {},
  UserIdByUserName = {},
  UserNameByUserId = {}
}

local function BuildPropertyCacheOptions(TypeName, Data, Path)
  local PrimaryKeyName = RTTICore:GetPrimaryKeyName(TypeName)
  local PrimaryKeyValue = PrimaryKeyName and Data[PrimaryKeyName]
  return {
    TypeName = TypeName,
    Path = Path,
    PrimaryKeyValue = PrimaryKeyValue
  }
end

local function ParsePath(Path)
  local Segments = {}
  for Part in string.gmatch(Path, "[^%.]+") do
    table.insert(Segments, Part)
  end
  return Segments
end

local function BuildPathTokens(Path)
  local Tokens = {}
  for _, Segment in ipairs(ParsePath(Path)) do
    local Name, IndexStr = string.match(Segment, "([^%[]+)%[(%d+)%]")
    if Name then
      table.insert(Tokens, {
        IsArray = true,
        Name = Name,
        Index = tonumber(IndexStr),
        Raw = Segment
      })
    else
      table.insert(Tokens, {
        IsArray = false,
        Name = Segment,
        Index = nil,
        Raw = Segment
      })
    end
  end
  return Tokens
end

local function FixDefaultByPrimaryKey(TargetTypeName, TargetFieldName, Default)
  if not RTTICore:HasType(TargetTypeName) then
    RTTIStatistics:RecordError(false, "\229\164\150\233\148\174\231\177\187\229\158\139\227\128\144%s\227\128\145\228\184\141\229\173\152\229\156\168\239\188\140\232\175\183\230\179\168\229\134\140\232\175\165\231\177\187\229\158\139\228\191\161\230\129\175", TargetTypeName)
    return Default
  end
  local PrimaryKeyName = RTTICore:GetPrimaryKeyName(TargetTypeName)
  if TargetFieldName ~= PrimaryKeyName then
    RTTIStatistics:RecordError(false, "\229\164\150\233\148\174\231\177\187\229\158\139\229\173\151\230\174\181\227\128\144%s.%s\227\128\145\228\184\141\230\152\175\228\184\187\233\148\174, \232\175\183\232\128\131\232\153\145\231\186\166\230\157\159\232\174\190\232\174\161\229\144\136\231\144\134\230\128\167", TargetTypeName, TargetFieldName)
    return Default
  end
  local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
  local AllPrimaryKeyValues = RTTIDataProvider:GetAllPrimaryKeyValues(TargetTypeName)
  local PrimaryKeyCount = #AllPrimaryKeyValues
  if PrimaryKeyCount <= 0 then
    return Default
  end
  local MinPrimaryKeyValue = AllPrimaryKeyValues[1]
  local MaxPrimaryKeyValue = AllPrimaryKeyValues[PrimaryKeyCount]
  if nil == Default then
    RTTIStatistics:RecordError(false, "\229\164\150\233\148\174\229\173\151\230\174\181\227\128\144%s.%s\227\128\145\230\151\160\230\179\149\230\142\168\229\175\188\231\188\186\231\156\129\229\128\188\239\188\140\229\183\178\229\136\134\233\133\141\230\156\128\229\176\143\228\184\187\233\148\174\229\128\188", tostring(TargetTypeName), tostring(TargetFieldName))
    return MinPrimaryKeyValue
  end
  if RTTIBase.IsValidNumberValue(Default) and RTTIBase.IsValidNumberValue(MinPrimaryKeyValue) then
    if Default < MinPrimaryKeyValue or Default > MaxPrimaryKeyValue then
      return MinPrimaryKeyValue
    end
    return Default
  end
  if nil ~= RTTIDataProvider:QueryByPrimaryKey(TargetTypeName, Default) then
    return Default
  end
  return MinPrimaryKeyValue
end

local function FixDefaultByFieldInfo(FieldInfo, Default, TypeInfo, Data)
  if not RTTIBase.IsPrimitiveType(FieldInfo.Type) then
    return Default
  end
  local Constraint = FieldInfo.Constraint
  if nil == Constraint then
    return Default
  end
  local FieldName = FieldInfo.Name
  if nil ~= Constraint.ForeignKey then
    local ForeignKeyTypeName = Constraint.ForeignKey.TypeName
    local ForeignKeyFieldName = Constraint.ForeignKey.FieldName
    return FixDefaultByPrimaryKey(ForeignKeyTypeName, ForeignKeyFieldName, Default)
  end
  local TypeName = TypeInfo and TypeInfo.Name
  if Constraint.SmartForeignKey and TypeName and FieldName and Data then
    local FromTypeName, FromFieldName = RTTICore:ResolveSmartForeignKeyTarget(TypeName, FieldName, Data)
    if FromTypeName and FromFieldName then
      return FixDefaultByPrimaryKey(FromTypeName, FromFieldName, Default)
    end
  end
  if Constraint.ConditionKey and TypeName and FieldName and Data then
    local FromTypeName, FromFieldName = RTTICore:ResolveConditionKeyTarget(TypeName, FieldName, Data)
    if FromTypeName and FromFieldName then
      return FixDefaultByPrimaryKey(FromTypeName, FromFieldName, Default)
    end
  end
  return Default
end

local function BuildDefaultFieldOrder(TypeInfo)
  local Visiting = {}
  local Visited = {}
  local Result = {}
  local Visit = function(FieldName)
    if Visited[FieldName] then
      return
    end
    if Visiting[FieldName] then
      return
    end
    Visiting[FieldName] = true
    local Info = TypeInfo.FieldInfos[FieldName]
    local DriverField = Info and Info.Constraint and Info.Constraint.ConditionKey and Info.Constraint.ConditionKey.DriverField
    if RTTIBase.IsValidStringValue(DriverField) and TypeInfo.FieldInfos[DriverField] then
      Visit(DriverField)
    end
    local Smart = Info and Info.Constraint and Info.Constraint.SmartForeignKey
    if type(Smart) == "table" then
      local SmartDriverField = Smart.DriverField
      if nil == SmartDriverField and #Smart > 0 then
        SmartDriverField = Smart[1] and Smart[1].DriverField
      end
      if RTTIBase.IsValidStringValue(SmartDriverField) and TypeInfo.FieldInfos[SmartDriverField] then
        Visit(SmartDriverField)
      end
    end
    Visiting[FieldName] = nil
    Visited[FieldName] = true
    table.insert(Result, FieldName)
  end
  for _, FieldName in ipairs(TypeInfo.FieldOrder) do
    if TypeInfo.FieldInfos[FieldName] ~= nil then
      Visit(FieldName)
    end
  end
  for FieldName in pairs(TypeInfo.FieldInfos) do
    if not Visited[FieldName] then
      Visit(FieldName)
    end
  end
  return Result
end

local function GetDefaultEnum(FieldInfo, Default)
  local Constraint = FieldInfo.Constraint
  if nil == Constraint then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\231\188\186\229\176\145\230\158\154\228\184\190\231\186\166\230\157\159\228\191\161\230\129\175", FieldInfo.Name)
    return Default
  end
  local EnumName = Constraint.Enum and Constraint.Enum.EnumName
  if not RTTIBase.IsValidStringValue(EnumName) then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\158\154\228\184\190\231\177\187\229\158\139\230\156\170\230\179\168\229\134\140\230\136\150\228\184\186\231\169\186", FieldInfo.Name)
    return Default
  end
  local EnumInfo = RTTICore:GetEnumInfo(EnumName)
  if nil == EnumInfo then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\178\161\230\156\137\229\174\154\228\185\137\230\158\154\228\184\190\231\177\187\229\158\139\228\191\161\230\129\175", FieldInfo.Name)
    return Default
  end
  local FieldOrder = EnumInfo.FieldOrder
  if nil == FieldOrder or 0 == #FieldOrder then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\178\161\230\156\137\229\174\154\228\185\137\230\158\154\228\184\190\229\128\188\229\136\151\232\161\168", FieldInfo.Name)
    return Default
  end
  local FieldInfos = EnumInfo.FieldInfos
  if nil == FieldInfos then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\158\154\228\184\190\229\173\151\230\174\181\228\191\161\230\129\175\231\188\186\229\164\177", FieldInfo.Name)
    return Default
  end
  local FirstName = FieldOrder[1]
  local FirstInfo = FieldInfos[FirstName]
  local FirstValue = FirstInfo and FirstInfo.Value
  if nil == FirstValue then
    return Default
  end
  return FirstValue
end

local function GetDefaultNumber(FieldInfo, Default, FieldType)
  local Constraint = FieldInfo.Constraint
  FieldType = FieldType or FieldInfo.Type
  local ValueLimit = Constraint and Constraint.ValueLimit
  if RTTIBase.IsValidTableValue(ValueLimit) then
    local Candidate
    local Ranges = ValueLimit.Ranges
    if RTTIBase.IsValidTableValue(Ranges) then
      for _, r in ipairs(Ranges) do
        if RTTIBase.IsValidTableValue(r) then
          local Min = r.Min
          local Max = r.Max
          local Pick
          if RTTIBase.IsValidNumberValue(Min) then
            Pick = Min
          elseif RTTIBase.IsValidNumberValue(Max) then
            Pick = Max
          end
          if RTTIBase.IsValidNumberValue(Pick) then
            local Current = Candidate
            if nil == Current or Pick < Current then
              Candidate = Pick
            end
          end
        end
      end
    end
    local Values = ValueLimit.Values
    if RTTIBase.IsValidTableValue(Values) then
      for _, v in ipairs(Values) do
        if RTTIBase.IsValidNumberValue(v) then
          local Current = Candidate
          if nil == Current or v < Current then
            Candidate = v
          end
        end
      end
    end
    if nil ~= Candidate and RTTIBase.IsValidNumberValue(Candidate) then
      Default = Candidate
    end
  end
  if RTTIBase.IsIntegerType(FieldType) and RTTIBase.IsValidNumberValue(Default) then
    Default = math.floor(Default)
  end
  return Default
end

local function GetDefaultStruct(FieldInfo, GetDefaultFunc, Default, Context)
  local Constraint = FieldInfo.Constraint
  if not RTTIBase.IsValidTableValue(Constraint) then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\178\161\230\156\137\229\174\154\228\185\137\231\187\147\230\158\132\228\189\147\231\186\166\230\157\159\228\191\161\230\129\175", FieldInfo.Name)
    return nil
  end
  local StructTypeName = Constraint.Type and Constraint.Type.TypeName
  if not RTTIBase.IsValidStringValue(StructTypeName) then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\178\161\230\156\137\229\174\154\228\185\137\231\187\147\230\158\132\228\189\147\231\177\187\229\158\139\231\186\166\230\157\159", FieldInfo.Name)
    return nil
  end
  local StructTypeInfo = RTTICore:GetTypeInfo(StructTypeName)
  if nil == StructTypeInfo then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\230\178\161\230\156\137\229\174\154\228\185\137\231\187\147\230\158\132\228\189\147\231\177\187\229\158\139\228\191\161\230\129\175", FieldInfo.Name)
    return nil
  end
  if nil == StructTypeInfo.FieldInfos then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\231\187\147\230\158\132\228\189\147\229\173\151\230\174\181\228\191\161\230\129\175\231\188\186\229\164\177", FieldInfo.Name)
    return nil
  end
  if not RTTIBase.IsValidTableValue(Default) then
    RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188\239\188\140\231\187\147\230\158\132\228\189\147\231\188\186\231\156\129\229\128\188\230\156\170\233\128\143\228\188\160\230\136\150\228\184\141\230\152\175\232\161\168", FieldInfo.Name)
    return nil
  end
  local FieldNames = BuildDefaultFieldOrder(StructTypeInfo)
  for _, StructFieldName in ipairs(FieldNames) do
    local StructFieldInfo = StructTypeInfo.FieldInfos[StructFieldName]
    if StructFieldInfo then
      local FinalStructFieldName = StructFieldInfo.Name or StructFieldName
      Default[FinalStructFieldName] = GetDefaultFunc(StructFieldInfo, StructTypeInfo, Default, Context)
    end
  end
  return Default
end

local DEFAULT_NIL = {}
local GetDefaultFieldValue = function(FieldInfo, TypeInfo, Data, Context)
  if nil == FieldInfo then
    return nil
  end
  Context = Context or {
    Memo = {},
    Visiting = {}
  }
  local FieldName = FieldInfo.Name
  local MemoKey = string.format("%s.%s", TypeInfo and TypeInfo.Name or "", FieldName)
  local MemoValue = Context.Memo[MemoKey]
  if MemoValue then
    if MemoValue == DEFAULT_NIL then
    end
    return MemoValue
  end
  if Context.Visiting[MemoKey] then
    return nil
  end
  Context.Visiting[MemoKey] = true
  local Default = FieldInfo.Default
  local EffectiveFieldInfo = FieldInfo
  if RTTIBase.IsValidTableValue(Default) then
    Default = RTTIBase.DeepCopy(Default)
  end
  if nil == Default then
    local Inferred = TypeInfo and RTTICore:InferFieldType(TypeInfo.Name, FieldName, Data)
    if Inferred then
      EffectiveFieldInfo = Inferred
    end
    local FieldType = EffectiveFieldInfo.Type
    if FieldType == RTTIBase.FieldType.BOOL then
      Default = false
    elseif FieldType == RTTIBase.FieldType.STRING then
      Default = ""
    elseif FieldType == RTTIBase.FieldType.ARRAY then
      Default = {}
    elseif RTTIBase.IsNumberType(FieldType) then
      Default = GetDefaultNumber(EffectiveFieldInfo, 0.0, FieldType)
    elseif FieldType == RTTIBase.FieldType.ENUM then
      Default = GetDefaultEnum(EffectiveFieldInfo, nil)
    elseif FieldType == RTTIBase.FieldType.STRUCT then
      local StructDefault = GetDefaultStruct(EffectiveFieldInfo, GetDefaultFieldValue, {}, Context)
      Context.Memo[MemoKey] = StructDefault or DEFAULT_NIL
      Context.Visiting[MemoKey] = nil
      return StructDefault
    else
      RTTIStatistics:RecordError(false, "\230\151\160\230\179\149\232\142\183\229\143\150\229\173\151\230\174\181\227\128\144%s\227\128\145\231\188\186\231\156\129\229\128\188, \229\173\151\230\174\181\231\177\187\229\158\139\228\184\141\232\175\134\229\136\171\227\128\144%s\227\128\145", FieldInfo.Name, tostring(FieldType))
      Default = nil
    end
  end
  Default = FixDefaultByFieldInfo(FieldInfo, Default, TypeInfo, Data)
  Context.Memo[MemoKey] = nil == Default and DEFAULT_NIL or Default
  Context.Visiting[MemoKey] = nil
  return Default
end

local function TraversePathForGet(Data, Path)
  local Tokens = BuildPathTokens(Path)
  local Depth = #Tokens
  local Node = Data
  for Index, Token in ipairs(Tokens) do
    local IsLast = Index == Depth
    if Token.IsArray then
      local Name = Token.Name
      local NumberIndex = Token.Index
      if nil == Node[Name] then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\174\185\229\153\168\227\128\144%s\227\128\145\228\184\141\229\173\152\229\156\168", Name)
        return nil
      end
      if not RTTIBase.IsValidTableValue(Node[Name]) then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\174\185\229\153\168\227\128\144%s\227\128\145\228\184\141\230\152\175\232\161\168", Name)
        return nil
      end
      Node = Node[Name]
      if nil == Node[NumberIndex] then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\180\162\229\188\149\227\128\144%d\227\128\145\228\184\141\229\173\152\229\156\168", Name, NumberIndex or -1)
        return nil
      end
      if not RTTIBase.IsValidTableValue(Node[NumberIndex]) and not IsLast then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\180\162\229\188\149\227\128\144%d\227\128\145\228\184\173\233\151\180\232\138\130\231\130\185\233\157\158\232\161\168", Name, NumberIndex or -1)
        return nil
      end
      Node = Node[NumberIndex]
    else
      local Segment = Token.Name
      if nil == Node[Segment] then
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\141\229\173\152\229\156\168", Segment)
        return nil
      end
      if not RTTIBase.IsValidTableValue(Node[Segment]) and not IsLast then
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\173\233\151\180\232\138\130\231\130\185\233\157\158\232\161\168", Segment)
        return nil
      end
      Node = Node[Segment]
    end
  end
  return Node
end

local function TraversePathForSet(TypeName, Data, Path)
  local Tokens = BuildPathTokens(Path)
  local Depth = #Tokens
  local Node = Data
  local CurrentTypeInfo = RTTICore:GetTypeInfo(TypeName)
  for Index, Token in ipairs(Tokens) do
    local IsLast = Index == Depth
    if Token.IsArray then
      local Name = Token.Name
      local NumberIndex = Token.Index
      local FieldInfo = CurrentTypeInfo and CurrentTypeInfo.FieldInfos and CurrentTypeInfo.FieldInfos[Name]
      if not FieldInfo then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\228\184\141\229\173\152\229\156\168\229\173\151\230\174\181\227\128\144%s\227\128\145", TypeName, Name)
        return nil, nil
      end
      if nil == Node[Name] then
        Node[Name] = {}
      end
      if not RTTIBase.IsValidTableValue(Node[Name]) then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\174\185\229\153\168\227\128\144%s\227\128\145\228\184\141\230\152\175\232\161\168", Name)
        return nil, nil
      end
      local ArrayNode = Node[Name]
      if not NumberIndex or NumberIndex < 1 then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\180\162\229\188\149\229\191\133\233\161\187\228\184\186\230\173\163\230\149\180\230\149\176(>=1): %s", Name, tostring(Token.Raw))
        return nil, nil
      end
      local ElementFieldInfo = RTTICore:BuildArrayElementFieldInfo(FieldInfo)
      if not ElementFieldInfo then
        RTTIStatistics:RecordError(true, "\230\151\160\230\179\149\232\142\183\229\143\150\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\229\133\131\231\180\160\229\173\151\230\174\181\228\191\161\230\129\175", Name)
        return nil, nil
      end
      for FillIndex = 1, NumberIndex do
        if nil == ArrayNode[FillIndex] then
          ArrayNode[FillIndex] = GetDefaultFieldValue(ElementFieldInfo)
        end
      end
      if IsLast then
        return ArrayNode, NumberIndex
      end
      Node = ArrayNode[NumberIndex]
      if not RTTIBase.IsValidTableValue(Node) then
        RTTIStatistics:RecordError(true, "\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\180\162\229\188\149\227\128\144%d\227\128\145\228\184\173\233\151\180\232\138\130\231\130\185\233\157\158\232\161\168", Name, NumberIndex)
        return nil, nil
      end
      local ElementType = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.ElementType
      if ElementType == RTTIBase.FieldType.STRUCT then
        local StructName = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
        CurrentTypeInfo = StructName and RTTICore:GetTypeInfo(StructName) or nil
      else
        CurrentTypeInfo = nil
      end
    else
      local Segment = Token.Name
      if IsLast then
        return Node, Segment
      end
      local FieldInfo = CurrentTypeInfo and CurrentTypeInfo.FieldInfos and CurrentTypeInfo.FieldInfos[Segment]
      if not FieldInfo then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\228\184\141\229\173\152\229\156\168\229\173\151\230\174\181\227\128\144%s\227\128\145", TypeName, Segment)
        return nil, nil
      end
      if nil == Node[Segment] then
        Node[Segment] = {}
      end
      if not RTTIBase.IsValidTableValue(Node[Segment]) then
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\173\233\151\180\232\138\130\231\130\185\233\157\158\232\161\168", Segment)
        return nil, nil
      end
      Node = Node[Segment]
      if FieldInfo.Type == RTTIBase.FieldType.STRUCT then
        local StructName = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
        CurrentTypeInfo = StructName and RTTICore:GetTypeInfo(StructName) or nil
      else
        CurrentTypeInfo = nil
      end
    end
  end
  return nil, nil
end

local function ValidatePropertyFieldPath(TypeName, Path)
  if not RTTIBase.IsValidStringValue(Path) then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\229\177\158\230\128\167\232\183\175\229\190\132\228\184\141\232\131\189\228\184\186\231\169\186", TypeName)
    return false
  end
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if not TypeInfo then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\156\170\230\179\168\229\134\140", TypeName)
    return false
  end
  local Tokens = BuildPathTokens(Path)
  local SegmentDepth = #Tokens
  if 0 == SegmentDepth then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\229\177\158\230\128\167\232\183\175\229\190\132\227\128\144%s\227\128\145\232\167\163\230\158\144\228\184\186\231\169\186", TypeName, Path)
    return false
  end
  local MaxPathDepth = RTTISettings:Get("Reflection.MaxPathDepth", 15)
  if SegmentDepth > MaxPathDepth then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\229\177\158\230\128\167\232\183\175\229\190\132\227\128\144%s\227\128\145\230\183\177\229\186\166\232\182\133\233\153\144:%d>%d", TypeName, Path, SegmentDepth, MaxPathDepth)
    return false
  end
  local CurrentTypeInfo = TypeInfo
  for Index, Token in ipairs(Tokens) do
    local FieldName = Token.Name
    if not (CurrentTypeInfo and CurrentTypeInfo.FieldInfos) or not CurrentTypeInfo.FieldInfos[FieldName] then
      RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\228\184\141\229\173\152\229\156\168\229\173\151\230\174\181\227\128\144%s\227\128\145", TypeName, FieldName)
      return false
    end
    local FieldInfo = CurrentTypeInfo.FieldInfos[FieldName]
    local IsLast = Index == SegmentDepth
    if Token.IsArray then
      if FieldInfo.Type ~= RTTIBase.FieldType.ARRAY then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\229\173\151\230\174\181\227\128\144%s\227\128\145\229\185\182\233\157\158\230\149\176\231\187\132\239\188\140\228\184\141\232\131\189\229\184\166\231\180\162\229\188\149", TypeName, FieldName)
        return false
      end
      local SizeLimit = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.Size
      local NumberIndex = Token.Index
      if not NumberIndex or NumberIndex < 1 then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\180\162\229\188\149\229\191\133\233\161\187\228\184\186\230\173\163\230\149\180\230\149\176(>=1): %s", TypeName, FieldName, tostring(Token.Raw))
        return false
      end
      if SizeLimit and SizeLimit < NumberIndex then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\180\162\229\188\149\232\182\138\231\149\140(%d>%d)", TypeName, FieldName, NumberIndex, SizeLimit)
        return false
      end
      local ElementType = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.ElementType
      local StructName = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
      if ElementType == RTTIBase.FieldType.STRUCT then
        CurrentTypeInfo = RTTICore:GetTypeInfo(StructName)
        if not CurrentTypeInfo then
          RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\229\133\131\231\180\160\231\177\187\229\158\139\227\128\144%s\227\128\145\230\156\170\230\179\168\229\134\140", TypeName, FieldName, StructName)
          return false
        end
      else
        if not IsLast then
          RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\231\187\132\229\159\186\231\161\128\229\133\131\231\180\160\229\173\151\230\174\181\227\128\144%s\227\128\145\229\144\142\228\184\141\229\133\129\232\174\184\231\187\167\231\187\173\232\174\191\233\151\174", TypeName, FieldName)
          return false
        end
        CurrentTypeInfo = nil
      end
    elseif FieldInfo.Type == RTTIBase.FieldType.STRUCT then
      local StructName = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
      CurrentTypeInfo = RTTICore:GetTypeInfo(StructName)
      if not CurrentTypeInfo then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\231\187\147\230\158\132\229\173\151\230\174\181\227\128\144%s\227\128\145\231\154\132\231\177\187\229\158\139\227\128\144%s\227\128\145\230\156\170\230\179\168\229\134\140", TypeName, FieldName, StructName)
        return false
      end
    elseif FieldInfo.Type == RTTIBase.FieldType.ARRAY then
      if not IsLast then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\149\176\231\187\132\229\173\151\230\174\181\227\128\144%s\227\128\145\233\156\128\229\184\166\231\180\162\229\188\149\229\144\142\230\137\141\232\131\189\232\174\191\233\151\174\229\173\144\229\173\151\230\174\181", TypeName, FieldName)
        return false
      end
      CurrentTypeInfo = nil
    else
      if not IsLast then
        RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\229\159\186\231\161\128\229\173\151\230\174\181\227\128\144%s\227\128\145\229\144\142\228\184\141\229\133\129\232\174\184\231\187\167\231\187\173\232\174\191\233\151\174", TypeName, FieldName)
        return false
      end
      CurrentTypeInfo = nil
    end
  end
  return true
end

local function CreateInstanceInternal(self, TypeName)
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if TypeInfo and TypeInfo.FieldInfos then
    local Instance = {}
    local DefaultContext = {
      Memo = {},
      Visiting = {}
    }
    local FieldNames = BuildDefaultFieldOrder(TypeInfo)
    for _, FieldName in ipairs(FieldNames) do
      local FieldInfo = TypeInfo.FieldInfos[FieldName]
      if FieldInfo then
        local NeedDefault = true
        if FieldInfo.Constraint.PrimaryKey then
          local PrimaryKeyValue = self:GeneratePrimaryKeyValue(TypeName)
          if nil ~= PrimaryKeyValue then
            Instance[FieldName] = PrimaryKeyValue
            NeedDefault = false
          end
        end
        if NeedDefault then
          Instance[FieldName] = GetDefaultFieldValue(FieldInfo, TypeInfo, Instance, DefaultContext)
        end
      end
    end
    return Instance
  end
  return nil
end

local DuplicateInstanceInternal = function(TypeName, Object, InvalidFields)
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if TypeInfo and TypeInfo.FieldInfos then
    local Instance = {}
    for FieldName, FieldInfo in pairs(TypeInfo.FieldInfos) do
      local FinalFieldName = FieldInfo.Name or FieldName
      local FieldValue = Object[FinalFieldName]
      if nil ~= FieldValue then
        local FieldType = FieldInfo.Type
        if FieldType == RTTIBase.FieldType.STRUCT then
          local StructInstance = DuplicateInstanceInternal(FieldInfo.Constraint.Type.TypeName, FieldValue, InvalidFields)
          Instance[FinalFieldName] = StructInstance
        elseif FieldType == RTTIBase.FieldType.ARRAY then
          local ElementType = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.ElementType
          if RTTIBase.IsValidFieldType(ElementType) then
            local ArrayInstance = {}
            for _, ArrayElement in ipairs(FieldValue) do
              if RTTIBase.IsPrimitiveType(ElementType) then
                table.insert(ArrayInstance, ArrayElement)
              else
                local ElementInstance = DuplicateInstanceInternal(ElementType, ArrayElement, InvalidFields)
                if ElementInstance then
                  table.insert(ArrayInstance, ElementInstance)
                end
              end
            end
            Instance[FinalFieldName] = ArrayInstance
          else
            table.insert(InvalidFields, FinalFieldName)
          end
        elseif RTTIBase.IsPrimitiveType(FieldType) then
          Instance[FinalFieldName] = FieldValue
        else
          table.insert(InvalidFields, FinalFieldName)
        end
      else
        table.insert(InvalidFields, FinalFieldName)
      end
    end
    return Instance
  end
  return nil
end

local function GetOrCreateDirtyBucket(self, TypeName)
  local PrimaryKeyName = RTTICore:GetPrimaryKeyName(TypeName)
  if nil == PrimaryKeyName then
    return nil
  end
  local DirtyBucketByTypeName = self.DirtyBucketByTypeName
  local DirtyBucket = DirtyBucketByTypeName[TypeName]
  if nil == DirtyBucket then
    DirtyBucket = {
      PrimaryKeyName = PrimaryKeyName,
      DataMap = {}
    }
    DirtyBucketByTypeName[TypeName] = DirtyBucket
  end
  return DirtyBucket
end

local function CollectDirtyData(self, TypeName, Data)
  local DirtyBucket = GetOrCreateDirtyBucket(self, TypeName)
  if nil == DirtyBucket then
    return false
  end
  local PrimaryKeyValue = Data[DirtyBucket.PrimaryKeyName]
  if nil == PrimaryKeyValue then
    return false
  end
  local IsDirty = RTTIBase.HasDataFlag(Data, RTTIBase.DataFlagType.Dirty)
  local DirtyData = DirtyBucket.DataMap[PrimaryKeyValue]
  if IsDirty then
    if nil == DirtyData then
      DirtyBucket.DataMap[PrimaryKeyValue] = Data
      return true
    end
    if DirtyData == Data then
      return true
    end
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\230\149\176\230\141\174\227\128\144%s\227\128\145\233\148\174\229\128\188\228\184\186\227\128\144%s\227\128\145\229\183\178\231\187\143\232\162\171\231\188\147\229\173\152\232\191\135\228\186\134", TypeName, tostring(PrimaryKeyValue))
    return false
  end
  if DirtyData == Data then
    DirtyBucket.DataMap[PrimaryKeyValue] = nil
    return true
  end
  return false
end

local function SaveDirtyData(TypeName, Data, ForceCreate)
  local RTTIValidator = require("NewRoco.Modules.System.PGC.RTTI.RTTIValidator")
  local Result = RTTIValidator:ValidateRecord(TypeName, Data)
  if not Result.Success then
    return false
  end
  if RTTIBase.HasDataFlag(Data, RTTIBase.DataFlagType.Destroy) then
    local _, PrimaryKeyValue = RTTICore:GetPrimaryKeyValue(TypeName, Data)
    return RTTIYamlStore:DeleteRecord(TypeName, PrimaryKeyValue)
  end
  return RTTIYamlStore:UpsertRecord(TypeName, Data, ForceCreate)
end

local function LoadUserInfo(self)
  local ProjectDir = UE.UBlueprintPathsLibrary.ProjectDir()
  local RegionFilePath = ProjectDir .. RTTISettings:Get("Reflection.RegionFile")
  local File = io.open(RegionFilePath, "r")
  if not File then
    return
  end
  local InAccounts = false
  for Line in File:lines() do
    Line = tostring(Line):gsub("\r$", "")
    if "" ~= Line and not Line:match("^%s*$") and not Line:match("^%s*#") then
      if Line:match("^[^%s]") then
        if Line:match("^Accounts:%s*$") then
          InAccounts = true
        else
          InAccounts = false
        end
      else
        if InAccounts then
          local UserName, UserIdStr = Line:match("^%s*([^:%s]+)%s*:%s*(%-?%d+)%s*$")
          if UserName and UserIdStr then
            local UserId = tonumber(UserIdStr)
            if nil ~= UserId then
              self.UserIdByUserName[UserName] = UserId
              if nil == self.UserNameByUserId[UserId] then
                self.UserNameByUserId[UserId] = UserName
              end
            end
          end
        else
        end
      end
    end
  end
  local UserName = RTTISettings:Get("User.Name")
  local UserId = self.UserIdByUserName[UserName] or 0
  RTTISettings:Set("User.Id", UserId)
  File:close()
end

local function LoadPrimaryKeyRule(self)
  local ProjectDir = UE.UBlueprintPathsLibrary.ProjectDir()
  local RulesFilePath = ProjectDir .. RTTISettings:Get("Reflection.RulesFile")
  local File = io.open(RulesFilePath, "r")
  if not File then
    return
  end
  local CurrentTypeName, CurrentRule, CurrentPadding
  
  local function FlushRule()
    if RTTIBase.IsValidStringValue(CurrentTypeName) then
      if nil == CurrentPadding then
        CurrentPadding = RTTISettings:Get(string.format("Ruler.%s.new_key_padding", CurrentTypeName))
      end
      self.NewKeyRuleCache[CurrentTypeName] = {Rule = CurrentRule, Padding = CurrentPadding}
    end
  end
  
  for Line in File:lines() do
    Line = tostring(Line):gsub("\r$", "")
    if "" ~= Line and not Line:match("^%s*$") and not Line:match("^%s*#") then
      if Line:match("^[^%s]") then
        do
          FlushRule()
          CurrentTypeName = nil
          CurrentRule = nil
          CurrentPadding = nil
          local Key, Rest = Line:match("^([^:%s]+)%s*:%s*(.*)$")
          if Key and Rest and Rest:match("!<Rule>") then
            CurrentTypeName = Key
          end
        end
      else
        if RTTIBase.IsValidStringValue(CurrentTypeName) then
          local Rule = Line:match("new_key_rule:%s*!NewKeyTypeEnum%s*'([^']+)'%s*")
          if Rule then
            CurrentRule = Rule
          end
          local Padding = Line:match("new_key_padding:%s*(%d+)")
          if Padding then
            CurrentPadding = tonumber(Padding)
          end
        else
        end
      end
    end
  end
  FlushRule()
  File:close()
end

local function GeneratePrimaryKeyValueByKeyRule(self, TypeName)
  local PrimaryKeyName = RTTICore:GetPrimaryKeyName(TypeName)
  local PrimaryKeyFieldInfo = RTTICore:GetFieldInfo(TypeName, PrimaryKeyName)
  if not PrimaryKeyFieldInfo or not RTTIBase.IsIntegerType(PrimaryKeyFieldInfo.Type) then
    return nil
  end
  local DEFAULT_USER_KEY_PADDING = 10000000
  local Cache = self.NewKeyRuleCache[TypeName]
  local NewKeyRule = Cache and Cache.Rule or nil
  local NewKeyPadding = Cache and Cache.Padding or nil
  
  local function ForeachPrimaryKeyValues(PrimaryKeyValueVistor)
    local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
    local PrimaryKeyValues = RTTIDataProvider:GetAllPrimaryKeyValues(TypeName) or {}
    for _, Key in ipairs(PrimaryKeyValues) do
      local KeyValue = tonumber(Key)
      PrimaryKeyValueVistor(KeyValue)
    end
  end
  
  if "LOCAL_INCR" == NewKeyRule then
    local Padding = DEFAULT_USER_KEY_PADDING
    if type(NewKeyPadding) == "number" and NewKeyPadding > 0 then
      Padding = math.floor(10 ^ NewKeyPadding)
    end
    local UserId = RTTISettings:Get("User.Id")
    local UserRangeMin = UserId * Padding
    local UserRangeMaxExclusive = (UserId + 1) * Padding
    local CacheByUser = self.PrimaryKeyMaxValuesByUser[TypeName]
    if nil == CacheByUser then
      CacheByUser = {}
      self.PrimaryKeyMaxValuesByUser[TypeName] = CacheByUser
    end
    local MaxKey = CacheByUser[UserId]
    if nil == MaxKey then
      ForeachPrimaryKeyValues(function(KeyValue)
        if nil ~= KeyValue and KeyValue >= UserRangeMin and KeyValue < UserRangeMaxExclusive and (nil == MaxKey or KeyValue > MaxKey) then
          MaxKey = KeyValue
        end
      end)
      MaxKey = MaxKey or UserRangeMin
    end
    local NextKey = MaxKey + 1
    if UserRangeMaxExclusive <= NextKey then
      return nil
    end
    CacheByUser[UserId] = NextKey
    return NextKey
  end
  local MaxKey = self.PrimaryKeyMaxValues[TypeName]
  if nil == MaxKey then
    ForeachPrimaryKeyValues(function(KeyValue)
      if nil ~= KeyValue and (nil == MaxKey or KeyValue > MaxKey) then
        MaxKey = KeyValue
      end
    end)
    MaxKey = MaxKey or 0
  end
  MaxKey = MaxKey + 1
  self.PrimaryKeyMaxValues[TypeName] = MaxKey
  return MaxKey
end

function RTTIReflection:Initialize()
  self:Reset()
end

function RTTIReflection:Reset()
  self.DirtyBucketByTypeName = {}
  self.PrimaryKeyGenerateHooks = {}
  self.PrimaryKeyMaxValues = {}
  self.NewKeyRuleCache = {}
  self.PrimaryKeyMaxValuesByUser = {}
  self.UserIdByUserName = {}
  self.UserNameByUserId = {}
  LoadUserInfo(self)
  LoadPrimaryKeyRule(self)
end

function RTTIReflection:RegisterPrimaryKeyGenerateHook(TypeName, Hook)
  if not RTTIBase.IsValidStringValue(TypeName) then
    return false
  end
  if type(Hook) ~= "function" then
    return false
  end
  self.PrimaryKeyGenerateHooks[TypeName] = Hook
  return true
end

function RTTIReflection:UnregisterPrimaryKeyGenerateHook(TypeName)
  self.PrimaryKeyGenerateHooks[TypeName] = nil
end

function RTTIReflection:GeneratePrimaryKeyValue(TypeName)
  if not RTTIBase.IsValidStringValue(TypeName) then
    return nil
  end
  local Hook = self.PrimaryKeyGenerateHooks[TypeName]
  if nil ~= Hook then
    local Ok, Value = pcall(Hook, TypeName)
    if Ok and nil ~= Value then
      return Value
    end
    return nil
  end
  return GeneratePrimaryKeyValueByKeyRule(self, TypeName)
end

function RTTIReflection:CreateInstance(TypeName)
  local Instance = CreateInstanceInternal(self, TypeName)
  if nil == Instance then
    return nil
  end
  local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
  if RTTIDataProvider:InsertRecord(TypeName, Instance) then
  end
  RTTIBase.AddDataFlag(Instance, RTTIBase.DataFlagType.Create)
  RTTIBase.AddDataFlag(Instance, RTTIBase.DataFlagType.Dirty)
  CollectDirtyData(self, TypeName, Instance)
  return Instance
end

function RTTIReflection:DestroyInstance(TypeName, KeyValue)
  local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
  local Instance = RTTIDataProvider:QueryByPrimaryKey(TypeName, KeyValue)
  if nil == Instance then
    return false
  end
  RTTIBase.AddDataFlag(Instance, RTTIBase.DataFlagType.Destroy)
  RTTIBase.RemoveDataFlag(Instance, RTTIBase.DataFlagType.Create)
  RTTIBase.AddDataFlag(Instance, RTTIBase.DataFlagType.Dirty)
  CollectDirtyData(self, TypeName, Instance)
  RTTIDataProvider:DeleteRecord(TypeName, KeyValue)
  return true
end

function RTTIReflection:DuplicateInstance(TypeName, Source, Force)
  local Instance
  local InvalidFields = {}
  local SourceMetatable = getmetatable(Source)
  local SourceIsDuplicated = not SourceMetatable and RTTIBase.HasDataFlag(Source, RTTIBase.DataFlagType.Duplicate) or false
  if not Force and SourceIsDuplicated then
    Instance = Source
  else
    Instance = DuplicateInstanceInternal(TypeName, Source, InvalidFields)
    if nil == Instance then
      return nil, InvalidFields
    end
    RTTIBase.AddDataFlag(Instance, RTTIBase.DataFlagType.Duplicate)
    if SourceIsDuplicated then
      RTTIBase.AddDataFlag(Instance, RTTIBase.DataFlagType.Dirty)
    else
      local BackupData = RTTIBase.DeepCopy(Instance)
      RTTIBase.SetUserData(Instance, "BackupData", BackupData)
    end
  end
  CollectDirtyData(self, TypeName, Instance)
  return Instance, InvalidFields
end

function RTTIReflection:DeepEquals(Left, Right)
  if type(Left) ~= type(Right) then
    return false
  end
  if not RTTIBase.IsValidTableValue(Left) then
    return Left == Right
  end
  for Key, Value in pairs(Left) do
    if RTTIBase.FilterFieldName(Key) and not self:DeepEquals(Value, Right[Key]) then
      return false
    end
  end
  for Key, Value in pairs(Right) do
    if RTTIBase.FilterFieldName(Key) and nil == Left[Key] then
      if "" == Value then
        return true
      else
        return false
      end
    end
  end
  return true
end

function RTTIReflection:GetProperty(TypeName, Data, Path)
  local EnablePropertyCache = RTTISettings:Get("Reflection.EnablePropertyCache")
  local CacheOptions
  if EnablePropertyCache then
    CacheOptions = BuildPropertyCacheOptions(TypeName, Data, Path)
    local CachedValue = RTTICache:GetCache(RTTIBase.CacheType.PROPERTY, CacheOptions)
    if CachedValue and CachedValue.Exists then
      return CachedValue.Value
    end
  end
  if not ValidatePropertyFieldPath(TypeName, Path) then
    return nil
  end
  local Node = TraversePathForGet(Data, Path)
  RTTIStatistics:RecordOperation("GetProperty", {TypeName = TypeName, Path = Path})
  if EnablePropertyCache then
    RTTICache:SetCache(RTTIBase.CacheType.PROPERTY, {
      Value = Node,
      Exists = nil ~= Node
    }, CacheOptions)
  end
  return Node
end

function RTTIReflection:SetProperty(TypeName, Data, Path, Value)
  if not ValidatePropertyFieldPath(TypeName, Path) then
    return false
  end
  local Parent, LastKey = TraversePathForSet(TypeName, Data, Path)
  if type(Parent) ~= "table" or nil == LastKey then
    return false
  end
  local OldValue = Parent[LastKey]
  if self:DeepEquals(OldValue, Value) then
    return false
  end
  Parent[LastKey] = Value
  RTTIStatistics:RecordOperation("SetProperty", {
    TypeName = TypeName,
    Path = Path,
    ValueType = type(Value)
  })
  local BackupData = RTTIBase.GetUserData(Data, "BackupData")
  if self:DeepEquals(BackupData, Data) then
    RTTIBase.RemoveDataFlag(Data, RTTIBase.DataFlagType.Dirty)
  else
    RTTIBase.AddDataFlag(Data, RTTIBase.DataFlagType.Dirty)
  end
  CollectDirtyData(self, TypeName, Data)
  local EnablePropertyCache = RTTISettings:Get("Reflection.EnablePropertyCache")
  if EnablePropertyCache then
    local CacheOptions = BuildPropertyCacheOptions(TypeName, Data, Path)
    RTTICache:RemoveCache(RTTIBase.CacheType.PROPERTY, CacheOptions)
  end
  return true
end

function RTTIReflection:SaveDirtyBucket(TypeName, ForceCreate)
  local Result = {
    Success = true,
    SuccessCount = 0,
    FailCount = 0,
    TotalCount = 0,
    Results = {}
  }
  local DirtyBucket = self.DirtyBucketByTypeName[TypeName]
  if DirtyBucket then
    local DirtyBucketDataMap = {}
    for PrimaryKey, DirtyData in pairs(DirtyBucket.DataMap) do
      DirtyBucketDataMap[PrimaryKey] = DirtyData
    end
    for PrimaryKey, DirtyData in pairs(DirtyBucketDataMap) do
      local Success = SaveDirtyData(TypeName, DirtyData, ForceCreate)
      if Success then
        local BackupData = RTTIBase.DeepCopy(DirtyData)
        RTTIBase.SetUserData(DirtyData, "BackupData", BackupData)
        Result.SuccessCount = Result.SuccessCount + 1
        RTTIBase.RemoveDataFlag(DirtyData, RTTIBase.DataFlagType.Dirty)
        RTTIBase.RemoveDataFlag(DirtyData, RTTIBase.DataFlagType.Create)
        RTTIBase.RemoveDataFlag(DirtyData, RTTIBase.DataFlagType.Destroy)
        DirtyBucket.DataMap[PrimaryKey] = nil
      else
        Result.FailCount = Result.FailCount + 1
      end
      Result.TotalCount = Result.TotalCount + 1
      table.insert(Result.Results, {PrimaryKey = PrimaryKey, Success = Success})
      Result.Success = Result.Success and Success
    end
  end
  return Result
end

function RTTIReflection:InsertYamlRecord(TypeName, Data)
  local _ = self
  local RTTIValidator = require("NewRoco.Modules.System.PGC.RTTI.RTTIValidator")
  local Result = RTTIValidator:ValidateRecord(TypeName, Data)
  if not Result.Success then
    return false
  end
  return RTTIYamlStore:InsertRecord(TypeName, Data)
end

function RTTIReflection:ModifyYamlRecord(TypeName, Data)
  local _ = self
  local RTTIValidator = require("NewRoco.Modules.System.PGC.RTTI.RTTIValidator")
  local Result = RTTIValidator:ValidateRecord(TypeName, Data)
  if not Result.Success then
    return false
  end
  return RTTIYamlStore:ModifyRecord(TypeName, Data)
end

function RTTIReflection:DeleteYamlRecord(TypeName, PrimaryKeyValue)
  local _ = self
  return RTTIYamlStore:DeleteRecord(TypeName, PrimaryKeyValue)
end

function RTTIReflection:Serialize(TypeName, Data, Format)
  if RTTISettings:Get("Reflection.EnableSerialization") == false then
    RTTIStatistics:RecordError(true, "\229\186\143\229\136\151\229\140\150\229\138\159\232\131\189\229\183\178\231\166\129\231\148\168")
    return
  end
  local Serializer = self.Serializers[string.lower(Format or "json")]
  if not Serializer then
    RTTIStatistics:RecordError(true, "\228\184\141\230\148\175\230\140\129\231\154\132\229\186\143\229\136\151\229\140\150\230\160\188\229\188\143\227\128\144%s\227\128\145", Format)
    return
  end
  local StartTime = os.clock()
  local Result = Serializer:Serialize(TypeName, Data)
  local Duration = os.clock() - StartTime
  RTTIStatistics:RecordOperation("Serialize", {
    TypeName = TypeName,
    Format = Format,
    Duration = Duration,
    Success = nil ~= Result
  })
  return Result
end

function RTTIReflection:Deserialize(TypeName, Serialized, Format)
  if RTTISettings:Get("Reflection.EnableSerialization") == false then
    RTTIStatistics:RecordError(true, "\229\186\143\229\136\151\229\140\150\229\138\159\232\131\189\229\183\178\231\166\129\231\148\168")
    return nil
  end
  local Serializer = self.Serializers[string.lower(Format or "json")]
  if not Serializer then
    RTTIStatistics:RecordError(true, "\228\184\141\230\148\175\230\140\129\231\154\132\229\186\143\229\136\151\229\140\150\230\160\188\229\188\143\227\128\144%s\227\128\145", Format)
    return nil
  end
  local StartTime = os.clock()
  local Result = Serializer:Deserialize(TypeName, Serialized)
  local Duration = os.clock() - StartTime
  RTTIStatistics:RecordOperation("Deserialize", {
    TypeName = TypeName,
    Format = Format,
    Duration = Duration,
    Success = nil ~= Result
  })
  return Result
end

return RTTIReflection

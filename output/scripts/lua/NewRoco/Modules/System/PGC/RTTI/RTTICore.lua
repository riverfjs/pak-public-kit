local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTICore = {
  TypeInfos = {},
  EnumInfos = {}
}

local function NormalizeField(FieldDefine)
  if not RTTIBase.IsValidTableValue(FieldDefine) then
    RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\229\191\133\233\161\187\228\184\186table")
    return nil
  end
  local FieldName = FieldDefine.Name
  if not RTTIBase.IsValidStringValue(FieldName) then
    RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\231\188\186\229\176\145Name")
    return nil
  end
  local FieldType = FieldDefine.Type
  if not RTTIBase.IsValidStringValue(FieldType) then
    RTTIStatistics:RecordError(true, "\229\173\151\230\174\181%s\231\188\186\229\176\145Type", FieldName)
    return nil
  end
  if not RTTIBase.IsValidFieldType(FieldType) then
    RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145Type\233\157\158\230\179\149: %s", FieldName, tostring(FieldType))
    return nil
  end
  local FieldInfo = {
    Name = FieldName,
    Type = FieldType,
    Description = FieldDefine.Description or "",
    Scope = FieldDefine.Scope or RTTIBase.ScopeType.Default,
    Default = FieldDefine.Default,
    Constraint = {}
  }
  if RTTIBase.IsComplexType(FieldType) then
    FieldInfo.Default = nil
  end
  if RTTIBase.IsValidTableValue(FieldDefine.Constraints) then
    for _, Constraint in ipairs(FieldDefine.Constraints) do
      if not RTTIBase.IsValidTableValue(Constraint) or not RTTIBase.IsValidStringValue(Constraint.Type) then
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\231\186\166\230\157\159\233\161\185\229\191\133\233\161\187\228\184\186table\228\184\148\229\140\133\229\144\171\230\156\137\230\149\136Type", FieldName)
        return nil
      end
      if Constraint.Type == RTTIBase.ConstraintType.LIMIT_VALUE then
        local Values = Constraint.Values
        local Ranges = Constraint.Ranges
        if Values and not RTTIBase.IsValidTableValue(Values) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145ValueLimit.Values\229\191\133\233\161\187\228\184\186\230\149\176\231\187\132", FieldName)
          return nil
        end
        if Ranges and not RTTIBase.IsValidTableValue(Ranges) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145ValueLimit.Ranges\229\191\133\233\161\187\228\184\186\230\149\176\231\187\132", FieldName)
          return nil
        end
        FieldInfo.Constraint.ValueLimit = {Values = Values, Ranges = Ranges}
      elseif Constraint.Type == RTTIBase.ConstraintType.LIMIT_SIZE then
        local Values = Constraint.Values
        local Ranges = Constraint.Ranges
        if Values and not RTTIBase.IsValidTableValue(Values) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145SizeLimit.Values\229\191\133\233\161\187\228\184\186\230\149\176\231\187\132", FieldName)
          return nil
        end
        if Ranges and not RTTIBase.IsValidTableValue(Ranges) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145SizeLimit.Ranges\229\191\133\233\161\187\228\184\186\230\149\176\231\187\132", FieldName)
          return nil
        end
        FieldInfo.Constraint.SizeLimit = {Values = Values, Ranges = Ranges}
      elseif Constraint.Type == RTTIBase.ConstraintType.LIMIT_LENGTH then
        local Values = Constraint.Values
        local Ranges = Constraint.Ranges
        if Values and not RTTIBase.IsValidTableValue(Values) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145LengthLimit.Values\229\191\133\233\161\187\228\184\186\230\149\176\231\187\132", FieldName)
          return nil
        end
        if Ranges and not RTTIBase.IsValidTableValue(Ranges) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145LengthLimit.Ranges\229\191\133\233\161\187\228\184\186\230\149\176\231\187\132", FieldName)
          return nil
        end
        FieldInfo.Constraint.LengthLimit = {Values = Values, Ranges = Ranges}
      elseif Constraint.Type == RTTIBase.ConstraintType.LIMIT_NOEMPTY then
        FieldInfo.Constraint.NotEmpty = true
      elseif Constraint.Type == RTTIBase.ConstraintType.INDEX then
        FieldInfo.Constraint.Index = true
      elseif Constraint.Type == RTTIBase.ConstraintType.UNIQUE then
        FieldInfo.Constraint.Unique = true
      elseif Constraint.Type == RTTIBase.ConstraintType.TYPE then
        if not RTTIBase.IsValidStringValue(Constraint.TypeName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145Type\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136TypeName", FieldName)
          return nil
        end
        FieldInfo.Constraint.Type = {
          TypeName = Constraint.TypeName
        }
      elseif Constraint.Type == RTTIBase.ConstraintType.ENUM then
        local EnumName = Constraint.EnumName
        if not RTTIBase.IsValidStringValue(EnumName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145Enum\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136EnumName", FieldName)
          return nil
        end
        FieldInfo.Constraint.Enum = {EnumName = EnumName}
      elseif Constraint.Type == RTTIBase.ConstraintType.ARRAY then
        if not RTTIBase.IsValidStringValue(Constraint.ElementType) or not RTTIBase.IsValidFieldType(Constraint.ElementType) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145Array\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136ElementType", FieldName)
          return nil
        end
        if Constraint.Size and not RTTIBase.IsValidNumberValue(Constraint.Size, true) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145Array.Size\229\191\133\233\161\187\228\184\186\230\149\180\230\149\176number", FieldName)
          return nil
        end
        FieldInfo.Constraint.Array = {
          Size = Constraint.Size,
          ElementType = Constraint.ElementType
        }
      elseif Constraint.Type == RTTIBase.ConstraintType.PRIMARY_KEY then
        FieldInfo.Constraint.PrimaryKey = true
      elseif Constraint.Type == RTTIBase.ConstraintType.FOREIGN_KEY then
        if not RTTIBase.IsValidStringValue(Constraint.TypeName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145ForeignKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136TypeName", FieldName)
          return nil
        end
        if not RTTIBase.IsValidStringValue(Constraint.FieldName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145ForeignKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136FieldName", FieldName)
          return nil
        end
        FieldInfo.Constraint.ForeignKey = {
          TypeName = Constraint.TypeName,
          FieldName = Constraint.FieldName
        }
      elseif Constraint.Type == RTTIBase.ConstraintType.CONDITION_KEY then
        if not RTTIBase.IsValidStringValue(Constraint.DriverField) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145ConditionKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136DriverField", FieldName)
          return nil
        end
        if not RTTIBase.IsValidTableValue(Constraint.Branches) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145ConditionKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171Branches\232\161\168", FieldName)
          return nil
        end
        FieldInfo.Constraint.ConditionKey = {
          DriverField = Constraint.DriverField,
          Branches = Constraint.Branches
        }
      elseif Constraint.Type == RTTIBase.ConstraintType.SMART_FOREIGN_KEY then
        if not RTTIBase.IsValidStringValue(Constraint.EnumName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145SmartForeignKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136EnumName", FieldName)
          return nil
        end
        if not RTTIBase.IsValidStringValue(Constraint.DriverField) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145SmartForeignKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136DriverField", FieldName)
          return nil
        end
        if not RTTIBase.IsValidStringValue(Constraint.LinkFieldName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145SmartForeignKey\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136LinkFieldName", FieldName)
          return nil
        end
        local Existing = FieldInfo.Constraint.SmartForeignKey
        local Item = {
          EnumName = Constraint.EnumName,
          DriverField = Constraint.DriverField,
          LinkFieldName = Constraint.LinkFieldName
        }
        if nil == Existing then
          FieldInfo.Constraint.SmartForeignKey = {Item}
        elseif type(Existing) == "table" and nil ~= Existing.EnumName then
          FieldInfo.Constraint.SmartForeignKey = {Existing, Item}
        elseif type(Existing) == "table" then
          table.insert(Existing, Item)
        else
          FieldInfo.Constraint.SmartForeignKey = {Item}
        end
      elseif Constraint.Type == RTTIBase.ConstraintType.LOCALE_NAME then
        if not RTTIBase.IsValidStringValue(Constraint.LocaleName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145LocaleName\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136LocaleName", FieldName)
          return nil
        end
        FieldInfo.Constraint.LocaleName = {
          LocaleName = Constraint.LocaleName
        }
      elseif Constraint.Type == RTTIBase.ConstraintType.CUSTOM then
        if not RTTIBase.IsValidStringValue(Constraint.RuleName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145Custom\231\186\166\230\157\159\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136RuleName", FieldName)
          return nil
        end
        FieldInfo.Constraint.Custom = {
          RuleName = Constraint.RuleName
        }
      else
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\229\173\152\229\156\168\230\156\170\231\159\165\231\186\166\230\157\159\231\177\187\229\158\139: %s", FieldName, tostring(Constraint.Type))
        return nil
      end
    end
  end
  if nil ~= FieldDefine.Required and FieldInfo.Constraint then
    FieldInfo.Constraint.Required = FieldDefine.Required
  end
  return FieldInfo
end

local function NormalizeType(TypeDefine)
  if not RTTIBase.IsValidTableValue(TypeDefine) then
    RTTIStatistics:RecordError(true, "TypeDefine\229\191\133\233\161\187\230\152\175table")
    return nil
  end
  local TypeName = TypeDefine.Name
  if not RTTIBase.IsValidStringValue(TypeName) then
    RTTIStatistics:RecordError(true, "TypeDefine\231\188\186\229\176\145Name")
    return nil
  end
  if not RTTIBase.IsValidTableValue(TypeDefine.Fields) then
    RTTIStatistics:RecordError(true, "TypeDefine.Fields\229\191\133\233\161\187\230\152\175\230\149\176\231\187\132")
    return nil
  end
  if #TypeDefine.Fields <= 0 then
    RTTIStatistics:RecordError(true, "TypeDefine\227\128\144%s\227\128\145Fields\228\184\141\232\131\189\228\184\186\231\169\186", TypeName)
    return nil
  end
  local TypeInfo = {
    Name = TypeName,
    Version = TypeDefine.Version or 1,
    Description = TypeDefine.Description or "",
    Alias = TypeDefine.Alias or "",
    Metadata = TypeDefine.Metadata or {},
    FieldOrder = {},
    FieldInfos = {}
  }
  for _, Field in ipairs(TypeDefine.Fields) do
    local FieldName = Field.Name
    if RTTIBase.IsValidFieldName(FieldName) then
      local FieldInfo = NormalizeField(Field)
      if not FieldInfo then
        RTTIStatistics:RecordError(true, "TypeDefine\227\128\144%s\227\128\145\229\173\151\230\174\181\229\189\146\228\184\128\229\140\150\229\164\177\232\180\165", TypeName)
        return nil
      end
      if TypeInfo.FieldInfos[FieldInfo.Name] then
        RTTIStatistics:RecordError(false, "TypeDefine\227\128\144%s\227\128\145\229\173\152\229\156\168\233\135\141\229\164\141\229\173\151\230\174\181\229\144\141: %s", TypeName, FieldInfo.Name)
      else
        table.insert(TypeInfo.FieldOrder, FieldInfo.Name)
        if FieldInfo.Constraint.PrimaryKey then
          if TypeInfo.PrimaryKeyName then
            RTTIStatistics:RecordError(true, "TypeDefine\227\128\144%s\227\128\145\229\173\152\229\156\168\229\164\154\228\184\170\228\184\187\233\148\174\229\173\151\230\174\181\227\128\144%s,%s\227\128\145", TypeName, TypeInfo.PrimaryKeyName, FieldInfo.Name)
            return nil
          else
            TypeInfo.PrimaryKeyName = FieldInfo.Name
          end
        end
        TypeInfo.FieldInfos[FieldInfo.Name] = FieldInfo
      end
    else
      RTTIStatistics:RecordError(false, "TypeDefine\227\128\144%s\227\128\145\229\173\151\230\174\181\229\144\141\233\157\158\230\179\149: %s", TypeName, tostring(FieldName))
    end
  end
  return TypeInfo
end

local function NormalizeEnum(EnumDefine)
  if not RTTIBase.IsValidTableValue(EnumDefine) then
    RTTIStatistics:RecordError(true, "EnumDefine\229\191\133\233\161\187\230\152\175table")
    return nil
  end
  local EnumName = EnumDefine.Name
  if not RTTIBase.IsValidStringValue(EnumName) then
    RTTIStatistics:RecordError(true, "EnumDefine\231\188\186\229\176\145Name")
    return nil
  end
  if not RTTIBase.IsValidTableValue(EnumDefine.Fields) then
    RTTIStatistics:RecordError(true, "EnumDefine\227\128\144%s\227\128\145Fields\229\191\133\233\161\187\230\152\175\230\149\176\231\187\132", EnumName)
    return nil
  end
  if #EnumDefine.Fields <= 0 then
    RTTIStatistics:RecordError(true, "EnumDefine\227\128\144%s\227\128\145Fields\228\184\141\232\131\189\228\184\186\231\169\186", EnumName)
    return nil
  end
  local EnumInfo = {
    Name = EnumName,
    Version = EnumDefine.Version or 1,
    Description = EnumDefine.Description or "",
    Metadata = type(EnumDefine.Metadata) == "table" and EnumDefine.Metadata or {},
    FieldOrder = {},
    FieldInfos = {},
    NameToValue = {},
    ValueToName = {}
  }
  for _, Field in ipairs(EnumDefine.Fields) do
    if not RTTIBase.IsValidTableValue(Field) then
      RTTIStatistics:RecordError(true, "EnumDefine\227\128\144%s\227\128\145Fields\233\161\185\229\191\133\233\161\187\228\184\186table", EnumName)
      return nil
    end
    local FieldName = Field.Name
    if not RTTIBase.IsValidFieldName(FieldName) then
      RTTIStatistics:RecordError(true, "EnumDefine\227\128\144%s\227\128\145\229\173\152\229\156\168\233\157\158\230\179\149\229\173\151\230\174\181\229\144\141: %s", EnumName, tostring(FieldName))
      return nil
    end
    local Value = Field.Value
    if not RTTIBase.IsValidNumberValue(Value, true) then
      RTTIStatistics:RecordError(true, "EnumDefine\227\128\144%s\227\128\145\229\173\151\230\174\181\227\128\144%s\227\128\145Value\229\191\133\233\161\187\228\184\186\230\149\180\230\149\176number", EnumName, FieldName)
      return nil
    end
    if EnumInfo.FieldInfos[FieldName] then
      RTTIStatistics:RecordError(false, "EnumDefine\227\128\144%s\227\128\145\229\173\152\229\156\168\233\135\141\229\164\141\230\158\154\228\184\190\233\161\185: %s", EnumName, FieldName)
    else
      local FieldInfo = {
        Name = FieldName,
        Value = Value,
        Description = Field.Description or ""
      }
      table.insert(EnumInfo.FieldOrder, FieldName)
      EnumInfo.FieldInfos[FieldName] = FieldInfo
      if EnumInfo.NameToValue[FieldName] ~= nil then
        RTTIStatistics:RecordError(false, "EnumDefine\227\128\144%s\227\128\145\229\173\152\229\156\168\233\135\141\229\164\141\230\158\154\228\184\190\229\144\141: %s", EnumName, FieldName)
      end
      EnumInfo.NameToValue[FieldName] = Value
      if EnumInfo.ValueToName[Value] ~= nil and EnumInfo.ValueToName[Value] ~= FieldName then
        RTTIStatistics:RecordError(false, "EnumDefine\227\128\144%s\227\128\145\229\173\152\229\156\168\233\135\141\229\164\141\230\158\154\228\184\190\229\128\188: %s", EnumName, tostring(Value))
      end
      EnumInfo.ValueToName[Value] = FieldName
    end
  end
  return EnumInfo
end

local function ValidateFieldInfo(FieldInfo)
  local Success = true
  local FieldName = FieldInfo.Name
  local Constraint = FieldInfo.Constraint or {}
  if FieldInfo.Type == RTTIBase.FieldType.ARRAY then
    local ConstraintArray = Constraint.Array
    if ConstraintArray then
      local ElementType = ConstraintArray.ElementType
      if ElementType == RTTIBase.FieldType.STRUCT then
        local StructTypeName = Constraint.Type and Constraint.Type.TypeName
        if not RTTIBase.IsValidStringValue(StructTypeName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\231\187\147\230\158\132\228\189\147\230\149\176\231\187\132\239\188\140\229\138\161\229\191\133\230\140\135\229\174\154\230\156\137\230\149\136\231\177\187\229\158\139\231\186\166\230\157\159(TypeName)", FieldName)
          Success = false
        elseif not RTTICore:HasType(StructTypeName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\231\187\147\230\158\132\228\189\147\230\149\176\231\187\132\239\188\140\229\133\131\231\180\160\231\177\187\229\158\139\227\128\144%s\227\128\145\229\176\154\230\156\170\229\174\154\228\185\137", FieldName, StructTypeName)
          Success = false
        end
        if ConstraintArray.Size ~= nil and ConstraintArray.Size <= 0 then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\231\187\147\230\158\132\228\189\147\230\149\176\231\187\132\239\188\140Array.Size \229\191\133\233\161\187\228\184\186\230\173\163\230\149\180\230\149\176", FieldName)
          Success = false
        end
      elseif ElementType == RTTIBase.FieldType.ENUM then
        local EnumName = Constraint.Enum and Constraint.Enum.EnumName
        if not RTTIBase.IsValidStringValue(EnumName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\230\158\154\228\184\190\230\149\176\231\187\132\239\188\140\229\138\161\229\191\133\230\140\135\229\174\154\230\156\137\230\149\136\230\158\154\228\184\190\231\186\166\230\157\159(EnumName)", FieldName)
          Success = false
        elseif not RTTICore:HasEnum(EnumName) then
          RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\230\158\154\228\184\190\230\149\176\231\187\132\239\188\140\230\158\154\228\184\190\231\177\187\229\158\139\227\128\144%s\227\128\145\229\176\154\230\156\170\230\179\168\229\134\140", FieldName, EnumName)
          Success = false
        end
      end
    else
      RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\230\149\176\231\187\132\231\177\187\229\158\139\239\188\140\229\138\161\229\191\133\230\140\135\229\174\154\230\149\176\231\187\132\231\186\166\230\157\159(Array)", FieldName)
      Success = false
    end
  elseif FieldInfo.Type == RTTIBase.FieldType.ENUM then
    local EnumName = Constraint.Enum and Constraint.Enum.EnumName
    if not RTTIBase.IsValidStringValue(EnumName) then
      RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\230\158\154\228\184\190\231\177\187\229\158\139\239\188\140\229\138\161\229\191\133\230\140\135\229\174\154\230\156\137\230\149\136\230\158\154\228\184\190\231\186\166\230\157\159(EnumName)", FieldName)
      Success = false
    elseif not RTTICore:HasEnum(EnumName) then
      RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\230\158\154\228\184\190\231\177\187\229\158\139\239\188\140\230\158\154\228\184\190\231\177\187\229\158\139\227\128\144%s\227\128\145\229\176\154\230\156\170\230\179\168\229\134\140", FieldName, EnumName)
      Success = false
    end
  elseif FieldInfo.Type == RTTIBase.FieldType.STRUCT then
    local ConstraintType = Constraint.Type
    if ConstraintType then
      local StructTypeName = ConstraintType.TypeName
      if not RTTIBase.IsValidStringValue(StructTypeName) then
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\231\187\147\230\158\132\231\177\187\229\158\139\239\188\140\229\138\161\229\191\133\230\140\135\229\174\154\230\156\137\230\149\136\231\177\187\229\158\139\231\186\166\230\157\159(TypeName)", FieldName)
        Success = false
      elseif not RTTICore:HasType(StructTypeName) then
        RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\231\187\147\230\158\132\231\177\187\229\158\139\227\128\144%s\227\128\145\229\176\154\230\156\170\229\174\154\228\185\137", FieldName, StructTypeName)
        Success = false
      end
    else
      RTTIStatistics:RecordError(true, "\229\173\151\230\174\181\227\128\144%s\227\128\145\228\184\186\231\187\147\230\158\132\231\177\187\229\158\139\239\188\140\229\138\161\229\191\133\230\140\135\229\174\154\231\177\187\229\158\139\231\186\166\230\157\159(Type)", FieldName)
      Success = false
    end
  end
  return Success
end

local function ValidateTypeInfo(TypeInfo)
  local Success = true
  for _, FieldInfo in pairs(TypeInfo.FieldInfos) do
    if not ValidateFieldInfo(FieldInfo) then
      Success = false
    end
  end
  if TypeInfo.Metadata.NeedPrimaryKey and TypeInfo.PrimaryKeyName == nil then
    RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\231\177\187\229\158\139\227\128\144%s\227\128\145\229\191\133\233\161\187\229\140\133\229\144\171\232\135\179\229\176\145\228\184\128\228\184\170\228\184\187\233\148\174\229\173\151\230\174\181", TypeInfo.Name)
    Success = false
  end
  return Success
end

local function BuildInferredFieldInfo(DeclaredFieldInfo, TargetFieldInfo)
  if nil == DeclaredFieldInfo or nil == TargetFieldInfo then
    return nil
  end
  local InferredFieldInfo = {
    Name = DeclaredFieldInfo.Name,
    Description = DeclaredFieldInfo.Description,
    Scope = DeclaredFieldInfo.Scope,
    Default = DeclaredFieldInfo.Default
  }
  if DeclaredFieldInfo.Type == RTTIBase.FieldType.ARRAY then
    local DeclaredArray = DeclaredFieldInfo.Constraint and DeclaredFieldInfo.Constraint.Array
    if nil == DeclaredArray then
      return DeclaredFieldInfo
    end
    local InferredConstraint = {
      Array = {
        Size = DeclaredArray.Size,
        ElementType = TargetFieldInfo.Type
      }
    }
    local TargetConstraint = TargetFieldInfo.Constraint
    if TargetConstraint then
      if TargetConstraint.ValueLimit then
        InferredConstraint.ValueLimit = TargetConstraint.ValueLimit
      end
      if TargetConstraint.Enum then
        InferredConstraint.Enum = TargetConstraint.Enum
      end
    end
    InferredFieldInfo.Type = RTTIBase.FieldType.ARRAY
    InferredFieldInfo.Constraint = InferredConstraint
  else
    InferredFieldInfo.Type = TargetFieldInfo.Type
    InferredFieldInfo.Constraint = TargetFieldInfo.Constraint
  end
  return InferredFieldInfo
end

function RTTICore:Initialize()
  self:Reset()
end

function RTTICore:Reset()
  self.TypeInfos = {}
  self.EnumInfos = {}
end

function RTTICore:BuildArrayElementFieldInfo(ArrayFieldInfo)
  if nil == ArrayFieldInfo or ArrayFieldInfo.Type ~= RTTIBase.FieldType.ARRAY then
    return nil
  end
  local Constraint = ArrayFieldInfo.Constraint
  local ElementType = Constraint.Array and Constraint.Array.ElementType
  return {
    Name = ArrayFieldInfo.Name .. ".Element",
    Type = ElementType,
    Constraint = Constraint
  }
end

function RTTICore:RegisterEnum(EnumName, EnumDefine)
  local StrictMode = RTTISettings:Get("Core.StrictMode")
  if not RTTIBase.IsValidStringValue(EnumName) then
    RTTIStatistics:RecordError(true, "EnumName\229\191\133\233\161\187\228\184\186\230\156\137\230\149\136\229\173\151\231\172\166\228\184\178")
    return false
  end
  if StrictMode then
    if self.EnumInfos[EnumName] then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\228\184\141\229\133\129\232\174\184\233\135\141\229\164\141\230\179\168\229\134\140\230\158\154\228\184\190: %s", EnumName)
      return false
    end
    if not RTTIBase.IsValidTableValue(EnumDefine) then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\158\154\228\184\190\227\128\144%s\227\128\145EnumDefine\229\191\133\233\161\187\230\152\175table", EnumName)
      return false
    end
    if not RTTIBase.IsValidTableValue(EnumDefine.Fields) then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\158\154\228\184\190\227\128\144%s\227\128\145Fields\229\191\133\233\161\187\230\152\175\230\149\176\231\187\132", EnumName)
      return false
    end
    if #EnumDefine.Fields <= 0 then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\158\154\228\184\190\227\128\144%s\227\128\145Fields\228\184\141\232\131\189\228\184\186\231\169\186", EnumName)
      return false
    end
  end
  if RTTIBase.IsValidTableValue(EnumDefine) and RTTIBase.IsValidStringValue(EnumDefine.Name) and EnumDefine.Name ~= EnumName then
    RTTIStatistics:RecordError(true, "\230\158\154\228\184\190\230\179\168\229\134\140\229\144\141(EnumName=%s)\228\184\142EnumDefine.Name(%s)\228\184\141\228\184\128\232\135\180", EnumName, EnumDefine.Name)
    return false
  end
  local EnumInfo = NormalizeEnum(EnumDefine)
  if not EnumInfo then
    RTTIStatistics:RecordError(true, "\230\158\154\228\184\190\227\128\144%s\227\128\145\230\160\135\229\135\134\229\140\150\229\164\177\232\180\165", EnumName)
    return false
  end
  self.EnumInfos[EnumName] = EnumInfo
  return true
end

function RTTICore:UnregisterEnum(EnumName)
  self.EnumInfos[EnumName] = nil
end

function RTTICore:GetEnumInfo(EnumName)
  local EnumInfo = self.EnumInfos[EnumName]
  if nil == EnumInfo then
    RTTIStatistics:RecordError(true, "\229\176\157\232\175\149\232\174\191\233\151\174\230\156\170\230\179\168\229\134\140\230\158\154\228\184\190: %s", EnumName)
    return nil
  end
  return EnumInfo
end

function RTTICore:HasEnum(EnumName)
  return self.EnumInfos[EnumName] ~= nil
end

function RTTICore:GetRegisteredEnums()
  local List = {}
  for Key in pairs(self.EnumInfos) do
    table.insert(List, Key)
  end
  return List
end

function RTTICore:RegisterType(TypeName, TypeDefine)
  local StrictMode = RTTISettings:Get("Core.StrictMode")
  if StrictMode then
    if not string.match(TypeName, "^[A-Z][a-zA-Z0-9_]*$") then
      RTTIStatistics:RecordError(false, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\231\177\187\229\158\139\229\144\141\227\128\144%s\227\128\145\229\191\133\233\161\187\231\172\166\229\144\136PascalCase\229\145\189\229\144\141\232\167\132\232\140\131", TypeName)
    end
    if self.TypeInfos[TypeName] then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\228\184\141\229\133\129\232\174\184\233\135\141\229\164\141\230\179\168\229\134\140\231\177\187\229\158\139: %s", TypeName)
      return false
    end
    if not RTTIBase.IsValidTableValue(TypeDefine) then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\231\177\187\229\158\139\227\128\144%s\227\128\145TypeDefine\229\191\133\233\161\187\230\152\175table", TypeName)
      return false
    end
    if not TypeDefine.Version or TypeDefine.Version <= 0 then
      RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\231\177\187\229\158\139\227\128\144%s\227\128\145\229\191\133\233\161\187\229\140\133\229\144\171\230\156\137\230\149\136\231\137\136\230\156\172\229\143\183", TypeName)
      return false
    end
  end
  if RTTIBase.IsValidTableValue(TypeDefine) and RTTIBase.IsValidStringValue(TypeDefine.Name) and TypeDefine.Name ~= TypeName then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\230\179\168\229\134\140\229\144\141(TypeName=%s)\228\184\142TypeDefine.Name(%s)\228\184\141\228\184\128\232\135\180", TypeName, TypeDefine.Name)
    return false
  end
  local TypeInfo = NormalizeType(TypeDefine)
  if not TypeInfo then
    RTTIStatistics:RecordError(true, "\231\177\187\229\158\139\227\128\144%s\227\128\145\230\160\135\229\135\134\229\140\150\229\164\177\232\180\165", TypeName)
    return false
  end
  if StrictMode and not ValidateTypeInfo(TypeInfo) then
    RTTIStatistics:RecordError(true, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\231\177\187\229\158\139\227\128\144%s\227\128\145\233\170\140\232\175\129\229\164\177\232\180\165", TypeName)
    return false
  end
  self.TypeInfos[TypeName] = TypeInfo
  return true
end

function RTTICore:UnregisterType(TypeName)
  self.TypeInfos[TypeName] = nil
end

function RTTICore:GetTypeInfo(TypeName)
  if RTTIBase.IsValidFieldType(TypeName) then
    return nil
  end
  local TypeInfo = self.TypeInfos[TypeName]
  if nil == TypeInfo then
    local TypeDefPath = "NewRoco.Modules.System.PGC.RTTI.Defines.Generates." .. TypeName
    package.loaded[TypeDefPath] = nil
    local Success = pcall(require, TypeDefPath)
    if Success then
      TypeInfo = self.TypeInfos[TypeName]
    end
    if nil == TypeInfo then
      RTTIStatistics:RecordError(true, "\229\176\157\232\175\149\232\174\191\233\151\174\230\156\170\230\179\168\229\134\140\231\177\187\229\158\139: %s", TypeName)
      return nil
    end
  end
  return TypeInfo
end

function RTTICore:HasType(TypeName)
  return self:GetTypeInfo(TypeName) ~= nil
end

function RTTICore:GetRegisteredTypes()
  local List = {}
  for Key in pairs(self.TypeInfos) do
    table.insert(List, Key)
  end
  return List
end

function RTTICore:GetFieldInfo(TypeName, FieldName)
  local TypeInfo = self.TypeInfos[TypeName]
  if not TypeInfo then
    return nil
  end
  return TypeInfo.FieldInfos[FieldName]
end

function RTTICore:GetEnumFieldValue(EnumName, FieldName)
  local EnumInfo = RTTICore:GetEnumInfo(EnumName)
  if EnumInfo then
    local FieldValue = EnumInfo.NameToValue[FieldName]
    if nil == FieldValue and #EnumInfo.FieldOrder > 0 then
      FieldName = EnumInfo.FieldOrder[1]
      FieldValue = EnumInfo.NameToValue[FieldName]
    end
    return FieldValue
  end
end

function RTTICore:GetEnumFieldName(EnumName, FieldValue)
  local EnumInfo = RTTICore:GetEnumInfo(EnumName)
  if EnumInfo then
    local FieldName = EnumInfo.ValueToName[FieldValue]
    if nil == FieldName and #EnumInfo.FieldOrder > 0 then
      FieldName = EnumInfo.FieldOrder[1]
    end
    return FieldName
  end
end

function RTTICore:GetPrimaryKeyName(TypeName)
  local TypeInfo = self.TypeInfos[TypeName]
  return TypeInfo and TypeInfo.PrimaryKeyName
end

function RTTICore:GetPrimaryKeyValue(TypeName, Data)
  local PrimaryKeyName = self:GetPrimaryKeyName(TypeName)
  if not PrimaryKeyName or "" == PrimaryKeyName then
    return nil, nil
  end
  return PrimaryKeyName, Data and Data[PrimaryKeyName]
end

function RTTICore:ResolveConditionKeyTarget(TypeName, FieldName, Data)
  if not RTTIBase.IsValidTableValue(Data) then
    return nil, nil
  end
  local FieldInfo = self:GetFieldInfo(TypeName, FieldName)
  if nil == FieldInfo or nil == Data then
    return nil, nil
  end
  local ConditionKey = FieldInfo.Constraint.ConditionKey
  if nil == ConditionKey then
    return nil, nil
  end
  local DriverField = ConditionKey.DriverField
  local TargetBranch
  local DriverValue = Data[DriverField]
  for _, Branch in ipairs(ConditionKey.Branches) do
    if nil ~= Branch and DriverValue == Branch.Value then
      TargetBranch = Branch
    end
  end
  if nil == TargetBranch then
    return nil, nil
  end
  return TargetBranch.TypeName, TargetBranch.FieldName
end

function RTTICore:ResolveSmartForeignKeyTarget(TypeName, FieldName, Data)
  local TypeInfo = self:GetTypeInfo(TypeName)
  if nil == TypeInfo then
    return nil, nil, nil
  end
  local DeclaredFieldInfo = TypeInfo.FieldInfos[FieldName]
  local Constraint = DeclaredFieldInfo and DeclaredFieldInfo.Constraint
  local Smart = Constraint and Constraint.SmartForeignKey
  if nil == Smart then
    return nil, nil, nil
  end
  local SmartList
  if type(Smart) == "table" and nil ~= Smart.EnumName then
    SmartList = {Smart}
  elseif type(Smart) == "table" then
    SmartList = Smart
  else
    return nil, nil, nil
  end
  
  local function EscapePattern(s)
    return (tostring(s):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
  end
  
  local function ParseByEnumDescription(Desc, LinkFieldName)
    if not RTTIBase.IsValidStringValue(Desc, true) or not RTTIBase.IsValidStringValue(LinkFieldName, true) then
      return nil, nil
    end
    local Key = EscapePattern(LinkFieldName)
    local Type1, Field1 = string.match(Desc, Key .. "%s*[:\239\188\154]%s*([%w_]+)%s*[,\239\188\140]%s*([%w_]+)")
    if RTTIBase.IsValidStringValue(Type1) and RTTIBase.IsValidStringValue(Field1) then
      return Type1, Field1
    end
    local Type2, Field2 = string.match(Desc, Key .. "%s*[=\239\188\157]%s*([%w_]+)%s*[,\239\188\140]%s*([%w_]+)")
    if RTTIBase.IsValidStringValue(Type2) and RTTIBase.IsValidStringValue(Field2) then
      return Type2, Field2
    end
    local Type3, Field3 = string.match(Desc, Key .. "%s*[=\239\188\157]%s*([%w_]+)%s*\231\154\132%s*([%w_]+)")
    if RTTIBase.IsValidStringValue(Type3) and RTTIBase.IsValidStringValue(Field3) then
      return Type3, Field3
    end
    local Type4 = string.match(Desc, Key .. "%s*[=\239\188\157]%s*([%w_]+)")
    if RTTIBase.IsValidStringValue(Type4) then
      return Type4, "id"
    end
    return nil, nil
  end
  
  local function ParseConditionalEnumName(EnumName)
    if not RTTIBase.IsValidStringValue(EnumName, true) then
      return nil, nil, nil
    end
    local CondField, CondToken, TargetType = string.match(EnumName, "^%s*([^=,]+)%s*=%s*([^,]+)%s*,%s*([^,]+)%s*$")
    if not (RTTIBase.IsValidStringValue(CondField, true) and RTTIBase.IsValidStringValue(CondToken, true)) or not RTTIBase.IsValidStringValue(TargetType, true) then
      return nil, nil, nil
    end
    return CondField, CondToken, TargetType
  end
  
  local function ResolveCondTokenValue(CondField, CondToken, ActualValue)
    if nil == CondToken then
      return CondToken
    end
    local n = tonumber(CondToken)
    if nil ~= n then
      return n
    end
    if type(ActualValue) == "number" then
      local CondFieldInfo = TypeInfo.FieldInfos and TypeInfo.FieldInfos[CondField]
      if nil ~= CondFieldInfo and CondFieldInfo.Type == RTTIBase.FieldType.ENUM then
        local EnumName = CondFieldInfo.Constraint and CondFieldInfo.Constraint.Enum and CondFieldInfo.Constraint.Enum.EnumName
        local EnumInfo = EnumName and self:GetEnumInfo(EnumName)
        local NameToValue = EnumInfo and EnumInfo.NameToValue
        local v = NameToValue and NameToValue[CondToken]
        if type(v) == "number" then
          return v
        end
      end
    end
    return CondToken
  end
  
  for _, Item in ipairs(SmartList) do
    local EnumName = Item and Item.EnumName
    local DriverField = Item and Item.DriverField
    local LinkFieldName = Item and Item.LinkFieldName
    if nil ~= Data and RTTIBase.IsValidStringValue(EnumName) and self:HasEnum(EnumName) and RTTIBase.IsValidStringValue(DriverField) and RTTIBase.IsValidStringValue(LinkFieldName) then
      local DriverValue = Data[DriverField]
      if type(DriverValue) == "number" then
        local EnumInfo = self:GetEnumInfo(EnumName)
        local EnumItemName = EnumInfo and EnumInfo.ValueToName and EnumInfo.ValueToName[DriverValue]
        local EnumFieldInfo = EnumItemName and EnumInfo and EnumInfo.FieldInfos and EnumInfo.FieldInfos[EnumItemName]
        local Desc = EnumFieldInfo and EnumFieldInfo.Description
        local TargetTypeName, TargetFieldName = ParseByEnumDescription(Desc, LinkFieldName)
        if type(TargetTypeName) == "string" and type(TargetFieldName) == "string" then
          local TargetFieldInfo = self:GetFieldInfo(TargetTypeName, TargetFieldName)
          if nil ~= TargetFieldInfo then
            return TargetTypeName, TargetFieldName, TargetFieldInfo
          end
        end
      end
    end
    if nil ~= Data and RTTIBase.IsValidStringValue(EnumName, true) and RTTIBase.IsValidStringValue(LinkFieldName, true) then
      local CondField, CondToken, TargetType = ParseConditionalEnumName(EnumName)
      if nil ~= CondField and nil ~= TargetType then
        local Actual = Data[CondField]
        local Expected = ResolveCondTokenValue(CondField, CondToken, Actual)
        if Actual == Expected then
          local TargetFieldInfo = self:GetFieldInfo(TargetType, LinkFieldName)
          if nil ~= TargetFieldInfo then
            return TargetType, LinkFieldName, TargetFieldInfo
          end
        end
      end
    end
    if RTTIBase.IsValidStringValue(EnumName) and RTTIBase.IsValidStringValue(LinkFieldName) and self:HasType(EnumName) then
      local TargetFieldInfo = self:GetFieldInfo(EnumName, LinkFieldName)
      if nil ~= TargetFieldInfo then
        return EnumName, LinkFieldName, TargetFieldInfo
      end
    end
  end
  return nil, nil, nil
end

function RTTICore:InferFieldType(TypeName, FieldName, Data)
  local FieldInfo = self:GetFieldInfo(TypeName, FieldName)
  if nil == FieldInfo then
    return nil
  end
  local TargetTypeName, TargetFieldName = self:ResolveConditionKeyTarget(TypeName, FieldName, Data)
  if nil == TargetTypeName and TargetFieldName then
    TargetTypeName, TargetFieldName = self:ResolveSmartForeignKeyTarget(TypeName, FieldName, Data)
  end
  local ForeignKey = FieldInfo.Constraint.ForeignKey
  if ForeignKey and nil == TargetTypeName and TargetFieldName then
    TargetTypeName, TargetFieldName = ForeignKey.TypeName, ForeignKey.FieldName
  end
  if TargetTypeName and TargetFieldName then
    local TargetFieldInfo = self:GetFieldInfo(TargetTypeName, TargetFieldName)
    if nil ~= TargetFieldInfo then
      return BuildInferredFieldInfo(FieldInfo, TargetFieldInfo)
    end
  end
  return FieldInfo
end

function RTTICore:TraverseTypeInfo(TypeName, Instance, FieldVisitor, Depth)
  if type(Instance) ~= "table" then
    return
  end
  if type(FieldVisitor) ~= "function" then
    return
  end
  local TypeInfo = self:GetTypeInfo(TypeName)
  if nil == TypeInfo then
    return
  end
  Depth = Depth or 0
  for _, FieldName in ipairs(TypeInfo.FieldOrder) do
    local FieldInfo = TypeInfo.FieldInfos[FieldName]
    local FieldType = FieldInfo and FieldInfo.Type
    local FieldValue = Instance[FieldName]
    if FieldType and FieldValue then
      FieldVisitor(TypeInfo, FieldInfo, FieldValue, Depth)
      if FieldType == RTTIBase.FieldType.STRUCT then
        local StructTypeName = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
        self:TraverseTypeInfo(StructTypeName, FieldValue, FieldVisitor, Depth + 1)
      elseif FieldType == RTTIBase.FieldType.ARRAY then
        for ElementIndex, ElementValue in ipairs(FieldValue) do
          local ElementType = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.ElementType
          if RTTIBase.IsPrimitiveType(ElementType) then
            local ArrayElementFieldInfo = self:BuildArrayElementFieldInfo(FieldInfo)
            FieldVisitor(TypeInfo, ArrayElementFieldInfo, ElementValue, Depth + 1)
          elseif ElementType == RTTIBase.FieldType.STRUCT then
            ElementType = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
            self:TraverseTypeInfo(ElementType, ElementValue, FieldVisitor, Depth + 1)
          end
        end
      end
    end
  end
end

return RTTICore

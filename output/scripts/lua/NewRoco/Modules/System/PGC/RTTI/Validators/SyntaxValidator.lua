local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local AbstractValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.AbstractValidator")
local SyntaxValidator = AbstractValidator:Extend("SyntaxValidator")

local function ValidateArraySize(self, FieldInfo, FieldValue)
  local ConstraintArray = FieldInfo.Constraint.Array
  if ConstraintArray then
    local ArraySize = #FieldValue
    local MaxSize = ConstraintArray.Size
    if MaxSize and ArraySize > MaxSize and self:PushFieldError(FieldInfo.Name, "\230\149\176\231\187\132\229\164\167\229\176\143%d\232\182\133\232\191\135\230\156\128\229\164\167\229\128\188%d", ArraySize, MaxSize) then
      return true
    end
  end
  return false
end

local function ValidateEnumValue(self, FieldInfo, FieldValue)
  local FieldName = FieldInfo.Name
  local EnumName = FieldInfo.Constraint.Enum and FieldInfo.Constraint.Enum.EnumName
  if not RTTIBase.IsValidStringValue(EnumName) then
    if self:PushFieldError(FieldName, "\230\158\154\228\184\190\229\173\151\230\174\181\231\188\186\229\176\145\230\158\154\228\184\190\231\186\166\230\157\159(EnumName)") then
      return true
    end
    return false
  end
  local EnumInfo = RTTICore:GetEnumInfo(EnumName)
  if nil == EnumInfo then
    if self:PushFieldError(FieldName, "\230\158\154\228\184\190\231\177\187\229\158\139\227\128\144%s\227\128\145\229\176\154\230\156\170\230\179\168\229\134\140", tostring(EnumName)) then
      return true
    end
    return false
  end
  if not RTTIBase.IsValidNumberValue(FieldValue, true) then
    if self:PushFieldError(FieldName, "\230\158\154\228\184\190\229\128\188\229\191\133\233\161\187\228\184\186\230\156\137\233\153\144\230\149\180\230\149\176number(\230\158\154\228\184\190\229\128\188)\239\188\140\229\174\158\233\153\133=%s(%s)", tostring(FieldValue), type(FieldValue)) then
      return true
    end
    return false
  end
  if (nil == EnumInfo.ValueToName or nil == EnumInfo.ValueToName[FieldValue]) and self:PushFieldError(FieldName, "\230\158\154\228\184\190\229\128\188\227\128\144%s\227\128\145\233\157\158\230\179\149\239\188\136%s\239\188\137\239\188\129", tostring(FieldValue), tostring(EnumName)) then
    return false
  end
  return false
end

local function ValidateFieldRequired(self, FieldInfo, FieldValue)
  if FieldInfo.Constraint.Required and nil == FieldValue and self:PushFieldError(FieldInfo.Name, "\229\191\133\229\161\171\229\173\151\230\174\181\228\184\141\232\131\189\228\184\186\231\169\186") then
    return true
  end
  return false
end

local function ValidateNotEmpty(self, FieldInfo, FieldValue, EffectiveFieldType)
  if nil == FieldValue then
    return false
  end
  if not FieldInfo.Constraint.NotEmpty then
    return false
  end
  local FieldType = EffectiveFieldType or FieldInfo.Type
  if FieldType == RTTIBase.FieldType.STRING then
    if "" == FieldValue and self:PushFieldError(FieldInfo.Name, "\229\173\151\230\174\181\228\184\141\232\131\189\228\184\186\231\169\186(not_empty)") then
      return true
    end
  elseif FieldType == RTTIBase.FieldType.ARRAY and RTTIBase.IsValidTableValue(FieldValue) and 0 == #FieldValue and self:PushFieldError(FieldInfo.Name, "\230\149\176\231\187\132\228\184\141\232\131\189\228\184\186\231\169\186(not_empty)") then
    return true
  end
  return false
end

local function IsValueAllowedByLimit(Value, Limit)
  if not RTTIBase.IsValidNumberValue(Value) or not RTTIBase.IsValidTableValue(Limit) then
    return true
  end
  local Values = Limit.Values
  if RTTIBase.IsValidTableValue(Values) then
    for _, v in ipairs(Values) do
      if RTTIBase.IsValidNumberValue(v) and v == Value then
        return true
      end
    end
  end
  local Ranges = Limit.Ranges
  if RTTIBase.IsValidTableValue(Ranges) then
    for _, r in ipairs(Ranges) do
      if RTTIBase.IsValidTableValue(r) then
        local Min = r.Min
        local Max = r.Max
        local MinOk = not RTTIBase.IsValidNumberValue(Min) or Value >= Min
        local MaxOk = not RTTIBase.IsValidNumberValue(Max) or Value <= Max
        if MinOk and MaxOk then
          return true
        end
      end
    end
  end
  if not RTTIBase.IsValidTableValue(Values) and not RTTIBase.IsValidTableValue(Ranges) then
    return true
  end
  return false
end

local function ValidateStringSizeLimit(self, FieldInfo, FieldValue, EffectiveFieldType)
  local Limit = FieldInfo.Constraint.SizeLimit
  if not Limit or nil == FieldValue then
    return false
  end
  local FieldType = EffectiveFieldType or FieldInfo.Type
  if FieldType ~= RTTIBase.FieldType.STRING or not RTTIBase.IsValidStringValue(FieldValue, true) then
    return false
  end
  local Size = string.len(FieldValue)
  if not IsValueAllowedByLimit(Size, Limit) and self:PushFieldError(FieldInfo.Name, "\229\173\151\231\172\166\228\184\178\233\149\191\229\186\166%d\228\184\141\230\187\161\232\182\179sz\231\186\166\230\157\159", Size) then
    return true
  end
  return false
end

local function ValidateArrayLengthLimit(self, FieldInfo, FieldValue, EffectiveFieldType)
  local Limit = FieldInfo.Constraint.LengthLimit
  if not Limit or nil == FieldValue then
    return false
  end
  local FieldType = EffectiveFieldType or FieldInfo.Type
  if FieldType ~= RTTIBase.FieldType.ARRAY or not RTTIBase.IsValidTableValue(FieldValue) then
    return false
  end
  local Len = #FieldValue
  if not IsValueAllowedByLimit(Len, Limit) and self:PushFieldError(FieldInfo.Name, "\230\149\176\231\187\132\233\149\191\229\186\166%d\228\184\141\230\187\161\232\182\179len\231\186\166\230\157\159", Len) then
    return true
  end
  return false
end

local function ValidateNumberValueLimit(self, FieldInfo, FieldValue, EffectiveFieldType)
  local Limit = FieldInfo.Constraint.ValueLimit
  if not Limit or nil == FieldValue then
    return false
  end
  local FieldType = EffectiveFieldType or FieldInfo.Type
  if RTTIBase.IsNumberType(FieldType) then
    if not RTTIBase.IsValidNumberValue(FieldValue) then
      return false
    end
    if not IsValueAllowedByLimit(FieldValue, Limit) and self:PushFieldError(FieldInfo.Name, "\230\149\176\229\128\188%s\228\184\141\230\187\161\232\182\179vl\231\186\166\230\157\159", tostring(FieldValue)) then
      return true
    end
    return false
  end
  if FieldType == RTTIBase.FieldType.ARRAY and RTTIBase.IsValidTableValue(FieldValue) then
    local ElementType = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.ElementType
    if RTTIBase.IsNumberType(ElementType) then
      for Index, Value in ipairs(FieldValue) do
        if RTTIBase.IsValidNumberValue(Value) and not IsValueAllowedByLimit(Value, Limit) and self:PushFieldError(FieldInfo.Name, "\230\149\176\231\187\132\229\133\131\231\180\160[%d]=%s\228\184\141\230\187\161\232\182\179vl\231\186\166\230\157\159", Index, tostring(Value)) then
          return true
        end
      end
    end
  end
  return false
end

local function ValidateFieldType(self, TypeInfo, FieldInfo, Data)
  local FieldName = FieldInfo.Name
  local FieldValue = Data[FieldName]
  if nil == FieldValue then
    return false
  end
  local DeclaredFieldType = FieldInfo.Type
  local ValueType = type(FieldValue)
  if nil == DeclaredFieldType or not RTTIBase.IsValidFieldType(DeclaredFieldType) then
    return false
  end
  local EffectiveFieldInfo = FieldInfo
  if Data then
    local Inferred = RTTICore:InferFieldType(TypeInfo.Name, FieldName, Data)
    if Inferred then
      EffectiveFieldInfo = Inferred
    end
  end
  local EffectiveFieldType = EffectiveFieldInfo.Type
  local IsDerivedType = EffectiveFieldInfo ~= FieldInfo
  if ValidateNotEmpty(self, FieldInfo, FieldValue, EffectiveFieldType) then
    return true
  end
  if ValidateStringSizeLimit(self, FieldInfo, FieldValue, EffectiveFieldType) then
    return true
  end
  if ValidateArrayLengthLimit(self, FieldInfo, FieldValue, EffectiveFieldType) then
    return true
  end
  local LimitFieldInfo = FieldInfo
  if IsDerivedType then
    if RTTIBase.IsNumberType(EffectiveFieldType) then
      LimitFieldInfo = EffectiveFieldInfo
    elseif EffectiveFieldType == RTTIBase.FieldType.ARRAY then
      local ElementType = EffectiveFieldInfo.Constraint and EffectiveFieldInfo.Constraint.Array and EffectiveFieldInfo.Constraint.Array.ElementType
      if RTTIBase.IsNumberType(ElementType) then
        LimitFieldInfo = EffectiveFieldInfo
      end
    end
  end
  if ValidateNumberValueLimit(self, LimitFieldInfo, FieldValue, EffectiveFieldType) then
    return true
  end
  local Additional = IsDerivedType and "(\230\157\161\228\187\182\230\142\168\229\175\188)" or "(\228\191\157\230\140\129\229\142\159\229\167\139)"
  if EffectiveFieldType == RTTIBase.FieldType.STRING then
    if not RTTIBase.IsValidStringValue(FieldValue, true) and self:PushFieldError(FieldName, "\229\173\151\230\174\181\231\177\187\229\158\139%s\229\186\148\228\184\186\229\173\151\231\172\166\228\184\178\239\188\140\229\174\158\233\153\133=%s(%s)", Additional, tostring(FieldValue), ValueType) then
      return true
    end
  elseif RTTIBase.IsIntegerType(EffectiveFieldType) then
    if not RTTIBase.IsValidNumberValue(FieldValue, true) and self:PushFieldError(FieldName, "\229\173\151\230\174\181\231\177\187\229\158\139%s\229\186\148\228\184\186\230\149\180\230\149\176\239\188\140\229\174\158\233\153\133=%s(%s)", Additional, tostring(FieldValue), ValueType) then
      return true
    end
  elseif RTTIBase.IsFloatType(EffectiveFieldType) then
    if not RTTIBase.IsValidNumberValue(FieldValue) and self:PushFieldError(FieldName, "\229\173\151\230\174\181\231\177\187\229\158\139%s\229\186\148\228\184\186\230\149\176\229\173\151\239\188\140\229\174\158\233\153\133=%s(%s)", Additional, tostring(FieldValue), ValueType) then
      return true
    end
  elseif EffectiveFieldType == RTTIBase.FieldType.BOOL then
    if "boolean" ~= ValueType and self:PushFieldError(FieldName, "\229\173\151\230\174\181\231\177\187\229\158\139%s\229\186\148\228\184\186\229\184\131\229\176\148\229\128\188\239\188\140\229\174\158\233\153\133=%s(%s)", Additional, tostring(FieldValue), ValueType) then
      return true
    end
  elseif EffectiveFieldType == RTTIBase.FieldType.ARRAY then
    if RTTIBase.IsValidTableValue(FieldValue) then
      if DeclaredFieldType == RTTIBase.FieldType.ARRAY then
        if ValidateArraySize(self, FieldInfo, FieldValue) then
          return true
        end
        local ConstraintArray = FieldInfo.Constraint.Array
        local EnumName = FieldInfo.Constraint.Enum and FieldInfo.Constraint.Enum.EnumName
        if ConstraintArray and ConstraintArray.ElementType == RTTIBase.FieldType.ENUM and RTTIBase.IsValidStringValue(EnumName) then
          local EnumInfo = RTTICore:GetEnumInfo(EnumName)
          if nil == EnumInfo then
            if self:PushFieldError(FieldName, "\230\158\154\228\184\190\231\177\187\229\158\139\227\128\144%s\227\128\145\229\176\154\230\156\170\230\179\168\229\134\140", tostring(EnumName)) then
              return true
            end
          else
            local ValueToName = EnumInfo.ValueToName
            for Index, EnumValue in ipairs(FieldValue) do
              if not RTTIBase.IsValidNumberValue(EnumValue, true) then
                if self:PushFieldError(FieldName, "\230\149\176\231\187\132\229\133\131\231\180\160[%d]\230\158\154\228\184\190\229\128\188\229\191\133\233\161\187\228\184\186\230\156\137\233\153\144\230\149\180\230\149\176number(\230\158\154\228\184\190\229\128\188)\239\188\140\229\174\158\233\153\133=%s(%s)", Index, tostring(EnumValue), type(EnumValue)) then
                  return true
                end
              elseif (nil == ValueToName or nil == ValueToName[EnumValue]) and self:PushFieldError(FieldName, "\230\149\176\231\187\132\229\133\131\231\180\160[%d]\230\158\154\228\184\190\229\128\188\233\157\158\230\179\149\239\188\154%s\239\188\136%s\239\188\137", Index, tostring(EnumValue), tostring(EnumName)) then
                return true
              end
            end
          end
        end
      end
    elseif self:PushFieldError(FieldName, "\229\173\151\230\174\181\231\177\187\229\158\139%s\229\186\148\228\184\186\233\157\158\231\169\186\230\149\176\231\187\132\239\188\140\229\174\158\233\153\133=%s(%s)", Additional, tostring(FieldValue), ValueType) then
      return true
    end
  elseif EffectiveFieldType == RTTIBase.FieldType.STRUCT then
    if not RTTIBase.IsValidTableValue(FieldValue) and self:PushFieldError(FieldName, "\229\173\151\230\174\181\231\177\187\229\158\139%s\229\186\148\228\184\186\231\187\147\230\158\132\230\149\176\230\141\174\239\188\140\229\174\158\233\153\133=%s(%s)", Additional, tostring(FieldValue), ValueType) then
      return true
    end
  elseif EffectiveFieldType == RTTIBase.FieldType.ENUM and "nil" ~= ValueType then
    local EnumFieldInfo = IsDerivedType and EffectiveFieldInfo or FieldInfo
    if ValidateEnumValue(self, EnumFieldInfo, FieldValue) then
      return true
    end
  end
  return false
end

local function ValidateStrict(self, TypeInfo, FieldInfo, Data)
  local FieldName = FieldInfo.Name
  local FieldValue = Data[FieldName]
  if nil == FieldValue or not self:IsStrictMode() then
    return false
  end
  local DeclaredFieldType = FieldInfo.Type
  if nil == DeclaredFieldType or not RTTIBase.IsValidFieldType(DeclaredFieldType) then
    return false
  end
  local EffectiveFieldType = DeclaredFieldType
  if Data then
    local Inferred = RTTICore:InferFieldType(TypeInfo.Name, FieldName, Data)
    local InferredType = Inferred and Inferred.Type
    if InferredType and RTTIBase.IsValidFieldType(InferredType) then
      EffectiveFieldType = InferredType
    end
  end
  if EffectiveFieldType == RTTIBase.FieldType.STRING and RTTIBase.IsValidStringValue(FieldValue, true) and string.match(FieldValue, "[\000-\031\127]") and self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\229\140\133\229\144\171\230\142\167\229\136\182\229\173\151\231\172\166") then
    return true
  end
  if RTTIBase.IsNumberType(EffectiveFieldType) then
    if not RTTIBase.IsValidNumberValue(FieldValue) and self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\149\176\229\128\188\229\191\133\233\161\187\230\152\175\230\156\137\233\153\144\230\149\176") then
      return true
    end
    if RTTIBase.IsIntegerType(EffectiveFieldType) and not RTTIBase.IsValidNumberValue(FieldValue, true) and self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\149\180\230\149\176\229\173\151\230\174\181\228\184\141\232\131\189\229\140\133\229\144\171\229\176\143\230\149\176\233\131\168\229\136\134") then
      return true
    end
  end
  if EffectiveFieldType == RTTIBase.FieldType.ARRAY then
    local MaxIndex = 0
    local IndexCount = 0
    if RTTIBase.IsValidTableValue(FieldValue) then
      for Index, _ in pairs(FieldValue) do
        if RTTIBase.IsValidNumberValue(Index, true) and Index > 0 then
          MaxIndex = math.max(MaxIndex, Index)
          IndexCount = IndexCount + 1
        else
          if self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\149\176\231\187\132\231\180\162\229\188\149\229\191\133\233\161\187\230\152\175\230\173\163\230\149\180\230\149\176") then
            return true
          end
          break
        end
      end
      if IndexCount > 0 and IndexCount ~= MaxIndex and self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\149\176\231\187\132\231\180\162\229\188\149\229\191\133\233\161\187\232\191\158\231\187\173") then
        return true
      end
    elseif self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\149\176\231\187\132\229\138\161\229\191\133\229\136\157\229\167\139\229\140\150") then
      return true
    end
  end
  return false
end

local function ValidateDefinedField(self, TypeInfo, Data)
  for FieldName, _ in pairs(Data) do
    if RTTIBase.FilterFieldName(FieldName) and not TypeInfo.FieldInfos[FieldName] and self:PushFieldError(FieldName, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\228\184\141\229\133\129\232\174\184\230\156\170\229\174\154\228\185\137\229\173\151\230\174\181") then
      return true
    end
  end
  return false
end

function SyntaxValidator:OnReset()
end

function SyntaxValidator:OnExecute(TypeInfo, Data)
  if self:IsStrictMode() and ValidateDefinedField(self, TypeInfo, Data) then
    return
  end
  for FieldName, FieldInfo in pairs(TypeInfo.FieldInfos) do
    local FieldValue = Data[FieldName]
    if ValidateFieldRequired(self, FieldInfo, FieldValue) then
      return
    end
    if ValidateFieldType(self, TypeInfo, FieldInfo, Data) then
      return
    end
    if ValidateStrict(self, TypeInfo, FieldInfo, Data) then
      return
    end
  end
end

return SyntaxValidator

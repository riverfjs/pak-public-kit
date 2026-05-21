local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
local AbstractValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.AbstractValidator")
local ReferenceValidator = AbstractValidator:Extend("ReferenceValidator")

local function ValidateCircular(self, FieldInfo, Object)
  local ObjectId = tostring(Object)
  if self.VisitedObjects[ObjectId] then
    local FieldName = type(FieldInfo) == "table" and FieldInfo.Name or "<Root>"
    if self:PushFieldError(FieldName, "\230\163\128\230\181\139\229\136\176\229\190\170\231\142\175\229\188\149\231\148\168") then
      return true
    end
  end
  self.VisitedObjects[ObjectId] = true
  return false
end

local function ValidatePrimaryKey(self, FieldInfo, FieldValue)
  local FieldConstraint = FieldInfo.Constraint
  if FieldConstraint.PrimaryKey and (nil == FieldValue or "" == FieldValue) and self:PushFieldError(FieldInfo.Name, "\228\184\187\233\148\174\229\173\151\230\174\181\228\184\141\232\131\189\228\184\186\231\169\186") then
    return true
  end
  return false
end

local function ValidateRecordExist(self, ForeignTypeName, ForeignFieldName, FieldName, FieldValue)
  local ForeignFieldInfo = RTTICore:GetFieldInfo(ForeignTypeName, ForeignFieldName)
  if ForeignFieldInfo then
    local ForeignRecord
    if ForeignFieldInfo.Constraint.PrimaryKey then
      ForeignRecord = RTTIDataProvider:QueryByPrimaryKey(ForeignTypeName, FieldValue)
    else
      ForeignRecord = RTTIDataProvider:QueryByFieldName(ForeignTypeName, true, ForeignFieldName, FieldValue)
    end
    if not ForeignRecord and self:PushFieldError(FieldName, "\229\164\150\233\148\174\227\128\144%s.%s=%s\227\128\145\230\149\176\230\141\174\228\184\141\229\173\152\229\156\168", ForeignTypeName, ForeignFieldName, tostring(FieldValue)) then
      return true
    end
  end
  return false
end

local ValidateForeignKey = function(self, FieldInfo, FieldValue)
  local FieldConstraint = FieldInfo.Constraint
  if FieldConstraint.ForeignKey then
    local ForeignTypeName = FieldConstraint.ForeignKey.TypeName
    local ForeignFieldName = FieldConstraint.ForeignKey.FieldName
    if FieldInfo.Type == RTTIBase.FieldType.ARRAY then
      if not RTTIBase.IsValidTableValue(FieldValue) then
        return false
      end
      local ElementFieldInfo = RTTICore:BuildArrayElementFieldInfo(FieldInfo)
      if nil == ElementFieldInfo then
        return false
      end
      for _, ElementValue in ipairs(FieldValue) do
        if ValidateForeignKey(self, ElementFieldInfo, ElementValue) then
          return true
        end
      end
    elseif ValidateRecordExist(self, ForeignTypeName, ForeignFieldName, FieldInfo.Name, FieldValue) then
      return true
    end
  end
  return false
end

local function ValidateSmartForeignKey(self, TypeInfo, FieldInfo, Data)
  local FieldName = FieldInfo.Name
  local FieldValue = Data[FieldName]
  local FieldConstraint = FieldInfo.Constraint
  if FieldConstraint and FieldConstraint.SmartForeignKey then
    if not (nil ~= TypeInfo and RTTIBase.IsValidStringValue(TypeInfo.Name) and RTTIBase.IsValidStringValue(FieldName)) or nil == Data then
      return false
    end
    local TargetTypeName, TargetFieldName = RTTICore:ResolveSmartForeignKeyTarget(TypeInfo.Name, FieldName, Data)
    if type(TargetTypeName) ~= "string" or type(TargetFieldName) ~= "string" then
      return false
    end
    if FieldInfo.Type == RTTIBase.FieldType.ARRAY then
      if RTTIBase.IsValidTableValue(FieldValue) then
        for _, ElementValue in ipairs(FieldValue) do
          if ValidateRecordExist(self, TargetTypeName, TargetFieldName, FieldInfo.Name, ElementValue) then
            return true
          end
        end
      elseif self:PushFieldError(FieldInfo.Name, "\229\173\151\230\174\181\231\177\187\229\158\139(SmartForeignKey)\229\186\148\228\184\186\230\149\176\231\187\132\239\188\140\229\174\158\233\153\133=%s(%s)", tostring(FieldValue), type(FieldValue)) then
        return true
      end
    elseif ValidateRecordExist(self, TargetTypeName, TargetFieldName, FieldInfo.Name, FieldValue) then
      return true
    end
  end
  return false
end

local function ValidateConditionKey(self, TypeInfo, FieldInfo, Data)
  local FieldName = FieldInfo.Name
  local FieldValue = Data[FieldName]
  local FieldConstraint = FieldInfo.Constraint
  if FieldConstraint.ConditionKey then
    if not (nil ~= TypeInfo and RTTIBase.IsValidStringValue(TypeInfo.Name) and RTTIBase.IsValidStringValue(FieldName)) or nil == Data then
      return false
    end
    local TargetTypeName, TargetFieldName = RTTICore:ResolveConditionKeyTarget(TypeInfo.Name, FieldName, Data)
    if type(TargetTypeName) ~= "string" or type(TargetFieldName) ~= "string" then
      return false
    end
    if FieldInfo.Type == RTTIBase.FieldType.ARRAY then
      if RTTIBase.IsValidTableValue(FieldValue) then
        for _, ElementValue in ipairs(FieldValue) do
          if ValidateRecordExist(self, TargetTypeName, TargetFieldName, FieldInfo.Name, ElementValue) then
            return true
          end
        end
      elseif self:PushFieldError(FieldInfo.Name, "\229\173\151\230\174\181\231\177\187\229\158\139(ConditionKey)\229\186\148\228\184\186\230\149\176\231\187\132\239\188\140\229\174\158\233\153\133=%s(%s)", tostring(FieldValue), type(FieldValue)) then
        return true
      end
    elseif ValidateRecordExist(self, TargetTypeName, TargetFieldName, FieldInfo.Name, FieldValue) then
      return true
    end
  end
  return false
end

local function ValidateStrict(self, FieldInfo, FieldValue)
  if not FieldValue or not self:IsStrictMode() then
    return false
  end
  if FieldInfo.Type == RTTIBase.FieldType.ARRAY then
    if FieldValue then
      for _, ElementValue in ipairs(FieldValue) do
        if RTTIBase.IsValidTableValue(ElementValue) and ValidateCircular(self, FieldInfo, ElementValue) then
          return true
        end
      end
    elseif self:PushFieldError(FieldInfo.Name, "\228\184\165\230\160\188\230\168\161\229\188\143\228\184\139\230\149\176\231\187\132\229\138\161\229\191\133\229\136\157\229\167\139\229\140\150") then
      return true
    end
  end
  return false
end

function ReferenceValidator:OnReset()
end

function ReferenceValidator:OnExecute(TypeInfo, Data)
  if self:IsStrictMode() then
    self.VisitedObjects = {}
    ValidateCircular(self, nil, Data)
  end
  for FieldName, FieldInfo in pairs(TypeInfo.FieldInfos) do
    local FieldValue = Data[FieldName]
    if ValidatePrimaryKey(self, FieldInfo, FieldValue) then
      return
    end
    if ValidateForeignKey(self, FieldInfo, FieldValue) then
      return
    end
    if ValidateSmartForeignKey(self, TypeInfo, FieldInfo, Data) then
      return
    end
    if ValidateConditionKey(self, TypeInfo, FieldInfo, Data) then
      return
    end
    if ValidateStrict(self, FieldInfo, FieldValue) then
      return
    end
  end
end

return ReferenceValidator

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local AbstractValidator = require("NewRoco.Modules.System.PGC.RTTI.Validators.AbstractValidator")
local SemanticValidator = AbstractValidator:Extend("SemanticValidator")

local function ValidateBusinessRules(self, TypeInfo, Data)
  local TypeName = TypeInfo.Name
  for _, Rule in pairs(self.BusinessRules) do
    local ApplicableTypeNames = Rule.ApplicableTypeNames
    if not ApplicableTypeNames or ApplicableTypeNames[TypeName] then
      local Success, Message = Rule.Callback(TypeInfo, Data)
      if not Success and self:PushTypeError(TypeName, Message) then
        return true
      end
    end
  end
  return false
end

local function ValidateCustomRules(self, TypeInfo, Data)
  for FieldName, FieldInfo in pairs(TypeInfo.FieldInfos) do
    local ConstraintCustom = FieldInfo.Constraint.Custom
    if ConstraintCustom then
      local FieldValue = Data[FieldName]
      local CustomRuleName = ConstraintCustom.RuleName
      local CustomRule = self.CustomRules[CustomRuleName]
      if CustomRule then
        local Success, Message = CustomRule(FieldInfo, FieldValue)
        if not Success and self:PushFieldError(FieldInfo.Name, Message) then
          return true
        end
      end
    end
  end
  return false
end

function SemanticValidator:RegisterBusinessRule(RuleName, Callback, ApplicableTypeNames)
  if not RTTIBase.IsValidStringValue(RuleName) or type(Callback) ~= "function" then
    RTTIStatistics:RecordError(true, "\230\179\168\229\134\140\228\184\154\229\138\161\232\167\132\229\136\153\230\151\182RuleName\229\191\133\233\161\187\230\152\175\229\173\151\231\172\166\228\184\178\239\188\140Callback\229\191\133\233\161\187\230\152\175\229\135\189\230\149\176")
    return false
  end
  if self.BusinessRules[RuleName] then
    RTTIStatistics:RecordError(false, "\228\184\154\229\138\161\232\167\132\229\136\153\227\128\144%s\227\128\145\229\183\178\231\187\143\229\173\152\229\156\168\239\188\140\229\176\134\228\188\154\232\162\171\232\166\134\231\155\150\239\188\129", RuleName)
  end
  local TypeNameMap
  if ApplicableTypeNames then
    TypeNameMap = {}
    local TypeCount = 0
    for _, ApplicableType in pairs(ApplicableTypeNames) do
      TypeNameMap[ApplicableType] = true
      TypeCount = TypeCount + 1
    end
    if 0 == TypeCount then
      TypeNameMap = nil
    end
  end
  self.BusinessRules[RuleName] = {Callback = Callback, ApplicableTypeNames = TypeNameMap}
  return true
end

function SemanticValidator:RegisterCustomRule(RuleName, Callback)
  if not RTTIBase.IsValidStringValue(RuleName) or type(Callback) ~= "function" then
    RTTIStatistics:RecordError(true, "\230\179\168\229\134\140\232\135\170\229\174\154\228\185\137\232\167\132\229\136\153RuleName\229\191\133\233\161\187\230\152\175\229\173\151\231\172\166\228\184\178\239\188\140Callback\229\191\133\233\161\187\230\152\175\229\135\189\230\149\176")
    return false
  end
  if self.CustomRules[RuleName] then
    RTTIStatistics:RecordError(false, "\232\135\170\229\174\154\228\185\137\232\167\132\229\136\153\227\128\144%s\227\128\145\229\183\178\231\187\143\229\173\152\229\156\168\239\188\140\229\176\134\228\188\154\232\162\171\232\166\134\231\155\150\239\188\129", RuleName)
  end
  if RTTISettings:Get("Validation.EnableCustomRules") == false then
    RTTIStatistics:RecordError(true, "\232\135\170\229\174\154\228\185\137\232\167\132\229\136\153\229\138\159\232\131\189\229\183\178\231\166\129\231\148\168")
    return false
  end
  self.CustomRules[RuleName] = Callback
  return true
end

function SemanticValidator:OnReset()
  self.BusinessRules = {}
  self.CustomRules = {}
end

function SemanticValidator:OnExecute(TypeInfo, Data)
  if ValidateBusinessRules(self, TypeInfo, Data) then
    return
  end
  if ValidateCustomRules(self, TypeInfo, Data) then
    return
  end
end

return SemanticValidator

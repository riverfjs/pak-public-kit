local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ConfTypeCreateAndValidateTestCase = AbstractTestCase:Extend("ConfTypeCreateAndValidateTestCase")

function ConfTypeCreateAndValidateTestCase:Ctor()
  self.Name = "CONF \231\177\187\229\158\139\239\188\154\229\136\155\229\187\186(CreateInstance) + \230\160\161\233\170\140(ValidateRecord)\239\188\136\229\133\168\233\135\143\239\188\137"
  self.Description = "\229\175\185 AREA/DIALOGUE/MODEL/NPC/NPC_OPTION/NPC_REFRESH_CONTENT \229\133\168\233\131\168\232\183\145\228\184\128\233\129\141\229\136\155\229\187\186+\230\160\161\233\170\140"
end

local function LoadType(TestCase, TypeName)
  local Loaded = false
  local TypeDefPath = "NewRoco.Modules.System.PGC.RTTI.Defines.Generates." .. TypeName
  package.loaded[TypeDefPath] = nil
  local Success = pcall(require, TypeDefPath)
  if not Success then
    TestCase:AssertTrue(false, string.format("%s \231\177\187\229\158\139\229\174\154\228\185\137\229\138\160\232\189\189\229\164\177\232\180\165", TypeName))
    return false
  end
  local ConfigTableId = DataConfigManager.ConfigTableId[TypeName]
  if ConfigTableId then
    local Config = DataConfigManager:GetTable(ConfigTableId)
    if Config then
      RTTIManager:RegisterConfig(TypeName, Config)
    end
  end
  return true
end

local function TryGetIdMinValueLimit(ConfTypeName)
  local TypeInfo = RTTIManager:GetTypeInfo(ConfTypeName)
  if type(TypeInfo) ~= "table" then
    return nil
  end
  local FieldInfos = TypeInfo.FieldInfos
  if type(FieldInfos) ~= "table" then
    return nil
  end
  local IdFieldInfo = FieldInfos.id
  if type(IdFieldInfo) ~= "table" then
    return nil
  end
  local ValueLimit = IdFieldInfo.Constraint and IdFieldInfo.Constraint.ValueLimit
  if type(ValueLimit) ~= "table" then
    return nil
  end
  local Candidate
  local Ranges = ValueLimit.Ranges
  if type(Ranges) == "table" then
    for _, r in ipairs(Ranges) do
      if type(r) == "table" then
        local Min = r.Min
        local Max = r.Max
        local Pick
        if type(Min) == "number" then
          Pick = Min
        elseif type(Max) == "number" then
          Pick = Max
        end
        if type(Pick) == "number" and (nil == Candidate or Candidate > Pick) then
          Candidate = Pick
        end
      end
    end
  end
  local Values = ValueLimit.Values
  if type(Values) == "table" then
    for _, v in ipairs(Values) do
      if type(v) == "number" and (nil == Candidate or v < Candidate) then
        Candidate = v
      end
    end
  end
  if type(Candidate) == "number" then
    return Candidate
  end
  return nil
end

function ConfTypeCreateAndValidateTestCase:RunSingleConfType(ConfTypeName)
  self:AssertTrue(RTTIManager:HasType(ConfTypeName) == true, string.format("%s \229\186\148\229\183\178\230\179\168\229\134\140", ConfTypeName))
  local Instance = RTTIManager:CreateInstance(ConfTypeName)
  self:AssertType(Instance, "table", string.format("%s CreateInstance \229\186\148\232\191\148\229\155\158 table", ConfTypeName))
  local TypeInfo = RTTIManager:GetTypeInfo(ConfTypeName)
  local IdFieldInfo = TypeInfo and TypeInfo.FieldInfos and TypeInfo.FieldInfos.id
  local IsIdPrimaryKey = IdFieldInfo and IdFieldInfo.Constraint and IdFieldInfo.Constraint.PrimaryKey
  local MinValue = TryGetIdMinValueLimit(ConfTypeName)
  if IsIdPrimaryKey and RTTIBase.IsValidNumberValue(Instance.id) then
    self:AssertTrue(Instance.id ~= nil, string.format("%s CreateInstance \229\186\148\231\148\159\230\136\144\233\157\158\231\169\186\228\184\187\233\148\174 id", ConfTypeName))
  elseif nil ~= MinValue then
    self:AssertEquals(MinValue, Instance.id, string.format("%s CreateInstance \229\186\148\230\138\138 id \231\188\186\231\156\129\229\128\188\232\174\190\231\189\174\228\184\186 ValueLimit.Min=%s", ConfTypeName, tostring(MinValue)))
  end
  local OkResult = RTTIManager:ValidateRecord(ConfTypeName, Instance)
  self:AssertType(OkResult, "table", string.format("%s ValidateRecord \231\187\147\230\158\156\229\186\148\228\184\186 table", ConfTypeName))
  self:AssertTrue(true == OkResult.Success, string.format("%s \230\150\176\229\136\155\229\187\186\229\174\158\228\190\139\229\186\148\233\128\154\232\191\135\230\160\161\233\170\140", ConfTypeName))
  local BadInstance = RTTIBase.DeepCopy(Instance)
  BadInstance.ExtraField = 1
  local BadResult = RTTIManager:ValidateRecord(ConfTypeName, BadInstance)
  self:AssertType(BadResult, "table", string.format("%s \229\164\177\232\180\165\231\187\147\230\158\156\229\186\148\228\184\186 table", ConfTypeName))
  self:AssertFalse(true == BadResult.Success, string.format("%s \229\173\152\229\156\168\230\156\170\229\174\154\228\185\137\229\173\151\230\174\181\229\186\148\230\160\161\233\170\140\229\164\177\232\180\165", ConfTypeName))
  self:AssertTrue("table" == type(BadResult.Errors) and #BadResult.Errors >= 1, string.format("%s \229\164\177\232\180\165\231\187\147\230\158\156\229\186\148\232\135\179\229\176\145\229\140\133\229\144\1711\230\157\161\233\148\153\232\175\175", ConfTypeName))
end

function ConfTypeCreateAndValidateTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Validation = {StopOnFirstError = true}
  })
  LoadType(self, "EnumDefine")
  LoadType(self, "TypeDefine")
  local TypeFiles = {
    "AREA_CONF",
    "DIALOGUE_CONF",
    "MODEL_CONF",
    "NPC_CONF",
    "NPC_OPTION_CONF",
    "NPC_REFRESH_CONTENT_CONF"
  }
  for _, TypeName in ipairs(TypeFiles) do
    LoadType(self, TypeName)
  end
  for _, TypeName in ipairs(TypeFiles) do
    self:RunSingleConfType(TypeName)
  end
end

return ConfTypeCreateAndValidateTestCase

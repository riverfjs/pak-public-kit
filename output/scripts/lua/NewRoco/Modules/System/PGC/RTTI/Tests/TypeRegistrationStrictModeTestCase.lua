local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local TypeRegistrationStrictModeTestCase = AbstractTestCase:Extend("TypeRegistrationStrictModeTestCase")

function TypeRegistrationStrictModeTestCase:Ctor()
  self.Name = "\231\177\187\229\158\139\230\179\168\229\134\140\228\184\165\230\160\188\230\160\161\233\170\140"
  self.Description = "\232\166\134\231\155\150 RegisterType \228\184\165\230\160\188\230\168\161\229\188\143\229\164\177\232\180\165\229\156\186\230\153\175\228\184\142\228\184\187\233\148\174\228\191\161\230\129\175\230\159\165\232\175\162"
end

function TypeRegistrationStrictModeTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIBase.IsValidNumberValue(0))
  self:AssertTrue(RTTIBase.IsValidNumberValue(-1.25))
  self:AssertFalse(RTTIBase.IsValidNumberValue("1"))
  self:AssertFalse(RTTIBase.IsValidNumberValue(0 / 0))
  self:AssertFalse(RTTIBase.IsValidNumberValue(math.huge))
  self:AssertFalse(RTTIBase.IsValidNumberValue(-math.huge))
  self:AssertTrue(RTTIBase.IsValidNumberValue(1, true))
  self:AssertTrue(RTTIBase.IsValidNumberValue(1.0, true))
  self:AssertFalse(RTTIBase.IsValidNumberValue(1.25, true))
  self:AssertTrue(RTTIBase.IsValidStringValue("Ok"))
  self:AssertFalse(RTTIBase.IsValidStringValue(""))
  self:AssertFalse(RTTIBase.IsValidStringValue("   "))
  self:AssertFalse(RTTIBase.IsValidStringValue("\t"))
  local WrongNameTypeDefine = self:BuildMinimalTypeDefine("WrongName")
  self:AssertFalse(RTTIManager:RegisterType("RightName", WrongNameTypeDefine), "\231\177\187\229\158\139\229\144\141\228\184\141\228\184\128\232\135\180\229\186\148\230\179\168\229\134\140\229\164\177\232\180\165")
  local BadVersionTypeDefine = self:BuildMinimalTypeDefine("BadVersionType")
  BadVersionTypeDefine.Version = 0
  self:AssertFalse(RTTIManager:RegisterType("BadVersionType", BadVersionTypeDefine), "Version<=0\229\186\148\230\179\168\229\134\140\229\164\177\232\180\165")
  local BadFieldTypeDefine = self:BuildMinimalTypeDefine("BadFieldType")
  BadFieldTypeDefine.Fields[1].Type = "unknown"
  self:AssertFalse(RTTIManager:RegisterType("BadFieldType", BadFieldTypeDefine), "\229\173\151\230\174\181Type\233\157\158\230\179\149\229\186\148\230\179\168\229\134\140\229\164\177\232\180\165")
  local MultiPrimaryKeyTypeDefine = self:BuildMinimalTypeDefine("MultiPrimaryKey")
  table.insert(MultiPrimaryKeyTypeDefine.Fields, {
    Name = "SecondId",
    Type = RTTIBase.FieldType.UINT32,
    Default = 0,
    Scope = RTTIBase.ScopeType.Both,
    Required = true,
    Constraints = {
      {
        Type = RTTIBase.ConstraintType.PRIMARY_KEY
      }
    },
    Description = "\231\172\172\228\186\140\228\184\187\233\148\174\239\188\136\229\186\148\232\167\166\229\143\145\229\164\177\232\180\165\239\188\137"
  })
  self:AssertFalse(RTTIManager:RegisterType("MultiPrimaryKey", MultiPrimaryKeyTypeDefine), "\229\164\154\228\184\187\233\148\174\229\186\148\230\179\168\229\134\140\229\164\177\232\180\165")
  local OkTypeDefine = self:BuildMinimalTypeDefine("OkType")
  self:AssertTrue(true == RTTIManager:RegisterType("OkType", OkTypeDefine), "OkType\230\179\168\229\134\140\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:HasType("OkType"), "OkType\229\186\148\229\173\152\229\156\168")
  local TypeInfo = RTTIManager:GetTypeInfo("OkType")
  self:AssertTrue("table" == type(TypeInfo), "GetTypeInfo\229\186\148\230\136\144\229\138\159")
  self:AssertEquals("OkType", TypeInfo.Name)
  local PrimaryKeyName = RTTIManager:GetPrimaryKeyName("OkType")
  self:AssertType(PrimaryKeyName, "string")
end

return TypeRegistrationStrictModeTestCase

local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ReflectionPropertyCacheDataFlagTestCase = AbstractTestCase:Extend("ReflectionPropertyCacheDataFlagTestCase")

function ReflectionPropertyCacheDataFlagTestCase:Ctor()
  self.Name = "\229\143\141\229\176\132/\232\183\175\229\190\132/\229\177\158\230\128\167\231\188\147\229\173\152/DataFlag"
  self.Description = "\232\166\134\231\155\150 CreateInstance + Get/SetProperty\239\188\136\229\144\171\230\149\176\231\187\132/\229\181\140\229\165\151\232\183\175\229\190\132\239\188\137+ \229\177\158\230\128\167\231\188\147\229\173\152 + Dirty \230\160\135\232\174\176"
end

function ReflectionPropertyCacheDataFlagTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Cache = {TTL = 600, MaxSize = 2000},
    Reflection = {
      EnablePropertyCache = true,
      EnableSerialization = true,
      MaxPathDepth = 20
    },
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  self:RegisterAllTestTypes()
  local Data = RTTIManager:CreateInstance("TestDataType")
  self:AssertType(Data, "table", "CreateInstance(TestDataType)\229\186\148\232\191\148\229\155\158table")
  self:AssertTrue(RTTIManager:SetProperty("TestDataType", Data, "Name", "Alpha"))
  self:AssertEquals("Alpha", RTTIManager:GetProperty("TestDataType", Data, "Name"))
  self:AssertTrue(RTTIManager:SetProperty("TestDataType", Data, "StructValue.Element1", 5))
  self:AssertEquals(5, RTTIManager:GetProperty("TestDataType", Data, "StructValue.Element1"))
  self:AssertTrue(RTTIManager:SetProperty("TestDataType", Data, "StructValue.Element2.Property2", "Beta"))
  self:AssertEquals("Beta", RTTIManager:GetProperty("TestDataType", Data, "StructValue.Element2.Property2"))
  self:AssertTrue(RTTIManager:SetProperty("TestDataType", Data, "ArrayValue[2].Property2", "Gamma"))
  self:AssertTrue(RTTIManager:GetProperty("TestDataType", Data, "ArrayValue[2].Property2"))
  self:AssertEquals("Gamma", RTTIManager:GetProperty("TestDataType", Data, "ArrayValue[2].Property2"))
  local ArrayValue = RTTIManager:GetProperty("TestDataType", Data, "ArrayValue")
  self:AssertType(ArrayValue, "table")
  self:AssertNotNil(ArrayValue[1], "\232\183\179\232\183\131\229\188\143\229\134\153\229\133\165\229\186\148\232\161\165\233\189\144 ArrayValue[1]")
  self:AssertNotNil(ArrayValue[2], "\232\183\179\232\183\131\229\188\143\229\134\153\229\133\165\229\186\148\229\136\155\229\187\186 ArrayValue[2]")
  self:AssertTrue(RTTIBase.HasDataFlag(Data, RTTIBase.DataFlagType.Dirty), "SetProperty\229\144\142\229\186\148\230\160\135\232\174\176Dirty")
  RTTIManager:ResetSystemStatus()
  local V1 = RTTIManager:GetProperty("TestDataType", Data, "StructValue.Element2.Property2")
  local V2 = RTTIManager:GetProperty("TestDataType", Data, "StructValue.Element2.Property2")
  self:AssertEquals("Beta", V1)
  self:AssertEquals("Beta", V2)
  local Report = RTTIManager:GetSystemStatus().Statistics
  self:AssertEquals(1, Report.Cache.Miss, "\230\184\133\231\169\186PROPERTY\231\188\147\229\173\152\229\144\142\231\172\172\228\184\128\230\172\161\232\175\187\229\143\150\229\186\148\228\184\186Miss")
  self:AssertEquals(1, Report.Cache.Hit, "\231\172\172\228\186\140\230\172\161\232\175\187\229\143\150\229\144\140\228\184\128\232\183\175\229\190\132\229\186\148\228\184\186Hit")
end

return ReflectionPropertyCacheDataFlagTestCase

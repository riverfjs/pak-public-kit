local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local DuplicateInstanceTestCase = AbstractTestCase:Extend("DuplicateInstanceTestCase")

function DuplicateInstanceTestCase:Ctor()
  self.Name = "\229\164\141\229\136\187\229\174\158\228\190\139"
  self.Description = "\232\166\134\231\155\150 RTTIManager:DuplicateInstance(TypeName, Source, Force) \232\175\173\228\185\137"
end

function DuplicateInstanceTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  self:RegisterAllTestTypes()
  local Original = RTTIManager:CreateInstance("TestDataType")
  self:AssertType(Original, "table")
  Original.Id = 1
  Original.Name = "Alpha"
  Original.FloatValue = 1.5
  Original.Extra = "ShouldBeDropped"
  local Copy1, InvalidFields1 = RTTIManager:DuplicateInstance("TestDataType", Original, false)
  self:AssertType(Copy1, "table")
  self:AssertType(InvalidFields1, "table")
  self:AssertTrue(Copy1 ~= Original, "\229\164\141\229\136\187\229\186\148\232\191\148\229\155\158\230\150\176\229\175\185\232\177\161")
  self:AssertTrue(Copy1.Extra == nil, "\229\164\141\229\136\187\231\187\147\230\158\156\228\184\141\229\186\148\229\140\133\229\144\171\230\156\170\229\174\154\228\185\137\229\173\151\230\174\181")
  self:AssertTrue(0 == #InvalidFields1, "CreateInstance \228\186\167\231\148\159\231\154\132\229\175\185\232\177\161\229\173\151\230\174\181\229\186\148\229\174\140\230\149\180")
  self:AssertTrue(RTTIBase.HasDataFlag(Copy1, RTTIBase.DataFlagType.Duplicate), "\229\164\141\229\136\187\231\187\147\230\158\156\229\186\148\230\160\135\232\174\176 Duplicate")
  local Copy2, InvalidFields2 = RTTIManager:DuplicateInstance("TestDataType", Copy1, false)
  self:AssertTrue(Copy2 == Copy1, "Duplicate \229\145\189\228\184\173\229\144\142\229\186\148\229\164\141\231\148\168\229\188\149\231\148\168")
  self:AssertTrue(0 == #InvalidFields2)
  local Copy3, InvalidFields3 = RTTIManager:DuplicateInstance("TestDataType", Copy1, true)
  self:AssertType(Copy3, "table")
  self:AssertTrue(Copy3 ~= Copy1, "Force=true \229\186\148\228\186\167\231\148\159\230\150\176\229\175\185\232\177\161")
  self:AssertTrue(0 == #InvalidFields3)
  self:AssertTrue(RTTIManager:DeepEquals(Copy1, Copy3), "\229\164\141\229\136\187\229\137\141\229\144\142\229\134\133\229\174\185\229\186\148\230\183\177\231\155\184\231\173\137")
  local Incomplete = {Id = 2, Name = "Beta"}
  local Copy4, InvalidFields4 = RTTIManager:DuplicateInstance("TestDataType", Incomplete, true)
  self:AssertType(Copy4, "table")
  self:AssertType(InvalidFields4, "table")
  self:AssertTrue(#InvalidFields4 > 0, "\231\188\186\229\164\177\229\173\151\230\174\181\229\186\148\228\186\167\231\148\159 InvalidFields")
  self:AssertTrue(RTTIBase.ArrayContains(InvalidFields4, "FloatValue"), "\229\186\148\229\140\133\229\144\171\231\188\186\229\164\177\229\173\151\230\174\181\229\144\141")
end

return DuplicateInstanceTestCase

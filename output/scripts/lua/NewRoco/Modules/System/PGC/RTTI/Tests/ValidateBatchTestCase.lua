local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ValidateBatchTestCase = AbstractTestCase:Extend("ValidateBatchTestCase")

function ValidateBatchTestCase:Ctor()
  self.Name = "ValidateBatch \230\137\185\233\135\143\233\170\140\232\175\129"
  self.Description = "\232\166\134\231\155\150 ValidateBatch \231\154\132\232\129\154\229\144\136\232\190\147\229\135\186\231\187\147\230\158\132"
end

function ValidateBatchTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Validation = {StopOnFirstError = false},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  self:RegisterAllTestTypes()
  local Ok = {
    Id = 1,
    Name = "Alpha",
    Comment = "safe"
  }
  local Bad = {Id = 2, Name = ""}
  local Batch = RTTIManager:ValidateBatch("TestDataType", {Ok, Bad})
  self:AssertType(Batch, "table")
  self:AssertTrue(Batch.TotalCount >= 1)
  self:AssertTrue(Batch.FailCount >= 1)
  self:AssertTrue("table" == type(Batch.Results))
end

return ValidateBatchTestCase

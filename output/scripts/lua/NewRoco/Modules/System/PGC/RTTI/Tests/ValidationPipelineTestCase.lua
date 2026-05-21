local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ValidationPipelineTestCase = AbstractTestCase:Extend("ValidationPipelineTestCase")

function ValidationPipelineTestCase:Ctor()
  self.Name = "\233\170\140\232\175\129\230\181\129\230\176\180\231\186\191\239\188\154Syntax/Semantic/Reference/Security/\233\187\145\231\153\189\229\144\141\229\141\149/StopOnFirstError"
  self.Description = "\232\166\134\231\155\150\229\155\155\233\152\182\230\174\181\233\170\140\232\175\129\229\153\168\227\128\129\233\187\145\231\153\189\229\144\141\229\141\149\228\187\165\229\143\138 StopOnFirstError"
end

function ValidationPipelineTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Validation = {
      StopOnFirstError = false,
      EnableBlacklist = true,
      EnableWhitelist = false
    },
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  self:AssertTrue(RTTIManager:RegisterBusinessRule("IdMustBePositive", function(_, Data)
    if type(Data.Id) ~= "number" or Data.Id <= 0 then
      return false, "Id\229\191\133\233\161\187\229\164\167\228\186\1420"
    end
    return true, ""
  end, {
    "TestDataType"
  }))
  self:AssertTrue(RTTIManager:RegisterSecurityRule("NoHello", function(Text)
    if string.find(Text, "hello", 1, true) then
      return false, "\228\184\141\229\133\129\232\174\184\229\140\133\229\144\171hello"
    end
    return true, ""
  end))
  self:RegisterAllTestTypes()
  local ForeignAData = {
    [1] = {Id = 1, Tag = "A"}
  }
  local ForeignBData = {
    [2] = {Id = 2}
  }
  self:AssertTrue(RTTIManager:RegisterConfig("ForeignTypeA", self:BuildMemoryProvider(ForeignAData)))
  self:AssertTrue(RTTIManager:RegisterConfig("ForeignTypeB", self:BuildMemoryProvider(ForeignBData)))
  local OkData = RTTIManager:CreateInstance("TestDataType")
  RTTIManager:SetProperty("TestDataType", OkData, "Id", 1)
  RTTIManager:SetProperty("TestDataType", OkData, "Name", "Alpha")
  RTTIManager:SetProperty("TestDataType", OkData, "ForeignId", 1)
  RTTIManager:SetProperty("TestDataType", OkData, "RefType", "A")
  RTTIManager:SetProperty("TestDataType", OkData, "RefId", 1)
  RTTIManager:SetProperty("TestDataType", OkData, "Comment", "safe")
  local OkResult = RTTIManager:ValidateRecord("TestDataType", OkData)
  self:AssertTrue(true == OkResult.Success, "\230\173\163\229\184\184\230\149\176\230\141\174\229\186\148\233\170\140\232\175\129\233\128\154\232\191\135")
  local BadSyntax = RTTIBase.DeepCopy(OkData)
  BadSyntax.ExtraField = 1
  local BadSyntaxResult = RTTIManager:ValidateRecord("TestDataType", BadSyntax)
  self:AssertFalse(BadSyntaxResult.Success, "\229\186\148\229\155\160\230\156\170\229\174\154\228\185\137\229\173\151\230\174\181\229\164\177\232\180\165")
  local BadCustom = RTTIBase.DeepCopy(OkData)
  BadCustom.Name = ""
  local BadCustomResult = RTTIManager:ValidateRecord("TestDataType", BadCustom)
  self:AssertFalse(BadCustomResult.Success, "\229\186\148\229\155\160\232\135\170\229\174\154\228\185\137\232\167\132\229\136\153\229\164\177\232\180\165")
  local BadBusiness = RTTIBase.DeepCopy(OkData)
  BadBusiness.Id = 0
  local BadBusinessResult = RTTIManager:ValidateRecord("TestDataType", BadBusiness)
  self:AssertFalse(BadBusinessResult.Success, "\229\186\148\229\155\160\228\184\154\229\138\161\232\167\132\229\136\153\229\164\177\232\180\165")
  local BadForeignKey = RTTIBase.DeepCopy(OkData)
  BadForeignKey.ForeignId = 999
  local BadForeignKeyResult = RTTIManager:ValidateRecord("TestDataType", BadForeignKey)
  self:AssertFalse(BadForeignKeyResult.Success, "\229\186\148\229\155\160\229\164\150\233\148\174\228\184\141\229\173\152\229\156\168\229\164\177\232\180\165")
  local BadConditionKey = RTTIBase.DeepCopy(OkData)
  BadConditionKey.RefType = "B"
  BadConditionKey.RefId = 999
  local BadConditionKeyResult = RTTIManager:ValidateRecord("TestDataType", BadConditionKey)
  self:AssertFalse(BadConditionKeyResult.Success, "\229\186\148\229\155\160\230\157\161\228\187\182\229\164\150\233\148\174\228\184\141\229\173\152\229\156\168\229\164\177\232\180\165")
  local BadSecurityBuiltin = RTTIBase.DeepCopy(OkData)
  BadSecurityBuiltin.Comment = "<script>alert(1)</script>"
  local BadSecurityBuiltinResult = RTTIManager:ValidateRecord("TestDataType", BadSecurityBuiltin)
  self:AssertFalse(BadSecurityBuiltinResult.Success, "\229\186\148\229\155\160\229\174\137\229\133\168\229\134\133\231\189\174\232\167\132\229\136\153\229\164\177\232\180\165")
  local BadSecurityCustom = RTTIBase.DeepCopy(OkData)
  BadSecurityCustom.Comment = "hello world"
  local BadSecurityCustomResult = RTTIManager:ValidateRecord("TestDataType", BadSecurityCustom)
  self:AssertFalse(BadSecurityCustomResult.Success, "\229\186\148\229\155\160\232\135\170\229\174\154\228\185\137\229\174\137\229\133\168\232\167\132\229\136\153\229\164\177\232\180\165")
  RTTIManager:SetSetting("Validation.EnableWhitelist", true)
  self:AssertTrue(true == RTTIManager:RegisterWhitelistRegexp("AlphaOnly", "^[a-z]+$"), "\230\179\168\229\134\140\231\153\189\229\144\141\229\141\149\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterBlacklistRegexp("NoBad", "bad"), "\230\179\168\229\134\140\233\187\145\229\144\141\229\141\149\229\164\177\232\180\165")
  local SecurityOk = {Id = 1, Text = "abc"}
  local SecurityOkResult = RTTIManager:ValidateRecord("SecurityType", SecurityOk)
  self:AssertTrue(true == SecurityOkResult.Success, "\231\153\189\229\144\141\229\141\149\233\128\154\232\191\135\230\160\183\228\190\139\229\186\148\230\136\144\229\138\159")
  local SecurityBadWhitelist = {Id = 1, Text = "abc123"}
  local SecurityBadWhitelistResult = RTTIManager:ValidateRecord("SecurityType", SecurityBadWhitelist)
  self:AssertFalse(SecurityBadWhitelistResult.Success, "\231\153\189\229\144\141\229\141\149\230\139\166\230\136\170\230\160\183\228\190\139\229\186\148\229\164\177\232\180\165")
  local SecurityBadBlacklist = {Id = 1, Text = "bad"}
  local SecurityBadBlacklistResult = RTTIManager:ValidateRecord("SecurityType", SecurityBadBlacklist)
  self:AssertFalse(SecurityBadBlacklistResult.Success, "\233\187\145\229\144\141\229\141\149\230\139\166\230\136\170\230\160\183\228\190\139\229\186\148\229\164\177\232\180\165")
  RTTIManager:SetSetting("Validation.StopOnFirstError", true)
  local MultiError = RTTIBase.DeepCopy(OkData)
  MultiError.ExtraField = 1
  MultiError.Comment = "<script>alert(1)</script>"
  local MultiErrorResult = RTTIManager:ValidateRecord("TestDataType", MultiError)
  self:AssertFalse(MultiErrorResult.Success)
  self:AssertTrue(1 == #(MultiErrorResult.Errors or {}), "StopOnFirstError\229\188\128\229\144\175\230\151\182\229\186\148\229\143\170\232\191\148\229\155\1581\230\157\161\233\148\153\232\175\175")
  local LastValidationResult = RTTIManager:GetLastValidationResult()
  self:AssertType(LastValidationResult, "table")
  self:AssertEquals("TestDataType", LastValidationResult.TypeName)
  local LastError = RTTIManager:GetLastError()
  self:AssertTrue(nil == LastError or "table" == type(LastError))
end

return ValidationPipelineTestCase

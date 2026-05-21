local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SystemInitTestCase = AbstractTestCase:Extend("SystemInitTestCase")

function SystemInitTestCase:Ctor()
  self.Name = "\231\179\187\231\187\159\229\136\157\229\167\139\229\140\150\228\184\142\231\138\182\230\128\129\229\191\171\231\133\167"
  self.Description = "\232\166\134\231\155\150 Initialize + GetSystemStatus \229\159\186\231\161\128\229\143\175\232\167\130\230\181\139\230\128\167"
end

function SystemInitTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true, MaxNestingLevel = 20},
    Cache = {TTL = 600, MaxSize = 2000},
    Reflection = {EnablePropertyCache = true, EnableSerialization = true},
    DataProvider = {CacheResults = true},
    Statistics = {EnableCollection = true, ReportInterval = 0},
    Validation = {
      StopOnFirstError = false,
      EnableBlacklist = true,
      EnableWhitelist = false
    }
  })
  self:RegisterAllTestTypes()
  local Status = RTTIManager:GetSystemStatus()
  self:AssertType(Status, "table")
  self:AssertTrue(true == Status.Initialized, "\231\179\187\231\187\159\229\186\148\228\184\186\229\183\178\229\136\157\229\167\139\229\140\150")
  self:AssertType(Status.RegisteredTypes, "table")
  self:AssertType(Status.Statistics, "table")
  self:AssertType(Status.Settings, "table")
end

return SystemInitTestCase

local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIDataProvider = require("NewRoco.Modules.System.PGC.RTTI.RTTIDataProvider")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ProviderDuplicateAndCacheTestCase = AbstractTestCase:Extend("ProviderDuplicateAndCacheTestCase")

function ProviderDuplicateAndCacheTestCase:Ctor()
  self.Name = "Provider\239\188\154\229\137\175\230\156\172\230\160\135\232\174\176/\229\188\149\231\148\168\229\164\141\231\148\168/\230\159\165\232\175\162\231\188\147\229\173\152"
  self.Description = "\232\166\134\231\155\150 RegisterConfig + QueryByPrimaryKey + QueryByFieldName + Duplicate \230\160\135\232\174\176\228\184\142\230\159\165\232\175\162\231\188\147\229\173\152"
end

function ProviderDuplicateAndCacheTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    DataProvider = {CacheResults = true},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  self:RegisterAllTestTypes()
  local DataMap = {
    [3] = {
      Id = 3,
      Name = "Beta",
      FloatValue = 3.5
    },
    [1] = {
      Id = 1,
      Name = "Alpha",
      FloatValue = 1.5
    },
    [2] = {
      Id = 2,
      Name = "Beta",
      FloatValue = 2.5
    }
  }
  local Provider = self:BuildMemoryProvider(DataMap)
  self:AssertTrue(RTTIManager:RegisterConfig("TestDataType", Provider))
  local PrimaryKeyValues = RTTIManager:GetAllPrimaryKeyValues("TestDataType") or {}
  self:AssertType(PrimaryKeyValues, "table")
  self:AssertTrue(3 == #PrimaryKeyValues, "\229\186\148\232\191\148\229\155\158 3 \228\184\170\228\184\187\233\148\174")
  self:AssertEquals(1, PrimaryKeyValues[1])
  self:AssertEquals(2, PrimaryKeyValues[2])
  self:AssertEquals(3, PrimaryKeyValues[3])
  local Record1 = RTTIManager:QueryByPrimaryKey("TestDataType", 1)
  self:AssertType(Record1, "table")
  self:AssertEquals(1, Record1.Id)
  self:AssertTrue(Record1 == DataMap[1], "\229\142\159\231\148\159 table \230\159\165\232\175\162\229\186\148\231\155\180\230\142\165\232\191\148\229\155\158\229\188\149\231\148\168")
  self:AssertFalse(RTTIBase.HasDataFlag(Record1, RTTIBase.DataFlagType.Duplicate), "\229\142\159\231\148\159 table \228\184\141\229\186\148\232\162\171\230\160\135\232\174\176 Duplicate")
  local Record1Again = RTTIManager:QueryByPrimaryKey("TestDataType", 1)
  self:AssertTrue(Record1Again == Record1, "\229\186\148\229\164\141\231\148\168\229\188\149\231\148\168")
  RTTIManager:ResetSystemStatus()
  local List1 = RTTIManager:QueryByFieldName("TestDataType", false, "Name", "Beta")
  local Report1 = RTTIManager:GetSystemStatus().Statistics
  local List2 = RTTIManager:QueryByFieldName("TestDataType", false, "Name", "Beta")
  local Report2 = RTTIManager:GetSystemStatus().Statistics
  self:AssertType(List1, "table")
  self:AssertType(List2, "table")
  self:AssertTrue(2 == #List1 and 2 == #List2, "\229\186\148\229\145\189\228\184\173\228\184\164\230\157\161Beta")
  self:AssertTrue(Report1.Cache.Miss >= 1, "\233\166\150\230\172\161\230\159\165\232\175\162\229\186\148\232\135\179\229\176\145\228\184\128\230\172\161Miss")
  self:AssertTrue(Report2.Cache.Hit >= 1, "\231\172\172\228\186\140\230\172\161\230\159\165\232\175\162\229\186\148\232\135\179\229\176\145\228\184\128\230\172\161Hit")
  local MissBefore = Report2.Cache.Miss or 0
  local Insert4 = {
    Id = 4,
    Name = "Beta",
    FloatValue = 4.5
  }
  self:AssertTrue(true == RTTIDataProvider:InsertRecord("TestDataType", Insert4), "InsertRecord(4) \229\186\148\230\136\144\229\138\159")
  self:AssertType(DataMap[4], "table", "Insert \229\144\142 DataMap[4] \229\186\148\229\173\152\229\156\168")
  local InsertNoIdRecord = {Name = "Gamma", FloatValue = 5.5}
  self:AssertFalse(true == RTTIDataProvider:InsertRecord("TestDataType", InsertNoIdRecord), "InsertRecord(\231\188\186\228\184\187\233\148\174) \229\186\148\229\164\177\232\180\165")
  self:AssertFalse(true == RTTIDataProvider:InsertRecord("TestDataType", Insert4), "\233\135\141\229\164\141 InsertRecord(4) \229\186\148\229\164\177\232\180\165")
  local PrimaryKeyValues2 = RTTIManager:GetAllPrimaryKeyValues("TestDataType") or {}
  self:AssertTrue(4 == #PrimaryKeyValues2)
  self:AssertEquals(1, PrimaryKeyValues2[1])
  self:AssertEquals(2, PrimaryKeyValues2[2])
  self:AssertEquals(3, PrimaryKeyValues2[3])
  self:AssertEquals(4, PrimaryKeyValues2[4])
  local List3 = RTTIManager:QueryByFieldName("TestDataType", false, "Name", "Beta")
  local Report3 = RTTIManager:GetSystemStatus().Statistics
  self:AssertType(List3, "table")
  self:AssertTrue(3 == #List3, "\230\143\146\229\133\165\229\144\142\229\186\148\229\145\189\228\184\173\228\184\137\230\157\161Beta")
  self:AssertTrue(MissBefore < (Report3.Cache.Miss or 0), "\230\143\146\229\133\165\229\144\142\229\186\148\230\184\133\233\153\164\230\159\165\232\175\162\231\188\147\229\173\152\230\161\182\239\188\140\230\159\165\232\175\162\229\186\148\228\186\167\231\148\159Miss")
  RTTIManager:RegisterPrimaryKeyGenerateHook("TestDataType", function()
    local Keys = RTTIManager:GetAllPrimaryKeyValues("TestDataType") or {}
    local MaxKey = 0
    for _, Key in ipairs(Keys) do
      local K = tonumber(Key)
      if K and MaxKey < K then
        MaxKey = K
      end
    end
    return MaxKey + 1
  end)
  local InsertInstance = RTTIManager:CreateInstance("TestDataType")
  self:AssertType(InsertInstance, "table", "CreateInstance \229\186\148\230\136\144\229\138\159")
  self:AssertTrue(5 == InsertInstance.Id, "\231\188\186\231\156\129\229\128\188\230\142\168\229\175\188\233\152\182\230\174\181\229\186\148\229\144\136\230\136\144 Id=5")
  RTTIManager:SetProperty("TestDataType", InsertInstance, "Name", "Gamma")
  RTTIManager:SetProperty("TestDataType", InsertInstance, "FloatValue", 5.5)
  self:AssertType(DataMap[5], "table", "CreateInstance \229\144\142 DataMap[5] \229\186\148\229\173\152\229\156\168")
  local PrimaryKeyValues2_1 = RTTIManager:GetAllPrimaryKeyValues("TestDataType") or {}
  self:AssertTrue(5 == #PrimaryKeyValues2_1)
  self:AssertEquals(5, PrimaryKeyValues2_1[5])
  RTTIManager:UnregisterPrimaryKeyGenerateHook("TestDataType")
  local MissBeforeDelete = Report3.Cache.Miss or 0
  self:AssertTrue(true == RTTIDataProvider:DeleteRecord("TestDataType", 2), "DeleteRecord(2) \229\186\148\230\136\144\229\138\159")
  self:AssertFalse(true == RTTIDataProvider:DeleteRecord("TestDataType", 999), "DeleteRecord(\228\184\141\229\173\152\229\156\168) \229\186\148\229\164\177\232\180\165")
  local Deleted2 = RTTIManager:QueryByPrimaryKey("TestDataType", 2)
  self:AssertTrue(nil == Deleted2, "\229\136\160\233\153\164\229\144\142 QueryByPrimaryKey(2) \229\186\148\232\191\148\229\155\158 nil")
  local List4 = RTTIManager:QueryByFieldName("TestDataType", false, "Name", "Beta")
  local Report4 = RTTIManager:GetSystemStatus().Statistics
  self:AssertType(List4, "table")
  self:AssertTrue(2 == #List4, "\229\136\160\233\153\164\229\144\142\229\186\148\229\145\189\228\184\173\228\184\164\230\157\161Beta")
  self:AssertTrue(MissBeforeDelete < (Report4.Cache.Miss or 0), "\229\136\160\233\153\164\229\144\142\229\186\148\230\184\133\233\153\164\230\159\165\232\175\162\231\188\147\229\173\152\230\161\182\239\188\140\230\159\165\232\175\162\229\186\148\228\186\167\231\148\159Miss")
  local PrimaryKeyValues3 = RTTIManager:GetAllPrimaryKeyValues("TestDataType") or {}
  self:AssertTrue(4 == #PrimaryKeyValues3)
  self:AssertEquals(1, PrimaryKeyValues3[1])
  self:AssertEquals(3, PrimaryKeyValues3[2])
  self:AssertEquals(4, PrimaryKeyValues3[3])
  self:AssertEquals(5, PrimaryKeyValues3[4])
  local NativeDataMap = {
    [1] = setmetatable({
      Id = 1,
      Name = "Native",
      FloatValue = 1.0
    }, {})
  }
  local NativeProvider = self:BuildMemoryProvider(NativeDataMap)
  self:AssertTrue(RTTIManager:RegisterConfig("TestDataType", NativeProvider))
  local NativeRecord = RTTIManager:QueryByFieldName("TestDataType", true, "Id", 1)
  self:AssertType(NativeRecord, "table")
  self:AssertTrue(nil == getmetatable(NativeRecord), "\229\164\141\229\136\187\231\187\147\230\158\156\229\186\148\228\184\186 Lua table\239\188\136\230\151\160 metatable\239\188\137")
  self:AssertTrue(RTTIBase.HasDataFlag(NativeRecord, RTTIBase.DataFlagType.Duplicate), "\229\164\141\229\136\187\231\187\147\230\158\156\229\186\148\230\160\135\232\174\176 Duplicate")
  self:AssertTrue(NativeDataMap[1] == NativeRecord, "\229\164\141\229\136\187\229\144\142\229\186\148\229\134\153\229\155\158 Provider \229\185\182\229\164\141\231\148\168\229\188\149\231\148\168")
end

return ProviderDuplicateAndCacheTestCase

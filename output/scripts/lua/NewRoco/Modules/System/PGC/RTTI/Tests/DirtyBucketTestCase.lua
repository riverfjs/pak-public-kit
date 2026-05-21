local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local RTTIReflection = require("NewRoco.Modules.System.PGC.RTTI.RTTIReflection")
local RTTIYamlStore = require("NewRoco.Modules.System.PGC.RTTI.RTTIYamlStore")
local DirtyBucketTestCase = AbstractTestCase:Extend("DirtyBucketTestCase")

function DirtyBucketTestCase:Ctor()
  self.Name = "\232\132\143\230\161\182\239\188\154SaveDirtyBucket"
  self.Description = "\232\166\134\231\155\150\232\132\143\230\149\176\230\141\174\230\148\182\233\155\134\228\184\142 SaveDirtyBucket \228\191\157\229\173\152\231\187\147\230\158\156\231\187\159\232\174\161"
end

function DirtyBucketTestCase:AfterEach()
  local YamlPath = RTTIYamlStore.ResolveYamlFilePath("DirtySaveSuccessType", false)
  if YamlPath then
    pcall(os.remove, YamlPath)
  end
end

function DirtyBucketTestCase:OnExecute()
  local YamlRootDir = "Content/Script/NewRoco/Modules/System/PGC/RTTI/Tests/"
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Reflection = {EnablePropertyCache = false, YamlRootDir = YamlRootDir},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  local SuccessTypeName = "DirtySaveSuccessType"
  local SuccessTypeDefine = {
    Name = SuccessTypeName,
    Version = 1,
    Description = "\232\132\143\230\161\182\228\191\157\229\173\152\230\136\144\229\138\159\230\181\139\232\175\149\231\177\187\229\158\139",
    Metadata = {RelativeYamlPath = "Test.yaml"},
    Fields = {
      {
        Name = "Id",
        Type = RTTIBase.FieldType.UINT32,
        Default = 1,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.PRIMARY_KEY
          }
        },
        Description = "\228\184\187\233\148\174"
      },
      {
        Name = "Name",
        Type = RTTIBase.FieldType.STRING,
        Default = "Alpha",
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Description = "\229\144\141\231\167\176"
      }
    }
  }
  self:AssertTrue(RTTIManager:RegisterType(SuccessTypeName, SuccessTypeDefine))
  local Data1 = RTTIManager:CreateInstance(SuccessTypeName)
  self:AssertType(Data1, "table")
  self:AssertTrue(RTTIBase.HasDataFlag(Data1, RTTIBase.DataFlagType.Dirty), "CreateInstance \229\144\142\229\186\148\230\160\135\232\174\176 Dirty")
  local SaveResult1 = RTTIManager:SaveDirtyBucket(SuccessTypeName, true)
  self:AssertType(SaveResult1, "table")
  self:AssertEquals(1, SaveResult1.TotalCount, "\229\186\148\228\191\157\229\173\152 1 \230\157\161\232\132\143\230\149\176\230\141\174")
  self:AssertTrue(true == SaveResult1.Success)
  self:AssertEquals(1, SaveResult1.SuccessCount)
  self:AssertEquals(0, SaveResult1.FailCount)
  self:AssertType(SaveResult1.Results, "table")
  self:AssertTrue(1 == #SaveResult1.Results)
  local SaveResult1Again = RTTIManager:SaveDirtyBucket(SuccessTypeName, true)
  self:AssertEquals(0, SaveResult1Again.TotalCount, "\228\191\157\229\173\152\230\136\144\229\138\159\229\144\142\229\186\148\228\187\142\232\132\143\230\161\182\231\167\187\233\153\164\239\188\140\233\129\191\229\133\141\233\135\141\229\164\141\228\191\157\229\173\152")
  self:AssertTrue(RTTIManager:RegisterCustomRule("NonEmptyString", function(_, FieldValue)
    return type(FieldValue) == "string" and "" ~= FieldValue, "\229\173\151\231\172\166\228\184\178\228\184\141\232\131\189\228\184\186\231\169\186"
  end))
  local FailTypeName = "DirtySaveFailType"
  local FailTypeDefine = {
    Name = FailTypeName,
    Version = 1,
    Description = "\232\132\143\230\161\182\228\191\157\229\173\152\229\164\177\232\180\165\230\181\139\232\175\149\231\177\187\229\158\139",
    Metadata = {RelativeYamlPath = "Test.xlsx"},
    Fields = {
      {
        Name = "Id",
        Type = RTTIBase.FieldType.UINT32,
        Default = 1,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.PRIMARY_KEY
          }
        },
        Description = "\228\184\187\233\148\174"
      },
      {
        Name = "Name",
        Type = RTTIBase.FieldType.STRING,
        Default = "",
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.CUSTOM,
            RuleName = "NonEmptyString"
          }
        },
        Description = "\229\144\141\231\167\176\239\188\136\228\184\141\232\131\189\228\184\186\231\169\186\239\188\137"
      }
    }
  }
  self:AssertTrue(RTTIManager:RegisterType(FailTypeName, FailTypeDefine))
  local Data2 = RTTIManager:CreateInstance(FailTypeName)
  self:AssertType(Data2, "table")
  local SaveResult2 = RTTIManager:SaveDirtyBucket(FailTypeName, true)
  self:AssertType(SaveResult2, "table")
  self:AssertEquals(1, SaveResult2.TotalCount)
  self:AssertTrue(false == SaveResult2.Success)
  self:AssertEquals(1, SaveResult2.FailCount)
  local RollbackTypeName = "DirtyRollbackType"
  local RollbackTypeDefine = {
    Name = RollbackTypeName,
    Version = 1,
    Description = "\232\132\143\230\161\182\229\155\158\230\187\154\230\184\133\232\132\143\230\181\139\232\175\149\231\177\187\229\158\139",
    Metadata = {RelativeYamlPath = "Test.xlsx"},
    Fields = {
      {
        Name = "Id",
        Type = RTTIBase.FieldType.UINT32,
        Default = 1,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.PRIMARY_KEY
          }
        },
        Description = "\228\184\187\233\148\174"
      },
      {
        Name = "Name",
        Type = RTTIBase.FieldType.STRING,
        Default = "Alpha",
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Description = "\229\144\141\231\167\176"
      }
    }
  }
  self:AssertTrue(RTTIManager:RegisterType(RollbackTypeName, RollbackTypeDefine))
  local Source3 = {Id = 1, Name = "Alpha"}
  local Data3 = RTTIManager:DuplicateInstance(RollbackTypeName, Source3, false)
  self:AssertType(Data3, "table")
  self:AssertFalse(RTTIBase.HasDataFlag(Data3, RTTIBase.DataFlagType.Dirty), "\229\164\141\229\136\187\229\142\159\229\167\139\230\149\176\230\141\174\229\144\142\233\187\152\232\174\164\228\184\141\229\186\148 Dirty")
  local Bucket3 = RTTIReflection.DirtyBucketByTypeName[RollbackTypeName]
  if Bucket3 then
    self:AssertTrue(Bucket3.DataMap[1] == nil, "\230\156\170 Dirty \228\184\141\229\186\148\232\191\155\229\133\165\232\132\143\230\161\182")
  end
  self:AssertTrue(RTTIManager:SetProperty(RollbackTypeName, Data3, "Name", "Beta"))
  self:AssertTrue(RTTIBase.HasDataFlag(Data3, RTTIBase.DataFlagType.Dirty), "\228\191\174\230\148\185\229\144\142\229\186\148 Dirty")
  Bucket3 = RTTIReflection.DirtyBucketByTypeName[RollbackTypeName]
  self:AssertType(Bucket3, "table")
  self:AssertTrue(Bucket3.DataMap[1] == Data3, "\231\189\174\232\132\143\229\144\142\229\186\148\229\133\165\230\161\182")
  self:AssertTrue(RTTIManager:SetProperty(RollbackTypeName, Data3, "Name", "Alpha"))
  self:AssertFalse(RTTIBase.HasDataFlag(Data3, RTTIBase.DataFlagType.Dirty), "\229\155\158\230\187\154\229\136\176\229\164\135\228\187\189\229\128\188\229\144\142\229\186\148\230\184\133\232\132\143")
  Bucket3 = RTTIReflection.DirtyBucketByTypeName[RollbackTypeName]
  if Bucket3 then
    self:AssertTrue(Bucket3.DataMap[1] == nil, "\230\184\133\232\132\143\229\144\142\229\186\148\229\135\186\230\161\182")
  end
end

return DirtyBucketTestCase

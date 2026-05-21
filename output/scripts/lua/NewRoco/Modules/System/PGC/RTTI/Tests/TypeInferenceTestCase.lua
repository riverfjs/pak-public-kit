local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TypeInferenceTestCase = AbstractTestCase:Extend("TypeInferenceTestCase")

function TypeInferenceTestCase:Ctor()
  self.Name = "\231\177\187\229\158\139\230\142\168\229\175\188\229\155\158\229\189\146\239\188\154ConditionKey/SmartForeignKey/\230\149\176\231\187\132\229\133\131\231\180\160\231\186\166\230\157\159"
  self.Description = "\232\166\134\231\155\150 InferFieldType \231\154\132\230\149\176\231\187\132\230\142\168\229\175\188\229\189\162\230\128\129\227\128\129\230\157\161\228\187\182\229\164\150\233\148\174\229\136\134\230\148\175\230\142\168\229\175\188\227\128\129\230\153\186\232\131\189\229\164\150\233\148\174\230\160\161\233\170\140\228\184\142\231\188\186\231\156\129\229\128\188\228\191\174\230\173\163"
end

local function AddStringField(TypeDefine, FieldName)
  table.insert(TypeDefine.Fields, {
    Name = FieldName,
    Type = RTTIBase.FieldType.STRING,
    Default = "",
    Scope = RTTIBase.ScopeType.Both,
    Required = false,
    Constraints = {},
    Description = "\230\181\139\232\175\149\229\173\151\230\174\181"
  })
end

local function AddNumberFieldWithValueLimit(TypeDefine, FieldName, Min, Max)
  table.insert(TypeDefine.Fields, {
    Name = FieldName,
    Type = RTTIBase.FieldType.UINT32,
    Default = 0,
    Scope = RTTIBase.ScopeType.Both,
    Required = false,
    Constraints = {
      {
        Type = RTTIBase.ConstraintType.LIMIT_VALUE,
        Ranges = {
          {Min = Min, Max = Max}
        }
      }
    },
    Description = "\229\143\150\229\128\188\231\186\166\230\157\159\229\173\151\230\174\181(vl)"
  })
end

function TypeInferenceTestCase:OnExecute()
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Validation = {
      StopOnFirstError = true,
      EnableBlacklist = false,
      EnableWhitelist = false
    },
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  local InferForeignA = self:BuildMinimalTypeDefine("InferForeignA")
  AddStringField(InferForeignA, "Tag")
  local InferForeignB = self:BuildMinimalTypeDefine("InferForeignB")
  self:AssertTrue(true == RTTIManager:RegisterType(InferForeignA.Name, InferForeignA), "\230\179\168\229\134\140 InferForeignA \229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(InferForeignB.Name, InferForeignB), "\230\179\168\229\134\140 InferForeignB \229\164\177\232\180\165")
  local ForeignAData = {
    [1] = {Id = 1, Tag = "A"},
    [2] = {Id = 2, Tag = "B"}
  }
  local ForeignBData = {
    [10] = {Id = 10}
  }
  self:AssertTrue(true == RTTIManager:RegisterConfig(InferForeignA.Name, self:BuildMemoryProvider(ForeignAData)), "\230\179\168\229\134\140 InferForeignA Provider \229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterConfig(InferForeignB.Name, self:BuildMemoryProvider(ForeignBData)), "\230\179\168\229\134\140 InferForeignB Provider \229\164\177\232\180\165")
  local InferLimitA = self:BuildMinimalTypeDefine("InferLimitA")
  AddNumberFieldWithValueLimit(InferLimitA, "Score", 1, 3)
  local InferLimitB = self:BuildMinimalTypeDefine("InferLimitB")
  AddNumberFieldWithValueLimit(InferLimitB, "Score", 10, 12)
  self:AssertTrue(true == RTTIManager:RegisterType(InferLimitA.Name, InferLimitA), "\230\179\168\229\134\140 InferLimitA \229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(InferLimitB.Name, InferLimitB), "\230\179\168\229\134\140 InferLimitB \229\164\177\232\180\165")
  local InferLimitAData = {
    [1] = {Id = 1, Score = 1},
    [2] = {Id = 2, Score = 3}
  }
  local InferLimitBData = {
    [10] = {Id = 10, Score = 10},
    [11] = {Id = 11, Score = 12}
  }
  self:AssertTrue(true == RTTIManager:RegisterConfig(InferLimitA.Name, self:BuildMemoryProvider(InferLimitAData)), "\230\179\168\229\134\140 InferLimitA Provider \229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterConfig(InferLimitB.Name, self:BuildMemoryProvider(InferLimitBData)), "\230\179\168\229\134\140 InferLimitB Provider \229\164\177\232\180\165")
  local InferOwnerArray = {
    Name = "InferOwnerArray",
    Version = 1,
    Description = "\230\157\161\228\187\182\230\142\168\229\175\188\230\149\176\231\187\132\229\173\151\230\174\181",
    Metadata = {NeedPrimaryKey = true},
    Fields = {
      {
        Name = "Id",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
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
        Name = "Kind",
        Type = RTTIBase.FieldType.STRING,
        Default = "A",
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = "\229\136\134\230\148\175\233\169\177\229\138\168\229\173\151\230\174\181"
      },
      {
        Name = "Values",
        Type = RTTIBase.FieldType.ARRAY,
        Default = {},
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.UINT32
          },
          {
            Type = RTTIBase.ConstraintType.CONDITION_KEY,
            DriverField = "Kind",
            Branches = {
              {
                Value = "A",
                TypeName = "InferLimitA",
                FieldName = "Score"
              },
              {
                Value = "B",
                TypeName = "InferLimitB",
                FieldName = "Score"
              }
            }
          }
        },
        Description = "\230\157\161\228\187\182\230\142\168\229\175\188\230\149\176\231\187\132\239\188\154\229\133\131\231\180\160\231\186\166\230\157\159\233\154\143\229\136\134\230\148\175\229\143\152\229\140\150"
      }
    }
  }
  self:AssertTrue(true == RTTIManager:RegisterType(InferOwnerArray.Name, InferOwnerArray), "\230\179\168\229\134\140 InferOwnerArray \229\164\177\232\180\165")
  local OkA = {
    Id = 1,
    Kind = "A",
    Values = {1, 3}
  }
  local OkAResult = RTTIManager:ValidateRecord(InferOwnerArray.Name, OkA)
  self:AssertTrue(true == OkAResult.Success, "Kind=A \228\184\148 Values={1,3} \229\186\148\233\128\154\232\191\135\239\188\136ARRAY \230\142\168\229\175\188\228\184\141\229\186\148\231\160\180\229\157\143\231\177\187\229\158\139\239\188\137")
  local BadTypeA = RTTIBase.DeepCopy(OkA)
  BadTypeA.Values = 1
  local BadTypeAResult = RTTIManager:ValidateRecord(InferOwnerArray.Name, BadTypeA)
  self:AssertFalse(true == BadTypeAResult.Success, "Values \233\157\158\230\149\176\231\187\132\230\151\182\229\186\148\229\164\177\232\180\165")
  local BadVlA = RTTIBase.DeepCopy(OkA)
  BadVlA.Values = {0}
  local BadVlAResult = RTTIManager:ValidateRecord(InferOwnerArray.Name, BadVlA)
  self:AssertFalse(true == BadVlAResult.Success, "Kind=A \230\151\182 Values \229\133\131\231\180\160 < 1 \229\186\148\229\155\160 vl \229\164\177\232\180\165")
  local OkB = RTTIBase.DeepCopy(OkA)
  OkB.Kind = "B"
  OkB.Values = {10, 12}
  local OkBResult = RTTIManager:ValidateRecord(InferOwnerArray.Name, OkB)
  self:AssertTrue(true == OkBResult.Success, "Kind=B \228\184\148 Values={10,12} \229\186\148\233\128\154\232\191\135")
  local BadVlB = RTTIBase.DeepCopy(OkB)
  BadVlB.Values = {9}
  local BadVlBResult = RTTIManager:ValidateRecord(InferOwnerArray.Name, BadVlB)
  self:AssertFalse(true == BadVlBResult.Success, "Kind=B \230\151\182 Values \229\133\131\231\180\160 < 10 \229\186\148\229\155\160 vl \229\164\177\232\180\165")
  local SmartLinkEnum = {
    Name = "SmartLinkEnum",
    Fields = {
      {
        Name = "A",
        Value = 1,
        Description = "link:InferForeignA,Id"
      },
      {
        Name = "B",
        Value = 2,
        Description = "link:InferForeignB,Id"
      }
    }
  }
  self:AssertTrue(true == RTTIManager:RegisterEnum(SmartLinkEnum.Name, SmartLinkEnum), "\230\179\168\229\134\140 SmartLinkEnum \229\164\177\232\180\165")
  local InferSmartOwner = {
    Name = "InferSmartOwner",
    Version = 1,
    Description = "\230\153\186\232\131\189\229\164\150\233\148\174 Owner",
    Metadata = {NeedPrimaryKey = true},
    Fields = {
      {
        Name = "Id",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
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
        Name = "DriverEnum",
        Type = RTTIBase.FieldType.ENUM,
        Default = 1,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ENUM,
            EnumName = "SmartLinkEnum"
          }
        },
        Description = "\230\153\186\232\131\189\229\164\150\233\148\174\233\169\177\229\138\168\229\173\151\230\174\181"
      },
      {
        Name = "SmartId",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
            EnumName = "SmartLinkEnum",
            DriverField = "DriverEnum",
            LinkFieldName = "link"
          }
        },
        Description = "\230\153\186\232\131\189\229\164\150\233\148\174\229\173\151\230\174\181"
      },
      {
        Name = "TagRef",
        Type = RTTIBase.FieldType.STRING,
        Default = "",
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.FOREIGN_KEY,
            TypeName = "InferForeignA",
            FieldName = "Tag"
          }
        },
        Description = "\233\157\158\228\184\187\233\148\174\229\164\150\233\148\174\239\188\136\229\145\189\228\184\173 QueryByFieldName \229\136\134\230\148\175\239\188\137"
      }
    }
  }
  self:AssertTrue(true == RTTIManager:RegisterType(InferSmartOwner.Name, InferSmartOwner), "\230\179\168\229\134\140 InferSmartOwner \229\164\177\232\180\165")
  local SmartOk = {
    Id = 1,
    DriverEnum = 1,
    SmartId = 1,
    TagRef = "A"
  }
  local SmartOkResult = RTTIManager:ValidateRecord(InferSmartOwner.Name, SmartOk)
  self:AssertTrue(true == SmartOkResult.Success, "SmartId=1 \229\186\148\233\128\154\232\191\135\239\188\136\230\153\186\232\131\189\229\164\150\233\148\174\229\173\152\229\156\168\239\188\137")
  local SmartBad = RTTIBase.DeepCopy(SmartOk)
  SmartBad.SmartId = 999
  local SmartBadResult = RTTIManager:ValidateRecord(InferSmartOwner.Name, SmartBad)
  self:AssertFalse(true == SmartBadResult.Success, "SmartId \228\184\141\229\173\152\229\156\168\229\186\148\229\164\177\232\180\165\239\188\136\230\153\186\232\131\189\229\164\150\233\148\174\229\173\152\229\156\168\230\128\167\230\160\161\233\170\140\239\188\137")
  local SmartOkB = RTTIBase.DeepCopy(SmartOk)
  SmartOkB.DriverEnum = 2
  SmartOkB.SmartId = 10
  local SmartOkBResult = RTTIManager:ValidateRecord(InferSmartOwner.Name, SmartOkB)
  self:AssertTrue(true == SmartOkBResult.Success, "DriverEnum=2 \228\184\148 SmartId=10 \229\186\148\233\128\154\232\191\135\239\188\136\229\145\189\228\184\173 InferForeignB.Id\239\188\137")
  local SmartBadB = RTTIBase.DeepCopy(SmartOkB)
  SmartBadB.SmartId = 1
  local SmartBadBResult = RTTIManager:ValidateRecord(InferSmartOwner.Name, SmartBadB)
  self:AssertFalse(true == SmartBadBResult.Success, "DriverEnum=2 \228\184\148 SmartId=1 \229\186\148\229\164\177\232\180\165\239\188\136InferForeignB \228\184\141\229\173\152\229\156\168\232\175\165\228\184\187\233\148\174\239\188\137")
  local TagBad = RTTIBase.DeepCopy(SmartOk)
  TagBad.TagRef = "Z"
  local TagBadResult = RTTIManager:ValidateRecord(InferSmartOwner.Name, TagBad)
  self:AssertFalse(true == TagBadResult.Success, "TagRef \228\184\141\229\173\152\229\156\168\229\186\148\229\164\177\232\180\165\239\188\136\233\157\158\228\184\187\233\148\174\229\164\150\233\148\174\229\173\152\229\156\168\230\128\167\230\160\161\233\170\140\239\188\137")
  local Instance = RTTIManager:CreateInstance(InferSmartOwner.Name)
  self:AssertType(Instance, "table", "CreateInstance \229\186\148\232\191\148\229\155\158 table")
  local DriverEnum = "table" == type(Instance) and Instance.DriverEnum or nil
  local SmartId = "table" == type(Instance) and Instance.SmartId or nil
  self:AssertEquals(1, DriverEnum, "DriverEnum \231\188\186\231\156\129\229\186\148\228\184\186 1")
  self:AssertEquals(1, SmartId, "SmartId \231\188\186\231\156\129\229\128\188\229\186\148\232\162\171\228\191\174\230\173\163\228\184\186\229\164\150\232\161\168\230\156\128\229\176\143\228\184\187\233\148\174\229\128\188 1")
end

return TypeInferenceTestCase

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local AbstractTestCase = RTTIBase.Class("AbstractTestCase")

function AbstractTestCase:Ctor()
  self.Name = self.Name or "UnnamedTestCase"
  self.Description = self.Description or ""
  self.Enabled = self.Enabled ~= false
end

function AbstractTestCase:AssertTrue(Condition, Message)
  if not Condition then
    local LastError = RTTIManager:GetLastError()
    local AssertMessage = string.format("Message = %s, LastError = %s", Message, LastError and LastError.Message)
    error(AssertMessage)
  end
end

function AbstractTestCase:AssertFalse(Condition, Message)
  self:AssertTrue(not Condition, Message)
end

function AbstractTestCase:AssertType(Value, ExpectedType, Message)
  self:AssertTrue(type(Value) == ExpectedType, Message or "\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\239\188\140\230\156\159\230\156\155=" .. ExpectedType .. " \229\174\158\233\153\133=" .. type(Value))
end

function AbstractTestCase:AssertNotNil(Value, Message)
  self:AssertTrue(nil ~= Value, Message or "\229\128\188\228\184\141\229\186\148\228\184\186nil")
end

function AbstractTestCase:AssertEquals(Expected, Actual, Message)
  Message = Message or string.format("\230\150\173\232\168\128\231\155\184\231\173\137\229\164\177\232\180\165\239\188\140\230\156\159\230\156\155=%s \229\174\158\233\153\133=%s", tostring(Expected), tostring(Actual))
  self:AssertTrue(Expected == Actual, Message)
end

function AbstractTestCase:AssertStringContains(Text, Sub, Message)
  self:AssertType(Sub, "string")
  self:AssertType(Text, "string", Message or "\230\150\135\230\156\172\229\191\133\233\161\187\228\184\186string")
  self:AssertTrue(string.find(Text, Sub, 1, true) ~= nil, Message or "\230\150\135\230\156\172\228\184\141\229\140\133\229\144\171\229\173\144\228\184\178: " .. Sub)
end

function AbstractTestCase:AssertTableHasKey(TableValue, Key, Message)
  self:AssertType(TableValue, "table", Message or "\231\155\174\230\160\135\229\191\133\233\161\187\228\184\186table")
  self:AssertTrue(nil ~= TableValue[Key], Message or "\232\161\168\228\184\173\231\188\186\229\176\145\233\148\174: " .. tostring(Key))
end

function AbstractTestCase:BeforeEach()
end

function AbstractTestCase:AfterEach()
end

function AbstractTestCase:OnExecute()
  error("AbstractTestCase:OnExecute \229\191\133\233\161\187\231\148\177\229\173\144\231\177\187\229\174\158\231\142\176")
end

function AbstractTestCase:Run(Results)
  if not Results then
    error("Results\228\184\141\232\131\189\228\184\186\231\169\186")
  end
  Results.Total = (Results.Total or 0) + 1
  Results.Passed = Results.Passed or 0
  Results.Failed = Results.Failed or 0
  Results.Failures = Results.Failures or {}
  if self.Enabled == false then
    Results.Passed = Results.Passed + 1
    print("[SKIP]", self.Name)
    return true
  end
  
  local function FormatError(Err)
    local Message = tostring(Err)
    if debug and debug.traceback then
      return Message .. "\n" .. debug.traceback()
    end
    return Message
  end
  
  local Success, ErrorMessage = xpcall(function()
    self:BeforeEach()
    self:OnExecute()
    self:AfterEach()
  end, FormatError)
  if Success then
    Results.Passed = Results.Passed + 1
    print("[PASS]", self.Name)
    return true
  end
  Results.Failed = Results.Failed + 1
  table.insert(Results.Failures, {
    Name = self.Name,
    ErrorMessage = tostring(ErrorMessage)
  })
  print("[FAIL]", self.Name, tostring(ErrorMessage))
  return false
end

function AbstractTestCase:ResetRTTIEnvironment(UserSettings)
  RTTIManager:Shutdown()
  UserSettings = UserSettings or {}
  UserSettings.User = {Name = "jaunwang"}
  UserSettings.Ruler = {
    NPC_REFRESH_CONTENT_CONF = {new_key_padding = 5}
  }
  RTTIManager:Initialize(UserSettings)
end

function AbstractTestCase:BuildMinimalTypeDefine(TypeName)
  return {
    Name = TypeName,
    Version = 1,
    Description = "\230\156\128\229\176\143\230\181\139\232\175\149\231\177\187\229\158\139",
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
      }
    }
  }
end

function AbstractTestCase:BuildMemoryProvider(DataMap)
  return {
    GetAllDatas = function()
      return DataMap
    end,
    GetData = function(_, PrimaryKey)
      return DataMap[PrimaryKey]
    end,
    SaveData = function(_, PrimaryKey, Record)
      DataMap[PrimaryKey] = Record
      return true
    end,
    InsertData = function(_, PrimaryKey, Record)
      if nil ~= DataMap[PrimaryKey] then
        return false
      end
      DataMap[PrimaryKey] = Record
      return true
    end,
    DeleteData = function(_, PrimaryKey)
      if nil == DataMap[PrimaryKey] then
        return false
      end
      DataMap[PrimaryKey] = nil
      return true
    end
  }
end

function AbstractTestCase:RegisterAllTestTypes()
  local TestElementType1 = {
    Name = "TestElementType1",
    Version = 1,
    Description = "\230\181\139\232\175\149\229\133\131\231\180\160\231\177\187\229\158\1391",
    Metadata = {},
    Fields = {
      {
        Name = "Property1",
        Type = RTTIBase.FieldType.UINT32,
        Default = 1,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.LIMIT_VALUE,
            Ranges = {
              {Min = 1, Max = 100}
            }
          }
        },
        Description = "\229\143\150\229\128\188\231\186\166\230\157\159\229\173\151\230\174\181(vl)"
      },
      {
        Name = "Property2",
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
        Description = "\232\135\170\229\174\154\228\185\137\232\167\132\229\136\153\229\173\151\230\174\181"
      }
    }
  }
  local TestElementType2 = {
    Name = "TestElementType2",
    Version = 1,
    Description = "\230\181\139\232\175\149\229\133\131\231\180\160\231\177\187\229\158\1392\239\188\136\229\181\140\229\165\151\231\187\147\230\158\132\239\188\137",
    Metadata = {},
    Fields = {
      {
        Name = "Element1",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {},
        Description = "\229\133\131\231\180\1601"
      },
      {
        Name = "Element2",
        Type = RTTIBase.FieldType.STRUCT,
        Default = {},
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = "TestElementType1"
          }
        },
        Description = "\229\133\131\231\180\1602"
      }
    }
  }
  local ForeignTypeA = self:BuildMinimalTypeDefine("ForeignTypeA")
  local ForeignTypeB = self:BuildMinimalTypeDefine("ForeignTypeB")
  table.insert(ForeignTypeA.Fields, {
    Name = "Tag",
    Type = RTTIBase.FieldType.STRING,
    Default = "",
    Scope = RTTIBase.ScopeType.Both,
    Required = false,
    Constraints = {},
    Description = "\230\160\135\231\173\190"
  })
  local TestEnum = {
    Name = "TestEnum",
    Fields = {
      {
        Name = "One",
        Value = 1,
        Description = ""
      },
      {
        Name = "Two",
        Value = 2,
        Description = ""
      },
      {
        Name = "Three",
        Value = 3,
        Description = ""
      }
    }
  }
  RTTIManager:RegisterEnum(TestEnum.Name, TestEnum)
  local TestDataType = {
    Name = "TestDataType",
    Version = 1,
    Description = "\230\181\139\232\175\149\230\149\176\230\141\174\231\177\187\229\158\139\239\188\136\232\166\134\231\155\150\229\164\167\233\131\168\229\136\134\231\137\185\230\128\167\239\188\137",
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
        Description = "\229\144\141\231\167\176\239\188\136\232\135\170\229\174\154\228\185\137\232\167\132\229\136\153\239\188\137"
      },
      {
        Name = "FloatValue",
        Type = RTTIBase.FieldType.FLOAT,
        Default = 0.0,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.LIMIT_VALUE,
            Ranges = {
              {Min = 0.0, Max = 100.0}
            }
          }
        },
        Description = "\230\181\174\231\130\185\230\149\176\239\188\136vl \229\143\150\229\128\188\231\186\166\230\157\159\239\188\137"
      },
      {
        Name = "EnumValue",
        Type = RTTIBase.FieldType.ENUM,
        Default = 1,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ENUM,
            EnumName = "TestEnum"
          }
        },
        Description = "\230\158\154\228\184\190\229\173\151\230\174\181"
      },
      {
        Name = "StructValue",
        Type = RTTIBase.FieldType.STRUCT,
        Default = {},
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = "TestElementType2"
          }
        },
        Description = "\231\187\147\230\158\132\229\173\151\230\174\181"
      },
      {
        Name = "ArrayValue",
        Type = RTTIBase.FieldType.ARRAY,
        Default = {},
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.STRUCT,
            Size = 3
          },
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = "TestElementType1"
          }
        },
        Description = "\231\187\147\230\158\132\230\149\176\231\187\132\229\173\151\230\174\181"
      },
      {
        Name = "ForeignId",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.FOREIGN_KEY,
            TypeName = "ForeignTypeA",
            FieldName = "Id"
          }
        },
        Description = "\229\164\150\233\148\174\229\173\151\230\174\181"
      },
      {
        Name = "RefType",
        Type = RTTIBase.FieldType.STRING,
        Default = "A",
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = "\230\157\161\228\187\182\229\164\150\233\148\174\233\169\177\229\138\168\229\173\151\230\174\181"
      },
      {
        Name = "RefId",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.CONDITION_KEY,
            DriverField = "RefType",
            Branches = {
              {
                Value = "A",
                TypeName = "ForeignTypeA",
                FieldName = "Id"
              },
              {
                Value = "B",
                TypeName = "ForeignTypeB",
                FieldName = "Id"
              }
            }
          }
        },
        Description = "\230\157\161\228\187\182\229\164\150\233\148\174\229\173\151\230\174\181"
      },
      {
        Name = "Comment",
        Type = RTTIBase.FieldType.STRING,
        Default = "",
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = "\229\174\137\229\133\168\230\181\139\232\175\149\229\173\151\230\174\181"
      }
    }
  }
  local SecurityType = {
    Name = "SecurityType",
    Version = 1,
    Description = "\229\174\137\229\133\168\233\170\140\232\175\129\228\184\147\231\148\168\231\177\187\229\158\139",
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
        Name = "Text",
        Type = RTTIBase.FieldType.STRING,
        Default = "",
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Constraints = {},
        Description = "\230\150\135\230\156\172"
      }
    }
  }
  self:AssertTrue(true == RTTIManager:RegisterType(TestElementType1.Name, TestElementType1), "\230\179\168\229\134\140TestElementType1\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(TestElementType2.Name, TestElementType2), "\230\179\168\229\134\140TestElementType2\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(ForeignTypeA.Name, ForeignTypeA), "\230\179\168\229\134\140ForeignTypeA\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(ForeignTypeB.Name, ForeignTypeB), "\230\179\168\229\134\140ForeignTypeB\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(TestDataType.Name, TestDataType), "\230\179\168\229\134\140TestDataType\229\164\177\232\180\165")
  self:AssertTrue(true == RTTIManager:RegisterType(SecurityType.Name, SecurityType), "\230\179\168\229\134\140SecurityType\229\164\177\232\180\165")
end

return AbstractTestCase

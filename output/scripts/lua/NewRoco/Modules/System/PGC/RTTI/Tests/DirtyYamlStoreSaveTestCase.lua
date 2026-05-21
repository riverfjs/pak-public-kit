local AbstractTestCase = require("NewRoco.Modules.System.PGC.RTTI.Tests.AbstractTestCase")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local RTTIYamlStore = require("NewRoco.Modules.System.PGC.RTTI.RTTIYamlStore")
local DirtyYamlStoreSaveTestCase = AbstractTestCase:Extend("DirtyYamlStoreSaveTestCase")

local function ReadTextFile(Path)
  local File = io.open(Path, "r")
  if not File then
    return nil
  end
  local Content = File:read("*a")
  File:close()
  return Content
end

local function WriteTextFile(Path, Content)
  local File = io.open(Path, "w")
  if not File then
    return false
  end
  File:write(Content)
  File:close()
  return true
end

local function CountSubstring(Text, Sub)
  if type(Text) ~= "string" or type(Sub) ~= "string" or "" == Sub then
    return 0
  end
  local _, Count = Text:gsub(Sub, "")
  return Count
end

local function AssertNotStringContains(self, Text, Sub, Message)
  self:AssertType(Sub, "string")
  self:AssertType(Text, "string", Message or "\230\150\135\230\156\172\229\191\133\233\161\187\228\184\186string")
  self:AssertTrue(string.find(Text, Sub, 1, true) == nil, Message or "\230\150\135\230\156\172\228\184\141\229\186\148\229\140\133\229\144\171\229\173\144\228\184\178: " .. Sub)
end

local function BuildTestTypeDefine(TypeName)
  return {
    Name = TypeName,
    Version = 1,
    Description = "\231\148\168\228\186\142\230\181\139\232\175\149 RTTIYamlStore CRUD \228\184\142 SaveDirtyBucket \232\144\189\231\155\152\231\154\132\231\177\187\229\158\139",
    Metadata = {},
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
      },
      {
        Name = "Count",
        Type = RTTIBase.FieldType.UINT32,
        Default = 0,
        Scope = RTTIBase.ScopeType.Both,
        Required = true,
        Description = "\232\174\161\230\149\176"
      }
    }
  }
end

function DirtyYamlStoreSaveTestCase:Ctor()
  self.Name = "YAML\229\134\153\229\155\158\239\188\154\229\162\158/\229\136\160/\230\148\185 + SaveDirtyBucket"
  self.Description = "\232\166\134\231\155\150 RTTIYamlStore \229\175\185 YAML \231\154\132\229\162\158/\229\136\160/\230\148\185\239\188\140\228\187\165\229\143\138 SaveDirtyBucket \231\154\132\231\156\159\229\174\158\232\144\189\231\155\152\228\184\142\230\184\133\230\161\182"
  self.YamlPaths = {}
end

function DirtyYamlStoreSaveTestCase:AfterEach()
  if type(self.YamlPaths) == "table" then
    for _, Path in ipairs(self.YamlPaths) do
      pcall(os.remove, Path)
    end
  end
  self.YamlPaths = {}
end

function DirtyYamlStoreSaveTestCase:OnExecute()
  local ProjectDir = UE.UBlueprintPathsLibrary.ProjectDir()
  local YamlRootDir = "Content/Script/NewRoco/Modules/System/PGC/RTTI/Tests/"
  self:ResetRTTIEnvironment({
    Core = {StrictMode = true},
    Reflection = {EnablePropertyCache = false, YamlRootDir = YamlRootDir},
    Statistics = {EnableCollection = true, ReportInterval = 0}
  })
  local CrudTypeName = "DirtyYamlStoreCrudType"
  self:AssertTrue(RTTIManager:RegisterType(CrudTypeName, BuildTestTypeDefine(CrudTypeName)))
  local CrudYamlPath = string.format("%s%s%s.yaml", ProjectDir, YamlRootDir, CrudTypeName)
  table.insert(self.YamlPaths, CrudYamlPath)
  self:AssertTrue(WriteTextFile(CrudYamlPath, [[
header: {}
body:]]), "\229\136\155\229\187\186 YAML \230\181\139\232\175\149\230\150\135\228\187\182\229\164\177\232\180\165\239\188\154" .. tostring(CrudYamlPath))
  self:AssertNotNil(RTTIYamlStore.ResolveYamlFilePath(CrudTypeName), "ResolveYamlFilePath \229\186\148\232\131\189\230\137\190\229\136\176 CRUD \230\181\139\232\175\149 YAML \230\150\135\228\187\182")
  local Insert1 = {
    Id = 1,
    Name = "Beta",
    Count = 42
  }
  self:AssertTrue(RTTIYamlStore:InsertRecord(CrudTypeName, Insert1))
  local Content1 = ReadTextFile(CrudYamlPath)
  self:AssertType(Content1, "string")
  self:AssertStringContains(Content1, "body:")
  self:AssertEquals(1, CountSubstring(Content1, "- !Row"), "InsertRecord \229\186\148\230\150\176\229\162\158 1 \230\157\161 Row")
  self:AssertStringContains(Content1, "    Id: 1")
  self:AssertStringContains(Content1, "    Name: Beta")
  self:AssertStringContains(Content1, "    Count: 42")
  local Content1Snap = Content1
  self:AssertFalse(RTTIYamlStore:InsertRecord(CrudTypeName, Insert1), "\233\135\141\229\164\141 Insert \229\144\140\228\184\187\233\148\174\229\186\148\229\164\177\232\180\165")
  local Content1AfterDupInsert = ReadTextFile(CrudYamlPath)
  self:AssertEquals(Content1Snap, Content1AfterDupInsert, "\233\135\141\229\164\141 Insert \229\164\177\232\180\165\230\151\182\228\184\141\229\186\148\230\148\185\229\138\168\230\150\135\228\187\182")
  local Update1 = {
    Id = 1,
    Name = "Beta",
    Count = 43
  }
  self:AssertTrue(RTTIYamlStore:ModifyRecord(CrudTypeName, Update1))
  local Content2 = ReadTextFile(CrudYamlPath)
  self:AssertType(Content2, "string")
  self:AssertEquals(1, CountSubstring(Content2, "- !Row"), "ModifyRecord \229\186\148\229\164\141\231\148\168\229\144\140\228\184\128\230\157\161 Row")
  self:AssertStringContains(Content2, "    Count: 43")
  local UpdateNotExisted = {
    Id = 2,
    Name = "Gamma",
    Count = 1
  }
  self:AssertFalse(RTTIYamlStore:ModifyRecord(CrudTypeName, UpdateNotExisted), "Update \228\184\141\229\173\152\229\156\168\228\184\187\233\148\174\229\186\148\229\164\177\232\180\165")
  local Insert2 = {
    Id = 2,
    Name = "Gamma",
    Count = 1
  }
  self:AssertTrue(RTTIYamlStore:InsertRecord(CrudTypeName, Insert2))
  local Content3Any = ReadTextFile(CrudYamlPath)
  self:AssertType(Content3Any, "string")
  local Content3 = Content3Any
  self:AssertEquals(2, CountSubstring(Content3, "- !Row"), "\231\172\172\228\186\140\230\172\161 InsertRecord \229\186\148\230\150\176\229\162\158\229\136\176 2 \230\157\161 Row")
  self:AssertStringContains(Content3, "    Id: 2")
  self:AssertStringContains(Content3, "    Name: Gamma")
  self:AssertTrue(RTTIYamlStore:DeleteRecord(CrudTypeName, 1))
  local Content4 = ReadTextFile(CrudYamlPath)
  self:AssertType(Content4, "string")
  self:AssertEquals(1, CountSubstring(Content4, "- !Row"), "DeleteRecord \229\186\148\229\136\160\233\153\164 1 \230\157\161 Row")
  AssertNotStringContains(self, Content4, "    Id: 1", "\229\136\160\233\153\164\229\144\142\228\184\141\229\186\148\229\140\133\229\144\171 Id=1 \231\154\132 Row")
  self:AssertStringContains(Content4, "    Id: 2")
  self:AssertFalse(RTTIYamlStore:DeleteRecord(CrudTypeName, 1), "Delete \228\184\141\229\173\152\229\156\168\228\184\187\233\148\174\229\186\148\229\164\177\232\180\165")
  local SaveTypeName = "DirtyYamlSavableType"
  self:AssertTrue(RTTIManager:RegisterType(SaveTypeName, BuildTestTypeDefine(SaveTypeName)))
  local SaveYamlPath = string.format("%s%s%s.yaml", ProjectDir, YamlRootDir, SaveTypeName)
  table.insert(self.YamlPaths, SaveYamlPath)
  self:AssertTrue(WriteTextFile(SaveYamlPath, [[
header: {}
body:]]), "\229\136\155\229\187\186 YAML \230\181\139\232\175\149\230\150\135\228\187\182\229\164\177\232\180\165\239\188\154" .. tostring(SaveYamlPath))
  self:AssertNotNil(RTTIYamlStore.ResolveYamlFilePath(SaveTypeName), "ResolveYamlFilePath \229\186\148\232\131\189\230\137\190\229\136\176 SaveDirtyBucket \230\181\139\232\175\149 YAML \230\150\135\228\187\182")
  local DataAny = RTTIManager:CreateInstance(SaveTypeName)
  self:AssertType(DataAny, "table")
  local Data = assert(DataAny)
  self:AssertTrue(RTTIManager:SetProperty(SaveTypeName, Data, "Name", "Beta"))
  self:AssertTrue(RTTIManager:SetProperty(SaveTypeName, Data, "Count", 42))
  local SaveResult1 = RTTIManager:SaveDirtyBucket(SaveTypeName, false)
  self:AssertType(SaveResult1, "table")
  self:AssertEquals(1, SaveResult1.TotalCount)
  self:AssertTrue(true == SaveResult1.Success)
  self:AssertEquals(1, SaveResult1.SuccessCount)
  self:AssertEquals(0, SaveResult1.FailCount)
  local SaveContent1 = ReadTextFile(SaveYamlPath)
  self:AssertType(SaveContent1, "string", "\228\191\157\229\173\152\229\144\142\229\186\148\232\131\189\232\175\187\229\136\176 YAML \229\134\133\229\174\185")
  self:AssertStringContains(SaveContent1, "body:")
  self:AssertEquals(1, CountSubstring(SaveContent1, "- !Row"), "\233\166\150\230\172\161\228\191\157\229\173\152\229\186\148\229\143\170\229\134\153\229\133\165 1 \230\157\161 Row")
  self:AssertStringContains(SaveContent1, "    Id: 1")
  self:AssertStringContains(SaveContent1, "    Name: Beta")
  self:AssertStringContains(SaveContent1, "    Count: 42")
  local SaveResult2 = RTTIManager:SaveDirtyBucket(SaveTypeName, false)
  self:AssertEquals(0, SaveResult2.TotalCount)
  local SaveContent2 = ReadTextFile(SaveYamlPath)
  self:AssertEquals(SaveContent1, SaveContent2, "\232\132\143\230\161\182\228\184\186\231\169\186\230\151\182\239\188\140SaveDirtyBucket \228\184\141\229\186\148\230\148\185\229\138\168\230\150\135\228\187\182")
  self:AssertTrue(RTTIManager:SetProperty(SaveTypeName, Data, "Count", 43))
  local SaveResult3 = RTTIManager:SaveDirtyBucket(SaveTypeName, false)
  self:AssertEquals(1, SaveResult3.TotalCount)
  self:AssertTrue(true == SaveResult3.Success)
  local SaveContent3 = ReadTextFile(SaveYamlPath)
  self:AssertType(SaveContent3, "string")
  self:AssertEquals(1, CountSubstring(SaveContent3, "- !Row"), "\230\155\180\230\150\176\229\186\148\229\164\141\231\148\168\229\144\140\228\184\128\230\157\161 Row\239\188\140\228\184\141\229\186\148\230\150\176\229\162\158")
  self:AssertStringContains(SaveContent3, "    Count: 43")
  local PointTypeName = "DirtyYamlStoreComplex_Point"
  self:AssertTrue(RTTIManager:RegisterType(PointTypeName, {
    Name = PointTypeName,
    Version = 1,
    Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
    Metadata = {},
    Fields = {
      {
        Name = "X",
        Type = RTTIBase.FieldType.UINT32,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = ""
      },
      {
        Name = "Y",
        Type = RTTIBase.FieldType.UINT32,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = ""
      }
    }
  }))
  local SubMetaTypeName = "DirtyYamlStoreComplex_SubMeta"
  self:AssertTrue(RTTIManager:RegisterType(SubMetaTypeName, {
    Name = SubMetaTypeName,
    Version = 1,
    Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
    Metadata = {},
    Fields = {
      {
        Name = "Level",
        Type = RTTIBase.FieldType.INT32,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = ""
      },
      {
        Name = "Ids",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.UINT32
          }
        },
        Description = ""
      }
    }
  }))
  local MetaTypeName = "DirtyYamlStoreComplex_Meta"
  self:AssertTrue(RTTIManager:RegisterType(MetaTypeName, {
    Name = MetaTypeName,
    Version = 1,
    Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
    Metadata = {},
    Fields = {
      {
        Name = "Enabled",
        Type = RTTIBase.FieldType.BOOL,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = ""
      },
      {
        Name = "Notes",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.STRING
          }
        },
        Description = ""
      },
      {
        Name = "Sub",
        Type = RTTIBase.FieldType.STRUCT,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = SubMetaTypeName
          }
        },
        Description = ""
      }
    }
  }))
  local MemberTypeName = "DirtyYamlStoreComplex_Member"
  self:AssertTrue(RTTIManager:RegisterType(MemberTypeName, {
    Name = MemberTypeName,
    Version = 1,
    Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
    Metadata = {},
    Fields = {
      {
        Name = "Uid",
        Type = RTTIBase.FieldType.UINT32,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = ""
      },
      {
        Name = "Scores",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.INT32
          }
        },
        Description = ""
      }
    }
  }))
  local GroupTypeName = "DirtyYamlStoreComplex_Group"
  self:AssertTrue(RTTIManager:RegisterType(GroupTypeName, {
    Name = GroupTypeName,
    Version = 1,
    Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
    Metadata = {},
    Fields = {
      {
        Name = "GroupId",
        Type = RTTIBase.FieldType.UINT32,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {},
        Description = ""
      },
      {
        Name = "Members",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.STRUCT
          },
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = MemberTypeName
          }
        },
        Description = ""
      }
    }
  }))
  local ComplexTypeName = "DirtyYamlStoreComplexType"
  self:AssertTrue(RTTIManager:RegisterType(ComplexTypeName, {
    Name = ComplexTypeName,
    Version = 1,
    Description = "\231\148\168\228\186\142\230\181\139\232\175\149\230\149\176\231\187\132/\231\187\147\230\158\132\228\189\147\229\181\140\229\165\151\229\134\153\229\155\158\231\154\132\231\177\187\229\158\139",
    Metadata = {},
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
        Name = "Tags",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.STRING
          }
        },
        Description = "\230\149\176\231\187\132<string>"
      },
      {
        Name = "Points",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.STRUCT,
            Size = 5
          },
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = PointTypeName
          }
        },
        Description = "\230\149\176\231\187\132<\231\187\147\230\158\132\228\189\147>"
      },
      {
        Name = "Meta",
        Type = RTTIBase.FieldType.STRUCT,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = MetaTypeName
          }
        },
        Description = "\231\187\147\230\158\132\228\189\147(\229\134\133\229\144\171\231\187\147\230\158\132\228\189\147+\230\149\176\231\187\132)"
      },
      {
        Name = "Groups",
        Type = RTTIBase.FieldType.ARRAY,
        Scope = RTTIBase.ScopeType.Both,
        Required = false,
        Constraints = {
          {
            Type = RTTIBase.ConstraintType.ARRAY,
            ElementType = RTTIBase.FieldType.STRUCT
          },
          {
            Type = RTTIBase.ConstraintType.TYPE,
            TypeName = GroupTypeName
          }
        },
        Description = "\230\149\176\231\187\132<\231\187\147\230\158\132\228\189\147(\229\134\133\229\144\171\230\149\176\231\187\132<\231\187\147\230\158\132\228\189\147>)>"
      }
    }
  }))
  local ComplexYamlPath = string.format("%s%s%s.yaml", ProjectDir, YamlRootDir, ComplexTypeName)
  table.insert(self.YamlPaths, ComplexYamlPath)
  self:AssertTrue(WriteTextFile(ComplexYamlPath, [[
header: {}
body:]]), "\229\136\155\229\187\186 YAML \230\181\139\232\175\149\230\150\135\228\187\182\229\164\177\232\180\165\239\188\154" .. tostring(ComplexYamlPath))
  self:AssertNotNil(RTTIYamlStore.ResolveYamlFilePath(ComplexTypeName), "ResolveYamlFilePath \229\186\148\232\131\189\230\137\190\229\136\176 Complex \230\181\139\232\175\149 YAML \230\150\135\228\187\182")
  local ComplexData = {
    Id = 1,
    Tags = {"alpha", "beta"},
    Points = {
      {X = 1, Y = 2},
      {X = 3, Y = 4}
    },
    Meta = {
      Enabled = true,
      Notes = {"n1", "n2"},
      Sub = {
        Level = 2,
        Ids = {7, 8}
      }
    },
    Groups = {
      {
        GroupId = 10,
        Members = {
          {
            Uid = 100,
            Scores = {1, 2}
          },
          {
            Uid = 200,
            Scores = {}
          }
        }
      }
    }
  }
  self:AssertTrue(RTTIYamlStore:InsertRecord(ComplexTypeName, ComplexData))
  local ComplexContent = ReadTextFile(ComplexYamlPath)
  self:AssertType(ComplexContent, "string")
  self:AssertStringContains(ComplexContent, "body:")
  self:AssertEquals(1, CountSubstring(ComplexContent, "- !Row"), "\229\164\141\230\157\130\231\177\187\229\158\139 InsertRecord \229\186\148\229\134\153\229\133\165 1 \230\157\161 Row")
  self:AssertStringContains(ComplexContent, "Tags:")
  self:AssertStringContains(ComplexContent, "- alpha")
  self:AssertStringContains(ComplexContent, "- beta")
  self:AssertStringContains(ComplexContent, "Points:")
  self:AssertStringContains(ComplexContent, "X: 1")
  self:AssertStringContains(ComplexContent, "Y: 2")
  self:AssertStringContains(ComplexContent, "Meta:")
  self:AssertStringContains(ComplexContent, "Enabled: true")
  self:AssertStringContains(ComplexContent, "Notes:")
  self:AssertStringContains(ComplexContent, "- n1")
  self:AssertStringContains(ComplexContent, "Sub:")
  self:AssertStringContains(ComplexContent, "Level: 2")
  self:AssertStringContains(ComplexContent, "Ids:")
  self:AssertStringContains(ComplexContent, "- 7")
  self:AssertStringContains(ComplexContent, "Groups:")
  self:AssertStringContains(ComplexContent, "GroupId: 10")
  self:AssertStringContains(ComplexContent, "Members:")
  self:AssertStringContains(ComplexContent, "Uid: 100")
  self:AssertStringContains(ComplexContent, "Scores:")
  self:AssertStringContains(ComplexContent, "Scores: []")
end

return DirtyYamlStoreSaveTestCase

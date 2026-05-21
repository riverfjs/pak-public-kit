local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PETFREE_CONF = {
  Name = "PETFREE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PETFREE_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "ID"
    },
    {
      Name = "petfree_sort",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\148\190\231\148\159\229\165\150\229\138\177\231\177\187ID"
    },
    {
      Name = "level_low",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\231\173\137\231\186\167\228\184\139\233\153\144"
    },
    {
      Name = "level_high",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\231\173\137\231\186\167\228\184\138\233\153\144"
    },
    {
      Name = "star_low",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\230\136\144\233\149\191\230\152\159\231\186\167\228\184\139\233\153\144"
    },
    {
      Name = "star_high",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\230\136\144\233\149\191\230\152\159\231\186\167\228\184\138\233\153\144"
    },
    {
      Name = "reward",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\148\190\231\148\159reward_id"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    }
  }
}
RTTIManager:RegisterType(PETFREE_CONF.Name, PETFREE_CONF)

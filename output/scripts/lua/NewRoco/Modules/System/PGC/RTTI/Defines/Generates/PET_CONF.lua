local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_CONF = {
  Name = "PET_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_CONF.yaml",
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
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 2000001, Max = 99999999}
          }
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "petname"
        }
      },
      Description = "\231\178\190\231\129\181\229\144\141\231\167\176"
    },
    {
      Name = "base_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132petbase_id"
    },
    {
      Name = "is_task_reward",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\228\187\187\229\138\161\232\138\130\229\165\150\229\138\177\231\178\190\231\129\181"
    },
    {
      Name = "release_forbidden",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\166\129\230\173\162\230\148\190\231\148\159"
    },
    {
      Name = "mark_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetPartnerMarkType"
        }
      },
      Description = "\230\137\128\230\144\186\229\184\166\231\154\132\228\188\153\228\188\180\230\160\135\232\174\176\239\188\136\231\149\153\231\169\186\228\184\141\229\184\166\228\187\187\228\189\149\230\160\135\232\174\176\239\188\137"
    },
    {
      Name = "mark_start_task",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\187\187\229\138\161\231\137\185\230\174\138\231\178\190\231\129\181\229\143\145\230\148\190\232\181\183\229\167\139"
    },
    {
      Name = "buff_icon_offset_z",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "buff\230\160\143z\232\189\180\229\129\143\231\167\187\233\135\143"
    },
    {
      Name = "pet_info_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\229\174\154\229\136\182\229\177\158\230\128\167ID"
    },
    {
      Name = "pet_egg_npc_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\232\155\139\231\154\132npc id\239\188\136\232\155\139\230\168\161\229\158\139\231\130\171\229\189\169\230\157\144\232\180\168\230\152\190\231\164\186\233\156\128\232\166\129"
    },
    {
      Name = "is_egg",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\231\178\190\231\129\181\232\155\139"
    }
  }
}
RTTIManager:RegisterType(PET_CONF.Name, PET_CONF)

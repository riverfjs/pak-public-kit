local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local LEVEL_SKILL_CONF = {
  Name = "LEVEL_SKILL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/LEVEL_SKILL_CONF.yaml",
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
      Description = "\229\174\160\231\137\169ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168\239\188\154\230\175\143\228\184\128\232\161\140\233\156\128\232\166\129\229\174\140\230\149\180\229\161\171\229\134\153\230\149\180\228\184\170\232\191\155\229\140\150\233\147\190\228\184\138\229\143\175\232\142\183\229\190\151\231\154\132\229\133\168\233\131\168\230\138\128\232\131\189"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 40
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "LEVEL_SKILL_CONF_level"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "machine_skill_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 225
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "LEVEL_SKILL_CONF_machine_skill_group"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "blood_skill_level_point",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\231\173\137\231\186\167"
    },
    {
      Name = "blood_skill_COMMON",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\153\174\233\128\154\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_GRASS",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\141\137\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_FIRE",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\129\171\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_WATER",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\176\180\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_LIGHT",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\133\137\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_STONE",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\176\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_ICE",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\134\176\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_DRAGON",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\190\153\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_ELECTRIC",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\148\181\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_TOXIC",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\175\146\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_INSECT",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\153\171\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_FIGHT",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\173\166\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_WING",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\191\188\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_MOE",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\144\140\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_GHOST",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\185\189\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_DEMON",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\129\182\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_MECHANIC",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\156\186\230\162\176\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "blood_skill_PHANTOM",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\185\187\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "legendary_skill",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\188\130\230\160\184\230\138\128\232\131\189id"
    },
    {
      Name = "legendary_skill_condition",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\230\160\184\230\138\128\232\131\189\232\167\163\233\148\129\230\157\161\228\187\182(petbase\232\161\168\231\154\132id\239\188\137"
    }
  }
}
RTTIManager:RegisterType(LEVEL_SKILL_CONF.Name, LEVEL_SKILL_CONF)

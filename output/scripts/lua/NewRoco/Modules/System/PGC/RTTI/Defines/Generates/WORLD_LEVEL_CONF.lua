local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local WORLD_LEVEL_CONF = {
  Name = "WORLD_LEVEL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "role/WORLD_LEVEL_CONF.yaml",
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
      Name = "world_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "WORLD_LEVEL_CONF",
          FieldName = "world_level"
        }
      },
      Description = "\233\173\148\230\179\149\230\152\159\233\152\182"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "title"
        }
      },
      Description = "\231\167\176\229\143\183"
    },
    {
      Name = "update_grade_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        }
      },
      Description = "\233\173\148\230\179\149\231\173\137\231\186\167\232\190\190\229\136\176\229\135\160\231\186\167\229\143\175\230\142\165\229\143\150\231\170\129\231\160\180\228\187\187\229\138\161"
    },
    {
      Name = "update_task_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\170\129\231\160\180\228\187\187\229\138\161"
    },
    {
      Name = "is_auto_accept_task",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\135\170\229\138\168\230\142\165\229\143\150\229\189\162\229\188\143"
    },
    {
      Name = "not_broadcast_tips",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\230\146\173\231\170\129\231\160\180\229\188\128\229\167\139\231\154\132\230\143\144\231\164\186(\228\184\186CE\231\137\136\230\156\172\231\137\185\230\174\138\229\164\132\231\144\134)"
    },
    {
      Name = "pet_top_level",
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
      Description = "\231\178\190\231\129\181\229\144\172\232\175\157\231\173\137\231\186\167\228\184\138\233\153\144"
    },
    {
      Name = "pet_level_limit",
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
      Description = "\230\152\159\233\152\182\231\173\137\231\186\167\229\175\185\229\186\148\231\154\132\231\178\190\231\129\181\231\173\137\231\186\167\228\184\138\233\153\144"
    },
    {
      Name = "pet_team_quantity",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\231\188\150\233\152\159\230\149\176\233\135\143"
    },
    {
      Name = "pet_bag_space_quantity",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\143\232\186\171\232\131\140\229\140\133\231\169\186\228\189\141\230\149\176\233\135\143"
    },
    {
      Name = "pet_settled_basic_amplify",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\138\230\138\165\230\151\182\239\188\140\231\178\190\231\129\181\229\141\149\228\187\183\230\148\190\229\164\167\229\128\141\231\142\135"
    },
    {
      Name = "world_level_reward_show",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\139\229\141\135list\228\184\138\233\162\132\232\167\136\231\154\132\229\165\150\229\138\177\239\188\136\229\143\170\230\152\175\233\162\132\232\167\136\239\188\140\229\174\158\233\153\133\229\165\150\229\138\177\229\143\145\230\148\190\230\152\175\233\128\154\232\191\135\228\187\187\229\138\161\239\188\137"
    },
    {
      Name = "promote_desc",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "WORLD_LEVEL_CONF_promote_desc"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "update_task_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\159\233\152\182\228\187\187\229\138\161\228\184\128\229\143\165\232\175\157\230\143\143\232\191\176"
    },
    {
      Name = "revival_desc",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "WORLD_LEVEL_CONF_revival_desc"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "reward",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "WORLD_LEVEL_CONF_reward"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "level_reward_show",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\139\231\186\167\228\187\187\229\138\161\229\165\150\229\138\177\229\177\149\231\164\186"
    },
    {
      Name = "team_battle",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 3
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "WORLD_LEVEL_CONF_team_battle"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "daily_task_reward",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\141\229\144\140\233\173\148\230\179\149\231\173\137\231\186\167\228\184\139\230\175\143\230\151\165\232\176\131\230\159\165\231\154\132\229\165\150\229\138\177"
    }
  }
}
RTTIManager:RegisterType(WORLD_LEVEL_CONF.Name, WORLD_LEVEL_CONF)

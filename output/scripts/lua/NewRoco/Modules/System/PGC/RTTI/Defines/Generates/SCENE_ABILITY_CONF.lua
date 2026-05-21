local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_ABILITY_CONF = {
  Name = "SCENE_ABILITY_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/SCENE_ABILITY_CONF.yaml",
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
      Description = "\229\156\186\230\153\175\230\138\128\232\131\189id\239\188\1361300001~1330000\239\188\137"
    },
    {
      Name = "ability_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "sceneabilityname"
        }
      },
      Description = "\230\138\128\232\131\189\229\144\141\231\167\176"
    },
    {
      Name = "skill_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189ID(\229\175\185\229\186\148Skill\232\161\168\228\184\173\231\154\132ID,\231\148\168\228\186\142\232\161\168\230\188\148)"
    },
    {
      Name = "skill_bp_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189\232\147\157\229\155\190\232\183\175\229\190\132\239\188\136\231\148\168\228\186\142\233\128\187\232\190\145\239\188\137"
    },
    {
      Name = "skill_lua_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189lua\232\132\154\230\156\172\239\188\136\231\148\168\228\186\142\233\128\187\232\190\145\239\188\140\230\178\161\230\156\137\233\133\141\231\189\174\232\147\157\229\155\190\232\183\175\229\190\132\230\151\182\231\155\180\230\142\165\228\189\191\231\148\168lua\232\132\154\230\156\172\239\188\140\228\188\152\229\133\136\228\189\191\231\148\168\232\147\157\229\155\190\232\183\175\229\190\132\239\188\137"
    },
    {
      Name = "ability_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189\229\155\190\230\160\135\232\183\175\229\190\132"
    },
    {
      Name = "ability_block_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\166\129\231\148\168\229\155\190\230\160\135\232\183\175\229\190\132"
    },
    {
      Name = "ability_press_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\137\229\142\139\229\155\190\230\160\135\232\183\175\229\190\132"
    },
    {
      Name = "ability_insufficient_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\133\141\231\189\174\230\157\144\230\150\153\228\184\141\232\182\179\230\151\182\231\154\132\229\155\190\230\160\135\232\183\175\229\190\132"
    },
    {
      Name = "scene_ability_slot_cast_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneAbilitySlotCastType"
        }
      },
      Description = "\230\138\128\232\131\189\230\140\137\233\146\174\232\167\166\229\143\145\231\177\187\229\158\139"
    },
    {
      Name = "cooldown_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneAbilityCooldownType"
        }
      },
      Description = "\229\134\183\229\141\180\231\177\187\229\158\139"
    },
    {
      Name = "cooldown",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\183\229\141\180\230\151\182\233\151\180"
    },
    {
      Name = "scene_ability_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneAbilityType"
        }
      },
      Description = "\230\138\128\232\131\189\231\177\187\229\158\139"
    },
    {
      Name = "scene_ability_type_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "scene_ability_type",
          Branches = {
            {
              Value = 0,
              TypeName = "SCENE_ABILITY_RIDING_CONF",
              FieldName = "id"
            },
            {
              Value = 1,
              TypeName = "SCENE_ABILITY_DASH_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "SCENE_ABILITY_FLYING_CONF",
              FieldName = "id"
            },
            {
              Value = 5,
              TypeName = "SCENE_ABILITY_ASCENDING_CONF",
              FieldName = "id"
            },
            {
              Value = 6,
              TypeName = "SCENE_ABILITY_SLIDING_CONF",
              FieldName = "id"
            },
            {
              Value = 7,
              TypeName = "SCENE_ABILITY_THROW_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\138\128\232\131\189\231\177\187\229\158\139id"
    },
    {
      Name = "priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189\228\188\152\229\133\136\231\186\167\239\188\140\228\188\152\229\133\136\231\186\167\233\171\152\231\154\132\229\143\175\228\187\165\230\137\147\230\150\173\228\188\152\229\133\136\231\186\167\228\189\142\231\154\132"
    },
    {
      Name = "is_passive",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\162\171\229\138\168"
    },
    {
      Name = "add_status",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldPlayerStatusType"
        }
      },
      Description = "\230\183\187\229\138\160\231\154\132\231\138\182\230\128\129"
    },
    {
      Name = "add_sub_status",
      Type = RTTIBase.FieldType.UINT32,
      Default = 0,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\183\187\229\138\160\231\154\132\229\173\144\231\138\182\230\128\129"
    },
    {
      Name = "remove_status",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldPlayerStatusType"
        }
      },
      Description = "\231\167\187\233\153\164\231\154\132\231\138\182\230\128\129"
    },
    {
      Name = "remove_sub_status",
      Type = RTTIBase.FieldType.UINT32,
      Default = 0,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\187\233\153\164\231\154\132\229\173\144\231\138\182\230\128\129"
    },
    {
      Name = "disable_env",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneAbilityDisableCode"
        }
      },
      Description = "\231\166\129\231\148\168\232\131\189\229\138\155\231\154\132\231\142\175\229\162\131\230\142\169\231\160\129"
    },
    {
      Name = "helper_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\190\133\229\138\169\232\132\154\230\156\172\232\183\175\229\190\132"
    }
  }
}
RTTIManager:RegisterType(SCENE_ABILITY_CONF.Name, SCENE_ABILITY_CONF)

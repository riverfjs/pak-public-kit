local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SKILL_CONF = {
  Name = "SKILL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "skill/SKILL_CONF.yaml",
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
      Description = "\230\138\128\232\131\189ID\239\188\140ID\230\174\181700000~799999\239\188\140799901~799999\228\184\186\231\137\185\230\174\138\229\138\159\232\131\189\231\148\168\239\188\140\229\139\191\229\141\160\231\148\168\239\188\140\231\148\168\228\186\142\231\190\142\230\156\175\232\181\132\230\186\144ID\232\167\132\232\140\131"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "name"
        }
      },
      Description = "\230\138\128\232\131\189\229\144\141\231\167\176"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "desc"
        }
      },
      Description = "\230\138\128\232\131\189\230\143\143\232\191\176"
    },
    {
      Name = "flavor_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "flavor_text"
        }
      },
      Description = "\232\183\159\229\156\168\230\138\128\232\131\189\230\143\143\232\191\176\229\144\142\233\157\162\231\154\132\233\163\142\229\145\179\230\150\135\229\173\151"
    },
    {
      Name = "energy_rule",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ChangeRule"
        }
      },
      Description = "\232\131\189\233\135\143\232\167\132\229\136\153"
    },
    {
      Name = "energy_cost",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\131\189\233\135\143\230\182\136\232\128\151"
    },
    {
      Name = "dam_para",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\138\128\232\131\189\229\168\129\229\138\155"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillActiveType"
        }
      },
      Description = "\230\138\128\232\131\189\231\177\187\229\158\139 1=\228\184\187\229\138\168\230\138\128\232\131\189NORMAL 2=\232\162\171\229\138\168\230\138\128\232\131\189\239\188\140\229\133\165\229\156\186\230\151\182\228\189\191\231\148\168\231\154\132\227\128\130FEATURE 3=\229\191\133\230\157\128\230\138\128\232\131\189ULTIMATE 4=\229\133\168\229\177\128\230\160\188\230\140\161\230\138\128\232\131\189GLOBAL 5=\233\135\142\230\128\170\228\184\147\229\177\158\230\138\128\232\131\189MONSTER"
    },
    {
      Name = "Skill_Type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillType"
        }
      },
      Description = "\230\138\128\232\131\189\231\177\187\229\158\139 0=\231\169\186 1=\228\188\164\229\174\179\231\177\187\230\138\128\232\131\189ST_DAMAGE 2=\231\138\182\230\128\129\231\177\187\230\138\128\232\131\189ST_STATUS 3=\233\152\178\229\190\161\231\177\187\230\138\128\232\131\189ST_DEFEND"
    },
    {
      Name = "skill_dam_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillDamType"
        }
      },
      Description = "\230\138\128\232\131\189\231\179\187\229\136\171\239\188\1360~18\239\188\137"
    },
    {
      Name = "skill_feature",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillFilterTitleType"
        }
      },
      Description = "\230\138\128\232\131\189\230\160\135\231\173\190\231\177\187 0=\230\151\160 1=\231\137\185\230\128\167 2=\232\131\182\230\176\180 3=\230\173\163\229\144\145 4=\232\180\159\229\144\145"
    },
    {
      Name = "damage_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "DamageType"
        }
      },
      Description = "\230\138\128\232\131\189\228\188\164\229\174\179\231\177\187\229\158\139"
    },
    {
      Name = "contact_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillContactType"
        }
      },
      Description = "\230\138\128\232\131\189\230\142\165\232\167\166\231\177\187\229\158\139"
    },
    {
      Name = "skill_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "damage_rule",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ChangeRule"
        }
      },
      Description = "\229\168\129\229\138\155\232\167\132\229\136\153"
    },
    {
      Name = "target_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillTargetType"
        }
      },
      Description = "\230\138\128\232\131\189\231\155\174\230\160\135\231\177\187\229\158\139"
    },
    {
      Name = "target_count",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189\231\155\174\230\160\135\230\149\176\233\135\143"
    },
    {
      Name = "cd_round",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\134\183\229\141\180\229\155\158\229\144\136"
    },
    {
      Name = "hit_para",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\145\189\228\184\173\228\191\174\230\173\163\229\128\188"
    },
    {
      Name = "skill_result",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 6
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "SKILL_CONF_skill_result"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "res_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\132\230\186\144ID"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\135\232\181\132\230\186\144"
    },
    {
      Name = "field_belong",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "FieldBelongType"
        }
      },
      Description = "\231\155\174\230\160\135\229\138\191\232\131\189\233\152\181\232\144\165"
    },
    {
      Name = "target_field",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\155\174\230\160\135\229\138\191\232\131\189"
    },
    {
      Name = "field_skill",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\148\185\229\143\152\229\144\142\230\138\128\232\131\189"
    },
    {
      Name = "is_show",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\231\137\185\230\174\138\233\149\156\229\164\180"
    },
    {
      Name = "describe_type",
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
          EnumName = "SkillDescribeType"
        }
      },
      Description = "\230\138\128\232\131\189\230\143\143\232\191\176\231\177\187\229\158\139\239\188\136AI\231\173\155\233\128\137\228\189\191\231\148\168\239\188\137"
    },
    {
      Name = "env_ban",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\142\175\229\162\131\229\134\133\230\152\175\229\144\166\229\143\175\228\187\165\228\189\191\231\148\168 0=\228\184\141\233\153\144\229\136\182 1=\230\183\177\230\176\180\228\184\173\230\151\160\230\179\149\228\189\191\231\148\168"
    },
    {
      Name = "skill_time",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillTime"
        }
      },
      Description = "\229\133\177\233\184\163\233\173\148\230\179\149\228\189\191\231\148\168\230\151\182\233\151\180"
    },
    {
      Name = "target_blood_limit",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\133\177\233\184\163\233\173\148\230\179\149\232\161\128\232\132\137\232\166\129\230\177\130"
    },
    {
      Name = "worldbuff_res_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\230\138\128\232\131\189\232\181\132\230\186\144ID"
    },
    {
      Name = "can_changed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\229\144\136\230\179\149\230\138\128\232\131\189"
    },
    {
      Name = "common_type",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\231\188\150\232\190\145\229\153\168\231\148\168 \230\138\128\232\131\189\231\168\128\230\156\137\229\186\166"
    },
    {
      Name = "common_type_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\232\131\189\231\168\128\230\156\137\229\186\166\230\149\176\229\173\151\230\158\154\228\184\190"
    },
    {
      Name = "use_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\231\188\150\232\190\145\229\153\168\231\148\168 \230\138\128\232\131\189\229\136\134\231\177\187"
    },
    {
      Name = "is_showlens",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\162\228\189\147\230\136\152\228\184\173 \230\152\175\229\144\166\232\161\168\230\188\148\230\138\128\232\131\189\231\137\185\229\134\153\233\149\156\229\164\180\231\173\137\232\161\168\231\142\176"
    },
    {
      Name = "special_aoe",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\231\137\185\230\174\138AOE"
    },
    {
      Name = "resonance_sk_black_list",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\133\177\233\184\163buff\233\187\145\229\144\141\229\141\149\239\188\154"
    },
    {
      Name = "resonance_sk_black_list_feature",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\133\177\233\184\163buff\233\187\145\229\144\141\229\141\149\231\154\132\232\175\134\229\136\171\230\138\128\232\131\189"
    }
  }
}
RTTIManager:RegisterType(SKILL_CONF.Name, SKILL_CONF)

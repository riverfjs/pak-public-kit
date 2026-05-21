local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BALL_CONF = {
  Name = "BALL_CONF",
  Version = 1,
  Description = "\233\133\141\231\189\174\228\186\134\229\146\149\229\153\156\231\144\131\231\154\132\230\141\149\230\141\137\230\166\130\231\142\135\239\188\140\230\141\149\230\141\137\231\137\185\230\149\136\232\183\175\229\190\132\239\188\140\229\155\190\230\160\135\231\173\137\233\128\154\231\148\168\229\143\130\230\149\176",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ball/BALL_CONF.yaml",
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
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "ID\239\188\136\231\173\137\228\186\142\233\129\147\229\133\183id\239\188\137"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "model",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\232\181\132\230\186\144\239\188\136\230\156\137\231\148\168\239\188\137"
    },
    {
      Name = "trail_fx",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\139\150\229\176\190\231\137\185\230\149\136"
    },
    {
      Name = "fx_source",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MODEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\144\131\232\147\157\229\155\190\232\181\132\230\186\144"
    },
    {
      Name = "bigworld_catch",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\230\141\149\230\141\137\229\138\159\232\131\189\230\152\175\229\144\166\229\188\128\229\144\175"
    },
    {
      Name = "catch_not_give_peer",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\175\165\231\144\131\231\167\141\230\141\149\230\141\137\231\154\132\231\178\190\231\129\181\228\184\141\232\131\189\232\181\160\233\128\129\231\187\153\229\144\140\232\161\140\233\152\159\229\143\139\239\188\136true\228\184\186\228\184\141\232\131\189\239\188\137"
    },
    {
      Name = "solid_ball_act",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\174\158\229\191\131\231\144\131\230\137\139\230\132\159\230\168\161\230\157\191"
    },
    {
      Name = "ball_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\144\131\231\167\141\230\166\130\231\142\135\228\191\174\230\173\163"
    },
    {
      Name = "Noeffect_ball_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\239\188\136\230\156\170\230\173\163\231\161\174\228\189\191\231\148\168\239\188\137\231\144\131\231\167\141\230\166\130\231\142\135\228\191\174\230\173\163"
    },
    {
      Name = "guarant_efficiency",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\144\131\231\167\141\228\191\157\229\186\149\230\149\136\231\142\135"
    },
    {
      Name = "static_catch_rate",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\165\229\155\186\229\174\154\230\166\130\231\142\135\230\141\149\230\141\137 \233\133\141\231\189\174-1\239\188\140\230\140\137\229\142\159\229\133\172\229\188\143\232\174\161\231\174\151\230\141\149\230\141\137\231\142\135\239\188\155 \233\133\141\231\189\174\229\133\182\228\187\150\230\173\163\230\149\176\239\188\140\228\184\135\232\191\155\229\136\182\230\138\152\231\174\151\228\184\186\230\141\149\230\141\137\231\142\135\227\128\130"
    },
    {
      Name = "ball_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BallType"
        }
      },
      Description = "\231\144\131\231\167\141\231\177\187\229\158\139"
    },
    {
      Name = "ball_effect_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BallEffectType"
        }
      },
      Description = "\231\144\131\231\167\141\230\149\136\230\158\156\231\177\187\229\158\139"
    },
    {
      Name = "extra_effect_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 2
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "BALL_CONF_extra_effect_group"
        }
      },
      Description = "\231\144\131\231\167\141\233\153\132\229\138\160\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "catch_action",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\230\141\137\230\151\182\232\176\131\231\148\168\231\154\132\229\138\168\228\189\156\239\188\136\233\156\128\232\166\129\228\184\142action_tag\228\191\157\230\140\129\228\184\128\232\135\180\239\188\137"
    },
    {
      Name = "param_blackboard",
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
          EnumName = "BattleAIStatus"
        }
      },
      Description = "\233\187\145\230\157\191\229\128\188\229\143\130\230\149\176"
    },
    {
      Name = "param_buff",
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
          EnumName = "BuffGroupSign"
        }
      },
      Description = "buff\229\143\130\230\149\176\239\188\136\230\136\152\230\150\151\229\134\133\231\148\168"
    },
    {
      Name = "param_skilldam",
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
          EnumName = "SkillDamType"
        }
      },
      Description = "\231\179\187\229\136\171\229\143\130\230\149\176"
    },
    {
      Name = "param_weather",
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
          EnumName = "WeatherType"
        }
      },
      Description = "\229\164\169\230\176\148\229\143\130\230\149\176"
    },
    {
      Name = "catch_effect_blackboard",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\230\141\137\231\137\185\230\149\136\233\187\145\230\157\191\229\128\188"
    },
    {
      Name = "ball_threshold_modify",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\128\229\183\167\231\144\131\233\152\136\229\128\188\228\191\174\230\173\163\229\128\188"
    },
    {
      Name = "catch_bp_exp",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\144\131\229\165\150\229\138\177\231\154\132BP\231\187\143\233\170\140"
    },
    {
      Name = "history_sup_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\142\134\229\143\178\230\172\161\230\149\176\232\161\165\230\173\163\230\175\148"
    },
    {
      Name = "hp_sup_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "HP\232\189\172\229\140\150\230\175\148"
    },
    {
      Name = "pp_sup_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "PP\232\189\172\229\140\150\230\175\148"
    },
    {
      Name = "happy_sup_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\128\229\191\131\232\189\172\229\140\150\230\175\148"
    },
    {
      Name = "debuff_sup_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "debuff\232\189\172\229\140\150\230\175\148"
    },
    {
      Name = "refresh_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\191\231\148\168\229\144\142\229\136\183\229\135\186\231\168\128\230\156\137\229\174\160\231\154\132\230\166\130\231\142\135"
    },
    {
      Name = "global_catch_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\168\229\177\128\229\159\186\231\161\128\230\141\149\230\141\137\231\142\135"
    },
    {
      Name = "npc_id",
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
      Description = "\229\175\185\229\186\148\231\154\132NPC ID"
    },
    {
      Name = "hidden_capture_correction",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\144\229\140\191\230\141\149\230\141\137\230\166\130\231\142\135\228\191\174\230\173\163"
    },
    {
      Name = "ball_list_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\144\131\230\142\146\229\136\151\228\188\152\229\133\136\231\186\167\239\188\136\232\182\138\231\143\141\232\180\181\231\154\132\231\144\131\228\189\141\230\149\176\232\182\138\229\164\154\239\188\140\231\161\174\228\191\157\230\142\146\229\186\143\232\167\132\229\136\153\230\176\184\232\191\156\230\173\163\231\161\174\239\188\137"
    },
    {
      Name = "ball_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\135\232\183\175\229\190\132\239\188\136\228\184\187\231\149\140\233\157\162\229\143\179\228\184\139\231\144\131\231\167\141\233\128\137\230\139\169\229\146\140\230\138\149\230\142\183\229\176\143icon\239\188\137"
    },
    {
      Name = "ball_mini_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\135\232\183\175\229\190\132\239\188\136\230\142\137\232\144\189\231\137\169\228\186\164\228\186\146icon\239\188\137"
    },
    {
      Name = "ball_tips_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "tips\229\155\190\230\160\135\232\183\175\229\190\132\239\188\136\231\178\190\231\129\181\231\149\140\233\157\162icon\239\188\137"
    }
  }
}
RTTIManager:RegisterType(BALL_CONF.Name, BALL_CONF)

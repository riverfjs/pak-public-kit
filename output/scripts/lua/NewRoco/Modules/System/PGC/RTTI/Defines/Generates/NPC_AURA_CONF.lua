local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NPC_AURA_CONF = {
  Name = "NPC_AURA_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "npc/NPC_AURA_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\229\133\137\231\142\175ID"
    },
    {
      Name = "aura_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AuraType"
        }
      },
      Description = "\229\133\137\231\142\175\231\177\187\229\158\139"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\133\137\231\142\175\231\148\168\233\128\148\230\143\143\232\191\176"
    },
    {
      Name = "leader_battle_distance",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "NPC\232\140\131\229\155\180"
    },
    {
      Name = "leader_battle_delay",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "NPC\230\136\152\230\150\151\229\187\182\230\151\182"
    },
    {
      Name = "aura_area_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AuraAreaType"
        }
      },
      Description = "\229\133\137\231\142\175\232\140\131\229\155\180\231\177\187\229\158\139"
    },
    {
      Name = "aura_distance",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\133\137\231\142\175\232\140\131\229\155\180\239\188\136\229\141\149\228\189\141\239\188\154\229\142\152\231\177\179\239\188\137"
    },
    {
      Name = "aura_target_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AuraTargetType"
        }
      },
      Description = "\229\133\137\231\142\175\231\155\174\230\160\135\231\177\187\229\158\139"
    },
    {
      Name = "aura_target",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\189\177\229\147\141NPCID"
    },
    {
      Name = "time_last",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\133\137\231\142\175\230\149\136\230\158\156\230\140\129\231\187\173\230\151\182\233\151\180(\229\141\149\228\189\141ms, \232\182\133\232\191\135\232\175\165\230\151\182\233\151\180\229\176\177\230\176\184\228\185\133\229\136\160\233\153\164\232\175\165\229\133\137\231\142\175\239\188\140\228\184\141\233\156\128\232\166\129\232\175\165\229\138\159\232\131\189\229\176\177\228\184\141\232\166\129\229\161\171\239\188\129\239\188\129\239\188\129)"
    },
    {
      Name = "next_aura_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_AURA_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\187\147\230\157\159\229\144\142\232\176\131\231\148\168\229\133\137\231\142\175id"
    },
    {
      Name = "aura_effect",
      Type = RTTIBase.FieldType.ARRAY,
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
          TypeName = "NPC_AURA_CONF_aura_effect"
        }
      },
      Description = ""
    },
    {
      Name = "max_count",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\133\137\231\142\175\230\156\128\229\164\167\229\173\152\229\156\168\230\149\176\233\135\143"
    },
    {
      Name = "bound_create_actor",
      Type = RTTIBase.FieldType.BOOL,
      Default = true,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\187\145\229\174\154\229\136\155\233\128\160\232\128\133"
    },
    {
      Name = "remove_aura_distance",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\136\160\233\153\164\232\183\157\231\166\187"
    },
    {
      Name = "delete_aura_effect",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AuraEffect"
        }
      },
      Description = "\229\136\155\229\187\186\230\151\182\239\188\140\231\167\187\233\153\164\232\140\131\229\155\180\229\134\133\231\154\132\229\133\137\231\142\175\231\177\187\229\158\139"
    },
    {
      Name = "result_area",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "EnvTagType"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132\229\156\176\232\161\168\239\188\136\229\166\130\230\158\156\230\156\137\233\133\141\231\189\174\229\176\177\230\152\175\229\156\176\232\161\168\229\133\137\231\142\175\239\188\140\229\156\176\232\161\168\229\133\137\231\142\175\233\151\180\228\186\146\231\155\184\232\166\134\231\155\150\239\188\137"
    },
    {
      Name = "area_reject_tip",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\155\160\229\156\176\232\161\168\233\153\132\229\138\160\229\164\177\232\180\165tip"
    },
    {
      Name = "weather_reject_tip",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\155\160\229\164\169\230\176\148\233\153\132\229\138\160\229\164\177\232\180\165tip"
    }
  }
}
RTTIManager:RegisterType(NPC_AURA_CONF.Name, NPC_AURA_CONF)

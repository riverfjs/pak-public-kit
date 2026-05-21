local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local AREA_FUNC_CONF = {
  Name = "AREA_FUNC_CONF",
  Version = 1,
  Description = "\229\159\186\228\186\142AREA\232\161\168\239\188\140\231\174\161\231\144\134\230\137\128\230\156\137\229\140\186\229\159\159\229\156\176\229\144\141\227\128\129BGM\227\128\129\229\140\186\229\159\159\231\137\185\230\174\138\229\138\159\232\131\189\239\188\136\229\166\130\229\174\164\229\134\133\231\166\129\233\163\158\231\173\137\239\188\137\231\154\132\232\161\168",
  Metadata = {
    Alias = "area_func\232\161\168",
    RelativeYamlPath = "area/AREA_FUNC_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\230\149\176\230\141\174ID"
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
      Name = "area_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\140\186\229\159\159ID\239\188\140\230\148\175\230\140\129\230\149\176\231\187\132"
    },
    {
      Name = "belong_cave",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\230\180\158\231\169\180\229\173\144\229\133\179\229\141\161\229\144\141"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\140\186\229\144\141\231\167\176"
    },
    {
      Name = "broadcast_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AreaBroadcastType"
        }
      },
      Description = "\230\152\175\229\144\166\232\191\155\232\161\140\229\156\176\229\144\141\230\146\173\230\138\165(0\230\136\150\232\128\133\231\169\186\228\184\141\230\146\173\239\188\1551\230\146\173)"
    },
    {
      Name = "world_map_name_scale",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\229\186\148\229\164\167\229\156\176\229\155\190\228\184\138\231\154\132\231\172\172\229\135\160\230\161\163\228\189\141"
    },
    {
      Name = "safe_region_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\174\137\229\133\168\229\140\186\228\184\147\231\148\168\229\144\141\231\167\176"
    },
    {
      Name = "name_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\144\141\231\167\176\230\152\190\231\164\186\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "battle_source",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\229\156\186\230\153\175"
    },
    {
      Name = "bgm_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "bgm\231\154\132id"
    },
    {
      Name = "bgm_area_state",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "bgm\231\154\132state\229\173\151\231\172\166\228\184\178"
    },
    {
      Name = "switch_group_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "bgm\231\154\132group"
    },
    {
      Name = "area_bgm",
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
          TypeName = "AREA_FUNC_CONF_area_bgm"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "bgm_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "bgm\230\146\173\230\148\190\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "amb_events",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\142\175\229\162\131\233\159\179\230\149\136state_group"
    },
    {
      Name = "amb_switch",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\142\175\229\162\131\233\159\179\230\149\136state"
    },
    {
      Name = "amb_switch_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\142\175\229\162\131\233\159\179\230\149\136\230\146\173\230\148\190\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "scene_effect",
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
          TypeName = "AREA_FUNC_CONF_scene_effect"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "water_platform",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\176\180\233\157\162\229\186\149\229\186\167\232\181\132\230\186\144"
    }
  }
}
RTTIManager:RegisterType(AREA_FUNC_CONF.Name, AREA_FUNC_CONF)

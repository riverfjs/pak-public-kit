local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MODEL_CONF = {
  Name = "MODEL_CONF",
  Version = 1,
  Description = "\231\174\161\231\144\134\230\184\184\230\136\143\229\134\133\230\137\128\230\156\137NPC\228\189\191\231\148\168\231\154\132\232\147\157\229\155\190\228\191\161\230\129\175\239\188\140\228\187\165\229\143\138\230\160\135\230\179\168\231\155\184\229\133\179\231\154\132\228\189\147\229\158\139\227\128\129\229\164\180\229\131\143\231\173\137\233\128\160\229\158\139\231\155\184\229\133\179\228\191\161\230\129\175",
  Metadata = {
    Alias = "model\232\161\168",
    RelativeYamlPath = "model/MODEL_CONF.yaml",
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
      Description = "\230\168\161\229\158\139ID"
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
      Name = "path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\168\161\229\158\139\232\183\175\229\190\132SUBSTITUTE(\"Blueprint'/Game/ArtRes/BP/Pets/Com_YaJiJi1_001/BP_Com_YaJiJi1_001.BP_Com_YaJiJi1_001_C'\",\"Com_YaJiJi1_001\",E1201)"
    },
    {
      Name = "lua_class",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\177\187\232\183\175\229\190\132"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\184\184\230\128\129\228\189\191\231\148\168\231\154\132\229\164\180\229\131\143icon"
    },
    {
      Name = "shiny_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\232\137\178\231\178\190\231\129\181\228\189\191\231\148\168\231\154\132\229\164\180\229\131\143icon"
    },
    {
      Name = "big_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "256\229\164\167\229\176\143\231\154\132\231\178\190\231\129\181\229\164\180\229\131\143"
    },
    {
      Name = "big_shiny_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "256\229\164\167\229\176\143\231\154\132\229\188\130\232\137\178\231\178\190\231\129\181\229\164\180\229\131\143"
    },
    {
      Name = "ui_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\231\149\140\233\157\162\232\142\183\229\190\151\230\143\144\231\164\186\231\148\168\231\154\132icon\232\183\175\229\190\132"
    },
    {
      Name = "small_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\231\149\140\233\157\162\229\174\160\231\137\169\229\164\180\229\131\143\230\151\129\232\190\185\231\148\168\231\154\132\229\176\143\229\164\180\229\131\143"
    },
    {
      Name = "tired_small_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\231\149\140\233\157\162\230\144\186\229\184\166\231\154\132\229\174\160\231\137\169\229\138\155\231\171\173\229\164\180\229\131\143\230\152\190\231\164\186"
    },
    {
      Name = "anim_conf_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "anim\233\133\141\231\189\174id\239\188\140\231\148\177\231\168\139\229\186\143\231\148\159\230\136\144"
    },
    {
      Name = "capsule_radius",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\229\141\138\229\190\132\239\188\136UE\229\134\133\231\154\132\230\149\176\229\128\188*1000\229\144\142\229\143\150\230\149\180\239\188\137\239\188\140\231\148\177\231\168\139\229\186\143\231\148\159\230\136\144"
    },
    {
      Name = "capsule_halfheight",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\229\141\138\233\171\152\239\188\136UE\229\134\133\231\154\132\230\149\176\229\128\188*1000\229\144\142\229\143\150\230\149\180\239\188\137\239\188\140\231\148\177\231\168\139\229\186\143\231\148\159\230\136\144"
    },
    {
      Name = "SMR",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\190\142\230\156\175\232\147\157\229\155\190\228\184\138\233\133\141\231\189\174\231\154\132SMR\239\188\136\228\185\152\228\187\165\228\186\134100\239\188\137"
    },
    {
      Name = "model_scale",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 2000}
          }
        }
      },
      Description = "\230\168\161\229\158\139BP\231\188\169\230\148\190\230\175\148\228\190\139"
    },
    {
      Name = "exclude_nav_flag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\143\175\231\167\187\229\138\168NavMesh\229\140\186\229\159\159\231\177\187\229\158\139\230\160\135\232\174\176\228\189\141"
    },
    {
      Name = "habitat_flag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "HABITAT_FLAG"
        }
      },
      Description = "\229\164\154\230\160\150\230\160\135\232\174\176"
    },
    {
      Name = "mimic_editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\185\187\229\140\150\229\144\141"
    },
    {
      Name = "head_height",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\229\164\180\233\171\152"
    },
    {
      Name = "hd_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\230\160\184\229\155\162\228\189\147\230\136\152\231\148\168\231\154\132\233\171\152\230\168\161\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "enable_stick_to_socket",
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
          EnumName = "StickToSocket"
        }
      },
      Description = "\228\189\191\231\148\168\231\154\132\229\144\184\233\153\132\231\130\185"
    },
    {
      Name = "enable_sticked_socket",
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
          EnumName = "StickToSocket"
        }
      },
      Description = "\228\189\191\231\148\168\231\154\132\232\162\171\229\144\184\233\153\132\231\130\185"
    },
    {
      Name = "affect_navigation",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\142NavMesh\229\175\188\229\135\186\230\151\182\228\189\156\228\184\186\233\154\156\231\162\141\229\137\148\233\153\164"
    },
    {
      Name = "capsule_as_root",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\160\185\232\138\130\231\130\185\230\152\175\229\144\166\230\152\175\232\131\182\229\155\138\228\189\147"
    },
    {
      Name = "waterline",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\144\131\230\176\180\230\183\177\229\186\166\239\188\136UE\229\134\133\231\154\132\230\149\176\229\128\188*1000\229\144\142\229\143\150\230\149\180\239\188\137"
    },
    {
      Name = "build_physx_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\155\229\187\186\231\137\169\231\144\134\230\150\185\229\188\143\239\188\1360\239\188\154\228\184\141\229\136\155\229\187\186\239\188\1551\239\188\154\229\136\155\229\187\186\233\157\153\230\128\129\239\188\1552\239\188\154\229\136\155\229\187\186\229\138\168\230\128\129\239\188\137"
    },
    {
      Name = "allow_standing",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\231\171\153\239\188\1360\239\188\154\229\143\175\231\171\153\239\188\1551\239\188\154\228\184\141\229\143\175\231\171\153\239\188\140\230\160\135\232\174\176\229\144\142\233\187\152\232\174\164\229\175\188\229\135\186\231\137\169\231\144\134\239\188\137"
    },
    {
      Name = "toy_poi_socket",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\231\142\169\229\133\183POI"
    },
    {
      Name = "battle_entry_anim_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151NPC\228\189\191\231\148\168\231\154\132\229\133\165\230\136\152\228\184\162\231\144\131\229\138\168\231\148\187\232\183\175\229\190\132"
    },
    {
      Name = "trampling_lawn_comp",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TramplingLawnComp"
        }
      },
      Description = "\232\184\169\232\141\137\230\168\161\229\188\143"
    }
  }
}
RTTIManager:RegisterType(MODEL_CONF.Name, MODEL_CONF)

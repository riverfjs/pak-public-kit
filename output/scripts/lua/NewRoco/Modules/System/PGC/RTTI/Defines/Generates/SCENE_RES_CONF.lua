local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_RES_CONF = {
  Name = "SCENE_RES_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene/SCENE_RES_CONF.yaml",
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
      Description = "\229\156\186\230\153\175\231\148\168\232\181\132\230\186\144ID"
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
      Name = "data_load_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\231\188\150\228\184\173\233\187\152\232\174\164\229\156\176\229\157\151\231\154\132\229\138\160\232\189\189\230\151\182\230\156\186\239\188\1361\228\184\186\229\137\175\230\156\172\231\177\187\229\158\139\239\188\1552\228\184\186\233\128\137\230\139\169\229\156\176\229\155\190\233\128\137\230\139\169\229\153\168\232\135\170\229\138\168\229\138\160\232\189\189\231\177\187\229\158\139\239\188\140\231\177\187\228\188\188\233\173\148\230\179\149\229\173\166\233\153\162\239\188\137"
    },
    {
      Name = "is_unused",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\186\159\229\188\131"
    },
    {
      Name = "sub_scene_res_list",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_RES_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132\229\173\144\229\156\186\230\153\175"
    },
    {
      Name = "scene_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\143\141\230\159\165\229\156\186\230\153\175id"
    },
    {
      Name = "scene_export_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.UNIQUE
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 100, Max = 4095}
          }
        }
      },
      Description = "\229\156\186\230\153\175\229\175\188\229\135\186\230\160\135\232\175\134\239\188\140\229\142\134\229\143\178\229\142\159\229\155\160\230\178\191\231\148\168\232\135\170SCENE_CONF.id\239\188\140scence_object\232\175\134\229\136\171\229\156\186\230\153\175\233\133\141\231\189\174\228\184\147\231\148\168\239\188\140\229\139\191\228\185\177\231\148\168\239\188\140\228\189\191\231\148\168\229\137\141\229\133\136\229\146\168\232\175\162\229\173\144\233\151\187."
    },
    {
      Name = "is_sub_scene",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\164\167\228\184\150\231\149\140\231\154\132\229\173\144\229\133\179\229\141\161\239\188\136\229\175\188\229\135\186\230\151\182\229\143\175\232\131\189\233\156\128\232\166\129\239\188\140\228\189\134\231\172\172\228\184\128\230\172\161\229\175\188\229\135\186\230\151\182\230\156\170\233\133\141\229\133\165sub_scene_res_list\239\188\137"
    },
    {
      Name = "task_scene_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\186\230\153\175\229\136\134\231\187\132\239\188\136\231\148\168\228\186\142\229\136\164\230\150\173\230\152\175\229\144\166\230\152\190\231\164\186\232\183\168\229\156\186\230\153\175\230\143\144\231\164\186\239\188\137"
    },
    {
      Name = "scene_res_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "scene_res_name"
        }
      },
      Description = "\229\156\186\230\153\175\229\144\141\231\167\176\239\188\136\231\148\168\228\186\142\232\183\168\229\156\186\230\153\175\228\187\187\229\138\161\229\144\141\231\167\176\232\175\187\229\143\150\239\188\137"
    },
    {
      Name = "not_teleport_scene_role_flag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\188\160\233\128\129\232\167\146\232\137\178\233\153\132\232\191\145\230\151\182\239\188\140\232\139\165\228\188\160\233\128\129\232\128\133\230\156\137\233\133\141\231\189\174\231\154\132flag\229\136\153\229\156\186\230\153\175\230\156\170\232\167\163\233\148\129\230\151\160\230\179\149\230\137\167\232\161\140\228\188\160\233\128\129"
    },
    {
      Name = "world_map_entry_npc_content_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\164\167\229\156\176\229\155\190\228\184\138\228\188\160\233\128\129\229\133\165\229\143\163NPC\231\154\132\229\136\183\230\150\176ID"
    },
    {
      Name = "main_map_res_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\231\149\140\233\157\162\229\176\143\229\156\176\229\155\190\231\154\132\233\187\152\232\174\164\232\181\132\230\186\144\232\183\175\229\190\132\239\188\140\228\187\165A1A2B1\228\184\186\229\141\149\228\189\141\229\140\186\229\136\134"
    },
    {
      Name = "function_ban_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "FUNCTION_BAN_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\177\143\232\148\189\229\138\159\232\131\189/UI\231\138\182\230\128\129\231\154\132\233\133\141\231\189\174ID"
    },
    {
      Name = "ban_type",
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
          EnumName = "SceneRideAllType"
        }
      },
      Description = "\231\166\129\231\148\168\231\154\132\233\170\145\228\185\152\232\131\189\229\138\155"
    },
    {
      Name = "ban_vitality",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\166\129\231\148\168\228\189\147\229\138\155\239\188\1360=\228\184\141\231\166\129\239\188\1401=\231\166\129)"
    },
    {
      Name = "ban_magic",
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
          EnumName = "SceneMagicType"
        }
      },
      Description = "\231\166\129\231\148\168\231\154\132\233\173\148\230\179\149\232\131\189\229\138\155"
    },
    {
      Name = "source",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\165\229\143\163\229\156\186\230\153\175\232\181\132\230\186\144"
    },
    {
      Name = "art_source",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\133\165\229\143\163\229\156\186\230\153\175\231\190\142\230\156\175\232\181\132\230\186\144"
    },
    {
      Name = "ban_ride_socket",
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
          EnumName = "ScenePlayerRideSocketType"
        }
      },
      Description = "\231\166\129\231\148\168\231\154\132\233\170\145\228\185\152\230\143\146\230\167\189\231\177\187\229\158\139"
    },
    {
      Name = "ban_transform_magic_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MAGIC_TRANSFORM_CONF",
          FieldName = "transform_group"
        }
      },
      Description = "\231\166\129\231\148\168\231\154\132\230\182\178\229\140\150\230\156\175\231\177\187\229\158\139"
    },
    {
      Name = "if_mainchara_light_scene",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\232\167\146\230\152\175\229\144\166\229\143\145\229\133\137\239\188\1360\228\184\141\229\143\145\239\188\1401\229\143\145\239\188\137"
    },
    {
      Name = "main_source",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\229\156\186\230\153\175"
    },
    {
      Name = "build_battlefield_and_envinfo",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\229\156\186\229\146\140env\230\152\175\229\144\166\230\158\132\229\187\186"
    },
    {
      Name = "build_physx",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\230\152\175\229\144\166\230\158\132\229\187\186"
    },
    {
      Name = "all_dynamic_load_sublevel_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\137\128\230\156\137\229\143\175\229\138\168\230\128\129\229\188\128\229\133\179\231\154\132\229\156\186\230\153\175\229\173\144\229\133\179\229\141\161\232\183\175\229\190\132"
    },
    {
      Name = "default_load_sublevel_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\187\152\232\174\164\229\138\160\232\189\189\231\154\132\229\156\186\230\153\175\229\173\144\229\133\179\229\141\161\232\183\175\229\190\132"
    },
    {
      Name = "friend_list_inf_ban",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\166\129\230\173\162\229\165\189\229\143\139\229\136\151\232\161\168\228\191\161\230\129\175\230\152\190\231\164\186"
    },
    {
      Name = "world_width",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\155\190\229\174\189\229\186\166"
    },
    {
      Name = "world_top_left_x",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\155\190\229\183\166\228\184\138\232\167\146X\229\157\144\230\160\135"
    },
    {
      Name = "world_top_left_y",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\155\190\229\183\166\228\184\138\232\167\146Y\229\157\144\230\160\135"
    },
    {
      Name = "minimap_zoom",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\176\143\229\156\176\229\155\190\230\152\190\231\164\186\229\140\186\229\159\159\231\188\169\230\148\190\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "x_size",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\186\230\153\175x\232\189\180\229\164\167\229\176\143"
    },
    {
      Name = "y_size",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\186\230\153\175y\232\189\180\229\164\167\229\176\143"
    },
    {
      Name = "offset_x",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "WorldComposition\228\184\1731x1\229\156\176\229\157\151\231\154\132VirtualLandOffsetX"
    },
    {
      Name = "offset_y",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "WorldComposition\228\184\1731x1\229\156\176\229\157\151\231\154\132VirtualLandOffsetY"
    },
    {
      Name = "tile_size",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "WorldComposition\228\184\1731x1\229\156\176\229\157\151\231\154\132VirtualLandSize*2"
    },
    {
      Name = "daily_build_nav",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\188\232\136\170\230\152\175\229\144\166\230\151\165\230\158\132\229\187\186"
    },
    {
      Name = "daily_build_physx",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\230\152\175\229\144\166\230\151\165\230\158\132\229\187\186"
    },
    {
      Name = "daily_build_battlefield",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\229\156\186\230\152\175\229\144\166\230\151\165\230\158\132\229\187\186"
    },
    {
      Name = "entry_npcid",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\229\184\184\233\169\187\229\133\165\229\143\163npc_id"
    },
    {
      Name = "exit_npcid",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\229\184\184\233\169\187\229\135\186\229\143\163npc_id"
    },
    {
      Name = "extra_infos",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\232\191\155\229\135\186\230\150\185\230\179\149\229\164\135\230\179\168"
    }
  }
}
RTTIManager:RegisterType(SCENE_RES_CONF.Name, SCENE_RES_CONF)

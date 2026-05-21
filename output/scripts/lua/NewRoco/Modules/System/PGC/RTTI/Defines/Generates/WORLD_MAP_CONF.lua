local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local WORLD_MAP_CONF = {
  Name = "WORLD_MAP_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "world_map/WORLD_MAP_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\228\184\150\231\149\140\229\156\176\229\155\190\229\133\131\231\180\160id"
    },
    {
      Name = "map_show_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapIconShowType"
        }
      },
      Description = "\231\177\187\229\136\171"
    },
    {
      Name = "area_func_ids",
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
          TypeName = "AREA_FUNC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\143\130\230\149\1761 (area_func_id)"
    },
    {
      Name = "npc_refresh_ids",
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
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\143\130\230\149\1762_1 (npc_refresh_id)"
    },
    {
      Name = "npc_conf_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\143\130\230\149\1762_2 (npc_conf_id)\229\141\129\229\136\134\232\128\151\230\128\167\232\131\189\239\188\140\230\133\142\231\148\168\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129"
    },
    {
      Name = "auto_explored_area",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\130\230\149\1763 (\229\141\149\228\189\141\239\188\154\231\177\179)"
    },
    {
      Name = "dungeon_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DUNGEON_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\143\130\230\149\1764"
    },
    {
      Name = "map_show_location",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapIconShowLocation"
        }
      },
      Description = "\229\156\176\229\155\190\229\133\131\231\180\160\230\137\128\229\177\158\229\156\186\230\153\175"
    },
    {
      Name = "area_func_id_inter",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_FUNC_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\167\132\229\136\146\229\140\186\229\159\159\230\160\135\231\173\190 (area_func_id)"
    },
    {
      Name = "storyflag_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "FUNCTION_STORY_FLAG_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\139\165\230\156\137storyflag\229\144\142\230\152\190\231\164\186\229\155\190\230\160\135"
    },
    {
      Name = "icon_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\183\233\155\190\232\167\163\233\148\129\229\144\142\239\188\140\233\133\141\231\189\174\233\135\141\229\143\160icon\231\154\132\230\152\190\231\164\186\229\177\130\231\186\167"
    },
    {
      Name = "default_track",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\229\176\143\229\156\176\229\155\190\232\135\170\229\138\168\232\191\189\232\184\170\239\188\136\232\180\180\232\190\185\232\191\189\232\184\170\239\188\137"
    },
    {
      Name = "default_track_worldmap",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162\229\144\142\230\151\160\232\167\134\232\183\157\231\166\187\230\152\190\231\164\186\229\156\168\229\164\167\229\156\176\229\155\190\228\184\138"
    },
    {
      Name = "default_track_loop",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\140\129\231\187\173\230\146\173\230\148\190\232\191\189\232\184\170\229\138\168\230\149\136\239\188\136default_track\233\156\128\232\166\129\228\184\186true\239\188\137"
    },
    {
      Name = "name_area_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\152\190\231\164\186\229\156\176\229\144\141/NPC\229\155\190\230\160\135\231\154\132\229\157\144\230\160\135\231\130\185"
    },
    {
      Name = "zone_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "regionname"
        }
      },
      Description = "\230\152\190\231\164\186\231\154\132\229\156\176\229\144\141"
    },
    {
      Name = "camp_refresh_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\230\158\175\230\158\157\231\154\132\231\178\190\231\129\181\232\184\170\232\191\185\239\188\136\230\158\175\230\158\157\229\136\183\230\150\176id\239\188\137"
    },
    {
      Name = "unexplored_in_compass",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\230\139\190\229\143\150\229\137\141 \230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\231\189\151\231\155\152"
    },
    {
      Name = "explored_in_compass",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\230\139\190\229\143\150\229\144\142 \230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\231\189\151\231\155\152"
    },
    {
      Name = "unfinished_in_compass",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\183\178\229\143\145\231\142\176\230\156\170\229\174\140\230\136\144\230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\231\189\151\231\155\152"
    },
    {
      Name = "unexplored_in_minimap",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\230\139\190\229\143\150\229\137\141 \230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\228\184\187\231\149\140\233\157\162\229\176\143\229\156\176\229\155\190"
    },
    {
      Name = "explored_in_minimap",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\230\139\190\229\143\150\229\144\142 \230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\228\184\187\231\149\140\233\157\162\229\176\143\229\156\176\229\155\190"
    },
    {
      Name = "unfinished_in_minimap",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\183\178\229\143\145\231\142\176\230\156\170\229\174\140\230\136\144\230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\228\184\187\231\149\140\233\157\162\229\176\143\229\156\176\229\155\190"
    },
    {
      Name = "h_detection_range",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\229\156\168\231\189\151\231\155\152\231\154\132 \230\176\180\229\185\179\230\163\128\230\181\139\232\183\157\231\166\187"
    },
    {
      Name = "v_detection_range",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\229\156\168\231\189\151\231\155\152\231\154\132 \231\171\150\231\155\180\230\163\128\230\181\139\232\183\157\231\166\187"
    },
    {
      Name = "unexplored_in_map",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\230\139\190\229\143\150\229\137\141 \230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\229\164\167\229\156\176\229\155\190"
    },
    {
      Name = "explored_in_map",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\230\139\190\229\143\150\229\144\142 \230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\229\164\167\229\156\176\229\155\190"
    },
    {
      Name = "unfinished_in_map",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\183\178\229\143\145\231\142\176\230\156\170\229\174\140\230\136\144\230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\229\164\167\229\156\176\229\155\190"
    },
    {
      Name = "areaicon_unexplore",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135 \239\188\136\230\156\170\230\142\162\231\180\162\239\188\137"
    },
    {
      Name = "areaicon_explore",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135 \239\188\136\230\142\162\231\180\162\239\188\137"
    },
    {
      Name = "areaicon_unfinished",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135 \239\188\136\230\156\170\229\143\145\231\142\176\230\156\170\229\174\140\230\136\144\239\188\137"
    },
    {
      Name = "npcicon_lock",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135 \239\188\136\230\156\170\232\167\163\233\148\129\239\188\137"
    },
    {
      Name = "npcicon_unlock",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135 \239\188\136\232\167\163\233\148\129\239\188\137"
    },
    {
      Name = "npcicon_corner_unlock",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135\239\188\136\232\167\163\233\148\129\239\188\137\231\154\132\232\167\146\230\160\135"
    },
    {
      Name = "npcicon_color_unlock",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135\239\188\136\232\167\163\233\148\129\239\188\137\229\186\149\232\137\178"
    },
    {
      Name = "npcicon_unfinished",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\230\136\150\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135 \239\188\136\229\183\178\229\143\145\231\142\176\230\156\170\229\174\140\230\136\144\239\188\137"
    },
    {
      Name = "map_markicon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\155\190\228\184\138\230\160\135\232\174\176\231\130\185\231\154\132\229\155\190\230\160\135"
    },
    {
      Name = "compass_markicon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\228\184\138\230\160\135\232\174\176\231\130\185\231\154\132\229\155\190\230\160\135"
    },
    {
      Name = "npcicon_levelup",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 4
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "WORLD_MAP_CONF_npcicon_levelup"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "teleport_rule_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TELEPORT_RULES_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\188\160\233\128\129\231\130\185\233\135\135\230\160\183"
    },
    {
      Name = "teleport_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TELEPORT_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\188\160\233\128\129\231\130\185Id, \230\151\160\229\136\1530, \229\189\147\229\137\141\228\189\191\231\148\168\231\179\187\231\187\159: - \228\184\150\231\149\140\229\156\176\229\155\190"
    },
    {
      Name = "special_teleport",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\228\188\160\233\128\129\231\130\185"
    },
    {
      Name = "special_teleport_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\228\188\160\233\128\129\231\130\185\230\150\135\230\156\172"
    },
    {
      Name = "special_teleport_flag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PlayerStoryFlagEnum"
        }
      },
      Description = "storyflag\232\167\163\233\148\129\231\137\185\230\174\138\228\188\160\233\128\129"
    },
    {
      Name = "map_func_icon_group",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapFuncIconGroup"
        }
      },
      Description = "\229\164\167\229\156\176\229\155\190/\231\189\151\231\155\152\228\184\138\229\155\190\230\160\135\229\136\134\231\187\132\239\188\136\230\150\185\228\190\191\232\176\131\230\149\180\230\175\143\231\187\132\229\155\190\230\160\135\231\154\132\229\164\167\229\176\143\239\188\137"
    },
    {
      Name = "layered_id",
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
          TypeName = "LAYERED_WORLD_MAP_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\156\168\231\154\132\229\136\134\229\177\130\229\156\176\229\155\190id"
    },
    {
      Name = "unlock_zone",
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
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\167\163\233\148\129\231\154\132\229\140\186\229\159\159ID\239\188\140\230\148\175\230\140\129\230\149\176\231\187\132"
    },
    {
      Name = "element_show_scale",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapElementScale"
        }
      },
      Description = "\230\152\190\231\164\186\229\156\168\229\164\167\229\156\176\229\155\190\231\154\132\229\135\160\231\186\167\230\175\148\228\190\139"
    },
    {
      Name = "lock_element_show_top",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\170\230\142\162\231\180\162/\230\156\170\232\167\163\233\148\129/\230\156\170\229\143\145\231\142\176\231\138\182\230\128\129\231\154\132\229\155\190\230\160\135\230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\232\191\183\233\155\190\228\184\138\230\150\185 \239\188\1360\230\136\150\231\169\186\228\184\186\230\152\190\231\164\186\229\156\168\232\191\183\233\155\190\228\184\139\230\150\185\239\188\1551\228\184\186\230\152\190\231\164\186\229\156\168\232\191\183\233\155\190\228\184\138\230\150\185\239\188\137"
    },
    {
      Name = "unlock_element_show_top",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\162\231\180\162/\232\167\163\233\148\129/\229\183\178\229\143\145\231\142\176\231\138\182\230\128\129\231\154\132\229\155\190\230\160\135\230\152\175\229\144\166\230\152\190\231\164\186\229\156\168\232\191\183\233\155\190\228\184\138\230\150\185 \239\188\1360\230\136\150\231\169\186\228\184\186\230\152\190\231\164\186\229\156\168\232\191\183\233\155\190\228\184\139\230\150\185\239\188\1551\228\184\186\230\152\190\231\164\186\229\156\168\232\191\183\233\155\190\228\184\138\230\150\185\239\188\137"
    },
    {
      Name = "map_tips_show_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapTipsShowType"
        }
      },
      Description = "\229\156\176\229\155\190\228\184\138tips\230\152\190\231\164\186\231\177\187\229\136\171\239\188\136\233\133\141\231\189\174\231\169\186\229\146\140MAP_TIPS_NONE\228\184\141\230\152\190\231\164\186tips\239\188\137"
    },
    {
      Name = "map_tips_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "map_tips_show_type",
          Branches = {
            {
              Value = 14,
              TypeName = "SHOP_CONF",
              FieldName = "id"
            },
            {
              Value = 15,
              TypeName = "SHOP_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\160\185\230\141\174map_tips_show_type\228\184\173\228\184\141\229\144\140\231\154\132\230\158\154\228\184\190\231\177\187\229\158\139\229\161\171\229\134\153\228\184\141\229\144\140\231\154\132\229\143\130\230\149\176 \229\189\147\229\161\171\229\134\153MAP_TIPS_SHOP_TOTAL_CONSUMPTION\230\136\150MAP_TIPS_SHOP_TOTAL_COMMON\230\151\182\239\188\140\229\143\130\230\149\176\228\184\186SHOP_CONF\228\184\173\231\154\132id"
    },
    {
      Name = "is_challenge",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\177\158\228\186\142\233\156\178\229\164\169\229\175\185\230\136\152"
    },
    {
      Name = "element_text_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "mapname"
        }
      },
      Description = "\229\156\176\229\155\190\229\133\131\231\180\160\229\144\141\231\167\176"
    },
    {
      Name = "world_map_NPCicon_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\150\231\149\140\229\156\176\229\155\190\228\184\138\229\175\185\229\186\148\231\154\132NPC\229\155\190\230\160\135\239\188\136\229\143\179\228\190\167\232\175\166\230\131\133\231\149\140\233\157\162\231\154\132\233\161\182\233\131\168\231\148\168\239\188\140\239\188\129\239\188\129\232\139\165\229\173\152\229\156\168\232\167\163\233\148\129\231\138\182\230\128\129\239\188\140\229\136\153\231\155\180\230\142\165\233\133\141\232\167\163\233\148\129\231\138\182\230\128\129\231\154\132\232\181\132\230\186\144\232\183\175\229\190\132\239\188\137"
    },
    {
      Name = "worldmap_npc_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "mapdesc"
        }
      },
      Description = "\228\184\150\231\149\140\229\156\176\229\155\190\228\184\138\231\130\185\229\135\187NPC\229\155\190\230\160\135\229\188\185\229\135\186\231\154\132\232\175\166\230\131\133\231\149\140\233\157\162\231\154\132\230\143\143\232\191\176"
    },
    {
      Name = "picked_mark_tips_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\160\135\232\174\176\231\130\185\232\175\166\230\131\133\230\160\143\231\154\132\229\155\190\230\160\135\232\183\175\229\190\132\239\188\136\233\128\137\228\184\173\239\188\137"
    },
    {
      Name = "unpicked_mark_tips_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\160\135\232\174\176\231\130\185\232\175\166\230\131\133\230\160\143\231\154\132\229\155\190\230\160\135\232\183\175\229\190\132\239\188\136\230\156\170\233\128\137\228\184\173\239\188\137"
    },
    {
      Name = "unlock_warn_tips",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\170\232\167\163\233\148\129\230\151\182\229\128\153\231\154\132\228\184\128\229\143\165\232\175\157\231\186\162\229\173\151\230\143\144\233\134\146"
    },
    {
      Name = "dungeon_type_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\137\175\230\156\172\231\177\187\229\158\139\230\150\135\229\173\151\230\143\143\232\191\176"
    },
    {
      Name = "dungeon_title_bg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\137\175\230\156\172tips\228\184\138\231\154\132\229\155\190\231\137\135\232\181\132\230\186\144"
    },
    {
      Name = "dungeon_interface_bg_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\137\175\230\156\172tips\228\184\138\229\186\149\230\157\191\232\183\175\229\190\132"
    },
    {
      Name = "zone_name_roco",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\231\154\132\229\156\176\229\144\141\239\188\136\230\180\155\229\133\139\230\150\135"
    },
    {
      Name = "name_scale",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\155\190\229\144\141\229\173\151\230\152\190\231\164\186\231\186\167\229\136\171\239\188\136\229\186\159\229\188\131\239\188\137"
    },
    {
      Name = "is_invisible",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\141\233\156\128\232\166\129\229\156\168\228\184\150\231\149\140\229\156\176\229\155\190\228\184\138\230\152\190\231\164\186 \239\188\136\233\128\154\232\191\135\229\136\160\233\153\164id\229\174\158\231\142\176 \229\186\159\229\188\131\239\188\137"
    },
    {
      Name = "area_id",
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
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\140\186\229\159\159id\239\188\140\230\148\175\230\140\129\230\149\176\231\187\132\239\188\136\229\140\186\229\159\159\229\174\160\231\137\169\230\148\182\233\155\134\229\134\140\239\188\140\229\186\159\229\188\131\239\188\137"
    },
    {
      Name = "pet_base_id",
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
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\229\140\186\229\159\159\229\129\182\233\129\135\231\178\190\231\129\181\228\191\161\230\129\175\239\188\136\229\140\186\229\159\159\229\174\160\231\137\169\230\148\182\233\155\134\229\134\140\239\188\140\229\177\143\232\148\189\239\188\137"
    },
    {
      Name = "belong_to_season",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\231\154\132\232\181\155\229\173\163\239\188\136\232\181\155\229\173\163id\239\188\137"
    }
  }
}
RTTIManager:RegisterType(WORLD_MAP_CONF.Name, WORLD_MAP_CONF)

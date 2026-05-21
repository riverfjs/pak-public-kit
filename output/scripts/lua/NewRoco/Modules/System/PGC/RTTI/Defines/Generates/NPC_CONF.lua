local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NPC_CONF = {
  Name = "NPC_CONF",
  Version = 1,
  Description = "NPC_CONF \230\152\175\230\184\184\230\136\143\229\134\133\231\148\168\228\186\142\229\174\154\228\185\137\230\137\128\230\156\137\233\157\158\231\142\169\229\174\182\232\167\146\232\137\178\239\188\136NPC\239\188\137\229\159\186\231\161\128\229\177\158\230\128\167\229\146\140\230\160\184\229\191\131\232\161\140\228\184\186\231\154\132\230\160\184\229\191\131\233\133\141\231\189\174\230\150\135\228\187\182\239\188\140\229\174\131\231\155\184\229\189\147\228\186\142\230\175\143\228\184\170NPC\231\154\132\226\128\156\232\186\171\228\187\189\232\175\129\226\128\157\229\146\140\226\128\156\232\161\140\228\184\186\229\135\134\229\136\153\230\137\139\229\134\140\226\128\157\227\128\130",
  Metadata = {
    Alias = "NPC\232\161\168\227\128\129NPC",
    RelativeYamlPath = "npc/NPC_CONF.yaml",
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
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 999999}
          }
        }
      },
      Description = "NPC_ID"
    },
    {
      Name = "genre",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ClientNpcType"
        }
      },
      Description = "NPC\231\177\187\229\158\139"
    },
    {
      Name = "reward_drop_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RewardNpcType"
        }
      },
      Description = "\229\165\150\229\138\177\230\142\137\232\144\189\230\150\185\229\188\143"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "name"
        }
      },
      Description = "\229\144\141\231\167\176"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\176\229\143\183"
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
      Name = "editor_name_1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\228\186\186\229\189\162NPC\227\128\144\231\150\145\228\188\188\229\186\159\229\188\131\227\128\145"
    },
    {
      Name = "npc_tag",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcFuncTag"
        }
      },
      Description = "NPC\231\177\187\229\158\139Tag"
    },
    {
      Name = "model_conf",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MODEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\181\132\230\186\144\233\133\141\231\189\174ID"
    },
    {
      Name = "original_action",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\184\184\230\128\129\229\190\170\231\142\175\229\138\168\228\189\156"
    },
    {
      Name = "original_emotion_eye",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\184\184\230\128\129\229\190\170\231\142\175\231\156\188\233\131\168\232\161\168\230\131\133"
    },
    {
      Name = "original_emotion_mouth",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\184\184\230\128\129\229\190\170\231\142\175\229\152\180\233\131\168\232\161\168\230\131\133"
    },
    {
      Name = "item_quality",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\168\128\230\156\137\229\186\166\239\188\1360~5\239\188\137"
    },
    {
      Name = "npc_group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\230\179\155\231\148\168\229\143\141\229\186\148\231\190\164\231\187\132\230\160\135\231\173\190"
    },
    {
      Name = "LocationTag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "LocationTag"
        }
      },
      Description = "\229\174\154\228\185\137\229\164\167\228\184\150\231\149\140\228\184\173\230\137\128\229\164\132\228\189\141\231\189\174"
    },
    {
      Name = "behavior_tree",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\161\140\228\184\186\230\160\145\232\181\132\228\186\167\232\183\175\229\190\132"
    },
    {
      Name = "mf_behavior_tree",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "MFBT\232\161\140\228\184\186\230\160\145\232\181\132\228\186\167\232\183\175\229\190\132"
    },
    {
      Name = "ai_perform_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_GROUP_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "enable_server_ai",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\187\152\232\174\164\229\144\175\231\148\168\230\156\141\229\138\161\229\153\168AI"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\171\139\231\187\152\232\181\132\230\186\144"
    },
    {
      Name = "BulkySizeType",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcBulkySizeType"
        }
      },
      Description = "\228\189\147\229\158\139\231\173\137\231\186\167\230\158\154\228\184\190\239\188\136\233\187\152\232\174\164AUTO\232\135\170\229\138\168\232\174\161\231\174\151\239\188\137"
    },
    {
      Name = "bulky",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\229\158\139\230\152\190\231\164\186\231\173\137\231\186\167"
    },
    {
      Name = "aoi_distance",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AoiCullDistance"
        }
      },
      Description = "aoi\228\184\139\229\143\145\232\183\157\231\166\187"
    },
    {
      Name = "act",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\229\138\168\228\189\156"
    },
    {
      Name = "show_name_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcNameType"
        }
      },
      Description = "\233\147\173\231\137\140\230\152\190\231\164\186\231\177\187\229\158\139"
    },
    {
      Name = "show_name",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\190\231\164\186NPC\229\144\141\231\167\176"
    },
    {
      Name = "show_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\190\231\164\186NPC\231\173\137\231\186\167"
    },
    {
      Name = "npc_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\231\173\137\231\186\167"
    },
    {
      Name = "npc_worldtitle",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\228\186\140\231\186\167\231\167\176\229\143\183\230\150\135\230\156\172"
    },
    {
      Name = "title_icon_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "icon\229\155\190\230\160\135\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "icon_show_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "icon\229\155\190\230\160\135\232\181\132\230\186\144\229\177\149\231\164\186\232\140\131\229\155\180"
    },
    {
      Name = "icon_height",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "icon\232\183\157\231\166\187NPC\233\148\154\231\130\185\233\171\152\229\186\166(cm)"
    },
    {
      Name = "npc_nameplate_show_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\233\147\173\231\137\140\230\156\128\229\176\143\229\143\175\232\167\134\232\140\131\229\155\180(cm\239\188\137"
    },
    {
      Name = "visible_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\230\156\128\229\176\143\229\143\175\232\167\134\232\140\131\229\155\180\239\188\136cm)"
    },
    {
      Name = "npc_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {},
      Description = "npc\231\167\187\229\138\168\233\128\159\229\186\166\239\188\136cm/s\239\188\137"
    },
    {
      Name = "min_map_disappear",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "WORLD_MAP_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\168\229\176\143\229\156\176\229\155\190\228\184\142\231\189\151\231\155\152\228\184\138\231\154\132\230\152\190\231\164\186\231\154\132mapid"
    },
    {
      Name = "map_show_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapShowType"
        }
      },
      Description = "\229\176\143\229\156\176\229\155\190\230\152\190\231\164\186\229\189\162\231\138\182"
    },
    {
      Name = "npc_act_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActType"
        }
      },
      Description = "NPC\232\161\140\228\184\186\231\177\187\229\158\139\239\188\136\230\150\176\229\162\158\239\188\137"
    },
    {
      Name = "model_scale",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\231\188\169\230\148\190\230\175\148\228\190\139"
    },
    {
      Name = "fx_locate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\149\136\230\140\130\232\189\189\228\189\141\231\189\174(0:\232\132\154\228\184\139,1:\232\186\171\228\184\138)"
    },
    {
      Name = "fx_source",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\149\136\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "not_turn_face",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\141\232\189\172\232\132\184\239\188\1360\239\188\154\232\189\172\232\132\184\239\188\1401\239\188\154\228\184\141\232\189\172\232\132\184\239\188\1402\239\188\154\228\187\133\229\175\185\232\175\157\228\184\173\232\189\172\232\132\184\239\188\137"
    },
    {
      Name = "stop_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\229\138\168\229\175\187\232\183\175\229\129\156\228\184\139\232\183\157\231\166\187\239\188\136cm\239\188\137 \239\188\136\231\155\174\229\137\141\228\189\156\228\184\186\228\186\164\228\186\146\229\141\138\229\190\132\228\189\191\231\148\168\239\188\137"
    },
    {
      Name = "appear_perform",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\229\156\186\230\151\182\230\146\173\230\148\190\230\138\128\232\131\189\232\161\168\230\188\148id"
    },
    {
      Name = "emerge_ani",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\142\176\230\151\182\231\137\185\230\149\136"
    },
    {
      Name = "disappear_ani",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\182\136\229\164\177\230\151\182\231\137\185\230\149\136"
    },
    {
      Name = "emerge_skill",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\142\176\230\151\182\230\138\128\232\131\189\232\183\175\229\190\132"
    },
    {
      Name = "disappear_skill",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\182\136\229\164\177\230\151\182\230\138\128\232\131\189\232\183\175\229\190\132"
    },
    {
      Name = "emerge_act",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\142\176\230\151\182\229\138\168\228\189\156"
    },
    {
      Name = "disappear_act",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\182\136\229\164\177\230\151\182\229\138\168\228\189\156"
    },
    {
      Name = "delay_disappear_performance",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\146\173\230\148\190\229\187\182\232\191\159\231\167\187\233\153\164\232\161\168\230\188\148"
    },
    {
      Name = "respond_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\229\138\168\229\147\141\229\186\148\232\183\157\231\166\187\239\188\136cm\239\188\137"
    },
    {
      Name = "lock_on_ground",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\135\170\229\138\168\232\180\180\229\156\176"
    },
    {
      Name = "forbid_collision",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\166\129\230\173\162\231\162\176\230\146\158\228\189\147\231\167\175 \239\188\136\229\166\130\230\158\156\230\168\161\229\158\139\229\142\159\230\156\172\230\156\137\231\162\176\230\146\158\239\188\140\229\143\175\228\187\165\228\189\191\231\148\168\232\175\165\233\161\185\231\166\129\230\173\162\239\188\137"
    },
    {
      Name = "npc_interact_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "InteractType"
        }
      },
      Description = "NPC\228\186\164\228\186\146\231\177\187\229\158\139"
    },
    {
      Name = "monster_fightflee_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "FightFleeType"
        }
      },
      Description = "\233\135\142\229\164\150\231\178\190\231\129\181\232\191\189\233\128\131\231\177\187\229\158\139"
    },
    {
      Name = "interactable_feature",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ECOLOGY_FEATURE"
        }
      },
      Description = "\229\143\175\228\186\164\228\186\146\231\154\132\231\178\190\231\129\181\231\148\159\230\128\129\231\137\185\230\128\167"
    },
    {
      Name = "throwing_interact_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "THROWING_INTERACT_TYPE"
        }
      },
      Description = "\230\138\149\230\142\183\228\186\164\228\186\146\231\177\187\229\158\139"
    },
    {
      Name = "monster_hit_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MonsterHitType"
        }
      },
      Description = "\229\143\151\229\136\176\231\178\190\231\129\181\230\148\187\229\135\187\230\151\182\231\154\132\229\147\141\229\186\148\230\150\185\229\188\143"
    },
    {
      Name = "option_id",
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
          TypeName = "NPC_OPTION_CONF",
          FieldName = "id"
        }
      },
      Description = "NPC\229\155\186\230\156\137\233\128\137\233\161\185id"
    },
    {
      Name = "reset_npc",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ResetType"
        }
      },
      Description = "\233\135\141\231\189\174NPC"
    },
    {
      Name = "reset_interval",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\229\174\154\228\185\137\230\151\182\233\151\180\233\135\141\231\189\174(\229\141\149\228\189\141:\231\167\146)"
    },
    {
      Name = "reset_in_view",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\229\156\168\232\167\134\233\135\142\232\140\131\229\155\180\229\134\133\233\135\141\231\189\174"
    },
    {
      Name = "aura_id",
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
          TypeName = "NPC_AURA_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\133\137\231\142\175ID"
    },
    {
      Name = "can_hide_in_sequence",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\129\232\174\184sequence\233\154\144\232\151\143"
    },
    {
      Name = "dont_hide_in_battle",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\228\184\173\228\184\141\232\166\129\233\154\144\232\151\143 1-\228\184\141\233\154\144\232\151\143,0/\231\169\186-\233\154\144\232\151\143"
    },
    {
      Name = "can_hide_in_player_condition",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\129\232\174\184\228\186\164\228\186\146\230\151\182\233\154\144\232\151\143"
    },
    {
      Name = "can_hide_in_minigame",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\129\232\174\184minigame\228\184\173\233\154\144\232\151\143"
    },
    {
      Name = "can_hide_in_pvp",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\129\232\174\184\229\156\168pvp\229\140\185\233\133\141\233\152\182\230\174\181\230\152\190\231\164\186"
    },
    {
      Name = "aoi_weight",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "aoi\230\152\190\231\164\186\230\157\131\229\128\188\239\188\140\232\161\168\231\164\186\229\144\142\231\171\175\231\187\153\229\137\141\231\171\175\228\184\139\229\143\145\231\154\132Npc\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "traverse_data_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "Traverse_Data_Type"
        }
      },
      Description = "\229\143\141\230\159\165\230\149\176\230\141\174\231\177\187\229\158\139"
    },
    {
      Name = "traverse_data_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "traverse_data_type",
          Branches = {
            {
              Value = 1,
              TypeName = "PETBASE_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "BAG_ITEM_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "PETBASE_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\141\230\159\165petbase\230\149\176\230\141\174\229\143\130\230\149\176"
    },
    {
      Name = "is_levelup_manual",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\137\139\229\138\168\229\141\135\231\186\167 \239\188\1360/\228\184\141\229\161\171=\233\154\143\232\167\146\232\137\178\231\173\137\231\186\167\230\143\144\229\141\135\232\135\170\229\138\168\229\141\135\231\186\167\239\188\1551=\228\184\141\233\154\143\232\167\146\232\137\178\231\173\137\231\186\167\230\143\144\229\141\135"
    },
    {
      Name = "battle_ai",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\229\134\133AI \239\188\136\229\143\170\230\156\137\230\136\152\230\150\151\229\134\133\231\148\168\229\136\176\231\154\132NPC\230\137\141\228\188\154\232\176\131\231\148\168\239\188\137"
    },
    {
      Name = "auto_escape",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NPCAutoEscapeType"
        }
      },
      Description = "\232\135\170\229\138\168\233\128\131\232\183\145\230\158\154\228\184\190\231\177\187\229\158\139"
    },
    {
      Name = "escape_params",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\135\170\229\138\168\233\128\131\232\183\145\229\143\130\230\149\176"
    },
    {
      Name = "escape_dialogue",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\135\170\229\138\168\233\128\131\232\183\145\233\149\156\229\164\180"
    },
    {
      Name = "overtime_action",
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
          TypeName = "NPC_CONF_overtime_action"
        }
      },
      Description = "\232\182\133\230\151\182\230\143\144\233\134\146\229\138\159\232\131\189\239\188\136\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142\239\188\137"
    },
    {
      Name = "npc_skill",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "NPC\231\154\132\228\184\187\232\167\146\230\138\128\232\131\189"
    },
    {
      Name = "trace_icon_offset",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\191\189\232\184\170\229\155\190\230\160\135\233\171\152\229\186\166\228\191\174\230\173\163"
    },
    {
      Name = "world_nature",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldNature"
        }
      },
      Description = "\229\164\167\228\184\150\231\149\140\230\128\167\230\160\188"
    },
    {
      Name = "mimic_target",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MODEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\185\187\229\140\150\229\175\185\232\177\161ID"
    },
    {
      Name = "mimic_skill",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\186\164\228\186\146\229\185\187\229\140\150\232\191\155\230\136\152\230\138\128\232\131\189"
    },
    {
      Name = "world_hide",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldHide"
        }
      },
      Description = "\229\140\191\232\184\170\231\138\182\230\128\129\231\177\187\229\158\139"
    },
    {
      Name = "world_hide_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\140\191\232\184\170\229\143\130\230\149\176"
    },
    {
      Name = "ai_group_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 6
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_CONF_ai_group_param"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "nightmare_ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\153\169\230\162\166\229\140\150\229\144\142\231\154\132\231\190\164\232\144\189ID"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\153\169\230\162\166\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189(\230\150\176\239\188\137"
    },
    {
      Name = "is_clean_ani",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\232\175\157\231\187\147\230\157\159\229\144\142\230\152\175\229\144\166\230\184\133\231\144\134\229\138\168\231\148\187"
    },
    {
      Name = "is_ai_loading_high_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\171\152\228\188\152\229\133\136\229\144\175\229\138\168\232\175\165NPC\231\154\132ai"
    },
    {
      Name = "is_pve_npc_around",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\188\154\228\189\156\228\184\186PVE\229\155\180\232\167\130NPC"
    },
    {
      Name = "special_audio_tag",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SpecialAudioTag"
        }
      },
      Description = "\232\175\165NPC\229\144\175\231\148\168\231\154\132\231\137\185\230\174\138\233\159\179\232\189\168"
    },
    {
      Name = "freeze_movement_when_spawn",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\179\233\151\173\231\167\187\229\138\168\231\187\132\228\187\182"
    },
    {
      Name = "npc_trampling_lawn_comp",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TramplingLawnComp"
        }
      },
      Description = "NPC\232\184\169\232\184\143\232\141\137\229\156\176\231\187\132\228\187\182"
    },
    {
      Name = "npc_role_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetRoleTypeInNPCConf"
        }
      },
      Description = "NPC\229\136\134\231\177\187"
    },
    {
      Name = "ai_random_pool_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_PERFORM_POOL_CONF",
          FieldName = "id"
        }
      },
      Description = "AI\232\161\140\228\184\186\231\187\132\233\154\143\230\156\186\230\177\160ID"
    },
    {
      Name = "opacity_rate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\164\150\232\167\130\228\184\141\233\128\143\230\152\142\229\186\166\239\188\136\228\184\138\233\153\14410000=100%\239\188\137"
    },
    {
      Name = "fresnel_color",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\157\144\232\180\168\230\179\155\229\133\137\233\162\156\232\137\178(RGB)"
    },
    {
      Name = "fresnel_intensity",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\157\144\232\180\168\230\179\155\229\133\137\229\188\186\229\186\166\239\188\136\228\184\138\233\153\14410000=100%\239\188\137"
    },
    {
      Name = "fresnel_exponent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\157\144\232\180\168\230\179\155\229\133\137\232\166\134\231\155\150\231\142\135\239\188\136\228\184\138\233\153\14410000=100%\239\188\137"
    }
  }
}
RTTIManager:RegisterType(NPC_CONF.Name, NPC_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NPC_OPTION_CONF = {
  Name = "NPC_OPTION_CONF",
  Version = 1,
  Description = "NPC_OPTION_CONF\239\188\136NPC\233\128\137\233\161\185\233\133\141\231\189\174\232\161\168\239\188\137\230\152\175\230\184\184\230\136\143\228\187\187\229\138\161\231\179\187\231\187\159\228\184\173\231\148\168\228\186\142\229\174\154\228\185\137\229\146\140\231\174\161\231\144\134\230\137\128\230\156\137\228\186\164\228\186\146\232\161\140\228\184\186\231\154\132\230\160\184\229\191\131\233\133\141\231\189\174\232\161\168\239\188\140\229\174\131\231\155\184\229\189\147\228\186\142\230\184\184\230\136\143\228\184\150\231\149\140\229\134\133\229\144\132\231\167\141\228\186\146\229\138\168\230\147\141\228\189\156\231\154\132\226\128\156\230\140\135\228\187\164\233\155\134\226\128\157\227\128\130",
  Metadata = {
    Alias = "\228\186\164\228\186\146\232\161\168\227\128\129opt\227\128\129option\227\128\129NPC\230\156\141\229\138\161",
    RelativeYamlPath = "npc/NPC_OPTION_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\233\128\137\233\161\185id"
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
      Name = "npc_aim_display",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NPC_AIM_DISPLAY"
        }
      },
      Description = "\231\178\190\231\129\181\230\138\149\230\142\183\231\158\132\229\135\134\230\151\182\231\154\132\229\135\134\230\152\159\231\177\187\229\158\139\239\188\140\231\189\174\231\169\186\230\151\182\233\187\152\232\174\164\228\184\186NAD_NORMAL\239\188\140\230\152\190\231\164\186\228\184\186\228\184\141\229\143\175\228\186\164\228\186\146\239\188\140\229\135\134\230\152\159\230\152\190\231\164\186\228\184\186\231\169\186"
    },
    {
      Name = "online_process",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OnlineVisitProcess"
        }
      },
      Description = "\232\129\148\230\156\186\231\138\182\230\128\129\228\184\139\230\152\175\229\144\166\229\143\175\229\174\140\230\136\144\239\188\136\232\167\146\232\137\178\228\184\142NPC\228\186\164\228\186\146\239\188\137"
    },
    {
      Name = "online_process_same_time",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OnlineVisitProcessCoop"
        }
      },
      Description = "\230\152\175\229\144\166\229\143\175\229\164\154\228\186\186\229\144\140\230\151\182\228\186\164\228\186\146"
    },
    {
      Name = "online_hidden_forbid_options",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\143\175\228\186\164\228\186\146\231\154\132\229\137\141\230\143\144\228\184\139\239\188\140\229\141\149\230\156\186\228\184\139\230\156\137option\231\154\132\230\152\175\229\144\166\233\154\144\232\151\143\228\186\164\228\186\146\233\128\137\233\161\185\239\188\136\229\146\149\229\153\156\231\144\131\228\184\141\230\152\190\231\164\186\233\133\1411\239\188\140\229\184\184\232\167\132NPC\230\152\190\231\164\186\239\188\137"
    },
    {
      Name = "IgnoreTaskVisitRules",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\177\129\229\133\141\239\188\154\232\162\171\228\187\187\229\138\161\232\176\131\231\148\168\229\136\153\232\135\170\229\138\168\232\176\131\230\149\180\228\186\164\228\186\146\232\167\132\229\136\153\228\184\186OVP_ONLY_OWNER\239\188\140\229\133\172\229\133\177opt\229\191\133\233\161\187\229\161\171true"
    },
    {
      Name = "initial_state",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\136\157\229\167\139\229\133\179\233\151\173\239\188\136\233\187\152\232\174\164\229\188\128\229\144\175\239\188\140\229\143\175\228\184\186\231\169\186\239\188\155\229\161\171true\229\136\153\229\136\157\229\167\139\229\133\179\233\151\173\239\188\140\228\187\187\229\138\161\231\148\168\239\188\137"
    },
    {
      Name = "scene_res_whitelist",
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
      Description = "\229\164\167\228\184\150\231\149\140\229\156\186\230\153\175\231\153\189\229\144\141\229\141\149\239\188\136\232\139\165\229\161\171\229\134\153\228\186\134\231\153\189\229\144\141\229\141\149\239\188\140\229\136\153\232\175\165option\229\143\170\229\156\168\228\187\165\228\184\139\229\156\186\230\153\175\231\148\159\230\149\136"
    },
    {
      Name = "scene_res_blacklist",
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
      Description = "\229\164\167\228\184\150\231\149\140\229\156\186\230\153\175\233\187\145\229\144\141\229\141\149\239\188\136\232\139\165\229\161\171\229\134\153\228\186\134\233\187\145\229\144\141\229\141\149\239\188\140\229\136\153\232\175\165option\229\143\170\229\156\168\228\187\165\228\184\139\229\156\186\230\153\175\228\184\141\231\148\159\230\149\136"
    },
    {
      Name = "option_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "option_auto",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\135\170\229\138\168\230\137\167\232\161\140"
    },
    {
      Name = "option_skip",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "1.  option\230\152\175\229\144\166\229\143\175\232\191\155\232\161\140\229\175\185\232\175\157\232\183\179\232\191\135\239\188\136\233\187\152\232\174\164\228\184\1860\239\188\140\232\161\168\231\164\186\228\184\141\229\143\175\232\183\179\232\189\172\239\188\140\229\161\1711\232\161\168\231\164\186\229\143\175\232\183\179\232\191\135\239\188\137"
    },
    {
      Name = "dialogue_transmission_2P",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\232\175\157\232\161\168\230\188\148\230\152\175\229\144\166\228\184\141\229\144\140\230\173\1652P\239\188\136\233\187\152\232\174\164\228\184\186false\239\188\140\233\133\141\231\189\174true\229\136\153\228\184\141\229\144\140\230\173\165\239\188\137"
    },
    {
      Name = "excute_delay",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\137\167\232\161\140\229\144\142\229\187\182\232\191\159(ms\239\188\137"
    },
    {
      Name = "logic_status_whitelist",
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
          EnumName = "SpaceActorLogicStatus"
        }
      },
      Description = "\233\128\137\233\161\185\230\191\128\230\180\187\233\128\187\232\190\145\231\138\182\230\128\129\231\153\189\229\144\141\229\141\149"
    },
    {
      Name = "logic_status_require_num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\156\128\232\166\129\230\187\161\232\182\179\231\153\189\229\144\141\229\141\149\228\184\173\233\128\187\232\190\145\231\138\182\230\128\129\228\184\170\230\149\176"
    },
    {
      Name = "logic_status_blacklist",
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
          EnumName = "SpaceActorLogicStatus"
        }
      },
      Description = "\233\128\137\233\161\185\230\191\128\230\180\187\233\128\187\232\190\145\231\138\182\230\128\129\233\187\145\229\144\141\229\141\149"
    },
    {
      Name = "use_vistor_story_flags",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\186\146\232\174\191\231\138\182\230\128\129\228\184\139\230\152\175\229\144\166\228\189\191\231\148\168\232\174\191\229\174\162\232\186\171\228\184\138\231\154\132\229\137\167\230\131\133\230\160\135\229\191\151\230\142\167\229\136\182\230\191\128\230\180\187\230\157\161\228\187\182\239\188\136\229\144\166\229\136\153\228\189\191\231\148\168\230\136\191\228\184\187\231\154\132\229\137\167\230\131\133\230\160\135\232\174\176\239\188\137"
    },
    {
      Name = "story_flag_whitelist",
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
          EnumName = "PlayerStoryFlagEnum"
        }
      },
      Description = "\233\128\137\233\161\185\230\191\128\230\180\187\229\137\167\230\131\133\230\160\135\232\174\176\231\153\189\229\144\141\229\141\149"
    },
    {
      Name = "story_flag_require_num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\156\128\232\166\129\230\187\161\232\182\179\231\153\189\229\144\141\229\141\149\229\137\167\230\131\133\230\160\135\232\174\176\231\154\132\228\184\170\230\149\176"
    },
    {
      Name = "story_flag_blacklist",
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
          EnumName = "PlayerStoryFlagEnum"
        }
      },
      Description = "\233\128\137\233\161\185\230\191\128\230\180\187\229\137\167\230\131\133\230\160\135\232\174\176\233\187\145\229\144\141\229\141\149"
    },
    {
      Name = "option_sequence",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\230\142\146\229\186\143 \239\188\136\230\149\176\229\173\151\229\164\167\230\142\146\228\184\138\230\150\185\239\188\137 \239\188\136\228\184\141\229\161\171\233\187\152\232\174\164\228\184\1860\239\188\137"
    },
    {
      Name = "stamina_cost",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\230\182\136\232\128\151\228\189\147\229\138\155\229\128\188"
    },
    {
      Name = "pet_interact_radius",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\138\149\230\142\183\228\186\164\228\186\146\231\154\132\229\141\138\229\190\132\232\183\157\231\166\187"
    },
    {
      Name = "pet_fight_radius",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\138\149\230\142\183\232\191\155\230\136\152\231\154\132\229\141\138\229\190\132\232\183\157\231\166\187"
    },
    {
      Name = "npc_interaction_show_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\228\186\164\228\186\146\230\143\144\231\164\186\230\152\190\231\164\186\232\140\131\229\155\180"
    },
    {
      Name = "option_radius",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\228\186\164\228\186\146UI\231\154\132\229\141\138\229\190\132\232\183\157\231\166\187"
    },
    {
      Name = "cancel_option_radius",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\143\150\230\182\136\228\186\164\228\186\146UI\231\154\132\229\141\138\229\190\132\232\183\157\231\166\187"
    },
    {
      Name = "vision_range",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\228\186\164\228\186\146UI\231\154\132\231\142\169\229\174\182\232\167\134\233\148\165\232\140\131\229\155\180"
    },
    {
      Name = "option_hight",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\228\186\164\228\186\146UI\231\154\132Z\232\189\180\232\140\131\229\155\180"
    },
    {
      Name = "vision_range_npc",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\186\164\228\186\146\231\154\132npc\230\176\180\229\185\179\231\148\159\230\149\136\232\167\146\229\186\166\239\188\136\230\151\160\230\149\136\229\173\151\230\174\181\239\188\137"
    },
    {
      Name = "vision_Z_range_npc",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\231\154\132npcZ\232\189\180\231\148\159\230\149\136\232\167\146\229\186\166\239\188\136\230\151\160\230\149\136\229\173\151\230\174\181\239\188\137"
    },
    {
      Name = "option_effective_angle",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\186\164\228\186\146\231\154\132\232\167\146\229\186\166\232\140\131\229\155\180"
    },
    {
      Name = "option_Z_effective_angle",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\231\154\132Z\232\189\180\232\167\146\229\186\166\232\140\131\229\155\180"
    },
    {
      Name = "option_area",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\187\133\231\137\185\229\174\154AREA\229\134\133\230\152\190\231\164\186OPTION"
    },
    {
      Name = "option_enable_condition",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OptionVisibleCondition"
        }
      },
      Description = "\228\186\164\228\186\146\230\152\190\231\164\186\230\157\161\228\187\182"
    },
    {
      Name = "option_enable_condition_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "option_enable_condition",
          Branches = {
            {
              Value = 1,
              TypeName = "WEATHER_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "WEATHER_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\228\186\164\228\186\146\230\152\190\231\164\186\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "npc_interact_condition",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "InteractConditionType"
        }
      },
      Description = "NPC\228\186\164\228\186\146\230\157\161\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "npc_interact_condition_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "NPC\228\186\164\228\186\146\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "npc_seat_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\161\171\229\134\153npc\228\186\164\228\186\146\229\140\186id"
    },
    {
      Name = "pet_ride_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RidePetCollect"
        }
      },
      Description = "\233\170\145\228\185\152\232\135\170\229\138\168\233\135\135\233\155\134\231\177\187\229\158\139"
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
      Name = "interact_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\228\186\164\228\186\146\231\177\187\229\158\139\229\143\130\230\149\1761"
    },
    {
      Name = "button_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\230\140\137\233\146\174ICON\230\160\183\229\188\143"
    },
    {
      Name = "button_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "optiontext"
        }
      },
      Description = "\230\140\137\233\146\174\230\150\135\230\156\172\232\166\134\231\155\150\239\188\136\230\150\176\229\162\158\239\188\137"
    },
    {
      Name = "show_option_rotation",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\231\154\132\232\167\146\229\186\166\232\140\131\229\155\180\239\188\136\230\151\167\239\188\137"
    },
    {
      Name = "button_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ButtonType"
        }
      },
      Description = "\230\140\137\233\146\174\230\160\183\229\188\143\239\188\136\230\150\176\229\162\158\239\188\137"
    },
    {
      Name = "enablefix_angle",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\144\175\231\148\168NPC\230\156\157\229\144\145\228\191\174\230\173\163"
    },
    {
      Name = "enablefix_distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\144\175\231\148\168\228\189\141\231\189\174\228\191\174\230\173\163"
    },
    {
      Name = "fix_distance",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\191\174\230\173\163\231\171\153\228\189\141\232\183\157\231\166\187\239\188\136\230\150\176\229\162\158\239\188\137"
    },
    {
      Name = "fix_rotation",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\191\174\230\173\163\231\171\153\228\189\141\230\156\157\229\144\145"
    },
    {
      Name = "unmount_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "UnmountType"
        }
      },
      Description = "\228\186\164\228\186\146\229\137\141\230\152\175\229\144\166\232\166\129\228\184\139\229\157\144\233\170\145"
    },
    {
      Name = "break_holdhands",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\150\173\229\188\128\231\137\181\230\137\139\239\188\136\233\187\152\232\174\164\231\169\186\230\136\150false\228\184\186\228\184\141\230\150\173\229\188\128\239\188\140true\228\184\186\230\150\173\229\188\128\239\188\137"
    },
    {
      Name = "action",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_OPTION_CONF_action"
        }
      },
      Description = "\231\142\169\229\174\182\228\186\164\228\186\146action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137"
    },
    {
      Name = "online_process_pet",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OnlineVisitProcess"
        }
      },
      Description = "\232\129\148\230\156\186\231\138\182\230\128\129\228\184\139\230\152\175\229\144\166\229\143\175\229\174\140\230\136\144\239\188\136\231\178\190\231\129\181\228\184\142NPC\228\186\164\228\186\146\239\188\137"
    },
    {
      Name = "pet_action",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_OPTION_CONF_pet_action"
        }
      },
      Description = "\229\174\160\231\137\169\228\186\164\228\186\146Action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137"
    },
    {
      Name = "pet_power_dash_action",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_OPTION_CONF_pet_power_dash_action"
        }
      },
      Description = "\229\174\160\231\137\169\229\134\178\230\146\158\228\186\164\228\186\146Action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137"
    },
    {
      Name = "online_process_magic",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OnlineVisitProcess"
        }
      },
      Description = "\232\129\148\230\156\186\231\138\182\230\128\129\228\184\139\230\152\175\229\144\166\229\143\175\229\174\140\230\136\144\239\188\136\230\142\162\233\153\169\233\173\148\230\179\149\228\184\142NPC\228\186\164\228\186\146\239\188\137"
    },
    {
      Name = "wild_action",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_OPTION_CONF_wild_action"
        }
      },
      Description = "\233\135\142\229\164\150\231\178\190\231\129\181\228\186\164\228\186\146Action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137"
    },
    {
      Name = "magic_interact_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MAGIC_INTERACT_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\173\148\230\179\149\228\186\164\228\186\146id\231\180\162\229\188\149"
    },
    {
      Name = "option_times",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\229\143\175\230\137\167\232\161\140\230\172\161\230\149\176"
    },
    {
      Name = "times_decrease_cond",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcOptTimesDecCond"
        }
      },
      Description = "\233\128\146\229\135\143\230\157\161\228\187\182\239\188\136\230\128\142\228\185\136\231\174\151\229\174\140\230\136\144\228\184\128\230\172\161\230\137\167\232\161\140\239\188\137"
    },
    {
      Name = "times_decrease_cond_params",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\128\146\229\135\143\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "reset_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OptionResetType"
        }
      },
      Description = "\233\135\141\231\189\174\230\150\185\229\188\143"
    },
    {
      Name = "reset_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\233\135\141\231\189\174\230\151\182\233\151\180,"
    },
    {
      Name = "cooldown_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcOptionCooldownType"
        }
      },
      Description = "CD\231\177\187\229\158\139"
    },
    {
      Name = "cooldown_reset_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "CD\233\135\141\231\189\174\230\151\182\233\151\180"
    },
    {
      Name = "available_times_in_cooldown",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\184\128\230\172\161CD\230\156\128\229\164\167\229\143\175\231\148\168\230\172\161\230\149\176"
    },
    {
      Name = "option_deletnpc",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\239\188\140\230\152\175\229\144\166\229\136\160\233\153\164\230\137\128\229\177\158Npc"
    },
    {
      Name = "delete_content",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\239\188\140\230\152\175\229\144\166\229\136\160\233\153\164\230\137\128\229\177\158Npc\231\154\132\229\136\183\230\150\176content"
    },
    {
      Name = "option_deleteself",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\232\135\170\229\138\168\229\136\160\233\153\164option"
    },
    {
      Name = "option_deletnpc_times",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\142\146\230\150\165\229\144\140Npc\229\133\182\229\174\131Options\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\231\154\132\229\136\160\233\153\164(\229\191\133\233\161\187\230\173\164\233\161\185\228\184\1860\230\137\141\232\131\189\229\136\160\233\153\164)"
    },
    {
      Name = "option_tiems_done",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\183\178\230\137\167\232\161\140option\231\154\132\230\172\161\230\149\176"
    },
    {
      Name = "option_changestatus",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\137\167\232\161\140\229\175\185\229\186\148\230\172\161\230\149\176\229\144\142\232\166\129\230\148\185\229\143\152\230\136\144\231\154\132\231\138\182\230\128\129"
    },
    {
      Name = "option_restart_dialogue",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\184\128\230\172\161option\230\137\167\232\161\140\229\174\140\230\136\144\229\144\142\239\188\140\228\184\139\230\172\161option\230\152\175\229\144\166\229\155\158\229\136\176\231\172\172\228\184\128\229\143\165\229\175\185\232\175\157\233\135\141\230\150\176\229\188\128\229\167\139"
    },
    {
      Name = "exp_reward_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\187\143\233\170\140\229\165\150\229\138\177\231\177\187\229\158\139\239\188\154 1\228\184\186\229\165\150\229\138\177\231\187\153\229\133\168\233\152\159 2\228\184\186\229\165\150\229\138\177\231\187\153\229\141\149\229\143\170\230\138\149\230\142\183\231\178\190\231\129\181"
    },
    {
      Name = "exp_reward_value",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\229\138\177\231\154\132\229\133\183\228\189\147\231\187\143\233\170\140\229\128\188"
    },
    {
      Name = "ignore_reset",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\229\174\140\230\136\144\229\144\142\228\184\141\229\134\141\230\137\167\232\161\140\233\128\137\233\161\185\230\149\176\230\141\174\233\135\141\231\189\174\233\128\187\232\190\145"
    },
    {
      Name = "trigger_guide",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\230\156\186\229\133\179\230\152\190\231\164\186"
    },
    {
      Name = "is_collect_option",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\184\170\228\186\186\229\144\141\231\137\135\231\178\190\231\129\181\228\186\164\228\186\146\233\135\135\233\155\134\232\174\161\230\172\161"
    },
    {
      Name = "touch_battle_cd",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\142\165\232\167\166\232\191\155\229\133\165\230\136\152\230\150\151CD"
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
      Name = "system_control_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SYSTEMCONTROLCONFIG",
          FieldName = "id"
        }
      },
      Description = "\231\187\159\228\184\128\229\177\143\232\148\189ID"
    }
  }
}
RTTIManager:RegisterType(NPC_OPTION_CONF.Name, NPC_OPTION_CONF)

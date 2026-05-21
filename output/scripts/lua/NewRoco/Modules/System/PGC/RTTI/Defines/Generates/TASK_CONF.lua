local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TASK_CONF = {
  Name = "TASK_CONF",
  Version = 1,
  Description = "task_conf  \239\188\136\228\187\187\229\138\161\233\133\141\231\189\174\232\161\168\239\188\137\230\152\175\230\184\184\230\136\143\228\187\187\229\138\161\231\179\187\231\187\159\231\154\132\230\160\184\229\191\131\230\161\134\230\158\182\232\161\168\239\188\140\229\174\131\229\174\154\228\185\137\228\186\134\228\187\187\229\138\161\231\154\132\230\149\180\228\189\147\231\187\147\230\158\132\227\128\129\231\155\174\230\160\135\227\128\129\230\181\129\231\168\139\232\167\132\229\136\153\228\187\165\229\143\138\228\184\142\229\133\182\228\187\150\231\179\187\231\187\159\231\154\132\228\186\164\228\186\146\230\150\185\229\188\143\227\128\130",
  Metadata = {
    Alias = "\228\187\187\229\138\161\232\161\168\227\128\129\228\187\187\229\138\161\227\128\129\228\187\187\229\138\161\233\133\141\231\189\174\232\161\168\227\128\129\228\187\187\229\138\161\231\187\147\230\158\132\227\128\129\228\187\187\229\138\161\230\149\176\230\141\174",
    RelativeYamlPath = "task/TASK_CONF.yaml",
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
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 200000000}
          }
        }
      },
      Description = "\228\187\187\229\138\161ID"
    },
    {
      Name = "story_bgm_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "STORY_BGM_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\187\187\229\138\161\233\159\179\233\162\145id"
    },
    {
      Name = "influence_area_func_id",
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
      Description = "\231\148\159\230\149\136\229\140\186\229\159\159"
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
      Description = "\228\187\187\229\138\161\230\160\135\233\162\152"
    },
    {
      Name = "task_class",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskClassType"
        }
      },
      Description = "\228\187\187\229\138\161\231\177\187\229\158\139"
    },
    {
      Name = "paragraph_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PARAGRAPH_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\232\138\130ID"
    },
    {
      Name = "res_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\231\171\139\231\187\152\232\183\175\229\190\132"
    },
    {
      Name = "belong_place",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "belongplace"
        }
      },
      Description = "\228\187\187\229\138\161\229\156\176\231\130\185\230\166\130\232\191\176"
    },
    {
      Name = "task_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "task_des"
        }
      },
      Description = "\228\187\187\229\138\161\230\166\130\232\191\176[\230\152\190\231\164\186\229\156\168\228\187\187\229\138\161\233\157\162\230\157\191\231\154\132\228\184\187\232\166\129\230\150\135\230\156\172\239\188\140\229\144\140\228\184\128\228\184\170\228\187\187\229\138\161\232\138\130\228\184\173\239\188\140\228\188\154\231\148\168\230\150\176\231\154\132\228\187\187\229\138\161\230\166\130\232\191\176\232\166\134\231\155\150\232\128\129\231\154\132\228\187\187\229\138\161\230\166\130\232\191\176]"
    },
    {
      Name = "task_structure_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStructureType"
        }
      },
      Description = "\228\187\187\229\138\161\231\187\147\230\158\132\231\177\187\229\158\139\239\188\136\229\175\185\232\175\157\227\128\129\230\136\152\230\150\151\227\128\129\228\188\160\233\128\129\227\128\129\230\146\173\231\137\135\239\188\137"
    },
    {
      Name = "task_special_structure_area",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "X",
          EnumName = "SCENE_CONF",
          LinkFieldName = "Y"
        }
      },
      Description = "\231\137\185\230\174\138\231\187\147\230\158\132\231\177\187\229\158\139\239\188\140\228\188\160\233\128\129&\230\146\173\231\137\135\230\142\165\229\143\150\232\161\140\228\184\186\232\167\166\229\143\145\229\140\186\229\159\159"
    },
    {
      Name = "rewrite",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\151\133\233\128\148\228\187\187\229\138\161\229\174\140\230\136\144\230\166\130\232\191\176\227\128\144\229\186\159\229\188\131\227\128\145"
    },
    {
      Name = "task_gameplay1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\231\177\187\229\158\139\229\143\130\230\149\1761"
    },
    {
      Name = "task_gameplay2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\231\177\187\229\158\139\229\143\130\230\149\1762"
    },
    {
      Name = "open",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\139\230\158\182\228\187\187\229\138\161"
    },
    {
      Name = "show",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\154\144\232\151\143\228\187\187\229\138\161"
    },
    {
      Name = "new_task",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TrackNewTask"
        }
      },
      Description = "\230\152\175\229\144\166\230\143\144\231\164\186\230\150\176\228\187\187\229\138\161\239\188\136\228\187\187\229\138\161\230\160\143\239\188\137"
    },
    {
      Name = "is_para_start",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\232\138\130\232\181\183\229\167\139"
    },
    {
      Name = "track_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\174\140\230\136\144\229\144\142\232\191\189\232\184\170\229\155\190\230\160\135\230\155\191\230\141\162"
    },
    {
      Name = "is_track",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\230\152\190\231\164\186\232\191\189\232\184\170\230\140\137\233\146\174"
    },
    {
      Name = "accept_condition",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 3
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TASK_CONF_accept_condition"
        }
      },
      Description = "\230\142\165\229\143\150\230\157\161\228\187\182\233\133\141\231\189\174"
    },
    {
      Name = "next_task_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NextTaskType"
        }
      },
      Description = "\229\144\142\231\187\173\228\187\187\229\138\161\231\177\187\229\158\139"
    },
    {
      Name = "next_task",
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
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\144\142\231\187\173\228\187\187\229\138\161ID"
    },
    {
      Name = "token_next_task",
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
          TypeName = "TASK_CONF_token_next_task"
        }
      },
      Description = "\229\144\142\231\187\173\230\188\134\229\141\176\228\187\187\229\138\161\230\149\176\233\135\143"
    },
    {
      Name = "extra_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\162\157\229\164\150\229\174\140\230\136\144\230\162\151\230\166\130"
    },
    {
      Name = "task_reset_cycle",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStoreType"
        }
      },
      Description = "\228\187\187\229\138\161\233\135\141\231\189\174\229\145\168\230\156\159"
    },
    {
      Name = "open_num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\143\175\233\135\141\229\164\141\229\174\140\230\136\144\230\172\161\230\149\176"
    },
    {
      Name = "accept_guide",
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
          TypeName = "TASK_CONF_accept_guide"
        }
      },
      Description = "\230\142\165\229\143\150\230\140\135\229\188\149"
    },
    {
      Name = "advance_finish_data",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\230\152\175\229\144\166\228\189\191\231\148\168\232\167\163\233\148\129\229\137\141\231\154\132\229\142\134\229\143\178\230\149\176\230\141\174\229\174\140\230\136\144\239\188\154 ================ 0\230\136\150\231\169\186=\228\187\133\231\155\145\229\144\172\232\167\163\233\148\129\228\187\187\229\138\161\229\144\142\230\150\176\229\162\158\231\154\132\230\149\176\230\141\174\239\188\155 1=\232\176\131\231\148\168\228\187\187\229\138\161\232\167\163\233\148\129\229\137\141\231\154\132\229\142\134\229\143\178\230\149\176\230\141\174 ================ "
    },
    {
      Name = "task_condition",
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
          TypeName = "TASK_CONF_task_condition"
        }
      },
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\230\149\176\233\135\143"
    },
    {
      Name = "key_content_id",
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
      Description = "\229\189\147\228\187\187\229\138\161\229\174\140\230\136\144\228\190\157\232\181\150\231\154\132content\239\188\140\228\184\142\228\187\187\229\138\161\232\191\189\232\184\170Content\228\184\141\228\184\128\232\135\180\230\151\182\239\188\140\233\162\157\229\164\150\233\133\141\231\189\174\231\156\159\229\174\158\228\186\164\228\186\146\231\154\132Content id"
    },
    {
      Name = "go_guide",
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
          TypeName = "TASK_CONF_go_guide"
        }
      },
      Description = "GO\232\161\140\228\184\186\230\149\176\233\135\143"
    },
    {
      Name = "image_combination",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskImageType"
        }
      },
      Description = "\229\155\190\231\137\135\230\142\146\231\137\136\230\160\188\229\188\143"
    },
    {
      Name = "task_image",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\174\140\230\136\144\229\144\142\230\143\146\229\133\165\229\155\190\231\137\135"
    },
    {
      Name = "auto_finish",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\135\170\229\138\168\233\162\134\229\143\150\229\165\150\229\138\177"
    },
    {
      Name = "Reward",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "rewardID"
    },
    {
      Name = "reward_state",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\138\130\229\165\150\229\138\177\231\138\182\230\128\129"
    },
    {
      Name = "message_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MESSAGE_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\191\161\228\187\182ID"
    },
    {
      Name = "refresh_content",
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
      Description = "\228\187\187\229\138\161\230\142\165\229\143\150\230\151\182\229\188\128\229\144\175 \228\187\187\229\138\161\233\162\134\229\165\150\230\151\182\229\133\179\233\151\173"
    },
    {
      Name = "npc_option",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TASK_CONF_npc_option"
        }
      },
      Description = ""
    },
    {
      Name = "accept_action",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 18
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TASK_CONF_accept_action"
        }
      },
      Description = "\230\142\165\229\143\151\228\187\187\229\138\161\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "finish_action",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 18
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TASK_CONF_finish_action"
        }
      },
      Description = "\229\174\140\230\136\144\228\187\187\229\138\161\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "reward_action",
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
          TypeName = "TASK_CONF_reward_action"
        }
      },
      Description = "\228\187\187\229\138\161\233\162\134\229\165\150\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "battle_ability",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\138\159\232\131\189\231\166\129\230\173\162"
    },
    {
      Name = "revive_point",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\164\141\230\180\187\231\130\185"
    },
    {
      Name = "peer_available",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\174\191\229\174\162\229\143\175\229\156\168\230\136\191\228\184\187\228\184\150\231\149\140\229\174\140\230\136\144\230\173\164\228\187\187\229\138\161"
    },
    {
      Name = "online_forbid",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "TRUE:\228\184\141\229\143\175\232\191\155\229\133\165\232\129\148\230\156\186"
    },
    {
      Name = "online_process",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OnlineVisitProcess"
        }
      },
      Description = "\232\129\148\230\156\186\231\138\182\230\128\129\228\184\139\230\152\175\229\144\166\229\143\175\229\174\140\230\136\144 OVP_BOTH_FORBIDED  \230\136\150\231\169\186 /\228\184\164\232\128\133\229\157\135\228\184\141\232\131\189\229\174\140\230\136\144 OVP_ONLY_OWNER  \229\143\170\230\136\191\228\184\187\230\137\141\232\131\189\229\174\140\230\136\144 OVP_BOTH   \230\136\191\228\184\187\232\174\191\229\174\162\233\131\189\229\143\175\228\187\165\232\191\155\232\161\140\232\175\165\228\187\187\229\138\161"
    },
    {
      Name = "online_forbid_receive_task",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\129\148\230\156\186\228\184\139\230\151\160\230\179\149\230\142\165\229\143\150\232\175\165\228\187\187\229\138\161\239\188\136\233\133\1411\229\136\153\232\129\148\230\156\186\230\151\160\230\179\149\230\142\165\229\143\150\239\188\137"
    },
    {
      Name = "task_flag",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\233\157\158next_task\232\161\148\230\142\165"
    },
    {
      Name = "map_avatar",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\180\229\131\143\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "is_break_task",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\228\184\173\230\150\173\228\187\187\229\138\161"
    },
    {
      Name = "is_para_done",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\174\140\230\136\144\228\187\187\229\138\161\232\138\130"
    },
    {
      Name = "receive_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "receivemsg"
        }
      },
      Description = "\230\148\182\228\191\161\230\151\182\232\191\189\232\184\170\230\160\143\230\143\144\231\164\186"
    },
    {
      Name = "task_system_item",
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
      Description = "\231\179\187\231\187\159\231\142\169\230\179\149\233\129\147\229\133\183"
    },
    {
      Name = "task_system_cmd",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "CLIENT_PUBLIC_CMD",
          FieldName = "text"
        }
      },
      Description = "\231\179\187\231\187\159\231\142\169\230\179\149\232\183\179\232\189\172\230\140\135\228\187\164"
    },
    {
      Name = "taskswitch_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_SWITCH_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\187\187\229\138\161\229\188\128\229\133\179id \231\148\168\228\185\139\229\137\141\229\146\140downeyzhang\231\161\174\232\174\164\239\188\137"
    },
    {
      Name = "accept_condition_record",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "x",
          EnumName = "SCENE_CONF",
          LinkFieldName = "x"
        }
      },
      Description = "\232\162\171\229\147\170\228\186\155\228\187\187\229\138\161\231\148\168\228\189\156\230\142\165\229\143\150\230\157\161\228\187\182"
    },
    {
      Name = "failed_action",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TASK_CONF_failed_action"
        }
      },
      Description = "\230\148\190\229\188\131\228\187\187\229\138\161\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139\239\188\136\231\148\168\228\185\139\229\137\141\229\146\140downeyzhang\231\161\174\232\174\164\239\188\137"
    },
    {
      Name = "expire_time_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskExpireTimeType"
        }
      },
      Description = "\228\187\187\229\138\161\229\136\176\230\156\159\230\151\182\233\151\180\231\177\187\229\158\139"
    },
    {
      Name = "expire_time_param",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "expire_time_type",
          Branches = {
            {
              Value = 1,
              TypeName = "BAG_ITEM_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "ACTIVITY_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "SEASON_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\228\187\187\229\138\161\229\136\176\230\156\159\230\151\182\233\151\180\229\143\130\230\149\176"
    },
    {
      Name = "auto_done_when_expired",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\135\230\156\159\229\144\142\230\152\175\229\144\166\232\135\170\229\138\168\229\174\140\230\136\144\239\188\136\229\174\140\230\136\144\228\187\187\229\138\161\231\171\160\232\138\130\228\189\134\228\184\141\230\137\167\232\161\140\229\133\182\228\187\150\233\128\187\232\190\145\239\188\137"
    },
    {
      Name = "clear_data_when_expired",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\135\230\156\159\229\144\142\230\152\175\229\144\166\228\191\157\231\149\153\228\187\187\229\138\161\229\177\149\231\164\186\239\188\136\229\140\133\229\144\171\228\187\187\229\138\161\230\149\176\230\141\174\239\188\137"
    },
    {
      Name = "time_out_auto_finish",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\232\182\133\230\151\182\229\174\140\230\136\144\239\188\136\228\187\142\228\187\187\229\138\161\230\142\165\229\143\150\229\188\128\229\167\139\232\174\161\231\174\151\239\188\140\229\141\149\228\189\141\228\184\186\231\167\146\239\188\137"
    }
  }
}
RTTIManager:RegisterType(TASK_CONF.Name, TASK_CONF)

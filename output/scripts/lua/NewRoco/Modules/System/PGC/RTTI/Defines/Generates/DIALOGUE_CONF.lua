local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local DIALOGUE_CONF = {
  Name = "DIALOGUE_CONF",
  Version = 1,
  Description = "DIALOGUE_CONF\229\146\140DIALOGUE_ENV_CONF\227\128\129DIALOGUE_JOURNEY_CONF\227\128\129DIALOGUE_MAIN_CONF\227\128\129DIALOGUE_SUB_CONF\239\188\136\229\175\185\232\175\157\233\133\141\231\189\174\232\161\168\239\188\137\230\152\175\230\184\184\230\136\143\228\187\187\229\138\161\231\179\187\231\187\159\228\184\173\232\180\159\232\180\163\231\174\161\231\144\134\230\137\128\230\156\137\229\175\185\232\175\157\229\134\133\229\174\185\227\128\129\232\161\140\228\184\186\232\167\166\229\143\145\229\146\140\229\136\134\230\148\175\233\128\137\230\139\169\231\154\132\230\160\184\229\191\131\233\133\141\231\189\174\230\150\135\228\187\182\239\188\140\229\174\131\230\137\191\230\139\133\231\157\128\229\143\153\228\186\139\230\142\168\232\191\155\228\184\142\231\142\169\230\179\149\232\161\148\230\142\165\231\154\132\229\133\179\233\148\174\228\189\156\231\148\168\227\128\130",
  Metadata = {
    Alias = "\229\175\185\232\175\157\232\161\168\227\128\129DIA\227\128\129\229\137\167\230\131\133\229\175\185\232\175\157\227\128\129\229\175\185\232\175\157\230\188\148\229\135\186\227\128\129\230\139\190\233\129\151\229\175\185\232\175\157\227\128\129\230\148\175\231\186\191\229\175\185\232\175\157",
    RelativeYamlPath = "dialogue/DIALOGUE_CONF.yaml",
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
            {Min = 1, Max = 199999999}
          }
        }
      },
      Description = "\229\175\185\231\153\189ID"
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
      Name = "opt_dia_relate",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\176\131\231\148\168\230\173\164dia\231\154\132opt"
    },
    {
      Name = "is_set_first_dialogue",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\231\153\189\230\152\175\229\144\166\232\135\170\229\138\168\229\173\152\230\161\163\239\188\136\229\189\147\229\188\128\229\167\139\230\173\164\229\175\185\231\153\189\230\151\182\239\188\140\230\152\175\229\144\166\229\176\134\232\175\165\229\175\185\231\153\189\232\174\190\231\189\174\228\184\186\229\175\185\229\186\148option\231\154\132\233\166\150\229\143\165\229\175\185\231\153\189\239\188\140\229\161\171TRUE\229\176\177\230\152\175\228\188\154\232\135\170\229\138\168\228\191\157\229\173\152\239\188\137"
    },
    {
      Name = "is_auto_commit",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\139\231\186\191\230\151\182\230\152\175\229\144\166\232\135\170\229\138\168\230\142\168\232\191\155\232\175\165\229\175\185\231\153\189"
    },
    {
      Name = "speaker",
      Type = RTTIBase.FieldType.INT64,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\175\180\232\175\157\232\128\133"
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
      Description = "\229\175\185\231\153\189\230\152\190\231\164\186\228\186\186\229\144\141"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "title"
        }
      },
      Description = "\230\152\190\231\164\186\231\167\176\229\143\183"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "text"
        }
      },
      Description = "\229\175\185\231\153\189\229\134\133\229\174\185"
    },
    {
      Name = "translate_end_string",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\191\187\232\175\145\231\154\132\230\156\128\229\144\142\228\184\128\228\184\170\229\173\151\231\154\132\228\189\141\231\189\174"
    },
    {
      Name = "Column1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\231\191\187\232\175\145\230\175\143\228\184\170\229\173\151\233\151\180\233\154\148\231\154\132\230\151\182\233\151\180\239\188\136\230\149\176\231\187\132\239\188\137"
    },
    {
      Name = "dialogue_sound_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\176\232\175\141\233\159\179\233\162\145id"
    },
    {
      Name = "speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\231\153\189\233\128\159\229\186\166"
    },
    {
      Name = "text_once",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TextOnceType"
        }
      },
      Description = "\230\150\135\229\173\151\229\135\186\231\142\176\231\177\187\229\158\139"
    },
    {
      Name = "ui_source",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\231\153\189UI\232\181\132\230\186\144\229\144\141"
    },
    {
      Name = "ui_source_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "UIsourceType"
        }
      },
      Description = "\229\175\185\231\153\189\232\181\132\230\186\144\231\177\187\229\158\139"
    },
    {
      Name = "ui_source_type_param1",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PlayerTeamType"
        }
      },
      Description = "\229\175\185\231\153\189\232\181\132\230\186\144\231\177\187\229\158\139\229\143\130\230\149\176"
    },
    {
      Name = "show_baseboard",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "UIT_PIC\230\152\175\229\144\166\233\154\144\232\151\143\229\155\190\231\137\135\229\186\149\230\157\191"
    },
    {
      Name = "source_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\132\230\186\144\229\143\130\230\149\176"
    },
    {
      Name = "timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\187\145\229\177\143\229\187\182\230\151\182\239\188\136ms\239\188\137"
    },
    {
      Name = "type_sound",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\231\153\189\230\137\147\229\173\151\233\159\179\230\149\136"
    },
    {
      Name = "timeline_asset_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "Timeline\233\133\141\231\189\174\232\183\175\229\190\132"
    },
    {
      Name = "camera_switch_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "CameraSwitchType"
        }
      },
      Description = "\233\149\156\229\164\180\229\136\135\230\141\162\230\150\185\229\188\143"
    },
    {
      Name = "interact_camera_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcInteractCameraType"
        }
      },
      Description = "\233\149\156\229\164\180"
    },
    {
      Name = "interact_camera_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1761"
    },
    {
      Name = "interact_camera_param2",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1762"
    },
    {
      Name = "interact_camera_param3",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1763"
    },
    {
      Name = "interact_camera_param4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1764"
    },
    {
      Name = "unskippable_duration",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\143\175\232\183\179\232\191\135\230\151\182\233\151\180"
    },
    {
      Name = "camera_motion_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcInteractCameraMoveType"
        }
      },
      Description = "\232\191\144\233\149\156\230\158\154\228\184\190"
    },
    {
      Name = "camera_motion_direction",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\144\233\149\156\229\143\130\230\149\1761"
    },
    {
      Name = "camera_motion_distance",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\144\233\149\156\229\143\130\230\149\1762"
    },
    {
      Name = "camera_motion_time",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\144\233\149\156\229\143\130\230\149\1763"
    },
    {
      Name = "interact_camera_type_2",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcInteractCameraType"
        }
      },
      Description = "\233\149\156\229\164\1802"
    },
    {
      Name = "interact_camera2_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1761"
    },
    {
      Name = "interact_camera2_param2",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1762"
    },
    {
      Name = "interact_camera2_param3",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1763"
    },
    {
      Name = "interact_camera2_param4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\149\156\229\164\180\229\143\130\230\149\1764"
    },
    {
      Name = "unskippable_duration2",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\143\175\232\183\179\232\191\135\230\151\182\233\151\180"
    },
    {
      Name = "camera2_motion_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcInteractCameraMoveType"
        }
      },
      Description = "\232\191\144\233\149\156\230\158\154\228\184\1902"
    },
    {
      Name = "camera2_motion_direction",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\144\233\149\156\229\143\130\230\149\1761"
    },
    {
      Name = "camera2_motion_distance",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\144\233\149\156\229\143\130\230\149\1762"
    },
    {
      Name = "camera2_motion_time",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\144\233\149\156\229\143\130\230\149\1763"
    },
    {
      Name = "dialogue_sound",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\229\186\148\233\133\141\233\159\179\230\150\135\228\187\182"
    },
    {
      Name = "actor_perform",
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
          TypeName = "DIALOGUE_CONF_actor_perform"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "next_dialog_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\139\228\184\128\229\143\165\229\175\185\231\153\189Id"
    },
    {
      Name = "select_ids",
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
          TypeName = "SELECT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\136\134\230\148\175id\229\136\151\232\161\168"
    },
    {
      Name = "select_auto_on",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\230\148\175\233\128\137\233\161\185\229\136\157\229\167\139\230\152\175\229\144\166\230\191\128\230\180\187"
    },
    {
      Name = "dia_skip",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\187\152\232\174\164\228\184\186\231\169\186\239\188\140\232\161\168\231\164\186\230\173\164\229\143\165\229\143\175\232\162\171\232\183\179\232\191\135\239\188\155\233\133\141\231\189\174\228\184\186-1\230\151\182\239\188\140\232\161\168\231\164\186\230\173\164\229\143\165\228\184\141\229\143\175\232\162\171\232\183\179\232\191\135\239\188\155\233\133\141\231\189\174\228\184\1861\230\151\182\239\188\140\232\161\168\231\164\186\232\183\179\232\191\135\232\135\179\230\173\164\229\143\165\227\128\130"
    },
    {
      Name = "dia_skip_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "dia_skip_text"
        }
      },
      Description = "\229\137\167\230\131\133\230\162\151\230\166\130\230\150\135\230\156\172\239\188\136\233\187\152\232\174\164\228\184\186\231\169\186\230\151\182\239\188\140\228\184\141\230\152\190\231\164\186\230\162\151\230\166\130\230\150\135\230\156\172\239\188\140\231\155\180\230\142\165\232\183\179\232\135\179\230\156\172\229\143\165\239\188\155\233\133\141\231\189\174\230\150\135\230\156\172\230\151\182\239\188\140\230\152\190\231\164\186\229\137\167\230\131\133\230\162\151\230\166\130\239\188\140\229\134\141\232\183\179\232\135\179\230\156\172\229\143\165\239\188\137"
    },
    {
      Name = "action",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DIALOGUE_CONF_action"
        }
      },
      Description = "action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137"
    },
    {
      Name = "dialoguePreset",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "DialoguePreset"
        }
      },
      Description = "\230\152\175\229\144\166\228\188\152\229\133\136\229\164\132\231\144\134\233\156\178\232\144\165"
    },
    {
      Name = "task_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Edit,
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
      Description = "\228\187\187\229\138\161ID(\232\135\170\229\138\168)"
    },
    {
      Name = "specified_task_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\187\187\229\138\161ID(\230\137\139\229\138\168)"
    },
    {
      Name = "reaction_dia_relate",
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
          TypeName = "NPC_REACTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\176\131\231\148\168\230\173\164dia\231\154\132npc_reaction"
    },
    {
      Name = "submit_free_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\230\139\169\233\129\147\229\133\183\228\184\138\228\186\164\231\154\132\230\150\135\230\156\172\230\143\143\232\191\176"
    }
  }
}
RTTIManager:RegisterType(DIALOGUE_CONF.Name, DIALOGUE_CONF)

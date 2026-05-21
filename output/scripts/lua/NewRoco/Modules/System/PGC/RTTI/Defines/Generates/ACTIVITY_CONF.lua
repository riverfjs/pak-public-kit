local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ACTIVITY_CONF = {
  Name = "ACTIVITY_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "activity_conf/ACTIVITY_CONF.yaml",
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
      Description = "\230\180\187\229\138\168id"
    },
    {
      Name = "activity_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActivityType"
        }
      },
      Description = "\230\180\187\229\138\168\231\177\187\229\158\139"
    },
    {
      Name = "base_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "activity_type",
          EnumName = "ActivityType",
          LinkFieldName = "base_id"
        }
      },
      Description = "base_id\239\188\136\230\160\185\230\141\174\230\180\187\229\138\168\231\177\187\229\158\139\231\154\132\229\173\144\232\161\168id\239\188\137"
    },
    {
      Name = "type_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "activity_type",
          EnumName = "ActivityType",
          LinkFieldName = "type_param"
        }
      },
      Description = "\229\138\159\232\131\189\233\162\132\231\149\153\228\189\141\239\188\140\229\143\175\228\187\165\229\146\140\229\188\128\229\143\145\231\186\166\229\174\154\229\161\171\229\134\153\229\134\133\229\174\185"
    },
    {
      Name = "activity_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "activityname"
        }
      },
      Description = "\230\180\187\229\138\168\229\144\141\231\167\176"
    },
    {
      Name = "tab_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\184\128\231\186\167\230\180\187\229\138\168\233\161\181id"
    },
    {
      Name = "prompt_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\230\143\143\232\191\176"
    },
    {
      Name = "activity_txt",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\228\187\139\231\187\141"
    },
    {
      Name = "activity_special_txt",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "ACTIVITY_SPECIAL_TXT_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\180\187\229\138\168\228\187\139\231\187\141\231\137\185\230\174\138\229\188\185\231\170\151"
    },
    {
      Name = "appear_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1591\227\128\145"
    },
    {
      Name = "disappear_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\227\128\144\230\180\187\229\138\168\231\187\147\230\157\159\232\166\129\230\177\1301\227\128\145"
    },
    {
      Name = "daily_clear_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\151\165\230\184\133\230\151\182\233\151\180"
    },
    {
      Name = "world_level_required",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1592\227\128\145"
    },
    {
      Name = "role_level_required",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1593\227\128\145"
    },
    {
      Name = "task_required",
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
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1594\227\128\145"
    },
    {
      Name = "world_level_end_required",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\227\128\144\230\180\187\229\138\168\231\187\147\230\157\159\232\166\129\230\177\1302\227\128\145"
    },
    {
      Name = "recommend_task_id",
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
      Description = "\230\142\168\232\141\144\228\187\187\229\138\161\229\136\164\229\174\154"
    },
    {
      Name = "unfinished_tips",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\178\161\229\174\140\230\136\144\230\142\168\232\141\144\228\187\187\229\138\161\230\143\144\231\164\186\229\188\185\231\170\151"
    },
    {
      Name = "get_activity_task",
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
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\160\185\230\141\174\229\188\128\229\144\175\230\151\182\233\151\180\230\142\165\229\143\150\228\187\187\229\138\161"
    },
    {
      Name = "delete_activity_task",
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
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\160\185\230\141\174\231\187\147\230\157\159\230\151\182\233\151\180\229\136\160\233\153\164\228\187\187\229\138\161"
    },
    {
      Name = "save_activity_task",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\136\160\233\153\16414d\229\144\142\228\187\187\229\138\161\230\149\176\230\141\174\230\152\175\229\144\166\228\191\157\231\149\153"
    },
    {
      Name = "open_visible_area",
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
          TypeName = "AREA_VISIBLE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\180\187\229\138\168\229\140\186\233\151\180\229\134\133\233\156\128\232\166\129\230\137\147\229\188\128\231\154\132\228\186\146\232\167\129\229\140\186"
    },
    {
      Name = "close_visible_area",
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
          TypeName = "AREA_VISIBLE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\180\187\229\138\168\229\140\186\233\151\180\229\134\133\233\156\128\232\166\129\229\133\179\233\151\173\231\154\132\228\186\146\232\167\129\229\140\186"
    },
    {
      Name = "login_channel",
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
          EnumName = "CliLoginChannel"
        }
      },
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1595\227\128\145"
    },
    {
      Name = "login_plat",
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
          EnumName = "PlatType"
        }
      },
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1596\227\128\145"
    },
    {
      Name = "channel_source",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\227\128\144\230\180\187\229\138\168\229\188\128\229\144\175\231\186\166\230\157\1597\227\128\145"
    },
    {
      Name = "account_registration_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\180\166\229\143\183\230\179\168\229\134\140\230\151\182\233\151\180"
    },
    {
      Name = "activity_whitelist",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\180\187\229\138\168\231\153\189\229\144\141\229\141\149\239\188\136\233\133\141\231\189\174\229\144\142\228\187\133\231\153\189\229\144\141\229\141\149Whitelist\229\134\133\229\143\175\232\167\129\239\188\137"
    },
    {
      Name = "if_hide",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\233\161\181\233\157\162\230\152\175\229\144\166\233\154\144\232\151\143"
    },
    {
      Name = "if_appear",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\230\156\170\232\167\163\233\148\129\230\151\182\239\188\140\230\152\175\229\144\166\229\177\149\231\164\186\230\180\187\229\138\168\231\149\140\233\157\162"
    },
    {
      Name = "appear_world_level_require",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\160\185\230\141\174\230\152\159\231\186\167\239\188\140\230\143\144\229\137\141\229\177\149\231\164\186\230\180\187\229\138\168\231\149\140\233\157\162"
    },
    {
      Name = "ban_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "activitylocked"
        }
      },
      Description = "\228\184\141\230\187\161\232\182\179\229\143\130\228\184\142\230\157\161\228\187\182\230\151\182\231\154\132\230\143\144\231\164\186"
    },
    {
      Name = "success_if_disappear",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\229\174\140\230\136\144\230\128\129\229\144\142\230\152\175\229\144\166\230\182\136\229\164\177for\230\176\184\228\185\133\230\180\187\229\138\168/\231\173\190\229\136\176"
    },
    {
      Name = "delete_bagitem",
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
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\180\187\229\138\168\229\174\140\230\136\144\229\144\142\239\188\140\229\155\158\230\148\182\233\129\147\229\133\183"
    },
    {
      Name = "success_mail",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MAIL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\180\187\229\138\168\229\174\140\230\136\144\229\144\142\239\188\140\228\184\139\229\143\145\233\130\174\228\187\182"
    },
    {
      Name = "save_past_data",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\136\176\230\156\15914d\229\144\142\230\149\176\230\141\174\230\152\175\229\144\166\228\191\157\231\149\153"
    },
    {
      Name = "maintab_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "ACTIVITY_MAINTAB_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\229\136\134\233\161\181id"
    },
    {
      Name = "belong_system",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BelongSystem"
        }
      },
      Description = "\230\137\128\229\177\158\231\179\187\231\187\159"
    },
    {
      Name = "priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {},
      Description = "\229\177\149\231\164\186\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "bgm",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "bgm\232\181\132\230\186\144"
    },
    {
      Name = "umg_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "UMG\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "image_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\166\134\231\155\150\229\186\149\229\155\190png"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\233\128\137\228\184\173\229\155\190\230\160\135\239\188\136\231\142\176\229\156\168\230\152\175\233\187\145\232\137\178\231\154\132\233\130\163\228\184\170\239\188\137"
    },
    {
      Name = "icon_select",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\229\155\190\230\160\135\239\188\136\231\142\176\229\156\168\230\152\175\231\129\176\232\137\178\231\154\132\233\130\163\228\184\170\239\188\137"
    },
    {
      Name = "title_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\160\135\233\162\152\229\155\190\230\160\135"
    },
    {
      Name = "title_icon_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "activitytitle"
        }
      },
      Description = "\230\160\135\233\162\152\229\155\190\230\160\135\231\154\132\230\150\135\230\156\172"
    },
    {
      Name = "ae_start",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\231\149\140\233\157\162\229\133\165\229\156\186\229\138\168\230\149\136"
    },
    {
      Name = "ae_loop",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\231\149\140\233\157\162\229\145\188\229\144\184\229\138\168\230\149\136"
    },
    {
      Name = "ae_end",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\231\149\140\233\157\162\233\128\128\229\156\186\229\138\168\230\149\136"
    },
    {
      Name = "popup_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168\229\188\128\229\144\175\229\138\168\230\149\136\232\183\175\229\190\132"
    },
    {
      Name = "popup_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\229\138\168\230\149\136\230\161\134\230\150\135\230\161\136"
    },
    {
      Name = "mail_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MAIL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\161\165\229\143\145\233\130\174\228\187\182id"
    },
    {
      Name = "reissue_reward_ignore",
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
          TypeName = "ACTIVITY_CONF_reissue_reward_ignore"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\230\151\182\229\137\148\233\153\164\231\154\132\233\129\147\229\133\183"
    },
    {
      Name = "marquee_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "ACTIVITY_GLOBAL_CONFIG",
          FieldName = "key"
        }
      },
      Description = "\232\183\145\233\169\172\231\129\175key(\233\156\128\232\166\129\229\161\171\229\134\153ACTIVITY_GLOBAL_CONFIG,key)"
    },
    {
      Name = "refresh_event_group",
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
          TypeName = "ACTIVITY_CONF_refresh_event_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(ACTIVITY_CONF.Name, ACTIVITY_CONF)

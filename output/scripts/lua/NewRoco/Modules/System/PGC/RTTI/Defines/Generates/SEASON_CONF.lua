local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_CONF = {
  Name = "SEASON_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season/SEASON_CONF.yaml",
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
      Description = "\232\181\155\229\173\163id"
    },
    {
      Name = "season_slogan",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "season_slogan"
        }
      },
      Description = "\232\181\155\229\173\163\228\184\187\233\162\152"
    },
    {
      Name = "part_id",
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
          TypeName = "SEASON_PART_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\173\144\230\168\161\229\157\151id"
    },
    {
      Name = "start_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\188\128\229\144\175\230\151\182\233\151\180"
    },
    {
      Name = "end_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\231\187\147\230\157\159\230\151\182\233\151\180"
    },
    {
      Name = "s_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\133\165\229\143\163icon"
    },
    {
      Name = "s_title_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\231\149\140\233\157\162title_icon"
    },
    {
      Name = "lobby_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\151\231\155\152\231\149\140\233\157\162icon"
    },
    {
      Name = "s_title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\231\149\140\233\157\162title\230\160\135\233\162\152"
    },
    {
      Name = "s_title_subtitle",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\231\149\140\233\157\162title\229\137\175\230\160\135\233\162\152"
    },
    {
      Name = "umg_part",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "UMG\232\183\175\229\190\132"
    },
    {
      Name = "bgm_state",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163BGM"
    },
    {
      Name = "kv_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonKVType"
        }
      },
      Description = "\229\186\149\229\155\190\230\152\190\231\164\186\231\177\187\229\158\139"
    },
    {
      Name = "param_kv_common",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\154\231\148\168\229\186\149\229\155\190(\230\156\137\233\133\141\231\189\174\232\175\187\233\133\141\231\189\174\231\154\132\230\149\180\229\155\190\239\188\140\232\139\165\230\178\161\233\133\141\231\189\174\228\188\154\230\152\190\231\164\186umg\229\134\133\229\155\186\229\174\154\231\154\132)"
    },
    {
      Name = "param_kv_male",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\148\183-\229\186\149\229\155\190"
    },
    {
      Name = "param_kv_felmale",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\165\179-\229\186\149\229\155\190\232\183\175\229\190\132"
    },
    {
      Name = "pv_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MOVIE_CONF",
          FieldName = "id"
        }
      },
      Description = "PV id"
    },
    {
      Name = "popup_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\188\128\229\144\175\229\138\168\230\149\136\232\183\175\229\190\132"
    },
    {
      Name = "popup_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\168\230\149\136\230\161\134\230\150\135\229\173\151"
    },
    {
      Name = "season_pve_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_PVE_BASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\180\162\229\188\149SEASON_PVE_BASE_CONF"
    },
    {
      Name = "season_tips_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_TIPS_TAB_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\181\155\229\173\163\233\161\187\231\159\165id"
    },
    {
      Name = "season_adventure",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\133\179\232\129\148\231\154\132\232\181\155\229\173\163\230\137\139\229\134\140ID"
    },
    {
      Name = "season_start_task",
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
          DriverField = "MESSAGE_CONF,id",
          EnumName = "TASK_CONF",
          LinkFieldName = "id"
        }
      },
      Description = "\232\181\155\229\173\163\232\181\183\229\167\139\228\187\187\229\138\161"
    },
    {
      Name = "season_task_paragraph",
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
          TypeName = "PARAGRAPH_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\181\155\229\173\163\229\143\153\228\186\139\228\187\187\229\138\161\231\171\160\232\138\130"
    },
    {
      Name = "focus_group",
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
          TypeName = "SEASON_CONF_focus_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(SEASON_CONF.Name, SEASON_CONF)

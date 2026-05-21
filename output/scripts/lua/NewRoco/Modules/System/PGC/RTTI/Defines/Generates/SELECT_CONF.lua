local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SELECT_CONF = {
  Name = "SELECT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "dialogue/SELECT_CONF.yaml",
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
      Description = "\229\136\134\230\148\175id"
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
      Description = "\232\129\148\230\156\186\231\138\182\230\128\129\228\184\139\230\152\175\229\144\166\229\143\175\230\137\167\232\161\140 OVP_BOTH_FORBIDED \229\157\135\228\184\141\232\131\189\228\186\164\228\186\146 OVP_ONLY_OWNER \230\136\191\228\184\187\230\137\141\232\131\189\228\186\164\228\186\146 OVP_BOTH = 3 \230\136\191\228\184\187\229\146\140\232\174\191\229\174\162\229\157\135\229\143\175\228\186\164\228\186\146"
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
      Description = "\229\136\134\230\148\175\233\128\137\233\161\185\230\152\190\231\164\186\229\134\133\229\174\185"
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
      Description = "\232\176\131\231\148\168\230\173\164select\231\154\132opt"
    },
    {
      Name = "color",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\233\162\156\232\137\178"
    },
    {
      Name = "select_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\229\137\141\229\155\190\230\160\135"
    },
    {
      Name = "initial_flags",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\136\157\229\167\139\232\174\190\229\174\154flags"
    },
    {
      Name = "enable_cond",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "DlgSelectEnableCond"
        }
      },
      Description = "\229\136\134\230\148\175\233\128\137\230\139\169\229\144\175\231\148\168\230\157\161\228\187\182"
    },
    {
      Name = "enable_cond_params",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\229\188\128\229\144\175\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "times",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\230\156\137\230\149\136\230\172\161\230\149\176"
    },
    {
      Name = "times_decrease_cond",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SelectTimesDecCond"
        }
      },
      Description = "\233\128\146\229\135\143\230\157\161\228\187\182"
    },
    {
      Name = "times_decrease_cond_params",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "times_decrease_cond",
          Branches = {
            {
              Value = 8,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            },
            {
              Value = 10,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\233\128\146\229\135\143\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "reset_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SelectResetType"
        }
      },
      Description = "\233\135\141\231\189\174\230\150\185\229\188\143"
    },
    {
      Name = "reset_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\135\141\231\189\174\230\151\182\233\151\180"
    },
    {
      Name = "obtain_story_flags",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 0, Max = 255}
          }
        }
      },
      Description = "\233\128\137\230\139\169\230\151\182\232\142\183\229\190\151\231\154\132\229\137\167\230\131\133\230\160\135\232\174\176id\229\136\151\232\161\168"
    },
    {
      Name = "lost_story_flags",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 0, Max = 255}
          }
        }
      },
      Description = "\233\128\137\230\139\169\230\151\182\229\164\177\229\142\187\231\154\132\229\137\167\230\131\133\230\160\135\232\174\176id\229\136\151\232\161\168"
    },
    {
      Name = "notimes_disable",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\233\161\185\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182, \230\152\175\229\144\166\231\166\129\231\148\168\233\128\137\233\161\185"
    },
    {
      Name = "notimes_dialogue",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\128\137\233\161\185\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\239\188\140\228\184\139\228\184\128\229\143\165\229\175\185\231\153\189"
    },
    {
      Name = "select_deletnpc",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\239\188\140\230\152\175\229\144\166\229\136\160\233\153\164\230\137\128\229\177\158Npc"
    },
    {
      Name = "select_deletnpc_times",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\142\146\230\150\165\229\144\140Npc\229\133\182\229\174\131select\230\156\137\230\149\136\230\172\161\230\149\176\228\184\1860\230\151\182\231\154\132\229\136\160\233\153\164"
    },
    {
      Name = "select_next_dialogue",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\128\137\233\161\185\229\175\185\229\186\148\228\184\139\228\184\128\229\143\165\229\175\185\231\153\189id"
    },
    {
      Name = "select_mark",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SelectMarkYellow"
        }
      },
      Description = "\229\175\185\232\175\157\233\128\137\233\161\185\230\160\135\233\187\132\231\154\132\230\157\161\228\187\182"
    },
    {
      Name = "select_skip",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\175\165\233\128\137\233\161\185\230\152\175\229\144\166\228\184\186\233\187\152\232\174\164\233\128\137\233\161\185\227\128\130\233\187\152\232\174\164\228\184\186\231\169\186\239\188\140\232\161\168\231\164\186false\227\128\130\233\133\141\231\189\174\228\184\186true\230\151\182\239\188\140\232\161\168\231\164\186\228\184\186\233\187\152\232\174\164\233\128\137\233\161\185\227\128\130"
    },
    {
      Name = "esc_skip",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\156\128\232\166\129ESC\230\140\137\233\148\174\229\147\141\229\186\148"
    }
  }
}
RTTIManager:RegisterType(SELECT_CONF.Name, SELECT_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SPE_REFRESH_TRIG_CONF = {
  Name = "SPE_REFRESH_TRIG_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "trigger/SPE_REFRESH_TRIG_CONF.yaml",
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
            {Min = 1, Max = 999999}
          }
        }
      },
      Description = "\229\136\183\230\150\176\228\186\139\228\187\182ID"
    },
    {
      Name = "available_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\128\229\144\175\230\151\182\233\151\180"
    },
    {
      Name = "unable_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\147\230\157\159\230\151\182\233\151\180"
    },
    {
      Name = "duration",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\149\230\172\161\228\186\139\228\187\182\230\140\129\231\187\173\230\151\182\233\151\180"
    },
    {
      Name = "trigger_player_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TriggerPlayerType"
        }
      },
      Description = "\232\167\166\229\143\145\228\186\139\228\187\182\231\142\169\229\174\182\231\177\187\229\158\139\230\158\154\228\184\190"
    },
    {
      Name = "trigger_player_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\167\166\229\143\145\228\186\139\228\187\182\231\142\169\229\174\182\231\177\187\229\158\139\229\143\130\230\149\176"
    },
    {
      Name = "next_event",
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
          TypeName = "SPE_REFRESH_TRIG_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\144\142\231\189\174\228\186\139\228\187\182ID"
    },
    {
      Name = "event_trigger_time_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TimeResetType"
        }
      },
      Description = "\232\167\166\229\143\145\233\151\180\233\154\148\231\177\187\229\158\139"
    },
    {
      Name = "event_trigger_time_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\233\151\180\233\154\148\229\143\130\230\149\176"
    },
    {
      Name = "event_trigger_time_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\233\151\180\233\154\148\229\143\130\230\149\1762"
    },
    {
      Name = "event_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\139\228\187\182\228\186\146\230\150\165\233\133\141\231\189\174"
    },
    {
      Name = "event_result",
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
          TypeName = "SPE_REFRESH_TRIG_CONF_event_result"
        }
      },
      Description = ""
    }
  }
}
RTTIManager:RegisterType(SPE_REFRESH_TRIG_CONF.Name, SPE_REFRESH_TRIG_CONF)

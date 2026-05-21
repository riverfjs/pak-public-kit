local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local WEATHER_CONF = {
  Name = "WEATHER_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "weather/WEATHER_CONF.yaml",
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
      Description = "\229\164\169\230\176\148id"
    },
    {
      Name = "weather_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WeatherType"
        }
      },
      Description = "\229\175\185\229\186\148\230\158\154\228\184\190"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "weathername1"
        }
      },
      Description = "\229\144\141\231\167\176"
    },
    {
      Name = "weather_params",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\169\230\176\148\229\143\130\230\149\176\230\150\135\228\187\182\229\144\141\231\167\176"
    },
    {
      Name = "tod_param",
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
          TypeName = "WEATHER_CONF_tod_param"
        }
      },
      Description = "\228\188\154\232\183\159\233\154\143tod\229\143\152\229\140\150\231\154\132\229\143\130\230\149\176\231\187\132"
    },
    {
      Name = "temperature",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\184\169\229\186\166"
    },
    {
      Name = "weather_buff",
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
          TypeName = "BUFF_CONF",
          FieldName = "id"
        }
      },
      Description = ""
    },
    {
      Name = "report_tip",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "weathestarttxt"
        }
      },
      Description = ""
    },
    {
      Name = "reject_aura_effect",
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
          EnumName = "AuraEffect"
        }
      },
      Description = ""
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "icon"
    },
    {
      Name = "show_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\231\149\140\233\157\162\231\154\132icon"
    }
  }
}
RTTIManager:RegisterType(WEATHER_CONF.Name, WEATHER_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BUFFBASE_CONF = {
  Name = "BUFFBASE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "skill/BUFFBASE_CONF.yaml",
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
      Description = "buff\232\161\168id\239\188\140ID\230\174\181900000~999999"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\231\173\150\229\136\146\230\143\143\232\191\176"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\229\173\151\230\158\154\228\184\190"
    },
    {
      Name = "buffbase_order",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BuffType"
        }
      },
      Description = "\230\158\154\228\184\190id"
    },
    {
      Name = "trigger_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BattleEvent"
        }
      },
      Description = "buffbase\232\167\166\229\143\145\230\151\182\233\151\180\231\130\185\230\158\154\228\184\190"
    },
    {
      Name = "is_dam_param_change",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\155\180\230\148\185UI\230\138\128\232\131\189\229\168\129\229\138\155"
    },
    {
      Name = "show_letters",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\137\185\230\128\167\233\163\152\229\173\151\232\167\166\229\143\145\231\130\185"
    },
    {
      Name = "client_trigger_type",
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
          EnumName = "Buffbasetrigger_type"
        }
      },
      Description = "\229\174\162\230\136\183\231\171\175\232\167\166\229\143\145\230\151\182\233\151\180\231\130\185"
    },
    {
      Name = "buffbase_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 24
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "BUFFBASE_CONF_buffbase_param"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(BUFFBASE_CONF.Name, BUFFBASE_CONF)

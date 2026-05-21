local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local FUNCTION_BAN_CONF = {
  Name = "FUNCTION_BAN_CONF",
  Version = 1,
  Description = "\231\174\161\231\144\134\231\142\169\229\174\182\229\164\132\228\186\142\230\159\144\228\186\155\231\138\182\230\128\129\228\184\139\230\151\182\239\188\140\230\184\184\230\136\143\228\184\173\231\154\132\233\131\168\229\136\134\229\138\159\232\131\189\230\152\175\229\144\166\232\162\171\231\166\129\230\173\162\228\189\191\231\148\168\227\128\129\231\149\140\233\157\162\230\152\175\229\144\166\230\152\190\231\164\186\231\154\132\232\161\168",
  Metadata = {
    Alias = "\228\186\146\230\150\165\232\161\168",
    RelativeYamlPath = "function_ban/FUNCTION_BAN_CONF.yaml",
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
            {Min = 1, Max = 65535}
          }
        }
      },
      Description = "\230\149\176\230\141\174ID"
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
      Name = "ban_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "notificationtext"
        }
      },
      Description = "\233\128\154\231\148\168\231\154\132\231\166\129\231\148\168\230\143\144\231\164\186"
    },
    {
      Name = "desc_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\143\144\231\164\186\230\152\190\231\164\186\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "auto_clear_status",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\173\148\229\138\155\228\185\139\230\186\144\228\188\145\230\129\175\230\136\150\232\132\177\229\155\176\230\151\182\230\152\175\229\144\166\230\184\133\233\153\164\231\138\182\230\128\129"
    },
    {
      Name = "function_ban_list",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 123
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "FUNCTION_BAN_CONF_function_ban_list"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(FUNCTION_BAN_CONF.Name, FUNCTION_BAN_CONF)

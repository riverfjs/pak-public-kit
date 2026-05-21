local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_ITEM_CONF = {
  Name = "SEASON_ITEM_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season/SEASON_ITEM_CONF.yaml",
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
      Description = "item id"
    },
    {
      Name = "item_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "item_name"
        }
      },
      Description = "\230\168\161\229\157\151\229\144\141\231\167\176for\229\188\185\231\170\151\230\160\135\233\162\152"
    },
    {
      Name = "textbox",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\167\189\228\189\141\232\190\185\230\161\134\229\155\190(\230\156\137\233\133\141\231\189\174\232\175\187\233\133\141\231\189\174\231\154\132\230\149\180\229\155\190\239\188\140\232\139\165\230\178\161\233\133\141\231\189\174\228\188\154\230\152\190\231\164\186umg\229\134\133\229\155\186\229\174\154\231\154\132)"
    },
    {
      Name = "textbox_disable",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\170\229\188\128\229\144\175\230\167\189\228\189\141\232\190\185\230\161\134\229\155\190"
    },
    {
      Name = "unlock_tips",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\170\232\167\163\233\148\129\230\143\144\231\164\186\232\175\173"
    },
    {
      Name = "lock_flag",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\167\163\233\148\129flag(\231\142\169\229\174\182\232\186\171\228\184\138\230\156\137\230\140\135\229\174\154flag\229\144\142\230\137\141\232\167\163\233\148\129\230\167\189\228\189\141)"
    },
    {
      Name = "jump_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActivitySeasonItemJump"
        }
      },
      Description = "\232\183\179\232\189\172\231\177\187\229\158\139"
    },
    {
      Name = "jump_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "jump_type",
          Branches = {
            {
              Value = 4,
              TypeName = "WORLD_MAP_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "CLIENT_PUBLIC_CMD",
              FieldName = "text"
            },
            {
              Value = 1,
              TypeName = "ACTIVITY_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\183\179\232\189\172param\239\188\136\230\150\176\230\179\168\229\134\140\231\154\132cmd\232\166\129\229\142\187CMD\229\156\168CLIENT_PUBLIC_CMD\231\153\187\232\174\176\239\188\137"
    },
    {
      Name = "param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164\229\143\130\230\149\1761"
    },
    {
      Name = "param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164\229\143\130\230\149\1762"
    },
    {
      Name = "param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164\229\143\130\230\149\1763"
    },
    {
      Name = "time_show_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActivitySeasonTimeShow"
        }
      },
      Description = "\230\151\182\233\151\180\230\152\190\231\164\186"
    },
    {
      Name = "time_show_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\151\182\233\151\180param1"
    },
    {
      Name = "time_show_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\151\182\233\151\180param2"
    },
    {
      Name = "time_show_param3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "time_show_type",
          Branches = {
            {
              Value = 3,
              TypeName = "PARAGRAPH_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\151\182\233\151\180param3"
    },
    {
      Name = "additional_show",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonItemAdditionalShow"
        }
      },
      Description = "\232\161\165\229\133\133\230\152\190\231\164\186"
    },
    {
      Name = "additional_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\165\229\133\133\230\152\190\231\164\186param"
    }
  }
}
RTTIManager:RegisterType(SEASON_ITEM_CONF.Name, SEASON_ITEM_CONF)

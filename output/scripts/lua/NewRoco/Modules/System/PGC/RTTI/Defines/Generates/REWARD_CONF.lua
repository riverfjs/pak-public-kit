local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local REWARD_CONF = {
  Name = "REWARD_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "reward/REWARD_CONF.yaml",
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
      Description = "\229\165\150\229\138\177ID"
    },
    {
      Name = "Name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "Name"
        }
      },
      Description = "\229\165\150\229\138\177\229\144\141\231\167\176"
    },
    {
      Name = "Type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RewardType"
        }
      },
      Description = "RT_GIFT"
    },
    {
      Name = "show_bagitem_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\180\187\229\138\168/\233\130\174\228\187\182\233\162\132\232\167\136\231\148\168\239\188\140\233\133\141bag_item_id"
    },
    {
      Name = "Icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\231\164\188\229\140\133icon"
    },
    {
      Name = "DisplayName",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "DisplayName"
        }
      },
      Description = "\229\177\149\231\164\186\231\148\168\229\144\141\231\167\176"
    },
    {
      Name = "Tag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RewardTag"
        }
      },
      Description = "\231\164\188\229\140\133\230\160\135\231\173\190"
    },
    {
      Name = "Description",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "Description"
        }
      },
      Description = "\229\177\149\231\164\186\231\148\168\230\143\143\232\191\176"
    },
    {
      Name = "ObtainLimit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\229\138\177\232\142\183\229\143\150\230\172\161\230\149\176\233\153\144\229\136\182"
    },
    {
      Name = "DropChance",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\174\161\231\144\134\233\154\143\230\156\186\228\186\167\229\135\186\233\156\128\230\177\130"
    },
    {
      Name = "DropRound",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\174\161\231\144\134\233\154\143\230\156\186\228\186\167\229\135\186\233\156\128\230\177\130\239\188\140\233\154\143\230\156\186\232\189\174\230\149\176"
    },
    {
      Name = "RewardItem",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 25
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "REWARD_CONF_RewardItem"
        }
      },
      Description = "\229\165\150\229\138\177\233\161\185\230\149\176\233\135\143"
    }
  }
}
RTTIManager:RegisterType(REWARD_CONF.Name, REWARD_CONF)

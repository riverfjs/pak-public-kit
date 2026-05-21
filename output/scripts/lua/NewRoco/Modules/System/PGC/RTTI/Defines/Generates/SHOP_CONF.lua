local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SHOP_CONF = {
  Name = "SHOP_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "shop/SHOP_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\229\149\134\229\186\151ID"
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
      Name = "shop_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "shop_name"
        }
      },
      Description = "\229\149\134\229\186\151\229\144\141\231\167\176"
    },
    {
      Name = "shop_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\149\134\229\186\151\229\183\166\228\184\138\232\167\146icon"
    },
    {
      Name = "shop_location",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "shoplocation"
        }
      },
      Description = "\229\149\134\229\186\151\229\189\146\229\177\158\231\154\132\229\140\186\229\159\159\239\188\136\230\152\190\231\164\186\229\156\168\232\180\173\231\137\169\229\176\143\231\165\168\228\184\138\239\188\137"
    },
    {
      Name = "checkout_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\149\134\229\186\151\232\180\173\231\137\169\229\176\143\231\165\168\231\155\150\231\171\160icon"
    },
    {
      Name = "is_enable",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\138\230\158\182"
    },
    {
      Name = "is_cumulative",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\180\175\230\182\136\229\149\134\229\186\151"
    },
    {
      Name = "multi_buy",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\129\232\174\184\229\144\140\230\151\182\232\180\173\228\185\176\229\164\154\231\167\141\229\149\134\229\147\129"
    },
    {
      Name = "shop_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ShopType"
        }
      },
      Description = "\229\149\134\229\186\151\231\177\187\229\158\139"
    },
    {
      Name = "random_shop_goods_num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\143\230\156\186\229\149\134\229\186\151\229\149\134\229\147\129\230\149\176\233\135\143"
    },
    {
      Name = "enable_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\149\134\229\186\151\229\135\186\231\142\176\229\188\128\229\167\139\230\151\182\233\151\180"
    },
    {
      Name = "disable_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\149\134\229\186\151\229\135\186\231\142\176\231\187\147\230\157\159\230\151\182\233\151\180"
    },
    {
      Name = "refresh_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\149\134\229\186\151\229\136\183\230\150\176\229\188\128\229\167\139\230\151\182\233\151\180"
    },
    {
      Name = "duration",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\149\134\229\186\151\229\136\183\230\150\176\233\151\180\233\154\148"
    },
    {
      Name = "refresh_time_slot",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RefreshRuleConf"
        }
      },
      Description = "\230\137\167\232\161\140\229\136\183\230\150\176\231\154\132\230\151\182\233\151\180\230\174\181\239\188\136npc\229\156\168\229\155\186\229\174\154\230\151\182\233\151\180\229\134\133\229\135\186\231\142\176\230\151\182\231\148\168\239\188\137"
    },
    {
      Name = "purchase_limit",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\149\228\184\170\229\149\134\229\147\129\232\180\173\228\185\176/\229\135\186\229\148\174\228\184\138\233\153\144\239\188\136\228\184\141\229\161\171\228\184\1861000\239\188\137"
    },
    {
      Name = "content_id",
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
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\180\162\229\188\149\231\154\132npc\228\191\161\230\129\175"
    },
    {
      Name = "goods",
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
          TypeName = "SHOP_CONF_goods"
        }
      },
      Description = ""
    }
  }
}
RTTIManager:RegisterType(SHOP_CONF.Name, SHOP_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MAIL_CONF = {
  Name = "MAIL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "mail/MAIL_CONF.yaml",
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
      Description = "\233\130\174\228\187\182id"
    },
    {
      Name = "mail_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MailType"
        }
      },
      Description = "\233\130\174\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "mail_platform",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MailPlatform"
        }
      },
      Description = "\229\143\145\233\128\129\229\185\179\229\143\176"
    },
    {
      Name = "server_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\141\229\138\161\229\153\168\233\128\137\230\139\169"
    },
    {
      Name = "mail_condition",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MailCondition"
        }
      },
      Description = "\229\143\145\233\128\129\230\157\161\228\187\182\230\158\154\228\184\190"
    },
    {
      Name = "start_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\145\233\128\129\229\188\128\229\167\139\230\151\182\233\151\180"
    },
    {
      Name = "end_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\145\233\128\129\231\187\147\230\157\159\230\151\182\233\151\180"
    },
    {
      Name = "version",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "level_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MailLevelType"
        }
      },
      Description = "\231\173\137\231\186\167\231\177\187\229\158\139"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\143\145\233\128\129\231\173\137\231\186\167"
    },
    {
      Name = "validity",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\155\184\229\175\185\232\191\135\230\156\159\230\151\182\233\151\180"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\130\174\228\187\182icon"
    },
    {
      Name = "expire_at",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\157\229\175\185\232\191\135\230\156\159\230\151\182\233\151\180"
    },
    {
      Name = "mail_title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "mail_title"
        }
      },
      Description = "\233\130\174\228\187\182\230\160\135\233\162\152"
    },
    {
      Name = "mail_sender",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "mail_sender"
        }
      },
      Description = "\229\143\145\228\187\182\228\186\186"
    },
    {
      Name = "mail_content",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "mail_content"
        }
      },
      Description = "\233\130\174\228\187\182\229\134\133\229\174\185"
    },
    {
      Name = "reward_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\165\150\229\138\177id"
    },
    {
      Name = "use_svr_data",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\175\187\229\143\150\229\144\142\229\143\176\230\149\176\230\141\174"
    },
    {
      Name = "whitelist",
      Type = RTTIBase.FieldType.INT64,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\153\189\229\144\141\229\141\149&mdash;&mdash;\229\133\172\230\181\139"
    },
    {
      Name = "denylist",
      Type = RTTIBase.FieldType.INT64,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\187\145\229\144\141\229\141\149&mdash;&mdash;\229\133\172\230\181\139"
    },
    {
      Name = "reg_from_date",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\179\168\229\134\140\229\188\128\229\167\139\230\151\182\233\151\180"
    },
    {
      Name = "reg_to_date",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\179\168\229\134\140\231\187\147\230\157\159\230\151\182\233\151\180"
    },
    {
      Name = "min_client_version",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\176\143\229\174\162\230\136\183\231\171\175\231\137\136\230\156\172"
    },
    {
      Name = "max_client_version",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\164\167\229\174\162\230\136\183\231\171\175\231\137\136\230\156\172"
    },
    {
      Name = "ban_client_version",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\233\187\145\229\144\141\229\141\149\231\137\136\230\156\172"
    },
    {
      Name = "redirect_website",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\189\145\233\161\181\232\183\179\232\189\172"
    },
    {
      Name = "unable_resend_mail",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\133\129\232\174\184\229\164\177\232\180\165\233\135\141\232\175\149\239\188\140\233\187\152\232\174\1640\239\188\136\229\141\179\229\133\129\232\174\184\233\135\141\232\175\149\239\188\137"
    },
    {
      Name = "reward_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 10
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "MAIL_CONF_reward_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(MAIL_CONF.Name, MAIL_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TEACH_CONF = {
  Name = "TEACH_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "teach/TEACH_CONF.yaml",
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
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "list_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TeachGuideType"
        }
      },
      Description = "\230\149\153\229\173\166\231\177\187\229\158\139(\233\161\181\231\173\190)"
    },
    {
      Name = "teach_platform",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "Teachplatform"
        }
      },
      Description = "\230\149\153\229\173\166\230\152\190\231\164\186\229\185\179\229\143\176"
    },
    {
      Name = "list_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "list_des"
        }
      },
      Description = "\229\136\151\232\161\168\230\150\135\229\173\151"
    },
    {
      Name = "guide_struct",
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
          TypeName = "TEACH_CONF_guide_struct"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "unlock_conditions",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 12
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TEACH_CONF_unlock_conditions"
        }
      },
      Description = ""
    },
    {
      Name = "is_review",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\155\158\230\186\175\230\149\176\230\141\174"
    },
    {
      Name = "unlock_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\229\155\190\230\160\135"
    },
    {
      Name = "unlock_text_main",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "unlock_text_main"
        }
      },
      Description = "\232\167\163\233\148\129\230\150\135\229\173\151\239\188\136\228\184\138\239\188\137"
    },
    {
      Name = "unlock_text_sub",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "unlock_text_sub"
        }
      },
      Description = "\232\167\163\233\148\129\230\150\135\229\173\151\239\188\136\228\184\139\239\188\137"
    },
    {
      Name = "unlock_remind",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\188\185\229\135\186\232\167\163\233\148\129\230\143\144\231\164\186"
    },
    {
      Name = "unlock_remind_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "tips\230\152\190\231\164\186\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "reward_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\165\150\229\138\177"
    }
  }
}
RTTIManager:RegisterType(TEACH_CONF.Name, TEACH_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_ADVENTURE_CONF = {
  Name = "SEASON_ADVENTURE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season_adventure/SEASON_ADVENTURE_CONF.yaml",
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
      Description = "\232\181\155\229\173\163\230\137\139\229\134\140ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonname"
        }
      },
      Description = "\232\181\155\229\173\163\229\144\141"
    },
    {
      Name = "ui_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_UI",
          FieldName = "id"
        }
      },
      Description = "\229\133\179\232\129\148\231\154\132\230\160\183\229\188\143ID"
    },
    {
      Name = "chapter_group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_CHAPTER",
          FieldName = "group_id"
        }
      },
      Description = "\229\140\133\229\144\171\231\154\132\232\181\155\229\173\163\231\171\160\232\138\130\228\187\187\229\138\161\231\187\132"
    },
    {
      Name = "badge_group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_BADGE_LEVEL",
          FieldName = "group_id"
        }
      },
      Description = "\229\140\133\229\144\171\231\154\132\232\181\155\229\173\163\229\190\189\231\171\160\231\187\132"
    },
    {
      Name = "tips_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "LOCALIZATION_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\175\165\230\137\139\229\134\140\231\154\132\231\142\169\230\179\149\232\175\180\230\152\142"
    },
    {
      Name = "shop_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SHOP_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\175\165\230\137\139\229\134\140\231\154\132\229\149\134\229\186\151\229\133\165\229\143\163"
    },
    {
      Name = "reward_mail_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MAIL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\233\130\174\228\187\182ID"
    },
    {
      Name = "reissue_reward_ignore",
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
          TypeName = "SEASON_ADVENTURE_CONF_reissue_reward_ignore"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\230\151\182\229\137\148\233\153\164\231\154\132\233\129\147\229\133\183"
    }
  }
}
RTTIManager:RegisterType(SEASON_ADVENTURE_CONF.Name, SEASON_ADVENTURE_CONF)

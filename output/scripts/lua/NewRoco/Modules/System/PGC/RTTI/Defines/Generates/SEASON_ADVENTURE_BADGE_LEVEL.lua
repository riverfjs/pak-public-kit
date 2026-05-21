local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_ADVENTURE_BADGE_LEVEL = {
  Name = "SEASON_ADVENTURE_BADGE_LEVEL",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season_adventure/SEASON_ADVENTURE_BADGE_LEVEL.yaml",
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
      Description = "\232\181\155\229\173\163\229\190\189\231\171\160\231\173\137\231\186\167ID"
    },
    {
      Name = "group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\190\189\231\171\160\231\187\132ID"
    },
    {
      Name = "level_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\189\231\171\160\231\173\137\231\186\167\230\142\146\229\186\143"
    },
    {
      Name = "next_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_BADGE_LEVEL",
          FieldName = "id"
        }
      },
      Description = "\228\184\139\228\184\170\231\173\137\231\186\167ID"
    },
    {
      Name = "badge_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\189\231\171\160\229\155\190\230\160\135\232\181\132\230\186\144"
    },
    {
      Name = "badge_icon_noedge",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\189\231\171\160\229\155\190\230\160\135\232\181\132\230\186\144-\230\151\160\230\138\149\229\189\177(\231\148\168\228\186\142\229\138\168\230\149\136)"
    },
    {
      Name = "badge_icon_noedge2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\189\231\171\160\229\155\190\230\160\135\232\181\132\230\186\144-\230\151\160\230\138\149\229\189\1772(\231\148\168\228\186\142\229\138\168\230\149\136)"
    },
    {
      Name = "badge_icon_mask",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\189\231\171\160\229\155\190\230\160\135\232\181\132\230\186\144-\233\129\174\231\189\169(\231\148\168\228\186\142\229\138\168\230\149\136)"
    },
    {
      Name = "button_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonmedalbuttonname"
        }
      },
      Description = "\229\190\189\231\171\160\229\143\179\228\190\167\233\162\134\229\165\150\230\140\137\233\146\174\230\150\135\230\156\172"
    },
    {
      Name = "next_level_task_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\135\229\136\176\230\156\172\231\186\167\230\137\128\233\156\128\229\174\140\230\136\144\228\187\187\229\138\161\230\149\176\233\135\143"
    },
    {
      Name = "badge_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonAdventureBadgeType"
        }
      },
      Description = "\229\190\189\231\171\160\229\138\160\230\136\144\230\149\136\230\158\156\231\177\187\229\158\139"
    },
    {
      Name = "badge_type_param1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "badge_type",
          Branches = {
            {
              Value = 4,
              TypeName = "REWARD_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\190\189\231\171\160\229\138\160\230\136\144\230\149\136\230\158\156\231\177\187\229\158\139\229\143\130\230\149\176"
    },
    {
      Name = "badge_type_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonmedaleffect"
        }
      },
      Description = "\229\190\189\231\171\160\229\138\160\230\136\144\230\149\136\230\158\156\230\143\143\232\191\176"
    }
  }
}
RTTIManager:RegisterType(SEASON_ADVENTURE_BADGE_LEVEL.Name, SEASON_ADVENTURE_BADGE_LEVEL)

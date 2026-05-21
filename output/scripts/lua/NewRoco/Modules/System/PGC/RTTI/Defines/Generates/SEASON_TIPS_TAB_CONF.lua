local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_TIPS_TAB_CONF = {
  Name = "SEASON_TIPS_TAB_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season_tips/SEASON_TIPS_TAB_CONF.yaml",
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
      Description = "\232\181\155\229\173\163tips_id"
    },
    {
      Name = "tips_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonentrytips"
        }
      },
      Description = "\229\133\165\229\143\163&tips\229\144\141\229\173\151"
    },
    {
      Name = "tips_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\165\229\143\163icon"
    },
    {
      Name = "tab_group",
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
          TypeName = "SEASON_TIPS_TAB_CONF_tab_group"
        }
      },
      Description = "tab\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(SEASON_TIPS_TAB_CONF.Name, SEASON_TIPS_TAB_CONF)

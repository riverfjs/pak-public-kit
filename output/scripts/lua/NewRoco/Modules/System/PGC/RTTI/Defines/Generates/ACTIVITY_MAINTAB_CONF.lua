local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ACTIVITY_MAINTAB_CONF = {
  Name = "ACTIVITY_MAINTAB_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "activity_conf/ACTIVITY_MAINTAB_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\229\136\134\233\161\181id"
    },
    {
      Name = "maintab_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "eventmaintabname"
        }
      },
      Description = "\229\136\134\233\161\181\229\144\141\231\167\176"
    },
    {
      Name = "maintab_icon_select",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\233\161\181icon\239\188\136\233\128\137\228\184\173\239\188\137"
    },
    {
      Name = "maintab_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\233\161\181icon\239\188\136\228\184\141\233\128\137\228\184\173\239\188\137"
    }
  }
}
RTTIManager:RegisterType(ACTIVITY_MAINTAB_CONF.Name, ACTIVITY_MAINTAB_CONF)

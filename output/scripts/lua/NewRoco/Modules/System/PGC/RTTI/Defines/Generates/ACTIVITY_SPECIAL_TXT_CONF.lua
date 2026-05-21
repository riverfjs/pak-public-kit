local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ACTIVITY_SPECIAL_TXT_CONF = {
  Name = "ACTIVITY_SPECIAL_TXT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "activity_func/ACTIVITY_SPECIAL_TXT_CONF.yaml",
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
      Description = "\229\188\185\231\170\151id"
    },
    {
      Name = "explain_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 4
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "ACTIVITY_SPECIAL_TXT_CONF_explain_group"
        }
      },
      Description = "\230\149\176\231\187\132\231\148\179\230\152\142"
    }
  }
}
RTTIManager:RegisterType(ACTIVITY_SPECIAL_TXT_CONF.Name, ACTIVITY_SPECIAL_TXT_CONF)

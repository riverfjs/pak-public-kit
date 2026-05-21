local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_GROUP_AI_BASIC_INFO_CONF = {
  Name = "NRC_GROUP_AI_BASIC_INFO_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_GROUP_AI_BASIC_INFO_CONF.yaml",
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
      Description = "\229\136\134\231\187\132ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "event_array",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 240
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF_event_array"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(NRC_GROUP_AI_BASIC_INFO_CONF.Name, NRC_GROUP_AI_BASIC_INFO_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_GROUP_AI_ROLE_TYPE_CONF = {
  Name = "NRC_GROUP_AI_ROLE_TYPE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_GROUP_AI_ROLE_TYPE_CONF.yaml",
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
      Description = "\231\190\164\232\144\189\232\167\146\232\137\178\231\177\187\229\158\139id"
    },
    {
      Name = "group_ai_role_type_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = true,
      Constraints = {},
      Description = "\231\190\164\232\144\189\232\167\146\232\137\178\231\177\187\229\158\139"
    }
  }
}
RTTIManager:RegisterType(NRC_GROUP_AI_ROLE_TYPE_CONF.Name, NRC_GROUP_AI_ROLE_TYPE_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_AI_BB_INPUT_CONF = {
  Name = "NRC_AI_BB_INPUT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_AI_BB_INPUT_CONF.yaml",
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
      Description = "\233\187\145\230\157\191\232\190\147\229\133\165ID"
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
      Name = "blackboard_input",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_BB_INPUT_CONF_blackboard_input"
        }
      },
      Description = "\233\187\145\230\157\191\231\187\132\230\149\176"
    }
  }
}
RTTIManager:RegisterType(NRC_AI_BB_INPUT_CONF.Name, NRC_AI_BB_INPUT_CONF)

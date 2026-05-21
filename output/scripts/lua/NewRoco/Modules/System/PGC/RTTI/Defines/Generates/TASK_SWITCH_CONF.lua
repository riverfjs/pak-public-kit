local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TASK_SWITCH_CONF = {
  Name = "TASK_SWITCH_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "task/TASK_SWITCH_CONF.yaml",
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
      Description = "\229\188\128\229\133\179ID"
    },
    {
      Name = "switch_group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\128\229\133\179\231\187\132ID"
    },
    {
      Name = "switch_initialstate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\138\182\230\128\129"
    },
    {
      Name = "switch_type",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\164\154\230\172\161\229\188\128\229\133\179"
    },
    {
      Name = "begintask",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\228\187\187\229\138\161\233\147\190\229\136\157\229\167\139\228\187\187\229\138\161"
    },
    {
      Name = "switch_condition",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 2
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TASK_SWITCH_CONF_switch_condition"
        }
      },
      Description = ""
    }
  }
}
RTTIManager:RegisterType(TASK_SWITCH_CONF.Name, TASK_SWITCH_CONF)

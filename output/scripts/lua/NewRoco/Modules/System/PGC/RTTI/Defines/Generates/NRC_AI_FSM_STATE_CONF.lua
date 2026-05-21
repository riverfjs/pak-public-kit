local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_AI_FSM_STATE_CONF = {
  Name = "NRC_AI_FSM_STATE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_AI_FSM_STATE_CONF.yaml",
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
      Description = "\231\138\182\230\128\129ID (\232\140\131\229\155\180\239\188\1541-100\239\188\137"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING,
          Size = 3
        }
      },
      Description = ""
    },
    {
      Name = "state_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StateType"
        }
      },
      Description = "\231\138\182\230\128\129\231\154\132\230\158\154\228\184\190"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\177\130\231\186\167"
    },
    {
      Name = "as_struct_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\175\165\231\138\182\230\128\129\229\181\140\229\165\151\228\187\165\228\184\139\231\138\182\230\128\129\229\143\138\231\187\147\230\158\132"
    },
    {
      Name = "fsm_state",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 10
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_FSM_STATE_CONF_fsm_state"
        }
      },
      Description = "\228\184\139\230\184\184\231\138\182\230\128\129\230\149\176"
    }
  }
}
RTTIManager:RegisterType(NRC_AI_FSM_STATE_CONF.Name, NRC_AI_FSM_STATE_CONF)

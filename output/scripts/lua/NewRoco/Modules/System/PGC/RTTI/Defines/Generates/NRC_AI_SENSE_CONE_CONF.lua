local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_AI_SENSE_CONE_CONF = {
  Name = "NRC_AI_SENSE_CONE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_AI_SENSE_CONE_CONF.yaml",
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
      Description = "\230\132\159\231\159\165\233\148\165ID"
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
      Name = "sense_cone_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "UnitAISenseConeType"
        }
      },
      Description = "\230\132\159\231\159\165\233\148\165\231\177\187\229\158\139"
    },
    {
      Name = "enable_state_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StateType"
        }
      },
      Description = "\229\144\175\229\138\168\230\156\172\230\132\159\231\159\165\233\148\165\231\154\132\231\138\182\230\128\129"
    },
    {
      Name = "start_angle",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\183\229\167\139\232\167\146\229\186\166"
    },
    {
      Name = "end_angle",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\136\230\173\162\232\167\146\229\186\166"
    },
    {
      Name = "percep_radius",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\132\159\231\159\165\229\141\138\229\190\132"
    },
    {
      Name = "height_modify",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\171\152\229\186\166\228\191\174\230\173\163"
    },
    {
      Name = "percep_rate",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\132\159\231\159\165\229\128\188\229\162\158\233\149\191\233\128\159\229\186\166/\232\189\174"
    }
  }
}
RTTIManager:RegisterType(NRC_AI_SENSE_CONE_CONF.Name, NRC_AI_SENSE_CONE_CONF)

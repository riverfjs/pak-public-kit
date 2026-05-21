local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local RED_POINT_CONF = {
  Name = "RED_POINT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "red_point/RED_POINT_CONF.yaml",
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
      Description = "key"
    },
    {
      Name = "child_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "RED_POINT_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\155\184\233\130\187\228\184\139\228\184\128\229\177\130\229\173\144\231\186\162\231\130\185\239\188\136\229\161\171\229\175\185\229\186\148key\239\188\140\229\164\154\228\184\170\231\148\168;\233\154\148\229\188\128\239\188\137"
    },
    {
      Name = "change_reason",
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
          EnumName = "RedPointReason"
        }
      },
      Description = "\230\149\176\230\141\174\230\186\144\229\143\152\229\140\150\229\142\159\229\155\160"
    },
    {
      Name = "redpoint_type",
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
          EnumName = "RedPointType"
        }
      },
      Description = "\231\186\162\231\130\185\232\181\132\230\186\144\231\177\187\229\158\139"
    }
  }
}
RTTIManager:RegisterType(RED_POINT_CONF.Name, RED_POINT_CONF)

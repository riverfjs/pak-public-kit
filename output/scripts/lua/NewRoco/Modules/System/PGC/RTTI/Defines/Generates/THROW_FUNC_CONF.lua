local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local THROW_FUNC_CONF = {
  Name = "THROW_FUNC_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "bag_item/THROW_FUNC_CONF.yaml",
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
      Description = "\230\138\149\230\142\183\229\138\159\232\131\189id"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "throw_function",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ThrowFunction"
        }
      },
      Description = "\230\138\149\230\142\183\229\138\159\232\131\189\231\177\187\229\158\139"
    },
    {
      Name = "throw_target",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ThrowTarget"
        }
      },
      Description = "\230\138\149\230\142\183\229\144\136\230\179\149\231\155\174\230\160\135"
    },
    {
      Name = "throw_work_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ThrowWorkType"
        }
      },
      Description = "\230\138\149\230\142\183\231\148\159\230\149\136\230\150\185\229\188\143"
    },
    {
      Name = "throw_done",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ThrowDone"
        }
      },
      Description = "\230\138\149\230\142\183\229\144\136\230\179\149\230\149\136\230\158\156"
    },
    {
      Name = "throw_undone",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ThrowDone"
        }
      },
      Description = "\230\138\149\230\142\183\233\157\158\230\179\149\230\149\136\230\158\156"
    },
    {
      Name = "retrieve",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\135\170\229\138\168\229\155\158\230\148\182"
    }
  }
}
RTTIManager:RegisterType(THROW_FUNC_CONF.Name, THROW_FUNC_CONF)

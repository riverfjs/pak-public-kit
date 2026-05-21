local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TELEPORT_CONF = {
  Name = "TELEPORT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "teleport/TELEPORT_CONF.yaml",
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
      Description = "\228\188\160\233\128\129/\232\167\163\233\148\129\231\130\185ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "resurrection_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\189\146\229\177\158\231\177\187\229\158\139"
    },
    {
      Name = "teleport_actor_types",
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
          EnumName = "TeleportActorType"
        }
      },
      Description = "\228\188\160\233\128\129\230\186\144\231\186\166\230\157\159:"
    },
    {
      Name = "teleport_actor_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = " \228\188\160\233\128\129\230\186\144\231\186\166\230\157\159\229\143\130\230\149\176, \230\154\130\230\151\182\230\156\170\229\144\175\231\148\168"
    },
    {
      Name = "teleport_begin_point_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TeleportBeginPointType"
        }
      },
      Description = "\228\188\160\233\128\129\232\181\183\229\167\139\229\156\176\231\186\166\230\157\159:"
    },
    {
      Name = "teleport_dest_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TeleportDestType"
        }
      },
      Description = "\228\188\160\233\128\129\231\155\174\231\154\132\229\156\176\231\177\187\229\158\139\239\188\136\229\141\149\230\156\186\239\188\137"
    },
    {
      Name = "teleport_dest",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TELEPORT_CONF_teleport_dest"
        }
      },
      Description = "\228\188\160\233\128\129\231\155\174\231\154\132\229\156\176\230\149\176\231\187\132\239\188\136\229\141\149\230\156\186\239\188\137"
    },
    {
      Name = "teleport_dest_online",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "TELEPORT_CONF_teleport_dest_online"
        }
      },
      Description = "\232\129\148\230\156\186\228\184\139\228\188\160\233\128\129\230\152\175\229\156\134\231\142\175\232\140\131\229\155\180\229\134\133\233\154\143\230\156\186\233\128\137\231\130\185\239\188\136\232\175\165\230\149\176\231\187\132\233\133\141\231\189\174\239\188\137"
    }
  }
}
RTTIManager:RegisterType(TELEPORT_CONF.Name, TELEPORT_CONF)

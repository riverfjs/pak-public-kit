local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local INSPIRE_LEVEL_CONF = {
  Name = "INSPIRE_LEVEL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/INSPIRE_LEVEL_CONF.yaml",
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
      Description = "\232\167\137\233\134\146\230\152\159\231\186\167"
    },
    {
      Name = "require_item",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 3
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "INSPIRE_LEVEL_CONF_require_item"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "grow_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "GROW_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\175\165\230\152\159\231\186\167\230\143\144\229\141\135\232\135\179\231\154\132\230\136\144\233\149\191\231\173\137\231\186\167 "
    },
    {
      Name = "type_enhance_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\172\231\179\187\228\188\164\229\174\179\229\188\186\229\140\150\231\154\132\229\138\160\230\136\144\230\149\176\229\128\188\239\188\136\228\184\135\229\136\134\230\175\148\231\180\175\229\138\160\230\149\176\229\128\188\239\188\137"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING,
          Size = 2
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "attr",
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
          TypeName = "INSPIRE_LEVEL_CONF_attr"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(INSPIRE_LEVEL_CONF.Name, INSPIRE_LEVEL_CONF)

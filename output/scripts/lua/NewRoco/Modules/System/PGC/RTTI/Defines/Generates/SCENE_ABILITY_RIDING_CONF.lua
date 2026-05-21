local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_ABILITY_RIDING_CONF = {
  Name = "SCENE_ABILITY_RIDING_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/SCENE_ABILITY_RIDING_CONF.yaml",
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
      Description = "ID\239\188\1361330001~1360000\239\188\137"
    },
    {
      Name = "accelerate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\138\160\233\128\159\229\186\166"
    },
    {
      Name = "ride_max_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\156\128\229\164\167\232\183\145\229\138\168\233\128\159\229\186\166"
    },
    {
      Name = "ride_delta_angular_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\170\145\228\185\152\229\165\148\232\183\145\228\184\173\230\175\143\231\167\146\230\156\128\229\164\167\232\189\172\232\191\135\232\167\146\229\186\166"
    },
    {
      Name = "dash_ability_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_ABILITY_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\134\178\229\136\186\230\138\128\232\131\189ID"
    },
    {
      Name = "off_ability_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_ABILITY_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132\232\167\163\233\153\164\230\138\128\232\131\189ID"
    }
  }
}
RTTIManager:RegisterType(SCENE_ABILITY_RIDING_CONF.Name, SCENE_ABILITY_RIDING_CONF)

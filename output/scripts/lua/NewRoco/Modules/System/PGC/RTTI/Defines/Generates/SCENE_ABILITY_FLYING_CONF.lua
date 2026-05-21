local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_ABILITY_FLYING_CONF = {
  Name = "SCENE_ABILITY_FLYING_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/SCENE_ABILITY_FLYING_CONF.yaml",
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
      Name = "jump_height",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\232\183\179\232\183\131\233\171\152\229\186\166"
    },
    {
      Name = "gravity",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\233\135\141\229\138\155\231\179\187\230\149\176"
    },
    {
      Name = "max_downward_spd",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\156\128\229\164\167\228\184\139\232\144\189\233\128\159\229\186\166"
    },
    {
      Name = "basic_movement_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\231\167\187\229\138\168\230\168\161\229\188\143ID(\228\189\147\229\138\155\230\182\136\232\128\151\230\149\176\230\141\174\232\189\172\229\173\152\229\156\168\232\191\153\233\135\140)"
    },
    {
      Name = "max_speed_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\160\233\128\159\230\155\178\231\186\191"
    },
    {
      Name = "accelerate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\176\180\229\185\179\229\138\160\233\128\159\229\186\166"
    },
    {
      Name = "turn_threshold",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\232\189\172\232\186\171\232\167\146\229\186\166\233\152\136\229\128\188"
    },
    {
      Name = "fly_delta_angular_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\156\128\229\164\167\232\189\172\232\186\171\233\128\159\231\142\135"
    },
    {
      Name = "ride_pet_bp",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\170\145\228\185\152\229\174\160\231\137\169\232\147\157\229\155\190\232\183\175\229\190\132"
    },
    {
      Name = "ascend_ability_id",
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
      Description = "\233\163\158\229\141\135\230\138\128\232\131\189ID"
    },
    {
      Name = "jump_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\183\131\230\155\178\231\186\191"
    }
  }
}
RTTIManager:RegisterType(SCENE_ABILITY_FLYING_CONF.Name, SCENE_ABILITY_FLYING_CONF)

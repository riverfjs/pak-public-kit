local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_ABILITY_THROW_CONF = {
  Name = "SCENE_ABILITY_THROW_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/SCENE_ABILITY_THROW_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "throw_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneThrowAbilityType"
        }
      },
      Description = "\230\138\149\230\142\183\231\138\182\230\128\129"
    },
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
      Description = "ID\239\188\1361300001~1390000\239\188\137"
    },
    {
      Name = "limit_pitch",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\153\144\229\136\182\228\191\175\228\187\176"
    },
    {
      Name = "pitch_max",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\164\167\228\191\175\228\187\176\232\167\146\229\186\166"
    },
    {
      Name = "pitch_min",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\176\143\228\191\175\228\187\176\232\167\146\229\186\166"
    },
    {
      Name = "limit_yaw",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\153\144\229\136\182\229\129\143\232\136\170"
    },
    {
      Name = "yaw_max",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\164\167\229\129\143\232\136\170\232\167\146\229\186\166"
    },
    {
      Name = "yaw_min",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\176\143\229\129\143\232\136\170\232\167\146\229\186\166"
    },
    {
      Name = "rideaim_pet_turn_speed",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\151\139\232\189\172\233\128\159\231\142\135"
    }
  }
}
RTTIManager:RegisterType(SCENE_ABILITY_THROW_CONF.Name, SCENE_ABILITY_THROW_CONF)

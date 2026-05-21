local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_ABILITY_SLIDING_CONF = {
  Name = "SCENE_ABILITY_SLIDING_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/SCENE_ABILITY_SLIDING_CONF.yaml",
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
      Description = "ID\239\188\1361360001~1390000\239\188\137"
    },
    {
      Name = "allow_long_press",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\129\232\174\184\233\149\191\230\140\137"
    },
    {
      Name = "speed_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\159\229\186\166\230\155\178\231\186\191"
    },
    {
      Name = "slide_accelerate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\229\138\160\233\128\159\229\186\166"
    },
    {
      Name = "vitality_cost_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\229\138\155\230\182\136\232\128\151\230\155\178\231\186\191"
    },
    {
      Name = "acc_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\160\233\128\159\230\155\178\231\186\191"
    },
    {
      Name = "deacc_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\143\233\128\159\230\155\178\231\186\191"
    },
    {
      Name = "vitality_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "VITALITY_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\189\147\229\138\155\233\133\141\231\189\174ID"
    },
    {
      Name = "slide_start_vitality_cost",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\188\128\229\144\175\230\187\145\232\161\140\230\137\128\233\156\128\231\154\132\230\156\128\229\176\143\228\189\147\229\138\155\228\189\153\233\135\143"
    },
    {
      Name = "slide_cooldown",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\178\229\136\186\230\140\137\233\146\174\229\147\141\229\186\148CD"
    },
    {
      Name = "slide_rotate_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\178\229\136\186\228\184\173\230\175\143\231\167\146\230\156\128\229\164\167\232\189\172\232\191\135\232\167\146\229\186\166"
    },
    {
      Name = "slide_required_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\176\143\231\187\180\230\140\129\233\128\159\229\186\166"
    },
    {
      Name = "slide_start_speed",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\229\188\128\229\167\139\233\128\159\229\186\166"
    },
    {
      Name = "slide_joystick_sensity",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\230\145\135\230\157\134\231\129\181\230\149\143\229\186\166\239\188\136\229\128\188\232\182\138\229\164\167\232\182\138\231\129\181\230\149\143\239\188\137"
    },
    {
      Name = "slide_trigger_delay",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\232\167\166\229\143\145\229\187\182\232\191\159"
    },
    {
      Name = "slide_ability_maintain_time",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\230\138\128\232\131\189\230\156\128\229\176\143\228\191\157\230\140\129\230\151\182\233\151\180"
    },
    {
      Name = "slide_ability_cooldown_time",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\230\138\128\232\131\189\229\134\183\229\141\180\230\151\182\233\151\180"
    },
    {
      Name = "slide_min_angle",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\230\156\128\229\176\143\229\157\161\229\186\166\239\188\136\232\180\159\230\149\176\232\161\168\231\164\186\228\184\139\229\157\161\239\188\137"
    },
    {
      Name = "slide_max_angle",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\187\145\232\161\140\230\156\128\229\164\167\229\157\161\229\186\166"
    },
    {
      Name = "maintain_press_time",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\191\157\230\140\129\229\134\178\229\136\186\231\154\132\230\140\137\229\142\139\230\151\182\233\151\180"
    }
  }
}
RTTIManager:RegisterType(SCENE_ABILITY_SLIDING_CONF.Name, SCENE_ABILITY_SLIDING_CONF)

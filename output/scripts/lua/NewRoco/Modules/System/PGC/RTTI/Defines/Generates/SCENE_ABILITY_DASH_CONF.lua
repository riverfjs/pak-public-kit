local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_ABILITY_DASH_CONF = {
  Name = "SCENE_ABILITY_DASH_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/SCENE_ABILITY_DASH_CONF.yaml",
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
      Name = "dash_accelerate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\134\178\229\136\186\229\138\160\233\128\159\229\186\166"
    },
    {
      Name = "dash_acc_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\160\233\128\159\230\155\178\231\186\191\227\128\144\230\173\164\229\173\151\230\174\181\229\186\159\229\188\131\227\128\145"
    },
    {
      Name = "dash_deacc_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\143\233\128\159\230\155\178\231\186\191\227\128\144\230\173\164\229\173\151\230\174\181\229\186\159\229\188\131\227\128\145"
    },
    {
      Name = "speed_curve",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\178\229\136\186\233\128\159\229\186\166\230\155\178\231\186\191\227\128\144\230\173\164\229\173\151\230\174\181\229\186\159\229\188\131\227\128\145"
    },
    {
      Name = "dash_max_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\134\178\229\136\186\230\158\129\233\128\159"
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
      Description = "\228\189\147\229\138\155ID"
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
      Name = "dash_start_vitality_cost",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\188\128\229\144\175\229\134\178\229\136\186\230\137\128\233\156\128\231\154\132\230\156\128\229\176\143\228\189\147\229\138\155\228\189\153\233\135\143"
    },
    {
      Name = "dash_duration",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\188\128\229\144\175\229\134\178\229\136\186\230\151\182\231\154\132\230\158\129\233\128\159\230\174\181\230\151\182\233\149\191"
    },
    {
      Name = "dashing_vitality_cost",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\129\231\187\173\229\134\178\229\136\186\228\184\173\231\154\132\228\189\147\229\138\155\230\175\143\231\167\146\230\137\163\229\135\143"
    },
    {
      Name = "dash_cooldown",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\178\229\136\186\230\140\137\233\146\174\229\147\141\229\186\148CD"
    },
    {
      Name = "dash_rotate_speed",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\178\229\136\186\228\184\173\230\175\143\231\167\146\230\156\128\229\164\167\232\189\172\232\191\135\232\167\146\229\186\166"
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
RTTIManager:RegisterType(SCENE_ABILITY_DASH_CONF.Name, SCENE_ABILITY_DASH_CONF)

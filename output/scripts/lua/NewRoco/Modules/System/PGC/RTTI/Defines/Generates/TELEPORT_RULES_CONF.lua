local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local TELEPORT_RULES_CONF = {
  Name = "TELEPORT_RULES_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "teleport/TELEPORT_RULES_CONF.yaml",
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
      Description = "\228\188\160\233\128\129\232\167\132\229\136\153"
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
      Name = "range",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\135\135\230\160\183\232\140\131\229\155\180\239\188\136\229\141\149\228\189\141cm,\229\141\138\229\190\132\239\188\137"
    },
    {
      Name = "deviation",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\129\232\174\184\233\171\152\229\186\166\229\183\174\229\188\130\239\188\136\229\141\149\228\189\141cm\239\188\137"
    },
    {
      Name = "towards",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\157\229\144\145\239\188\1361\229\167\139\231\187\136\230\156\157\229\144\145\231\155\174\230\160\135NPC\239\188\1550\230\151\160\239\188\137"
    },
    {
      Name = "fail_add_z",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\188\160\233\128\129\229\164\177\232\180\165\230\151\182\228\184\138\232\176\131\231\154\132z\229\157\144\230\160\135\229\141\149\228\189\141"
    },
    {
      Name = "not_use_protect_place",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\144\175\231\148\168\228\191\157\229\186\149\228\188\160\233\128\129\231\130\185\239\188\136\230\151\160\230\179\149\228\188\160\232\191\135\229\142\187\228\188\154\231\155\180\230\142\165\229\188\185\228\184\154\229\138\161\230\143\144\231\164\186\239\188\137\239\188\140\233\133\1411\229\136\153\228\184\186\228\184\141\229\144\175\231\148\168\239\188\140\233\187\152\232\174\164\229\144\175\231\148\168"
    }
  }
}
RTTIManager:RegisterType(TELEPORT_RULES_CONF.Name, TELEPORT_RULES_CONF)

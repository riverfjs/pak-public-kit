local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BREAK_NUMBER_CONF = {
  Name = "BREAK_NUMBER_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/BREAK_NUMBER_CONF.yaml",
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
      Description = "\233\152\182\230\149\176"
    },
    {
      Name = "require_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\156\128\230\177\130\231\178\190\231\129\181\231\173\137\231\186\167"
    },
    {
      Name = "require_grow_time",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\156\128\230\177\130\230\136\144\233\149\191\230\172\161\230\149\176"
    },
    {
      Name = "type_item_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\179\187\229\136\171\230\157\144\230\150\153\230\149\176\233\135\143"
    },
    {
      Name = "cost_item_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\135\135\233\155\134\231\137\169\230\149\176\233\135\143"
    },
    {
      Name = "dust_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\137\229\176\152\230\149\176\233\135\143"
    },
    {
      Name = "spec_item_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\157\144\230\150\153\230\149\176\233\135\143"
    },
    {
      Name = "currency_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\180\167\229\184\129\231\177\187\229\158\139"
    },
    {
      Name = "currency_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\180\167\229\184\129\230\149\176\233\135\143"
    },
    {
      Name = "world_level_limit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\137\128\233\156\128\233\173\148\230\179\149\231\173\137\231\186\167\239\188\136\229\186\159\229\188\131\239\188\137"
    },
    {
      Name = "free_type_item_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\148\190\231\148\159\232\191\148\232\191\152\231\179\187\229\136\171\230\157\144\230\150\153\230\149\176\233\135\143"
    },
    {
      Name = "free_memory_item_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\148\190\231\148\159\232\191\148\232\191\152\232\174\176\229\191\134\230\157\144\230\150\153\230\149\176\233\135\143"
    }
  }
}
RTTIManager:RegisterType(BREAK_NUMBER_CONF.Name, BREAK_NUMBER_CONF)

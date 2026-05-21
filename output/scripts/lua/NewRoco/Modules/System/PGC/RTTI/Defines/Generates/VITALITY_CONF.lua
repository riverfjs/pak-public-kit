local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local VITALITY_CONF = {
  Name = "VITALITY_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene_ability/VITALITY_CONF.yaml",
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
      Description = "0\239\188\154\228\184\187\232\167\146\239\188\155\229\133\182\228\187\150\230\140\137ID\231\180\162\229\188\149"
    },
    {
      Name = "max_vitality",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\156\128\229\164\167\228\189\147\229\138\155\229\128\188"
    },
    {
      Name = "vitality_recover_delay",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\229\138\155\230\129\162\229\164\141\229\187\182\232\191\159(\230\175\171\231\167\146)"
    },
    {
      Name = "vitality_recover",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\229\138\155\230\175\143\231\167\146\230\129\162\229\164\141\229\128\188"
    },
    {
      Name = "vitality_recover_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\229\138\155\230\175\143\231\167\146\230\129\162\229\164\141\239\188\136\230\156\128\229\164\167\228\189\147\229\138\155\231\153\190\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "vitality_recover_idle",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "Idle\228\189\147\229\138\155\230\175\143\231\167\146\233\162\157\229\164\150\230\129\162\229\164\141\229\128\188"
    },
    {
      Name = "vitality_recover_percent_idle",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "Idle\228\189\147\229\138\155\230\175\143\231\167\146\233\162\157\229\164\150\230\129\162\229\164\141\239\188\136\230\156\128\229\164\167\228\189\147\229\138\155\231\153\190\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "forbid_status",
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
          EnumName = "WorldPlayerStatusType"
        }
      },
      Description = "\231\166\129\230\173\162\230\129\162\229\164\141\231\154\132\231\138\182\230\128\129"
    }
  }
}
RTTIManager:RegisterType(VITALITY_CONF.Name, VITALITY_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local AREA_VISIBLE_CONF = {
  Name = "AREA_VISIBLE_CONF",
  Version = 1,
  Description = "\229\159\186\228\186\142AREA\232\161\168\239\188\140\228\184\186\229\140\186\229\159\159\232\181\139\228\186\136\228\186\146\232\167\129\229\140\186\229\138\159\232\131\189\239\188\140\229\185\182\230\140\135\229\174\154\230\173\164\228\186\146\232\167\129\229\140\186\230\156\128\229\164\154\230\148\175\230\140\129\229\135\160\228\186\186\228\186\146\232\167\129",
  Metadata = {
    Alias = "\228\186\146\232\167\129\229\140\186\232\161\168",
    RelativeYamlPath = "area/AREA_VISIBLE_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\140\186\229\159\159ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\232\167\129\229\140\186\229\164\135\230\179\168"
    },
    {
      Name = "editor_name1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "visible_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "VisibleType"
        }
      },
      Description = "\229\140\186\229\159\159\231\177\187\229\158\139"
    },
    {
      Name = "area_visible_density",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AreaVisibleDensity"
        }
      },
      Description = "\229\140\186\229\159\159\228\186\186\229\138\155\231\131\173\229\186\166\231\177\187\229\158\139(\231\148\168\230\157\165\232\161\161\233\135\143\229\136\134\233\133\141\229\135\160\228\184\170\230\146\174\229\144\136\230\156\141)"
    },
    {
      Name = "visible_area_default_close",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\187\152\232\174\164\229\133\179\233\151\173\239\188\136\228\184\187\232\166\129\230\152\175\230\180\187\229\138\168\231\177\187\229\158\139\229\138\168\230\128\129\229\188\128\229\144\175\231\154\132\228\186\146\232\167\129\229\140\186,\232\183\159\231\157\128\230\180\187\229\138\168\229\188\128\229\144\175\231\154\132\229\136\157\229\167\139\233\133\141TRUE\239\188\137"
    },
    {
      Name = "area_visible_player_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\232\167\129\229\140\186\230\156\128\229\164\167\229\143\175\232\167\129\228\186\186\230\149\176"
    },
    {
      Name = "area_visible_merge_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\232\167\129\229\140\186\229\144\136\229\185\182\233\152\136\229\128\188"
    },
    {
      Name = "area_visible_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\186\146\232\167\129\229\140\186\229\140\186\229\159\159\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "area_visible_player_online_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\189\147\229\137\141\228\186\146\232\167\129\229\140\186\230\156\128\229\164\154\232\131\189\229\140\185\233\133\141\229\135\160\228\184\170\228\186\146\232\174\191\233\152\159\228\188\141"
    },
    {
      Name = "area_visible_player_friend_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\165\189\229\143\139\230\186\162\229\135\186\230\149\176\233\135\143\228\184\138\233\153\144"
    },
    {
      Name = "buffer_dist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\188\147\229\134\178\229\140\186\229\174\189\229\186\166(cm)\239\188\140\228\184\141\229\144\175\231\148\168"
    },
    {
      Name = "area_visible_special_rule",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\146\232\167\129\229\140\186\228\184\187\233\162\152"
    },
    {
      Name = "area_visible_special_rule_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\146\232\167\129\229\140\186\228\184\187\233\162\152\229\143\130\230\149\1761"
    }
  }
}
RTTIManager:RegisterType(AREA_VISIBLE_CONF.Name, AREA_VISIBLE_CONF)

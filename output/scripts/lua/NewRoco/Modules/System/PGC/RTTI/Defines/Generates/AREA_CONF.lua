local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local AREA_CONF = {
  Name = "AREA_CONF",
  Version = 1,
  Description = "\231\174\161\231\144\134\229\156\186\230\153\175\228\184\173\230\137\128\230\156\137NPC\229\146\140\229\144\132\231\177\187\229\140\186\229\159\159\232\140\131\229\155\180\231\173\137\229\156\186\230\153\175\229\156\176\231\144\134\228\191\161\230\129\175\231\154\132\232\161\168",
  Metadata = {
    Alias = "area\232\161\168",
    RelativeYamlPath = "area/AREA_CONF.yaml",
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
        }
      },
      Description = "\229\140\186\229\159\159ID"
    },
    {
      Name = "scene_res_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_RES_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\229\156\186\230\153\175\232\181\132\230\186\144id"
    },
    {
      Name = "scene_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\229\156\186\230\153\175id"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING,
          Size = 3
        }
      },
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "area_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AreaType"
        }
      },
      Description = "\229\140\186\229\159\159\231\177\187\229\158\139"
    },
    {
      Name = "is_visible",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\129\148\230\156\186\229\140\186\229\159\159"
    },
    {
      Name = "is_special",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\137\185\230\174\138\229\140\186\229\159\159\239\188\136\228\187\133\231\188\150\232\190\145\229\153\168\230\160\135\231\173\190\231\148\168\239\188\137"
    },
    {
      Name = "is_teleport",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\188\160\233\128\129\229\140\186\229\159\159\239\188\136\228\187\133\231\188\150\232\190\145\229\153\168\230\160\135\231\173\190\231\148\168\239\188\137"
    },
    {
      Name = "is_bt_use",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\161\140\228\184\186\230\160\145\229\188\149\231\148\168\229\140\186\229\159\159\239\188\136\228\187\133\231\188\150\232\190\145\229\153\168\230\160\135\231\173\190\231\148\168\239\188\137"
    },
    {
      Name = "area_layer",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\140\186\229\159\159\229\155\190\229\177\130\231\177\187\229\158\139"
    },
    {
      Name = "stealth_on",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {},
      Description = "\229\143\175\229\144\166\230\189\156\232\161\140"
    },
    {
      Name = "is_open",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ResponseBlockType"
        }
      },
      Description = "\229\143\175\229\144\166\229\147\141\229\186\148\232\141\137\228\184\155\229\164\150\231\142\169\229\174\182"
    },
    {
      Name = "area_height",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\140\186\229\159\159\233\171\152\229\186\166"
    },
    {
      Name = "pos",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 70
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "AREA_CONF_pos"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "pos_empty",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 14
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "AREA_CONF_pos_empty"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "center_xyz",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\140\186\229\159\159\228\184\173\229\191\131\231\130\185\229\157\144\230\160\135"
    },
    {
      Name = "falcon_map_data_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "falcon\230\155\178\231\186\191ID"
    }
  }
}
RTTIManager:RegisterType(AREA_CONF.Name, AREA_CONF)

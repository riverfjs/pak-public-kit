local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BLOCK_CONF = {
  Name = "BLOCK_CONF",
  Version = 1,
  Description = "\233\133\141\231\189\174\230\184\184\230\136\143\229\134\133\229\144\132\231\177\187\231\169\186\230\176\148\229\162\153\231\154\132\232\140\131\229\155\180\239\188\140\228\184\128\232\136\172\228\189\191\231\148\168\229\156\176\231\188\150\230\136\150falconmap\229\175\188\229\135\186\231\169\186\230\176\148\229\162\153\239\188\140\229\175\188\229\133\165\229\136\176spline\232\161\168\229\144\142\239\188\140\229\134\141\228\187\142spline\229\164\132\229\164\141\229\136\182\232\191\135\230\157\165",
  Metadata = {
    Alias = "\231\169\186\230\176\148\229\162\153\232\161\168",
    RelativeYamlPath = "world_combat/BLOCK_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "block_up_height",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\144\145\228\184\138\232\163\129\229\137\170\233\171\152\229\186\166\239\188\136\229\141\149\228\189\141\229\142\152\231\177\179\239\188\137"
    },
    {
      Name = "block_down_height",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\144\145\228\184\139\232\163\129\229\137\170\233\171\152\229\186\166\239\188\136\229\141\149\228\189\141\229\142\152\231\177\179\239\188\137"
    },
    {
      Name = "block_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldCombatBlockType"
        }
      },
      Description = "\232\190\185\231\149\140\231\177\187\229\158\139"
    },
    {
      Name = "is_block_reversed",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\169\186\230\176\148\229\162\153\230\150\185\229\144\145\230\152\175\229\144\166\229\144\145\229\134\133\228\190\167"
    },
    {
      Name = "reverse_face",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\141\232\189\172\229\162\153\233\157\162?"
    },
    {
      Name = "is_block_detection",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\156\128\232\166\129\229\138\160\228\191\157\229\186\149\230\163\128\230\181\139\230\156\186\229\136\182\239\188\1361\233\156\128\232\166\129\239\188\137"
    },
    {
      Name = "block_scene_res_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_RES_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\160\228\191\157\229\186\149\230\156\186\229\136\182\230\163\128\230\181\139\231\169\186\230\176\148\229\162\153\229\175\185\229\186\148SCENE_RES_CONF\231\154\132ID\239\188\136\233\156\128\232\166\129\230\163\128\230\181\139\228\189\134\230\156\170\233\133\141\231\189\174\233\187\152\232\174\16410003\239\188\137"
    },
    {
      Name = "is_block_alltime",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\153\187\229\189\149\230\184\184\230\136\143\229\144\142\228\184\128\231\155\180\230\163\128\230\181\139"
    },
    {
      Name = "id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\230\160\183\230\157\161id"
    },
    {
      Name = "AirWallSerPosition",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\156\141\229\138\161\229\153\168\231\148\168\231\130\185\239\188\129\239\188\129\239\188\129"
    },
    {
      Name = "position",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\160\183\230\157\161\230\156\172\228\189\147\228\189\141\231\189\174"
    },
    {
      Name = "rotation",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\160\183\230\157\161\230\156\172\228\189\147\230\151\139\232\189\172"
    },
    {
      Name = "scale",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\160\183\230\157\161\230\156\172\228\189\147\231\188\169\230\148\190"
    },
    {
      Name = "contained_area_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\231\148\159\230\136\144\231\154\132\229\133\179\232\129\148\229\140\186\229\159\159"
    },
    {
      Name = "bp_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = ""
    },
    {
      Name = "spline_point",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 200
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "BLOCK_CONF_spline_point"
        }
      },
      Description = ""
    }
  }
}
RTTIManager:RegisterType(BLOCK_CONF.Name, BLOCK_CONF)

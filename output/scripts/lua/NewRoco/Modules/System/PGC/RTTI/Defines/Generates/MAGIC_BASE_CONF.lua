local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MAGIC_BASE_CONF = {
  Name = "MAGIC_BASE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "magic_base_conf/MAGIC_BASE_CONF.yaml",
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
      Description = "\233\173\148\230\179\149id"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "name"
        }
      },
      Description = "\233\173\148\230\179\149\229\144\141\231\167\176"
    },
    {
      Name = "magic_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\173\148\230\179\149\229\156\168\233\157\162\230\157\191\228\184\173\231\154\132\230\142\146\229\186\143"
    },
    {
      Name = "localization_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "LOCALIZATION_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\142\183\229\190\151\233\173\148\230\179\149\230\151\182\231\154\132\229\144\141\231\167\176\239\188\136\229\175\185\229\186\148localization_conf\231\154\132id\239\188\137"
    },
    {
      Name = "get_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\142\183\229\143\150\233\173\148\230\179\149\230\151\182\231\154\132ICON"
    },
    {
      Name = "magic_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneMagicType"
        }
      },
      Description = "\233\173\148\230\179\149\231\177\187\229\158\139"
    },
    {
      Name = "charge_type",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\133\232\131\189\231\177\187\229\158\139\239\188\1400\231\158\172\229\143\145\239\188\1401\232\147\132\229\138\155"
    },
    {
      Name = "vitality_cost_minimum",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\228\189\142\228\189\147\229\138\155\230\182\136\232\128\151"
    },
    {
      Name = "vitality_cost_perscond",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\175\143\231\167\146\228\189\147\229\138\155\230\182\136\232\128\151\239\188\136\232\147\132\229\138\155\239\188\137"
    },
    {
      Name = "vitality_cost_charge",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\147\132\229\138\155\229\144\132\230\174\181\228\189\147\229\138\155\230\182\136\232\128\151"
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
      Name = "charge_time",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\147\132\229\138\155\229\144\132\230\174\181\230\151\182\233\151\180"
    },
    {
      Name = "charge_parameter",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\147\132\229\138\155\229\144\132\230\174\181\229\143\130\230\149\176"
    },
    {
      Name = "maxcount",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\164\167\229\173\152\229\156\168\230\149\176\233\135\143"
    },
    {
      Name = "cost_bag_item",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\182\136\232\128\151\232\131\140\229\140\133\233\129\147\229\133\183"
    },
    {
      Name = "sceneability",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_ABILITY_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175\232\131\189\229\138\155ID"
    },
    {
      Name = "effect_struct",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 2
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "MAGIC_BASE_CONF_effect_struct"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(MAGIC_BASE_CONF.Name, MAGIC_BASE_CONF)

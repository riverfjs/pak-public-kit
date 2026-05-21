local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local LAYERED_WORLD_MAP_CONF = {
  Name = "LAYERED_WORLD_MAP_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "world_map/LAYERED_WORLD_MAP_CONF.yaml",
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
      Description = "\229\156\176\228\184\139\229\156\176\229\155\190ID"
    },
    {
      Name = "area_func_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_FUNC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\140\186\229\159\159ID"
    },
    {
      Name = "map_resource",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\228\184\139\229\156\176\229\155\190\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "map_layer_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\228\184\139\229\156\176\229\155\190\231\187\132\229\136\171"
    },
    {
      Name = "map_sort_order",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\228\184\139\229\156\176\229\155\190\230\152\190\231\164\186\230\142\146\229\186\143"
    },
    {
      Name = "map_layer_icon_select",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\229\177\130\229\156\176\229\155\190\229\177\130\231\186\167\229\136\135\230\141\162\230\160\135\232\175\134icon\239\188\136\232\162\171\233\128\137\228\184\173\239\188\137"
    },
    {
      Name = "map_layer_icon_unselected",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\229\177\130\229\156\176\229\155\190\229\177\130\231\186\167\229\136\135\230\141\162\230\160\135\232\175\134icon\239\188\136\230\156\170\233\128\137\228\184\173\239\188\137"
    },
    {
      Name = "display_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "display_name"
        }
      },
      Description = "\229\156\176\228\184\139\229\156\176\229\155\190\229\144\141\231\167\176"
    },
    {
      Name = "camera_center",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\155\184\230\156\186\228\184\173\229\191\131\231\130\185"
    },
    {
      Name = "Ortho_width",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\157\151\229\174\189\229\186\166"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "map_layer_unlock_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MapLayerUnlockType"
        }
      },
      Description = "\232\167\163\233\148\129\229\136\134\229\177\130\229\156\176\229\155\190\231\154\132\231\177\187\229\158\139"
    },
    {
      Name = "para",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\143\130\230\149\176"
    },
    {
      Name = "belong_camp",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\233\173\148\229\138\155\228\185\139\230\186\144ID"
    },
    {
      Name = "scene_res_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_RES_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175ID"
    }
  }
}
RTTIManager:RegisterType(LAYERED_WORLD_MAP_CONF.Name, LAYERED_WORLD_MAP_CONF)

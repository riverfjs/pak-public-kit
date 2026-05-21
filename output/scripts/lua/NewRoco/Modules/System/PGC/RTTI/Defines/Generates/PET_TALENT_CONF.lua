local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_TALENT_CONF = {
  Name = "PET_TALENT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_TALENT_CONF.yaml",
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
      Description = "\231\137\185\233\149\191id"
    },
    {
      Name = "editor_name1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "editor_name2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "pettalentname"
        }
      },
      Description = "\231\137\185\233\149\191\229\144\141\231\167\176"
    },
    {
      Name = "spec_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "pettalenttxt"
        }
      },
      Description = "\231\137\185\230\174\138\230\143\143\232\191\176"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "pettalentdesc"
        }
      },
      Description = "\231\137\185\233\149\191\230\149\136\230\158\156\230\143\143\232\191\176"
    },
    {
      Name = "active_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\157\161\228\187\182\230\163\128\230\181\139\231\177\187\229\158\139(=0\230\151\160\230\132\143\228\185\137\239\188\155=1\232\161\168\231\164\186\230\136\152\230\150\151\229\133\165\229\156\186\230\151\182\239\188\155=2\232\161\168\231\164\186\229\155\158\229\144\136\229\188\128\229\167\139\230\151\182)"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\233\149\191\229\136\134\231\177\187(\228\187\133\231\148\168\228\186\142\229\137\141\229\143\176\227\128\130=1\232\161\168\231\164\186\228\184\150\231\149\140\231\148\159\228\186\167\231\177\187\239\188\140=2\232\161\168\231\164\186\231\178\190\231\129\181\230\151\133\232\161\140\239\188\140=3\232\161\168\231\164\186\229\174\182\229\155\173\231\148\159\228\186\167\231\177\187\239\188\140=4\232\161\168\231\164\186\228\184\150\231\149\140\229\134\146\233\153\169\231\177\187\239\188\140=5\232\161\168\231\164\186\229\177\128\229\134\133\230\136\152\230\150\151\231\177\187)"
    },
    {
      Name = "filter_enum_value",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\149\140\233\157\162\231\173\155\233\128\137\229\136\134\231\177\187"
    },
    {
      Name = "priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "condition_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 3
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_TALENT_CONF_condition_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "can_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\155\184\229\144\140\231\137\185\233\149\191\232\131\189\229\144\166\229\143\160\229\138\160\239\188\1360=\228\184\141\233\153\144\229\136\182\229\143\160\229\138\160\239\188\1551=\228\184\141\229\143\175\229\143\160\229\138\160\239\188\1552=\229\143\175\228\187\165\229\143\160\229\138\1602\230\172\161\239\188\1553=\229\143\175\228\187\165\229\143\160\229\138\1603\230\172\161\226\128\166\239\188\137"
    },
    {
      Name = "effect_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 10
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_TALENT_CONF_effect_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "remove",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\139\230\158\182"
    },
    {
      Name = "new_talent_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_TALENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\139\230\158\182\229\144\142\230\155\191\230\141\162\231\137\185\233\149\191"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\233\149\191icon"
    },
    {
      Name = "talent_color",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\233\149\191\230\149\136\230\158\156\229\173\151\232\137\178(\229\174\182\229\155\173\227\128\129\230\151\133\232\161\140\231\173\137\231\149\140\233\157\162\228\188\154\231\148\168\229\136\176\239\188\140\229\162\158\231\155\138\230\152\175\231\187\1915C9F11FF\227\128\129\229\135\143\231\155\138\230\152\175\231\186\162AE3D3EFF\227\128\129\230\151\160\229\162\158\231\155\138\230\152\175\233\187\145272727FF/\233\133\141\231\169\186)"
    },
    {
      Name = "icon_visible_switch",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\156\168\229\150\130\229\133\187\229\128\146\232\174\161\230\151\182\230\142\167\228\187\182\228\184\138\230\152\190\231\164\186icon"
    }
  }
}
RTTIManager:RegisterType(PET_TALENT_CONF.Name, PET_TALENT_CONF)

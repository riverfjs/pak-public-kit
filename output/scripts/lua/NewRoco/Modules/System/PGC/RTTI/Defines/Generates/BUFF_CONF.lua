local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BUFF_CONF = {
  Name = "BUFF_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "skill/BUFF_CONF.yaml",
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
      Description = "BUFF\231\187\132ID\239\188\140ID\230\174\181800000~899999"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\231\173\150\229\136\146\230\143\143\232\191\176"
    },
    {
      Name = "buff_base_ids",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BUFFBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "buffbase\232\161\168id"
    },
    {
      Name = "buff_list_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "icon\229\140\186\230\142\146\229\186\143\230\157\131\233\135\141"
    },
    {
      Name = "buff_groupsigns",
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
          EnumName = "BuffGroupSign"
        }
      },
      Description = "buff\230\149\176\231\187\132\231\177\187\229\158\139"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "BUFF\231\187\132\229\144\141\231\167\176"
    },
    {
      Name = "type_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "BUFF\231\177\187\229\158\139id"
    },
    {
      Name = "add_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\153\132\229\138\160\230\151\182\231\154\132buff\229\134\146\229\173\151"
    },
    {
      Name = "add_icon",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AddIcon"
        }
      },
      Description = "\233\153\132\229\138\160\230\151\182\231\154\132\229\173\151\228\189\147\233\162\156\232\137\178\239\188\140\228\184\141\229\134\141\228\184\147\230\140\135icon"
    },
    {
      Name = "trigger_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\151\182\231\154\132buff\229\134\146\229\173\151"
    },
    {
      Name = "trigger_icon",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AddIcon"
        }
      },
      Description = "\232\167\166\229\143\145\230\151\182\231\154\132\229\173\151\228\189\147\233\162\156\232\137\178\239\188\140\228\184\141\229\134\141\228\184\147\230\140\135icon"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BuffGroupType"
        }
      },
      Description = "BUFF\231\187\132\231\177\187\229\158\139"
    },
    {
      Name = "cover_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\155\191\230\141\162\233\128\187\232\190\145\229\136\134\231\187\132"
    },
    {
      Name = "add_max",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "buff\231\187\132\229\143\160\229\138\160\230\156\128\229\164\167\229\177\130\230\149\176"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\136\230\158\156\230\143\143\232\191\176"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\135\232\181\132\230\186\144"
    },
    {
      Name = "corner_markers",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\146\230\160\135\232\181\132\230\186\144"
    },
    {
      Name = "res_id_0",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\190\142\230\156\175\232\181\132\230\186\144\239\188\136type0\239\188\137"
    },
    {
      Name = "res_id_1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\190\142\230\156\175\232\181\132\230\186\144\239\188\136type1\239\188\137"
    },
    {
      Name = "res_id_2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\190\142\230\156\175\232\181\132\230\186\144\239\188\136type2\239\188\137"
    },
    {
      Name = "buff_group_reduce",
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
          TypeName = "BUFF_CONF_buff_group_reduce"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "is_clean_when_rest",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\149\228\189\141\228\184\139\229\156\186\229\144\142\230\152\175\229\144\166\230\184\133\233\153\164"
    },
    {
      Name = "connect_buff",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BUFF_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\138\181\230\182\136\230\149\136\230\158\156"
    },
    {
      Name = "buff_can_react",
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
          EnumName = "BuffCanReact"
        }
      },
      Description = "\229\143\151\229\136\176\230\148\187\229\135\187\231\177\187\229\158\139\228\184\141\228\188\154\228\186\167\231\148\159\229\143\151\229\135\187\229\138\168\228\189\156"
    },
    {
      Name = "field_buff",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BUFF_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\189\172\230\141\162\229\144\142\231\154\132\230\149\136\230\158\156id"
    },
    {
      Name = "MAX_EFFECTIVE",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BUFF_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\156\128\229\164\167\229\177\130\229\144\142\232\142\183\229\190\151\230\149\136\230\158\156"
    },
    {
      Name = "buff_trigger_priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\168\229\144\140\228\184\128\228\184\170\232\167\166\229\143\145\231\130\185\232\167\166\229\143\145\231\154\132\230\149\136\230\158\156\239\188\140\239\188\136\231\173\150\229\136\146\229\188\186\229\136\182\239\188\137\232\167\166\229\143\145\228\188\152\229\133\136\231\186\167\227\128\130"
    }
  }
}
RTTIManager:RegisterType(BUFF_CONF.Name, BUFF_CONF)

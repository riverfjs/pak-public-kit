local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_BOND = {
  Name = "PET_BOND",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_BOND.yaml",
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
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "period_weight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\155\186\229\174\154\233\135\143\232\161\168\228\184\138\233\153\144\229\128\188"
    },
    {
      Name = "default_scale",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\135\143\232\161\168\229\159\186\229\135\134\229\128\188"
    },
    {
      Name = "minimum_factor",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\143\230\156\186\229\140\186\233\151\180\228\184\139\233\153\144\231\179\187\230\149\176"
    },
    {
      Name = "maximum_factor",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\143\230\156\186\229\140\186\233\151\180\228\184\138\233\153\144\231\179\187\230\149\176"
    },
    {
      Name = "maximum_alarm",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\165\232\191\145\228\184\138\233\153\144\233\162\132\232\173\166"
    },
    {
      Name = "option_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_OPTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\186\146\229\138\168\233\128\137\233\161\185id"
    },
    {
      Name = "find_gift_option",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_OPTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\191\157\229\186\149\229\143\145\229\165\150\228\186\146\229\138\168\233\128\137\233\161\185id"
    },
    {
      Name = "close_level",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\228\186\178\229\175\134\229\186\166\231\173\137\231\186\167"
    },
    {
      Name = "close_level_need_exp",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "0~\229\175\185\229\186\148\231\173\137\231\186\167\231\154\132\231\187\143\233\170\140\229\128\188\228\184\138\233\153\144"
    },
    {
      Name = "bond_random",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_BOND_bond_random"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "find_random",
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
          TypeName = "PET_BOND_find_random"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "find_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ClientNpcType"
        }
      },
      Description = "\231\177\187\229\158\1394"
    },
    {
      Name = "find_weight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\154\143\230\156\186\230\157\131\233\135\141"
    },
    {
      Name = "required_interact_count",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\186\146\229\138\168x\230\172\161\229\144\142\232\191\155\229\133\165\233\154\143\230\156\186\230\177\160"
    },
    {
      Name = "base_friendly_param_value",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\232\174\191\229\174\162\229\143\139\229\165\189\229\186\166\229\159\186\231\161\128\229\128\188"
    },
    {
      Name = "close_exp_retio",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\228\186\178\229\175\134\229\186\166\231\187\143\233\170\140\232\142\183\229\143\150\229\128\141\231\142\135(\228\184\135\229\136\134\230\175\148)"
    }
  }
}
RTTIManager:RegisterType(PET_BOND.Name, PET_BOND)

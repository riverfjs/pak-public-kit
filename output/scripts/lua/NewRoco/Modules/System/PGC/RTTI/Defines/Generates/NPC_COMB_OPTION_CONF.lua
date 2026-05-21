local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NPC_COMB_OPTION_CONF = {
  Name = "NPC_COMB_OPTION_CONF",
  Version = 1,
  Description = "NPC_COMB_OPTION_CONF\230\152\175\230\184\184\230\136\143\229\134\133\231\148\168\228\186\142\229\174\154\228\185\137\230\137\128\230\156\137\230\156\186\229\133\179\231\154\132\230\157\161\228\187\182\231\187\132\229\144\136\231\154\132\233\133\141\231\189\174\230\150\135\228\187\182\239\188\140\231\148\168\230\157\165\231\174\161\231\144\134NPC_COMB_RESULT_CONF\228\184\173\229\175\185\229\186\148\230\156\186\229\133\179\231\187\147\230\158\156\230\137\128\233\156\128\231\154\132\230\157\161\228\187\182\227\128\130\229\174\131\229\174\154\228\185\137\228\186\134\229\166\130\228\184\139\229\134\133\229\174\185\239\188\1541.\230\156\186\229\133\179\230\157\161\228\187\182\231\154\132\231\187\132\229\144\136\231\177\187\229\158\139\239\188\140\230\132\143\228\184\186\229\144\171\230\156\137\229\164\154\228\184\170\230\157\161\228\187\182\230\151\182\231\154\132\232\190\190\230\136\144\232\167\132\229\136\153\239\188\1552.\230\175\143\228\184\170\230\156\186\229\133\179\230\157\161\228\187\182\229\175\185\229\186\148\231\154\132npc\229\136\183\230\150\176\231\130\185\229\143\138\230\157\161\228\187\182\231\177\187\229\158\139\239\188\140\230\132\143\228\184\186\230\175\143\228\184\170npc\233\156\128\232\166\129\232\190\190\230\136\144\231\154\132\230\157\161\228\187\182\239\188\1553.\230\149\180\228\184\170\230\156\186\229\133\179\231\187\132\229\144\136\231\154\132\229\159\186\231\161\128\232\167\132\229\136\153\239\188\140\229\166\130\230\152\175\229\144\166\233\156\128\232\166\129\229\144\140\230\151\182\230\187\161\232\182\179\230\157\161\228\187\182\227\128\129\230\156\186\229\133\179\231\154\132\230\156\137\230\149\136\230\172\161\230\149\176\229\146\140\229\143\175\233\135\141\229\164\141\230\172\161\230\149\176\227\128\129\230\156\186\229\133\179\229\143\175\229\144\166\233\135\141\231\189\174\228\187\165\229\143\138\233\135\141\231\189\174\230\150\185\229\188\143\231\173\137\227\128\130",
  Metadata = {
    Alias = "\230\156\186\229\133\179\232\161\168\227\128\129\230\156\186\229\133\179\230\157\161\228\187\182\227\128\129combination\227\128\129\230\157\161\228\187\182\232\161\168\227\128\129\230\156\186\229\133\179option",
    RelativeYamlPath = "npc_combination/NPC_COMB_OPTION_CONF.yaml",
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
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "map_ID",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DUNGEON_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\229\156\176\229\155\190"
    },
    {
      Name = "comb_is_unused",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\186\159\229\188\131"
    },
    {
      Name = "result_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.UNIQUE
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_COMB_RESULT_CONF",
          FieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 999999}
          }
        }
      },
      Description = "ID"
    },
    {
      Name = "npc_comb_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcCombType"
        }
      },
      Description = "\231\187\132\229\144\136\231\177\187\229\158\139"
    },
    {
      Name = "option",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 20
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_COMB_OPTION_CONF_option"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "Is_Keep",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\155\145\230\181\139\230\140\129\231\187\173\231\138\182\230\128\129"
    },
    {
      Name = "result_times",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\180\228\189\147\230\156\137\230\149\136\230\172\161\230\149\176"
    },
    {
      Name = "cond_reset_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "CombCondResetType"
        }
      },
      Description = "\230\156\186\229\133\179\230\157\161\228\187\182\233\135\141\231\189\174\231\177\187\229\158\139"
    },
    {
      Name = "total_time",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\233\135\141\229\164\141\230\172\161\230\149\176"
    },
    {
      Name = "version",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\230\141\174\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "comb_update_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "CombUpdateType"
        }
      },
      Description = "\232\139\165\231\137\136\230\156\172\229\143\183\229\143\152\229\140\150\239\188\140\233\156\128\229\164\132\231\144\134\230\156\186\229\133\179\230\149\176\230\141\174"
    },
    {
      Name = "fail_tips",
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
      Description = "\229\164\177\232\180\165\230\143\144\231\164\186"
    }
  }
}
RTTIManager:RegisterType(NPC_COMB_OPTION_CONF.Name, NPC_COMB_OPTION_CONF)

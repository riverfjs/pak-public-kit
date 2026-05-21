local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local DUNGEON_STAGE = {
  Name = "DUNGEON_STAGE",
  Version = 1,
  Description = "DUGEON_STAGE \230\152\175\231\148\168\228\186\142\233\133\141\231\189\174\230\184\184\230\136\143\228\184\173\230\137\128\230\156\137\229\137\175\230\156\172\226\128\156\233\152\182\230\174\181\239\188\136Stage\239\188\137\226\128\157\231\154\132\233\133\141\231\189\174\230\150\135\228\187\182\239\188\140\229\140\133\229\144\171\228\187\165\228\184\139\229\134\133\229\174\185\239\188\154",
  Metadata = {
    Alias = "\233\152\182\230\174\181\232\161\168\227\128\129\230\173\165\233\170\164\232\161\168\227\128\129\229\156\176\229\159\142\233\152\182\230\174\181\227\128\129\229\156\176\229\174\171\233\152\182\230\174\181\227\128\129stage\232\161\168",
    RelativeYamlPath = "dungeon/DUNGEON_STAGE.yaml",
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
      Description = "\233\152\182\230\174\181ID"
    },
    {
      Name = "dungeon_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DUNGEON_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\229\137\175\230\156\172"
    },
    {
      Name = "stage_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "dungeonstage"
        }
      },
      Description = "\233\152\182\230\174\181\229\144\141\231\167\176"
    },
    {
      Name = "has_stage_finish_ui",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\233\152\182\230\174\181\229\174\140\230\136\144UI"
    },
    {
      Name = "start_condition",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_STAGE_start_condition"
        }
      },
      Description = ""
    },
    {
      Name = "start_action",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 4
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_STAGE_start_action"
        }
      },
      Description = "\233\152\182\230\174\181\229\188\128\229\167\139\230\151\182\232\161\140\228\184\186"
    },
    {
      Name = "finish_condition",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_STAGE_finish_condition"
        }
      },
      Description = ""
    },
    {
      Name = "finish_action",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 4
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_STAGE_finish_action"
        }
      },
      Description = "\233\152\182\230\174\181\229\174\140\230\136\144\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "stage_content",
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
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\152\182\230\174\181\229\191\133\229\136\183\230\150\176\231\154\132content\229\136\151\232\161\168"
    },
    {
      Name = "stage_combination",
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
          TypeName = "NPC_COMB_OPTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\152\182\230\174\181\233\156\128\232\166\129\233\135\141\231\189\174\231\154\132\230\156\186\229\133\179"
    },
    {
      Name = "reset_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TimeResetType"
        }
      },
      Description = "\233\152\182\230\174\181\230\152\175\229\144\166\229\143\175\228\187\165\233\135\141\231\189\174"
    },
    {
      Name = "revive_point",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\152\182\230\174\181\229\164\141\230\180\187\231\130\185"
    },
    {
      Name = "version",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\230\141\174\231\137\136\230\156\172\229\143\183"
    }
  }
}
RTTIManager:RegisterType(DUNGEON_STAGE.Name, DUNGEON_STAGE)

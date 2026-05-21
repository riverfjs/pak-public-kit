local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PARAGRAPH_CONF = {
  Name = "PARAGRAPH_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "task/PARAGRAPH_CONF.yaml",
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
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 99999}
          }
        }
      },
      Description = "\232\138\130ID"
    },
    {
      Name = "sorthels",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\151\133\233\128\148\232\138\130\229\144\141\229\134\141\228\184\138\233\157\162\231\154\132\229\173\151\231\172\166\228\184\178"
    },
    {
      Name = "unit_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "UNIT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\177\158\228\186\142\231\154\132\229\141\149\229\133\131ID"
    },
    {
      Name = "paragraph_order",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\168\229\141\149\229\133\131\228\184\173\231\154\132\233\161\186\228\189\141"
    },
    {
      Name = "plot_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\137\128\229\177\158\230\149\133\228\186\139\231\188\150\229\143\183\239\188\136JQ/TQ/FQ)"
    },
    {
      Name = "plot_paragraph_order",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\138\130\230\142\146\229\186\143\239\188\136JQ/TQ/FQ\229\134\133\233\161\186\228\189\141\239\188\137"
    },
    {
      Name = "show_task_start",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\177\149\231\164\186\232\138\130\229\188\128\229\167\139"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questparagraph"
        }
      },
      Description = "\232\138\130\230\160\135\233\162\152"
    },
    {
      Name = "title_new",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questparagraphend"
        }
      },
      Description = "\229\174\140\230\136\144\229\144\142\232\138\130\230\160\135\233\162\152"
    },
    {
      Name = "sub_disappear",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\139\190\233\129\151\229\174\140\230\136\144\229\144\142\230\152\175\229\144\166\230\182\136\229\164\177"
    },
    {
      Name = "is_hide_paragraph",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\233\154\144\232\151\143\231\171\160\232\138\130"
    },
    {
      Name = "description",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "paragraphdesc"
        }
      },
      Description = "\232\138\130\230\149\133\228\186\139\230\162\151\230\166\130\227\128\144\229\186\159\229\188\131\227\128\145"
    },
    {
      Name = "description_new",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "paragraphdescafter"
        }
      },
      Description = "\229\174\140\230\136\144\229\144\142\232\138\130\230\149\133\228\186\139\230\162\151\230\166\130[\228\187\187\229\138\161\232\138\130\229\174\140\230\136\144\229\144\142\230\152\190\231\164\186\229\156\168\228\187\187\229\138\161\233\157\162\230\157\191\231\154\132\230\150\135\230\156\172]"
    },
    {
      Name = "paragraph_background",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\138\130\229\155\190\231\137\135\232\131\140\230\153\175"
    },
    {
      Name = "Reward",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "rewardID"
    },
    {
      Name = "is_map_task",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\229\156\176\229\155\190\228\187\187\229\138\161"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = ""
    },
    {
      Name = "season_task",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\232\181\155\229\173\163\228\187\187\229\138\161"
    }
  }
}
RTTIManager:RegisterType(PARAGRAPH_CONF.Name, PARAGRAPH_CONF)

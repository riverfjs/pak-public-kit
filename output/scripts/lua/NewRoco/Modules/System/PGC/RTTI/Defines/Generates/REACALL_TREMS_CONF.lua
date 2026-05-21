local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local REACALL_TREMS_CONF = {
  Name = "REACALL_TREMS_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "recall/REACALL_TREMS_CONF.yaml",
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
      Description = "\230\157\161\231\155\174ID"
    },
    {
      Name = "reacall_terms_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "recaltermsname"
        }
      },
      Description = "\230\157\161\231\155\174\229\144\141\231\167\176"
    },
    {
      Name = "reacall_terms_picture",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\157\161\231\155\174\233\133\141\229\155\190"
    },
    {
      Name = "reacall_terms_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "recalltermsdesc"
        }
      },
      Description = "\230\157\161\231\155\174\230\143\143\232\191\176"
    },
    {
      Name = "reacall_terms_show",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "GUIDE_CTRL_CONF",
          FieldName = "guide_group_id"
        }
      },
      Description = "\230\188\148\231\164\186\230\140\137\233\146\174\229\133\179\232\129\148"
    },
    {
      Name = "reacall_terms_teach",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TEACH_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\153\229\173\166\231\149\140\233\157\162\229\133\179\232\129\148"
    },
    {
      Name = "reacall_terms_go",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "CLIENT_PUBLIC_CMD",
          FieldName = "text"
        }
      },
      Description = "\232\183\179\232\189\172\229\138\159\232\131\189cmd\229\145\189\228\187\164"
    },
    {
      Name = "args",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\143\130\230\149\1761"
    },
    {
      Name = "args2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\143\130\230\149\1762"
    },
    {
      Name = "reacallt_terms_unlock_trigger1",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ReacallUnlockTriggerType"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\1821\239\188\136\229\133\179\231\179\187\228\184\186\230\136\150\239\188\137"
    },
    {
      Name = "trigger1_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "reacallt_terms_unlock_trigger1",
          Branches = {
            {
              Value = 1,
              TypeName = "TASK_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "ADVENTURE_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\1821\229\143\130\230\149\176"
    },
    {
      Name = "reacallt_terms_unlock_trigger2",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ReacallUnlockTriggerType"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\1822\239\188\136\229\133\179\231\179\187\228\184\186\230\136\150\239\188\137"
    },
    {
      Name = "trigger2_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "reacallt_terms_unlock_trigger2",
          Branches = {
            {
              Value = 1,
              TypeName = "TASK_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "ADVENTURE_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\1822\229\143\130\230\149\176"
    },
    {
      Name = "reacallt_terms_unlock_trigger3",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ReacallUnlockTriggerType"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\1823\239\188\136\229\133\179\231\179\187\228\184\186\230\136\150\239\188\137"
    },
    {
      Name = "trigger3_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "reacallt_terms_unlock_trigger3",
          Branches = {
            {
              Value = 1,
              TypeName = "TASK_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "ADVENTURE_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\1823\229\143\130\230\149\176"
    }
  }
}
RTTIManager:RegisterType(REACALL_TREMS_CONF.Name, REACALL_TREMS_CONF)

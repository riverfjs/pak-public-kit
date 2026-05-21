local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local REACALL_LIST_CONF = {
  Name = "REACALL_LIST_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "recall/REACALL_LIST_CONF.yaml",
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
      Description = "\231\177\187\229\136\171id"
    },
    {
      Name = "reacall_list_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "recaletypes"
        }
      },
      Description = "\231\177\187\229\136\171\229\144\141\231\167\176"
    },
    {
      Name = "reacall_list_picture",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\231\177\187\229\136\171\233\133\141\229\155\190"
    },
    {
      Name = "main_terms_id1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\187\230\184\160\233\129\147id"
    },
    {
      Name = "main_terms_id2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\187\230\184\160\233\129\147id"
    },
    {
      Name = "main_terms_id3",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\187\230\184\160\233\129\147id"
    },
    {
      Name = "sub_terms_id1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\173\144\230\184\160\233\129\147id"
    },
    {
      Name = "sub_terms_id2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\173\144\230\184\160\233\129\147id"
    },
    {
      Name = "sub_terms_id3",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\173\144\230\184\160\233\129\147id"
    },
    {
      Name = "sub_terms_id4",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_TREMS_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\173\144\230\184\160\233\129\147id"
    },
    {
      Name = "reacallt_list_unlock_trigger1",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ReacallUnlockTriggerType"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\182\239\188\136\229\133\179\231\179\187\228\184\186\230\136\150\239\188\137"
    },
    {
      Name = "trigger1_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "reacallt_list_unlock_trigger1",
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
      Description = "\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "reacallt_list_unlock_trigger2",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ReacallUnlockTriggerType"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\182\239\188\136\229\133\179\231\179\187\228\184\186\230\136\150\239\188\137"
    },
    {
      Name = "trigger2_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "reacallt_list_unlock_trigger2",
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
      Description = "\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "reacallt_list_unlock_trigger3",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ReacallUnlockTriggerType"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\182\239\188\136\229\133\179\231\179\187\228\184\186\230\136\150\239\188\137"
    },
    {
      Name = "trigger3_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "reacallt_list_unlock_trigger3",
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
      Description = "\230\157\161\228\187\182\229\143\130\230\149\176"
    }
  }
}
RTTIManager:RegisterType(REACALL_LIST_CONF.Name, REACALL_LIST_CONF)

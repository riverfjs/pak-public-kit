local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local REACALL_CONF = {
  Name = "REACALL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "recall/REACALL_CONF.yaml",
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
      Description = "\229\155\158\229\191\134\233\155\134\229\144\136id"
    },
    {
      Name = "reacall_title_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "recalltitle"
        }
      },
      Description = "\231\149\140\233\157\162\228\186\140\231\186\167\230\160\135\233\162\152"
    },
    {
      Name = "jump_target",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\187\152\232\174\164\230\137\147\229\188\128\231\149\140\233\157\162"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data3",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data4",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data5",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data6",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data7",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data8",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data9",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data10",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data11",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data12",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data13",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data14",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data15",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data16",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data17",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data18",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data19",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "data20",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_LIST_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\176\230\141\174ID"
    }
  }
}
RTTIManager:RegisterType(REACALL_CONF.Name, REACALL_CONF)

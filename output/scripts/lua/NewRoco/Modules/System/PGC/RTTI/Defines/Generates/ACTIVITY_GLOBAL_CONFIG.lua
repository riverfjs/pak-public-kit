local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ACTIVITY_GLOBAL_CONFIG = {
  Name = "ACTIVITY_GLOBAL_CONFIG",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "global_config/ACTIVITY_GLOBAL_CONFIG.yaml",
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
      Description = "\229\186\143\229\143\183"
    },
    {
      Name = "key",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.UNIQUE
        }
      },
      Description = "\229\144\141\229\173\151"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\230\141\174\231\188\150\232\190\145\229\153\168\230\152\190\231\164\186\229\144\141\231\167\176"
    },
    {
      Name = "num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\229\173\151"
    },
    {
      Name = "numList",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "TASK_CONF,id",
          EnumName = "@key=activity_treasure_hunt_guide_task,ACTIVITY_CONF",
          LinkFieldName = "id"
        }
      },
      Description = "\230\149\176\231\187\132"
    },
    {
      Name = "str",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "globaltxt"
        }
      },
      Description = "\229\173\151\231\172\166\228\184\178"
    },
    {
      Name = "is_svr_ctl",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\141\229\138\161\229\153\168\230\142\167\229\136\182"
    },
    {
      Name = "is_loc",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\191\187\232\175\145"
    }
  }
}
RTTIManager:RegisterType(ACTIVITY_GLOBAL_CONFIG.Name, ACTIVITY_GLOBAL_CONFIG)

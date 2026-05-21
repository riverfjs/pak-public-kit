local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_PART_CONF = {
  Name = "SEASON_PART_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season/SEASON_PART_CONF.yaml",
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
      Description = "part_id"
    },
    {
      Name = "slot_position",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonPartSlotPosition"
        }
      },
      Description = "\230\167\189\228\189\141\230\140\135\229\174\154"
    },
    {
      Name = "red_point_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "RED_POINT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\136\157\229\167\139\231\186\162\231\130\185id"
    },
    {
      Name = "item_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\136\157\229\167\139item_id"
    },
    {
      Name = "change_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 8
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "SEASON_PART_CONF_change_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(SEASON_PART_CONF.Name, SEASON_PART_CONF)

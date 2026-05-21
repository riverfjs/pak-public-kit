local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MONSTER_SKILLBANK_CONF = {
  Name = "MONSTER_SKILLBANK_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "monster/MONSTER_SKILLBANK_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\230\138\128\232\131\189\229\186\147ID"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 10
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "MONSTER_SKILLBANK_CONF_level"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(MONSTER_SKILLBANK_CONF.Name, MONSTER_SKILLBANK_CONF)

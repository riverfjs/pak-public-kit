local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_BEHAVIOR_REACTION_CONF = {
  Name = "PET_BEHAVIOR_REACTION_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "role_play/PET_BEHAVIOR_REACTION_CONF.yaml",
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
      Description = "\229\143\141\229\186\148\229\128\190\229\144\145"
    },
    {
      Name = "reaction_random",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 7
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_BEHAVIOR_REACTION_CONF_reaction_random"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(PET_BEHAVIOR_REACTION_CONF.Name, PET_BEHAVIOR_REACTION_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ANIM_ID_CONF = {
  Name = "ANIM_ID_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "anim/ANIM_ID_CONF.yaml",
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
      Description = "\229\138\168\231\148\187\229\186\143\229\136\151id"
    },
    {
      Name = "anim_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.UNIQUE
        }
      },
      Description = "\229\138\168\231\148\187\229\186\143\229\136\151\229\144\141\231\167\176"
    }
  }
}
RTTIManager:RegisterType(ANIM_ID_CONF.Name, ANIM_ID_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_UI_CAMERA_CONF = {
  Name = "PET_UI_CAMERA_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_UI_CAMERA_CONF.yaml",
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
      Description = "ID"
    },
    {
      Name = "camera_yaobi_len",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\145\135\232\135\130\233\149\191\229\186\166"
    },
    {
      Name = "camera_yaobi_pitch",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\145\135\232\135\130Pitch"
    }
  }
}
RTTIManager:RegisterType(PET_UI_CAMERA_CONF.Name, PET_UI_CAMERA_CONF)

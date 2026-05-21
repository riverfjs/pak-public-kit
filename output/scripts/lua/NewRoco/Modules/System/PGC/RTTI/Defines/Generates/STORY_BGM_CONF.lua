local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local STORY_BGM_CONF = {
  Name = "STORY_BGM_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "task/STORY_BGM_CONF.yaml",
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
      Description = "\228\187\187\229\138\161\233\159\179\233\162\145id"
    },
    {
      Name = "story_bgm_state",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\159\179\233\162\145\229\146\146\232\175\173"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    }
  }
}
RTTIManager:RegisterType(STORY_BGM_CONF.Name, STORY_BGM_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local UNIT_CONF = {
  Name = "UNIT_CONF",
  Version = 1,
  Description = "\231\148\168\228\186\142\229\156\168\228\187\187\229\138\161\231\149\140\233\157\162\228\184\173\239\188\140\229\176\134\229\164\154\228\184\170\228\187\187\229\138\161\230\174\181\232\144\189\239\188\136PARAGRAPH_CONF\239\188\137\230\148\182\230\157\159\229\145\136\231\142\176\239\188\140\229\174\158\231\142\176\232\191\158\231\187\173\231\175\135\231\171\160\230\136\150\229\144\140\228\184\128\231\179\187\229\136\151\231\154\132\232\167\134\232\167\137\229\145\136\231\142\176\227\128\130",
  Metadata = {
    Alias = "\229\141\149\229\133\131\232\161\168\227\128\129\228\187\187\229\138\161\229\141\149\229\133\131",
    RelativeYamlPath = "task/UNIT_CONF.yaml",
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
      Description = "\229\141\149\229\133\131ID"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questunit"
        }
      },
      Description = "\229\141\149\229\133\131\230\160\135\233\162\152"
    },
    {
      Name = "editor_sorting",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\142\146\229\186\143\232\167\132\229\136\153(\231\188\150\232\190\145\229\153\168\231\148\168\233\128\148)"
    },
    {
      Name = "unit_background",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\149\229\133\131\229\155\190\231\137\135"
    },
    {
      Name = "unit_background2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\229\144\142\229\141\149\229\133\131\229\155\190\231\137\135"
    }
  }
}
RTTIManager:RegisterType(UNIT_CONF.Name, UNIT_CONF)

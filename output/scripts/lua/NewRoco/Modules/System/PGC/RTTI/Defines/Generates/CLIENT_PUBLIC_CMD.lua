local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local CLIENT_PUBLIC_CMD = {
  Name = "CLIENT_PUBLIC_CMD",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "client_public_cmd/CLIENT_PUBLIC_CMD.yaml",
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
      Description = "CMD\230\179\168\229\134\140ID"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164"
    },
    {
      Name = "param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\143\130\230\149\1761"
    },
    {
      Name = "param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\143\130\230\149\1762"
    }
  }
}
RTTIManager:RegisterType(CLIENT_PUBLIC_CMD.Name, CLIENT_PUBLIC_CMD)

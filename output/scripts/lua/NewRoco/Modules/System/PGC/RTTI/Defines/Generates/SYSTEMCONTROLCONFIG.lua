local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SYSTEMCONTROLCONFIG = {
  Name = "SYSTEMCONTROLCONFIG",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "system_control/SYSTEMCONTROLCONFIG.yaml",
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
      Description = "\231\179\187\231\187\159ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "parent_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\231\136\182\232\138\130\231\130\185"
    },
    {
      Name = "is_open",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {},
      Description = "\231\179\187\231\187\159\230\152\175\229\144\166\229\188\128\229\144\175"
    },
    {
      Name = "is_audit",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {},
      Description = "ios\230\143\144\229\174\161\230\152\175\229\144\166\229\188\128\229\144\175"
    },
    {
      Name = "login_plat_limit",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\231\153\187\229\189\149\229\185\179\229\143\176\233\153\144\229\136\182"
    },
    {
      Name = "version_rule",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {},
      Description = "\229\133\168\231\137\136\230\156\172\229\143\183\230\152\190\231\164\186"
    },
    {
      Name = "open_client_version_ios",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "ios\231\179\187\231\187\159\229\188\128\229\144\175\231\154\132\229\174\162\230\136\183\231\171\175\232\181\132\230\186\144\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "open_client_version_android",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\174\137\229\141\147\231\179\187\231\187\159\229\188\128\229\144\175\231\154\132\229\174\162\230\136\183\231\171\175\232\181\132\230\186\144\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "open_client_version_pc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "PC\231\179\187\231\187\159\229\188\128\229\144\175\231\154\132\229\174\162\230\136\183\231\171\175\232\181\132\230\186\144\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "open_client_version_harmony_os",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\184\191\232\146\153\230\137\139\230\156\186\231\179\187\231\187\159\229\188\128\229\144\175\231\154\132\229\174\162\230\136\183\231\171\175\232\181\132\230\186\144\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "open_client_version_harmony_pc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\184\191\232\146\153\231\148\181\232\132\145\231\179\187\231\187\159\229\188\128\229\144\175\231\154\132\229\174\162\230\136\183\231\171\175\232\181\132\230\186\144\231\137\136\230\156\172\229\143\183"
    },
    {
      Name = "channel",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "CHANNELCONTROLCONFIG",
          FieldName = "id"
        }
      },
      Description = "\230\184\160\233\129\147\230\152\190\231\164\186\232\167\132\229\136\153"
    }
  }
}
RTTIManager:RegisterType(SYSTEMCONTROLCONFIG.Name, SYSTEMCONTROLCONFIG)

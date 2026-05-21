local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local CHANNELCONTROLCONFIG = {
  Name = "CHANNELCONTROLCONFIG",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "system_control/CHANNELCONTROLCONFIG.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\232\167\132\229\136\153ID"
    },
    {
      Name = "cli_login_channel",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\231\137\185\229\174\154\231\153\187\229\189\149\230\184\160\233\129\147"
    },
    {
      Name = "pkg_channel_hidden_list",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\230\184\160\233\129\147\229\143\183\233\154\144\232\151\143\229\136\151\232\161\168\239\188\140\233\128\154\232\191\135MSDK\228\188\160\233\128\146"
    },
    {
      Name = "pkg_channel_show_list",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\230\184\160\233\129\147\229\143\183\230\152\190\231\164\186\229\136\151\232\161\168\239\188\140\233\128\154\232\191\135MSDK\228\188\160\233\128\146"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    }
  }
}
RTTIManager:RegisterType(CHANNELCONTROLCONFIG.Name, CHANNELCONTROLCONFIG)

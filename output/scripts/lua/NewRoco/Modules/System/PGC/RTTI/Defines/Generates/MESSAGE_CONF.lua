local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MESSAGE_CONF = {
  Name = "MESSAGE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "task/MESSAGE_CONF.yaml",
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
      Description = "\228\191\161\228\187\182ID"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\180\229\131\143\232\181\132\230\186\144"
    },
    {
      Name = "envelop_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\191\161\229\176\129\231\137\185\230\174\138\232\181\132\230\186\144"
    },
    {
      Name = "letter_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\191\161\231\186\184\231\137\185\230\174\138\232\181\132\230\186\144"
    },
    {
      Name = "myname",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questmailtitle"
        }
      },
      Description = "\229\175\132\228\191\161\228\186\186\229\175\185\231\142\169\229\174\182\231\136\177\231\167\176"
    },
    {
      Name = "sender",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questmailsign"
        }
      },
      Description = "\229\175\132\228\191\161\228\186\186\232\135\170\231\167\176"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questmailtext"
        }
      },
      Description = "\228\191\161\228\187\182\230\173\163\230\150\135"
    },
    {
      Name = "envelop_style",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "LetterSkin"
        }
      },
      Description = "\228\191\161\229\176\129\230\160\183\229\188\143"
    },
    {
      Name = "receive_style",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "LetterReceiveStyle"
        }
      },
      Description = "\228\191\161\228\187\182\230\148\182\229\143\150\229\138\168\231\148\187"
    },
    {
      Name = "page_style",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "LetterPaper"
        }
      },
      Description = "\228\191\161\231\186\184\230\160\183\229\188\143"
    },
    {
      Name = "receive_des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "questmailreceive"
        }
      },
      Description = "\228\184\187\231\149\140\233\157\162\230\148\182\228\191\161\230\143\144\231\164\186"
    }
  }
}
RTTIManager:RegisterType(MESSAGE_CONF.Name, MESSAGE_CONF)

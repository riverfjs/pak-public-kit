local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_ADVENTURE_UI = {
  Name = "SEASON_ADVENTURE_UI",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season_adventure/SEASON_ADVENTURE_UI.yaml",
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
      Description = "\232\181\155\229\173\163\230\137\139\229\134\140\230\160\183\229\188\143ID"
    },
    {
      Name = "theme_color1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\233\162\152\232\137\1781"
    },
    {
      Name = "theme_color2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\233\162\152\232\137\1782"
    },
    {
      Name = "theme_color3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\233\162\152\232\137\1783"
    },
    {
      Name = "theme_color4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\233\162\152\232\137\1784"
    },
    {
      Name = "theme_color5",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\233\162\152\232\137\1785"
    },
    {
      Name = "chapter_picture_tips",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\182\133\233\147\190\229\188\185\231\170\151"
    },
    {
      Name = "chapter_picture_title1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\230\160\135\233\162\152\229\186\149\229\155\1901"
    },
    {
      Name = "chapter_picture_title2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\230\160\135\233\162\152\229\186\149\229\155\1902"
    },
    {
      Name = "chapter_stamp",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\133\168\233\131\168\229\174\140\230\136\144\229\141\176\231\171\160"
    },
    {
      Name = "stamp_left",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\165\150\229\138\177\229\186\149\229\155\190"
    },
    {
      Name = "stamp_left_badge",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\165\150\229\138\177\229\186\149\229\155\190-\231\137\185\230\174\138\231\171\160\232\138\130"
    },
    {
      Name = "magic_manual_switch_img1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\136\135\230\141\162\230\140\137\233\128\137\230\161\134\230\160\135\233\162\152"
    },
    {
      Name = "magic_manual_switch_img2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\136\135\230\141\162\230\140\137\233\128\137\230\161\134\229\186\149"
    },
    {
      Name = "magic_manual_switch_img3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\233\128\137\233\161\185\233\128\137\228\184\173"
    },
    {
      Name = "magic_manual_switch_img4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\233\128\137\233\161\185\230\156\170\233\128\137\228\184\173"
    },
    {
      Name = "magic_manual_switch_img5",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\174\233\128\154\233\128\137\233\161\185\233\128\137\228\184\173"
    },
    {
      Name = "magic_manual_switch_img6",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\174\233\128\154\233\128\137\233\161\185\230\156\170\233\128\137\228\184\173"
    },
    {
      Name = "magic_manual_switch_text_color1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\137\228\184\173\229\173\151\232\137\178"
    },
    {
      Name = "magic_manual_switch_text_color2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\170\233\128\137\228\184\173\229\173\151\232\137\178"
    }
  }
}
RTTIManager:RegisterType(SEASON_ADVENTURE_UI.Name, SEASON_ADVENTURE_UI)

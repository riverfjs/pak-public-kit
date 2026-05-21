local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MOVIE_CONF = {
  Name = "MOVIE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "sequence/MOVIE_CONF.yaml",
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
      Description = "mp4\231\154\132ID"
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
      Name = "movie_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "mp4\230\150\135\228\187\182\232\183\175\229\190\132"
    },
    {
      Name = "sound_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "mp4\233\159\179\233\162\145id"
    },
    {
      Name = "subtitle_track_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "VIDEO_SUBTITLES_CONF",
          FieldName = "track_id"
        }
      },
      Description = "mp4\229\173\151\229\185\149id"
    },
    {
      Name = "audio_state",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "audio\230\146\173\230\148\190state"
    },
    {
      Name = "begin_black_fade_in",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\188\128\229\167\139\230\146\173\230\148\190\230\151\182\233\187\145\229\177\143\230\152\175\229\144\166\232\166\129\230\183\161\229\133\165"
    },
    {
      Name = "begin_black",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\128\229\167\139\230\146\173\230\148\190\230\151\182\231\154\132\233\187\145\229\177\143\230\151\182\233\149\191\239\188\136\229\141\149\228\189\141\239\188\154ms\239\188\137"
    },
    {
      Name = "end_black",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\147\230\157\159\230\146\173\230\148\190\230\151\182\231\154\132\233\187\145\229\177\143\230\151\182\233\149\191\239\188\136\229\141\149\228\189\141\239\188\154ms\239\188\137"
    },
    {
      Name = "restart_bgm",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\147\230\157\159\229\144\142\233\135\141\229\144\175BGM"
    },
    {
      Name = "mute_time",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\147\230\157\159\229\144\142\233\157\153\233\159\179BGM\230\151\182\233\149\191(ms)"
    },
    {
      Name = "close_player_tick",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\179\233\151\173\231\142\169\229\174\182\231\167\187\229\138\168\231\187\132\228\187\182tick\239\188\136\231\155\174\229\137\141\228\187\133\231\148\168\228\186\142\229\186\143\231\171\160\239\188\137"
    },
    {
      Name = "skippable",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\228\187\165\232\183\179\232\191\135"
    },
    {
      Name = "not_skip_check",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\141\229\188\185\229\135\186\232\183\179\232\191\135\231\161\174\232\174\164\229\188\185\231\170\151"
    }
  }
}
RTTIManager:RegisterType(MOVIE_CONF.Name, MOVIE_CONF)

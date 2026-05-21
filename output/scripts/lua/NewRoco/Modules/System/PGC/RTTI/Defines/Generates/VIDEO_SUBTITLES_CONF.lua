local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local VIDEO_SUBTITLES_CONF = {
  Name = "VIDEO_SUBTITLES_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "video_subtitles/VIDEO_SUBTITLES_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "track_id",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\232\189\168\233\129\147ID"
    },
    {
      Name = "begin_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\229\188\128\229\167\139\230\151\182\233\151\180"
    },
    {
      Name = "end_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\231\187\147\230\157\159\230\151\182\233\151\180"
    },
    {
      Name = "content",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "videosubtitle"
        }
      },
      Description = "\229\173\151\229\185\149"
    },
    {
      Name = "roco_content",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\180\155\229\133\139\229\173\151\229\185\149"
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
RTTIManager:RegisterType(VIDEO_SUBTITLES_CONF.Name, VIDEO_SUBTITLES_CONF)

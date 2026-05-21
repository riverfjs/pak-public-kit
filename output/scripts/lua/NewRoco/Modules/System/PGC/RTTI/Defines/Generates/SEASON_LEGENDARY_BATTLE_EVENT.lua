local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_LEGENDARY_BATTLE_EVENT = {
  Name = "SEASON_LEGENDARY_BATTLE_EVENT",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season/SEASON_LEGENDARY_BATTLE_EVENT.yaml",
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
      Description = "\229\164\150\233\147\190\230\168\161\229\157\151id"
    },
    {
      Name = "quest_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\176\131\230\159\165\229\144\141\231\167\176"
    },
    {
      Name = "start_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\188\160\232\175\180\231\178\190\231\129\181\232\176\131\230\159\165\229\188\128\229\167\139\230\151\182\233\151\180"
    },
    {
      Name = "duration",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\228\188\160\232\175\180\231\178\190\231\129\181\232\176\131\230\159\165\230\140\129\231\187\173\230\151\182\233\151\180"
    },
    {
      Name = "appear_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\176\131\230\159\165\229\133\137\229\156\136\229\135\186\231\142\176\230\151\182\233\151\180"
    },
    {
      Name = "disappear_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\176\131\230\159\165\229\133\137\229\156\136\230\182\136\229\164\177\230\151\182\233\151\180"
    },
    {
      Name = "story_flag",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\167\163\233\148\129\228\188\160\232\175\180\231\178\190\231\129\181\229\155\162\228\189\147\230\136\152\230\137\128\233\156\128storyflag"
    },
    {
      Name = "world_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "WORLD_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\167\163\233\148\129\230\156\128\228\189\142\233\154\190\229\186\166battle\230\137\128\233\156\128\233\173\148\230\179\149\229\184\136\230\152\159\231\186\167"
    },
    {
      Name = "task_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\176\131\230\159\165\228\187\187\229\138\161"
    },
    {
      Name = "refresh_content_id_1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\133\137\229\156\136\229\136\183\230\150\176ID"
    },
    {
      Name = "refresh_content_id_2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\188\160\232\175\180\231\178\190\231\129\181\229\136\183\230\150\176ID"
    },
    {
      Name = "refresh_content_id_3",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\143\144\231\164\186\229\136\183\230\150\176ID"
    },
    {
      Name = "pet_base_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181baseId"
    },
    {
      Name = "battle_key",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.UNIQUE
        }
      },
      Description = "\231\178\190\231\129\181\232\191\155\230\136\152\233\133\141\231\189\174"
    },
    {
      Name = "start_difficulty",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\181\183\229\167\139\233\154\190\229\186\166\230\152\190\231\164\186"
    },
    {
      Name = "battle_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BATTLE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\136\152\230\150\151ID"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\160\135\233\162\152"
    },
    {
      Name = "is_season",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\232\181\155\229\173\163\228\188\160\232\175\180\231\178\190\231\129\181"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "UI\228\184\138\231\154\132\230\150\135\229\173\151\230\143\143\232\191\176"
    },
    {
      Name = "frame_1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\134\146\233\153\169\230\137\139\229\134\140\231\137\185\230\174\138\232\190\185\230\161\134\232\181\132\230\186\144\232\183\175\229\190\1321"
    },
    {
      Name = "frame_2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\134\146\233\153\169\230\137\139\229\134\140\231\137\185\230\174\138\232\190\185\230\161\134\232\181\132\230\186\144\232\183\175\229\190\1322"
    }
  }
}
RTTIManager:RegisterType(SEASON_LEGENDARY_BATTLE_EVENT.Name, SEASON_LEGENDARY_BATTLE_EVENT)

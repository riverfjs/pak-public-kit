local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_ADVENTURE_CHAPTER = {
  Name = "SEASON_ADVENTURE_CHAPTER",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season_adventure/SEASON_ADVENTURE_CHAPTER.yaml",
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
      Description = "\230\137\139\229\134\140\231\171\160\232\138\130ID"
    },
    {
      Name = "group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\137\139\229\134\140\231\171\160\232\138\130\231\187\132ID"
    },
    {
      Name = "chapter_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonAdventureChapterType"
        }
      },
      Description = "\231\171\160\232\138\130\231\177\187\229\158\139"
    },
    {
      Name = "badge_group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_BADGE_LEVEL",
          FieldName = "group_id"
        }
      },
      Description = "\229\133\179\232\129\148\231\154\132\232\181\155\229\173\163\229\190\189\231\171\160\231\187\132"
    },
    {
      Name = "chapter_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\230\149\176"
    },
    {
      Name = "next_chapter",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ADVENTURE_CHAPTER",
          FieldName = "id"
        }
      },
      Description = "\228\184\139\228\184\170\231\171\160\232\138\130ID"
    },
    {
      Name = "chapter_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonchaptername"
        }
      },
      Description = "\231\171\160\232\138\130\229\144\141\231\167\176"
    },
    {
      Name = "chapter_story_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonstoryname"
        }
      },
      Description = "\231\171\160\232\138\130\230\149\133\228\186\139\229\144\141\231\167\176"
    },
    {
      Name = "chapter_story",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonstory"
        }
      },
      Description = "\231\171\160\232\138\130\230\149\133\228\186\139"
    },
    {
      Name = "chapter_picture",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\155\190\231\137\135"
    },
    {
      Name = "progress_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasonchapterprogress"
        }
      },
      Description = "\231\171\160\232\138\130\232\191\155\229\186\166\230\150\135\230\156\172"
    },
    {
      Name = "rewards",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\171\160\232\138\130\229\165\150\229\138\177"
    },
    {
      Name = "pre_task",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\171\160\232\138\130\231\154\132\229\137\141\231\189\174\228\187\187\229\138\161"
    },
    {
      Name = "tasks",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\187\187\229\138\161\229\136\151\232\161\168"
    },
    {
      Name = "hide_tasks_season",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\154\144\232\151\143\232\181\155\229\173\163\228\187\187\229\138\161"
    },
    {
      Name = "pre_task_season_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\153\164\233\154\144\232\151\143\229\174\140\230\136\144\231\154\132\232\181\155\229\173\163\228\187\187\229\138\161\230\149\176"
    },
    {
      Name = "chapter_finish_task_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\231\171\160\232\138\130\233\156\128\232\166\129\231\154\132\232\181\155\229\173\163\228\187\187\229\138\161\230\149\176\233\135\143"
    },
    {
      Name = "reacall_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\156\172\231\171\160\232\138\130\229\133\179\232\129\148\231\154\132\229\155\158\230\131\179id"
    },
    {
      Name = "open_at_season_start",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\181\155\229\173\163\229\188\128\229\167\139\230\151\182\231\155\180\230\142\165\228\184\138\232\186\171\231\154\132\228\187\187\229\138\161"
    }
  }
}
RTTIManager:RegisterType(SEASON_ADVENTURE_CHAPTER.Name, SEASON_ADVENTURE_CHAPTER)

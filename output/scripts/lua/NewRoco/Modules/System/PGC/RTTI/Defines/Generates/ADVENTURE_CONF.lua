local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local ADVENTURE_CONF = {
  Name = "ADVENTURE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "adventure/ADVENTURE_CONF.yaml",
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
      Description = "ID"
    },
    {
      Name = "pet_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181ID"
    },
    {
      Name = "",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
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
          TypeName = "ADVENTURE_CONF",
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
          LocaleName = "chaptername"
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
          LocaleName = "chaptertitle"
        }
      },
      Description = "\231\171\160\232\138\130\230\149\133\228\186\139\229\144\141\231\167\176"
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
      Name = "chapter_story",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "chapterintro"
        }
      },
      Description = "\231\171\160\232\138\130\230\149\133\228\186\139"
    },
    {
      Name = "reacall_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REACALL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\229\155\158\230\131\179\229\138\159\232\131\189"
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
      Name = "chapter_title1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = ""
    },
    {
      Name = "chapter_title2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = ""
    },
    {
      Name = "chapter_stamp",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\230\153\174\233\128\154\229\174\140\230\136\144\229\141\176\231\171\160"
    },
    {
      Name = "stamp_left",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\160\232\138\130\229\165\150\229\138\177\229\186\149\229\155\190\239\188\136\228\184\187\233\162\152\231\178\190\231\129\181/\229\137\167\230\131\133\232\166\129\231\180\160\231\155\184\229\133\179\239\188\137"
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
      Description = "\228\187\187\229\138\161"
    },
    {
      Name = "hide_tasks_core",
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
      Description = "\233\154\144\232\151\143\229\191\133\228\191\174\228\187\187\229\138\161"
    },
    {
      Name = "pre_task_core_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\153\164\233\154\144\232\151\143\229\174\140\230\136\144\231\154\132\229\144\140\231\177\187\229\158\139\228\187\187\229\138\161\230\149\176"
    },
    {
      Name = "hide_tasks_elective",
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
      Description = "\233\154\144\232\151\143\233\128\137\228\191\174\228\187\187\229\138\161"
    },
    {
      Name = "pre_task_elective_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\153\164\233\154\144\232\151\143\229\174\140\230\136\144\231\154\132\229\144\140\231\177\187\229\158\139\228\187\187\229\138\161\230\149\176"
    },
    {
      Name = "chapter_new_anim_comp",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\173\148\230\179\149\230\137\139\229\134\140\231\171\160\232\138\130\229\138\168\230\149\136\229\189\169\229\184\166\232\181\132\230\186\144"
    }
  }
}
RTTIManager:RegisterType(ADVENTURE_CONF.Name, ADVENTURE_CONF)

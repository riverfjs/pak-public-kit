local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local DUNGEON_CONF = {
  Name = "DUNGEON_CONF",
  Version = 1,
  Description = "DUGEON_CONF \230\152\175\231\148\168\228\186\142\233\133\141\231\189\174\230\184\184\230\136\143\228\184\173\230\137\128\230\156\137\229\137\175\230\156\172\226\128\156\229\159\186\231\161\128\228\191\161\230\129\175\226\128\157\231\154\132\233\133\141\231\189\174\230\150\135\228\187\182\239\188\140\229\140\133\229\144\171\228\187\165\228\184\139\229\134\133\229\174\185\239\188\154",
  Metadata = {
    Alias = "\229\156\176\229\174\171\232\161\168\227\128\129\229\156\176\229\159\142\232\161\168\227\128\129dungeon\232\161\168\227\128\129dconf",
    RelativeYamlPath = "dungeon/DUNGEON_CONF.yaml",
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
      Description = "\229\137\175\230\156\172ID\239\188\140ID\230\174\181101001~199999"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "dungeonname"
        }
      },
      Description = "\229\137\175\230\156\172\229\144\141\231\167\176"
    },
    {
      Name = "sub_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "dungeontitle"
        }
      },
      Description = "\229\137\175\230\160\135\233\162\152"
    },
    {
      Name = "region_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\140\186\229\136\146\229\136\134\239\188\136gm\229\183\165\229\133\183\231\148\168\239\188\137"
    },
    {
      Name = "scene_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\229\156\186\230\153\175id"
    },
    {
      Name = "world_scene_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\229\177\158\233\157\153\230\128\129\229\156\186\230\153\175\239\188\136\229\147\170\228\184\170\229\156\186\230\153\175\231\154\132\229\137\175\230\156\172\239\188\140\231\155\174\229\137\141\229\164\167\229\156\176\229\155\190\231\148\168\239\188\137"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "DungeonType"
        }
      },
      Description = "\229\137\175\230\156\172\231\177\187\229\158\139"
    },
    {
      Name = "type_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "dungeondesc"
        }
      },
      Description = "\229\137\175\230\156\172\231\177\187\229\158\139\229\144\141\231\167\176"
    },
    {
      Name = "require_cond",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 3
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_CONF_require_cond"
        }
      },
      Description = "\229\137\175\230\156\172\230\142\165\229\143\150\230\157\161\228\187\182\230\149\176\233\135\143"
    },
    {
      Name = "hide_tag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "HideTagType"
        }
      },
      Description = "\230\152\175\229\144\166\233\156\128\232\166\129\233\154\144\232\151\143\233\157\158\229\189\147\229\137\141\229\156\176\229\155\190\230\160\135\232\174\176\231\154\132\228\187\187\229\138\161"
    },
    {
      Name = "main_exit",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\231\149\140\233\157\162\229\135\186\229\143\163"
    },
    {
      Name = "has_enter_ui",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\229\137\175\230\156\172\232\191\155\229\133\165\231\149\140\233\157\162"
    },
    {
      Name = "show_reward",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 8
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_CONF_show_reward"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "battle_starlevel",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\168\232\141\144\230\136\152\230\150\151\230\152\159\231\186\167"
    },
    {
      Name = "reward_bagitem_id",
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
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\129\147\229\133\183\229\165\150\229\138\177\229\136\151\232\161\168"
    },
    {
      Name = "reward_word",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\229\138\177\230\150\135\229\173\151\228\191\161\230\129\175"
    },
    {
      Name = "finish_stage",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DUNGEON_STAGE",
          FieldName = "id"
        }
      },
      Description = "\229\137\175\230\156\172\229\174\140\230\136\144\230\157\161\228\187\182\226\128\148\226\128\148\233\152\182\230\174\181ID"
    },
    {
      Name = "has_finish_ui",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\229\137\175\230\156\172\229\174\140\230\136\144UI"
    },
    {
      Name = "collection",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 4
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "DUNGEON_CONF_collection"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(DUNGEON_CONF.Name, DUNGEON_CONF)

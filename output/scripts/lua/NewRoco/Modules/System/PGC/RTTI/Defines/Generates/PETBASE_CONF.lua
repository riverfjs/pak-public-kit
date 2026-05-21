local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PETBASE_CONF = {
  Name = "PETBASE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PETBASE_CONF.yaml",
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
      Description = "\231\178\190\231\129\181id"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "petname"
        }
      },
      Description = "\231\178\190\231\129\181\229\144\141\231\167\176"
    },
    {
      Name = "form",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "petform"
        }
      },
      Description = "\231\178\190\231\129\181\229\189\162\230\128\129"
    },
    {
      Name = "boss_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MonsterDifficultyType"
        }
      },
      Description = "\229\155\162\228\189\147\230\136\152\228\184\173BOSS\231\177\187\229\158\139"
    },
    {
      Name = "move_type",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\164\154\230\160\150\231\167\187\229\138\168\239\188\136\229\144\136\231\133\167\231\148\168\239\188\137"
    },
    {
      Name = "completeness",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\174\140\230\136\144"
    },
    {
      Name = "pet_evolution_id",
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
          TypeName = "PET_EVOLUTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\191\155\229\140\150\233\147\190ID"
    },
    {
      Name = "quality",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetQuality"
        }
      },
      Description = "\231\178\190\231\129\181\231\168\128\230\156\137\229\186\166"
    },
    {
      Name = "stength_stage",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\232\181\132\232\180\168\239\188\136\229\143\170\230\156\1371\233\152\182\229\176\177\229\161\1713\239\188\140\230\156\1372\233\152\182\229\161\1712\229\146\1403\239\188\140\230\156\1373\233\152\182\229\161\1711\239\188\1402\239\188\1403\239\188\137"
    },
    {
      Name = "stage",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\152\182\231\186\167"
    },
    {
      Name = "pet_scroe",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\232\175\132\229\136\134\239\188\136\231\148\168\228\186\142pvp\230\142\146\228\189\141\231\179\187\231\187\159\239\188\140\231\142\169\229\174\182\229\143\175\228\189\191\231\148\168\231\154\132\231\178\190\231\129\181\229\157\135\233\156\128\230\183\187\229\138\160\239\188\137"
    },
    {
      Name = "consume_role_hp",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\155\231\171\173\230\182\136\232\128\151\232\167\146\232\137\178\231\154\132\229\185\178\229\138\178\230\149\176\233\135\143"
    },
    {
      Name = "max_energy",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\131\189\233\135\143\228\184\138\233\153\144"
    },
    {
      Name = "unit_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillDamType"
        }
      },
      Description = "\231\179\187\229\136\171"
    },
    {
      Name = "show_tag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\148\175\228\184\128ID\239\188\136\231\155\174\229\137\141\231\148\168\228\186\142\233\166\150\230\172\161\230\136\152\230\150\151\230\152\190\231\164\186\231\179\187\229\136\171\231\154\132\229\136\164\230\150\173\239\188\140\232\139\165\230\156\137\229\133\182\228\187\150\231\148\168\233\128\148\232\129\148\231\179\187\228\184\128\228\184\139colliershi\239\188\137"
    },
    {
      Name = "ai_group_info_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_GROUP_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "AI\233\133\141\231\189\174\239\188\136id\239\188\137"
    },
    {
      Name = "pet_habitat_group_role_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\230\160\150\230\129\175\229\156\176\231\190\164\231\187\132\232\167\146\232\137\178"
    },
    {
      Name = "ecology_feature",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ECOLOGY_FEATURE"
        }
      },
      Description = "\231\178\190\231\129\181\231\148\159\231\137\169\231\137\185\230\128\167"
    },
    {
      Name = "level_skill_conf_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "LEVEL_SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\230\138\128\232\131\189\229\186\147ID"
    },
    {
      Name = "pet_feature",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\231\137\185\230\128\167\230\138\128\232\131\189ID"
    },
    {
      Name = "pet_chaos_feature",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\183\183\230\178\140\231\170\129\229\143\152\231\178\190\231\129\181\231\137\185\230\128\167\230\138\128\232\131\189ID\239\188\136\230\178\161\229\156\168\231\148\168\239\188\137"
    },
    {
      Name = "pet_glass_feature",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\142\187\231\146\131\231\170\129\229\143\152\231\178\190\231\129\181\231\137\185\230\128\167\230\138\128\232\131\189ID\239\188\136\230\178\161\229\156\168\231\148\168\239\188\137"
    },
    {
      Name = "pet_idle_skill",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\190\133\230\156\186\230\138\128\232\131\189ID"
    },
    {
      Name = "pet_lackenergy_skill",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\188\186\232\131\189\233\135\143\230\138\128\232\131\189ID"
    },
    {
      Name = "model_conf",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MODEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\181\132\230\186\144\233\133\141\231\189\174ID"
    },
    {
      Name = "shining_model_conf",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MODEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\188\130\232\137\178\231\170\129\229\143\152\232\181\132\230\186\144\233\133\141\231\189\174ID"
    },
    {
      Name = "scene_ability",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_ABILITY_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175\230\138\128\232\131\189ID"
    },
    {
      Name = "description",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "description"
        }
      },
      Description = "\231\178\190\231\129\181\228\191\161\230\129\175\230\143\143\232\191\176"
    },
    {
      Name = "pet_scale",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetScale"
        }
      },
      Description = "\231\178\190\231\129\181\230\168\161\229\158\139\229\164\167\229\176\143\231\177\187\229\158\139"
    },
    {
      Name = "pictorial_book_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\233\137\180\231\188\150\229\143\183"
    },
    {
      Name = "petfree_sort",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETFREE_CONF",
          FieldName = "petfree_sort"
        }
      },
      Description = "\231\178\190\231\129\181\230\148\190\231\148\159\229\165\150\229\138\177\231\177\187id"
    },
    {
      Name = "petfree_extra_item_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\148\190\231\148\159\233\162\157\229\164\150\233\129\147\229\133\183id"
    },
    {
      Name = "petfree_extra_common_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\174\233\128\154\230\131\133\229\134\181\230\148\190\231\148\159\232\142\183\229\190\151\233\129\147\229\133\183\230\149\176\233\135\143"
    },
    {
      Name = "petfree_extra_mixblood_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\183\183\232\161\128\231\178\190\231\129\181\230\148\190\231\148\159\232\142\183\229\190\151\233\129\147\229\133\183\230\149\176\233\135\143"
    },
    {
      Name = "petfree_extra_shining_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\232\137\178\231\170\129\229\143\152\231\178\190\231\129\181\230\148\190\231\148\159\232\142\183\229\190\151\233\129\147\229\133\183\230\149\176\233\135\143"
    },
    {
      Name = "petfree_extra_glass_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\142\187\231\146\131\231\170\129\229\143\152\231\178\190\231\129\181\230\148\190\231\148\159\232\142\183\229\190\151\233\129\147\229\133\183\230\149\176\233\135\143"
    },
    {
      Name = "ban_free",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\166\129\230\173\162\230\148\190\231\148\159"
    },
    {
      Name = "belong_habit_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_HABIT_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\185\160\230\128\167\231\187\132ID"
    },
    {
      Name = "pet_bond_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_BOND",
          FieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_NOEMPTY
        }
      },
      Description = "\228\186\178\230\152\181\228\186\146\229\138\168id"
    },
    {
      Name = "pet_reaction",
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
          TypeName = "PET_BEHAVIOR_REACTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\187\229\138\168\229\138\168\228\189\156\228\184\142\229\143\171\229\163\176\229\143\141\229\186\148\229\128\190\229\144\145id"
    },
    {
      Name = "evolution_pet_id",
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
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\191\155\229\140\150\229\144\142\231\178\190\231\129\181id"
    },
    {
      Name = "degenerate_pet_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\128\128\229\140\150\229\144\142\231\178\190\231\129\181id"
    },
    {
      Name = "bosspetbase_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\227\128\144\229\183\178\229\186\159\229\188\131\239\188\140\228\187\165AU\228\184\186\229\135\134\227\128\145\233\166\150\233\162\134\229\140\150\229\144\142\231\154\132petbase_id"
    },
    {
      Name = "bosspetbase_id_arry",
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
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\166\150\233\162\134\229\140\150\229\144\142\231\154\132petbase_id"
    },
    {
      Name = "bosspetbase_rule",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\166\150\233\162\134\229\140\150\232\167\132\229\136\153\239\188\154"
    },
    {
      Name = "bosspetbase_rule_param",
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
      Description = "\233\166\150\233\162\134\229\140\150\232\167\132\229\136\153\229\143\130\230\149\176"
    },
    {
      Name = "evolution_need_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\191\155\229\140\150\229\136\176\230\173\164\229\189\162\230\128\129\231\154\132\231\173\137\231\186\167"
    },
    {
      Name = "evolution_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\155\229\140\150\231\177\187\229\158\139"
    },
    {
      Name = "evolution_need",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 2
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PETBASE_CONF_evolution_need"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "evolution_need_money",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\155\229\140\150\229\136\176\232\191\153\228\184\170\229\189\162\230\128\129\233\156\128\230\177\130\230\180\155\229\133\139\232\180\157"
    },
    {
      Name = "evolution_task_id",
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
      Description = "\232\191\155\229\140\150\229\136\176\232\191\153\228\184\170\229\189\162\230\128\129\232\166\129\229\129\154\231\154\132\232\175\149\231\130\188\228\187\187\229\138\161id"
    },
    {
      Name = "evolution_need_items",
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
          TypeName = "PETBASE_CONF_evolution_need_items"
        }
      },
      Description = ""
    },
    {
      Name = "evolution_reward_items",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 2
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PETBASE_CONF_evolution_reward_items"
        }
      },
      Description = ""
    },
    {
      Name = "base_point_limit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\164\233\152\182\231\186\167\230\151\182\231\154\132\230\136\144\233\149\191\229\128\188\228\184\138\233\153\144"
    },
    {
      Name = "proportion_male",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\231\190\164\233\155\132\230\128\167\230\175\148"
    },
    {
      Name = "nature_ids",
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
          TypeName = "NATURE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\137\128\230\156\137\230\128\167\230\160\188id"
    },
    {
      Name = "hp_max_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\231\148\159\229\145\189\229\128\188\228\184\138\233\153\144"
    },
    {
      Name = "phy_attack_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\231\137\169\231\144\134\230\148\187\229\135\187"
    },
    {
      Name = "spe_attack_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\231\137\185\230\174\138\230\148\187\229\135\187"
    },
    {
      Name = "phy_defence_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\231\137\169\231\144\134\233\152\178\229\190\161"
    },
    {
      Name = "spe_defence_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\231\137\185\230\174\138\233\152\178\229\190\161"
    },
    {
      Name = "speed_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\233\128\159\229\186\166"
    },
    {
      Name = "SUM_race",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\230\151\143\232\181\132\232\180\168\230\177\130\229\146\140"
    },
    {
      Name = "hp_max_first",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\148\159\229\145\189\229\128\188\228\184\138\233\153\144"
    },
    {
      Name = "phy_attack_first",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\137\169\231\144\134\230\148\187\229\135\187"
    },
    {
      Name = "spe_attack_first",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\137\185\230\174\138\230\148\187\229\135\187"
    },
    {
      Name = "phy_defence_first",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\137\169\231\144\134\233\152\178\229\190\161"
    },
    {
      Name = "spe_defence_first",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\137\185\230\174\138\233\152\178\229\190\161"
    },
    {
      Name = "speed_first",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\233\128\159\229\186\166"
    },
    {
      Name = "hit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\145\189\228\184\173\231\142\135"
    },
    {
      Name = "dodge",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\151\170\233\129\191\231\142\135"
    },
    {
      Name = "critical",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\154\180\229\135\187\231\142\135"
    },
    {
      Name = "critical_res",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\154\180\229\135\187\230\138\181\230\138\151"
    },
    {
      Name = "critical_dam",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\154\180\229\135\187\228\188\164\229\174\179"
    },
    {
      Name = "critical_dam_res",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\154\180\229\135\187\228\188\164\229\174\179\230\138\181\230\138\151"
    },
    {
      Name = "phy_dam_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\228\188\164\229\174\179\229\138\160\230\136\144"
    },
    {
      Name = "spe_dam_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\148\187\229\135\187\229\138\160\230\136\144"
    },
    {
      Name = "phy_dam_res",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\228\188\164\229\174\179\229\135\143\229\133\141"
    },
    {
      Name = "spe_dam_res",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\228\188\164\229\174\179\229\135\143\229\133\141"
    },
    {
      Name = "all_dam_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\168\228\188\164\229\174\179\229\138\160\230\136\144"
    },
    {
      Name = "all_dam_res",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\168\228\188\164\229\174\179\229\135\143\229\133\141"
    },
    {
      Name = "dam_wave_low",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\188\164\229\174\179\230\179\162\229\138\168\228\184\139\233\153\144"
    },
    {
      Name = "dam_wave_high",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\188\164\229\174\179\230\179\162\229\138\168\228\184\138\233\153\144"
    },
    {
      Name = "counter_bonus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\139\229\136\182\229\188\186\229\140\150"
    },
    {
      Name = "resist_bonus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\181\230\138\151\229\188\186\229\140\150"
    },
    {
      Name = "common_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\174\233\128\154\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "grass_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\141\137\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "fire_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\129\171\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "water_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\176\180\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "light_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\137\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "stone_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "phantom_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\185\187\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "ice_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\176\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "dragon_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\190\153\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "electric_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\148\181\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "toxic_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\175\146\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "insect_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\153\171\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "fight_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\166\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "wing_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\191\188\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "moe_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\144\140\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "ghost_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\185\189\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "demon_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\129\182\233\173\148\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "mechanic_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\186\230\162\176\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "candy_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\179\150\229\177\158\230\128\167\229\188\186\229\140\150"
    },
    {
      Name = "common_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\174\233\128\154\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "grass_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\141\137\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "fire_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\129\171\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "water_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\176\180\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "light_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\137\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "earth_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\156\176\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "phantom_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\185\187\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "ice_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\134\176\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "dragon_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\190\153\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "electric_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\148\181\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "toxic_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\175\146\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "insect_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\153\171\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "fight_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\166\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "wing_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\191\188\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "moe_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\144\140\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "ghost_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\185\189\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "demon_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\129\182\233\173\148\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "mechanic_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\186\230\162\176\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "candy_resist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\179\150\229\177\158\230\128\167\230\138\151\230\128\167"
    },
    {
      Name = "heal_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\162\171\230\178\187\231\150\151\229\138\160\230\136\144"
    },
    {
      Name = "sheild_enhance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\164\231\155\190\229\138\160\230\136\144"
    },
    {
      Name = "hpmax_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\148\159\229\145\189\228\184\138\233\153\144\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "phyatk_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\230\148\187\229\135\187\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "speatk_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\148\187\229\135\187\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "phydef_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\233\152\178\229\190\161\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "spedef_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\233\152\178\229\190\161\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "speed_percent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\159\229\186\166\231\153\190\229\136\134\230\175\148"
    },
    {
      Name = "evolution_or_not",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\131\189\232\191\155\229\140\150"
    },
    {
      Name = "base_point_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\144\233\149\191\229\128\188\230\168\161\230\157\191id"
    },
    {
      Name = "happy_skill_ids",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\188\128\229\191\131\230\138\128\232\131\189id"
    },
    {
      Name = "angry_skill_ids",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\148\159\230\176\148\230\138\128\232\131\189id"
    },
    {
      Name = "release",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\135\138\230\148\190\232\191\148\232\191\152\233\146\177\230\149\176"
    },
    {
      Name = "pet_ui_camera_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_UI_CAMERA_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\231\149\140\233\157\162\230\145\135\232\135\130\233\149\156\229\164\180\231\177\187\229\158\139"
    },
    {
      Name = "petpage_ui_percentage",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\231\149\140\233\157\162\231\178\190\231\129\181\230\168\161\229\158\139\231\188\169\230\148\190\230\175\148"
    },
    {
      Name = "petpage_capsule_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\231\178\190\231\129\181\231\149\140\233\157\162\232\131\182\229\155\138\228\189\147\229\129\143\231\167\187"
    },
    {
      Name = "handbook_ui_percentage",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\233\137\180\229\134\133\233\161\181\231\178\190\231\129\181\230\168\161\229\158\139\231\188\169\230\148\190\230\175\148"
    },
    {
      Name = "handbook_capsule_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\229\155\190\233\137\180\229\134\133\233\161\181\232\131\182\229\155\138\228\189\147\229\129\143\231\167\187"
    },
    {
      Name = "pet_ui_percentage",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\177\143\229\141\160\230\175\148"
    },
    {
      Name = "formation_ui_scale",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\231\188\150\233\152\159\231\149\140\233\157\162\229\141\160\230\175\148"
    },
    {
      Name = "ui_camera_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\231\149\140\233\157\162\231\155\184\230\156\186\229\129\143\231\167\187"
    },
    {
      Name = "shadow_height",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\149\140\233\157\162\230\152\190\231\164\186\229\189\177\229\173\144\233\171\152\229\186\166"
    },
    {
      Name = "shadow_scale",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\189\177\229\173\144\231\188\169\230\148\190\230\175\148\228\190\139"
    },
    {
      Name = "model_height",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\233\171\152\229\186\166"
    },
    {
      Name = "show_area",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "demo\233\152\182\230\174\181\229\133\136\229\161\171\229\156\186\230\153\175ID"
    },
    {
      Name = "scene_ability_id",
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
          TypeName = "SCENE_ABILITY_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175\232\131\189\229\138\155id"
    },
    {
      Name = "npc_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132npcid"
    },
    {
      Name = "appearTime",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\188\229\164\156\231\177\187\229\158\139"
    },
    {
      Name = "special_act",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\137\185\230\174\138\232\161\140\228\184\186"
    },
    {
      Name = "world_nature",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldNature"
        }
      },
      Description = "\229\164\167\228\184\150\231\149\140\230\128\167\230\160\188"
    },
    {
      Name = "world_hide",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldHide"
        }
      },
      Description = "\229\140\191\232\184\170\231\138\182\230\128\129\231\177\187\229\158\139"
    },
    {
      Name = "world_hide_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\140\191\232\184\170\229\143\130\230\149\176"
    },
    {
      Name = "forbid_hide_envtagtype",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "EnvTagType"
        }
      },
      Description = "\228\184\141\229\143\175\229\140\191\232\184\170\229\156\176\232\178\140\231\177\187\229\158\139"
    },
    {
      Name = "mimic_target",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MODEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\185\187\229\140\150\229\175\185\232\177\161ID"
    },
    {
      Name = "mimic_skill",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\186\164\228\186\146\229\185\187\229\140\150\232\191\155\230\136\152\230\138\128\232\131\189"
    },
    {
      Name = "substitute_character",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SubstituteCharacter"
        }
      },
      Description = "\230\155\191\232\161\165\230\151\182\231\154\132\230\128\167\230\160\188"
    },
    {
      Name = "substitute_random_skill",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\155\191\232\161\165\230\138\128\232\131\189\228\189\191\231\148\168\230\166\130\231\142\135\228\184\135\229\136\134\230\175\148"
    },
    {
      Name = "Catch_Threshold_Bonustime",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\230\141\137\230\136\144\229\138\159\230\156\128\229\164\167\229\143\175\230\143\144\229\141\135\230\172\161\230\149\176"
    },
    {
      Name = "Catch_Threshold_Bonus",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\175\143\230\172\161\230\141\149\230\141\137\230\136\144\229\138\159\230\143\144\229\141\135\228\184\135\229\136\134\230\175\148"
    },
    {
      Name = "weight_low",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\233\135\141\228\184\139\233\153\144\239\188\136g\239\188\137"
    },
    {
      Name = "weight_high",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\147\233\135\141\228\184\138\233\153\144\239\188\136g\239\188\137"
    },
    {
      Name = "height_low",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\186\171\233\171\152\228\184\139\233\153\144(cm)"
    },
    {
      Name = "height_high",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\186\171\233\171\152\228\184\138\233\153\144(cm)"
    },
    {
      Name = "have_shiny",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\229\188\130\232\137\178\229\189\162\230\128\129"
    },
    {
      Name = "belong_season",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\189\146\229\177\158\232\181\155\229\173\163"
    },
    {
      Name = "relate_boss_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\133\179\232\129\148\231\154\132\233\166\150\233\162\134id"
    },
    {
      Name = "pet_classis_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_CLASSIS_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\177\187\229\136\171"
    },
    {
      Name = "break_cost_item",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\170\129\231\160\180\230\137\128\233\156\128\233\135\135\233\155\134\231\137\169"
    },
    {
      Name = "break_spec_item_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\170\129\231\160\180\230\137\128\233\156\128\231\137\185\230\174\138\230\157\144\230\150\153"
    },
    {
      Name = "break_award_sort",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BREAK_REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\170\129\231\160\180\229\165\150\229\138\177\231\177\187id"
    },
    {
      Name = "enjoy_field_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\228\186\178\229\146\140\231\179\187\229\136\171"
    },
    {
      Name = "hate_field_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\138\181\232\167\166\231\179\187\229\136\171"
    },
    {
      Name = "pet_settled_basic_reward",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\230\143\144\228\186\164\229\159\186\231\161\128\229\165\150\229\138\177"
    },
    {
      Name = "grow_x_individuality",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\144\233\149\191\230\151\182\230\143\144\229\141\135x\230\157\161\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "individuality_lower_limit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\170\228\189\147\232\181\132\232\180\168\229\140\186\233\151\180\228\184\139\233\153\144"
    },
    {
      Name = "individuality_upper_limit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\170\228\189\147\232\181\132\232\180\168\229\140\186\233\151\180\228\184\138\233\153\144"
    },
    {
      Name = "hatch_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\230\141\137\229\144\142\230\143\144\228\190\155\231\154\132\229\173\181\229\140\150\232\191\155\229\186\166"
    },
    {
      Name = "JL_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\231\171\139\231\187\152\239\188\1361024\239\188\137"
    },
    {
      Name = "JL_shiny_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\232\137\178\231\178\190\231\129\181\231\171\139\231\187\152\239\188\1361024\239\188\137"
    },
    {
      Name = "JL_small_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\231\171\139\231\187\152\239\188\136256\239\188\137"
    },
    {
      Name = "JL_small_shiny_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\232\137\178\231\178\190\231\129\181\231\171\139\231\187\152\239\188\136256\239\188\137"
    },
    {
      Name = "JL_photo_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\144\136\229\189\177\231\148\168\231\154\132\231\178\190\231\129\181\231\171\139\231\187\152\239\188\1361024\239\188\137"
    },
    {
      Name = "JL_photo_shiny_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\144\136\229\189\177\231\148\168\231\154\132\229\188\130\232\137\178\231\178\190\231\129\181\231\171\139\231\187\152\239\188\1361024\239\188\137"
    },
    {
      Name = "res_horizontal_flip_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\139\231\187\152\230\176\180\229\185\179\231\191\187\232\189\172\229\143\130\230\149\176"
    },
    {
      Name = "res_ui_percentage",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\171\139\231\187\152\231\188\169\230\148\190\229\164\167\229\176\143"
    },
    {
      Name = "res_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\231\171\139\231\187\152\229\129\143\231\167\187\232\183\157\231\166\187"
    },
    {
      Name = "is_display_shadow",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\149\229\189\177\230\152\175\229\144\166\230\152\190\231\164\186"
    },
    {
      Name = "shadow_horizontal_flip_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\149\229\189\177\230\152\175\229\144\166\230\176\180\229\185\179\231\191\187\232\189\172"
    },
    {
      Name = "shadow_vertical_flip_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\149\229\189\177\230\152\175\229\144\166\229\158\130\231\155\180\231\191\187\232\189\172"
    },
    {
      Name = "shadow_ui_percentage",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\230\138\149\229\189\177\231\188\169\230\148\190\229\164\167\229\176\143"
    },
    {
      Name = "shadow_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\230\138\149\229\189\177\229\129\143\231\167\187\232\183\157\231\166\187"
    },
    {
      Name = "shadow_angle",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\230\138\149\229\189\177\230\150\156\229\136\135\232\167\146\229\186\166"
    },
    {
      Name = "shadow_opacity",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\138\149\229\189\177\228\184\141\233\128\143\230\152\142\229\186\166"
    },
    {
      Name = "handbook_standpaint_bg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\231\171\139\231\187\152\232\131\140\230\153\175"
    },
    {
      Name = "handbook_unknown_bg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\231\171\139\231\187\152\232\131\140\230\153\175\239\188\136\230\156\170\230\141\149\232\142\183\239\188\137"
    },
    {
      Name = "share_bg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\232\167\134\233\162\145\229\136\134\228\186\171loading\229\155\190\232\131\140\230\153\175\239\188\136\228\184\142\231\171\139\231\187\152\232\131\140\230\153\175\228\184\128\228\184\128\229\175\185\229\186\148\239\188\137"
    },
    {
      Name = "share_uncommon_card_fg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\141\161\231\137\140\229\136\134\228\186\171\231\168\128\230\156\137\229\141\161\229\137\141\230\153\175\239\188\136\228\184\142\231\171\139\231\187\152\232\131\140\230\153\175\228\184\128\228\184\128\229\175\185\229\186\148\239\188\137"
    },
    {
      Name = "share_uncommon_card_bg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\141\161\231\137\140\229\136\134\228\186\171\231\168\128\230\156\137\229\141\161\232\131\140\230\153\175\239\188\136\228\184\142\231\171\139\231\187\152\232\131\140\230\153\175\228\184\128\228\184\128\229\175\185\229\186\148\239\188\137"
    },
    {
      Name = "Pet_Circadian",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetCircadian"
        }
      },
      Description = "\231\178\190\231\129\181\230\152\188\229\164\156\228\185\160\230\128\167"
    },
    {
      Name = "habit_1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "pethabits01"
        }
      },
      Description = "\231\178\190\231\129\181\228\185\160\230\128\1671"
    },
    {
      Name = "habit_2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "pethabits02"
        }
      },
      Description = "\231\178\190\231\129\181\228\185\160\230\128\1672"
    },
    {
      Name = "habit_3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "pethabits03"
        }
      },
      Description = "\231\178\190\231\129\181\228\185\160\230\128\1673"
    },
    {
      Name = "can_swim",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\131\189\229\144\166\230\184\184\230\179\179"
    },
    {
      Name = "pet_egg",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\232\155\139"
    },
    {
      Name = "pet_egg_shining",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BAG_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\188\130\232\137\178\231\178\190\231\129\181\232\155\139"
    },
    {
      Name = "egg_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetEggGroup"
        }
      },
      Description = "\231\178\190\231\129\181\232\155\139\231\190\164"
    },
    {
      Name = "stun_resistance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\187\230\153\149\230\138\151\230\128\167"
    },
    {
      Name = "axial_density",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\189\180\229\144\145\229\144\185\233\163\158\230\128\167\232\131\189\229\143\130\230\149\176"
    },
    {
      Name = "radial_density",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\132\229\144\145\229\144\185\233\163\142\230\128\167\232\131\189\229\143\130\230\149\176"
    },
    {
      Name = "bag_buff",
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
          TypeName = "BUFF_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\229\164\132\228\186\142\232\131\140\229\140\133\228\184\173\229\176\177\232\166\129\232\142\183\229\190\151\231\154\132\232\162\171\229\138\168\230\138\128\232\131\189\230\182\137\229\143\138buff"
    },
    {
      Name = "team_battle_ai",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\162\228\189\147\230\136\152\228\184\173\231\154\132AI"
    },
    {
      Name = "weight_compensation",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\228\184\150\231\149\140\230\138\128\232\131\189\233\152\187\230\140\161\228\189\147\233\135\141\228\191\174\230\173\163"
    },
    {
      Name = "is_pet_legendary",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\228\188\160\232\175\180\231\178\190\231\129\181"
    },
    {
      Name = "is_boss",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\233\166\150\233\162\134\231\178\190\231\129\181"
    },
    {
      Name = "is_pet_collection",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\187\152\232\174\164\230\148\182\232\151\143"
    },
    {
      Name = "talent_normal_chance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\128\232\136\172\232\136\172\229\164\169\229\136\134\230\157\131\229\128\188"
    },
    {
      Name = "talent_good_chance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\152\228\184\141\233\148\153\229\164\169\229\136\134\230\157\131\229\128\188"
    },
    {
      Name = "talent_amazing_chance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\155\184\229\189\147\229\165\189\229\164\169\229\136\134\230\157\131\229\128\188"
    },
    {
      Name = "talent_perfect_chance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\134\228\184\141\232\181\183\229\164\169\229\136\134\230\157\131\229\128\188"
    },
    {
      Name = "pet_track_npc_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\142\183\229\143\150\233\128\148\229\190\132\232\191\189\232\184\170\231\154\132npc_ids"
    },
    {
      Name = "pet_track_fail_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "canttrackmsg"
        }
      },
      Description = "\230\151\160\230\179\149\232\191\189\232\184\170npc\230\151\182\231\154\132\230\143\144\230\150\135\229\173\151"
    },
    {
      Name = "home_npc_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132\229\174\182\229\155\173npc_id"
    },
    {
      Name = "wish_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\232\142\183\232\142\183\229\190\151\230\152\159\229\133\137\230\149\176\233\135\143"
    },
    {
      Name = "report_res_horizontal_flip_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\138\230\138\165\231\171\139\231\187\152\230\176\180\229\185\179\231\191\187\232\189\172\229\143\130\230\149\176"
    },
    {
      Name = "report_res_ui_percentage",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\138\230\138\165\231\171\139\231\187\152\231\188\169\230\148\190\229\164\167\229\176\143"
    },
    {
      Name = "report_res_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\228\184\138\230\138\165\231\171\139\231\187\152\229\129\143\231\167\187\232\183\157\231\166\187"
    },
    {
      Name = "card_res_horizontal_flip_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\161\231\137\140\231\171\139\231\187\152\230\176\180\229\185\179\231\191\187\232\189\172\229\143\130\230\149\176"
    },
    {
      Name = "card_res_ui_percentage",
      Type = RTTIBase.FieldType.FLOAT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\161\231\137\140\231\171\139\231\187\152\231\188\169\230\148\190\229\164\167\229\176\143"
    },
    {
      Name = "card_res_offset",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.FLOAT
        }
      },
      Description = "\229\141\161\231\137\140\231\171\139\231\187\152\229\129\143\231\167\187\232\183\157\231\166\187"
    },
    {
      Name = "talent_random_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_TALENT_RANDOM_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\137\185\233\149\191\233\154\143\230\156\186\230\177\160id"
    },
    {
      Name = "audio_config_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_NAME_MAP_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\229\175\185\229\186\148\231\154\132\233\159\179\233\162\145id\229\137\141\231\188\128"
    },
    {
      Name = "falling_resistance",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\139\232\144\189\233\152\187\229\138\155\239\188\136cm/s)"
    }
  }
}
RTTIManager:RegisterType(PETBASE_CONF.Name, PETBASE_CONF)

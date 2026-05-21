local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MONSTER_CONF = {
  Name = "MONSTER_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "monster/MONSTER_CONF.yaml",
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
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 2000000}
          }
        }
      },
      Description = "\230\128\170\231\137\169ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "name"
        }
      },
      Description = "\230\128\170\231\137\169\229\144\141\231\167\176"
    },
    {
      Name = "base_id",
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
      Description = "\229\165\151\231\148\168\231\154\132\229\174\160\231\137\169baseId"
    },
    {
      Name = "petbase_find_enum",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetbaseFindType"
        }
      },
      Description = "petbase\229\140\185\233\133\141\230\158\154\228\184\190"
    },
    {
      Name = "find_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "petbase\229\140\185\233\133\141\229\143\130\230\149\176"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\128\170\231\137\169\231\173\137\231\186\167\239\188\136\229\186\159\229\188\131\239\188\137"
    },
    {
      Name = "monster_level_script",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcLevelScript"
        }
      },
      Description = "\231\173\137\231\186\167\232\132\154\230\156\172\230\158\154\228\184\190"
    },
    {
      Name = "new_level",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "\232\181\183\229\167\139\229\143\152\229\140\150\231\173\137\231\186\167",
          EnumName = "monster_level_script=NLS_ROLE_STAR,PET_LEVEL_CONF",
          LinkFieldName = "\229\143\152\229\140\150\233\151\180\233\154\148\231\173\137\231\186\167"
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "monster_level_script",
          Branches = {
            {
              Value = 2,
              TypeName = "PET_LEVEL_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\128\170\231\137\169\231\173\137\231\186\167"
    },
    {
      Name = "difficulty",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MonsterDifficultyType"
        }
      },
      Description = "\230\128\170\231\137\169\233\154\190\229\186\166\232\174\190\229\174\154"
    },
    {
      Name = "shining_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\232\137\178\231\170\129\229\143\152\230\166\130\231\142\135"
    },
    {
      Name = "chaos_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\183\183\230\178\140\231\170\129\229\143\152\230\166\130\231\142\135"
    },
    {
      Name = "glass_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\130\171\229\189\169\231\170\129\229\143\152\230\166\130\231\142\135"
    },
    {
      Name = "custom_glass",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "MONSTER_CONF_custom_glass"
        }
      },
      Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "height_percent",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\232\186\171\233\171\152\231\153\190\229\136\134\230\175\148\239\188\136\228\184\135\232\191\155\229\136\182\239\188\137"
    },
    {
      Name = "voice_percent",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\151\147\233\159\179\231\153\190\229\136\134\230\175\148\239\188\136\231\153\190\229\136\134\229\136\182\239\188\137"
    },
    {
      Name = "monster_carry_on",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 3
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "MONSTER_CONF_monster_carry_on"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "habit_stage",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\233\152\182\231\186\167"
    },
    {
      Name = "catch_pet_back_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\230\141\137\229\144\142\229\155\158\233\128\128\231\173\137\231\186\167"
    },
    {
      Name = "active_skill1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MONSTER_SKILLBANK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\144\186\229\184\166\228\184\187\229\138\168\230\138\128\232\131\1891"
    },
    {
      Name = "active_skill2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MONSTER_SKILLBANK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\144\186\229\184\166\228\184\187\229\138\168\230\138\128\232\131\1892"
    },
    {
      Name = "active_skill3",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MONSTER_SKILLBANK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\144\186\229\184\166\228\184\187\229\138\168\230\138\128\232\131\1893"
    },
    {
      Name = "active_skill4",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MONSTER_SKILLBANK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\144\186\229\184\166\228\184\187\229\138\168\230\138\128\232\131\1894"
    },
    {
      Name = "gender",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\140\135\229\174\154\230\128\167\229\136\171"
    },
    {
      Name = "nature_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NATURE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\140\135\229\174\154\230\128\167\230\160\188"
    },
    {
      Name = "blood_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_BLOOD_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\140\135\229\174\154\232\161\128\232\132\137"
    },
    {
      Name = "catch_difficulty",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\159\186\231\161\128\230\141\149\230\141\137\233\154\190\229\186\166\232\161\165\230\173\163"
    },
    {
      Name = "Catch_difficulty_OverThreshold",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\233\152\136\229\128\188\230\187\161\232\182\179\230\141\149\230\141\137\230\166\130\231\142\135"
    },
    {
      Name = "Catch_difficulty_UnderThreshold",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\233\152\136\229\128\188\230\156\170\230\187\161\232\182\179\228\191\174\230\173\163\229\128\188"
    },
    {
      Name = "catch_prob_max",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\164\167\230\141\149\230\141\137\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "individuality_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\228\184\170\228\189\147\232\181\132\232\180\168\230\149\176"
    },
    {
      Name = "break_times",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\170\129\231\160\180\230\172\161\230\149\176"
    },
    {
      Name = "inspire_time",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "INSPIRE_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\167\137\233\134\146\230\152\159\231\186\167"
    },
    {
      Name = "sharpen_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\179\187\229\136\171\230\158\129\229\140\150\230\149\176\229\128\188\229\174\154\229\136\182"
    },
    {
      Name = "blunt_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\179\187\229\136\171\233\146\157\229\140\150\230\149\176\229\128\188\229\174\154\229\136\182"
    },
    {
      Name = "attr_enum_break_set",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\170\129\231\160\180\232\174\190\229\174\154\229\177\158\230\128\167\230\158\154\228\184\190"
    },
    {
      Name = "individuality",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "waw"
    },
    {
      Name = "hp_max_plus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\148\159\229\145\189\229\128\188\228\184\138\233\153\144\233\153\132\229\138\160"
    },
    {
      Name = "phy_attack_plus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\230\148\187\229\135\187\233\153\132\229\138\160"
    },
    {
      Name = "spe_attack_plus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\148\187\229\135\187\233\153\132\229\138\160"
    },
    {
      Name = "phy_defence_plus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\233\152\178\229\190\161\233\153\132\229\138\160"
    },
    {
      Name = "spe_defence_plus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\233\152\178\229\190\161\233\153\132\229\138\160"
    },
    {
      Name = "speed_plus",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\128\159\229\186\166\233\153\132\229\138\160"
    },
    {
      Name = "hp_max_upper_mag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\148\159\229\145\189\229\128\188\228\184\138\233\153\144\229\128\141\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\140\233\187\152\232\174\164\228\184\1861w\239\188\137"
    },
    {
      Name = "phy_attack_upper_mag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\230\148\187\229\135\187\229\128\141\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "spe_attack_upper_mag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\148\187\229\135\187\229\128\141\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "phy_defence_upper_mag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\233\152\178\229\190\161\229\128\141\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "spe_defence_upper_mag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\233\152\178\229\190\161\229\128\141\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "speed_upper_mag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\128\159\229\186\166\229\128\141\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "level_skill_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "LEVEL_SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\138\128\232\131\189\233\154\143\230\156\186ID"
    },
    {
      Name = "level_skill_find_enum",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "LevelSkillFindType"
        }
      },
      Description = "\230\138\128\232\131\189ID\229\140\185\233\133\141\230\158\154\228\184\190"
    },
    {
      Name = "skill_find_param",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "level_skill_find_enum",
          Branches = {
            {
              Value = 1,
              TypeName = "LEVEL_SKILL_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\138\128\232\131\189ID\229\140\185\233\133\141\229\143\130\230\149\176"
    },
    {
      Name = "exp_award_fight_stage",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\136\152\230\150\151\232\131\156\229\136\169\230\143\144\228\190\155\231\187\143\233\170\140\229\128\188\239\188\136\233\154\143\233\152\182\230\174\181\230\138\149\230\148\190\239\188\137\227\128\144\233\133\141\231\189\174\229\141\149\228\184\128\229\128\188\229\136\153\228\184\186\229\155\186\229\174\154\231\187\143\233\170\140\229\128\188\239\188\140\229\189\147\231\178\190\231\129\181\232\191\155\229\140\150\233\147\190\229\140\185\233\133\141\230\158\154\228\184\190\239\188\154PFT_EVOLUTION_CHANGE\228\184\148\232\175\165\229\173\151\230\174\181\233\133\141\231\189\174\228\184\186\230\149\176\231\187\132\230\151\182\239\188\140\230\138\149\230\148\190\231\178\190\231\129\181\233\154\143\231\178\190\231\129\181\233\152\182\231\186\167\230\138\149\230\148\190\227\128\145"
    },
    {
      Name = "exp_award_catch_stage",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\141\149\230\141\137\230\136\144\229\138\159\230\143\144\228\190\155\231\187\143\233\170\140\229\128\188\239\188\136\233\154\143\233\152\182\230\174\181\230\138\149\230\148\190\239\188\137\227\128\144\233\133\141\231\189\174\229\141\149\228\184\128\229\128\188\229\136\153\228\184\186\229\155\186\229\174\154\231\187\143\233\170\140\229\128\188\239\188\140\229\189\147\231\178\190\231\129\181\232\191\155\229\140\150\233\147\190\229\140\185\233\133\141\230\158\154\228\184\190\239\188\154PFT_EVOLUTION_CHANGE\228\184\148\232\175\165\229\173\151\230\174\181\233\133\141\231\189\174\228\184\186\230\149\176\231\187\132\230\151\182\239\188\140\230\138\149\230\148\190\231\178\190\231\129\181\233\154\143\231\178\190\231\129\181\233\152\182\231\186\167\230\138\149\230\148\190\227\128\145"
    },
    {
      Name = "defeat_award",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\135\187\232\180\165/\233\128\131\232\183\145\230\151\182\231\154\132\229\165\150\229\138\177ID"
    },
    {
      Name = "catch_award",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\138\147\230\141\149\230\151\182\231\154\132\229\165\150\229\138\177ID"
    },
    {
      Name = "glass_award",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\142\187\231\146\131\231\170\129\229\143\152\231\154\132\233\162\157\229\164\150\229\165\150\229\138\177"
    },
    {
      Name = "exp_award_throwcatch_stage",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\138\149\230\142\183\230\141\149\230\141\137\230\136\144\229\138\159\230\143\144\228\190\155\231\187\143\233\170\140\229\128\188\239\188\136\233\154\143\233\152\182\230\174\181\230\138\149\230\148\190\239\188\137\227\128\144\233\133\141\231\189\174\229\141\149\228\184\128\229\128\188\229\136\153\228\184\186\229\155\186\229\174\154\231\187\143\233\170\140\229\128\188\239\188\140\229\189\147\231\178\190\231\129\181\232\191\155\229\140\150\233\147\190\229\140\185\233\133\141\230\158\154\228\184\190\239\188\154PFT_EVOLUTION_CHANGE\228\184\148\232\175\165\229\173\151\230\174\181\233\133\141\231\189\174\228\184\186\230\149\176\231\187\132\230\151\182\239\188\140\230\138\149\230\148\190\231\178\190\231\129\181\233\154\143\231\178\190\231\129\181\233\152\182\231\186\167\230\138\149\230\148\190\227\128\145"
    },
    {
      Name = "mf_behavior_tree_fight",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "MFBT\230\136\152\230\150\151\232\161\140\228\184\186\230\160\145\232\181\132\228\186\167\232\183\175\229\190\132"
    },
    {
      Name = "pre_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\233\162\132\228\188\176\231\177\187\229\158\139"
    },
    {
      Name = "pre_num",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\162\132\228\188\176\229\143\130\230\149\176"
    },
    {
      Name = "monster_bornmagic",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\233\173\148\230\179\149\229\128\188"
    },
    {
      Name = "unit_skill",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\139\134\228\187\182\230\138\128\232\131\189\239\188\136\231\148\168\230\157\165\228\184\180\230\151\182\230\143\146\229\133\165\231\137\185\229\174\154\230\138\128\232\131\189\239\188\137"
    },
    {
      Name = "bottle_reward_switch",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\148\175\230\140\129\231\147\182\232\163\133\233\135\135\233\155\134\231\137\169"
    },
    {
      Name = "model_scale",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 1, Max = 2000}
          }
        }
      },
      Description = "monster\230\168\161\229\158\139\231\188\169\230\148\190\230\175\148\228\190\139"
    },
    {
      Name = "is_nightmare",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\230\152\175\229\144\166\230\152\175\229\153\169\230\162\166\229\189\162\230\128\129"
    },
    {
      Name = "buff_icon_offset_z",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "buff\230\160\143z\232\189\180\229\129\143\231\167\187\233\135\143"
    },
    {
      Name = "difficulty_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\233\154\190\229\186\166\231\173\137\231\186\167\239\188\140\233\166\150\233\162\134\230\136\152\231\148\168"
    },
    {
      Name = "death_exist",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\231\187\147\230\157\159\230\151\182\239\188\140\231\178\190\231\129\181\231\154\132\230\173\187\228\186\161\232\161\168\230\188\148\239\188\154\239\188\136\229\143\170\233\146\136\229\175\185\233\135\142\230\128\170\230\136\152\230\150\151\239\188\137"
    }
  }
}
RTTIManager:RegisterType(MONSTER_CONF.Name, MONSTER_CONF)

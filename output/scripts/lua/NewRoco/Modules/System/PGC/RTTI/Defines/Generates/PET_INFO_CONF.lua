local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_INFO_CONF = {
  Name = "PET_INFO_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet_info/PET_INFO_CONF.yaml",
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
      Description = "\231\178\190\231\129\181\228\191\161\230\129\175ID"
    },
    {
      Name = "ball_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BALL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\146\149\229\153\156\231\144\131id"
    },
    {
      Name = "exp",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\231\187\143\233\170\140"
    },
    {
      Name = "shining_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\130\232\137\178\231\170\129\229\143\152\230\166\130\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "chaos_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\153\169\230\162\166\231\170\129\229\143\152\230\166\130\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "glass_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\142\187\231\146\131\231\170\129\229\143\152\230\166\130\231\142\135\239\188\136\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "custom_glass",
      Type = RTTIBase.FieldType.STRUCT,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_INFO_CONF_custom_glass"
        }
      },
      Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "height_percent",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
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
      Name = "weight_percent",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\228\189\147\233\135\141\231\153\190\229\136\134\230\175\148\239\188\136\228\184\135\232\191\155\229\136\182\239\188\137"
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
      Name = "pet_talent_rate",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetTalentRate"
        }
      },
      Description = "\231\178\190\231\129\181\229\164\169\229\136\134\232\175\132\228\187\183(\229\161\171\228\186\134\232\175\165\233\133\141\231\189\174\231\154\132\231\178\190\231\129\181\239\188\140\229\133\182\230\128\167\230\160\188\229\146\140\228\184\170\228\189\147\232\181\132\232\180\168\228\188\154\232\191\155\232\161\140\233\154\143\230\156\186\239\188\140\229\144\142\233\157\162\231\154\132\230\128\167\230\160\188id\239\188\140\228\184\170\228\189\147\232\181\132\232\180\168\233\133\141\231\189\174\229\176\134\230\151\160\230\149\136\239\188\137"
    },
    {
      Name = "gender",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\135\229\174\154\230\128\167\229\136\171"
    },
    {
      Name = "nature_id",
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
      Description = "\230\140\135\229\174\154\230\128\167\230\160\188id"
    },
    {
      Name = "blood_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_BLOOD_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\140\135\229\174\154\232\161\128\232\132\137id"
    },
    {
      Name = "talent_rand_value",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\135\229\174\154\228\184\170\228\189\147\232\181\132\232\180\168\233\154\143\230\156\186\229\128\188"
    },
    {
      Name = "hp_max_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "HP\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "phy_attack_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\230\148\187\229\135\187\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "spe_attack_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\148\187\229\135\187\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "phy_defence_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\231\144\134\233\152\178\229\190\161\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "spe_defence_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\233\152\178\229\190\161\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "speed_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\159\229\186\166\228\184\170\228\189\147\232\181\132\232\180\168"
    },
    {
      Name = "learn_skill_id",
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
      Description = "\230\138\128\232\131\189\233\154\143\230\156\186ID"
    },
    {
      Name = "is_unlock_all_machine_skill",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\167\163\233\148\129\230\137\128\230\156\137\231\154\132\230\138\128\232\131\189\231\159\179\230\138\128\232\131\189"
    },
    {
      Name = "pet_grow_times",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "GROW_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\136\144\233\149\191\230\172\161\230\149\176"
    },
    {
      Name = "pet_break_times",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BREAK_NUMBER_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\170\129\231\160\180\230\172\161\230\149\176"
    },
    {
      Name = "pet_inspire_time",
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
      Name = "blood_skill",
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
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\174\154\229\136\182\231\148\168\232\161\128\232\132\137\230\138\128\232\131\189"
    },
    {
      Name = "talent_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_TALENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\174\154\229\136\182\231\137\185\233\149\191"
    },
    {
      Name = "close_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\178\229\175\134\229\186\166\231\173\137\231\186\167"
    }
  }
}
RTTIManager:RegisterType(PET_INFO_CONF.Name, PET_INFO_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_BLOOD_CONF = {
  Name = "PET_BLOOD_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_BLOOD_CONF.yaml",
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
      Description = "\232\161\128\232\132\137ID"
    },
    {
      Name = "blood",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetBloodType"
        }
      },
      Description = "\232\161\128\232\132\137\231\177\187\229\158\139"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "bloodlinename"
        }
      },
      Description = "\232\161\128\232\132\137\229\144\141\231\167\176"
    },
    {
      Name = "blood_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillDamType"
        }
      },
      Description = "\231\179\187\229\136\171\231\177\187\229\158\139"
    },
    {
      Name = "is_precious",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\143\141\232\180\181\232\161\128\232\132\137"
    },
    {
      Name = "change_blood_action",
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
          EnumName = "ItemBehavior"
        }
      },
      Description = "\229\143\175\228\189\156\231\148\168\229\156\168\230\173\164\232\161\128\232\132\137\231\154\132\232\131\140\229\140\133\232\161\140\228\184\186\239\188\136\229\144\142\229\143\176\230\160\161\233\170\140\231\148\168\239\188\137"
    },
    {
      Name = "change_to_this_blood_action",
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
          EnumName = "ItemBehavior"
        }
      },
      Description = "\229\143\175\228\191\174\230\148\185\228\184\186\230\173\164\232\161\128\232\132\137\231\154\132\232\131\140\229\140\133\232\161\140\228\184\186\239\188\136\229\144\142\229\143\176\230\160\161\233\170\140\231\148\168\239\188\137"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\128\232\132\137\229\155\190\230\160\135"
    },
    {
      Name = "icon_1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\128\232\132\137\229\155\190\230\160\135\233\149\191\230\157\161"
    },
    {
      Name = "icon_flower",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\128\232\132\137\229\175\185\229\186\148\231\168\128\229\133\189\232\138\177\231\167\141"
    },
    {
      Name = "icon_flower_2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\128\232\132\137\232\138\177\231\167\141\229\155\190\230\160\135\239\188\136\232\191\155\229\133\165\230\140\145\230\136\152\231\149\140\233\157\162\231\148\168\239\188\137"
    },
    {
      Name = "blood_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "petbloodtypeshort"
        }
      },
      Description = "\232\161\128\232\132\137\229\144\141\231\167\176"
    },
    {
      Name = "attribute_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AttributeType"
        }
      },
      Description = "\229\189\177\229\147\141\229\177\158\230\128\167"
    },
    {
      Name = "attribute_data",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\189\177\229\147\141\230\175\148\228\190\139"
    },
    {
      Name = "inherit_or_not",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\129\151\228\188\160"
    },
    {
      Name = "blood_tips",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetBloodTipsType"
        }
      },
      Description = "\232\161\128\232\132\137tips\230\158\154\228\184\190"
    },
    {
      Name = "tips_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\150\135\230\156\172tips\230\143\143\232\191\176"
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
      Description = "\229\133\177\233\184\163\233\173\148\230\179\149\229\143\175\228\187\165\233\154\143\230\156\186\229\136\176\231\154\132\230\138\128\232\131\189"
    },
    {
      Name = "team_battle_location",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\162\228\189\147\230\136\152\230\151\182\232\175\165\232\161\128\232\132\137\229\175\185\229\186\148\231\154\132\228\189\141\231\189\174"
    },
    {
      Name = "icon_magicbook_limited_flower_seed",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\233\128\137\232\138\177\231\167\141\230\180\187\229\138\168\230\175\143\230\151\165\232\138\177\231\167\141\231\149\140\233\157\162icon"
    },
    {
      Name = "icon_activity_limited_flower_seed",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\233\128\137\232\138\177\231\167\141\230\180\187\229\138\168\231\149\140\233\157\162\230\152\190\231\164\186\231\148\168icon"
    },
    {
      Name = "star_ratio",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\159\229\133\137\230\148\190\229\164\167\229\128\141\231\142\135"
    }
  }
}
RTTIManager:RegisterType(PET_BLOOD_CONF.Name, PET_BLOOD_CONF)

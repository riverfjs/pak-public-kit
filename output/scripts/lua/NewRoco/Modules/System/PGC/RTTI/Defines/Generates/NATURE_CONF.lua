local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NATURE_CONF = {
  Name = "NATURE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/NATURE_CONF.yaml",
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
      Description = "\230\128\167\230\160\188ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "petpersonality"
        }
      },
      Description = "\230\128\167\230\160\188\229\144\141\231\167\176"
    },
    {
      Name = "is_player_pet_nature",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\231\142\169\229\174\182\231\178\190\231\129\181\228\189\191\231\148\168\231\154\132\230\128\167\230\160\188\239\188\159\239\188\136\230\128\167\230\160\188\228\184\186false\231\154\132\230\128\167\230\160\188\228\184\186\231\142\169\229\174\182\228\184\141\229\143\175\232\142\183\229\190\151\231\154\132\230\128\167\230\160\188\239\188\140\231\155\174\229\137\14131\230\152\175\231\187\153\233\135\142\230\128\170\228\184\147\231\148\168\231\154\132\239\188\137"
    },
    {
      Name = "positive_effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AttributeType"
        }
      },
      Description = "\230\173\163\233\157\162\229\189\177\229\147\141\229\177\158\230\128\167"
    },
    {
      Name = "positive_effect_proportion",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\163\233\157\162\229\189\177\229\147\141\229\136\157\229\167\139\229\128\188"
    },
    {
      Name = "positive_effect_grow",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\163\233\157\162\229\189\177\229\147\141\230\136\144\233\149\191\229\128\188"
    },
    {
      Name = "negative_effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AttributeType"
        }
      },
      Description = "\232\180\159\233\157\162\229\189\177\229\147\141\229\177\158\230\128\167"
    },
    {
      Name = "negative_effect_proportion",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\180\159\233\157\162\229\189\177\229\147\141\229\136\157\229\167\139\229\128\188"
    },
    {
      Name = "prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\157\131\233\135\141"
    },
    {
      Name = "relative_emotion",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\187\145\229\174\154\232\161\168\230\131\133\231\154\132\230\155\178\231\186\191\229\128\188"
    },
    {
      Name = "random_desc",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NATURE_CONF_random_desc"
        }
      },
      Description = ""
    },
    {
      Name = "morph_target_data",
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
          TypeName = "NATURE_CONF_morph_target_data"
        }
      },
      Description = ""
    }
  }
}
RTTIManager:RegisterType(NATURE_CONF.Name, NATURE_CONF)

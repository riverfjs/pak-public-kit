local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_GROWTH_CONF = {
  Name = "SEASON_GROWTH_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season/SEASON_GROWTH_CONF.yaml",
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
      Description = "\232\138\130\231\130\185id"
    },
    {
      Name = "season",
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
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "name"
        }
      },
      Description = "\229\144\141\231\167\176"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "desc"
        }
      },
      Description = "\230\143\143\232\191\176"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\138\130\231\130\185\231\168\128\230\156\137\229\186\166"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonGrowthType"
        }
      },
      Description = "\232\138\130\231\130\185\231\177\187\229\158\139\230\158\154\228\184\190"
    },
    {
      Name = "params",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 0,
              TypeName = "BUFF_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\138\130\231\130\185\229\143\130\230\149\176"
    },
    {
      Name = "target",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\139\228\186\136\229\175\185\232\177\161"
    },
    {
      Name = "sort",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\138\130\231\130\185\230\142\146\229\186\143"
    },
    {
      Name = "neighbor_sort",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\155\184\233\130\187\229\186\143\229\136\151"
    },
    {
      Name = "frame",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\186\149\230\161\134\232\181\132\230\186\144"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\135\232\181\132\230\186\144"
    },
    {
      Name = "material",
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
      Description = "\232\167\163\233\148\129\230\137\128\233\156\128\232\180\167\229\184\129\233\129\147\229\133\183"
    },
    {
      Name = "material_cost",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\230\137\128\233\156\128\230\157\144\230\150\153\230\149\176\233\135\143"
    },
    {
      Name = "battle_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BattleType"
        }
      },
      Description = "\231\148\159\230\149\136\231\154\132\230\136\152\230\150\151\231\177\187\229\158\139"
    },
    {
      Name = "battle_type_2",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BattleType"
        }
      },
      Description = "\231\148\159\230\149\136\231\154\132\230\136\152\230\150\151\231\177\187\229\158\139"
    },
    {
      Name = "battle_type_3",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BattleType"
        }
      },
      Description = "\231\148\159\230\149\136\231\154\132\230\136\152\230\150\151\231\177\187\229\158\139"
    },
    {
      Name = "special_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\185\230\174\138\230\143\143\232\191\176"
    }
  }
}
RTTIManager:RegisterType(SEASON_GROWTH_CONF.Name, SEASON_GROWTH_CONF)

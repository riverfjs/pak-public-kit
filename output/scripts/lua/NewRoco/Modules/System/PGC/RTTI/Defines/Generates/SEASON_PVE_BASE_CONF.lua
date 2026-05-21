local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SEASON_PVE_BASE_CONF = {
  Name = "SEASON_PVE_BASE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "season/SEASON_PVE_BASE_CONF.yaml",
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
      Description = "\229\164\150\233\147\190\230\168\161\229\157\151id"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\229\144\141\231\167\176"
    },
    {
      Name = "rule_show",
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
          TypeName = "SEASON_PVE_BASE_CONF_rule_show"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "season_talent",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_TALENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\164\169\232\181\139\230\160\145ID"
    },
    {
      Name = "legendary_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_LEGENDARY_BATTLE_EVENT",
          FieldName = "id"
        }
      },
      Description = "\232\181\155\229\173\163\228\188\160\232\175\180\231\178\190\231\129\181\228\186\139\228\187\182\231\180\162\229\188\149id"
    },
    {
      Name = "legendary_pet",
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
      Description = "\232\181\155\229\173\163\228\188\160\232\175\180\231\178\190\231\129\181petbase"
    },
    {
      Name = "legendary_refresh_trigger",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SPE_REFRESH_TRIG_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\181\155\229\173\163\228\188\160\232\175\180\231\178\190\231\129\181\229\136\183\230\150\176\228\186\139\228\187\182"
    },
    {
      Name = "ticket",
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
      Description = "\232\181\155\229\173\163\228\188\160\232\175\180\231\178\190\231\129\181\229\133\165\229\156\186\233\151\168\231\165\168id"
    },
    {
      Name = "season_ticket_cost",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\155\229\173\163\228\188\160\232\175\180\231\178\190\231\129\181\233\151\168\231\165\168\230\182\136\232\128\151\230\149\176\233\135\143"
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
      Description = "\232\181\155\229\173\163\229\164\169\232\181\139\230\160\145\231\160\148\231\169\182\231\130\185ID"
    },
    {
      Name = "res_id_0",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\169\232\181\139\230\149\136\230\158\156\231\148\159\230\149\136\230\136\145\230\150\185\231\178\190\231\129\181\231\137\185\230\149\136"
    },
    {
      Name = "res_id_1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\175\141\230\157\161\231\148\159\230\149\136\230\149\140\230\150\185\231\178\190\231\129\181\231\137\185\230\149\136"
    }
  }
}
RTTIManager:RegisterType(SEASON_PVE_BASE_CONF.Name, SEASON_PVE_BASE_CONF)

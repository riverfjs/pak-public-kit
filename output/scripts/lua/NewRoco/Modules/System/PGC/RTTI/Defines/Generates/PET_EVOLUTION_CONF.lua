local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_EVOLUTION_CONF = {
  Name = "PET_EVOLUTION_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_EVOLUTION_CONF.yaml",
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
      Description = "\232\191\155\229\140\150\233\147\190ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "evoname"
        }
      },
      Description = "\232\191\155\229\140\150\233\147\190\229\144\141\231\167\176"
    },
    {
      Name = "allow_show_team_battle_star",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\129\232\174\184\229\135\186\231\142\176\231\154\132\231\168\128\229\133\189\232\138\177\231\167\141\230\152\159\231\186\167\239\188\136\233\133\1410\230\136\150\231\169\186\232\161\168\231\164\186\228\184\141\229\135\186\231\142\176\239\188\137"
    },
    {
      Name = "allow_show_team_battle_star_array",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\133\129\232\174\184\229\135\186\231\142\176\231\154\132\231\168\128\229\133\189\232\138\177\231\167\141\230\152\159\231\186\167\239\188\140\229\133\172\229\188\143\239\188\154TEXTJOIN(\";\",1,IF(G6:H6=\"\",99,1))"
    },
    {
      Name = "pvp_mute_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "pvp\228\186\146\230\150\165\232\191\155\229\140\150\233\147\190\229\136\134\231\187\132\239\188\140I252\231\154\132\229\133\172\229\188\143\239\188\154IF(COUNTIF($C$6:$C252,$C252)=1,MAX($I$6:$I251)+1,XLOOKUP($C252,$C$6:$C251,$I$6:$I251))"
    },
    {
      Name = "evolution_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\231\137\140\231\148\168\232\191\155\229\140\150\233\147\190\231\187\132"
    },
    {
      Name = "handbook_evolution_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\233\137\180\231\148\168\232\191\155\229\140\150\233\147\190\231\187\132"
    },
    {
      Name = "statistics_evolution_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\230\141\174\231\187\159\232\174\161\231\148\168\232\191\155\229\140\150\233\147\190\231\187\132"
    },
    {
      Name = "evolution_chain",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 10
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_EVOLUTION_CONF_evolution_chain"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    },
    {
      Name = "home_feed_bagitem_id",
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
      Description = "\231\133\167\230\150\153\230\137\128\233\156\128bagitemid"
    },
    {
      Name = "home_feed_bagitem_num",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\133\167\230\150\153\230\137\128\233\156\128\231\137\169\229\147\129\230\149\176\233\135\143"
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
    }
  }
}
RTTIManager:RegisterType(PET_EVOLUTION_CONF.Name, PET_EVOLUTION_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BATTLE_CONF = {
  Name = "BATTLE_CONF",
  Version = 1,
  Description = "\231\174\161\231\144\134\230\184\184\230\136\143\229\134\133\229\143\145\231\148\159\231\154\132\230\137\128\230\156\137\230\136\152\230\150\151\231\154\132\228\191\161\230\129\175\239\188\140\229\140\133\230\139\172\229\175\185\230\137\139\231\154\132\233\128\160\229\158\139\227\128\129AI\227\128\129\228\189\191\231\148\168\231\154\132\231\178\190\231\129\181\227\128\129\230\138\128\232\131\189\239\188\140\228\187\165\229\143\138\230\136\152\230\150\151\232\161\168\231\142\176\231\173\137\228\191\161\230\129\175",
  Metadata = {
    Alias = "battle\232\161\168\227\128\129\230\136\152\230\150\151\232\161\168",
    RelativeYamlPath = "battle/BATTLE_CONF.yaml",
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
      Description = "\230\136\152\230\150\151ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "battlename"
        }
      },
      Description = "\230\136\152\230\150\151\229\144\141\231\167\176"
    },
    {
      Name = "background",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\229\156\186\230\153\175ID"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BattleType"
        }
      },
      Description = "\230\136\152\230\150\151\231\177\187\229\158\139"
    },
    {
      Name = "opposite_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OppositeType"
        }
      },
      Description = "\229\175\185\230\137\139\231\177\187\229\136\171 \239\188\136HP\229\136\164\230\150\173\239\188\137 0\239\188\154\230\153\174\233\128\154\233\135\142\230\128\170\230\136\152\230\150\151 1\239\188\154\228\184\142\229\157\143\228\186\186\230\136\152\230\150\151 2\239\188\154\228\184\142\229\165\189\228\186\186\230\136\152\230\150\151"
    },
    {
      Name = "show_availableHP_rule",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\177\149\231\164\186\229\133\165\229\156\186\232\167\132\229\136\153\231\149\140\233\157\162 0\230\136\150\231\169\186\228\184\141\229\177\149\231\164\186 1\229\177\149\231\164\186"
    },
    {
      Name = "role_available_HP",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\146\232\137\178\229\143\175\231\148\168HP\229\128\188"
    },
    {
      Name = "rival_available_HP",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\230\137\139\229\143\175\231\148\168HP\229\128\188"
    },
    {
      Name = "battle_model",
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
      Description = "\230\149\140\230\150\185\232\174\173\231\187\131\229\184\136\229\189\162\232\177\161"
    },
    {
      Name = "npc_title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "rivaltitle"
        }
      },
      Description = "\230\149\140\230\150\185\232\174\173\231\187\131\229\184\136\231\167\176\229\143\183"
    },
    {
      Name = "screen_show_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\135\229\177\143\230\188\148\229\135\186\230\149\136\230\158\156\232\183\175\229\190\132"
    },
    {
      Name = "show_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\186\174\231\155\184\230\188\148\229\135\186\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "show_brief_res",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\158\231\187\173\230\136\152\230\150\151\228\184\173\231\174\128\229\140\150\228\186\174\231\155\184\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "challanger_unit_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\140\145\230\136\152\230\150\185\228\184\138\229\156\186\229\141\149\228\189\141\230\149\176"
    },
    {
      Name = "bechallanger_unit_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\232\162\171\230\140\145\230\136\152\230\150\185\228\184\138\229\156\186\229\141\149\228\189\141\230\149\176"
    },
    {
      Name = "exchange_cold",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\162\229\174\160\230\140\135\228\187\164\229\134\183\229\141\180\229\155\158\229\144\136\230\149\176"
    },
    {
      Name = "exchange_initial_cold",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\162\229\174\160\230\140\135\228\187\164\229\136\157\229\167\139\229\134\183\229\141\180\229\155\158\229\144\136\230\149\176"
    },
    {
      Name = "max_round",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\231\154\132\230\156\128\229\164\167\229\155\158\229\144\136\230\149\176"
    },
    {
      Name = "result_over_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\232\190\190\229\136\176\230\156\128\229\164\167\229\155\158\229\144\136\230\149\176\231\187\147\230\157\159\230\151\182\239\188\140\231\187\147\230\158\156\229\136\164\229\174\154\230\150\185\229\188\143\239\188\154"
    },
    {
      Name = "background_music",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\232\131\140\230\153\175\233\159\179\228\185\144"
    },
    {
      Name = "bgm_battle_state",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "bgm\231\154\132state\229\173\151\231\172\166\228\184\178"
    },
    {
      Name = "is_auto",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\155\229\133\165\230\136\152\230\150\151\230\151\182\230\152\175\229\144\166\231\187\167\230\137\191\232\135\170\229\138\168\231\138\182\230\128\129"
    },
    {
      Name = "assist1",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\152\230\128\170\231\137\169\231\171\153\228\189\1411"
    },
    {
      Name = "assist2",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\152\230\128\170\231\137\169\231\171\153\228\189\1412"
    },
    {
      Name = "assist3",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\152\230\128\170\231\137\169\231\171\153\228\189\1413"
    },
    {
      Name = "assist4",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\152\230\128\170\231\137\169\231\171\153\228\189\1414"
    },
    {
      Name = "assist5",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\152\230\128\170\231\137\169\231\171\153\228\189\1415"
    },
    {
      Name = "assist6",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\152\230\128\170\231\137\169\231\171\153\228\189\1416"
    },
    {
      Name = "can_catch_or_not",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\229\143\175\230\141\149\230\141\137\230\136\152\230\150\151"
    },
    {
      Name = "can_useitem_or_not",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\229\143\175\228\189\191\231\148\168\233\129\147\229\133\183\230\136\152\230\150\151 0\239\188\154\228\184\141\233\153\144\229\136\182 1:\231\166\129\230\153\174\233\128\154\233\129\147\229\133\183 2:\231\166\129\229\133\177\233\184\163\233\173\148\230\179\149 3=1+2"
    },
    {
      Name = "can_escape",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\228\187\165\229\156\168\230\136\152\230\150\151\228\184\173\233\128\131\232\183\145"
    },
    {
      Name = "can_changepet",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\228\187\165\230\155\180\230\141\162\231\178\190\231\129\181"
    },
    {
      Name = "use_ball_time",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\175\143\229\155\158\229\144\136\229\143\175\228\184\162\231\144\131\230\172\161\230\149\176"
    },
    {
      Name = "use_happy_or_not",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\189\191\231\148\168\229\188\128\229\191\131\230\156\186\229\136\182"
    },
    {
      Name = "round_pet_timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\141\149\228\189\141\232\161\165\229\133\133\230\140\135\228\187\164\230\151\182\233\151\180"
    },
    {
      Name = "round_select_timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\135\228\187\164\233\128\137\230\139\169\233\152\182\230\174\181\230\151\182\233\151\180"
    },
    {
      Name = "pre_perform_timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\162\132\232\161\168\230\188\148\233\152\182\230\174\181\230\156\128\229\164\167\231\173\137\229\190\133\230\151\182\233\151\180"
    },
    {
      Name = "wait_load_timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\173\137\229\190\133\229\138\160\232\189\189\230\156\128\229\164\167\231\173\137\229\190\133\230\151\182\233\151\180 \233\133\141\231\169\186/0\232\175\187\233\187\152\232\174\164\230\151\182\233\151\180"
    },
    {
      Name = "catch_timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\141\149\230\141\137\233\152\182\230\174\181\231\173\137\229\190\133\230\156\128\229\164\167\230\151\182\233\151\180\239\188\136\231\155\174\229\137\141\229\143\170\230\156\137\229\155\162\228\189\147\230\136\152\230\156\137\232\175\165\233\152\182\230\174\181\239\188\137 \233\133\141\231\169\186/0\232\175\187\233\187\152\232\174\164\230\151\182\233\151\180"
    },
    {
      Name = "settle_timeout",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\229\156\186\231\187\147\231\174\151\233\152\182\230\174\181\230\156\128\229\164\167\231\173\137\229\190\133\230\151\182\233\151\180 \233\133\141\231\169\186/0\232\175\187\233\187\152\232\174\164\230\151\182\233\151\180"
    },
    {
      Name = "use_random_or_not",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\189\191\231\148\168\233\154\143\230\156\186\233\161\186\229\186\143"
    },
    {
      Name = "battle_item",
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
      Description = "\232\131\140\229\140\133\233\162\132\232\174\190\233\129\147\229\133\183"
    },
    {
      Name = "npc_battle_list",
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
          TypeName = "BATTLE_CONF_npc_battle_list"
        }
      },
      Description = "\230\149\140\228\186\186\232\174\190\231\189\174"
    },
    {
      Name = "special_battle_start_time",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\189\147\230\136\152\230\150\151\231\177\187\229\158\139\228\184\186PVESPECIAL\230\151\182\239\188\140\230\139\137\232\181\183\230\136\152\230\150\151\231\154\132\230\151\182\233\151\180\239\188\136\230\175\171\231\167\146\239\188\137"
    },
    {
      Name = "local_point",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\140\135\229\174\154\229\143\145\232\181\183\230\136\152\230\150\151\231\130\185\239\188\136\229\144\140\229\140\186\239\188\137"
    },
    {
      Name = "battle_done_data",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\174\176\229\189\149\230\136\152\230\150\151\229\174\140\230\136\144\230\149\176\230\141\174"
    },
    {
      Name = "battle_end_notify",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\136\152\230\150\151\231\187\147\230\157\159\229\144\142\233\128\154\231\159\165\229\156\186\230\153\175\231\154\132\230\151\182\230\156\186\239\188\1360/\231\169\186\230\152\175\231\187\147\230\157\159\229\137\141\229\136\160\233\153\164npc;1\230\152\175\231\187\147\230\157\159\229\144\142\229\136\160\233\153\164\239\188\137"
    },
    {
      Name = "teamA_prohibit_buff",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\136\145\230\150\185\231\166\129\230\173\162\232\162\171\230\183\187\229\138\160\231\154\132buff/effect"
    },
    {
      Name = "teamB_prohibit_buff",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\149\140\230\150\185\231\166\129\230\173\162\232\162\171\230\183\187\229\138\160\231\154\132buff/effect"
    },
    {
      Name = "is_hideskill",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "1\239\188\154\230\175\1434\228\184\170\230\138\128\232\131\189\228\184\128\231\187\132\239\188\140\230\175\143\231\187\132\233\154\144\232\151\143\233\154\143\230\156\1861\228\184\170\230\138\128\232\131\189\239\188\155 2~4\239\188\154\229\144\1401\239\188\140\233\154\143\230\156\186\233\154\144\232\151\1432~4\228\184\170\230\138\128\232\131\189\239\188\155 5\239\188\154\233\154\144\232\151\143\230\148\187\229\135\187\231\177\187+\233\152\178\229\190\161\231\177\187\230\138\128\232\131\189\239\188\155 6\239\188\154\233\154\144\232\151\143\230\148\187\229\135\187\231\177\187+\231\138\182\230\128\129\231\177\187\230\138\128\232\131\189\239\188\155 7\239\188\154\233\154\144\232\151\143\233\152\178\229\190\161\231\177\187+\231\138\182\230\128\129\231\177\187\230\138\128\232\131\189"
    },
    {
      Name = "battle_refresh_content",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\156\128\232\166\129\230\136\152\230\150\151\231\187\147\230\157\159\229\137\141\229\176\177\229\136\183\230\150\176\231\154\132id\239\188\136\231\155\174\229\137\141\229\143\170\231\148\168\230\157\165\233\133\141\231\189\174\233\166\150\233\162\134\230\136\152\231\154\132\229\174\157\231\174\177\239\188\137"
    },
    {
      Name = "worldcombat_box_guideicon",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcGuideIcon"
        }
      },
      Description = "\233\166\150\233\162\134\230\136\152\229\174\157\231\174\177\230\140\135\229\188\149\229\155\190\230\160\135\231\177\187\229\158\139"
    },
    {
      Name = "available_hp_rule",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AvailableHpRule"
        }
      },
      Description = "\230\136\152\230\150\151\233\148\129\232\161\128\231\154\132\231\177\187\229\158\139"
    },
    {
      Name = "available_hp_rule_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\143\130\230\149\176 blackman:\233\148\129\232\161\128\229\144\142\231\154\132\229\128\188\239\188\155\229\135\187\230\157\128\229\144\142\230\129\162\229\164\141\231\154\132\229\128\188"
    },
    {
      Name = "player_battle_buff",
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
      Description = "\232\191\155\230\136\152\230\150\151\229\144\142\231\142\169\229\174\182\232\142\183\229\190\151\231\154\132buff"
    },
    {
      Name = "npc_battle_buff",
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
      Description = "\232\191\155\230\136\152\230\150\151\229\144\142NPC\232\142\183\229\190\151\231\154\132buff"
    },
    {
      Name = "pet_close_buff",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\131\189\229\144\166\230\183\187\229\138\160\228\186\178\229\175\134\229\186\166BUFF"
    },
    {
      Name = "battle_habbit_switch",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\144\175\231\148\168\230\136\152\230\150\151\231\137\185\233\149\191"
    },
    {
      Name = "npc_battle_ally_list",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "BATTLE_CONF_npc_battle_ally_list"
        }
      },
      Description = "\229\138\169\230\136\152\232\174\190\231\189\174"
    },
    {
      Name = "if_npc_round_use_conf",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\180\232\167\130NPC\230\152\175\229\144\166\228\189\191\231\148\168\233\133\141\231\189\174\230\136\150\233\154\143\230\156\186\230\177\160"
    },
    {
      Name = "pve_npc_round_id",
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
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\155\180\232\167\130NPCid"
    },
    {
      Name = "pve_npc_round_ai_type",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\155\180\232\167\130NPCAI\231\177\187\229\158\139"
    },
    {
      Name = "battle_rule",
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
          TypeName = "BATTLE_RULE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\136\152\230\150\151\232\167\132\229\136\153"
    },
    {
      Name = "battle_tlog_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\175\165\230\136\152\230\150\151\232\162\171\228\189\191\231\148\168\229\156\168\229\147\170\228\184\170\231\142\169\230\179\149\233\135\140"
    },
    {
      Name = "die_show",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\187\228\186\161\232\161\168\230\188\148G6\239\188\136\229\155\160\228\188\160\232\175\180\231\178\190\231\129\181\229\155\162\228\189\147\230\136\152\228\191\174\230\148\185\230\183\187\229\138\160\231\154\132\230\150\176\229\173\151\230\174\181\239\188\137"
    },
    {
      Name = "escape_rule_1vn",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "1vN/1v1v1\230\151\182\239\188\140\231\178\190\231\129\181\233\128\131\232\183\145\231\154\132\232\167\132\229\136\153"
    },
    {
      Name = "delete_npc_rule_1vn",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "1vN/1v1v1\230\151\182\239\188\140\230\136\152\230\150\151\231\187\147\230\157\159\229\136\160\233\153\164NPC\231\154\132\232\167\132\229\136\153"
    },
    {
      Name = "task_battle_performance_control",
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
          EnumName = "TaskBattlePerformanceControl"
        }
      },
      Description = "\229\137\167\230\131\133\230\136\152\230\150\151\229\135\186\229\133\165\229\156\186\232\161\168\230\188\148\230\142\167\229\136\182"
    },
    {
      Name = "npc_round_scale",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\180\232\167\130NPC\231\154\132\231\188\169\230\148\190\230\175\148\228\190\139\239\188\136100=100%\239\188\137"
    },
    {
      Name = "npc_round_tip_scale",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\180\232\167\130NPC\230\137\128\229\134\146\229\135\186\233\163\152\229\173\151\230\176\148\230\179\161UI\231\154\132\231\188\169\230\148\190\230\175\148\228\190\139"
    },
    {
      Name = "is_mark_close",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\133\179\233\151\173\231\149\153\231\151\149\231\155\184\229\133\179\231\154\132\228\184\128\229\136\135\229\138\159\232\131\189"
    },
    {
      Name = "cancel_watch",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\177\143\232\148\189\232\167\130\230\136\152"
    },
    {
      Name = "feature_resonance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "FeatureResonanceType"
    }
  }
}
RTTIManager:RegisterType(BATTLE_CONF.Name, BATTLE_CONF)

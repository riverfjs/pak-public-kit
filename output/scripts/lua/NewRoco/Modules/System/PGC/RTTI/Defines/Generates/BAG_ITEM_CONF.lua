local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local BAG_ITEM_CONF = {
  Name = "BAG_ITEM_CONF",
  Version = 1,
  Description = "\231\174\161\231\144\134\230\137\128\230\156\137\231\142\169\229\174\182\229\143\175\228\187\165\232\142\183\229\190\151\231\154\132\233\129\147\229\133\183\231\154\132\232\161\168\239\188\140\229\143\175\228\187\165\231\174\161\231\144\134\233\129\147\229\133\183\231\154\132\229\144\141\231\167\176\227\128\129\230\143\143\232\191\176\227\128\129ICON\227\128\129\232\142\183\229\143\150\230\184\160\233\129\147\231\173\137\228\191\161\230\129\175",
  Metadata = {
    Alias = "\233\129\147\229\133\183\232\161\168",
    RelativeYamlPath = "bag_item/BAG_ITEM_CONF.yaml",
    SheetIndex = 0,
    NeedPrimaryKey = true
  },
  Fields = {
    {
      Name = "id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.PRIMARY_KEY
        }
      },
      Description = "\233\129\147\229\133\183ID"
    },
    {
      Name = "sort_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\142\146\229\186\143ID"
    },
    {
      Name = "npcid",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\129\147\229\133\183\229\175\185\229\186\148\229\156\186\230\153\175\228\186\164\228\186\146\231\137\169id"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "itemname"
        }
      },
      Description = "\229\144\141\231\167\176"
    },
    {
      Name = "is_release",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\138\149\230\148\190/\232\191\155\231\137\136\230\156\172"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\230\141\174\231\188\150\232\190\145\229\153\168\230\152\190\231\164\186\229\144\141\231\167\176"
    },
    {
      Name = "description",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "itemdesc"
        }
      },
      Description = "\231\137\169\229\147\129\230\143\143\232\191\176\239\188\140\233\156\128\232\166\129\230\148\175\230\140\129html\230\150\135\230\156\172"
    },
    {
      Name = "flavor_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "flavortext"
        }
      },
      Description = "\232\183\159\229\156\168\231\137\169\229\147\129\230\143\143\232\191\176\229\144\142\233\157\162\231\154\132\233\163\142\229\145\179\230\150\135\229\173\151"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\135\232\183\175\229\190\132"
    },
    {
      Name = "big_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\229\155\190\230\160\135\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "TUIbutton_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\187\231\149\140\233\157\162\230\138\149\230\142\183\230\140\137\233\146\174\229\155\190\230\160\135\232\181\132\230\186\144\232\183\175\229\190\132"
    },
    {
      Name = "model",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\232\183\175\229\190\132"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BagItemType"
        }
      },
      Description = "\231\137\169\229\147\129\231\177\187\229\158\139\239\188\140\231\148\168\228\186\142\233\128\187\232\190\145\229\136\134\231\177\187\239\188\140\229\188\128\229\143\145\228\188\154\228\189\191\231\148\168\232\191\153\229\136\151\232\191\155\232\161\140\233\128\187\232\190\145\229\136\164\230\150\173\239\188\129\232\175\183\230\179\168\230\132\143"
    },
    {
      Name = "is_para_reward",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\232\138\130\229\165\150\229\138\177\233\129\147\229\133\183\239\188\140\229\133\179\232\129\148\228\187\187\229\138\161\233\133\141\231\189\174\239\188\140\232\139\165true\229\136\153\230\152\175\239\188\140\233\187\152\232\174\164false"
    },
    {
      Name = "lable_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ItemLableType"
        }
      },
      Description = "\229\140\133\232\163\185\231\149\140\233\157\162\229\136\134\231\177\187\230\160\135\231\173\190\239\188\140\231\148\168\228\186\142\233\133\141\231\189\174\231\137\169\229\147\129\229\156\168\229\140\133\232\163\185\231\149\140\233\157\162\228\184\173\231\169\182\231\171\159\229\189\146\229\177\158\229\156\168\229\147\170\228\184\170\229\136\134\231\177\187\228\184\139"
    },
    {
      Name = "type_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "itemtypetxt"
        }
      },
      Description = "\231\177\187\229\158\139\230\143\143\232\191\176"
    },
    {
      Name = "is_interior_finish",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\232\163\133\230\189\162"
    },
    {
      Name = "can_see",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\156\168\229\140\133\232\163\185\229\134\133\230\152\190\231\164\186"
    },
    {
      Name = "tips_not_show_inventory",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\162\132\232\167\136tips\228\184\141\230\152\190\231\164\186\232\131\140\229\140\133\229\186\147\229\173\152"
    },
    {
      Name = "throw_function_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "THROW_FUNC_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\138\149\230\142\183\229\138\159\232\131\189id"
    },
    {
      Name = "magic_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "MAGIC_BASE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\229\186\148\231\154\132\233\173\148\230\179\149\233\133\141\231\189\174id"
    },
    {
      Name = "player_skill_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PLAYER_MAGIC_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\133\177\233\184\163\233\173\148\230\179\149\231\154\132\233\133\141\231\189\174id"
    },
    {
      Name = "can_charging",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\229\143\175\229\133\133\232\131\189\233\129\147\229\133\183"
    },
    {
      Name = "icon_charging1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\133\232\131\189\233\129\147\229\133\183\229\155\190\230\160\135\232\183\175\229\190\1321"
    },
    {
      Name = "icon_charging2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\133\232\131\189\229\155\190\230\160\135\233\129\147\229\133\183\232\183\175\229\190\1322"
    },
    {
      Name = "initial_use_times",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\228\189\191\231\148\168\230\172\161\230\149\176\228\184\138\233\153\144"
    },
    {
      Name = "can_use_in_battle",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\230\136\152\230\150\151\229\134\133\228\189\191\231\148\168\231\154\132\233\129\147\229\133\183"
    },
    {
      Name = "can_use_in_bag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\229\156\168\232\131\140\229\140\133\228\184\173\228\189\191\231\148\168"
    },
    {
      Name = "can_use_in_pet_bag",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\229\156\168\229\174\160\231\137\169\229\140\133\232\163\185\228\184\173\228\189\191\231\148\168"
    },
    {
      Name = "is_consume",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\191\231\148\168\229\144\142\230\152\175\229\144\166\230\182\136\232\128\151"
    },
    {
      Name = "is_auto_use",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\142\183\229\143\150\229\144\142\230\152\175\229\144\166\232\135\170\229\138\168\228\189\191\231\148\168"
    },
    {
      Name = "show_quantity",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\190\231\164\186\233\129\147\229\133\183\230\149\176\233\135\143"
    },
    {
      Name = "item_behavior",
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
          TypeName = "BAG_ITEM_CONF_item_behavior"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "can_stack",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\229\143\160\229\138\160:1-\229\143\175\229\143\160\229\138\160"
    },
    {
      Name = "can_not_repeat",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\141\229\143\175\233\135\141\229\164\141\232\142\183\229\190\151\239\188\140\229\133\183\230\156\137\229\148\175\228\184\128\230\128\167"
    },
    {
      Name = "can_compose",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\228\187\165\229\144\136\230\136\144"
    },
    {
      Name = "compose_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\144\136\230\136\144\233\129\147\229\133\183\231\154\132\230\149\176\233\135\143"
    },
    {
      Name = "compose_id",
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
      Description = "\229\144\136\230\136\144\231\187\147\230\158\156ID"
    },
    {
      Name = "expire_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\135\230\156\159\230\151\182\233\151\180"
    },
    {
      Name = "item_quality",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\168\128\230\156\137\229\186\166\239\188\1360~5\239\188\137"
    },
    {
      Name = "acquire_struct",
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
          TypeName = "BAG_ITEM_CONF_acquire_struct"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142\239\188\136\230\142\167\229\136\182\230\149\176\233\135\143  \231\155\174\229\137\141\232\167\132\229\136\146\230\156\128\229\164\1543\230\157\161\239\188\137"
    },
    {
      Name = "is_daily_reward",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\189\156\228\184\186\230\175\143\230\151\165\232\176\131\230\159\165\229\165\150\229\138\177\231\178\190\231\129\181\232\155\139"
    },
    {
      Name = "is_close_bagui",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\189\191\231\148\168\231\137\169\229\147\129\229\144\142\229\133\179\233\151\173\232\131\140\229\140\133\231\149\140\233\157\162\239\188\1361\239\188\154\229\133\179\233\151\173\239\188\1550\230\136\150\231\149\153\231\169\186\239\188\154\228\184\141\229\133\179\233\151\173\239\188\137"
    },
    {
      Name = "outline_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\158\156\229\174\158\232\189\174\229\187\147icon\232\183\175\229\190\132"
    },
    {
      Name = "effect_description",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\137\169\229\147\129\230\143\143\232\191\176\239\188\140\233\156\128\232\166\129\230\148\175\230\140\129html\230\150\135\230\156\172"
    },
    {
      Name = "badge_pos",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\190\189\231\171\160\230\142\146\229\186\143"
    },
    {
      Name = "mark_start_task",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\137\185\230\174\138\228\187\187\229\138\161\233\129\147\229\133\183\232\181\183\229\167\139\228\187\187\229\138\161"
    },
    {
      Name = "mark_end_task",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\137\185\230\174\138\228\187\187\229\138\161\233\129\147\229\133\183\231\187\147\230\157\159\228\187\187\229\138\161"
    },
    {
      Name = "icon_sign",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "icon\229\143\179\228\184\138\232\167\146\232\167\146\230\160\135"
    },
    {
      Name = "known_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\173\152\229\156\168\229\155\190\233\137\180\230\149\176\230\141\174\229\144\142\231\154\132\231\178\190\231\129\181\232\155\139/\230\158\156\229\174\158\229\144\141\231\167\176"
    },
    {
      Name = "known_description",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\173\152\229\156\168\229\155\190\233\137\180\230\149\176\230\141\174\229\144\142\231\154\132\231\178\190\231\129\181\232\155\139/\230\158\156\229\174\158\230\143\143\232\191\176"
    },
    {
      Name = "is_no_display_in_main",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\141\229\156\168\228\184\187\231\149\140\233\157\162\229\143\179\228\190\167\230\152\190\231\164\186\232\142\183\229\190\151\230\143\144\231\164\186"
    },
    {
      Name = "is_home_plant_item",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\229\174\182\229\155\173\231\167\141\230\164\141\228\189\156\231\137\169(icon\229\143\179\228\184\138\229\138\160\232\167\146\230\160\135\231\148\168)"
    },
    {
      Name = "key_identifier",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\179\233\148\174\233\129\147\229\133\183\230\160\135\232\175\134\239\188\1361-\233\135\141\231\130\185\229\133\179\230\179\168\239\188\137"
    },
    {
      Name = "ban_pet_return",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "ban\230\142\137\228\184\141\232\131\189\229\155\158\230\186\175\231\154\132\231\137\169\229\147\129"
    }
  }
}
RTTIManager:RegisterType(BAG_ITEM_CONF.Name, BAG_ITEM_CONF)

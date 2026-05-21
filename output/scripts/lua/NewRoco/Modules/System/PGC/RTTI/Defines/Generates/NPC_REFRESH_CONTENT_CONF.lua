local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NPC_REFRESH_CONTENT_CONF = {
  Name = "NPC_REFRESH_CONTENT_CONF",
  Version = 1,
  Description = "NPC_REFRESH_CONTENT_CONF\239\188\136\233\128\154\229\184\184\231\174\128\231\167\176\228\184\186 Content \232\161\168\239\188\137\230\152\175\230\184\184\230\136\143\228\187\187\229\138\161\231\179\187\231\187\159\228\184\173\231\148\168\228\186\142\229\174\154\228\185\137\229\146\140\231\174\161\231\144\134\230\184\184\230\136\143\228\184\150\231\149\140\229\134\133\229\133\183\228\189\147\228\186\164\228\186\146\229\175\185\232\177\161\229\174\158\228\190\139\231\154\132\230\160\184\229\191\131\233\133\141\231\189\174\230\150\135\228\187\182\227\128\130",
  Metadata = {
    Alias = "REFRESH\227\128\129CONTENT\227\128\129NPC",
    RelativeYamlPath = "npc_refresh/NPC_REFRESH_CONTENT_CONF.yaml",
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
            {Min = 1, Max = 8099999},
            {Min = 10000000, Max = 14999999},
            {Min = 20000000, Max = 41000000}
          }
        }
      },
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING,
          Size = 3
        }
      },
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "disable",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\175\165\230\157\161\233\133\141\231\189\174\229\164\177\230\149\136"
    },
    {
      Name = "version",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\230\141\174\231\137\136\230\156\172\229\143\18312"
    },
    {
      Name = "refresh_update_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RefreshUpdateType"
        }
      },
      Description = "\232\139\165\231\137\136\230\156\172\229\143\183\229\143\145\231\148\159\229\143\152\229\140\150\239\188\140\233\156\128\232\166\129\229\164\132\231\189\174\229\183\178\229\136\183\230\150\176\231\154\132npc"
    },
    {
      Name = "online_is_clear",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\232\129\148\230\156\186\228\184\139\228\184\141\229\136\183\229\135\186"
    },
    {
      Name = "refresher_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RefresherType"
        }
      },
      Description = "\229\136\183\230\150\176\229\153\168\231\177\187\229\158\139"
    },
    {
      Name = "relogin_refresh_point",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "NPC\231\166\187\229\188\128\230\156\141\229\138\161\229\153\168aoi\232\140\131\229\155\180\229\144\142\228\184\139\230\172\161\230\152\175\229\144\166\229\156\168\231\166\187\229\188\128\228\189\141\231\189\174\229\136\183\229\135\186 \239\188\136FALSE\230\136\150\232\128\133\231\169\186\228\184\186\229\156\168\229\136\157\229\167\139\229\136\183\230\150\176\231\130\185\228\189\141\231\189\174\229\136\183\229\135\186\239\188\155TRUE\228\184\186\229\156\168\231\166\187\229\188\128aoi\228\189\141\231\189\174\229\136\183\229\135\186\239\188\137"
    },
    {
      Name = "overlap_processing_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OverLapProcessingType"
        }
      },
      Description = "\229\136\183\230\150\176\228\189\141\231\189\174\228\184\142\231\142\169\229\174\182\239\188\136\230\136\191\228\184\187\229\146\140\232\174\191\229\174\162\239\188\137\233\135\141\229\143\160\229\164\132\231\144\134\230\150\185\230\161\136\230\158\154\228\184\190"
    },
    {
      Name = "Application_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "Applicationtype"
        }
      },
      Description = "\231\148\168\233\128\148\232\175\180\230\152\142"
    },
    {
      Name = "refresh_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RefreshType"
        }
      },
      Description = "\229\136\183\230\150\176\230\150\185\229\188\143"
    },
    {
      Name = "refresh_param",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "refresh_type",
          Branches = {
            {
              Value = 1,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "SCENE_OBJECT_CONF",
              FieldName = "id"
            },
            {
              Value = 6,
              TypeName = "SCENE_CONF",
              FieldName = "id"
            },
            {
              Value = 7,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 9,
              TypeName = "AREA_GROUP_CONF",
              FieldName = "id"
            },
            {
              Value = 5,
              TypeName = "SCENE_OBJECT_CONF",
              FieldName = "object_tag"
            }
          }
        }
      },
      Description = "\229\136\183\230\150\176\229\143\130\230\149\176"
    },
    {
      Name = "affiliated_object",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\153\132\229\177\158\229\175\185\232\177\161"
    },
    {
      Name = "bb_input_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_BB_INPUT_CONF",
          FieldName = "id"
        }
      },
      Description = ""
    },
    {
      Name = "refresh_rule",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RefreshRuleConf"
        }
      },
      Description = "\229\136\183\230\150\176\232\167\132\229\136\153"
    },
    {
      Name = "ClientHidden",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\136\157\229\167\139\233\154\144\232\151\143\239\188\136\229\174\162\230\136\183\231\171\175\229\177\130\233\157\162\239\188\137\239\188\140\233\187\152\232\174\164\228\184\186\231\169\186=\230\152\190\231\164\186\239\188\140\229\161\171TRUE\229\136\153\233\154\144\232\151\143"
    },
    {
      Name = "specify_area_number",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\140\135\229\174\154\229\186\143\229\136\151"
    },
    {
      Name = "max_num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\156\128\229\164\167\229\173\152\229\156\168\230\149\176\233\135\143"
    },
    {
      Name = "storage_num",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\186\147\229\173\152\230\149\176\233\135\143"
    },
    {
      Name = "patrol_belong_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PatrolBelongType"
        }
      },
      Description = "\229\183\161\233\128\187\229\189\146\229\177\158\231\177\187\229\158\139"
    },
    {
      Name = "patrol_param",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "patrol_belong_type",
          Branches = {
            {
              Value = 1,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "AREA_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\183\161\233\128\187\229\189\146\229\177\158\229\143\130\230\149\176"
    },
    {
      Name = "npc_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "npc_id"
    },
    {
      Name = "npc_option_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcrefreshOptionType"
        }
      },
      Description = "npc_option\231\154\132\229\164\132\231\144\134\230\150\185\229\188\143"
    },
    {
      Name = "npc_option_ids",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "npc_option_type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\183\187\229\138\160\230\136\150\232\166\134\229\134\153\231\154\132option_id"
    },
    {
      Name = "time_random",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\154\143\230\156\186\230\151\182\233\151\180\229\136\183\230\150\176\229\143\130\230\149\176"
    },
    {
      Name = "survive_time",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "npc\230\156\128\229\164\154\232\131\189\229\173\152\230\180\187\231\154\132\230\151\182\233\151\180\239\188\136\231\167\146\239\188\137"
    },
    {
      Name = "offline_remove",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\228\184\139\231\186\191\229\144\142\230\152\175\229\144\166\231\167\187\233\153\164"
    },
    {
      Name = "npc_level_script",
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
      Name = "level_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "\232\181\183\229\167\139\229\143\152\229\140\150\231\173\137\231\186\167",
          EnumName = "npc_level_script=NLS_ROLE_STAR,PET_LEVEL_CONF",
          LinkFieldName = "\229\143\152\229\140\150\233\151\180\233\154\148\231\173\137\231\186\167"
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "npc_level_script",
          Branches = {
            {
              Value = 2,
              TypeName = "PET_LEVEL_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\173\137\231\186\167\229\143\130\230\149\176"
    },
    {
      Name = "lock_on_ground",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\135\170\229\138\168\232\180\180\229\156\176"
    },
    {
      Name = "LocationTag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "LocationTag"
        }
      },
      Description = "\229\174\154\228\185\137\229\164\167\228\184\150\231\149\140\228\184\173\230\137\128\229\164\132\228\189\141\231\189\174"
    },
    {
      Name = "local_point",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
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
      Name = "adjust_dir",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "npc\229\136\155\229\187\186\230\151\182\230\152\175\229\144\166\228\191\174\230\173\163\230\156\157\229\144\145\228\184\187\232\167\146\230\137\128\229\156\168\230\150\185\229\144\145"
    },
    {
      Name = "Close_Condition_Type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "CloseConditionType"
        }
      },
      Description = "NPC\231\167\187\233\153\164\229\136\183\230\150\176\229\186\143\229\136\151\230\157\161\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "Close_Condition_param",
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
          DriverField = "Close_Condition_Type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "BATTLE_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "NPC\231\167\187\233\153\164\229\136\183\230\150\176\229\186\143\229\136\151\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "npc_initial_status",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcInitialStatus"
        }
      },
      Description = "\229\136\157\229\167\139\232\161\168\231\142\176\231\138\182\230\128\129"
    },
    {
      Name = "init_status",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.ENUM
        },
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SpaceActorLogicStatus"
        }
      },
      Description = "npc\229\136\157\229\167\139\233\128\187\232\190\145\231\138\182\230\128\129"
    },
    {
      Name = "init_property_types",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
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
      Description = "npc\229\136\157\229\167\139\231\179\187\229\136\171"
    },
    {
      Name = "glass_limit_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GlassLimitType"
        }
      },
      Description = "\231\170\129\229\143\152\228\188\170\233\154\143\230\156\186\231\177\187\229\158\139"
    },
    {
      Name = "chaos_limit_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ChaosLimitType"
        }
      },
      Description = "\229\153\169\230\162\166\231\170\129\229\143\152\228\188\170\233\154\143\230\156\186\231\177\187\229\158\139"
    },
    {
      Name = "shining_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "npc\229\188\130\232\137\178\231\170\129\229\143\152\230\166\130\231\142\135\239\188\136\231\153\190\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "chaos_prob",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "npc\229\153\169\230\162\166\231\170\129\229\143\152\230\166\130\231\142\135\239\188\136\231\153\190\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "glass_prob",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "npc\231\142\187\231\146\131\231\170\129\229\143\152\230\166\130\231\142\135\239\188\136\231\153\190\228\184\135\229\136\134\230\175\148\239\188\137"
    },
    {
      Name = "nature_rand",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
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
      Description = "\229\143\175\233\154\143\230\156\186\231\154\132\230\128\167\230\160\188\229\136\151\232\161\168"
    },
    {
      Name = "proportion_male",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\231\167\141\231\190\164\233\155\132\230\128\167\230\175\148\239\188\136\233\133\141\231\169\186\228\184\186\232\183\159\233\154\143petbase\239\188\140\233\133\1410\232\161\168\231\164\186\229\143\170\230\156\137\233\155\140\230\128\167\239\188\137"
    },
    {
      Name = "init_option_available",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\229\136\157\229\167\139\228\186\164\228\186\146\230\152\175\229\144\166\229\133\179\233\151\173"
    },
    {
      Name = "belong_camp",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.INDEX
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\174\161\232\190\150\230\158\175\230\158\157id"
    },
    {
      Name = "npc_pendant_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_PENDANT_CONF",
          FieldName = "id"
        }
      },
      Description = "Npc\230\140\130\228\187\182Id"
    },
    {
      Name = "worldnature_prob",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "npc\229\164\167\228\184\150\231\149\140\230\128\167\230\160\188\231\170\129\229\143\152\230\166\130\231\142\135"
    },
    {
      Name = "worldnature_prob_direction",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "WorldNatureDirection"
        }
      },
      Description = "npc\229\164\167\228\184\150\231\149\140\230\128\167\230\160\188\231\170\129\229\143\152\230\150\185\229\144\145"
    },
    {
      Name = "disappear_animation",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "ANIM_ID_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\182\136\229\164\177\230\151\182\230\146\173\230\148\190\231\137\185\230\149\136"
    },
    {
      Name = "ai_group_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 5
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NPC_REFRESH_CONTENT_CONF_ai_group_param"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "pet_habitat_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\160\150\230\129\175\229\156\176\231\190\164\231\187\132"
    },
    {
      Name = "show_habitat",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\232\162\171\231\178\190\231\129\181\230\160\150\230\129\175\229\156\176\230\163\128\231\180\162"
    },
    {
      Name = "mf_behavior_tree",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "MFBT\232\161\140\228\184\186\230\160\145\232\181\132\228\186\167\232\183\175\229\190\132"
    },
    {
      Name = "ai_perform_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_GROUP_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "AI\232\161\140\228\184\186\232\166\134\231\155\150"
    },
    {
      Name = "world_hide",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
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
      Scope = RTTIBase.ScopeType.Both,
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
      Name = "mimic_target",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
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
      Name = "cannot_be_seen",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\183\230\150\176\230\151\182\233\154\144\229\189\162\239\188\136\230\132\159\231\159\165\229\144\142\230\176\184\228\185\133\229\143\175\232\167\129\239\188\137"
    },
    {
      Name = "visible_during_perception",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\183\230\150\176\230\151\182\233\154\144\229\189\162\239\188\136\229\143\170\230\156\137\230\132\159\231\159\165\230\156\159\233\151\180\229\143\175\232\167\129\239\188\137"
    },
    {
      Name = "visible_during_nightmare",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\183\230\150\176\228\185\139\229\144\142\229\143\170\230\156\137\229\153\169\230\162\166\231\169\186\233\151\180\229\134\133\229\143\175\232\167\129"
    },
    {
      Name = "model_scale",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\168\161\229\158\139\231\188\169\230\148\190(\233\187\152\232\174\164\228\184\186100)"
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
      Name = "refresh_delaytime",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\183\230\150\176\229\187\182\232\191\159\230\151\182\233\151\180\239\188\136\230\175\171\231\167\146\239\188\137"
    },
    {
      Name = "Light_BP",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "NPC\230\140\130\232\189\189\231\129\175\229\133\137\232\147\157\229\155\190"
    },
    {
      Name = "not_destroy_by_1vn",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\232\162\171\230\139\137\229\133\1651vN\229\144\142\230\152\175\229\144\166\233\148\128\230\175\129\239\188\140\233\133\1411\228\191\157\231\149\153"
    },
    {
      Name = "is_reroll_npc_position",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\156\168\230\175\143\230\172\161\229\136\155\229\187\186npc\230\151\182\233\135\141\233\128\137\229\135\186\231\148\159\231\130\185\239\188\136\230\175\143\230\172\161\233\135\141\230\150\176\232\191\155\229\133\165aoi\232\140\131\229\155\180\233\131\189\228\188\154\229\134\141\230\172\161\233\154\143\230\156\186\239\188\137"
    },
    {
      Name = "is_forbid_track",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\231\166\129\230\173\162\229\155\190\233\137\180\232\191\189\232\184\170"
    },
    {
      Name = "emerge_skill",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\142\176\230\151\182\230\138\128\232\131\189\232\183\175\229\190\132"
    },
    {
      Name = "is_can_exhausted",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\156\137\232\128\151\229\176\189\231\138\182\230\128\129"
    },
    {
      Name = "team_battle_not_delete",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\153\174\233\128\154\232\138\177\231\167\141\230\136\152\230\150\151\231\187\147\230\157\159\229\144\142\230\152\175\229\144\166\228\184\141\229\136\160\233\153\164"
    },
    {
      Name = "is_questgiver",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\187\187\229\138\161\229\167\148\230\137\152\228\186\186"
    },
    {
      Name = "is_bonus_shining",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\232\191\158\231\187\173\230\141\149\230\141\137\232\167\166\229\143\145\231\154\132\229\188\130\232\137\178\231\178\190\231\129\181"
    },
    {
      Name = "custom_mutation_type",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\164\150\232\167\130\231\170\129\229\143\152"
    },
    {
      Name = "force_show_falconmap",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\188\186\229\136\182\229\156\168falconMap\228\184\173\230\152\190\231\164\186"
    }
  }
}
RTTIManager:RegisterType(NPC_REFRESH_CONTENT_CONF.Name, NPC_REFRESH_CONTENT_CONF)

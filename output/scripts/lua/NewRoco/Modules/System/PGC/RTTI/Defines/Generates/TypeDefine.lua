local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
RTTIManager:RegisterType("NPC_CONF_overtime_action", {
  Name = "NPC_CONF_overtime_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "overtime",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\182\133\230\151\182\230\143\144\233\134\146\230\151\182\233\151\180\239\188\136\231\167\146\239\188\137"
    },
    {
      Name = "overtime_notify",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\230\143\144\233\134\146\230\150\135\230\156\172"
    },
    {
      Name = "overtime_act",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "EmotionType"
        }
      },
      Description = "\230\143\144\233\134\146\230\151\182\232\161\168\230\188\148\231\154\132\229\138\168\228\189\156"
    }
  }
})
RTTIManager:RegisterType("NPC_CONF_ai_group_param", {
  Name = "NPC_CONF_ai_group_param",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("BAG_ITEM_CONF_item_behavior", {
  Name = "BAG_ITEM_CONF_item_behavior",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "use_action",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ItemBehavior"
        }
      },
      Description = "\228\189\191\231\148\168\230\151\182\231\154\132\232\161\140\228\184\186"
    },
    {
      Name = "ratio",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "BATTLE_PASS_THEME_CONF,id",
          EnumName = "use_action=IB_UNLOCK_BP_BASICS_SPECIFIC,BATTLE_PASS_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "BATTLE_PASS_THEME_CONF,id",
          EnumName = "use_action=IB_UNLOCK_BP_UPGRADE_SPECIFIC,BATTLE_PASS_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "SKILL_CONF,id",
          EnumName = "use_action=IB_CHANGE_BLOOD_FANTASTIC,PET_BLOOD_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "use_action",
          Branches = {
            {
              Value = 10,
              TypeName = "WORLD_MAP_AREA_GUIDE",
              FieldName = "id"
            },
            {
              Value = 13,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 14,
              TypeName = "TREASURE_ITEM_CONF",
              FieldName = "id"
            },
            {
              Value = 15,
              TypeName = "PET_BLOOD_CONF",
              FieldName = "id"
            },
            {
              Value = 16,
              TypeName = "BATTLE_PASS_GIFT_CONF",
              FieldName = "id"
            },
            {
              Value = 17,
              TypeName = "PET_EGG_CONF",
              FieldName = "id"
            },
            {
              Value = 19,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 20,
              TypeName = "TELEPORT_CONF",
              FieldName = "id"
            },
            {
              Value = 21,
              TypeName = "TASK_CONF",
              FieldName = "id"
            },
            {
              Value = 28,
              TypeName = "MEDAL_CONF",
              FieldName = "id"
            },
            {
              Value = 31,
              TypeName = "READ_CONF",
              FieldName = "id"
            },
            {
              Value = 33,
              TypeName = "NORMAL_SHOP_CONF",
              FieldName = "id"
            },
            {
              Value = 40,
              TypeName = "BEHAVIOR_CONF",
              FieldName = "id"
            },
            {
              Value = 42,
              TypeName = "LOTTERY_REWARD_CONF",
              FieldName = "id"
            },
            {
              Value = 43,
              TypeName = "EXCHANGE_CONF",
              FieldName = "id"
            },
            {
              Value = 44,
              TypeName = "ACTIVITY_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\161\140\228\184\186\229\143\130\230\149\176"
    },
    {
      Name = "ratio2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "use_action",
          Branches = {
            {
              Value = 15,
              TypeName = "PET_EVOLUTION_CONF",
              FieldName = "id"
            },
            {
              Value = 17,
              TypeName = "PET_RANDOM_EGG_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\161\140\228\184\186\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("BAG_ITEM_CONF_acquire_struct", {
  Name = "BAG_ITEM_CONF_acquire_struct",
  Version = 1,
  Description = "\233\129\147\229\133\183\232\142\183\229\143\150\233\128\148\229\190\132\231\154\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "acquire_way_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "acquisitiondesc01"
        }
      },
      Description = "\232\142\183\229\143\150\233\128\148\229\190\132\230\143\143\232\191\1761"
    },
    {
      Name = "behavior_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "BEHAVIOR_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\183\179\232\189\172ID1"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "CLIENT_PUBLIC_CMD",
          FieldName = "text"
        }
      },
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164"
    },
    {
      Name = "param1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\183\179\232\189\172\229\175\185\232\177\161\229\143\130\230\149\17611"
    },
    {
      Name = "param2",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActivityType"
        }
      },
      Description = "\232\183\179\232\189\172\229\175\185\232\177\161\229\143\130\230\149\17612"
    },
    {
      Name = "param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\175\185\232\177\161\229\143\130\230\149\17613"
    }
  }
})
RTTIManager:RegisterType("MAGIC_BASE_CONF_effect_struct", {
  Name = "MAGIC_BASE_CONF_effect_struct",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MagicEffect"
        }
      },
      Description = "\233\173\148\230\179\149\230\149\136\230\158\156"
    },
    {
      Name = "effect_params_1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "effect",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_AURA_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "MAGIC_TRANSFORM_CONF",
              FieldName = "id"
            },
            {
              Value = "ME_CREATE_MAGIC_MASSAGE",
              TypeName = "NPC_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\233\173\148\230\179\149\230\149\136\230\158\156\229\175\185\229\186\148\231\154\132\229\143\130\230\149\1761"
    },
    {
      Name = "effect_params_2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\173\148\230\179\149\230\149\136\230\158\156\229\175\185\229\186\148\231\154\132\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_accept_condition", {
  Name = "TASK_CONF_accept_condition",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "prerequisite"
        }
      },
      Description = "\228\187\187\229\138\161\230\142\165\229\143\150\230\157\161\228\187\182\230\143\143\232\191\176"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskAcceptConditionType"
        }
      },
      Description = "\230\142\165\229\143\150\228\187\187\229\138\161\230\137\128\233\156\128\230\157\161\228\187\182"
    },
    {
      Name = "data1",
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
              Value = 2,
              TypeName = "TASK_CONF",
              FieldName = "id"
            },
            {
              Value = 1,
              TypeName = "ROLE_EXP_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            },
            {
              Value = "TACT_FORCE_TASK",
              TypeName = "TASK_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "available_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\151\182\233\151\180\229\143\130\230\149\176"
    },
    {
      Name = "group_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\157\161\228\187\182\229\136\134\231\187\132"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_token_next_task", {
  Name = "TASK_CONF_token_next_task",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "next_task",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\188\134\229\141\176\229\144\142\231\187\173"
    },
    {
      Name = "token_required",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "TASK_TOKEN_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\156\128\230\177\130\230\188\134\229\141\176"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_accept_guide", {
  Name = "TASK_CONF_accept_guide",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskGuideType"
        }
      },
      Description = "\230\142\165\229\143\150\230\140\135\229\188\149\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\142\165\229\143\150\230\140\135\229\188\149\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\142\165\229\143\150\230\140\135\229\188\149\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_task_condition", {
  Name = "TASK_CONF_task_condition",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "text01"
        }
      },
      Description = "\228\187\187\229\138\161\229\174\140\230\136\144\230\157\161\228\187\182\230\143\143\232\191\176"
    },
    {
      Name = "des_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "des_text01"
        }
      },
      Description = "\228\187\187\229\138\161\232\191\155\232\161\140\228\184\173\230\143\143\232\191\176[\229\156\168\228\187\187\229\138\161\233\157\162\230\157\191\228\184\173\232\166\134\231\155\150\228\187\187\229\138\161\229\174\140\230\136\144\230\157\161\228\187\182\230\143\143\232\191\176\230\152\190\231\164\186\239\188\140\229\143\175\228\187\165\229\134\153\233\149\191\229\143\165]"
    },
    {
      Name = "done_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "done_text01"
        }
      },
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\174\140\230\136\144\229\144\142\230\143\143\232\191\176"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskKeyType"
        }
      },
      Description = "\228\187\187\229\138\161\229\174\140\230\136\144\230\157\161\228\187\182\239\188\154 ===================== TKT_WORLDCOMBAT_WIN: \229\164\167\228\184\150\231\149\140\230\136\152\230\150\151\232\131\156\229\136\169 ===================== <\229\133\182\229\174\131\230\157\161\228\187\182\229\143\130\230\149\176\232\167\163\233\135\138, \229\166\130\230\158\156\230\156\137>"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskKeyType",
          LinkFieldName = "data1"
        }
      },
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskKeyType",
          LinkFieldName = "data2"
        }
      },
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\143\130\230\149\1762"
    },
    {
      Name = "data3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskKeyType",
          LinkFieldName = "data3"
        }
      },
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\143\130\230\149\1763"
    },
    {
      Name = "data4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\143\130\230\149\1764"
    },
    {
      Name = "data5",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\143\130\230\149\1765"
    },
    {
      Name = "data6",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskKeyType",
          LinkFieldName = "data6"
        }
      },
      Description = "\228\187\187\229\138\161\230\157\161\228\187\182\229\143\130\230\149\1766"
    },
    {
      Name = "count",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\187\229\138\161\229\174\140\230\136\144\233\156\128\230\177\130\230\172\161\230\149\176"
    },
    {
      Name = "count_operate",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\157\161\228\187\182\232\174\161\230\149\176\230\150\185\229\188\143"
    },
    {
      Name = "count_reset_cycle",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStoreType"
        }
      },
      Description = "\230\172\161\230\149\176\233\135\141\231\189\174\229\145\168\230\156\159"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_go_guide", {
  Name = "TASK_CONF_go_guide",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskGoActionType"
        }
      },
      Description = "GO\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "\229\157\144\230\160\135x",
          EnumName = "type=TGAT_POINT_SET,SCENE_CONF",
          LinkFieldName = "\229\157\144\230\160\135y"
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 6,
              TypeName = "NPC_CONF",
              FieldName = "id"
            },
            {
              Value = 8,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 7,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 1,
              TypeName = "NPC_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "disable_force_track",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\133\179\233\151\173\229\188\186\229\136\182\232\191\189\232\184\170"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "CLIENT_PUBLIC_CMD",
          FieldName = "text"
        }
      },
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164"
    },
    {
      Name = "args",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\143\130\230\149\1761"
    },
    {
      Name = "args2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\229\143\130\230\149\1762"
    },
    {
      Name = "show_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "show_text01"
        }
      },
      Description = "\230\152\190\231\164\186\230\150\135\230\156\172"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_npc_option", {
  Name = "TASK_CONF_npc_option",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "option_id",
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
          TypeName = "NPC_OPTION_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\128\137\233\161\185ID"
    },
    {
      Name = "npc_cfg_id",
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
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\140\130\232\189\189npc\233\133\141\231\189\174ID"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_accept_action", {
  Name = "TASK_CONF_accept_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStateChangeActionType"
        }
      },
      Description = "\230\142\165\229\143\151\228\187\187\229\138\161\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data1"
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data2"
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\173\151\231\172\166\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_finish_action", {
  Name = "TASK_CONF_finish_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStateChangeActionType"
        }
      },
      Description = "\229\174\140\230\136\144\228\187\187\229\138\161\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data1"
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data2"
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\173\151\231\172\166\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_reward_action", {
  Name = "TASK_CONF_reward_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStateChangeActionType"
        }
      },
      Description = "\233\162\134\229\165\150\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data1"
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data2"
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\230\150\135\230\156\172"
    }
  }
})
RTTIManager:RegisterType("TASK_CONF_failed_action", {
  Name = "TASK_CONF_failed_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskStateChangeActionType"
        }
      },
      Description = "\230\148\190\229\188\131\228\187\187\229\138\161\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data1"
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "type",
          EnumName = "TaskStateChangeActionType",
          LinkFieldName = "data2"
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\173\151\231\172\166\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("ACTIVITY_CONF_reissue_reward_ignore", {
  Name = "ACTIVITY_CONF_reissue_reward_ignore",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "goods_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\229\137\148\233\153\164\231\154\132\233\129\147\229\133\183\231\177\187\229\158\139"
    },
    {
      Name = "goods_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "goods_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\229\137\148\233\153\164\231\154\132\233\129\147\229\133\183id"
    }
  }
})
RTTIManager:RegisterType("ACTIVITY_CONF_refresh_event_group", {
  Name = "ACTIVITY_CONF_refresh_event_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "refresh_content",
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
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\136\183\229\135\186content_id"
    },
    {
      Name = "start_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\183\229\135\186\230\137\167\232\161\140\230\151\182\233\151\180 \229\191\133\233\161\187\230\149\180\231\130\185!!!"
    },
    {
      Name = "delete_content",
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
          TypeName = "NPC_REFRESH_CONTENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\136\160\233\153\164content_id"
    },
    {
      Name = "end_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\136\160\233\153\164\230\137\167\232\161\140\230\151\182\233\151\180 \229\191\133\233\161\187\230\151\1691\231\167\146!!!\239\188\136\228\184\141\229\161\171\229\176\177\230\152\175\230\180\187\229\138\168\231\187\147\230\157\159\230\151\182\233\151\180\239\188\137"
    }
  }
})
RTTIManager:RegisterType("ACTIVITY_SPECIAL_TXT_CONF_explain_group", {
  Name = "ACTIVITY_SPECIAL_TXT_CONF_explain_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "txt",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "activityspecialtxt01"
        }
      },
      Description = "\230\150\135\230\156\1721"
    },
    {
      Name = "image_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\231\137\1351"
    }
  }
})
RTTIManager:RegisterType("AREA_CONF_pos", {
  Name = "AREA_CONF_pos",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "position_xyz",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\189\141\231\189\174\229\157\144\230\160\135"
    },
    {
      Name = "rotation_xyz",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\167\146\229\186\166"
    }
  }
})
RTTIManager:RegisterType("AREA_CONF_pos_empty", {
  Name = "AREA_CONF_pos_empty",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "position_xyz",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\189\141\231\189\174\229\157\144\230\160\135"
    },
    {
      Name = "rotation_xyz",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\167\146\229\186\166"
    }
  }
})
RTTIManager:RegisterType("BLOCK_CONF_spline_point", {
  Name = "BLOCK_CONF_spline_point",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "InputKey",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = ""
    },
    {
      Name = "Position",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = ""
    },
    {
      Name = "ArriveTangent",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = ""
    },
    {
      Name = "LeaveTangent",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = ""
    },
    {
      Name = "Rotation",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = ""
    },
    {
      Name = "Scale",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = ""
    },
    {
      Name = "Type",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = ""
    }
  }
})
RTTIManager:RegisterType("FUNCTION_BAN_CONF_function_ban_list", {
  Name = "FUNCTION_BAN_CONF_function_ban_list",
  Version = 1,
  Description = "\231\166\129\231\148\168\229\136\151\232\161\168\239\188\140\230\149\176\231\187\132\229\164\167\229\176\143\228\184\142\230\158\154\228\184\190PlayerFunctionBanType\228\184\128\232\135\180\239\188\140\230\140\137\231\133\167\230\158\154\228\184\190\233\161\186\229\186\143\231\166\129\231\148\168\239\188\155True\228\184\186\231\166\129\231\148\168\239\188\140False\228\184\186\228\184\141\231\166\129\231\148\168",
  Metadata = {},
  Fields = {
    {
      Name = "function_ban_switch",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\150\231\149\140\229\143\152\229\140\150\232\161\168\231\142\176\230\154\130\229\129\156(PFBT_WORLDCHANGE)"
    }
  }
})
RTTIManager:RegisterType("MAIL_CONF_reward_group", {
  Name = "MAIL_CONF_reward_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "goods_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\229\165\150\229\138\177\231\177\187\229\158\139"
    },
    {
      Name = "goods_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "goods_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\229\165\150\229\138\177id"
    },
    {
      Name = "goods_count",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\229\138\177\230\149\176\233\135\143"
    }
  }
})
RTTIManager:RegisterType("AREA_FUNC_CONF_area_bgm", {
  Name = "AREA_FUNC_CONF_area_bgm",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "start_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\232\181\183\229\167\139\230\184\184\230\136\143\230\151\182\233\151\180"
    },
    {
      Name = "end_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\187\147\230\157\159\230\184\184\230\136\143\230\151\182\233\151\180"
    },
    {
      Name = "switch",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "bgm\229\175\185\229\186\148\231\154\132state"
    }
  }
})
RTTIManager:RegisterType("AREA_FUNC_CONF_scene_effect", {
  Name = "AREA_FUNC_CONF_scene_effect",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "effect_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneEffect"
        }
      },
      Description = "\229\138\159\232\131\189\230\158\154\228\184\190\229\136\151\232\161\168"
    },
    {
      Name = "effect_param1",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\138\159\232\131\189\229\143\130\230\149\1761"
    },
    {
      Name = "effect_param2",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\138\159\232\131\189\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("REWARD_CONF_RewardItem", {
  Name = "REWARD_CONF_RewardItem",
  Version = 1,
  Description = "\230\142\137\232\144\189\233\161\185",
  Metadata = {},
  Fields = {
    {
      Name = "Type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\231\137\169\229\147\129\231\177\187\229\158\1391"
    },
    {
      Name = "Id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "Type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\229\165\150\229\138\177\231\137\169\229\147\129\230\151\182\239\188\140\231\137\169\229\147\129\231\154\132ID"
    },
    {
      Name = "Count",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\229\138\177\231\137\169\229\147\129\230\151\182\239\188\140\231\137\169\229\147\129\231\154\132\230\149\176\233\135\143"
    },
    {
      Name = "DropWeight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\154\143\230\156\186\230\157\131\233\135\141"
    },
    {
      Name = "DropWeight_change_conf",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "REWARD_WEIGHT_CHANGE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\157\131\233\135\141\232\176\131\230\149\180\232\167\132\229\136\153ID"
    }
  }
})
RTTIManager:RegisterType("SEASON_CONF_focus_group", {
  Name = "SEASON_CONF_focus_group",
  Version = 1,
  Description = "\230\139\141\232\132\184\229\155\190\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "focus_img_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\139\141\232\132\184\229\155\190\232\183\175\229\190\132"
    },
    {
      Name = "option_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\137\233\146\174\229\144\141\231\167\176"
    },
    {
      Name = "option_skip_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonFocusImgOptionType"
        }
      },
      Description = "\232\183\179\232\189\172\231\177\187\229\158\139"
    },
    {
      Name = "jump_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "option_skip_type",
          Branches = {
            {
              Value = 2,
              TypeName = "CLIENT_PUBLIC_CMD",
              FieldName = "text"
            }
          }
        }
      },
      Description = "\232\183\179\232\189\172param"
    },
    {
      Name = "param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164\229\143\130\230\149\1761"
    },
    {
      Name = "param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164\229\143\130\230\149\1762"
    },
    {
      Name = "param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\230\140\135\228\187\164\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("SEASON_ADVENTURE_CONF_reissue_reward_ignore", {
  Name = "SEASON_ADVENTURE_CONF_reissue_reward_ignore",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "goods_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\229\137\148\233\153\164\231\154\132\233\129\147\229\133\183\231\177\187\229\158\139"
    },
    {
      Name = "goods_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "goods_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\232\161\165\229\143\145\229\165\150\229\138\177\229\137\148\233\153\164\231\154\132\233\129\147\229\133\183id"
    }
  }
})
RTTIManager:RegisterType("PET_INFO_CONF_custom_glass", {
  Name = "PET_INFO_CONF_custom_glass",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "glass_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GlassType"
        }
      },
      Description = "\231\130\171\229\189\169\231\177\187\229\158\139"
    },
    {
      Name = "glass_param_1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "glass_type",
          Branches = {
            {
              Value = 1,
              TypeName = "COLOR_RANDOM_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "HIDDEN_GLASS_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\130\171\229\189\169\229\143\130\230\149\1761"
    },
    {
      Name = "glass_param_2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "glass_type",
          Branches = {
            {
              Value = 1,
              TypeName = "PARTICLE_RANDOM_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\130\171\229\189\169\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("BALL_CONF_extra_effect_group", {
  Name = "BALL_CONF_extra_effect_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "extra_effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BallExtraEffect"
        }
      },
      Description = "\231\144\131\231\167\141\231\154\132\233\153\132\229\138\160\230\149\136\230\158\156"
    },
    {
      Name = "extra_effect_param1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "extra_effect",
          Branches = {
            {
              Value = 1,
              TypeName = "PET_EVOLUTION_CONF",
              FieldName = "id"
            },
            {
              Value = 6,
              TypeName = "MEDAL_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\233\153\132\229\138\160\230\149\136\230\158\156\229\143\130\230\149\1761"
    },
    {
      Name = "extra_effect_param2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\153\132\229\138\160\230\149\136\230\158\156\229\143\130\230\149\1762"
    },
    {
      Name = "extra_effect_param3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\153\132\229\138\160\230\149\136\230\158\156\229\143\130\230\149\1763"
    },
    {
      Name = "extra_effect_param4",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\153\132\229\138\160\230\149\136\230\158\156\229\143\130\230\149\1764"
    }
  }
})
RTTIManager:RegisterType("GROW_LEVEL_CONF_require_item", {
  Name = "GROW_LEVEL_CONF_require_item",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "Type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\233\129\147\229\133\183\231\177\187\229\158\1391"
    },
    {
      Name = "require_item_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "Type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\233\129\147\229\133\183id1"
    },
    {
      Name = "require_item_count",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\129\147\229\133\183\230\149\176\233\135\1431"
    }
  }
})
RTTIManager:RegisterType("GROW_LEVEL_CONF_attr", {
  Name = "GROW_LEVEL_CONF_attr",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "attr_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "growattr01"
        }
      },
      Description = "\229\177\158\230\128\1671"
    },
    {
      Name = "attr_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AttributeType"
        }
      },
      Description = "\229\177\158\230\128\167\231\177\187\229\158\1391"
    },
    {
      Name = "attr_data",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\177\158\230\128\167\229\128\1881"
    }
  }
})
RTTIManager:RegisterType("INSPIRE_LEVEL_CONF_require_item", {
  Name = "INSPIRE_LEVEL_CONF_require_item",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "item_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\233\129\147\229\133\183\231\177\187\229\158\1391"
    },
    {
      Name = "item_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "item_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\233\129\147\229\133\183id1"
    },
    {
      Name = "item_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\129\147\229\133\183\230\149\176\233\135\1431"
    }
  }
})
RTTIManager:RegisterType("INSPIRE_LEVEL_CONF_attr", {
  Name = "INSPIRE_LEVEL_CONF_attr",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "attr_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AttributeType"
        }
      },
      Description = "\229\177\158\230\128\1671"
    },
    {
      Name = "attr_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\177\158\230\128\167\231\177\187\229\158\1391"
    },
    {
      Name = "attr_data",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\177\158\230\128\167\229\128\1881"
    }
  }
})
RTTIManager:RegisterType("LEVEL_SKILL_CONF_level", {
  Name = "LEVEL_SKILL_CONF_level",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "level_point",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\173\137\231\186\167\231\130\1851"
    },
    {
      Name = "stage",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\233\152\182\231\186\167"
    },
    {
      Name = "level_gain_skill",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\175\165\231\173\137\231\186\167\229\143\175\232\142\183\229\190\151\230\138\128\232\131\189\230\136\150\233\154\143\230\156\186\230\138\128\232\131\189"
    },
    {
      Name = "param",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "level_gain_skill",
          Branches = {
            {
              Value = 1,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "SKILL_RANDOM_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("LEVEL_SKILL_CONF_machine_skill_group", {
  Name = "LEVEL_SKILL_CONF_machine_skill_group",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "machine_skill_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\143\175\231\148\168\229\173\166\228\185\160\230\156\186\228\185\160\229\190\151\230\138\128\232\131\1891"
    },
    {
      Name = "machine_skill_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\175\231\148\168\229\173\166\228\185\160\230\156\186\228\185\160\229\190\151\229\144\141\231\167\1761"
    }
  }
})
RTTIManager:RegisterType("NATURE_CONF_random_desc", {
  Name = "NATURE_CONF_random_desc",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "nature_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\128\167\230\160\188\230\143\143\232\191\176id1"
    },
    {
      Name = "nature_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "description01"
        }
      },
      Description = "\230\128\167\230\160\188\230\143\143\232\191\176\230\150\135\230\156\1721"
    },
    {
      Name = "random_weight",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\143\230\156\186\230\157\131\233\135\1411"
    }
  }
})
RTTIManager:RegisterType("NATURE_CONF_morph_target_data", {
  Name = "NATURE_CONF_morph_target_data",
  Version = 1,
  Description = "morph\232\161\168\230\131\133\229\143\152\229\140\150\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "morph_target_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "target\229\144\141\231\167\176"
    },
    {
      Name = "morph_target_value",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\229\128\188\239\188\136\228\189\191\231\148\168\230\151\182\233\153\164\228\187\165100\239\188\137"
    }
  }
})
RTTIManager:RegisterType("PET_TALENT_CONF_condition_group", {
  Name = "PET_TALENT_CONF_condition_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "talent_condition",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetTalentCondition"
        }
      },
      Description = "\232\167\166\229\143\145\230\157\161\228\187\182"
    },
    {
      Name = "talent_condition_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\167\166\229\143\145\230\157\161\228\187\182\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("PET_TALENT_CONF_effect_group", {
  Name = "PET_TALENT_CONF_effect_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetTalentEffect"
        }
      },
      Description = "\231\137\185\233\149\191\230\149\136\230\158\156"
    },
    {
      Name = "effect_param",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "effect",
          Branches = {
            {
              Value = 1,
              TypeName = "PET_TALENT_CONF",
              FieldName = "id"
            },
            {
              Value = 207,
              TypeName = "BUFF_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\149\136\230\158\156\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("TEACH_CONF_guide_struct", {
  Name = "TEACH_CONF_guide_struct",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "bg",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\181\132\230\186\1441"
    },
    {
      Name = "title",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "teachtitle"
        }
      },
      Description = "\230\149\153\229\173\166\230\160\135\233\162\1521"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "teachtext"
        }
      },
      Description = "\230\149\153\229\173\166\229\134\133\229\174\1851"
    },
    {
      Name = "cmd",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\232\182\133\233\147\190"
    },
    {
      Name = "bg_PC",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "PC\232\181\132\230\186\1441"
    },
    {
      Name = "title_PC",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "teachtitle"
        }
      },
      Description = "PC\230\149\153\229\173\166\230\160\135\233\162\1521"
    },
    {
      Name = "text_PC",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "teachtext"
        }
      },
      Description = "PC\230\149\153\229\173\166\229\134\133\229\174\1851"
    },
    {
      Name = "cmd_PC",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\189\172\232\182\133\233\147\190"
    }
  }
})
RTTIManager:RegisterType("TEACH_CONF_unlock_conditions", {
  Name = "TEACH_CONF_unlock_conditions",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "unlock_condition",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TeachUnlockCondition"
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\182"
    },
    {
      Name = "unlock_condition_parameter",
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
          DriverField = "unlock_condition",
          Branches = {
            {
              Value = 3,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            },
            {
              Value = 7,
              TypeName = "PETBASE_CONF",
              FieldName = "id"
            },
            {
              Value = 18,
              TypeName = "ROLE_EXP_CONF",
              FieldName = "id"
            },
            {
              Value = 19,
              TypeName = "WORLD_LEVEL_CONF",
              FieldName = "id"
            },
            {
              Value = 27,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\167\163\233\148\129\230\157\161\228\187\182\229\143\130\230\149\176"
    },
    {
      Name = "unlock_group",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\230\157\161\228\187\182\229\136\134\231\187\132"
    },
    {
      Name = "priority",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\157\161\228\187\182\228\188\152\229\133\136\231\186\167"
    }
  }
})
RTTIManager:RegisterType("SHOP_CONF_goods", {
  Name = "SHOP_CONF_goods",
  Version = 1,
  Description = "\230\152\190\231\164\186\231\137\169\229\147\129\229\136\151\232\161\168",
  Metadata = {},
  Fields = {
    {
      Name = "goods_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\230\152\190\231\164\186\231\137\169\229\147\129\231\177\187\229\158\139"
    },
    {
      Name = "goods_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "goods_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\230\152\190\231\164\186\231\137\169\229\147\129id"
    }
  }
})
RTTIManager:RegisterType("SEASON_PART_CONF_change_group", {
  Name = "SEASON_PART_CONF_change_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "instead_start_time",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\166\134\231\155\150\230\151\182\233\151\180"
    },
    {
      Name = "instead_red_point_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "RED_POINT_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\166\134\231\155\150\231\154\132\231\186\162\231\130\185id"
    },
    {
      Name = "instead_item_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_ITEM_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\166\134\231\155\150\231\154\132item _id"
    }
  }
})
RTTIManager:RegisterType("SEASON_PVE_BASE_CONF_rule_show", {
  Name = "SEASON_PVE_BASE_CONF_rule_show",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
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
      Description = "\230\136\152\230\150\151\231\177\187\229\158\139"
    },
    {
      Name = "tab_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\161\181\231\173\190\229\144\141\231\167\176"
    },
    {
      Name = "season_battle_rule",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SEASON_BATTLE_RULE_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\175\141\230\157\161\229\186\147id(\231\149\140\233\157\162\229\177\149\231\164\186\231\148\168\239\188\137"
    }
  }
})
RTTIManager:RegisterType("BATTLE_CONF_npc_battle_list", {
  Name = "BATTLE_CONF_npc_battle_list",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "battle_model_1st",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\172\1721\228\189\141\230\149\140\230\150\185\232\174\173\231\187\131\229\184\136\229\189\162\232\177\161 (\233\133\141\231\189\17417\229\188\128\229\164\180\231\154\132NPCid)"
    },
    {
      Name = "is_uid",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\175\231\142\169\229\174\182\229\189\162\232\177\161\231\154\132uid"
    },
    {
      Name = "npc_title_1st",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "rivaltitle"
        }
      },
      Description = "\231\172\1721\228\189\141\230\149\140\230\150\185\232\174\173\231\187\131\229\184\136\231\167\176\229\143\183"
    },
    {
      Name = "pos1_1st",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\140\230\150\1851\229\143\183\228\189\141"
    },
    {
      Name = "pos2_1st",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\140\230\150\1852\229\143\183\228\189\141"
    },
    {
      Name = "pos3_1st",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\140\230\150\1853\229\143\183\228\189\141"
    },
    {
      Name = "pos4_1st",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\140\230\150\1854\229\143\183\228\189\141"
    },
    {
      Name = "pos5_1st",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\140\230\150\1855\229\143\183\228\189\141"
    },
    {
      Name = "pos6_1st",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\149\140\230\150\1856\229\143\183\228\189\141"
    },
    {
      Name = "ball1_1st",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID1"
    },
    {
      Name = "ball2_1st",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID2"
    },
    {
      Name = "ball3_1st",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID3"
    },
    {
      Name = "ball4_1st",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID4"
    },
    {
      Name = "ball5_1st",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID5"
    },
    {
      Name = "ball6_1st",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID6"
    },
    {
      Name = "npc_ai",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "NPC\232\161\140\228\184\186\230\160\145"
    },
    {
      Name = "ai_word_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AI_WORD_CONF",
          FieldName = "id"
        }
      },
      Description = "\233\166\150\229\155\158\229\144\136\230\154\151\231\164\186id"
    },
    {
      Name = "npc_location",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "NPC\228\189\141\231\189\174\229\157\144\230\160\135"
    },
    {
      Name = "nrc_ai_model",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NRCAiModel"
        }
      },
      Description = "\229\188\149\229\133\165\229\164\167\230\168\161\229\158\139AI\231\154\132\229\144\141\231\167\176"
    },
    {
      Name = "magic",
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
      Description = "\230\144\186\229\184\166\228\184\187\232\167\146\233\173\148\230\179\149"
    }
  }
})
RTTIManager:RegisterType("BATTLE_CONF_npc_battle_ally_list", {
  Name = "BATTLE_CONF_npc_battle_ally_list",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "battle_model_ally",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NPC_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\172\1722\228\189\141\229\138\169\230\136\152\232\174\173\231\187\131\229\184\136\229\189\162\232\177\161(\233\133\141\231\189\17417\229\188\128\229\164\180\231\154\132NPCid)"
    },
    {
      Name = "npc_title_ally",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\172\1722\228\189\141\229\138\169\230\136\152\232\174\173\231\187\131\229\184\136\231\167\176\229\143\183"
    },
    {
      Name = "pos1_1st_ally",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\1521\229\143\183\228\189\141"
    },
    {
      Name = "pos2_1st_ally",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\1522\229\143\183\228\189\141"
    },
    {
      Name = "pos3_1st_ally",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\1523\229\143\183\228\189\141"
    },
    {
      Name = "pos4_1st_ally",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\1524\229\143\183\228\189\141"
    },
    {
      Name = "pos5_1st_ally",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\1525\229\143\183\228\189\141"
    },
    {
      Name = "pos6_1st_ally",
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
          TypeName = "MONSTER_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\169\230\136\1526\229\143\183\228\189\141"
    },
    {
      Name = "ball1_1st_ally",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID1"
    },
    {
      Name = "ball2_1st_ally",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID2"
    },
    {
      Name = "ball3_1st_ally",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID3"
    },
    {
      Name = "ball4_1st_ally",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID4"
    },
    {
      Name = "ball5_1st_ally",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID5"
    },
    {
      Name = "ball6_1st_ally",
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
      Description = "\230\128\170\231\137\169\229\175\185\229\186\148\229\146\149\229\153\156\231\144\131ID6"
    },
    {
      Name = "npc_ai_ally",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "NPC\232\161\140\228\184\186\230\160\145"
    }
  }
})
RTTIManager:RegisterType("BUFF_CONF_buff_group_reduce", {
  Name = "BUFF_CONF_buff_group_reduce",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "reduce_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BuffReduceType"
        }
      },
      Description = "buff\231\187\132\229\177\130\230\149\176\229\137\138\229\135\143\231\177\187\229\158\139 BRT_LAYER_ROUND\231\177\187\229\158\139\229\143\170\232\131\189\231\139\172\231\171\139\228\189\191\231\148\168,\229\143\130\230\149\176\228\187\163\232\161\168x\229\155\158\229\144\136\229\144\142\231\167\187\233\153\1641\229\177\130"
    },
    {
      Name = "reduce_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_LENGTH,
          Ranges = {
            {Min = 0, Max = 2}
          }
        }
      },
      Description = "buff\231\187\132\229\137\138\229\135\143\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("BUFFBASE_CONF_buffbase_param", {
  Name = "BUFFBASE_CONF_buffbase_param",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "params",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        }
      },
      Description = "\230\149\136\230\158\156\229\143\130\230\149\1761"
    }
  }
})
RTTIManager:RegisterType("MONSTER_CONF_custom_glass", {
  Name = "MONSTER_CONF_custom_glass",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "glass_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GlassType"
        }
      },
      Description = "\231\130\171\229\189\169\231\177\187\229\158\139"
    },
    {
      Name = "glass_param_1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "glass_type",
          Branches = {
            {
              Value = 1,
              TypeName = "COLOR_RANDOM_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "HIDDEN_GLASS_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\130\171\229\189\169\229\143\130\230\149\1761"
    },
    {
      Name = "glass_param_2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "glass_type",
          Branches = {
            {
              Value = 1,
              TypeName = "PARTICLE_RANDOM_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\130\171\229\189\169\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("MONSTER_CONF_monster_carry_on", {
  Name = "MONSTER_CONF_monster_carry_on",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "carry_on_item",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_CARRYON_ITEM",
          FieldName = "id"
        }
      },
      Description = "\230\128\170\231\137\169\230\144\186\229\184\166\230\140\129\230\156\137\231\137\1691"
    },
    {
      Name = "carry_on_item_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\144\186\229\184\166\231\154\132\230\140\129\230\156\137\231\137\169\231\173\137\231\186\167"
    },
    {
      Name = "carry_on_item_stage",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\144\186\229\184\166\231\154\132\230\140\129\230\156\137\231\137\169\233\152\182\231\186\167"
    }
  }
})
RTTIManager:RegisterType("MONSTER_SKILLBANK_CONF_level", {
  Name = "MONSTER_SKILLBANK_CONF_level",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "level_limit",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\173\137\231\186\167\228\184\138\233\153\1441"
    },
    {
      Name = "is_random",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Server,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\233\154\143\230\156\186\230\138\128\232\131\189"
    },
    {
      Name = "skill_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SKILL_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\138\128\232\131\189id1"
    }
  }
})
RTTIManager:RegisterType("WORLD_LEVEL_CONF_promote_desc", {
  Name = "WORLD_LEVEL_CONF_promote_desc",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\155\190\230\160\1351"
    },
    {
      Name = "promote_text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\150\135\230\156\172\230\143\143\232\191\1761"
    },
    {
      Name = "value",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\229\128\1881"
    }
  }
})
RTTIManager:RegisterType("WORLD_LEVEL_CONF_revival_desc", {
  Name = "WORLD_LEVEL_CONF_revival_desc",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "up_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\172\1721\230\157\161\230\143\143\232\191\176icon"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\172\1721\230\157\161\229\143\152\229\140\150\230\143\143\232\191\176"
    },
    {
      Name = "upvalue",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\149\176\229\128\1881"
    }
  }
})
RTTIManager:RegisterType("WORLD_LEVEL_CONF_reward", {
  Name = "WORLD_LEVEL_CONF_reward",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "level_reward_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\229\165\150\229\138\177\233\129\147\229\133\183\231\177\187\229\158\139"
    },
    {
      Name = "level_reward_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "level_reward_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\233\129\147\229\133\183\229\143\130\230\149\176ID"
    },
    {
      Name = "level_reward_count",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\129\147\229\133\183\230\149\176\233\135\143"
    }
  }
})
RTTIManager:RegisterType("WORLD_LEVEL_CONF_team_battle", {
  Name = "WORLD_LEVEL_CONF_team_battle",
  Version = 1,
  Description = "\232\138\177\231\167\141\233\154\190\229\186\166\233\133\141\231\189\174",
  Metadata = {},
  Fields = {
    {
      Name = "battle_star_rule",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TeamBattleStarRule"
        }
      },
      Description = "\232\138\177\231\167\141\230\152\159\231\186\167\232\174\161\231\174\151\232\167\132\229\136\153"
    },
    {
      Name = "battle_star",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\138\177\231\167\141\230\152\159\231\186\167"
    },
    {
      Name = "create_weight",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\173\164\230\152\159\231\186\167\232\138\177\231\167\141\230\157\131\233\135\141"
    }
  }
})
RTTIManager:RegisterType("SPE_REFRESH_TRIG_CONF_event_result", {
  Name = "SPE_REFRESH_TRIG_CONF_event_result",
  Version = 1,
  Description = "\228\186\139\228\187\182\231\187\147\230\158\156\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "event_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "EventResultType"
        }
      },
      Description = "\228\186\139\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "event_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "NPC_CONF,id",
          EnumName = "event_type=ERT_CREAT_CONTENT,AREA_GROUP_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "AREA_FUNC_CONF,enum",
          EnumName = "event_type=ERT_CHANGE_WEATHER,WeatherType",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "OWL_CONTENT_NPC_CONF,id",
          EnumName = "event_type=ERT_CREAT_NEAREST_CONTENT,AREA_GROUP_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "event_type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 8,
              TypeName = "ACTIVITY_SPEC_FLOWER_SEED_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\228\186\139\228\187\182\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("SEASON_TIPS_TAB_CONF_tab_group", {
  Name = "SEASON_TIPS_TAB_CONF_tab_group",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "page_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SeasonTipsPageType"
        }
      },
      Description = "\229\136\134\233\161\181\231\177\187\229\158\139"
    },
    {
      Name = "page_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\233\161\181id"
    },
    {
      Name = "page_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "seasontabname01"
        }
      },
      Description = "\229\136\134\233\161\181\230\160\135\233\162\152"
    },
    {
      Name = "page_icon_select",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\233\161\181icon_\233\128\137\228\184\173"
    },
    {
      Name = "page_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\136\134\233\161\181icon"
    }
  }
})
RTTIManager:RegisterType("TASK_SWITCH_CONF_switch_condition", {
  Name = "TASK_SWITCH_CONF_switch_condition",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "condition_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskSwitchCondition"
        }
      },
      Description = "\229\188\128\229\133\179\229\143\152\230\155\180\230\157\161\228\187\182[1]"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "condition_type",
          Branches = {
            {
              Value = 1,
              TypeName = "TASK_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\157\161\228\187\182[1]\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("DIALOGUE_CONF_actor_perform", {
  Name = "DIALOGUE_CONF_actor_perform",
  Version = 1,
  Description = "\232\161\168\230\188\148\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "actor",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\168\230\188\148\232\128\133"
    },
    {
      Name = "transform",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\141\231\189\174\239\188\134\230\151\139\232\189\172"
    },
    {
      Name = "move_action",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "MoveActionType"
        }
      },
      Description = "\231\167\187\229\138\168\230\150\185\229\188\143"
    },
    {
      Name = "body_turn_to",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\186\171\228\189\147\230\156\157\229\144\145"
    },
    {
      Name = "turn_to",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\180\230\156\157\229\144\145"
    },
    {
      Name = "eye_turn_to",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\156\188\231\157\155\230\156\157\229\144\145"
    },
    {
      Name = "action",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\168\228\189\156"
    },
    {
      Name = "emotion",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "EmotionType"
        }
      },
      Description = "\230\131\133\231\187\170\232\190\133\229\138\169"
    },
    {
      Name = "shakehead",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "HeadMotion"
        }
      },
      Description = "\231\130\185\229\164\180\230\145\135\229\164\180"
    },
    {
      Name = "hidden_switch",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\140\191\232\184\170(1:\232\167\163\233\153\164,2:\232\191\155\229\133\165)"
    },
    {
      Name = "reveal_switch",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\146\232\137\178\229\143\175\232\167\129\230\128\167(1:\230\152\190\231\164\186,2:\233\154\144\232\151\143)"
    }
  }
})
RTTIManager:RegisterType("DIALOGUE_CONF_action", {
  Name = "DIALOGUE_CONF_action",
  Version = 1,
  Description = "action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137",
  Metadata = {},
  Fields = {
    {
      Name = "action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionType"
        }
      },
      Description = "Action\231\177\187\229\158\139"
    },
    {
      Name = "action_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param1"
        }
      },
      Description = "action\229\143\130\230\149\1761"
    },
    {
      Name = "action_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param2"
        }
      },
      Description = "action\229\143\130\230\149\1762"
    },
    {
      Name = "action_param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param3"
        }
      },
      Description = "action\229\143\130\230\149\1763"
    },
    {
      Name = "action_param4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param4"
        }
      },
      Description = "action\229\143\130\230\149\1764"
    },
    {
      Name = "success_dialogue",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\231\153\189\228\184\173\232\161\140\228\184\186\230\136\144\229\138\159\230\151\182\239\188\140\228\184\139\228\184\128\229\143\165\229\175\185\231\153\189id"
    },
    {
      Name = "failure_dialogue",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\175\185\231\153\189\228\184\173\232\161\140\228\184\186\229\164\177\232\180\165\230\151\182\239\188\140\228\184\139\228\184\128\229\143\165\229\175\185\231\153\189id"
    }
  }
})
RTTIManager:RegisterType("NPC_REACTION_CONF_reaction_conf", {
  Name = "NPC_REACTION_CONF_reaction_conf",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "npc_dialog_id",
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
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "npc\229\175\185\231\153\1891"
    },
    {
      Name = "npc_dialog_id_awesome",
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
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\186\134\228\184\141\232\181\183\229\164\169\228\187\189\229\175\185\231\153\1891"
    },
    {
      Name = "npc_dialog_id_rainbow",
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
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\130\171\229\189\169\229\175\185\231\153\1891"
    },
    {
      Name = "npc_dialog_id_alterchromo",
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
          TypeName = "DIALOGUE_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\188\130\232\137\178\229\175\185\231\153\1891"
    },
    {
      Name = "npc_anim",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "ANIM_ID_CONF",
          FieldName = "id"
        }
      },
      Description = "npc\229\138\168\228\189\1561"
    }
  }
})
RTTIManager:RegisterType("NPC_AURA_CONF_aura_effect", {
  Name = "NPC_AURA_CONF_aura_effect",
  Version = 1,
  Description = "\229\133\137\231\142\175\230\149\136\230\158\156\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137",
  Metadata = {},
  Fields = {
    {
      Name = "aura_effect_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AuraEffect"
        }
      },
      Description = "\229\133\137\231\142\175\230\149\136\230\158\156\231\177\187\229\158\139"
    },
    {
      Name = "params",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "aura_effect_type",
          Branches = {
            {
              Value = 1,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 10009,
              TypeName = "WORLD_BUFF_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\149\136\230\158\156\229\143\130\230\149\1761"
    }
  }
})
RTTIManager:RegisterType("NPC_OPTION_CONF_action", {
  Name = "NPC_OPTION_CONF_action",
  Version = 1,
  Description = "\231\142\169\229\174\182\228\186\164\228\186\146action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137",
  Metadata = {},
  Fields = {
    {
      Name = "action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionType"
        }
      },
      Description = "Action\231\177\187\229\158\139"
    },
    {
      Name = "action_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param1"
        }
      },
      Description = "action\229\143\130\230\149\1761"
    },
    {
      Name = "action_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param2"
        }
      },
      Description = "action\229\143\130\230\149\1762"
    },
    {
      Name = "action_param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param3"
        }
      },
      Description = "action\229\143\130\230\149\1763"
    },
    {
      Name = "action_param4",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param4"
        }
      },
      Description = "action\229\143\130\230\149\1764"
    },
    {
      Name = "action_param5",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "action\229\143\130\230\149\1765"
    }
  }
})
RTTIManager:RegisterType("NPC_OPTION_CONF_pet_action", {
  Name = "NPC_OPTION_CONF_pet_action",
  Version = 1,
  Description = "\229\174\160\231\137\169\228\186\164\228\186\146Action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137",
  Metadata = {},
  Fields = {
    {
      Name = "action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionType"
        }
      },
      Description = "Action\231\177\187\229\158\139"
    },
    {
      Name = "action_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param1"
        }
      },
      Description = "action\229\143\130\230\149\1761"
    },
    {
      Name = "action_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param2"
        }
      },
      Description = "action\229\143\130\230\149\1762"
    },
    {
      Name = "action_param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param3"
        }
      },
      Description = "action\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("NPC_OPTION_CONF_pet_power_dash_action", {
  Name = "NPC_OPTION_CONF_pet_power_dash_action",
  Version = 1,
  Description = "\229\174\160\231\137\169\229\134\178\230\146\158\228\186\164\228\186\146Action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137",
  Metadata = {},
  Fields = {
    {
      Name = "action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionType"
        }
      },
      Description = "Action\231\177\187\229\158\139"
    },
    {
      Name = "action_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param1"
        }
      },
      Description = "action\229\143\130\230\149\1761"
    },
    {
      Name = "action_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param2"
        }
      },
      Description = "action\229\143\130\230\149\1762"
    },
    {
      Name = "action_param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param3"
        }
      },
      Description = "action\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("NPC_OPTION_CONF_wild_action", {
  Name = "NPC_OPTION_CONF_wild_action",
  Version = 1,
  Description = "\233\135\142\229\164\150\231\178\190\231\129\181\228\186\164\228\186\146Action\231\187\147\230\158\132\228\189\147\229\174\154\228\185\137",
  Metadata = {},
  Fields = {
    {
      Name = "action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionType"
        }
      },
      Description = "Action\231\177\187\229\158\139"
    },
    {
      Name = "action_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param1"
        }
      },
      Description = "action\229\143\130\230\149\1761"
    },
    {
      Name = "action_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param2"
        }
      },
      Description = "action\229\143\130\230\149\1762"
    },
    {
      Name = "action_param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param3"
        }
      },
      Description = "action\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("MAGIC_INTERACT_CONF_action_struct", {
  Name = "MAGIC_INTERACT_CONF_action_struct",
  Version = 1,
  Description = "action\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
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
      Description = "\233\173\148\230\179\149id"
    },
    {
      Name = "magic_charge_level",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\173\148\230\179\149\232\147\132\229\138\155\231\173\137\231\186\167"
    },
    {
      Name = "angle_effective_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "ACTION\232\167\146\229\186\166\231\148\159\230\149\136\231\187\132\229\136\171"
    },
    {
      Name = "horizontal_effective_angle",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "Action\230\176\180\229\185\179\231\148\159\230\149\136\232\167\146\229\186\166"
    },
    {
      Name = "z_axis_effective_angle",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "ActionZ\232\189\180\231\148\159\230\149\136\232\167\146\229\186\166"
    },
    {
      Name = "action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionType"
        }
      },
      Description = "Action\231\177\187\229\158\1391"
    },
    {
      Name = "action_param1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param1"
        }
      },
      Description = "action\229\143\130\230\149\1761"
    },
    {
      Name = "action_param2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param2"
        }
      },
      Description = "action\229\143\130\230\149\1762"
    },
    {
      Name = "action_param3",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "action_type",
          EnumName = "ActionType",
          LinkFieldName = "param3"
        }
      },
      Description = "action\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("WEATHER_CONF_tod_param", {
  Name = "WEATHER_CONF_tod_param",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "available_time_enum",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "RefreshTimeConf"
        }
      },
      Description = "tod\230\158\154\228\184\190"
    },
    {
      Name = "field_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SkillDamType"
        }
      },
      Description = "\229\138\191\232\131\189\231\177\187\229\158\139"
    },
    {
      Name = "field_layer",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\138\191\232\131\189\229\177\130\230\149\176"
    },
    {
      Name = "des",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "weathername2"
        }
      },
      Description = "\230\143\143\232\191\176\239\188\136\231\137\185\230\174\138\229\173\151\231\172\166\229\188\149\231\148\168\239\188\137"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_GROUP_INFO_CONF_behavior_group", {
  Name = "NRC_AI_GROUP_INFO_CONF_behavior_group",
  Version = 1,
  Description = "\231\138\182\230\128\129\229\175\185\229\186\148\232\161\140\228\184\186\231\187\132",
  Metadata = {},
  Fields = {
    {
      Name = "state_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_FSM_STATE_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\138\182\230\128\129ID"
    },
    {
      Name = "behavior_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_BEHAVIOR_GROUP_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\161\140\228\184\186\231\187\132 ID"
    },
    {
      Name = "cond_ids",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\135\186\229\186\166\230\157\161\228\187\182"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_FSM_STATE_CONF_fsm_state", {
  Name = "NRC_AI_FSM_STATE_CONF_fsm_state",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "next_state_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_FSM_STATE_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\184\139\228\184\128\228\184\170\231\138\182\230\128\129id "
    },
    {
      Name = "state_cond_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_AI_FSM_COND_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\138\182\230\128\129\229\136\135\230\141\162\230\157\161\228\187\182ID"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_PERFORM_POOL_CONF_ai_group_param_1", {
  Name = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_1",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_PERFORM_POOL_CONF_ai_group_param_2", {
  Name = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_2",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_PERFORM_POOL_CONF_ai_group_param_3", {
  Name = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_3",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_PERFORM_POOL_CONF_ai_group_param_4", {
  Name = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_4",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_PERFORM_POOL_CONF_ai_group_param_5", {
  Name = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_5",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_PERFORM_POOL_CONF_ai_group_param_6", {
  Name = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_6",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_GROUP_AI_BASIC_INFO_CONF_event_array", {
  Name = "NRC_GROUP_AI_BASIC_INFO_CONF_event_array",
  Version = 1,
  Description = "\228\186\139\228\187\182\230\149\176\231\187\132",
  Metadata = {},
  Fields = {
    {
      Name = "event_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_EVENT_CONF",
          FieldName = "id"
        }
      },
      Description = "\228\186\139\228\187\182ID"
    },
    {
      Name = "abort_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIEventAbortType"
        }
      },
      Description = "\228\186\139\228\187\182\228\184\173\230\150\173\230\150\185\229\188\143"
    },
    {
      Name = "group_behavior_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BEHAVIOR_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\190\164\232\144\189\232\161\140\228\184\186ID"
    },
    {
      Name = "group_station_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_STATION_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\190\164\232\144\189\231\171\153\228\189\141ID"
    },
    {
      Name = "auto_destroy",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\229\138\168\232\167\163\230\149\163"
    },
    {
      Name = "lock_fsm",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\148\129\229\174\154FSM\230\181\129\232\189\172"
    }
  }
})
RTTIManager:RegisterType("PETBASE_CONF_evolution_need", {
  Name = "PETBASE_CONF_evolution_need",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "evolution_need_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PetEvolutionCondition"
        }
      },
      Description = "\232\191\155\229\140\150\229\136\176\232\191\153\228\184\170\229\189\162\230\128\129\233\156\128\230\177\130\230\157\161\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "evolution_need_data1",
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
          DriverField = "evolution_need_type",
          Branches = {
            {
              Value = 13,
              TypeName = "PET_BLOOD_CONF",
              FieldName = "id"
            },
            {
              Value = 16,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 18,
              TypeName = "PETBASE_CONF",
              FieldName = "id"
            },
            {
              Value = 19,
              TypeName = "NPC_CONF",
              FieldName = "id"
            },
            {
              Value = 20,
              TypeName = "NPC_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\173\164\230\157\161\228\187\182\230\137\128\233\156\128\231\154\132\229\143\130\230\149\1761"
    },
    {
      Name = "evolution_need_data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\230\173\164\230\157\161\228\187\182\230\137\128\233\156\128\231\154\132\229\143\130\230\149\1762"
    }
  }
})
RTTIManager:RegisterType("PETBASE_CONF_evolution_need_items", {
  Name = "PETBASE_CONF_evolution_need_items",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "evolution_need_item",
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
      Description = "\232\191\155\229\140\150\229\136\176\232\191\153\228\184\170\229\189\162\230\128\129\233\156\128\230\177\130\233\129\147\229\133\183"
    },
    {
      Name = "number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\156\128\230\177\130\230\149\176\233\135\143"
    }
  }
})
RTTIManager:RegisterType("PETBASE_CONF_evolution_reward_items", {
  Name = "PETBASE_CONF_evolution_reward_items",
  Version = 1,
  Description = "\232\191\155\229\140\150\232\181\160\233\128\129\233\129\147\229\133\183\231\187\132",
  Metadata = {},
  Fields = {
    {
      Name = "evolution_reward_item",
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
      Description = "\232\191\155\229\140\150\232\181\160\233\128\129\233\129\147\229\133\183ID"
    },
    {
      Name = "reward_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\191\155\229\140\150\232\181\160\233\128\129\233\129\147\229\133\183\230\149\176\233\135\143"
    }
  }
})
RTTIManager:RegisterType("BREAK_REWARD_CONF_break_award", {
  Name = "BREAK_REWARD_CONF_break_award",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "break_level_point",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\170\129\231\160\180\231\173\137\231\186\167\231\130\1851"
    },
    {
      Name = "break_attribute_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AttributeType"
        }
      },
      Description = "\231\170\129\231\160\180\229\177\158\230\128\167\231\167\141\231\177\187"
    },
    {
      Name = "break_attribute_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\170\129\231\160\180\229\177\158\230\128\167\230\143\144\229\141\135"
    },
    {
      Name = "is_slot_add",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\162\158\229\138\160\230\140\129\230\156\137\231\137\169\230\160\143\228\189\141"
    }
  }
})
RTTIManager:RegisterType("PET_BEHAVIOR_REACTION_CONF_reaction_random", {
  Name = "PET_BEHAVIOR_REACTION_CONF_reaction_random",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "behavior_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "ROLEPLAY_BEHAVIOR_CONF",
          FieldName = "id"
        }
      },
      Description = "\227\128\144\229\186\159\229\188\131\227\128\145\231\142\169\229\174\182\232\161\140\228\184\1861"
    },
    {
      Name = "behavior_ids",
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
          TypeName = "ROLEPLAY_BEHAVIOR_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\140\185\233\133\141\231\142\169\229\174\182\232\161\140\228\184\186"
    },
    {
      Name = "reaction_ai",
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
          TypeName = "NRC_AI_BEHAVIOR_GROUP_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\178\190\231\129\181\229\143\141\229\186\148"
    },
    {
      Name = "weight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\157\131\233\135\141"
    },
    {
      Name = "home_reaction_ai",
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
          TypeName = "NRC_AI_BEHAVIOR_GROUP_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\174\182\229\155\173AI\231\178\190\231\129\181\229\143\141\229\186\148"
    },
    {
      Name = "home_reaction_weight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\174\182\229\155\173AI\231\178\190\231\129\181\229\143\141\229\186\148\230\157\131\233\135\141"
    },
    {
      Name = "friend_reaction_fix_value",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\165\189\229\143\139\232\174\191\229\174\162_\229\143\139\229\165\189\229\186\166\228\191\174\230\173\163\229\128\188"
    },
    {
      Name = "stranger_reaction_fix_value",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\153\140\231\148\159\228\186\186\232\174\191\229\174\162_\229\143\139\229\165\189\229\186\166\228\191\174\230\173\163\229\128\188"
    }
  }
})
RTTIManager:RegisterType("PET_BOND_bond_random", {
  Name = "PET_BOND_bond_random",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ActionResultType"
        }
      },
      Description = "\231\177\187\229\158\1391"
    },
    {
      Name = "weight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\154\143\230\156\186\230\157\131\233\135\141"
    },
    {
      Name = "required_interact_count",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\186\146\229\138\168x\230\172\161\229\144\142\232\191\155\229\133\165\233\154\143\230\156\186\230\177\160"
    }
  }
})
RTTIManager:RegisterType("PET_BOND_find_random", {
  Name = "PET_BOND_find_random",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "find_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ClientNpcType"
        }
      },
      Description = "\231\177\187\229\158\1391"
    },
    {
      Name = "find_weight",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\233\154\143\230\156\186\230\157\131\233\135\141"
    },
    {
      Name = "required_interact_count",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\228\186\146\229\138\168x\230\172\161\229\144\142\232\191\155\229\133\165\233\154\143\230\156\186\230\177\160"
    }
  }
})
RTTIManager:RegisterType("PET_EVOLUTION_CONF_evolution_chain", {
  Name = "PET_EVOLUTION_CONF_evolution_chain",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "petbase_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PETBASE_CONF",
          FieldName = "id"
        }
      },
      Description = "petbase\231\154\132id"
    },
    {
      Name = "pet_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "petname01"
        }
      },
      Description = "\231\178\190\231\129\181\229\144\141\231\167\176"
    },
    {
      Name = "stage",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\232\191\155\229\140\150\233\152\182\231\186\167"
    },
    {
      Name = "level",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "PET_LEVEL_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\191\155\229\140\150\231\173\137\231\186\167"
    },
    {
      Name = "unit_type",
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
          EnumName = "SkillDamType"
        }
      },
      Description = "\231\178\190\231\129\181\231\179\187\229\136\171"
    }
  }
})
RTTIManager:RegisterType("PET_HABIT_CONF_habit_ability", {
  Name = "PET_HABIT_CONF_habit_ability",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ability_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "HabitAbilityType"
        }
      },
      Description = "\228\185\160\230\128\167\231\154\132\232\131\189\229\138\155\229\138\160\230\136\144\231\177\187\229\158\139"
    },
    {
      Name = "ability_param1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "ability_type",
          Branches = {
            {
              Value = 1,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\131\189\229\138\155\229\138\160\230\136\144\229\143\130\230\149\1761"
    },
    {
      Name = "ability_param2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "ability_type",
          Branches = {
            {
              Value = 3,
              TypeName = "SKILL_CONF",
              FieldName = "id"
            },
            {
              Value = 6,
              TypeName = "BUFF_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\131\189\229\138\155\229\138\160\230\136\144\229\143\130\230\149\1762"
    },
    {
      Name = "ability_param3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\131\189\229\138\155\229\138\160\230\136\144\229\143\130\230\149\1763"
    },
    {
      Name = "ability_param4",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\131\189\229\138\155\229\138\160\230\136\144\229\143\130\230\149\1764"
    }
  }
})
RTTIManager:RegisterType("SKILL_CONF_skill_result", {
  Name = "SKILL_CONF_skill_result",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "effect_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\153\132\229\138\160\231\154\132buff\231\187\132\230\136\150effect\231\154\132ID"
    },
    {
      Name = "result_target_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "ResultTargetType"
        }
      },
      Description = "\230\138\128\232\131\189\230\149\136\230\158\156\231\155\174\230\160\135\231\177\187\229\158\139 1=\230\150\189\230\179\149\232\128\133 2=\228\184\187\231\155\174\230\160\135+\233\157\158\228\184\187\231\155\174\230\160\135 3=\229\133\168\228\189\147\229\143\139\230\150\185 4=\229\133\168\228\189\147\230\149\140\230\150\185"
    },
    {
      Name = "cast_moment",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "Buffbasetrigger_type"
        }
      },
      Description = "\233\153\132\229\138\160\230\149\136\230\158\156\230\151\182\233\151\180\231\130\185 1=\230\148\187\229\135\187\229\137\141 2=\230\148\187\229\135\187\229\144\142"
    },
    {
      Name = "success_rate",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\153\132\229\138\160\230\136\144\229\138\159\231\142\135=\233\133\141\231\189\174\229\128\188/10000"
    },
    {
      Name = "buff_level_rule",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BuffLevelRule"
        }
      },
      Description = "buff\229\177\130\230\149\176\232\167\132\229\136\153"
    },
    {
      Name = "buff_group_level",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "buff\231\187\132\229\177\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("WORLD_MAP_CONF_npcicon_levelup", {
  Name = "WORLD_MAP_CONF_npcicon_levelup",
  Version = 1,
  Description = "\229\141\135\231\186\167\229\144\142\239\188\140\231\189\151\231\155\152\230\136\150\229\186\149\229\155\190\228\184\138\229\175\185\229\186\148\229\155\190\230\160\135",
  Metadata = {},
  Fields = {
    {
      Name = "level",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\173\137\231\186\167"
    },
    {
      Name = "icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\175\185\229\186\148icon"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_CONF_require_cond", {
  Name = "DUNGEON_CONF_require_cond",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "is_consume",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\182\136\232\128\151\233\129\147\229\133\183"
    },
    {
      Name = "require_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "TaskAcceptConditionType"
        }
      },
      Description = "\230\137\128\233\156\128\230\157\161\228\187\182"
    },
    {
      Name = "require_data",
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
          DriverField = "require_type",
          Branches = {
            {
              Value = 2,
              TypeName = "TASK_CONF",
              FieldName = "id"
            },
            {
              Value = 1,
              TypeName = "ROLE_EXP_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            },
            {
              Value = "TACT_FORCE_TASK",
              TypeName = "TASK_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_CONF_show_reward", {
  Name = "DUNGEON_CONF_show_reward",
  Version = 1,
  Description = "\229\177\149\231\164\186\231\148\168\229\165\150\229\138\177",
  Metadata = {},
  Fields = {
    {
      Name = "reward_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GoodsType"
        }
      },
      Description = "\229\165\150\229\138\177\231\177\187\229\158\1391"
    },
    {
      Name = "reward_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "reward_type",
          EnumName = "GoodsType",
          LinkFieldName = "param_id"
        }
      },
      Description = "\229\165\150\229\138\177id"
    },
    {
      Name = "reward_count",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\165\150\229\138\177\230\149\176\233\135\143"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_CONF_collection", {
  Name = "DUNGEON_CONF_collection",
  Version = 1,
  Description = "\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142",
  Metadata = {},
  Fields = {
    {
      Name = "collect_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "DungeonCollectionType"
        }
      },
      Description = "\230\148\182\233\155\134\231\137\169\231\177\187\229\158\1391"
    },
    {
      Name = "collect_content_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "collect_type",
          Branches = {
            {
              Value = "DCT_TREASURE_BOX",
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\148\182\233\155\134\231\137\169ContentID"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_STAGE_start_condition", {
  Name = "DUNGEON_STAGE_start_condition",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StageConditionType"
        }
      },
      Description = "\229\188\128\229\144\175\230\157\161\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 1,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "BATTLE_CONF",
              FieldName = "id"
            },
            {
              Value = 5,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "DUNGEON_STAGE",
              FieldName = "id"
            },
            {
              Value = 6,
              TypeName = "NPC_COMB_OPTION_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\157\161\228\187\182\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\157\161\228\187\182\229\143\130\230\149\1762"
    },
    {
      Name = "data3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\157\161\228\187\182\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_STAGE_start_action", {
  Name = "DUNGEON_STAGE_start_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StageAction"
        }
      },
      Description = "\233\152\182\230\174\181\229\188\128\229\167\139\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\230\150\135\230\156\172"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_STAGE_finish_condition", {
  Name = "DUNGEON_STAGE_finish_condition",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StageConditionType"
        }
      },
      Description = "\229\174\140\230\136\144\230\157\161\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 1,
              TypeName = "DIALOGUE_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            },
            {
              Value = 3,
              TypeName = "BATTLE_CONF",
              FieldName = "id"
            },
            {
              Value = 5,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 4,
              TypeName = "DUNGEON_STAGE",
              FieldName = "id"
            },
            {
              Value = 6,
              TypeName = "NPC_COMB_OPTION_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\230\157\161\228\187\182\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\157\161\228\187\182\229\143\130\230\149\1762"
    },
    {
      Name = "data3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\157\161\228\187\182\229\143\130\230\149\1763"
    }
  }
})
RTTIManager:RegisterType("DUNGEON_STAGE_finish_action", {
  Name = "DUNGEON_STAGE_finish_action",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StageAction"
        }
      },
      Description = "\229\174\140\230\136\144\233\152\182\230\174\181\230\151\182\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "data1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "type",
          Branches = {
            {
              Value = 1,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            },
            {
              Value = 2,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\1761"
    },
    {
      Name = "data2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\229\143\130\230\149\1762"
    },
    {
      Name = "text",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\190\231\164\186\230\150\135\230\156\172"
    }
  }
})
RTTIManager:RegisterType("NPC_COMB_OPTION_CONF_option", {
  Name = "NPC_COMB_OPTION_CONF_option",
  Version = 1,
  Description = "\230\157\161\228\187\182\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "option_cond_npc",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "NPC\229\156\186\230\153\175\230\140\135\229\174\154\229\136\183\230\150\176\231\130\1851"
    },
    {
      Name = "option_cond_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "OptionCondType"
        }
      },
      Description = "\230\137\128\233\156\128\229\174\140\230\136\144\230\157\161\228\187\182\231\177\187\229\158\1391"
    },
    {
      Name = "con_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\229\143\130\230\149\176"
    }
  }
})
RTTIManager:RegisterType("NPC_COMB_RESULT_CONF_result_struct", {
  Name = "NPC_COMB_RESULT_CONF_result_struct",
  Version = 1,
  Description = "Result\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "result",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "CombinationResultType"
        }
      },
      Description = "\232\167\166\229\143\145\231\187\147\230\158\1561 CRT_UNLOCK_NPC=\232\167\163\233\148\129NPC CRT_CREATE_NPC=\229\136\155\229\187\186NPC"
    },
    {
      Name = "result_param",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "result",
          Branches = {
            {
              Value = 11,
              TypeName = "NPC_REFRESH_CONTENT_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\187\147\230\158\1561\229\143\130\230\149\1761"
    },
    {
      Name = "result_param2",
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
          DriverField = "result",
          Branches = {
            {
              Value = 10,
              TypeName = "NPC_OPTION_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\231\187\147\230\158\1561\229\143\130\230\149\1762"
    },
    {
      Name = "result_param3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\231\187\147\230\158\1561\229\143\130\230\149\1763"
    },
    {
      Name = "result_param4",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\187\147\230\158\1561\229\143\130\230\149\1764"
    },
    {
      Name = "result_param5",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.UINT32
        }
      },
      Description = "\231\187\147\230\158\1561\229\143\130\230\149\1765"
    },
    {
      Name = "wait_result",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\156\128\232\166\129\231\173\137\229\190\133\230\137\167\232\161\140\231\154\132\231\187\147\230\158\156\239\188\136\229\175\185\229\186\148\231\187\147\230\158\156\230\172\161\229\186\143-1\239\188\137"
    },
    {
      Name = "lock_guide",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\152\190\231\164\186\233\148\129\229\174\154\229\133\179\231\179\187\230\140\135\229\188\149"
    },
    {
      Name = "npc_guide",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcGuideIcon"
        }
      },
      Description = "\231\187\147\230\158\1561\230\140\135\231\164\186\229\153\168"
    },
    {
      Name = "set_permanent",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\174\190\231\189\174\231\187\147\230\158\156NPC\229\184\184\233\169\187"
    }
  }
})
RTTIManager:RegisterType("TELEPORT_CONF_teleport_dest", {
  Name = "TELEPORT_CONF_teleport_dest",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "dest_id",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\155\174\231\154\132\229\156\176Id\239\188\136\229\141\149\230\156\186\239\188\137"
    },
    {
      Name = "dest_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\155\174\231\154\132\229\156\176\229\143\130\230\149\176\239\188\136\229\141\149\230\156\186\239\188\137"
    },
    {
      Name = "dest_weight",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\155\174\231\154\132\229\156\176\230\157\131\229\128\188\239\188\136\229\141\149\230\156\186\239\188\137"
    }
  }
})
RTTIManager:RegisterType("TELEPORT_CONF_teleport_dest_online", {
  Name = "TELEPORT_CONF_teleport_dest_online",
  Version = 1,
  Description = "\232\129\148\230\156\186\228\184\139\228\188\160\233\128\129\230\152\175\229\156\134\231\142\175\232\140\131\229\155\180\229\134\133\233\154\143\230\156\186\233\128\137\231\130\185\239\188\136\232\175\165\230\149\176\231\187\132\233\133\141\231\189\174\239\188\137",
  Metadata = {},
  Fields = {
    {
      Name = "dest_area_id_online",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_CONF",
          FieldName = "id"
        }
      },
      Description = "\232\129\148\230\156\186\228\184\139\228\188\160\233\128\129\231\155\174\231\154\132\229\156\176\231\154\132\229\156\134\229\191\131"
    },
    {
      Name = "dest_outside_radius_online",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\129\148\230\156\186\228\184\139\228\188\160\233\128\129\231\155\174\231\154\132\229\156\176\231\154\132\229\164\167\229\156\134\229\141\138\229\190\132"
    },
    {
      Name = "dest_inside_radius_online",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\187\165\229\141\149\230\156\186\228\184\139\228\188\160\233\128\129\231\130\185\229\175\185\229\186\148NPC\228\184\186\228\184\173\229\191\131\239\188\140\229\156\134\231\142\175\229\134\133\229\141\138\229\190\132\239\188\140\233\129\191\229\133\141\228\188\160\233\128\129\232\191\135\229\142\187\228\184\142NPC\233\135\141\229\144\136\239\188\136\229\141\149\228\189\141\239\188\154\229\142\152\231\177\179\239\188\137"
    },
    {
      Name = "deviation_online",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\129\148\230\156\186\228\184\139\228\188\160\233\128\129\231\155\174\231\154\132\229\156\176\229\133\129\232\174\184\231\154\132\233\171\152\229\186\166\229\183\174\229\188\130"
    }
  }
})
RTTIManager:RegisterType("NPC_REFRESH_CONTENT_CONF_ai_group_param", {
  Name = "NPC_REFRESH_CONTENT_CONF_ai_group_param",
  Version = 1,
  Description = "",
  Metadata = {},
  Fields = {
    {
      Name = "ai_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_BASIC_INFO_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\230\137\128\229\177\158\231\190\164\232\144\189ID_1"
    },
    {
      Name = "ai_group_role",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GroupAIRoleType"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1"
    },
    {
      Name = "ai_group_role_id",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        },
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "NRC_GROUP_AI_ROLE_TYPE_CONF",
          FieldName = "id"
        }
      },
      Description = "ai\229\156\168\231\190\164\232\144\189\228\184\173\231\154\132\232\186\171\228\187\189_1(\232\175\187\229\143\150\230\150\176\232\161\168\239\188\137"
    },
    {
      Name = "ai_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\231\190\164\232\144\189\233\133\141\231\189\174\228\188\152\229\133\136\231\186\167_1"
    }
  }
})
RTTIManager:RegisterType("NRC_AI_BB_INPUT_CONF_blackboard_input", {
  Name = "NRC_AI_BB_INPUT_CONF_blackboard_input",
  Version = 1,
  Description = "\233\187\145\230\157\191\229\134\153\229\133\165\231\187\147\230\158\132\228\189\147",
  Metadata = {},
  Fields = {
    {
      Name = "blackboard_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\187\145\230\157\191\230\157\161\231\155\174"
    },
    {
      Name = "annotation",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\157\161\231\155\174\230\143\143\232\191\176"
    },
    {
      Name = "data_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "BBInputType"
        }
      },
      Description = "\230\149\176\230\141\174\231\177\187\229\158\139"
    },
    {
      Name = "data",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\187\145\230\157\191\229\128\188"
    },
    {
      Name = "additional_para",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\165\229\133\133\229\143\130\230\149\176"
    }
  }
})

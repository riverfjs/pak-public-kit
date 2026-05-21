local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_AI_PERFORM_POOL_CONF = {
  Name = "NRC_AI_PERFORM_POOL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_AI_PERFORM_POOL_CONF.yaml",
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
            {Min = 1, Max = 999999}
          }
        }
      },
      Description = "NPC_ID"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {},
      Description = "\229\144\141\231\167\176"
    },
    {
      Name = "ai_rand_method",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "AiPoolRandomMethod"
        }
      },
      Description = "\233\154\143\230\156\186\230\150\185\229\188\143"
    },
    {
      Name = "param1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\154\143\230\156\186\230\150\185\229\188\143\228\184\139\229\143\130\230\149\176(\229\176\143\230\151\182\239\188\137"
    },
    {
      Name = "pool_number",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\230\191\128\230\180\187\231\154\132\233\133\141\231\189\174\229\186\143\229\143\183(\230\179\168\230\132\143\233\161\186\229\186\143)"
    },
    {
      Name = "ai_perform_group_1",
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
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "ai_group_param_1",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_1"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "ai_perform_group_2",
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
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "ai_group_param_2",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_2"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "ai_perform_group_3",
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
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "ai_group_param_3",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_3"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "ai_perform_group_4",
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
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "ai_group_param_4",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_4"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "ai_perform_group_5",
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
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "ai_group_param_5",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_5"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    },
    {
      Name = "ai_perform_group_6",
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
      Description = "AI\230\137\128\229\177\158\229\136\134\231\187\132"
    },
    {
      Name = "ai_group_param_6",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Both,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 1
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_PERFORM_POOL_CONF_ai_group_param_6"
        }
      },
      Description = "\230\149\176\231\187\132\231\187\147\230\158\132\228\189\147\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(NRC_AI_PERFORM_POOL_CONF.Name, NRC_AI_PERFORM_POOL_CONF)

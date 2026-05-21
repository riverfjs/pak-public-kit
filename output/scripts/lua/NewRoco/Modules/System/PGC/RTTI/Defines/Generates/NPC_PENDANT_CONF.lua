local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NPC_PENDANT_CONF = {
  Name = "NPC_PENDANT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "npc_pendant/NPC_PENDANT_CONF.yaml",
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
      Description = "\230\140\130\228\187\182Id"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcPendantType"
        }
      },
      Description = "npc\230\140\130\228\187\182\231\177\187\229\158\139\239\188\136\230\160\135\229\191\151\232\191\153\228\184\170\230\140\130\228\187\182\230\152\175\229\129\154\228\187\128\228\185\136\231\148\168\231\154\132\239\188\137"
    },
    {
      Name = "area_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcPendantAreaType"
        }
      },
      Description = "\230\140\130\228\187\182\233\161\185\231\154\132\228\189\141\231\189\174\231\177\187\229\158\139"
    },
    {
      Name = "area_id",
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
      Description = "\230\140\130\228\187\182area id(\229\143\170\232\131\189\228\184\186\231\130\185\233\155\134)"
    },
    {
      Name = "npc_id",
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
      Description = "\230\140\130\228\187\182\233\161\185npc_id\239\188\136\230\191\128\230\180\187\229\144\142\229\135\186\230\157\165\231\154\132NpcId\239\188\137"
    },
    {
      Name = "disable_time",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\135\170\229\138\168\229\133\179\233\151\173\230\151\182\233\151\180\239\188\136ms\239\188\137\239\188\140\228\184\141\233\156\128\232\166\129\232\135\170\229\138\168\229\133\179\233\151\173\229\136\153\228\184\141\229\161\171\229\141\179\229\143\175"
    },
    {
      Name = "distance",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Client,
      Required = false,
      Constraints = {},
      Description = "\228\186\164\228\186\146\232\183\157\231\166\187(cm)"
    },
    {
      Name = "interact_effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcPendantInteractEffect"
        }
      },
      Description = "\230\140\130\228\187\182\233\161\185\228\186\164\228\186\146\230\149\136\230\158\156"
    },
    {
      Name = "interact_params",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "interact_effect",
          Branches = {
            {
              Value = 1,
              TypeName = "BAG_ITEM_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\229\143\130\230\149\176"
    },
    {
      Name = "interact_finish_effect",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "NpcPendantInteractFinishEffect"
        }
      },
      Description = "\230\140\130\228\187\182\233\161\185\229\133\168\233\131\168\228\186\164\228\186\146\229\174\140\230\136\144\229\174\140\230\136\144\230\149\136\230\158\156"
    },
    {
      Name = "interact_finish_params",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\130\230\149\176"
    }
  }
}
RTTIManager:RegisterType(NPC_PENDANT_CONF.Name, NPC_PENDANT_CONF)

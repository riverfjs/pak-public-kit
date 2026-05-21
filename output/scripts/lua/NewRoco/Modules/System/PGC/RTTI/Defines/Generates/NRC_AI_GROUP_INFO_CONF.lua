local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local NRC_AI_GROUP_INFO_CONF = {
  Name = "NRC_AI_GROUP_INFO_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "ai_new/NRC_AI_GROUP_INFO_CONF.yaml",
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
      Description = "\229\136\134\231\187\132ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRING,
          Size = 2
        }
      },
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "fsm_struct_id",
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
      Description = "\231\138\182\230\128\129\230\156\186\231\187\147\230\158\132ID"
    },
    {
      Name = "visual_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\134\232\167\137\233\133\141\231\189\174"
    },
    {
      Name = "audio_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\144\172\232\167\137\233\133\141\231\189\174"
    },
    {
      Name = "mod_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\132\159\231\159\165\228\191\174\230\173\163"
    },
    {
      Name = "cone_ids",
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
          TypeName = "NRC_AI_SENSE_CONE_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\132\159\231\159\165\233\148\165id"
    },
    {
      Name = "bb_input",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\170\230\128\167\229\140\150\229\143\130\230\149\176"
    },
    {
      Name = "behavior_group",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 20
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "NRC_AI_GROUP_INFO_CONF_behavior_group"
        }
      },
      Description = "\230\149\176\231\187\132\229\163\176\230\152\142"
    }
  }
}
RTTIManager:RegisterType(NRC_AI_GROUP_INFO_CONF.Name, NRC_AI_GROUP_INFO_CONF)

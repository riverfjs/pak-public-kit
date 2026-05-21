local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local FUNCTION_STORY_FLAG_CONF = {
  Name = "FUNCTION_STORY_FLAG_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "dialogue/FUNCTION_STORY_FLAG_CONF.yaml",
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
      Description = "\230\149\176\230\141\174ID"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "story_flag\229\164\135\230\179\168"
    },
    {
      Name = "story_flag_action_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "StoryFlagAction"
        }
      },
      Description = "story_flag\229\184\166\230\156\137\231\154\132\232\161\140\228\184\186\231\177\187\229\158\139"
    },
    {
      Name = "action_string_param",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\161\140\228\184\186\229\143\130\230\149\176\239\188\136\230\150\135\230\156\172\231\177\187\239\188\137"
    },
    {
      Name = "action_int_param",
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
          DriverField = "SCENE_RES_CONF,id",
          EnumName = "story_flag_action_type=SFA_AIR_WALL_OPEN,BLOCK_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.SMART_FOREIGN_KEY,
          DriverField = "SCENE_RES_CONF,id",
          EnumName = "story_flag_action_type=SFA_AIR_WALL_CLOSE,BLOCK_CONF",
          LinkFieldName = "id"
        },
        {
          Type = RTTIBase.ConstraintType.CONDITION_KEY,
          DriverField = "story_flag_action_type",
          Branches = {
            {
              Value = 7,
              TypeName = "AREA_VISIBLE_CONF",
              FieldName = "id"
            },
            {
              Value = 12,
              TypeName = "AREA_CONF",
              FieldName = "id"
            },
            {
              Value = 8,
              TypeName = "SCENE_RES_CONF",
              FieldName = "id"
            }
          }
        }
      },
      Description = "\232\161\140\228\184\186\229\143\130\230\149\176\239\188\136\230\149\176\229\173\151\231\177\187\239\188\137"
    },
    {
      Name = "apply_to_visitor",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\175\185\232\174\191\229\174\162\231\148\159\230\149\136"
    },
    {
      Name = "unreachable_range",
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
          DriverField = "X",
          EnumName = "SCENE_CONF",
          LinkFieldName = "Y"
        }
      },
      Description = "\233\128\128\229\135\186\228\186\146\232\174\191\232\191\155\229\133\165\228\184\141\229\143\175\232\190\190\229\140\186\229\159\159\229\157\144\230\160\135"
    },
    {
      Name = "range_data",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\233\128\128\229\135\186\228\186\146\232\174\191\232\191\155\229\133\165\228\184\141\229\143\175\232\190\190\229\140\186\229\159\159\232\140\131\229\155\180\239\188\136\229\141\138\229\190\132\239\188\137"
    }
  }
}
RTTIManager:RegisterType(FUNCTION_STORY_FLAG_CONF.Name, FUNCTION_STORY_FLAG_CONF)

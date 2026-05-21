local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local SCENE_CONF = {
  Name = "SCENE_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "scene/SCENE_CONF.yaml",
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
        },
        {
          Type = RTTIBase.ConstraintType.LIMIT_VALUE,
          Ranges = {
            {Min = 100, Max = 4095}
          }
        }
      },
      Description = "\229\156\186\230\153\175ID\239\188\140ID\230\174\181100~4095"
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
      Name = "scene_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.LOCALE_NAME,
          LocaleName = "scene_name"
        }
      },
      Description = "\229\156\186\230\153\175\229\144\141\231\167\176"
    },
    {
      Name = "scene_res_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "SCENE_RES_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175\228\189\191\231\148\168\231\154\132res_id"
    },
    {
      Name = "is_unused",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\186\159\229\188\131"
    },
    {
      Name = "scene_load_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneLoadType"
        }
      },
      Description = "\229\156\186\230\153\175\229\138\160\232\189\189\231\177\187\229\158\139"
    },
    {
      Name = "env_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "SceneAbilityDisableCode"
        }
      },
      Description = "\229\156\186\230\153\175\231\142\175\229\162\131\231\177\187\229\158\139"
    },
    {
      Name = "born_pos_x",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\148\159\231\130\185\229\157\144\230\160\135x \229\144\142\231\187\173\232\176\131\230\149\180\228\184\186\229\156\176\229\155\190\229\175\188\232\161\168\230\150\185\229\188\143"
    },
    {
      Name = "born_pos_y",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\148\159\231\130\185\229\157\144\230\160\135y"
    },
    {
      Name = "born_pos_z",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\148\159\231\130\185\229\157\144\230\160\135z"
    },
    {
      Name = "born_spin_x",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\148\159\231\130\185\230\151\139\232\189\172x"
    },
    {
      Name = "born_spin_y",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\148\159\231\130\185\230\145\132\229\131\143\230\156\186\230\178\191Y\232\189\180\231\154\132\230\151\139\232\189\172"
    },
    {
      Name = "born_spin_z",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\135\186\231\148\159\231\130\185\232\167\146\232\137\178\230\178\191Z\232\189\180\231\154\132\230\151\139\232\189\172"
    },
    {
      Name = "block_ids",
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
          TypeName = "BLOCK_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175\232\190\185\231\149\140\229\184\184\233\169\187\231\154\132\231\169\186\230\176\148\229\162\153"
    }
  }
}
RTTIManager:RegisterType(SCENE_CONF.Name, SCENE_CONF)

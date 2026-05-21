local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local MAGIC_TRANSFORM_CONF = {
  Name = "MAGIC_TRANSFORM_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "magic_base_conf/MAGIC_TRANSFORM_CONF.yaml",
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
      Description = "ID"
    },
    {
      Name = "is_pet",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = true,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\228\184\186\231\178\190\231\129\181"
    },
    {
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\229\144\141\231\167\176"
    },
    {
      Name = "transform_group",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\182\178\229\140\150\230\156\175\231\154\132\229\143\152\229\189\162\229\136\134\231\187\132"
    },
    {
      Name = "function_ban_ref",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "FUNCTION_BAN_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\138\159\232\131\189\231\166\129\231\148\168"
    },
    {
      Name = "aim_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\153\186\232\131\189\229\135\134\230\152\159\232\181\132\228\186\167\232\183\175\229\190\132"
    },
    {
      Name = "time",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\140\129\231\187\173\230\151\182\233\151\180\239\188\136ms\239\188\137 -1\232\161\168\231\164\186\230\176\184\228\185\133"
    },
    {
      Name = "area_func_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.FOREIGN_KEY,
          TypeName = "AREA_FUNC_CONF",
          FieldName = "id"
        }
      },
      Description = "\231\148\159\230\149\136\229\140\186\229\159\159"
    },
    {
      Name = "model_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "NPC\231\154\132model_id\239\188\136\232\139\165\228\184\186\231\178\190\231\129\181\229\136\153\229\175\185\229\186\148all_ride\231\154\132id\239\188\137"
    },
    {
      Name = "use_confirm_panel",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\130\185\229\135\187\229\143\150\230\182\136\229\143\152\229\189\162\230\151\182\229\188\185\229\135\186\231\161\174\232\174\164\230\143\144\231\164\186"
    },
    {
      Name = "which_bantype",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PlayerFunctionBanType"
        }
      },
      Description = "\228\189\191\231\148\168\228\189\149\231\167\141\229\143\152\229\189\162\228\186\146\230\150\165\230\158\154\228\184\190"
    },
    {
      Name = "player_story_flag",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "PlayerStoryFlagEnum"
        }
      },
      Description = "\229\143\152\229\189\162\231\138\182\230\128\129\228\184\139\232\181\139\228\186\136\231\154\132storyflag"
    },
    {
      Name = "use_lique_fx",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\189\191\231\148\168\230\182\178\229\140\150\229\143\152\229\189\162\231\137\185\230\149\136"
    },
    {
      Name = "lique_start_fx",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\182\178\229\140\150\230\156\175\229\188\128\229\167\139\229\143\152\229\189\162\231\137\185\230\149\136\232\183\175\229\190\132"
    },
    {
      Name = "lique_end_fx",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\182\178\229\140\150\230\156\175\232\167\163\233\153\164\229\143\152\229\189\162\231\137\185\230\149\136\232\183\175\229\190\132"
    },
    {
      Name = "idle_anim",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\143\152\229\189\162\231\178\190\231\129\181\229\190\133\230\146\173\229\138\168\228\189\156\231\154\132\229\144\141\231\167\176"
    },
    {
      Name = "exit_cancel_transformation",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\164\167\233\128\128\230\152\175\229\144\166\232\167\163\233\153\164\229\143\152\232\186\171"
    }
  }
}
RTTIManager:RegisterType(MAGIC_TRANSFORM_CONF.Name, MAGIC_TRANSFORM_CONF)

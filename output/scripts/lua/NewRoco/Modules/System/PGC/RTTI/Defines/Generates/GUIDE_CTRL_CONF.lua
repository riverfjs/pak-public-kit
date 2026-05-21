local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local GUIDE_CTRL_CONF = {
  Name = "GUIDE_CTRL_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "guide/GUIDE_CTRL_CONF.yaml",
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
      Name = "editor_name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Edit,
      Required = false,
      Constraints = {},
      Description = "\229\164\135\230\179\168"
    },
    {
      Name = "guide_group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\149\229\175\188\231\187\132"
    },
    {
      Name = "sub_guide_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\173\144\229\188\149\229\175\188\229\186\143\229\136\151"
    },
    {
      Name = "pc_show",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "PC\230\152\175\229\144\166\230\152\190\231\164\186"
    },
    {
      Name = "mobile_show",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\137\139\231\171\175\230\152\175\229\144\166\230\152\190\231\164\186"
    },
    {
      Name = "guide_group_priority",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\188\149\229\175\188\231\187\132\228\188\152\229\133\136\231\186\167"
    },
    {
      Name = "can_interrupt_other",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\143\175\228\187\165\230\137\147\230\150\173\229\133\182\228\187\150\229\188\149\229\175\188\231\187\132"
    },
    {
      Name = "cond_type",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\157\161\228\187\182\230\163\128\230\181\139\231\177\187\229\158\139"
    },
    {
      Name = "type1",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\157\161\228\187\1821\231\177\187\229\158\139"
    },
    {
      Name = "type1_data_1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\157\161\228\187\1821\229\143\130\230\149\1761"
    },
    {
      Name = "type1_data_2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\157\161\228\187\1821\229\143\130\230\149\1762"
    },
    {
      Name = "type2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\157\161\228\187\1822\231\177\187\229\158\139"
    },
    {
      Name = "type2_data_1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\157\161\228\187\1822\229\143\130\230\149\1761"
    },
    {
      Name = "type2_data_2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\230\157\161\228\187\1822\229\143\130\230\149\1762"
    },
    {
      Name = "res_scene_id",
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
          TypeName = "SCENE_RES_CONF",
          FieldName = "id"
        }
      },
      Description = "\229\156\186\230\153\175"
    },
    {
      Name = "delay_time",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\166\229\143\145\229\187\182\232\191\159\239\188\136\230\175\171\231\167\146\239\188\137"
    },
    {
      Name = "open",
      Type = RTTIBase.FieldType.INT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\184\139\230\158\182"
    },
    {
      Name = "finish_button_showtime",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\183\179\232\191\135\230\140\137\233\146\174\229\135\186\231\142\176\230\151\182\233\151\180\239\188\136\229\141\149\228\189\141\239\188\154\230\175\171\231\167\146\239\188\137"
    },
    {
      Name = "finish_overtime",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\182\133\230\151\182\232\183\179\232\191\135"
    },
    {
      Name = "reconnect",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\230\150\173\231\186\191\233\135\141\232\191\158"
    },
    {
      Name = "reset_step",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\150\173\231\186\191\233\135\141\232\191\158\230\129\162\229\164\141\230\173\165\233\170\164"
    },
    {
      Name = "is_local",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\229\155\158\230\131\179\231\177\187\229\158\139\239\188\136\228\184\141\228\184\138\230\138\165\232\174\176\229\189\149\239\188\137"
    },
    {
      Name = "strong_guide",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\229\188\186\230\140\135\229\188\149"
    },
    {
      Name = "is_inbattle",
      Type = RTTIBase.FieldType.BOOL,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\152\175\229\144\166\228\184\186\230\136\152\230\150\151\229\177\128\229\134\133\230\140\135\229\188\149"
    },
    {
      Name = "transparence",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\146\153\229\177\130\233\128\143\230\152\142\229\186\166"
    },
    {
      Name = "active_ia_watch",
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
          TypeName = "GUIDE_IA_CONF",
          FieldName = "id"
        }
      },
      Description = "\230\191\128\230\180\187\229\144\142\229\147\141\229\186\148\229\147\170\228\186\155IA"
    },
    {
      Name = "style_type",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\160\183\229\188\143\231\177\187\229\158\139"
    },
    {
      Name = "type_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\160\183\229\188\143id"
    },
    {
      Name = "finish_type",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\191\157\229\186\149\229\174\140\230\136\144\230\157\161\228\187\182\231\177\187\229\158\139"
    },
    {
      Name = "finish_data1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1821\229\143\130\230\149\1761"
    },
    {
      Name = "finish_data2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1821\229\143\130\230\149\1762"
    },
    {
      Name = "cond_type_done",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\182\230\163\128\230\181\139\231\177\187\229\158\139"
    },
    {
      Name = "done_type",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1821\231\177\187\229\158\139"
    },
    {
      Name = "done_type_data1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1821\229\143\130\230\149\1761"
    },
    {
      Name = "done_type_data2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1821\229\143\130\230\149\1762"
    },
    {
      Name = "done_type2",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1822\231\177\187\229\158\139"
    },
    {
      Name = "done_type2_data1",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1822\229\143\130\230\149\1761"
    },
    {
      Name = "done_type2_data2",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\229\174\140\230\136\144\230\157\161\228\187\1822\229\143\130\230\149\1762"
    },
    {
      Name = "func_ban_id",
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
      Description = "\231\166\129\231\148\168\229\138\159\232\131\189id"
    },
    {
      Name = "setting_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "GuideSettingMode"
        }
      },
      Description = "\232\174\190\231\189\174\231\177\187\229\158\139"
    },
    {
      Name = "setting_data",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.INT32
        }
      },
      Description = "\232\174\190\231\189\174\229\143\130\230\149\176"
    }
  }
}
RTTIManager:RegisterType(GUIDE_CTRL_CONF.Name, GUIDE_CTRL_CONF)

local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local PET_HABIT_CONF = {
  Name = "PET_HABIT_CONF",
  Version = 1,
  Description = "",
  Metadata = {
    Alias = "",
    RelativeYamlPath = "pet/PET_HABIT_CONF.yaml",
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
      Name = "group_id",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\231\178\190\231\129\181\228\185\160\230\128\167\230\137\128\229\177\158\231\187\132ID"
    },
    {
      Name = "group_number",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\231\154\132\231\187\132\231\188\150\229\143\183"
    },
    {
      Name = "name",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\229\144\141\231\167\176"
    },
    {
      Name = "desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\230\143\143\232\191\176"
    },
    {
      Name = "effect_desc",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\230\149\136\230\158\156\230\143\143\232\191\176"
    },
    {
      Name = "habit_icon_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\230\139\188\229\155\190icon\232\183\175\229\190\132"
    },
    {
      Name = "habit_buff_type",
      Type = RTTIBase.FieldType.ENUM,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ENUM,
          EnumName = "HabitBuffType"
        }
      },
      Description = "\228\185\160\230\128\167\229\162\158\231\155\138\230\149\136\230\158\156\231\167\141\231\177\187"
    },
    {
      Name = "habit_locked_icon_path",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\230\156\170\232\167\163\233\148\129\228\185\160\230\128\167\230\139\188\229\155\190icon\232\183\175\229\190\132"
    },
    {
      Name = "attribute_icon",
      Type = RTTIBase.FieldType.STRING,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\228\185\160\230\128\167\229\177\158\230\128\167icon\239\188\136\231\187\147\231\174\151\233\161\181\231\148\168\239\188\137"
    },
    {
      Name = "unlock_money",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\230\182\136\232\128\151\230\180\155\229\133\139\232\180\157\230\149\176\233\135\143"
    },
    {
      Name = "unlock_item_id",
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
      Description = "\232\167\163\233\148\129\230\182\136\232\128\151\233\129\147\229\133\183id"
    },
    {
      Name = "unlock_item_num",
      Type = RTTIBase.FieldType.UINT32,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {},
      Description = "\232\167\163\233\148\129\230\182\136\232\128\151\233\129\147\229\133\183\230\149\176\233\135\143"
    },
    {
      Name = "habit_ability",
      Type = RTTIBase.FieldType.ARRAY,
      Scope = RTTIBase.ScopeType.Default,
      Required = false,
      Constraints = {
        {
          Type = RTTIBase.ConstraintType.ARRAY,
          ElementType = RTTIBase.FieldType.STRUCT,
          Size = 2
        },
        {
          Type = RTTIBase.ConstraintType.TYPE,
          TypeName = "PET_HABIT_CONF_habit_ability"
        }
      },
      Description = ""
    }
  }
}
RTTIManager:RegisterType(PET_HABIT_CONF.Name, PET_HABIT_CONF)

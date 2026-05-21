local UMG_AbstractView = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractView")
local UMG_FieldValue_C = UMG_AbstractView:Extend("UMG_FieldValue_C")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")

local function GetValueType(FieldInfo)
  local FieldType = FieldInfo and FieldInfo.Type
  if FieldType then
    if RTTIBase.IsIntegerType(FieldType) then
      return PGCModuleEnum.ValueType.Integer
    elseif RTTIBase.IsFloatType(FieldType) then
      return PGCModuleEnum.ValueType.Float
    elseif RTTIBase.FieldType.STRING == FieldType then
      return PGCModuleEnum.ValueType.String
    elseif RTTIBase.FieldType.BOOL == FieldType then
      return PGCModuleEnum.ValueType.Boolean
    elseif RTTIBase.FieldType.ENUM == FieldType then
      return PGCModuleEnum.ValueType.Enum
    elseif RTTIBase.FieldType.STRUCT == FieldType then
      return PGCModuleEnum.ValueType.Struct
    elseif RTTIBase.FieldType.ARRAY == FieldType then
      return PGCModuleEnum.ValueType.Array
    end
  end
end

function UMG_FieldValue_C:OnActiveView()
  self.ValueInputs = {
    [PGCModuleEnum.ValueType.Array] = self.UMG_InputArray,
    [PGCModuleEnum.ValueType.Boolean] = self.UMG_InputBoolean,
    [PGCModuleEnum.ValueType.Enum] = self.UMG_InputEnum,
    [PGCModuleEnum.ValueType.Float] = self.UMG_InputFloat,
    [PGCModuleEnum.ValueType.Integer] = self.UMG_InputInteger,
    [PGCModuleEnum.ValueType.String] = self.UMG_InputString,
    [PGCModuleEnum.ValueType.Struct] = self.UMG_InputStruct
  }
  for _, ValueInput in pairs(self.ValueInputs) do
    ValueInput:Active()
  end
end

function UMG_FieldValue_C:OnDeactiveView()
  if self.ValueInputs then
    for _, ValueInput in pairs(self.ValueInputs) do
      ValueInput:Deactive()
    end
    self.ValueInputs = nil
  end
end

function UMG_FieldValue_C:OnFlushData()
  local FieldInfo = self.Data.RTTI.FieldInfo
  if FieldInfo.Constraint.PrimaryKey then
    self.Mask.Slot:SetZorder(2)
  else
    self.Mask.Slot:SetZorder(0)
  end
  local ValueType = GetValueType(FieldInfo)
  if ValueType then
    self.Switcher:SetActiveWidgetIndex(ValueType)
    local ValueInput = self.ValueInputs and self.ValueInputs[ValueType]
    if ValueInput then
      ValueInput:RefreshData(self.Data)
    end
  end
end

return UMG_FieldValue_C

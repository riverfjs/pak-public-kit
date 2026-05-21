local PGCModuleEnum = {}
PGCModuleEnum.DataType = {NPCType = 1, NPCInstance = 2}
PGCModuleEnum.PanelNames = {
  DataView = "DataView",
  EnumView = "EnumView",
  StructView = "StructView",
  ArrayView = "ArrayView"
}
local EnumIndex = 0

local function ResetEnumIndex()
  EnumIndex = 0
  return EnumIndex
end

local function AutoEnumIndex()
  EnumIndex = EnumIndex + 1
  return EnumIndex
end

PGCModuleEnum.ValueType = {
  Array = ResetEnumIndex(),
  Boolean = AutoEnumIndex(),
  Enum = AutoEnumIndex(),
  Float = AutoEnumIndex(),
  Integer = AutoEnumIndex(),
  String = AutoEnumIndex(),
  Struct = AutoEnumIndex()
}
return PGCModuleEnum

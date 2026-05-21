local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local UMG_InputEnum_C = UMG_AbstractInput:Extend("UMG_InputEnum_C")

function UMG_InputEnum_C:OnActiveView()
  self.Button.OnPressed:Add(self, self.OnPressed)
  self.DropdownState:SetActiveWidgetIndex(0)
end

function UMG_InputEnum_C:OnDeactiveView()
  self.Button.OnPressed:Clear()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self.DelayHandle = nil
  end
end

function UMG_InputEnum_C:OnFlushData()
  local Value = self:GetProperty()
  if nil == Value then
    self.Value:SetText("")
    return
  end
  local ValueName = self:GetEnumNameByValue(Value)
  if ValueName then
    self.Value:SetText(ValueName)
  else
    self.Value:SetText(tostring(Value))
  end
end

function UMG_InputEnum_C:GetEnumInfo()
  local FieldInfo = self.Data and self.Data.RTTI and self.Data.RTTI.FieldInfo
  local Constraint = FieldInfo and FieldInfo.Constraint
  local EnumConstraint = Constraint and Constraint.Enum
  local EnumName = EnumConstraint and EnumConstraint.EnumName
  if not EnumName then
    return nil
  end
  return RTTIManager:GetEnumInfo(EnumName)
end

function UMG_InputEnum_C:GetEnumValueNameList()
  local ValueNameList = {}
  local EnumInfo = self:GetEnumInfo()
  local FieldOrder = EnumInfo and EnumInfo.FieldOrder
  if FieldOrder then
    for _, Name in ipairs(FieldOrder) do
      table.insert(ValueNameList, Name)
    end
  end
  return ValueNameList
end

function UMG_InputEnum_C:GetEnumNameByValue(EnumValue)
  if nil == EnumValue then
    return nil
  end
  local EnumInfo = self:GetEnumInfo()
  local ValueToName = EnumInfo and EnumInfo.ValueToName
  return ValueToName and ValueToName[EnumValue] or nil
end

function UMG_InputEnum_C:GetEnumValueByName(EnumName)
  local EnumInfo = self:GetEnumInfo()
  local Value = EnumInfo and EnumInfo.NameToValue and EnumInfo.NameToValue[EnumName] or nil
  if nil == Value then
    Value = self:GetProperty()
  end
  return Value
end

function UMG_InputEnum_C:OnPressed()
  if 1 == self.DropdownState:GetActiveWidgetIndex() then
    NRCModuleManager:DoCmd(PGCModuleCmd.ShowEnumData)
    return
  end
  local ValueNameList = self:GetEnumValueNameList()
  NRCModuleManager:DoCmd(PGCModuleCmd.ShowEnumData, ValueNameList, self.DropdownSlot, self.DropdownState, function(_, Index, Selected)
    if not Selected then
      return
    end
    local ValueName = ValueNameList[Index + 1]
    if ValueName then
      self.DelayHandle = _G.DelayManager:DelayFrames(1, self.OnValueSelected, self, ValueName)
    end
  end)
end

function UMG_InputEnum_C:OnValueSelected(ValueName)
  self.Value:SetText(ValueName)
  local Value = self:GetEnumValueByName(ValueName)
  self:SetProperty(Value)
  NRCModuleManager:DoCmd(PGCModuleCmd.ShowEnumData)
end

return UMG_InputEnum_C

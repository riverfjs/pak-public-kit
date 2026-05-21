local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local UMG_InputFloat_C = UMG_AbstractInput:Extend("UMG_InputFloat_C")

function UMG_InputFloat_C:OnActiveView()
  self.Value:SetDelta(0.0)
  self.Value:SetMinFractionalDigits(2)
  self.Value:SetMaxFractionalDigits(2)
  self.Value.OnValueChanged:Add(self, self.OnValueChanged)
end

function UMG_InputFloat_C:OnDeactiveView()
  self.Value.OnValueChanged:Remove(self, self.OnValueChanged)
end

function UMG_InputFloat_C:OnFlushData()
  local Value = self:GetProperty()
  if Value then
    self.Value:SetValue(Value)
  end
end

function UMG_InputFloat_C:OnValueChanged(Value)
  self:SetProperty(Value)
end

return UMG_InputFloat_C

local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local UMG_InputInteger_C = UMG_AbstractInput:Extend("UMG_InputInteger_C")

function UMG_InputInteger_C:OnActiveView()
  self.Value:SetDelta(1.0)
  self.Value:SetMinFractionalDigits(0)
  self.Value:SetMaxFractionalDigits(0)
  self.Value.OnValueChanged:Add(self, self.OnValueChanged)
end

function UMG_InputInteger_C:OnDeactiveView()
  self.Value.OnValueChanged:Remove(self, self.OnValueChanged)
end

function UMG_InputInteger_C:OnFlushData()
  local Value = self:GetProperty()
  if Value then
    self.Value:SetValue(Value)
  end
end

function UMG_InputInteger_C:OnValueChanged(Value)
  self:SetProperty(math.floor(Value))
end

return UMG_InputInteger_C

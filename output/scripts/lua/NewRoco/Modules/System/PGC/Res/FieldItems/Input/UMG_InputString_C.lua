local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local UMG_InputString_C = UMG_AbstractInput:Extend("UMG_InputString_C")

function UMG_InputString_C:OnActiveView()
  self.Value.OnTextCommitted:Add(self, self.OnTextCommitted)
end

function UMG_InputString_C:OnDeactiveView()
  self.Value.OnTextCommitted:Remove(self, self.OnTextCommitted)
end

function UMG_InputString_C:OnFlushData()
  local Text = self:GetProperty()
  if nil == Text then
    Text = ""
  end
  self.Value:SetText(Text)
end

function UMG_InputString_C:OnTextCommitted(Text)
  if "" == Text then
    Text = nil
  end
  self:SetProperty(Text)
end

return UMG_InputString_C

local UMG_AbstractInput = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractInput")
local UMG_InputBoolean_C = UMG_AbstractInput:Extend("UMG_InputBoolean_C")

function UMG_InputBoolean_C:OnActiveView()
  self.Unselected.OnPressed:Add(self, self.OnUnselected)
  self.Selected.OnPressed:Add(self, self.OnSelected)
end

function UMG_InputBoolean_C:OnDeactiveView()
  self.Unselected.OnPressed:Clear()
  self.Selected.OnPressed:Clear()
end

function UMG_InputBoolean_C:OnFlushData()
  local Toggle = self:GetProperty()
  if Toggle then
    self.Value:SetActiveWidgetIndex(1)
  else
    self.Value:SetActiveWidgetIndex(0)
  end
end

function UMG_InputBoolean_C:OnUnselected()
  local Toggle = self:GetProperty()
  if not Toggle and self:SetProperty(true) then
    self.Value:SetActiveWidgetIndex(1)
  end
end

function UMG_InputBoolean_C:OnSelected()
  local Toggle = self:GetProperty()
  if Toggle and self:SetProperty(false) then
    self.Value:SetActiveWidgetIndex(0)
  end
end

return UMG_InputBoolean_C

local UMG_EnumView_C = NRCPanelBase:Extend("UMG_EnumView_C")

function UMG_EnumView_C:OnActive(Data)
  NRCPanelBase.OnActive(self, Data)
  if Data then
    if Data.Values then
      self.Options:InitList(Data.Values)
    end
    if Data.Slot then
      Data.Slot:SetContent(self)
    end
    if Data.State then
      Data.State:SetActiveWidgetIndex(1)
      self.DataState = Data.State
    end
    if Data.OnItemSelected then
      self.OnItemSelected = Data.OnItemSelected
      self.Options.OnItemSelected:Add(self, self.OnOptionSelected)
    end
  end
end

function UMG_EnumView_C:OnDeactive()
  if self.DataState then
    self.DataState:SetActiveWidgetIndex(0)
    self.DataState = nil
  end
  self.Options:ClearList(false)
  self:RemoveFromParent()
  if self.OnItemSelected then
    self.Options.OnItemSelected:Clear()
    self.OnItemSelected = nil
  end
  NRCPanelBase.OnDeactive(self)
end

function UMG_EnumView_C:OnOptionSelected(OwnerView, Index, Selected, ScrollChoose)
  if self.OnItemSelected then
    self.OnItemSelected(OwnerView, Index, Selected, ScrollChoose)
  end
end

return UMG_EnumView_C

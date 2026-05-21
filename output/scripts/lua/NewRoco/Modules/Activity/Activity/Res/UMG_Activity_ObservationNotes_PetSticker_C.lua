local UMG_Activity_ObservationNotes_PetSticker_C = _G.NRCPanelBase:Extend("UMG_Activity_ObservationNotes_PetSticker_C")

function UMG_Activity_ObservationNotes_PetSticker_C:SetInfo(data)
  self.Sticker:SetPath(data.image)
  if data.txt_pos == Enum.PetSotryDecorationImageTxt.PSDI_RIGHT then
    self.NRCText_Name_1:SetText(data.content)
    self.NRCSwitcher_Text:SetActiveWidgetIndex(1)
  elseif data.txt_pos == Enum.PetSotryDecorationImageTxt.PSDI_LEFT then
    self.NRCText_Name:SetText(data.content)
    self.NRCSwitcher_Text:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_Text:SetActiveWidgetIndex(2)
  end
end

return UMG_Activity_ObservationNotes_PetSticker_C

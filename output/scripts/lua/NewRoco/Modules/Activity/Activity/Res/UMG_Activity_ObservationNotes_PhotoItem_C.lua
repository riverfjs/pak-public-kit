local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_Activity_ObservationNotes_PhotoItem_C = Base:Extend("UMG_Activity_ObservationNotes_PhotoItem_C")

function UMG_Activity_ObservationNotes_PhotoItem_C:OnConstruct()
end

function UMG_Activity_ObservationNotes_PhotoItem_C:OnDestruct()
end

function UMG_Activity_ObservationNotes_PhotoItem_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.data = _data
end

function UMG_Activity_ObservationNotes_PhotoItem_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ObservationNotes_PhotoItem_C:OnDeactive()
end

function UMG_Activity_ObservationNotes_PhotoItem_C:ShowInfo(isTarget)
  if isTarget then
    self.NRCSwitcher_16:SetActiveWidgetIndex(1)
    self.NRCText_Titel:SetText(self.data.text)
    self.Image_Colour_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(self.data.color))
  else
    self.NRCSwitcher_16:SetActiveWidgetIndex(0)
    self.Image_Colour:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(self.data.color))
  end
end

return UMG_Activity_ObservationNotes_PhotoItem_C

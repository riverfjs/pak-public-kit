local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TakePhatosDropDownListltem_C = Base:Extend("UMG_TakePhatosDropDownListltem_C")

function UMG_TakePhatosDropDownListltem_C:OnConstruct()
end

function UMG_TakePhatosDropDownListltem_C:OnDestruct()
end

function UMG_TakePhatosDropDownListltem_C:OnItemUpdate(_data, datalist, index)
  self.SettingData = _data
  self.TText:SetText(_data.Name)
  if self.SettingData.IsSelected() then
    self.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827FF"))
  else
    self.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("C4C2B6FF"))
  end
end

function UMG_TakePhatosDropDownListltem_C:OnItemSelected(_bSelected)
  if _bSelected then
    self.SettingData.OnClicked()
  end
end

function UMG_TakePhatosDropDownListltem_C:OnDeactive()
end

return UMG_TakePhatosDropDownListltem_C

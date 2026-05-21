local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local LoginModuleEvent = require("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local UMG_CultureListItem_C = Base:Extend("UMG_CultureListItem_C")

function UMG_CultureListItem_C:OnItemUpdate(data, dataList, index)
  self.index = index
  self:SetData(data)
end

function UMG_CultureListItem_C:SetData(data)
  local displayName = UE4.UKismetInternationalizationLibrary.GetCultureDisplayName(data.culture, false)
  self.Display:SetText(displayName)
  self.data = data
  self.parent = self.data.parent
  local curCulture = UE4.UNRCStatics.GetCurrentCulture()
  self.Selected:SetVisibility(curCulture == self.data.culture and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Hidden)
  self.Display:SetColorAndOpacity(curCulture == self.data.culture and UE4.UNRCStatics.HexToSlateColor("#272727FF") or UE4.UNRCStatics.HexToSlateColor("#C3C1B4FF"))
end

function UMG_CultureListItem_C:OnItemSelected(_bSelect)
  if _bSelect then
    self.Display:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    self.Selected:SetVisibility(UE4.ESlateVisibility.Visible)
    self:Log("UMG_CultureListItem_C:OnItemSelected ", self.data.culture)
    NRCModuleManager:GetModule("LoginModule"):DispatchEvent(LoginModuleEvent.CultureClick, self.data)
  end
end

function UMG_CultureListItem_C:ClearItemSelected()
  self.Display:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C3C1B4FF"))
  self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_CultureListItem_C:Destruct()
  self:ReleaseForce()
end

return UMG_CultureListItem_C

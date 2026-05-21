local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Handbook_Albumtab_C = Base:Extend("UMG_Handbook_Albumtab_C")

function UMG_Handbook_Albumtab_C:OnConstruct()
end

function UMG_Handbook_Albumtab_C:OnDestruct()
end

function UMG_Handbook_Albumtab_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.Title:SetText(_data.title)
end

function UMG_Handbook_Albumtab_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.Press)
    _G.NRCModuleManager:GetModule("HandbookModule"):DispatchEvent(HandbookModuleEvent.OnChangeSelectPhotoSwitcher, self.index)
  else
    self:PlayAnimation(self.Normal)
  end
end

function UMG_Handbook_Albumtab_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_Handbook_Albumtab_C:OnTouchEnded")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Handbook_Albumtab_C:OnDeactive()
end

return UMG_Handbook_Albumtab_C

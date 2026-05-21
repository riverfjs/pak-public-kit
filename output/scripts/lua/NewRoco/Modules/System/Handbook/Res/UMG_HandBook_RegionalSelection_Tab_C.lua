local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local HandbookModuleEnum = reload("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_HandBook_RegionalSelection_Tab_C = Base:Extend("UMG_HandBook_RegionalSelection_Tab_C")

function UMG_HandBook_RegionalSelection_Tab_C:OnConstruct()
end

function UMG_HandBook_RegionalSelection_Tab_C:OnDestruct()
end

function UMG_HandBook_RegionalSelection_Tab_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  if self.data then
    self.Title:SetText(self.data.name)
    self.Dot:SetupKey(126, {
      self.data.type
    })
  end
end

function UMG_HandBook_RegionalSelection_Tab_C:OnItemSelected(_bSelected)
  if _bSelected then
    self.Dot:SetupKey(0)
  else
    self.Dot:SetupKey(126, {
      self.data.type
    })
  end
  if self.isSelect == _bSelected then
    return
  end
  self:StopAllAnimations()
  self.isSelect = _bSelected
  if _bSelected then
    self:PlayAnimation(self.Press)
    _G.NRCModuleManager:GetModule("HandbookModule"):DispatchEvent(HandbookModuleEvent.OnClickHandbookSeasonTable, self.data.type)
  else
    self:PlayAnimation(self.Normal)
  end
end

function UMG_HandBook_RegionalSelection_Tab_C:OnDeactive()
end

return UMG_HandBook_RegionalSelection_Tab_C

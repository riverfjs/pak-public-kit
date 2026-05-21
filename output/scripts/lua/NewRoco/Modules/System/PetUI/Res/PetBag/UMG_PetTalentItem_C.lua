local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PetTalentItem_C = Base:Extend("UMG_PetTalentItem_C")

function UMG_PetTalentItem_C:OnConstruct()
end

function UMG_PetTalentItem_C:OnDestruct()
end

function UMG_PetTalentItem_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.data = _data
  self.clickToggle = false
  if self.data.filter_enum_name and self.data.filter_enum_value then
    self.enum = _G.Enum[self.data.filter_enum_name][self.data.filter_enum_value]
  end
  self.Text:SetText(self.data.filter_desc)
end

function UMG_PetTalentItem_C:OnItemSelected(_bSelected)
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_BagScrrenItem_C:OnItemSelected")
    self.clickToggle = not self.clickToggle
    if self.clickToggle then
      self:PlayAnimation(self.Press)
    else
      self:PlayAnimation(self.Cancel)
    end
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnChangePetBagFilterToggle, self.data.filter_type, self.enum, self.clickToggle)
  end
end

function UMG_PetTalentItem_C:OnSelect()
  self.clickToggle = true
  self:PlayAnimation(self.Press)
end

function UMG_PetTalentItem_C:OnUnSelect()
  if self.clickToggle then
    self.clickToggle = false
    self:PlayAnimation(self.Cancel)
  end
end

function UMG_PetTalentItem_C:OnDeactive()
end

return UMG_PetTalentItem_C

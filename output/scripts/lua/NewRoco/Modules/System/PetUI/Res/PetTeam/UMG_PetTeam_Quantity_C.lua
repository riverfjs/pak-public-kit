local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PetTeam_Quantity_C = Base:Extend("UMG_PetTeam_Quantity_C")

function UMG_PetTeam_Quantity_C:OnConstruct()
end

function UMG_PetTeam_Quantity_C:OnDestruct()
end

function UMG_PetTeam_Quantity_C:OnItemUpdate(_data, datalist, index)
  self:OnSwitcherSwitcher(0)
end

function UMG_PetTeam_Quantity_C:OnItemSelected(_bSelected)
  if _bSelected then
    self:OnSwitcherSwitcher(1)
    self:PlayAnimation(self.Cut_1)
  else
    self:OnSwitcherSwitcher(0)
    self:PlayAnimation(self.OFF)
  end
end

function UMG_PetTeam_Quantity_C:OnDeactive()
end

function UMG_PetTeam_Quantity_C:OnTick()
end

function UMG_PetTeam_Quantity_C:OnLogin()
end

function UMG_PetTeam_Quantity_C:OnAnimationFinished(anim)
end

function UMG_PetTeam_Quantity_C:OnSwitcherSwitcher(SwitcherIndex)
  self.Switcher:SetActiveWidgetIndex(SwitcherIndex)
end

return UMG_PetTeam_Quantity_C

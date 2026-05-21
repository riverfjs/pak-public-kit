local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_BoxOrganizationFethodItem_C = Base:Extend("UMG_BoxOrganizationFethodItem_C")

function UMG_BoxOrganizationFethodItem_C:OnConstruct()
end

function UMG_BoxOrganizationFethodItem_C:OnDestruct()
end

function UMG_BoxOrganizationFethodItem_C:OnItemUpdate(_data, datalist, index)
  self.conf = _data.conf
  self.parent = _data.parent
  self:InitPanel()
end

function UMG_BoxOrganizationFethodItem_C:InitPanel()
  if self.conf then
    local name = self.conf.sequence_name
    if name then
      self.SortText:SetText(name)
    end
    local icon = self.conf.sequence_icon
    if icon then
      self.HeadIcon:SetPath(icon)
    end
  end
end

function UMG_BoxOrganizationFethodItem_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.Press)
    if self.parent then
      self.parent:OnChooseTidyType(self.conf)
    end
  else
    self:PlayAnimation(self.Cancel)
  end
end

function UMG_BoxOrganizationFethodItem_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_BoxOrganizationFethodItem_C:OnTouchEnded")
  Base.OnTouchEnded(self, _MyGeometry, _TouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_BoxOrganizationFethodItem_C:OnDeactive()
end

return UMG_BoxOrganizationFethodItem_C

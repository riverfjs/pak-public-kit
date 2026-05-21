local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TeachingManual_DotItem_C = Base:Extend("UMG_TeachingManual_DotItem_C")

function UMG_TeachingManual_DotItem_C:OnConstruct()
end

function UMG_TeachingManual_DotItem_C:OnDestruct()
end

function UMG_TeachingManual_DotItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self:StopAllAnimations()
  self.Bright:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TeachingManual_DotItem_C:SelectInfo(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    self.Bright:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.Select)
  else
    self:PlayAnimation(self.Select_not)
  end
end

function UMG_TeachingManual_DotItem_C:OnItemSelected(_bSelected)
  if not _bSelected then
    self:SelectInfo(false)
  end
  if _bSelected then
    _G.NRCModeManager:DoCmd(TeachingManualModuleCmd.SelectViewPicture, self.data, self.index)
  end
end

function UMG_TeachingManual_DotItem_C:OnDeactive()
end

function UMG_TeachingManual_DotItem_C:OnAnimationFinished(Anim)
  if Anim == self.Select_not then
  end
end

return UMG_TeachingManual_DotItem_C

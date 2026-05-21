local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TakePhotos_CameraAppearanceItem_C = Base:Extend("UMG_TakePhotos_CameraAppearanceItem_C")

function UMG_TakePhotos_CameraAppearanceItem_C:OnConstruct()
  self.btnLevelUp:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.SelectedAtEnd = nil
end

function UMG_TakePhotos_CameraAppearanceItem_C:OnDestruct()
end

function UMG_TakePhotos_CameraAppearanceItem_C:OnItemUpdate(_data, datalist, index)
  self.Text_Title:SetText(_data.SkinConf.name)
  self.Image_Icon:SetPath(_data.SkinConf.icon)
  self.Data = _data
  if self.RedDot then
    if _data.RedDotKey then
      self.RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.RedDot:SetupKey(_data.RedDotKey, _data.RedDotExtraKey)
    else
      self.RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TakePhotos_CameraAppearanceItem_C:OnItemSelected(_bSelected)
  if _bSelected then
    if self.RedDot then
      self.RedDot:EraseRedPoint()
    end
    self.Data.OnClicked()
    if not self.SelectedAtEnd then
      self.SelectedAtEnd = true
      self:PlayAnimationForward(self.Selected_in)
    end
  elseif self.SelectedAtEnd then
    self.SelectedAtEnd = false
    self:PlayAnimationReverse(self.Selected_in)
  end
end

return UMG_TakePhotos_CameraAppearanceItem_C

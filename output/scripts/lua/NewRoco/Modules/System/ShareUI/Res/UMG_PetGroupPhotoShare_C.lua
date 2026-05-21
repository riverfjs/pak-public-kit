local UMG_PetGroupPhotoShare_C = _G.NRCPanelBase:Extend("UMG_PetGroupPhotoShare_C")

function UMG_PetGroupPhotoShare_C:OnActive(data)
  if data then
    self.PhotoSub:InitPanel(data)
  end
end

function UMG_PetGroupPhotoShare_C:PlayInAnim()
  self.PhotoSub:PlayAnimation(self.PhotoSub.In_Card)
end

function UMG_PetGroupPhotoShare_C:PlayOutAnim()
  self.PhotoSub:PlayAnimation(self.PhotoSub.Out_Card)
end

function UMG_PetGroupPhotoShare_C:OnDeactive()
end

function UMG_PetGroupPhotoShare_C:OnAddEventListener()
end

function UMG_PetGroupPhotoShare_C:ShowPlayerInfoPanel(isShow)
  if isShow then
    self.PhotoSub.NameText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.UID:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.NameText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PhotoSub.UID:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PetGroupPhotoShare_C

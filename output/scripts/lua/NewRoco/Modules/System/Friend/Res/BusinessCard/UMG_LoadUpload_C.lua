local UMG_LoadUpload_C = _G.NRCViewBase:Extend("UMG_LoadUpload_C")
local EnumPlayFlag = {None = 0, Loop = 1}

function UMG_LoadUpload_C:OnActive()
end

function UMG_LoadUpload_C:OnDeactive()
end

function UMG_LoadUpload_C:OnEnable()
end

function UMG_LoadUpload_C:OnAddEventListener()
end

function UMG_LoadUpload_C:SetCardDownloading()
  self.PlayFlag = EnumPlayFlag.Loop
  self.Text:SetText(LuaText.rolecard_photo_loading)
  self:PlayAnimation(self.Loading)
end

function UMG_LoadUpload_C:SetCardUploading()
  self.PlayFlag = EnumPlayFlag.Loop
  self.Text:SetText(LuaText.rolecard_photo_uploading)
  self:PlayAnimation(self.Loading)
end

function UMG_LoadUpload_C:SetPublishUploading()
  self.PlayFlag = EnumPlayFlag.Loop
  self.Text:SetText(LuaText.home_layout_release_loading)
  self:PlayAnimation(self.Loading)
end

function UMG_LoadUpload_C:SetLoading(msg, isLoop, disableBlur)
  self.Text:SetText(msg)
  self.PlayFlag = isLoop and EnumPlayFlag.Loop or EnumPlayFlag.None
  self:PlayAnimation(self.Loading)
  if self.BackgroundBlur then
    self.BackgroundBlur:SetVisibility(disableBlur and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LoadUpload_C:OnAnimationFinished(Animation)
  if Animation == self.Loading and self.PlayFlag == EnumPlayFlag.Loop then
    self:PlayAnimation(self.Loading)
  end
end

return UMG_LoadUpload_C

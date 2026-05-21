local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TakePhotos_FilmItem_C = Base:Extend("UMG_TakePhotos_FilmItem_C")

function UMG_TakePhotos_FilmItem_C:OnConstruct()
end

function UMG_TakePhotos_FilmItem_C:OnDestruct()
  if self._data and self._data.PhotoData then
    self._data.PhotoData:RemoveTextureReadyDelegate(self, self.OnTextureReady)
  end
end

function UMG_TakePhotos_FilmItem_C:OnTextureReady(Data)
  if self._data and self._data.PhotoData == Data then
    local Texture = Data:GetThumbnailTexture(self._index)
    if Texture then
      self:RefreshTexture(Texture)
    end
  end
end

function UMG_TakePhotos_FilmItem_C:RefreshTexture(Texture)
  self:ToggleDownloadProgressMask(false)
  self.Photograph:SetVisibility(UE.ESlateVisibility.Visible)
  self.NRCImage_Loading:SetVisibility(UE.ESlateVisibility.Collapsed)
  local DesiredWidth, DesiredHeight = self._data:GetDesiredThumbnailSize()
  local ThumbnailWidth = Texture:Blueprint_GetSizeX()
  local ThumbnailHeight = Texture:Blueprint_GetSizeY()
  local ScaleToViewWidth = DesiredWidth / ThumbnailWidth
  local ScaleToViewHeight = DesiredHeight / ThumbnailHeight
  local MaxiScale = math.max(ScaleToViewWidth, ScaleToViewHeight)
  DesiredWidth = MaxiScale * ThumbnailWidth
  DesiredHeight = MaxiScale * ThumbnailHeight
  self.Photograph:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(Texture, math.floor(DesiredWidth), math.floor(DesiredHeight)))
  self.Switcher:SetActiveWidgetIndex(0)
end

function UMG_TakePhotos_FilmItem_C:OnItemUpdate(_data, datalist, index)
  if self._data and _data ~= self._data and self._data.PhotoData then
    self._data.PhotoData:RemoveTextureReadyDelegate(self, self.OnTextureReady)
  end
  self._data = _data
  if _data.SerialId then
    local Texture = _data.PhotoData:GetThumbnailTexture(self._index)
    if Texture then
      self:RefreshTexture(Texture)
    else
      self.Switcher:SetActiveWidgetIndex(0)
      self:ToggleDownloadProgressMask(true)
      self.Photograph:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.NRCImage_Loading:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      _data.PhotoData:AddTextureReadyDelegate(self, self.OnTextureReady)
    end
    if _data.bRemoveMode then
      self.Check:SetVisibility(UE.ESlateVisibility.Visible)
      if _data.bSelected then
        self.Select:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.NRCImage_1:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
      else
        self.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.NRCImage_1:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    else
      self.Check:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  else
    self.Switcher:SetActiveWidgetIndex(1)
  end
  if _data.CreateDateText then
    self.Time:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Time:SetText(_data.CreateDateText)
  else
    self.Time:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self:OnRefreshActivityReportedFlag()
  self:RefreshUploadProgressMask()
end

function UMG_TakePhotos_FilmItem_C:OnRefreshActivityReportedFlag()
  if self._data and self._data.bHasBeenActivityReported then
    self.MarkerPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.MarkerPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self._data.InAlbumSubmitStatus then
    if self._data.bActivityRequiredPhoto then
      self.BgMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      self.BgMask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.BgMask:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_TakePhotos_FilmItem_C:OnItemSelected(_bSelected)
  if _bSelected and self._data.DoSelectDelegate and self._data.DoSelectDelegate() then
    if self._data.bSelected then
      self.Select:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
      self.NRCImage_1:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
      self.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.NRCImage_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TakePhotos_FilmItem_C:OnDeactive()
end

function UMG_TakePhotos_FilmItem_C:RefreshUploadProgressMask()
  if self._data and self._data.bRemoteData then
    self:ToggleUploadProgressMask(false)
    self.Cloud:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    if not (self._data and self._data.PhotoData) or self._data.PhotoData:IsUploadFinish() then
      self:ToggleUploadProgressMask(false)
    else
      self:ToggleUploadProgressMask(true)
    end
    if self._data and self._data.PhotoData and self._data.PhotoData:IsUploadFinish() then
      if self._data.bLocalFileInRemote then
        self.Cloud:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      else
        self.Cloud:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    else
      self.Cloud:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TakePhotos_FilmItem_C:RefreshByUploadRefresh()
  self:RefreshUploadProgressMask()
end

function UMG_TakePhotos_FilmItem_C:ToggleDownloadProgressMask(bEnabled)
  if bEnabled == self.bEnabledDownloadMask then
    return
  end
  self.bEnabledDownloadMask = bEnabled
  local LoadUpload = self.UMG_LoadDownload
  if not LoadUpload then
    return
  end
  LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if bEnabled then
    LoadUpload:SetCardDownloading()
  else
    LoadUpload:StopAllAnimations()
  end
end

function UMG_TakePhotos_FilmItem_C:ToggleUploadProgressMask(bEnabled)
  if bEnabled == self.bEnabledUploadMask then
    return
  end
  self.bEnabledUploadMask = bEnabled
  local LoadUpload = self.UMG_LoadUpload1
  if not LoadUpload then
    return
  end
  LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if bEnabled then
    LoadUpload:SetCardUploading()
  else
    LoadUpload:StopAllAnimations()
  end
end

return UMG_TakePhotos_FilmItem_C

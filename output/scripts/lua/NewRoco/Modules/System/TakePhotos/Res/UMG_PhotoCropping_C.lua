local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local UMG_PhotoCropping_C = _G.NRCPanelBase:Extend("UMG_PhotoCropping_C")
local EnmOpStatus = {
  None = 0,
  Move = 1,
  Scale = 2
}

function UMG_PhotoCropping_C:OnConstruct()
  self.MaxiScale = TakePhotosEnum.TPGlobalNum("takephoto_rolecard_enlarge_max", 20000) / 10000
  self:OnAddEventListener()
end

function UMG_PhotoCropping_C:OnActive(PhotoTexture, OnCroppingFinishDelegate, bUploadToCard, ClipPhoto)
  self.OnCroppingFinishDelegate = OnCroppingFinishDelegate
  self.PhotoTexture = PhotoTexture
  self.bUploadToCard = bUploadToCard
  self.InputClippingPhoto = ClipPhoto
  if ClipPhoto and UE4.UObject.IsValid(ClipPhoto) then
    self.ClippingPhoto = ClipPhoto
    ClipPhoto:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.SelfClippingPhoto:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.ClippingPhoto = self.SelfClippingPhoto
    self.SelfClippingPhoto:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  self.Photo = self.ClippingPhoto.Photo
  self.ClipFrame = self.ClippingPhoto.ClipFrame
  self.ClipFrame:SetClipping(UE.EWidgetClipping.ClipToBounds)
  self.SelfClippingPhoto.ClipFrame:SetClipping(UE.EWidgetClipping.ClipToBounds)
  self:RecordSetting()
  UpdateManager:Register(self)
  self:BindInput()
end

function UMG_PhotoCropping_C:OnDeactive()
  UpdateManager:UnRegister(self)
  if self.InputClippingPhoto then
    self.InputClippingPhoto:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if not self.bSetupEstablished then
    local Module = NRCModuleManager:GetModule("TakePhotosModule")
    if Module then
      Module:DispatchEvent(TakePhotosModuleEvent.OnStopPhotoCropping)
    end
  end
end

function UMG_PhotoCropping_C:BindInput()
  local mappingContext = self:AddInputMappingContext("IMC_PhotoCropping")
  if mappingContext and mappingContext then
    local actions = {
      {
        name = "IA_MouseWheelUp_Home",
        method = "OnPcWheelUp"
      },
      {
        name = "IA_MouseWheelDown_Home",
        method = "OnPcWheelDown"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
  end
end

function UMG_PhotoCropping_C:OnPcWheelUp()
  self.ThisFrameWheelNum = 1
end

function UMG_PhotoCropping_C:OnPcWheelDown()
  self.ThisFrameWheelNum = -1
end

function UMG_PhotoCropping_C:OnAddEventListener()
  self:AddButtonListener(self.Rotation.btnLevelUp, self.ResetSetting)
  self:AddButtonListener(self.Confirm.btnLevelUp, self.OnConfirm)
  self:AddButtonListener(self.Btn_Exit.btnClose, self.OnBtnClose)
end

function UMG_PhotoCropping_C:RecordSetting()
  local PhotoRawSize = UE.FVector2D(1, 1)
  if self.PhotoTexture then
    PhotoRawSize = UE.FVector2D(self.PhotoTexture:Blueprint_GetSizeX(), self.PhotoTexture:Blueprint_GetSizeY())
  end
  UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Photo):SetSize(PhotoRawSize)
  self.Photo:SetBrushFromTexture(self.PhotoTexture, true)
  self.PhotoSize = PhotoRawSize
  self.ClipFrameSize = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ClipFrame):GetSize()
  self.ClipFrameHalfSize = self.ClipFrameSize / 2
  local InvScaleVecToAlign = PhotoRawSize / self.ClipFrameSize
  local InvScaleToAlign = math.min(InvScaleVecToAlign.X, InvScaleVecToAlign.Y)
  local ScaleToAlign = 1.0 / InvScaleToAlign
  self.MinAlignScale = ScaleToAlign
  if self.MinAlignScale > 1 then
    self.Photo.RenderTransform.Scale.X = ScaleToAlign
    self.Photo.RenderTransform.Scale.Y = ScaleToAlign
    self.Photo:SetRenderTransform(self.Photo.RenderTransform)
  end
  self:Log("MinAlignScale=", self.MinAlignScale)
  local Translation = self.Photo.RenderTransform.Translation
  local Scale = self.Photo.RenderTransform.Scale
  self.PhotoTranslation = UE.FVector2D(Translation.X, Translation.Y)
  self.PhotoScale = UE.FVector2D(Scale.X, Scale.Y)
  self.CurState = EnmOpStatus.None
  self.ClipFrame.Clipping = UE.EWidgetClipping.OnDemand
end

function UMG_PhotoCropping_C:ResetSetting()
  _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_PhotoCropping_C:ResetSetting")
  self.Photo.RenderTransform.Scale.X = self.PhotoScale.X
  self.Photo.RenderTransform.Scale.Y = self.PhotoScale.Y
  self.Photo.RenderTransform.Translation.X = self.PhotoTranslation.X
  self.Photo.RenderTransform.Translation.Y = self.PhotoTranslation.Y
  self.Photo:SetRenderTransform(self.Photo.RenderTransform)
end

function UMG_PhotoCropping_C:OnConfirm()
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_PhotoCropping_C:OnConfirm")
  local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempPhotos"
  })
  if self.bUploadToCard then
    TempPhotos = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "CommonUrlImages",
      "CardPhotos"
    })
  end
  if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
    UE.UNRCStatics.MakeDirectory(TempPhotos)
  end
  local PhotoPath = UE.UBlueprintPathsLibrary.Combine({
    TempPhotos,
    string.format("%d%d", _G.DataModelMgr.PlayerDataModel:GetPlayerUin(), math.floor(_G.ZoneServer:GetServerTime()))
  })
  if UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), self.ClippingPhoto, PhotoPath) then
    if not self.bUploadToCard then
      if self.OnCroppingFinishDelegate then
        self.OnCroppingFinishDelegate(PhotoPath)
      end
    else
      self:InternalUpload(PhotoPath)
    end
  end
end

function UMG_PhotoCropping_C:OnBtnClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_PhotoCropping_C:OnBtnClose")
  self:OnReqClose()
end

function UMG_PhotoCropping_C:OnReqClose()
  self:OnClose()
end

function UMG_PhotoCropping_C:IfPosInWidget(Box, ScreenX, ScreenY)
  local TouchScreenPoint = UE.FVector2D(ScreenX, ScreenY)
  local TouchAreaGeo = Box:GetCachedGeometry()
  return UE4.USlateBlueprintLibrary.IsUnderLocation(TouchAreaGeo, TouchScreenPoint)
end

function UMG_PhotoCropping_C:OnTick()
  if self.bLockInput then
    self.CurState = EnmOpStatus.None
    return
  end
  local locationX0, locationY0, bPressed0 = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(0)
  local locationX1, locationY1, bPressed1 = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(1)
  local bInvalid0 = bPressed0 and not self:IfPosInWidget(self.NRCImage_30, locationX0, locationY0)
  local bInvalid1 = bPressed1 and not self:IfPosInWidget(self.NRCImage_30, locationX1, locationY1)
  if bPressed0 and bInvalid0 then
    bPressed0 = false
  end
  if bPressed1 and bInvalid1 then
    bPressed1 = false
  end
  if bPressed0 and bPressed1 then
    self:TickScale(locationX0, locationY0, locationX1, locationY1)
  elseif bPressed0 then
    self:TickTranslate(locationX0, locationY0)
  elseif bPressed1 then
    self:TickTranslate(locationX1, locationY1)
  elseif self.ThisFrameWheelNum then
    local Num = self.ThisFrameWheelNum
    self.ThisFrameWheelNum = nil
    local Scale = 0.05 * Num
    self:TickWheel(Scale)
  else
    self.CurState = EnmOpStatus.None
  end
end

function UMG_PhotoCropping_C:TickWheel(WheelNum)
  if self.bLockInput then
    return
  end
  local Scale = self.Photo.RenderTransform.Scale.Y + WheelNum
  Scale = math.clamp(Scale, self.MinAlignScale, self.MaxiScale)
  self.Photo.RenderTransform.Scale.Y = Scale
  self.Photo.RenderTransform.Scale.X = Scale
  self:Constraints()
  self.Photo:SetRenderTransform(self.Photo.RenderTransform)
end

function UMG_PhotoCropping_C:TickScale(locationX0, locationY0, locationX1, locationY1)
  local Dist = UE.FVector2D.Dist(UE.FVector2D(locationX0, locationY0), UE.FVector2D(locationX1, locationY1))
  if self.CurState ~= EnmOpStatus.Scale then
    self.CurState = EnmOpStatus.Scale
    self.ScaleDist = Dist
    self.InputScale = self.Photo.RenderTransform.Scale.X
  else
    local Scale = Dist / self.ScaleDist * self.InputScale
    Scale = math.clamp(Scale, self.MinAlignScale, self.MaxiScale)
    self.Photo.RenderTransform.Scale.X = Scale
    self.Photo.RenderTransform.Scale.Y = Scale
    self:Constraints()
    self.Photo:SetRenderTransform(self.Photo.RenderTransform)
  end
end

function UMG_PhotoCropping_C:TickTranslate(X, Y)
  if self.CurState ~= EnmOpStatus.Move then
    self.CurState = EnmOpStatus.Move
    self.MoveX = X
    self.MoveY = Y
    self.InputTranslationX = self.Photo.RenderTransform.Translation.X
    self.InputTranslationY = self.Photo.RenderTransform.Translation.Y
  else
    local DiffX = X - self.MoveX
    local DiffY = Y - self.MoveY
    self.MoveX = X
    self.MoveY = Y
    self.InputTranslationX = self.InputTranslationX + DiffX
    self.InputTranslationY = self.InputTranslationY + DiffY
    self.Photo.RenderTransform.Translation.X = self.InputTranslationX
    self.Photo.RenderTransform.Translation.Y = self.InputTranslationY
    self:Constraints()
    self.Photo:SetRenderTransform(self.Photo.RenderTransform)
  end
end

function UMG_PhotoCropping_C:Constraints()
  local Transform = self.Photo.RenderTransform
  local Pos = Transform.Translation
  local Size = Transform.Scale * self.PhotoSize
  local HalfSize = Size / 2
  local DownRight = Pos + HalfSize
  local TopLeft = Pos - HalfSize
  if DownRight.X < self.ClipFrameHalfSize.X then
    DownRight.X = self.ClipFrameHalfSize.X
    Pos.X = DownRight.X - HalfSize.X
  end
  if DownRight.Y < self.ClipFrameHalfSize.Y then
    DownRight.Y = self.ClipFrameHalfSize.Y
    Pos.Y = DownRight.Y - HalfSize.Y
  end
  if TopLeft.X > -self.ClipFrameHalfSize.X then
    TopLeft.X = -self.ClipFrameHalfSize.X
    Pos.X = TopLeft.X + HalfSize.X
  end
  if TopLeft.Y > -self.ClipFrameHalfSize.Y then
    TopLeft.Y = -self.ClipFrameHalfSize.Y
    Pos.Y = TopLeft.Y + HalfSize.Y
  end
  Transform.Translation = Pos
end

function UMG_PhotoCropping_C:InternalUpload(FilePath)
  self.Rotation:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.Confirm:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.Btn_Exit:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.bLockInput = true
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    self:ToggleUploadProgressMask(true)
    Module:UploadCard(FilePath, FPartial(self.OnUploadFinish, self, FilePath))
  end
end

function UMG_PhotoCropping_C:OnUploadFinish(PhotoPath, bSuccess)
  if not self.enableView then
    return
  end
  self:ToggleUploadProgressMask(false)
  if bSuccess then
    self.bSetupEstablished = true
    if self.OnCroppingFinishDelegate then
      self.OnCroppingFinishDelegate(PhotoPath)
    end
    self:OnReqClose()
  else
    self.Rotation:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Confirm:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_Exit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.bLockInput = false
  end
end

function UMG_PhotoCropping_C:ToggleUploadProgressMask(bEnabled)
  if bEnabled == self.bEnabledUploadMask then
    return
  end
  self.bEnabledUploadMask = bEnabled
  if not self.NRCWidgetLoader_LoadUpload then
    return
  end
  self.NRCWidgetLoader_LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if not self.NRCWidgetLoader_LoadUpload:GetPanel() then
    self.NRCWidgetLoader_LoadUpload:LoadPanelSync(self)
  end
  if bEnabled then
    local panel = self.NRCWidgetLoader_LoadUpload:GetPanel()
    if panel then
      panel:SetCardUploading()
    end
  else
    local panel = self.NRCWidgetLoader_LoadUpload:GetPanel()
    if panel then
      panel:StopAllAnimations()
    end
  end
end

return UMG_PhotoCropping_C

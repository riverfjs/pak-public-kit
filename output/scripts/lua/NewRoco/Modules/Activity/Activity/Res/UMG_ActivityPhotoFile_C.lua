local PhotoDisplayUtils = require("NewRoco.Modules.System.TakePhotos.Common.PhotoDisplayUtils")
local PhotoDisplayProxy = require("NewRoco.Modules.System.TakePhotos.Common.PhotoDisplayProxy")
local CdnResChecker = require("NewRoco.Modules.System.TakePhotos.Common.CdnResChecker")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_ActivityPhotoFile_C = _G.NRCViewBase:Extend("UMG_ActivityPhotoFile_C")

function UMG_ActivityPhotoFile_C:OnConstruct()
  self.DisplayProxy = PhotoDisplayProxy(self, self.Photo, PhotoDisplayUtils.PhotoCacheDefine.Tags.PhotoActivity)
  self.DisplayProxy.OnReadyDelegate:Add(self, self.OnTextureReady)
  self.cdnResChecker = CdnResChecker(self, self.OnPhotoMissing)
  self.Text:SetText(_G.LuaText.pic_game_photo_error)
  self:SetWaterMaskEnabled(false)
end

function UMG_ActivityPhotoFile_C:OnDestruct()
  if self.DisplayProxy then
    self.DisplayProxy:Destroy()
    self.DisplayProxy = nil
  end
end

function UMG_ActivityPhotoFile_C:DisplayFixedFramePhotoMiniMode(Url, Md5, DisplaySize, bEnableFrame)
  if not Url or not Md5 then
    self:LogError("Invalid")
    return
  end
  self.bDirty = true
  self.bEmptyDirty = true
  self.bInRawMode = false
  self.MarkExtraData = nil
  self.FileTexture2D = nil
  self.OverrideHeight = nil
  self.OverrideWidth = nil
  self.OverrideDisplaySize = DisplaySize
  self:ToggleLoadingProgressMask(true)
  
  function self.DisplayImpl(Size)
    if "" ~= Url and "" ~= Md5 then
      PhotoDisplayUtils.DisplayActivityPhotoMiniMode(Url, Md5, self.DisplayProxy, Size.X, Size.Y)
    else
      self:LogError("Invalid Url=", Url, "Md5=", Md5)
    end
  end
  
  if bEnableFrame then
    self.NRCImage_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_Frame_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NRCImage_Frame_1:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.cdnResChecker:SetUrl(Url) then
    self.lastCheckTime = 0
    self.cdnResChecker:SetVerificationKeys("Content-Type", "image/png")
  end
end

function UMG_ActivityPhotoFile_C:DisplayRawPhoto(Url, Md5, AutoDisplayCanvas, ActivityPhotoFile, MarkExtraData)
  if not Url or not Md5 then
    self:LogError("Invalid")
    return
  end
  assert(AutoDisplayCanvas)
  assert(AutoDisplayCanvas.Slot)
  self.AutoDisplayCanvas = AutoDisplayCanvas
  self.bDirty = true
  self.bEmptyDirty = true
  self.bInRawMode = true
  self.MarkExtraData = MarkExtraData
  self.FileTexture2D = nil
  self.OverrideHeight = nil
  self.OverrideWidth = nil
  self.OverrideDisplaySize = nil
  if "" ~= Url then
    local FileName, rawWidth, rawHeight = PhotoDisplayUtils.ParseActivityPhotoParams(Url)
    self.OverrideHeight = rawHeight
    self.OverrideWidth = rawWidth
  end
  self:ToggleLoadingProgressMask(true)
  
  function self.DisplayImpl(Size)
    if "" ~= Url and "" ~= Md5 then
      PhotoDisplayUtils.DisplayActivityPhotoRawMode(Url, Md5, self.DisplayProxy)
    else
      self:LogError("Invalid Url=", Url, "Md5=", Md5)
    end
  end
  
  self.NRCImage_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.NRCImage_Frame_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  if ActivityPhotoFile and "" ~= Url and ActivityPhotoFile.FileTexture2D and UE.UObject.IsValid(ActivityPhotoFile.FileTexture2D) then
    local FileName, rawWidth, rawHeight = PhotoDisplayUtils.ParseActivityPhotoParams(Url)
    self.DisplayProxy:SetDisplayRawMode(rawWidth, rawHeight)
    self.DisplayProxy:InternalRefreshTexture(ActivityPhotoFile.FileTexture2D)
  end
  self.cdnResChecker:SetUrl(nil)
end

function UMG_ActivityPhotoFile_C:Tick(MyGeometry, Dt)
  self.MyLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(MyGeometry)
  local CacheSize = UE.USlateBlueprintLibrary.GetLocalSize(self:GetCachedGeometry())
  if self.bDirty and CacheSize.X > 0 and CacheSize.Y > 0 then
    local Size = self.OverrideDisplaySize or self.MyLocalSize
    self:Log("Display", self.bInRawMode, Size)
    if Size.X > 0 and Size.Y > 0 then
      self.bDirty = false
      self.DisplayImpl(Size)
    end
  end
  if self.bInRawMode then
    self:UpdateTransform()
  end
  if not self.FileTexture2D then
    self:UpdateEmptyPhoto()
  end
  if self.cdnResChecker then
    local curTimestamp = _G.UpdateManager.Timestamp
    local lastCheckTime = self.lastCheckTime or 0
    if curTimestamp - lastCheckTime >= 30 then
      self.lastCheckTime = curTimestamp
      self.cdnResChecker:Check()
    end
  end
end

function UMG_ActivityPhotoFile_C:OnTextureReady(Texture)
  self.FileTexture2D = Texture
  self:ToggleLoadingProgressMask(false)
end

function UMG_ActivityPhotoFile_C:SetWaterMaskEnabled(bEnable)
  if bEnable then
    self.Text_WaterMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Text_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_Logo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
    self.Text_Name:SetText(PlayerInfo.name)
    self.Text_WaterMark:SetText(string.format("UID:%s", PlayerInfo.uin))
    local CustomData = self.MarkExtraData
    if CustomData then
      self.VerticalBox_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.ActivityName:SetText(CustomData.ActivityName or "")
      local Number = string.format("%02d", (CustomData.PhaseNumber or 0) % 10)
      self.IssueNumber:SetText(string.format(LuaText.pic_game_count, Number))
      self.Topic:SetText(CustomData.PhaseName or "")
    else
      self.VerticalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  else
    self.VerticalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Text_WaterMark:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Text_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NRCImage_Logo:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_ActivityPhotoFile_C:OnDownloading()
end

function UMG_ActivityPhotoFile_C:ToggleLoadingProgressMask(bEnabled)
  if bEnabled == self.bEnabledUploadMask then
    return
  end
  self.bEnabledUploadMask = bEnabled
  if not self.LoadUpload then
    return
  end
  self.LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  self.EmptyPhoto:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if bEnabled and self.LoadUpload and self.LoadUpload.BackgroundBlur then
    self.LoadUpload.BackgroundBlur:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if bEnabled then
    self.LoadUpload:SetCardDownloading()
  else
    self.LoadUpload:StopAllAnimations()
  end
end

local EMPTY_POS_2D = UE.FVector2D(0, 0)

function UMG_ActivityPhotoFile_C:UpdateEmptyPhoto()
  if self.EmptyPhoto:IsVisible() or self.EmptyPhoto_1:IsVisible() then
    local Size = self.OverrideDisplaySize or self.MyLocalSize
    if self.OverrideWidth or Size.X > 0 and Size.Y > 0 then
      self.EmptyPhoto.Slot:SetAutoSize(true)
      self.EmptyPhoto_1.Slot:SetAutoSize(true)
      local Scale = math.max(Size.X / 1024, Size.Y / 512)
      local DesiredSize = UE.FVector2D(Scale * 1024, Scale * 512)
      self.EmptyPhoto:SetBrushSize(DesiredSize)
      self.EmptyPhoto_1:SetBrushSize(DesiredSize)
      self.EmptyPhoto.Slot:SetPosition(EMPTY_POS_2D)
      self.EmptyPhoto_1.Slot:SetPosition(EMPTY_POS_2D)
    end
  end
end

function UMG_ActivityPhotoFile_C:UpdateTransform()
  local CustomDisplayCanvas = self.AutoDisplayCanvas
  if not CustomDisplayCanvas then
    return
  end
  local OverrideWidth = self.OverrideWidth
  local OverrideHeight = self.OverrideHeight
  if self.FileTexture2D and UE.UObject.IsValid(self.FileTexture2D) or OverrideWidth and OverrideHeight then
    local world = _G.UE4Helper.GetCurrentWorld()
    local dpi = UE.UWidgetLayoutLibrary.GetViewportScale(world)
    local Width = OverrideWidth or self.FileTexture2D:Blueprint_GetSizeX()
    local Height = OverrideHeight or self.FileTexture2D:Blueprint_GetSizeY()
    local DesiredViewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(world)
    local DeltaWidth = DesiredViewportSize.X / Width
    local DeltaHeight = DesiredViewportSize.Y / Height
    local DesiredHeight = 0
    local DesiredWidth = 0
    local Scale = 1 / dpi
    if math.abs(DeltaWidth) >= math.abs(DeltaHeight) then
      DesiredHeight = DesiredViewportSize.Y * Scale
      DesiredWidth = DesiredHeight * Width / Height
    else
      DesiredWidth = DesiredViewportSize.X * Scale
      DesiredHeight = DesiredWidth * Height / Width
    end
    local CanvasSlot = CustomDisplayCanvas.Slot
    local Padding = CanvasSlot:GetOffsets()
    Padding.Left = -DesiredWidth / 2
    Padding.Top = -DesiredHeight / 2
    Padding.Right = DesiredWidth
    Padding.Bottom = DesiredHeight
    CanvasSlot:SetOffsets(Padding)
  end
end

function UMG_ActivityPhotoFile_C:ReqDownloadSaveAlbum()
  local PhotoPath = self.DisplayProxy:GetValidPhotoPath()
  if "" == PhotoPath then
    return false
  end
  if not UE.UNRCStatics.FileExists(PhotoPath) then
    return false
  end
  if not self.FileTexture2D then
    return false
  end
  if self.bEnabledUploadMask then
    return
  end
  local FileName = self.DisplayProxy:GetFileName()
  FileName = string.format("%s0.png", FileName)
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  
  local function OnPermissionCallback()
    if not UE.UObject.IsValid(self) then
      self:LogError("Invalid UserWidget")
      return
    end
    local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
      UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "TempPhotos"
    })
    if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
      UE.UNRCStatics.MakeDirectory(TempPhotos)
    end
    local TempPhotoPath = UE.UBlueprintPathsLibrary.Combine({TempPhotos, FileName})
    TempPhotoPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(TempPhotoPath)
    local Width = self.FileTexture2D:Blueprint_GetSizeX()
    local Height = self.FileTexture2D:Blueprint_GetSizeY()
    local DesiredSize = UE.FVector2D(Width, Height)
    self:RefreshInnerWaterMaskImmediate()
    local Result = UE.UPlatformImageLibrary.SaveUserWidgetToImageByCustomSize(UE4Helper.GetCurrentWorld(), self, TempPhotoPath, DesiredSize)
    self:CloseInnerWaterMaskImmediate()
    if Result then
      self:Log("Saved:", TempPhotoPath)
      UE.UPlatformImageLibrary.SaveImageToAlbum(TempPhotoPath)
      if RocoEnv.PLATFORM_WINDOWS then
        if RocoEnv.IS_EDITOR then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\231\188\150\232\190\145\229\153\168\228\191\157\229\173\152\229\136\176:Saved\\PhotoScreenshots")
        elseif RocoEnv.PLATFORM_OPENHARMONY then
          return
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.PC_Photo_Save_Tips)
        end
      elseif RocoEnv.PLATFORM_OPENHARMONY then
        return
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_save_succeed)
      end
    end
  end
  
  local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.AccessAlbum)
  if not bGranted and (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS) then
    self.requestCode = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.AccessAlbum, {
      self,
      function(_, bGranted)
        self.requestCode = nil
        if bGranted then
          OnPermissionCallback()
        else
          self:LogError("[TakePhotos] !!!Permission!!!")
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.takephoto_save_fail)
        end
      end
    })
  else
    OnPermissionCallback()
  end
  return true
end

function UMG_ActivityPhotoFile_C:ReqSharePhoto()
  local PhotoPath = self.DisplayProxy:GetValidPhotoPath()
  if not PhotoPath then
    Log.Error("Invalid PhotoPath")
    return
  end
  if not self.DisplayProxy.LoadingInfo then
    Log.Error("Invalid LoadingInfo")
    return
  end
  if self.MarkExtraData and self.MarkExtraData:GetPlayerName() ~= "" then
    self.MarkExtraData.PlayerName = self.MarkExtraData:GetPlayerName()
    NRCModuleManager:GetModule("TakePhotosModule"):OpenSharePhotoPanel(PhotoPath, true, self.MarkExtraData, self.DisplayProxy.LoadingInfo.Md5)
  else
    self:LogError("Invalid PlayerName", self.MarkExtraData.PhotoUin)
  end
end

function UMG_ActivityPhotoFile_C:OnPhotoMissing()
  self.PhotoSwitcher:SetActiveWidgetIndex(1)
end

function UMG_ActivityPhotoFile_C:RefreshInnerWaterMaskImmediate()
  if not self.MarkCanvas then
    return
  end
  UIUtils.RefreshWaterMaskImmediate(self)
end

function UMG_ActivityPhotoFile_C:CloseInnerWaterMaskImmediate()
  if not self.MarkCanvas then
    return
  end
  self.MarkCanvas:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return UMG_ActivityPhotoFile_C

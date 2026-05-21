local UMG_TakephotoShare_C = _G.NRCPanelBase:Extend("UMG_TakephotoShare_C")

function UMG_TakephotoShare_C:OnActive(data)
  self.data = data
  self:RefreshAvatar()
  self:RefreshPhotoData()
  _G.UpdateManager:Register(self)
end

function UMG_TakephotoShare_C:OnTick(InDeltaTime)
  self:UpdateTransform()
end

function UMG_TakephotoShare_C:UpdateTransform()
  if self.FileTexture then
    local dpi = UE.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
    local Width = self.FileTexture:Blueprint_GetSizeX()
    local Height = self.FileTexture:Blueprint_GetSizeY()
    local DesiredViewportSize = self:GetScreenSize()
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
    local CanvasSlot = self.CanvasPanel_153.Slot
    local Padding = CanvasSlot:GetOffsets()
    Padding.Left = -DesiredWidth / 2
    Padding.Top = -DesiredHeight / 2
    Padding.Right = DesiredWidth
    Padding.Bottom = DesiredHeight
    CanvasSlot:SetOffsets(Padding)
  end
end

function UMG_TakephotoShare_C:OnDeactive()
  if self.data and self.data.photoData then
    local PhotoTexture = self.data.photoData.PhotoTexture
    if PhotoTexture and UE.UObject.IsValid(PhotoTexture) then
      UnLua.Unref(PhotoTexture)
    end
  end
  self.data = nil
  _G.UpdateManager:UnRegister(self)
end

function UMG_TakephotoShare_C:GetScreenSize()
  local Size = UE.FIntPoint(0, 0)
  local viewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local borderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
  local borderHeight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
  viewportSize.X = viewportSize.X - borderWidth * 2
  viewportSize.Y = viewportSize.Y - borderHeight * 2
  Size.X = math.floor(viewportSize.X)
  Size.Y = math.floor(viewportSize.Y)
  return Size
end

function UMG_TakephotoShare_C:RefreshPhotoData()
  if not self.data.photoData then
    return
  end
  local FileTexture, Path = self:GetPhotoTexture()
  self.FileTexture = FileTexture
  if FileTexture then
    self.PhotoSub.Photo:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(FileTexture))
    self.PhotoSub.Photo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.Photo:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self:UpdateTransform()
end

function UMG_TakephotoShare_C:RefreshAvatar()
  if not self.data.photoData then
    return
  end
  local bEnableWaterMask = self.data.photoData.bWaterMaskEnabled
  if bEnableWaterMask then
    self.PhotoSub.Text_WaterMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.HeadPortrait:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoSub.Text_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.NRCImage_Logo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.BG:SetVisibility(UE.ESlateVisibility.Collapsed)
    local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
    local CardInfo = PlayerInfo.additional_data.card_brief_info
    if CardInfo then
      local CardIconConf = _G.DataConfigManager:GetCardIconConf(CardInfo.card_icon_selected)
      if CardIconConf then
        local AvatarPath = CardIconConf.icon_resource_path
        AvatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/", AvatarPath, AvatarPath)
        self.PhotoSub.HeadPortrait:SetPath(AvatarPath)
      end
    else
      Log.Error("\230\178\161\230\156\137\233\187\152\232\174\164\229\144\141\231\137\135\229\164\180\229\131\143\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\144\142\229\143\176\230\149\176\230\141\174")
    end
    self.PhotoSub.Text_Name:SetText(PlayerInfo.name)
    self.PhotoSub.Text_WaterMark:SetText(string.format("UID:%s", PlayerInfo.uin))
    local CustomData = self.data.photoData.CustomData
    if CustomData then
      self.PhotoSub.Text_Name:SetText(CustomData.PlayerName)
      self.PhotoSub.VerticalBox_0:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.PhotoSub.ActivityName:SetText(CustomData.ActivityName or "")
      local Number = string.format("%02d", (CustomData.PhaseNumber or 0) % 10)
      self.PhotoSub.IssueNumber:SetText(string.format(LuaText.pic_game_count, Number))
      self.PhotoSub.Topic:SetText(CustomData.PhaseName or "")
      local bEnableSelfInfo = CustomData.PhotoUin == PlayerInfo.uin
      if not bEnableSelfInfo then
        self.PhotoSub.Text_WaterMark:SetVisibility(UE.ESlateVisibility.Collapsed)
      else
        self.PhotoSub.Text_WaterMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      self.PhotoSub.VerticalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  else
    self.PhotoSub.VerticalBox_0:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoSub.Text_WaterMark:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoSub.HeadPortrait:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoSub.Text_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoSub.NRCImage_Logo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PhotoSub.BG:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_TakephotoShare_C:GetPhotoTexture()
  local PhotoTexture = self.data.photoData.PhotoTexture
  if PhotoTexture and UE.UObject.IsValid(PhotoTexture) then
    return PhotoTexture
  end
  local PhotoPath = self.data.photoData.PhotoPath
  if PhotoPath then
    local Md5 = UE.UNRCStatics.HashFileMD5(PhotoPath)
    local DesiredMd5 = self.data.photoData.Md5
    if DesiredMd5 and Md5 ~= DesiredMd5 then
      Log.Error("Invalid Md5")
      return nil
    end
    PhotoTexture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(UE4Helper.GetCurrentWorld(), PhotoPath)
    if PhotoTexture then
      self.data.photoData.PhotoTextureRef = UnLua.Ref(PhotoTexture)
    end
  end
  return PhotoTexture
end

function UMG_TakephotoShare_C:ShowPlayerInfoPanel(isShow)
  if isShow then
    local bEnableWaterMask = self.data.photoData.bWaterMaskEnabled
    if bEnableWaterMask then
      self.PhotoSub.Text_Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PhotoSub.HeadPortrait:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PhotoSub.Text_WaterMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PhotoSub.BG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.PhotoSub.Text_Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PhotoSub.HeadPortrait:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PhotoSub.Text_WaterMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PhotoSub.BG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.PhotoSub.Text_Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PhotoSub.HeadPortrait:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PhotoSub.Text_WaterMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PhotoSub.BG:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_TakephotoShare_C

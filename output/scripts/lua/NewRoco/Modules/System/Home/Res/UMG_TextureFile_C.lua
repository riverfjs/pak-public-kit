local UMG_TextureFile_C = _G.NRCViewBase:Extend("UMG_TextureFile_C")

function UMG_TextureFile_C:OnActive()
end

function UMG_TextureFile_C:SetTexture(FileTexture, ContentSlot)
  assert(FileTexture)
  assert(ContentSlot)
  self.World = UE4Helper.GetCurrentWorld()
  self.FileTexture = FileTexture
  self.ContentSlot = ContentSlot
  self.Photo:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(FileTexture))
  self:UpdateTransform()
end

function UMG_TextureFile_C:Tick(MyGeometry, Dt)
  self:UpdateTransform()
end

function UMG_TextureFile_C:UpdateTransform()
  if self.FileTexture and self.ContentSlot then
    local dpi = UE.UWidgetLayoutLibrary.GetViewportScale(self.World)
    local size = UE.UWidgetLayoutLibrary.GetViewportSize(self.World)
    local Width = self.FileTexture:Blueprint_GetSizeX()
    local Height = self.FileTexture:Blueprint_GetSizeY()
    local DesiredViewportSize = size
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
    local CanvasSlot = self.ContentSlot
    local Padding = CanvasSlot:GetOffsets()
    Padding.Left = -DesiredWidth / 2
    Padding.Top = -DesiredHeight / 2
    Padding.Right = DesiredWidth
    Padding.Bottom = DesiredHeight
    CanvasSlot:SetOffsets(Padding)
  end
end

return UMG_TextureFile_C

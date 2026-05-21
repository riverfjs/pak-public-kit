local UMG_ViewPhoto_C = _G.NRCPanelBase:Extend("UMG_ViewPhoto_C")

function UMG_ViewPhoto_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_ViewPhoto_C:OnAddEventListener()
  self:AddButtonListener(self.FullScreen_Close, self.OnReqClose)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnReqClose)
end

function UMG_ViewPhoto_C:OnReqClose()
  if self.bPendingClose then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_ViewPhoto_C:OnReqClose")
  self.bPendingClose = true
  self:DoClose()
end

function UMG_ViewPhoto_C:OnActive(DisplayData)
  if not DisplayData then
    return
  end
  local TexturePath = DisplayData.TexturePath
  local FurnitureName = DisplayData.FurnitureName
  self:SetTextureByPath(TexturePath)
  self.PhotoName:SetText(FurnitureName or "")
end

function UMG_ViewPhoto_C:OnDeactive()
end

function UMG_ViewPhoto_C:SetTextureByPath(TexturePath)
  if not TexturePath or "" == TexturePath then
    self:LogError("Invalid TexturePath", TexturePath)
    return
  end
  if TexturePath ~= self.TexturePath then
    self.TexturePath = TexturePath
    self.TextureFile:SetVisibility(UE.ESlateVisibility.Hidden)
    self:InternalLoadTexture()
  end
end

function UMG_ViewPhoto_C:InternalLoadTexture()
  if self.TextureLoadRequest then
    assert(self.TexturePath)
    self:UnLoadResByPath(self.TexturePath)
    self.TextureLoadRequest = nil
  end
  self.TextureLoadRequest = self:LoadPanelRes(self.TexturePath, 255, self.OnTextureLoaded)
end

function UMG_ViewPhoto_C:OnTextureLoaded(req, Texture)
  if Texture and UE.UObject.IsValid(Texture) then
    self.TextureFile:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextureFile:SetTexture(Texture, self.Content.Slot)
  else
    self:LogError("Invalid Texture")
  end
end

return UMG_ViewPhoto_C

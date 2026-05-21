local UMG_TraceIconHero_C = _G.NRCPanelBase:Extend("UMG_TraceIconHero_C")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")

function UMG_TraceIconHero_C:OnConstruct()
  self:SetVisible(false)
  self.NRCButton_ClickRange.OnClicked:Add(self, self.OnClickRange)
end

function UMG_TraceIconHero_C:OnDestruct()
  self.uiData = nil
  self.NRCButton_ClickRange.OnClicked:Remove(self, self.OnClickRange)
end

function UMG_TraceIconHero_C:OnClickRange()
  Log.Debug("UMG_TraceIconHero_C:OnClickRange")
  local BigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  BigMapModule:DispatchEvent(BigMapModuleEvent.ClickTraceIconEvent, self)
end

function UMG_TraceIconHero_C:SetData(_data)
  self.uiData = _data
  self:UpdatePanel()
end

function UMG_TraceIconHero_C:IsUsable()
  return true
end

function UMG_TraceIconHero_C:GetData()
  return self.uiData
end

function UMG_TraceIconHero_C:GetImagePosition()
  if self.uiData then
    return self.uiData.imagePosX or 0, self.uiData.imagePosY or 0
  else
    return 0, 0
  end
end

function UMG_TraceIconHero_C:UpdateImagePosition(_posX, _posY)
  local uiData = self.uiData
  uiData.imagePosX = _posX or 0
  uiData.imagePosY = _posY or 0
end

function UMG_TraceIconHero_C:SetVisible(_isVisible)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.isVisible == _isVisible then
    return
  end
  self.isVisible = _isVisible
  if self.isVisible then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TraceIconHero_C:UpdatePanel()
  local uiData = self.uiData
  self:SetIconDir(uiData.heroDir)
end

function UMG_TraceIconHero_C:SetArrowDir(_angle)
  local dirMat = self.dirIcon1:GetDynamicMaterial()
  if dirMat then
    dirMat:SetScalarParameterValue("Angle", 90 - _angle)
  end
  self.dirIcon1:SetRenderTransformAngle(90 - _angle)
end

function UMG_TraceIconHero_C:SetIconDir(dir)
  local dirMat = self.heroIcon.HeroIcon1:GetDynamicMaterial()
  if dirMat then
    dirMat:SetScalarParameterValue("Angle", dir or 0)
  end
  self.heroIcon:SetRenderTransformAngle(dir or 0)
end

function UMG_TraceIconHero_C:GetSceneResId()
  return self.uiData.sceneResId
end

return UMG_TraceIconHero_C

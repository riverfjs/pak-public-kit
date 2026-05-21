local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UMG_IconVisit_C = _G.NRCPanelBase:Extend("UMG_IconVisit_C")

function UMG_IconVisit_C:OnConstruct()
end

function UMG_IconVisit_C:OnActive()
end

function UMG_IconVisit_C:Destruct()
end

function UMG_IconVisit_C:OnDeactive()
end

function UMG_IconVisit_C:SetMarkerIndex(data, _Index)
  self.uiData = data
  self.index = _Index
  self.SerialNumber:SetText(_Index)
  self.SerialNumber_1:SetText(_Index)
  self.Switcher:SetActiveWidgetIndex(0)
end

function UMG_IconVisit_C:UpdateMapShowLevel(_level)
  local scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(_G.Enum.MapElementScale.ESCALE_ALL)
  if _level <= scaleConf.max_scale / 100.0 and _level >= scaleConf.min_scale / 100.0 then
    self:SetIconVisible(true)
  else
    self:SetIconVisible(false)
  end
end

function UMG_IconVisit_C:SetIconVisible(bShow)
  if bShow then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_IconVisit_C:playAnimClose()
  self:PlayAnimation(self.Out)
end

function UMG_IconVisit_C:PlayAnimUp()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.In)
end

function UMG_IconVisit_C:OnAddEventListener()
end

function UMG_IconVisit_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_IconVisit_C:GetSceneResId()
  if self.uiData then
    local sceneResId, iconSceneResId = BigMapUtils.GetVisitorIconSceneResIdAndPos(self.uiData)
    return iconSceneResId
  end
  return BigMapUtils.GetDefaultSceneResId()
end

return UMG_IconVisit_C

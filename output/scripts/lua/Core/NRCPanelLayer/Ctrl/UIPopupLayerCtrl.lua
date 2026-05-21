local Base = require("Core.NRCPanelLayer.Base.UICommonLayerCtrl")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local UIPopupLayerCtrl = Base:Extend("UIPopupLayerCtrl")
UIPopupLayerCtrl._windowDepthOffset = 50

function UIPopupLayerCtrl:Ctor(center, type, depth)
  Base.Ctor(self, center, type, depth)
end

function UIPopupLayerCtrl:AddWindowData(windowId, module, panelData)
  local windowData = Base.AddWindowData(self, windowId, module, panelData)
  if windowData then
    local fullScreenCtrl = self.center and self.center:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    if fullScreenCtrl then
      local dependentPanelName = panelData and panelData.dependentPanelName
      fullScreenCtrl:AddPopWin(windowData, fullScreenCtrl:GetWindowData(dependentPanelName))
    end
  end
  return windowData
end

function UIPopupLayerCtrl:RemoveWindowData(windowId)
  local windowData = Base.RemoveWindowData(self, windowId)
  if windowData then
    local fullScreenCtrl = self.center and self.center:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    if fullScreenCtrl then
      fullScreenCtrl:RemovePopWin(windowData)
    end
  end
  return windowData
end

function UIPopupLayerCtrl:OnAddToLayerViewport(windowData)
  self:SendEvent(UILayerEvent.POPUP_LAYER_OPENWINDOW, windowData.windowId)
end

function UIPopupLayerCtrl:OnRemoveFromLayerViewport(windowData)
  self:SendEvent(UILayerEvent.POPUP_LAYER_CLOSEWINDOW, windowData.windowId)
end

function UIPopupLayerCtrl:BringToFrontImpl(windowId)
  local fullScreenCtrl = self.center and self.center:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  if fullScreenCtrl and fullScreenCtrl:HasAnyWindow() then
    local winData = self:GetWindowData(windowId)
    if winData then
      local success = fullScreenCtrl:BringPopupToFront(winData)
      return success, winData
    end
  else
    return Base.BringToFrontImpl(self, windowId)
  end
end

function UIPopupLayerCtrl:SendToBackImpl(windowId)
  local fullScreenCtrl = self.center and self.center:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  if fullScreenCtrl and fullScreenCtrl:HasAnyWindow() then
    local winData = self:GetWindowData(windowId)
    if winData then
      local success = fullScreenCtrl:SendPopupToBack(winData)
      return success, winData
    end
  else
    return Base.SendToBackImpl(self, windowId)
  end
end

function UIPopupLayerCtrl:CloseAll()
  local fullScreenCtrl = self.center and self.center:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  if fullScreenCtrl then
    local size = self._showWins:Size()
    for i = size, 1, -1 do
      local windowData = self._showWins:Get(i)
      fullScreenCtrl:RemovePopWin(windowData)
    end
  end
  Base.CloseAll(self)
end

return UIPopupLayerCtrl

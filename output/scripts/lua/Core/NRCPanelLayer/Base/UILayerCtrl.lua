local Class = _G.MakeSimpleClass
local UILayerCtrl = Class("UILayerCtrl")

function UILayerCtrl:Ctor(center, type, depth)
  self.center = center
  self.type = type
  self.depth = depth
end

function UILayerCtrl:Init()
end

function UILayerCtrl:Free()
end

function UILayerCtrl:GetWindow(windowId)
end

function UILayerCtrl:GetAllWindow()
end

function UILayerCtrl:GetWindowDepth(windowId)
  return self.depth
end

function UILayerCtrl:IsOpen(windowId)
end

function UILayerCtrl:CheckCanOpen(windowId)
  return true
end

function UILayerCtrl:GetLayerWindowCount()
  return 0
end

function UILayerCtrl:BringToFront(windowId, ...)
end

function UILayerCtrl:SendToBack(windowId, ...)
end

function UILayerCtrl:GetDebugData()
end

function UILayerCtrl:AddToLayerViewport(windowId, panel, module)
end

function UILayerCtrl:RemoveFromLayerViewport(panelOrWindowId)
end

function UILayerCtrl:RemoveAll()
end

function UILayerCtrl:SetPanelReadyToOpen(windowId, module, panelData)
end

function UILayerCtrl:SetPanelAlreadyVisible(windowId, panel)
end

function UILayerCtrl:SetPanelReadyToClosed(windowId)
end

function UILayerCtrl:SetPanelAlreadyClosed(windowId)
end

function UILayerCtrl:PreAssignedPanelDepth(windowId, module, panelData)
end

function UILayerCtrl:UndoPreAssignedPanelDepth(windowId)
end

function UILayerCtrl:Tick(deltaTime)
end

function UILayerCtrl:SendEvent(event, ...)
  if self.center then
    self.center:SendEvent(event, ...)
  end
end

function UILayerCtrl:CastToWindowId(panelOrWindowId)
  local windowId = panelOrWindowId
  if type(panelOrWindowId) ~= "string" then
    windowId = self:GetPanelName(panelOrWindowId)
  end
  return windowId
end

function UILayerCtrl:GetPanelName(window)
  if window then
    return window.panelName
  end
end

function UILayerCtrl:GetPanelLayer(window)
  if window and window.panelData then
    return window.panelData.panelLayer
  end
end

function UILayerCtrl:GetPanelNoCloseBehind(window)
  if window and window.panelData then
    return window.panelData.noCloseBehind
  end
end

function UILayerCtrl:IsWindowActive(panel)
  if panel then
    return panel.enableView
  end
end

function UILayerCtrl:IsWindowDeActive(panel)
  if panel then
    return not panel.enableView
  end
end

function UILayerCtrl:DoActiveWindow(panel)
  if panel then
    panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return panel:Enable()
  end
end

function UILayerCtrl:DoDeActiveWindow(panel)
  if panel then
    panel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return panel:Disable()
  end
end

function UILayerCtrl:DoCloseWindow(panel)
  if panel.panelName == "LobbyMain" then
    panel:Disable()
  else
    panel:DoClose()
  end
end

function UILayerCtrl:DoAddToViewport(panel, depth)
  panel:AddToViewport(depth, true)
end

function UILayerCtrl:DoRemoveFromViewport(panel)
  panel:RemoveFromViewport()
end

return UILayerCtrl

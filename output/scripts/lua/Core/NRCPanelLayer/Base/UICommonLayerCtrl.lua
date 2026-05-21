local Array = require("Utils.Array")
local Base = require("Core.NRCPanelLayer.Base.UILayerCtrl")
local NRCPanelEnum = require("Core.NRCPanel.NRCPanelEnum")
local UICommonLayerCtrl = Base:Extend("UICommonLayerCtrl")
UICommonLayerCtrl._enableLog = true
UICommonLayerCtrl._windowDepthOffset = 50

function UICommonLayerCtrl:Ctor(center, type, depth)
  Base.Ctor(self, center, type, depth)
  self._showWins = Array()
end

function UICommonLayerCtrl:Free()
  self:CloseAll()
  self._showWins:Clear()
end

function UICommonLayerCtrl:GetWindowDepthOffset()
  return self._windowDepthOffset or 50
end

function UICommonLayerCtrl:CalcWindowDepth(specifiedDepthStart)
  local depth = self.depth
  local depthOffset = self:GetWindowDepthOffset()
  if specifiedDepthStart and specifiedDepthStart > 0 then
    depth = specifiedDepthStart + depthOffset
  else
    local topWindowData = self._showWins:Last()
    if topWindowData then
      depth = (topWindowData.depth or 0) + depthOffset
    else
      depth = depth + depthOffset
    end
  end
  return depth
end

function UICommonLayerCtrl:AddWindowData(windowId, module, panelData)
  local windowData = {}
  windowData.layerCtrl = self
  windowData.windowId = windowId
  windowData.module = module
  windowData.panelData = panelData
  windowData.depth = self:CalcWindowDepth()
  windowData.status = NRCPanelEnum.PanelStatus.Init
  self._showWins:Add(windowData)
  return windowData
end

function UICommonLayerCtrl:RemoveWindowData(windowId)
  for i, winData in ipairs(self._showWins:Items()) do
    if winData.windowId == windowId then
      self._showWins:RemoveAt(i)
      return winData
    end
  end
end

function UICommonLayerCtrl:GetWindowData(windowId)
  if not windowId then
    return
  end
  for index, winData in ipairs(self._showWins:Items()) do
    if winData.windowId == windowId then
      return winData, index
    end
  end
end

function UICommonLayerCtrl:OnAddToLayerViewport(windowData)
end

function UICommonLayerCtrl:OnRemoveFromLayerViewport(windowData)
end

function UICommonLayerCtrl:SafeInvokeWindowFunction(windowData, funcName, ...)
  if string.IsNilOrEmpty(funcName) then
    return
  end
  local panel = windowData and windowData.panel
  if panel and panel[funcName] then
    local ok, msg = pcall(panel[funcName], panel, ...)
    if not ok then
      Log.Error(msg)
    end
  end
end

function UICommonLayerCtrl:AdjustWindowDepth(windowData, depth, inBatching)
  if windowData and depth then
    windowData.depth = depth
    local panel = windowData.panel
    if panel then
      panel.depth = depth
      panel:SetWidgetOrderInViewport(depth, inBatching)
      self:SafeInvokeWindowFunction(windowData, "OnDepthChanged", depth)
    end
  end
end

function UICommonLayerCtrl:FloatingWindowByData(wins, windowData, dstIndex)
  local srcIndex = wins and wins:IndexOf(windowData)
  return self:FloatingWindowByIndex(wins, srcIndex, dstIndex)
end

function UICommonLayerCtrl:FloatingWindowByIndex(wins, srcIndex, dstIndex)
  if not (wins and srcIndex) or not dstIndex then
    return false
  end
  local size = wins:Size()
  dstIndex = math.min(dstIndex, size)
  if srcIndex <= 0 or srcIndex > size or dstIndex <= 0 or size < dstIndex then
    return false
  end
  if srcIndex ~= dstIndex then
    local windowData = wins:Get(srcIndex)
    local adjustDepth = windowData.depth
    local step = srcIndex < dstIndex and 1 or -1
    for i = srcIndex + step, dstIndex, step do
      local curData = wins:Get(i)
      local curDepth = adjustDepth
      adjustDepth = curData.depth
      self:AdjustWindowDepth(curData, curDepth, true)
    end
    self:AdjustWindowDepth(windowData, adjustDepth, false)
    wins:RemoveAt(srcIndex)
    wins:Insert(dstIndex, windowData)
  end
  return true
end

function UICommonLayerCtrl:BringToFrontImpl(windowId)
  local winData, winIndex = self:GetWindowData(windowId)
  local success = self:FloatingWindowByIndex(self._showWins, winIndex, self._showWins:Size())
  return success, winData
end

function UICommonLayerCtrl:SendToBackImpl(windowId)
  local winData, winIndex = self:GetWindowData(windowId)
  local success = self:FloatingWindowByIndex(self._showWins, winIndex, 1)
  return success, winData
end

function UICommonLayerCtrl:GetWindow(windowId)
  local winData = self:GetWindowData(windowId)
  if winData then
    return winData.panel
  end
end

function UICommonLayerCtrl:GetAllWindow()
  local ret = {}
  for _, winData in ipairs(self._showWins:Items()) do
    if winData and winData.panel then
      table.insert(ret, winData.panel)
    end
  end
  return ret
end

function UICommonLayerCtrl:GetWindowDepth(windowId)
  local winData = self:GetWindowData(windowId)
  if winData then
    return winData.depth
  end
end

function UICommonLayerCtrl:IsOpen(windowId)
  return self:GetWindowData(windowId) ~= nil
end

function UICommonLayerCtrl:GetLayerWindowCount()
  return self._showWins:Size()
end

function UICommonLayerCtrl:BringToFront(windowId, ...)
  local success, winData = self:BringToFrontImpl(windowId)
  if success then
    self:SafeInvokeWindowFunction(winData, "OnBringToFront", ...)
  end
end

function UICommonLayerCtrl:SendToBack(windowId, ...)
  local success, winData = self:SendToBackImpl(windowId)
  if success then
    self:SafeInvokeWindowFunction(winData, "OnSendToBack", ...)
  end
end

function UICommonLayerCtrl:GetDebugData()
  local ret = {}
  for _, winData in ipairs(self._showWins:Items()) do
    table.insert(ret, winData)
  end
  return ret
end

function UICommonLayerCtrl:AddToLayerViewport(windowId, panel, module)
  local windowData = self:GetWindowData(windowId)
  windowData = windowData or self:AddWindowData(windowId, module)
  windowData.panel = panel
  panel.depth = windowData.depth
  self:DoAddToViewport(panel, windowData.depth, true)
  self:OnAddToLayerViewport(windowData)
  return true
end

function UICommonLayerCtrl:RemoveFromLayerViewport(panelOrWindowId)
  local windowId = self:CastToWindowId(panelOrWindowId)
  local windowData = self:RemoveWindowData(windowId)
  local window = windowData and windowData.panel
  if not window then
    return false
  end
  self:DoRemoveFromViewport(window)
  self:OnRemoveFromLayerViewport(windowData)
  return true
end

function UICommonLayerCtrl:SetPanelReadyToOpen(windowId, module, panelData)
  local windowData = self:PreAssignedPanelDepth(windowId, module, panelData)
  if windowData then
    windowData.status = NRCPanelEnum.PanelStatus.ReadyToOpen
  end
end

function UICommonLayerCtrl:SetPanelAlreadyVisible(windowId, panel)
  local windowData = self:GetWindowData(windowId)
  if windowData then
    windowData.status = NRCPanelEnum.PanelStatus.Visible
  end
end

function UICommonLayerCtrl:SetPanelReadyToClosed(windowId)
  local windowData = self:GetWindowData(windowId)
  if windowData then
    windowData.status = NRCPanelEnum.PanelStatus.ReadyToClose
  end
end

function UICommonLayerCtrl:SetPanelAlreadyClosed(windowId)
  self:RemoveWindowData(windowId)
end

function UICommonLayerCtrl:PreAssignedPanelDepth(windowId, module, panelData)
  local windowData = self:GetWindowData(windowId)
  windowData = windowData or self:AddWindowData(windowId, module, panelData)
  return windowData
end

function UICommonLayerCtrl:UndoPreAssignedPanelDepth(windowId)
  local windowData = self:GetWindowData(windowId)
  if windowData and windowData.status == NRCPanelEnum.PanelStatus.Init then
    self:RemoveWindowData(windowId)
  end
end

function UICommonLayerCtrl:CloseWindowByData(windowData)
  if not windowData then
    return
  end
  if windowData.panel then
    self:DoCloseWindow(windowData.panel)
  elseif windowData.module then
    windowData.module:ClosePanel(windowData.windowId)
  end
end

function UICommonLayerCtrl:ShowOrHideWindowByData(windowData, enable)
  if not windowData then
    return
  end
  local module = windowData.module
  if module then
    if enable then
      module:EnablePanel(windowData.windowId, NRCPanelEnum.PanelDisableReason.LayerCtrl)
    else
      module:DisablePanel(windowData.windowId, NRCPanelEnum.PanelDisableReason.LayerCtrl)
    end
  end
end

function UICommonLayerCtrl:CloseAll()
  local processWins = self._showWins:Clone()
  local size = processWins:Size()
  for i = size, 1, -1 do
    local windowData = processWins:Get(i)
    self:CloseWindowByData(windowData)
  end
end

function UICommonLayerCtrl:ActiveAll()
  local processWins = self._showWins:Clone()
  local size = processWins:Size()
  for i = 1, size do
    local windowData = processWins:Get(i)
    self:ShowOrHideWindowByData(windowData, true)
  end
end

function UICommonLayerCtrl:DeactiveAll()
  local processWins = self._showWins:Clone()
  local size = processWins:Size()
  for i = 1, size do
    local windowData = processWins:Get(i)
    self:ShowOrHideWindowByData(windowData, false)
  end
end

function UICommonLayerCtrl:Tick(deltaTime)
end

return UICommonLayerCtrl

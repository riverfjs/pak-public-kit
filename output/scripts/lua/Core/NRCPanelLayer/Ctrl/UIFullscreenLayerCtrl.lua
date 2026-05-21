local Array = require("Utils.Array")
local Base = require("Core.NRCPanelLayer.Base.UICommonLayerCtrl")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local NRCPanelEnum = require("Core.NRCPanel.NRCPanelEnum")
local FAKE_FULLSCREEN = "fake_fullscreen"
local UIFullscreenLayerCtrl = Base:Extend("UIFullscreenLayerCtrl")
UIFullscreenLayerCtrl._windowDepthOffset = 1000

function UIFullscreenLayerCtrl:Ctor(center, type, depth)
  Base.Ctor(self, center, type, depth)
  self._relatePopWinsDic = {}
end

function UIFullscreenLayerCtrl:Init()
  Base.Init(self)
  self:AddWindowData(FAKE_FULLSCREEN)
end

function UIFullscreenLayerCtrl:OnAddToLayerViewport(windowData)
  self:FoldOtherPanelAndPopupInAdvance()
  self:SendEvent(UILayerEvent.FULLSCREEN_LAYER_OPENWINDOW, windowData.panel)
end

function UIFullscreenLayerCtrl:OnRemoveFromLayerViewport(windowData)
  self:SendEvent(UILayerEvent.FULLSCREEN_LAYER_CLOSEWINDOW, windowData.panel)
end

function UIFullscreenLayerCtrl:IsFakePanel(windowData)
  return windowData and windowData.windowId == FAKE_FULLSCREEN
end

function UIFullscreenLayerCtrl:AdjustWindowDepth(windowData, depth, inBatching)
  if not windowData or not depth then
    return
  end
  local popWins = self._relatePopWinsDic[windowData.windowId]
  if popWins then
    local curPopWinDepthStart = depth
    for i = 1, popWins:Size() do
      local popWinData = popWins:Get(i)
      if popWinData then
        popWinData.depth = Base.CalcWindowDepth(popWinData.layerCtrl, curPopWinDepthStart)
        curPopWinDepthStart = popWinData.depth
        Base.AdjustWindowDepth(self, popWinData, popWinData.depth, false)
      end
    end
  end
  Base.AdjustWindowDepth(self, windowData, depth, inBatching)
end

function UIFullscreenLayerCtrl:BringToFrontImpl(windowId)
  local success, winData = Base.BringToFrontImpl(self, windowId)
  if success then
    self:UnDoFoldSpecifiedWindow(winData)
    self:OnNewTopPanelVisible(windowId)
  end
  return success, winData
end

function UIFullscreenLayerCtrl:SendToBackImpl(windowId)
  local size = self._showWins:Size()
  if size <= 0 then
    return false
  end
  local hasFakePanel = self:IsFakePanel(self._showWins:Get(1))
  if hasFakePanel and size <= 1 then
    return false
  end
  local winData, winIndex = self:GetWindowData(windowId)
  local isTopWin = winIndex == size
  local success = self:FloatingWindowByIndex(self._showWins, winIndex, hasFakePanel and 2 or 1)
  if success and isTopWin then
    local newTopWinData = self._showWins:Last()
    if newTopWinData then
      self:UnDoFoldSpecifiedWindow(newTopWinData)
      self:OnNewTopPanelVisible(newTopWinData.windowId)
    end
  end
  return success, winData
end

function UIFullscreenLayerCtrl:GetLayerWindowCount()
  local windowCount = Base.GetLayerWindowCount(self)
  if windowCount > 0 and self:IsFakePanel(self._showWins:First()) then
    windowCount = windowCount - 1
  end
  return windowCount
end

function UIFullscreenLayerCtrl:HasAnyWindow()
  return self._showWins:Size() > 0
end

function UIFullscreenLayerCtrl:BringPopupToFront(windowData, topDepth)
  local success = false
  local topFullWinData = self._showWins:Last()
  if topFullWinData then
    if topFullWinData.windowId ~= windowData.parentId then
      self:RemovePopWin(windowData)
      if self:AddPopWin(windowData, topFullWinData) then
        self:AdjustWindowDepth(windowData, windowData.depth, false)
        success = true
      end
    else
      local popWins = self._relatePopWinsDic[topFullWinData.windowId]
      if popWins then
        if popWins:Last() == windowData then
          success = true
        else
          success = self:FloatingWindowByData(popWins, windowData, math.maxinteger)
        end
      end
    end
  end
  if success then
    self:UnDoFoldSpecifiedWindow(windowData)
  end
  return success
end

function UIFullscreenLayerCtrl:SendPopupToBack(windowData)
  local success = false
  if string.IsNilOrEmpty(windowData.parentId) then
    success = self:FloatingWindowByData(self._relatePopWinsDic[windowData.parentId], windowData, 1)
  else
    Log.Error("UIFullscreenLayerCtrl:SendPopupToBack:", windowData.windowId, "parentId is nil or empty!")
  end
  if success then
    self:DoFoldSpecifiedWindow(windowData)
  end
  return success
end

function UIFullscreenLayerCtrl:GetDebugData()
  local ret = {}
  for _, winData in ipairs(self._showWins:Items()) do
    local debugDataItem = table.copy(winData)
    table.insert(ret, debugDataItem)
    local popWins = self._relatePopWinsDic[winData.windowId]
    if popWins and not popWins:IsEmpty() then
      debugDataItem.popWins = {}
      for _, popWinData in ipairs(popWins:Items()) do
        table.insert(debugDataItem.popWins, popWinData)
      end
    end
  end
  return ret
end

function UIFullscreenLayerCtrl:RemoveFromLayerViewport(panelOrWindowId)
  local windowId = self:CastToWindowId(panelOrWindowId)
  if self._relatePopWinsDic[windowId] and self._relatePopWinsDic[windowId]:Size() > 0 then
    local secondTopWin = self._showWins:Size() > 1 and self._showWins:Get(self._showWins:Size() - 1)
    local relatePopWinsDicClone = self._relatePopWinsDic[windowId]:Clone()
    local size = relatePopWinsDicClone:Size()
    for i = size, 1, -1 do
      local popWinData = relatePopWinsDicClone:Get(i)
      if popWinData and popWinData.panelData and popWinData.panelData.manualClosedPopPanel then
        if not secondTopWin or not self:AddPopWin(popWinData, secondTopWin) then
          popWinData.parentId = nil
          popWinData.depth = Base.CalcWindowDepth(popWinData.layerCtrl)
        end
        self:AdjustWindowDepth(popWinData, popWinData.depth, false)
      else
        self:CloseWindowByData(popWinData)
      end
    end
    self._relatePopWinsDic[windowId]:Clear()
  end
  self:SetPanelReadyToClosed(windowId)
  return Base.RemoveFromLayerViewport(self, windowId)
end

function UIFullscreenLayerCtrl:AddPopWin(windowData, dependentWin)
  if not windowData then
    return
  end
  local topWin = dependentWin or self._showWins:Last()
  if topWin then
    local windowId = topWin.windowId
    if self._relatePopWinsDic[windowId] == nil then
      self._relatePopWinsDic[windowId] = Array()
    end
    windowData.parentId = windowId
    windowData.depth = Base.CalcWindowDepth(windowData.layerCtrl, self:GetRelateTopPopWinDepth(topWin))
    self._relatePopWinsDic[windowId]:Add(windowData)
    return true
  end
end

function UIFullscreenLayerCtrl:RemovePopWin(windowData)
  if not windowData or not windowData.parentId then
    return
  end
  local popWins = self._relatePopWinsDic[windowData.parentId]
  if popWins then
    local size = popWins:Size()
    for i = size, 1, -1 do
      local popWinData = popWins:Get(i)
      if popWinData.windowId == windowData.windowId then
        popWins:RemoveAt(i)
        windowData.parentId = nil
        break
      end
    end
  end
end

function UIFullscreenLayerCtrl:GetLayerOpaqueWindowCount()
  local count = 0
  local size = self._showWins:Size()
  for i = 1, size do
    local windowData = self._showWins:Get(i)
    local window = windowData.panel
    if window and window.panelData and not window.panelData.translucent then
      count = count + 1
    end
  end
end

function UIFullscreenLayerCtrl:GetTopPopWinDepth()
  return self:GetRelateTopPopWinDepth(self._showWins:Last())
end

function UIFullscreenLayerCtrl:GetRelateTopPopWinDepth(fullWindowData)
  if fullWindowData then
    local windowId = fullWindowData.windowId
    local popWins = windowId and self._relatePopWinsDic[windowId]
    local topPopWinData = popWins and popWins:Last()
    if topPopWinData then
      return topPopWinData.depth
    else
      return fullWindowData.depth
    end
  end
end

function UIFullscreenLayerCtrl:CheckWindowBeOverlay(inWindowId)
  local size = self._showWins:Size()
  for i = 1, size do
    local windowData = self._showWins:Get(i)
    if windowData.windowId == inWindowId then
      return i ~= size
    end
  end
  return false
end

function UIFullscreenLayerCtrl:SetPanelAlreadyVisible(windowId, panel)
  Base.SetPanelAlreadyVisible(self, windowId, panel)
  self:OnNewTopPanelVisible(windowId)
end

function UIFullscreenLayerCtrl:SetPanelReadyToClosed(frontWindowId)
  Base.SetPanelReadyToClosed(self, frontWindowId)
  self:OnCurTopPanelClosed(frontWindowId)
end

function UIFullscreenLayerCtrl:OnNewTopPanelVisible(topWindowId)
  if _G.GlobalConfig.EnableFullScreenPanelCollapsed == true then
    if self.delayCollapsed then
      _G.DelayManager:CancelDelayById(self.delayCollapsed)
    end
    self.delayCollapsed = _G.DelayManager:DelayFrames(1, self.CollapsedOtherPanelAndPopup, self, topWindowId)
  end
end

function UIFullscreenLayerCtrl:OnCurTopPanelClosed(topWindowId)
  if _G.GlobalConfig.EnableFullScreenPanelCollapsed == true then
    local size = self._showWins:Size()
    if size > 1 then
      local frontWindowData = self._showWins:Get(size)
      if frontWindowData.windowId == topWindowId then
        self:ShowLastPanelAndPopup()
      end
    end
  end
end

function UIFullscreenLayerCtrl:DoFoldSpecifiedWindow(windowData)
  if not windowData then
    return false
  end
  if windowData._visibilityBeforeFold then
    return true
  end
  local curVisibility = -1
  local panel = windowData.panel
  if panel then
    curVisibility = panel:GetVisibility()
    panel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SafeInvokeWindowFunction(windowData, "OnFoldCollapsed")
  else
    self:ShowOrHideWindowByData(windowData, false)
  end
  windowData._visibilityBeforeFold = curVisibility
  return true
end

function UIFullscreenLayerCtrl:UnDoFoldSpecifiedWindow(windowData)
  if not windowData then
    return false
  end
  local visibilityBeforeFold = windowData._visibilityBeforeFold
  windowData._visibilityBeforeFold = nil
  if -1 == visibilityBeforeFold then
    self:ShowOrHideWindowByData(windowData, true)
  end
  local panel = windowData.panel
  if visibilityBeforeFold and -1 ~= visibilityBeforeFold and panel then
    self:SafeInvokeWindowFunction(windowData, "OnUnDoFoldCollapsed")
    if self:IsWindowActive(panel) and panel:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      panel:SetVisibility(visibilityBeforeFold)
      return true
    end
  end
  if panel then
    return panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed
  else
    return false
  end
end

function UIFullscreenLayerCtrl:FoldOtherPanelAndPopupInAdvance()
  local size = self._showWins:Size()
  if size > 1 then
    for i = 1, size - 1 do
      local windowData = self._showWins:Get(i)
      self:ShowPopWinsByWindowId(false, windowData.windowId)
    end
  end
end

function UIFullscreenLayerCtrl:CollapsedOtherPanelAndPopup(desireFrontWindowId)
  self.delayCollapsed = nil
  local size = self._showWins:Size()
  if size > 1 then
    local frontWindowData = self._showWins:Get(size)
    if frontWindowData.windowId ~= desireFrontWindowId then
      return
    end
    if frontWindowData.status and frontWindowData.status >= NRCPanelEnum.PanelStatus.ReadyToClose then
      return
    end
    local frontWindow = frontWindowData.panel
    if frontWindow and frontWindow:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      self.delayCollapsed = _G.DelayManager:DelayFrames(1, self.CollapsedOtherPanelAndPopup, self, desireFrontWindowId)
      return
    end
    for i = 1, size - 1 do
      local windowData = self._showWins:Get(i)
      self:ShowPopWinsByWindowId(false, windowData.windowId)
      self:DoFoldSpecifiedWindow(windowData)
    end
  end
end

function UIFullscreenLayerCtrl:ShowLastPanelAndPopup()
  local size = self._showWins:Size()
  if size > 1 then
    for i = size - 1, 1, -1 do
      local topWinData = self._showWins:Get(i)
      local success = false
      success = self:UnDoFoldSpecifiedWindow(topWinData)
      success = self:ShowPopWinsByWindowId(true, topWinData.windowId) or success
      if success then
        break
      end
    end
  end
end

function UIFullscreenLayerCtrl:ShowPopWinsByWindowId(bShow, windowId)
  local ret = false
  local popWins = self._relatePopWinsDic[windowId]
  if popWins then
    local size = popWins:Size()
    for j = 1, size do
      local popWinData = popWins:Get(j)
      local success = false
      if bShow then
        success = self:UnDoFoldSpecifiedWindow(popWinData)
      else
        success = self:DoFoldSpecifiedWindow(popWinData)
      end
      ret = ret or success
    end
  end
  return ret
end

return UIFullscreenLayerCtrl

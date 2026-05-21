local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local UMG_Guidance_DragLine_C = _G.NRCPanelBase:Extend("UMG_Guidance_DragLine_C")

function UMG_Guidance_DragLine_C:OnConstruct()
  self.tickedInterval = 0.1
  self.tickedTime = 0
end

function UMG_Guidance_DragLine_C:OnActive(style, dragConf)
  self.style = style
  self.dragConf = dragConf
  if not dragConf then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.bShouldSimulateDrag = dragConf.simulate_drag
  if _G.UE4Helper.IsPCMode() then
    self.resX, self.resY = UE4.UNRCQualityLibrary.GetPCResolution()
  else
  end
  self.elementA = self:GetDragElement(dragConf.start_type, dragConf.start_ui_path, dragConf.start_screen, dragConf.start_offset)
  self.elementB = self:GetDragElement(dragConf.end_type, dragConf.end_ui_path, dragConf.end_screen, dragConf.end_offset)
  self:CheckElementHasList(self.elementA)
  self:CheckElementHasList(self.elementB)
  self:UpdateDragLineDisplay()
  self:OnBeginDragStart(self.elementA)
  self:OnBeginDragEnd(self.elementB)
  if self.DragLine and self.loopAnim then
    self.DragLine:PlayAnimation(self.loopAnim, 0, 0)
  end
  local panelWidget, panelData = GuideConfigTypes.GetTargetWidget({
    dragConf.show_panel
  }, nil, true)
  if not panelWidget then
    Log.Warning("UMG_Guidance_DragLine_C:OnActive: panelWidget is nil", dragConf.show_panel)
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideFocusTargetLost)
    return
  end
  self.targetPanelWidget = panelWidget
  self.targetPanelData = panelData
end

function UMG_Guidance_DragLine_C:OnDeactive()
  self:OnFinishDragStart(self.elementA)
  self:OnFinishDragEnd(self.elementB)
end

function UMG_Guidance_DragLine_C:GetDragElement(eleType, uiPath, screen, offset)
  if not eleType or eleType == GuideConfigTypes.DragElementType.None then
    return
  end
  local element = {type = eleType}
  if eleType == GuideConfigTypes.DragElementType.Widget then
    element.widget_path = uiPath
  elseif eleType == GuideConfigTypes.DragElementType.Screen then
    element.ratio = screen
  end
  if offset and #offset >= 2 then
    element.offset = offset
  end
  self:UpdateDragElement(element)
  return element
end

function UMG_Guidance_DragLine_C:UpdateDragElement(element)
  if not element then
    return
  end
  if element.type == GuideConfigTypes.DragElementType.None then
    return
  end
  local viewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(self)
  if element.type == GuideConfigTypes.DragElementType.Widget then
    if not element.widget_path or #element.widget_path < 1 then
      return
    end
    local targetWidget, _, pathWidgets = GuideConfigTypes.GetTargetWidget(element.widget_path)
    if not targetWidget then
      Log.Warning("UMG_Guidance_DragLine_C:GetDragElement: targetWidget is nil", element.widget_path)
      return
    end
    element.widget = targetWidget
    element.pathWidgets = pathWidgets
    local geometry = targetWidget:GetPaintSpaceGeometry()
    local position = UE4.UNRCStatics.GetWidgetViewportPosition(targetWidget)
    local absoluteSize = UE4.USlateBlueprintLibrary.GetAbsoluteSize(geometry)
    local realSize = UE4.FVector2D(absoluteSize.X, absoluteSize.Y)
    realSize = realSize / viewportScale
    element.position = position + realSize / 2
  elseif element.type == GuideConfigTypes.DragElementType.Screen then
    if not element.ratio or #element.ratio < 2 then
      return
    end
    local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(self)
    local realViewportSize = viewportSize / viewportScale
    local screenPosition = realViewportSize * UE4.FVector2D(element.ratio[1], element.ratio[2])
    element.position = screenPosition
  end
  if not element.position then
    return
  end
  if element.offset and #element.offset >= 2 then
    local realOffset = UE4.FVector2D(element.offset[1], element.offset[2]) / viewportScale
    element.position = element.position + realOffset
  end
end

function UMG_Guidance_DragLine_C:CheckElementHasList(element)
  if not element or element.type ~= GuideConfigTypes.DragElementType.Widget then
    return
  end
  if not element.pathWidgets then
    return
  end
  for _, widget in pairs(element.pathWidgets) do
    if widget and widget.GuidanceListRecord then
      element.bWidgetHasListItem = true
      break
    end
  end
end

function UMG_Guidance_DragLine_C:IsElementValid(element)
  if not element then
    return false
  end
  if not element.position then
    return false
  end
  if element.type == GuideConfigTypes.DragElementType.Widget then
    if not element.pathWidgets then
      return false
    end
    for _, widget in pairs(element.pathWidgets) do
      if not widget or not UE4.UObject.IsValid(widget) then
        return false
      end
    end
  end
  return true
end

function UMG_Guidance_DragLine_C:UpdateDragLineDisplay()
  if not self:IsElementValid(self.elementA) or not self:IsElementValid(self.elementB) then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local centerPosition = (self.elementA.position + self.elementB.position) / 2
  self:SetSlotPosition(self.DragLine, centerPosition)
  self:AdjustArrow(self.elementA.position, self.elementB.position)
end

function UMG_Guidance_DragLine_C:SetSlotPosition(widget, position)
  if not widget or not UE4.UObject.IsValid(widget) then
    return
  end
  if not position then
    return
  end
  local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(widget)
  if slot and UE4.UObject.IsValid(slot) then
    slot:SetPosition(position)
  end
end

function UMG_Guidance_DragLine_C:AdjustArrow(positionA, positionB)
  if not positionA or not positionB then
    return
  end
  local delta = positionB - positionA
  local radian = math.atan(delta.Y, delta.X)
  local angel = radian * 180 / math.pi
  local distance = delta:Size()
  local offset = distance * 0.25
  if self.DragLine then
    if angel <= 90 and angel >= -90 then
      self.loopAnim = self.DragLine.GustureRight_Loop
      self.DragLine:SetRenderTransformAngle(angel)
    else
      self.loopAnim = self.DragLine.GustureLeft_Loop
      self.DragLine:SetRenderTransformAngle(angel + 180)
    end
    self:SetSlotPosition(self.DragLine.LeftArrow, UE4.FVector2D(-offset, 0))
    self:SetSlotPosition(self.DragLine.RightArrow, UE4.FVector2D(offset, 0))
  end
  Log.Debug("UMG_Guidance_DragLine_C:AdjustArrow:", positionA, positionB, delta, radian, angel, distance)
end

function UMG_Guidance_DragLine_C:OnTick(deltaTime)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:SimulateDrag()
  if not (self.tickedTime and self.tickedInterval) or not deltaTime then
    Log.Debug("UMG_Guidance_DragLine_C:OnTick: tickTime or tickInterval or deltaTime is nil", self, self.tickedTime, self.tickedInterval, deltaTime)
    return
  end
  self.tickedTime = self.tickedTime + deltaTime
  if self.tickedTime < self.tickedInterval then
    return
  end
  self.tickedTime = self.tickedTime - self.tickedInterval
  if _G.UE4Helper.IsPCMode() then
    local resX, resY = UE4.UNRCQualityLibrary.GetPCResolution()
    if resX ~= self.resX or resY ~= self.resY then
      Log.Debug("UMG_Guidance_DragLine_C:OnTick resolution changed", self.resX, self.resY, resX, resY)
      self.resX = resX
      self.resY = resY
      self.resolutionChanged = true
    end
  else
  end
  local elementAVisible = self:CheckElementVisible(self.elementA)
  local elementBVisible = self:CheckElementVisible(self.elementB)
  if not elementAVisible or not elementBVisible then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if self.resolutionChanged then
      self.resolutionChanged = false
      self:UpdateDragElement(self.elementA)
      self:UpdateDragElement(self.elementB)
      self:UpdateDragLineDisplay()
      Log.Debug("UMG_Guidance_DragLine_C:OnTick update after resolution changed")
    end
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_Guidance_DragLine_C:SimulateDrag()
  if not self.bShouldSimulateDrag then
    return
  end
  local fakeTouchPosition
  if _G.UE4Helper.IsPCMode() then
    fakeTouchPosition = UE4.UWidgetLayoutLibrary.GetMousePositionOnPlatform()
  else
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.viewObj and localPlayer.viewObj:IsValid() then
      local playerController = localPlayer:GetUEController()
      if playerController then
        local locationX, locationY, bPressed = playerController:GetInputTouchState(0)
        fakeTouchPosition = UE4.FVector2D(locationX, locationY)
      end
    end
  end
  if fakeTouchPosition then
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.OnRocoTouchMove, 0, fakeTouchPosition)
  end
end

function UMG_Guidance_DragLine_C:CheckElementVisible(element)
  if not element then
    return false
  end
  if element.type == GuideConfigTypes.DragElementType.Screen then
    return true
  end
  if not element.pathWidgets then
    return false
  end
  self:TryUpdateListItem(element)
  for _, widget in ipairs(element.pathWidgets) do
    if not widget or not UE4.UObject.IsValid(widget) then
      return false
    end
    local currentWidget = widget
    while currentWidget and UE4.UObject.IsValid(currentWidget) do
      if not currentWidget:IsVisible() then
        return false
      end
      currentWidget = currentWidget:GetParent()
    end
  end
  return true
end

function UMG_Guidance_DragLine_C:TryUpdateListItem(element)
  if not element then
    return
  end
  if not element.bWidgetHasListItem then
    return
  end
  local bListChanged = false
  local newPathWidgets = {}
  for _, widget in pairs(element.pathWidgets) do
    if widget then
      local record = widget.GuidanceListRecord
      local item
      if record then
        local index = record.index
        if record.list and UE4.UObject.IsValid(record.list) then
          item = record.list:GetItemAt(index - 1)
        elseif record.grid and UE4.UObject.IsValid(record.grid) then
          item = record.grid:GetItemByIndex(index - 1)
        elseif record.scroll and UE4.UObject.IsValid(record.scroll) then
          item = record.scroll:GetItemByIndex(index - 1)
        end
        if item and UE4.UObject.IsValid(item) then
          table.insert(newPathWidgets, item)
          if item ~= widget then
            bListChanged = true
            widget.GuidanceListRecord = nil
            item.GuidanceListRecord = record
          end
        end
      else
        table.insert(newPathWidgets, widget)
      end
    end
  end
  if bListChanged then
    element.pathWidgets = newPathWidgets
    Log.Debug("UMG_Guidance_DragLine_C:TryUpdateListItem list changed")
  end
end

function UMG_Guidance_DragLine_C:OnBeginDragStart(element)
  if not element then
    return
  end
  local widget = element.widget
  if not widget or not UE4.UObject.IsValid(widget) then
    return
  end
  if widget.OnBeginDragStart then
    widget:OnBeginDragStart()
  end
end

function UMG_Guidance_DragLine_C:OnBeginDragEnd(element)
  if not element then
    return
  end
  local widget = element.widget
  if not widget or not UE4.UObject.IsValid(widget) then
    return
  end
  if widget.OnBeginDragEnd then
    widget:OnBeginDragEnd()
  end
end

function UMG_Guidance_DragLine_C:OnFinishDragStart(element)
  if not element then
    return
  end
  local widget = element.widget
  if not widget or not UE4.UObject.IsValid(widget) then
    return
  end
  if widget.OnFinishDragStart then
    widget:OnFinishDragStart()
  end
end

function UMG_Guidance_DragLine_C:OnFinishDragEnd(element)
  if not element then
    return
  end
  local widget = element.widget
  if not widget or not UE4.UObject.IsValid(widget) then
    return
  end
  if widget.OnFinishDragEnd then
    widget:OnFinishDragEnd()
  end
end

function UMG_Guidance_DragLine_C:CheckPanelOnTop()
  if not self.targetPanelData then
    return
  end
  if GuideConfigTypes.CheckIsTopPanel(self.targetPanelData) then
    if not self:IsVisible() then
      Log.Debug("UMG_Guidance_DragLine_C:CheckPanelOnTop", "panel is on top")
      self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  elseif self:IsVisible() then
    Log.Debug("UMG_Guidance_DragLine_C:CheckPanelOnTop", "panel is not on top")
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Guidance_DragLine_C

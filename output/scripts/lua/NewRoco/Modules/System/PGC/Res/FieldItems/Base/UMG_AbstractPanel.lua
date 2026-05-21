local UMG_AbstractPanel = NRCPanelBase:Extend("UMG_AbstractPanel")

function UMG_AbstractPanel:OnConstruct()
  NRCPanelBase.OnConstruct(self)
  self.IsDragging = false
  self.DragOffset = UE4.FVector2D(0, 0)
  self.LastMousePosition = UE4.FVector2D(0, 0)
  self.EnableDrag = true
  self.DragAreaWidget = nil
  self.IsConstrainToViewport = true
  self.DragThreshold = 1
  self.CachedViewportSize = nil
  self.CachedPanelSize = nil
  self:OnAddEventListener()
end

function UMG_AbstractPanel:OnActive(Data)
  NRCPanelBase.OnActive(self, Data)
  if self.In then
    self:PlayAnimation(self.In)
  end
  self:RefreshData(Data)
  if self.EnableDrag then
    self:OnSetupDragArea()
  end
end

function UMG_AbstractPanel:OnDeactive()
  self:RefreshData(nil)
  if self.Out then
    self:PlayAnimation(self.Out)
  end
  NRCPanelBase.OnDeactive(self)
end

function UMG_AbstractPanel:OnDestruct()
  self:OnRemoveEventListener()
  NRCPanelBase.OnDestruct(self)
end

function UMG_AbstractPanel:SetDraggable(enable)
  self.EnableDrag = enable
end

function UMG_AbstractPanel:SetConstrainToViewport(constrain)
  self.IsConstrainToViewport = constrain
end

function UMG_AbstractPanel:SetDragArea(widget)
  self.DragAreaWidget = widget
  self:OnSetupDragArea()
end

function UMG_AbstractPanel:ConstrainToViewport(Position)
  local ViewportSize = self.CachedViewportSize
  local PanelSize = self.CachedPanelSize
  local ClampedPosition = UE4.FVector2D(Position.X, Position.Y)
  if ClampedPosition.X < 0 then
    ClampedPosition.X = 0
  elseif ClampedPosition.X + PanelSize.X > ViewportSize.X then
    ClampedPosition.X = ViewportSize.X - PanelSize.X
  end
  if ClampedPosition.Y < 0 then
    ClampedPosition.Y = 0
  elseif ClampedPosition.Y + PanelSize.Y > ViewportSize.Y then
    ClampedPosition.Y = ViewportSize.Y - PanelSize.Y
  end
  return ClampedPosition
end

function UMG_AbstractPanel:RefreshData(Data)
  if Data then
    self:OnRefreshData(Data)
  else
    self:OnCleanData()
  end
end

function UMG_AbstractPanel:OnAddEventListener()
end

function UMG_AbstractPanel:OnRefreshData(Data)
end

function UMG_AbstractPanel:OnCleanData()
end

function UMG_AbstractPanel:OnRemoveEventListener()
end

function UMG_AbstractPanel:OnSetupDragArea()
end

function UMG_AbstractPanel:OnMouseButtonDown(MyGeometry, MouseEvent)
  if not self.EnableDrag then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  local MousePosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
  if self.DragAreaWidget then
    local DragAreaGeometry = self.DragAreaWidget:GetCachedGeometry()
    if not UE4.USlateBlueprintLibrary.IsUnderLocation(DragAreaGeometry, MousePosition) then
      return UE4.UWidgetBlueprintLibrary.Unhandled()
    end
  end
  local MouseViewportPosition = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(UE4Helper.GetCurrentWorld())
  local WidgetViewportPosition = UE4.UNRCStatics.GetWidgetViewportPosition(self)
  self.DragOffset = MouseViewportPosition - WidgetViewportPosition
  self.CachedViewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  self.CachedPanelSize = self:GetDesiredSize()
  self.IsDragging = true
  self.LastMousePosition = MousePosition
  self:OnDragBegin(WidgetViewportPosition)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_AbstractPanel:OnMouseMove(MyGeometry, MouseEvent)
  if not self.IsDragging then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  local MousePosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
  local OffsetMousePosition = MousePosition - self.LastMousePosition
  if math.abs(OffsetMousePosition.X) < self.DragThreshold and math.abs(OffsetMousePosition.Y) < self.DragThreshold then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  self.LastMousePosition = MousePosition
  local MouseViewportPosition = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(UE4Helper.GetCurrentWorld())
  local TargetViewportPosition = MouseViewportPosition - self.DragOffset
  if self.IsConstrainToViewport then
    TargetViewportPosition = self:ConstrainToViewport(TargetViewportPosition)
  end
  self:SetPositionInViewport(TargetViewportPosition, false)
  self:OnDraging(TargetViewportPosition)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_AbstractPanel:OnMouseButtonUp(MyGeometry, MouseEvent)
  if not self.IsDragging then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  self.IsDragging = false
  self.CachedViewportSize = nil
  self.CachedPanelSize = nil
  local WidgetViewportPosition = UE4.UNRCStatics.GetWidgetViewportPosition(self)
  self:OnDragEnd(WidgetViewportPosition)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_AbstractPanel:OnDragBegin(ViewportPosition)
end

function UMG_AbstractPanel:OnDraging(ViewportPosition)
end

function UMG_AbstractPanel:OnDragEnd(ViewportPosition)
end

return UMG_AbstractPanel

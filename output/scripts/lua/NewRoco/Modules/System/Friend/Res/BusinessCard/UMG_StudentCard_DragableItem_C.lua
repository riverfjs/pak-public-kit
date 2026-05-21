local BP_NRCItemBase_C = require("NewRoco.TUI.BP_NRCItemBase_C")
local Base = BP_NRCItemBase_C
local UMG_StudentCard_DragableItem_C = Base:Extend("UMG_StudentCard_DragableItem_C")

function UMG_StudentCard_DragableItem_C:OnTouchStarted(_MyGeometry, _TouchEvent)
  Log.Debug("UMG_StudentCard_DragableItem_C:OnTouchStarted")
  self.detectDragStartMs = UE4.UNRCStatics.GetTimestampMicroseconds()
  local reply = UE.UWidgetBlueprintLibrary.DetectDragIfPressed(_TouchEvent, self, UE.FKey("LeftMouseButton"))
  Base.OnTouchStarted(self, _MyGeometry, _TouchEvent)
  return reply
end

function UMG_StudentCard_DragableItem_C:OnTouchMoved(_MyGeometry, _MouseEvent)
  if self:IsEnableListScroll() then
    Log.Debug("UMG_StudentCard_DragableItem_C:OnTouchMoved - ListScroll is enabled, returning Unhandled")
    return UE.UWidgetBlueprintLibrary.Unhandled()
  else
    Log.Debug("UMG_StudentCard_DragableItem_C:OnTouchMoved - ListScroll is disabled, returning Handled")
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
end

function UMG_StudentCard_DragableItem_C:OnDragDetected(MyGeometry, PointerEvent, Operation)
  if not self:IsShowDragDropWidget() then
    local defaultDraDrop = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(UE.UDragDropOperation)
    Log.Debug("UMG_StudentCard_DragableItem_C:OnDragDetected - ListScroll is disabled, returning default DragDropOperation")
    return defaultDraDrop
  end
  local curMs = UE4.UNRCStatics.GetTimestampMicroseconds()
  local delayMicroSeconds = self:ThresholdMilliTimeForDragStart() * 1000
  if not self.detectDragStartMs or 0 == self.detectDragStartMs or delayMicroSeconds > curMs - self.detectDragStartMs then
    local defaultDragDrop = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(UE.UDragDropOperation)
    return defaultDragDrop
  end
  Log.Debug("UMG_StudentCard_DragableItem_C:OnDragDetected")
  local cardDragDropOpClass = UE.UClass.Load("/Game/NewRoco/Modules/System/Friend/Res/BusinessCard/BP_CardDragDropOperation.BP_CardDragDropOperation_C")
  if not cardDragDropOpClass then
    Log.Error("UMG_StudentCard_DragableItem_C:OnDragDetected - cardDragDropOpClass is nil")
    return nil
  end
  local DragDropOp = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(cardDragDropOpClass)
  if not DragDropOp then
    Log.Error("UMG_StudentCard_DragableItem_C:OnDragDetected - Operation is nil")
    return nil
  end
  local DragVisualClass = UE.UClass.Load("/Game/NewRoco/Modules/System/Friend/Res/BusinessCard/UMG_StudentCard_Drag_Move_Item.UMG_StudentCard_Drag_Move_Item_C")
  if not DragVisualClass then
    Log.Error("Failed to load DragVisual widget class")
    return DragDropOp
  end
  local DragVisualWidget = UE4.UWidgetBlueprintLibrary.Create(UE4Helper.GetCurrentWorld(), DragVisualClass)
  if not DragVisualWidget then
    Log.Error("Failed to create DragVisual widget instance")
    return DragDropOp
  end
  local initParam = self:GetDragWidgetInitParam()
  if initParam and DragVisualWidget.Init then
    DragVisualWidget:Init(initParam)
  end
  DragDropOp.DefaultDragVisual = DragVisualWidget
  DragDropOp.WidgetRef = self
  self:HandleDragStart(MyGeometry, PointerEvent, DragDropOp)
  return DragDropOp
end

function UMG_StudentCard_DragableItem_C:OnDrop(MyGeometry, PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:OnDrop")
  self:HandleDrop(MyGeometry, PointerEvent, Operation)
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_StudentCard_DragableItem_C:OnDragCancelled(PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:OnDragCancelled")
  self:HandleDragCancelled(PointerEvent, Operation)
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_StudentCard_DragableItem_C:OnDragEnter(MyGeometry, PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:OnDragEnter")
  self:HandleDragEnter(MyGeometry, PointerEvent, Operation)
end

function UMG_StudentCard_DragableItem_C:OnDragLeave(PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:OnDragLeave")
  self:HandleDragLeave(PointerEvent, Operation)
end

function UMG_StudentCard_DragableItem_C:IsShowDragDropWidget()
  return true
end

function UMG_StudentCard_DragableItem_C:IsEnableListScroll()
  return true
end

function UMG_StudentCard_DragableItem_C:ThresholdMilliTimeForDragStart()
  return 0
end

function UMG_StudentCard_DragableItem_C:GetDragWidgetInitParam()
  return nil
end

function UMG_StudentCard_DragableItem_C:HandleDragStart(MyGeometry, PointerEvent, BP_CardDragDropOperation_C)
end

function UMG_StudentCard_DragableItem_C:HandleDragEnter(MyGeometry, PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:HandleDragEnter")
end

function UMG_StudentCard_DragableItem_C:HandleDragLeave(PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:HandleDragLeave")
end

function UMG_StudentCard_DragableItem_C:HandleDrop(MyGeometry, PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:HandleDrop")
end

function UMG_StudentCard_DragableItem_C:HandleDragCancelled(PointerEvent, Operation)
  Log.Debug("UMG_StudentCard_DragableItem_C:HandleDragCancelled")
end

return UMG_StudentCard_DragableItem_C

local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_Pet_TeamReplace_GridTouchProxy_C = _G.NRCPanelBase:Extend("UMG_Pet_TeamReplace_GridTouchProxy_C")

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnConstruct()
  self.stateManager = WidgetStateManager()
  local initOption = {}
  initOption.owner = self
  initOption.UpdateDerivedState = self.UpdateDerivedState
  initOption.DeriveStateFromProps = self.DeriveStateFromProps
  initOption.RenderWidget = self.RenderWidget
  initOption.OnWidgetDidUpdate = self.OnWidgetDidUpdate
  initOption.autoCreateDebugger = false
  local initState = {}
  
  function initState.getGeometryFn()
    return self:GetCachedGeometry()
  end
  
  function initState.getLocalSizeFn()
    local geometry = self:GetCachedGeometry()
    local size = UE4.USlateBlueprintLibrary.GetLocalSize(geometry)
    return size
  end
  
  initState.rowCount = self.RowCount
  initState.colCount = self.ColCount
  initState.orientation = self.Orientation
  initOption.initState = initState
  self.stateManager:Init(initOption)
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnActive()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnDeactive()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnDestruct()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnAddEventListener()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnRemoveEventListener()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C.DeriveStateFromProps(prevState, nextProps)
  local nextState = {}
  table.copy(prevState, nextState)
  if nextProps and nextProps.colCount then
    nextState.colCount = nextProps and nextProps.colCount
  end
  if nextProps and nextProps.rowCount then
    nextState.rowCount = nextProps and nextProps.rowCount
  end
  return nextState
end

function UMG_Pet_TeamReplace_GridTouchProxy_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevDragContext = prevProps and prevProps.dragContext
  local currDragContext = currProps and currProps.dragContext
  local prevDragPosition = prevDragContext and prevDragContext.dragPosition
  local currDragPosition = currDragContext and currDragContext.dragPosition
  local prevStartPosition = prevDragContext and prevDragContext.startPosition
  local currStartPosition = currDragContext and currDragContext.startPosition
  local prevIsDraggingItem = prevDragContext and prevDragContext.isDraggingItem
  local currIsDraggingItem = currDragContext and currDragContext.isDraggingItem
  local prevCanInteractWhenWarehouseIsScrolling = prevProps and prevProps.canInteractWhenWarehouseIsScrolling
  local currCanInteractWhenWarehouseIsScrolling = currProps and currProps.canInteractWhenWarehouseIsScrolling
  local prevWarehouseIsScrollingToPage = prevProps and prevProps.warehouseIsScrollingToPage
  local currWarehouseIsScrollingToPage = currProps and currProps.warehouseIsScrollingToPage
  local prevCanInteract = prevState and prevState.canInteract
  local currCanInteract = currState and currState.canInteract
  if prevDragContext ~= currDragContext or prevCanInteract ~= currCanInteract then
    local startIndex = -1
    local index = -1
    local canInteractAtStart = currDragContext and currDragContext.canInteractAtStart
    if currCanInteract and canInteractAtStart and currDragContext then
      local rowCount = currState and currState.rowCount or 1
      local colCount = currState and currState.colCount or 1
      local world = UE4Helper.GetCurrentWorld()
      local startPosition = currDragContext and currDragContext.startPosition
      local dragPosition = currDragContext and currDragContext.dragPosition
      local startPositionFromTouchContext = currDragContext and currDragContext.startPositionFromTouchContext
      local dragPositionFromTouchContext = currDragContext and currDragContext.dragPositionFromTouchContext
      local getGeometryFn = currState and currState.getGeometryFn
      local geometry = getGeometryFn and getGeometryFn()
      local getLocalSizeFn = currState and currState.getLocalSizeFn
      local localSize = getLocalSizeFn and getLocalSizeFn()
      startIndex = UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(startPositionFromTouchContext, rowCount, colCount, world, geometry)
      index = UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(dragPositionFromTouchContext, rowCount, colCount, world, geometry)
    end
    derivedState.startIndex = startIndex
    derivedState.index = index
  end
  if prevCanInteractWhenWarehouseIsScrolling ~= currCanInteractWhenWarehouseIsScrolling or prevWarehouseIsScrollingToPage ~= currWarehouseIsScrollingToPage or prevIsDraggingItem ~= currIsDraggingItem then
    local canInteract = true
    if not currIsDraggingItem and currWarehouseIsScrollingToPage and not currCanInteractWhenWarehouseIsScrolling then
      canInteract = false
    end
    derivedState.canInteract = canInteract
  end
  if prevDragContext ~= currDragContext then
    local screenStartPosition = currDragContext and currDragContext.startPosition
    local screenPosition = currDragContext and currDragContext.dragPosition
    local startPositionFromTouchContext = currDragContext and currDragContext.startPositionFromTouchContext
    local dragPositionFromTouchContext = currDragContext and currDragContext.dragPositionFromTouchContext
    local rowCount = 1
    local colCount = 1
    local world = UE4Helper.GetCurrentWorld()
    local getGeometryFn = currState and currState.getGeometryFn
    local getLocalSizeFn = currState and currState.getLocalSizeFn
    local geometry = getGeometryFn and getGeometryFn()
    local localSize = getLocalSizeFn and getLocalSizeFn()
    local oneCellGridIndexStart = UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(startPositionFromTouchContext, rowCount, colCount, world, geometry)
    local oneCellGridIndex = UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(dragPositionFromTouchContext, rowCount, colCount, world, geometry)
    local isDragHoveringStart = oneCellGridIndexStart >= 0
    local isDragHovering = oneCellGridIndex >= 0
    derivedState.isDragStartHovering = isDragHoveringStart
    derivedState.isDraggingHovering = isDragHovering
  end
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local nextKey = currProps and currProps.key
  local keyChanged = prevKey ~= nextKey
  local prevDragContext = prevProps and prevProps.dragContext
  local currDragContext = currProps and currProps.dragContext
  local prevIsInArea = prevState and prevState.isInArea
  local currIsInArea = currState and currState.isInArea
  local prevIndex = prevState and prevState.index
  local currIndex = currState and currState.index
  local prevIsDebugMode = prevProps and prevProps.isDebugMode
  local currIsDebugMode = currProps and currProps.isDebugMode
  if prevIsDebugMode ~= currIsDebugMode then
    if currIsDebugMode then
      self.Background:SetRenderOpacity(1)
    else
      self.DebugText:SetText("")
      self.Background:SetRenderOpacity(0)
    end
  end
  local prevWarehouseIsScrollingToPage = prevProps and prevProps.warehouseIsScrollingToPage
  local currWarehouseIsScrollingToPage = currProps and currProps.warehouseIsScrollingToPage
  local startWarehouseScrollOffset = prevProps and prevProps.startWarehouseScrollOffset
  local startWarehouseLocalPositionX = currProps and currProps.startWarehouseLocalPositionX
  local currWarehouseLocalPositionX = currProps and currProps.currWarehouseLocalPositionX
  local currDebugText = currProps and currProps.debugText
  if currIsDebugMode and (prevDragContext ~= currDragContext or keyChanged or prevIsInArea ~= currIsInArea or prevIndex ~= currIndex or prevWarehouseIsScrollingToPage ~= currWarehouseIsScrollingToPage) then
    local NRCTextVisibility = UE.ESlateVisibility.Collapsed
    if currDragContext or currWarehouseIsScrollingToPage then
      local screenPosition = currDragContext and currDragContext.dragPosition
      local angleToHorizontalAxis = currDragContext and currDragContext.angleToHorizontalAxis
      local isDraggingItem = currDragContext and currDragContext.isDraggingItem
      local isScrollingList = currDragContext and currDragContext.isScrollingList
      local canInteract = currState and currState.canInteract
      local canInteractAtStart = currDragContext and currDragContext.canInteractAtStart
      NRCTextVisibility = UE.ESlateVisibility.SelfHitTestInvisible
      local world = UE4Helper.GetCurrentWorld()
      local geometry = self:GetCachedGeometry()
      local geometryAbsolutePosition = UE4.USlateBlueprintLibrary.LocalToAbsolute(geometry, UE4.FVector2D(0, 0))
      local geometryAbsolutePosition1X = geometryAbsolutePosition and geometryAbsolutePosition.X or 0
      local geometryAbsolutePosition1Y = geometryAbsolutePosition and geometryAbsolutePosition.Y or 0
      local absoluteSize = UE.USlateBlueprintLibrary.GetAbsoluteSize(geometry)
      local geometryAbsolutePosition2X = geometryAbsolutePosition1X + (absoluteSize and absoluteSize.X or 0)
      local geometryAbsolutePosition2Y = geometryAbsolutePosition1Y + (absoluteSize and absoluteSize.Y or 0)
      local localPosition
      if world and geometry and screenPosition then
        localPosition = UE.FVector2D(0, 0)
        UE4.USlateBlueprintLibrary.ScreenToWidgetLocal(world, geometry, screenPosition, localPosition, false)
      end
      local screenPositionX = screenPosition and screenPosition.X or 0
      local screenPositionY = screenPosition and screenPosition.Y or 0
      local localPositionX = localPosition and localPosition.X or 0
      local localPositionY = localPosition and localPosition.Y or 0
      local text = string.format([[
currIndex: %s 
 angle: %s 
 isDraggingItem: %s 
 isScrollingList: %s 
 geometry absolute1: (%.2f, %.2f) 
 geometry absolute2: (%.2f, %.2f) 
 current warehouse is scrolling: %s 
 canInteractAtStart: %s 
 %s]], tostring(currIndex), tostring(angleToHorizontalAxis), tostring(isDraggingItem), tostring(isScrollingList), geometryAbsolutePosition1X, geometryAbsolutePosition1Y, geometryAbsolutePosition2X, geometryAbsolutePosition2Y, tostring(currWarehouseIsScrollingToPage), tostring(canInteractAtStart), tostring(currDebugText))
      self.DebugText:SetText(text)
    else
    end
    self.DebugText:SetVisibility(NRCTextVisibility)
  end
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevDragContext = prevProps and prevProps.dragContext
  local currDragContext = currProps and currProps.dragContext
  local prevIndex = prevState and prevState.index
  local currIndex = currState and currState.index
  local prevStartIndex = prevState and prevState.startIndex
  local currStartIndex = currState and currState.startIndex
  local currCanInteract = currState and currState.canInteract
  local prevIsDragStartHovering = prevState and prevState.isDragStartHovering
  local currIsDragStartHovering = currState and currState.isDragStartHovering
  local prevIsDraggingHovering = prevState and prevState.isDraggingHovering
  local currIsDraggingHovering = currState and currState.isDraggingHovering
  if prevDragContext ~= currDragContext and prevDragContext and nil == currDragContext then
    local startPosition = prevDragContext and prevDragContext.startPosition
    local finalPosition = prevDragContext and prevDragContext.dragPosition
    local startPositionFromTouchContext = prevDragContext and prevDragContext.startPositionFromTouchContext
    local dragPositionFromTouchContext = prevDragContext and prevDragContext.dragPositionFromTouchContext
    local canInteractAtStart = prevDragContext and prevDragContext.canInteractAtStart
    local isClickWhenDragEnd = prevDragContext and prevDragContext.isClickWhenDragEnd
    local rowCount = currState and currState.rowCount or 1
    local colCount = currState and currState.colCount or 1
    local world = UE4Helper.GetCurrentWorld()
    local getGeometryFn = currState and currState.getGeometryFn
    local getLocalSizeFn = currState and currState.getLocalSizeFn
    local geometry = getGeometryFn and getGeometryFn()
    local localSize = getLocalSizeFn and getLocalSizeFn()
    local startIndex = UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(startPositionFromTouchContext, rowCount, colCount, world, geometry)
    local finalIndex = UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(dragPositionFromTouchContext, rowCount, colCount, world, geometry)
    if startIndex >= 0 and finalIndex >= 0 and startIndex == finalIndex and isClickWhenDragEnd and canInteractAtStart then
      local onItemSelectCallback = currProps and currProps.onItemSelectCallback
      local onItemSelectCallbackOwner = currProps and currProps.onItemSelectCallbackOwner
      local gridType = currProps and currProps.gridType
      if onItemSelectCallback then
        tcall(onItemSelectCallbackOwner, onItemSelectCallback, gridType, finalIndex)
      end
    end
  end
  if prevIndex ~= currIndex then
    local onHoveringItemUpdateCallback = currProps and currProps.onDragHoveringItemUpdateCallback
    local onHoveringItemUpdateCallbackOwner = currProps and currProps.onDragHoveringItemUpdateCallbackOwner
    local gridType = currProps and currProps.gridType
    if onHoveringItemUpdateCallback then
      tcall(onHoveringItemUpdateCallbackOwner, onHoveringItemUpdateCallback, gridType, currIndex)
    end
  end
  if prevStartIndex ~= currStartIndex then
    local onDragItemUpdateCallback = currProps and currProps.onDragItemUpdateCallback
    local onDragItemUpdateCallbackOwner = currProps and currProps.onDragItemUpdateCallbackOwner
    local gridType = currProps and currProps.gridType
    if onDragItemUpdateCallback then
      tcall(onDragItemUpdateCallbackOwner, onDragItemUpdateCallback, gridType, currStartIndex)
    end
  end
  if prevIsDragStartHovering ~= currIsDragStartHovering or prevIsDraggingHovering ~= currIsDraggingHovering then
    local onDragHoveringStateUpdateCallback = currProps and currProps.onDragHoveringStateUpdateCallback
    local onDragHoveringStateUpdateCallbackOwner = currProps and currProps.onDragHoveringStateUpdateCallbackOwner
    local gridType = currProps and currProps.gridType
    if onDragHoveringStateUpdateCallback then
      tcall(onDragHoveringStateUpdateCallbackOwner, onDragHoveringStateUpdateCallback, gridType, currIsDragStartHovering, currIsDraggingHovering)
    end
  end
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:CheckIsInArea(screenPosition)
  if not screenPosition then
    return false
  end
  local world = UE4Helper.GetCurrentWorld()
  local geometry = self:GetCachedGeometry()
  local localPosition
  if world and geometry and screenPosition then
    localPosition = UE.FVector2D(0, 0)
    UE4.USlateBlueprintLibrary.ScreenToWidgetLocal(world, geometry, screenPosition, localPosition, false)
  end
  local localPositionX = localPosition and localPosition.X or 0
  local localPositionY = localPosition and localPosition.Y or 0
  local size = UE4.USlateBlueprintLibrary.GetLocalSize(geometry)
  if not size then
    return false
  end
  local sizeX = size and size.X or 0
  local sizeY = size and size.Y or 0
  if localPositionX >= 0 and localPositionX <= sizeX and localPositionY >= 0 and localPositionY <= sizeY then
    return true
  end
  return false
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnTouchStarted(MyGeometry, InTouchEvent)
  local props = self:GetProps()
  local state = self:GetState()
  local screenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InTouchEvent)
  local screenPositionLocal = UE4.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, screenPosition)
  local screenPositionAbsolute = UE4.USlateBlueprintLibrary.LocalToAbsolute(MyGeometry, screenPositionLocal)
  local canInteract = state and state.canInteract
  local gridType = props and props.gridType
  local osTimeMs = os.msTime()
  local id = string.format("%s-%s", tostring(gridType), tostring(osTimeMs))
  local context = {}
  context.id = id
  context.gridType = props and props.gridType
  context.canInteractAtStart = canInteract or false
  context.startPositionAbsolute = screenPositionAbsolute
  context.touchPositionAbsolute = screenPositionAbsolute
  local onStartTouchCallbackOwner = props and props.onStartTouchCallbackOwner
  local onStartTouchCallback = props and props.onStartTouchCallback
  if onStartTouchCallback then
    tcall(onStartTouchCallbackOwner, onStartTouchCallback, context)
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnTouchMoved(MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnTouchEnded(MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:OnMouseWheel(MyGeometry, InTouchEvent)
  local wheelData = UE4.UKismetInputLibrary.PointerEvent_GetWheelDelta(InTouchEvent)
  local props = self:GetProps()
  local onWheelDataUpdateCallback = props and props.onWheelDataUpdateCallback
  if onWheelDataUpdateCallback then
    tcall(nil, onWheelDataUpdateCallback, wheelData)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C.GetHoveringIndex(absolutePosition, rowCount, colCount, world, geometry, localSize)
  local index = -1
  if not (world and geometry) or not absolutePosition then
    return index
  end
  absolutePosition = UE.FVector2D(absolutePosition.X, absolutePosition.Y)
  local geometryAbsolutePosition = UE4.USlateBlueprintLibrary.LocalToAbsolute(geometry, UE4.FVector2D(0, 0))
  local absoluteSize = UE.USlateBlueprintLibrary.GetAbsoluteSize(geometry)
  local absolutePositionX = absolutePosition and absolutePosition.X or 0
  local absolutePositionY = absolutePosition and absolutePosition.Y or 0
  local originalPositionX = geometryAbsolutePosition and geometryAbsolutePosition.X or 0
  local originalPositionY = geometryAbsolutePosition and geometryAbsolutePosition.Y or 0
  local positionX = absolutePositionX - originalPositionX
  local positionY = absolutePositionY - originalPositionY
  local sizeX = absoluteSize and absoluteSize.X or 0
  local sizeY = absoluteSize and absoluteSize.Y or 0
  if sizeX and sizeY and sizeX > 0 and sizeY > 0 and rowCount > 0 and colCount > 0 then
    local cellWidth = sizeX / colCount
    local cellHeight = sizeY / rowCount
    local col = math.floor(positionX / cellWidth)
    local row = math.floor(positionY / cellHeight)
    if positionX >= 0 and positionX < sizeX and positionY >= 0 and positionY < sizeY then
      index = row * colCount + col
    end
  end
  return index
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:GetLocalPositionFromScreenPosition(absolutePosition)
  local world = UE4Helper.GetCurrentWorld()
  local state = self:GetState()
  local getGeometryFn = state and state.getGeometryFn
  local geometry = getGeometryFn and getGeometryFn()
  return UMG_Pet_TeamReplace_GridTouchProxy_C.CalculateLocalPosition(absolutePosition, world, geometry)
end

function UMG_Pet_TeamReplace_GridTouchProxy_C.CalculateLocalPosition(absolutePosition, world, geometry)
  absolutePosition = UE.FVector2D(absolutePosition.X, absolutePosition.Y)
  local geometryAbsolutePosition = UE4.USlateBlueprintLibrary.LocalToAbsolute(geometry, UE4.FVector2D(0, 0))
  local localPosition = UE4.USlateBlueprintLibrary.AbsoluteToLocal(geometry, absolutePosition)
  return localPosition
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:GetProps()
  return self.stateManager:GetProps()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:SetProps(nextProps)
  self.stateManager:SetProps(nextProps)
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:GetState()
  return self.stateManager:GetState()
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:SetState(nextState)
  self.stateManager:SetState(nextState)
end

function UMG_Pet_TeamReplace_GridTouchProxy_C:GetCurrAndNextState()
  return self.stateManager:GetCurrAndNextState()
end

return UMG_Pet_TeamReplace_GridTouchProxy_C

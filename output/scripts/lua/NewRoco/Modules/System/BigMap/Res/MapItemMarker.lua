local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local MapItemBase = require("NewRoco.Modules.System.BigMap.Res.MapItemBase")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local MapItemMarker = MapItemBase:Extend("MapItemMarker")
MapItemMarker.ItemData = {}

function MapItemMarker:Ctor(parentView, layerList, iconTemplateList)
  MapItemBase.Ctor(self, parentView, layerList, iconTemplateList)
  self.iconList = {}
  self.iconPool = {}
  self.itemData = {}
  self.iconPoolRef = {}
end

function MapItemMarker:Create(itemData)
  local markerInfo = itemData.markerInfo
  local markId = markerInfo.mark_id
  if nil == markId then
    Log.Error("MapItemMarker:Create, markId is nil")
    return
  end
  local iconData = itemData.iconData
  local posX, posY = self:GetImagePos(itemData.markerInfo)
  iconData.iconImagePos = {x = posX, y = posY}
  if nil == self.iconList then
    self.iconList = {}
  end
  if self.iconList[markId] then
    self:Refresh(itemData)
  else
    self.iconList[markId] = {}
    local renderScale = 1.0 / (iconData.curMapImageScale or 1)
    local Widget = self:GetItemFromPool()
    if nil == Widget then
      Widget = MapItemBase.CreateWidget(self, iconData, renderScale)
    else
      MapItemBase.WidgetAddToViewPort(self, Widget, iconData, renderScale)
    end
    self.iconList[markId] = Widget
    self:Refresh(itemData)
  end
  self:OnTravelStateChanged(self.bTravel)
end

function MapItemMarker:Refresh(itemData)
  local markerInfo = itemData.markerInfo
  local markId = markerInfo.mark_id
  local iconData = itemData.iconData
  local itemWidget = self.iconList[markId]
  if nil == markId then
    Log.Error("MapItemMarker:Create, markId is nil or 0")
    return
  end
  if self.iconList == nil then
    Log.Error("MapItemMarker:Refresh, iconList is nil")
    return
  end
  if itemWidget then
    self.itemData[markId] = itemData
    if markerInfo.index then
      itemWidget.Slot:SetZOrder(markerInfo.index)
    else
      itemWidget.Slot:SetZOrder(markerInfo.mark_id)
    end
    itemWidget:SetSelectMarkerInfo(markerInfo)
    itemWidget:UpdateMapShowLevel(iconData.curMapSliderScale)
    itemWidget:SetPath(markerInfo.world_map_cfg_id)
    itemWidget:SetMapLayerIconVisible(BigMapModuleEnum.CreatorPriority.MarkerIcons)
    local curShowLayerId = NRCModuleManager:DoCmd(BigMapModuleCmd.GetCurShowLayerId)
    if itemWidget.mapLayerId == curShowLayerId then
      itemWidget:SetLayerMapIcon(true)
    else
      itemWidget:SetLayerMapIcon(false)
    end
    if iconData.bTracing and iconData.bTracing == true then
      itemWidget:PlayTraceEffect(true)
    else
      itemWidget:PlayTraceEffect(false)
    end
  end
end

function MapItemMarker:GetImagePos(markerInfo)
  local posX = 0
  local posY = 0
  if markerInfo.pos then
    posX = markerInfo.pos.x or 0
    posY = markerInfo.pos.y or 0
  end
  local sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
  local iconPosX, iconPosY = BigMapUtils.ScenePosToImagePos(sceneResId, posX, posY)
  return iconPosX, iconPosY
end

function MapItemMarker:GetItemData(markId)
  return self.itemData[markId]
end

function MapItemMarker:Get(markId)
  return self.iconList[markId]
end

function MapItemMarker:Destroy(markId)
  local itemWidget = self.iconList[markId]
  if itemWidget then
    itemWidget:RemoveFromParent()
    itemWidget:Destruct()
    table.removeKey(self.iconList, markId)
  end
end

function MapItemMarker:Recycle(markId)
  local iconWidget = self.iconList[markId]
  if iconWidget and UE4.UObject.IsValid(iconWidget) then
    iconWidget:RemoveFromParent()
    table.removeKey(self.iconList, markId)
    if self.iconPool == nil then
      self.iconPool = {}
    end
    table.insert(self.iconPool, iconWidget)
    table.insert(self.iconPoolRef, UnLua.Ref(iconWidget))
  end
end

function MapItemMarker:GetItemFromPool()
  if self.iconPool and #self.iconPool > 0 then
    if self.iconPoolRef and #self.iconPoolRef > 0 then
      table.remove(self.iconPoolRef, 1)
    end
    return table.remove(self.iconPool, 1)
  end
  return nil
end

function MapItemMarker:GetItemFromPool(templateIndex)
  if self.iconPool[templateIndex] and #self.iconPool[templateIndex] > 0 then
    if self.iconPoolRef[templateIndex] and #self.iconPoolRef[templateIndex] > 0 then
      table.remove(self.iconPoolRef[templateIndex], 1)
    end
    return table.remove(self.iconPool[templateIndex], 1)
  end
  return nil
end

function MapItemMarker:OnTravelStateChanged(bTravel)
  MapItemBase.OnTravelStateChanged(self, bTravel)
  if self.iconList then
    for k, v in pairs(self.iconList) do
      if bTravel then
        v:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function MapItemMarker:UpdateIconScale(_scaleParam)
  Log.Trace("MapItemMarker:UpdateIconScale", _scaleParam)
  for k, v in pairs(self.iconList) do
    if v and UE4.UObject.IsValid(v) then
      v:SetRenderScale(_scaleParam)
    end
  end
end

function MapItemMarker:UpdateIconScaleByMarkId(markId, _scaleParam)
  Log.Trace("MapItemMarker:UpdateIconScaleByMarkId", markId)
  local icon = self:Get(markId)
  if icon and UE4.UObject.IsValid(icon) then
    icon:SetRenderScale(_scaleParam)
  end
end

function MapItemMarker:SetTraceEffect(bTracing, markId)
  if self.iconList then
    local widget = self.iconList[markId]
    if widget and UE4.UObject.IsValid(widget) then
      widget:PlayTraceEffect(bTracing)
    end
  end
end

function MapItemMarker:SetIconLayer(markId, layerIndex)
  self:Recycle(markId)
  local itemData = self.itemData[markId]
  if itemData then
    itemData.iconData.layerIndex = layerIndex
    self:Create(self.itemData[markId])
  end
end

return MapItemMarker

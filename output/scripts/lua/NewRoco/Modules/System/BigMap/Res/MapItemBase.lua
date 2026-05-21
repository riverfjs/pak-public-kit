local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local MapItemBase = Class("MapItemBase")

function MapItemBase:Ctor(parentView, layerList, iconTemplateList)
  self.parentView = parentView
  self.layerList = layerList
  self.iconTemplateList = iconTemplateList
  self.data = _G.NRCModuleManager:GetModule("BigMapModule"):GetData("BigMapModuleData")
  self.bTravel = parentView.isTravel
  self.travelInfo = nil
end

function MapItemBase:Create()
end

function MapItemBase:CreateWidget(iconData, renderScale)
  local iconTemplate, iconLayer
  iconTemplate = self.iconTemplateList[iconData.iconTemplateIndex]
  iconLayer = self.layerList[iconData.layerIndex]
  local iconWidget = UE4.UWidgetBlueprintLibrary.Create(self.parentView, iconTemplate)
  self:WidgetAddToViewPort(iconWidget, iconData, renderScale)
  return iconWidget
end

function MapItemBase:WidgetAddToViewPort(iconWidget, iconData, renderScale)
  local posX = iconData.iconImagePos.x
  local posY = iconData.iconImagePos.y
  local scale = renderScale or 1
  local iconLayer = self.layerList[iconData.layerIndex]
  local iconSlot
  if iconWidget and iconLayer then
    iconSlot = iconLayer:AddChild(iconWidget)
    if iconSlot then
      iconSlot:SetPosition(UE4.FVector2D(posX, posY))
      iconSlot:SetAnchors(UE4.FAnchors(0.5))
      iconSlot:SetAlignment(UE4.FVector2D(0.5, 0.5))
      iconSlot:SetAutoSize(true)
      iconSlot:SetZOrder(iconData.ZOrder)
      iconWidget:SetRenderScale(UE4.FVector2D(scale, scale))
    else
      Log.Error("iconslot \231\169\186\228\186\134\239\188\129")
    end
  end
end

function MapItemBase:CreateTraceWidget(traceData, zOrder)
  zOrder = zOrder or 1
  local iconTemplate, iconLayer
  iconTemplate = self.iconTemplateList[traceData.traceType]
  iconLayer = self.layerList[4]
  local iconWidget = UE4.UWidgetBlueprintLibrary.Create(self.parentView, iconTemplate)
  local posX, posY = 0, 0
  if traceData.iconImagePos then
    posX = traceData.iconImagePos.x
    posY = traceData.iconImagePos.y
  else
    local npcInfo = traceData.npcInfo
    if npcInfo and npcInfo.npc_pos then
      posX = npcInfo.npc_pos.x
      posY = npcInfo.npc_pos.y
      local sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
      posX, posY = BigMapUtils.ScenePosToImagePosF(sceneResId, posX, posY)
    end
  end
  local iconSlot
  if iconWidget and iconLayer then
    iconSlot = iconLayer:AddChild(iconWidget)
    iconSlot:SetPosition(UE4.FVector2D(posX, posY))
    iconSlot:SetAnchors(UE4.FAnchors(0.5))
    iconSlot:SetAlignment(UE4.FVector2D(0.5, 0.5))
    iconSlot:SetAutoSize(true)
    iconSlot:SetZOrder(traceData.traceType * 10 + zOrder)
  end
  return iconWidget
end

function MapItemBase:CreateImageWidget(iconData, imageData)
  local template
  if iconData.iconTemplateIndex == nil or 0 == iconData.iconTemplateIndex then
    template = self.iconTemplateList
  else
    template = self.iconTemplateList[iconData.iconTemplateIndex]
  end
  local imageWidget = UE4.UWidgetBlueprintLibrary.Create(self.parentView, template)
  local imageSlot, iconLayer
  if nil == iconData.layerIndex or 0 == iconData.layerIndex then
    iconLayer = self.layerList
  else
    iconLayer = self.layerList[iconData.layerIndex]
  end
  if imageWidget and iconLayer then
    imageSlot = iconLayer:AddChild(imageWidget)
    imageSlot:SetPosition(UE4.FVector2D(iconData.iconImagePos.x, iconData.iconImagePos.y))
    imageSlot:SetSize(imageData.imageScale)
    imageSlot:SetAnchors(UE4.FAnchors(0.5))
    imageSlot:SetAlignment(UE4.FVector2D(0, 0))
  end
  return imageWidget
end

function MapItemBase:Refresh()
end

function MapItemBase:Get()
end

function MapItemBase:Destroy()
end

function MapItemBase:DestroyAll()
  if self.iconList then
    for k, v in pairs(self.iconList) do
      self:Destroy(k)
    end
    self.iconList = nil
  end
  self.parentView = nil
  self.layerList = nil
  self.iconTemplateList = nil
end

function MapItemBase:ClearAll()
  if self.iconList then
    for k, v in pairs(self.iconList) do
      self:Destroy(k)
    end
    self.iconList = {}
  end
end

function MapItemBase:UpdateMapShowLevel(_sliderScale, _scale, _scaleRatio)
  if self.iconList then
    for k, v in pairs(self.iconList) do
      if #v > 0 then
        for key, val in pairs(v) do
          if val and val.UpdateMapShowLevel then
            val:UpdateMapShowLevel(_sliderScale, _scale, _scaleRatio)
          end
        end
      elseif v and v.UpdateMapShowLevel then
        v:UpdateMapShowLevel(_sliderScale, _scale, _scaleRatio)
      end
    end
  end
end

function MapItemBase:UpdateIconScale(_scaleParam)
end

function MapItemBase:OnTravelStateChanged(bTravel)
  self.bTravel = bTravel
end

function MapItemBase:OnTravelInfoUpdated(travelInfo)
  self.travelInfo = travelInfo
end

function MapItemBase:SetIconPos(type, key, pos, extraKey)
  if type == BigMapModuleEnum.CreatorPriority.MarkerIcons or type == BigMapModuleEnum.CreatorPriority.VisitorIcons then
    local iconWidget = self:Get(key)
    if iconWidget and UE4.UObject.IsValid(iconWidget) and iconWidget.Slot then
      iconWidget.Slot:SetPosition(pos)
    end
  elseif type == BigMapModuleEnum.CreatorPriority.TaskIcons or type == BigMapModuleEnum.CreatorPriority.NpcIcons then
    local iconWidget = self:Get(key, extraKey)
    if iconWidget and UE4.UObject.IsValid(iconWidget) and iconWidget.Slot then
      iconWidget.Slot:SetPosition(pos)
    end
  end
end

function MapItemBase:SetUpOrDown(type, bUp, key, extraKey)
  if type == BigMapModuleEnum.CreatorPriority.NpcIcons or type == BigMapModuleEnum.CreatorPriority.MarkerIcons then
    local iconWidget = self:Get(key, extraKey)
    if iconWidget and UE4.UObject.IsValid(iconWidget) then
      if iconWidget.Up then
        if bUp == BigMapModuleEnum.IconDirection.Up then
          iconWidget.Up:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          iconWidget.Up:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      if iconWidget.Down then
        if bUp == BigMapModuleEnum.IconDirection.Down then
          iconWidget.Down:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          iconWidget.Down:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    end
  end
end

function MapItemBase:SetItemVisibility(bShow, type, key, extraKey)
  if type == BigMapModuleEnum.CreatorPriority.TaskIcons then
    local itemWidgets = self:Get(key)
    if itemWidgets and #itemWidgets > 0 then
      for k, itemWidget in ipairs(itemWidgets) do
        if bShow then
          itemWidget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          itemWidget:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    end
  elseif type == BigMapModuleEnum.CreatorPriority.NpcIcons then
    local itemWidget = self:Get(key, extraKey)
    if itemWidget and UE4.UObject.IsValid(itemWidget) then
      if bShow then
        itemWidget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        itemWidget:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  else
    local itemWidget = self:Get(key)
    if itemWidget and UE4.UObject.IsValid(itemWidget) then
      if bShow then
        itemWidget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        itemWidget:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

return MapItemBase

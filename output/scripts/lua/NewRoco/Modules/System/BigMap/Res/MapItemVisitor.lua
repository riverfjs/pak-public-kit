local MapItemBase = require("NewRoco.Modules.System.BigMap.Res.MapItemBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local MapItemVisitor = MapItemBase:Extend("MapItemVisitor")
MapItemVisitor.ItemData = {}

function MapItemVisitor:Ctor(parentView, layerList, iconTemplateList)
  MapItemBase.Ctor(self, parentView, layerList, iconTemplateList)
  self.iconList = {}
end

function MapItemVisitor:Create(itemData)
  self:Refresh(itemData)
end

function MapItemVisitor:Refresh(itemData)
  local visitorInfo = itemData.visitorInfo
  local itemWidget
  local iconData = itemData.iconData
  local BigMapModule = NRCModuleManager:GetModule("BigMapModule")
  if visitorInfo and #visitorInfo > 0 then
    local renderScale = 1.0 / (iconData.curMapImageScale or 1)
    for k, v in ipairs(visitorInfo) do
      local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      if v.uin ~= myUin then
        local posX, posY = self:GetImagePos(v)
        iconData.iconImagePos = {x = posX, y = posY}
        iconData.ZOrder = k
        local curSceneResId = BigMapUtils.GetDefaultSceneResId()
        local iconSceneResId = BigMapUtils.GetDefaultSceneResId()
        local sceneResId1, iconSceneResId1 = BigMapUtils.GetVisitorIconSceneResIdAndPos(v)
        if iconData.bMiniMap then
          curSceneResId = SceneUtils.GetSceneResId()
          iconSceneResId = sceneResId1
        else
          curSceneResId = NRCModuleManager:DoCmd(BigMapModuleCmd.GetCurShowSceneResId)
          iconSceneResId = iconSceneResId1
        end
        if self.iconList[v.uin] then
          itemWidget = self.iconList[v.uin]
        elseif not iconData.bMiniMap and curSceneResId == iconSceneResId or iconData.bMiniMap and (curSceneResId == iconSceneResId or curSceneResId == iconSceneResId1) then
          self.iconList[v.uin] = {}
          itemWidget = MapItemBase.CreateWidget(self, iconData, renderScale)
          self.iconList[v.uin] = itemWidget
        end
        if itemWidget then
          if iconData.bMiniMap then
            itemWidget:SetMarkerIndex(v, k)
            itemWidget:UpdateMapShowLevel(iconData.curMapSliderScale)
          else
            itemWidget.Slot:SetPosition(UE4.FVector2D(posX, posY))
            if curSceneResId == iconSceneResId then
              itemWidget:SetMarkerIndex(v, k)
              itemWidget:UpdateMapShowLevel(iconData.curMapSliderScale)
            else
              itemWidget:SetIconVisible(false)
            end
          end
        end
      end
    end
  end
  local removeList = {}
  local visitorIndex = 0
  if self.iconList then
    for _uin, v in pairs(self.iconList) do
      local hasSame = false
      visitorIndex = visitorIndex + 1
      local removeInfo = v.uiData
      if visitorInfo and #visitorInfo > 0 then
        for i, val in ipairs(visitorInfo) do
          local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
          if v.uin ~= myUin then
            removeInfo = v.uiData
            if _uin == val.uin then
              hasSame = true
              break
            end
          end
        end
      end
      if false == hasSame then
        table.insert(removeList, removeInfo)
      end
    end
  end
  if removeList and #removeList > 0 then
    for k, v in ipairs(removeList) do
      self:Destroy(v.uin)
    end
  end
end

function MapItemVisitor:GetImagePos(visitorInfo)
  local sceneResId, iconSceneResId, posX, posY = BigMapUtils.GetVisitorIconSceneResIdAndPos(visitorInfo)
  local iconPosX, iconPosY = BigMapUtils.ScenePosToImagePosF(iconSceneResId, posX, posY)
  return iconPosX, iconPosY
end

function MapItemVisitor:UpdateIconScale(_scaleParam)
  for k, v in pairs(self.iconList) do
    if v and UE4.UObject.IsValid(v) then
      v:SetRenderScale(_scaleParam)
    end
  end
end

function MapItemVisitor:UpdateIconScaleByUin(uin, _scaleParam)
  local icon = self:Get(uin)
  if icon and UE4.UObject.IsValid(icon) then
    icon:SetRenderScale(_scaleParam)
  end
end

function MapItemVisitor:Get(uin)
  return self.iconList[uin]
end

function MapItemVisitor:Destroy(uin)
  local iconWidget = self.iconList[uin]
  if iconWidget then
    iconWidget:RemoveFromParent()
    iconWidget:Destruct()
    table.removeKey(self.iconList, uin)
  end
end

function MapItemVisitor:DestroyAll()
  if self.iconList then
    for k, v in pairs(self.iconList) do
      self:Destroy(k)
    end
    self.iconList = nil
  end
end

return MapItemVisitor

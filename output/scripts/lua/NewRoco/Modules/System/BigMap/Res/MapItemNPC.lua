local MapItemBase = require("NewRoco.Modules.System.BigMap.Res.MapItemBase")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local MapItemNPC = MapItemBase:Extend("MapItemNPC")
MapItemNPC.ItemData = {}

function MapItemNPC:Ctor(parentView, layerList, iconTemplateList)
  MapItemBase.Ctor(self, parentView, layerList, iconTemplateList)
  self.iconList = {}
  self.iconPool = {}
  self.itemData = {}
  self.templateList = {}
  self.iconPoolRef = {}
  self.allLogicIdList = {}
  self.logicIdToEntryIdMap = {}
end

function MapItemNPC:Create(itemData)
  local entryId = itemData.npcInfo.entry_id
  if nil == entryId or 0 == entryId then
    Log.Error("MapItemNPC:Create, entryId is nil or 0")
    return
  end
  local logicId = itemData.npcInfo.logic_id or entryId
  local templateIndex = self:GetIconTemplate(itemData)
  local iconData = itemData.iconData
  iconData.iconTemplateIndex = templateIndex
  if nil == iconData.layerIndex or iconData.layerIndex <= 0 then
    iconData.layerIndex = BigMapUtils.GetNpcIconLayer(itemData.npcInfo, iconData.bMiniMap)
  end
  iconData.ZOrder = self:GetZOrder(itemData.npcInfo.world_map_cfg_id)
  itemData.iconData = iconData
  if nil == self.iconList then
    self.iconList = {}
  end
  if nil == self.iconList[entryId] then
    self.iconList[entryId] = {}
  end
  if self.iconList[entryId][logicId] then
    if (self.itemData and self.itemData[entryId] and self.itemData[entryId][logicId] and self.itemData[entryId][logicId].iconData.layerIndex) ~= (itemData and itemData.iconData and itemData.iconData.layerIndex) then
      self:Recycle(entryId, logicId)
      local renderScale = 1.0 / (iconData.curMapImageScale or 1)
      local Widget = self:GetItemFromPool(templateIndex)
      MapItemBase.WidgetAddToViewPort(self, Widget, iconData, renderScale)
      Widget:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.iconList[entryId][logicId] = Widget
    end
    self:Refresh(itemData)
  else
    local renderScale = 1.0 / (iconData.curMapImageScale or 1)
    local Widget = self:GetItemFromPool(templateIndex)
    if nil == Widget or not UE4.UObject.IsValid(Widget) then
      Widget = MapItemBase.CreateWidget(self, iconData, renderScale)
    else
      MapItemBase.WidgetAddToViewPort(self, Widget, iconData, renderScale)
      Widget:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.iconList[entryId][logicId] = Widget
    self:Refresh(itemData)
  end
  if nil == self.templateList[entryId] then
    self.templateList[entryId] = {}
  end
  self.templateList[entryId][logicId] = templateIndex
end

function MapItemNPC:Refresh(itemData)
  local entryId = itemData.npcInfo.entry_id
  if nil == entryId or 0 == entryId then
    Log.Error("MapItemNPC:Create, entryId is nil or 0")
    return
  end
  local logicId = itemData.npcInfo.logic_id or entryId
  if nil == self.iconList then
    Log.Error("MapItemNPC:Refresh, iconList is nil")
    return
  end
  if self.iconList[entryId] and self.iconList[entryId][logicId] then
    local _npcInfo = itemData.npcInfo
    local iconData = itemData.iconData
    iconData.ZOrder = self:GetZOrder(_npcInfo.world_map_cfg_id)
    local itemWidget = self.iconList[entryId][logicId]
    local worldMapConf = _G.DataConfigManager:GetWorldMapConf(_npcInfo.world_map_cfg_id)
    if itemWidget and UE4.UObject.IsValid(itemWidget) then
      if nil == self.itemData[entryId] then
        self.itemData[entryId] = {}
      end
      self.logicIdToEntryIdMap[logicId] = entryId
      self.itemData[entryId][logicId] = itemData
      itemWidget:SetData(_npcInfo, worldMapConf)
      itemWidget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if iconData.bTracing and iconData.bTracing == true then
        itemWidget:PlayTraceEffect(true)
      else
        itemWidget:PlayTraceEffect(false)
      end
      itemWidget:UpdateMapShowLevel(iconData.curMapSliderScale)
      itemWidget:SetShowTime(_npcInfo)
      itemWidget:SetMapLayerIconVisible(BigMapModuleEnum.CreatorPriority.NpcIcons)
      itemWidget:SetPetOwnerVisible()
      local curShowLayerId = NRCModuleManager:DoCmd(BigMapModuleCmd.GetCurShowLayerId)
      if itemWidget.mapLayerId == curShowLayerId then
        itemWidget:SetLayerMapIcon(true)
      else
        itemWidget:SetLayerMapIcon(false)
      end
      if _npcInfo.npcCfg and _npcInfo.npcCfg.genre == _G.Enum.ClientNpcType.CNT_HOME_NPC then
        itemWidget.Slot:SetPosition(UE4.FVector2D(itemData.iconData.iconImagePos.x, itemData.iconData.iconImagePos.y))
      end
    end
  end
end

function MapItemNPC:GetIconTemplate(itemData)
  if itemData.npcInfo == nil then
    Log.Error("MapItemNPC:GetIconTemplate, npcInfo is nil")
    return nil
  end
  local _npcInfo = itemData.npcInfo
  local iconTemplateIndex = 1
  local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(_npcInfo.world_map_cfg_id)
  if _npcInfo.npcCfg then
    if _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS or _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT then
      if worldMapCfg and worldMapCfg.map_show_type == Enum.MapIconShowType.MAP_HANDBOOK_TRACK then
        iconTemplateIndex = 3
      else
        iconTemplateIndex = 1
      end
    elseif _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_CAMP or _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_TELEPORT or _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_FLOWER_SEED or worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY or worldMapCfg.map_show_type == Enum.MapIconShowType.MAP_ACTIVITY_AREA then
      iconTemplateIndex = 2
    elseif _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_HOME_NPC then
      iconTemplateIndex = 1
    else
      local isShowCathPet = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.IsShowCatchPet, _npcInfo.npc_refresh_id)
      if worldMapCfg.map_func_icon_group and worldMapCfg.map_func_icon_group == _G.Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
        iconTemplateIndex = 2
      elseif isShowCathPet then
        if worldMapCfg.map_func_icon_group and worldMapCfg.map_func_icon_group == _G.Enum.MapFuncIconGroup.MFIG_NPCROLE then
          iconTemplateIndex = 3
        elseif worldMapCfg.default_track_type == Enum.DefaultTrackType.DTT_SHINE then
          if nil == _npcInfo.mutation_type or PetMutationUtils.GetMutationValue(_npcInfo.mutation_type, Enum.MutationDiffType.MDT_SHINING) then
            iconTemplateIndex = 2
          else
            iconTemplateIndex = 3
          end
        else
          iconTemplateIndex = 2
        end
      elseif worldMapCfg.map_tips_show_type and worldMapCfg.map_tips_show_type == _G.ProtoEnum.MapTipsShowType.MAP_TIPS_DUNGEON then
        iconTemplateIndex = 2
      else
        iconTemplateIndex = 3
      end
    end
  end
  return iconTemplateIndex
end

function MapItemNPC:GetZOrder(worldMapCfgId)
  local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
  if worldMapCfg then
    if worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CAMP then
      return -1
    elseif worldMapCfg.icon_priority then
      return worldMapCfg.icon_priority
    else
      return 0
    end
  end
  return 0
end

function MapItemNPC:Get(entryId, logicId)
  logicId = logicId or entryId
  if self.iconList[entryId] then
    return self.iconList[entryId][logicId]
  end
end

function MapItemNPC:GetItemData(entryId, logicId)
  logicId = logicId or entryId
  if self.itemData[entryId] then
    return self.itemData[entryId][logicId]
  end
end

function MapItemNPC:GetAllLogicId()
  table.clear(self.allLogicIdList)
  for entryId, icons in pairs(self.iconList) do
    for logicId, icon in pairs(icons) do
      if logicId then
        table.insert(self.allLogicIdList, logicId)
      end
    end
  end
  return self.allLogicIdList
end

function MapItemNPC:Destroy(entryId, logicId)
  logicId = logicId or entryId
  if self.iconList[entryId] then
    local itemWidget = self.iconList[entryId][logicId]
    if itemWidget and UE4.UObject.IsValid(itemWidget) then
      itemWidget:RemoveFromParent()
      itemWidget:Destruct()
      self.logicIdToEntryIdMap[logicId] = nil
      table.removeKey(self.iconList[entryId], logicId)
      if table.isEmpty(self.iconList[entryId]) then
        table.removeKey(self.iconList, entryId)
      end
    end
  end
end

function MapItemNPC:ClearAll()
  if self.iconList then
    for entryId, icons in pairs(self.iconList) do
      for logicId, icon in pairs(icons) do
        self:Destroy(entryId, logicId)
      end
    end
  end
end

function MapItemNPC:Recycle(entryId, logicId)
  logicId = logicId or entryId
  if self.iconList and self.iconList[entryId] then
    local iconWidget = self.iconList[entryId][logicId]
    if iconWidget and UE4.UObject.IsValid(iconWidget) then
      iconWidget:RemoveFromParent()
      self.logicIdToEntryIdMap[logicId] = nil
      table.removeKey(self.iconList[entryId], logicId)
      if self.templateList and self.templateList[entryId] then
        local templateIndex = self.templateList[entryId][logicId]
        if templateIndex and templateIndex > 0 then
          if nil == self.iconPool[templateIndex] then
            self.iconPool[templateIndex] = {}
          end
          if nil == self.iconPoolRef[templateIndex] then
            self.iconPoolRef[templateIndex] = {}
          end
          table.insert(self.iconPool[templateIndex], iconWidget)
          table.insert(self.iconPoolRef[templateIndex], UnLua.Ref(iconWidget))
        end
      end
    end
  end
end

function MapItemNPC:GetItemFromPool(templateIndex)
  if self.iconPool[templateIndex] and #self.iconPool[templateIndex] > 0 then
    if self.iconPoolRef[templateIndex] and #self.iconPoolRef[templateIndex] > 0 then
      table.remove(self.iconPoolRef[templateIndex], 1)
    end
    return table.remove(self.iconPool[templateIndex], 1)
  end
  return nil
end

function MapItemNPC:OnTravelStateChanged(bTravel)
  MapItemBase.OnTravelStateChanged(self, bTravel)
  for entryId, icons in pairs(self.iconList) do
    for logicId, icon in pairs(icons) do
      if icon and UE.UObject.IsValid(icon) then
        local worldMapCfg
        if bTravel then
          if icon.uiData and icon.uiData.world_map_cfg_id then
            worldMapCfg = _G.DataConfigManager:GetWorldMapConf(icon.uiData.world_map_cfg_id)
          end
          if worldMapCfg and worldMapCfg.map_tips_show_type ~= Enum.MapTipsShowType.MAP_TIPS_CAMP then
            self:SetItemVisibility(false, BigMapModuleEnum.CreatorPriority.NpcIcons, entryId)
          else
            icon:ShowTravel(icon.uiData)
            if nil == _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetTravelInfo, icon.uiData.npc_refresh_id) and UE4.UObject.IsValid(icon.Travel_DuringJourney) then
              icon.Travel_DuringJourney:SetVisibility(UE4.ESlateVisibility.Collapsed)
            end
          end
        else
          self:SetItemVisibility(true, BigMapModuleEnum.CreatorPriority.NpcIcons, entryId)
          if UE4.UObject.IsValid(v.Travel_DuringJourney) then
            icon.Travel_DuringJourney:SetVisibility(UE4.ESlateVisibility.Collapsed)
          end
        end
      end
    end
  end
end

function MapItemNPC:UpdateIconScale(_scaleParam)
  for entryId, iconList in pairs(self.iconList) do
    for logicId, icon in pairs(iconList) do
      if icon and UE4.UObject.IsValid(icon) then
        icon:SetRenderScale(_scaleParam)
      end
    end
  end
end

function MapItemNPC:UpdateIconScaleById(entryId, logicId, _scaleParam)
  local icon = self:Get(entryId, logicId)
  if icon and UE4.UObject.IsValid(icon) then
    icon:SetRenderScale(_scaleParam)
  end
end

function MapItemNPC:UpdateMapShowLevel(_sliderScale, _scale, _scaleRatio)
  if self.iconList then
    for entryId, icons in pairs(self.iconList) do
      for logicId, icon in pairs(icons) do
        if self.bTravel then
          if icon.uiData and icon.uiData.world_map_cfg_id then
            local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(icon.uiData.world_map_cfg_id)
            if worldMapCfg and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CAMP and icon and icon.UpdateMapShowLevel then
              icon:UpdateMapShowLevel(_sliderScale, _scale, _scaleRatio)
            end
          end
        elseif icon and icon.UpdateMapShowLevel then
          icon:UpdateMapShowLevel(_sliderScale, _scale, _scaleRatio)
        end
      end
    end
  end
end

function MapItemNPC:SetTraceEffect(bTracing, entryId, logicId)
  if self.iconList then
    local icons = self.iconList[entryId]
    if icons then
      local icon = icons[logicId]
      if icon and UE4.UObject.IsValid(icon) then
        icon:PlayTraceEffect(bTracing)
      end
    end
  end
end

function MapItemNPC:SetIconLayer(entryId, logicId, layerIndex)
  self:Recycle(entryId, logicId)
  if self.itemData[entryId] and self.itemData[entryId][logicId] then
    local itemData = self.itemData[entryId][logicId]
    itemData.iconData.layerIndex = layerIndex
    self:Create(self.itemData[entryId][logicId])
  end
end

function MapItemNPC:SetIconTempFlag(entryId, logicId, bTemp)
  if self.itemData[entryId] and self.itemData[entryId][logicId] then
    self.itemData[entryId][logicId].iconData.bTemp = bTemp
  end
end

function MapItemNPC:GetEntryIdByLogicId(logicId)
  return self.logicIdToEntryIdMap[logicId]
end

function MapItemNPC:UpdateItemDataImagePos(entryId, logicId, posX, posY)
  local itemData = self:GetItemData(entryId, logicId)
  local iconImagePos = itemData and itemData.iconData and itemData.iconData.iconImagePos
  if nil == iconImagePos then
    return
  end
  iconImagePos.x = posX
  iconImagePos.y = posY
end

return MapItemNPC

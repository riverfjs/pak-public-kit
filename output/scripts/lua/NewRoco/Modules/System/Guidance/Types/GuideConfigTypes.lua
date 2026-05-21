local DefaultTargetPanel = "UMG_LobbyMain"
local GuideConfigTypes = {}
GuideConfigTypes.ConditionOperator = {
  None = -1,
  Or = 0,
  And = 1
}
GuideConfigTypes.ConditionType = {
  InValid = -2,
  None = -1,
  Task = 0,
  Option = 1,
  Dialogue = 2,
  Button = 3,
  WorldCombat = 4,
  Panel = 5,
  PlayerStatus = 6,
  HomeFurniture = 7,
  GuideSetting = 100,
  Locally = 1000
}
GuideConfigTypes.GuideStyleType = {
  None = -1,
  Focus = 0,
  Banner = 1,
  Highlight = 2,
  Drag = 3
}
GuideConfigTypes.SubConfigState = {
  None = -1,
  Activated = 0,
  Pending = 1,
  Triggered = 2,
  Completed = 4
}
GuideConfigTypes.DragElementType = {
  None = 0,
  Widget = 1,
  Screen = 2
}

function GuideConfigTypes.StringToConditionOperator(str)
  if "or" == str then
    return GuideConfigTypes.ConditionOperator.Or
  elseif "and" == str then
    return GuideConfigTypes.ConditionOperator.And
  end
  return GuideConfigTypes.ConditionOperator.None
end

function GuideConfigTypes.StringToConditionType(str)
  if "" == str then
    return GuideConfigTypes.ConditionType.None
  elseif "task" == str then
    return GuideConfigTypes.ConditionType.Task
  elseif "option" == str then
    return GuideConfigTypes.ConditionType.Option
  elseif "dialogue" == str then
    return GuideConfigTypes.ConditionType.Dialogue
  elseif "ui_button" == str then
    return GuideConfigTypes.ConditionType.Button
  elseif "worldcombat" == str then
    return GuideConfigTypes.ConditionType.WorldCombat
  elseif "panel" == str then
    return GuideConfigTypes.ConditionType.Panel
  elseif "status" == str then
    return GuideConfigTypes.ConditionType.PlayerStatus
  elseif "home_furniture" == str then
    return GuideConfigTypes.ConditionType.HomeFurniture
  elseif "none" == str then
    return GuideConfigTypes.ConditionType.Locally
  end
  return GuideConfigTypes.ConditionType.InValid
end

function GuideConfigTypes.StringToGuideStyleType(str)
  if "GUIDE_FOCUS" == str then
    return GuideConfigTypes.GuideStyleType.Focus
  elseif "GUIDE_BANNER" == str then
    return GuideConfigTypes.GuideStyleType.Banner
  elseif "GUIDE_HIGHLIGHT" == str then
    return GuideConfigTypes.GuideStyleType.Highlight
  elseif "GUIDE_DRAG" == str then
    return GuideConfigTypes.GuideStyleType.Drag
  end
  return GuideConfigTypes.GuideStyleType.None
end

function GuideConfigTypes.GetGuideConditionConfig(condition, param1, param2)
  if not (condition and param1) or not param2 then
    return nil
  end
  local type = GuideConfigTypes.StringToConditionType(condition)
  if type == GuideConfigTypes.ConditionType.None then
    return nil
  end
  if type == GuideConfigTypes.ConditionType.Panel then
    local panelConf = _G.DataConfigManager:GetGuidePanelConf(param1)
    if panelConf and panelConf.panel_custom_type then
      local customTypeString = panelConf.panel_custom_type
      if customTypeString and "" ~= customTypeString then
        local customPanelType = tonumber(customTypeString)
        Log.Debug("GuideConfigTypes.GetGuideConditionConfig found custom panel", param1, param2, customPanelType)
        return {
          type = GuideConfigTypes.ConditionType.Panel,
          param1 = param1,
          param2 = param2,
          param1Custom = customPanelType
        }
      end
    end
  end
  return {
    type = type,
    param1 = param1,
    param2 = param2
  }
end

function GuideConfigTypes.GetWidgetNameFromPanelData(panelData)
  if panelData and panelData.panelPath then
    local panelPath = panelData.panelPath
    local lastSplash = string.find(panelPath, "/[^/]*$")
    local stop = string.find(panelPath, "%.")
    if lastSplash and stop then
      panelPath = string.sub(panelPath, lastSplash + 1, stop - 1)
      return panelPath
    end
  end
  return nil
end

function GuideConfigTypes.GetTargetWidget(ui_path, ui_button_name, bUseLobbyMainAsDefault)
  if not ui_path or #ui_path <= 0 then
    if bUseLobbyMainAsDefault then
      ui_path = {DefaultTargetPanel}
      ui_button_name = nil
    else
      return nil
    end
  end
  local topWidgetName = ui_path[1]
  local panelDict = _G.NRCPanelManager:GetPanelDict()
  if not panelDict then
    return nil
  end
  local topWidget, panelData
  for _, moduleDict in pairs(panelDict) do
    for _, panelList in pairs(moduleDict) do
      for _, panelInst in pairs(panelList) do
        if panelInst then
          local inst = panelInst.inst
          if inst and inst.panelData then
            local widgetName = GuideConfigTypes.GetWidgetNameFromPanelData(inst.panelData)
            if widgetName == topWidgetName then
              topWidget = inst
              panelData = inst.panelData
              break
            end
          end
        end
      end
    end
  end
  if not topWidget then
    Log.Debug("GuideConfigTypes.GetTargetWidget: topWidget is nil", topWidgetName)
    return nil
  end
  local pathWidgets = {topWidget}
  local currentWidget = topWidget
  for idx = 2, #ui_path do
    local nextWidget = GuideConfigTypes.GetChildWidget(currentWidget, ui_path[idx])
    if not nextWidget then
      Log.Debug("GuideConfigTypes.GetTargetWidget: cannot find widget", topWidgetName, ui_path[idx], idx)
      return nil
    end
    if nextWidget.name == "BP_NRCUmgLoader_C" and nextWidget.GetPanel then
      local panel = nextWidget:GetPanel()
      if not panel then
        Log.Debug("GuideConfigTypes.GetTargetWidget: GetPanel is nil in UNRCWidgetLoader", topWidgetName, idx, ui_path[idx])
        return nil
      end
      nextWidget = panel
    end
    if nextWidget.panelData then
      panelData = nextWidget.panelData
    end
    currentWidget = nextWidget
    table.insert(pathWidgets, nextWidget)
  end
  if not ui_button_name then
    return currentWidget, panelData, pathWidgets
  end
  local targetWidget = UE4.UNRCStatics.GetWidgetFromName(currentWidget, ui_button_name)
  if not targetWidget then
    Log.Debug("GuideConfigTypes.GetTargetWidget: cannot find targetWidget", topWidgetName, ui_button_name)
    return nil
  end
  return targetWidget, panelData, pathWidgets
end

function GuideConfigTypes.GetChildWidget(widget, name)
  if not (widget and UE4.UObject.IsValid(widget)) or not name then
    return nil
  end
  local customListName, customListIndexString = name:match("^(.+)%<(%d+)%>$")
  if customListName and customListIndexString then
    local target, realIndex
    local listWidget = widget[customListName]
    local customIndexNumber = tonumber(customListIndexString)
    if listWidget and customIndexNumber then
      local itemCount = 0
      local getItemByIndexFunc
      local guidanceListRecord = {}
      if listWidget.GetNumItems and listWidget.GetItemAt then
        itemCount = listWidget:GetNumItems()
        getItemByIndexFunc = listWidget.GetItemAt
        guidanceListRecord.list = listWidget
      elseif listWidget.itemCount and listWidget.GetItemByIndex then
        itemCount = listWidget.itemCount
        getItemByIndexFunc = listWidget.GetItemByIndex
        guidanceListRecord.scroll = listWidget
      elseif listWidget.GetItemCount and listWidget.GetItemByIndex then
        itemCount = listWidget:GetItemCount()
        getItemByIndexFunc = listWidget.GetItemByIndex
        guidanceListRecord.grid = listWidget
      end
      for i = 1, itemCount do
        local item = getItemByIndexFunc(listWidget, i - 1)
        if UE4.UObject.IsValid(item) and item.GetGuidanceCustomListIndex then
          local customIndex = item:GetGuidanceCustomListIndex()
          if customIndex == customIndexNumber then
            target = item
            realIndex = i
            break
          end
        end
      end
      if target and realIndex then
        guidanceListRecord.index = realIndex
        target.GuidanceListRecord = guidanceListRecord
        return target
      end
    end
  end
  local listName, listIndexString = name:match("^(.+)%[(%d+)%]$")
  if listName and listIndexString then
    local item, index
    local listWidget = widget[listName]
    local listIndexNumber = tonumber(listIndexString)
    local guidanceListRecord = {}
    if listWidget and listIndexNumber then
      if listWidget.GetNumItems and listWidget.GetItemAt then
        index = math.min(listIndexNumber, listWidget:GetNumItems())
        item = listWidget:GetItemAt(index - 1)
        guidanceListRecord.list = listWidget
      elseif listWidget.itemCount and listWidget.GetItemByIndex then
        index = math.min(listIndexNumber, listWidget.itemCount)
        item = listWidget:GetItemByIndex(index - 1)
        guidanceListRecord.scroll = listWidget
      elseif listWidget.GetItemCount and listWidget.GetItemByIndex then
        index = math.min(listIndexNumber, listWidget:GetItemCount())
        item = listWidget:GetItemByIndex(index - 1)
        guidanceListRecord.grid = listWidget
      end
      if item then
        guidanceListRecord.index = index
        item.GuidanceListRecord = guidanceListRecord
        return item
      end
    end
  else
    return UE4.UNRCStatics.GetWidgetFromName(widget, name)
  end
  return nil
end

local LayerIgnoredPanels = {
  "AdditionalTarget",
  "CompassUnlockTips",
  "LobbyPropTips",
  "LobbyDownTips",
  "NPCInteractMain",
  "TemperatureHot",
  "TemperatureCold",
  "DialogueOverlay",
  "RolePlay_GetTips",
  "MiniGamePanel",
  "MiniGameModuleNightmarePanel",
  "LegendaryTaskUnlockTips",
  "TeachingUnlockTips",
  "MarqueePanel",
  "AntiAddiction_PullDown",
  "FruitTreeTips",
  "LeaderFightTips",
  "NPCRosterTip",
  "MusicCollectTips",
  "UMG_TopHUD",
  "ZoneTip",
  "UniversalTips",
  "Screenshotsharing",
  "MaterialItems"
}
local IgnoreCompareLayerPanelPairs = {
  NewPetBag = {
    "NewPetBagBox"
  },
  HandbookCover = {
    "HandBook_RegionalSelection"
  },
  BattleMain = {
    "BattleRunAwayTip",
    "HudPerceptionPanel",
    "BattlePopUpTips",
    "BattleProcess_Visible",
    "BattleRedPanel",
    "PVPValueNumber"
  }
}

function GuideConfigTypes.IsTopPanel(panelData, selfPanelData)
  if not panelData then
    return false
  end
  if panelData.moduleName == "GuidanceModule" then
    return false
  end
  if table.contains(LayerIgnoredPanels, panelData.panelName) then
    return false
  end
  if panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_DEBUG or panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_TOP_MARK or panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_TOP_MSG then
    return false
  end
  if selfPanelData then
    local ignoredPanelPairs = IgnoreCompareLayerPanelPairs[selfPanelData.panelName]
    if ignoredPanelPairs and table.contains(ignoredPanelPairs, panelData.panelName) then
      return false
    end
  end
  return true
end

function GuideConfigTypes.ComparePanelLayer(layerA, layerB)
  if not layerA or not layerB then
    return false
  end
  local layerCenter = _G.NRCPanelManager.layerCenter
  if not layerCenter then
    return false
  end
  local layerCtrlA = layerCenter:GetLayerCtrl(layerA)
  local layerCtrlB = layerCenter:GetLayerCtrl(layerB)
  if not layerCtrlA then
    return false
  end
  if not layerCtrlB then
    return true
  end
  local layerDepthA = layerCtrlA.depth
  local layerDepthB = layerCtrlB.depth
  if not layerDepthA then
    return false
  end
  if not layerDepthB then
    return true
  end
  return layerDepthA >= layerDepthB
end

function GuideConfigTypes.GetBlackBorderSize()
  local borderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
  local borderHeight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
  return UE4.FVector2D(borderWidth, borderHeight)
end

function GuideConfigTypes.GetTargetPanelName(panelName)
  if panelName then
    return panelName
  end
  return DefaultTargetPanel
end

function GuideConfigTypes.CheckIsTopPanel(targetPanelData)
  if not targetPanelData then
    return false
  end
  local panel = _G.NRCPanelManager:GetPanel(targetPanelData.moduleName, targetPanelData.panelName)
  if not panel then
    Log.Debug("GuideConfigTypes.CheckIsTopPanel panel is nil", targetPanelData.moduleName, targetPanelData.panelName)
    return false
  end
  local targetPanelLayer = targetPanelData.panelLayer
  local targetPanelModule = targetPanelData.moduleName
  local targetPanelName = targetPanelData.panelName
  local panelStack = _G.NRCPanelManager.PanelStack
  local len = #panelStack
  if len > 0 then
    for idx = len, 1, -1 do
      local moduleName = panelStack[idx].moduleName
      local panelName = panelStack[idx].panelName
      local panel = _G.NRCPanelManager:GetPanel(moduleName, panelName)
      if panel and panel:IsVisible() then
        local panelData = panel.panelData
        if GuideConfigTypes.IsTopPanel(panelData, targetPanelData) and GuideConfigTypes.ComparePanelLayer(panelData.panelLayer, targetPanelLayer) then
          if panelName ~= targetPanelName or moduleName ~= targetPanelModule then
            return
          else
            break
          end
        end
      end
    end
  end
  return true
end

local KeyNamesConvertPair = {Escape = "Esc"}

function GuideConfigTypes.GetRealMatchKeyName(keyName)
  if KeyNamesConvertPair[keyName] then
    return KeyNamesConvertPair[keyName]
  end
  return keyName
end

return GuideConfigTypes

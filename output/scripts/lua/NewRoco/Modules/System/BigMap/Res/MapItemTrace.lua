local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FVector2DUtils = require("NewRoco.Utils.FVector2DUtils")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local MapItemBase = require("NewRoco.Modules.System.BigMap.Res.MapItemBase")
local MapItemTrace = MapItemBase:Extend("MapItemTrace")
MapItemTrace.ItemData = {}

function MapItemTrace:Ctor(parentView, layerList, iconTemplateList)
  MapItemBase.Ctor(self, parentView, layerList, iconTemplateList)
  self.iconList = {}
  self.travelHideType = {
    BigMapModuleEnum.TraceType.NPC,
    BigMapModuleEnum.TraceType.Marker,
    BigMapModuleEnum.TraceType.Task,
    BigMapModuleEnum.TraceType.Visitor
  }
  self.travelShowType = {
    BigMapModuleEnum.TraceType.Travel
  }
  self.zOrderList = nil
end

function MapItemTrace:GetTraceZOrder(traceType)
  if self.zOrderList == nil then
    self.zOrderList = {}
  end
  local zOrder = self.zOrderList[traceType] or 0
  zOrder = zOrder + 1
  self.zOrderList[traceType] = zOrder
  return zOrder
end

function MapItemTrace:Create(itemData)
  self:Refresh(itemData)
end

function MapItemTrace:Refresh(itemData)
  local traceInfo = itemData.traceInfo
  local traceType = traceInfo.traceType
  local posX = 0
  local posY = 0
  if traceInfo.iconImagePos then
    posX = traceInfo.iconImagePos.x
    posY = traceInfo.iconImagePos.y
  else
    local npcInfo = traceInfo.npcInfo
    if npcInfo and npcInfo.npc_pos then
      posX = npcInfo.npc_pos.x
      posY = npcInfo.npc_pos.y
      local sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
      posX, posY = BigMapUtils.ScenePosToImagePosF(sceneResId, posX, posY)
    end
  end
  local itemWidget
  if self.iconList[traceType] == nil then
    self.iconList[traceType] = {}
  end
  if traceType == BigMapModuleEnum.TraceType.Self then
    if #self.iconList[traceType] > 0 then
      itemWidget = self.iconList[traceType][1]
    else
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      table.insert(self.iconList[traceType], itemWidget)
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        heroDir = traceInfo.dir,
        sceneResId = traceInfo.sceneResId
      })
    end
  elseif traceType == BigMapModuleEnum.TraceType.NPC then
    local entryId = traceInfo.npcInfo.entry_id
    if self.iconList[traceType][entryId] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][entryId] = itemWidget
    else
      itemWidget = self.iconList[traceType][entryId]
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        npcId = entryId,
        npcCfg = traceInfo.npcInfo
      })
    end
  elseif traceType == BigMapModuleEnum.TraceType.Marker then
    local markId = traceInfo.markInfo.mark_id
    if self.iconList[traceType][markId] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][markId] = itemWidget
    else
      itemWidget = self.iconList[traceType][markId]
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        MarkInfo = traceInfo.markInfo
      })
    end
  elseif traceType == BigMapModuleEnum.TraceType.Task then
    local taskInfo = traceInfo.taskInfo
    local taskId = taskInfo.taskId
    local goIndex = taskInfo.go_index or 1
    if self.iconList[traceType][taskId] == nil then
      self.iconList[traceType][taskId] = {}
    end
    if self.iconList[traceType][taskId][goIndex] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][taskId][goIndex] = itemWidget
    else
      itemWidget = self.iconList[traceType][taskId][goIndex]
    end
    if itemWidget then
      local showTaskConf = _G.DataConfigManager:GetTaskConf(taskId)
      if showTaskConf then
        local AcceptTaskList = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetAcceptTaskList)
        if AcceptTaskList[taskId] then
          itemWidget.taskIcon:ShowDiffByTaskClass(showTaskConf, BigMapModuleEnum.TaskShowType.UNDO)
        else
          itemWidget.taskIcon:ShowDiffByTaskClass(showTaskConf, nil)
        end
      end
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        taskId = taskId,
        sceneResId = traceInfo.sceneResId
      })
    end
  elseif traceType == BigMapModuleEnum.TraceType.Visitor then
    local visitorIndex = traceInfo.visitorInfo.visitorIndex
    if self.iconList[traceType][visitorIndex] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][visitorIndex] = itemWidget
    else
      itemWidget = self.iconList[traceType][visitorIndex]
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        data = traceInfo.visitorInfo.visitorInfo
      }, traceInfo.visitorInfo.visitorIndex)
    end
  elseif traceType == BigMapModuleEnum.TraceType.AutoTrace then
    local logicId = traceInfo.npcInfo.logic_id
    if self.iconList[traceType][logicId] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][logicId] = itemWidget
    else
      itemWidget = self.iconList[traceType][logicId]
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        npcId = logicId,
        npcCfg = traceInfo.npcInfo
      })
    end
  elseif traceType == BigMapModuleEnum.TraceType.TempTrace or traceType == BigMapModuleEnum.TraceType.ForceTrace then
    local logicId = traceInfo.npcInfo.logic_id
    if self.iconList[traceType][logicId] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][logicId] = itemWidget
    else
      itemWidget = self.iconList[traceType][logicId]
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        npcId = logicId,
        npcCfg = traceInfo.npcInfo
      })
    end
  elseif traceType == BigMapModuleEnum.TraceType.Travel then
    local campId = traceInfo.travelInfo.camp_content_id
    if self.iconList[traceType][campId] == nil then
      itemWidget = MapItemBase.CreateTraceWidget(self, traceInfo, self:GetTraceZOrder(traceType))
      self.iconList[traceType][campId] = itemWidget
    else
      itemWidget = self.iconList[traceType][campId]
    end
    if itemWidget then
      itemWidget:SetData({
        imagePosX = posX,
        imagePosY = posY,
        travelInfo = traceInfo.travelInfo
      })
    end
  end
end

function MapItemTrace:Get(traceType)
  return self.iconList[traceType]
end

function MapItemTrace:Destroy(traceType)
  if self.iconList[traceType] then
    for k, v in pairs(self.iconList[traceType]) do
      if traceType ~= BigMapModuleEnum.TraceType.Task then
        v:RemoveFromParent()
        v:Destruct()
      else
        for goIndex, taskIcon in pairs(v) do
          taskIcon:RemoveFromParent()
          taskIcon:Destruct()
          table.removeKey(self.iconList[traceType][k], goIndex)
        end
      end
      table.removeKey(self.iconList[traceType], k)
    end
    table.removeKey(self.iconList, traceType)
    if self.zOrderList then
      table.removeKey(self.zOrderList, traceType)
    end
  end
end

function MapItemTrace:StartTrace(traceInfo)
  if traceInfo.traceType == BigMapModuleEnum.TraceType.NPC then
    self:Destroy(BigMapModuleEnum.TraceType.Marker)
  elseif traceInfo.traceType == BigMapModuleEnum.TraceType.Marker then
    self:Destroy(BigMapModuleEnum.TraceType.NPC)
  end
  self:Refresh(traceInfo)
end

function MapItemTrace:CancelTrace(traceType)
  if self.iconList[traceType] then
    self:Destroy(traceType)
  end
end

function MapItemTrace:CancelTraceByID(traceType, contentID)
  if self.iconList[traceType] and self.iconList[traceType][contentID] then
    self.iconList[traceType][contentID]:RemoveFromParent()
    self.iconList[traceType][contentID]:Destruct()
    table.removeKey(self.iconList[traceType], contentID)
  end
end

function MapItemTrace:UpdateTracePosAndVisible(mapCenterX, mapCenterY, mapImageScale)
  if nil == mapCenterX or nil == mapCenterX then
    return
  end
  local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.layerList[4]:GetCachedGeometry())
  local viewSizeHalfX = wndSize.X / mapImageScale / 2
  local viewSizeHalfY = wndSize.Y / mapImageScale / 2
  local posLeftTopX = mapCenterX - viewSizeHalfX
  local posLeftTopY = mapCenterY - viewSizeHalfY
  local posRightBottomX = mapCenterX + viewSizeHalfX
  local posRightBottomY = mapCenterY + viewSizeHalfY
  local tempVector2D = UE4.FVector2D(0, 0)
  local coordinateAxis = UE4.FVector2D(1, 0)
  
  local function CheckPointInViewport(_posX, _posY)
    if _posX > posLeftTopX and _posX < posRightBottomX and _posY > posLeftTopY and _posY < posRightBottomY then
      return true
    else
      return false
    end
  end
  
  local function UpdateTraceIcon(_traceIcon)
    if not _traceIcon or not _traceIcon:IsUsable() then
      return
    end
    local posX, posY = _traceIcon:GetImagePosition()
    local sceneResId = 0
    if _traceIcon.GetSceneResId then
      sceneResId = _traceIcon:GetSceneResId()
    elseif _traceIcon.IsTaskTrace and _traceIcon:IsTaskTrace() then
      sceneResId = _traceIcon.uiData and _traceIcon.uiData.sceneResId or SceneUtils.GetSceneResId()
    else
      sceneResId = SceneUtils.GetSceneResId()
    end
    if self.bTravel and _traceIcon.uiData and _traceIcon.uiData.travelInfo then
      sceneResId = self.data.curShowSceneResId
    end
    if CheckPointInViewport(posX, posY) or sceneResId ~= self.data.curShowSceneResId then
      _traceIcon:SetVisible(false)
    else
      tempVector2D.X = posX - mapCenterX
      tempVector2D.Y = posY - mapCenterY
      local angle = FVector2DUtils.AngleBetween(tempVector2D, coordinateAxis)
      _traceIcon:SetVisible(true)
      self:UpdateTraceIconPos(_traceIcon, wndSize.X, wndSize.Y, angle)
    end
  end
  
  if self.iconList then
    for traceEnum, v in pairs(self.iconList) do
      if traceEnum < BigMapModuleEnum.TraceType.Travel then
        if not self.bTravel or traceEnum == BigMapModuleEnum.TraceType.Self then
          if traceEnum == BigMapModuleEnum.TraceType.Task then
            if v then
              for taskId, traceIcons in pairs(v) do
                for goIndex, traceIcon in pairs(traceIcons) do
                  UpdateTraceIcon(traceIcon)
                end
              end
            end
          elseif v then
            for _, traceIcon in pairs(v) do
              UpdateTraceIcon(traceIcon)
            end
          end
        end
      elseif v then
        for _, traceIcon in pairs(v) do
          UpdateTraceIcon(traceIcon)
        end
      end
    end
  end
end

function MapItemTrace:UpdateTraceIconPos(_traceIcon, _wndSizeX, _wndSizeY, _angle)
  local posX, posY = self:GetTraceIconPosition(_wndSizeX, _wndSizeY, _angle)
  _traceIcon.Slot:SetPosition(UE4.FVector2D(posX, posY))
  _traceIcon:SetArrowDir(_angle)
end

function MapItemTrace:GetTraceIconPosition(_wndSizeX, _wndSizeY, _angle)
  local a = math.deg(math.atan(_wndSizeY, _wndSizeX))
  local posX = 0
  local posY = 0
  if _angle < a and _angle >= -a then
    posX = _wndSizeX - 40
    posY = _wndSizeY / 2 - (_wndSizeX / 2 - 40) * math.tan(math.rad(_angle))
  elseif _angle >= a and _angle < 180 - a then
    posX = _wndSizeX / 2 - (_wndSizeY / 2 - 40) * math.tan(math.rad(_angle + 90))
    posY = 40
  elseif _angle >= 180 - a and _angle < 180 + a then
    posX = 40
    posY = _wndSizeY / 2 - (_wndSizeX / 2 - 40) * math.tan(math.rad(180 - _angle))
  elseif _angle < -180 + a and _angle >= -180 then
    posX = 40
    posY = _wndSizeY / 2 + (_wndSizeX / 2 - 40) * math.tan(math.rad(_angle + 180))
  elseif _angle < -a and _angle >= -180 + a then
    posX = _wndSizeX / 2 + (_wndSizeY / 2 - 40) * math.tan(math.rad(_angle + 90))
    posY = _wndSizeY - 40
  end
  if posX > _wndSizeX - 210 then
    posX = _wndSizeX - 210
  elseif posX < 210 then
    posX = 250
  end
  if posY > _wndSizeY - 170 then
    posY = _wndSizeY - 170
  elseif posY < 170 then
    posY = 170
  end
  return posX, posY
end

function MapItemTrace:GetTraceTaskSceneResId()
  return 10003
end

function MapItemTrace:OnTravelStateChanged(bTravel)
  MapItemBase.OnTravelStateChanged(self, bTravel)
  for k, v in ipairs(self.travelHideType) do
    self:SetVisibilityByType(v, not bTravel)
  end
  for k, v in ipairs(self.travelShowType) do
    self:SetVisibilityByType(v, bTravel)
  end
end

function MapItemTrace:SetVisibilityByType(traceType, bVisible)
  if self.iconList[traceType] then
    for k, v in pairs(self.iconList[traceType]) do
      if v and UE.UObject.IsValid(v) then
        if bVisible then
          v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          v:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      elseif v and type(v) == "table" then
        for _, icon in pairs(v or {}) do
          if icon and UE.UObject.IsValid(icon) then
            if bVisible then
              icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            else
              icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
            end
          end
        end
      end
    end
  end
end

return MapItemTrace

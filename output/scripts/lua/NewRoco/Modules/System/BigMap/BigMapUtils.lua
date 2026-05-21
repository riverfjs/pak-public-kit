local BigMapUtils = {}
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
BigMapUtils.TotalPieceCount = 16

function BigMapUtils.SetImageNodeVisible(TUIWidget, bVisible)
  if bVisible then
    TUIWidget:SetRenderOpacity(1)
  else
    TUIWidget:SetRenderOpacity(0)
  end
end

function BigMapUtils.SetupDottedEdgeImage(TUIWidget, NrcImageNode, Path)
  if not UE.UObject.IsValid(NrcImageNode) then
    return
  end
  if NrcImageNode.SetDottedEdgeEnabled then
    return NrcImageNode:SetPath(Path, TUIWidget)
  end
  if NrcImageNode.SetPath then
    BigMapUtils.SetImageNodeVisible(TUIWidget, false)
    NrcImageNode:SetPathWithCallBack(Path, function()
      BigMapUtils.SetImageNodeVisible(TUIWidget, true)
    end)
  elseif NrcImageNode.SetIconPath then
    NrcImageNode:SetIconPath(Path)
  end
  local bEnableMapVirtualIconShow = ENABLE_DEBUG_MAP_VIRTUAL_ICON or 1 == DataConfigManager:GetMapGlobalConfig("map_show_inter").num
  if not bEnableMapVirtualIconShow then
    return
  end
end

function BigMapUtils.SetDottedEdgeEnabled(TUIWidget, NrcImageNode, bEnableDottedEdge)
  if not UE.UObject.IsValid(NrcImageNode) then
    return
  end
  if NrcImageNode.SetDottedEdgeEnabled then
    return NrcImageNode:SetDottedEdgeEnabled(bEnableDottedEdge, TUIWidget)
  end
  local bEnableMapVirtualIconShow = ENABLE_DEBUG_MAP_VIRTUAL_ICON or 1 == DataConfigManager:GetMapGlobalConfig("map_show_inter").num
  if not bEnableMapVirtualIconShow then
    return
  end
  if bEnableDottedEdge then
    local GrayColor = UE4.UNRCStatics.HexToSlateColor("#777777F0")
    NrcImageNode:SetBrushTintColor(GrayColor)
  else
    local NormalColor = UE4.UNRCStatics.HexToSlateColor("#FFFFFFFF")
    NrcImageNode:SetBrushTintColor(NormalColor)
  end
end

function BigMapUtils.ApplyDottedTextureMaterial(TUIWidget, NrcImageNode, Texture2D)
  local function OnSuccess(caller, request, asset)
    if UE.UObject.IsValid(NrcImageNode) then
      NrcImageNode._DottedAsyncReq = nil
      
      NrcImageNode:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(Texture2D))
      NrcImageNode:SetBrushFromMaterial(asset)
      local DynamicMaterial = NrcImageNode:GetDynamicMaterial()
      if TUIWidget._bEnableDottedEdge then
        DynamicMaterial:SetScalarParameterValue("Width", 0.1)
      else
        DynamicMaterial:SetScalarParameterValue("Width", 0)
      end
      DynamicMaterial:SetTextureParameterValue("TargetTexture", Texture2D)
      NrcImageNode:SetRenderOpacity(1)
    end
  end
  
  local function OnFailed(caller, request, err)
    Log.Error("ApplyDottedTextureMaterial failed, asset=", Texture2D:GetFullName())
    if UE.UObject.IsValid(NrcImageNode) then
      NrcImageNode._DottedAsyncReq = nil
    end
  end
  
  local Path = "/Game/ArtRes/UI/TUI/Materials/MI_UI_DottedEdge.MI_UI_DottedEdge"
  TUIWidget._DottedAsyncReq = NRCResourceManager:LoadResAsync(self, Path, 255, -1, OnSuccess, OnFailed, nil, nil)
end

function BigMapUtils.ApplyDottedSpriteMaterial(TUIWidget, NrcImageNode, Sprite)
  local function OnSuccess(caller, request, asset)
    if UE.UObject.IsValid(NrcImageNode) then
      NrcImageNode._DottedAsyncReq = nil
      
      local BakedSourceTexture = Sprite.BakedSourceTexture
      local UV = Sprite.BakedSourceUV
      local Dm = Sprite.BakedSourceDimension
      local Brush = UE.UWidgetBlueprintLibrary.MakeBrushFromMaterial(asset)
      NrcImageNode:SetBrush(Brush)
      NrcImageNode:SetBrushSize(Dm)
      local DynamicMaterial = NrcImageNode:GetDynamicMaterial()
      DynamicMaterial:SetTextureParameterValue("SpriteTexture", BakedSourceTexture)
      DynamicMaterial:SetScalarParameterValue("AtlasWidth", BakedSourceTexture:Blueprint_GetSizeX())
      DynamicMaterial:SetScalarParameterValue("AtlasHeight", BakedSourceTexture:Blueprint_GetSizeY())
      DynamicMaterial:SetScalarParameterValue("SourceU", UV.X)
      DynamicMaterial:SetScalarParameterValue("SourceV", UV.Y)
      DynamicMaterial:SetScalarParameterValue("SourceWidth", Dm.X)
      DynamicMaterial:SetScalarParameterValue("SourceHeight", Dm.Y)
      if TUIWidget._bEnableDottedEdge then
        DynamicMaterial:SetScalarParameterValue("Edge", 1)
        DynamicMaterial:SetScalarParameterValue("StepValue", 0.7)
      else
        DynamicMaterial:SetScalarParameterValue("Edge", 0)
        DynamicMaterial:SetScalarParameterValue("StepValue", 0.2)
      end
      NrcImageNode:SetRenderOpacity(1)
    end
  end
  
  local function OnFailed(caller, request, err)
    Log.Error("ApplyDottedTextureMaterial failed, asset=", Sprite:GetFullName())
    if UE.UObject.IsValid(NrcImageNode) then
      NrcImageNode._DottedAsyncReq = nil
    end
  end
  
  local Path = "/Game/ArtRes/UI/TUI/Materials/MI_UI_DottedEdge_Atlas.MI_UI_DottedEdge_Atlas"
  TUIWidget._DottedAsyncReq = NRCResourceManager:LoadResAsync(self, Path, 255, -1, OnSuccess, OnFailed, nil, nil)
end

function BigMapUtils.GetConstData(sceneResId)
  local sceneOffsetX = 306000.0
  local sceneOffsetY = 408000.0
  local sceneWidth = 408000.0
  local sceneHeight = 408000.0
  local bigMapModule = NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule.data and bigMapModule.data.mapConstData then
    local mapConstData = bigMapModule.data.mapConstData[sceneResId]
    if mapConstData then
      sceneOffsetX = mapConstData.sceneOffsetX
      sceneOffsetY = mapConstData.sceneOffsetY
      sceneWidth = mapConstData.sceneWidth
      sceneHeight = mapConstData.sceneHeight
    end
  end
  return sceneOffsetX, sceneOffsetY, sceneWidth, sceneHeight
end

function BigMapUtils.ScenePosToImagePos(sceneResId, scenePosX, scenePosY)
  local x, y = BigMapUtils.ScenePosToImagePosF(sceneResId, scenePosX, scenePosY)
  return math.floor(x + 0.5), math.floor(y + 0.5)
end

function BigMapUtils.ScenePosToImagePosF(sceneResId, scenePosX, scenePosY)
  local sceneOffsetX, sceneOffsetY, sceneWidth, sceneHeight = BigMapUtils.GetConstData(sceneResId)
  local imageWidth = 6144
  local imageToSceneScale = imageWidth / sceneWidth
  local x = (scenePosX - sceneOffsetX) * imageToSceneScale
  local y = (scenePosY - sceneOffsetY) * imageToSceneScale
  return x, y
end

function BigMapUtils.GetLayerMapImagePath(layerId)
  local layerMapConf = _G.DataConfigManager:GetLayeredWorldMapConf(layerId)
  local filePath
  if layerMapConf then
    local fileName = layerMapConf.map_resource
    filePath = string.format("/Game/NewRoco/Modules/System/BigMap/Raw/Texture/LayerMap/%s.%s", fileName, fileName)
  end
  return filePath
end

function BigMapUtils.GetMapPieceIdByPos(posX, posY, sceneResId)
  local mapPieceId = 0
  local sceneOffsetX, sceneOffsetY, sceneWidth, sceneHeight = BigMapUtils.GetConstData(sceneResId)
  local sideNum = math.sqrt(BigMapUtils.TotalPieceCount)
  local colNum = math.ceil((posX - sceneOffsetX) / (sceneWidth / sideNum))
  local rowNum = math.ceil((posY - sceneOffsetY) / (sceneHeight / sideNum))
  mapPieceId = (rowNum - 1) * sideNum + colNum
  return mapPieceId
end

function BigMapUtils.GetSceneResIdByPos(posX, posY, sceneResId)
  if sceneResId and sceneResId > 0 then
    return sceneResId
  end
  if nil == posX or nil == posY then
    return 10003
  end
  if posX >= -886161.0 and posX <= -706161.0 and posY >= -891000.0 and posY <= -711000.0 then
    return 10018
  end
  return 10003
end

function BigMapUtils.GetSceneResIdByRefreshId(refreshId)
  local refreshContentConf = DataConfigManager:GetNpcRefreshContentConf(refreshId)
  if not refreshContentConf then
    return nil
  end
  if refreshContentConf.refresh_type == Enum.RefreshType.RFT_AREA then
    local areaConf = DataConfigManager:GetAreaConf(refreshContentConf.refresh_param)
    if areaConf then
      return areaConf.scene_res_id
    end
  end
  if refreshContentConf.refresh_type == Enum.RefreshType.RFT_BYTAG or refreshContentConf.refresh_type == Enum.RefreshType.RFT_BYTAGID then
    local sceneObjConf = DataConfigManager:GetSceneObjectConf(refreshContentConf.refresh_param, true)
    if sceneObjConf then
      local sceneConf = DataConfigManager:GetSceneConf(sceneObjConf.scene_cfg_id)
      if sceneConf then
        return sceneConf.scene_res_id
      end
    end
  end
  return nil
end

function BigMapUtils.GetLoadPiecesByImagePosition(piecePixel, showWndSize, centerPos, imageScale)
  local piecesIdList = {}
  local sideNum = math.sqrt(BigMapUtils.TotalPieceCount)
  local leftX, leftY, rightX, rightY = BigMapUtils.GetShowMapRange(showWndSize, centerPos, imageScale)
  local numX = math.ceil(leftX / (piecePixel * 1.5))
  local numY = math.ceil(leftY / (piecePixel * 1.5))
  local numX1 = math.ceil(rightX / (piecePixel * 1.5))
  local numY1 = math.ceil(rightY / (piecePixel * 1.5))
  for i = numY, numY1 do
    for j = numX, numX1 do
      local tempNum = (i - 1) * sideNum + j
      table.insert(piecesIdList, tempNum)
    end
  end
  return piecesIdList
end

function BigMapUtils.GetShowMapRange(wndSize, centerPos, imageScale)
  wndSize = wndSize or UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  imageScale = imageScale or 1
  local viewSizeHalfX = wndSize.X / imageScale / 2
  local viewSizeHalfY = wndSize.Y / imageScale / 2
  local posLeftTopX = centerPos.X - viewSizeHalfX
  local posLeftTopY = centerPos.Y - viewSizeHalfY
  local posRightBottomX = centerPos.X + viewSizeHalfX
  local posRightBottomY = centerPos.Y + viewSizeHalfY
  return posLeftTopX, posLeftTopY, posRightBottomX, posRightBottomY
end

function BigMapUtils.GetMapPicPath(sceneResId, pieceNo)
  local assetPath
  local bigMapModule = NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule.data then
    local blockConf = bigMapModule.data.sceneResIdToBlockConf[sceneResId]
    if not blockConf then
      return assetPath
    end
  end
  local assetDir = string.format("%s%d", "/Game/NewRoco/Modules/System/BigMap/Raw/Texture/Maps/", sceneResId or 10003)
  local assetDir_PC = string.format("%s%d", "/Game/NewRoco/Modules/System/BigMap/Raw/Texture/Maps_PC/", sceneResId or 10003)
  if 30001 == sceneResId then
    local roomLevel = HomeIndoorSandbox.Server:GetHomeRoomLevel()
    if roomLevel > 0 then
      local subFolder = string.format("/RoomLevel%d", roomLevel)
      assetDir = string.format("%s%s", assetDir, subFolder)
      assetDir_PC = string.format("%s%s", assetDir_PC, subFolder)
    end
    Log.Debug("GetMapPicPath RoomLevel", roomLevel)
  end
  if RocoEnv.PLATFORM_WINDOWS then
    local assetPath_PC = string.format("%s/%02d.%02d", assetDir_PC, pieceNo, pieceNo)
    assetPath = assetPath_PC
  end
  assetPath = assetPath or string.format("%s/%02d.%02d", assetDir, pieceNo, pieceNo)
  return assetPath
end

function BigMapUtils.CheckLayerIdUnlocked(layerId)
  local isUnlocked = false
  local layerMapConf = DataConfigManager:GetLayeredWorldMapConf(layerId)
  local unlockType = layerMapConf.map_layer_unlock_type
  if unlockType and unlockType > 0 then
    if unlockType == Enum.MapLayerUnlockType.MLUT_HOME_LV then
      local briefInfo = HomeIndoorSandbox.Server:GetDisplayHomeBriefInfo()
      if briefInfo and layerMapConf.para and #layerMapConf.para > 0 then
        local roomLevel = briefInfo.room_level
        if roomLevel >= layerMapConf.para[1] then
          isUnlocked = true
        end
      end
    end
  else
    isUnlocked = true
  end
  return isUnlocked
end

function BigMapUtils.CheckShowMapMask(showSceneResId)
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    local moduleData = bigMapModule.data
    local blockConf = moduleData.sceneResIdToBlockConf[showSceneResId]
    if blockConf then
      if blockConf.not_foggy and blockConf.not_foggy > 0 or 30002 == showSceneResId then
        return false
      else
        return true
      end
    end
  end
  return false
end

function BigMapUtils.GetVisitorIconSceneResIdAndPos(visitorInfo)
  local sceneResId = visitorInfo.scene_res_id
  local bUnlock = NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, sceneResId)
  local posX = 0
  local posY = 0
  local posZ = 0
  if bUnlock or nil == sceneResId then
    if visitorInfo.pos then
      posX = visitorInfo.pos.pos.x
      posY = visitorInfo.pos.pos.y
      posZ = visitorInfo.pos.pos.z
    end
  elseif visitorInfo.main_scene_pt then
    posX = visitorInfo.main_scene_pt.pos.x
    posY = visitorInfo.main_scene_pt.pos.y
    posZ = visitorInfo.main_scene_pt.pos.z
  end
  local iconSceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
  sceneResId = sceneResId or BigMapUtils.GetDefaultSceneResId()
  return sceneResId, iconSceneResId, posX, posY, posZ
end

function BigMapUtils.IsBigWorldMap(sceneResId)
  if 10003 == sceneResId or 10018 == sceneResId then
    return true
  end
  return false
end

function BigMapUtils.IsHomeMap(sceneResId)
  if 30001 == sceneResId or 30002 == sceneResId then
    return true
  end
  return false
end

function BigMapUtils.GetDefaultSceneResId()
  return 10003
end

function BigMapUtils.IsHomeScene(sceneId)
  if 301 == sceneId then
    return true
  else
    return false
  end
end

function BigMapUtils.CheckInFogAreaByPos(npc_pos, sceneResId)
  sceneResId = sceneResId or 10003
  local bigMapModule = NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule and bigMapModule:IsShowMaskMap(sceneResId) then
    local imageWidth = 6144
    local imageHeight = 6144
    local posX, posY = BigMapUtils.ScenePosToImagePos(sceneResId, npc_pos.x, npc_pos.y)
    local posU = posX / imageWidth * 1024
    local posV = posY / imageHeight * 1024
    local bigMapModuleData = bigMapModule.data
    if bigMapModuleData then
      local unlockDeadWoodList = bigMapModuleData.UnlockDeadwoodList
      if unlockDeadWoodList then
        local curUnlockDeadWoodList = bigMapModuleData.UnlockDeadwoodList[sceneResId]
        local areaIdArray = UE4.UNRCTUIStatics.GetPointAreaId(posU, posV, curUnlockDeadWoodList)
        local areaIds = areaIdArray:ToTable()
        Log.Dump(areaIds, 5, "BigMapUtils.CheckInFogAreaByPos")
        if areaIds and #areaIds > 0 then
          return true
        end
      end
      return false
    end
  end
  return true
end

function BigMapUtils.GetLayerIdByAreaIds(areaIds)
  local layerId = 0
  local bigMapModule = NRCModuleManager:GetModule("BigMapModule")
  local bigMapModuleData = bigMapModule.data
  if bigMapModuleData then
    for k, v in ipairs(areaIds) do
      local areaFunId = bigMapModuleData.AreaIdToAreaFuncId[v]
      if areaFunId then
        local mapLayerConf = bigMapModuleData.AreaFuncIdToLayerInfo[areaFunId]
        if mapLayerConf then
          layerId = mapLayerConf.id
        end
      end
    end
  end
  return layerId
end

function BigMapUtils.GetLayerIdByPos(posX, posY, sceneResId, bImagePos)
  sceneResId = sceneResId or BigMapUtils.GetSceneResIdByPos(posX, posY, sceneResId)
  local checkDeadWoodList = NRCModuleManager:DoCmd(BigMapModuleCmd.GetCheckDeadWoodList)
  if checkDeadWoodList then
    local curShowDeadWoodList = checkDeadWoodList[sceneResId]
    if curShowDeadWoodList and #curShowDeadWoodList > 0 then
      local imagePosX, imagePosY = 0, 0
      if bImagePos then
        imagePosX = posX
        imagePosY = posY
      else
        imagePosX, imagePosY = BigMapUtils.ScenePosToImagePosF(sceneResId, posX, posY)
      end
      local posU = imagePosX / 6144 * 1024
      local posV = imagePosY / 6144 * 1024
      local areaIdArray = UE4.UNRCTUIStatics.GetPointAreaId(posU, posV, curShowDeadWoodList)
      local areaIds = areaIdArray:ToTable()
      if areaIds and #areaIds > 0 then
        return BigMapUtils.GetLayerIdByAreaIds(areaIds)
      end
    end
  end
  return 0
end

function BigMapUtils.GetSceneIdBySceneResId(sceneResId)
  if sceneResId then
    local sceneResConf = DataConfigManager:GetSceneResConf(sceneResId)
    if sceneResConf then
      return sceneResConf.scene_id
    end
  end
  return 103
end

function BigMapUtils.GetNpcIconLayer(_npcInfo, _bMiniMap)
  if nil == _npcInfo then
    Log.Error("BigMapUtils.GetNpcIconLayer, npcInfo is nil")
    return nil
  end
  local layerIndex = 1
  local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(_npcInfo.world_map_cfg_id)
  if nil == worldMapCfg then
    return nil
  end
  if _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.LOCKED then
    if 1 == worldMapCfg.lock_element_show_top then
      layerIndex = 2
    end
  else
    if 1 == worldMapCfg.unlock_element_show_top then
      layerIndex = 2
    end
    if _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
      layerIndex = 2
    end
  end
  if _npcInfo.npcCfg and _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_CAMP then
    layerIndex = 2
  end
  if not _bMiniMap and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CHALLENGE then
    layerIndex = 7
  end
  return layerIndex
end

function BigMapUtils.CheckShowRongDuanIcon(worldMapConf, mutationType)
  if nil == worldMapConf then
    return false
  end
  if nil == mutationType then
    return false
  end
  if worldMapConf.default_track_type == Enum.DefaultTrackType.DTT_SHINE and not PetMutationUtils.GetMutationValue(mutationType, Enum.MutationDiffType.MDT_SHINING) then
    return true
  end
  return false
end

function BigMapUtils.IsFullPath(path)
  local param = string.split(path, "/")
  if #param > 1 then
    return true
  end
  return false
end

return BigMapUtils

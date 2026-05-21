local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local UMG_IconTempBasic_C = _G.NRCPanelBase:Extend("UMG_IconTempBasic_C")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")

function UMG_IconTempBasic_C:Init()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    self.data = bigMapModule:GetData("BigMapModuleData")
  end
  self.mapLayerId = 0
end

function UMG_IconTempBasic_C:SetFlagPath(assetPath)
  self.TheShowingIconNode = self.iconFlag
  BigMapUtils.SetupDottedEdgeImage(self, self.iconFlag, assetPath)
end

function UMG_IconTempBasic_C:SetPetPath(assetPath)
  self.TheShowingIconNode = self.NRCpetIcon
  BigMapUtils.SetupDottedEdgeImage(self, self.NRCpetIcon, assetPath)
end

function UMG_IconTempBasic_C:SetIconPath(assetPath)
  self.TheShowingIconNode = self.Icon
  BigMapUtils.SetupDottedEdgeImage(self, self.Icon, assetPath)
end

function UMG_IconTempBasic_C:SetDottedEdgeEnabled(bEnable)
  if self.TheShowingIconNode then
    BigMapUtils.SetDottedEdgeEnabled(self, self.TheShowingIconNode, bEnable)
  end
end

function UMG_IconTempBasic_C:SetMapLayerIconVisible(iconType)
  if not self.EntranceCave then
    return
  end
  self.EntranceCave:SetPath(UEPath.MapLayerIcon)
  if iconType == BigMapModuleEnum.CreatorPriority.NpcIcons then
    if self.uiData.world_map_cfg_id > 0 then
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(self.uiData.world_map_cfg_id)
      local mapConfLayerId = 0
      if worldMapConf and worldMapConf.layered_id and #worldMapConf.layered_id > 0 then
        mapConfLayerId = worldMapConf.layered_id[1]
      end
      if mapConfLayerId > 0 then
        self.mapLayerId = mapConfLayerId
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
        local svrLayerId = 0
        if self.uiData and self.uiData.layerId and self.uiData.layerId > 0 then
          svrLayerId = self.uiData.layerId
        end
        if svrLayerId > 0 then
          self.mapLayerId = svrLayerId
          self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          local npcRefreshId = self.uiData.npc_refresh_id
          if nil == npcRefreshId then
            return
          end
          if npcRefreshId and npcRefreshId > 0 then
            local npcRefreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(npcRefreshId)
            if npcRefreshConf then
              local areaId = npcRefreshConf.refresh_param
              if areaId > 0 then
                local areaFuncId = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetAreaFuncIdByAreaId, areaId)
                if self.data and self.data.AreaFuncIdToLayerInfo and areaFuncId > 0 and self.data.AreaFuncIdToLayerInfo[areaFuncId] then
                  self.mapLayerId = self.data.AreaFuncIdToLayerInfo[areaFuncId].id
                  self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
                  return
                else
                  self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
                end
              else
                self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
              end
            end
          end
        end
      end
    end
  elseif iconType == BigMapModuleEnum.CreatorPriority.TaskIcons then
    if self.uiData then
      local layerId = self.uiData.layerId
      if layerId and layerId > 0 then
        self.mapLayerId = layerId
        local layerConf = DataConfigManager:GetLayeredWorldMapConf(layerId)
        if 0 ~= layerConf.area_func_id then
          self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  elseif iconType == BigMapModuleEnum.CreatorPriority.MarkerIcons and self.uiData then
    local layerId = self.uiData.layer_id
    if layerId and layerId > 0 then
      self.mapLayerId = layerId
      local layerConf = DataConfigManager:GetLayeredWorldMapConf(layerId)
      if 0 ~= layerConf.area_func_id then
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_IconTempBasic_C:SetPetOwnerVisible()
  if not self.MutualVisits then
    return
  end
  self.MutualVisits:SetPath(UEPath.PetOwnerIcon)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    local playerId = localPlayer:GetServerId()
    if self.uiData.ownerId and self.uiData.ownerId ~= playerId then
      self.MutualVisits:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.EntranceCave then
        self.EntranceCave:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.MutualVisits:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_IconTempBasic_C:SetLayerMapIcon(bSelected)
  if self.EntranceCave then
    if bSelected then
      self.EntranceCave:SetPath(UEPath.selectPath)
    else
      self.EntranceCave:SetPath(UEPath.unSelectPath)
    end
  end
end

return UMG_IconTempBasic_C

local Super = require("NewRoco/Modules/System/BigMap/Res/UMG_IconTempBasic_C")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local UMG_IconNpcPet_C = Super:Extend("UMG_IconNpcPet_C")

function UMG_IconNpcPet_C:OnConstruct()
  self.isShowTraceEffect = false
  self.curMapShowLevel = 1
  self.CurrentTime = nil
  self.IsStarCountDown = false
  self.IsCatchPet = false
  self.IsTravelInfo = false
  self.TravelContentId = 0
  self.TravelInfo = nil
end

function UMG_IconNpcPet_C:OnDestruct()
  self.uiData = nil
end

function UMG_IconNpcPet_C:SetData(_data, worldMap)
  self.uiData = _data
  self.WorldMapConfig = worldMap
  local npcType = 0
  if self.uiData and self.uiData.npcCfg then
    if self.uiData.npcCfg then
      npcType = self.uiData.npcCfg.genre
    else
      local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(worldMap.npc_refresh_ids[1])
      local npcId = refreshConf.npc_id
      local npcCfg = _G.DataConfigManager:GetNpcConf(npcId)
      npcType = npcCfg.genre
    end
    self.needMapShowLevel = 2
  elseif self.uiData and self.uiData.next_npc_refresh_time then
    self.needMapShowLevel = 2
  end
  self.scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(self.WorldMapConfig.element_show_scale)
  self.maxScale = self.scaleConf.max_scale / 100
  self.minScale = self.scaleConf.min_scale / 100
  self:UpdateIcon()
  if _data.isNewUnLock then
    _data.isNewUnLock = false
    self:PlayAnimation(self.change_map)
  end
  Super.Init(self)
end

function UMG_IconNpcPet_C:SetShowTime(data)
end

function UMG_IconNpcPet_C:SetMapAreaData(_data, worldMap)
  self.uiData = _data
  self.WorldMapConfig = worldMap
  self.needMapShowLevel = 2
  self:UpdateIcon()
  if _data.isNewUnLock then
    _data.isNewUnLock = false
    self:PlayAnimation(self.change_map)
  end
end

function UMG_IconNpcPet_C:GetData()
  return self.uiData
end

function UMG_IconNpcPet_C:UpdateIcon()
  if self.uiData and self.WorldMapConfig then
    local model
    if self.uiData.npcCfg then
      model = _G.DataConfigManager:GetModelConf(self.uiData.npcCfg.model_conf)
    else
      local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(self.WorldMapConfig.npc_refresh_ids[1])
      local npcId = refreshConf.npc_id
      local npcCfg = _G.DataConfigManager:GetNpcConf(npcId)
      model = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
    end
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local npcCfg = self.uiData.npcCfg
    if self.uiData.status then
      if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        if self.WorldMapConfig.areaicon_explore then
          self:GetIconPath(self.WorldMapConfig.areaicon_explore)
        elseif self.WorldMapConfig.npcicon_unlock then
          if npcCfg and npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS then
            self.Bg:SetPath(UEPath.MapIconNpcPetBg1)
            self:GetPetIconPath(self.WorldMapConfig.npcicon_unlock)
          elseif npcCfg and npcCfg.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT then
            self.Bg:SetPath(UEPath.MapIconNpcPetBg2)
            self:GetPetIconPath(self.WorldMapConfig.npcicon_unlock)
            self.Crown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          else
            self:GetPetIconPath(self.WorldMapConfig.npcicon_unlock)
          end
        elseif npcCfg and npcCfg.genre and npcCfg.genre == _G.Enum.ClientNpcType.CNT_HOME_NPC and self.uiData.petInfo and self.uiData.petInfo.pet_gid then
          local petData = HomeUtils.GetHomePetAdditionalInfo(self.uiData.petInfo.pet_gid)
          if petData then
            self.NRCpetIcon_1:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
          elseif self.uiData.petInfo and self.uiData.petInfo.base_conf_id and self.uiData.petInfo.mutation_type and self.uiData.petInfo.glass_info then
            self.NRCpetIcon_1:SetIconPathAndMaterial(self.uiData.petInfo.base_conf_id, self.uiData.petInfo.mutation_type, self.uiData.petInfo.glass_info)
          end
        end
      elseif self.WorldMapConfig.areaicon_unexplore then
        self:GetIconPath(self.WorldMapConfig.areaicon_unexplore)
      elseif self.WorldMapConfig.npcicon_lock then
        self:GetIconPath(self.WorldMapConfig.npcicon_lock)
      elseif model then
        if npcCfg and npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS then
          self.Pet:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
          self:SetPetPath(model.icon)
        else
          self:SetPetPath(model.icon)
        end
      end
    else
      self.Pet:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self:SetPetPath(model.icon)
    end
    if npcCfg and npcCfg.genre and npcCfg.genre == _G.Enum.ClientNpcType.CNT_HOME_NPC then
      self:RefreshCornerIcon()
      self.NRCpetIcon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.NRCpetIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_IconNpcPet_C:RefreshCornerIcon()
  if self.uiData.petInfo and self.uiData.petInfo.pet_gid then
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.uiData.petInfo and self.uiData.petInfo.productionInfo then
    if HomeIndoorSandbox then
      local output = self.uiData.petInfo.productionInfo
      if not output then
        self:UpdateCrownIcon(UE4.ESlateVisibility.Collapsed, nil)
      end
      if HomeIndoorSandbox:InLocalMasterIndoor() then
        for _, v in ipairs(output) do
          if v.goods_num > 0 then
            if not self.WorldMapConfig then
              return
            end
            if self.WorldMapConfig.npcicon_corner_unlock then
              self:UpdateCrownIcon(UE4.ESlateVisibility.HitTestInvisible, self.WorldMapConfig.npcicon_corner_unlock)
            end
          end
        end
      elseif HomeIndoorSandbox:InOtherHomeIndoor() then
        for _, v in ipairs(output) do
          if v.goods_id == _G.Enum.VisualItem.VI_FURNITURE_COIN then
            local remainRatio = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_left_steal_max").num / 10000
            remainRatio = remainRatio or 0
            if v.goods_num <= v.goods_total_num * remainRatio then
              return
            end
            if not self.WorldMapConfig then
              return
            end
            if self.WorldMapConfig.npcicon_corner_unlock then
              self:UpdateCrownIcon(UE4.ESlateVisibility.HitTestInvisible, self.WorldMapConfig.npcicon_corner_unlock)
            end
            break
          end
        end
      end
    end
  else
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_IconNpcPet_C:UpdateCrownIcon(visibility, iconPath)
  if self.Crown and self.Crown:GetVisibility() ~= visibility then
    self.Crown:SetVisibility(visibility)
    if visibility ~= UE4.ESlateVisibility.Collapsed and visibility ~= UE4.ESlateVisibility.Hidden then
      if not iconPath then
        return
      end
      local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
      if self.WorldMapConfig.npcicon_corner_unlock and bigMapModule then
        self.Crown:SetPath(bigMapModule:GetMainUIStaticIconRes(self.WorldMapConfig.npcicon_corner_unlock))
      end
    end
  end
end

function UMG_IconNpcPet_C:UpdateMapShowLevel(_level, bForceRefresh)
  if (not self.needMapShowLevel or _level == self.curMapShowLevel) and not bForceRefresh then
    return
  end
  self.curMapShowLevel = _level
  if self.WorldMapConfig.element_show_scale then
    if 0 == self.WorldMapConfig.element_show_scale then
      self.WorldMapConfig.element_show_scale = 1
    end
    if self.scaleConf == nil or self.curMapShowLevel <= self.maxScale and self.curMapShowLevel >= self.minScale or self.isShowTraceEffect then
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_IconNpcPet_C:SetOpacity(_alpha)
  self.NRCpetIcon:SetOpacity(_alpha)
end

function UMG_IconNpcPet_C:PlayTraceEffect(_show)
  if self.isShowTraceEffect ~= _show then
    self.isShowTraceEffect = _show
    if _show then
      self.traceEffect:LoadPanel(nil)
    else
      self.traceEffect:UnLoadPanel(true)
    end
  end
end

function UMG_IconNpcPet_C:IsFullPath(path)
  local param = string.split(path, "/")
  if #param > 1 then
    return true
  end
  return false
end

function UMG_IconNpcPet_C:GetIconPath(Icon)
  self.TheShowingIconNode = self.NRCpetIcon
  if self:IsFullPath(Icon) then
    self:SetPetPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      self:SetPetPath(bigMapModule:GetBigMapIconRes(Icon))
    end
  end
end

function UMG_IconNpcPet_C:GetPetIconPath(Icon)
  if self:IsFullPath(Icon) then
    self:SetPetPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      self:SetPetPath(bigMapModule:GetBigMapIconRes(Icon))
    end
  end
end

function UMG_IconNpcPet_C:GetCathIconPath(Icon)
  self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CatchRewardCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
  self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self:IsFullPath(Icon) then
    self:SetIconPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      local iconPath = Icon
      self:SetIconPath(iconPath)
    end
  end
end

function UMG_IconNpcPet_C:SetCathPet()
  self.IsCatchPet = true
  self:GetCathIconPath(self.WorldMapConfig.npcicon_unlock)
end

function UMG_IconNpcPet_C:ShowTravel(npcInfo)
end

function UMG_IconNpcPet_C:GetTravelDownTime()
end

function UMG_IconNpcPet_C:PlayInTravel()
end

function UMG_IconNpcPet_C:PlayOutTravel()
end

function UMG_IconNpcPet_C:OnAnimationFinished(anim)
end

return UMG_IconNpcPet_C

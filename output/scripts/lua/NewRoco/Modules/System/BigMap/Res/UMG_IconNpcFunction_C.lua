local Super = require("NewRoco/Modules/System/BigMap/Res/UMG_IconTempBasic_C")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UMG_IconNpcFunction_C = Super:Extend("UMG_IconNpcFunction_C")

function UMG_IconNpcFunction_C:OnConstruct()
  self.isShowTraceEffect = false
  self.curMapShowLevel = 1
  self.CurrentTime = nil
  self.IsStarCountDown = false
  self.IsCatchPet = false
  self.IsTravelInfo = false
  self.TravelContentId = 0
  self.TravelInfo = nil
  self:PlayAnimation(self.TraceStop)
end

function UMG_IconNpcFunction_C:OnDestruct()
  self.uiData = nil
  _G.UpdateManager:UnRegister(self)
end

function UMG_IconNpcFunction_C:SetData(_data, worldMap)
  self.uiData = _data
  self.WorldMapConfig = worldMap
  if self.WorldMapConfig.element_show_scale == nil then
    self.WorldMapConfig.element_show_scale = 1
  end
  self.scaleConf = _G.DataConfigManager:GetWorldMapScaleConf(self.WorldMapConfig.element_show_scale)
  self.maxScale = self.scaleConf.max_scale / 100
  self.minScale = self.scaleConf.min_scale / 100
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
  self:UpdateIcon()
  if _data.isNewUnLock then
    _data.isNewUnLock = false
    self:PlayAnimation(self.NewMap_In_1)
  end
  local RefreshContentId = self.uiData.npc_refresh_id or worldMap.npc_refresh_ids[1]
  local Flower, FlowerTypeWrap = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetNpcFlowerInfo, RefreshContentId)
  if self.Predestined then
    self.Predestined:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  local TypeWrap = FlowerTypeWrap
  if Flower and TypeWrap.IsShinyFlower then
    self.huazhongEffect:LoadPanel(nil, TypeWrap)
  elseif Flower and TypeWrap.IsLimitedFlower then
    self.huazhongEffect:LoadPanel(nil, TypeWrap)
  elseif Flower and TypeWrap.Is7StarHardFlower then
    if self.Predestined then
      self.Predestined:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Mingding_Loop then
      self:PlayAnimation(self.Mingding_Loop)
    end
  end
  Super.Init(self)
end

function UMG_IconNpcFunction_C:SetShowTime(data)
  if data.npc_remain_time == nil then
    return
  end
  if data.npc_remain_time > 0 then
    self.CurrentTime = data.npc_remain_time - (os.time() - data.CreateTime)
    if self.CurrentTime > 0 then
      _G.UpdateManager:Register(self)
      self.Time:SetVisibility(UE4.ESlateVisibility.Visible)
      self.IsStarCountDown = true
    else
      _G.UpdateManager:UnRegister(self)
      self.Time:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.IsStarCountDown = false
    end
  else
    _G.UpdateManager:UnRegister(self)
    self.Time:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsStarCountDown = false
  end
end

function UMG_IconNpcFunction_C:OnTick(deltaTime)
  if self.IsStarCountDown then
    local Text = self:secondsToTime(self.CurrentTime)
    self.Time:SetText(Text)
    self.CurrentTime = self.CurrentTime - deltaTime
    if self.CurrentTime <= 0 then
      self.IsStarCountDown = false
      _G.UpdateManager:UnRegister(self)
    end
  end
end

function UMG_IconNpcFunction_C:secondsToTime(ts)
  local seconds = math.floor(math.fmod(ts, 60))
  local min = math.floor(ts / 60)
  local hour = math.floor(min / 60)
  local day = math.floor(hour / 24)
  local str
  if tonumber(seconds) >= 0 and tonumber(seconds) < 60 and tonumber(min - hour * 60) >= 0 and tonumber(min - hour * 60) < 60 and tonumber(hour - day * 24) >= 0 and tonumber(hour - day * 60) < 24 then
    str = string.format("%02d:%02d", min - hour * 60, seconds)
  else
    Log.Error(ts, seconds, hour, day, tonumber(seconds) >= 0 and tonumber(seconds) < 60, tonumber(min - hour * 60) >= 0 and tonumber(min - hour * 60) < 60, tonumber(hour - day * 24) >= 0 and tonumber(hour - day * 60) < 24, "\230\151\182\233\151\180\230\141\162\231\174\151\230\156\137\233\151\174\233\162\152\232\175\183\230\163\128\230\159\165")
  end
  return str
end

function UMG_IconNpcFunction_C:SetMapAreaData(_data, worldMap)
  self.uiData = _data
  self.WorldMapConfig = worldMap
  self.needMapShowLevel = 2
  self:UpdateIcon()
end

function UMG_IconNpcFunction_C:GetData()
  return self.uiData
end

function UMG_IconNpcFunction_C:UpdateIcon()
  if self.uiData and self.WorldMapConfig then
    local model
    if self.uiData.npcCfg then
      model = _G.DataConfigManager:GetModelConf(self.uiData.npcCfg.model_conf)
    elseif self.WorldMapConfig.npc_refresh_ids and #self.WorldMapConfig.npc_refresh_ids > 0 then
      local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(self.WorldMapConfig.npc_refresh_ids[1])
      if refreshConf then
        local npcId = refreshConf.npc_id
        if npcId then
          local npcCfg = _G.DataConfigManager:GetNpcConf(npcId)
          if npcCfg then
            model = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
          end
        end
      end
    end
    self.iconFlag:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    if not self.WorldMapConfig.dungeon_id or self.WorldMapConfig.dungeon_id > 0 then
    end
    if (self.WorldMapConfig.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING or self.WorldMapConfig.map_show_type == Enum.MapIconShowType.MAP_SHINING_SEASON_DAZZLING) and self.uiData.glass_info and self.uiData.mutation_type then
      local path = self:GetHiddenGlassIcon()
      if "" ~= path then
        self:GetIconPath(path)
      end
    elseif self.uiData.status then
      if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        if self.WorldMapConfig.dungeon_id and self.WorldMapConfig.dungeon_id > 0 then
          self:GetIconPath(self.WorldMapConfig.npcicon_unfinished)
        elseif self.WorldMapConfig.areaicon_explore then
          self:GetIconPath(self.WorldMapConfig.areaicon_explore)
        elseif self.WorldMapConfig.npcicon_unlock then
          if #self.WorldMapConfig.npcicon_levelup > 0 then
            for i = 1, #self.WorldMapConfig.npcicon_levelup do
              if self.WorldMapConfig.npcicon_levelup[i].level == self.uiData.npc_level then
                self:GetIconPath(self.WorldMapConfig.npcicon_levelup[i].icon)
              end
            end
          else
            self:GetIconPath(self.WorldMapConfig.npcicon_unlock)
          end
        end
      elseif self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
        if self.WorldMapConfig.dungeon_id and self.WorldMapConfig.dungeon_id > 0 then
          self:GetIconPath(self.WorldMapConfig.npcicon_unlock)
        end
      elseif self.WorldMapConfig.areaicon_unexplore then
        self:GetIconPath(self.WorldMapConfig.areaicon_unexplore)
      elseif self.WorldMapConfig.npcicon_lock then
        self:GetIconPath(self.WorldMapConfig.npcicon_lock)
      else
        local owlSanctuaryConf = _G.DataConfigManager:GetOwlSanctuaryConf(self.WorldMapConfig.npc_refresh_ids[1])
        if owlSanctuaryConf and owlSanctuaryConf.first_area_name and #self.WorldMapConfig.npcicon_levelup > 0 then
          for i = 1, #self.WorldMapConfig.npcicon_levelup do
            if self.WorldMapConfig.npcicon_levelup[i].level == self.uiData.npc_level then
              self:GetIconPath(self.WorldMapConfig.npcicon_levelup[i].icon)
            end
          end
        end
      end
    elseif model and model.icon then
      self:GetIconPath(model.icon)
    elseif self.WorldMapConfig.areaicon_explore then
      self:GetIconPath(self.WorldMapConfig.areaicon_explore)
    elseif self.WorldMapConfig.world_map_NPCicon_des then
      self:GetIconPath(self.WorldMapConfig.world_map_NPCicon_des)
    end
  end
  if self.uiData and self.uiData.npc_refresh_id and self.uiData.npc_refresh_id > 0 then
    local isCatchPet = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.IsShowCatchPet, self.uiData.npc_refresh_id)
    if isCatchPet and self.WorldMapConfig.world_map_NPCicon_des then
      self:SetCathPet()
    end
  end
end

function UMG_IconNpcFunction_C:GetHiddenGlassIcon()
  if self.uiData and self.uiData.glass_info and self.uiData.mutation_type then
    local isShining = 0 ~= self.uiData.mutation_type & _G.Enum.MutationDiffType.MDT_SHINING
    local HiddenGlassID = self.uiData.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if not isShining and HiddenGlassConf.stroke_icon then
          return HiddenGlassConf.stroke_icon
        elseif isShining and HiddenGlassConf.yise_stroke_icon then
          return HiddenGlassConf.yise_stroke_icon
        end
      end
    end
  end
  if self.WorldMapConfig and self.WorldMapConfig.npcicon_lock then
    return self.WorldMapConfig.npcicon_lock
  end
  return ""
end

function UMG_IconNpcFunction_C:UpdateMapShowLevel(_level, bForceRefresh)
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

function UMG_IconNpcFunction_C:SetOpacity(_alpha)
  self.iconFlag:SetOpacity(_alpha)
end

function UMG_IconNpcFunction_C:PlayTraceEffect(_show)
  if self.isShowTraceEffect ~= _show then
    self.isShowTraceEffect = _show
    if _show then
      self.traceEffect:LoadPanel(nil)
    else
      self.traceEffect:UnLoadPanel(true)
    end
  end
end

function UMG_IconNpcFunction_C:IsFullPath(path)
  local param = string.split(path, "/")
  if #param > 1 then
    return true
  end
  return false
end

function UMG_IconNpcFunction_C:GetIconPath(Icon)
  if self:IsFullPath(Icon) then
    self:SetFlagPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      self:SetFlagPath(bigMapModule:GetBigMapIconRes(Icon))
    end
  end
end

function UMG_IconNpcFunction_C:GetPetIconPath(Icon)
  if self:IsFullPath(Icon) then
    self:SetPetPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      self:SetPetPath(bigMapModule:GetBigMapIconRes(Icon))
    end
  end
end

function UMG_IconNpcFunction_C:SetCathPet()
  self.IsCatchPet = true
  self:GetCathIconPath()
end

function UMG_IconNpcFunction_C:GetCathIconPath()
  if self.WorldMapConfig == nil then
    return
  end
  local path = ""
  if BigMapUtils.CheckShowRongDuanIcon(self.WorldMapConfig, self.uiData.mutation_type) then
    path = self.WorldMapConfig.shine_rongduan_icon
  else
    path = self.WorldMapConfig.world_map_NPCicon_des
  end
  self:SetFlagPath(path)
end

function UMG_IconNpcFunction_C:ShowTravel(npcInfo)
  if npcInfo then
    local travelInfo = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetTravelInfo, npcInfo.npc_refresh_id)
    if travelInfo then
      self.TravelInfo = travelInfo
      self.IsTravelInfo = true
      self.TravelContentId = travelInfo.camp_content_id
    end
  else
    self.TravelContentId = 0
    self.IsTravelInfo = false
  end
end

function UMG_IconNpcFunction_C:GetTravelDownTime()
  if self.IsTravelInfo then
    if self.TravelInfo and self.TravelInfo.travel_complete then
      return 0
    end
    return 0
  end
  return 0
end

function UMG_IconNpcFunction_C:PlayInTravel()
end

function UMG_IconNpcFunction_C:PlayOutTravel()
end

function UMG_IconNpcFunction_C:RandomAngle(bRandom)
  local randomAngle = 0
  if bRandom then
    randomAngle = math.random(-60, 60)
  end
  self.iconFlag:SetRenderTransformAngle(randomAngle)
end

function UMG_IconNpcFunction_C:OnAnimationFinished(anim)
  if anim == self.NewMap_In_1 then
    self:PlayAnimation(self.NewMap_In1_2)
  elseif anim == self.Yisehuazhong_Loop then
    self:PlayAnimation(self.Yisehuazhong_Loop)
  elseif anim == self.Xishouhuazhong_Loop then
    self:PlayAnimation(self.Xishouhuazhong_Loop)
  elseif anim == self.Mingding_Loop then
    self:PlayAnimation(self.Mingding_Loop)
  end
end

return UMG_IconNpcFunction_C

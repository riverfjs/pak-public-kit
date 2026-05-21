local Super = require("NewRoco/Modules/System/BigMap/Res/UMG_IconTempBasic_C")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UMG_IconNpcRole_C = Super:Extend("UMG_IconNpcRole_C")

function UMG_IconNpcRole_C:OnConstruct()
  self.isShowTraceEffect = false
  self.IsPlayReverse = false
  self.curMapShowLevel = 1
  self.CurrentTime = nil
  self.IsStarCountDown = false
  self.IsCatchPet = false
  self.IsTravelInfo = false
  self.TravelContentId = 0
  self.TravelInfo = nil
end

function UMG_IconNpcRole_C:OnDestruct()
  self.uiData = nil
end

function UMG_IconNpcRole_C:SetData(_data, worldMap)
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

function UMG_IconNpcRole_C:SetShowTime(data)
end

function UMG_IconNpcRole_C:SetMapAreaData(_data, worldMap)
  self.uiData = _data
  self.WorldMapConfig = worldMap
  self.needMapShowLevel = 2
  self:UpdateIcon()
  if _data.isNewUnLock then
    _data.isNewUnLock = false
    self:PlayAnimation(self.change_map)
  end
end

function UMG_IconNpcRole_C:GetData()
  return self.uiData
end

function UMG_IconNpcRole_C:UpdateIcon()
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Visible)
  self.iconPath = nil
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
    if self.uiData.status then
      if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        if self.WorldMapConfig.areaicon_explore then
          self:GetIconPath(self.WorldMapConfig.areaicon_explore)
        elseif self.WorldMapConfig.npcicon_unlock then
          self:GetIconPath(self.WorldMapConfig.npcicon_unlock)
          self:SetCornerIcon()
        elseif model and (model.icon or model.ui_icon) then
          self:SetPetIconPath(model.icon or model.ui_icon)
          self:SetCornerIcon()
        end
      elseif self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
        if self.WorldMapConfig.npcicon_unlock then
          self:GetIconPath(self.WorldMapConfig.npcicon_unlock)
          self:SetCornerIcon()
        end
      elseif self.WorldMapConfig.areaicon_unexplore then
        self:GetIconPath(self.WorldMapConfig.areaicon_unexplore)
      elseif self.WorldMapConfig.npcicon_lock then
        self:GetIconPath(self.WorldMapConfig.npcicon_lock)
        self:SetCornerIcon()
      elseif model then
        self:SetPetIconPath(model.icon or model.ui_icon)
      end
    end
    if self.uiData and self.uiData.npc_refresh_id then
      local isCatchPet = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.IsShowCatchPet, self.uiData.npc_refresh_id)
      if isCatchPet and self.WorldMapConfig.world_map_NPCicon_des then
        self:SetCathPet(self.uiData.npc_refresh_id)
      end
    end
  end
end

function UMG_IconNpcRole_C:SetCornerIcon()
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if self.WorldMapConfig.npcicon_corner_unlock and bigMapModule then
    self.Crown:SetPath(bigMapModule:GetMainUIStaticIconRes(self.WorldMapConfig.npcicon_corner_unlock))
    self.Crown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.WorldMapConfig.npcicon_color_unlock then
    local color = self.WorldMapConfig.npcicon_color_unlock .. "FF"
    self.Department:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  end
end

function UMG_IconNpcRole_C:UpdateMapShowLevel(_level, bForceRefresh)
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

function UMG_IconNpcRole_C:SetOpacity(_alpha)
  self.NRCpetIcon:SetOpacity(_alpha)
end

function UMG_IconNpcRole_C:PlayTraceEffect(_show)
  if self.isShowTraceEffect ~= _show then
    self.isShowTraceEffect = _show
    if _show then
      self.traceEffect:LoadPanel(nil)
    else
      self.traceEffect:UnLoadPanel(true)
    end
  end
end

function UMG_IconNpcRole_C:IsFullPath(path)
  local param = string.split(path, "/")
  if #param > 1 then
    return true
  end
  return false
end

function UMG_IconNpcRole_C:GetIconPath(Icon)
  if self:IsFullPath(Icon) then
    self:SetPetPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      self:SetPetPath(bigMapModule:GetBigMapIconRes(Icon))
    end
  end
end

function UMG_IconNpcRole_C:GetPetIconPath(Icon)
  if self:IsFullPath(Icon) then
    self:SetPetPath(Icon)
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      self:SetPetPath(bigMapModule:GetBigMapIconRes(Icon))
    end
  end
end

function UMG_IconNpcRole_C:GetCathIconPath(npcRefreshId)
  if self.WorldMapConfig == nil then
    return
  end
  local path = ""
  if BigMapUtils.CheckShowRongDuanIcon(self.WorldMapConfig, self.uiData.mutation_type) then
    path = self.WorldMapConfig.shine_rongduan_icon
  else
    path = self.WorldMapConfig.world_map_NPCicon_des
  end
  self:SetPetPath(path)
  self.Department:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_IconNpcRole_C:SetCathPet(npcRefreshId)
  self.IsCatchPet = true
  self:GetCathIconPath(npcRefreshId)
end

function UMG_IconNpcRole_C:ShowTravel(npcInfo)
end

function UMG_IconNpcRole_C:GetTravelDownTime()
end

function UMG_IconNpcRole_C:PlayInTravel()
end

function UMG_IconNpcRole_C:PlayOutTravel()
end

function UMG_IconNpcRole_C:OnAnimationFinished(anim)
end

function UMG_IconNpcRole_C:SetPetIconPath(iconPath)
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if iconPath then
    if self.uiData.state then
      if self.uiData.petBase_id and 0 ~= self.uiData.petBase_id then
        if self.uiData.state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
          self:SetRenderOpacity(0)
          self.iconPath = iconPath
          self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self:SetUnFoundIcon()
        elseif not self.uiData.isFound then
          self.iconPath = iconPath
          self:SetDarkIcon()
        else
          self:SetPetPath(iconPath)
        end
      else
        self:SetPetPath(iconPath)
      end
    else
      self:SetPetPath(iconPath)
    end
  end
end

function UMG_IconNpcRole_C:SetDarkIcon()
  local materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_Mask_DressUp3.MI_UI_Mask_DressUp3'"
  self.Icon_Mask:SwitchToSetBrushFromMaterialInstanceMode(true)
  self.Icon_Mask:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#0000007F"))
  self:LoadPanelRes(materialPath, 255, self.OnLoadDarkIconMaterialSucceed, self.OnLoadDarkIconMaterialFail, nil)
end

function UMG_IconNpcRole_C:OnLoadDarkIconMaterialSucceed(_, asset)
  self.Icon_Mask.MaterialInstance = asset
  self.Icon_Mask:SetBrushFromMaterial(asset)
  self:SetPetPath(self.iconPath)
  self.Icon_Mask:SetPathWithCallBack(self.iconPath, {
    self,
    self.OnSetIconMask
  })
end

function UMG_IconNpcRole_C:OnLoadDarkIconMaterialFail()
  self:SetPetPath(self.iconPath)
  self.Icon_Mask:SetPathWithCallBack(self.iconPath, {
    self,
    self.OnSetIconMask
  })
end

function UMG_IconNpcRole_C:OnSetIconMask()
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_IconNpcRole_C:SetUnFoundIcon()
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Department:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Department:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#DCD5C0FF"))
  local materialPath = "MaterialInstanceConstant'/Game/NewRoco/Modules/System/TeamBattle/Res/MI_UI_Silhouettew.MI_UI_Silhouettew'"
  self.Icon_Mask:SwitchToSetBrushFromMaterialInstanceMode(true)
  self.Icon_Mask:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
  self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
end

function UMG_IconNpcRole_C:OnLoadIconMaterialSucceed(_, asset)
  if self.iconPath and asset then
    self.Icon_Mask.MaterialInstance = asset
    self.Icon_Mask:SetBrushFromMaterial(asset)
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadImageResSucc, nil, nil)
  end
end

function UMG_IconNpcRole_C:OnLoadIconMaterialFail()
  if self.iconPath ~= "" then
    self:SetPetPath(self.iconPath)
  end
end

function UMG_IconNpcRole_C:OnLoadImageResSucc(req, asset)
  local material = self.Icon_Mask:GetDynamicMaterial()
  material:SetTextureParameterValue("SpriteTexture", asset)
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SetRenderOpacity(1)
end

return UMG_IconNpcRole_C

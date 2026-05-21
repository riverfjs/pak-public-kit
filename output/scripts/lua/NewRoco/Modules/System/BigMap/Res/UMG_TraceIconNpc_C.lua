local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UMG_TraceIconNpc_C = _G.NRCPanelBase:Extend("UMG_TraceIconNpc_C")
UMG_TraceIconNpc_C.IconType = {
  Pet = 1,
  NPC = 2,
  HandBook = 3,
  Other = 4
}

function UMG_TraceIconNpc_C:OnConstruct()
  self.NRCButton_ClickRange.OnClicked:Add(self, self.OnClickRange)
end

function UMG_TraceIconNpc_C:OnDestruct()
  self.uiData = nil
  self.NRCButton_ClickRange.OnClicked:Remove(self, self.OnClickRange)
end

function UMG_TraceIconNpc_C:OnClickRange()
  Log.Debug("UMG_TraceIconNpc_C:OnClickRange")
  local BigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  BigMapModule:DispatchEvent(BigMapModuleEvent.ClickTraceIconEvent, self)
end

function UMG_TraceIconNpc_C:SetData(_data)
  self.uiData = _data
  self:UpdatePanel()
end

function UMG_TraceIconNpc_C:IsUsable()
  return self.uiData ~= nil
end

function UMG_TraceIconNpc_C:GetImagePosition()
  return self.uiData.imagePosX or 0, self.uiData.imagePosY or 0
end

function UMG_TraceIconNpc_C:UpdateImagePosition(_posX, _posY)
  local uiData = self.uiData
  uiData.imagePosX = _posX or 0
  uiData.imagePosY = _posY or 0
end

function UMG_TraceIconNpc_C:SetVisible(_isVisible)
  if self.isVisible == _isVisible then
    return
  end
  self.isVisible = _isVisible
  if self.isVisible then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TraceIconNpc_C:UpdatePanel()
  self:SetVisible(false)
  self:StopAllAnimations()
  self.Flower = false
  self.bLimitedFlower = false
  self.xishouhuazhong:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Yisehuazhong:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.uiData then
    local Icon, Type
    if self.uiData.npcCfg then
      local _npcInfo = self.uiData.npcCfg
      local worldMapCfgId = self.uiData.npcCfg.world_map_cfg_id
      local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
      if nil == worldMapCfg then
        return
      end
      local model
      if self.uiData.npcCfg.npcCfg then
        model = _G.DataConfigManager:GetModelConf(self.uiData.npcCfg.npcCfg.model_conf)
      end
      if self.uiData.npcCfg.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        if #worldMapCfg.npcicon_levelup > 0 and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
          for i = 1, #worldMapCfg.npcicon_levelup do
            if worldMapCfg.npcicon_levelup[i].level == self.uiData.npcCfg.npc_level then
              Icon = worldMapCfg.npcicon_levelup[i].icon
            end
          end
        elseif BigMapUtils.CheckShowRongDuanIcon(worldMapCfg, self.uiData.mutation_type) then
          Icon = worldMapCfg.shine_rongduan_icon
        else
          Icon = worldMapCfg.npcicon_unlock or model and model.ui_icon or model and model.icon
        end
      else
        Icon = worldMapCfg.npcicon_lock or model and model.ui_icon or model and model.icon
      end
      if _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS or _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT then
        Type = UMG_TraceIconNpc_C.IconType.Pet
        self.Crown_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if self.uiData.npcCfg.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED and worldMapCfg.npcicon_unlock and _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_LEGENDARY_SPIRIT then
          self.Switcher_Boss:SetActiveWidgetIndex(1)
          self.Crown_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.Switcher_Boss:SetActiveWidgetIndex(0)
        end
      elseif _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_CAMP or _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_TELEPORT or _npcInfo.npcCfg.genre == Enum.ClientNpcType.CNT_FLOWER_SEED or worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
        Type = UMG_TraceIconNpc_C.IconType.Other
      elseif worldMapCfg.map_func_icon_group and worldMapCfg.map_func_icon_group == _G.Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
        Type = UMG_TraceIconNpc_C.IconType.Other
      else
        if worldMapCfg.map_show_type == Enum.MapIconShowType.MAP_HANDBOOK_TRACK then
          Type = UMG_TraceIconNpc_C.IconType.HandBook
        else
          Type = UMG_TraceIconNpc_C.IconType.NPC
        end
        if worldMapCfg.default_track_type == Enum.DefaultTrackType.DTT_GLASS or worldMapCfg.default_track_type == Enum.DefaultTrackType.DTT_SURPRISEBOX then
          Type = UMG_TraceIconNpc_C.IconType.NPC
        elseif worldMapCfg.default_track_type == Enum.DefaultTrackType.DTT_SHINE then
          if BigMapUtils.CheckShowRongDuanIcon(worldMapCfg, self.uiData.mutation_type) then
            Type = UMG_TraceIconNpc_C.IconType.NPC
          else
            Type = UMG_TraceIconNpc_C.IconType.Other
          end
        end
        local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
        if worldMapCfg.npcicon_corner_unlock and bigMapModule then
          self.Crown:SetPath(bigMapModule:GetMainUIStaticIconRes(worldMapCfg.npcicon_corner_unlock))
          self.Crown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        if worldMapCfg.npcicon_color_unlock then
          local color = worldMapCfg.npcicon_color_unlock .. "FF"
          self.Department:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
        end
      end
    else
      local worldMapCfgId = self.uiData.world_map_cfg_id
      local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
      if nil == worldMapCfg then
        return
      end
      if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        if #worldMapCfg.npcicon_levelup > 0 and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
          for i = 1, #worldMapCfg.npcicon_levelup do
            if worldMapCfg.npcicon_levelup[i].level == self.uiData.npcCfg.npc_level then
              Icon = worldMapCfg.npcicon_levelup[i].icon
            end
          end
        else
          Icon = worldMapCfg.npcicon_unlock
        end
      else
        Icon = worldMapCfg.npcicon_lock
      end
      Type = UMG_TraceIconNpc_C.IconType.Other
    end
    self:GetIconPath(Icon, Type)
    local worldMapCfgId, worldMapCfg
    if self.uiData.npcCfg then
      worldMapCfgId = self.uiData.npcCfg.world_map_cfg_id
      worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
    else
      worldMapCfgId = self.uiData.world_map_cfg_id
      worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
    end
    local RefreshContentId = self.uiData.npcCfg.npc_refresh_id or worldMapCfg.npc_refresh_ids[1]
    self.Flower = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcFlowerInfo, RefreshContentId)
    if self.Flower then
      self.Yisehuazhong:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Yisehuazhong_Loop)
    else
      self.bLimitedFlower = NRCModuleManager:DoCmd(MagicManualModuleCmd.IsLimitedFlower, RefreshContentId)
      if self.bLimitedFlower then
        self.xishouhuazhong:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation(self.Xishouhuazhong_Loop)
      end
    end
  end
end

function UMG_TraceIconNpc_C:SetArrowDir(_angle)
  local dirMat = self.dirIcon1:GetDynamicMaterial()
  if dirMat then
    dirMat:SetScalarParameterValue("Angle", 90 - _angle)
  end
  self.dirIcon1:SetRenderTransformAngle(90 - _angle)
end

function UMG_TraceIconNpc_C:GetIconPath(icon, type)
  if not self then
    return
  end
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    if type == UMG_TraceIconNpc_C.IconType.NPC then
      self.npcIcon:SetPath(bigMapModule:GetBigMapIconRes(icon))
      self.NPC:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif type == UMG_TraceIconNpc_C.IconType.Pet then
      if bigMapModule:IsFullPath(icon) then
        self.PetIcon:SetIconPath(icon)
      else
        self.PetIcon:SetIconPath(bigMapModule:GetBigMapIconRes(icon))
      end
      self.Pet:SetVisibility(UE4.ESlateVisibility.Visible)
      self.NPC:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif type == UMG_TraceIconNpc_C.IconType.HandBook then
      self:SetPetIconPath(icon)
      self.NPC:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Icon:SetPath(bigMapModule:GetBigMapIconRes(icon))
      self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NPC:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TraceIconNpc_C:GetSceneResId()
  local npcCfg = self.uiData.npcCfg
  if npcCfg then
    if npcCfg.npc_refresh_id then
      local sceneResId = BigMapUtils.GetSceneResIdByRefreshId(npcCfg.npc_refresh_id)
      if sceneResId then
        return sceneResId
      end
    end
    local posX = 0
    local posY = 0
    if npcCfg.npc_pos then
      posX = npcCfg.npc_pos.x
      posY = npcCfg.npc_pos.y
    end
    return BigMapUtils.GetSceneResIdByPos(posX, posY)
  end
  return 10003
end

function UMG_TraceIconNpc_C:OnAnimationFinished(anim)
  if anim == self.Yisehuazhong_Loop then
    if self.Flower then
      self:PlayAnimation(self.Yisehuazhong_Loop)
    end
  elseif anim == self.Xishouhuazhong_Loop and self.bLimitedFlower then
    self:PlayAnimation(self.Xishouhuazhong_Loop)
  end
end

function UMG_TraceIconNpc_C:SetPetIconPath(iconPath)
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if iconPath then
    if self.uiData and self.uiData.npcCfg and self.uiData.npcCfg.state then
      if self.uiData.npcCfg.petBase_id and 0 ~= self.uiData.npcCfg.petBase_id then
        if self.uiData.npcCfg.state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
          self.iconPath = iconPath
          self:SetUnFoundIcon()
        elseif not self.uiData.npcCfg.isFound then
          self.npcIcon:SetPath(iconPath)
          self.Icon_Mask:SetPath(iconPath)
          self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.npcIcon:SetPath(iconPath)
        end
      else
        self.npcIcon:SetPath(iconPath)
      end
    else
      self.npcIcon:SetPath(iconPath)
    end
  end
end

function UMG_TraceIconNpc_C:SetUnFoundIcon()
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Department:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Department:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#DCD5C0FF"))
  local materialPath = "MaterialInstanceConstant'/Game/NewRoco/Modules/System/TeamBattle/Res/MI_UI_Silhouettew.MI_UI_Silhouettew'"
  self.npcIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
  self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
end

function UMG_TraceIconNpc_C:OnLoadIconMaterialSucceed(_, asset)
  if self.iconPath and asset then
    self.npcIcon.MaterialInstance = asset
    self.npcIcon:SetBrushFromMaterial(asset)
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadImageResSucc, nil, nil)
  end
end

function UMG_TraceIconNpc_C:OnLoadIconMaterialFail()
  if self.iconPath ~= "" then
    self.npcIcon:SetPath(self.iconPath)
  end
end

function UMG_TraceIconNpc_C:OnLoadImageResSucc(req, asset)
  local material = self.npcIcon:GetDynamicMaterial()
  material:SetTextureParameterValue("SpriteTexture", asset)
end

return UMG_TraceIconNpc_C

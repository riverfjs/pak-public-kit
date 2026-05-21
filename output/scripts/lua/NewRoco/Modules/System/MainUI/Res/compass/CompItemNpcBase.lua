local Base = require("NewRoco.Modules.System.MainUI.Res.compass.CompItemBase")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local CompItemNpcBase = Base:Extend("CompItemNpcBase")

function CompItemNpcBase:SetIcon()
  if not self.uiData then
    Log.Error("zgx  uiData is nil!!!")
    return
  end
  if not self.uiData.WorldMapConfig then
    Log.Error("zgx WorldMapConfig is nil!!!", self.uiData.Id or "nil")
    return
  end
  local model
  local MapAreaState = self.uiData.MapAreaState
  if self.uiData.NpcConfig then
    model = _G.DataConfigManager:GetModelConf(self.uiData.NpcConfig.model_conf)
  end
  local RefreshContentIds = self.uiData and self.uiData.WorldMapConfig and self.uiData.WorldMapConfig.npc_refresh_ids
  if RefreshContentIds and #RefreshContentIds > 0 then
    for i, RefreshContentId in pairs(RefreshContentIds) do
      local Flower = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcFlowerInfo, RefreshContentId)
      if Flower then
        local flowerTypeWrap = {
          IsShinyFlower = true,
          IsLimitedFlower = false,
          Is7StarHardFlower = false
        }
        self:PlayHuazhongLoop(flowerTypeWrap)
        break
      else
        local bLimitedFlower = NRCModuleManager:DoCmd(MagicManualModuleCmd.IsLimitedFlower, RefreshContentId)
        if bLimitedFlower then
          local flowerTypeWrap = {
            IsShinyFlower = false,
            IsLimitedFlower = true,
            Is7StarHardFlower = false
          }
          self:PlayHuazhongLoop(flowerTypeWrap)
          break
        end
      end
    end
  end
  if self.uiData.IsUnLock and not self.uiData.IsFinish then
    if self.uiData.WorldMapConfig.dungeon_id and self.uiData.WorldMapConfig.dungeon_id > 0 then
      self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.npcicon_unfinished))
    elseif self.uiData.WorldMapConfig.areaicon_explore and self.uiData.CurState == MapAreaState.MAP_AREA then
      self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.areaicon_explore))
    elseif self.uiData.WorldMapConfig.npcicon_unlock and (self.uiData.CurState == MapAreaState.MAP_NPC or self.uiData.CurState == MapAreaState.CHANGE_TO_NPC) then
      if #self.uiData.WorldMapConfig.npcicon_levelup > 0 then
        for i = 1, #self.uiData.WorldMapConfig.npcicon_levelup do
          if self.uiData.WorldMapConfig.npcicon_levelup[i].level == self.uiData.NPC_level then
            if self.uiData.WorldMapConfig.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
              self:SetNpcIconPath(self:GetMapIconPath(self.uiData.WorldMapConfig.npcicon_levelup[i].icon))
            else
              self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.npcicon_levelup[i].icon))
            end
          end
        end
      elseif self.uiData.IsCathPetNpc then
        local path = ""
        if self.uiData.WorldMapConfig.default_track_type == Enum.DefaultTrackType.DTT_SHINE and self.uiData.mutation_type ~= nil and not PetMutationUtils.GetMutationValue(self.uiData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
          path = self.uiData.WorldMapConfig.shine_rongduan_icon
        else
          path = self.uiData.WorldMapConfig.world_map_NPCicon_des
        end
        self:SetNpcIconPath(path)
      else
        if self.Predestined then
          local world_map_ids = _G.DataConfigManager:GetActivityGlobalConfig("hard_flower_world_map_id").numList
          for _, v in ipairs(world_map_ids) do
            if self.uiData.WorldMapConfig.id == v then
              self.Predestined:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
              break
            end
          end
        end
        self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.npcicon_unlock))
      end
      if self.SetCornerIcon then
        self:SetCornerIcon(self.uiData.WorldMapConfig)
      end
    elseif model then
      self:SetNpcIconPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
    else
      Log.Error("zgx comp icon set nil WorldMapConfig ", self.uiData.WorldMapConfig.id)
    end
  elseif self.uiData.IsFinish then
    if self.uiData.WorldMapConfig.dungeon_id and self.uiData.WorldMapConfig.dungeon_id > 0 then
      self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.npcicon_unlock))
    end
  elseif self.uiData.WorldMapConfig.areaicon_unexplore and self.uiData.CurState == MapAreaState.MAP_AREA then
    self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.areaicon_unexplore))
  elseif self.uiData.mutation_type and self.uiData.glass_info and self.uiData.WorldMapConfig.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING then
    local path = self:GetHiddenGlassIcon()
    if "" ~= path then
      self:SetNpcIconPath(path)
    end
  elseif self.uiData.WorldMapConfig.npcicon_lock and (self.uiData.CurState == MapAreaState.MAP_NPC or self.uiData.CurState == MapAreaState.CHANGE_TO_NPC) then
    self:SetNpcIconPath(self:GetNpcIconPath(self.uiData.WorldMapConfig.npcicon_lock))
  elseif model then
    self:SetNpcIconPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
  else
    Log.Error("zgx comp icon set nil WorldMapConfig ", self.uiData.WorldMapConfig.id)
  end
end

function CompItemNpcBase:PlayHuazhongLoop(flowerTypeWrap)
  if not self.huazhongEffect then
    Log.Error("zgx huazhongEffect is nil!!!")
    return
  end
  if not UE4.UObject.IsValid(self.huazhongEffect) or not self.huazhongEffect:IsA(UE4.UNRCWidgetLoader) then
    Log.Error("zgx huazhongEffect is invalid or not UNRCWidgetLoader!!!")
    return
  end
  self.huazhongEffect:LoadPanel(nil, flowerTypeWrap)
end

function CompItemNpcBase:SetNpcIconPath(IconPath)
  Base.SetIcon(self, IconPath)
end

function CompItemNpcBase:GetNpcIconPath(Icon)
  local iconPath
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    if Icon and string.find(Icon, "/Game/NewRoco") then
      iconPath = Icon
    else
      iconPath = bigMapModule:GetBigMapIconRes(Icon)
    end
  end
  return iconPath
end

function CompItemNpcBase:GetMapIconPath(Icon)
  local iconPath
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    if Icon and string.find(Icon, "/Game/NewRoco") then
      iconPath = Icon
    else
      iconPath = bigMapModule:GetBigMapIconRes(Icon)
    end
  end
  return iconPath
end

function CompItemNpcBase:GetCornerPath(Icon)
  local iconPath
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    if Icon and string.find(Icon, "/Game/NewRoco") then
      iconPath = Icon
    else
      iconPath = bigMapModule:GetMainUIStaticIconRes(Icon)
    end
  end
  return iconPath
end

function CompItemNpcBase:GetHiddenGlassIcon()
  if self.uiData and self.uiData.glass_info and self.uiData.mutation_type then
    local isShining = 0 ~= self.uiData.mutation_type & _G.Enum.MutationDiffType.MDT_SHINING
    local HiddenGlassID = self.uiData.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if not isShining and HiddenGlassConf.stroke_small_icon then
          return HiddenGlassConf.stroke_small_icon
        elseif isShining and HiddenGlassConf.yise_stroke_small_icon then
          return HiddenGlassConf.yise_stroke_small_icon
        end
      end
    end
  end
  if self.uiData and self.uiData.WorldMapConfig and self.uiData.WorldMapConfig.npcicon_lock then
    local path = self:GetNpcIconPath(self.uiData.WorldMapConfig.npcicon_lock)
    if path then
      return path
    end
  end
  return ""
end

return CompItemNpcBase

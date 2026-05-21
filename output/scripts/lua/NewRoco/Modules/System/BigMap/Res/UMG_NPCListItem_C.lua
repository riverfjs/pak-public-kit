local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local UMG_NPCListItem_C = _G.NRCPanelBase:Extend("UMG_NPCListItem_C")

function UMG_NPCListItem_C:OnConstruct()
  self.npcdata = {}
end

function UMG_NPCListItem_C:OnDestruct()
end

function UMG_NPCListItem_C:OnActive()
end

function UMG_NPCListItem_C:OnDeactive()
end

function UMG_NPCListItem_C:OnAddEventListener()
  self:RemoveButtonListener(self.ClickBtn, self.OnClickBtnClick)
  self:AddButtonListener(self.ClickBtn, self.OnClickBtnClick)
end

function UMG_NPCListItem_C:SetData(npcData)
  self:OnAddEventListener()
  self.uiData = npcData
  local npcCfg, model
  local worldMapCfgId = npcData.world_map_cfg_id
  if worldMapCfgId then
    self.NRCImage1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(worldMapCfgId)
    if nil == worldMapCfg then
      return
    end
    if self.uiData.npcCfg then
      model = _G.DataConfigManager:GetModelConf(self.uiData.npcCfg.model_conf)
    else
      local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(worldMapCfg.npc_refresh_ids[1])
      local npcId = refreshConf.npc_id
      local npcCfg = _G.DataConfigManager:GetNpcConf(npcId)
      model = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
    end
    if npcData.npcCfg then
      npcCfg = npcData.npcCfg
      if worldMapCfg.element_text_name and worldMapCfg.element_text_name ~= "" then
        self.ItemDesc:SetText(worldMapCfg.element_text_name)
      else
        self.ItemDesc:SetText(npcCfg.name)
      end
    else
      npcCfg = npcData
      self.ItemDesc:SetText(worldMapCfg.element_text_name)
    end
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_108:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.uiData.status then
      if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        if worldMapCfg.dungeon_id and worldMapCfg.dungeon_id > 0 then
          if worldMapCfg.map_tips_show_type and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CHALLENGE_EVENT then
            local switcherIndex = 1
            self:GetIconPath(worldMapCfg.npcicon_unlock, switcherIndex)
          else
            self:GetIconPath(worldMapCfg.npcicon_unfinished)
          end
        elseif worldMapCfg.areaicon_explore then
          if BigMapUtils.CheckShowRongDuanIcon(worldMapCfg, self.uiData.mutation_type) then
            self:GetIconPath(worldMapCfg.shine_rongduan_icon)
          else
            self:GetIconPath(worldMapCfg.areaicon_explore)
          end
        elseif worldMapCfg.npcicon_unlock then
          if #worldMapCfg.npcicon_levelup > 0 then
            for i = 1, #worldMapCfg.npcicon_levelup do
              if worldMapCfg.npcicon_levelup[i].level == self.uiData.npc_level then
                if worldMapCfg.map_tips_show_type and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CAMP or worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
                  self.NRCSwitcher_63:SetActiveWidgetIndex(0)
                end
                self:GetIconPath(worldMapCfg.npcicon_levelup[i].icon)
              end
            end
          elseif worldMapCfg.map_tips_show_type and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_PIKA then
            self:GetIconPath(worldMapCfg.npcicon_unlock)
          elseif worldMapCfg.map_tips_show_type and worldMapCfg.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_BOSS_BATTLE then
            local switcherIndex = 2
            self:GetIconPath(worldMapCfg.npcicon_unlock, switcherIndex)
          elseif worldMapCfg.map_func_icon_group and worldMapCfg.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
            self:GetIconPath(worldMapCfg.npcicon_unlock)
          elseif self.uiData.npcCfg.genre == Enum.ClientNpcType.CNT_FLOWER_SEED then
            self:GetIconPath(worldMapCfg.npcicon_unlock)
          else
            local switcherIndex = 1
            self:GetIconPath(worldMapCfg.npcicon_unlock, switcherIndex)
          end
        elseif model then
          if self.uiData.npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS then
            self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.Pet:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
            self.NRCpetIcon:SetPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
          else
            self:SetPetIconPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
          end
        end
      elseif self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH then
        if worldMapCfg.dungeon_id and worldMapCfg.dungeon_id > 0 then
          self:GetIconPath(worldMapCfg.npcicon_unlock)
        end
      elseif worldMapCfg.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING or worldMapCfg.map_show_type == Enum.MapIconShowType.MAP_SHINING_SEASON_DAZZLING then
        local path = self:GetHiddenGlassIcon()
        if path and "" ~= path then
          self.NRCSwitcher_63:SetActiveWidgetIndex(2)
          self.pet1:SetPath(path)
        else
          self:GetIconPath(worldMapCfg.npcicon_lock)
        end
        self:GetIconPath(path)
      elseif worldMapCfg.areaicon_unexplore then
        self:GetIconPath(worldMapCfg.areaicon_unexplore)
      elseif worldMapCfg.npcicon_lock then
        if worldMapCfg.map_func_icon_group and worldMapCfg.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
          self.NRCSwitcher_63:SetActiveWidgetIndex(0)
        end
        self:GetIconPath(worldMapCfg.npcicon_lock)
      elseif model then
        if self.uiData.npcCfg.genre == Enum.ClientNpcType.CNT_PETBOSS then
          self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Pet:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
          self.NRCpetIcon:SetPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
        else
          self.Icon:SetPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
        end
      end
    elseif npcData.SpecialTaskType and npcData.SpecialTaskType == "TreasureDig" then
      self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/CompassIcon/Frames/img_cangbaotu_png.img_cangbaotu_png'")
    else
      self.Pet:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.NRCpetIcon:SetPath(NRCUtils:FormatConfIconPath(model.ui_icon, _G.UIIconPath.UIHeadIconPath))
    end
  elseif npcData.MarksType and npcData.MarksType == BigMapModuleEnum.MarksType.CustomMark then
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_108:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local worldMapConfig = _G.DataConfigManager:GetWorldMapConf(self.uiData.mapCfgId)
    self.Bg_1:SetPath(worldMapConfig.map_markicon)
    local name = self.uiData.name
    if not name or "" == name then
      name = _G.DataConfigManager:GetLocalizationConf("umg_markerpanel_1").msg
    end
    self.ItemDesc:SetText(name)
  elseif npcData.visitorIndex and npcData.visitorIndex > 0 and npcData.visitorInfo then
    self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_108:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Bg_1:SetPath("PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMapStatic/Frames/img_pailiedi_png.img_pailiedi_png'")
    self.NRCText_28:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_28:SetText(tostring(npcData.visitorIndex))
    local visitorInfo = NRCModuleManager:DoCmd(FriendModuleCmd.GetOnlineVisitorByUin, npcData.visitorInfo.uin)
    if visitorInfo then
      self.ItemDesc:SetText(visitorInfo.name)
    else
      Log.Error("visitorInfo is nil")
    end
  else
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_108:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local showTitle = ""
    local taskClass = Enum.TaskClassType.TCT_MAIN
    if npcData.TaskShowType == BigMapModuleEnum.TaskShowType.UNDO then
      local IconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
      showTitle = _G.DataConfigManager:GetLocalizationConf("task_unknown_title").msg
      local taskConf = npcData.ShowTaskConf or npcData.TaskConf
      if taskConf then
        Log.Debug("UMG_NPCListItem_C:SetData taskConf id=", taskConf.id)
        taskClass = taskConf.task_class
        if taskClass == Enum.TaskClassType.TCT_MAIN then
          IconPath = UEPath.TASK_ICON_MAIN_WENHAO
        elseif taskClass == Enum.TaskClassType.TCT_SUB or taskClass == Enum.TaskClassType.TCT_EVOLUTION or taskClass == Enum.TaskClassType.TCT_CAMPAIGN then
          IconPath = UEPath.TASK_ICON_SUB_WENHAO
        elseif taskClass == Enum.TaskClassType.TCT_JOURNEY or taskClass == Enum.TaskClassType.TCT_DUNGEON then
          IconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
        else
          IconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
        end
      end
      self.NRCpetIcon:SetPath(IconPath)
    else
      local taskConf = npcData.ShowTaskConf or npcData.TaskConf
      local paragraphId = taskConf.paragraph_id
      local paragraphConf
      if paragraphId then
        paragraphConf = _G.DataConfigManager:GetParagraphConf(paragraphId)
      end
      if npcData.TaskShowType == BigMapModuleEnum.TaskShowType.TRACING then
        taskClass = taskConf.task_class
        if paragraphConf then
          showTitle = paragraphConf.title
        end
      else
        taskClass = taskConf.task_class
        if paragraphConf then
          showTitle = paragraphConf.title
        end
      end
      if taskClass == Enum.TaskClassType.TCT_MAIN then
        self.NRCpetIcon:SetPath(UEPath.TASK_ICON_ZHUXIAN)
      elseif taskClass == Enum.TaskClassType.TCT_SUB then
        self.NRCpetIcon:SetPath(UEPath.TASK_ICON_ZHIXIAN)
      elseif taskClass == Enum.TaskClassType.TCT_JOURNEY then
        self.NRCpetIcon:SetPath(UEPath.TASK_ICON_SHILIAN)
      else
        self.NRCpetIcon:SetPath(UEPath.TASK_ICON_ZHUXIAN)
      end
    end
    self.ItemDesc:SetText(showTitle)
  end
end

function UMG_NPCListItem_C:GetIconPath(icon, switcherIndex)
  self.NRCSwitcher_63:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if bigMapModule then
    if switcherIndex then
      if 1 == switcherIndex then
        self.NRCSwitcher_63:SetActiveWidgetIndex(switcherIndex)
        self.Npc:SetPath(bigMapModule:GetBigMapIconRes(icon))
      elseif 2 == switcherIndex then
        self.NRCSwitcher_63:SetActiveWidgetIndex(switcherIndex)
        self.pet1:SetPath(bigMapModule:GetBigMapIconRes(icon))
      end
    else
      self.NRCSwitcher_63:SetActiveWidgetIndex(0)
      self.Icon:SetPath(bigMapModule:GetBigMapIconRes(icon))
    end
  end
end

function UMG_NPCListItem_C:OnSelected(bool)
  if bool then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401015, "UMG_IconNpcTemple_C:ShowSelectState")
    self:SetSelect(true)
    self:PlayAnimation(self.out)
  else
    self:SetSelect(false)
  end
end

function UMG_NPCListItem_C:SetSelect(bSelect)
  if bSelect then
    self.Background_Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemDesc:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
  else
    self.Background_Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemDesc:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C4C2B6FF"))
  end
end

function UMG_NPCListItem_C:OnAnimationFinished(anim)
  local BigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  if anim == self.out then
    BigMapModule:DispatchEvent(BigMapModuleEvent.HideNPCList)
    BigMapModule:DispatchEvent(BigMapModuleEvent.ShowNormalNpcEvent, self.uiData)
  end
end

function UMG_NPCListItem_C:OnClickBtnClick()
  local BigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
  BigMapModule:DispatchEvent(BigMapModuleEvent.ClearNPCListSelectedState)
  Log.Debug("UMG_NPCListItem_C:OnClickBtnClick")
  self:OnSelected(true)
end

function UMG_NPCListItem_C:PlayItemShowAnim()
  self:PlayAnimation(self.In)
end

function UMG_NPCListItem_C:SetPetIconPath(iconPath)
  self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.wenHao:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if iconPath then
    if self.uiData and self.uiData.state then
      self.NRCSwitcher_63:SetActiveWidgetIndex(2)
      if self.uiData.petBase_id and 0 ~= self.uiData.petBase_id then
        if self.uiData.state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
          self.iconPath = iconPath
          self:SetUnFoundIcon()
        elseif not self.uiData.isFound then
          self.pet1:SetPath(iconPath)
          self.Icon_Mask:SetPath(iconPath)
          self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.pet1:SetPath(iconPath)
        end
      else
        self.pet1:SetPath(iconPath)
      end
    else
      self.Icon:SetPath(iconPath)
    end
  end
end

function UMG_NPCListItem_C:SetUnFoundIcon()
  self.wenHao:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ItemDesc:SetText("???")
  local materialPath = "MaterialInstanceConstant'/Game/NewRoco/Modules/System/TeamBattle/Res/MI_UI_Silhouettew.MI_UI_Silhouettew'"
  self.pet1:SwitchToSetBrushFromMaterialInstanceMode(true)
  self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
end

function UMG_NPCListItem_C:OnLoadIconMaterialSucceed(_, asset)
  if self.iconPath and asset then
    self.pet1.MaterialInstance = asset
    self.pet1:SetBrushFromMaterial(asset)
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadImageResSucc, nil, nil)
  end
end

function UMG_NPCListItem_C:OnLoadIconMaterialFail()
  if self.iconPath ~= "" then
    self.pet1:SetPath(self.iconPath)
  end
end

function UMG_NPCListItem_C:OnLoadImageResSucc(req, asset)
  local material = self.pet1:GetDynamicMaterial()
  material:SetTextureParameterValue("SpriteTexture", asset)
end

function UMG_NPCListItem_C:GetHiddenGlassIcon()
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
  return ""
end

return UMG_NPCListItem_C

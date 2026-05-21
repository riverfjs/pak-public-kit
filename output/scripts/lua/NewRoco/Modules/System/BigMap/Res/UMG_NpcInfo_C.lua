local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_NpcInfo_C = _G.NRCViewBase:Extend("UMG_NpcInfo_C")
UMG_NpcInfo_C.TraceType = {NPC = 1, TASK = 2}

function UMG_NpcInfo_C:Initialize(Initializer)
end

function UMG_NpcInfo_C:OnConstruct()
  self.data = self.module:GetData("BigMapModuleData")
  self:SetChildViews(self.MagicInfo)
  self.icon = "PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/img_combtn_di1_png.img_combtn_di1_png'"
  self.Btn1:SetPath(self.icon)
  self.Btn1:SetPath(self.icon)
  self.Btn1:SetPath(self.icon)
  self.Btn1:SetBtnText(LuaText.umg_npcinfo_1)
  self.Btn2:SetBtnText(LuaText.umg_npcinfo_2)
  self.Btn3:SetBtnText(LuaText.umg_npcinfo_3)
  self.uiItem = {}
  self:OnAddEventListener()
  self.traceType = 0
  self.Btn5:SetClickAble(false)
  self.Btn5:SetBtnText(LuaText.umg_npcinfo_2)
  self.lastIconCategory = nil
  self.lastStoreId = nil
end

function UMG_NpcInfo_C:UpdateShinyFlowerInfo()
  local Flower, FlowerInfoTypeWrap = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetNpcFlowerInfo, self.uiData.npc_refresh_id)
  local props = {
    shouldSetPetIcon = false,
    npcRefreshId = "",
    petIconPath = "",
    FlowerInfoTypeWrap = FlowerInfoTypeWrap
  }
  if Flower and FlowerInfoTypeWrap.IsShinyFlower then
    props.npcRefreshId = self.uiData.npc_refresh_id
    if self.FlowerPetModelConf then
      props.shouldSetPetIcon = true
      props.petIconPath = self.FlowerPetModelConf.shiny_icon
    end
    if self.Star_1 then
      self.NRCSwitcher_56:SetActiveWidgetIndex(1)
      self.Star_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif self.Star_1 then
    self.Star_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.WidgetLoader:GetPanel() and self.WidgetLoader:GetPanel().UpdateShinyFlowerInfo then
    self.WidgetLoader:GetPanel():UpdateShinyFlowerInfo(Flower, props)
  end
end

function UMG_NpcInfo_C:OnDestruct()
  if self.worldMap and self.worldMap.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.LeaveOwlSanctuaryRigthPanel)
  end
  table.clear(self.uiItem)
  self.uiData = nil
  self.worldMap = nil
  self.uiItem = nil
  self.module.data:SetNpcTipShowType(nil)
end

function UMG_NpcInfo_C:OnEnable()
end

function UMG_NpcInfo_C:OnDisable()
end

function UMG_NpcInfo_C:OnAddEventListener()
  self:AddButtonListener(self.Btn1.btnLevelUp, self.OnBtnTraceClick)
  self:AddButtonListener(self.btnUnkown, self.OnBtnUnkownClick)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnBtnTransferClick)
  self:AddButtonListener(self.Btn3.btnLevelUp, self.OnBtnCancelTraceClick)
  self:AddButtonListener(self.Btn4.btnLevelUp, self.OnMarkBtnClick)
  self:AddButtonListener(self.BtnTeleportationChamber.btnLevelUp, self.OnSpecialTransBtnClicked)
  self:AddButtonListener(self.BtnTransfer.btnLevelUp, self.OnTransBtnClicked)
  self:RegisterEvent(self, BigMapModuleEvent.StarNumChange, self.UpdateHealth)
  self:RegisterEvent(self, BigMapModuleEvent.NpcRefreshTimeChange, self.OnNpcRefreshTimeChange)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateShinyFlowerInfo, self.UpdateShinyFlowerInfo)
  self.WidgetLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
end

function UMG_NpcInfo_C:OnLoadWidgetCallback(Panel)
  if Panel then
    self:UpdateShinyFlowerInfo()
  end
end

function UMG_NpcInfo_C:OnNpcRefreshTimeChange(_npcInfo)
  self.bPlayOpenAnim = false
  if _npcInfo.world_map_cfg_id then
    local worldMapCfg = _G.DataConfigManager:GetWorldMapConf(_npcInfo.world_map_cfg_id)
    if worldMapCfg and self.uiData and worldMapCfg.npc_refresh_ids[1] == self.uiData.npc_refresh_id then
      self.uiData = _npcInfo
      self:UpdatePanel(_npcInfo)
    end
  elseif self.uiData and _npcInfo.npc_refresh_id and self.uiData.npc_refresh_id == _npcInfo.npc_refresh_id then
    self.uiData = _npcInfo
    self:UpdatePanel(_npcInfo)
  end
end

function UMG_NpcInfo_C:UpdateHealth()
  if self.enableView then
    local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    local stamina = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
    local StaminaProportion = string.format("%s%s%s", StarNum, "/", stamina.num)
  end
end

function UMG_NpcInfo_C:OnRemoveEventListener()
end

function UMG_NpcInfo_C:InitPanelData(_data, worldMap, extraInfo, bPlayOpenAnim)
  if nil == bPlayOpenAnim then
    bPlayOpenAnim = true
  end
  self.bPlayOpenAnim = bPlayOpenAnim
  if self.bPlayOpenAnim then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.btnState = 0
  self.uiData = _data
  self.worldMap = worldMap
  self.extraInfo = extraInfo
  self:UpdatePanel(_data)
end

function UMG_NpcInfo_C:OnTick(deltaTime)
  if self.uiData and self.uiData.next_npc_refresh_time and self.uiData.next_npc_refresh_time > 0 then
    local refreshTime = self.uiData.next_npc_refresh_time - _G.ZoneServer:GetServerTime() / 1000
    if refreshTime >= 0 then
      local min = math.floor(refreshTime / 60)
      local sec = math.ceil(refreshTime - min * 60)
      local btnText = ""
      if BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) then
        btnText = DataConfigManager:GetLocalizationConf("home_to_world_maptips_info_old").msg
      else
        btnText = string.format(LuaText.umg_npcinfo_4, min, sec)
      end
      if self.Btn5 then
        self.Btn5:SetShowLockIcon(false)
        self.Btn5:SetTitleTextAndIcon(nil, nil, nil, true, btnText)
        self.Btn5:SetTitleTextColor("c7494a")
      end
    elseif 4 == self.btnState then
      if self._npcType == _G.Enum.ClientNpcType.CNT_PETBOSS and self.isUnLock then
        self:SetBtnSwitcherIndex(2)
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CloseMapRightPanel)
      else
        self:SetBtnSwitcherIndex(1)
        self:OnBtnCancelTraceClick()
      end
    end
  end
end

function UMG_NpcInfo_C:UpdatePanel(_npcInfo)
  if self.NRCSwitcher_56 then
    self.NRCSwitcher_56:SetActiveWidgetIndex(0)
  end
  self.Btn2:SetBtnText(LuaText.umg_npcinfo_2)
  local teleportId = 0
  if _npcInfo then
    if _npcInfo.npcCfg then
      self:SelectPanel(_npcInfo)
      if not _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
        self:UpdateMessage(_npcInfo.npcCfg.genre)
        self.textMessage:SetText(self.worldMap.unlock_warn_tips or "")
      else
        self:setActive(self.textMessage, false)
      end
      if self.worldMap then
        if self.worldMap.teleport_id > 0 then
          teleportId = self.worldMap.teleport_id
        else
          teleportId = self.worldMap.teleport_rule_id
        end
        self:UpdateButtonState(_npcInfo.npcCfg.genre, teleportId, _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH)
      else
        Log.Error("worldMap is nil!!!")
      end
    elseif self.worldMap then
      self:SelectPanel(_npcInfo)
      if self.worldMap.map_show_type == Enum.MapIconShowType.MAP_ONLINE_TEAM then
        self:setActive(self.textMessage, false)
        self:UpdateButtonState(nil, nil, true)
      else
        if not _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
          self.textMessage:SetText(self.worldMap.unlock_warn_tips or "")
        else
          self:setActive(self.textMessage, false)
        end
        local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(self.worldMap.npc_refresh_ids[1])
        local npcId = refreshConf.npc_id
        local npcCfg = _G.DataConfigManager:GetNpcConf(npcId)
        local genre = npcCfg.genre
        if self.worldMap.teleport_id > 0 then
          teleportId = self.worldMap.teleport_id
        else
          teleportId = self.worldMap.teleport_rule_id
        end
        self:UpdateButtonState(genre, teleportId, _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED or _npcInfo.status == _G.ProtoEnum.LockStatus.ENUM.DUNGEON_FINISH)
      end
    else
      self:SelectPanel(_npcInfo)
      self:setActive(self.textMessage, false)
      self:UpdateButtonState(nil)
    end
  else
    self:setActive(self.textMessage, false)
    self.textMessage:SetText("")
    local unLockTips = ""
    self.textMessage:SetText(unLockTips)
    self:SetBtnSwitcherIndex(0)
  end
  self:UpdateShinyFlowerInfo()
end

function UMG_NpcInfo_C:SelectPanel(_npcInfo)
  if self.worldMap then
    local npcTipsShowType = self.worldMap.map_tips_show_type
    if npcTipsShowType then
      self.btnSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
      if npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_CAMP then
        local CampingInfo = _G.DataConfigManager:GetCampConf(_npcInfo.npc_refresh_id)
        local advantage_type = CampingInfo.advantage_type
        local disadvantage_type = CampingInfo.disadvantage_type
        self.GoodAndBad:OnActive(advantage_type, disadvantage_type)
      end
      self.GoodAndBad:SetVisibility(npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_CAMP and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
      if self.module.data:GetNpcTipShowType() ~= _G.Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP then
        self:UnloadLastPanel(self.lastIconCategory, npcTipsShowType)
      end
      self:ResetPanelState()
      self.lastIconCategory = npcTipsShowType
      if npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_TELEPORT or npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_ACTIVITY_DROP then
        self:UpdatePanel1Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_NORMALFUNC then
        self:UpdatePanel2Info(_npcInfo, true)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_TRAVEL then
        self:UpdatePanel5Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_DUNGEON then
        self:UpdatePanel3Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_CAMP then
        self:UpdatePanel4Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_TEAM_BATTLE then
        self:UpdatePanel6Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_BOSS_BATTLE then
        self:UpdatePanel7Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_LEGENDARY_BATTLE then
        self:UpdatePanel9Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_PIKA then
        self:UpdatePanel10Info()
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
        self:UpdatePanelSanctuaryInfo(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_CHALLENGE then
        self:UpdatePanel11Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_CHALLENGE_EVENT then
        self:UpdatePanel13Info(_npcInfo)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_CONSUMPTION then
        self:UpdatePanel2Info(_npcInfo, true)
      elseif npcTipsShowType == _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_COMMON then
        self:UpdatePanel2Info(_npcInfo, false)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_HOME then
        self.btnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:UpdatePanelHomeInfo(_npcInfo)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_PLANT then
        self:UpdatePlantGroundInfo(_npcInfo)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP then
        self:UpdatePanelRandomShopInfo(_npcInfo)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_ONLINE_TEAM then
        self:UpdatePanel14Info(_npcInfo)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_SEASON then
        self:UpdatePanel15Info(_npcInfo)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_TERRITORY_TRIAL then
        self:UpdatePanel16Info(_npcInfo)
      elseif npcTipsShowType == Enum.MapTipsShowType.MAP_TIPS_AUTO_TRACK then
        self:UpdatePanel17Info(_npcInfo)
      end
      self.module.data:SetNpcTipShowType(npcTipsShowType)
    end
  else
    self:ResetPanelState()
    self:UpdatePanel8Info(_npcInfo)
    _G.NRCEventCenter:DispatchEvent(BigMapModuleEvent.ExcludeUmgPanelEvent, "NpcInfo")
  end
end

function UMG_NpcInfo_C:SetTransferBtn()
  local transferBtnCnt = self.module:GetTransferBtnNum(self.worldMap)
  if 0 == transferBtnCnt then
  elseif 1 == transferBtnCnt then
    self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Teleport_1)
  elseif 2 == transferBtnCnt then
    self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Teleport_2)
  end
  local transferBtnText = self.worldMap.teleport_text
  if string.IsNilOrEmpty(transferBtnText) then
    transferBtnText = LuaText.umg_npcinfo_2
  end
  local specialTransferBtnText = self.worldMap.special_teleport_text
  if string.IsNilOrEmpty(specialTransferBtnText) then
    specialTransferBtnText = LuaText.umg_npcinfo_9
  end
  if 1 == transferBtnCnt then
    if self.worldMap.teleport_id > 0 or self.worldMap.teleport_rule_id > 0 then
      self.Btn2:SetBtnText(transferBtnText)
    else
      self.Btn2:SetBtnText(specialTransferBtnText)
    end
  end
  self.BtnTransfer:SetBtnText(transferBtnText)
  self.BtnTeleportationChamber:SetBtnText(specialTransferBtnText)
end

function UMG_NpcInfo_C:UnloadLastPanel(panelType, curPanelType)
  if curPanelType ~= _G.Enum.MapTipsShowType.MAP_TIPS_PIKA and curPanelType ~= _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_COMMON and curPanelType ~= _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_CONSUMPTION then
    self.lastStoreId = nil
    self.WidgetLoader:UnLoadPanel(true)
    return
  end
  if panelType ~= curPanelType then
    self.lastStoreId = nil
    self.WidgetLoader:UnLoadPanel(true)
    return
  end
end

function UMG_NpcInfo_C:ResetPanelState()
  if self.NRCImage_72 then
    self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.StudyTourTime then
    self.StudyTourTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

local function SetHeadIconFunc(self)
  local retIcon, bIsFullPath
  local worldMapConf = self.worldMap
  if nil == worldMapConf and self.uiData.world_map_cfg_id then
    worldMapConf = _G.DataConfigManager:GetWorldMapConf(self.uiData.world_map_cfg_id)
  end
  if not worldMapConf then
    return nil
  end
  if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
    if self.worldMap.areaicon_explore then
      if worldMapConf and worldMapConf.map_show_type == Enum.MapIconShowType.MAP_CREATE_MAGIC then
        retIcon = self:GetDesIconPath(worldMapConf.world_map_NPCicon_des)
      else
        retIcon = self:GetDesIconPath(self.worldMap.areaicon_explore)
      end
    elseif self.worldMap.npcicon_unlock then
      if #self.worldMap.npcicon_levelup > 0 then
        for i = 1, #self.worldMap.npcicon_levelup do
          if self.worldMap.npcicon_levelup[i].level == self.uiData.npc_level then
            retIcon = self:GetDesIconPath(self.worldMap.npcicon_levelup[i].icon)
          end
        end
      else
        retIcon = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
      end
    end
  elseif self.worldMap.areaicon_unexplore then
    if worldMapConf and worldMapConf.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
      local iconDes = self.worldMap.world_map_NPCicon_des
      local iconDesHui = string.gsub(iconDes, "_png", "_hui_png")
      retIcon = self:GetDesIconPath(iconDesHui)
    else
      retIcon = self:GetDesIconPath(self.worldMap.areaicon_unexplore)
    end
  elseif self.worldMap.npcicon_lock then
    if self.worldMap.world_map_NPCicon_des then
      local iconDes = self.worldMap.world_map_NPCicon_des
      retIcon, bIsFullPath = self:GetDesIconPath(iconDes)
      if not bIsFullPath then
        local iconDesHui = string.gsub(iconDes, "_png", "_hui_png")
        retIcon = self:GetDesIconPath(iconDesHui)
      end
    else
      retIcon = self:GetDesIconPath(self.worldMap.npcicon_lock)
    end
  elseif self.worldMap.world_map_NPCicon_des then
    local iconDes = self.worldMap.world_map_NPCicon_des
    retIcon, bIsFullPath = self:GetDesIconPath(iconDes)
    if not bIsFullPath then
      retIcon = self:GetDesIconPath(iconDes)
    end
  else
    retIcon = self:GetDesIconPath(self.worldMap.npcicon_lock)
  end
  return retIcon
end

function UMG_NpcInfo_C:UpdatePanel11Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  if not _npcInfo then
    Log.Error("UMG_NpcInfo:UpdatePanel10Info Error! _npcInfo is nil")
    return
  end
  local npcCfg = _npcInfo.npcCfg
  local title = ""
  local desc = ""
  local icon = ""
  if self.worldMap and self.worldMap.element_text_name then
    title = self.worldMap.element_text_name
  else
  end
  if self.worldMap then
    desc = self.worldMap.worldmap_npc_des or ""
  else
    if npcCfg then
      desc = ""
      desc = npcCfg.worldmap_npc_des or desc
    else
    end
  end
  icon = SetHeadIconFunc(self)
  local mapChallengeCfg = _G.DataConfigManager:GetWorldMapChallengeConf(_npcInfo.npc_refresh_id)
  local displayItems = {}
  if mapChallengeCfg and mapChallengeCfg.show_reward and table.len(mapChallengeCfg.show_reward) > 0 then
    for _, reward in ipairs(mapChallengeCfg.show_reward) do
      local displayItem = _G.NRCCommonItemIconData()
      displayItem.itemType = reward.reward_type
      displayItem.itemId = reward.reward_id
      displayItem.itemNum = reward.reward_count
      displayItem.bShowNum = true
      displayItem.bShowTip = true
      table.insert(displayItems, displayItem)
    end
  end
  self.WidgetLoader:SetWidgetClass(self.ChallengeNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, title, desc, icon, displayItems)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel1Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    name = "",
    desc = "",
    headIconIndex = 0,
    isHeadIcon = false,
    headIconPath = "",
    bShowCatchTime = false,
    petCircadian = Enum.PetCircadian.PC_ALLDAY,
    state = nil,
    isFound = nil
  }
  local npcCfg = _npcInfo.npcCfg
  if self.worldMap then
    if self.worldMap.element_text_name then
      props.name = self.worldMap.element_text_name
    elseif npcCfg and npcCfg.name then
      props.name = npcCfg.name
    else
      props.name = ""
    end
    if self.worldMap then
      props.desc = self.worldMap.worldmap_npc_des or ""
    elseif npcCfg then
      props.desc = npcCfg.worldmap_npc_des or ""
    end
    self.StudyTourTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if not (self.worldMap.map_show_type == Enum.MapIconShowType.MAP_CREATE_MAGIC or self.worldMap.map_func_icon_group) or 0 == self.worldMap.map_func_icon_group then
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = false
      props.headIconIndex = 1
    elseif self.worldMap.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCROLE then
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = false
      props.headIconIndex = 1
    elseif self.worldMap.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCPET then
      if _npcInfo.petBase_id and 0 ~= _npcInfo.petBase_id then
        props.headIconPath = string.format("Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/%s.%s'", _npcInfo.petBase_id, _npcInfo.petBase_id)
        props.isHeadIcon = false
        props.headIconIndex = 1
        props.bShowCatchTime = true
        if "" == props.desc then
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_npcInfo.petBase_id, false)
          if petBaseConf then
            props.petCircadian = petBaseConf.Pet_Circadian
            props.desc = petBaseConf.description
            props.name = petBaseConf.name
          end
        end
        props.state = _npcInfo.state
        props.isFound = _npcInfo.isFound
      else
        local model = _G.DataConfigManager:GetModelConf(_npcInfo.npcCfg and _npcInfo.npcCfg.model_conf)
        props.headIconPath = model and (model.icon or model.ui_icon)
        props.isHeadIcon = false
        props.headIconIndex = 1
        props.bShowCatchTime = false
        if "" == props.desc and _npcInfo.npcCfg and _npcInfo.npcCfg.traverse_data_param and _npcInfo.npcCfg.traverse_data_type == Enum.Traverse_Data_Type.TDT_BAGITEM then
          local bagItem_conf = _npcInfo.npcCfg and _G.DataConfigManager:GetBagItemConf(_npcInfo.npcCfg.traverse_data_param[1])
          if bagItem_conf then
            props.name = bagItem_conf.name
            props.desc = bagItem_conf.description
          end
        end
        props.state = 3
        props.isFound = true
      end
    elseif self.worldMap.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCFUNCTION then
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = true
      props.headIconIndex = 0
      if _npcInfo.npcCfg and _npcInfo.npcCfg.genre == _G.Enum.ClientNpcType.CNT_ALCHEMY and (_G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsBottleTimeUpgradeEnable) or _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRolePowerUpgradeEnable) or _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRoleHpUpgradeEnable)) then
        self.StudyTourTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.StudyTourTime:SetText(_G.LuaText.alchemy_magic_enhance_available)
        self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = true
      props.headIconIndex = 0
    end
  end
  self.WidgetLoader:SetWidgetClass(self.CommonNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, 0, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel2Info(_npcInfo, hasConsumptionCount)
  local shouldReloadPanel = false
  local npcCfg = _npcInfo.npcCfg
  local shopInfo
  if (self.worldMap.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_CONSUMPTION or self.worldMap.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_COMMON) and self.worldMap.map_tips_param and #self.worldMap.map_tips_param > 0 then
    shopInfo = _G.DataConfigManager:GetShopConf(self.worldMap.map_tips_param[1])
  end
  local isOnlineMode = false
  if shopInfo then
    local cardReq = _G.ProtoMessage.newZoneGetPlayerCardInfoReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_INFO_REQ, cardReq, self, self.OnZoneGetPlayerCardInfoRsp, false, true)
    local req = _G.ProtoMessage:newZoneShopGetInfoReq()
    req.shop_id = shopInfo.id
    if self.lastIconCategory ~= _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_CONSUMPTION and self.lastIconCategory ~= _G.Enum.MapTipsShowType.MAP_TIPS_SHOP_TOTAL_COMMON or self.lastStoreId ~= shopInfo.id then
      self.WidgetLoader:UnLoadPanel(true)
      shouldReloadPanel = true
    end
    self.lastStoreId = shopInfo.id
    local reqShopData = {
      shopId = shopInfo.id,
      Caller = self,
      rspHandler = self.GetStoreListRsp,
      needModal = false,
      ignoreErrorTip = false,
      reqTag = "UMG_NpcInfo_C:UpdatePanel2Info"
    }
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      if playerUin == _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() then
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
      else
        isOnlineMode = true
        self:OnPanelShow(true)
      end
    else
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
    end
  else
    self:UpdatePanel1Info(_npcInfo)
    return
  end
  local title = ""
  local desc = ""
  local titleIcon = ""
  if self.worldMap then
    if self.worldMap.element_text_name then
      title = self.worldMap.element_text_name
    else
      if npcCfg and npcCfg.name then
        title = npcCfg.name
      else
      end
    end
    if self.worldMap then
      desc = self.worldMap.worldmap_npc_des or ""
    elseif npcCfg then
      desc = npcCfg.worldmap_npc_des or ""
    end
    local iconDes = self.worldMap.world_map_NPCicon_des or ""
    titleIcon = self:GetDesIconPath(iconDes)
  end
  if shouldReloadPanel then
    self.WidgetLoader:SetWidgetClass(self.MerchantNpcClassRef)
    self.WidgetLoader:LoadPanelSync(self, hasConsumptionCount, isOnlineMode, title, desc, titleIcon)
  end
end

function UMG_NpcInfo_C:UpdatePanel3Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local npcCfg = _npcInfo.npcCfg
  if nil == npcCfg then
    return
  end
  local name = npcCfg.name or ""
  local headIcon = ""
  local isHeadIconActive = false
  local desc = ""
  local rewardsList = {}
  local isDone = false
  local collectionInfoList = {}
  local npcContentId
  if self.worldMap then
    if self.worldMap.element_text_name then
      name = self.worldMap.element_text_name
    elseif npcCfg and npcCfg.name then
      name = npcCfg.name
    else
      name = ""
    end
    if self.worldMap.world_map_NPCicon_des then
      headIcon = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
      isHeadIconActive = true
    elseif npcCfg and npcCfg.world_map_NPCicon_des then
      headIcon = self:GetDesIconPath(npcCfg.world_map_NPCicon_des)
      isHeadIconActive = true
    else
      isHeadIconActive = false
    end
    if self.worldMap.dungeon_type_des then
      desc = self.worldMap.dungeon_type_des
    elseif npcCfg and npcCfg.dungeon_type_des then
      desc = npcCfg.dungeon_type_des
    else
      desc = ""
    end
    if self.extraInfo.dungeon_state == _G.ProtoEnum.DungeonState.DS_DONE then
      isDone = true
    else
      isDone = false
    end
    local dungeonConf = _G.DataConfigManager:GetDungeonConf(self.worldMap.dungeon_id)
    npcContentId = dungeonConf and dungeonConf.enemy_id and dungeonConf.enemy_id[1]
    local rewardsTable = {}
    for k, v in ipairs(dungeonConf.show_reward) do
      local rewards = _G.NRCCommonItemIconData()
      local bShowNum = false
      if v.reward_count and 0 ~= v.reward_count then
        bShowNum = true
      end
      rewards.itemType = v.reward_type
      rewards.itemId = v.reward_id
      rewards.itemNum = v.reward_count
      rewards.bShowNum = bShowNum
      rewards.bShowTip = true
      rewards.isDone = isDone
      rewards.isPreciousPetEgg = v.reward_type == _G.Enum.GoodsType.GT_BAGITEM and self:IsPreciousPetEgg(v.reward_id) or false
      table.insert(rewardsTable, rewards)
    end
    rewardsList = rewardsTable
    if dungeonConf.collection then
      for i, v in ipairs(dungeonConf.collection) do
        local collectionInfo = {}
        collectionInfo.collectType = v.collect_type
        collectionInfo.curNum = self:GetCollectionNumByType(v.collect_type)
        collectionInfo.needNum = #v.collect_content_id
        table.insert(collectionInfoList, collectionInfo)
      end
    end
  end
  self.WidgetLoader:SetWidgetClass(self.EctypeNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, name, desc, headIcon, isHeadIconActive, rewardsList, isDone, collectionInfoList, npcContentId)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:IsPreciousPetEgg(rewardId)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(rewardId)
  if bagItemConf and bagItemConf.item_behavior and #bagItemConf.item_behavior > 0 then
    for i = 1, #bagItemConf.item_behavior do
      if bagItemConf.item_behavior[i].use_action == _G.Enum.ItemBehavior.IB_PET_EGG_HATCH and #bagItemConf.item_behavior[i].ratio > 0 then
        for j = 1, #bagItemConf.item_behavior[i].ratio do
          local petEggConf = _G.DataConfigManager:GetPetEggConf(bagItemConf.item_behavior[i].ratio[j])
          if petEggConf and petEggConf.precious_egg_type and petEggConf.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
            return true
          end
        end
      end
    end
  end
  return false
end

function UMG_NpcInfo_C:GetCollectionNumByType(collecttionType)
  if self.extraInfo and self.extraInfo.collections then
    for i, v in ipairs(self.extraInfo.collections) do
      if v.collecttion_type == collecttionType then
        return v.collection_num
      end
    end
  end
  return 0
end

function UMG_NpcInfo_C:UpdatePanel4Info(npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local title = ""
  local node = ""
  title = self.worldMap.element_text_name
  local worldMapConf = _G.DataConfigManager:GetWorldMapConf(self.uiData.world_map_cfg_id)
  if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
    if #self.worldMap.npcicon_levelup > 0 then
      if worldMapConf and worldMapConf.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CAMP then
        node = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
      else
        for i = 1, #self.worldMap.npcicon_levelup do
          if self.worldMap.npcicon_levelup[i].level == npcInfo.npc_level then
            node = self:GetDesIconPath(self.worldMap.npcicon_levelup[i].icon)
          end
        end
      end
    else
      node = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
    end
  elseif worldMapConf and worldMapConf.map_tips_show_type == Enum.MapTipsShowType.MAP_TIPS_CAMP then
    node = self:GetDesIconPath("PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/WorldMapNpc/Frames/img_weijiesuo_png.img_weijiesuo_png'")
  else
    node = self:GetDesIconPath(self.worldMap.npcicon_lock)
  end
  self.WidgetLoader:SetWidgetClass(self.MagicClassRef)
  self.WidgetLoader:LoadPanelSync(self, true, title, node, npcInfo)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel5Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    name = "",
    desc = "",
    shouldActivateList = false,
    listContent = {},
    iconPath = ""
  }
  local npcCfg = _npcInfo.npcCfg
  if self.worldMap then
    if self.worldMap.element_text_name then
      props.name = self.worldMap.element_text_name
    elseif npcCfg and npcCfg.name then
      props.name = npcCfg.name
    else
      props.name = ""
    end
    if self.worldMap then
      props.desc = self.worldMap.worldmap_npc_des or ""
    elseif npcCfg then
      props.desc = npcCfg.worldmap_npc_des or ""
    end
    local isFinishTravel = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.IsFinishTravel)
    props.shouldActivateList = isFinishTravel
    props.listContent = LuaText.travel_reward_remind
    props.iconPath = self:GetTravelIconPath()
  end
  self.WidgetLoader:SetWidgetClass(self.CommonNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, 1, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:RefreshTeamBattleTimeText()
  if not self.extraInfo or not self.extraInfo.team_battle_info then
    return
  end
  local teamBattleInfo = self.extraInfo.team_battle_info
  local shouldShowTime = false
  local timeText = ""
  if not self.WidgetLoader:GetPanel() then
    return
  end
  if not self.WidgetLoader:GetPanel().RefreshTeamBattleTimeText then
    return
  end
  if teamBattleInfo.end_timestamp then
    local refreshTime = teamBattleInfo.end_timestamp - _G.ZoneServer:GetServerTime() / 1000
    local day = math.floor(refreshTime / 86400)
    local hour = math.floor((refreshTime - day * 86400) / 3600)
    local min = math.floor((refreshTime - day * 86400 - hour * 3600) / 60)
    local sec = math.floor(refreshTime % 60)
    local btnText = 0
    if day > 0 then
      btnText = string.format(LuaText.activity_RTS1, day, hour)
    elseif hour > 0 then
      btnText = string.format(LuaText.activity_RTS2, hour, min)
    else
      btnText = string.format(LuaText.magicmanual_challenge_countdown03, min, sec)
    end
    shouldShowTime = true
    timeText = btnText
  else
  end
  if self.WidgetLoader:GetPanel() and self.WidgetLoader:GetPanel().RefreshTeamBattleTimeText then
    self.WidgetLoader:GetPanel():RefreshTeamBattleTimeText(shouldShowTime, timeText)
  end
end

function UMG_NpcInfo_C:UpdatePanel6Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    isLimitedFlower = false,
    titleImagePath = "",
    title = "",
    moneyBtnText = "",
    shouldTextTime = false,
    timeText = "",
    costIconPath = "",
    costText = "",
    consumeText = "",
    consumeText1 = "",
    imageIconPath = "",
    petIconPath = "",
    petName = "",
    desc = "",
    starList = {},
    hasReward = false,
    rewardList = {},
    unit_type = {}
  }
  local teamBattleInfo = self.extraInfo.team_battle_info
  if not teamBattleInfo then
    return
  end
  local bLimitedFlower = NRCModuleManager:DoCmd(MagicManualModuleCmd.IsLimitedFlower, self.uiData.npc_refresh_id)
  if bLimitedFlower then
    props.isLimitedFlower = true
  end
  if self.worldMap.world_map_NPCicon_des then
    props.titleImagePath = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
  end
  if self.worldMap then
    props.title = self.worldMap.element_text_name or _G.LuaText.magicmanualmoduledata_2
  end
  local starNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local starMax = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StarMaxText = string.format("%s%s%s", starNum, "/", starMax.num)
  props.moneyBtnText = StarMaxText
  if teamBattleInfo.end_timestamp then
    local refreshTime = teamBattleInfo.end_timestamp - _G.ZoneServer:GetServerTime() / 1000
    local day = math.floor(refreshTime / 86400)
    local hour = math.floor((refreshTime - day * 86400) / 3600)
    local min = math.floor((refreshTime - day * 86400 - hour * 3600) / 60)
    local sec = math.floor(refreshTime % 60)
    local btnText = 0
    if day > 0 then
      btnText = string.format(LuaText.activity_RTS1, day, hour)
    elseif hour > 0 then
      btnText = string.format(LuaText.magicmanual_challenge_countdown01, hour, min)
    else
      btnText = string.format(LuaText.magicmanual_challenge_countdown03, min, sec)
    end
    props.shouldTextTime = true
    props.timeText = btnText
  else
  end
  local vItemConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
  local costText = string.format(_G.DataConfigManager:GetLocalizationConf("battle_star_cost").msg, vItemConf.displayName)
  local useStarNum = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_starlink", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  props.costIconPath = vItemConf.iconPath
  props.costText = costText
  props.consumeText = useStarNum
  props.consumeText1 = useStarNum
  local bloodConf = _G.DataConfigManager:GetPetBloodConf(teamBattleInfo.blood)
  props.imageIconPath = bloodConf.icon
  props.teamBattleInfo = teamBattleInfo
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(teamBattleInfo.battle_petbase_id)
  local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  props.petIconPath = modelConf.icon
  props.petName = petBaseConf.name
  props.desc = self.worldMap.worldmap_npc_des or ""
  props.unit_type = petBaseConf.unit_type
  local AwardList = _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.GetTeamBattleAwards, teamBattleInfo.star, teamBattleInfo.blood)
  local StarList = {}
  for i = 1, teamBattleInfo.star do
    table.insert(StarList, {hasStar = true})
  end
  props.starList = StarList
  props.star = teamBattleInfo.star
  local rewardsTable = {}
  local activity_objects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_FLOWER_APPEAR_HARD)
  for _, v in ipairs(activity_objects) do
    if v:IsInProgress() then
      local flower_group = _G.DataConfigManager:GetActivityFlowerAppearConf(v:GetSinglePartId()).flower_group
      for _, seed in ipairs(flower_group) do
        if seed.seed_id == teamBattleInfo.spec_flower_seed_id then
          local bGetReward = v:GetTaskState(seed.appear_task_id[1])
          local bGetMedal = v:GetTaskState(seed.appear_task_id[2])
          if not bGetMedal then
            local flowerTaskConf = _G.DataConfigManager:GetActivityFlowerTaskConf(seed.appear_task_id[2])
            local rewards = _G.NRCCommonItemIconData()
            rewards.itemType = flowerTaskConf.reward_type
            rewards.itemId = flowerTaskConf.reward_id
            rewards.itemNum = 1
            rewards.bShowTip = true
            rewards.tag = _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_MEDAL
            table.insert(rewardsTable, rewards)
          end
          if not bGetReward then
            local reward_id = _G.DataConfigManager:GetActivityFlowerTaskConf(seed.appear_task_id[1]).reward_id
            local rewardItem = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem
            for _, item in ipairs(rewardItem) do
              local rewards = _G.NRCCommonItemIconData()
              rewards.itemType = item.Type
              rewards.itemId = item.Id
              rewards.itemNum = item.Count
              rewards.bShowNum = true
              rewards.bShowTip = true
              rewards.tag = _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST
              table.insert(rewardsTable, rewards)
            end
          end
          goto lbl_376
        end
      end
    end
  end
  ::lbl_376::
  local dropReward = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetSpecificTimeActivityReward, ProtoEnum.ActivityDropShowArea.ADSA_FLOWER)
  if dropReward then
    for k, v in ipairs(dropReward) do
      table.insert(rewardsTable, v)
    end
  end
  if AwardList and #AwardList > 0 then
    for k, v in ipairs(AwardList) do
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = v.Type
      rewards.itemId = v.Id
      rewards.itemNum = v.Count
      if rewards.itemNum > 0 then
        rewards.bShowNum = true
      else
        rewards.bShowNum = false
      end
      rewards.bShowTip = true
      table.insert(rewardsTable, rewards)
    end
    props.hasReward = true
    props.rewardList = rewardsTable
  else
  end
  self.WidgetLoader:SetWidgetClass(self.TeamBattleClassRef)
  self.WidgetLoader:LoadPanelSync(self, 0, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel7Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    costIconPath = "",
    costText = "",
    starMaxText = "",
    title = "",
    desc = "",
    petBossImagePath = "",
    hasConsumeText = false,
    consumeText = "",
    consumeText1 = "",
    hasReward = false,
    rewardList = {},
    npcRefreshId = "",
    petBaseId = "",
    petIconPath = "",
    petName = "",
    unit_type = {}
  }
  local npcCfg = _npcInfo.npcCfg
  local starNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local starMax = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StarMaxText = string.format("%s%s%s", starNum, "/", starMax.num)
  local vItemConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
  local costText = string.format(_G.DataConfigManager:GetLocalizationConf("battle_star_cost").msg, vItemConf.displayName)
  props.costText = costText
  props.costIconPath = vItemConf.iconPath
  props.starMaxText = StarMaxText
  self:setActive(self.CampBG, false)
  if self.worldMap then
    props.title = self.worldMap.element_text_name or ""
    props.desc = self.worldMap.worldmap_npc_des or ""
  else
    props.title = self.worldMap.element_text_name or ""
    props.desc = self.worldMap.worldmap_npc_des or ""
  end
  props.petBossImagePath = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
  local worldCombatConf
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_COMBAT_CONF)
  local bossDatas = cfgTable:GetAllDatas()
  local starRewards
  for k, v in pairs(bossDatas) do
    if v.refresh_content_id and self.worldMap.npc_refresh_ids and #self.worldMap.npc_refresh_ids > 0 and v.refresh_content_id == self.worldMap.npc_refresh_ids[1] and v.trophy_id then
      starRewards = _G.DataConfigManager:GetStarAwardConf(v.trophy_id).show_award
      local useStarNum = _G.DataConfigManager:GetStarAwardConf(v.trophy_id).star_amount
      props.hasConsumeText = true
      props.npcRefreshId = v.refresh_content_id
      props.consumeText = useStarNum
      props.consumeText1 = useStarNum
      worldCombatConf = v
    end
  end
  local rewardsTable = {}
  local dropReward = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetSpecificTimeActivityReward, ProtoEnum.ActivityDropShowArea.ADSA_BOSS)
  if dropReward then
    for k, v in ipairs(dropReward) do
      table.insert(rewardsTable, v)
    end
  end
  if starRewards and #starRewards > 0 then
    for k, v in ipairs(starRewards) do
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = v.Type
      rewards.itemId = v.Id
      rewards.itemNum = v.Count
      if rewards.itemNum > 0 then
        rewards.bShowNum = true
      else
        rewards.bShowNum = false
      end
      rewards.bShowTip = true
      rewards = self:HandleBossEvoReward(rewards)
      if self:CheckThisRewardShouldShow(rewards) then
        table.insert(rewardsTable, rewards)
      end
    end
    props.hasReward = true
    props.rewardList = rewardsTable
  else
  end
  if worldCombatConf then
    local petBaseId = worldCombatConf.world_boss_refer
    props.petBaseId = petBaseId
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    props.petIconPath = modelConf.icon
    props.petName = petBaseConf.name
    props.unit_type = petBaseConf.unit_type
  end
  self.WidgetLoader:SetWidgetClass(self.TeamBattleClassRef)
  self.WidgetLoader:LoadPanelSync(self, 1, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:HandleBossEvoReward(RewardItem)
  local RetRewardItem = RewardItem
  if not RetRewardItem then
    Log.Error("UMG_NpcInfo_C:HandleBossEvoReward RewardItem is nil")
    return RetRewardItem
  end
  if RewardItem.itemId ~= nil and RewardItem.itemType and RewardItem.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(RewardItem.itemId)
    local BagItemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, RewardItem.itemId)
    if BagItemConf then
      local BagItemType = BagItemConf.type
      if BagItemType == _G.Enum.BagItemType.BI_BOSS_EVO and nil == BagItemData then
        RetRewardItem.topLabelText = LuaText.BossEvoItem_Title
      end
    end
  end
  return RetRewardItem
end

function UMG_NpcInfo_C:CheckThisRewardShouldShow(RewardItem)
  local bShow = true
  if not RewardItem then
    Log.Error("UMG_NpcInfo_C:CheckThisRewardShouldShow RewardItem is nil")
    return bShow
  end
  if RewardItem.itemId ~= nil and RewardItem.itemType and RewardItem.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(RewardItem.itemId)
    local BagItemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, RewardItem.itemId)
    if BagItemData and BagItemConf then
      local BagItemType = BagItemConf.type
      if BagItemType == _G.Enum.BagItemType.BI_BOSS_EVO and 0 ~= BagItemData.num then
        bShow = false
      end
    end
  end
  return bShow
end

function UMG_NpcInfo_C:UpdatePanel8Info(taskInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    name = "",
    desc = "",
    taskIconPath = "",
    shouldShowRewardList = false,
    rewardsList = {},
    awardCanvasVisibility = UE4.ESlateVisibility.Collapsed,
    TaskId = nil
  }
  local taskConf
  if taskInfo.TaskShowType == BigMapModuleEnum.TaskShowType.UNDO then
    local title = _G.DataConfigManager:GetLocalizationConf("task_unknown_title").msg
    local desc = _G.DataConfigManager:GetLocalizationConf("task_unknown_text").msg
    props.name = title
    props.desc = desc
    props.taskIconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
    if taskInfo.TaskConf then
      local TaskClass = taskInfo.TaskConf.task_class
      if TaskClass == Enum.TaskClassType.TCT_MAIN then
        props.taskIconPath = UEPath.TASK_ICON_MAIN_WENHAO
      elseif TaskClass == Enum.TaskClassType.TCT_SUB or TaskClass == Enum.TaskClassType.TCT_EVOLUTION or TaskClass == Enum.TaskClassType.TCT_CAMPAIGN then
        props.taskIconPath = UEPath.TASK_ICON_SUB_WENHAO
      elseif TaskClass == Enum.TaskClassType.TCT_DUNGEON or TaskClass == Enum.TaskClassType.TCT_JOURNEY then
        props.taskIconPath = UEPath.TASK_ICON_JOURNEY_WENHAO
      else
        props.taskIconPath = UEPath.TASK_ICON_WENHAO
      end
    end
    props.awardCanvasVisibility = UE4.ESlateVisibility.Collapsed
  elseif taskInfo.TaskShowType == BigMapModuleEnum.TaskShowType.TRACING then
    taskConf = taskInfo.TaskConf
  else
    taskConf = taskInfo.TaskConf
  end
  if taskConf then
    local name = taskConf.name
    local paragraphId = taskConf.paragraph_id
    if paragraphId then
      local paragraphConf = _G.DataConfigManager:GetParagraphConf(paragraphId)
      if paragraphConf then
        name = paragraphConf.title
      end
    end
    props.name = name
    props.desc = taskConf.task_des
    props.TaskId = taskConf.id
    local Reward = 0
    local ParagraphConf = _G.DataConfigManager:GetParagraphConf(taskConf.paragraph_id)
    if ParagraphConf.Reward and 0 ~= ParagraphConf.Reward then
      Reward = ParagraphConf.Reward
    elseif taskConf.Reward and 0 ~= taskConf.Reward then
      Reward = taskConf.Reward
    end
    if 0 == Reward or taskConf.task_class == Enum.TaskClassType.TCT_JOURNEY then
      props.awardCanvasVisibility = UE4.ESlateVisibility.Collapsed
    else
      props.awardCanvasVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
      local Rewards = _G.DataConfigManager:GetRewardConf(Reward).RewardItem
      local rewardsTable = {}
      for k, v in ipairs(Rewards) do
        local rewards = _G.NRCCommonItemIconData()
        rewards.itemType = v.Type
        rewards.itemId = v.Id
        rewards.itemNum = v.Count
        rewards.bShowNum = true
        rewards.bShowTip = true
        table.insert(rewardsTable, rewards)
      end
      props.rewardsList = rewardsTable
      props.shouldShowRewardList = true
    end
    if taskConf.task_class == Enum.TaskClassType.TCT_MAIN then
      props.taskIconPath = UEPath.TASK_TITLE_ZHUXIAN
    elseif taskConf.task_class == Enum.TaskClassType.TCT_SUB then
      props.taskIconPath = UEPath.TASK_TITLE_ZHIXIAN
    elseif taskConf.task_class == Enum.TaskClassType.TCT_JOURNEY then
      props.taskIconPath = UEPath.TASK_TITLE_SHILIAN
    elseif taskInfo.SpecialTaskType and taskInfo.SpecialTaskType == "TreasureDig" then
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(self.uiData.world_map_cfg_id)
      if worldMapConf and worldMapConf.world_map_NPCicon_des then
        props.taskIconPath = worldMapConf.world_map_NPCicon_des
      else
        props.taskIconPath = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/WorldMapNpc/Frames/TipDes_cangbaotu_png.TipDes_cangbaotu_png'"
      end
      self.btnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:SetBtnState(taskConf)
  else
  end
  self.NpcInfo = taskInfo
  self.WidgetLoader:SetWidgetClass(self.TaskNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:SetBtnState(TaskConf)
  local IsVisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local CanVisitTrace = true
  if IsVisitState and TaskConf then
    if TaskConf.peer_available then
      CanVisitTrace = true
    elseif _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      CanVisitTrace = true
    else
      CanVisitTrace = false
    end
  end
  if not CanVisitTrace then
    self.Btn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_NpcInfo_C:UpdatePanel9Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    petBossIconPath = "",
    title = "",
    desc = "",
    shouldShowTimeText = false,
    npcRefreshId = _npcInfo.npc_refresh_id,
    timeText = "",
    isConsumeTextRed = false,
    colorEnough = "#272727FF",
    colorRed = "#AF3A3DFF",
    consumeText = "",
    consumeText1 = "",
    costIconPath = "",
    costIcon1Path = "",
    costText = "",
    rewardList = {}
  }
  if self.worldMap.element_text_name then
    props.title = self.worldMap.element_text_name
  end
  if self.worldMap.worldmap_npc_des then
    props.desc = self.worldMap.worldmap_npc_des
  end
  props.petBossIconPath = self:GetDesIconPath(self.worldMap.world_map_NPCicon_des)
  local text = ""
  local tip = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_14").msg
  local tipNumString = ""
  if self.extraInfo.available_challenge_num_via_star then
    if self.extraInfo.available_challenge_num_via_star < 1 then
      tipNumString = "<red>" .. tostring(self.extraInfo.available_challenge_num_via_star) .. "</>"
    else
      tipNumString = tostring(self.extraInfo.available_challenge_num_via_star)
    end
    text = string.format(tip, tipNumString, self.extraInfo.available_challenge_num_via_star_max)
    props.shouldShowTimeText = true
    props.timeText = text
  else
  end
  local starConsume = _G.DataConfigManager:GetLegendaryGlobalConfig("star_consume").num
  local ticketId, ticketConsume = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, _npcInfo.npc_refresh_id)
  local ticketNum = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, ticketId)
  local colorEnough = props.colorEnough
  local colorRed = props.colorRed
  if nil == ticketNum then
    ticketNum = 0
  else
    ticketNum = ticketNum.num
  end
  if ticketConsume > ticketNum then
    props.isConsumeTextRed = true
  else
  end
  props.consumeText = starConsume
  props.consumeText1 = ticketConsume
  local vItemConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
  props.costIconPath = vItemConf.iconPath
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(ticketId)
  local costText = _G.DataConfigManager:GetLocalizationConf("team_battle_text_4").msg
  props.costIcon1Path = bagItemConf.icon
  props.costText = costText
  local petBaseId = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryBattlePetBaseID, _npcInfo.npc_refresh_id)
  local RewardList = {}
  local star = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryBattleStar, _npcInfo.npc_refresh_id)
  if star then
    local rewards = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryBattleAwards, star, petBaseId)
    for _, j in ipairs(rewards or {}) do
      table.insert(RewardList, {
        itemId = j.Id,
        itemType = j.Type,
        itemCount = j.Count
      })
    end
  end
  local rewardsTable = {}
  local dropReward = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetSpecificTimeActivityReward, ProtoEnum.ActivityDropShowArea.ADSA_LEGENDARY)
  if dropReward then
    for k, v in ipairs(dropReward) do
      table.insert(rewardsTable, v)
    end
  end
  for k, v in ipairs(RewardList) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.itemType
    rewards.itemId = v.itemId
    rewards.itemNum = v.itemCount
    if rewards.itemNum > 0 then
      rewards.bShowNum = true
    else
      rewards.bShowNum = false
    end
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  props.rewardList = rewardsTable
  self.WidgetLoader:SetWidgetClass(self.TeamBattleClassRef)
  self.WidgetLoader:LoadPanelSync(self, 2, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel10Info()
  local headIcon = ""
  local showData = {}
  local title = ""
  local pikaActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PIKA)
  if pikaActivityInst and #pikaActivityInst > 0 then
    local leftTime = pikaActivityInst[1]:GetActivityTimeLeft()
    title = pikaActivityInst[1]:GetActivityPromptText()
    local subItemIds = pikaActivityInst[1]:GetPartIds()
    local activityPikaConf = _G.DataConfigManager:GetActivityPikaConf(subItemIds[1])
    if self.pikaActivityList == nil then
      self.pikaActivityList = {}
    end
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      for k, v in ipairs(activityPikaConf.kv_path) do
        if v.gender == player.gender then
          for key, pkgId in ipairs(v.package_id1) do
            local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(pkgId, true)
            if fashionPackageConf and player.gender == fashionPackageConf.gender then
              table.insert(showData, {
                leftTime = leftTime,
                kvBg = fashionPackageConf.kv_map
              })
            end
          end
        end
      end
    end
  end
  if self.module.data:GetNpcTipShowType() ~= _G.Enum.MapTipsShowType.MAP_TIPS_PIKA then
    self.WidgetLoader:UnLoadPanel(true)
  end
  headIcon = self:GetDesIconPath(self.worldMap.npcicon_unlock)
  self.WidgetLoader:SetWidgetClass(self.FashionMallClassRef)
  self.WidgetLoader:LoadPanelSync(self, title, self.worldMap.element_text_name, self.worldMap.worldmap_npc_des, headIcon, showData)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:GetStoreListRsp(_rsp)
  if self.isDestruct then
    return
  end
  local totalConsume = ""
  local nextRewardRemaining = ""
  local costIconPath = ""
  local hasReward = false
  local itemList
  local hasNextLevelReward = true
  local numText = ""
  if _rsp.shop_data == nil then
    Log.Warning("UMG_NpcInfo_C:GetStoreListRsp _rsp.shop_data is nil")
    self.WidgetLoader:GetPanel():ShowDefault()
    self:OnPanelShow(true)
    return
  end
  if nil == _rsp.shop_data.goods_data then
    Log.Warning("UMG_NpcInfo_C:GetStoreListRsp _rsp.shop_data.goods_data is nil")
    self.WidgetLoader:GetPanel():ShowDefault()
    self:OnPanelShow(true)
    return
  end
  self.ShopID = _rsp.shop_data.id
  if 0 == _rsp.ret_info.ret_code then
    if _rsp.shop_data.consume_info and _rsp.shop_data.consume_info.total_consume_num and _rsp.shop_data.consume_info.total_consume_num > 0 then
      local shopData = _rsp.shop_data
      local totalConsumptionConf = _G.DataConfigManager:GetShopTotalConsumptionConf(shopData.id)
      local totalConsumeNum = shopData.consume_info.total_consume_num
      local iconPath, name = NPCShopUtils:GetGoodsCurrencyIconByType(totalConsumptionConf.price_goods_type, totalConsumptionConf.price_goods_id)
      numText = name
      costIconPath = iconPath
      totalConsume = NPCShopUtils:GetGoodsCurrencyNumByType(totalConsumptionConf.price_goods_type, totalConsumptionConf.price_goods_id)
      local nextAwardLevel = 1
      local hasRewardCanTake = false
      if shopData.consume_info.reward_taken_info then
        for i = 1, #shopData.consume_info.reward_taken_info do
          if shopData.consume_info.reward_taken_info[i].is_reward_taken == false then
            hasRewardCanTake = true
            hasReward = true
            nextAwardLevel = shopData.consume_info.reward_taken_info[i].level
            break
          end
        end
        if not hasRewardCanTake then
          nextAwardLevel = #shopData.consume_info.reward_taken_info + 1
        end
      end
      if nextAwardLevel <= #totalConsumptionConf.shop_consumption_reward then
        local totalConsumptionRewardList = {}
        local nextAwardNum = totalConsumptionConf.shop_consumption_reward[nextAwardLevel].total_consumption_num
        local text = string.format("%s/%s", totalConsumeNum, nextAwardNum)
        nextRewardRemaining = text
        for i = 1, #totalConsumptionConf.shop_consumption_reward do
          local rewardId = totalConsumptionConf.shop_consumption_reward[i].reward_id
          local rewardList = _G.DataConfigManager:GetRewardConf(rewardId).RewardItem
          local rewardItemList = self:SetRewardList(rewardList)
          for k, v in ipairs(rewardItemList) do
            local isItemExists = false
            for j = 1, #totalConsumptionRewardList do
              if totalConsumptionRewardList[j].itemId == v.itemId then
                isItemExists = true
                break
              end
            end
            if not isItemExists then
              table.insert(totalConsumptionRewardList, v)
            end
          end
        end
        local shopList = shopData.goods_data
        local shopItemList = self:SetShopList(shopList)
        self:AddMarkerForShopList(shopItemList)
        local showItemList = table.copy(shopItemList)
        showItemList = self:GetShowItemList(totalConsumptionRewardList, showItemList)
        showItemList = self:SortShowItemList(showItemList)
        itemList = showItemList
      else
        local totalConsumptionRewardList = {}
        hasNextLevelReward = false
        for i = 1, #totalConsumptionConf.shop_consumption_reward do
          local rewardId = totalConsumptionConf.shop_consumption_reward[i].reward_id
          local rewardList = _G.DataConfigManager:GetRewardConf(rewardId).RewardItem
          local rewardItemList = self:SetRewardList(rewardList)
          for k, v in ipairs(rewardItemList) do
            local isItemExists = false
            for j = 1, #totalConsumptionRewardList do
              if totalConsumptionRewardList[j].itemId == v.itemId then
                isItemExists = true
                break
              end
            end
            if not isItemExists then
              table.insert(totalConsumptionRewardList, v)
            end
          end
        end
        local shopList = shopData.goods_data
        local shopItemList = self:SetShopList(shopList)
        self:AddMarkerForShopList(shopItemList)
        local showItemList = table.copy(shopItemList)
        showItemList = self:GetShowItemList(totalConsumptionRewardList, showItemList)
        showItemList = self:SortShowItemList(showItemList)
        itemList = showItemList
      end
    else
      local shopData = _rsp.shop_data
      local shopConf = _G.DataConfigManager:GetShopConf(_rsp.shop_data.id)
      if shopConf.is_cumulative then
        local totalConsumptionRewardList = {}
        local totalConsumptionConf = _G.DataConfigManager:GetShopTotalConsumptionConf(shopData.id)
        local sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNumByType(totalConsumptionConf.price_goods_type, totalConsumptionConf.price_goods_id)
        local iconPath, displayName = NPCShopUtils:GetGoodsCurrencyIconByType(totalConsumptionConf.price_goods_type, totalConsumptionConf.price_goods_id)
        numText = displayName
        costIconPath = iconPath
        if not sumMoneyNum then
          totalConsume = "0"
        else
          totalConsume = sumMoneyNum
        end
        local text = string.format("%s/%s", 0, totalConsumptionConf.shop_consumption_reward[1].total_consumption_num)
        nextRewardRemaining = text
        for i = 1, #totalConsumptionConf.shop_consumption_reward do
          local rewardId = totalConsumptionConf.shop_consumption_reward[i].reward_id
          local rewardList = _G.DataConfigManager:GetRewardConf(rewardId).RewardItem
          local rewardItemList = self:SetRewardList(rewardList)
          for k, v in ipairs(rewardItemList) do
            local isItemExists = false
            for j = 1, #totalConsumptionRewardList do
              if totalConsumptionRewardList[j].itemId == v.itemId then
                isItemExists = true
                break
              end
            end
            if not isItemExists then
              table.insert(totalConsumptionRewardList, v)
            end
          end
        end
        local shopList = shopData.goods_data
        local rewardItemList = totalConsumptionRewardList
        local shopItemList = self:SetShopList(shopList)
        self:AddMarkerForShopList(shopItemList)
        local showItemList = table.copy(shopItemList)
        showItemList = self:GetShowItemList(rewardItemList, showItemList)
        showItemList = self:SortShowItemList(showItemList)
        itemList = showItemList
      else
        local ShopData = _rsp.shop_data
        local shopList = ShopData.goods_data
        local shopItemList = self:SetShopList(shopList)
        shopItemList = self:SortShowItemList(shopItemList)
        itemList = shopItemList
        self:AddMarkerForShopList(itemList)
      end
    end
  else
    local shopData = _rsp.shop_data
    if shopData and shopData.id then
      local shopConf = _G.DataConfigManager:GetShopConf(_rsp.shop_data.id)
      if shopConf and shopConf.shop_type == _G.Enum.ShopType.ST_RANDOM_SHOP then
        Log.Info("UMG_NpcInfo_C random shop return")
        return
      end
    end
  end
  if self.WidgetLoader:GetPanel() and self.WidgetLoader:GetPanel().UpdateAsyncResource then
    self.WidgetLoader:GetPanel():UpdateAsyncResource(totalConsume, nextRewardRemaining, costIconPath, hasReward, itemList, numText, hasNextLevelReward)
  end
  if self.WidgetLoader:GetPanel() and self.WidgetLoader:GetPanel().UpdatePanelInfo then
    self.WidgetLoader:GetPanel():UpdatePanelInfo(_rsp)
  else
    self.module.data:SetShopData(_rsp)
    Log.Info("UMG_NpcInfo_C:GetStoreListRsp self.WidgetLoader:GetPanel() is nil")
  end
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:OnZoneGetPlayerCardInfoRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdUpdateCardInfo, _rsp)
  end
end

function UMG_NpcInfo_C:AddMarkerForShopList(list)
  for i = 1, #list do
    local item = list[i]
    if item.itemType == Enum.GoodsType.GT_BAGITEM then
      item.bShowAdditional = true
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(item.itemId)
      if 1 == bagItemConf.is_auto_use then
        local rewardId = bagItemConf.item_behavior[1].ratio[1]
        if rewardId then
          if bagItemConf.type == Enum.BagItemType.BI_MUSIC then
            local MusicList = _G.DataModelMgr.PlayerDataModel:GetPlayerMusicInfo()
            if MusicList and MusicList.music_id_list then
              local hasItem = false
              for j, v in pairs(MusicList.music_id_list) do
                if rewardId == v then
                  hasItem = true
                  break
                end
              end
              if hasItem then
                if 0 ~= item.limit_buy_num then
                  if item.limit_buy_num > item.buy_num then
                    local canBuyCount = item.limit_buy_num - item.buy_num
                    item.topLabelText = "\233\153\144\233\135\143"
                    item.bShowNum = true
                    item.itemNum = canBuyCount
                  else
                    item.topLabelText = "\229\148\174\231\189\132"
                  end
                end
              else
                item.topLabelText = "\230\156\170\232\142\183\229\190\151"
              end
            else
              item.topLabelText = "\230\156\170\232\142\183\229\190\151"
            end
          else
            local rewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
            local rewardItem = rewardConf.RewardItem[1]
            if rewardItem and rewardItem.Type == Enum.GoodsType.GT_RP_BEHAVIOR then
              local putPropsItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, RolePlayModuleDef.RolePlayType.PutProp)
              local behaviorItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, RolePlayModuleDef.RolePlayType.Action)
              local hasItem = false
              for j = 1, #putPropsItems do
                if putPropsItems[j].value == rewardItem.Id then
                  hasItem = true
                  break
                end
              end
              for k = 1, #behaviorItems do
                if behaviorItems[k].value == rewardItem.Id then
                  hasItem = true
                  break
                end
              end
              if hasItem then
                if 0 ~= item.limit_buy_num then
                  if item.limit_buy_num > item.buy_num then
                    local canBuyCount = item.limit_buy_num - item.buy_num
                    item.topLabelText = "\233\153\144\233\135\143"
                    item.bShowNum = true
                    item.itemNum = canBuyCount
                  else
                    item.topLabelText = "\229\148\174\231\189\132"
                  end
                end
              else
                item.topLabelText = "\230\156\170\232\142\183\229\190\151"
              end
            elseif rewardItem and rewardItem.Type == Enum.GoodsType.GT_CARD_SKIN then
              local hasItem = false
              local skinList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetSkinList)
              for j = 1, #skinList do
                if 0 ~= skinList[j].card_item_get_timestamp and skinList[j].card_item_id == rewardItem.Id then
                  hasItem = true
                  break
                end
              end
              if hasItem then
                if 0 ~= item.limit_buy_num then
                  if item.limit_buy_num > item.buy_num then
                    local canBuyCount = item.limit_buy_num - item.buy_num
                    item.topLabelText = "\233\153\144\233\135\143"
                    item.bShowNum = true
                    item.itemNum = canBuyCount
                  else
                    item.topLabelText = "\229\148\174\231\189\132"
                  end
                end
              else
                item.topLabelText = "\230\156\170\232\142\183\229\190\151"
              end
            elseif rewardItem and rewardItem.Type == Enum.GoodsType.GT_CARD_LABEL then
              local hasItem = false
              local OwnedLabelList = _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdGetOwnedLabel)
              for j = 1, #OwnedLabelList do
                if OwnedLabelList[j].card_item_id == rewardItem.Id then
                  hasItem = true
                  break
                end
              end
              if hasItem then
                if 0 ~= item.limit_buy_num then
                  if item.limit_buy_num > item.buy_num then
                    local canBuyCount = item.limit_buy_num - item.buy_num
                    item.topLabelText = "\233\153\144\233\135\143"
                    item.bShowNum = true
                    item.itemNum = canBuyCount
                  else
                    item.topLabelText = "\229\148\174\231\189\132"
                  end
                end
              else
                item.topLabelText = "\230\156\170\232\142\183\229\190\151"
              end
            elseif rewardItem and rewardItem.Type == Enum.GoodsType.GT_SHARE_FORM then
              item.topLabelText = "\230\156\170\232\142\183\229\190\151"
              item.cardId = rewardItem.Id
              local req = ProtoMessage:newZoneGetShareFormInfoReq()
              req.pet_id = _G.DataConfigManager:GetPetShareItemConf(rewardItem.Id).allowed_petbase
              _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_SHARE_FORM_INFO_REQ, req, self, self.GetCardUnlockState, false, true)
            end
          end
        end
      elseif 0 ~= item.limit_buy_num then
        if item.limit_buy_num > item.buy_num then
          local canBuyCount = item.limit_buy_num - item.buy_num
          item.topLabelText = "\233\153\144\233\135\143"
          item.bShowNum = true
          item.itemNum = canBuyCount
        else
          item.topLabelText = "\229\148\174\231\189\132"
        end
      else
        item.topLabelText = "\228\184\141\233\153\144\233\135\143"
      end
    elseif item.itemType == Enum.GoodsType.GT_FASHION then
      item.bShowAdditional = true
      local hasItem = false
      local rolePlayItems = _G.DataModelMgr.PlayerDataModel:GetPlayerOwnedFashion()
      if rolePlayItems then
        for k = 1, #rolePlayItems do
          if rolePlayItems[k].item_id == item.itemId then
            hasItem = true
            break
          end
        end
        if hasItem then
          if 0 ~= item.limit_buy_num then
            if item.limit_buy_num > item.buy_num then
              local canBuyCount = item.limit_buy_num - item.buy_num
              item.topLabelText = "\233\153\144\233\135\143"
              item.bShowNum = true
              item.itemNum = canBuyCount
            else
              item.topLabelText = "\229\148\174\231\189\132"
            end
          else
            item.topLabelText = "\228\184\141\233\153\144\233\135\143"
          end
        else
          item.topLabelText = "\230\156\170\232\142\183\229\190\151"
        end
      else
        item.topLabelText = "\230\156\170\232\142\183\229\190\151"
      end
    elseif item.itemType == Enum.GoodsType.GT_FASHION_SUITS then
      local hasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, item.itemId)
      if hasSuit then
        item.topLabelText = LuaText.tailor_owned_btn
      else
        item.topLabelText = LuaText.map_shop_item_marker_text4
      end
    end
  end
end

function UMG_NpcInfo_C:GetCardUnlockState(rsp)
  if 0 == rsp.ret_info.ret_code and self.WidgetLoader:GetPanel() and self.WidgetLoader:GetPanel().UpdateCardItem then
    self.WidgetLoader:GetPanel():UpdateCardItem(rsp.share_form_item)
  end
end

function UMG_NpcInfo_C:UpdatePanel12Info(_npcInfo)
  local npcCfg = _npcInfo.npcCfg
  if self.worldMap then
    if self.worldMap.element_text_name then
      self.npcName:SetText(self.worldMap.element_text_name)
    elseif npcCfg and npcCfg.name then
      self.npcName:SetText(npcCfg.name)
    else
      self.npcName:SetText("")
    end
    if self.worldMap then
      self.npcDesc:SetText(self.worldMap.worldmap_npc_des or "")
    elseif npcCfg then
      self.npcDesc:SetText(npcCfg.worldmap_npc_des or "")
    end
    if not (self.worldMap.map_show_type == Enum.MapIconShowType.MAP_CREATE_MAGIC or self.worldMap.map_func_icon_group) or 0 == self.worldMap.map_func_icon_group then
      self.HeadIconSwitcher:SetActiveWidgetIndex(1)
      SetHeadIconFunc(self, self.Node_4)
    elseif self.worldMap.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCROLE then
      self.HeadIconSwitcher:SetActiveWidgetIndex(1)
      SetHeadIconFunc(self, self.Node_4)
    else
      self.HeadIconSwitcher:SetActiveWidgetIndex(0)
      SetHeadIconFunc(self, self.headIcon)
    end
  end
  self:OnPanelShow(true)
  self.CycleChallenge:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if not self.worldMap then
    return
  end
  if self.worldMap.dungeon_id > 0 then
    local BossChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_BOSS_CHALLENGE_EVENT)
    if BossChallengeEventActivityObject and BossChallengeEventActivityObject[1] then
      BossChallengeEventActivityObject[1]:BindActivityTimeLeft(self.Text_Time_2)
      local bossChallengeData = BossChallengeEventActivityObject[1]:GetBossChallengeData()
      if bossChallengeData and bossChallengeData.event_id > 0 then
        local bossChallengeEventConf = _G.DataConfigManager:GetBossChallengeEventConf(bossChallengeData.event_id)
        self.NRCText_Title:SetText(_G.DataConfigManager:GetLocalizationConf("challenge_title_2").msg)
        self.CycleChallenge_Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/img_jiaodou_png.img_jiaodou_png'")
        local curSchedule = MagicManualUtils.GetFinishBossChallengeEventSchedule(bossChallengeData, false)
        local curStar = MagicManualUtils.GetFinishBossChallengeEventSchedule(bossChallengeData, true)
        local totalSchedule = MagicManualUtils.GetBossChallengeEventSchedule(bossChallengeEventConf)
        local totalStar = MagicManualUtils.GetNPCChallengeEventStarNum(bossChallengeEventConf)
        local scheduleText = string.format("%d/%d", curSchedule, totalSchedule)
        self.TextSchedule:SetText(scheduleText)
        local starText = string.format("%d/%d", curStar, totalStar)
        self.TextStarNumber:SetText(starText)
        local displayItems = {}
        if bossChallengeEventConf and bossChallengeEventConf.show_reward and table.len(bossChallengeEventConf.show_reward) > 0 then
          for _, reward in ipairs(bossChallengeEventConf.show_reward) do
            local displayItem = _G.NRCCommonItemIconData()
            displayItem.itemType = reward.item_type
            displayItem.itemId = reward.item_id
            displayItem.itemNum = reward.item_count
            displayItem.bShowNum = true
            displayItem.bShowTip = true
            table.insert(displayItems, displayItem)
          end
        end
        self.TaskAwardList_1:InitGridView(displayItems)
      end
    end
  else
    local NPCChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT)
    if NPCChallengeEventActivityObject and NPCChallengeEventActivityObject[1] then
      NPCChallengeEventActivityObject[1]:BindActivityTimeLeft(self.Text_Time_2)
      local npcChallengeData = NPCChallengeEventActivityObject[1]:GetNpcChallengeData()
      if npcChallengeData and npcChallengeData.event_id > 0 then
        local npcChallengeEventConf = _G.DataConfigManager:GetNpcChallengeEventConf(npcChallengeData.event_id)
        self.NRCText_Title:SetText(_G.DataConfigManager:GetLocalizationConf("worldmap_tips_vs_text").msg)
        self.CycleChallenge_Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/img_duizhan_png.img_duizhan_png'")
        local curSchedule = MagicManualUtils.GetFinishNPCChallengeEventSchedule(npcChallengeData, false)
        local curStar = MagicManualUtils.GetFinishNPCChallengeEventSchedule(npcChallengeData, true)
        local totalSchedule = MagicManualUtils.GetNPCChallengeEventSchedule(npcChallengeEventConf)
        local totalStar = MagicManualUtils.GetNPCChallengeEventStarNum(npcChallengeEventConf)
        local scheduleText = string.format("%s/%s", curSchedule, totalSchedule)
        self.TextSchedule:SetText(scheduleText)
        local starText = string.format("%s/%s", curStar, totalStar)
        self.TextStarNumber:SetText(starText)
        local displayItems = {}
        if npcChallengeEventConf and npcChallengeEventConf.show_reward and table.len(npcChallengeEventConf.show_reward) > 0 then
          for _, reward in ipairs(npcChallengeEventConf.show_reward) do
            local displayItem = _G.NRCCommonItemIconData()
            displayItem.itemType = reward.item_type
            displayItem.itemId = reward.item_id
            displayItem.itemNum = reward.item_count
            displayItem.bShowNum = true
            displayItem.bShowTip = true
            table.insert(displayItems, displayItem)
          end
        end
        self.TaskAwardList_1:InitGridView(displayItems)
      end
    end
  end
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel13Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    name = "",
    desc = "",
    headIconIndex = 0,
    isHeadIcon = false,
    headIconPath = "",
    subtitle = "",
    cycleChallengeIconPath = "",
    scheduleText = nil,
    starNumberText = "",
    displayItems = {}
  }
  local npcCfg = _npcInfo.npcCfg
  if self.worldMap then
    if self.worldMap.element_text_name then
      props.name = self.worldMap.element_text_name
    elseif npcCfg and npcCfg.name then
      props.name = npcCfg.name
    end
    if self.worldMap then
      props.desc = self.worldMap.worldmap_npc_des or ""
    elseif npcCfg then
      props.desc = npcCfg.worldmap_npc_des or ""
    end
    if not (self.worldMap.map_show_type == Enum.MapIconShowType.MAP_CREATE_MAGIC or self.worldMap.map_func_icon_group) or 0 == self.worldMap.map_func_icon_group then
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = false
      props.headIconIndex = 1
    elseif self.worldMap.map_func_icon_group == Enum.MapFuncIconGroup.MFIG_NPCROLE then
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = false
      props.headIconIndex = 1
    else
      props.headIconPath = SetHeadIconFunc(self)
      props.isHeadIcon = true
      props.headIconIndex = 0
    end
  end
  self.WidgetLoader:SetWidgetClass(self.CommonNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, 2, props)
  if not self.WidgetLoader:GetPanel() then
    return
  end
  if not self.worldMap then
    return
  end
  if self.worldMap.dungeon_id > 0 then
    local BossChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_BOSS_CHALLENGE_EVENT)
    if BossChallengeEventActivityObject and BossChallengeEventActivityObject[1] then
      BossChallengeEventActivityObject[1]:BindActivityTimeLeft(self.WidgetLoader:GetPanel().Text_Time_2)
      local bossChallengeData = BossChallengeEventActivityObject[1]:GetBossChallengeData()
      if bossChallengeData and bossChallengeData.event_id > 0 then
        local bossChallengeEventConf = _G.DataConfigManager:GetBossChallengeEventConf(bossChallengeData.event_id)
        local curSchedule = MagicManualUtils.GetFinishBossChallengeEventSchedule(bossChallengeData, false)
        local curStar = MagicManualUtils.GetFinishBossChallengeEventSchedule(bossChallengeData, true)
        local totalSchedule = MagicManualUtils.GetBossChallengeEventSchedule(bossChallengeEventConf)
        local totalStar = MagicManualUtils.GetNPCChallengeEventStarNum(bossChallengeEventConf)
        local scheduleText = string.format("%d/%d", curSchedule, totalSchedule)
        local starText = string.format("%d/%d", curStar, totalStar)
        local displayItems = {}
        if bossChallengeEventConf and bossChallengeEventConf.show_reward and table.len(bossChallengeEventConf.show_reward) > 0 then
          for _, reward in ipairs(bossChallengeEventConf.show_reward) do
            local displayItem = _G.NRCCommonItemIconData()
            displayItem.itemType = reward.item_type
            displayItem.itemId = reward.item_id
            displayItem.itemNum = reward.item_count
            displayItem.bShowNum = true
            displayItem.bShowTip = true
            table.insert(displayItems, displayItem)
          end
        end
        props.subtitle = _G.LuaText.challenge_title_2
        props.cycleChallengeIconPath = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/img_jiaodou_png.img_jiaodou_png'"
        props.scheduleText = scheduleText
        props.starNumberText = starText
        props.displayItems = displayItems
      end
    end
  elseif self.worldMap.id == 700002 then
    local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
    if WeeklyChallengeEventActivityObject and WeeklyChallengeEventActivityObject[1] then
      WeeklyChallengeEventActivityObject[1]:BindActivityTimeLeft(self.WidgetLoader:GetPanel().Text_Time_2)
      local weeklyChallengeData = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
      if weeklyChallengeData then
        local curStar = weeklyChallengeData.challenge_info.highest_cheer_point or 0
        local totalStar = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeEventStarNum()
        local starText = string.format("%s/%s", curStar, totalStar)
        local displayItems = {}
        if weeklyChallengeData and weeklyChallengeData.event_id and weeklyChallengeData.event_id > 0 then
          local weeklyChallengeEventConf = _G.DataConfigManager:GetWeeklyChallengeEventConf(weeklyChallengeData.event_id)
          if weeklyChallengeEventConf and weeklyChallengeEventConf.show_reward and table.len(weeklyChallengeEventConf.show_reward) > 0 then
            for _, reward in ipairs(weeklyChallengeEventConf.show_reward) do
              local displayItem = _G.NRCCommonItemIconData()
              displayItem.itemType = reward.item_type
              displayItem.itemId = reward.item_id
              displayItem.itemNum = reward.item_count
              displayItem.bShowNum = true
              displayItem.bShowTip = true
              table.insert(displayItems, displayItem)
            end
          end
        end
        props.subtitle = _G.LuaText.weekly_challenge_topic_1
        props.cycleChallengeIconPath = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/img_StarlightShowdown_png.img_StarlightShowdown_png'"
        props.starNumberText = starText
        props.displayItems = displayItems
        props.starText = _G.LuaText.weekly_challenge_text_20
        props.starIcon = "PaperSprite'/Game/NewRoco/Modules/System/WeeklyChallengeBattle/Raw/Frames/img_CheerIcon1_png.img_CheerIcon1_png'"
      end
    end
  else
    local NPCChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT)
    if NPCChallengeEventActivityObject and NPCChallengeEventActivityObject[1] then
      NPCChallengeEventActivityObject[1]:BindActivityTimeLeft(self.WidgetLoader:GetPanel().Text_Time_2)
      local npcChallengeData = NPCChallengeEventActivityObject[1]:GetNpcChallengeData()
      if npcChallengeData and npcChallengeData.event_id > 0 then
        local npcChallengeEventConf = _G.DataConfigManager:GetNpcChallengeEventConf(npcChallengeData.event_id)
        local curSchedule = MagicManualUtils.GetFinishNPCChallengeEventSchedule(npcChallengeData, false)
        local curStar = MagicManualUtils.GetFinishNPCChallengeEventSchedule(npcChallengeData, true)
        local totalSchedule = MagicManualUtils.GetNPCChallengeEventSchedule(npcChallengeEventConf)
        local totalStar = MagicManualUtils.GetNPCChallengeEventStarNum(npcChallengeEventConf)
        local scheduleText = string.format("%s/%s", curSchedule, totalSchedule)
        local starText = string.format("%s/%s", curStar, totalStar)
        local displayItems = {}
        if npcChallengeEventConf and npcChallengeEventConf.show_reward and table.len(npcChallengeEventConf.show_reward) > 0 then
          for _, reward in ipairs(npcChallengeEventConf.show_reward) do
            local displayItem = _G.NRCCommonItemIconData()
            displayItem.itemType = reward.item_type
            displayItem.itemId = reward.item_id
            displayItem.itemNum = reward.item_count
            displayItem.bShowNum = true
            displayItem.bShowTip = true
            table.insert(displayItems, displayItem)
          end
        end
        props.subtitle = _G.LuaText.weekly_challenge_topic_1
        props.cycleChallengeIconPath = "PaperSprite'/Game/NewRoco/Modules/System/BigMap/Raw/Atlas/BigMap/Frames/img_duizhan_png.img_duizhan_png'"
        props.scheduleText = scheduleText
        props.starNumberText = starText
        props.displayItems = displayItems
      end
    end
  end
  self.WidgetLoader:LoadPanelSync(self, 2, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel14Info(_visitorInfo)
  self.Btn2:SetBtnText(LuaText.online_number_map_tips_btn_text)
  self.WidgetLoader:UnLoadPanel(true)
  if not _visitorInfo then
    Log.Error("UMG_NpcInfo:UpdatePanel14Info Error! _visitorInfo is nil")
    return
  end
  local title = ""
  local desc = ""
  local icon = ""
  local visitorTip = ""
  if _visitorInfo.visitorInfo.scene_res_id and not BigMapUtils.IsBigWorldMap(_visitorInfo.visitorInfo.scene_res_id) then
    visitorTip = DataConfigManager:GetLocalizationConf("online_number_map_tips_text").msg
  end
  if not string.IsNilOrEmpty(visitorTip) then
    self.StudyTourTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.StudyTourTime:SetText(visitorTip)
    self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.StudyTourTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_72:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.worldMap then
    desc = self.worldMap.worldmap_npc_des or ""
  end
  local visitorInfo = NRCModuleManager:DoCmd(FriendModuleCmd.GetOnlineVisitorByUin, _visitorInfo.visitorInfo.uin)
  if visitorInfo then
    title = visitorInfo.name
  end
  icon = SetHeadIconFunc(self)
  self.WidgetLoader:SetWidgetClass(self.ChallengeNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, title, desc, icon, nil, _visitorInfo.visitorIndex, visitorTip)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel15Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  self.WidgetLoader:SetWidgetClass(self.SeasonNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, _npcInfo.entry_id, self.worldMap)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel16Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {}
  self.WidgetLoader:SetWidgetClass(self.TerritoryTrialNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, props)
  if not self.WidgetLoader:GetPanel() then
    return
  end
  local TerritoryTrialActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TERRITORY_TRIAL)
  local activityObject
  for _, v in ipairs(TerritoryTrialActivityObject) do
    local activity_id = v:GetActivityId()
    if _G.DataConfigManager:GetActivityConf(activity_id).refresh_event_group[1].refresh_content[1] == _npcInfo.npc_refresh_id then
      activityObject = v
      break
    end
  end
  if activityObject then
    activityObject:BindActivityTimeLeft(self.WidgetLoader:GetPanel().Text_Time)
    local activityData = activityObject:GetActivityData()
    if activityData and activityData.trial_info then
      local trial_info = activityData.trial_info
      props.highest_score = trial_info.highest_score
      props.least_finish_round = trial_info.least_finish_round
      props.base_id = activityObject:GetSinglePartId()
      props.desc = _npcInfo.worldMapConf.worldmap_npc_des
    end
  else
    local base_id, close_time
    local activity_conf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ACTIVITY_CONF):GetAllDatas()
    for _, conf in pairs(activity_conf) do
      if conf.activity_type == _G.Enum.ActivityType.ATP_TERRITORY_TRIAL and conf.refresh_event_group[1].refresh_content[1] == _npcInfo.npc_refresh_id then
        base_id = conf.base_id[1]
        close_time = conf.disappear_time
        break
      end
    end
    props.base_id = base_id
    props.desc = _npcInfo.worldMapConf.worldmap_npc_des
    self.WidgetLoader:GetPanel():SetCloseTimestamp(ActivityUtils.ToTimestamp(close_time))
  end
  self.WidgetLoader:LoadPanelSync(self, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanel17Info(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local props = {
    name = "",
    desc = "",
    headIconPath = "",
    ownerName = "",
    isHeadIcon = true
  }
  if self.module:CheckIsTracing(BigMapModuleEnum.TraceType.ForceTrace, _npcInfo.entry_id, _npcInfo.logic_id) then
    self.btnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.btnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local worldMapConfId = _npcInfo.world_map_cfg_id
  if worldMapConfId and worldMapConfId > 0 then
    local worldMapConf = DataConfigManager:GetWorldMapConf(worldMapConfId)
    if worldMapConf then
      props.name = worldMapConf.element_text_name
      if BigMapUtils.CheckShowRongDuanIcon(worldMapConf, _npcInfo.mutation_type) then
        props.headIconPath = self:GetDesIconPath(worldMapConf.shine_rongduan_icon)
      else
        props.headIconPath = self:GetDesIconPath(worldMapConf.world_map_NPCicon_des)
      end
      if (worldMapConf.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING or worldMapConf.map_show_type == Enum.MapIconShowType.MAP_SHINING_SEASON_DAZZLING) and _npcInfo and _npcInfo.mutation_type and _npcInfo.glass_info and PetUtils.CheckIsHiddenGlass(_npcInfo.mutation_type, _npcInfo.glass_info) then
        local iconPath = self:GetHiddenGlassIcon(_npcInfo.mutation_type, _npcInfo.glass_info)
        if iconPath then
          props.headIconPath = iconPath
        end
      end
      local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      if localPlayer then
        local playerId = localPlayer:GetServerId()
        if playerId == _npcInfo.ownerId then
          props.desc = worldMapConf.worldmap_npc_des
        else
          local desc1 = ""
          if worldMapConf.map_show_type == Enum.MapIconShowType.MAP_NPC_DAZZLING or worldMapConf.map_show_type == Enum.MapIconShowType.MAP_SEASON_DAZZLING then
            desc1 = DataConfigManager:GetMapGlobalConfig("highvalue_pet_track_not_owner").str
          else
            desc1 = DataConfigManager:GetMapGlobalConfig("highvalue_nightmare_pet_track_not_owner").str
          end
          props.ownerName = _npcInfo.ownerName
          props.desc = string.format(desc1, _npcInfo.ownerName)
        end
      end
    end
  end
  self.WidgetLoader:SetWidgetClass(self.CommonNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, 0, props)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:GetHiddenGlassIcon(mutation_type, glass_info)
  if mutation_type and glass_info then
    local isShining = 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_SHINING
    local HiddenGlassID = glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if not isShining and HiddenGlassConf.stroke_small_icon and not string.IsNilOrEmpty(HiddenGlassConf.stroke_small_icon) then
          return HiddenGlassConf.stroke_small_icon
        elseif isShining and HiddenGlassConf.yise_stroke_small_icon and not string.IsNilOrEmpty(HiddenGlassConf.yise_stroke_small_icon) then
          return HiddenGlassConf.yise_stroke_small_icon
        end
      end
    end
  end
  return nil
end

function UMG_NpcInfo_C:GetShowItemList(shopItemList, showItemList)
  for k, shopItem in ipairs(shopItemList) do
    local isItemExists = false
    for l, showItem in ipairs(showItemList) do
      if showItem.itemId == shopItem.itemId then
        isItemExists = true
        break
      end
    end
    if not isItemExists then
      table.insert(showItemList, shopItem)
    end
  end
  return showItemList
end

function UMG_NpcInfo_C:SortShowItemList(list)
  table.sort(list, function(a, b)
    local aIsFashion = a.itemType == _G.Enum.GoodsType.GT_FASHION or a.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS
    local bIsFashion = b.itemType == _G.Enum.GoodsType.GT_FASHION or b.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS
    if aIsFashion and not bIsFashion then
      return true
    elseif not aIsFashion and bIsFashion then
      return false
    elseif aIsFashion and bIsFashion then
      return a.sortId < b.sortId
    elseif a.itemQuantity == b.itemQuantity then
      if a.sortId == b.sortId then
        return a.itemId < b.itemId
      else
        return a.sortId < b.sortId
      end
    else
      return a.itemQuantity > b.itemQuantity
    end
  end)
  local coinItem
  for k, v in ipairs(list) do
    if v.itemId == _G.Enum.VisualItem.VI_COIN then
      coinItem = table.remove(list, k)
      break
    end
  end
  if coinItem then
    table.insert(list, coinItem)
  end
  return list
end

function UMG_NpcInfo_C:SetRewardList(itemInfo)
  local rewardsTable = {}
  for k, v in ipairs(itemInfo) do
    local rewards = _G.NRCCommonItemIconData()
    if v.Type == _G.Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(v.Id)
      rewards.itemQuantity = vItemConf.item_quality
      rewards.sortId = vItemConf.sort_id
    elseif v.Type == _G.Enum.GoodsType.GT_BAGITEM then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(v.Id)
      rewards.itemQuantity = bagItemConf.item_quality
      rewards.sortId = bagItemConf.sort_id
    end
    rewards.itemType = v.Type
    rewards.itemId = v.Id
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  return rewardsTable
end

function UMG_NpcInfo_C:SetShopList(itemInfo)
  local shopTable = {}
  if itemInfo then
    for k, v in ipairs(itemInfo) do
      local rewards = _G.NRCCommonItemIconData()
      local goodsConf = NPCShopUtils:GetAdjustGoodConf(v.goods_id, self.ShopID)
      if goodsConf then
        if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
          rewards.itemQuantity = bagItemConf.item_quality
          rewards.sortId = bagItemConf.sort_id
        elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
          local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsConf.item_id)
          rewards.itemQuantity = vItemConf.item_quality
          rewards.sortId = vItemConf.sort_id
        elseif goodsConf.Type == Enum.GoodsType.GT_FASHION then
          local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(goodsConf.item_id)
          rewards.itemQuantity = fashionItemConf.item_quality
          rewards.sortId = goodsConf.shop_pos
        elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_SUITS then
          local fashionItemConf = _G.DataConfigManager:GetFashionSuitsConf(goodsConf.item_id)
          rewards.itemQuantity = AppearanceUtils.GetSuitQuality(fashionItemConf.suit_grade)
          rewards.sortId = goodsConf.shop_pos
        else
          rewards.itemQuantity = 1
          rewards.sortId = goodsConf.shop_pos
        end
        rewards.itemType = goodsConf.Type
        rewards.itemId = goodsConf.item_id
        rewards.buy_num = v.buy_num
        rewards.limit_buy_num = v.limit_buy_num
        rewards.bShowTip = true
        table.insert(shopTable, rewards)
      end
    end
  end
  return shopTable
end

function UMG_NpcInfo_C:SetBtnSwitcherIndex(index)
  if index >= 0 then
    self.btnSwitcher:SetActiveWidgetIndex(index)
    self.btnState = index
  end
end

function UMG_NpcInfo_C:UpdateMessage(_npcType)
  if _npcType == _G.Enum.ClientNpcType.CNT_UNLOCKPORT then
    self:setActive(self.textMessage, true)
    self.textMessage:SetText(LuaText.umg_npcinfo_6)
  elseif _npcType == _G.Enum.ClientNpcType.CNT_TELEPORT then
    self:setActive(self.textMessage, true)
    self.textMessage:SetText(LuaText.umg_npcinfo_7)
  elseif _npcType == _G.Enum.ClientNpcType.CNT_NORMALFUNC then
    self:setActive(self.textMessage, false)
  elseif _npcType == _G.Enum.ClientNpcType.CNT_PETBOSS then
    self:setActive(self.textMessage, false)
  else
    self:setActive(self.textMessage, false)
  end
end

function UMG_NpcInfo_C:UpdateButtonState(_npcType, _teleportId, _isUnLock)
  if _npcType then
    self.traceType = UMG_NpcInfo_C.TraceType.NPC
    self.isUnLock = _isUnLock
    if _npcType == _G.Enum.ClientNpcType.CNT_PETBOSS and self.uiData.next_npc_refresh_time and self.uiData.next_npc_refresh_time - _G.ZoneServer:GetServerTime() / 1000 >= 0 then
      self._npcType = _npcType
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.WaitTime)
      return
    end
    if self.module:GetTransferBtnNum(self.worldMap) > 0 then
      local bNotInFogArea = true
      if self.uiData.npc_pos then
        bNotInFogArea = BigMapUtils.CheckInFogAreaByPos(self.uiData.npc_pos, self.data.curShowSceneResId)
      end
      if self.worldMap.map_tips_show_type == _G.Enum.MapTipsShowType.MAP_TIPS_OWL_SANCTUARY then
        if self.uiData.npc_level > 1 then
          self:SetTransferBtn()
        else
          self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
        end
      elseif _isUnLock then
        if 0 == self.worldMap.unlock_element_show_top and not bNotInFogArea then
          self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
        else
          self:SetTransferBtn()
        end
      else
        self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
      end
    elseif _npcType == _G.Enum.ClientNpcType.CNT_FLOWER_SEED or self.worldMap.map_show_type == _G.Enum.MapIconShowType.MAP_CREATE_MAGIC then
      if _isUnLock then
        self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Teleport_1)
      else
        self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
      end
    else
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
    end
    local npcId = self.uiData and self.uiData.entry_id or self.uiData.npcId
    local logicId = self.uiData and self.uiData.logic_id or npcId
    local moduleData = self.module and self.module.data
    if moduleData then
      local traceNpcInfo = moduleData:GetTraceInfoByType(BigMapModuleEnum.TraceType.NPC)
      local traceEntryId = 0
      local traceLogicId = 0
      if traceNpcInfo then
        traceEntryId = traceNpcInfo.npcInfo.entry_id
        traceLogicId = traceNpcInfo.npcInfo.logic_id
      end
      if npcId and logicId and traceEntryId == npcId and traceLogicId == logicId then
        if _npcType == _G.Enum.ClientNpcType.CNT_UNLOCKPORT or _npcType == _G.Enum.ClientNpcType.CNT_TELEPORT then
          if _isUnLock then
            self:SetTransferBtn()
          else
            self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
          end
        else
          self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
        end
      end
    end
  elseif self.worldMap and self.worldMap.map_show_type == _G.Enum.MapIconShowType.MAP_ONLINE_TEAM then
    self:SetTransferBtn()
  else
    self.traceType = UMG_NpcInfo_C.TraceType.TASK
    if self.uiData.TaskShowType == BigMapModuleEnum.TaskShowType.TRACING then
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
    elseif self.uiData.TaskShowType == BigMapModuleEnum.TaskShowType.UNDO then
      local moduleData = self.module and self.module.data
      if moduleData and self.uiData.TaskConf then
        local bIsTrack = moduleData:GetCurTraceAcceptableTask(self.uiData.TaskConf.id)
        if bIsTrack then
          self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
        else
          self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
        end
        return
      end
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
    elseif self.uiData.TaskShowType == BigMapModuleEnum.TaskShowType.ACCEPTED then
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
    end
  end
end

function UMG_NpcInfo_C:setActive(_uiItem, _isShow)
  if _uiItem then
    if _isShow then
      _uiItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      _uiItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_NpcInfo_C:OnBtnTraceClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_NpcInfo_C:OnBtnTraceClick")
  if self.traceType == UMG_NpcInfo_C.TraceType.TASK then
    if self.uiData.TaskShowType == BigMapModuleEnum.TaskShowType.UNDO then
      local moduleData = self.module and self.module.data
      if moduleData and self.uiData.NpcPosition[1] and self.uiData.NpcPosition[1].pos then
        local traceInfo = {}
        traceInfo.traceType = BigMapModuleEnum.TraceType.Task
        traceInfo.taskShowType = BigMapModuleEnum.TaskShowType.UNDO
        local posX = self.uiData.NpcPosition[1].pos.x
        local posY = self.uiData.NpcPosition[1].pos.y
        local sceneResId = self.uiData.TaskSceneResId
        if not sceneResId or 0 == sceneResId then
          sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
        end
        local imagePosX, imagePosY = BigMapUtils.ScenePosToImagePos(sceneResId, posX, posY)
        traceInfo.iconImagePos = {x = imagePosX, y = imagePosY}
        traceInfo.sceneResId = sceneResId
        traceInfo.taskConf = self.uiData.TaskConf
        traceInfo.taskInfo = {}
        traceInfo.taskInfo.taskId = self.uiData.TaskConf.id
        traceInfo.taskInfo.go_index = 1
        moduleData:SetCurTraceAcceptTask(self.uiData.TaskConf.id, true)
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.StartOrCancelTrace, true, traceInfo)
        self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
      end
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.CloseWorldMap)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
      return
    end
    if self.NpcInfo and self.NpcInfo.SpecialTaskType and self.NpcInfo.SpecialTaskType == "TreasureDig" then
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.SwitchActivityTraceTask, true, self.uiData.TaskConf.id)
      self.uiData.TaskShowType = BigMapModuleEnum.TaskShowType.TRACING
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.CloseWorldMap)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
    else
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.setTrack, self.uiData.TaskConf.id, true)
      self.uiData.TaskShowType = BigMapModuleEnum.TaskShowType.TRACING
      self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.CloseWorldMap)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
    end
  elseif self.traceType == UMG_NpcInfo_C.TraceType.NPC then
    local npcId = 0
    if self.uiData.entry_id then
      npcId = self.uiData and self.uiData.entry_id
    else
      npcId = self.uiData.npcId
    end
    local logicId = self.uiData.logic_id or npcId
    local moduleData = self.module and self.module.data
    if moduleData and npcId then
      local traceNpcInfo = moduleData:GetNPCInfoByEntryId(npcId, logicId)
      if traceNpcInfo then
        local posX = traceNpcInfo.npc_pos.x
        local posY = traceNpcInfo.npc_pos.y
        local sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
        if self.uiData.npc_refresh_id and self.uiData.npc_refresh_id > 0 then
          sceneResId = BigMapUtils.GetSceneResIdByRefreshId(self.uiData.npc_refresh_id)
        end
        if nil == sceneResId then
          sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
        end
        moduleData:SetCurTraceNpc(npcId, logicId, sceneResId)
        self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.CancelTrace)
      end
    end
  end
end

function UMG_NpcInfo_C:OnBtnUnkownClick()
end

function UMG_NpcInfo_C:OnBtnCancelTraceClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_NpcInfo_C:OnBtnCancelTraceClick")
  if self.traceType == UMG_NpcInfo_C.TraceType.TASK then
    if self.uiData.TaskShowType == BigMapModuleEnum.TaskShowType.UNDO then
      if self.uiData.TaskConf then
        local moduleData = self.module and self.module.data
        if moduleData then
          local traceInfo = {}
          traceInfo.traceType = BigMapModuleEnum.TraceType.Task
          traceInfo.taskShowType = BigMapModuleEnum.TaskShowType.UNDO
          local posX = self.uiData.NpcPosition[1].pos.x
          local posY = self.uiData.NpcPosition[1].pos.y
          local sceneResId = self.uiData.TaskSceneResId
          if not sceneResId or 0 == sceneResId then
            sceneResId = BigMapUtils.GetSceneResIdByPos(posX, posY)
          end
          local imagePosX, imagePosY = BigMapUtils.ScenePosToImagePos(sceneResId, posX, posY)
          traceInfo.iconImagePos = {x = imagePosX, y = imagePosY}
          traceInfo.sceneResId = sceneResId
          traceInfo.taskConf = self.uiData.TaskConf
          traceInfo.taskInfo = {}
          traceInfo.taskInfo.taskId = self.uiData.TaskConf.id
          traceInfo.taskInfo.go_index = 1
          moduleData:SetCurTraceAcceptTask(self.uiData.TaskConf.id, false)
          _G.NRCModuleManager:DoCmd(BigMapModuleCmd.StartOrCancelTrace, false, traceInfo)
          _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.CloseWorldMap)
          _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
        end
      end
      return
    end
    if self.uiData.TaskConf then
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.setTrack, self.uiData.TaskConf.id, false)
      if self.NpcInfo and self.NpcInfo.SpecialTaskType and self.NpcInfo.SpecialTaskType == "TreasureDig" then
        _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.SwitchActivityTraceTask, false, self.uiData.TaskConf.id)
      end
    end
    self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
    self.uiData.TaskShowType = BigMapModuleEnum.TaskShowType.ACCEPTED
    self:DispatchEvent(BigMapModuleEvent.UpdateTraceEffect, self.uiData.TaskConf.id)
  elseif self.traceType == UMG_NpcInfo_C.TraceType.NPC then
    local npcId = 0
    if self.uiData.entry_id then
      npcId = self.uiData and self.uiData.entry_id
    else
      npcId = self.uiData.npcId
    end
    local moduleData = self.module and self.module.data
    if moduleData and npcId then
      local traceNpcId = moduleData:GetCurTraceNpcId()
      if traceNpcId == npcId and -1 ~= npcId and 0 ~= npcId then
        moduleData:SetCurTraceNpc(-1)
        self:SetBtnSwitcherIndex(BigMapModuleEnum.NpcInfoButtonType.Trace)
        local traceInfo = {}
        traceInfo.traceType = BigMapModuleEnum.TraceType.NPC
        traceInfo.npcInfo = {entry_id = npcId}
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.StartOrCancelTrace, false, traceInfo)
      end
    end
  end
end

function UMG_NpcInfo_C:OnMarkBtnClick()
  if self.traceType == UMG_NpcInfo_C.TraceType.TASK then
    self:DispatchEvent(BigMapModuleEvent.SetMarkerEvent, self.uiData.NpcPosition, 35)
  end
end

function UMG_NpcInfo_C:OnBtnTransferClick()
  self:ClickTransferBtn()
end

function UMG_NpcInfo_C:OnSpecialTransBtnClicked()
  self:ClickTransferBtn(true)
end

function UMG_NpcInfo_C:OnTransBtnClicked()
  self:ClickTransferBtn(false)
end

function UMG_NpcInfo_C:ClickTransferBtn(bSpecial)
  local curSceneId = SceneUtils.GetSceneID()
  local bInHome = BigMapUtils.IsHomeScene(curSceneId)
  if nil == bSpecial then
    if self.worldMap.teleport_rule_id > 0 or self.worldMap.teleport_id > 0 then
      bSpecial = false
    elseif self.worldMap.special_teleport > 0 then
      bSpecial = true
    end
  end
  if bInHome and BigMapUtils.IsBigWorldMap(self.data.curShowSceneResId) then
    self.module:DoLeaveHomeTransfer(self.uiData.entry_id, self.worldMap)
  else
    self.module:DoCommonTransfer(self.uiData.entry_id, self.worldMap, self.uiData.visitorInfo, bSpecial)
  end
  if not BattleManager:IsInBattle() then
    local npcId = self.uiData and self.uiData.entry_id
    if npcId and 0 ~= npcId and self.module:GetTransferBtnNum(self.worldMap) > 0 and npcId > 0 and self.worldMap.map_show_location == Enum.MapIconShowLocation.MISL_BIGWORLD then
      self.Btn2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    if self.worldMap.map_show_type == _G.Enum.MapIconShowType.MAP_ONLINE_TEAM then
      self.Btn2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  end
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CloseMapRightPanel)
end

function UMG_NpcInfo_C:OnPanelShow(_isShow)
  UE4.UNRCTUIStatics.ReleaseAllCapture(0)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  Log.Info("UMG_NpcInfo_C:OnPanelShow", _isShow)
  if _isShow then
    if self.bPlayOpenAnim then
      _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
      self:PlayAnimation(self.Open)
    end
  else
    self:PlayAnimation(self.Out)
  end
end

function UMG_NpcInfo_C:GetDesIconPath(Icon)
  local param = string.split(Icon, "/")
  if #param > 1 then
    return Icon, true
  else
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      return bigMapModule:GetBigMapIconRes(Icon)
    end
  end
end

function UMG_NpcInfo_C:GetTravelIconPath()
  return "PaperSprite'/Game/NewRoco/Modules/System/Travel/Raw/Frames/img_lvxingshe_png.img_lvxingshe_png'"
end

function UMG_NpcInfo_C:OnAnimationFinished(anim)
  if anim == self.Open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

function UMG_NpcInfo_C:UpdatePanelSanctuaryInfo(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  local title = self.worldMap.element_text_name
  local node = ""
  if self.uiData.status == _G.ProtoEnum.LockStatus.ENUM.UNLOCKED then
    if #self.worldMap.npcicon_levelup > 0 then
      for i = 1, #self.worldMap.npcicon_levelup do
        if self.worldMap.npcicon_levelup[i].level == self.uiData.npc_level then
          node = self:GetDesIconPath(self.worldMap.npcicon_levelup[i].icon)
        end
      end
    else
      node = self:GetDesIconPath(self.worldMap.npcicon_unlock)
    end
  elseif self.worldMap.npcicon_lock then
    node = self:GetDesIconPath(self.worldMap.npcicon_lock)
  end
  self.WidgetLoader:SetWidgetClass(self.MagicClassRef)
  self.WidgetLoader:LoadPanelSync(self, false, title, node, _npcInfo)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanelHomeInfo(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  self.WidgetLoader:SetWidgetClass(self.HomeOptionNpcClassRef)
  self.WidgetLoader:LoadPanelSync(self, self.worldMap, _npcInfo, FPartial(self.OnBtnTransferClick, self), self.extraInfo)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePlantGroundInfo(_npcInfo)
  self.WidgetLoader:UnLoadPanel(true)
  self.WidgetLoader:SetWidgetClass(self.PlantGroundClassRef)
  self.WidgetLoader:LoadPanelSync(self, self.worldMap, _npcInfo, self.extraInfo)
  self:OnPanelShow(true)
end

function UMG_NpcInfo_C:UpdatePanelRandomShopInfo(_npcInfo)
  local npcCfg = _npcInfo.npcCfg
  local shopID = self.module.data:GetShopIDByNpcCfg(npcCfg)
  if nil == shopID or 0 == shopID then
    Log.Error("[UMG_NpcInfo_C:UpdatePanelRandomShopInfo]:shopID is nil or 0!")
    return
  end
  if self.module.data:GetNpcTipShowType() ~= _G.Enum.MapTipsShowType.MAP_TIPS_RANDOM_SHOP then
    self.WidgetLoader:UnLoadPanel(true)
    local req = _G.ProtoMessage:newZoneShopGetInfoReq()
    req.shop_id = shopID
    local reqShopData = {
      shopId = shopID,
      Caller = self,
      rspHandler = self.GetStoreListRsp,
      needModal = false,
      ignoreErrorTip = false,
      reqTag = "UMG_NpcInfo_C:UpdatePanelRandomShopInfo"
    }
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
  end
  local widgetClass = "WidgetBlueprint'/Game/NewRoco/Modules/System/BigMap/Res/UMG_NpcInfo_MysteriousStore.UMG_NpcInfo_MysteriousStore_C'"
  local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(widgetClass)
  self.WidgetLoader:SetWidgetClass(softClassPath)
  self.WidgetLoader:LoadPanel(self, _npcInfo)
end

return UMG_NpcInfo_C

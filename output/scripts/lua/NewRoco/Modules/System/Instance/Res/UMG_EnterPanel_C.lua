local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local nameColorBoundary = _G.DataConfigManager:GetPetGlobalConfig("pet_level_boundary").num
local UMG_EnterPanel_C = _G.NRCPanelBase:Extend("UMG_EnterPanel_C")
local InstanceModuleEvent = require("NewRoco.Modules.Core.Instance.InstanceModuleEvent")

function UMG_EnterPanel_C:OnConstruct()
  self.did = 0
  self.Btn_Challenge:SetBtnText(LuaText.umg_enterpanel_1)
  self.Btn_Challenge_1:SetBtnText(LuaText.team_battle_text_2)
end

function UMG_EnterPanel_C:OnDestruct()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer.inputComponent:SetInputEnable(self, true, "EnterDungeon")
    localPlayer.inputComponent:SetCameraControlEnable(self, true)
  end
end

function UMG_EnterPanel_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Challenge.btnLevelUp, self.OnEnterBtnPress)
  self:AddButtonListener(self.Btn_Challenge_1.btnLevelUp, self.OnExitBtnPress)
  _G.NRCEventCenter:RegisterEvent("UMG_EnterPanel_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_DUNGEON_DATA_NOTIFY, self.RefreshData)
end

function UMG_EnterPanel_C:OnRemoveEventListener()
  self:RemoveAllButtonListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_DUNGEON_DATA_NOTIFY, self.RefreshData)
end

function UMG_EnterPanel_C:RefreshData()
  local dconf = DataConfigManager:GetDungeonConf(self.did, true)
  if dconf then
    self:UpdateReward(dconf)
  end
end

function UMG_EnterPanel_C:UpdateReward(dunCfg)
  local rewardList = dunCfg.show_reward
  if table.isNil(rewardList) then
    self.Icon_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Icon_List:SetVisibility(UE4.ESlateVisibility.Visible)
    local rewardsTable = {}
    for k, v in ipairs(dunCfg.show_reward) do
      local bShowNum = false
      if v.reward_count and 0 ~= v.reward_count then
        bShowNum = true
      end
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = v.reward_type
      rewards.itemId = v.reward_id
      rewards.itemNum = v.reward_count
      rewards.bShowNum = bShowNum
      rewards.bShowTip = true
      rewards.isDone = self.isDone
      rewards.isPreciousPetEgg = self:IsPreciousPetEgg(v.reward_id)
      table.insert(rewardsTable, rewards)
    end
    self.Icon_List:InitGridView(rewardsTable)
  end
end

function UMG_EnterPanel_C:IsPreciousPetEgg(rewardId)
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(rewardId, true)
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

function UMG_EnterPanel_C:UpdateCollectionList(dunCfg, collections)
  local collectionInfoList = {}
  if dunCfg and dunCfg.collection then
    local function GetCollectionNumByType(type)
      if collections and #collections > 0 then
        for i, v in ipairs(collections) do
          if v.collecttion_type == type then
            return v.collection_num
          end
        end
      end
      return 0
    end
    
    for i, v in ipairs(dunCfg.collection) do
      local collectionInfo = {}
      collectionInfo.collectType = v.collect_type
      collectionInfo.curNum = GetCollectionNumByType(v.collect_type)
      collectionInfo.needNum = #v.collect_content_id
      table.insert(collectionInfoList, collectionInfo)
    end
  end
  self.List:InitGridView(collectionInfoList)
end

function UMG_EnterPanel_C:OnActive()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  self.Ret_Param = "1"
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1060, "UMG_EnterPanel_C")
  self:OnAddEventListener()
  self.did = NRCModuleManager:DoCmd(InstanceModuleCmd.GetCurrentDungeon)
  local State = NRCModuleManager:DoCmd(InstanceModuleCmd.GetDungeonInfo, self.did)
  self.Satisfied = false
  local Entered
  if not State then
    Entered = false
  else
    Entered = State.entered
  end
  if State and State.dungeon_state == _G.ProtoEnum.DungeonState.DS_DONE then
    self.isDone = true
    self.OffTheStocks:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.OffTheStocks:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.isDone = false
  end
  local dconf = DataConfigManager:GetDungeonConf(self.did, true)
  if not dconf then
    Log.Error("\230\159\165\230\137\190\228\184\141\229\136\176\229\137\175\230\156\172ID", self.did)
    return
  end
  local recommendLevel = dconf.battle_starlevel
  if recommendLevel and 0 ~= recommendLevel then
    recommendLevel = string.format("\230\142\168\232\141\144\233\173\148\230\179\149\229\184\136\230\152\159\231\186\167 %s", tostring(dconf.battle_starlevel))
    self.MagicStarLevel:SetText(recommendLevel)
    self.CanvasPanel_84:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif dconf.enemy_id and dconf.enemy_id[1] then
    self.CanvasPanel_84:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local level, IsReCom = MagicManualUtils.GetBossLevel(dconf.enemy_id[1])
    local worldLevel = (_G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0) + 1
    local pet_level_limit = _G.DataConfigManager:GetWorldLevelConf(worldLevel).pet_level_limit
    local subLevel = level - pet_level_limit
    local fColor = UE4.UNRCStatics.HexToSlateColor("#ffffff")
    if subLevel > nameColorBoundary then
      fColor = UE4.UNRCStatics.HexToSlateColor("#c12a2a")
    elseif subLevel > 0 and subLevel <= nameColorBoundary then
      fColor = UE4.UNRCStatics.HexToSlateColor("#e77d00")
    else
      fColor = UE4.UNRCStatics.HexToSlateColor("#ffffff")
    end
    self.MagicStarLevel:SetColorAndOpacity(fColor)
    self.MagicStarLevel:SetText(string.format(LuaText.dungeon_enemy_level_description, level))
  else
    self.CanvasPanel_84:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Name:SetText(dconf.type_name)
  local icon = ""
  local worldMapConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_CONF):GetAllDatas()
  for k, v in pairs(worldMapConfs) do
    if v.dungeon_id == self.did then
      self.npcName:SetText(v.element_text_name)
      icon = v.dungeon_title_bg
      break
    end
  end
  local ReqNomen = ""
  for k, v in ipairs(dconf.require_cond) do
    if 1 == k then
      self.Satisfied = true
    end
    if v.require_type == Enum.TaskAcceptConditionType.TACT_ITEM then
      local item
      local numberReq = 0
      item = v.require_data[1]
      numberReq = v.require_data[2]
      if item then
        local itemConf = DataConfigManager:GetBagItemConf(item, true)
        local numberActual = 0
        local itemData
        itemData = NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, item)
        if not itemData then
          numberActual = 0
        else
          numberActual = itemData.num
        end
        if numberActual <= 0 then
          numberActual = 0
        end
        if Entered then
          if itemConf then
            ReqNomen = string.format("%s%s %d/%d ", ReqNomen, itemConf.name, numberReq, numberReq)
          end
        else
          if itemConf then
            ReqNomen = string.format("%s%s %d/%d ", ReqNomen, itemConf.name, numberActual, numberReq)
          end
          if numberReq <= numberActual then
          else
            self.Satisfied = false
          end
        end
      end
    elseif v.require_type == Enum.TaskAcceptConditionType.TACT_LEVEL then
      ReqNomen = string.format("%s%s ", ReqNomen, v.require_data)
      if DataModelMgr.PlayerDataModel:GetPlayerLevel() >= v.require_data then
      else
        self.Satisfied = false
      end
    end
  end
  self:UpdateReward(dconf)
  self:QueryDungeonCollectState(dconf.id)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").DIALOG
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
end

function UMG_EnterPanel_C:QueryDungeonCollectState(ID)
  local Req = _G.ProtoMessage:newZoneSceneDungeonInfoQueryReq()
  Req.dungeon_cfg_id = ID
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_DUNGEON_INFO_QUERY_REQ, Req, self, self.OnDungeonCollectionRsp, true, false)
end

function UMG_EnterPanel_C:OnDungeonCollectionRsp(Rsp)
  if not self:IsValid() then
    return
  end
  local Conf = _G.DataConfigManager:GetDungeonConf(self.did)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.open)
  self:UpdateCollectionList(Conf, Rsp.collections)
end

function UMG_EnterPanel_C:OnEnterBtnPress()
  if self:IsAnimationPlaying(self.close) then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_EnterPanel_C")
  self.Ret_Param = "0"
  self:PlayAnimation(self.close)
  self:RemoveAllButtonListener()
end

function UMG_EnterPanel_C:OnAnimationFinished(Animation)
  if Animation == self.close then
    if self.Ret_Param == "0" and self.Satisfied then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1254, "UMG_EnterPanel_C")
    else
    end
    self:DoClose()
  elseif Animation == self.open then
    self:PlayAnimation(self.loop)
  elseif Animation == self.loop then
    self:PlayAnimation(self.loop)
  end
end

function UMG_EnterPanel_C:OnExitBtnPress()
  self.Icon_List:SetItemClickAble(false)
  if self:IsAnimationPlaying(self.close) then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_EnterPanel_C")
  self.Ret_Param = "1"
  self:PlayAnimation(self.close)
  self:RemoveAllButtonListener()
end

function UMG_EnterPanel_C:OnPcClose()
  self:OnExitBtnPress()
end

function UMG_EnterPanel_C:OnDeactive()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  self:OnRemoveEventListener()
  self.module.InstanceID = nil
  self.module.FailEnterDungeon = self.Ret_Param
  self.module:DispatchEvent(InstanceModuleEvent.EnterPanelClosed, self.Ret_Param)
end

function UMG_EnterPanel_C:OnReConnect()
  self.Ret_Param = "1"
  self:DoClose()
end

return UMG_EnterPanel_C

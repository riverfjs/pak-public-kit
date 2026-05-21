local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_RelationTree_Item_C = _G.NRCPanelBase:Extend("UMG_RelationTree_Item_C")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ProtoEnum = require("Data.PB.ProtoEnum")
local relationtree_refresh_cd = _G.DataConfigManager:GetGlobalConfigByKeyType("relationtree_refresh_cd", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local CoinType = _G.Enum.VisualItem.VI_DIAMOND
local StarLightType = _G.Enum.VisualItem.VI_STAR_LIGHT
local EnumOpationState = {GetState = 1, Implement = 2}

function UMG_RelationTree_Item_C:OnConstruct()
  self.module = _G.NRCModuleManager:GetModule("RelationTreeModule")
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:OnAddEventListener()
end

function UMG_RelationTree_Item_C:OnAddEventListener()
  self:AddButtonListener(self.SelectButton, self.OnSelectButton)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_C", self, RelationTreeEvent.RELATION_ITEM_UNLOCK_EFFECT, self.ItemUnlockEffect)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_C", self, RelationTreeEvent.UpdateItemEffect, self.UpdateItemEffect)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_C", self, RelationTreeEvent.RELATION_ITEM_UNLOCK_CANCEL_EFFECT, self.OnlyPlayerWaitForResponse_Out)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_C", self, RelationTreeEvent.UpdateCostPanel, self.UpdateCostPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_C", self, RelationTreeEvent.OnTodaySendEggTimesUpdate, self.RefreshNoteGaryMask)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_C", self, RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, self.UpdateInviteAnim)
end

function UMG_RelationTree_Item_C:SetData(Data, Floor, DataList, PlayerUid, UnlockMaxFloor, OtherPlayerLevelData)
  if not Data then
    return
  end
  self.floor = Floor
  self.DataList = DataList
  self.PlayerUid = PlayerUid
  self.MaxUnlockFloor = UnlockMaxFloor
  self.OtherPlayerLevelData = OtherPlayerLevelData
  self:OnItemUpdate(Data)
end

function UMG_RelationTree_Item_C:OnItemUpdate(_data)
  self.ItemData = _data
  self.State = self:GetEnumOpation(EnumOpationState.GetState)
  self:UpdateUI()
end

function UMG_RelationTree_Item_C:UpdateItemEffect(playerUin, relatioNTreeType)
  if self.ItemData and self.ItemData.RelationTreeType == relatioNTreeType and self.PlayerUid and self.PlayerUid == playerUin then
    self:PlayAnimation(self.WaitForResponse_In)
  else
  end
end

function UMG_RelationTree_Item_C:UpdateInviteAnim(isCancel)
  if self.ItemData and self.player then
    local InviteComponent = self.player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    if InviteComponent and InviteComponent.TargetUin == self.PlayerUid then
      local IITType
      if self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_INVITE_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_REQUEST_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_INVITE_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_REQUEST_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_BATTLE_WATCH then
        if 1 == self.State then
          IITType = ProtoEnum.InteractInviteType.IIT_BATTLE
        end
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_VISITREQ then
        IITType = ProtoEnum.InteractInviteType.IIT_REQUEST_VISIT
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_INVITE then
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_GIFTEGG then
        IITType = ProtoEnum.InteractInviteType.IIT_GIFTING_EGG
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_HIGHFIVE then
        IITType = ProtoEnum.InteractInviteType.IIT_HIGHFIVE
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_HUGE then
        IITType = ProtoEnum.InteractInviteType.IIT_HUGE
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_ARM then
        IITType = ProtoEnum.InteractInviteType.IIT_ARM
      end
      if not isCancel then
        if IITType and IITType == InviteComponent.InviteType then
          Log.Debug("UMG_RelationTree_Item_C:UpdateInviteAnim Is Cancel false", tostring(InviteComponent.InviteType))
          self:PlayAnimation(self.WaitForResponse_In)
        end
      elseif IITType and IITType == InviteComponent.InviteType then
        Log.Debug("UMG_RelationTree_Item_C:UpdateInviteAnim Is Cancel true", tostring(InviteComponent.InviteType))
        self:StopAnimation(self.WaitForResponse_In)
        self:StopAnimation(self.WaitForResponse)
        self:PlayAnimation(self.WaitForResponse_Out)
      end
    end
  end
end

function UMG_RelationTree_Item_C:OnlyPlayerWaitForResponse_Out(RelationShipType)
  if self.ItemData and RelationShipType == self.ItemData.RelationTreeType then
    local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
    local PlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
    if MyRequest and PlayerUin and PlayerUin == self.PlayerUid then
      self:StopAnimation(self.WaitForResponse_In)
      self:StopAnimation(self.WaitForResponse)
      self:PlayAnimation(self.WaitForResponse_Out)
      if self.SelfSelect then
        if self.ItemData.ForwardUnlockState then
          self:PlayAnimation(self.Unlockable)
        else
          self:StopAnimation(self.Unlockable)
        end
        self.SelfSelect = false
      end
    end
  end
end

function UMG_RelationTree_Item_C:UpdateUI()
  if self.ItemData then
    self.FriendGuang:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if not self.ItemData.Unlock then
      if self.ItemData.ForwardUnlockState then
        self.NRCSwitcher:SetActiveWidgetIndex(0)
        local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
        local PlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
        if MyRequest and PlayerUin and PlayerUin == self.PlayerUid and MyRequest == self.ItemData.RelationTreeType then
          self:PlayAnimation(self.WaitForResponse_In)
        end
        self:StopAnimation(self.WaitForResponse)
        self:StopAnimation(self.Unlocked_normal)
        self:PlayAnimation(self.Unlockable)
        if self.ItemData.UnlockCost > 0 then
          self:UpdateItemCostPanel()
        else
          self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        if self.ItemData.StateStruct[self.State].icon then
          self.headPortrait:SetPath(self.ItemData.StateStruct[self.State].icon)
          if self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_ADDFRIEND then
            self.FriendGuang:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          end
        end
        self.NameText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self:StopAnimation(self.Unlockable_to_Unlocked)
        self:StopAnimationEx(self.Unlock)
        self:StopAllAnimations()
        self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Select2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if self.SelfSelect then
          self.SelfSelect = false
        end
        self.NRCSwitcher:SetActiveWidgetIndex(1)
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NameText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.NameText:SetText(self.ItemData.StateStruct[self.State].name)
    else
      self.NRCSwitcher:SetActiveWidgetIndex(0)
      self:StopAnimation(self.WaitForResponse)
      self:PlayAnimation(self.Unlocked_normal, 0, 0)
      self:UpdateInviteAnim(false)
      if self.ItemData.StateStruct[self.State].icon then
        self.headPortrait:SetPath(self.ItemData.StateStruct[self.State].icon)
      end
      self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NameText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NameText:SetText(self.ItemData.StateStruct[self.State].name)
      if self.ItemData.bShowRecall then
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NRCSwitcher_701:SetActiveWidgetIndex(1)
        self.Text_Starlight:SetText(_G.LuaText.recall_haoyoushu_starbuff)
        local iconPath = _G.DataConfigManager:GetVisualItemConf(StarLightType).iconPath
        self.Icon:SetPath(iconPath)
      end
      if self.ItemData.bPlayRecallAnim then
        self:PlayAnimation(self.WaitForResponse_In)
      end
      self:RefreshNoteGaryMask()
    end
  end
end

function UMG_RelationTree_Item_C:UpdateItemCostPanel()
  if self.ItemData then
    local iconPath = _G.DataConfigManager:GetVisualItemConf(CoinType).iconPath
    self.Icon:SetPath(iconPath)
    self.QuantityText:SetText(self.ItemData.UnlockCost)
    self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ConstPanel:SetRenderScale(UE4.FVector2D(1.0, 1.0))
    local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(CoinType) or 0
    if diamondNum < self.ItemData.UnlockCost then
      self.QuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AE3D3EFF"))
    else
      self.QuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
    end
  end
end

function UMG_RelationTree_Item_C:UpdateCostPanel()
  if self.ItemData then
    if not self.ItemData.Unlock then
      if self.ItemData.ForwardUnlockState then
        if self.ItemData.UnlockCost > 0 then
          self:UpdateItemCostPanel()
        else
          self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    elseif not self.ItemData.bShowRecall then
      self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_RelationTree_Item_C:OnSelectButton()
  if _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationItemSelectCD) > 0 then
    local Text = _G.DataConfigManager:GetLocalizationConf("relationtree_item_select_incd").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  if self.player then
    local InviteComponent = self.player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    if InviteComponent then
      local IITType
      if self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_INVITE_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_REQUEST_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_INVITE_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_REQUEST_TOGETHER then
        IITType = ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_BATTLE_WATCH then
        if 1 == self.State then
          IITType = ProtoEnum.InteractInviteType.IIT_BATTLE
        end
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_VISITREQ then
        IITType = ProtoEnum.InteractInviteType.IIT_REQUEST_VISIT
      elseif self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_INVITE then
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_GIFTEGG then
        IITType = ProtoEnum.InteractInviteType.IIT_GIFTING_EGG
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_HIGHFIVE then
        IITType = ProtoEnum.InteractInviteType.IIT_HIGHFIVE
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_HUGE then
        IITType = ProtoEnum.InteractInviteType.IIT_HUGE
      elseif self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_ARM then
        IITType = ProtoEnum.InteractInviteType.IIT_ARM
      end
      local InviteType = IITType
      if not self.ItemData.Unlock then
        InviteType = ProtoEnum.InteractInviteType.IIT_DOUBLE_ACTION
      end
      if InviteType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER or InviteType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
        local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.PlayerUid)
        if TargetPlayer and TargetPlayer.serverData and TargetPlayer.serverData.avatar_interact and TargetPlayer.serverData.avatar_interact.sit_info and 0 ~= TargetPlayer.serverData.avatar_interact.sit_info.sit_npc_id then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.sit_travel_together)
          return
        end
        if self.player.serverData and self.player.serverData.avatar_interact and self.player.serverData.avatar_interact.sit_info and 0 ~= self.player.serverData.avatar_interact.sit_info.sit_npc_id then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.no_enter_travel_together)
          return
        end
      end
      if InviteType and not InviteComponent:IsCanOverrideInteract(InviteType, InviteComponent._interactType) then
        local Text = LuaText.relationtree_performing_request_tip
        if Text then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
        end
        return
      end
      if InviteComponent.TargetUin == self.PlayerUid and IITType and IITType == InviteComponent.InviteType then
        local Text = LuaText.relationtree_repeat_request_tip
        if Text then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
        end
        return
      end
    end
  end
  if self.ItemData then
    if self.ItemData.Unlock then
      if not self:NodeIsGaryMask() then
      end
      self:GetEnumOpation(EnumOpationState.Implement)
    elseif self.ItemData.ForwardUnlockState then
      local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
      local PlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
      if MyRequest and PlayerUin and PlayerUin == self.PlayerUid and MyRequest == self.ItemData.RelationTreeType then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("relationtree_node_applying_unlock").msg)
        return
      else
        local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(CoinType) or 0
        if diamondNum >= self.ItemData.UnlockCost then
          if self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_ADDFRIEND then
            _G.NRCAudioManager:PlaySound2DAuto(40008003, "UMG_RelationTree_Item_C:SendUnlockReq")
            local UIBanConf = _G.DataConfigManager:GetUiEnterBanConf(_G.Enum.FunctionEntrance.FE_FRIEND)
            local UnlockType = UIBanConf and UIBanConf.unlock_cond_list and UIBanConf.unlock_cond_list[1] and UIBanConf.unlock_cond_list[1].unlock_type and UIBanConf.unlock_cond_list[1].unlock_type or Enum.EntranceUnlockCondition.EUC_ROLE_LEVEL
            local UnlockFriend = UIBanConf and UIBanConf.unlock_cond_list and UIBanConf.unlock_cond_list[1] and UIBanConf.unlock_cond_list[1].unlock_param and UIBanConf.unlock_cond_list[1].unlock_param[1] and UIBanConf.unlock_cond_list[1].unlock_param[1] or 5
            if UnlockType == Enum.EntranceUnlockCondition.EUC_ROLE_LEVEL then
              local heroLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() or 0
              if heroLv < tonumber(UnlockFriend) then
                local Text = LuaText.relationtree_self_addfriend_faild
                _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
                return
              end
              local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
              local OtherHeroLv = playerInfo and playerInfo.level and playerInfo.level or 0
              if OtherHeroLv < tonumber(UnlockFriend) then
                local Text = LuaText.relationtree_other_addfriend_faild
                _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
                return
              end
            elseif UnlockType == Enum.EntranceUnlockCondition.EUC_STORY_FLAG then
              local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_FRIEND, true)
              if isBan then
                return
              end
            end
            if self.player then
              local InviteComponent = self.player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
              if InviteComponent and not InviteComponent:IsCanOverrideInteract(ProtoEnum.InteractInviteType.IIT_DOUBLE_ACTION, InviteComponent._interactType) then
                local Text = LuaText.relationtree_performing_request_tip
                if Text then
                  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
                end
                return
              end
            end
            _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.UnlockRelationShipNodeReq, self.PlayerUid, self.ItemData.RelationTreeType)
          else
            _G.NRCAudioManager:PlaySound2DAuto(40008003, "UMG_RelationTree_Item_C:SendUnlockReq")
            self:OnDeleteUnlockRelationTreeNode()
          end
        else
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("relationtree_cost_diiamond_notenough").msg)
          return
        end
      end
    else
      local Text = _G.DataConfigManager:GetLocalizationConf("RelationTree_Node_UnableUnlock").msg
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      return
    end
    _G.NRCModeManager:DoCmd(RelationTreeCmd.SetRelationItemSelectCD, relationtree_refresh_cd)
    self:PlayAnimation(self.click)
  end
end

function UMG_RelationTree_Item_C:UpdateItemSelect(NodeId)
  if self.ItemData then
    if self.ItemData.ID == NodeId then
      self.SelfSelect = true
      if self.ItemData.Unlock then
        if not self:NodeIsGaryMask() then
        end
      elseif self.ItemData.ForwardUnlockState then
      end
    elseif self.SelfSelect then
      self.SelfSelect = false
      if self.ItemData.Unlock then
        self:PlayAnimation(self.Unlocked_normal, 0, 0)
      elseif self.ItemData.ForwardUnlockState then
        self:PlayAnimation(self.Unlockable)
      else
        self:StopAnimation(self.Unlockable)
      end
    end
  end
end

function UMG_RelationTree_Item_C:PrepareOnlineData()
  local canBeWatchBattle = false
  local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
  local battleBriefInfo = playerInfo and playerInfo.battle_brief_info
  if playerInfo and playerInfo.battle_brief_info and playerInfo.battle_brief_info.battle_conf_id then
    local isInBattleState = playerInfo.battle_state == ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IN_BATTLE
    local battleConfId = battleBriefInfo and battleBriefInfo.battle_conf_id
    local isConfigCanBeWatchBattle = BattleUtils.IsBattleConfigIdCanBeWatch(battleConfId)
    canBeWatchBattle = isConfigCanBeWatchBattle and isInBattleState or false
  end
  return canBeWatchBattle
end

function UMG_RelationTree_Item_C:GetDefaultEnumOpation(Opation)
  local ItemState = 1
  local UserEnum = Enum.RelationTreeTypeDefault
  if self.ItemData.RelationTreeTypeDefault == UserEnum.RLTTD_INVITE_TOGETHER then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        local isPlayerExitVisitor = false
        local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
        for k, v in ipairs(visitorList) do
          if v.uin == tonumber(self.PlayerUid) then
            isPlayerExitVisitor = true
          end
        end
        if isPlayerExitVisitor then
          self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER)
        elseif #visitorList >= 4 then
          local Text = LuaText.online_invite_num_full_cannot_hand_now
          if Text then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
          end
          return
        else
          self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER)
        end
      else
        self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER)
      end
      return
    end
  elseif self.ItemData.RelationTreeTypeDefault == UserEnum.RLTTD_REQUEST_TOGETHER then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        local isPlayerExitVisitor = false
        local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
        for k, v in ipairs(visitorList) do
          if v.uin == tonumber(self.PlayerUid) then
            isPlayerExitVisitor = true
          end
        end
        if isPlayerExitVisitor then
          self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER)
        else
          self.TogetherType = ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER
          local TipsContent = LuaText.online_apply_num_full_cannot_hand_now
          local dialogContext = DialogContext():SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCallback(self, self.PopUpBoxInvetTogetherHandle)
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
        end
      else
        self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER)
      end
      return
    end
  elseif self.ItemData.RelationTreeTypeDefault == UserEnum.RLTTD_BATTLE_WATCH then
    if Opation == EnumOpationState.GetState then
      local PlayerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
      if PlayerInfo and PlayerInfo.battle_state == ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IN_BATTLE then
        if self:PrepareOnlineData() then
          ItemState = 2
        else
          ItemState = 1
        end
      else
        ItemState = 1
      end
      return ItemState
    elseif self.ItemData.RelationTreeTypeDefault == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      if 1 == self.State then
        _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ApplyDoubleAction, self.PlayerUid, ProtoEnum.InteractInviteType.IIT_BATTLE, self.ItemData.StateStruct[self.State].actionID)
      else
        _G.NRCModuleManager:DoCmd(FriendModuleCmd.WatchFriendBattle, self.PlayerUid)
      end
      return
    end
  elseif self.ItemData.RelationTreeTypeDefault == UserEnum.RLTTD_VISITREQ then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      local bInHome = _G.NRCModeManager:DoCmd(_G.HomeModuleCmd.IsInHomeScene)
      if bInHome then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.ERR_SCENE_RELATION_INTERACT_NOT_ALLOW_VISIT_IN_HOME)
        return
      end
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        local isPlayerExitVisitor = false
        local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
        for k, v in ipairs(visitorList) do
          if v.uin == tonumber(self.PlayerUid) then
            isPlayerExitVisitor = true
          end
        end
        if isPlayerExitVisitor then
          local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
          if playerInfo then
            local Name = playerInfo.name
            local Text = string.format(LuaText.relationtree_visit_world_already, Name)
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
          end
          return
        else
          self.TogetherType = ProtoEnum.InteractInviteType.IIT_REQUEST_VISIT
          local TipsContent = LuaText.relationtree_leave_world_check
          local dialogContext = DialogContext():SetTitle(LuaText.relationtree_visit_title):SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCallback(self, self.PopUpBoxInvetTogetherHandle)
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
        end
      else
        self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_REQUEST_VISIT)
      end
      return
    end
  elseif self.ItemData.RelationTreeTypeDefault == UserEnum.RLTTD_INVITE then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      self:OnRequestAccessOrInvitation(FriendEnum.TAB_TYPE.Invitation)
      return
    end
  end
end

function UMG_RelationTree_Item_C:GetNeedUnlockEnumOpation(Opation)
  local ItemState = 1
  local UserEnum = Enum.RelationTreeType
  if self.ItemData.RelationTreeType == UserEnum.RLTT_ADDFRIEND then
    if Opation == EnumOpationState.GetState then
      if self.ItemData.Unlock then
        ItemState = 2
      else
        ItemState = 1
      end
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      if 2 == self.State then
        _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
        local ItemData = {
          RelationTreeType = 100001,
          StateStruct = {}
        }
        table.insert(ItemData.StateStruct, self.ItemData.StateStruct[self.State])
        _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.OpenRelationTreeTipsPanel, ItemData)
      end
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_CHAT then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      if 1 == self.State then
        _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanel, self.PlayerUid, nil, true)
      end
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_GIFTEGG then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      self:SendPetEgg(self.ItemData.StateStruct[self.State].actionID)
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_SHAREPET then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.OpenRelationTreeTipsPanel, self.ItemData)
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_RECOVER then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.OpenRelationTreeTipsPanel, self.ItemData)
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_HIGHFIVE then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ApplyDoubleAction, self.PlayerUid, ProtoEnum.InteractInviteType.IIT_HIGHFIVE, self.ItemData.StateStruct[self.State].actionID)
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_HUGE then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ApplyDoubleAction, self.PlayerUid, ProtoEnum.InteractInviteType.IIT_HUGE, self.ItemData.StateStruct[self.State].actionID)
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_INVITE_TOGETHER then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        local isPlayerExitVisitor = false
        local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
        for k, v in ipairs(visitorList) do
          if v.uin == tonumber(self.PlayerUid) then
            isPlayerExitVisitor = true
          end
        end
        if isPlayerExitVisitor then
          self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER)
        elseif #visitorList >= 4 then
          local Text = LuaText.online_invite_num_full_cannot_hand_now
          if Text then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
          end
          return
        else
          self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER)
        end
      else
        self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER)
      end
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_REQUEST_TOGETHER then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        local isPlayerExitVisitor = false
        local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
        for k, v in ipairs(visitorList) do
          if v.uin == tonumber(self.PlayerUid) then
            isPlayerExitVisitor = true
          end
        end
        if isPlayerExitVisitor then
          self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER)
        else
          self.TogetherType = ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER
          local TipsContent = LuaText.online_apply_num_full_cannot_hand_now
          local dialogContext = DialogContext():SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCallback(self, self.PopUpBoxInvetTogetherHandle)
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
        end
      else
        self:InvetTogetherHandle(ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER)
      end
      return
    end
  elseif self.ItemData.RelationTreeType == UserEnum.RLTT_ARM then
    if Opation == EnumOpationState.GetState then
      return ItemState
    elseif Opation == EnumOpationState.Implement then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
      _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ApplyDoubleAction, self.PlayerUid, ProtoEnum.InteractInviteType.IIT_ARM, self.ItemData.StateStruct[self.State].actionID)
      return
    end
  end
end

function UMG_RelationTree_Item_C:SendPetEgg(actionId)
  local canSendEggTimes = _G.NRCModeManager:DoCmd(RelationTreeCmd.CanSendEggTimes)
  if not canSendEggTimes then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.RLTT_Giftegg_text_limit_2)
    return
  end
  local ordinaryEggNum = 0
  local items = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagEggItemWithoutHathcing)
  if items and #items > 0 then
    for i, bagItem in pairs(items) do
      if bagItem and bagItem.conf and bagItem.egg_data then
        local eggId = bagItem.conf.item_behavior[1].ratio[1]
        local eggConf = _G.DataConfigManager:GetPetEggConf(eggId)
        if eggConf and eggConf.precious_egg_type and eggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_NONE then
          ordinaryEggNum = ordinaryEggNum + 1
          break
        end
      end
    end
  end
  if 0 == ordinaryEggNum then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.relationtree_give_egg_lack_egg)
    return
  end
  local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
  if playerInfo then
    local panelData = require("NewRoco.Modules.System.RelationTree.Res.RelationEggPanelData")
    if panelData then
      panelData:SetType(panelData.EggPanelType.Presentation)
      panelData:SetArgData({
        targetUin = playerInfo.uin,
        targetName = playerInfo.name,
        actionId = actionId
      })
      _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.OpenRelationEggBag, panelData)
    end
  end
end

function UMG_RelationTree_Item_C:GetEnumOpation(Opation)
  if self.ItemData then
    if self.ItemData.RelationTreeTypeDefault == Enum.RelationTreeTypeDefault.RLTTD_NONE then
      if Opation == EnumOpationState.GetState then
        return self:GetNeedUnlockEnumOpation(Opation)
      else
        self:GetNeedUnlockEnumOpation(Opation)
      end
    elseif Opation == EnumOpationState.GetState then
      return self:GetDefaultEnumOpation(Opation)
    else
      self:GetDefaultEnumOpation(Opation)
    end
  end
end

function UMG_RelationTree_Item_C:OnDeleteUnlockRelationTreeNode()
  local name = self.ItemData.StateStruct[self.State].name
  local _Id = "RelationTree_Unlock_Node_text_1"
  local Text = _G.DataConfigManager:GetLocalizationConf(_Id).msg
  local TipsContent = string.format(Text, name)
  if self.ItemData.UnlockCost > 0 then
    _Id = "RelationTree_Unlock_Node_text_2"
    Text = _G.DataConfigManager:GetLocalizationConf(_Id).msg
    TipsContent = string.format(Text, self.ItemData.UnlockCost, name)
  end
  local PopupData = {
    PlayerUin = self.PlayerUid,
    RelationTreeType = self.ItemData.RelationTreeType,
    UnLockText = TipsContent,
    CostNum = self.ItemData.UnlockCost
  }
  NRCModuleManager:DoCmd(RelationTreeCmd.OpenUnlockInvitationPopup, PopupData)
end

function UMG_RelationTree_Item_C:OnRequestAccessOrInvitation(reqType)
  if reqType == FriendEnum.TAB_TYPE.RequestAccess or reqType == FriendEnum.TAB_TYPE.Invitation then
    local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
    local OnlineConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
    local UnlockLevel = 15
    for i = 1, #OnlineConf do
      if OnlineConf[i].key == "online_unlock_role_level" then
        UnlockLevel = OnlineConf[i].num
        break
      end
    end
    local PlayerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
    if UnlockLevel > PlayerLevel then
      self.ClickMsg = string.format(_G.DataConfigManager:GetLocalizationConf("cant_online_apply_mine").msg, UnlockLevel)
    end
    local Level = playerInfo and playerInfo.level or 0
    if UnlockLevel > Level then
      self.ClickMsg = _G.DataConfigManager:GetLocalizationConf("cant_online_apply_other").msg
    end
    if reqType == FriendEnum.TAB_TYPE.RequestAccess then
      if self.ClickMsg then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.ClickMsg)
        return
      end
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.ReqZonePlayerInteract, self.PlayerUid, ProtoEnum.PlayerInteractType.Visiting)
    elseif reqType == FriendEnum.TAB_TYPE.Invitation then
      if self.ClickMsg then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.ClickMsg)
        return
      end
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.ReqZonePlayerInteract, self.PlayerUid, ProtoEnum.PlayerInteractType.InviteVisiting)
    end
  end
end

function UMG_RelationTree_Item_C:ItemUnlockEffect(PlayerUin, RelationType)
  if self.ItemData and self.ItemData.RelationTreeType and self.ItemData.RelationTreeType == RelationType and self.PlayerUid == PlayerUin then
    if self.ItemData.ForwardUnlockState then
      _G.NRCAudioManager:PlaySound2DAuto(41501001, "UMG_RelationTree_Item_C:Unlockable_to_Unlocked")
      self:StopAnimation(self.WaitForResponse)
      self:PlayAnimation(self.WaitForResponse_Out)
      self.Select:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.Select2:SetVisibility(UE4.ESlateVisibility.Hidden)
      self:PlayAnimation(self.Unlockable_to_Unlocked)
    elseif not self.ItemData.Unlock then
      if self.ItemData and self.ItemData.StateStruct[self.State].icon then
        self.headPortrait:SetPath(self.ItemData.StateStruct[self.State].icon)
      end
      _G.NRCAudioManager:PlaySound2DAuto(41501003, "UMG_RelationTree_Item_C:Unlock_to_Unlockable")
      self:PlayAnimation(self.Unlock)
    end
  end
end

function UMG_RelationTree_Item_C:OnAnimationFinished(anim)
  if anim == self.Select1 then
  elseif anim == self.WaitForResponse_In then
    self:PlayAnimation(self.WaitForResponse, 0, 0)
  elseif anim == self.Unlock then
    local isUnlock = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetPeerRelationTreeNodeState, self.PlayerUid, self.ItemData.RelationTreeType, true)
    if not isUnlock then
      local ItemData = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurrentNodeValueByType, self.PlayerUid, self.ItemData.RelationTreeType)
      self:OnItemUpdate(ItemData)
    else
      _G.NRCAudioManager:PlaySound2DAuto(41501001, "UMG_RelationTree_Item_C:Unlockable_to_Unlocked")
      self.Select:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.Select2:SetVisibility(UE4.ESlateVisibility.Hidden)
      self:PlayAnimation(self.Unlockable_to_Unlocked)
    end
  elseif anim == self.Unlockable_to_Unlocked then
    local isUnlock = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetPeerRelationTreeNodeState, self.PlayerUid, self.ItemData.RelationTreeType, true)
    if isUnlock then
      if self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_ADDFRIEND then
        self:PlayAnimation(self.Icon_cut_1)
      else
        self:AnimationUnlockableToUnlockedAndFriendCut()
      end
    end
  elseif anim == self.Icon_cut_1 then
    self.headPortrait:SetPath(self.ItemData.StateStruct[2].icon)
    self:PlayAnimation(self.Icon_cut_2)
  elseif anim == self.Icon_cut_2 then
    self:AnimationUnlockableToUnlockedAndFriendCut()
  end
end

function UMG_RelationTree_Item_C:AnimationUnlockableToUnlockedAndFriendCut()
  if self.ItemData then
    if 1 == self.ItemData.NodeType then
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, self.PlayerUid, self.ItemData.RelationTreeType)
      local NextNode = self.module:GetNextNode(self.PlayerUid, self.ItemData.ID)
      if NextNode then
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, self.PlayerUid, NextNode.RelationTreeType)
      end
      local ItemData = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurrentNodeValueByType, self.PlayerUid, self.ItemData.RelationTreeType)
      self:OnItemUpdate(ItemData)
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UpdateCostPanel)
    else
      local NextNode = self.module:GetNextNode(self.PlayerUid, self.ItemData.ID)
      if NextNode then
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, self.PlayerUid, NextNode.RelationTreeType)
      end
      local ItemData = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurrentNodeValueByType, self.PlayerUid, self.ItemData.RelationTreeType)
      self:OnItemUpdate(ItemData)
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UpdateCostPanel)
    end
  end
end

function UMG_RelationTree_Item_C:RefreshNoteGaryMask()
  self.Mask:SetVisibility(self:NodeIsGaryMask() and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_RelationTree_Item_C:NodeIsGaryMask()
  if self.ItemData and self.ItemData.RelationTreeType == Enum.RelationTreeType.RLTT_GIFTEGG then
    local canSendEggTimes = _G.NRCModeManager:DoCmd(RelationTreeCmd.CanSendEggTimes)
    return not canSendEggTimes
  end
  return false
end

function UMG_RelationTree_Item_C:InvetTogetherHandle(Type)
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ApplyDoubleAction, self.PlayerUid, Type, self.ItemData.StateStruct[self.State].actionID)
end

function UMG_RelationTree_Item_C:PopUpBoxInvetTogetherHandle(_ok)
  if _ok and self.TogetherType then
    self:InvetTogetherHandle(self.TogetherType)
  else
  end
end

function UMG_RelationTree_Item_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_ITEM_UNLOCK_EFFECT, self.ItemUnlockEffect)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_ITEM_UNLOCK_CANCEL_EFFECT, self.OnlyPlayerWaitForResponse_Out)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.UpdateCostPanel, self.UpdateCostPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnTodaySendEggTimesUpdate, self.RefreshNoteGaryMask)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, self.UpdateInviteAnim)
end

return UMG_RelationTree_Item_C

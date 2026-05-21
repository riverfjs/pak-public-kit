local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local RelationTreeModule = NRCModuleBase:Extend("RelationTreeModule")

function RelationTreeModule:OnConstruct()
  self.OldRelationTreeUnlockNode = {}
  self.RelationItemSelectCD = 0
  _G.RelationTreeCmd = reload("NewRoco.Modules.System.RelationTree.RelationTreeCmd")
  self.data = self:SetData("RelationTreeData", "NewRoco.Modules.System.RelationTree.RelationTreeData")
end

function RelationTreeModule:OnActive()
  self:RegisterRelationTreeEvent(true)
  self:RegisterRelationTreeCMD()
  self:RegRelationTreePanel()
  self:RegisterRelationTreeProto(true)
  self:RegisterPetRelationTreeCMD()
  self:RegPetRelationTreePanel()
end

function RelationTreeModule:RegisterRelationTreeCMD()
  self:RegisterCmd(RelationTreeCmd.OpenRelationCover, self.OnZoneRelationShipTreeReq)
  self:RegisterCmd(RelationTreeCmd.CloseRelationCover, self.OnCmdCloseRelationTreePanel)
  self:RegisterCmd(RelationTreeCmd.GetRelationTreeIsOpenAndClose, self.GetRelationTreeIsOpenAndClose)
  self:RegisterCmd(RelationTreeCmd.RestRelationTreeCloseState, self.RestRelationTreeCloseState)
  self:RegisterCmd(RelationTreeCmd.OpenUnlockInvitationPopup, self.OpenUnlockInvitationPopup)
  self:RegisterCmd(RelationTreeCmd.CloseUnlockInvitationPopup, self.CloseUnlockInvitationPopup)
  self:RegisterCmd(RelationTreeCmd.UnlockRelationShipNodeReq, self.UnlockRelationShipNodeReq)
  self:RegisterCmd(RelationTreeCmd.ConfrimUnlockRelationShipNodeReq, self.OnZoneConfirmUnlockRelationShipNodeReq)
  self:RegisterCmd(RelationTreeCmd.UpdateShowMoreClick, self.UpdateShowMoreClick)
  self:RegisterCmd(RelationTreeCmd.CancelUnlockRelationshipNodeReq, self.OnZoneCancelUnlockRelationshipNodeReq)
  self:RegisterCmd(RelationTreeCmd.CancelUnlockRelationshipNodeReqAndInvite, self.CancelUnlockRelationshipNodeReqAndInvite)
  self:RegisterCmd(RelationTreeCmd.GetOtherRequestsByUin, self.GetOtherRequestsByUin)
  self:RegisterCmd(RelationTreeCmd.GetAllOtherRequests, self.GetAllOtherRequests)
  self:RegisterCmd(RelationTreeCmd.GetRelationTreeNodeByEnum, self.GetRelationTreeNodeByEnum)
  self:RegisterCmd(RelationTreeCmd.GetRelationTreeNode, self.GetRelationTreeNode)
  self:RegisterCmd(RelationTreeCmd.GetCurRequestPlayerUID, self.GetCurRequestPlayerUID)
  self:RegisterCmd(RelationTreeCmd.GetCurrentNodeValueByType, self.GetCurrentNodeValueByType)
  self:RegisterCmd(RelationTreeCmd.UpdateRelationTreeUI, self.OnUpdateRelationTreeUI)
  self:RegisterCmd(RelationTreeCmd.OpenRelationTreeTipsPanel, self.OpenRelationTreeTipsPanel)
  self:RegisterCmd(RelationTreeCmd.CloseRelationTreeTipsPanel, self.CloseRelationTreeTipsPanel)
  self:RegisterCmd(RelationTreeCmd.ApplyDoubleAction, self.ApplyDoubleAction)
  self:RegisterCmd(RelationTreeCmd.GetMyRequest, self.GetMyRequest)
  self:RegisterCmd(RelationTreeCmd.GetMoreElementData, self.GetMoreElementData)
  self:RegisterCmd(RelationTreeCmd.GetCurrentNodeApplied, self.GetCurrentNodeApplied)
  self:RegisterCmd(RelationTreeCmd.GetPeerRelationTreeNodeState, self.GetPeerRelationTreeNodeState)
  self:RegisterCmd(RelationTreeCmd.SetRelationItemSelectCD, self.SetRelationItemSelectCD)
  self:RegisterCmd(RelationTreeCmd.GetRelationItemSelectCD, self.GetRelationItemSelectCD)
  self:RegisterCmd(RelationTreeCmd.GetOpenPlayerInfo, self.GetOpenPlayerInfo)
  self:RegisterCmd(RelationTreeCmd.GetCurPlayerUID, self.GetCurPlayerUID)
  self:RegisterCmd(RelationTreeCmd.DynamicAddEventListener, self.DynamicAddRelationMoreEventListener)
  self:RegisterCmd(RelationTreeCmd.OpenRelationEggBag, self.OpenRelationEggBag)
  self:RegisterCmd(RelationTreeCmd.CloseRelationEggBag, self.CloseRelationEggBag)
  self:RegisterCmd(RelationTreeCmd.ApplyBlessingEgg, self.OnApplyBlessingEgg)
  self:RegisterCmd(RelationTreeCmd.IsShowEggTips, self.IsShowEggTips)
  self:RegisterCmd(RelationTreeCmd.GetPetEvoGroupFirstBaseIds, self.GetPetEvoGroupFirstBaseIds)
  self:RegisterCmd(RelationTreeCmd.OpenRelationPetPreview, self.OpenRelationPetPreview)
  self:RegisterCmd(RelationTreeCmd.OpenComplimentaryPetEggs, self.OpenComplimentaryPetEggs)
  self:RegisterCmd(RelationTreeCmd.CloseComplimentaryPetEggs, self.CloseComplimentaryPetEggs)
  self:RegisterCmd(RelationTreeCmd.OnZoneQueryGiftingEggTimesReq, self.OnZoneQueryGiftingEggTimesReq)
  self:RegisterCmd(RelationTreeCmd.CanSendEggTimes, self.CanSendEggTimes)
  self:RegisterCmd(RelationTreeCmd.OnGivePetEggStar, self.OnGivePetEggReq)
  self:RegisterCmd(RelationTreeCmd.RelationTreeSendTLog, self.RelationTreeSendTLog)
  self:RegisterCmd(RelationTreeCmd.SetCurOpenPanelPlayerUID, self.SetCurOpenPanelPlayerUID)
  self:RegisterCmd(RelationTreeCmd.SetOpenPlayerInfo, self.SetOpenPlayerInfo)
  self:RegisterCmd(RelationTreeCmd.SetCurOtherLevelData, self.SetCurOtherLevelData)
  self:RegisterCmd(RelationTreeCmd.SetCurUnLockMaxFloor, self.SetCurUnLockMaxFloor)
  self:RegisterCmd(RelationTreeCmd.AddFriendBlackCloseRelationTree, self.AddFriendBlackCloseRelationTree)
  _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
end

function RelationTreeModule:RegisterPetRelationTreeCMD()
  self:RegisterCmd(RelationTreeCmd.OpenPetRelationCover, self.OpenPetRelationCover)
  self:RegisterCmd(RelationTreeCmd.ClosePetRelationCover, self.ClosePetRelationCover)
  self:RegisterCmd(RelationTreeCmd.GetPetRelationTreeData, self.GetPetRelationTreeData)
  self:RegisterCmd(RelationTreeCmd.GetPetRelationTreeUIData, self.GetPetRelationTreeUIData)
  self:RegisterCmd(RelationTreeCmd.GetPetInfoData, self.GetPetInfoData)
  self:RegisterCmd(RelationTreeCmd.SearchPetReq, self.SearchPetReq)
  self:RegisterCmd(RelationTreeCmd.SetPetRelationTreeUIData, self.SetPetRelationTreeUIData)
  self:RegisterCmd(RelationTreeCmd.SetPetInfoData, self.SetPetInfoData)
  self:RegisterCmd(RelationTreeCmd.SetCurOpenPetPanelPlayerUin, self.SetCurOpenPetPanelPlayerUin)
  self:RegisterCmd(RelationTreeCmd.GetCurOpenPetPanelPlayerUin, self.GetCurOpenPetPanelPlayerUin)
  self:RegisterCmd(RelationTreeCmd.SetCurOpenPetPanelPlayerName, self.SetCurOpenPetPanelPlayerName)
  self:RegisterCmd(RelationTreeCmd.GetCurOpenPetPanelPlayerName, self.GetCurOpenPetPanelPlayerName)
  self:RegisterCmd(RelationTreeCmd.HasRelationTreePanel, self.HasRelationTreePanel)
  self:RegisterCmd(RelationTreeCmd.OpenRelationTreeMedalPopUp, self.OpenRelationTreeMedalPopUp)
  self:RegisterCmd(RelationTreeCmd.OpenRelationTreeMedalDetail, self.OpenShiningMedalDetail)
  self:RegisterCmd(RelationTreeCmd.OpenRelationTreeIntimacyTipsPanel, self.OpenRelationTreeIntimacyTipsPanel)
  self:RegisterCmd(RelationTreeCmd.CloseRelationTreeIntimacyTipsPanel, self.CloseRelationTreeIntimacyTipsPanel)
  self:RegisterCmd(RelationTreeCmd.GetRelationTreeIntimacyTipsPanel, self.GetRelationTreeIntimacyTipsPanel)
  self:RegisterCmd(RelationTreeCmd.GetPetFashionBondID, self.GetPetFashionBondID)
  self:RegisterCmd(RelationTreeCmd.GetBondInteractID, self.GetBondInteractID)
  self:RegisterCmd(RelationTreeCmd.GetFashionSuitIsCanBuy, self.GetFashionSuitIsCanBuy)
  self:RegisterCmd(RelationTreeCmd.GetSelfIsHaveBondID, self.GetSelfIsHaveBondID)
  self:RegisterCmd(RelationTreeCmd.GetPetBondFirstClick, self.GetPetBondFirstClick)
  self:RegisterCmd(RelationTreeCmd.GetFashionSuitBuyState, self.GetFashionSuitBuyState)
  self:RegisterCmd(RelationTreeCmd.StartCloseRolePlayFromRelationTree, self.StartCloseRolePlayFromRelationTree)
  self:RegisterCmd(RelationTreeCmd.GetPlayingCloseBondId, self.GetPlayingCloseBondId)
  self:RegisterCmd(RelationTreeCmd.ResetCloseRolePlayFromRelationTree, self.ResetCloseRolePlayFromRelationTree)
  self:RegisterCmd(RelationTreeCmd.GetColorSuitState, self.GetColorSuitState)
  self:RegisterCmd(RelationTreeCmd.GetPetBondColorSuitState, self.GetPetBondColorSuitState)
  self:RegisterCmd(RelationTreeCmd.OpenGiftReminder, self.OpenGiftReminder)
  self:RegisterCmd(RelationTreeCmd.SetOpeningRelationPanel, self.SetOpeningRelationPanel)
  self:RegisterCmd(RelationTreeCmd.GetOpeningRelationPanel, self.GetOpeningRelationPanel)
end

function RelationTreeModule:RegRelationTreePanel()
  self:RegPanel("RelationTree", "UMG_RelationTree", _G.Enum.UILayerType.UI_LAYER_MAIN, true, "In", "Out", false, false)
  self:RegPanel("RelationTreeTips", "UMG_RelationTree_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, true, "Appear", "Disappear")
  self:RegPanel("UnlockInvitationPopup", "UMG_UnlockInvitation_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, true, "In", "Out", true)
  self:RegPanel("RelationTreeEggBag", "UMG_RelationTreeEggs", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, true)
  self:RegPanel("ComplimentaryPetEggs", "UMG_ComplimentaryPetEggs", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, true)
  self:RegPanel("ShiningMedalPopUp", "UMG_RelationTree_ShiningMedal", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, true)
  self:RegPanel("ShiningMedalDetail", "UMG_RelationTree_ShiningMedal", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, true)
end

function RelationTreeModule:RegPetRelationTreePanel()
  self:RegPanel("PetRelationTree", "UMG_RelationTree_Pet", _G.Enum.UILayerType.UI_LAYER_MAIN, true, "In", "Out", false, false)
  self:RegPanel("RelationTreeIntimacyTips", "UMG_RelationTree_IntimacyTips", _G.Enum.UILayerType.UI_LAYER_POPUP, true, "Appear", "Disappear")
  self:RegPanel("GiftReminder", "UMG_GiftReminder", _G.Enum.UILayerType.UI_LAYER_POPUP, false, "In", "Out", true, true)
  self:RegPanel("GiftReminderFullScreen", "UMG_GiftReminder", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true, "In", "Out", true, true)
end

function RelationTreeModule:RegisterRelationTreeEvent(isActive)
  if isActive then
    _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
    _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpened)
    _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClosed)
    _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, _G.SceneEvent.OnPreTeleportNotify, self.OnZoneCancelUnlockRelationshipNodeReq)
    _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, RelationTreeEvent.TwoPeopleActionPlayCompleted, self.OnTwoPeopleActionPlayCompleted)
    _G.NRCEventCenter:RegisterEvent("RelationTreeModule", self, MagicReplayModuleEvent.EnterPreviewState, self.OnEnterMagicReplayState)
  else
    _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.EnterPreviewState, self.OnEnterMagicReplayState)
    _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
    _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpened)
    _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClosed)
    _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnPreTeleportNotify, self.OnZoneCancelUnlockRelationshipNodeReq)
    _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.TwoPeopleActionPlayCompleted, self.OnTwoPeopleActionPlayCompleted)
  end
end

function RelationTreeModule:RegisterRelationTreeProto(isActive)
  if isActive then
    _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RELATIONSHIP_TREE_CHANGED_NOTIFY, self.RelationTreeChangeNotify)
    _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RELATIONSHIP_REQ_UNLOCK_NOTIFY, self.RelationShipReqUnLockNotify)
    _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RELATIONSHIP_CANCEL_UNLOCK_NOTIFY, self.RelationShipCancelUnlockNotify)
  else
    _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RELATIONSHIP_TREE_CHANGED_NOTIFY, self.RelationTreeChangeNotify)
    _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RELATIONSHIP_REQ_UNLOCK_NOTIFY, self.RelationShipReqUnLockNotify)
    _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RELATIONSHIP_CANCEL_UNLOCK_NOTIFY, self.RelationShipCancelUnlockNotify)
  end
end

function RelationTreeModule:OnLogin(isRelogin)
  if isRelogin then
  end
end

function RelationTreeModule:OnReconnect()
  if self.data then
    if self.data:GetMyRequests() then
      self:OnZoneCancelUnlockRelationshipNodeReq()
    end
    self.data:ClearOtherRequests()
  end
  self:CloseRelationTreePanel()
end

function RelationTreeModule:OnLoadingUIOpened()
  if self:HasPanel("RelationTree") then
    local PlayerUin = self:GetCurPlayerUID()
    self:OnCmdCloseRelationTreePanel(PlayerUin)
  end
  if self:HasPanel("PetRelationTree") then
    self:ClosePetRelationCover()
  end
end

function RelationTreeModule:OnLoadingUIClosed()
  if self:HasPanel("RelationTree") then
    local PlayerUin = self:GetCurPlayerUID()
    self:OnCmdCloseRelationTreePanel(PlayerUin)
  end
  if self:HasPanel("PetRelationTree") then
    self:ClosePetRelationCover()
  end
end

function RelationTreeModule:OnEnterBattle()
  if self:HasPanel("RelationTree") then
    local PlayerUin = self:GetCurPlayerUID()
    self:OnCmdCloseRelationTreePanel(PlayerUin)
  end
  if self:HasPanel("PetRelationTree") then
    self:ClosePetRelationCover()
  end
  if self:HasPanel("RelationTreeEggBag") then
    self:ClosePanel("RelationTreeEggBag")
  end
end

function RelationTreeModule:OnEnterMagicReplayState()
  if self:HasPanel("RelationTree") then
    local PlayerUin = self:GetCurPlayerUID()
    self:OnCmdCloseRelationTreePanel(PlayerUin)
  end
  if self:HasPanel("PetRelationTree") then
    self:ClosePetRelationCover()
  end
  if self:HasPanel("RelationTreeEggBag") then
    self:ClosePanel("RelationTreeEggBag")
  end
end

function RelationTreeModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, enablePcEsc, isSingleTouchPanel)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/RelationTree/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function RelationTreeModule:OpenUnlockInvitationPopup(CommonPopUpData)
  if CommonPopUpData then
    self:OpenPanel("UnlockInvitationPopup", CommonPopUpData)
  end
  if self:HasPanel("RelationTreeEggBag") then
    local p = self:GetPanel("RelationTreeEggBag")
    p:SetHiddenMoney(true)
  end
end

function RelationTreeModule:CloseUnlockInvitationPopup()
  if self:HasPanel("UnlockInvitationPopup") then
    self:ClosePanel("UnlockInvitationPopup")
  end
  if self:HasPanel("RelationTreeEggBag") then
    local p = self:GetPanel("RelationTreeEggBag")
    p:SetHiddenMoney(false)
  end
end

function RelationTreeModule:OpenRelationTreePanel(arg)
  if not self:HasPanel("RelationTree") and not _G.BattleManager:IsInBattle() then
    self:SetCurOpenPanelPlayerUID(arg)
    self:DoOpenRelationTreePanel()
  end
end

function RelationTreeModule:DoOpenRelationTreePanel(...)
  self:SetOpeningRelationPanel(true)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_OPEN_PLAYER_RELATIONSHIP_TREE)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, true)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OffSetNPCInteractObjectList, false)
  self:OpenPanel("RelationTree", ...)
end

function RelationTreeModule:CloseRelationTreePanel()
  if self:HasPanel("RelationTree") then
    self:ClosePanel("RelationTree")
  end
end

function RelationTreeModule:RestRelationTreeCloseState()
  self.isClosing = false
end

function RelationTreeModule:GetRelationTreeIsOpenAndClose()
  if self:HasPanel("RelationTree") then
    local panel = self:GetPanel("RelationTree")
    if not self.isClosing then
      panel:OnCloseClick()
      self.isClosing = true
    end
  end
end

function RelationTreeModule:OpenRelationTreeIntimacyTipsPanel(playeruin, petinfo)
  local req = _G.ProtoMessage:newZoneQueryNpcPetDataReq()
  req.target_uin = playeruin
  req.target_pet_gid = petinfo.PetInfo and petinfo.PetInfo.serverData and petinfo.PetInfo.serverData.pet_info and petinfo.PetInfo.serverData.pet_info.gid or 0
  req.target_pet_npc_id = petinfo.PetInfo.serverData and petinfo.PetInfo.serverData.base and petinfo.PetInfo.serverData.base.logic_id or 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_NPC_PET_DATA_REQ, req, self, self.OpenRelationTreeIntimacyTipsPanel_Enter)
end

function RelationTreeModule:OpenRelationTreeIntimacyTipsPanel_Enter(Rsp)
  if Rsp.ret_info and 0 == Rsp.ret_info.ret_code and not self:HasPanel("RelationTreeIntimacyTips") then
    self:SetPetInfoData(Rsp.target_pet_data)
    self:OpenPanel("RelationTreeIntimacyTips")
  end
end

function RelationTreeModule:CloseRelationTreeIntimacyTipsPanel()
  if self:HasPanel("RelationTreeIntimacyTips") then
    _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
    self:ClosePanel("RelationTreeIntimacyTips")
    if self:HasPanel("PetRelationTree") then
      local panel = self:GetPanel("PetRelationTree")
      panel:CloseClosenessDetailUI()
    end
  end
end

function RelationTreeModule:GetRelationTreeIntimacyTipsPanel()
  if self:HasPanel("RelationTreeIntimacyTips") then
    return self:GetPanel("RelationTreeIntimacyTips")
  end
  return nil
end

function RelationTreeModule:OpenRelationTreeTipsPanel(relationItem)
  if not self:HasPanel("RelationTreeTips") then
    _G.NRCAudioManager:PlaySound2DAuto(41400002, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
    self:OpenPanel("RelationTreeTips", relationItem)
    if self:HasPanel("RelationTree") then
      local RelationTreePanel = self:GetPanel("RelationTree")
      RelationTreePanel:UnBindInputSpecialAction()
    else
    end
  end
end

function RelationTreeModule:CloseRelationTreeTipsPanel()
  if self:HasPanel("RelationTreeTips") then
    _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_RelationTree_Item_C:UseRelationNodeSendInvite")
    self:ClosePanel("RelationTreeTips")
    if self:HasPanel("RelationTree") then
      local RelationTreePanel = self:GetPanel("RelationTree")
      RelationTreePanel:BindInputAction()
    end
  end
end

function RelationTreeModule:OnCmdCloseRelationTreePanel(PlayerUid)
  self:OnZoneCloseRelationShipTreeReq(PlayerUid)
end

function RelationTreeModule:AddFriendBlackCloseRelationTree(uin)
  local target_uin = self:GetCurPlayerUID()
  local pet_target_uin = self:GetCurOpenPetPanelPlayerUin()
  if target_uin and uin == target_uin then
    self:OnCmdCloseRelationTreePanel(target_uin)
  elseif pet_target_uin and uin == pet_target_uin then
    self:ClosePetRelationCover()
  end
end

function RelationTreeModule:UpdateShowMoreClick()
  if self:HasPanel("RelationTree") then
    local panel = self:GetPanel("RelationTree")
    panel:CollapsedMoreUI()
  end
end

function RelationTreeModule:DynamicAddRelationMoreEventListener()
  if self:HasPanel("RelationTree") then
    local panel = self:GetPanel("RelationTree")
    panel:DynamicAddEventListener()
  end
end

function RelationTreeModule:OnUpdateRelationTreeUI(IsAnim)
  if self:HasPanel("RelationTree") then
    local panel = self:GetPanel("RelationTree")
    panel:UpdateUI(IsAnim)
  end
end

function RelationTreeModule:GetRelationTreeNode(OtherPlayerId)
  if self.data then
    local RelationTreeData = self.data:GetRelationTreeNode(OtherPlayerId)
    self:SetCurUnLockMaxFloor(RelationTreeData.MaxUnLockFloor)
    self:SetCurOtherLevelData(RelationTreeData.OterLevelData)
    return RelationTreeData
  end
  return nil
end

function RelationTreeModule:GetCurrentNodeValueByType(OtherPlayerUID, NodeRelationType)
  if OtherPlayerUID and NodeRelationType then
    local RelationTreeData = self.data:GetRelationTreeNode(OtherPlayerUID, true)
    for _, floorvalue in ipairs(RelationTreeData.RelationTree) do
      for _, nodevalue in ipairs(floorvalue) do
        if nodevalue.RelationTreeType == NodeRelationType then
          return nodevalue
        end
      end
    end
  end
end

function RelationTreeModule:GetNextMasterNode(PlayerUID, NodeID)
  if PlayerUID and NodeID then
    local RelationTreeData = self.data:GetRelationTreeNode(PlayerUID, true)
    for _, floorvalue in ipairs(RelationTreeData.RelationTree) do
      for _, nodevalue in ipairs(floorvalue) do
        if 1 == nodevalue.NodeType and nodevalue.ForwardNodeID == NodeID then
          return nodevalue
        end
      end
    end
  end
  return nil
end

function RelationTreeModule:GetNextNode(PlayerUID, NodeID)
  if PlayerUID and NodeID then
    local RelationTreeData = self.data:GetRelationTreeNode(PlayerUID, true)
    for _, floorvalue in ipairs(RelationTreeData.RelationTree) do
      for _, nodevalue in ipairs(floorvalue) do
        if nodevalue.ForwardNodeID == NodeID and 1 ~= nodevalue.NodeType then
          return nodevalue
        end
      end
    end
  end
  return nil
end

function RelationTreeModule:GetNodeValueByID(PlayerUID, NodeID)
  if PlayerUID and NodeID then
    local RelationTreeData = self.data:GetRelationTreeNode(PlayerUID, true)
    for _, floorvalue in ipairs(RelationTreeData.RelationTree) do
      for _, nodevalue in ipairs(floorvalue) do
        if nodevalue.ID == NodeID then
          return nodevalue
        end
      end
    end
  end
  return nil
end

function RelationTreeModule:GetMoreElementData(IsFriend)
  local BasicTable = self.data:GetRelationTreeBasicTable(true)
  for i = #BasicTable, 1, -1 do
    if BasicTable[i].FriendNeed and not IsFriend then
      table.remove(BasicTable, i)
    end
  end
  return BasicTable
end

function RelationTreeModule:GetCurrentNodeApplied(OtherPlayerUID, NodeRelationType)
  if self.data then
    local OtherRequestsData = self.data:GetOtherRequestsData()
    if OtherRequestsData and OtherRequestsData[OtherPlayerUID] then
      return OtherRequestsData[OtherPlayerUID] == NodeRelationType
    else
      return false
    end
  end
  return false
end

function RelationTreeModule:GetRelationTreeNodeByEnum(RelationType)
  if self.data then
    local RelationTreeNode = self.data:GetRelationTreeNodeByEnum(RelationType)
    if RelationTreeNode then
      return RelationTreeNode
    end
  end
  return nil
end

function RelationTreeModule:GetOtherRequestsByUin(OtherPlayerUID)
  if self.data then
    local OtherRequestsData = self.data:GetOtherRequestsData()
    if OtherRequestsData and OtherRequestsData[OtherPlayerUID] then
      return OtherRequestsData[OtherPlayerUID]
    end
  end
  return nil
end

function RelationTreeModule:GetAllOtherRequests()
  if self.data then
    local OtherRequestsData = self.data:GetOtherRequestsData()
    if OtherRequestsData and table.getTableCount(OtherRequestsData) > 0 then
      return OtherRequestsData
    end
  end
  return nil
end

function RelationTreeModule:GetMyRequest()
  if self.data then
    local MyRequests = self.data:GetMyRequests()
    if MyRequests then
      return MyRequests
    end
  end
  return nil
end

function RelationTreeModule:ClearMyRequestsHandle()
  self.data:ClearMyRequests()
  self:SetCurRequestPlayerUID(nil)
end

function RelationTreeModule:RelationTreeChangeNotify(Rsp)
  if Rsp then
    local RelationShipTreeData = Rsp.tree_data
    local removeSendUnlockReq = Rsp.remove_send_unlock_req
    local removeRecvUnlockReq = Rsp.remove_recv_unlock_req
    local IsRelationshipTreeAddFriend = Rsp.relationship_tree_add_friend
    if RelationShipTreeData then
      local PlayerUid = RelationShipTreeData.peer_uin
      if not self.OldRelationTreeUnlockNode[PlayerUid] then
        self.OldRelationTreeUnlockNode[PlayerUid] = {}
      end
      if removeSendUnlockReq then
        self:ClearMyRequestsHandle()
      end
      if removeRecvUnlockReq then
        self.data:UpdateOtherRequestsData(PlayerUid, nil, true)
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, PlayerUid)
      end
      local RelationShipBits = tostring(RelationShipTreeData.relationship_bits)
      local Cnt = string.len(RelationShipBits)
      local RelationShipTreeBytesTable = {}
      for i = 1, Cnt do
        local UnlockState = string.sub(tostring(RelationShipBits), i, i)
        RelationShipTreeBytesTable[i] = tonumber(UnlockState)
        if RelationShipTreeBytesTable[Enum.RelationTreeType.RLTT_ADDFRIEND] and 0 == RelationShipTreeBytesTable[Enum.RelationTreeType.RLTT_ADDFRIEND] then
          NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_STATE_LOCK, PlayerUid, i)
        end
      end
      self.data:CheckCacheRelationTreePool(PlayerUid, RelationShipTreeBytesTable)
      local OldRelationTreeUnlockNode = self.OldRelationTreeUnlockNode[PlayerUid]
      local isDeleteFriend = false
      if OldRelationTreeUnlockNode[Enum.RelationTreeType.RLTT_ADDFRIEND] and 0 == OldRelationTreeUnlockNode[Enum.RelationTreeType.RLTT_ADDFRIEND] then
        isDeleteFriend = true
      end
      local isUnlock = false
      local isUnlockFriend = false
      local optionDeleteFriend = false
      for i = 1, #RelationShipTreeBytesTable do
        if isDeleteFriend and 1 == RelationShipTreeBytesTable[Enum.RelationTreeType.RLTT_ADDFRIEND] and i ~= Enum.RelationTreeType.RLTT_ADDFRIEND and 1 == RelationShipTreeBytesTable[i] then
          _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_STATE_UNLOCK, PlayerUid, i)
        end
        if i == Enum.RelationTreeType.RLTT_ADDFRIEND and 1 == OldRelationTreeUnlockNode[i] and 0 == RelationShipTreeBytesTable[i] then
          optionDeleteFriend = true
        end
        if not OldRelationTreeUnlockNode[i] and 1 == RelationShipTreeBytesTable[i] then
          if i == Enum.RelationTreeType.RLTT_ADDFRIEND then
            isUnlockFriend = true
          end
          isUnlock = true
          _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_STATE_UNLOCK, PlayerUid, i)
        elseif OldRelationTreeUnlockNode[i] ~= RelationShipTreeBytesTable[i] and 0 == OldRelationTreeUnlockNode[i] and 1 == RelationShipTreeBytesTable[i] then
          if i == Enum.RelationTreeType.RLTT_ADDFRIEND then
            isUnlockFriend = true
          end
          isUnlock = true
          _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_STATE_UNLOCK, PlayerUid, i)
        end
      end
      local UnlockNode = {}
      if isUnlock then
        for i = 1, #RelationShipTreeBytesTable do
          if not OldRelationTreeUnlockNode[i] and 1 == RelationShipTreeBytesTable[i] then
            local ClientNode = self:GetRelationTreeNodeByEnum(i)
            table.insert(UnlockNode, ClientNode)
          elseif OldRelationTreeUnlockNode[i] ~= RelationShipTreeBytesTable[i] and 0 == OldRelationTreeUnlockNode[i] and 1 == RelationShipTreeBytesTable[i] then
            local ClientNode = self:GetRelationTreeNodeByEnum(i)
            table.insert(UnlockNode, ClientNode)
          end
        end
      end
      if UnlockNode then
        if 1 == table.getTableCount(UnlockNode) then
          self:SendLineUnLockEffect(PlayerUid, UnlockNode[1].RelationTreeType)
        elseif table.getTableCount(UnlockNode) > 1 then
          table.sort(UnlockNode, function(a, b)
            if a.NodeFloor ~= b.NodeFloor then
              return a.NodeFloor < b.NodeFloor
            else
              return a.NodeType < b.NodeType
            end
          end)
          self:SendLineUnLockEffect(PlayerUid, UnlockNode[1].RelationTreeType)
        end
      end
      self.OldRelationTreeUnlockNode[PlayerUid] = RelationShipTreeBytesTable
      if not isUnlock then
        if removeSendUnlockReq then
          local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
          if player then
            local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
            if InviteComponent then
              InviteComponent:InviteCancel()
            end
          end
        end
        if optionDeleteFriend then
          self:OnUpdateRelationTreeUI(false)
        end
      elseif isUnlockFriend and removeSendUnlockReq and not IsRelationshipTreeAddFriend then
        local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        if player then
          local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
          if InviteComponent then
            InviteComponent:InviteCancel()
          end
        end
      end
    end
  end
end

function RelationTreeModule:SendLineUnLockEffect(PlayerUin, RelationType)
  local ClientNode = self:GetRelationTreeNodeByEnum(RelationType)
  if ClientNode then
    if 1 == ClientNode.NodeType then
      local SerNodeValue = self:GetCurrentNodeValueByType(PlayerUin, ClientNode.RelationTreeType)
      if SerNodeValue then
        local ByIdNodeValue = self:GetNodeValueByID(PlayerUin, SerNodeValue.ForwardNodeID)
        if ByIdNodeValue then
          if ByIdNodeValue.RelationTreeTypeDefault > 0 then
            _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, PlayerUin, ByIdNodeValue.RelationTreeTypeDefault, true)
          else
            _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, PlayerUin, ByIdNodeValue.RelationTreeType)
          end
        end
      end
    elseif ClientNode.RelationTreeTypeDefault > 0 then
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, PlayerUin, ClientNode.RelationTreeTypeDefault, true)
    else
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_LINE_UNLOCK_EFFECT, PlayerUin, ClientNode.RelationTreeType)
    end
  end
end

function RelationTreeModule:RelationShipReqUnLockNotify(Rsp)
  if Rsp then
    local reqPlayerUid = Rsp.req_uin
    local reqRelationShipType = Rsp.relationship_type
    local resetUnlockedData = Rsp.reset_unlocked_data
    if reqPlayerUid and reqRelationShipType then
      self.data:UpdateOtherRequestsData(reqPlayerUid, reqRelationShipType, false)
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, reqPlayerUid)
      self:OnTipOtherRequestByUin(reqPlayerUid)
      local ReqPlayerRelationTreeData = self.data:GetRelationTreePoolByUin(reqPlayerUid)
      if resetUnlockedData and ReqPlayerRelationTreeData then
        for floor, nodevalue in pairs(ReqPlayerRelationTreeData.RelationTree) do
          for nodetype, value in pairs(nodevalue) do
            if value.RelationTreeType == reqRelationShipType then
              value.Unlock = false
            end
          end
        end
      end
    end
  end
end

function RelationTreeModule:RelationShipCancelUnlockNotify(Rsp)
  if Rsp then
    local CancelPlayerUid = Rsp.cancel_uin
    local CancelRelationShipType = Rsp.relationship_type
    if CancelPlayerUid and CancelRelationShipType then
      local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
      if CancelPlayerUid == uin then
        if self.data:GetMyRequests() == CancelRelationShipType then
          self:ClearMyRequestsHandle()
          local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
          if player then
            local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
            if InviteComponent then
              InviteComponent:InviteCancel()
            end
          end
        end
      else
        self.data:UpdateOtherRequestsData(CancelPlayerUid, CancelRelationShipType, true)
      end
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, CancelPlayerUid)
    end
  end
end

function RelationTreeModule:OnZoneRelationShipTreeReq(PlayerUid, Action)
  if PlayerUid then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddInputBlockMappingContext, "RelationTreePanelOpen")
    local req = _G.ProtoMessage:newZoneOpenRelationshipTreeReq()
    req.peer_uin = PlayerUid
    self.PlayerAction = Action
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_OPEN_RELATIONSHIP_TREE_REQ, req, self, self.OnZoneOpenRelationShipTreeRsp, true, true)
  end
end

function RelationTreeModule:OnZoneOpenRelationShipTreeRsp(Rsp)
  local Text
  if Rsp then
    local RetInfo = Rsp.ret_info
    if 0 == RetInfo.ret_code then
      local RelationShipTreeBytes = Rsp.tree_data
      if RelationShipTreeBytes then
        if Rsp.peer_info then
          self:SetOpenPlayerInfo(Rsp.peer_info)
        end
        local UnlockRelationType = Rsp.unlock_relation_type and Rsp.unlock_relation_type > 0 and Rsp.unlock_relation_type or 0
        local RelationShipTreeBytesTable = {}
        local PlayerUid = RelationShipTreeBytes.peer_uin
        local LevelData = {
          peer_role_lv = Rsp.peer_role_lv,
          peer_role_world_lv = Rsp.peer_role_world_lv
        }
        if not self.OldRelationTreeUnlockNode[PlayerUid] then
          self.OldRelationTreeUnlockNode[PlayerUid] = {}
        end
        local OldRelationTreeUnlockNode = self.OldRelationTreeUnlockNode[PlayerUid]
        if RelationShipTreeBytes.relationship_bits then
          local RelationShipBits = tostring(RelationShipTreeBytes.relationship_bits)
          local Cnt = string.len(RelationShipBits)
          for i = 1, Cnt do
            local UnlockState = string.sub(tostring(RelationShipBits), i, i)
            RelationShipTreeBytesTable[i] = tonumber(UnlockState)
          end
          self.OldRelationTreeUnlockNode[PlayerUid] = RelationShipTreeBytesTable
        end
        self.data:CheckCacheRelationTreePool(PlayerUid, RelationShipTreeBytesTable, LevelData, UnlockRelationType)
        self:OpenRelationTreePanel(PlayerUid)
      end
    else
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "RelationTreePanelOpen")
      if RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_DATA_FULL then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2433").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_PLAYER_OFFLINE then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2435").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MINE_BLACK_LIMIT then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438_1").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_OTHER_BLACK_LIMIT then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438_2").msg
      end
      if Text then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      end
    end
    if self.PlayerAction then
      self.PlayerAction:Finish()
      self.PlayerAction = nil
    end
  end
end

function RelationTreeModule:UnlockRelationShipNodeReq(PlayerUid, RelationShipType)
  if PlayerUid and RelationShipType then
    local MAX_RELATION_INTERACT_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("relationtree_interact_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
    self.UnlockReq = _G.ProtoMessage:newZoneUnlockRelationshipNodeReq()
    self.UnlockReq.peer_uin = PlayerUid
    self.UnlockReq.relationship_type = RelationShipType
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not player or not player.viewObj then
      return
    end
    local MeshComp = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
    if not MeshComp then
      return
    end
    local OwnerLocation = MeshComp:Abs_K2_GetComponentLocation()
    local RequestPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, PlayerUid)
    if not RequestPlayer or RequestPlayer.isDestroy or not RequestPlayer.viewObj then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.RLTT_Error_Code_2435)
      return
    else
      local InRange = true
      local PlayerMeshComp = RequestPlayer.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
      if not PlayerMeshComp then
        InRange = false
      else
        local Dist = UE4.FVector.Dist(OwnerLocation, PlayerMeshComp:Abs_K2_GetComponentLocation())
        if MAX_RELATION_INTERACT_DISTANCE < Dist then
          InRange = false
        end
      end
      if not InRange then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.RLTT_exceeding_application_scope)
        return
      end
    end
    local CanPlayer = player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
    local CanPlayer_2 = self:GetBPRideIsNotPlay()
    if CanPlayer and not CanPlayer_2 then
      local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
      local MyRequestPlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
      if MyRequest and MyRequestPlayerUin and MyRequestPlayerUin == PlayerUid then
        self:OnZoneCancelUnlockRelationshipNodeReq(self, self.ZoneCancelUnlockRelationNode)
      else
        self:ZoneCancelUnlockRelationNode()
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.RLTT_Error_Code_2443)
    end
  end
end

function RelationTreeModule:GetBPRideIsNotPlay()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local state = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetPlayerInteractState, player)
    if state then
      return state == Enum.LocationInteractionBanType.STA_WATER_RIDE or state == Enum.LocationInteractionBanType.STA_FLY_RIDE
    end
  end
  return false
end

function RelationTreeModule:CancelUnlockRelationshipNodeReqAndInvite(PlayerUid, Caller, CallBack)
  local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
  local MyRequestPlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
  self.CancelNodeAndInviteCaller = Caller
  self.CancelNodeAndInviteCallBack = CallBack
  if MyRequest and MyRequestPlayerUin and MyRequestPlayerUin == PlayerUid then
    self:OnZoneCancelUnlockRelationshipNodeReq(self, self.ZoneOnlyCancelUnlockRelationNode)
  end
end

function RelationTreeModule:ZoneOnlyCancelUnlockRelationNode()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    if InviteComponent then
      InviteComponent:InviteCancel(self.CancelNodeAndInviteCaller, self.CancelNodeAndInviteCallBack)
    end
  end
end

function RelationTreeModule:ZoneCancelUnlockRelationNode()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    if InviteComponent then
      InviteComponent:InviteCancel(self, self.OnZoneUnlockRelationShipNodeReq)
    end
  end
end

function RelationTreeModule:OnZoneUnlockRelationShipNodeReq()
  if self.UnlockReq and self.UnlockReq.peer_uin and self.UnlockReq.relationship_type then
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UNLOCK_RELATIONSHIP_NODE_REQ, self.UnlockReq, self, self.OnZoneUnlockRelationShipNodeRsp, true, true)
  end
end

function RelationTreeModule:OnZoneUnlockRelationShipNodeRsp(Rsp)
  if Rsp then
    local RetInfo = Rsp.ret_info
    self.UnlockReq = nil
    if 0 == RetInfo.ret_code then
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_ITEM_UNLOCK_CANCEL_EFFECT, self.data:GetMyRequests())
      local PlayerUid = Rsp.peer_uin
      local RelationShipType = Rsp.relationship_type
      if PlayerUid and RelationShipType then
        self.data:UpdateMyRequests(RelationShipType)
        self:SetCurRequestPlayerUID(PlayerUid)
        self:OnTipMyRequestByUin(PlayerUid)
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UpdateItemEffect, PlayerUid, RelationShipType)
        local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        if player then
          local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
          local RelationTreeNode = self.data:GetRelationTreeNodeByEnum(RelationShipType)
          if RelationTreeNode and RelationTreeNode.LockAnimKey and 0 ~= RelationTreeNode.LockAnimKey then
            local bTogether = RelationTreeNode.RelationTreeType and (RelationTreeNode.RelationTreeType == Enum.RelationTreeType.RLTT_INVITE_TOGETHER or RelationTreeNode.RelationTreeType == Enum.RelationTreeType.RLTT_REQUEST_TOGETHER)
            local Param = ProtoMessage:newInteractParam()
            Param.action_id = RelationTreeNode.LockAnimKey
            Param.is_lock = true
            InviteComponent:Invite(PlayerUid, _G.ProtoEnum.InteractInviteType.IIT_DOUBLE_ACTION, Param, bTogether)
          end
        end
      end
    else
      local Text
      if RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_PLAYER_OFFLINE then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2435").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_WISH_CRYSTAL_NOT_ENOUGH then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2436").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_DENNY_UNLOCK then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2437").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_IN_BLACK_ROLE then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_PEER_REQ_PROCESSING then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2439").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_UNLOCK_PROCESSING then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2441").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_SELF_FUNC_BANNED_UNLOCK then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2443").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_PEER_FUNC_BANNED_UNLOCK then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2444").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CREDIT_SCORE_NOT_ENOUGH then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2328").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_FULL then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13002").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_MINE then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13005").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MODULE_NOT_UNLOCK then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13024").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_CANT_BE_ADDED then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13025").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_LIMIT then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13012").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_EXIST then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13004").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_OTHER_BLACK_LIMIT then
        Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438_2").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
        Text = _G.DataConfigManager:GetLocalizationConf("relationtree_abnormal_status_tip").msg
      elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and Rsp.ban_info then
        local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
        local uin = Rsp.ban_info.uin
        local ban_time = os.date("%Y-%m-%d %H:%M:%S", Rsp.ban_info.ban_time)
        local reasonStr = Rsp.ban_info.ban_reason or ""
        local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
        local dialogContext = DialogContext()
        dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      else
        local TextConf = _G.DataConfigManager:GetLocalizationConf(string.format("RLTT_Error_Code_%d", RetInfo.ret_code))
        if TextConf then
          Text = TextConf.msg
        end
      end
      if Text then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      end
      self:OnUpdateRelationTreeUI(false)
    end
  end
end

function RelationTreeModule:OnZoneConfirmUnlockRelationShipNodeReq(PlayerUid, RelationShipType)
  if PlayerUid and RelationShipType then
    local isUnLock = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetPeerRelationTreeNodeState, PlayerUid, RelationShipType, true)
    if isUnLock then
      local Text = LuaText.relationtree_confirm_node_unlocked
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    else
      local req = _G.ProtoMessage:newZoneConfirmUnlockRelationshipNodeReq()
      req.peer_uin = PlayerUid
      req.relationship_type = RelationShipType
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CONFIRM_UNLOCK_RELATIONSHIP_NODE_REQ, req, self, self.OnZoneConfirmUnlockRelationShipNodeRsp, true, true)
    end
  end
end

function RelationTreeModule:OnZoneConfirmUnlockRelationShipNodeRsp(Rsp)
  local Text
  if Rsp then
    local RetInfo = Rsp.ret_info
    local PlayerUid = Rsp.peer_uin
    local RelationShipType = Rsp.relationship_type
    self.data:UpdateOtherRequestsData(PlayerUid, RelationShipType, true)
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, PlayerUid)
    if 0 == RetInfo.ret_code then
      if PlayerUid and RelationShipType then
        local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        if player then
          local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
          local RelationTreeNode = self.data:GetRelationTreeNodeByEnum(RelationShipType)
          if RelationTreeNode and RelationTreeNode.LockAnimKey and 0 ~= RelationTreeNode.LockAnimKey then
            local bTogether = RelationTreeNode.RelationTreeType and (RelationTreeNode.RelationTreeType == Enum.RelationTreeType.RLTT_INVITE_TOGETHER or RelationTreeNode.RelationTreeType == Enum.RelationTreeType.RLTT_REQUEST_TOGETHER)
            local Param = ProtoMessage:newInteractParam()
            Param.action_id = RelationTreeNode.LockAnimKey
            InviteComponent:InviteAccept(PlayerUid, _G.ProtoEnum.InteractInviteType.IIT_DOUBLE_ACTION, Param, bTogether)
          end
        end
        _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.CancelUnlockRelationshipNodeReq)
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_STATE_UNLOCK, PlayerUid, RelationShipType)
      end
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_DATA_FULL then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2433").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_PLAYER_OFFLINE then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2435").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_WISH_CRYSTAL_NOT_ENOUGH then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2436").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_DENNY_UNLOCK then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2437").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_ALREADY_CANCEL_LOCK then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2440").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_MINE then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13005").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_OTHERS then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13010").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_NOT_EXIST then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13000").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MODULE_NOT_UNLOCK then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13024").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_CANT_BE_ADDED then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_13025").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CREDIT_SCORE_NOT_ENOUGH then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2328").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MINE_BLACK_LIMIT then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438_1").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_OTHER_BLACK_LIMIT then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438_2").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_ZONE_RELATIONSHIP_UNLOCK_PROCESSING then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2441").msg
    elseif RetInfo.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_SELF_FUNC_BANNED_UNLOCK then
      Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2443").msg
    else
      local TextConf = _G.DataConfigManager:GetLocalizationConf(string.format("RLTT_Error_Code_%d", RetInfo.ret_code))
      if TextConf then
        Text = TextConf.msg
      end
    end
    if Text then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    end
  end
end

function RelationTreeModule:OnZoneCloseRelationShipTreeReq(PlayerUid)
  if PlayerUid then
    local req = _G.ProtoMessage:newZoneCloseRelationshipTreeReq()
    req.peer_uin = PlayerUid
    local IsSuccess = _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLOSE_RELATIONSHIP_TREE_REQ, req)
    if IsSuccess then
      self:CloseRelationTreePanel()
    end
  end
end

function RelationTreeModule:OnZoneCancelUnlockRelationshipNodeReq(caller, callback)
  if self.data:GetMyRequests() and self.CurRequestPlayerUin then
    self.Caller = nil
    self.Callback = nil
    local req = _G.ProtoMessage:newZoneCancelUnlockRelationshipNodeReq()
    local MyRequestsRelationType = self.data:GetMyRequests()
    if MyRequestsRelationType then
      local uin = self.CurRequestPlayerUin
      req.peer_uin = uin
      req.relationship_type = MyRequestsRelationType
      if caller and callback then
        self.Caller = caller
        self.Callback = callback
      end
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CANCEL_UNLOCK_RELATIONSHIP_NODE_REQ, req, self, self.OnZoneCancelUnlockRelationshipNodeRsp, true, true)
    end
  end
end

function RelationTreeModule:OnZoneCancelUnlockRelationshipNodeRsp(Rsp)
  if Rsp then
    local RetInfo = Rsp.ret_info
    if RetInfo and 0 == RetInfo.ret_code then
      local PlayerUin = Rsp.peer_uin
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_ITEM_UNLOCK_CANCEL_EFFECT, self.data:GetMyRequests())
      self:ClearMyRequestsHandle()
      local Text = _G.DataConfigManager:GetLocalizationConf("relationtree_unlock_req_Interrupted_text").msg
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, PlayerUin)
      if self.Callback then
        self.Callback(self.Caller)
      end
    end
  end
end

function RelationTreeModule:OnTipMyRequestByUin(Uin)
  if Uin then
    local req = _G.ProtoMessage.newZoneFriendSearchPlayerReq()
    req.uin = Uin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnShowMyRequestTips)
  end
end

function RelationTreeModule:OnShowMyRequestTips(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    local Text = _G.DataConfigManager:GetLocalizationConf("relationtree_text_req_inf").msg
    local name = Rsp.player_info and Rsp.player_info.name or ""
    local uin = Rsp.player_info and Rsp.player_info.uin or 0
    local NodeValue = self:GetCurrentNodeValueByType(uin, self.data:GetMyRequests())
    if NodeValue.RelationTreeType == Enum.RelationTreeType.RLTT_ADDFRIEND then
      Text = _G.DataConfigManager:GetLocalizationConf("relationtree_add_friend_text_sp_send").msg
      if Text then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(Text, name))
      end
    else
      local NodeName = NodeValue and NodeValue.StateStruct and NodeValue.StateStruct[1] and NodeValue.StateStruct[1].name or ""
      if Text then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(Text, name, NodeName))
      end
    end
  else
    Log.Error("FriendModule:OnWaitingOtherPlayerCardInfoRspToOpenCard error code = " .. _rsp.ret_info.ret_code)
  end
end

function RelationTreeModule:OnTipOtherRequestByUin(Uin)
  if Uin then
    local req = _G.ProtoMessage.newZoneFriendSearchPlayerReq()
    req.uin = Uin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnShowOtherRequestTips)
  end
end

function RelationTreeModule:OnShowOtherRequestTips(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and player.statusComponent then
      local isBattle = player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_BATTLE)
      local bInDialogue = _G.NRCModuleManager:DoCmd(DialogueModuleCmd.HasDialogue) or false
      if not isBattle and not bInDialogue then
        local Text = _G.DataConfigManager:GetLocalizationConf("relationtree_text_revieice_inf").msg
        local name = Rsp.player_info and Rsp.player_info.name or ""
        local uin = Rsp.player_info and Rsp.player_info.uin or 0
        local NodeValue = self:GetCurrentNodeValueByType(uin, self:GetOtherRequestsByUin(uin))
        if NodeValue then
          if NodeValue.RelationTreeType == Enum.RelationTreeType.RLTT_ADDFRIEND then
            Text = _G.DataConfigManager:GetLocalizationConf("relationtree_add_friend_text_sp_recevied").msg
            if Text then
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(Text, name))
            end
          else
            local NodeName = NodeValue.StateStruct and NodeValue.StateStruct[1] and NodeValue.StateStruct[1].name or ""
            if Text then
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(Text, name, NodeName))
            end
          end
        end
      end
    end
  else
    Log.Error("FriendModule:OnWaitingOtherPlayerCardInfoRspToOpenCard error code = " .. _rsp.ret_info.ret_code)
  end
end

function RelationTreeModule:ApplyDoubleAction(PlayerUin, InteractType, ActionID)
  local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
  local MyRequestPlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
  self.DoubleActionPlayerUin = PlayerUin
  self.DoubleActionInteractType = InteractType
  self.DoubleActionActionID = ActionID
  if MyRequest and MyRequestPlayerUin and MyRequestPlayerUin == PlayerUin then
    self:OnZoneCancelUnlockRelationshipNodeReq(self, self.SuccessApplyDoubleAction)
  else
    self:SuccessApplyDoubleAction()
  end
end

function RelationTreeModule:SuccessApplyDoubleAction()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and self.DoubleActionPlayerUin and self.DoubleActionInteractType then
    local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    local Param = ProtoMessage:newInteractParam()
    Param.action_id = self.DoubleActionActionID
    Param.is_lock = false
    InviteComponent:Invite(self.DoubleActionPlayerUin, self.DoubleActionInteractType, Param)
  end
end

function RelationTreeModule:SetCurOpenPanelPlayerUID(arg)
  self.CurOpenPanelPlayerUid = arg
end

function RelationTreeModule:GetCurPlayerUID()
  return self.CurOpenPanelPlayerUid
end

function RelationTreeModule:SetCurOpenPetPanelPlayerUin(arg)
  self.CurOpenPetPanelPlayerUid = arg
end

function RelationTreeModule:GetCurOpenPetPanelPlayerUin()
  return self.CurOpenPetPanelPlayerUid
end

function RelationTreeModule:SetCurOpenPetPanelPlayerName(arg)
  self.CurOpenPetPanelPlayerName = arg
end

function RelationTreeModule:GetCurOpenPetPanelPlayerName(arg)
  return self.CurOpenPetPanelPlayerName
end

function RelationTreeModule:SetCurRequestPlayerUID(arg)
  self.CurRequestPlayerUin = arg
end

function RelationTreeModule:GetCurRequestPlayerUID()
  return self.CurRequestPlayerUin
end

function RelationTreeModule:SetCurUnLockMaxFloor(floor)
  self.CurOpenPanelUnLockMaxFloor = floor
end

function RelationTreeModule:GetCurUnLockMaxFloor()
  return self.CurOpenPanelUnLockMaxFloor
end

function RelationTreeModule:SetCurOtherLevelData(LevelData)
  self.CurOpenPanelPlayerLevelData = LevelData
end

function RelationTreeModule:GetCurOtherLevelData(LevelData)
  return self.CurOpenPanelPlayerLevelData
end

function RelationTreeModule:SetRelationItemSelectCD(CD)
  self.RelationItemSelectCD = CD
end

function RelationTreeModule:GetRelationItemSelectCD()
  return self.RelationItemSelectCD
end

function RelationTreeModule:SetOpenPlayerInfo(PlayerInfo)
  self.RleationTreeOpenPlayerInfo = PlayerInfo
end

function RelationTreeModule:GetOpenPlayerInfo()
  return self.RleationTreeOpenPlayerInfo
end

function RelationTreeModule:QueryOtherPlayerFriendState(arg)
  self.relationEggArg = arg
  local argData = arg.argData
  if argData and argData.targetUin and argData.petId and argData.petNpcId then
    local req = _G.ProtoMessage:newZoneQueryNpcPetDataReq()
    req.target_uin = argData.targetUin
    req.target_pet_gid = argData.petId
    req.target_pet_npc_id = argData.petNpcId
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_NPC_PET_DATA_REQ, req, self, self.OnOpenRelationEggBag)
  end
end

function RelationTreeModule:OnOpenRelationEggBag(Rsp)
  if Rsp.ret_info and 0 == Rsp.ret_info.ret_code then
    if Rsp.relationship_type == _G.ProtoEnum.PlayerRelationshipType.PRT_FORBID then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.RLTT_Error_Code_2438_2)
      return false
    elseif not self:HasPanel("RelationTreeEggBag") and self.relationEggArg then
      self:OpenPanel("RelationTreeEggBag", self.relationEggArg)
      self.relationEggArg = nil
      return true
    end
  end
end

function RelationTreeModule:OpenRelationEggBag(arg)
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_PET_BLESSING_INVITE)
  if Ban then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.RLTT_Error_Code_2443)
    return false
  end
  if arg.panelType == arg.EggPanelType.Bless then
    local PlayerUin = arg and arg.argData and arg.argData.targetUin and arg.argData.targetUin or nil
    if PlayerUin and _G.DataModelMgr.PlayerDataModel:CheckHasBlackByPlayerUin(PlayerUin) then
      local Text = LuaText.RLTT_Error_Code_2438_1
      if Text then
        _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      end
      return false
    end
    if arg.argData.petbaseId then
      local curBaseConf = _G.DataConfigManager:GetPetbaseConf(arg.argData.petbaseId)
      local curEvoConf = _G.DataConfigManager:GetPetEvolutionConf(curBaseConf.pet_evolution_id[1])
      local fristEvoBaseId
      if curEvoConf then
        for i = 1, #curEvoConf.evolution_chain do
          local chain = curEvoConf.evolution_chain[i]
          if 1 == chain.stage then
            fristEvoBaseId = chain.petbase_id
            break
          end
        end
      end
      if fristEvoBaseId and self:IsShowEggTips(fristEvoBaseId) then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_egg_limit_text)
        return false
      end
    end
    self:QueryOtherPlayerFriendState(arg)
  elseif not self:HasPanel("RelationTreeEggBag") then
    self:OpenPanel("RelationTreeEggBag", arg)
    return true
  end
  return false
end

function RelationTreeModule:GetPetEvoGroupFirstBaseIds(baseId)
  local evoFirstBaseIds = {}
  if self.EvoConfs == nil then
    local EvoConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_EVOLUTION_CONF)
    if EvoConf then
      self.EvoConfs = EvoConf:GetAllDatas()
    end
  end
  local baseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
  if nil ~= baseConf and baseConf.pet_evolution_id and #baseConf.pet_evolution_id > 0 then
    local evoCfg = _G.DataConfigManager:GetPetEvolutionConf(baseConf.pet_evolution_id[1])
    if evoCfg and evoCfg.handbook_evolution_group then
      for _, v in pairs(self.EvoConfs) do
        if v.handbook_evolution_group == evoCfg.handbook_evolution_group and v.evolution_chain and #v.evolution_chain > 0 then
          for _, chain in pairs(v.evolution_chain) do
            if 1 == chain.stage then
              table.insert(evoFirstBaseIds, chain.petbase_id)
            end
          end
        end
      end
    end
  end
  return evoFirstBaseIds
end

function RelationTreeModule:IsShowEggTips(baseId)
  local isShowTips = true
  local items = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagEggItemWithoutHathcing)
  if items and #items > 0 then
    for i, bagItem in pairs(items) do
      if bagItem and bagItem.conf and bagItem.egg_data then
        local eggId = bagItem.conf.item_behavior[1].ratio[1]
        local eggConf = _G.DataConfigManager:GetPetEggConf(eggId)
        if eggConf and eggConf.pet_id then
          local petConf = _G.DataConfigManager:GetPetConf(eggConf.pet_id)
          if petConf and petConf.base_id then
            local eggEvoFirstBaseIds = self:GetPetEvoGroupFirstBaseIds(petConf.base_id)
            for _, eggEvoBaseId in pairs(eggEvoFirstBaseIds) do
              if eggEvoBaseId == baseId then
                local EggConfIsPrecious = eggConf.precious_egg_type and eggConf.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE
                local EggItemIsPrecious = bagItem.egg_data.precious_egg_type ~= nil and bagItem.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE
                if false == EggConfIsPrecious and false == EggItemIsPrecious then
                  isShowTips = false
                  break
                end
              end
            end
          end
        end
      end
    end
  else
    isShowTips = true
  end
  return isShowTips
end

function RelationTreeModule:CloseRelationEggBag(arg)
  if self:HasPanel("RelationTreeEggBag") then
    self:ClosePanel("RelationTreeEggBag", arg)
  end
end

function RelationTreeModule:OnApplyBlessingEgg(uin, pet_gid, pet_npc_id, be_blessing_egg_gid, bagitem_id)
  self:OnZoneInvitePetBlessingReq(uin, pet_gid, pet_npc_id, be_blessing_egg_gid, bagitem_id)
end

function RelationTreeModule:OpenRelationPetPreview(uin, pet_gid, pet_npc_id)
  self:OnZoneQueryNpcPetDataReq(uin, pet_gid, pet_npc_id)
end

function RelationTreeModule:OnZoneQueryNpcPetDataReq(uin, pet_gid, pet_npc_id)
  if uin and pet_gid and pet_npc_id then
    local req = _G.ProtoMessage:newZoneQueryNpcPetDataReq()
    req.target_uin = uin
    req.target_pet_gid = pet_gid
    req.target_pet_npc_id = pet_npc_id
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_NPC_PET_DATA_REQ, req, self, self.OnZoneQueryNpcPetDataRsp)
  end
end

function RelationTreeModule:OnZoneQueryNpcPetDataRsp(Rsp)
  if Rsp.ret_info and 0 == Rsp.ret_info.ret_code then
    local friendInfo = {
      info = Rsp.player_info,
      type = Rsp.relationship_type,
      petData = Rsp.target_pet_data
    }
    Log.Error("\229\165\150\231\137\140id", Rsp.target_pet_data.wear_medal_conf_id)
    local petData = Rsp.target_pet_data
    if Rsp.target_pet_data and Rsp.relationship_type == _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(Rsp.target_pet_data.gid)
    end
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetFriendInfoToPetMain, friendInfo)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 1, true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {subPanelIndex = 4})
  end
end

function RelationTreeModule:OnZoneInvitePetBlessingReq(uin, pet_gid, pet_npc_id, be_blessing_egg_gid, bagitem_id)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local inviteComponent = localPlayer:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
  local newInteractParams = _G.ProtoMessage:newInteractParam()
  newInteractParams.is_lock = false
  newInteractParams.action_id = 18
  newInteractParams.is_double_ride = false
  newInteractParams.picked_bagitem_conf_id = bagitem_id
  newInteractParams.picked_pet_gid = pet_gid
  newInteractParams.picked_pet_npc_id = pet_npc_id
  newInteractParams.picked_egg_gid = be_blessing_egg_gid
  inviteComponent:Invite(uin, _G.ProtoEnum.InteractInviteType.IIT_PET_BLESSING, newInteractParams)
end

function RelationTreeModule:OpenComplimentaryPetEggs(...)
  if not self:HasPanel("ComplimentaryPetEggs") then
    self:OpenPanel("ComplimentaryPetEggs", ...)
  end
end

function RelationTreeModule:CloseComplimentaryPetEggs(...)
  if self:HasPanel("ComplimentaryPetEggs") then
    self:ClosePanel("ComplimentaryPetEggs", ...)
  end
end

function RelationTreeModule:OnZoneQueryGiftingEggTimesReq()
  local target_uin = self:GetCurPlayerUID()
  if target_uin then
    local req = _G.ProtoMessage:newZoneQueryGiftingEggTimesReq()
    req.target_uin = target_uin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_GIFTING_EGG_TIMES_REQ, req, self, self.OnZoneQueryGiftingEggTimesRsp)
  end
end

function RelationTreeModule:OnZoneQueryGiftingEggTimesRsp(Rsp)
  if Rsp.ret_info and 0 == Rsp.ret_info.ret_code then
    self.data.todaySendEggTimes = Rsp.times
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnTodaySendEggTimesUpdate)
  end
end

function RelationTreeModule:CanSendEggTimes()
  local limitTimesConf = _G.DataConfigManager:GetGlobalConfigByKeyType("Relationtree_egggift_limit", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG)
  return (self.data.todaySendEggTimes or 0) < (limitTimesConf and limitTimesConf.num or 1)
end

function RelationTreeModule:OnGivePetEggReq(target_uin, interact_type, param)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    if InviteComponent then
      InviteComponent:Invite(target_uin, interact_type, param)
    end
  end
end

function RelationTreeModule:OnTwoPeopleActionPlayCompleted(custom_params)
  if custom_params and custom_params.player_interact_param and custom_params.player_interact_param.pet_egg_id then
    self:OnZoneQueryGiftingEggTimesReq()
    local selfUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if custom_params.player_interact_param.player_uin2 == selfUin then
      local reward = {}
      reward.id = custom_params.player_interact_param.pet_egg_id
      reward.type = ProtoEnum.GoodsType.GT_BAGITEM
      reward.num = 1
      local param = {reward}
      
      function param.callBack()
        local info = {
          goods_reward = {
            rewards = {}
          }
        }
        local reward2 = {}
        info.goods_reward.rewards[1] = reward2
        reward2.first_get = true
        reward2.id = custom_params.player_interact_param.pet_egg_id
        reward2.num = 1
        reward2.reward_reason = _G.ProtoEnum.FlowReason.FLOW_REASON_COLLECT
        reward2.tag = _G.ProtoEnum.GoodsDsiplayTag.NARMAL_SHOW
        reward2.type = _G.ProtoEnum.GoodsType.GT_BAGITEM
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ProcessRetInfo, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_NOTIFY, info, false)
      end
      
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, param)
    end
  end
end

function RelationTreeModule:GetPeerRelationTreeNodeState(PeerUin, RelationType, NeedUnlock)
  if self.data then
    local RelationTreeTable = self.data:GetRelationTreePoolByUin(PeerUin)
    if RelationTreeTable then
      for floor, nodevalue in pairs(RelationTreeTable.RelationTree) do
        for nodetype, value in pairs(nodevalue) do
          if NeedUnlock then
            if value.RelationTreeType == RelationType then
              return value.Unlock
            end
          elseif value.RelationTreeTypeDefault == RelationType or value.RelationTreeType == RelationType then
            return value.Unlock
          end
        end
      end
    end
  end
  return nil
end

function RelationTreeModule:SearchPetReq(playeruin, petinfo)
  local req = _G.ProtoMessage:newZoneQueryNpcPetDataReq()
  req.target_uin = playeruin
  req.target_pet_gid = petinfo.PetInfo and petinfo.PetInfo.serverData and petinfo.PetInfo.serverData.pet_info and petinfo.PetInfo.serverData.pet_info.gid or 0
  req.target_pet_npc_id = petinfo.PetInfo.serverData and petinfo.PetInfo.serverData.base and petinfo.PetInfo.serverData.base.logic_id or 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_NPC_PET_DATA_REQ, req, self, self.UpdatePetInfoOnPanel)
end

function RelationTreeModule:UpdatePetInfoOnPanel(Rsp)
  if Rsp.ret_info and 0 == Rsp.ret_info.ret_code and self:HasPanel("PetRelationTree") then
    self:SetPetInfoData(Rsp.target_pet_data)
    local panel = self:GetPanel("PetRelationTree")
    panel:UpdatePetInfo()
  end
end

function RelationTreeModule:OpenPetRelationCover(playeruin, arg, Action)
  local req = _G.ProtoMessage:newZoneQueryNpcPetDataReq()
  req.target_uin = playeruin
  req.target_pet_gid = arg.PetInfo and arg.PetInfo.serverData and arg.PetInfo.serverData.pet_info and arg.PetInfo.serverData.pet_info.gid or 0
  req.target_pet_npc_id = arg.PetInfo.serverData and arg.PetInfo.serverData.base and arg.PetInfo.serverData.base.logic_id or 0
  self:SetPetRelationTreeUIData(arg)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddInputBlockMappingContext, "RelationTreePanelOpen")
  self.PlayerAction = Action
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_NPC_PET_DATA_REQ, req, self, self.OpenPetRelationCoverRsp)
end

function RelationTreeModule:OpenPetRelationCoverRsp(Rsp)
  if Rsp.ret_info and 0 == Rsp.ret_info.ret_code then
    if Rsp.relationship_type == Enum.PlayerRelationshipType.PRT_FORBID then
      local Text = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2438_2").msg
      if Text then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      end
      self:SetPetRelationTreeUIData(nil)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "RelationTreePanelOpen")
      return
    end
    self:SetPetInfoData(Rsp.target_pet_data)
    self:OpenPetRelationPanel(Rsp.player_info.uin, Rsp.player_info.name)
  else
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "RelationTreePanelOpen")
  end
  if self.PlayerAction then
    self.PlayerAction:Finish()
    self.PlayerAction = nil
  end
end

function RelationTreeModule:OpenPetRelationPanel(playeruin, playername)
  if not self:HasPanel("PetRelationTree") and not _G.BattleManager:IsInBattle() then
    self:SetOpeningRelationPanel(true)
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_OPEN_PLAYER_RELATIONSHIP_TREE)
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, true)
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OffSetNPCInteractObjectList, false)
    self:SetCurOpenPetPanelPlayerUin(playeruin)
    self:SetCurOpenPetPanelPlayerName(playername)
    self:OpenPanel("PetRelationTree")
  else
    Log.Debug("\229\183\178\231\187\143\229\173\152\229\156\168\228\186\134\228\184\141\232\131\189\229\134\141\230\137\147\229\188\128 PetRelationTree")
  end
end

function RelationTreeModule:ClosePetRelationCover()
  if self:HasPanel("PetRelationTree") then
    self:ClosePanel("PetRelationTree")
  end
end

function RelationTreeModule:SetPetRelationTreeUIData(Param)
  self.PetRelationTreeData = Param
end

function RelationTreeModule:GetPetRelationTreeUIData()
  return self.PetRelationTreeData
end

function RelationTreeModule:SetPetInfoData(pet_data)
  self.PetInfoData = pet_data
end

function RelationTreeModule:GetPetInfoData()
  return self.PetInfoData
end

function RelationTreeModule:GetPetRelationTreeData()
  if self.data then
    return self.data:GetPetRelationMainTable()
  end
end

function RelationTreeModule:RelationTreeSendTLog(ActionType, ItemData, PetBaseID, PetGID, PetMutationType, PetOwnerUin)
  local key = "PetInteractionTreeLog"
  local tempString = "PetInteractionTreeLog|%s|%s|%d|%d|%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%s"
  local deEventTime = os.date("%Y-%m-%d %H:%M:%S")
  local gameAppId = "1110613799"
  local platId = -1
  local zoneId = 0
  local openId = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" then
      platId = needData.plat_info.plat_id or -1
      zoneId = needData.zoneId or 0
      openId = needData.openid or "nil"
    end
  end
  local ActionType = ActionType
  local NodeId = ItemData and ItemData.ID or 0
  local NodeType = ItemData and ItemData.InteractionTreeTypeDefault or 0
  local Cost = ItemData and ItemData.Cost or 0
  local PetBaseID = PetBaseID or 0
  local PetGID = PetGID or 0
  local PetMutationType = PetMutationType or 0
  local PetOwnerUin = PetOwnerUin or "nil"
  local value = string.format(tempString, deEventTime, gameAppId, platId, zoneId, openId, uin, roleName, level, ActionType, NodeId, NodeType, Cost, PetBaseID, PetGID, PetMutationType, PetOwnerUin)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function RelationTreeModule:HasRelationTreePanel()
  local hasRelationTree = self:HasPanel("RelationTree")
  local hasPetRelationTree = self:HasPanel("PetRelationTree")
  local hasPanel = hasRelationTree or hasPetRelationTree
  return hasPanel
end

function RelationTreeModule:OnDeactive()
  self:RegisterRelationTreeEvent(false)
  self:RegisterRelationTreeProto(false)
end

function RelationTreeModule:OpenRelationTreeMedalPopUp(bondId, mutationType)
  local bHasPanel = self:HasPanel("ShiningMedalPopUp")
  if not bHasPanel then
    self:OpenPanel("ShiningMedalPopUp", bondId, nil, mutationType)
  end
end

function RelationTreeModule:OpenShiningMedalDetail(bondId)
  local bHasPanel = self:HasPanel("ShiningMedalDetail")
  if not bHasPanel then
    local mutationType = _G.Enum.MutationDiffType.MDT_NONE
    local bondConf = _G.DataConfigManager:GetFashionBondConf(bondId)
    if bondConf.fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
      mutationType = _G.Enum.MutationDiffType.MDT_GLASS
      if bondConf.color_suits_id and #bondConf.color_suits_id > 0 then
        mutationType = mutationType | _G.Enum.MutationDiffType.MDT_SHINING
      end
    end
    self:OpenPanel("ShiningMedalDetail", bondId, true, mutationType)
  end
end

function RelationTreeModule:GetPetFashionBondID(PetBaseId)
  local bond_id_list = _G.DataConfigManager:GetPetbaseUsedByFashionBond(PetBaseId)
  if bond_id_list then
    local fashionbondlist = bond_id_list.fashion_bond_id
    if table.getTableCount(fashionbondlist) > 0 then
      return fashionbondlist[1]
    end
  end
  return nil
end

function RelationTreeModule:GetPetBondFirstClick(BondId)
  local medalInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBondInfo()
  local FashionbondItem = medalInfo.fashion_bond_item
  if FashionbondItem and table.getTableCount(FashionbondItem) > 0 then
    for _, v in ipairs(FashionbondItem) do
      if BondId == v.id then
        if not v.pet_tree_interacted then
          return true
        else
          return false
        end
      end
    end
  end
  return true
end

function RelationTreeModule:GetPetBondColorSuitState(BondId)
  local medalInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBondInfo()
  local State = 0
  local FashionbondItem = medalInfo.fashion_bond_item
  if FashionbondItem and table.getTableCount(FashionbondItem) > 0 then
    for _, v in ipairs(FashionbondItem) do
      if BondId == v.id then
        State = v.color_suit_state or 0
      end
    end
  end
  self:SetColorSuitState(State)
end

function RelationTreeModule:GetSelfIsHaveBondID(BondID)
  local medalInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBondInfo()
  local FashionbondItem = medalInfo.fashion_bond_item
  if FashionbondItem and table.getTableCount(FashionbondItem) > 0 then
    for _, v in ipairs(FashionbondItem) do
      if BondID == v.id then
        return true
      end
    end
  end
  return false
end

function RelationTreeModule:GetShopIsCanBuy(suitId)
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local goodsShopConf = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetNormalShopConfBySuitId, suitId)
  if goodsShopConf then
    local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
    local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
    if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
      return true
    end
  end
  local exchangeGoodsId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetExchangeGoodsIdBySuitId, suitId)
  if exchangeGoodsId then
    local exchangeGoodsConf = _G.DataConfigManager:GetNormalShopConf(exchangeGoodsId)
    if exchangeGoodsConf and exchangeGoodsConf.enable then
      local startTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.enable_time) * 1000
      local endTimeStamp = ActivityUtils.ToTimestamp(exchangeGoodsConf.disable_time) * 1000
      if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
        return true
      end
    end
  end
  return false
end

function RelationTreeModule:GetFashionSuitIsCanBuy(BondID)
  local BondConf = _G.DataConfigManager:GetFashionBondConf(BondID)
  local IsAllCanBuy = true
  if BondConf then
    local BondSuitList = BondConf.suits_id
    if table.getTableCount(BondSuitList) > 0 then
      for _, suitId in ipairs(BondSuitList) do
        if not self:GetShopIsCanBuy(suitId) then
          IsAllCanBuy = false
        end
      end
    else
      IsAllCanBuy = false
    end
  end
  return IsAllCanBuy
end

function RelationTreeModule:GetShopBuyState(suitId)
  local State = AppearanceModuleEnum.SuitState.NotPurchasable
  local svrTime = _G.ZoneServer:GetServerTime() or 0
  local goodsShopConf = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetNormalShopConfBySuitId, suitId)
  if goodsShopConf then
    local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
    local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
    if svrTime < startTimeStamp then
      State = AppearanceModuleEnum.SuitState.NotOnShelf
    elseif svrTime > endTimeStamp then
      State = AppearanceModuleEnum.SuitState.OffShelf
    elseif svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
      State = AppearanceModuleEnum.SuitState.OnShelf
    end
  end
  return State
end

function RelationTreeModule:GetFashionSuitBuyState(BondID)
  local BondConf = _G.DataConfigManager:GetFashionBondConf(BondID)
  local State = AppearanceModuleEnum.SuitState.NotPurchasable
  local IsAllCanBuy = true
  if BondConf then
    local BondSuitList = BondConf.suits_id
    if table.getTableCount(BondSuitList) > 0 then
      for _, suitId in ipairs(BondSuitList) do
        if not self:GetShopIsCanBuy(suitId) then
          IsAllCanBuy = false
        end
      end
    else
      IsAllCanBuy = false
    end
    if not IsAllCanBuy and table.getTableCount(BondSuitList) > 0 then
      State = self:GetShopBuyState(BondSuitList[1])
    end
  end
  return State
end

function RelationTreeModule:GetBondInteractID(BondID)
  local BondConf = _G.DataConfigManager:GetFashionBondConf(BondID)
  if BondConf and BondConf.pet_interact_id and BondConf.pet_interact_id > 0 then
    return BondConf.pet_interact_id
  end
  return nil
end

function RelationTreeModule:StartCloseRolePlayFromRelationTree(bondId, petGid, ownerActorId)
  self.data.PlayingCloseBondId = bondId
  self.data.PlayingClosePetGid = petGid
  self.data.PlayingClosePetOwnerActorId = ownerActorId
end

function RelationTreeModule:GetPlayingCloseBondId()
  return self.data.PlayingCloseBondId, self.data.PlayingClosePetGid, self.data.PlayingClosePetOwnerActorId
end

function RelationTreeModule:ResetCloseRolePlayFromRelationTree()
  self.data.PlayingCloseBondId = nil
  self.data.PlayingClosePetGid = nil
  self.data.PlayingClosePetOwnerActorId = nil
end

function RelationTreeModule:SetColorSuitState(ColorSuitState)
  self.ColorSuitState = ColorSuitState
end

function RelationTreeModule:GetColorSuitState()
  return self.ColorSuitState
end

function RelationTreeModule:SetOpeningRelationPanel(IsOpening)
  self.OpeningRelationPanel = IsOpening
end

function RelationTreeModule:GetOpeningRelationPanel()
  return self.OpeningRelationPanel
end

function RelationTreeModule:OpenGiftReminder(petGid, bondId, bIsPopUp)
  if bIsPopUp then
    local bHasPanel = self:HasPanel("GiftReminder")
    if bHasPanel then
      return
    end
    self:OpenPanel("GiftReminder", petGid, bondId)
  else
    local fullscreenCount = _G.NRCPanelManager:GetLayerWindowCount(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    local dialogueCount = _G.NRCPanelManager:GetLayerWindowCount(_G.Enum.UILayerType.UI_LAYER_DIALOGUE)
    local dialogueOverlayCount = _G.NRCPanelManager:GetLayerWindowCount(_G.Enum.UILayerType.UI_LAYER_DIALOGUE_OVERLAY)
    if fullscreenCount > 0 or dialogueCount > 0 or dialogueOverlayCount > 0 then
      return
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and (player:IsLogicStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_INTERACTING) or player:IsLogicStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_TELEPORT)) then
      return
    end
    local bHasPanel = self:HasPanel("GiftReminderFullScreen")
    if bHasPanel then
      return
    end
    self:OpenPanel("GiftReminderFullScreen", petGid, bondId)
  end
end

function RelationTreeModule:GetAllInteractiontreeConfs()
  if self.InteractiontreeConfs == nil then
    local confs = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.INTERACTIONTREE_CONF)
    if confs then
      self.InteractiontreeConfs = confs:GetAllDatas()
    end
  end
  return self.InteractiontreeConfs
end

return RelationTreeModule

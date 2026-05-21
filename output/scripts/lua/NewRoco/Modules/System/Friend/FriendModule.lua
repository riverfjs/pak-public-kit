local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local LoadingUIModuleEvent = reload("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local LegendaryBattleModuleEnum = require("NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleEnum")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local NRCSDKManagerEnum = require("Core.Service.SDKManager.NRCSDKManagerEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local NRCPanelDynamicData = require("Core.NRCPanel.NRCPanelDynamicData")
local UIUtilsTotal = require("NewRoco.Utils.UIUtils")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local FriendModule = NRCModuleBase:Extend("FriendModule")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_FRIEND

function FriendModule:OnConstruct()
  self.bHadReqInitializeCardInfo = false
  _G.FriendModuleCmd = reload("NewRoco.Modules.System.Friend.FriendModuleCmd")
  self.data = self:SetData("FriendModuleData", "NewRoco.Modules.System.Friend.FriendModuleData")
  self:InitializeChatBubbles()
  self:RegPanel("Friend", "UMG_Friend", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Out", nil, false, nil, true)
  self:RegPanel("FriendChat", "UMG_Friend", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Out", nil, false, nil, true)
  self:RegPanel("UMG_Friend_AddPrivateChat", "UMG_Friend_AddPrivateChat", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Out", nil, true, nil, true)
  self:RegPanel("Friend_Function", "UMG_Friend_Function1", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Friend_ApplyFor_Blacklist", "UMG_Friend_ApplyFor_Blacklist", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("Friend_Remark", "UMG_Friend_Remark", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("Friend_Report", "UMG_Friend_Report", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, true)
  self:RegPanel("FriendRequest", "UMG_FriendRequest", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("Plane_Team", "UMG_Plane_Team", _G.Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("Plane_ExchangeVisits_Hint", "UMG_Plane_ExchangeVisits_Hint", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, nil, true)
  self:RegPanel("Plane_ExchangeVisits", "UMG_Plane_ExchangeVisits", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, true)
  self:RegStudentPanel("CardComponentSelectList", "UMG_StudentCard_Dragable_List", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, true)
  self:RegStudentPanel("CardEditingComponent", "UMG_EditingComponent", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegStudentPanel("PetCardTypeSelect", "UMG_Card_Type_Select", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegStudentPanel("CardChangeBackground", "UMG_ChangeBackground", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, false, "In", "Out", true)
  self:RegStudentPanel("StudentCard", "UMG_StudentCard", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegStudentPanel("ChangeAvatar", "UMG_ChangeAvatar", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegStudentPanel("ChangeCardBG", "UMG_ChangeCard", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegStudentPanel("ChangeCardLabel", "UMG_ThisTag", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, true)
  self:RegStudentPanel("ChangeSign", "UMG_AlterSignature", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegStudentPanel("ReplaceElf", "UMG_ReplaceElf", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegStudentPanel("Photograph", "UMG_Photograph", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("Chat_Main", "UMG_Friend_Chitchat", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("Emo_Main", "UMG_Friend_Expression", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Friend_Wold", "UMG_Friend_Wold", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Friend_CaptureTips", "UMG_Friend_CaptureTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Friend_AccessAuthority", "UMG_AccessAuthority", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("Friend_HomeEntrance", "UMG_FriendHome_Entrance", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("QuickChatBubble", "UMG_QuickChatBubble", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil)
  self:RegPanel("TalkingBboutBubbles_Panel2", "UMG_TalkingBboutBubbles_Panel2", _G.Enum.UILayerType.UI_LAYER_BG)
  self:RegPanel("FriendRecommendFilter", "UMG_FriendRecommendFilter", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_DEAD, self.CmdClosePlaneExchangeVisitsHint)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.GetVisitOwnerName)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_ADD_OR_REMOVE_FRIEND_NOTIFY, self.FriendAddOrRemoveFriendNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_APPLY_VISIT_NOTIFY, self.ApplyVisitNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_APPLY_VISIT_RESULT_NOTIFY, self.ApplyVisitResultNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_INFO_NOTIFY, self.SetOnlineVisitorInfoNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_LEAVE_ONLINE_VISIT_NOTIFY, self.GetZoneLeaveOnlineVisitNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_INTERACT_RESULT_NOTIFY, self.OnNotifyInteractResult)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BE_INTERACTED_NOTIFY, self.OnNotifyBeInteract)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_GET_CHAT_LIST_RSP, self.OnZoneChatGetChatListRsp)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_DISBAND_VISIT_RSP, self.GetZoneDisbandVisitRsp)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_UPDATE_CHAT_INFO_NOTIFY, self.UpdataChatInfoNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_CARD_ICON_NOTIFY, self.OnReceiveNewCardIconNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_CARD_SKIN_NOTIFY, self.OnReceiveNewCardSkinNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_CARD_LABEL_NOTIFY, self.OnReceiveNewCardLabelNotify)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.VISIT_PERMISSION_CHANGED, self.OnVisitPermissionChanged)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MULTI_MAIN_MULTI_CHAT, self, self.OnFunctionBanMultiChat)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.OnEnterMapForEnterVisit, self.OnEnterMapByVisit)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.OnEnterMapForLeaveVisit, self.OnEnterMapByVisit)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.OnTeleportNotify, self.HandleSceneEvent_OnTeleportNotify)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, BattleEvent.EnterBattle, self.CmdBattleClosePlane_Team)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.VISIT_OWNER_CHANGED, self.OnVisitPlayerInfoSyncNotify)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.AfterEnterScene)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.EntranceVisibleZone, self.OnPlayerEntranceVisibleZone)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.LeaveVisibleZone, self.OnPlayerLeaveVisibleZone)
  _G.NRCEventCenter:RegisterEvent("FriendModule", self, SceneEvent.OnPlayerDead, self.DeadCloseStarChainPanel)
  self.StudentCardIsOpenChildPanel = false
  self.lastSelectedIndex = 0
  self.IsWaitVisitReplyRsp = false
  self.VisitListRefreshTime = 0
  self.bOpenByQuickChat = nil
  self:SetEmojiRanges()
  _G.GVoiceManager:Init(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  self.VisitNumMax = 0
  self.PrivateChatTabIndex = 0
end

function FriendModule:InitializeChatBubbles()
  self.chatBubbleController = NewObject(UE.UNRCChatBubbleController, UE4.UNRCPlatformGameInstance.GetInstance())
  self.chatBubbleController_Ref = UnLua.Ref(self.chatBubbleController)
  self.chatBubbleController:InitForLua("NRCChatBubbleDataAsset'/Game/NewRoco/Modules/System/Friend/Res/DA_NRCChatBubble.DA_NRCChatBubble'", nil, _G.UILayerCtrlCenter.ENUM_LAYER.MAIN)
  local BubbleGap = _G.DataConfigManager:GetFriendGlobalConfig("BubbleGap").numList
  local Lifetime = _G.DataConfigManager:GetFriendGlobalConfig("Lifetime").num / 1000
  local ActorBubbleMaxCount = _G.DataConfigManager:GetFriendGlobalConfig("ActorBubbleMaxCount").num
  local ActorMaxDistance = _G.DataConfigManager:GetFriendGlobalConfig("ActorMaxDistance").num
  self.chatBubbleController:OverrideConfigForLua(UE.FVector2D(BubbleGap[1], BubbleGap[2]), Lifetime, ActorBubbleMaxCount, ActorMaxDistance)
  self.chatBubblePanel2VisibilityFlags = {}
end

function FriendModule:OnActive()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FRIEND, false)
  if isBan then
    self.functionBanUIController = FunctionBanUIController()
    local functionBanUIController = self.functionBanUIController
    if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
      functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.RequestWeGameFriendsInfo, self)
    end
    functionBanUIController:Activate()
  else
    _G.NRCSDKManager:GetWeGameFriendsInfo()
  end
end

function FriendModule:RequestWeGameFriendsInfo(funcId, bHide)
  if funcId ~= _G.Enum.FunctionEntrance.FE_FRIEND or bHide then
    return
  end
  _G.NRCSDKManager:GetWeGameFriendsInfo()
end

function FriendModule:SetPrivateChatTabIndex(tabIndex)
  self.PrivateChatTabIndex = tabIndex
end

function FriendModule:GetPrivateChatTabIndex()
  return self.PrivateChatTabIndex
end

function FriendModule:GetVisitNumMax()
  if self.VisitNumMax ~= nil and self.VisitNumMax > 0 then
    return self.VisitNumMax
  end
  local OnlineConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
  for i = 1, #OnlineConf do
    if OnlineConf[i].key == "online_member_max" then
      self.VisitNumMax = OnlineConf[i].num
      break
    end
  end
  return self.VisitNumMax
end

function FriendModule:OnVisitPermissionChanged(permission_type)
  if permission_type == ProtoEnum.VisitPermissionSettingType.VPST_JOIN_DIRECT then
    self:CmdClosePlaneExchangeVisitsHint()
    local NotifyList = self.data:GetApplyVisitNotifyList()
    if NotifyList and #NotifyList > 0 then
      self:ReqZoneReplyPlayerInteract(NotifyList[1].uin, ProtoEnum.PlayerInteractType.Visiting, true)
    end
  elseif permission_type == ProtoEnum.VisitPermissionSettingType.VPST_JOIN_REFUSE then
    local NotifyList = self.data:GetApplyVisitNotifyList()
    self:CmdClosePlaneExchangeVisitsHint()
    if self.InviteVisitingUin then
      self:ReqZoneReplyPlayerInteract(self.InviteVisitingUin, ProtoEnum.PlayerInteractType.InviteVisiting, false)
    end
    if NotifyList and #NotifyList > 0 then
      self:ReqZoneReplyPlayerInteract(NotifyList[1].uin, ProtoEnum.PlayerInteractType.Visiting, false)
    end
  end
end

function FriendModule:OnRelogin()
  if self:HasPanel("Friend_Report") then
    local panel = self:GetPanel("Friend_Report")
    if panel then
      panel:OnRelogin()
    end
  end
end

function FriendModule:OnDeactive()
  table.clear(self.chatBubblePanel2VisibilityFlags)
  self:ClearAllBubbles(false)
end

function FriendModule:ClearAllBubbles(bAutoRestoreTypingBubble)
  self:DoClearAllBubbles()
  if bAutoRestoreTypingBubble then
    self:TryRestoreTypingBubble()
    self:TryRestoreOtherPlayersTypingBubble()
  end
end

function FriendModule:DoClearAllBubbles(bAutoRestoreTypingBubble)
  if self.chatBubbleController_Ref then
    self.chatBubbleController:ClearAllBubbles()
  end
end

function FriendModule:TryRestoreTypingBubble()
  local shouldShow = self.data:ShouldShowTyping()
  if shouldShow then
    self:HideOrShowTypingBubbleInfo(false, _G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  end
end

function FriendModule:TryRestoreOtherPlayersTypingBubble()
  local allPlayers = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  if not allPlayers then
    return
  end
  local selfUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  for _, player in pairs(allPlayers) do
    if player and player.serverData and player.serverData.base then
      local uin = player.serverData.base.logic_id
      if uin ~= selfUin and player:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_MSG_INPUT) then
        self:HideOrShowTypingBubbleInfo(false, uin)
      end
    end
  end
end

function FriendModule:OnCmdHasAnyChatBubble(ViewObj)
  if self.chatBubbleController_Ref then
    return self.chatBubbleController:HasAnyChatBubble(ViewObj)
  end
  return false
end

function FriendModule:OnCmdSwitchChatBubbles(ViewObj, bShow)
  if self.chatBubbleController_Ref then
    if bShow then
      return self.chatBubbleController:ShowChatBubbles(ViewObj)
    else
      return self.chatBubbleController:HideChatBubbles(ViewObj)
    end
  end
end

function FriendModule:OnCmdChangeChatBubblesParent(canvasPanel)
  if self.chatBubbleController_Ref then
    self.chatBubbleController:SetupViewportDepth(canvasPanel, _G.UILayerCtrlCenter.ENUM_LAYER.MAIN, false)
  end
end

function FriendModule:OnCmdUseUMGChatBubblesParent(caller, bVisible)
  self.chatBubblePanel2VisibilityFlags[caller] = bVisible
  self:UpdateChatBubblePanel2Visility()
end

function FriendModule:OnCmdUseMainUIChatBubblesParent()
  table.clear(self.chatBubblePanel2VisibilityFlags)
  self:ClosePanel("TalkingBboutBubbles_Panel2")
end

function FriendModule:OnCmdHideChatBubbles(canvasPanel)
  if 0 == self.chatBubblePanel2VisibilityFlags and self.chatBubbleController_Ref then
    self.chatBubbleController:RemoveFromParent(canvasPanel)
  end
end

function FriendModule:OnCmdSwitchUMGChatBubblesParentVisible(bShow)
  if self:HasPanel("TalkingBboutBubbles_Panel2") then
    local panel = self:GetPanel("TalkingBboutBubbles_Panel2")
    if bShow then
      panel:Enable()
    else
      panel:Disable()
    end
  end
end

function FriendModule:ReportTLog(tabId, FunctionID, OwnerData)
  local key = "FriendFunctionLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  local playerLocationStr = string.format("%d|%d|%d", math.floor(playerLocation.X), math.floor(playerLocation.Y), math.floor(playerLocation.Z))
  local tab = tabId or 0
  local Function = FunctionID or 0
  local Relation = 0
  local OwnervRoleID = 0
  local OwenrvOpenID = 0
  local OwnervRoleName = "nil"
  if OwnerData then
    Relation = (OwnerData.is_friend or OwnerData.add_friend_time or OwnerData.isFriend) and 1 or 0
    OwnervRoleID = OwnerData.uin or 0
    OwenrvOpenID = OwnerData.openid or 0
    OwnervRoleName = OwnerData.name or "nil"
  end
  local value = string.format("%s|%s|%s|%s|%s|%s|%s|%s|%s", key, roleDataStr, playerLocationStr, tab, Function, Relation, OwnervRoleID, OwenrvOpenID, OwnervRoleName)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function FriendModule:ReportInviteFriendTLog(InviteType, FriendVopenid, FriendVroleID, FriendVrolename)
  if 1 ~= InviteType and 2 ~= InviteType and 3 ~= InviteType and 4 ~= InviteType then
    Log.ErrorFormat("FriendModule:ReportInviteFriendTLog InviteType is invalid: %s", tostring(InviteType))
    return
  end
  local key = "InviteFriendIntoGameLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  InviteType = tostring(InviteType or 0)
  FriendVopenid = tostring(FriendVopenid or "")
  FriendVroleID = tostring(FriendVroleID or "")
  FriendVrolename = tostring(FriendVrolename or "")
  local value = string.format("%s|%s|%s|%s|%s|%s", key, roleDataStr, InviteType, FriendVopenid, FriendVroleID, FriendVrolename)
  Log.InfoFormat("FriendModule:ReportInviteFriendTLog value: %s", tostring(value))
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function FriendModule:OnCmdStartOverrideAttachment(ViewObj, AttachBoneName, AttachBoneOffset, PositionOffset)
  if self.chatBubbleController_Ref then
    self.chatBubbleAttachmentCache = self.chatBubbleAttachmentCache or UE.FNCRChatBubbleAttachment()
    self.chatBubbleAttachmentCache.AttachBoneName = AttachBoneName or "Bip001-Head"
    if AttachBoneOffset then
      self.chatBubbleAttachmentCache.AttachBoneOffset:Set(AttachBoneOffset.X, AttachBoneOffset.Y, AttachBoneOffset.Z)
    else
      self.chatBubbleAttachmentCache.AttachBoneOffset:Set(0, 0, 60)
    end
    if PositionOffset then
      self.chatBubbleAttachmentCache.PositionOffset:Set(PositionOffset.X, PositionOffset.Y)
    else
      self.chatBubbleAttachmentCache.PositionOffset:Set(0, -60)
    end
    self.chatBubbleController:StartOverrideAttachment(ViewObj, self.chatBubbleAttachmentCache)
  end
end

function FriendModule:OnCmdStopOverrideAttachment(ViewObj)
  if self.chatBubbleController_Ref then
    self.chatBubbleController:StopOverrideAttachment(ViewObj)
  end
end

function FriendModule:ChitchatOpenFriendPanel()
  if self:HasPanel("Chat_Main") then
    self:ClosePanel("Chat_Main")
  end
end

function FriendModule:ChitchatOpenCardPanel()
  if self:HasPanel("StudentCard") and self:HasPanel("Chat_Main") then
    self:ClosePanel("StudentCard")
  end
end

function FriendModule:OnCmdOpenAddPrivateChatPanel(uin)
  if self:HasPanel("UMG_Friend_AddPrivateChat") then
    self:ClosePanel("UMG_Friend_AddPrivateChat")
  end
  self.data:SetbCloseLobbyMain(false)
  self:OnCmdSetEntrance(nil)
  local panelDynamicData = NRCPanelDynamicData()
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
  local bInFighting = false
  if myPlayer then
    bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  end
  if bInFighting then
    panelDynamicData:SetModifiedPanelLayerType(Enum.UILayerType.UI_LAYER_TOP)
  end
  self:OpenPanel("UMG_Friend_AddPrivateChat", uin, panelDynamicData)
end

function FriendModule:OnCmdCloseAddPrivateChatPanel()
  if self:HasPanel("UMG_Friend_AddPrivateChat") then
    self:ClosePanel("UMG_Friend_AddPrivateChat")
  end
end

function FriendModule:OnCmdOpenChatMainPanelByCardPanel(uin, index)
  self.data:SetbCloseLobbyMain(true)
  if self:HasPanel("Chat_Main") then
    self:ClosePanel("Chat_Main")
    self:OnCmdOpenChatMainPanel(uin, index, true)
  else
    self:OnCmdOpenChatMainPanel(uin, index, true)
  end
end

function FriendModule:OnCmdOpenChatMainPanelByFriendPanel(uin, index, bOpenInBattle)
  self.data:SetbCloseLobbyMain(false)
  local bOpenByQuickChat = self.data:GetbOpenByQuickChat()
  if self:HasPanel("UMG_Friend_AddPrivateChat") then
    self:ClosePanel("UMG_Friend_AddPrivateChat")
  end
  if self.data:GetEntrance() == FriendEnum.OpenFriendEntrance.Chat then
    if self:HasPanel("FriendChat") then
      self:ClosePanel("FriendChat")
    end
    self:OnCmdOpenChatMainPanel(uin, index, false, bOpenByQuickChat, bOpenInBattle)
  else
    self:OnCmdOpenChatMainPanel(uin, index, false, false, bOpenInBattle)
  end
end

function FriendModule:DoOpenChatMainPanel(...)
  self:OnCmdUseUMGChatBubblesParent(self, true)
  if self:HasPanel("Chat_Main") then
    local Panel = self:GetPanel("Chat_Main")
    if Panel then
      Panel:UpdatePanelInfo(...)
    end
  else
    self:OpenPanel("Chat_Main", ...)
  end
end

function FriendModule:UpdateChatBubblePanel2Visility()
  local bFinalVisible = false
  local bOwingPanelVisible = false
  for caller, bVisible in pairs(self.chatBubblePanel2VisibilityFlags) do
    bOwingPanelVisible = bOwingPanelVisible or bVisible
    if bOwingPanelVisible then
      break
    end
  end
  bFinalVisible = bOwingPanelVisible
  if bOwingPanelVisible then
    local bOverrideVisible = false
    bOverrideVisible = true
    bFinalVisible = bOverrideVisible
  end
  Log.Debug("self.chatBubbleController:UpdateChatBubblePanel2Visility, bFinalVisible", bFinalVisible)
  if bFinalVisible then
    self:OpenPanel("TalkingBboutBubbles_Panel2")
  else
    self:ClosePanel("TalkingBboutBubbles_Panel2")
  end
end

function FriendModule:UpdateChatBubbles(DeltaTime)
  if self.chatBubbleController_Ref then
    self.chatBubbleController:Tick(DeltaTime)
  end
end

function FriendModule:OnReconnect()
  local hasPanel = self:HasPanel("Chat_Main")
  if hasPanel then
    local panel = self:GetPanel("Chat_Main")
    if panel then
      panel:DoClose()
    end
  end
  if self:HasPanel("StudentCard") then
    self:ClosePanel("StudentCard")
  end
  if self:HasPanel("Friend_Report") then
    self:ClosePanel("Friend_Report")
  end
  self:ClearAllBubbles(true)
  _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.ReturnCamera, self)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.TryDisplayAdditionalTarget)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CloseQuickChat)
end

function FriendModule:SetEmojiRanges()
  self.emojiRanges = {
    {128512, 128591},
    {127744, 128511},
    {128640, 128767},
    {128102, 129535},
    {127462, 127487},
    {9728, 9983},
    {9984, 10175},
    {65024, 65039},
    {917536, 917631}
  }
end

function FriendModule:CheckIsEmoji(char)
  for k, range in ipairs(self.emojiRanges) do
    if char >= range[1] and char <= range[2] or char > 65535 then
      return true
    end
  end
  return false
end

function FriendModule:OnCmdOpenAccessAuthority(permission_type)
  self:OpenPanel("Friend_AccessAuthority", permission_type)
end

function FriendModule:CmdSendZoneHomeQueryFriendHomeInfoReq(friendUin)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_HOME, true)
  if isBan then
    return
  end
  local req = _G.ProtoMessage:newZoneHomeQueryFriendHomeInfoReq()
  req.uin = friendUin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_QUERY_FRIEND_HOME_INFO_REQ, req, self, self.OnZoneHomeQueryFriendHomeInfoRsp, false, true)
end

function FriendModule:OnZoneHomeQueryFriendHomeInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.home_feature_opened ~= nil and rsp.home_feature_opened == false then
      Log.InfoFormat("FriendModule:OnZoneHomeQueryFriendHomeInfoRsp home_feature_opened == false, uin = %s", tostring(rsp.uin))
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.home_owner_lock_home)
      return
    end
    self:OnCmdOpenHomeEntrance(rsp.friend_home_brief_info, rsp.uin, rsp.friend_cell_home_brief_info)
  end
end

function FriendModule:OnCmdOpenHomeEntrance(homeInfo, homeOwnerId, friendCellHomeBriefInfo)
  self:OpenPanel("Friend_HomeEntrance", homeInfo, homeOwnerId, friendCellHomeBriefInfo, self:GetPanelAdaptationLayer())
end

function FriendModule:OnCmdCloseHomeEntrance()
  self:ClosePanel("Friend_HomeEntrance")
end

function FriendModule:CmdSendZoneSceneHomeEnterReq(homeOwnerId, Callback, OnSuccess, OnFailed, bDisableReqToEnterHome, TargetHomeSceneType)
  _G.NRCModuleManager:DoCmd(HomeModuleCmd.ReqEnterPlayerHomeIndoor, homeOwnerId, Callback, OnSuccess, OnFailed, bDisableReqToEnterHome, TargetHomeSceneType)
end

function FriendModule:CmdSendZoneSetVisitPermissionSettingReq(permission_type)
  local Req = _G.ProtoMessage:newZoneSetVisitPermissionSettingReq()
  Req.permission_type = permission_type
  self.change_permission_type = permission_type
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_VISIT_PERMISSION_SETTING_REQ, Req, self, self.OnZoneSetVisitPermissionSettingRsp, false, true)
end

function FriendModule:OnZoneSetVisitPermissionSettingRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:OnSetVisitPermissionSetting(self.change_permission_type)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function FriendModule:RemoveEmoji(string)
  local resultString = ""
  for _, char in utf8.codes(string) do
    if not self:CheckIsEmoji(char) then
      resultString = resultString .. utf8.char(char)
    end
  end
  return resultString
end

function FriendModule:OnEnterMapByVisit()
  Log.Debug("FriendModule:OnEnterMapByVisit")
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  self:ClearAllBubbles(true)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.CloseModuleAllPanel)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
end

function FriendModule:OnOwnerEnterMapByVisit()
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCModuleManager:DoCmd(_G.InstanceModuleCmd.CloseEnterPanel)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  self:ClearAllBubbles(true)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.CloseModuleAllPanel)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
end

function FriendModule:HandleSceneEvent_OnTeleportNotify()
  self:ClearAllBubbles(true)
end

function FriendModule:GetRandomPos()
  local Pos = _G.ProtoMessage:newPosition()
  local VisitorPos = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.FindVisitorPos)
  if VisitorPos then
    Pos.x = math.round(VisitorPos.X)
    Pos.y = math.round(VisitorPos.Y)
    Pos.z = math.round(VisitorPos.Z)
  else
    return
  end
  return Pos
end

function FriendModule:ReqZonePlayerInteract(Uin, Type)
end

function FriendModule:OnNotifyInteractResult(Notify)
  if Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_FUNCTIONBAN then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_interact_apply_abort").msg)
    self:CmdClosePlaneExchangeVisitsHint()
    return
  elseif Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_TIMEOUT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("players_interact_apply_over_time").msg)
    return
  elseif Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_DOUBLE_RIDE_CANCEL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_interact_apply_abort").msg)
    return
  end
  print("==amonsu========OnNotifyInteractResult", Notify.type, Notify.agree)
  self:DispatchEvent(FriendModuleEvent.NotifyInteractResult, Notify)
  if Notify.agree then
    if Notify.type == ProtoEnum.PlayerInteractType.ExchangeEgg then
      self:CmdClosePlaneExchangeVisitsHint()
      _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenSwapEggsUI)
    end
  else
    if Notify.type == ProtoEnum.PlayerInteractType.Visiting then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_owner_forbid_apply_tips").msg)
    elseif Notify.type == ProtoEnum.PlayerInteractType.InviteVisiting then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_invite_refuse_tips").msg)
    elseif Notify.type == ProtoEnum.PlayerInteractType.Fighting then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("spar_invite_refuse_tips").msg)
    elseif Notify.type == ProtoEnum.PlayerInteractType.ExchangeEgg then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("petegg_trade_invite_refuse_tips").msg)
    elseif Notify.type == ProtoEnum.PlayerInteractType.DoubleRide then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("ride_invitation_reject").msg)
    end
    local playerInteractType = FriendEnum.CardInteractionEntrance.None
    if Notify.type == ProtoEnum.PlayerInteractType.Visiting then
      playerInteractType = FriendEnum.CardInteractionEntrance.RequestAccess
    elseif Notify.type == ProtoEnum.PlayerInteractType.InviteVisiting then
      playerInteractType = FriendEnum.CardInteractionEntrance.Invitation
    end
    if playerInteractType ~= FriendEnum.CardInteractionEntrance.None then
      self.data:SetApplyTimeForPlayerInteractType(Notify.uin, playerInteractType, 0)
    end
  end
end

function FriendModule:OnNotifyBeInteract(Notify)
  print("==amonsu========OnNotifyBeInteract", Notify.type)
  if _G.BattleManager.isInBattle then
    return
  end
  if Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_PEER_FUNCTIONBAN then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_interact_recive_abort").msg)
    self.data:RemoveApplyVisitNotifyToListByUin(Notify.player_info.uin)
    self:CmdClosePlaneExchangeVisitsHint()
    return
  elseif Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_FUNCTIONBAN then
    self:CmdClosePlaneExchangeVisitsHint()
    self.data:ClearApplyVisitNotifyToList()
    return
  elseif Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_TIMEOUT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("players_interact_apply_over_time").msg)
    return
  elseif Notify.cancel_status == ProtoEnum.InteractCancelStatus.ICS_DOUBLE_RIDE_CANCEL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_interact_apply_abort").msg)
    return
  end
  if Notify.type == ProtoEnum.PlayerInteractType.Visiting then
    local VisitPermissionType = _G.DataModelMgr.PlayerDataModel:GetVisitPermissionType()
    if VisitPermissionType == ProtoEnum.VisitPermissionSettingType.VPST_JOIN_DIRECT or Notify.auto_confirm_visiting then
      self:ReqZoneReplyPlayerInteract(Notify.player_info.uin, ProtoEnum.PlayerInteractType.Visiting, true)
      return
    end
    if _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.LocalIsPlaying) then
      self.delayReplyPlayerInteractId = _G.DelayManager:DelaySeconds(1, function()
        self:ReqZoneReplyPlayerInteract(Notify.player_info.uin, ProtoEnum.PlayerInteractType.Visiting, false)
      end)
      return
    end
    self.data:AddApplyVisitNotifyToList(Notify.player_info)
    if self:HasPanel("Plane_ExchangeVisits") then
      local list = self.data:GetApplyVisitNotifyList()
      local Panel = self:GetPanel("Plane_ExchangeVisits")
      if Panel then
        Panel:SetPanelInfo(list, FriendEnum.ExchangeVisitsType.ApplyVisit)
      end
    else
      self:OpenApplyVisitInfoHitPanel(FriendEnum.ExchangeVisitsType.ApplyVisit, Notify.player_info)
    end
  elseif Notify.type == ProtoEnum.PlayerInteractType.InviteVisiting then
    self.InviteVisitingUin = Notify.player_info.uin
    self:OpenApplyVisitInfoHitPanel(FriendEnum.ExchangeVisitsType.InviteVisit, Notify.player_info)
  elseif Notify.type == ProtoEnum.PlayerInteractType.Fighting then
    self:OpenApplyVisitInfoHitPanel(FriendEnum.ExchangeVisitsType.ResponseCompetition, Notify.player_info)
  elseif Notify.type == ProtoEnum.PlayerInteractType.ExchangeEgg then
    self:OpenApplyVisitInfoHitPanel(FriendEnum.ExchangeVisitsType.ResponseSwapEggs, Notify.player_info)
  elseif Notify.type == ProtoEnum.PlayerInteractType.DoubleRide then
    self:OpenApplyVisitInfoHitPanel(FriendEnum.ExchangeVisitsType.DoubleRide, Notify.player_info)
  end
end

function FriendModule:CmdGetWaitVisitReplyRsp()
  return self.IsWaitVisitReplyRsp
end

function FriendModule:ReqZoneReplyPlayerInteract(Uin, Type, Agree)
end

function FriendModule:ReqZonePickEggReq(EggGid)
end

function FriendModule:OnResZonePickEgg(Res)
  if 0 == Res.ret_info.ret_code then
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.ResZonePickEggResult, true)
  else
    self:DealErrorCodeForInteract(Res)
  end
end

function FriendModule:OnNotifyPickEggResult(Notify)
  _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.NotifyPickEggResult, Notify.result)
end

function FriendModule:OnNotifyExchangeEggResult(Notify)
  self.ExchangeEggResultNotify = Notify
  _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.NotifyExchangeEggResult, 0 == Notify.ret_info.ret_code)
  self:CloseStudentCard()
end

function FriendModule:OnNotifySwapEggsUIClosed()
  if not self.ExchangeEggResultNotify then
    return
  end
  if 0 == self.ExchangeEggResultNotify.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, self.ExchangeEggResultNotify.ret_info.goods_reward.rewards, LuaText.tipenum_1)
  elseif self.ExchangeEggResultNotify.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_HAS_NOT_PICKED_EGG then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("petegg_trade_interrupt").msg)
  elseif self.ExchangeEggResultNotify.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_EXIT_EXCHANG_EGG then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("petegg_trade_interrupt").msg)
  end
  self.ExchangeEggResultNotify = nil
end

local function CompareApplyListData(a, b)
  return a.apply_time > b.apply_time
end

function FriendModule:DealErrorCodeForInteract(rsp)
  local VisitName, WorldLevel
  if rsp.player_info then
    VisitName = rsp.player_info.name
    WorldLevel = rsp.player_info.world_level
  end
  Log.Debug(rsp.ret_info.ret_code, "FriendModule:DealErrorCodeForInteract")
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CANT_VISITED then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_2153").msg, VisitName))
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_NUM_FULL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_apply_owner_full").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_OWNER_FORBIDEN_TASK then
    if VisitName then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_2151").msg, VisitName))
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_2151").msg, "\229\189\147\229\137\141\233\173\148\230\179\149\229\184\136"))
    end
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_LOW_LEVEL then
    local OnlineConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
    local UnlockLevel = 15
    for i = 1, #OnlineConf do
      if OnlineConf[i].key == "online_unlock_role_level" then
        UnlockLevel = OnlineConf[i].num
        break
      end
    end
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("cant_online_apply_mine").msg, UnlockLevel))
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_APPLY_FORBIDEN_TASK then
    local TaskConf = _G.DataConfigManager:GetTaskConf(rsp.ret_pram)
    if TaskConf then
      _G.NRCAudioManager:PlaySound2DAuto(1086, "UMG_Friend_Item_C:StartFriendVisit")
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_2147").msg, TaskConf.name))
    end
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_OWNER_WORLD_LEVEL_TOO_HIGH then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_2150").msg, tostring(WorldLevel).LuaText.friendmodule_1))
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_APPLY_FULL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2154").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_APPLY_EFFECTIVE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2155").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ALREADY_SEND_VISIT_APPLY then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2158").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_OWNER_LV_TOO_LOW then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("cant_online_apply_other").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ALREADY_RECIEVE_VISIT_APPLY then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2221").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_apply_fail").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PLAYER_INTERACT_PEER_NOT_ONLINE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2149").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HAS_OTHER_EXCLUSIVE_INTERACT_APLLICATION then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_REPEATED_INTERACT_APLLICATION then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2155").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELAY_INTERACT_NOT_EXIST then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("err_relay_interact_not_exist").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_INITIATE_PK_FAIL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_spar_invite_fail").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_ZONE_IS_NOT_IN_EXCHANGING_EGG then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_petegg_trade_fail").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_IS_NOT_IN_EXCHANGING_EGG then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_owner_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PPER_HAS_OTHER_EXCLUSIVE_STATUS then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_owner_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HAS_OTHER_EXCLUSIVE_STATUS then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_apply_fail").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_HAS_OTHER_EXCLUSIVE_INTERACTED_APLLICATION then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_owner_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_HAS_OTHER_EXCLUSIVE_BE_INTERACTED_APLLICATION then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_owner_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISITOR_HAS_BEEN_VISITING then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("visitor_is_already_online").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HAS_OTHER_BE_INTERACTED_APLLICATION then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ISVISITING_WHEN_PLAYER_INTERACT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("visitor_is_already_online").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_ISVISITING_WHEN_APPLY_VISITING then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2183").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PEER_IS_FULL_WHEN_APPLY_VISITING then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_apply_owner_full").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HAS_OTHER_EXCLUSIVE_STATUS_WHEN_VISITING then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HAS_OTHER_EXCLUSIVE_STATUS_WHEN_EXCHANGING_EGG then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PLAYER_INTERACT_NOT_ONLINE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2183").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_PPER_ISVISITING_WHEN_INVITE_VISITING then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_owner_interact_mutex").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_OTHER_BLACK_LIMIT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("blacklist_apply_interact").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MINE_BLACK_LIMIT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("blacklist_again_tips").msg)
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local reasonStr = rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function FriendModule:GetApplyVisitListInfoReq()
end

function FriendModule:OpenApplyVisitPanel(_rsp)
  Log.Dump(_rsp, 6, "FriendModule:OpenApplyVisitPanel")
  if 0 == _rsp.ret_info.ret_code then
    local data = _rsp.apply_list
    if data and #data > 0 then
      table.sort(data, CompareApplyListData)
      if self:HasPanel("Plane_ExchangeVisits") then
        local panel = self:GetPanel("Plane_ExchangeVisits")
        panel:SetPanelInfo(data)
      else
        self:OpenPanel("Plane_ExchangeVisits", data, FriendEnum.ExchangeVisitsType.ApplyVisit)
      end
    end
  end
end

function FriendModule:CheckApplyVisitInfoHitPanelIsOpen()
  return self:HasPanel("Plane_ExchangeVisits_Hint") or self:IsPanelInOpening("Plane_ExchangeVisits_Hint")
end

function FriendModule:CheckApplyVisitListPanelIsOpen()
  return self:HasPanel("Plane_ExchangeVisits") or self:IsPanelInOpening("Plane_ExchangeVisits")
end

function FriendModule:OpenApplyVisitInfoHitPanel(reason, data)
  if 0 == reason then
    local list = self.data:GetApplyVisitNotifyList()
    if #list > 0 then
      if self:HasPanel("Plane_ExchangeVisits_Hint") then
        local Panel = self:GetPanel("Plane_ExchangeVisits_Hint")
        if Panel then
          Panel:SetPanelInfo(reason, data, #list)
        end
      else
        self:OpenPanel("Plane_ExchangeVisits_Hint", reason, data, #list)
      end
    end
  elseif 1 == reason then
    if _G.BattleManager.isInBattle then
    else
      self:OpenPanel("Plane_ExchangeVisits_Hint", reason, data)
    end
  elseif self:HasPanel("Plane_ExchangeVisits_Hint") then
    local Panel = self:GetPanel("Plane_ExchangeVisits_Hint")
    if Panel then
      Panel:SetPanelInfo(reason, data)
    end
  else
    self:OpenPanel("Plane_ExchangeVisits_Hint", reason, data)
  end
end

function FriendModule:ApplyVisitNotify(_notify)
  local BattleUiModule = _G.NRCModuleManager:GetModule("BattleUIModule")
  local ShowConfirmTeleportTips = _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_HasConfirmTeleportTips)
  local IspvpMatching
  if BattleUiModule and BattleUiModule:HasPanel("BattlePVPMatching") then
    local pvpMatching = BattleUiModule:GetPanel("BattlePVPMatching")
    if pvpMatching then
      IspvpMatching = pvpMatching:IsMatching()
    end
  end
  if _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle) or IspvpMatching or ShowConfirmTeleportTips then
  else
    self.data:AddApplyVisitNotifyToList(_notify)
    if self:HasPanel("Plane_ExchangeVisits") then
      self:GetApplyVisitListInfoReq()
    elseif self:HasPanel("Plane_ExchangeVisits_Hint") then
    else
      self:OpenPanel("Plane_ExchangeVisits_Hint", 0, nil)
    end
  end
end

function FriendModule:ApplyVisitResultNotify(_notify)
  if _notify.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_visitor_apply_allowed_fail").msg)
    return
  elseif _notify.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NO_SUITABLE_VISIT_EXIT_POS then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2184").msg)
    return
  elseif _notify.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_SCENE_ENTER_POS_INVALID then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_50199").msg)
    return
  elseif _notify.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RECIEVE_NO_VISIT_APPLY then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2230").msg)
    return
  end
  if _notify.agree == false then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("online_owner_forbid_apply_tips").msg, _notify.owner_name))
    self:DispatchEvent(FriendModuleEvent.VisitFail, _notify.owner_uin)
    _G.NRCAudioManager:PlaySound2DAuto(1009, "FriendModule:ApplyVisitResultNotify")
  end
  if _notify.agree == true then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ClearTipsList)
    self.data:SetVisitOwnerName(_notify.owner_name)
    self.FirstVisit = true
    self.data.VisitSwitchScreen = true
    if self:HasPanel("Friend") then
      self:ClosePanel("Friend")
    end
  end
  Log.Dump(_notify, 6, "FriendModule:ApplyVisitResultNotify")
end

function FriendModule:GetVisitOwnerName()
  local visitOwnerName = self.data:GetVisitOwnerName()
  if visitOwnerName and self.data.VisitSwitchScreen then
    self.data.VisitSwitchScreen = false
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("online_enter_succeed_visitor_tips").msg, visitOwnerName))
  end
end

function FriendModule:OperatorApplyVisitNotifyList(State)
  if "Get" == State then
    return self.data:GetApplyVisitNotifyList()
  elseif "Clear" == State then
    self.data:ClearApplyVisitNotifyToList()
  elseif "Remove" == State then
    self.data:RemoveApplyVisitNotifyToList()
  end
end

function FriendModule:OnCmdGetOnlineVisitorList()
  return self.data:GetOnlineVisitorList()
end

function FriendModule:OnCmdGetOnlineVisitorByUin(uin)
  local visitList = self.data:GetOnlineVisitorList()
  if visitList and uin then
    for _, visitor in ipairs(visitList) do
      if visitor.uin == uin then
        return visitor
      end
    end
  end
end

function FriendModule:OnCmdGetOnlineVisitorIndex(uin)
  return self.data:GetVisitIndex(uin)
end

function FriendModule:SetOnlineVisitorChangeNotify(_notify)
  Log.Dump(_notify, 6, "FriendModule:SetOnlineVisitorChangeNotify")
  if _notify.timestamp then
    if _notify.timestamp > self.VisitListRefreshTime then
      self.VisitListRefreshTime = _notify.timestamp
    else
      return
    end
  end
  if self.FirstVisit then
    self.FirstVisit = false
  else
    if not _notify.visitors then
      if _notify.change_reason == ProtoEnum.OnlineVisitorInfoChangeReason.OVICR_VISITOR_NUM then
        self:ClosePanel("Plane_Team")
        if self:HasPanel("Friend") then
          local panel = self:GetPanel("Friend")
          panel:SetItemsVisitState()
        end
        local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
        NRCEventCenter:DispatchEvent(FriendModuleEvent.OnVisitorLeaved, uin)
        Log.Error("\232\167\163\230\149\163\233\152\159\228\188\141")
      end
      return
    end
    local OnlineVisitorList = self.data:GetOnlineVisitorList()
    local ownerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or _notify.visitors[1].uin
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
    local visitOwnerName = _notify.visitors[1].name
    if #OnlineVisitorList > 0 then
      local leaveVisitorName = ""
      local leaveVisitorUin
      for _, OldVisitor in pairs(OnlineVisitorList) do
        local IsFind = false
        leaveVisitorName = OldVisitor.name
        leaveVisitorUin = OldVisitor.uin
        for i, v in ipairs(_notify.visitors) do
          if OldVisitor.uin == v.uin then
            IsFind = true
            break
          end
        end
        if not IsFind then
          NRCEventCenter:DispatchEvent(FriendModuleEvent.OnVisitorLeaved, leaveVisitorUin)
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("online_leave_visitor_tips").msg, leaveVisitorName))
          if ownerUin ~= leaveVisitorUin then
            self:OnCmdAddLocalChatMessage(self.data.MultiPlayerChannelType, string.format(_G.LuaText.online_leave_chat, leaveVisitorName))
          end
        end
      end
      local EnterVisitorName = ""
      local EnterVisitorUin
      for i, v in ipairs(_notify.visitors) do
        local IsFind = false
        EnterVisitorName = v.name
        EnterVisitorUin = v.uin
        for _, OldVisitor in pairs(OnlineVisitorList) do
          if OldVisitor.uin == v.uin then
            IsFind = true
            break
          end
        end
        if not IsFind then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("online_enter_succeed_owner_tips").msg, EnterVisitorName))
          if ownerUin ~= EnterVisitorUin then
            self:OnCmdAddLocalChatMessage(self.data.MultiPlayerChannelType, string.format(_G.LuaText.online_enter_chat, EnterVisitorName))
          end
        end
      end
    else
      if ownerUin ~= playerUin then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("online_enter_succeed_visitor_tips").msg, visitOwnerName))
        self:OnCmdAddLocalChatMessage(self.data.MultiPlayerChannelType, string.format(_G.LuaText.online_enter_chat, _G.DataModelMgr.PlayerDataModel:GetPlayerName()))
      end
      if ownerUin == playerUin then
        for i, v in ipairs(_notify.visitors) do
          if v.uin ~= playerUin then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("online_enter_succeed_owner_tips").msg, v.name))
            self:OnCmdAddLocalChatMessage(self.data.MultiPlayerChannelType, string.format(_G.LuaText.online_enter_chat, v.name))
          end
        end
      end
    end
  end
  local visitList = _notify.visitors
  local visitListInfo = self.data:GetVisitListChangeInfo()
  for i = 1, #visitList do
    for j = 1, #visitListInfo do
      if visitList[i].uin == visitListInfo[j].uin then
        visitList[i].network = visitListInfo[j].network
      end
    end
  end
  self.data:SetOnlineVisitorList(visitList)
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    panel:SetPanelInfo(visitList)
  end
  if self:HasPanel("Friend") then
    local panel = self:GetPanel("Friend")
    panel:SetItemsVisitState(_notify.visitors)
  end
  NRCEventCenter:DispatchEvent(FriendModuleEvent.OnVisitorChanged, _notify)
end

function FriendModule:CmdZoneVisitNetworkSyncReq(PlayerList)
  if PlayerList and #PlayerList > 0 then
    local visitList = self.data:GetOnlineVisitorList()
    if HomeIndoorSandbox:InHomeIndoor() or _G.FarmModuleCmd and _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) then
      local home_owner_id = HomeIndoorSandbox.Server.MasterId
      if home_owner_id and home_owner_id > 0 then
      else
        local homeInfo = FarmUtils.GetCurrentWorldHomeInfo()
        if homeInfo then
          home_owner_id = homeInfo.home_owner_id
        end
      end
      local req = _G.ProtoMessage:newZoneSceneHomeGetVisitorInfoReq()
      req.home_owner_id = home_owner_id
      self.HomePlayerList = PlayerList
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_HOME_GET_VISITOR_INFO_REQ, req, self, self.ZoneGetHomeNetWorkRsp, false, true)
      return
    elseif #visitList > 1 then
      self.HomePlayerList = PlayerList
      for i = 1, #self.HomePlayerList do
        self.HomePlayerList[i].network = _G.ZoneServer:GetTConndRTT()
      end
      self:OpenPanel("Plane_Team", self.HomePlayerList)
      return
    end
  end
  self:OnOpenFriendPanelTeam()
  local _req = _G.ProtoMessage:newZoneQueryVisitorInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_VISITOR_INFO_REQ, _req, self, self.GetZoneQueryVisitorInfoRsp, false, true)
end

function FriendModule:GetZoneQueryVisitorInfoRsp(rsp)
  Log.Debug("ZoneGetHomeNetWorkRsp")
end

function FriendModule:ZoneGetHomeNetWorkRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local homeVisitInfo = rsp.visitor_info
    if homeVisitInfo and #homeVisitInfo > 0 then
      Log.Error("ZoneGetHomeNetWorkRsp")
      for _, v in ipairs(homeVisitInfo) do
        for i = 1, #self.HomePlayerList do
          if self.HomePlayerList[i].uin == v.uin then
            self.HomePlayerList[i].network = v.network_latency_ms
          end
        end
      end
    end
  end
  self:OpenPanel("Plane_Team", self.HomePlayerList)
end

function FriendModule:SetOnlineVisitorInfoNotify(_notify)
  self.data:SetVisitListChangeInfo(_notify.visitor_info)
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SetVisitListInfo, _notify.visitor_info)
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    panel:SetNetWork(_notify.visitor_info)
  end
end

function FriendModule:OnOpenFriendPanelTeam()
  local visitList = self.data:GetOnlineVisitorList()
  if #visitList < 1 then
    visitList = _G.DataModelMgr.PlayerDataModel.visitList
    visitList = visitList or {}
  end
  local visitListInfo = self.data:GetVisitListChangeInfo()
  for i = 1, #visitList do
    for j = 1, #visitListInfo do
      if visitList[i].uin == visitListInfo[j].uin then
        visitList[i].network = visitListInfo[j].network
      end
    end
  end
  Log.Dump(visitList, 6, "FriendModule:OnOpenFriendPanelTeam")
  self.data:SetOnlineVisitorList(visitList)
  self.data:SetFriendSelectEntranceType(FriendEnum.SELECT_TAB.VisitPanelList)
  self:OpenPanel("Plane_Team", visitList)
end

function FriendModule:SetZoneDisbandVisitReq()
  local Req = _G.ProtoMessage:newZoneSceneDisbandVisitReq()
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_DISBAND_VISIT_REQ, Req)
end

function FriendModule:GetZoneDisbandVisitRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ONLY_OWNER_DISBAND_VISIT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2157").msg)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function FriendModule:SetZoneKickOutVisitReq(uin)
  local visitList = self.data:GetOnlineVisitorList()
  if #visitList <= 2 then
    self:SetZoneDisbandVisitReq()
    return
  end
  local Req = _G.ProtoMessage:newZoneSceneKickOutVisitReq()
  Req.kick_out_uin = uin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_KICK_OUT_VISIT_REQ, Req, self, self.GetKickOutVisitRsp, false, true)
end

function FriendModule:GetKickOutVisitRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    Log.Error("\232\184\162\228\186\186\230\136\144\229\138\159")
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_KICK_OUT_ISNT_ONLINE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2159").msg)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISITOR_HAS_BEEN_LEFT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2170").msg)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function FriendModule:SetZoneExitVisitReq()
  if self:HasPanel("Plane_ExchangeVisits_Hint") then
    local panel = self:GetPanel("Plane_ExchangeVisits_Hint")
    local Reason = panel.Reason
    if Reason == FriendEnum.ExchangeVisitsType.TeamBattle then
      _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SendZoneTeamBattleConfirmInviteReq, false)
    end
  end
  local Req = _G.ProtoMessage:newZoneSceneExitVisitReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_EXIT_VISIT_REQ, Req, self, self.GetZoneExitVisitRsp, false, true)
end

function FriendModule:GetZoneExitVisitRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:ClosePanel("Plane_Team")
    Log.Error("\233\128\128\229\135\186\230\136\191\233\151\180")
    self.data:SetVisitOwnerName(nil)
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
    NRCEventCenter:DispatchEvent(FriendModuleEvent.OnVisitorLeaved, playerUin)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_OWNER_MUST_DISBAND_VISIT_FIRSTLY then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2156").msg)
  end
end

function FriendModule:GetZoneLeaveOnlineVisitNotify(notify)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ClearTipsList)
  if 0 == notify.reason then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_leave_visitor_self").msg)
  elseif 1 == notify.reason then
    self:ClosePanel("Plane_Team")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_leave_visitor_self").msg)
    if self:HasPanel("Friend") then
      self:ClosePanel("Friend")
    end
    self.data:SetVisitOwnerName(nil)
    _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.CloseModuleAllPanel)
  elseif 2 == notify.reason then
    if self:HasPanel("Friend") then
      self:ClosePanel("Friend")
    end
    self:ClosePanel("Plane_Team")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_leave_visitor_forced").msg)
    self.data:SetVisitOwnerName(nil)
  end
  self.data:RemoveSessionInfo(self.data.MultiPlayerChannelType)
  self:OnCmdCloseChatMainPanel()
end

function FriendModule:CmdClosePlaneExchangeVisitsHint(IsEnterBattle)
  self:ClosePanel("Plane_ExchangeVisits_Hint")
  self:ClosePanel("Plane_ExchangeVisits")
  if IsEnterBattle then
    self.data:ClearApplyVisitNotifyToList()
  end
end

function FriendModule:CmdClosePlane_Team()
  if self:HasPanel("Friend") then
    local panel = self:GetPanel("Friend")
    panel:SetItemsVisitState()
  end
  local list = {}
  self.data:SetOnlineVisitorList(list)
  if self:HasPanel("Plane_Team") then
    self:ClosePanel("Plane_Team")
  end
end

function FriendModule:CmdBattleClosePlane_Team()
  if self:HasPanel("Plane_Team") then
    self:ClosePanel("Plane_Team")
  end
  self:ClearAllBubbles(true)
end

function FriendModule:CmdOnPCKeyPressClosePlane_Team()
  if self:HasPanel("Plane_Team") then
    self:ClosePanel("Plane_Team")
  end
end

function FriendModule:OnOpenMainPanel(IsOpenAssignPanel, entrance)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FRIEND, true)
  if isBan then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
    return
  end
  local PanelName = "Friend"
  self:MarkPanelWaitingOpen(PanelName)
  local curTime = os.msTime() / 1000.0
  self.data:SetLastFriendListAutoRefreshTimeSec(ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME, curTime)
  self.data:SetLastChangeTabRefreshTimeSec(ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME, curTime)
  self.data:RequestFriendRoleInfo(self, self.OnOpenMainPanelRsp, FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault, nil, ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME)
  _G.NRCSDKManager:GetWeGameFriendsInfo()
  self:OnCmdSetEntrance(entrance)
  self:ChitchatOpenFriendPanel()
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
  local bInFighting = false
  if myPlayer then
    bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  end
  if bInFighting and "FriendChat" == PanelName then
    local panelDynamicData = NRCPanelDynamicData()
    panelDynamicData:SetModifiedPanelLayerType(Enum.UILayerType.UI_LAYER_TOP)
    self:OpenPanel(PanelName, panelDynamicData)
  else
    self:OpenPanel(PanelName)
  end
end

function FriendModule:OnOpenMainPanelRsp(friendList, clientFriendScene)
  self.data:UpdateInfo()
  Log.Debug("[FriendModule:OnOpenMainPanelRsp] OnFriendDataUpdate")
  self:DispatchEvent(FriendModuleEvent.OnFriendDataUpdate)
end

function FriendModule:OnCmdQQArkServerInviteFriendReq(uin)
  local req = _G.ProtoMessage:newZoneInviteFriendReq()
  req.friend_uin = uin
  Log.DebugFormat("[FriendModule:OnCmdQQArkServerInviteFriendReq] friend_uin=%s", tostring(req.friend_uin))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_INVITE_FRIEND_REQ, req, self, self.OnQQArkServerInviteFriendRsp, false, false)
end

function FriendModule:OnQQArkServerInviteFriendRsp(rsp)
  Log.DebugFormat("[FriendModule:OnQQArkServerInviteFriendRsp] ret_code=%s", tostring(rsp.ret_info.ret_code))
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Invite_Friend_Limit5)
  end
end

function FriendModule:OnCmdQQArkGetClientInviteInfoReq()
  if self.data:GetLoginChannelType() ~= Enum.CliLoginChannel.CLC_QQ then
    Log.WarningFormat("[FriendModule:OnQQArkGetClientInviteInfoReq] Not QQ Login Channel, return, loginChannelType=%s", tostring(self.data:GetLoginChannelType()))
    return
  end
  local req = _G.ProtoMessage:newZoneGetSignedCommArkReq()
  req.business_type = Enum.QQArkBusinessType.QQ_ARK_BUSINESS_TYPE_CLIENT_INVITE
  Log.DebugFormat("[FriendModule:OnQQArkGetClientInviteInfoReq] business_type=%s", tostring(req.business_type))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_SIGNED_COMM_ARK_REQ, req, self, self.OnQQArkGetClientInviteInfoRsp, false, false)
end

function FriendModule:OnQQArkGetClientInviteInfoRsp(rsp)
  Log.DebugFormat("[FriendModule:OnQQArkGetClientInviteInfoRsp] business_type=%s, rsp.signed_ark=%s, ret_code=%s", tostring(rsp.business_type), tostring(rsp.signed_ark), tostring(rsp.ret_info.ret_code))
  if 0 == rsp.ret_info.ret_code then
    if not rsp.business_type then
      rsp.business_type = Enum.QQArkBusinessType.QQ_ARK_BUSINESS_TYPE_CLIENT_INVITE
    end
    self.data:SetQQArkJsonByInviteType(rsp.business_type, rsp.signed_ark)
    self:DispatchEvent(FriendModuleEvent.OnQQArkClientInviteInfoRsp, rsp.business_type)
  end
end

function FriendModule:EnableMainPanel()
  local panel = self:GetPanel("Friend")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function FriendModule:PreLoadMainPanel()
  self:PreLoadPanel("Friend", 10)
end

function FriendModule:OnCmdSetEntrance(entrance)
  if self:HasPanel("Chat_Main") then
    Log.Info("FriendModule:OnCmdSetEntrance Chat_Main")
    self.data:SetEntrance(FriendEnum.OpenFriendEntrance.Chat)
  else
    Log.Info("FriendModule:OnCmdSetEntrance Compass")
    self.data:SetEntrance(FriendEnum.OpenFriendEntrance.Compass)
  end
  if entrance then
    Log.Info("FriendModule:OnCmdSetEntrance entrance: ", entrance)
    self.data:SetEntrance(entrance)
  end
end

function FriendModule:OnCmdGetEntrance()
  return self.data:GetEntrance()
end

function FriendModule:GMVisitFriendNotFriendPanel(uin)
  if not uin then
    return
  end
  local req = _G.ProtoMessage:newZoneSceneGmAutoEnterVisitReq()
  req.owner_uin = uin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrGmCmd.ZONE_SCENE_GM_AUTO_ENTER_VISIT_REQ, req, self, self.OnZoneSceneGmAutoEnterVisitRsp, false, true)
end

function FriendModule:OnZoneSceneGmAutoEnterVisitRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\229\191\171\233\128\159\228\186\146\232\174\191\230\147\141\228\189\156\229\164\177\232\180\165!!!", rsp.ret_info.ret_code)
  end
end

function FriendModule:StartFriendVisitNotFriendPanel(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    self:ReqZonePlayerInteract(Rsp.player_info.uin, ProtoEnum.PlayerInteractType.Visiting)
  end
end

function FriendModule:OnOpenFriendInfoFrame(_data, screenPos, SelectTab)
  self:OpenPanel("Friend_Function", _data, screenPos, SelectTab)
end

function FriendModule:OnCloseFriendInfoFrame()
  if self:HasPanel("Friend_Function") then
    self:ClosePanel("Friend_Function")
  end
  if self:HasPanel("ChangeSign") then
    self:ClosePanel("ChangeSign")
  end
end

function FriendModule:OnCmdSelectFriendTabIndex(FriendTab)
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    FriendTab = 1
    GlobalConfig.OpenMainPanelFromDebugBtn = 0
  elseif 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    FriendTab = 2
    GlobalConfig.OpenMainPanelFromDebugBtn = 0
  end
  self:ReportTLog(2, FriendTab == FriendEnum.FriendTab.SearchFriend and 2 or 1)
  self.FriendTab = FriendTab
  if FriendTab == FriendEnum.FriendTab.GameFriend then
    self.data:SetFriendSelectEntranceType(FriendEnum.SELECT_TAB.FriendList)
    self:OnSetSelectFriendTabIndex()
  elseif FriendTab == FriendEnum.FriendTab.PlatformFriend then
    self.data:SetFriendSelectEntranceType(FriendEnum.SELECT_TAB.FriendApply)
    self:OnSetSelectFriendTabIndex()
  elseif FriendTab == FriendEnum.FriendTab.SearchFriend then
    self.data:SetFriendSelectEntranceType(FriendEnum.SELECT_TAB.AddFriend)
    self:OnSetSelectFriendTabIndex()
  elseif FriendTab == FriendEnum.FriendTab.WeGameFriend then
    self.data:SetFriendSelectEntranceType(FriendEnum.SELECT_TAB.WeGameFriend)
    self:OnSetSelectFriendTabIndex()
  end
end

function FriendModule:SetFriendApplyFor()
  self.data:RequestFriendRequestInfo(self, self.OnSetFriendApplyFor)
end

function FriendModule:OnSetFriendApplyFor()
  self.data:SetFriendApplyForList()
  self:OnSetSelectFriendTabIndex()
end

function FriendModule:OnSetSelectFriendTabIndex()
  self:DispatchEvent(FriendModuleEvent.ChangeFriendTab, self.FriendTab)
end

function FriendModule:OnOpenFriendApplyForPanel()
  self.data:RequestFriendRequestInfo(self, self.OnFriendApplyFor)
end

function FriendModule:CmdActorEnterAction(actor)
  local visitList = self.data:GetOnlineVisitorList()
  local num = #visitList
  for i = 1, num do
    if visitList[i].uin == actor.logic_id then
      visitList[i].name = actor.name
    end
  end
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    panel:SetPanelInfo(visitList)
  end
end

function FriendModule:CmdFriendChangeName(uin, name)
  local visitList = self.data:GetOnlineVisitorList()
  local num = #visitList
  for i = 1, num do
    if visitList[i].uin == uin then
      visitList[i].name = name
    end
  end
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    panel:SetPanelInfo(visitList)
  end
end

function FriendModule:OnFriendApplyFor()
  self.data:SetFriendApplyForList()
  self:OpenPanel("Friend_ApplyFor_Blacklist")
end

function FriendModule:OnOpenFriendBlackList()
  self.data:SetFriendSelectEntranceType(FriendEnum.SELECT_TAB.BlackList)
  self.data:RequestBlackListRoleInfo(self, self.OnFriendBlackList)
end

function FriendModule:OnFriendBlackList()
  self.data:SetFriendBlackList()
  self:OpenPanel("Friend_ApplyFor_Blacklist")
end

function FriendModule:OnEnableOrDisableBlackListOnPopUpOpen(isEnable, bNeedClose)
  if self:HasPanel("Friend_ApplyFor_Blacklist") then
    local panel = self:GetPanel("Friend_ApplyFor_Blacklist")
    if bNeedClose then
      panel:DoClose()
    elseif isEnable then
      panel:SetNeedAnimOnDisable(false)
      panel:Enable()
    else
      panel:SetNeedAnimOnDisable(true)
      panel:Disable()
    end
  end
end

function FriendModule:OnFriendConfirmAddFriend(_uin, _Type)
  self.friendConfirmOperType = _Type
  self.friendConfirmUin = _uin
  local req = _G.ProtoMessage:newZoneFriendConfirmAddFriendReq()
  req.uin = _uin
  req.oper_type = _Type
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_CONFIRM_ADD_FRIEND_REQ, req, self, self.OnFriendConfirmAddFriendRsp, false, true)
end

function FriendModule:OnFriendConfirmAddFriendRsp(rsp)
  local Text
  local IsSucceed = false
  if 0 == rsp.ret_info.ret_code then
    if self.friendConfirmOperType == _G.ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.AGREE_REQ then
      self.data:SetIsFriend(true, rsp.change_friend_role.uin)
      self.data:AddFriendList(rsp.change_friend_role)
      self.data:RemoveFriendApplyForListByUin(rsp.change_friend_role.uin)
    elseif self.friendConfirmOperType == _G.ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.REFUSE_REQ then
      self.data:SetIsFriend(false, self.friendConfirmUin)
      self.data:RemoveFriendApplyForListByUin(self.friendConfirmUin)
    end
    IsSucceed = true
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_MINE then
    Text = _G.DataConfigManager:GetLocalizationConf("friend_apply_num_max_unable_send_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_NOT_EXIST then
    Text = _G.DataConfigManager:GetLocalizationConf("friend_apply_valid_agree_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MINE_BLACK_LIMIT then
    Text = _G.DataConfigManager:GetLocalizationConf("blacklist_again_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_OTHERS then
    Text = _G.DataConfigManager:GetLocalizationConf("Error_Code_13010").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local reasonStr = rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
  if Text then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  end
  self:DispatchEvent(FriendModuleEvent.UpdateFriendTabInfo)
  self:DispatchEvent(FriendModuleEvent.OnFriendApplyListUpdate)
  local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").ACCEPT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType1)
  local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").DELETE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType2)
end

function FriendModule:OnAddOrRemoveBlackList(_uin, Type)
  self.AddOrRemoveBlackUin = _uin
  local req = _G.ProtoMessage:newZoneFriendAddOrRemoveBlackListReq()
  req.uin = _uin
  req.oper_type = Type
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_ADD_OR_REMOVE_BLACK_LIST_REQ, req, self, self.OnAddOrRemoveBlackListRsp, false, true)
end

function FriendModule:OnAddOrRemoveBlackListRsp(_rsp)
  local Text
  if 0 == _rsp.ret_info.ret_code then
    local time = 0
    local AddOrRemoveBlockUin = self.AddOrRemoveBlackUin
    if _rsp.type == _G.ProtoEnum.ZoneFriendAddOrRemoveBlackListReq.TYPE.ADD then
      self.data:SetIsFriend(false, _rsp.changed_black_info.uin)
      self.data:RemoveFriendListByUin(_rsp.changed_black_info.uin)
      self.data:AddFriendBlackList(_rsp.changed_black_info)
      self.data:RemoveFriendApplyForListByUin(_rsp.changed_black_info.uin)
      self.data:RemoveRecommendFriendByUin(_rsp.changed_black_info.uin)
      Text = _G.DataConfigManager:GetLocalizationConf("blacklist_success_tips").msg
      time = _rsp.changed_black_info.block_time
      AddOrRemoveBlockUin = _rsp.changed_black_info.uin
      self.data:RemoveSessionInfo(_rsp.changed_black_info.uin)
      self:RemoveActorMessages(_rsp.changed_black_info.uin, true)
      _G.NRCModuleManager:DoCmd(RelationTreeCmd.AddFriendBlackCloseRelationTree, AddOrRemoveBlockUin)
    else
      self.data:RemoveFriendBlackList(self.AddOrRemoveBlackUin)
      self:RemoveActorMessages(self.AddOrRemoveBlackUin, false)
      if _rsp.change_friend_role and _rsp.change_friend_role.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_PLAT then
        Log.DebugFormat("FriendModule:OnAddOrRemoveBlackListRsp Add Plat Friend Uin=%s", tostring(_rsp.change_friend_role.uin))
        self.data:AddFriendList(_rsp.change_friend_role)
      end
    end
    _G.DataModelMgr.PlayerDataModel:OnAddOrRemoveBlackInfo(_rsp.type, AddOrRemoveBlockUin, time)
    self:DispatchEvent(FriendModuleEvent.AddOrRemoveBlackListUpdate)
    NRCEventCenter:DispatchEvent(FriendModuleEvent.AddOrRemoveBlackListUpdate)
    self:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    self:DispatchEvent(FriendModuleEvent.OnFriendApplyListUpdate)
    self:DispatchEvent(FriendModuleEvent.OnFriendRefreshRecommendSuccess)
    self:CloseStudentCard()
    self:OnCloseFriendInfoFrame()
  elseif _rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MINE_BLACK_LIMIT then
    Text = _G.DataConfigManager:GetLocalizationConf("blacklist_again_tips").msg
  elseif _rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_BLACK_LIST_FULL then
    Text = _G.DataConfigManager:GetLocalizationConf("blacklist_num_max_tips").msg
  end
  if Text then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  end
  local visitList = self.data:GetOnlineVisitorList()
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    panel:SetPanelInfo(visitList)
  end
end

function FriendModule:OnAddFriendApplicationOrRemoveFriend(_uin, AddType, Index)
  self.RemoveFriendUin = _uin
  self.AddType = AddType
  local req = _G.ProtoMessage:newZoneFriendAddOrRemoveFriendReq()
  req.uin = _uin
  req.oper_type = AddType
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_ADD_OR_REMOVE_FRIEND_REQ, req, self, self.OnAddFriendApplicationOrRemoveFriendRsp, false, true)
  self:DispatchEvent(FriendModuleEvent.SelectFriendByIndex, Index)
end

function FriendModule:OnAddFriendApplicationOrRemoveFriendRsp(rsp)
  local Text
  if 0 == rsp.ret_info.ret_code then
    if self.AddType == _G.ProtoEnum.ZoneFriendAddOrRemoveFriendReq.TYPE.ADD_FRIEND then
      Text = _G.DataConfigManager:GetLocalizationConf("add_friend_success_tips").msg
    else
      Text = _G.DataConfigManager:GetLocalizationConf("delete_friend_tips").msg
      self:CloseStudentCard()
    end
    self:OnCloseFriendInfoFrame()
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_MINE then
    Text = _G.DataConfigManager:GetLocalizationConf("friend_apply_num_max_unable_send_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_MINE_BLACK_LIMIT then
    _G.NRCAudioManager:PlaySound2DAuto(1009, "UMG_Friend_Item_C:StartFriendVisit")
    Text = _G.DataConfigManager:GetLocalizationConf("friend_apply_in_blacklist_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_LIMIT then
    Text = _G.DataConfigManager:GetLocalizationConf("friend_apply_different_limit_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_EXIST then
    Text = _G.DataConfigManager:GetLocalizationConf("add_friend_wait_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_EXIST then
    Text = _G.DataConfigManager:GetLocalizationConf("add_friend_repeate_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_REQUEST_FULL then
    Text = _G.DataConfigManager:GetLocalizationConf("friend_apply_list_player_full_tips").msg
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_OTHER_BLACK_LIMIT then
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CREDIT_SCORE_NOT_ENOUGH then
    _G.NRCSDKManager:ShowCreditScoreNotEnoughDialog(NRCSDKManagerEnum.CreditScoreNotEnoughType.AddFriend)
    Text = nil
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local reasonStr = rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
  if Text then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  end
  local visitList = self.data:GetOnlineVisitorList()
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    panel:SetPanelInfo(visitList)
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").ADDFRIEND
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
end

function FriendModule:FriendAddOrRemoveFriendNotify(_notify)
  Log.Debug(_notify.uin, "ZoneFriendAddOrRemoveFriendNotify")
  Log.Debug(_notify.oper_type, "ZoneFriendAddOrRemoveFriendNotify")
  if _notify.oper_type == _G.ProtoEnum.ZoneFriendAddOrRemoveFriendNotify.TYPE.ADD_FRIEND_REQ then
    self.data:AddFriendApplyForList(_notify.new_req_friend)
    if self:HasPanel("Friend_ApplyFor_Blacklist") then
      self:DispatchEvent(FriendModuleEvent.FriendConfirmAddFriendUpdate)
    end
  elseif _notify.oper_type == _G.ProtoEnum.ZoneFriendAddOrRemoveFriendNotify.TYPE.REMOVE_FRIEND then
    self:IsCloseDialogPanel()
    self.data:RemoveFriendListByUin(_notify.uin, _notify.change_friend_role)
    self.data:SetIsFriend(false, _notify.uin)
    self:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    self.data:RemoveSessionInfo(_notify.uin)
    self:OnCloseFriendInfoFrame()
  elseif _notify.oper_type == _G.ProtoEnum.ZoneFriendAddOrRemoveFriendNotify.TYPE.ADD_FRIEND_AGREE then
    self.data:SetIsFriend(true, _notify.uin)
    self.data:AddFriendList(_notify.change_friend_role)
    self.data:RemoveFriendApplyForListByUin(_notify.uin)
    self:DispatchEvent(FriendModuleEvent.OnFriendApplyListUpdate)
    if self:HasPanel("Friend") then
      self:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    end
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
  elseif _notify.oper_type == _G.ProtoEnum.ZoneFriendAddOrRemoveFriendNotify.TYPE.REMOVE_FRIEND_REQ then
    self.data:RemoveFriendApplyForListByUin(_notify.uin)
    self:DispatchEvent(FriendModuleEvent.OnFriendApplyListUpdate)
    if self:HasPanel("Friend_ApplyFor_Blacklist") then
      self:DispatchEvent(FriendModuleEvent.AddOrRemoveBlackListUpdate)
    end
  end
end

function FriendModule:IsCloseDialogPanel()
  local IsHasDialogPanel = _G.NRCModeManager:DoCmd(TipsModuleCmd.IsHasDialogPanel)
  if IsHasDialogPanel then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
  end
end

function FriendModule:newCallBackInfo()
  return {
    callBackOwner = nil,
    func = nil,
    type = nil
  }
end

function FriendModule:ConsumeCallBackInfo()
  while #self.data.settings.callback > 0 do
    local info = table.remove(self.data.settings.callback)
    if info and info.callback and (info.type == "querySuggest" or info.type == "querySearch" or info.type == "setSuggest" or info.type == "setSearch" or info.type == "setStrangerAdd" or info.type == "setStrangerVisit" or info.type == "setPersonalRecommend") then
      if info.callBackOwner then
        if info.type == "setPersonalRecommend" then
          info.callback(info.callBackOwner, self.data.settings.player_settings.recommendations)
        else
          info.callback(info.callBackOwner, self.data.settings.player_settings.friendship)
        end
      elseif info.type == "setPersonalRecommend" then
        info.callback(self.data.settings.player_settings.recommendations)
      else
        info.callback(self.data.settings.player_settings.friendship)
      end
    end
  end
end

function FriendModule:OnCmdQueryWhetherCanBeSuggested(callbackOwner, callback)
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "querySuggest"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ, req, self, self.OnQueryWhetherCanBeSuggestedRsp, false, true)
end

function FriendModule:OnQueryWhetherCanBeSuggestedRsp(Rsp)
  if 0 == not Rsp.ret_info.ret_code then
    return
  end
  if not Rsp.settings.friendship then
    self.data.settings.player_settings.friendship.can_be_searched = true
    self.data.settings.player_settings.friendship.can_be_sugguested = true
    self.data.settings.player_settings.friendship.can_be_add_friend = true
    self.data.settings.player_settings.friendship.can_stranger_visit = true
    self:ConsumeCallBackInfo()
  else
    self.data.settings.player_settings.friendship = Rsp.settings.friendship
    self:ConsumeCallBackInfo()
  end
end

function FriendModule:OnCmdSetWhetherCanStrangerVisit(_inRequest, callbackOwner, callback)
  Log.Info("FriendModule:OnCmdSetWhetherCanStrangerVisit ", _inRequest)
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  self.data.settings.cached_friendship = self.data.settings.player_settings
  self.data.settings.player_settings.friendship.can_stranger_visit = _inRequest
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "setStrangerVisit"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneModifyPlayerSettingsReq()
  req.settings.friendship.can_stranger_visit = _inRequest
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_PLAYER_SETTINGS_REQ, req, self, self.OnSetWhetherCanStrangerVisitRsp, false, true)
end

function FriendModule:OnSetWhetherCanStrangerVisitRsp(Rsp)
  if Rsp and Rsp.ret_info then
    Log.Info("FriendModule:OnSetWhetherCanStrangerVisitRsp ", Rsp.ret_info.ret_code)
  end
  if 0 == not Rsp.ret_info.ret_code then
    self.data.settings.player_settings.friendship = self.data.settings.cached_friendship
    return
  end
  self:ConsumeCallBackInfo()
end

function FriendModule:OnCmdSetWhetherCanPersonalRecommend(_inRequest, callbackOwner, callback)
  Log.Info("FriendModule:OnCmdSetWhetherCanPersonalRecommend ", _inRequest)
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  self.data.settings.cached_friendship = self.data.settings.player_settings
  self.data.settings.player_settings.recommendations.friend_pr = _inRequest
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "setStrangerVisit"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneModifyPlayerSettingsReq()
  req.settings.recommendations.friend_pr = _inRequest
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_PLAYER_SETTINGS_REQ, req, self, self.OnSetWhetherCanPersonalRecommendRsp, false, true)
end

function FriendModule:OnSetWhetherCanPersonalRecommendRsp(Rsp)
  if Rsp and Rsp.ret_info then
    Log.Info("FriendModule:OnSetWhetherCanPersonalRecommendRsp ", Rsp.ret_info.ret_code)
  end
  if 0 == not Rsp.ret_info.ret_code then
    self.data.settings.player_settings.recommendations = self.data.settings.cached_friendship
    return
  end
  self:ConsumeCallBackInfo()
end

function FriendModule:OnCmdSetWhetherCanStrangerAdd(_inResult, callbackOwner, callback)
  Log.Info("FriendModule:OnCmdSetWhetherCanStrangerAdd _inResult", _inResult)
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  self.data.settings.cached_friendship = self.data.settings.player_settings
  self.data.settings.player_settings.friendship.can_be_add_friend = _inResult
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "setStrangerAdd"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneModifyPlayerSettingsReq()
  req.settings.friendship.can_be_add_friend = _inResult
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_PLAYER_SETTINGS_REQ, req, self, self.OnSetWhetherCanStrangerAddRsp, false, true)
end

function FriendModule:OnSetWhetherCanStrangerAddRsp(Rsp)
  if Rsp and Rsp.ret_info then
    Log.Info("FriendModule:OnSetWhetherCanStrangerAddRsp ", Rsp.ret_info.ret_code)
  end
  if 0 == not Rsp.ret_info.ret_code then
    self.data.settings.player_settings.friendship = self.data.settings.cached_friendship
    return
  end
  self:ConsumeCallBackInfo()
end

function FriendModule:OnCmdSetWhetherCanBeSuggested(_inResult, callbackOwner, callback)
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  self.data.settings.cached_friendship = self.data.settings.player_settings
  self.data.settings.player_settings.friendship.can_be_sugguested = _inResult
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "setSuggest"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneModifyPlayerSettingsReq()
  req.settings.friendship.can_be_sugguested = _inResult
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_PLAYER_SETTINGS_REQ, req, self, self.OnSetWhetherCanBeSuggestedRsp, false, true)
end

function FriendModule:OnSetWhetherCanBeSuggestedRsp(Rsp)
  if 0 == not Rsp.ret_info.ret_code then
    self.data.settings.player_settings.friendship = self.data.settings.cached_friendship
    return
  end
  self:ConsumeCallBackInfo()
end

function FriendModule:OnCmdQueryWhetherCanBeSearched(callbackOwner, callback)
  Log.Info("FriendModule:OnCmdQueryWhetherCanBeSearched")
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "querySearch"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ, req, self, self.OnQueryWhetherCanBeSearchedRsp, false, true)
end

function FriendModule:OnQueryWhetherCanBeSearchedRsp(Rsp)
  if Rsp and Rsp.ret_info then
    Log.Info("FriendModule:OnQueryWhetherCanBeSearchedRsp ", Rsp.ret_info.ret_code)
  end
  if 0 == not Rsp.ret_info.ret_code then
    return
  end
  if not Rsp.settings.friendship then
    self.data.settings.player_settings.friendship.can_be_searched = true
    self.data.settings.player_settings.friendship.can_be_sugguested = true
    self.data.settings.player_settings.friendship.can_be_add_friend = true
    self.data.settings.player_settings.friendship.can_stranger_visit = true
    self:ConsumeCallBackInfo()
  else
    Log.Info("FriendModule:OnQueryWhetherCanBeSearchedRsp  can_be_searched ", Rsp.settings.friendship.can_be_searched, " can_be_suggested ", Rsp.settings.friendship.can_be_sugguested, " can_be_add_friend ", Rsp.settings.friendship.can_be_add_friend, "  can_stranger_visit ", Rsp.settings.friendship.can_stranger_visit)
    self.data.settings.player_settings.friendship = Rsp.settings.friendship
    self:ConsumeCallBackInfo()
  end
end

function FriendModule:OnCmdSetWhetherCanBeSearched(_inResult, callbackOwner, callback)
  if not self.data.settings then
    self.data.settings = self.data:newClientPlayerSettings()
  end
  self.data.settings.cached_friendship = self.data.settings.player_settings
  self.data.settings.player_settings.friendship.can_be_searched = _inResult
  if not self.data.settings.callback then
    self.data.settings.callback = {}
  end
  local ongoingInfo = self:newCallBackInfo()
  ongoingInfo.callBackOwner = callbackOwner
  ongoingInfo.callback = callback
  ongoingInfo.type = "setSearch"
  table.insertUnique(self.data.settings.callback, ongoingInfo)
  local req = _G.ProtoMessage:newZoneModifyPlayerSettingsReq()
  req.settings.friendship.can_be_searched = _inResult
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_PLAYER_SETTINGS_REQ, req, self, self.OnSetWhetherCanBeSearchedRsp, false, true)
end

function FriendModule:OnSetWhetherCanBeSearchedRsp(Rsp)
  if 0 == not Rsp.ret_info.ret_code then
    self.data.settings.player_settings.friendship = self.data.settings.cached_friendship
    return
  end
  self:ConsumeCallBackInfo()
end

function FriendModule:OnFriendSearchPlayer(_uin)
  local Now = os.msTime() / 1000.0
  if self.LastSearchPlayerUin == _uin and self.LastSearchPlayerRsp and Now - (self.LastSearchPlayerTime or 0) <= 1.0 then
    Log.DebugFormat("[FriendModule:OnFriendSearchPlayer] Using cached search result for uin %s", tostring(_uin))
    self:OnFriendSearchPlayerRsp(self.LastSearchPlayerRsp)
    return
  end
  local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
  req.uin = _uin
  self.LastSearchPlayerUin = _uin
  self.LastSearchPlayerTime = Now
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnFriendSearchPlayerRsp, false, true)
end

function FriendModule:OnFriendSearchPlayerRsp(Rsp)
  if Rsp and Rsp.player_info and Rsp.player_info.uin then
    self.LastSearchPlayerUin = Rsp.player_info.uin
  end
  self.LastSearchPlayerRsp = Rsp
  if 0 == Rsp.ret_info.ret_code then
    self.data:SetIsSearchSucceed(true)
    if Rsp.player_info and Rsp.can_be_add_friend ~= nil then
      Rsp.player_info.can_be_add_friend = Rsp.can_be_add_friend
      Log.DebugFormat("FriendModule:OnFriendSearchPlayerRsp can_be_add_friend = %s, uin = %s", tostring(Rsp.can_be_add_friend), tostring(Rsp.player_info.uin))
    end
    self.data:SetIsFriend(Rsp.is_friend, Rsp.player_info.uin)
    self.data:SetSearchInfo(Rsp.player_info)
    self:DispatchEvent(FriendModuleEvent.IsSearchSucceed, self.data:GetIsSearchSucceed())
  else
    self.data:SetIsSearchSucceed(false)
    self.data:SetIsFriend(false)
    self.data:SetSearchInfo(nil)
    local Text
    if Rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.DbErr.DB_DATA_LOAD_EMPTY then
      Text = _G.DataConfigManager:GetLocalizationConf("search_UID_nonexist_tips").msg
    elseif Rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_NOT_OPER_MYSELF then
      Text = _G.DataConfigManager:GetLocalizationConf("search_UID_myself").msg
    elseif Rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and Rsp.ban_info then
      local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
      local uin = Rsp.ban_info.uin
      local ban_time = os.date("%Y-%m-%d %H:%M:%S", Rsp.ban_info.ban_time)
      local reasonStr = Rsp.ban_info.ban_reason or ""
      local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
      local dialogContext = DialogContext()
      dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    else
      Text = _G.DataConfigManager:GetLocalizationConf("search_UID_nonexist_tips").msg
    end
    if Text then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    end
  end
end

function FriendModule:OnOpenFriendRemark(_data)
  self:OpenPanel("Friend_Remark", _data, self:GetPanelAdaptationLayer())
end

function FriendModule:OnCloseFriendRemark()
  self:ClosePanel("Friend_Remark")
end

function FriendModule:OpenUIFriendRequest()
  self.data:RequestFriendRequestInfo()
  self:OpenPanel("FriendRequest")
end

function FriendModule:OnOpenFriendReport(_Data, closeCallbackCaller, closeCallback)
  self:OpenPanel("Friend_Report", _Data, closeCallbackCaller, closeCallback)
end

function FriendModule:OnCmdCloseFriendReport()
  self:ClosePanel("Friend_Report")
end

function FriendModule:OnModifyFriendRemark(_uin, note)
  local req = _G.ProtoMessage:newZoneFriendUpdateFriendInfoReq()
  req.uin = _uin
  req.type = _G.ProtoEnum.UpdateFriendInfoType.MODIFY_NOTE
  req.note = note
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_UPDATE_FRIEND_INFO_REQ, req, self, self.OnModifyFriendInfoRsp, false, true)
end

function FriendModule:OnModifyFriendTopReq(_uin, _need_top)
  local req = _G.ProtoMessage:newZoneFriendUpdateFriendInfoReq()
  req.uin = _uin
  req.type = _G.ProtoEnum.UpdateFriendInfoType.MODIFY_PINNED
  req.is_pinned = _need_top
  Log.Debug("[FriendModule:OnModifyFriendTopReq] uin = " .. _uin .. ", type = " .. tostring(req.type) .. ",1 is_pinned= " .. tostring(req.is_pinned))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_UPDATE_FRIEND_INFO_REQ, req, self, self.OnModifyFriendInfoRsp, false, true)
end

function FriendModule:OnModifyFriendInfoRsp(_rsp)
  Log.Dump(_rsp, 3, "[FriendModule:OnModifyFriendInfoRsp]")
  if 0 == _rsp.ret_info.ret_code then
    if _rsp.type == _G.ProtoEnum.UpdateFriendInfoType.MODIFY_NOTE then
      self.data:SetFriendRemark(_rsp.uin, _rsp.note)
      _G.DataModelMgr.PlayerDataModel:UpdateFriendBriefInfoWithNote(_rsp.uin, _rsp.note)
      self.data:RefreshSessionNote(_rsp.uin, _rsp.note)
      self:DispatchEvent(FriendModuleEvent.ModifyFriendRemarkUpdate, _rsp.uin, _rsp.note)
      _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.ModifyFriendRemarkUpdate, _rsp.uin, _rsp.note)
      self:ClosePanelByName("Friend_Remark")
      self:OnCloseFriendInfoFrame()
    elseif _rsp.type == _G.ProtoEnum.UpdateFriendInfoType.MODIFY_PINNED then
      self.data:UpdateFriendTopInfo(_rsp.uin, _rsp.pinned_time)
      self.data:UpdatePlayerCardBriefInfoPinnedTime(_rsp.uin, _rsp.pinned_time)
      _G.DataModelMgr.PlayerDataModel:UpdateFriendBriefInfoWithPinnedTime(_rsp.uin, _rsp.pinned_time)
      self.data:SortFriendRoleList()
      local Text = _rsp.pinned_time and 0 ~= _rsp.pinned_time and LuaText.friend_top_friend_tips or LuaText.friend_cancel_top_friend_tips
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      self:DispatchEvent(FriendModuleEvent.ModifyFriendTopUpdate, _rsp.uin, _rsp.pinned_time)
    end
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_NOTE_INVALID then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.input_sensitive_words_tips)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_NOTE_FULL_BLANK then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_1095)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_FULL_PINNED then
    local tips = string.safeFormat(LuaText.Error_Code_13022, self.data:GetFriendTopMaxNum())
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  else
    Log.Error("[FriendModule:OnModifyFriendTopRsp] failed, ret_code = " .. _rsp.ret_info.ret_code)
  end
end

function FriendModule:OnBatchRemoveFriendReq(uinList)
  if not uinList or 0 == #uinList then
    Log.Error("[FriendModule:OnBatchRemoveFriendReq] uinList is empty")
    return
  end
  local req = _G.ProtoMessage:newZoneFriendBatchRemoveFriendReq()
  req.uin_list = uinList
  Log.Debug("[FriendModule:OnBatchRemoveFriendReq] uin_list num = " .. #uinList)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_BATCH_REMOVE_FRIEND_REQ, req, self, self.OnBatchRemoveFriendRsp, false, true)
end

function FriendModule:OnBatchRemoveFriendRsp(rsp)
  Log.Dump(rsp, 2, "[FriendModule:OnBatchRemoveFriendRsp]")
  if 0 == rsp.ret_info.ret_code then
    for _, uin in ipairs(rsp.uin_list) do
      self.data:RemoveFriendListByUin(uin)
      self.data:SetIsFriend(false, uin)
      self.data:RemoveSessionInfo(uin)
    end
    self:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.delete_friend_tips)
  else
    Log.Error("[FriendModule:OnBatchRemoveFriendRsp] failed, ret_code = " .. rsp.ret_info.ret_code)
  end
end

function FriendModule:OnFriendRefreshRecommendReq(isResetCount)
  if isResetCount then
    self.data:SetRecommendRefreshCount(0)
  end
  local refreshCount = self.data:GetRecommendRefreshCount()
  local cdMsTime = self.data:GetRecommendRefreshCDMsTime()
  local curMsTime = os.msTime()
  if refreshCount > 1 and cdMsTime > curMsTime - self.data:GetLastMsTimeRecommendRefresh() then
    local cdLeft = math.ceil((cdMsTime - (curMsTime - self.data:GetLastMsTimeRecommendRefresh())) / 1000)
    Log.InfoFormat("[FriendModule:OnFriendRefreshRecommendReq] CD not enough, please wait, cdLeft = %d seconds", cdLeft)
    return false, cdLeft
  end
  local req = _G.ProtoMessage:newZoneFriendGetRecommendFriendListReq()
  req.count = refreshCount
  local filterBitFlag = self.data:GetRecommendFilterSourceBitFlag()
  if filterBitFlag > 0 then
    req.source = filterBitFlag
  end
  Log.Debug("[FriendModule:OnGetRecommendFriendListReq] req count = " .. refreshCount .. ", curMsTime = " .. curMsTime .. ", source = " .. filterBitFlag)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_RECOMMEND_FRIEND_LIST_REQ, req, self, self.OnFriendRefreshRecommendRsp, false, true)
  self.data:SetLastMsTimeRecommendRefresh(curMsTime)
  self.data:SetRecommendRefreshCount(refreshCount + 1)
  return true, 0
end

function FriendModule:OnFriendRefreshRecommendRsp(rsp)
  Log.Dump(rsp, 3, "[FriendModule:OnGetRecommendFriendListRsp]")
  if 0 == rsp.ret_info.ret_code then
    local num = rsp.recommend_player_list and #rsp.recommend_player_list or 0
    Log.Debug("[FriendModule:OnGetRecommendFriendListRsp] recommend_friend_list num = " .. num)
    self.data:SetStrangeFriendList(rsp.recommend_player_list)
    self:DispatchEvent(FriendModuleEvent.OnFriendRefreshRecommendSuccess)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_OPT_TOO_FREQUENT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_13023)
    Log.Error("[FriendModule:OnGetRecommendFriendListRsp] failed, ERR_FRIEND_OPT_TOO_FREQUENT")
  else
    Log.Error("[FriendModule:OnGetRecommendFriendListRsp] failed, ret_code = " .. rsp.ret_info.ret_code)
  end
end

function FriendModule:OnSetPlayerCardCollectPetInfoReq(card_module_id, collect_pet_info)
  collect_pet_info = collect_pet_info or {}
  local req = _G.ProtoMessage:newZoneSetPlayerCardCollectPetInfoReq()
  req.collect_pet_info = collect_pet_info
  req.card_module_id = card_module_id
  Log.Debug("[FriendModule:OnSetPlayerCardCollectPetInfoReq] card_module_id = " .. card_module_id .. " collect_pet_info num = " .. #collect_pet_info)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_COLLECT_PET_INFO_REQ, req, self, self.OnSetPlayerCardCollectPetInfoRsp, false, false)
end

function FriendModule:OnSetPlayerCardCollectBadgeInfoReq(card_module_id, collect_fashion_info)
  if not card_module_id then
    Log.Error("[FriendModule:OnSetPlayerCardCollectBadgeInfoReq] card_module_id is nil")
    return
  end
  collect_fashion_info = collect_fashion_info or {}
  local req = _G.ProtoMessage:newZoneSetPlayerCardCollectFashionInfoReq()
  req.collect_fashion_info = collect_fashion_info
  req.card_module_id = card_module_id
  Log.Debug("[FriendModule:OnSetPlayerCardCollectBadgeInfoReq] card_module_id = " .. card_module_id .. " collect_fashion_info num = " .. #collect_fashion_info)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_COLLECT_FASHION_INFO_REQ, req, self, self.OnSetPlayerCardCollectBadgeInfoRsp, false, false)
end

function FriendModule:OnSetPlayerCardCollectBadgeInfoRsp(rsp)
  self:HandlePlayerCardCollectRsp(rsp.ret_info, rsp.card_brief_info)
end

function FriendModule:OnSetPlayerCardCollectPetInfoRsp(rsp)
  self:HandlePlayerCardCollectRsp(rsp.ret_info, rsp.card_brief_info)
end

function FriendModule:HandlePlayerCardCollectRsp(ret_info, card_brief_info)
  if 0 == ret_info.ret_code then
    local num = 0
    if card_brief_info and card_brief_info.card_collect_info and card_brief_info.card_collect_info.card_module_pet_infos then
      num = #card_brief_info.card_collect_info.card_module_pet_infos
    end
    Log.Debug("[FriendModule:OnSetPlayerCardCollectPetInfoRsp] OnSetPlayerCardCollectPetInfoRsp success, card_collect_info num = " .. num)
    _G.DataModelMgr.PlayerDataModel:SetCardBriefInfo(card_brief_info)
    self:DispatchEvent(FriendModuleEvent.OnSetPlayerCardCollectPetSuccess, card_brief_info)
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.rolecard_module_edit_save_succeed)
  else
    Log.Error("[FriendModule:OnSetPlayerCardCollectPetInfoRsp] OnSetPlayerCardCollectPetInfoRsp failed, ret_code = " .. ret_info.ret_code)
  end
end

function FriendModule:OnModifyPlayerRemark(note, fontObject)
  if not UIUtilsTotal.CheckNameIsLegal(note) then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_name_sensitive_tips)
    Log.Debug("[FriendModule:OnModifyPlayerRemark] note has special chars, note: ", note)
    return
  end
  local PlayerReq = _G.ProtoMessage:newZoneSetPlayerNameReq()
  PlayerReq.name = note
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_NAME_REQ, PlayerReq, self, self.OnModifyPlayerRemarkRsp, false, true)
end

function FriendModule:OnModifyPlayerRemarkRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:SetPlayerOpenid(_rsp.name)
    self:DispatchEvent(FriendModuleEvent.ModifyPlayerNameUpdate, _rsp.name)
    self:DispatchEvent(FriendModuleEvent.NotifyNameChangeRsp, _rsp)
    _G.NRCModeManager:DoCmd(LevelUpUIModuleCmd.ChangeLevelPlayerName)
    _G.NRCModeManager:DoCmd(SystemSettingModuleCmd.ChangePlayerName)
    self:ClosePanelByName("Friend_Remark")
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_name_modify_tips)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_name_sensitive_tips)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_NOTE_FULL_BLANK then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.friend_remake_affirm_empty)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RENAME_CD_NOT_ENOUGH then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.role_rename_cd_des)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_INVALID_SIGNATURE_LEN then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.friendmodule_2)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NAME_DUPLICATE then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_name_repet_tips)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NAME_EMPTY then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_name_empty_tips)
  else
    Log.Error("[FriendModule:OnModifyPlayerRemarkRsp] failed, ret_code = " .. _rsp.ret_info.ret_code)
  end
end

function FriendModule:ClosePanelByName(Name)
  if self:HasPanel(Name) then
    local panel = self:GetPanel(Name)
    if panel then
      panel:OnClose()
    end
  end
end

function FriendModule:OnReportPlayer(_uin, businessInfo)
  local req = _G.ProtoMessage:newZoneReportSafetyDataReq()
  req.reported_uin = _uin
  req.business_data = businessInfo
  self.reportScene = businessInfo.report_scene
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_REPORT_SAFETY_DATA_REQ, req, self, self.OnReportPlayerRsp, false, true)
end

function FriendModule:OnReportPlayerRsp(rsp)
  local panel
  if self:HasPanel("Friend_Report") then
    panel = self:GetPanel("Friend_Report")
  end
  if panel then
    panel.UploadHomeReportSuccessBegin = false
    if panel.EventListener then
      panel.EventListener:Stop()
    end
  end
  if 0 == rsp.ret_info.ret_code or rsp.ret_info.ret_code == 1065 then
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnReportSuccessEvent, self.reportScene)
    self.reportScene = nil
    local Text = _G.DataConfigManager:GetLocalizationConf("expose_succeed_tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    if panel then
      panel:IsLock(false)
    end
    self:ClosePanelByName("Friend_Report")
    self:OnCloseFriendInfoFrame()
    return
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.input_sensitive_words_tips)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_STR_TOO_LONG then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_1095").msg)
  end
  if panel then
    panel:ClosePanelWithHomeReport()
  end
end

function FriendModule:OnDestruct()
  if self.delayReplyPlayerInteractId then
    _G.DelayManager:CancelDelayById(self.delayReplyPlayerInteractId)
    self.delayReplyPlayerInteractId = nil
  end
  if self.delayReqZoneReplyPlayerInteractId then
    _G.DelayManager:CancelDelayById(self.delayReqZoneReplyPlayerInteractId)
    self.delayReqZoneReplyPlayerInteractId = nil
  end
  if self.MoveEndHandler then
    _G.DelayManager:CancelDelayById(self.MoveEndHandler)
    self.MoveEndHandler = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.AfterEnterScene)
  if self.chatBubbleController_Ref then
    self.chatBubbleController:DestroyForLua()
    self.chatBubbleController_Ref = nil
    self.chatBubbleController = nil
  end
end

function FriendModule:OnClickFriendHead(_ClickHeadInfo)
  self.data:SetClickHeadInfo(_ClickHeadInfo)
end

function FriendModule:OnCmdSetSelectFriendTab(_SelectFriendTabIndex)
  self.data:SetSelectFriendTabIndex(_SelectFriendTabIndex)
end

function FriendModule:OnCmdGetSelectFriendTab()
  return self.data:GetSelectFriendTabIndex()
end

function FriendModule:OnCmdGetFriendSelectEntranceType()
  return self.data:GetFriendSelectEntranceType()
end

function FriendModule:OnCmdOpenFriendWold(FriendInfo, Index)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_VISITOR, true)
  if isBan then
    return
  end
  self.FriendInfo = FriendInfo
  self.Index = Index
  local req = _G.ProtoMessage:newZoneSceneQueryBossNpcInfoReq()
  req.friend_uin = FriendInfo.uin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUERY_BOSS_NPC_INFO_REQ, req, self, self.OnZoneSceneQueryBossNpcInfoRsp, false, true)
end

function FriendModule:OnZoneSceneQueryBossNpcInfoRsp(Rsp)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").WORLD
  if 0 == Rsp.ret_info.ret_code then
    self:OnCmdOpenFriendWorld(Rsp.flower_npcs, self.FriendInfo)
  elseif Rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NEED_LOGIN then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2149").msg)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  elseif Rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_ACTOR_NOT_READY then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2149").msg)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  elseif Rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_AVATAR_NOT_FOUND then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("Error_Code_2149").msg)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  else
    self:DealErrorCodeForInteract(Rsp)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  end
  self:DispatchEvent(FriendModuleEvent.SelectFriendByIndex, self.Index)
end

function FriendModule:OnCmdGetFriendByUin(Uin)
  return self.data:GetFriendByUin(Uin)
end

function FriendModule:OnCmdGetLocalFindPlayerInfoByUin(uin)
  local playerInfo
  playerInfo = self.data:GetFriendByUin(uin)
  if playerInfo then
    return playerInfo
  end
  playerInfo = self.data:GetStrangeFriendInfo(uin)
  if playerInfo then
    return playerInfo
  end
  playerInfo = self.data:GetSearchInfo()
  return playerInfo
end

function FriendModule:OnCmdGetFriendNewRemarkByUin(uin)
  return self.data:GetFriendNewRemarkByUin(uin)
end

function FriendModule:OnCmdOpenFriend_CaptureTips()
  self:OpenPanel("Friend_CaptureTips")
end

function FriendModule:OnCmdOpenChatMainPanel(uin, index, bCloseLobbyMain, bOpenByQuickChat, bOpenInBattle)
  Log.DebugFormat("FriendModule:OnCmdOpenChatMainPanel uin=%s, index=%s, bCloseLobbyMain=%s, bOpenByQuickChat=%s, bOpenInBattle=%s", tostring(uin), tostring(index), tostring(bCloseLobbyMain), tostring(bOpenByQuickChat), tostring(bOpenInBattle))
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHAT, true)
  if isBan then
    Log.Error("FriendModule:OnCmdOpenChatMainPanel isBan")
    return
  end
  self.bOpenByQuickChat = bOpenByQuickChat
  self.data:SetbOpenByQuickChat(bOpenByQuickChat)
  if nil == bOpenInBattle then
    local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
    local bInFighting = false
    if myPlayer then
      bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    end
    if bInFighting then
      bOpenInBattle = bInFighting
      Log.DebugFormat("FriendModule:OnCmdOpenChatMainPanel bOpenInBattle not passed, set to bInFighting=%s", tostring(bInFighting))
    end
  end
  self.bOpenInBattle = bOpenInBattle
  if bOpenInBattle then
    local panelDynamicData = NRCPanelDynamicData()
    panelDynamicData:SetModifiedPanelLayerType(Enum.UILayerType.UI_LAYER_TOP)
    self.chatMainPanelDynamicData = panelDynamicData
  else
    self.chatMainPanelDynamicData = nil
  end
  self.data:SetbCloseLobbyMain(bCloseLobbyMain)
  self:MarkPanelWaitingOpen("Chat_Main")
  self:OnZoneChatGetChatListReq(uin, 0)
  self:DispatchEvent(FriendModuleEvent.SelectFriendByIndex, index)
end

function FriendModule:OnCmdCloseChatMainPanel()
  if self:HasPanel("Chat_Main") then
    local chatPanel = self:GetPanel("Chat_Main")
    if chatPanel then
      chatPanel:DoClose()
    end
  end
end

function FriendModule:OnCmdCheckChatMainPanelIsOpen()
  return self:HasPanel("Chat_Main")
end

function FriendModule:OnCmdCloseFriendChatPanel()
  if self:HasPanel("FriendChat") then
    self:ClosePanel("FriendChat")
  end
end

function FriendModule:OnCmdOpenEmoMainPanel(index, bOpen, ChatMode)
  if bOpen then
    local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
    local bInFighting = false
    if myPlayer then
      bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    end
    if bInFighting then
      local panelDynamicData = NRCPanelDynamicData()
      panelDynamicData:SetModifiedPanelLayerType(Enum.UILayerType.UI_LAYER_TOP)
      self:OpenPanel("Emo_Main", index, ChatMode, panelDynamicData)
    else
      self:OpenPanel("Emo_Main", index, ChatMode)
    end
  elseif self:HasPanel("Emo_Main") then
    local panel = self:GetPanel("Emo_Main")
    panel:DoClose()
  end
end

function FriendModule:OnZoneChatGetChatListReq(uin, count)
  local req = _G.ProtoMessage.newZoneChatGetChatListReq()
  req.uin = uin
  req.count = count
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    req.visit_owner_uin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin()
  end
  Log.DebugFormat("FriendModule:OnZoneChatGetChatListReq uin=%s, count=%s, visit_owner_uin=%s", tostring(req.uin), tostring(req.count), tostring(req.visit_owner_uin))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_GET_CHAT_LIST_REQ, req, self, self.DummyRsp, false, true)
end

function FriendModule:DummyRsp(rsp)
end

function FriendModule:OnZoneChatGetChatListRsp(rsp)
  local bOpenByQuickChat = self.data:GetbOpenByQuickChat()
  Log.DebugFormat("FriendModule:OnZoneChatGetChatListRsp ret_code=%s", tostring(rsp.ret_info.ret_code))
  if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_USE_CLIENT_CACHE then
    local friendData = {}
    if rsp.req_uin and 0 ~= rsp.req_uin then
      if self.ChatSessionList and #self.ChatSessionList > 0 then
        for k, v in ipairs(self.ChatSessionList) do
          if v.uin == rsp.uin then
            return
          end
        end
      end
      friendData = self.data:GetFriendByUin(rsp.req_uin)
      local NewSessionInfo = {}
      if friendData then
        local nowTime = math.floor(_G.ZoneServer:GetServerTime())
        table.insert(NewSessionInfo, {
          uin = rsp.req_uin,
          name = friendData.name,
          note = friendData.note,
          head_img = friendData.head_img,
          time_stamp = 0,
          basic_info = {
            uin = rsp.req_uin,
            name = friendData.name,
            time_stamp = nowTime
          },
          friend_session_info = {
            name = friendData.name,
            note = friendData.note,
            head_img = friendData.head_img,
            card_icon_selected = friendData.card_icon_selected,
            online = friendData.online,
            last_logout_time = friendData.last_logout_time,
            state = friendData.state,
            battle_brief_info = friendData.battle_brief_info,
            gende = friendData.gende,
            level_award_info = friendData.level_award_info,
            regist_date = friendData.regist_date,
            world_level = friendData.world_level,
            offline_msg_num = friendData.offline_msg_num
          }
        })
      end
      self.data:SetChatRoleList(NewSessionInfo, rsp.req_uin, nil)
    end
    self.data:SetLatestChatSession(rsp.req_uin or 0, 0)
    self:DoOpenChatMainPanel(rsp.req_uin, self:OnLoadChatPanelRes(), bOpenByQuickChat, self.bOpenInBattle, self.chatMainPanelDynamicData)
    self.bOpenByQuickChat = nil
    self.bOpenInBattle = nil
    self.chatMainPanelDynamicData = nil
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_MSG_DIRTY then
    self:UnlockMultiTouchLimit()
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_NOT_FRIEND then
    self:UnlockMultiTouchLimit()
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_SESSION_NOT_EXIST then
    self:UnlockMultiTouchLimit()
  elseif 0 == rsp.ret_info.ret_code then
    local chat_session_list_count = rsp.chat_session_list and #rsp.chat_session_list or 0
    Log.DebugFormat("FriendModule:OnZoneChatGetChatListRsp, ret_code=0, req_uin=%s, pack_index=%s, is_end=%s, chat_session_list_count=%s, first_chat_session_uin=%s, bOpenByQuickChat=%s, bOpenInBattle=%s", tostring(rsp.req_uin), tostring(rsp.pack_index), tostring(rsp.is_end), tostring(chat_session_list_count), tostring(rsp.first_chat_session_uin), tostring(bOpenByQuickChat), tostring(self.bOpenInBattle))
    local packIndex = rsp.pack_index or 1
    if 1 == packIndex then
      self.data:ClearChatCache()
    end
    if rsp.chat_session_list then
      self.data:SetChatRoleList(rsp.chat_session_list, rsp.first_chat_session_uin, rsp.first_chat_message_list)
      if rsp.is_end then
        self:DoOpenChatMainPanel(rsp.req_uin, self:OnLoadChatPanelRes(), bOpenByQuickChat, self.bOpenInBattle, self.chatMainPanelDynamicData)
        self.bOpenByQuickChat = nil
        self.bOpenInBattle = nil
        self.chatMainPanelDynamicData = nil
      end
    else
      self:DoOpenChatMainPanel(0, self:OnLoadChatPanelRes(), bOpenByQuickChat, self.bOpenInBattle, self.chatMainPanelDynamicData)
      self.bOpenByQuickChat = nil
      self.bOpenInBattle = nil
      self.chatMainPanelDynamicData = nil
    end
  else
    Log.Error("FriendModule:OnZoneChatGetChatListRsp unexpected ret_code:", rsp.ret_info.ret_code)
  end
end

function FriendModule:OnZoneChatSendChatMessageReq(uin, message)
  local req = _G.ProtoMessage.newZoneChatSendChatMessageReq()
  if uin then
    req.uin = uin
  else
    req.uin = self.data.CurChatUin
  end
  req.chat_message = message
  if req.uin == self.data.MultiPlayerChannelType then
    req.visit_owner_uin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin()
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_SEND_CHAT_MESSAGE_REQ, req, self, self.OnZoneChatSendChatMessageRsp, false, true)
end

function FriendModule:OnZoneChatSendChatMessageRsp(rsp)
  local recode = rsp.ret_info.ret_code
  if 0 == recode then
    self.data:RefreshSessionTimeStamp(rsp.recv_uin, rsp.chat_message.time_stamp)
    self.data:GetSortedChatSessionList(rsp.recv_uin)
    for k, v in ipairs(self.data.ChatSessionList) do
      if v.basic_info.uin == rsp.recv_uin then
        self.data:SetChatMessageList(nil, v, {
          rsp.chat_message
        })
        self.data:SetChatMultiPlayerMessageList(v, {
          rsp.chat_message
        })
        break
      end
    end
    self:DispatchEvent(FriendModuleEvent.OnSendChatMessageSucc, true, rsp.recv_uin, self:IsEmo(rsp.chat_message.chat_message))
    self:ShowBubblePanel(rsp.recv_uin, rsp.chat_message)
    return
  elseif recode == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_BANNED then
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("mute_notice")
    local Uin = rsp.ban_info.uin
    local Text = string.format(GlobalConfig.str, Uin, rsp.ban_info.ban_reason, ban_time)
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  elseif recode == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_MSG_DIRTY then
    if not self:OnCmdAddLocalChatMessage(rsp.recv_uin, rsp.chat_message, FriendEnum.ChatMsgSource.DirtyMsgForSend) then
      local tip = _G.DataConfigManager:GetLocalizationConf("input_sensitive_words_tips").msg
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    end
    self:ShowBubblePanel(rsp.recv_uin, rsp.chat_message)
  elseif recode == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_MSG_INVALID then
    local tip = _G.DataConfigManager:GetLocalizationConf("chat_message_send_empty_tips2").msg
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
  elseif recode == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CREDIT_SCORE_NOT_ENOUGH then
    _G.NRCSDKManager:ShowCreditScoreNotEnoughDialog(NRCSDKManagerEnum.CreditScoreNotEnoughType.Chat)
  elseif recode == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_MSG_NOT_EMOJI then
    local tip = _G.DataConfigManager:GetLocalizationConf("input_sensitive_words_tips").msg
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
  elseif recode == _G.ProtoEnum.MOBA_RET.ChatErr.ERR_CHAT_SEND_MSG_SPAN_TOO_SMALL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_message_send_CD)
  else
    Log.ErrorFormat("FriendModule:OnZoneChatSendChatMessageRsp unexpected error code = %s", tostring(rsp.ret_info.ret_code))
  end
  self:DispatchEvent(FriendModuleEvent.OnSendChatMessageSucc, false)
end

function FriendModule:UpdataChatInfoNotify(notify)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and notify.chat_message.uin == localPlayer:GetLogicId() then
    return
  end
  local chatMessageList = {}
  local uin = notify.chat_session.basic_info.uin
  table.insert(chatMessageList, notify.chat_message)
  local NewSessionInfo = {}
  table.insert(NewSessionInfo, notify.chat_session)
  self.data:SetChatRoleList(NewSessionInfo, uin, nil)
  self.data:GetSortedChatSessionList(uin)
  self.data:SetChatMessageList(nil, notify.chat_session, chatMessageList)
  self.data:SetChatMultiPlayerMessageList(notify.chat_session, chatMessageList)
  self:UpdateBubble(notify)
  self:ShowGiftTips(notify)
  self:DispatchEvent(FriendModuleEvent.OnUpdataChatInfoNotify, notify)
end

function FriendModule:ShowGiftTips(notify)
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if myUin and notify.chat_message.uin == myUin then
    return
  end
  local message = notify.chat_message
  if message and message.chat_msg_type == _G.ProtoEnum.ChatMessageType.CMT_GIVE_GIFT then
    Log.Info("FriendModule:ShowGiftTips", message.uin, message.gift_data.goods_id)
    local tipsData = {}
    tipsData.title = LuaText.get_gift_text02
    tipsData.subtitle = LuaText.get_gift_text03
    tipsData.countdownText = LuaText.get_gift_text01
    local time = _G.DataConfigManager:GetGlobalConfigNumByKey("bp_gift_tips_time", 5)
    tipsData.countdown = time
    tipsData.actionType = "callback"
    tipsData.actionData = {
      params = message.uin,
      callback = function(tipData, uin)
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanel, uin, nil)
      end
    }
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateBPGiftTips(tipsData))
  end
end

function FriendModule:UpdateBubble(notify)
  if notify.chat_message then
    local chatMsgType = notify.chat_message.chat_msg_type
    if chatMsgType == _G.ProtoEnum.ChatMessageType.CMT_GIVE_GIFT then
      Log.DebugFormat("FriendModule:UpdateBubble, chatMsgType = %s, uin = %s", tostring(chatMsgType), tostring(notify.chat_message.uin))
      return
    end
    local session_uin = (notify.chat_message.msg_detail_info or {}).session_uin
    self:ShowBubblePanel(session_uin, notify.chat_message)
  end
end

function FriendModule:GetTextColorByPlayerUin(uin)
  local TextColor = uin == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() and UE4.UNRCStatics.HexToSlateColor("#f7c15c") or UE4.UNRCStatics.HexToSlateColor("#ffffff")
  return TextColor
end

function FriendModule:GetAdaptivePlayerModel(uin)
  if not uin then
    return nil
  end
  local selfInFighting = _G.BattleManager:IsInBattle()
  if selfInFighting then
    if _G.BattleManager.battlePawnManager then
      local battlePlayer = _G.BattleManager.battlePawnManager:GetPlayerByGuid(uin)
      if battlePlayer and battlePlayer.model then
        return battlePlayer.model
      end
      local observationPlayer = _G.BattleManager.battlePawnManager:GetBattlePlayerInspectorByUin(uin)
      if observationPlayer and observationPlayer.model then
        return observationPlayer:GetModel()
      end
    end
  else
    local bigWordPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, uin)
    if bigWordPlayer and bigWordPlayer.viewObj then
      return bigWordPlayer.viewObj
    end
  end
  return nil
end

function FriendModule:ShowBubblePanel(recv_uin, chat_message)
  if recv_uin == _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM then
    local bLogicVisible = false
    local playerUin = chat_message and chat_message.uin
    local model = self:GetAdaptivePlayerModel(playerUin)
    local time_stamp = chat_message and chat_message.time_stamp
    local selfInFighting = _G.BattleManager:IsInBattle()
    if selfInFighting then
      bLogicVisible = model and UE.UObject.IsValid(model) and not model.bHidden
    else
      local bigWordPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerUin)
      bLogicVisible = self:CheckChatVisibleForPlayer(bigWordPlayer)
    end
    if bLogicVisible then
      if self:IsEmo(chat_message.chat_message) then
        local Path = self:OnCmdGetEmoPathByEsc(chat_message.chat_message)
        if Path then
          self.chatBubbleController:AddEmojiBubble(Path, model, time_stamp)
        end
      else
        local Text = self:EscapeString(chat_message.chat_message)
        local msg_detail_info = chat_message and chat_message.msg_detail_info
        local bCypher = msg_detail_info and msg_detail_info.need_cypher
        local is_friend = msg_detail_info and msg_detail_info.is_friend or true
        Text = self:GetFinalBubbleTextByUinAndAreaVisible(playerUin, self.data.CurrentVisibleZoneConfId, Text, is_friend)
        local FontObject = bCypher and _G.NRCBigWorldPreloader:Get("Font_Obj_Rune_Regular") or _G.NRCBigWorldPreloader:Get("Font_Obj_FangZhengLanTing_ZhongChu")
        local TextColor = self:GetTextColorByPlayerUin(playerUin)
        local bClick = not bCypher
        self.chatBubbleController:AddTextBubble(Text, TextColor, FontObject, bClick, model, time_stamp)
      end
    end
  end
end

function FriendModule:OnCmdSetCurChatUin(uin)
  if self:HasPanel("Chat_Main") then
    local chatPanel = self:GetPanel("Chat_Main")
    if chatPanel then
      chatPanel:OnSessionChanged()
    end
  end
  self.data.CurChatUin = uin
end

function FriendModule:OnZoneChatRemoveChatListReq(uin)
  local req = _G.ProtoMessage.newZoneChatRemoveChatListReq()
  req.uin = uin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_REMOVE_CHAT_LIST_REQ, req, self, self.OnZoneChatRemoveChatListRsp, false, true)
end

function FriendModule:OnZoneChatRemoveChatListRsp(rsp)
  self.data:RemoveSessionInfo(rsp.uin)
end

function FriendModule:OnZoneChatGetChatMessageReq(uin, offset, count)
  if uin == self.data.MultiPlayerChannelType then
    Log.DebugFormat("FriendModule:OnZoneChatGetChatMessageReq for multi-player channel, uin=%s, offset=%s, count=%s. Using local cache without server request.", tostring(uin), tostring(offset), tostring(count))
    self:DispatchEvent(FriendModuleEvent.OnGetChatMessageSucc, uin)
    return
  end
  local messageList = self:OnCmdGetChatInfoByUin(uin, false)
  if messageList and #messageList >= offset + count - 1 then
    self:OnCmdRefreshMessageListByUin(uin)
  else
    if self.data.ChatAllMsgFetchedMap[uin] and messageList and #messageList > 0 then
      Log.DebugFormat("FriendModule:OnZoneChatGetChatMessageReq for uin=%s, offset=%s, count=%s. All messages already fetched and local cache exists. Refreshing from local cache without server request.", tostring(uin), tostring(offset), tostring(count))
      self:OnCmdRefreshMessageListByUin(uin)
      return
    end
    local req = _G.ProtoMessage.newZoneChatGetChatMessageReq()
    req.uin = uin
    req.offset = offset
    req.count = count
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHAT_GET_CHAT_MESSAGE_REQ, req, self, self.OnZoneChatGetChatMessageRsp, false, true)
  end
end

function FriendModule:OnZoneChatGetChatMessageRsp(rsp)
  Log.Dump(rsp, 4, "FriendModule:OnZoneChatGetChatMessageRsp")
  local chatMessageList = rsp.chat_message_list
  local uin = rsp.uin
  if 0 == rsp.ret_info.ret_code then
    if rsp.all_msg_fetched then
      Log.DebugFormat("FriendModule:OnZoneChatGetChatMessageRsp, all messages fetched for uin=%s", tostring(uin))
      self.data.ChatAllMsgFetchedMap[uin] = true
    else
      self.data.ChatAllMsgFetchedMap[uin] = false
    end
    if rsp.offset and rsp.offset > 1 then
      for k, v in ipairs(self.data.ChatSessionList) do
        if v.basic_info.uin == uin then
          self.data:SetChatMessageList(nil, v, chatMessageList, rsp.offset)
        end
      end
    else
      self.data:SetChatMessageList(uin, nil, chatMessageList)
    end
    self:OnCmdRefreshMessageListByUin(uin)
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_USE_CLIENT_CACHE then
    self:DispatchEvent(FriendModuleEvent.OnGetChatMessageSucc, uin)
  else
    self:DispatchEvent(FriendModuleEvent.OnGetChatMessageSucc, uin)
  end
end

function FriendModule:OnCmdRefreshMessageListByUin(uin)
  self:DispatchEvent(FriendModuleEvent.OnGetChatMessageSucc, uin)
end

function FriendModule:OnCmdSetChatMessageListByUin(uin)
  if self:HasPanel("Chat_Main") then
    local panel = self:GetPanel("Chat_Main")
    if panel then
      panel:SetChatMessageList(uin)
    end
  end
end

function FriendModule:OnCmdGetEmoPathByEsc(message)
  if string.IsNilOrEmpty(message) then
    return
  end
  local EmojiEscData = self.data.CanSeeEmojiEscToIdMap[message]
  local EmoId = EmojiEscData and EmojiEscData.id
  if not EmoId then
    return nil
  end
  local EmoConf = _G.DataConfigManager:GetChatEmojiConf(EmoId)
  if EmoConf then
    local path = "/Game/NewRoco/Modules/System/Friend/Raw/Expressio/Textures/" .. EmoConf.emoji_use_icon
    return path
  end
  return nil
end

function FriendModule:IsEmo(message)
  local index = string.find(message, "c#%%_")
  if index and 1 == index then
    return true
  end
  return false
end

function FriendModule:EscapeString(original)
  local escaped = original
  escaped = string.gsub(escaped, "\n", "\\n")
  escaped = string.gsub(escaped, "\t", "\\t")
  escaped = string.gsub(escaped, "\r", "\\r")
  escaped = string.gsub(escaped, "\b", "\\b")
  escaped = string.gsub(escaped, "\f", "\\f")
  escaped = string.gsub(escaped, "\"", "\\\"")
  escaped = string.gsub(escaped, "'", "\\'")
  return escaped
end

function FriendModule:OnCmdGetChatInfoByUin(uin, bSession)
  if bSession then
    for k, v in ipairs(self.data.ChatSessionList) do
      if v.basic_info.uin == uin then
        return v
      end
    end
  else
    return self.data.ChatMessageList[uin]
  end
end

function FriendModule:OnCmdAddLocalChatMessage(uin, message, msgSource)
  local localMsg = self.data:AddLocalChatMessage(uin, message, msgSource)
  if localMsg then
    self:DispatchEvent(FriendModuleEvent.OnAddLocalChatMessageSucc, uin, localMsg)
    return true
  end
end

function FriendModule:OnFunctionBanMultiChat(newBanState, functionType)
  if newBanState then
    self:HideOrSHowQuickChatBubble(true)
    self:OnCmdCloseQuickChatBubble()
    local Uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    self:HideOrShowTypingBubbleInfo(true, Uin)
  end
end

function FriendModule:OnCmdOpenQuickChatBubble()
  self.data:SetIsOpenQuickChatBubble(true)
  self:HideOrSHowQuickChatBubble(false)
end

function FriendModule:OnCmdCloseQuickChatBubble()
  self:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.AllFlag, false)
end

function FriendModule:OnCmdGetCurChatUin()
  return self.data:GetCurChatUin()
end

function FriendModule:OnCmdGetSessionInfo(uin)
  return self.data:GetSessionInfo(uin)
end

function FriendModule:RequestShowOrHideTypingBubble(flag, isShow)
  local flagChanged = self.data:SetTypingFlag(flag, isShow)
  if flagChanged then
    local shouldShow = self.data:ShouldShowTyping()
    self:ZoneChatInputMsgStatusReq(not shouldShow)
  end
end

function FriendModule:ZoneChatInputMsgStatusReq(is_over)
  Log.DebugFormat("FriendModule:ZoneChatInputMsgStatusReq %s", tostring(is_over and "true" or "false"))
  self:HideOrShowTypingBubbleInfo(is_over, _G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  local req = _G.ProtoMessage.newZoneSceneClientEventReq()
  req.client_event = {
    {
      event = Enum.ClientEvent.CE_MSG_INPUT,
      is_start = not is_over
    }
  }
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_EVENT_REQ, req, self, self.OnZoneSceneClientEventRsp, false, true)
end

function FriendModule:OnZoneSceneClientEventRsp(Rsp)
end

function FriendModule:OnZoneChatInputMsgStatusRsp(Rsp)
  Log.Debug(Rsp.is_over, Rsp.ret_info.ret_code, "FriendModule:OnZoneChatInputMsgStatusRsp")
end

function FriendModule:OnChatInputMsgStatusNotify(notify)
  self:HideOrShowTypingBubbleInfo(notify.is_over, notify.uin)
end

function FriendModule:HideOrShowTypingBubbleInfo(IsHide, Uin)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin)
  if player and player.viewObj and UE.UObject.IsValid(player.viewObj) then
    local bLogicVisible = self:CheckChatVisibleForPlayer(player)
    if IsHide or not bLogicVisible then
      self.chatBubbleController:HideTypingBubble(player.viewObj)
    else
      local TextColor = self:GetTextColorByPlayerUin(Uin)
      self.chatBubbleController:ShowTypingBubble(player.viewObj, TextColor)
    end
  end
end

function FriendModule:CheckChatVisibleForPlayer(player)
  local bLogicVisible = true
  if not player.viewObj.bHidden then
  else
    local bInBlindBox = player:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_PLAYER_IN_BLINDBOX)
    bLogicVisible = bInBlindBox
  end
  return bLogicVisible
end

function FriendModule:HideOrSHowQuickChatBubble(IsHide)
  if IsHide then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CloseQuickChat)
    if self:HasPanel("QuickChatBubble") then
      local Panel = self:GetPanel("QuickChatBubble")
      Panel:ClosePanel()
    end
  elseif self.data:GetIsOpenQuickChatBubble() then
    self:OpenPanel("QuickChatBubble")
  end
end

function FriendModule:RemoveActorMessages(Uin, IsRemove)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin)
  if player and self:ShouldShowBubble(player) then
    if IsRemove then
      self.chatBubbleController:RemoveActorMessages(player.viewObj)
    else
      local TextColor = self:GetTextColorByPlayerUin(Uin)
      self.chatBubbleController:ShowTypingBubble(player.viewObj, TextColor)
    end
  end
end

function FriendModule:ShouldShowBubble(player)
  if not player:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_MSG_INPUT) then
    return false
  end
  return true
end

function FriendModule:HideOrQuickChatBubble(IsHide)
  if IsHide then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CloseQuickChat)
    if self:HasPanel("QuickChatBubble") then
      local Panel = self:GetPanel("QuickChatBubble")
      Panel:ClosePanel()
    end
  elseif self.data:GetIsOpenQuickChatBubble() then
    self:OpenPanel("QuickChatBubble")
  end
end

function FriendModule:InitializeCardInfo()
  local req = _G.ProtoMessage.newZoneGetPlayerCardInfoReq()
  self.bHadReqInitializeCardInfo = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_INFO_REQ, req, self, self.OnInitializeCardInfo, false, true)
end

function FriendModule:OnInitializeCardInfo(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:InitMyCardData(_rsp.player_card_info, _rsp.player_card_brief_info)
  end
end

function FriendModule:OnCmdUpdateCardInfo(_rsp)
  self:OnInitializeCardInfo(_rsp)
end

function FriendModule:OnOpenStudentCardPanel(FriendInfo, AdminFriendType, Source, SELECT_TAB, IsPhotograph, bToggleToPhotoCropping, studentCardForbidAddFriend, Action, forbidEdit)
  self:ChitchatOpenCardPanel()
  local FriendType = AdminFriendType
  local SourceType = Source
  local SelectTab = SELECT_TAB
  SelectTab = SelectTab or FriendEnum.SELECT_TAB.None
  self.IsPhotograph = IsPhotograph
  if not AdminFriendType then
    FriendType = FriendEnum.AdminFriendType.Own
  end
  if not Source then
    SourceType = FriendEnum.Source.Friend
  end
  if nil == studentCardForbidAddFriend then
    studentCardForbidAddFriend = false
  end
  if nil == forbidEdit then
    forbidEdit = false
  end
  self.data:SetModifyCardInfo(FriendInfo, FriendType, SourceType, SELECT_TAB, bToggleToPhotoCropping, studentCardForbidAddFriend, forbidEdit)
  if FriendType == FriendEnum.AdminFriendType.Own then
    local PlayerCardInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerCardInfo()
    local PlayerCardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
    if PlayerCardInfo and PlayerCardBriefInfo then
      self:RealOpenStudentCardPanel()
      Log.Debug("FriendModule:OnOpenStudentCardPanel", "PlayerCardInfo and PlayerCardBriefInfo already exist, directly open StudentCard panel, and request latest data")
      local req = _G.ProtoMessage.newZoneGetPlayerCardInfoReq()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_INFO_REQ, req, self, self.OnInitializeCardInfo, false, true)
    else
      Log.Debug("FriendModule:OnOpenStudentCardPanel", "PlayerCardInfo or PlayerCardBriefInfo not exist, request data first")
      local req = _G.ProtoMessage.newZoneGetPlayerCardInfoReq()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_INFO_REQ, req, self, self.OnWaitingMyPlayerCardInfoToOpenCard, false, true)
    end
  else
    local req = _G.ProtoMessage.newZoneGetPlayerCardBriefInfoReq()
    local CardSelectTab = self.data:GetCardSelectTab()
    local uin
    req.source = self.data:GetCardSource()
    if CardSelectTab == FriendEnum.SELECT_TAB.FaceToFaceInteraction then
      uin = self.data:GetCardFriendInfo().base.logic_id
      if _G.DataModelMgr.PlayerDataModel:CheckHasBlackByPlayerUin(uin) then
        local Text = _G.DataConfigManager:GetLocalizationConf("open_relation_player_on_the_balcklist").msg
        if Text then
          _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
        end
        if Action then
          Action:Finish()
        end
        return
      end
      _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.OpenRelationCover, uin, Action)
      return
    else
      if not FriendInfo or not FriendInfo.uin then
        if Action then
          Action:Finish()
        end
        Log.Error("FriendModule:OnOpenStudentCardPanel", "FriendInfo or FriendInfo.uin is nil")
        return
      end
      uin = FriendInfo.uin
    end
    req.uin = uin
    Log.Debug("FriendModule:OnOpenStudentCardPanel", "uin = " .. uin .. ", SourceType = " .. req.source .. ", FriendType = " .. FriendType .. ", SELECT_TAB = " .. SelectTab)
    self.data:SetPlayerCardBriefInfoUin(uin)
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_BRIEF_INFO_REQ, req, self, self.OnWaitingOtherPlayerCardInfoRspToOpenCard, false, true)
  end
  Log.Debug(FriendType, SourceType, SelectTab, "FriendModule:OnOpenStudentCardPanel")
end

function FriendModule:OnWaitingMyPlayerCardInfoToOpenCard(rsp)
  if 0 == rsp.ret_info.ret_code then
    Log.Debug("FriendModule:OnWaitingMyPlayerCardInfoToOpenCard", "player card info received, initializing my card data")
    self:InitMyCardData(rsp.player_card_info, rsp.player_card_brief_info)
    self:RealOpenStudentCardPanel()
  else
    Log.Error("FriendModule:OnWaitingPlayerCardInfoToOpenCard error code = " .. rsp.ret_info.ret_code)
  end
end

function FriendModule:GetPlayerCardInfoReq()
  local req = _G.ProtoMessage.newZoneGetPlayerCardInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_INFO_REQ, req, self, self.OnZoneGetPlayerCardInfoRsp, false, true)
end

function FriendModule:InitMyCardData(player_card_info, player_card_brief_info)
  _G.DataModelMgr.PlayerDataModel:SetCardBriefInfo(player_card_brief_info)
  _G.DataModelMgr.PlayerDataModel:SetPlayerCardInfo(player_card_info)
  self.data:AddIconList(player_card_info.icon_owned)
  self.data:AddSkinList(player_card_info.skin_owned)
  self.data:AddLabelList(player_card_info.label_owned)
  self.data:AddSuitList()
  self.data:AddPoseList()
end

function FriendModule:OnZoneGetPlayerCardInfoRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data:AddIconList(_rsp.player_card_info.icon_owned)
    self.data:AddSkinList(_rsp.player_card_info.skin_owned)
    self.data:AddLabelList(_rsp.player_card_info.label_owned)
    self.data:AddSuitList()
    self.data:AddPoseList()
    _G.DataModelMgr.PlayerDataModel:SetCardBriefInfo(_rsp.player_card_brief_info)
  end
  local CardAdminFriendType = self.data:GetCardAdminFriendType()
  if CardAdminFriendType == FriendEnum.AdminFriendType.Others then
    local req = _G.ProtoMessage.newZoneGetPlayerCardBriefInfoReq()
    local CardSelectTab = self.data:GetCardSelectTab()
    local uin
    req.source = self.data:GetCardSource()
    if CardSelectTab == FriendEnum.SELECT_TAB.FaceToFaceInteraction then
      uin = self.data:GetCardFriendInfo().base.logic_id
    else
      uin = self.data:GetCardFriendInfo().uin
    end
    req.uin = uin
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_BRIEF_INFO_REQ, req, self, self.OnWaitingOtherPlayerCardInfoRspToOpenCard, false, true)
  else
    self:RealOpenStudentCardPanel()
  end
end

function FriendModule:EnableStudentCardPanel()
  local Panel = self:GetPanel("StudentCard")
  if Panel then
    Panel:EnableAndShouldBanWorldRendering()
    Panel:IsLoadSucceed()
  end
end

function FriendModule:PreLoadStudentCardPanel()
  self:PreLoadPanel("StudentCard", 10)
end

function FriendModule:OnWaitingOtherPlayerCardInfoRspToOpenCard(_rsp)
  Log.Dump(_rsp, 3, "FriendModule:OnWaitingOtherPlayerCardInfoRspToOpenCard")
  if 0 == _rsp.ret_info.ret_code then
    local CardSource = self.data:GetCardSource()
    local AdminFriendType = self.data:GetCardAdminFriendType()
    if CardSource == FriendEnum.Source.Friend and AdminFriendType == FriendEnum.AdminFriendType.Others then
      _rsp.is_friend = true
    end
    self.data:SetPlayerCardBriefInfo(_rsp)
    self:RealOpenStudentCardPanel()
  else
    Log.Error("FriendModule:OnWaitingOtherPlayerCardInfoRspToOpenCard error code = " .. _rsp.ret_info.ret_code)
  end
end

function FriendModule:RealOpenStudentCardPanel()
  self:OpenPanel("StudentCard", self:GetPanelAdaptationLayer())
end

function FriendModule:GetPanelAdaptationLayer()
  local panelDynamicData
  if _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.CheckInFightingOrObserver) then
    panelDynamicData = NRCPanelDynamicData()
    panelDynamicData:SetModifiedPanelLayerType(Enum.UILayerType.UI_LAYER_TOP)
  end
  return panelDynamicData
end

function FriendModule:AdvanceCapture()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local cameraManager = player:GetUEController().playerCameraManager
  local uiCamera = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.GetUICamera)
  self.RT_capture = nil
  UE4Helper.SetEnableWorldRendering(true, false, "Friend_AdvanceCapture")
  if not uiCamera then
    cameraManager:StartCaptureBlurScene2D(4, 4)
    self.RT_capture = cameraManager:GetTextureTarget2D()
  else
    cameraManager:StartCaptureBlurScene2D(0, 0)
    self.RT_capture = cameraManager:GetTextureTarget2D()
  end
  UE4Helper.SetEnableWorldRendering(nil, true, "Friend_AdvanceCapture")
end

function FriendModule:CloseStudentCard()
  if self:HasPanel("StudentCard") then
    local Panel = self:GetPanel("StudentCard")
    if Panel then
      Panel:CloseStudentCardPanel()
    end
  end
end

function FriendModule:OnCmdCloseStudentCardPanel()
  self:CloseStudentCard()
end

function FriendModule:OnOpenChangeAvatarPanel()
  self.data:OpenAvatar()
  self:OpenPanel("ChangeAvatar")
end

function FriendModule:OnSetSelectedAvatarItem(CardIconConf)
  self:DispatchEvent(FriendModuleEvent.SetChooseItemInfo, CardIconConf)
end

function FriendModule:OnSetStudentCardAvatarPath(AvatarPath, AvatarIconId)
  self.ModifyAvatarPath = AvatarPath
  self.ModifyAvatarIconId = AvatarIconId
  local PlayerIconReq = _G.ProtoMessage:newZoneSetPlayerCardIconReq()
  PlayerIconReq.icon_id = AvatarIconId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_ICON_REQ, PlayerIconReq, self, self.OnModifyPlayerIconRsp, false, true)
end

function FriendModule:OnModifyPlayerIconRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:UpdatePlayerIAvatarData(_rsp.card_brief_info)
    self:DispatchEvent(FriendModuleEvent.SetChooseAvatar, _rsp.card_brief_info)
    _G.NRCModeManager:DoCmd(LevelUpUIModuleCmd.ChangeLevelPlayerHead)
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_icon_modify_tips)
  end
end

function FriendModule:OnCloseChangeAvatarPanel()
  if self:HasPanel("ChangeAvatar") then
    self:ClosePanel("ChangeAvatar")
  end
end

function FriendModule:OnOpenChangeCardBG(SkinId)
  self.data:OpenCardBG()
  local ResListData = self:OnLoadPanelRes()
  self:OpenPanel("ChangeCardBG", ResListData)
end

function FriendModule:OnSetSelectedCardBG(itemData)
  self:DispatchEvent(FriendModuleEvent.SelectCardSkinInfo, itemData)
end

function FriendModule:OnSetStudentCardBGPath(SkinId)
  Log.Debug("FriendModule:OnSetStudentCardBGPath", SkinId)
  local PlayerSkinReq = _G.ProtoMessage:newZoneSetPlayerCardSkinReq()
  PlayerSkinReq.skin_id = SkinId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_SKIN_REQ, PlayerSkinReq, self, self.OnModifySkinRsp, false, true)
end

function FriendModule:OnModifySkinRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:UpdatePlayerSkinData(_rsp.card_brief_info)
    self:DispatchEvent(FriendModuleEvent.SetChooseCardBGPath, _rsp.card_brief_info)
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.rolecard_skin_edit_succeed)
  end
end

function FriendModule:OnCmdSelectInformationEditorIndex(Type)
  self.data:SetSelectImageEditorIndex(Type)
  self:DispatchEvent(FriendModuleEvent.SelectInformationEditorIndex, Type)
  self.data:SetOldSelectTab(Type)
end

function FriendModule:OnCmdGetImageEditorIndex()
  return self.data:GetSelectImageEditorIndex()
end

function FriendModule:OmCmdGetOldSelectTab()
  return self.data:GetOldSelectTab()
end

function FriendModule:OnCloseChangeCardBG()
  if self:HasPanel("ChangeCardBG") then
    self:ClosePanel("ChangeCardBG")
  end
end

function FriendModule:OnOpenChangeCardLabel(_FirstId, _LastId, IniSeletItemIndex)
  self.data:OpenLabel()
  local ResListData = self:OnLoadPanelRes()
  self:OpenPanel("ChangeCardLabel", ResListData, IniSeletItemIndex)
end

function FriendModule:OnSetSelectedLabel(index)
  if self:HasPanel("ChangeCardLabel") then
    local panel = self:GetPanel("ChangeCardLabel")
    if panel then
      panel:ChangeFirstSelected(index)
    end
  end
end

function FriendModule:OnSetLastSelectedLabel(index)
  self.LastId = index
  if self:HasPanel("ChangeCardLabel") then
    local panel = self:GetPanel("ChangeCardLabel")
    if panel then
      panel:ChangeLastSelected(index)
    end
  end
end

function FriendModule:OnSetLabelId(_FirstIndex, _LastIndex)
  self.FirstId = _FirstIndex
  self.LastId = _LastIndex
  local PlayerFirstIdReq = _G.ProtoMessage:newZoneSetPlayerCardLabelReq()
  PlayerFirstIdReq.label_first_id = self.FirstId
  PlayerFirstIdReq.label_last_id = self.LastId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_LABEL_REQ, PlayerFirstIdReq, self, self.OnModifyPlayerLabelRsp, false, true)
end

function FriendModule:OnModifyPlayerLabelRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local Data = {}
    Data = _G.DataModelMgr.PlayerDataModel:UpdatePlayerLabelData(_rsp.card_brief_info)
    self:DispatchEvent(FriendModuleEvent.SetLabelText, self.FirstId, self.LastId, Data)
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_title_modify_tips)
    local req = _G.ProtoMessage.newZoneGetPlayerCardInfoReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_CARD_INFO_REQ, req, self, self.UpdateLabelInfo, false, true)
  end
end

function FriendModule:UpdateLabelInfo(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data:AddLabelList(_rsp.player_card_info.label_owned)
  end
end

function FriendModule:OnCloseChangeCardLabel()
  if self:HasPanel("ChangeCardLabel") then
    self:ClosePanel("ChangeCardLabel")
  end
end

function FriendModule:OnOpenChangeSign(_data)
  self:OpenPanel("ChangeSign")
end

function FriendModule:OnCmdOpenCardComponentSelectList()
  self:OpenPanel("CardComponentSelectList")
end

function FriendModule:OpenCardChangeBackground()
  self:OpenPanel("CardChangeBackground")
end

function FriendModule:OpenCardEditingComponent(arg)
  self:OpenPanel("CardEditingComponent", arg)
end

function FriendModule:OpenPetCardTypeSelect()
  self:OpenPanel("PetCardTypeSelect")
end

function FriendModule:OnModifyPlayerSignature(OldNote, NewNote)
  self.ModifyRemarkOldNote = OldNote
  self.ModifyRemarkNewNote = NewNote
  local req = _G.ProtoMessage:newZoneSetPlayerCardSignatureReq()
  req.signature = NewNote
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_SIGNATURE_REQ, req, self, self.OnModifySignatureRsp, false, true)
end

function FriendModule:OnModifySignatureRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local Data = {}
    Data = _G.DataModelMgr.PlayerDataModel:UpdatePlayerSignatureData(_rsp.card_brief_info)
    self:DispatchEvent(FriendModuleEvent.ModifyPlayerSignatureUpdate, self.ModifyRemarkOldNote, self.ModifyRemarkNewNote, Data)
    self:ClosePanelByName("ChangeSign")
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_signature_modify_tips)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.input_sensitive_words_tips)
  elseif _rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and _rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = _rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", _rsp.ban_info.ban_time)
    local reasonStr = _rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function FriendModule:OnCmdOpenReplaceElf(_data)
  if self.data:GetCardAdminFriendType() == FriendEnum.AdminFriendType.Own then
    self.data:SetFavoritePet(nil)
    self:OpenPanel("ReplaceElf", _data)
  end
end

function FriendModule:OnCmdSelectFavoritePet(PetData)
  self.data:SetFavoritePet(PetData)
  self:DispatchEvent(FriendModuleEvent.SelectFavoritePet, PetData)
end

function FriendModule:OnCmdSetFavoritePet(_IsSetFavoritePet)
  local FavoritePet = self.data:GetFavoritePet()
  local CardFavoritePet = self.data:GetCardFavoriteData()
  local req = _G.ProtoMessage:newZoneSetPlayerCardFavoritePetInfoReq()
  req.pet_base_id = _IsSetFavoritePet and FavoritePet.base_conf_id or 0
  req.skill_dam_type = CardFavoritePet.SystemType.id
  if PetMutationUtils.GetMutationValue(FavoritePet.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsCHAOS(FavoritePet.mutation_type) then
    req.mutation_diff_type = _G.Enum.MutationDiffType.MDT_SHINING
  else
    req.mutation_diff_type = _G.Enum.MutationDiffType.MDT_NONE
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_FAVORITE_PET_INFO_REQ, req, self, self.OnSetFavoritePetRsp, false, true)
end

function FriendModule:OnSetFavoritePetRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:SetPlayerCardFavoritePetInfo(_rsp)
  end
end

function FriendModule:SetPlayerCardFavoritePetInfo(_rsp)
  local card_favorite_pet_info = {}
  for i, _ in ipairs(_rsp.card_brief_info.card_favorite_pet_info) do
    if 0 ~= _.pet_base_id then
      table.insert(card_favorite_pet_info, _)
    end
  end
  _rsp.card_brief_info.card_favorite_pet_info = card_favorite_pet_info
  self:DispatchEvent(FriendModuleEvent.SetFavoritePetEvent, _rsp.card_brief_info)
  _G.DataModelMgr.PlayerDataModel:SetPlayerCardFavoritePetInfo(card_favorite_pet_info)
end

function FriendModule:OnCmdOnClickPhoto()
  local ResListData = self:OnLoadPanelRes()
  self:OpenPanel("Photograph", ResListData)
end

function FriendModule:OnCmdPhotoGraphSave()
  local AppearanceInfo = self.data:GetPlayerCardAppearanceInfo()
  local req = _G.ProtoMessage:newZoneSetPlayerCardAppearanceInfoReq()
  req.appearance_info.card_skin_selected = AppearanceInfo.card_skin_selected
  req.appearance_info.fashion_wear_id = AppearanceInfo.fashion_wear_id
  req.appearance_info.pose_selected = AppearanceInfo.pose_selected
  req.appearance_info.pose_frame_id = AppearanceInfo.pose_frame_id
  req.appearance_info.salon_item_data = AppearanceInfo.salon_item_data
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_CARD_APPEARANCE_INFO_REQ, req, self, self.SetPlayerCardAppearanceInfoRsp, false, true)
  self:ClosePanel("ChangeCardBG")
end

function FriendModule:SetPlayerCardAppearanceInfoRsp(_Rsp)
  if 0 == _Rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:SetCardAppearanceInfo(self.data:GetPlayerCardAppearanceInfo())
  else
    Log.Error("\230\139\141\231\133\167\229\164\177\232\180\165")
  end
  self:OnOpenStudentCardPanel(self.data:GetCardFriendInfo(), self.data:GetCardAdminFriendType(), self.data:GetCardSource(), self.data:GetCardSelectTab(), true)
end

function FriendModule:OnCmdAgainPhotograph()
  local HasPanel = self:HasPanel("ChangeCardBG")
  if HasPanel then
    local Panel = self:GetPanel("ChangeCardBG")
    Panel:AgainPhotograph()
  end
end

function FriendModule:OnCmdGetPhotographAppearanceInfo()
  return self.data:GetPlayerCardAppearanceInfo()
end

function FriendModule:OnCmdGetCurrentUsePlayerHead()
  return self.data:GetCurrentUseHeadIcon()
end

function FriendModule:OnCmdGetCardHeadIconByHeadId(HeadId)
  return self.data:GetHeadIconByHeadId(HeadId)
end

function FriendModule:OnCmdGetDefaultSkinId()
  return self.data:GetDefaultSkinId()
end

function FriendModule:OnCmdGetDefaultPoseId()
  return self.data:GetDefaultPoseId()
end

function FriendModule:OnCmdGetSkinByCardItemId(card_item_id)
  return self.data:GetSkinByCardItemId(card_item_id)
end

function FriendModule:RegStudentPanel(name, path, layer, bCustomDisableRendering, openAnimName, closeAnimName, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Friend/Res/BusinessCard/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = bCustomDisableRendering or false
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function FriendModule:SetLegendaryMatchTime(time)
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    if panel then
      panel:SetLegendaryMatchTime(time)
    end
  end
end

function FriendModule:OnMatchStateChanged(state)
  if self:HasPanel("Plane_Team") then
    local panel = self:GetPanel("Plane_Team")
    if panel then
      panel:SetMatchInfo()
    end
  end
end

function FriendModule:OnLoadPanelRes()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC1.BP_DefaultSuit_PC1_C'"
  local path1 = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC2.BP_DefaultSuit_PC2_C'"
  local path2 = "Blueprint'/Game/NewRoco/Modules/System/Friend/Raw/Player/BP_CardLocalPlayer.BP_CardLocalPlayer_C'"
  table.insert(ResListData.PreLoadResList, path)
  table.insert(ResListData.PreLoadResList, path1)
  table.insert(ResListData.PreLoadResList, path2)
  table.insert(ResListData.PreLoadResList, UEPath.ABP_CARD_PLAYER_MALE)
  table.insert(ResListData.PreLoadResList, UEPath.ANIM_CONFIG_MALE)
  table.insert(ResListData.PreLoadResList, UEPath.ABP_CARD_PLAYER_FEMALE)
  table.insert(ResListData.PreLoadResList, UEPath.ANIM_CONFIG_FEMALE)
  return ResListData
end

function FriendModule:OnLoadChatPanelRes()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  table.insert(ResListData.PreLoadResList, UEPath.Font)
  table.insert(ResListData.PreLoadResList, UEPath.Font_1)
  return ResListData
end

function FriendModule:OnCmdGetChatPanelAsset(path, name)
  return self:GetRes(path, name)
end

function FriendModule:OnOpenApplyVisitListInfo(Info, Type)
  if self:HasPanel("Plane_ExchangeVisits") then
    self:ClosePanel("Plane_ExchangeVisits")
  end
  self:OpenPanel("Plane_ExchangeVisits", Info, Type)
end

function FriendModule:OnCmdSetDefaultSuit(PlayerActor, gender, fashionIds, salonIds, CardEntrance, PanelName)
  local defaultSuitClass
  if 2 == gender then
    defaultSuitClass = self:GetRes("Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC2.BP_DefaultSuit_PC2_C'", PanelName)
    if not defaultSuitClass then
      defaultSuitClass = UE4.UClass.Load("Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC2.BP_DefaultSuit_PC2_C'")
    end
  else
    defaultSuitClass = self:GetRes("Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC1.BP_DefaultSuit_PC1_C'", PanelName)
    defaultSuitClass = defaultSuitClass or UE4.UClass.Load("Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC1.BP_DefaultSuit_PC1_C'")
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  if salonIds and #salonIds > 0 then
    local salonWearIds = {}
    for k, v in ipairs(salonIds) do
      if v.item_wear_id and 0 ~= v.item_wear_id then
        local SalonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
        if SalonItemConf then
          local avatarId = SalonItemConf.avatar_id
          local colorId = SalonItemConf.texture_id
          local fullSalonId = self:GetFullSalonId(avatarId, colorId)
          table.insert(salonWearIds, fullSalonId)
        end
      end
    end
    defaultSuitObj:SetSalons(salonWearIds)
  end
  if fashionIds and #fashionIds > 0 then
    for k, v in ipairs(fashionIds) do
      if 0 ~= v then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
        if fashionItemConf then
          local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(fashionItemConf.type)
          if bBodyType then
            defaultSuitObj:SetBody(v, 0)
          else
            defaultSuitObj:SetBody(v, 0)
          end
        else
          Log.Error("fashion\228\184\141\229\173\152\229\156\168")
        end
      end
    end
  end
  local CardPlayer = PlayerActor
  if CardPlayer then
    self.CardEntrance = CardEntrance
    local mesh = CardPlayer:GetComponentByClass(UE4.USkeletalMeshComponent)
    self.avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    if self.avatarSystem.OnSwitchAvatarSuitComplete then
      self.avatarSystem.OnSwitchAvatarSuitComplete:Add(self.avatarSystem, self.RecoverAllStatus)
    end
    self.ID = self.avatarSystem:StartSwitchAvatarSuit(mesh, defaultSuitObj)
  else
    Log.Error("\229\144\141\231\137\135\228\186\186\231\137\169\231\148\159\230\136\144\229\164\177\232\180\165")
  end
end

function FriendModule:RecoverAllStatus(ID, CardEntrance)
  local friendModule = NRCModuleManager:GetModule("FriendModule")
  if friendModule and ID == friendModule.ID then
    friendModule:DispatchEvent(FriendModuleEvent.SwitchAvatarSuitComplete, friendModule.CardEntrance)
    friendModule.ID = nil
    friendModule.CardEntrance = nil
    friendModule.avatarSystem.OnSwitchAvatarSuitComplete:Remove(friendModule.avatarSystem, friendModule.RecoverAllStatus)
    friendModule.avatarSystem = nil
    _G.NRCModeManager:DoCmd(_G.AppearanceModuleCmd.OnNameCardPopupAvatarSuitComplete)
  end
end

function FriendModule.RecoverAllStatusStatic()
  local friendModule = NRCModuleManager:GetModule("FriendModule")
  friendModule:DispatchEvent(FriendModuleEvent.SwitchAvatarSuitComplete, friendModule.CardEntrance)
end

function FriendModule:GetFullSalonId(configId, colorIndex)
  if colorIndex > 0 then
    colorIndex = colorIndex - 1
  end
  local fullSalonId = configId * 100 + colorIndex
  return fullSalonId
end

function FriendModule:OnCmdSelectImageEditorTypeItem(ItemData, Index)
  self.data:SetSelectItem(Index)
  self:DispatchEvent(FriendModuleEvent.UpdateInformationEditorPanel, ItemData, Index)
end

function FriendModule:OnCmdGetImageEditorTypeItem()
  return self.data:GetSelectItem()
end

function FriendModule:UpdateInteractionOptionsInfo(ActorID, Skin, LabelFirst, LabelLast)
  if not ActorID then
    return
  end
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, ActorID)
  if not Player.viewObj then
    return
  end
  if Skin then
    Player.serverData.card_info.card_skin_selected = Skin
  end
  if LabelFirst then
    Player.serverData.card_info.card_label_first_selected = LabelFirst
  end
  if LabelLast then
    Player.serverData.card_info.card_label_last_selected = LabelLast
  end
  local HeadWidget = Player.viewObj.HeadWidget
  if HeadWidget then
    local HeadHud = HeadWidget:GetUserWidgetObject()
    if HeadHud and HeadHud:GetInteractionOptionsVisible() then
      HeadHud:SetInteractionOptionsInfo(Skin, LabelFirst, LabelLast)
    end
  end
end

function FriendModule:OnCmdChangeCardLabel(Action)
  self:UpdateInteractionOptionsInfo(Action.actor_id, nil, Action.card_label_first_selected, Action.card_label_last_selected)
end

function FriendModule:OnCmdChangeCardSkin(Action)
  self:UpdateInteractionOptionsInfo(Action.actor_id, Action.card_skin_selected)
end

function FriendModule:OnCmdChangeCardIcon(Action)
  if not Action.actor_id then
    return
  end
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Action.actor_id)
  if not Player.viewObj then
    return
  end
  if Action.card_icon_selected then
    Player.serverData.card_info.card_icon_selected = Action.card_icon_selected
  end
end

function FriendModule:OnCmdChangeCardMusic(Action)
  local CardSelectTab = self.data:GetCardSelectTab()
  if CardSelectTab == FriendEnum.SELECT_TAB.FaceToFaceInteraction then
    local actor_id = self.data:GetCardFriendInfo().base.actor_id
    if actor_id == Action.actor_id then
      local CardInfo = self.data:GetPlayerCardBriefInfo() and self.data:GetPlayerCardBriefInfo().player_card_brief_info
      CardInfo.card_music_id = Action.card_music_id
      self.data:SetPlayerCardBriefInfo(CardInfo)
    end
  end
end

function FriendModule:RegPanel(name, path, layer, openAnimName, closeAnimName, bCustomDisableRendering, enablePcEsc, disableLoadBlock, autoSetDesiredCursor)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Friend/Res/%s", path)
  registerData.panelLayer = layer
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  registerData.enablePcEsc = enablePcEsc
  registerData.disableLoadBlock = disableLoadBlock
  registerData.customDisableRendering = bCustomDisableRendering or false
  registerData.autoSetDesiredCursor = autoSetDesiredCursor
  self:RegisterPanel(registerData)
end

function FriendModule:OnVisitPlayerInfoSyncNotify(oldOwner, newOwner, bFirstEnter)
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if nil ~= newOwner and newOwner ~= oldOwner and nil ~= playerUin then
    if 0 == newOwner then
      if nil ~= oldOwner then
        if oldOwner ~= playerUin then
          _G.NRCModuleManager:DoCmd(BigMapModuleCmd.TraceNpcByID, -1)
          _G.NRCModuleManager:DoCmd(BigMapModuleCmd.ClearTraceInfoByType, BigMapModuleEnum.TraceType.ForceTrace)
        end
        self:OnLeaveOnlineVisit()
        _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnLeaveVisit)
      end
    elseif bFirstEnter then
      if not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.TraceNpcByID, -1)
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.ClearTraceInfoByType, BigMapModuleEnum.TraceType.ForceTrace)
      end
      self:OnEnterOnlineVisit()
      _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnEnterVisit, bFirstEnter)
    end
  end
  if not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    local list = {}
    self.data:SetOnlineVisitorList(list)
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SetVisitListInfo, list)
    NRCEventCenter:DispatchEvent(FriendModuleEvent.OnVisitorChanged, {
      visitors = {}
    })
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateVisitListInfo)
    self.data:RemoveSessionInfo(self.data.MultiPlayerChannelType)
    self:OnCmdCloseChatMainPanel()
  end
end

function FriendModule:OnEnterOnlineVisit()
  Log.Debug("FriendModule:OnEnterOnlineVisit")
  self:OnOwnerEnterMapByVisit()
end

function FriendModule:OnLeaveOnlineVisit()
  Log.Debug("FriendModule:OnLeaveOnlineVisit")
  self:OnOwnerEnterMapByVisit()
end

function FriendModule:OnCmdSetSelectFriendIndex(index)
  self.data:SetSelectFriendIndex(index)
end

function FriendModule:OnCmdGetVisitListChangeInfo()
  return self.data:GetVisitListChangeInfo()
end

function FriendModule:OnCmdWatchFriendBattle(battlerUin)
  if _G.BattleManager.isInBattle then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").WATCH
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
    return
  end
  local a = require("Common.Coroutine.async")
  local au = require("Common.Coroutine.async_util")
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer:IsInTogetherMove() and localPlayer.viewObj then
    local rideComp = localPlayer.viewObj.BP_RideComponent
    if rideComp and rideComp:TryChangeToLink() then
      localPlayer:StopRide(true, nil)
    end
  end
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ReqJoinObservingBattle, battlerUin)
end

function FriendModule:OnZoneBattleWatchRsp()
  Log.Debug("FriendModule:OnZoneBattleWatchRsp \229\143\145\232\181\183\232\167\130\230\136\152\232\175\183\230\177\130\229\155\158\229\140\133...")
end

function FriendModule:OnCmdOpenPlaneTeam()
  self:OpenPanel("Plane_Team")
end

function FriendModule:OnCmdOpenFriendWorld(...)
  self:OpenPanel("Friend_Wold", self:GetPanelAdaptationLayer(), ...)
end

function FriendModule:OnCmdCloseFriendWold()
  self:ClosePanel("Friend_Wold")
end

function FriendModule:OnOpenFriendRecommendFilter()
  self:OpenPanel("FriendRecommendFilter")
end

function FriendModule:OnCloseFriendRecommendFilter()
  self:ClosePanel("FriendRecommendFilter")
end

function FriendModule:OnCmdHasCardIcon(cardIconId)
  local cardIconList = self.data:GetIconList()
  for idx, skin in ipairs(cardIconList) do
    if skin.card_item_id == cardIconId and 0 ~= skin.card_item_get_timestamp then
      return true
    end
  end
  return false
end

function FriendModule:OnCmdHasCardSkin(cardSkinItemId)
  local cardSkinList = self.data:GetSkinList()
  for idx, skin in ipairs(cardSkinList) do
    if skin.card_item_id == cardSkinItemId and 0 ~= skin.card_item_get_timestamp then
      return true
    end
  end
  return false
end

function FriendModule:OnCmdRequestUpgradeCardSkin(cardSkinId)
  local req = _G.ProtoMessage:newZoneUpgradePlayerCardSkinReq()
  req.skin_id = cardSkinId
  Log.DebugFormat("FriendModule:OnCmdRequestUpgradeCardSkin \232\175\183\230\177\130\229\141\135\231\186\167\229\144\141\231\137\135\231\154\174\232\130\164\239\188\140\231\154\174\232\130\164ID=%s", tostring(cardSkinId))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UPGRADE_PLAYER_CARD_SKIN_REQ, req, self, self.OnUpgradeCardSkinRsp, false, true)
end

function FriendModule:OnUpgradeCardSkinRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.ErrorFormat("FriendModule:OnUpgradeCardSkinRsp \229\141\135\231\186\167\229\144\141\231\137\135\231\154\174\232\130\164\229\164\177\232\180\165\239\188\140\233\148\153\232\175\175\231\160\129=%s", tostring(rsp.ret_info.ret_code))
    return
  end
  Log.Debug("FriendModule:OnUpgradeCardSkinRsp \229\141\135\231\186\167\229\144\141\231\137\135\231\154\174\232\130\164\230\136\144\229\138\159")
  _G.DataModelMgr.PlayerDataModel:UpdatePlayerSkinData(rsp.card_brief_info)
  self:DispatchEvent(FriendModuleEvent.SetChooseCardBGPath, rsp.card_brief_info)
  _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.skin_level_up)
  local oriCardSkinConfig = _G.DataConfigManager:GetCardSkinConf(rsp.skin_id)
  if oriCardSkinConfig then
    if oriCardSkinConfig.level_up_card and 0 ~= oriCardSkinConfig.level_up_card then
      self.data:SetEditSelectedCardSkinId(oriCardSkinConfig.level_up_card)
      self:DispatchEvent(FriendModuleEvent.OnCardBackgroundItemSelect)
    else
      Log.ErrorFormat("FriendModule:OnUpgradeCardSkinRsp config error, skin_id=%s has no level_up_card field", tostring(rsp.skin_id))
    end
  else
    Log.ErrorFormat("FriendModule:OnUpgradeCardSkinRsp config not found, skin_id=%s", tostring(rsp.skin_id))
  end
  self:DispatchEvent(FriendModuleEvent.UpgradeCardSkinSucceed, rsp.skin_id)
end

function FriendModule:OnCmdGetSkinList()
  return self.data:GetSkinList()
end

function FriendModule:OnReceiveNewCardSkinNotify(newCardSkinNotify)
  local cardItemOwnedInfo = newCardSkinNotify.card_item_info
  local skinList = self.data:GetSkinList()
  for idx, cardItem in ipairs(skinList) do
    if cardItem.card_item_id == cardItemOwnedInfo.card_item_id then
      cardItem.ownedNum = cardItemOwnedInfo.card_item_num
      if 0 == cardItem.ownedNum then
        cardItem.is_initial_unlock = false
        cardItem.card_item_get_timestamp = 0
      else
        cardItem.is_initial_unlock = true
        cardItem.card_item_get_timestamp = cardItemOwnedInfo.card_item_get_timestamp
      end
    end
  end
  self:DispatchEvent(FriendModuleEvent.UpdateCardSkinInfo)
end

function FriendModule:OnReceiveNewCardIconNotify(newCardIconNotify)
  local cardItemOwnedInfo = newCardIconNotify.card_item_info
  local IconList = self.data:GetIconList()
  for idx, cardItem in ipairs(IconList) do
    if cardItem.card_item_id == cardItemOwnedInfo.card_item_id then
      cardItem.card_item_get_timestamp = cardItemOwnedInfo.card_item_get_timestamp
    end
  end
end

function FriendModule:OnReceiveNewCardLabelNotify(newCardLabelNotify)
  local cardItemOwnedInfo = newCardLabelNotify.card_item_info
  local labelList = self.data:GetLabelList()
  for idx, cardItem in ipairs(labelList) do
    if cardItem.card_item_id == cardItemOwnedInfo.card_item_id then
      cardItem.card_item_get_timestamp = cardItemOwnedInfo.card_item_get_timestamp
    end
  end
end

function FriendModule:AfterEnterScene(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  if self.bHadReqInitializeCardInfo == false then
    self:InitializeCardInfo()
  end
  if self:HasPanel("Friend") then
    local Panel = self:GetPanel("Friend")
    if Panel then
      Panel:DoClose()
    end
  end
  if self:HasPanel("Friend_HomeEntrance") then
    local Panel = self:GetPanel("Friend_HomeEntrance")
    if Panel then
      Panel:DoClose()
    end
  end
  if self:HasPanel("Plane_Team") then
    local Panel = self:GetPanel("Plane_Team")
    if Panel then
      self:ClosePanel("Plane_Team")
    end
  end
  self:CloseStudentCard()
end

function FriendModule:SetExchangeVisitsHintVisible(bVisible)
  local Panel = self:GetPanel("Plane_ExchangeVisits_Hint")
  if Panel then
    Panel:SetVisibleManual(bVisible)
  end
end

function FriendModule:UnlockMultiTouchLimit()
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").CHAT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").MESSAGE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType1)
end

function FriendModule:OnCmdGetFriendListForGiftVoucher(callback)
  self.data:RequestFriendRoleInfo(self, function(caller, friendList)
    if callback then
      callback(friendList)
    end
  end, FriendEnum.ClientFriendRoleInfoScene.BattlePassGift, nil, ProtoEnum.FriendType.FRIEND_TYPE_ALL, ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_BP_GIFT)
end

function FriendModule:OnCmdGetFriendListForSpecifiedFurnitureId(furniture_id, page, callback)
  local req = _G.ProtoMessage:newZoneHomeGetCraftableFriendListReq()
  req.furniture_id = furniture_id
  req.page = page
  self.GetFurnitureFriendCallback = callback
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_GET_CRAFTABLE_FRIEND_LIST_REQ, req, self, self.OnGetFriendListForSpecifiedFurnitureId, false, true)
end

function FriendModule:OnGetFriendListForSpecifiedFurnitureId(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.GetFurnitureFriendCallback(rsp.friend_list, rsp.total_num)
  end
end

function FriendModule:RequestFriendExtInfoList(uinList)
  if not uinList or 0 == #uinList then
    Log.Error("FriendModule:OnCmdRequestFriendExtInfoList uinList is empty")
    return
  end
  local maxReqNum = self.data:GetMaxNumForFriendExtInfoListReq()
  if maxReqNum < #uinList then
    Log.ErrorFormat("FriendModule:OnCmdRequestFriendExtInfoList uinList count %s exceeds max limit %s", tostring(#uinList), tostring(maxReqNum))
    return
  end
  Log.DebugFormat("FriendModule:OnCmdRequestFriendExtInfoList requesting friend extra info list for %s friends", tostring(#uinList))
  local req = _G.ProtoMessage:newZoneGetFriendExtInfoListReq()
  req.uin_list = uinList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_FRIEND_EXT_INFO_LIST_REQ, req, self, self.OnGetFriendExtraInfoRsp, false, true)
end

function FriendModule:OnGetFriendExtraInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:ParseFriendExtInfoList(rsp.ext_info_list)
    _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnFriendExtInfoUpdate)
  else
    Log.ErrorFormat("FriendModule:OnGetFriendExtraInfoRsp failed, ret_code=%s", tostring(rsp.ret_info.ret_code))
  end
end

function FriendModule:OnCmdGetMultiPlayerChannelType()
  return self.data.MultiPlayerChannelType
end

function FriendModule:OnCmdMovePlayerCamera(timer)
  if self.data.IsMove then
    return
  end
  local TargetCameraTransform, InitCameraTransform = self:GetCameraMoveTransform()
  self:MoveCamera(TargetCameraTransform, InitCameraTransform, timer)
  self.CurTargetCameraTransform = TargetCameraTransform
  self.CurInitCameraTransform = InitCameraTransform
  self.data.IsMove = true
end

function FriendModule:OnCmdGoBackPlayerCamera(timer)
  if self.CurTargetCameraTransform and self.CurInitCameraTransform then
    self:MoveCamera(self.CurInitCameraTransform, self.CurTargetCameraTransform, timer, true)
    self.data.IsMove = false
  end
end

function FriendModule:GetIsPanelMoveCamera()
  return self.data.isPanelMoveCamera
end

function FriendModule:SetIsPanelMoveCamera(isMove)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil == player then
    return
  end
  if _G.BattleManager:IsInBattle() then
    return
  end
  local isHand2p = player.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
  if isHand2p then
    self.data.isPanelMoveCamera = false
    return
  end
  self.data.isPanelMoveCamera = isMove
end

function FriendModule:GetIsMove()
  return self.data.IsMove
end

function FriendModule:OnCmdGetOwnedLabel()
  return self.data.label_owned
end

function FriendModule:OnCmdGetFriendBehaviorText(friendRoleInfo)
  return self:GetFriendBehaviorText(friendRoleInfo)
end

function FriendModule:MoveCamera(TargetCameraTransform, InitCameraTransform, timer, isRevert)
  local CameraMotionInfo = NRCModuleManager:DoCmd(CameraModuleCmd.FillCameraMotionInfo, "HorizontalMoveCamera")
  CameraMotionInfo.TargetCameraTransform = TargetCameraTransform
  CameraMotionInfo.InitCameraTransform = InitCameraTransform
  CameraMotionInfo.CameraMoveTime = timer
  CameraMotionInfo.NonStoppableByObstacle = true
  if isRevert then
    self.MoveEndHandler = _G.DelayManager:DelaySeconds(timer, function()
      _G.NRCModeManager:DoCmd(_G.CameraModuleCmd.ReturnCamera)
    end, self)
  end
  NRCModuleManager:DoCmd(CameraModuleCmd.RequestRocoCameraAndInit)
  NRCModuleManager:DoCmd(CameraModuleCmd.StartCameraMotion, CameraMotionInfo)
end

function FriendModule:GetCameraMoveTransform()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = player:GetUEController()
  local cameraTranslation = Controller.PlayerCameraManager:Abs_GetTransform().Translation
  local playerTranslation = player:GetActorLocation()
  local offsetTransform = UE4.FTransform()
  local Rotator = Controller.PlayerCameraManager.CameraRotation
  local viewRight = UE.UKismetMathLibrary.GetRightVector(Rotator)
  local screenLeft = -viewRight
  local xyOffset = UE4.FVector(screenLeft.X, screenLeft.Y, 0)
  xyOffset:Normalize()
  local dist = UE4.FVector.Dist(playerTranslation, cameraTranslation)
  local offsetDistance = 300 * dist / 500
  offsetTransform.Translation = cameraTranslation + xyOffset * offsetDistance
  local curTransform = UE4.FTransform()
  curTransform.Translation = cameraTranslation
  return offsetTransform, curTransform
end

function FriendModule:OnPlayerLeaveVisibleZone(id)
  if self.data.CurrentVisibleZoneConfId == id then
    self.data.CurrentVisibleZoneConfId = nil
  end
end

function FriendModule:DeadCloseStarChainPanel()
  local IsRecover = false
  if self:HasPanel("Chat_Main") then
    IsRecover = true
    self:ClosePanel("Chat_Main")
  end
  if self:HasPanel("QuickChatBubble") then
    IsRecover = true
    self:ClosePanel("QuickChatBubble")
  end
end

function FriendModule:OnPlayerEntranceVisibleZone(id)
  self.data.CurrentVisibleZoneConfId = id
end

function FriendModule:GetFinalBubbleTextByUinAndAreaVisible(uin, areaId, text, bIsFriend)
  local selfUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local areaConf = _G.DataConfigManager:GetAreaVisibleConf(areaId, true)
  if not areaConf then
    return text
  end
  local replacement = areaConf.area_visible_special_rule_param1
  if not replacement then
    return text
  end
  local type = areaConf.area_visible_special_rule
  if not bIsFriend and selfUin ~= uin then
    if self:IsInInteract(selfUin, uin) then
      if type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_FREE or type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_PET then
        return text
      elseif type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_LASTWORDS or type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_ALLCHANGE then
        return text .. replacement
      end
    else
      return text
    end
  elseif selfUin == uin then
    if type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_FREE or type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_PET then
      return text
    elseif type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_LASTWORDS or type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_ALLCHANGE then
      return text .. replacement
    end
  elseif type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_FREE or type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_PET then
    return text
  elseif type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_LASTWORDS or type == _G.Enum.PlayerVisibleSpecialRule.PVT_TALK_ALLCHANGE then
    return text .. replacement
  end
  return text
end

function FriendModule:IsInInteract(playerUin1, playerUin2)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local selfUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local anotherPlayer
  if playerUin1 == selfUin then
    anotherPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerUin2)
  else
    anotherPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerUin1)
  end
  if not anotherPlayer then
    return false
  end
  if not localPlayer then
    return false
  end
  local statusComponent = localPlayer.statusComponent
  if not statusComponent then
    return false
  end
  if localPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER) and anotherPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST) or localPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST) and anotherPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER) then
    local param = statusComponent._statusParams[_G.Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND]
    if param and param.player_interact_param then
      if param.player_interact_param.player_uin1 == playerUin1 and param.player_interact_param.player_uin2 == playerUin2 or param.player_interact_param.player_uin1 == playerUin2 and param.player_interact_param.player_uin2 == playerUin1 then
        return true
      end
    else
      param = statusComponent._statusParams[_G.Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P]
      if param and param.player_interact_param and (param.player_interact_param.player_uin1 == playerUin1 and param.player_interact_param.player_uin2 == playerUin2 or param.player_interact_param.player_uin1 == playerUin2 and param.player_interact_param.player_uin2 == playerUin1) then
        return true
      end
    end
  end
  if localPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_DOUBLE_RIDE_GUEST) or anotherPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_DOUBLE_RIDE_GUEST) then
    local param = statusComponent._statusParams[_G.Enum.WorldPlayerStatusType.WPST_RIDEALL]
    if param and param.ride_param then
      local uin1 = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, param.ride_param.double_ride_1p_id)
      local uin2 = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, param.ride_param.double_ride_2p_id)
      if uin1 == localPlayer and uin2 == anotherPlayer or uin1 == anotherPlayer and uin2 == localPlayer then
        return true
      end
    else
      local anotherPlayerStatusComp = anotherPlayer.statusComponent
      if anotherPlayerStatusComp then
        param = anotherPlayerStatusComp._statusParams[_G.Enum.WorldPlayerStatusType.WPST_RIDEALL]
        if param and param.ride_param then
          local uin1 = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, param.ride_param.double_ride_1p_id)
          local uin2 = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, param.ride_param.double_ride_2p_id)
          if uin1 == localPlayer and uin2 == anotherPlayer or uin1 == anotherPlayer and uin2 == localPlayer then
            return true
          end
        end
      end
    end
  end
  if localPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN) and anotherPlayer:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN) then
    return true
  end
  local visitorsList = self.data:GetOnlineVisitorList()
  local containPlayer1 = false
  local containPlayer2 = false
  for k, v in ipairs(visitorsList) do
    if v.uin == playerUin1 then
      containPlayer1 = true
    end
    if v.uin == playerUin2 then
      containPlayer2 = true
    end
  end
  if containPlayer1 and containPlayer2 then
    return true
  end
  return false
end

function FriendModule:GetFriendBehaviorText(friendRoleInfo)
  return self:GetPlayerOnlineStatusText(friendRoleInfo.battle_brief_info, friendRoleInfo.pos_info)
end

function FriendModule:GetPlayerOnlineStatusText(battle_brief_info, pos_info)
  local onlineTitle = self:GetBattleInfo(battle_brief_info)
  if "" ~= onlineTitle then
    return onlineTitle
  end
  onlineTitle = self:GetZonePositionInfo(pos_info)
  if "" ~= onlineTitle then
    return onlineTitle
  end
  local friendListOnlineTextConfig = _G.DataConfigManager:GetLocalizationConf("friend_list_online_text")
  onlineTitle = friendListOnlineTextConfig and friendListOnlineTextConfig.msg or ""
  return onlineTitle
end

function FriendModule:GetBattleInfo(battleBriefInfo)
  if not battleBriefInfo then
    return ""
  end
  local onlineTitle = ""
  local canBeWatchBattle = false
  if nil ~= battleBriefInfo and nil ~= next(battleBriefInfo) and battleBriefInfo.battle_state and battleBriefInfo.battle_state > 0 then
    local isInBattleState = battleBriefInfo.battle_state == ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IN_BATTLE
    local battleConfId = battleBriefInfo and battleBriefInfo.battle_conf_id
    local battleConf = _G.DataConfigManager:GetBattleConf(battleConfId)
    if not battleConf then
      Log.Error("UMG_Friend_Item_C:GetBattleInfo battleConf is nil", battleConfId)
      return ""
    end
    local battleType = battleConf and battleConf.type
    local battleTypeConf = battleType and _G.DataConfigManager:GetBattleTypeConf(battleType)
    if not battleTypeConf then
      Log.Error("UMG_Friend_Item_C:GetBattleInfo battleTypeConf is nil", battleType)
      return ""
    end
    canBeWatchBattle = isInBattleState and battleTypeConf and battleTypeConf.is_show_battle_type or false
    local battleTypeName = battleTypeConf and battleTypeConf.name or ""
    local pvpBattleWatchChar6Config = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character6")
    local pvpBattleWatchChar6
    if pvpBattleWatchChar6Config then
      pvpBattleWatchChar6 = pvpBattleWatchChar6Config.str
    end
    if canBeWatchBattle and "" ~= battleTypeName then
      onlineTitle = string.format(pvpBattleWatchChar6, battleTypeName)
    end
  end
  return onlineTitle
end

function FriendModule:GetZonePositionInfo(pos_info)
  if not pos_info then
    return ""
  end
  local zonePositionInfo = pos_info
  if not zonePositionInfo then
    return ""
  end
  if zonePositionInfo.display_type == _G.ProtoEnum.FriendPositionDisplayType.FPDT_CAMP_NAME then
    local campId = zonePositionInfo.camp_id
    if campId then
      local campConf = _G.DataConfigManager:GetCampConf(campId)
      if campConf then
        return campConf.camp_name
      end
    end
  elseif zonePositionInfo.display_type == _G.ProtoEnum.FriendPositionDisplayType.FPDT_SCENE_NAME then
    local sceneId = zonePositionInfo.scene_res_cfg_id
    if sceneId then
      local sceneConf = _G.DataConfigManager:GetSceneResConf(sceneId)
      if sceneConf and not sceneConf.friend_list_inf_ban then
        return sceneConf.scene_res_name
      end
    end
  else
    return ""
  end
  return ""
end

function FriendModule:GetAllCardAdventureRecordConfs()
  if self.CardRecordConfs == nil then
    local RecordConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CARD_ADVENTURE_RECORD_CONF)
    if RecordConf then
      self.CardRecordConfs = RecordConf:GetAllDatas()
    end
  end
  return self.CardRecordConfs
end

return FriendModule

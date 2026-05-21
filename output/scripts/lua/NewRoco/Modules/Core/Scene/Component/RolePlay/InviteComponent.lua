local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local PlayerOption = require("NewRoco.Modules.Core.NPC.Executors.PlayerOption")
local RelationTreeEvent = require("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MAX_DELTA_TIME = 1
local MAX_INTERACT_NUMBER = _G.DataConfigManager:GetGlobalConfig("relationtree_anim_option_num").num
local MAX_RELATION_INTERACT_DISTANCE = _G.DataConfigManager:GetGlobalConfig("relationtree_interact_distance").num
local InteractErrorCode = {
  NO_ENTER_TRAVEL_TOGETHER = 1,
  TRAVEL_TOGETHER_FULL = 2,
  COMMON_ABNORMAL_STATUS = 3
}
local InviteComponent = Base:Extend("InviteComponent")

function InviteComponent:Attach(owner)
  Base.Attach(self, owner)
  self.InviterMap = {}
  self.YellowBubblesList = {}
  self.acceptedInteract = false
  self.TotalTime = 0
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_NOTIFY, self.OnInviteNty)
  _G.NRCEventCenter:RegisterEvent("InviteComponent", self, NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.NRCEventCenter:RegisterEvent("InviteComponent", self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDespawn)
  _G.NRCEventCenter:RegisterEvent("InviteComponent", self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
  self:Restore(self.owner.serverData)
end

function InviteComponent:UpdateData(serverData, isReconnect)
  self:Restore(serverData)
end

function InviteComponent:Restore()
  if self.owner.statusComponent:IsInTogetherTeleport() then
    Log.Error("[TogetherTeleport] InviteComponent:Restore")
    local relationInfo = self.owner.serverData.relation_interact
    if GlobalConfig.DebugTogetherTelInfo then
      relationInfo = ProtoMessage:newActorInfo_RelationInteract()
      relationInfo.status = GlobalConfig.DebugTogetherTelInfo.status
      relationInfo.type = GlobalConfig.DebugTogetherTelInfo.type
      relationInfo.uin1p = GlobalConfig.DebugTogetherTelInfo.uin1p
      relationInfo.uin2p = GlobalConfig.DebugTogetherTelInfo.uin2p
    end
    if relationInfo then
      local targetUin = relationInfo.uin1p
      if targetUin ~= self.owner:GetLogicId() then
        targetUin = relationInfo.uin2p
      end
      self._interactType = relationInfo.type
      self.TargetUin = targetUin
      local handStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
      if self.owner:GetLogicId() ~= relationInfo.uin1p then
        handStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P
      end
      self.CurStatus = handStatus
      self.otherUin = targetUin
    else
      Log.Error("[TogetherTeleport] InviteComponent:Restore Failed - relation_interact is nil")
    end
  end
end

function InviteComponent:RevertRestore()
  if self.CurStatus and (self.CurStatus == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND or self.CurStatus == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    self._interactType = nil
    self.TargetUin = nil
    self.otherUin = nil
    if self.owner then
      self.owner.statusComponent:ClearStatus(self.CurStatus)
    end
    self.CurStatus = nil
  end
  self.owner.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
  self.owner.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
end

function InviteComponent:DeAttach()
  Base.DeAttach(self)
  for _Uin, v in pairs(self.InviterMap) do
    self:RemoveInviter(_Uin)
  end
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_NOTIFY, self.OnInviteNty)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDespawn)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
end

function InviteComponent:Invite(playerUin, interactType, param, bTogether)
  if not playerUin or not interactType then
    Log.Error("InviteComponent:Invite No Param")
    return
  end
  local targetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerUin)
  local Dis = targetPlayer and self.owner:DistanceTo(targetPlayer) or -1
  if Dis < 0 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2435").msg)
    return
  elseif Dis > MAX_RELATION_INTERACT_DISTANCE then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("RLTT_exceeding_application_scope").msg)
    return
  end
  local player = self.owner
  if self:IsTogetherType(interactType) and player.viewObj:IsAirWallBetweenDestination(targetPlayer:GetActorLocationFrameCache()) then
    self:ShowErrorMsg(InteractErrorCode.COMMON_ABNORMAL_STATUS)
    return
  end
  if player:IsSwimming() or targetPlayer:IsSwimming() then
    if interactType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER then
      if player and UE.UObject.IsValid(player.viewObj) then
        local is_double_ride = player.viewObj.BP_RideComponent:CanBeDoubleRide1p()
        if not is_double_ride then
          self:ShowErrorMsg(InteractErrorCode.COMMON_ABNORMAL_STATUS)
          return
        end
      end
    elseif interactType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER and targetPlayer and UE.UObject.IsValid(targetPlayer.viewObj) then
      local is_double_ride = targetPlayer.viewObj.BP_RideComponent:CanBeDoubleRide1p()
      if not is_double_ride then
        self:ShowErrorMsg(InteractErrorCode.COMMON_ABNORMAL_STATUS)
        return
      end
    end
  end
  if player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE) then
    player.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
  end
  if self:IsCanOverrideInteract(interactType, self._interactType) then
    self:InteractCancel()
  end
  param = param or ProtoMessage:newInteractParam()
  self.bTogetherReq = bTogether or interactType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER or interactType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
  local custom_params = ProtoMessage.newPlayerStatusCustomParams()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  custom_params.player_interact_param.player_uin1 = localPlayer:GetLogicId()
  custom_params.player_interact_param.player_uin2 = playerUin
  custom_params.player_interact_param.interact_id = param and param.action_id
  custom_params.player_interact_param.pet_id = param and param.picked_pet_npc_id or nil
  player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE, nil, nil, custom_params, interactType)
  if player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE) then
    local req = ProtoMessage:newZoneSceneRelationInteractInviteReq()
    req.target_uin = playerUin
    req.interact_type = interactType
    req.param = param
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_INVITE_REQ, req, self, self.OnInviteRsp, nil, true)
    self.TargetUin = playerUin
    self.InviteType = interactType
    self.TargetActionId = param and param.action_id
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, false)
  else
    local ErrorCode = InteractErrorCode.COMMON_ABNORMAL_STATUS
    self:ShowErrorMsg(ErrorCode)
  end
end

function InviteComponent:InviteCancel(caller, callback)
  local player = self.owner
  local InteractId = self.TargetActionId
  if InteractId and self.TargetUin == player:GetLogicId() then
    InteractId = nil
  end
  player.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
  local req = ProtoMessage:newZoneSceneRelationInteractInterruptReq()
  local rspWrapper = {}
  rspWrapper.handler = _G.MakeWeakFunctor(self, self.OnInviteCancelRsp)
  rspWrapper.reqMsg = req
  rspWrapper.customData = {
    InteractId = InteractId,
    caller = caller,
    callback = callback
  }
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    if _rspWrapper then
      _rspWrapper.handler(_protoData, _rspWrapper.reqMsg, _rspWrapper.customData)
    end
  end
  
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_INTERRUPT_REQ, req, rspWrapper, OnSvrRspHandle, nil, true)
  local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
  local PlayerUin = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetCurRequestPlayerUID)
  if MyRequest and PlayerUin and self.TargetUin == PlayerUin then
    _G.NRCModuleManager:DoCmd(RelationTreeCmd.CancelUnlockRelationshipNodeReq)
  end
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, true)
  self.TargetUin = nil
  self.InviteType = nil
  self.TargetActionId = nil
end

function InviteComponent:InviteAccept(playerUin, interactType, InteractParam, bTogether)
  if not playerUin or not interactType then
    Log.Error("InviteComponent:InviteAccept No Param")
    return
  end
  if self:IsTogetherType(interactType) then
    local targetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, playerUin)
    if targetPlayer and self.owner.viewObj:IsAirWallBetweenDestination(targetPlayer:GetActorLocationFrameCache()) then
      self:ShowErrorMsg(InteractErrorCode.COMMON_ABNORMAL_STATUS)
      return
    end
  end
  bTogether = bTogether or interactType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER or interactType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
  if self:IsCanOverrideInteract(interactType, self._interactType) then
    self:InteractCancel()
  else
    if self._interactType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER or self._interactType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
      self:ShowErrorMsg(InteractErrorCode.TRAVEL_TOGETHER_FULL)
    end
    return
  end
  local player = self.owner
  if self.CurStatus and player.statusComponent:HasStatus(self.CurStatus) then
    return
  end
  InteractParam = InteractParam or _G.ProtoMessage:newInteractParam()
  local uin1 = playerUin
  local uin2 = player:GetLogicId()
  if interactType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
    uin1 = uin2
    uin2 = playerUin
  end
  do
    local req = ProtoMessage:newZoneSceneRelationInteractAcceptReq()
    req.target_uin = playerUin
    req.interact_type = interactType
    req.param = InteractParam
    local rspWrapper = {}
    rspWrapper.handler = _G.MakeWeakFunctor(self, self.OnInviteAcceptRsp)
    rspWrapper.reqMsg = req
    rspWrapper.customData = {bTogether = bTogether}
    
    local function OnSvrRspHandle(_rspWrapper, _protoData)
      if _rspWrapper then
        _rspWrapper.handler(_protoData, _rspWrapper.reqMsg, _rspWrapper.customData)
      end
    end
    
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_ACCEPT_REQ, req, rspWrapper, OnSvrRspHandle, nil, true)
    if self.owner and self.owner.inputComponent ~= nil then
      self:EnableIgnoreMoveInputForRelationInteractRsp()
      _G.TimerManager:CreateTimer(self, "WaitRelationInteractRsp", 1, nil, self.DisableIgnoreMoveInputForRelationInteractRsp, 99999)
    end
    self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
    if interactType == ProtoEnum.InteractInviteType.IIT_BATTLE then
      _G.BattleNetManager:DelayOpenPVP()
      goto lbl_179
      Log.Error("InviteAccept Failed, interactType = ", interactType)
    end
  end
  ::lbl_179::
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, true)
  self.TargetUin = nil
  self.InviteType = nil
  self.TargetActionId = nil
end

function InviteComponent:InviteAcceptOnlyOption(playerUin)
  local Info = self.InviterMap[playerUin]
  if not Info then
    return
  end
  if Info.InteractType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER or Info.InteractType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER then
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      local isPlayerExitVisitor = false
      local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
      for k, v in ipairs(visitorList) do
        if v.uin == tonumber(playerUin) then
          isPlayerExitVisitor = true
        end
      end
      if isPlayerExitVisitor then
        self:InviteAccept(playerUin, Info.InteractType, Info.InteractParam)
      elseif Info.InteractType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
        if #visitorList >= 4 then
          local Text = LuaText.quit_invite_apply_join_hands_confirm_text
          if Text then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
          end
          return
        end
        self:InviteAccept(playerUin, Info.InteractType, Info.InteractParam)
      elseif Info.InteractType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER then
        self.InteractPlayerUin = playerUin
        local TipsContent = LuaText.peer_online_leave_now
        local dialogContext = DialogContext():SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCallback(self, self.InviteAcceptPopupOnlyOption)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      end
    else
      self:InviteAccept(playerUin, Info.InteractType, Info.InteractParam)
    end
  elseif Info.InteractType == ProtoEnum.InteractInviteType.IIT_REQUEST_VISIT then
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      local isPlayerExitVisitor = false
      local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
      for k, v in ipairs(visitorList) do
        if v.uin == tonumber(playerUin) then
          isPlayerExitVisitor = true
        end
      end
      if isPlayerExitVisitor then
      elseif #visitorList >= 4 then
        local Text = LuaText.relationtree_receive_world_full
        if Text then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
        end
        return
      else
        self:InviteAccept(playerUin, Info.InteractType, Info.InteractParam)
      end
    else
      self:InviteAccept(playerUin, Info.InteractType, Info.InteractParam)
    end
  else
    self:InviteAccept(playerUin, Info.InteractType, Info.InteractParam)
  end
end

function InviteComponent:InviteAcceptPopupOnlyOption(_ok)
  if _ok and self.InteractPlayerUin then
    local Info = self.InviterMap[self.InteractPlayerUin]
    if not Info then
      return
    end
    self:InviteAccept(self.InteractPlayerUin, Info.InteractType, Info.InteractParam)
  end
end

function InviteComponent:InteractCancel(selfToSelf, forceSend)
  if self.owner.statusComponent:IsInTogetherTeleport() then
    Log.Error("[TogetherTeleport] InviteComponent InteractCancel InTogetherTeleport Skip")
    return
  end
  if self._interactType or forceSend then
    if not selfToSelf then
      Log.Error("[TogetherTeleport] InviteComponent InteractCancel Tell Server")
      local req = ProtoMessage:newZoneSceneRelationInteractEndReq()
      req.interact_type = self._interactType or ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_END_REQ, req, self, self.OnInteractEndRsp, nil, true)
    end
    self._interactType = nil
    if self.CurStatus then
      self.owner.statusComponent:RemoveStatus(self.CurStatus)
      self.CurStatus = nil
    end
    local otherUin = self.otherUin
    self.otherUin = nil
    if self.owner.viewObj and self.owner.viewObj.BP_RideComponent then
      self.owner.viewObj.BP_RideComponent:OnDoubleNotifyEnd()
    end
    self:ClearPreStatusList(otherUin)
  end
end

function InviteComponent:CheckTogetherModeRight(sub_type)
  sub_type = sub_type or ProtoEnum.RelationInteractSubType.RIST_NONE
  if not self.owner then
    return false
  end
  local statusComponent = self.owner.statusComponent
  local status_hand = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
  local status_hand_2p = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P
  if not statusComponent then
    return false
  end
  if sub_type == ProtoEnum.RelationInteractSubType.RIST_NONE then
    local result = not self.owner:IsInTogetherMove()
    if false == result then
      Log.Error("\228\184\141\229\156\168\229\144\140\232\161\140")
    end
    return result
  end
  if sub_type == ProtoEnum.RelationInteractSubType.RIST_HOLD_HANDS then
    local result = statusComponent:HasStatus(status_hand) or statusComponent:HasStatus(status_hand_2p)
    if false == result then
      Log.Error("\228\184\141\229\156\168\231\137\181\230\137\139")
    end
    return result
  end
  if sub_type == ProtoEnum.RelationInteractSubType.RIST_DOUBLE_RIDE and self.owner.viewObj and self.owner.viewObj.BP_RideComponent then
    local result = self.owner.viewObj.BP_RideComponent:IsInDoubleRide()
    if false == result then
      Log.Error("\228\184\141\229\156\168\233\170\145\228\185\152")
    end
    return result
  end
  Log.Error("\230\178\161\230\156\137sub_type")
  return false
end

function InviteComponent:CheckTogetherModeAndCancel(sub_type)
  if not self:CheckTogetherModeRight(sub_type) then
    Log.Error("\230\160\161\233\170\140\229\164\177\232\180\165\239\188\140\230\137\147\230\150\173\229\143\140\228\186\186\228\186\164\228\186\146\239\188\129")
    if self.owner.statusComponent:IsInTogetherTeleport() then
      Log.Error("[TogetherTeleport] InviteComponent InteractCancel InTogetherTeleport Skip --CheckTogetherModeRight")
      return
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.no_enter_travel_together)
    self:InteractCancel()
  end
end

function InviteComponent:OnInviteRsp(rsp)
  local code = rsp.ret_info.ret_code
  local succes = false
  if 0 ~= code then
    Log.Error("InviteComponent:OnInviteRsp Error ", code, rsp.ret_info.ret_msg)
    if code ~= ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_INVITE_REPEATED then
      local TargetUin = self.TargetUin
      local InviteType = self.InviteType
      if code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
        local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
        local uin = rsp.ban_info.uin
        local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
        local reasonStr = rsp.ban_info.ban_reason or ""
        local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
        local dialogContext = DialogContext()
        dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      end
      self:InviteCancel()
      local msg = LuaText.relationtree_abnormal_status_tip
      if code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_PEER_WORLD_IS_FULL then
        local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, TargetUin)
        local Name = TargetPlayer and TargetPlayer.serverData.base.name or ""
        msg = _G.DataConfigManager:GetLocalizationConf("quit_online_apply_join_hands_confirm_text").msg
        msg = string.format(msg, Name)
      elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_WORLD_IS_FULL then
        msg = _G.DataConfigManager:GetLocalizationConf("online_invite_num_full_cannot_hand_now").msg
      elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_ALREADY then
        if InviteType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER or InviteType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER then
          msg = LuaText.travel_together_full
        end
      elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
        local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, TargetUin)
        if TargetPlayer and TargetPlayer.statusComponent then
          if TargetPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND) then
            local Config = _G.DataConfigManager:GetFunctionBanConf(Enum.PlayerConditionType.PCT_HOLD_HANDS_LEADER)
            if Config then
              msg = Config.ban_desc
            end
          elseif TargetPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
            local Config = _G.DataConfigManager:GetFunctionBanConf(Enum.PlayerConditionType.PCT_HOLD_HANDS_GUEST)
            if Config then
              msg = Config.ban_desc
            end
          end
        end
      elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_PEER_FUNCTION_BANNED then
        msg = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2444").msg
      else
        local TextConf = _G.DataConfigManager:GetLocalizationConf(string.format("RLTT_Error_Code_%d", code))
        if TextConf then
          msg = TextConf.msg
        end
      end
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
    end
  else
    succes = true
    if self.bTogetherReq then
      self.owner:PlayTogetherFx(1)
    end
    if self.TargetActionId and self.TargetUin ~= self.owner:GetLogicId() then
      local RAConf = _G.DataConfigManager:GetRelationtreeAnimConf(self.TargetActionId)
      local invite_tip = RAConf and RAConf.invite_tip
      if not string.IsNilOrEmpty(invite_tip) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, invite_tip)
      end
    end
  end
  self.bTogetherReq = nil
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UNLOCK_RELATION_SHIP_NODE_REQ, succes)
end

function InviteComponent:OnInviteCancelRsp(rsp, req, customData)
  if 0 == rsp.ret_info.ret_code and customData.InteractId then
    local RAConf = _G.DataConfigManager:GetRelationtreeAnimConf(customData.InteractId)
    local cancel_tip = RAConf and RAConf.cancel_tip
    if not string.IsNilOrEmpty(cancel_tip) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, cancel_tip)
    end
  end
  if customData.caller and customData.callback then
    _G.tcall(customData.caller, customData.callback, rsp)
  end
end

function InviteComponent:OnInviteAcceptRsp(rsp, req, customData)
  self:DisableIgnoreMoveInputForRelationInteractRsp()
  local code = rsp.ret_info.ret_code
  if 0 ~= code then
    Log.Error("InviteComponent:OnInviteAcceptRsp Error ", code, rsp.ret_info.ret_msg)
    if code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
      local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
      local uin = rsp.ban_info.uin
      local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
      local reasonStr = rsp.ban_info.ban_reason or ""
      local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
      local dialogContext = DialogContext()
      dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    end
    if code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_AVATAR_NOT_FOUND then
      self:RemoveInviter(req.target_uin)
    end
    local msg
    if code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_PEER_WORLD_IS_FULL then
      local Info = req and req.target_uin and self.InviterMap[req.target_uin]
      local Name = Info and Info.PlayerName or ""
      msg = _G.DataConfigManager:GetLocalizationConf("online_invite_num_full_cannot_hand").msg
      msg = string.format(msg, Name)
    elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_WORLD_IS_FULL then
      msg = _G.DataConfigManager:GetLocalizationConf("quit_invite_apply_join_hands_confirm_text").msg
    elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_INTERACT_ALREADY then
      if req.interact_type == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER or req.interact_type == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER then
        msg = LuaText.travel_together_full
      end
    elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_PEER_FUNCTION_BANNED then
      msg = _G.DataConfigManager:GetLocalizationConf("RLTT_Error_Code_2444").msg
    elseif code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
      msg = _G.DataConfigManager:GetLocalizationConf("Error_Code_50104").msg
    elseif code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_BAG_ITEM_PET_EGG_LIMIT then
      msg = (_G.DataConfigManager:GetBagItemTypeConf(Enum.BagItemType.BI_PET_EGG) or {}).type_hint_limit_max
    end
    if msg then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
    end
  else
    self:RemoveInviter(rsp.target_uin)
    local uin1 = req.target_uin
    local uin2 = self.owner:GetLogicId()
    if rsp.interact_type == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
      uin1 = uin2
      uin2 = req.target_uin
    end
    local bSuccess, ErrorCode = self:OnInteract(uin1, uin2, rsp.interact_type, rsp.param, rsp.interact_sub_type)
    if not bSuccess then
      self:InteractCancel(false, true)
      self:ShowErrorMsg(ErrorCode)
    else
      self:CheckTogetherModeAndCancel(rsp.interact_sub_type)
      if customData.bTogether then
        self.owner:PlayTogetherFx(2)
      end
    end
  end
end

function InviteComponent:OnInteractEndRsp(rsp)
  local code = rsp.ret_info.ret_code
  if 0 ~= code then
    Log.Error("InviteComponent:OnInteractEndRsp Error ", code, rsp.ret_info.ret_msg)
  end
  self:CheckTogetherModeAndCancel(ProtoEnum.RelationInteractSubType.RIST_NONE)
end

function InviteComponent:OnInviteNty(nty)
  local notify_type = nty.notify_type
  local target_uin = nty.target_uin
  if notify_type == ProtoEnum.RELATION_INTERACT_NOTIFY_TYPE.RINT_INVITE then
    if not nty.interact_param.is_lock then
      self:AddInviter(target_uin, nty.interact_type, nty.interact_param)
    end
  elseif notify_type == ProtoEnum.RELATION_INTERACT_NOTIFY_TYPE.RINT_ACCEPT then
    self.acceptedInteract = true
    local bSuccess, ErrorCode = self:OnInteract(nty.uin1, nty.uin2, nty.interact_type, nty.interact_param, nty.interact_sub_type)
    if nty.interact_type == ProtoEnum.InteractInviteType.IIT_BATTLE and bSuccess then
      _G.BattleNetManager:DelayOpenPVP()
    end
    self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
    self.acceptedInteract = false
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, true)
    self.TargetUin = nil
    self.InviteType = nil
    self.TargetActionId = nil
    if not bSuccess then
      self:InteractCancel(false, true)
      self:ShowErrorMsg(ErrorCode)
    else
      self:CheckTogetherModeAndCancel(nty.interact_sub_type)
    end
  elseif notify_type == ProtoEnum.RELATION_INTERACT_NOTIFY_TYPE.RINT_INTERRUPT then
    self:RemoveInviter(target_uin)
  elseif notify_type == ProtoEnum.RELATION_INTERACT_NOTIFY_TYPE.RINT_END then
    local otherUin = self.otherUin
    self.otherUin = nil
    self._interactType = nil
    if self.CurStatus then
      self.owner.statusComponent:RemoveStatus(self.CurStatus)
      self.CurStatus = nil
    end
    self.owner.viewObj.BP_RideComponent:OnDoubleNotifyEnd()
    self.owner.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
    self.owner.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
    self:ClearPreStatusList(otherUin)
    self:RemoveInviter(target_uin)
    if nty.interact_type == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER or nty.interact_type == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
      Log.DebugFormat("[%d] InviteEnd reason %d", self.owner:GetLogicId(), nty.notify_reason)
      if nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_NONE or nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_STATE_CHANGE then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.other_cancel_together)
      elseif nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_LEAVE_VISIT then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.end_visit_end_together)
      elseif nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_WAIT_TIMEOUT then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.travel_together_time_out)
      elseif nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_DIS_TOO_FAR then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.travel_together_distance_far)
      elseif nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_RECOVER_FAIL then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.teleport_fail_hold_hands)
      elseif nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_ENTER_VISIT_FAIL then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.teleport_together_both_fail)
      elseif nty.notify_reason == ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_OUT_AIRWALL then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.travel_together_illegal_area)
      end
    end
  elseif notify_type == ProtoEnum.RELATION_INTERACT_NOTIFY_TYPE.RINT_CHANGE then
    if nil == self._interactType then
      Log.error("InviteComponent NotifyChange _interactType is nil")
      return
    end
    self._ChangeTogetherType = self._interactType
    self._interactType = nil
    local Player1p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, nty.uin1)
    local is2PRide = self.owner.viewObj.BP_RideComponent.bIsDoubleRide2p
    if is2PRide then
      self.owner.viewObj.BP_RideComponent:OnDoubleNotifyEnd()
      Player1p.movementComponent:PushCurrentMoveData()
      Player1p.viewObj.RidePet.CharacterMovement:SnapToLatestReplicateData()
      Player1p.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      if localPlayer then
        local CurPos = Player1p:GetActorLocation()
        local LandPos, bGet = localPlayer.viewObj.CharacterMovement:Abs_GetLandPos(CurPos)
        if bGet and math.abs(LandPos.Z - CurPos.Z) < 300 then
          Player1p.viewObj:Abs_K2_SetActorLocation(LandPos, false, nil, false)
        end
      end
    elseif self.CurStatus and Player1p then
      Player1p.viewObj.CharacterMovement:SnapToLatestReplicateData()
      self.owner.statusComponent:RemoveStatus(self.CurStatus)
      self.CurStatus = nil
    end
    self:OnInteract(nty.uin1, nty.uin2, nty.interact_type, nty.interact_param, nty.interact_sub_type)
    self._interactType = self._ChangeTogetherType
    self._ChangeTogetherType = nil
    self:CheckTogetherModeAndCancel(nty.interact_sub_type)
    self.owner:SendEvent(PlayerModuleEvent.ON_UPDATE_TOGETHER)
  end
end

function InviteComponent:OnInteract(Uin1, Uin2, InteractType, InteractParam, SubType)
  if self._interactType == InteractType then
    return false
  end
  local player = self.owner
  local bInteract = false
  local Status, ErrorCode
  local custom_params = ProtoMessage.newPlayerStatusCustomParams()
  if InteractParam then
    custom_params.player_interact_param.interact_id = InteractParam.action_id
  end
  custom_params.player_interact_param.player_uin1 = Uin1
  custom_params.player_interact_param.player_uin2 = Uin2
  if InteractType == ProtoEnum.InteractInviteType.IIT_DOUBLE_ACTION or InteractType == ProtoEnum.InteractInviteType.IIT_HIGHFIVE or InteractType == ProtoEnum.InteractInviteType.IIT_HUGE or InteractType == ProtoEnum.InteractInviteType.IIT_REQUEST_VISIT or InteractType == ProtoEnum.InteractInviteType.IIT_BATTLE or InteractType == ProtoEnum.InteractInviteType.IIT_ARM then
    Status = Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM
    player.statusComponent:ApplyStatus(Status, nil, nil, custom_params, InteractType)
    bInteract = player.statusComponent:HasStatus(Status)
  elseif InteractType == ProtoEnum.InteractInviteType.IIT_GIFTING_EGG then
    Status = Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM
    custom_params.player_interact_param.pet_egg_id = InteractParam.picked_bagitem_conf_id
    player.statusComponent:ApplyStatus(Status, nil, nil, custom_params)
    bInteract = player.statusComponent:HasStatus(Status)
  elseif InteractType == _G.ProtoEnum.InteractInviteType.IIT_PET_BLESSING then
    Status = _G.Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING
    custom_params.player_interact_param.pet_id = InteractParam.picked_pet_npc_id
    custom_params.player_interact_param.pet_egg_id = InteractParam.picked_bagitem_conf_id
    custom_params.player_interact_param.pet_egg_gid = InteractParam.picked_egg_gid
    custom_params.player_interact_param.pet_gid = InteractParam.picked_pet_gid
    if not custom_params.player_interact_param.player_uin1 then
      custom_params.player_interact_param.player_uin1 = self.owner.serverData.base.logic_id
    end
    if not custom_params.player_interact_param.player_uin2 then
      custom_params.player_interact_param.player_uin2 = self.owner.serverData.base.logic_id
    end
    player.statusComponent:ApplyStatus(Status, nil, nil, custom_params)
    bInteract = player.statusComponent:HasStatus(Status)
  elseif InteractType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER or InteractType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER then
    local is_double_ride = SubType == ProtoEnum.RelationInteractSubType.RIST_DOUBLE_RIDE
    local Player1p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin1)
    if (nil == SubType or SubType == ProtoEnum.RelationInteractSubType.RIST_NONE) and Player1p and Player1p.viewObj then
      is_double_ride = Player1p.viewObj.BP_RideComponent:CanBeDoubleRide1p()
    end
    if is_double_ride then
      self.owner.viewObj.BP_RideComponent:OnDoubleNotifyBegin(Uin1, Uin2)
      bInteract = true
    elseif self.owner:GetLogicId() == Uin1 then
      Status = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
      bInteract = self:HandInHandLink(custom_params, Status)
    else
      Status = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P
      bInteract = self:HandInHandLink(custom_params, Status)
    end
    if bInteract then
      self.otherUin = Uin1
      if self.owner:GetLogicId() == Uin1 then
        self.otherUin = Uin2
      end
    else
      ErrorCode = InteractErrorCode.NO_ENTER_TRAVEL_TOGETHER
    end
  else
    Log.Error("InviteComponent:OnInteract Unknown InteractType")
  end
  if not bInteract and not ErrorCode then
    ErrorCode = InteractErrorCode.COMMON_ABNORMAL_STATUS
  end
  self.CurStatus = Status
  if bInteract then
    self._interactType = InteractType
  end
  return bInteract, ErrorCode
end

function InviteComponent:ShowErrorMsg(ErrorCode)
  if not ErrorCode then
    return
  end
  local Msg
  if ErrorCode == InteractErrorCode.NO_ENTER_TRAVEL_TOGETHER then
    Msg = LuaText.no_enter_travel_together
  elseif ErrorCode == InteractErrorCode.TRAVEL_TOGETHER_FULL then
    Msg = LuaText.travel_together_full
  elseif ErrorCode == InteractErrorCode.COMMON_ABNORMAL_STATUS then
    Msg = LuaText.relationtree_abnormal_status_tip
  end
  if Msg then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Msg)
  end
end

function InviteComponent:IsCanOverrideInteract(NewInteractType, OldInteractType)
  if not OldInteractType then
    return true
  end
  if self:IsTogetherType(OldInteractType) then
    return true
  end
  return false
end

function InviteComponent:OnInviteStatusChanged(isInvite)
  self.isInviteTiming = isInvite
  local player = self.owner
  if player.inputComponent then
    player.inputComponent:SetIgnoreMoveInput(self, isInvite)
  end
  self.inviteTime = 0
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if isInvite then
    if playerModule then
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.OnInputMove)
    end
    _G.NRCEventCenter:RegisterEvent("InviteComponent", self, SceneEvent.OnPlayerAttacked, self.InviteCancel)
    _G.NRCEventCenter:RegisterEvent("InviteComponent", self, NPCModuleEvent.NpcActionExecute, self.OnNpcActionExecute)
    _G.NRCPanelManager.layerCenter:AddEventListener(self, UILayerEvent.FULLSCREEN_LAYER_OPENWINDOW, self.OnOpenFullScreenWindow)
    player:AddEventListener(self, PlayerModuleEvent.ON_LUOPAN_STATE_CHANGED, self.InviteCancel)
  else
    if playerModule then
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
    end
    _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerAttacked, self.InviteCancel)
    _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.NpcActionExecute, self.OnNpcActionExecute)
    _G.NRCPanelManager.layerCenter:RemoveEventListener(self, UILayerEvent.FULLSCREEN_LAYER_OPENWINDOW, self.OnOpenFullScreenWindow)
    player:RemoveEventListener(self, PlayerModuleEvent.ON_LUOPAN_STATE_CHANGED, self.InviteCancel)
  end
end

function InviteComponent:AddInviter(Uin, InteractType, InteractParam)
  local Info = self.InviterMap[Uin]
  if Info then
    Info.InteractType = InteractType
    Info.InteractParam = InteractParam
    if Info.Option then
      Info.Option:RemoveFromInteractUI()
      local PlayerUin = Info.Option.owner and Info.Option.owner.serverData and Info.Option.owner.serverData.base and Info.Option.owner.serverData.base.logic_id or nil
      if PlayerUin and self.YellowBubblesList[PlayerUin] then
        self.YellowBubblesList[PlayerUin] = nil
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, PlayerUin)
      end
      Info.Option = nil
    end
  else
    local Distance = -1
    local action_id = InteractParam and InteractParam.action_id
    local RA_Config = action_id and _G.DataConfigManager:GetRelationtreeAnimConf(InteractParam.action_id)
    local OptionID = RA_Config and RA_Config.option_key
    local Config = OptionID and _G.DataConfigManager:GetNpcOptionConf(OptionID)
    Distance = Config and Config.option_radius or -1
    Info = {
      InteractType = InteractType,
      InteractParam = InteractParam,
      Distance = Distance
    }
    self.InviterMap[Uin] = Info
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin)
    local local_logic_id = self.owner and self.owner:GetLogicId() or 0
    local player_logic_id = player and player:GetLogicId() or 0
    local receive_invite_tip = RA_Config and RA_Config.receive_invite_tip
    if player and local_logic_id ~= player_logic_id and receive_invite_tip then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(receive_invite_tip, player.serverData.base.name))
    end
  end
end

function InviteComponent:RemoveInviter(Uin)
  local Info = self.InviterMap[Uin]
  if Info and Info.Option then
    Info.Option:RemoveFromInteractUI()
    local PlayerUin = Info.Option.owner and Info.Option.owner.serverData and Info.Option.owner.serverData.base and Info.Option.owner.serverData.base.logic_id or nil
    if PlayerUin and self.YellowBubblesList[PlayerUin] then
      self.YellowBubblesList[PlayerUin] = nil
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, PlayerUin)
    end
  end
  self.InviterMap[Uin] = nil
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.DELETE_OTHER_INVITE_REQUEST, Uin)
end

function InviteComponent:GetInviterActionID(Uin)
  local Info = self.InviterMap[Uin]
  if Info then
    return Info.InteractParam and Info.InteractParam.action_id
  end
end

function InviteComponent:GetInvviterByUin(Uin)
  local Info = self.InviterMap[Uin]
  if Info then
    return Info
  end
end

function InviteComponent:OnInputMove(dir, actionValue)
  self.bHasInput = true
end

function InviteComponent:Update(deltaTime)
  local player = self.owner
  if not player then
    return
  end
  if self.isInviteTiming then
    if self.bHasInput then
      self.bHasInput = false
      self.inviteTime = self.inviteTime + deltaTime
      if self.inviteTime > 0.15 then
        self.isInviteTiming = false
        self:InviteCancel()
      end
    else
      self.inviteTime = 0
    end
  end
  if self.InviteType and self:IsTogetherType(self.InviteType) and self.TargetUin then
    local targetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.TargetUin)
    if targetPlayer and player.viewObj:IsAirWallBetweenDestination(targetPlayer:GetActorLocationFrameCache()) then
      self:ShowErrorMsg(InteractErrorCode.COMMON_ABNORMAL_STATUS)
      self:InviteCancel()
    end
  end
  self.TotalTime = self.TotalTime + deltaTime
  if self.TotalTime < MAX_DELTA_TIME then
    return
  end
  self.TotalTime = 0
  if self.TargetUin then
    local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.TargetUin)
    if TargetPlayer and (TargetPlayer:DistanceTo(player) > MAX_RELATION_INTERACT_DISTANCE or TargetPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)) then
      self:InviteCancel()
    end
  end
  if next(self.InviterMap) then
    for _Uin, _Info in pairs(self.InviterMap) do
      local Player = _Info.Player
      if not Player then
        Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, _Uin)
        if Player then
          _Info.Player = Player
          _Info.PlayerName = Player.serverData.base.name
        else
          Log.Debug("InviteComponent:Update GetPlayerByUin fail", _Uin)
        end
      end
      if not Player or not Player.viewObj then
        _Info.Player = nil
      end
    end
  end
end

function InviteComponent:IsNPCActionCanInterrupt(NPCAction)
  local NPCOption = NPCAction.Owner
  if NPCOption and not NPCOption:IsManual() then
    return false
  end
  if NPCAction.playerId ~= self.owner:GetServerId() then
    return false
  end
  Log.Debug("InviteComponent NPCActionInterrupt", NPCAction.className, NPCOption and NPCOption:GetID())
  return true
end

function InviteComponent:OnNpcActionExecute(NPCAction)
  if self:IsNPCActionCanInterrupt(NPCAction) then
    self:InviteCancel()
  end
end

function InviteComponent:OnOpenFullScreenWindow(panel)
  if panel.panelName == "Chat_Main" then
    return
  end
  if panel.panelName == "RelationTree" or panel.panelName == "PetRelationTree" then
    return
  end
  self:InviteCancel()
end

function InviteComponent:OnNetPlayerDespawn(netPlayer)
  self:RemoveInviter(netPlayer:GetLogicId())
  if netPlayer:GetLogicId() == self.TargetUin then
    self:InviteCancel()
  end
end

function InviteComponent:OnTeleportNotify()
  for _Uin, v in pairs(self.InviterMap) do
    self:RemoveInviter(_Uin)
  end
  if self.InviteType then
    self:InviteCancel()
  end
end

function InviteComponent:OnReConnect()
  for _Uin, v in pairs(self.InviterMap) do
    self:RemoveInviter(_Uin)
  end
end

function InviteComponent:IsTogetherType(interactType)
  return interactType == ProtoEnum.InteractInviteType.IIT_REQUEST_TOGETHER or interactType == ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
end

function InviteComponent:HandInHandLink(customParams, status)
  self.owner.statusComponent:ApplyStatus(status, nil, 1, customParams)
  local success = self.owner.statusComponent:HasStatus(status)
  if GlobalConfig.DebugTogetherTel and success then
    GlobalConfig.DebugTogetherTelInfo = {}
    GlobalConfig.DebugTogetherTelInfo.status = status
    GlobalConfig.DebugTogetherTelInfo.type = self._interactType
    GlobalConfig.DebugTogetherTelInfo.uin1p = customParams.player_interact_param.player_uin1
    GlobalConfig.DebugTogetherTelInfo.uin2p = customParams.player_interact_param.player_uin2
  end
  return success
end

function InviteComponent:PreChangeTogether(target_type)
  if self._interactType then
    self._ChangeTogetherType = self._interactType
    self._interactType = nil
    local req = ProtoMessage:newZoneSceneRelationInteractChangeReq()
    req.interact_type = self._ChangeTogetherType or ProtoEnum.InteractInviteType.IIT_INVITE_TOGETHER
    req.interact_sub_type = target_type
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_INTERACT_CHANGE_REQ, req, self, self.OnChangeTogetherRsp)
    return true
  end
  return false
end

function InviteComponent:OnChangeTogetherRsp(rsp)
  Log.Debug("OnChangeTogetherRsp")
end

function InviteComponent:EndChangeTogether()
  if self._ChangeTogetherType then
    self._interactType = self._ChangeTogetherType
    self._ChangeTogetherType = nil
  end
end

function InviteComponent:IsTogetherPlayer(otherPlayer)
  if self.otherUin then
    return otherPlayer and otherPlayer:GetLogicId() == self.otherUin
  end
  return false
end

function InviteComponent:OnNoLoadingTeleport()
  local LogicStatusList = self.owner.serverData.status_info
  local isHand1p = false
  local isHand2p = false
  for _, v in ipairs(LogicStatusList) do
    if v.status == ProtoEnum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER then
      isHand1p = true
    end
    if v.status == ProtoEnum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST then
      isHand2p = true
    end
  end
  local statusComponent = self.owner.statusComponent
  if isHand1p and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND) then
    self:InteractCancel()
  end
  if isHand2p and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    self:InteractCancel()
  end
  if not isHand1p and not isHand2p and (statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND) or statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)) then
    self:InteractCancel()
  end
end

function InviteComponent:ClearPreStatusList(otherUin)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, otherUin)
  if player and player.statusComponent.ClearPreStatusList then
    player.statusComponent:ClearPreStatusList()
  end
end

function InviteComponent:EnableIgnoreMoveInputForRelationInteractRsp()
  if not self.owner or not self.owner.inputComponent then
    return
  end
  Log.Debug("EnableIgnoreMoveInputForRelationInteractRsp")
  self.owner.inputComponent:SetIgnoreMoveInput(self, true, "WaitRelationInteractRsp")
end

function InviteComponent:DisableIgnoreMoveInputForRelationInteractRsp()
  if not self.owner or not self.owner.inputComponent then
    return
  end
  Log.Debug("DisableIgnoreMoveInputForRelationInteractRsp")
  self.owner.inputComponent:SetIgnoreMoveInput(self, false, "WaitRelationInteractRsp")
end

return InviteComponent

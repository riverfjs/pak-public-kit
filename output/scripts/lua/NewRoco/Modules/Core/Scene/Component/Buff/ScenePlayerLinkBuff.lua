local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerBuff")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local RolePlayComponent = require("NewRoco.Modules.Core.Scene.Component.RolePlay.RolePlayComponent")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local ScenePlayerLinkBuff = Base:Extend("ScenePlayerLinkBuff")
local SYNC_INTERVAL = 5000
ScenePlayerLinkBuff.BuffName = "LinkBuff"

function ScenePlayerLinkBuff:OnBegin(owner, customParams, status)
  self.owner = owner
  self.customParams = customParams
  self.unlinkFlags = 0
  if not customParams then
    Log.Error("ScenePlayerLinkBuff Begin Failed: customParams is nil")
    self.owner.statusComponent:RemoveStatus(status)
    return false
  end
  self.syncReq = ProtoMessage:newZoneSceneRelationTravelTogetherSyncReq()
  self.syncPos = ProtoMessage:newPosition()
  Log.Error("ScenePlayerLinkBuff OnBegin: ", self.owner:GetLogicId())
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_SET_LINK_STATE, self.OnSetLink)
  self.isLeader = self.owner:GetLogicId() == customParams.player_interact_param.player_uin1
  self.otherPlayerUin = self.isLeader and customParams.player_interact_param.player_uin2 or customParams.player_interact_param.player_uin1
  local otherPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.otherPlayerUin)
  if otherPlayer then
    self:ListenOtherPlayer(otherPlayer)
  else
    _G.NRCEventCenter:RegisterEvent("ScenePlayerLinkBuff", self, SceneEvent.OnNetPlayerSpawn, self.OnPlayerCreated)
  end
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnAvatarReady)
  self:LinkInternal()
  self.owner:SendEvent(PlayerModuleEvent.ON_LINK_BUFF_ADD)
  if not self.isLeader and otherPlayer and UE.UObject.IsValid(otherPlayer.viewObj) then
    otherPlayer.viewObj.LinkComponent:FixChildPos()
  end
end

function ScenePlayerLinkBuff:ListenOtherPlayer(otherPlayer)
  if self.owner.isLocal and not self.isLeader then
    otherPlayer:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnLeaderApplyStatus)
    otherPlayer:AddEventListener(self, PlayerModuleEvent.ON_REMOVE_STATUS, self.OnLeaderRemoveStatus)
    otherPlayer:AddEventListener(self, PlayerModuleEvent.ON_CLEAR_STATUS, self.OnLeaderClearStatus)
    otherPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnLeaderRefreshStatus)
    local otherCrouch = otherPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
    if otherCrouch then
      self.owner.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
    else
      self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
    end
  end
  if otherPlayer.isLocal and not self.isLeader then
    self.owner:AddEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnGuestMovementModeChange)
  end
  otherPlayer:AddEventListener(self, PlayerModuleEvent.ON_LINK_BUFF_ADD, self.OnOtherPlayerLink)
  otherPlayer:AddEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnAvatarReady)
end

function ScenePlayerLinkBuff:RemoveListenOtherPlayer(otherPlayer)
  if self.owner.isLocal and not self.isLeader then
    otherPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnLeaderApplyStatus)
    otherPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_REMOVE_STATUS, self.OnLeaderRemoveStatus)
    otherPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_CLEAR_STATUS, self.OnLeaderClearStatus)
    otherPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnLeaderRefreshStatus)
  end
  if otherPlayer.isLocal and not self.isLeader then
    self.owner:RemoveEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnGuestMovementModeChange)
  end
  otherPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_LINK_BUFF_ADD, self.OnOtherPlayerLink)
  otherPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnAvatarReady)
end

function ScenePlayerLinkBuff:OnPlayerCreated(player)
  if player and player:GetLogicId() == self.otherPlayerUin then
    self:UpdateLinkState()
    self:ListenOtherPlayer(player)
  end
end

function ScenePlayerLinkBuff:OnAvatarReady()
  self:UpdateLinkState()
end

function ScenePlayerLinkBuff:OnOtherPlayerLink()
end

function ScenePlayerLinkBuff:OnGuestMovementModeChange(PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  local otherPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.otherPlayerUin)
  if otherPlayer then
    otherPlayer:ForceSendMoveReq()
  end
end

function ScenePlayerLinkBuff:OnUpdate(deltaTime)
  if not self.isLeader and self.owner.isLocal then
    self:SyncLinkPos()
    local RolePlayCpt = self.owner:GetComponent(RolePlayComponent)
    if RolePlayCpt then
      local isPlayingRpBehavior, interruptType = RolePlayCpt:CheckMoveCanInterruptRpBehavior()
      if isPlayingRpBehavior and interruptType == RolePlayModuleDef.InterruptType.CanInterrupt then
        local otherPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.otherPlayerUin)
        if otherPlayer and UE.UObject.IsValid(otherPlayer.viewObj) then
          local velocity = otherPlayer.viewObj.CharacterMovement.Velocity
          if velocity:Size() > 1 then
            self.owner.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
          end
        end
      end
    end
  end
  if self.isLeader and self.owner.isLocal then
    local otherPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.otherPlayerUin)
    if otherPlayer and otherPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR) and UE.UObject.IsValid(self.owner.viewObj) then
      local velocity = self.owner.viewObj.CharacterMovement.Velocity
      if velocity:Size() > 1 then
        otherPlayer:BreakSuitRelax()
      end
    end
  end
end

function ScenePlayerLinkBuff:SyncLinkPos()
  local curServerTime = _G.ZoneServer:GetServerTime()
  self._lastSyncTime = self._lastSyncTime or 0
  if curServerTime - self._lastSyncTime > SYNC_INTERVAL then
    if self.isLinking and UE.UObject.IsValid(self.owner.viewObj) then
      local ownerPos = self.owner.viewObj:Abs_K2_GetActorLocation()
      self.syncReq.report_pos = SceneUtils.PlayerPos2ServerPos(ownerPos, nil, self.syncPos)
      self.syncReq.pos_diff = nil
      _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_TRAVEL_TOGETHER_SYNC_REQ, self.syncReq, false)
      Log.DebugFormat("TravelTogetherSync req uin %d, %s", self.owner:GetLogicId(), self.syncReq.report_pos)
    end
    self._lastSyncTime = curServerTime
  end
end

function ScenePlayerLinkBuff:OnFinish(param)
  Log.Error("ScenePlayerLinkBuff OnFinish: ", self.owner:GetLogicId())
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_SET_LINK_STATE, self.OnSetLink)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnAvatarReady)
  local otherPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.otherPlayerUin)
  if otherPlayer then
    self:RemoveListenOtherPlayer(otherPlayer)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerSpawn, self.OnPlayerCreated)
  self:UnLinkInternal()
  if self.owner and self.owner.InviteComponent then
    self.owner.InviteComponent:InteractCancel()
    if not self.isLeader then
      self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
    end
    self.owner.movementComponent:SetIsMovingTagOnce("LinkBuffFinish")
  elseif otherPlayer and otherPlayer.isLocal then
    if otherPlayer.statusComponent:IsInTogetherTeleport() then
      Log.Error("[TogetherTeleport] otherPlayer IsInTogetherTeleport Skip Remove Hand Status")
    else
      otherPlayer.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
      otherPlayer.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
    end
  end
  self.owner = nil
  self.customParams = nil
  self.unlinkFlags = 0
end

function ScenePlayerLinkBuff:OnLeaderApplyStatus(status, statusValue, opCode, customParam)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING then
    self.owner.statusComponent:ApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    local conf
    if customParam and customParam.role_play_param and customParam.role_play_param.role_play_id then
      conf = _G.DataConfigManager:GetRoleplayBehaviorConf(customParam.role_play_param.role_play_id)
    else
      conf = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetConfByBehaviorType, statusValue)
    end
    if not conf or conf and (conf.behavior_type == Enum.BehaviorType.BT_FASHION_RELAX or conf.behavior_type == Enum.BehaviorType.BT_BOND_TOUCH_ACTIVE) then
      Log.Debug("ScenePlayerLinkBuff: Skip Sync Leader Behavior role_play_id or type is BT_FASHION_RELAX or BT_BOND_TOUCH_ACTIVE")
    else
      self.owner.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
      self.owner.statusComponent:ApplyStatus(status, opCode, statusValue, customParam)
      if not self.owner.statusComponent:HasStatus(status) then
        Log.Error("LinkStatus Applied Failed")
      end
    end
  end
end

function ScenePlayerLinkBuff:OnLeaderRemoveStatus(status, statusValue, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING then
    self.owner.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING)
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR and opCode ~= ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE then
    self.owner.statusComponent:ClearStatus(status, opCode, statusValue)
  end
end

function ScenePlayerLinkBuff:OnLeaderClearStatus(status, statusValue, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING then
    self.owner.statusComponent:ClearStatus(status, opCode, statusValue)
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    self.owner.statusComponent:ClearStatus(status, opCode, statusValue)
  end
end

function ScenePlayerLinkBuff:OnLeaderRefreshStatus(status, statusValue, opCode, customParam)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    self.owner.statusComponent:RefreshStatus(status, statusValue, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParam)
  end
end

function ScenePlayerLinkBuff:OnSetLink(isLink, flag)
  if nil == flag then
    flag = 0
  end
  if isLink then
    self.unlinkFlags = self.unlinkFlags & ~(1 << flag)
  else
    self.unlinkFlags = self.unlinkFlags | 1 << flag
  end
  Log.Debug("ScenePlayerLinkBuff:OnSetLink: ", isLink, flag, self.unlinkFlags)
  self:UpdateLinkState()
end

function ScenePlayerLinkBuff:UpdateLinkState()
  if 0 == self.unlinkFlags then
    self:LinkInternal()
  else
    self:UnLinkInternal()
  end
end

function ScenePlayerLinkBuff:LinkInternal()
  if self.isLinking then
    Log.Debug("ScenePlayerLinkBuff:LinkInternal Already Link")
    return
  end
  local selfStatus = self.isLeader and ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND or ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P
  local selfHasStatus = self.owner.statusComponent:HasStatus(selfStatus)
  if not selfHasStatus then
    Log.Debug("ScenePlayerLinkBuff:LinkInternal not selfHasStatus, finish buff")
    self.owner.buffComponent:RemoveBuff(ScenePlayerLinkBuff.BuffName)
    return
  end
  local otherPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByUin, self.otherPlayerUin)
  if otherPlayer and UE.UObject.IsValid(self.owner.viewObj) and UE.UObject.IsValid(otherPlayer.viewObj) then
    if self.isLeader then
      self.owner.viewObj.LinkComponent:Link(otherPlayer.viewObj.LinkComponent)
      if not otherPlayer.isLocal and not otherPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
        Log.Debug("ScenePlayerLinkBuff:LinkInternal Remove OtherPlayer Invite Status")
        otherPlayer.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
      end
    else
      otherPlayer.viewObj.LinkComponent:Link(self.owner.viewObj.LinkComponent)
    end
    self.isLinking = true
    if self.owner.isLocal then
      local isInTogetherTeleport = self.owner.statusComponent:IsInTogetherTeleport()
      if isInTogetherTeleport then
        self.owner.statusComponent:ReportRestoreTogetherResult(true)
        if GlobalConfig.DebugTogetherTelInfo then
          GlobalConfig.DebugTogetherTelInfo = nil
        end
      end
    end
  end
end

function ScenePlayerLinkBuff:UnLinkInternal()
  if UE.UObject.IsValid(self.owner.viewObj) then
    self.owner.viewObj.LinkComponent:UnLink()
    self.isLinking = false
  else
    Log.Error("ScenePlayerLinkBuff:UnLinkInternal Failed : owner.viewObj is nil ", self.owner:GetLogicId())
  end
end

return ScenePlayerLinkBuff

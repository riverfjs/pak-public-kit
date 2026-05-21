local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local VitalityRecoverBuff = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerVitalityRecoverBuff")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local SocialComponentEnum = require("NewRoco.Modules.Core.Scene.Component.Social.SocialComponentEnum")
local FSM = require("Common.FSM.FSM")
local VitalityRecoverStageEnum = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverEnum")
local VRSearchState = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VRSearchState")
local VRClientTriggerState = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VRClientTriggerState")
local VRServerAckSucceedState = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VRServerAckSucceedState")
local VRClientCancelState = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VRClientCancelState")
local SocialComponent = Base:Extend("SocialComponent")
local CancelReasonEnum = SocialComponentEnum.CancelReasonEnum
local FAKE_MATE_ID = 0.1
local VITALITY_RECOVER_BUFF_NAME = "VitalityRecoverBuff"

function SocialComponent:Ctor()
  Base.Ctor(self)
  self.friendList = {}
  self.strangerList = {}
  self.triggerFriendID = 0
  self.mateID = 0
  self.bIsMaster = false
  self.buffs = {}
  self.vitalityID = 0
  self.bRecoverBeginReqSent = false
  self.bCancelRequestSent = false
  self.bBeginReqSuccess = false
  self.bBeginReqFailed = false
  self.bCancelReqFailed = false
  self.cancelReason = CancelReasonEnum.NONE
  self.bFlickerStateChanged = false
  self.bPassiveFlickerState = false
  self.vitalityRecoverDistance = _G.DataConfigManager:GetGlobalConfigNumByKeyType("vitality_recover_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1)
  self.buffDelayMaxTime = _G.DataConfigManager:GetGlobalConfigNumByKeyType("vitality_recover_disappear_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1000) / 1000
  self.sendReqMaxTime = 2
  self.lastSearchReqTime = 0
  self.tickIntervalNums = 1
  self.deltaTimeCache = 0
  self.fsm = FSM()
  self.fsm:SetState(VitalityRecoverStageEnum.SEARCH, VRSearchState(self))
  self.fsm:SetState(VitalityRecoverStageEnum.CLIENT_TRIGGER, VRClientTriggerState(self))
  self.fsm:SetState(VitalityRecoverStageEnum.SERVER_ACK_SUCCEED, VRServerAckSucceedState(self))
  self.fsm:SetState(VitalityRecoverStageEnum.CLIENT_CANCEL, VRClientCancelState(self))
  self.fsm:ChangeState(VitalityRecoverStageEnum.SEARCH)
  self:DumpInfo()
end

function SocialComponent:Attach(owner)
  Base.Attach(self, owner)
  Log.Debug("[SocialComponent] Attach ownerID=", owner and owner.serverData and owner.serverData.base.logic_id)
  self.buffComponent = self.owner.buffComponent
  _G.NRCEventCenter:RegisterEvent("SocialComponent", self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
  _G.NRCEventCenter:RegisterEvent("SocialComponent", self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDeSpawn)
  _G.NRCEventCenter:RegisterEvent("SocialComponent", self, RelationTreeEvent.RELATION_STATE_LOCK, self.LockRecoverNode)
  _G.NRCEventCenter:RegisterEvent("SocialComponent", self, RelationTreeEvent.RELATION_STATE_UNLOCK, self.UnLockRecoverNode)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
end

function SocialComponent:DeAttach()
  Log.Debug("[SocialComponent] DeAttach stage=", self:GetCurVitalityRecoverStageName(), "mateID=", self.mateID, "bIsMaster=", self.bIsMaster)
  if self.owner then
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDeSpawn)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_STATE_LOCK, self.LockRecoverNode)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_STATE_UNLOCK, self.UnLockRecoverNode)
  if self.fsm then
    self.fsm:OnDestroy()
    self.fsm = nil
  end
  Base.DeAttach(self)
end

function SocialComponent:Update(deltaTime)
  if self.tickIntervalNums > 0 then
    self.tickIntervalNums = self.tickIntervalNums - 1
    self.deltaTimeCache = self.deltaTimeCache + deltaTime
    return
  else
    self.tickIntervalNums = 1
    deltaTime = deltaTime + self.deltaTimeCache
    self.deltaTimeCache = 0
  end
  if self.fsm then
    self.fsm:OnTick(deltaTime)
  end
end

function SocialComponent:UpdateData(serverData, bIsReconnect)
  Log.Debug("[SocialComponent] UpdateData bIsReconnect=", bIsReconnect, "stage=", self:GetCurVitalityRecoverStageName())
  Base.UpdateData(self, serverData)
  self:ResetToSearch()
end

function SocialComponent:ClientBreak()
  Base.OnConnect(self)
end

function SocialComponent:OnDisConnect()
  Base.OnDisConnect(self)
end

function SocialComponent:OnReConnect()
end

function SocialComponent:HasRecoverBuff()
  for _, confId in pairs(self.buffs) do
    local conf = _G.DataConfigManager:GetWorldBuffConf(confId)
    if conf and conf.buff_effect_type == Enum.WorldBuffEffect.WBE_RECOVER_STAMINA then
      return true
    end
  end
  return false
end

function SocialComponent:IsOwnerDead()
  if self.owner and self.owner.statusComponent then
    return self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)
  end
  return false
end

function SocialComponent:IsMatePlayerDead()
  local player = self:GetMatePlayer()
  if player and player.statusComponent then
    return player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)
  end
  return true
end

function SocialComponent:IsTriggerPlayerDead()
  local player = self:GetTriggerPlayer()
  if player and player.statusComponent then
    return player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)
  end
  return true
end

function SocialComponent:GetTriggerPlayer()
  if 0 ~= self.triggerFriendID then
    return self.friendList[self.triggerFriendID]
  end
  return nil
end

function SocialComponent:GetMatePlayer()
  if 0 ~= self.mateID then
    return self.friendList[self.mateID]
  end
  return nil
end

function SocialComponent:FindNearestFriend()
  if not self.owner then
    return nil
  end
  local localPlayerPos = self.owner:GetActorLocation()
  local bestId
  local bestDist = self.vitalityRecoverDistance
  for id, player in pairs(self.friendList) do
    if player and player.serverData then
      local bIsDead = false
      if player.statusComponent then
        bIsDead = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH)
      end
      if not bIsDead then
        local otherPos = player:GetActorLocation()
        local distance = UE.UKismetMathLibrary.Subtract_VectorVector(localPlayerPos, otherPos):Size()
        if bestDist > distance then
          bestDist = distance
          bestId = id
        end
      end
    end
  end
  return bestId
end

function SocialComponent:GetCurVitalityRecoverStageName()
  if self.fsm and self.fsm.state then
    return VitalityRecoverStageEnum.GetStageName(self.fsm.state.stateID)
  end
  return "NoState"
end

function SocialComponent:ResetInteractionData()
  Log.Debug("[SocialComponent] ResetInteractionData mateID=", self.mateID, "triggerFriendID=", self.triggerFriendID, "bIsMaster=", self.bIsMaster, "hasBuff=", self:HasRecoverBuff())
  self:RemoveMatePlayerListener()
  self:ResetTriggerFriendID()
  self.mateID = 0
  self.bIsMaster = false
  self.bBeginReqSuccess = false
  self.bBeginReqFailed = false
  self.bCancelReqFailed = false
  self.cancelReason = CancelReasonEnum.NONE
  self.bFlickerStateChanged = false
  self.bPassiveFlickerState = false
  self.bRecoverBeginReqSent = false
  self.bCancelRequestSent = false
  if self.buffComponent and self.buffComponent:HasBuff(VITALITY_RECOVER_BUFF_NAME) then
    Log.Debug("[SocialComponent] ResetInteractionData - removing VitalityRecoverBuff")
    self.buffs = {}
    self.buffComponent:RemoveBuff(VITALITY_RECOVER_BUFF_NAME)
  end
end

function SocialComponent:EnsureRecoverBuffAdded()
  if self.buffComponent and not self.buffComponent:HasBuff(VITALITY_RECOVER_BUFF_NAME) then
    Log.Debug("[SocialComponent] EnsureRecoverBuffAdded VitalityID=", self.vitalityID)
    self.buffComponent:AddBuff(VITALITY_RECOVER_BUFF_NAME, VitalityRecoverBuff, self.owner, self.vitalityID)
  end
end

function SocialComponent:AddMatePlayerListener()
  local matePlayer = self:GetMatePlayer()
  if matePlayer then
    Log.Debug("[SocialComponent] AddMatePlayerListener mateID=", self.mateID)
    matePlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnMatePlayerStatusChanged)
  end
end

function SocialComponent:RemoveMatePlayerListener(player)
  local matePlayer = self:GetMatePlayer() or player
  if matePlayer then
    Log.Debug("[SocialComponent] RemoveMatePlayerListener mateID=", self.mateID)
    matePlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnMatePlayerStatusChanged)
  end
end

function SocialComponent:AddTriggerPlayerListener()
  local player = self:GetTriggerPlayer()
  if player then
    Log.Debug("[SocialComponent] AddTriggerPlayerListener triggerFriendID=", self.triggerFriendID)
    player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnTriggerPlayerStatusChanged)
  end
end

function SocialComponent:RemoveTriggerPlayerListener(player)
  local triggerPlayer = self:GetTriggerPlayer() or player
  if triggerPlayer then
    Log.Debug("[SocialComponent] RemoveTriggerPlayerListener triggerFriendID=", self.triggerFriendID)
    triggerPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnTriggerPlayerStatusChanged)
  end
end

function SocialComponent:ResetToSearch()
  Log.Debug("[SocialComponent] ResetToSearch", self:GetCurVitalityRecoverStageName())
  if self.fsm then
    self.fsm:ChangeState(VitalityRecoverStageEnum.SEARCH)
  end
end

function SocialComponent:NotifyStateChangeToNext()
  Log.Debug("[SocialComponent] NotifyStateChangeToNext stage=", self:GetCurVitalityRecoverStageName())
  if self.fsm and self.fsm.state then
    self.fsm.state:ChangeToNext()
    self.cancelReason = CancelReasonEnum.NONE
  end
end

function SocialComponent:SetTriggerFriendID(id)
  self:ResetTriggerFriendID()
  if self.friendList[id] then
    Log.Debug("[SocialComponent] SetTriggerFriendID id=", id)
    self.triggerFriendID = id
    self:AddTriggerPlayerListener()
    return true
  end
  Log.Debug("[SocialComponent] SetTriggerFriendID failed, id=", id, "not in friendList")
  return false
end

function SocialComponent:SetMateID(id)
  Log.Debug("[SocialComponent] SetMateID", id, "triggerFriendID", self.triggerFriendID)
  self.mateID = id
  self:AddMatePlayerListener()
end

function SocialComponent:ResetTriggerFriendID()
  Log.Debug("[SocialComponent] ResetTriggerFriendID old=", self.triggerFriendID)
  if self.friendList[self.triggerFriendID] then
    self:RemoveTriggerPlayerListener()
  end
  self.triggerFriendID = 0
end

function SocialComponent:SendRecoverBeginReq()
  local id = self.triggerFriendID
  if 0 == id then
    return
  end
  local player = self.friendList[id]
  local name = player and player.serverData and player.serverData.base.name or "Unknown"
  Log.Debug("[SocialComponent] SendRecoverBeginReq id=", id, " name=", name)
  local reqMsg = ProtoMessage:newZoneSceneRelationRecoverBeginReq()
  reqMsg.recover_mate_uin = id
  local bSucceed = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_RECOVER_BEGIN_REQ, reqMsg, self, self.OnBeginReqCallback, false, true)
  if not bSucceed then
    Log.Debug("[SocialComponent] SendRecoverBeginReq - send failed")
    self:ResetToSearch()
  else
    self.lastSearchReqTime = 0.5
    self.bRecoverBeginReqSent = true
    self:NotifyStateChangeToNext()
  end
end

function SocialComponent:SendRecoverEndReq()
  Log.Debug("[SocialComponent] SendRecoverEndReq", self:GetCurVitalityRecoverStageName())
  local reqMsg = ProtoMessage:newZoneSceneRelationRecoverEndReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_RECOVER_END_REQ, reqMsg, self, self.OnEndReqCallback, false, true)
  self.bCancelRequestSent = true
end

function SocialComponent:SendModifyBuffReq(bFlickerState)
  local reqMsg = ProtoMessage:newZoneSceneRelationRecoverModifyBuffReq()
  reqMsg.buff_val = bFlickerState and 1 or 0
  Log.Debug("[SocialComponent] SendModifyBuffReq value=", reqMsg.buff_val)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RELATION_RECOVER_MODIFY_BUFF_REQ, reqMsg, self, self.OnModifyBuffCallback, false, true)
end

function SocialComponent:OnBeginReqCallback(rsp)
  Log.Debug("[SocialComponent] OnBeginReqCallback code=", rsp.ret_info.ret_code, " stage=", self:GetCurVitalityRecoverStageName())
  self.bRecoverBeginReqSent = false
  if 0 ~= rsp.ret_info.ret_code then
    if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_RELATIONSHIP_UNLOCK then
      local targetPlayer = self.friendList[self.triggerFriendID]
      if targetPlayer then
        self.friendList[self.triggerFriendID] = nil
        self.strangerList[self.triggerFriendID] = targetPlayer
      end
    end
    if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_RELATION_RECOVER_REPEATED then
      if self:HasRecoverBuff() then
        self.bIsMaster = false
        self.bBeginReqSuccess = false
        self.bBeginReqFailed = false
        self:NotifyStateChangeToNext()
        return
      end
      Log.Debug("[SocialComponent] OnBeginReqCallback - REPEATED, waiting for buff")
    end
    self.bBeginReqFailed = true
    self.bBeginReqSuccess = false
  else
    if self.triggerFriendID and not self.friendList[self.triggerFriendID] then
      Log.Debug("[SocialComponent] OnBeginReqCallback - friend not found, need cancel", self.triggerFriendID)
      self.cancelReason = CancelReasonEnum.TRIGGER_FRIEND_NOT_IN_LIST
    end
    self.bBeginReqSuccess = true
    self.bBeginReqFailed = false
  end
  self:NotifyStateChangeToNext()
end

function SocialComponent:OnEndReqCallback(rsp)
  Log.Debug("[SocialComponent] OnEndReqCallback code=", rsp.ret_info.ret_code, " stage=", self:GetCurVitalityRecoverStageName())
  self.bCancelRequestSent = false
  if 0 ~= rsp.ret_info.ret_code then
    self.bCancelReqFailed = true
  else
    self.bCancelReqFailed = false
  end
  self:NotifyStateChangeToNext()
end

function SocialComponent:OnModifyBuffCallback(rsp)
  Log.Debug("[SocialComponent] OnModifyBuffCallback code=", rsp.ret_info.ret_code)
end

function SocialComponent:OnPlayerStatusChanged(status, value)
  if self.bIsMaster and self:IsOwnerDead() then
    Log.Debug("[SocialComponent] OnPlayerStatusChanged - owner dead")
    self.cancelReason = CancelReasonEnum.OWNER_DEAD
    self:NotifyStateChangeToNext()
  end
end

function SocialComponent:OnMatePlayerStatusChanged(status, value)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_DEATH and self.bIsMaster and self:IsMatePlayerDead() then
    Log.Debug("[SocialComponent] OnMatePlayerStatusChanged uin=", self.mateID)
    self.cancelReason = CancelReasonEnum.MATE_DEAD
    self:NotifyStateChangeToNext()
  end
end

function SocialComponent:OnTriggerPlayerStatusChanged(status, value)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_DEATH and self.triggerFriendID > 0 and self:IsTriggerPlayerDead() then
    Log.Debug("[SocialComponent] OnTriggerPlayerStatusChanged uin=", self.triggerFriendID)
    self.cancelReason = CancelReasonEnum.TRIGGER_FRIEND_DEAD
    self:NotifyStateChangeToNext()
  end
end

function SocialComponent:LockRecoverNode(uin, type)
  if type == Enum.RelationTreeType.RLTT_RECOVER or type == Enum.RelationTreeType.RLTT_ADDFRIEND then
    Log.Debug("[SocialComponent] LockRecoverNode uin=", uin, "mateID=", self.mateID, "stage=", self:GetCurVitalityRecoverStageName())
    local player = self.friendList[uin]
    if player then
      self.friendList[uin] = nil
      self.strangerList[uin] = player
      Log.Debug("[SocialComponent] LockRecoverNode uin=", uin, "moved friendList -> strangerList")
    end
    if self.mateID == uin then
      Log.Debug("[SocialComponent] LockRecoverNode uin=", uin, "is current mate, cancelReason -> RECOVER_NODE_LOCKED")
      self.cancelReason = CancelReasonEnum.RECOVER_NODE_LOCKED
      self:NotifyStateChangeToNext()
    end
  end
end

function SocialComponent:UnLockRecoverNode(uin, type)
  if type == Enum.RelationTreeType.RLTT_RECOVER or type == Enum.RelationTreeType.RLTT_ADDFRIEND then
    local player = self.strangerList[uin]
    if player then
      self.strangerList[uin] = nil
      self.friendList[uin] = player
      Log.Debug("[SocialComponent] UnLockRecoverNode uin=", uin, "moved strangerList -> friendList")
    else
      Log.Debug("[SocialComponent] UnLockRecoverNode uin=", uin, "not in strangerList, skip")
    end
  end
end

function SocialComponent:OnNetPlayerSpawn(player)
  if player then
    local id = player.serverData.base.logic_id
    local bIsUnLock = false
    if _G.RelationTreeCmd ~= nil then
      bIsUnLock = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetPeerRelationTreeNodeState, id, Enum.RelationTreeType.RLTT_RECOVER)
    end
    if bIsUnLock or nil == bIsUnLock then
      self.friendList[id] = player
      Log.Debug("[SocialComponent] OnNetPlayerSpawn id=", id, "-> friendList")
    else
      self.strangerList[id] = player
      Log.Debug("[SocialComponent] OnNetPlayerSpawn id=", id, "-> strangerList")
    end
  end
end

function SocialComponent:OnNetPlayerDeSpawn(player)
  if player then
    local id = player.serverData.base.logic_id
    Log.Debug("[SocialComponent] OnNetPlayerDeSpawn id=", id, "mateID", self.mateID, "triggerFriendID", self.triggerFriendID)
    local bTrigger = false
    if id == self.mateID then
      self:RemoveMatePlayerListener(player)
      self.cancelReason = CancelReasonEnum.MATE_DESPAWN
      bTrigger = true
    elseif id == self.triggerFriendID then
      self:RemoveTriggerPlayerListener(player)
      self.cancelReason = CancelReasonEnum.TRIGGER_PLAYER_DESPAWN
      bTrigger = true
    end
    if bTrigger then
      self:NotifyStateChangeToNext()
    end
    self.friendList[id] = nil
    self.strangerList[id] = nil
  end
end

function SocialComponent:OnBuffChange(change)
  Log.Debug("[SocialComponent] OnBuffChange", change and change.removed_buff_id, change and change.changed_buff_info and change.changed_buff_info.buff_cfg_id, self:GetCurVitalityRecoverStageName())
  if not change then
    return
  end
  local bNeedNotify = false
  local removeID = change.removed_buff_id
  if removeID and 0 ~= removeID then
    Log.Debug("[SocialComponent] OnBuffChange removeID=", removeID)
    if self.buffs[removeID] then
      local confId = self.buffs[removeID]
      self.buffs[removeID] = nil
      local conf = _G.DataConfigManager:GetWorldBuffConf(confId)
      if conf and conf.buff_effect_type == Enum.WorldBuffEffect.WBE_RECOVER_STAMINA then
        Log.Debug("[SocialComponent] OnBuffChange - recover buff removed")
        bNeedNotify = true
      end
    end
  end
  local changeInfo = change and change.changed_buff_info
  if not changeInfo and change and change.buff_info and #change.buff_info > 0 then
    changeInfo = change.buff_info[1]
  end
  if changeInfo then
    local id = changeInfo.buff_cfg_id
    if id and 0 ~= id then
      local conf = _G.DataConfigManager:GetWorldBuffConf(id)
      if conf and conf.buff_effect_type == Enum.WorldBuffEffect.WBE_RECOVER_STAMINA then
        Log.Debug("[SocialComponent] OnBuffChange - recover buff added/changed, id=", changeInfo.id)
        self.buffs[changeInfo.id] = id
        self.vitalityID = conf.params[1]
        if changeInfo.add_buff_caster_id > 0 and changeInfo.add_buff_caster_id ~= self.owner.serverData.base.actor_id then
          Log.Debug("[SocialComponent] OnBuffChange - passive player received buff, caster_actor_id=", changeInfo.add_buff_caster_id)
          local caster = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, changeInfo.add_buff_caster_id)
          if not caster then
            Log.Error("[SocialComponent] OnBuffChange - passive player received buff, but caster is nil id=", changeInfo.add_buff_caster_id)
          end
          local uin = caster and caster.serverData.base.logic_id or FAKE_MATE_ID
          Log.Debug("[SocialComponent] OnBuffChange - passive caster uin=", uin, "bIsMaster=", self.bIsMaster)
          self:SetMateID(uin)
        end
        if not self.bIsMaster then
          self.bFlickerStateChanged = true
          self.bPassiveFlickerState = 0 ~= changeInfo.buff_val
          Log.Debug("[SocialComponent] OnBuffChange - passive flicker changed, bPassiveFlickerState=", self.bPassiveFlickerState)
        end
        bNeedNotify = true
      end
    end
  end
  if bNeedNotify then
    self:NotifyStateChangeToNext()
  end
end

function SocialComponent:DumpInfo()
end

return SocialComponent

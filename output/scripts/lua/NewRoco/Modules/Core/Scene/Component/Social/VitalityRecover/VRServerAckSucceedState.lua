local VitalityRecoverStateBase = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverStateBase")
local VitalityRecoverStageEnum = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SocialComponentEnum = require("NewRoco.Modules.Core.Scene.Component.Social.SocialComponentEnum")
local VRServerAckSucceedState = VitalityRecoverStateBase:Extend("VRServerAckSucceedState")
local CancelReasonEnum = SocialComponentEnum.CancelReasonEnum

function VRServerAckSucceedState:Ctor(component)
  VitalityRecoverStateBase.Ctor(self, component)
  self.buffDelayTime = 0
  self.bCurFlickerState = false
  self.bLastFlickerState = false
  self.sendReqTime = 0
end

function VRServerAckSucceedState:OnEnter(...)
  VitalityRecoverStateBase.OnEnter(self, ...)
  Log.Debug("[SocialComponent] VRServerAckSucceedState:OnEnter. bIsMaster=", self.component.bIsMaster)
  self.buffDelayTime = 0
  self.bCurFlickerState = false
  self.bLastFlickerState = false
  self.sendReqTime = self.component.sendReqMaxTime
  self.component:EnsureRecoverBuffAdded()
end

function VRServerAckSucceedState:OnExit()
  if self.bCurFlickerState then
    local owner = self.component.owner
    if owner then
      owner:SendEvent(PlayerModuleEvent.ON_VITALITY_BUFF_RANGE_STATE_UPDATE, false)
    end
  end
  self.buffDelayTime = 0
  self.bCurFlickerState = false
  self.bLastFlickerState = false
  self.sendReqTime = 0
  VitalityRecoverStateBase.OnExit(self)
end

function VRServerAckSucceedState:OnTick(deltaTime)
  local comp = self.component
  if comp:IsOwnerDead() then
    return
  end
  if not comp.bIsMaster then
    return
  end
  local player = comp:GetMatePlayer()
  if not player then
    Log.Debug("[SocialComponent] VRServerAckSucceedState:OnTick - MatePlayer is nil, to Search", comp.mateID)
    comp.cancelReason = CancelReasonEnum.MATE_NOT_IN_LIST
    self:ChangeToNext()
    return
  end
  local localPlayerPos = comp.owner:GetActorLocation()
  local otherPlayerPos = player:GetActorLocation()
  local distance = UE.UKismetMathLibrary.Subtract_VectorVector(localPlayerPos, otherPlayerPos):Size()
  self:DelaySendFlickerRequest(deltaTime)
  if distance < comp.vitalityRecoverDistance then
    if 0 ~= self.buffDelayTime then
      self:LeaveFlicker()
    end
    self.buffDelayTime = 0
  else
    if 0 == self.buffDelayTime then
      self:EnterFlicker()
    end
    self.buffDelayTime = self.buffDelayTime + deltaTime
    if self.buffDelayTime >= comp.buffDelayMaxTime then
      Log.Debug("[SocialComponent] VRServerAckSucceedState:OnTick - buffDelayMaxTime, to ClientCancel")
      comp.cancelReason = CancelReasonEnum.BUFF_DELAY_TIMEOUT
      self:ChangeToNext()
    end
  end
end

function VRServerAckSucceedState:ChangeToNext()
  local comp = self.component
  comp:DumpInfo()
  if not comp:HasRecoverBuff() then
    Log.Debug("[SocialComponent] VRServerAckSucceedState:ChangeToNext - no recover buff, to Search")
    self:ChangeState(VitalityRecoverStageEnum.SEARCH)
    return true
  end
  if comp.bIsMaster and comp.cancelReason ~= CancelReasonEnum.NONE then
    if comp.cancelReason ~= CancelReasonEnum.TRIGGER_FRIEND_DEAD then
      Log.Debug("[SocialComponent] VRServerAckSucceedState:ChangeToNext - to ClientCancel, cancelReason:", table.getKeyName(CancelReasonEnum, comp.cancelReason), comp.cancelReason)
      comp.cancelReason = CancelReasonEnum.NONE
      self:ChangeState(VitalityRecoverStageEnum.CLIENT_CANCEL)
      return true
    else
      Log.Debug("[SocialComponent] VRServerAckSucceedState:ChangeToNext - ignore cancelReason:", table.getKeyName(CancelReasonEnum, comp.cancelReason), comp.cancelReason)
    end
  end
  if not comp.bIsMaster and comp.bFlickerStateChanged then
    comp.bFlickerStateChanged = false
    local owner = comp.owner
    if owner then
      owner:SendEvent(PlayerModuleEvent.ON_VITALITY_BUFF_RANGE_STATE_UPDATE, comp.bPassiveFlickerState)
    end
  end
  return false
end

function VRServerAckSucceedState:DelaySendFlickerRequest(deltaTime)
  self.sendReqTime = self.sendReqTime + deltaTime
  local comp = self.component
  if self.sendReqTime > comp.sendReqMaxTime and self.bLastFlickerState ~= self.bCurFlickerState then
    self.sendReqTime = 0
    self.bLastFlickerState = self.bCurFlickerState
    comp:SendModifyBuffReq(self.bCurFlickerState)
  end
end

function VRServerAckSucceedState:EnterFlicker()
  Log.Debug("[SocialComponent] VRServerAckSucceedState:EnterFlicker mateID=", self.component.mateID)
  self.bCurFlickerState = true
  local owner = self.component.owner
  if owner then
    owner:SendEvent(PlayerModuleEvent.ON_VITALITY_BUFF_RANGE_STATE_UPDATE, true)
  end
end

function VRServerAckSucceedState:LeaveFlicker()
  Log.Debug("[SocialComponent] VRServerAckSucceedState:LeaveFlicker mateID=", self.component.mateID, "buffDelayTime=", self.buffDelayTime)
  self.bCurFlickerState = false
  local owner = self.component.owner
  if owner then
    owner:SendEvent(PlayerModuleEvent.ON_VITALITY_BUFF_RANGE_STATE_UPDATE, false)
  end
end

return VRServerAckSucceedState

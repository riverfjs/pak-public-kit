local VitalityRecoverStateBase = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverStateBase")
local VitalityRecoverStageEnum = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverEnum")
local SocialComponentEnum = require("NewRoco.Modules.Core.Scene.Component.Social.SocialComponentEnum")
local VRClientTriggerState = VitalityRecoverStateBase:Extend("VRClientTriggerState")
local CancelReasonEnum = SocialComponentEnum.CancelReasonEnum

function VRClientTriggerState:Ctor(component)
  VitalityRecoverStateBase.Ctor(self, component)
end

function VRClientTriggerState:OnEnter(...)
  VitalityRecoverStateBase.OnEnter(self, ...)
  Log.Debug("[SocialComponent] VRClientTriggerState:OnEnter triggerFriendID=", self.component.triggerFriendID)
end

function VRClientTriggerState:OnExit()
  Log.Debug("[SocialComponent] VRClientTriggerState:OnExit triggerFriendID=", self.component.triggerFriendID)
  VitalityRecoverStateBase.OnExit(self)
end

function VRClientTriggerState:ChangeToNext()
  local comp = self.component
  comp:DumpInfo()
  if comp.cancelReason == CancelReasonEnum.TRIGGER_PLAYER_DESPAWN or 0 == comp.triggerFriendID or not comp.friendList[comp.triggerFriendID] then
    Log.Debug("[SocialComponent] VRClientTriggerState:ChangeToNext - TriggerFriend gone, to Search cancelReason: ", table.getKeyName(CancelReasonEnum, comp.cancelReason))
    self:ChangeState(VitalityRecoverStageEnum.SEARCH)
    return true
  end
  if comp.bBeginReqSuccess then
    comp.bBeginReqSuccess = false
    local triggerPlayer = comp:GetTriggerPlayer()
    if not triggerPlayer or comp:IsTriggerPlayerDead() or comp:IsOwnerDead() then
      Log.Debug("[SocialComponent] VRClientTriggerState:ChangeToNext - BeginReq success but player dead/gone, to ClientCancel")
      self:ChangeState(VitalityRecoverStageEnum.CLIENT_CANCEL)
      return true
    end
    comp.bIsMaster = true
    comp:SetMateID(comp.triggerFriendID)
    comp:ResetTriggerFriendID()
    Log.Debug("[SocialComponent] VRClientTriggerState:ChangeToNext - BeginReq success, to ServerAckSucceed as Master")
    self:ChangeState(VitalityRecoverStageEnum.SERVER_ACK_SUCCEED)
    return true
  end
  if comp.bBeginReqFailed then
    comp.bBeginReqFailed = false
    Log.Debug("[SocialComponent] VRClientTriggerState:ChangeToNext - BeginReq failed, to Search")
    self:ChangeState(VitalityRecoverStageEnum.SEARCH)
    return true
  end
  if comp:HasRecoverBuff() and comp.mateID > 0 then
    Log.Debug("[SocialComponent] VRClientTriggerState:ChangeToNext - HasRecoverBuff, to ServerAckSucceed as passive")
    comp.bIsMaster = false
    self:ChangeState(VitalityRecoverStageEnum.SERVER_ACK_SUCCEED)
    return true
  end
  Log.Debug("[SocialComponent] VRClientTriggerState:ChangeToNext - no condition met, stay in ClientTrigger, hasBuff=", comp:HasRecoverBuff(), "mateID=", comp.mateID)
  return false
end

return VRClientTriggerState

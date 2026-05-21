local VitalityRecoverStateBase = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverStateBase")
local VitalityRecoverStageEnum = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverEnum")
local VRClientCancelState = VitalityRecoverStateBase:Extend("VRClientCancelState")

function VRClientCancelState:Ctor(component)
  VitalityRecoverStateBase.Ctor(self, component)
end

function VRClientCancelState:OnEnter(...)
  VitalityRecoverStateBase.OnEnter(self, ...)
  Log.Debug("[SocialComponent] VRClientCancelState:OnEnter mateID=", self.component.mateID, "bIsMaster=", self.component.bIsMaster, "hasBuff=", self.component:HasRecoverBuff())
  self.component:SendRecoverEndReq()
end

function VRClientCancelState:OnExit()
  Log.Debug("[SocialComponent] VRClientCancelState:OnExit mateID=", self.component.mateID, "hasBuff=", self.component:HasRecoverBuff())
  self.component:RemoveMatePlayerListener()
  VitalityRecoverStateBase.OnExit(self)
end

function VRClientCancelState:ChangeToNext()
  local comp = self.component
  comp:DumpInfo()
  if not comp:HasRecoverBuff() then
    Log.Debug("[SocialComponent] VRClientCancelState:ChangeToNext - no recover buff, to Search")
    self:ChangeState(VitalityRecoverStageEnum.SEARCH)
    return true
  end
  if comp.bCancelReqFailed then
    comp.bCancelReqFailed = false
    Log.Debug("[SocialComponent] VRClientCancelState:ChangeToNext - CancelReq failed, buff still exists, back to ServerAckSucceed")
    self:ChangeState(VitalityRecoverStageEnum.SERVER_ACK_SUCCEED)
    return true
  end
  return false
end

return VRClientCancelState

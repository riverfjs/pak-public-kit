local VitalityRecoverStateBase = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverStateBase")
local VitalityRecoverStageEnum = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverEnum")
local VRSearchState = VitalityRecoverStateBase:Extend("VRSearchState")

function VRSearchState:Ctor(component)
  VitalityRecoverStateBase.Ctor(self, component)
  self.searchTimer = 0
end

function VRSearchState:OnEnter(...)
  VitalityRecoverStateBase.OnEnter(self, ...)
  self.searchTimer = 0
  self.component:ResetInteractionData()
end

function VRSearchState:OnExit()
  VitalityRecoverStateBase.OnExit(self)
  self.searchTimer = 0
end

function VRSearchState:OnTick(deltaTime)
  local comp = self.component
  if comp:IsOwnerDead() then
    return
  end
  self.searchTimer = self.searchTimer + deltaTime
  if self.searchTimer < comp.lastSearchReqTime then
    return
  end
  self.searchTimer = 0
  local bestId = comp:FindNearestFriend()
  if bestId and bestId > 0 then
    Log.Debug("[SocialComponent] VRSearchState:OnTick - found nearestFriend id=", bestId)
    if comp:SetTriggerFriendID(bestId) then
      comp:SendRecoverBeginReq()
    end
  end
end

function VRSearchState:ChangeToNext()
  local comp = self.component
  comp:DumpInfo()
  if comp:HasRecoverBuff() then
    Log.Debug("[SocialComponent] VRSearchState:ChangeToNext - HasRecoverBuff, to ServerAckSucceed")
    self:ChangeState(VitalityRecoverStageEnum.SERVER_ACK_SUCCEED)
    return true
  end
  if comp.bRecoverBeginReqSent then
    Log.Debug("[SocialComponent] VRSearchState:ChangeToNext - bRecoverBeginReqSent, to ClientTrigger")
    self:ChangeState(VitalityRecoverStageEnum.CLIENT_TRIGGER)
    return true
  end
  if comp.bBeginReqSuccess then
    Log.Debug("[SocialComponent] VRSearchState:ChangeToNext - bBeginReqSuccess, to ServerAckSucceed")
    comp.bBeginReqSuccess = false
    self:ChangeState(VitalityRecoverStageEnum.SERVER_ACK_SUCCEED)
    return true
  end
  Log.Debug("[SocialComponent] VRSearchState:ChangeToNext - no condition met, stay in Search")
  return false
end

return VRSearchState

local FSMState = require("Common.FSM.FSMState")
local VitalityRecoverStageEnum = require("NewRoco.Modules.Core.Scene.Component.Social.VitalityRecover.VitalityRecoverEnum")
local VitalityRecoverStateBase = FSMState:Extend("VitalityRecoverStateBase")

function VitalityRecoverStateBase:Ctor(component)
  self.component = component
end

function VitalityRecoverStateBase:GetStateName()
  return VitalityRecoverStageEnum.GetStageName(self.stateID)
end

function VitalityRecoverStateBase:ChangeToNext()
  return false
end

function VitalityRecoverStateBase:ChangeState(stateId, ...)
  if self.fsm then
    self.fsm:ChangeState(stateId, ...)
  end
end

function VitalityRecoverStateBase:InState(stateId)
  if self.fsm then
    return self.fsm:InState(stateId)
  end
  return false
end

function VitalityRecoverStateBase:OnEnter(...)
  Log.Debug("[SocialComponent] Enter state: ", self:GetStateName())
end

function VitalityRecoverStateBase:OnExit()
  Log.Debug("[SocialComponent] Exit state: ", self:GetStateName())
end

function VitalityRecoverStateBase:OnTick(deltaTime)
end

return VitalityRecoverStateBase

local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleActionBase
local BattleRoundPlayEndCheck = Base:Extend("BattleRoundPlayEndCheck")
FsmUtils.MergeMembers(Base, BattleRoundPlayEndCheck, {})

function BattleRoundPlayEndCheck:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
end

function BattleRoundPlayEndCheck:OnEnter()
  self:CheckCameraLayerMask()
  self.BattleManager.battleRuntimeData:SetIsJumpAiPerform(false)
  self:Finish()
end

function BattleRoundPlayEndCheck:CheckCameraLayerMask()
  local battleCraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
  if not (battleCraneCamera and battleCraneCamera.CameraActor) or not battleCraneCamera.CameraComponent then
    return
  end
  local battleCameraComp = battleCraneCamera.CameraComponent
  battleCameraComp.CullingMask = -1
end

return BattleRoundPlayEndCheck

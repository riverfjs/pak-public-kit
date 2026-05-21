local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleActionBase
local BeastCheckBattleActor = Base:Extend("BeastCheckBattleActor")
FsmUtils.MergeMembers(Base, BeastCheckBattleActor, {})

function BeastCheckBattleActor:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BeastCheckBattleActor:OnEnter()
  self.resList = BattleConst.TeamBeastEnterSkill
  self:OnTick(0)
end

function BeastCheckBattleActor:OnTick(DeltaTime)
  if not BattleManager.PrepareOver then
    return
  end
  if BattleUtils.IsEnterCatchInTeamBattle() then
    self:Finish()
  end
  if self.fsm:GetProperty("BeastHud") == nil then
    return
  end
  for _, v in ipairs(self.resList or {}) do
    if not BattleSkillManager:IsResReady(v) then
      return
    end
  end
  self:Finish()
end

function BeastCheckBattleActor:OnFinish()
  self.resList = nil
end

return BeastCheckBattleActor

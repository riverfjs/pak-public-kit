local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattleActionBase
local BattleBranchAction = Base:Extend("BattleBranchAction")
FsmUtils.MergeMembers(Base, BattleBranchAction, {})

function BattleBranchAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleBranchAction:OnEnter()
  if _G.EnableSpeedUpEnterBattle then
    local battleType = _G.BattleManager.battleRuntimeData.battleType
    if BattleUtils.IsPvp() then
      if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      elseif _G.EnableSpeedUpEnterPVPBattle then
        self.fsm:SendEvent(BattleEvent.EnterPvpPreInit)
      end
    elseif BattleUtils.IsNpcChallenge() then
      if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      else
      end
    elseif battleType == Enum.BattleType.BT_PVESPECIAL then
      if self:CheckIsReconnect() or self:CheckIsDebugConnect() then
      else
      end
    elseif BattleUtils.IsLeaderFight() or BattleUtils.IsWorldLeaderFight() or BattleUtils.IsLeaderChallenge() then
      if self:CheckIsReconnect() or self:CheckIsDebugConnect() then
      else
        Log.Debug("BattleInitAction onenter leader fight")
      end
    elseif BattleUtils.IsTrainBattle() then
    elseif BattleUtils.IsBloodTeam() then
      if self:CheckIsReconnect() then
      elseif _G.EnableSpeedUpEnterBloodTeamBattle then
        self.fsm:SendEvent(BattleEvent.EnterTeamBlood, self)
      end
    elseif BattleUtils.IsBeastTeam() then
      if self:CheckIsReconnect() then
      elseif _G.EnableSpeedUpEnterBeastTeamBattle then
        self.fsm:SendEvent(BattleEvent.EnterBeastPreInit)
      end
    elseif BattleUtils.IsFinalBattleP1() then
      if self:CheckIsReconnect() then
      elseif _G.EnableSpeedUpEnterFinalBattle then
        self.fsm:SendEvent(BattleEvent.EnterFinalBattleSpeedUp)
      end
    elseif BattleUtils.IsB1FinalBattleP1() then
      if self:CheckIsReconnect() then
      else
        self.fsm:SendEvent(BattleEvent.EnterB1FinalBattle, self)
      end
    elseif BattleUtils.IsSpecialNoPc() then
      if self:CheckIsReconnect() then
      else
        self.fsm:SendEvent(BattleEvent.EnterNoPC, self)
      end
    elseif self:CheckIsReconnect() or self:CheckIsDebugConnect() or BattleUtils.IsWatchingBattle() then
    elseif not BattleUtils.HasEnemyPlayer() then
      self.fsm:SendEvent(BattleEvent.EnterWildPreInit, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterPvePreInit)
    end
  end
  self:Finish()
end

function BattleBranchAction:CheckIsReconnect()
  return BattleUtils.CheckIsReconnect()
end

function BattleBranchAction:CheckIsDebugConnect()
  if _G.IsEnterBattleByDebug then
    return false
  end
  if not BattleManager.battleRuntimeData:HasValidNPC() then
    return true
  end
  return false
end

return BattleBranchAction

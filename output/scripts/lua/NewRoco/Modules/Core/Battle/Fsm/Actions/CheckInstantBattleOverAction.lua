local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local Base = BattleActionBase
local CheckInstantBattleOverAction = BattleActionBase:Extend("CheckInstantBattleOverAction")
FsmUtils.MergeMembers(BattleActionBase, CheckInstantBattleOverAction, {
  {name = "Flows", type = "table"},
  {
    name = "IsSelfPerform",
    type = "boolean"
  },
  {name = "NpcDelay", type = "boolean"}
})

function CheckInstantBattleOverAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function CheckInstantBattleOverAction:OnEnter()
  if BattleManager.isInBattle then
    local PerformCmd = self:GetProperty("Flows")
    local IsFromRoundStart = self:GetProperty("IsFromRoundStart")
    if self.fsm == BattleManager.teamBattlePerformFsm and not IsFromRoundStart then
      BattleNetManager:SendBattleRoundFlowFinishReq(PerformCmd.seq_num)
    end
    if BattleUtils.IsTeam() then
      BattleManager:TeamBattlePerformFinish(PerformCmd)
    end
    local npcDelay = self:GetProperty("NpcDelay")
    self.BattleManager = _G.BattleManager
    if BattleExitHelper.IsFinishSeamless() then
      if BattleUtils.IsPvp() then
        return
      end
      self.BattleManager.stateFsm:Resume()
      self.BattleManager.stateFsm:SendEvent(BattleEvent.EnterSeamlessOver, self)
    elseif BattleExitHelper.IsFinishByCatch() then
      if self.fsm == self.BattleManager.instantFsm then
        self.fsm.EventDispatcher:SendEvent(BattleEvent.InstantPlayOver)
      end
    elseif self.fsm == self.BattleManager.instantFsm then
      local enemys = self.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
      local isCatchOver = true
      for _, v in ipairs(enemys) do
        if not v.card:IsBeCatch() then
          isCatchOver = false
        end
      end
      if isCatchOver then
        self.BattleManager.instantFsm.EventDispatcher:SendEvent(BattleEvent.InstantPlayOver)
      else
        local IsSelfPerform = self:GetProperty("IsSelfPerform")
        if IsSelfPerform then
          if self.BattleManager.stateFsm:GetActiveStateName() == BattleEnum.StateNames.StartInstant then
            self.BattleManager.stateFsm:Resume()
            if true == npcDelay then
              Log.Debug("zgx No op \229\141\179\230\151\182\232\161\168\230\188\148\229\174\140\230\136\144 \232\191\155\229\133\165\232\161\168\230\131\133\230\181\129\231\168\139")
              self.BattleManager.stateFsm:SendEvent(BattleEvent.EnterWaitOther, self, {
                BattleEnum.StateNames.StartInstant
              })
            else
              self.BattleManager.stateFsm:SendEvent(BattleEvent.EnterRoundSelect, self, {
                BattleEnum.StateNames.StartInstant
              })
            end
          end
        else
          local currentBattleStateName = _G.BattleManager:GetCurrentStateName()
          if currentBattleStateName == BattleEnum.StateNames.RoundSelect then
            BattleUtils.DirectUpdateUI()
          end
        end
      end
    end
  end
  self:Finish()
end

function CheckInstantBattleOverAction:OnExit()
  self.BattleManager = nil
end

return CheckInstantBattleOverAction

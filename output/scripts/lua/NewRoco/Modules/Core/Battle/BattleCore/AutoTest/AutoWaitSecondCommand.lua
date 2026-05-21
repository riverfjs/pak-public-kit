local Base = require("NewRoco.Modules.Core.Battle.BattleCore.AutoTest.BattleAutoCommand")
local AutoWaitSecondCommand = Base:Extend("AutoWaitSecondCommand")

function AutoWaitSecondCommand:Ctor(second, isOutBattle)
  Base.Ctor(self)
  self.waitSecond = second
  self.IsOutBattleCommand = isOutBattle
end

function AutoWaitSecondCommand:ExecuteCommand()
  Base.ExecuteCommand(self)
  Log.Debug("BattleAutoTest  \229\188\128\229\167\139\231\173\137\229\190\133\229\145\189\228\187\164  \231\173\137\229\190\133\231\167\146\230\149\176 ", self.waitSecond)
  self.delayId = _G.DelayManager:DelaySeconds(self.waitSecond, self.CompleteCommand, self)
end

function AutoWaitSecondCommand:LogFinish()
  Log.Debug("BattleAutoTest  \231\173\137\229\190\133\229\145\189\228\187\164\231\187\147\230\157\159")
  _G.DelayManager:CancelDelay(self.delayId)
  self.delayId = nil
end

function AutoWaitSecondCommand:Break()
  Log.Error("BattleAutoTest.AutoWaitSecondCommand \230\137\167\232\161\140\229\164\177\232\180\165")
  Base.Break(self)
  _G.DelayManager:CancelDelay(self.delayId)
  self.delayId = nil
end

return AutoWaitSecondCommand

local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleAutoCommand = NRCClass:Extend()

function BattleAutoCommand:Ctor()
  self.IsExecuted = false
  self.IsExecuting = false
  self.RepeatInterval = 1.5
  self.RepeatLimitNumber = 20
  self:AddListener()
end

function BattleAutoCommand:AddListener()
end

function BattleAutoCommand:ExecuteCommand()
  if self.waitDelay then
    _G.DelayManager:CancelDelayById(self.waitDelay)
  end
  self.waitDelay = nil
  if self.IsExecuted or self.IsExecuting then
    return
  end
  self.IsExecuting = true
end

function BattleAutoCommand:WaitToRepeat()
  self.RepeatLimitNumber = self.RepeatLimitNumber - 1
  self.IsExecuting = false
  if self.RepeatLimitNumber < 0 then
    self:Break()
  else
    self.waitDelay = _G.DelayManager:DelaySeconds(self.RepeatInterval, self.ExecuteCommand, self)
  end
end

function BattleAutoCommand:CompleteCommand()
  if self.IsExecuting then
    self.IsExecuting = false
    self.IsExecuted = true
    self:RemoveListener()
    self:LogFinish()
    _G.BattleAutoTest:CommandComplete(self)
  end
end

function BattleAutoCommand:LogFinish()
end

function BattleAutoCommand:RemoveListener()
end

function BattleAutoCommand:Break()
  self:RemoveListener()
  _G.BattleAutoTest:CommandBreak(self)
end

return BattleAutoCommand

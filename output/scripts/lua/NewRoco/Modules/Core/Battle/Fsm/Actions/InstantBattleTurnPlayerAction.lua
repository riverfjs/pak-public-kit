local BattleTurnPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleTurnPlayer")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local Base = BattleActionBase
local InstantBattleTurnPlayerAction = Base:Extend("InstantBattleTurnPlayerAction")
FsmUtils.MergeMembers(Base, InstantBattleTurnPlayerAction, {
  {name = "Flows", type = "table"},
  {name = "SettleInfo", type = "table"},
  {
    name = "IsSelfPerform",
    type = "boolean"
  },
  {name = "NpcDelay", type = "boolean"}
})

function InstantBattleTurnPlayerAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.TurnPlayer = BattleTurnPlayer()
  self:SetActionType(BattleActionBase.ActionType.ClientTurnPlayAction)
end

function InstantBattleTurnPlayerAction:OnEnter()
  self.timeout = 300
  local PerformCmd = self:GetProperty("Flows")
  local SettleInfo = self:GetProperty("SettleInfo")
  local IsSelfPerform = self:GetProperty("IsSelfPerform")
  local npcDelay = self:GetProperty("NpcDelay")
  if IsSelfPerform then
    _G.BattleManager.EscapeContext:Close()
  end
  if self.TurnPlayer then
    self.TurnPlayer:OnActionAquireFromPool()
  end
  if PerformCmd then
    self.TurnPlayer:RunFlows(PerformCmd, SettleInfo, self, self.Finish, IsSelfPerform, npcDelay)
  else
    self:Finish()
  end
end

function InstantBattleTurnPlayerAction:DoFinalize()
  Base.DoFinalize(self)
  if self.TurnPlayer then
    self.TurnPlayer:DoFinalize()
  end
end

function InstantBattleTurnPlayerAction:OnFinish()
  self:DestroyProperty("camActor_0002")
  self:DestroyProperty("camActor_0002_SA")
  if self.TurnPlayer then
    self.TurnPlayer:OnActionReleaseToPool()
  end
  local IsSelfPerform = self:GetProperty("IsSelfPerform")
  if IsSelfPerform then
    _G.BattleManager.vBattleField.battleCameraManager:CalcPos()
  end
end

function InstantBattleTurnPlayerAction:OnExit()
end

function InstantBattleTurnPlayerAction:DestroyProperty(name)
  local Actor = self.fsm:GetProperty(name, nil)
  if Actor and Actor:IsValid() then
    Actor:K2_DestroyActor()
    Actor = nil
  end
  self.fsm:SetProperty(name, nil)
end

return InstantBattleTurnPlayerAction

local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local EventDispatcher = require("Common.EventDispatcher")
local Fsm = require("NewRoco.Modules.Core.Fsm.Fsm")
local InstantBattleTurnPlayerAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.InstantBattleTurnPlayerAction")
local CheckInstantBattleOverAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.CheckInstantBattleOverAction")
local BattlePreloadTurnPlayResAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.BattlePreloadTurnPlayResAction")
local BattlePetRevertPosAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.BattlePetRevertPosAction")
local BattleRoundPlayEndCheck = require("NewRoco.Modules.Core.Battle.Fsm.Actions.BattleRoundPlayEndCheck")

local function CreateFsm()
  local fsm = Fsm("InstantBattleFsm")
  local FlowsVar = fsm:CreateVar("Flows")
  local SettleInfoVar = fsm:CreateVar("SettleInfo")
  local IsSelfPerform = fsm:CreateVar("IsSelfPerform")
  local npcDelayVar = fsm:CreateVar("NpcDelay")
  local IsFromRoundStartVar = fsm:CreateVar("IsFromRoundStart")
  fsm:SetProperty("IsFromInstantBattleFsm", true)
  local InstantPlay = fsm:CreateSequentialState(BattleEnum.InstantBattleState.InstantPlay)
  InstantPlay:AddAction(BattlePreloadTurnPlayResAction("BattlePreloadTurnPlayResAction", {Flows = FlowsVar, SettleInfo = SettleInfoVar}))
  InstantPlay:AddAction(InstantBattleTurnPlayerAction("InstantBattleTurnPlayerAction", {
    Flows = FlowsVar,
    SettleInfo = SettleInfoVar,
    IsSelfPerform = IsSelfPerform,
    NpcDelay = npcDelayVar
  }))
  InstantPlay:AddAction(BattlePetRevertPosAction("BattlePetRevertPosAction"))
  InstantPlay:AddAction(BattleRoundPlayEndCheck("BattleRoundPlayEndCheck"))
  InstantPlay:AddAction(CheckInstantBattleOverAction("CheckInstantBattleOverAction", {
    Flows = FlowsVar,
    IsSelfPerform = IsSelfPerform,
    NpcDelay = npcDelayVar,
    IsFromRoundStart = IsFromRoundStartVar
  }))
  fsm:SetInitState(InstantPlay)
  fsm.EventDispatcher = EventDispatcher()
  return fsm
end

return CreateFsm

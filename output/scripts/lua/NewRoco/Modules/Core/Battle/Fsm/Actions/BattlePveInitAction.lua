local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Enum = require("Data.Config.Enum")
local BattlePveInitAction = BattleActionBase:Extend("BattleInitAction")

function BattlePveInitAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
end

function BattlePveInitAction:OnEnter()
  Log.Trace("BattlePveInitAction:OnEnter")
  NRCEventCenter:DispatchEvent(BattleEvent.EnterBattle)
  BattleManager:OpenBattleMainWindow()
  BattleManager:PlayBattleBGM()
  self:Finish()
end

function BattlePveInitAction:CheckIsReconnect()
  return BattleUtils.CheckIsReconnect()
end

function BattlePveInitAction:CheckIsDebugConnect()
  if _G.IsEnterBattleByDebug then
    return false
  end
  if not BattleManager.battleRuntimeData:HasValidNPC() then
    return true
  end
  return false
end

function BattlePveInitAction:OnExit()
  self.preLoadAssetNumber = 0
end

return BattlePveInitAction

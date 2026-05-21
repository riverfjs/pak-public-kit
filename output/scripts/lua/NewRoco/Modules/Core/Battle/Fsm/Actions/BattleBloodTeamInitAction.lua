local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleInitAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.BattleInitAction")
local BattleBloodTeamInitAction = BattleInitAction:Extend("BattleBloodTeamInitAction")

function BattleBloodTeamInitAction:OnEnter()
  NRCEventCenter:DispatchEvent(BattleEvent.EnterBattle)
  self.BattleManager:OpenBattleMainWindow()
  _G.BattleLevelHelper:SetEnvVolumeForLoadLevel(true)
  _G.BattleLevelHelper:ResetBloodTeamLevelData()
  self:Finish()
end

return BattleBloodTeamInitAction

local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleActionBase
local BattleB1P3ReconnectEnterPerformAction = Base:Extend("BattleB1P3ReconnectEnterPerformAction")
FsmUtils.MergeMembers(Base, BattleB1P3ReconnectEnterPerformAction, {})

function BattleB1P3ReconnectEnterPerformAction:OnEnter()
  if not _G.BattleUtils.IsB1FinalBattleP3() then
    self:Finish()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.HideBattlePopupPanel)
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenPetTheFinalBattle)
  self:Finish()
end

return BattleB1P3ReconnectEnterPerformAction

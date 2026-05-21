local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleSurpriseBoxShowAction = BattleActionBase:Extend("BattleSurpriseBoxShowAction")

function BattleSurpriseBoxShowAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
end

function BattleSurpriseBoxShowAction:OnEnter()
end

function BattleSurpriseBoxShowAction:OnExit()
end

return BattleSurpriseBoxShowAction

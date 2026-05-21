local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleAdaptivePetPosAction = BattleActionBase:Extend("BattleAdaptivePetPosAction")

function BattleAdaptivePetPosAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
end

function BattleAdaptivePetPosAction:OnEnter()
  if _G.enableAdaptiveBattlePetPos then
    local pets = BattleManager.battlePawnManager:GetPlayerTeamPets()
    for i, v in ipairs(pets) do
      if v then
        BattleManager.vBattleField:AdaptiveMyBattlePetPos(v.model)
        v:PinOnTheGround()
      end
    end
    local enemyPet = BattleManager.battlePawnManager:GetInFieldPet(BattleEnum.Team.ENUM_ENEMY)
    if enemyPet then
      BattleManager.vBattleField:AdaptiveEnemyBattlePetPos(enemyPet)
      enemyPet:PinOnTheGround()
    end
  end
  self:Finish()
end

return BattleAdaptivePetPosAction

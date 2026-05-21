local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local Base = BattleActionBase
local BattleB1P1EnterPerformAction = Base:Extend("BattleB1P1EnterPerformAction")
FsmUtils.MergeMembers(Base, BattleB1P1EnterPerformAction, {})

function BattleB1P1EnterPerformAction:OnEnter()
  self.BattleManager = _G.BattleManager
  self.PawnManger = self.BattleManager.battlePawnManager
  local BossPlayer = self.PawnManger:GetPlayerEnemyTeam()
  if BossPlayer and BossPlayer then
    local skillPath = BattleConst.B1P1EnterG6
    local class = BattleSkillManager:GetLoadedClass(skillPath)
    if not class then
      Log.WarningFormat("Can't load skill class %s", skillPath)
      self:Finish()
      return
    end
    local skillComponent = BossPlayer.model.RocoSkill
    local skill = skillComponent:FindOrAddSkillObj(class)
    if not skill then
      Log.WarningFormat("Can't find or load skill object %s %s", class, skillPath)
      self:Finish()
      return
    end
    if self:EnemyHasSupplyPet() then
      local blackboard = skill:GetBlackboard()
      if blackboard and UE.UObject.IsValid(blackboard) then
        blackboard:SetValueAsString("CreateBall", "CreateBall")
      end
    end
    local pets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
    for i, battlePet in ipairs(pets) do
      if battlePet and battlePet.model and battlePet.card then
        BattleUtils.SetParticleKeyForSkillObj(battlePet.model, skill, battlePet.card.medalBlackBoard)
      end
    end
    skill:SetCaster(BossPlayer.model)
    skill:SetTargets({
      BossPlayer.model
    })
    skill:SetCharacters(_G.BattleManager.battlePawnManager:GetAllPawnActorForSkill())
    skill:RegisterEventCallback("ActionStart", self, self.OnActionStart)
    skill:RegisterEventCallback("SavedBallBP", self, self.SavedBallBP)
    skill:RegisterEventCallback("HideBuffBar", self, self.HideBuffBar)
    skill:RegisterEventCallback("ShowBuffBar", self, self.ShowBuffBar)
    skill:RegisterEventCallback("End", self, self.OnSkillComplete)
    skill:RegisterEventCallback("PreEnd", self, self.OnSkillComplete)
    skillComponent:LoadAndPlaySkill(skill)
    self.skillObject = skill
  else
    _G.BattleManager.battleRuntimeData:RemoveB1P1LevelSequence()
    self:Finish()
  end
end

function BattleB1P1EnterPerformAction:OnActionStart()
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
end

function BattleB1P1EnterPerformAction:EnemyHasSupplyPet()
  local enemyAliveCount = self:GetSurvivalEnemyPetNum()
  return enemyAliveCount > 1 and enemyAliveCount <= 6
end

function BattleB1P1EnterPerformAction:GetSurvivalEnemyPetNum()
  if BattleUtils.GetBattleInitInfo().b1_final_battle and BattleUtils.GetBattleInitInfo().b1_final_battle.p1_enemy_pet_num then
    return BattleUtils.GetBattleInitInfo().b1_final_battle.p1_enemy_pet_num
  end
  local enemyAlivePet = self.PawnManger:GetPlayerEnemyTeam().deck:GetAliveCards()
  return #enemyAlivePet
end

function BattleB1P1EnterPerformAction:SavedBallBP()
  if self.skillObject then
    local blackboard = self.skillObject:GetBlackboard()
    if blackboard and UE.UObject.IsValid(blackboard) then
      local B1BallBP = blackboard:GetValueAsObject(BattleConst.B1BallBlackboardKey)
      if B1BallBP and UE.UObject.IsValid(B1BallBP) then
        self.BattleManager.battleRuntimeData:SetB1P1BallActor(B1BallBP)
        if self:EnemyHasSupplyPet() then
          local enemyAliveCount = self:GetSurvivalEnemyPetNum()
          if enemyAliveCount < 6 then
            B1BallBP["CW" .. enemyAliveCount - 1](B1BallBP)
          end
        end
      end
    end
  end
end

function BattleB1P1EnterPerformAction:OnSkillComplete()
  if self.skillObject then
    local blackboard = self.skillObject:GetBlackboard()
    if blackboard and UE.UObject.IsValid(blackboard) then
      blackboard:RemoveObjectValue(BattleConst.B1BallBlackboardKey)
    end
    self.skillObject = nil
  end
  self:Finish()
end

function BattleB1P1EnterPerformAction:HideBuffBar()
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for i, v in ipairs(pets) do
    v:ChangeBuffVisibility(false)
  end
end

function BattleB1P1EnterPerformAction:ShowBuffBar()
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for i, v in ipairs(pets) do
    v:ChangeBuffVisibility(true)
  end
end

return BattleB1P1EnterPerformAction

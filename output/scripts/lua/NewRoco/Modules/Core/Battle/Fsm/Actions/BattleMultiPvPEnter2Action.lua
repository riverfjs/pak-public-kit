local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local Base = BattleActionBase
local BattleMultiPvPEnter2Action = Base:Extend("BattleMultiPvPEnter2Action")
FsmUtils.MergeMembers(Base, BattleMultiPvPEnter2Action, {})

function BattleMultiPvPEnter2Action:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleMultiPvPEnter2Action:OnEnter()
  if not BattleManager.battlePawnManager:IsValid() then
    self:Finish()
    return
  end
  local CheckAppearanceMode = self:GetProperty("CheckAppearanceMode", false)
  self.IsShowAppearance = CheckAppearanceMode and BattleUtils.IsTriggerAppearanceInField(CheckAppearanceMode)
  if self.IsShowAppearance then
    self:Finish()
    return
  end
  self:FindActors()
  self:LoadPetSkill()
end

function BattleMultiPvPEnter2Action:FindActors()
  local pets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  self.ballPath = {}
  self.playerPets = pets
  for i, v in ipairs(pets) do
    self.ballPath[#pets - i + 1] = BattleUtils.GetPetBallPath(v.card.petInfo.battle_common_pet_info)
  end
  local enemyPets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  self.enemyBallPath = {}
  self.enemyPets = pets
  for i, v in ipairs(enemyPets) do
    self.enemyBallPath[#enemyPets - i + 1] = BattleUtils.GetPetBallPath(v.card.petInfo.battle_common_pet_info)
  end
end

function BattleMultiPvPEnter2Action:LoadPetSkill()
  Log.Error("BattleMultiPvPEnter2Action LoadPetSkill")
  local MyCastObject = CastSkillObject.Create()
  MyCastObject.ResID = BattleConst.PvPEnter.TwoPlayerPetSkill_C
  MyCastObject:SetDynamicData({
    BallAdditionalPaths = self.ballPath
  })
  MyCastObject:SetCallbackOwner(self)
  MyCastObject:SetSkillBreakCallback(self.OnSkillEnd)
  MyCastObject:SetStartFailedCallback(self.OnSkillEnd)
  local characters = BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  local teamOuterSkillCharacters = {}
  table.copy(characters, teamOuterSkillCharacters)
  if BattleUtils.IsNpcAssist() and BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithPet then
    local posTwoPetIndex = BattleConst.CharacterIndex.Player_Pet1
    local npcAssistBattlePet = BattleManager.battlePawnManager:GetBattlePetByActor(teamOuterSkillCharacters[posTwoPetIndex])
    if npcAssistBattlePet then
      npcAssistBattlePet:ShowPet()
    end
    teamOuterSkillCharacters[posTwoPetIndex] = nil
  end
  MyCastObject:SetCharacters(teamOuterSkillCharacters)
  local pets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  if #pets > 0 then
    for i = 1, #pets do
      BattleUtils.SetParticleKeyForCastSkillObject(pets[i].model, MyCastObject, pets[i].card.medalBlackBoard)
    end
  end
  local myPlayer = BattleManager.battlePawnManager:GetPlayerMyTeam()
  if not myPlayer.model then
    self:OnSkillEnd()
    self:OnSkillEndEnemy()
    return
  end
  self.OuterSkillComponent, self.OuterSkill = BattleSkillManager:PrepareSkill(myPlayer, myPlayer.model.RocoSkill, MyCastObject)
  if not self.OuterSkill then
    self:Finish()
    return
  end
  if #self.ballPath <= 1 then
    self.OuterSkill.PlayerAmountType = 1
  else
    self.OuterSkill.PlayerAmountType = 2
  end
  self.OuterSkill:RegisterEventCallback("PreEnd", self, self.OnSkillEnd)
  local EnemyCastObject = CastSkillObject.Create()
  EnemyCastObject.ResID = BattleConst.PvPEnter.TwoEnemyPetSkill_C
  EnemyCastObject:SetDynamicData({
    BallAdditionalPaths = self.enemyBallPath
  })
  EnemyCastObject:SetCallbackOwner(self)
  EnemyCastObject:SetSkillBreakCallback(self.OnSkillEndEnemy)
  EnemyCastObject:SetStartFailedCallback(self.OnSkillEndEnemy)
  EnemyCastObject:SetCharacters(characters)
  local enemyPets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  if #enemyPets > 0 then
    for i = 1, #enemyPets do
      BattleUtils.SetParticleKeyForCastSkillObject(enemyPets[i].model, EnemyCastObject, enemyPets[i].card.medalBlackBoard)
    end
  end
  local enemyPlayer = BattleManager.battlePawnManager:GetPlayerEnemyTeam()
  if not enemyPlayer.model then
    self:OnSkillEndEnemy()
    return
  end
  self.OuterEnemySkillComponent, self.OuterEnemySkill = BattleSkillManager:PrepareSkill(enemyPlayer, enemyPlayer.model.RocoSkill, EnemyCastObject)
  if #self.enemyBallPath <= 1 then
    self.OuterEnemySkill.PlayerAmountType = 1
  else
    self.OuterEnemySkill.PlayerAmountType = 2
  end
  self.OuterEnemySkill:RegisterEventCallback("HelmetOn", self, self.OnSkillHelmetOnEnemy)
  self.OuterEnemySkill:RegisterEventCallback("PreEnd", self, self.OnSkillEndEnemy)
  self.OuterEnemySkill:RegisterEventCallback("PostStart", self, self.PostStart)
  self.charEnemy = characters
  self.OuterSkillComponent:LoadAndPlaySkill(self.OuterSkill)
  self.OuterEnemySkillComponent:LoadAndPlaySkill(self.OuterEnemySkill)
  Log.Error("BattleMultiPvPEnter2Action:PlaySkill")
end

function BattleMultiPvPEnter2Action:OnSkillEnd(Event, Skill)
  self.Skill1End = true
  if self.Skill2End then
    self:Finish()
  end
end

function BattleMultiPvPEnter2Action:OnSkillHelmetOnEnemy()
  Log.Debug("BattleMultiPvPEnter1Action:OnSkillHelmetOnEnemy")
  if not self.charEnemy then
    return
  end
  for i, v in pairs(self.charEnemy) do
    if v and "nil" ~= v then
      self.charEnemy[i]:TryHelmetOn()
    end
  end
end

function BattleMultiPvPEnter2Action:OnSkillEndEnemy(Event, Skill)
  self.Skill2End = true
  if self.Skill1End then
    self:Finish()
  end
end

function BattleMultiPvPEnter2Action:PostStart()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePvpEntryHud)
  for i, v in ipairs(BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)) do
    if v.player and v.player.model then
      v.player:ShowPlayer()
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(true)
      end
    end
  end
  for i, v in ipairs(BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)) do
    if v.player and v.player.model then
      v.player:ShowPlayer()
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(true)
      end
    end
  end
end

function BattleMultiPvPEnter2Action:OnFinish()
  if self.IsShowAppearance then
    return
  end
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePvpEntryHud)
end

function BattleMultiPvPEnter2Action:OnExit()
  if self.IsShowAppearance then
    return
  end
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePvpEntryHud)
end

return BattleMultiPvPEnter2Action

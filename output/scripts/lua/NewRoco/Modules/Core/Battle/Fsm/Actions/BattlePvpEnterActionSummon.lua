local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattleActionBase
local BattlePvpEnterActionSummon = Base:Extend("BattlePvpEnterActionSummon")
FsmUtils.MergeMembers(Base, BattlePvpEnterActionSummon, {})

function BattlePvpEnterActionSummon:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.PawnManger = _G.BattleManager.battlePawnManager
  self.Skill1End = false
  self.Skill2End = false
  self.loadMySkillEnd = false
  self.loadEnemySkillEnd = false
end

function BattlePvpEnterActionSummon:FindActors()
  self.BattlePet = self.PawnManger:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  self.enemyPet = self.PawnManger:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  self.BattlePlayer = self.PawnManger.TeamatePlayer
  self.WorldPlayer = BattleUtils.GetPlayer()
  self.TraceCache = BattleUtils.GetTraceNpc()
  if self.TraceCache then
    self.WorldPet = self.TraceCache.npc
  else
    self.WorldPet = nil
  end
end

function BattlePvpEnterActionSummon:OnEnter()
  NRCModuleManager:DoCmd(EnvSystemModuleCmd.TogglePause)
  self.enemy = self.PawnManger:GetPlayerEnemyTeam()
  if not self.BattlePlayer.model or not self.enemy.model then
    Log.Error("BattlePvpEnterActionSummon:OnEnter model is nil")
    self:Finish()
    return
  end
  self:FindActors()
  self.PlayerLocRes = self.BattlePlayer.model:Abs_K2_GetActorLocation()
  self.EnemyLocRes = self.enemy.model:Abs_K2_GetActorLocation()
  self.SkillComponent = _G.BattleManager.vBattleField.battleFieldActor.Skill
  self.enemySkillComponent = self.enemy.model.RocoSkill
  self.resList = {
    BattleConst.PveEnter.PlayerSkill1,
    BattleConst.PveEnter.EnemySkill1,
    BattleConst.PveEnter.PlayerSkill2,
    BattleConst.PveEnter.EnemySkill2
  }
  self.loadedResCount = 0
  BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
  _G.BattleSkillManager:PreLoadRes(self.resList, true)
end

function BattlePvpEnterActionSummon:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    Log.Debug("BattleMultiPvPEnterAction:OnBattleEvent:", event, value)
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    if self.loadedResCount == #self.resList then
      self:LoadSkillOver()
    end
    return true
  end
end

function BattlePvpEnterActionSummon:GetSkillClass(resPath)
  if _G.BattleSkillManager:IsResLoaded(resPath) then
    return _G.BattleSkillManager:GetLoadedClass(resPath)
  else
    Log.Error("BattlePvpEnterActionPetShow:GetSkillClass resPath not loaded resPath=", resPath)
    self:Finish()
  end
end

function BattlePvpEnterActionSummon:LoadSkillOver()
  local skillClass = self:GetSkillClass(BattleConst.PveEnter.PlayerSkill1)
  local EnemySkillClass = self:GetSkillClass(BattleConst.PveEnter.EnemySkill1)
  if skillClass and EnemySkillClass then
    self:LoadSkillOver(skillClass)
    self:LoadEnemySkillOver(EnemySkillClass)
  end
end

function BattlePvpEnterActionSummon:LoadSkillOver(skillClass)
  self.loadMySkillEnd = true
  self.Skill = self.SkillComponent:FindOrAddSkillObj(skillClass)
  self.Skill:RegisterEventCallback("Start", self, self.OnSkillStart)
  self.Skill:RegisterEventCallback("End", self, self.OnSkillEnd)
  self.Skill:RegisterEventCallback("PostStart", self, self.OnPostStartPlayer)
  self.Skill:RegisterEventCallback("Interrupt", self, self.OnSkillEnd)
  self.Skill:RegisterEventCallback("StartFailed", self, self.OnSkillEnd)
  self.Skill:SetCaster(self.BattlePlayer.model)
  self.Skill:SetTargets({
    self.BattlePet.model
  })
  self.Skill:SetDynamicData({
    BallPath = BattleUtils.GetPetBallPath(self.BattlePet.card.petInfo.battle_common_pet_info)
  })
  if self.loadEnemySkillEnd then
    self:LoadHud()
  end
end

function BattlePvpEnterActionSummon:LoadEnemySkillOver(skillClass)
  self.enemySkill = self.enemySkillComponent:FindOrAddSkillObj(skillClass)
  self.enemySkill:SetCaster(self.enemy.model)
  self.enemySkill:RegisterEventCallback("Start", self, self.OnSkillStartEnemy)
  self.enemySkill:RegisterEventCallback("End", self, self.OnSkillEndEnemy)
  self.enemySkill:RegisterEventCallback("PostStart", self, self.OnPostStart)
  self.enemySkill:RegisterEventCallback("Interrupt", self, self.OnSkillEndEnemy)
  self.enemySkill:RegisterEventCallback("StartFailed", self, self.OnSkillEndEnemy)
  self.enemySkill:SetTargets({
    self.enemyPet.model
  })
  local enemyBall = BattleUtils.GetPetBallPath(self.BattlePet.card.petInfo.battle_common_pet_info)
  self.enemySkill:SetDynamicData({BallPath = enemyBall})
  if self.loadMySkillEnd then
    self:LoadHud()
  end
end

function BattlePvpEnterActionSummon:LoadHud()
  _G.BattleResourceManager:LoadWidgetAsync(self, "/Game/NewRoco/Modules/Core/Battle/entryHud.entryHud_C", UE4.UGameplayStatics:GetPlayerController(0), function(caller, widget)
    caller.widget = widget
    caller:PlaySkill()
  end, self.Finish)
end

function BattlePvpEnterActionSummon:PlaySkill()
  self.SkillComponent:PlaySkill(self.Skill)
  self.enemySkillComponent:PlaySkill(self.enemySkill)
end

function BattlePvpEnterActionSummon:OnSkillEnd(Event, Skill)
  self.Skill1End = true
  if self.Skill2End then
    self:Finish()
  end
end

function BattlePvpEnterActionSummon:OnSkillStartEnemy(Event, Skill)
end

function BattlePvpEnterActionSummon:OnSkillEndEnemy(Event, Skill)
  self.Skill2End = true
  if self.Skill1End then
    self:Finish()
  end
end

function BattlePvpEnterActionSummon:OnPostStart(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  self:SaveObject(Blackboard, "camActor_Save1")
  self:SaveObject(Blackboard, "camActor_Save1_SA")
  local Mat = Blackboard:GetValueAsObject("MaterialToBe")
  if Mat then
    Log.Debug("Material Retrieved!")
  else
    Log.Debug("No Mat :(")
  end
  self.fsm:SetProperty("resMat", Mat)
  local img = self.widget.ImageFuse
  if img then
    Log.Debug("Image Retrieved!")
  end
  img:SetBrushFromMaterial(Mat, false)
  _G.BattleManager.battlePawnManager:GetPlayerEnemyTeam():ShowPlayer()
  self.widget:AddToViewport()
  local Cache = BattleUtils.GetTraceNpc()
  if Cache and Cache.npc then
    Cache.npc:SetVisibleForBattleReason(false)
  end
  local Mat2 = Blackboard:GetValueAsObject("MaterialDiv")
  if Mat2 then
    Log.Debug("Material Retrieved!")
  else
    Log.Debug("No Mat :(")
  end
  local img2 = self.widget.ImageFuse2
  if img2 then
    Log.Debug("Image Retrieved!")
  end
  img2:SetBrushFromMaterial(Mat2, false)
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
  _G.BattleManager.battlePawnManager.playerTeam.pets[1]:ShowPet()
  _G.BattleManager.battlePawnManager.enemyTeam.pets[1]:ShowPet()
end

function BattlePvpEnterActionSummon:OnPostStartPlayer(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  _G.BattleManager.battlePawnManager:GetPlayerMyTeam():ShowPlayer()
  self:SaveObject(Blackboard, "camActor_Save2")
  self:SaveObject(Blackboard, "camActor_Save2_SA")
  self.fsm:SetProperty("wig", self.widget)
end

function BattlePvpEnterActionSummon:OnDisplayStart()
end

function BattlePvpEnterActionSummon:OnSkillStart(Event, Skill)
end

function BattlePvpEnterActionSummon:OnFinish()
  BattleEventCenter:UnBind(self)
  self.enemySkill = nil
  self.enemySkillComponent = nil
  self.Skill = nil
  self.SkillComponent = nil
  self.BattlePet = nil
  self.BattlePlayer = nil
  self.WorldPet = nil
  self.WorldPlayer = nil
  self.widget = nil
end

function BattlePvpEnterActionSummon:OnExit()
end

function BattlePvpEnterActionSummon:SaveObject(bb, name)
  FsmUtils.SaveAsProperty(self.fsm, bb, name)
end

return BattlePvpEnterActionSummon

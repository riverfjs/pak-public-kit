local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleActionBase
local BattlePvpEnterActionPetShow = Base:Extend("BattlePvpEnterActionPetShow")
FsmUtils.MergeMembers(Base, BattlePvpEnterActionPetShow, {})

function BattlePvpEnterActionPetShow:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.PawnManger = _G.BattleManager.battlePawnManager
  self.Skill1End = false
  self.Skill2End = false
  self.TickCamera = false
  self.TickCameraEnemy = false
  self.time = 0
  self.timeRemain = 0
  self.Kam2Vec = UE4.FVector()
  self.Kam1Vec = UE4.FVector()
end

function BattlePvpEnterActionPetShow:OnTick(DeltaTime)
  if self.TickCamera and self.TickCameraEnemy then
    self.time = self.time + DeltaTime * 1.5
    local alpha = self.time / self.timeRemain
    if alpha >= 1 then
      alpha = 1
    end
    local CamVec = _G.BattleManager.vBattleField:GetPCGCamTransform()
    local FOVDiff = _G.BattleManager.vBattleField.battleCameraManager.FOV - 50
    self.Kam1Vec = self.Kamera1Bone.SkeletalMeshComponent:GetSocketTransform("cam_01")
    self.Kam2Vec = self.Kamera2Bone.SkeletalMeshComponent:GetSocketTransform("cam_01")
    self.Kamera1:Abs_K2_SetActorTransform_WithoutHit(UE4.UKismetMathLibrary.TLerp(self.Kam1Vec, CamVec, alpha))
    self.Kamera1:GetComponentByClass(UE4.UCameraComponent).FieldOfView = 50 + FOVDiff * alpha
    self.Kamera2:Abs_K2_SetActorTransform_WithoutHit(UE4.UKismetMathLibrary.TLerp(self.Kam2Vec, CamVec, alpha))
    if self.Kamera2:GetComponentByClass(UE4.USceneCaptureComponent2D) then
      self.Kamera2:GetComponentByClass(UE4.USceneCaptureComponent2D).FOVAngle = 50 + FOVDiff * alpha
    end
  end
end

function BattlePvpEnterActionPetShow:FindActors()
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

function BattlePvpEnterActionPetShow:OnEnter()
  self.widget = self.fsm:GetProperty("wig", nil)
  local img = self.widget.ImageFuse
  img:SetBrushFromMaterial(self.fsm:GetProperty("resMat", nil))
  self.enemy = self.PawnManger:GetPlayerEnemyTeam()
  self:FindActors()
  self.SkillComponent = _G.BattleManager.vBattleField.battleFieldActor.Skill
  self.enemySkillComponent = self.enemy.model.RocoSkill
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0, nil, nil, true)
  self:LoadSkillOver()
end

function BattlePvpEnterActionPetShow:GetSkillClass(resPath)
  if _G.BattleSkillManager:IsResLoaded(resPath) then
    return _G.BattleSkillManager:GetLoadedClass(resPath)
  else
    Log.Error("BattlePvpEnterActionPetShow:GetSkillClass resPath not loaded resPath=", resPath)
    self:Finish()
  end
end

function BattlePvpEnterActionPetShow:LoadSkillOver()
  local skillClass = self:GetSkillClass(BattleConst.PveEnter.PlayerSkill2)
  local EnemySkillClass = self:GetSkillClass(BattleConst.PveEnter.EnemySkill2)
  if skillClass and EnemySkillClass then
    self:MySkillLoadOver(skillClass)
    self:EnemySkillLoadOver(EnemySkillClass)
  end
end

function BattlePvpEnterActionPetShow:MySkillLoadOver(skillClass)
  self.Skill = self.SkillComponent:FindOrAddSkillObj(skillClass)
  self.Skill:RegisterEventCallback("Start", self, self.OnSkillStart)
  self.Skill:RegisterEventCallback("End", self, self.OnSkillEnd)
  self.Skill:RegisterEventCallback("Unbind", self, self.OnUnbind)
  self.Skill:RegisterEventCallback("Interrupt", self, self.OnSkillEnd)
  self.Skill:RegisterEventCallback("StartFailed", self, self.OnSkillEnd)
  self.Skill:SetCaster(self.BattlePlayer.model)
  self.Skill:SetTargets({
    self.BattlePet.model
  })
  self.Skill:SetDynamicData({
    BallPath = BattleUtils.GetPetBallPath(self.BattlePet.card.petInfo.battle_common_pet_info)
  })
  self.SkillComponent:PlaySkill(self.Skill)
end

function BattlePvpEnterActionPetShow:EnemySkillLoadOver(skillClass)
  self.enemySkill = self.enemySkillComponent:FindOrAddSkillObj(skillClass)
  self.enemySkill:SetCaster(self.enemy.model)
  self.enemySkill:RegisterEventCallback("Start", self, self.OnSkillStartEnemy)
  self.enemySkill:RegisterEventCallback("End", self, self.OnSkillEndEnemy)
  self.enemySkill:RegisterEventCallback("PostStart", self, self.OnPostStart)
  self.enemySkill:RegisterEventCallback("Unbind", self, self.OnUnbindEnemy)
  self.enemySkill:RegisterEventCallback("Interrupt", self, self.OnSkillEndEnemy)
  self.enemySkill:RegisterEventCallback("StartFailed", self, self.OnSkillEndEnemy)
  self.enemySkill:SetTargets({
    self.enemyPet.model
  })
  local enemyBall = BattleUtils.GetPetBallPath(self.BattlePet.card.petInfo.battle_common_pet_info)
  self.enemySkill:SetDynamicData({BallPath = enemyBall})
  self.enemySkillComponent:PlaySkill(self.enemySkill)
end

function BattlePvpEnterActionPetShow:OnSkillEnd(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  self.Skill1End = true
  if self.Skill2End then
    self:Finish()
  end
end

function BattlePvpEnterActionPetShow:OnSkillStartEnemy(Event, Skill)
end

function BattlePvpEnterActionPetShow:OnUnbind(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  self.timeRemain = Skill:GetLength() - Skill:GetCurrentTime()
  self.Kamera1 = Blackboard:GetValueAsObject("camActor_0002")
  self.Kamera1Bone = Blackboard:GetValueAsObject("camActor_0002_SA")
  self:SaveObject(Blackboard, "camActor_0002")
  self:SaveObject(Blackboard, "camActor_0002_SA")
  self.TickCamera = true
end

function BattlePvpEnterActionPetShow:OnUnbindEnemy(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  self.Kamera2 = Blackboard:GetValueAsObject("camActor_0001")
  self.Kamera2Bone = Blackboard:GetValueAsObject("camActor_0001_SA")
  self.TickCameraEnemy = true
end

function BattlePvpEnterActionPetShow:OnSkillEndEnemy(Event, Skill)
  self.Skill2End = true
  if self.Skill1End then
    self:Finish()
  end
end

function BattlePvpEnterActionPetShow:OnPostStart(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  local Mat = Blackboard:GetValueAsObject("MaterialToBe")
  if Mat then
    Log.Debug("Material Retrieved!")
  else
    Log.Debug("No Mat :(")
  end
  self:DestroyProperty("camActor_Save1")
  self:DestroyProperty("camActor_Save1_SA")
  self:DestroyProperty("camActor_Save2")
  self:DestroyProperty("camActor_Save2_SA")
  local img = self.widget.ImageFuse
  if img then
    Log.Debug("Image Retrieved!")
  end
  img:SetBrushFromMaterial(Mat, false)
  local Mat2 = Blackboard:GetValueAsObject("MaterialDiv")
  if Mat2 then
    Log.Debug("Material Retrieved!")
  else
    Log.Debug("No Mat :(")
  end
  local time = (_G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.GetCurrentTime) or 0) / 3600
  Mat2:SetScalarParameterValue("Gamma", time)
  local img2 = self.widget.ImageFuse2
  if img2 then
    Log.Debug("Image Retrieved!")
  end
  img2:SetBrushFromMaterial(Mat2, false)
  img2:SetOpacity(0)
end

function BattlePvpEnterActionPetShow:OnSkillStart(Event, Skill)
end

function BattlePvpEnterActionPetShow:OnFinish()
  self.Skill = nil
  self.enemySkill = nil
  self.enemySkillComponent = nil
  self.SkillComponent = nil
  self.enemySkill = nil
  self.BattlePet = nil
  self.BattlePlayer = nil
  self.WorldPet = nil
  self.WorldPlayer = nil
  self.fsm:SetProperty("wig", nil)
  self.fsm:SetProperty("resMat", nil)
  self.widget:RemoveFromViewport()
  self.widget:Destruct()
  self.Kamera2:K2_DestroyActor()
  self.Kamera1 = nil
  self.Kamera2 = nil
  self.Kamera1Bone = nil
  self.Kamera2Bone = nil
  self.TickCamera = false
  self.TickCameraEnemy = false
  NRCModuleManager:DoCmd(EnvSystemModuleCmd.TogglePause)
end

function BattlePvpEnterActionPetShow:SaveObject(bb, name)
  FsmUtils.SaveAsProperty(self.fsm, bb, name)
end

function BattlePvpEnterActionPetShow:DestroyProperty(name)
  FsmUtils.ClearProperty(self.fsm, name)
end

function BattlePvpEnterActionPetShow:OnExit()
end

return BattlePvpEnterActionPetShow

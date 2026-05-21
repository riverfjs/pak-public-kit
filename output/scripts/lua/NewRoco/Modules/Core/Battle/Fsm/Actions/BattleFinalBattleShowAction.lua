local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleFinalBattleShowAction = BattleActionBase:Extend("BattleLeaderBattleShowTime")
local WaitMaxTime = 5

function BattleFinalBattleShowAction:OnEnter()
  if not BattleUtils.IsFinalBattleP1() then
    self:Finish()
    return
  end
  self:SetActionType(BattleActionBase.ActionType.ClientTurnPlayAction)
  self.Caster = BattleManager.battlePawnManager.TeamatePlayer
  self.Target = BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
  self.skillResList = {
    BattleConst.FinalBattleP1EnterG6
  }
  self.WaitShieldTime = 0
  self.loadedSkillResCount = 0
  _G.BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
  _G.BattleSkillManager:PreLoadRes(self.skillResList, true)
end

function BattleFinalBattleShowAction:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.skillResList do
      if value == self.skillResList[i] then
        self.loadedSkillResCount = self.loadedSkillResCount + 1
      end
    end
    if self.loadedSkillResCount == #self.skillResList then
      self:CheckCanPlay()
    end
  end
end

function BattleFinalBattleShowAction:CheckCanPlay()
  if not self.finished then
    if self.Target and not self.Target.buffComponent:CheckStateIsPlaying(Enum.BuffGroupSign.BGS_PERSISTENT_SHIELD) and self.WaitShieldTime <= WaitMaxTime then
      self.WaitShieldTime = self.WaitShieldTime + 0.3
      self:SafeDelaySeconds("d_CheckCanPlay", 0.3, self.CheckCanPlay, self)
    end
    self:PlaySkill()
  end
end

function BattleFinalBattleShowAction:PlaySkill()
  if not self.Caster or not self.Caster.model then
    self:Finish()
    return
  end
  local skillComponent = self.Caster.model.RocoSkill
  if not skillComponent then
    self:Finish()
    return
  end
  local skillPath = self.skillResList[1]
  local skillClass = BattleSkillManager:GetLoadedClass(skillPath)
  if not skillClass then
    Log.ErrorFormat("Failed to load skill class %s", skillPath)
    self:Finish()
    return
  end
  local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if not skillObj then
    self:Finish()
    return
  end
  self.IsChangeCameraOver = false
  self.IsSkillOver = false
  skillObj:SetCaster(self.Target.model)
  skillObj:SetTargets({
    self.Target.model
  })
  skillObj:SetCharacters(_G.BattleManager.battlePawnManager:GetAllPawnActorForSkill())
  skillObj:SetPassive(true)
  skillObj:RegisterEventCallback("Start", self, self.CloseLoading)
  skillObj:RegisterEventCallback("ChangeCamera", self, self.OnChangeCamera)
  skillObj:RegisterEventCallback("End", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("Interrupt", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("StartFailed", self, self.OnSkillComplete)
  skillComponent:PlaySkill(skillObj)
end

function BattleFinalBattleShowAction:OnChangeCamera(Event, Skill)
  local BattleState = "Battle;Battle;Battle_Type;A1EndWar;Battle_Stage;Stage_1"
  _G.NRCAudioManager:BatchSetState(BattleState)
  local Conf = _G.DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_prologue_target_camera")
  local camTransform
  if Conf then
    camTransform = UE4.UKismetMathLibrary.MakeTransform(UE.FVector(Conf.numList[1], Conf.numList[2], Conf.numList[3]), UE.FRotator(Conf.numList[5], Conf.numList[6], Conf.numList[4]), UE4.FVector(1, 1, 1))
  else
    camTransform = UE4.UKismetMathLibrary.MakeTransform(UE.FVector(-6274.456543, 2343.78076, 427.529419), UE.FRotator(0.2, -91.847, -0.8), UE4.FVector(1, 1, 1))
  end
  local camera = self:SpawnKamera(80, false, camTransform)
  camera:Abs_K2_SetActorTransform_WithoutHit(camTransform, false, false)
  self.fsm:SetProperty("FinalBattleSkipCamera", _G.ObjectRefBoxing(camera))
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerController = localPlayer:GetUEController()
  playerController:SetViewTargetWithBlend(camera, 1, UE4.EViewTargetBlendFunction.VTBlend_Linear, 2)
  self:SafeDelaySeconds("d_TryFinish", 1.2, function()
    self.IsChangeCameraOver = true
    self:TryFinish()
  end)
end

function BattleFinalBattleShowAction:SpawnKamera(fov, Constrain, transForm)
  local Camera = UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ACameraActor, transForm or UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  local CameraComp = Camera:GetComponentByClass(UE4.UCameraComponent)
  CameraComp.FieldOfView = fov
  CameraComp.bConstrainAspectRatio = Constrain
  return Camera
end

function BattleFinalBattleShowAction:OnSkillStart()
  self:SafeDelayFrames("d_CloseLoading", 2, function()
    self:CloseLoading()
  end)
end

function BattleFinalBattleShowAction:CloseLoading()
  if BattleManager.CacheSequencer then
    BattleManager.CacheSequencer:Stop()
    BattleManager.CacheSequencer = nil
  end
end

function BattleFinalBattleShowAction:OnSkillComplete()
  Log.Debug("BattleFinalBattleShowAction:OnSkillComponent")
  self.IsSkillOver = true
  self:TryFinish()
end

function BattleFinalBattleShowAction:TryFinish()
  if self.IsSkillOver and self.IsChangeCameraOver then
    self:Finish()
  end
end

function BattleFinalBattleShowAction:OnFinish()
  if not self.Target or self.Target.card.petState:GetPersistentShield() then
  end
  self.Caster = nil
  self.Target = nil
  self:CloseLoading()
  _G.BattleEventCenter:UnBind(self)
end

return BattleFinalBattleShowAction

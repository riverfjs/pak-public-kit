local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BattleWorldLeaderShowAction = BattleActionBase:Extend("BattleLeaderBattleShowTime")

function BattleWorldLeaderShowAction:OnEnter()
  if not BattleUtils.IsWorldLeaderFight() then
    self:Finish()
    return
  end
  self.HitSkill = BattleManager.battleRuntimeData:GetWorldLeaderShowSkill()
  if self.HitSkill then
    self.skillResList = {
      BattleConst.Define.LeaderBattleEnterShow1
    }
  else
    self.skillResList = {
      BattleConst.Define.LeaderHitShow,
      BattleConst.Define.LeaderBattleEnterShow1
    }
  end
  self.loadedSkillResCount = 0
  _G.BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
  _G.BattleSkillManager:PreLoadRes(self.skillResList, true)
end

function BattleWorldLeaderShowAction:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.skillResList do
      if value == self.skillResList[i] then
        self.loadedSkillResCount = self.loadedSkillResCount + 1
      end
    end
    if self.loadedSkillResCount == #self.skillResList then
      _G.BattleEventCenter:UnBind(self)
      if self.HitSkill then
        self:PlaySkill()
      else
        self:PlayHitSkill()
      end
    end
    return true
  end
end

function BattleWorldLeaderShowAction:PlayHitSkill()
  local caster = BattleUtils.GetTraceNpc()
  if not caster or not UE.UObject.IsValid(caster.npc.viewObj) then
    Log.Error("zgx Target is nil!!!!")
    self:PlaySkill()
    return
  end
  local model = caster.npc.viewObj
  local skillComponent = model.RocoSkill
  if not skillComponent then
    self:PlaySkill()
    return
  end
  local skillPath = BattleConst.Define.LeaderHitShow
  local skillClass = BattleSkillManager:GetLoadedClass(skillPath)
  if not skillClass then
    Log.ErrorFormat("Failed to load skill class %s", skillPath)
    self:PlaySkill()
    return
  end
  local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if not skillObj then
    self:PlaySkill()
    return
  end
  self.HitSkill = skillObj
  skillObj:SetCaster(model)
  skillObj:SetTargets({model})
  skillObj:SetPassive(true)
  skillObj:RegisterEventCallback("PreStart", self, self.HitSkillStart)
  skillObj:RegisterEventCallback("End", self, self.HitSkillOver)
  skillObj:RegisterEventCallback("PreEnd", self, self.HitSkillOver)
  skillObj:RegisterEventCallback("Interrupt", self, self.HitSkillOver)
  skillObj:RegisterEventCallback("StartFailed", self, self.HitSkillOver)
  skillComponent:PlaySkill(skillObj)
end

function BattleWorldLeaderShowAction:HitSkillStart(Name, skillObject)
  UE4.RocoSkillUtils.SetBranchJumpFrames(skillObject, "RemoveWorldLeaderShow", 0)
end

function BattleWorldLeaderShowAction:HitSkillOver()
  if self.HitSkill then
    self.HitSkill = nil
    self:PlaySkill()
  end
end

function BattleWorldLeaderShowAction:PlaySkill()
  local BattleManager = _G.BattleManager
  local battleStartParam = BattleManager.battleRuntimeData.battleStartParam
  if not battleStartParam then
    self:Finish()
    return
  end
  local target = BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
  if not target or not target.model then
    self:Finish()
    return
  end
  local skillComponent = target.model.RocoSkill
  if not skillComponent then
    self:Finish()
    return
  end
  local skillPath = BattleConst.Define.LeaderBattleEnterShow1
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
  BattleManager.battlePawnManager:TogglePetBuffsVisibility(false)
  local caster = BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_TEAM)
  if not caster or not caster.model then
    self:Finish()
    return
  end
  skillObj:SetCaster(caster.model)
  skillObj:SetTargets({
    target.model
  })
  skillObj:SetPassive(true)
  skillObj:SetCharacters(_G.BattleManager.battlePawnManager:GetAllPawnActorForSkill())
  skillObj:RegisterEventCallback("ActionStart", self, self.OnActionStart)
  skillObj:RegisterEventCallback("End", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("Interrupt", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("StartFailed", self, self.OnSkillComplete)
  local pets = BattleManager.battlePawnManager:GetTeamAllPets()
  if #pets <= 1 then
    skillObj.PlayerAmountType = UE4.EBattlePlayerAmount.Singleplayer
  else
    skillObj.PlayerAmountType = UE4.EBattlePlayerAmount.Multiplayer2V2
  end
  self:CustomCastG6BeforePlay(caster, skillObj)
  self.skillObj = skillObj
  local result = skillComponent:PlaySkill(skillObj)
  if result ~= UE4.ESkillStartResult.Success then
    self:OnSkillComplete()
  end
end

function BattleWorldLeaderShowAction:CustomCastG6BeforePlay(caster, skill_obj)
  if caster and caster.model and caster.card then
    BattleUtils.SetParticleKeyForSkillObj(caster.model, skill_obj, caster.card.medalBlackBoard)
  end
end

function BattleWorldLeaderShowAction:OnActionStart()
  BattleManager.battleRuntimeData:StopWorldLeaderShowSkill()
  self:HideScenePet()
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPet(0, nil, nil, true, false)
  local worldRelativeTransform, worldCameraFov = BattleManager.battleRuntimeData:GetWorldLeaderShowInfo()
  local target = BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
  target:ShowPet(false)
  local bossTransform = target.model:GetTransform()
  bossTransform.Scale3D = FVectorOne
  local startTransform = UE.UKismetMathLibrary.ComposeTransforms(worldRelativeTransform, bossTransform)
  local blackboard = self.skillObj:GetBlackboard()
  if blackboard then
    local endTransform = _G.BattleManager.vBattleField:GetPCGCamTransform()
    local hitResult = LineTraceUtils.HitWorldStaticMesh(SceneUtils.ConvertRelativeToAbsolute(startTransform.Translation), SceneUtils.ConvertRelativeToAbsolute(endTransform.Translation), {
      target.model
    })
    if hitResult then
      blackboard:SetValueAsTransform("StartTransform", endTransform)
    else
      blackboard:SetValueAsTransform("StartTransform", startTransform)
    end
    blackboard:SetValueAsTransform("EndTransform", endTransform)
    blackboard:SetValueAsFloat("StartFov", worldCameraFov)
    blackboard:SetValueAsFloat("EndFOV", _G.BattleManager.vBattleField:GetPCGCamFieldOfView())
    Log.Warning("BattleWorldLeaderShowAction ", startTransform, endTransform)
    Log.Warning("BattleWorldLeaderShowAction ", worldCameraFov, _G.BattleManager.vBattleField:GetPCGCamFieldOfView())
  end
end

function BattleWorldLeaderShowAction:HideScenePet()
  local Caches = BattleUtils.GetAllTraceNpc()
  if Caches then
    for _, Cache in ipairs(Caches) do
      if Cache and Cache.npc then
        if Cache.npc.AIComponent then
          Cache.npc.AIComponent:LockForBattleReason()
        end
        Cache.npc:SetVisibleForBattleReason(false)
      end
    end
  end
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_LOCAL_PLAYER, true)
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_OTHER_PLAYER, true)
  BattleUtils.SetPlayerSkmTickable(false)
  NRCModeManager:DoCmd(NPCModuleCmd.EnterBattle, BattleManager.battleRuntimeData.NearbyValidBattleLocation, BattleConst.Define.BattleFieldRange)
  BattleUtils.PinOnTheGroundForAllPawn()
end

function BattleWorldLeaderShowAction:OnSkillComplete()
  _G.BattleManager.battlePawnManager:TogglePetBuffsVisibility(true)
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPet(0)
  self.skillObj = nil
  self:Finish()
end

function BattleWorldLeaderShowAction:OnFinish()
  _G.BattleEventCenter:UnBind(self)
end

return BattleWorldLeaderShowAction

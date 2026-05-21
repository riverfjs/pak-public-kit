local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local PlayerTeamShowAction = BattleActionBase:Extend("PlayerTeamShowAction")
PlayerTeamShowAction.ShowSkillType = {
  NpcAssist = 1,
  ZhaoHuang = 2,
  SkipSkill = 3
}

function PlayerTeamShowAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
end

function PlayerTeamShowAction:GetTarget()
  self.targetPets = self.PawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM) or {}
  for i = #self.targetPets, 1 do
    if self.targetPets[i] and self.targetPets[i].player ~= self.PawnManager.TeamatePlayer then
      table.remove(self.targetPets, i)
    end
  end
  self.targetModels = {}
  for i, v in ipairs(self.targetPets) do
    self.targetModels[i] = v.model
  end
end

function PlayerTeamShowAction:LoadBallPath()
  local ballAddPath = {}
  self.ballAddPathNum = 0
  for i = 1, #self.targetPets do
    self.ballAddPathNum = self.ballAddPathNum + 1
    ballAddPath[i] = BattleUtils.GetPetBallPath(self.targetPets[i].card.petInfo.battle_common_pet_info)
  end
  self.playerBallActors = {}
  self.playerBallCount = 0
  for index, Path in pairs(ballAddPath) do
    NRCResourceManager:LoadResAsync(self, Path, 255, -1, function(caller, resRequest, modelClass)
      self:LoadPlayerBallPathOver(resRequest, modelClass, index)
    end, function(caller, resRequest, errMsg)
      Log.Error("UMG_BattleShowImage_C LoadResAsync failed teamClassPath1=", path, errMsg)
    end)
  end
end

function PlayerTeamShowAction:LoadPlayerBallPathOver(resRequest, modelClass, Index)
  local Transform = UE4.FTransform(UE4.FQuat(), UE.FVector(0, 0, 0))
  local World = UE4Helper.GetCurrentWorld()
  local ballActor = World:SpawnActor(modelClass, Transform)
  ballActor:InitOutSceneAsync(nil, function(actor)
    self:SaveBallActor(actor, Index)
  end)
end

function PlayerTeamShowAction:SaveBallActor(actor, Index)
  if not self.playerBallActors then
    self.playerBallActors = {}
  end
  if not self.playerBallCount then
    self.playerBallCount = 0
  end
  self.playerBallActors[Index] = actor
  self.playerBallCount = self.playerBallCount + 1
  self:CheckAllActorsLoaded()
end

function PlayerTeamShowAction:CheckAllActorsLoaded()
  if self.loadedSkill and self.playerBallCount == self.ballAddPathNum then
    self:LoadedAllActors()
  end
end

function PlayerTeamShowAction:LoadedAllActors()
  BattleUtils.CloseBattleAndTaskBlackLoading()
  if self.skillType == PlayerTeamShowAction.ShowSkillType.NpcAssist then
    self:OnNpcAssistSkillLoaded(nil, self.skillClass)
  elseif self.skillType == PlayerTeamShowAction.ShowSkillType.ZhaoHuang then
    self:OnSkillLoad(nil, self.skillClass)
  elseif self.skillType == PlayerTeamShowAction.ShowSkillType.SkipSkill then
    self:OnSkipSkillLoad(nil, self.skillClass)
  end
end

function PlayerTeamShowAction:ChangeCameraToSkill()
  _G.BattleManager.TransBattleCamera(UE.ESkillBattleTransCamera.SkillPlayer, 0.5, UE4.EViewTargetBlendFunction.VTBlend_Linear)
end

function PlayerTeamShowAction:OnSkillStart()
  self.skillStartHideObjectDelay = _G.DelayManager:DelayFrames(2, self.HideSceneObjectsAndShowBattleObjects, self)
end

function PlayerTeamShowAction:OnEnter()
  local CheckAppearanceMode = self:GetProperty("CheckAppearanceMode", false)
  if CheckAppearanceMode and BattleUtils.IsTriggerAppearanceInField(CheckAppearanceMode) then
    self:Finish()
    return
  end
  if BattleUtils.IsFriendAssist() then
    if BattleUtils.IsWorldLeaderFight() or BattleUtils.IsLeaderFight() then
      _G.BattleManager.TransBattleCamera(UE.ESkillBattleTransCamera.SkillPlayer, 0.5, UE4.EViewTargetBlendFunction.VTBlend_Linear)
    end
    self:Finish()
    return
  end
  local contactType = _G.BattleManager.battleRuntimeData:GetContactEnterType()
  local isShow = true
  if contactType == BattleEnum.ContactEnterType.PetHit then
    isShow = 0 == _G.DataConfigManager:GetBattleGlobalConfig("npc_hit_skip_throw_ball").num
  elseif contactType == BattleEnum.ContactEnterType.PlayerHit then
    isShow = 0 == _G.DataConfigManager:GetBattleGlobalConfig("player_hit_skip_throw_ball").num
  elseif contactType == BattleEnum.ContactEnterType.HitTogether then
    isShow = 0 == _G.DataConfigManager:GetBattleGlobalConfig("each_hit_skip_throw_ball").num
  end
  if BattleUtils.IsWorldLeaderFight() then
    isShow = false
  end
  if BattleManager.EnterBattleStateBit ~= BattleEnum.EnterBattleState.Default then
    isShow = false
  end
  if isShow then
    self:GetTarget()
    self:LoadBallPath()
    self.loadedSkill = false
    if BattleUtils.IsNpcAssist() and BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithNpc then
      local skillPath = BattleConst.NpcAssistZhaoHuan
      _G.NRCResourceManager:LoadResAsync(self, skillPath, -1, 10, function(caller, resRequest, modelClass)
        self:OnAllSkillLoaded(resRequest, modelClass, PlayerTeamShowAction.ShowSkillType.NpcAssist)
      end, self.OnSkillFinish)
    else
      local skillPath = BattleConst.ZhaoHuan
      _G.NRCResourceManager:LoadResAsync(self, skillPath, -1, 10, function(caller, resRequest, modelClass)
        self:OnAllSkillLoaded(resRequest, modelClass, PlayerTeamShowAction.ShowSkillType.ZhaoHuang)
      end, self.OnSkillFinish)
    end
  else
    local enemyPet = _G.BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
    if enemyPet then
      local skillPath = BattleConst.Define.ThrowFrontEnterSecond
      if BattleUtils.IsWorldLeaderFight() then
        skillPath = BattleConst.Define.ThrowFrontEnterThree
      end
      if enemyPet.card.petState:GetBackStab() then
        if BattleUtils.IsWorldLeaderFight() then
          skillPath = BattleConst.Define.ThrowBackEnterThree
        else
          skillPath = BattleConst.Define.ThrowBackEnterSecond
        end
      end
      self.targetPets = {enemyPet}
      self.targetModels = {
        enemyPet.model
      }
      self:LoadBallPath()
      skillPath = NRCUtils.FormatBlueprintAssetPath(skillPath)
      _G.NRCResourceManager:LoadResAsync(self, skillPath, -1, 10, function(caller, resRequest, modelClass)
        self:OnAllSkillLoaded(resRequest, modelClass, PlayerTeamShowAction.ShowSkillType.SkipSkill)
      end, self.OnSkillFinish)
    else
      self:OnSkillFinish()
    end
  end
end

function PlayerTeamShowAction:OnFinish()
  BattleUtils.CloseBattleAndTaskBlackLoading()
end

function PlayerTeamShowAction:ShowPawnActor(teamEnum)
  for i, v in ipairs(_G.BattleManager.battlePawnManager:GetAllTeam(teamEnum)) do
    if v.player and v.player.model then
      v.player:ShowPlayer()
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(true)
      end
      v.player.model:TryHelmetOn()
      if v.player.battlePlayerComponents and v.player.battlePlayerComponents.HideMark then
        v.player.battlePlayerComponents:HideMark()
      end
    end
    if #v.pets > 0 then
      for _, p in pairs(v.pets) do
        if p.model and p.card:IsExistAtField() then
          p:ShowPet()
        end
      end
    end
  end
end

function PlayerTeamShowAction:OnSkipSkillLoad(request, skillClass)
  if skillClass then
    local pet = _G.BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
    if pet and pet.model and pet.model.RocoSkill then
      local Skill = pet.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
      local characters = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
      local ballPath = BattleUtils.GetPetBallPath(pet.card.petInfo.battle_common_pet_info)
      BattleUtils.SetParticleKeyForSkillObj(pet.model, Skill, pet.card.medalBlackBoard)
      for _, model in ipairs(self.targetModels) do
        local targetPet = BattleManager.battlePawnManager:GetBattlePetByActor(model)
        if targetPet then
          BattleUtils.SetParticleKeyForSkillObj(model, Skill, targetPet.card.medalBlackBoard)
        end
      end
      local Blackboard = Skill:GetBlackboard()
      for index, path in pairs(self.playerBallActors) do
        if self.playerBallActors and self.playerBallActors[index] then
          Blackboard:SetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", index - 1), self.playerBallActors[index])
        end
      end
      Skill:SetDynamicData({BallPath = ballPath})
      Skill:SetCaster(pet.model)
      Skill:SetTargets(self.targetModels)
      Skill:SetCharacters(characters)
      Skill:RegisterEventCallback("ChangeCameraToSkill", self, self.ChangeCameraToSkill)
      Skill:RegisterEventCallback("Start", self, self.OnSkillStart)
      Skill:RegisterEventCallback("End", self, self.OnSkillFinish)
      Skill:RegisterEventCallback("PreEnd", self, self.OnSkillFinish)
      pet.model.RocoSkill:LoadAndPlaySkill(Skill)
      _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ShowHPBars)
    else
      Log.Error("PlayerTeamShowAction OnSkipSkillLoad pet or model is nil:\229\143\175\232\131\189\230\152\175\228\184\128\229\156\186\233\157\158\230\179\149\230\136\152\230\150\151\230\149\176\230\141\174")
      self:OnSkillFinish()
    end
  else
    Log.Error("PlayerTeamShowAction OnSkipSkillLoad skillClass is nil:\229\143\175\232\131\189\230\152\175\228\184\128\229\156\186\233\157\158\230\179\149\230\136\152\230\150\151\230\149\176\230\141\174")
    self:OnSkillFinish()
  end
end

function PlayerTeamShowAction:OnSkillLoad(request, skillClass)
  if skillClass and self.PawnManager then
    local Player = self.PawnManager.TeamatePlayer
    if Player and Player.model then
      local Skill = Player.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
      if Skill then
        local characters = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
        local ballPath = "None"
        if self.targetPets and #self.targetPets >= 1 then
          ballPath = BattleUtils.GetPetBallPath(self.targetPets[1].card.petInfo.battle_common_pet_info)
        end
        local ballAddPath = {"None", "None"}
        for i = 2, #self.targetPets do
          ballAddPath[i - 1] = BattleUtils.GetPetBallPath(self.targetPets[i].card.petInfo.battle_common_pet_info)
        end
        if 1 == #self.targetPets then
          Skill.PlayerAmountType = 1
          if characters[4] == self.targetPets[1].model then
            characters[5] = nil
          else
            characters[4] = nil
          end
        else
          Skill.PlayerAmountType = 2
        end
        for _, model in ipairs(self.targetModels) do
          local pet = BattleManager.battlePawnManager:GetBattlePetByActor(model)
          if pet then
            BattleUtils.SetParticleKeyForSkillObj(model, Skill, pet.card.medalBlackBoard)
          end
        end
        local Blackboard = Skill:GetBlackboard()
        for index, path in pairs(self.playerBallActors) do
          if self.playerBallActors and self.playerBallActors[index] then
            Blackboard:SetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", index - 1), self.playerBallActors[index])
          end
        end
        Skill:SetDynamicData({BallPath = ballPath, BallAdditionalPaths = ballAddPath})
        Skill:SetCaster(Player.model)
        Skill:SetTargets(self.targetModels)
        Skill:SetCharacters(characters)
        Skill:RegisterEventCallback("Start", self, self.OnSkillStart)
        Skill:RegisterEventCallback("AdjustCamera", self, self.AdjustCamera)
        Skill:RegisterEventCallback("End", self, self.OnSkillFinish)
        Skill:RegisterEventCallback("PreEnd", self, self.OnSkillFinish)
        Player:PlaySkillObject(Skill)
        return
      end
    end
  end
  self:OnSkillFinish()
end

function PlayerTeamShowAction:OnAllSkillLoaded(request, skillClass, type)
  self.loadedSkill = true
  self.skillClass = skillClass
  self.skillType = type
  self:CheckAllActorsLoaded()
end

function PlayerTeamShowAction:OnNpcAssistSkillLoaded(request, skillClass)
  local battlePlayer = self.PawnManager.TeamatePlayer
  if not battlePlayer or not battlePlayer.model then
    self:OnSkillFinish()
    return
  end
  local skillObj = battlePlayer.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
  if not skillClass or not skillObj then
    self:OnSkillFinish()
    return
  end
  local characters = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  local ballPath = BattleUtils.GetPetBallPath(self.targetPets[1].card.petInfo.battle_common_pet_info)
  local ballAddPath = {"None", "None"}
  for i = 2, #self.targetPets do
    ballAddPath[i - 1] = BattleUtils.GetPetBallPath(self.targetPets[i].card.petInfo.battle_common_pet_info)
  end
  local Blackboard = skillObj:GetBlackboard()
  for index, path in pairs(self.playerBallActors) do
    if self.playerBallActors and self.playerBallActors[index] then
      Blackboard:SetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", index - 1), self.playerBallActors[index])
    end
  end
  skillObj.PlayerAmountType = 2
  local teamPets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM) or {}
  for _, pet in ipairs(teamPets) do
    BattleUtils.SetParticleKeyForSkillObj(pet.model, skillObj, pet.card.medalBlackBoard)
  end
  skillObj:SetDynamicData({BallPath = ballPath, BallAdditionalPaths = ballAddPath})
  skillObj:SetCaster(characters[1])
  skillObj:SetTargets(self.targetModels)
  skillObj:SetCharacters(characters)
  skillObj:RegisterEventCallback("Start", self, self.OnSkillStart)
  skillObj:RegisterEventCallback("AdjustCamera", self, self.AdjustCamera)
  skillObj:RegisterEventCallback("End", self, self.OnSkillFinish)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillFinish)
  battlePlayer:PlaySkillObject(skillObj)
end

function PlayerTeamShowAction:AdjustCamera(Event, skill)
  local Blackboard
  if skill then
    Blackboard = skill:GetBlackboard()
  else
    return
  end
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ShowHPBars)
  if Blackboard then
    self:SaveObject(Blackboard, BattleConst.PlayerShow.Cam)
    self:SaveObject(Blackboard, BattleConst.PlayerShow.Cam_SA)
  end
end

function PlayerTeamShowAction:HideSceneObjectsAndShowBattleObjects()
  if self.hasHideSceneObjectsAndShowBattleObjects then
    return
  end
  self.hasHideSceneObjectsAndShowBattleObjects = true
  self:ShowPawnActor(BattleEnum.Team.ENUM_TEAM)
  self:ShowPawnActor(BattleEnum.Team.ENUM_ENEMY)
  local HideScenePetDelegate = self:GetProperty(BattleConst.FsmVarNames.HideScenePetDelegate)
  if HideScenePetDelegate then
    HideScenePetDelegate:Invoke()
  end
  local HideSceneTreesDelegate = self:GetProperty(BattleConst.FsmVarNames.HideSceneTreesDelegate)
  if HideSceneTreesDelegate then
    HideSceneTreesDelegate:Invoke()
  end
end

function PlayerTeamShowAction:OnSkillFinish(Event, Skill)
  self:HideSceneObjectsAndShowBattleObjects()
  self:ReleaseBallActor()
  BattleUtils.CloseBattleAndTaskBlackLoading()
  self:Finish()
end

function PlayerTeamShowAction:ReleaseBallActor()
  if self.playerBallActors then
    for _, ballActor in pairs(self.playerBallActors) do
      if ballActor and UE4.UObject.IsValid(ballActor) then
        ballActor:K2_DestroyActor()
      end
    end
    self.playerBallActors = nil
  end
end

function PlayerTeamShowAction:SaveObject(bb, name)
  FsmUtils.SaveAsProperty(self.fsm, bb, name)
end

function PlayerTeamShowAction:DestroyProperty(name)
  FsmUtils.ClearProperty(self.fsm, name)
end

function PlayerTeamShowAction:OnExit()
  self.BattleManager = nil
  self.PawnManager = nil
  self.skillClass = nil
  self:ReleaseBallActor()
  self.playerBallActors = nil
  self.playerBallCount = nil
  if self.skillStartHideObjectDelay then
    _G.DelayManager:CancelDelayById(self.skillStartHideObjectDelay)
    self.skillStartHideObjectDelay = nil
  end
end

return PlayerTeamShowAction

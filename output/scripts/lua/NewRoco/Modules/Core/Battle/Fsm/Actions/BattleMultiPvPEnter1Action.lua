local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local Base = BattleActionBase
local BattleMultiPvPEnter1Action = Base:Extend("BattleMultiPvPEnter1Action")
FsmUtils.MergeMembers(Base, BattleMultiPvPEnter1Action, {})
BattleMultiPvPEnter1Action.HudType = {OneEnemyNpc = 1, TwoEnemyNpc = 2}
BattleMultiPvPEnter1Action.NpcAssistType = {
  WithNPC = 1,
  WithPet = 2,
  MAX = 3
}

function BattleMultiPvPEnter1Action:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.PawnManger = _G.BattleManager.battlePawnManager
  self.Skill1End = false
  self.Skill2End = false
  self.loadMySkillEnd = false
  self.loadEnemySkillEnd = false
  self.TickCamera = false
  self.TickCameraEnemy = false
  self.time = 0
  self.timeRemain = 0
  self.IsNewMaterial = false
  self.CameraPos = nil
  self.Kam2Vec = UE4.FVector()
  self.Kam1Vec = UE4.FVector()
end

function BattleMultiPvPEnter1Action:FindActors()
  local pets = BattleManager.battlePawnManager:GetInFieldAllPetByServer(BattleEnum.Team.ENUM_TEAM)
  local isNpcAssistAndWithNpcPet = BattleUtils.IsNpcAssist() and BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithPet
  local myPlayer = BattleManager.battlePawnManager:GetPlayerMyTeam()
  self.ballPath = {}
  self.playerPets = pets
  for i, v in ipairs(pets) do
    if isNpcAssistAndWithNpcPet and myPlayer and v.team ~= myPlayer.team then
      self.ballPath[#pets - i + 1] = BattleConst.BallPaths.None
    else
      self.ballPath[#pets - i + 1] = self:GetPetBallSpecial(v.card.petInfo.battle_common_pet_info)
    end
  end
  local enemyPets = BattleManager.battlePawnManager:GetInFieldAllPetByServer(BattleEnum.Team.ENUM_ENEMY)
  self.enemyBallPath = {}
  self.enemyPets = pets
  for i, v in ipairs(enemyPets) do
    self.enemyBallPath[#enemyPets - i + 1] = BattleUtils.GetPetBallPath(v.card.petInfo.battle_common_pet_info)
  end
end

function BattleMultiPvPEnter1Action:GetPetBallSpecial(petData)
  local specialBattleBall = _G.DataConfigManager:GetBattleGlobalConfig("dimo_battle_ball")
  if specialBattleBall and specialBattleBall.numList then
    local battleId = specialBattleBall.numList[1] or 0
    local ballId = specialBattleBall.numList[2] or 0
    local battleConf = BattleUtils.GetBattleConfig()
    if battleConf and battleConf.id == battleId then
      return BattleUtils.GetPetBallPath({ball_id = ballId})
    end
  end
  return BattleUtils.GetPetBallPath(petData)
end

function BattleMultiPvPEnter1Action:OnEnter()
  if BattleManager.isSkipEnterAction then
    self:Finish()
    return
  end
  local CheckAppearanceMode = self:GetProperty("CheckAppearanceMode", false)
  self.IsShowAppearance = CheckAppearanceMode and BattleUtils.IsTriggerAppearanceInField(CheckAppearanceMode)
  self.isTickable = false
  self:FindActors()
  self.IsNewMaterial = false
  self.isSceneObjectsHide = false
  if self.IsShowAppearance then
    self.resList = {
      BattleConst.PvPEnter.TwoPlayerSkill_C,
      BattleConst.PvPEnter.TwoEnemySkill_C
    }
  else
    self.resList = {
      BattleConst.PvPEnter.TwoPlayerSkill_C,
      BattleConst.PvPEnter.TwoPlayerPetSkill_C,
      BattleConst.PvPEnter.TwoEnemyPetSkill_C,
      BattleConst.PvPEnter.TwoEnemySkill_C
    }
  end
  self.loadedResCount = 0
  self.hasLoadHud = false
  BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
  _G.NRCEventCenter:RegisterEvent("BattleMultiPvPEnter1Action", self, BattleEvent.NPC_ENTER_ANIM_DISAPPEAR, self.SetMaterialLine)
  self:AddEventListener()
  _G.BattleSkillManager:PreLoadRes(self.resList, true)
end

function BattleMultiPvPEnter1Action:DoLineDisappear(DeltaTime)
  if self.LineDisappearState then
    if self.LineDisappearTime + DeltaTime <= self.LineDisappearLength then
      local ratio = (self.LineDisappearTime + DeltaTime) / self.LineDisappearLength
      self.Material:SetScalarParameterValue("ZLineDisappearTime", ratio)
      self.LineDisappearTime = self.LineDisappearTime + DeltaTime
    else
      self.LineDisappearState = nil
      self.LineDisappearTime = nil
      self.LineDisappearLength = nil
    end
  end
end

function BattleMultiPvPEnter1Action:SetMaterialLine(State)
  if 1 == State then
    if self.Material then
      self.LineDisappearState = true
      self.LineDisappearLength = 0.1
      self.LineDisappearTime = 0
      self.Material:SetScalarParameterValue("ZLineDisappearTime", 0)
      self.Material:SetScalarParameterValue("ZLineDisappearState", 1)
    end
  else
    if self.Material then
      self.Material:SetScalarParameterValue("ZLineDisappearTime", 1)
    end
    self.LineDisappearState = nil
  end
end

function BattleMultiPvPEnter1Action:RemoveEventListener()
  if _G.BattleUtils.IsWeeklyChallenge() then
    _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.PlayWeeklySequenceFinished, self.OnPlayWeeklySequenceFinished)
  end
end

function BattleMultiPvPEnter1Action:AddEventListener()
  self.IsWeeklyPlaySequenceFinished = self:IsWeeklyChallengeFinished()
  if _G.BattleUtils.IsWeeklyChallenge() then
    _G.NRCEventCenter:RegisterEvent("BattleMultiPvPEnter1Action", self, WeeklyChallengeBattleModuleEvent.PlayWeeklySequenceFinished, self.OnPlayWeeklySequenceFinished)
  end
end

function BattleMultiPvPEnter1Action:OnPlayWeeklySequenceFinished()
  self.IsWeeklyPlaySequenceFinished = true
  self:CheckCanLoadHud()
end

function BattleMultiPvPEnter1Action:GetSkillClass(resPath)
  if _G.BattleSkillManager:IsResLoaded(resPath) then
    return _G.BattleSkillManager:GetLoadedClass(resPath)
  else
    Log.Error("BattleMultiPvPEnter1Action:GetSkillClass resPath not loaded resPath=", resPath)
  end
end

function BattleMultiPvPEnter1Action:CheckOnePlayerAnimClass(Player, teamEnum)
  local str
  if teamEnum == BattleEnum.Team.ENUM_ENEMY then
    str = "\230\136\145\230\150\185\232\167\146\232\137\178"
  else
    str = "\230\149\140\230\150\185\232\167\146\232\137\178"
  end
  if Player then
    local softAnimClass = Player.Mesh.SoftAnimClass
    if not softAnimClass then
      Log.Error("BattleMultiPvPEnter1Action \230\137\148\231\144\131\232\161\168\230\188\148" .. str .. "TPos\228\186\134\239\188\140softAnimClass = nil")
    end
    local animClass = Player.Mesh:GetAnimClass()
    if not animClass then
      Log.Error("BattleMultiPvPEnter1Action \230\137\148\231\144\131\232\161\168\230\188\148" .. str .. "TPos\228\186\134\239\188\140animClass = nil")
    end
    local animInstance1 = Player.Mesh:GetAnimInstance()
    if not animInstance1 then
      Log.Error("BattleMultiPvPEnter1Action \230\137\148\231\144\131\232\161\168\230\188\148" .. str .. "TPos\228\186\134\239\188\140animInstance = nil")
    end
  end
end

function BattleMultiPvPEnter1Action:CheckPlayerAnimClass(myPlayer, enemyPlayer)
  self:CheckOnePlayerAnimClass(myPlayer, BattleEnum.Team.ENUM_TEAM)
  self:CheckOnePlayerAnimClass(enemyPlayer, BattleEnum.Team.ENUM_ENEMY)
end

function BattleMultiPvPEnter1Action:PrintEnemyModelPath()
  local enemyPlayer = BattleManager.battlePawnManager:GetPlayerEnemyTeam()
  if enemyPlayer.roleInfo then
    local ModelConfID = BattleUtils.GetPlayerModelId(enemyPlayer.roleInfo)
    local modelConfig = _G.DataConfigManager:GetModelConf(ModelConfID)
    if modelConfig then
      Log.Warning("BattleMultiPvPEnter1Action.PrintEnemyModelPath:modelConfig is nil ModelConfID=", ModelConfID, "path=", modelConfig.path, "please check the \"MODEL_CONF\" config")
    else
      Log.Warning("BattleMultiPvPEnter1Action.PrintEnemyModelPath:modelConfig is nil ModelConfID=", ModelConfID, "please check the \"MODEL_CONF\" config")
    end
  end
end

function BattleMultiPvPEnter1Action:OnLoadSkillOver(playerModelData, myPlayer, myPlayer2, enemyPlayer, enemyPlayer2)
  BattleEventCenter:UnBind(self)
  self:RemoveEventListener()
  if not self.active then
    Log.Debug("BattleMultiPvPEnter1Action has finished")
    return
  end
  self:CheckPlayerAnimClass(myPlayer, enemyPlayer)
  self.skillClass = self:GetSkillClass(BattleConst.PvPEnter.TwoPlayerSkill_C)
  self.SkillComponent = myPlayer.RocoSkill
  if not self.SkillComponent then
    Log.Error("self.SkillComponent is nil", "battleType=", _G.BattleManager.battleRuntimeData.battleType, "Name", myPlayer:GetName())
    self:Finish()
    return
  end
  self.SkillComponent:ClearAllPassiveSkillObjs()
  self.Skill = self.SkillComponent:FindOrAddSkillObj(self.skillClass)
  if not self.Skill then
    Log.Error("self.Skill is nil")
    self:Finish()
    return
  end
  if BattleUtils.IsPve() or BattleUtils.IsNpcChallenge() or BattleUtils.IsWeeklyChallenge() then
    local characters = {}
    characters[0] = myPlayer
    if BattleUtils.IsNpcAssist() then
      local blackboard = self.Skill:GetBlackboard()
      if BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithPet then
        blackboard:SetValueAsString("PET_2V2", "PET_2V2")
      elseif BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithNpc then
        blackboard:SetValueAsString("NPC_2V2", "NPC_2V2")
      else
        blackboard:SetValueAsString("Normal", "Normal")
      end
      characters[1] = myPlayer2
    end
    self.Skill:SetCharacters(characters)
  end
  for _, pet in ipairs(self.playerPets) do
    if pet.model then
      BattleUtils.SetParticleKeyForSkillObj(pet.model, self.Skill, pet.card.medalBlackBoard)
    end
  end
  self.playerBallActors = playerModelData.playerBallActors
  local Blackboard = self.Skill:GetBlackboard()
  for index, path in pairs(self.ballPath) do
    if self.playerBallActors and self.playerBallActors[index] then
      Blackboard:SetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", index), self.playerBallActors[index])
    end
  end
  self.Skill:SetCaster(myPlayer)
  self.Skill:SetPassive(true)
  self.Skill:SetBallAdditionalPaths(self.ballPath)
  if #self.ballPath <= 1 then
    self.Skill.PlayerAmountType = 1
  else
    self.Skill.PlayerAmountType = 2
  end
  self.Skill:RegisterEventCallback("PostStart1", self, self.OnPostStartPlayer1)
  self.Skill:RegisterEventCallback("Pause", self, self.OnPauseForAppearance)
  self.Skill:RegisterEventCallback("Unbind", self, self.OnUnbind)
  self.SkillComponent:LoadAndPlaySkill(self.Skill)
  self.loadMySkillEnd = true
  local enemySkillClass = self:GetSkillClass(self.resList[#self.resList])
  if not enemyPlayer or not enemyPlayer.RocoSkill then
    if not enemyPlayer then
      Log.Error("BattleMultiPvPEnter1Action.OnLoadSkillOver \230\149\140\230\150\185\230\149\176\230\141\174\228\184\186\231\169\186 battleType=", _G.BattleManager.battleRuntimeData.battleType, "\230\136\152\230\150\151id=", _G.BattleManager.battleRuntimeData.battleConfig.id)
    end
    if not enemyPlayer.RocoSkill then
      self:PrintEnemyModelPath()
      Log.Error("BattleMultiPvPEnter1Action.OnLoadSkillOver \230\149\140\230\150\185\230\149\176\230\141\174RocoSkill\228\184\186\231\169\186 battleType=", _G.BattleManager.battleRuntimeData.battleType, "\230\136\152\230\150\151id=", _G.BattleManager.battleRuntimeData.battleConfig.id)
    end
    self:Finish()
    return
  end
  self.enemySkillComponent = enemyPlayer.RocoSkill
  self.enemySkillComponent:ClearAllPassiveSkillObjs()
  self.enemySkill = self.enemySkillComponent:FindOrAddSkillObj(enemySkillClass)
  Blackboard = self.enemySkill:GetBlackboard()
  self.enemyBallActors = playerModelData.enemyBallActors
  for index, path in pairs(self.enemyBallPath) do
    if self.enemyBallActors and self.enemyBallActors[index] then
      Blackboard:SetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", index), self.enemyBallActors[index])
    end
  end
  self.enemySkill:SetCaster(enemyPlayer)
  self.enemySkill:SetPassive(true)
  self.enemySkill:SetBallAdditionalPaths(self.enemyBallPath)
  if #self.enemyBallPath <= 1 then
    self.enemySkill.PlayerAmountType = 1
  else
    self.enemySkill.PlayerAmountType = 2
  end
  for _, pet in ipairs(self.enemyPets) do
    if pet.model then
      BattleUtils.SetParticleKeyForSkillObj(pet.model, self.Skill, pet.card.medalBlackBoard)
    end
  end
  self.enemySkill:RegisterEventCallback("PostStart1", self, self.OnPostStart1)
  self.enemySkill:RegisterEventCallback("NewMaterial", self, self.OnNewMaterial)
  self.enemySkill:RegisterEventCallback("ShowPlayer", self, self.ShowPlayer)
  self.enemySkill:RegisterEventCallback("Pause", self, self.OnEnemyPauseForAppearance)
  self.enemySkill:RegisterEventCallback("End", self, self.OnSkillEnd)
  local enemyCharacters = {}
  enemyCharacters[8] = enemyPlayer
  if enemyPlayer2 then
    enemyCharacters[9] = enemyPlayer2
    self.enemySkill:SetTargets({enemyPlayer2})
  end
  self.enemySkill:SetCharacters(enemyCharacters)
  self.enemySkillComponent:LoadAndPlaySkill(self.enemySkill)
  self.loadEnemySkillEnd = true
  BattleUtils.ShowAllPetPlatForm()
  BattleUtils.CloseBattleAndTaskBlackLoading()
end

function BattleMultiPvPEnter1Action:OnSkillEnd()
  self.isSkillEnd = true
end

function BattleMultiPvPEnter1Action:CanFinish()
  return self.isSkillEnd and BattleManager.vBattleField:IsChangedGrass()
end

function BattleMultiPvPEnter1Action:LoadHud()
  self.hasLoadHud = true
  local BattleConf = BattleUtils.GetBattleConfig()
  self.hudType = BattleMultiPvPEnter1Action.HudType.OneEnemyNpc
  local enemyPlayer, enemyPlayer2, teamPlayer, teamPlayer2
  if BattleConf.npc_battle_list and #BattleConf.npc_battle_list >= 2 then
    self.hudType = BattleMultiPvPEnter1Action.HudType.TwoEnemyNpc
    local enemyTeams = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)
    if #enemyTeams >= 2 then
      enemyPlayer2 = enemyTeams[2].player
    end
  end
  if BattleUtils.IsNpcAssist() then
    local playerTeams = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
    if #playerTeams >= 2 then
      teamPlayer2 = playerTeams[1].player
      if BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithPet then
        teamPlayer2 = teamPlayer2.team.pets[1]
        self.npcAssistBattlePet = teamPlayer2.team.pets[1]
      else
      end
    end
  end
  teamPlayer = BattleManager.battlePawnManager:GetPlayerMyTeam()
  enemyPlayer = BattleManager.battlePawnManager:GetPlayerEnemyTeam()
  local battlePlayerData = {
    teamPlayer = teamPlayer,
    teamPlayer2 = teamPlayer2,
    enemyPlayer = enemyPlayer,
    enemyPlayer2 = enemyPlayer2
  }
  
  local function successCallback(playerModelData, widget)
    widget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    widget:SetRenderOpacity(0)
    NRCModuleManager:DoCmd(BattleUIModuleCmd.RefWidget, "PvpHud", widget)
    self:OnLoadSkillOver(playerModelData, playerModelData.teamPlayer, playerModelData.teamPlayer2, playerModelData.enemyPlayer, playerModelData.enemyPlayer2)
    self:RefreshPlayerName()
  end
  
  local bPanelOpen = _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenBattleEntryHud, battlePlayerData, self.ballPath, self.enemyBallPath, successCallback)
  if not bPanelOpen then
    self:Finish()
  end
end

function BattleMultiPvPEnter1Action:PlaySkill()
  if self.SkillComponent then
    self.SkillComponent:LoadAndPlaySkill(self.Skill)
    if self.enemySkillComponent then
      self.enemySkillComponent:LoadAndPlaySkill(self.enemySkill)
    end
  else
    self:OnCloseBattleEntryHud()
    self:Finish()
  end
end

function BattleMultiPvPEnter1Action:ShowPlayer()
  local Caches = BattleUtils.GetAllTraceNpc()
  if Caches then
    for _, Cache in ipairs(Caches) do
      if Cache and Cache.npc then
        Cache.npc:SetVisibleForBattleReason(false)
      end
    end
  end
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_LOCAL_PLAYER, true)
  NRCModeManager:DoCmd(NPCModuleCmd.EnterBattle, BattleManager.battleRuntimeData.NearbyValidBattleLocation, BattleConst.Define.BattleFieldRange)
  BattleUtils.PinOnTheGroundForAllPawn()
  local playerTeams = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  local enemyTeams = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)
  for i, v in ipairs(playerTeams) do
    if v.player.model then
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(true)
      end
    end
    if v.player.battlePlayerComponents then
      v.player.battlePlayerComponents:HideMark()
    end
  end
  for i, v in ipairs(enemyTeams) do
    if v.player.model then
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(true)
      end
    end
    if v.player.battlePlayerComponents then
      v.player.battlePlayerComponents:HideMark()
    end
  end
end

function BattleMultiPvPEnter1Action:OnUnbind(Event, Skill)
  if not BattleManager.GetIsInBattle() then
    return
  end
  local Blackboard = Skill:GetBlackboard()
  self.timeRemain = Skill:GetLength() - Skill:GetCurrentTime()
  self.Kamera1 = Blackboard:GetValueAsObject("camActor_0002")
  self.Kamera1Bone = Blackboard:GetValueAsObject("camActor_0002_SA")
  self:SaveObject(Blackboard, "camActor_0002")
  self:SaveObject(Blackboard, "camActor_0002_SA")
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0, nil, nil, true)
  self.TickCamera = true
end

function BattleMultiPvPEnter1Action:OnNewMaterial(Event, Skill)
  self:ClearDelay()
  self.matDelayID = _G.DelayManager:DelayFrames(1, function()
    self:OnCloseBattleEntryHud()
    self:Finish()
  end)
end

function BattleMultiPvPEnter1Action:OnCloseBattleEntryHud()
  if self.IsShowAppearance then
    return
  end
  if BattleUtils.IsPvp() then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePvpEntryHud)
  end
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePVP_PreparePanel)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ForceCloseLoading)
end

function BattleMultiPvPEnter1Action:GetWidget()
  return NRCModuleManager:DoCmd(BattleUIModuleCmd.GetWidget, "PvpHud")
end

function BattleMultiPvPEnter1Action:HideSceneObjects()
  if self.isSceneObjectsHide then
    return
  end
  self.isSceneObjectsHide = true
  local HideScenePetDelegate = self:GetProperty(BattleConst.FsmVarNames.HideScenePetDelegate)
  if HideScenePetDelegate then
    HideScenePetDelegate:Invoke()
  end
  local HideSceneTreesDelegate = self:GetProperty(BattleConst.FsmVarNames.HideSceneTreesDelegate)
  if HideSceneTreesDelegate then
    HideSceneTreesDelegate:Invoke()
  end
end

function BattleMultiPvPEnter1Action:OnUnbindEnemy(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  self.Kamera2 = Blackboard:GetValueAsObject("camActor_Save1")
  self.Kamera2Bone = Blackboard:GetValueAsObject("camActor_Save1_SA")
  self.TickCameraEnemy = true
end

function BattleMultiPvPEnter1Action:OnTick(DeltaTime)
  if not self.isTickable then
    return
  end
  if not BattleManager.vBattleField:TryChangeGrass() then
    return
  end
  if self:CanFinish() then
    self:Finish()
    return
  end
  if self.TickCamera and self.Kamera1Bone then
    self.time = self.time + DeltaTime * 1.5
    local alpha = self.time / self.timeRemain
    if alpha >= 1 then
      alpha = 1
    end
    if not self.CameraPos then
      self.CameraPos = _G.BattleManager.vBattleField:GetPCGCamTransform()
    end
    local CamVec = self.CameraPos
    local FOVDiff = _G.BattleManager.vBattleField.battleCameraManager.FOV - 50
    self.Kam1Vec = self.Kamera1Bone.SkeletalMeshComponent:GetSocketTransform("cam_01")
    self.Kamera1:Abs_K2_SetActorTransform_WithoutHit(UE4.UKismetMathLibrary.TLerp(self.Kam1Vec, CamVec, alpha), false, false)
    if self.Kamera1:GetComponentByClass(UE4.UCameraComponent) then
      self.Kamera1:GetComponentByClass(UE4.UCameraComponent).FieldOfView = 50 + FOVDiff * alpha
    end
  end
  self:DoLineDisappear(DeltaTime)
end

function BattleMultiPvPEnter1Action:OnPostStartPlayer1(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  local Mat = Blackboard:GetValueAsObject("MaterialToBe")
  if Mat then
    Log.Debug("Material Retrieved!")
  else
    Log.Error("No Mat :(")
  end
  if not self:GetWidget() then
    return
  end
  local img = self:GetWidget().ImagePlayer
  if img then
    Log.Debug("Image Retrieved!")
  end
  img:SetBrushFromMaterial(Mat, false)
end

function BattleMultiPvPEnter1Action:OnPauseForAppearance(Event, Skill)
  if not self.IsShowAppearance then
    return
  end
  Skill:SetPlayRate(0)
end

function BattleMultiPvPEnter1Action:OnEnemyPauseForAppearance(Event, Skill)
  if not self.IsShowAppearance then
    return
  end
  Skill:SetPlayRate(0)
  self.isSkillEnd = true
end

function BattleMultiPvPEnter1Action:SetPlayerName(player, text)
  if not player or not text then
    return
  end
  local text_str
  if player.roleInfo.role_addi_info.appearance_info then
    local firstCardId = player.roleInfo.role_addi_info.appearance_info.card_label_first_selected
    local secondCardId = player.roleInfo.role_addi_info.appearance_info.card_label_last_selected
    if firstCardId and secondCardId and 0 ~= firstCardId and 0 ~= secondCardId then
      local CardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(firstCardId)
      local CardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(secondCardId)
      if CardLabelFirstConf and CardLabelLastConf then
        text_str = string.format("%s%s", CardLabelFirstConf.label_text, CardLabelLastConf.label_text)
      end
    elseif player.roleInfo.role_addi_info.appearance_info.npc_title then
      text_str = player.roleInfo.role_addi_info.appearance_info.npc_title
    else
      Log.Warning("BattleMultiPvPEnter1Action.SetPlayerName,card_label_first_selected=", firstCardId, "card_label_last_selected=", secondCardId, "npc_title=", player.roleInfo.role_addi_info.appearance_info.npc_title)
    end
  else
    Log.Warning("BattleMultiPvPEnter1Action.SetPlayerName.Func:\231\142\169\229\174\182\231\188\186\229\176\145appearance_info\230\149\176\230\141\174")
  end
  if text_str and "" ~= text_str then
    text:SetVisibility(UE4.ESlateVisibility.Visible)
    text:SetText(text_str)
  else
    text:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function BattleMultiPvPEnter1Action:SetNPCName(NpcChallengeInfo, text)
  if not NpcChallengeInfo or not text then
    return
  end
  if NpcChallengeInfo and NpcChallengeInfo.appearance_info and NpcChallengeInfo.appearance_info[1] then
    text:SetVisibility(UE4.ESlateVisibility.Visible)
    local firstCardId = NpcChallengeInfo.appearance_info[1].card_label_first_selected
    local secondCardId = NpcChallengeInfo.appearance_info[1].card_label_last_selected
    if firstCardId and secondCardId then
      local CardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(firstCardId)
      local CardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(secondCardId)
      if CardLabelFirstConf and CardLabelLastConf then
        text:SetText(string.format("%s%s", CardLabelFirstConf.label_text, CardLabelLastConf.label_text))
      end
    end
  end
end

function BattleMultiPvPEnter1Action:RefreshPlayerName()
  if BattleUtils.IsPvp() then
    local teamPlayer = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
    local enemyPlayer = _G.BattleManager.battlePawnManager:GetPlayerEnemyTeam()
    self:GetWidget().Uno:SetText(teamPlayer.roleInfo.base.name)
    self:GetWidget().Uno_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self:SetPlayerName(teamPlayer, self:GetWidget().Uno_1)
    self:GetWidget().Dos:SetText(enemyPlayer.roleInfo.base.name)
    self:GetWidget().Dos_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self:SetPlayerName(enemyPlayer, self:GetWidget().Dos_1)
  else
    local teamPlayer = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
    self:SetPlayerName(teamPlayer, self:GetWidget().Uno)
    local BattleConf = BattleUtils.GetBattleConfig()
    if BattleConf.npc_battle_list and BattleConf.npc_battle_list[1] then
      local NpcTitleText = BattleConf.npc_battle_list[1].npc_title_1st
      if NpcTitleText and string.len(NpcTitleText) > 0 then
        self:GetWidget().Dos:SetText(NpcTitleText)
      elseif 0 ~= BattleConf.npc_battle_list[1].is_uid then
        local NpcChallengeInfo = _G.BattleManager:GetBattleNpcChallengeInfo()
        self:SetNPCName(NpcChallengeInfo, self:GetWidget().Dos)
      end
    end
    self:GetWidget().Uno_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:GetWidget().Dos_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function BattleMultiPvPEnter1Action:CancelStart1DelayID()
  if self.start1DelayID then
    DelayManager:CancelDelay(self.start1DelayID)
    self.start1DelayID = nil
  end
end

function BattleMultiPvPEnter1Action:OnPostStart1(Event, Skill)
  self:CancelStart1DelayID()
  self.start1DelayID = DelayManager:DelayFrames(1, function()
    _G.BattleEventCenter:Dispatch(BattleEvent.EntryHudSkillStartPlayerEvent)
    _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.CloseLoadingCurtainEvent)
    _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.EntryHudSkillStartPlayerEvent)
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  end)
  self.isTickable = true
  self:GetWidget():SetPanelAlreadyVisible()
  self:GetWidget():SetRenderOpacity(1)
  self:GetWidget():CloseWorldRenderingByTag()
  self:HideSceneObjects()
  self:NpcChallengeCloseBlackScreen()
  local Blackboard = Skill:GetBlackboard()
  local Mat = Blackboard:GetValueAsObject("MaterialToBe")
  if Mat then
    Log.Debug("Material Retrieved!")
    self.Material = Mat
  else
    Log.Error("No Mat :(")
  end
  if not self:GetWidget() then
    return
  end
  local img = self:GetWidget().ImageFuse
  if img then
    Log.Debug("Image Retrieved!")
  end
  img:SetBrushFromMaterial(Mat, false)
  local answer
  if Mat then
    answer = Mat:K2_GetTextureParameterValue("Texture")
  end
  if answer then
    self.screenSize = {}
    self.screenSize.X, self.screenSize.Y = answer.SizeX, answer.SizeY
  else
    self.screenSize = UE4.USlateBlueprintLibrary.GetLocalSize(img:GetCachedGeometry())
  end
  self:GetWidget():PlayAnimation(self:GetWidget().anim)
end

function BattleMultiPvPEnter1Action:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    self:CheckCanLoadHud()
    return true
  end
end

function BattleMultiPvPEnter1Action:CheckCanLoadHud()
  if not self.hasLoadHud and self.loadedResCount == #self.resList and self.IsWeeklyPlaySequenceFinished then
    self:LoadHud()
  end
end

function BattleMultiPvPEnter1Action:IsWeeklyChallengeFinished()
  if not _G.BattleUtils.IsWeeklyChallenge() then
    return true
  end
  local isPlaying = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPlaySequenceState)
  return not isPlaying
end

function BattleMultiPvPEnter1Action:ClearDelay()
  if self.matDelayID then
    _G.DelayManager:CancelDelayById(self.matDelayID)
    self.matDelayID = nil
  end
end

function BattleMultiPvPEnter1Action:OnFinish()
  if BattleUtils.IsNpcAssist() and BattleUtils.NpcAssistType() == BattleEnum.NpcAssistType.WithPet then
    self.npcAssistBattlePet:ShowPet()
  end
  self:CancelStart1DelayID()
  self:ClearDelay()
  self.isTickable = false
  self:SetMaterialLine(0)
  self.LineDisappearState = nil
  self.LineDisappearLength = nil
  self.LineDisappearTime = nil
  self.Material = nil
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.NPC_ENTER_ANIM_DISAPPEAR, self.SetMaterialLine)
  BattleUtils.CloseBattleAndTaskBlackLoading()
  BattleManager.isSkipEnterAction = true
  self.enemySkill = nil
  self.enemySkillComponent = nil
  self.Skill = nil
  self.SkillComponent = nil
  self.Kamera1 = nil
  self.Kamera2 = nil
  self.Kamera1Bone = nil
  self.Kamera2Bone = nil
  self.TickCamera = false
  self.TickCameraEnemy = false
  self.enemyPets = nil
  self.playerPets = nil
end

function BattleMultiPvPEnter1Action:NpcChallengeCloseBlackScreen()
  if BattleUtils.IsNpcChallenge() then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.SetForbidCloseLoading, nil)
    NRCModuleManager:DoCmdAsync({}, BattleUIModuleCmd.CloseLoading)
  end
end

function BattleMultiPvPEnter1Action:OnExit()
  self:HideSceneObjects()
  self:OnCloseBattleEntryHud()
end

function BattleMultiPvPEnter1Action:SaveObject(bb, name)
  FsmUtils.SaveAsProperty(self.fsm, bb, name)
end

return BattleMultiPvPEnter1Action

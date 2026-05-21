local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Base = BattleActionBase
local BattleShowPetByAppearance = Base:Extend("BattleShowPetByAppearance")
FsmUtils.MergeMembers(Base, BattleShowPetByAppearance, {})
local SkillComponentSourceType = {Player = 1, Pet = 2}

function BattleShowPetByAppearance:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function BattleShowPetByAppearance:GetTarget(context)
  local allPets = BattleManager.battlePawnManager:GetAllPets()
  table.sort(allPets, function(a, b)
    local aValue = a.card.posInField + (10 - a.teamEnm)
    local bValue = b.card.posInField + (10 - b.teamEnm)
    if aValue == bValue then
      return a.teamEnm < b.teamEnm
    else
      return aValue < bValue
    end
  end)
  local shouldShowPets = {}
  local targetPets = {}
  for _, v in ipairs(allPets) do
    if v.player.model then
      v:HidePet()
      table.insert(targetPets, v)
    elseif v.card:IsExistAtField() then
      table.insert(shouldShowPets, v)
    end
  end
  context.targetPets = targetPets
  context.shouldShowPets = shouldShowPets
end

function BattleShowPetByAppearance:LoadBallPath(context)
  local ballAddPath = {}
  local loadBallContext = context.loadBallContext
  loadBallContext.ballAddPathNum = 0
  local targetPets = context.targetPets or {}
  for i = 1, #targetPets do
    loadBallContext.ballAddPathNum = loadBallContext.ballAddPathNum + 1
    local targetPet = targetPets[i]
    local card = targetPet and targetPet.card
    local petInfo = card and card.petInfo
    local commonInfo = petInfo and petInfo.battle_common_pet_info
    ballAddPath[i] = self:GetPetBallSpecial(commonInfo, targetPet.teamEnm)
  end
  loadBallContext.playerBallActors = {}
  loadBallContext.playerBallCount = 0
  for index, Path in pairs(ballAddPath) do
    NRCResourceManager:LoadResAsync(self, Path, 255, -1, function(caller, resRequest, modelClass)
      self:LoadPlayerBallPathOver(context, resRequest, modelClass, index)
    end, function(caller, resRequest, errMsg)
      Log.Error("BattleShowPetByAppearance LoadResAsync failed teamClassPath1=", Path, errMsg)
    end)
  end
end

function BattleShowPetByAppearance:GetPetBallSpecial(petData, teamEnum)
  if teamEnum == BattleEnum.Team.ENUM_TEAM then
    local specialBattleBall = _G.DataConfigManager:GetBattleGlobalConfig("dimo_battle_ball")
    if specialBattleBall and specialBattleBall.numList then
      local battleId = specialBattleBall.numList[1] or 0
      local ballId = specialBattleBall.numList[2] or 0
      local battleConf = BattleUtils.GetBattleConfig()
      if battleConf and battleConf.id == battleId then
        return BattleUtils.GetPetBallPath({ball_id = ballId})
      end
    end
  end
  return BattleUtils.GetPetBallPath(petData)
end

function BattleShowPetByAppearance:LoadPlayerBallPathOver(context, resRequest, modelClass, Index)
  local Transform = UE4.FTransform(UE4.FQuat(), UE.FVector(0, 0, 0))
  local World = UE4Helper.GetCurrentWorld()
  local ballActor = World:SpawnActor(modelClass, Transform)
  ballActor:InitOutSceneAsync(nil, function(actor)
    self:SaveBallActor(context, actor, Index)
  end)
end

function BattleShowPetByAppearance:ActionStart(mainContext, skillContext)
  if not self.active then
    return
  end
  local needCameraChangeToSkillOnActionStart = skillContext and skillContext.needCameraChangeToSkillOnActionStart
  if needCameraChangeToSkillOnActionStart then
    BattleManager.vBattleField.battleCameraManager:CalcPosCache()
    BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  end
  local needShowCurrentPetOnActionStart = skillContext and skillContext.needShowCurrentPetOnActionStart
  self:HideSceneActor(mainContext)
  self:CloseBlackScreen()
  self:PrepareForG6(skillContext)
  self:ShowAllPlayer(mainContext)
  if needShowCurrentPetOnActionStart then
    self:ShowCurrentPet(mainContext, skillContext)
  end
  self:ShowOtherPet(mainContext)
end

function BattleShowPetByAppearance:CloseBlackScreen()
  if _G.BattleUtils.IsTrainBattle() then
    local asyncData = {
      owner = self,
      callback = function()
      end
    }
    NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.CloseLoading)
  end
end

function BattleShowPetByAppearance:HideSceneActor(context)
  if not self.active then
    return
  end
  if context.hasHideSceneObjectsAndShowBattleObjects then
    return
  end
  self:OnCloseBattleEntryHud()
  context.hasHideSceneObjectsAndShowBattleObjects = true
  local HideScenePetDelegate = self:GetProperty(BattleConst.FsmVarNames.HideScenePetDelegate)
  if HideScenePetDelegate then
    HideScenePetDelegate:Invoke()
    BattleUtils.PinOnTheGroundForAllPawn()
  else
    Log.Debug("BattlePlayThrowBallEnterAnimAction OnHidePlayer")
    NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
    NRCModeManager:DoCmd(NPCModuleCmd.EnterBattle, BattleManager.battleRuntimeData.NearbyValidBattleLocation, BattleConst.Define.BattleFieldRange)
    BattleUtils.PinOnTheGroundForAllPawn()
  end
  local HideSceneTreesDelegate = self:GetProperty(BattleConst.FsmVarNames.HideSceneTreesDelegate)
  if HideSceneTreesDelegate then
    HideSceneTreesDelegate:Invoke()
  end
end

function BattleShowPetByAppearance:ShowCurrentPet(mainContext, skillContext)
  if not self.active then
    return
  end
  local currentPet = skillContext and skillContext.currentPet
  if not currentPet then
    return
  end
  currentPet:ShowPet()
end

function BattleShowPetByAppearance:ShowOtherPet(context)
  if not self.active then
    return
  end
  local shouldShowPets = context and context.shouldShowPets
  if not shouldShowPets then
    return
  end
  for _, v in ipairs(shouldShowPets) do
    v:ShowPet()
  end
end

function BattleShowPetByAppearance:ShowAllPlayer(context)
  if not self.active then
    return
  end
  if context.hasShowAllPlayer then
    return
  end
  context.hasShowAllPlayer = true
  self:ShowPawnActor(BattleEnum.Team.ENUM_TEAM, true)
  self:ShowPawnActor(BattleEnum.Team.ENUM_ENEMY, true)
end

function BattleShowPetByAppearance:ShowAll(context)
  if not self.active then
    return
  end
  self:ShowPawnActor(BattleEnum.Team.ENUM_TEAM)
  self:ShowPawnActor(BattleEnum.Team.ENUM_ENEMY)
end

function BattleShowPetByAppearance:SaveBallActor(context, actor, Index)
  if not self.active then
    return
  end
  local loadBallContext = context.loadBallContext
  if not loadBallContext.playerBallActors then
    loadBallContext.playerBallActors = {}
  end
  if not loadBallContext.playerBallCount then
    loadBallContext.playerBallCount = 0
  end
  loadBallContext.playerBallActors[Index] = actor
  loadBallContext.playerBallCount = loadBallContext.playerBallCount + 1
  loadBallContext.allBallsLoaded = loadBallContext.playerBallCount == loadBallContext.ballAddPathNum
  self:OnAllBallActorsLoaded(context)
end

function BattleShowPetByAppearance:OnEnter()
  local CheckAppearanceMode = self:GetProperty("CheckAppearanceMode", false)
  if not CheckAppearanceMode or not BattleUtils.IsTriggerAppearanceInField(CheckAppearanceMode) then
    self:Finish()
    return
  end
  local asyncContext = {}
  self.asyncContext = asyncContext
  asyncContext.loadingSkillIndex = 0
  asyncContext.playingSkillIndex = 0
  asyncContext.targetPets = {}
  asyncContext.shouldShowPets = {}
  asyncContext.hasHideSceneObjectsAndShowBattleObjects = false
  asyncContext.hasShowAllPlayer = false
  asyncContext.allSkillsPlayFinished = false
  local loadBallContext = {}
  asyncContext.loadBallContext = loadBallContext
  loadBallContext.playerBallActors = {}
  loadBallContext.playerBallCount = 0
  loadBallContext.ballAddPathNum = 0
  loadBallContext.allBallsLoaded = false
  local showPetContextList = {}
  asyncContext.showPetContextList = showPetContextList
  self:GetTarget(asyncContext)
  self:LoadBallPath(asyncContext)
  self.AllResList = {}
  self.CallPetIndex = 0
  local targetPets = asyncContext and asyncContext.targetPets or {}
  for i, v in ipairs(targetPets) do
    local useNpcEnterSkill = false
    local skillResPath = v.card.AppearancePath:GetZhaoHuan()
    local needShowCurrentPet = true
    if v.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      local npcCfg = _G.DataConfigManager:GetNpcConf(v.player:GetNpcID())
      if npcCfg then
        local modelConfig = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
        if modelConfig and not string.IsNilOrEmpty(modelConfig.battle_entry_anim_path) then
          useNpcEnterSkill = true
          skillResPath = modelConfig.battle_entry_anim_path
        end
      end
    end
    local isDefaultEnemyZhaoHuanSkill = skillResPath == BattleConst.EnemyZhaoHuan
    local needExtraSkill = isDefaultEnemyZhaoHuanSkill or useNpcEnterSkill
    if needExtraSkill then
      needShowCurrentPet = false
    end
    local context = BattleShowPetByAppearance.CreateSkillContext(v.player, v, skillResPath, false, needShowCurrentPet, SkillComponentSourceType.Player)
    table.insert(showPetContextList, context)
    if needExtraSkill then
      local extraContext = BattleShowPetByAppearance.CreateSkillContext(v.player, v, BattleConst.PveEnter.OneEnemyPetAppearanceCallout, true, true, SkillComponentSourceType.Pet)
      table.insert(showPetContextList, extraContext)
    end
  end
  BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded, BattleEvent.OnSkillBeforeAsync)
  self:LoadNextRes(asyncContext)
  self:TryPlayNextSkill(asyncContext)
end

function BattleShowPetByAppearance.CreateSkillContext(battlePlayer, targetPet, skillResPath, needCameraChange, needShowCurrentPet, skillComponentSourceType)
  local context = {}
  context.battlePlayer = battlePlayer
  context.targetPet = targetPet
  context.skillResPath = skillResPath
  context.skillComponentSourceType = skillComponentSourceType or SkillComponentSourceType.Pet
  context.loadedResCount = 0
  context.skillLoaded = false
  context.skillLoading = false
  context.resList = {skillResPath}
  context.needCameraChangeToSkillOnActionStart = needCameraChange or false
  context.needShowCurrentPetOnActionStart = needShowCurrentPet or false
  context.skillObject = nil
  context.skillPlaying = false
  context.skillPlayFinished = false
  context.currentPet = nil
  return context
end

function BattleShowPetByAppearance:LoadNextRes(context)
  local nextIndex = context.loadingSkillIndex + 1
  if nextIndex > #context.showPetContextList then
    return
  end
  context.loadingSkillIndex = nextIndex
  local skillContext = context.showPetContextList[nextIndex]
  if skillContext.skillLoaded then
    self:LoadNextRes(context)
    return
  end
  self.loadSkillContext = skillContext
  skillContext.loadedResCount = 0
  skillContext.skillLoaded = false
  skillContext.skillLoading = true
  local resList = {
    skillContext.skillResPath
  }
  skillContext.resList = resList
  if #resList > 0 then
    BattleSkillManager:PreLoadRes(resList, true)
  else
    Log.Warning("BattleShowPetByAppearance:LoadNextRes \229\189\147\229\137\141 skill context \230\151\160\232\181\132\230\186\144\232\166\129\229\138\160\232\189\189\239\188\140\229\183\178\232\183\179\232\191\135", nextIndex)
    self:OnAllSkillLoaded(context, skillContext)
  end
end

function BattleShowPetByAppearance:OnBattleEvent(event, ...)
  if event == BattleEvent.OnSkillResLoaded then
    local value = (...)
    local mainContext = self.asyncContext
    local showPetContextList = mainContext and mainContext.showPetContextList or {}
    local resList = self.loadSkillContext and self.loadSkillContext.resList or {}
    for _, resPath in ipairs(resList) do
      if value == resPath then
        self.loadSkillContext.loadedResCount = self.loadSkillContext.loadedResCount + 1
        if self.loadSkillContext.loadedResCount == #self.loadSkillContext.resList then
          self:OnAllSkillLoaded(mainContext, self.loadSkillContext)
        end
      end
    end
    return true
  elseif event == BattleEvent.OnSkillBeforeAsync then
    local value, skillObject = ...
    local mainContext = self.asyncContext
    local showPetContextList = mainContext and mainContext.showPetContextList or {}
    local skillResPath = self.loadSkillContext and self.loadSkillContext.skillResPath
    if value == skillResPath then
      local skill = skillObject
      local pet = self.loadSkillContext.targetPet
      if pet then
        skill:SetCaster(pet.player.model)
        skill:SetTargets({
          pet.model
        })
        skill:SetCharacters(BattleManager.battlePawnManager:GetAllPawnActorForSkill())
        BattleUtils.SetParticleKeyForSkillObj(pet.model, skillObject, pet.card.medalBlackBoard)
      end
    end
  end
end

function BattleShowPetByAppearance:OnAllSkillLoaded(mainContext, skillContext)
  if self.finished then
    return
  end
  skillContext.skillLoading = false
  skillContext.skillLoaded = true
  self:TryPlayNextSkill(mainContext)
  self:LoadNextRes(mainContext)
end

function BattleShowPetByAppearance:OnAllBallActorsLoaded(context, skillContext)
  self:TryPlayNextSkill(context)
end

function BattleShowPetByAppearance:PlayShowPetSkill(mainContext, skillContext, eventName, skill)
  skillContext.skillObject = nil
  if not skillContext.skillLoaded then
    return
  end
  local skillPlayFinished = skillContext and skillContext.skillPlayFinished
  if skillPlayFinished then
    return
  end
  local skillPlaying = skillContext and skillContext.skillPlaying
  if skillPlaying then
    return
  end
  skillContext.skillPlaying = true
  local targetPet = skillContext.targetPet
  if not targetPet then
    self:OnSkillPlayFinished(mainContext, skillContext)
    return
  end
  local battlePlayer = skillContext.battlePlayer
  if not battlePlayer or not battlePlayer.model then
    self:OnSkillPlayFinished(mainContext, skillContext)
    return
  end
  local skillResPath = skillContext and skillContext.skillResPath
  local skillClass = BattleSkillManager:GetLoadedClass(skillResPath)
  if not skillClass then
    self:OnSkillPlayFinished(mainContext, skillContext)
    return
  end
  local skillComponent
  local sourceType = skillContext and skillContext.skillComponentSourceType or SkillComponentSourceType.Pet
  if sourceType == SkillComponentSourceType.Pet then
    local targetPetModel = targetPet and targetPet.model
    skillComponent = targetPetModel and targetPetModel.RocoSkill
  elseif sourceType == SkillComponentSourceType.Player then
    local playerModel = battlePlayer and battlePlayer.model
    skillComponent = playerModel and playerModel.RocoSkill
  end
  if not UE.UObject.IsValid(skillComponent) then
    self:OnSkillPlayFinished(mainContext, skillContext)
    return
  end
  local prevActiveSkillObject = skillComponent:GetActiveSkill()
  if UE.UObject.IsValid(prevActiveSkillObject) then
    Log.Warning("[BattleShowPetByAppearance] \229\173\152\229\156\168\230\173\163\229\156\168\230\146\173\230\148\190\231\154\132\228\184\187\229\138\168\230\138\128\232\131\189\239\188\140\230\173\163\229\156\168\229\176\157\232\175\149\230\137\147\230\150\173")
    skillComponent:CancelSkill(prevActiveSkillObject, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  local skillObject = skillComponent:AddSkillObjFromClassAndReturn(skillClass)
  if not skillObject then
    self:OnSkillPlayFinished(mainContext, skillContext)
    return
  end
  skillContext.skillObject = skillObject
  local ballPath = self:GetPetBallSpecial(targetPet.card.petInfo.battle_common_pet_info, targetPet.teamEnm)
  BattleUtils.SetParticleKeyForSkillObj(targetPet.model, skillObject, targetPet.card.medalBlackBoard)
  local characters = BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  do
    local playerStartIndex = UE4.EBattleStaticActorType.Player_1
    local petStartIndex = UE4.EBattleStaticActorType.Pet_1_1
    local MaxPlaterIndex = UE4.EBattleStaticActorType.Player_1_4
    if battlePlayer.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      playerStartIndex = UE4.EBattleStaticActorType.Player_2
      petStartIndex = UE4.EBattleStaticActorType.Pet_2_1
      MaxPlaterIndex = UE4.EBattleStaticActorType.Player_2_4
    end
    if characters[playerStartIndex] ~= battlePlayer.model then
      local oldPlayer = characters[playerStartIndex]
      characters[playerStartIndex] = battlePlayer.model
      for i = playerStartIndex + 1, MaxPlaterIndex do
        if characters[i] == battlePlayer.model then
          characters[i] = oldPlayer
          break
        end
      end
    end
    characters[petStartIndex] = targetPet.model
  end
  skillContext.currentPet = targetPet
  skillObject.PlayerAmountType = 1
  skillObject:SetDynamicData({BallPath = ballPath})
  skillObject:SetCaster(battlePlayer.model)
  skillObject:SetTargets({
    targetPet.model
  })
  skillObject:SetCharacters(characters)
  skillObject:RegisterEventCallback("ActionStart", self, function()
    self:ActionStart(mainContext, skillContext)
  end)
  skillObject:RegisterEventCallback("PostStart", self, function()
    self:ActionStart(mainContext, skillContext)
  end)
  skillObject:RegisterEventCallback("AdjustCamera", self, self.AdjustCamera)
  skillObject:RegisterEventCallback("PreEnd", self, function()
    self:OnSkillPlayFinished(mainContext, skillContext)
  end)
  skillObject:RegisterEventCallback("End", self, function()
    self:OnSkillPlayFinished(mainContext, skillContext)
  end)
  if BattleUtils.IsDeepWater() then
    skillObject.BattleFieldLimitType = UE.EBattleFieldLimitType.Water
  else
    skillObject.BattleFieldLimitType = UE.EBattleFieldLimitType.Ground
  end
  local skillStartResult = skillComponent:LoadAndPlaySkill(skillObject)
  if skillStartResult ~= UE.ESkillStartResult.Success then
    Log.Error("[BattleShowPetByAppearance] LoadAndPlaySkill result is not success", skillStartResult)
    self:OnSkillPlayFinished(mainContext, skillContext)
  end
end

function BattleShowPetByAppearance:AdjustCamera(Event, skill)
  BattleManager.vBattleField.battleCameraManager:CalcPosCache()
  BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
end

function BattleShowPetByAppearance:SaveObject(bb, name)
  FsmUtils.SaveAsProperty(self.fsm, bb, name)
end

function BattleShowPetByAppearance:OnSkillPlayFinished(mainContext, skillContext)
  if not skillContext then
    return
  end
  self:RecoverFromG6(skillContext)
  local skillPlayFinished = skillContext and skillContext.skillPlayFinished
  if skillPlayFinished then
    return
  end
  skillContext.skillPlayFinished = true
  skillContext.skillPlaying = false
  self:TryPlayNextSkill(mainContext)
end

function BattleShowPetByAppearance:PrepareForG6(skillContext)
  if skillContext then
    if skillContext.battlePlayer then
      skillContext.battlePlayer:PrepareForG6()
    end
    if skillContext.targetPet then
      skillContext.targetPet:PrepareForG6()
    end
  end
end

function BattleShowPetByAppearance:RecoverFromG6(skillContext)
  if skillContext then
    if skillContext.battlePlayer then
      skillContext.battlePlayer:RecoverFromG6()
    end
    if skillContext.targetPet then
      skillContext.targetPet:RecoverFromG6()
    end
  end
end

function BattleShowPetByAppearance:TryPlayNextSkill(mainContext)
  local currentIndex = mainContext.playingSkillIndex
  local nextIndex = currentIndex + 1
  Log.Debug("TryPlayNextSkill: currentIndex=", currentIndex, " nextIndex=", nextIndex, " totalSkills=", #mainContext.showPetContextList)
  if nextIndex <= #mainContext.showPetContextList then
    local currentSkillContext = mainContext.showPetContextList[currentIndex]
    local currentSkillFinished = 0 == currentIndex or currentSkillContext and currentSkillContext.skillPlayFinished
    local nextSkillContext = mainContext.showPetContextList[nextIndex]
    local loadBallContext = mainContext and mainContext.loadBallContext
    local nextSkillLoaded = nextSkillContext and nextSkillContext.skillLoaded
    local allBallsLoaded = loadBallContext and loadBallContext.allBallsLoaded
    if currentSkillFinished and nextSkillLoaded and allBallsLoaded then
      mainContext.playingSkillIndex = nextIndex
      self:PlayShowPetSkill(mainContext, nextSkillContext)
    end
  else
    Log.Debug("TryPlayNextSkill: All skills finished")
    self:OnSkillFinish(mainContext)
  end
end

function BattleShowPetByAppearance:OnSkillFinish(context, Event, Skill)
  local allSkillsPlayFinished = context and context.allSkillsPlayFinished
  if allSkillsPlayFinished then
    return
  end
  if context then
    context.allSkillsPlayFinished = true
  end
  self:HideSceneActor(context)
  self:ShowAll(context)
  local loadBallContext = context and context.loadBallContext
  self:ReleaseBallActor(loadBallContext)
  self:Finish()
end

function BattleShowPetByAppearance:ShowPawnActor(teamEnum, ignorePets)
  for i, v in ipairs(_G.BattleManager.battlePawnManager:GetAllTeam(teamEnum)) do
    self:ShowPlayer(v.player)
    if not ignorePets and #v.pets > 0 then
      for _, p in pairs(v.pets) do
        if p.model and p.card:IsExistAtField() then
          p:ShowPet()
        end
      end
    end
  end
end

function BattleShowPetByAppearance:ShowPlayer(player)
  if player and player.model then
    player:ShowPlayer()
    local sceneComp = player.model:GetComponentByClass(UE4.USceneComponent)
    if sceneComp then
      sceneComp:SetVisibility(true)
    end
    player.model:TryHelmetOn()
    if player.battlePlayerComponents and player.battlePlayerComponents.HideMark then
      player.battlePlayerComponents:HideMark()
    end
  end
end

function BattleShowPetByAppearance:ReleaseBallActor(loadBallContext)
  local playerBallActors = loadBallContext and loadBallContext.playerBallActors
  if playerBallActors then
    for _, ballActor in pairs(playerBallActors) do
      if ballActor and UE4.UObject.IsValid(ballActor) then
        ballActor:K2_DestroyActor()
      end
    end
    self.playerBallActors = nil
  end
end

function BattleShowPetByAppearance:OnCloseBattleEntryHud()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePvpEntryHud)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePVP_PreparePanel)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ForceCloseLoading)
end

function BattleShowPetByAppearance:OnFinish()
  self.asyncContext = nil
  BattleEventCenter:UnBind(self)
  BattleUtils.CloseBattleAndTaskBlackLoading()
  self:OnCloseBattleEntryHud()
end

return BattleShowPetByAppearance

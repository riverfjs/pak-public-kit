local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local RocoSkillLuaEventTypeLabels = require("NewRoco.Utils.RocoSkillLuaEventTypeLabels")
local RocoSkillLuaCustomEvent = require("NewRoco.Utils.RocoSkillLuaCustomEvent")
local Base = BattlePlayerBase
local BattleBagToPreparePlayer = Base:Extend("BagToPreparePlayer")

function BattleBagToPreparePlayer:Ctor()
  Base.Ctor(self)
end

function BattleBagToPreparePlayer:Reset()
  _G.BattleEventCenter:UnBind(self)
end

function BattleBagToPreparePlayer:Play(performNode)
  self:Reset()
  self:InitFromNode(performNode)
  local context = {}
  self.currentContext = context
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED, BattleEvent.PET_LOAD_MODE_LOVER)
  Log.Debug("BattleBagToPreparePlayer:Play")
  local bagToPrepare = self.bag_to_prepare
  local petIdList = bagToPrepare and bagToPrepare.pet_id or {}
  local toPosList = bagToPrepare and bagToPrepare.to_pos or {}
  local petIdToPos = {}
  for i, petId in ipairs(petIdList) do
    local toPos = toPosList[i]
    petIdToPos[petId] = toPos
  end
  local petIdWaitingToSpawn = {}
  context.petIdWaitingToSpawn = petIdWaitingToSpawn
  context.spawningPets = true
  context.petIdToNewPet = {}
  for petId, toPos in pairs(petIdToPos) do
    local pawnManager = _G.BattleManager.battlePawnManager
    local battleCard = pawnManager:GetCardByGuid(petId)
    local owner = battleCard and battleCard.owner
    local teamEnum = owner and owner.teamEnm
    local team = owner and owner.team
    if battleCard then
      battleCard:RefreshPosInFieldWithPos()
      petIdWaitingToSpawn[petId] = true
      local newPet = pawnManager:PawnPet(teamEnum, team, battleCard, owner)
    end
  end
  self:CheckAllPetSpawned()
end

function BattleBagToPreparePlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode and performNode:GetInfo()
  self.performInfo = performInfo
  local bag_to_prepare = performInfo and performInfo.bag_to_prepare
  if bag_to_prepare then
    self.bag_to_prepare = bag_to_prepare
  end
end

function BattleBagToPreparePlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_LOAD_MODE_LOVER then
    self:OnPetSpawned(...)
    return true
  end
end

function BattleBagToPreparePlayer:OnPetSpawned(battlePet)
  local context = self.currentContext
  local petIdToNewPet = context and context.petIdToNewPet
  local petId = battlePet and battlePet.guid
  local petIdWaitingToSpawn = context and context.petIdWaitingToSpawn
  if petId and petIdWaitingToSpawn then
    petIdWaitingToSpawn[petId] = false
  end
  if petIdToNewPet and petId then
    petIdToNewPet[petId] = battlePet
  end
  self:CheckAllPetSpawned()
end

function BattleBagToPreparePlayer:CheckAllPetSpawned()
  local context = self.currentContext
  local allPetSpawned = context and context.allPetSpawned
  if allPetSpawned then
    Log.Error("BattleBagToPreparePlayer:CheckAllPetSpawned")
    return
  end
  local anyPetIsWaitingSpawned = false
  local petIdWaitingToSpawn = context and context.petIdWaitingToSpawn or {}
  for petId, isWaiting in pairs(petIdWaitingToSpawn) do
    if isWaiting then
      anyPetIsWaitingSpawned = true
    end
  end
  if not anyPetIsWaitingSpawned then
    if context then
      context.spawningPets = false
      context.allPetSpawned = true
    end
    self:PlaySpawnSkill()
  end
end

function BattleBagToPreparePlayer:PlaySpawnSkill()
  local context = self.currentContext
  if context then
    context.skillLoading = true
  end
  local skillPath = BattleConst.TerritoryTrial.CommonBagToPrepare
  local skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath, true)
  if UE.UObject.IsValid(skillClass) then
    self:PlayBagToPrepareSkill(skillClass)
  else
    _G.BattleSkillManager:PreLoadSingleRes(skillPath, true, self, function(callbackOwner, isLoadedSucceed, resPath)
      skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath)
      self:PlayBagToPrepareSkill(skillClass)
    end)
  end
end

function BattleBagToPreparePlayer:PlayBagToPrepareSkill(skillClass)
  local context = self.currentContext
  if context then
    context.skillLoading = false
    context.skillLoaded = true
  end
  local petIdToNewPet = context and context.petIdToNewPet or {}
  if not UE.UObject.IsValid(skillClass) then
    Log.Error("BattleChangeModelPlayer:PlayChangeModelSkill skillClass is invalid")
    self:OnSkillComplete()
    return
  end
  local petIdList = {}
  for petId, pet in pairs(petIdToNewPet) do
    table.insert(petIdList, petId)
  end
  table.sort(petIdList)
  local petList = {}
  for i, petId in ipairs(petIdList) do
    local pet = petIdToNewPet[petId]
    table.insert(petList, pet)
  end
  local FirstTarget = petList[1]
  local FirstTargetModel = FirstTarget and FirstTarget.model
  if not UE.UObject.IsValid(FirstTargetModel) then
    Log.Error("no model found for BattleBagToPreparePlayer:PlayBagToPrepareSkill")
    self:OnSkillComplete()
    return
  end
  local RocoSkill = FirstTargetModel and FirstTargetModel.RocoSkill
  if not UE.UObject.IsValid(RocoSkill) then
    Log.Error("no RocoSkill found for BattleBagToPreparePlayer:PlayBagToPrepareSkill")
    self:OnSkillComplete()
    return
  end
  local targetList = {}
  for i, pet in ipairs(petList) do
    local model = pet and pet.model
    if UE.UObject.IsValid(model) then
      model.mesh.BoundsScale = 100
      table.insert(targetList, model)
    end
  end
  local skillObj = RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("skillObj is not found")
    return
  end
  skillObj:SetTargets(targetList)
  skillObj:SetPassive(true)
  skillObj:RegisterEventCallback("ActionStart", self, self.OnSkillStarted)
  skillObj:RegisterEventCallback("End", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback(RocoSkillLuaCustomEvent.StartFailed, self, self.OnSkillComplete)
  skillObj:RegisterEventCallback(RocoSkillLuaCustomEvent.Interrupt, self, self.OnSkillComplete)
  local skillStartResult = RocoSkill:PlaySkill(skillObj)
  if skillStartResult ~= UE.ESkillStartResult.Success then
    Log.Error("[BattleBagToPreparePlayer:PlayBagToPrepareSkill] skill start not success")
    self:OnSkillComplete()
  end
end

function BattleBagToPreparePlayer:OnSkillStarted()
  local context = self.currentContext
  if context then
    context.skillStarted = true
  end
  local petIdToNewPet = context and context.petIdToNewPet or {}
  for petId, pet in pairs(petIdToNewPet) do
    pet:ShowPet()
  end
end

function BattleBagToPreparePlayer:OnSkillComplete()
  local context = self.currentContext
  local skillCompleted = context and context.skillCompleted
  if skillCompleted then
    return
  end
  if context then
    context.skillCompleted = true
  end
  self:Finish()
end

function BattleBagToPreparePlayer:Finish()
  _G.BattleEventCenter:UnBind(self)
  self.currentContext = nil
  local performNode = self.performNode
  if performNode then
    self.performNode:PerformComplete()
  end
end

return BattleBagToPreparePlayer

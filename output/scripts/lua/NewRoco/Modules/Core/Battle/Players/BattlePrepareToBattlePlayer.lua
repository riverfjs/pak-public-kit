local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local RocoSkillLuaCustomEvent = require("NewRoco.Utils.RocoSkillLuaCustomEvent")
local Base = BattlePlayerBase
local BattlePrepareToBattlePlayer = Base:Extend("BattlePrepareToBattlePlayer")

function BattlePrepareToBattlePlayer:Ctor()
  Base.Ctor(self)
end

function BattlePrepareToBattlePlayer:Reset()
end

function BattlePrepareToBattlePlayer:Play(performNode)
  self:Reset()
  self:InitFromNode(performNode)
  Log.Debug("BattlePrepareToBattlePlayer:Play")
  local generalContext = {}
  local petIdToMoveContext = {}
  generalContext.petIdToMoveContext = petIdToMoveContext
  self.currentContext = generalContext
  local prepareToBattle = self.prepare_to_battle
  local petIdList = prepareToBattle and prepareToBattle.pet_id or {}
  local toPosList = prepareToBattle and prepareToBattle.to_pos or {}
  local petCount = #petIdList
  for i = 1, petCount do
    local context = {}
    local petId = petIdList and petIdList[i]
    local toPos = toPosList and toPosList[i]
    if petId then
      petIdToMoveContext[petId] = context
      goto lbl_49
      goto lbl_142
      ::lbl_49::
      local pawnManager = _G.BattleManager.battlePawnManager
      local battlePet = pawnManager:GetPetByGuid(petId)
      if not battlePet then
        Log.Error("BattlePrepareToBattlePlayer:Play battle pet is nil", petId)
        self:OnFinish()
        return
      end
      local battleCard = battlePet and battlePet.card
      local owner = battleCard and battleCard.owner
      local teamEnum = owner and owner.teamEnm
      local team = owner and owner.team
      local vBattleField = _G.BattleManager.vBattleField
      local petInfo = battleCard and battleCard.petInfo
      local insideInfo = petInfo and petInfo.battle_inside_pet_info
      local trialInfo = insideInfo and insideInfo.trial_pet_info
      local isBoss = trialInfo and trialInfo.is_boss
      local posInField = toPos
      if isBoss then
        if battleCard then
          battleCard.pos = 1
        end
        posInField = 1
      end
      local transform = vBattleField:GetPetBornPosition(teamEnum, posInField, battleCard)
      local translation = transform and transform.Translation or UE.FVector()
      local targetPosition = UE4.FVector(translation.X, translation.Y, translation.Z)
      context.battlePet = battlePet
      context.targetTransform = transform
      context.targetPosition = targetPosition
      if battleCard then
        battleCard:RefreshPosInFieldWithPos()
      end
      if team then
        team:RelocatePet(battlePet, toPos)
      end
      if isBoss then
        self:StartBossMove(context)
      else
        self:StartMove(battlePet, targetPosition, context)
      end
    end
    ::lbl_142::
  end
  if petCount > 0 then
    local battleManager = _G.BattleManager
    local vBattleField = battleManager and battleManager.vBattleField
    local battleCameraManager = vBattleField and vBattleField.battleCameraManager
    if battleCameraManager then
      battleCameraManager:CalcPosCache()
      battleCameraManager:ClearTemporaryPosData()
      battleCameraManager:ChangeToSkill(1, true)
    end
  end
  self:CheckAllPetMoved(generalContext)
end

function BattlePrepareToBattlePlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode and performNode:GetInfo()
  self.performInfo = performInfo
  local prepare_to_battle = performInfo and performInfo.prepare_to_battle
  if prepare_to_battle then
    self.prepare_to_battle = prepare_to_battle
  end
end

function BattlePrepareToBattlePlayer:StartMove(battlePet, targetPosition, context)
  if targetPosition then
    battlePet:MoveTo(targetPosition, true, self.OnPetMoveComplete, self, battlePet, context)
  else
    self:OnFinish()
  end
end

function BattlePrepareToBattlePlayer:StartBossMove(context)
  self:PlayMoveSkill(context)
end

function BattlePrepareToBattlePlayer:PlayMoveSkill(context)
  if context then
    context.skillLoading = true
  end
  local skillPath = BattleConst.TerritoryTrial.BossPrepareToBattle
  local skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath, true)
  if UE.UObject.IsValid(skillClass) then
    self:PlayPrepareToBattleSkill(skillClass, context)
  else
    _G.BattleSkillManager:PreLoadSingleRes(skillPath, true, self, function(callbackOwner, isLoadedSucceed, resPath)
      skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath)
      self:PlayPrepareToBattleSkill(skillClass, context)
    end)
  end
end

function BattlePrepareToBattlePlayer:PlayPrepareToBattleSkill(skillClass, context)
  if context then
    context.skillLoading = false
    context.skillLoaded = true
  end
  local targetTransform = context and context.targetTransform
  local targetPosition = context and context.targetPosition or FVectorZero
  if not UE.UObject.IsValid(skillClass) then
    Log.Error("BattleChangeModelPlayer:PlayChangeModelSkill skillClass is invalid")
    self:OnBossMoveSkillComplete(context)
    return
  end
  local Caster = context and context.battlePet
  local CasterModel = Caster and Caster.model
  if not UE.UObject.IsValid(CasterModel) then
    Log.Error("no model found for BattleBagToPreparePlayer:PlayBagToPrepareSkill")
    self:OnBossMoveSkillComplete(context)
    return
  end
  local RocoSkill = CasterModel and CasterModel.RocoSkill
  if not UE.UObject.IsValid(RocoSkill) then
    Log.Error("no RocoSkill found for BattleBagToPreparePlayer:PlayBagToPrepareSkill")
    self:OnBossMoveSkillComplete(context)
    return
  end
  local skillObj = RocoSkill:FindOrAddSkillObj(skillClass)
  if not UE.UObject.IsValid(skillObj) then
    Log.Error("skillObj is not found")
    return
  end
  local blackboard = skillObj:GetBlackboard()
  local halfHeight = Caster and Caster:GetHalfHeight() or 0
  if UE.UObject.IsValid(blackboard) then
    local currentWorld = _G.UE4Helper.GetCurrentWorld()
    local BossPositionActor = currentWorld and currentWorld:Abs_SpawnActor(UE.AActor, targetTransform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    local pinPosition = LineTraceUtils.GetPointValidLocationByLine(targetPosition, nil, nil, nil)
    pinPosition.Z = pinPosition.Z + halfHeight
    BossPositionActor:AddComponentByClass(UE.USceneComponent, false, UE.FTransform(), false)
    BossPositionActor:Abs_K2_SetActorLocation_WithoutHit(pinPosition)
    blackboard:SetValueAsObject("Battle_Boss_Pos", BossPositionActor)
  end
  skillObj:SetCaster(CasterModel)
  skillObj:SetPassive(false)
  skillObj:RegisterEventCallback("End", self, function()
    self:OnBossMoveSkillComplete(context)
  end)
  skillObj:RegisterEventCallback("PreEnd", self, function()
    self:OnBossMoveSkillComplete(context)
  end)
  skillObj:RegisterEventCallback(RocoSkillLuaCustomEvent.StartFailed, self, function()
    self:OnBossMoveSkillComplete(context)
  end)
  skillObj:RegisterEventCallback(RocoSkillLuaCustomEvent.Interrupt, self, function()
    self:OnBossMoveSkillComplete(context)
  end)
  local skillStartResult = RocoSkill:PlaySkill(skillObj)
  if skillStartResult ~= UE.ESkillStartResult.Success then
    Log.Error("[BattlePrepareToBattlePlayer:PlayPrepareToBattleSkill] skill start not success")
    self:OnSkillComplete()
  end
end

function BattlePrepareToBattlePlayer:OnBossMoveSkillComplete(context)
  local battlePet = context and context.battlePet
  self:OnPetMoveComplete(battlePet, context)
end

function BattlePrepareToBattlePlayer:OnPetMoveComplete(battlePet, context)
  if battlePet then
    _G.BattleEventCenter:Dispatch(BattleEvent.CHEER_SWITCH, battlePet)
  end
  if context then
    context.moveCompleted = true
  end
  self:CheckAllPetMoved(self.currentContext)
end

function BattlePrepareToBattlePlayer:CheckAllPetMoved(context)
  local petIdToMoveContext = context and context.petIdToMoveContext or {}
  local firstNotCompleteId
  for petId, moveContext in pairs(petIdToMoveContext) do
    local isComplete = moveContext and moveContext.moveCompleted
    local notComplete = not isComplete
    if notComplete then
      firstNotCompleteId = petId
      break
    end
  end
  if nil == firstNotCompleteId then
    self:OnFinish()
  end
end

function BattlePrepareToBattlePlayer:OnFinish()
  self.currentContext = nil
  local performNode = self.performNode
  if performNode then
    performNode:PerformComplete()
  end
end

return BattlePrepareToBattlePlayer

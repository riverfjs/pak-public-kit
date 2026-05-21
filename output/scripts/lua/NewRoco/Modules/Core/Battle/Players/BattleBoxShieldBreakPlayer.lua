local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local EventDispatcher = require("Common.EventDispatcher")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleBoxShieldBreakPlayer = BattlePlayerBase:Extend()

function BattleBoxShieldBreakPlayer:Ctor(owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.BattleManager = _G.BattleManager
  self.PawnManager = _G.BattleManager.battlePawnManager
  self.newPet = nil
end

function BattleBoxShieldBreakPlayer:Reset()
  self.box_shield_break = nil
  self.old_model = nil
  self.Player = nil
  self.performNode = nil
  self.changeModelBaseId = nil
  self.newPet = nil
end

function BattleBoxShieldBreakPlayer:Play(performNode)
  self:Reset()
  self:InitFromNode(performNode)
  self.oldPet = self.PawnManager:GetPetByGuid(self.box_shield_break.pet_id)
  if not self.oldPet then
    Log.Warning("zgx BattleBoxShieldBreakPlayer cant find battle pet ,\229\183\178\228\184\139\229\156\186\231\154\132\229\174\160\231\137\169\230\151\160\230\179\149\230\137\167\232\161\140changeModel\239\188\129\239\188\129\239\188\129", self.box_shield_break.pet_id)
    local card = self.PawnManager:GetCardByGuid(self.box_shield_break.pet_id)
    if card then
      card:OverwriteByServer(self.box_shield_break.pet_info)
      card:RefreshByServer()
    end
    self:OnSkillComplete()
    return
  end
  self:SetHpVisible(false)
  self.oldPet:ChangeBuffVisibility(false)
  self.Player = self.oldPet.player
  self.changeModelBaseId = self.box_shield_break.base_conf_id
  self:PawnNewPetModel()
end

function BattleBoxShieldBreakPlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.PerformInfo = performInfo
  self.box_shield_break = performInfo.box_shield_break
end

function BattleBoxShieldBreakPlayer:OnSkillComplete()
  if self.performNode then
    self:SetRotationData(self.oldPet, true)
    self:SetHpVisible(true)
    self:OnFinish()
    Log.Debug("BattleBoxShieldBreakPlayer Play OnSkillComplete:", self.performNode:GetNodeIdx())
    self.performNode:PerformComplete()
    self:Reset()
  end
end

function BattleBoxShieldBreakPlayer:PawnNewPetModel()
  local card = self.Player.deck:GetCardByGuid(self.box_shield_break.pet_id)
  local petInfo = card.petInfo
  if not card then
    Log.Warning("not find pet by id : ", self.box_shield_break.pet_id)
    self:OnSkillComplete()
    return
  end
  self.boxBaseConfId = petInfo.battle_common_pet_info.base_conf_id
  petInfo.battle_common_pet_info.base_conf_id = self.changeModelBaseId
  petInfo.battle_common_pet_info.conf_id = self.changeModelBaseId
  petInfo.battle_inside_pet_info.base_conf_id = self.changeModelBaseId
  petInfo.battle_inside_pet_info.conf_id = self.changeModelBaseId
  local conf = _G.DataConfigManager:GetPetbaseConf(self.changeModelBaseId)
  if conf then
    petInfo.battle_common_pet_info.name = conf.name
    petInfo.battle_inside_pet_info.name = conf.name
  end
  card:RefreshByServer()
  card:RefreshByBaseConf(self.changeModelBaseId)
  self.newPet = nil
  self.newPet = self.PawnManager:PawnPet(self.Player.teamEnm, self.Player.team, card, self.Player)
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED)
end

function BattleBoxShieldBreakPlayer:OnPawnNewPetFinish(pet)
  if not self.newPet or not self.newPet.model then
    self:OnSkillComplete()
    return
  end
  self.newPet = pet
  self.newPet:SetScale(1)
  if not BattleUtils.IsDeepWater() or not self.newPet:GetCanSwimming() then
    local pos = self.newPet.model:Abs_K2_GetActorLocation()
    local halfHeight = pet:GetHalfHeight()
    local ans, posNew = LineTraceUtils.GetPointValidLocation(pos, halfHeight)
    posNew.Z = posNew.Z + self.newPet:GetHalfHeight()
    self.newPet.model:Abs_K2_SetActorLocation_WithoutHit(posNew)
  end
  _G.BattleEventCenter:UnBind(self)
  self.newPet:SetPetVisibility(false)
  self.firstSkillPath, self.secondSkillPath = _G.BattleSkillManager:GetSurpriseBoxShieldBreakRes(self.box_shield_break)
  if self.firstSkillPath then
    local skillClass = _G.BattleSkillManager:GetLoadedClass(self.firstSkillPath)
    self:PlayMutationsSkill(skillClass)
  else
    self:OnMutationsSkillComplete()
  end
end

function BattleBoxShieldBreakPlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
    return true
  end
end

function BattleBoxShieldBreakPlayer:SaveBlackboard(blackboard, name)
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BattleBoxShieldBreakPlayer:SetTeamPetHide(IsHide)
  local allPet = _G.BattleManager.battlePawnManager:GetPlayerTeamPets()
  for _, pet in ipairs(allPet) do
    if pet then
      pet:SetPetVisibility(not IsHide)
    end
  end
end

function BattleBoxShieldBreakPlayer:OnMutationsSkillPostStart(Event, Skill)
end

function BattleBoxShieldBreakPlayer:OnMutationsSkillPreEnd(Event, Skill)
  if self.secondSkillPath then
    self:SavePrizeCamera(Skill)
    local skillClass = BattleSkillManager:GetLoadedClass(self.secondSkillPath)
    self:PlayChangeModelSkill(skillClass)
  else
    self:OnSkillComplete()
  end
end

function BattleBoxShieldBreakPlayer:SavePrizeCamera(Skill)
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerSkill(0)
end

function BattleBoxShieldBreakPlayer:OnMutationsSkillComplete()
  if self.secondSkillPath then
    local skillClass = BattleSkillManager:GetLoadedClass(self.secondSkillPath)
    self:PlayChangeModelSkill(skillClass)
  else
    self:OnSkillComplete()
  end
end

function BattleBoxShieldBreakPlayer:PlayMutationsSkill(skillClass)
  if not (skillClass and self.performNode) or self.performNode.IsFastPlay then
    self:OnMutationsSkillComplete()
    return
  end
  if not UE.UObject.IsValid(skillClass) then
    Log.Error("BattleBoxShieldBreakPlayer:PlayMutationsSkill skillClass is invalid")
    self:OnMutationsSkillComplete()
    return
  end
  local Caster = self.oldPet
  local casterModel = Caster and Caster.model
  if not casterModel then
    Log.Error("no model found for BattleBoxShieldBreakPlayer")
    self:OnMutationsSkillComplete()
    return
  end
  casterModel.mesh.BoundsScale = 100
  local skillObj = casterModel.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
  if not skillObj then
    Log.Error("skillObj is not found")
    self:OnMutationsSkillComplete()
    return
  end
  self:SetRotationData(self.oldPet, nil)
  self:SetMutationsSkillBlackBoard(skillObj)
  skillObj:SetCaster(casterModel)
  skillObj:SetTargets({
    self.newPet.model
  })
  skillObj:SetPassive(true)
  skillObj:RegisterEventCallback("Start", self, self.OnMutationsSkillPostStart)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnMutationsSkillPreEnd)
  casterModel.RocoSkill:LoadAndPlaySkill(skillObj)
end

function BattleBoxShieldBreakPlayer:SetMutationsSkillBlackBoard(skillObj)
  local blackboard = skillObj and skillObj:GetBlackboard()
  if blackboard and UE.UObject.IsValid(blackboard) then
    blackboard:SetValueAsFloat("HideFaceIndex", self.boxRandHideNum)
  end
end

function BattleBoxShieldBreakPlayer:SetChangeModeSkillBlackBoard(skillObj)
  local blackboard = skillObj and skillObj:GetBlackboard()
  if blackboard and UE.UObject.IsValid(blackboard) then
    local hasMutationsSkill = false
    local rarityType = self.box_shield_break.pet_rarity_type
    local PetRarityTypeEnum = _G.ProtoEnum.PetRarityType
    if rarityType == PetRarityTypeEnum.PET_RARITY_TYPE_SEASON_RARE then
      hasMutationsSkill = true
      blackboard:SetValueAsString("SaiJi", "SaiJi")
    end
    if not hasMutationsSkill then
      blackboard:SetValueAsString("Normal", "Normal")
    end
    if self.boxBaseConfId then
      if self.boxBaseConfId == 9001 then
        blackboard:SetValueAsString("box1", "box1")
      elseif self.boxBaseConfId == 9002 then
        blackboard:SetValueAsString("box2", "box2")
      elseif self.boxBaseConfId == 9003 then
        blackboard:SetValueAsString("box3", "box3")
      end
    end
    if self.changeModelBaseId and 0 ~= self.changeModelBaseId then
      local EffectsConf = _G.DataConfigManager:GetSeasonPetEffectsConf(self.changeModelBaseId, true)
      if EffectsConf and EffectsConf.condition_name then
        local effectBlacks = EffectsConf.condition_name
        for _, effectBlack in ipairs(effectBlacks) do
          blackboard:SetValueAsString(effectBlack, effectBlack)
        end
      end
    end
  end
end

function BattleBoxShieldBreakPlayer:PlayChangeModelSkill(skillClass)
  if not (skillClass and self.performNode) or self.performNode.IsFastPlay then
    self:OnSkillComplete()
    return
  end
  if not UE.UObject.IsValid(skillClass) then
    Log.Error("BattleBoxShieldBreakPlayer:PlayChangeModelSkill skillClass is invalid")
    self:OnSkillComplete()
    return
  end
  local Caster = self.oldPet
  local casterModel = Caster and Caster.model
  if not casterModel then
    Log.Error("no model found for BattleBoxShieldBreakPlayer")
    self:OnSkillComplete()
    return
  end
  casterModel.mesh.BoundsScale = 100
  local skillObj = casterModel.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
  if not skillObj then
    Log.Error("skillObj is not found")
    return
  end
  self:SetChangeModeSkillBlackBoard(skillObj)
  skillObj:SetCaster(casterModel)
  skillObj:SetTargets({
    self.newPet.model
  })
  skillObj:SetPassive(true)
  skillObj:RegisterEventCallback("End", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillComplete)
  skillObj:RegisterEventCallback("ShowPet", self, self.OnShowNewPet)
  casterModel.RocoSkill:LoadAndPlaySkill(skillObj)
end

function BattleBoxShieldBreakPlayer:OnShowNewPet(Event, Skill)
  if self.newPet then
    self.newPet:SetPetVisibility(true)
  end
end

function BattleBoxShieldBreakPlayer:SetRotationData(Pet, IsEnd)
  if not Pet or not Pet.model then
    return
  end
  local mesh = Pet.model:GetComponentByClass(UE4.UMeshComponent)
  if not mesh then
    return
  end
  local animInstance = mesh:GetAnimInstance()
  if not animInstance then
    return
  end
  if IsEnd then
    if animInstance.bEnableModify ~= nil then
      animInstance.bEnableModify = false
    end
    if animInstance.IndexHeZi1 then
      animInstance.IndexHeZi1 = 0
    end
    if animInstance.IndexHeZi2 then
      animInstance.IndexHeZi2 = 0
    end
    if animInstance.IndexHeZi3 then
      animInstance.IndexHeZi3 = 0
    end
    if animInstance.CycleHeZi1 then
      animInstance.CycleHeZi1 = 2
    end
    if animInstance.CycleHeZi2 then
      animInstance.CycleHeZi2 = 1
    end
    if animInstance.CycleHeZi3 then
      animInstance.CycleHeZi3 = 1
    end
  else
    Log.Debug("BattleBoxShieldBreakPlayer \230\131\138\229\150\156\231\155\146\229\173\144\231\160\180\231\155\190\232\161\168\230\188\148\230\149\176\230\141\174: \231\178\190\231\129\181\231\168\128\230\156\137\231\177\187\229\158\139=", self.box_shield_break.pet_rarity_type, "\231\178\190\231\129\181\231\129\181\231\170\129\229\143\152\231\177\187\229\158\139=", self.box_shield_break.pet_mutation_type, "\231\178\190\231\129\181\229\177\158\230\128\167\231\177\187\229\158\139=", self.box_shield_break.pet_attr_type)
    if animInstance.IndexHeZi1 then
      local rarityType = self.box_shield_break.pet_rarity_type
      local PetRarityTypeEnum = _G.ProtoEnum.PetRarityType
      if rarityType == PetRarityTypeEnum.PET_RARITY_TYPE_INVALID or rarityType == PetRarityTypeEnum.PET_RARITY_TYPE_COMMON then
        animInstance.IndexHeZi1 = 4
      else
        animInstance.IndexHeZi1 = rarityType - 1
      end
      Log.Debug("BattleBoxShieldBreakPlayer \230\131\138\229\150\156\231\155\146\229\173\144 \231\172\172\228\184\128\229\177\130\229\177\149\231\164\186\231\154\132\233\157\162=", animInstance.IndexHeZi1)
    end
    if animInstance.IndexHeZi2 then
      local mutationType = self.box_shield_break.pet_mutation_type
      local PetMutationTypeEnum = _G.ProtoEnum.PetMutationType
      if mutationType == PetMutationTypeEnum.PET_MUTATION_TYPE_INVALID or mutationType == PetMutationTypeEnum.PET_MUTATION_TYPE_COMMON then
        animInstance.IndexHeZi2 = 4
      else
        animInstance.IndexHeZi2 = mutationType - 1
      end
      Log.Debug("BattleBoxShieldBreakPlayer \230\131\138\229\150\156\231\155\146\229\173\144 \231\172\172\228\186\140\229\177\130\229\177\149\231\164\186\231\154\132\233\157\162=", animInstance.IndexHeZi2)
    end
    if animInstance.IndexHeZi3 then
      local petAttrType = self.box_shield_break.pet_attr_type
      if petAttrType == ProtoEnum.PetAttrType.PET_ATTR_TYPE_INVALID then
        Log.Error("BattleBoxShieldBreakPlayer \230\131\138\229\150\156\231\155\146\229\173\144 \231\172\172\228\184\137\229\177\130\229\177\149\231\164\186\231\154\132\233\157\162, pet_attr_type\230\149\176\230\141\174\233\148\153\232\175\175=", self.box_shield_break.pet_attr_type)
        petAttrType = 1
      end
      local PetAttrTypeEnum = _G.ProtoEnum.PetAttrType
      local dataMap = {
        [0] = {
          [PetAttrTypeEnum.PET_ATTR_TYPE_HP] = 0,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPEED] = 1,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_ATK] = 2,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_DEF] = 3,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_DEF] = 4
        },
        [1] = {
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_ATK] = 0,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPEED] = 1,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_ATK] = 2,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_DEF] = 3,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_DEF] = 4
        },
        [2] = {
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_ATK] = 0,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPEED] = 1,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_ATK] = 2,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_DEF] = 3,
          [PetAttrTypeEnum.PET_ATTR_TYPE_HP] = 4
        },
        [3] = {
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_ATK] = 0,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPEED] = 1,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_ATK] = 2,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_DEF] = 3,
          [PetAttrTypeEnum.PET_ATTR_TYPE_HP] = 4
        },
        [4] = {
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_ATK] = 0,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPEED] = 1,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_DEF] = 2,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_DEF] = 3,
          [PetAttrTypeEnum.PET_ATTR_TYPE_HP] = 4
        },
        [5] = {
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_ATK] = 0,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_ATK] = 1,
          [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_DEF] = 2,
          [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_DEF] = 3,
          [PetAttrTypeEnum.PET_ATTR_TYPE_HP] = 4
        }
      }
      local randNumMap = {
        [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_ATK] = 0,
        [PetAttrTypeEnum.PET_ATTR_TYPE_HP] = 1,
        [PetAttrTypeEnum.PET_ATTR_TYPE_SPE_DEF] = 2,
        [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_DEF] = 3,
        [PetAttrTypeEnum.PET_ATTR_TYPE_PHY_ATK] = 4,
        [PetAttrTypeEnum.PET_ATTR_TYPE_SPEED] = 5
      }
      local randHideNum = math.random(1, 5)
      if petAttrType <= randHideNum then
        randHideNum = randHideNum + 1
      end
      Log.Debug("BattleBoxShieldBreakPlayer \230\131\138\229\150\156\231\155\146\229\173\144 \231\172\172\228\184\137\229\177\130 \229\177\158\230\128\167=", petAttrType, "\233\154\143\230\156\186\229\128\188=", randHideNum)
      if not randNumMap[randHideNum] then
        Log.Error("BattleBoxShieldBreakPlayer randNumMap\228\184\141\229\173\152\229\156\168 randHideNum=", randHideNum)
      end
      randHideNum = randNumMap[randHideNum]
      local attrInex = dataMap[randHideNum][petAttrType]
      if not dataMap[randHideNum] then
        Log.Error("BattleBoxShieldBreakPlayer dataMap\228\184\141\229\173\152\229\156\168 randHideNum=", randHideNum)
      end
      if dataMap[randHideNum] and not dataMap[randHideNum][petAttrType] then
        Log.Error("BattleBoxShieldBreakPlayer dataMap[randHideNum]\228\184\141\229\173\152\229\156\168 petAttrType=", petAttrType)
      end
      Log.Debug("BattleBoxShieldBreakPlayer \230\131\138\229\150\156\231\155\146\229\173\144 \231\172\172\228\184\137\229\177\130 \233\154\144\232\151\143\231\154\132\229\128\188=", randHideNum, "\229\176\157\232\175\149\230\152\190\231\164\186\231\154\132\233\157\162=", attrInex)
      animInstance.IndexHeZi3 = attrInex
      self.boxRandHideNum = randHideNum
    end
    if animInstance.CycleHeZi1 then
      animInstance.CycleHeZi1 = 1
    end
    if animInstance.CycleHeZi2 then
      animInstance.CycleHeZi2 = 1
    end
    if animInstance.CycleHeZi3 then
      animInstance.CycleHeZi3 = 1
    end
  end
end

function BattleBoxShieldBreakPlayer:SetHpVisible(isShow)
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PLAYERSKILL_ISHIDE_HP, isShow)
end

function BattleBoxShieldBreakPlayer:OnFinish()
  if self.oldPet then
    self.oldPet:HidePet()
    table.insert(BattleManager.battlePawnManager.PendingKillBattlePets, self.oldPet)
  end
  _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerSkill(0)
  _G.BattleEventCenter:Dispatch(BattleEvent.BoxShieldBreak, self.newPet)
end

return BattleBoxShieldBreakPlayer

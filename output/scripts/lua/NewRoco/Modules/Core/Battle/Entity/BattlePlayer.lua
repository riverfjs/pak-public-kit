local BattlePlayerDeck = require("NewRoco.Modules.Core.Battle.Entity.Card.BattlePlayerDeck")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePathWithAppearance = require("NewRoco.Modules.Core.Battle.Common.BattlePathWithAppearance")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local SkillPlayer = require("NewRoco.Modules.Core.Battle.Common.SkillPlayer")
local BattleChangePetPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleChangePetPlayer")
local BattleCatchPetPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleCatchPetPlayer")
local RoundSelectReactionComponent = require("NewRoco.Modules.Core.Battle.Entity.Components.RoundSelect.RoundSelectReactionComponent")
local BubbleComponent = require("NewRoco.Modules.Core.Scene.Component.Bubble.BubbleComponent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local ProtoMessage = require("Data.PB.ProtoMessage")
local Base = require("NewRoco.Modules.Core.Battle.Entity.BattleObject")
local ServerData = require("Common.LocalServer.LocalBattleRSPTable")
local BattlePlayerSkill = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.BattlePlayerSkill")
local FashionSuitData = require("NewRoco.Modules.Core.Battle.Common.FashionSuitData")
local BattlePlayer = Base:Extend("BattlePlayer")

function BattlePlayer:Ctor()
  Base.Ctor(self)
  self.teamEnm = 0
  self.model = nil
  self.FirstPetPosInField = 0
  self.deck = BattlePlayerDeck(self)
  self.BubbleComponent = self:AddComponent(BubbleComponent(self))
  self.RoundSelectReactionComponent = self:AddComponent(RoundSelectReactionComponent(self))
  self.catchSkill = nil
  self.isNeedLoad = true
  self.lastTakenItemIsCompass = false
  self.battlePets = {}
  self.restPets = {}
  self.modelScale = 1.0
  self.TeamNumber = 0
  self.itemInfo = {}
  self.battlePlayerComponents = nil
  self.IsCanUseSkill = true
  self.playerSkillPhase = BattleEnum.PlayerSkillPhase.NoSkill
  self.PlayerSkillInfo = BattlePlayerSkill()
  self.PlayerSkillInfo:Init(nil, "NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePiecePlayerSkillChangePet", self)
  self.SkillList = {}
  self.CalCultsSkillList = {}
  self.FashionData = FashionSuitData()
  self.FashionData:SetOwner(self)
  self.ContinuousSkillSucceed = false
  self.free_catch = false
  self.QuicklyCatchBallId = -1
end

function BattlePlayer:InitDeck(deckParam)
  self.deck:Init(deckParam)
end

function BattlePlayer:Spawn(roleInfo, team, deckParam)
  self.guid = roleInfo.base.role_uin
  self.team = team
  self:SetRoleInfo(roleInfo)
  self.TeamNumber = roleInfo.teamNumber or 0
  self:InitFashionInfo()
  self:InitDeck(deckParam)
  if not self.isNeedLoad then
    self.sendPlayerSpawnedDelay = _G.DelayManager:DelayFrames(1, self.SendPlayerSpawned, self)
  end
  self.itemInfo = roleInfo.items or {}
end

function BattlePlayer:SendPlayerSpawned()
  _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_SPAWNED, self)
end

function BattlePlayer:InitFashionInfo()
  for i, v in pairs(self.FashionData) do
    if BattleConst[i] then
      self.FashionData[i] = BattleConst[i]
    end
  end
  if self.roleInfo.role_addi_info and self.roleInfo.role_addi_info.appearance_info then
    local apperance = self.roleInfo.role_addi_info.appearance_info
    local fashionIds = apperance.fashion_id
    if apperance.wearing_item and #apperance.wearing_item > 0 then
      fashionIds = {}
      for _, v in ipairs(apperance.wearing_item or {}) do
        table.insert(fashionIds, v.wearing_item_id)
      end
    end
    if fashionIds and #fashionIds > 0 then
      local suitIdTable = NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSuitEffect, fashionIds)
      if suitIdTable and #suitIdTable > 0 then
        local suitID = tonumber(suitIdTable[1])
        local suitConf = DataConfigManager:GetFashionSuitsConf(suitID, true)
        self.FashionData.suitConf = suitConf
      end
    end
    self.FashionData.bondConfs = {}
    if apperance.bond_info then
      for _, v in ipairs(apperance.bond_info.fashion_bond_item or {}) do
        local bondConf = DataConfigManager:GetFashionBondConf(v.id, true)
        if bondConf then
          table.insert(self.FashionData.bondConfs, bondConf)
        end
      end
    end
  end
end

function BattlePlayer:InitOp()
  self.opState = BattleEnum.Operation.ENUM_NONE
end

function BattlePlayer:SetOp(op)
  self.opState = op
end

function BattlePlayer:UpdateOpState(roleInfo)
  if roleInfo and roleInfo.req then
    if roleInfo.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CATCH_PET then
      self:SetOp(BattleEnum.Operation.ENUM_CATCH)
    else
      self:InitOp()
    end
  else
    self:InitOp()
  end
end

function BattlePlayer:OnRoleInfoUpdate(prevRoleInfo, nextRoleInfo)
  local prevRoleAddiInfo = prevRoleInfo and prevRoleInfo.role_addi_info
  local prevComoCmd = prevRoleAddiInfo and prevRoleAddiInfo.combo_cmd
  local nextRoleAddiInfo = nextRoleInfo and nextRoleInfo.role_addi_info
  local nextComoCmd = nextRoleAddiInfo and nextRoleAddiInfo.combo_cmd
  self:UpdateOpState(nextRoleInfo)
  if prevComoCmd ~= nextComoCmd then
    if BattleManager.battlePawnManager:IsLocalPlayer(self) then
      self:ClearCalCuLusSkillList()
      self:UpdateSkillListByServer(nextComoCmd)
    else
      self:SetSkillList(nextComoCmd)
    end
  end
end

function BattlePlayer:CopyLocalPlayerAppearance()
  local localPlayer = BattleUtils.GetPlayerModel()
  if localPlayer and self.model then
    self.model.IsCopyLocalPlayer = true
    self.model:CopyAppearance(localPlayer)
    local cameraManager = localPlayer:GetController().PlayerCameraManager
    cameraManager:UpdateCharacterFade(self.model.mesh, 0)
  end
end

function BattlePlayer:SetFashionSuit(caller, callback)
  if ServerData.values.battleMode then
    return false
  end
  if _G.BattleManager.battleRuntimeData.battleDebugControl and 0 == self.roleInfo.base.side and GlobalConfig.CharacterIndex ~= self.roleInfo.base.sex then
    self.model:SetDefaultSuit(self.model.Mesh, GlobalConfig.CharacterIndex, {}, {}, callback, caller)
    return true
  end
  if self.model and self.roleInfo.role_addi_info and self.roleInfo.role_addi_info.appearance_info then
    local wearing_items = self.roleInfo.role_addi_info.appearance_info.wearing_item or self.roleInfo.role_addi_info.appearance_info.fashion_id
    local salonIds = self.roleInfo.role_addi_info.appearance_info.salon_item_data
    if BattleUtils.IsPlayerUseHumanResByBit(self.roleInfo.base.state_bit) then
      self.model:SetDefaultSuit(self.model.Mesh, self.roleInfo.base.sex, wearing_items, salonIds, callback, caller)
      return true
    end
  end
  return false
end

function BattlePlayer:LoadBPComponents()
  local fTransfom = UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0))
  local params = {}
  params.player = self
  _G.BattleResourceManager:LoadActorAsyncWithParam(self, _G.UEPath.BP_BattlePlayerComponents, fTransfom, PriorityEnum.Passive_Battle_Players, params, self.LoadBPComponentsOver)
end

function BattlePlayer:LoadBPComponentsOver(battlePlayerComponents)
  if not UE4.UObject.IsValid(self.model) then
    if battlePlayerComponents and battlePlayerComponents.K2_DestroyActor then
      battlePlayerComponents:K2_DestroyActor()
    end
    Log.Error("zgx player is destroyed!!!")
    return
  end
  self.battlePlayerComponentsRef = UnLua.Ref(battlePlayerComponents)
  battlePlayerComponents:K2_AttachRootComponentToActor(self.model)
  battlePlayerComponents:K2_SetActorRelativeLocation(UE4.FVector(0, 0, 0), false, nil, false)
  if battlePlayerComponents.ClickTipUIOffset then
    local attachName = BattleUtils.GetAttachPointNameByType(UE4.EFXAttachPointType.Body)
    battlePlayerComponents.ClickTipUIOffset:K2_AttachTo(self.model:GetComponentByClass(UE4.USkeletalMeshComponent), attachName)
  end
  if battlePlayerComponents.SkillPredictionUIOffset then
    local attachName = BattleUtils.GetAttachPointNameByType(UE4.EFXAttachPointType.Hp)
    battlePlayerComponents.SkillPredictionUIOffset:K2_AttachTo(self.model:GetComponentByClass(UE4.USkeletalMeshComponent), attachName)
  end
  if battlePlayerComponents.SelectMarker3dOffset then
    local attachName = BattleUtils.GetAttachPointNameByType(UE4.EFXAttachPointType.Pos)
    battlePlayerComponents.SelectMarker3dOffset:K2_AttachTo(self.model:GetComponentByClass(UE4.USkeletalMeshComponent), attachName)
    local trans = battlePlayerComponents.SelectMarker3dOffset:GetRelativeTransform()
    trans.Translation.Z = trans.Translation.Z + BattleConst.ModelOffset.SelectorMarker3dOffsetZ
    battlePlayerComponents.SelectMarker3dOffset:K2_SetRelativeLocationAndRotation(trans.Translation, trans.Rotation:ToRotator(), false, nil, false)
  end
  self.battlePlayerComponents = battlePlayerComponents
  self.RoundSelectReactionComponent:Init()
  if battlePlayerComponents.DialogBoxUIOffset then
    self:DelaySetDialogPos()
  end
end

function BattlePlayer:DelaySetDialogPos()
  if self.destroyed or self.destroying then
    return
  end
  if not UE4.UObject.IsValid(self.model) then
    return
  end
  if self.model.Mesh.SkeletalMesh then
    if self.model.Mesh.SkeletalMesh:FindSocket("locator_talk") then
      local pos = self.battlePlayerComponents.DialogBoxUI:GetRelativeTransform().Translation
      pos.Z = 0
      self.battlePlayerComponents.DialogBoxUI:K2_SetRelativeLocation(pos, false, nil, false)
      self.battlePlayerComponents.DialogBoxUIOffset:K2_AttachTo(self.model:GetComponentByClass(UE4.USkeletalMeshComponent), "locator_talk")
    else
      local attachName = BattleUtils.GetAttachPointNameByType(UE4.EFXAttachPointType.Hp)
      self.battlePlayerComponents.DialogBoxUIOffset:K2_AttachTo(self.model:GetComponentByClass(UE4.USkeletalMeshComponent), attachName)
    end
  else
    self.setDialogPosDelay = DelayManager:DelayFrames(1, self.DelaySetDialogPos, self)
  end
end

function BattlePlayer:SetModel(model)
  self.model = model
  if not model then
    return
  end
  self.CompassSkill = SkillPlayer(self.model.RocoSkill, self.model, BattleConst.PerFormComPassSkill.Sequence)
  self.BagSkill = SkillPlayer(self.model.RocoSkill, self.model, BattleConst.BagHighlight.Sequence)
  self.CatchPetSkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.CatchPet.Sequence)
  self.TakeBallSkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.TakeBall.Sequence)
  self.TakeBallNoBlendSkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.TakeBallNoBlend.Sequence)
  self.TakeItemSkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.TakeItem.Sequence)
  self.TakeItemFromCompassSkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.TakeItemFromCompass.Sequence)
  self.TakeCompassSkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.TakeCompass.Sequence)
  self.RunAwaySkill = SkillPlayer(self.model.RocoSkillSub, self.model, BattleConst.RunAway.Sequence)
  if BattleUtils.IsDeepWater() then
    self:SetWaterPlatformVisible(true)
  end
end

function BattlePlayer:HidePlayer(setForceHidden)
  if UE4.UObject.IsValid(self.model) then
    self.model:SetActorHiddenInGame(true)
    if setForceHidden and self.model:IsA(UE.ARocoCharacter) then
      local model = self.model
      model:SetForceHidden(true)
    end
    if self.model.AvatarDecorator then
      local AActorS = self.model.AvatarDecorator:GetDecorators()
      for i, Actor in ipairs(AActorS:ToTable()) do
        Actor:SetActorHiddenInGame(true)
      end
    end
  end
end

function BattlePlayer:ShowPlayer()
  if UE4.UObject.IsValid(self.model) then
    self.model:SetActorHiddenInGame(false)
    if self.model:IsA(UE.ARocoCharacter) then
      local model = self.model
      model:SetForceHidden(false)
      UE.UNRCCharacterUtils.SetTickFaceParam(model, true)
    end
    if self.model.AvatarDecorator then
      local AActorS = self.model.AvatarDecorator:GetDecorators()
      for i, Actor in ipairs(AActorS:ToTable()) do
        Actor:SetActorHiddenInGame(false)
      end
    end
  end
  self:SetWaterPlatformVisible(true)
end

function BattlePlayer:SetWaterPlatformVisible(visible)
  if BattleUtils.IsDeepWater() and self.posInField then
    BattleManager.vBattleField:SetWaterPlatformVisible(self.teamEnm + 10, self.posInField, not visible)
  end
end

function BattlePlayer:SetRoleInfo(nextRoleInfo)
  nextRoleInfo = self:DeriveRoleInfoWithPushPopData(nextRoleInfo)
  local prevRoleInfo = self.roleInfo
  self.roleInfo = nextRoleInfo
  self:OnRoleInfoUpdate(prevRoleInfo, nextRoleInfo)
end

function BattlePlayer:ReplaceByServer(roleInfo)
  self:SetRoleInfo(roleInfo)
  self.itemInfo = roleInfo.items or {}
  self.deck:ReplaceByServer(roleInfo.pets)
  for _, card in ipairs(self.deck.cards) do
    local pet = self.team:GetPetByGuid(card.guid)
    if pet then
      pet:UpdateByCard(card)
    end
  end
end

function BattlePlayer:OverridesByServer(roleInfoOverrides)
  local prevRoleInfo = self.roleInfo
  local nextRoleInfo = BattlePlayer.DeriveRoleInfoFromOverrides(prevRoleInfo, roleInfoOverrides)
  self:SetRoleInfo(nextRoleInfo)
end

function BattlePlayer.DeriveRoleInfoFromOverrides(prevRoleInfo, roleInfoOverrides)
  local nextRoleInfo = {}
  table.copy(prevRoleInfo, nextRoleInfo)
  for key, value in pairs(roleInfoOverrides) do
    nextRoleInfo[key] = value
  end
  return nextRoleInfo
end

function BattlePlayer:DeriveRoleInfoWithPushPopData(nextRoleInfo)
  local baseInfo = nextRoleInfo and nextRoleInfo.base
  local roleUin = baseInfo and baseInfo.role_uin
  local battleInfoManager = _G.BattleManager.battleInfoManager
  local roleInfoData = battleInfoManager:GetBattleRoleInfoFromPushPopByUin(roleUin)
  return BattlePlayer.DeriveRoleInfoFromRoleInfoPushPopData(nextRoleInfo, roleInfoData)
end

function BattlePlayer.DeriveRoleInfoFromRoleInfoPushPopData(prevRoleInfo, roleInfoData)
  if nil == roleInfoData then
    return prevRoleInfo
  end
  local roleInfo = roleInfoData and roleInfoData.roleInfo or {}
  local nextRoleInfo = BattlePlayer.DeriveRoleInfoFromOverrides(prevRoleInfo, roleInfo)
  return nextRoleInfo
end

function BattlePlayer:RefreshItemByServer(itemInfo)
  for i = 1, #self.itemInfo do
    local clientItemInfo = self.itemInfo[i]
    if itemInfo.is_temp then
      if clientItemInfo.item_conf_id == itemInfo.item_conf_id then
        self.itemInfo[i] = itemInfo
        return
      end
    elseif clientItemInfo.gid == itemInfo.gid then
      self.itemInfo[i] = itemInfo
      return
    end
  end
  table.insert(self.itemInfo, itemInfo)
end

function BattlePlayer:GetCardByGuid(petGuid)
  return self.deck:GetCardByGuid(petGuid)
end

function BattlePlayer:IsEnemy()
  return self.teamEnm == BattleEnum.Team.ENUM_ENEMY
end

function BattlePlayer:IsObserver()
  return self.teamEnm == BattleEnum.Team.ENUM_OBSERVER
end

function BattlePlayer:IsSpectator()
  return BattleUtils.IsWatchingBattle()
end

function BattlePlayer:IsMyself()
  return self == _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
end

function BattlePlayer:IsTeammate()
  return self.teamEnm == BattleEnum.Team.ENUM_TEAM and not self:IsMyself()
end

function BattlePlayer:GetInBattleCards()
  return self.deck:GetInBattleCards()
end

function BattlePlayer:GetReservesPetCards()
  return self.deck:GetReservesPetCards()
end

function BattlePlayer:GetReservesPetInfos()
  local ret = {}
  local infos = _G.BattleManager.battleInfoManager:FindEnemyReversePetInfos(self.guid)
  if infos then
    for pet_id, info in pairs(infos) do
      table.insert(ret, info)
    end
  end
  return ret
end

function BattlePlayer:TryGetItemConfID(itemID)
  for _, v in ipairs(self.itemInfo) do
    if v.item_id == itemID then
      return v.item_conf_id
    end
  end
  return nil
end

function BattlePlayer:TryGetItem(itemConfID)
  for _, v in ipairs(self.itemInfo) do
    if v.item_conf_id == itemConfID then
      return v
    end
  end
  return nil
end

function BattlePlayer:UseItem(itemID, callbackOwner, completeCallback)
  self.itemID = itemID
  self.useItemComplete = completeCallback
  self.useItemCompleteOwner = callbackOwner
  if not self.model or not self.model.RocoSkill then
    self:OnUseItemEnd()
  end
  BattleResourceManager:LoadClassAsync(self, BattleConst.UseItem.SkillPath, self.OnClassLoad)
end

function BattlePlayer:OnClassLoad(skillClass)
  if not self.model then
    Log.Error("No model")
    self:OnUseItemEnd()
    return
  end
  local itemConf = _G.DataConfigManager:GetBattleItemConf(self.itemID)
  if not itemConf then
    Log.ErrorFormat("No item conf found %d", self.itemID)
    self:OnUseItemEnd()
    return
  end
  local itemPath = itemConf.model
  if not itemPath then
    Log.ErrorFormat("No item path found %d", self.itemID)
    self:OnUseItemEnd()
    return
  end
  local skillUseItem = self.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
  if not skillUseItem then
    UE4.UNRCStatics.DumpFClassDesc("ABP_BattleBasePlayer_C")
    self:OnUseItemEnd()
    Log.ErrorFormat("can't find use item skillobj")
    return
  end
  skillUseItem:SetDynamicData({ItemPath = itemPath})
  skillUseItem:SetCaster(self.model)
  skillUseItem:RegisterEventCallback("Start", self, self.OnUseItemStart)
  skillUseItem:RegisterEventCallback("PreEnd", self, self.OnUseItemEnd)
  skillUseItem:RegisterEventCallback("End", self, self.OnUseItemEnd)
  if self.teamEnm == BattleEnum.Team.ENUM_TEAM and self ~= BattleManager.battlePawnManager:GetPlayerMyTeam() then
    local actions = skillUseItem:GetAllActions()
    for i = 1, actions:Length() do
      local action = actions:Get(i)
      if action:IsA(UE4.URocoCameraAnimationAction) then
        action.m_Enable = false
      end
    end
  end
  self.model.RocoSkill:StopCurrentSkill()
  self:PlaySkillObject(skillUseItem)
end

function BattlePlayer:OnUseItemStart()
end

function BattlePlayer:OnUseItemEnd()
  local Callback = self.useItemComplete
  local Owner = self.useItemCompleteOwner
  if Callback then
    Callback(Owner)
  end
end

function BattlePlayer:PlaySkill(skillID, target, callbackOwner, completeCallback, extraParams, overrideCharacters, overrideTargets)
  Log.Debug("BattlePlayer:PlaySkill" .. skillID)
  local skillPath = skillID
  if type(skillID) == "number" then
    local SkillResConf = DataConfigManager:GetSkillResConf(skillID)
    skillPath = SkillResConf and SkillResConf.res_id
  end
  BattleResourceManager:LoadClassAsyncWithParam(self, skillPath, self.OnSkillClassLoad, nil, target, callbackOwner, completeCallback, extraParams, overrideCharacters, overrideTargets)
end

function BattlePlayer:OnSkillClassLoad(skillClass, target, callbackOwner, completeCallback, extraParams, overrideCharacters, overrideTargets)
  if not (skillClass and self.model) or not self.model.RocoSkill then
    Log.Error("Skill Class not found")
    if completeCallback then
      completeCallback(callbackOwner)
    end
    return nil
  end
  local skillObj = self.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
  if not skillObj then
    if completeCallback then
      completeCallback(callbackOwner)
    end
    return nil
  end
  extraParams = extraParams or {}
  extraParams.Caster = self.model
  skillObj:SetDynamicData(extraParams)
  local pawnManager = _G.BattleManager.battlePawnManager
  skillObj:SetCharacters(overrideCharacters or pawnManager:GetAllPawnActorForSkill())
  skillObj:SetTargets(overrideTargets or {
    target.model
  })
  skillObj:SetCaster(self.model)
  skillObj:RegisterEventCallback("End", callbackOwner, completeCallback)
  skillObj:RegisterEventCallback("PreEnd", callbackOwner, completeCallback)
  self:PlaySkillObject(skillObj)
  return skillObj
end

function BattlePlayer:PlaySkillObject(skill)
  return self.model.RocoSkill:LoadAndPlaySkill(skill)
end

function BattlePlayer:NeedSupplyPet()
  local capacity = self.team.capacity
  local battlePets = self.deck:GetBattleFieldAliveCards()
  local lackNumber = capacity - #battlePets
  return lackNumber > 0 and self:GetSummonNumber() > 0
end

function BattlePlayer:OnPetDead(deadPetCard)
  local roleInfo = self.roleInfo
  if self.roleInfo then
    local roleAddiInfo = roleInfo and roleInfo.role_addi_info
    self.roleInfo.role_addi_info.dead_pet_num = (self.roleInfo.role_addi_info.dead_pet_num or 0) + 1
    local petInfo = deadPetCard and deadPetCard.petInfo
    local petData = petInfo and petInfo.battle_common_pet_info
    local typeInfo = petData and petData.type
    local typeInfoType = typeInfo and typeInfo.type
    if typeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
      local nextDeadRandomPetNum = roleAddiInfo and roleAddiInfo.dead_random_pet_num or 0
      nextDeadRandomPetNum = nextDeadRandomPetNum + 1
      if roleAddiInfo then
        roleAddiInfo.dead_random_pet_num = nextDeadRandomPetNum
      end
    end
  end
end

function BattlePlayer:RefreshDeadPetNum()
  local deadPetNum = 0
  local deadRandomPetNum = 0
  for _, card in ipairs(self.deck.cards) do
    local isDead = card.petState and card.petState:GetDead()
    local petInfo = card.petInfo
    local petData = petInfo and petInfo.battle_common_pet_info
    local typeInfo = petData and petData.type
    local typeInfoType = typeInfo and typeInfo.type
    local isRandomPet = typeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM
    if isDead then
      deadPetNum = deadPetNum + 1
      if isRandomPet then
        deadRandomPetNum = deadRandomPetNum + 1
      end
    end
  end
  self:SetDeadPetNum(deadPetNum)
  self:SetDeadRandomPetCount(deadRandomPetNum)
end

function BattlePlayer:UpdateMagicInfo(magicInfo)
  local roleInfoOverrides = {}
  roleInfoOverrides.magic_op_info = magicInfo and magicInfo.magic_op_info
  roleInfoOverrides.magic_skill_info = magicInfo and magicInfo.magic_skill_info
  self:OverridesByServer(roleInfoOverrides)
end

function BattlePlayer:UpdateMagicOpInfo(magicOpInfo)
  local roleInfoOverrides = {}
  roleInfoOverrides.magic_op_info = magicOpInfo
  self:OverridesByServer(roleInfoOverrides)
end

function BattlePlayer:ClearMagicOpInfo()
  local roleInfoOverrides = {}
  local magicOpInfo = ProtoMessage:newBattleRoleMagicOpInfo()
  roleInfoOverrides.magic_op_info = magicOpInfo
  self:OverridesByServer(roleInfoOverrides)
end

function BattlePlayer:SetPetNum(value)
  if value then
    self.roleInfo.role_addi_info.pet_num = value
  end
end

function BattlePlayer:GetPetNum(value)
  if self.roleInfo and self.roleInfo.role_addi_info then
    return self.roleInfo.role_addi_info.pet_num or 0
  end
  return 0
end

function BattlePlayer:SetDeadPetNum(value)
  if value then
    self.roleInfo.role_addi_info.dead_pet_num = value
  end
end

function BattlePlayer:SetStateBit(value)
  if value and value > 0 then
    self.roleInfo.base.state_bit = value
  end
end

function BattlePlayer:GetStateBit(index)
  local move = index % 32
  return self.roleInfo.base.state_bit & 1 << move > 0
end

function BattlePlayer:GetSummonNumber()
  local summon = 0
  if self.roleInfo and self.roleInfo.role_addi_info then
    summon = (self.roleInfo.role_addi_info.pet_num or 0) - (self.roleInfo.role_addi_info.dead_pet_num or 0)
  end
  return summon
end

function BattlePlayer:GetHeadLookAtComponent()
  return self.model and self.model.BP_HeadLookAtComponent
end

function BattlePlayer:SetRandomPetCount(newValue)
  local roleInfo = self.roleInfo
  local roleAddiInfo = roleInfo and roleInfo.role_addi_info
  if roleAddiInfo then
    roleAddiInfo.random_pet_num = newValue
  end
end

function BattlePlayer:GetLiveRandomPetCount()
  local roleInfo = self.roleInfo
  local roleAddiInfo = roleInfo and roleInfo.role_addi_info
  local randomPetNum = roleAddiInfo and roleAddiInfo.random_pet_num or 0
  local deadRandomPetNum = roleAddiInfo and roleAddiInfo.dead_random_pet_num or 0
  return math.max(randomPetNum - deadRandomPetNum, 0)
end

function BattlePlayer:SetDeadRandomPetCount(newValue)
  local roleInfo = self.roleInfo
  local roleAddiInfo = roleInfo and roleInfo.role_addi_info
  if roleAddiInfo then
    roleAddiInfo.dead_random_pet_num = newValue
  end
end

function BattlePlayer:GetDeadRandomPetCount()
  local roleInfo = self.roleInfo
  local roleAddiInfo = roleInfo and roleInfo.role_addi_info
  local deadRandomPetNum = roleAddiInfo and roleAddiInfo.dead_random_pet_num or 0
  return deadRandomPetNum
end

function BattlePlayer:GetMaxPetLevel()
  local maxLevel = 0
  for _, p in ipairs(self.deck.cards) do
    maxLevel = math.max(maxLevel, p.lv)
  end
  return maxLevel
end

function BattlePlayer:GetCatchCount()
  if not self.roleInfo then
    return 0
  end
  if not self.roleInfo.base then
    return 0
  end
  return self.roleInfo.base.catch_counts
end

function BattlePlayer:SetLoadOver()
  self.isLoadedOver = true
end

function BattlePlayer:IsLoadOver()
  if self.model then
    return self.isLoadedOver and self.model.resourceLoaded
  else
    return self.isLoadedOver
  end
end

function BattlePlayer:DestroyDelay()
  BattleBudget:PushTask(self, self.Destroy)
end

function BattlePlayer:Destroy()
  if self.CompassSkill then
    self.CompassSkill:Destroy()
    self.CompassSkill:UnBindRef()
  end
  if self.BagSkill then
    self.BagSkill:Destroy()
    self.BagSkill:UnBindRef()
  end
  if self.CatchPetSkill then
    self.CatchPetSkill:Destroy()
    self.CatchPetSkill:UnBindRef()
  end
  if self.TakeBallSkill then
    self.TakeBallSkill:Destroy()
    self.TakeBallSkill:UnBindRef()
  end
  if self.TakeBallNoBlendSkill then
    self.TakeBallNoBlendSkill:Destroy()
    self.TakeBallNoBlendSkill:UnBindRef()
  end
  if self.RunAwaySkill then
    self.RunAwaySkill:Destroy()
    self.RunAwaySkill:UnBindRef()
  end
  if UE.UObject.IsValid(self.battlePlayerComponentsRef) then
    UnLua.Unref(self.battlePlayerComponentsRef)
  end
  self.battlePlayerComponentsRef = nil
  if self.battlePlayerComponents and UE4.UObject.IsValid(self.battlePlayerComponents) then
    if self.battlePlayerComponents.Reset then
      self.battlePlayerComponents:Reset()
    end
    if self.battlePlayerComponents.K2_DestroyActor then
      self.battlePlayerComponents:K2_DestroyActor()
    end
    self.battlePlayerComponents = nil
  end
  if self.model and UE4.UObject.IsValid(self.model) then
    if self.model.IsCopyLocalPlayer then
      local MeshComp = self.model:GetComponentByClass(UE4.USkeletalMeshComponent)
      if MeshComp then
        MeshComp:SetSkeletalMesh(nil, true)
      end
    end
    self:ClearSkill()
    self.model:OnBattlePlayerDestroyed(self)
  end
  self.model = nil
  self:ClearAllDelay()
  self.catchSkill = nil
  self.deck = nil
  Base.Destroy(self)
end

function BattlePlayer:ClearSkill()
  if self.model and UE4.UObject.IsValid(self.model) then
    SkillUtils.ClearSkillObj(self.model.RocoSkill)
    SkillUtils.ClearSkillObj(self.model.RocoSkillSub)
  end
end

function BattlePlayer:TakeBallWithCard(card, operateType)
  if card then
    self:TakeBall(BattleUtils.GetPetBallPath(card.petInfo.battle_common_pet_info), operateType)
  else
    Log.Warning("you haven't specified with a card")
  end
end

function BattlePlayer:TakeBallWithID(id, operateType)
  local ballConf = _G.DataConfigManager:GetBallConf(id or 0)
  if ballConf then
    Log.Debug("BattlePlayer:TakeBallWithID")
    local ModelConfig = _G.DataConfigManager:GetModelConf(ballConf.fx_source)
    if ModelConfig then
      if 104000 == id then
        self:TakeCompass(ModelConfig.path, operateType)
      else
        self:TakeBall(ModelConfig.path, operateType)
      end
    end
  else
    Log.WarningFormat("Can't find ball conf with %d", id or 0)
  end
end

function BattlePlayer:TakeBall(ballPath, operateType)
  local skillObj, swapSkillName
  self:ClearTakeItem()
  self:ClearTakeItemFromCompass()
  self:ClearTakeCompass()
  self:CancelCompassSkill()
  if operateType == BattleEnum.Operation.ENUM_CATCH then
    skillObj = self.CatchPetSkill
    swapSkillName = BattleConst.CatchPetNames.SwapBall
    self:ClearTakeBall()
  elseif operateType == BattleEnum.Operation.ENUM_CHANGE then
    if self.model and UE4.UObject.IsValid(self.model) then
      local animComponent = self.model:GetAnimComponent()
      if animComponent then
        local currentAnimName = animComponent:GetCurAnimName()
        if "HuanChongLoop" == currentAnimName then
          skillObj = self.TakeBallNoBlendSkill
          swapSkillName = BattleConst.TakeBallNoBlendNames.SwapBall
        else
          skillObj = self.TakeBallSkill
          swapSkillName = BattleConst.TakeBallNames.SwapBall
        end
      end
    end
    self:ClearTakeBall()
    self:ClearCatchBall()
  else
    Log.Error("OperateType\228\184\141\229\186\148\228\184\186\230\141\149\230\141\137\227\128\129\230\141\162\229\174\160\229\164\150\229\133\182\229\174\131\239\188\140\232\175\183\230\163\128\230\159\165\232\176\131\231\148\168\229\164\132")
    return
  end
  if not skillObj then
    Log.Warning("Can't find skillObj")
    return
  end
  Log.Warning("BattlePlayer:TakeBall ", ballPath, skillObj.CurrentBallPath, skillObj.Objects.Ball)
  if ballPath then
    self.RunAwaySkill:Toggle(false)
    if skillObj.Objects.Ball then
      if skillObj.CurrentBallPath ~= ballPath then
        skillObj:ClearCachedObjects()
        Log.DebugFormat("Will replace ball %s -> %s", skillObj.CurrentBallPath, ballPath)
        skillObj:SetDynamicParams({BallPath = ballPath})
        skillObj:InternalPlay(swapSkillName)
        skillObj.CurrentBallPath = ballPath
      else
        Log.Debug("Getting the same ball, skip")
      end
    else
      skillObj.CurrentBallPath = ballPath
      skillObj:SetDynamicParams({BallPath = ballPath})
      skillObj:Toggle(true)
    end
  else
    skillObj:Toggle(false)
  end
end

function BattlePlayer:RecallBall()
  self:ClearTakeItem()
  self:ClearTakeItemFromCompass()
  self:ClearTakeCompass()
  self:CancelCompassSkill()
  self:ClearCatchBall()
  self:ClearTakeBall()
end

function BattlePlayer:TakeItemWithID(id)
  local itemConf = _G.DataConfigManager:GetBattleItemConf(id or 0)
  if itemConf then
    if 104000 == id then
      self:TakeCompass(itemConf.model)
      self.lastTakenItemIsCompass = true
    else
      self:TakeItem(itemConf.model)
      self.lastTakenItemIsCompass = false
    end
  else
    Log.WarningFormat("Can't find bag item conf with %d", id or 0)
  end
end

function BattlePlayer:TakeItem(itemPath)
  local skillObj, swapSkillName
  if self.lastTakenItemIsCompass then
    skillObj = self.TakeItemFromCompassSkill
  else
    skillObj = self.TakeItemSkill
  end
  swapSkillName = BattleConst.TakeItemNames.SwapItem
  self:ClearCatchBall()
  self:ClearTakeBall()
  self:ClearTakeCompass()
  if itemPath then
    self.RunAwaySkill:Toggle(false)
    if skillObj.Objects.Item then
      if skillObj.CurrentItemPath ~= itemPath then
        skillObj:ClearCachedObjects()
        skillObj:SetDynamicParams({ItemPath = itemPath})
        skillObj:InternalPlay(swapSkillName)
        skillObj.CurrentItemPath = itemPath
      else
        Log.Debug("Getting the same item, skip")
      end
    else
      if skillObj.isPlaying then
        skillObj:Toggle(false)
      end
      skillObj.CurrentItemPath = itemPath
      skillObj:SetDynamicParams({ItemPath = itemPath})
      skillObj:Toggle(true)
    end
  else
    skillObj:Toggle(false)
  end
end

function BattlePlayer:TakeCompassWithID(id)
  local itemConf = _G.DataConfigManager:GetBattleItemConf(id or 0)
  if itemConf then
    self:TakeCompass(itemConf.model)
    self.lastTakenItemIsCompass = true
  else
    Log.WarningFormat("Can't find bag item conf with %d", id or 0)
  end
end

function BattlePlayer:TakeCompass(itemPath)
  local skillObj, swapSkillName
  skillObj = self.TakeCompassSkill
  swapSkillName = BattleConst.TakeCompassNames.SwapItem
  self:ClearCatchBall()
  self:ClearTakeBall()
  self:ClearTakeItem()
  self:ClearTakeItemFromCompass()
  if itemPath then
    self.RunAwaySkill:Toggle(false)
    if skillObj.Objects.Item then
      if skillObj.CurrentItemPath ~= itemPath then
        skillObj:ClearCachedObjects()
        skillObj:SetDynamicParams({ItemPath = itemPath})
        skillObj:InternalPlay(swapSkillName)
        skillObj.CurrentItemPath = itemPath
      else
        Log.Debug("Getting the same item, skip")
      end
    else
      if skillObj.isPlaying then
        skillObj:Toggle(false)
        skillObj:ClearCachedObjects()
      end
      skillObj.CurrentItemPath = itemPath
      skillObj:SetDynamicParams({ItemPath = itemPath})
      skillObj:Toggle(true)
    end
  else
    skillObj:Toggle(false)
  end
end

function BattlePlayer:EnableGravity(value)
  if not self.model or not UE4.UObject.IsValid(self.model) then
    return
  end
  if value then
    self.model.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Walking)
    self.model:SetIKEnable(true)
    self.model.IkOverride = true
  else
    self.model.CharacterMovement:DisableMovement()
    self.model:SetIKEnable(false)
    self.model.IkOverride = false
  end
end

function BattlePlayer:PinOnTheGround()
  if not self.model or not UE4.UObject.IsValid(self.model) then
    return
  end
  local pos = self.model:K2_GetActorLocation()
  local posNew = UE4.UNRCStatics.PinActorOnGround(nil, self.model, pos, self.model)
  Log.Debug("BattlePlayer:PinOnTheGround", posNew)
  self.model:K2_SetActorLocation(posNew, false, nil, false)
end

function BattlePlayer:PreparePlayerSkill(targets, needShow, callback)
  self:PrepareCompassSkill(needShow)
end

function BattlePlayer:CancelPlayerSkill(targets)
  self:CancelCompassSkill()
end

function BattlePlayer:PrepareCompassSkill(needShow)
  self.CompassSkill:Stop()
  self.CompassSkill:Toggle(needShow)
end

function BattlePlayer:CancelCompassSkill()
  if self.CompassSkill then
    self.CompassSkill:Stop()
    self.CompassSkill:Destroy()
  end
end

function BattlePlayer:ShowBag(needShow)
  if self.BagSkill then
    self.BagSkill:Toggle(false)
  end
end

function BattlePlayer:HoldBag(needHold)
  if needHold then
    self.RunAwaySkill:Toggle(false)
    self:ClearCatchBall()
    self:ClearTakeBall()
  end
end

function BattlePlayer:ClearCatchBall()
  self:ClearSkillCachedObjects(self.CatchPetSkill)
end

function BattlePlayer:ClearTakeCompass()
  self:ClearSkillCachedObjects(self.TakeCompassSkill)
end

function BattlePlayer:ClearTakeBall()
  self:ClearSkillCachedObjects(self.TakeBallSkill)
  self:ClearSkillCachedObjects(self.TakeBallNoBlendSkill)
end

function BattlePlayer:ClearTakeItemFromCompass()
  self:ClearSkillCachedObjects(self.TakeItemFromCompassSkill)
end

function BattlePlayer:ClearTakeItem()
  self:ClearSkillCachedObjects(self.TakeItemSkill)
end

function BattlePlayer:ClearSkillCachedObjects(skill)
  if skill then
    skill:Toggle(false)
    skill:ClearCachedObjects()
  else
    Log.Error("BattlePlayer:ClearSkillCachedObjects skill is nil")
  end
end

function BattlePlayer:RunAway(needRun)
  if needRun then
    self.BagSkill:Toggle(false)
    self:ClearCatchBall()
    self:ClearTakeBall()
    self:ClearTakeItem()
    self:ClearTakeItemFromCompass()
    self:ClearTakeCompass()
    self:CancelCompassSkill()
  end
  if self.RunAwaySkill then
    self.RunAwaySkill:Toggle(needRun)
  end
end

function BattlePlayer:StopAll(willChangePet, willCatchPet)
  if not UE4.UObject.IsValid(self.model) then
    return
  end
  self.BagSkill:Toggle(false)
  self.CatchPetSkill:Toggle(false)
  self.TakeBallSkill:Toggle(false)
  self.TakeBallNoBlendSkill:Toggle(false)
  self.RunAwaySkill:Toggle(false)
  self:ClearTakeItem()
  self:ClearTakeItemFromCompass()
  if not willChangePet then
    self.TakeBallSkill:ClearCachedObjects()
    self.TakeBallNoBlendSkill:ClearCachedObjects()
  end
  if not willCatchPet then
    self.CatchPetSkill:ClearCachedObjects()
  end
  self:ClearTakeCompass()
  self:CancelCompassSkill()
end

function BattlePlayer:Hide()
  if self.model then
    self.model:SetActorScale3D(_G.FVectorZero)
  end
end

function BattlePlayer:Show()
  if self.model then
    self.model:SetActorScale3D(_G.FVectorOne)
  end
end

function BattlePlayer:IsRoundDone(ignorePetIds)
  ignorePetIds = ignorePetIds or {}
  if self.opState ~= BattleEnum.Operation.ENUM_NONE then
    return true
  end
  local pets = self.team:GetPets()
  for i, v in pairs(pets) do
    local isIgnore = false
    for _, id in ipairs(ignorePetIds) do
      if v.guid == id then
        isIgnore = true
        break
      end
    end
    if not isIgnore and v.opState == BattleEnum.Operation.ENUM_NONE then
      return false
    end
  end
  return true
end

function BattlePlayer:GetItemsByType(itemType)
  local ret = {}
  for i, v in pairs(self.itemInfo) do
    if v.item_type == itemType then
      table.insert(ret, v)
    end
  end
  return ret
end

function BattlePlayer:ShowSkillPrediction()
  local pets = self.team:GetInBattlePets()
  if pets and pets[1] then
    local pet = pets[1]
    local info = BattleUtils.GetSkillPredictionByPlayer(pet)
    if info and self.battlePlayerComponents and info.no_show == false and info.npc_hint_mode ~= ProtoEnum.ShowType.ST_NO_HINT then
      self:UpdateSkillPrediction()
      if info.show_word then
        if not self.IsShowSkillPrediction then
          self.IsShowSkillPrediction = true
          local worldConfig = _G.DataConfigManager:GetAiWordConf(info.word_conf_id)
          if worldConfig and worldConfig.hint_info[info.word_conf_index + 1] then
            local wordInfo = worldConfig.hint_info[info.word_conf_index + 1]
            if wordInfo.string then
              self:UpdateDialogBox(wordInfo.string, "SkillPrediction")
              self:ShowDialogBox()
            end
            if wordInfo.action then
              if self.model and UE4.UObject.IsValid(self.model) then
                self.model:PlayAnimByName(wordInfo.action, 1, 0, 0, 0, 1, 0)
              end
            elseif wordInfo.emotion then
              self.BubbleComponent:Play(nil, wordInfo.emotion)
            end
          end
        end
      else
        self.battlePlayerComponents:ShowSkillPredictionUI()
      end
    end
  end
end

function BattlePlayer:UpdateSkillPrediction()
  local pets = self.team:GetInBattlePets()
  if pets and pets[1] then
    local pet = pets[1]
    local info = BattleUtils.GetSkillPredictionByPlayer(pet)
    if info and self.battlePlayerComponents and info.no_show == false and info.npc_hint_mode ~= ProtoEnum.ShowType.ST_NO_HINT then
      self:UpdateSkillPredictionByInfo(info)
    end
  end
end

function BattlePlayer:HideSkillPrediction()
  if self.battlePlayerComponents then
    self.battlePlayerComponents:HideSkillPredictionUI()
    if self:GetDialogBoxType() == "SkillPrediction" then
      self:HideDialogBox()
    end
  end
end

function BattlePlayer:UpdateSkillPredictionByInfo(info)
  self.battlePlayerComponents:UpdateSkillPredictionUI(info)
end

function BattlePlayer:ShowDialogBox()
  if self.battlePlayerComponents then
    self.battlePlayerComponents:ShowDialogBoxUI()
  end
end

function BattlePlayer:HideDialogBox()
  if self.battlePlayerComponents then
    self.battlePlayerComponents:HideDialogBoxUI()
  end
end

function BattlePlayer:UpdateDialogBox(text, type)
  if self.battlePlayerComponents then
    self.battlePlayerComponents:UpdateDialogBoxUI(text, type)
  end
end

function BattlePlayer:GetDialogBoxType()
  if self.battlePlayerComponents then
    return self.battlePlayerComponents:GetDialogBoxUIType()
  end
end

function BattlePlayer:TryShowThinking()
  if self.model and UE4.UObject.IsValid(self.model) and _G.BattleManager:CheckActiveState(BattleEnum.StateNames.WaitingOther) then
    self.model:ShowThinking()
  end
end

function BattlePlayer:TryShowSkillPrediction()
  if _G.BattleManager:CheckActiveState(BattleEnum.StateNames.RoundSelect) or _G.BattleManager:CheckActiveState(BattleEnum.StateNames.WaitingOther) then
    self:UpdateSkillPrediction()
    self:ShowSkillPrediction()
  end
end

function BattlePlayer:HideEmoji()
  if self.model and UE4.UObject.IsValid(self.model) then
    self.model:HideEmoji()
  end
end

function BattlePlayer:GetNpcID()
  return self.roleInfo.base.npc_id
end

function BattlePlayer:SetPlayerSkill(playerSkillPhase)
  self.playerSkillPhase = playerSkillPhase
end

function BattlePlayer:GetPlayerSkillPhase()
  return self.playerSkillPhase, self.PlayerSkillInfo
end

function BattlePlayer:GetPlayerSkillInfo()
  return self.PlayerSkillInfo
end

function BattlePlayer:GetPosInField()
  if not _G.BattleManager.vBattleField:IsBattleFieldConfValid() then
    Log.Error("zgx BattlePlayer:GetPosInField battleFieldConf is not valid")
    return
  end
  local TargetPlayerPos
  if self.teamEnm == BattleEnum.Team.ENUM_TEAM then
    TargetPlayerPos = _G.BattleManager.vBattleField.battleFieldConf.CurrentModePosInfo.TeamatePlayerPos
  else
    TargetPlayerPos = _G.BattleManager.vBattleField.battleFieldConf.CurrentModePosInfo.EnemyPlayerPos
  end
  if self.posInField <= TargetPlayerPos:Length() then
    return TargetPlayerPos:Get(self.posInField)
  else
    return TargetPlayerPos:Get(TargetPlayerPos:Length() - 1)
  end
end

function BattlePlayer:HasPet()
end

function BattlePlayer:IsRealPlayer()
  if not self.roleInfo then
    return false
  end
  return self.roleInfo.base.state_bit & 1 << ProtoEnum.BATTLER_BIT_TYPE.BT_BATTLER_HUMAN > 0
end

function BattlePlayer:SetIsCanUseSkill(_IsCanUseSkill)
  if not (not _IsCanUseSkill and BattleUtils:IsWorldLeaderFight()) or BattleUtils.GetWorldLeaderRewardCount() <= 1 then
    self.IsCanUseSkill = _IsCanUseSkill
    Log.Debug("zgx BattlePlayer:SetIsCanUseSkill", self.IsCanUseSkill)
  end
end

function BattlePlayer:AddSkillList(_SkillInfo)
  table.insert(self.SkillList, _SkillInfo)
end

function BattlePlayer:UpdateSkillListByServer(_SkillList)
  local isSame = true
  if #_SkillList == #self.SkillList then
    for i, Skill in ipairs(_SkillList) do
      if Skill.cast_skill.skill_id ~= self.SkillList[i].cast_skill.skill_id then
        isSame = false
        break
      end
    end
  else
    isSame = false
  end
  if not isSame then
    self:SetSkillList(_SkillList)
    _G.BattleEventCenter:Dispatch(BattleEvent.Resend_SkillList)
    self:ClearCalCuLusSkillList()
    self:AddCalCuLusSkillList()
  end
end

function BattlePlayer:SetSkillList(_SkillList)
  local SkillList = {}
  for i, Skill in ipairs(_SkillList) do
    table.insert(SkillList, Skill)
  end
  self.SkillList = SkillList
  _G.BattleEventCenter:Dispatch(BattleEvent.SkillListChangeUpdate, self.SkillList)
end

function BattlePlayer:GetSkillList()
  return self.SkillList
end

function BattlePlayer:ClearSkillList()
  table.clear(self.SkillList)
end

function BattlePlayer:ClearSkillListByIndex(Index)
  table.remove(self.SkillList, Index)
end

function BattlePlayer:AddCalCuLusSkillList()
  local wl_req_id = BattleNetManager:GetWlReqID()
  local SkillList = {}
  for i, Skill in ipairs(self.SkillList) do
    table.insert(SkillList, Skill)
  end
  table.insert(self.CalCultsSkillList, {wl_req_id = wl_req_id, SkillList = SkillList})
end

function BattlePlayer:ClearCalCuLusSkillList()
  table.clear(self.CalCultsSkillList)
end

function BattlePlayer:SetContinuousSkillSucceed(_ContinuousSkillSucceed)
  self.ContinuousSkillSucceed = _ContinuousSkillSucceed
end

function BattlePlayer:GetContinuousSkillSucceed()
  return self.ContinuousSkillSucceed
end

function BattlePlayer:SetFreeCatch(value)
  self.free_catch = value
end

function BattlePlayer:GetFreeCatch()
  return self.free_catch
end

function BattlePlayer:ChangeListToPreSuccess()
  local targetIndex = -1
  for i = #self.CalCultsSkillList, 1, -1 do
    if self.CalCultsSkillList[i].Success then
      targetIndex = i
      break
    end
  end
  if -1 == targetIndex then
    self:SetSkillList({})
    self:ClearCalCuLusSkillList()
  else
    self:SetSkillList(self.CalCultsSkillList[targetIndex].SkillList)
    self:ClearCalCuLusSkillList()
    self:AddCalCuLusSkillList()
  end
end

function BattlePlayer:RemoveCalCuLusSkillByWlReqId(wl_req_id)
  local successIndex = -1
  local removeIndex = -1
  for i = #self.CalCultsSkillList, 1, -1 do
    if self.CalCultsSkillList[i].Success and wl_req_id > self.CalCultsSkillList[i].wl_req_id then
      successIndex = i
      self:SetSkillList(self.CalCultsSkillList[i].SkillList)
      break
    else
      if wl_req_id == self.CalCultsSkillList[i].wl_req_id then
        removeIndex = i
      end
      table.remove(self.CalCultsSkillList, i)
    end
  end
  if -1 == successIndex then
    self:SetSkillList({})
    _G.BattleEventCenter:Dispatch(BattleEvent.Resend_SkillList)
    self:ClearCalCuLusSkillList()
  elseif removeIndex > successIndex + 1 then
    _G.BattleEventCenter:Dispatch(BattleEvent.Resend_SkillList)
    self:ClearCalCuLusSkillList()
    self:AddCalCuLusSkillList()
  end
end

function BattlePlayer:CalCuLusSkillSucceedUpdateSkillList(wl_req_id)
  local Index
  for i = #self.CalCultsSkillList, 1, -1 do
    if wl_req_id == self.CalCultsSkillList[i].wl_req_id then
      Index = i
      self.CalCultsSkillList[i].Success = true
      self:SetSkillList(self.CalCultsSkillList[i].SkillList)
    end
    if Index and i < Index then
      table.remove(self.CalCultsSkillList, i)
    end
  end
end

function BattlePlayer:GetSuitId()
  if self.FashionData and self.FashionData.suitConf then
    return self.FashionData.suitConf.id
  end
end

function BattlePlayer:IsAssistNpc()
  if not BattleUtils.IsNpcAssist() then
    return false
  end
  local playerTeams = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  if not playerTeams[1] then
    return false
  end
  return self == playerTeams[1].player
end

function BattlePlayer:HasNpcId()
  return 0 ~= self.roleInfo.base.npc_id
end

function BattlePlayer:IsSpecialNoPcSelfDead()
  return BattleUtils.IsSpecialNoPc() and self.teamEnm == BattleEnum.Team.ENUM_TEAM and not self:HasNpcId()
end

function BattlePlayer:PlayAnim(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  if self.model and UE4.UObject.IsValid(self.model) then
    return self.model:PlayAnimByName(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  end
end

function BattlePlayer:GetAnimComponent()
  if not self.model then
    return
  end
  if not self.model.GetAnimComponent then
    return
  end
  local AnimComp = self.model:GetAnimComponent()
  if AnimComp then
    return AnimComp
  end
  AnimComp = self.model:GetComponentByClass(UE4.URocoAnimComponent)
  return AnimComp
end

function BattlePlayer:StopAllMontage(BlendOut)
  local AnimComp = self:GetAnimComponent()
  if AnimComp and UE.UObject.IsValid(AnimComp) then
    return AnimComp:StopAllMontage(BlendOut or 0.1)
  end
  return false
end

function BattlePlayer:DoHeadMotion(MotionType)
  if not self.model then
    Log.Error("No view")
    return
  end
  if MotionType == Enum.HeadMotion.Nod and self.model.Event_Action_Yes then
    self.model:Event_Action_Yes()
  elseif MotionType == Enum.HeadMotion.Shake and self.model.Event_Action_No then
    self.model:Event_Action_No()
  elseif MotionType == Enum.HeadMotion.Lookup and self.model.Event_Action_Lookup then
    self.model:Event_Action_Lookup()
  end
end

function BattlePlayer:GetActorTransform()
  if self.model then
    return self.model:Abs_GetTransform()
  end
  return UE4.FTransform()
end

function BattlePlayer:GetActorLocation()
  if self.model then
    return self.model:Abs_K2_GetActorLocation()
  end
  return UE4.FVector(0, 0, 0)
end

function BattlePlayer:GetActorRotation()
  if self.model then
    return self.model:K2_GetActorRotation()
  end
  return UE4.FRotator(0, 0, 0)
end

function BattlePlayer:GetActorScale3D()
  if self.model then
    return self.model:GetActorScale3D()
  end
  return UE4.FVector(1, 1, 1)
end

function BattlePlayer:RefreshMagicItem(itemInfo)
  for i = 1, #self.itemInfo do
    local clientItemInfo = self.itemInfo[i]
    if clientItemInfo.item_id == itemInfo.item_id then
      clientItemInfo.num = itemInfo.num or clientItemInfo.num
      clientItemInfo.remain_use_cnt = itemInfo.remain_use_cnt or clientItemInfo.remain_use_cnt
      clientItemInfo.allow_use_cnt = itemInfo.allow_use_cnt or clientItemInfo.allow_use_cnt
      clientItemInfo.battle_use_time_max = itemInfo.battle_use_time_max or clientItemInfo.battle_use_time_max
      clientItemInfo.battle_use_time_remain = itemInfo.battle_use_time_remain or clientItemInfo.battle_use_time_remain
      break
    end
  end
end

function BattlePlayer:GetHalfHeight()
  if self.model and self.model.GetHalfHeight then
    return self.model:GetHalfHeight()
  end
  return 0
end

function BattlePlayer:IsRunAwayBattle()
  if self.roleInfo and self.roleInfo.base then
    local bit = self.roleInfo.base.state_bit or 0
    return bit & 1 << ProtoEnum.BATTLER_BIT_TYPE.BT_BATTLER_RUNAWAY > 0
  end
  return false
end

function BattlePlayer:RunAwayBattle(reason)
  if self.destroyed then
    return
  end
  if self.destroying then
    return
  end
  reason = reason or ProtoEnum.ZoneBattleRoleLeaveNotify.LeaveType.NORMAL_LEAVE
  local tip
  if ProtoEnum.ZoneBattleRoleLeaveNotify.LeaveType.NORMAL_LEAVE == reason and BattleUtils.IsFriendAssist() then
    tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("syn_battle_other_player_flee_tip", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "%s leave game")
  elseif ProtoEnum.ZoneBattleRoleLeaveNotify.LeaveType.HIGH_VALUE_OWNER_LEAVE == reason then
    tip = _G.DataConfigManager:GetLocalizationConf("Highvaluepet_Owner_Rule_Ownerdead").msg
  end
  if nil ~= tip then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(tip, self.roleInfo.base.name, self.roleInfo.base.name), 3)
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_LEAVE_GAME, self, true)
  if self.model then
    self.model:PlayGradualChangeFade(0, 1, 1, function()
      if self.destroyed then
        return
      end
      if self.destroying then
        return
      end
      self:SetWaterPlatformVisible(false)
      self:HidePlayer()
    end)
  else
    self:SetWaterPlatformVisible(false)
    self:HidePlayer()
  end
  local pets = BattleManager.battlePawnManager:GetCanSelectPetsByPlayer(self)
  if pets and #pets > 0 then
    for i, v in ipairs(pets) do
      v.model:PlayGradualChangeFade(0, 1, 1, function()
        if v.destroyed then
          return
        end
        if v.destroying then
          return
        end
        v:SetWaterPlatformVisible(false)
        v:OnRecall()
      end)
    end
  end
  for _, v in ipairs(self.components:Items()) do
    if v then
      v:Destroy()
    end
  end
  self.components:Clear()
end

function BattlePlayer:IsTriggerAppearance()
  local pets = BattleManager.battlePawnManager:GetCanSelectPetsByPlayer(self)
  if pets and #pets > 0 then
    for i, v in ipairs(pets) do
      if v.card.AppearancePath.HuanchongSuiId > 0 then
        return true
      end
    end
  end
  if self.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    local npcCfg = _G.DataConfigManager:GetNpcConf(self:GetNpcID())
    if npcCfg then
      local modelConfig = _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
      if modelConfig and not string.IsNilOrEmpty(modelConfig.battle_entry_anim_path) then
        return true
      end
    end
  end
  return false
end

function BattlePlayer:SetQuicklyCatchBall(value, changeCamera)
  self.QuicklyCatchBallId = value
  if changeCamera and BattleManager.vBattleField.battleCraneCamera then
    BattleManager.vBattleField.battleCraneCamera:ChangeToPlayerCatch(1, true, nil, nil, true)
  end
end

function BattlePlayer:ClearSendPlayerSpawnedDelay()
  if self.sendPlayerSpawnedDelay then
    _G.DelayManager:CancelDelay(self.sendPlayerSpawnedDelay)
    self.sendPlayerSpawnedDelay = nil
  end
end

function BattlePlayer:ClearSetDialogPosDelay()
  if self.setDialogPosDelay then
    _G.DelayManager:CancelDelay(self.setDialogPosDelay)
    self.setDialogPosDelay = nil
  end
end

function BattlePlayer:ClearAllDelay()
  self:ClearSendPlayerSpawnedDelay()
  self:ClearSetDialogPosDelay()
end

function BattlePlayer:GetFriendSeconds(uin)
  if self.roleInfo.base.fri_type_list then
    for _, friend in ipairs(self.roleInfo.base.fri_type_list) do
      if friend.uin == uin then
        return friend.friend_seconds
      end
    end
  end
  return 0
end

function BattlePlayer:GetName()
  return self.roleInfo.base.name
end

return BattlePlayer

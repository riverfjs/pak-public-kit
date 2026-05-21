local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local BattleSpectatorOutsidePetInfo = _G.MakeSimpleClass("BattleSpectatorOutsidePetInfo")

function BattleSpectatorOutsidePetInfo:Ctor(petData)
  self:UpdatePetData(petData)
end

function BattleSpectatorOutsidePetInfo:UpdatePetData(petData)
  self.petData = petData
  if petData then
    self.baseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id, true)
    if self.baseConf then
      self.npcConf = _G.DataConfigManager:GetNpcConf(self.baseConf.npc_id, true)
      if self.npcConf then
        self.modelConf = _G.DataConfigManager:GetModelConf(self.npcConf.model_conf, true)
      end
    end
  end
end

function BattleSpectatorOutsidePetInfo:IsValid()
  if not self.baseConf then
    return false
  end
  if not self.npcConf then
    return false
  end
  if not self.modelConf then
    return false
  end
  return true
end

function BattleSpectatorOutsidePetInfo:GetDebugInfo()
  if self.baseConf then
    return string.format("%d, %s", self.baseConf.id, self.baseConf.name)
  end
  if self.petData then
    return string.format("%d, %d", self.petData.base_conf_id, self.petData.conf_id)
  end
  if self.pet then
    return string.format("%d, %d", self.pet:DebugNPCNameAndID())
  end
  return string.format("invalid pet info")
end

function BattleSpectatorOutsidePetInfo:OnDestroyed()
  if self.pet then
    self.pet:SetVisibleForBattleOutsideReason(false)
    _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, self.pet:GetServerId())
  end
  self:TryClearExceptPet()
end

function BattleSpectatorOutsidePetInfo:GetNpcConfId()
  if self.npcConf then
    return self.npcConf.id
  end
  return nil
end

function BattleSpectatorOutsidePetInfo:GetPetHabitat()
  if self.modelConf then
    return self.modelConf.habitat_flag or Enum.HABITAT_FLAG.HAB_LAND
  end
  return Enum.HABITAT_FLAG.HAB_LAND
end

function BattleSpectatorOutsidePetInfo:InitPet(pet, location, bIsPlayerPet)
  if not pet then
    return
  end
  self.placeHolder = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ATriggerCapsule, UE4.FTransform(UE4.FQuat(), location, UE4.FVector(1, 1, 1)), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  local capsule = self.placeHolder.CollisionComponent
  if capsule and UE4.UObject.IsValid(capsule) then
    capsule:SetCapsuleSize(50, 60, false)
    capsule:SetCollisionResponseToChannel(UE4.ECollisionChannel.ECC_GameTraceChannel9, UE4.ECollisionResponse.ECR_Ignore)
    if _G.NRCModuleManager:DoCmd(_G.BattleSpectatorModuleCmd.GetCanDrawDebug) then
      self.placeHolder:SetActorHiddenInGame(false)
      capsule.ShapeColor = UE4.FColor(20, 200, 100, 200)
      capsule.LineThickness = 1
    end
  end
  self.pet = pet
  if not pet.serverData then
    pet.serverData = ProtoMessage:newActorInfo_Npc()
  end
  local serverData = pet.serverData
  if not serverData.npc_base then
    serverData.npc_base = ProtoMessage:newActorInfo_NpcBase()
  end
  local petData = self.petData
  local npcBase = serverData.npc_base
  npcBase.height = petData.height
  npcBase.weight = petData.weight
  npcBase.nature = petData.nature
  npcBase.mutation_type = petData.mutation_type
  npcBase.glass_info = petData.glass_info
  self:DisguiseForThrow(bIsPlayerPet)
  if pet.viewObj then
    self:OnViewShellReady(pet)
  else
    pet:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnViewShellReady)
  end
  
  function pet.SetVisibleForBattleReason()
  end
end

function BattleSpectatorOutsidePetInfo:DisguiseForThrow(bIsPlayerPet)
  local statusChangeInfo = ProtoMessage:newLogicStatusChangeInfo()
  statusChangeInfo.op_type = ProtoEnum.LogicStatusOpType.LSOT_ADD
  statusChangeInfo.changed_status.status = ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING
  local updatesStatusAction = ProtoMessage:newSpaceAct_UpdateActorLogicStatus()
  updatesStatusAction.change_info = {statusChangeInfo}
  self.pet:UpdateLogicStatus(updatesStatusAction)
  self.pet.customThrowType = Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
  self.pet.customAimDisplay = Enum.NPC_AIM_DISPLAY.NAD_WILD_PET
  if bIsPlayerPet then
    self.pet.customActorType = ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Pet
  else
    self.pet.customActorType = ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Scene
  end
end

function BattleSpectatorOutsidePetInfo:OnViewShellReady(npc)
  if not npc then
    return
  end
  if npc:HasListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnViewShellReady) then
    npc:RemoveEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnViewShellReady)
  end
  self:OnPetLoaded(npc)
end

function BattleSpectatorOutsidePetInfo:OnPetLoaded(pet)
  if self.placeHolder then
    self.placeHolder:K2_DestroyActor()
    self.placeHolder = nil
  end
  if not pet then
    return
  end
  local petHudComponent = pet.PetHUDComponent
  if petHudComponent then
    petHudComponent.bShouldShow = false
  end
  pet:LockAIForReason(true, false, _G.AIDefines.LockReason.BattleSpectator)
  pet:SetVisibleForBattleOutsideReason(false)
  local viewObj = pet.viewObj
  if viewObj and UE4.UObject.IsValid(viewObj) then
    local movementComp = viewObj.CharacterMovement
    if movementComp and UE4.UObject.IsValid(movementComp) then
      movementComp.GravityScale = 0
    end
  end
end

function BattleSpectatorOutsidePetInfo:CheckPetHabit()
  if self.bNeedWaterPlatform ~= nil then
    return
  end
  local habit = self:GetPetHabitat()
  if habit == Enum.HABITAT_FLAG.HAB_LAND or habit == Enum.HABITAT_FLAG.HAB_FLY then
    self.bNeedWaterPlatform = true
    Log.Debug("BattleSpectatorOutsidePetInfo:CheckPetHabit land or fly", self:GetDebugInfo(), habit)
    return
  end
  if not self.baseConf then
    self.bNeedWaterPlatform = true
    Log.Warning("BattleSpectatorOutsidePetInfo:CheckPetHabit no base config", self:GetDebugInfo())
    return
  end
  if 1 == self.baseConf.can_swim then
    self.bNeedWaterPlatform = false
  else
    self.bNeedWaterPlatform = true
  end
  Log.Debug("BattleSpectatorOutsidePetInfo:CheckPetHabit may swim", self:GetDebugInfo(), habit, self.baseConf.can_swim, self.bNeedWaterPlatform)
end

function BattleSpectatorOutsidePetInfo:GenerateWaterPlatform(class, surfaceIsWater, location)
  if not surfaceIsWater or not self.bNeedWaterPlatform then
    return
  end
  if not self.waterPlatform or not UE4.UObject.IsValid(self.waterPlatform) then
    self.waterPlatform = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(class, UE4.FTransform(UE4.FQuat(), location, UE4.FVector(1, 1, 1)), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  end
  if self.waterPlatform then
    self.waterPlatform:SetActorHiddenInGame(true)
  end
  self:AdjustPetHeight()
end

function BattleSpectatorOutsidePetInfo:AdjustPetInWater()
  if not self.pet then
    return
  end
  local model = self.pet.viewObj
  if not model then
    return
  end
  local characterMovementComp = model.CharacterMovement
  if not characterMovementComp then
    return
  end
  local halfHeight = self.pet:GetScaledHalfHeight()
  local location = model:K2_GetActorLocation()
  local _, waterDepth, hitResults = UE.URocoMapUtils.GetSurface(model, location, nil, nil, nil, UE.FVector(0, 0, -1))
  local petWaterDepth = halfHeight - characterMovementComp:GetSwimPosOffsetZ()
  local WaterHeight = hitResults.ImpactPoint.Z
  if 0 == waterDepth or waterDepth > petWaterDepth then
    location.Z = location.Z - petWaterDepth
    characterMovementComp:SetMovementMode(UE.EMovementMode.MOVE_Swimming)
    characterMovementComp:OverrideNextDefaultMovementMode(UE.EMovementMode.MOVE_Swimming)
    Log.Debug("BattleSpectatorOutsidePetInfo:AdjustPetInWater swim", self.baseConf.id, self.baseConf.name, waterDepth, petWaterDepth)
  else
    location.Z = WaterHeight - waterDepth + halfHeight + 0.5
    Log.Debug("BattleSpectatorOutsidePetInfo:AdjustPetInWater stand", self.baseConf.id, self.baseConf.name, waterDepth, petWaterDepth)
  end
  model:K2_SetActorLocation(location, false, nil, false)
end

function BattleSpectatorOutsidePetInfo:AdjustPetHeight()
  if not self.waterPlatform then
    return
  end
  local location = self.waterPlatform:Abs_K2_GetActorLocation()
  local halfHeight = self.pet:GetHalfHeight()
  location.Z = location.Z + halfHeight
  self.pet:SetActorLocation(location)
end

function BattleSpectatorOutsidePetInfo:ReadyForPreform(bSelfInBattle, surfaceIsWater)
  if self.bAlreadyPrepared then
    return
  end
  self.bAlreadyPrepared = true
  Log.Debug("BattleSpectatorOutsidePetInfo:ReadyForPreform", self:GetDebugInfo(), bSelfInBattle, surfaceIsWater, self.bNeedWaterPlatform)
  if surfaceIsWater and not self.bNeedWaterPlatform then
    self:AdjustPetInWater()
  end
  if self.pet then
    if not bSelfInBattle then
      self.pet:SetVisibleForBattleOutsideReason(true)
    end
    self.pet:ApplyCollision("BattleSpectatorPet")
    self.finalPosition = self.pet:GetActorLocation()
  end
end

function BattleSpectatorOutsidePetInfo:OnReconnect()
  self:OnDestroyed()
end

function BattleSpectatorOutsidePetInfo:TryClearExceptPet()
  if self.waterPlatform and UE4.UObject.IsValid(self.waterPlatform) then
    self.waterPlatform:K2_DestroyActor()
    self.waterPlatform = nil
  end
  if self.placeHolder and UE4.UObject.IsValid(self.placeHolder) then
    self.placeHolder:K2_DestroyActor()
    self.placeHolder = nil
  end
end

function BattleSpectatorOutsidePetInfo:ResetPetLocation()
  if self.pet and self.finalPosition then
    Log.Debug("BattleSpectatorOutsidePetInfo:ResetPetLocation", self:GetDebugInfo(), self.pet:GetActorLocation(), self.finalPosition)
    self.pet:SetActorLocation(self.finalPosition)
    self.pet:StopAllMontage(0.1)
  end
end

function BattleSpectatorOutsidePetInfo:SetOwner(player)
  if self.pet then
    UE4.UNRCStatics.SetActorOwner(self.pet.viewObj, player)
  end
  if self.waterPlatform then
    UE4.UNRCStatics.SetActorOwner(self.waterPlatform, player)
  end
end

function BattleSpectatorOutsidePetInfo:OnLeaveBattle(player)
  if not self.pet then
    return
  end
  self:SetOwner(player)
  self.pet:SetVisibleForBattleOutsideReason(true)
  local viewObj = self.pet.viewObj
  if viewObj then
    local bVisible = 0 == viewObj.hiddenFlag
    self.pet.visibility = bVisible
    viewObj:SetActorHiddenInGame(not bVisible)
  end
end

function BattleSpectatorOutsidePetInfo:OnPlayerVisibleChange(bVisible)
  if not self.pet then
    return
  end
  local viewObj = self.pet.viewObj
  if self.pet:IsVisibleForBattleOutsideReason() then
    self.pet.visibility = bVisible
    if viewObj then
      viewObj:SetActorHiddenInGame(not bVisible)
    end
  end
end

return BattleSpectatorOutsidePetInfo

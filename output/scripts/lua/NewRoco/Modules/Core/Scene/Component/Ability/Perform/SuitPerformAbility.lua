local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ResQueue = require("NewRoco.Utils.ResQueue")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local SuitPerformAbility = Base:Extend("SuitPerformAbility")
local MAX_CAST_TIME = 30

function SuitPerformAbility:Ctor(caster)
  self.caster = caster
  self.castTime = 0
  self.casterOriginRotation = nil
  self.skipPetBack = nil
  self.faceToFace = nil
  self.keepOriginSize = nil
end

function SuitPerformAbility:StartPerform(skillId, petBaseId, petServerId, mutationType, glassInfo, nature, ball_id)
  if self.petNpc and self.petNpc.isFake then
    Log.Error("SuitPerformAbility:StartPerform Previous fakeNpc not destroyed, destroy now")
    self.petNpc:Destroy()
    self.petNpc = nil
  end
  if self.LoadQueue or self:IsCasting() then
    self:InterruptPerform()
  end
  self.bInterrupted = false
  local skillInteractConf = _G.DataConfigManager:GetSkillInteractConf(skillId)
  if not skillInteractConf then
    return
  end
  self.skipPetBack = skillInteractConf.skip_pet_back
  self.faceToFace = skillInteractConf.face_to_face
  self.keepOriginSize = skillInteractConf.keep_origin_size
  local rpSkillResId = skillInteractConf.interact_skill_id
  if not rpSkillResId then
    return
  end
  local SkillResConf = _G.DataConfigManager:GetSkillResConf(rpSkillResId)
  local rpSkillResPath = SkillResConf and SkillResConf.res_id
  self.relaxSkillPath = rpSkillResPath
  if self.relaxSkillPath then
    if petServerId then
      local sceneNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, petServerId)
      if sceneNpc then
        self.petNpc = sceneNpc
        self.canChangePetInteraction = not self.caster.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_IDLE_RELAX)
        self:SetPetInteractionEnable(false)
        if self.caster and not self.caster.isLocal and self.petNpc:IsControlledByPlayer() then
          local petFriendTouchFormat = _G.LuaText.interactiontree_pet_friend_touch
          local casterName = self.caster.serverData and self.caster.serverData.base.name or ""
          local petName = self.petNpc.serverData and self.petNpc.serverData.base.name or ""
          local petFriendTouchTip = string.format(petFriendTouchFormat, casterName, petName)
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, petFriendTouchTip)
        end
        self:RegisterPetLeave()
        self:RegisterMoveEvent()
        self.petNpc.isFake = false
        self:StartG6()
        sceneNpc:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.SUIT_PERFORM)
      else
        Log.Error("SuitPerformAbility cant find sceneNpc by serverId ", petServerId)
      end
    elseif petBaseId then
      local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
      if PetBaseConf then
        self:RegisterMoveEvent()
        local npcId = PetBaseConf.npc_id
        self.LoadQueue = ResQueue(30)
        local playerPos = self.caster:GetActorLocation()
        local halfHeight = self.caster:GetScaledHalfHeight()
        local lookAtRotation = self.caster:GetActorRotation()
        local forwardVector = lookAtRotation:ToVector()
        forwardVector = forwardVector / forwardVector:Size()
        local petPos = playerPos + forwardVector * 50
        local position = ProtoMessage:newPosition()
        position.x = petPos.X
        position.y = petPos.Y
        position.z = playerPos.Z - halfHeight
        self.LoadQueue:InsertNPC("NPC", npcId, position, -lookAtRotation.Yaw)
        self.LoadQueue:StartLoad(self, self.OnLoadFakeNpc)
        self.fakeNpc = self.LoadQueue:Get("NPC")
        self.fakeNpc.DestroyModelOnCallbackIfNpcDestroyed = true
        self.petData = {
          mutation_type = mutationType,
          nature = nature,
          glass_info = glassInfo,
          base_conf_id = petBaseId,
          ball_id = ball_id or 0
        }
      end
    else
      Log.Error("SuitPerformAbility petBaseId and petServerId == nil")
    end
  end
end

function SuitPerformAbility:OnLoadFakeNpc(Queue, Success)
  if Success and self.caster and UE.UObject.IsValid(self.caster.viewObj) then
    self.fakeNpc = nil
    self.petNpc = Queue:Get("NPC")
    self.petNpc.isFake = true
    self.petNpc.serverData.npc_base.create_avatar_id = self.caster:GetServerId()
    PetMutationUtils.DoMutation(self.petNpc.viewObj, self.petData)
    if UE.UObject.IsValid(self.petNpc.viewObj) then
      self.petNpc.viewObj:SetActorEnableCollision(false)
      self.petNpc.viewObj.Mesh.BoundsScale = 5
    end
    self.LoadQueue = nil
    if self.caster and self.caster.IsMagicReplayActor and self.caster:IsMagicReplayActor() then
      _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqNpcSpawned, self.petNpc.viewObj, true)
    end
    self:StartG6()
  else
    if self.fakeNpc then
      self.fakeNpc:Destroy()
      self.fakeNpc = nil
    end
    self.LoadQueue:DoRelease()
    self.LoadQueue = nil
  end
end

function SuitPerformAbility:StartG6()
  if self.relaxSkillPath then
    local petBp = self.petNpc and self.petNpc.viewObj
    if nil ~= petBp then
      self:SetBlobShadowEnable(false)
      self.petOriginXfm = petBp:GetTransform()
      if petBp and petBp.Mesh then
        if not self.keepOriginSize then
          self.petOriginScale = petBp.Mesh:K2_GetComponentScale()
          UE.UNRCCharacterUtils.SetCharacterMeshScale(petBp, 1)
        end
        if not self.skipPetBack then
          self.petNpc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.SUIT_PERFORM)
          Log.Debug("[SuitPerform] StartG6 Hide(true) HiddenBits = ", petBp:GetHiddenBits())
        end
        petBp.IkOverride = false
      end
      if self.faceToFace then
        self.casterOriginRotation = self.caster:GetActorRotation()
        self.petNpc:FaceTo(self.caster)
        self.caster:FaceTo(self.petNpc)
      end
      if self.petNpc.AIComponent then
        self.petNpc.AIComponent:ForceLockForReason(true, false, _G.AIDefines.LockReason.SUIT_PERFORM)
      end
      self.petNpc:SetHeadLookAtActor(nil)
      self.petNpc.TurnComponent:StopTurn(AIDefines.ActionResult.Aborted, true)
      local targets = {petBp}
      self:CastG6AbilityAsync({}, targets, self.relaxSkillPath)
      self.castTime = 0
      self.state = ABEnum.AbilityState.Casting
      self.petNpc.PetHUDComponent:SetRenderStatus(false, MainUIModuleEnum.DisableHudOpSource.SuitPerform)
      return
    end
  end
  Log.Error("SuitPerformAbility:StartG6 Failed")
  self:FinishPerform()
end

function SuitPerformAbility:SetBlobShadowEnable(enable)
  if self.petNpc and UE.UObject.IsValid(self.petNpc.viewObj) then
    self.petNpc.viewObj:SetBlobShadowActive(enable)
  end
  if self.caster and UE.UObject.IsValid(self.caster.viewObj) then
    if self.caster.isLocal then
      self.caster.viewObj.bEnableBlobShadow = enable
    else
      self.caster.viewObj:SetBlobShadowActive(enable)
    end
  end
end

function SuitPerformAbility:Update(DeltaTime)
  if self:IsCasting() then
    if GlobalConfig.DebugSuitPerform then
      local playerLoc = self.caster.viewObj:K2_GetActorLocation()
      local playerFwd = self.caster.viewObj:GetActorForwardVector()
      UE.UKismetSystemLibrary.DrawDebugArrow(self.caster.viewObj, playerLoc, playerLoc + playerFwd * 100, 6, UE.FLinearColor(0, 1, 1, 1), 0, 3)
      local petLoc = self.petNpc.viewObj:K2_GetActorLocation()
      local petFwd = self.petNpc.viewObj:GetActorForwardVector()
      UE.UKismetSystemLibrary.DrawDebugArrow(self.caster.viewObj, petLoc, petLoc + petFwd * 100, 6, UE.FLinearColor(1, 0, 0, 1), 0, 3)
    end
    self.castTime = self.castTime + DeltaTime
    if self.castTime > MAX_CAST_TIME then
      Log.Warning("SuitPerformAbility Casting Time Over MAX_CAST_TIME ", self.castTime)
      self:InterruptPerform()
    end
  end
end

function SuitPerformAbility:OnSkillEvent(event)
  if "PetBack" == event then
    self:PlayPetBack()
    self.bInterrupted = true
  elseif "Interrupt" == event then
    if not self.bInterrupted then
      self:InterruptPerform()
    end
  elseif "End" == event then
    if self.skipPetBack then
      self:FinishPerform()
    elseif not self.bInterrupted then
      self:InterruptPerform()
    else
      self:FinishPerform()
    end
  end
end

function SuitPerformAbility:PlayPetBack()
  self:UnRegisterPetLeave()
  if self.petNpc and UE.UObject.IsValid(self.petNpc.viewObj) and not self.skipPetBack then
    if self.petNpc.isFake then
      local ballId = self.petData and self.petData.ball_id
      local petServerData = self.petNpc and self.petNpc.serverData
      local petInfo = petServerData and petServerData.pet_info
      if petInfo then
        petInfo.ball_id = ballId
      end
      self.petNpc.viewObj:FlyBackToPlayer()
      self.petNpc = nil
    else
      local petBp = self.petNpc.viewObj
      if not UE.UObject.IsValid(petBp) then
        Log.Debug("SuitPerformAbility:PlayPetBack Invalid petBp,Finish Directly")
        self:FinishPerform()
        return
      end
      petBp:SetActorHiddenInGame(true)
      Log.Debug("[SuitPerform] PlayPetBack Hide(true) HiddenBits = ", petBp:GetHiddenBits())
      if not self.keepOriginSize then
        UE.UNRCCharacterUtils.SetCharacterMeshScale(petBp, self.petOriginScale.X)
      end
      local endSkillPath = "/Game/ArtRes/Effects/G6Skill/SYH/G6_Suits_Relax_End.G6_Suits_Relax_End"
      local casterActor = self.caster.viewObj
      local skillComponent = casterActor.RocoSkill
      self.endSkillProxy = RocoSkillProxy.Create(endSkillPath, skillComponent)
      if not self.endSkillProxy then
        self:FinishPerform()
        return
      end
      local priority = _G.PriorityEnum.Local_Player_Logic
      if not self.caster.isLocal then
        priority = _G.PriorityEnum.Other_Player_Logic
      end
      self.endSkillProxy.Priority = priority
      self.endSkillProxy:SetCaster(casterActor)
      self.endSkillProxy:SetPassive(true)
      self.endSkillProxy:SetTargets({petBp})
      self.endSkillProxy:RegisterRawCallback(self, self.OnEndSkillEvent)
      self.endSkillProxy:RegisterEventCallback("PreStart", self, self.OnEndG6PreStart)
      self.endSkillProxy:RegisterEventCallback("ActivateFailed", self, self.OnEndG6Failed)
      self.endSkillProxy:RegisterEventCallback("ActivateSuccess", self, self.OnEndG6Success)
      self.endSkillProxy:PlaySkill(self, self.OnEndG6AbilityAsync)
    end
  else
    self:FinishPerform()
  end
end

function SuitPerformAbility:InterruptPerform()
  self:UnregisterMoveEvent()
  self:UnRegisterPetLeave()
  self.bInterrupted = true
  self:SetBlobShadowEnable(true)
  if self.LoadQueue then
    self.LoadQueue:DoRelease()
    self.LoadQueue = nil
  end
  if self.fakeNpc then
    self.fakeNpc:Destroy()
    self.fakeNpc = nil
  end
  self:CancelAsyncG6Ability()
  self:FinishG6Ability()
  self.caster:StopAllMontage(0.1)
  self.state = ABEnum.AbilityState.Finished
  self:SetPetInteractionEnable(true)
  if self.petNpc and self.petNpc.SetCollisionDisable then
    self.petNpc:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.SUIT_PERFORM)
  end
  self:ReleaseNpc()
  if self.caster.isLocal and self.caster.statusComponent then
    self.caster.statusComponent:ClearStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
  end
  self.caster.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_IDLE_RELAX)
  if self._delayId then
    _G.DelayManager:CancelDelayById(self._delayId)
    self._delayId = nil
  end
  self:RecoverPlayerStatus()
end

function SuitPerformAbility:FinishPerform(keepNpc)
  if self.petNpc and self.petNpc.SetCollisionDisable then
    self.petNpc:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.SUIT_PERFORM)
  end
  self:UnregisterMoveEvent()
  self:UnRegisterPetLeave()
  self:FinishG6Ability()
  self:FinishEndSkill()
  self.state = ABEnum.AbilityState.Finished
  self:SetPetInteractionEnable(true)
  self:SetBlobShadowEnable(true)
  if not keepNpc then
    self:ReleaseNpc()
  end
  if self.caster.isLocal and self.caster.statusComponent then
    self.caster.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
  end
  self.caster.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_IDLE_RELAX)
  if self._delayId then
    _G.DelayManager:CancelDelayById(self._delayId)
    self._delayId = nil
  end
  self:RecoverPlayerStatus()
end

function SuitPerformAbility:ReleaseNpc()
  if self.petNpc then
    self.petNpc:StopAllMontage(0.1)
    if self.petNpc.isFake then
      self.petNpc:Destroy()
    else
      local petBp = self.petNpc.viewObj
      if petBp then
        if not self.skipPetBack then
          petBp:K2_SetActorTransform(self.petOriginXfm, false, nil, true)
        end
        local detachKeepWorld = UE.EDetachmentRule.KeepWorld
        petBp:K2_DetachFromActor(detachKeepWorld, detachKeepWorld, detachKeepWorld)
        if not self.keepOriginSize then
          UE.UNRCCharacterUtils.SetCharacterMeshScale(petBp, self.petOriginScale.X)
        end
        self.petNpc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.SUIT_PERFORM)
        petBp:SetActorHiddenInGame(false)
        Log.Debug("[SuitPerform] ReleaseNpc Hide(false) HiddenBits = ", petBp:GetHiddenBits())
      end
      if self.petNpc.AIComponent then
        self.petNpc.AIComponent:ForceLockForReason(false, false, _G.AIDefines.LockReason.SUIT_PERFORM)
      end
      self.petNpc.PetHUDComponent:SetRenderStatus(true, MainUIModuleEnum.DisableHudOpSource.SuitPerform)
    end
    self.petNpc = nil
  end
end

function SuitPerformAbility:OnEndSkillEvent(event)
  if "Interrupt" == event then
  end
  if "End" == event then
    self:FinishPerform()
  end
end

function SuitPerformAbility:OnG6PreStart()
  local Blackboard = self.skillProxy.SkillObject:GetBlackboard()
  local casterXfm = self.caster.viewObj:GetTransform()
  Blackboard:SetValueAsTransform("Target", casterXfm)
  Blackboard:SetValueAsString("HavePet", "HavePet")
  if self.caster.IsMagicReplayActor and self.caster:IsMagicReplayActor() then
    Blackboard:SetValueAsString("VideoMagicMat", "VideoMagicMat")
  end
end

function SuitPerformAbility:OnEndG6PreStart()
  if self.endSkillProxy then
    local Blackboard = self.endSkillProxy.SkillObject:GetBlackboard()
    Blackboard:SetValueAsTransform("Target", self.petOriginXfm)
  else
    Log.Debug("[[SuitPerform] OnEndG6PreStart self.endSkillProxy == nil ")
  end
end

function SuitPerformAbility:OnCastG6Failed()
  self:FinishPerform()
end

function SuitPerformAbility:OnCastG6Success()
  self._delayId = DelayManager:DelaySeconds(0.5, function()
    self._delayId = nil
    if self.petNpc and UE.UObject.IsValid(self.petNpc.viewObj) then
      self.petNpc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.SUIT_PERFORM)
      Log.Debug("[SuitPerform] OnCastG6Success Hide(false) HiddenBits = ", self.petNpc.viewObj:GetHiddenBits())
    end
  end)
end

function SuitPerformAbility:OnEndG6AbilityAsync(skillProxy, result)
  self.endSkillProxy = nil
  self._endSkillObj = skillProxy.SkillObject
end

function SuitPerformAbility:OnEndG6Success()
end

function SuitPerformAbility:OnEndG6Failed()
  self:FinishPerform()
end

function SuitPerformAbility:FinishEndSkill()
  self.endSkillProxy = nil
  if self._endSkillObj then
    self._endSkillObj:UnregisterRawCallback(self, self.OnSkillEvent)
    self._endSkillObj = nil
  end
end

function SuitPerformAbility:RecoverPlayerStatus()
  if self.faceToFace and self.casterOriginRotation then
    if self.caster:IsInTogetherMove() then
      self.caster:SetActorRotation(self.casterOriginRotation)
    end
    self.casterOriginRotation = nil
  end
end

function SuitPerformAbility:OnPetLeave(Pet)
  self:UnRegisterPetLeave()
  if self.caster and self.caster.isLocal then
    local PetShareCancelTip = _G.LuaText.interactiontree_petshare_cancel
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, PetShareCancelTip)
  end
  self:InterruptPerform()
end

function SuitPerformAbility:RegisterPetLeave()
  if not self.petNpc then
    Log.Warning("PetNpc is not exist")
    return
  end
  self.petNpc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnPetLeave)
end

function SuitPerformAbility:UnRegisterPetLeave()
  if not self.petNpc then
    Log.Warning("PetNpc is not exist")
    return
  end
  self.petNpc:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnPetLeave)
end

function SuitPerformAbility:RegisterMoveEvent()
  local player = self.caster
  if player and player.isLocal then
    local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
    if playerModule then
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.OnInputMove)
    end
    _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_PET_CLOSE_INTERACT)
  end
end

function SuitPerformAbility:UnregisterMoveEvent()
  local player = self.caster
  if player and player.isLocal then
    local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
    if playerModule then
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
    end
    _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_PET_CLOSE_INTERACT)
  end
end

function SuitPerformAbility:OnInputMove()
  self:InterruptPerform()
end

function SuitPerformAbility:SetPetInteractionEnable(bEnable)
  if not self.canChangePetInteraction or not self.petNpc then
    return
  end
  local interactionComponent = self.petNpc and self.petNpc.InteractionComponent
  if interactionComponent then
    interactionComponent:SetInteractionEnable(bEnable, NPCModuleEnum.NpcInteractDisableFlag.ROLEPLAY)
  end
end

return SuitPerformAbility

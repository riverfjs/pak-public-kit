local SKILL_BEGIN_PATH = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Pet_Hide/NiZong_HuanHua.NiZong_HuanHua_C'"
local SKILL_END_PATH = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Pet_Hide/NiZong_HuanHua_End.NiZong_HuanHua_End_C'"
local Delegate = require("Utils.Delegate")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenActionBase")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local SkillSuccessFlag = UE.ESkillStartResult.Success
local HiddenActionMimic = Base:Extend("HiddenActionMimic")
local TraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
local debugColor_1 = UE4.FLinearColor(0, 1, 0, 1)
local debugColor_2 = UE4.FLinearColor(1, 1, 0, 1)
local DebugLevel = 0

function HiddenActionMimic:Ctor(mode)
  self.config_EnableMimicAttach = 1 == mode[1]
  self.config_EnableForceSignificance = 1 == mode[2]
end

function HiddenActionMimic:Init(comp)
  Base.Init(self, comp)
  self.spawnedMimicTarget = nil
  self.req_model = nil
  self.req_begin_skill = nil
  self.req_end_skill = nil
  self.begin_ret = Delegate()
  self.end_ret = Delegate()
  self.processing = false
  self.request_skip_begin_skill = false
  self.lockedMovement = false
  local model_id = self:GetConfigurationMimicModelId()
  local model_conf = _G.DataConfigManager:GetModelConf(model_id or 0, true)
  if model_conf then
    self.mimicPath = model_conf.path
    self.trailMode = model_conf.trampling_lawn_comp or Enum.TramplingLawnComp.TLC_NONE
  else
    self.mimicPath = nil
    self.trailMode = Enum.TramplingLawnComp.TLC_NONE
  end
  self.owner:AddEventListener(self, NPCModuleEvent.OnViewVisible, self.OnViewVisible)
  self.owner:AddEventListener(self, NPCModuleEvent.OnNpcMeshAdjusted, self.AdjustHeadWidgetOffset)
end

function HiddenActionMimic:Release()
  self.begin_ret:Invoke(AIDefines.ActionResult.Failed)
  self.begin_ret:Clear()
  self:AssureUnhidden(true)
  self:CleanupModel()
  self:CleanupEndSkill()
  self:CleanupBeginSkill()
  self.owner:RemoveEventListener(self, NPCModuleEvent.OnViewVisible, self.OnViewVisible)
  self.owner:RemoveEventListener(self, NPCModuleEvent.OnNpcMeshAdjusted, self.AdjustHeadWidgetOffset)
  Base.Release(self)
end

function HiddenActionMimic:GetConfigurationMimicModelId()
  local model_id
  local mutType = self.owner.serverData.npc_base.mutation_type
  if PetMutationUtils.GetMutationValue(mutType, _G.Enum.MutationDiffType.MDT_SHINING) then
    model_id = self.owner.config.shining_mimic_target
    if model_id and 0 ~= model_id then
      return model_id
    end
  end
  local RefreshContentConf = _G.DataConfigManager:GetNpcRefreshContentConf(self.owner.serverData.npc_base.npc_content_cfg_id, true)
  if RefreshContentConf then
    model_id = RefreshContentConf.mimic_target
  end
  if model_id and 0 ~= model_id then
    return model_id
  end
  model_id = self.owner.config.mimic_target
  if model_id and 0 ~= model_id then
    return model_id
  end
  if self.owner.config.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE then
    local petbase_conf = _G.DataConfigManager:GetPetbaseConf(self.owner.config.traverse_data_param[1], true)
    if petbase_conf then
      model_id = petbase_conf.mimic_target
    end
  end
  return model_id
end

function HiddenActionMimic:EnablePinToGround()
  return not self.config_EnableMimicAttach
end

local AttachKeepWorld = UE.EAttachmentRule.KeepWorld
local DettachKeepWorld = UE.EDetachmentRule.KeepWorld

function HiddenActionMimic:UpdateAttach()
  if not self.config_EnableMimicAttach then
    return
  end
  if self.spawnedMimicTarget then
    if self.comp.state == self.comp.State.PendingStart or self.comp.state == self.comp.State.Hidden then
      local OwnerPos = self.owner.viewObj:Abs_K2_GetActorLocation()
      if self.spawnedMimicTarget:Abs_K2_GetActorLocation():Dist(OwnerPos) > 100 then
        OwnerPos.Z = OwnerPos.Z - self.owner:GetScaledHalfHeight()
        self.spawnedMimicTarget:Abs_K2_SetActorLocation_WithoutHit(OwnerPos, false, false)
      end
      self.spawnedMimicTarget:K2_AttachToActor(self.owner.viewObj, nil, AttachKeepWorld, AttachKeepWorld, AttachKeepWorld, false)
    else
      self.spawnedMimicTarget:K2_DetachFromActor(DettachKeepWorld, DettachKeepWorld, DettachKeepWorld)
    end
  end
end

function HiddenActionMimic:OnHidden()
  if not self.mimicPath then
    Log.Warning("[HiddenActionMimic] \229\185\187\229\140\150\231\137\169\230\156\170\233\133\141\231\189\174", self.owner.config.id, self.owner.config.name)
    self.comp:EnterHidden(AIDefines.ActionResult.Failed)
    return
  end
  if self.req_model then
    return
  end
  self.begin_ret:Add(self.comp, self.comp.EnterHidden)
  self.req_model = _G.NRCResourceManager:LoadResAsync(self, self.mimicPath, PriorityEnum.Passive_World_NPC_Hidden_Mimic, 1, self.OnMimicObjLoad, self.OnHiddenFailed)
end

function HiddenActionMimic:OnMimicObjLoad(req, asset)
  if not (self.owner and asset) or self.req_model ~= req then
    return self:OnHiddenFailed()
  end
  local ownerTrans = self.owner:GetActorTransform()
  local halfHeight = self.owner:GetScaledHalfHeight()
  local OwnerPos = self.owner:GetActorLocation()
  local TraceEnd = OwnerPos - UE.FVector(0, 0, 500)
  local TraceBegin = OwnerPos + UE.FVector(0, 0, halfHeight)
  local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(self.owner.viewObj, TraceBegin, TraceEnd, TraceChannel, true, {
    self.spawnedMimicTarget
  }, DebugLevel, nil, true, debugColor_1, debugColor_2, 5)
  if Success then
    ownerTrans.Translation = Hit.ImpactPoint
    if self.config_EnableMimicAttach and math.abs(OwnerPos.Z - halfHeight - Hit.ImpactPoint.Z) > 20 then
      ownerTrans.Translation.Z = OwnerPos.Z - halfHeight
    end
  else
    Log.PrintScreenMsg("%s \229\144\140\229\173\166\228\188\188\228\185\142\229\156\168\233\171\152\229\164\132\229\185\187\229\140\150\228\186\134", self.owner.config.name)
  end
  local model = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(asset, ownerTrans, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.spawnedMimicTarget = model
  self.spawnedMimicTargetRef = UnLua.Ref(model)
  SceneUtils.NormNPCLightingChannels(model)
  if self.config_EnableMimicAttach then
    self.spawnedMimicTarget:K2_GetRootComponent():SetAbsolute(false, false, false)
    UE.UNRCStatics.MakeAllComponentsNeverAffectNav(self.spawnedMimicTarget)
  end
  self:UpdatePrimitiveIgnoreState(true)
  if self.request_skip_begin_skill then
    self:SetMimicVisible(true)
  else
    self:SetMimicVisible(false, true)
  end
  if model.resourceLoaded then
    self:OnMimicObjReady(model)
  else
    model:InitOutSceneAsync(self, self.OnMimicObjReady)
    model:SetActorHiddenInGame(true)
  end
end

function HiddenActionMimic:OnMimicObjReady(view)
  if self.trailMode ~= Enum.TramplingLawnComp.TLC_NONE then
    if self.config_EnableMimicAttach or self.trailMode == Enum.TramplingLawnComp.TLC_DYNAMIC then
      view:RegisterToTrailSystem(UE.ENRCTrailFootstepDetectType.RealTime)
    else
      view:RegisterToTrailSystem(UE.ENRCTrailFootstepDetectType.OneTime)
    end
  end
  view:SetActorHiddenInGame(false)
  if self.spawnedMimicTarget ~= view then
    view:UnLoadResource()
    self:OnHiddenFailed()
    return
  end
  local subItemVisibility = self.comp:SubItemVisibility()
  self.spawnedMimicTarget:SetVisible(subItemVisibility)
  self.spawnedMimicTarget:SetCollisionEnable(subItemVisibility)
  self.spawnedMimicTarget.sceneCharacter = self.owner
  if self.request_skip_begin_skill or not self.comp:SubItemVisibility() then
    self.request_skip_begin_skill = false
    self:SetMimicVisible(true)
    self:OnHiddenComplete()
    return
  else
    self:SetMimicVisible(false, true)
  end
  self.req_begin_skill = _G.NRCResourceManager:LoadResAsync(self, SKILL_BEGIN_PATH, PriorityEnum.Passive_World_NPC_Hidden_Mimic, -1, self.OnBeginSkillLoaded, self.OnHiddenFailed)
end

function HiddenActionMimic:OnBeginSkillLoaded(req, klass)
  if self.req_begin_skill ~= req then
    return self:OnHiddenFailed()
  end
  if self.request_skip_begin_skill then
    self.request_skip_begin_skill = false
    self:SetMimicVisible(true)
    self:OnHiddenComplete()
    return
  end
  if not self.owner.viewObj then
    self:OnHiddenFailed()
    return
  end
  local skillClass = klass
  local RocoSkill = self.owner.viewObj.RocoSkill
  local skillObj = self.owner.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if skillObj and skillObj.ClearDelegates then
    skillObj:ClearDelegates()
    skillObj:SetCaster(self.owner.viewObj):SetTargets({
      self.spawnedMimicTarget
    }):RegisterEventCallback("End", self, self.OnBeginSkillFinished):RegisterEventCallback("PreEnd", self, self.OnBeginSkillFinished):RegisterEventCallback("Interrupt", self, self.OnHiddenInterrupt):RegisterEventCallback("ActivateFailed", self, self.OnHiddenFailed)
    local result = RocoSkill:LoadAndPlaySkill(skillObj)
    if result ~= SkillSuccessFlag then
      self:OnHiddenFailed()
    else
      self.processing = true
    end
  else
    Log.PrintScreenMsg("[HiddenActionMimic:OnMimicObjLoad] skillObj invalid, actor=%d", self.owner.serverData.base.actor_id)
    self:OnHiddenFailed()
  end
end

function HiddenActionMimic:AssureHidden(imme)
  if not self.req_model then
    self.request_skip_begin_skill = imme
    self:OnHidden()
  end
  if imme then
    self:SetMimicVisible(true)
  end
end

function HiddenActionMimic:OnUnhidden()
  if not self.spawnedMimicTarget then
    self:LockMovement(false)
    self.comp:FinalizeHidden(AIDefines.ActionResult.Success)
    return
  end
  if not self.comp:SubItemVisibility() then
    self:SetMimicVisible(false)
    self:OnUnhiddenComplete()
    self.comp:FinalizeHidden(AIDefines.ActionResult.Success)
    return
  end
  if self.req_end_skill then
    return
  end
  self.req_end_skill = _G.NRCResourceManager:LoadResAsync(self, SKILL_END_PATH, PriorityEnum.Passive_World_NPC_Hidden_Mimic, -1, self.OnEndSkillLoaded, self.OnUnhiddenFailed)
end

function HiddenActionMimic:OnEndSkillLoaded(req, klass)
  if self.owner == nil then
    return
  end
  if self.req_end_skill ~= req then
    return
  end
  local skillClass = klass
  local targetObj = self.spawnedMimicTarget
  local RocoSkill = self.owner.viewObj.RocoSkill
  local skillObj = self.owner.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if skillObj then
    RocoSkill:StopCurrentSkill()
    skillObj:ClearDelegates()
    skillObj:SetCaster(targetObj):SetTargets({
      self.owner.viewObj
    }):RegisterEventCallback("End", self, self.OnEndSkillFinished):RegisterEventCallback("PreEnd", self, self.OnEndSkillFinished):RegisterEventCallback("Interrupt", self, self.OnUnhiddenInterrupt):RegisterEventCallback("ActivateFailed", self, self.OnUnhiddenFailed):RegisterEventCallback("ActivateSuccess", self, self.OnUnhiddenBegin)
    local result = RocoSkill:LoadAndPlaySkill(skillObj)
    if result ~= SkillSuccessFlag then
      self.comp:FinalizeHidden(AIDefines.ActionResult.Failed)
    else
      self.processing = true
      self:SetMimicCollision(false)
      self.end_ret:Add(self.comp, self.comp.FinalizeHidden)
    end
  else
    Log.Warning("HiddenActionMimic:OnUnhidden, skillObj invalid")
    self.comp:FinalizeHidden(AIDefines.ActionResult.Failed)
  end
end

function HiddenActionMimic:OnUnhiddenBegin()
  self:UpdateAttach()
end

function HiddenActionMimic:OnUnhiddenFailed()
  if self.comp then
    self.comp:FinalizeHidden(AIDefines.ActionResult.Failed)
  end
end

function HiddenActionMimic:AssureUnhidden(imme)
  if self.spawnedMimicTarget then
    if imme then
      self:SetMimicVisible(false)
      self.end_ret:Add(self.comp, self.comp.FinalizeHidden)
      self:OnUnhiddenComplete()
    else
      self:OnUnhidden()
    end
  end
end

function HiddenActionMimic:SetVisible(subItemVisibility, ownerVisibility)
  if self.spawnedMimicTarget and self.spawnedMimicTarget.SetVisible then
    self:SetMimicVisible(3 == self.comp.state, false)
    self.spawnedMimicTarget:SetVisible(subItemVisibility)
    self.spawnedMimicTarget:SetCollisionEnable(subItemVisibility)
  end
end

local HIDDEN_REASON = 4

function HiddenActionMimic:SetMimicVisible(flag, skipOwner, skipMimic)
  local mimicComp = not skipMimic and SceneUtils.GetActorMesh(self.spawnedMimicTarget) or nil
  if mimicComp then
    if self.spawnedMimicTarget.SetMimicVisibility then
      self.spawnedMimicTarget:SetMimicVisibility(flag)
    else
      mimicComp:SetHiddenInGame(not flag, true)
    end
    mimicComp:SetCollisionEnabled(flag and UE4.ECollisionEnabled.QueryAndPhysics or UE4.ECollisionEnabled.NoCollision)
    if flag then
      local halfHeight = self.owner:GetScaledHalfHeight()
      local OwnerPos = self.owner:GetActorLocation()
      local TraceEnd = OwnerPos - UE.FVector(0, 0, 500)
      local TraceBegin = OwnerPos + UE.FVector(0, 0, halfHeight)
      local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(self.owner.viewObj, TraceBegin, TraceEnd, TraceChannel, true, {
        self.spawnedMimicTarget,
        self.owner.viewObj
      }, DebugLevel, nil, true, debugColor_1, debugColor_2, 5)
      if Success then
        local targetPos = Hit.ImpactPoint
        if self.config_EnableMimicAttach and math.abs(OwnerPos.Z - halfHeight - targetPos.Z) > 20 then
          targetPos.Z = OwnerPos.Z - halfHeight
        end
        self.spawnedMimicTarget:SetActorLocation(targetPos)
      else
        OwnerPos.Z = OwnerPos.Z - halfHeight
        self.spawnedMimicTarget:SetActorLocation(OwnerPos)
      end
    end
  end
  local selfComp = not skipOwner and self.owner and SceneUtils.GetActorMesh(self.owner.viewObj) or nil
  if selfComp then
    UE.UNRCStatics.SetComponentHiddenInGame(selfComp, flag, true, UE.UShapeComponent, "SkillHit")
    self.owner:SetCollisionDisable(flag, HIDDEN_REASON)
    self:LockMovement(flag)
  end
end

function HiddenActionMimic:OnViewVisible(view)
  if self.owner then
    if self.comp.state == self.comp.State.Hidden or self.comp.state == self.comp.State.PendingEnd then
      self:SetMimicVisible(true)
    else
      self:SetMimicVisible(false)
    end
  end
end

function HiddenActionMimic:UpdatePrimitiveIgnoreState(shouldIgnore)
  local view = self.owner and self.owner.viewObj
  if view and UE.UObject.IsValid(view) then
    local ownerPrimitive = view:K2_GetRootComponent()
    if ownerPrimitive and ownerPrimitive:IsA(UE.UPrimitiveComponent) then
      ownerPrimitive:IgnoreActorWhenMoving(self.spawnedMimicTarget, shouldIgnore)
    end
  end
end

function HiddenActionMimic:LockMovement(lock)
  if not self.owner then
    return
  end
  if self.config_EnableMimicAttach then
    return
  end
  if lock == self.lockedMovement then
    return
  end
  self.lockedMovement = true
  local char = self.owner.viewObj
  if not char or not UE.UObject.IsValid(char) then
    return
  end
  if char.SetCharacterMovementTickEnabled then
    char:SetCharacterMovementTickEnabled(not lock, "HiddenActionMimic")
  else
    local moveComp = char.GetMovementComponent and char:GetMovementComponent() or nil
    if moveComp then
      moveComp:SetComponentTickEnabled(not lock)
    end
  end
end

function HiddenActionMimic:SetMimicCollision(flag)
  local mimicComp = SceneUtils.GetActorMesh(self.spawnedMimicTarget)
  if mimicComp then
    mimicComp:SetCollisionEnabled(flag and UE4.ECollisionEnabled.QueryAndPhysics or UE4.ECollisionEnabled.NoCollision)
  end
  if self.owner then
    self.owner:SetCollisionDisable(flag, HIDDEN_REASON)
  end
end

function HiddenActionMimic:ForceSignificance(enable)
  if not self.config_EnableForceSignificance then
    return
  end
  local view = self.owner and self.owner.viewObj
  local Significance = view and view:GetComponentByClass(UE.USignificanceComponent)
  if Significance then
    Significance:SelfControlSignificance(enable, UE.ESignificanceValue.Highest)
  end
end

function HiddenActionMimic:OnHiddenFailed()
  self.processing = false
  self:CleanupModel()
  self:CleanupBeginSkill()
  self.begin_ret:Invoke(AIDefines.ActionResult.Failed)
  self.begin_ret:Clear()
end

function HiddenActionMimic:OnBeginSkillFinished()
  self.processing = false
  self:OnHiddenComplete()
end

local XfmCache_Offset = UE.FTransform()

function HiddenActionMimic:OnHiddenComplete()
  local bEnterHide = false
  if self.comp then
    local curState = self.comp:GetState()
    if curState == self.comp.State.Hidden or curState == self.comp.State.PendingStart then
      bEnterHide = true
    end
  end
  self:SetMimicVisible(bEnterHide, false, not bEnterHide)
  self:ForceSignificance(bEnterHide)
  self:UpdateAttach()
  self:SetMimicCollision(bEnterHide)
  self:LockMovement(bEnterHide)
  self:AdjustHeadWidgetOffset()
  if not self.processing then
    self:CleanupBeginSkill()
  end
  self.begin_ret:Invoke(AIDefines.ActionResult.Success)
  self.begin_ret:Clear()
end

function HiddenActionMimic:OnHiddenInterrupt()
  self.processing = false
  self:OnHiddenComplete()
end

function HiddenActionMimic:OnUnhiddenFailed()
  self.processing = false
  self:CleanupEndSkill()
  self.end_ret:Invoke(AIDefines.ActionResult.Failed)
  self.end_ret:Clear()
end

function HiddenActionMimic:OnEndSkillFinished()
  self.processing = false
  self:OnUnhiddenComplete()
end

function HiddenActionMimic:OnUnhiddenComplete()
  local bLeaveHide = false
  if self.comp then
    local curState = self.comp:GetState()
    if curState == self.comp.State.Idle or curState == self.comp.State.PendingEnd then
      bLeaveHide = true
    end
  end
  self:SetMimicVisible(not bLeaveHide, false, bLeaveHide)
  self:ForceSignificance(not bLeaveHide)
  self:SetMimicCollision(not bLeaveHide)
  self:LockMovement(not bLeaveHide)
  local HudComp = self.owner and self.owner.PetHUDComponent
  if HudComp then
    HudComp:RestoreHeadWidgetLocation()
  end
  if bLeaveHide and not self.processing then
    self:CleanupModel()
    self:CleanupEndSkill()
  end
  self.end_ret:Invoke(AIDefines.ActionResult.Success)
  self.end_ret:Clear()
end

function HiddenActionMimic:OnUnhiddenInterrupt()
  self.processing = false
  self:OnUnhiddenComplete()
end

function HiddenActionMimic:CleanupModel()
  if self.req_model then
    self:UpdatePrimitiveIgnoreState(false)
    if self.spawnedMimicTarget then
      local actor = self.spawnedMimicTarget
      if UE.UObject.IsValid(self.spawnedMimicTargetRef) then
        UnLua.Unref(self.spawnedMimicTargetRef)
        self.spawnedMimicTargetRef = nil
      end
      self.spawnedMimicTarget = nil
      actor:SetSceneCharacter(nil)
      if self.trailMode ~= Enum.TramplingLawnComp.TLC_NONE then
        actor:UnRegisterFromTrailSystem()
      end
      actor:K2_DestroyActor()
    end
    local request = self.req_model
    self.req_model = nil
    _G.NRCResourceManager:UnLoadRes(request)
  end
  if self.spawnedMimicTarget then
    Log.Error("[HiddenActionMimic] \228\184\141\229\186\148\232\175\165\233\129\151\231\149\153\229\185\187\229\140\150\229\175\185\232\177\161")
  end
end

function HiddenActionMimic:CleanupBeginSkill()
  if self.req_begin_skill then
    local req = self.req_begin_skill
    self.req_begin_skill = nil
    _G.NRCResourceManager:UnLoadRes(req)
  end
end

function HiddenActionMimic:CleanupEndSkill()
  if self.req_end_skill then
    local req = self.req_end_skill
    self.req_end_skill = nil
    _G.NRCResourceManager:UnLoadRes(req)
  end
end

function HiddenActionMimic:OnVisibilityChange(visible)
  self:SetMimicVisible(visible and self.spawnedMimicTarget ~= nil, not visible)
end

function HiddenActionMimic:EnterBattle()
  if self.spawnedMimicTarget and self.spawnedMimicTarget.ChangeXray then
    self.spawnedMimicTarget:ChangeXray(false)
  end
end

function HiddenActionMimic:LeaveBattle()
  if self.spawnedMimicTarget and self.spawnedMimicTarget.ChangeXray then
    self.spawnedMimicTarget:ChangeXray(true)
  end
end

function HiddenActionMimic:AdjustHeadWidgetOffset()
  local HudComp = self.owner and self.owner.PetHUDComponent
  if HudComp then
    local mimicObj = self.spawnedMimicTarget
    if mimicObj and mimicObj.GetHeadWidgetOffsetInplace and mimicObj:GetHeadWidgetOffsetInplace(XfmCache_Offset) then
      XfmCache_Offset.Translation.Z = XfmCache_Offset.Translation.Z - self.owner:GetScaledHalfHeight()
      HudComp:SetHeadWidgetTransform(XfmCache_Offset, true, false)
    end
  end
end

return HiddenActionMimic

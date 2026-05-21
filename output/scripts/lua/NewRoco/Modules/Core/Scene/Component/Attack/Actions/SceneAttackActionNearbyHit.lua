local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = require("NewRoco.Modules.Core.Scene.Component.Attack.SceneAttackBase")
local SceneAttackActionNearbyHit = Base:Extend("SceneAttackActionNearbyHit")
local GS_SceneBattle_Path = "/Game/ArtRes/Effects/G6Skill/SceneBattle/GS_SceneBattle"
local GS_SceneBattle_Path_Full = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneBattle/GS_SceneBattle.GS_SceneBattle_C'"
local FX_Hit_Path = "NiagaraSystem'/Game/ArtRes/Effects/Particle/Common/Perception/NS_Perception_Hit01.NS_Perception_Hit01'"
local SOUND_ID_HIT = 70000201
local TickingHitBox = true

function SceneAttackActionNearbyHit:Ctor()
  Base.Ctor(self)
  self.target = nil
  self.hitbox = nil
  self.hitActors = {}
  MakeWeakTable(self.hitActors)
  self.prevEnableCanStandOnWaterSurface = false
  self.prevEnableCanStandUnderWater = false
  self.prevEnableMovementTick = false
  self.prevMovementMode = nil
  self.prevCustomMovementMode = nil
  self.preProcessed = false
  self.wasInterrupted = false
end

function SceneAttackActionNearbyHit:Init(inComp)
  self.comp = inComp
  self.owner = inComp.owner
  self:Release()
  self.preloadCount = 2
  self.attackSkillClassRequest = NRCResourceManager:LoadResAsync(self, GS_SceneBattle_Path_Full, inComp.ResourcePriority, 10, self.Loaded, self.LoadFailed)
  self.hitFxRequest = NRCResourceManager:LoadResAsync(self, FX_Hit_Path, inComp.ResourcePriority, 10, self.Loaded, self.LoadFailed)
end

function SceneAttackActionNearbyHit:Release()
  if self.attackSkillClassRequest then
    self.attackSkillClassRequest.asset = nil
    NRCResourceManager:UnLoadRes(self.attackSkillClassRequest)
    self.attackSkillClassRequest = nil
  end
  if self.hitFxRequest then
    self.hitFxRequest.asset = nil
    NRCResourceManager:UnLoadRes(self.hitFxRequest)
    self.hitFxRequest = nil
  end
end

function SceneAttackActionNearbyHit:Loaded(request, asset)
  request.asset = asset
  request.assetRef = asset and UnLua.Ref(asset)
  self.preloadCount = self.preloadCount - 1
  if 0 == self.preloadCount then
    self.comp:LoadFinished(true)
  end
end

function SceneAttackActionNearbyHit:LoadFailed(request, msg)
  self.comp:LoadFinished(false)
end

function SceneAttackActionNearbyHit:OnStart(target, hitbox)
  local view = self.owner.viewObj
  local hitboxPos = hitbox:K2_GetActorLocation()
  local selfPos = view:K2_GetActorLocation()
  local dir = hitboxPos - selfPos
  local dist = dir:Size()
  dir:Normalize()
  local fixdir = dir * 35
  dir = dir * math.clamp(dist, 10, 600)
  local targetPos = selfPos + dir
  hitbox:K2_SetActorLocation(targetPos, false, nil, false)
  table.clear(self.hitActors)
  local curr_hitboxPos = hitbox:K2_GetActorLocation()
  local _, isBlocked = UE4.UKismetSystemLibrary.LineTraceSingle(view, selfPos, targetPos, UE.ETraceTypeQuery.AirWall, false, nil, UE.EDrawDebugTrace.None, nil, true)
  if isBlocked then
    Log.PrintScreenMsg("AttackActionNearbyHit: airwall")
    return false
  end
  self.hitbox = hitbox
  local skillClass = self.attackSkillClassRequest and self.attackSkillClassRequest.asset
  if not skillClass then
    Log.PrintScreenMsg("AttackActionNearbyHit: no asset loaded")
    return false
  end
  self.prevRot = view:K2_GetActorRotation()
  local skillObj = view.RocoSkill:FindOrAddSkillObj(skillClass)
  if skillObj and skillObj.SetCaster then
    skillObj:ClearDelegates()
    skillObj:SetCaster(view):SetTargets({hitbox}):RegisterEventCallback("End", self, self.OnEnd):RegisterEventCallback("PreEnd", self, self.OnEnd):RegisterEventCallback("PreEndAnim", self, self.OnEnd):RegisterEventCallback("Interrupt", self, self.OnEnd):RegisterEventCallback("TriggerBeHit", self, self.AttackHitEvent)
    local result = self.owner.viewObj.RocoSkill:LoadAndPlaySkill(skillObj)
    if result == UE.ESkillStartResult.Success then
      if TickingHitBox then
        UpdateManager:Register(self)
      end
      self:PreProcess()
      return true
    else
      Log.Warning("SceneAttackActionNearbyHit:OnStart, PlaySkillFailed", result)
    end
  else
    Log.Warning("SceneAttackActionNearbyHit:OnStart, SkillObj Init Failed", GS_SceneBattle_Path)
  end
  return false
end

function SceneAttackActionNearbyHit:PreProcess()
  local view = self.owner.viewObj
  if view:IsA(UE.ANPCBaseCharacter) then
    self.prevEnableCanStandOnWaterSurface = view:GetCanStandOnWaterSurface()
    self.prevEnableCanStandUnderWater = view:GetCanStandUnderWater()
    local moveComp = view:GetMovementComponent()
    self.prevEnableMovementTick = moveComp:IsComponentTickEnabled()
    self.prevMovementMode = moveComp.MovementMode
    self.prevCustomMovementMode = moveComp.CustomMovementMode
    view:EnableCanStandOnWaterSurface(true)
    view:EnableCanStandUnderWater(true)
    moveComp:SetComponentTickEnabled(false)
    self.preProcessed = true
  end
  if self.owner.SetCollisionDisable then
    self.owner:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.AI_MOVING)
  end
end

function SceneAttackActionNearbyHit:PostProcess()
  if not self.preProcessed then
    return
  end
  local view = self.owner.viewObj
  if view and view:IsA(UE.ANPCBaseCharacter) then
    view:EnableCanStandOnWaterSurface(self.prevEnableCanStandOnWaterSurface or false)
    view:EnableCanStandUnderWater(self.prevEnableCanStandUnderWater or false)
    local moveComp = view:GetMovementComponent()
    moveComp:SetComponentTickEnabled(self.prevEnableMovementTick or false)
    if self.wasInterrupted then
      moveComp:SetMovementMode(UE.EMovementMode.MOVE_Walking, UE.ERocoCustomMovementMode.MOVE_N)
    elseif self.prevMovementMode ~= nil then
      local prevMode = self.prevMovementMode
      local prevCustom = self.prevCustomMovementMode or UE.ERocoCustomMovementMode.MOVE_N
      local isFlying = prevMode == UE.EMovementMode.MOVE_Flying or prevMode == UE.EMovementMode.MOVE_Custom and prevCustom == UE.ERocoCustomMovementMode.MOVE_Hovering
      if isFlying then
        moveComp:SetMovementMode(prevMode, prevCustom)
      end
    end
  end
  self.wasInterrupted = false
  self.prevMovementMode = nil
  self.prevCustomMovementMode = nil
  self.preProcessed = false
end

function SceneAttackActionNearbyHit:AttackHitEvent()
  if not self.owner or not self.hitbox then
    return
  end
  local hitboxPos = self.hitbox:Abs_K2_GetActorLocation()
  local hit = false
  local overlapSceneActors = self.hitbox:GetOverlapSceneActors()
  for _, sceneActor in ipairs(overlapSceneActors) do
    if not table.contains(self.hitActors, sceneActor) then
      if self.comp:OnHit(sceneActor) then
        hit = true
        Log.Debug("AttackComponent:OnHit [SceneAttackActionNearbyHit] success, from: ", self.owner.config.name)
        _G.NRCAudioManager:PlaySound3DAtLocationAuto(SOUND_ID_HIT, self.owner:GetActorLocation())
        local hitFx = self.hitFxRequest and self.hitFxRequest.asset
        if hitFx then
          local rotation = UE4.FRotator()
          local FxManager = UE.UFXManager.Get()
          if FxManager then
            local World = _G.UE4Helper.GetCurrentWorld()
            local RelPos = UE.UNRCStatics.AbsoluteToRelative(hitboxPos, World)
            FxManager.SpawnFXAtLocation(World, hitFx, UE4.UKismetMathLibrary.MakeTransform(RelPos, rotation, _G.UE4Helper.OneVector))
          end
        end
      elseif sceneActor ~= self.owner then
        sceneActor:SendEvent(NPCModuleEvent.BE_ATTACKED, self.owner)
      end
      table.insert(self.hitActors, sceneActor)
    end
  end
  if GlobalConfig.DebugLuaBTree then
    local radius = self.comp.AttackParam.Radius
    local target = self.comp.AttackParam.Target
    if target then
      UE4.UKismetSystemLibrary.Abs_DrawDebugArrow(self.owner.viewObj, target:GetActorLocation(), hitboxPos, 10, UE4.FLinearColor(1, 1, 1), 1, 1)
    end
    if hit then
      UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(self.owner.viewObj, hitboxPos, radius, 10, UE4.FLinearColor(1.0, 0.1, 0.1), 1, 1)
    else
      UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(self.owner.viewObj, hitboxPos, radius, 10, UE4.FLinearColor(0.1, 1.0, 0.1), 1, 1)
    end
  end
end

local debugColor_1 = UE4.FLinearColor(0, 1, 0, 1)
local debugColor_2 = UE4.FLinearColor(1, 1, 0, 1)
local traceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)

function SceneAttackActionNearbyHit:OnTick(deltaTime)
  if not (self.owner and self.comp) or not self.comp:IsAttacking() then
    UpdateManager:UnRegister(self)
    return
  end
  local view = self.owner.viewObj
  if not view then
    return
  end
  local vel = 0
  local moveComp = view:GetMovementComponent()
  vel = moveComp and moveComp.Velocity or UE4Helper.ZeroVector
  local velSize = vel:Size2D()
  if velSize < 10 then
    return
  end
  local debugType = GlobalConfig.DebugLuaBTree and 3 or 0
  local selfPos = self.owner:GetActorLocation()
  local selfFwd = self.owner:GetForwardVector()
  selfFwd = selfFwd * math.clamp(velSize * deltaTime * 3, self.owner:GetScaledRadius(), 150)
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(view, selfPos, selfPos + selfFwd, traceChannel, false, nil, debugType, nil, true, debugColor_1, debugColor_2, 3)
  if isHit then
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      local hitPos = hitResult.ImpactPoint
      local hitNor = hitResult.ImpactNormal
      self.owner:SendEvent(NPCModuleEvent.BE_COLLIDE_WHILE_ATTACK, hitPos, hitNor)
      UpdateManager:UnRegister(self)
      break
    end
  end
end

function SceneAttackActionNearbyHit:OnEnd()
  if TickingHitBox then
    UpdateManager:UnRegister(self)
  end
  if self.owner == nil then
    return
  end
  if self.owner.SetCollisionDisable then
    self.owner:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.AI_MOVING)
  end
  self:PostProcess()
  self:Release()
  self.hitbox = nil
  self.comp:ActEnd()
  Base.OnEnd(self)
end

function SceneAttackActionNearbyHit:OnInterrupt()
  self.wasInterrupted = true
  if self.attackSkillClassRequest and not self.owner.isDestroy and UE.UObject.IsValid(self.owner.viewObj) then
    local RocoSkill = self.owner.viewObj.RocoSkill
    local skillObj = RocoSkill:FindSkillObj(self.attackSkillClassRequest.asset)
    if skillObj and UE.UObject.IsValid(skillObj) then
      if self.owner.StopAllMontage then
        self.owner:StopAllMontage(0.05)
      end
      if self.owner.SetCollisionDisable then
        self.owner:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.AI_MOVING)
      end
      RocoSkill:CancelSkill(skillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
      self:ResetRotation()
      return
    end
  end
  self:ResetRotation()
  self:OnEnd()
end

function SceneAttackActionNearbyHit:ResetRotation()
  if self.prevRot and self.owner and not self.owner.isDestroy then
    self.owner.viewObj:K2_SetActorRotation(self.prevRot, false)
    self.prevRot = nil
  end
end

return SceneAttackActionNearbyHit

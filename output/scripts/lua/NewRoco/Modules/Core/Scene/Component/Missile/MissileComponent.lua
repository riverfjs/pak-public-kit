local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local WorldCombatSkillComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local Base = ActorComponent
local MissileComponent = Base:Extend("MissileComponent")

function MissileComponent:Ctor()
  Base.Ctor(self)
  self.launchedDuration = 0
  self.nextLandHeight = 0
end

function MissileComponent:Update(deltaTime)
  if self.target ~= nil then
    self.targetPos = self.target:GetActorLocation()
  end
end

function MissileComponent:Attach(owner, module)
  Base.Attach(self, owner)
  self.module = module or NRCModuleManager:GetModule("MissileModule")
  self.timerIds = {}
end

function MissileComponent:InitMissileData(caster, target, targetPos, skillId, actionIdx, data, initPos, initDir)
  self.caster = caster
  self.target = target
  if nil == targetPos and target then
    self.targetPos = target:GetActorLocation()
  else
    self.targetPos = targetPos
  end
  self.skillId = skillId
  self.actionIdx = actionIdx
  self.data = data
  self.speed = data.InitSpeed
  self.logicPos = initPos
  self.logicDir = initDir
  self.initHeight = data.LandHeight or 0
  if _G.WorldCombatModuleCmd and _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInOfflineMode) then
    local CasterBase = self:GetCasterLandPos()
    if CasterBase then
      self.initHeight = math.min(self.logicPos.Z - CasterBase.Z, 170)
    else
      Log.Error("Can't find land pos")
    end
  end
end

function MissileComponent:OnSetViewObj()
  Base.OnSetViewObj(self)
  if self.owner.viewObj.CharacterMovement then
    self.owner.viewObj.CharacterMovement:SetComponentTickEnabled(false)
    self.owner.viewObj.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    self.owner.viewObj.CharacterMovement:DisableMovement()
  end
end

function MissileComponent:GetMissileHeight()
  local View = self.owner and self.owner.viewObj
  local ViewWorld = View and View:GetWorld()
  return SceneUtils.GetPosInLand(self.logicPos, nil, nil, nil, nil, nil, nil, nil, nil, true, ViewWorld) or self.logicPos
end

function MissileComponent:GetCasterLandPos()
  if self.caster then
    local View = self.caster and self.caster.viewObj
    local ViewWorld = View and View:GetWorld()
    if ViewWorld then
      return SceneUtils.GetPosInLand(View:Abs_K2_GetActorLocation(), nil, nil, nil, nil, nil, nil, nil, nil, true, ViewWorld)
    end
  end
  if self.owner.viewObj then
    local origin, extend = self.owner.viewObj:GetActorBounds(true)
    origin.Z = origin.Z - extend.Z / 2.0
    return origin
  end
  return self.logicPos
end

function MissileComponent:OnCreate()
  if self.data.NeedFollow == true then
    if self.owner.viewObj then
      local attachRule = UE.EAttachmentRule.KeepWorld
      self.owner:SetActorRotation(self.logicDir:ToRotator())
      self.owner.viewObj:K2_AttachToActor(self.caster.viewObj, self.data.AttachSocket, attachRule, attachRule, attachRule, false)
    else
      self.owner:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnMissileViewCreated)
    end
  end
end

function MissileComponent:OnMissileViewCreated(missile)
  if self.owner ~= missile then
    return
  end
  self.owner:SetActorRotation(self.logicDir:ToRotator())
  if self.hasLaunched then
    local attachRule = UE.EAttachmentRule.KeepWorld
    self.owner.viewObj:K2_DetachFromActor(attachRule, attachRule, attachRule)
    self.NextStepExceedStepHeight = false
    self:PlayAudioAtLocation(self.data.FlyConfigID, self:GetOwnerLocation())
  else
    local attachRule = UE.EAttachmentRule.KeepWorld
    self.owner.viewObj:K2_AttachToActor(self.caster.viewObj, self.data.AttachSocket, attachRule, attachRule, attachRule, false)
  end
end

function MissileComponent:OnLaunch()
  self.hasLaunched = true
  if self.owner.viewObj then
    local attachRule = UE.EAttachmentRule.KeepWorld
    self.owner.viewObj:K2_DetachFromActor(attachRule, attachRule, attachRule)
    if self.module.isDebug then
      table.insert(self.timerIds, _G.DelayManager:DelaySeconds(self.data.LifeTime, self.Destroy, self, Enum.MissileDestroyReason.MDR_LIFE_TIME_OUT))
    end
    self.NextStepExceedStepHeight = false
    self:PlayAudioAtLocation(self.data.FlyConfigID, self:GetOwnerLocation())
  else
    self.owner:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnMissileViewCreated)
  end
  if self.data.MissileType == Enum.MissileType.AIM_AT_TARGET_POS then
    self.target = nil
  end
  self.lastHitTime = nil
end

function MissileComponent:GetOwnerLocation()
  return self.owner:GetActorLocation()
end

function MissileComponent:GetOwnerDirection()
  if self.owner.viewObj == nil then
    return
  end
  local forwardDir = UE.UKismetMathLibrary.Conv_RotatorToVector(self.owner.viewObj:K2_GetActorRotation())
  return UE.UKismetMathLibrary.Normal(forwardDir, 0.01)
end

function MissileComponent:GetTargetDirection()
  if self.owner.viewObj == nil then
    return
  end
  local targetDir = self.targetPos - self:GetOwnerLocation()
  return UE.UKismetMathLibrary.Normal(targetDir, 0.01)
end

function MissileComponent:OnCollision(otherActor, hitResult, lastHitDir)
  if self.data.IsKeepLandHeight and otherActor:IsA(UE.ALandscapeProxy) then
    return
  end
  if not hitResult then
    return
  end
  if not _G.NRCModuleManager:IsModuleActive("CollisionModule") then
    _G.NRCModuleManager:ActiveModule("CollisionModule")
  end
  local collisionModule = NRCModuleManager:GetModule("CollisionModule")
  lastHitDir:Normalize()
  local beHitEntity = otherActor.sceneCharacter
  if not beHitEntity then
    self:Destroy(Enum.MissileDestroyReason.MDR_HIT_OBSTACLE)
    return
  end
  beHitEntity:EnsureComponent(WorldCombatSkillComponent):OnSkillCollisionAction(self.caster, beHitEntity, self.skillId, nil, SceneUtils.ConvertVectorToPoint(lastHitDir), self.data.ImpactForce)
  if self.data.HitFX and (not self.lastHitTime or UE4.UNRCStatics.GetTimestampMS() - self.lastHitTime > self.data.HitCD) then
    collisionModule:PlayHitFx(nil, beHitEntity, self.data.HitFX, hitResult.ImpactPoint, lastHitDir, self.data.HitFXScale, true, self.data.HitFxDuration)
    self.lastHitTime = UE4.UNRCStatics.GetTimestampMS()
  end
  self:PlayAudioAtLocation(self.data.HitEnemyConfigID, self:GetOwnerLocation())
  if beHitEntity.name == "SceneLocalPlayer" and not GlobalConfig.DisablePetDamage then
    beHitEntity:SendEvent(PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, 0, lastHitDir, self.data.IsHeavyAttack, false, self.data.AttackPerformType)
  end
  self:Destroy(Enum.MissileDestroyReason.MDR_HIT_ENTITY)
end

function MissileComponent:Arrived()
  self:Destroy(Enum.MissileDestroyReason.MDR_ARRIVED)
  self.isArrived = true
end

function MissileComponent:GetOwnerId()
  return self.missileId
end

function MissileComponent:CalcCurrentSpeed(deltaTime)
  local accelerateSpeed = self.data.AccelerateSpeed
  self.speed = math.min(self.speed + accelerateSpeed * deltaTime, self.data.MaxSpeed)
end

function MissileComponent:SphericalSinterp(deltaTime)
  if self.isStraight then
    return
  end
  local currentDir = self:GetOwnerDirection()
  local targetDir = self:GetTargetDirection()
  local innerAngle = LuaMathUtils.AngleBetweenVectors(currentDir, targetDir)
  if innerAngle > 1 and self.data.AngleSpeed > 0 then
    local tickChangeAngle = self.data.AngleSpeed * deltaTime
    tickChangeAngle = math.min(tickChangeAngle, innerAngle)
    self.logicDir = LuaMathUtils.Slerp(currentDir, targetDir, tickChangeAngle / innerAngle)
  else
    self.logicDir = targetDir
  end
end

local MaxStepHeight = 25

function MissileComponent:CorrectDirectionWithLandHeight(velocity)
  local nextPos = self.logicPos + velocity
  local landPos = self:GetLandPos(nextPos)
  landPos = landPos or nextPos + UE.FVector(0, 0, 50)
  if UE.UKismetMathLibrary.Vector_IsNearlyZero(landPos) ~= true then
    nextPos = landPos
  end
  self.nextLandHeight = nextPos.Z
end

function MissileComponent:ApplyOwnerPos(velocity, deltaTime)
  self.logicPos = self.logicPos + velocity
  if self.data.IsKeepLandHeight then
    self.logicPos.Z = self.nextLandHeight
    local ownerPos = self.owner.viewObj:K2_GetActorLocation()
    ownerPos = self:GetLandPos(ownerPos)
    velocity = self.logicPos - ownerPos
    self.logicDir = UE.UKismetMathLibrary.Normal(velocity, 0.01)
  end
  coroutine.resume(coroutine.create(MissileComponent.DelayMoveComponent), self, velocity, deltaTime)
end

function MissileComponent:GetLandPos(initPos)
  local World = _G.UE4Helper.GetCurrentWorld()
  local excludeTags = {
    "LayerTag_BuildingsA",
    "LayerTag_BuildingsB",
    "LayerTag_BuildingsC"
  }
  local halfHeight = 0
  if self.owner.viewObj and self.owner.viewObj.GetHalfHeight and type(self.owner.viewObj.GetHalfHeight) == "function" then
    halfHeight = self.owner.viewObj:GetHalfHeight() or 0
  end
  local landPos = UE4.UNRCStatics.GetPosInLandWithClass(World, initPos, halfHeight, 500, 500, nil, nil, nil, nil, excludeTags, {}, true, true)
  if not landPos or UE.UKismetMathLibrary.Vector_IsZero(landPos) then
    return initPos
  end
  return landPos
end

function MissileComponent:DelayMoveComponent(velocity, deltaTime)
  if not self.owner.viewObj or not UE4.UObject.IsValid(self.owner.viewObj) then
    return
  end
  local bSweep = false
  if not _G.WorldCombatModuleCmd or _G.WorldCombatModuleCmd and _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInOfflineMode) then
    bSweep = true
  end
  if self.hasHit and not self.data.IsHitDestroy then
    bSweep = false
  end
  self.owner.viewObj:K2_SetActorTransform(UE.UKismetMathLibrary.MakeTransform(self.owner.viewObj:K2_GetActorLocation() + velocity, UE.UKismetMathLibrary.Conv_VectorToRotator(self.logicDir)), bSweep, nil, false)
end

function MissileComponent:CheckIsArrived(velocity)
  local moveDir = self.targetPos - self:GetOwnerLocation()
  if velocity:Size() >= moveDir:Size() and LuaMathUtils.AngleBetweenVectors(velocity, moveDir) <= 5 then
    return true
  end
  return false
end

function MissileComponent:Destroy(reason)
  Log.Debug("MissileComponent:Destroy", reason, self.skillId, self.owner.name)
  if self.currentAudioId and self.currentAudioId > 0 then
    local audioComp = self.owner.viewObj.RocoAudio
    if not audioComp then
      Log.Error("cannot find RocoAudioComponent on bp in Missile", self.owner.viewObj)
      return
    end
    audioComp:StopAudioById(self.currentAudioId)
  end
  self:CancelAllTimer()
  self:BeforeDestroyAction(reason)
  if self.data and reason == Enum.MissileDestroyReason.MDR_HIT_ENTITY and not self.data.IsHitDestroy then
    Log.Debug("MissileComponent:OnCollision: Hit Actor But IsHitDestroy is false")
    self.hasHit = true
    return
  end
  self.module:OnMissileArrived(self:GetOwnerId())
end

function MissileComponent:BeforeDestroyAction(reason)
  if _G.WorldCombatModuleCmd and not _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInOfflineMode) then
    return
  end
  if reason ~= Enum.MissileDestroyReason.MDR_HIT_OBSTACLE and reason ~= Enum.MissileDestroyReason.MDR_LIFE_TIME_OUT then
    return
  end
  local collisionModule = _G.NRCModuleManager:GetModule("CollisionModule")
  if not collisionModule and self.module.isDebug then
    _G.NRCModuleManager:RegisterModule("CollisionModule", "Type_Core", "NewRoco.Modules.Core.Collision.CollisionModuleHead", "NewRoco.Modules.Core.Collision.CollisionModule")
    _G.NRCModuleManager:ActiveModule("CollisionModule")
    collisionModule = _G.NRCModuleManager:GetModule("CollisionModule")
    collisionModule.isDebug = true
  end
  if self.data.ExplodeFX then
    local FxCaster = self.caster
    if not UE.UObject.IsValid(self.caster.viewObj) then
      FxCaster = self.owner
    end
    collisionModule:PlayHitFx(FxCaster, nil, self.data.ExplodeFX, self.owner:GetActorLocation(), UE.UKismetMathLibrary.Conv_RotatorToVector(self.owner:GetActorRotation()), self.data.ExplodeFXScale, true, self.data.ExplodeFxDuration)
  end
  self:PlayAudioAtLocation(self.data.HitObstacleConfigID, self:GetOwnerLocation())
  if self.data.EffectRadius <= 0 then
    return
  end
  local traceStart = self:GetOwnerLocation()
  local hitResults, isHit = UE.UKismetSystemLibrary.Abs_SphereTraceMultiForObjects(UE4Helper.GetCurrentWorld(), traceStart, traceStart, self.data.EffectRadius, {
    UE.EObjectTypeQuery.Hited
  }, true, {}, UE.EDrawDebugTrace.None)
  if not isHit then
    return
  end
  for idx = 1, hitResults:Length() do
    local hitResult = hitResults:Get(idx)
    local victimActor = hitResult.Actor
    if not victimActor then
    else
      local character = victimActor.sceneCharacter
      character:EnsureComponent(WorldCombatSkillComponent):OnSkillCollisionAction(self.caster, character, self.skillId, nil, SceneUtils.ConvertVectorToPoint(-hitResult.Normal))
      if character.name == "SceneLocalPlayer" and not GlobalConfig.DisablePetDamage then
        character:SendEvent(PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, 0, UE.UKismetMathLibrary.Conv_RotatorToVector(self.owner:GetActorRotation()), self.data.IsHeavyAttack, false, self.data.AttackPerformType)
      end
      if self.data.AddBuffId ~= nil and 0 ~= self.data.AddBuffId then
        character:EnsureComponent(WorldCombatSkillComponent):OnBuffAction(self.skillId, self.actionIdx, self.caster, Enum.WorldBuffOperateType.WBPT_ADD, self.data.AddBuffId, self.data.AddBuffDuration, 0, 1)
      end
    end
  end
end

function MissileComponent:CancelAllTimer()
  for _, timerId in pairs(self.timerIds) do
    DelayManager:CancelDelayById(timerId)
  end
end

function MissileComponent:PlayAudioToSelf(configId)
  if not self:CheckConfig(configId) then
    return
  end
  self:StopAudio(self.currentAudioId)
  local audioComp = self.owner.viewObj.RocoAudio
  audioComp:PlayAudioToSelf(configId)
  self.currentAudioId = configId
end

function MissileComponent:PlayAudioAtLocation(configId, position)
  if not self:CheckConfig(configId) then
    return
  end
  position = SceneUtils.ConvertAbsoluteToRelative(position)
  self:StopAudio(self.currentAudioId)
  local audioId = _G.NRCAudioManager:PlaySound3DAtLocationAuto(configId, position)
  self.currentAudioId = audioId
end

function MissileComponent:StopAudio(configId)
  if not self:CheckConfig(configId) then
    return
  end
  local audioComp = self.owner.viewObj.RocoAudio
  if self.currentAudioId and self.currentAudioId > 0 then
    audioComp:StopAudioById(self.currentAudioId)
  end
  self.currentAudioId = nil
end

function MissileComponent:CheckConfig(configId)
  if not configId or configId <= 0 then
    Log.Debug("Missile Check Audio ConfigId Invalid!!!", configId)
    return false
  end
  local audioComp = self.owner.viewObj.RocoAudio
  if not audioComp then
    Log.Error("cannot find RocoAudioComponent on bp in Missile", self.owner.viewObj)
    return false
  end
  return true
end

return MissileComponent

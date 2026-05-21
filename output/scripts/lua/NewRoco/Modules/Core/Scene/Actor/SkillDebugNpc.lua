local SceneActor = require("NewRoco.Modules.Core.Scene.Actor.SceneActor")
local WorldCombatSkillComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillComponent")
local TraceMissileComponent = require("NewRoco.Modules.Core.Scene.Component.Missile.TraceMissileComponent")
local BornDieComponent = require("NewRoco.Modules.Core.Scene.Component.BornDie.BornDieComponent")
local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
local ProtoMessage = require("Data.PB.ProtoMessage")
local EventDispatcher = require("Common.EventDispatcher")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local Base = SceneActor
local PerformData = _G.MakeSimpleClass("PerformData")
local SkillDebugNpc = Base:Extend("SkillDebugNpc")
SkillDebugNpc.PerformType = {
  None = 0,
  NormalSkill = 1,
  Missile = 2
}
SkillDebugNpc.ActorId = 1
SkillDebugNpc.npcDict = {}

function SkillDebugNpc:Ctor(owner, caster)
  EventDispatcher():Attach(self)
  self.owner = owner
  if owner then
    self.world = owner:GetWorld()
    caster = caster or owner:GetActorByActorInfo(self.owner.DefaultExecuteActorInfo)
  end
  if caster then
    self.world = caster:GetWorld()
  end
  self.serverPos = UE.FVector(0, 0, 0)
  self.landPos = UE.FVector(0, 0, 0)
end

function SkillDebugNpc.CreateNpc(owner, caster, config, performData, initTransform, serverData, modelPath, isNightMareBoss)
  local npc = SkillDebugNpc(owner, caster)
  npc:InitData(config, performData, initTransform, serverData, modelPath, isNightMareBoss)
  npc.ActorId = SkillDebugNpc.ActorId
  SkillDebugNpc.ActorId = SkillDebugNpc.ActorId + 1
  SkillDebugNpc.npcDict[npc.ActorId] = npc
  return npc
end

function SkillDebugNpc.GetNpcByActorId(actorId)
  return SkillDebugNpc.npcDict[actorId]
end

function SkillDebugNpc.GetAllNpc()
  return SkillDebugNpc.npcDict
end

function SkillDebugNpc.RemoveNpc(npc)
  table.removeValue(SkillDebugNpc.npcDict, npc)
  npc:Destroy()
end

function SkillDebugNpc:InitData(config, performData, initTransform, serverData, modelPath, isNightMareBoss)
  self.config = config
  self.performData = performData
  self.serverData = serverData
  self.modelPath = modelPath
  self.isNightMareBoss = isNightMareBoss
  self.hiddenFlag = 0
  self.modelConf = _G.DataConfigManager:GetModelConf(self.config.model_conf)
  if not modelPath and not self.modelConf then
    Log.Error("\230\137\190\228\184\141\229\136\176ModelConf", self.config.id, self.config.model_conf)
    return
  end
  local Pos = UE4Helper.ZeroVector
  self.serverDataRotate = UE4Helper.ZeroVector
  local serverDataRotate_z = 0
  local serverDataRotate_x = 0
  local serverDataRotate_y = 0
  if not self.serverData then
    self.serverData = _G.ProtoMessage:newActorInfo_Npc()
  end
  if self.serverData then
    Pos = self.serverData.base.pt.pos.x and self.serverData.base.pt.pos or initTransform.Translation
    if self.serverData.base.pt.dir.x then
      serverDataRotate_x = self.serverData.base.pt.dir.x / 10
    end
    if self.serverData.base.pt.dir.y then
      serverDataRotate_y = self.serverData.base.pt.dir.y / 10
    end
    if self.serverData.base.pt.dir.z then
      serverDataRotate_z = self.serverData.base.pt.dir.z / 10
    end
    self.serverDataRotate = UE4.FRotator(serverDataRotate_y, serverDataRotate_z, serverDataRotate_x)
  else
    Pos = initTransform.Translation
    self.serverDataRotate = initTransform.Rotation
  end
  self.serverPos:Set(Pos.X, Pos.Y, Pos.Z + 0.001)
  self.landPos:Set(Pos.X, Pos.Y, Pos.Z + 0.001)
  self:InitComponent()
  self:CreateView(true)
  if not self.timerIds then
    self.timerIds = {}
  end
end

function SkillDebugNpc:PostInit(isRuntime)
  if self.bInitAI and self.config.genre == _G.Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM and isRuntime then
    local AIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIComponent")
    self.aiComp = self:EnsureComponent(AIComponent)
    self.aiComp:ForceLock(false)
    self.aiComp.PersistentEnable = true
    self.aiComp:OnDistanceOptimize(0, 1, 0, 0)
    _G.UpdateManager:Register(self)
    if self.viewObj.CharacterMovement then
      if self.viewObj.SetCharacterMovementTickEnabled then
        self.viewObj:SetCharacterMovementTickEnabled(false, "SkillDebugNpc-PostInit")
      else
        self.viewObj.CharacterMovement:SetComponentTickEnabled(false)
      end
      self.viewObj.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
      self.viewObj.CharacterMovement:DisableMovement()
    end
  end
end

function SkillDebugNpc:OnTick(deltaTime)
  if self.aiComp then
    self.aiComp:OnDistanceOptimize(0, 1, 0, 0)
  end
end

function SkillDebugNpc:GetActorLocation()
  if self.viewObj and UE4.UObject.IsValid(self.viewObj) then
    return self.viewObj:Abs_K2_GetActorLocation()
  end
  return self.landPos
end

function SkillDebugNpc:GetActorRotation()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:K2_GetActorRotation()
  end
  return UE4.FRotator(0, 0, 0)
end

function SkillDebugNpc:CreateView(block)
  if nil == block then
    block = true
  end
  if self.viewObj then
    Log.Error("SkillDebugNpc:CreateView, \229\175\185\229\183\178\231\187\143\229\173\152\229\156\168view\231\154\132npc\229\143\141\229\164\141\229\136\155\229\187\186view")
    return
  end
  if not self.modelConf then
    Log.Error("SkillDebugNpc:CreateView, modelConf is invalid")
    return
  end
  if not self.world then
    Log.Error("SkillDebugNpc:CreateView, world is invalid")
    return
  end
  local url = self.modelPath ~= "" and self.modelPath or self.modelConf.path
  self.classUrl = url
  local Transform = UE.FTransform(self.serverDataRotate:ToQuat(), self.serverPos)
  self.viewObj = self.world:Abs_SpawnActor(UE.UClass.Load(url), Transform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.viewObj.sceneCharacter = self
  UE.UNRCStatics.SetActorOwner(self.viewObj, self.caster)
  self:AdjustModelHeight()
  self.viewObj.resourceLoaded = true
  local Lua_NPCBaseHandy = require("NewRoco.Modules.Core.NPC.Lua_NPCBaseHandy")
  self.luaObj = Lua_NPCBaseHandy()
  if self.components then
    local items = self.components:Items()
    for _, v in ipairs(items) do
      if v.OnSetViewObj then
        v:OnSetViewObj()
      end
    end
  end
end

function SkillDebugNpc:GetCollisionCompByUComp(UPrimitiveComp)
  for _, luaComp in pairs(self.collisionComps) do
    if luaComp.viewObj == UPrimitiveComp then
      return luaComp
    end
  end
end

function SkillDebugNpc:InitComponent()
  if self.performData then
    if self.performData.performType == self.PerformType.NormalSkill then
      self:EnsureComponent(WorldCombatSkillComponent)
    elseif self.performData.performType == self.PerformType.Missile then
      self:EnsureComponent(TraceMissileComponent)
    end
  end
  if self.config.disappear_skill then
    self.serverData.base.actor_id = 0
    self:EnsureComponent(BornDieComponent)
  end
end

function SkillDebugNpc:EnsureComponent(ComponentClass, ...)
  local MemberName = ComponentClass.className
  local Instance = rawget(self, MemberName)
  if Instance then
    return Instance
  end
  Instance = ComponentClass(...)
  rawset(self, MemberName, Instance)
  self:AddComponent(Instance)
  return Instance
end

function SkillDebugNpc:AddComponent(component)
  if self.components == nil then
    self.components = _G.Array()
  end
  component:Attach(self)
  self.components:Add(component)
end

function SkillDebugNpc:RemoveComponent(Component)
  if self.components then
    Component:DeAttach()
    self.components:Remove(Component)
  end
  local MemberName = Component.className
  rawset(self, MemberName, nil)
end

function SkillDebugNpc:RemoveAllComponent()
  if self.components then
    local items = self.components:Items()
    for i = #items, 1, -1 do
      local curItem = items[i]
      curItem:DeAttach()
      curItem:Destroy()
    end
    self.components = nil
  end
end

function SkillDebugNpc:FaceTo(targetActor)
  if UE.UObject.IsValid(targetActor) then
    local dir = targetActor:Abs_K2_GetActorLocation() - self:GetActorLocation()
    dir.Z = 0
    self.viewObj:K2_SetActorRotation(dir:ToRotator(), true)
  end
end

function SkillDebugNpc:DoDestroy()
  self:RemoveAllComponent()
  if self.viewObj and UE.UObject.IsValid(self.viewObj) then
    self.viewObj:K2_DestroyActor()
    self.viewObj = nil
  end
  self.isDestroyed = true
end

function SkillDebugNpc:Destroy()
  _G.UpdateManager:UnRegister(self)
  if self.isDestroyed then
    self:DoDestroy()
    return
  end
  if self.BornDieComponent and _G.NRCResourceManager and _G.NRCResourceManager.bind then
    local action = ProtoMessage:newSpaceAct_ActorDieBegin()
    action.die_reason = ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_NONE
    action.skill_or_anim = self.config.disappear_skill
    action.is_skill = true
    self.BornDieComponent:OnBeginDying(action)
    self.BornDieComponent.shouldDestroy = true
    self.isDestroyed = true
    return
  end
  self:DoDestroy()
end

function SkillDebugNpc:OnDestroyedByEngine()
  self.viewObj = nil
  self.viewObjRef = nil
end

function SkillDebugNpc:OnLoadResource()
  self:InvokeAllComponents("OnResourceLoaded")
end

function SkillDebugNpc:OnVisible()
end

function SkillDebugNpc:IsPet()
  return false
end

function SkillDebugNpc:OnInvisible()
end

function SkillDebugNpc:Disappear()
  self:Destroy()
end

function SkillDebugNpc:SetNotDestroyFlag(notDestroyFlag)
end

function SkillDebugNpc:IsLogicStatus(logicStatus)
  if logicStatus == ProtoEnum.SpaceActorLogicStatus.SALS_NIGHTMARE_BOSS and self.isNightMareBoss then
    return true
  end
  return false
end

function SkillDebugNpc:GetActorScale3D()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetActorScale3D()
  end
  return UE4.FVector(1, 1, 1)
end

function SkillDebugNpc:GetHalfHeight()
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.GetHalfHeight then
    return self.viewObj:GetHalfHeight()
  end
  return 0
end

function SkillDebugNpc:GetScaledHalfHeight()
  local HalfHeight = self:GetHalfHeight()
  local Scale = self:GetActorScale3D()
  return HalfHeight * Scale.Z
end

function SkillDebugNpc:SetActorLocation(pos)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:Abs_K2_SetActorLocation_WithoutHit(pos, false, true)
  end
end

function SkillDebugNpc:SetActorRotation(rotate)
  local Model = self.viewObj
  if Model then
    if Model.Event_StopTurn then
      Model:Event_StopTurn()
    end
    if Model.ClearTargetRotator then
      Model:ClearTargetRotator()
    end
    Model:K2_SetActorRotation(rotate, true)
  end
end

function SkillDebugNpc:GetServerId()
  local npcModule = NRCModuleManager:GetModule("NPCModule")
  return npcModule:AcquireFakeID()
end

function SkillDebugNpc:OnDebugSkillEnd(skillId)
  if not self.initDebugPos then
    return
  end
  self:SetActorLocation(self.initDebugPos)
end

function SkillDebugNpc:ClearTimers()
  if not self.timerIds then
    return
  end
  for _, timerId in pairs(self.timerIds) do
    _G.DelayManager:CancelDelayById(timerId)
  end
  table.clear(self.timerIds)
end

function SkillDebugNpc:AdjustModelHeight()
  if self.viewObj:IsA(UE.ARocoCharacter) and _G.NRCAudioManager then
    _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_World", self.viewObj)
    UE.UNRCCharacterUtils.SetCharacterMeshScale(self.viewObj, self:GetConfigScale())
  else
    self.viewObj:SetActorScale3D(_G.FVectorOne * self:GetConfigScale())
  end
end

function SkillDebugNpc:GetConfigScale()
  local scale1 = math.clamp((self.modelConf.model_scale or 100) / 100, 0.001, 100.0)
  local scale2 = math.clamp((self.config.model_scale or 100) / 100, 0.001, 100.0)
  local scale3 = self:GetNpcRefreshScale()
  local scale4 = self:GetNpcFarmScale()
  local scale = scale1 * scale2 * scale3 * scale4
  return scale
end

function SkillDebugNpc:GetNpcRefreshScale()
  if not self.contentConf then
    return 1
  end
  return math.clamp((self.contentConf.model_scale or 100) / 100, 0.001, 100.0)
end

function SkillDebugNpc:GetNpcFarmScale()
  if not (self.serverData and self.serverData.npc_base and self.serverData.npc_base.home_plant_land_id) or 0 == self.serverData.npc_base.home_plant_land_id then
    return 1
  end
  local land_id = self.serverData.npc_base.home_plant_land_id
  if not FarmUtils.IsLandHarvest(land_id) then
    return 1
  end
  local plantGrowConf = FarmUtils.GetPlantGrowConfByLandId(land_id)
  if not plantGrowConf then
    return 1
  end
  local landInfo = FarmUtils.GetLandInfo(land_id)
  if not landInfo then
    return 1
  end
  local growGrade = plantGrowConf.plant_grow_grade[landInfo.plant_tab_id]
  return math.clamp((growGrade.model_scale or 100) / 100, 0.001, 100.0)
end

function SkillDebugNpc:GetBulkyLevel()
  if self.bulky then
    return self.bulky
  end
  if self.config.bulky == nil or 0 == self.config.bulky then
    local modelConf = _G.DataConfigManager:GetModelConf(self.config.model_conf)
    if not modelConf then
      Log.Error("NPC\231\154\132model conf\228\184\141\229\173\152\229\156\168", self:DebugNPCNameAndID())
      return 1
    end
    local scaleRatio = (modelConf.model_scale or 100) / 100 * ((self.config.model_scale or 100) / 100) * self:GetNpcRefreshScale()
    local scale = (modelConf.capsule_halfheight or 1000) / 1000 * scaleRatio * ((modelConf.capsule_radius or 1000) / 1000) * scaleRatio
    if scale >= 0 and scale < 1000 then
      self.bulky = 1
    elseif scale >= 1000 and scale < 5000 then
      self.bulky = 2
    elseif scale >= 5000 and scale < 20000 then
      self.bulky = 3
    else
      self.bulky = 12
    end
  else
    self.bulky = self.config.bulky
  end
  return self.bulky
end

function SkillDebugNpc:IsLocal()
  return true
end

function SkillDebugNpc:ScheduleNextTick(Interval)
  if self.viewObj then
    UE.NPCBaseCommon.ScheduleNextTick(self.viewObj, Interval)
  end
end

function SkillDebugNpc:IsHuman()
  return false
end

function SkillDebugNpc:CanIntimate()
  return false
end

function SkillDebugNpc:GetContentId()
  local npc_base = self.serverData and self.serverData.npc_base
  return npc_base and npc_base.npc_content_cfg_id or 0
end

function SkillDebugNpc:RequestRelease(effect_op)
end

function SkillDebugNpc:GetForwardVector()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetActorForwardVector()
  end
  return UE4.FVector(1, 0, 0)
end

function SkillDebugNpc:GetAnimComponent()
  if not self.viewObj or not UE.UObject.IsValid(self.viewObj) then
    return
  end
  if not self.viewObj.GetAnimComponent then
    return
  end
  local AnimComp = self.viewObj:GetAnimComponent()
  if AnimComp then
    return AnimComp
  end
  AnimComp = self.viewObj:GetComponentByClass(UE4.URocoAnimComponent)
  return AnimComp
end

function SkillDebugNpc:SetHidden(Hidden, Flag)
end

function SkillDebugNpc:SetCollisionDisable(CollisionDisable, Flag)
end

function SkillDebugNpc:StopAllMontage(BlendOut)
  local AnimComp = self:GetAnimComponent()
  if AnimComp and UE.UObject.IsValid(AnimComp) then
    return AnimComp:StopAllMontage(BlendOut or 0.1)
  end
  return false
end

function SkillDebugNpc:Stop()
  if self.BezierFlyComponent and self.BezierFlyComponent:IsFlying() then
    self.BezierFlyComponent:FinishFly(AIDefines.ActionResult.Aborted)
    self.BezierFlyComponent:PostFlySettings()
  end
end

function SkillDebugNpc:CheckPlayerInSeat()
end

function SkillDebugNpc:IsFarmCropNpc()
  if not FarmUtils.IsModuleEnable() then
    return false
  end
  if not (self.serverData and self.serverData.npc_base and self.serverData.npc_base.home_plant_land_id) or 0 == self.serverData.npc_base.home_plant_land_id then
    return false
  end
  return true
end

function SkillDebugNpc:DebugNPCNameAndID()
  if self.serverData then
    local serverId = self.serverData.base.actor_id
    return string.format("%s %u %d %d", self.config.name, serverId, serverId, self:GetContentId())
  elseif self.ThrowSession then
    return string.format("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: %s %d", self.config.name, self.ThrowSession.SeqID)
  else
    return self.config.name
  end
end

function SkillDebugNpc:GetActorTransform()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:Abs_GetTransform()
  end
  return UE4.FTransform()
end

return SkillDebugNpc

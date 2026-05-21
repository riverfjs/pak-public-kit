local Class = _G.MakeSimpleClass
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ExplodeActorComponent = Class("ExplodeActorComponent")

function ExplodeActorComponent:Ctor()
  rawset(self, "explodeAxis", _G.FVectorUp)
  rawset(self, "angle", 20)
  rawset(self, "force", 6000)
  rawset(self, "phyTime", 0.8)
  rawset(self, "startPos", _G.FVectorZero)
  rawset(self, "modules", {})
  self.DelayHandlerMap = {}
end

function ExplodeActorComponent:__Dctor()
  for item, handler in pairs(self.DelayHandlerMap) do
    if handler then
      _G.DelayManager:CancelDelay(handler)
      self.DelayHandlerMap[item] = nil
    end
  end
end

function ExplodeActorComponent:AddForceModule(module)
  table.insert(self.modules, module)
end

function ExplodeActorComponent:SetTargetForwardRotator(rotator)
  self.targetForwardRotator = rotator
end

function ExplodeActorComponent:Explode(actors)
  if not actors then
    return
  end
  Log.Debug("ExplodeActorComponent:Explode", #actors)
  for i, actor in pairs(actors) do
    if not actor or not UE.UObject.IsValid(actor) then
    else
      local sceneCharacter = actor.sceneCharacter
      if sceneCharacter and sceneCharacter.SetVisibleForExplodeReason then
        sceneCharacter:SetVisibleForExplodeReason(false)
      end
      if not actor.K2_SetActorLocation then
        Log.Error("ExplodeActorComponent:Explode, actor\230\178\161\230\156\137K2_SetActorLocation\230\150\185\230\179\149\239\188\159")
      elseif not actor.bEmptyNPC then
        actor:Abs_K2_SetActorLocation_WithoutHit(self.startPos)
        actor.forbidFixCoord = true
        local rotator = self.targetForwardRotator or UE4.UKismetMathLibrary.RandomRotator()
        actor:K2_SetActorRotation(rotator, true)
        local rootComponent = actor:K2_GetRootComponent()
        if rootComponent then
          rootComponent:SetCollisionProfileName("CreatingNPC")
          Log.Debug("ExplodeActorComponent:Explode before delay")
          self.DelayId = _G.DelayManager:DelayFrames(2, self.ExplodeSingle, self, actor, rootComponent)
        else
          Log.Warning("\229\166\130\230\158\156rootCompnent\228\184\186\231\169\186\239\188\140\232\166\129\228\185\136\230\152\175\232\191\153\228\184\170actor\232\162\171\233\148\128\230\175\129\228\186\134\239\188\140\232\166\129\228\185\136\230\152\175\229\135\186\231\142\176\228\186\134\232\175\161\229\188\130\231\154\132\233\151\174\233\162\152")
        end
      end
    end
  end
end

function ExplodeActorComponent:AddForce(Comp)
  if not Comp then
    return
  end
  local forward = UE4.FVector(0, 0, 0)
  if 0 == #self.modules then
    if self.targetForwardRotator then
      self.explodeAxis = UE.UKismetMathLibrary.GetForwardVector(self.targetForwardRotator)
    end
    forward = UE4.UKismetMathLibrary.RandomUnitVectorInConeInDegrees(self.explodeAxis, self.angle)
  else
    for _, module in ipairs(self.modules) do
      forward = forward + module:Get()
    end
  end
  local force = forward * self.force
  Comp:AddImpulse(force)
end

function ExplodeActorComponent:ExplodeSingle(Actor, Root)
  if not Actor or not UE4.UObject.IsValid(Actor) then
    return
  end
  if not Root then
    return
  end
  Actor:SetActorTickEnabled(true)
  local NPC = Actor.sceneCharacter
  if NPC then
    NPC:SetVisible(true)
  end
  Actor:SetActorHiddenInGame(false)
  if not Root then
    Log.Error("No root for actor", UE.UObject.GetName(Actor))
    return
  end
  UE.UNRCStatics.SetupExplodeComponent(Root)
  local sceneCharacter = Actor.sceneCharacter
  if sceneCharacter and sceneCharacter.SetVisibleForExplodeReason then
    sceneCharacter:SetVisibleForExplodeReason(true)
  end
  self:AddForce(Root)
  if Actor.OnDropStart then
    Actor:OnDropStart()
  end
end

function ExplodeActorComponent:GetExplodeAroundLocation(Emitter, height, Actor, Degree, radius, collisionRadians)
  local radians = Degree / 180 * math.pi
  local cos = math.cos(radians)
  local sin = math.sin(radians)
  local finalLocation = self.startPos + Emitter:GetActorForwardVector() * cos * radius * 1.5 + Emitter:GetActorRightVector() * sin * radius * 1.5
  finalLocation.Z = finalLocation.Z + height * 1.2
  local beginLocation = self.startPos + Emitter:GetActorForwardVector() * cos * radius + Emitter:GetActorRightVector() * sin * radius
  beginLocation.Z = beginLocation.Z + height
  local Hit
  if _G.GlobalConfig.bShowHintWhenInteractQuantityChange then
    Hit = UE4.UKismetSystemLibrary.Abs_SphereTraceSingle(Emitter, beginLocation, finalLocation, 10, UE4.ETraceTypeQuery.TraceTypeQuery_MAX, true, nil, UE4.EDrawDebugTrace.ForDuration, Hit, true, UE4.FLinearColor(0, 1, 0, 0), UE4.FLinearColor(0, 1, 0, 1))
  else
    Hit = UE4.UKismetSystemLibrary.Abs_SphereTraceSingle(Emitter, beginLocation, finalLocation, 10, UE4.ETraceTypeQuery.TraceTypeQuery_MAX, true, nil, UE4.EDrawDebugTrace.None, Hit, true, UE4.FLinearColor(0, 1, 0, 0), UE4.FLinearColor(0, 1, 0, 1))
  end
  if Hit.Actor then
    return false, beginLocation
  else
    return true, beginLocation
  end
end

function ExplodeActorComponent:ExplodeToAround(Actor, Radius, HalfHeight, Location, createdNpc, caller, callback)
  local goodPoints = {}
  local badPoints = {}
  self.table = {}
  self.caller = caller
  self.callback = callback
  local location = Location
  self.startPos = UE4.FVector(location.X, location.Y, location.Z)
  local SearchTable = {}
  table.insert(SearchTable, {
    Degree = 30,
    Radius = Radius + 60,
    height = HalfHeight * 0
  })
  table.insert(SearchTable, {
    Degree = -30,
    Radius = Radius + 60,
    height = HalfHeight * 0
  })
  table.insert(SearchTable, {
    Degree = 60,
    Radius = Radius + 60,
    height = HalfHeight * 0
  })
  table.insert(SearchTable, {
    Degree = -60,
    Radius = Radius + 60,
    height = HalfHeight * 0
  })
  table.insert(SearchTable, {
    Degree = 30,
    Radius = Radius + 20,
    height = HalfHeight * 1
  })
  table.insert(SearchTable, {
    Degree = -30,
    Radius = Radius + 20,
    height = HalfHeight * 1
  })
  table.insert(SearchTable, {
    Degree = 60,
    Radius = Radius + 20,
    height = HalfHeight * 1
  })
  table.insert(SearchTable, {
    Degree = -60,
    Radius = Radius + 20,
    height = HalfHeight * 1
  })
  for index, data in ipairs(SearchTable) do
    local Degree = data.Degree
    local radius = data.Radius
    local height = data.height
    local result, point = self:GetExplodeAroundLocation(Actor, height, nil, Degree, radius, 5)
    if result then
      table.insert(goodPoints, {point = point, searchTableIndex = index})
      if #goodPoints >= #createdNpc then
      end
    else
      table.insert(badPoints, {point = point, searchTableIndex = index})
    end
  end
  for i, item in ipairs(createdNpc) do
    local point, data, searchTableIndex
    if #goodPoints > 0 then
      data = table.remove(goodPoints, 1)
    else
      data = table.remove(badPoints, 1)
    end
    point = data.point
    searchTableIndex = data.searchTableIndex
    item:Abs_K2_SetActorLocation_WithoutHit(point)
    item.sceneCharacter:ChangeNeedPosAdjust(false, true)
    item.forbidFixCoord = true
    self.table[item] = point
    self:DoLater(item, point)
    local scale = item:GetActorScale3D()
    Log.Debug("ExplodeToAround ", item:GetDebugInfo(), scale.X, scale.Y, scale.Z)
  end
  self:TryDoCallBack()
end

function ExplodeActorComponent:DoLater(item)
  local point = self.table[item]
  if not point then
    self:TryDoCallBack(item)
    return
  end
  item:SetActorHiddenInGame(false)
  item:Abs_K2_SetActorLocation_WithoutHit(point)
  local rootComponent = item:K2_GetRootComponent()
  if rootComponent then
    rootComponent:SetCollisionProfileName("CreatingNPC")
    rootComponent:SetVisibility(true)
  end
  self.DelayHandlerMap[item] = _G.DelayManager:DelayFrames(5, function()
    self.DelayHandlerMap[item] = nil
    self:ExplodeSingleAround(item)
  end)
end

function ExplodeActorComponent:ExplodeSingleAround(item)
  if not UE4.UObject.IsValid(item) then
    Log.Error("\232\166\129\230\138\155\229\176\132\231\154\132\229\175\185\232\177\161\229\183\178\231\187\143\232\162\171\233\148\128\230\175\129")
    self:TryDoCallBack(item)
    return
  end
  local rootComponent = item:K2_GetRootComponent()
  if rootComponent then
    rootComponent:SetSimulatePhysics(true)
    rootComponent:SetLinearDamping(0.6)
    item:SetActorTickEnabled(true)
  end
  local SkillPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/Pet/G6_Pet_GiftProps_01.G6_Pet_GiftProps_01"
  if not item.RocoSkill then
    item.RocoSkill = item:AddComponentByClass(UE4.URocoSkillComponent, false, UE4.FTransform(), false)
  end
  local SkillProxy = RocoSkillProxy.Create(SkillPath, item.RocoSkill, PriorityEnum.Passive_Pet_Drop)
  if not item.RocoFx then
    item.RocoFx = item:AddComponentByClass(UE4.URocoFXComponent, false, UE4.FTransform(), false)
  end
  SkillProxy:SetCaster(item)
  SkillProxy:PlaySkill()
  local point = self.table[item]
  local horizontalDir = UE4.FVector(point.X - self.startPos.X, point.Y - self.startPos.Y, 0)
  UE4.UKismetMathLibrary.Vector_Normalize(horizontalDir, 0.001)
  local verticalDir = UE4.FVector(0, 0, 1)
  local EmitDegree = 0.4444444444444444 * math.pi
  local velocity = 3000
  local finalVelocity = horizontalDir * math.cos(EmitDegree) + verticalDir * math.sin(EmitDegree)
  finalVelocity = finalVelocity * velocity
  rootComponent:AddImpulse(finalVelocity)
  self:TryDoCallBack(item)
end

function ExplodeActorComponent:TryDoCallBack(item)
  if item then
    table.removeKey(self.table, item)
  end
  if table.isNotEmpty(self.table) then
    return
  end
  local caller = self.caller
  local callback = self.callback
  self.caller = nil
  self.callback = nil
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  if caller and callback then
    callback(caller)
  end
  caller = nil
  callback = nil
end

return ExplodeActorComponent

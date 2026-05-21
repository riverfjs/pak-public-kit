require("UnLuaEx")
local TreeShakeConfig = require("NewRoco.Modules.Core.NPC.Config.TreeShakeConfig")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MathExtend = require("Utils.MathExtend")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local TreeData = require("NewRoco.Modules.Core.NPC.DropTree.NPCTreeData")
local DebugUtils = require("NewRoco.Modules.Core.Scene.Common.DebugUtils")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local BP_NPCTree_C = Base:Extend("BP_NPCTree_C")

function BP_NPCTree_C:Init()
  Base.Init(self)
  self.bFixCoord = nil
  self.bViewOpt = true
  self.bViewOptVisible = nil
  self.optVisible = nil
  self.fruitClosed = false
  self.bGPUDamping = true
  self.Mounts = {}
  self.bIsShake = false
  self:SetActorTickEnabled(false)
  self.LocationIndex = 0
  self.DropFruitDelayHandlers = {}
end

function BP_NPCTree_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  self.PetBullRush = false
  self.InteractType = NPCModuleEnum.InteractType.PLAYER
end

function BP_NPCTree_C:OnLoadResource()
  Log.Debug("BP_NPCTree_C:OnLoadResource", self:GetDebugInfo())
  if self.sceneCharacter and self.sceneCharacter.luaObj:GetShakeTreeTimes() > 0 then
    self:PrepareFruitOnTree()
  else
    self:DestroyAllFruits()
  end
  Base.OnLoadResource(self)
end

function BP_NPCTree_C:DestroyAllFruits()
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  for idx = 1, fruitComps:Length() do
    local fruitComp = fruitComps:Get(idx)
    if fruitComp then
      if fruitComp.GetChildActor then
        local fruit = fruitComp:GetChildActor()
        if fruit then
          NRCResourceManager:UnLoadResByCaller(fruit)
          fruit:ForceHidden()
        end
      end
      if fruitComp.SetPath then
      elseif fruitComp.SetChildActorClass then
        fruitComp:SetChildActorClass(nil)
      end
    end
  end
end

function BP_NPCTree_C:Recycle()
  self:DestroyAllFruits()
  self:ClearHandlers()
  Base.Recycle(self)
  if self.FruitDelayId then
    _G.DelayManager:CancelDelayById(self.FruitDelayId)
    self.FruitDelayId = nil
  end
  if self.GPUDumpingDelayId then
    _G.DelayManager:CancelDelayById(self.GPUDumpingDelayId)
    self.GPUDumpingDelayId = nil
  end
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  if self.PreShakeDelayId then
    _G.DelayManager:CancelDelayById(self.PreShakeDelayId)
    self.PreShakeDelayId = nil
  end
  if self.RestoreDelayId then
    _G.DelayManager:CancelDelayById(self.RestoreDelayId)
    self.RestoreDelayId = nil
  end
end

function BP_NPCTree_C:ClearHandlers()
  if not self.DropFruitDelayHandlers then
    return
  end
  if table.isEmpty(self.DropFruitDelayHandlers) then
    return
  end
  for k, _ in pairs(self.DropFruitDelayHandlers) do
    _G.DelayManager:CancelDelayById(k)
  end
  table.clear(self.DropFruitDelayHandlers)
end

function BP_NPCTree_C:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if self.frameLoaded and (self.resourceLoaded or self:IsFake()) then
    if self.optVisible ~= bulkyVisible then
      if not self.bGPUDamping then
        self:SetActorTickEnabled(bulkyVisible)
      end
      self.optVisible = bulkyVisible
      local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
      for idx = 1, fruitComps:Length() do
        local fruitComp = fruitComps:Get(idx)
        local fruit = fruitComp:GetChildActor()
        if fruit then
          fruit:K2_GetRootComponent():SetVisibility(bulkyVisible, true)
        end
      end
      if not bulkyVisible then
        self.bViewOptVisible = nil
      end
    end
    if bulkyVisible then
      local bViewOptVisible = viewDotValue > self.angleVisibleConfig
      if bViewOptVisible ~= self.bViewOptVisible then
        local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
        for idx = 1, fruitComps:Length() do
          local fruitComp = fruitComps:Get(idx)
          local fruit = fruitComp:GetChildActor()
          if fruit and not fruit.bGPUDamping then
            fruit:SetActorTickEnabled(bViewOptVisible)
          end
        end
        self.bViewOptVisible = bViewOptVisible
      end
    end
  end
end

function BP_NPCTree_C:PlayOptRefreshEffect()
  Log.Debug("BP_NPCTree_C:PlayOptRefreshEffect", self:GetDebugInfo())
  Base.PlayOptRefreshEffect(self)
  if self.resourceLoaded then
    self:PrepareFruitOnTree()
  else
    Log.Debug("\232\181\132\230\186\144\229\176\154\230\156\170\229\138\160\232\189\189")
  end
  self.fruitClosed = false
end

function BP_NPCTree_C:PrepareFruitOnTree()
  Log.Debug("BP_NPCTree_C:PrepareFruitOnTree, \229\188\128\229\144\175\230\158\156\229\173\144", self:GetDebugInfo())
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  local MountPos = self:GetMountPos()
  local MountPosLength = #MountPos
  for idx, fruitComp in tpairs(fruitComps) do
    local fruit
    if fruitComp and UE4.UObject.IsValid(fruitComp) then
      if fruitComp.GetChildActor then
        fruit = fruitComp:GetChildActor()
      else
        Log.Error("Fruit Component of tree: ", self:GetDebugInfo(), "Don't have GetChildActor!!!!!")
      end
    else
      Log.Error("Fruit Component of tree: ", self:GetDebugInfo(), "IsInValid!!!!!")
    end
    if fruit and UE.UObject.IsValid(fruit) then
      fruit:SetActorEnableCollision(false)
      fruit:Init()
      fruit:LuaBeginPlay(false)
      fruit:OnFrameLoad()
      if self.optVisible then
        if not fruit.bGPUDamping then
          Log.Debug("set fruit tick enable")
          fruit:SetActorTickEnabled(true)
        else
          fruit:SetActorTickEnabled(false)
        end
        fruit:K2_GetRootComponent():SetVisibility(true, true)
      end
      if idx <= MountPosLength then
        if fruitComp.SetPath then
          fruit:ForceVisible()
        end
        local Pos = MountPos[idx]
        fruitComp:Abs_K2_SetWorldLocation(Pos, false, nil, false)
        fruit:Abs_K2_SetActorLocation_WithoutHit(Pos, false, false)
      end
    else
      Log.Error("failed to get child actor...")
    end
  end
  self:StartFruitWind()
end

function BP_NPCTree_C:DebugDetail()
  Log.Debug("BP_NPCTree_C:DebugDetail", self:GetDebugInfo())
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  for idx = 1, fruitComps:Length() do
    local fruitComp = fruitComps:Get(idx)
    local fruit = fruitComp:GetChildActor()
    if fruit then
      fruit:DebugDetail()
    end
  end
end

function BP_NPCTree_C:SetActorLocation(newPos)
  Base.SetActorLocation(self, newPos)
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  for idx = 1, fruitComps:Length() do
    local fruitComp = fruitComps:Get(idx)
    local fruit = fruitComp:GetChildActor()
    if fruit and fruit.resourceLoaded then
      fruit:SetHangPoint()
    end
  end
end

function BP_NPCTree_C:CloseFruit(comps)
  Log.Debug("BP_NPCTree_C:CloseFruit", #comps)
  for _, comp in ipairs(comps) do
    local fruit = comp:GetChildActor()
    if comp.SetPath then
      fruit:ForceHidden()
      fruit:SetActorTickEnabled(false)
    else
      if fruit then
        fruit:K2_DestroyActor()
        comp:SetChildActorClass(nil)
      else
      end
    end
  end
  self.fruitClosed = true
  self.bFruitWind = false
end

function BP_NPCTree_C:GetMountLocationsFarFromPlayer()
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  local locations = {}
  for idx = 1, fruitComps:Length() do
    local comp = fruitComps:Get(idx)
    table.insert(locations, comp)
  end
  return locations
end

function BP_NPCTree_C:GetRandomLocations()
  local Center = self:Abs_K2_GetActorLocation()
  local Array = {}
  for i = 1, 10 do
    local X = math.random() > 0.5 and math.random() * 100 + 30 or -100 * math.random() - 30
    local Y = math.random() > 0.5 and math.random() * 100 + 30 or -100 * math.random() - 30
    table.insert(Array, Center + UE.FVector(X, Y, 100))
  end
  return Array
end

function BP_NPCTree_C:GetNearLocation()
  if self.CachedLocations == nil then
    self.CachedLocations = self:GetRandomLocations()
  end
  self.LocationIndex = self.LocationIndex % #self.CachedLocations + 1
  return self.CachedLocations[self.LocationIndex]
end

function BP_NPCTree_C:GetNearLocations(num)
  local locations = self:GetMountLocationsFarFromPlayer()
  return MathExtend.GetRandomSequence_LuaTable(locations, num)
end

function BP_NPCTree_C:Drop(fruits)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  Log.Debug("BP_NPCTree_C:Drop", #fruits)
  local shakeTimes = 0
  local fakeFruitComps = {}
  local fakeFruitCompsAfterRandom = {}
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  for _, fruitComp in tpairs(fruitComps) do
    local fruit = fruitComp:GetChildActor()
    if fruit then
      table.insert(fakeFruitComps, fruitComp)
    end
  end
  if 0 == #fruits then
    if shakeTimes <= 0 then
      self:CloseFruit(fakeFruitComps)
    end
    return
  end
  local after_random_pos = self:GetMountPos()
  local needToDestroy = {}
  if shakeTimes > 0 then
    for i = 1, #fakeFruitComps / 2 do
      table.remove(fakeFruitComps)
    end
  elseif 0 == shakeTimes then
    local total = #fakeFruitComps
    for i = 1, total - #fruits do
      local comp = table.remove(fakeFruitComps)
      table.insert(needToDestroy, comp)
    end
  end
  for idx, fruit in ipairs(fruits) do
    local FruitComp, FruitPos
    if idx <= #fakeFruitComps then
      FruitComp = fakeFruitComps[idx]
    else
      FruitPos = after_random_pos[idx]
    end
    if fruit and UE.UObject.IsValid(fruit) then
      fruit:ForceVisible()
      if fruit.sceneCharacter then
        fruit.sceneCharacter:SetVisibleForBornDieReason(false)
      end
      self:PrepareDropOneFruit(fruit, FruitComp, FruitPos)
    else
      Log.Error("fruit is nil")
    end
  end
  if 0 == shakeTimes and not self.fruitClosed then
    self:CloseFruit(needToDestroy)
    table.clear(needToDestroy)
  end
end

function BP_NPCTree_C:PrepareDropOneFruit(fruit, fruitComp, fruitPos)
  if not UE.UObject.IsValid(fruit) then
    Log.Error("\233\156\128\232\166\129\230\142\137\232\144\189\231\154\132\230\158\156\229\174\158\229\135\137\228\186\134...\229\143\175\228\187\165\232\129\148\231\179\187\229\188\128\229\143\145\231\156\139\231\156\139\230\156\137\230\178\161\230\156\137\229\188\130\229\184\184")
    return
  end
  local useFake = false
  if fruitComp then
    useFake = true
    local fakeFruit = fruitComp:GetChildActor()
    if fakeFruit then
      local fruitLocation = fakeFruit:Abs_K2_GetActorLocation()
      fruit:Abs_K2_SetActorLocation_WithoutHit(fruitLocation)
    end
  elseif fruit.Mount then
    fruit:Mount(fruitPos)
  else
    fruit:Abs_K2_SetActorLocation_WithoutHit(fruitPos)
  end
  local FruitMeshComp = fruit:GetComponentByClass(UE4.UStaticMeshComponent)
  if FruitMeshComp then
    FruitMeshComp:SetCollisionProfileName("CreatingNPC")
    local Handler = _G.DelayManager:DelayFrames(5, self.DropOneFruit, self, fruit, FruitMeshComp, fruitComp)
    self.DropFruitDelayHandlers[Handler] = true
  else
    Log.Error("\232\175\149\229\155\190\229\150\183\229\176\132\231\154\132actor\230\178\161\230\156\137\230\137\190\229\136\176mesh")
  end
end

function BP_NPCTree_C:DropOneFruit(fruit, fruitMesh, fruitComp)
  if not UE.UObject.IsValid(fruit) then
    return
  end
  if fruitComp then
    if fruitComp.SetPath then
      local fakeFruit = fruitComp:GetChildActor()
      if UE4.UObject.IsValid(fakeFruit) then
        fakeFruit:ForceHidden()
      end
    else
      local fakeFruit = fruitComp:GetChildActor()
      if fakeFruit then
        fakeFruit:K2_DestroyActor()
        fruitComp:SetChildActorClass(nil)
      else
      end
    end
  end
  if fruit.sceneCharacter then
    fruit.sceneCharacter:SetVisibleForBornDieReason(true)
  end
  fruit:K2_GetRootComponent():SetVisibility(true)
  fruit:SetActorTickEnabled(true)
  fruit.dropFlag = true
  fruitMesh:SetSimulatePhysics(true)
end

function BP_NPCTree_C:UpdateData(ServerData, bIsReconnect)
  Base.UpdateData(self, ServerData, bIsReconnect)
  if bIsReconnect then
    if self.sceneCharacter and self.sceneCharacter.luaObj:GetShakeTreeTimes() > 0 then
      self:PrepareFruitOnTree()
    else
      self:DestroyAllFruits()
    end
  end
end

function BP_NPCTree_C:Shake()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  Log.Debug("BP_NPCTree_C:Shake")
  self.timer = 0
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.CharactForward = self:Abs_K2_GetActorLocation() - player.viewObj:Abs_K2_GetActorLocation()
  self.CharactForward.Z = 0
  self.CharactForward2 = UE4.FVector(self.CharactForward.X, self.CharactForward.Y, self.CharactForward.Z)
  self.CharactForward = UE4.UKismetMathLibrary.Cross_VectorVector(self.CharactForward, UE4.FVector(0, 0, 1))
  self.OscParamX0 = TreeShakeConfig.TreeShake.x0
  self.OscParamP = TreeShakeConfig.TreeShake.p
  self.OscParamW = TreeShakeConfig.TreeShake.w
  self.OscTimeSpeed = TreeShakeConfig.TreeShake.timeSpeed
  self.OscParamHeight = TreeShakeConfig.TreeShake.start_height
  self.OscParamX02 = TreeShakeConfig.TreeShake.x02
  self.OscParamP2 = TreeShakeConfig.TreeShake.p2
  self.OscParamW2 = TreeShakeConfig.TreeShake.w2
  self.OscTimeSpeed2 = TreeShakeConfig.TreeShake.timeSpeed2
  self.OscParamHeight2 = TreeShakeConfig.TreeShake.start_height2
  self.ConfigDampedOscillation = TreeShakeConfig.TreeShake.func
  self.bIsShake = UE.UNRCQualityLibrary.GetImageQuality() > UE.ENRCImageQuality.Low
  if self.bGPUDamping then
    self:SetActorTickEnabled(self.bIsShake)
    self.GPUDumpingDelayId = _G.DelayManager:DelaySeconds(5, self.CloseTick, self)
  end
end

function BP_NPCTree_C:CloseTick()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.bIsShake = false
  self:ChangeTrunkShakeMaterial()
  self:SetActorTickEnabled(false)
end

function BP_NPCTree_C:CalcFruitHangOffset(fruit)
  local hangLocation = fruit.HangPoint:Abs_K2_GetComponentLocation()
  local treeLocation = self:Abs_K2_GetActorLocation()
  local pivot = UE4.FVector(hangLocation.X, hangLocation.Y, hangLocation.Z)
  pivot.Z = treeLocation.Z - 200
  local vec = hangLocation - pivot
  if vec.Z > 0 then
    local rotate1 = UE4.UKismetMathLibrary.RotateAngleAxis(vec, self.curShakeAngle * 360, self.CharactForward)
    local offset1 = rotate1 - vec
    local pos_after_rotate = hangLocation + offset1
    pivot = UE4.FVector(pos_after_rotate.X, pos_after_rotate.Y, pos_after_rotate.Z)
    pivot.Z = treeLocation.Z - 100
    local vec2 = pos_after_rotate - pivot
    if vec2.Z > 0 then
      local rotate2 = UE4.UKismetMathLibrary.RotateAngleAxis(vec2, self.curShakeAngle2 * 360, self.CharactForward2)
      local offset2 = rotate2 - vec2
      return offset1 + offset2
    else
      return offset1
    end
  end
  return UE4.FVector(0, 0, 0)
end

function BP_NPCTree_C:CalcFruitTransform(fruit)
  local fruitLocation = fruit:Abs_K2_GetActorLocation()
  local hangPos = fruit.HangPoint:Abs_K2_GetComponentLocation()
  local angle = fruit.ShakeAngle
end

function BP_NPCTree_C:CalcFruitShakeAngle(fruit)
  local hangLocation = fruit.HangPoint:Abs_K2_GetComponentLocation()
  local treeLocation = self:Abs_K2_GetActorLocation()
  local offsetZ = hangLocation.Z - treeLocation.Z
  return math.min(offsetZ / 10, 30)
end

function BP_NPCTree_C:ReceiveTick(DeltaSeconds)
  if self.frameLoaded then
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    if self.bFruitWind then
      local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
      for idx = 1, fruitComps:Length() do
        local fruitComp = fruitComps:Get(idx)
        local fruit = fruitComp:GetChildActor()
        if fruit then
          if self.bIsShake then
            local hangOffset = self:CalcFruitHangOffset(fruit)
            local fruitActorLocation = fruitComp:Abs_K2_GetComponentLocation() + hangOffset
            fruit:Abs_K2_SetActorLocation_WithoutHit(fruitActorLocation)
            local k = self:CalcFruitShakeAngle(fruit)
            fruit:SetTreeAngle(self.curShakeAngle2 * k)
            fruit.bShakeTree = true
          else
            fruit.bShakeTree = false
          end
          if not fruit.bGPUDamping then
            local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
            if player then
              local vec = self:Abs_K2_GetActorLocation() - player:GetActorLocation()
              vec.Z = 0
              fruit.HangShakeAxis = vec
            end
          end
        end
      end
    end
  end
end

function BP_NPCTree_C:StartFruitWind()
  Log.Debug("BP_NPCTree_C:StartFruitWind", self:GetDebugInfo())
  self.bFruitWind = true
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  for idx = 1, fruitComps:Length() do
    local fruitComp = fruitComps:Get(idx)
    local fruit = fruitComp:GetChildActor()
    if fruit then
      fruit.timer = 0
      fruit.bIsWind = true
      if not fruit.bGPUDamping then
        local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        if player then
          local vec = self:Abs_K2_GetActorLocation() - player:GetActorLocation()
          vec.Z = 0
          fruit.HangShakeAxis = vec
        end
        fruit.ShakeFhase = UE4.UKismetMathLibrary.RandomFloatInRange(0, 2 * math.pi)
        fruit.OscParamX0 = TreeShakeConfig.FruitWind.x0
        fruit.OscParamP = TreeShakeConfig.FruitWind.p
        fruit.OscParamW = TreeShakeConfig.FruitWind.w
        fruit.OscTimeSpeed = TreeShakeConfig.FruitWind.timeSpeed
        fruit.ConfigDampedOscillation = TreeShakeConfig.FruitWind.func
      end
    end
  end
end

function BP_NPCTree_C:StopShake()
  self.bIsShake = false
  self.timer = 0
end

function BP_NPCTree_C:UnlockMoveAndBattle()
  Log.Debug("BP_NPCTree_C:UnlockMoveAndBattle", self:GetDebugInfo())
  _G.GlobalConfig.DisableBattle = false
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.inputComponent:SetInputEnable(self, true)
end

function BP_NPCTree_C:Show()
  Log.Debug("BP_NPCTree_C:Show", self:GetDebugInfo(), self.HoldFruit, self.bShowing)
  if self.HoldFruit then
    if self.InteractType == NPCModuleEnum.InteractType.PLAYER then
      self.InteractType = NPCModuleEnum.InteractType.PET_BULL_RUSH
    end
    return
  end
  if self.bShowing then
    return
  end
  self.bShowing = true
  self.RestoreDelayId = _G.DelayManager:DelaySeconds(2, self.RestoreFlags, self)
  local fruits = self.sceneCharacter.luaObj:GetChildrenNPCViews()
  if #fruits > 0 then
    self.FruitDelayId = _G.DelayManager:DelaySeconds(1.67, self.UnlockMoveAndBattle, self)
  else
    self:UnlockMoveAndBattle()
  end
  if self.InteractType == NPCModuleEnum.InteractType.PET_BULL_RUSH then
    self:PreShake(fruits)
  else
    self.PreShakeDelayId = _G.DelayManager:DelaySeconds(0.33, self.PreShake, self, fruits)
  end
  if self.InteractType == NPCModuleEnum.InteractType.PET_BULL_RUSH then
    self.InteractType = NPCModuleEnum.InteractType.PLAYER
  end
end

function BP_NPCTree_C:DropFruits(fruits)
  self:Drop(fruits)
  self.sceneCharacter:SetNotDestroyFlag(false)
end

function BP_NPCTree_C:PreShake(fruits)
  self:Shake()
  self.Item_Tree:Activate(true)
  _G.NRCAudioManager:PlaySound3DAtLocationAuto(1051, self:K2_GetActorLocation())
  self.DelayId = _G.DelayManager:DelaySeconds(0.1, self.DropFruits, self, fruits)
end

function BP_NPCTree_C:RestoreFlags()
  self.bShowing = false
end

function BP_NPCTree_C:ReceiveActorBeginOverlap(OtherActor)
  if OtherActor.sceneCharacter and OtherActor.sceneCharacter.isLocal then
    self.OtherActor = OtherActor
    if self.sceneCharacter then
      self.sceneCharacter.InteractionComponent:OnPlayerEnterActionArea()
    end
  end
end

function BP_NPCTree_C:ReceiveActorEndOverlap(OtherActor)
  if OtherActor.sceneCharacter and OtherActor.sceneCharacter.isLocal and self.sceneCharacter then
    self:StopShake()
    self.sceneCharacter.InteractionComponent:OnPlayerLeaveActionArea()
  end
end

function BP_NPCTree_C:GetMountPos()
  local serverData = self.sceneCharacter and self.sceneCharacter.serverData
  local npc_base = serverData and serverData.npc_base
  local random_seed = npc_base and npc_base.npc_content_cfg_id
  if random_seed then
    math.randomseed(random_seed)
  end
  if #self.Mounts > 0 then
    return self.Mounts
  end
  if not self.StaticMesh or not UE.UObject.IsValid(self.StaticMesh) then
    return {}
  end
  local Names = self.StaticMesh:GetAllSocketNames()
  local nameArray = {}
  for _, Name in tpairs(Names) do
    table.insert(nameArray, Name)
  end
  table.sort(nameArray)
  local Array = {}
  for _, Name in ipairs(nameArray) do
    local SocketPos = self.StaticMesh:Abs_GetSocketLocation(Name)
    local SocketPosCopy = UE.FVector(SocketPos.X, SocketPos.Y, SocketPos.Z)
    table.insert(Array, SocketPosCopy)
  end
  self.Mounts = MathExtend.GetRandomSequence_LuaTable(Array, #Array)
  math.randomseed(os.time())
  return self.Mounts
end

function BP_NPCTree_C:SetChildNPC(npcs)
  for _, npc in ipairs(npcs) do
    local landPos = self:GetNearLandLocation()
    if landPos then
      local FullHeight = npc.viewObj.GetTotalHeight and npc.viewObj:GetTotalHeight() or 0
      Log.Debug("landPos x, y, z", landPos.X, landPos.Y, landPos.Z, FullHeight)
      landPos.Z = landPos.Z + FullHeight
      local serverPos = npc.serverData.base.pt.pos
      serverPos.x = landPos.X
      serverPos.y = landPos.Y
      serverPos.z = landPos.Z
      npc.serverPos = UE.FVector(serverPos.x, serverPos.y, serverPos.z)
      npc.viewObj.forbidFixCoord = false
      npc:SetActorLocation(landPos)
      if npc.viewObj then
        npc.viewObj:PlayBeamEffect()
      end
    else
      Log.Warning("landPos\228\184\141\229\173\152\229\156\168")
    end
  end
end

function BP_NPCTree_C:CanEnterThrowInter(Comp)
  return Comp and (Comp == self.ActionArea or Comp == self.TreeCollision)
end

function BP_NPCTree_C:SetCustomDepth(Depth)
  local fruitComps = self:GetComponentsByTag(UE4.UChildActorComponent, "FruitActor")
  local FruitCount = 0
  for _, FruitComp in tpairs(fruitComps) do
    local Fruit = FruitComp:GetChildActor()
    if Fruit and Fruit.SetCustomDepth then
      Fruit:SetCustomDepth(Depth)
      FruitCount = FruitCount + 1
    end
  end
  if 0 == FruitCount then
    Base.SetCustomDepth(self, nil)
  else
    Base.SetCustomDepth(self, Depth)
  end
end

return BP_NPCTree_C

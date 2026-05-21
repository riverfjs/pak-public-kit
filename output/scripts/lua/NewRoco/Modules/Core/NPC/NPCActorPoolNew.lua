local Class = _G.MakeSimpleClass
local FrameLimitQueue = require("NewRoco.Modules.Core.NPC.FrameLimitQueue")
local TempSweepResult = UE.FHitResult()
local FarAwayPos = UE4.FVector(-10000, -10000, -10000)
local EnableLog = true

local function LogInfo(...)
  if not EnableLog then
    return
  end
  Log.Debug("[NPCActorPoolNew]", ...)
end

local NPCActorPoolNew = Class("NPCActorPoolNew")

function NPCActorPoolNew:Ctor()
  self.asyncLoad = true
  self.defaultPoolConfig = self:GetDefaultPoolConfig()
  self.customPoolConfigs = {}
  self.pools = {}
  self.recycle_num = 1
  self.spawn_num = 1
  self.SpawnQueue = FrameLimitQueue("Spawn", self.spawn_num)
  self.RecycleQueue = FrameLimitQueue("Recycle", self.recycle_num)
  self.waitNPCCaller = {}
  self.waitNPCUrl = {}
  self.waitNPCRequest = {}
  self.poolCleanCheckNumPerFrame = 1
  self.poolCleanCheckCurrentUrl = nil
  self.cleanActorEachPoolPerFrame = 1
  self:Init()
end

function NPCActorPoolNew:Init()
  local npcActorPoolConfigs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.NPC_ACTOR_POOL_CONF)
  if npcActorPoolConfigs then
    for _, actorPoolConfig in pairs(npcActorPoolConfigs) do
      local modelId = actorPoolConfig.model_conf
      if not modelId then
      else
        local modelConf = _G.DataConfigManager:GetModelConf(modelId, true)
        if not modelConf then
        else
          local url = modelConf.path
          if not url then
          elseif self.customPoolConfigs[url] then
            Log.Debug("[NPCActorPoolNew]", "customPoolConfigs already exist, skip", actorPoolConfig.id, actorPoolConfig.editor_name, url, modelId)
          else
            local config = {
              maxSize = actorPoolConfig.max_size,
              lifetime = actorPoolConfig.life_time
            }
            self.customPoolConfigs[url] = config
          end
        end
      end
    end
  end
end

function NPCActorPoolNew:PrintInfo()
  LogInfo("PrintInfo")
  local total = 0
  for url, pool in pairs(self.pools) do
    local num = self:GetPoolTotalSize(pool)
    local available = pool.available or {}
    local inUse = pool.inUse or {}
    total = total + num
    LogInfo("url", url, "num", num, "available", table.len(available), "inUse", table.len(inUse))
  end
  LogInfo("Pool Total", total)
  LogInfo("Recycle Queue Size", #self.recycleQueue)
  LogInfo("Spawn Queue Size", #self.spawnQueue)
end

function NPCActorPoolNew:ClearAll()
  local Node = self.RecycleQueue:Pop()
  while Node do
    self:Recycle(Node.url, Node.viewObj)
    self.RecycleQueue:ReturnNode(Node)
    Node = self.RecycleQueue:Pop()
  end
  self.SpawnQueue:ClearAll()
  for url, pool in pairs(self.pools) do
    for _, entry in pairs(pool.available) do
      if entry then
        local actor = entry.actor
        if UE4.UObject.IsValid(actor) then
          NRCResourceManager:UnLoadResByCaller(actor)
          if actor.K2_DestroyActor then
            actor:K2_DestroyActor()
          end
        end
      end
    end
    table.clear(pool.available)
  end
  self.pools = {}
  self.waitNPCCaller = {}
  self.waitNPCUrl = {}
  self.waitNPCRequest = {}
  NRCResourceManager:UnLoadResByCaller(self)
end

function NPCActorPoolNew:OnTick(deltaTime)
  local First = self.RecycleQueue:FramedPop()
  if First then
    self:Recycle(First.url, First.viewObj)
    self.RecycleQueue:ReturnNode(First)
  else
    self:TryOnClassLoad()
  end
  self:ProcessPoolsCleanup()
end

function NPCActorPoolNew:ProcessPoolsCleanup()
  if not self.pools then
    return
  end
  if self.poolCleanCheckCurrentUrl and not self.pools[self.poolCleanCheckCurrentUrl] then
    self.poolCleanCheckCurrentUrl = nil
  end
  local currentPool
  for _ = 1, self.poolCleanCheckNumPerFrame do
    if not self.pools[self.poolCleanCheckCurrentUrl] then
      self.poolCleanCheckCurrentUrl = nil
    end
    self.poolCleanCheckCurrentUrl, currentPool = next(self.pools, self.poolCleanCheckCurrentUrl)
    if not self.poolCleanCheckCurrentUrl then
      self.poolCleanCheckCurrentUrl, currentPool = next(self.pools)
    end
    if not self.poolCleanCheckCurrentUrl then
      break
    end
    if not currentPool then
      Log.Error("ProcessPoolsCleanup", "Pool is nil", self.poolCleanCheckCurrentUrl)
    else
      self:ExecutePoolCleanup(currentPool)
      local poolSize = self:GetPoolTotalSize(currentPool)
      if 0 == poolSize then
        LogInfo("ProcessPoolsCleanup", "Pool clean to 0", self.poolCleanCheckCurrentUrl, poolSize)
        self.pools[self.poolCleanCheckCurrentUrl] = nil
      end
    end
  end
end

function NPCActorPoolNew:ExecutePoolCleanup(pool)
  if not pool then
    return
  end
  local config = self:GetPoolConfig(pool.url)
  if not config then
    return
  end
  local lifetime = config.lifetime
  local currentTime = os.time()
  local checkNum = math.min(self.cleanActorEachPoolPerFrame, table.len(pool.available))
  for _ = 1, checkNum do
    local entry = pool.available[1]
    if not entry then
    elseif not entry.enqueueTime then
      LogInfo("ExecutePoolCleanup", pool.url, self:GetPoolTotalSize(pool), entry.enqueueTime, currentTime, UE4.UKismetSystemLibrary.GetDisplayName(entry.actor))
    elseif lifetime <= currentTime - entry.enqueueTime then
      table.remove(pool.available, 1)
      local actor = entry.actor
      LogInfo("ExecutePoolCleanup", pool.url, self:GetPoolTotalSize(pool), entry.enqueueTime, currentTime, UE4.UKismetSystemLibrary.GetDisplayName(actor))
      if UE4.UObject.IsValid(actor) and actor.K2_DestroyActor then
        actor:K2_DestroyActor()
      end
    else
      break
    end
  end
end

function NPCActorPoolNew:Get(url, caller, block, priority)
  if priority and priority >= 255 then
    Log.Error("NPCActorPool:Get NPC should never large or equal to 255", url)
  end
  local actor = self:TryGetFromPool(url)
  if actor then
    self:OnViewHasGotten(actor, caller)
    return actor
  end
  if block or not self.asyncLoad then
    local characterClass = UE4.UClass.Load(url)
    if nil == characterClass then
      Log.Error("NPCActorPool:Get: Class\229\138\160\232\189\189\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165\232\181\132\230\186\144\233\133\141\231\189\174 ", url)
      return nil
    end
    local viewObj = self:CreateActorByClass(characterClass)
    if not viewObj then
      Log.Error("Class\229\138\160\232\189\189\230\136\144\229\138\159\228\189\134\229\136\155\229\187\186Actor\229\164\177\232\180\165 ", url)
    end
    self:OnViewHasGotten(viewObj, caller)
    return viewObj
  else
    local request = NRCResourceManager:LoadResAsync(self, url, priority or -1, -1, self.PreOnClassLoad, self.OnLoadFailed)
    self.waitNPCCaller[request] = caller
    self.waitNPCUrl[request] = url
    self.waitNPCRequest[caller] = request
  end
  LogInfo("Get", "\230\150\176\229\136\155\229\187\186", url, caller:DebugNPCNameAndID())
  return nil
end

function NPCActorPoolNew:OnViewHasGotten(viewObj, npc)
  if not UE4.UObject.IsValid(viewObj) then
    return
  end
  viewObj:SetActorHiddenInGame(false)
  viewObj:SetActorEnableCollision(true)
  if npc and npc.OnViewObjGetFromPool then
    npc:OnViewObjGetFromPool(viewObj)
  end
end

function NPCActorPoolNew:CreateActorByClass(class)
  local params = {}
  params.sceneCharacter = nil
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, 0)
  local World = _G.UE4Helper.GetCurrentWorld()
  local fTransfom = UE4.FTransform(quat, FarAwayPos)
  local actor = World:Abs_SpawnActor(class, fTransfom, UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn, nil, nil, nil, params)
  if actor and actor.ForceHidden then
    actor:ForceHidden()
  end
  return actor
end

function NPCActorPoolNew:TryGetFromPool(url)
  local pool = self.pools[url]
  if not pool then
    return nil
  end
  local poolSize = table.len(pool.available)
  if 0 == poolSize then
    return nil
  end
  for i = 1, poolSize do
    local entry = table.remove(pool.available, 1)
    if not entry then
    else
      local actor = entry.actor
      if actor and UE4.UObject.IsValid(actor) then
        pool.inUse[actor] = entry
        LogInfo("TryGetFromPool", "\228\187\142\230\177\160\228\184\173\232\142\183\229\143\150Actor", UE4.UKismetSystemLibrary.GetDisplayName(actor), entry.enqueueTime)
        entry.enqueueTime = nil
        return actor
      else
        LogInfo("TryGetFromPool", "\230\177\160\228\184\173Actor\232\162\171\233\148\128\230\175\129\239\188\140\228\187\142\230\177\160\228\184\173\231\167\187\233\153\164", i)
      end
    end
  end
  return nil
end

function NPCActorPoolNew:PreOnClassLoad(Request, Klass)
  if nil == Klass then
    Log.Error("NPCActorPool:Get: Class\229\138\160\232\189\189\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165\232\181\132\230\186\144\233\133\141\231\189\174 ", Request.assetPath)
    return nil
  end
  local Node = self.SpawnQueue:Push()
  Node.Request = Request
  Node.Klass = Klass
end

function NPCActorPoolNew:OnLoadFailed(resRequest, errMsg)
  Log.Error("NPCActorPool:Get: Class\229\138\160\232\189\189\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165\232\181\132\230\186\144\233\133\141\231\189\174 ", resRequest.assetPath, errMsg)
end

function NPCActorPoolNew:TryOnClassLoad()
  local First = self.SpawnQueue:FramedPop()
  if not First then
    return
  end
  local Req = First.Request
  local Klass = First.Klass
  self.SpawnQueue:ReturnNode(First)
  self:OnClassLoad(Req, Klass)
end

function NPCActorPoolNew:OnClassLoad(resRequest, characterClass)
  local url = self.waitNPCUrl[resRequest]
  if nil == url then
    return nil
  end
  if nil == characterClass then
    Log.Error("NPCActorPool:Get: Class\229\138\160\232\189\189\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165\232\181\132\230\186\144\233\133\141\231\189\174 ", url)
    return nil
  end
  local viewObj = self:CreateActorByClass(characterClass)
  if nil == viewObj then
    Log.Error("Failed to create class ", tostring(characterClass))
  end
  local npc = self.waitNPCCaller[resRequest]
  npc:OnViewObjGetFromPool(viewObj)
  self.waitNPCUrl[resRequest] = nil
  self.waitNPCCaller[resRequest] = nil
  self.waitNPCRequest[npc] = nil
  NRCResourceManager:UnLoadRes(resRequest)
end

function NPCActorPoolNew:StopWaitClass(caller)
  local resRequest = self.waitNPCRequest[caller]
  if resRequest then
    self.waitNPCUrl[resRequest] = nil
    self.waitNPCCaller[resRequest] = nil
    self.waitNPCRequest[caller] = nil
    NRCResourceManager:UnLoadRes(resRequest)
  end
end

function NPCActorPoolNew:PreRecycle(url, viewObj)
  if viewObj and UE.UObject.IsValid(viewObj) then
    local Node = self.RecycleQueue:Push()
    Node.url = url
    Node.viewObj = viewObj
    Node.viewObjRef = UnLua.Ref(viewObj)
    UE4.UNRCStatics.SetActorOwner(viewObj, nil)
    viewObj:SetActorHiddenInGame(true)
    viewObj:SetActorEnableCollision(false)
  end
end

function NPCActorPoolNew:Recycle(url, viewObj)
  if not UE4.UObject.IsValid(viewObj) then
    return
  end
  viewObj:Abs_K2_SetActorLocation(FarAwayPos, false, TempSweepResult, false)
  if viewObj.ForceHidden then
    viewObj:ForceHidden()
  end
  if viewObj.Recycle then
    viewObj:Recycle()
  end
  if string.IsNilOrEmpty(url) then
    NRCResourceManager:UnLoadResByCaller(viewObj)
    viewObj:K2_DestroyActor()
    return
  end
  local config = self:GetPoolConfig(url)
  if not config then
    LogInfo("Recycle", "\230\178\161\230\156\137\233\133\141\231\189\174pool\229\138\159\232\131\189\239\188\140\231\155\180\230\142\165\231\167\187\233\153\164", url, UE4.UKismetSystemLibrary.GetDisplayName(viewObj))
    return
  end
  local pool = self.pools[url]
  if not pool then
    pool = {
      url = url,
      available = {},
      inUse = {}
    }
    self.pools[url] = pool
  end
  local existedEntry = pool.inUse[viewObj]
  if existedEntry then
    pool.inUse[viewObj] = nil
    existedEntry.enqueueTime = os.time()
    table.insert(pool.available, existedEntry)
    LogInfo("Recycle", "\229\183\178\230\156\137Entry\239\188\140\231\155\180\230\142\165\229\155\158\230\148\182", url, UE4.UKismetSystemLibrary.GetDisplayName(viewObj), existedEntry.enqueueTime)
    return
  end
  if self:CheckPoolReachMaxSize(pool) then
    Log.Warning("Recycle", "\230\177\160\229\183\178\230\187\161\239\188\140\230\177\160\229\164\167\229\176\143\229\143\175\232\131\189\232\190\131\229\176\143", url, self:GetPoolTotalSize(pool), UE4.UKismetSystemLibrary.GetDisplayName(viewObj))
    self:DestroyActor(viewObj)
    return
  end
  local entry = self:NewActorPoolEntry(viewObj)
  table.insert(pool.available, entry)
  LogInfo("NPCActorPoolNew:Recycle", "\230\150\176Entry\232\191\155\229\133\165\230\177\160\228\184\173", url, self:GetPoolTotalSize(pool), UE4.UKismetSystemLibrary.GetDisplayName(viewObj), entry.enqueueTime)
end

function NPCActorPoolNew:DestroyActor(actor)
  if not UE4.UObject.IsValid(actor) then
    return
  end
  NRCResourceManager:UnLoadResByCaller(actor)
  if actor.K2_DestroyActor then
    actor:K2_DestroyActor()
  end
end

function NPCActorPoolNew:GetDefaultPoolConfig()
  return {maxSize = 1, lifetime = 5}
end

function NPCActorPoolNew:GetPoolConfig(url)
  if not url or not self.customPoolConfigs then
    return nil
  end
  local config = self.customPoolConfigs[url]
  if config then
    return config
  end
  return nil
end

function NPCActorPoolNew:NewActorPoolEntry(actor)
  if not actor then
    return nil
  end
  return {
    actor = actor,
    actorRef = UnLua.Ref(actor),
    enqueueTime = os.time()
  }
end

function NPCActorPoolNew:GetPoolTotalSize(pool)
  if not pool then
    return 0
  end
  local totalSize = 0
  if pool.available then
    totalSize = totalSize + #pool.available
  end
  if pool.inUse then
    totalSize = totalSize + table.len(pool.inUse)
  end
  return totalSize
end

function NPCActorPoolNew:CheckPoolReachMaxSize(pool)
  if not pool then
    return false
  end
  local config = self:GetPoolConfig(pool.url)
  if not config then
    return false
  end
  if self:GetPoolTotalSize(pool) >= config.maxSize then
    return true
  end
  return false
end

return NPCActorPoolNew

local Singleton = _G.Singleton
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleRequest = require("NewRoco.Modules.Core.Battle.BattleCore.BattleRequest")
local DummyTable = require("Common.DummyTable")
local Base = Singleton
local BattleResourceManager = Singleton:Extend("BattleResourceManager")
BattleResourceManager.UnloadType = {
  ROUND_START = 1,
  TIME = 2,
  END_GAME = 3,
  HANDLE = 4
}
BattleResourceManager.ResourceType = {
  Widget = 1,
  ACTOR = 2,
  OTHER = 4
}

function BattleResourceManager:Ctor(name)
  self.name = name or "BattleResourceManager"
  Base.Ctor(self, self.name)
  self.burnTime = 0
  self:InitTable()
end

function BattleResourceManager:InitTable()
  self.selfLoadQuest = {}
  self.requestMap = {}
  self.requestPool = {}
  self.classPool = {}
  WeakTable(self.classPool)
  self.castSkillObjectLst = {}
  WeakTable(self.castSkillObjectLst)
  self.preloadReqDict = {}
end

function BattleResourceManager:AttachCastSkillObject(obj)
  if BattleManager:IsInBattle() then
    self.castSkillObjectLst[obj] = 1
  end
end

function BattleResourceManager:ReleaseAllCastSkillObject()
  for i, v in pairs(self.castSkillObjectLst) do
    i:ReleaseSkill()
  end
  self.castSkillObjectLst = {}
end

function BattleResourceManager:LoadUClassOnEditor(path)
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance and RocoEnv.IS_EDITOR then
    return UE4.UClass.Load(path)
  end
  Log.Error("BattleResourceManager:LoadUClassOnEditor \232\175\183\228\189\191\231\148\168\229\188\130\230\173\165\229\138\160\232\189\189\230\142\165\229\143\163LoadAssetAsync\239\188\140\230\138\128\232\131\189\228\189\191\231\148\168PreLoadRes/PreLoadSingleRes\233\162\132\229\138\160\232\189\189", path)
  return nil
end

function BattleResourceManager:LoadUClass(path)
  if string.IsNilOrEmpty(path) then
    Log.Error("BattleResourceManager:LoadUClass path error ", path)
    return
  end
  local cacheObject = self:GetCacheAssetDirect(path)
  if cacheObject then
    if cacheObject.GetDefaultObject then
      return cacheObject
    else
      Log.Warning("[BattleResourceManager] cannot use cache object", cacheObject, ", it's not a uclass, path=", path)
    end
  end
  if self.classPool[path] then
    return self.classPool[path]
  end
  Log.Warning("BattleResourceManager:LoadUClass \232\175\183\228\189\191\231\148\168\229\188\130\230\173\165\229\138\160\232\189\189\230\142\165\229\143\163LoadAssetAsync\239\188\140\230\138\128\232\131\189\228\189\191\231\148\168PreLoadRes/PreLoadSingleRes\233\162\132\229\138\160\232\189\189", path)
  local cla = UE4.UClass.Load(path)
  self.classPool[path] = cla
  return cla
end

function BattleResourceManager:LoadUClassAsync(caller, assetPath, successCallback, failedCallback)
  if string.IsNilOrEmpty(assetPath) then
    Log.Error("[BattleResourceManager] invalid path:", assetPath)
    if failedCallback then
      failedCallback()
    end
    return
  end
  local class = self.classPool[assetPath]
  if class and not class:IsValid() then
    self.classPool[assetPath] = nil
    class = nil
  end
  if not class and class then
    Log.Info("[BattleResourceManager] found valid class:", class, assetPath)
  end
  if class then
    if class.GetDefaultObject then
      local promise = {
        TryGetUClass = function()
          return class
        end,
        GetUClass = function()
          return class
        end,
        CancelLoad = function()
          return nil
        end
      }
      self.classPool[assetPath] = class
      if successCallback then
        successCallback(class)
      end
      return promise
    else
      Log.Error("[BattleResourceManager] class", class, "is not a UClass")
    end
  end
  local classPath = assetPath
  local Dot = string.find(assetPath, "%.")
  if not Dot then
    local Dirs = string.split(assetPath, "/")
    local Name = Dirs[#Dirs]
    classPath = classPath .. "." .. Name .. "_C"
  elseif not string.EndsWith(classPath, "_C") then
    classPath = classPath .. "_C"
  end
  Log.Info("[BattleResourceManager] class path:", classPath)
  local promise = {
    _requestHandle = nil,
    _promiseUClass = nil,
    GetUClass = nil,
    CancelLoad = nil,
    OnUClassLoaded = nil
  }
  
  function promise.GetUClass(p, bNoEnsureAsync)
    if not p._promiseUClass then
      local Notify = Log.Warning
      if not bNoEnsureAsync then
        Notify = Log.Error
      end
      Notify("[BattleResourceManager] LoadUClass sync", classPath)
      p.CancelLoad()
      p._promiseUClass = UE.UClass.Load(classPath)
    end
    return p._promiseUClass
  end
  
  function promise.TryGetUClass(_)
    return promise._promiseUClass
  end
  
  function promise.CancelLoad()
    if promise._requestHandle then
      NRCResourceManager:UnLoadRes(promise._requestHandle)
      promise._requestHandle = nil
    end
    promise._promiseUClass = nil
  end
  
  function promise.OnUClassLoaded(InClass)
    if not promise._requestHandle then
      Log.Error("[BattleResourceManager] logical error!!!, request handle is canceled!!, but got", InClass)
    end
    promise._requestHandle = nil
    promise._promiseUClass = InClass
    if not InClass and promise._requester then
      Log.ErrorFormat("[BattleResourceManager] request %s:%s failed!!! class path:%s", promise._requester.short_src, promise._requester.currentline, classPath)
    end
  end
  
  local function OnLoadAssetAsyncFailed(InCaller)
    assert(InCaller == caller, string.format("ResourceManager bug?, caller %s expected, but got %s", caller, _caller))
    promise.OnUClassLoaded(nil)
    if failedCallback then
      failedCallback()
    end
  end
  
  local function OnLoadAssetAsyncSuccess(InCaller, InRequestHandle, InClass)
    assert(InCaller == caller, string.format("ResourceManager bug?, caller %s expected, but got %s", caller, InCaller))
    if not InClass or not InClass.GetDefaultObject then
      Log.Error("[BattleResourceManager] cannot load class from path:", classPath)
      promise.OnUClassLoaded(nil)
      if failedCallback then
        failedCallback()
      end
      return
    end
    Log.Debug("[BattleResourceManager] LoadUClass async", InClass, "path:", assetPath, "class path:", classPath)
    promise.OnUClassLoaded(InClass)
    self.classPool[assetPath] = InClass
    if successCallback then
      successCallback(InClass)
    end
  end
  
  local request = NRCResourceManager:LoadResAsync(caller, classPath, PriorityEnum.Passive_Battle_Default, 99999, OnLoadAssetAsyncSuccess, OnLoadAssetAsyncFailed)
  promise._requestHandle = request
  return promise
end

function BattleResourceManager:ClearUClass()
  self.classPool = {}
end

function BattleResourceManager:LoadActorAsync(caller, assetPath, transform, param, successCallback, failedCallback)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, BattleResourceManager.ResourceType.ACTOR)
  request:SetActorParam(transform, param or DummyTable)
end

function BattleResourceManager:LoadActorAsyncWithParam(caller, assetPath, transform, priority, param, successCallback, failedCallback, ...)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, BattleResourceManager.ResourceType.ACTOR, nil, nil, priority)
  request:SetSuccessParam(...)
  request:SetActorParam(transform, param or DummyTable)
  return request
end

function BattleResourceManager:LoadWidgetAsync(caller, assetPath, owningPlayer, successCallback, failedCallback, containObj)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, BattleResourceManager.ResourceType.Widget)
  request:SetWidgetParam(owningPlayer, containObj)
end

function BattleResourceManager:LoadWidgetFromCache(caller, assetPath, owningPlayer, successCallback, failedCallback, containObj)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:GetCacheAsset(assetPath)
  if request then
    request:SetData(request.request, request.unloadType, BattleResourceManager.ResourceType.Widget, request.cacheTime, successCallback, failedCallback, caller)
    request:SetWidgetParam(owningPlayer, containObj)
    self:LoadAssetSuccessCallBack(request.request, request.assert, request)
  else
    request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, BattleResourceManager.ResourceType.Widget)
    request:SetWidgetParam(owningPlayer, containObj)
  end
  return request
end

function BattleResourceManager:LoadWidgetAsyncWithParam(caller, assetPath, owningPlayer, successCallback, failedCallback, containObj, ...)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, BattleResourceManager.ResourceType.Widget)
  request:SetSuccessParam(...)
  request:SetWidgetParam(owningPlayer)
end

function BattleResourceManager:LoadClassAsync(caller, assetPath, successCallback, failedCallback)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback)
end

function BattleResourceManager:LoadClassAsyncWithParam(caller, assetPath, successCallback, failedCallback, ...)
  assetPath = NRCUtils.FormatBlueprintAssetPath(assetPath)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback)
  request:SetSuccessParam(...)
end

function BattleResourceManager:LoadResAsync(caller, assetPath, successCallback, failedCallback, resType, unLoadType, cacheTime, priority)
  self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, resType, unLoadType, cacheTime, priority)
end

function BattleResourceManager:LoadResAsyncWithParam(caller, assetPath, successCallback, failedCallback, ...)
  local request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback)
  request:SetSuccessParam(...)
  return request
end

function BattleResourceManager:LoadResAsyncThunk(caller, assetPath, resType, unLoadType, cacheTime, priority, callback)
  self:LoadAssetAsync(caller, assetPath, function(callbackOwner, asset, request)
    tcall(callbackOwner, callback, true, asset, request)
  end, function(callbackOwner, request, errMsg)
    tcall(callbackOwner, callback, false, errMsg, request)
  end, resType, unLoadType, cacheTime, priority)
end

function BattleResourceManager:LoadResWithParam(caller, assetPath, successCallback, failedCallback, ...)
  local request = self:GetCacheAsset(assetPath)
  if request then
    request:SetData(request.request, request.unloadType, request.resType, request.cacheTime, successCallback, failedCallback, caller)
    request:SetSuccessParam(...)
    self:LoadAssetSuccessCallBack(request.request, request.assert, request)
  else
    request = self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback)
    request:SetSuccessParam(...)
  end
end

function BattleResourceManager:LoadRes(caller, assetPath, successCallback, failedCallback)
  local request = self:GetCacheAsset(assetPath)
  if request then
    request:SetData(request.request, request.unloadType, request.resType, request.cacheTime, successCallback, failedCallback, caller)
    self:LoadAssetSuccessCallBack(request.request, request.assert, request)
  else
    self:LoadAssetAsync(caller, assetPath, successCallback, failedCallback)
  end
end

function BattleResourceManager:LoadAssetAsync(caller, assetPath, successCallback, failedCallback, resType, unLoadType, cacheTime, priority)
  priority = priority or PriorityEnum.Passive_Battle_Default
  unLoadType = unLoadType or BattleResourceManager.UnloadType.END_GAME
  resType = resType or BattleResourceManager.ResourceType.OTHER
  cacheTime = 99999
  local cache = self:GetCacheAsset(assetPath)
  local battleRequest = self:GetNewBattleRequest()
  if cache and UE4.UObject.IsValid(cache) then
    battleRequest:SetData(cache.request, unLoadType, resType, cacheTime, successCallback, failedCallback, caller)
    battleRequest.assert = cache.assert
    battleRequest.LockBattleRequest = cache
    cache.Lock = cache.Lock + 1
    cache.unloadType = math.max(cache.unloadType, unLoadType)
    cache.cacheTime = 999999
    table.insert(self.selfLoadQuest, battleRequest)
  else
    local request = NRCResourceManager:LoadResAsync(self, assetPath, priority, cacheTime or -1, self.LoadAssetSuccessCallBack, self.LoadAssetFailCallBack, self.LoadAssetProgressCallBack)
    battleRequest:SetData(request, unLoadType, resType, cacheTime, successCallback, failedCallback, caller)
    self.requestMap[request.sessionId] = battleRequest
  end
  return battleRequest
end

function BattleResourceManager:GetNewBattleRequest()
  local battleRequest
  if #self.requestPool > 0 then
    battleRequest = self.requestPool[#self.requestPool]
    battleRequest:ResetData()
    table.remove(self.requestPool, #self.requestPool)
  end
  if nil == battleRequest then
    battleRequest = BattleRequest()
  end
  return battleRequest
end

function BattleResourceManager:GetCacheAsset(assetPath)
  for _, v in pairs(self.requestMap) do
    if v.request and UE.UObject.IsValid(v.assert) and v.request.assetPath == assetPath then
      return v
    end
  end
  return nil
end

function BattleResourceManager:GetCacheAssetDirect(assetPath, silent)
  for _, v in pairs(self.requestMap) do
    if v.request and v.assert and v.request.assetPath == assetPath then
      return v.assert
    end
  end
  if not silent then
    Log.Error("BattleResourceManager GetCacheAssetDirect fail:", assetPath)
  end
  return nil
end

function BattleResourceManager:PreloadAssetAsync(caller, assetPath, successCallback, failedCallback, cacheTime, priority)
  cacheTime = cacheTime or 255
  priority = priority or PriorityEnum.Passive_Battle_Default
  local request = NRCResourceManager:LoadResAsync(caller, assetPath, priority, cacheTime, successCallback, failedCallback, nil)
  self.preloadReqDict[assetPath] = request
end

function BattleResourceManager:UnLoadPreloadAsset()
  for assetPath, req in pairs(self.preloadReqDict) do
    NRCResourceManager:UnLoadRes(req)
  end
  self.preloadReqDict = {}
end

function BattleResourceManager:LoadAssetSuccessCallBack(resRequest, asset, battleRequest)
  local request = battleRequest or self.requestMap[resRequest.sessionId]
  if request and request.successCallback then
    request.assert = asset
    request.assetRef = UnLua.Ref(asset)
    if request.resType == BattleResourceManager.ResourceType.Widget then
      local parent = self.param and self.param.containObj or _G.UE4Helper.GetCurrentWorld() or request.caller
      asset = UE4.UWidgetBlueprintLibrary.Create(parent, asset, self.param and self.param.own)
    elseif request.resType == BattleResourceManager.ResourceType.ACTOR then
      asset = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(asset, request.param.transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, request.param.param)
    end
    if request.successParam then
      request.successCallback(request.caller, asset, table.unpack(request.successParam))
    else
      request.successCallback(request.caller, asset)
    end
  end
end

function BattleResourceManager:LoadAssetFailCallBack(resRequest, errMsg)
  local request = self.requestMap[resRequest.sessionId]
  if request and request.failCallback then
    request.failCallback(request.caller, request, errMsg)
  end
  self:RecycleRequest(resRequest.sessionId)
end

function BattleResourceManager:LoadAssetProgressCallBack(resRequest, progress)
end

function BattleResourceManager:UnLoadAssetByType(unloadType)
  local unloadArray = {}
  if unloadType == BattleResourceManager.UnloadType.END_GAME then
    for i = #self.selfLoadQuest, 1, -1 do
      local re = self.selfLoadQuest[i]
      if unloadType >= re.unloadType then
        if re.LockBattleRequest then
          re.LockBattleRequest.Lock = re.LockBattleRequest.Lock - 1
        end
        re:ResetData()
        table.remove(self.selfLoadQuest, i)
        table.insert(self.requestPool, re)
      end
    end
  end
  for _, v in pairs(self.requestMap) do
    if v.unloadType == unloadType and v.Lock <= 0 then
      unloadArray[#unloadArray + 1] = v
    end
  end
  for _, v in ipairs(unloadArray) do
    self:UnLoadAsset(v)
  end
  if unloadType == BattleResourceManager.UnloadType.TIME then
    self.burnTime = 0
  end
end

function BattleResourceManager:UnLoadAsset(request)
  if request then
    if request.request then
      self:RecycleRequest(request.request.sessionId)
      request:UnloadRequest()
    end
    request:ResetData()
  end
end

function BattleResourceManager:RecycleRequest(sessionId)
  local request = self.requestMap[sessionId]
  if request then
    self.requestMap[sessionId] = nil
    table.insert(self.requestPool, request)
  end
end

function BattleResourceManager:ClearRequestPool()
  self.requestPool = {}
  self.requestMap = {}
end

function BattleResourceManager:PreloadPvpAssetOutsideBattle()
  local preloadResList = {
    _G.UEPath.BP_BattleFieldConf,
    BattleConst.BattleDepthCam,
    _G.UEPath.UMG_Battle_Buff,
    BattleConst.UI.UMG_Battle_Common_1,
    BattleConst.UI.UMG_Battle_BuffEffectUp,
    BattleConst.UI.UMG_Battle_DamageGeneral,
    BattleConst.MimicRemove,
    _G.UEPath.UMG_Battle_Buff,
    _G.UEPath.UMG_Battle_BuffInfoItem_C,
    BattleConst.BP_BattleEQSRunner_C,
    BattleConst.HandheldShake,
    BattleConst.HandheldWaterShake,
    _G.UEPath.BP_BattlePlayerComponents
  }
  for i = 1, #preloadResList do
    _G.BattleResourceManager:LoadResAsync(self, preloadResList[i], nil, nil)
  end
  local skillLst = {
    BattleConst.PvPEnter.TwoPlayerSkill_C,
    BattleConst.PvPEnter.TwoPlayerPetSkill_C,
    BattleConst.PvPEnter.TwoEnemyPetSkill_C,
    BattleConst.PvPEnter.TwoEnemySkill_C
  }
  _G.BattleSkillManager:PreLoadRes(skillLst, false)
  NRCPanelManager:PreloadPanel("/Game/NewRoco/Modules/Core/Battle/UMG_EntryHud")
  NRCPanelManager:PreloadPanel("/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleMainWindow")
end

function BattleResourceManager:UnloadPvpAssetOutsideBattle()
end

function BattleResourceManager:OnTick(deltaTime)
  self.burnTime = self.burnTime + deltaTime
  if self.burnTime > 10 then
    for _, v in pairs(self.requestMap) do
      if v.unloadType == BattleResourceManager.UnloadType.TIME then
        v:BurnTime(self.burnTime)
      end
    end
    self.burnTime = 0
  end
  for i = #self.selfLoadQuest, 1, -1 do
    local re = self.selfLoadQuest[i]
    if re.LockBattleRequest then
      re.LockBattleRequest.Lock = re.LockBattleRequest.Lock - 1
    end
    if re.assert then
      self:LoadAssetSuccessCallBack(re.request, re.assert, re)
    end
    re:ResetData()
    table.remove(self.selfLoadQuest, i)
    table.insert(self.requestPool, re)
  end
end

return BattleResourceManager

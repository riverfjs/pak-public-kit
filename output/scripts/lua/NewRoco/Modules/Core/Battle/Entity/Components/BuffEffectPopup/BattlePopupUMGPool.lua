local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UmgCacheInfo = NRCClass("UmgCacheInfo")

function UmgCacheInfo:Ctor(umgPath)
  self.umg = nil
  self.umgPath = umgPath
  self.umgRef = nil
  self.hasAddParent = false
  self.isDestroyed = false
  self.isInUse = false
  self.isLoad = false
end

function UmgCacheInfo:OnLoad(umg)
  self.umg = umg
  self.umgRef = UnLua.Ref(umg)
  self.isLoad = true
end

function UmgCacheInfo:SetUse()
  self.isInUse = true
  if self.umg and self.umg.SetVisibility then
    self.umg:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UmgCacheInfo:IsUse()
  return self.isInUse
end

function UmgCacheInfo:AddParent(parent)
  if not self.hasAddParent and parent and UE4.UObject.IsValid(parent) then
    self.hasAddParent = true
    parent:AddChildtoCanvas(self.umg)
  end
end

function UmgCacheInfo:Release()
  self.isInUse = false
  self.hasAddParent = false
  if self.umg then
    if self.umg.Reset then
      self.umg:Reset()
    end
    if self.umg.SetVisibility then
      self.umg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UmgCacheInfo:IsValid()
  if self.umg and UE.UObject.IsValid(self.umg) then
    return true
  end
  self:Reset()
  return false
end

function UmgCacheInfo:Reset()
  self.isInUse = false
  self.hasAddParent = false
  self.isLoad = false
  if self.umg and UE4.UObject.IsValid(self.umg) then
    if self.umg.RemoveFromParent then
      self.umg:RemoveFromParent()
    end
    self.umg = nil
  end
  if self.umgRef and UE.UObject.IsValid(self.umgRef) then
    UnLua.Unref(self.umgRef)
    self.umgRef = nil
  end
end

function UmgCacheInfo:Destroy()
  self.isDestroyed = true
  self:Reset()
end

local BattlePopupUMGPool = NRCClass("BattlePopupUMGPool")
local DEFAULT_CONFIG = {
  initialSize = 2,
  maxSize = 10,
  preloadCount = 3
}

function BattlePopupUMGPool:Ctor(owner)
  self.owner = owner
  self.umgCacheInfo = {}
  self.poolConfig = {}
  self.umgRef = {}
  self.isDestroyed = false
  self.debugMode = true
  self:InitConfig()
end

function BattlePopupUMGPool:InitConfig()
  local poolConfigs = {
    [BattleConst.UI.UMG_Battle_DamageGeneral] = {
      initialSize = 3,
      maxSize = 10,
      preloadCount = 3
    },
    [BattleConst.UI.UMG_Battle_HealNumber] = {
      initialSize = 1,
      maxSize = 10,
      preloadCount = 1
    },
    [BattleConst.UI.UMG_Battle_Common_1] = {
      initialSize = 1,
      maxSize = 5,
      preloadCount = 1
    },
    [BattleConst.UI.UMG_Battle_Miss] = {
      initialSize = 1,
      maxSize = 5,
      preloadCount = 1
    },
    [BattleConst.UI.UMG_Battle_BuffEffectUp] = {
      initialSize = 1,
      maxSize = 5,
      preloadCount = 1
    },
    [BattleConst.UI.UMG_Battle_BuffEffectDown] = {
      initialSize = 1,
      maxSize = 5,
      preloadCount = 1
    }
  }
  for umgPath, config in pairs(poolConfigs) do
    self.poolConfig[umgPath] = {
      initialSize = config.initialSize or DEFAULT_CONFIG.initialSize,
      maxSize = config.maxSize or DEFAULT_CONFIG.maxSize,
      preloadCount = config.preloadCount or DEFAULT_CONFIG.preloadCount
    }
  end
end

function BattlePopupUMGPool:Acquire(umgPath, callback, callbackOwner, parent)
  if self.isDestroyed then
    Log.Error("[BattlePopupUMGPool] Pool is destroyed, cannot acquire")
    self:LoadCallBack(nil, false, callback, callbackOwner)
    return
  end
  local config = self.poolConfig[umgPath]
  if not config then
    config = DEFAULT_CONFIG
    self.poolConfig[umgPath] = {
      initialSize = config.initialSize,
      maxSize = config.maxSize,
      preloadCount = config.preloadCount
    }
  end
  if not self.umgCacheInfo[umgPath] then
    self.umgCacheInfo[umgPath] = {}
  end
  local cacheInfos = self.umgCacheInfo[umgPath]
  for i, cacheInfo in pairs(cacheInfos) do
    if cacheInfo.isLoad and cacheInfo:IsValid() and not cacheInfo:IsUse() then
      local umg = cacheInfo.umg
      cacheInfo:SetUse()
      cacheInfo:AddParent(parent)
      if self.debugMode then
        Log.DebugFormat("[BattlePopupUMGPool] Reuse UMG from pool: %s parent:%s", umgPath, parent)
      end
      self:LoadCallBack(umg, true, callback, callbackOwner)
      return
    end
  end
  table.insert(self.umgCacheInfo[umgPath], UmgCacheInfo(umgPath))
  self:_CreateNewUMG(umgPath, callback, callbackOwner, parent)
end

function BattlePopupUMGPool:LoadCallBack(umg, isSucceed, callback, callbackOwner, isNew)
  if not callback then
    return
  end
  if callbackOwner then
    callback(callbackOwner, umg, isSucceed, isNew)
  else
    callback(umg, isSucceed, isNew)
  end
end

function BattlePopupUMGPool:_CreateNewUMG(umgPath, callback, callbackOwner, parent)
  local config = self.poolConfig[umgPath]
  if not config then
    Log.Warning("[BattlePopupUMGPool] No config found for %s", umgPath)
    self:LoadCallBack(nil, false, callback, callbackOwner)
    return
  end
  local BattleMain = BattleUtils.GetMainWindow()
  if not BattleMain then
    Log.Error("[BattlePopupUMGPool] BattleMain not found")
    self:LoadCallBack(nil, false, callback, callbackOwner)
    return
  end
  BattleResourceManager:LoadWidgetAsync(self, umgPath, nil, function(caller, retUMG)
    if not retUMG or not UE.UObject.IsValid(retUMG) then
      self:LoadCallBack(nil, false, callback, callbackOwner)
      return
    end
    local cacheInfos = self.umgCacheInfo[umgPath]
    for i, v in ipairs(cacheInfos) do
      if not v:IsValid() then
        v:OnLoad(retUMG)
        v:SetUse()
        v:AddParent(parent)
        break
      end
    end
    if self.debugMode then
      Log.DebugFormat("[BattlePopupUMGPool] Created new UMG: %s, total created: %d parent:%s", umgPath, #cacheInfos, parent)
    end
    self:LoadCallBack(retUMG, true, callback, callbackOwner, true)
  end, nil, BattleMain)
end

function BattlePopupUMGPool:Release(umg, umgPath)
  local cacheInfos = self.umgCacheInfo[umgPath]
  if not cacheInfos then
    return
  end
  if self.isDestroyed then
    for i, cacheInfo in pairs(cacheInfos) do
      cacheInfo:Destroy()
    end
    self.umgCacheInfo[umgPath] = nil
    return
  end
  for i, cacheInfo in pairs(cacheInfos) do
    if cacheInfo.umg == umg then
      cacheInfo:Release()
      break
    end
  end
  if self.debugMode then
    Log.DebugFormat("[BattlePopupUMGPool] Release UMG to pool: %s", umgPath)
  end
end

function BattlePopupUMGPool:Preload(callback, callbackOwner)
  if self.isDestroyed then
    self:LoadCallBack(nil, false, callback, callbackOwner)
    return
  end
  Log.Debug("[BattlePopupUMGPool] Start preloading...")
  local preloadList = {}
  for umgPath, config in pairs(self.poolConfig) do
    for i = 1, config.preloadCount do
      table.insert(preloadList, umgPath)
    end
  end
  local loadedCount = 0
  local totalCount = #preloadList
  if 0 == totalCount then
    self:LoadCallBack(true, false, callback, callbackOwner)
    return
  end
  for _, umgPath in ipairs(preloadList) do
    local config = self.poolConfig[umgPath]
    local currentSize = #(self.umgCacheInfo[umgPath] or {})
    if currentSize < config.preloadCount then
      self:Acquire(umgPath, function(umg, success)
        if success and umg then
          self:Release(umg, umgPath)
        end
        loadedCount = loadedCount + 1
        if loadedCount >= totalCount then
          Log.DebugFormat("[BattlePopupUMGPool] Preload completed, loaded: %d", loadedCount)
          self:LoadCallBack(umg, true, callback, callbackOwner, true)
        end
      end)
    else
      loadedCount = loadedCount + 1
      if totalCount <= loadedCount then
        Log.DebugFormat("[BattlePopupUMGPool] Preload completed (already loaded), loaded: %d", loadedCount)
        self:LoadCallBack(nil, false, callback, callbackOwner)
      end
    end
  end
end

function BattlePopupUMGPool:Destroy()
  if self.isDestroyed then
    return
  end
  self.isDestroyed = true
  Log.Debug("[BattlePopupUMGPool] Destroying pool...")
  for i, CacheInfos in pairs(self.umgCacheInfo) do
    for _, v in pairs(CacheInfos) do
      v:Destroy()
    end
  end
end

function BattlePopupUMGPool:UpdateConfig(umgPath, config)
  if not self.poolConfig[umgPath] then
    self.poolConfig[umgPath] = {}
  end
  if config.initialSize then
    self.poolConfig[umgPath].initialSize = config.initialSize
  end
  if config.maxSize then
    self.poolConfig[umgPath].maxSize = config.maxSize
  end
  if config.preloadCount then
    self.poolConfig[umgPath].preloadCount = config.preloadCount
  end
  Log.DebugFormat("[BattlePopupUMGPool] Updated config for %s: %s", umgPath, table.toString(self.poolConfig[umgPath]))
end

return BattlePopupUMGPool

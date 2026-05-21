local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIStatistics = require("NewRoco.Modules.System.PGC.RTTI.RTTIStatistics")
local RTTICache = {
  Caches = {
    [RTTIBase.CacheType.QUERY] = {},
    [RTTIBase.CacheType.PROPERTY] = {}
  },
  LastCleanupTime = 0
}
local AppendKeyPart = function(Parts, Part)
  if nil == Part then
    return
  end
  local TypeName = type(Part)
  if "table" == TypeName then
    for PartKey, PartItem in pairs(Part) do
      if "BucketKey" ~= PartKey then
        AppendKeyPart(Parts, PartItem)
      end
    end
  elseif "function" ~= TypeName then
    table.insert(Parts, tostring(Part))
  end
end

local function BuildCacheKey(CacheType, Options)
  Options = Options or {}
  local Parts = {CacheType}
  AppendKeyPart(Parts, Options)
  return table.concat(Parts, "_")
end

local function ForEachCacheEntry(self, Callback)
  local QueryCache = self.Caches[RTTIBase.CacheType.QUERY]
  for BucketKey, Bucket in pairs(QueryCache) do
    for CacheKey, Entry in pairs(Bucket) do
      Callback(RTTIBase.CacheType.QUERY, BucketKey, CacheKey, Entry)
    end
  end
  local PropertyCache = self.Caches[RTTIBase.CacheType.PROPERTY]
  for CacheKey, Entry in pairs(PropertyCache) do
    Callback(RTTIBase.CacheType.PROPERTY, nil, CacheKey, Entry)
  end
end

local function RemoveCacheEntry(self, EntryInfo)
  local CacheTable = self.Caches[EntryInfo.Type]
  if not CacheTable then
    return
  end
  if EntryInfo.BucketKey then
    if CacheTable[EntryInfo.BucketKey] then
      CacheTable[EntryInfo.BucketKey][EntryInfo.CacheKey] = nil
    end
  else
    CacheTable[EntryInfo.CacheKey] = nil
  end
end

local function IsExpired(Entry, TTL)
  if not Entry then
    return true
  end
  if not TTL or TTL <= 0 then
    return false
  end
  return TTL < os.time() - Entry.Timestamp
end

local function AutoEvict(self)
  if RTTISettings:Get("Cache.EnableAutoCleanup") then
    local CurrentTime = os.time()
    local TimeSinceLastCleanup = CurrentTime - self.LastCleanupTime
    if TimeSinceLastCleanup >= RTTISettings:Get("Cache.CleanupInterval") then
      local TTL = RTTISettings:Get("Cache.TTL")
      local ExpiredEntries = {}
      ForEachCacheEntry(self, function(CacheType, BucketKey, CacheKey, Entry)
        if IsExpired(Entry, TTL) then
          table.insert(ExpiredEntries, {
            Type = CacheType,
            BucketKey = BucketKey,
            CacheKey = CacheKey
          })
        end
      end)
      for _, EntryInfo in ipairs(ExpiredEntries) do
        RemoveCacheEntry(self, EntryInfo)
        RTTIStatistics:RecordCacheEviction(EntryInfo.BucketKey)
        RTTIStatistics:RecordCachRemoveEntry(EntryInfo.BucketKey)
      end
      self.LastCleanupTime = CurrentTime
    end
  end
end

local function EvictLRU(self)
  local AllEntries = {}
  ForEachCacheEntry(self, function(CacheType, BucketKey, CacheKey, Entry)
    table.insert(AllEntries, {
      Type = CacheType,
      BucketKey = BucketKey,
      CacheKey = CacheKey,
      Timestamp = Entry.Timestamp
    })
  end)
  table.sort(AllEntries, function(A, B)
    return A.Timestamp < B.Timestamp
  end)
  local EvictionRatio = RTTISettings:Get("Cache.EvictionRatio", 0.25)
  local ToRemove = math.ceil(#AllEntries * EvictionRatio)
  for Index = 1, ToRemove do
    local EntryInfo = AllEntries[Index]
    RemoveCacheEntry(self, EntryInfo)
    RTTIStatistics:RecordCacheEviction(EntryInfo.BucketKey)
    RTTIStatistics:RecordCachRemoveEntry(EntryInfo.BucketKey)
  end
end

local function GetFromCache(self, CacheTable, BucketKey, CacheKey, TypeName)
  AutoEvict(self)
  local Entry
  if BucketKey then
    local Bucket = CacheTable[BucketKey]
    Entry = Bucket and Bucket[CacheKey]
  else
    Entry = CacheTable[CacheKey]
  end
  local TTL = RTTISettings:Get("Cache.TTL")
  if Entry and not IsExpired(Entry, TTL) then
    RTTIStatistics:RecordCacheHit(TypeName)
    return Entry.Value
  end
  RTTIStatistics:RecordCacheMiss(TypeName)
  return nil
end

local function SetToCache(self, CacheTable, BucketKey, CacheKey, Value, TypeName)
  local Entry = {
    Value = Value,
    Timestamp = os.time()
  }
  RTTIStatistics:RecordCacheAddEntry(TypeName)
  if BucketKey then
    local Bucket = CacheTable[BucketKey] or {}
    CacheTable[BucketKey] = Bucket
    Bucket[CacheKey] = Entry
  else
    CacheTable[CacheKey] = Entry
  end
  local Report = RTTIStatistics:GetReport()
  local TotalEntries = Report.Cache.Total
  if TotalEntries > RTTISettings:Get("Cache.MaxSize") then
    EvictLRU(self)
  end
end

function RTTICache:Initialize()
  self:Reset()
end

function RTTICache:Reset()
  for CacheType, _ in pairs(self.Caches) do
    if self.Caches[CacheType] then
      self.Caches[CacheType] = {}
    end
  end
  self.LastCleanupTime = os.time()
end

function RTTICache:GetCache(CacheType, Options)
  Options = Options or {}
  local CacheTable = self.Caches[CacheType]
  if CacheTable then
    local CacheKey = BuildCacheKey(CacheType, Options)
    local TypeName = Options.BucketKey or Options.TypeName
    return GetFromCache(self, CacheTable, Options.BucketKey, CacheKey, TypeName)
  end
end

function RTTICache:SetCache(CacheType, Value, Options)
  Options = Options or {}
  local CacheTable = self.Caches[CacheType]
  if CacheTable and Value then
    local CacheKey = BuildCacheKey(CacheType, Options)
    local TypeName = Options.BucketKey or Options.TypeName
    SetToCache(self, CacheTable, Options.BucketKey, CacheKey, Value, TypeName)
  end
end

function RTTICache:RemoveCache(CacheType, Options)
  Options = Options or {}
  local CacheTable = self.Caches[CacheType]
  if CacheTable then
    local CacheKey = BuildCacheKey(CacheType, Options)
    if Options.BucketKey then
      local Bucket = CacheTable[Options.BucketKey]
      if Bucket then
        Bucket[CacheKey] = nil
      end
    else
      CacheTable[CacheKey] = nil
    end
  end
end

function RTTICache:ClearQueryBucket(BucketKey)
  if type(BucketKey) ~= "string" or "" == BucketKey then
    return
  end
  local QueryCache = self.Caches[RTTIBase.CacheType.QUERY]
  if QueryCache and QueryCache[BucketKey] then
    QueryCache[BucketKey] = {}
  end
end

return RTTICache

local NRCClass = require("Core.NRCClass")
local Base = NRCClass
local WidgetStateDebugger = Base:Extend("WidgetStateDebugger")
local defaultMaxSnapshots = 50
local defaultMaxRenderSnapshots = 20
WidgetStateDebugger.DebugLevel = {
  None = 0,
  Minimal = 1,
  Sampled = 2,
  Full = 3
}

function WidgetStateDebugger:Ctor(option)
  option = option or {}
  self.enabled = option.enabled ~= false
  self.maxSnapshots = option.maxSnapshots or defaultMaxSnapshots
  self.maxRenderSnapshots = option.maxRenderSnapshots or defaultMaxRenderSnapshots
  local defaultDebugLevel = WidgetStateDebugger.DebugLevel.None
  if _G.RocoEnv.IS_EDITOR then
    defaultDebugLevel = WidgetStateDebugger.DebugLevel.Minimal
  end
  self.debugLevel = option.debugLevel or defaultDebugLevel
  self.stackTraceSampleRate = option.stackTraceSampleRate or 0.1
  self.snapshots = {}
  self.snapshotIndex = 0
  self.snapshotCount = 0
  self.renderSnapshots = {}
  self.renderSnapshotIndex = 0
  self.renderSnapshotCount = 0
  self.watchers = {}
  self.watchFieldPaths = {}
end

local function TableDiff(old, new)
  local diff = {}
  local allKeys = {}
  if old then
    for k in pairs(old) do
      allKeys[k] = true
    end
  end
  if new then
    for k in pairs(new) do
      allKeys[k] = true
    end
  end
  for k in pairs(allKeys) do
    local oldVal = old and old[k]
    local newVal = new and new[k]
    if oldVal ~= newVal then
      diff[tostring(k)] = {old = oldVal, new = newVal}
    end
  end
  return diff
end

local function GetChangedKeys(old, new)
  local changed = {}
  local diff = TableDiff(old, new)
  for k in pairs(diff) do
    table.insert(changed, k)
  end
  return changed
end

local function GetValueByPath(obj, path)
  if not obj or not path then
    return nil, false
  end
  local keys = {}
  for key in string.gmatch(path, "[^%.]+") do
    local arrayKey = string.match(key, "^%[(%d+)%]$")
    if arrayKey then
      table.insert(keys, tonumber(arrayKey) + 1)
    else
      local baseKey, arrayIndex = string.match(key, "^([^%[]+)%[(%d+)%]$")
      if baseKey and arrayIndex then
        table.insert(keys, baseKey)
        table.insert(keys, tonumber(arrayIndex) + 1)
      else
        table.insert(keys, key)
      end
    end
  end
  local current = obj
  for _, key in ipairs(keys) do
    if "table" ~= type(current) then
      return nil, false
    end
    current = current[key]
  end
  return current, true
end

local function FormatValue(value)
  if nil == value then
    return "nil"
  elseif type(value) == "table" then
    return table.dump(value)
  else
    return tostring(value)
  end
end

local function GetStackTrace(skip, depth)
  skip = skip or 3
  depth = depth or 5
  return debug.traceback("", skip, depth)
end

function WidgetStateDebugger:RecordSnapshot(source, prevState, nextState, ownerName, skipStack)
  if not self.enabled then
    return
  end
  local prevCopy = {}
  table.copy(prevState, prevCopy)
  local nextCopy = {}
  table.copy(nextState, nextCopy)
  local stackTrace
  if self.debugLevel == WidgetStateDebugger.DebugLevel.Full then
    stackTrace = GetStackTrace(skipStack or 3, 5)
  elseif self.debugLevel == WidgetStateDebugger.DebugLevel.Sampled and math.random() < self.stackTraceSampleRate then
    stackTrace = GetStackTrace(skipStack or 3, 5)
  end
  local snapshot = {
    timestamp = os.time(),
    source = source,
    prevState = prevCopy,
    nextState = nextCopy,
    diff = TableDiff(prevState, nextState),
    stackTrace = stackTrace,
    ownerName = ownerName or "Unknown"
  }
  self.snapshotIndex = self.snapshotIndex % self.maxSnapshots + 1
  self.snapshots[self.snapshotIndex] = snapshot
  self.snapshotCount = math.min(self.snapshotCount + 1, self.maxSnapshots)
  self:TriggerWatchers(prevState, nextState, source, ownerName)
end

function WidgetStateDebugger:RecordRender(prevProps, nextProps, prevState, nextState, ownerName)
  if not self.enabled then
    return
  end
  local prevPropsCopy = {}
  table.copy(prevProps, prevPropsCopy)
  local nextPropsCopy = {}
  table.copy(nextProps, nextPropsCopy)
  local prevStateCopy = {}
  table.copy(prevState, prevStateCopy)
  local nextStateCopy = {}
  table.copy(nextState, nextStateCopy)
  local stackTrace
  if self.debugLevel == WidgetStateDebugger.DebugLevel.Full then
    stackTrace = GetStackTrace(3, 5)
  elseif self.debugLevel == WidgetStateDebugger.DebugLevel.Sampled and math.random() < self.stackTraceSampleRate then
    stackTrace = GetStackTrace(3, 5)
  end
  local snapshot = {
    timestamp = os.time(),
    changedProps = GetChangedKeys(prevProps, nextProps),
    changedState = GetChangedKeys(prevState, nextState),
    prevProps = prevPropsCopy,
    nextProps = nextPropsCopy,
    prevState = prevStateCopy,
    nextState = nextStateCopy,
    stackTrace = stackTrace,
    ownerName = ownerName or "Unknown"
  }
  self.renderSnapshotIndex = self.renderSnapshotIndex % self.maxRenderSnapshots + 1
  self.renderSnapshots[self.renderSnapshotIndex] = snapshot
  self.renderSnapshotCount = math.min(self.renderSnapshotCount + 1, self.maxRenderSnapshots)
end

function WidgetStateDebugger:Watch(fieldPath, callback, options)
  options = options or {}
  local watcher = {
    fieldPath = fieldPath,
    callback = callback,
    immediate = options.immediate or false
  }
  table.insert(self.watchers, watcher)
  local watcherId = #self.watchers
  if watcher.immediate then
    local info = {
      source = "WatchImmediate",
      stackTrace = GetStackTrace(2),
      timestamp = os.time(),
      ownerName = "Watch"
    }
    callback(nil, nil, info)
  end
  return watcherId
end

function WidgetStateDebugger:Unwatch(watcherId)
  self.watchers[watcherId] = nil
end

function WidgetStateDebugger:ClearWatchers()
  self.watchers = {}
end

function WidgetStateDebugger:TriggerWatchers(prevState, nextState, source, ownerName)
  if not self.watchers or 0 == #self.watchers then
    return
  end
  local stackTrace
  if self.debugLevel == WidgetStateDebugger.DebugLevel.Full then
    stackTrace = GetStackTrace(3, 5)
  elseif self.debugLevel == WidgetStateDebugger.DebugLevel.Sampled and math.random() < self.stackTraceSampleRate then
    stackTrace = GetStackTrace(3, 5)
  end
  local info = {
    source = source,
    stackTrace = stackTrace,
    timestamp = os.time(),
    ownerName = ownerName
  }
  for _, watcher in ipairs(self.watchers) do
    if watcher then
      local oldVal, oldFound = GetValueByPath(prevState, watcher.fieldPath)
      local newVal, newFound = GetValueByPath(nextState, watcher.fieldPath)
      if oldVal ~= newVal then
        local ok, err = xpcall(function()
          watcher.callback(newVal, oldVal, info)
        end, debug.traceback)
        if not ok then
          Log.ErrorFormat("[WidgetStateDebugger] Watch callback error for '%s': %s", watcher.fieldPath, tostring(err))
        end
      end
    end
  end
end

function WidgetStateDebugger:GetSnapshots()
  local result = {}
  if self.snapshotCount < self.maxSnapshots then
    for i = 1, self.snapshotCount do
      table.insert(result, self.snapshots[i])
    end
  else
    local startIdx = self.snapshotIndex % self.maxSnapshots + 1
    for i = 0, self.maxSnapshots - 1 do
      local idx = (startIdx + i - 1) % self.maxSnapshots + 1
      table.insert(result, self.snapshots[idx])
    end
  end
  return result
end

function WidgetStateDebugger:GetRenderSnapshots()
  local result = {}
  if self.renderSnapshotCount < self.maxRenderSnapshots then
    for i = 1, self.renderSnapshotCount do
      table.insert(result, self.renderSnapshots[i])
    end
  else
    local startIdx = self.renderSnapshotIndex % self.maxRenderSnapshots + 1
    for i = 0, self.maxRenderSnapshots - 1 do
      local idx = (startIdx + i - 1) % self.maxRenderSnapshots + 1
      table.insert(result, self.renderSnapshots[idx])
    end
  end
  return result
end

function WidgetStateDebugger:FindChanges(fieldPath)
  local result = {}
  local snapshots = self:GetSnapshots()
  for _, snapshot in ipairs(snapshots) do
    local oldVal = GetValueByPath(snapshot.prevState, fieldPath)
    local newVal = GetValueByPath(snapshot.nextState, fieldPath)
    if oldVal ~= newVal then
      table.insert(result, {
        snapshot = snapshot,
        oldValue = oldVal,
        newValue = newVal
      })
    end
  end
  return result
end

function WidgetStateDebugger:GetLastSnapshot()
  if 0 == self.snapshotCount then
    return nil
  end
  return self.snapshots[self.snapshotIndex]
end

function WidgetStateDebugger:GetLastRenderSnapshot()
  if 0 == self.renderSnapshotCount then
    return nil
  end
  return self.renderSnapshots[self.renderSnapshotIndex]
end

function WidgetStateDebugger:PrintHistory(count)
  if not self.enabled then
    Log.Error("[WidgetStateDebugger] Debugger is disabled")
    return
  end
  local snapshots = self:GetSnapshots()
  local total = #snapshots
  count = count or total
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  Log.Error(string.format("[WidgetStateDebugger] State Change History (showing %d of %d)", math.min(count, total), total))
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  local startIdx = math.max(1, total - count + 1)
  for i = startIdx, total do
    local snapshot = snapshots[i]
    Log.Error(string.format([[

[%d] Source: %s | Owner: %s | Time: %s]], i - startIdx + 1, snapshot.source, snapshot.ownerName, os.date("%H:%M:%S", snapshot.timestamp)))
    Log.Error(string.format("    Diff: %s", table.dump(snapshot.diff)))
    if snapshot.stackTrace then
      Log.Error(string.format("    Stack: %s", snapshot.stackTrace))
    end
  end
end

function WidgetStateDebugger:PrintRenderHistory(count)
  if not self.enabled then
    Log.Error("[WidgetStateDebugger] Debugger is disabled")
    return
  end
  local snapshots = self:GetRenderSnapshots()
  local total = #snapshots
  count = count or total
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  Log.Error(string.format("[WidgetStateDebugger] Render History (showing %d of %d)", math.min(count, total), total))
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  local startIdx = math.max(1, total - count + 1)
  for i = startIdx, total do
    local snapshot = snapshots[i]
    Log.Error(string.format([[

[%d] Owner: %s | Time: %s]], i - startIdx + 1, snapshot.ownerName, os.date("%H:%M:%S", snapshot.timestamp)))
    Log.Error(string.format("    Changed Props: %s", table.concat(snapshot.changedProps, ", ")))
    Log.Error(string.format("    Changed State: %s", table.concat(snapshot.changedState, ", ")))
  end
end

function WidgetStateDebugger:PrintFieldChanges(fieldPath)
  if not self.enabled then
    Log.Error("[WidgetStateDebugger] Debugger is disabled")
    return
  end
  local changes = self:FindChanges(fieldPath)
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  Log.Error(string.format("[WidgetStateDebugger] Field Changes for '%s' (%d records)", fieldPath, #changes))
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  for i, change in ipairs(changes) do
    Log.Error(string.format([[

[%d] Source: %s | Owner: %s | Time: %s]], i, change.snapshot.source, change.snapshot.ownerName, os.date("%H:%M:%S", change.snapshot.timestamp)))
    Log.Error(string.format("    Old: %s", FormatValue(change.oldValue)))
    Log.Error(string.format("    New: %s", FormatValue(change.newValue)))
    if change.snapshot.stackTrace then
      Log.Error(string.format("    Stack: %s", change.snapshot.stackTrace))
    end
  end
end

function WidgetStateDebugger:PrintCurrentState()
  local lastSnapshot = self:GetLastSnapshot()
  if not lastSnapshot then
    Log.Error("[WidgetStateDebugger] No snapshots recorded yet")
    return
  end
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  Log.Error(string.format("[WidgetStateDebugger] Current State (Owner: %s)", lastSnapshot.ownerName))
  Log.Error(string.format("\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144"))
  Log.Error(string.format("State: %s", FormatValue(lastSnapshot.nextState)))
end

function WidgetStateDebugger:Enable()
  self.enabled = true
end

function WidgetStateDebugger:Disable()
  self.enabled = false
end

function WidgetStateDebugger:IsEnabled()
  return self.enabled
end

function WidgetStateDebugger:SetDebugLevel(level)
  self.debugLevel = level
end

function WidgetStateDebugger:GetDebugLevel()
  return self.debugLevel
end

function WidgetStateDebugger:SetStackTraceSampleRate(rate)
  self.stackTraceSampleRate = math.max(0, math.min(1, rate))
end

function WidgetStateDebugger:ClearSnapshots()
  self.snapshots = {}
  self.snapshotIndex = 0
  self.snapshotCount = 0
  self.renderSnapshots = {}
  self.renderSnapshotIndex = 0
  self.renderSnapshotCount = 0
end

function WidgetStateDebugger:Dispose()
  self:ClearSnapshots()
  self:ClearWatchers()
  self.enabled = false
end

function WidgetStateDebugger.New(option)
  return WidgetStateDebugger(option)
end

return WidgetStateDebugger

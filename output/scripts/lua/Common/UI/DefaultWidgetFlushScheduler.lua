local WidgetFlushSchedulerBase = require("Common.UI.WidgetFlushSchedulerBase")
local Base = WidgetFlushSchedulerBase
local DefaultWidgetFlushScheduler = Base:Extend("DefaultWidgetFlushScheduler")

function DefaultWidgetFlushScheduler:Ctor()
  Base.Ctor(self)
  self.pendingDelays = {}
end

function DefaultWidgetFlushScheduler:Schedule(flushFn, source)
  if self.pendingDelays[source] then
    return
  end
  local delayId = _G.DelayManager:DelayFrames(1, function()
    self.pendingDelays[source] = nil
    flushFn()
  end)
  self.pendingDelays[source] = {delayId = delayId, flushFn = flushFn}
end

function DefaultWidgetFlushScheduler:Cancel(source)
  local pending = self.pendingDelays[source]
  if pending then
    _G.DelayManager:CancelDelayById(pending.delayId)
    self.pendingDelays[source] = nil
  end
end

function DefaultWidgetFlushScheduler:Flush(source)
  local pending = self.pendingDelays[source]
  if pending then
    _G.DelayManager:CancelDelayById(pending.delayId)
    self.pendingDelays[source] = nil
    pending.flushFn()
  end
end

function DefaultWidgetFlushScheduler:Dispose()
  for _, delayId in pairs(self.pendingDelays) do
    _G.DelayManager:CancelDelayById(delayId)
  end
  self.pendingDelays = {}
end

local _defaultScheduler

function DefaultWidgetFlushScheduler.GetDefault()
  if not _defaultScheduler then
    _defaultScheduler = DefaultWidgetFlushScheduler()
  end
  return _defaultScheduler
end

return DefaultWidgetFlushScheduler

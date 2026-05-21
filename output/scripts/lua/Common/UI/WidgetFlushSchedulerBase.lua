local NRCClass = require("Core.NRCClass")
local Base = NRCClass
local WidgetFlushSchedulerBase = Base:Extend("WidgetFlushSchedulerBase")

function WidgetFlushSchedulerBase:Schedule(flushFn, source)
  error("WidgetFlushSchedulerBase:Schedule must be overridden by subclass")
end

function WidgetFlushSchedulerBase:Flush(source)
  error("WidgetFlushSchedulerBase:Flush must be overridden by subclass")
end

function WidgetFlushSchedulerBase:Cancel(source)
  error("WidgetFlushSchedulerBase:Cancel must be overridden by subclass")
end

function WidgetFlushSchedulerBase:Dispose()
  error("WidgetFlushSchedulerBase:Dispose must be overridden by subclass")
end

return WidgetFlushSchedulerBase

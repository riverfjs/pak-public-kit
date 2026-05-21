local HomeTask = Class("HomeTask")

function HomeTask:Ctor()
  self.bFinished = false
end

function HomeTask:ToString()
  if self.DebugStr then
    return self.DebugStr
  end
  if self.DebugInfo then
    local func = self.DebugInfo.short_src
    local currline = self.DebugInfo.currentline
    self.DebugStr = string.format("%s[%s:%s]", self.className, func, currline)
    return self.DebugStr
  end
  return ""
end

function HomeTask:NotifyFinish(...)
  if self.bFinished then
    return
  end
  HomeIndoorSandbox:LogInfo("NotifyFinish", self:ToString())
  self.bFinished = true
  if self.OnFinishFeedback then
    self.OnFinishFeedback(...)
  end
end

function HomeTask:IsRunning()
  return self.bRunning
end

function HomeTask:IsFinish()
  return self.bFinished
end

return HomeTask

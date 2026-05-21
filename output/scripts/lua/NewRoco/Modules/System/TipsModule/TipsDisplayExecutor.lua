local TipUtils = require("NewRoco.Modules.System.TipsModule.Utils.TipUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local TipsDisplayExecutorId = 0

local function GetTipsDisplayExecutorTag()
  TipsDisplayExecutorId = TipsDisplayExecutorId + 1
  return "TipsDisplayExecutor" .. TipsDisplayExecutorId
end

local TipsDisplayExecutor = NRCClass()

function TipsDisplayExecutor:Ctor()
  self.logTag = GetTipsDisplayExecutorTag()
  self.pauseReasons = {}
  self.sortCompareFunc = nil
  self.tipList = {}
  self.displayingTip = nil
  self.delayProcessId = nil
end

function TipsDisplayExecutor:__Dctor()
  self:Free()
end

function TipsDisplayExecutor:Attach(owner, _onTipDisplayStart, _onTipTick, _onTipDisplayEnd, _onTipDisplayStatusChange)
  Log.Debug(self.logTag, "Attach")
  self.onTipDisplayStart = _onTipDisplayStart and _G.MakeWeakFunctor(owner, _onTipDisplayStart)
  self.onTipTick = _onTipTick and _G.MakeWeakFunctor(owner, _onTipTick)
  self.onTipDisplayEnd = _onTipDisplayEnd and _G.MakeWeakFunctor(owner, _onTipDisplayEnd)
  self.onTipDisplayStatusChange = _onTipDisplayStatusChange and _G.MakeWeakFunctor(owner, _onTipDisplayStatusChange)
  return self
end

function TipsDisplayExecutor:Detach()
  Log.Debug(self.logTag, "Detach")
  self.onTipDisplayStart = nil
  self.onTipTick = nil
  self.onTipDisplayEnd = nil
  self.onTipDisplayStatusChange = nil
  return self
end

function TipsDisplayExecutor:Free()
  Log.Debug(self.logTag, "Free")
  self:Clear()
  if self.listeningTipDispatchState then
    self.listeningTipDispatchState = false
    _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_DisplayCoordinatorPaused, self.OnDisplayCoordinatorPausedHandle)
    _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_DisplayCoordinatorResumed, self.OnDisplayCoordinatorResumed)
    _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_DisplayCoordinatorAreaBlock, self.OnDisplayCoordinatorAreaBlock)
  end
end

function TipsDisplayExecutor:StartTipDispatchStateListener()
  if self.listeningTipDispatchState then
    return
  end
  self.listeningTipDispatchState = true
  _G.NRCEventCenter:RegisterEvent("TipsDisplayExecutor", self, TipsModuleEvent.Tips_DisplayCoordinatorPaused, self.OnDisplayCoordinatorPausedHandle)
  _G.NRCEventCenter:RegisterEvent("TipsDisplayExecutor", self, TipsModuleEvent.Tips_DisplayCoordinatorResumed, self.OnDisplayCoordinatorResumed)
  _G.NRCEventCenter:RegisterEvent("TipsDisplayExecutor", self, TipsModuleEvent.Tips_DisplayCoordinatorAreaBlock, self.OnDisplayCoordinatorAreaBlock)
end

function TipsDisplayExecutor:AddDisplayTip(tip)
  TipUtils.DebugTipFlow("[AddDisplayTip]", tip)
  table.insert(self.tipList, tip)
  if #self.tipList > 1 and self.sortCompareFunc then
    table.stableSort(self.tipList, self.sortCompareFunc)
  end
  if not self.displayingTip and not self.delayActiveId then
    self.delayActiveId = _G.DelayManager:DelayFrames(1, self.ActiveProcess, self)
  end
end

function TipsDisplayExecutor:StopQueuedTips(ConditionFunc)
  for i = #self.tipList, 1, -1 do
    local tip = self.tipList[i]
    if ConditionFunc(tip) then
      TipUtils.DebugTipFlow("[StopQueuedTips]", self.tip)
      tip:MarkFinished()
      table.remove(self.tipList, i)
    end
  end
  local tip = self:GetDisplayingTip()
  if tip and ConditionFunc(tip) then
    Log.Debug("TipsDisplayExecutor:StopTipsImmediately Current", tip.type, tip.tipCustomType)
  end
end

function TipsDisplayExecutor:ConsumeNextTip()
  self.waitingUserAgreeFinish = false
  if #self.tipList > 0 then
    self:DoFinishCurDisplayTip()
    if not self:IsPaused() then
      self:DoStartDisplayTip()
    end
  else
    if self.onTipDisplayEnd then
      local ok, ret = pcall(self.onTipDisplayEnd)
      if ok and ret then
        self.waitingUserAgreeFinish = true
      end
    end
    if not self.waitingUserAgreeFinish then
      self:DoFinishCurDisplayTip()
    else
      TipUtils.DebugTipFlow("waitingUserAgreeFinish...", self.displayingTip)
    end
  end
end

function TipsDisplayExecutor:UserAgreeFinish()
  if not self.waitingUserAgreeFinish then
    return
  end
  TipUtils.DebugTipFlow("[UserAgreeFinish]", self.displayingTip)
  self.waitingUserAgreeFinish = false
  self:DoFinishCurDisplayTip()
end

function TipsDisplayExecutor:GetNextTip()
  return self.tipList[1]
end

function TipsDisplayExecutor:GetDisplayingTip()
  return self.displayingTip
end

function TipsDisplayExecutor:EnableTipSort(comp)
  self.sortCompareFunc = comp
end

function TipsDisplayExecutor:TraverseCacheData(handler)
  if #self.tipList <= 0 or not handler then
    return
  end
  for _index, _tip in ipairs(self.tipList) do
    if handler(_index, _tip) then
      break
    end
  end
end

function TipsDisplayExecutor:Pause(reason, finishCur)
  if string.IsNilOrEmpty(reason) then
    Log.Error(self.logTag, "pause tip executor should give valid reason!")
    return
  end
  Log.Debug(self.logTag, "Pause", reason, finishCur)
  if finishCur then
    self:DoFinishCurDisplayTip()
  end
  self.pauseReasons = self.pauseReasons or {}
  if self.pauseReasons[reason] then
    return
  end
  local inPausing = self:IsPaused()
  self.pauseReasons[reason] = true
  if not inPausing and self.onTipDisplayStatusChange then
    pcall(self.onTipDisplayStatusChange, true)
  end
  if self.onExecutorPauseReasonChangeCallback then
    pcall(self.onExecutorPauseReasonChangeCallback)
  end
end

function TipsDisplayExecutor:Resume(reason)
  if string.IsNilOrEmpty(reason) then
    Log.Error(self.logTag, "resume tip executor should give valid reason!")
    return
  end
  Log.Debug(self.logTag, "Resume", reason)
  if not self.pauseReasons or not self.pauseReasons[reason] then
    return
  end
  self.pauseReasons[reason] = nil
  if not self:IsPaused() then
    if self.onTipDisplayStatusChange then
      pcall(self.onTipDisplayStatusChange, false)
    end
    if not self.displayingTip and not self.delayProcessId and #self.tipList > 0 then
      self:ConsumeNextTip()
    end
  end
  if self.onExecutorPauseReasonChangeCallback then
    pcall(self.onExecutorPauseReasonChangeCallback)
  end
end

function TipsDisplayExecutor:SetPauseReasonChangeCallback(caller, callback, ...)
  self.onExecutorPauseReasonChangeCallback = _G.MakeWeakFunctor(caller, callback, ...)
end

function TipsDisplayExecutor:IsPausedExcept(reason)
  if not self.pauseReasons or next(self.pauseReasons) == nil then
    return false
  end
  if not reason then
    reason = {}
  elseif type(reason) ~= "table" then
    reason = {reason}
  end
  if next(reason) == nil then
    return self:IsPaused()
  else
    for _reason, _ in pairs(self.pauseReasons) do
      if not table.contains(reason, _reason) then
        return true
      end
    end
  end
  return false
end

function TipsDisplayExecutor:Clear()
  Log.Debug(self.logTag, "Clear")
  self:DoFinishCurDisplayTip()
  for _, _tip in ipairs(self.tipList) do
    _tip:MarkFinished()
  end
  self.tipList = {}
  if self.onTipDisplayEnd then
    pcall(self.onTipDisplayEnd)
  end
  if self.delayActiveId then
    _G.DelayManager:CancelDelayById(self.delayActiveId)
    self.delayActiveId = nil
  end
end

function TipsDisplayExecutor:GetDebugInfo()
  return {
    logTag = self.logTag,
    displayingTip = self.displayingTip,
    tipList = self.tipList,
    pauseReasons = self.pauseReasons,
    waitingUserAgreeFinish = self.waitingUserAgreeFinish
  }
end

function TipsDisplayExecutor:IsPaused()
  return self.pauseReasons and next(self.pauseReasons) ~= nil
end

function TipsDisplayExecutor:ActiveProcess()
  self.delayActiveId = nil
  if not self.displayingTip then
    self:ConsumeNextTip()
  end
end

function TipsDisplayExecutor:DoStartDisplayTip()
  if #self.tipList > 0 then
    local tip = table.remove(self.tipList, 1)
    self.displayingTip = tip
    self.displayingTip:MarkDisplaying()
    local startSuccess = false
    if self.onTipDisplayStart then
      startSuccess, err = pcall(self.onTipDisplayStart, tip)
      if not startSuccess then
        Log.Error(self.logTag, "tip start failed.", err)
      end
    end
    if startSuccess then
      self:StartDelayProcess(tip)
    else
      self:ConsumeNextTip()
    end
  end
end

function TipsDisplayExecutor:StartDelayProcess(tip)
  local delayInterval = 0
  if tip.timeLeft and tip.timeLeft > 0 then
    if tip.tickInterval and tip.tickInterval > 0 then
      delayInterval = math.min(tip.tickInterval, tip.timeLeft)
    else
      delayInterval = tip.timeLeft
    end
  end
  if delayInterval > 0 then
    self.delayProcessId = _G.DelayManager:DelaySeconds(delayInterval, self.OnDelayProcess, self, tip, delayInterval)
  end
end

function TipsDisplayExecutor:OnDelayProcess(tip, delayInterval)
  self.delayProcessId = nil
  if self:IsPaused() then
    self:StartDelayProcess(tip)
  else
    tip.timeLeft = tip.timeLeft - delayInterval
    if tip.timeLeft > 0 then
      if self.onTipTick then
        pcall(self.onTipTick, tip, delayInterval)
      end
      self:StartDelayProcess(tip)
    else
      self:ConsumeNextTip()
    end
  end
end

function TipsDisplayExecutor:CancelDelayProcess()
  if self.delayProcessId then
    _G.DelayManager:CancelDelayById(self.delayProcessId)
  end
  self.delayProcessId = nil
end

function TipsDisplayExecutor:DoFinishCurDisplayTip()
  self:CancelDelayProcess()
  if self.displayingTip then
    self.displayingTip:MarkFinished()
    self.displayingTip = nil
    return true
  end
end

function TipsDisplayExecutor:OnDisplayCoordinatorPausedHandle()
  self:Pause("Coordinator")
end

function TipsDisplayExecutor:OnDisplayCoordinatorResumed()
  self:Resume("Coordinator")
end

function TipsDisplayExecutor:OnDisplayCoordinatorAreaBlock(area, block)
  Log.Debug(self.logTag, "OnDisplayCoordinatorAreaBlock", area, block)
  local reason = "AreaBlock_" .. area
  if block then
    local shouldPause = false
    local displayingTip = self.displayingTip
    if displayingTip and table.contains(displayingTip.tipDisplayAreas, area) then
      shouldPause = true
    else
      self:TraverseCacheData(function(_, _tip)
        if _tip and table.contains(_tip.tipDisplayAreas, area) then
          shouldPause = true
          return true
        end
      end)
    end
    if shouldPause then
      self:Pause(reason)
    end
  else
    self:Resume(reason)
  end
end

return TipsDisplayExecutor

local a = require("Common.Coroutine.async")
local NRCScheduler = {}
NRCScheduler.cb = {}
NRCScheduler.name = "NRCScheduler"
NRCScheduler.enable = false
NRCScheduler.zero_frame = 0

function NRCScheduler.Schedule(f)
  assert(type(f) == "function", "[NRCScheduler] scheduler should be a callback")
  if not NRCScheduler.enable then
    _G.UpdateManager:Register(NRCScheduler)
    NRCScheduler.enable = true
  end
  table.insert(NRCScheduler.cb, f)
end

function NRCScheduler.OnTick(instance, dt)
  if 0 == #instance.cb then
    NRCScheduler.zero_frame = NRCScheduler.zero_frame + 1
  else
    NRCScheduler.zero_frame = 0
  end
  if NRCScheduler.zero_frame > 2 then
    NRCScheduler.Release()
  end
  local cb = instance.cb
  instance.cb = {}
  for _, f in ipairs(cb) do
    f(dt)
  end
end

function NRCScheduler.Release()
  _G.UpdateManager:UnRegister(NRCScheduler)
  NRCScheduler.enable = false
end

local function NextTick()
  return a.wrap(NRCScheduler.Schedule)()
end

local function _delayS(seconds, callback)
  _G.DelayManager:DelaySeconds(seconds, callback, seconds)
end

local function _delayF(frames, callback)
  _G.DelayManager:DelayFrames(frames, callback, frames)
end

local function DelaySeconds(seconds)
  return a.wrap(_delayS)(seconds or 1)
end

local function DelayFrames(frames)
  return a.wrap(_delayF)(frames or 1)
end

local function _LoadResource(path, priority, cacheTime, callback)
  local proxy = {
    failCallback = function(_self, req, err)
      callback(false, req, err)
    end,
    succCallback = function(_self, req, res)
      callback(true, req, res)
    end
  }
  _G.NRCResourceManager:LoadResAsync(proxy, path, priority, cacheTime, proxy.succCallback, proxy.failCallback)
end

local function LoadResource(path, priority, cacheTime)
  return a.wrap(_LoadResource)(path, priority or -1, cacheTime or -1)
end

local function _ResRequestCallback(req, callback)
  if _G.NRCResourceManager.requestMap[req.sessionId] then
    local prevSuccessCallback = req.loadSuccessCallback
    req.loadSuccessCallback = prevSuccessCallback and function(_self, _req, res)
      prevSuccessCallback(_self, _req, res)
      callback(true, _req, res)
    end or function(_self, _req, res)
      callback(true, _req, res)
    end
    local prevFailedCallback = req.loadFailedCallback
    req.loadFailedCallback = prevFailedCallback and function(_self, _req, err)
      prevFailedCallback(_self, _req, err)
      callback(false, _req, err)
    end or function(_self, _req, err)
      callback(false, _req, err)
    end
  else
    callback(false, req, "not loading")
  end
end

local function ResRequestCallback(req)
  return a.wrap(_ResRequestCallback)(req)
end

local function _LoadLevelInstance(worldContext, levelName, location, rotation, bMakeVisibleAfterLoad, timeOutSeconds, callback)
  local ULevelStreamingDynamic = UE4.ULevelStreamingDynamic
  local IsSuccess, LevelStreamingOrNil = ULevelStreamingDynamic.LoadLevelInstance(worldContext, levelName, location, rotation)
  local levelStreaming
  if IsSuccess then
    levelStreaming = LevelStreamingOrNil
  end
  if not UE4.UObject.IsValid(levelStreaming) then
    callback(false, "levelStreaming is nil")
    return
  end
  local isLoaded = false
  local OnLevelLoaded
  
  function OnLevelLoaded(selfLevelStreaming)
    if UE4.UObject.IsValid(selfLevelStreaming) then
      selfLevelStreaming.OnLevelLoaded:Remove(selfLevelStreaming, OnLevelLoaded)
      if bMakeVisibleAfterLoad then
        selfLevelStreaming:SetShouldBeVisible(true)
      end
    end
    isLoaded = true
    callback(true, selfLevelStreaming)
  end
  
  levelStreaming.OnLevelLoaded:Add(levelStreaming, OnLevelLoaded)
  _G.DelayManager:DelaySeconds(timeOutSeconds, function()
    if not isLoaded then
      if UE4.UObject.IsValid(levelStreaming) then
        levelStreaming:SetIsRequestingUnloadAndRemoval(true)
      end
      levelStreaming = nil
      callback(false, "steaming level loading time out")
    end
  end)
end

local function LoadLevelInstance(worldContext, levelName, location, rotation, bMakeVisibleAfterLoad, timeOutSeconds)
  if nil == timeOutSeconds then
    timeOutSeconds = 10
  end
  return a.wrap(_LoadLevelInstance)(worldContext, levelName, location, rotation, bMakeVisibleAfterLoad, timeOutSeconds)
end

local function WaitUntilTimeOut(thunk, timeSeconds)
  local result = {
    a.wait_any({
      thunk,
      DelaySeconds(timeSeconds)
    })
  }
  local index = result[1]
  if 2 == index then
    return false, "time out"
  end
  return true, table.unpack(result, 2)
end

local function WaitUntilCondition(conditionFunction)
  return a.task(function()
    if type(conditionFunction) ~= "function" then
      Log.Error("conditionFunction should be a function")
      return
    end
    while not conditionFunction() do
      a.wait(NextTick())
    end
  end)
end

local function Launch(thunk, callback)
  if type(callback) ~= "function" then
    Log.Warning("callback should be a function")
    
    function callback()
    end
  end
  return thunk(callback)
end

local function LaunchWithTimeout(thunk, timeSeconds, callback)
  if type(callback) ~= "function" then
    Log.Warning("callback should be a function")
    
    function callback()
    end
  end
  local taskFinished = false
  local context = Launch(thunk, function(...)
    if not taskFinished then
      taskFinished = true
      callback(...)
    end
  end)
  _G.DelayManager:DelaySeconds(timeSeconds, function()
    if not taskFinished then
      taskFinished = true
      callback(false, string.format([[
Async task time out.
Async Context Trace: 
%s]], context and a.trace(context) or ""))
    end
  end)
  return context
end

local function CreatePromise()
  local retrieved = false
  local resume_callback, promised_args
  return {
    resolve = function(...)
      if not retrieved then
        retrieved = true
        if select("#", ...) > 0 then
          promised_args = setmetatable({
            ...
          }, {__mode = "v"})
        end
        if resume_callback then
          resume_callback(true, ...)
          resume_callback = nil
        end
      end
    end,
    future = function(callback)
      if retrieved then
        callback(true, promised_args and table.unpack(promised_args) or nil)
        return
      end
      if resume_callback then
        resume_callback(false, nil)
      end
      resume_callback = callback
    end,
    result = function()
      return retrieved, promised_args and table.unpack(promised_args) or nil
    end
  }
end

local function CreatePromiseLite()
  local retrieved = false
  local resume_callback
  return {
    resolve = function(...)
      if not retrieved then
        retrieved = true
        if resume_callback then
          resume_callback(true, ...)
          resume_callback = nil
        end
      end
    end,
    future = function(callback)
      if retrieved then
        callback(false)
        return
      end
      resume_callback = callback
    end
  }
end

local function CreateOpenPanelFuture(PanelName, Timeout)
  Timeout = Timeout or 3
  local Promise = CreatePromise()
  local Finished = false
  local SuccessHandler, FailedHandler, TimeoutID
  
  local function Cleanup()
    if SuccessHandler then
      _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.LoadPanelSucc, SuccessHandler)
      SuccessHandler = nil
    end
    if FailedHandler then
      _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.LoadPanelFail, FailedHandler)
      FailedHandler = nil
    end
    if TimeoutID then
      _G.DelayManager:CancelDelayById(TimeoutID)
      TimeoutID = nil
    end
  end
  
  function SuccessHandler(panelData)
    if Finished then
      return
    end
    if panelData and panelData.panelName == PanelName then
      Finished = true
      Cleanup()
      Promise.resolve({true, panelData})
    end
  end
  
  function FailedHandler(panelData)
    if Finished then
      return
    end
    if panelData and panelData.panelName == PanelName then
      Finished = true
      Cleanup()
      Promise.resolve({
        false,
        "LoadPanelFail"
      })
    end
  end
  
  _G.NRCEventCenter:RegisterEvent("async", self, _G.NRCPanelEvent.LoadPanelSucc, SuccessHandler)
  _G.NRCEventCenter:RegisterEvent("async", self, _G.NRCPanelEvent.LoadPanelFail, FailedHandler)
  TimeoutID = _G.DelayManager:DelaySeconds(Timeout, function()
    if Finished then
      return
    end
    Finished = true
    Cleanup()
    Promise.resolve({false, "Timeout"})
  end)
  return Promise.future
end

local __context_cmd = {__async_command__ = true, __async_get_context__ = true}

local function GetContext()
  local context = a.cmd(__context_cmd)
  return context
end

return {
  Launch = Launch,
  LaunchWithTimeout = LaunchWithTimeout,
  NextTick = NextTick,
  DelaySeconds = DelaySeconds,
  DelayFrames = DelayFrames,
  LoadResource = LoadResource,
  ResRequestCallback = ResRequestCallback,
  LoadLevelInstance = LoadLevelInstance,
  WaitUntilTimeOut = WaitUntilTimeOut,
  WaitUntilCondition = WaitUntilCondition,
  GetContext = GetContext,
  CreatePromise = CreatePromise,
  CreatePromiseLite = CreatePromiseLite,
  CreateOpenPanelFuture = CreateOpenPanelFuture
}

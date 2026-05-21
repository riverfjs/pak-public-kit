local NRCClass = require("Core.NRCClass")
local DefaultWidgetFlushScheduler = require("Common.UI.DefaultWidgetFlushScheduler")
local WidgetStateDebugger = require("Common.UI.WidgetStateDebugger")
local Base = NRCClass
local WidgetStateManager = Base:Extend("WidgetStateManager")
WidgetStateManager.EffectType = {
  SetProps = "WidgetStateManager.EffectType.SetProps",
  SetState = "WidgetStateManager.EffectType.SetState"
}
local defaultMaxDeriveCount = 20

local function ValueEquals(a, b)
  if a == b then
    return true
  end
  if type(a) == "table" and type(b) == "table" then
    for key, valueA in pairs(a) do
      local valueB = b[key]
      if valueB ~= valueA then
        return false
      end
    end
    for key, valueB in pairs(b) do
      local valueA = a[key]
      if valueA ~= valueB then
        return false
      end
    end
    return true
  end
  return false
end

function WidgetStateManager:Ctor()
  Base.Ctor(self)
  self.props = {}
  self.state = {}
  self.effectQueue = {}
  self.isFlushing = false
end

function WidgetStateManager:Init(option)
  self.owner = option and option.owner
  self.UpdateDerivedState = option and option.UpdateDerivedState
  self.DeriveStateFromProps = option and option.DeriveStateFromProps
  self.RenderWidget = option and option.RenderWidget
  self.OnWidgetDidUpdate = option and option.OnWidgetDidUpdate
  self.GetChildWidgets = option and option.GetChildWidgets
  self.scheduler = option and option.scheduler or DefaultWidgetFlushScheduler.GetDefault()
  self.maxDeriveCount = option and option.maxDeriveCount or defaultMaxDeriveCount
  local autoCreateDebugger = option and option.autoCreateDebugger
  self.debugger = option and option.debugger or nil
  if not self.debugger and autoCreateDebugger then
    self.debugger = WidgetStateDebugger()
  end
  local initState = option and option.initState or {}
  self.initState = {}
  table.copy(initState, self.initState)
  local initProps = {}
  initProps.key = WidgetStateManager.InitKey
  self:SetState(initState)
  self:SetProps(initProps)
  if self.scheduler then
    self.scheduler:Flush(self)
  end
end

WidgetStateManager.ValueEquals = ValueEquals
WidgetStateManager.InitKey = "__INITIAL__"

function WidgetStateManager:DeInit()
  if self.scheduler then
    self.scheduler:Cancel(self)
  end
  if self.debugger then
    self.debugger:Dispose()
    self.debugger = nil
  end
  self.owner = nil
  self.UpdateDerivedState = nil
  self.RenderWidget = nil
  self.OnWidgetDidUpdate = nil
  self.scheduler = nil
  self.state = nil
  self.props = nil
  self.effectQueue = nil
end

function WidgetStateManager:GetProps()
  return self.props
end

function WidgetStateManager:SetProps(nextProps)
  local prevProps = self.props
  local prevKey = prevProps and prevProps.key
  local nextKey = nextProps and nextProps.key
  local prevState = self.state
  local currState = self.state
  local nextState = self.state
  if prevKey ~= nextKey then
    currState = {}
    nextState = {}
    table.copy(self.initState, currState)
    table.copy(self.initState, nextState)
    local currentQueue = self.effectQueue or {}
    local firstEffect = currentQueue[1]
    if firstEffect then
      prevProps = firstEffect and firstEffect.prevProps
      prevState = firstEffect and firstEffect.prevState
    end
    self.scheduler:Cancel(self)
    self.effectQueue = {}
  end
  local DeriveStateFromProps = self.DeriveStateFromProps
  if DeriveStateFromProps then
    nextState = DeriveStateFromProps(currState, nextProps)
    local derivedState = self:ComputeDerivedState(prevProps, nextProps, currState, nextState)
    nextState = derivedState
  end
  self.props = nextProps
  self.state = nextState
  if self.debugger then
    self.debugger:RecordSnapshot("SetProps", prevState, nextState, self.owner:GetName(), 3)
  end
  self:ScheduleEffect({
    type = WidgetStateManager.EffectType.SetProps,
    prevProps = prevProps,
    currProps = nextProps,
    prevState = prevState,
    currState = nextState
  })
end

function WidgetStateManager:GetState()
  return self.state
end

function WidgetStateManager:SetState(nextState)
  if self.isRenderingWidget then
    local owner = self.owner
    local name = ""
    if owner and owner.GetName then
      name = owner:GetName()
    end
    Log.WarningFormat("[WidgetStateManager] \230\163\128\230\181\139\229\136\176 %s \230\137\167\232\161\140 RenderWidget \232\191\135\231\168\139\228\184\173\232\176\131\231\148\168\228\186\134 SetState\239\188\140\230\132\143\229\145\179\231\157\128 RenderWidget \228\184\141\230\152\175\231\186\175\229\135\189\230\149\176\239\188\140\232\175\183\230\163\128\230\159\165.", name)
  end
  local prevState = self.state
  local derivedState = self:ComputeDerivedState(self.props, self.props, prevState, nextState)
  self.state = derivedState
  if self.debugger then
    self.debugger:RecordSnapshot("SetState", prevState, derivedState, self.owner:GetName(), 3)
  end
  self:ScheduleEffect({
    type = WidgetStateManager.EffectType.SetState,
    prevProps = self.props,
    currProps = self.props,
    prevState = prevState,
    currState = derivedState
  })
end

function WidgetStateManager:ComputeDerivedState(prevProps, currProps, prevState, nextState)
  local state = nextState
  local derivedState = {}
  local maxDeriveCount = self.maxDeriveCount or defaultMaxDeriveCount
  local currentDeriveCount = 0
  local stateChanged = false
  repeat
    currentDeriveCount = currentDeriveCount + 1
    derivedState = {}
    table.copy(state, derivedState)
    local UpdateDerivedState = self.UpdateDerivedState
    if UpdateDerivedState then
      UpdateDerivedState(prevProps, currProps, prevState, state, derivedState)
    end
    stateChanged = not ValueEquals(state, derivedState)
    if stateChanged then
      prevProps = currProps
      prevState = state
      state = derivedState
    end
  until not stateChanged or maxDeriveCount < currentDeriveCount
  if maxDeriveCount < currentDeriveCount then
    Log.ErrorFormat("WidgetStateManager:SetState \232\182\133\232\191\135\230\156\128\229\164\167\230\180\190\231\148\159\230\172\161\230\149\176 %d", maxDeriveCount)
  end
  return derivedState
end

function WidgetStateManager:ScheduleEffect(effectInfo)
  table.insert(self.effectQueue, effectInfo)
  self.scheduler:Schedule(function()
    self:FlushEffects()
  end, self)
end

function WidgetStateManager:FlushEffects()
  if self.isFlushing then
    return
  end
  self.isFlushing = true
  local currentQueue = self.effectQueue or {}
  self.effectQueue = {}
  if #currentQueue > 0 then
    local firstEffect = currentQueue[1]
    local lastEffect = currentQueue[#currentQueue]
    local mergedEffect = {
      type = firstEffect.type,
      prevProps = firstEffect.prevProps,
      prevState = firstEffect.prevState,
      currProps = lastEffect.currProps,
      currState = lastEffect.currState
    }
    if self.debugger then
      self.debugger:RecordRender(mergedEffect.prevProps, mergedEffect.currProps, mergedEffect.prevState, mergedEffect.currState, self.owner:GetName())
    end
    self.isRenderingWidget = true
    local RenderWidget = self.RenderWidget
    if RenderWidget then
      RenderWidget(self.owner, mergedEffect.prevProps, mergedEffect.currProps, mergedEffect.prevState, mergedEffect.currState)
    end
    self.isRenderingWidget = false
    local childStateManagers = self:GetChildStateManagers()
    for i, childStateManager in ipairs(childStateManagers) do
      local scheduler = childStateManager and childStateManager.scheduler
      if scheduler then
        scheduler:Flush(childStateManager)
      end
    end
    local OnWidgetDidUpdate = self.OnWidgetDidUpdate
    if OnWidgetDidUpdate then
      OnWidgetDidUpdate(self.owner, mergedEffect.prevProps, mergedEffect.currProps, mergedEffect.prevState, mergedEffect.currState)
    end
  end
  self.isFlushing = false
end

function WidgetStateManager:GetCurrAndNextState()
  local prevState = self.state
  local nextState = {}
  table.copy(prevState, nextState)
  return prevState, nextState
end

function WidgetStateManager:GetChildStateManagers()
  local result = {}
  local seen = {}
  local owner = self.owner
  local viewBase = owner
  local childViews = {}
  local GetChildWidgets = self.GetChildWidgets
  if GetChildWidgets then
    local childWidgets = GetChildWidgets(owner)
    childWidgets = childWidgets or {}
    for _, childView in ipairs(childWidgets) do
      table.insert(childViews, childView)
    end
  else
    local viewChildViews = viewBase and viewBase.viewChildViews or {}
    for _, childView in ipairs(viewChildViews) do
      table.insert(childViews, childView)
    end
  end
  for _, childView in ipairs(childViews) do
    local stateManager = childView and childView.stateManager
    if stateManager and not seen[stateManager] then
      table.insert(result, stateManager)
      seen[stateManager] = true
    end
  end
  return result
end

function WidgetStateManager:Watch(fieldPath, callback, options)
  if not self.debugger then
    Log.Error("[WidgetStateManager] Watch is not available because debugger is not initialized")
    return -1
  end
  return self.debugger:Watch(fieldPath, callback, options)
end

function WidgetStateManager:Unwatch(watcherId)
  if self.debugger then
    self.debugger:Unwatch(watcherId)
  end
end

function WidgetStateManager:GetDebugger()
  return self.debugger
end

return WidgetStateManager

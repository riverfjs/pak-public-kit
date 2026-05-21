local TipsDisplayExecutor = require("NewRoco.Modules.System.TipsModule.TipsDisplayExecutor")
local TipUtils = require("NewRoco.Modules.System.TipsModule.Utils.TipUtils")
local TipsViewStatus = {
  Uninitialized = 1,
  Initializing = 2,
  Initialized = 3,
  Deinitializing = 4
}
local TipsDisplayControllerId = 0

local function GetTipsDisplayControllerTag()
  TipsDisplayControllerId = TipsDisplayControllerId + 1
  return "TipsDisplayController" .. TipsDisplayControllerId
end

local TipsDisplayController = NRCClass()

function TipsDisplayController:Ctor(tipType, caller, initTipsView)
  assert(nil ~= tipType, "tipType can not be nil")
  assert(not initTipsView or type(initTipsView) == "function", "initTipsView must be a function")
  self.logTag = GetTipsDisplayControllerTag()
  self.tipType = tipType
  self.executor = TipsDisplayExecutor():Attach(self, self.OnTipDisplayStartHandler, self.OnTipTipTickHandler, self.OnTipDisplayEndHandler, self.OnTipDisplayStatusChange)
  self.executor:SetPauseReasonChangeCallback(self, self.OnExecutorPauseReasonChangeHandler)
  self.pendingTips = {}
  self.initTipsView = initTipsView and _G.MakeWeakFunctor(caller, initTipsView)
  self.tipsViewStatus = TipsViewStatus.Uninitialized
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.RegisterDisplayController, self)
end

function TipsDisplayController:__Dctor()
  self:Free()
end

function TipsDisplayController:Free()
  Log.Debug(self.logTag, "Free")
  for _, _tip in ipairs(self.pendingTips) do
    _tip:MarkFinished()
  end
  self.pendingTips = {}
  self.executor:Free()
  self:CancelDelayInitTipsView()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.UnRegisterDisplayController, self)
end

function TipsDisplayController:BindView(viewInst)
  Log.Debug(self.logTag, "BindView", self.tipsViewStatus)
  if self.tipsViewStatus == TipsViewStatus.Initialized then
    return
  end
  self.tipsViewStatus = TipsViewStatus.Initialized
  if not viewInst then
    Log.Error(self.logTag, "viewInst can not be nil")
    return
  end
  if viewInst.OnPlayTips and type(viewInst.OnPlayTips) == "function" then
    self.onTipDisplayStart = _G.MakeWeakFunctor(viewInst, viewInst.OnPlayTips)
  else
    Log.Error(self.logTag, "\230\156\170\229\174\154\228\185\137OnPlayTips\229\135\189\230\149\176!!")
  end
  if viewInst.OnUpdateTips and "function" == type(viewInst.OnUpdateTips) then
    self.onTipTick = _G.MakeWeakFunctor(viewInst, viewInst.OnUpdateTips)
  end
  if viewInst.OnAllTipsFinished and "function" == type(viewInst.OnAllTipsFinished) then
    self.onTipDisplayEnd = _G.MakeWeakFunctor(viewInst, viewInst.OnAllTipsFinished)
  else
    Log.Error(self.logTag, "\230\156\170\229\174\154\228\185\137OnAllTipsFinished\229\135\189\230\149\176!!")
  end
  if viewInst.OnPlayTipStatusChange and "function" == type(viewInst.OnPlayTipStatusChange) then
    self.onTipDisplayStatusChange = _G.MakeWeakFunctor(viewInst, viewInst.OnPlayTipStatusChange)
  end
  self.executor:Resume("ViewChange")
  for _, tip in ipairs(self.pendingTips) do
    self.executor:AddDisplayTip(tip)
  end
  self.pendingTips = {}
end

function TipsDisplayController:UnBindView()
  Log.Debug(self.logTag, "UnBindView", self.tipsViewStatus)
  if self.tipsViewStatus == TipsViewStatus.Uninitialized then
    return
  end
  self.tipsViewStatus = TipsViewStatus.Uninitialized
  self.onTipDisplayStart = nil
  self.onTipTick = nil
  self.onTipDisplayEnd = nil
  self.onTipDisplayStatusChange = nil
  self.executor:Pause("ViewChange", true)
  if self:HasAnyPendingTip() then
    self:DelayInitTipsView()
  end
end

function TipsDisplayController:GetTipType()
  return self.tipType
end

function TipsDisplayController:GetExecutor()
  return self.executor
end

function TipsDisplayController:AddDisplayTip(tip)
  if not tip or tip.tipType ~= self.tipType then
    return false
  end
  if self.tipsViewStatus == TipsViewStatus.Initializing or self.tipsViewStatus == TipsViewStatus.Deinitializing then
    TipUtils.DebugTipFlow("[wait initialize or uninitialize view...]", tip)
    table.insert(self.pendingTips, tip)
  elseif self.tipsViewStatus == TipsViewStatus.Initialized then
    self.executor:AddDisplayTip(tip)
  elseif self:DoInitTipsView() then
    TipUtils.DebugTipFlow("[call initTipsView, waiting...]", tip)
    table.insert(self.pendingTips, tip)
  else
    tip:MarkFinished()
    Log.Error(self.logTag, "\230\156\170\229\174\154\228\185\137initTipsView\229\135\189\230\149\176!!")
  end
  return true
end

function TipsDisplayController:GetDebugInfo()
  return {
    logTag = self.logTag,
    tipType = self.tipType,
    tipsViewStatus = self.tipsViewStatus,
    pendingTips = self.pendingTips,
    executor = self.executor:GetDebugInfo()
  }
end

function TipsDisplayController:HasAnyPendingTip()
  local hasAnyTip = false
  self.executor:TraverseCacheData(function(_, tip)
    hasAnyTip = true
    return true
  end)
  return hasAnyTip or #self.pendingTips > 0
end

function TipsDisplayController:DelayInitTipsView()
  Log.Debug(self.logTag, "DelayInitTipsView")
  self:CancelDelayInitTipsView()
  self.delayInitTipsViewId = _G.DelayManager:DelaySeconds(1, self.DoDelayInitTipsView, self)
end

function TipsDisplayController:DoDelayInitTipsView()
  Log.Debug(self.logTag, "DoDelayInitTipsView")
  self.delayInitTipsViewId = nil
  self:DoInitTipsView()
end

function TipsDisplayController:CancelDelayInitTipsView()
  if self.delayInitTipsViewId then
    Log.Debug(self.logTag, "CancelDelayInitTipsView")
    _G.DelayManager:CancelDelayById(self.delayInitTipsViewId)
    self.delayInitTipsViewId = nil
    return true
  end
end

function TipsDisplayController:DoInitTipsView()
  Log.Debug(self.logTag, "DoInitTipsView")
  if self.executor:IsPausedExcept("ViewChange") then
    return false
  end
  if self.tipsViewStatus == TipsViewStatus.Uninitialized then
    self.tipsViewStatus = TipsViewStatus.Initializing
    if self.initTipsView then
      self.initTipsView()
    end
    return true
  end
  return false
end

function TipsDisplayController:OnTipDisplayStartHandler(tip)
  if self.onTipDisplayStart then
    self.onTipDisplayStart(tip)
  else
    self.executor:ConsumeNextTip()
  end
end

function TipsDisplayController:OnTipTipTickHandler(tip, interval)
  if self.onTipTick then
    self.onTipTick(tip, interval)
  end
end

function TipsDisplayController:OnTipDisplayEndHandler()
  if not self.initTipsView then
    if self.onTipDisplayEnd then
      return self.onTipDisplayEnd()
    end
    return false
  end
  self.tipsViewStatus = TipsViewStatus.Deinitializing
  if self.onTipDisplayEnd then
    return self.onTipDisplayEnd()
  else
    self:UnBindView()
    return false
  end
end

function TipsDisplayController:OnTipDisplayStatusChange(pause)
  if self.onTipDisplayStatusChange then
    self.onTipDisplayStatusChange(pause)
  end
end

function TipsDisplayController:OnExecutorPauseReasonChangeHandler()
  if self.executor:IsPausedExcept("ViewChange") then
    self:CancelDelayInitTipsView()
  elseif self:HasAnyPendingTip() then
    self:DoInitTipsView()
  end
end

return TipsDisplayController

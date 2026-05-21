local NRCViewBase = NRCUmgClass:Extend("NRCViewBase")
NRCViewBase.ClassType = "NRCViewBase"

function NRCViewBase:Construct()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    self.openSafeCheck = true
  else
    self.openSafeCheck = false
  end
  self.viewName = NRCViewBase.ClassType
  self.isContruct = false
  self.enableLog = true
  self.enableView = true
  self.viewbuttonEventDict = {}
  self.viewDelegateDict = {}
  self.viewEventDict = {}
  self.viewChildViews = {}
  self.delayFunctions = {}
  WeakTable(self.delayFunctions)
  self.resRequestList = nil
  WeakTable(self.resRequestList)
  if not self.LogPrefix then
    self.LogPrefix = string.format("[%s]", self.name)
  end
  if self.OnTick and type(self.OnTick) == "function" then
    self:Log("NRCPanelBase register tick")
    UpdateManager:Register(self)
  end
  self.isContruct = true
  self.isDestruct = false
  self.WidgetTreeRef = self.WidgetTree
end

function NRCViewBase:DoSetChildViewDataAndConstruct(panel)
  local ok, msg = pcall(self.OnConstruct, self)
  if not ok then
    NRCUtils.LuaFatalError(string.format("%s OnConstruct Exception", self.name), "Umg Exception", msg)
  end
  if self.module and self.module.name and #self.viewChildViews > 0 then
    for i = 1, #self.viewChildViews do
      local childview = self.viewChildViews[i]
      if childview and type(childview) == "table" and (childview.ClassType == "NRCViewBase" or childview.ClassType == "NRCPanelBase") then
        childview:SetViewData(self.module, panel)
        childview:DoSetChildViewDataAndConstruct(self)
      else
        self:LogError("NRCViewBase:DoSetChildViewDataAndConstruct childview is nil or not NRCViewBase", i)
      end
    end
  end
end

function NRCViewBase:OnConstruct()
end

function NRCViewBase:UnBindChild(view)
  view:ReleaseForce()
end

function NRCViewBase:UnbindSelf()
  if self.isDestruct == false then
    self:Log("UnBindSelf:", self)
    self:CancelDelay()
    self:RemoveAllButtonListener()
    self:RemoveAllDelegateListener()
    self:UnRegisterAllEvent()
    self:ReleaseResLoadRequest()
    self:ClearAllEnhancedInput()
    self.class = nil
    self.Super = nil
    self:UnbindSelfRef()
    self:Log("ReleaseForce view")
    self.isDestruct = true
    self:UnBindChild(self)
  else
  end
end

function NRCViewBase:Destruct()
  if not self.isDestruct then
    Log.Debug("view Destruct:", self, self.viewName, self.LogPrefix)
    self.isWaitForRecycle = true
    local ok, msg = pcall(self.OnDestruct, self)
    if not ok then
      NRCUtils.LuaFatalError(string.format("%s OnDestruct Exception", self.name), "Umg Exception", msg)
    end
    if self.OnTick and type(self.OnTick) == "function" then
      UpdateManager:UnRegister(self)
    end
    self:UnbindSelf()
    self.module = nil
    self.data = nil
  else
    Log.Debug("is Destructing class")
  end
end

function NRCViewBase:OnDestruct()
end

function NRCViewBase:SafeCheck()
  if not self.openSafeCheck then
    return
  end
  if not table.isNil(self.viewEventDict) then
    self:LogWarning("SafeCheck \228\184\141\233\128\154\232\191\135,\230\178\161\230\156\137\231\167\187\233\153\164\230\137\128\230\156\137\228\186\139\228\187\182:", self.viewEventDict)
  end
  if not table.isNil(self.viewDelegateDict) then
    self:LogWarning("SafeCheck \228\184\141\233\128\154\232\191\135,\230\178\161\230\156\137\231\167\187\233\153\164\230\137\128\230\156\137Delegate:", self.viewDelegateDict)
  end
  if not table.isNil(self.viewbuttonEventDict) then
    self:LogWarning("SafeCheck \228\184\141\233\128\154\232\191\135,\230\178\161\230\156\137\231\167\187\233\153\164\230\137\128\230\156\137Button:", self.viewbuttonEventDict)
  end
end

function NRCViewBase:Enable(...)
  if self.enableView ~= true then
    self:Log("NRCViewBase Enable")
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetAllInputMappingContextActive(true)
    self.enableView = true
    if self.OnEnable then
      self:OnEnable(...)
    end
  end
end

function NRCViewBase:DisableAndShouldRecoverWorldRendering(...)
  UE4Helper.SetEnableWorldRendering(true)
  self:Disable(...)
end

function NRCViewBase:EnableAndShouldBanWorldRendering(...)
  self:Enable(...)
  _G.DelayManager:DelayFrames(2, function()
    UE4Helper.SetEnableWorldRendering(false, true)
  end)
end

function NRCViewBase:Disable(...)
  if self.enableView ~= false then
    self:Log("NRCViewBase Disable")
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetAllInputMappingContextActive(false)
    self.enableView = false
    if self.OnDisable then
      self:OnDisable(...)
    end
  end
end

function NRCViewBase:OnEnable()
end

function NRCViewBase:OnDisable()
end

function NRCViewBase:SetChildViews(...)
  self.viewChildViews = table.pack(...)
end

function NRCViewBase:DynamicAddChildView(childView)
  if not childView or not childView.SetViewData then
    return
  end
  childView:SetViewData(self.module, self)
  table.insert(self.viewChildViews, childView)
end

function NRCViewBase:SetViewData(module, panel)
  self:Log("SetViewData:", module.moduleName, panel.viewName)
  self.module = module
  self.panel = panel
  self:SetEventDispatcher(module.eventDispatcher)
end

function NRCViewBase:SetEventDispatcher(dispatcher)
  if not dispatcher then
    self.eventDispatcher = NRCClass()
    EventDispatcher():Attach(self.eventDispatcher)
  else
    self.eventDispatcher = dispatcher
  end
end

function NRCViewBase:AddButtonListener(btn, handler)
  if not btn then
    self:LogError("btn\228\184\141\229\173\152\229\156\168\239\188\140\230\179\168\229\134\140\230\140\137\233\146\174\229\164\177\232\180\165")
    return
  end
  if self.viewbuttonEventDict and not self.viewbuttonEventDict[btn] then
    btn.OnClicked:Add(self, handler)
    self.viewbuttonEventDict[btn] = handler
  elseif _G.RocoEnv.IS_EDITOR and self.viewbuttonEventDict then
    self:LogError("\232\175\183\229\139\191\233\135\141\229\164\141\230\179\168\229\134\140Button\228\186\139\228\187\182:", self.viewbuttonEventDict[btn])
  end
end

function NRCViewBase:RemoveButtonListener(btn)
  if not btn then
    self:LogError("btn\228\184\141\229\173\152\229\156\168\239\188\140\231\167\187\233\153\164\230\140\137\233\146\174\229\164\177\232\180\165")
    return
  end
  if self.viewbuttonEventDict and self.viewbuttonEventDict[btn] then
    btn.OnClicked:Remove(self, self.viewbuttonEventDict[btn])
    self.viewbuttonEventDict[btn] = nil
  else
  end
end

function NRCViewBase:RemoveAllButtonListener()
  if not self.viewbuttonEventDict then
    self:LogError("\232\175\183\229\139\191\232\166\134\231\155\150\231\136\182\231\177\187Construct")
    return
  end
  for btn, handlerWrap in pairs(self.viewbuttonEventDict) do
    self:RemoveButtonListener(btn)
  end
end

function NRCViewBase:PauseButtonListener(btn)
end

function NRCViewBase:PauseAllButtonListener()
end

function NRCViewBase:RecoverAllButtonListener()
end

function NRCViewBase:AddDelegateListener(delegateProperty, listener)
  if not self.isContruct then
    Log.Error("\232\175\183\229\156\168OnActive\228\184\173\230\179\168\229\134\140delegateProperty")
    return
  end
  if not delegateProperty then
    Log.Error("delegateProperty is nil")
    return
  end
  if not self.viewDelegateDict[delegateProperty] then
    delegateProperty:Add(self, listener)
    self.viewDelegateDict[delegateProperty] = listener
  else
    self:LogError("\232\175\183\229\139\191\233\135\141\229\164\141\230\179\168\229\134\140Delegate")
  end
end

function NRCViewBase:RemoveDelegateListener(delegateProperty)
  if not delegateProperty then
    Log.Error("delegateProperty is nil")
    return
  end
  if self.viewDelegateDict[delegateProperty] then
    delegateProperty:Remove(self, self.viewDelegateDict[delegateProperty])
    self.viewDelegateDict[delegateProperty] = nil
  else
  end
end

function NRCViewBase:RemoveAllDelegateListener()
  if self.viewDelegateDict then
    for delegateProperty, handlerWarp in pairs(self.viewDelegateDict) do
      self:RemoveDelegateListener(delegateProperty)
    end
  end
end

function NRCViewBase:RegisterEvent(caller, eventName, handler)
  if not self.eventDispatcher then
    self:LogError("\229\173\144View\229\191\133\233\161\187\232\166\129\229\156\168\231\136\182\232\138\130\231\130\185OnConstruct\229\135\189\230\149\176\228\184\173\232\176\131\231\148\168SetChildViews\230\179\168\229\134\140\230\137\141\232\131\189\228\189\191\231\148\168\228\186\139\228\187\182\228\190\166\229\144\172\227\128\130")
    return
  end
  if not self.viewEventDict[caller] then
    self.viewEventDict[caller] = {}
  end
  if not self.viewEventDict[caller][eventName] then
    self.viewEventDict[caller][eventName] = {c = caller, h = handler}
    self:Log("RegisterEvent:", eventName)
    self.eventDispatcher:AddEventListener(caller, eventName, handler)
  end
end

function NRCViewBase:UnRegisterEvent(caller, eventName)
  if not self then
    Log.Error("NRCViewBase:UnRegisterEvent Self is not valid")
    return
  end
  if not self.viewEventDict or not self.viewEventDict[caller] then
    self:LogError("UnRegisterEvent caller is not registered")
    return
  end
  if self.viewEventDict[caller][eventName] then
    self:Log("UnRegisterEvent:", eventName)
    local caller = self.viewEventDict[caller][eventName].c
    local handler = self.viewEventDict[caller][eventName].h
    self.eventDispatcher:RemoveEventListener(caller, eventName, handler)
    self.viewEventDict[caller][eventName] = nil
  end
end

function NRCViewBase:UnRegisterAllEvent()
  if self.viewEventDict then
    for caller, v in pairs(self.viewEventDict) do
      for eventName, t in pairs(v) do
        self:UnRegisterEvent(caller, eventName)
      end
    end
  end
end

function NRCViewBase:DispatchEvent(eventName, ...)
  if not self.eventDispatcher then
    self:Log("dispatch event before Construct, may be call from parent ui, this=", self.GetName and self:GetName() or self, "event=", eventName)
    return
  end
  self.eventDispatcher:SendEvent(eventName, ...)
end

function NRCViewBase:__AddDelayFunction(func, delayId)
  if not func then
    return
  end
  local delayFunctions = self.delayFunctions
  if not delayFunctions then
    delayFunctions = _G.WeakTable()
    self.delayFunctions = delayFunctions
  end
  local existDelayId = delayFunctions[func]
  if nil ~= existDelayId then
    _G.DelayManager:CancelDelayById(existDelayId)
  end
  delayFunctions[func] = delayId
end

function NRCViewBase:__RemoveDelayFunction(func, delayId)
  local delayFunctions = self.delayFunctions
  if not delayFunctions then
    return
  end
  local _key = func
  if delayId then
    for _func, _id in pairs(delayFunctions) do
      if _id == delayId then
        _key = _func
        break
      end
    end
  end
  if _key then
    delayFunctions[_key] = nil
  end
end

function NRCViewBase:DelaySeconds(seconds, func, ...)
  if self.isDestruct then
    return
  end
  local delayId = _G.DelayManager:DelaySeconds(seconds, func, ...)
  self:__AddDelayFunction(func, delayId)
  return delayId
end

function NRCViewBase:DelayFrames(frames, func, ...)
  if self.isDestruct then
    return
  end
  local delayId = _G.DelayManager:DelayFrames(frames, func, ...)
  self:__AddDelayFunction(func, delayId)
  return delayId
end

function NRCViewBase:CancelDelayByID(id)
  _G.DelayManager:CancelDelayByIdEx(id)
  self:__RemoveDelayFunction(nil, id)
end

function NRCViewBase:CancelDelayByFunc(func)
  _G.DelayManager:CancelDelay(func)
  self:__RemoveDelayFunction(func, nil)
end

function NRCViewBase:CancelDelay()
  local delayFunctions = self.delayFunctions
  if delayFunctions then
    for func, _ in pairs(delayFunctions) do
      _G.DelayManager:CancelDelay(func)
    end
    self.delayFunctions = nil
  end
end

function NRCViewBase:LoadPanelRes(resPath, priority, succCallback, failedCallback, progressCallback)
  local resRequest = NRCResourceManager:LoadResAsync(self, resPath, priority, 0, succCallback, failedCallback, progressCallback)
  if self.resRequestList == nil then
    self.resRequestList = {}
  end
  table.insert(self.resRequestList, resRequest)
  return resRequest
end

function NRCViewBase:ReleaseResLoadRequest()
  local ReqList = self.resRequestList
  if ReqList and #ReqList > 0 then
    for i = #ReqList, 1, -1 do
      if ReqList[i] then
        NRCResourceManager:UnLoadRes(ReqList[i])
      end
      table.remove(ReqList, i)
    end
  end
  self.resRequestList = nil
end

function NRCViewBase:UnLoadRes(resRequest)
  NRCResourceManager:UnLoadRes(resRequest)
end

function NRCViewBase:IsLoadingRes(resRequest)
  return NRCResourceManager:IsLoadingRes(resRequest)
end

function NRCViewBase:IsLoadedRes(resRequest)
  return NRCResourceManager:IsLoadedRes(resRequest)
end

function NRCViewBase:TryGetLoadedRes(resRequest)
  return NRCResourceManager:TryGetLoadedRes(resRequest)
end

function NRCViewBase:UnLoadResByPath(resPath)
  local ReqList = self.resRequestList
  if ReqList and #ReqList > 0 then
    for i = 1, #ReqList do
      local resRequest = ReqList[i]
      if resRequest.assetPath == resPath then
        self:UnLoadRes(resRequest)
        return
      end
    end
  end
end

function NRCViewBase:IsLoadingResByPath(resPath)
  local ReqList = self.resRequestList
  if ReqList and #ReqList > 0 then
    for i = 1, #ReqList do
      local resRequest = ReqList[i]
      if resRequest.assetPath == resPath then
        return self:IsLoadingRes(resRequest)
      end
    end
  end
end

function NRCViewBase:IsLoadedResByPath(resPath)
  local ReqList = self.resRequestList
  if ReqList and #ReqList > 0 then
    for i = 1, #ReqList do
      local resRequest = ReqList[i]
      if resRequest.assetPath == resPath then
        return self:IsLoadedRes(resRequest)
      end
    end
  end
end

function NRCViewBase:TryGetLoadedResByPath(resPath)
  local ReqList = self.resRequestList
  if ReqList and #ReqList > 0 then
    for i = 1, #ReqList do
      local resRequest = ReqList[i]
      if resRequest.assetPath == resPath then
        return self:TryGetLoadedRes(resRequest)
      end
    end
  end
end

function NRCViewBase:GetPanelName()
  return self.panel.panelData.panelName
end

function NRCViewBase:GetPanelName()
  return self.panel.panelData.panelName
end

function NRCViewBase:PlayPressedOrReleasedAnimation(isPressed, pressedAnim, releasedAnim)
  self:StopAnimation(pressedAnim)
  self:StopAnimation(releasedAnim)
  if isPressed then
    self:PlayAnimation(pressedAnim)
  else
    self:PlayAnimation(releasedAnim)
  end
end

function NRCViewBase:AddInputMappingContext(_contextName, _priority)
  local mappingContextCached = self.mappingContextCached
  if not mappingContextCached then
    mappingContextCached = {}
    self.mappingContextCached = mappingContextCached
  end
  _priority = _priority or self.depth
  local mappingContext = mappingContextCached[_contextName]
  if not mappingContext then
    mappingContext = _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddInputMappingContext, _contextName, nil, _priority)
    if mappingContext then
      mappingContextCached[_contextName] = mappingContext
    end
  end
  if mappingContext then
    mappingContext:SetMappingContextActive(true)
  end
  return mappingContext
end

function NRCViewBase:GetInputMappingContext(_contextName)
  local mappingContextCached = self.mappingContextCached
  local mappingContext = mappingContextCached and mappingContextCached[_contextName]
  if mappingContext then
    return mappingContext
  end
  return _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.GetInputMappingContext, _contextName)
end

function NRCViewBase:RemoveInputMappingContext(_contextName)
  local mappingContextCached = self.mappingContextCached
  local mappingContext = mappingContextCached and mappingContextCached[_contextName]
  if mappingContext then
    _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveInputMappingContext, _contextName)
    mappingContextCached[_contextName] = nil
  end
end

function NRCViewBase:ClearAllEnhancedInput()
  local mappingContextCached = self.mappingContextCached
  if not mappingContextCached then
    return
  end
  self.mappingContextCached = {}
  for _contextName, _ in pairs(mappingContextCached) do
    _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveInputMappingContext, _contextName)
  end
end

function NRCViewBase:SetAllInputMappingContextActive(_active)
  local mappingContextCached = self.mappingContextCached
  if not mappingContextCached then
    return
  end
  for _, mappingContext in pairs(mappingContextCached) do
    mappingContext:SetMappingContextActive(_active)
  end
end

function NRCViewBase:SetAllInputMappingContextPriority(_priority)
  local mappingContextCached = self.mappingContextCached
  if not mappingContextCached then
    return
  end
  for _, mappingContext in pairs(mappingContextCached) do
    mappingContext:SetMappingContextPriority(_priority)
  end
end

function NRCViewBase:Log(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogDebug, 4, self.LogPrefix, ...)
  end
end

function NRCViewBase:LogWarning(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogWarn, 3, self.LogPrefix, ...)
  end
end

function NRCViewBase:LogTrace(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogTrace, 3, self.LogPrefix, ...)
  end
end

function NRCViewBase:LogError(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogError, 3, self.LogPrefix, ...)
  end
end

return NRCViewBase

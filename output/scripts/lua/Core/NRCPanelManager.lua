local NRCPanelManager = _G.Singleton:Extend("NRCPanelManager")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local PriorityEnum = require("PriorityEnum")
NRCPanelManager.CacheType = {NoCache = 1, CacheType1 = 2}
NRCPanelManager.ActivePreCondition = {
  PreLoadRes = 1,
  LoadingLoadRes = 2,
  OpenRsp = 4
}
_G.NRCPanelEvent = {}
NRCPanelEvent.OpenPanel = "NRCPanelEvent.OpenPanel"
NRCPanelEvent.LoadPanel = "NRCPanelEvent.LoadPanel"
NRCPanelEvent.LoadPanelSucc = "NRCPanelEvent.LoadPanelSucc"
NRCPanelEvent.LoadPanelFail = "NRCPanelEvent.LoadPanelFail"
NRCPanelEvent.ClosePanel = "NRCPanelEvent.ClosePanel"
NRCPanelEvent.OpenPanelFailed = "NRCPanelEvent.OpenPanelFailed"
NRCPanelEvent.OpenPanelFinish = "NRCPanelEvent.OpenPanelFinish"

local function GetResPriority(resPriority, panelPriority)
  if panelPriority and panelPriority < resPriority then
    return panelPriority
  end
  return resPriority
end

function NRCPanelManager:Ctor()
  _G.Singleton.Ctor(self, self.name)
  Log.Debug("[NRCPanelManager] ctor")
  self.debugData = {}
  self.panelDataDict = {}
  self.panelArgsDict = {}
  self.panelArgsDynamicAdd = {}
  self.panelDict = {}
  self.panelLoaderDict = {}
  self.isLoadingPanelDict = {}
  self.waitForActivePanelLst = {}
  self.layerCenter = UILayerCtrlCenter()
  self.startTime = 0
  self.endTime = 0
  self.UmgAssetDict = {}
  self.cacheMode = NRCPanelManager.CacheType.NoCache
  self.CacheAssetDict = {}
  self.resCacheTime = 0
  self.waitForAddToViewport = {}
  self.waitForActivePanel = {}
  self.ActiveConditionState = {}
  self.waitForClosePanel = {}
  self.PanelStack = {}
  self.panelTriggers = {}
  self.UmgStaticConfigDic = {}
  self:EnableTick(true)
  self:InstantiateGlobalPanelExitTrigger()
end

function NRCPanelManager:InitAllUmgStaticConfig()
  local AllConfig = _G.DataConfigManager:GetAllByName("UMG_STATIC_CONF")
  if nil == AllConfig then
    Log.Error("[NRCPanelManager] InitAllUmgStaticConfig, AllConfig is nil")
    return
  end
  for k, v in pairs(AllConfig) do
    self.UmgStaticConfigDic[v.panel_name] = v
  end
end

function NRCPanelManager:Free()
  _G.Singleton.Free(self)
end

function NRCPanelManager:CloseCapture()
end

function NRCPanelManager:SafeCallPanelFunction(panelName, func, caller, ...)
  if not func then
    return
  end
  local ok, msg
  if _G.RocoEnv.IS_SHIPPING then
    ok, msg = pcall(func, caller, ...)
  else
    ok, msg = xpcall(func, debug.traceback, caller, ...)
  end
  if not ok then
    NRCUtils.LuaFatalError(string.format("%s Exception", panelName), "Umg Exception", msg)
  end
end

function NRCPanelManager:GetLayerWindowCount(panelLayer)
  local Count = self.layerCenter:GetLayerWindowCount(panelLayer)
  Log.Debug("[NRCPanelManager] GetLayerWindowCount:" .. Count)
  return Count
end

function NRCPanelManager:GetAllLayerWindowCount()
  local Count = self.layerCenter:GetAllLayerWindowCount()
  Log.Debug("[NRCPanelManager] GetAllLayerWindowCount:" .. Count)
  return Count
end

function NRCPanelManager:GetEnabledWindowCount(panelLayer)
  local Ctrl = self.layerCenter:GetLayerCtrl(panelLayer)
  local Panels = Ctrl:GetAllWindow()
  local Count = 0
  if Panels and #Panels > 0 then
    for k, v in ipairs(Panels) do
      if v.enableView then
        Count = Count + 1
      end
    end
  end
  return Count
end

function NRCPanelManager:CheckNeedCloseFirst(panelData)
  if panelData and panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    local fullScreenCtrl = self.layerCenter:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    if fullScreenCtrl then
      return fullScreenCtrl:CheckWindowBeOverlay(panelData.panelName)
    end
  end
  return false
end

function NRCPanelManager:CheckFullScreenPanelIsShowTop(panelName)
  if self.layerCenter then
    local fullScreenCtrl = self.layerCenter:GetLayerCtrl(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    if fullScreenCtrl then
      return not fullScreenCtrl:CheckWindowBeOverlay(panelName)
    end
  end
end

function NRCPanelManager:OpenPanelTest(module, panelData, panelArg, isOpenNew)
  self:LoadPanel(module, panelData, panelArg)
end

function NRCPanelManager:GetLayerCtrl(panelLayer)
  return self.layerCenter:GetLayerCtrl(panelLayer)
end

function NRCPanelManager:PreloadPanel(panelPath, priorityEnum)
  local resRequest = NRCResourceManager:LoadResAsync(self, panelPath, priorityEnum or PriorityEnum.UI_PreLoadPanel_Default, self.resCacheTime, function(caller, resRequest, asset)
    Log.Debug("NRCPanelManager PreloadPanel:", panelPath)
  end, function(caller, resRequest, errMsg)
  end, function(caller, resRequest, progress)
  end, function(resRequest)
    Log.Debug("[NRCPanelManager] LoadPanel unLoad:", resRequest.assetPath)
  end)
end

function NRCPanelManager:OpenPanel(module, panelData, panelArg)
  if self:IsLoadingPanel(module.moduleName, panelData.panelName) then
    Log.Debug("[NRCPanelManager] OpenPanel return false:" .. panelData.panelName)
    return false
  end
  _G.NRCSDKManager:ReportExtraCrashData(UE4.ECrashDataReporterType.UIOperate, "OpenPanel " .. panelData.panelName)
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.OpenPanel)
  _G.NRCPanelBlocker:StartBlockWithRegisted(panelData.panelName)
  Log.Debug("NRCPanelManager StartBlockGC")
  _G.BlockGC = true
  Log.Debug("[NRCPanelManager] OpenPanel:" .. panelData.panelName)
  local debugData = {}
  debugData.path = panelData.panelPath
  self.debugData[panelData.panelPath] = debugData
  if not self.panelDataDict[module.moduleName] then
    self.panelDataDict[module.moduleName] = {}
  end
  self.panelDataDict[module.moduleName][panelData.panelName] = panelData
  if not self.panelArgsDict[module.moduleName] then
    self.panelArgsDict[module.moduleName] = {}
  end
  self.panelArgsDict[module.moduleName][panelData.panelName] = panelArg
  if self.panelArgsDynamicAdd[module.moduleName] then
    self.panelArgsDynamicAdd[module.moduleName][panelData.panelName] = nil
  end
  panelData.openReqParam = nil
  panelData.panelDynamicData = nil
  panelData.NeedRes = nil
  if panelArg and #panelArg > 0 then
    for k, v in pairs(panelArg) do
      if type(v) == "table" then
        if v.className == "NRCPanelOpenReqData" then
          panelData.openReqParam = v
        elseif v.className == "NRCPanelResLoadData" then
          panelData.NeedRes = v
        elseif v.className == "NRCPanelDynamicData" then
          panelData.panelDynamicData = v
        end
      end
    end
  end
  if panelData.panelDynamicData and panelData.panelDynamicData:GetModifiedPanelLayerType() then
    local oldPanelLayer = panelData.panelLayer
    panelData.panelLayer = panelData.panelDynamicData:GetModifiedPanelLayerType()
    Log.DebugFormat("[NRCPanelManager] OpenPanel dynamic modify panel(%s) layer from %s to %s", panelData.panelName, tostring(oldPanelLayer), tostring(panelData.panelLayer))
  elseif panelData.backupRegisterPanelLayer and panelData.panelLayer ~= panelData.backupRegisterPanelLayer then
    Log.DebugFormat("[NRCPanelManager] OpenPanel restore panel(%s) layer from %s to %s", panelData.panelName, tostring(panelData.panelLayer), tostring(panelData.backupRegisterPanelLayer))
    panelData.panelLayer = panelData.backupRegisterPanelLayer
  end
  if panelData.necessaryResList and #panelData.necessaryResList > 0 then
    panelData.NeedRes = panelData.NeedRes or {}
    if panelData.NeedRes.PreLoadResList then
      for _, v in ipairs(panelData.necessaryResList) do
        table.insert(panelData.NeedRes.PreLoadResList, v)
      end
    else
      panelData.NeedRes.PreLoadResList = panelData.necessaryResList
    end
  end
  self:AddToUIStack(module.moduleName, panelData.panelName)
  NRCEventCenter:DispatchEvent(NRCPanelEvent.OpenPanel, panelData)
  if self.layerCenter:CheckCanOpen(panelData) then
    local layerCtrl = self.layerCenter:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:SetPanelReadyToOpen(panelData.panelName, module, panelData)
    end
    if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
      _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.FullSpeed, panelData.panelName)
    end
    NRCModuleManager:DoCmd(MultiTouchModuleCmd.AddSingleTouchPanel, panelData)
    local success = false
    if self:HasPanelAsset(panelData.panelName) then
      self:InitPanelWithCache(module, panelData, panelArg)
      success = true
    else
      _G.NRCProfilerLog:NRCPanelProfilerLog(true, true, panelData.panelName)
      success = self:LoadPanel(module, panelData, panelArg)
    end
    if success and panelData.panelDynamicData then
      panelData.panelDynamicData:TriggerOpen(panelData)
    end
    return success
  else
    Log.Warning("[NRCPanelManager] OpenPanel layerCenter:CheckCanOpen false")
  end
end

function NRCPanelManager:InitPanelWithCache(module, panelData, panelArg)
  local asset = self:GetPanelAsset(panelData.panelName)
  self:AddToWaitingList(asset, module, panelData, panelArg)
end

function NRCPanelManager:LoadPanel(module, panelData, panelArg)
  if not panelData:IsPreCache() and not panelData.disableLoadBlock then
    local BlockTrigger = self:AddPanelBlockIMC(panelData)
    panelData.BlockTrigger = BlockTrigger
  else
  end
  if panelData.enableTouchMask then
    NRCModuleManager:DoCmd(MultiTouchModuleCmd.OpenBlockingMask)
  end
  local path = panelData.panelPath
  if not self.panelLoaderDict[module.moduleName] then
    self.panelLoaderDict[module.moduleName] = {}
  end
  if not self.panelLoaderDict[module.moduleName][panelData.panelPath] then
    self.panelLoaderDict[module.moduleName][panelData.panelPath] = {}
  end
  self:AddLoadingPanel(module.moduleName, panelData)
  if panelData.openReqParam ~= nil and nil ~= panelData.openReqParam.reqClass then
    if not module:SendOpenReq(module, panelData, panelData.openReqParam) then
      Log.Error("NRCPanelManager:LoadPanel SendOpenReq failed!", panelData.panelName)
      self:ClosePanel(module.moduleName, panelData.panelName)
      return false
    end
  else
    self:SetActiveConditionState(NRCPanelManager.ActivePreCondition.OpenRsp, panelData, module)
  end
  _G.NRCProfilerLog:NRCPanelLoad(true, panelData.panelName)
  local resRequest = NRCResourceManager:LoadResAsync(self, path, panelData.loadPriority, self.resCacheTime, function(caller, resRequest, asset)
    if not module then
      Log.Error("NRCPanelManager:LoadPanel module lost")
      return
    end
    if panelData.NeedRes then
      local syncResPriority = GetResPriority(panelData.NeedRes.SyncResPriority or PriorityEnum.UI_OpenPanel_SyncRes, panelData.loadPriority)
      if panelData.NeedRes.PreLoadResList and #panelData.NeedRes.PreLoadResList > 0 then
        module:PreLoadPanelRes(panelData.NeedRes.PreLoadResList, panelData, module, NRCPanelManager.ActivePreCondition.PreLoadRes, syncResPriority)
      else
        self:SetActiveConditionState(NRCPanelManager.ActivePreCondition.PreLoadRes, panelData, module)
      end
      if panelData.NeedRes.LoadingResList and #panelData.NeedRes.LoadingResList > 0 then
        module:PreLoadPanelRes(panelData.NeedRes.LoadingResList, panelData, module, NRCPanelManager.ActivePreCondition.LoadingLoadRes, syncResPriority)
      else
        self:SetActiveConditionState(NRCPanelManager.ActivePreCondition.LoadingLoadRes, panelData, module)
      end
      if panelData.NeedRes.PreparingResList and #panelData.NeedRes.PreparingResList > 0 then
        local asyncResPriority = GetResPriority(panelData.NeedRes.AsyncResPriority or PriorityEnum.UI_OpenPanel_ASyncRes, panelData.loadPriority)
        module:PreLoadPanelRes(panelData.NeedRes.PreparingResList, panelData, module, nil, asyncResPriority)
      end
    else
      self:SetActiveConditionState(NRCPanelManager.ActivePreCondition.PreLoadRes, panelData, module)
      self:SetActiveConditionState(NRCPanelManager.ActivePreCondition.LoadingLoadRes, panelData, module)
    end
    Log.Debug("[NRCPanelManager] OpenPanel LoadPanel succ:", panelData.panelName, resRequest.assetPath, asset, umgPanel, getmetatable(asset), getmetatable(umgPanel), asset)
    _G.NRCProfilerLog:NRCPanelLoad(false, panelData.panelName)
    UE4.UNRCStatics.GetPackageDependenciesLoadTime(asset, _G.GlobalConfig.bShowProfilerLog)
    if _G.ForceRefUClass then
      table.insert(self.UmgAssetDict, asset)
    end
    if self:IsUsingCacheMode() then
      self.CacheAssetDict[panelData.panelName] = asset
    end
    self:AddToWaitingList(asset, module, panelData, panelArg)
  end, function(caller, resRequest, errMsg)
    Log.Error("[NRCPanelManager] LoadPanel fail:", resRequest.assetPath)
    module:OnOpenPanelCallback(panelData.panelName, 1, false)
    self:ClosePanel(module.moduleName, panelData.panelName)
    NRCEventCenter:DispatchEvent(NRCPanelEvent.LoadPanelFail, panelData)
  end, function(caller, resRequest, progress)
  end, function(resRequest)
    module:OnOpenPanelCallback(panelData.panelName, 1, false)
    Log.Debug("[NRCPanelManager] LoadPanel unLoad:", resRequest.assetPath)
  end)
  table.insert(self.panelLoaderDict[module.moduleName][panelData.panelPath], resRequest)
  NRCEventCenter:DispatchEvent(NRCPanelEvent.LoadPanel, panelData)
  return true
end

function NRCPanelManager:AddToWaitingList(asset, module, panelData, panelArg)
  if not self.world then
    Log.Debug("NRCPanelManager LoadPanel InitWorld")
  end
  Log.Debug("NRCPanelManager LoadPanel InitWorld self.world:", self.world)
  local world = UE4.UNRCPlatformGameInstance.GetInstance()
  local UEDeltaTime2 = UE4.UGameplayStatics.GetUnpausedTimeSeconds(UE4Helper.GetCurrentWorld())
  local UEDeltaTime3 = UE4.UGameplayStatics.GetTimeSeconds(UE4Helper.GetCurrentWorld())
  Log.Debug("GetUnpausedTimeSeconds:", UEDeltaTime2, UEDeltaTime3)
  _G.NRCProfilerLog:NRCPanelCreate(true, panelData.panelName)
  local umgPanel = UE4.UWidgetBlueprintLibrary.Create(world, asset)
  if not umgPanel.SetPanelData then
    NRCUtils.LuaFatalError("NRCPanelManager AddToWaitingList failed!", "Umg Exception", string.format("umgPanel %s is not inherit NRCPanelBase", tostring(asset)))
    return
  end
  if panelData.panelType == _G.NRCPanelEnum.PanelTypeEnum.PANEL_3DUI1 or panelData.panelType == _G.NRCPanelEnum.PanelTypeEnum.PANEL_3DUI2 then
  end
  self:AddPanel(module.moduleName, panelData.panelName, umgPanel)
  umgPanel:SetPanelData(module, panelData)
  _G.NRCProfilerLog:NRCPanelCreate(false, panelData.panelName)
  local waitForAddPanelInfo = {
    umgPanel = umgPanel,
    module = module,
    moduleName = module.moduleName,
    panelData = panelData,
    OpenReqParam = panelData.openReqParam,
    cTime = os.msTime()
  }
  table.insert(self.waitForAddToViewport, waitForAddPanelInfo)
end

function NRCPanelManager:InstantiatePanel(module, umgPanel, panelData)
  local tempPanelArg
  if self.panelArgsDict[module.moduleName] then
    tempPanelArg = self.panelArgsDict[module.moduleName][panelData.panelName]
  end
  self:DoInstantiatePanel(module, umgPanel, panelData, tempPanelArg)
  tempPanelArg = nil
  module:OnOpenPanelCallback(panelData.panelName, 1, true)
  self:RemoveLoadingPanel(module.moduleName, panelData)
  if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN and not _G.BattleManager.isInBattle then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    NRCModuleManager:DoCmd(MultiTouchModuleCmd.DisableMultiTouch, panelData.touchCount)
  end
  if 0 == self:GetLoadingPanelCount() then
    _G.BlockGC = false
    Log.Debug("NRCPanelManager StopBlockGC")
  end
  NRCEventCenter:DispatchEvent(NRCPanelEvent.LoadPanelSucc, panelData)
end

function NRCPanelManager:DoInstantiatePanel(module, umgPanel, panelData, panelArg)
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.OpenPanelComplete)
  Log.Debug("[NRCPanelManager] DoInstantiatePanel:", type(umgPanel), panelData.panelName)
  if not panelData:IsPreCache() then
    if nil ~= panelArg then
      Log.Debug("[NRCPanelManager] panel active:", panelData.panelPath)
      if not UE4.UObject.IsValid(umgPanel) or not umgPanel.Active then
        Log.Error("\233\157\162\230\157\191\229\138\160\232\189\189\229\188\130\229\184\184:", panelData.panelPath)
        return
      end
      if module:IsPanelEnabled(panelData.panelName) then
        self:SafeCallPanelFunction(panelData.panelName, umgPanel.Enable, umgPanel)
      else
        Log.Debug("IsPanelEnabled = false", panelData.panelName)
      end
      NRCEventCenter:DispatchEvent(NRCPanelEvent.OpenPanelFinish, panelData)
      local panelConfig = self.UmgStaticConfigDic[panelData.panelName]
      if panelConfig then
        panelData.panelStaticConf = panelConfig
      end
      self:SafeCallPanelFunction(panelData.panelName, umgPanel.Active, umgPanel, table.unpack(panelArg, 1, math.max(panelArg.n, #panelArg)))
      self:OnPostActivePanel(umgPanel)
      self:CloseCapture()
    end
  else
    Log.Debug("NRCPanelManager DisablePanel")
    self:SafeCallPanelFunction(panelData.panelName, umgPanel.Disable, umgPanel)
  end
  Log.Debug("[NRCPanelManager] DoInstantiatePanel succ:", type(umgPanel))
end

function NRCPanelManager:RefreshPanelOpenArg(module, panelData, panelArgs)
  if not module or not panelData then
    return
  end
  local curArgs = self.panelArgsDict[module.moduleName][panelData.panelName]
  if curArgs then
    panelArgs = panelArgs or {}
    self.panelArgsDict[module.moduleName][panelData.panelName] = panelArgs
    local dynamicArgs = self.panelArgsDynamicAdd[module.moduleName] and self.panelArgsDynamicAdd[module.moduleName][panelData.panelName]
    if dynamicArgs then
      for _, arg in ipairs(dynamicArgs) do
        table.insert(panelArgs, arg)
      end
    end
  end
end

function NRCPanelManager:AddPanelOpenArg(module, panelData, arg)
  if not (module and panelData) or not arg then
    return
  end
  local panelArgs = self.panelArgsDict[module.moduleName][panelData.panelName]
  if panelArgs then
    table.insert(panelArgs, arg)
    self.panelArgsDict[module.moduleName][panelData.panelName] = panelArgs
    if not self.panelArgsDynamicAdd[module.moduleName] then
      self.panelArgsDynamicAdd[module.moduleName] = {}
    end
    local dynamicArgs = self.panelArgsDynamicAdd[module.moduleName][panelData.panelName] or {}
    table.insert(dynamicArgs, arg)
    self.panelArgsDynamicAdd[module.moduleName][panelData.panelName] = dynamicArgs
    return panelArgs
  end
end

function NRCPanelManager:OnReceiveOpenRsp(module, panelData, rsp)
  self:AddPanelOpenArg(module, panelData, rsp)
  if rsp and rsp.ret_info and rsp.ret_info.ret_code and 0 == rsp.ret_info.ret_code then
    self:SetActiveConditionState(NRCPanelManager.ActivePreCondition.OpenRsp, panelData, module)
  else
    self:ClosePanel(module.moduleName, panelData.panelName)
    local reason = NRCPanelEnum.OpenFailedReason.RspError
    NRCEventCenter:DispatchEvent(NRCPanelEvent.OpenPanelFailed, reason, panelData)
  end
end

function NRCPanelManager:SetActiveConditionState(conditionEnum, panelData, module)
  local panelName = panelData.panelName
  if self.ActiveConditionState[panelName] == nil then
    self.ActiveConditionState[panelName] = 0
  end
  self.ActiveConditionState[panelName] = self.ActiveConditionState[panelName] | conditionEnum
  if 7 == self.ActiveConditionState[panelName] then
    local panel = self:GetPanel(module.moduleName, panelName)
    if nil ~= panel and panel.bAddtoViewport == true then
      self.ActiveConditionState[panelName] = nil
      self:InstantiatePanel(module, panel, panelData)
    end
  end
end

function NRCPanelManager:GetPanel(moduleName, panelName, isGetVisibleTrue, panelIdx)
  isGetVisibleTrue = isGetVisibleTrue or false
  panelIdx = panelIdx or 1
  if self.panelDict[moduleName] and self.panelDict[moduleName][panelName] and panelIdx <= #self.panelDict[moduleName][panelName] then
    local panelInst = self.panelDict[moduleName][panelName][panelIdx]
    local panel = panelInst and panelInst.inst
    if isGetVisibleTrue then
      if not panel then
        return nil
      end
      if panel.enableView then
        if panel.IsValid and not panel:IsValid() then
          Log.Error("panel was gced by UE, klass=", getmetatable(panel).__name)
        end
        return panel
      else
        return nil
      end
    else
      if panel and panel.IsValid and not panel:IsValid() then
        Log.Error("panel was gced by UE, klass=", getmetatable(panel).__name)
      end
      return panel
    end
  end
end

function NRCPanelManager:ClosePanel(moduleName, panelName, panelIndex)
  _G.NRCSDKManager:ReportExtraCrashData(UE4.ECrashDataReporterType.UIOperate, "ClosePanel " .. panelName)
  _G.NRCPanelBlocker:StopBlock()
  self:ClearPanelTriggerRecord(panelName)
  Log.Debug("[NRCPanelManager] ClosePanel:", moduleName, panelName)
  panelIndex = panelIndex or 1
  self:CloseCapture()
  if self.panelDataDict[moduleName] then
    local panelData = self.panelDataDict[moduleName][panelName]
    if panelData then
      if panelData.panelDynamicData then
        panelData.panelDynamicData:TriggerClose(panelData)
      end
      self:RemovePanelBlockIMC(panelData)
      _G.NRCModuleManager:DoCmd(_G.MultiTouchModuleCmd.RemoveSingleTouchPanel, panelData)
      _G.NRCProfilerLog:NRCPanelProfilerLog(false, true, panelName)
      self.debugData[panelData.panelPath] = nil
      local panel = self:GetPanel(moduleName, panelName, false, panelIndex)
      local hasPanel = false
      if nil ~= panel then
        if not panelData.NeedCapture or panelData.OpenCmd then
        end
        for i = #self.waitForAddToViewport, 1, -1 do
          if not self.waitForAddToViewport[i].umgPanel or self.waitForAddToViewport[i].umgPanel == panel then
            if not self.waitForAddToViewport[i].umgPanel then
              Log.Error("NRCPanelManager ClosePanel not self.waitForAddToViewport[i].umgPanel")
            end
            table.remove(self.waitForAddToViewport, i)
          end
        end
        if self.panelArgsDict[moduleName] then
          self.panelArgsDict[moduleName][panelName] = nil
        end
        if self.panelArgsDynamicAdd[moduleName] then
          self.panelArgsDynamicAdd[moduleName][panelName] = nil
        end
        if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
          _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, panelName)
          UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(0)
        end
        self:SafeCallPanelFunction(panelData.panelName, panel.Disable, panel)
        self:SafeCallPanelFunction(panelData.panelName, panel.Deactive, panel)
        Log.Debug("[NRCPanelManager] ClosePanel succ:", moduleName, panelName)
        self.layerCenter:RemoveFromLayerViewportByNameAndType(panelData.panelName, panelData.panelLayer)
        if panel and UE4.UObject.IsValid(panel) then
          UE4.UNRCStatics.DestroyImmediately(panel)
        end
        self:OnPostDestructPanel(panelData)
        if _G.GlobalConfig.DebugOpenUI then
          self:ClearLocalPlayerSkill()
        end
        if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN and not _G.BattleManager.isInBattle then
          NRCModuleManager:DoCmd(MultiTouchModuleCmd.EnableMultiTouch)
        end
        hasPanel = true
      end
      if self.ActiveConditionState[panelName] then
        self.ActiveConditionState[panelName] = nil
      end
      self:RemovePanel(moduleName, panelName, panelIndex)
      self:RemoveLoadingPanel(moduleName, panelData)
      local layerCtrl = self.layerCenter:GetLayerCtrl(panelData.panelLayer)
      if layerCtrl then
        layerCtrl:SetPanelAlreadyClosed(panelData.panelName)
      end
      if hasPanel and not BattleManager.isInBattle then
        if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN and not panelData.customDisableGC then
          NRCGCManager:TryGC(false, 100)
        else
          NRCGCManager:TryGC(false, panelData.closeGCWeight)
        end
      end
      if not self:IsUsingCacheMode() then
        self:RecyclePanel(moduleName, panelData.panelPath)
      end
      self:RemoveFromUIStack(moduleName, panelName)
      NRCEventCenter:DispatchEvent(NRCPanelEvent.ClosePanel, panelData)
    end
  end
end

function NRCPanelManager:CloseAllPanel(moduleName)
  if self.panelDict[moduleName] then
    for panelName, panelList in pairs(self.panelDict[moduleName]) do
      for i = 1, #panelList do
        self:ClosePanel(moduleName, panelName, i)
      end
    end
  end
end

function NRCPanelManager:CheckPanelVisible(panelName)
  for _, _panelList in pairs(self.panelDict) do
    for _panelName, _panelDetails in pairs(_panelList or {}) do
      if _panelName == panelName then
        local panelInst = _panelDetails and _panelDetails[1]
        local panel = panelInst and panelInst.inst
        if panel and UE4.UObject.IsValid(panel) then
          local visibility = panel:GetVisibility()
          if visibility ~= UE4.ESlateVisibility.Collapsed and visibility ~= UE4.ESlateVisibility.Hidden then
            return true
          end
        end
        break
      end
    end
  end
  return false
end

function NRCPanelManager:CheckStopRenderPanelCount()
  local stopRenderCount = 0
  for moduleName, panelList in pairs(self.panelDict) do
    for panelName, panelDetails in pairs(panelList) do
      for k, v in ipairs(panelDetails) do
        local panel = v.inst
        if panel and panel.panelData then
          local panelData = panel.panelData
          if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN and panelData.customDisableRendering == false and (panel:GetVisibility() == UE4.ESlateVisibility.Visible or panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible or panel:GetVisibility() == UE4.ESlateVisibility.HitTestInvisible) then
            Log.Error(panelData.panelName)
            stopRenderCount = stopRenderCount + 1
          end
        end
      end
    end
  end
end

function NRCPanelManager:GetCaptureShot()
end

function NRCPanelManager:GetAllOpenedPanelName()
  local lst = {}
  for moduleName, _ in pairs(self.panelDict) do
    for panelName, panelList in pairs(self.panelDict[moduleName]) do
      for i = 1, #panelList do
        table.insert(lst, panelName)
      end
    end
  end
  return lst
end

function NRCPanelManager:CloseAllPanelByLayer(panelLayer)
  local layerCtrl = self.layerCenter:GetLayerCtrl(panelLayer)
  if layerCtrl and layerCtrl.CloseAll then
    layerCtrl:CloseAll()
  end
end

function NRCPanelManager:AddPanel(moduleName, panelName, panel)
  Log.Debug("[NRCPanelManager] addPanel:", panelName)
  if not self.panelDict[moduleName] then
    self.panelDict[moduleName] = {}
  end
  if not self.panelDict[moduleName][panelName] then
    self.panelDict[moduleName][panelName] = {}
  end
  table.insert(self.panelDict[moduleName][panelName], {
    inst = panel,
    inst_Ref = UnLua.Ref(panel)
  })
end

function NRCPanelManager:RemovePanel(moduleName, panelName, panelIndex)
  Log.Debug("[NRCPanelManager] RemovePanel:", moduleName, panelName, panelIndex)
  if self.panelDict[moduleName] and self.panelDict[moduleName][panelName] and self.panelDict[moduleName][panelName][panelIndex] then
    Log.Debug("[NRCPanelManager] RemovePanel succ:", moduleName, panelName, panelIndex)
    local inst = self.panelDict[moduleName][panelName][panelIndex].inst
    if UE.UObject.IsValid(inst) then
      UnLua.Unref(inst)
    end
    table.remove(self.panelDict[moduleName][panelName], panelIndex)
  end
end

function NRCPanelManager:RecyclePanel(moduleName, panelPath)
  if not self.panelLoaderDict[moduleName] or not self.panelLoaderDict[moduleName][panelPath] then
    return
  end
  local loaderLst = self.panelLoaderDict[moduleName][panelPath]
  if loaderLst and #loaderLst > 0 then
    local resRequest = loaderLst[1]
    NRCResourceManager:UnLoadRes(resRequest)
    table.remove(loaderLst, 1)
    self.panelLoaderDict[moduleName][panelPath] = nil
  end
end

function NRCPanelManager:OnTick(deltaTime)
  if #self.waitForAddToViewport > 0 then
    local waitForAddPanelInfo = self.waitForAddToViewport[1]
    if waitForAddPanelInfo.cTime >= os.msTime() then
      Log.Warning("NRCPanelManager:OnTick:waitForAddPanelInfo.cTime > os.msTime()")
    end
    if waitForAddPanelInfo and os.msTime() - waitForAddPanelInfo.cTime > 30 then
      table.remove(self.waitForAddToViewport, 1)
      local umgPanel = waitForAddPanelInfo.umgPanel
      if umgPanel and UE4.UObject.IsValid(umgPanel) then
        local module = waitForAddPanelInfo.module
        local moduleName = module.moduleName
        local panelData = waitForAddPanelInfo.panelData
        local panelName = panelData.panelName
        local OpenReqParam = panelData.openReqParam
        Log.Debug("NRCPanelManager:AddToLayerViewport:", waitForAddPanelInfo.umgPanel, waitForAddPanelInfo.umgPanel.panelName, waitForAddPanelInfo.cTime, os.msTime())
        if panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
          UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(2)
        end
        self:OnPreConstructPanel(panelData)
        _G.NRCProfilerLog:NRCPanelAddToViewport(true, panelName)
        self.layerCenter:AddToLayerViewport(umgPanel, module)
        waitForAddPanelInfo.umgPanel.bAddtoViewport = true
        _G.NRCProfilerLog:NRCPanelAddToViewport(false, panelName)
        self:SafeCallPanelFunction(panelName, umgPanel.Disable, umgPanel)
        if self.ActiveConditionState[panelName] and 7 == self.ActiveConditionState[panelName] then
          self:InstantiatePanel(module, umgPanel, panelData)
        end
        if UE4.UObject.IsValid(umgPanel) then
          if umgPanel:IsA(UE4.UNRCUserWidget) then
            umgPanel:SetAddedToViewportInited(true)
          end
        else
          Log.Error("NRCPanelManager close panel in construct or active!", panelName)
        end
      else
        Log.Error("NRCPanelManager waitForAddToViewport fail:", umgPanel, UE4.UObject.IsValid(umgPanel))
        local module = waitForAddPanelInfo.module
        local moduleName = module.moduleName
        local panelData = waitForAddPanelInfo.panelData
        local panelName = panelData.panelName
        if self.ActiveConditionState[panelName] then
          self.ActiveConditionState[panelName] = nil
        end
        self:RemovePanel(moduleName, panelName, 1)
        self:RemoveLoadingPanel(moduleName, panelData)
        if not self:IsUsingCacheMode() then
          self:RecyclePanel(moduleName, panelData.panelPath)
        end
      end
    end
  end
  if #self.waitForClosePanel > 0 then
    local waitForClosePanelInfo = self.waitForClosePanel[1]
    if waitForClosePanelInfo and waitForClosePanelInfo:GetAllSonWidgetInitalize() then
      local layerCtrl = self.layerCenter:GetLayerCtrl(0)
      layerCtrl:DoCloseWindow(waitForClosePanelInfo)
      table.remove(self.waitForClosePanel, 1)
    end
  end
end

function NRCPanelManager:AddLoadingPanel(moduleName, panelData)
  if not self.isLoadingPanelDict[moduleName] then
    self.isLoadingPanelDict[moduleName] = {}
  end
  self.isLoadingPanelDict[moduleName][panelData.panelName] = true
  if panelData.fullSpeedDesired then
    _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.FullSpeed, panelData.panelName)
  end
end

function NRCPanelManager:RemoveLoadingPanel(moduleName, panelData)
  if self.isLoadingPanelDict[moduleName] then
    self.isLoadingPanelDict[moduleName][panelData.panelName] = false
  end
  if panelData.fullSpeedDesired then
    _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, panelData.panelName)
  end
end

function NRCPanelManager:IsLoadingPanel(moduleName, panelName)
  Log.Debug("[NRCPanelManager] IsLoadingPanel:", moduleName, panelName)
  if self.isLoadingPanelDict[moduleName] and self.isLoadingPanelDict[moduleName][panelName] then
    return true
  end
  return false
end

function NRCPanelManager:GetLoadingPanelCount(Mute)
  Mute = true == Mute
  local count = 0
  for moduleName, v in pairs(self.isLoadingPanelDict) do
    for panelName, boo in pairs(v) do
      if boo then
        count = count + 1
        if not Mute then
          Log.Debug("[NRCPanelManager] Panel is loading... :", moduleName, panelName)
          return count
        end
      end
    end
  end
  return count
end

function NRCPanelManager:GetPanelDict()
  return self.panelDict
end

function NRCPanelManager:IsUsingCacheMode()
  return self.cacheMode ~= NRCPanelManager.CacheType.NoCache
end

function NRCPanelManager:HasPanelAsset(panelName)
  return self.CacheAssetDict[panelName] ~= nil
end

function NRCPanelManager:GetPanelAsset(panelName)
  return self.CacheAssetDict[panelName]
end

function NRCPanelManager:AddToUIStack(moduleName, panelName)
  table.insert(self.PanelStack, {moduleName = moduleName, panelName = panelName})
end

function NRCPanelManager:RemoveFromUIStack(moduleName, panelName)
  for k, v in pairs(self.PanelStack) do
    if v.moduleName == moduleName and v.panelName == panelName then
      table.remove(self.PanelStack, k)
      break
    end
  end
end

function NRCPanelManager:GetTopVisiblePanel()
  local len = #self.PanelStack
  if len > 0 then
    for i = len, 1, -1 do
      local moduleName = self.PanelStack[i].moduleName
      local panelName = self.PanelStack[i].panelName
      local panel = self:GetPanel(moduleName, panelName)
      if panel and panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden then
        return panel
      end
    end
  end
  return nil
end

function NRCPanelManager:InstantiateGlobalPanelExitTrigger()
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if self.bInputBindEstablished then
    return
  end
  self.panelExitTriggerFreePool = {}
  self.panelExitTriggerElements = {}
  self.panelBlockTriggerFreePool = {}
  self.panelBlockTriggerElements = {}
  self:BindInputAction()
end

function NRCPanelManager:AddPanelTriggerRecord(panelName, triggerObj)
  if not string.IsNilOrEmpty(panelName) and triggerObj then
    local triggerList = self.panelTriggers[panelName]
    if triggerList then
      table.insert(triggerList, triggerObj)
    else
      self.panelTriggers[panelName] = {triggerObj}
    end
  end
end

function NRCPanelManager:RemovePanelTriggerRecord(panelName, triggerObj)
  if not string.IsNilOrEmpty(panelName) and triggerObj then
    local triggerList = self.panelTriggers[panelName]
    if triggerList then
      for i, v in ipairs(triggerList) do
        if v == triggerObj then
          table.remove(triggerList, i)
          break
        end
      end
    end
  end
end

function NRCPanelManager:ClearPanelTriggerRecord(panelName)
  if not string.IsNilOrEmpty(panelName) then
    self.panelTriggers[panelName] = nil
  end
end

function NRCPanelManager:UpdatePanelTriggerPriority(panelName, priority)
  if not string.IsNilOrEmpty(panelName) and priority then
    local triggerList = self.panelTriggers[panelName]
    if triggerList then
      for _, triggerObj in ipairs(triggerList) do
        if UE.UObject.IsValid(triggerObj) then
          UE.UNRCEnhancedInputHelper.SetInputMappingContextPriority(triggerObj, priority)
        end
      end
    end
  end
end

function NRCPanelManager:OnPreOpenPanel(PanelData)
end

function NRCPanelManager:OnPreConstructPanel(PanelData)
  if RocoEnv.PLATFORM_WINDOWS then
    self:DoInsertPanelImcWait(PanelData)
  end
end

function NRCPanelManager:DoInsertPanelImcWait(PanelData)
  if RocoEnv.PLATFORM_WINDOWS and PanelData then
    self:PushPanelWaitJudgeImc(PanelData)
  end
end

function NRCPanelManager:TryInsertImcManual(PanelData)
  if RocoEnv.PLATFORM_WINDOWS then
    self:DoRemovePanelImc(PanelData)
    self:DoInsertPanelImcWait(PanelData)
    self:DoJudgePanelInsertImc(PanelData)
  end
end

function NRCPanelManager:TryRemoveImcManual(PanelData)
  if RocoEnv.PLATFORM_WINDOWS then
    self:DoRemovePanelImc(PanelData)
  end
end

function NRCPanelManager:OnPostActivePanel(Panel)
  if RocoEnv.PLATFORM_WINDOWS then
    self:DoJudgePanelInsertImc(Panel.panelData)
  end
end

function NRCPanelManager:DoJudgePanelInsertImc(panelData)
  if RocoEnv.PLATFORM_WINDOWS then
  end
end

function NRCPanelManager:OnPostDestructPanel(PanelData)
  if RocoEnv.PLATFORM_WINDOWS then
    self:DoRemovePanelImc(PanelData)
  end
end

function NRCPanelManager:DoRemovePanelImc(PanelData)
  if RocoEnv.PLATFORM_WINDOWS then
    if not self._WaitJudgeIMCPanelStack or not PanelData then
      return
    end
    for i = #self._WaitJudgeIMCPanelStack, 1, -1 do
      local PanelInfo = self._WaitJudgeIMCPanelStack[i]
      if PanelInfo.PanelData == PanelData then
        Log.Debug("[IMC] pop panel", PanelData.panelName)
        table.remove(self._WaitJudgeIMCPanelStack, i)
        self:PopEscTrigger(PanelInfo)
      end
    end
  end
end

function NRCPanelManager:AddPanelBlockIMC(panelData)
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if not _G.NRCModuleManager:GetModule("EnhancedInputModule") then
    return
  end
  local Trigger = self:GetOrCreateBlockTrigger()
  if Trigger then
    local layerCtrl = self.layerCenter:GetLayerCtrl(panelData.panelLayer)
    local priority = 0
    if layerCtrl then
      priority = layerCtrl:GetWindowDepth(panelData.panelName)
    end
    local TriggerObj = ObjectRefUnBoxing(Trigger)
    self:AddPanelTriggerRecord(panelData.panelName, TriggerObj)
    _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, TriggerObj, priority)
    Log.Debug("+++++++++ AddPanelBlockIMC IMC = %s  PanelName = %s", TriggerObj:GetName(), panelData.panelName)
  else
    Log.Warning("[IMC] cannot allocate block trigger", panelData.panelName)
  end
  return Trigger
end

function NRCPanelManager:RemovePanelBlockIMC(panelData)
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if not _G.NRCModuleManager:GetModule("EnhancedInputModule") then
    return
  end
  if panelData and panelData.BlockTrigger then
    local TriggerObj = ObjectRefUnBoxing(panelData.BlockTrigger)
    self:RemovePanelTriggerRecord(panelData.panelName, TriggerObj)
    _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, TriggerObj)
    table.insert(self.panelBlockTriggerFreePool, panelData.BlockTrigger)
    Log.Debug("--------- RemovePanelBlockIMC IMC = %s  PanelName = %s", TriggerObj:GetName(), panelData.panelName)
  end
end

function NRCPanelManager:RemoveBlockIMC(blockTrigger)
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if not _G.NRCModuleManager:GetModule("EnhancedInputModule") then
    return
  end
  if blockTrigger then
    local TriggerObj = ObjectRefUnBoxing(blockTrigger)
    _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, TriggerObj)
    table.insert(self.panelBlockTriggerFreePool, blockTrigger)
  end
end

function NRCPanelManager:GetOrCreateBlockTrigger()
  if not self.panelBlockTriggerFreePool then
    return
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    return
  end
  if #self.panelBlockTriggerFreePool > 0 then
    return table.remove(self.panelBlockTriggerFreePool)
  end
  local Index = #self.panelBlockTriggerElements + 1
  local Obj = NewObject(UE.UInputMappingContext, GameInstance, "DynamicImc_Block_" .. Index)
  Obj.bBlock = true
  local Elem = ObjectRefBoxing(Obj)
  table.insert(self.panelBlockTriggerElements, Elem)
  Log.Info("[IMC] create dynamic block imc", Index)
  return Elem
end

function NRCPanelManager:GetOrCreateEscTrigger()
  if not self.panelExitTriggerFreePool then
    return
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    return
  end
  if #self.panelExitTriggerFreePool > 0 then
    return table.remove(self.panelExitTriggerFreePool)
  end
  local Index = #self.panelExitTriggerElements + 1
  local Obj = NewObject(UE.UInputMappingContext, GameInstance, "DynamicImc_Exit_" .. Index)
  Obj.bBlock = true
  local Elem = ObjectRefBoxing(Obj)
  table.insert(self.panelExitTriggerElements, Elem)
  Log.Info("[IMC] create dynamic exit imc", Index)
  return Elem
end

function NRCPanelManager:PushEscTrigger(PanelInfo)
  if PanelInfo then
    if PanelInfo.EscTrigger then
      Log.Info("[IMC] has esc trigger for panel", PanelInfo.PanelData.panelName)
    elseif PanelInfo.PanelData.enablePcEsc then
      local Trigger = self:GetOrCreateEscTrigger()
      if Trigger then
        local TriggerObj = ObjectRefUnBoxing(Trigger)
        PanelInfo.EscTrigger = Trigger
        local layerCtrl = self.layerCenter:GetLayerCtrl(PanelInfo.PanelData.panelLayer)
        local priority = 0
        if layerCtrl then
          priority = layerCtrl:GetWindowDepth(PanelInfo.PanelData.panelName)
        end
        self:AddPanelTriggerRecord(PanelInfo.PanelData.panelName, TriggerObj)
        _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, TriggerObj, priority)
        Log.Info("[IMC] push esc trigger for panel", PanelInfo.PanelData.panelName, TriggerObj:GetName())
      else
        Log.Warning("[IMC] cannot allocate esc trigger", PanelInfo.PanelData.panelName)
      end
    end
  end
end

function NRCPanelManager:PopEscTrigger(PanelInfo)
  if PanelInfo and PanelInfo.EscTrigger then
    local panelName = PanelInfo.PanelData and PanelInfo.PanelData.panelName
    local TriggerObj = ObjectRefUnBoxing(PanelInfo.EscTrigger)
    self:RemovePanelTriggerRecord(panelName, TriggerObj)
    _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, TriggerObj)
    table.insert(self.panelExitTriggerFreePool, PanelInfo.EscTrigger)
    Log.Info("[IMC] remove esc trigger", panelName, TriggerObj:GetName())
  end
end

function NRCPanelManager:PushPanelWaitJudgeImc(PanelData)
  if RocoEnv.PLATFORM_WINDOWS then
    if not self._WaitJudgeIMCPanelStack then
      self._WaitJudgeIMCPanelStack = {}
    else
      for i = #self._WaitJudgeIMCPanelStack, 1, -1 do
        if self._WaitJudgeIMCPanelStack[i].PanelData == PanelData then
          return
        end
      end
    end
    local PanelInfo = {PanelData = PanelData, EscTrigger = nil}
    table.insert(self._WaitJudgeIMCPanelStack, PanelInfo)
    Log.Debug("[IMC] push panel", PanelData.panelName)
    self:PushEscTrigger(PanelInfo)
  end
end

function NRCPanelManager:GetTopVisibleImcPanel()
  if self._WaitJudgeIMCPanelStack then
    local len = #self._WaitJudgeIMCPanelStack
    if len > 0 then
      local MaxiEscLayer = -1
      local MaxiEscLayerPanel
      for i = len, 1, -1 do
        local PanelInfo = self._WaitJudgeIMCPanelStack[i]
        local panelData = PanelInfo.PanelData
        if panelData then
          local moduleName = panelData.moduleName
          local panelName = panelData.panelName
          local panel = self:GetPanel(moduleName, panelName)
          if panel and panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden and PanelInfo.EscTrigger then
            local Ctrl = self.layerCenter:GetLayerCtrl(panelData.panelLayer)
            local Depth = Ctrl and Ctrl.depth
            if MaxiEscLayer < Depth then
              MaxiEscLayer = Depth
              MaxiEscLayerPanel = panel
            end
          end
        end
      end
      return MaxiEscLayerPanel
    end
    return nil
  end
end

function NRCPanelManager:IfBlockByEscPanel(PanelData)
  if not PanelData then
    return false
  end
  if self._WaitJudgeIMCPanelStack then
    local len = #self._WaitJudgeIMCPanelStack
    if len > 0 then
      local PanelCtrl = self.layerCenter:GetLayerCtrl(PanelData.panelLayer)
      local PanelDepth = PanelCtrl and PanelCtrl.depth or 0
      for i = len, 1, -1 do
        local PanelInfo = self._WaitJudgeIMCPanelStack[i]
        local panelData = PanelInfo.PanelData
        local moduleName = panelData.moduleName
        local panelName = panelData.panelName
        local panel = self:GetPanel(moduleName, panelName)
        if panelData.enablePcEsc and panel and panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden then
          local Ctrl = self.layerCenter:GetLayerCtrl(panelData.panelLayer)
          local Depth = Ctrl and Ctrl.depth or 0
          if PanelDepth < Depth then
            return true, panelData.panelName
          end
        end
      end
    end
  end
  return false
end

function NRCPanelManager:BindInputAction()
  if self.bInputBindEstablished then
    return
  end
  self.bInputBindEstablished = true
  local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
  ScenePlayerInputManager.RegisterActionEvent("ESC", self, self.OnPcClose)
  local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
  _G.NRCEventCenter:RegisterEvent("NRCPanelManager", self, LoginModuleEvent.PressEscape, self.OnPcClose)
end

function NRCPanelManager:UnBindInputAction()
  if not self.bInputBindEstablished then
    return
  end
  self.bInputBindEstablished = false
  local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
  ScenePlayerInputManager.UnRegisterActionEvent("ESC", self, self.OnPcClose)
  local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
  _G.NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.PressEscape, self.OnPcClose)
end

function NRCPanelManager:GetAppliedInputContexts()
  local World = UE4Helper.GetCurrentWorld()
  if not World or not UE.UObject.IsValid(World) then
    return
  end
  local Controller = UE.UGameplayStatics.GetPlayerController(World, 0)
  if not Controller or not UE.UObject.IsValid(Controller) then
    return
  end
  return Controller.PlayerInput.AppliedInputContexts
end

function NRCPanelManager:IfCanTriggerExitPanel()
  local AppliedInputContexts = self:GetAppliedInputContexts()
  if not AppliedInputContexts then
    return
  end
  local Num = AppliedInputContexts:Length()
  if Num <= 0 then
    return
  end
  local Prefix = "DynamicImc_Exit"
  for i = Num, 1, -1 do
    local Elem = AppliedInputContexts:Get(i)
    local Name = Elem:GetName()
    if string.StartsWith(Name, Prefix) then
      return true
    end
    if Elem and Elem.bBlock then
      return false, Elem:GetName()
    end
  end
end

function NRCPanelManager:OnPcClose(Event)
  if Event ~= UE.EInputEvent.IE_Released then
    return
  end
  if not UE4Helper.IsPCMode() then
    return
  end
  local Panel = self:GetTopVisibleImcPanel()
  if Panel and Panel.OnPcClose then
    if not Panel.panelData then
      return
    end
    local bTriggerEnabled, BlockBy = self:IfCanTriggerExitPanel()
    if not bTriggerEnabled then
      Log.Info("[IMC] Pending escape, but block by", BlockBy, "try notify panel", Panel.panelData.panelName)
      tcall(Panel, Panel.OnPcCloseByKeyDirectly)
      return
    end
    local exitAnims = {}
    exitAnims["1"] = Panel.Out
    exitAnims["2"] = Panel.out
    exitAnims["3"] = Panel.Close
    exitAnims["4"] = Panel.close
    exitAnims["5"] = Panel.GetAnimByIndex and Panel:GetAnimByIndex(2)
    for _, anim in pairs(exitAnims) do
      if anim and UE.UObject.IsA(anim, UE.UWidgetAnimation) and Panel:IsAnimationPlaying(anim) then
        Log.Info("[IMC] Pending escape, but panel is playing exit animation", Panel.panelData.panelName)
        return
      end
    end
    Log.Info("[IMC] Pending close panel", Panel.panelData.panelName)
    tcall(Panel, Panel.OnPcClose)
  else
    Log.Debug("[IMC] Cannot found esc panel")
  end
end

function NRCPanelManager:ClearLocalPlayerSkill()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.viewObj and localPlayer.viewObj.RocoSkill then
    SkillUtils.ClearSkillObj(localPlayer.viewObj.RocoSkill)
  end
end

local worldListenerVolumeStack = {}

local function CheckEnableWorldListenerVolume(enable, panelName)
  if enable then
    if worldListenerVolumeStack and #worldListenerVolumeStack > 0 then
      for i, name in ipairs(worldListenerVolumeStack) do
        if name == panelName then
          table.remove(worldListenerVolumeStack, i)
          break
        end
      end
    end
    return 0 == #worldListenerVolumeStack
  else
    table.insertUnique(worldListenerVolumeStack, panelName)
    return 1 == #worldListenerVolumeStack
  end
end

local db

function NRCPanelManager:SetEnableWorldListenerVolume(enable, panelName)
  if not db and _G.DataConfigManager then
    db = _G.DataConfigManager:GetGlobalConfigByKeyType("ui_audio_reduction_db", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  end
  if true == enable then
    if CheckEnableWorldListenerVolume(enable, panelName) then
      Log.Debug("=========================NRCPanelBase:EnableWorldListenerVolume", true, panelName)
      UE4.UNRCAudioManager.ResetWorldListenerVolumeOffset()
      _G.NRCAudioManager:SetStateByName("Fullscreen", "Close", "PanelManager")
    end
  elseif CheckEnableWorldListenerVolume(enable, panelName) then
    Log.Debug("=========================NRCPanelBase:EnableWorldListenerVolume", false, panelName)
    _G.UE4.UNRCAudioManager.SetWorldListenerVolumeOffset(db)
    _G.NRCAudioManager:SetStateByName("Fullscreen", "Open", "PanelManager")
  end
end

return NRCPanelManager

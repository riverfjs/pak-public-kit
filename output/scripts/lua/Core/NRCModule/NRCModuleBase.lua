local NRCModuleBase = NRCClass:Extend("NRCModuleBase")
local EventDispatcher = require("Common.EventDispatcher")
local NRCResourceManagerEnum = require("Core.Service.ResourceManager.NRCResourceManagerEnum")
local PriorityEnum = require("PriorityEnum")
local NRCPanelEnum = require("Core.NRCPanel.NRCPanelEnum")
local DefaultPreLoadPanelResCacheTime = 5
local WaitingRspPanelSeq = 1
local PanelStatus = {
  Enable = 1,
  Disable = 2,
  Closed = 3
}

local function OnSvrRspHandleAdapter(_callbackFunctor, _rsp)
  if _callbackFunctor then
    _callbackFunctor(_rsp)
  end
end

function NRCModuleBase:Ctor()
  NRCClass.Ctor(self)
  self.eventDispatcher = NRCClass()
  EventDispatcher():Attach(self.eventDispatcher)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    self.openSafeCheck = true
  else
    self.openSafeCheck = false
  end
  self.isActive = false
  self.moduleName = nil
  self.moduleData = nil
  self.enableLog = true
  self.moduleDataDict = {}
  self.modulePanelDataDict = {}
  self.moduleOpeningPanelLst = {}
  self.moduleOpenedPanelLst = {}
  self.moduleLivingPanelLst = {}
  self.modulePanelStatueDict = {}
  self.modulePanelPrevStatueDict = {}
  self.moduleEventDict = {}
  self.moduleCmdDict = {}
  self.moduleCurDataName = nil
  self.moduleWaitingOpenPanelLst = {}
  self.moduleWaitingRspPanelLst = {}
  self.PreLoadPanelAssetList = {}
  self.LoadResReqList = {}
end

function NRCModuleBase:OnReciviceLogin(isRelogin)
  self:Log("OnReciviceLogin:", isRelogin, self.moduleName)
  if isRelogin and self.moduleWaitingRspPanelLst and next(self.moduleWaitingRspPanelLst) then
    local moduleWaitingRspPanelLst = table.copy(self.moduleWaitingRspPanelLst)
    for panelName, _ in pairs(moduleWaitingRspPanelLst) do
      _G.tcall(self, self.ClosePanel, panelName)
    end
  end
  if self.OnLogin then
    self:OnLogin(isRelogin)
  end
end

function NRCModuleBase:OnReceiveActiveMode(modeName)
  if self.OnActiveMode then
    self:OnActiveMode(modeName)
  end
end

function NRCModuleBase:OnShutdown()
  self:CloseAllPanel()
end

function NRCModuleBase:SetModuleData(moduleData)
  self.moduleName = moduleData.moduleName
  self.moduleData = moduleData
  self.moduleHead = moduleData.moduleHead
  self.LogPrefix = string.format("[%s]", self.moduleName)
  self:Log("SetModuleData:", moduleData.moduleName)
end

function NRCModuleBase:Construct()
  self:RegisterHeadCmd()
  self:OnConstruct()
end

function NRCModuleBase:RegisterHeadCmd()
  if self.moduleHead then
    for cmdName, funcName in pairs(self.moduleHead.cmdDict) do
      if type(self[funcName]) ~= "function" then
        self:LogError("cmd callback is illegal:", cmdName, funcName, type(self[funcName]), self)
      else
        self:RegisterCmd(cmdName, self[funcName])
      end
    end
  end
end

function NRCModuleBase:OnConstruct()
end

function NRCModuleBase:Destruct()
  self:OnDestruct()
end

function NRCModuleBase:OnDestruct()
end

function NRCModuleBase:OnModuleBaseHookPreLoadMap()
  self:Log("\230\163\128\230\181\139\229\136\176\229\156\186\230\153\175\229\136\135\230\141\162\228\186\139\228\187\182")
  local lst = self:GetOpenedPanelName()
  self.ChangeMapPanelCache = {}
  if #lst > 0 then
    self:Log(string.format("\230\179\168\230\132\143\239\188\154\229\156\186\230\153\175\229\136\135\230\141\162\230\151\182\239\188\140%s\230\156\137%s\230\173\163\229\156\168\229\188\128\229\144\175\228\184\173\239\188\140Module\229\183\178\232\135\170\229\138\168\229\133\179\233\151\173\229\175\185\229\186\148Panel", self.moduleName, table.tostring(lst)))
    for i = #lst, 1, -1 do
      self:Log("lst[i]:", lst[i], i)
      table.insert(self.ChangeMapPanelCache, lst[i])
      self:ClosePanel(lst[i])
    end
  end
  self:Log("show ChangeMapPanelCache:", table.tostring(self.ChangeMapPanelCache), table.tostring(lst))
end

function NRCModuleBase:SetData(dataName, data)
  if type(data) == "string" then
    HotFix.ReloadFile(data)
    local dataCla = require(data)
    if type(dataCla) == "string" then
      self:LogError("\230\149\176\230\141\174\231\177\187\230\151\160\230\179\149\233\128\154\232\191\135\231\188\150\232\175\145:", data, self.moduleName)
      return nil
    end
    self:Log("setdata:", dataName)
    self.moduleDataDict[dataName] = dataCla()
  elseif type(data) == "table" then
    self.moduleDataDict[dataName] = data
  end
  self.moduleCurDataName = dataName
  self.moduleDataDict[dataName]:SetInitData(self)
  self.moduleDataDict[dataName].name = dataName
  return self.moduleDataDict[dataName]
end

function NRCModuleBase:GetData(dataName)
  dataName = dataName or self.moduleCurDataName
  self:Log("getdata:", dataName)
  if not self.moduleDataDict[dataName] then
    self.moduleDataDict[dataName] = NRCData()
  end
  return self.moduleDataDict[dataName]
end

function NRCModuleBase:ClearData(dataName)
  self.moduleDataDict[dataName] = nil
end

function NRCModuleBase:ClearAllData()
  self.moduleDataDict = {}
end

function NRCModuleBase:CacheConf(confName, conf, frame)
  if not self.cachedConfDict then
    self.cachedConfDict = {}
    self.cachedConfDelayIDDict = {}
  end
  if nil == frame then
    frame = 1
  end
  self.cachedConfDict[confName] = conf
  if -1 ~= frame then
    self.cachedConfDelayIDDict[confName] = DelayManager:DelayFrames(frame, function()
      if self.cachedConfDict then
        self:ClearConf(confName)
      end
    end)
  end
end

function NRCModuleBase:ClearConf(confName)
  if self.cachedConfDelayIDDict[confName] then
    DelayManager:CancelDelayById(self.cachedConfDelayIDDict[confName])
    self.cachedConfDelayIDDict[confName] = nil
  end
  self.cachedConfDict[confName] = nil
end

function NRCModuleBase:ActiveModule(...)
  if not self.isActive then
    self:Log("NRCModuleBase ActiveModule")
    self.isActive = true
    if self.OnTick ~= nil and type(self.OnTick) == "function" then
      self:Log("register tick")
      UpdateManager:Register(self)
    end
    if _G.NRCGlobalEvent then
      NRCEventCenter:RegisterEvent(self.moduleName, self, _G.NRCGlobalEvent.ON_LOGIN, self.OnReciviceLogin)
    end
    self:OnActive(...)
  else
    self:LogError("\232\175\183\229\139\191\233\135\141\229\164\141ActiveModule")
  end
end

function NRCModuleBase:OnActive(...)
end

function NRCModuleBase:DeactiveModule()
  self:Log("NRCModuleBase DeactiveModule")
  if self.isActive then
    self.ChangeMapPanelCache = {}
    self:OnDeactive()
    self:SafeCheck()
    self.isActive = false
    if self.OnTick and type(self.OnTick) == "function" then
      UpdateManager:UnRegister(self)
    end
    if _G.NRCGlobalEvent then
      NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_LOGIN, self.OnReciviceLogin)
    end
    self:CloseAllPanel()
    self:UnRegisterAllEvent()
    self:UnRegisterAllCmd()
    self:ClearAllData()
  else
    self:LogError("\232\175\183\229\139\191\233\135\141\229\164\141DeactiveModule")
  end
end

function NRCModuleBase:OnDeactive()
end

function NRCModuleBase:SafeCheck()
  if not self.openSafeCheck then
    return
  end
  if #self.moduleOpeningPanelLst > 0 then
  end
  if not table.isNil(self.moduleEventDict) then
  end
  if not table.isNil(self.moduleCmdDict) then
  end
  if not table.isNil(self.moduleDataDict) then
  end
end

function NRCModuleBase:RegisterRes(resData)
end

function NRCModuleBase:RegisterPanel(panelData)
  if not self.modulePanelDataDict[panelData.panelName] then
    panelData.panelPath = NRCUtils.FormatBlueprintAssetPath(panelData.panelPath)
    panelData.moduleName = self.moduleName
    panelData.backupRegisterPanelLayer = panelData.panelLayer
    self.modulePanelDataDict[panelData.panelName] = panelData
  else
    self:LogError("\232\175\183\229\139\191\233\135\141\229\164\141\230\179\168\229\134\140Panel:" .. panelData.panelName)
  end
end

function NRCModuleBase:RegisterPanelWithConf(confKey)
  local uiConf = DataConfigManager:GetUiConf(confKey)
  if uiConf then
    local panelData = _G.NRCPanelRegisterData()
    for k, v in pairs(uiConf) do
      panelData[k] = v
    end
    self:RegisterPanel(panelData)
  else
    self:LogError("\230\178\161\230\156\137\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132UI\233\133\141\231\189\174:", confKey)
  end
end

function NRCModuleBase:UnRegisterAllPanel()
end

function NRCModuleBase:PreLoadCachePanel()
  for panelName, panelData in pairs(self.modulePanelDataDict) do
    local cacheType = panelData.panelCacheType
    if cacheType == NRCPanelRegisterData.PanelCacheType.PreCache then
      self:Log("PreLoadCachePanel:", panelData.panelName)
      self:OpenPanel(panelData.panelName)
    end
  end
end

function NRCModuleBase:RegisterEvent(caller, eventName, handler)
  if not self.moduleEventDict[caller] then
    self.moduleEventDict[caller] = {}
  end
  if not self.moduleEventDict[caller][eventName] then
    self.moduleEventDict[caller][eventName] = {callFrom = caller, callback = handler}
    self.eventDispatcher:AddEventListener(caller, eventName, handler)
  end
end

function NRCModuleBase:UnRegisterEvent(caller, eventName)
  if not self.moduleEventDict[caller] then
    return
  end
  if self.moduleEventDict[caller][eventName] then
    local caller = self.moduleEventDict[caller][eventName].callFrom
    local callback = self.moduleEventDict[caller][eventName].callback
    self.eventDispatcher:RemoveEventListener(caller, eventName, callback)
    self.moduleEventDict[caller][eventName] = nil
  end
  if self.moduleEventDict[caller] then
    local i = -1
    for k, v in pairs(self.moduleEventDict[caller]) do
      i = 1
      break
    end
    if i < 0 then
      self.moduleEventDict[caller] = nil
    end
  end
end

function NRCModuleBase:DispatchEvent(eventName, ...)
  self.eventDispatcher:SendEvent(eventName, ...)
end

function NRCModuleBase:UnRegisterAllEvent()
  for caller, v in pairs(self.moduleEventDict) do
    for eventName, t in pairs(v) do
      self:UnRegisterEvent(caller, eventName)
    end
  end
end

function NRCModuleBase:RegisterCmd(cmd, handler)
  if not cmd then
    self:LogError("RegisterCmd fail:cmd is nil")
    return
  end
  if not self.moduleCmdDict[cmd] then
    local cmdData = {}
    cmdData.cmd = cmd
    cmdData.handler = SimpleDelegateFactory:CreateCallback(self, handler)
    self.moduleCmdDict[cmd] = cmdData
    NRCModuleManager:RegisterModuleCmd(cmd, self.moduleName)
  else
    self:Log("\232\175\183\229\139\191\233\135\141\229\164\141\230\179\168\229\134\140CMD:" .. cmd)
  end
end

function NRCModuleBase:UnRegisterCmd(cmd)
  NRCModuleManager:UnRegisterModuleCmd(cmd, self.moduleName)
  self.moduleCmdDict[cmd] = nil
end

function NRCModuleBase:UnRegisterAllCmd()
  for cmd, v in pairs(self.moduleCmdDict) do
    self:UnRegisterCmd(cmd)
  end
end

function NRCModuleBase:GetPanelData(panelName)
  self:Log("GetPanelData:", panelName)
  return self.modulePanelDataDict[panelName]
end

function NRCModuleBase:PreAssignedPanelDepth(panelName)
  local panelData = self:GetPanelData(panelName)
  if panelData then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:PreAssignedPanelDepth(panelName, self)
    end
  end
end

function NRCModuleBase:UndoPreAssignedPanelDepth(panelName)
  local panelData = self:GetPanelData(panelName)
  if panelData then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:UndoPreAssignedPanelDepth(panelName)
    end
  end
end

function NRCModuleBase:MarkPanelWaitingOpen(panelName, cancel)
  local curStatus = self.moduleWaitingOpenPanelLst[panelName]
  if cancel then
    self.moduleWaitingOpenPanelLst[panelName] = nil
  else
    self.moduleWaitingOpenPanelLst[panelName] = PanelStatus.Enable
  end
  return curStatus
end

function NRCModuleBase:OpenPanel(panelName, ...)
  local panelOptionIndex
  local panelArg = table.pack(...)
  local panelOpenOptions
  for i = 1, panelArg.n do
    local arg = panelArg[i]
    if "table" == type(arg) and rawget(arg, "__isPanelOpenOptions") then
      panelOpenOptions = arg
      panelOptionIndex = i
      break
    end
  end
  if panelOptionIndex then
    local newArgs = {}
    local newArgsCount = 0
    for i = 1, panelArg.n do
      if i ~= panelOptionIndex then
        newArgsCount = newArgsCount + 1
        newArgs[newArgsCount] = panelArg[i]
      end
    end
    return self:OpenPanelImpl(panelName, panelOpenOptions, table.unpack(newArgs, 1, newArgsCount))
  else
    return self:OpenPanelImpl(panelName, panelOpenOptions, ...)
  end
end

function NRCModuleBase:OpenPanelEx(panelName, priorityEnum, ...)
  return self:OpenPanelImpl(panelName, _G.NRCPanelOpenOptions.New():SetPriority(priorityEnum), ...)
end

function NRCModuleBase:OpenPanelImpl(panelName, panelOpenOptions, ...)
  self:Log("OpenPanel:", panelName, ...)
  local panelData = self:GetPanelData(panelName)
  if not panelData then
    self:LogError("OpenPanel fail: panelData is nil", panelName)
    return NRCPanelEnum.PanelOpenResult.Error
  end
  panelData.loadPriority = panelOpenOptions and panelOpenOptions.priority or PriorityEnum.UI_OpenPanel
  local curStatus = self:MarkPanelWaitingOpen(panelName, true)
  if curStatus == PanelStatus.Closed then
    return NRCPanelEnum.PanelOpenResult.NotAllowed
  end
  local hasPanel = self:HasPanel(panelName)
  local isPanelInOpening = self:IsPanelInOpening(panelName)
  if hasPanel or isPanelInOpening then
    local openStrategy = panelOpenOptions and panelOpenOptions.openStrategy or NRCPanelEnum.NRCPanelOpenStrategy.Default
    if openStrategy == NRCPanelEnum.NRCPanelOpenStrategy.Default then
      local needCloseFirst = _G.NRCPanelManager:CheckNeedCloseFirst(panelData)
      if not needCloseFirst then
        if RocoEnv.IS_EDITOR then
          self:LogWarning("\232\175\183\229\139\191\229\164\154\230\172\161\230\137\147\229\188\128\229\144\140\228\184\128\228\184\170\233\157\162\230\157\191:", panelName)
        end
        return hasPanel and NRCPanelEnum.PanelOpenResult.Opened or NRCPanelEnum.PanelOpenResult.Opening
      else
        self:ClosePanel(panelName)
      end
    elseif openStrategy == NRCPanelEnum.NRCPanelOpenStrategy.ForceCloseFirst then
      self:ClosePanel(panelName)
    elseif openStrategy == NRCPanelEnum.NRCPanelOpenStrategy.BringToFront then
      if isPanelInOpening and panelOpenOptions and panelOpenOptions.refreshOpeningArgs then
        _G.NRCPanelManager:RefreshPanelOpenArg(self, panelData, table.pack(...))
      end
      self:BringPanelToFront(panelName, ...)
      return NRCPanelEnum.PanelOpenResult.BringToFront
    end
  end
  local panelOpenResult = NRCPanelEnum.PanelOpenResult.Error
  if GlobalConfig.DontShowUI == false then
    local panelArg = table.pack(...)
    local success = _G.NRCPanelManager:OpenPanel(self, panelData, panelArg)
    if success then
      panelOpenResult = NRCPanelEnum.PanelOpenResult.Success
      self:AddOpening(panelName)
      self:AddLiving(panelName)
      if curStatus ~= PanelStatus.Disable then
        self:SetPanelEnable(panelName, true)
      else
        self.modulePanelPrevStatueDict[panelName] = false
        self:SetPanelEnable(panelName, false)
      end
    end
  end
  return panelOpenResult
end

function NRCModuleBase:OpenPanelTest(panelName, ...)
  local panelArg = table.pack(...)
  if GlobalConfig.DontShowUI == false then
    _G.NRCPanelManager:OpenPanelTest(self, self:GetPanelData(panelName), panelArg)
  end
end

function NRCModuleBase:BringPanelToFront(panelName, ...)
  self:Log("BringPanelToFront:", panelName, ...)
  local panelData = self:GetPanelData(panelName)
  if panelData then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:BringToFront(panelData.panelName, ...)
    end
  end
end

function NRCModuleBase:SendPanelToBack(panelName, ...)
  self:Log("SendPanelToBack:", panelName, ...)
  local panelData = self:GetPanelData(panelName)
  if panelData then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:SendToBack(panelData.panelName, ...)
    end
  end
end

function NRCModuleBase:SendOpenReq(module, panelData, openReqParam)
  if openReqParam and openReqParam.reqClass ~= nil then
    local req = openReqParam.reqClass
    if openReqParam.paramList then
      for k, v in pairs(openReqParam.paramList) do
        req[k] = v
      end
    end
    local seq = WaitingRspPanelSeq + 1
    WaitingRspPanelSeq = seq
    local OpenReqInfo = {
      Module = module,
      PanelData = panelData,
      CmdId = openReqParam.cmdId,
      Seq = seq
    }
    _G.NRCProfilerLog:NRCProtoReqAndRspInterval(openReqParam.cmdId, true, panelData.panelName)
    local sendSuccess = _G.ZoneServer:SendWithHandler(openReqParam.cmdId, req, _G.MakeWeakFunctor(self, self.OnPanelActive, OpenReqInfo), OnSvrRspHandleAdapter)
    if sendSuccess then
      self.moduleWaitingRspPanelLst[panelData.panelName] = seq
    end
    return sendSuccess
  end
end

function NRCModuleBase:OnPanelActive(_openReqInfo, _rsp)
  local panelName = _openReqInfo.PanelData.panelName
  if self.moduleWaitingRspPanelLst[panelName] ~= _openReqInfo.Seq then
    return
  end
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_openReqInfo.CmdId, false, panelName)
  if _openReqInfo.PanelData and _openReqInfo.PanelData.openReqParam then
    local openReqParam = _openReqInfo.PanelData.openReqParam
    if openReqParam and openReqParam.Caller and openReqParam.Callback then
      openReqParam.Callback(openReqParam.Caller, _rsp)
    end
  end
  _G.NRCPanelManager:OnReceiveOpenRsp(_openReqInfo.Module, _openReqInfo.PanelData, _rsp)
  self.moduleWaitingRspPanelLst[panelName] = nil
end

function NRCModuleBase:OnOpenPanelCallback(panelName, panelIndex, isSucc)
  self:Log("OnOpenPanelCallback:", panelName, panelIndex, isSucc, self.modulePanelStatueDict[panelName])
  if isSucc then
    self:RemoveOpening(panelName, panelIndex)
    self:AddOpened(panelName, panelIndex)
    if not self:IsPanelEnabled(panelName) then
      self:DisablePanel(panelName, NRCPanelEnum.PanelDisableReason.None)
    end
  else
    self:RemoveOpening(panelName, panelIndex)
  end
end

function NRCModuleBase:ClosePanel(panelName)
  self:Log("ClosePanel:", self.moduleName, panelName)
  local isHas, panelIndex = self:HasPanel(panelName)
  if isHas then
    local panel = self:GetPanel(panelName)
    if panel and panel:GetIsSelectBtn() then
      panel:RevertIsSelectBtn()
    end
  end
  self.modulePanelStatueDict[panelName] = nil
  self.modulePanelPrevStatueDict[panelName] = nil
  self.moduleWaitingRspPanelLst[panelName] = nil
  self:RemoveOpening(panelName)
  self:RemoveOpened(panelName)
  self:RemoveLiving(panelName)
  self:ReleaseLoadRes(panelName)
  _G.NRCPanelManager:ClosePanel(self.moduleName, panelName)
end

function NRCModuleBase:EnablePanel(panelName, reason)
  if not self:SetPanelEnable(panelName, true, reason) then
    return
  end
  local panel = self:GetPanel(panelName)
  if nil ~= panel then
    panel:Enable()
  end
end

function NRCModuleBase:DisablePanel(panelName, reason)
  self:SetPanelEnable(panelName, false, reason)
  if self:HasPanel(panelName) then
    local panel = self:GetPanel(panelName)
    if nil ~= panel then
      panel:Disable(reason)
    end
  end
end

function NRCModuleBase:SetPanelEnable(panelName, enable, reason)
  if not reason or type(reason) ~= "number" then
    reason = NRCPanelEnum.PanelDisableReason.Default
  end
  local curReason = self.modulePanelStatueDict[panelName] or 0
  self:Log("SetPanelEnable", panelName, enable, reason, curReason)
  if enable then
    self.modulePanelStatueDict[panelName] = 0 ~= reason and curReason & ~reason or 0
  else
    self.modulePanelStatueDict[panelName] = curReason | reason
  end
  return self:IsPanelEnabled(panelName)
end

function NRCModuleBase:IsPanelEnabled(panelName)
  local curReason = self.modulePanelStatueDict[panelName] or 0
  return 0 == curReason
end

function NRCModuleBase:DisablePanelByLayer(layer, filterPanelList)
  for i = 1, #self.moduleLivingPanelLst do
    local panelName = self.moduleLivingPanelLst[i]
    local panelData = self:GetPanelData(panelName)
    if panelData and panelData.panelLayer == layer then
      if self.modulePanelPrevStatueDict[panelName] == false then
        self:Log("\232\175\183\229\139\191\229\164\154\230\172\161\232\176\131\231\148\168DisablePanelByLayer\239\188\140\232\176\131\231\148\168DisablePanelByLayer\229\144\142\233\156\128\232\166\129\232\176\131\231\148\168RevertPanelEnableStateByLayer\229\164\141\229\142\159UI\231\138\182\230\128\129", layer)
        return
      end
      if not filterPanelList or not filterPanelList[panelName] then
        self.modulePanelPrevStatueDict[panelName] = false
        if self:IsPanelEnabled(panelName) then
          self:DisablePanel(panelName)
        else
          self:SetPanelEnable(panelName, false)
        end
      else
        Log.Debug("\232\175\165\233\157\162\230\157\191\232\162\171\232\191\135\230\187\164\239\188\140\228\184\141Disable\232\175\165\233\157\162\230\157\191\239\188\140" .. panelName)
      end
    end
  end
  for panelName, status in pairs(self.moduleWaitingOpenPanelLst) do
    if status == PanelStatus.Enable then
      local panelData = self:GetPanelData(panelName)
      if panelData and panelData.panelLayer == layer and (not filterPanelList or not filterPanelList[panelName]) then
        self.moduleWaitingOpenPanelLst[panelName] = PanelStatus.Disable
      end
    end
  end
end

function NRCModuleBase:RevertPanelEnableStateByLayer(layer)
  for i = 1, #self.moduleLivingPanelLst do
    local panelName = self.moduleLivingPanelLst[i]
    local panelData = self:GetPanelData(panelName)
    if panelData and panelData.panelLayer == layer and self.modulePanelPrevStatueDict[panelName] ~= nil then
      if self.modulePanelPrevStatueDict[panelName] then
        self:DisablePanel(panelName)
      else
        local bCheckHasDisableMainPopUp = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CheckHasDisableMainPopUp) or false
        if layer ~= _G.Enum.UILayerType.UI_LAYER_MAIN or not _G.BattleManager.isInBattle and not bCheckHasDisableMainPopUp then
          self:EnablePanel(panelName)
          self.modulePanelPrevStatueDict[panelName] = nil
        end
      end
    end
  end
  for panelName, status in pairs(self.moduleWaitingOpenPanelLst) do
    local panelData = self:GetPanelData(panelName)
    if panelData and panelData.panelLayer == layer then
      if status == PanelStatus.Enable then
        self.moduleWaitingOpenPanelLst[panelName] = PanelStatus.Disable
      elseif status == PanelStatus.Disable then
        self.moduleWaitingOpenPanelLst[panelName] = nil
      end
    end
  end
end

function NRCModuleBase:ClosePanelByLayer(layer)
  local livingPanelLst = table.copy(self.moduleLivingPanelLst)
  if livingPanelLst then
    for i = #livingPanelLst, 1, -1 do
      local panelName = livingPanelLst[i]
      local panelData = self:GetPanelData(panelName)
      if panelData and panelData.panelLayer == layer then
        self:ClosePanel(panelName)
      end
    end
  end
  for panelName, _ in pairs(self.moduleWaitingOpenPanelLst) do
    local panelData = self:GetPanelData(panelName)
    if panelData and panelData.panelLayer == layer then
      self.moduleWaitingOpenPanelLst[panelName] = PanelStatus.Closed
    end
  end
end

function NRCModuleBase:HasPanel(panelName)
  for i = 1, #self.moduleOpenedPanelLst do
    if self.moduleOpenedPanelLst[i] == panelName then
      return true, i
    end
  end
  return false, 0
end

function NRCModuleBase:IsPanelInOpening(panelName)
  for i = 1, #self.moduleOpeningPanelLst do
    if self.moduleOpeningPanelLst[i] == panelName then
      return true
    end
  end
end

function NRCModuleBase:GetOpenedPanelName()
  return self.moduleOpenedPanelLst
end

function NRCModuleBase:GetLivingPanelName()
  return self.moduleLivingPanelLst
end

function NRCModuleBase:GetPanel(panelName, panelIndex)
  local panel = _G.NRCPanelManager:GetPanel(self.moduleName, panelName, false, 1)
  if not panel then
    self:LogError("\232\142\183\229\143\150Panel\229\164\177\232\180\165:", panelName)
  end
  return panel
end

function NRCModuleBase:CloseAllPanel()
  local livingPanelLst = table.copy(self.moduleLivingPanelLst)
  if livingPanelLst then
    for i = #livingPanelLst, 1, -1 do
      self:Log("CloseAllPanel:", livingPanelLst[i])
      self:ClosePanel(livingPanelLst[i])
    end
  end
end

function NRCModuleBase:EnableOrDisableAllPanel(bEnable)
  if bEnable then
    for i = #self.moduleLivingPanelLst, 1, -1 do
      self:EnablePanel(self.moduleLivingPanelLst[i])
    end
  else
    for i = #self.moduleLivingPanelLst, 1, -1 do
      self:DisablePanel(self.moduleLivingPanelLst[i])
    end
  end
end

function NRCModuleBase:DoCmdInternal(cmd, ...)
  if self.moduleCmdDict[cmd] ~= nil then
    return self.moduleCmdDict[cmd]:handler(...)
  end
end

function NRCModuleBase:DoCmdAsync(asyncData, cmd, ...)
  if self.moduleCmdDict[cmd] ~= nil then
    return self.moduleCmdDict[cmd]:handler(asyncData, ...)
  end
end

function NRCModuleBase:Log(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogDebug, 4, self.LogPrefix, ...)
  end
end

function NRCModuleBase:LogWarning(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogWarn, 3, self.LogPrefix, ...)
  end
end

function NRCModuleBase:LogTrace(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogTrace, 3, self.LogPrefix, ...)
  end
end

function NRCModuleBase:LogError(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogError, 3, self.LogPrefix, ...)
  end
end

function NRCModuleBase:AddOpening(panelName, panelIndex)
  table.insert(self.moduleOpeningPanelLst, panelName)
end

function NRCModuleBase:RemoveOpening(panelName, panelIndex)
  for i = 1, #self.moduleOpeningPanelLst do
    if self.moduleOpeningPanelLst[i] == panelName then
      table.remove(self.moduleOpeningPanelLst, i)
      return
    end
  end
end

function NRCModuleBase:AddOpened(panelName, panelIndex)
  table.insert(self.moduleOpenedPanelLst, panelName)
end

function NRCModuleBase:RemoveOpened(panelName, panelIndex)
  for i = 1, #self.moduleOpenedPanelLst do
    if self.moduleOpenedPanelLst[i] == panelName then
      table.remove(self.moduleOpenedPanelLst, i)
      return
    end
  end
end

function NRCModuleBase:AddLiving(panelName, panelIndex)
  table.insert(self.moduleLivingPanelLst, panelName)
end

function NRCModuleBase:RemoveLiving(panelName, panelIndex)
  for i = 1, #self.moduleLivingPanelLst do
    if self.moduleLivingPanelLst[i] == panelName then
      table.remove(self.moduleLivingPanelLst, i)
      return
    end
  end
end

function NRCModuleBase:PreLoadPanel(panelName, cacheTime, priorityEnum)
  if self:HasPanel(panelName) or self:IsPanelInOpening(panelName) then
    return
  end
  local priority = priorityEnum or PriorityEnum.UI_PreLoadPanel_Default
  local panelData = self:GetPanelData(panelName)
  if panelData then
    local function PreLoadResAsync(resPath)
      local resRequest = NRCResourceManager:LoadResAsync(self, resPath, priority, cacheTime or DefaultPreLoadPanelResCacheTime)
      
      if resRequest then
        resRequest.isPreLoadPanel = true
        self:AddResRequest(panelName, resRequest)
      end
    end
    
    PreLoadResAsync(panelData.panelPath)
    local resList = panelData.necessaryResList
    if resList then
      for _, _res in ipairs(resList) do
        PreLoadResAsync(_res)
      end
    end
  end
end

function NRCModuleBase:CancelPreLoadPanel(panelName)
  self:RemoveResRequest(panelName, function(resRequest)
    return resRequest.isPreLoadPanel
  end)
end

function NRCModuleBase:PreLoadPanelRes(resList, panelData, module, activePreCondition, priority)
  local panelName = panelData and panelData.panelName
  if nil == panelName then
    return
  end
  if not resList or 0 == #resList then
    return
  end
  if NRCPanelManager.ActivePreCondition.PreLoadRes == activePreCondition then
    _G.NRCProfilerLog:NRCPanelPreloadRes(true, panelName)
  end
  local LoadResNum = 0
  if nil == self.PreLoadPanelAssetList[panelName] then
    self.PreLoadPanelAssetList[panelName] = {}
  end
  
  local function CheckAllAssetLoaded()
    if activePreCondition and LoadResNum == #resList then
      NRCPanelManager:SetActiveConditionState(activePreCondition, panelData, module)
      if NRCPanelManager.ActivePreCondition.PreLoadRes == activePreCondition then
        _G.NRCProfilerLog:NRCPanelPreloadRes(false, panelName)
      end
    end
  end
  
  local function OnLoadFinished(caller, resRequest, asset)
    LoadResNum = LoadResNum + 1
    if caller then
      table.insert(caller.PreLoadPanelAssetList[panelName], {
        path = resRequest.assetPath,
        realAsset = asset,
        realAssetRef = asset and UnLua.Ref(asset)
      })
    end
    CheckAllAssetLoaded()
  end
  
  local function OnLoadFailed(caller, resRequest, errorMsg)
    LoadResNum = LoadResNum + 1
    Log.Error("[NRCModuleBase] PreLoadPanelRes fail:", resRequest and resRequest.assetPath)
    CheckAllAssetLoaded()
  end
  
  if resList and #resList > 0 then
    for _, v in ipairs(resList) do
      self:LoadRes(panelName, v, OnLoadFinished, OnLoadFailed, nil, priority)
    end
  end
end

function NRCModuleBase:LoadRes(panelName, resPath, succCallback, failedCallback, progressCallback, priorityEnum)
  local priority = priorityEnum or PriorityEnum.UI_LoadRes_Default
  local resRequest = NRCResourceManager:LoadResAsync(self, resPath, priority, 0, succCallback, failedCallback, progressCallback)
  self:AddResRequest(panelName, resRequest)
  return resRequest
end

function NRCModuleBase:AddResRequest(panelName, resRequest)
  if not panelName or not resRequest then
    return
  end
  if self.LoadResReqList[panelName] == nil then
    self.LoadResReqList[panelName] = {}
  end
  table.insert(self.LoadResReqList[panelName], resRequest)
end

function NRCModuleBase:RemoveResRequest(panelName, conditionFun, conditionFunThis)
  local resReqList = panelName and self.LoadResReqList[panelName]
  if resReqList then
    local index = #resReqList
    while index > 0 do
      local shouldRemove = true
      if conditionFun then
        shouldRemove = conditionFunThis and conditionFun(conditionFunThis, resReqList[index]) or conditionFun(resReqList[index])
      end
      if shouldRemove then
        NRCResourceManager:UnLoadRes(resReqList[index])
        table.remove(resReqList, index)
      end
      index = index - 1
    end
  end
end

function NRCModuleBase:GetRes(path, panelName)
  local assetList = self.PreLoadPanelAssetList[panelName]
  if assetList and #assetList > 0 then
    for k, v in ipairs(assetList) do
      if v.path == path then
        return v.realAsset
      end
    end
  end
  Log.Error("\230\178\161\230\156\137\232\142\183\229\143\150\229\136\176\229\175\185\229\186\148\232\181\132\230\186\144", path)
  return nil
end

function NRCModuleBase:ReleaseLoadRes(PanelName)
  local assetList = self.PreLoadPanelAssetList[PanelName]
  if assetList and #assetList > 0 then
    for k, v in ipairs(assetList) do
      v.realAsset:Release()
      v.realAsset = nil
      v.realAssetRef = nil
      v = nil
    end
    self.PreLoadPanelAssetList[PanelName] = nil
  end
  local resReqList = self.LoadResReqList[PanelName]
  if resReqList and #resReqList > 0 then
    for k, v in ipairs(resReqList) do
      NRCResourceManager:UnLoadRes(v)
    end
    self.LoadResReqList[PanelName] = nil
  end
end

return NRCModuleBase

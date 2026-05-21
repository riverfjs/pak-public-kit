local MultiTouchModule = NRCModuleBase:Extend("MultiTouchModule")
local TimeoutEventListener = require("Common.TimeoutEventListener")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")

function MultiTouchModule:OnConstruct()
  _G.MultiTouchModuleCmd = reload("NewRoco.Modules.Core.MultiTouch.MultiTouchModuleCmd")
  self.data = self:SetData("MultiTouchModuleData", "NewRoco.Modules.Core.MultiTouch.MultiTouchModuleData")
  local TouchBlockingMaskPanelData = _G.NRCPanelRegisterData()
  TouchBlockingMaskPanelData.panelName = "UMG_TouchBlockingMask"
  TouchBlockingMaskPanelData.panelPath = "/Game/NewRoco/Modules/Core/MultiTouch/Res/UMG_TouchBlockingMask"
  TouchBlockingMaskPanelData.panelLayer = Enum.UILayerType.UI_LAYER_TOP
  TouchBlockingMaskPanelData.enableTouchMask = false
  TouchBlockingMaskPanelData.panelCacheType = NRCPanelRegisterData.PanelCacheType.PreCache
  TouchBlockingMaskPanelData.enablePcEsc = false
  self:RegisterPanel(TouchBlockingMaskPanelData)
  self:OnSetMultiTouchLimit(self.data.defaultTouchLimit)
  self.data.addPanelTypeList = {
    _G.Enum.UILayerType.UI_LAYER_FULLSCREEN
  }
  self.EventListener = TimeoutEventListener()
end

function MultiTouchModule:OnActive()
  _G.NRCEventCenter:RegisterEvent("MultiTouchModule", self, NRCGlobalEvent.OnApplicationWillDeactivate, self.OnMultiTouchModuleWillDeactivate)
  _G.NRCEventCenter:RegisterEvent("MultiTouchModule", self, NRCGlobalEvent.OnApplicationHasReactivated, self.OnMultiTouchModuleHasReactivated)
end

function MultiTouchModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationWillDeactivate, self.OnMultiTouchModuleWillDeactivate)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasReactivated, self.OnMultiTouchModuleHasReactivated)
end

function MultiTouchModule:OnMultiTouchModuleWillDeactivate()
  self:Log("ModifyNRCMultiTouchSetting==OnMultiTouchModuleWillDeactivate")
  self.data.revertTimer = 0
  self:ModifyNRCMultiTouchSetting(self.data.disableTouchLimit)
end

function MultiTouchModule:OnMultiTouchModuleHasReactivated()
  self:Log("ModifyNRCMultiTouchSetting==OnMultiTouchModuleHasReactivated")
  self.data.revertTimer = 0
end

function MultiTouchModule:OnReciviceLogin(isRelogin)
  self.data.enableTouchMask = true
end

function MultiTouchModule:OnEnableMultiTouch()
  self:Log("ModifyNRCMultiTouchSetting==OnEnableMultiTouch==TouchValue==", self.data.touchInputLimit)
  self:OnSetMultiTouchLimit(self.data.touchInputLimit)
end

function MultiTouchModule:OnDisableMultiTouch(touchCount)
  self:Log("ModifyNRCMultiTouchSetting==OnDisableMultiTouch")
  self:OnSetMultiTouchLimit(touchCount)
end

function MultiTouchModule:OnSetMultiTouchLimit(value)
  if _G.App:GetIsAppDeactivate() then
    return
  end
  local curTouchLimit = UE4.UNRCStatics.ModifyNRCGetTouchLimit()
  if curTouchLimit == value then
    return
  end
  self:Log("ModifyNRCMultiTouchSetting==OnSetMultiTouchLimit==TouchValue==", value)
  self.data.touchInputLimit = value
  self:ModifyNRCMultiTouchSetting(self.data.touchInputLimit)
end

function MultiTouchModule:OnRevertMultiTouchLimit()
end

function MultiTouchModule:OnOpenBlockingMask()
  if self:CheckIsThrowing() then
    return
  end
  if not self.data.enableTouchMask then
    return
  end
  self:Log("ModifyNRCMultiTouchSetting==OnOpenBlockingMask")
  self:ModifyNRCMultiTouchSetting(self.data.disableTouchLimit)
end

function MultiTouchModule:ModifyNRCMultiTouchSetting(value)
  UE4.UNRCStatics.ModifyNRCMultiTouchSetting(value, true)
end

function MultiTouchModule:OnCloseBlockingMask()
  if self:CheckIsThrowing() then
    return
  end
  if not self.data.enableTouchMask then
    return
  end
  self:Log("ModifyNRCMultiTouchSetting==OnCloseBlockingMask==TouchValue==", self.data.touchInputLimit)
  self:OnSetMultiTouchLimit(self.data.touchInputLimit)
end

function MultiTouchModule:OnIsNRCButtonTouchable()
end

function MultiTouchModule:OnAddSingleTouchPanel(panelData)
  if self:CheckCanAddPanelStack(panelData) then
    self:Log("ModifyNRCMultiTouchSetting==OnAddSingleTouchPanel", panelData.panelName)
    local panel = {
      panelName = panelData.panelName,
      touchCount = panelData.touchCount,
      timestamp = _G.UpdateManager.Timestamp
    }
    table.insert(self.data.panelStack, panel)
    self:OnSetMultiTouchLimit(panelData.touchCount)
  end
end

function MultiTouchModule:OnRemoveSingleTouchPanel(panelData)
  if self:CheckCanAddPanelStack(panelData) then
    for k, v in pairs(self.data.panelStack) do
      if v.panelName and v.panelName == panelData.panelName then
        self:Log("ModifyNRCMultiTouchSetting==OnRemoveSingleTouchPanel", panelData.panelName)
        table.remove(self.data.panelStack, k)
        break
      end
    end
  end
  self:OnSetMultiTouchLimit(self:GetCurPanelTouchCount())
end

function MultiTouchModule:OnJoystickStartTouch()
  Log.Debug("ModifyNRCMultiTouchSetting==OnJoystickStartTouch")
  local curTouchLimit = UE4.UNRCStatics.ModifyNRCGetTouchLimit()
  if curTouchLimit < self.data.joystickTouchLimit then
    self:OnSetMultiTouchLimit(self.data.joystickTouchLimit)
  end
end

function MultiTouchModule:OnJoystickEndTouch()
  Log.Debug("ModifyNRCMultiTouchSetting==OnJoystickEndTouch")
  local curPanelTouchCount = self:GetCurPanelTouchCount()
  self:OnSetMultiTouchLimit(curPanelTouchCount)
end

function MultiTouchModule:CheckCanAddPanelStack(panelData)
  local isInAddPanelTypeList = false
  for _, v in ipairs(self.data.addPanelTypeList) do
    if panelData.panelLayer == v then
      isInAddPanelTypeList = true
      break
    end
  end
  return isInAddPanelTypeList or panelData.isSingleTouchPanel or panelData.panelName == "LobbyMain" or panelData.panelName == "LobbyMainLocal"
end

function MultiTouchModule:GetCurPanelTouchCount(checkPanel)
  local len = #self.data.panelStack
  if 0 == len then
    return self.data.defaultTouchLimit
  else
    local touchCount = self.data.panelStack[len].touchCount
    if touchCount then
      if checkPanel and touchCount <= self.data.singleTouchLimit and len <= 1 then
        local panelStackData = self.data.panelStack[len]
        local panelName = panelStackData and panelStackData.panelName
        local addTimeStamp = panelStackData and panelStackData.timestamp
        local curTimeStamp = _G.UpdateManager.Timestamp
        if panelName and addTimeStamp and curTimeStamp - addTimeStamp > 300 then
          if not _G.NRCPanelManager:CheckPanelVisible(panelName) then
            self.data.panelStack[len] = nil
            NRCUtils.LuaFatalError("error touch limit!", "MultiTouch Exception", string.format("%s is not visible but still in panelStack!", panelName), true)
          else
            panelStackData.timestamp = curTimeStamp
          end
        end
      end
      return math.max(touchCount, self.data.singleTouchLimit)
    else
      return self.data.singleTouchLimit
    end
  end
end

function MultiTouchModule:GetIsJoystickTouch()
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if mainUIModule then
    return NRCModuleManager:DoCmd(MainUIModuleCmd.GetIsJoystickTouch)
  else
    return false
  end
end

function MultiTouchModule:OnTick(deltaTime)
  if _G.App:GetIsAppDeactivate() then
    local curTouchLimit = UE4.UNRCStatics.ModifyNRCGetTouchLimit()
    if curTouchLimit ~= self.data.disableTouchLimit then
      Log.Debug("ModifyNRCMultiTouchSetting==OnTick==correct the backgroundTouchCount!!!")
      self:OnSetMultiTouchLimit(self.data.disableTouchLimit)
    end
    self.data.revertTimer = 0
    return
  end
  self.data.revertTimer = self.data.revertTimer + deltaTime
  if self.data.revertTimer >= self.data.revertTime then
    local curTouchLimit = UE4.UNRCStatics.ModifyNRCGetTouchLimit()
    local isJoystickTouch = self:GetIsJoystickTouch()
    if isJoystickTouch then
      if curTouchLimit < self.data.joystickTouchLimit then
        Log.Debug("ModifyNRCMultiTouchSetting==OnTick==correct the joystickTouchCount!!!")
        self:OnSetMultiTouchLimit(self.data.joystickTouchLimit)
      end
    else
      local curPanelTouchCount = self:GetCurPanelTouchCount(true)
      if curTouchLimit ~= curPanelTouchCount then
        Log.Debug("ModifyNRCMultiTouchSetting==OnTick==correct the panelTouchCount!!!")
        self:OnSetMultiTouchLimit(curPanelTouchCount)
      end
    end
    self.data.revertTimer = 0
  end
end

function MultiTouchModule:OnCmdLockIsSelectBtn(moduleName, panelName, flag)
  local module = _G.NRCModuleManager:GetModule(moduleName)
  if module and module:HasPanel(panelName) then
    local panel = module:GetPanel(panelName)
    if panel then
      panel:SetIsSelectBtn(true, flag)
      
      local function callback()
        panel:SetIsSelectBtn(false, flag)
      end
      
      local name = panelName .. tostring(flag)
      if self.EventListener.Caller or self.EventListener.Callback then
        self.EventListener:TimesUp()
      end
      self.EventListener:StartGlobalEventListener(2, name, self, name, callback)
    end
  end
end

function MultiTouchModule:OnCmdGetIsSelectBtn(moduleName, panelName)
  local module = _G.NRCModuleManager:GetModule(moduleName)
  if module and module:HasPanel(panelName) then
    local panel = module:GetPanel(panelName)
    if panel then
      return panel:GetIsSelectBtn()
    end
  end
end

function MultiTouchModule:OnCmdSetIsOpenPetPanel(flag)
  self.data.isOpenPetPanel = flag
end

function MultiTouchModule:OnCmdGetIsOpenPetPanel()
  return self.data.isOpenPetPanel
end

function MultiTouchModule:OnCmdGetPanelSelectBtnReason(panelName)
  if not self.data.panelSelectBtnReason[panelName] then
    Log.Error("MultiTouchModule:OnCmdGetPanelSelectBtnReason==check panelName in panelSelectBtnReason!!!")
  end
  return self.data.panelSelectBtnReason[panelName]
end

function MultiTouchModule:OnCmdUnlockIsSelectBtn(moduleName, panelName, flag)
  local module = _G.NRCModuleManager:GetModule(moduleName)
  if module and module:HasPanel(panelName) then
    local panel = module:GetPanel(panelName)
    if panel then
      local name = panelName .. tostring(flag)
      _G.NRCEventCenter:DispatchEvent(name)
    end
  end
end

function MultiTouchModule:OnCmdGetSpecialSelectLimitReason(typeName)
  if not self.data.specialSelectLimit[typeName] then
    Log.Error("MultiTouchModule:OnCmdGetSpecialSelectLimit==check typeName in specialSelectLimit!!!")
    return
  end
  if not self.data.specialSelectLimit[typeName].reason then
    Log.Error("MultiTouchModule:OnCmdGetSpecialSelectLimit==check reason in specialSelectLimit!!!")
    return
  end
  return self.data.specialSelectLimit[typeName].reason
end

function MultiTouchModule:OnCmdIsSpecialSelectLimit(typeName)
  if not self.data.specialSelectLimit[typeName] then
    Log.Error("MultiTouchModule:OnCmdIsSpecialSelectLimit==check typeName in specialSelectLimit!!!")
    return
  end
  return 0 ~= self.data.specialSelectLimit[typeName].flag
end

function MultiTouchModule:OnCmdSetSpecialSelectLimit(typeName, reason, enable)
  if not self.data.specialSelectLimit[typeName] then
    Log.Error("MultiTouchModule:OnCmdSetSpecialSelectLimit==check typeName in specialSelectLimit!!!")
    return
  end
  local curFlag = self.data.specialSelectLimit[typeName].flag
  if enable then
    self.data.specialSelectLimit[typeName].flag = curFlag | 1 << reason
  else
    self.data.specialSelectLimit[typeName].flag = curFlag & ~(1 << reason)
  end
end

function MultiTouchModule:CheckIsThrowing()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
      return true
    elseif player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
      return true
    end
  end
  return false
end

function MultiTouchModule:OnCmdGetIsSelectBtnValue(moduleName, panelName)
  local module = _G.NRCModuleManager:GetModule(moduleName)
  if module and module:HasPanel(panelName) then
    local panel = module:GetPanel(panelName)
    if panel then
      return panel:GetIsSelectBtnValue()
    end
  end
end

function MultiTouchModule:OnCmdGetLockFlags(moduleName, panelName)
  local isLock = self:OnCmdGetIsSelectBtn(moduleName, panelName)
  if not isLock then
    return {}
  end
  if not self.data.panelSelectBtnReason[panelName] then
    return {}
  end
  local lock = self:OnCmdGetIsSelectBtnValue(moduleName, panelName)
  local locked = {}
  local maxFlagsList = self.data.panelSelectBtnReason[panelName]
  for _, flag in pairs(maxFlagsList) do
    if 0 ~= lock & 1 << flag then
      table.insert(locked, flag)
    end
  end
  return locked
end

return MultiTouchModule

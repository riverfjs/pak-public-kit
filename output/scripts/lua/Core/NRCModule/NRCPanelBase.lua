_G.EnvSystemModuleCmd = require("NewRoco.Modules.System.EnvSystem.EnvSystemModuleCmd")
local MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local NRCPanelBase = _G.NRCViewBase:Extend("NRCPanelBase")
NRCPanelBase.ClassType = "NRCPanelBase"

function NRCPanelBase:Construct()
  _G.NRCProfilerLog:NRCPanelConstruct(true, self.panelName)
  NRCViewBase.Construct(self)
  self.isActive = false
  self.AllWidgetConfDic = {}
  self:DoSetChildViewDataAndConstruct(self)
  _G.NRCProfilerLog:NRCPanelConstruct(false, self.panelName)
end

function NRCPanelBase:Destruct()
  NRCPanelManager:RemovePanelBlockIMC(self.panelData)
  _G.NRCProfilerLog:NRCPanelDestruct(true, self.panelName)
  NRCViewBase.Destruct(self)
  _G.NRCProfilerLog:NRCPanelDestruct(false, self.panelName)
  _G.NRCProfilerLog:NRCPanelProfilerLog(false, false, self.panelName)
end

function NRCPanelBase:SetPanelData(module, panelData)
  self.panelName = panelData.panelName
  self.viewName = panelData.panelName
  self.LogPrefix = string.format("[%s]", self.panelName)
  self.panelData = panelData
  self.enableLog = true
  self.module = module
  if not module.eventDispatcher then
    self:Log("SetPanelData fail")
  end
  self:SetEventDispatcher(module.eventDispatcher)
  self:Log("bind panel:", module.moduleName, self.panelName)
end

function NRCPanelBase:InitUmgStaticConf(umgStaticConf)
  if self.umgStaticConf == nil then
    Log.Debug("NRCPanelBase:InitUmgStaticConf fail", self.panelName)
    return
  end
  local widgetConfName = self.umgStaticConf.panel_widget_conf_name
  if widgetConfName then
    self.AllWidgetConf = _G.DataConfigManager:GetAllByName(widgetConfName)
    if self.AllWidgetConf then
      for k, v in pairs(self.AllWidgetConf) do
        if v.widget_name then
          self.AllWidgetConfDic[v.widget_name] = v
          local widget = self:GetWidgetByName(v.widget_name)
          if widget then
            if v.redpoint_id and 0 ~= v.redpoint_id then
              if widget.SetupKey then
                widget:SetupKey(v.redpoint_id)
              else
                Log.Warning("NRCPanelBase:InitUmgStaticConf widget is not NrcRedPoint_C ", v.widget_name, self.panelName, v.id)
              end
            end
            if v.btn_sound_id and 0 ~= v.btn_sound_id and widget.GetSoundID then
              local btnSound = widget:GetSoundID()
              if 0 == btnSound then
                if widget.SetSoundID then
                  widget:SetSoundID(v.btn_sound_id)
                else
                  Log.Warning("NRCPanelBase:InitUmgStaticConf widget is not UNRCButton", v.widget_name, self.panelName, v.id)
                end
              end
            end
            if v.mutex_group_name and v.mutex_group_name ~= "" then
              if widget.SetMutexGroup then
                widget:SetMutexGroup(v.mutex_group_name)
              else
                Log.Warning("NRCPanelBase:InitUmgStaticConf widget is not UNRCButton", v.widget_name, self.panelName, v.id)
              end
            end
          else
            Log.Warning("NRCPanelBase:InitUmgStaticConf wiget not found", v.widget_name, self.panel, v.id)
          end
        else
          Log.Warning("NRCPanelBase:InitUmgStaticConf widget_name is nil ", v.widget_name, self.panelName, v.id)
        end
      end
    else
      Log.Debug("NRCPanelBase:InitUmgStaticConf fail AllWidgetConf", widgetConfName, self.panelName)
    end
  end
end

function NRCPanelBase:GetWidgetByName(widgetName)
  if not widgetName or "" == widgetName then
    return nil
  end
  if not string.find(widgetName, ".", 1, true) then
    return self[widgetName]
  end
  local parts = string.split(widgetName, "%.")
  local current = self
  for i, part in ipairs(parts) do
    if nil == current then
      return nil
    end
    current = current[part]
  end
  return current
end

function NRCPanelBase:Active(...)
  local panelData = self.panelData
  if nil == panelData then
    Log.Error("panelData is nil?!")
    return
  end
  _G.NRCProfilerLog:NRCPanelActive(true, self.panelName)
  self.isActive = true
  self:OnActive(...)
  local openAnimName = panelData.openAnimName
  NRCPanelManager:RemovePanelBlockIMC(panelData)
  panelData.BlockTrigger = nil
  if openAnimName and self[openAnimName] then
    self:PlayAnimation(self[openAnimName])
  else
    if panelData.enableTouchMask then
      NRCModuleManager:DoCmd(MultiTouchModuleCmd.CloseBlockingMask)
    end
    if not self.hasCustomOpenAnim then
      self:SetPanelAlreadyVisible()
    end
  end
  _G.NRCProfilerLog:NRCPanelProfilerLog(true, false, self.panelName)
  _G.NRCProfilerLog:NRCPanelActive(false, self.panelName)
  if panelData.panelStaticConf then
    self.umgStaticConf = panelData.panelStaticConf
    self:RegisterStaticConf()
  end
end

function NRCPanelBase:RegisterStaticConf()
  local panelConf = self.umgStaticConf
  self:InitUmgStaticConf(panelConf)
  if panelConf.bgm_state_name then
    Log.Debug("NRCPanelBase:OnActive bgm_state_name", panelConf.bgm_state_name, self.panelName)
    _G.NRCAudioManager:SetStateByName("UI_Music", panelConf.bgm_state_name)
  end
  if panelConf.bgm_state_ui_type then
    Log.Debug("NRCPanelBase:OnActive bgm_state_ui_type", panelConf.bgm_state_ui_type, self.panelName)
    _G.NRCAudioManager:SetStateByName("UI_Type", panelConf.bgm_state_ui_type)
  end
  if panelConf.open_effect then
    Log.Debug("NRCPanelBase:OnActive playanim", panelConf.open_effect, self.panelName)
    local Anim = self[panelConf.open_effect]
    self:PlayAnimation(Anim)
  end
  if panelConf.open_soundid then
    Log.Debug("NRCPanelBase:OnActive play sound", panelConf.open_soundid, self.panelName)
    local Tag = self.panelName .. ":OnActive"
    _G.NRCAudioManager:PlaySound2DAuto(panelConf.open_soundid, Tag)
  end
end

function NRCPanelBase:OnAddDynamicIMC()
  NRCPanelManager:TryInsertImcManual(self.panelData)
end

function NRCPanelBase:OnRemoveDynamicIMC()
  NRCPanelManager:TryRemoveImcManual(self.panelData)
end

function NRCPanelBase:OnActive(...)
  self:Log("OnActive:", ...)
end

function NRCPanelBase:IsActive()
  return self.isActive
end

function NRCPanelBase:Deactive()
  Log.Debug("NRCPanelBase:Deactive")
  if self.panelData and self.panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN and 0 == _G.NRCPanelManager:GetEnabledWindowCount(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN) and self:CheckCanOpenLobbyMain() then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  end
  self:SetPanelReadyToClosed()
  self.panelData = nil
  self:OnDeactive()
end

function NRCPanelBase:OnDeactive()
end

function NRCPanelBase:TryEnable(reason)
  local module = self.module
  if module and module:SetPanelEnable(self.panelName, true, reason) then
    self:Enable()
  end
end

function NRCPanelBase:Enable()
  self:PreEnable()
  local panelName = self.panelName
  local module = self.module
  if module then
    module:SetPanelEnable(panelName, true, NRCPanelEnum.PanelDisableReason.None)
  else
    Log.Debug("NRCPanelBase have no module:", panelName)
  end
  NRCViewBase.Enable(self)
  self:ChangeWorldRendering(false)
  self:EnableWorldListenerVolume(false, panelName)
end

function NRCPanelBase:Disable(reason)
  NRCViewBase.Disable(self)
  self:ChangeWorldRendering(true)
  local panelName = self.panelName
  local module = self.module
  if module then
    if self.isActive then
      module:SetPanelEnable(panelName, false, reason)
    end
  else
    Log.Debug("NRCPanelBase have no module:", panelName)
  end
  self:EnableWorldListenerVolume(true, panelName)
  self:PostDisable()
end

function NRCPanelBase:PreEnable()
  if not self.panelData then
    Log.Debug("NRCPanelBase PreEnable paneldata is nil:", self.panelName)
    return
  end
  if self.panelData then
    local bAutoSetDesiredCursor = self.panelData.enablePcEsc
    if self.panelData.autoSetDesiredCursor ~= nil then
      bAutoSetDesiredCursor = self.panelData.autoSetDesiredCursor
    end
    if bAutoSetDesiredCursor then
      UE4Helper.SetDesiredShowCursor(true, self.panelData.panelName)
    end
  end
end

function NRCPanelBase:PostDisable()
  if self.panelData then
    local bAutoSetDesiredCursor = self.panelData.enablePcEsc
    if self.panelData.autoSetDesiredCursor ~= nil then
      bAutoSetDesiredCursor = self.panelData.autoSetDesiredCursor
    end
    if bAutoSetDesiredCursor then
      UE4Helper.ReleaseDesiredShowCursor(self.panelData.panelName)
    end
  end
end

function NRCPanelBase:IsNeedCache()
  return self.panelData.panelCacheType == NRCPanelRegisterData.PanelCacheType.PreCache or self.panelData.panelCacheType == NRCPanelRegisterData.PanelCacheType.LoadAndCache
end

function NRCPanelBase:OnFoldCollapsed()
end

function NRCPanelBase:OnUnDoFoldCollapsed()
end

function NRCPanelBase:OnDepthChanged(depth)
  self:SetAllInputMappingContextPriority(depth)
  _G.NRCPanelManager:UpdatePanelTriggerPriority(self.panelName, depth)
end

function NRCPanelBase:OnBringToFront(...)
end

function NRCPanelBase:OnSendToBack(...)
end

function NRCPanelBase:BindCloseBtn(btn)
  btn = btn and btn.btnClose or btn or self.CloseBtn
  self:AddButtonListener(btn, self.DoClose)
end

function NRCPanelBase:OnClose()
  if self.panelData then
    if self[self.panelData.closeAnimName] then
      if self.isPanelClosing then
        return
      end
      self.isPanelClosing = true
      if self[self.panelData.openAnimName] then
        self:StopAnimation(self[self.panelData.openAnimName])
      end
      self:PlayAnimation(self[self.panelData.closeAnimName])
      self:SetPanelReadyToClosed()
    else
      self:DoClose()
    end
  else
    self:DoClose()
  end
end

function NRCPanelBase:DoClose()
  if self.panelData then
    local panelConf = self.umgStaticConf
    if panelConf and panelConf.close_effect then
      Log.Debug("NRCPanelBase:DoClose playanim", panelConf.close_effect, self.panelName)
      local Anim = self[panelConf.close_effect]
      self:PlayAnimation(Anim)
    end
    if self:IsNeedCache() then
      self:Log("NRCPanelBase:DoClose:")
      self:Disable()
    else
      self:DelayClose()
    end
  else
    Log.Error("NRCPanelBase:DoClose self.panelData is nil")
  end
end

function NRCPanelBase:DelayClose()
  self:StopAllAnimations()
  if self.module then
    self.module:ClosePanel(self.panelName)
  else
    Log.Error("NRCPanelBase:DelayClose module lost")
  end
end

function NRCPanelBase:OnAnimationStarted(Anim)
  if self.panelData == nil then
    return
  end
  if self.OnAnimStarted then
    self:OnAnimStarted(Anim)
  end
  if self.panelData.openAnimName and Anim == self[self.panelData.openAnimName] or self.panelData.closeAnimName and Anim == self[self.panelData.closeAnimName] then
    self:PauseAllButtonListener()
    if Anim == self[self.panelData.openAnimName] then
    elseif Anim == self[self.panelData.closeAnimName] then
    end
  end
end

function NRCPanelBase:OnAnimationFinished(Anim)
  if self.panelData == nil then
    return
  end
  if self.OnAnimFinished then
    self:OnAnimFinished(Anim)
  end
  if self.panelData.openAnimName and Anim == self[self.panelData.openAnimName] or self.panelData.closeAnimName and Anim == self[self.panelData.closeAnimName] then
    self:RecoverAllButtonListener()
    if Anim == self[self.panelData.openAnimName] then
      if self.panelData.enableTouchMask then
        NRCModuleManager:DoCmd(MultiTouchModuleCmd.CloseBlockingMask)
      end
      if not self.isPanelClosing then
        self:SetPanelAlreadyVisible()
      end
    elseif Anim == self[self.panelData.closeAnimName] and self.DoClose then
      self:DoClose()
    end
  end
end

function NRCPanelBase:CheckCanOpenLobbyMain()
  local bHasCompass = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.HasCompass) or false
  local bInBattle = _G.BattleManager.isInBattle or false
  local bInDialogue = _G.NRCModuleManager:DoCmd(DialogueModuleCmd.HasDialogue) or false
  local bCheckHasDisableMainPopUp = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CheckHasDisableMainPopUp) or false
  Log.Debug("CheckCanOpenLobbyMain", bHasCompass, bInBattle, bInDialogue, bCheckHasDisableMainPopUp)
  if bHasCompass or bInBattle or bInDialogue or bCheckHasDisableMainPopUp then
    return false
  else
    return true
  end
end

function NRCPanelBase:GetPanelName()
  return self.panelData.panelName
end

function NRCPanelBase:GetEnablePcEsc()
  return self.panelData and self.panelData.enablePcEsc
end

function NRCPanelBase:SetPanelHasCustomOpenAnim()
  self.hasCustomOpenAnim = true
end

function NRCPanelBase:SetPanelAlreadyVisible()
  local panelData = self.panelData
  if panelData and panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:SetPanelAlreadyVisible(panelData.panelName, self)
    end
    self:ChangeWorldRendering(false)
    self:EnableWorldListenerVolume(false, panelData.panelName)
  end
end

function NRCPanelBase:SetPanelReadyToClosed()
  local panelData = self.panelData
  if panelData and panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      layerCtrl:SetPanelReadyToClosed(panelData.panelName)
    end
    self:ChangeWorldRendering(true)
    self:EnableWorldListenerVolume(true, panelData.panelName)
  end
end

function NRCPanelBase:ChangeWorldRendering(enable)
  local panelData = self.panelData
  if panelData and panelData:IsDesiredDisableWorldRendering() then
    if not enable then
      if self.enableView then
        UE4Helper.SetEnableWorldRendering(false, true, panelData.panelName)
      end
    else
      UE4Helper.SetEnableWorldRendering(nil, nil, panelData.panelName)
    end
  end
end

function NRCPanelBase:EnableWorldListenerVolume(enable)
  local panelData = self.panelData
  if panelData and panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
    _G.NRCPanelManager:SetEnableWorldListenerVolume(enable, panelData.panelName)
  end
end

function NRCPanelBase:Log(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogDebug, 4, self.LogPrefix, ...)
  end
end

function NRCPanelBase:LogWarning(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogWarn, 3, self.LogPrefix, ...)
  end
end

function NRCPanelBase:LogTrace(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogTrace, 3, self.LogPrefix, ...)
  end
end

function NRCPanelBase:LogError(...)
  if self.enableLog then
    Log.LogWithLevel(Log.LOG_LEVEL.ELogError, 3, self.LogPrefix, ...)
  end
end

function NRCPanelBase:SetIsSelectBtn(enable, flag)
  if not flag then
    return
  end
  if not self.panelData then
    return
  end
  if enable then
    self.panelData.isSelectBtn = self.panelData.isSelectBtn | 1 << flag
  else
    self.panelData.isSelectBtn = self.panelData.isSelectBtn & ~(1 << flag)
  end
end

function NRCPanelBase:GetIsSelectBtn()
  if not self.panelData then
    return false
  end
  return 0 ~= self.panelData.isSelectBtn
end

function NRCPanelBase:RevertIsSelectBtn()
  self.panelData.isSelectBtn = 0
end

function NRCPanelBase:GetIsSelectBtnValue()
  return self.panelData.isSelectBtn
end

function NRCPanelBase:OnPcClose()
  if not self:IsVisible() then
    Log.Debug("[IMC] panel is invisible, return", self.panelName)
    return
  end
  local HandlerExpected = self.OnPcCloseHandler
  if not HandlerExpected and self.viewbuttonEventDict then
    for btn, handler in pairs(self.viewbuttonEventDict) do
      if btn:GetName() == "btnCloseRenamePanel" then
        if not btn:IsVisible() then
          Log.Debug("[IMC] close btn is invisible, return")
          return
        end
        HandlerExpected = handler
        Log.Debug("[IMC] OnPcClose, using btnCloseRenamePanel", btn, "as exit trigger handler")
        break
      elseif btn:GetName() == "btnClose" then
        local OwningUserWidget = btn:GetOuter():GetOuter()
        if OwningUserWidget and not OwningUserWidget:IsVisible() then
          Log.Debug("[IMC] close btn is invisible, return")
          return
        end
        HandlerExpected = handler
        Log.Debug("[IMC] OnPcClose, using btnClose", btn, "as exit trigger handler")
        break
      end
    end
    local CloseBtn = self.CloseBtn or self.BtnClose or self.Btn_Close or self.btnCloseTips or self.Btn_GlobalClose or self.HotArea or self.CloseBtn1
    if not HandlerExpected and CloseBtn then
      if not CloseBtn:IsVisible() then
        Log.Debug("[IMC] close btn is invisible, return")
        return
      end
      if CloseBtn.OnClicked then
        CloseBtn.OnClicked:Broadcast()
        Log.Debug("[IMC] OnPcClose, using CloseBtn", CloseBtn, "as exit trigger handler")
        return
      end
    end
  end
  if HandlerExpected then
    HandlerExpected(self)
  elseif not RocoEnv.IS_SHIPPING and NRCModuleManager and TipsModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\227\128\144PC\230\181\139\232\175\149\230\143\144\231\164\186\227\128\145\229\189\147\229\137\141\231\149\140\233\157\162\230\178\161\230\156\137ESC\232\131\189\229\138\155\229\174\158\231\142\176\239\188\140\230\136\170\229\155\190\230\143\144\229\141\149\239\188\154" .. self.panelName)
  end
end

function NRCPanelBase:OnPcCloseByKeyDirectly()
end

function NRCPanelBase:OnBeginGuideTarget(config)
end

function NRCPanelBase:OnEndGuideTarget(config)
end

function NRCPanelBase:GetGuidanceCustomPanelType()
  return nil
end

return NRCPanelBase

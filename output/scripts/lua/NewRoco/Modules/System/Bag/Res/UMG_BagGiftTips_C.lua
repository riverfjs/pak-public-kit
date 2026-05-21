local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_BagGiftTips_C = _G.NRCPanelBase:Extend("UMG_BagGiftTips_C")

function UMG_BagGiftTips_C:OnConstruct()
  self:OnAddEventListener()
  self:PCKeySetting()
  self.text:SetText(LuaText.get_gift_text02)
  self.text_1:SetText("")
  self.RichText:SetText(LuaText.get_gift_text03)
end

function UMG_BagGiftTips_C:OnActive(tipsControllerModule)
  Log.Info("umg baggifttips active")
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local curModule = tipsControllerModule
  self.tipsDisplayController = curModule and curModule.getUniversalTipsController
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  else
    Log.Warning("module getUniversalTipsController is nil ")
  end
  local mappingContext = self:AddInputMappingContext("IMC_LobbyMessageDetails")
  if mappingContext then
    mappingContext:BindAction("IA_MessageDetails")
  end
end

function UMG_BagGiftTips_C:OnPlayTips(tip)
  if nil == tip then
    Log.Warning("tips is nil")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008001, "UMG_BagGiftTips_C:OnActive")
  local tipData = tip.customData
  self.currentTipData = tipData
  Log.Debug(tipData, "UMG_BagGiftTips_C:OnPlayTips")
  if tipData.iconPath and tipData.iconPath ~= "" then
    self.TeachIcon:SetPath(tipData.iconPath)
  else
    self.TeachIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if tipData.title and "" ~= tipData.title then
    self.text:SetText(tipData.title)
  else
    self.text:SetText("")
  end
  if tipData.subtitle and "" ~= tipData.subtitle then
    self.RichText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RichText:SetText(tipData.subtitle)
  else
    self.RichText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PlayAnimation(self.Appear)
  self.ShowTime = tip.timeLeft
  local countdownText = tipData.countdownText or "(%ds)"
  self.text_1:SetText(string.format(countdownText, self.ShowTime))
  if self.tipsDisplayController and self.tipsDisplayController:GetExecutor():IsPaused() then
    Log.Debug("UniversalTipsDisplayExecutorIsPause")
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BagGiftTips_C:OnAllTipsFinished()
  self:ClosePanel()
end

function UMG_BagGiftTips_C:ClosePanel()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:PlayAnimation(self.Disappear)
end

function UMG_BagGiftTips_C:OnPlayTipStatusChange(pause)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if pause then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    if self:IsAnimationPlaying(self.Disappear) then
      self.IsClose = true
      self:DoClose()
      return
    end
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BagGiftTips_C:OnUpdateTips(tip, interval)
  if tip and tip.timeLeft and self.currentTipData then
    self.ShowTime = tip.timeLeft
    local countdownText = self.currentTipData.countdownText or _G.LuaText.BagGiftTips_Cd
    self.text_1:SetText(string.format(countdownText, self.ShowTime))
  end
end

function UMG_BagGiftTips_C:PCKeySetting()
  if SystemSettingModuleCmd then
    local InputAction = string.format("IA_MessageDetails")
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, InputAction)
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey:SetKeyVisibility(true)
  end
end

function UMG_BagGiftTips_C:OnDeactive()
  self:RemoveInputMappingContext("IMC_LobbyMessageDetails")
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
  end
end

function UMG_BagGiftTips_C:OnAnimationFinished(anim)
  if anim == self.Disappear and not self.IsClose then
    self:DoClose()
  end
end

function UMG_BagGiftTips_C:OnAddEventListener()
  self:AddButtonListener(self.TipsBtn, self.OpenPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_BagGiftTips_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_BagGiftTips_C:OpenPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_BagGiftTips_C:OpenPanel")
  if self.tipsDisplayController then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    if tip and self.currentTipData then
      self:ExecuteAction(self.currentTipData)
    end
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  else
    self:DoClose()
  end
end

function UMG_BagGiftTips_C:ExecuteAction(tipData)
  local actionType = tipData.actionType or "none"
  local actionData = tipData.actionData or {}
  if "panel" == actionType then
    local moduleName = actionData.module
    local panelName = actionData.panel
    local params = actionData.params
    if moduleName and panelName then
      local moduleCmd = _G[moduleName .. "Cmd"]
      if moduleCmd and moduleCmd.OpenPanel then
        _G.NRCModuleManager:DoCmd(moduleCmd.OpenPanel, panelName, params)
      else
        Log.Warning(string.format("Module command not found: %s", moduleName .. "Cmd"))
      end
    end
  elseif "command" == actionType then
    local moduleName = actionData.module
    local command = actionData.command
    local params = actionData.params or {}
    if moduleName and command then
      local moduleCmd = _G[moduleName .. "Cmd"]
      if moduleCmd and moduleCmd[command] then
        _G.NRCModuleManager:DoCmd(moduleCmd[command], table.unpack(params))
      else
        Log.Warning(string.format("Command not found: %s.%s", moduleName .. "Cmd", command))
      end
    end
  elseif "callback" == actionType then
    local callback = actionData.callback
    if callback and type(callback) == "function" then
      local success, error = pcall(callback, tipData, actionData.params)
      if not success then
        Log.Error("Tips callback error: " .. tostring(error))
      end
    end
  elseif "module_method" == actionType then
    local moduleName = actionData.module
    local methodName = actionData.method
    local params = actionData.params or {}
    if moduleName and methodName then
      local module = _G.NRCModuleManager:GetModule(moduleName)
      if module and module[methodName] then
        local success, error = pcall(module[methodName], module, table.unpack(params))
        if not success then
          Log.Error(string.format("Module method error: %s.%s - %s", moduleName, methodName, tostring(error)))
        end
      else
        Log.Warning(string.format("Module method not found: %s.%s", moduleName, methodName))
      end
    end
  elseif "url" == actionType then
    local url = actionData.url
    if url then
      Log.Info("Open URL: " .. url)
    end
  else
    Log.Debug("No action or unknown action type: " .. tostring(actionType))
  end
end

function UMG_BagGiftTips_C:HasValidData()
  if self.tipsDisplayController then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    return nil ~= tip
  end
  return false
end

return UMG_BagGiftTips_C

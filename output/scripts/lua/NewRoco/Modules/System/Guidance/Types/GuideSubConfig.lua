local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local GuideSubConfig = NRCClass:Extend("GuideSubConfig")

function GuideSubConfig.InitFromDataConfig(config)
  if not config then
    return nil
  end
  local subConfig = GuideSubConfig()
  subConfig.unique_id = config.id
  subConfig.sub_guide_id = config.sub_guide_id
  subConfig.cond_type = GuideConfigTypes.StringToConditionOperator(config.cond_type)
  subConfig.reconnect = config.reconnect
  subConfig.reset_step = config.reset_step
  
  local function addCondition(type, param1, param2)
    local condition = GuideConfigTypes.GetGuideConditionConfig(type, param1, param2)
    if not condition then
      return
    end
    if subConfig.triggers == nil then
      subConfig.triggers = {}
    end
    table.insert(subConfig.triggers, condition)
  end
  
  addCondition(config.type1, config.type1_data_1, config.type1_data_2)
  addCondition(config.type2, config.type2_data_1, config.type2_data_2)
  subConfig.res_scene_id = config.res_scene_id
  subConfig.completion_type = GuideConfigTypes.StringToConditionOperator(config.cond_type_done)
  subConfig.completion = GuideConfigTypes.GetGuideConditionConfig(config.done_type, config.done_type_data1, config.done_type_data2)
  subConfig.completion2 = GuideConfigTypes.GetGuideConditionConfig(config.done_type2, config.done_type2_data1, config.done_type2_data2)
  if subConfig.completion.type == GuideConfigTypes.ConditionType.Button then
    local conf = _G.DataConfigManager:GetGuideButtonConf(subConfig.completion.param1, true)
    if conf and conf.watch_ia_names then
      subConfig.watchedIaNames = conf.watch_ia_names
    end
  end
  subConfig.styleConfig = {
    delay_time = config.delay_time,
    finish_button_showtime = config.finish_button_showtime,
    finish_overtime = config.finish_overtime,
    strong_guide = config.strong_guide,
    transparence = config.transparence,
    style_type = GuideConfigTypes.StringToGuideStyleType(config.style_type),
    type_id = config.type_id
  }
  subConfig.funcBanId = config.func_ban_id
  if config.setting_type and config.setting_data and #config.setting_data > 0 then
    subConfig.isMutex = true
    subConfig.settingMask = false
    subConfig.settingMode = {
      type = 1 or config.setting_type,
      data = config.setting_data
    }
  end
  subConfig:Reset()
  if config.active_ia_watch and #config.active_ia_watch > 0 then
    subConfig.iaWatchConfigs = {}
    for _, id in pairs(config.active_ia_watch) do
      local iaConfig = _G.DataConfigManager:GetGuideIaConf(id, true)
      if iaConfig then
        local ia = {
          id = id,
          iaName = iaConfig.ia_name,
          cmd = iaConfig.ia_command
        }
        table.insert(subConfig.iaWatchConfigs, ia)
      end
    end
  end
  return subConfig
end

function GuideSubConfig:CheckCondition(type, param1, param2)
  if self.state ~= GuideConfigTypes.SubConfigState.Activated then
    return false
  end
  if type == GuideConfigTypes.ConditionType.GuideSetting then
    if self:ShouldResponseGuideSettingChanged() then
      return self:CheckGuideSettingMode(param1, param2)
    end
    return false
  end
  if not self.triggers then
    return true
  end
  if 0 == #self.triggers then
    return true
  end
  for idx, trig in pairs(self.triggers) do
    if 1 == self.conditionMask & 1 << idx - 1 then
    elseif not self:CheckConditionSatisfied(trig, type, param1, param2) then
    else
      self.conditionMask = self.conditionMask | 1 << idx - 1
      if self:CheckCanTrig() then
        return true
      end
    end
  end
  return false
end

function GuideSubConfig:CheckCanTrig()
  if self.state ~= GuideConfigTypes.SubConfigState.Activated then
    return false
  end
  if self.cond_type == GuideConfigTypes.ConditionOperator.Or then
    if self.conditionMask > 0 then
      self.state = GuideConfigTypes.SubConfigState.Pending
      return true
    end
  elseif self.cond_type == GuideConfigTypes.ConditionOperator.And then
    if self.triggers then
      if self.conditionMask == (1 << #self.triggers) - 1 then
        self.state = GuideConfigTypes.SubConfigState.Pending
        return true
      end
    else
      return true
    end
  end
  return false
end

function GuideSubConfig:BecomeTriggered()
  if self.state ~= GuideConfigTypes.SubConfigState.Pending then
    Log.Debug("GuideSubConfig:BecomeTriggered not pending", self.unique_id, self.group_id, self.sub_guide_id)
    return false
  end
  if self.state == GuideConfigTypes.SubConfigState.Triggered then
    Log.Debug("GuideSubConfig:BecomeTriggered already triggered", self.unique_id, self.group_id, self.sub_guide_id)
    return false
  end
  Log.Debug("GuideSubConfig:BecomeTriggered", self.unique_id, self.group_id, self.sub_guide_id)
  self.state = GuideConfigTypes.SubConfigState.Triggered
  if self.styleConfig.finish_overtime > 0 then
    self.delayFuncId = _G.DelayManager:DelaySeconds(self.styleConfig.finish_overtime / 1000.0, function()
      if not self then
        return
      end
      self.delayFuncId = nil
      if self.state ~= GuideConfigTypes.SubConfigState.Triggered then
        return
      end
      Log.Debug("GuideSubConfig:BecomeTriggered reach finish_overtime", self.unique_id, self.group_id, self.sub_guide_id, self.styleConfig.finish_overtime)
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideSkip, self)
    end)
  end
  return true
end

function GuideSubConfig:AfterTriggerDelayFinish()
  self:TryWatchTargetButtonClick(self.completion)
  self:TryWatchTargetButtonClick(self.completion2)
end

function GuideSubConfig:CheckCompletion(type, param1, param2)
  if not self.state == GuideConfigTypes.SubConfigState.Triggered then
    return false
  end
  local cond1Completed = self:CheckConditionSatisfied(self.completion, type, param1, param2)
  local cond2Completed = self:CheckConditionSatisfied(self.completion2, type, param1, param2)
  if self.completion_type == GuideConfigTypes.ConditionOperator.And then
    return cond1Completed and cond2Completed
  else
    return cond1Completed or cond2Completed
  end
  return false
end

function GuideSubConfig:CheckParam1(condition, param1)
  if not condition then
    return false
  end
  if condition.type == GuideConfigTypes.ConditionType.Panel then
    local realParam1 = param1
    if type(param1) ~= "number" then
      realParam1 = GuideConfigTypes.GetWidgetNameFromPanelData(param1)
    end
    if realParam1 == condition.param1 then
      return true
    end
    local panelConf = _G.DataConfigManager:GetGuidePanelConf(condition.param1)
    if not panelConf then
      return false
    end
    return panelConf.panel_name == realParam1
  else
    return condition.param1 == param1
  end
  return false
end

function GuideSubConfig:CheckConditionSatisfied(condition, condType, param1, param2)
  if not condition then
    return false
  end
  if condition.type == GuideConfigTypes.ConditionType.InValid then
    return false
  end
  if condition.type ~= condType then
    return false
  end
  if not self:CheckParam1(condition, param1) then
    return false
  end
  if condition.type == GuideConfigTypes.ConditionType.Panel and type(param1) ~= "number" then
    local panel = _G.NRCPanelManager:GetPanel(param1.moduleName, param1.panelName)
    if not self:CheckPanelCustomMatch(panel, condition) then
      return false
    end
  end
  if condition.param2 ~= param2 then
    return false
  end
  return true
end

function GuideSubConfig:CheckPanelCustomMatch(panel, condition)
  if condition.param1Custom and panel and panel.GetGuidanceCustomPanelType then
    local customPanelType = panel:GetGuidanceCustomPanelType()
    if customPanelType ~= condition.param1Custom then
      Log.Debug("GuideSubConfig:CheckPanelCustomMatch panel custom type not match", condition.param1Custom, customPanelType)
      return false
    end
  end
  return true
end

function GuideSubConfig:CheckTriggerSatisfied()
  return self:CheckSceneSatisfied() and self:GetSettingModeSatisfied()
end

function GuideSubConfig:CheckSceneSatisfied()
  if not self.res_scene_id then
    return true
  end
  if 0 == #self.res_scene_id then
    return true
  end
  if 1 == #self.res_scene_id and 0 == self.res_scene_id[1] then
    return true
  end
  local sceneResId = _G.NRCModuleManager:DoCmd(SceneModuleCmd.GetCurrentMapResId)
  if not sceneResId then
    return false
  end
  return table.contains(self.res_scene_id, sceneResId)
end

function GuideSubConfig:CheckGuideSettingMode(param1, param2)
  if self.settingMode == nil then
    return true
  end
  if self.settingMode.type == param1 and table.contains(self.settingMode.data, param2) then
    self.settingMask = true
    return true
  end
  self.settingMask = false
  return false
end

function GuideSubConfig:ShouldResponseGuideSettingChanged()
  if self.settingMode == nil then
    return false
  end
  return true
end

function GuideSubConfig:GetSettingModeSatisfied()
  if self.settingMode == nil then
    return true
  end
  return self.settingMask
end

function GuideSubConfig:GetIsMutex()
  return self.isMutex
end

function GuideSubConfig:OnCompleted()
  if self.state == GuideConfigTypes.SubConfigState.Completed then
    return
  end
  Log.Debug("GuideSubConfig:OnCompleted", self.unique_id, self.group_id, self.sub_guide_id)
  self.state = GuideConfigTypes.SubConfigState.Completed
  self:ClearWatch()
  _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.RemoveFunctionBan, self)
end

function GuideSubConfig:TryWatchTargetButtonClick(completion)
  if not completion then
    return
  end
  if completion.type ~= GuideConfigTypes.ConditionType.Button then
    return
  end
  local conf = _G.DataConfigManager:GetGuideButtonConf(completion.param1)
  if not conf then
    return
  end
  local targetButton = GuideConfigTypes.GetTargetWidget(conf.ui_path, conf.ui_button_name)
  self:DoWatchTargetButtonClick(completion, targetButton)
end

function GuideSubConfig:DoWatchTargetButtonClick(completion, targetButton)
  if not targetButton then
    Log.Debug("GuideSubConfig:DoWatchTargetButtonClick: targetButton is nil", completion.param1)
    return
  end
  completion.watchedWidget = targetButton
  Log.Debug("GuideSubConfig:DoWatchTargetButtonClick: targetButton", self:GetDebugInfo(), UE4.UKismetSystemLibrary.GetDisplayName(targetButton), completion.param1, completion.param2)
  
  local function callbackNoReply()
    Log.Debug("GuideSubConfig:DoWatchTargetButtonClick: callbackNoReply", self.unique_id, self.group_id, self.sub_guide_id, completion.type, completion.param1)
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideTargetClicked, self)
  end
  
  local function callbackReply()
    Log.Debug("GuideSubConfig:DoWatchTargetButtonClick: callbackReply", self.unique_id, self.group_id, self.sub_guide_id, completion.type, completion.param1)
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideTargetClicked, self)
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  
  if completion.param2 == Enum.GuideActionType.GAT_CLICK then
    if targetButton.OnClicked then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnClicked:Add(targetButton, completion.watchedClickCallback)
    elseif targetButton.OnClickedEvent then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnClickedEvent:Add(targetButton, completion.watchedClickCallback)
    elseif targetButton.OnMouseButtonDownEvent then
      completion.watchedClickCallback = callbackReply
      targetButton.OnMouseButtonDownEvent:Bind(targetButton, completion.watchedClickCallback)
    end
  elseif completion.param2 == Enum.GuideActionType.GAT_LONGPRESS then
    if targetButton.OnGuidanceLongPress then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnGuidanceLongPress:Add(targetButton, completion.watchedClickCallback)
    end
  elseif completion.param2 == Enum.GuideActionType.GAT_RELEASED then
    if targetButton.OnGuidanceReleased then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnGuidanceReleased:Add(targetButton, completion.watchedClickCallback)
    end
  elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_UP then
    if targetButton.OnGuidanceScrollUp then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnGuidanceScrollUp:Add(targetButton, completion.watchedClickCallback)
    end
  elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_DOWN then
    if targetButton.OnGuidanceScrollDown then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnGuidanceScrollDown:Add(targetButton, completion.watchedClickCallback)
    end
  elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_LEFT then
    if targetButton.OnGuidanceScrollLeft then
      completion.watchedClickCallback = callbackNoReply
      targetButton.OnGuidanceScrollLeft:Add(targetButton, completion.watchedClickCallback)
    end
  elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_RIGHT and targetButton.OnGuidanceScrollRight then
    completion.watchedClickCallback = callbackNoReply
    targetButton.OnGuidanceScrollRight:Add(targetButton, completion.watchedClickCallback)
  end
end

function GuideSubConfig:Reset()
  self.state = GuideConfigTypes.SubConfigState.Activated
  self.conditionMask = 0
  self:ClearWatch()
  _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.RemoveFunctionBan, self)
  self:ResetIaWatchConfigs()
end

function GuideSubConfig:ClearWatch()
  if self.delayFuncId then
    _G.DelayManager:CancelDelayById(self.delayFuncId)
    self.delayFuncId = nil
  end
  self:ClearButtonWatch(self.completion)
  self:ClearButtonWatch(self.completion2)
end

function GuideSubConfig:ClearButtonWatch(completion)
  if not completion then
    return
  end
  local watchedWidget = completion.watchedWidget
  if watchedWidget and UE4.UObject.IsValid(watchedWidget) and completion.watchedClickCallback then
    if completion.param2 == Enum.GuideActionType.GAT_CLICK then
      if watchedWidget.OnClicked then
        watchedWidget.OnClicked:Remove(watchedWidget, completion.watchedClickCallback)
      elseif watchedWidget.OnClickedEvent then
        watchedWidget.OnClickedEvent:Remove(watchedWidget, completion.watchedClickCallback)
      elseif watchedWidget.OnMouseButtonDownEvent then
        watchedWidget.OnMouseButtonDownEvent:Unbind()
      end
    elseif completion.param2 == Enum.GuideActionType.GAT_LONGPRESS then
      if watchedWidget.OnGuidanceLongPress then
        watchedWidget.OnGuidanceLongPress:Remove(watchedWidget, completion.watchedClickCallback)
      end
    elseif completion.param2 == Enum.GuideActionType.GAT_RELEASED then
      if watchedWidget.OnGuidanceReleased then
        watchedWidget.OnGuidanceReleased:Remove(watchedWidget, completion.watchedClickCallback)
      end
    elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_UP then
      if watchedWidget.OnGuidanceScrollUp then
        watchedWidget.OnGuidanceScrollUp:Remove(watchedWidget, completion.watchedClickCallback)
      end
    elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_DOWN then
      if watchedWidget.OnGuidanceScrollDown then
        watchedWidget.OnGuidanceScrollDown:Remove(watchedWidget, completion.watchedClickCallback)
      end
    elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_LEFT then
      if watchedWidget.OnGuidanceScrollLeft then
        watchedWidget.OnGuidanceScrollLeft:Remove(watchedWidget, completion.watchedClickCallback)
      end
    elseif completion.param2 == Enum.GuideActionType.GAT_SCROLL_RIGHT and watchedWidget.OnGuidanceScrollRight then
      watchedWidget.OnGuidanceScrollRight:Remove(watchedWidget, completion.watchedClickCallback)
    end
    completion.watchedWidget = nil
    completion.watchedClickCallback = nil
  end
end

function GuideSubConfig:SwitchFunctionBan(bAdd)
  if not self.funcBanId or 0 == self.funcBanId then
    self.bHasFunctionBan = bAdd
    return false
  end
  if bAdd then
    if not self.bHasFunctionBan then
      Log.Debug("GuideSubConfig:SwitchFunctionBan add", self.unique_id, self.funcBanId)
      _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, self.funcBanId)
      self.bHasFunctionBan = true
      if self.styleConfig.strong_guide then
        _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnInVisible)
      end
      return true
    end
  elseif self.bHasFunctionBan then
    Log.Debug("GuideSubConfig:SwitchFunctionBan remove", self.unique_id, self.funcBanId)
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, self.funcBanId)
    self.bHasFunctionBan = false
    return true
  end
  return false
end

function GuideSubConfig:GetReconnectStep()
  if not self.reconnect then
    if self.state == GuideConfigTypes.SubConfigState.Triggered then
      return -1
    end
    return nil
  end
  if not self.reset_step then
    if self.state == GuideConfigTypes.SubConfigState.Triggered then
      return -1
    end
    return nil
  end
  if self.reset_step > self.sub_guide_id then
    return nil
  end
  return self.reset_step
end

function GuideSubConfig:TryMatchIAInput(actionName, keyName, inputEvent)
  if not self.bHasFunctionBan then
    return
  end
  self:TryMatchActiveIA(keyName)
  self:TryMatchButtonAndIA(keyName)
end

function GuideSubConfig:TryMatchActiveIA(keyName)
  if not self.styleConfig then
    return
  end
  if not self.styleConfig.strong_guide then
    return
  end
  if not self.iaWatchConfigs then
    return
  end
  for _, iaConfig in ipairs(self.iaWatchConfigs) do
    if not iaConfig then
    elseif iaConfig.hasTriggered then
    else
      local iaName = iaConfig.iaName
      if self:JudgeIAMatch(iaName, keyName) then
        self:OnIAInputMatched(iaConfig)
        break
      end
    end
  end
end

function GuideSubConfig:TryMatchButtonAndIA(keyName)
  if not self.watchedIaNames then
    return
  end
  for _, iaName in pairs(self.watchedIaNames) do
    if self:JudgeIAMatch(iaName, keyName) then
      Log.Debug("GuideSubConfig:TryMatchButtonAndIA: target ia matched", self.unique_id, self.group_id, self.sub_guide_id, iaName)
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideTargetClicked, self)
      break
    end
  end
end

function GuideSubConfig:JudgeIAMatch(iaName, keyName)
  if not iaName then
    return false
  end
  local realKeyName = GuideConfigTypes.GetRealMatchKeyName(keyName)
  local keyUIName = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetKeyUIName, keyName)
  
  local function checkKeyMatch(name)
    if "" ~= keyUIName then
      return keyUIName == name
    end
    return realKeyName == name
  end
  
  local keyText, _ = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetMappingKeyUIName, iaName)
  if keyText and "" ~= keyText then
    if checkKeyMatch(keyText) then
      return true
    end
  elseif checkKeyMatch(iaName) then
    return true
  end
  return false
end

function GuideSubConfig:OnIAInputMatched(iaConfig)
  if not iaConfig then
    return
  end
  Log.Debug("GuideSubConfig:OnIAInputMatched", self.unique_id, self.group_id, self.sub_guide_id, iaConfig.cmd)
  iaConfig.hasTriggered = true
  if iaConfig.cmd then
    _G.NRCModuleManager:DoCmd(iaConfig.cmd)
  end
end

function GuideSubConfig:ResetIaWatchConfigs()
  if not self.iaWatchConfigs then
    return
  end
  for _, iaConfig in ipairs(self.iaWatchConfigs) do
    if not iaConfig then
    else
      iaConfig.hasTriggered = nil
    end
  end
end

function GuideSubConfig:CheckIfTargetPanelClosed(panelData)
  if not panelData then
    return
  end
  if not self.styleConfig then
    return
  end
  local styleType = self.styleConfig.style_type
  local styleId = self.styleConfig.type_id
  local panelName
  if styleType == GuideConfigTypes.GuideStyleType.Focus then
    local focusConf = _G.DataConfigManager:GetGuideFocusConf(styleId, true)
    if not focusConf then
      return
    end
    if not focusConf.ui_path then
      return
    end
    panelName = focusConf.ui_path[1]
  elseif styleType == GuideConfigTypes.GuideStyleType.Banner then
    local bannerConf = _G.DataConfigManager:GetGuideBannerConf(styleId, true)
    if not bannerConf then
      return
    end
    panelName = GuideConfigTypes.GetTargetPanelName(bannerConf.show_panel)
  elseif styleType == GuideConfigTypes.GuideStyleType.Drag then
    local dragConf = _G.DataConfigManager:GetGuideDragConf(styleId, true)
    if not dragConf then
      return
    end
    panelName = GuideConfigTypes.GetTargetPanelName(dragConf.show_panel)
  end
  if not panelName then
    return
  end
  local widgetName = GuideConfigTypes.GetWidgetNameFromPanelData(panelData)
  Log.Debug("GuideSubConfig:CheckIfTargetPanelClosed", styleType, styleId, panelName, widgetName)
  if panelName ~= widgetName then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideFocusTargetLost, self)
end

function GuideSubConfig:GetDebugInfo()
  return string.format("%d-%d-%d", self.unique_id, self.group_id, self.sub_guide_id)
end

function GuideSubConfig:IsStrongGuide()
  if not self.styleConfig then
    return false
  end
  return self.styleConfig.strong_guide
end

function GuideSubConfig:GetButtonCompletionType()
  local types = {}
  
  local function insertButtonType(completion)
    if not completion then
      return
    end
    if completion.type ~= GuideConfigTypes.ConditionType.Button then
      return
    end
    table.insert(types, completion.param2)
  end
  
  insertButtonType(self.completion)
  insertButtonType(self.completion2)
  return types
end

function GuideSubConfig:IsCompleteWithButtonClicked()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_CLICK then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonLongPress()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_LONGPRESS then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonReleased()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_RELEASED then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonScrollUp()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_SCROLL_UP then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonScrollDown()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_SCROLL_DOWN then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonScrollLeft()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_SCROLL_LEFT then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonScrollRight()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_SCROLL_RIGHT then
      return true
    end
  end
  return false
end

function GuideSubConfig:IsCompleteWithButtonScroll()
  local types = self:GetButtonCompletionType()
  for _, type in pairs(types) do
    if type == Enum.GuideActionType.GAT_SCROLL_UP or type == Enum.GuideActionType.GAT_SCROLL_DOWN or type == Enum.GuideActionType.GAT_SCROLL_LEFT or type == Enum.GuideActionType.GAT_SCROLL_RIGHT then
      return true
    end
  end
  return false
end

return GuideSubConfig

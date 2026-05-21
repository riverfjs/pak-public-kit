local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local GuideSubConfig = require("NewRoco.Modules.System.Guidance.Types.GuideSubConfig")
local MaxFocusTargetLostTimes = 3
local GuideGroupConfig = NRCClass:Extend("GuideGroupConfig")

function GuideGroupConfig.ConfigIsEnabled(config)
  if not config then
    return false
  end
  if 1 == config.open then
    Log.Debug("GuideGroupConfig:ConfigIsEnabled: config is not open", config.id, config.editor_name)
    return false
  end
  if config.is_inbattle then
    Log.Debug("GuideGroupConfig:ConfigIsEnabled: is_inbattle", config.id, config.editor_name)
    return false
  end
  if _G.UE4Helper.IsPCMode() then
    if not config.pc_show then
      Log.Debug("GuideGroupConfig:ConfigIsEnabled: config not enable for pc", config.id, config.editor_name)
      return false
    end
  elseif not config.mobile_show then
    Log.Debug("GuideGroupConfig:ConfigIsEnabled: config not enable for mobile", config.id, config.editor_name)
    return false
  end
  return true
end

function GuideGroupConfig.InitFromDataConfig(config)
  if not config then
    return nil
  end
  if not GuideGroupConfig.ConfigIsEnabled(config) then
    return nil
  end
  Log.Debug("GuideGroupConfig:InitFromDataConfig: config added", config.id, config.editor_name)
  local guide = GuideGroupConfig()
  guide.guide_group_id = config.guide_group_id
  guide.guide_group_priority = config.guide_group_priority
  guide.bIsLocal = config.is_local
  guide.bCanInterruptOther = config.can_interrupt_other
  guide.ensureFinishCond = GuideConfigTypes.GetGuideConditionConfig(config.finish_type, config.finish_data1, config.finish_data2)
  guide.subConfigs = {}
  guide.subIds = {}
  guide:AddSubConfig(config)
  return guide
end

function GuideGroupConfig:AddSubConfig(config)
  if not config then
    return nil
  end
  if not GuideGroupConfig.ConfigIsEnabled(config) then
    return nil
  end
  Log.Debug("GuideGroupConfig:AddSubConfig: config added", config.id, config.editor_name)
  if self.subConfigs == nil then
    self.subConfigs = {}
  end
  local subConfig = GuideSubConfig.InitFromDataConfig(config)
  subConfig.group_id = self.guide_group_id
  subConfig.guide_group_priority = self.guide_group_priority
  if not table.containsKey(self.subConfigs, subConfig.sub_guide_id) then
    self.subConfigs[subConfig.sub_guide_id] = {}
    table.insert(self.subIds, subConfig.sub_guide_id)
  end
  table.insert(self.subConfigs[subConfig.sub_guide_id], subConfig)
end

function GuideGroupConfig:SortSubConfigs()
  if self.subIds == nil then
    return
  end
  table.sort(self.subIds, function(a, b)
    return a < b
  end)
  self.currentSubId = 1
end

function GuideGroupConfig:CheckCondition(type, param1, param2)
  if self:HasCompleted() then
    return
  end
  local finishCond = self.ensureFinishCond
  if finishCond and finishCond.type == type and finishCond.param1 == param1 and finishCond.param2 == param2 then
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideeGroupComplete, self)
    return
  end
  if not self.subConfigs then
    return false
  end
  local subConfigId = self.subIds[self.currentSubId]
  local subConfigs = self.subConfigs[subConfigId]
  if not subConfigs then
    return false
  end
  if self:IsSubmitting(subConfigId) then
    Log.Debug("GuideGroupConfig:CheckCondition: is submitting", subConfigId, type, param1, param2)
    return
  end
  local notTriggerConfig = {}
  local newTriggerConfig = {}
  local completedMask = 0
  for idx, subConfig in pairs(subConfigs) do
    if subConfig.state == GuideConfigTypes.SubConfigState.Activated then
      if subConfig:CheckCondition(type, param1, param2) and subConfig:CheckTriggerSatisfied() then
        if type == GuideConfigTypes.ConditionType.GuideSetting then
          if subConfig:CheckCanTrig() then
            table.insert(newTriggerConfig, subConfig)
          end
        else
          subConfig.state = GuideConfigTypes.SubConfigState.Pending
          Log.Debug("GuideGroupConfig:CheckCondition: sub guide change to pending", subConfig.unique_id, subConfig.group_id, subConfig.sub_guide_id, type, param1, param2)
          _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
        end
      end
    elseif subConfig.state == GuideConfigTypes.SubConfigState.Triggered then
      if type == GuideConfigTypes.ConditionType.GuideSetting and subConfig:ShouldResponseGuideSettingChanged() then
        if subConfig:GetSettingModeSatisfied() and not subConfig:CheckGuideSettingMode(param1, param2) then
          table.insert(notTriggerConfig, subConfig)
        end
      elseif subConfig:CheckCompletion(type, param1, param2) then
        Log.Debug("GuideGroupConfig:CheckCondition: sub guide change to complete", subConfig.unique_id, subConfig.group_id, subConfig.sub_guide_id, type, param1, param2)
        if subConfig:GetIsMutex() then
          completedMask = (1 << #subConfigs) - 1
        else
          completedMask = completedMask | 1 << idx - 1
        end
        subConfig:OnCompleted()
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideComplete, subConfig)
      end
    elseif subConfig.state == GuideConfigTypes.SubConfigState.Pending then
      if type == GuideConfigTypes.ConditionType.GuideSetting and subConfig:ShouldResponseGuideSettingChanged() then
        if not subConfig:GetSettingModeSatisfied() and subConfig:CheckGuideSettingMode(param1, param2) and subConfig:CheckTriggerSatisfied() then
          table.insert(newTriggerConfig, subConfig)
        end
      elseif subConfig:CheckTriggerSatisfied() then
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
      end
    elseif subConfig.state == GuideConfigTypes.SubConfigState.Completed then
      completedMask = completedMask | 1 << idx - 1
    end
  end
  if #notTriggerConfig > 0 or #newTriggerConfig > 0 then
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideSwitch, notTriggerConfig, newTriggerConfig)
  end
  if completedMask == (1 << #subConfigs) - 1 then
    Log.Debug("GuideGroupConfig:CheckCondition sub guide group completed", self.guide_group_id, subConfigId)
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideSubmit, self, subConfigId)
  end
end

function GuideGroupConfig:IsSubmitting(subConfigId)
  if not subConfigId then
    return false
  end
  if not self.submittingSubIds then
    return false
  end
  if self.submittingSubIds[subConfigId] then
    return true
  end
  return false
end

function GuideGroupConfig:StartSubmit(subConfigId)
  if not subConfigId then
    return
  end
  if not self.submittingSubIds then
    self.submittingSubIds = {}
  end
  self.submittingSubIds[subConfigId] = true
end

function GuideGroupConfig:EndSubmit(sync_group)
  if not sync_group then
    return
  end
  if not self.submittingSubIds then
    return
  end
  if sync_group.finish_all then
    self.submittingSubIds = nil
  elseif sync_group.finish_index then
    for _, id in pairs(sync_group.finish_index) do
      if id and self.submittingSubIds[id] then
        self.submittingSubIds[id] = nil
      end
    end
  end
end

function GuideGroupConfig:HasCompleted()
  if self.currentSubId == nil then
    return false
  end
  return self.currentSubId > #self.subIds
end

function GuideGroupConfig:OnInterrupted()
  self:ClearFlags()
  if not self.subConfigs then
    return
  end
  local currentSubConfigId = self.subIds[self.currentSubId]
  local currentSubConfigs = self.subConfigs[currentSubConfigId]
  if not currentSubConfigs then
    return
  end
  for _, subConfig in pairs(currentSubConfigs) do
    if subConfig.state == GuideConfigTypes.SubConfigState.Triggered then
      subConfig:Reset()
      subConfig.state = GuideConfigTypes.SubConfigState.Pending
    end
  end
end

function GuideGroupConfig:OnReconnect(bFromLostPanel)
  self:ClearFlags(bFromLostPanel)
  if not self.subConfigs then
    return
  end
  local currentSubConfigId = self.subIds[self.currentSubId]
  local currentSubConfigs = self.subConfigs[currentSubConfigId]
  if not currentSubConfigs then
    return
  end
  local resetToStep
  for _, subConfig in pairs(currentSubConfigs) do
    local step = subConfig:GetReconnectStep()
    if step then
      if nil == resetToStep then
        resetToStep = step
      else
        resetToStep = math.min(resetToStep, step)
      end
    end
  end
  if -1 == resetToStep then
    Log.Debug("GuideGroupConfig:OnReconnect: triggered but not need to recover", self.guide_group_id, currentSubConfigId)
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideeGroupComplete, self)
    return
  end
  if nil == resetToStep then
    return
  end
  if currentSubConfigId < resetToStep then
    return
  end
  local resetToStepIdx
  for idx, value in pairs(self.subIds) do
    if value == resetToStep then
      resetToStepIdx = idx
      break
    end
  end
  if nil == resetToStepIdx then
    return
  end
  for _, subConfigs in pairs(self.subConfigs) do
    if subConfigs then
      for _, subConfig in pairs(subConfigs) do
        subConfig:Reset()
      end
    end
  end
  Log.Debug("GuideGroupConfig:OnReconnect", self.guide_group_id, self.currentSubId, resetToStep)
  self.currentSubId = resetToStepIdx
end

function GuideGroupConfig:OnRecover()
  local subConfigs = self.subConfigs[self.currentSubId]
  if not subConfigs then
    return
  end
  for _, subConfig in pairs(subConfigs) do
    if subConfig.state == GuideConfigTypes.SubConfigState.Activated then
      subConfig.state = GuideConfigTypes.SubConfigState.Pending
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
    elseif subConfig.state == GuideConfigTypes.SubConfigState.Pending then
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
    elseif subConfig.state == GuideConfigTypes.SubConfigState.Triggered then
      subConfig:Reset()
      subConfig.state = GuideConfigTypes.SubConfigState.Pending
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
    end
  end
end

function GuideGroupConfig:UpdateWithServerData(serverData)
  if not serverData then
    return
  end
  self.currentSubId = 1
  for id, subConfigs in pairs(self.subConfigs) do
    local bCompleted = false
    if serverData.finish_all then
      bCompleted = true
    else
      bCompleted = table.contains(serverData.finish_index, id)
    end
    if bCompleted then
      for _, subConfig in pairs(subConfigs) do
        subConfig:OnCompleted()
      end
      self.currentSubId = self.currentSubId + 1
    else
      break
    end
  end
end

function GuideGroupConfig:MarkSubGuideComplete()
  if not self.subConfigs then
    return
  end
  local subConfigId = self.subIds[self.currentSubId]
  local subConfigs = self.subConfigs[subConfigId]
  if not subConfigs then
    return
  end
  for _, subConfig in pairs(subConfigs) do
    subConfig:OnCompleted()
  end
  self.currentSubId = self.currentSubId + 1
end

function GuideGroupConfig:ForceStart(targetSubId)
  if self:HasCompleted() then
    return
  end
  if not self.subConfigs then
    return false
  end
  local subConfigId = self.subIds[self.currentSubId]
  if nil ~= targetSubId then
    for idx = subConfigId, targetSubId - 1 do
      local subConfigs = self.subConfigs[idx]
      if subConfigs then
        for _, subConfig in pairs(subConfigs) do
          if subConfig.state ~= GuideConfigTypes.SubConfigState.Completed then
            subConfig:OnCompleted()
          end
        end
        subConfigId = idx
      end
    end
    subConfigId = targetSubId
    self.currentSubId = targetSubId
  end
  local subConfigs = self.subConfigs[subConfigId]
  if not subConfigs then
    return false
  end
  for _, subConfig in pairs(subConfigs) do
    if subConfig.state == GuideConfigTypes.SubConfigState.Activated then
      subConfig.state = GuideConfigTypes.SubConfigState.Pending
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
    elseif subConfig.state == GuideConfigTypes.SubConfigState.Pending then
      _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, subConfig)
    end
  end
end

function GuideGroupConfig:Reset()
  self.currentSubId = 1
  for _, subConfigs in pairs(self.subConfigs) do
    for _, subConfig in pairs(subConfigs) do
      subConfig:Reset()
    end
  end
  self:ClearFlags()
end

function GuideGroupConfig:ForceCompleted()
  Log.Debug("GuideGroupConfig:ForceCompleted", self.guide_group_id, self.currentSubId)
  if self.subConfigs then
    local subConfigId = self.subIds[self.currentSubId]
    local subConfigs = self.subConfigs[subConfigId]
    if subConfigs then
      for _, subConfig in pairs(subConfigs) do
        _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.RemoveFunctionBan, subConfig)
      end
    end
  end
  self.currentSubId = #self.subIds + 1
  self:ClearFlags()
end

function GuideGroupConfig:GetSubGuideWithState(state)
  if self:HasCompleted() then
    return
  end
  if not self.subConfigs then
    return
  end
  local subConfigId = self.subIds[self.currentSubId]
  local subConfigs = self.subConfigs[subConfigId]
  if not subConfigs then
    return
  end
  local subGuides = {}
  for _, subConfig in pairs(subConfigs) do
    if subConfig.state == state and subConfig:CheckTriggerSatisfied() then
      table.insert(subGuides, subConfig)
    end
  end
  return subGuides
end

function GuideGroupConfig:ResetSubGuide(subGuideIdx)
  local subConfigs = self.subConfigs[subGuideIdx]
  if not subConfigs then
    return
  end
  for _, subConfig in pairs(subConfigs) do
    subConfig:Reset()
  end
  self.currentSubId = 1
  self:ClearFlags()
end

function GuideGroupConfig:FocusTargetLostOnce()
  if not self.focusTargetLostTimes then
    self.focusTargetLostTimes = 0
  end
  self.focusTargetLostTimes = self.focusTargetLostTimes + 1
end

function GuideGroupConfig:HasReachedMaxFocusTargetLostTimes()
  if not self.focusTargetLostTimes then
    return false
  end
  return self.focusTargetLostTimes >= MaxFocusTargetLostTimes
end

function GuideGroupConfig:AddSkippedSubConfig(subConfig)
  if not self.skippedSubConfigs then
    self.skippedSubConfigs = {}
  end
  self.skippedSubConfigs[subConfig.unique_id] = subConfig
end

function GuideGroupConfig:CheckIsPreviousSkipped(subConfig)
  if not self.skippedSubConfigs then
    return false
  end
  if 0 == table.len(self.skippedSubConfigs) then
    return false
  end
  return true
end

function GuideGroupConfig:ClearFlags(bFromLostPanel)
  if not bFromLostPanel then
    self.focusTargetLostTimes = nil
  end
  if self.submittingSubIds then
    table.clear(self.submittingSubIds)
    self.submittingSubIds = {}
  end
  if self.skippedSubConfigs then
    table.clear(self.skippedSubConfigs)
    self.skippedSubConfigs = {}
  end
end

return GuideGroupConfig

local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local GuideGroupConfig = require("NewRoco.Modules.System.Guidance.Types.GuideGroupConfig")
local PlayerConditionToLogicStatus = {
  [_G.ProtoEnum.PlayerConditionType.PCT_NEWPLAYER_GUIDE_BLACKMASK] = _G.ProtoEnum.SpaceActorLogicStatus.SALS_NEWPLAYER_GUIDE_BLACKMASK,
  [_G.ProtoEnum.PlayerConditionType.PCT_NEWPLAYER_GUIDE] = _G.ProtoEnum.SpaceActorLogicStatus.SALS_NEWPLAYER_GUIDE
}
local GuidanceModule = NRCModuleBase:Extend("GuidanceModule")

function GuidanceModule:OnConstruct()
  _G.GuidanceModuleCmd = reload("NewRoco.Modules.System.Guidance.GuidanceModuleCmd")
  _G.GuidanceModuleEvent = reload("NewRoco.Modules.System.Guidance.GuidanceModuleEvent")
  self:RegisterCmd(_G.GuidanceModuleCmd.GetCurrentGuideGroupId, self.OnGetCurrentGuideGroupId)
  self:RegisterCmd(_G.GuidanceModuleCmd.GuideTriggerSatisfied, self.OnGuideTriggerSatisfied)
  self:RegisterCmd(_G.GuidanceModuleCmd.SubGuideComplete, self.OnGuideComplete)
  self:RegisterCmd(_G.GuidanceModuleCmd.SubGuideTargetClicked, self.OnSubGuideTargetClicked)
  self:RegisterCmd(_G.GuidanceModuleCmd.SubGuideSkip, self.OnGuideSkip)
  self:RegisterCmd(_G.GuidanceModuleCmd.SubGuideSubmit, self.OnSubGuideSubmit)
  self:RegisterCmd(_G.GuidanceModuleCmd.SubGuideSwitch, self.OnSubGuideSwitch)
  self:RegisterCmd(_G.GuidanceModuleCmd.SubGuideFocusTargetLost, self.OnFocusPanelTargetLost)
  self:RegisterCmd(_G.GuidanceModuleCmd.GuideeGroupComplete, self.OnGuideeGroupComplete)
  self:RegisterCmd(_G.GuidanceModuleCmd.StartLocalGuideGroup, self.OnStartLocalGuideGroup)
  self:RegisterCmd(_G.GuidanceModuleCmd.AddFunctionBan, self.OnAddFunctionBan)
  self:RegisterCmd(_G.GuidanceModuleCmd.RemoveFunctionBan, self.OnRemoveFunctionBan)
  self:RegisterCmd(_G.GuidanceModuleCmd.AddTargetStatus, self.OnAddTargetStatus)
  self:RegisterCmd(_G.GuidanceModuleCmd.RemoveTargetStatus, self.OnRemoveTargetStatus)
  self:RegisterCmd(_G.GuidanceModuleCmd.SetDebugEnabled, self.SetDebugEnabled)
  self:RegisterCmd(_G.GuidanceModuleCmd.GetDebugEnabled, self.GetDebugEnabled)
  self:RegisterCmd(_G.GuidanceModuleCmd.SetShouldSkipServer, self.OnSetShouldSkipServer)
  self:RegisterCmd(_G.GuidanceModuleCmd.StartGuideGroup, self.OnStartGuideGroup)
  self:RegisterCmd(_G.GuidanceModuleCmd.StartSubGuide, self.OnStartSubGuide)
  self:RegisterCmd(_G.GuidanceModuleCmd.FinishCurrentGuideGroup, self.OnFinishCurrentGuideGroup)
  self:RegisterCmd(_G.GuidanceModuleCmd.FinishCurrentSubGuide, self.OnFinishCurrentSubGuide)
  self:RegisterCmd(_G.GuidanceModuleCmd.ClearGuideGroup, self.OnClearGuideGroup)
  self:RegisterCmd(_G.GuidanceModuleCmd.ClearSubGuide, self.OnClearSubGuide)
  self:RegisterCmd(_G.GuidanceModuleCmd.CompleteAllGuide, self.OnCompleteAllGuide)
  self:RegisterCmd(_G.GuidanceModuleCmd.ResetAllGuide, self.OnResetAllGuide)
  self:RegisterCmd(_G.GuidanceModuleCmd.OpenFocusPanel, self.OnOpenFocusPanel)
  self:RegisterCmd(_G.GuidanceModuleCmd.CloseFocusPanel, self.OnCloseFocusPanel)
end

function GuidanceModule:RestParameters()
  self.guideGroups = {}
  self.guideServerData = {}
  self.currentGuideGroupId = nil
  self.candidateGuide = nil
  self.targetPanelData = nil
  self.bPlayerHighlighted = false
end

function GuidanceModule:OnActive()
  if self.bIsLoading ~= false then
    self.bIsLoading = true
  end
  self.bShouldSkipServer = false
  self.bDebugEnabled = false
  self:RestParameters()
  self:InitDataTable()
  self:RegPanel("BlockMask", "UMG_Guidance_BlockMask", _G.Enum.UILayerType.UI_LAYER_GUIDANCE)
  self:RegPanel("FocusPanel", "UMG_Guidance_Main", _G.Enum.UILayerType.UI_LAYER_GUIDANCE)
  self:RegPanel("BannerPanel", "UMG_Guidance_Banner", _G.Enum.UILayerType.UI_LAYER_GUIDANCE)
  self:RegPanel("DragPanel", "UMG_Guidance_DragLine", _G.Enum.UILayerType.UI_LAYER_GUIDANCE)
  self.bIsBaned = _G.FunctionBanManager:GetFunctionState(_G.Enum.PlayerFunctionBanType.PFBT_NEWPLAYER_GUIDE, false, false)
  _G.FunctionBanManager:AddFunctionStateListener(_G.Enum.PlayerFunctionBanType.PFBT_NEWPLAYER_GUIDE, self, self.OnFunctionStateChanged)
  _G.FunctionBanManager:AddRawFunctionStateListener(_G.Enum.PlayerFunctionBanType.PFBT_NEWPLAYER_GUIDE, self, self.OnRawFunctionStateChanged)
  Log.Debug("GuidanceModule:OnActive function state", self.bIsBaned)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GUIDE_INFO_NOTIFY, self.OnReceiveGuideInfoNotify)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.LoadMapFinish, self.LoadMapFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.NAVIGATION_MODE_UPDATE, self.OnNavigationModeChanged)
  _G.NRCEventCenter:RegisterEvent(self.name, self, TaskModuleEvent.OnTaskUpdated, self.OnTaskUpdated)
  _G.NRCEventCenter:RegisterEvent(self.name, self, TaskModuleEvent.OnHiddenTaskUpdated, self.OnHiddenTaskUpdated)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NPCModuleEvent.NpcActionExecute, self.OnNpcActionExecute)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NPCModuleEvent.NpcActionFinish, self.OnNpcActionFinish)
  local dialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  if dialogueModule then
    dialogueModule:RegisterEvent(self, DialogueModuleEvent.ForwardOptionChange, self.OnDialogueOptionChanged)
  end
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.WorldCombatModuleEvent.Enter, self.OnWorldCombatEnter)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.WorldCombatModuleEvent.Exit, self.OnWorldCombatExit)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:RegisterEvent(self, HomeModuleEvent.ApplyFurnitureData, self.OnHomeApplyFurnitureData)
  end
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.LoadPanelSucc, self.OnLoadPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.GuidanceModuleEvent.OnPanelAllReady, self.OnGuideEventPanelAllReady)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.GuidanceModuleEvent.OnPanelLoaded, self.OnGuideEventPanelLoaded)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.GuidanceModuleEvent.OnPanelClosed, self.OnGuideEventPanelClosed)
  local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_KEY, self.OnInputKeyNotify)
  end
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.LoadPanelFail, self.OnPanelLoadFailed)
end

function GuidanceModule:OnDeactive()
  _G.FunctionBanManager:RemoveFunctionStateListener(_G.Enum.PlayerFunctionBanType.PFBT_NEWPLAYER_GUIDE, self, self.OnFunctionStateChanged)
  _G.FunctionBanManager:RemoveRawFunctionStateListener(_G.Enum.PlayerFunctionBanType.PFBT_NEWPLAYER_GUIDE, self, self.OnRawFunctionStateChanged)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GUIDE_INFO_NOTIFY, self.OnReceiveGuideInfoNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.LoadMapFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.NAVIGATION_MODE_UPDATE, self.OnNavigationModeChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.OnTaskUpdated, self.OnTaskUpdated)
  _G.NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.OnHiddenTaskUpdated, self.OnHiddenTaskUpdated)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.NpcActionExecute, self.OnNpcActionExecute)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.NpcActionFinish, self.OnNpcActionFinish)
  local dialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  if dialogueModule then
    dialogueModule:UnRegisterEvent(self, DialogueModuleEvent.ForwardOptionChange)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.Enter, self.OnWorldCombatEnter)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.Exit, self.OnWorldCombatExit)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:UnRegisterEvent(self, HomeModuleEvent.ApplyFurnitureData, self.OnHomeApplyFurnitureData)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.LoadPanelSucc, self.OnLoadPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.GuidanceModuleEvent.OnPanelAllReady, self.OnGuideEventPanelAllReady)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.GuidanceModuleEvent.OnPanelLoaded, self.OnGuideEventPanelLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.GuidanceModuleEvent.OnPanelClosed, self.OnGuideEventPanelClosed)
  local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_KEY, self.OnInputKeyNotify)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.LoadPanelFail, self.OnPanelLoadFailed)
  self:UnInitDataTable()
  self:RestParameters()
  self.bShouldSkipServer = false
end

function GuidanceModule:RegPanel(name, path, layer)
  local panelData = _G.NRCPanelRegisterData()
  panelData.panelName = name
  panelData.panelPath = string.format("/Game/NewRoco/Modules/System/Guidance/Res/%s", path)
  panelData.panelLayer = layer
  panelData.enablePcEsc = false
  panelData.customDisableRendering = true
  self:RegisterPanel(panelData)
end

function GuidanceModule:DisablePanelByLayer(layer, filterPanelList)
end

function GuidanceModule:InitDataTable()
  local guideCtrlConfigs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.GUIDE_CTRL_CONF)
  if not guideCtrlConfigs then
    Log.Warning("failed to get GUIDE_CTRL_CONF")
    return
  end
  self.guideGroups = {}
  for _, guideCtrlConfig in pairs(guideCtrlConfigs) do
    local group_id = guideCtrlConfig.guide_group_id
    if table.containsKey(self.guideGroups, group_id) then
      self.guideGroups[group_id]:AddSubConfig(guideCtrlConfig)
    else
      local guideGroup = GuideGroupConfig.InitFromDataConfig(guideCtrlConfig)
      if guideGroup then
        self.guideGroups[group_id] = guideGroup
      end
    end
  end
  for _, guideGroup in pairs(self.guideGroups) do
    guideGroup:SortSubConfigs()
  end
end

function GuidanceModule:UnInitDataTable()
  table.clear(self.guideGroups)
end

function GuidanceModule:OnPanelLoadFailed(panelData)
  if not panelData then
    return
  end
  Log.Debug("GuidanceModule:OnPanelLoadFailed", panelData.moduleName, panelData.panelName, panelData.panelPath)
  local moduleName = panelData.moduleName
  if moduleName ~= self.name then
    return
  end
  self:OnGuidancePanelOpenFailed()
end

function GuidanceModule:OnGuidancePanelOpenFailed()
  Log.Debug("GuidanceModule:OnGuidancePanelOpenFailed", self.currentGuideGroupId)
  if not self.currentGuideGroupId then
    return
  end
  local guideGroup = self.guideGroups[self.currentGuideGroupId]
  if not guideGroup then
    return
  end
  self:OnGuideeGroupComplete(guideGroup)
end

function GuidanceModule:OnFunctionStateChanged(newBanState, functionType)
  if functionType ~= _G.Enum.PlayerFunctionBanType.PFBT_NEWPLAYER_GUIDE then
    return
  end
  if self.bIsBaned == newBanState then
    return
  end
  self.bIsBaned = newBanState
  Log.Debug("GuidanceModule:OnFunctionStateChanged", newBanState, functionType, self.currentGuideGroupId)
  if self.bIsBaned then
    if self.currentGuideGroupId then
      local guideGroup = self.guideGroups[self.currentGuideGroupId]
      if guideGroup then
        guideGroup:OnInterrupted()
      end
    end
    self:ResetGuideEffect()
  else
    self:CheckCondition()
  end
end

function GuidanceModule:OnRawFunctionStateChanged(newState, functionType, Reason)
  Log.Debug("GuidanceModule:OnRawFunctionStateChanged", newState, functionType, Reason)
end

function GuidanceModule:OnReceiveGuideInfoNotify(notify)
  if not notify or not notify.guide_info then
    return
  end
  Log.Debug("GuidanceModule:OnReceiveGuideInfoNotify")
  local maxUnCompletedGroup
  self.guideServerData = {}
  for _, guide in pairs(notify.guide_info) do
    local group_id = guide.group_id
    if not guide.finish_all then
      if not guide.finish_index then
        Log.Debug("GuidanceModule:OnReceiveGuideInfoNotify not finish_all and finish_index is nil", group_id)
      elseif #guide.finish_index <= 0 then
        Log.Debug("GuidanceModule:OnReceiveGuideInfoNotify not finish_all and len guide.finish_index = 0", group_id)
      elseif self.guideServerData[group_id] then
        Log.Debug("GuidanceModule:OnReceiveGuideInfoNotify group_id already processed", group_id)
      else
        self.guideServerData[group_id] = guide
        Log.Debug("GuidanceModule:OnReceiveGuideInfoNotify find guide record", group_id, guide.finish_all, table.tostring(guide.finish_index))
        if table.containsKey(self.guideGroups, group_id) then
          local groupConfig = self.guideGroups[group_id]
          if groupConfig then
            groupConfig:UpdateWithServerData(guide)
            if groupConfig.currentSubId > 1 and not groupConfig:HasCompleted() and (not maxUnCompletedGroup or groupConfig.guide_group_priority > maxUnCompletedGroup.currentSubId) then
              maxUnCompletedGroup = groupConfig
            end
          end
        end
      end
    end
  end
  if maxUnCompletedGroup then
    Log.Debug("GuidanceModule:OnReceiveGuideInfoNotify no uncompleted group to start", maxUnCompletedGroup.guide_group_id)
    self.currentGuideGroupId = maxUnCompletedGroup.guide_group_id
  end
  self:OnReconnectFinish()
end

function GuidanceModule:OnReconnectFinish()
  Log.Debug("GuidanceModule:OnReconnectFinish")
  self:ResetGuideEffect()
  for _, guideGroup in pairs(self.guideGroups) do
    if self.guideServerData[guideGroup.guide_group_id] then
      guideGroup:OnReconnect()
    else
      Log.Debug("GuidanceModule:OnReconnectFinish no server data, skip", guideGroup.guide_group_id)
    end
    if self.currentGuideGroupId and self.currentGuideGroupId == guideGroup.guide_group_id then
      Log.Debug("GuidanceModule:OnReconnect still currentGuideGroupId, recover. ", self.currentGuideGroupId)
      guideGroup:OnRecover()
      self:CheckGuideSettingMode()
      self:TryDisplayCandidateStyle()
    end
  end
end

function GuidanceModule:LoadMapFinish()
  Log.Debug("GuidanceModule:LoadMapFinish")
  if self:HasPanel("BlockMask") or self:IsPanelInOpening("BlockMask") then
    return
  end
  self:OpenPanel("BlockMask")
end

function GuidanceModule:OnLoadingUIClose()
  self.bIsLoading = false
  Log.Debug("GuidanceModule:OnLoadingUIClose")
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and not localPlayer:HasListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged) then
    localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  end
  self:CheckCondition()
  self:CheckGuideSettingMode()
  self:TryDisplayCandidateStyle()
end

function GuidanceModule:OnLoadingUIOpen()
  self.bIsLoading = true
  Log.Debug("GuidanceModule:OnLoadingUIOpen")
end

function GuidanceModule:GetNavigationMode()
  local navigationMode = 1
  if _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.GetNavigationMode then
    navigationMode = _G.DataModelMgr.PlayerDataModel:GetNavigationMode() or 1
  end
  return navigationMode
end

function GuidanceModule:CheckGuideSettingMode()
  self:OnNavigationModeChanged(self:GetNavigationMode())
end

function GuidanceModule:OnNavigationModeChanged(mode)
  Log.Debug("GuidanceModule:OnNavigationModeChanged", mode)
  self:CheckCondition(GuideConfigTypes.ConditionType.GuideSetting, _G.Enum.GuideSettingMode.GSM_Navigation_Mode, mode)
end

function GuidanceModule:OnSubGuideSwitch(oldSubConfig, newSubConfig)
  if not oldSubConfig or not newSubConfig then
    return
  end
  if #oldSubConfig > 0 then
    for _, guide in pairs(oldSubConfig) do
      guide.state = GuideConfigTypes.SubConfigState.Pending
      Log.Debug("GuidanceModule:OnSubGuideSwitch old close", guide.unique_id, guide.group_id, guide.sub_guide_id)
    end
    if oldSubConfig[1].group_id == self.currentGuideGroupId then
      self:ResetGuideEffect()
      self.currentGuideGroupId = nil
    end
  end
  if #newSubConfig > 0 then
    local bCanBecomeCandidate = true
    if self.currentGuideGroupId then
      local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
      if currentGuideGroup then
        if currentGuideGroup.guide_group_priority >= newSubConfig[1].guide_group_priority then
          bCanBecomeCandidate = false
        else
          local subGuides = currentGuideGroup:GetSubGuideWithState(GuideConfigTypes.SubConfigState.Triggered)
          if subGuides then
            for _, guide in pairs(subGuides) do
              guide.state = GuideConfigTypes.SubConfigState.Pending
            end
          end
          self:ResetGuideEffect()
        end
      end
    end
    if bCanBecomeCandidate then
      self.currentGuideGroupId = newSubConfig[1].group_id
      for _, guide in pairs(newSubConfig) do
        Log.Debug("GuidanceModule:OnSubGuideSwitch new open", guide.unique_id, guide.group_id, guide.sub_guide_id)
      end
    end
  end
end

function GuidanceModule:OnStatusChanged(status, statusValue, opCode, customParam)
  Log.Debug("GuidanceModule:OnStatusChanged", status, statusValue, opCode, customParam)
  if opCode == _G.Enum.WPST_OpCode.WPST_OPCODE_ADD then
    self:CheckCondition(GuideConfigTypes.ConditionType.PlayerStatus, status, 0)
  elseif opCode == _G.Enum.WPST_OpCode.WPST_OPCODE_REMOVE then
    self:CheckCondition(GuideConfigTypes.ConditionType.PlayerStatus, status, 1)
  end
end

function GuidanceModule:IsMapLoading()
  return self.bIsLoading == true
end

function GuidanceModule:IsCurrentWorldOwner()
  if _G.DataModelMgr.PlayerDataModel.IsCurrentWorldOwner then
    return _G.DataModelMgr.PlayerDataModel:IsCurrentWorldOwner()
  elseif _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
    return false
  end
  return true
end

function GuidanceModule:OnTaskUpdated(info)
  if not info then
    return
  end
  if info.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    self:CheckCondition(GuideConfigTypes.ConditionType.Task, info.id, 0)
  elseif info.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    self:CheckCondition(GuideConfigTypes.ConditionType.Task, info.id, 1)
  end
end

function GuidanceModule:OnTaskRemoved(info)
end

function GuidanceModule:OnHiddenTaskUpdated(info)
  if not info then
    return
  end
  Log.Debug("GuidanceModule:OnHiddenTaskUpdated", info.id, info.state, info.open_time, info.done_time, info.is_trace, info.is_track, info.done_count, info.state, info.pet_gid, info.new_task)
  if info.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    self:CheckCondition(GuideConfigTypes.ConditionType.Task, info.id, 0)
  elseif info.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    self:CheckCondition(GuideConfigTypes.ConditionType.Task, info.id, 1)
  end
end

function GuidanceModule:OnHiddenTaskRemoved(taskId, state)
  if not taskId or not state then
    return
  end
end

function GuidanceModule:OnNpcActionExecute(action)
  if not action then
    return
  end
  if not action.Owner then
    return
  end
  if not action.Owner.optionInfo then
    return
  end
  Log.Debug("GuidanceModule:OnNpcActionExecute", action.Owner.optionInfo.option_id)
  self:CheckCondition(GuideConfigTypes.ConditionType.Option, action.Owner.optionInfo.option_id, 0)
end

function GuidanceModule:OnNpcActionFinish(action)
  if not action then
    return
  end
  if not action.Owner then
    return
  end
  if not action.Owner.optionInfo then
    return
  end
  Log.Debug("GuidanceModule:OnNpcActionFinish", action.Owner.optionInfo.option_id)
  self:CheckCondition(GuideConfigTypes.ConditionType.Option, action.Owner.optionInfo.option_id, 1)
end

function GuidanceModule:OnDialogueOptionChanged(option)
  local dialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  if not dialogueModule then
    return
  end
  local actions = dialogueModule:GetActions(option)
  if not actions then
    return
  end
  local newestAction = actions[#actions]
  if not newestAction then
    return
  end
  Log.Debug("GuidanceModule:OnDialogueOptionChanged", newestAction.act_type, newestAction.act_status, newestAction.act_exec_success, newestAction.bound_dialog_id, newestAction.act_result_type, newestAction.dialog_id, newestAction.next_dialog_id)
  local param2
  if newestAction.act_status == _G.ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing then
    param2 = 0
  elseif newestAction.act_status == _G.ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Commited then
    param2 = 1
  end
  self:CheckCondition(GuideConfigTypes.ConditionType.Dialogue, newestAction.dialog_id, param2)
end

function GuidanceModule:OnWorldCombatEnter(combatId, npcId, combatConfId)
  if not combatConfId then
    return
  end
  local combatConf = _G.DataConfigManager:GetWorldCombatConf(combatConfId)
  if not combatConf then
    return
  end
  Log.Debug("GuidanceModule:OnWorldCombatEnter", npcId, combatConf.id, combatConf.editor_name, combatConf.npc_id, combatConf.refresh_content_id)
  self:CheckCondition(GuideConfigTypes.ConditionType.WorldCombat, combatConf.refresh_content_id, 0)
end

function GuidanceModule:OnWorldCombatExit(combatId, npcId, combatConfId)
  if not combatConfId then
    return
  end
  local combatConf = _G.DataConfigManager:GetWorldCombatConf(combatConfId)
  if not combatConf then
    return
  end
  Log.Debug("GuidanceModule:OnWorldCombatExit", npcId, combatConf.id, combatConf.editor_name, combatConf.npc_id, combatConf.refresh_content_id)
  self:CheckCondition(GuideConfigTypes.ConditionType.WorldCombat, combatConf.refresh_content_id, 1)
end

function GuidanceModule:OnHomeApplyFurnitureData(furnitureData)
  if not furnitureData then
    return
  end
  local itemConf = furnitureData.FurnitureItemConf
  if not itemConf then
    return
  end
  Log.Debug("GuidanceModule:OnHomeApplyFurnitureData", itemConf.id, itemConf.name, itemConf.type)
  self:CheckCondition(GuideConfigTypes.ConditionType.HomeFurniture, itemConf.id, 0)
end

function GuidanceModule:OnLoadPanel(panelData)
  if panelData.moduleName == self.name then
    return
  end
  Log.Debug("GuidanceModule:OnPanelLoaded", panelData.panelName, panelData.panelPath, panelData.panelLayer, panelData.openAnimName, panelData.closeAnimName)
  self:CheckCondition(GuideConfigTypes.ConditionType.Panel, panelData, 0)
  self:CheckPanelOnTop(panelData)
end

function GuidanceModule:OnClosePanel(panelData)
  if panelData.moduleName == self.name then
    return
  end
  if self.targetPanelData and self.targetPanelData == panelData and self.currentGuideGroupId ~= nil then
    local isReconnecting = _G.ZoneServer.ZoneServerGCloud:IsReconnecting()
    Log.Debug("GuidanceModule:OnPanelClose target panel closed", panelData.panelName, panelData.panelPath, self.currentGuideGroupId, isReconnecting)
    if isReconnecting then
      self.targetPanelData = nil
    end
  end
  Log.Debug("GuidanceModule:OnPanelClose", panelData.panelName, panelData.panelPath, panelData.panelLayer, panelData.openAnimName, panelData.closeAnimName)
  self:CheckCondition(GuideConfigTypes.ConditionType.Panel, panelData, 1)
  self:CheckPanelOnTop(panelData)
  self:CheckIfTargetPanelClosed(panelData)
end

function GuidanceModule:OnGuideEventPanelAllReady(panelData)
  if not panelData then
    return
  end
  Log.Debug("GuidanceModule:OnGuideEventPanelAllReady", panelData.panelName, panelData.panelPath, panelData.panelLayer)
  self:CheckCondition(GuideConfigTypes.ConditionType.Panel, panelData, 2)
  self:CheckPanelOnTop(panelData)
end

function GuidanceModule:OnGuideEventPanelLoaded(panelData)
  Log.Debug("GuidanceModule:OnGuideEventPanelLoaded")
  self:OnLoadPanel(panelData)
end

function GuidanceModule:OnGuideEventPanelClosed(panelData)
  Log.Debug("GuidanceModule:OnGuideEventPanelClosed")
  self:OnClosePanel(panelData)
end

function GuidanceModule:OnInputKeyNotify(actionName, key, inputEvent)
  if inputEvent ~= UE4.EInputEvent.IE_Released then
    return
  end
  if not self.currentGuideGroupId then
    return
  end
  local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
  if not currentGuideGroup then
    return
  end
  local subGuides = currentGuideGroup:GetSubGuideWithState(GuideConfigTypes.SubConfigState.Triggered)
  if not subGuides then
    return
  end
  for _, subGuide in ipairs(subGuides) do
    subGuide:TryMatchIAInput(actionName, key.KeyName, inputEvent)
  end
end

function GuidanceModule:CheckCondition(type, param1, param2)
  if not self:IsCurrentWorldOwner() then
    return
  end
  for _, guideGroup in pairs(self.guideGroups) do
    guideGroup:CheckCondition(type, param1, param2)
  end
  if self.candidateGuide then
    self.currentGuideGroupId = self.candidateGuide.group_id
    self.candidateGuide = nil
  end
  self:TryDisplayCandidateStyle()
end

function GuidanceModule:TryDisplayCandidateStyle()
  if self:IsMapLoading() then
    return
  end
  if not self:IsCurrentWorldOwner() then
    return
  end
  if self.bIsBaned then
    Log.Debug("GuidanceModule:TryDisplayCandidateStyle bIsBaned")
    return
  end
  if not self.currentGuideGroupId then
    return
  end
  local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
  if not currentGuideGroup then
    return
  end
  local subGuides = currentGuideGroup:GetSubGuideWithState(GuideConfigTypes.SubConfigState.Pending)
  if not subGuides then
    return
  end
  for _, guide in pairs(subGuides) do
    self:OnOpenGuideStyle(guide)
  end
end

function GuidanceModule:OnOpenGuideStyle(config)
  if not config then
    return
  end
  local styleConfig = config.styleConfig
  if not styleConfig then
    return
  end
  local typeId = styleConfig.type_id
  if not typeId then
    return
  end
  
  local function openFocus()
    local focusConf = _G.DataConfigManager:GetGuideFocusConf(typeId, true)
    if not focusConf then
      return
    end
    local targetWidget, targetPanelData, pathWidgets = GuideConfigTypes.GetTargetWidget(focusConf.ui_path, focusConf.ui_button_name)
    if not targetWidget then
      Log.Error("GuidanceModule:OnOpenGuideStyle: targetWidget is nil", config.unique_id, styleConfig.type_id)
      self:OnFocusPanelTargetLost(config)
      return
    end
    local focusPanelData = self:GetPanelData("FocusPanel")
    if styleConfig.strong_guide then
      focusPanelData.enablePcEsc = true
    else
      focusPanelData.enablePcEsc = false
    end
    self.targetPanelData = targetPanelData
    Log.Debug("GuidanceModule:OnOpenGuideStyle Focus", config.unique_id, config.group_id, config.sub_guide_id, typeId)
    self:OpenPanel("FocusPanel", config, styleConfig, targetWidget, targetPanelData, pathWidgets)
    _G.NRCEventCenter:DispatchEvent(_G.GuidanceModuleEvent.CloseBlockMask)
  end
  
  local function openBanner()
    local bannerConf = _G.DataConfigManager:GetGuideBannerConf(typeId, true)
    if not bannerConf then
      return
    end
    Log.Debug("GuidanceModule:OnOpenGuideStyle Banner", config.unique_id, config.group_id, config.sub_guide_id, typeId)
    self:OpenPanel("BannerPanel", styleConfig, bannerConf)
    self:OnAddFunctionBan(config)
  end
  
  local function highlight()
    self:UpdateHighlightState(true)
    self:OnAddFunctionBan(config)
  end
  
  local function openDrag()
    local dragConf = _G.DataConfigManager:GetGuideDragConf(typeId, true)
    if not dragConf then
      return
    end
    Log.Debug("GuidanceModule:OnOpenGuideStyle Drag", config.unique_id, config.group_id, config.sub_guide_id, typeId)
    self:OpenPanel("DragPanel", styleConfig, dragConf)
    self:OnAddFunctionBan(config)
  end
  
  local function tryDelayOpen(func, panelName)
    if panelName and (self:HasPanel(panelName) or self:IsPanelInOpening(panelName)) then
      Log.Debug("GuidanceModule:OnOpenGuideStyle panel is already open", panelName, config.unique_id, config.group_id, config.sub_guide_id)
      return
    end
    if styleConfig.delay_time and styleConfig.delay_time > 0 then
      return _G.DelayManager:DelaySeconds(styleConfig.delay_time / 1000.0, function()
        if self:HasPanel(panelName) or self:IsPanelInOpening(panelName) then
          Log.Debug("GuidanceModule:OnOpenGuideStyle panel is already open after delay", panelName, config.unique_id, config.group_id, config.sub_guide_id)
          return
        end
        config:AfterTriggerDelayFinish()
        func()
      end)
    else
      config:AfterTriggerDelayFinish()
      func()
    end
  end
  
  if not config:BecomeTriggered() then
    return
  end
  if styleConfig.style_type == GuideConfigTypes.GuideStyleType.Focus then
    _G.NRCEventCenter:DispatchEvent(_G.GuidanceModuleEvent.OpenBlockMask)
    self.focusDelayHandle = tryDelayOpen(openFocus, "FocusPanel")
  elseif styleConfig.style_type == GuideConfigTypes.GuideStyleType.Banner then
    self.bannerDelayHandle = tryDelayOpen(openBanner, "BannerPanel")
  elseif styleConfig.style_type == GuideConfigTypes.GuideStyleType.Highlight then
    self.highlightDelayHandle = tryDelayOpen(highlight)
  elseif styleConfig.style_type == GuideConfigTypes.GuideStyleType.Drag then
    self.dragDelayHandle = tryDelayOpen(openDrag, "DragPanel")
  end
end

function GuidanceModule:OnOpenFocusPanel(styleConfig, targetWidget, targetPanelData, pathWidgets, IsInBattle)
  if not styleConfig then
    return
  end
  local typeId = styleConfig.type_id
  if not typeId then
    return
  end
  local focusConf = _G.DataConfigManager:GetGuideFocusConf(typeId)
  if not focusConf then
    return
  end
  local focusPanelData = self:GetPanelData("FocusPanel")
  if styleConfig.strong_guide then
    focusPanelData.enablePcEsc = true
  else
    focusPanelData.enablePcEsc = false
  end
  self:OpenPanel("FocusPanel", nil, styleConfig, targetWidget, targetPanelData, pathWidgets, IsInBattle)
end

function GuidanceModule:OnCloseFocusPanel()
  if self:HasPanel("FocusPanel") then
    self:ClosePanel("FocusPanel")
  end
end

function GuidanceModule:OnGuideTriggerSatisfied(config)
  if self:IsMapLoading() then
    return
  end
  if not self:IsCurrentWorldOwner() then
    return
  end
  if not config then
    return
  end
  if self.currentGuideGroupId ~= nil and not self:CheckCanInterrupt(config.group_id) then
    return
  end
  if nil == self.candidateGuide then
    self.candidateGuide = config
    return
  end
  if config.guide_group_priority > self.candidateGuide.guide_group_priority then
    self.candidateGuide = config
  end
end

function GuidanceModule:CheckCanInterrupt(groupId)
  if self.currentGuideGroupId == groupId then
    return false
  end
  local guideGroup = self.guideGroups[groupId]
  if not guideGroup then
    return false
  end
  if not guideGroup.bCanInterruptOther then
    return false
  end
  local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
  if currentGuideGroup then
    if currentGuideGroup.guide_group_priority >= guideGroup.guide_group_priority then
      return false
    end
    currentGuideGroup:OnInterrupted()
  end
  Log.Debug("GuidanceModule:CheckCanInterrupt", self.currentGuideGroupId, " -> ", groupId)
  self:ResetGuideEffect()
  return true
end

function GuidanceModule:OnGuideComplete(guideSubConfig)
  if not guideSubConfig then
    return
  end
  Log.Debug("GuidanceModule:OnGuideComplete", guideSubConfig.unique_id, guideSubConfig.group_id, guideSubConfig.sub_guide_id)
  self:ResetGuideEffect()
end

function GuidanceModule:OnFocusPanelTargetLost(subConfig)
  local guideGroupId = self.currentGuideGroupId
  if subConfig then
    Log.Debug("GuidanceModule:OnFocusPanelTargetLost with subConfig", subConfig.unique_id, subConfig.group_id, subConfig.sub_guide_id)
    guideGroupId = subConfig.group_id
  end
  local guideGroup = self.guideGroups[guideGroupId]
  if guideGroup then
    if guideGroup:CheckIsPreviousSkipped() then
      self:GMCompleteGuideGroup(guideGroupId)
    else
      guideGroup:FocusTargetLostOnce()
      if guideGroup:HasReachedMaxFocusTargetLostTimes() then
        Log.Debug("GuidanceModule:OnFocusPanelTargetLost HasReachedMaxFocusTargetLostTimes", guideGroupId)
        self:GMCompleteGuideGroup(guideGroupId)
      else
        Log.Debug("GuidanceModule:OnFocusPanelTargetLost not ReachedMaxFocusTargetLostTimes", guideGroupId)
        self:ResetGuideEffect()
        guideGroup:OnReconnect(true)
        guideGroup:OnRecover()
        self:CheckGuideSettingMode()
        self:TryDisplayCandidateStyle()
      end
    end
  end
end

function GuidanceModule:OnGuideeGroupComplete(groupConfig)
  if not groupConfig then
    return
  end
  Log.Debug("GuidanceModule:OnGuideeGroupComplete", groupConfig.guide_group_id)
  groupConfig:ForceCompleted()
  self:GMCompleteGuideGroup(groupConfig.guide_group_id)
  self:OnSubGuideFinished()
end

function GuidanceModule:OnSubGuideTargetClicked(subConfig)
  if not subConfig then
    return
  end
  if not subConfig.completion then
    return
  end
  Log.Debug("GuidanceModule:OnSubGuideTargetClicked", subConfig.unique_id, subConfig.group_id, subConfig.sub_guide_id)
  local guideGroup = self.guideGroups[subConfig.group_id]
  if guideGroup then
    guideGroup:CheckCondition(subConfig.completion.type, subConfig.completion.param1, subConfig.completion.param2)
  end
end

function GuidanceModule:OnGuideSkip(subConfig)
  Log.Debug("GuidanceModule:OnGuideSkip", subConfig.unique_id, subConfig.group_id, subConfig.sub_guide_id)
  local guideGroup = self.guideGroups[subConfig.group_id]
  if guideGroup then
    guideGroup:AddSkippedSubConfig(subConfig)
    guideGroup:ForceCompleted()
  end
  self:GMCompleteGuideGroup(subConfig.group_id)
end

function GuidanceModule:CheckConfigFinishedOnServer(group_id, sub_guide_id)
  if self:ShouldSkipServer(group_id) then
    return true
  end
  if not group_id or not sub_guide_id then
    return false
  end
  local serverData = self.guideServerData[group_id]
  if not serverData then
    return false
  end
  if serverData.finish_all then
    return true
  end
  return table.contains(serverData.finish_index, sub_guide_id)
end

function GuidanceModule:OnSubGuideSubmit(groupConfig, sub_guide_id)
  if not groupConfig or not sub_guide_id then
    return
  end
  local group_id = groupConfig.guide_group_id
  if self:CheckConfigFinishedOnServer(group_id, sub_guide_id) then
    Log.Debug("GuidanceModule:OnSubGuideSubmit config has finished on server", group_id, sub_guide_id)
    groupConfig:MarkSubGuideComplete()
    self:OnSubGuideFinished()
    return
  end
  if groupConfig:IsSubmitting(sub_guide_id) then
    Log.Debug("GuidanceModule:OnSubGuideSubmit config is submitting", group_id, sub_guide_id)
    return
  end
  groupConfig:StartSubmit(sub_guide_id)
  Log.Debug("GuidanceModule:OnSubGuideSubmit send finish req", group_id, sub_guide_id)
  local req = _G.ProtoMessage:newZoneFinishGuideReq()
  req.group_id = group_id
  req.index = {sub_guide_id}
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FINISH_GUIDE_REQ, req, self, self.OnFinishGuideRsp)
  groupConfig:MarkSubGuideComplete()
  self:OnSubGuideFinished()
end

function GuidanceModule:OnFinishGuideRsp(rsp)
  if not rsp then
    return
  end
  local retInfo = rsp.ret_info
  if not retInfo then
    return
  end
  if 0 == retInfo.ret_code then
    if not rsp.sync_group then
      return
    end
    local groupInfo = rsp.sync_group
    if not groupInfo then
      return
    end
    Log.Debug("GuidanceModule:OnFinishGuideRsp", retInfo.ret_code, groupInfo.group_id, groupInfo.finish_all, groupInfo.finish_index and table.tostring(groupInfo.finish_index))
    self.guideServerData[groupInfo.group_id] = groupInfo
    local guideGroup = self.guideGroups[groupInfo.group_id]
    if not guideGroup then
      Log.Debug("GuidanceModule:OnFinishGuideRsp guideGroup is nil", groupInfo.group_id)
      return
    end
    guideGroup:EndSubmit(groupInfo)
  else
    Log.Debug("GuidanceModule:OnFinishGuideRsp error ", retInfo.ret_code, retInfo.ret_msg)
  end
end

function GuidanceModule:OnSubGuideFinished()
  Log.Debug("GuidanceModule:OnSubGuideFinished", self.currentGuideGroupId)
  if self.currentGuideGroupId then
    local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
    if currentGuideGroup and currentGuideGroup:HasCompleted() then
      self.currentGuideGroupId = nil
    end
  end
  self:CheckCondition()
end

function GuidanceModule:ResetGuideEffect()
  if _G.BattleManager.isInBattle then
    return
  end
  
  local function closeGuidePanel(panelName)
    if self:HasPanel(panelName) or self:IsPanelInOpening(panelName) then
      self:ClosePanel(panelName)
    end
  end
  
  closeGuidePanel("FocusPanel")
  closeGuidePanel("BannerPanel")
  closeGuidePanel("DragPanel")
  
  local function clearDelayHandle(delayHandle)
    if delayHandle then
      _G.DelayManager:CancelDelayById(delayHandle)
    end
  end
  
  clearDelayHandle(self.focusDelayHandle)
  clearDelayHandle(self.bannerDelayHandle)
  clearDelayHandle(self.highlightDelayHandle)
  clearDelayHandle(self.dragDelayHandle)
  self.focusDelayHandle = nil
  self.bannerDelayHandle = nil
  self.highlightDelayHandle = nil
  self.dragDelayHandle = nil
  self:UpdateHighlightState(false)
  self.targetPanelData = nil
  NRCEventCenter:DispatchEvent(GuidanceModuleEvent.CloseBlockMask)
end

function GuidanceModule:UpdateHighlightState(bOpen)
  if self.bPlayerHighlighted == bOpen then
    return
  end
  self.bPlayerHighlighted = bOpen
  self:UpdateHighlightEffect(bOpen)
end

function GuidanceModule:UpdateHighlightEffect(bOpen)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local viewObj = localPlayer.viewObj
  if not viewObj then
    return
  end
  local skeletalMesh = viewObj.mesh
  if not UE4.UObject.IsValid(skeletalMesh) then
    return
  end
  local materials = skeletalMesh:GetMaterials()
  if not materials then
    return
  end
  local color = UE4.FLinearColor(0.014444, 0.005605, 0.035601, 0)
  local width = 0.2
  if bOpen then
    color = UE4.FLinearColor(1, 0.56, 0, 1)
    width = 0.6
  end
  for idx, mat in tpairs(materials) do
    if not mat:IsA(UE4.UMaterialInstanceDynamic) then
      mat = skeletalMesh:CreateDynamicMaterialInstance(idx - 1, mat)
      skeletalMesh:SetMaterial(idx - 1, mat)
    end
    for _, additionalMat in tpairs(mat.AdditionalMaterials) do
      if UE4.UObject.IsValid(additionalMat) then
        additionalMat:SetVectorParameterValue("CustomOutlineColorAndSwitch", color)
        additionalMat:SetScalarParameterValue("OutlineWidth", width)
      end
    end
  end
end

function GuidanceModule:OnGetCurrentGuideGroupId()
  return self.currentGuideGroupId
end

function GuidanceModule:OnStartLocalGuideGroup(group_id)
  if self.currentGuideGroupId then
    Log.Debug("GuidanceModule:OnStartLocalGuideGroup currentGuideGroupId is nil", group_id)
    return
  end
  local groupConfig = self.guideGroups[group_id]
  if not groupConfig then
    Log.Debug("GuidanceModule:OnStartLocalGuideGroup groupConfig is nil", group_id)
    return
  end
  if not groupConfig.bIsLocal then
    Log.Debug("GuidanceModule:OnStartLocalGuideGroup groupConfig is not local", group_id)
    return
  end
  self.currentGuideGroupId = group_id
  groupConfig:Reset()
  groupConfig:ForceStart()
  groupConfig:CheckCondition(GuideConfigTypes.ConditionType.GuideSetting, _G.Enum.GuideSettingMode.GSM_Navigation_Mode, self:GetNavigationMode())
  self:TryDisplayCandidateStyle()
end

function GuidanceModule:OnLogicStatusAdd(rsp)
  if not rsp then
    return
  end
  if not rsp.ret_info then
    return
  end
  Log.Debug("GuidanceModule:OnLogicStatusAdd", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
end

function GuidanceModule:OnLogicStatusRemove(rsp)
  if not rsp then
    return
  end
  if not rsp.ret_info then
    return
  end
  Log.Debug("GuidanceModule:OnLogicStatusRemove", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
end

function GuidanceModule:CheckIfTargetPanelClosed(panelData)
  local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
  if not currentGuideGroup then
    return
  end
  local subGuides = currentGuideGroup:GetSubGuideWithState(GuideConfigTypes.SubConfigState.Triggered)
  if not subGuides then
    return
  end
  for _, guide in pairs(subGuides) do
    guide:CheckIfTargetPanelClosed(panelData)
  end
end

function GuidanceModule:CheckPanelOnTop(panelData)
  if self:HasPanel("FocusPanel") then
    local focusPanel = self:GetPanel("FocusPanel")
    if focusPanel then
      focusPanel:CheckPanelOnTop()
    end
  end
  if self:HasPanel("BannerPanel") then
    local bannerPanel = self:GetPanel("BannerPanel")
    if bannerPanel then
      bannerPanel:CheckPanelOnTop()
    end
  end
  if self:HasPanel("DragPanel") then
    local dragPanel = self:GetPanel("DragPanel")
    if dragPanel then
      dragPanel:CheckPanelOnTop()
    end
  end
end

function GuidanceModule:OnAddFunctionBan(subconfig)
  if subconfig and subconfig:SwitchFunctionBan(true) then
    Log.Debug("GuidanceModule:OnAddFunctionBan", subconfig.unique_id, subconfig.group_id, subconfig.sub_guide_id)
    self:OnAddTargetStatus(subconfig.funcBanId)
  end
end

function GuidanceModule:OnRemoveFunctionBan(subconfig)
  if subconfig and subconfig:SwitchFunctionBan(false) then
    Log.Debug("GuidanceModule:OnRemoveFunctionBan", subconfig.unique_id, subconfig.group_id, subconfig.sub_guide_id)
    self:OnRemoveTargetStatus(subconfig.funcBanId)
  end
end

function GuidanceModule:OnAddTargetStatus(status)
  local logicStatus = PlayerConditionToLogicStatus[status]
  if not logicStatus then
    return
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    local req = _G.ProtoMessage:newZoneSceneModifyGuideLogicStatusReq()
    req.op.op_type = _G.ProtoEnum.LogicStatusOpType.LSOT_ADD
    req.op.status = logicStatus
    Log.Debug("GuidanceModule:OnAddTargetStatus: send status change req", req.op.op_type, req.op.status)
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MODIFY_GUIDE_LOGIC_STATUS_REQ, req, self, self.OnLogicStatusAdd)
  end
end

function GuidanceModule:OnRemoveTargetStatus(status)
  local logicStatus = PlayerConditionToLogicStatus[status]
  if not logicStatus then
    return
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    local req = _G.ProtoMessage:newZoneSceneModifyGuideLogicStatusReq()
    req.op.op_type = _G.ProtoEnum.LogicStatusOpType.LSOT_REMOVE
    req.op.status = logicStatus
    Log.Debug("GuidanceModule:OnRemoveTargetStatus: send status change req", req.op.op_type, req.op.status)
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MODIFY_GUIDE_LOGIC_STATUS_REQ, req, self, self.OnLogicStatusRemove)
  end
end

function GuidanceModule:SetDebugEnabled(bDebug)
  self.bDebugEnabled = bDebug
  if self:HasPanel("FocusPanel") then
    local focusPanel = self:GetPanel("FocusPanel")
    if focusPanel then
      focusPanel.bEnabledDebug = bDebug
    end
  end
end

function GuidanceModule:GetDebugEnabled()
  if _G.RocoEnv.IS_SHIPPING then
    return false
  end
  return self.bDebugEnabled == true
end

function GuidanceModule:OnSetShouldSkipServer(bShouldSkipServer)
  Log.Debug("GuidanceModule:OnSetShouldSkipServer", self.bShouldSkipServer, " -> ", bShouldSkipServer)
  self.bShouldSkipServer = bShouldSkipServer
end

function GuidanceModule:ShouldSkipServer(group_id)
  local groupConfig = self.guideGroups[group_id]
  if groupConfig and groupConfig.bIsLocal then
    return true
  end
  if _G.RocoEnv.IS_SHIPPING then
    return false
  end
  return self.bShouldSkipServer == true
end

function GuidanceModule:OnStartGuideGroup(group_id)
  local groupConfig = self.guideGroups[group_id]
  if not groupConfig then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\228\184\141\229\173\152\229\156\168\229\188\149\229\175\188\231\187\132\239\188\154%d", group_id), 1, nil, 5)
    return
  end
  if groupConfig:HasCompleted() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\188\149\229\175\188\231\187\132\229\183\178\229\174\140\230\136\144\239\188\154%d", group_id), 1, nil, 5)
    return
  end
  if self.currentGuideGroupId and not self:CheckCanInterrupt(group_id) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\189\147\229\137\141\230\156\137\229\190\133\229\174\140\230\136\144\231\154\132\229\188\149\229\175\188\239\188\154%d", self.currentGuideGroupId), 1, nil, 5)
    return
  end
  self.currentGuideGroupId = group_id
  groupConfig:ForceStart()
  groupConfig:CheckCondition(GuideConfigTypes.ConditionType.GuideSetting, _G.Enum.GuideSettingMode.GSM_Navigation_Mode, self:GetNavigationMode())
  self:TryDisplayCandidateStyle()
end

function GuidanceModule:OnStartSubGuide(group_id, sub_guide_id)
  if self.currentGuideGroupId then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\189\147\229\137\141\230\156\137\229\190\133\229\174\140\230\136\144\231\154\132\229\188\149\229\175\188\239\188\154%d", self.currentGuideGroupId), 1, nil, 5)
    return
  end
  local groupConfig = self.guideGroups[group_id]
  if not groupConfig then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\228\184\141\229\173\152\229\156\168\229\188\149\229\175\188\231\187\132\239\188\154%d", group_id), 1, nil, 5)
    return
  end
  if groupConfig:HasCompleted() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\188\149\229\175\188\231\187\132\229\183\178\229\174\140\230\136\144\239\188\154%d", group_id), 1, nil, 5)
    return
  end
  self.currentGuideGroupId = group_id
  groupConfig:ForceStart(sub_guide_id)
  groupConfig:CheckCondition(GuideConfigTypes.ConditionType.GuideSetting, _G.Enum.GuideSettingMode.GSM_Navigation_Mode, self:GetNavigationMode())
  self:TryDisplayCandidateStyle()
end

function GuidanceModule:OnFinishCurrentGuideGroup()
  if not self.currentGuideGroupId then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\230\178\161\230\156\137\229\190\133\229\174\140\230\136\144\231\154\132\229\188\149\229\175\188\231\187\132"), 1, nil, 5)
    return
  end
  self:GMCompleteGuideGroup(self.currentGuideGroupId)
end

function GuidanceModule:OnFinishCurrentSubGuide()
  if not self.currentGuideGroupId then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\230\178\161\230\156\137\229\190\133\229\174\140\230\136\144\231\154\132\229\173\144\229\188\149\229\175\188\229\186\143\229\136\151"), 1, nil, 5)
    return
  end
  local currentGuideGroup = self.guideGroups[self.currentGuideGroupId]
  if not currentGuideGroup then
    return
  end
  local subGuides = currentGuideGroup:GetSubGuideWithState(GuideConfigTypes.SubConfigState.Triggered)
  if not subGuides then
    return
  end
  for _, subGuide in pairs(subGuides) do
    if subGuide and subGuide.completion then
      currentGuideGroup:CheckCondition(subGuide.completion.type, subGuide.completion.param1, subGuide.completion.param2)
    end
  end
end

function GuidanceModule:OnClearGuideGroup(group_id)
  local groupConfig = self.guideGroups[group_id]
  if not groupConfig then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\228\184\141\229\173\152\229\156\168\229\188\149\229\175\188\231\187\132%d", group_id), 1, nil, 5)
    return
  end
  
  local function clearLocally()
    Log.Debug("GuidanceModule:OnClearGuideGroup clear locally", group_id)
    self:TryResetGuideEffectAfterGM(group_id)
    groupConfig:Reset()
  end
  
  if self:ShouldSkipServer(group_id) then
    clearLocally()
    return
  end
  local serverData = self.guideServerData[group_id]
  if not serverData then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\188\149\229\175\188\231\187\132%d\230\178\161\230\156\137\230\156\141\229\138\161\229\153\168\232\174\176\229\189\149", group_id), 1, nil, 5)
    clearLocally()
    return
  end
  local req = _G.ProtoMessage:newZoneGmClearGuideReq()
  req.group_id = group_id
  if serverData.finish_all then
    req.index = groupConfig.subIds
  else
    if not serverData.finish_index then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\188\149\229\175\188\231\187\132%d\230\178\161\230\156\137\230\156\141\229\138\161\229\153\168\232\174\176\229\189\149\231\154\132finish_index", group_id), 1, nil, 5)
      clearLocally()
      return
    end
    req.index = serverData.finish_index
  end
  Log.Debug("GuidanceModule:OnClearGuideGroup send req", group_id)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrGmCmd.ZONE_GM_CLEAR_GUIDE_REQ, req, self, self.OnClearGuideGroupRsp)
end

function GuidanceModule:OnClearGuideGroupRsp(rsp)
  if not rsp.sync_group then
    Log.Warning("GuidanceModule:OnClearGuideGroupRsp sync_group is nil")
    return
  end
  local group_id = rsp.sync_group.group_id
  Log.Debug("GuidanceModule:OnClearGuideGroupRsp", group_id)
  self.guideServerData[group_id] = rsp.sync_group
  local groupConfig = self.guideGroups[group_id]
  groupConfig:Reset()
  self:TryResetGuideEffectAfterGM(group_id)
end

function GuidanceModule:OnClearSubGuide(group_id, sub_guide_id)
  local groupConfig = self.guideGroups[group_id]
  if not groupConfig then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\228\184\141\229\173\152\229\156\168\229\188\149\229\175\188\231\187\132%d", group_id), 1, nil, 5)
    return
  end
  
  local function clearLocally()
    Log.Debug("GuidanceModule:OnClearSubGuide clearLocally", group_id, sub_guide_id)
    self:TryResetGuideEffectAfterGM(group_id)
    groupConfig:ResetSubGuide(sub_guide_id)
  end
  
  if self:ShouldSkipServer(group_id) then
    clearLocally()
    return
  end
  local serverData = self.guideServerData[group_id]
  if not serverData then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\188\149\229\175\188\231\187\132%d\230\178\161\230\156\137\230\156\141\229\138\161\229\153\168\232\174\176\229\189\149", group_id), 1, nil, 5)
    clearLocally()
    return
  end
  if not serverData.finish_all then
    if not serverData.finish_index then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\188\149\229\175\188\231\187\132%d\230\178\161\230\156\137\230\156\141\229\138\161\229\153\168\232\174\176\229\189\149", group_id), 1, nil, 5)
      clearLocally()
      return
    end
    if not table.contains(serverData.finish_index, sub_guide_id) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\229\173\144\229\186\143\229\136\151%d\232\191\152\230\156\170\229\174\140\230\136\144", group_id), 1, nil, 5)
      return
    end
  end
  local req = _G.ProtoMessage:newZoneGmClearGuideReq()
  req.group_id = group_id
  req.index = {sub_guide_id}
  Log.Debug("GuidanceModule:OnClearSubGuide send req", group_id, sub_guide_id)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrGmCmd.ZONE_GM_CLEAR_GUIDE_REQ, req, self, self.OnOnClearSubGuideRsp)
end

function GuidanceModule:OnOnClearSubGuideRsp(rsp)
  if not rsp.sync_group then
    Log.Warning("GuidanceModule:OnOnClearSubGuideRsp sync_group is nil")
    return
  end
  local group_id = rsp.sync_group.group_id
  Log.Debug("GuidanceModule:OnOnClearSubGuideRsp", group_id)
  self.guideServerData[group_id] = rsp.sync_group
  local groupConfig = self.guideGroups[group_id]
  groupConfig:Reset()
  groupConfig:UpdateWithServerData(rsp.sync_group)
  self:TryResetGuideEffectAfterGM(group_id)
end

function GuidanceModule:TryResetGuideEffectAfterGM(group_id)
  Log.Debug("GuidanceModule:TryResetGuideEffectAfterGM", self.currentGuideGroupId, group_id)
  if self.currentGuideGroupId and self.currentGuideGroupId == group_id then
    self:ResetGuideEffect()
    self.currentGuideGroupId = nil
  end
end

function GuidanceModule:OnCompleteAllGuide()
  for group_id, _ in pairs(self.guideGroups) do
    self:GMCompleteGuideGroup(group_id)
  end
end

function GuidanceModule:OnResetAllGuide()
  for group_id, _ in pairs(self.guideGroups) do
    self:OnClearGuideGroup(group_id)
  end
end

function GuidanceModule:GMCompleteGuideGroup(group_id)
  local group = self.guideGroups[group_id]
  if not group then
    return
  end
  group:ForceCompleted()
  if self:ShouldSkipServer(group_id) then
    self:ResetGuideEffect()
    self:OnSubGuideFinished()
    return
  end
  if group:IsSubmitting() then
    Log.Debug("GuidanceModule:GMCompleteGuideGroup config is submitting", group_id)
    return
  end
  group:StartSubmit()
  self:ResetGuideEffect()
  self:OnSubGuideFinished()
  local subIds = {}
  for _, id in pairs(group.subIds) do
    table.insert(subIds, id)
  end
  local serverData = self.guideServerData[group_id]
  if serverData then
    if serverData.finish_all then
      Log.Debug("GuidanceModule:GMCompleteGuideGroup \229\188\149\229\175\188\231\187\132\229\183\178\229\133\168\233\131\168\229\174\140\230\136\144 finish_all", group_id)
      return
    end
    if serverData.finish_index then
      for _, idx in pairs(serverData.finish_index) do
        if table.contains(subIds, idx) then
          table.removeValue(subIds, idx)
        end
      end
      if not subIds or 0 == #subIds then
        Log.Debug("GuidanceModule:GMCompleteGuideGroup \229\188\149\229\175\188\231\187\132\229\183\178\229\133\168\233\131\168\229\174\140\230\136\144 not subIds or #subIds == 0", group_id)
        return
      end
    end
  end
  local req = _G.ProtoMessage:newZoneFinishGuideReq()
  req.group_id = group_id
  req.index = subIds
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FINISH_GUIDE_REQ, req, self, self.GMCompleteGuideGroupRsp)
end

function GuidanceModule:GMCompleteGuideGroupRsp(rsp)
  if rsp and rsp.ret_info and rsp.sync_group then
    Log.Debug("GuidanceModule:GMCompleteGuideGroupRsp", rsp.ret_info.ret_code, rsp.sync_group.group_id, rsp.sync_group.finish_all, rsp.sync_group.finish_index)
  end
  self:OnFinishGuideRsp(rsp)
end

return GuidanceModule

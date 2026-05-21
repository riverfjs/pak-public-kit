local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local ProtoEnum = require("Data.PB.ProtoEnum")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local Base = _G.NRCPanelBase
local UMG_PVP_ValueNumber_C = Base:Extend("UMG_PVP_ValueNumber_C")

function UMG_PVP_ValueNumber_C:OnActive()
  self.isShow = false
  self.roundIsPlaying = false
  local kickOffTitleStringConfig = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character4")
  local exitTitleStringConfig = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character1")
  local exitContentStringConfig = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character2")
  local kickOffTitleString = kickOffTitleStringConfig and kickOffTitleStringConfig.str or ""
  local exitTitleString = exitTitleStringConfig and exitTitleStringConfig.str or ""
  local exitContentString = exitContentStringConfig and exitContentStringConfig.str or ""
  self.kickOffDialogueContext = DialogContext()
  self.kickOffDialogueContext:SetTitle(kickOffTitleString)
  self.kickOffDialogueContext:SetMode(DialogContext.Mode.OK_CANCEL)
  self.kickOffDialogueContext:SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1)
  self.kickOffDialogueContext:SetCallback(self, self.OnKickOffDialogueContextCallback)
  self.leaveWatchingBattleDialogueContext = DialogContext()
  self.leaveWatchingBattleDialogueContext:SetTitle(exitTitleString)
  self.leaveWatchingBattleDialogueContext:SetContent(exitContentString)
  self.leaveWatchingBattleDialogueContext:SetMode(DialogContext.Mode.OK_CANCEL)
  self.leaveWatchingBattleDialogueContext:SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1)
  self.leaveWatchingBattleDialogueContext:SetCallback(self, self.OnLeaveWatchBattleConfirm)
  self.observerListWaitingForShow = {}
  self.observerListCanvasPanelIsVisible = false
  self.ObserverListCanvasPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.BtnCloseObserverList:SetVisibility(UE.ESlateVisibility.Collapsed)
  if UE.UObject.IsValid(self.Name_1) then
    self.Name:SetRenderOpacity(0)
    self.Name_1:SetRenderOpacity(0)
  end
  _G.BattleEventCenter:Bind(self, BattleEvent.PVP_OBSERVER_CHANGE, BattleEvent.BATTLE_STATE_SETTLEMENT, BattleEvent.ROUND_START, BattleEvent.START_BATTLE_PERFORM, BattleEvent.UI_SHOW, BattleEvent.UI_HIDE)
  if BattleUtils.IsWatchingBattle() then
    self.getPlayerSettingsAsyncContext = au.Launch(self:TryMakeSurePlayerSetting(), function(ok, messageOrResult)
      if not ok then
        Log.Warning(messageOrResult)
      else
        Log.Debug("UMG_PVP_ValueNumber_C:TryMakeSurePlayerSetting async operation completed")
      end
      self.getPlayerSettingsAsyncContext = nil
    end)
    self.Switcher:SetActiveWidgetIndex(1)
    self:InitWatchModeGrid()
    self.DropOut.btnLevelUp.OnClicked:Add(self, self.HandleLeaveWatchingBattleButtonClick)
    self:HandlePlayerSettingUpdate()
  else
    self.Switcher:SetActiveWidgetIndex(0)
    self.Switcher:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:UpdateObserverList()
    self.Watch.btnLevelUp.OnClicked:Add(self, self.ToggleObserverListPanel)
    self.BtnCloseObserverList.OnClicked:Add(self, self.ToggleObserverListPanel)
  end
  _G.NRCEventCenter:RegisterEvent("UMG_PVP_ValueNumber_C", self, SystemSettingModuleEvent.PlayerSettingUpdate, self.HandlePlayerSettingUpdate)
  local panel = self.module:GetPanel("BattleMain")
  if panel and not panel:IsShowing() then
    self:HideUmg()
  else
    self:PlayAnimation(self.In)
  end
end

function UMG_PVP_ValueNumber_C:OnDeactive()
  if self.showWatchingNameAsyncContext then
    a.kill(self.showWatchingNameAsyncContext)
    self.showWatchingNameAsyncContext = nil
  end
  if self.getPlayerSettingsAsyncContext then
    a.kill(self.getPlayerSettingsAsyncContext)
    self.getPlayerSettingsAsyncContext = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.PlayerSettingUpdate, self.HandlePlayerSettingUpdate)
  _G.BattleEventCenter:UnBind(self)
  self.Watch.btnLevelUp.OnClicked:Remove(self, self.ToggleObserverListPanel)
  self.DropOut.btnLevelUp.OnClicked:Remove(self, self.HandleLeaveWatchingBattleButtonClick)
  if self.kickOffDialogueContext then
    self.kickOffDialogueContext:Close()
  end
  if self.leaveWatchingBattleDialogueContext then
    self.leaveWatchingBattleDialogueContext:Close()
  end
  self.kickOffDialogueContext = nil
  self.leaveWatchingBattleDialogueContext = nil
end

function UMG_PVP_ValueNumber_C:OnAddEventListener()
end

function UMG_PVP_ValueNumber_C:HandlePvpObserverChange(observerEnterList)
  if BattleUtils.IsWatchingBattle() then
    return
  end
  self:UpdateObserverList()
  for i, observerInfo in ipairs(observerEnterList) do
    table.insert(self.observerListWaitingForShow, observerInfo)
  end
  if not self.roundIsPlaying then
    self:TryShowNewWatchingNames()
  end
end

function UMG_PVP_ValueNumber_C:TryShowNewWatchingNames()
  if not self.showWatchingNameAsyncContext and #self.observerListWaitingForShow > 0 then
    self.showWatchingNameAsyncContext = au.Launch(UMG_PVP_ValueNumber_C.StartShowEnterObserverNameList(self), function(ok, messageOrResult)
      if not ok then
        Log.Error(messageOrResult)
      else
        Log.Debug("UMG_PVP_ValueNumber_C.StartShowEnterObserverNameList async operation completed")
      end
      self.showWatchingNameAsyncContext = nil
    end)
  end
end

function UMG_PVP_ValueNumber_C:UpdateObserverList()
  local observerInfoList = _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.GetObserverBriefInfoList)
  local newIsShow = false
  if 0 == #observerInfoList then
    newIsShow = false
  else
    newIsShow = true
  end
  if newIsShow and not self.isShow then
    if self:IsAnimationPlaying(self.Out) then
      self:StopAnimation(self.Out)
    end
    self.Switcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.In)
  end
  if not newIsShow and self.isShow then
    if self:IsAnimationPlaying(self.In) then
      self:StopAnimation(self.In)
    end
    self:PlayAnimation(self.Out)
  end
  self.isShow = newIsShow
  local currentWaitingForConfirmUniIsInList = false
  for i, data in ipairs(observerInfoList) do
    data.OnKickOffCallbackOwner = self
    data.OnKickOffCallback = self.HandleItemKickOffButtonClick
    if self.waitingForConfirmKickOffPlayerUni ~= nil and self.waitingForConfirmKickOffPlayerUni == data.uin then
      currentWaitingForConfirmUniIsInList = true
    end
  end
  self.List:InitList(observerInfoList)
  if not currentWaitingForConfirmUniIsInList then
    self.kickOffDialogueContext:Close()
  end
  local observerCount = #observerInfoList
  if observerCount <= 99 then
    self.Quantity:SetText(string.format("%d", observerCount))
  else
    self.Quantity:SetText("99+")
  end
end

function UMG_PVP_ValueNumber_C:InitWatchModeGrid()
  local options = {
    {
      label = "1",
      value = ProtoEnum.ObserveBattleMode.OBM_MODE_1
    },
    {
      label = "2",
      value = ProtoEnum.ObserveBattleMode.OBM_MODE_2
    }
  }
  for i, option in ipairs(options) do
    option.OnSelectCallbackOwner = self
    option.OnSelectCallback = self.HandleModeChangeButtonClick
  end
  self.SummaryRecall:InitGridView(options)
end

function UMG_PVP_ValueNumber_C:UpdateWatchModeGrid(observeMode)
  local selectIndex = observeMode
  self.SummaryRecall:SelectItemByIndex(selectIndex)
end

function UMG_PVP_ValueNumber_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PVP_OBSERVER_CHANGE then
    self:HandlePvpObserverChange(...)
  elseif eventName == BattleEvent.BATTLE_STATE_SETTLEMENT then
    self:HandlePvpOver()
  elseif eventName == BattleEvent.UI_SHOW then
    self:ShowUmg()
  elseif eventName == BattleEvent.UI_HIDE then
    self:HideUmg()
  end
end

function UMG_PVP_ValueNumber_C:ShowUmg()
  self.roundIsPlaying = false
  self:Enable()
  if BattleUtils.IsWatchingBattle() then
    if self:IsAnimationPlaying(self.Out) then
      self:StopAnimation(self.Out)
    end
    self.Switcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if not self:IsAnimationPlaying(self.In) then
      self:PlayAnimation(self.In)
    end
  else
    self:UpdateObserverList()
    self:TryShowNewWatchingNames()
  end
end

function UMG_PVP_ValueNumber_C:HideUmg()
  self.roundIsPlaying = true
  local runtimeDateObservingInfo = _G.BattleManager.battleRuntimeData.observingInfo
  if runtimeDateObservingInfo and _G.BattleManager.battleRuntimeData.operateType ~= BattleEnum.Operation.ENUM_NONE then
    runtimeDateObservingInfo.lastOperationType = _G.BattleManager.battleRuntimeData.operateType
  end
  if self:IsAnimationPlaying(self.In) then
    self:StopAnimation(self.In)
  end
  if not self:IsAnimationPlaying(self.Out) then
    self:PlayAnimation(self.Out)
  end
  self.isShow = false
end

function UMG_PVP_ValueNumber_C:ToggleObserverListPanel()
  if self:IsAnimationPlaying(self.ObserverList_In) or self:IsAnimationPlaying(self.ObserverList_Out) then
    return
  end
  self.observerListCanvasPanelIsVisible = not self.observerListCanvasPanelIsVisible
  if self.observerListCanvasPanelIsVisible then
    self.ObserverListCanvasPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.BtnCloseObserverList:SetVisibility(UE.ESlateVisibility.Visible)
    self:PlayAnimation(self.ObserverList_In)
  else
    self.BtnCloseObserverList:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.ObserverList_Out)
  end
end

function UMG_PVP_ValueNumber_C:HandleItemKickOffButtonClick(widget)
  Log.Warning(string.format("UMG_PVP_ValueNumber_C:HandleItemKickOffButtonClick %s kick of", widget.data.name))
  local kickOffContentStringConfig = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character5")
  local kickOffContentString = kickOffContentStringConfig and string.format(kickOffContentStringConfig.str, widget.data.name) or ""
  self.kickOffDialogueContext:SetContent(kickOffContentString)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, self.kickOffDialogueContext)
  self.waitingForConfirmKickOffPlayerUni = widget.data.uin
end

function UMG_PVP_ValueNumber_C:OnKickOffDialogueContextCallback(result)
  if result then
    _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.ReqBattleKickOutObserver, self.waitingForConfirmKickOffPlayerUni)
    self.waitingForConfirmKickOffPlayerUni = nil
  else
    self.waitingForConfirmKickOffPlayerUni = nil
  end
end

local function StartShowEnterObserverNameList(self)
  a.wait(au.DelaySeconds(0.1))
  if not UE.UObject.IsValid(self.Name1_in) then
    return
  end
  local currentUsingName1 = true
  while #self.observerListWaitingForShow > 0 do
    local observerListWaitingForShowCache = {}
    for i, observerInfo in ipairs(self.observerListWaitingForShow) do
      table.insert(observerListWaitingForShowCache, observerInfo)
    end
    self.observerListWaitingForShow = {}
    for i, observerInfo in ipairs(observerListWaitingForShowCache) do
      local friendNameTextStringConfig = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character7")
      local friendNameTextString = friendNameTextStringConfig and friendNameTextStringConfig.str or ""
      if currentUsingName1 then
        self.Name_1:SetText(string.format(friendNameTextString, observerInfo.name))
        self:PlayAnimation(self.Name1_in)
      else
        self.Name:SetText(string.format(friendNameTextString, observerInfo.name))
        self:PlayAnimation(self.Name_in)
      end
      a.wait(au.DelaySeconds(1.05))
      currentUsingName1 = not currentUsingName1
    end
    for i = 1, 10 do
      if 0 == #self.observerListWaitingForShow then
        a.wait(au.DelaySeconds(0.1))
      end
    end
  end
end

UMG_PVP_ValueNumber_C.StartShowEnterObserverNameList = a.sync(StartShowEnterObserverNameList)

local function TryMakeSurePlayerSetting(self)
  local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  local observeMode = BattleUtils.GetObserveModeFromSystemSettings(playerSettings)
  while nil == playerSettings or nil == observeMode do
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqQueryPlayerSettings)
    a.wait(au.DelaySeconds(3))
    playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  end
  a.wait(au.DelayFrames(1))
end

UMG_PVP_ValueNumber_C.TryMakeSurePlayerSetting = a.sync(TryMakeSurePlayerSetting)

function UMG_PVP_ValueNumber_C:HandleModeChangeButtonClick(widget)
  Log.WarningFormat("UMG_PVP_ValueNumber_C:HandleModeChangeButtonClick %s", widget.data.label)
  local nextObserveMode = widget.data.value
  local prevPlayerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  local nextPlayerSettings = BattleUtils.ModifyObserveModeInPlayerSettings(prevPlayerSettings, nextObserveMode)
  if nextPlayerSettings == prevPlayerSettings then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, nextPlayerSettings)
end

function UMG_PVP_ValueNumber_C:HandleLeaveWatchingBattleButtonClick()
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, self.leaveWatchingBattleDialogueContext)
end

function UMG_PVP_ValueNumber_C:OnLeaveWatchBattleConfirm(result)
  if result then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.ReqLeaveObservingBattle)
  else
  end
end

function UMG_PVP_ValueNumber_C:HandlePlayerSettingUpdate()
  if self.getPlayerSettingsAsyncContext then
    a.kill(self.getPlayerSettingsAsyncContext)
    self.getPlayerSettingsAsyncContext = nil
  end
  if BattleUtils.IsWatchingBattle() then
    local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    local observeMode = BattleUtils.GetObserveModeFromSystemSettings(playerSettings)
    if playerSettings then
      self:UpdateWatchModeGrid(observeMode)
      local currentStateName = _G.BattleManager:GetCurrentStateName()
      if currentStateName == BattleEnum.StateNames.RoundSelect or currentStateName == BattleEnum.StateNames.SwapSelect then
        local runtimeDateObservingInfo = _G.BattleManager.battleRuntimeData.observingInfo
        if observeMode == ProtoEnum.ObserveBattleMode.OBM_MODE_1 then
          if _G.BattleManager:GetCurrentStateName() == BattleEnum.StateNames.SwapSelect then
            _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_CHANGE)
          elseif runtimeDateObservingInfo and nil ~= runtimeDateObservingInfo.lastOperationType and -1 ~= runtimeDateObservingInfo.lastOperationType then
            _G.BattleManager:ChangeOperateMode(runtimeDateObservingInfo.lastOperationType)
          else
            _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_SKILL)
          end
        else
          if runtimeDateObservingInfo then
            runtimeDateObservingInfo.lastOperationType = _G.BattleManager.battleRuntimeData.operateType
          end
          _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_NONE)
          _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPet(0.5, true)
        end
      end
    end
  end
end

function UMG_PVP_ValueNumber_C:OnAnimationFinished(Anim)
  if Anim == self.Pop_out then
    self.ObserverListCanvasPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
  elseif Anim == self.Out then
    self.ObserverListCanvasPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Switcher:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_PVP_ValueNumber_C:HandlePvpOver()
  self:PlayAnimation(self.Out)
end

return UMG_PVP_ValueNumber_C

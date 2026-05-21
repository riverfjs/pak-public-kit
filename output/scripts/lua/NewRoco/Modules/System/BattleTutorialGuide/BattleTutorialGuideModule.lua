local BattleTutorialGuideModule = _G.NRCModuleBase:Extend("BattleTutorialGuideModule")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleTutorialGuideConfig = require("NewRoco.Modules.System.BattleTutorialGuide.Data.BattleTutorialGuideConfig")
local BattleTutorialGuideModuleEvent = require("NewRoco.Modules.System.BattleTutorialGuide.BattleTutorialGuideModuleEvent")
local BattleTutorialGuideModuleUtils = require("NewRoco.Modules.System.BattleTutorialGuide.BattleTutorialGuideModuleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local GuideState = {
  Normal = 0,
  DoStep = 1,
  WaitStep = 2,
  BackStep = 3,
  WaitRoundStartNotify = 4
}
local GuideClickState = {
  None = 0,
  Click = 1,
  LongClick = 2
}

function BattleTutorialGuideModule:OnConstruct()
  self.CurId = nil
  self.CurGuideData = nil
  self.CurStepId = 0
  self.FinishMap = {}
  self.CurState = GuideState.Normal
  self:InitDataTable()
  self:AddEventListener()
  _G.BattleTutorialGuideModuleCmd = require("NewRoco.Modules.System.BattleTutorialGuide.BattleTutorialGuideModuleCmd")
  self:RegisterCmd(BattleTutorialGuideModuleCmd.EnterGuide, self.EnterGuide)
  self:RegisterCmd(BattleTutorialGuideModuleCmd.ClearGuide, self.ClearGuide)
  self:RegisterCmd(BattleTutorialGuideModuleCmd.BtnClick, self.BtnClick)
  self:RegisterCmd(BattleTutorialGuideModuleCmd.GuideFinishById, self.GuideFinishById)
  self:RegisterCmd(BattleTutorialGuideModuleCmd.RefreshGuideData, self.RefreshGuideData)
  self:RegisterCmd(BattleTutorialGuideModuleCmd.GetIsForBidSkillClick, self.OnCmdGetIsForBidSkillClick)
end

function BattleTutorialGuideModule:OnDestruct()
  self:RemoveEventListener()
  self.cachedUIEnumShow = {}
  self.UICmdDic = nil
end

function BattleTutorialGuideModule:RegPanel(name, path, layer, OpenAnimName, CloseAnimName, isSingleTouchPanel, customDisableRendering, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/BattleTutorialGuide/Res/%s", path)
  registerData.panelLayer = layer
  registerData.openAnimName = OpenAnimName
  registerData.closeAnimName = CloseAnimName
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.customDisableRendering = customDisableRendering or false
  if nil == enablePcEsc then
    enablePcEsc = false
  end
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function BattleTutorialGuideModule:OnTick(deltaTime)
  if not self.CurState or self.CurState == GuideState.Normal then
    return
  end
  if self.CurState == GuideState.DoStep then
    self:DoStep(self.CurStepInfo)
  elseif self.CurState == GuideState.WaitStep then
    self:CheckCurStep()
  end
end

function BattleTutorialGuideModule:InitDataTable()
  self.guideCfg = BattleTutorialGuideConfig()
  self.guideCfg:InitDataTable()
end

function BattleTutorialGuideModule:CheckCurStep()
  local Step = self.CurStepInfo
  local widget = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
  if not BattleTutorialGuideModuleUtils.IsWidgetVisible(widget) then
    self:ClearCurStep()
    self.CurState = GuideState.DoStep
    self:DoStep(Step)
  end
end

function BattleTutorialGuideModule:TryBackStep()
  self.CurStepId = self.CurStepId - 1
  if 0 == self.CurStepId then
    self:TryNextStep()
  else
    local Step = self.CurGuideData[self.CurStepId]
    self.CurStepInfo = Step
    self.btnName = Step.battle_guidance_location
    local widget = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
    if BattleTutorialGuideModuleUtils.IsWidgetVisible(widget) then
      self.CurStepId = self.CurStepId - 1
      self:TryNextStep()
    else
      self:TryBackStep()
    end
  end
end

function BattleTutorialGuideModule:ClearGuide(id)
  self:GuideFinishById(id)
end

function BattleTutorialGuideModule:EnterGuide(id)
  if self.CurId then
    Log.Warning("\230\173\163\229\156\168\232\191\155\232\161\140\230\150\176\230\137\139\229\188\149\229\175\188 id=", id)
    return
  end
  local guideData = self.guideCfg:GetGroup(id)
  if guideData then
    self.CurId = id
    self.CurrentRound = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.roundIndex
    self.CurrentRoundId = id
    self.CurGuideData = guideData
    self.CurStepId = 0
    self:TryNextStep()
  end
end

function BattleTutorialGuideModule:RefreshGuideData()
  if self.guideCfg then
    self.guideCfg:InitDataTable()
  end
end

function BattleTutorialGuideModule:GuideFinishById(id)
  if self.CurId then
    self:ClearCurStep()
    self:GuideFinish()
    self:OnCmdCloseBattleGuideMain()
  end
end

function BattleTutorialGuideModule:GuideFinish()
  if not self.FinishMap then
    self.FinishMap = {}
  end
  self:SetIsForBidSkillClick(nil)
  self:ClearForceTermination()
  self.FinishMap[self.CurId] = true
  self.CurId = nil
  self.CurGuideData = nil
  self.CurWeakGuideWidget = nil
  self.CurState = GuideState.Normal
end

function BattleTutorialGuideModule:BtnClick(id)
  if not self.CurId then
    return
  end
  if id == self.btnName then
    self:TryNextStep()
  end
end

function BattleTutorialGuideModule:ClearCurStep()
  local Step = self.CurStepInfo
  if not Step then
    return
  end
  self:SetIsForBidSkillClick(nil)
  self:ClearClickedHandler(Step)
  self:ClearForceTermination()
  self:ClearActiveIaWatch()
  self.CurStepInfo = nil
  self:OnCmdCloseBattleGuideMain()
end

function BattleTutorialGuideModule:TryNextStep()
  self:ClearCurStep()
  self.CurStepId = self.CurStepId + 1
  if not self.CurGuideData then
    return
  end
  if self.CurStepId > #self.CurGuideData then
    self:GuideFinish()
  else
    local Step = self.CurGuideData[self.CurStepId]
    if Step then
      self:DoStep(Step)
    else
      self:GuideFinish()
    end
  end
end

function BattleTutorialGuideModule:DoStep(Step)
  Log.Debug("BattleTutorialGuideModule.DoStep:\230\137\167\232\161\140\230\140\135\229\188\149 id=" .. Step.battle_guidance_location)
  self.CurStepInfo = Step
  self.btnName = Step.battle_guidance_location
  if Step.battle_guidance_location == Enum.BattleGuidanceLocation.BGL_WAIT_BEGIN then
    self.CurState = GuideState.WaitRoundStartNotify
  else
    local widget, targetPanelData, pathWidgets = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
    if BattleTutorialGuideModuleUtils.IsWidgetVisible(widget) then
      local styleConfig = Step.CtrlConf
      self:OnCmdOpenBattleGuideMain(styleConfig, widget, targetPanelData, pathWidgets)
      self.CurStrongGuideWidget = widget
      self.CurState = GuideState.WaitStep
      self:TrySetIsForBidSkillClick(Step)
      self:AddClickCallCallBack(widget, Step)
      self:ForceTermination(Step)
      self:AddActiveIaWatch(styleConfig)
    else
      self.CurState = GuideState.DoStep
    end
  end
end

function BattleTutorialGuideModule:AddClickCallCallBack(widget, Step)
  if Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS or Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
    return
  end
  
  local function TryAddCompletion(targetButton)
    if targetButton then
      local completion = {
        targetButton = targetButton,
        CallBack = function()
          self:CurStepHasClicked(Step)
        end
      }
      if targetButton:IsA(UE.UButton) then
        Step.completion = completion
        targetButton.OnClicked:Add(targetButton, Step.completion.CallBack)
      elseif targetButton:IsA(UE.UCheckBox) then
        Step.completion = completion
        targetButton.OnCheckStateChanged:Add(targetButton, Step.completion.CallBack)
      elseif targetButton.OnClickedEvent then
        Step.completion = completion
        targetButton.OnClickedEvent:Add(targetButton, Step.completion.CallBack)
      end
    end
  end
  
  if widget then
    TryAddCompletion(widget)
  end
end

function BattleTutorialGuideModule:ClearClickedHandler(Step)
  if not Step or not Step.completion then
    return
  end
  local targetButton = Step.completion.targetButton
  if targetButton and UE4.UObject.IsValid(targetButton) then
    if targetButton:IsA(UE.UButton) then
      targetButton.OnClicked:Remove(targetButton, Step.completion.CallBack)
    elseif targetButton:IsA(UE.UCheckBox) then
      targetButton.OnCheckStateChanged:Remove(targetButton, Step.completion.CallBack)
    elseif targetButton.OnClickedEvent then
      targetButton.OnClickedEvent:Remove(targetButton, Step.completion.CallBack)
    end
    Step.completion = nil
  end
end

function BattleTutorialGuideModule:CurStepHasClicked(Step)
  self:ClearClickedHandler(Step)
  self:BtnClick(Step.battle_guidance_location)
end

function BattleTutorialGuideModule:ClearForceTermination()
  if self.forceTerminationId then
    _G.DelayManager:CancelDelayById(self.forceTerminationId)
    self.forceTerminationId = nil
  end
end

function BattleTutorialGuideModule:ForceTermination(Step)
  self:ClearForceTermination()
  local time = Step.CtrlConf.finish_overtime or 0
  if time <= 0 then
    return
  end
  self.forceTerminationId = _G.DelayManager:DelaySeconds(time / 1000, function()
    if self then
      self:AutoClickAndNextStep(Step)
    end
  end)
end

function BattleTutorialGuideModule:ClearActiveIaWatch()
  self.IaWatchConfigs = nil
  self.watchedIaNames = nil
end

function BattleTutorialGuideModule:AddActiveIaWatch(styleConfig)
  if styleConfig.active_ia_watch and #styleConfig.active_ia_watch > 0 then
    self.IaWatchConfigs = {}
    self.watchedIaNames = {}
    for _, id in pairs(styleConfig.active_ia_watch) do
      local iaConfig = _G.DataConfigManager:GetGuideIaConf(id, true)
      if iaConfig then
        local ia = {
          id = id,
          iaName = iaConfig.ia_name,
          cmd = iaConfig.ia_command
        }
        table.insert(self.IaWatchConfigs, ia)
        table.insert(self.watchedIaNames, iaConfig.ia_name)
      end
    end
  end
end

function BattleTutorialGuideModule:OnInputKeyNotify(actionName, key, inputEvent)
  if inputEvent ~= UE4.EInputEvent.IE_Released then
    return
  end
  self:TryMatchIAInput(actionName, key.KeyName, inputEvent)
end

function BattleTutorialGuideModule:TryMatchIAInput(actionName, keyName, inputEvent)
  self:TryMatchButtonAndIA(keyName)
end

function BattleTutorialGuideModule:TryMatchActiveIA(keyName)
  local Step = self.CurStepInfo
  if not Step or not self.IaWatchConfigs then
    return
  end
  local styleConfig = Step.CtrlConf
  if not styleConfig or not styleConfig.strong_guide then
    return
  end
  for _, iaConfig in ipairs(self.IaWatchConfigs) do
    if not iaConfig then
    else
      local iaName = iaConfig.iaName
      if self:JudgeIAMatch(iaName, keyName) then
        self:OnIAInputMatched(iaConfig)
        break
      end
    end
  end
end

function BattleTutorialGuideModule:OnIAInputMatched(iaConfig)
  if not iaConfig then
    return
  end
  if iaConfig.cmd then
    _G.NRCModuleManager:DoCmd(iaConfig.cmd)
    self:TryNextStep()
  end
end

function BattleTutorialGuideModule:TryMatchButtonAndIA(keyName)
  if "Touch1" == keyName then
    return
  end
  if not self.CurState or self.CurState == GuideState.Normal then
    return
  end
  if not self.watchedIaNames then
    return
  end
  if not self.CurStepInfo then
    return
  end
  for _, iaName in pairs(self.watchedIaNames) do
    if self:JudgeIAMatch(iaName, keyName) then
      self:AutoClickAndNextStep(self.CurStepInfo)
      break
    end
  end
end

function BattleTutorialGuideModule:JudgeIAMatch(iaName, keyName)
  if not iaName then
    return false
  end
  local keyUIName = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetKeyUIName, keyName)
  
  local function checkKeyMatch(name)
    if "" ~= keyUIName then
      return keyUIName == name
    end
    return keyName == name
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

function BattleTutorialGuideModule:AutoClickAndNextStep(Step)
  self:ClearForceTermination()
  local id = Step.battle_guidance_location
  local ClickState = GuideClickState.None
  if id == Enum.BattleGuidanceLocation.BGL_SKILL_1 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      if Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS then
        BattleMain:TrySelectSkillInfo(1)
        ClickState = GuideClickState.LongClick
      elseif Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
        BattleMain:TrySelectSkillRun(1, true)
        BattleMain:TrySelectSkillRun(1, false)
        ClickState = GuideClickState.Click
      end
    end
  elseif id == Enum.BattleGuidanceLocation.BGL_SKILL_2 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      if Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS then
        BattleMain:TrySelectSkillInfo(2)
        ClickState = GuideClickState.LongClick
      elseif Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
        BattleMain:TrySelectSkillRun(2, true)
        BattleMain:TrySelectSkillRun(2, false)
        ClickState = GuideClickState.Click
      end
    end
  elseif id == Enum.BattleGuidanceLocation.BGL_SKILL_3 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      if Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS then
        BattleMain:TrySelectSkillInfo(3)
        ClickState = GuideClickState.LongClick
      elseif Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
        BattleMain:TrySelectSkillRun(3, true)
        BattleMain:TrySelectSkillRun(3, false)
        ClickState = GuideClickState.Click
      end
    end
  elseif id == Enum.BattleGuidanceLocation.BGL_SKILL_4 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      if Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS then
        BattleMain:TrySelectSkillInfo(4)
        ClickState = GuideClickState.LongClick
      elseif Step.battle_lead_Finish_type == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
        BattleMain:TrySelectSkillRun(4, true)
        BattleMain:TrySelectSkillRun(4, false)
        ClickState = GuideClickState.Click
      end
    end
    ClickState = GuideClickState.LongClick
  elseif id == Enum.BattleGuidanceLocation.BGL_BAG then
    _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_ITEM)
    ClickState = GuideClickState.None
  elseif id == Enum.BattleGuidanceLocation.BGL_BAG_1 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      BattleMain:TrySelectItem(1, true)
      BattleMain:TrySelectItem(1, false)
    end
    ClickState = GuideClickState.None
  elseif id == Enum.BattleGuidanceLocation.BGL_BAG_2 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      BattleMain:TrySelectItem(2, true)
      BattleMain:TrySelectItem(2, false)
    end
    ClickState = GuideClickState.None
  elseif id == Enum.BattleGuidanceLocation.BGL_OUR_PET_ICON then
    local targetButton = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
    if targetButton and UE4.UObject.IsValid(targetButton) and targetButton:IsA(UE.UButton) then
      targetButton.OnClicked:Broadcast()
    end
    ClickState = GuideClickState.Click
  elseif id == Enum.BattleGuidanceLocation.BGL_ENEMY_PET_ICON then
    local targetButton = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
    if targetButton and UE4.UObject.IsValid(targetButton) and targetButton:IsA(UE.UButton) then
      targetButton.OnClicked:Broadcast()
    end
    ClickState = GuideClickState.Click
  elseif id == Enum.BattleGuidanceLocation.BGL_REPLY_ENEMY then
    local targetButton = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
    if targetButton and UE4.UObject.IsValid(targetButton) and targetButton:IsA(UE.UButton) then
      targetButton.OnPressed:Broadcast()
      targetButton.OnReleased:Broadcast()
      targetButton.OnClicked:Broadcast()
    end
    ClickState = GuideClickState.Click
  elseif id == Enum.BattleGuidanceLocation.BGL_CAPTURE then
    _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_CATCH)
    ClickState = GuideClickState.None
  elseif id == Enum.BattleGuidanceLocation.BGL_CAPTURE_1 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      BattleMain:TrySelectCatchBall(0)
    end
    ClickState = GuideClickState.Click
  elseif id == Enum.BattleGuidanceLocation.BGL_PET then
    _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_CHANGE)
    ClickState = GuideClickState.None
  elseif id == Enum.BattleGuidanceLocation.BGL_PET_1 then
    local BattleMain = _G.BattleUtils.GetMainWindow()
    if BattleMain then
      BattleMain:TrySelectChangePet(1)
    end
    ClickState = GuideClickState.None
  else
    local targetButton = self.guideCfg:TryGetGuideWidgetWithFocusId(Step.CtrlConf.type_id)
    if targetButton and UE4.UObject.IsValid(targetButton) and targetButton:IsA(UE.UButton) then
      targetButton.OnClicked:Broadcast()
      ClickState = GuideClickState.Click
    end
  end
  if ClickState == GuideClickState.Click then
    Log.Debug("BattleTutorialGuideModule.AutoClickAndNextStep:\230\137\167\232\161\140\228\184\139\228\184\128\230\173\165\230\140\135\229\188\149 location=" .. id)
  else
    self:TryNextStep()
  end
end

function BattleTutorialGuideModule:OnLeaveBattle()
  if self.CurId then
    self:GuideFinish()
  end
  self.CurrentRound = nil
  self.CurrentRoundId = nil
end

function BattleTutorialGuideModule:AddEventListener()
  _G.NRCEventCenter:RegisterEvent("BattleTutorialGuideModule", self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:RegisterEvent("BattleTutorialGuideModule", self, BattleTutorialGuideModuleEvent.BtnClickEvent, self.BtnClick)
  _G.NRCEventCenter:RegisterEvent("BattleTutorialGuideModule", self, BattleTutorialGuideModuleEvent.EnterBattleTutorialGuideEvent, self.EnterGuide)
  _G.NRCEventCenter:RegisterEvent("BattleTutorialGuideModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_START)
  local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_KEY, self.OnInputKeyNotify)
  end
end

function BattleTutorialGuideModule:RemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleTutorialGuideModuleEvent.BtnClickEvent, self.BtnClick)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleTutorialGuideModuleEvent.EnterBattleTutorialGuideEvent, self.EnterGuide)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.BattleEventCenter:UnBind(self)
end

function BattleTutorialGuideModule:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.ROUND_START and self.CurState == GuideState.WaitRoundStartNotify then
    self:BtnClick(Enum.BattleGuidanceLocation.BGL_WAIT_BEGIN)
  end
end

function BattleTutorialGuideModule:OnReconnect()
  self:CheckCurrentRoundGuide()
end

function BattleTutorialGuideModule:CheckCurrentRoundGuide()
  if not self.CurrentRound or not self.CurrentRoundId then
    return
  end
  local currentId = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.roundIndex or 0
  if currentId == self.CurrentRound then
    self:ClearGuide()
    self:EnterGuide(self.CurrentRoundId)
  end
end

function BattleTutorialGuideModule:OnCmdCloseBattleGuideMain()
  _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.CloseFocusPanel)
end

function BattleTutorialGuideModule:TrySetIsForBidSkillClick(Step)
  self:SetIsForBidSkillClick(Step.battle_lead_Finish_type)
end

function BattleTutorialGuideModule:SetIsForBidSkillClick(State)
  self.IsForBidSKillClick = State
end

function BattleTutorialGuideModule:OnCmdGetIsForBidSkillClick()
  return self.IsForBidSKillClick
end

function BattleTutorialGuideModule:OnCmdOpenBattleGuideMain(styleConfig, TargetWidget, targetPanelData, pathWidgets)
  _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.OpenFocusPanel, styleConfig, TargetWidget, targetPanelData, pathWidgets, true)
end

return BattleTutorialGuideModule

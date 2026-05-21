require("UnLuaEx")
local TextReplaceContext = require("NewRoco.Modules.System.TextReplaceContext")
local DialogueTextReplacer = require("NewRoco.Modules.System.Dialogue.DialogueTextReplacer")
local DialogueModuleEvent = reload("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueTextIndicators = require("NewRoco.Modules.System.Dialogue.Res.DialogueTextIndicators")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local ShowID = RocoEnv.IS_EDITOR or not RocoEnv.IS_SHIPPING and _G.AppMain:HasLaunchParams()
local DialoguePanelBase = NRCPanelBase:Extend("DialoguePanelBase")

function DialoguePanelBase:OnConstruct()
  Log.Debug("DialoguePanelBase:OnConstruct")
  self:InitData()
  self.Replacer = DialogueTextReplacer()
  self.AutoPlayChangedCallbackID = _G.UserSettingManager:RegisterDialogueAutoPlayChangedCallback(self, self.OnDialogueAutoPlayChanged)
end

function DialoguePanelBase:OnDestruct()
  if self.AutoPlayDelayID and self.AutoPlayDelayID > 0 then
    _G.DelayManager:CancelDelayById(self.AutoPlayDelayID)
    self.AutoPlayDelayID = 0
  end
  NRCPanelBase.OnDestruct(self)
end

function DialoguePanelBase:InitData()
  self.done = false
  self._writeDelay = 0.025
  self._texts = {}
  self._textsPerClick = {}
  self._textIndex = 1
  self._textIndexSinglePage = 1
  self.NofSpaces = {}
  self.clicked = false
  self.TypeDone = false
end

function DialoguePanelBase:OnActive(DialogueConf, ContextOption, bBlockEnterAnimation, ExtraConf, EnterCallback, EnterCaller)
  _G.NRCAudioManager:PlaySound2DAuto(41401018, "UMG_AlternateMaterial_C:OnCancel")
  Log.Debug("DialoguePanelBase:OnActive")
  if self.TypeWritter then
    Log.Debug(self.name, "Add OnTypeFinish")
    self.TypeWritter.OnTypeFinish:Add(self, self.OnTypeFinish)
  end
  self:RefreshView(DialogueConf, ContextOption, bBlockEnterAnimation, ExtraConf, EnterCallback, EnterCaller)
end

function DialoguePanelBase:OnDeactive()
  _G.NRCAudioManager:PlaySound2DAuto(41401019, "UMG_AlternateMaterial_C:OnCancel")
  self.DialogueContext = nil
  if UE.UObject.IsValid(self) and self.TypeWritter and UE.UObject.IsValid(self.TypeWritter) then
    self.TypeWritter.OnTypeFinish:Remove(self, self.OnTypeFinish)
    Log.Debug(self.name, "Remove OnTypeFinish")
  end
  _G.UserSettingManager:UnregisterDialogueAutoPlayChangedCallback(self.AutoPlayChangedCallbackID)
  self.AutoPlayChangedCallbackID = 0
end

function DialoguePanelBase:ShowPvpPetTeamList(DialogueConf)
end

function DialoguePanelBase:ShowName(DialogueConf)
end

function DialoguePanelBase:ShowTitle(DialogueConf)
end

function DialoguePanelBase:ShowExtraImage(DialogueConf)
end

function DialoguePanelBase:FakeCenterAlign(inText, TextNumberPerLine)
  TextNumberPerLine = TextNumberPerLine or 34
  local textsPerline = inText:split(DialogueTextIndicators.NextLine)
  local FinalText = ""
  for i = 1, #textsPerline do
    local curLine = textsPerline[i]
    local outText = curLine:gsub("</>", "")
    local outTextNoCenter = outText:gsub("<Center>", "")
    local effectiveText = outTextNoCenter:gsub(DialogueTextIndicators.NeedClick, "")
    effectiveText = effectiveText:gsub(DialogueTextIndicators.PageSeparator, "")
    effectiveText = effectiveText:gsub(DialogueTextIndicators.NextLine, "")
    if outText ~= outTextNoCenter then
      local SentenceLength = #effectiveText
      local SpaceN = (TextNumberPerLine - SentenceLength / 3) * 1.95 + 2
      self.NofSpaces[i] = SpaceN
      local Spaces = ""
      for j = 1, math.round(SpaceN) do
        Spaces = " " .. Spaces
      end
      outText = outText:gsub("<Center>", Spaces)
      FinalText = FinalText .. outText
      FinalText = FinalText .. DialogueTextIndicators.NextLine
    else
      FinalText = FinalText .. curLine
      FinalText = FinalText .. DialogueTextIndicators.NextLine
    end
  end
  return FinalText
end

function DialoguePanelBase:PreprocessText(inText)
  if not inText then
    Log.Warning("Opening a nil text panel")
    return ""
  end
  local outText = inText:gsub(DialogueTextIndicators.NextLine, "\n")
  return outText
end

function DialoguePanelBase:HideNamePanel()
end

function DialoguePanelBase:ApplyNamePanelChange()
end

function DialoguePanelBase:RefreshView(DialogueConf, ContextOption, bBlockEnterAnimation, ExtraConf, EnterCallback, EnterCaller)
  self.ExtraConf = ExtraConf
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Inited = false
  self:StopAllAnimations()
  self.Inited = true
  self.DialogueContext = ContextOption
  self.DialogueConf = DialogueConf
  self.EnterCallback = EnterCallback
  self.EnterCaller = EnterCaller
  if self.ExtraImage then
    self.ExtraImage:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self:ShowName(DialogueConf)
  self:ShowTitle(DialogueConf)
  self:ApplyNamePanelChange(DialogueConf)
  self:ShowExtraImage(DialogueConf)
  self:_SetNextIndicatorVisibility(UE.ESlateVisibility.Collapsed)
  if self.TypeWritter and UE.UObject.IsValid(self.TypeWritter) and self.TypeWritter.Clear then
    self.TypeWritter:Clear()
    self.TypeWritter:SetTextStyles()
  end
  self:ShowPvpPetTeamList(DialogueConf)
  self.callback = nil
  self.caller = nil
  self.bHasNoSelection = not DialogueConf.select_ids or 0 == #DialogueConf.select_ids
  self.bBlockEndAnimation = bBlockEnterAnimation
  self.bIsLastDialogue = true
  if DialogueUtils.SkipDialogue or DialogueUtils.SkipTyping then
    bBlockEnterAnimation = true
    self.bBlockEndAnimation = true
  elseif DialogueConf.next_dialog_id and 0 ~= DialogueConf.next_dialog_id then
    self.bIsLastDialogue = false
    local NextDialogueConf = _G.DataConfigManager:GetDialogueConf(DialogueConf.next_dialog_id)
    if NextDialogueConf and NextDialogueConf.ui_source_type == DialogueConf.ui_source_type then
      self.bBlockEndAnimation = true
    elseif DialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK and (not NextDialogueConf or NextDialogueConf and nil ~= NextDialogueConf.ui_source_type) then
      self.TriggerEndAnimOnPageEnd = true
      self.bBlockEndAnimation = false
    end
    if NextDialogueConf and NextDialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK_EXIT then
      self.bBlockEndAnimation = false
      self.TriggerEndAnimOnPageEnd = true
    end
  elseif DialogueConf.action and nil ~= DialogueConf.action.action_type then
    self.bBlockEndAnimation = true
  elseif not DialogueConf.next_dialog_id or 0 == DialogueConf.next_dialog_id then
    self.bBlockEndAnimation = self.DialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK_ENTER or self.DialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK_EXIT
    self.bIsLastDialogue = true
  end
  self.bShowTextInstant = 0 == DialogueConf.speed
  self.bShowTextInstant = true == self.bShowTextInstant or DialogueUtils.SkipDialogue or DialogueUtils.SkipTyping
  if self:GetEnterAnimation() and not bBlockEnterAnimation then
    self:PlayEnterAnimation()
  else
    DialogueUtils.CallAndRemoveCallback(self, "EnterCaller", "EnterCallback")
    if not DialogueUtils.SkipTyping and not DialogueUtils.SkipDialogue then
      self:OnSkipEnterAnimation()
    end
    self:Show(DialogueConf)
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").DIALOG
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
end

function DialoguePanelBase:Show(DialogueConf)
  self.CurLine = 1
  if not DialogueConf.text then
    self._texts = {}
  else
    local FullText = DialogueConf.text
    if ShowID and " " ~= FullText then
      FullText = string.format("%s(%d)", FullText, DialogueConf.id or 0)
    end
    self._texts = FullText:split(DialogueTextIndicators.PageSeparator)
  end
  self.NofSpaces = {}
  for i = 1, #self._texts do
    if DialogueConf.ui_source_type == Enum.UIsourceType.UIT_PANGBAI then
      self._texts[i] = self:FakeCenterAlign(self._texts[i])
    end
    self._texts[i] = self:PreprocessText(self._texts[i])
  end
  self.Replacer:BatchReplace(self._texts, TextReplaceContext(self.DialogueContext))
  if DialogueConf.select_auto_on then
    self.done = true
  else
    self.done = false
  end
  self._textIndex = 1
  self.clicked = false
  self.listening = true
  self._writeDelay = DialogueConf.speed / 1000
  self.TypeDone = false
  if self.bShowTextInstant then
    self:StartWriteInstant()
  else
    self:StartWrite()
  end
end

function DialoguePanelBase:DoPlayEndAnimation(caller, callback, InSourceType)
  Log.Debug("DialoguePanelBase:DoPlayEndAnimation", table.getKeyName(Enum.UIsourceType, InSourceType))
  if InSourceType == self.DialogueConf.ui_source_type or DialogueUtils.SkipDialogue or DialogueUtils.SkipTyping then
    callback(caller)
    self:SendFinishEvent()
  else
    self.caller = caller
    self.callback = callback
    self:PlayEndAnimation()
  end
end

function DialoguePanelBase:_SetNextIndicatorVisibility(visibility)
  if self.NextIndicator then
    if self.panelName == "DialogueAncient" then
      self.NextIndicator:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self:PlaySelectAnim()
    end
  end
end

function DialoguePanelBase:StartWrite()
  self.clicked = false
  self.TypeDone = false
  local WordPertype = 4
  if not self.DialogueConf.text_once == Enum.TextOnceType.TOT_ONEWORD then
    WordPertype = 1 * math.max(1, (math.round(0.03 / self._writeDelay)))
  end
  if self.bTranslate then
    self:WriteWithAcceleratingSpeed(WordPertype, self._writeDelay)
  else
    self:WriteWithGivenSpeed(WordPertype, self._writeDelay)
  end
end

function DialoguePanelBase:OnSkipEnterAnimation()
end

function DialoguePanelBase:StartWriteInstant()
  self.clicked = false
  self.TypeDone = false
  self:WriteWithGivenSpeed(1000, self._writeDelay)
end

function DialoguePanelBase:WriteWithAcceleratingSpeed(WordPerType, InitTypeInterval)
  local _newPageFlag = self._textIndexSinglePage > #self._textsPerClick
  if _newPageFlag then
    local textOnThisPage = self._texts[self._textIndex]
    textOnThisPage = textOnThisPage or ""
    self._textsPerClick = textOnThisPage:split(DialogueTextIndicators.NeedClick)
    self._textIndexSinglePage = 1
    if self.TypeWritter then
      self.TypeWritter:Init(InitTypeInterval, WordPerType, true)
    end
    self._textIndex = self._textIndex + 1
  end
  self._textIndexSinglePage = self._textIndexSinglePage + 1
  if self.TypeWritter then
    self.TypeWritter:WriteOnSamePageWithTranslation(self._textsPerClick[self._textIndexSinglePage - 1], nil, nil, self.DialogueConf.translate_end_string)
  end
end

function DialoguePanelBase:Tick(MyGeometry, InDeltaTime)
  self:CheckAutoPlay()
end

function DialoguePanelBase:WriteWithGivenSpeed(WordPerType, TypeInterval)
  local _newPageFlag = self._textIndexSinglePage > #self._textsPerClick
  if _newPageFlag then
    local textOnThisPage = self._texts[self._textIndex]
    textOnThisPage = textOnThisPage or ""
    self._textsPerClick = textOnThisPage:split(DialogueTextIndicators.NeedClick)
    self._textIndexSinglePage = 1
    if self.TypeWritter then
      self.TypeWritter:Init(TypeInterval, WordPerType)
    end
    self._textIndex = self._textIndex + 1
  end
  self._textIndexSinglePage = self._textIndexSinglePage + 1
  if self.TypeWritter then
    self.TypeWritter:WriteOnSamePage(self._textsPerClick[self._textIndexSinglePage - 1])
  end
end

function DialoguePanelBase:OnDialogueClick(bAutoPlay, bSync)
  if self.module and self.module.DialogueFsm and self.module.DialogueFsm:GetProperty("SpectatorMode", false) and not bSync then
    return
  end
  Log.DebugFormat("[DialogueFlow] DialoguePanelBase:OnDialogueClick, bAutoPlay = %s, DialogueID = %s, TypeDone = %s, done = %s, page = %d/%d, click =%d/%d", bAutoPlay, self.DialogueConf and self.DialogueConf.id or 0, self.TypeDone, self.done, self._textIndex, #self._texts, self._textIndexSinglePage, #self._textsPerClick)
  if self.AutoPlayDelayID and self.AutoPlayDelayID > 0 then
    _G.DelayManager:CancelDelayById(self.AutoPlayDelayID)
    self.AutoPlayDelayID = 0
  end
  if self.module then
    self.module:DispatchEvent(DialogueModuleEvent.DialogueClicked, self.DialogueConf)
  end
  if not bAutoPlay then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "DialoguePanelBase:OnDialogueClick")
  end
  if not self.TypeDone then
    return
  end
  if self.DialogueConf.id == 1302060 then
    NRCModeManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
    NRCModeManager:DoCmd(BattleUIModuleCmd.MainHideAll, true)
  end
  if not bSync and self._textIndex > #self._texts and self._textIndexSinglePage > #self._textsPerClick then
    local bClickIntercept = self.module and self.module.DialogueFsm and self.module.DialogueFsm:GetProperty("bClickIntercept", false) or false
    if bClickIntercept then
      Log.Debug("[DialogueFlow] DialoguePanelBase:OnDialogueClick, skip click as this is a intercept click")
      return
    end
  end
  self.clicked = true
  if self._textIndex > #self._texts and self._textIndexSinglePage > #self._textsPerClick then
    if not self.done then
      self.done = true
      if DialogueUtils.SkipTyping or DialogueUtils.SkipDialogue then
        self:SendFinishEvent()
      elseif self.DialogueConf.id and self.DialogueConf.id < 0 then
        self:SendFinishEvent()
      elseif self.DialogueConf.ui_source_type and self.DialogueConf.ui_source_type == Enum.UIsourceType.UIT_BLACK_EXIT then
        self:PlayEndAnimation()
      elseif self:GetEndAnimation() and self.bHasNoSelection then
        if (self.bIsLastDialogue or self.TriggerEndAnimOnPageEnd) and not self.bBlockEndAnimation then
          self:PlayEndAnimation()
        else
          self:SendFinishEvent()
        end
      else
        self:SendFinishEvent()
      end
    end
    return
  end
  self:StartWrite()
  self:SyncClick()
end

function DialoguePanelBase:OnTypeFinish()
  Log.Debug("DialoguePanelBase:OnTypeFinish", self.name, self.done)
  self.CurSentence = ""
  self.CurLine = self.CurLine + 1
  self.TypeDone = true
  if self.done then
    self:SendFinishEvent()
    return
  end
  self:OnSyncProgressUpdate()
  self:CheckAutoPlay(true)
end

function DialoguePanelBase:CheckAutoPlay(bTypeFinishCallback)
  if self.module and self.module.DialogueFsm and self.module.DialogueFsm:GetProperty("SpectatorMode", false) then
    return
  end
  if self.clicked then
    return
  end
  if self.AutoPlayDelayID and self.AutoPlayDelayID > 0 then
    return
  end
  local isInBattle = self.module and self.module.DialogueFsm and self.module.DialogueFsm:GetProperty("bInBattle", false)
  if _G.UserSettingManager:IsDialogueAutoPlayOn() and not isInBattle then
    if self.TypeDone then
      if self._textIndexSinglePage > #self._textsPerClick and self._textIndex > #self._texts then
        if not self.module:IsCurDialogueAudioPlaying() then
          local AutoPlayDelay = 0.0
          if not bTypeFinishCallback then
            AutoPlayDelay = _G.DataConfigManager:GetTaskGlobalConfig("dialogue_autoplay_time_sound")
            AutoPlayDelay = (AutoPlayDelay and AutoPlayDelay.num or 500.0) / 1000.0
          elseif self.DialogueConf and self.DialogueConf.select_ids and #self.DialogueConf.select_ids > 0 then
            AutoPlayDelay = _G.DataConfigManager:GetTaskGlobalConfig("dialogue_autoplay_time_separator")
            AutoPlayDelay = (AutoPlayDelay and AutoPlayDelay.num or 1000.0) / 1000.0
          else
            AutoPlayDelay = self.ExtraConf and self.ExtraConf.CustomAutoplayDelay
            if not AutoPlayDelay then
              AutoPlayDelay = _G.DataConfigManager:GetTaskGlobalConfig("dialogue_autoplay_time")
              AutoPlayDelay = (AutoPlayDelay and AutoPlayDelay.num or 4500.0) / 1000.0
            end
          end
          Log.DebugFormat("DialoguePanelBase:CheckAutoPlay, wait audio end, session ID = %d, delay = %f", self.module.CurDlgAudioSessionID or 0, AutoPlayDelay)
          self.AutoPlayDelayID = _G.DelayManager:DelaySeconds(AutoPlayDelay, self.OnAutoPlay, self)
        end
      elseif self.module:IsCurDialogueAudioPlaying() then
        local AudioProgressToClick = math.clamp((self._textIndex - 2) / #self._texts, 0.0, 1.0)
        AudioProgressToClick = AudioProgressToClick + math.clamp((self._textIndexSinglePage - 1) / #self._textsPerClick, 0.0, 1.0) / #self._texts
        local CurAudioProgress = self.module:GetCurDialogueAudioProgress()
        Log.DebugFormat("DialoguePanelBase:CheckAutoPlay, wait audio progress = %f, cur = %f, session id = %d", AudioProgressToClick, CurAudioProgress, self.module.CurDlgAudioSessionID or 0)
        if AudioProgressToClick <= CurAudioProgress then
          self:OnAutoPlay()
        end
      else
        local AutoPlayDelay = _G.DataConfigManager:GetTaskGlobalConfig("dialogue_autoplay_time_separator")
        AutoPlayDelay = (AutoPlayDelay and AutoPlayDelay.num or 1000.0) / 1000.0
        Log.DebugFormat("DialoguePanelBase:CheckAutoPlay, auto play next in one config with delay %f", AutoPlayDelay)
        self.AutoPlayDelayID = _G.DelayManager:DelaySeconds(AutoPlayDelay, self.OnAutoPlay, self)
      end
    elseif self.DialogueSelector and self.DialogueSelector:GetVisibility() ~= UE4.ESlateVisibility.Hidden and self.DialogueSelector:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
      local SelectOptions = self.module.DialogueFsm:GetProperty("Options")
      local bAnyDefaultOption = false
      for _, Option in ipairs(SelectOptions) do
        if Option.select_skip then
          bAnyDefaultOption = true
          break
        end
      end
      if bAnyDefaultOption then
        local AutoPlayDelay = _G.DataConfigManager:GetTaskGlobalConfig("dialogue_autoplay_time")
        AutoPlayDelay = (AutoPlayDelay and AutoPlayDelay.num or 1000.0) / 1000.0
        self.AutoPlayDelayID = _G.DelayManager:DelaySeconds(AutoPlayDelay, self.OnAutoPlay, self)
      end
    end
  end
end

function DialoguePanelBase:OnDialogueAutoPlayChanged()
  if self.AutoPlayDelayID and self.AutoPlayDelayID > 0 then
    _G.DelayManager:CancelDelayById(self.AutoPlayDelayID)
    self.AutoPlayDelayID = 0
  end
end

function DialoguePanelBase:OnAutoPlay()
  self.AutoPlayDelayID = 0
  self:OnDialogueClick(true)
end

function DialoguePanelBase:ShowOptions(selectConfs, Option)
end

function DialoguePanelBase:OnPlayEnterAnimation()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function DialoguePanelBase:OnAnimationFinished(animation)
  if not self.Inited then
    return
  end
  if animation == self:GetEnterAnimation() then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self:Show(self.DialogueConf)
    self.bIsClosing = false
    DialogueUtils.CallAndRemoveCallback(self, "EnterCaller", "EnterCallback")
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  elseif animation == self:GetEndAnimation() then
    if self.callback and self.caller then
      DialogueUtils.CallAndRemoveCallback(self, "caller", "callback")
    else
      self:SendFinishEvent()
    end
    self:Disable()
  elseif self.done and animation == self.Ani_click2 then
  else
    Log.Debug("Dialog not finished")
  end
end

function DialoguePanelBase:SendFinishEvent()
  if self.listening then
    Log.Debug("DialoguePanelBase:SendFinishEvent, ", self.DialogueConf and self.DialogueConf.id or 0)
    self.module:DispatchEvent(DialogueModuleEvent.DialogueTalkFinished, self.DialogueConf)
  end
  self.listening = false
end

function DialoguePanelBase:OnPlayEndAnimation()
  if self.TypeWritter and UE.UObject.IsValid(self.TypeWritter) then
    self.TypeWritter:Clear()
  end
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function DialoguePanelBase:Enable()
  NRCPanelBase.Enable(self)
  if self.module and self.module._currentMainPanel == self.panelName then
    self.module.PanelOn = true
  end
end

function DialoguePanelBase:Disable()
  self.Inited = false
  self:StopAllAnimations()
  NRCPanelBase.Disable(self)
  if self.module and self.module._currentMainPanel == self.panelName then
    self.module.PanelOn = false
  end
end

function DialoguePanelBase:OnDisable()
  self.Inited = false
  self:StopAllAnimations()
  if self.TypeWritter and UE.UObject.IsValid(self.TypeWritter) and self.TypeWritter.Clear then
    self.TypeWritter:Clear()
  end
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function DialoguePanelBase:SetVisibility(...)
  self.Overridden.SetVisibility(self, ...)
end

function DialoguePanelBase:IsTypeFinish()
  return self.TypeDone and self._textIndexSinglePage > #self._textsPerClick and self._textIndex > #self._texts
end

function DialoguePanelBase:SyncClick()
  if self.module and self.DialogueContext and self.DialogueContext.config and not self.DialogueContext.config.dialogue_transmission_2P then
    local progress = self._textIndexSinglePage + self._textIndex * 10
    self.module:SyncProgress(self.DialogueConf and self.DialogueConf.id or 0, progress)
  end
end

function DialoguePanelBase:OnSyncProgressUpdate()
  if self.TypeDone and self.module and self.module.DialogueFsm and self.module.DialogueFsm:GetProperty("SpectatorMode", false) then
    local Progress = self.module.DialogueFsm:GetProperty("Progress", 22)
    local ProgressPage = math.floor(Progress / 10)
    local ProgressClick = Progress % 10
    if 0 == Progress or ProgressPage > self._textIndex or self._textIndex == ProgressPage and ProgressClick > self._textIndexSinglePage then
      self:OnDialogueClick(false, true)
    end
  end
end

return DialoguePanelBase

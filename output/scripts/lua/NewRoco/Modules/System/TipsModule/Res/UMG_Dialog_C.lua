local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local UMG_Dialog_C = _G.NRCPanelBase:Extend("UMG_Dialog_C")
local CLICK_INTERVAL = 1

function UMG_Dialog_C:OnActive(...)
  NRCPanelBase.OnActive(self, ...)
  if not UE.UObject.IsValid(self) then
    Log.Error("UMG_Dialog_C:OnActive, self is invalid")
    return
  end
  self:OnInit()
  local ArgContext = (...)
  self.contextData = ArgContext
  self.IsOnClickOK = false
  self.Btn1:SetBtnText(LuaText.umg_dialog_1)
  if nil == ArgContext[1] then
    self.BIGBT:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn2:SetBtnText(LuaText.umg_dialog_2)
  else
    self.BIGBT:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnInVisible)
  self:OnAddEventListener()
  self:OnBeforeOpen()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400007, "UMG_Dialog_C:OnActive")
end

function UMG_Dialog_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("DialogContext", self, _G.NRCGlobalEvent.OnNetworkStatusTurnToWifi, self.OnNetworkStatusTurnToWifi)
  self.LastClickTime = {}
end

function UMG_Dialog_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnNetworkStatusTurnToWifi, self.OnNetworkStatusTurnToWifi)
end

function UMG_Dialog_C:OnEnable()
  UE4Helper.SetDesiredShowCursor(true, "UMG_Dialog_C")
  self:BindInputAction()
  if TUIModuleCmd then
    self.bgProxy = _G.NRCModuleManager:DoCmd(TUIModuleCmd.PushBlackBackgroundWidgets, {
      self.NRCImage_35,
      self.NRCImage_17
    }, {
      [self.NRCImage_35] = true
    })
  end
  local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
  if PlayerModule and PlayerModule.playerModuleData then
    PlayerModule.playerModuleData.playerCtrlEnable = false
  end
end

function UMG_Dialog_C:OnDisable()
  UE4Helper.ReleaseDesiredShowCursor("UMG_Dialog_C")
  self:UnBindInputAction()
  if self.bgProxy then
    _G.NRCModuleManager:DoCmd(TUIModuleCmd.PopBlackBackgroundWidgets, self.bgProxy)
  end
  local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
  if PlayerModule and PlayerModule.playerModuleData then
    PlayerModule.playerModuleData.playerCtrlEnable = true
  end
  if self.isOnlyForNetwork then
    if self:IsActive() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_SetOnlyForNetworkDialogClosed)
    end
  else
    NRCModuleManager:DoCmd(TipsModuleCmd.CheckIFHasShouldOpenDialog)
  end
  if self.context and self.context.bCancelAnyway and self.listenHandler then
    if self.listener then
      if not self.listener.WidgetTreeRef or UE.UObject.IsValid(self.listener) then
        self.listenHandler(self.listener)
      end
    else
      self.listenHandler(false)
    end
  end
end

function UMG_Dialog_C:BindInputAction()
  self:OnAddDynamicIMC()
end

function UMG_Dialog_C:UnBindInputAction()
  self:OnRemoveDynamicIMC()
end

function UMG_Dialog_C:OnPcClose()
  if self.context and not self.context.bBlockPcEsc then
    self:OnClickCancelButton(CommonBtnEnum.DialogCancelType.NullClickType)
  end
end

function UMG_Dialog_C:OnDeactive()
end

function UMG_Dialog_C:OnNetworkStatusTurnToWifi()
  if self.context and self.context:GetAutoCloseOnWifiBtnHandlerType() ~= DialogContext.EAutoCloseOnWifiBtnHandlerType.None then
    if self.context:GetAutoCloseOnWifiBtnHandlerType() == DialogContext.EAutoCloseOnWifiBtnHandlerType.OK then
      Log.Debug("[UMG_Dialog_C:OnNetworkStatusTurnToWifi] auto click OK button")
      self:OnClickOkButton(true)
    elseif self.context:GetAutoCloseOnWifiBtnHandlerType() == DialogContext.EAutoCloseOnWifiBtnHandlerType.CANCEL then
      self:OnClickCancelButton(CommonBtnEnum.DialogCancelType.BtnClickType, nil, true)
      Log.Debug("[UMG_Dialog_C:OnNetworkStatusTurnToWifi] auto click CANCEL button")
    end
  end
end

function UMG_Dialog_C:OnInit()
  if self.context then
    self.context:RemoveEventListener(self, TipsModuleEvent.Tips_CloseDialogue, self.TryClose)
  end
  self.context = nil
  self.listener = nil
  self.listenHandler = nil
  self.listenerOK = nil
  self.listenHandlerOK = nil
  self.isClosing = false
  self.isCountdown = false
  self.countdownTimer = nil
  self.countdownBtnMode = nil
  self.countdownBtnText = nil
  self.isPopup = false
  self.RichTextListener = nil
  self.RichTextListenerHandler = nil
end

function UMG_Dialog_C:OnAddEventListener()
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnClickOkButton)
  self:AddButtonListener(self.Btn1.btnLevelUp, self.OnClickCancelButton)
  if self.btnClose then
    self:AddButtonListener(self.btnClose.btnClose, self.OnCloseBtnClick)
  end
  self:AddButtonListener(self.BIGBT, self.GlobalCloseClick)
  self:AddButtonListener(self.Btn_GlobalClose, self.OnBtnGlobalClose)
  if self.MoneyBtn then
    self:AddButtonListener(self.MoneyBtn.ShowStarChainTimeBtn, self.ClosePanel)
  end
  if self.ContentText_2 and self.ContentText_2.OnRichTextClick then
    self:AddDelegateListener(self.ContentText_2.OnRichTextClick, self.OnContentText2RichTextClick)
  end
end

function UMG_Dialog_C:OnBtnGlobalClose()
  if not self:CheckAndRecordClick("BtnGlobalClose") then
    return
  end
  self:OnClickCancelButton(CommonBtnEnum.DialogCancelType.NullClickType)
end

function UMG_Dialog_C:OnCloseBtnClick()
  if not self:CheckAndRecordClick("CloseBtn") then
    return
  end
  self:OnClickCancelButton(CommonBtnEnum.DialogCancelType.CloseClickType)
end

function UMG_Dialog_C:GlobalCloseClick()
  if not self:CheckAndRecordClick("GlobalClose") then
    return
  end
  local CancelType = CommonBtnEnum.DialogCancelType.NullClickType
  self:OnClickCancelButton(CancelType, self.context:GetIsNoEffect())
end

function UMG_Dialog_C:OnContentText2RichTextClick(key)
  if self.RichTextListenerHandler then
    if self.RichTextListener then
      if not self.RichTextListener.WidgetTreeRef or UE.UObject.IsValid(self.RichTextListener) then
        self.RichTextListenerHandler(self.RichTextListener, key)
      end
    else
      self.RichTextListenerHandler(key)
    end
  end
end

function UMG_Dialog_C:OnBeforeOpen()
  self:SetContext(self.contextData)
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:LoadAnimation(0)
end

function UMG_Dialog_C:TryOpen()
  if self.enableView ~= true or self.isClosing then
    self:Enable()
    self:StopAllAnimations()
    _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
    self:LoadAnimation(0)
  end
  self.isClosing = false
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400007, "UMG_Dialog_C:OnActive")
end

function UMG_Dialog_C:SetContext(context)
  if not context then
    return
  end
  self.isOnlyForNetwork = context:IsOnlyForNetwork()
  if self.context and self.context.RemoveEventListener then
    self.context:RemoveEventListener(self, TipsModuleEvent.Tips_CloseDialogue, self.OnClickCancelButton)
  end
  self.context = context
  if self.context and self.context.AddEventListener then
    self.context:AddEventListener(self, TipsModuleEvent.Tips_CloseDialogue, self.OnClickCancelButton)
  end
  self:SetContent(context.title, context.content, context.contentTextJustify)
  if self.Spacer and self.ContentText_2 then
    self:SetContent2(context.content2)
  end
  self:RegisterCallback(context.listener, context.listenHandler)
  self:RegisterCallbackOk(context.listenerOk, context.listenHandlerOk)
  self:RegisterCallbackRichText(context.RichTextListener, context.RichTextListenerHandler)
  self:SetButtonText(context.okText, context.cancelText)
  self:SetDebugInfo(context.debugInfo)
  if context.clickAnywhereClose then
    self.BIGBT:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn_GlobalClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if context.mode == context.Mode.OK then
    if self.CanvasPanel_86 then
      self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Btn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.CanvasPanel_103 then
      self.CanvasPanel_103:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Btn2:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif context.mode == context.Mode.OK_CANCEL then
    if self.CanvasPanel_86 then
      self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Btn1:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.CanvasPanel_103 then
      self.CanvasPanel_103:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.Btn1:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif context.mode == context.Mode.NotBtn then
    self.CanvasPanel_103:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_GlobalClose:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.btnClose then
    if self.context.bIfHideCloseBtn then
      self.btnClose:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
      self.btnClose:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
  if context.bForceEnableFullScreen then
    self.Btn_GlobalClose:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if UE4.UKismetSystemLibrary.IsValid(self.NRCSwitcher_1) then
    if -1 == context.toppingType then
      self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Visible)
      self.NRCSwitcher_1:SetActiveWidgetIndex(context.toppingType)
    end
  end
  if self.MoneyBtn then
    self:SetMoneyBtn()
  end
  self.Btn1.Title_Second:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn2.Title_Second:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetCountdown(context)
  if self.ScrollBox_63 then
    self.ScrollBox_63:SetScrollOffset(0)
  end
end

function UMG_Dialog_C:SetCountdown(context)
  if context.countdownTime and context.countdownTime > 0 then
    self.isCountdown = true
    self.countdownTimer = context.countdownTime
    self.countdownBtnMode = context.countdownBtnMode
    self.countdownBtnText = ""
    if context.countdownBtnMode == context.Mode.OK then
      self.countdownBtnText = context.okText
    elseif context.countdownBtnMode == context.Mode.CANCEL then
      self.countdownBtnText = context.cancelText
    end
  end
end

function UMG_Dialog_C:SetCountdownButtonText(DeltaTime)
  if self.isCountdown == false then
    return
  end
  if self.countdownTimer then
    self.countdownTimer = self.countdownTimer - DeltaTime
  end
  if self.countdownTimer and self.countdownTimer > 0 then
    local timer = math.floor(self.countdownTimer)
    timer = "(" .. timer .. "s)"
    local text = self.countdownBtnText
    if self.countdownBtnMode == DialogContext.Mode.OK then
      self.Btn2:SetBtnText(text)
      self.Btn2.Title_Second:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn2.Title_Second:SetText(timer)
    elseif self.countdownBtnMode == DialogContext.Mode.CANCEL then
      self.Btn1:SetBtnText(text)
      self.Btn1.Title_Second:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn1.Title_Second:SetText(timer)
    end
  else
    self.isCountdown = false
    if self.listenHandler or self.listenHandlerOK then
      if not self.isClosing then
        if self.countdownBtnMode == DialogContext.Mode.OK then
          if self.listenHandlerOK then
            if self.listenerOK then
              self.listenHandlerOK(self.listenerOK, true)
            else
              self.listenHandlerOK(true)
            end
          end
          if self.listenHandler then
            if self.listener then
              self.listenHandler(self.listener, true)
            else
              self.listenHandler(true)
            end
          end
        elseif self.countdownBtnMode == DialogContext.Mode.CANCEL and self.listenHandler then
          if self.listener then
            self.listenHandler(self.listener, false)
          else
            self.listenHandler(false)
          end
        end
      end
      self:TryClose()
    end
  end
end

function UMG_Dialog_C:SetContent(title, content, contentTextJustify)
  if string.IsNilOrEmpty(title) then
    self.TitleText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.CanvasPanel_114 then
      self.CanvasPanel_114:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.BIGBT:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TitleText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.TitleText:SetText(title)
    if self.CanvasPanel_114 then
      self.CanvasPanel_114:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
  if string.IsNilOrEmpty(content) then
    self.ContentText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ContentText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ContentText:SetText(content)
  end
  if contentTextJustify then
    self.ContentText:SetJustification(contentTextJustify)
  end
end

function UMG_Dialog_C:SetContent2(content2)
  if not self.ContentText_2 or not self.Spacer then
    return
  end
  if string.IsNilOrEmpty(content2) then
    self.Spacer:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ContentText_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Spacer:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ContentText_2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ContentText_2:SetText(content2)
  end
end

function UMG_Dialog_C:SetDebugInfo(debugInfo)
  if not RocoEnv.IS_SHIPPING and debugInfo then
    self.DebugInfoText:SetText("DebugInfo: " .. debugInfo)
  else
    self.DebugInfoText:SetText("")
  end
end

function UMG_Dialog_C:SetButtonText(okTxt, cancelTxt)
  if okTxt then
    self.Btn2:SetBtnText(okTxt)
  else
    self.Btn2:SetBtnText(LuaText.tips_dialog_butten_accept)
  end
  if cancelTxt then
    self.Btn1:SetBtnText(cancelTxt)
  else
    self.Btn1:SetBtnText(LuaText.tips_dialog_butten_cancel)
  end
end

function UMG_Dialog_C:RegisterCallback(listener, listenHandler)
  self.listener = listener
  self.listenHandler = listenHandler
end

function UMG_Dialog_C:RegisterCallbackOk(listener, listenHandler)
  self.listenerOK = listener
  self.listenHandlerOK = listenHandler
end

function UMG_Dialog_C:RegisterCallbackRichText(listener, listenHandler)
  self.RichTextListener = listener
  self.RichTextListenerHandler = listenHandler
end

function UMG_Dialog_C:OnClickOkButton(bNoSound)
  if not self:CheckAndRecordClick("BtnOk") then
    return
  end
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  self.isCountdown = false
  if not bNoSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Dialog_C:OnClickOkButton")
  end
  self:DelaySeconds(0.1, function()
    self.IsOnClickOK = true
    if self.listenHandler then
      if self.listener then
        if not self.listener.WidgetTreeRef or UE.UObject.IsValid(self.listener) then
          self.listenHandler(self.listener, true)
        end
      else
        self.listenHandler(true)
      end
    end
    if self.listenHandlerOK then
      if self.listenerOK then
        if not self.listenerOK.WidgetTreeRef or UE.UObject.IsValid(self.listenerOK) then
          self.listenHandlerOK(self.listenerOK, true)
        end
      else
        self.listenHandlerOK(true)
      end
    end
    if self.context and self.context.autoCloseOnOk then
      self:TryClose()
    end
    if self.context and self.context.RemoveEventListener then
      self.context:RemoveEventListener(self, TipsModuleEvent.Tips_CloseDialogue, self.OnClickCancelButton)
    end
  end)
end

function UMG_Dialog_C:OnClickCancelButton(_CancelType, IsNoEffect, bNoSound)
  if not self:CheckAndRecordClick("BtnCancel") then
    return
  end
  self.isCountdown = false
  if not bNoSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Dialog_C:OnClickCancelButton")
  end
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  self:CancelDelay()
  self:DelaySeconds(0.1, function()
    local CancelType = _CancelType or CommonBtnEnum.DialogCancelType.BtnClickType
    self.IsOnClickOK = false
    if self.listenHandler then
      if self.listener then
        if not self.listener.WidgetTreeRef or UE.UObject.IsValid(self.listener) then
          self.listenHandler(self.listener, false, CancelType, IsNoEffect)
        end
      else
        self.listenHandler(false, CancelType, IsNoEffect)
      end
    end
    if self.context and self.context.autoCloseOnCancel then
      self:TryClose()
    end
  end)
end

function UMG_Dialog_C:TryClose()
  self:Log("TryClose")
  self.isClosing = true
  self:UnBindInputAction()
  self:StopAllAnimations()
  self:LoadAnimation(2)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400008, "UMG_Dialog_C:OnAnimationFinished")
end

function UMG_Dialog_C:OnAnimationFinished(anima)
  self:Log("OnAnimationFinished")
  if anima == self:GetAnimByIndex(2) and self.isClosing == true then
    if self.context then
      self.module:OnDialogFinished(self.context.bReconnect)
      if self.context.RemoveEventListener then
        self.context:RemoveEventListener(self, TipsModuleEvent.Tips_CloseDialogue, self.OnClickCancelButton)
      end
    end
    self.context = nil
    self.listener = nil
    self.listenHandler = nil
    self:Disable()
    self.isClosing = false
    self.IsOnClickOK = false
  elseif anima == self:GetAnimByIndex(0) then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

function UMG_Dialog_C:ClosePanel()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_MiniGame_GiveUp_C:OnBigBtn")
  self:DoClose()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Player.inputComponent:SetCameraControlEnable(self, true)
end

function UMG_Dialog_C:SetMoneyBtn()
  local consumeItemType = self.context.okConsumeItemType
  if nil ~= consumeItemType then
    if self.context.BanFullScreenBtn == true then
      self.BIGBT:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Btn_GlobalClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.context.BanFullScreenBtn == false then
      self.BIGBT:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Btn_GlobalClose:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if consumeItemType == _G.Enum.VisualItem.VI_LEGENDARY_COIN then
      local costItemId = _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num
      local starNum = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, costItemId)
      if nil == starNum then
        starNum = 0
      else
        starNum = starNum.num
      end
      self.MoneyBtn:SetInfo(costItemId, starNum, true)
      self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.MoneyBtn:SetSourceReturnFlagAndFunc(true, self.context.ReOpenFunc)
      self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.Visible)
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(costItemId)
      self.CurrencyIcon:SetPath(NRCUtils:FormatConfIconPath(bagItemConf.icon, _G.UIIconPath.BagItemPath))
      self.CurrencyText:SetText(self.context.okConsumeItemCost)
    end
    if consumeItemType == _G.Enum.VisualItem.VI_DIAMOND then
      self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local vItemsConf = _G.DataConfigManager:GetVisualItemConf(Enum.VisualItem.VI_DIAMOND)
      self.CurrencyIcon:SetPath(vItemsConf.bigIcon)
      self.CurrencyText:SetText(self.context.okConsumeItemCost)
    end
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Dialog_C:OnTick(DeltaTime)
  self:SetCountdownButtonText(DeltaTime)
end

function UMG_Dialog_C:CheckAndRecordClick(btnName)
  local currentTime = _G.UpdateManager.Timestamp
  if self.LastClickTime[btnName] and currentTime - self.LastClickTime[btnName] < CLICK_INTERVAL then
    return false
  end
  self.LastClickTime[btnName] = currentTime
  return true
end

return UMG_Dialog_C

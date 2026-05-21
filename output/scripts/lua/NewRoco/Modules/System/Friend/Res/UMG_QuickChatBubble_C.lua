local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local UMG_QuickChatBubble_C = _G.NRCPanelBase:Extend("UMG_QuickChatBubble_C")

function UMG_QuickChatBubble_C:OnConstruct()
  UE4Helper.SetDesiredShowCursor(true, "UMG_QuickChatBubble_C")
  self.data = self.module:GetData("FriendModuleData")
  self.data:SetCurChatUin(_G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM)
  self.InputBox:SetText(self.data:GetQuickChatTemporaryInput())
  self:OnAddEventListener()
  self:PlayAnimation(self.Textbox_in)
  self.IsClose = false
  self.lastClickSendTime = nil
  _G.NRCAudioManager:PlaySound2DAuto(40004007, "UMG_QuickChatBubble_C:OnConstruct")
end

function UMG_QuickChatBubble_C:OnDestruct()
  self:SetInputEnable(false)
  UE4Helper.ReleaseDesiredShowCursor("UMG_QuickChatBubble_C")
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CloseQuickChat)
end

function UMG_QuickChatBubble_C:OnActive()
  self.InputBox:SetFocus()
  self.RedDot:SetupKey(423)
  self.QuickChat:SetRedDot(83)
  self:BindInputAction()
  self:ChangeChatGvoiceVisibility(false)
  _G.NRCPanelManager.layerCenter:SendEvent(UILayerEvent.BREAKRIDESKILL_LAYER_OPENWINDOW)
  self.module:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.QuickChatFlag, true)
  _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.QuickChatOpen)
end

function UMG_QuickChatBubble_C:OnDeactive()
  if self.module then
    self.module:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.QuickChatFlag, false)
  end
  if self.data then
    self.data:SetQuickChatTemporaryInput(self.InputBox:GetText())
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenEmoMainPanel, 1, false)
  if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
    UE4.UNRCStatics.ClearKeyboardFocus()
    Log.Debug("UMG_QuickChatBubble_C:OnDeactive ClearKeyboardFocus")
  end
  self:ChangeChatGvoiceVisibility(false)
  self:RemoveButtonListener(self.QuickChat.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.ManuiOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.ManuiClose)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.ChangeChatGvoiceVisibility, self.ChangeChatGvoiceVisibility)
  _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.QuickChatClose)
end

function UMG_QuickChatBubble_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Send.btnLevelUp, self.OnSendBtn)
  self:AddButtonListener(self.Btn_paste, self.OnClickBtn_paste)
  self:AddButtonListener(self.EditBtn, self.OnClickEditBtn)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtn)
  self:AddButtonListener(self.QuickChat.btnLevelUp, self.OnOpenChatPanel)
  self:AddButtonListener(self.Btn_Gvoice, self.OpenGvoicePanel)
  self:RegisterEvent(self, FriendModuleEvent.OnSendChatMessageSucc, self.OnSendChatMessageSucc)
  _G.NRCEventCenter:RegisterEvent("UMG_QuickChatBubble_C", self, MainUIModuleEvent.MAINUIOPEN, self.ManuiOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_QuickChatBubble_C", self, MainUIModuleEvent.MAINUICLOSE, self.ManuiClose)
  _G.NRCEventCenter:RegisterEvent("UMG_QuickChatBubble_C", self, FriendModuleEvent.ChangeChatGvoiceVisibility, self.ChangeChatGvoiceVisibility)
  self.InputBox.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  self.InputBox.OnTextCommitted:Add(self, self.OnTextCommitted)
  self.InputBox.OnFocusChanged:Add(self, self.OnInputFocusChanged)
end

function UMG_QuickChatBubble_C:ChangeChatGvoiceVisibility(IsVisibility)
  if self.ChatGvoice then
    if IsVisibility and not self.ChatGvoice:IsVisible() then
      local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.RecordAudio)
      if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
        bGranted = true
      end
      if bGranted then
        self.ChatGvoice:OnInitialize(self.data.CurChatUin)
        self.ChatGvoice:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.ChatGvoice:PlayerAnimIn()
        self.ChatGvoice:StartActive()
      else
        self.RequestPermission = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.RecordAudio, {
          self,
          function(_, bGranted)
            self.RequestPermission = nil
            if bGranted then
              self:ChangeChatGvoiceVisibility(true)
            else
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_gvoice_microphone_premission_not_open)
            end
          end
        })
      end
    else
      self.ChatGvoice:ChangeRegisterVoiceEvent(false)
      self.ChatGvoice:OnAddEventListener(false)
      if self.ChatGvoice.IsRecording then
        local Result = _G.GVoiceManager:StopRecording(false)
      end
      self.ChatGvoice:IsWaitSpeechFalse()
      self.ChatGvoice:RestChatGvoiceState()
      self.ChatGvoice:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_QuickChatBubble_C:ManuiOpen()
end

function UMG_QuickChatBubble_C:ManuiClose()
  self.module:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.QuickChatFlag, false)
  self:PlayAnimation(self.Textbox_out)
end

function UMG_QuickChatBubble_C:OnTextCommitted(text, type)
  if type == UE4.ETextCommit.OnEnter and not self:QuantityExtraction(text) then
    self:OnSendBtn()
  end
end

function UMG_QuickChatBubble_C:OnInputFocusChanged(bFocused)
  self:SetInputEnable(bFocused)
end

function UMG_QuickChatBubble_C:SetInputEnable(bEnable)
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if bEnable then
    if localPlayer then
      localPlayer.inputComponent:SetInputEnable(self, false, "UMG_QuickChatBubble_C")
    end
  elseif localPlayer then
    localPlayer.inputComponent:SetInputEnable(self, true, "UMG_QuickChatBubble_C")
  end
end

function UMG_QuickChatBubble_C:OnTextChanged()
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if self._isPinYin then
    return
  end
  local text = self.InputBox:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1072, "UMG_Friend_Chitchat_C:OnTextChanged")
  local maxLength = _G.DataConfigManager:GetFriendGlobalConfig("friend_message_num_max").num
  local text_1 = self.InputBox:GetText()
  local text_2 = self.module:RemoveEmoji(text_1)
  local textLen = string.StringGetTotalNum(text_2)
  local MaxContent, curLen = string.GetSubStr(text_2, maxLength)
  if maxLength < textLen then
    self.InputBox:SetText(MaxContent)
    local tips = _G.DataConfigManager:GetLocalizationConf("Shurufa_Toolong").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  elseif text_1 ~= text_2 then
    self.InputBox:SetText(text_2)
  end
end

function UMG_QuickChatBubble_C:QuantityExtraction(Text)
  local maxLength = _G.DataConfigManager:GetFriendGlobalConfig("friend_message_num_max").num
  local text_2 = self.module:RemoveEmoji(Text)
  local textLen = string.StringGetTotalNum(text_2)
  local MaxContent, curLen = string.GetSubStr(text_2, maxLength)
  if maxLength < textLen then
    if text_2 ~= MaxContent then
      self.InputBox:SetText(MaxContent)
    end
    local tips = _G.DataConfigManager:GetLocalizationConf("Shurufa_Toolong").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
    return true
  elseif Text ~= text_2 then
    self.InputBox:SetText(text_2)
  end
  return false
end

function UMG_QuickChatBubble_C:OnTextEndTransaction()
  self._isPinYin = false
  self:OnTextChanged()
end

function UMG_QuickChatBubble_C:OnSendBtn()
  self.Btn_Send:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Friend_Chitchat_C:OnClickSendBtn")
  local text = self.InputBox:GetText()
  if "" == text or nil == text then
    local tip = _G.DataConfigManager:GetLocalizationConf("chat_message_send_empty_tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip)
    self.Btn_Send:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif self:IsCheckSendTime() then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SendChatMessage, _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM, text)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_message_send_CD)
    self.Btn_Send:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_QuickChatBubble_C:IsCheckSendTime()
  if self.lastClickSendTime then
    local cd = self.data:GetSendMultipleChatCD()
    local curTime = UE4.UNRCStatics.GetMilliSeconds()
    if cd > curTime - self.lastClickSendTime then
      return false
    else
      self.lastClickSendTime = curTime
      return true
    end
  else
    self.lastClickSendTime = UE4.UNRCStatics.GetMilliSeconds()
    return true
  end
  return true
end

function UMG_QuickChatBubble_C:OnClickBtn_paste()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008003, "UMG_Friend_Chitchat_C:OnClickBtn_paste")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenEmoMainPanel, 1, true, FriendEnum.ChatMode.QuickAnnouncement)
end

function UMG_QuickChatBubble_C:OnClickEditBtn()
end

function UMG_QuickChatBubble_C:OnSendChatMessageSucc(bSucc, uin, IsEmo)
  if not IsEmo then
    self.InputBox:SetText("")
  end
  self.Btn_Send:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.InputBox:SetFocus()
end

function UMG_QuickChatBubble_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_CloseQuickChat")
  if mappingContext then
    local actions = {
      {
        name = "IA_CloseQuickChat",
        method = "OnPcClose2"
      },
      {
        name = "IA_QuickChat_Jump",
        method = "OnOpenChatPanel"
      },
      {
        name = "IA_QuickChat_Send",
        method = "OnSendBtn"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
    self.QuickChat:SetPCKey("IA_QuickChat_Jump")
    self.Btn_Send_PCKey:SetIAName("IA_QuickChat_Send")
    self.CloseBtn_PCKey:SetIAName("IA_CloseQuickChat")
  else
    Log.Error("IMC_CloseQuickChat  is nil")
  end
end

function UMG_QuickChatBubble_C:OnOpenChatPanel()
  NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdSetIsPanelMoveCamera, true)
  NRCModuleManager:DoCmd(MainUIModuleCmd.TryOpenChatPanel, true)
end

function UMG_QuickChatBubble_C:OpenGvoicePanel()
  if self.ChatGvoice and not self.ChatGvoice:IsVisible() then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_QuickChatBubble_C:OpenGvoicePanel")
    self:ChangeChatGvoiceVisibility(true)
  end
end

function UMG_QuickChatBubble_C:OnPcClose2()
  if self.ChatGvoice and self.ChatGvoice:IsVisible() then
    self:ChangeChatGvoiceVisibility(false)
    return
  end
  if self:IsPlayingAnimation() then
    return
  end
  self:OnCloseBtn()
end

function UMG_QuickChatBubble_C:OnCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_QuickChatBubble_C:OnCloseBtn")
  self:PlayAnimation(self.Textbox_out)
end

function UMG_QuickChatBubble_C:OnPcClose()
  if self.ChatGvoice and self.ChatGvoice:IsVisible() then
    self:ChangeChatGvoiceVisibility(false)
    return
  end
  self:OnCloseBtn()
end

function UMG_QuickChatBubble_C:ClosePanel()
  self:DoClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_QuickChatBubble_C:ClosePanel")
end

function UMG_QuickChatBubble_C:OnAnimationFinished(Anim)
  if Anim == self.Textbox_out then
    self:DoClose()
  end
end

return UMG_QuickChatBubble_C

local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local UMG_Friend_Chitchat_C = _G.NRCPanelBase:Extend("UMG_Friend_Chitchat_C")
UMG_Friend_Chitchat_C.RefreshType = {
  All = 1,
  Receive = 2,
  Send = 3,
  Remove = 4
}

local function MergeSortedArray(arr1, arr2, comp, ignore)
  local function filter_array(arr)
    local filtered = {}
    
    for _, v in ipairs(arr) do
      if not ignore or not ignore(v) then
        table.insert(filtered, v)
      end
    end
    return filtered
  end
  
  arr1 = arr1 or {}
  arr2 = arr2 or {}
  local filtered1 = ignore and filter_array(arr1) or arr1
  local filtered2 = ignore and filter_array(arr2) or arr2
  comp = comp or function(a, b)
    return a < b
  end
  local merged = {}
  local i, j = 1, 1
  while i <= #filtered1 and j <= #filtered2 do
    if comp(filtered1[i], filtered2[j]) then
      table.insert(merged, filtered1[i])
      i = i + 1
    else
      table.insert(merged, filtered2[j])
      j = j + 1
    end
  end
  while i <= #filtered1 do
    table.insert(merged, filtered1[i])
    i = i + 1
  end
  while j <= #filtered2 do
    table.insert(merged, filtered2[j])
    j = j + 1
  end
  return merged
end

local function ChatMessageSortImpl(a, b)
  if a.time_stamp and b.time_stamp then
    return a.time_stamp < b.time_stamp
  end
end

function UMG_Friend_Chitchat_C:OnConstruct()
  self.data = self.module:GetData("FriendModuleData")
  self:SetChildViews(self.FriendMore)
  self:OnAddEventListener()
  self:BindInputAction()
  self.Name_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RemarkName:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemList_Friend_1:InitList({})
  self.bScrollToStart = false
  self.bScrollToEnd = false
  self.maxShowNum = 100
  self.curStartIndex = 1
  self.curEndIndex = 1
  self.bInit = false
  self.lastClickSendTime = nil
  self.isFirstOpenPanel = true
  if RocoEnv.PLATFORM_WINDOWS then
    self.NRCSwitcher_110:SetActiveWidgetIndex(1)
    self.MultipleLines:SetText(self.data:GetTemporaryInput())
  else
    self.NRCSwitcher_110:SetActiveWidgetIndex(0)
    self.InputBox:SetText(self.data:GetTemporaryInput())
  end
end

function UMG_Friend_Chitchat_C:UpdatePanelInfo(Uin, param2, bOpenByQuickChat, bOpenInBattle)
  self:OnActive(Uin, param2, bOpenByQuickChat, bOpenInBattle)
end

function UMG_Friend_Chitchat_C:OnActive(uin, resLoadData, bOpenByQuickChat, bOpenInBattle)
  local LatestChatSessionUin = self.data:GetLatestChatSessionUin()
  self.bOpenByQuickChat = bOpenByQuickChat
  self.bOpenInBattle = bOpenInBattle
  if self.bOpenInBattle then
    self.CanvasPanel_459:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.QuickChat:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif bOpenByQuickChat then
    self.QuickChat:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.CanvasPanel_459:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.QuickChat:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local isHide, _ = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_FRIEND_ADD_CHAT)
  if isHide then
    self.AddAFriend:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.AddAFriend:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  UE4Helper.SetDesiredShowCursor(true, "UMG_Friend_Chitchat_C")
  if 0 == LatestChatSessionUin then
    self.Blur:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Blur:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:PlayAnimation(self.In)
  if self.module:GetIsPanelMoveCamera() then
    _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.OnCmdMovePlayerCamera, self.In:GetEndTime())
  end
  Log.Debug(LatestChatSessionUin, "UMG_Friend_Chitchat_C:OnActive")
  self:ChangeChatGvoiceVisibility(false)
  local targetUin = 0
  if uin and 0 ~= uin then
    local sessionInfo = self.data:GetSessionInfo(uin)
    if sessionInfo then
      targetUin = uin
    end
  end
  if 0 == targetUin then
    local latestUnreadUin = self.data:GetLatestUnreadPrivateChatUin()
    if 0 ~= latestUnreadUin then
      targetUin = latestUnreadUin
    end
  end
  if 0 == targetUin then
    local multiPlayerUin = _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
    if self.data:GetSessionInfo(multiPlayerUin) then
      targetUin = multiPlayerUin
    else
      targetUin = LatestChatSessionUin
    end
  end
  self.data.CurChatUin = targetUin
  self.NewMessageNum = 0
  self.data:GetSortedChatSessionList(targetUin)
  self:RefreshPanelByType(UMG_Friend_Chitchat_C.RefreshType.All)
  self.OneLine = true
  self.StartSessionNum = #self.data.ChatSessionList
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").CHAT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").MESSAGE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType1)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_MainUIRoleHPItem_C:SetHpBt")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnInVisible)
  _G.NRCPanelManager.layerCenter:SendEvent(UILayerEvent.BREAKRIDESKILL_LAYER_OPENWINDOW)
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UnLockOpenSubUiEvent)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, true)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self.module, false)
  if not self.data:GetbCloseLobbyMain() then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddToDisableLobbyMainPopUpList, "UMG_Friend_Chitchat_C")
  end
  self.RedDot:SetupKey(423)
  if self.data.CurChatUin == _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM then
    self.module:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.MultiChannelChatFlag, true)
  end
end

function UMG_Friend_Chitchat_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, false)
  if RocoEnv.PLATFORM_WINDOWS then
    if self.data then
      self.data:SetTemporaryInput(self.MultipleLines:GetText())
    end
  elseif self.data then
    self.data:SetTemporaryInput(self.InputBox:GetText())
  end
  self:ChangeChatGvoiceVisibility(false)
  if self.module then
    if self.module:GetIsPanelMoveCamera() or self.module:GetIsMove() then
      _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.OnCmdGoBackPlayerCamera, self.Out:GetEndTime())
      self.module:SetIsPanelMoveCamera(false)
    end
    self.module:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.MultiChannelChatFlag, false)
  end
  UE4Helper.ReleaseDesiredShowCursor("UMG_Friend_Chitchat_C")
  if self.data and not self.data:GetbCloseLobbyMain() then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveFromDisableLobbyMainPopUpList, "UMG_Friend_Chitchat_C")
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  self.InputBox.OnTextChanged:Remove(self, self.OnTextChanged)
  self.InputBox.OnTextEndTransaction:Remove(self, self.OnTextEndTransaction)
  self.InputBox.OnTextCommitted:Remove(self, self.OnTextCommitted)
  self.InputBox.OnFocusChanged:Remove(self, self.OnInputFocusChanged)
  self.MultipleLines.OnTextChanged:Remove(self, self.OnTextChanged)
  self.MultipleLines.OnTextEndTransaction:Remove(self, self.OnTextEndTransaction)
  self.MultipleLines.OnTextCommitted:Remove(self, self.OnTextCommitted)
  self.MultipleLines.OnFocusChanged:Remove(self, self.OnInputFocusChanged)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenEmoMainPanel, 1, false)
end

function UMG_Friend_Chitchat_C:OnAddEventListener()
  self:AddButtonListener(self.BtnCloseChatPanel, self.OnClickBtnCloseChatPanel)
  self:AddButtonListener(self.Btn_paste, self.OnClickBtn_paste)
  self:AddButtonListener(self.FunctionBtn.btnLevelUp, self.OnClickFunctionBtn)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickBtnCloseChatPanel)
  self:AddButtonListener(self.Btn_Send.btnLevelUp, self.OnClickSendBtn)
  self:AddButtonListener(self.EditBtn, self.OnEditBtnClicked)
  self.EditBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:AddButtonListener(self.EditBtn_1, self.OnEditBtnClicked)
  self:AddButtonListener(self.Btn_report.btnLevelUp, self.OnReportBtn)
  self:AddButtonListener(self.AddAFriend.btnLevelUp, self.OnAddAFriend)
  self:AddButtonListener(self.MaskBtn, self.OnMaskBtn)
  self:AddButtonListener(self.MessageinformBtn, self.OnMessageinformBtn)
  self:AddButtonListener(self.QuickChat.btnLevelUp, self.OnOpenQuickChat)
  self:AddButtonListener(self.Btn_Gvoice, self.OpenGvoicePanel)
  self.InputBox.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  self.InputBox.OnTextCommitted:Add(self, self.OnTextCommitted)
  self.InputBox.OnFocusChanged:Add(self, self.OnInputFocusChanged)
  self.MultipleLines.OnTextChanged:Add(self, self.OnTextChanged)
  self.MultipleLines.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  self.MultipleLines.OnTextCommitted:Add(self, self.OnTextCommitted)
  self.MultipleLines.OnFocusChanged:Add(self, self.OnInputFocusChanged)
  self:RegisterEvent(self, FriendModuleEvent.OnSendChatMessageSucc, self.OnSendChatMessageSucc)
  self:RegisterEvent(self, FriendModuleEvent.OnRemoveChatListSucc, self.OnRemoveChatListSucc)
  self:RegisterEvent(self, FriendModuleEvent.OnGetChatMessageSucc, self.OnGetChatMessageSucc)
  self:RegisterEvent(self, FriendModuleEvent.OnUpdataChatInfoNotify, self.OnUpdataChatInfoNotify)
  self:RegisterEvent(self, FriendModuleEvent.OnAddLocalChatMessageSucc, self.OnAddLocalChatMessageSucc)
  self:RegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.OnModifyFriendRemarkUpdate)
  self:RegisterEvent(self, FriendModuleEvent.OnHideChatMenuDropdown, self.OnHideChatMenuDropdown)
  _G.NRCEventCenter:RegisterEvent("UMG_Friend_Chitchat_C", self, NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoGlobalTouchEnd)
  _G.NRCEventCenter:RegisterEvent("UMG_Friend_Chitchat_C", self, FriendModuleEvent.ChangeChatGvoiceVisibility, self.ChangeChatGvoiceVisibility)
  self.ItemList_Friend_1.OnUserScrolled:Add(self, self.OnChatScrolled)
end

function UMG_Friend_Chitchat_C:ChangeChatGvoiceVisibility(IsVisibility)
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
        local IsFirstTime = UE.UNRCPermissionMgr.IsFirstTimeRequest(UE.ENRCPermissionType.RecordAudio)
        if IsFirstTime then
          self.RequestPermission = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.RecordAudio, {
            self,
            function(_, bGranted)
              self.RequestPermission = nil
              if bGranted then
              else
                _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_gvoice_microphone_premission_not_open)
              end
            end
          })
        else
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_gvoice_microphone_premission_not_open)
        end
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

function UMG_Friend_Chitchat_C:OnRemoveEventListener()
  self.module:SetIsPanelMoveCamera(false)
  self:RemoveButtonListener(self.QuickChat.btnLevelUp)
  self:UnRegisterEvent(self, FriendModuleEvent.OnSendChatMessageSucc)
  self:UnRegisterEvent(self, FriendModuleEvent.OnRemoveChatListSucc)
  self:UnRegisterEvent(self, FriendModuleEvent.OnGetChatMessageSucc)
  self:UnRegisterEvent(self, FriendModuleEvent.OnUpdataChatInfoNotify)
  self:UnRegisterEvent(self, FriendModuleEvent.OnAddLocalChatMessageSucc)
  self:UnRegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.OnHideChatMenuDropdown)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoGlobalTouchEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.ChangeChatGvoiceVisibility, self.ChangeChatGvoiceVisibility)
end

function UMG_Friend_Chitchat_C:OnDestruct()
  self:OnRemoveEventListener()
  self:UnBindInputAction()
end

function UMG_Friend_Chitchat_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_DialogueUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local actions = {
    {
      name = "IA_CloseDialogueUI",
      method = "OnPcClose"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, action.method)
  end
end

function UMG_Friend_Chitchat_C:UnBindInputAction()
  local actions = {
    {
      name = "IA_CloseDialogueUI"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  end
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_DialogueUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_Friend_Chitchat_C:OnPcClose()
  if self.ChatGvoice and self.ChatGvoice:IsVisible() then
    self:ChangeChatGvoiceVisibility(false)
    return
  end
  self:OnClickBtnCloseChatPanel()
end

function UMG_Friend_Chitchat_C:OnInputFocusChanged(bFocused)
end

function UMG_Friend_Chitchat_C:OnEditBtnClicked()
  if RocoEnv.PLATFORM_WINDOWS then
    if self.MultipleLines.GoToTextEnd then
      self.MultipleLines:GoToTextEnd()
    end
    self.MultipleLines:SetFocus()
  else
  end
end

function UMG_Friend_Chitchat_C:OnChatScrolled(offset)
  local MaxOffset = self.ItemList_Friend_1:GetScrollOffsetOfEndData()
  if 0 ~= MaxOffset and offset >= MaxOffset then
    if self.HintCanvasPanel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self.HintCanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NewMessageNum = 0
    end
    if self.bScrollToEnd == false then
      self.bScrollToEnd = true
      self:SetChatMessageList(self.data.CurChatUin)
    end
  else
    self.bScrollToEnd = false
  end
  if 0 == offset and false == self.bScrollToStart then
    self.bScrollToStart = true
    local curChatNum = self:GetCurShowChatMsgNum(self.data.CurChatUin)
    self.module:OnZoneChatGetChatMessageReq(self.data.CurChatUin, curChatNum + 1, 10)
  end
end

function UMG_Friend_Chitchat_C:OnReportBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1010, "UMG_Friend_Chitchat_C:OnReportBtn")
  local multiPlayerUin = _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  if self.data.CurChatUin == multiPlayerUin then
    return
  end
  local ReportData = {}
  ReportData.uin = self.data.CurChatUin
  ReportData.business_data = {}
  ReportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_CONVERSATION_SPEAKING_SCENE
  ReportData.business_data.report_content = self:GetReportChatContent()
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendReport, ReportData)
end

function UMG_Friend_Chitchat_C:OnAddAFriend()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Chitchat_C:OnAddAFriend")
  local isUIFunctionBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_FRIEND_ADD_CHAT, true)
  if isUIFunctionBan then
    Log.Warning("UMG_Friend_Chitchat_C:OnAddAFriend FE_FRIEND_ADD_CHAT function is baned")
    return
  end
  Log.Debug("UMG_Friend_Chitchat_C:OnCmdOpenAddPrivateChatPanel", "self.data.CurChatUin", self.data.CurChatUin)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdOpenAddPrivateChatPanel, self.data.CurChatUin)
end

function UMG_Friend_Chitchat_C:OnMaskBtn()
  self.FunctionPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Friend_Chitchat_C:OnHideChatMenuDropdown()
  self.FunctionPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Friend_Chitchat_C:OnMessageinformBtn()
  local showMessageNum = self.curShowMessageListInfo and #self.curShowMessageListInfo or 0
  if showMessageNum > 0 then
    local messageList = MergeSortedArray(self.data.ChatMessageList[self.data.CurChatUin], self.data.LocalChatMessageList[self.data.CurChatUin], ChatMessageSortImpl, function(a)
      return self:ShouldIgnoreChatMessage(a)
    end)
    local totalNum = messageList and #messageList or 0
    local bIsLastPage = self.curEndIndex >= totalNum - 1
    if bIsLastPage then
      if showMessageNum < self.maxShowNum then
        self:ChatListScrollToEnd()
      else
        self.curStartIndex = self.curEndIndex + 1
        self.curEndIndex = #messageList
        Log.InfoFormat("[jessietest] OnMessageinformBtn \229\189\147\229\137\141\228\184\186\230\156\128\229\144\142\228\184\128\233\161\181\228\184\148\230\156\128\229\144\142\228\184\128\233\161\181\229\183\178\230\187\161\239\188\140\229\136\135\229\136\176\228\184\139\228\184\128\233\161\181 \229\143\150\230\149\176\230\141\174:%d~%d", self.curStartIndex, self.curEndIndex)
        local tempList = {}
        for i = self.curStartIndex, self.curEndIndex do
          table.insert(tempList, messageList[i])
        end
        self.curShowMessageListInfo = tempList
        self.ItemList_Friend_1:InitList(tempList)
        self:ChatListScrollToEnd()
      end
    else
      local lastPageIndex = math.floor(totalNum / self.maxShowNum)
      self.curStartIndex = lastPageIndex * self.maxShowNum + 1
      self.curEndIndex = #messageList
      Log.InfoFormat("[jessietest] OnMessageinformBtn \229\189\147\229\137\141\228\184\186\228\184\173\233\151\180\233\161\181\239\188\140\229\136\135\229\136\176\230\156\128\229\144\142\228\184\128\233\161\181 \229\143\150\230\149\176\230\141\174:%d~%d", self.curStartIndex, self.curEndIndex)
      local tempList = {}
      for i = self.curStartIndex, self.curEndIndex do
        table.insert(tempList, messageList[i])
      end
      self.curShowMessageListInfo = tempList
      self.ItemList_Friend_1:InitList(tempList)
      self:ChatListScrollToEnd()
    end
  end
end

function UMG_Friend_Chitchat_C:GetReportChatContent()
  local Result = ""
  local MaxBytes = 9
  local ChatContentData = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetChatInfoByUin, self.data.CurChatUin, false)
  if ChatContentData then
    for _, ChatContent in ipairs(ChatContentData) do
      if MaxBytes < #Result then
        break
      end
      Result = Result .. ChatContent.chat_message
    end
  end
  return Result
end

function UMG_Friend_Chitchat_C:GetCurShowChatMsgNum(uin)
  if self.data.ChatMessageList and self.data.ChatMessageList[uin] then
    return #self.data.ChatMessageList[uin]
  end
  return 0
end

function UMG_Friend_Chitchat_C:EnterChatUIPCMode(bEnter)
  if UE4.UNRCPlatformGameInstance.GetInstance():IsPCMode() then
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      local playerController = player:GetUEController()
      playerController:ToggleCursor(bEnter)
      player.inputComponent:SetInputEnable(self, not bEnter)
    end
  end
end

function UMG_Friend_Chitchat_C:OnClickBtnCloseChatPanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_MainUIRoleHPItem_C:SetHpBt")
  self:ChangeChatGvoiceVisibility(false)
  self:PlayAnimation(self.Out)
  if self.module:GetIsPanelMoveCamera() or self.module:GetIsMove() then
    _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.OnCmdGoBackPlayerCamera, self.Out:GetEndTime())
    self.module:SetIsPanelMoveCamera(false)
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, false)
end

function UMG_Friend_Chitchat_C:OnClickBtn_paste()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_Friend_Chitchat_C:OnClickBtn_paste")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenEmoMainPanel, 1, true, FriendEnum.ChatMode.GeneralChatting)
end

function UMG_Friend_Chitchat_C:OnClickDeleteBtn()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401009, "UMG_Friend_Chitchat_C:OnClickBtn_paste")
  local multiPlayerUin = _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  if self.data.CurChatUin == multiPlayerUin then
    return
  end
  local Ctx = DialogContext()
  Ctx:SetTitle(_G.LuaText.TIPS):SetContent(_G.LuaText.online_chat_message_delete_confirm):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetButtonText(_G.LuaText.umg_dialog_2, _G.LuaText.umg_dialog_1):SetCallback(self.data.CurChatUin, function(uin, isOk)
    if isOk then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.RemoveChatList, uin)
    end
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UMG_Friend_Chitchat_C:OnClickFunctionBtn()
  self.FunctionPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Chitchat_C:OnClickFunctionBtn")
end

function UMG_Friend_Chitchat_C:OnClickSendBtn()
  self.Btn_Send:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Friend_Chitchat_C:OnClickSendBtn")
  local text = self:GetInputText():GetText()
  if "" == text or nil == text then
    local tip = _G.DataConfigManager:GetLocalizationConf("chat_message_send_empty_tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip)
    self.Btn_Send:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif self:IsCheckSendTime(self.data.CurChatUin) then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SendChatMessage, self.data.CurChatUin, text)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.chat_message_send_CD)
    self.Btn_Send:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Friend_Chitchat_C:IsCheckSendTime(uin)
  if uin == _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType) then
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
  end
  return true
end

function UMG_Friend_Chitchat_C:OnEnterKeyDown(action_type)
  if 0 == action_type then
  end
end

function UMG_Friend_Chitchat_C:OnTextCommitted(text, type)
  if type == UE4.ETextCommit.OnEnter and not self:QuantityExtraction(text) then
    self:OnClickSendBtn()
  end
end

function UMG_Friend_Chitchat_C:OnTextChanged()
  if not RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if self._isPinYin then
    return
  end
  local text = self:GetInputText():GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1072, "UMG_Friend_Chitchat_C:OnTextChanged")
  local maxLength = _G.DataConfigManager:GetFriendGlobalConfig("friend_message_num_max").num
  local text_1 = self:GetInputText():GetText()
  local text_2 = self.module:RemoveEmoji(text_1)
  local textLen = string.StringGetTotalNum(text_2)
  local MaxContent, curLen = string.GetSubStr(text_2, maxLength)
  if maxLength < textLen then
    if text_2 ~= MaxContent then
      self:GetInputText():SetText(MaxContent)
    end
    local tips = _G.DataConfigManager:GetLocalizationConf("Shurufa_Toolong").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  elseif text_1 ~= text_2 then
    self:GetInputText():SetText(text_2)
  end
end

function UMG_Friend_Chitchat_C:QuantityExtraction(Text)
  local maxLength = _G.DataConfigManager:GetFriendGlobalConfig("friend_message_num_max").num
  local text_2 = self.module:RemoveEmoji(Text)
  local textLen = string.StringGetTotalNum(text_2)
  local MaxContent, curLen = string.GetSubStr(text_2, maxLength)
  if maxLength < textLen then
    if text_2 ~= MaxContent then
      self:GetInputText():SetText(MaxContent)
    end
    local tips = _G.DataConfigManager:GetLocalizationConf("Shurufa_Toolong").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
    return true
  elseif Text ~= text_2 then
    self:GetInputText():SetText(text_2)
  end
  return false
end

function UMG_Friend_Chitchat_C:OnTextEndTransaction()
  self._isPinYin = false
  self:OnTextChanged()
end

function UMG_Friend_Chitchat_C:RefreshPanel(bRefreshAll)
  if self.isDestruct then
    Log.Warning("UMG_Friend_Chitchat_C:RefreshPanel is destroyed")
    return
  end
  if self.data.ChatSessionList and #self.data.ChatSessionList > 0 then
    if bRefreshAll then
      local sessionInfo, index = self.data:GetSessionInfo(self.data.CurChatUin)
      local initData = {}
      if self.bOpenInBattle then
        initData = self.data.ChatSessionList
      elseif self.bOpenByQuickChat then
        self.data:SortChatSessionList()
        initData = self.data.ChatSessionList
      else
        for i = 2, #self.data.ChatSessionList do
          table.insert(initData, self.data.ChatSessionList[i])
        end
      end
      self.ItemList_Friend:InitList(initData)
      if 0 == #initData then
        self.Switcher:SetActiveWidgetIndex(1)
      else
        self.Switcher:SetActiveWidgetIndex(0)
        if sessionInfo then
          local targetIndex
          for i = 1, #initData do
            if initData[i] == sessionInfo then
              targetIndex = i
              break
            end
          end
          if targetIndex then
            self.ItemList_Friend:SelectItemByIndex(targetIndex - 1)
          else
            Log.ErrorFormat("UMG_Friend_Chitchat_C:RefreshPanel \230\137\190\228\184\141\229\136\176targetIndex uin=%s\239\188\140\233\187\152\232\174\164\233\128\137\230\139\169\231\172\172\228\184\128\228\184\170", tostring(self.data.CurChatUin))
            self.ItemList_Friend:SelectItemByIndex(0)
          end
        else
          Log.ErrorFormat("UMG_Friend_Chitchat_C:RefreshPanel \230\137\190\228\184\141\229\136\176\229\175\185\229\186\148\228\188\154\232\175\157 uin=%s\239\188\140\233\187\152\232\174\164\233\128\137\230\139\169\231\172\172\228\184\128\228\184\170", tostring(self.data.CurChatUin))
          self.ItemList_Friend:SelectItemByIndex(0)
        end
      end
    end
  else
    self.ItemList_Friend:InitList(self.data.ChatSessionList)
    self.Switcher:SetActiveWidgetIndex(1)
  end
end

function UMG_Friend_Chitchat_C:RefreshPanelByType(refreshType)
  if refreshType == UMG_Friend_Chitchat_C.RefreshType.Receive then
    self:RefreshPanel(true)
  elseif refreshType == UMG_Friend_Chitchat_C.RefreshType.Send then
    self:RefreshPanel(true)
  elseif refreshType == UMG_Friend_Chitchat_C.RefreshType.Remove then
    self:RefreshPanel(true)
  else
    self:RefreshPanel(true)
  end
end

function UMG_Friend_Chitchat_C:RefreshCurSessionName(newNote)
  local curChatSession = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetChatInfoByUin, self.data.CurChatUin, true)
  local showNote = newNote and newNote or _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendNewRemarkByUin, self.data.CurChatUin)
  local showName = curChatSession and curChatSession.friend_session_info.name or ""
  if string.IsNilOrEmpty(showNote) then
    showNote = curChatSession and curChatSession.friend_session_info.note or ""
  end
  if not string.IsNilOrEmpty(showNote) then
    self.Name_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RemarkName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local nameText = string.format(_G.LuaText.chat_name_show, showName)
    self.Name_1:SetText(nameText)
    self.RemarkName:SetText(showNote)
    self.RemarkName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#d87a35ff"))
    self.Name_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#f4eee1ff"))
  else
    self.Name_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RemarkName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RemarkName:SetText(showName)
    self.RemarkName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#f4eee1ff"))
  end
  local visitInfo = curChatSession and curChatSession.friend_session_info.visit_info
  if visitInfo and visitInfo.visitor_num > 0 then
    self.MutualVisits:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.VisitNumMax = self.module:GetVisitNumMax()
    local visitNumText = string.format("%d/%d", visitInfo.visitor_num, self.VisitNumMax)
    self.MutualVisitsText:SetText(visitNumText)
  else
    self.MutualVisits:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Chitchat_C:OnRocoGlobalTouchEnd()
  local index = self.ItemList_Friend_1._selectedItemIndex
  if index > 0 and index <= self.ItemList_Friend_1:GetItemCount() then
    self.ItemList_Friend_1:OpItemByIndex(index, FriendEnum.ChatItemRefreshType.HideReportBtn)
  end
end

function UMG_Friend_Chitchat_C:OnSessionChanged()
  self.bScrollToStart = false
  self.bScrollToEnd = false
  self.curStartIndex = 1
  self.curEndIndex = 1
  self.bInit = false
end

function UMG_Friend_Chitchat_C:SetChatMessageList(uin)
  if 0 == self.data.CurChatUin or 0 == uin then
    return
  end
  if self.data.CurChatUin ~= uin then
    return
  end
  self.curShowMessageListInfo = {}
  local messageList = MergeSortedArray(self.data.ChatMessageList[uin], self.data.LocalChatMessageList[uin], ChatMessageSortImpl, function(a)
    return self:ShouldIgnoreChatMessage(a)
  end)
  local bChangePage = false
  local tempList = {}
  if messageList and #messageList > 0 then
    for i = 1, #messageList do
      local timeInterval = 0
      if 1 == i then
        timeInterval = messageList[1].time_stamp
      else
        timeInterval = messageList[i].time_stamp - messageList[i - 1].time_stamp
      end
      messageList[i].TimeInterval = timeInterval
      messageList[i].bSelected = false
    end
    Log.Info("[jessietest] messageList\230\149\176\233\135\143\239\188\154", #messageList)
    if not self.bInit then
      if uin == _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM then
        self.curEndIndex = #messageList
        self.curStartIndex = math.floor(#messageList / self.maxShowNum) * self.maxShowNum + 1
      else
        self.curEndIndex = self.curStartIndex + self.maxShowNum - 1
        if self.curEndIndex > #messageList then
          self.curEndIndex = #messageList
        end
      end
    else
      if self.bScrollToStart then
        if self.curStartIndex - 1 > 0 then
          bChangePage = true
          self.curEndIndex = self.curStartIndex - 1
          self.curStartIndex = self.curEndIndex - self.maxShowNum + 1
        else
          self.curEndIndex = self.curStartIndex + self.maxShowNum - 1
          if self.curEndIndex > #messageList then
            self.curEndIndex = #messageList
          end
        end
      end
      if self.bScrollToEnd and self.curEndIndex and #messageList > self.curEndIndex then
        bChangePage = true
        self.curStartIndex = self.curEndIndex + 1
        self.curEndIndex = self.curStartIndex + self.maxShowNum - 1
        if self.curEndIndex > #messageList then
          self.curEndIndex = #messageList
        end
      end
    end
    Log.InfoFormat("[jessietest] InitList \229\143\150\230\149\176\230\141\174:%d~%d", self.curStartIndex, self.curEndIndex)
    for i = self.curStartIndex, self.curEndIndex do
      table.insert(tempList, messageList[i])
    end
    self.curShowMessageListInfo = tempList
    self.ItemList_Friend_1:InitList(tempList)
  else
    self.ItemList_Friend_1:InitList(messageList)
  end
  self:DelayFrames(1, function()
    self.ItemList_Friend_1:ForceLayoutPrepass()
    if not self.bInit then
      if #tempList > 0 then
        self.Switcher:SetActiveWidgetIndex(0)
        self:ChatListScrollToEnd()
      end
      self.bInit = true
    else
      if self.bScrollToStart then
        if bChangePage then
          self.ItemList_Friend_1:ScrollToEnd()
        end
        self.bScrollToStart = false
      end
      if self.bScrollToEnd then
        if bChangePage then
          self.ItemList_Friend_1:ScrollToStart()
        end
        self.bScrollToEnd = false
      end
    end
  end)
  local multiPlayerUin = _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  local isVisitChat = uin == multiPlayerUin
  if isVisitChat then
    self.FunctionBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.FunctionBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.bOpenByQuickChat then
    if isVisitChat and not self.bOpenInBattle then
      self.QuickChat:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.QuickChat:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if isVisitChat then
    self.Btn_report:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Name_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RemarkName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RemarkName:SetText(LuaText.chat_multi_message_tips)
    self.RemarkName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#f4eee1ff"))
  else
    self:RefreshCurSessionName()
  end
end

function UMG_Friend_Chitchat_C:ClearEditableText(focus, IsEmo)
  if not IsEmo then
    self:GetInputText():SetText("")
  end
  if focus and self:GetInputText().SetKeyboardFocus then
    self:GetInputText():SetKeyboardFocus()
  end
end

function UMG_Friend_Chitchat_C:AppendChatMessageToList(uin, message, refreshType)
  if not uin or not message then
    return
  end
  if uin == self.data.CurChatUin then
    if self:ShouldIgnoreChatMessage(message) then
      return
    end
    local showMessageNum = self.curShowMessageListInfo and #self.curShowMessageListInfo or 0
    if showMessageNum > 0 then
      local messageList = MergeSortedArray(self.data.ChatMessageList[uin], self.data.LocalChatMessageList[uin], ChatMessageSortImpl, function(a)
        return self:ShouldIgnoreChatMessage(a)
      end)
      local showMessageTail = self.ItemList_Friend_1:GetDataByIndex(showMessageNum)
      if showMessageTail ~= message then
        message.TimeInterval = message.time_stamp - showMessageTail.time_stamp
        message.bSelected = false
        local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
        local totalNum = messageList and #messageList or 0
        local bIsLastPage = self.curEndIndex >= totalNum - 1
        if bIsLastPage then
          if showMessageNum < self.maxShowNum then
            table.insert(self.curShowMessageListInfo, message)
            self.ItemList_Friend_1:AddOrRemoveItem(true, showMessageNum + 1, message, true)
            self.curEndIndex = self.curEndIndex + 1
            local Offset = self.ItemList_Friend_1:GetScrollOffset()
            local MaxOffset = self.ItemList_Friend_1:GetScrollOffsetOfEndData()
            if Offset < MaxOffset and message and message.uin ~= playerUin then
              self:ShowNewMessage()
            else
              self:ChatListScrollToEnd()
            end
          else
            local Offset = self.ItemList_Friend_1:GetScrollOffset()
            local MaxOffset = self.ItemList_Friend_1:GetScrollOffsetOfEndData()
            if Offset < MaxOffset and message and message.uin ~= playerUin then
              self:ShowNewMessage()
            else
              self.curStartIndex = self.curEndIndex + 1
              self.curEndIndex = #messageList
              Log.InfoFormat("[jessietest] AppendChatMessageToList \229\189\147\229\137\141\228\184\186\230\156\128\229\144\142\228\184\128\233\161\181\228\184\148\230\156\128\229\144\142\228\184\128\233\161\181\229\183\178\230\187\161\239\188\140\229\136\135\229\136\176\228\184\139\228\184\128\233\161\181 \229\143\150\230\149\176\230\141\174:%d~%d", self.curStartIndex, self.curEndIndex)
              local tempList = {}
              for i = self.curStartIndex, self.curEndIndex do
                table.insert(tempList, messageList[i])
              end
              self.curShowMessageListInfo = tempList
              self.ItemList_Friend_1:InitList(tempList)
              self:ChatListScrollToEnd()
            end
          end
        elseif message and message.uin == playerUin then
          local lastPageIndex = math.floor(totalNum / self.maxShowNum)
          self.curStartIndex = lastPageIndex * self.maxShowNum + 1
          self.curEndIndex = #messageList
          Log.InfoFormat("[jessietest] AppendChatMessageToList \229\189\147\229\137\141\228\184\186\228\184\173\233\151\180\233\161\181\239\188\140\229\136\135\229\136\176\230\156\128\229\144\142\228\184\128\233\161\181 \229\143\150\230\149\176\230\141\174:%d~%d", self.curStartIndex, self.curEndIndex)
          local tempList = {}
          for i = self.curStartIndex, self.curEndIndex do
            table.insert(tempList, messageList[i])
          end
          self.curShowMessageListInfo = tempList
          self.ItemList_Friend_1:InitList(tempList)
          self:ChatListScrollToEnd()
        else
          self:ShowNewMessage()
        end
      end
    else
      self:RefreshPanelByType(refreshType)
    end
  end
end

function UMG_Friend_Chitchat_C:OnSendChatMessageSucc(bSucc, uin, IsEmo)
  self.Btn_Send:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if bSucc then
    self:ClearEditableText(RocoEnv.PLATFORM_WINDOWS, IsEmo)
    local messageList = self.data.ChatMessageList[uin]
    local messageNum = messageList and #messageList or 0
    if messageNum > 0 then
      self:AppendChatMessageToList(uin, messageList[messageNum], UMG_Friend_Chitchat_C.RefreshType.Send)
    end
  end
end

function UMG_Friend_Chitchat_C:OnRemoveChatListSucc(uin)
  self:DelaySeconds(0.25, function()
    self:RefreshPanelByType(UMG_Friend_Chitchat_C.RefreshType.Remove)
    self.FunctionPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end)
end

function UMG_Friend_Chitchat_C:ShowNewMessage()
  self.NewMessageNum = self.NewMessageNum + 1
  self.HintCanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.RedPointImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local Text
  if self.NewMessageNum < 99 then
    Text = _G.DataConfigManager:GetLocalizationConf("chat_message_less_99").msg
  else
    self.NewMessageNum = 99
    Text = _G.DataConfigManager:GetLocalizationConf("chat_message_99").msg
  end
  self.NumText:SetText(string.format(Text, self.NewMessageNum))
end

function UMG_Friend_Chitchat_C:ChatListScrollToEnd()
  self.ItemList_Friend_1:ScrollToEnd()
  self.bScrollToEnd = true
  self.HintCanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NewMessageNum = 0
end

function UMG_Friend_Chitchat_C:OnTick()
end

function UMG_Friend_Chitchat_C:OnGetChatMessageSucc(uin)
  if self.isFirstOpenPanel then
    self.isFirstOpenPanel = false
    self.data:InItMultiPlayerChannelData()
  end
  self:SetChatMessageList(uin)
  self:ChangeChatGvoiceVisibility(false)
end

function UMG_Friend_Chitchat_C:CheckGetMsgFriendIsShow(uin)
  for i = 1, self.ItemList_Friend:GetItemCount() do
    local Data = self.ItemList_Friend:GetDataByIndex(i)
    local friendUin = Data and Data.basic_info and Data.basic_info.uin
    if uin == friendUin then
      return true
    end
  end
  return false
end

function UMG_Friend_Chitchat_C:OnUpdataChatInfoNotify(notify)
  local curUin = notify.chat_session.basic_info.uin
  self.data:GetSortedChatSessionList(curUin)
  if 0 ~= curUin and not self:CheckGetMsgFriendIsShow(curUin) then
    self:RefreshPanelByType(UMG_Friend_Chitchat_C.RefreshType.All)
  elseif curUin == self.data.CurChatUin then
    local messageList = self.data.ChatMessageList[curUin]
    local messageNum = #messageList
    if messageNum > 0 then
      self:AppendChatMessageToList(curUin, messageList[messageNum], UMG_Friend_Chitchat_C.RefreshType.Receive)
    end
  end
end

function UMG_Friend_Chitchat_C:OnAddLocalChatMessageSucc(uin, localMsg)
  if not localMsg then
    return
  end
  if localMsg.msgSource == FriendEnum.ChatMsgSource.DirtyMsgForSend then
    self:ClearEditableText(RocoEnv.PLATFORM_WINDOWS)
  end
  self:AppendChatMessageToList(uin, localMsg, UMG_Friend_Chitchat_C.RefreshType.Receive)
end

function UMG_Friend_Chitchat_C:UpdateChatItemInfo(uin, refreshType)
  local chatSession = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetChatInfoByUin, uin, true)
  if chatSession then
    local index = self.ItemList_Friend:GetIndexByData(chatSession)
    if index > 0 then
      self.ItemList_Friend:OpItemByIndex(index, refreshType)
    end
  end
  local itemNum = self.ItemList_Friend_1:GetItemCount()
  for i = 1, itemNum do
    local chatMsg = self.ItemList_Friend_1:GetDataByIndex(i)
    if chatMsg and chatMsg.uin == uin then
      self.ItemList_Friend_1:OpItemByIndex(i, refreshType)
    end
  end
end

function UMG_Friend_Chitchat_C:OnModifyFriendRemarkUpdate(uin, newNote)
  if uin == self.data.CurChatUin then
    self:RefreshCurSessionName(newNote)
  end
  self:UpdateChatItemInfo(uin, FriendEnum.ChatItemRefreshType.FriendRemarkUpdate)
end

function UMG_Friend_Chitchat_C:SortSessionList(uin, bRemove)
  if bRemove then
  else
  end
end

function UMG_Friend_Chitchat_C:ShouldIgnoreChatMessage(chatMsg)
  if chatMsg.uin then
    local blackTimestamp = self.data:GetBlackTimestamp(chatMsg.uin)
    if blackTimestamp and chatMsg.time_stamp and blackTimestamp < chatMsg.time_stamp then
      return true
    end
  end
  return false
end

function UMG_Friend_Chitchat_C:GetInputText()
  if RocoEnv.PLATFORM_WINDOWS then
    return self.MultipleLines
  else
    return self.InputBox
  end
end

function UMG_Friend_Chitchat_C:OnOpenQuickChat()
  self:PlayAnimation(self.Out)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.ReOpenQuickChat)
end

function UMG_Friend_Chitchat_C:OpenGvoicePanel()
  if self.ChatGvoice and not self.ChatGvoice:IsVisible() then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Chitchat_C:OpenGvoicePanel")
    self:ChangeChatGvoiceVisibility(true)
  end
end

function UMG_Friend_Chitchat_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:DoClose()
  end
end

function UMG_Friend_Chitchat_C:DoClose()
  self.CloseBtn:SetKeyboardFocus()
  _G.NRCPanelBase.DoClose(self)
end

return UMG_Friend_Chitchat_C

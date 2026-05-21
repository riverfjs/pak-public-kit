local UMG_GiftVoucherSharing_C = _G.NRCPanelBase:Extend("UMG_GiftVoucherSharing_C")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")

function UMG_GiftVoucherSharing_C:OnConstruct()
  self.giftVoucherData = nil
  self.friendList = {}
  self.selectedFriend = nil
  self.searchText = ""
  self._isPinYin = false
  self.SearchInfo = nil
  self:SetChildViews(self.PopUp)
  local maxInputConfig = _G.DataConfigManager:GetBpGlobalConfig(6)
  self.maxInputLength = maxInputConfig and maxInputConfig.num or 100
  self:AddButtonListener(self.UBtn_Search.btnLevelUp, self.OnClickBtnSearch)
  self:AddButtonListener(self.UMG_Details_Question.btnLevelUp, self.OnClickQuestion)
  self:AddButtonListener(self.Btn_paste, self.OnPastBtnClicked)
  self:AddButtonListener(self.Btn_Delete, self.OnClearInputBoxBtnClicked)
end

function UMG_GiftVoucherSharing_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  local titleText = _G.DataConfigManager:GetLocalizationConf("bp_gift_share_title").msg
  CommonPopUpData.TitleText = titleText or ""
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnCancel
  CommonPopUpData.Btn_RightHandler = self.OnConfirm
  CommonPopUpData.ClosePanelHandler = self.OnCancel
  CommonPopUpData.Btn_CloseHandler = self.OnCancel
  CommonPopUpData.SkipCloseAnim = true
  CommonPopUpData.CloseBtnSound = 41401014
  self.OnPcCloseHandler = self.OnCancel
  self.PopUp:SetPanelInfo(CommonPopUpData)
  self.PopUp:RemoveButtonListener(self.PopUp.FullScreen_Close)
end

function UMG_GiftVoucherSharing_C:OnClickQuestion()
  local Content = LuaText.bp_gift_share_rule
  local title = LuaText.bp_gift_share_rule_title or ""
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_GiftVoucherSharing_C:OnOpenTips")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_GiftVoucherSharing_C:OnCancel()
  Log.Info("UMG_GiftVoucherSharing_C:OnCancel")
  local moduleName = "BagModule"
  local panelName = "UMG_GiftVoucherSharing"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    self.PopUp:SetLock(false)
    Log.Info("UMG_GiftVoucherSharing_C:OnCancel isSelectBtn", moduleName, panelName)
    return
  end
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).CLOSE)
  self:LoadAnimation(2)
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_GiftVoucherSharing_C:OnFullScreen_Close")
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_GiftVoucherSharing_C:OnFullScreen_Close")
end

function UMG_GiftVoucherSharing_C:OnConfirm()
  Log.Info("UMG_GiftVoucherSharing_C:OnConfirm")
  self:DoClose()
end

function UMG_GiftVoucherSharing_C:OnActive(giftVoucherItemData)
  self:LoadAnimation(0)
  if giftVoucherItemData then
    self.giftVoucherItemData = giftVoucherItemData
  else
    local bagModule = _G.NRCModuleManager:GetModule("BagModule")
    if bagModule then
      self.giftVoucherItemData = bagModule:GetData():GetGiftVoucherData()
    end
  end
  self:SetCommonPopUpInfo()
  self:InitUI()
  self:OnAddEventListener()
end

function UMG_GiftVoucherSharing_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_GiftVoucherSharing_C:OnAddEventListener()
  if self.EditText_Search then
    self.EditText_Search.OnTextChanged:Add(self, self.OnSearchTextChanged)
    self.EditText_Search.OnTextCommitted:Add(self, self.OnSearchTextCommitted)
    self.EditText_Search.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  end
end

function UMG_GiftVoucherSharing_C:OnRemoveEventListener()
  if self.EditText_Search then
    self.EditText_Search.OnTextChanged:Remove(self, self.OnSearchTextChanged)
    self.EditText_Search.OnTextCommitted:Remove(self, self.OnSearchTextCommitted)
    self.EditText_Search.OnTextEndTransaction:Remove(self, self.OnTextEndTransaction)
  end
end

function UMG_GiftVoucherSharing_C:InitUI()
  if self.GridView_Friends then
    self.GridView_Friends:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetGiftVoucherInfo()
  self:SetPastDeleteUI(false)
  self:LoadFriendList()
end

function UMG_GiftVoucherSharing_C:SetGiftVoucherInfo()
  if self.RemarkName then
    local text01 = _G.DataConfigManager:GetLocalizationConf("bp_gift_share_text01").msg or ""
    self.RemarkName:SetText(text01)
    self.RemarkName:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.RemarkName_1 then
    local text02 = _G.DataConfigManager:GetLocalizationConf("bp_gift_share_text02").msg or ""
    self.RemarkName_1:SetText(text02)
    self.RemarkName_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.EditText_Search then
    local text03 = _G.DataConfigManager:GetLocalizationConf("bp_gift_share_text03").msg or ""
    self.EditText_Search:SetHintText(text03)
  end
  if self.UBtn_Search then
    local text04 = _G.DataConfigManager:GetLocalizationConf("bp_gift_share_button01").msg or ""
    self.UBtn_Search.Title_1:SetText(text04)
  end
end

function UMG_GiftVoucherSharing_C:LoadFriendList()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendListForGiftVoucher, function(friendList)
    self.friendList = friendList or {}
    self.friendList = self:FilterBlacklistedFriends(self.friendList)
    if #self.friendList > 0 then
      if self.GridView_Friends then
        self.GridView_Friends:SetVisibility(UE4.ESlateVisibility.Visible)
      end
      self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    else
      self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    end
    self.friendList = self:CheckGiftableStatusAndSort(self.friendList)
    if self.GridView_Friends then
      self.GridView_Friends:InitList(self.friendList)
    end
  end)
end

function UMG_GiftVoucherSharing_C:FilterBlacklistedFriends(friendList)
  local filteredList = {}
  for _, friend in ipairs(friendList) do
    if friend.bp_gift_grade == _G.Enum.BattlePassGiftGrade.BPGG_FREE then
      table.insert(filteredList, friend)
    end
  end
  return filteredList
end

function UMG_GiftVoucherSharing_C:CheckGiftableStatusAndSort(friendList)
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  local friendTimeLimit = _G.DataConfigManager:GetGlobalConfig("bp_gift_friend_time_limit").num or 0
  local friendLevelLimit = _G.DataConfigManager:GetGlobalConfig("bp_gift_friend_level_limit").num or 0
  for _, friend in ipairs(friendList) do
    friend.canGift = self:CheckCanGiftToFriend(friend, currentTime, friendTimeLimit, friendLevelLimit)
  end
  table.sort(friendList, function(a, b)
    if a.canGift and not b.canGift then
      return true
    elseif not a.canGift and b.canGift then
      return false
    else
      return false
    end
  end)
  return friendList
end

function UMG_GiftVoucherSharing_C:CheckCanGiftToFriend(friend, currentTime, friendTimeLimit, friendLevelLimit)
  if not friend then
    return false
  end
  if not friend.uin then
    return false
  end
  if not friend.is_chat_node_unlock then
    return false
  end
  if friend.bp_gift_grade ~= _G.Enum.BattlePassGiftGrade.BPGG_FREE then
    return false
  end
  local friendAddTime = friend.add_friend_time or 0
  local friendDuration = currentTime - friendAddTime
  if friendTimeLimit > friendDuration then
    return false
  end
  local friendLevel = friend.level or 0
  if friendLevelLimit > friendLevel then
    return false
  end
  return true
end

function UMG_GiftVoucherSharing_C:OnClickBtnSearch()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_GiftVoucherSharing_C:OnClickBtnSearch")
  if self.EditText_Search then
    local searchText = self.EditText_Search:GetText()
    if self:InputIsValid(searchText) then
      self:PerformRealTimeSearch(searchText)
    else
      self.SearchInfo = nil
      local text = _G.DataConfigManager:GetLocalizationConf("search_UID_empty_tips").msg
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, text)
    end
  end
end

function UMG_GiftVoucherSharing_C:OnClearInputBoxBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1005, "UMG_GiftVoucherSharing_C:OnClearInputBoxBtnClicked")
  self.EditText_Search:SetText("")
end

function UMG_GiftVoucherSharing_C:OnPastBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1004, "UMG_GiftVoucherSharing_C:OnPastBtnClicked")
  local Text = UE4.UNRCStatics.ClipboardPaste()
  self.EditText_Search:SetText(Text)
end

function UMG_GiftVoucherSharing_C:OnSearchTextCommitted(text, type)
  Log.Info("UMG_GiftVoucherSharing_C:OnSearchTextCommitted", text, type)
  if type == UE4.ETextCommit.OnEnter then
    self:OnClickBtnSearch()
  end
end

function UMG_GiftVoucherSharing_C:OnTextEndTransaction()
  self._isPinYin = false
  self:OnSearchTextChanged()
end

function UMG_GiftVoucherSharing_C:OnSearchTextChanged()
  if self._isPinYin then
    return
  end
  local text = self.EditText_Search:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  local NewInput = self.EditText_Search:GetText()
  local MaxCount = self.maxInputLength
  local MaxContent, CurrentNum = string.GetSubStr(NewInput, MaxCount)
  if NewInput and NewInput ~= MaxContent then
    self.EditText_Search:SetText(MaxContent)
    local tips = _G.DataConfigManager:GetLocalizationConf("chat_message_send_empty_tips3").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  end
  if NewInput and "" ~= NewInput then
    self:SetPastDeleteUI(true)
  else
    self:SetPastDeleteUI(false)
    self:LoadFriendList()
  end
  _G.NRCAudioManager:PlaySound2DAuto(1086, "UMG_Friend_Item_C:StartFriendVisit")
end

function UMG_GiftVoucherSharing_C:SetPastDeleteUI(hasInput)
  if hasInput then
    self.NRCSwitcher_91:SetActiveWidgetIndex(1)
  else
    self.NRCSwitcher_91:SetActiveWidgetIndex(0)
  end
end

function UMG_GiftVoucherSharing_C:PerformRealTimeSearch(searchText)
  if not searchText or "" == searchText then
    self:LoadFriendList()
    return
  end
  local filteredList = {}
  for _, friend in ipairs(self.friendList) do
    if self:IsFriendMatchSearch(friend, searchText) then
      table.insert(filteredList, friend)
    end
  end
  filteredList = self:CheckGiftableStatusAndSort(filteredList)
  if filteredList and #filteredList > 0 then
    if self.GridView_Friends then
      self.GridView_Friends:InitList(filteredList)
    end
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
  end
end

function UMG_GiftVoucherSharing_C:IsFriendMatchSearch(friend, searchText)
  if not friend or not searchText then
    return false
  end
  searchText = string.lower(searchText)
  if friend.uin and tostring(friend.uin):find(searchText, 1, true) then
    return true
  end
  if friend.name and string.find(string.lower(friend.name), searchText, 1, true) then
    return true
  end
  if friend.note and string.find(string.lower(friend.note), searchText, 1, true) then
    return true
  end
  return false
end

function UMG_GiftVoucherSharing_C:InputIsValid(InputInfo)
  if not InputInfo or 0 == #InputInfo then
    return false
  end
  return true
end

function UMG_GiftVoucherSharing_C:isFloat(num)
  return num ~= math.floor(num)
end

function UMG_GiftVoucherSharing_C:OnFriendItemClicked(friendData)
  self.selectedFriend = friendData
end

function UMG_GiftVoucherSharing_C:OnDestruct()
end

function UMG_GiftVoucherSharing_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    local moduleName = "BagModule"
    local panelName = "UMG_GiftVoucherSharing"
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).CLOSE
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, moduleName, panelName, touchReasonType)
    Log.Info("UMG_GiftVoucherSharing_C:OnAnimationFinished CLOSE")
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

return UMG_GiftVoucherSharing_C

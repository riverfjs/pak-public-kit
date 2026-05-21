local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Friend_Chitchat_ChatItem_C = Base:Extend("UMG_Friend_Chitchat_ChatItem_C")
local RefreshFriendInfoType = {
  All = 0,
  Remark = 1,
  HeadIcon = 2,
  VisitIndex = 3
}

function UMG_Friend_Chitchat_ChatItem_C:OnConstruct()
  self:AddButtonListener(self.friend.ReportBtn.button, self.OnReportBtn)
  self:AddButtonListener(self.myself.ReportBtn.button, self.OnReportBtn)
  self:AddButtonListener(self.friend.Btn_Head, self.OnClickHead)
  self:AddButtonListener(self.myself.Btn_Head, self.OnClickHead)
  self:AddButtonListener(self.friend.Btn_Receive, self.OnClickReceiveGift)
  self:AddButtonListener(self.myself.Btn_ItemTips, self.OnClickItemTips)
  self:AddButtonListener(self.friend.Btn_ItemTips, self.OnClickItemTips)
  self.isReqSendingGift = false
end

function UMG_Friend_Chitchat_ChatItem_C:OnDestruct()
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
  if self.DelayReqID then
    _G.DelayManager:CancelDelayById(self.DelayReqID)
    self.DelayReqID = nil
  end
end

function UMG_Friend_Chitchat_ChatItem_C:OnReportBtn()
  local ReportData = {}
  ReportData.uin = self.uiData.uin
  ReportData.business_data = {}
  ReportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_CONVERSATION_SPEAKING_SCENE
  ReportData.business_data.report_content = self:EscapeString(self.uiData.chat_message)
  if self.uiData.msg_uid then
    ReportData.business_data.callback = "{\"msg_uid\":" .. "\"" .. self.uiData.msg_uid .. "\"" .. "}"
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenFriendReport, ReportData)
  self:SetReportBtnShowState()
end

function UMG_Friend_Chitchat_ChatItem_C:OnClickHead()
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if myUin == self.uiData.uin then
    local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
    if myPlayer then
      local bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
      if bInFighting then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.battle_chat_not_open_role_card)
        return
      end
    end
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, nil, FriendEnum.AdminFriendType.Own, FriendEnum.Source.Friend, nil)
  else
    local isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(self.uiData.uin)
    if isFriend then
      local friendData = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendByUin, self.uiData.uin)
      if friendData then
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, friendData, FriendEnum.AdminFriendType.Others, FriendEnum.Source.Friend, nil)
      else
        local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
        req.uin = self.uiData.uin
        _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnReadyOpenOpenStudentCardPanel, false, true)
      end
    else
      Log.DebugFormat("UMG_Friend_Chitchat_ChatItem_C:OnClickHead not friend uin=%s", tostring(self.uiData.uin))
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.role_not_open_stranger_card)
    end
  end
end

function UMG_Friend_Chitchat_ChatItem_C:OnReadyOpenOpenStudentCardPanel(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, rsp.player_info, FriendEnum.AdminFriendType.Others, rsp.is_friend and FriendEnum.Source.Friend or FriendEnum.Source.Scene, nil)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:RefreshFriendInfo(refreshType)
  local isVisitChat = self.uiData.msg_detail_info and self.uiData.msg_detail_info.session_uin == _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  local note = ""
  local name = ""
  local headIconStr = ""
  local is_friend = false
  if isVisitChat then
    note = self.uiData.msg_detail_info.note
    name = self.uiData.msg_detail_info.name
    is_friend = self.uiData.msg_detail_info.is_friend
    headIconStr = self.uiData.msg_detail_info.card_icon_selected
  else
    local chatSession = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetChatInfoByUin, self.uiData.uin, true)
    if chatSession then
      note = chatSession.friend_session_info.note
      name = chatSession.friend_session_info.name
      headIconStr = chatSession.friend_session_info.card_icon_selected
    end
  end
  if refreshType == RefreshFriendInfoType.All or refreshType == RefreshFriendInfoType.Remark then
    local showName = self:GetShowName(self.uiData.uin, note, name)
    local extraTag = ""
    local bIsFightTogether = false
    local battlePlayer = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.uiData.uin)
    if battlePlayer then
      bIsFightTogether = battlePlayer:IsTeammate()
    end
    if bIsFightTogether then
      extraTag = LuaText.chat_multi_message_relation_battle
    elseif _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.CheckInObserver, self.uiData.uin) then
      extraTag = LuaText.chat_multi_message_relation_battle_look
    elseif is_friend and _G.DataModelMgr.PlayerDataModel:IsVisitState() == false and isVisitChat then
      extraTag = LuaText.chat_multi_message_relation
    end
    self.friend.Name:SetText(showName .. extraTag)
  end
  if refreshType == RefreshFriendInfoType.All or refreshType == RefreshFriendInfoType.HeadIcon then
    headIcon = self:GetHeadIconById(headIconStr)
    self.friend.HeadPortrait:SetPath(headIcon)
  end
  if refreshType == RefreshFriendInfoType.All or refreshType == RefreshFriendInfoType.VisitIndex then
    local visitIndex = isVisitChat and _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, self.uiData.uin) or nil
    if visitIndex then
      self.friend.TeamMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.friend.SerialNumber:SetText(string.format("%s%s", visitIndex, "P"))
    else
      self.friend.TeamMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local isBlack = _G.DataModelMgr.PlayerDataModel:CheckHasBlackByPlayerUin(self.uiData.uin)
  if isBlack then
    UIUtils.SafeSetVisibility(self.friend.Icon_Blacklist, UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    UIUtils.SafeSetVisibility(self.friend.Icon_Blacklist, UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  if self.uiData == nil then
    Log.Error("\232\129\138\229\164\169\230\149\176\230\141\174\232\174\190\231\189\174\230\156\137\232\175\175")
    return
  end
  Log.DebugFormat("UMG_Friend_Chitchat_ChatItem_C:OnItemUpdate uin=%s, msg=%s, chat_msg_type=%s, msg_uid= %s, time_stamp=%s", tostring(self.uiData.uin), tostring(self.uiData.chat_message), tostring(self.uiData.chat_msg_type), tostring(self.uiData.msg_uid), tostring(self.uiData.time_stamp))
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  UIUtils.SafeSetVisibility(self.friend.Icon_Blacklist, UE4.ESlateVisibility.Collapsed)
  if self.uiData.msgSource == FriendEnum.ChatMsgSource.Client then
    self.ChatSwitcher:SetActiveWidgetIndex(2)
    self.Text_AccessPrompt:SetText(self.uiData.chat_message)
  elseif self.uiData.uin ~= myUin then
    self.ChatSwitcher:SetActiveWidgetIndex(0)
    self:UpdateChatMessageDisplay(self.uiData, false, self.friend)
    self:RefreshFriendInfo(RefreshFriendInfoType.All)
  else
    self.ChatSwitcher:SetActiveWidgetIndex(1)
    self:UpdateChatMessageDisplay(self.uiData, true, self.myself)
    self.myself.Name:SetText(_G.DataModelMgr.PlayerDataModel:GetPlayerName())
    local myHeadPath = _G.NRCModeManager:DoCmd(FriendModuleCmd.GetCurrentUsePlayerHead) or ""
    self.myself.HeadPortrait:SetPath(myHeadPath)
    local isVisitChat = self.uiData.msg_detail_info and _G.DataModelMgr.PlayerDataModel:IsVisitState()
    local visitIndex = isVisitChat and _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, self.uiData.uin) or nil
    if visitIndex then
      self.myself.TeamMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.myself.SerialNumber:SetText(string.format("%s%s", visitIndex, "P"))
    else
      self.myself.TeamMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local ShowTimeStampInterval = _G.DataConfigManager:GetFriendGlobalConfig("chat_message_time_CD").num
  if self.uiData.TimeInterval >= ShowTimeStampInterval * 1000 then
    self.TimeStamp:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetTimeStamp(self.uiData.time_stamp)
  else
    self.TimeStamp:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetReportBtnShowState(false)
end

function UMG_Friend_Chitchat_ChatItem_C:OnItemSelected(_bSelected)
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
  self.delayId = _G.DelayManager:DelaySeconds(0.1, function()
    self:SetReportBtnShowState(_bSelected)
  end, self)
end

function UMG_Friend_Chitchat_ChatItem_C:OpItem(opType)
  if opType == FriendEnum.ChatItemRefreshType.FriendRemarkUpdate then
    self:RefreshFriendInfo(RefreshFriendInfoType.Remark)
  elseif opType == FriendEnum.ChatItemRefreshType.HideReportBtn then
    if self.delayID then
      _G.DelayManager:CancelDelayById(self.delayID)
      self.delayID = nil
    end
    self.delayId = _G.DelayManager:DelayFrames(1, self.SetReportBtnShowState, self)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:SetReportBtnShowState(bShow)
  if not (self and UE4.UObject.IsValid(self) and self.myself) or not self.friend then
    Log.Warning("UMG_Friend_Chitchat_ChatItem_C:SetReportBtnShowState is destroyed")
    return
  end
  if true == bShow then
    self.myself.ReportBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.friend.ReportBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.myself.ReportBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.friend.ReportBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:GetHeadIconById(Id)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Id = Id or player.gender
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  local HeadIconPath = ""
  local CardIconConf = _G.DataConfigManager:GetCardIconConf(Id)
  if CardIconConf then
    HeadIconPath = CardIconConf.icon_resource_path
  end
  return string.format("%s%s.%s'", path, HeadIconPath, HeadIconPath)
end

function UMG_Friend_Chitchat_ChatItem_C:IsEmo(message)
  local index = string.find(message, "c#%%_")
  if index and 1 == index then
    return true
  end
  return false
end

function UMG_Friend_Chitchat_ChatItem_C:SetTimeStamp(timeStampMS)
  local timeStamp = math.ceil(timeStampMS / 1000)
  local curTimeStamp = os.time()
  local yearNum = os.date("%Y", curTimeStamp)
  local monthNum = os.date("%m", curTimeStamp)
  local dayNum = os.date("%d", curTimeStamp)
  local HourMin = os.date("%H:%M", timeStamp)
  local todayStamp = os.time({
    day = dayNum,
    month = monthNum,
    year = yearNum,
    hour = 0,
    minute = 0,
    second = 0
  })
  local yesterdayStamp = todayStamp - 86400
  local twoDaysAgoStamp = yesterdayStamp - 86400
  local yearStamp = os.time({
    day = 1,
    month = 1,
    year = yearNum,
    hour = 0,
    minute = 0,
    second = 0
  })
  local stampText = ""
  if timeStamp < yearStamp then
    stampText = os.date("%Y", timeStamp) .. "-" .. os.date("%m", timeStamp) .. "-" .. os.date("%d", timeStamp) .. os.date(" %H:%M", timeStamp)
  elseif timeStamp < twoDaysAgoStamp and timeStamp >= yearStamp then
    stampText = os.date("%m", timeStamp) .. "-" .. os.date("%d", timeStamp) .. os.date(" %H:%M", timeStamp)
  elseif timeStamp < yesterdayStamp and timeStamp >= twoDaysAgoStamp then
    stampText = LuaText.umg_friend_chitchat_chatitem_1 .. HourMin
  elseif timeStamp < todayStamp and timeStamp >= yesterdayStamp then
    stampText = LuaText.umg_friend_chitchat_chatitem_2 .. HourMin
  else
    stampText = HourMin
  end
  self.Text_Time:SetText(stampText)
end

function UMG_Friend_Chitchat_ChatItem_C:AddOrRemove(bAdd, bAnim)
  if bAdd and bAnim then
    self.myself:PlayAnimation(self.myself.In)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:OnDeactive()
end

function UMG_Friend_Chitchat_ChatItem_C:OnAnimationFinished(anim)
  if anim == self.myself.In then
    self.ParentView:AddOrRemoveItem(true, self.index, nil, false)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:EscapeString(original)
  local escaped = original
  escaped = string.gsub(escaped, "\n", "\\n")
  escaped = string.gsub(escaped, "\t", "\\t")
  escaped = string.gsub(escaped, "\r", "\\r")
  escaped = string.gsub(escaped, "\b", "\\b")
  escaped = string.gsub(escaped, "\f", "\\f")
  escaped = string.gsub(escaped, "\"", "\\\"")
  escaped = string.gsub(escaped, "'", "\\'")
  return escaped
end

function UMG_Friend_Chitchat_ChatItem_C:GetShowName(uin, note, name)
  if self.uiData.msg_detail_info and self.uiData.msg_detail_info.session_uin == _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType) then
    if not string.IsNilOrEmpty(note) then
      showName = note
    else
      showName = name
    end
    if not string.IsNilOrEmpty(showName) then
      return showName
    end
  end
  local showName = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendNewRemarkByUin, uin)
  if string.IsNilOrEmpty(showName) then
    if not string.IsNilOrEmpty(note) then
      showName = note
    else
      showName = name
    end
  end
  return showName
end

function UMG_Friend_Chitchat_ChatItem_C:UpdateChatMessageDisplay(chatMessageInfo, isMyMessage, targetPanel)
  if not chatMessageInfo or not targetPanel then
    return
  end
  local chatMsgType = chatMessageInfo.chat_msg_type or _G.ProtoEnum.ChatMessageType.CMT_NORMAL
  if chatMsgType == _G.ProtoEnum.ChatMessageType.CMT_NORMAL then
    self:UpdateNormalMessageDisplay(chatMessageInfo, targetPanel)
  elseif chatMsgType == _G.ProtoEnum.ChatMessageType.CMT_GIVE_GIFT then
    self:UpdateGiftMessageDisplay(chatMessageInfo, targetPanel)
  else
    self:UpdateNormalMessageDisplay(chatMessageInfo, targetPanel)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:UpdateNormalMessageDisplay(chatMessageInfo, targetPanel)
  if self:IsEmo(chatMessageInfo.chat_message) == true then
    targetPanel.Expression:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    targetPanel.TextPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local path = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetEmoPathByEsc, chatMessageInfo.chat_message)
    targetPanel.Expression:SetPath(path)
  else
    targetPanel.Expression:SetVisibility(UE4.ESlateVisibility.Collapsed)
    targetPanel.TextPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    targetPanel.ChatContent:SetText(self:EscapeString(chatMessageInfo.chat_message))
    self:SetFontInfo(chatMessageInfo, targetPanel)
  end
  targetPanel.Gift:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Friend_Chitchat_ChatItem_C:UpdateGiftMessageDisplay(chatMessageInfo, targetPanel)
  targetPanel.Expression:SetVisibility(UE4.ESlateVisibility.Collapsed)
  targetPanel.TextPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  targetPanel.ChatContent:SetVisibility(UE4.ESlateVisibility.Collapsed)
  targetPanel.Gift:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  targetPanel.Text:SetVisibility(UE4.ESlateVisibility.Collapsed)
  targetPanel.ItemMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  targetPanel.Item:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.uiData.gift_data and self.uiData.gift_data.goods_id then
    local bagItem = _G.DataConfigManager:GetBagItemConf(self.uiData.gift_data.goods_id)
    if bagItem then
      targetPanel.Item:SetPath(bagItem.icon)
      targetPanel.ItemMask:SetPath(bagItem.icon)
    end
  else
    Log.Dump(self.uiData, 4, "UpdateGiftMessageDisplay: self.uiData.gift_data.goods_id is nil")
    Log.Warning("UpdateGiftMessageDisplay: self.uiData.gift_data.goods_id is nil")
  end
  local Switcher = targetPanel.NRCSwitcher_0
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if self.uiData.msgSource == FriendEnum.ChatMsgSource.Client then
    Switcher:SetActiveWidgetIndex(0)
  end
  if self.uiData.gift_data.receive_state == nil then
    self.uiData.gift_data.receive_state = _G.ProtoEnum.GiftData.ReceiveState.RS_NONE
    Log.Error("self.uiData.gift_data.receive_state is nil")
  end
  local serverTime = _G.ZoneServer:GetServerTime() / 1000
  local timeStamp = self.uiData.gift_data.expire_time or serverTime
  local timeDiff = serverTime - timeStamp
  if self.uiData.uin == myUin then
    if self.uiData.gift_data.receive_state == _G.ProtoEnum.GiftData.ReceiveState.RS_RECEIVED then
      Switcher:SetActiveWidgetIndex(2)
      targetPanel.ItemMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      targetPanel.Text:SetVisibility(UE4.ESlateVisibility.Visible)
      local tipsText = _G.DataConfigManager:GetLocalizationConf("gift_has_been_accepted").msg
      targetPanel.Text:SetText(tipsText)
    else
      Switcher:SetActiveWidgetIndex(1)
    end
  elseif self.uiData.gift_data.receive_state == _G.ProtoEnum.GiftData.ReceiveState.RS_RECEIVED then
    Switcher:SetActiveWidgetIndex(2)
    targetPanel.ItemMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    targetPanel.Text:SetVisibility(UE4.ESlateVisibility.Visible)
    local tipsText = _G.DataConfigManager:GetLocalizationConf("you_have_accept_gift").msg
    targetPanel.Text:SetText(tipsText)
  else
    Switcher:SetActiveWidgetIndex(0)
  end
  targetPanel:StopAnimation(targetPanel.Star_Loop)
  if self.uiData.gift_data.receive_state ~= _G.ProtoEnum.GiftData.ReceiveState.RS_RECEIVED then
    if timeDiff > 0 then
      Switcher:SetActiveWidgetIndex(3)
      targetPanel.Text:SetVisibility(UE4.ESlateVisibility.Visible)
      local tipsText = _G.DataConfigManager:GetLocalizationConf("gift_has_been_returned01").msg
      if self.uiData.uin == myUin then
        tipsText = _G.DataConfigManager:GetLocalizationConf("gift_has_been_returned02").msg
      end
      targetPanel.Text:SetText(tipsText)
    else
      targetPanel:PlayAnimation(targetPanel.Star_Loop, 0, 0)
    end
  end
end

function UMG_Friend_Chitchat_ChatItem_C:SetFontInfo(chatMessageInfo, targetPanel)
  local Font = targetPanel.ChatContent.Font
  if chatMessageInfo and chatMessageInfo.msg_detail_info and chatMessageInfo.msg_detail_info.need_cypher then
    local FontObject = _G.NRCModuleManager:DoCmd(FriendModuleCmd.GetChatPanelAsset, UEPath.Font_1, "Chat_Main")
    Font.FontObject = FontObject
  else
    local FontObject = _G.NRCModuleManager:DoCmd(FriendModuleCmd.GetChatPanelAsset, UEPath.Font, "Chat_Main")
    Font.FontObject = FontObject
  end
  targetPanel.ChatContent:SetFont(Font)
end

function UMG_Friend_Chitchat_ChatItem_C:OnClickReceiveGift()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Friend_Chitchat_ChatItem_C:OnClickReceiveGift")
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
  if myPlayer then
    local bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    if bInFighting then
      local otherUin = self.uiData and self.uiData.uin or 0
      Log.ErrorFormat("UMG_Friend_Chitchat_ChatItem_C:OnClickReceiveGift \230\136\152\230\150\151\228\184\173\228\184\141\229\133\129\232\174\184\233\162\134\229\143\150\231\164\188\231\137\169, myUin=%s, item uin=%s", tostring(myUin), tostring(otherUin))
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.battle_chat_not_get_BP)
      return
    end
  end
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local curGrade = curPassInfo.battle_pass_brief_info.gift_grade
  if curGrade ~= _G.Enum.BattlePassGiftGrade.BPGG_FREE then
    local text = _G.DataConfigManager:GetLocalizationConf("bp_gift_card_accept_fail01").msg
    if nil == text then
      text = "bp_gift_card_accept_fail01"
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, text)
    return
  end
  if self.uiData and self.uiData.gift_data and self.uiData.gift_data.goods_id then
    local GoodsId = self.uiData.gift_data.goods_id
    Log.Info("UMG_Friend_Chitchat_ChatItem_C:OnClickReceiveGift GoodsId", GoodsId)
  else
    Log.Error("UMG_Friend_Chitchat_ChatItem_C:OnClickReceiveGift self.uiData.gift_data is nil")
    return
  end
  local BPModule = _G.NRCModuleManager:GetModule("BattlePassModule")
  if not BPModule then
    Log.Error("BPModule is nil")
    return
  end
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.uiData.gift_data.goods_id)
  if bagItem and bagItem.num > 0 then
    local text = _G.DataConfigManager:GetLocalizationConf("bp_gift_card_accept_fail02").msg
    if nil == text then
      text = "bp_gift_card_accept_fail02"
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, text)
    return
  end
  local bagModule = _G.NRCModuleManager:GetModule("BagModule")
  if bagModule then
    local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.uiData.gift_data.goods_id)
    local expireStatus = bagModule.data:CheckItemExpireStatus(bagItemConf, expireThreshold)
    if expireStatus.isExpired then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_expired)
      return
    end
  end
  if self.isReqSendingGift then
    Log.Warning("UMG_Friend_Chitchat_ChatItem_C:OnClickReceiveGift isReqSendingGift is true")
    return
  end
  local req = ProtoMessage:newZoneGiftReceivingReq()
  req.giver_uin = self.uiData.uin
  req.goods_id = self.uiData.gift_data.goods_id
  req.goods_type = self.uiData.gift_data.goods_type
  req.gift_unique_id = self.uiData.gift_data.gift_unique_id
  req.goods_num = self.uiData.gift_data.goods_num
  Log.Info("OnClickReceiveGift", req.giver_uin, req.goods_id, req.goods_type, req.gift_unique_id, req.goods_num)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GIFT_RECEIVING_REQ, req, self, self.OnZoneGiftReceivingRsp, false, true)
  self.isReqSendingGift = true
  self.DelayReqID = _G.DelayManager:DelaySeconds(1, function()
    if self.isReqSendingGift then
      self.isReqSendingGift = false
    end
  end)
end

function UMG_Friend_Chitchat_ChatItem_C:OnZoneGiftReceivingRsp(rsp)
  Log.Info("OnZoneGiftReceivingRsp", rsp.ret_info.ret_code)
  if self.DelayReqID then
    _G.DelayManager:CancelDelayById(self.DelayReqID)
    self.DelayReqID = nil
  end
  self.isReqSendingGift = false
  if rsp and rsp.ret_info and rsp.ret_info.ret_code ~= nil then
    if 0 ~= rsp.ret_info.ret_code then
      if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED then
        local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
        local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
        local uin = rsp.ban_info.uin
        local contenText = string.format(banConfig.str, uin, ban_time, rsp.ban_info.ban_reason)
        local dialogContext = DialogContext()
        dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
        return
      end
      local Key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
      local ErrorText = _G.DataConfigManager:GetLocalizationConf(Key, true)
      ErrorText = ErrorText and ErrorText.msg
      if nil == ErrorText then
        local notCfgDes = string.format("%s(%d)", _G.LocalText.NetErrorDefault, rsp.ret_info.ret_code)
        if RocoEnv.IS_SHIPPING or not RocoEnv.IS_EDITOR then
          ErrorText = notCfgDes
        else
          local ErrorCodeDesc = require("Data.PB.ErrorCodeDesc")
          ErrorText = ErrorCodeDesc[rsp.ret_info.ret_code] or notCfgDes
        end
      end
      if nil ~= ErrorText and not string.IsNilOrEmpty(ErrorText) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, ErrorText)
      else
        Log.Warning("ErrorText is nil or empty", rsp.ret_info.ret_code)
      end
      return
    end
    self.uiData.gift_data.receive_state = _G.ProtoEnum.GiftData.ReceiveState.RS_RECEIVED
    self:UpdateGiftMessageDisplay(self.uiData, self.friend)
    local rewardList = {
      {
        id = self.uiData.gift_data.goods_id,
        num = self.uiData.gift_data.goods_num,
        type = self.uiData.gift_data.goods_type
      }
    }
    local CommonPopUpData = _G.NRCCommonPopUpData()
    CommonPopUpData.Call = self
    CommonPopUpData.Btn_LeftHandler = self.OnUseItemclick
    CommonPopUpData.HideBtn = false
    CommonPopUpData.OnlyHideRightBtn = true
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo)
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardList, nil, nil, nil, nil, nil, false, CommonPopUpData)
  end
end

function UMG_Friend_Chitchat_ChatItem_C:OnClickItemTips()
  if self.uiData and self.uiData.gift_data and self.uiData.gift_data.goods_id and self.uiData.gift_data.goods_type then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, self.uiData.gift_data.goods_id, self.uiData.gift_data.goods_type, false)
  else
    Log.Error("UMG_Friend_Chitchat_ChatItem_C:OnClickItemTips self.uiData.gift_data is nil")
  end
end

function UMG_Friend_Chitchat_ChatItem_C:OnUseItemclick()
  Log.Debug("UMG_Friend_Chitchat_ChatItem_C:OnUseItemclick")
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Friend_Chitchat_ChatItem_C:OnUseItemclick")
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.CloseNPCShopItemRewardsPanel)
  local GoodsId = self.uiData.gift_data.goods_id
  local GoodsUniqueId = self.uiData.gift_data.gift_unique_id
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeAndUnlockGift, GoodsId, GoodsUniqueId)
end

return UMG_Friend_Chitchat_ChatItem_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ProtoEnum = require("Data.PB.ProtoEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_Friend_Item_C = Base:Extend("UMG_Friend_Itme_C")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")

function UMG_Friend_Item_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_Friend_Item_C", self, FriendModuleEvent.OnFriendBatchModeUpdate, self.OnFriendBatchModeUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_Friend_Item_C", self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.OnModifyFriendRemarkUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_Friend_Item_C", self, FriendModuleEvent.OnFriendExtInfoUpdate, self.OnFriendExtInfoUpdate)
  self.module = _G.NRCModuleManager:GetModule("FriendModule")
  self.moduleData = self.module:GetData("FriendModuleData")
  self.VisitNumMax = self.module:GetVisitNumMax()
  if self.isBatchMode == nil then
    self.isBatchMode = false
  end
end

function UMG_Friend_Item_C:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnFriendBatchModeUpdate, self.OnFriendBatchModeUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.OnModifyFriendRemarkUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnFriendExtInfoUpdate, self.OnFriendExtInfoUpdate)
  if self.inviteCdTimer then
    self.inviteCdTimer:Stop()
    self.inviteCdTimer = nil
  end
end

function UMG_Friend_Item_C:OnModifyFriendRemarkUpdate(uin, newRemark)
  if not self.data then
    return
  end
  if self.data.uin == uin then
    self:UpdatePlayerNameInfo()
  end
end

function UMG_Friend_Item_C:OnFriendBatchModeUpdate(isBatchMode)
  if not self.data then
    return
  end
  local CurSelectTabIndex = self:GetFriendTabType()
  if CurSelectTabIndex == FriendEnum.FriendTab.GameFriend then
    if self.isBatchMode == nil or self.isBatchMode ~= isBatchMode then
      if self.moduleData:GetIsFriendBatchDeleteMode() then
        self:PlayAnimation(self.Delete)
      else
        self:PlayAnimation(self.Recover)
      end
    end
    self.isBatchMode = isBatchMode
  end
  self:UpdateInfo()
end

function UMG_Friend_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.RedDot:SetupKey(82, {
    self.data.uin
  })
  self.index = index
  self.Offset = 0
  self.vector2DZero = UE4.FVector2D(0, 0)
  if self.isShowSelectAnim then
    self:ResetUnselectedState()
  end
  self:CheckAndPlayRecoverAnimation()
  self.isShowSelectAnim = false
  self.isLogicSelected = false
  self:UpdateInfo()
  self:SetPanelBaseInfo()
  self:OnAddEventListener()
  if nil == _data then
    Log.Error("UMG_Friend_Item_C:OnItemUpdate _data is nil", table.isArray(datalist), #datalist, index)
  end
  self:UpdateHomeInfoUI()
  self:CheckAndRequestFriendHomeInfoData(index, datalist)
end

function UMG_Friend_Item_C:CheckAndRequestFriendHomeInfoData(index, datalist)
  if not self:IsNeedShowHomeRedDot() then
    return
  end
  if self.moduleData:TryGetFriendExtInfoByUin(self.data.uin) then
    return
  end
  if not datalist or 0 == #datalist or index > #datalist then
    return
  end
  local curTimeMs = os.msTime()
  local hasReqHomeInfo, lastReqHomeInfoTime = self.moduleData:TryGetHomeInfoReqMsTimeForFriendPanel(self.data.uin)
  local timeoutMs = self.moduleData:GetThresholdTimeoutMsForReqHomeInfo()
  if hasReqHomeInfo and timeoutMs > curTimeMs - lastReqHomeInfoTime then
    return
  end
  local maxReqCount = self.moduleData:GetMaxNumForFriendExtInfoListReq()
  local reqCount = 0
  local reqUinList = {}
  for i = index, #datalist do
    local friendRoleInfo = datalist[i]
    if not friendRoleInfo or not friendRoleInfo.uin then
    elseif self.moduleData:TryGetFriendExtInfoByUin(friendRoleInfo.uin) then
    else
      local hasReqTemp, lastReqTimeTemp = self.moduleData:TryGetHomeInfoReqMsTimeForFriendPanel(friendRoleInfo.uin)
      if hasReqTemp and timeoutMs > curTimeMs - lastReqTimeTemp then
      else
        table.insert(reqUinList, friendRoleInfo.uin)
        reqCount = reqCount + 1
        self.moduleData:SetHomeInfoReqMsTimeForFriendPanel(friendRoleInfo.uin, curTimeMs)
        if maxReqCount <= reqCount then
          break
        end
      end
    end
  end
  if #reqUinList > 0 then
    self.module:RequestFriendExtInfoList(reqUinList)
  end
end

function UMG_Friend_Item_C:IsNeedShowHomeRedDot()
  local friendTabType = self:GetFriendTabType()
  return friendTabType == FriendEnum.FriendTab.GameFriend or friendTabType == FriendEnum.FriendTab.PlatformFriend
end

function UMG_Friend_Item_C:OnFriendExtInfoUpdate()
  if self:IsNeedShowHomeRedDot() then
    self:UpdateHomeInfoUI()
  end
end

function UMG_Friend_Item_C:UpdateHomeInfoUI()
  if not self.data then
    return
  end
  if not self:IsNeedShowHomeRedDot() then
    self.EntranceToTheHome.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local has, result = self.moduleData:TryGetFriendExtInfoByUin(self.data.uin)
  local friendExtInfo = has and result or nil
  local bShowRedDot = friendExtInfo and friendExtInfo.home_ext_info and (friendExtInfo.home_ext_info.home_pet_can_steal == true or true == friendExtInfo.home_ext_info.home_plant_can_pick and not FarmUtils.IsLocalPlayerReachStealLimit())
  if bShowRedDot then
    self.EntranceToTheHome.RedDot:ShowRedPoint(true)
    self.EntranceToTheHome.RedDot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.EntranceToTheHome.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Item_C:PlayInAnimation()
  if self.index <= 50 then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.DelayId = _G.DelayManager:DelaySeconds(0.1 * self.index, function()
      self:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.Appear)
    end)
  end
end

function UMG_Friend_Item_C:SetPanelBaseInfo()
  local PanelName = self:GetParentCustomData()
  local Entrance = _G.NRCModuleManager:DoCmd(FriendModuleCmd.GetEntrance)
  Log.Debug(Entrance, PanelName, self.index, "UMG_Friend_Item_C:SetPanelBaseInfo")
  if Entrance == FriendEnum.OpenFriendEntrance.Chat and PanelName and "FriendChat" == PanelName then
    self.BtnCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BtnCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Friend_Item_C:SetParentInfo(_Parent, _ParentSwitcherOffset)
  if self.HeadItem then
    self.HeadItem:SetParentInfo(_Parent, _ParentSwitcherOffset)
    self.HeadItem:SetItemSize(self.ItemSize.Slot:GetSize())
  end
end

function UMG_Friend_Item_C:SetSwitcher()
  self.Switcher:SetActiveWidgetIndex(1)
  self.Btn_RequestAccess:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Friend_Item_C:SetTimeText(delaTime)
end

function UMG_Friend_Item_C:OnAddEventListener()
  self.SendMessage.btnLevelUp.OnClicked:Add(self, self.OnSendMessage)
  self.AddFriends.btnLevelUp.OnClicked:Add(self, self.OnAddFriends)
  self.Btn_RequestAccess.btnLevelUp.OnClicked:Add(self, self.StartFriendVisit)
  self.NewsBtn.OnClicked:Add(self, self.OnSendMessage)
  self.AddBtn.OnClicked:Add(self, self.OnAddFriends)
  self.AcceptBtn.OnClicked:Add(self, self.OnClickConsent)
  self.WorldBtn.OnClicked:Add(self, self.OnClickWorldBtn)
  self.WeiXinBtn.OnClicked:Add(self, self.OnClickWeiXinBtn)
  self.QQBtn.OnClicked:Add(self, self.OnClickQQBtn)
  self.WeGameBtn.OnClicked:Add(self, self.OnClickWeGameBtn)
  self.DeleteBtn.OnClicked:Add(self, self.OnClickDeleteBtn)
  self.Watch.btnLevelUp.OnClicked:Add(self, self.OnClickWatchFriendBattleButton)
  self.EntranceToTheHome.btnLevelUp.OnClicked:Add(self, self.OnClickEntranceToTheHomeButton)
  self.AcceptBtn1.OnClicked:Add(self, self.OnBatchDeleteFriendBtn)
  self.Privilege.QQBtn.OnClicked:Add(self, self.OnClickedQQ)
  self.Privilege.WeiXinBtn.OnClicked:Add(self, self.OnClickedWX)
  self.SendAttachment.btnLevelUp.OnClicked:Add(self, self.OnTeleportPlayer)
end

function UMG_Friend_Item_C:OnSendMessage()
  self.module:ReportTLog(3, 5, self.data)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHAT, true)
  if isBan then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").MESSAGE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnSendMessage")
  NRCProfilerLog:NRCClickBtn(true, "Chat_Main")
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
  local bInFighting = false
  if myPlayer then
    bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanelByFriendPanel, self.data.uin, self.index, bInFighting)
end

function UMG_Friend_Item_C:OnAddFriends()
  if self:CheckIsSelectBtn() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Report_C:OnConfirm")
  if self.data.isSearch and self.data.can_be_add_friend == false then
    if _G.DataModelMgr.PlayerDataModel:IsFriend(self.data.uin) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.add_friend_repeate_tips)
      Log.DebugFormat("UMG_Friend_Item_C:OnAddFriends uin = %s, is already friend", tostring(self.data.uin))
      return
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.RLTT_Error_Code_13025)
    Log.WarningFormat("UMG_Friend_Item_C:OnAddFriends uin = %s, can_be_add_friend = false", tostring(self.data.uin))
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").ADDFRIEND
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.AddFriendApplicationOrRemoveFriend, self.data.uin, _G.ProtoEnum.ZoneFriendAddOrRemoveFriendReq.TYPE.ADD_FRIEND, self.index)
end

function UMG_Friend_Item_C:OnClickConsent()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").ACCEPT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickConsent")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.FriendConfirmAddFriend, self.data.uin, _G.ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.AGREE_REQ, self.index)
end

function UMG_Friend_Item_C:OnClickWorldBtn()
  self.module:ReportTLog(3, 4, self.data)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_VISITOR, true)
  if isBan then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").WORLD
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  local playerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local Level = _G.DataConfigManager:GetOnlineGlobalConfig(1).num
  if playerLevel >= Level then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickDeleteBtn")
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendWold, self.data, self.index)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("cant_online_apply_mine").msg, Level))
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  end
end

function UMG_Friend_Item_C:OnClickDeleteBtn()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").DELETE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickDeleteBtn")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.FriendConfirmAddFriend, self.data.uin, _G.ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.REFUSE_REQ, self.index)
end

function UMG_Friend_Item_C:OnBatchDeleteFriendBtn()
  if self.moduleData:IsFriendBatchDeleteUinContain(self.data.uin) then
    self.moduleData:RemoveFriendBatchDeleteUin(self.data.uin)
    self:PlayAnimation(self.Back)
  else
    self.moduleData:AddFriendBatchDeleteUin(self.data.uin)
    self:PlayAnimation(self.Choose)
  end
  self:UpdateInfo()
end

function UMG_Friend_Item_C:OnTeleportPlayer()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnTeleportPlayer")
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OnCmdTeleportToPlayerReq, self.data.uin)
end

function UMG_Friend_Item_C:OnClickedQQ()
  if self.Privilege then
    self.Privilege:OnClickedQQ()
  end
end

function UMG_Friend_Item_C:OnClickedWX()
  if self.Privilege then
    self.Privilege:OnClickedWX()
  end
end

function UMG_Friend_Item_C:OnClickWatchFriendBattleButton()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").WATCH
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.WatchFriendBattle, self.data.uin)
end

function UMG_Friend_Item_C:OnClickEntranceToTheHomeButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickEntranceToTheHomeButton")
  self.module:ReportTLog(3, 3, self.data)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.CmdSendZoneHomeQueryFriendHomeInfoReq, self.data.uin)
end

function UMG_Friend_Item_C:UpdateInfo()
  local Data = self.data
  if not Data then
    Log.Error("UMG_Friend_Item_C:SetData")
    return
  end
  self:UpdatePlayerNameInfo()
  if Data.online then
    self.WorldBtn:SetIsEnabled(true)
    self.State:SetActiveWidgetIndex(0)
    self:PrepareOnlineData()
    self.OnlineOrNot_Title:SetText(self.onlineTitle)
    self.WeGameTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.WorldBtn:SetIsEnabled(false)
    self.State:SetActiveWidgetIndex(1)
    local LastLogoutTime = Data.last_logout_time or 0
    local nowTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
    local TimeDiff = nowTime - LastLogoutTime
    local min = math.floor(TimeDiff / 60)
    local hour = math.floor(min / 60)
    local day = math.floor(hour / 24)
    Log.Debug(LastLogoutTime, nowTime, TimeDiff, min, hour, day, Data.name, "UMG_Friend_Itme_C:SetData")
    if day >= 7 then
      self.Offline:SetText(LuaText.umg_friend_item_2)
    else
      local Text
      if day < 7 and hour >= 24 then
        Text = string.format(LuaText.umg_friend_item_3, day)
      elseif hour < 24 and hour > 0 then
        Text = string.format(LuaText.umg_friend_item_4, hour)
      elseif min < 60 and min >= 1 then
        Text = string.format(LuaText.umg_friend_applyfor_item_6, min)
      elseif min < 1 and min >= 0 then
        Text = LuaText.umg_friend_applyfor_item_5
      end
      self.Offline:SetText(Text)
    end
    if self.data.isWeGameFriend then
      self.WeGameTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local wegameOnlineState = ""
      if self:IsOnlineWeGameFriend() then
        if self.data.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateBusy then
          wegameOnlineState = LuaText.wegame_friends_info3
        else
          wegameOnlineState = LuaText.wegame_friends_info1
        end
        self.WeGameOnline:SetText(wegameOnlineState)
        self.WeGameTips:SetActiveWidgetIndex(0)
      else
        wegameOnlineState = LuaText.wegame_friends_info2
        self.WeGameOffline:SetText(wegameOnlineState)
        self.WeGameTips:SetActiveWidgetIndex(1)
      end
    end
  end
  if not self.data.isWeGameFriend then
    self.WeGameTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetHeadInfo()
  self:SetBtnByTab()
  self:SetLabel()
  self:UpdatePrivilegeUI()
  self.Btn_RequestAccess:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCImage_13:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not self.moduleData:GetIsFriendBatchDeleteMode() then
    self.EntranceToTheHome:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.EntranceToTheHome:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.data.pinned_time and self.data.pinned_time > 0 then
    self.TopPositionIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TopPositionIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Data.is_chat_node_unlock ~= nil then
    if Data.is_chat_node_unlock then
      self.NewsBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.NewsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.data.isWeGameFriend then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Starlight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if Data.tags then
    for _, tag in ipairs(Data.tags) do
      if tag == _G.ProtoEnum.PlayerTag.PT_RECALL then
        self.Starlight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  self:UpdateVisitInfo()
  self:UpdateBehaviorInfo()
  self:SetSignature()
end

function UMG_Friend_Item_C:IsOnlineWeGameFriend()
  if self.data.isWeGameFriend and not string.IsNilOrEmpty(self.data.onlineState) and (self.data.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateInGame or self.data.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateBusy or self.data.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateOnline) then
    return true
  end
  return false
end

function UMG_Friend_Item_C:UpdatePlayerNameInfo()
  if not self.data then
    return
  end
  if not self.RemarkName or not self.Name_1 then
    return
  end
  local name = self.data.name or ""
  local note = self.data.note or ""
  local platformName = self.data.plat_nick_name or ""
  if self.data.isWeGameFriend then
    platformName = self.data.nickName
  end
  self.RemarkName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local gameNameShow, gameColorShow
  if note and "" ~= note then
    gameNameShow = note
    gameColorShow = UE4.UNRCStatics.HexToSlateColor("d56c1fff")
  else
    gameNameShow = name
    if self.isLogicSelected then
      gameColorShow = UE4.UNRCStatics.HexToSlateColor("272727ff")
    else
      gameColorShow = UE4.UNRCStatics.HexToSlateColor("f4eee1ff")
    end
  end
  self.RemarkName:SetText(gameNameShow)
  self.RemarkName:SetColorAndOpacity(gameColorShow)
  if platformName and "" ~= platformName then
    self.Name_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local totalNum = _G.DataConfigManager:GetGlobalConfigNumByKey("share_nickname_limit_num", 7)
    local nickNameLength = utf8.len(platformName)
    if totalNum < nickNameLength then
      platformName = UIUtils.SubUTF8String(platformName, totalNum)
      platformName = platformName .. "..."
    end
    local platformShowName = string.format("(%s)", platformName)
    local platformColorShow
    if self.isLogicSelected then
      platformColorShow = UE4.UNRCStatics.HexToSlateColor("272727ff")
    else
      platformColorShow = UE4.UNRCStatics.HexToSlateColor("f4eee1ff")
    end
    self.Name_1:SetText(platformShowName)
    self.Name_1:SetColorAndOpacity(platformColorShow)
  else
    self.Name_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Item_C:SetSignature()
  if self.Signature0 then
    self.Signature0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local signatureText = ""
  if self.data.signature == nil or "" == self.data.signature then
    signatureText = _G.DataConfigManager:GetLocalizationConf("card_signature_input_empty_text").msg
  else
    signatureText = self.data.signature
  end
  local battleText = self.OnlineOrNot_Title:GetText()
  local battleTextNum = utf8.len(battleText)
  local totalNum = _G.DataConfigManager:GetGlobalConfigNumByKey("status_signature_num_sum", 20)
  local signatureTextNum = utf8.len(signatureText)
  if totalNum < battleTextNum + signatureTextNum then
    local maxSignatureNum = totalNum - battleTextNum
    if maxSignatureNum > 3 then
      signatureText = self:SubUTF8String(signatureText, maxSignatureNum) .. "..."
    elseif maxSignatureNum > 0 then
      signatureText = self:SubUTF8String(signatureText, maxSignatureNum)
    else
      signatureText = ""
    end
  end
  UIUtils.SafeSetText(self.Signature, signatureText)
end

function UMG_Friend_Item_C:SubUTF8String(str, maxChars)
  return UIUtils.SubUTF8String(str, maxChars)
end

function UMG_Friend_Item_C:GetSelfLoginChannelType()
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local loginChannelType = accountInfo and accountInfo.plat_info and accountInfo.plat_info.cli_login_channel or nil
  return loginChannelType
end

function UMG_Friend_Item_C:UpdatePrivilegeUI()
  local data = self.data
  if not data then
    self.Privilege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if not data.start_up_privilege_info then
    self.Privilege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if data.cli_login_channel ~= Enum.CliLoginChannel.CLC_WX and data.cli_login_channel ~= Enum.CliLoginChannel.CLC_QQ then
    self.Privilege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local loginChannelType = self:GetSelfLoginChannelType()
  local IsBan = false
  if loginChannelType == Enum.CliLoginChannel.CLC_WX then
    IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_WX_VIP, false)
  elseif loginChannelType == Enum.CliLoginChannel.CLC_QQ then
    IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_QQ_VIP, false)
  end
  if IsBan then
    Log.Error("UpdatePrivilegeUI System Ban from WX")
    self.Privilege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if self.data.isWeGameFriend then
    self.Privilege:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.Privilege:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local startUpPrivilegeInfo = data.start_up_privilege_info
  self.Privilege:SetData(data.cli_login_channel, startUpPrivilegeInfo)
end

function UMG_Friend_Item_C:GetFriendTabType()
  local friendListCustomData = self:GetParentCustomData()
  if friendListCustomData and friendListCustomData.curTabType then
    return friendListCustomData.curTabType
  else
    Log.Warning("UMG_Friend_Item_C:GetFriendTabType friendListCustomData is nil")
    return -1
  end
end

function UMG_Friend_Item_C:SetBtnByTab()
  local CurSelectTabIndex = self:GetFriendTabType()
  self.Watch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetBatchState(false)
  self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if CurSelectTabIndex == FriendEnum.FriendTab.GameFriend then
    if self.moduleData:GetIsFriendBatchDeleteMode() then
      self:SetBatchState(true)
    else
      self.Switcher:SetActiveWidgetIndex(0)
      if self.data.online and self.canBeWatchBattle then
        self.Watch:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  elseif CurSelectTabIndex == FriendEnum.FriendTab.PlatformFriend then
    self.Switcher:SetActiveWidgetIndex(0)
    if self.data.online and self.canBeWatchBattle then
      self.Watch:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif CurSelectTabIndex == FriendEnum.FriendTab.SearchFriend then
    if not self.data.isSearch then
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Switcher:SetActiveWidgetIndex(1)
  elseif CurSelectTabIndex == FriendEnum.FriendTab.WeGameFriend then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Watch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.CanvasPanel_197:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.data.source then
    local conf = self.moduleData:GetFriendRecommendConfBySource(self.data.source)
    if conf then
      self.hufang:SetText(conf.table_name)
      self.CanvasPanel_197:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      Log.ErrorFormat("UMG_Friend_Item_C:SetBtnByTab conf is nil, source: %s", tostring(self.data.source))
    end
  end
  self:SelectSwitcher1()
end

function UMG_Friend_Item_C:SelectSwitcher1()
  local selectIndex = 8
  local showGrayTeleport = false
  local CurSelectTabIndex = self:GetFriendTabType()
  local isPlatOrWegameFriendTab = CurSelectTabIndex == FriendEnum.FriendTab.PlatformFriend or CurSelectTabIndex == FriendEnum.FriendTab.WeGameFriend
  if self.data.online then
    selectIndex = 8
    showGrayTeleport = false
  elseif not isPlatOrWegameFriendTab then
    selectIndex = 8
    showGrayTeleport = true
  else
    local isQQFriend = self.moduleData:GetLoginChannelType() == Enum.CliLoginChannel.CLC_QQ and (self.data.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_PLAT or self.data.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_ALL)
    local isWXFriend = self.moduleData:GetLoginChannelType() == Enum.CliLoginChannel.CLC_WX and (self.data.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_PLAT or self.data.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_ALL)
    local isHideQQInvite = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_QQ_FRIEND_INVITE, false)
    local isHideWXInvite = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_WX_FRIEND_INVITE, false)
    if CurSelectTabIndex == FriendEnum.FriendTab.WeGameFriend and (_G.UE4Helper.IsPCMode() or RocoEnv.IS_EDITOR) then
      if self.data.isWeGameFriend then
        if self.data.online then
          selectIndex = 8
        elseif self:IsOnlineWeGameFriend() and not self.data.online then
          selectIndex = 7
        else
          selectIndex = 8
          showGrayTeleport = true
        end
      end
    elseif isQQFriend and not isHideQQInvite then
      selectIndex = 5
    elseif isWXFriend and not isHideWXInvite then
      selectIndex = 6
    else
      selectIndex = 8
      showGrayTeleport = true
    end
  end
  self.Switcher1:SetActiveWidgetIndex(selectIndex)
  self.Switcher1:GetActiveWidget():SetVisibility(UE4.ESlateVisibility.Visible)
  if showGrayTeleport then
    self.SendAttachment:SwitchState(2)
    self.Switcher1:GetActiveWidget():SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.SendAttachment:SwitchState(1)
  end
end

function UMG_Friend_Item_C:OnClickWeiXinBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickWeiXinBtn")
  Log.DebugFormat("UMG_Friend_Item_C:OnClickWeiXinBtn, openid = %s", tostring(self.data.openid))
  local title = LuaText.Invite_Friend_Limit1
  local content = LuaText.Invite_Friend_Limit2
  NRCModuleManager:DoCmd(ShareModuleCmd.ShareInviteWechat, title, content, self.data.openid, self.data.uin, self.data.name)
end

function UMG_Friend_Item_C:OnClickQQBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickQQBtn")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdQQArkServerInviteFriendReq, self.data.uin)
end

function UMG_Friend_Item_C:OnClickWeGameBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnClickWeGameBtn")
  if not self.data.platformOpenID then
    return
  end
  if not self.inviteCdTimer then
    local cd = _G.DataConfigManager:GetGlobalConfig("friend_invite_cd") and _G.DataConfigManager:GetGlobalConfig("friend_invite_cd").num or 30
    self.inviteCdTimer = _G.TimerManager:CreateTimer(self, "UMG_Friend_Item_C" .. self.data.platformOpenID, cd, nil, self.OnInviteCdFinished, 0.1)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Invite_Friend_Limit6)
    return
  end
  local inviteRes = _G.NRCSDKManager:InviteWeGameFriend(self.data.platformOpenID)
  if not inviteRes or inviteRes == math.mininteger then
    local failTips = _G.DataConfigManager:GetLocalizationConf("Invite_Friend_Limit8") and _G.DataConfigManager:GetLocalizationConf("Invite_Friend_Limit8").msg or ""
    failTips = failTips .. "(" .. math.mininteger .. ")"
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, failTips)
  elseif 0 == inviteRes then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Invite_Friend_Limit5)
  else
    local failTips = _G.DataConfigManager:GetLocalizationConf("Invite_Friend_Limit8") and _G.DataConfigManager:GetLocalizationConf("Invite_Friend_Limit8").msg or ""
    failTips = failTips .. "(" .. inviteRes .. ")"
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, failTips)
  end
end

function UMG_Friend_Item_C:OnInviteCdFinished()
  if self.inviteCdTimer then
    self.inviteCdTimer:Stop()
    self.inviteCdTimer = nil
  end
end

function UMG_Friend_Item_C:SetBatchState(isBatchMode)
  if isBatchMode then
    if self.AcceptBtn1 then
      self.AcceptBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.Switcher then
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.Switcher1 then
      self.Switcher1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local isSelectedDelete = self.moduleData:IsFriendBatchDeleteUinContain(self.data.uin)
    if isSelectedDelete then
      if not self:IsAnimationPlaying(self.Choose) then
        self:PlayAnimation(self.Choose_Loop)
      end
      _G.NRCAudioManager:PlaySound2DAuto(40007001, "UMG_Friend_Item_C:OnItemSelected")
    else
      if not self:IsAnimationPlaying(self.Back) then
        self:PlayAnimation(self.Normal)
      end
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_Item_C:OnItemSelected")
    end
  else
    if self.AcceptBtn1 then
      self.AcceptBtn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.Switcher then
      self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Switcher1 then
      self.Switcher1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Friend_Item_C:SetLabel()
  local Path = UEPath.CARD_COMMON_PATH
  local Id = not self.data.card_skin_selected and self.data.card_info and self.data.card_info.card_appearance_info and self.data.card_info.card_appearance_info.card_skin_selected
  if Id and 0 ~= Id and _G.DataConfigManager:GetCardSkinConf(Id) then
    local CardSkinConf = _G.DataConfigManager:GetCardSkinConf(Id)
    local SkinPath = string.format(Path, CardSkinConf.skin_resource_path, "Skin", CardSkinConf.skin_resource_path, "Skin")
    self.skin_1:SetPath(SkinPath)
    self.Grade:Init(Id)
    if CardSkinConf.level_icon and CardSkinConf.level_icon ~= "" then
      self:PlayAnimation(self.shine_loop)
    else
      self:PlayAnimation(self.shine_no)
    end
  else
  end
  local CardInfo = self.data and self.data.card_info
  if self.data.card_label_first_selected and self.data.card_label_first_selected and 0 ~= self.data.card_label_first_selected or CardInfo and CardInfo.card_label_first_selected and 0 ~= CardInfo.card_label_first_selected and CardInfo.card_label_last_selected and 0 ~= CardInfo.card_label_last_selected then
    self.BriefIntroduction:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Label:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local CardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(self.data and self.data.card_label_first_selected or CardInfo and CardInfo.card_label_first_selected)
    local CardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(self.data and self.data.card_label_last_selected or CardInfo and CardInfo.card_label_last_selected)
    if CardLabelLastConf and CardLabelFirstConf then
      self.BriefIntroduction:SetText(string.format("%s%s", CardLabelFirstConf.label_text, CardLabelLastConf.label_text))
    end
  else
    self.BriefIntroduction:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Label:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Item_C:SetHeadInfo()
  if self.HeadItem then
    local data = self.data
    local CurSelectTabIndex = self:GetFriendTabType()
    local studentCardForbidAddFriend = CurSelectTabIndex == FriendEnum.FriendTab.SearchFriend and not self.data.isSearch
    local hideLevel = CurSelectTabIndex == FriendEnum.FriendTab.SearchFriend
    local isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(self.data.uin)
    local forbidStudentCardForStranger = CurSelectTabIndex == FriendEnum.FriendTab.SearchFriend and not isFriend
    self.HeadItem:SetInfo(data, self.index, studentCardForbidAddFriend, hideLevel, forbidStudentCardForStranger)
  end
end

function UMG_Friend_Item_C:ResetUnselectedState()
  if not self.isShowSelectAnim then
    return
  end
  Log.Debug("UMG_Friend_Item_C:ResetUnselectedState", self.index)
  if self.HeadItem then
    self.HeadItem:PlayAni(false)
  end
  self:PlayAnimation(self.Select_out, 0, 1, UE4.EUMGSequencePlayMode.Forward, 10)
end

function UMG_Friend_Item_C:CheckAndPlayRecoverAnimation()
  local CurSelectTabIndex = self:GetFriendTabType()
  if CurSelectTabIndex == FriendEnum.FriendTab.GameFriend and not self.isBatchMode then
    self:StopAnimation(self.Recover)
    self:StopAnimation(self.Delete)
    self:StopAnimation(self.Back)
    self:StopAnimation(self.Normal)
    self:StopAnimation(self.Choose)
    self:StopAnimation(self.Choose_Loop)
    self:PlayAnimation(self.Recover_Loop)
  end
end

function UMG_Friend_Item_C:OnItemSelected(_bSelected, bScrolled)
  if not self then
    Log.Error("UMG_Friend_Item_C:OnItemSelected self is nil")
    return
  end
  if self.HeadItem then
    self.HeadItem:PlayAni(_bSelected)
  end
  self.isLogicSelected = _bSelected
  if _bSelected then
    local CurSelectTabIndex = self:GetFriendTabType()
    if not bScrolled and CurSelectTabIndex == FriendEnum.FriendTab.GameFriend and self.moduleData:GetIsFriendBatchDeleteMode() then
      self:OnBatchDeleteFriendBtn()
    end
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.SetSelectFriendIndex, self.index)
    if not self.moduleData:GetIsFriendBatchDeleteMode() then
      _G.NRCAudioManager:PlaySound2DAuto(40006008, "UMG_Friend_Item_C:OnItemSelected")
    end
    self:PlayAnimation(self.Select_in)
  else
    self:PlayAnimation(self.Select_out)
  end
  self:UpdatePlayerNameInfo()
end

function UMG_Friend_Item_C:AddOrRemove(bAdd, bAnim)
  if bAnim then
    if bAdd then
      self:PlayAnimationReverse(self.Add)
    else
      self:PlayAnimation(self.Add)
    end
  end
end

function UMG_Friend_Item_C:OnAnimationFinished(Animation)
  if Animation == self.Add then
    self.ParentView:AddOrRemoveItem(false, self.index, nil, false)
  elseif Animation == self.Select_out then
    self.isShowSelectAnim = false
    Log.Debug("1111UMG_Friend_Item_C:OnAnimationFinished", self.index, "finish Select_out, set bIsSelect is false")
  elseif Animation == self.Select_in then
    self.isShowSelectAnim = true
    Log.Debug("1111UMG_Friend_Item_C:OnAnimationFinished", self.index, "finish Select_in, set bIsSelect is true")
  end
end

function UMG_Friend_Item_C:StartFriendVisit()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").STARTVISIT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  local tackTaskList = NRCModuleManager:DoCmd(_G.TaskModuleCmd.getAllTraceTask, true)
  _G.NRCAudioManager:PlaySound2DAuto(1086, "UMG_Friend_Item_C:StartFriendVisit")
  for i = 1, #tackTaskList do
    if tackTaskList[i].Config.online_forbid then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_2147").msg, tackTaskList[i].Config.name))
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
      return
    end
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("online_exit").msg)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
    return
  end
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.ReqZonePlayerInteract, self.data.uin, ProtoEnum.PlayerInteractType.Visiting)
end

function UMG_Friend_Item_C:GoFriendVisit()
end

function UMG_Friend_Item_C:SetVisitState()
end

function UMG_Friend_Item_C:PrepareOnlineData()
  local friendListOnlineTextConfig = _G.DataConfigManager:GetLocalizationConf("friend_list_online_text")
  local onlineTitle = friendListOnlineTextConfig and friendListOnlineTextConfig.msg or ""
  local dataState = self.data.state
  local battleBriefInfo = self.data.battle_brief_info
  local canBeWatchBattle = false
  if nil ~= dataState and nil ~= next(battleBriefInfo) and battleBriefInfo.battle_state and battleBriefInfo.battle_state > 0 then
    local isInBattleState = battleBriefInfo.battle_state == ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IN_BATTLE
    local battleConfId = battleBriefInfo and battleBriefInfo.battle_conf_id
    local isConfigCanBeWatchBattle = BattleUtils.IsBattleConfigIdCanBeWatch(battleConfId)
    local battleConf = _G.DataConfigManager:GetBattleConf(battleConfId)
    local battleType = battleConf and battleConf.type
    local battleTypeConf = battleType and _G.DataConfigManager:GetBattleTypeConf(battleType)
    canBeWatchBattle = isConfigCanBeWatchBattle and isInBattleState or false
    local battleTypeName = battleTypeConf and battleTypeConf.name or ""
    local pvpBattleWatchChar6Config = _G.DataConfigManager:GetBattleGlobalConfig("pvp_battlewatch_character6")
    local pvpBattleWatchChar6
    if pvpBattleWatchChar6Config then
      pvpBattleWatchChar6 = pvpBattleWatchChar6Config.str
    end
    if canBeWatchBattle then
      onlineTitle = string.format(pvpBattleWatchChar6, battleTypeName)
    end
  end
  self.onlineTitle = onlineTitle
end

function UMG_Friend_Item_C:OnDeactive()
end

function UMG_Friend_Item_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "FriendModule", "Friend")
end

function UMG_Friend_Item_C:UpdateVisitInfo()
  local data = self.data
  if self.MutualVisits then
    self.MutualVisits:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not data then
    Log.Error("UMG_Friend_Item_C:UpdateVisitInfo data is nil")
    return
  end
  local visitInfo = data.visit_info
  if not visitInfo then
    return
  end
  local visitNum = visitInfo.visitor_num
  if not visitNum then
    return
  end
  if visitNum > 0 then
    local visitNumText = string.format("%d/%d", visitNum, self.VisitNumMax)
    self.MutualVisitsText:SetText(visitNumText)
    self.MutualVisits:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Friend_Item_C:UpdateBehaviorInfo()
  local data = self.data
  if not data then
    Log.Error("UMG_Friend_Item_C:UpdateBehaviorInfo data is nil")
    return
  end
  local onlineTitle = self.module:GetFriendBehaviorText(data)
  self.OnlineOrNot_Title:SetText(onlineTitle)
end

return UMG_Friend_Item_C

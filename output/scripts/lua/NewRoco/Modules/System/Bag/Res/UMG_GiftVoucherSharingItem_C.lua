local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_GiftVoucherSharingItem_C = Base:Extend("UMG_GiftVoucherSharingItem_C")

function UMG_GiftVoucherSharingItem_C:OnConstruct()
  self.friendData = nil
  self.index = 0
  self.isOnline = false
  self.lastOnlineTime = 0
  self.canShare = true
  self.shareCooldown = 0
  self.lastShareTime = 0
  self:AddButtonListener(self.UMG_Btn_Share.btnLevelUp, self.OnClickBtnShare)
end

function UMG_GiftVoucherSharingItem_C:OnDestruct()
end

function UMG_GiftVoucherSharingItem_C:OnItemUpdate(_data, datalist, index)
  self.isLogicSelected = false
  self.friendData = _data
  self.index = index
  self.isOnline = self.friendData.online or false
  self.lastOnlineTime = self.friendData.last_logout_time or 0
  self:FillComponentInfo()
  self:SetOnlineState()
  self:SetHeadPortrait()
  self:SetFriendNameAndLevel()
  self:CheckGiftableStatus()
  self:UpdateShareButtonState()
end

function UMG_GiftVoucherSharingItem_C:OnItemSelected(_bSelected)
  self.isLogicSelected = _bSelected
  if _bSelected then
    self:SetSelectedState(true)
  else
    self:SetSelectedState(false)
  end
  self:SetFriendNameAndLevel()
end

function UMG_GiftVoucherSharingItem_C:OnDeactive()
end

function UMG_GiftVoucherSharingItem_C:FillComponentInfo()
  if not self.friendData then
    return
  end
  if self.Text_FriendName then
    local friendName = self.friendData.name or self.friendData.nickname
    self.Text_FriendName:SetText(friendName)
    self.Text_FriendName:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.Text_Offlinetime then
    if not self.isOnline and self.lastOnlineTime >= 0 then
      local offlineTime = self:FormatOfflineTime(self.lastOnlineTime)
      self.Text_Offlinetime:SetText(offlineTime)
    else
      self.Text_Offlinetime:SetText("")
    end
    self.Text_Offlinetime:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_GiftVoucherSharingItem_C:SetOnlineState()
  if not self.friendData then
    return
  end
  if self.Switcher_OnlineState then
    if self.isOnline then
      self.Switcher_OnlineState:SetActiveWidgetIndex(0)
    else
      self.Switcher_OnlineState:SetActiveWidgetIndex(1)
    end
  end
end

function UMG_GiftVoucherSharingItem_C:SetHeadPortrait()
  if not self.friendData then
    return
  end
  local card_icon_selected = self.friendData.card_icon_selected
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  if card_icon_selected and 0 ~= card_icon_selected then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
      Log.Debug(AvatarPath, "UMG_GiftVoucherSharingItem_C:SetHeadPortrait")
      self.HeadPortrait:SetPath(AvatarPath)
    end
  else
  end
end

function UMG_GiftVoucherSharingItem_C:SetFriendNameAndLevel()
  if not self.friendData or not self.Text_FriendName then
    return
  end
  local friendName = ""
  if self.friendData.note and "" ~= self.friendData.note then
    friendName = self.friendData.note
  elseif self.friendData.name and "" ~= self.friendData.name then
    friendName = self.friendData.name
  else
    friendName = ""
  end
  if self.Text_UID then
    self.Text_UID:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Text_UID:SetText(self.friendData.uin)
  end
  Log.Info("UMG_GiftVoucherSharingItem_C nickname ", self.friendData.plat_nick_name)
  if self.Text_NickName then
    local nickName = self.friendData.plat_nick_name or ""
    if not string.IsNilOrEmpty(nickName) then
      local totalNum = _G.DataConfigManager:GetGlobalConfigNumByKey("share_nickname_limit_num", 7)
      local nickNameLength = utf8.len(nickName)
      if totalNum < nickNameLength then
        nickName = UIUtils.SubUTF8String(nickName, totalNum)
        nickName = nickName .. "..."
      end
      nickName = string.format("(%s)", nickName)
      self.Text_NickName:SetText(nickName)
      self.Text_NickName:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Text_NickName:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self.Text_FriendName:SetText(friendName)
  self.Grade:SetText(self.friendData.level or 0)
end

function UMG_GiftVoucherSharingItem_C:CheckGiftableStatus()
  if not self.friendData then
    self.canGift = false
    return
  end
  self.canGift = self.friendData.canGift or false
end

function UMG_GiftVoucherSharingItem_C:UpdateShareButtonState()
  if not self.UMG_Btn_Share then
    return
  end
  local shareButtonText = _G.DataConfigManager:GetLocalizationConf("bp_gift_share_button02").msg or ""
  self.UMG_Btn_Share.Title_1:SetText(shareButtonText)
  local cangift, text = self:GetGiftableState()
  self.NRCText_Describe:SetText(text)
  if cangift then
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
  end
end

function UMG_GiftVoucherSharingItem_C:SetSelectedState(isSelected)
end

function UMG_GiftVoucherSharingItem_C:FormatOfflineTime(lastOnlineTime)
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  local timeDiff = currentTime - lastOnlineTime
  if timeDiff < 60 then
    return LuaText.umg_friend_applyfor_item_5
  elseif timeDiff < 3600 then
    local minutes = math.floor(timeDiff / 60)
    return string.format(LuaText.umg_friend_applyfor_item_6, minutes)
  elseif timeDiff < 86400 then
    local hours = math.floor(timeDiff / 3600)
    return string.format(LuaText.umg_friend_applyfor_item_3, hours)
  else
    local days = math.floor(timeDiff / 86400)
    return string.format(LuaText.umg_friend_applyfor_item_2, days)
  end
end

function UMG_GiftVoucherSharingItem_C:OnClickBtnShare()
  local moduleName = "BagModule"
  local panelName = "UMG_GiftVoucherSharing"
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).CLOSE
  Log.Info("UMG_GiftVoucherSharing_C:OnClickBtnShare UnlockIsSelectBtn", touchReasonType)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, moduleName, panelName, touchReasonType)
  if not self.friendData then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_GiftVoucherSharingItem_C:OnClickBtnShare")
  if not self:ShowCannotGiftTip() then
    return
  end
  self.lastShareTime = _G.ZoneServer:GetServerTime() / 1000
  self.shareCooldown = 30
  self:UpdateShareButtonState()
  local bagModule = _G.NRCModuleManager:GetModule("BagModule")
  local giftVoucherData
  if bagModule then
    local bagModuleData = bagModule:GetData()
    if bagModuleData and bagModuleData.GetGiftVoucherData then
      giftVoucherData = bagModuleData:GetGiftVoucherData()
    end
  end
  if giftVoucherData and giftVoucherData.expireStatus.isExpired then
    local expireTip = LuaText.item_expired
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, expireTip)
    return
  end
  local moduleName = "BagModule"
  local panelName = "UMG_GiftVoucherSharing"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    Log.Info("UMG_GiftVoucherSharingItem_C:OnClickBtnShare isSelectBtn", moduleName, panelName)
    return
  end
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).SHARE)
  self.isCancelled = false
  local initData = _G.NRCCommonPopUpData()
  initData.Call = self
  initData.TitleText = _G.DataConfigManager:GetLocalizationConf("bp_share_confirm_title").msg
  initData.Btn_LeftText = LuaText.CANCEL
  initData.Btn_RightText = LuaText.umg_bag_11
  local Text = _G.DataConfigManager:GetLocalizationConf("bp_share_confirm_text").msg
  local friendName = self.friendData.name or self.friendData.nickname or ""
  if giftVoucherData and giftVoucherData.bagItemConf then
    initData.ContentText = string.format(Text, giftVoucherData.bagItemConf.name, friendName)
  else
    initData.ContentText = string.format(Text, "", friendName)
  end
  initData.Btn_RightHandler = self.SendGiftMessage
  initData.Btn_LeftHandler = self.CancelShare
  initData.Btn_CloseHandler = self.CancelShare
  initData.ClosePanelHandler = self.CancelShare
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, initData)
end

function UMG_GiftVoucherSharingItem_C:SendGiftMessage()
  if self.isCancelled then
    Log.Info("UMG_GiftVoucherSharingItem_C:SendGiftMessage already cancelled, ignore confirm")
    return
  end
  local moduleName = "BagModule"
  local panelName = "UMG_GiftVoucherSharing"
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).SHARE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, moduleName, panelName, touchReasonType)
  local bagModule = _G.NRCModuleManager:GetModule("BagModule")
  local giftVoucherData
  if bagModule then
    local bagModuleData = bagModule:GetData()
    if bagModuleData and bagModuleData.GetGiftVoucherData then
      giftVoucherData = bagModuleData:GetGiftVoucherData()
    end
  end
  if not giftVoucherData or not giftVoucherData.bagItemConf then
    Log.Warning("[BP] \231\164\188\229\147\129\229\136\184\230\149\176\230\141\174\231\188\186\229\164\177\239\188\140\230\151\160\230\179\149\229\143\145\233\128\129\232\181\160\233\128\129\232\175\183\230\177\130")
    return
  end
  local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
  local expireStatus = bagModule.data:CheckItemExpireStatus(giftVoucherData.bagItemConf, expireThreshold)
  if expireStatus.isExpired then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_expired)
    return
  end
  local req = ProtoMessage:newZoneGiftGivingReq()
  req.receiver_uin = self.friendData.uin
  req.goods_type = _G.ProtoEnum.GoodsType.GT_BAGITEM
  req.goods_id = giftVoucherData.bagItemConf.id
  req.goods_gid = giftVoucherData.gid
  req.goods_num = 1
  Log.Dump(req, 6, "UMG_GiftVoucherSharingItem_C:SendGiftMessage")
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GIFT_GIVING_REQ, req, self, self.OnZoneGiftGivingRsp)
end

function UMG_GiftVoucherSharingItem_C:OnZoneGiftGivingRsp(rsp)
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("bp_share_success").msg)
    _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.CloseGiftVoucherSharing)
  else
    Log.Warning("UMG_GiftVoucherSharingItem_C:OnZoneGiftGivingRsp", rsp.ret_info.ret_code)
    if rsp and rsp.ret_info and rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED then
      local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
      local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
      local uin = rsp.ban_info.uin
      local contenText = string.format(banConfig.str, uin, ban_time, rsp.ban_info.ban_reason)
      local dialogContext = DialogContext()
      dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      return
    end
  end
end

function UMG_GiftVoucherSharingItem_C:CancelShare()
  self.isCancelled = true
  local moduleName = "BagModule"
  local panelName = "UMG_GiftVoucherSharing"
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).SHARE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, moduleName, panelName, touchReasonType)
  Log.Info("UMG_GiftVoucherSharing_C:CancelShare UnlockIsSelectBtn", touchReasonType)
end

function UMG_GiftVoucherSharingItem_C:GetGiftableState()
  if not self.friendData or not self.friendData.uin then
    return false, LuaText.bp_function_unlock
  end
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  local friendTimeLimit = _G.DataConfigManager:GetGlobalConfig("bp_gift_friend_time_limit").num or 0
  local friendLevelLimit = _G.DataConfigManager:GetGlobalConfig("bp_gift_friend_level_limit").num or 0
  local friendAddTime = self.friendData.add_friend_time or 0
  if friendTimeLimit > currentTime - friendAddTime then
    local insufficientText = _G.DataConfigManager:GetLocalizationConf("bp_friendtime_insufficient").msg
    local hour = math.floor(friendTimeLimit / 3600) or 0
    return false, string.format(insufficientText, hour)
  end
  local friendLevel = self.friendData.level or 0
  if friendLevelLimit > friendLevel then
    local levelText = _G.DataConfigManager:GetLocalizationConf("bp_friendlevel_insufficient").msg
    return false, levelText
  end
  if self.friendData.is_chat_node_unlock ~= nil and not self.friendData.is_chat_node_unlock then
    local funcInvalid = _G.DataConfigManager:GetLocalizationConf("bp_friendfunction_invalid").msg
    return false, funcInvalid
  end
  return true, ""
end

function UMG_GiftVoucherSharingItem_C:ShowCannotGiftTip()
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  local friendTimeLimit = _G.DataConfigManager:GetGlobalConfig("bp_gift_friend_time_limit").num or 0
  local friendLevelLimit = _G.DataConfigManager:GetGlobalConfig("bp_gift_friend_level_limit").num or 0
  local tipText = ""
  local canGift = true
  if not self.friendData.uin then
    tipText = LuaText.bp_function_unlock
    return false
  elseif self.friendData.bp_gift_grade ~= _G.Enum.BattlePassGiftGrade.BPGG_FREE then
    tipText = _G.DataConfigManager:GetLocalizationConf("bp_function_unlock").msg
    canGift = false
  else
    local friendAddTime = self.friendData.add_friend_time or 0
    local friendDuration = currentTime - friendAddTime
    if friendTimeLimit > friendDuration then
      local insufficientText = _G.DataConfigManager:GetLocalizationConf("bp_friendtime_insufficient").msg
      local hour = math.floor(friendTimeLimit / 3600) or 0
      tipText = string.format(insufficientText, hour)
      canGift = false
    else
      local friendLevel = self.friendData.level or 0
      if friendLevelLimit > friendLevel then
        tipText = _G.DataConfigManager:GetLocalizationConf("bp_function_unlock").msg
        canGift = false
      end
    end
  end
  if not canGift then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipText)
  end
  return canGift
end

return UMG_GiftVoucherSharingItem_C

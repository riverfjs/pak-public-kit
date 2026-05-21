local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_Friend_Chitchat_Item_C = Base:Extend("UMG_Friend_Chitchat_Item_C")
local VISIT_CHAT_ROOM_ICON = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/img_yusanjia.img_yusanjia'"

function UMG_Friend_Chitchat_Item_C:OnConstruct()
  self.module = _G.NRCModuleManager:GetModule("FriendModule")
  self.moduleData = self.module:GetData("FriendModuleData")
end

function UMG_Friend_Chitchat_Item_C:OnDestruct()
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
end

function UMG_Friend_Chitchat_Item_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.SizeBox1:SetHeightOverride(100)
  self.SizeBox1:SetRenderOpacity(1)
  self.uiData = _data
  local isVisitChat = self.uiData.basic_info.uin == _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  self.Subtext:SetVisibility(isVisitChat and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  local headIcon = isVisitChat and VISIT_CHAT_ROOM_ICON or self:GetHeadIconById(self.uiData.friend_session_info.card_icon_selected)
  self.HeadPortrait:SetPath(headIcon)
  self:RefreshFriendName()
  self:SetRedPoint()
  self:SetSubText()
  self:SetOnlineState()
  if self.isShowSelectAnim then
    self:PlayAnimation(self.select_out)
  end
  self.isShowSelectAnim = false
end

function UMG_Friend_Chitchat_Item_C:OnItemSelected(_bSelected)
  if self.uiData == nil then
    Log.Warning("self.uiData is nil")
    return
  end
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.select_in)
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetCurChatUin, self.uiData.basic_info.uin)
    local multiPlayerUin = _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
    local friendModule = _G.NRCModuleManager:GetModule("FriendModule")
    if friendModule then
      if self.uiData.basic_info.uin == multiPlayerUin then
        friendModule:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.MultiChannelChatFlag, true)
      else
        friendModule:RequestShowOrHideTypingBubble(FriendEnum.TypingFlag.MultiChannelChatFlag, false)
      end
    end
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetChatMessageListByUin, self.uiData.basic_info.uin, 1, 10)
    self.delayID = _G.DelayManager:DelaySeconds(0.5, function()
      if self.ItemRedPoint then
        self.ItemRedPoint:EraseRedPoint(true)
      end
    end)
    self.ItemRedPoint:ActiveKey()
  else
    self.selected = false
    self.ItemRedPoint:DeactiveKey()
    self:PlayAnimation(self.select_out)
  end
end

function UMG_Friend_Chitchat_Item_C:OpItem(opType)
  if opType == FriendEnum.ChatItemRefreshType.FriendRemarkUpdate then
    self:RefreshFriendName()
  end
end

function UMG_Friend_Chitchat_Item_C:SetSubText()
  local type = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  if self.uiData.basic_info.uin ~= type and self.uiData.basic_info.uin ~= type then
    self.Subtext:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Subtext:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_Chitchat_Item_C:RefreshFriendName()
  local isVisitChat = self.uiData.uin == _G.NRCModeManager:DoCmd(_G.FriendModuleCmd.GetMultiPlayerChannelType)
  local showName = ""
  if isVisitChat then
    showName = _G.LuaText.online_team_chat_name
  elseif self.uiData and self.uiData.friend_session_info then
    local uin = self.uiData.basic_info and self.uiData.basic_info.uin or 0
    local showNote = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendNewRemarkByUin, uin)
    if string.IsNilOrEmpty(showNote) then
      showNote = self.uiData.friend_session_info.note or ""
    end
    if not string.IsNilOrEmpty(showNote) then
      showName = showNote
      self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#d87a35ff"))
    else
      showName = self.uiData.friend_session_info.name
      self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
    end
  else
    Log.Warning("UMG_Friend_Chitchat_Item_C:RefreshFriendName", "self.uiData is nil")
  end
  local NeedSub, text = self:GetTextInfo(showName)
  if NeedSub then
    self.Name:SetText(string.format("%s%s", text, "..."))
  else
    self.Name:SetText(showName)
  end
end

function UMG_Friend_Chitchat_Item_C:GetTextInfo(showName)
  local str = string.GetPrintTable(showName)
  local text = ""
  local text_1 = ""
  local NeedSub = false
  local Count = 0
  for i = 1, #str do
    local ByteCount = string.SubStringGetByteCount(str[i], 1)
    if ByteCount < 2 then
      Count = Count + 1
    else
      Count = Count + 2
    end
    if Count > 12 then
      NeedSub = true
      break
    else
      text = text .. str[i]
      if Count < 12 then
        text_1 = text_1 .. str[i]
      end
    end
  end
  if NeedSub then
    return NeedSub, text_1
  end
  return NeedSub, text
end

function UMG_Friend_Chitchat_Item_C:GetHeadIconById(Id)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Id = Id or player.gender
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  if Id > 0 then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(Id)
    local HeadIconPath = ""
    if CardIconConf then
      HeadIconPath = CardIconConf.icon_resource_path
      return string.format("%s%s.%s'", path, HeadIconPath, HeadIconPath)
    else
      return ""
    end
  else
    return ""
  end
end

function UMG_Friend_Chitchat_Item_C:RemoveCurItem()
  self:PlayAnimation(self.FadeOut)
end

function UMG_Friend_Chitchat_Item_C:SetRedPoint()
  self.ItemRedPoint:SetupKey(82, self.uiData.basic_info.uin)
end

function UMG_Friend_Chitchat_Item_C:UnshowRedPoint()
  self.ItemRedPoint:SetupKey(82, 0)
end

function UMG_Friend_Chitchat_Item_C:SetOnlineState()
  local FriendRoleInfo = self.uiData.friend_session_info
  if FriendRoleInfo then
    if FriendRoleInfo.online then
      self:PrepareOnlineData()
      self.Subtext:SetText(self.onlineTitle)
      self.Subtext:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("5CA011FF"))
    elseif FriendRoleInfo.last_logout_time then
      local LastLogoutTime = FriendRoleInfo.last_logout_time
      local nowTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
      local TimeDiff = nowTime - LastLogoutTime
      local min = math.floor(TimeDiff / 60)
      local hour = math.floor(min / 60)
      local day = math.floor(hour / 24)
      if day >= 7 then
        self.Subtext:SetText(LuaText.umg_friend_item_2)
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
        self.Subtext:SetText(Text)
      end
      self.Subtext:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("62605EFF"))
    end
  end
end

function UMG_Friend_Chitchat_Item_C:PrepareOnlineData()
  self.onlineTitle = ""
  local sessionInfo = self.uiData.friend_session_info
  if sessionInfo then
    self.onlineTitle = self.module:GetPlayerOnlineStatusText(sessionInfo.battle_brief_info, sessionInfo.pos_info)
  end
end

function UMG_Friend_Chitchat_Item_C:OnDeactive()
end

function UMG_Friend_Chitchat_Item_C:BroadcastOnClicked()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40006008, "UMG_Friend_Chitchat_Item_C:OnItemSelected")
end

function UMG_Friend_Chitchat_Item_C:OnAnimationFinished(anim)
  if anim == self.select_in then
    self.isShowSelectAnim = true
  elseif anim == self.select_out then
    self.isShowSelectAnim = false
  end
end

return UMG_Friend_Chitchat_Item_C

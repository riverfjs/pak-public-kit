local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ProtoEnum = require("Data.PB.ProtoEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UMG_Pass_SelectFriendItem_C = Base:Extend("UMG_Pass_SelectFriendItem_C")

function UMG_Pass_SelectFriendItem_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_SelectFriendItem_C", self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.OnModifyFriendRemarkUpdate)
end

function UMG_Pass_SelectFriendItem_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.OnModifyFriendRemarkUpdate)
  self.data = nil
end

function UMG_Pass_SelectFriendItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  if not self.data then
    Log.Error("UMG_Pass_SelectFriendItem_C:OnItemUpdate _data is nil")
    return
  end
  self:UpdatePlayerNameInfo()
  if self.grade then
    self.grade:SetText(tostring(self.data.level or 0))
  end
  self:UpdateOnlineState()
  self:UpdateBtns()
  self:SetHeadInfo()
  self:BindButtonEvents()
end

function UMG_Pass_SelectFriendItem_C:OnItemSelected(_bSelected)
end

function UMG_Pass_SelectFriendItem_C:OnDeactive()
  self.data = nil
end

function UMG_Pass_SelectFriendItem_C:OnModifyFriendRemarkUpdate(uin, newRemark)
  if not self.data then
    return
  end
  if self.data.uin == uin then
    self.data.note = newRemark
    self:UpdatePlayerNameInfo()
  end
end

function UMG_Pass_SelectFriendItem_C:UpdatePlayerNameInfo()
  if not self.data or not self.RemarkName then
    return
  end
  local name = self.data.name or ""
  local note = self.data.note or ""
  local platformName = self.data.plat_nick_name or ""
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
  local platformShowName = ""
  if platformName and "" ~= platformName then
    local totalNum = _G.DataConfigManager:GetGlobalConfigNumByKey("share_nickname_limit_num", 7)
    local nickNameLength = utf8.len(platformName) or 0
    if totalNum < nickNameLength then
      platformName = UIUtils.SubUTF8String(platformName, totalNum) .. "..."
    end
    platformShowName = string.format("(%s)", platformName)
  end
  local displayName = gameNameShow .. platformShowName
  self.RemarkName:SetText(displayName)
end

function UMG_Pass_SelectFriendItem_C:UpdateBtns()
  if not self.data then
    return
  end
  if self.data.is_chat_node_unlock then
    self.BtnChatting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.BtnChatting:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.data.online then
    self.BtntTransmission:ChangeIconSelectState(1)
    self.BtntTransmission:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.BtntTransmission:ChangeIconSelectState(2)
    self.BtntTransmission:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_Pass_SelectFriendItem_C:UpdateOnlineState()
  if not self.data then
    return
  end
  if self.data.online then
    self.State:SetActiveWidgetIndex(0)
    local onlineText = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendBehaviorText, self.data)
    if self.OnlineOrNot_Title then
      self.OnlineOrNot_Title:SetText(onlineText)
    end
  else
    self.State:SetActiveWidgetIndex(1)
    local lastLogoutTime = self.data.last_logout_time or 0
    local nowTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
    local timeDiff = nowTime - lastLogoutTime
    local min = math.floor(timeDiff / 60)
    local hour = math.floor(min / 60)
    local day = math.floor(hour / 24)
    local offlineText = ""
    if day >= 7 then
      offlineText = LuaText.umg_friend_item_2
    elseif day < 7 and hour >= 24 then
      offlineText = string.format(LuaText.umg_friend_item_3, day)
    elseif hour < 24 and hour > 0 then
      offlineText = string.format(LuaText.umg_friend_item_4, hour)
    elseif min < 60 and min >= 1 then
      offlineText = string.format(LuaText.umg_friend_applyfor_item_6, min)
    elseif min < 1 and min >= 0 then
      offlineText = LuaText.umg_friend_applyfor_item_5
    end
    if self.Offline then
      self.Offline:SetText(offlineText)
    end
  end
end

function UMG_Pass_SelectFriendItem_C:SetHeadInfo()
  if not self.data or not self.HeadPortrait then
    return
  end
  local cardIconSelected = self.data.card_icon_selected
  if cardIconSelected and 0 ~= cardIconSelected then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(cardIconSelected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BigHeadIcon256/", AvatarPath, AvatarPath)
      self.HeadPortrait:SetPath(AvatarPath)
    else
      Log.ErrorFormat("UMG_Pass_SelectFriendItem_C:SetHeadInfo no CardIconConf found for cardIconSelected: %s, uin: %s", tostring(cardIconSelected), tostring(self.data.uin))
    end
  else
    Log.ErrorFormat("UMG_Pass_SelectFriendItem_C:SetHeadInfo no cardIconSelected or cardIconSelected is 0, uin: %s", tostring(self.data.uin))
  end
end

function UMG_Pass_SelectFriendItem_C:BindButtonEvents()
  if self.BtntTransmission and self.BtntTransmission.btnLevelUp then
    self.BtntTransmission.btnLevelUp.OnClicked:Clear()
    self.BtntTransmission.btnLevelUp.OnClicked:Add(self, self.OnTeleportPlayer)
  end
  if self.BtnChatting and self.BtnChatting.btnLevelUp then
    self.BtnChatting.btnLevelUp.OnClicked:Clear()
    self.BtnChatting.btnLevelUp.OnClicked:Add(self, self.OnSendMessage)
  end
end

function UMG_Pass_SelectFriendItem_C:OnTeleportPlayer()
  if not self.data then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Pass_SelectFriendItem_C:OnTeleportPlayer")
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OnCmdTeleportToPlayerReq, self.data.uin)
end

function UMG_Pass_SelectFriendItem_C:OnSendMessage()
  if not self.data then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHAT, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Pass_SelectFriendItem_C:OnSendMessage")
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local myPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, myUin)
  local bInFighting = false
  if myPlayer then
    bInFighting = myPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanelByFriendPanel, self.data.uin, self.index, bInFighting)
end

return UMG_Pass_SelectFriendItem_C

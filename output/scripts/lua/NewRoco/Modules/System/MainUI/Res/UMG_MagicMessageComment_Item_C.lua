local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local UMG_MagicMessageComment_Item_C = Base:Extend("UMG_MagicMessageComment_Item_C")

function UMG_MagicMessageComment_Item_C:OnConstruct()
  self:OnAddEventListener()
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  self.showMessagePanel = mainUIModule:GetPanel("ShowMagicMessage")
  self.feedInfo = nil
  if self.showMessagePanel then
    self.feedInfo = self.showMessagePanel.feedInfo
    self.encryptCommentFlag = self.showMessagePanel.encryptCommentFlag
  end
end

function UMG_MagicMessageComment_Item_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.ClickMagicMessageCommentMoreEvent, self.UpdateMoreContent)
end

function UMG_MagicMessageComment_Item_C:OnAddEventListener()
  self.Button_Praise.OnClicked:Add(self, self.OnClickPraise)
  self.Btn_More.OnClicked:Add(self, self.OnClickMoreBtn)
  self.Btn_MoreContent.OnClicked:Add(self, self.OnClickMoreContentBtn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.ClickMagicMessageCommentMoreEvent, self.UpdateMoreContent)
end

function UMG_MagicMessageComment_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  local card_icon_selected = self.data.card_icon_selected
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  if card_icon_selected and 0 ~= card_icon_selected then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    local avatarPath = cardIconConf.icon_resource_path
    avatarPath = string.format("%s%s.%s'", path, avatarPath, avatarPath)
    self.Image_Head:SetPath(avatarPath)
  end
  self.Text_RoleName:SetText(self.data.name)
  local currentSec = _G.ZoneServer:GetServerTime() / 1000
  local timeSeconds = currentSec - self.data.create_timestamp
  self:SetTime(timeSeconds)
  if 1 == self.encryptCommentFlag then
    self.TextSwitcher:SetActiveWidgetIndex(1)
    self.RocoText_Content:SetText(self.data.comment)
  else
    self.TextSwitcher:SetActiveWidgetIndex(0)
    local content = self.data.comment
    if self.feedInfo and self.feedInfo.sub_type and 0 ~= self.feedInfo.sub_type then
      content = string.ConvertToRichText(self.data.comment)
    end
    self.Text_Content:SetText(content)
  end
  if self.data.good_num > 9999 then
    self.Text_PraiseNum:SetText("9999+")
  else
    self.Text_PraiseNum:SetText(self.data.good_num)
  end
  self.WidgetSwitcher_Praise:SetActiveWidgetIndex(self.data.comment_attitude == ProtoEnum.FeedCommentAttitudeType.FEED_COMMENT_ATTITUDE_TYPE_GOOD and 1 or 0)
  self.Btn_MoreContent:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MagicMessageComment_Item_C:SetTime(timeSeconds)
  if timeSeconds > 0 then
    local day = timeSeconds // 86400
    local hour = (timeSeconds - 86400 * day) // 3600
    local minute = (timeSeconds - 86400 * day - 3600 * hour) // 60
    if day > 0 then
      self.Text_Time:SetText(string.format(_G.LuaText.magic_message_comment_time_tips_4, day))
    elseif hour > 0 then
      self.Text_Time:SetText(string.format(_G.LuaText.magic_message_comment_time_tips_3, hour))
    elseif minute > 0 then
      self.Text_Time:SetText(string.format(_G.LuaText.magic_message_comment_time_tips_2, minute))
    else
      self.Text_Time:SetText(string.format(_G.LuaText.magic_message_comment_time_tips_1))
    end
  end
end

function UMG_MagicMessageComment_Item_C:OnClickPraise()
  local reqMsg = _G.ProtoMessage:newZoneFeedCommentAttitudeReq()
  reqMsg.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  reqMsg.feed_id = self.feedInfo.feed_id
  reqMsg.feedback_id = self.data.feedback_id
  reqMsg.attitude = ProtoEnum.FeedCommentAttitudeType.FEED_COMMENT_ATTITUDE_TYPE_GOOD
  reqMsg.category = self.feedInfo.category
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_COMMENT_ATTITUDE_REQ, reqMsg, self, self.OnFeedCommentAttitudeRsp, nil, false)
end

function UMG_MagicMessageComment_Item_C:OnFeedCommentAttitudeRsp(rsp)
  if rsp.ret_info.ret_code == 18306 then
    if self.showMessagePanel then
      self.showMessagePanel:DeleteCurFeed()
    end
    return
  end
  if 0 == rsp.ret_info.ret_code then
    self.WidgetSwitcher_Praise:SetActiveWidgetIndex(rsp.comment_info.comment_attitude == ProtoEnum.FeedCommentAttitudeType.FEED_COMMENT_ATTITUDE_TYPE_GOOD and 1 or 0)
    self.UMG_Upvote:PlayAnimation(self.UMG_Upvote.Like)
    if rsp.comment_info.good_num > 9999 then
      self.Text_PraiseNum:SetText("9999+")
    else
      self.Text_PraiseNum:SetText(rsp.comment_info.good_num)
    end
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.UpdateMagicMessageCommentInfoEvent, rsp.comment_info)
  end
end

function UMG_MagicMessageComment_Item_C:OnClickHeadBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_MagicMessageComment_Item_C:OnClickHeadBtn")
  local curPlayerUni = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if curPlayerUni == self.data.uin then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, nil, FriendEnum.AdminFriendType.Own, FriendEnum.Source.Friend, nil)
  else
    local friendData = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendByUin, self.data.uin)
    if friendData then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, friendData, FriendEnum.AdminFriendType.Others, FriendEnum.Source.Friend, nil)
    else
      local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
      req.uin = self.data.uin
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnSearchPlayerRsp, false, true)
    end
  end
end

function UMG_MagicMessageComment_Item_C:OnSearchPlayerRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    local source = rsp.is_friend and FriendEnum.Source.Friend or FriendEnum.Source.Scene
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, rsp.player_info, FriendEnum.AdminFriendType.Others, source, nil)
  end
end

function UMG_MagicMessageComment_Item_C:OnClickMoreBtn()
  if self.data then
    if self.Btn_MoreContent:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.ClickMagicMessageCommentMoreEvent, self.data.feedback_id)
    elseif self.Btn_MoreContent:GetVisibility() == UE4.ESlateVisibility.Visible then
      _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.ClickMagicMessageCommentMoreEvent, 0)
    end
  end
end

function UMG_MagicMessageComment_Item_C:UpdateMoreContent(feedback_id)
  if self.data then
    if 0 == feedback_id then
      self.Btn_MoreContent:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.data.feedback_id ~= feedback_id then
      self.Btn_MoreContent:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Btn_MoreContent:SetVisibility(UE4.ESlateVisibility.Visible)
      local curPlayerUni = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      if curPlayerUni == self.data.uin then
        self.Text_More:SetText(LuaText.magic_message_comment_delete)
      else
        self.Text_More:SetText(LuaText.magic_message_comment_report)
      end
    end
  end
end

function UMG_MagicMessageComment_Item_C:OnClickMoreContentBtn()
  self.Btn_MoreContent:SetVisibility(UE4.ESlateVisibility.Collapsed)
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.ClickMagicMessageCommentMoreContentEvent, self.data)
end

function UMG_MagicMessageComment_Item_C:OnDeactive()
end

return UMG_MagicMessageComment_Item_C

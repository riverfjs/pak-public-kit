local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local EditComponentItemData = reload("NewRoco.Modules.System.Friend.EditComponentItemData")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local FriendModuleData = _G.NRCData:Extend("FriendModuleData")

function FriendModuleData:Ctor()
  self.SearchInfo = nil
  self.SearchText = nil
  self.is_friend = nil
  self.ApplyForOrBlackListType = nil
  self.FriendSelectEntranceType = nil
  self.ClickHeadInfo = nil
  self.curSelectedItemData = nil
  self.SelectFriendTabIndex = 0
  self.EditSelectedPetTypeId = 0
  self.scrollOffset = 0
  self.StudentCardList = nil
  NRCData.Ctor(self)
  self.friendRoleList = {}
  self.wegameFriendList = {}
  self.clientWeGameFriendList = {}
  self.friendRemarkData = {}
  self.friendRequestList = {}
  self.blackList = {}
  self.blackTimestamp = {}
  self.StrangeFriendList = {}
  self.qqInviteTypeToArkJsonDic = {}
  self.friendRoleWaitData = false
  self.friendRequestWaitData = false
  self.blackListWaitData = false
  self.isPanelMoveCamera = false
  self.IsMove = false
  self.friendRoleCaller = nil
  self.friendRoleCallback = nil
  self.friendRequestCaller = nil
  self.friendRequestCallback = nil
  self.blackListCaller = nil
  self.blackListCallback = nil
  self.AddOrRemoveFriendIndex = nil
  self.RemoveFriendIndex = nil
  self.IsFriendBatchDeleteMode = false
  self.FriendBatchDeleteUinList = {}
  self.recommendRefreshCount = 0
  self.lastMsTimeRecommendRefresh = 0
  self.recommendFilterSources = {}
  self.friendTypeToLastAutoRefreshTimeDic = {}
  self.friendTypeToRefreshIntervalSecDic = {}
  self.friendTypeToLastChangeTabRefreshTimeDic = {}
  self.friendRoleExtInfoDic = {}
  self.friendRecommendSourceToConfDic = {}
  self.ApplyVisitNotifyList = {}
  self.VisitName = ""
  self.VisitUin = -1
  self.VisitWorldLevel = -1
  self.VisitSwitchScreen = false
  self.VisitConfirmName = ""
  self.VisitList = {}
  self.VisitorIndexMap = {}
  self.OwnerName = nil
  self.VisitListChangeInfo = {}
  self.VisitItem = nil
  self.VisitTimeLeft = {}
  self.icon_owned = {}
  self.skin_owned = {}
  self.editSelectedCardSkinId = nil
  self.label_owned = {}
  self.Pose_owned = {}
  self.Suit_owned = {}
  self.DefaultSkinId = nil
  self.DefaultPoseId = 14
  self.SelectTab = nil
  self.OldSelectTab = nil
  self.CardFriendInfo = nil
  self.CardAdminFriendType = nil
  self.CardSource = nil
  self.CardSelectTab = nil
  self.PlayerCardBriefInfo = nil
  self.PlayerCardBriefInfoUin = 0
  self.FavoritePet = nil
  self.CardFavoritePet = nil
  self.SelectFriendIndex = nil
  self.ChangeCardIndex = nil
  self.curEditCardsDic = {}
  self.curEditCardsDic[_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET] = {}
  self.curEditCardsDic[_G.ProtoEnum.RoleCardModuleType.RCMT_BADGE] = {}
  self.isEditingComponent = false
  self.CardComponentTypeToIdDic = {}
  self.PetTypeFilterList = {}
  self.curEditPetTypeIdList = {}
  self.PlayerCardAppearanceInfo = {}
  self.studentCardForbidEdit = false
  self.MultiPlayerChannelType = _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM
  self.ChatMultiPlayerChannelInfo = {
    basic_info = {
      uin = self.MultiPlayerChannelType
    },
    friend_session_info = {
      name = LuaText.chat_multi_message_name,
      note = nil,
      online = true
    },
    head_img = nil,
    time_stamp = nil,
    card_icon_selected = nil
  }
  self.ChatChatMultiPlayerMessageList = {}
  self.ChatSessionList = {}
  table.insert(self.ChatSessionList, self.ChatMultiPlayerChannelInfo)
  self.ChatMessageList = {}
  self.LocalChatMessageList = {}
  self.ChatAllMsgFetchedMap = {}
  self.ChatFirstRoleUin = 0
  self.EmojiEscToIdMap = nil
  self:BuildEmojiEscToIdMap()
  self.CurChatUin = 0
  self.LatestChatSession = {Uin = 0, time_stamp = 0}
  self.IsOpenQuickChatBubble = false
  self.FirstChatRoleListItem = nil
  self.TemporaryInput = ""
  self.QuickChatTemporaryInput = ""
  self.Entrance = nil
  self.bCloseLobbyMain = false
  self.TypingFlag = 0
  self:InitCardComponent()
  self:initializeCardSkin()
  self:initializeCardIcon()
  self:initializeCardLabel()
  self:initializeCardPose()
  self:_BuildFriendRecommendSourceConfCache()
  self.settings = nil
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_FRIEND_LIST_RSP, self.OnGetFriendRoleList)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_BLACK_LIST_RSP, self.OnGetBlackList)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_ADD_FRIEND_LIST_RSP, self.OnGetFriendRequestList)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_EMODATA, self.BuildEmojiEscToIdMap)
  _G.NRCEventCenter:RegisterEvent("FriendModuleData", self, NRCSDKManagerEvent.OnWeGameFriendInfoUpdate, self.OnWeGameFriendListRefresh)
  _G.NRCEventCenter:RegisterEvent("FriendModuleData", self, NRCSDKManagerEvent.OnWeGameFriendStateUpdate, self.OnWeGameOnlineStateRefresh)
  local minRefreshCfg = _G.DataConfigManager:GetGlobalConfig("friendlist_auto_refresh_cd")
  self.minFriendListAutoRefreshIntervalSec = math.max(minRefreshCfg and minRefreshCfg.num or 10, 10)
end

function FriendModuleData:OnWeGameOnlineStateRefresh(friendsOnlineInfo)
  if friendsOnlineInfo and table.len(friendsOnlineInfo) > 0 then
    for i = 1, table.len(friendsOnlineInfo) do
      for j = 1, table.len(self.wegameFriendList) do
        if self.wegameFriendList[j].openID == friendsOnlineInfo[i].OpenID then
          self.wegameFriendList[j].onlineState = friendsOnlineInfo[i].State
        end
      end
    end
  end
  self:SortWeGameFriendList()
  self:DispatchEvent(FriendModuleEvent.OnWeGameFriendInfoRefresh)
end

function FriendModuleData:OnWeGameFriendListRefresh(friendsInfo)
  local openIds = {}
  if friendsInfo and table.len(friendsInfo) > 0 then
    for i = 1, table.len(friendsInfo) do
      if not string.IsNilOrEmpty(friendsInfo[i].openID) then
        if not self.clientWeGameFriendList then
          self.clientWeGameFriendList = {}
        end
        local onlyRefresh = false
        for _, existFriendInfo in ipairs(self.clientWeGameFriendList) do
          if existFriendInfo.openID == friendsInfo[i].openID then
            existFriendInfo.onlineState = friendsInfo[i].onlineState
            existFriendInfo.nickName = friendsInfo[i].nickName
            existFriendInfo.avatarUrl = friendsInfo[i].avatarUrl
            existFriendInfo.platformOpenID = friendsInfo[i].platformOpenID
            onlyRefresh = true
          end
        end
        if not onlyRefresh then
          table.insert(self.clientWeGameFriendList, friendsInfo[i])
        end
        table.insert(openIds, friendsInfo[i].openID)
      end
    end
  end
  if self.module:HasPanel("Friend") then
    if openIds and table.len(openIds) > 0 then
      local req = ProtoMessage:newZoneFriendBatchSearchPlayerReq()
      req.openid_list = openIds
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_BATCH_SEARCH_PLAYER_REQ, req, self, self.OnWeGameFriendStateUpdate, false, true)
    else
      Log.Error("OnWeGameFriendListRefresh empty openIds")
    end
  end
  local openIdList = {}
  for _, friendInfo in ipairs(self.clientWeGameFriendList) do
    table.insert(openIdList, friendInfo.openID)
  end
  _G.NRCSDKManager:GetWeGameFriendsOnlineInfo(openIdList, "")
end

function FriendModuleData:OnWeGameFriendStateUpdate(rsp)
  Log.Dump(rsp, 3, "OnWeGameFriendStateUpdate")
  if 0 == rsp.ret_info.ret_code then
    local roleList = rsp.role_list
    if roleList then
      for _, role in ipairs(roleList) do
        if 0 == role.search_ret then
          if self.clientWeGameFriendList then
            local found = false
            for _, existingRole in ipairs(self.clientWeGameFriendList) do
              if existingRole.openID == role.openid and role.player_info then
                if role.is_black_role then
                  table.removeValue(self.clientWeGameFriendList, existingRole)
                  break
                end
                for k, v in pairs(role.player_info) do
                  if nil ~= v then
                    existingRole[k] = v
                  end
                end
                found = true
                break
              end
            end
            if not found then
              Log.Error("ZoneFriendBatchSearchPlayerRsp wrong info with " .. role.openid)
            end
          end
        elseif self.clientWeGameFriendList then
          for _, existingRole in ipairs(self.clientWeGameFriendList) do
            if existingRole.openID == role.openid then
              table.removeValue(self.clientWeGameFriendList, existingRole)
              break
            end
          end
        end
      end
    end
    self.wegameFriendList = self.clientWeGameFriendList
    self:SortWeGameFriendList()
    self:DispatchEvent(FriendModuleEvent.OnWeGameFriendInfoRefresh)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_FRIEND_USE_CLIENT_CACHE then
    self:SortWeGameFriendList()
    self:DispatchEvent(FriendModuleEvent.OnWeGameFriendInfoRefresh)
  else
    Log.Error("ZoneFriendBatchSearchPlayerRsp failed with ret_code " .. rsp.ret_info.ret_code)
  end
end

function FriendModuleData:UpdateInfo()
  self.SearchInfo = nil
  self.is_friend = nil
  self.IsSearchSucceed = false
end

function FriendModuleData:AddApplyVisitNotifyToList(ApplyVisitNotify)
  local Notify = ApplyVisitNotify
  Log.Error("\228\186\146\232\174\191AddApplyVisitNotifyToList")
  table.insert(self.ApplyVisitNotifyList, 1, Notify)
end

function FriendModuleData:ClearApplyVisitNotifyToList()
  table.clear(self.ApplyVisitNotifyList)
end

function FriendModuleData:GetApplyVisitNotifyList()
  return self.ApplyVisitNotifyList
end

function FriendModuleData:RemoveApplyVisitNotifyToList()
  table.remove(self.ApplyVisitNotifyList, 1)
end

function FriendModuleData:RemoveApplyVisitNotifyToListByUin(uin)
  if self.ApplyVisitNotifyList and #self.ApplyVisitNotifyList > 0 then
    for i = 1, #self.ApplyVisitNotifyList do
      if self.ApplyVisitNotifyList[i].uin == uin then
        table.remove(self.ApplyVisitNotifyList, i)
        break
      end
    end
  end
end

function FriendModuleData:SetOnlineVisitorList(List)
  self.VisitList = List
  self.VisitorIndexMap = {}
  if List then
    for index, visitor in ipairs(List) do
      self.VisitorIndexMap[visitor.uin] = index
    end
  end
end

function FriendModuleData:GetOnlineVisitorList()
  return self.VisitList
end

function FriendModuleData:SetVisitListChangeInfo(ListInfo)
  self.VisitListChangeInfo = ListInfo
end

function FriendModuleData:GetVisitListChangeInfo()
  return self.VisitListChangeInfo
end

function FriendModuleData:SetVisitOwnerName(OwnerName)
  self.OwnerName = OwnerName
end

function FriendModuleData:GetVisitOwnerName()
  return self.OwnerName
end

function FriendModuleData:GetVisitIndex(uin)
  return self.VisitorIndexMap[uin]
end

function FriendModuleData:GetQQArkJsonByInviteType(inviteType)
  if self.qqInviteTypeToArkJsonDic and self.qqInviteTypeToArkJsonDic[inviteType] then
    return self.qqInviteTypeToArkJsonDic[inviteType] or ""
  end
  return ""
end

function FriendModuleData:SetQQArkJsonByInviteType(inviteType, arkJson)
  if not self.qqInviteTypeToArkJsonDic then
    self.qqInviteTypeToArkJsonDic = {}
  end
  self.qqInviteTypeToArkJsonDic[inviteType] = arkJson
end

function FriendModuleData:ClearQQArkJsonCache()
  self.qqInviteTypeToArkJsonDic = {}
end

function FriendModuleData:GetFriendList()
  return self.friendRoleList
end

function FriendModuleData:GetWeGameFriendList()
  for _, wegameFriend in pairs(self.wegameFriendList) do
    if string.IsNilOrEmpty(wegameFriend.uin) then
      table.removeValue(self.wegameFriendList, wegameFriend)
    end
  end
  return self.wegameFriendList
end

function FriendModuleData:GetFriendListForSpecifiedType(friendType)
  local gameFriendList = {}
  if not friendType or friendType == ProtoEnum.FriendType.FRIEND_TYPE_NONE then
    Log.ErrorFormat("FriendModuleData:GetFriendListForSpecifiedType invalid friendType = %s", tostring(friendType))
    return {}
  end
  for i, friend in ipairs(self.friendRoleList) do
    if friend.friend_type == friendType or friend.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_ALL or friend.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_NONE then
      table.insert(gameFriendList, friend)
    end
  end
  Log.InfoFormat("FriendModuleData:GetFriendListForSpecifiedType friendType = %s, count = %d", tostring(friendType), #gameFriendList)
  return gameFriendList
end

function FriendModuleData:ClearHomeInfoReqMsTimeCache()
  self.homeInfoReqUinToReqMsTimeDicForFriendPanel = {}
end

function FriendModuleData:TryGetHomeInfoReqMsTimeForFriendPanel(uin)
  if self.homeInfoReqUinToReqMsTimeDicForFriendPanel and self.homeInfoReqUinToReqMsTimeDicForFriendPanel[uin] then
    local reqMsTime = self.homeInfoReqUinToReqMsTimeDicForFriendPanel[uin]
    return true, reqMsTime
  end
  return false, 0
end

function FriendModuleData:SetHomeInfoReqMsTimeForFriendPanel(uin, timeMs)
  if not self.homeInfoReqUinToReqMsTimeDicForFriendPanel then
    self.homeInfoReqUinToReqMsTimeDicForFriendPanel = {}
  end
  if uin then
    self.homeInfoReqUinToReqMsTimeDicForFriendPanel[uin] = timeMs
  end
end

function FriendModuleData:GetHomeInfoLastReqIndexForFriendPanel()
  return self.homeInfoLastReqIndexForFriendPanel or 0
end

function FriendModuleData:SetHomeInfoLastReqIndexForFriendPanel(index)
  self.homeInfoLastReqIndexForFriendPanel = index
end

function FriendModuleData:GetHomeInfoReqTimeForFriendPanel()
  return self.homeInfoReqTimeForFriendPanel or 0
end

function FriendModuleData:SetHomeInfoReqTimeForFriendPanel(time)
  self.homeInfoReqTimeForFriendPanel = time
end

function FriendModuleData:GetThresholdTimeoutMsForReqHomeInfo()
  return 1000
end

function FriendModuleData:GetHomeInfoMaxReqNumForFriendPanel()
  return 10
end

function FriendModuleData:IsWaitingFriendRoleData()
  return self.friendRoleWaitData
end

local function CompareFriendRoleData(a, b)
  if a.pinned_time ~= b.pinned_time then
    return a.pinned_time > b.pinned_time
  end
  if a.online ~= b.online then
    return a.online
  end
  if a.unlocked_rel_node_num and b.unlocked_rel_node_num and a.unlocked_rel_node_num ~= b.unlocked_rel_node_num then
    return a.unlocked_rel_node_num > b.unlocked_rel_node_num
  end
  if a.level ~= b.level then
    return a.level > b.level
  end
  return a.uin > b.uin
end

local function CompareFriendApplyData(a, b)
  if a.req_time ~= b.req_time then
    return a.req_time > b.req_time
  end
  return a.uin > b.uin
end

local function CompareBlackListData(a, b)
  if a.block_time ~= b.block_time then
    return a.block_time > b.block_time
  end
  return a.uin > b.uin
end

local function CompareWeGameFriendData(a, b)
  local priorityA = 0
  local priorityB = 0
  if a.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateInGame then
    priorityA = 1
  elseif a.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateOnline then
    priorityA = 2
  elseif a.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateBusy then
    priorityA = 3
  elseif a.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateLeave then
    priorityA = 4
  else
    priorityA = 5
  end
  if b.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateInGame then
    priorityB = 1
  elseif b.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateOnline then
    priorityB = 2
  elseif b.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateBusy then
    priorityB = 3
  elseif b.onlineState == UE.WeGameFriendOnlineState.kRailThirdPartyFriendsOnlineStateLeave then
    priorityB = 4
  else
    priorityB = 5
  end
  if a.online ~= b.online then
    return a.online
  end
  if priorityA ~= priorityB then
    return priorityA < priorityB
  end
  return a.uin > b.uin
end

function FriendModuleData:SortFriendRoleList()
  table.sort(self.friendRoleList, CompareFriendRoleData)
end

function FriendModuleData:SortFriendRequestList()
  table.sort(self.friendRequestList, CompareFriendApplyData)
end

function FriendModuleData:SortBlackList()
  table.sort(self.blackList, CompareBlackListData)
end

function FriendModuleData:SortWeGameFriendList()
  local friendList = self:GetWeGameFriendList()
  if table.isEmpty(friendList) then
    table.sort(self.clientWeGameFriendList, CompareWeGameFriendData)
  else
    table.sort(friendList, CompareWeGameFriendData)
  end
end

function FriendModuleData:AddFriendList(_change_friend_role)
  local briefFriendInfo = {
    uin = _change_friend_role.uin,
    note = _change_friend_role.note,
    pinned_time = _change_friend_role.pinned_time,
    friend_type = _change_friend_role.friend_type or ProtoEnum.FriendType.FRIEND_TYPE_NONE,
    plat_nick_name = _change_friend_role.plat_nick_name or ""
  }
  _G.DataModelMgr.PlayerDataModel:AddOrRemoveBriefFriend(true, _change_friend_role.uin, briefFriendInfo)
  if not self:IsHasFriend(self.friendRoleList, _change_friend_role.openid) then
    for i, role in ipairs(self.friendRoleList) do
      if false == CompareFriendRoleData(role, _change_friend_role) then
        self:AddServerFriendToDefaultFriendList(_change_friend_role, i)
        return i
      end
    end
    self:AddServerFriendToDefaultFriendList(_change_friend_role)
  else
    self:ReplaceServerFriendToDefaultFriendList(_change_friend_role)
  end
  return #self.friendRoleList - 1
end

function FriendModuleData:RemoveFriendListByUin(_Uin, change_friend_role)
  local realRemove
  if change_friend_role then
    if change_friend_role.friend_type == ProtoEnum.FriendType.FRIEND_TYPE_PLAT and change_friend_role.uin then
      realRemove = false
    else
      realRemove = true
    end
  else
    realRemove = true
  end
  if realRemove then
    _G.DataModelMgr.PlayerDataModel:AddOrRemoveBriefFriend(false, _Uin)
    self:ClearFriendNewRemarkByUin(_Uin)
    for i = #self.friendRoleList, 1, -1 do
      if _Uin == self.friendRoleList[i].uin then
        self.RemoveFriendIndex = i
        table.remove(self.friendRoleList, i)
        return i
      end
    end
  else
    local briefFriendInfo = {
      uin = change_friend_role.uin,
      note = change_friend_role.note,
      pinned_time = change_friend_role.pinned_time,
      friend_type = change_friend_role.friend_type,
      plat_nick_name = change_friend_role.plat_nick_name
    }
    _G.DataModelMgr.PlayerDataModel:AddOrRemoveBriefFriend(true, change_friend_role.uin, briefFriendInfo)
    self:ReplaceServerFriendToDefaultFriendList(change_friend_role)
  end
end

function FriendModuleData:SetFriendApplyForList()
  self.ApplyForOrBlackListType = FriendEnum.SELECT_TAB.FriendApply
end

function FriendModuleData:GetFriendApplyForList()
  return self.friendRequestList
end

function FriendModuleData:AddFriendApplyForList(new_req_friend)
  if not self:IsHasFriend(self.friendRequestList, new_req_friend.openid) then
    table.insert(self.friendRequestList, 1, new_req_friend)
    self.module:DispatchEvent(FriendModuleEvent.OnFriendApplyListUpdate)
  end
end

function FriendModuleData:IsHasFriend(_List, openid)
  local List = _List
  if List and #List > 0 then
    for i, Friend in ipairs(List) do
      if Friend.openid == openid then
        return true
      end
    end
  end
  return false
end

function FriendModuleData:RemoveRecommendFriendByUin(uin)
  for i = #self.StrangeFriendList, 1, -1 do
    if self.StrangeFriendList[i].uin == uin then
      table.remove(self.StrangeFriendList, i)
      break
    end
  end
end

function FriendModuleData:RemoveFriendApplyForListByUin(uin)
  local friendRequestList = self.friendRequestList
  for i = 1, #friendRequestList do
    if friendRequestList[i].uin == uin then
      table.remove(friendRequestList, i)
      break
    end
  end
end

function FriendModuleData:SetFriendBlackList(_FriendBlackList)
  self.ApplyForOrBlackListType = FriendEnum.SELECT_TAB.BlackList
end

function FriendModuleData:GetFriendBlackList()
  return self.blackList
end

function FriendModuleData:GetBlackTimestamp(_uin)
  return self.blackTimestamp[_uin]
end

function FriendModuleData:GetLoginChannelType()
  local onlineModuleData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if onlineModuleData then
    return onlineModuleData.loginChannelType
  else
    return Enum.CliLoginChannel.CLC_NONE
  end
end

function FriendModuleData:AddFriendBlackList(_changed_black_info)
  if not self:IsHasFriend(self.blackList, _changed_black_info.openid) then
    table.insert(self.blackList, 1, _changed_black_info)
  end
  if _changed_black_info.uin and _changed_black_info.block_time then
    self.blackTimestamp[_changed_black_info.uin] = _changed_black_info.block_time * 1000
  end
end

function FriendModuleData:RemoveFriendBlackList(_uin)
  for i = #self.blackList, 1, -1 do
    if _uin == self.blackList[i].uin then
      table.remove(self.blackList, i)
      break
    end
  end
  if _uin then
    self.blackTimestamp[_uin] = nil
  end
end

function FriendModuleData:SetFriendRemark(_Uin, _Note)
  for i, friendRole in ipairs(self.friendRoleList) do
    if _Uin == friendRole.uin then
      friendRole.note = _Note
      break
    end
  end
  if _Uin and _Note then
    self.friendRemarkData[_Uin] = _Note
  end
end

function FriendModuleData:UpdateFriendTopInfo(_Uin, _pinned_time)
  for i, friendRole in ipairs(self.friendRoleList) do
    if _Uin == friendRole.uin then
      friendRole.pinned_time = _pinned_time
      break
    end
  end
end

function FriendModuleData:SetIsFriend(_is_friend, _Uin)
  if _is_friend and tostring(_Uin) == self.SearchText then
    self.is_friend = _is_friend
  else
    self.is_friend = _is_friend
  end
end

function FriendModuleData:GetIsFriend()
  return self.is_friend
end

function FriendModuleData:SetSearchInfo(_SearchInfo)
  self.SearchInfo = _SearchInfo
end

function FriendModuleData:GetSearchInfo()
  return self.SearchInfo
end

function FriendModuleData:SetSearchText(SearchText)
  self.SearchText = SearchText
end

function FriendModuleData:GetSearchText()
  return self.SearchText
end

function FriendModuleData:SetApplyForOrBlackListType(_ApplyForOrBlackListType)
  self.ApplyForOrBlackListType = _ApplyForOrBlackListType
end

function FriendModuleData:GetApplyForOrBlackListType()
  return self.ApplyForOrBlackListType
end

function FriendModuleData:SetFriendSelectEntranceType(_FriendSelectEntranceType)
  self.FriendSelectEntranceType = _FriendSelectEntranceType
end

function FriendModuleData:GetFriendSelectEntranceType()
  return self.FriendSelectEntranceType
end

function FriendModuleData:SetStudentCardOptionList()
  return FriendEnum.SELECT_TAB.StudentCardList
end

function FriendModuleData:SetIsSearchSucceed(_IsSearchSucceed)
  self.IsSearchSucceed = _IsSearchSucceed
end

function FriendModuleData:GetIsSearchSucceed()
  return self.IsSearchSucceed
end

function FriendModuleData:SetStrangeFriendList(_StrangeFriendList)
  if nil == _StrangeFriendList then
    self.StrangeFriendList = {}
  else
    self.StrangeFriendList = _StrangeFriendList
  end
end

function FriendModuleData:GetStrangeFriendList()
  return self.StrangeFriendList
end

function FriendModuleData:GetStrangeFriendInfo(_uin)
  if self.StrangeFriendList then
    for i, friendRole in ipairs(self.StrangeFriendList) do
      if friendRole.uin == _uin then
        return friendRole
      end
    end
  end
  return nil
end

function FriendModuleData:GetFriendByUin(_Uin, clientFriendScene)
  local friendList
  if not clientFriendScene or clientFriendScene == FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault then
    friendList = self.friendRoleList
  else
    friendList = self:GetOtherSceneFriendList(clientFriendScene)
  end
  for i, friendRole in ipairs(self.friendRoleList) do
    if _Uin == friendRole.uin then
      return friendRole, i
    end
  end
  return nil
end

function FriendModuleData:GetFriendNewRemarkByUin(_Uin)
  return self.friendRemarkData[_Uin]
end

function FriendModuleData:ClearFriendNewRemarkByUin(_Uin)
  self.friendRemarkData[_Uin] = nil
end

function FriendModuleData:SetAddOrRemoveFriendIndex(_Uin, Type)
end

function FriendModuleData:GetRemoveFriendIndex()
  return self.RemoveFriendIndex
end

function FriendModuleData:SetRemoveFriendIndex(_RemoveFriendIndex)
  self.RemoveFriendIndex = _RemoveFriendIndex
end

function FriendModuleData:GetMinFriendListAutoRefreshIntervalSec()
  return self.minFriendListAutoRefreshIntervalSec
end

function FriendModuleData:RequestFriendRoleInfo(caller, callback, clientReqScene, uinList, friendType, getFriendListScene, isMergeData, furnitureId)
  self.friendRoleCaller = caller
  self.friendRoleCallback = callback
  local req = _G.ProtoMessage:newZoneFriendGetFriendListReq()
  if uinList then
    req.uin_list = uinList
    req.count = #uinList
  else
    req.count = 0
  end
  req.friend_type = friendType or _G.ProtoEnum.FriendType.FRIEND_TYPE_ALL
  req.scene = getFriendListScene or _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_DEFAULT
  if clientReqScene then
    req.client_data1 = clientReqScene
  else
    req.client_data1 = FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault
  end
  if isMergeData then
    req.client_data2 = 1
  else
    req.client_data2 = 0
  end
  if furnitureId then
    req.furniture_id = furnitureId
  end
  self.friendRoleWaitData = true
  Log.Dump(req, 3, "FriendModuleData:RequestFriendRoleInfo req")
  if req.scene == _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_UIN_LIST then
    if not uinList or 0 == #uinList then
      Log.Error("FriendModuleData:RequestFriendRoleInfo invalid uinList for ZONE_FRIEND_GET_FRIEND_LIST_SCENE_UIN_LIST")
      return
    end
  elseif req.scene == _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_FURNITURE_ID and not req.furniture_id then
    Log.Error("FriendModuleData:RequestFriendRoleInfo invalid furnitureId for ZONE_FRIEND_GET_FRIEND_LIST_SCENE_FURNITURE_ID")
    return
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_FRIEND_LIST_REQ, req, self, self.DummyRsp, false, true)
end

function FriendModuleData:OnGetFriendRoleList(rsp)
  local clientReqScene = rsp.client_data1 or FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault
  local serverFriendScene = rsp.scene or _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_DEFAULT
  if 0 ~= rsp.ret_info.ret_code then
    if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.FriendError.ERR_FRIEND_USE_CLIENT_CACHE then
      Log.WarningFormat("FriendModuleData:OnGetFriendRoleList cd limit, use client cache, ret_code = %d", rsp.ret_info.ret_code)
    else
      Log.ErrorFormat("FriendModuleData:OnGetFriendRoleList failed, ret_code = %d", rsp.ret_info.ret_code)
    end
    self.friendRoleWaitData = false
    self:DoGetFriendListCallback(clientReqScene)
    return
  end
  local isMergeData = 1 == rsp.client_data2
  local friendNum = rsp.friend_role_list and #rsp.friend_role_list or 0
  Log.InfoFormat("FriendModuleData:OnGetFriendRoleList pack_index = %s, is_end = %s, isMergeData = %s, clientReqScene = %s, friendNum = %s, serverFriendScene = %s, friendType = %s", tostring(rsp.pack_index), tostring(rsp.is_end), tostring(isMergeData), tostring(clientReqScene), tostring(friendNum), tostring(serverFriendScene), tostring(rsp.friend_type))
  if 1 == rsp.pack_index and not isMergeData then
    self.friendRoleWaitData = true
    if clientReqScene == FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault then
      self:ClearDefaultFriendListByType(rsp.friend_type)
    else
      self:ClearOtherSceneFriendList(clientReqScene)
    end
  end
  if rsp.friend_role_list then
    for _, friend_role in ipairs(rsp.friend_role_list) do
      if isMergeData then
        local exist_role, _ = self:GetFriendByUin(friend_role.uin, clientReqScene)
        if exist_role then
          for k, v in pairs(friend_role) do
            exist_role[k] = v
          end
        else
          Log.WarningFormat("FriendModuleData:OnGetFriendRoleList merge data but not exist uin = %s", tostring(friend_role.uin))
        end
      elseif clientReqScene == FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault then
        self:AddServerFriendToDefaultFriendList(friend_role)
      else
        self:AddServerFriendToOtherSceneFriendList(friend_role, clientReqScene)
      end
    end
  end
  if serverFriendScene == _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_DEFAULT or serverFriendScene == _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_REFRESH then
    self.friendTypeToRefreshIntervalSecDic[rsp.friend_type] = math.max(rsp.refresh_gap or 0, self.minFriendListAutoRefreshIntervalSec)
  end
  if rsp.is_end then
    self:DoGetFriendListCallback(clientReqScene, rsp.furniture_id)
  end
end

function FriendModuleData:GetMaxNumForFriendExtInfoListReq()
  return 20
end

function FriendModuleData:ClearFriendExtInfoList()
  self.friendRoleExtInfoDic = {}
  Log.Info("FriendModuleData:ClearFriendExtInfoList")
end

function FriendModuleData:ParseFriendExtInfoList(friendExtInfoList)
  if not friendExtInfoList or 0 == #friendExtInfoList then
    Log.Error("FriendModuleData:ParseFriendExtInfoList invalid friendExtInfoList")
    return
  end
  Log.InfoFormat("FriendModuleData:ParseFriendExtInfoList count = %d", #friendExtInfoList)
  for _, friendExtInfo in ipairs(friendExtInfoList) do
    self.friendRoleExtInfoDic[friendExtInfo.uin] = friendExtInfo
  end
end

function FriendModuleData:TryGetFriendExtInfoByUin(uin)
  local result = self.friendRoleExtInfoDic[uin]
  if result then
    return true, result
  end
  return false, nil
end

function FriendModuleData:GetFriendListRefreshIntervalSec(friendType)
  return self.friendTypeToRefreshIntervalSecDic[friendType] or self.minFriendListAutoRefreshIntervalSec
end

function FriendModuleData:GetLastFriendListAutoRefreshTimeSec(friendType)
  return self.friendTypeToLastAutoRefreshTimeDic[friendType] or 0
end

function FriendModuleData:SetLastFriendListAutoRefreshTimeSec(friendType, timeSec)
  self.friendTypeToLastAutoRefreshTimeDic[friendType] = timeSec
end

function FriendModuleData:GetLastChangeTabRefreshTimeSec(friendType)
  return self.friendTypeToLastChangeTabRefreshTimeDic[friendType] or 0
end

function FriendModuleData:SetLastChangeTabRefreshTimeSec(friendType, timeSec)
  self.friendTypeToLastChangeTabRefreshTimeDic[friendType] = timeSec
end

function FriendModuleData:AddServerFriendToDefaultFriendList(serverFriendRoleInfo, pos)
  local localFriendRole = self:CreateFriendRoleInfoFromServer(serverFriendRoleInfo)
  if not localFriendRole then
    Log.Error("FriendModuleData:AddServerFriendToDefaultFriendList failed to create localFriendRole")
    return
  end
  if pos then
    table.insert(self.friendRoleList, pos, localFriendRole)
  else
    table.insert(self.friendRoleList, localFriendRole)
  end
end

function FriendModuleData:ReplaceServerFriendToDefaultFriendList(serverFriendRoleInfo)
  local localFriendRole = self:CreateFriendRoleInfoFromServer(serverFriendRoleInfo)
  if not localFriendRole then
    Log.Error("FriendModuleData:ReplaceServerFriendToDefaultFriendList failed to create localFriendRole")
    return
  end
  for i, friend in ipairs(self.friendRoleList) do
    if friend.uin == localFriendRole.uin then
      self.friendRoleList[i] = localFriendRole
      return
    end
  end
  Log.ErrorFormat("FriendModuleData:ReplaceServerFriendToDefaultFriendList not found uin = %s", tostring(localFriendRole.uin))
end

function FriendModuleData:ClearDefaultFriendListByType(friendType)
  if friendType == ProtoEnum.FriendType.FRIEND_TYPE_ALL then
    self.friendRoleList = {}
  elseif friendType == ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME or friendType == ProtoEnum.FriendType.FRIEND_TYPE_PLAT then
    local newFriendRoleList = {}
    for _, friend in ipairs(self.friendRoleList) do
      if friend.friend_type ~= friendType and friend.friend_type ~= ProtoEnum.FriendType.FRIEND_TYPE_ALL then
        table.insert(newFriendRoleList, friend)
      end
    end
    self.friendRoleList = newFriendRoleList
  else
    self.friendRoleList = {}
  end
end

function FriendModuleData:AddServerFriendToOtherSceneFriendList(serverFriendRoleInfo, clientFriendScene)
  if not clientFriendScene then
    Log.Error("FriendModuleData:AddServerFriendToOtherSceneFriendList clientFriendScene is nil")
    return
  end
  if clientFriendScene == FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault then
    Log.Error("FriendModuleData:AddServerFriendToOtherSceneFriendList clientFriendScene is FriendPanelDefault, should use AddServerFriendToDefaultFriendList")
    return
  end
  local localFriendRole = self:CreateFriendRoleInfoFromServer(serverFriendRoleInfo)
  if not localFriendRole then
    Log.Error("FriendModuleData:AddServerFriendToOtherSceneFriendList failed to create localFriendRole")
    return
  end
  if not self.otherSceneToFriendRoleListDic then
    self.otherSceneToFriendRoleListDic = {}
  end
  if not self.otherSceneToFriendRoleListDic[clientFriendScene] then
    self.otherSceneToFriendRoleListDic[clientFriendScene] = {}
  end
  table.insert(self.otherSceneToFriendRoleListDic[clientFriendScene], localFriendRole)
end

function FriendModuleData:GetOtherSceneFriendList(clientFriendScene)
  if not clientFriendScene then
    Log.Error("FriendModuleData:GetOtherSceneFriendList clientFriendScene is nil")
    return {}
  end
  if not self.otherSceneToFriendRoleListDic then
    return {}
  end
  return self.otherSceneToFriendRoleListDic[clientFriendScene] or {}
end

function FriendModuleData:ClearOtherSceneFriendList(clientFriendScene)
  if not clientFriendScene then
    Log.Error("FriendModuleData:ClearOtherSceneFriendList clientFriendScene is nil")
    return
  end
  if not self.otherSceneToFriendRoleListDic then
    return
  end
  self.otherSceneToFriendRoleListDic[clientFriendScene] = nil
end

function FriendModuleData:CreateFriendRoleInfoFromServer(serverFriendRoleInfo)
  if not serverFriendRoleInfo then
    Log.Error("FriendModuleData:CreateFriendRoleInfoFromServer serverFriendRoleInfo is nil")
    return nil
  end
  if serverFriendRoleInfo.uin == nil then
    Log.Error("FriendModuleData:CreateFriendRoleInfoFromServer serverFriendRoleInfo.uin is nil")
    return nil
  end
  local friendRoleInfo = {}
  local s = serverFriendRoleInfo
  friendRoleInfo.openid = s.openid or ""
  friendRoleInfo.uin = s.uin or 0
  friendRoleInfo.name = s.name or ""
  friendRoleInfo.note = s.note or ""
  friendRoleInfo.head_img = s.head_img or ""
  friendRoleInfo.level = s.level or 0
  if nil == s.online then
    friendRoleInfo.online = false
  else
    friendRoleInfo.online = s.online
  end
  friendRoleInfo.gender = s.gender or 0
  friendRoleInfo.last_logout_time = s.last_logout_time or 0
  friendRoleInfo.signature = s.signature or ""
  friendRoleInfo.world_level = s.world_level or 0
  friendRoleInfo.send_visit_apply_time = s.send_visit_apply_time or 0
  friendRoleInfo.card_skin_selected = s.card_skin_selected or 0
  friendRoleInfo.regist_date = s.regist_date or 0
  friendRoleInfo.source = s.source or 0
  friendRoleInfo.card_icon_selected = s.card_icon_selected or 0
  friendRoleInfo.card_label_first_selected = s.card_label_first_selected or 0
  friendRoleInfo.card_label_last_selected = s.card_label_last_selected or 0
  friendRoleInfo.card_handbook_collect_num = s.card_handbook_collect_num or 0
  friendRoleInfo.card_music_id = s.card_music_id or 0
  friendRoleInfo.state = s.state or 0
  friendRoleInfo.battle_brief_info = s.battle_brief_info or nil
  friendRoleInfo.home_info = s.home_info or nil
  friendRoleInfo.add_friend_time = s.add_friend_time or 0
  friendRoleInfo.pinned_time = s.pinned_time or 0
  friendRoleInfo.bp_gift_grade = s.bp_gift_grade or 0
  friendRoleInfo.card_bussiness_card_url = s.card_bussiness_card_url or ""
  friendRoleInfo.friend_type = s.friend_type or 0
  friendRoleInfo.plat_nick_name = s.plat_nick_name or ""
  friendRoleInfo.start_up_privilege_info = s.start_up_privilege_info or nil
  friendRoleInfo.cli_login_channel = s.cli_login_channel or 0
  if nil == s.is_chat_node_unlock then
    friendRoleInfo.is_chat_node_unlock = true
  else
    friendRoleInfo.is_chat_node_unlock = s.is_chat_node_unlock
  end
  friendRoleInfo.unlocked_rel_node_num = s.unlocked_rel_node_num or 0
  if nil == s.pos_info then
  end
  friendRoleInfo.pos_info = s.pos_info or nil
  if nil == s.visit_info then
  end
  friendRoleInfo.visit_info = s.visit_info or nil
  friendRoleInfo.tags = s.tags
  return friendRoleInfo
end

function FriendModuleData:DoGetFriendListCallback(clientReqScene, furnitureId)
  Log.Info("FriendModuleData:DoGetFriendListCallback")
  self:SortFriendRoleList()
  if self.friendRoleCallback and self.friendRoleCaller then
    local friendList
    if not clientReqScene or clientReqScene == FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault then
      friendList = self.friendRoleList
    else
      friendList = self:GetOtherSceneFriendList(clientReqScene)
    end
    self.friendRoleCallback(self.friendRoleCaller, friendList, clientReqScene, furnitureId)
  end
  self.friendRoleCaller = nil
  self.friendRoleCallback = nil
  self.friendRoleWaitData = false
end

function FriendModuleData:RequestFriendRequestInfo(caller, callback)
  self.friendRequestCaller = caller
  self.friendRequestCallback = callback
  local req = _G.ProtoMessage:newZoneFriendGetAddFriendListReq()
  req.count = 0
  self.friendRequestWaitData = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_ADD_FRIEND_LIST_REQ, req, self, self.DummyRsp, false, true)
end

function FriendModuleData:DummyRsp(rsp)
end

function FriendModuleData:GetIsFriendBatchDeleteMode()
  return self.IsFriendBatchDeleteMode or false
end

function FriendModuleData:SetIsFriendBatchDeleteMode(isBatchMode)
  self.IsFriendBatchDeleteMode = isBatchMode
end

function FriendModuleData:GetFriendBatchDeleteUinList()
  return self.FriendBatchDeleteUinList or {}
end

function FriendModuleData:IsFriendBatchDeleteUinContain(uin)
  for _, v in ipairs(self.FriendBatchDeleteUinList) do
    if v == uin then
      return true
    end
  end
  return false
end

function FriendModuleData:AddFriendBatchDeleteUin(uin)
  if not self:IsFriendBatchDeleteUinContain(uin) then
    table.insert(self.FriendBatchDeleteUinList, uin)
  end
end

function FriendModuleData:RemoveFriendBatchDeleteUin(uin)
  for i = #self.FriendBatchDeleteUinList, 1, -1 do
    if self.FriendBatchDeleteUinList[i] == uin then
      table.remove(self.FriendBatchDeleteUinList, i)
      break
    end
  end
end

function FriendModuleData:ClearFriendBatchDeleteUinList()
  self.FriendBatchDeleteUinList = {}
end

function FriendModuleData:OnGetFriendRequestList(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:DoFriendRequestCallback()
    return
  end
  if 1 == rsp.pack_index then
    self.friendRequestWaitData = true
    self.friendRequestList = {}
  end
  if rsp.add_friend_list then
    for _, friend_req in ipairs(rsp.add_friend_list) do
      table.insert(self.friendRequestList, friend_req)
    end
  end
  if rsp.is_end then
    self:DoFriendRequestCallback()
  end
end

function FriendModuleData:DoFriendRequestCallback()
  self:SortFriendRequestList()
  if self.friendRequestCallback and self.friendRequestCaller then
    self.friendRequestCallback(self.friendRequestCaller, self.friendRequestList)
  end
  self.friendRequestCaller = nil
  self.friendRequestCallback = nil
  self.friendRequestWaitData = false
  self.module:DispatchEvent(FriendModuleEvent.OnFriendApplyListUpdate)
end

function FriendModuleData:RequestBlackListRoleInfo(caller, callback)
  self.blackListCaller = caller
  self.blackListCallback = callback
  local req = _G.ProtoMessage:newZoneFriendGetBlackListReq()
  req.count = 0
  self.blackListWaitData = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_GET_BLACK_LIST_REQ, req, self, self.DummyRsp, false, true)
end

function FriendModuleData:OnGetBlackList(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:DoGetBlackListCallback()
    return
  end
  if 1 == rsp.pack_index then
    self.blackListWaitData = true
    self.blackList = {}
    self.blackTimestamp = {}
  end
  if rsp.black_role_list then
    for _, black_role in ipairs(rsp.black_role_list) do
      table.insert(self.blackList, black_role)
      if black_role.uin and black_role.block_time then
        self.blackTimestamp[black_role.uin] = black_role.block_time * 1000
      end
    end
  end
  if rsp.is_end then
    self:DoGetBlackListCallback()
  end
end

function FriendModuleData:DoGetBlackListCallback()
  self:SortBlackList()
  if self.blackListCallback and self.blackListCaller then
    self.blackListCallback(self.blackListCaller, self.blackList)
  end
  self.blackListCallback = nil
  self.blackListCaller = nil
  self.blackListWaitData = false
end

function FriendModuleData:SetClickHeadInfo(_ClickHeadInfo)
  self.ClickHeadInfo = _ClickHeadInfo
end

function FriendModuleData:GetClickHeadInfo()
  return self.ClickHeadInfo
end

function FriendModuleData:SetSelectFriendIndex(index)
  self.SelectFriendIndex = index
end

function FriendModuleData:GetSelectFriendIndex()
  return self.SelectFriendIndex
end

function FriendModuleData:SetSelectFriendTabIndex(_SelectFriendTabIndex)
  self.SelectFriendTabIndex = _SelectFriendTabIndex
end

function FriendModuleData:GetSelectFriendTabIndex()
  return self.SelectFriendTabIndex
end

function FriendModuleData:SetEditSelectedPetTypeId(_EditSelectedPetTypeId)
  self.EditSelectedPetTypeId = _EditSelectedPetTypeId
end

function FriendModuleData:GetEditSelectedPetTypeId()
  return self.EditSelectedPetTypeId
end

function FriendModuleData:SetScrollOffset(scrollOffset)
  self.scrollOffset = scrollOffset
end

function FriendModuleData:GetScrollOffset()
  return self.scrollOffset
end

function FriendModuleData:GetRecommendRefreshCount()
  return self.recommendRefreshCount
end

function FriendModuleData:SetRecommendRefreshCount(count)
  self.recommendRefreshCount = count
end

function FriendModuleData:GetLastMsTimeRecommendRefresh()
  return self.lastMsTimeRecommendRefresh
end

function FriendModuleData:SetLastMsTimeRecommendRefresh(timeStamp)
  self.lastMsTimeRecommendRefresh = timeStamp
end

function FriendModuleData:GetRecommendRefreshCDMsTime()
  local FriendGlobalConfig = _G.DataConfigManager:GetFriendGlobalConfig("friend_recommend_friend_cd")
  if FriendGlobalConfig then
    local num = FriendGlobalConfig.num
    return num * 1000 or 8000
  end
  return 8000
end

function FriendModuleData:GetMaxNumOfGameFriend()
  local maxGameFriendConfig = _G.DataConfigManager:GetFriendGlobalConfig("friend_mine_num_max")
  return maxGameFriendConfig and maxGameFriendConfig.num or 100
end

function FriendModuleData:IsRecommendRefreshInCDing()
  local refreshCount = self:GetRecommendRefreshCount()
  local cdMsTime = self:GetRecommendRefreshCDMsTime()
  local curMsTime = os.msTime()
  if refreshCount > 1 and cdMsTime > curMsTime - self:GetLastMsTimeRecommendRefresh() then
    return true
  else
    return false
  end
end

function FriendModuleData:SetRecommendFilterSources(sources)
  self.recommendFilterSources = sources or {}
end

function FriendModuleData:GetRecommendFilterSources()
  return self.recommendFilterSources or {}
end

function FriendModuleData:HasRecommendFilter()
  return self.recommendFilterSources and #self.recommendFilterSources > 0
end

function FriendModuleData:ClearRecommendFilter()
  self.recommendFilterSources = {}
end

function FriendModuleData:GetRecommendFilterSourceBitFlag()
  local result = 0
  for _, source in ipairs(self.recommendFilterSources) do
    result = result | 1 << source
  end
  return result
end

function FriendModuleData:GetAllFriendRecommendConfSorted()
  local confTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FRIEND_RECOMMEND_CONF)
  if not confTable then
    return {}
  end
  local allDatas = confTable:GetAllDatas()
  if not allDatas then
    return {}
  end
  local sortedList = {}
  for _, conf in pairs(allDatas) do
    sortedList[#sortedList + 1] = conf
  end
  table.sort(sortedList, function(a, b)
    return (a.list_sort or 0) < (b.list_sort or 0)
  end)
  return sortedList
end

function FriendModuleData:_BuildFriendRecommendSourceConfCache()
  self.friendRecommendSourceToConfDic = {}
  local confTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.FRIEND_RECOMMEND_CONF)
  if not confTable then
    return
  end
  local allDatas = confTable:GetAllDatas()
  if not allDatas then
    return
  end
  for _, conf in pairs(allDatas) do
    if conf.friend_recommend_source then
      self.friendRecommendSourceToConfDic[conf.friend_recommend_source] = conf
    end
  end
end

function FriendModuleData:GetFriendRecommendConfBySource(source)
  if not source then
    return nil
  end
  if not self.friendRecommendSourceToConfDic then
    return nil
  end
  return self.friendRecommendSourceToConfDic[source]
end

function FriendModuleData:GetFriendTopMaxNum()
  local FriendGlobalConfig = _G.DataConfigManager:GetFriendGlobalConfig("friend_top_friend_num")
  if FriendGlobalConfig then
    local num = FriendGlobalConfig.num
    return num or 1
  end
  return 1
end

function FriendModuleData:GetCurEditCardInfoList(ComponentType)
  if not self.curEditCardsDic[ComponentType] then
    Log.Error("FriendModuleData:GetCurEditCardInfoList: No card list found for component type " .. ComponentType)
    return {}
  end
  return self.curEditCardsDic[ComponentType]
end

function FriendModuleData:GetMaxCardNum(ComponentType)
  local componentId = self.CardComponentTypeToIdDic[ComponentType]
  if not componentId then
    Log.Error("FriendModuleData:GetMaxCardNum: No component ID found for type " .. ComponentType)
    return 6
  end
  local componentInfo = _G.DataConfigManager:GetCardModuleConf(componentId)
  if componentInfo then
    return componentInfo.module_num
  else
    Log.Error("FriendModuleData:GetMaxCardNum: No component info found for ID " .. componentId)
    return 6
  end
end

function FriendModuleData:GetComponentNameByType(ComponentType)
  local componentId = self.CardComponentTypeToIdDic[ComponentType]
  if not componentId then
    Log.Error("FriendModuleData:GetComponentNameByType: No component ID found for type " .. ComponentType)
    return ""
  end
  local componentInfo = _G.DataConfigManager:GetCardModuleConf(componentId)
  if componentInfo then
    return componentInfo.module_name or ""
  else
    Log.Error("FriendModuleData:GetComponentNameByType: No component info found for ID " .. componentId)
    return ""
  end
end

function FriendModuleData:SetItemNumPerPageForCardComponent(itemNum)
  self.itemNumPerPageForCardComponent = itemNum
end

function FriendModuleData:GetItemNumPerPageForCardComponent()
  return self.itemNumPerPageForCardComponent
end

function FriendModuleData:GetPetTypeFilterList()
  return self.PetTypeFilterList or {}
end

function FriendModuleData:SetPetTypeFilterList(petTypeFilterList)
  petTypeFilterList = petTypeFilterList or {}
  self.PetTypeFilterList = petTypeFilterList
end

function FriendModuleData:GetCurEditPetTypeIdList()
  return self.curEditPetTypeIdList or {}
end

function FriendModuleData:SetCurEditPetTypeIdList(petTypeIdList)
  petTypeIdList = petTypeIdList or {}
  self.curEditPetTypeIdList = petTypeIdList
end

function FriendModuleData:SetCurEditCardList(ComponentType, cardInfoList)
  cardInfoList = cardInfoList or {}
  table.sort(cardInfoList, function(a, b)
    return (a:GetIndex() or 0) < (b:GetIndex() or 0)
  end)
  self.curEditCardsDic[ComponentType] = cardInfoList
end

function FriendModuleData:RemoveCurEditCard(ComponentType, posIndex)
  local curEditCardList = self.curEditCardsDic[ComponentType]
  if not curEditCardList then
    Log.Error("FriendModuleData:RemoveCurEditCard: No card list found for component type " .. ComponentType)
    return false
  end
  for i, v in ipairs(curEditCardList) do
    if v:GetIndex() == posIndex then
      table.remove(curEditCardList, i)
      return true
    end
  end
  Log.Error("FriendModuleData:RemoveCurEditCard: Pet with index " .. posIndex .. " not found")
  return false
end

function FriendModuleData:AddOrReplaceCurEditCardInfo(posIndex, cardInfo)
  if not cardInfo or cardInfo:IsCardInfoEmpty() then
    Log.Error("FriendModuleData:AddOrReplaceCurEditCardInfo: Invalid petInfo")
    return false
  end
  local curEditCardList = self.curEditCardsDic[cardInfo.ComponentType]
  if not curEditCardList then
    Log.Error("FriendModuleData:AddOrReplaceCurEditCardInfo: No card list found for component type " .. cardInfo.ComponentType)
    return false
  end
  Log.Debug("FriendModuleData:AddOrReplaceCurEditCardInfo: card with index " .. posIndex .. " and base id " .. cardInfo:GetId())
  cardInfo:SetIndex(posIndex)
  for i, v in ipairs(curEditCardList) do
    if v:GetIndex() == posIndex then
      curEditCardList[i] = cardInfo
      table.sort(curEditCardList, function(a, b)
        return a:GetIndex() < b:GetIndex()
      end)
      return true
    end
  end
  table.insert(curEditCardList, cardInfo)
  table.sort(curEditCardList, function(a, b)
    return a:GetIndex() < b:GetIndex()
  end)
  return true
end

function FriendModuleData:IsValidPetType(petTypeId)
  local validType = petTypeId ~= ProtoEnum.SkillDamType.SDT_INVALID and petTypeId ~= ProtoEnum.SkillDamType.SDT_NONE and petTypeId ~= ProtoEnum.SkillDamType.SDT_EARTH and petTypeId ~= ProtoEnum.SkillDamType.SDT_RELAX
  if validType then
    local validConfig = _G.DataConfigManager:GetTypeDictionary(petTypeId)
    if validConfig then
      return true
    else
      Log.Error("FriendModuleData:IsValidPetType: Invalid pet type config for id " .. petTypeId)
      return false
    end
  else
    return false
  end
end

function FriendModuleData:IsCurEditCardPetContainsPetHandbook(petHandbook)
  if not petHandbook then
    Log.Error("FriendModuleData:IsCurEditCardPetInfoContainsSpecificPet: Invalid petHandbook")
    return false
  end
  local curEditCardList = self.curEditCardsDic[_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET]
  if not curEditCardList then
    Log.Error("FriendModuleData:IsCurEditCardPetInfoContainsSpecificPet: No card list found for RCMT_FAVOURITE_PET")
    return false
  end
  for _, v in ipairs(curEditCardList) do
    if v:CompareFromPetHandbook(petHandbook) then
      return true
    end
  end
  return false
end

function FriendModuleData:IsCurEditCardFashionContainsFashionId(fashionId)
  if not fashionId or fashionId <= 0 then
    Log.Error("FriendModuleData:IsCurEditCardFashionContainsFashionId: Invalid fashionId")
    return false
  end
  local curEditCardList = self.curEditCardsDic[_G.ProtoEnum.RoleCardModuleType.RCMT_BADGE]
  if not curEditCardList then
    Log.Error("FriendModuleData:IsCurEditCardFashionContainsFashionId: No card list found for RCMT_FAVOURITE_FASHION")
    return false
  end
  for _, v in ipairs(curEditCardList) do
    if v:CompareFromFashinInfo(fashionId) then
      return true
    end
  end
  return false
end

function FriendModuleData:GetNextEmptyIndexForCurEditComponent(ComponentType)
  local curEditCardList = self.curEditCardsDic[ComponentType]
  if not curEditCardList then
    Log.Error("FriendModuleData:GetNextEmptyIndexForCurEditComponent: No card list found for component type " .. ComponentType)
    return nil, nil
  end
  local usedIndices = {}
  for _, v in ipairs(curEditCardList) do
    usedIndices[v:GetIndex()] = true
  end
  for i = 0, self:GetMaxCardNum(ComponentType) - 1 do
    if not usedIndices[i] then
      local pageIndex = math.floor(i / self:GetItemNumPerPageForCardComponent())
      return i, pageIndex
    end
  end
  Log.Error("FriendModuleData:GetNextEmptyIndexForCurEditComponent: No empty index available")
  return nil
end

function FriendModuleData:SwapCurEditCardInfo(ComponentType, index1, index2)
  if index1 == index2 then
    return false
  end
  local curEditCardList = self.curEditCardsDic[ComponentType]
  if not curEditCardList then
    Log.Error("FriendModuleData:SwapCurEditCardPetInfo: No card list found for component type " .. ComponentType)
    return false
  end
  local petInfo1, petInfo2
  for i, v in ipairs(curEditCardList) do
    if v:GetIndex() == index1 then
      petInfo1 = v
    elseif v:GetIndex() == index2 then
      petInfo2 = v
    end
  end
  if not petInfo1 or not petInfo2 then
    Log.Error("FriendModuleData:SwapCurEditCardPetInfo: Invalid indices")
    return false
  end
  local tempIndex = petInfo1:GetIndex()
  petInfo1:SetIndex(petInfo2:GetIndex())
  petInfo2:SetIndex(tempIndex)
  table.sort(curEditCardList, function(a, b)
    return a:GetIndex() < b:GetIndex()
  end)
  return true
end

function FriendModuleData:ResetCurEditCardInfoList(componentType)
  local curEditCardList = self.curEditCardsDic[componentType]
  if not curEditCardList then
    Log.Error("FriendModuleData:ResetCurEditCardInfoList: No card list found for component type " .. componentType)
    return
  end
  for i = #curEditCardList, 1, -1 do
    table.remove(curEditCardList, i)
  end
end

function FriendModuleData:IsCurEditCardInfoListChanged(ComponentType)
  local serverPetInfo = self:GetMyCardComponentInfoList(ComponentType) or {}
  local curEditCardList = self.curEditCardsDic[ComponentType] or {}
  local serverNum = #serverPetInfo
  local localNum = #curEditCardList
  if serverNum ~= localNum then
    return true
  end
  if 0 == serverNum and 0 == localNum then
    return false
  end
  
  local function sortLocalByIndex(a, b)
    return a:GetIndex() < b:GetIndex()
  end
  
  local function sortServerByIndex(a, b)
    return (a.index or 0) < (b.index or 0)
  end
  
  table.sort(curEditCardList, sortLocalByIndex)
  table.sort(serverPetInfo, sortServerByIndex)
  for i = 1, #curEditCardList do
    local localPet = curEditCardList[i]
    local serverPet = serverPetInfo[i]
    if not localPet:CompareFromServerCollectInfo(serverPet) then
      return true
    end
  end
  return false
end

function FriendModuleData:IsCurEditCardInfoChanged()
  return self:IsCurEditCardInfoListChanged(_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET) or self:IsCurEditCardInfoListChanged(_G.ProtoEnum.RoleCardModuleType.RCMT_BADGE)
end

function FriendModuleData:SetIsEditingComponent(isEditing)
  self.isEditingComponent = isEditing
end

function FriendModuleData:GetIsEditingComponent()
  return self.isEditingComponent
end

function FriendModuleData:InitCardComponent()
  local cardModuleTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CARD_MODULE_CONF)
  local cardModuleData = cardModuleTable:GetAllDatas()
  self.CardComponentTypeToIdDic = {}
  for _, conf in pairs(cardModuleData) do
    self.CardComponentTypeToIdDic[conf.module_type] = conf.id
  end
end

function FriendModuleData:GetCardComponentIdByType(componentType)
  return self.CardComponentTypeToIdDic[componentType]
end

function FriendModuleData:BuildEmojiEscToIdMap()
  local emoji_bag_info = _G.DataModelMgr.PlayerDataModel:GetEmojiBagInfo()
  self.EmojiEscToIdMap = {}
  self.CanSeeEmojiEscToIdMap = {}
  if emoji_bag_info then
    for i, v in ipairs(emoji_bag_info) do
      local conf = _G.DataConfigManager:GetChatEmojiConf(v.emoji_id)
      if conf and conf.emoji_esc and v.is_unlock then
        self.EmojiEscToIdMap[conf.emoji_esc] = conf
      end
    end
  end
  local EmoTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CHAT_EMOJI_CONF)
  local EmoData = EmoTable:GetAllDatas()
  self.CanSeeEmojiEscToIdMap = {}
  for _, conf in pairs(EmoData) do
    self.CanSeeEmojiEscToIdMap[conf.emoji_esc] = conf
  end
end

function FriendModuleData:SetChatFirstRole(uin)
  self.ChatFirstRoleUin = uin
end

function FriendModuleData:GetChatFirstRole()
  return self.ChatFirstRoleUin
end

function FriendModuleData:SetCurChatUin(_CurChatUin)
  self.CurChatUin = _CurChatUin
end

function FriendModuleData:GetCurChatUin()
  return self.CurChatUin
end

function FriendModuleData:SetLatestChatSession(_Uin, _time_stamp)
  self.LatestChatSession.Uin = _Uin
  self.LatestChatSession.time_stamp = _time_stamp
end

function FriendModuleData:GetLatestChatSessionUin()
  return self.LatestChatSession.Uin
end

function FriendModuleData:SetIsOpenQuickChatBubble(_IsOpenQuickChatBubble)
  self.IsOpenQuickChatBubble = _IsOpenQuickChatBubble
end

function FriendModuleData:GetIsOpenQuickChatBubble()
  return self.IsOpenQuickChatBubble
end

function FriendModuleData:SetTemporaryInput(_TemporaryInput)
  self.TemporaryInput = _TemporaryInput
end

function FriendModuleData:GetTemporaryInput()
  return self.TemporaryInput
end

function FriendModuleData:SetQuickChatTemporaryInput(_QuickChatTemporaryInput)
  self.QuickChatTemporaryInput = _QuickChatTemporaryInput
end

function FriendModuleData:GetQuickChatTemporaryInput()
  return self.QuickChatTemporaryInput
end

function FriendModuleData:SetbCloseLobbyMain(_bCloseLobbyMain)
  self.bCloseLobbyMain = _bCloseLobbyMain
end

function FriendModuleData:GetbCloseLobbyMain()
  return self.bCloseLobbyMain
end

function FriendModuleData:SetChatRoleList(chatSessionInfoList, firstUin, firstMessageList)
  if chatSessionInfoList and #chatSessionInfoList > 0 then
    for k, v in ipairs(chatSessionInfoList) do
      local hasSame = false
      for i = 1, #self.ChatSessionList do
        if self.ChatSessionList[i].basic_info.uin == v.basic_info.uin then
          hasSame = true
          self.ChatSessionList[i].basic_info.time_stamp = v.basic_info.time_stamp
          if v.friend_session_info then
            self.ChatSessionList[i].friend_session_info = v.friend_session_info
          end
        end
      end
      if false == hasSame and v.basic_info.uin and v.basic_info.uin > 0 then
        table.insert(self.ChatSessionList, v)
      end
      if firstUin == v.basic_info.uin then
        self:SetChatFirstRole(v.basic_info.uin)
      end
      if v.basic_info.time_stamp and v.basic_info.time_stamp > self.LatestChatSession.time_stamp then
        self:SetLatestChatSession(v.basic_info.uin, v.basic_info.time_stamp)
      end
    end
  end
end

function FriendModuleData:RefreshSessionTimeStamp(uin, timeStamp)
  if self.ChatSessionList and #self.ChatSessionList > 0 then
    for k, v in ipairs(self.ChatSessionList) do
      if v.basic_info.uin == uin then
        v.basic_info.time_stamp = timeStamp
        return
      end
    end
  end
end

function FriendModuleData:RefreshSessionNote(uin, note)
  if self.ChatSessionList and #self.ChatSessionList > 0 then
    for k, v in ipairs(self.ChatSessionList) do
      if v.basic_info.uin == uin then
        v.friend_session_info.note = note
        return
      end
    end
  end
end

function FriendModuleData:GetSortedChatSessionList(uin)
  if 0 == uin then
    self:SortChatSessionList()
  elseif self:GetSessionInfo(self.MultiPlayerChannelType) then
    self:SortChatSessionList()
  else
    local firstChatRoleListItem
    for k, v in pairs(self.ChatSessionList) do
      if v.basic_info.uin == uin then
        firstChatRoleListItem = v
        table.remove(self.ChatSessionList, k)
        break
      end
    end
    self:SortChatSessionList()
    if firstChatRoleListItem then
      table.insert(self.ChatSessionList, 1, firstChatRoleListItem)
    end
  end
  return self.ChatSessionList
end

function FriendModuleData:SortChatSessionList()
  local sessionList = self.ChatSessionList
  if sessionList then
    table.sort(sessionList, function(a, b)
      if a.basic_info.uin == self.MultiPlayerChannelType then
        return true
      end
      if b.basic_info.uin == self.MultiPlayerChannelType then
        return false
      end
      if a.basic_info.time_stamp and b.basic_info.time_stamp then
        return a.basic_info.time_stamp > b.basic_info.time_stamp
      end
    end)
  end
  self.ChatSessionList = sessionList
end

function FriendModuleData:AddLocalChatMessage(uin, message, msgSource)
  if not uin or not message then
    return
  end
  local messageInfo = {}
  if type(message) == "string" then
    messageInfo.chat_message = message
    messageInfo.time_stamp = _G.ZoneServer:GetServerTime()
  else
    messageInfo = message
  end
  messageInfo.msgSource = msgSource or FriendEnum.ChatMsgSource.Client
  self.LocalChatMessageList[uin] = self.LocalChatMessageList[uin] or {}
  self:SetChatMultiPlayerMessageList({messageInfo})
  table.insert(self.LocalChatMessageList[uin], messageInfo)
  return messageInfo
end

function FriendModuleData:SetChatMessageList(uin, sessionInfo, messageList, startIndex)
  if nil == messageList or #messageList <= 0 then
    return
  end
  for k, v in ipairs(messageList) do
    if v.msg_detail_info and v.msg_detail_info.need_cypher then
      v.chat_message = string.CipherTextEncode(v.chat_message)
    end
  end
  local setUin = 0
  if sessionInfo then
    setUin = sessionInfo.basic_info.uin
  else
    setUin = uin
  end
  if nil == setUin then
    return
  end
  if nil == self.ChatMessageList[setUin] then
    self.ChatMessageList[setUin] = {}
    self.ChatMessageList[setUin] = messageList
  else
    if startIndex and startIndex > 0 then
      for i = #messageList, 1, -1 do
        if nil == self.ChatMessageList[setUin] then
          self.ChatMessageList[setUin] = {}
        end
        table.insert(self.ChatMessageList[setUin], 1, messageList[i])
      end
    else
      for k, v in ipairs(messageList) do
        if nil == self.ChatMessageList[setUin] then
          self.ChatMessageList[setUin] = {}
        end
        if uin then
          self.ChatMessageList[setUin] = messageList
        else
          table.insert(self.ChatMessageList[setUin], v)
          if setUin == self.MultiPlayerChannelType then
            local maxSize = self:GetSaveMultipleChatNum()
            if maxSize < #self.ChatMessageList[setUin] then
              table.remove(self.ChatMessageList[setUin], 1)
            end
          end
        end
      end
    end
    if uin then
      table.sort(self.ChatMessageList[setUin], function(a, b)
        if a.time_stamp and b.time_stamp then
          return a.time_stamp < b.time_stamp
        end
      end)
    else
    end
  end
end

function FriendModuleData:SetChatMultiPlayerMessageList(sessionInfo, messageList)
  if sessionInfo and sessionInfo.basic_info and sessionInfo.basic_info.uin then
    if sessionInfo.basic_info.uin ~= self.MultiPlayerChannelType then
      return
    end
  else
    return
  end
  if nil == messageList or #messageList <= 0 then
    return
  end
  local maxSize = self:GetSaveMultipleChatNum()
  if nil == self.ChatChatMultiPlayerMessageList then
    self.ChatChatMultiPlayerMessageList = {}
  end
  for k, v in ipairs(messageList) do
    table.insert(self.ChatChatMultiPlayerMessageList, v)
  end
  if maxSize < #self.ChatChatMultiPlayerMessageList then
    table.remove(self.ChatChatMultiPlayerMessageList, 1)
  end
end

function FriendModuleData:RemoveSessionInfo(uin)
  if uin then
    self.ChatAllMsgFetchedMap[uin] = nil
  end
  local removeKey = 0
  for k, v in ipairs(self.ChatSessionList) do
    if v.basic_info.uin == uin then
      removeKey = k
      break
    end
  end
  if 0 ~= removeKey then
    self.module:DispatchEvent(FriendModuleEvent.OnRemoveChatListSucc, uin)
    table.remove(self.ChatSessionList, removeKey)
    table.removeKey(self.ChatMessageList, uin)
  end
  if uin then
    self.LocalChatMessageList[uin] = nil
  end
end

function FriendModuleData:GetSessionInfo(uin)
  for i, v in ipairs(self.ChatSessionList) do
    if v.basic_info.uin == uin then
      return v, i
    end
  end
end

function FriendModuleData:ClearChatCache()
  self.ChatSessionList = nil
  self.ChatMessageList = nil
  self.ChatAllMsgFetchedMap = {}
  if self.ChatSessionList == nil then
    self.ChatSessionList = {}
    table.insert(self.ChatSessionList, self.ChatMultiPlayerChannelInfo)
  end
  if nil == self.ChatMessageList then
    self.ChatMessageList = {}
  end
end

function FriendModuleData:InItMultiPlayerChannelData()
  if self.ChatChatMultiPlayerMessageList and #self.ChatChatMultiPlayerMessageList > 0 then
    self.ChatMessageList[self.MultiPlayerChannelType] = table.deepCopy(self.ChatChatMultiPlayerMessageList)
  end
end

function FriendModuleData:SetEntrance(_Entrance)
  self.Entrance = _Entrance
end

function FriendModuleData:GetEntrance()
  return self.Entrance
end

function FriendModuleData:SetbOpenByQuickChat(_bOpenByQuickChat)
  self.bOpenByQuickChat = _bOpenByQuickChat
end

function FriendModuleData:GetbOpenByQuickChat()
  return self.bOpenByQuickChat
end

function FriendModuleData:initializeCardIcon()
  local UnlockCardIcon = {}
  local CardIconConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CARD_ICON_CONF):GetAllDatas()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  for i, CardIcon in ipairs(CardIconConf) do
    if CardIcon.is_initial_unlock == true then
      if PlayerInfo.sex == _G.ProtoEnum.ESexValue.SEX_MALE then
        if CardIcon.unlock_condition == Enum.UnlockCondition.UC_MALE then
          table.insert(UnlockCardIcon, {
            card_item_id = CardIcon.id,
            card_item_get_timestamp = 0,
            ConfigurationInfo = CardIcon,
            is_initial_unlock = CardIcon.is_initial_unlock
          })
        end
      elseif PlayerInfo.sex == _G.ProtoEnum.ESexValue.SEX_FEMALE and CardIcon.unlock_condition == Enum.UnlockCondition.UC_FEMALE then
        table.insert(UnlockCardIcon, {
          card_item_id = CardIcon.id,
          card_item_get_timestamp = 0,
          ConfigurationInfo = CardIcon,
          is_initial_unlock = CardIcon.is_initial_unlock
        })
      end
    end
  end
  self.icon_owned = UnlockCardIcon
end

function FriendModuleData:AddIconList(_icon_owned)
  if not _icon_owned then
    return
  end
  local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_CARD_NEW_ICON)
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  for i, IconId in ipairs(_icon_owned) do
    if not self:IsExistCardInfo(self.icon_owned, IconId.card_item_id) then
      local CardIconConf = _G.DataConfigManager:GetCardIconConf(IconId.card_item_id)
      if CardBriefInfo and CardBriefInfo.card_icon_selected == IconId.card_item_id then
        table.insert(self.icon_owned, 1, {
          card_item_id = IconId.card_item_id,
          card_item_get_timestamp = IconId.card_item_get_timestamp,
          ConfigurationInfo = CardIconConf,
          is_initial_unlock = true
        })
      else
        table.insert(self.icon_owned, {
          card_item_id = IconId.card_item_id,
          card_item_get_timestamp = IconId.card_item_get_timestamp,
          ConfigurationInfo = CardIconConf,
          is_initial_unlock = true
        })
      end
    end
  end
  self:SortByTime(self.icon_owned)
end

function FriendModuleData:OpenAvatar()
end

function FriendModuleData:OpenPanelSort(Reason, _TabList, CardType, LastLabelReason)
  self:SortByTime(_TabList)
  if nil ~= LastLabelReason then
    _TabList = self:LabelSort(_TabList)
  end
end

function FriendModuleData:LabelSort(_TabList)
  local LeftLabel = {}
  local RightLabel = {}
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  for i, Label in ipairs(_TabList) do
    if Label.ConfigurationInfo.label_type == Enum.LabelType.LT_FIRST then
      if CardBriefInfo and Label.card_item_id == CardBriefInfo.card_label_first_selected then
        table.insert(LeftLabel, 1, Label)
      else
        table.insert(LeftLabel, Label)
      end
    elseif CardBriefInfo and Label.card_item_id == CardBriefInfo.card_label_last_selected then
      table.insert(RightLabel, 1, Label)
    else
      table.insert(RightLabel, Label)
    end
  end
  for i, Label in ipairs(LeftLabel) do
    table.insert(RightLabel, Label)
  end
  return RightLabel
end

function FriendModuleData:GetIconList()
  return self.icon_owned
end

function FriendModuleData:initializeCardSkin()
  local UnlockCardSkin = {}
  local CardSkinConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CARD_SKIN_CONF):GetAllDatas()
  for i, CardSkin in pairs(CardSkinConf) do
    local card_item_get_timestamp = 0
    if CardSkin.is_initial_unlock then
      card_item_get_timestamp = 1
      if CardSkin.is_default then
        self:SetDefaultSkinId(CardSkin.id)
      end
    end
    table.insert(UnlockCardSkin, {
      card_item_id = CardSkin.id,
      card_item_get_timestamp = card_item_get_timestamp,
      ownedNum = 0,
      is_initial_unlock = CardSkin.is_initial_unlock,
      ConfigurationInfo = CardSkin,
      is_initial_unlock = CardSkin.is_initial_unlock,
      TabType = FriendEnum.ImageEditorType.Theme
    })
  end
  self.skin_owned = UnlockCardSkin
  self:SortByTime(self.skin_owned)
end

function FriendModuleData:OpenCardBG()
end

function FriendModuleData:AddSkinList(serverSkinOwned)
  if not serverSkinOwned then
    return
  end
  self:initializeCardSkin()
  local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_CARD_NEW_SKIN)
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  for i, IconId in ipairs(serverSkinOwned) do
    for j, skin in ipairs(self.skin_owned) do
      if skin.card_item_id == IconId.card_item_id then
        skin.is_initial_unlock = true
        skin.card_item_get_timestamp = IconId.card_item_get_timestamp
        skin.ownedNum = IconId.card_item_num or 1
      end
    end
  end
  self:SortByTime(self.skin_owned)
end

function FriendModuleData:GetSkinList()
  return self.skin_owned
end

function FriendModuleData:GetCurUsedCardSkinId()
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  local curUsedCardSkinId = CardBriefInfo.card_appearance_info and CardBriefInfo.card_appearance_info.card_skin_selected or 0
  if 0 == curUsedCardSkinId then
    curUsedCardSkinId = self:GetDefaultSkinId() or 0
  end
  return curUsedCardSkinId
end

function FriendModuleData:GetSkinByCardItemId(card_item_id)
  for j, skin in ipairs(self.skin_owned) do
    if skin.card_item_id == card_item_id then
      return skin
    end
  end
  return nil
end

function FriendModuleData:GetEditSelectedCardSkinId()
  return self.editSelectedCardSkinId or 0
end

function FriendModuleData:SetEditSelectedCardSkinId(card_item_id)
  self.editSelectedCardSkinId = card_item_id
end

function FriendModuleData:initializeCardLabel()
  local UnlockCardLabel = {}
  local CardLabelConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CARD_LABEL_CONF):GetAllDatas()
  for i, CardLabel in pairs(CardLabelConf) do
    if CardLabel.is_initial_unlock == true then
      table.insert(UnlockCardLabel, {
        card_item_id = CardLabel.id,
        card_item_get_timestamp = 0,
        ConfigurationInfo = CardLabel,
        is_initial_unlock = CardLabel.is_initial_unlock
      })
    end
  end
  self.label_owned = UnlockCardLabel
end

function FriendModuleData:OpenLabel()
end

function FriendModuleData:AddLabelList(_label_owned)
  if not _label_owned then
    return
  end
  local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_CARD_NEW_LABEL_FIRST)
  local pointData_1 = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_CARD_NEW_LABEL_LAST)
  for i, IconId in ipairs(_label_owned) do
    if not self:IsExistCardInfo(self.label_owned, IconId.card_item_id) then
      local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(IconId.card_item_id)
      table.insert(self.label_owned, {
        card_item_id = IconId.card_item_id,
        card_item_get_timestamp = 0,
        ConfigurationInfo = CardLabelConf,
        is_initial_unlock = true
      })
    end
  end
  self.label_owned = self:LabelSort(self.label_owned)
  self:SortByTime(self.label_owned)
end

function FriendModuleData:AddSuitList()
  self.Suit_owned = {}
  local rolePlayItems = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, RolePlayModuleDef.RolePlayType.Suit)
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  for i, rolePlayItem in ipairs(rolePlayItems) do
    local Name, Icon, FashionItemConf, fashionIds
    if rolePlayItem.suitType == "allCollect" then
      Name = rolePlayItem.name
      Icon = rolePlayItem.iconPath
      local FashionSuitsConf = _G.DataConfigManager:GetFashionSuitsConf(rolePlayItem.suitID)
      fashionIds = FashionSuitsConf and FashionSuitsConf.item_id or nil
      if fashionIds then
        for _, v in ipairs(fashionIds) do
          if 0 ~= v then
            FashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
            break
          end
        end
      end
    else
      local Text = _G.DataConfigManager:GetLocalizationConf("umg_appearance_suititem_1").msg
      Name = string.format("%s%d", Text, i)
      local wardrobeConf = rolePlayItem and rolePlayItem.value
      if wardrobeConf then
        fashionIds = wardrobeConf.fashion_wear_id
        if not fashionIds then
          local fashionItems = wardrobeConf.wearing_item
          fashionIds = {}
          for _, v in pairs(fashionItems or {}) do
            table.insert(fashionIds, v.wearing_item_id)
          end
        end
        if fashionIds then
          for _, v in ipairs(fashionIds) do
            if 0 ~= v then
              FashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
              Icon = FashionItemConf.icon
              break
            end
          end
        end
        if FashionItemConf then
          if wardrobeConf and wardrobeConf.wardrobe_name and wardrobeConf.wardrobe_name ~= "" then
            Name = wardrobeConf.wardrobe_name
          end
          if wardrobeConf and wardrobeConf.name and wardrobeConf.name ~= "" then
            Name = wardrobeConf.name
          end
        end
      end
    end
    if FashionItemConf then
      if CardBriefInfo and CardBriefInfo.card_appearance_info and CardBriefInfo.card_appearance_info.fashion_wear_id and CardBriefInfo.card_appearance_info.fashion_wear_id[1] == FashionItemConf.id then
        table.insert(self.Suit_owned, 1, {
          card_item_id = FashionItemConf.id,
          card_item_get_timestamp = i,
          fashionIds = fashionIds,
          ConfigurationInfo = FashionItemConf,
          is_initial_unlock = true,
          Name = Name,
          suitID = rolePlayItem.suitID,
          Icon = Icon,
          TabType = FriendEnum.ImageEditorType.Clothing
        })
      else
        table.insert(self.Suit_owned, {
          card_item_id = FashionItemConf.id,
          card_item_get_timestamp = i,
          fashionIds = fashionIds,
          ConfigurationInfo = FashionItemConf,
          is_initial_unlock = true,
          Name = Name,
          suitID = rolePlayItem.suitID,
          Icon = Icon,
          TabType = FriendEnum.ImageEditorType.Clothing
        })
      end
    else
      Log.Error("\230\178\161\230\156\137\232\175\165\230\156\141\232\163\133id,\230\156\141\232\163\133\229\144\141\229\173\151---", Name)
    end
  end
  self:CardSortDown(self.Suit_owned)
end

function FriendModuleData:GetSuitList()
  return self.Suit_owned
end

function FriendModuleData:initializeCardPose()
  local UnlockCardPose = {}
  local CardPoseConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ROLEPLAY_BEHAVIOR_CONF):GetAllDatas()
  for i, CardPose in pairs(CardPoseConf) do
    if CardPose.behavior_type == Enum.BehaviorType.BT_EMONTIONAL_EMOTE or CardPose.behavior_type == Enum.BehaviorType.BT_INFORMATION_EMOTE then
      local card_item_get_timestamp = 0
      if 14 == CardPose.id then
        card_item_get_timestamp = 9999
      end
      table.insert(UnlockCardPose, {
        card_item_id = CardPose.id,
        card_item_get_timestamp = card_item_get_timestamp,
        ConfigurationInfo = CardPose,
        is_initial_unlock = CardPose.is_initial_unlock,
        TabType = FriendEnum.ImageEditorType.PlayerAction
      })
    end
  end
  self.Pose_owned = UnlockCardPose
  self:SortPoseList(self.Pose_owned)
end

function FriendModuleData:AddPoseList()
  local RolePlayList = _G.DataModelMgr.PlayerDataModel:GetRolePlayList()
  if not RolePlayList or #RolePlayList <= 0 then
    return
  end
  for i, IconId in ipairs(RolePlayList) do
    for j, Pose in ipairs(self.Pose_owned) do
      if Pose.card_item_id == IconId then
        Pose.is_initial_unlock = true
        if 14 == IconId then
          Pose.card_item_get_timestamp = 9999
        else
          Pose.card_item_get_timestamp = 9998 - (#RolePlayList - i)
        end
      end
    end
  end
  self:SortPoseList(self.Pose_owned)
end

function FriendModuleData:SortPoseList(_TabList)
  table.sort(_TabList, function(a, b)
    if a.card_item_get_timestamp > b.card_item_get_timestamp then
      return a.card_item_get_timestamp > b.card_item_get_timestamp
    elseif a.card_item_get_timestamp == b.card_item_get_timestamp then
      if a.is_initial_unlock == true then
        if b.is_initial_unlock == true then
          return a.card_item_id < b.card_item_id
        else
          return true
        end
      elseif b.is_initial_unlock == true then
        return false
      else
        return a.card_item_id < b.card_item_id
      end
    end
  end)
end

function FriendModuleData:GetPoseList()
  return self.Pose_owned
end

function FriendModuleData:GetLabelList()
  return self.label_owned
end

function FriendModuleData:IsExistCardInfo(_TabList, FindId)
  if type(FindId) ~= "number" then
    FindId = tonumber(FindId)
  end
  for i, Tab in ipairs(_TabList) do
    if FindId == Tab.card_item_id then
      return true
    end
  end
  return false
end

function FriendModuleData:IsExistCardSuit(_TabList, FindId)
  if type(FindId) ~= "number" then
    FindId = tonumber(FindId)
  end
  for i, Tab in ipairs(_TabList) do
    if FindId == Tab.id then
      return true
    end
  end
  return false
end

function FriendModuleData:IsFirstGetCardInfo(pointData, FindId)
  if not pointData then
    return false
  end
  for i, Point in ipairs(pointData) do
    if FindId == tonumber(Point) then
      return true
    end
  end
  return false
end

function FriendModuleData:CardSort(_TabList)
  table.sort(_TabList, function(a, b)
    if a.card_item_id > b.card_item_id then
      return a.card_item_id > b.card_item_id
    end
  end)
end

function FriendModuleData:CardSortDown(_TabList)
  table.sort(_TabList, function(a, b)
    if a.card_item_get_timestamp and b.card_item_get_timestamp and a.card_item_get_timestamp == b.card_item_get_timestamp then
      return a.card_item_id < b.card_item_id
    else
      return a.card_item_get_timestamp < b.card_item_get_timestamp
    end
  end)
end

function FriendModuleData:SortByTime(_TabList)
  table.sort(_TabList, function(a, b)
    if a.card_item_get_timestamp and b.card_item_get_timestamp and a.card_item_get_timestamp == b.card_item_get_timestamp then
      return a.card_item_id < b.card_item_id
    else
      return a.card_item_get_timestamp > b.card_item_get_timestamp
    end
  end)
end

function FriendModuleData:RemovePointCard(_TabList, RemoveId)
  for i = #_TabList, 1, -1 do
    if _TabList[i].card_item_id == RemoveId then
      table.remove(_TabList, i)
    end
  end
end

function FriendModuleData:InsertFirst(PointCardInfo, _TabList)
  for i, Point in ipairs(PointCardInfo) do
    table.insert(_TabList, 1, Point)
  end
  self.new_label_owned = _TabList
end

function FriendModuleData:GetPointCardInfo(pointData, _TabList, CardType)
  local PointCardInfo = {}
  if pointData then
    for i, point in ipairs(pointData) do
      if self:IsExistCardInfo(_TabList, point) then
        self:RemovePointCard(_TabList, tonumber(point))
      end
      local CardConf
      if CardType == Enum.GoodsType.GT_CARD_ICON then
        CardConf = _G.DataConfigManager:GetCardIconConf(tonumber(point))
      elseif CardType == Enum.GoodsType.GT_CARD_SKIN then
        CardConf = _G.DataConfigManager:GetCardSkinConf(tonumber(point))
      elseif CardType == Enum.GoodsType.GT_CARD_LABEL then
        CardConf = _G.DataConfigManager:GetCardLabelConf(tonumber(point))
      end
      table.insert(PointCardInfo, CardConf)
    end
  end
  return PointCardInfo
end

function FriendModuleData:GetCurrentUseHeadIcon()
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  local AvatarPath
  if not CardBriefInfo or CardBriefInfo.card_icon_selected == nil then
    AvatarPath = self.icon_owned[1].icon_resource_path
  else
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(CardBriefInfo.card_icon_selected)
    if CardIconConf then
      AvatarPath = CardIconConf.icon_resource_path
    end
  end
  AvatarPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, AvatarPath, AvatarPath)
  return AvatarPath
end

function FriendModuleData:GetHeadIconByHeadId(IconId)
  local CardIconConf = _G.DataConfigManager:GetCardIconConf(IconId)
  if not CardIconConf then
    return ""
  end
  local AvatarPath = CardIconConf.icon_resource_path
  AvatarPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, AvatarPath, AvatarPath)
  return AvatarPath
end

function FriendModuleData:SetApplyTimeForPlayerInteractType(_Uin, _PlayerInteractType, _ApplyTime)
  if not self.PlayerInteractTypeToApplyTimeDic then
    self.PlayerInteractTypeToApplyTimeDic = {}
  end
  if not self.PlayerInteractTypeToApplyTimeDic[_Uin] then
    self.PlayerInteractTypeToApplyTimeDic[_Uin] = {}
  end
  self.PlayerInteractTypeToApplyTimeDic[_Uin][_PlayerInteractType] = _ApplyTime
end

function FriendModuleData:GetApplyTimeForPlayerInteractType(_Uin, _PlayerInteractType)
  if not self.PlayerInteractTypeToApplyTimeDic then
    return 0
  end
  if not self.PlayerInteractTypeToApplyTimeDic[_Uin] then
    return 0
  end
  return self.PlayerInteractTypeToApplyTimeDic[_Uin][_PlayerInteractType] or 0
end

function FriendModuleData:SetSelectImageEditorIndex(_Index)
  self.SelectTab = _Index
end

function FriendModuleData:GetSelectImageEditorIndex()
  return self.SelectTab
end

function FriendModuleData:SetOldSelectTab(_Index)
  self.OldSelectTab = _Index
end

function FriendModuleData:GetOldSelectTab()
  return self.OldSelectTab
end

function FriendModuleData:SetModifyCardInfo(_CardFriendInfo, _CardAdminFriendType, _CardSource, _CardSelectTab, bToggleToPhotoCropping, _studentCardForbidAddFriend, _studentCardForbidEdit)
  self.CardFriendInfo = _CardFriendInfo
  self.CardAdminFriendType = _CardAdminFriendType
  self.CardSource = _CardSource
  self.CardSelectTab = _CardSelectTab
  self.bToggleToPhotoCropping = bToggleToPhotoCropping
  self.studentCardForbidAddFriend = _studentCardForbidAddFriend
  self.studentCardForbidEdit = _studentCardForbidEdit
end

function FriendModuleData:SetCroppingPhotoData(PhotoData)
  self.CroppingPhotoData = PhotoData
end

function FriendModuleData:GetCroppingPhotoData()
  return self.CroppingPhotoData
end

function FriendModuleData:IsStudentCardForbidAddFriend()
  return self.studentCardForbidAddFriend or false
end

function FriendModuleData:IsStudentCardForbidEdit()
  return self.studentCardForbidEdit or false
end

function FriendModuleData:IsToggleToPhotoCropping()
  return self.bToggleToPhotoCropping
end

function FriendModuleData:GetModifyCardInfo()
  return self.CardFriendInfo, self.CardAdminFriendType, self.CardSource, self.CardSelectTab
end

function FriendModuleData:GetStudentCardSelectTab()
  return self.CardSelectTab
end

function FriendModuleData:ClearStudentCardSelectTab()
  self.CardSelectTab = nil
end

function FriendModuleData:ClearModifyCardInfo()
  self.CardFriendInfo = nil
  self.CardAdminFriendType = nil
  self.CardSource = nil
  self.CardSelectTab = nil
end

function FriendModuleData:GetCardFriendInfo()
  return self.CardFriendInfo
end

function FriendModuleData:GetCardAdminFriendType()
  return self.CardAdminFriendType
end

function FriendModuleData:GetCardSource()
  return self.CardSource
end

function FriendModuleData:SetPlayerCardBriefInfo(_PlayerCardBriefInfo)
  self.PlayerCardBriefInfo = _PlayerCardBriefInfo
end

function FriendModuleData:GetPlayerCardBriefInfo()
  return self.PlayerCardBriefInfo
end

function FriendModuleData:SetPlayerCardBriefInfoUin(_Uin)
  self.PlayerCardBriefInfoUin = _Uin
end

function FriendModuleData:GetPlayerCardBriefInfoUin()
  return self.PlayerCardBriefInfoUin
end

function FriendModuleData:UpdatePlayerCardBriefInfoPinnedTime(_uin, _pinnedTime)
  if not self.PlayerCardBriefInfoUin or self.PlayerCardBriefInfoUin ~= _uin then
    return
  end
  if self.PlayerCardBriefInfo then
    self.PlayerCardBriefInfo.pinned_time = _pinnedTime
  end
end

function FriendModuleData:GetMyCardComponentCollectInfo()
  local PlayerCardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  if PlayerCardBriefInfo and PlayerCardBriefInfo.card_collect_info then
    return PlayerCardBriefInfo.card_collect_info
  else
    return nil
  end
end

function FriendModuleData:GetMyCardComponentInfoList(ComponentType)
  local collectCardInfo = self:GetMyCardComponentCollectInfo()
  if collectCardInfo then
    if ComponentType == _G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET then
      return collectCardInfo.card_module_pet_infos or {}
    elseif ComponentType == _G.ProtoEnum.RoleCardModuleType.RCMT_BADGE then
      return collectCardInfo.card_module_fashion_infos or {}
    end
  end
  return {}
end

function FriendModuleData:GetCardComponentInfoListForShow(ComponentType, PlayerCardBriefInfo)
  local cardInfoList = {}
  if not PlayerCardBriefInfo or not PlayerCardBriefInfo.card_collect_info then
    return cardInfoList
  end
  local collectCardInfo = PlayerCardBriefInfo.card_collect_info
  if ComponentType == _G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET then
    if collectCardInfo.card_module_pet_infos then
      for i, petInfo in ipairs(collectCardInfo.card_module_pet_infos) do
        local newPetInfo = table.deepCopy(petInfo)
        local itemData = EditComponentItemData:Create(_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET)
        itemData:InitFromPetInfo(newPetInfo)
        table.insert(cardInfoList, itemData)
      end
    end
  elseif ComponentType == _G.ProtoEnum.RoleCardModuleType.RCMT_BADGE and collectCardInfo.card_module_fashion_infos then
    for i, fashionInfo in ipairs(collectCardInfo.card_module_fashion_infos) do
      local newFashionInfo = table.deepCopy(fashionInfo)
      local itemData = EditComponentItemData:Create(_G.ProtoEnum.RoleCardModuleType.RCMT_BADGE)
      itemData:InitFromBadgeInfo(newFashionInfo)
      table.insert(cardInfoList, itemData)
    end
  end
  return cardInfoList
end

function FriendModuleData:InitCurEditCardInfo()
  local collectCardInfo = self:GetMyCardComponentCollectInfo()
  if collectCardInfo then
    local petInfos = {}
    if collectCardInfo.card_module_pet_infos then
      for i, petInfo in ipairs(collectCardInfo.card_module_pet_infos) do
        local newPetInfo = table.deepCopy(petInfo)
        local itemData = EditComponentItemData:Create(_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET)
        itemData:InitFromPetInfo(newPetInfo)
        table.insert(petInfos, itemData)
      end
    end
    self:SetCurEditCardList(_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET, petInfos)
    local fashionInfos = {}
    if collectCardInfo.card_module_fashion_infos then
      for i, fashionInfo in ipairs(collectCardInfo.card_module_fashion_infos) do
        local newFashionInfo = table.deepCopy(fashionInfo)
        local itemData = EditComponentItemData:Create(_G.ProtoEnum.RoleCardModuleType.RCMT_BADGE)
        itemData:InitFromBadgeInfo(newFashionInfo)
        table.insert(fashionInfos, itemData)
      end
    end
    self:SetCurEditCardList(_G.ProtoEnum.RoleCardModuleType.RCMT_BADGE, fashionInfos)
  end
end

function FriendModuleData:GetCardSelectTab()
  return self.CardSelectTab
end

function FriendModuleData:SetFavoritePet(_FavoritePet)
  self.FavoritePet = _FavoritePet
end

function FriendModuleData:GetFavoritePet()
  return self.FavoritePet
end

function FriendModuleData:SetCardFavoriteData(_CardFavoritePet)
  self.CardFavoritePet = _CardFavoritePet
end

function FriendModuleData:GetCardFavoriteData()
  return self.CardFavoritePet
end

function FriendModuleData:SetDefaultSkinId(_DefaultSkinId)
  self.DefaultSkinId = _DefaultSkinId
  if not _DefaultSkinId or 0 == _DefaultSkinId then
    Log.Error("FriendModuleData:SetDefaultSkinId", "\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140DefaultSkinId is nil or 0")
  end
end

function FriendModuleData:GetDefaultSkinId()
  return self.DefaultSkinId
end

function FriendModuleData:SetDefaultPoseId(_DefaultPoseId)
  self.DefaultPoseId = _DefaultPoseId
end

function FriendModuleData:GetDefaultPoseId()
  return self.DefaultPoseId
end

function FriendModuleData:SetPlayerCardAppearanceInfo(card_skin_selected, fashion_wear_id, pose_selected, pose_frame_id, salon_item_data)
  self.PlayerCardAppearanceInfo.card_skin_selected = card_skin_selected
  self.PlayerCardAppearanceInfo.fashion_wear_id = fashion_wear_id
  self.PlayerCardAppearanceInfo.pose_selected = pose_selected
  self.PlayerCardAppearanceInfo.pose_frame_id = pose_frame_id
  self.PlayerCardAppearanceInfo.salon_item_data = salon_item_data
end

function FriendModuleData:GetPlayerCardAppearanceInfo()
  return self.PlayerCardAppearanceInfo
end

function FriendModuleData:newClientPlayerSettings()
  local setting = {}
  local protoMessage = _G.ProtoMessage
  setting.player_settings = protoMessage:newPlayerSettings()
  setting.cached_friendship = protoMessage:newPlayerSettings()
  return setting
end

function FriendModuleData:SetSelectItem(Index)
  self.ChangeCardIndex = Index
end

function FriendModuleData:GetSelectItem()
  return self.ChangeCardIndex
end

function FriendModuleData:SetCurCardComponentType(_CurCardComponentType)
  self.CurCardComponentType = _CurCardComponentType or _G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET
end

function FriendModuleData:GetCurCardComponentType()
  return self.CurCardComponentType or _G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET
end

function FriendModuleData:GetSaveMultipleChatNum()
  local FriendGlobalConfig = _G.DataConfigManager:GetFriendGlobalConfig("chat_multi_message_storage_num_max")
  if FriendGlobalConfig then
    local num = FriendGlobalConfig.num
    return num or 10
  end
  return 10
end

function FriendModuleData:GetSendMultipleChatCD()
  local FriendGlobalConfig = _G.DataConfigManager:GetFriendGlobalConfig("chat_multi_message_send_CD")
  if FriendGlobalConfig then
    local num = FriendGlobalConfig.num
    return num or 3
  end
  return 3
end

function FriendModuleData:GetLatestUnreadPrivateChatUin()
  local latestUin = 0
  local multiPlayerUin = self.MultiPlayerChannelType
  local lastTimestamp = 0
  if self.ChatSessionList then
    for _, session in ipairs(self.ChatSessionList) do
      local uin = session.basic_info.uin
      if uin ~= multiPlayerUin then
        local UnreadCount = self:GetUnreadPrivateChatMessageCount(uin)
        if UnreadCount > 0 then
          local timestamp = session.basic_info.time_stamp
          if timestamp and lastTimestamp < timestamp then
            lastTimestamp = timestamp
            latestUin = uin
          end
        end
      end
    end
  end
  return latestUin
end

function FriendModuleData:GetUnreadPrivateChatMessageCount(uin)
  local unreadCount = 0
  local redPointModule = _G.NRCModuleManager:GetModule("RedPointModule")
  if redPointModule then
    local rpNodeDic = redPointModule.data:GetRedPointNodeDic()
    if rpNodeDic and rpNodeDic[82] then
      local rpNode = rpNodeDic[82]
      local reason = Enum.RedPointReason.RPR_CHAT_RECV_MSG
      if rpNode.litUpReasonDic and rpNode.litUpReasonDic[reason] then
        local reasonData = rpNode.litUpReasonDic[reason]
        local RedPointUtils = require("NewRoco.Modules.System.RedPoint.RedPointUtils")
        unreadCount = RedPointUtils.GetAdvRedCountInReasonData(reasonData, {
          tostring(uin)
        })
      end
    end
  end
  return unreadCount
end

function FriendModuleData:SetTypingFlag(flag, isShow)
  local oldFlag = self.TypingFlag or 0
  if isShow then
    self.TypingFlag = oldFlag | flag
  else
    self.TypingFlag = oldFlag & ~flag
  end
  return oldFlag ~= self.TypingFlag
end

function FriendModuleData:GetTypingFlag()
  return self.TypingFlag or 0
end

function FriendModuleData:ShouldShowTyping()
  return (self.TypingFlag or 0) > 0
end

return FriendModuleData

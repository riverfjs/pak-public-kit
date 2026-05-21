local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Friend_C = _G.NRCPanelBase:Extend("UMG_Friend_C")

function UMG_Friend_C:OnConstruct()
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_FRIEND)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_FRIEND)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self:SetChildViews(self.Tab_1, self.Tab_2, self.Tab_3, self.Tab_5)
  self.FriendTabList = {
    self.Tab_1,
    self.Tab_2,
    self.Tab_3,
    self.Tab_5
  }
  self.data = self.module:GetData("FriendModuleData")
  self.Timer = 0
  self.SearchInfo = nil
  self.FriendApplyForList = nil
  self.CheckTimeoutDelayId = nil
  self.initRecommendFriendTab = false
  self.friendTypeToLastRefreshTimeDic = {}
  local minRefreshCfg = _G.DataConfigManager:GetGlobalConfig("friendlist_auto_refresh_cd")
  self.minFriendListRefreshIntervalSec = minRefreshCfg and minRefreshCfg.num or 1000
  self.data:SetRecommendRefreshCount(0)
  self:SetFriendListBatchState(false)
  self.LastPlayRecommendPageInTime = 0
  self.data:ClearHomeInfoReqMsTimeCache()
  self.data:ClearFriendExtInfoList()
  self:OnAddEventListener()
  self:BindInputAction()
  self:SetCommonTitle()
  if self.UpperLimit then
    self.UpperLimit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_C:OnDestruct()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_FRIEND)
  self:OnRemoveEventListener()
  if self.CheckTimeoutDelayId then
    _G.DelayManager:CancelDelayById(self.CheckTimeoutDelayId)
    self.CheckTimeoutDelayId = nil
  end
  if self.QQInviteTimeoutDelayId then
    _G.DelayManager:CancelDelayById(self.QQInviteTimeoutDelayId)
    self.QQInviteTimeoutDelayId = nil
  end
  self:CancelDelay()
  if self.data then
    self.data:ClearQQArkJsonCache()
    self.data:ClearRecommendFilter()
  end
end

function UMG_Friend_C:BindInputAction()
  local mappingContext
  if self:GetPanelName() == "Friend" then
    mappingContext = self:AddInputMappingContext("IMC_FriendUI")
    if mappingContext then
      mappingContext:BindAction("IA_CloseFriendUI", self, "OnPcClose")
      mappingContext:BindAction("IA_CloseFriendQuick", self, "OnPcClose")
    end
  else
    mappingContext = self:AddInputMappingContext("IMC_FriendUI_1")
    if mappingContext then
      mappingContext:BindAction("IA_CloseFriendUI_1", self, "OnPcClose_1")
      mappingContext:BindAction("IA_CloseFriendQuick_1", self, "OnPcClose_1")
    end
  end
end

function UMG_Friend_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnCloseBtn()
end

function UMG_Friend_C:OnPcClose_1()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnCloseBtn()
end

function UMG_Friend_C:SetTabInfo()
  local loginChannelType = self.data:GetLoginChannelType()
  self.Tab_1:SetPath(FriendEnum.FriendTab.GameFriend, loginChannelType)
  self.Tab_2:SetPath(FriendEnum.FriendTab.PlatformFriend, loginChannelType)
  self.Tab_3:SetPath(FriendEnum.FriendTab.WeGameFriend, loginChannelType)
  self.Tab_5:SetPath(FriendEnum.FriendTab.SearchFriend, loginChannelType)
  if loginChannelType ~= Enum.CliLoginChannel.CLC_QQ and loginChannelType ~= Enum.CliLoginChannel.CLC_WX then
    self.Tab_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Tab_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local bWeGameTabBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_WEGAME_FRIEND, false)
    if RocoEnv.PLATFORM_WINDOWS and _G.NRCSDKManager:CouldQueryWeGameFriend() and not bWeGameTabBan then
      self.Tab_3:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Tab_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Tab_2:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  for _, tab in ipairs(self.FriendTabList) do
    tab:SetCallbacks(self.GetCurrentSelectedTabCallback, self.SetCurrentSelectedTabCallback, self)
  end
end

function UMG_Friend_C:GetCurrentSelectedTabCallback()
  return _G.NRCModuleManager:DoCmd(FriendModuleCmd.GetSelectFriendTab)
end

function UMG_Friend_C:SetCurrentSelectedTabCallback(tabIndex)
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.SelectFriendTabIndex, tabIndex)
end

function UMG_Friend_C:EnterChatUIPCMode(bEnter)
  if UE4.UNRCPlatformGameInstance.GetInstance():IsPCMode() then
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      local playerController = player:GetUEController()
      playerController:ToggleCursor(bEnter)
      player.inputComponent:SetInputEnable(self, not bEnter)
    end
  end
end

function UMG_Friend_C:OnActive()
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_CLOSE_FRIEND)
  self:SetPanelInfo()
  self:InitializeInfo()
  self:PlayAnimation(self.In)
  self.Btn_FriendRequest:SetRedDotKey(73)
  self.Tab_1.RedDot:SetupKey(73)
  self.Tab_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.Btn2 then
    self.Btn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.CloseBtn:SetStyle(1)
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  if self.CheckTimeoutDelayId then
    _G.DelayManager:CancelDelayById(self.CheckTimeoutDelayId)
    self.CheckTimeoutDelayId = nil
  end
  self.CheckTimeoutDelayId = _G.DelayManager:DelaySeconds(1.0, self.CheckTimeoutForFriendDataUpdate, self)
  if self.FriendChat then
    self.FriendChat:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.AccessAuthority then
    self.AccessAuthority:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_C:SetPanelBaseInfo(ESlateVisibility)
  Log.Debug("UMG_Friend_C:SetPanelBaseInfo ", self.data:GetEntrance(), self:GetPanelName())
  if self.data:GetEntrance() == FriendEnum.OpenFriendEntrance.Chat and self:GetPanelName() == "FriendChat" then
    self.Tab_1:SetVisibility(ESlateVisibility)
    self.Tab_5:SetVisibility(ESlateVisibility)
    local FriendList = self.data:GetFriendList()
    if self.FriendChat then
      self.FriendChat:SetVisibility(ESlateVisibility)
    end
    self.Blacklist:SetVisibility(ESlateVisibility)
    self.Capture:SetVisibility(ESlateVisibility)
    self.NRCSwitcher_Btn:SetVisibility(ESlateVisibility)
  end
end

function UMG_Friend_C:CheckTimeoutForFriendDataUpdate()
  local CurItemType = self:GetFriendTabSelectIndex()
  Log.Debug("UMG_Friend_C:CheckTimeoutForFriendDataUpdate ", CurItemType)
  if CurItemType == FriendEnum.FriendTab.GameFriend then
    Log.Debug("UMG_Friend_C:CheckTimeoutForFriendDataUpdate FriendTab.Friend")
    if self.data:IsWaitingFriendRoleData() then
      self.NRCText_65:SetText(LuaText.friend_mine_interface_empty_text)
      Log.Debug("UMG_Friend_C:CheckTimeoutForFriendDataUpdate timeout and set empty friend")
    end
  end
end

function UMG_Friend_C:GetFriendTabSelectIndex()
  return self.data:GetSelectFriendTabIndex()
end

function UMG_Friend_C:OnFriendDataUpdate()
  local CurItemType = self:GetFriendTabSelectIndex()
  Log.Debug("UMG_Friend_C:OnFriendDataUpdate ", CurItemType)
  if CurItemType == FriendEnum.FriendTab.GameFriend then
    Log.Debug("UMG_Friend_C:OnFriendDataUpdate FriendTab.Friend")
    self:OnClickTabGameFriend()
  elseif CurItemType == FriendEnum.FriendTab.PlatformFriend then
    Log.Debug("UMG_Friend_C:OnFriendDataUpdate FriendTab.PlatformFriend")
    self:OnClickTabPlatformFriend()
  elseif CurItemType == FriendEnum.FriendTab.WeGameFriend then
    Log.Debug("UMG_Friend_C:OnFriendDataUpdate FriendTab.WeGameFriend")
    self:OnClickTabWeGameFriend()
  end
end

function UMG_Friend_C:OnRecommendDataUpdate()
  local CurItemType = self:GetFriendTabSelectIndex()
  Log.Debug("UMG_Friend_C:OnRecommendDataUpdate ", CurItemType)
  if CurItemType == FriendEnum.FriendTab.SearchFriend then
    Log.Debug("UMG_Friend_C:OnRecommendDataUpdate FriendTab.SearchFriend")
    self:OnClickTabSearchRecommendFriend()
  end
end

function UMG_Friend_C:InitializeInfo()
  self:SetTabInfo()
  if self:GetPanelName() == "Friend" then
    self.data:SetSelectFriendTabIndex(FriendEnum.FriendTab.GameFriend)
    self.Tab_1:OnSelect()
  elseif self:GetPanelName() == "FriendChat" then
    self:OnClickTabGameFriend()
  end
  self:UpdateGameFriendListInfo()
  self:PlayGameFriendItemInAnimation()
end

function UMG_Friend_C:SetPanelInfo()
  local Msg = _G.DataConfigManager:GetLocalizationConf("search_UID_initial_text").msg
  self.InputBox_1:SetHintText(Msg)
  local PlayerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  if PlayerPetInfo then
    local catchTimes = PlayerPetInfo.visit_remain_catch_times
    local shinyCatchTimes = PlayerPetInfo.visit_remain_shiny_catch_times or 0
    self.Capture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Capture:InitNum(shinyCatchTimes, nil, LuaText.visit_xuancai_catch_time_text, true, UEPath.Capture, true, "+", true)
  else
    self.Capture:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetComboBox()
  local VisitPermissionType = _G.DataModelMgr.PlayerDataModel:GetVisitPermissionType()
  local Index = self:SetVisitPermissionType(VisitPermissionType)
  self.ComboBox_Popup:SelectListItem(Index)
end

function UMG_Friend_C:SetComboBox()
  local PermissionSettingTypeList = {}
  local Str = _G.DataConfigManager:GetOnlineGlobalConfig(24).str
  local online_limit_order = string.Split(Str, ";")
  if online_limit_order then
    for i, v in pairs(online_limit_order) do
      local Type = ProtoEnum.VisitPermissionSettingType.VPST_JOIN_AFTER_AGREE
      if "online_limit_refuse" == v then
        Type = ProtoEnum.VisitPermissionSettingType.VPST_JOIN_REFUSE
      end
      if "online_limit_agree" == v then
        Type = ProtoEnum.VisitPermissionSettingType.VPST_JOIN_DIRECT
      end
      if Type ~= ProtoEnum.VisitPermissionSettingType.VPST_JOIN_REFUSE then
        table.insert(PermissionSettingTypeList, {
          Type = Type,
          IsSelect = true,
          SelectIndex = self:GetComboBoxSelectIndex(),
          isNotChangColor = true,
          name = _G.DataConfigManager:GetLocalizationConf(v).msg,
          isHideRedDot = true,
          ComType = CommonBtnEnum.ComboBoxType.FriendVisits,
          OnSelectDelegate = function()
            self:HideComboBoxPopup()
          end
        })
      end
    end
  end
  self.ComboBox_Popup:SetListTitle(PermissionSettingTypeList)
end

function UMG_Friend_C:GetComboBoxSelectIndex()
  local CurType = _G.DataModelMgr.PlayerDataModel:GetVisitPermissionType()
  local Str = _G.DataConfigManager:GetOnlineGlobalConfig(24).str
  local SelectIndex
  local online_limit_order = string.Split(Str, ";")
  if online_limit_order then
    for i, v in pairs(online_limit_order) do
      local Type = ProtoEnum.VisitPermissionSettingType.VPST_JOIN_AFTER_AGREE
      if "online_limit_refuse" == v then
        Type = ProtoEnum.VisitPermissionSettingType.VPST_JOIN_REFUSE
      end
      if "online_limit_agree" == v then
        Type = ProtoEnum.VisitPermissionSettingType.VPST_JOIN_DIRECT
      end
      if Type == CurType then
        SelectIndex = i
      end
    end
  end
  return SelectIndex
end

function UMG_Friend_C:SetVisitPermissionType(VisitPermissionType)
  local Index = 0
  if VisitPermissionType == ProtoEnum.VisitPermissionSettingType.VPST_JOIN_DIRECT then
    self.AccessAuthorityText:SetText(LuaText.online_limit_agree)
    Index = 1
  elseif VisitPermissionType == ProtoEnum.VisitPermissionSettingType.VPST_JOIN_AFTER_AGREE then
    self.AccessAuthorityText:SetText(LuaText.online_limit_approval)
    Index = 0
  end
  return Index
end

function UMG_Friend_C:UpdateGameFriendListInfo(resetOffset)
  local curFriendType = self:GetFriendTabSelectIndex()
  if curFriendType ~= FriendEnum.FriendTab.GameFriend then
    Log.WarningFormat("UMG_Friend_C:UpdateGameFriendListInfo should not call, current select friend tab is not GameFriend, curFriendType = %s", tostring(curFriendType))
    return
  end
  local FriendList = self.data:GetFriendListForSpecifiedType(ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME)
  local VisitList = self.data:GetOnlineVisitorList()
  if #FriendList > 0 then
    if self.ItemList_Friend then
      self.ItemList_Friend:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.Empty_1 then
      self.Empty_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if 1 ~= self.Switcher:GetActiveWidgetIndex() then
    end
    if #VisitList > 0 then
      for i = 1, #VisitList do
        for j = 1, #FriendList do
          if VisitList[i].uin == FriendList[j].uin then
            FriendList[j].is_Visit = true
          end
        end
      end
    end
    local friendListCustomData = {}
    friendListCustomData.curTabType = curFriendType
    self.ItemList_Friend:SetCustomData(friendListCustomData)
    local oriScrollOffset = self.ItemList_Friend:GetScrollOffset()
    local UnlockFriendList = {}
    local Entrance = self.data:GetEntrance()
    if Entrance == FriendEnum.OpenFriendEntrance.Chat then
      for i, Friend in ipairs(FriendList) do
        if Friend.is_chat_node_unlock ~= nil and Friend.is_chat_node_unlock then
          table.insert(UnlockFriendList, Friend)
        end
      end
    else
      UnlockFriendList = FriendList
    end
    if 0 == #UnlockFriendList then
      if self.ItemList_Friend then
        self.ItemList_Friend:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.Empty_1 then
        self.Empty_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self:UpdateEmptyText()
      if 0 == self.Switcher:GetActiveWidgetIndex() then
        self:PlayAnimation(self.Page_In)
      end
      return
    end
    self.ItemList_Friend:InitList(UnlockFriendList)
    if not resetOffset then
      self.ItemList_Friend:NRCSetScrollOffset(oriScrollOffset)
    end
  elseif 0 == self.Switcher:GetActiveWidgetIndex() then
    if self.ItemList_Friend then
      self.ItemList_Friend:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.Empty_1 then
      self.Empty_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:UpdateEmptyText()
    self:PlayAnimation(self.Page_In)
  end
end

function UMG_Friend_C:UpdateEmptyText()
  if self.NRCText_1 then
    self.NRCText_1:SetText(LuaText.friend_mine_interface_empty_text)
  end
end

function UMG_Friend_C:UpdateStrangeFriendList(_IsShowSearchFriend)
  local curFriendType = self:GetFriendTabSelectIndex()
  if curFriendType ~= FriendEnum.FriendTab.SearchFriend then
    Log.WarningFormat("UMG_Friend_C:UpdateStrangeFriendList should not call, current select friend tab is not SearchFriend, curFriendType = %s", tostring(curFriendType))
    return
  end
  local friendListCustomData = {}
  friendListCustomData.curTabType = curFriendType
  self.ItemList_Friend_1:SetCustomData(friendListCustomData)
  local StrangerFriendList = {}
  local FriendBlackList = {}
  local FriendList = {}
  if _IsShowSearchFriend then
    local SearChInfo = self.data:GetSearchInfo()
    if SearChInfo then
      SearChInfo.isSearch = true
    end
    table.insert(StrangerFriendList, SearChInfo)
  else
    StrangerFriendList = self.data:GetStrangeFriendList()
    FriendList = self.data:GetFriendList()
    FriendBlackList = self.data:GetFriendBlackList()
    for i = #StrangerFriendList, 1, -1 do
      for j = 1, #FriendList do
        if StrangerFriendList[i] and StrangerFriendList[i].uin == FriendList[j].uin then
          table.remove(StrangerFriendList, i)
          break
        end
      end
    end
    local currentStrangerCount = #StrangerFriendList
    for i = currentStrangerCount, 1, -1 do
      for j = 1, #FriendBlackList do
        if StrangerFriendList[i] and StrangerFriendList[i].uin == FriendBlackList[j].uin then
          table.remove(StrangerFriendList, i)
          break
        end
      end
    end
    self.data:SetSearchText("")
    self.data:SetSearchInfo()
    self.data:SetIsSearchSucceed(false)
  end
  self.ItemList_Friend_1:InitList(StrangerFriendList)
  self:UpdateRecommendEmptyTips(StrangerFriendList)
end

function UMG_Friend_C:UpdateRecommendEmptyTips(strangerList)
  if not self.CanvasPanel_Empty then
    return
  end
  if not strangerList or 0 == #strangerList then
    self.CanvasPanel_Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.NRCTextEmpty then
      self.NRCTextEmpty:SetText(LuaText.filter_rule_none)
    end
  else
    self.CanvasPanel_Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_C:PlayWegameFriendItemInAnimation()
end

function UMG_Friend_C:PlayPlatformFriendItemInAnimation()
  local platformFriendList = self.data:GetFriendListForSpecifiedType(ProtoEnum.FriendType.FRIEND_TYPE_PLAT)
  for i, List in ipairs(platformFriendList) do
    local Item = self.ItemList_Friend_2:GetItemByIndex(i - 1)
    if Item then
      Item:PlayInAnimation()
    end
  end
end

function UMG_Friend_C:PlayAddItemInAnimation()
  local FriendApplyList = self.data:GetStrangeFriendList()
  for i, List in ipairs(FriendApplyList) do
    local Item = self.ItemList_Friend_1:GetItemByIndex(i - 1)
    if Item then
      Item:PlayInAnimation()
    end
  end
end

function UMG_Friend_C:PlayGameFriendItemInAnimation()
  local FriendList = self.data:GetFriendListForSpecifiedType(ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME)
  for i, List in ipairs(FriendList) do
    local Item = self.ItemList_Friend:GetItemByIndex(i - 1)
    if Item then
      Item:PlayInAnimation()
    end
  end
end

function UMG_Friend_C:SetItemsVisitState(VisitInfo)
end

function UMG_Friend_C:SetItemsVisitBtn(Visit_uin)
end

function UMG_Friend_C:GetSwitcherTop()
  return self.Switcher.Slot:GetOffsets().Top
end

function UMG_Friend_C:OnDeactive()
end

function UMG_Friend_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_paste, self.OnClickBtn_paste)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtn)
  self:AddButtonListener(self.Btn_Search.btnLevelUp, self.OnClickSearchBtn)
  self:AddButtonListener(self.Btn_FriendRequest.btnLevelUp, self.OnClickFriendRequest)
  self:AddButtonListener(self.Btn_Blacklist.btnLevelUp, self.OnClickBlackList)
  self:AddButtonListener(self.Btn_Delete, self.OnClickDelete)
  self:AddButtonListener(self.ClearSelectionMask, self.ClearAllSelection)
  self:AddButtonListener(self.CaptureBtn, self.OnClickCapture)
  self:AddButtonListener(self.MaskBtn, self.OnMaskBtn)
  self:AddButtonListener(self.InvitationBtn.btnLevelUp, self.OnClickInvitationBtn)
  self:AddButtonListener(self.Btn_Refresh.btnLevelUp, self.OnClickRefresh)
  self:AddButtonListener(self.Btn_Refresh_GrayState.btnLevelUp, self.OnClickRefresh)
  if self.Btn_BatchManagement then
    self:AddButtonListener(self.Btn_BatchManagement.btnLevelUp, self.OnClickBatchManagement)
  end
  if self.Btn_Cancel then
    self:AddButtonListener(self.Btn_Cancel.btnLevelUp, self.OnCancelBatchManagement)
  end
  if self.Btn_ConfirmDeletion then
    self:AddButtonListener(self.Btn_ConfirmDeletion.btnLevelUp, self.OnConfirmBatchDelete)
  end
  self:AddButtonListener(self.KnowBtn.btnLevelUp, self.OnClickKnowBtn)
  if self.ScreeningBtn then
    self:AddButtonListener(self.ScreeningBtn.btnLevelUp, self.OnClickScreeningBtn)
  end
  self.InputBox_1.OnTextChanged:Add(self, self.SearchTextChanged)
  self.InputBox_1.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  self:RegisterEvent(self, FriendModuleEvent.IsSearchSucceed, self.SearchIsSucceed)
  self:RegisterEvent(self, FriendModuleEvent.FriendConfirmAddFriendUpdate, self.FriendConfirmAddFriendUpdate)
  self:RegisterEvent(self, FriendModuleEvent.AddFriendOrRemoveFriendSucceed, self.FriendConfirmAddFriendUpdate)
  self:RegisterEvent(self, FriendModuleEvent.VisitFail, self.SetItemsVisitBtn)
  self:RegisterEvent(self, FriendModuleEvent.ChangeFriendTab, self.OnChangeFriendTab)
  self:RegisterEvent(self, FriendModuleEvent.UpdateFriendTabInfo, self.OnUpdateFriendTabInfo)
  self:RegisterEvent(self, FriendModuleEvent.SelectFriendByIndex, self.OnSelectFriendByIndex)
  self:RegisterEvent(self, FriendModuleEvent.OnFriendDataUpdate, self.OnFriendDataUpdate)
  self:RegisterEvent(self, FriendModuleEvent.ModifyFriendTopUpdate, self.OnFriendDataUpdate)
  self:RegisterEvent(self, FriendModuleEvent.OnFriendRefreshRecommendSuccess, self.OnRecommendDataUpdate)
  self:RegisterEvent(self, FriendModuleEvent.OnRecommendFilterConfirmed, self.OnRecommendFilterConfirmed)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.VISIT_PERMISSION_CHANGED, self.SetVisitPermissionType)
  self:RegisterEvent(self, FriendModuleEvent.OnWeGameFriendInfoRefresh, self.UpdateWeGameFriendList)
  self:RegisterEvent(self, FriendModuleEvent.OnQQArkClientInviteInfoRsp, self.OnQQArkClientInviteInfoRsp)
end

function UMG_Friend_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, FriendModuleEvent.IsSearchSucceed)
  self:UnRegisterEvent(self, FriendModuleEvent.FriendConfirmAddFriendUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
  self:UnRegisterEvent(self, FriendModuleEvent.VisitFail)
  self:UnRegisterEvent(self, FriendModuleEvent.ChangeFriendTab)
  self:UnRegisterEvent(self, FriendModuleEvent.UpdateFriendTabInfo)
  self:UnRegisterEvent(self, FriendModuleEvent.SelectFriendByIndex)
  self:UnRegisterEvent(self, FriendModuleEvent.OnFriendDataUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.ModifyFriendTopUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.OnFriendRefreshRecommendSuccess)
  self:UnRegisterEvent(self, FriendModuleEvent.OnRecommendFilterConfirmed)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.VISIT_PERMISSION_CHANGED, self.SetVisitPermissionType)
  self:UnRegisterEvent(self, FriendModuleEvent.OnQQArkClientInviteInfoRsp)
end

function UMG_Friend_C:FriendConfirmAddFriendUpdate(_IsUpdateRedDot)
  self:SetPanelInfo()
  self:OnFriendDataUpdate()
  self.ItemList_Friend_1:ClearSelection()
  if not self.data:GetIsSearchSucceed() then
    self:UpdateStrangeFriendList(false)
  else
    self:UpdateStrangeFriendList(true)
  end
  if _IsUpdateRedDot then
    local FriendApplyForList = self.data:GetFriendApplyForList()
    if #FriendApplyForList <= 0 then
      self.Btn_FriendRequest:EraseRedPoint()
    end
  end
end

function UMG_Friend_C:OnTick(delaTime)
  local CurItemType = self:GetFriendTabSelectIndex()
  local friendType
  if CurItemType == FriendEnum.FriendTab.SearchFriend then
    self:UpdateRecommendRefreshBtn()
  elseif CurItemType == FriendEnum.FriendTab.GameFriend then
    friendType = ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME
  elseif CurItemType == FriendEnum.FriendTab.PlatformFriend then
    friendType = ProtoEnum.FriendType.FRIEND_TYPE_PLAT
  elseif CurItemType == FriendEnum.FriendTab.WeGameFriend then
    friendType = ProtoEnum.FriendType.FRIEND_TYPE_WEGAME
  end
  if friendType then
    if self.module:HasPanel("Chat_Main") then
      local lastRefreshTime = self.data:GetLastFriendListAutoRefreshTimeSec(friendType)
      lastRefreshTime = lastRefreshTime + delaTime
      self.data:SetLastFriendListAutoRefreshTimeSec(friendType, lastRefreshTime)
    else
      self:CheckAndRequestFriendListRefresh(friendType)
    end
  end
end

function UMG_Friend_C:CheckAndRequestFriendListRefresh(friendType)
  local lastRefreshTime = self.data:GetLastFriendListAutoRefreshTimeSec(friendType)
  local intervalSec = self.data:GetFriendListRefreshIntervalSec(friendType)
  local curTime = os.msTime() / 1000.0
  if intervalSec <= curTime - lastRefreshTime then
    self.data:SetLastFriendListAutoRefreshTimeSec(friendType, curTime)
    self.data:SetLastChangeTabRefreshTimeSec(friendType, curTime)
    self:DoRequestFriendListStatusForStayInTab(friendType)
  end
end

function UMG_Friend_C:DoRequestFriendListStatusForStayInTab(friendType)
  if friendType == ProtoEnum.FriendType.FRIEND_TYPE_WEGAME then
    _G.NRCSDKManager:GetWeGameFriendsInfo()
    return
  end
  local isMergeData = true
  self.data:RequestFriendRoleInfo(self, self.OnFriendListRefreshRsp, FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault, nil, friendType, _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_REFRESH, isMergeData)
end

function UMG_Friend_C:DoRequestFriendListStatusForChangeTab(friendType)
  local curTime = os.msTime() / 1000.0
  local lastRequestTime = self.data:GetLastChangeTabRefreshTimeSec(friendType)
  if curTime - lastRequestTime < 1 then
    Log.DebugFormat("UMG_Friend_C:DoRequestFriendListStatusForChangeTab friendType:%s request too frequently, lastRequestTime:%s, curTime:%s", tostring(friendType), tostring(lastRequestTime), tostring(curTime))
    return
  end
  self.data:SetLastChangeTabRefreshTimeSec(friendType, curTime)
  self.data:SetLastFriendListAutoRefreshTimeSec(friendType, curTime)
  if friendType == ProtoEnum.FriendType.FRIEND_TYPE_WEGAME then
    _G.NRCSDKManager:GetWeGameFriendsInfo()
    return
  end
  local isMergeData = false
  self.data:RequestFriendRoleInfo(self, self.OnFriendListRefreshRsp, FriendEnum.ClientFriendRoleInfoScene.FriendPanelDefault, nil, friendType, _G.ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_DEFAULT, isMergeData)
end

function UMG_Friend_C:OnFriendListRefreshRsp(friendList, clientFriendScene)
  Log.DebugFormat("UMG_Friend_C:OnFriendListRefreshRsp friendList count:%s, clientFriendScene:%s", tostring(#friendList), tostring(clientFriendScene))
  self.module:DispatchEvent(FriendModuleEvent.OnFriendDataUpdate)
end

function UMG_Friend_C:OnClickFriendRequest()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Plane_ExchangeVisits_C:OnActive")
  self.module:OpenUIFriendRequest()
end

function UMG_Friend_C:OnClickBatchManagement()
  if self.data:GetIsFriendBatchDeleteMode() then
    Log.Error("UMG_Friend_C:OnClickBatchManagement IsFriendBatchMode is true but batch btn is show")
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Friend_C:OnClickBatchManagement")
    self:SetFriendListBatchState(true)
  end
end

function UMG_Friend_C:OnCancelBatchManagement()
  if not self.data:GetIsFriendBatchDeleteMode() then
    Log.Error("UMG_Friend_C:OnCancelBatchManagement IsFriendBatchMode is false but cancel btn is show")
  else
    self:SetFriendListBatchState(false)
  end
end

function UMG_Friend_C:OnConfirmBatchDelete()
  local deleteUinList = self.data:GetFriendBatchDeleteUinList()
  if #deleteUinList <= 0 then
    local Text = LuaText.friend_mass_delete_friend_empty
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  if not self.data:GetIsFriendBatchDeleteMode() then
    Log.Error("UMG_Friend_C:OnConfirmBatchDelete IsFriendBatchMode is false but confirm btn is show")
  else
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    Context:SetTitle(LuaText.TIPS):SetContent(string.safeFormat(LuaText.friend_mass_delete_friend_confirm_text, tostring(#deleteUinList))):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel):SetCloseOnCancel(true):SetCloseOnOK(true):SetCallback(self, self.OnBatchDeleteDialogCallBack):SetClickAnywhereClose(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UMG_Friend_C:OnBatchDeleteDialogCallBack(isOK)
  if not self.data then
    Log.Error("UMG_Friend_C:OnBatchDeleteDialogCallBack self.data is nil")
    return
  end
  if isOK then
    local deleteUinList = self.data:GetFriendBatchDeleteUinList()
    if #deleteUinList > 0 then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnBatchRemoveFriendReq, deleteUinList)
    else
      Log.Error("UMG_Friend_C:OnBatchDeleteDialogCallBack deleteUinList is empty")
    end
    self:SetFriendListBatchState(false)
  end
end

function UMG_Friend_C:OnClickRefresh()
  self:RequestFriendRecommend()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Friend_Item_C:StartFriendVisit")
end

function UMG_Friend_C:RequestFriendRecommend(isResetCount)
  local isSuccess, cdLeft = _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnFriendRefreshRecommendReq, isResetCount)
  if not isSuccess then
    local Text = string.safeFormat(LuaText.friend_recommend_friend_tips, cdLeft)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  end
end

function UMG_Friend_C:OnClickBlackList()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").BLACKLIST
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  self.ItemList_Friend:ClearSelection()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Plane_ExchangeVisits_C:OnActive")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendBlackList)
end

function UMG_Friend_C:OnClickDelete()
  self.InputBox_1:SetText("")
  self.SearchInfo = nil
end

function UMG_Friend_C:ModifyFriendTopUpdate(ModifyUin, IsTop)
end

function UMG_Friend_C:SearchTextChanged()
  self.ItemList_Friend_1:ClearSelection()
  if self._isPinYin then
    return
  end
  local text = self.InputBox_1:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  elseif text and "" == text then
    self.data:SetSearchText("")
  end
  self.NewInput = self.InputBox_1:GetText()
  local MaxCount = _G.DataConfigManager:GetFriendGlobalConfig("friend_search_textnum_max").num
  local MaxContent, CurrentNum = string.GetSubStr(self.NewInput, MaxCount)
  if MaxCount <= CurrentNum then
    self.InputBox_1:SetText(MaxContent)
  end
  if "" == MaxContent then
    self:UpdateStrangeFriendList(false)
    self.NRCSwitcher_91:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_91:SetActiveWidgetIndex(1)
  end
  self.SearchInfo = MaxContent
  _G.NRCAudioManager:PlaySound2DAuto(1086, "UMG_Friend_Item_C:StartFriendVisit")
end

function UMG_Friend_C:OnTextEndTransaction()
  self._isPinYin = false
  self:SearchTextChanged()
end

function UMG_Friend_C:OnClickSearchBtn()
  local InputInfo = self.InputBox_1:GetText()
  if self.data:GetSearchText() == InputInfo then
    self:InputIsValid(InputInfo)
    return
  end
  self.data:SetSearchText(InputInfo)
  self:InputIsValid(InputInfo)
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Friend_Item_C:StartFriendVisit")
end

function UMG_Friend_C:OnSelectFriendByIndex(Index)
  local CurItemType = self:GetFriendTabSelectIndex()
  if CurItemType == FriendEnum.FriendTab.GameFriend and Index then
    if not self.ItemList_Friend:GetSelectedItem() or self.ItemList_Friend:GetSelectedItem().index ~= Index then
      self.ItemList_Friend:SelectItemByIndex(Index - 1)
    end
  elseif CurItemType == FriendEnum.FriendTab.PlatformFriend and Index then
    if not self.ItemList_Friend_2:GetSelectedItem() or self.ItemList_Friend_2:GetSelectedItem().index ~= Index then
      self.ItemList_Friend_2:SelectItemByIndex(Index - 1)
    end
  elseif CurItemType == FriendEnum.FriendTab.SearchFriend and Index and (not self.ItemList_Friend_1:GetSelectedItem() or self.ItemList_Friend_1:GetSelectedItem().index ~= Index) then
    self.ItemList_Friend_1:SelectItemByIndex(Index - 1)
  end
end

function UMG_Friend_C:InputIsValid(InputInfo)
  if 0 == #InputInfo then
    self.data:SetSearchInfo(nil)
    local Text = _G.DataConfigManager:GetLocalizationConf("search_UID_empty_tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return false
  end
  local Input = tonumber(InputInfo)
  if nil == Input or self:isFloat(Input) then
    Input = 0
  end
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.FriendSearchPlayer, Input)
end

function UMG_Friend_C:isFloat(num)
  return num ~= math.floor(num)
end

function UMG_Friend_C:SearchIsSucceed(_IsSucceed)
  if _IsSucceed then
    self:UpdateStrangeFriendList(true)
  else
    self:UpdateStrangeFriendList(false)
  end
end

function UMG_Friend_C:GetChangedOffsetInfo()
  local Index = self.Switcher:GetActiveWidgetIndex()
  local Offset
  if Index == FriendEnum.SELECT_TAB.AddFriend then
    Offset = self.UMG_Friend_Itme.Slot:GetPosition()
    return Offset.Y, FriendEnum.SELECT_TAB.AddFriend
  else
    return self.ItemList_Friend:GetScrollOffset(), FriendEnum.SELECT_TAB.FriendList
  end
end

function UMG_Friend_C:OnChangeFriendTab(FriendTab)
  if self.TabSelect then
    _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_Friend_C:OnClickTab_1")
  else
    self.TabSelect = true
  end
  local CurItemType = self:GetFriendTabSelectIndex()
  for i, Friend in ipairs(self.FriendTabList) do
    Friend:RemoveSelected(CurItemType)
  end
  if FriendTab == FriendEnum.FriendTab.SearchFriend then
    if not self.initRecommendFriendTab then
      self.initRecommendFriendTab = true
      self.data:SetRecommendRefreshCount(0)
      self.data:SetLastMsTimeRecommendRefresh(0)
      self.data:SetStrangeFriendList(nil)
      self:RequestFriendRecommend()
    end
  elseif FriendTab == FriendEnum.FriendTab.GameFriend then
    self:DoRequestFriendListStatusForChangeTab(ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME)
  elseif FriendTab == FriendEnum.FriendTab.PlatformFriend then
    self:DoRequestFriendListStatusForChangeTab(ProtoEnum.FriendType.FRIEND_TYPE_PLAT)
  elseif FriendTab == FriendEnum.FriendTab.WeGameFriend then
    self:DoRequestFriendListStatusForChangeTab(ProtoEnum.FriendType.FRIEND_TYPE_WEGAME)
  end
  self.data:SetSelectFriendTabIndex(FriendTab)
  self:SetFriendListBatchState(false)
  self:OnUpdateFriendTabInfo()
  self:PlayAnimation(self.Change)
end

function UMG_Friend_C:OnUpdateFriendTabInfo()
  local CurItemType = self:GetFriendTabSelectIndex()
  Log.Debug(CurItemType, "UMG_Friend_C:SelectTaskTabInfo")
  if CurItemType == FriendEnum.FriendTab.GameFriend then
    self:OnClickTabGameFriend()
  elseif CurItemType == FriendEnum.FriendTab.PlatformFriend then
    self:OnClickTabPlatformFriend()
  elseif CurItemType == FriendEnum.FriendTab.SearchFriend then
    self:OnClickTabSearchRecommendFriend()
  elseif CurItemType == FriendEnum.FriendTab.WeGameFriend then
    self:OnClickWeGameFriend()
  end
end

function UMG_Friend_C:SetCommonTitle()
  local Panel = "Friend"
  self.titleConf = _G.DataConfigManager:GetTitleConf(Panel)
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Friend_C:OnClickTabGameFriend()
  self.ItemList_Friend_1:ClearSelection()
  self.ItemList_Friend_2:ClearSelection()
  if self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
  local FriendList = self.data:GetFriendListForSpecifiedType(ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME)
  local maxGameFriendNum = self.data:GetMaxNumOfGameFriend()
  self.NRCText_65:SetText(LuaText.friend_mine_interface_empty_text)
  self.Switcher:SetActiveWidgetIndex(0)
  self:UpdateGameFriendListInfo()
  self:SetPanelBaseInfo(UE4.ESlateVisibility.Collapsed)
  self:UpdateInviteBtn()
  self:UpdateKnownBtn()
end

function UMG_Friend_C:UpdateInviteBtn()
  local CurItemType = self:GetFriendTabSelectIndex()
  local isPlatFormFriendTab = CurItemType == FriendEnum.FriendTab.PlatformFriend
  if not (self:GetPanelName() ~= "FriendChat" and isPlatFormFriendTab) or _G.UE4Helper.IsPCMode() then
    self.InviteBtnRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local inviteStr
  local loginChannelType = self.data:GetLoginChannelType()
  local isHideQQInvite = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_QQ_FRIEND_INVITE, false)
  local isHideWXInvite = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_WX_FRIEND_INVITE, false)
  if loginChannelType == Enum.CliLoginChannel.CLC_QQ and isHideQQInvite then
    self.InviteBtnRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if loginChannelType == Enum.CliLoginChannel.CLC_WX and isHideWXInvite then
    self.InviteBtnRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if CurItemType ~= FriendEnum.FriendTab.WeGameFriend then
    if loginChannelType == Enum.CliLoginChannel.CLC_QQ then
      inviteStr = LuaText.Invite_Friend_Limit4
    elseif loginChannelType == Enum.CliLoginChannel.CLC_WX then
      inviteStr = LuaText.Invite_Friend_Limit3
    end
  end
  if inviteStr then
    self.InviteBtnRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.InvitationBtn:SetBtnText(inviteStr)
  else
    self.InviteBtnRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_C:OnClickInvitationBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_Friend_C:OnClickInvitationBtn")
  local loginChannelType = self.data:GetLoginChannelType()
  if loginChannelType == Enum.CliLoginChannel.CLC_QQ then
    if self:CheckIsSelectBtn() then
      Log.Debug("UMG_Friend_C:OnClickInvitationBtn IsSelectBtn is true")
      return
    end
    local arkJson = self.data:GetQQArkJsonByInviteType(Enum.QQArkBusinessType.QQ_ARK_BUSINESS_TYPE_CLIENT_INVITE)
    if arkJson and "" ~= arkJson then
      NRCModuleManager:DoCmd(ShareModuleCmd.ShareQQArk, arkJson)
    else
      local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").QQINVITE
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
      if self.QQInviteTimeoutDelayId then
        _G.DelayManager:CancelDelayById(self.QQInviteTimeoutDelayId)
      end
      self.QQInviteTimeoutDelayId = _G.DelayManager:DelaySeconds(1.0, self.OnQQInviteTimeout, self)
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdQQArkGetClientInviteInfoReq)
    end
  elseif loginChannelType == Enum.CliLoginChannel.CLC_WX then
    local title = LuaText.Invite_Friend_Limit1
    local content = LuaText.Invite_Friend_Limit2
    NRCModuleManager:DoCmd(ShareModuleCmd.ShareInviteWechat, title, content)
  else
    Log.ErrorFormat("UMG_Friend_C:OnClickInvitationBtn no invite channel type:{0}", tostring(loginChannelType))
  end
end

function UMG_Friend_C:OnQQInviteTimeout()
  self.QQInviteTimeoutDelayId = nil
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").QQINVITE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  Log.Warning("UMG_Friend_C:OnQQInviteTimeout QQArk request timeout")
end

function UMG_Friend_C:OnQQArkClientInviteInfoRsp()
  if self.QQInviteTimeoutDelayId then
    _G.DelayManager:CancelDelayById(self.QQInviteTimeoutDelayId)
    self.QQInviteTimeoutDelayId = nil
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").QQINVITE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  local curFriendType = self:GetFriendTabSelectIndex()
  if curFriendType ~= FriendEnum.FriendTab.PlatformFriend then
    Log.DebugFormat("UMG_Friend_C:OnQQArkClientInviteInfoRsp current tab is not PlatformFriend, curFriendType=%s", tostring(curFriendType))
    return
  end
  local arkJson = self.data:GetQQArkJsonByInviteType(Enum.QQArkBusinessType.QQ_ARK_BUSINESS_TYPE_CLIENT_INVITE)
  if arkJson and "" ~= arkJson then
    NRCModuleManager:DoCmd(ShareModuleCmd.ShareQQArk, arkJson)
  else
    Log.Error("UMG_Friend_C:OnQQArkClientInviteInfoRsp arkJson is empty")
  end
end

function UMG_Friend_C:SetFriendListBatchState(_IsBatch)
  self.data:SetIsFriendBatchDeleteMode(_IsBatch)
  self.data:ClearFriendBatchDeleteUinList()
  if _IsBatch then
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
  else
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
  end
  self.NRCSwitcher_Btn:GetActiveWidget():SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnFriendBatchModeUpdate, _IsBatch)
end

function UMG_Friend_C:OnClickTabSearchRecommendFriend()
  local SearchInfo = self.SearchInfo
  self.ItemList_Friend:ClearSelection()
  self.ItemList_Friend_2:ClearSelection()
  if self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
  end
  self.Switcher:SetActiveWidgetIndex(2)
  self:UpdateRecommendRefreshBtn()
  if nil == SearchInfo then
    self.InputBox_1:SetText("")
    self:UpdateStrangeFriendList(false)
  else
    self.InputBox_1:SetText(SearchInfo)
    self:SearchIsSucceed(self.data:GetIsSearchSucceed())
  end
  self:PlayAddItemInAnimation()
  local nowTime = os.msTime() / 1000.0
  if not self.LastPlayRecommendPageInTime or nowTime - self.LastPlayRecommendPageInTime >= 0.5 then
    self.LastPlayRecommendPageInTime = nowTime
    self:PlayAnimation(self.Page_In)
  end
  self:UpdateInviteBtn()
  self:UpdateKnownBtn()
end

function UMG_Friend_C:UpdateRecommendRefreshBtn()
  local isCding = self.data:IsRecommendRefreshInCDing()
  if isCding then
    if self.Btn_Refresh then
      self.Btn_Refresh:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.Btn_Refresh_GrayState then
      self.Btn_Refresh_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    if self.Btn_Refresh then
      self.Btn_Refresh:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.Btn_Refresh_GrayState then
      self.Btn_Refresh_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:UpdateScreeningBtnVisibility()
end

function UMG_Friend_C:UpdateScreeningBtnVisibility()
  if self.ScreeningBtn then
    local CurItemType = self:GetFriendTabSelectIndex()
    if CurItemType == FriendEnum.FriendTab.SearchFriend then
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      local path
      if self.data:HasRecommendFilter() then
        path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen3_png.img_Screen3_png'"
      else
        path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
      end
      self.ScreeningBtn:SetPath(path, path, path)
    else
      self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Friend_C:OnClickScreeningBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Friend_C:OnClickScreeningBtn")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendRecommendFilter)
end

function UMG_Friend_C:OnRecommendFilterConfirmed()
  self:RequestFriendRecommend(true)
end

function UMG_Friend_C:OnClickWeGameFriend()
  self.ItemList_Friend:ClearSelection()
  self.ItemList_Friend_1:ClearSelection()
  if self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[4] then
    self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
  end
  self.Switcher:SetActiveWidgetIndex(1)
  self:UpdateWeGameFriendList()
  self:PlayWegameFriendItemInAnimation()
  self:UpdateInviteBtn()
  self:UpdateKnownBtn()
end

function UMG_Friend_C:OnClickKnowBtn()
  local content = _G.DataConfigManager:GetLocalizationConf("friend_tab_tips1") and _G.DataConfigManager:GetLocalizationConf("friend_tab_tips1").msg or ""
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentTitle = _G.DataConfigManager:GetLocalizationConf("TIPS").msg
  Context:SetTitle(ContentTitle):SetContent(content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Friend_C:UpdateKnownBtn()
  if self:GetFriendTabSelectIndex() == FriendEnum.FriendTab.WeGameFriend then
    self.KnowBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.KnowBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Friend_C:OnClickTabPlatformFriend()
  self.ItemList_Friend:ClearSelection()
  self.ItemList_Friend_1:ClearSelection()
  local loginChannelType = self.data:GetLoginChannelType()
  if loginChannelType == Enum.CliLoginChannel.CLC_QQ then
    self.Title1:SetSubtitle(LuaText.friend_tab_tips2)
  elseif loginChannelType == Enum.CliLoginChannel.CLC_WX then
    self.Title1:SetSubtitle(LuaText.friend_tab_tips3)
  end
  self.Switcher:SetActiveWidgetIndex(1)
  self:UpdatePlatformFriendList()
  self:UpdateInviteBtn()
  self:UpdateKnownBtn()
end

function UMG_Friend_C:UpdateWeGameFriendList()
  local curFriendType = self:GetFriendTabSelectIndex()
  if curFriendType ~= FriendEnum.FriendTab.WeGameFriend then
    return
  end
  local friendListCustomData = {}
  friendListCustomData.curTabType = curFriendType
  self.ItemList_Friend_2:SetCustomData(friendListCustomData)
  local weGameFriendList = self.data:GetWeGameFriendList()
  self.ItemList_Friend_2:InitList(weGameFriendList)
  if weGameFriendList and table.len(weGameFriendList) > 0 then
    self.ItemList_Friend_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ItemList_Friend_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Friend_C:UpdatePlatformFriendList(resetOffset)
  local curFriendType = self:GetFriendTabSelectIndex()
  if curFriendType ~= FriendEnum.FriendTab.PlatformFriend then
    Log.WarningFormat("UMG_Friend_C:UpdatePlatformFriendList should not call, current tab is not platform friend, curFriendType = %s", tostring(curFriendType))
    return
  end
  local friendListCustomData = {}
  friendListCustomData.curTabType = curFriendType
  self.ItemList_Friend_2:SetCustomData(friendListCustomData)
  local platformFriendList = self.data:GetFriendListForSpecifiedType(ProtoEnum.FriendType.FRIEND_TYPE_PLAT)
  local oriScrollOffset = self.ItemList_Friend_2:GetScrollOffset()
  self.ItemList_Friend_2:InitList(platformFriendList)
  if not resetOffset then
    self.ItemList_Friend_2:NRCSetScrollOffset(oriScrollOffset)
  end
  if platformFriendList and #platformFriendList > 0 then
    self.ItemList_Friend_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ItemList_Friend_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Friend_C:OnAnimationFinished(anim)
  if anim == self.Out then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").CLOSE
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
    self:DoClose()
  end
end

function UMG_Friend_C:OnClickBtn_paste()
  local Text = UE4.UNRCStatics.ClipboardPaste()
  self.SearchInfo = Text
  self.InputBox_1:SetText(Text)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Plane_ExchangeVisits_C:OnActive")
end

function UMG_Friend_C:OnCloseBtn()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").CLOSE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  local mappingContext
  if "Friend" == self:GetPanelName() then
    mappingContext = self:GetInputMappingContext("IMC_FriendUI")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseFriendUI")
      mappingContext:UnBindAction("IA_CloseFriendQuick")
    end
  else
    mappingContext = self:GetInputMappingContext("IMC_FriendUI_1")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseFriendUI_1")
      mappingContext:UnBindAction("IA_CloseFriendQuick_1")
    end
  end
  self.data:SetSearchText("")
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Friend_C:OnCloseBtn")
  self:PlayAnimation(self.Out)
  UE4Helper.SetEnableWorldRendering(true, false)
end

function UMG_Friend_C:CardCloseFriend()
  self.data:SetSearchText("")
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Plane_ExchangeVisits_C:OnActive")
  self:DoClose()
end

function UMG_Friend_C:HideComboBoxPopup()
  if self.ComboBox_Popup then
    self.ComboBox_Popup:PlayAnimationInfo(false)
  end
  if self.NRCImage_134 then
    self.NRCImage_134:SetRenderTransformAngle(0)
  end
  self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Friend_C:OnAccessAuthorityBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ComboBox_C:OnSortingBtnClicked")
  if self.ComboBox_Popup:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    if self.ComboBox_Popup then
      self.ComboBox_Popup:PlayAnimationInfo(false)
    end
    if self.NRCImage_134 then
      self.NRCImage_134:SetRenderTransformAngle(0)
    end
    self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if self.ComboBox_Popup then
      self.ComboBox_Popup:PlayAnimationInfo(true)
    end
    if self.NRCImage_134 then
      self.NRCImage_134:SetRenderTransformAngle(180)
    end
    self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Friend_C:OnMaskBtn()
  self.MaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:OnAccessAuthorityBtnClick()
end

function UMG_Friend_C:OnClickCapture()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").VISIT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Friend_Item_C:StartFriendVisit")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriend_CaptureTips)
end

function UMG_Friend_C:ClearAllSelection()
  self.ItemList_Friend:ClearSelection()
  self.ItemList_Friend_1:ClearSelection()
  self.ItemList_Friend_2:ClearSelection()
end

function UMG_Friend_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "FriendModule", "Friend")
end

function UMG_Friend_C:OnOpenChatPanel()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHAT, true)
  if isBan then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_Friend_C:OpenChatPanel")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanelByFriendPanel, 0)
end

function UMG_Friend_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "FriendModule", "Friend")
end

function UMG_Friend_C:DoClose()
  self.CloseBtn:SetKeyboardFocus()
  _G.NRCPanelBase.DoClose(self)
end

return UMG_Friend_C

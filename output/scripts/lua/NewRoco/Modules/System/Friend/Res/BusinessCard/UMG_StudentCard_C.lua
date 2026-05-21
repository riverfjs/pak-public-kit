local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local PhotoDisplayProxy = require("NewRoco.Modules.System.TakePhotos.Common.PhotoDisplayProxy")
local PhotoDisplayUtils = require("NewRoco.Modules.System.TakePhotos.Common.PhotoDisplayUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local EditComponentItemData = require("NewRoco.Modules.System.Friend.EditComponentItemData")
local UIUtils = require("NewRoco.Utils.UIUtils")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local UMG_StudentCard_C = _G.NRCPanelBase:Extend("UMG_StudentCard_C")

local function CheckIsGameCenterStartup(startupChannel, startupDay)
  if startupChannel == Enum.CliStartUpChannel.CSUC_WX_GAME_CENTER then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_WX_VIP, false)
    if isBan then
      return false
    end
    local svrTimeStamp = (_G.ZoneServer:GetServerTime() or 0) / 1000
    if startupDay and startupDay <= svrTimeStamp and svrTimeStamp - startupDay <= 86400 then
      return true
    end
  end
  return false
end

function UMG_StudentCard_C:OnConstruct()
  if self.UMG_CardImage then
    self.UMG_CardImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.CardPhotoDisplayProxy = PhotoDisplayProxy(self, nil, PhotoDisplayUtils.PhotoCacheDefine.Tags.CardPhotos)
  self.CardPhotoDisplayProxy.OnReadyDelegate:Add(self, self.OnInitCardPhoto)
  self.data = self.module:GetData("FriendModuleData")
  self.BaseData = {}
  self.IsFrontPanel = true
  self.FriendInfo = nil
  self.CardInfo = nil
  self.PlayerInfo = nil
  self.Lock = false
  self.IsPhotograph = nil
  self.OpenedByCompass = false
  self.LoadSucceed = false
  self.CardEnterType = FriendEnum.AdminFriendType.Own
  self.IsFirstOpen = true
  self.data:SetCurCardComponentType(_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET)
  self:SetBtnCloseTabState(true)
  self.ScrollPageController:SetPageChangeHandler(self.OnPageChangeHandle, self)
  self.ScrollPageController.clickAreaWidthScale = 0.9
  self.ScrollPageController.clickAreaHeightScale = 0.9
  self.data:SetItemNumPerPageForCardComponent(self.ScrollPageController:GetItemNumPerPage())
  if self.PanelBg then
    self.PanelBg:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self:CheckShareIsOpen()
  if self.SizeBox_3 then
    self.SizeBox_3:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_StudentCard_C:OnDestruct()
  if self.module.StudentCardIsOpenChildPanel then
  else
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_CARD)
  end
  self.data:SetCurCardComponentType(_G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET)
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
end

function UMG_StudentCard_C:InitializePanel(IsPhotograph)
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_CLOSE_IDCARD)
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if self.module.StudentCardIsOpenChildPanel then
    self.module.StudentCardIsOpenChildPanel = false
  else
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_CARD)
  end
  local privilegeInfo
  if AdminFriendType == FriendEnum.AdminFriendType.Others then
    self.CardEnterType = AdminFriendType
    self.CardInfo = self.data:GetPlayerCardBriefInfo() and self.data:GetPlayerCardBriefInfo().player_card_brief_info
    self.WidgetSwitcher_0:SetActiveWidgetIndex(0)
    local PlayerCardBriefInfo = self.data:GetPlayerCardBriefInfo()
    if PlayerCardBriefInfo.player_card_brief_info and PlayerCardBriefInfo.player_card_brief_info.card_music_id then
      local musicConf = _G.DataConfigManager:GetMusicConf(PlayerCardBriefInfo.player_card_brief_info.card_music_id)
      if musicConf then
        local StateGroup
        if musicConf.music_type == Enum.MusicType.MT_WEBGAME then
          StateGroup = "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Web;" .. musicConf.StateGroup_State
        elseif musicConf.music_type == Enum.MusicType.MT_MOBILE then
          StateGroup = "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Mobile;" .. musicConf.StateGroup_State
        end
        if StateGroup then
          _G.NRCAudioManager:BatchSetState(StateGroup)
        end
      end
    end
    privilegeInfo = PlayerCardBriefInfo and PlayerCardBriefInfo.start_up_privilege_info
  else
    local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_CARD)
    if StateGroup then
      _G.NRCAudioManager:BatchSetState(StateGroup)
    end
    local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
    self.PlayerInfo = PlayerInfo
    self.CardInfo = self.PlayerInfo.additional_data.card_brief_info
    Log.Dump(self.CardInfo, 6, "UMG_StudentCard_C:OnActive")
    self.WidgetSwitcher_0:SetActiveWidgetIndex(1)
    privilegeInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPrivilegeData()
  end
  if self.SizeBox_3 then
    if privilegeInfo and CheckIsGameCenterStartup(privilegeInfo.cli_startup_channel, privilegeInfo.cli_startup_day) then
      self.SizeBox_3:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.SizeBox_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:SetBaseData()
  self:SetPanelInfo()
  self.IsPhotograph = IsPhotograph
  if 1 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:DelaySeconds(2, function()
      self:OverturnCardPanel()
    end)
  end
  _G.NRCAudioManager:PlaySound2DAuto(40006003, "UMG_StudentCard_C:OnActive")
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ReleaseAimState)
  self:BindInputAction()
end

function UMG_StudentCard_C:OnDataModifiedAndRefreshUI()
  self:SetBaseData()
  self:SetPanelInfo()
end

function UMG_StudentCard_C:OnActive(_Param, RT_capture, IsPhotograph)
  self:InitializePanel(self.module.IsPhotograph)
  NRCProfilerLog:NRCPanelRequireRes(true, self.panelName)
  self:InitMenuComboBoxPopup()
  self:InitCardInteractionEntryList()
  self:ShowPlayerOperationComboBox(self.ComboBox_Popup_1, false)
  self:ShowPlayerOperationComboBox(self.ComboBox_Popup_2, false)
  self:OnAddEventListener()
  self:StartPlayAnimation()
  self:UpdatePrivilegeCardUI()
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    Module:RegisterEvent(self, TakePhotosModuleEvent.OnBeginCroppingCard, self.OnBeginCroppingCard)
    Module:RegisterEvent(self, TakePhotosModuleEvent.OnStopPhotoCropping, self.OnStopPhotoCropping)
    if self.data:IsToggleToPhotoCropping() then
      self:OnBeginCroppingCard(self.data:GetCroppingPhotoData():GetPhotoTexture2D())
    end
  end
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
end

function UMG_StudentCard_C:OnDeactive()
  self:UnBindInputAction()
  self:OnRemoveEventListener()
  if self.bEditingPhoto then
    self.bEditingPhoto = false
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "UMG_StudentCard_C.OnReqEnterPhotoEdit")
  end
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnBeginCroppingCard)
    Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnStopPhotoCropping)
    if self.bNeedRecoverPhotoPopup then
      NRCModuleManager:GetModule("TakePhotosModule"):EnablePanel("PhotoHistoryUI")
      NRCModuleManager:GetModule("TakePhotosModule"):EnablePanel("PhotoFileViewUI")
    end
  end
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
end

function UMG_StudentCard_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MenuClose")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseMenu")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_StudentCard_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseMenu")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MenuClose")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_StudentCard_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:CloseStudentCardPanel()
end

function UMG_StudentCard_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseStudentCardPanel, self.CloseStudentCardPanel)
  self:AddButtonListener(self.Overturn, self.OverturnCardPanel)
  self:AddButtonListener(self.BtnCloseTab, self.OnClickBtnCloseTab)
  self:AddButtonListener(self.ChangeNumber, self.OnChangeNumber)
  self:AddButtonListener(self.ChangeNumber_1, self.OnChangeNumber)
  self:AddButtonListener(self.NRCButton_68, self.OnLeftSlide)
  self:AddButtonListener(self.NRCButton, self.OnRightSlide)
  self:AddButtonListener(self.LButton, self.OnPreviousPage)
  self:AddButtonListener(self.RButton, self.OnNextPage)
  self:AddButtonListener(self.MoreBtn, self.OnFrontPlayerOperationMoreBtnClick)
  self:AddButtonListener(self.MoreBtn2, self.OnReverseSidePlayerOperationMoreBtnClick)
  self:AddButtonListener(self.QQBtn, self.ClickQQPrivilegeCard)
  self:AddButtonListener(self.WeiXinBtn, self.ClickWechatPrivilegeCard)
  if self.MenuBtn and self.MenuBtn.btnLevelUp then
    self:AddButtonListener(self.MenuBtn.btnLevelUp, self.OnBtnMenuClick)
    self.MenuBtn:SetRedDot(42)
  end
  if self.ShareBtn and self.ShareBtn.btnLevelUp then
    self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnBtnShareClick)
  end
  self:RegisterEvent(self, FriendModuleEvent.ModifyPlayerNameUpdate, self.OnModifyPlayerRemarkUpdate)
  self:RegisterEvent(self, FriendModuleEvent.ModifyPlayerSignatureUpdate, self.OnModifyPlayerSignatureUpdate)
  self:RegisterEvent(self, FriendModuleEvent.SetChooseAvatar, self.OnModifyAvatarUpdate)
  self:RegisterEvent(self, FriendModuleEvent.SetChooseCardBGPath, self.OnModifyCardBGUpdate)
  self:RegisterEvent(self, FriendModuleEvent.SetLabelText, self.OnModifyLabelText)
  self:RegisterEvent(self, FriendModuleEvent.SetFavoritePetEvent, self.OnSetFavoritePetEvent)
  self:RegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.OnModifyFriendRemarkUpdate)
  self:RegisterEvent(self, FriendModuleEvent.UpdateCardComponentEdit, self.OnUpdateCardComponentEdit)
  self:RegisterEvent(self, FriendModuleEvent.OnSetPlayerCardCollectPetSuccess, self.OnSetPlayerCardCollectPetSuccess)
  _G.NRCEventCenter:RegisterEvent("UMG_StudentCard_C", self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("UMG_StudentCard_C", self, FriendModuleEvent.OnCardMenuSelect, self.SelectCardMenu)
  self:AddButtonListener(self.UploadBtn, self.OnClickUploadPhoto)
  _G.NRCEventCenter:RegisterEvent("UMG_StudentCard_C", self, FriendModuleEvent.OnCardPlayerOperationSelect, self.OnCardPlayerOperationSelect)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self:RegisterEvent(self, FriendModuleEvent.AddFriendOrRemoveFriendSucceed, self.OnFriendRelationChanged)
  self:RegisterEvent(self, FriendModuleEvent.AddOrRemoveBlackListUpdate, self.OnBlackListChanged)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.ON_CARD_INFO_CHANGED, self.OnCardInfoChanged)
end

function UMG_StudentCard_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, FriendModuleEvent.ModifyPlayerNameUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.ModifyPlayerSignatureUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.SetChooseAvatar)
  self:UnRegisterEvent(self, FriendModuleEvent.SetChooseCardBGPath)
  self:UnRegisterEvent(self, FriendModuleEvent.SetLabelText)
  self:UnRegisterEvent(self, FriendModuleEvent.SetFavoritePetEvent)
  self:UnRegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate)
  self:UnRegisterEvent(self, FriendModuleEvent.UpdateCardComponentEdit)
  self:UnRegisterEvent(self, FriendModuleEvent.OnSetPlayerCardCollectPetSuccess)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnCardMenuSelect, self.SelectCardMenu)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnCardPlayerOperationSelect, self.OnCardPlayerOperationSelect)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self:UnRegisterEvent(self, FriendModuleEvent.AddFriendOrRemoveFriendSucceed)
  self:UnRegisterEvent(self, FriendModuleEvent.AddOrRemoveBlackListUpdate)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.ON_CARD_INFO_CHANGED, self.OnCardInfoChanged)
end

function UMG_StudentCard_C:OnEnterSceneFinishNtyAck()
  self:CloseStudentCardPanel(true)
end

function UMG_StudentCard_C:OnFriendRelationChanged()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if AdminFriendType ~= FriendEnum.AdminFriendType.Others then
    return
  end
  local playerCardBriefInfo = self.data:GetPlayerCardBriefInfo()
  if not playerCardBriefInfo then
    return
  end
  local CardFriendInfo = self.data:GetCardFriendInfo()
  if not CardFriendInfo then
    return
  end
  playerCardBriefInfo.is_friend = _G.DataModelMgr.PlayerDataModel:IsFriend(CardFriendInfo.uin)
  self:OnDataModifiedAndRefreshUI()
end

function UMG_StudentCard_C:OnBlackListChanged()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if AdminFriendType ~= FriendEnum.AdminFriendType.Others then
    return
  end
  local playerCardBriefInfo = self.data:GetPlayerCardBriefInfo()
  if not playerCardBriefInfo then
    return
  end
  local CardFriendInfo = self.data:GetCardFriendInfo()
  if not CardFriendInfo then
    return
  end
  playerCardBriefInfo.is_black_role = _G.DataModelMgr.PlayerDataModel:CheckHasBlackByPlayerUin(CardFriendInfo.uin)
  self:OnDataModifiedAndRefreshUI()
end

function UMG_StudentCard_C:OnUpdateCardComponentEdit(scrollPageIndex)
  self:SetCardFavoriteList(scrollPageIndex)
  local isEditing = self.data:GetIsEditingComponent()
  if isEditing then
    UIUtils.SafeSetVisibility(self.Overturn, UE4.ESlateVisibility.Collapsed)
  else
    UIUtils.SafeSetVisibility(self.Overturn, UE4.ESlateVisibility.Visible)
  end
  if self.BaseData.isSelf or self.BaseData.isFriend then
    UIUtils.SafeSetVisibility(self.ChangeNumber, UE4.ESlateVisibility.Visible)
    UIUtils.SafeSetVisibility(self.ChangeNumber_1, UE4.ESlateVisibility.Visible)
  else
    UIUtils.SafeSetVisibility(self.ChangeNumber, UE4.ESlateVisibility.Collapsed)
    UIUtils.SafeSetVisibility(self.ChangeNumber_1, UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateMenuBtn()
end

function UMG_StudentCard_C:IsLoadSucceed()
  if not self.LoadSucceed then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_StudentCard_C:StartPlayAnimation()
  self.LoadSucceed = true
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  NRCProfilerLog:NRCPanelRequireRes(false, self.panelName)
  if self.IsPhotograph then
    self:SetLock(true)
    self:PlayAnimation(self.Pick_in)
  else
    self:SetLock(true)
    self:PlayAnimation(self.In)
  end
end

function UMG_StudentCard_C:GetSelfLoginChannelType()
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local loginChannelType = accountInfo and accountInfo.plat_info and accountInfo.plat_info.cli_login_channel or nil
  return loginChannelType
end

function UMG_StudentCard_C:UpdatePrivilegeCardUI()
  local loginChannelType = self:GetSelfLoginChannelType()
  local IsBan = false
  if loginChannelType == Enum.CliLoginChannel.CLC_WX then
    IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_WX_VIP, false)
  elseif loginChannelType == Enum.CliLoginChannel.CLC_QQ then
    IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_QQ_VIP, false)
  end
  if IsBan then
    self.Switcher1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Switcher1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if playerInfoData then
      Log.Info("UMG_StudentCard_C:UpdatePrivilegeCardUI", tostring(playerInfoData.loginChannelType))
      if playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_WX then
        self.Switcher1:SetActiveWidgetIndex(1)
      elseif playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_QQ then
        self.Switcher1:SetActiveWidgetIndex(0)
      else
        self.Switcher1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.Switcher1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_StudentCard_C:ClickQQPrivilegeCard()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StudentCard_C:ClickQQPrivilegeCard")
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.LobbyMainInnerBottonMoreOpenPanel, "PrivilegeIntroductionPopUp", Enum.CliLoginChannel.CLC_QQ)
end

function UMG_StudentCard_C:ClickWechatPrivilegeCard()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StudentCard_C:ClickWechatPrivilegeCard")
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.LobbyMainInnerBottonMoreOpenPanel, "PrivilegeIntroductionPopUp", Enum.CliLoginChannel.CLC_WX)
end

function UMG_StudentCard_C:SetLock(Lock)
  self.Lock = Lock
end

function UMG_StudentCard_C:SetBaseData()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  local CardSource = self.data:GetCardSource()
  local CardFriendInfo = self.data:GetCardFriendInfo()
  local PlayerCardBriefInfo = self.data:GetPlayerCardBriefInfo()
  local CardSelectTab = self.data:GetCardSelectTab()
  local PlayerCardPhotoUrl = ""
  local PlayerCardPhotoMd5 = ""
  local Name, Level, note, uin, regist_date
  local isFriend = false
  local friendType = ProtoEnum.FriendType.FRIEND_TYPE_NONE
  local isBlack = false
  local isOnline = false
  local openid
  local isSelf = false
  local WorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0
  if AdminFriendType == FriendEnum.AdminFriendType.Others then
    if CardSource == FriendEnum.Source.Scene and CardSelectTab == FriendEnum.SELECT_TAB.FaceToFaceInteraction then
      Name = CardFriendInfo.base.name
      note = PlayerCardBriefInfo.note
      Level = CardFriendInfo.base.lv
      uin = CardFriendInfo.base.logic_id
      regist_date = PlayerCardBriefInfo.register_timestamp
      WorldLevel = CardFriendInfo.attrs.world_level or 0
    else
      Name = CardFriendInfo.name
      note = CardFriendInfo.note
      Level = CardFriendInfo.level
      uin = CardFriendInfo.uin
      openid = CardFriendInfo.openid
      regist_date = CardFriendInfo.regist_date
      WorldLevel = CardFriendInfo.world_level or 0
    end
    local PhotoInfo = PlayerCardBriefInfo and PlayerCardBriefInfo.player_card_brief_info and PlayerCardBriefInfo.player_card_brief_info.business_card_info or {}
    PlayerCardPhotoUrl = PhotoInfo.cur_card_url or ""
    PlayerCardPhotoMd5 = PhotoInfo.cur_card_md5 or ""
    self.Empty:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.UploadBtn1:SetVisibility(UE.ESlateVisibility.Collapsed)
    isFriend = PlayerCardBriefInfo.is_friend
    if isFriend then
      friendType = PlayerCardBriefInfo.friend_type or ProtoEnum.FriendType.FRIEND_TYPE_NONE
    end
    isBlack = PlayerCardBriefInfo.is_black_role
    isOnline = PlayerCardBriefInfo.online
    isSelf = false
  else
    isSelf = true
    Name = self.PlayerInfo.name
    note = self.PlayerInfo.note
    Level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
    uin = self.PlayerInfo.uin
    openid = self.PlayerInfo.openid
    WorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
    regist_date = self.PlayerInfo.register_time
    local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
    local PhotoInfo = CardBriefInfo and CardBriefInfo.business_card_info or {}
    PlayerCardPhotoUrl = PhotoInfo.cur_card_url or ""
    PlayerCardPhotoMd5 = PhotoInfo.cur_card_md5 or ""
    local ban = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CLOUD_BACKGROUND_IMAGE, true)
    ban = ban or _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_BACKGROUND_IMAGE, true)
    if ban then
      PlayerCardPhotoUrl = ""
    end
    if "" == PlayerCardPhotoUrl then
      self.Empty:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Empty:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.data:IsStudentCardForbidEdit() then
      self.UploadBtn1:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    isOnline = true
  end
  self.BaseData.name = Name
  self.BaseData.level = Level
  self.BaseData.WorldLevel = WorldLevel
  self.BaseData.note = note
  self.BaseData.uin = uin
  self.BaseData.regist_date = regist_date
  self.BaseData.CardInfo = self.CardInfo
  self.BaseData.isFriend = isFriend
  self.BaseData.friendType = friendType
  self.BaseData.isBlack = isBlack
  self.BaseData.isOnline = isOnline
  self.BaseData.openid = openid
  self.BaseData.isSelf = isSelf
  Log.Dump(self.BaseData, 4, "UMG_StudentCard_C:SetBaseData")
  self.UploadedPhotoTex = nil
  if "" ~= PlayerCardPhotoUrl and self.CurPlayerCardPhotoUrl ~= PlayerCardPhotoUrl then
    self.CurPlayerCardPhotoUrl = PlayerCardPhotoUrl
    self.CurPlayerCardPhotoMd5 = PlayerCardPhotoMd5
    self:LoadPlayerCardPhoto()
  end
  self.EmptyBg:SetVisibility("" == PlayerCardPhotoUrl and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function UMG_StudentCard_C:SetPanelInfo()
  local PlayerCardBriefInfo = self.data:GetPlayerCardBriefInfo()
  local CardFriendInfo = self.data:GetCardFriendInfo()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if self.BaseData.note and self.BaseData.note ~= "" then
    self:SetPlayerName(self.BaseData.note, true)
  else
    self:SetPlayerName(self.BaseData.name, false)
  end
  if AdminFriendType == FriendEnum.AdminFriendType.Own then
    UIUtils.SafeSetVisibility(self.MoreBtn, UE4.ESlateVisibility.Collapsed)
    UIUtils.SafeSetVisibility(self.MoreBtn2, UE4.ESlateVisibility.Collapsed)
  elseif self.IsFrontPanel then
    UIUtils.SafeSetVisibility(self.MoreBtn, UE4.ESlateVisibility.Visible)
    UIUtils.SafeSetVisibility(self.MoreBtn2, UE4.ESlateVisibility.Collapsed)
  else
    UIUtils.SafeSetVisibility(self.MoreBtn, UE4.ESlateVisibility.Collapsed)
    UIUtils.SafeSetVisibility(self.MoreBtn2, UE4.ESlateVisibility.Visible)
  end
  self.ChangeNumber:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ChangeNumber_1:SetVisibility(UE4.ESlateVisibility.Visible)
  UIUtils.SafeSetVisibility(self.WidgetSwitcher_0, UE4.ESlateVisibility.Collapsed, true)
  UIUtils.SafeSetVisibility(self.Card_Function, UE4.ESlateVisibility.Collapsed, true)
  self.levelText:SetText(self.BaseData.level)
  local starLevelData = {}
  local worldLevel = self.BaseData.WorldLevel or 0
  for i = 1, worldLevel do
    table.insert(starLevelData, {})
  end
  self.StarLevel:InitGridView(starLevelData)
  self:SetPanelReverseSideInfo()
  self:UpdateMenuBtn()
  self:SetLabel()
  self:SetSignature()
end

function UMG_StudentCard_C:UpdateMenuBtn()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if AdminFriendType == FriendEnum.AdminFriendType.Own and not self.data:GetIsEditingComponent() and not self.data:IsStudentCardForbidEdit() then
    self.MenuBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.MenuText:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.ShareIsOpen then
      self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ShareText:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    self.MenuBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.MenuText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_StudentCard_C:SetPanelReverseSideInfo()
  local cardRecordConfs = self.module:GetAllCardAdventureRecordConfs()
  local info = self.data:GetPlayerCardBriefInfo()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if nil ~= cardRecordConfs then
    local recordDatas = {}
    for k, v in pairs(cardRecordConfs) do
      local context = ""
      if v.adventure_record == _G.Enum.AdventureRecord.AR_REGISTRATION_TIME then
        context = os.date("%Y.%m.%d", self.BaseData.regist_date)
      elseif v.adventure_record == _G.Enum.AdventureRecord.AR_FASHION_BOND_NUM then
        if self.CardInfo.card_fashion_bond_collect_num then
          context = self.CardInfo.card_fashion_bond_collect_num
        else
          context = 0
        end
      elseif v.adventure_record == _G.Enum.AdventureRecord.AR_PETHANDBOOK_NUM then
        if self.CardInfo.card_handbook_collect_num then
          context = self.CardInfo.card_handbook_collect_num
        else
          context = 0
        end
      elseif v.adventure_record == _G.Enum.AdventureRecord.AR_COLLECTED_VISUAL_ITEM then
        if AdminFriendType ~= FriendEnum.AdminFriendType.Own and info and info.is_friend then
          context = info.topic_point or 0
        else
          local id = v.record_param
          if id then
            local count = _G.DataModelMgr.PlayerDataModel:GetVItemCount(id) or 0
            context = count
          end
        end
      elseif v.adventure_record == _G.Enum.AdventureRecord.AR_COLLECTED_MUTATION_PET_NUM and self.CardInfo.card_pet_info then
        if v.record_param == _G.Enum.MutationDiffType.MDT_GLASS then
          context = self.CardInfo.card_pet_info.collected_glass_pet_count or 0
        elseif v.record_param == _G.Enum.MutationDiffType.MDT_SHINING then
          context = self.CardInfo.card_pet_info.collected_shining_pet_count or 0
        end
      end
      local data = {
        conf = v,
        context = context,
        isNil = 0
      }
      table.insert(recordDatas, data)
    end
    local nilItemDataCount = 0 == #cardRecordConfs % 3 and 0 or 3 - #cardRecordConfs % 3
    for i = 1, nilItemDataCount do
      table.insert(recordDatas, {isNil = 1})
    end
    table.sort(recordDatas, function(a, b)
      if 0 == a.isNil and a.isNil == b.isNil then
        return a.conf.id < b.conf.id
      else
        return a.isNil < b.isNil
      end
    end)
    if not self.IsFrontPanel then
      self.ScrollPageController2:SetValidItemTotalNum(#recordDatas)
      self.ScrollPageController2:ScrollToPage(0, 0.1)
      self.Record:InitList(recordDatas)
    end
  end
  local starLevelData = {}
  local worldLevel = self.BaseData.WorldLevel or 0
  for i = 1, worldLevel do
    table.insert(starLevelData, {})
  end
  if self.StarLevel_1 then
    self.StarLevel_1:InitGridView(starLevelData)
  end
  self.NRCText_145:SetText(self.BaseData.uin)
  self.NRCText_1:SetText(self.BaseData.uin)
  self:SetPanelTextInfo()
  self.BusinessCard_HeadItem:UpdateHead(self.BaseData, nil, true)
  local CardSkinConf = _G.DataConfigManager:GetCardSkinConf(self:GetSkillId())
  if CardSkinConf then
    local Path = string.format(UEPath.CARD_COMMON_PATH, CardSkinConf.skin_resource_path, "Fram", CardSkinConf.skin_resource_path, "Fram")
    self.PanelBg_3:SetPathWithCallBack(Path, {
      self,
      self.SetShinePetIcon
    })
  end
  self:SetCardSkinUpgradeInfo()
  if not self.IsFrontPanel then
    self:SetCardFavoriteList(0)
  end
  if self.BaseData.isSelf or self.BaseData.isFriend then
    UIUtils.SafeSetVisibility(self.ChangeNumber_1, UE4.ESlateVisibility.Visible)
    UIUtils.SafeSetVisibility(self.ChangeNumber, UE4.ESlateVisibility.Visible)
  else
    UIUtils.SafeSetVisibility(self.ChangeNumber_1, UE4.ESlateVisibility.Collapsed)
    UIUtils.SafeSetVisibility(self.ChangeNumber, UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_StudentCard_C:SetCardSkinUpgradeInfo()
  local CardSkinId = self:GetSkillId()
  self.Grade:Init(CardSkinId)
end

function UMG_StudentCard_C:SetShinePetIcon()
  self:SetImageDrawas(UE4.ESlateBrushDrawType.Box)
end

function UMG_StudentCard_C:SetImageDrawas(drawAs)
  local CurrentBrush = self.PanelBg_3.Brush
  CurrentBrush.DrawAs = drawAs
  self.PanelBg_3:SetBrush(CurrentBrush)
end

function UMG_StudentCard_C:OnSetFavoritePetEvent(_CardInfo)
  self.CardInfo = _CardInfo
  self:SetCardFavoriteList()
end

function UMG_StudentCard_C:OnSetPlayerCardCollectPetSuccess(cardBriefInfo)
  self.CardInfo = cardBriefInfo
  self:SetCardFavoriteList()
end

function UMG_StudentCard_C:SetCardFavoriteList(scrollPageIndex)
  if not self.data then
    return
  end
  local CardComponentTabDataList = {}
  table.insert(CardComponentTabDataList, {
    ComponentType = _G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET
  })
  table.insert(CardComponentTabDataList, {
    ComponentType = _G.ProtoEnum.RoleCardModuleType.RCMT_BADGE
  })
  self.TabList:InitGridView(CardComponentTabDataList)
  UIUtils.SafeSetVisibility(self.TabList, UE4.ESlateVisibility.SelfHitTestInvisible)
  UIUtils.SafeSetVisibility(self.TravelButton, UE4.ESlateVisibility.SelfHitTestInvisible)
  local cardComponentDataList = {}
  local ComponentType = self.data:GetCurCardComponentType()
  cardComponentDataList = self:GetCardDataList(ComponentType)
  local originalPageIndex = self.ScrollPageController:GetCurrentPage()
  local originalTotalNum = self.ScrollPageController:GetTotalPageNum()
  self.LovePartner_3:InitList(cardComponentDataList)
  if originalTotalNum ~= #cardComponentDataList then
    self.ScrollPageController:SetValidItemTotalNum(#cardComponentDataList)
  end
  local maxPageNum = self.ScrollPageController:GetTotalPageNum()
  local targetPageIndex
  if scrollPageIndex then
    targetPageIndex = scrollPageIndex
  elseif originalPageIndex >= maxPageNum then
    if maxPageNum <= 0 then
      targetPageIndex = 0
    else
      targetPageIndex = maxPageNum - 1
    end
  else
    targetPageIndex = originalPageIndex
  end
  if scrollPageIndex and targetPageIndex ~= originalPageIndex then
    local scrollTime = 0.2
    self.ScrollPageController:ScrollToPage(targetPageIndex, scrollTime)
  else
    local scrollToIndex = targetPageIndex * self.ScrollPageController:GetItemNumPerPage()
    self.LovePartner_3:ScrollToIndex(scrollToIndex, true)
    self.ScrollPageController:ScrollToPage(targetPageIndex, 0.1)
  end
  self:SetItemSpinAngle()
  if maxPageNum > 1 then
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    local pageData = {}
    for i = 1, maxPageNum do
      table.insert(pageData, i)
    end
    self.Dot_List:InitGridView(pageData)
    self.Dot_List:SelectItemByIndex(targetPageIndex)
  else
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_StudentCard_C:GetItemNumPerPage()
  return self.ScrollPageController:GetItemNumPerPage()
end

function UMG_StudentCard_C:GetCardDataList(ComponentType)
  local cardInfoListResult = {}
  local isEditingComponent = self.data:GetIsEditingComponent()
  local validCardInfoList = {}
  if isEditingComponent then
    validCardInfoList = self.data:GetCurEditCardInfoList(ComponentType)
  else
    validCardInfoList = self.data:GetCardComponentInfoListForShow(ComponentType, self.CardInfo)
  end
  local maxPetNum = self.data:GetMaxCardNum(ComponentType)
  local cardShowType = isEditingComponent and FriendEnum.CardComponentShowType.CardModified or FriendEnum.CardComponentShowType.CardNormal
  for i = 1, maxPetNum do
    local validCardInfo
    for _, v in ipairs(validCardInfoList) do
      if v:GetIndex() == i - 1 then
        validCardInfo = v
        break
      end
    end
    local cardItemData
    if validCardInfo then
      cardItemData = validCardInfo
      cardItemData:SetCardShowType(cardShowType)
    else
      cardItemData = EditComponentItemData:Create(ComponentType)
      cardItemData:InitEmptyInfo(ComponentType, cardShowType)
    end
    table.insert(cardInfoListResult, cardItemData)
  end
  if not isEditingComponent then
    cardInfoListResult = self:CheckAndDeleteEmptyPage(cardInfoListResult)
  end
  return cardInfoListResult
end

function UMG_StudentCard_C:CheckAndDeleteEmptyPage(oriCardInfoList)
  local itemNumPerPage = self:GetItemNumPerPage()
  local pageCount = math.ceil(#oriCardInfoList / itemNumPerPage)
  local newCardInfoList = {}
  for i = 1, pageCount do
    local startIndex = (i - 1) * itemNumPerPage + 1
    local endIndex = math.min(i * itemNumPerPage, #oriCardInfoList)
    if startIndex >= 1 and startIndex <= endIndex then
      local pageData = {}
      for j = startIndex, endIndex do
        local item = oriCardInfoList[j]
        if not item:IsCardInfoEmpty() then
          table.insert(pageData, oriCardInfoList[j])
        end
      end
      if #pageData > 0 then
        for j = startIndex, endIndex do
          table.insert(newCardInfoList, oriCardInfoList[j])
        end
      end
    end
  end
  if 0 == #newCardInfoList then
    for i = 1, math.min(itemNumPerPage, #oriCardInfoList) do
      table.insert(newCardInfoList, oriCardInfoList[i])
    end
  end
  Log.Debug("UMG_StudentCard_C:CheckAndDeleteEmptyPage oriCardInfoList num=" .. #oriCardInfoList .. " newCardInfoList num=", #newCardInfoList)
  return newCardInfoList
end

function UMG_StudentCard_C:UpdateScrollToPage()
  self.ScrollPageController:ScrollToPage(self.ScrollPageController:GetCurrentPage(), 0.5, true)
end

function UMG_StudentCard_C:SetItemSpinAngle()
  local listCount = self.LovePartner_3:GetTotalItemNumber()
  for i = 1, listCount do
    local Item = self.LovePartner_3:GetItemByIndex(i - 1)
    if Item then
      Item:SetAngle(self:GetSpinAngle(i))
    end
  end
end

function UMG_StudentCard_C:GetSpinAngle(CurrenIndex)
  if 0 == CurrenIndex % 6 then
    return -13
  elseif 1 == CurrenIndex % 6 then
    return -6
  elseif 2 == CurrenIndex % 6 then
    return 9
  elseif 3 == CurrenIndex % 6 then
    return 17
  elseif 4 == CurrenIndex % 6 then
    return -15
  elseif 5 == CurrenIndex % 6 then
    return 12
  end
end

function UMG_StudentCard_C:OnPageChangeHandle(_page)
  self.Dot_List:SelectItemByIndex(_page)
end

function UMG_StudentCard_C:OnLeftSlide()
  if self.ScrollPageController.curPage > 0 then
    local Success = self.ScrollPageController:ScrollToPage(self.ScrollPageController.curPage - 1, 0.5, true)
  end
end

function UMG_StudentCard_C:OnRightSlide()
  if self.ScrollPageController.curPage < self.ScrollPageController:GetTotalPageNum() - 1 then
    local Success = self.ScrollPageController:ScrollToPage(self.ScrollPageController.curPage + 1, 0.5, true)
  end
end

function UMG_StudentCard_C:OnPreviousPage()
  _G.NRCAudioManager:PlaySound2DAuto(40006002, "UMG_StudentCard_C:OnPreviousPage")
  if self.ScrollPageController2.curPage > 0 then
    local Success = self.ScrollPageController2:ScrollToPage(self.ScrollPageController2.curPage - 1, 0.1, true)
  end
end

function UMG_StudentCard_C:OnNextPage()
  _G.NRCAudioManager:PlaySound2DAuto(40006002, "UMG_StudentCard_C:OnNextPage")
  if self.ScrollPageController2.curPage < self.ScrollPageController2:GetTotalPageNum() - 1 then
    local Success = self.ScrollPageController2:ScrollToPage(self.ScrollPageController2.curPage + 1, 0.1, true)
  end
end

function UMG_StudentCard_C:OnTick(_DeltaTime)
  if self.IsFrontPanel then
    return
  end
  self:UpdateLeftRightButtonState()
  self:UpdateRecordLeftRightButtonState()
end

function UMG_StudentCard_C:UpdateLeftRightButtonState()
  if self.ScrollPageController:GetTotalPageNum() <= 1 then
    self.NRCButton_68:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.ScrollPageController.curPage <= 0 then
    self.NRCButton_68:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.ScrollPageController.curPage >= self.ScrollPageController:GetTotalPageNum() - 1 then
    self.NRCButton_68:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCButton_68:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCButton:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_StudentCard_C:UpdateRecordLeftRightButtonState()
  if self.ScrollPageController2:GetTotalPageNum() <= 1 then
    self.LButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.ScrollPageController2.curPage <= 0 then
    self.LButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RButton:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.ScrollPageController2.curPage >= self.ScrollPageController2:GetTotalPageNum() - 1 then
    self.LButton:SetVisibility(UE4.ESlateVisibility.Visible)
    self.RButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.LButton:SetVisibility(UE4.ESlateVisibility.Visible)
    self.RButton:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_StudentCard_C:GetSkillId()
  local Id
  if self.BaseData and self.BaseData.CardInfo and self.BaseData.CardInfo.card_appearance_info then
    Id = self.BaseData.CardInfo.card_appearance_info.card_skin_selected
  end
  if not Id or 0 == Id then
    Id = self.data:GetDefaultSkinId()
    if not Id then
      Log.Error("\233\187\152\232\174\164\232\131\140\230\153\175Id\228\185\159\228\184\186\231\169\186,\230\159\165\231\156\139\233\187\152\232\174\164\232\174\190\231\189\174\232\131\140\230\153\175Id\233\128\187\232\190\145")
    end
  end
  return Id
end

function UMG_StudentCard_C:SetPanelTextInfo()
  self.NRCText_85:SetText(_G.DataConfigManager:GetLocalizationConf("rolecard_adventure_record_title").msg)
end

function UMG_StudentCard_C:OnModifyAvatarUpdate(_data)
  self.CardInfo = _data
  self:OnDataModifiedAndRefreshUI()
end

function UMG_StudentCard_C:OnModifyPlayerRemarkUpdate(note)
  self.BaseData.name = note
  self:SetPlayerName(note, false)
end

function UMG_StudentCard_C:OnModifyPlayerSignatureUpdate(OldNote, NewNote, _data)
  local Text = NewNote
  if nil == NewNote or "" == NewNote then
    Text = _G.DataConfigManager:GetLocalizationConf("card_signature_input_empty_text").msg
  end
  self.PlayerInfo = _data
  if _data and _data.card_brief_info then
    self.CardInfo = _data.card_brief_info
  end
  self.Personalized_Signature_1:SetText(Text)
  self.Personalized_Signature:SetText(Text)
end

function UMG_StudentCard_C:OnModifyLabelText(_FirstId, _LastId, _data)
  if _data and _data.card_brief_info then
    self.CardInfo = _data.card_brief_info
  end
  self:SetLabel()
end

function UMG_StudentCard_C:OnModifyCardBGUpdate(_card_brief_info)
  self.CardInfo = _card_brief_info
  self:OnDataModifiedAndRefreshUI()
end

function UMG_StudentCard_C:SetAvatar()
  local PlayerInfo = self.PlayerInfo
  local UnlockAvatar = _G.ProtoMessage:newPlayerCardInfo().icon_owned
  local AvatarConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CARD_ICON_CONF):GetAllDatas()
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  for i, _ in ipairs(AvatarConf) do
    if AvatarConf[i].is_initial_unlock == true then
      table.insert(UnlockAvatar, AvatarConf[i])
      if PlayerInfo.additional_data.card_brief_info == nil then
        if PlayerInfo.sex == AvatarConf[i].id then
          local AvatarPath = UnlockAvatar[i].icon_resource_path
          AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
          self.HeadPortrait:SetPath(AvatarPath)
        end
      elseif nil ~= PlayerInfo.additional_data.card_brief_info.card_icon_selected and PlayerInfo.additional_data.card_brief_info.card_icon_selected == AvatarConf[i].id then
        local AvatarPath = UnlockAvatar[i].icon_resource_path
        AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
        self.HeadPortrait:SetPath(AvatarPath)
      end
    end
  end
end

function UMG_StudentCard_C:SetSignature()
  local CardInfo = self.CardInfo
  Log.Dump(CardInfo, 6, "UMG_StudentCard_C:SetSignature")
  local Text
  if CardInfo.card_signature == nil or CardInfo.card_signature == "" then
    Text = _G.DataConfigManager:GetLocalizationConf("card_signature_input_empty_text").msg
  else
    Text = CardInfo.card_signature
  end
  self.Personalized_Signature_1:SetText(Text)
  self.Personalized_Signature:SetText(Text)
end

function UMG_StudentCard_C:SetLabel()
  local Path = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Skin/Frames/"
  local CardInfo = self.CardInfo
  if CardInfo and CardInfo.card_label_first_selected and CardInfo.card_label_last_selected then
    local CardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(CardInfo.card_label_first_selected)
    local CardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(CardInfo.card_label_last_selected)
    if CardLabelFirstConf and CardLabelLastConf then
      self.UMG_BusinessCard_Label_61:SetLabelText(string.format("%s%s", CardLabelFirstConf.label_text, CardLabelLastConf.label_text))
    end
  end
end

function UMG_StudentCard_C:SetIcon()
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  local CardInfo = self.CardInfo
  local CardIconConf = _G.DataConfigManager:GetCardIconConf(CardInfo.card_icon_selected)
  if CardIconConf and CardIconConf.icon_resource_path then
    local AvatarPath = CardIconConf.icon_resource_path
    AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
    self.HeadPortrait:SetPath(AvatarPath)
  end
end

function UMG_StudentCard_C:SetColor()
  if 1 == self.CardInfo.card_skin_selected then
    self.Personalized_Signature:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Time_Enrollment_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Time_Enrollment:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Line:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Line_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Line_2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Line_3:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
    self.Colour_Line:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#B7871DFF"))
  else
    self.Personalized_Signature:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Time_Enrollment_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Time_Enrollment:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Line:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Line_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Line_2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Line_3:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
    self.Colour_Line:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#2B5F58FF"))
  end
end

function UMG_StudentCard_C:OnChangeNumber()
  if self.data:GetIsEditingComponent() then
    Log.Debug("UMG_StudentCard_C:OnChangeNumber data:GetIsEditingComponent() true, cannot change number")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1001, "UMG_StudentCard_C:OnChangeNumber")
  UE4.UNRCStatics.ClipboardCopy(self.NRCText_145:GetText())
  _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_copy_UID_tips)
end

function UMG_StudentCard_C:OpenOptionPanel()
end

function UMG_StudentCard_C:OnClickMultipleChoice()
end

function UMG_StudentCard_C:OnClickBtnCloseTab()
  self:SetLock(false)
  self:SetBtnCloseTabState(true)
end

function UMG_StudentCard_C:GetChangedInfo()
  return self.data:SetStudentCardOptionList()
end

function UMG_StudentCard_C:OverturnCardPanel()
  if self.data:GetIsEditingComponent() then
    Log.Debug("UMG_StudentCard_C:OverturnCardPanel data:GetIsEditingComponent() true, cannot overturn")
    return
  end
  if self.Lock then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40006004, "UMG_StudentCard_C:OverturnCardPanel")
  self:SetLock(true)
  if self.IsFrontPanel then
    self:PlayAnimation(self.TurnOver)
    self:PlayAnimation(self.Press_Overturn)
    self.IsFrontPanel = false
  else
    self:PlayAnimation(self.TurnOver_Back)
    self:PlayAnimation(self.Press_Overturn)
    self.IsFrontPanel = true
  end
  self:SetPanelInfo()
end

function UMG_StudentCard_C:CloseStudentCardPanel(isForceClose)
  if self.data:GetIsEditingComponent() and not isForceClose then
    return
  end
  if self.isClosing then
    return
  end
  self.isClosing = true
  Log.Debug("UMG_StudentCard_C:CloseStudentCardPanel")
  self:StopAllAnimations()
  self:PlayAnimation(self.Out)
  UE4Helper.SetEnableWorldRendering(true, false)
  self.btnCloseStudentCardPanel:SetIsEnabled(false)
end

function UMG_StudentCard_C:OnAnimationFinished(Animation)
  if Animation == self.In then
    self:SetLock(false)
  elseif Animation == self.Out then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
    Log.Debug("UMG_StudentCard_C:OnAnimationFinished Out DoClose")
    self:DoClose()
    self.btnCloseStudentCardPanel:SetIsEnabled(true)
    self.isClosing = false
  elseif Animation == self.TurnOver then
    self:SetLock(false)
    self:SetPanelReverseSideInfo()
    self:ResetCardPanelTransform()
  elseif Animation == self.TurnOver_Back then
    self:SetLock(false)
    self:ResetCardPanelTransform()
  elseif Animation == self.Pick_in then
    self:SetLock(false)
  end
end

function UMG_StudentCard_C:ResetCardPanelTransform()
  if self.CanvasPanel_71 then
    self.CanvasPanel_71:SetRenderScale(UE4.FVector2D(1.0, 1.0))
  end
end

function UMG_StudentCard_C:SetBtnCloseTabState(_IsClose)
  if _IsClose then
    self.BtnCloseTab:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BtnCloseTab:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_StudentCard_C:OnReportBtn()
  local ReportData = {}
  ReportData.uin = self.BaseData.uin
  ReportData.business_data = {}
  ReportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_PERSONAL_INFORMATION_SCENE
  local CardInfo = self.CardInfo
  if CardInfo.card_signature == nil or CardInfo.card_signature == "" then
    ReportData.business_data.signature = _G.DataConfigManager:GetLocalizationConf("card_signature_input_empty_text").msg
  else
    ReportData.business_data.signature = CardInfo.card_signature
  end
  ReportData.business_data.is_form_card = true
  if CardInfo.business_card_info and CardInfo.business_card_info.cur_card_url then
    ReportData.business_data.reported_card_url = CardInfo.business_card_info.cur_card_url
    ReportData.business_data.reported_card_name = CardInfo.business_card_info.cur_card
  end
  _G.NRCAudioManager:PlaySound2DAuto(1010, "UMG_Friend_Chitchat_C:OnReportBtn")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendReport, ReportData)
end

function UMG_StudentCard_C:OnBlacklistBtn()
  self:OnDeleteFriendOrAddBlack("blacklist_affirm_content", self.OnOnAddBlackListCallback)
end

function UMG_StudentCard_C:OnDeleteBtn()
  self:OnDeleteFriendOrAddBlack("delete_friend_affirm_content", self.DeleteCallback)
end

function UMG_StudentCard_C:OnInformationEditorBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_ThisTag_C:OnActive")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenChangeCardLabel)
end

function UMG_StudentCard_C:OnModifyRemarks()
  _G.NRCModeManager:DoCmd(FriendModuleCmd.OpenFriendRemark, self.BaseData)
end

function UMG_StudentCard_C:OnModifyFriendRemarkUpdate(Uin, RemarkName)
  local Name = RemarkName
  if "" == RemarkName then
    Name = self.BaseData.name
    self:SetPlayerName(Name, false)
  else
    self:SetPlayerName(Name, true)
  end
  self.BaseData.note = RemarkName
end

function UMG_StudentCard_C:SetPlayerName(playerName, isNote)
  self.Name_content_1:SetText(playerName)
  self.Name_content_3:SetText(playerName)
  if isNote then
    self.Name_content_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#DC9827FF"))
    self.Name_content_3:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFC65FFF"))
  else
    self.Name_content_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    self.Name_content_3:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFFFF"))
  end
end

function UMG_StudentCard_C:OnDeleteFriendOrAddBlack(_Id, Callback)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local dialogContext = DialogContext()
  local Text = _G.DataConfigManager:GetLocalizationConf(_Id).msg
  local showName = UIUtils.GetShowNameByCheckFriendNote(self.BaseData.uin, self.BaseData.name, false)
  local TipsContent = string.format(Text, showName)
  dialogContext:SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCallback(self, Callback)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
end

function UMG_StudentCard_C:DeleteCallback(_ok)
  if _ok then
    if self.BaseData then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.AddFriendApplicationOrRemoveFriend, self.BaseData.uin, _G.ProtoEnum.ZoneFriendAddOrRemoveFriendReq.TYPE.REMOVE_FRIEND)
    else
      Log.Error("BaseData\230\178\161\230\156\137\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    end
  end
end

function UMG_StudentCard_C:OnOnAddBlackListCallback(_ok)
  if _ok then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.AddOrRemoveBlackList, self.BaseData and self.BaseData.uin, _G.ProtoEnum.ZoneFriendAddOrRemoveBlackListReq.TYPE.ADD)
  end
end

local CardMenuType = {
  ModifiedInfo = 1,
  UploadPhoto = 2,
  EditComponent = 3,
  EditBackground = 4
}

function UMG_StudentCard_C:OnBtnMenuClick()
  if self.ComboBox_Popup:IsVisible() then
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.press2 then
      self:PlayAnimation(self.press2)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StudentCard_C:OnBtnMenuClick")
end

function UMG_StudentCard_C:HideMenuComboBoxPopup()
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_StudentCard_C:InitMenuComboBoxPopup()
  self.MenuInfo = {
    {
      menuType = CardMenuType.ModifiedInfo,
      menuName = LuaText.rolecard_edit_basic_information_buttuon
    },
    {
      menuType = CardMenuType.UploadPhoto,
      menuName = LuaText.rolecard_upload_picture_button
    },
    {
      menuType = CardMenuType.EditComponent,
      menuName = LuaText.rolecard_edit_module_button
    },
    {
      menuType = CardMenuType.EditBackground,
      menuName = LuaText.rolecard_skin_edit_button
    }
  }
  local ComboBoxData = {}
  for i, v in ipairs(self.MenuInfo) do
    local redDotKey = 0
    if v.menuType == CardMenuType.ModifiedInfo then
      redDotKey = 41
    elseif v.menuType == CardMenuType.EditBackground then
      redDotKey = 441
    end
    local comboBoxItemData = {}
    comboBoxItemData.name = v.menuName
    comboBoxItemData.isHideRedDot = 0 == redDotKey
    comboBoxItemData.redDotKey = redDotKey
    comboBoxItemData.isNotChangColor = true
    comboBoxItemData.ComType = CommonBtnEnum.ComboBoxType.StudentCardMenu
    table.insert(ComboBoxData, comboBoxItemData)
  end
  self.ComboBox_Popup:SetAutoCheckClose(true)
  self.ComboBox_Popup.List_title:InitList(ComboBoxData)
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_StudentCard_C:OnFrontPlayerOperationMoreBtnClick()
  if not self.ComboBox_Popup_1 then
    Log.Error("UMG_StudentCard_C:OnFrontPlayerOperationMoreBtnClick ComboBox_Popup_1 is nil")
    return
  end
  if self.ComboBox_Popup_1:IsVisible() then
    self:ShowPlayerOperationComboBox(self.ComboBox_Popup_1, false)
  else
    self:ShowPlayerOperationComboBox(self.ComboBox_Popup_1, true)
    if self.press then
      self:PlayAnimation(self.press)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StudentCard_C:OnFrontPlayerOperationMoreBtnClick")
end

function UMG_StudentCard_C:OnReverseSidePlayerOperationMoreBtnClick()
  if not self.ComboBox_Popup_2 then
    Log.Error("UMG_StudentCard_C:OnReverseSidePlayerOperationMoreBtnClick ComboBox_Popup_2 is nil")
    return
  end
  if self.ComboBox_Popup_2:IsVisible() then
    self:ShowPlayerOperationComboBox(self.ComboBox_Popup_2, false)
  else
    self:ShowPlayerOperationComboBox(self.ComboBox_Popup_2, true)
    if self.press then
      self:PlayAnimation(self.Press4)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StudentCard_C:OnFrontPlayerOperationMoreBtnClick")
end

function UMG_StudentCard_C:ShowPlayerOperationComboBox(PlayerOptComboBoxPopup, isShow)
  if not PlayerOptComboBoxPopup then
    Log.Error("UMG_StudentCard_C:InitPlayerOperationComboBox PlayerOptComboBoxPopup is nil")
    return
  end
  if not isShow then
    PlayerOptComboBoxPopup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local isFriend = self.BaseData.isFriend
  local PlayerCardBriefInfo = self.data:GetPlayerCardBriefInfo()
  local isTop = PlayerCardBriefInfo.pinned_time and PlayerCardBriefInfo.pinned_time > 0
  local isBlack = self.BaseData.isBlack
  local entryInfo = self:GetPlayerOperationEntryInfo(isFriend, self.BaseData.friendType, isTop, isBlack)
  self.PlayerOperationComboBoxData = {}
  for _, v in ipairs(entryInfo) do
    local comboBoxItemData = {}
    comboBoxItemData.name = v.menuName
    comboBoxItemData.isHideRedDot = true
    comboBoxItemData.isNotChangColor = true
    comboBoxItemData.ComType = CommonBtnEnum.ComboBoxType.StudentCardPlayerOperation
    comboBoxItemData.SubType = v.menuType
    table.insert(self.PlayerOperationComboBoxData, comboBoxItemData)
  end
  PlayerOptComboBoxPopup:SetAutoCheckClose(true)
  PlayerOptComboBoxPopup:SetListTitle(self.PlayerOperationComboBoxData)
  PlayerOptComboBoxPopup:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_StudentCard_C:GetPlayerOperationEntryInfo(isFriend, friendType, isTop, isBlack)
  local entryInfo = {}
  if isFriend then
    table.insert(entryInfo, {
      menuType = FriendEnum.PlayerOperationEntrance.ChangeNickname,
      menuName = LuaText.umg_friend_function1_2
    })
    if not isTop then
      table.insert(entryInfo, {
        menuType = FriendEnum.PlayerOperationEntrance.FriendTop,
        menuName = LuaText.friend_top_friend_btn
      })
    else
      table.insert(entryInfo, {
        menuType = FriendEnum.PlayerOperationEntrance.CancelTop,
        menuName = LuaText.friend_cancel_top_friend_btn
      })
    end
    if friendType == ProtoEnum.FriendType.FRIEND_TYPE_IN_GAME or friendType == ProtoEnum.FriendType.FRIEND_TYPE_ALL or friendType == ProtoEnum.FriendType.FRIEND_TYPE_NONE then
      table.insert(entryInfo, {
        menuType = FriendEnum.PlayerOperationEntrance.RemoveFriend,
        menuName = LuaText.umg_friend_function1_3
      })
    end
  end
  if isBlack then
    table.insert(entryInfo, {
      menuType = FriendEnum.PlayerOperationEntrance.CancelBlack,
      menuName = LuaText.umg_friend_function1_12
    })
  else
    table.insert(entryInfo, {
      menuType = FriendEnum.PlayerOperationEntrance.Black,
      menuName = LuaText.umg_friend_function1_4
    })
  end
  table.insert(entryInfo, {
    menuType = FriendEnum.PlayerOperationEntrance.Report,
    menuName = LuaText.umg_friend_function1_5
  })
  return entryInfo
end

function UMG_StudentCard_C:OnCardPlayerOperationSelect(operationType)
  Log.Debug("UMG_StudentCard_C:SelectPlayerOperationMenu operationType", operationType)
  if operationType == FriendEnum.PlayerOperationEntrance.ChangeNickname or operationType == FriendEnum.PlayerOperationEntrance.FriendTop or operationType == FriendEnum.PlayerOperationEntrance.CancelTop or operationType == FriendEnum.PlayerOperationEntrance.RemoveFriend then
    local isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(self.BaseData.uin)
    if not isFriend then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.friend_not_friend_privilege_tips)
      self:ShowPlayerOperationComboBox(self.ComboBox_Popup_1, false)
      self:ShowPlayerOperationComboBox(self.ComboBox_Popup_2, false)
      Log.ErrorFormat("UMG_StudentCard_C:SelectPlayerOperationMenu not friend uin=%s", tostring(self.BaseData.uin))
      return
    end
  end
  if operationType == FriendEnum.PlayerOperationEntrance.ChangeNickname then
    self:OnModifyRemarks()
  elseif operationType == FriendEnum.PlayerOperationEntrance.FriendTop then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnModifyFriendTopReq, self.BaseData.uin, true)
    _G.NRCAudioManager:PlaySound2DAuto(40006002, "UMG_StudentCard_C:OnCardPlayerOperationSelect")
  elseif operationType == FriendEnum.PlayerOperationEntrance.CancelTop then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnModifyFriendTopReq, self.BaseData.uin, false)
    _G.NRCAudioManager:PlaySound2DAuto(40006002, "UMG_StudentCard_C:OnCardPlayerOperationSelect")
  elseif operationType == FriendEnum.PlayerOperationEntrance.RemoveFriend then
    self:OnDeleteBtn()
  elseif operationType == FriendEnum.PlayerOperationEntrance.Black then
    self:OnBlacklistBtn()
  elseif operationType == FriendEnum.PlayerOperationEntrance.CancelBlack then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.AddOrRemoveBlackList, self.BaseData.uin, _G.ProtoEnum.ZoneFriendAddOrRemoveBlackListReq.TYPE.REMOVE)
  elseif operationType == FriendEnum.PlayerOperationEntrance.Report then
    self:OnReportBtn()
  else
    Log.Error("UMG_StudentCard_C:SelectPlayerOperationMenu unknown menu type", operationType)
  end
  self:ShowPlayerOperationComboBox(self.ComboBox_Popup_1, false)
  self:ShowPlayerOperationComboBox(self.ComboBox_Popup_2, false)
end

function UMG_StudentCard_C:SelectCardMenu(selectedIndex)
  if selectedIndex < 0 or selectedIndex > #self.MenuInfo then
    Log.Error("UMG_StudentCard_C:SelectCardMenu selectedIndex is out of range")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_StudentCard_C:SelectCardMenu")
  if selectedIndex == CardMenuType.ModifiedInfo then
    self:OnInformationEditorBtn()
  elseif selectedIndex == CardMenuType.UploadPhoto then
    self:OnReqUploadPhoto()
  elseif selectedIndex == CardMenuType.EditComponent then
    _G.NRCAudioManager:PlaySound2DAuto(40006003, "UMG_StudentCard_C:SelectCardMenu")
    Log.Debug("DebugTabOpenUI:OpenCardComponentSelectList")
    local cardType = self.data:GetCurCardComponentType()
    Log.Debug("DebugTabOpenUI:cardType", cardType)
    self:CheckAndTurnOverPanel()
    local param = {ComponentType = cardType}
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenCardEditingComponent, param)
  elseif selectedIndex == CardMenuType.EditBackground then
    _G.NRCAudioManager:PlaySound2DAuto(40006003, "UMG_StudentCard_C:SelectCardMenu")
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenCardChangeBackground)
  else
    Log.Error("UMG_StudentCard_C:SelectCardMenu unknown menu type", selectedIndex)
  end
  self:HideMenuComboBoxPopup()
end

function UMG_StudentCard_C:CheckAndTurnOverPanel()
  if not self.IsFrontPanel then
    return
  end
  self:SetLock(false)
  self:OverturnCardPanel()
end

function UMG_StudentCard_C:OnClickUploadPhoto()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StudentCard_C:OnClickUploadPhoto")
  self:OnReqUploadPhoto()
end

function UMG_StudentCard_C:OnReqUploadPhoto()
  local ban = false
  ban = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CLOUD_BACKGROUND_IMAGE, true)
  if ban then
    return
  else
    ban = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CLOUD_IMAGE, true)
    if ban then
      return
    end
  end
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.OpenPhotosRemoteHistoryPanel)
end

function UMG_StudentCard_C:OnReqEnterPhotoEdit(PhotoTexture)
  self.bEditingPhoto = true
  self.UploadedPhoto:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.EmptyVisibility = self.Empty:GetVisibility()
  self.Empty:SetVisibility(UE.ESlateVisibility.Collapsed)
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.OpenPhotoCroppingPanel, PhotoTexture, FPartial(self.OnPhotoUploadEstablished, self), true, self.UMG_ClippingPhoto)
end

function UMG_StudentCard_C:OnPhotoUploadEstablished(FilePath)
  if not self.enableView then
    return
  end
  self.bEditingPhoto = false
  self.bUploaded = true
  self.UploadedPhoto:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.UploadedPhotoTex = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(self, FilePath)
  self.UploadedPhoto:SetBrushFromTexture(self.UploadedPhotoTex)
  self.Empty:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_StudentCard_C:LoadPlayerCardPhoto()
  self:ToggleUploadProgressMask(true)
  local CardName = PhotoDisplayUtils.ParseUrlFileName(self.CurPlayerCardPhotoUrl)
  self:Log("LoadPlayerCardPhoto", self.CurPlayerCardPhotoUrl, self.CurPlayerCardPhotoMd5, CardName)
  if self.CurPlayerCardPhotoMd5 ~= "" then
    self.CardPhotoDisplayProxy:DisplayUrl(self.CurPlayerCardPhotoUrl, self.CurPlayerCardPhotoMd5, CardName)
  else
    NRCModuleManager:DoCmd(TakePhotosModuleCmd.DownloadCard, self.CurPlayerCardPhotoUrl, FPartial(self.OnDownloadCard, self))
  end
end

function UMG_StudentCard_C:OnDownloadCard(bSuccess, PhotoFilePath)
  if bSuccess then
    local Texture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(UE4Helper.GetCurrentWorld(), PhotoFilePath)
    self:OnInitCardPhoto(Texture)
  end
end

function UMG_StudentCard_C:ToggleUploadProgressMask(bEnabled)
  if bEnabled == self.bEnabledDownloadingPhotoMask then
    return
  end
  self.bEnabledDownloadingPhotoMask = bEnabled
  if not self.NRCWidgetLoader_LoadUpload then
    return
  end
  self.NRCWidgetLoader_LoadUpload:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  self.AccessLoading:SetVisibility(bEnabled and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
  if not self.NRCWidgetLoader_LoadUpload:GetPanel() then
    self.NRCWidgetLoader_LoadUpload.OnLoadPanelCallbackDelegate:Clear()
    self.NRCWidgetLoader_LoadUpload.OnLoadPanelCallbackDelegate:Add(self, self.OnUploadMaskLoaded)
    self.NRCWidgetLoader_LoadUpload:LoadPanel(self)
  else
    self:OnUploadMaskLoaded(true)
  end
end

function UMG_StudentCard_C:OnUploadMaskLoaded(bSuccess)
  if bSuccess then
    if self.bEnabledDownloadingPhotoMask then
      local panel = self.NRCWidgetLoader_LoadUpload:GetPanel()
      if panel then
        panel:SetCardDownloading()
      end
    else
      local panel = self.NRCWidgetLoader_LoadUpload:GetPanel()
      if panel then
        panel:StopAllAnimations()
      end
    end
  end
end

function UMG_StudentCard_C:OnInitCardPhoto(Texture)
  if not self.enableView then
    return
  end
  if not Texture then
    return
  end
  self:ToggleUploadProgressMask(false)
  self.UploadedPhoto:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.UploadedPhotoTex = Texture
  self.UploadedPhotoTexRef = UnLua.Ref(Texture)
  self.UploadedPhoto:SetBrushFromTexture(self.UploadedPhotoTex)
  self.Empty:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_StudentCard_C:OnBeginCroppingCard(PhotoTexture)
  if not PhotoTexture or not UE.UObject.IsValid(PhotoTexture) then
    return
  end
  self.bNeedRecoverPhotoPopup = true
  NRCModuleManager:GetModule("TakePhotosModule"):DisablePanel("PhotoHistoryUI")
  NRCModuleManager:GetModule("TakePhotosModule"):DisablePanel("PhotoFileViewUI")
  self:OnReqEnterPhotoEdit(PhotoTexture)
  if not self.IsFrontPanel then
    self:PlayAnimation(self.TurnOver_Back)
    self:PlayAnimation(self.Press_Overturn)
    self.IsFrontPanel = true
  end
end

function UMG_StudentCard_C:OnStopPhotoCropping()
  self.UploadedPhoto:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  if self.CurPlayerCardPhotoUrl and self.CurPlayerCardPhotoUrl ~= "" then
    self.Empty:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.Empty:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_StudentCard_C:InitCardInteractionEntryList()
  local AdminFriendType = self.data:GetCardAdminFriendType()
  if AdminFriendType == FriendEnum.AdminFriendType.Own or self.data:IsStudentCardForbidEdit() then
    self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.List:SetVisibility(UE4.ESlateVisibility.Visible)
  local CardInteractionEntryList = self:GetCardInteractionEntryList(self.BaseData.isFriend, self.BaseData.friendType)
  self.List:InitGridView(CardInteractionEntryList)
end

function UMG_StudentCard_C:GetCardInteractionEntryList(isFriend, friendType)
  local entryList = {
    {
      name = LuaText.chat_func_btn_text_home,
      TabType = FriendEnum.CardInteractionEntrance.HomeInfo,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_HomeInformation_png.img_HomeInformation_png'",
      DisabledIcon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_HomeInformation_GrayState_png.img_HomeInformation_GrayState_png'"
    },
    {
      name = LuaText.players_interact_world_report,
      TabType = FriendEnum.CardInteractionEntrance.WorldInfo,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_iconxinxi_png.img_iconxinxi_png'",
      DisabledIcon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_iconxinxi_GrayState_png.img_iconxinxi_GrayState_png'"
    },
    {
      name = LuaText.visible_circle_teleport_btn_text,
      TabType = FriendEnum.CardInteractionEntrance.Teleport,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_SendAttachmentIcon_png.img_SendAttachmentIcon_png'",
      DisabledIcon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_SendAttachmentIcon_GrayState_png.img_SendAttachmentIcon_GrayState_png'"
    }
  }
  local forbidAddFriend = self.data:IsStudentCardForbidAddFriend()
  if isFriend then
    if friendType == ProtoEnum.FriendType.FRIEND_TYPE_PLAT then
      table.insert(entryList, {
        name = LuaText.umg_friend_function1_11,
        TabType = FriendEnum.CardInteractionEntrance.AddFriend,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_AddFriend_png.img_AddFriend_png'",
        DisabledIcon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_AddFriend_png.img_AddFriend_png'"
      })
    end
  elseif not forbidAddFriend then
    table.insert(entryList, {
      name = LuaText.umg_friend_function1_11,
      TabType = FriendEnum.CardInteractionEntrance.AddFriend,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_AddFriend_png.img_AddFriend_png'",
      DisabledIcon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_AddFriend_png.img_AddFriend_png'"
    })
  end
  for _, entry in ipairs(entryList) do
    entry.PlayerInfo = self.BaseData
    if self.BaseData.isOnline or entry.TabType == FriendEnum.CardInteractionEntrance.Chitchat or entry.TabType == FriendEnum.CardInteractionEntrance.HomeInfo or entry.TabType == FriendEnum.CardInteractionEntrance.AddFriend then
      entry.IsActive = true
    else
      entry.IsActive = false
    end
  end
  return entryList
end

function UMG_StudentCard_C:OnBtnShareClick()
  local shareBaseId = _G.Enum.ShareButtonType.SBT_ROLE_CARD
  local sharePartId = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartIdByShareBaseId, shareBaseId)
  if sharePartId then
    local petCollectList = self:GetCardDataList(1)
    local badgeCollectList = self:GetCardDataList(2)
    local extraData = {
      BaseData = self.BaseData,
      CardInfo = self.CardInfo,
      SkillId = self:GetSkillId(),
      SetShinePetIcon = self.SetShinePetIcon,
      PetCollectList = petCollectList,
      BadgeCollectList = badgeCollectList,
      UploadedPhotoTex = self.UploadedPhotoTex
    }
    local data = {
      shareBaseId = shareBaseId,
      sharePartId = sharePartId,
      extraData = extraData
    }
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, data)
  end
end

function UMG_StudentCard_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = false
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_StudentCard_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_StudentCard_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_ROLE_CARD
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
  if self.ShareIsOpen then
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ShareText:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_StudentCard_C:OnCardInfoChanged()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  self.PlayerInfo = PlayerInfo
  self.CardInfo = self.PlayerInfo.additional_data.card_brief_info
  self:SetPanelReverseSideInfo()
end

return UMG_StudentCard_C

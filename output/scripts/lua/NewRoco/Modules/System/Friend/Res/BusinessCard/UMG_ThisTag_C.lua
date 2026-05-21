local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_ThisTag_C = _G.NRCPanelBase:Extend("UMG_ThisTag_C")

function UMG_ThisTag_C:OnConstruct()
  self:SetChildViews(self.UMG_CardImage)
  self.data = self.module:GetData("FriendModuleData")
  self.TabList = {
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_icontouxiang1_png.img_icontouxiang1_png'",
      Icon_1 = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_icontouxiang2_png.img_icontouxiang2_png'",
      Type = FriendEnum.InformationEditorType.ChangeHeadTab,
      CardEntranceType = FriendEnum.CardEntrance.InformationEditorPanel
    },
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_gaizhang1_png.img_gaizhang1_png'",
      Icon_1 = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_gaizhang2_png.img_gaizhang2_png'",
      Type = FriendEnum.InformationEditorType.ChangeLabelTab,
      CardEntranceType = FriendEnum.CardEntrance.InformationEditorPanel
    },
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_iconqianming1_png.img_iconqianming1_png'",
      Icon_1 = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_iconqianming2_png.img_iconqianming2_png'",
      Type = FriendEnum.InformationEditorType.ChangeNickNameTab,
      CardEntranceType = FriendEnum.CardEntrance.InformationEditorPanel
    },
    {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_iconxiugai1_png.img_iconxiugai1_png'",
      Icon_1 = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Frames/img_iconxiugai2_png.img_iconxiugai2_png'",
      Type = FriendEnum.InformationEditorType.ChangeSignTab,
      CardEntranceType = FriendEnum.CardEntrance.InformationEditorPanel
    }
  }
  self.NRCTitle_2:SetText(LuaText.edit_personal_information_name)
  self.NRCTitle:SetText(LuaText.edit_personal_information_epithet)
  self.NRCTitle_3:SetText(LuaText.edit_personal_information_sign)
  self.NRCTitle_1:SetText(LuaText.edit_personal_information_headshot)
  self.Btn_Affirm:SetBtnText(LuaText.rolecard_information_edit_btn)
  self:SetCommonTitle()
  self.NRCText_84:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SelectTab = FriendEnum.InformationEditorType.ChangeHeadTab
  self.NickName = nil
  self.FirstScrolling = false
  self.LastScrolling = false
  self.SelectedFirstIndex = nil
  self.SelectedLastIndex = nil
  self.First = nil
  self.Last = nil
  self.CardBriefInfo = nil
  self.note = nil
  self.NewInput = nil
  self.AvatarIconId = nil
  self.BtnAffirmState = true
  self.CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  self.UMG_CardImage:SetCardEntranceType(FriendEnum.CardEntrance.InformationEditorPanel)
  self.FirstSelectItem = true
  self.FirstSelectTab = true
  self.RenameCountDown = 0
  self:OnAddEventListener()
end

function UMG_ThisTag_C:OnDestruct()
  if self.CheckTimeoutDelayId then
    _G.DelayManager:CancelDelayById(self.CheckTimeoutDelayId)
    self.CheckTimeoutDelayId = nil
  end
end

function UMG_ThisTag_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:CloseLabelPanel()
end

function UMG_ThisTag_C:OnDeactive()
  if RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
    UE4.UNRCStatics.ClearKeyboardFocus()
    Log.Debug("UMG_ThisTag_C:OnDeactive ClearKeyboardFocus")
  end
end

function UMG_ThisTag_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Affirm.btnLevelUp, self.OnClickConfirm)
  self:AddButtonListener(self.CloseBtn.btnClose, self.CloseLabelPanel)
  self.List.OnUserScrolled:Add(self, self.OnFirstListScrolled)
  self.List_1.OnUserScrolled:Add(self, self.OnLastListScrolled)
  self.InputBox.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox.OnTextCommitted:Add(self, self.OnTextCommitted)
  self.InputBox.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  self.InputBox_1.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox_1.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  self:RegisterEvent(self, FriendModuleEvent.ModifyPlayerSignatureUpdate, self.OnModifyPlayerSignatureUpdate)
  self:RegisterEvent(self, FriendModuleEvent.ModifyPlayerNameUpdate, self.OnModifyPlayerNameUpdate)
  self:RegisterEvent(self, FriendModuleEvent.NotifyNameChangeRsp, self.OnModifyPlayerRemarkRsp)
  self:RegisterEvent(self, FriendModuleEvent.SelectInformationEditorIndex, self.OnSelectInformationEditorEvent)
  self:RegisterEvent(self, FriendModuleEvent.SetLabelText, self.OnModifyLabelText)
  self:RegisterEvent(self, FriendModuleEvent.SetChooseItemInfo, self.SetChooseItem)
  self:RegisterEvent(self, FriendModuleEvent.SetChooseAvatar, self.SetItemInfo)
  self:RegisterEvent(self, FriendModuleEvent.ShowOnlyActorsSucceed, self.OnShowOnlyActorsSucceed)
end

function UMG_ThisTag_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_ThisTag_C:OnActive(panelResLoadData, iniSelectItemIndex)
  self.UMG_CardImage.panelName = "ChangeCardLabel"
  if _G.GlobalConfig.DebugOpenUI then
    UE4Helper.SetEnableWorldRendering(false)
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  self.UMG_CardImage:SetPlayerPath()
  self:SetPanelList()
  if iniSelectItemIndex then
    self.List_tab:SelectItemByIndex(tonumber(iniSelectItemIndex) or 0)
  end
  self.UMG_CardImage:SetCardAdminFriendType(self.data:GetCardAdminFriendType())
  self.UMG_CardImage:SetScaleAndLocation(UE4.FVector(1.4, 1.4, 1.4), UE4.FVector(0, -80, -120))
  local fashion_wear_id = self.CardBriefInfo and self.CardBriefInfo.card_appearance_info and self.CardBriefInfo.card_appearance_info.fashion_wear_id
  local salon_item_data = self.CardBriefInfo and self.CardBriefInfo.card_appearance_info and self.CardBriefInfo.card_appearance_info.salon_item_data
  self.UMG_CardImage:SelectSuit(fashion_wear_id, FriendEnum.CardEntrance.InformationEditorPanel, salon_item_data)
  self:PlayAnimation(self.open)
  if self.UMG_CardImage and self.UMG_CardImage.previewImage then
    self.UMG_CardImage.previewImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.NameHint:SetText(LuaText.illegal_name_tips)
end

function UMG_ThisTag_C:OnShowOnlyActorsSucceed()
  Log.Info("UMG_ThisTag_C:OnShowOnlyActorsSucceed, DelayShowCardImage")
  self.CheckTimeoutDelayId = _G.DelayManager:DelaySeconds(0.3, self.DelayShowCardImage, self)
end

function UMG_ThisTag_C:DelayShowCardImage()
  Log.Info("UMG_ThisTag_C:DelayShowCardImage")
  self.CheckTimeoutDelayId = nil
  if self.UMG_CardImage and self.UMG_CardImage.previewImage then
    self.UMG_CardImage.previewImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_ThisTag_C:OnSelectInformationEditorEvent(Type)
  if self.FirstSelectTab then
    self.FirstSelectTab = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_ThisTag_C:OnActive")
  end
  self.FirstSelectItem = true
  self.SelectTab = Type
  self.Btn_Affirm:SetTitleTextAndIcon(nil, nil)
  self.Btn_Affirm:SetShowOrHideTitleCanvas(false)
  if self.SelectTab == FriendEnum.InformationEditorType.ChangeNickNameTab then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
    end
    self.SwitcherTab:SetActiveWidgetIndex(FriendEnum.InformationEditorType.ChangeNickNameTab)
    if self.InputBox:GetText() == self.NickName then
      self:RefreshAffirmBtn(false)
    else
      self:RefreshAffirmBtn(true)
    end
    local PlayerReq = _G.ProtoMessage:newZoneSetPlayerNameReq()
    PlayerReq.name = ""
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_PLAYER_NAME_REQ, PlayerReq, self, self.OnModifyPlayerRemarkRsp, false, true)
    self:SetNickNameInfo()
    self:PlayAnimation(self.Change1)
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeLabelTab then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
    self.SwitcherTab:SetActiveWidgetIndex(FriendEnum.InformationEditorType.ChangeLabelTab)
    self:RefreshAffirmBtn(true)
    self:SetLabelInfo()
    self:PlayAnimation(self.Change1)
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeSignTab then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
    end
    self.SwitcherTab:SetActiveWidgetIndex(FriendEnum.InformationEditorType.ChangeSignTab)
    self:RefreshAffirmBtn(true)
    self:SetSignInfo()
    self:PlayAnimation(self.Change1)
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeHeadTab then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
    self.SwitcherTab:SetActiveWidgetIndex(FriendEnum.InformationEditorType.ChangeHeadTab)
    self:RefreshAffirmBtn(true)
    self:SetHeadInfo()
    self:PlayAnimation(self.Change1)
  end
end

function UMG_ThisTag_C:OnModifyPlayerRemarkRsp(_rsp)
  if _rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and _rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = _rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", _rsp.ban_info.ban_time)
    local reasonStr = _rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    return
  end
  _G.DataModelMgr.PlayerDataModel:SetPlayerOpenid(_rsp.name)
  local nameChangedTimeStamp = _rsp.last_name_changed_time or 0
  if 0 == nameChangedTimeStamp then
    self.Btn_Affirm:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.role_rename_cd_des)
    self.Btn_Affirm:SetTitleTextColor("F4EEE0FF")
    self.Btn_Affirm:SetShowOrHideTitleCanvas(false)
  else
    local svrTimeStamp = ActivityUtils.GetSvrTimestamp()
    local timeCloseStamp = nameChangedTimeStamp + 604800
    local timeRemainStamp = timeCloseStamp - svrTimeStamp
    local day = timeRemainStamp // 86400
    local hour = (timeRemainStamp - 86400 * day) // 3600
    self.RenameCountDown = timeRemainStamp
    Log.Dump(timeRemainStamp, 6, "timeRemainStampRec")
    local btnText = string.format(LuaText.role_rename_cd_des_2, day, hour)
    self.Btn_Affirm:SetTitleTextAndIcon(nil, nil, nil, nil, btnText)
    self.Btn_Affirm:SetTitleTextColor("AF3D3EFF")
    if timeRemainStamp > 0 then
      self.Btn_Affirm:SetShowOrHideTitleCanvas(true)
    else
      self.Btn_Affirm:SetShowOrHideTitleCanvas(false)
    end
  end
end

function UMG_ThisTag_C:RefreshAffirmBtn(bIsEnable)
  self.BtnAffirmState = bIsEnable
  self.Btn_Affirm:SetClickAble(bIsEnable)
  if bIsEnable then
    self.Btn_Affirm.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
  else
    self.Btn_Affirm.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
  end
end

function UMG_ThisTag_C:SetPanelList()
  self.List_tab:InitGridView(self.TabList)
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self.List_tab:SelectItemByIndex(3)
  else
    self.List_tab:SelectItemByIndex(0)
  end
end

function UMG_ThisTag_C:GetSkinId()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local Id
  if PlayerInfo and PlayerInfo.additional_data and PlayerInfo.additional_data.card_brief_info and PlayerInfo.additional_data.card_brief_info.card_appearance_info and PlayerInfo.additional_data.card_brief_info.card_appearance_info.card_skin_selected then
    Id = PlayerInfo.additional_data.card_brief_info.card_appearance_info.card_skin_selected
  else
    Id = self.data:GetDefaultSkinId()
  end
  if not Id then
    Log.Error("\233\187\152\232\174\164\232\131\140\230\153\175Id\228\185\159\228\184\186\231\169\186,\230\159\165\231\156\139\233\187\152\232\174\164\232\174\190\231\189\174\232\131\140\230\153\175Id\233\128\187\232\190\145")
  end
  return Id
end

function UMG_ThisTag_C:SetNickNameInfo()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local HintText = _G.DataConfigManager:GetLocalizationConf("card_name_empty_text").msg
  self.NickName = PlayerInfo.name
  self.InputBox:SetText(PlayerInfo.name)
  self.InputBox:SetHintText(HintText)
  self.NRCText:SetText(PlayerInfo.name)
end

function UMG_ThisTag_C:updateListInfo()
  local _First = {}
  local _Last = {}
  local LabelList = self.data:GetLabelList()
  Log.Dump(LabelList, 3, "UMG_ThisTag_C:updateListInfo")
  for i, Label in ipairs(LabelList) do
    if Label.ConfigurationInfo then
      if Label.ConfigurationInfo.label_type == Enum.LabelType.LT_FIRST then
        table.insert(_First, Label.ConfigurationInfo)
      else
        table.insert(_Last, Label.ConfigurationInfo)
      end
    else
      Log.Error("\230\178\161\230\156\137\232\191\153\228\184\170\230\160\135\231\173\190\233\133\141\231\189\174\232\161\168")
    end
  end
  table.insert(_First, 1, {label_type = -1})
  table.insert(_First, 2, {label_type = -1})
  table.insert(_First, 3, {label_type = -1})
  table.insert(_First, {label_type = -1})
  table.insert(_First, {label_type = -1})
  table.insert(_First, {label_type = -1})
  table.insert(_First, {label_type = -1})
  table.insert(_First, {label_type = -1})
  table.insert(_Last, 1, {label_type = -1})
  table.insert(_Last, 2, {label_type = -1})
  table.insert(_Last, 3, {label_type = -1})
  table.insert(_Last, {label_type = -1})
  table.insert(_Last, {label_type = -1})
  table.insert(_Last, {label_type = -1})
  table.insert(_Last, {label_type = -1})
  table.insert(_Last, {label_type = -1})
  self.First = _First
  self._Last = _Last
  if #_First > 0 then
    self.List:InitList(_First)
  end
  if #_Last > 0 then
    self.List_1:InitList(_Last)
  end
  self:SelectUseLabel(self.First, self.CardBriefInfo.card_label_first_selected, self.List)
  self:SelectUseLabel(self._Last, self.CardBriefInfo.card_label_last_selected, self.List_1)
end

function UMG_ThisTag_C:SelectUseLabel(LabelList, CardLabelId, List)
  for i, Label in ipairs(LabelList) do
    if Label.id == CardLabelId then
      local Item = List:GetItemByIndex(i - 1)
      if Item then
        Item:CurrentUse(true)
        List:ScrollToIndex(i - 4, true)
      end
    end
  end
end

function UMG_ThisTag_C:SetUseLabel(LabelList, CardLabelId, List)
  for i, Label in ipairs(LabelList) do
    local Item = List:GetItemByIndex(i - 1)
    if Label.id == CardLabelId then
      if Item then
        Item:CurrentUse(true)
      end
    elseif Item then
      Item:CurrentUse(false)
    end
  end
end

function UMG_ThisTag_C:OnFirstListScrolled(offset)
  self.FirstScrolling = true
end

function UMG_ThisTag_C:OnLastListScrolled(offset)
  self.LastScrolling = true
end

function UMG_ThisTag_C:OnTick(deltaTime)
  if self.SelectTab == FriendEnum.InformationEditorType.ChangeLabelTab then
    if self.FirstScrolling == false then
      self.List:TempTick(deltaTime, 0)
    end
    if false == self.LastScrolling then
      self.List_1:TempTick(deltaTime, 0)
    end
    local FirstIndex = self.List:SelectItemByOffset(192)
    local LastIndex = self.List_1:SelectItemByOffset(192)
    if FirstIndex ~= self.SelectedFirstIndex and false == self.List.bScrollBySelf then
      self.List:SelectItemByIndex(FirstIndex)
    end
    if LastIndex ~= self.SelectedLastIndex and false == self.List_1.bScrollBySelf then
      self.List_1:SelectItemByIndex(LastIndex)
    end
    self.SelectedFirstIndex = FirstIndex
    self.SelectedLastIndex = LastIndex
    self.FirstScrolling = false
    self.LastScrolling = false
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeNickNameTab then
    if self.RenameCountDown and self.RenameCountDown > 0 then
      self.Btn_Affirm:SetShowOrHideTitleCanvas(true)
      if self.BtnAffirmState and false ~= self.BtnAffirmState then
        self:RefreshAffirmBtn(false)
      end
    else
      self.Btn_Affirm:SetShowOrHideTitleCanvas(false)
    end
  end
  if self.RenameCountDown and self.RenameCountDown > 0 then
    self.RenameCountDown = self.RenameCountDown - deltaTime
  end
end

function UMG_ThisTag_C:ChangeFirstSelected(index)
  self.curFirstSelectedIndex = index
end

function UMG_ThisTag_C:ChangeLastSelected(index)
  self.curLastSelectedIndex = index
end

function UMG_ThisTag_C:SetLabelInfo()
  self:updateListInfo()
  local FirstSelectIndex = self.List:SelectItemByOffset(192)
  self.List:SelectItemByIndex(FirstSelectIndex)
  local LastSelectIndex = self.List_1:SelectItemByOffset(192)
  self.List_1:SelectItemByIndex(LastSelectIndex)
  self.UMG_BusinessCard_Label_43:OnModifyLabelText(self.CardBriefInfo.card_label_first_selected, self.CardBriefInfo.card_label_last_selected)
end

function UMG_ThisTag_C:OnModifyLabelText(_FirstId, _LastId)
  self.UMG_BusinessCard_Label_43:OnModifyLabelText(_FirstId, _LastId)
  self:SetUseLabel(self.First, _FirstId, self.List)
  self:SetUseLabel(self._Last, _LastId, self.List_1)
end

function UMG_ThisTag_C:SetSignInfo()
  local CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  local LocalizationConf_1 = _G.DataConfigManager:GetLocalizationConf("card_signature_input_des").msg
  local numLimit = _G.DataConfigManager:GetRoleGlobalConfig("role_signature_num").num
  self.note = CardBriefInfo.card_signature
  self.InputBox_1:SetText(self.note)
  self.NRCText_1:SetText(self.note)
  local HintText = string.format(LocalizationConf_1, numLimit)
  self.InputBox_1:SetHintText(HintText)
end

function UMG_ThisTag_C:OnModifyPlayerSignatureUpdate(OldNote, NewNote)
  self.InputBox_1:SetText(NewNote)
  self.NRCText_1:SetText(NewNote)
end

function UMG_ThisTag_C:OnModifyPlayerNameUpdate(note)
  self.InputBox:SetText(note)
  self.NRCText:SetText(note)
end

function UMG_ThisTag_C:OnTextChanged()
  if self._isPinYin then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401008, "UMG_Plane_ExchangeVisits_C:OnActive")
  local InputBoxInfo, text, MaxCount
  if self.SelectTab == FriendEnum.InformationEditorType.ChangeNickNameTab then
    text = self.InputBox:GetSelectedText()
    InputBoxInfo = self.InputBox
    MaxCount = _G.DataConfigManager:GetRoleGlobalConfig("max_name_char_num").num
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeSignTab then
    text = self.InputBox_1:GetSelectedText()
    InputBoxInfo = self.InputBox_1
    MaxCount = _G.DataConfigManager:GetRoleGlobalConfig("role_signature_num").num
  end
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  local newText, bIsLegal = self:PlayerNameHandle(InputBoxInfo, MaxCount, not RocoEnv.PLATFORM_WINDOWS)
  if newText ~= InputBoxInfo:GetText() then
    InputBoxInfo:SetText(newText)
  end
  self.NameHint:SetVisibility(bIsLegal and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  if self.RenameCountDown <= 0 then
    self:RefreshAffirmBtn(bIsLegal and newText ~= self.NickName)
  end
end

function UMG_ThisTag_C:OnTextCommitted(text, type)
  if self.SelectTab == FriendEnum.InformationEditorType.ChangeNickNameTab and type == UE4.ETextCommit.OnEnter then
    local MaxCount = _G.DataConfigManager:GetRoleGlobalConfig("max_name_char_num").num
    local newText, bIsLegal = self:PlayerNameHandle(self.InputBox, MaxCount, not RocoEnv.PLATFORM_WINDOWS)
    self.InputBox:SetText(newText)
    self.NameHint:SetVisibility(bIsLegal and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    if self.RenameCountDown <= 0 then
      self:RefreshAffirmBtn(bIsLegal and newText ~= self.NickName)
    end
  end
end

function UMG_ThisTag_C:PlayerNameHandle(InputBoxInfo, maxLen, showTip)
  if not InputBoxInfo then
    return "", false
  end
  local newInputTextBackup = InputBoxInfo:GetText()
  local newInputText = InputBoxInfo:GetText()
  newInputText = UIUtils.RemoveEmoji(newInputText)
  newInputText = UIUtils.RemoveInvalidCharsByFont(newInputText, InputBoxInfo.WidgetStyle.Font.FontObject)
  newInputText = string.gsub(newInputText, "[\r\n]", "")
  newInputText = string.GetSubStr(newInputText, maxLen)
  if showTip and newInputTextBackup ~= newInputText then
    if self.SelectTab == FriendEnum.InformationEditorType.ChangeSignTab then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.biography_max_tips)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.max_name_tip)
    end
  end
  return newInputText, UIUtils.CheckNameIsLegal(newInputText)
end

function UMG_ThisTag_C:OnTextEndTransaction()
  _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Plane_ExchangeVisits_C:OnActive")
  self._isPinYin = false
  self:OnTextChanged()
end

function UMG_ThisTag_C:SetHeadInfo()
  self.IconList = self.data:GetIconList()
  Log.Dump(self.IconList, 5, "UMG_ChangeAvatar_C:SetItemList")
  self.CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  self.List_4:InitGridView(self.IconList)
  for i, Icon in ipairs(self.IconList) do
    if Icon.card_item_id == self.CardBriefInfo.card_icon_selected then
      self.List_4:SelectItemByIndex(i - 1)
      local Item = self.List_4:GetItemByIndex(i - 1)
      Item:CurrentUse(true)
      break
    end
  end
  self:SetItemInfo(self.CardBriefInfo)
end

function UMG_ThisTag_C:SetChooseItem(CardIconConf)
  if self.FirstSelectItem then
    self.FirstSelectItem = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_ChangeAvatar_Item_C:OnClick")
  end
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  local AvatarItemInfo = CardIconConf.ConfigurationInfo
  if nil ~= AvatarItemInfo then
    local AvatarPath = AvatarItemInfo.icon_resource_path
    self.AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
    self.AvatarIconId = AvatarItemInfo.id
  end
end

function UMG_ThisTag_C:SetItemInfo(_data)
  for i, Icon in ipairs(self.IconList) do
    local Item = self.List_4:GetItemByIndex(i - 1)
    if Icon.card_item_id == _data.card_icon_selected then
      self.UMG_ChangeAvatar_Item:UpdateHead(Icon)
      if Item then
        Item:CurrentUse(true)
      end
    elseif Item then
      Item:CurrentUse(false)
    end
  end
end

function UMG_ThisTag_C:OnClickConfirm()
  self.CardBriefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  if self.SelectTab == FriendEnum.InformationEditorType.ChangeNickNameTab then
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Plane_ExchangeVisits_C:OnActive")
    local InputInfo = self.InputBox:GetText()
    Log.Debug(InputInfo, self.NickName, "UMG_ThisTag_C:OnClickConfirm")
    if "" == InputInfo then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\228\184\141\232\131\189\228\184\186\231\169\186")
    elseif InputInfo == self.NickName then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_name_same_tips)
    else
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.ModifyPlayerRemark, InputInfo)
    end
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeLabelTab then
    if self.CardBriefInfo.card_label_first_selected ~= self.curFirstSelectedIndex or self.CardBriefInfo.card_label_last_selected ~= self.curLastSelectedIndex then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.SetLabelId, self.curFirstSelectedIndex, self.curLastSelectedIndex)
    end
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_ThisTag_C:ChangeLastSelected")
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeSignTab then
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Plane_ExchangeVisits_C:OnActive")
    local InputInfo = self.InputBox_1:GetText()
    if InputInfo ~= self.note then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.ModifyPlayerSignature, self.note, InputInfo)
    end
  elseif self.SelectTab == FriendEnum.InformationEditorType.ChangeHeadTab then
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_ChangeAvatar_C:OnClickConfirm")
    if self.CardBriefInfo.card_icon_selected ~= self.AvatarIconId then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.SetStudentCardAvatarPath, self.AvatarPath, self.AvatarIconId)
    end
  end
end

function UMG_ThisTag_C:CloseLabelPanel()
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_ThisTag_C:CloseLabelPanel")
  self:PlayAnimation(self.ClosePanel)
  if not _G.GlobalConfig.DebugOpenUI then
  else
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    UE4Helper.SetEnableWorldRendering(true)
  end
end

function UMG_ThisTag_C:OnAnimationFinished(Animation)
  if Animation == self.ClosePanel then
    self:DoClose()
  end
end

return UMG_ThisTag_C

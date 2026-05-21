local UMG_CreateMagicMessage_C = _G.NRCPanelBase:Extend("UMG_CreateMagicMessage_C")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local MusicCollectionModuleEvent = require("NewRoco.Modules.System.MusicCollection.MusicCollectionModuleEvent")

function UMG_CreateMagicMessage_C:OnActive(param)
  self.markType = param.markType
  self.childConf = param.ChildConf
  self.create_pos = param.create_pos
  self.npc_id = param.npc_id
  self.valid = param.valid
  self.strMessage = param.strMessage
  self.bReqPlace = false
  self.bOperate = false
  self.MusicId = 0
  self.SoundSession = -1
  if self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
    local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
    if MainUIModule then
      MainUIModule:SetJoystickEnabled(false)
    end
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_MARK_MESSAGE_SHARE, "CreateMagicMessage")
  end
  self:PlayAnimation(self.In)
  self:InitUI()
end

function UMG_CreateMagicMessage_C:OnDeactive()
end

function UMG_CreateMagicMessage_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_CreateMagicMessage_C:OnDestruct()
  self.BtnClose:SetKeyboardFocus()
  self.InputBox_Content.OnTextChanged:Remove(self, self.OnTextChanged)
  self.InputBox_Content.OnTextCommitted:Remove(self, self.OnTextCommitted)
  _G.NRCEventCenter:UnRegisterEvent(self, MusicCollectionModuleEvent.SelectedMusicEvent, self.OnSelectedMusicEvent)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.CancelMagicMessage)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, self.CancelMagicMessage)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.CancelMagicMessage)
  if self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
    local MainUIModule = NRCModuleManager:GetModule("MainUIModule")
    if MainUIModule then
      MainUIModule:SetJoystickEnabled(true)
    end
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MARK_MESSAGE_SHARE, "CreateMagicMessage")
  end
  if -1 ~= self.SoundSession then
    self:DoStopMusic()
  end
  if not self.bOperate then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, self.npc_id, self.markType)
  end
  self.markType = nil
  self.create_pos = nil
  self.npc_id = nil
  self.valid = nil
  self.strMessage = nil
  self.bReqPlace = false
  self.MusicId = 0
end

function UMG_CreateMagicMessage_C:OnAddEventListener()
  self:AddButtonListener(self.BtnCancel.btnLevelUp, self.OnClickCloseBtn)
  self:AddButtonListener(self.BtnPlace.btnLevelUp, self.OnClickPlaceBtn)
  self:AddButtonListener(self.BtnGrayPlace.btnLevelUp, self.OnClickPlaceGreyBtn)
  self:AddButtonListener(self.BtnClose.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.Btn_BackVideo, self.OnClickBackVideoBtn)
  self:AddButtonListener(self.BtnPlaceVideo.btnLevelUp, self.OnClickPlaceVideoBtn)
  self:AddButtonListener(self.Btn_AddMusic, self.OnClickAddMusicBtn)
  self:AddButtonListener(self.PlayMusic.btnLevelUp, self.OnClickPlayMusicBtn)
  self:AddButtonListener(self.StopMusic.btnLevelUp, self.OnClickStopMusicBtn)
  self:AddButtonListener(self.ReplaceMusic.btnLevelUp, self.OnClickReplaceMusicBtn)
  self:AddButtonListener(self.DeleteMusic.btnLevelUp, self.OnClickDeleteMusicBtn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MusicCollectionModuleEvent.SelectedMusicEvent, self.OnSelectedMusicEvent)
  self.InputBox_Content.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox_Content.OnTextCommitted:Add(self, self.OnTextCommitted)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.CancelMagicMessage)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, self.CancelMagicMessage)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnEnterVisit, self.CancelMagicMessage)
end

function UMG_CreateMagicMessage_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self.bOperate = true
    self:DoClose()
  end
end

function UMG_CreateMagicMessage_C:CancelMagicMessage()
  if self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
  end
  _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, self.npc_id, self.markType)
  self:PlayAnimation(self.Out)
end

function UMG_CreateMagicMessage_C:OnPcClose()
  self:OnClickCloseBtn()
end

function UMG_CreateMagicMessage_C:InitUI()
  local hintText = LuaText.message_wand_null_remind_text
  if self.childConf then
    hintText = self.childConf.remind_text
  end
  self.InputBox_Content:SetHintText(hintText)
  self.InputBox_Content:SetText("")
  self.Text_InputLen:SetText("0")
  local Conf = _G.DataConfigManager:GetGlobalConfig("magic_message_word_count")
  self.maxCharacterCount = Conf.num / 3 * 2
  self.Text_InputLen_1:SetText("/" .. string.format("%d", self.maxCharacterCount / 2))
  if self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
    self.Title:SetText(LuaText.magic_message_share_title)
    self.WidgetSwitcher_Media:SetActiveWidgetIndex(0)
    self.WidgetSwitcher_Music:SetActiveWidgetIndex(0)
    self.WidgetSwitcher_Place:SetActiveWidgetIndex(0)
    self.todayRemainCount = -1
    self:ReqGetFeedCtrlData()
  elseif self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    self.Title:SetText(LuaText.mark_video_share_title)
    self.WidgetSwitcher_Media:SetActiveWidgetIndex(1)
    self.WidgetSwitcher_Place:SetActiveWidgetIndex(1)
    local numList = _G.DataConfigManager:GetGlobalConfig("mark_video_item_demand").numList
    if 2 == #numList then
      local itemID = numList[1]
      local needNum = numList[2]
      local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, itemID)
      local bagNum = itemData and itemData.num or 0
      local itemConf = _G.DataConfigManager:GetBagItemConf(itemID)
      if itemConf then
        self.BtnPlaceVideo:SetTitleTextAndIcon(itemConf.icon, needNum .. "/" .. bagNum)
      end
    end
    if not string.IsNilOrEmpty(self.strMessage) then
      self.InputBox_Content:SetText(self.strMessage)
      local characterCount = string.StringGetTotalNum(self.strMessage)
      if characterCount > self.maxCharacterCount then
        self.Text_InputLen:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
      else
        self.Text_InputLen:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("605E5AFF"))
      end
      self.Text_InputLen:SetText(math.ceil(characterCount / 2))
    end
  end
  local card_brief_info = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  if card_brief_info then
    local card_icon_selected = card_brief_info.card_icon_selected
    local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
    if card_icon_selected and 0 ~= card_icon_selected then
      local cardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
      local avatarPath = cardIconConf.icon_resource_path
      avatarPath = string.format("%s%s.%s'", path, avatarPath, avatarPath)
      self.Image_Head:SetPath(avatarPath)
    end
  end
  self.Text_RoleName:SetText(_G.DataModelMgr.PlayerDataModel:GetPlayerName())
  self.RemainCnt:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_CreateMagicMessage_C:ReqGetFeedCtrlData()
  local req = ProtoMessage:newZoneFeedGetCtrlDataReq()
  req.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FEED_GET_CTRL_DATA_REQ, req, self, self.OnGetCtrlRsp, nil, false)
end

function UMG_CreateMagicMessage_C:OnGetCtrlRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local feedCtrlData = rsp.data
    if feedCtrlData and feedCtrlData.daily_magic_feed_count and feedCtrlData.today_magic_feed_count then
      self.todayRemainCount = feedCtrlData.daily_magic_feed_count - feedCtrlData.today_magic_feed_count
      local Conf = _G.DataConfigManager:GetGlobalConfig("mk_magic_message_remain_count_tips")
      if self.todayRemainCount <= Conf.num then
        self.RemainCnt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if 0 == self.todayRemainCount then
          self.Text_RemainCnt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FF0000FF"))
        else
          self.Text_RemainCnt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F5EEE0FF"))
        end
        self.Text_RemainCnt:SetText(self.todayRemainCount .. "/" .. feedCtrlData.daily_magic_feed_count)
      else
        self.RemainCnt:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.RemainCnt:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_CreateMagicMessage_C:OnClickPlaceBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickPlaceBtn")
  if self.bReqPlace then
    return
  end
  if 0 == self.todayRemainCount then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_18302)
    return
  end
  local content = self.InputBox_Content:GetText()
  local plainText = ""
  if self.childConf then
    plainText = string.ExtractColorCodes(content)
  else
    plainText = content
  end
  local characterCount = string.StringGetTotalNum(plainText)
  if characterCount > self.maxCharacterCount then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_18303)
    return
  end
  local validContent
  if self.childConf then
    validContent = string.ExtractInvalidColorCodes(content)
  else
    validContent = content
  end
  if "" == validContent and 0 ~= self.MusicId and "" == validContent then
    local strConf = _G.DataConfigManager:GetGlobalConfig("mark_music_random_message").str
    local strList = string.Split(strConf, ";")
    local randomIndex = math.random(1, #strList)
    validContent = LuaText[strList[randomIndex]]
  end
  self.bReqPlace = true
  local reqMsg = _G.ProtoMessage:newZoneFeedMagicCreateReq()
  reqMsg.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  reqMsg.content = validContent
  reqMsg.create_pos = self.create_pos
  reqMsg.ext_info = tostring(self.valid)
  reqMsg.music_id = self.MusicId
  if self.childConf then
    reqMsg.sub_type = self.childConf.child_type
  else
    reqMsg.sub_type = 0
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_MAGIC_CREATE_REQ, reqMsg, self, self.OnFeedMagicCreateRsp, nil, false)
  self:DelaySeconds(2, function()
    self.bReqPlace = false
  end)
end

function UMG_CreateMagicMessage_C:OnClickPlaceGreyBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickPlaceGreyBtn")
  local content = self.InputBox_Content:GetText()
  local validContent
  if self.childConf then
    validContent = string.ExtractInvalidColorCodes(content)
  else
    validContent = content
  end
  if "" == validContent then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_18300)
  end
end

function UMG_CreateMagicMessage_C:OnFeedMagicCreateRsp(rsp)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local contenText = string.format(banConfig.str, uin, ban_time, rsp.ban_info.ban_reason)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    return
  end
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.AddLocalNpcToList, rsp.feed, self.npc_id)
    self:PlayAnimation(self.Out)
  end
end

function UMG_CreateMagicMessage_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickCloseBtn")
  if self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, self.npc_id, self.markType)
    self:PlayAnimation(self.Out)
  elseif self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
    self:OnExitVideoPopUp()
  end
end

function UMG_CreateMagicMessage_C:OnExitVideoPopUp()
  local function OnClickConfirm()
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
    
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, self.npc_id, self.markType)
    self:PlayAnimation(self.Out)
  end
  
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.Call = self
  popUpData.Btn_LeftText = LuaText.CANCEL
  popUpData.Btn_RightText = LuaText.umg_bag_11
  popUpData.TitleText = LuaText.mark_video_recording_title
  popUpData.RemindSwitch = 0
  popUpData.ContentText = LuaText.mark_video_rec_give_up
  popUpData.Btn_RightHandler = OnClickConfirm
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function UMG_CreateMagicMessage_C:OnClickBackVideoBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickBackVideoBtn")
  local content = self.InputBox_Content:GetText()
  _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.OnEnterPreviewState, content)
  self:PlayAnimation(self.Out)
end

function UMG_CreateMagicMessage_C:OnClickPlaceVideoBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickPlaceVideoBtn")
  if self.bReqPlace then
    return
  end
  local content = self.InputBox_Content:GetText()
  local Conf = _G.DataConfigManager:GetGlobalConfig("magic_message_word_count")
  if string.len(content) > Conf.num then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_18303)
    return
  end
  if "" == content then
    local strConf = _G.DataConfigManager:GetGlobalConfig("mark_video_random_message").str
    local strList = string.Split(strConf, ";")
    local randomIndex = math.random(1, #strList)
    content = LuaText[strList[randomIndex]]
  end
  local curMagicSeqForRecord = _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.GetCurMagicSeqForRecord)
  if not curMagicSeqForRecord then
    Log.Error("UMG_CreateMagicMessage_C:OnClickPlaceVideoBtn curMagicSeqForRecord is nil")
    return
  end
  self.bReqPlace = true
  local file_name = curMagicSeqForRecord:GetFileName()
  local reqMsg = _G.ProtoMessage:newZoneFeedVideoGetUploadUrlReq()
  reqMsg.file_name = file_name
  reqMsg.create_pos = self.create_pos
  reqMsg.content = content
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_FEED_VIDEO_GET_UPLOAD_URL_REQ, reqMsg, self, self.OnFeedVideoGetUploadUrlRsp, nil, false)
  self:DelaySeconds(2, function()
    self.bReqPlace = false
  end)
end

function UMG_CreateMagicMessage_C:OnFeedVideoGetUploadUrlRsp(rsp)
  if not self or not UE4.UObject.IsValid(self) then
    Log.Warning("UMG_CreateMagicMessage_C:OnFeedVideoGetUploadUrlRsp self is nil")
    return
  end
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FeedSvrErr.ERR_FEEDSVR_TSS_CHECK_CONTENT_FAIL then
    return
  end
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local contenText = string.format(banConfig.str, uin, ban_time, rsp.ban_info.ban_reason)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    return
  end
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcBeforeEnsure, self.npc_id, self.markType)
  else
    local content = self.InputBox_Content:GetText()
    if "" == content then
      local strConf = _G.DataConfigManager:GetGlobalConfig("mark_video_random_message").str
      local strList = string.Split(strConf, ";")
      local randomIndex = math.random(1, #strList)
      content = LuaText[strList[randomIndex]]
    end
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.OnPlaceMagicReplay, content, self.create_pos, self.npc_id, rsp)
  end
  _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
  self:PlayAnimation(self.Out)
end

function UMG_CreateMagicMessage_C:OnClickAddMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickAddMusicBtn")
  _G.NRCModuleManager:DoCmd(_G.MusicCollectionModuleCmd.OnOpenMainPanel, nil, "MagicMessage")
end

function UMG_CreateMagicMessage_C:OnClickPlayMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickPlayMusicBtn")
  if -1 == self.SoundSession then
    self:DoPlayMusic()
  end
end

function UMG_CreateMagicMessage_C:OnClickStopMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickStopMusicBtn")
  if -1 ~= self.SoundSession then
    self:DoStopMusic()
  end
end

function UMG_CreateMagicMessage_C:OnClickReplaceMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickReplaceMusicBtn")
  self:DoStopMusic()
  _G.NRCModuleManager:DoCmd(_G.MusicCollectionModuleCmd.OnOpenMainPanel, self.MusicId, "MagicMessage")
end

function UMG_CreateMagicMessage_C:OnClickDeleteMusicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_CreateMagicMessage_C:OnClickDeleteMusicBtn")
  
  local function OnClickConfirm()
    self:DoStopMusic()
    self.MusicId = 0
    self.WidgetSwitcher_Music:SetActiveWidgetIndex(0)
    self:SetPlaceMessageSwitcherState()
  end
  
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.Call = self
  popUpData.Btn_LeftText = LuaText.CANCEL
  popUpData.Btn_RightText = LuaText.umg_bag_11
  popUpData.TitleText = LuaText.TIPS
  popUpData.RemindSwitch = 0
  popUpData.ContentText = LuaText.mark_music_reselect
  popUpData.Btn_RightHandler = OnClickConfirm
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function UMG_CreateMagicMessage_C:OnSelectedMusicEvent(MusicId)
  local musicConf = _G.DataConfigManager:GetMusicConf(MusicId)
  if musicConf then
    self.MusicId = MusicId
    self.WidgetSwitcher_Music:SetActiveWidgetIndex(1)
    self.Text_MusicName:SetText(musicConf.music_name)
    self:SetPlaceMessageSwitcherState()
  end
  self:DelaySeconds(0.5, function()
    self:DoPlayMusic()
  end)
end

function UMG_CreateMagicMessage_C:DoPlayMusic()
  local musicConf = _G.DataConfigManager:GetMusicConf(self.MusicId)
  if musicConf then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.Progress:SetFillAmount(0)
    self.Progress:SetFillStartPercent(0.5)
    if self.playingTimer then
      _G.TimerManager:RemoveTimer(self.playingTimer)
    end
    self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(musicConf.EventName, "UMG_CreateMagicMessage_C")
    self.musicTime = _G.NRCAudioManager:GetMaxTimeFromEventName(musicConf.EventName)
    self.playingTimer = _G.TimerManager:CreateTimer(self, "UMG_CreateMagicMessage_C:DoPlayMusic", self.musicTime, self.OnTimerUpdate, self.OnTimerEnd, 0.1)
  end
end

function UMG_CreateMagicMessage_C:OnTimerUpdate()
  if self.SoundSession and -1 ~= self.SoundSession then
    local playPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
    local playTime = math.floor(playPositionMs / 1000)
    local progress = playTime / self.musicTime
    self.Progress:SetFillAmount(progress)
  end
end

function UMG_CreateMagicMessage_C:OnTimerEnd()
  self:DoStopMusic()
end

function UMG_CreateMagicMessage_C:DoStopMusic()
  self.BtnSwitcher:SetActiveWidgetIndex(0)
  _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, "UMG_CreateMagicMessage_C")
  self.SoundSession = -1
  if self.playingTimer then
    _G.TimerManager:RemoveTimer(self.playingTimer)
  end
end

function UMG_CreateMagicMessage_C:OnTextChanged()
  local content = self.InputBox_Content:GetText()
  if string.find(content, "[\r\n]") then
    local newContent = string.gsub(content, "[\r\n]", "")
    Log.Info("UMG_CreateMagicMessage_C:OnTextChanged \231\167\187\233\153\164\230\141\162\232\161\140\231\172\166", newContent)
    self.InputBox_Content:SetText(newContent)
    return
  end
  local plainText, colorList
  if self.childConf then
    plainText, colorList = string.ExtractColorCodes(content)
  else
    plainText = content
  end
  local curCharacterCount = string.StringGetTotalNum(plainText)
  local limitCharacterCount = 999
  if curCharacterCount > limitCharacterCount then
    plainText = string.GetSubStr(plainText, limitCharacterCount)
    local finalText = plainText
    if self.markType == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE and self.childConf then
      finalText = string.RebuildTextWithColorCodes(plainText, colorList)
    end
    self.InputBox_Content:SetText(finalText)
    return
  end
  if curCharacterCount > self.maxCharacterCount then
    self.Text_InputLen:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
  else
    self.Text_InputLen:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("605E5AFF"))
  end
  self.Text_InputLen:SetText(math.ceil(curCharacterCount / 2))
  self:SetPlaceMessageSwitcherState()
end

function UMG_CreateMagicMessage_C:SetPlaceMessageSwitcherState()
  if self.markType == Enum.MarkGameplay.MK_MAGIC_MESSAGE then
    if 0 ~= self.MusicId then
      self.WidgetSwitcher_PlaceMessage:SetActiveWidgetIndex(1)
    else
      local content = self.InputBox_Content:GetText()
      local validContent
      if self.childConf then
        validContent = string.ExtractInvalidColorCodes(content)
      else
        validContent = content
      end
      if "" ~= validContent then
        self.WidgetSwitcher_PlaceMessage:SetActiveWidgetIndex(1)
      else
        self.WidgetSwitcher_PlaceMessage:SetActiveWidgetIndex(0)
      end
    end
  end
end

function UMG_CreateMagicMessage_C:OnTextCommitted()
  local content = self.InputBox_Content:GetText()
  content = string.gsub(content, "[\r\n]", "")
  self.InputBox_Content:SetText(content)
end

return UMG_CreateMagicMessage_C

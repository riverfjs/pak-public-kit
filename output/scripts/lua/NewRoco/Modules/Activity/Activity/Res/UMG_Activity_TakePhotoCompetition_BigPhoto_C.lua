local UMG_Activity_TakePhotoCompetition_BigPhoto_C = _G.NRCPanelBase:Extend("UMG_Activity_TakePhotoCompetition_BigPhoto_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ActivityModuleCmd = require("NewRoco.Modules.System.Activity.ActivityModuleCmd")
local TakePhotosUtils = require("NewRoco.Modules.System.TakePhotos.TakePhotosUtils")

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnConstruct()
  self:OnAddEventListener()
  self:SetChildViews(self.PhotoFile)
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_PlayerInfo, self.OnClickPlayerInfo)
  self:AddButtonListener(self.Btn_ReSubmit, self.OnClickReSubmit)
  self:AddButtonListener(self.Btn_DownLoad.btnLevelUp, self.OnClickDownLoad)
  self:AddButtonListener(self.Btn_Share.btnLevelUp, self.OnClickShare)
  self:AddButtonListener(self.Btn_Report.btnLevelUp, self.OnClickReport)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickClose)
  self:AddButtonListener(self.NRCButton_Bg, self.OnClickClose)
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickPlayerInfo()
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickReSubmit()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickReSubmit")
  _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.OpenPhotosActivityAlbumPanel)
  self:DoClose()
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickDownLoad()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickDownLoad")
  self.PhotoFile:ReqDownloadSaveAlbum()
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickShare()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickShare")
  self.PhotoFile:ReqSharePhoto()
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickReport()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickReport")
  local photoData = self.photoData
  if photoData then
    TakePhotosUtils.ReportPhoto(photoData.uin, photoData.mini_photo_url, photoData.photo_url, photoData.activity_sub_id)
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnClickClose")
  if self.bPendingClose then
    return
  end
  self.bPendingClose = true
  self:PlayAnimation(self.Out)
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnAnimationStarted(Anim)
  if Anim == self.In_1 then
    self.bIn2Played = false
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  elseif Anim == self.In_1 then
    self:OnTextureReady()
    self:DelaySeconds(3, function()
      if not self.bIn2Played then
        self.bIn2Played = true
        self:PlayAnimation(self.In_2)
      end
    end)
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnTextureReady()
  if self.PhotoFile.FileTexture2D and not self.bPendingClose and not self:IsAnimationPlaying(self.Out) then
    self.bIn2Played = true
    self:PlayAnimation(self.In_2)
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnActive(photoData)
  if not self.bTextureReadyDelegateBind then
    self.bTextureReadyDelegateBind = true
    self.PhotoFile.DisplayProxy.OnReadyDelegate:Add(self, self.OnTextureReady)
  end
  local takePhotoActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  if not takePhotoActivityInst then
    Log.Error("UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnActive takePhotoActivityInst is nil")
    return
  end
  if not photoData then
    Log.Error("UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnActive photoData is nil")
    return
  end
  if photoData.uin == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
    self.Btn_Report:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.photoData = photoData
  self:DisplayPhoto()
  if self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.MySubmission then
    self.CanvasPanel_PlayerInfo:SetVisibility(UE.ESlateVisibility.Visible)
    self:SetIconAndName(self.photoData.uin)
    local curStage = takePhotoActivityInst[1]:GetCurrentStage()
    if curStage == ActivityEnum.TakePhotoCompetitionStage.Preparation or curStage == ActivityEnum.TakePhotoCompetitionStage.PhotoCheck then
      self.HotSwitcher:SetActiveWidgetIndex(0)
      if curStage == ActivityEnum.TakePhotoCompetitionStage.Preparation then
        self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Visible)
      elseif curStage == ActivityEnum.TakePhotoCompetitionStage.PhotoCheck then
        self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
    elseif curStage == ActivityEnum.TakePhotoCompetitionStage.Competition or curStage == ActivityEnum.TakePhotoCompetitionStage.CurPhaseEnd then
      self.HotSwitcher:SetActiveWidgetIndex(1)
      self.HotValue:SetText(self.photoData.hot_value)
      self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.Btn_DownLoad:SetVisibility(UE.ESlateVisibility.Visible)
    self.Btn_Share:SetVisibility(UE.ESlateVisibility.Visible)
  elseif self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.HotPhoto then
    self.CanvasPanel_PlayerInfo:SetVisibility(UE.ESlateVisibility.Visible)
    self:SetIconAndName(self.photoData.uin)
    self.HotSwitcher:SetActiveWidgetIndex(1)
    self.HotValue:SetText(self.photoData.hot_value)
    self.Btn_Share:SetVisibility(UE.ESlateVisibility.Visible)
    self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_DownLoad:SetVisibility(UE.ESlateVisibility.Collapsed)
  elseif self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.RankPhoto then
    self.CanvasPanel_PlayerInfo:SetVisibility(UE.ESlateVisibility.Visible)
    self:SetIconAndName(self.photoData.uin)
    self.HotSwitcher:SetActiveWidgetIndex(1)
    self.HotValue:SetText(self.photoData.hot_value)
    self.Btn_Share:SetVisibility(UE.ESlateVisibility.Visible)
    self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_DownLoad:SetVisibility(UE.ESlateVisibility.Collapsed)
  elseif self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.VotePhoto then
    self.CanvasPanel_PlayerInfo:SetVisibility(UE.ESlateVisibility.Visible)
    self:SetIconAndName(self.photoData.uin)
    self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_DownLoad:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_Share:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_Report:SetVisibility(UE.ESlateVisibility.Visible)
  elseif self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.RewardPhoto then
    self.CanvasPanel_PlayerInfo:SetVisibility(UE.ESlateVisibility.Visible)
    self:SetIconAndName(self.photoData.uin)
    self.HotSwitcher:SetActiveWidgetIndex(1)
    self.HotValue:SetText(self.photoData.hot_value)
    self.Btn_ReSubmit:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Btn_DownLoad:SetVisibility(UE.ESlateVisibility.Visible)
    self.Btn_Share:SetVisibility(UE.ESlateVisibility.Visible)
  end
  self:PlayAnimation(self.In_1)
  if self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.HotPhoto then
    self:SendTLog(1)
  elseif self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.RankPhoto then
    self:SendTLog(3)
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:GetActivityObject()
  local ObjectList = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  return ObjectList and ObjectList[1]
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:DisplayPhoto()
  local activityObject = self:GetActivityObject()
  local ActivityName = ""
  if activityObject then
    ActivityName = activityObject:GetActivityName()
  else
    Log.Error("UMG_Activity_TakePhotoCompetition_BigPhoto_C ActivityObject is nil")
  end
  local PhaseConf = self.photoData.activity_sub_id and _G.DataConfigManager:GetTakephotoCompetitionConf(self.photoData.activity_sub_id, true)
  local MarkExtraData = {
    ActivityName = ActivityName,
    PhaseName = PhaseConf and PhaseConf.name,
    PhaseNumber = self.photoData.activity_sub_id,
    PhotoUin = self.photoData.uin,
    GetPlayerName = function()
      return self.Text_PlayerName:GetText()
    end
  }
  self.PhotoFile:DisplayRawPhoto(self.photoData.photo_url, self.photoData.photo_md5, self.CanvasPanel_Content, self.photoData.sourcePhoto, MarkExtraData)
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:SetIconAndName(uin)
  self.Text_PlayerName:SetText("")
  local curPlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if curPlayerUin == self.photoData.uin then
    self:Log("SetIconAndName LocalPlayer", curPlayerUin)
    local card_brief_info = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
    if card_brief_info then
      local card_icon_selected = card_brief_info.card_icon_selected
      self:SetHeadIcon(card_icon_selected)
      local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
      self.Text_PlayerName:SetText(playerName)
    end
  else
    local friendData = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetFriendByUin, uin)
    if friendData then
      self:Log("SetIconAndName GetFriendByUin", friendData)
      local card_icon_selected = friendData.card_icon_selected
      self:SetHeadIcon(card_icon_selected)
      local playerName = friendData.name
      self.Text_PlayerName:SetText(playerName)
    else
      self:Log("SetIconAndName ZONE_FRIEND_SEARCH_PLAYER_REQ", uin)
      local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
      req.uin = uin
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnSearchPlayerRsp, false, true)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:OnSearchPlayerRsp(rsp)
  self:Log("SetIconAndName ZoneFriendSearchPlayerRsp", rsp.ret_info.ret_code, rsp.player_info and rsp.player_info.name)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    self.searchPlayerRsp = rsp
    local card_icon_selected = rsp.player_info.card_icon_selected
    self:SetHeadIcon(card_icon_selected)
    local playerName = rsp.player_info.name
    self.Text_PlayerName:SetText(playerName)
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:SetHeadIcon(card_icon_selected)
  if card_icon_selected and 0 ~= card_icon_selected then
    local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
    local avatarPath = cardIconConf.icon_resource_path
    avatarPath = string.format("%s%s.%s'", path, avatarPath, avatarPath)
    self.Image_Head:SetPath(avatarPath)
  end
end

function UMG_Activity_TakePhotoCompetition_BigPhoto_C:SendTLog(actionType)
  if self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.HotPhoto or self.photoData.bigPhotoType == ActivityEnum.TakePhotoCompetitionBigPhotoType.RankPhoto then
    local key = "PhotoContestBigPhotoLog"
    local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
    local activity_sub_id = self.photoData.activity_sub_id
    local activityName = ""
    local phaseConf = _G.DataConfigManager:GetTakephotoCompetitionConf(activity_sub_id)
    if phaseConf then
      activityName = phaseConf.name
    end
    local photoUrl = self.photoData.photo_url
    local photoRank = self.photoData.rank or 0
    local value = string.format("%s|%s|%d|%s|%d|%s|%d", key, roleDataStr, activity_sub_id, activityName, actionType, photoUrl, photoRank)
    _G.GEMPostManager:SendNRCTLog(key, value)
  end
end

return UMG_Activity_TakePhotoCompetition_BigPhoto_C

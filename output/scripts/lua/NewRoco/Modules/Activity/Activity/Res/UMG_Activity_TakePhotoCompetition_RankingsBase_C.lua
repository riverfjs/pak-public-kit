local UMG_Activity_TakePhotoCompetition_RankingsBase_C = _G.NRCPanelBase:Extend("UMG_Activity_TakePhotoCompetition_RankingsBase_C")
local RankDataHandler = require("NewRoco.Modules.System.Misc.RankDataHandler")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local NumberImagePath = {
  [1] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_1_png.img_1_png'",
  [2] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_2_png.img_2_png'",
  [3] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_3_png.img_3_png'",
  [4] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_4_png.img_4_png'",
  [5] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_5_png.img_5_png'",
  [6] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_6_png.img_6_png'",
  [7] = "PaperSprite'/Game/NewRoco/Modules/System/Activity/Raw/ActivityTakePhotoCompetition/Frames/img_7_png.img_7_png'"
}

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnConstruct()
  self.uiElements = self:BindUIElements() or {}
  self.rankDataController = RankDataHandler.CreateRankDataController()
  local emptyText = self.uiElements.emptyText
  if emptyText then
    emptyText:SetText(_G.LuaText.pic_game_rankboard_loading)
  end
  local rankList = self.uiElements.rankList
  if rankList then
    rankList:SetMsgHandler({
      OnSelectRankDataItem = _G.MakeWeakFunctor(self, self.OnSelectRankDataItem)
    })
  end
  local rankDataEventHandler = {}
  rankDataEventHandler.OnPlayerRankDataChanged = _G.MakeWeakFunctor(self, self.OnPlayerRankDataChanged)
  rankDataEventHandler.OnSvrRspPageRankData = _G.MakeWeakFunctor(self, self.OnSvrRspPageRankData)
  rankDataEventHandler.OnViewDataRefreshed = _G.MakeWeakFunctor(self, self.OnViewDataRefreshed)
  self.rankDataController:SetEventHandler(rankDataEventHandler)
  self.rankDataController:BindView(rankList)
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnDestruct()
  local rankDataController = self.rankDataController
  if rankDataController then
    rankDataController:Free()
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:GetNumberImage(id)
  local number = id % 10
  return NumberImagePath[number]
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:SetCommonTitle(TitleCtrl)
  local titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if titleConf then
    TitleCtrl:Set_MainTitle(titleConf.title)
    TitleCtrl:SetBg(titleConf.head_icon)
    TitleCtrl:SetSubtitle(titleConf.subtitle[1].subtitle)
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:SetCardBg(id, cardCtrl)
  if id and cardCtrl then
    local cardBgIndex = id % 10
    if cardBgIndex >= 1 and cardBgIndex <= 7 then
      cardCtrl:SetActiveWidgetIndex(cardBgIndex - 1)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:RefreshPlayerRankData(playerRankData)
  if not playerRankData then
    return
  end
  self.playerRankData = playerRankData
  self:OnRefreshPlayerRankData(playerRankData)
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnPlayerRankDataChanged(object, playerRankData, fromRankList)
  local rankDataController = self.rankDataController
  local rankDataObject = rankDataController and rankDataController:GetRankDataObject()
  if rankDataObject == object then
    if not fromRankList then
      playerRankData = rankDataObject:GetPlayerRankData(true)
    end
    self:RefreshPlayerRankData(playerRankData)
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnSvrRspPageRankData(object, success)
  local rankDataController = self.rankDataController
  local rankDataObject = rankDataController and rankDataController:GetRankDataObject()
  if rankDataObject == object then
    local loadState = self.uiElements.loadState
    if loadState then
      loadState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnViewDataRefreshed(controller, dataCnt, initFlag)
  if self.rankDataController == controller then
    local loadState = self.uiElements.loadState
    if loadState and (not initFlag or dataCnt > 0) then
      loadState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local emptyState = self.uiElements.emptyState
    if emptyState then
      if dataCnt > 0 then
        emptyState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        emptyState:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      end
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:ChangeSelectRankDataItem(itemRankData)
  if not itemRankData then
    return
  end
  self.selectRankData = itemRankData
  local photoImageCtrl = self.uiElements.photoFile
  if photoImageCtrl then
    local url, md5 = self:GetImageUrlFromRankUser(itemRankData, true)
    if url and md5 then
      photoImageCtrl:DisplayFixedFramePhotoMiniMode(url, md5, self.WidgetSwitcher_Image.Slot:GetSize())
      local photoSwitcher = self.uiElements.photoSwitcher
      if photoSwitcher then
        photoSwitcher:SetActiveWidgetIndex(1)
      end
    else
      Log.Error("UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnSelectRankDataItem url or md5 is nil.", url, md5)
    end
  end
  self:PlayAnimation(self.Switch)
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnSelectRankDataItem(itemRankData)
  if self.selectRankData == self.playerRankData then
    self:StopAnimation(self.Selection)
    self:PlayAnimation(self.Unselect)
  end
  self:ChangeSelectRankDataItem(itemRankData)
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnPcClose()
  self:OnClose()
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnClickMyRankData()
  local playerRankData = self.playerRankData
  if not playerRankData then
    return
  end
  if not self:GetIsPlayerSubmit() then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.pic_game_no_submit_tips)
    return
  end
  self:PlayAnimation(self.Selection)
  self:ChangeSelectRankDataItem(playerRankData)
  local rankList = self.uiElements.rankList
  if rankList then
    rankList:ClearSelection()
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnClickPhotoBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_TakePhotoCompetition_Rankings_C:OnClickPhotoBtn")
  local selectRankData = self.selectRankData
  if not selectRankData then
    return
  end
  local userInfo = selectRankData.user_info
  local extData = userInfo and userInfo.ext_data
  local photoData = extData and extData.photo_contest
  if not photoData or string.IsNilOrEmpty(photoData.photo_url) then
    Log.Error("UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnClickPhotoBtn photo_data is nil.")
    return
  end
  local bigPhotoData = {}
  bigPhotoData.bigPhotoType = ActivityEnum.TakePhotoCompetitionBigPhotoType.RankPhoto
  bigPhotoData.sourcePhoto = self.uiElements.photoFile
  bigPhotoData.uin = userInfo.info_id
  bigPhotoData.photo_url = photoData.photo_url
  bigPhotoData.photo_md5 = photoData.photo_md5
  bigPhotoData.mini_photo_url = photoData.mini_photo_url
  bigPhotoData.mini_photo_md5 = photoData.mini_photo_md5
  bigPhotoData.hot_value = userInfo.score
  local Object = self.rankDataController:GetRankDataObject()
  local ActivitySubId = Object and Object.key.rank_id
  bigPhotoData.activity_sub_id = ActivitySubId
  bigPhotoData.rank = selectRankData.rank
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenTakePhotoCompetitionBigPhoto, bigPhotoData)
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:GetPlayerHeadIcon()
  local headId = _G.DataModelMgr.PlayerDataModel:GetPlayerHeadIcon()
  if headId and 0 ~= headId then
    return _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetCardHeadIconByHeadId, headId)
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:CreateRankUserBrief(rankUser, submit)
  local rankUserBrief = {}
  if rankUser then
    local userInfo = rankUser.user_info
    local extData = userInfo and userInfo.ext_data
    local baseExtData = extData and extData.base_data
    rankUserBrief.name = baseExtData and baseExtData.name or ""
    rankUserBrief.rank = rankUser.rank
    rankUserBrief.score = userInfo and userInfo.score
    if rankUser.rank <= 0 and submit then
      local estimated = userInfo and rankUser.estimated
      local estimatedRank = estimated and estimated.rank or 0
      local totalCount = estimated and estimated.total_count or 0
      if estimatedRank > 0 and totalCount > 0 then
        local percentage = math.ceil((estimatedRank - 1) / totalCount * 100)
        rankUserBrief.estimatedRank = percentage .. "%"
      end
    end
    local headId = baseExtData and baseExtData.card_icon_selected
    if headId and 0 ~= headId then
      rankUserBrief.iconPath = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetCardHeadIconByHeadId, headId)
    end
  end
  return rankUserBrief
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:GetImageUrlFromRankUser(rankUser, miniPhoto)
  local userInfo = rankUser.user_info
  local extData = userInfo and userInfo.ext_data
  local photoData = extData and extData.photo_contest
  if photoData then
    if miniPhoto then
      return photoData.mini_photo_url, photoData.mini_photo_md5
    else
      return photoData.photo_url, photoData.photo_md5
    end
  end
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:BindUIElements()
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:GetIsPlayerSubmit()
end

function UMG_Activity_TakePhotoCompetition_RankingsBase_C:OnRefreshPlayerRankData(rankData)
end

return UMG_Activity_TakePhotoCompetition_RankingsBase_C

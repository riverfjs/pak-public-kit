local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local CommonModuleEvent = reload("NewRoco.Modules.System.Common.CommonModuleEvent")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_PVP_FirstReward_C = _G.NRCPanelBase:Extend("UMG_PVP_FirstReward_C")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local LoadSpineAssetContextPhase = {
  LoadAssets = 1,
  WaitingForAssetLoading = 2,
  AssetLoaded = 3,
  Complete = 4
}

function UMG_PVP_FirstReward_C:OnActive()
  _G.NRCAudioManager:PlaySound2DAuto(40004001, "UMG_PVP_FirstReward_C:OnActive")
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    self:OnAddEventListener()
    self:PlayAnimation(self.In)
    return
  end
  self:OnAddEventListener()
  self:SetCommonTitle()
  self:InitData()
  self:RefreshUI()
  self:CheckShareIsOpen()
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
end

function UMG_PVP_FirstReward_C:OnDeactive()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_PVP_FirstReward_C:OnDeactive")
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    return
  end
  self:OnRemoveEventListener()
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
end

function UMG_PVP_FirstReward_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnClickClose)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OpenActivityDescription)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnShareBtnClick)
  _G.NRCModuleManager:GetModule("CommonModule"):RegisterEvent(self, CommonModuleEvent.SelectTab, self.OnSelectedTabIndex)
  _G.NRCModuleManager:GetModule("PVPRankedMatchModule"):RegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpSeasonRecordData, self.OnSetPvpSeasonRecordData)
  _G.NRCEventCenter:RegisterEvent("UMG_PVP_FirstReward_C", self, NRCGlobalEvent.OnComboBoxSelectChanged, self.OnSeasonRecordSelected)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self.SpineFlag.AnimationStart:Add(self, self.OnSpineAnimationStart)
end

function UMG_PVP_FirstReward_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.btnClose.btnClose, self.OnClickClose)
  self:RemoveButtonListener(self.DetailsBtn.btnLevelUp, self.OpenActivityDescription)
  _G.NRCModuleManager:GetModule("CommonModule"):UnRegisterEvent(self, CommonModuleEvent.SelectTab)
  _G.NRCModuleManager:GetModule("PVPRankedMatchModule"):UnRegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpSeasonRecordData)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnComboBoxSelectChanged, self.OnSeasonRecordSelected)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self.SpineFlag.AnimationStart:Clear()
end

function UMG_PVP_FirstReward_C:OpenActivityDescription()
  local titleText = _G.DataConfigManager:GetLocalizationConf("PVP_rank_character7").msg
  local contentStr = _G.DataConfigManager:GetLocalizationConf("PVP_rank_character6").msg
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnActivityDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_PVP_FirstReward_C:OnActivityDescDialogClosed()
end

function UMG_PVP_FirstReward_C:OnShareBtnClick()
  if self.ShareDataSnapshot then
    local sharePartId = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartIdByShareBaseId, self.shareBaseId)
    if sharePartId then
      local data = {
        shareBaseId = self.shareBaseId,
        sharePartId = sharePartId,
        extraData = self.ShareDataSnapshot
      }
      _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, data)
    end
  end
end

function UMG_PVP_FirstReward_C:OnTick(deltaTime)
  if self.SpineFlag then
    self.SpineFlag:Tick(deltaTime, false)
  end
end

function UMG_PVP_FirstReward_C:OnLogin()
end

function UMG_PVP_FirstReward_C:OnConstruct()
  self.ShareDataSnapshot = {}
  self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local initState = {}
  initState.isFlagShow = false
  initState.isPvpQualifierStarShow = false
  
  function initState.getSelfIsTopMasterFn()
    local data = self.data
    local top_master_info = data and data:GetTopMaster()
    local top_master_info_type = top_master_info and top_master_info.type
    local is_top_master = top_master_info_type == _G.ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_TOP_MASTER
    return is_top_master
  end
  
  self.stateManager = WidgetStateManager()
  self.stateManager:Init({
    owner = self,
    RenderWidget = self.RenderWidget,
    OnWidgetDidUpdate = self.OnWidgetDidUpdate,
    UpdateDerivedState = self.UpdateDerivedState,
    initState = initState
  })
end

function UMG_PVP_FirstReward_C:OnDestruct()
  self.stateManager:DeInit()
end

function UMG_PVP_FirstReward_C:OnAnimationFinished(anim)
  if anim == self.In then
    self:StopAllAnimations()
    self:PlayAnimation(self.Loop, 0, 0)
    self.Tab:SelectItemByIndex(0)
  end
end

function UMG_PVP_FirstReward_C:OnSpineAnimationStart(entry)
  PVPRankedMatchModuleUtils.OnFlagSpineAnimationStart(entry)
end

function UMG_PVP_FirstReward_C:OnClickClose()
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_PVP_FirstReward_C:OnClickClose")
  if _G.GlobalConfig.DebugOpenUI then
  else
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ShowUmgPVPQualifier)
  end
  self:DoClose()
end

function UMG_PVP_FirstReward_C:InitData()
  self.data = self.module:GetData("PVPRankedMatchModuleData")
  self.dataList = self.data:GetCurStarReward()
  self.season_record_data = {}
  self:SetTitle(self.data:GetCurSeasonId())
end

function UMG_PVP_FirstReward_C:RefreshUI()
  self.Tab:InitGridView({
    {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/PVPQualifier/Raw/Frames/img_tabicon1_png.img_tabicon1_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/PVPQualifier/Raw/Frames/img_tabicon1_select_png.img_tabicon1_select_png'"
    },
    {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/PVPQualifier/Raw/Frames/img_tabicon2_png.img_tabicon2_png'",
      select_icon = "PaperSprite'/Game/NewRoco/Modules/System/PVPQualifier/Raw/Frames/img_tabicon2_select_png.img_tabicon2_select_png'"
    }
  })
  self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TextQuantity_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RankName:SetText("")
  self.GridView:Clear()
  self.Popup_Downward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Popup_Downward:SetAutoCheckClose(true)
  self.AccessAuthorityBtn.OnClicked:Add(self, self.OnAccessAuthorityBtnClick)
  self:StopAllAnimations()
  self:PlayAnimation(self.In)
end

function UMG_PVP_FirstReward_C:OnSelectedTabIndex(index)
  local _, nextState = self:GetCurrAndNextState()
  nextState.tabIndex = index
  self:SetState(nextState)
end

function UMG_PVP_FirstReward_C:OnTabIndexChanged(index)
  if 1 == index then
    local _, nextState = self:GetCurrAndNextState()
    local seasonId = self.data:GetCurSeasonId()
    local startCount = PVPRankedMatchModuleUtils.GetSelfRankStar()
    nextState.selfStarCount = startCount
    nextState.selfSeasonId = seasonId
    nextState.selectRankSeasonInfo = nil
    self:SetState(nextState)
    self:RefreshSeasonReward()
    self.NRCText_7:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SeasonReward:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SeasonRecord:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetTitle(self.data:GetCurSeasonId())
  else
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TextQuantity_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_7:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SeasonReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.ShareIsOpen then
      self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.SeasonRecord:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if not self.sort_season_datas then
      self.sort_season_datas = self.data:GetSortSeasonDatas()
      self.Popup_Downward.List_title:InitList(self.sort_season_datas)
      if #self.sort_season_datas > 0 then
        self.Popup_Downward.List_title:SelectItemByIndex(0)
      else
        self:RefreshNoneSeasonData()
      end
    elseif self.season_record_index then
      self.Popup_Downward.List_title:SelectItemByIndex(self.season_record_index)
    else
      self:RefreshNoneSeasonData()
    end
  end
end

function UMG_PVP_FirstReward_C:RefreshSeasonReward()
  if self.dataList and self.GridView:GetItemCount() <= 0 then
    self.GridView:InitGridView(self.dataList)
  end
  self.RankName:SetText(PVPRankedMatchModuleUtils.GetCurRankName())
  local curRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  self.TextQuantity_1:SetText(string.format("%d/%d", curRankConf.star_num, curRankConf.star_total))
  self:UpdateStarUI()
end

function UMG_PVP_FirstReward_C:UpdateStarUI()
  local curRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  local starNum = curRankConf and curRankConf.star_num
  if PVPRankedMatchModuleUtils.IsSelfMaxRankStar() then
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TextQuantity_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local option = self.PVPQualifier_Star.GetDefaultStartIndexOption(0)
    self.PVPQualifier_Star:SwitcherStarIndex(option)
  else
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TextQuantity_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TextQuantity_1:SetText(string.format("%d/%d", curRankConf.star_num, curRankConf.star_total))
    local option = self.PVPQualifier_Star.GetDefaultStartIndexOption(starNum)
    self.PVPQualifier_Star:SwitcherStarIndex(option)
  end
end

function UMG_PVP_FirstReward_C:RefreshSeasonRewardForRecord(tabIndex, selectRankSeasonInfo)
  if 2 == tabIndex and selectRankSeasonInfo then
    local rankStar = selectRankSeasonInfo and selectRankSeasonInfo.rank_star or 1
    local isMaxRankStar = rankStar and PVPRankedMatchModuleUtils.IsMaxRankStar(rankStar)
    if isMaxRankStar then
      local option = self.PVPQualifier_Star.GetSeasonHistoryStartIndexOption(selectRankSeasonInfo)
      self.PVPQualifier_Star:SwitcherStarIndex(option)
    end
  end
end

function UMG_PVP_FirstReward_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_PVP_FirstReward_C:SetTitle(season_id)
  local season_conf = _G.DataConfigManager:GetPvpRankSeasonConf(season_id)
  if season_conf then
    self.Title1:Set_MainTitle(season_conf.name)
  end
end

function UMG_PVP_FirstReward_C:SetupSpineWidget(atlasAsset, skeletonAsset)
  local spineWidget = self.SpineFlag
  spineWidget:ClearTrack(0)
  spineWidget.skeletondata = skeletonAsset
  spineWidget.atlas = atlasAsset
  spineWidget:LuaSynchronizeProperties()
end

function UMG_PVP_FirstReward_C:ShowInSpineWidget(rank_star, is_dan_grading, is_top_master)
  if self.ShareDataSnapshot then
    self.ShareDataSnapshot.rank_star = rank_star
  end
  is_dan_grading = is_dan_grading or false
  rank_star = PVPRankedMatchModuleUtils.CorrectionRankStar(rank_star)
  local incomingGradeAnimConf = self.data:GetGradingAnimConfig(rank_star, is_top_master, is_dan_grading)
  self.SpineFlag:SetToSetupPose()
  self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.show, false)
  self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
end

function UMG_PVP_FirstReward_C:ReceiveSeasonReward()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZoneGetPvpRankSeasonRewardReq)
end

function UMG_PVP_FirstReward_C:RefreshNoneSeasonData()
  self.AccessAuthorityBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Options:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCText_54:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCText_7:SetText(_G.DataConfigManager:GetLocalizationConf("PVP_rank_character4").msg)
  self:UpdateRank(1)
end

function UMG_PVP_FirstReward_C:RefreshSeasonRecord(record_season_data)
  local data = self.data
  self.ShareDataSnapshot.TableDatas = data and data:GetSortSeasonDatas() or {}
  self.ShareDataSnapshot.TableIndex = self.season_record_index
  self.ShareDataSnapshot.CurSeasonData = record_season_data
  local sort_season_data = self.sort_season_data
  local sort_season_data_id = sort_season_data and sort_season_data.id or 1
  self:SetTitle(sort_season_data_id)
  local is_dan_grading = false
  local end_time = sort_season_data and sort_season_data.end_time or ""
  local timestamp = PVPRankedMatchModuleUtils.GetTimestampFromTimeStr(end_time)
  local cur_timestamp = _G.ZoneServer:GetServerTime() / 1000
  if timestamp <= cur_timestamp then
    self.NRCText_7:SetText(_G.DataConfigManager:GetLocalizationConf("PVP_rank_character5").msg)
    is_dan_grading = true
  else
    self.NRCText_7:SetText(_G.DataConfigManager:GetLocalizationConf("PVP_rank_character4").msg)
  end
  local petListItemList = {}
  local magicListItemList = {}
  local battle_cnt = record_season_data and record_season_data.battle_cnt or 0
  local DataSwitcherIndex = 1
  local win_count = record_season_data and record_season_data.win_count or 0
  local max_win_streak = record_season_data and record_season_data.max_win_streak or 0
  local winRate = 0
  if battle_cnt > 0 then
    winRate = math.floor(win_count / battle_cnt * 100)
    local pet_use_info = {
      {},
      {},
      {},
      {},
      {},
      {}
    }
    local petUseInfo = record_season_data and record_season_data.pet_use_info or {}
    for i, v in ipairs(petUseInfo) do
      pet_use_info[i] = v
    end
    petListItemList = pet_use_info
    magicListItemList = record_season_data and record_season_data.magic_used or {}
    DataSwitcherIndex = 0
  end
  self.SeasonMatchesText:SetText(tostring(battle_cnt))
  self.VictoriesText:SetText(tostring(win_count))
  self.WinningRateText:SetText(tostring(winRate) .. "%")
  self.HighestWinningStreakText:SetText(tostring(max_win_streak))
  self.PetList:InitGridView(petListItemList)
  self.MagicList:InitGridView(magicListItemList)
  self.DataSwitcher:SetActiveWidgetIndex(DataSwitcherIndex)
  local rank_star = record_season_data and record_season_data.rank_star or 1
  do
    local _, nextState = self:GetCurrAndNextState()
    nextState.isDanGrading = is_dan_grading or false
    self:SetState(nextState)
  end
  if record_season_data then
    self:UpdateRank(rank_star, is_dan_grading)
  end
end

function UMG_PVP_FirstReward_C:UpdateRank(rank_star, is_dan_grading)
  is_dan_grading = is_dan_grading or false
  local rank_conf = PVPRankedMatchModuleUtils.GetPvpRankConf(rank_star)
  if rank_conf then
    self.RankName:SetText(rank_conf.name)
  end
end

function UMG_PVP_FirstReward_C:OnSetPvpSeasonRecordData(data)
  self.season_record_data[data.season_id] = data
  local sort_season_data = self.sort_season_data
  local sort_season_data_season_id = sort_season_data and sort_season_data.id
  local dataSeasonId = data and data.season_id
  if sort_season_data_season_id == dataSeasonId then
    local _, nextState = self:GetCurrAndNextState()
    nextState.selectRankSeasonInfo = data
    self:SetState(nextState)
  end
end

function UMG_PVP_FirstReward_C:OnAccessAuthorityBtnClick()
  if #self.sort_season_datas <= 0 then
    return
  end
  if self.Popup_Downward:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self.Popup_Downward:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Popup_Downward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVP_FirstReward_C:OnSeasonRecordSelected(index, data_list)
  self.season_record_index = index - 1
  self.sort_season_data = data_list[index]
  self.AccessAuthorityText:SetText(self.sort_season_data.name)
  local s_year, s_month, s_day, hour, min, sec = string.match(self.sort_season_data.start_time, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  local e_year, e_month, e_day = string.match(self.sort_season_data.end_time, "(%d+)%-(%d+)%-(%d+)")
  self.NRCText_54:SetText(string.format("%s.%s.%s-%s.%s.%s", s_year, s_month, s_day, e_year, e_month, e_day))
  self.Popup_Downward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local timestamp = PVPRankedMatchModuleUtils.GetTimestampFromTimeStr(self.sort_season_data.start_time)
  local cur_timestamp = _G.ZoneServer:GetServerTime() / 1000
  local sortSeasonData = self.sort_season_data
  local sortSeasonDataId = sortSeasonData and sortSeasonData.id
  local seasonRecordData = self.season_record_data or {}
  local recordSeasonData = seasonRecordData and sortSeasonDataId and seasonRecordData[sortSeasonDataId]
  if timestamp <= cur_timestamp and nil == recordSeasonData then
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendPVPSeasonRecordQueryReq, self.sort_season_data.id)
  else
  end
  goto lbl_81
  ::lbl_81::
  local _, nextState = self:GetCurrAndNextState()
  nextState.selectRankSeasonInfo = recordSeasonData
  self:SetState(nextState)
end

function UMG_PVP_FirstReward_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = true
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_PVP_FirstReward_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PVP_FirstReward_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_PVP_RECORD
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
end

function UMG_PVP_FirstReward_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevStarCount = prevState and prevState.starCount
  local currStarCount = currState and currState.starCount
  local prevSelfStarCount = prevState and prevState.selfStarCount
  local currSelfStarCount = currState and currState.selfStarCount
  local prevSeasonId = prevState and prevState.seasonId
  local currSeasonId = currState and currState.seasonId
  local prevSelfSeasonId = prevState and prevState.selfSeasonId
  local currSelfSeasonId = currState and currState.selfSeasonId
  local prevLoadSpineAssetContext = prevState and prevState.loadSpineAssetContext
  local currLoadSpineAssetContext = currState and currState.loadSpineAssetContext
  local prevAtlasAsset = prevState and prevState.atlasAsset
  local currAtlasAsset = currState and currState.atlasAsset
  local prevSkeletonAsset = prevState and prevState.skeletonAsset
  local currSkeletonAsset = currState and currState.skeletonAsset
  local prevTabIndex = prevState and prevState.tabIndex
  local currTabIndex = currState and currState.tabIndex
  local prevSelectRankSeasonInfo = prevState and prevState.selectRankSeasonInfo
  local currSelectRankSeasonInfo = currState and currState.selectRankSeasonInfo
  local prevSelfIsTopMaster = prevState and prevState.selfIsTopMaster
  local currSelfIsTopMaster = currState and currState.selfIsTopMaster
  local prevIsSelectRankSeasonInfoTopMaster = prevState and prevState.isSelectRankSeasonInfoTopMaster
  local currIsSelectRankSeasonInfoTopMaster = currState and currState.isSelectRankSeasonInfoTopMaster
  local prevGetSelfIsTopMasterFn = prevState and prevState.getSelfIsTopMasterFn
  local currGetSelfIsTopMasterFn = currState and currState.getSelfIsTopMasterFn
  if prevStarCount ~= currStarCount or prevSeasonId ~= currSeasonId then
    local pvpRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(currStarCount)
    local atlasPath, skeletonDataPath
    atlasPath, skeletonDataPath = PVPRankedMatchModuleUtils.GetSpineAssetPathsSeasonIdInRankConf(pvpRankConf, currSeasonId)
    derivedState.atlasPath = atlasPath or UEPath.PVP_FlagSpineAtlasAsset
    derivedState.skeletonDataPath = skeletonDataPath or UEPath.PVP_FlagSpineSkeletonDataAsset
  end
  if prevLoadSpineAssetContext ~= currLoadSpineAssetContext or prevAtlasAsset ~= currAtlasAsset or prevSkeletonAsset ~= currSkeletonAsset then
    UMG_PVP_FirstReward_C.DeriveSpineFlagShow(currLoadSpineAssetContext, currAtlasAsset, currSkeletonAsset, derivedState)
  end
  if prevStarCount ~= currStarCount or prevTabIndex ~= currTabIndex then
    UMG_PVP_FirstReward_C.DerivePvpQualifierStarShow(currTabIndex, currStarCount, derivedState)
  end
  if prevTabIndex ~= currTabIndex or prevSelfStarCount ~= currSelfStarCount or prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    UMG_PVP_FirstReward_C.DeriveStarCount(currTabIndex, currSelfStarCount, currSelectRankSeasonInfo, derivedState)
  end
  if prevTabIndex ~= currTabIndex or prevSelfSeasonId ~= currSelfSeasonId or prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    UMG_PVP_FirstReward_C.DeriveSeasonId(currTabIndex, currSelfSeasonId, currSelectRankSeasonInfo, derivedState)
  end
  if prevTabIndex ~= currTabIndex or prevGetSelfIsTopMasterFn ~= currGetSelfIsTopMasterFn then
    UMG_PVP_FirstReward_C.DeriveSelfIsTopMaster(currTabIndex, currGetSelfIsTopMasterFn, derivedState)
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    UMG_PVP_FirstReward_C.DeriveSelectSeasonInfoIsTopMaster(currSelectRankSeasonInfo, derivedState)
  end
  if prevTabIndex ~= currTabIndex or prevSelfIsTopMaster ~= currSelfIsTopMaster or prevIsSelectRankSeasonInfoTopMaster ~= currIsSelectRankSeasonInfoTopMaster then
    UMG_PVP_FirstReward_C.DeriveIsTopMaster(currTabIndex, currSelfIsTopMaster, currIsSelectRankSeasonInfoTopMaster, derivedState)
  end
end

function UMG_PVP_FirstReward_C.DeriveSpineFlagShow(loadAssetContext, atlasAsset, skeletonDataAsset, derivedState)
  local isShow = false
  if atlasAsset and skeletonDataAsset then
    isShow = true
  end
  if loadAssetContext then
    isShow = false
  end
  derivedState.isFlagShow = isShow
end

function UMG_PVP_FirstReward_C.DerivePvpQualifierStarShow(tabIndex, starCount, derivedState)
  local isShow = false
  if 1 == tabIndex then
    isShow = true
  else
    local isMaxStar = PVPRankedMatchModuleUtils.IsMaxRankStar(starCount)
    if isMaxStar then
      isShow = true
    end
  end
  derivedState.isPvpQualifierStarShow = isShow
end

function UMG_PVP_FirstReward_C.DeriveStarCount(tabIndex, selfStarCount, selectRankSeasonInfo, derivedState)
  local starCount
  if 1 == tabIndex then
    if selfStarCount then
      starCount = selfStarCount
    end
  elseif selectRankSeasonInfo then
    starCount = selectRankSeasonInfo and selectRankSeasonInfo.rank_star or 1
  end
  if starCount then
    derivedState.starCount = starCount
  end
end

function UMG_PVP_FirstReward_C.DeriveSeasonId(tabIndex, selfSeasonId, selectRankSeasonInfo, derivedState)
  local seasonId
  if 1 == tabIndex then
    if selfSeasonId then
      seasonId = selfSeasonId
    end
  else
    local rankSeasonId = selectRankSeasonInfo and selectRankSeasonInfo.season_id
    if rankSeasonId then
      seasonId = rankSeasonId
    end
  end
  if seasonId then
    derivedState.seasonId = seasonId
  end
end

function UMG_PVP_FirstReward_C.DeriveSelfIsTopMaster(tabIndex, getSelfIsTopMasterFn, derivedState)
  local selfIsTopMaster = false
  if getSelfIsTopMasterFn then
    selfIsTopMaster = getSelfIsTopMasterFn()
  end
  derivedState.selfIsTopMaster = selfIsTopMaster
end

function UMG_PVP_FirstReward_C.DeriveSelectSeasonInfoIsTopMaster(seasonInfo, derivedState)
  local isSelectRankSeasonInfoTopMaster = false
  local rankOrder = seasonInfo and seasonInfo.rank_order
  local masterScore = seasonInfo and seasonInfo.master_score
  local pvp_param12Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_param12", false)
  local minMasterScore = pvp_param12Conf and pvp_param12Conf.num
  local pvp_param13Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_param13", false)
  local maxRankOrder = pvp_param13Conf and pvp_param13Conf.num
  rankOrder = rankOrder or 0
  if rankOrder <= 0 then
    rankOrder = 10001
  end
  if minMasterScore and masterScore and masterScore >= minMasterScore and maxRankOrder and rankOrder and maxRankOrder >= rankOrder then
    isSelectRankSeasonInfoTopMaster = true
  end
  derivedState.isSelectRankSeasonInfoTopMaster = isSelectRankSeasonInfoTopMaster
end

function UMG_PVP_FirstReward_C.DeriveIsTopMaster(tabIndex, selfIsTopMaster, isSelectSeasonInfoTopMaster, derivedState)
  local isTopMaster = false
  if 1 == tabIndex then
    isTopMaster = selfIsTopMaster or false
  else
    isTopMaster = isSelectSeasonInfoTopMaster or false
  end
  derivedState.isTopMaster = isTopMaster
end

function UMG_PVP_FirstReward_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsFlagShow = prevState and prevState.isFlagShow or false
  local currIsFlagShow = currState and currState.isFlagShow or false
  local prevIsPvpQualifierStarShow = prevState and prevState.isPvpQualifierStarShow or false
  local currIsPvpQualifierStarShow = currState and currState.isPvpQualifierStarShow or false
  local prevSelectRankSeasonInfo = prevState and prevState.selectRankSeasonInfo
  local currSelectRankSeasonInfo = currState and currState.selectRankSeasonInfo
  if prevIsFlagShow ~= currIsFlagShow or prevKey ~= currKey then
    self:RenderSpineFlagShow(currIsFlagShow)
  end
  if prevIsPvpQualifierStarShow ~= currIsPvpQualifierStarShow or prevKey ~= currKey then
    self:RenderPvpQualifierStarShow(currIsPvpQualifierStarShow)
  end
end

function UMG_PVP_FirstReward_C:RenderSpineFlagShow(isShow)
  local visibility = UE.ESlateVisibility.Collapsed
  if isShow then
    visibility = UE.ESlateVisibility.SelfHitTestInvisible
  end
  self.SpineFlag:SetVisibility(visibility)
end

function UMG_PVP_FirstReward_C:RenderPvpQualifierStarShow(isShow)
  local visibility = UE.ESlateVisibility.Collapsed
  if isShow then
    visibility = UE.ESlateVisibility.SelfHitTestInvisible
  end
  self.PVPQualifier_Star:SetVisibility(visibility)
end

function UMG_PVP_FirstReward_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevSkeletonDataPath = prevState and prevState.skeletonDataPath
  local currSkeletonDataPath = currState and currState.skeletonDataPath
  local prevAtlasPath = prevState and prevState.atlasPath
  local currAtlasPath = currState and currState.atlasPath
  local prevLoadSpineAssetContext = prevState and prevState.loadSpineAssetContext
  local currLoadSpineAssetContext = currState and currState.loadSpineAssetContext
  local prevAtlasAsset = prevState and prevState.atlasAsset
  local currAtlasAsset = currState and currState.atlasAsset
  local prevSkeletonAsset = prevState and prevState.skeletonAsset
  local currSkeletonAsset = currState and currState.skeletonAsset
  local prevStarCount = prevState and prevState.starCount
  local currStarCount = currState and currState.starCount
  local prevIsDanGrading = prevState and prevState.isDanGrading or false
  local currIsDanGrading = currState and currState.isDanGrading or false
  local prevTabIndex = prevState and prevState.tabIndex
  local currTabIndex = currState and currState.tabIndex
  local prevSelectRankSeasonInfo = prevState and prevState.selectRankSeasonInfo
  local currSelectRankSeasonInfo = currState and currState.selectRankSeasonInfo
  local prevShowSpineFlagAnimContext = prevState and prevState.showSpineFlagAnimContext
  local currShowSpineFlagAnimContext = currState and currState.showSpineFlagAnimContext
  if prevSkeletonDataPath ~= currSkeletonDataPath or prevAtlasPath ~= currAtlasPath then
    self:OnSpineAssetPathChanged(currAtlasPath, currSkeletonDataPath)
  end
  if prevLoadSpineAssetContext ~= currLoadSpineAssetContext then
    self:HandleLoadAssetContextChanged(prevLoadSpineAssetContext, currLoadSpineAssetContext)
  end
  if prevAtlasAsset ~= currAtlasAsset or prevSkeletonAsset ~= currSkeletonAsset then
    self:OnSpineAssetChanged(currAtlasAsset, currSkeletonAsset)
  end
  if prevAtlasAsset ~= currAtlasAsset or prevSkeletonAsset ~= currSkeletonAsset or prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo or prevTabIndex ~= currTabIndex or prevLoadSpineAssetContext ~= currLoadSpineAssetContext then
    self:SyncStateForShowFlag()
  end
  if prevTabIndex ~= currTabIndex or prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    self:RefreshSeasonRewardForRecord(currTabIndex, currSelectRankSeasonInfo)
  end
  if prevTabIndex ~= currTabIndex then
    self:OnTabIndexChanged(currTabIndex)
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo or prevKey ~= currKey then
    self:RefreshSeasonRecord(currSelectRankSeasonInfo)
  end
  if prevShowSpineFlagAnimContext ~= currShowSpineFlagAnimContext then
    self:HandleShowSpineFlagAnimContextChanged(currShowSpineFlagAnimContext)
  end
end

function UMG_PVP_FirstReward_C:SyncStateForShowFlag()
  local currState, nextState = self:GetCurrAndNextState()
  local currLoadSpineAssetContext = currState and currState.loadSpineAssetContext
  local currAtlasAsset = currState and currState.atlasAsset
  local currSkeletonAsset = currState and currState.skeletonAsset
  local currSelectRankSeasonInfo = currState and currState.selectRankSeasonInfo
  local currTabIndex = currState and currState.tabIndex
  if not currLoadSpineAssetContext and currAtlasAsset and currSkeletonAsset and (1 == currTabIndex or 2 == currTabIndex and currSelectRankSeasonInfo) then
    local currShowSpineFlagAnimContext = currState and currState.showSpineFlagAnimContext
    local currStarCountForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.starCount
    local currIsDanGradingForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.isDanGrading
    local currSeasonIdForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.seasonId
    local currTabIndexForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.tabIndex
    local currIsTopMasterForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.isTopMaster
    local nextStarCountForFlag = currState and currState.starCount
    local nextIsDanGradingForFlag = currState and currState.isDanGrading
    local nextSeasonIdForFlag = currState and currState.seasonId
    local nextTabIndexForFlag = currState and currState.tabIndex
    local nextIsTopMasterForFlag = currState and currState.isTopMaster
    if currStarCountForFlag ~= nextStarCountForFlag or currIsDanGradingForFlag ~= nextIsDanGradingForFlag or currSeasonIdForFlag ~= nextSeasonIdForFlag or currTabIndexForFlag ~= nextTabIndexForFlag or currIsTopMasterForFlag ~= nextIsTopMasterForFlag then
      local nextContext = {}
      table.copy(currShowSpineFlagAnimContext, nextContext)
      nextContext.starCount = nextStarCountForFlag
      nextContext.isDanGrading = nextIsDanGradingForFlag
      nextContext.seasonId = nextSeasonIdForFlag
      nextContext.tabIndex = nextTabIndexForFlag
      nextContext.isTopMaster = nextIsTopMasterForFlag
      nextState.showSpineFlagAnimContext = nextContext
      self:SetState(nextState)
    end
  end
end

function UMG_PVP_FirstReward_C:OnSpineAssetPathChanged(atlasPath, skeletonDataPath)
  if atlasPath and skeletonDataPath then
    local context = {}
    local contextId = os.msTime()
    context.id = contextId
    context.atlasPath = atlasPath
    context.skeletonDataPath = skeletonDataPath
    context.phase = LoadSpineAssetContextPhase.LoadAssets
    local _, nextState = self:GetCurrAndNextState()
    nextState.loadSpineAssetContext = context
    nextState.atlasAsset = nil
    nextState.skeletonAsset = nil
    self:SetState(nextState)
  end
end

function UMG_PVP_FirstReward_C:HandleLoadAssetContextChanged(prevContext, currContext)
  if currContext then
    self:HandleLoadAssetContextNextPhase(currContext)
  end
end

function UMG_PVP_FirstReward_C:HandleLoadAssetContextNextPhase(context)
  local phase = context and context.phase
  if phase == LoadSpineAssetContextPhase.LoadAssets then
    self:HandleLoadSpineAssets(context)
  elseif phase == LoadSpineAssetContextPhase.WaitingForAssetLoading then
    self:HandleWaitingForAssetLoading(context)
  elseif phase == LoadSpineAssetContextPhase.AssetLoaded then
    self:HandleSpineAssetLoaded(context)
  elseif phase == LoadSpineAssetContextPhase.Complete then
    self:HandleSpineAssetComplete(context)
  end
end

function UMG_PVP_FirstReward_C:HandleLoadSpineAssets(context)
  local currContextId = context and context.id
  local nextContext = {}
  table.copy(context, nextContext)
  nextContext.phase = LoadSpineAssetContextPhase.WaitingForAssetLoading
  nextContext.isLoadAtlasLoading = true
  nextContext.isLoadSkeletonLoading = true
  local _, nextState = self:GetCurrAndNextState()
  nextState.loadSpineAssetContext = nextContext
  self:SetState(nextState)
  local atlasPath = context and context.atlasPath
  local skeletonDataPath = context and context.skeletonDataPath
  self:LoadPanelRes(atlasPath, 255, function(caller, request, asset)
    self:LoadAtlasComplete(currContextId, true, asset)
  end, function(caller, request, errorMessage)
    self:LoadAtlasComplete(currContextId, false, errorMessage)
  end)
  self:LoadPanelRes(skeletonDataPath, 255, function(caller, request, asset)
    self:LoadSkeletonDataComplete(currContextId, true, asset)
  end, function(caller, request, errorMessage)
    self:LoadSkeletonDataComplete(currContextId, false, errorMessage)
  end)
end

function UMG_PVP_FirstReward_C:HandleWaitingForAssetLoading(context)
  local currIsLoadAtlasCompleted = context and context.isLoadAtlasCompleted
  local currIsLoadSkeletonCompleted = context and context.isLoadSkeletonCompleted
  local currIsLoadingComplete = currIsLoadAtlasCompleted and currIsLoadSkeletonCompleted or false
  if currIsLoadingComplete then
    local _, nextState = self:GetCurrAndNextState()
    local nextContext = {}
    table.copy(context, nextContext)
    nextContext.phase = LoadSpineAssetContextPhase.AssetLoaded
    nextState.loadSpineAssetContext = nextContext
    self:SetState(nextState)
  end
end

function UMG_PVP_FirstReward_C:LoadAtlasComplete(contextId, ok, result1)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.loadSpineAssetContext
  local currContextId = currContext and currContext.id
  if contextId and currContextId == contextId then
    local asset, errorMessage
    if ok then
      asset = result1
    else
      errorMessage = result1
      Log.Error("[UMG_PVP_FirstReward_C:LoadAtlasComplete]", errorMessage)
    end
    local nextContext = {}
    table.copy(currContext, nextContext)
    nextContext.isLoadAtlasLoading = false
    nextContext.isLoadAtlasCompleted = true
    nextContext.atlasAsset = asset
    nextState.loadSpineAssetContext = nextContext
    Log.Info("UMG_PVP_FirstReward_C:LoadAtlasComplete", ok)
    self:SetState(nextState)
  end
end

function UMG_PVP_FirstReward_C:LoadSkeletonDataComplete(contextId, ok, result1)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.loadSpineAssetContext
  local currContextId = currContext and currContext.id
  if contextId and currContextId == contextId then
    local asset, errorMessage
    if ok then
      asset = result1
    else
      errorMessage = result1
      Log.Error("[UMG_PVP_FirstReward_C:LoadSkeletonDataComplete]", errorMessage)
    end
    local nextContext = {}
    table.copy(currContext, nextContext)
    nextContext.isLoadSkeletonLoading = false
    nextContext.isLoadSkeletonCompleted = true
    nextContext.skeletonAsset = asset
    nextState.loadSpineAssetContext = nextContext
    Log.Info("UMG_PVP_FirstReward_C:LoadSkeletonDataComplete", ok)
    self:SetState(nextState)
  end
end

function UMG_PVP_FirstReward_C:HandleSpineAssetLoaded(context)
  local atlasAsset = context and context.atlasAsset
  local skeletonAsset = context and context.skeletonAsset
  local _, nextState = self:GetCurrAndNextState()
  local nextContext = {}
  table.copy(context, nextContext)
  nextContext.phase = LoadSpineAssetContextPhase.Complete
  nextState.loadSpineAssetContext = nextContext
  if atlasAsset and skeletonAsset then
    nextState.atlasAsset = atlasAsset
    nextState.skeletonAsset = skeletonAsset
  else
    Log.Error("[UMG_PVP_FirstReward_C] Spine \232\181\132\230\186\144\229\138\160\232\189\189\229\164\177\232\180\165")
    nextState.atlasAsset = nil
    nextState.skeletonAsset = nil
  end
  Log.Info("UMG_PVP_FirstReward_C:HandleSpineAssetLoaded", atlasAsset, skeletonAsset)
  self:SetState(nextState)
end

function UMG_PVP_FirstReward_C:HandleSpineAssetComplete(context)
  local _, nextState = self:GetCurrAndNextState()
  nextState.loadSpineAssetContext = nil
  self:SetState(nextState)
end

function UMG_PVP_FirstReward_C:OnSpineAssetChanged(atlasAsset, skeletonAsset)
  if atlasAsset and skeletonAsset then
    self:SetupSpineWidget(atlasAsset, skeletonAsset)
  end
end

function UMG_PVP_FirstReward_C:HandleShowSpineFlagAnimContextChanged(context)
  local starCount = context and context.starCount
  local isDanGrading = context and context.isDanGrading
  local isTopMaster = context and context.isTopMaster
  if starCount then
    self:ShowInSpineWidget(starCount, isDanGrading, isTopMaster)
  end
end

function UMG_PVP_FirstReward_C:GetProps()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetProps() or {}
end

function UMG_PVP_FirstReward_C:GetState()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetState() or {}
end

function UMG_PVP_FirstReward_C:GetCurrAndNextState()
  local stateManager = self.stateManager
  if stateManager then
    return stateManager:GetCurrAndNextState()
  end
  return {}, {}
end

function UMG_PVP_FirstReward_C:SetProps(nextProps)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetProps(nextProps)
  end
end

function UMG_PVP_FirstReward_C:SetState(nextState)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetState(nextState)
  end
end

return UMG_PVP_FirstReward_C

local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_PVPSharing_C = _G.NRCPanelBase:Extend("UMG_PVPSharing_C")
local LoadSpineAssetContextPhase = {
  LoadAssets = 1,
  WaitingForAssetLoading = 2,
  AssetLoaded = 3,
  Complete = 4
}

function UMG_PVPSharing_C:OnActive()
end

function UMG_PVPSharing_C:OnDeactive()
end

function UMG_PVPSharing_C:OnAddEventListener()
  self:AddButtonListener(self.AccessAuthorityBtn, self.OnAccessAuthorityBtnClick)
  self.SpineFlag.AnimationStart:Add(self, self.OnSpineAnimationStart)
end

function UMG_PVPSharing_C:OnRemoveEventListener()
  self.SpineFlag.AnimationStart:Clear()
end

function UMG_PVPSharing_C:InitData(data, index, tableDatas, startNum)
  self.RankName:SetText("")
  self.TableDatas = tableDatas or {}
  self.TableIndex = index
  self.CruData = data
  self.StarNum = startNum
  self:ShowPlayer()
  local rank_conf = PVPRankedMatchModuleUtils.GetPvpRankConf(startNum)
  if rank_conf then
    self.RankName:SetText(rank_conf.name)
  end
  if nil == index and nil == data then
    self.VerticalBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.VerticalBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.VerticalBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.VerticalBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Options:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_54:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DataSwitcher:SetActiveWidgetIndex(1)
    return
  end
  self.Popup_Downward.List_title:InitList(self.TableDatas)
  if not self.TableIndex then
    if self.TableDatas and #self.TableDatas > 0 then
      self.Popup_Downward.List_title:SelectItemByIndex(0)
    end
  else
    self.Popup_Downward.List_title:SelectItemByIndex(self.TableIndex)
  end
end

function UMG_PVPSharing_C:OnConstruct()
  local stateManager = WidgetStateManager()
  local initState = {}
  initState.isFlagShow = false
  local initOption = {}
  initOption.owner = self
  initOption.UpdateDerivedState = self.UpdateDerivedState
  initOption.RenderWidget = self.RenderWidget
  initOption.OnWidgetDidUpdate = self.OnWidgetDidUpdate
  initOption.initState = initState
  stateManager:Init(initOption)
  self.stateManager = stateManager
  self.season_record_data = {}
  self:OnAddEventListener()
  _G.NRCModuleManager:GetModule("PVPRankedMatchModule"):RegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpSeasonRecordData, self.OnSetPvpSeasonRecordData)
  _G.NRCEventCenter:RegisterEvent("UMG_PVPShare_C", self, NRCGlobalEvent.OnComboBoxSelectChanged, self.OnSeasonRecordSelected)
end

function UMG_PVPSharing_C:OnDestruct()
  local stateManager = self.stateManager
  if stateManager then
    stateManager:DeInit()
  end
  self:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnComboBoxSelectChanged, self.OnSeasonRecordSelected)
  _G.NRCModuleManager:GetModule("PVPRankedMatchModule"):UnRegisterEvent(self, PVPRankedMatchModuleEvent.SetPvpSeasonRecordData)
end

function UMG_PVPSharing_C:ShowPlayer()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local CardInfo = PlayerInfo.additional_data.card_brief_info
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
  self.Grade:SetText(playerName)
  self.Grade_1:SetText(playerUin)
  if CardInfo then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(CardInfo.card_icon_selected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BigHeadIcon256/", AvatarPath, AvatarPath)
      self.HeadPortrait:SetPath(AvatarPath)
    end
  else
    Log.Debug("\230\178\161\230\156\137\233\187\152\232\174\164\229\144\141\231\137\135\229\164\180\229\131\143\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\144\142\229\143\176\230\149\176\230\141\174")
  end
end

function UMG_PVPSharing_C:OnSetPvpSeasonRecordData(data)
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

function UMG_PVPSharing_C:OnAccessAuthorityBtnClick()
  if self.Popup_Downward:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.ShowShareUIPanelCloseMoreBtn, true)
    self.Popup_Downward:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Popup_Downward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVPSharing_C:OnSeasonRecordSelected(index, data_list)
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
  if timestamp <= cur_timestamp and self.season_record_data[self.sort_season_data.id] == nil then
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendPVPSeasonRecordQueryReq, self.sort_season_data.id)
  else
  end
  goto lbl_85
  ::lbl_85::
  local _, nextState = self:GetCurrAndNextState()
  nextState.selectRankSeasonInfo = recordSeasonData
  self:SetState(nextState)
end

function UMG_PVPSharing_C:RefreshSeasonRecord(record_season_data)
  local rank_star = self.StarNum or 1
  local battle_cnt = record_season_data and record_season_data.battle_cnt or 0
  local petListItemList = {}
  local magicListItemList = {}
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
    rank_star = record_season_data and record_season_data.rank_star
    petListItemList = pet_use_info
    magicListItemList = record_season_data and record_season_data.magic_used or {}
    DataSwitcherIndex = 0
  end
  self.SeasonMatchesText:SetText(tostring(battle_cnt))
  self.VictoriesText:SetText(tostring(win_count))
  self.WinningRateText:SetText(tostring(winRate) .. "%")
  self.HighestWinningStreakText:SetText(tostring(max_win_streak))
  self.PetList:InitGridView(petListItemList)
  self.PetList_1:InitGridView(magicListItemList)
  self.DataSwitcher:SetActiveWidgetIndex(DataSwitcherIndex)
end

function UMG_PVPSharing_C:ShowInSpineWidget(rank_star, is_dan_grading, is_top_master)
  local PVPRankedMatchModuleData = _G.NRCModuleManager:GetModule("PVPRankedMatchModule"):GetData("PVPRankedMatchModuleData")
  is_dan_grading = is_dan_grading or false
  rank_star = PVPRankedMatchModuleUtils.CorrectionRankStar(rank_star)
  local incomingGradeAnimConf = PVPRankedMatchModuleData:GetGradingAnimConfig(rank_star, is_top_master, is_dan_grading)
  self.SpineFlag:SetToSetupPose()
  self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.show, false)
end

function UMG_PVPSharing_C:OnSpineAnimationStart(entry)
  PVPRankedMatchModuleUtils.OnFlagSpineAnimationStart(entry)
end

function UMG_PVPSharing_C:OnTick(deltaTime)
  if self.SpineFlag then
    self.SpineFlag:Tick(deltaTime, true)
  end
end

function UMG_PVPSharing_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevStarCount = prevState and prevState.starCount
  local currStarCount = currState and currState.starCount
  local prevSeasonId = prevState and prevState.seasonId
  local currSeasonId = currState and currState.seasonId
  local prevLoadSpineAssetContext = prevState and prevState.loadSpineAssetContext
  local currLoadSpineAssetContext = currState and currState.loadSpineAssetContext
  local prevAtlasAsset = prevState and prevState.atlasAsset
  local currAtlasAsset = currState and currState.atlasAsset
  local prevSkeletonAsset = prevState and prevState.skeletonAsset
  local currSkeletonAsset = currState and currState.skeletonAsset
  local prevSelectRankSeasonInfo = prevState and prevState.selectRankSeasonInfo
  local currSelectRankSeasonInfo = currState and currState.selectRankSeasonInfo
  local prevIsSelectRankSeasonInfoTopMaster = prevState and prevState.isSelectRankSeasonInfoTopMaster
  local currIsSelectRankSeasonInfoTopMaster = currState and currState.isSelectRankSeasonInfoTopMaster
  if prevStarCount ~= currStarCount or prevSeasonId ~= currSeasonId then
    UMG_PVPSharing_C.DeriveSpineAssetPath(currStarCount, currSeasonId, derivedState)
  end
  if prevLoadSpineAssetContext ~= currLoadSpineAssetContext or prevAtlasAsset ~= currAtlasAsset or prevSkeletonAsset ~= currSkeletonAsset then
    UMG_PVPSharing_C.DeriveSpineFlagShow(currLoadSpineAssetContext, currAtlasAsset, currSkeletonAsset, derivedState)
  end
  if prevStarCount ~= currStarCount then
    UMG_PVPSharing_C.DerivePvpQualifierStarShow(currStarCount, derivedState)
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    UMG_PVPSharing_C.DeriveStarCount(currSelectRankSeasonInfo, derivedState)
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    UMG_PVPSharing_C.DeriveSeasonId(currSelectRankSeasonInfo, derivedState)
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    UMG_PVPSharing_C.DeriveSelectSeasonInfoIsTopMaster(currSelectRankSeasonInfo, derivedState)
  end
  if prevIsSelectRankSeasonInfoTopMaster ~= currIsSelectRankSeasonInfoTopMaster then
    UMG_PVPSharing_C.DeriveIsTopMaster(currIsSelectRankSeasonInfoTopMaster, derivedState)
  end
end

function UMG_PVPSharing_C.DeriveSpineAssetPath(starCount, seasonId, derivedState)
  local pvpRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(starCount)
  local atlasPath, skeletonDataPath
  atlasPath, skeletonDataPath = PVPRankedMatchModuleUtils.GetSpineAssetPathsSeasonIdInRankConf(pvpRankConf, seasonId)
  derivedState.atlasPath = atlasPath or UEPath.PVP_FlagSpineAtlasAsset
  derivedState.skeletonDataPath = skeletonDataPath or UEPath.PVP_FlagSpineSkeletonDataAsset
end

function UMG_PVPSharing_C.DeriveSpineFlagShow(loadAssetContext, atlasAsset, skeletonDataAsset, derivedState)
  local isShow = false
  if atlasAsset and skeletonDataAsset then
    isShow = true
  end
  if loadAssetContext then
    isShow = false
  end
  derivedState.isFlagShow = isShow
end

function UMG_PVPSharing_C.DerivePvpQualifierStarShow(starCount, derivedState)
  local isShow = false
  local isMaxStar = PVPRankedMatchModuleUtils.IsMaxRankStar(starCount)
  if isMaxStar then
    isShow = true
  end
  derivedState.isPvpQualifierStarShow = isShow
end

function UMG_PVPSharing_C.DeriveStarCount(selectRankSeasonInfo, derivedState)
  local starCount
  if selectRankSeasonInfo then
    starCount = selectRankSeasonInfo and selectRankSeasonInfo.rank_star or 1
  end
  if starCount then
    derivedState.starCount = starCount
  end
end

function UMG_PVPSharing_C.DeriveSeasonId(selectRankSeasonInfo, derivedState)
  local seasonId
  local rankSeasonId = selectRankSeasonInfo and selectRankSeasonInfo.season_id
  if rankSeasonId then
    seasonId = rankSeasonId
  end
  if seasonId then
    derivedState.seasonId = seasonId
  end
end

function UMG_PVPSharing_C.DeriveSelectSeasonInfoIsTopMaster(seasonInfo, derivedState)
  local isSelectRankSeasonInfoTopMaster = false
  local rankOrder = seasonInfo and seasonInfo.rank_order
  local masterScore = seasonInfo and seasonInfo.master_score
  local pvp_param12Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_param12", false)
  local minMasterScore = pvp_param12Conf and pvp_param12Conf.num
  local pvp_param13Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_param13", false)
  local maxRankOrder = pvp_param13Conf and pvp_param13Conf.num
  if minMasterScore and masterScore and masterScore >= minMasterScore and maxRankOrder and rankOrder and rankOrder <= maxRankOrder then
    isSelectRankSeasonInfoTopMaster = true
  end
  derivedState.isSelectRankSeasonInfoTopMaster = isSelectRankSeasonInfoTopMaster
end

function UMG_PVPSharing_C.DeriveIsTopMaster(isSelectSeasonInfoTopMaster, derivedState)
  local isTopMaster = false
  isTopMaster = isSelectSeasonInfoTopMaster or false
  derivedState.isTopMaster = isTopMaster
end

function UMG_PVPSharing_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevIsFlagShow = prevState and prevState.isFlagShow or false
  local currIsFlagShow = currState and currState.isFlagShow or false
  local prevStarCount = prevState and prevState.starCount
  local currStarCount = currState and currState.starCount
  local prevIsPvpQualifierStarShow = prevState and prevState.isPvpQualifierStarShow or false
  local currIsPvpQualifierStarShow = currState and currState.isPvpQualifierStarShow or false
  if prevIsFlagShow ~= currIsFlagShow or prevKey ~= currKey then
    self:RenderSpineFlagShow(currIsFlagShow)
  end
  if prevStarCount ~= currStarCount then
    self:RenderRankName(currStarCount)
  end
  if prevIsPvpQualifierStarShow ~= currIsPvpQualifierStarShow or prevKey ~= currKey then
    self:RenderPvpQualifierStarShow(currIsPvpQualifierStarShow)
  end
end

function UMG_PVPSharing_C:RenderSpineFlagShow(isShow)
  local visibility = UE.ESlateVisibility.Collapsed
  if isShow then
    visibility = UE.ESlateVisibility.SelfHitTestInvisible
  end
  self.SpineFlag:SetVisibility(visibility)
end

function UMG_PVPSharing_C:RenderRankName(rankStar)
  local rankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(rankStar)
  local rankConfName = rankConf and rankConf.name
  if rankConfName then
    self.RankName:SetText(rankConfName)
  end
end

function UMG_PVPSharing_C:RenderPvpQualifierStarShow(isShow)
  local visibility = UE.ESlateVisibility.Collapsed
  if isShow then
    visibility = UE.ESlateVisibility.SelfHitTestInvisible
  end
  self.PVPQualifier_Star:SetVisibility(visibility)
end

function UMG_PVPSharing_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  Log.Debug("UMG_PVPSharing_C:OnWidgetDidUpdate")
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
  if prevAtlasAsset ~= currAtlasAsset or prevSkeletonAsset ~= currSkeletonAsset or prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo or prevLoadSpineAssetContext ~= currLoadSpineAssetContext then
    self:SyncStateForShowFlag()
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo then
    self:RefreshSeasonRewardForRecord(currSelectRankSeasonInfo)
  end
  if prevSelectRankSeasonInfo ~= currSelectRankSeasonInfo or prevKey ~= currKey then
    self:RefreshSeasonRecord(currSelectRankSeasonInfo)
  end
  if prevShowSpineFlagAnimContext ~= currShowSpineFlagAnimContext then
    self:HandleShowSpineFlagAnimContextChanged(currShowSpineFlagAnimContext)
  end
end

function UMG_PVPSharing_C:SyncStateForShowFlag()
  local currState, nextState = self:GetCurrAndNextState()
  local currLoadSpineAssetContext = currState and currState.loadSpineAssetContext
  local currAtlasAsset = currState and currState.atlasAsset
  local currSkeletonAsset = currState and currState.skeletonAsset
  local currSelectRankSeasonInfo = currState and currState.selectRankSeasonInfo
  if not currLoadSpineAssetContext and currAtlasAsset and currSkeletonAsset and currSelectRankSeasonInfo then
    local currShowSpineFlagAnimContext = currState and currState.showSpineFlagAnimContext
    local currStarCountForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.starCount
    local currIsDanGradingForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.isDanGrading
    local currSeasonIdForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.seasonId
    local currIsTopMasterForFlag = currShowSpineFlagAnimContext and currShowSpineFlagAnimContext.isTopMaster
    local nextStarCountForFlag = currState and currState.starCount
    local nextIsDanGradingForFlag = currState and currState.isDanGrading
    local nextSeasonIdForFlag = currState and currState.seasonId
    local nextIsTopMasterForFlag = currState and currState.isTopMaster
    if currStarCountForFlag ~= nextStarCountForFlag or currIsDanGradingForFlag ~= nextIsDanGradingForFlag or currSeasonIdForFlag ~= nextSeasonIdForFlag or currIsTopMasterForFlag ~= nextIsTopMasterForFlag then
      local nextContext = {}
      table.copy(currShowSpineFlagAnimContext, nextContext)
      nextContext.starCount = nextStarCountForFlag
      nextContext.isDanGrading = nextIsDanGradingForFlag
      nextContext.seasonId = nextSeasonIdForFlag
      nextContext.isTopMaster = nextIsTopMasterForFlag
      nextState.showSpineFlagAnimContext = nextContext
      self:SetState(nextState)
    end
  end
end

function UMG_PVPSharing_C:OnSpineAssetPathChanged(atlasPath, skeletonDataPath)
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

function UMG_PVPSharing_C:HandleLoadAssetContextChanged(prevContext, currContext)
  if currContext then
    self:HandleLoadAssetContextNextPhase(currContext)
  end
end

function UMG_PVPSharing_C:HandleLoadAssetContextNextPhase(context)
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

function UMG_PVPSharing_C:HandleLoadSpineAssets(context)
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

function UMG_PVPSharing_C:HandleWaitingForAssetLoading(context)
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

function UMG_PVPSharing_C:LoadAtlasComplete(contextId, ok, result1)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.loadSpineAssetContext
  local currContextId = currContext and currContext.id
  if contextId and currContextId == contextId then
    local asset, errorMessage
    if ok then
      asset = result1
    else
      errorMessage = result1
      Log.Error("[UMG_PVPSharing_C:LoadAtlasComplete]", errorMessage)
    end
    local nextContext = {}
    table.copy(currContext, nextContext)
    nextContext.isLoadAtlasLoading = false
    nextContext.isLoadAtlasCompleted = true
    nextContext.atlasAsset = asset
    nextState.loadSpineAssetContext = nextContext
    Log.Info("UMG_PVPSharing_C:LoadAtlasComplete", ok)
    self:SetState(nextState)
  end
end

function UMG_PVPSharing_C:LoadSkeletonDataComplete(contextId, ok, result1)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.loadSpineAssetContext
  local currContextId = currContext and currContext.id
  if contextId and currContextId == contextId then
    local asset, errorMessage
    if ok then
      asset = result1
    else
      errorMessage = result1
      Log.Error("[UMG_PVPSharing_C:LoadSkeletonDataComplete]", errorMessage)
    end
    local nextContext = {}
    table.copy(currContext, nextContext)
    nextContext.isLoadSkeletonLoading = false
    nextContext.isLoadSkeletonCompleted = true
    nextContext.skeletonAsset = asset
    nextState.loadSpineAssetContext = nextContext
    Log.Info("UMG_PVPSharing_C:LoadSkeletonDataComplete", ok)
    self:SetState(nextState)
  end
end

function UMG_PVPSharing_C:HandleSpineAssetLoaded(context)
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
    Log.Error("[UMG_PVPSharing_C] Spine \232\181\132\230\186\144\229\138\160\232\189\189\229\164\177\232\180\165")
    nextState.atlasAsset = nil
    nextState.skeletonAsset = nil
  end
  Log.Info("UMG_PVPSharing_C:HandleSpineAssetLoaded", atlasAsset, skeletonAsset)
  self:SetState(nextState)
end

function UMG_PVPSharing_C:HandleSpineAssetComplete(context)
  local _, nextState = self:GetCurrAndNextState()
  nextState.loadSpineAssetContext = nil
  self:SetState(nextState)
end

function UMG_PVPSharing_C:OnSpineAssetChanged(atlasAsset, skeletonAsset)
  if atlasAsset and skeletonAsset then
    self:SetupSpineWidget(atlasAsset, skeletonAsset)
  end
end

function UMG_PVPSharing_C:SetupSpineWidget(atlasAsset, skeletonAsset)
  local spineWidget = self.SpineFlag
  spineWidget:ClearTrack(0)
  spineWidget.skeletondata = skeletonAsset
  spineWidget.atlas = atlasAsset
  spineWidget:LuaSynchronizeProperties()
end

function UMG_PVPSharing_C:HandleShowSpineFlagAnimContextChanged(context)
  local starCount = context and context.starCount
  local isDanGrading = context and context.isDanGrading
  local isTopMaster = context and context.isTopMaster
  if starCount then
    self:ShowInSpineWidget(starCount, isDanGrading, isTopMaster)
  end
end

function UMG_PVPSharing_C:RefreshSeasonRewardForRecord(selectRankSeasonInfo)
  local rankStar = selectRankSeasonInfo and selectRankSeasonInfo.rank_star or 1
  local isMaxRankStar = rankStar and PVPRankedMatchModuleUtils.IsMaxRankStar(rankStar)
  if isMaxRankStar then
    local option = self.PVPQualifier_Star.GetSeasonHistoryStartIndexOption(selectRankSeasonInfo)
    self.PVPQualifier_Star:SwitcherStarIndex(option)
  end
end

function UMG_PVPSharing_C:GetProps()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetProps() or {}
end

function UMG_PVPSharing_C:SetProps(nextProps)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetProps(nextProps)
  end
end

function UMG_PVPSharing_C:GetState()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetState() or {}
end

function UMG_PVPSharing_C:SetState(nextState)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetState(nextState)
  end
end

function UMG_PVPSharing_C:GetCurrAndNextState()
  local stateManager = self.stateManager
  if stateManager then
    return stateManager:GetCurrAndNextState()
  end
  return {}, {}
end

return UMG_PVPSharing_C

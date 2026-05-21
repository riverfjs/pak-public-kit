local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_Victory_C = _G.NRCPanelBase:Extend("UMG_Battle_Victory_C")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
UMG_Battle_Victory_C.PKState = {
  ENUM_REFUSE = -1,
  ENUM_NONE = 0,
  ENUM_WAIT_SERVER = 1,
  ENUM_PK_AGAIN = 2
}

function UMG_Battle_Victory_C:OnActive(param)
  _G.NRCAudioManager:BatchSetState("UI_Music;UI_Music;UI_Type;PVP_End")
  _G.BattleEventCenter:Bind(self, BattleEvent.PK_AGAIN)
  self:OnAddEventListener()
  self.Text_Hint:SetShowLockIcon(false)
  self.Text_Hint:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("pvp_not_fight_again_desc").msg)
  self.Btn_DiscussAgain:SetTitleTextAndIcon(nil, nil, nil, nil, _G.DataConfigManager:GetLocalizationConf("pvp_fightend_again_desc").msg)
  if not param then
    self.Switcher:SetActiveWidgetIndex(2)
    return
  end
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  self.FinishData = param
  self.ChangeToAgain = false
  self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_NONE
  self.EnemyState = UMG_Battle_Victory_C.PKState.ENUM_NONE
  self.BattleRecord = {
    self.Tips_1,
    self.Tips_2,
    self.Tips_3,
    self.Tips_4,
    self.Tips_5,
    self.Tips_6
  }
  self.CanvasPanelTitleRetainerBox:SetRetainRendering(true)
  if BattleUtils.IsPvp() or _G.EnableFakePVPRecord then
    self:InitInfo()
  elseif BattleUtils.IsNpcChallenge() or BattleUtils.IsLeaderChallenge() then
    if not self.FinishData.settle_info or not self.FinishData.settle_info.pve_add_info then
      self:OnClickClose()
    else
      self:InitNpcChallengeInfo()
    end
  end
  if self:IsEnableDebugFillMaskUiImage() then
    self:AddDebugFillMaskUiImage()
  end
end

function UMG_Battle_Victory_C:OnTick(DeltaTime)
  self:UpdateSceneViewportSizeAndScale()
end

function UMG_Battle_Victory_C:ShowFastWinInfo()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenPVPCeleritCarnetyPanel, self.FinishData, self, self.NpcChallengeClosePanel)
end

function UMG_Battle_Victory_C:OnAnimationFinished(anim)
  if anim == self.ShouLing_Out then
    self:NpcChallengeOutAnimEndClose()
  end
end

function UMG_Battle_Victory_C:NpcChallengeOutAnimEndClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  local activityId = self.FinishData.settle_info.pve_add_info.activity_id
  self.activityId = activityId
  local ActivityConf = _G.DataConfigManager:GetActivityConf(activityId)
  self.activityConf = ActivityConf
  self.challenge_level_id = self.FinishData.settle_info.pve_add_info.challenge_level_id
  local activity_type = self.activityConf.activity_type
  local challenge_level_id = self.FinishData.settle_info.pve_add_info.challenge_level_id
  if activity_type == Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT then
    _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.SetLeveBattleSilhouette)
    self:OnClickClose()
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1192, "UMG_Battle_VictoryFailure_C:NpcChallengeOutAnimEndClose")
    _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.SetWillOpenLeveSelect)
    self:TryExitBossChallenge()
  end
end

function UMG_Battle_Victory_C:TryExitBossChallenge()
  local Request = ProtoMessage:newZoneExitChallengeReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_EXIT_CHALLENGE_REQ, Request, self, self.OnLeaveDungeonRsp)
end

function UMG_Battle_Victory_C:OnLeaveDungeonRsp()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleAdditionalTarget)
  self:OnClickClose()
end

function UMG_Battle_Victory_C:NpcChallengeClosePanel()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    self:DoClose()
    return
  end
  self:PlayAnimation(self.ShouLing_Out)
end

function UMG_Battle_Victory_C:InitNpcChallengeInfo()
  self.CanvasPanelTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetActiveWidgetIndex(4)
  self:RemoveButtonListener(self.BtnClose, self.ShowExistPanel)
  local pve_add_info = self.FinishData.settle_info.pve_add_info
  if not pve_add_info then
    Log.Error("\229\145\168\230\156\159\230\128\167\230\140\145\230\136\152\231\187\147\231\174\151\231\155\184\229\133\179\229\141\143\232\174\174 ZoneBattleFinishNotify.settle_info.pve_add_info\230\149\176\230\141\174\228\184\162\229\164\177\239\188\140\228\191\157\231\149\153\232\180\166\229\143\183\227\128\129\230\156\141\229\138\161\229\153\168\227\128\129\230\136\152\230\150\151\230\151\182\233\151\180 \231\155\184\229\133\179\228\191\161\230\129\175 \231\187\153\229\144\142\229\143\176\231\156\139\228\184\139\230\149\176\230\141\174")
    return
  end
  if pve_add_info.pre_level_ids and #pve_add_info.pre_level_ids > 0 then
    self:RemoveButtonListener(self.BtnClose, self.ShowFastWinInfo)
    self:AddButtonListener(self.BtnClose, self.ShowFastWinInfo)
  else
    self:RemoveButtonListener(self.BtnClose, self.NpcChallengeClosePanel)
    self:AddButtonListener(self.BtnClose, self.NpcChallengeClosePanel)
  end
  self.Btn_report:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local CurRound = _G.BattleManager:GetCurRound()
  self.Number_1:SetText(CurRound)
  self:PlayAnimation(self.ShouLing_in)
  if _G.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin() then
    local titleStr = _G.DataConfigManager:GetLocalizationConf("challenge_text_4").msg
    self.NpcChallengeTitle:SetText(titleStr)
    self.FinishList:InitGridView(pve_add_info.task_infos)
    if pve_add_info.is_unfinish then
      local ActivityConf = _G.DataConfigManager:GetActivityConf(pve_add_info.activity_id)
      local baseId = pve_add_info.challenge_level_id
      local ChallengeConf
      if ActivityConf.activity_type == Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT then
        ChallengeConf = _G.DataConfigManager:GetNpcChallengeConf(baseId)
      elseif ActivityConf.activity_type == Enum.ActivityType.ATP_BOSS_CHALLENGE_EVENT then
        ChallengeConf = _G.DataConfigManager:GetBossChallengeConf(baseId)
      end
      if ChallengeConf then
        self.ClearanceReward:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NRCText_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NRCImage_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:SetInfo(ChallengeConf.reward_pass)
      else
        self.ClearanceReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NRCText_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NRCImage_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.ClearanceReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCText_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Text_Name:SetText(_G.BattleManager.battlePawnManager:GetPlayerMyTeam().roleInfo.base.name)
  else
    self.NpcChallengeTitle:SetText(LuaText.leader_battle_ui_win_tip)
    self.ClearanceReward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Victory_C:SetInfo(RewardId)
  local RewardList = {}
  local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId)
  for i, reward in ipairs(RewardConf.RewardItem) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = reward.Type
    rewards.itemId = reward.Id
    rewards.itemNum = reward.Count
    rewards.bShowNum = true
    rewards.bShowTip = true
    table.insert(RewardList, rewards)
  end
  self.ClearanceReward:InitGridView(RewardList)
end

function UMG_Battle_Victory_C:NpcChallengeShowExistPanel()
  self.Switcher:SetActiveWidgetIndex(2)
end

function UMG_Battle_Victory_C:ShowExistPanel()
  self.Switcher:SetActiveWidgetIndex(1)
end

function UMG_Battle_Victory_C:InitInfo()
  self.Switcher:SetActiveWidgetIndex(0)
  self.ResultCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BonusPointsBlock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  for i, v in ipairs(self.BattleRecord) do
    v:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self.Btn_report:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local lastHitPetId = BattleManager.battlePawnManager.TeamatePlayer.FashionData.LastHitGID
  local lastHitBaseId = BattleManager.battlePawnManager.TeamatePlayer.FashionData.LastHitPetBaseId
  local suitPetCard = BattleManager.battlePawnManager:GetCardByCommonGuid(BattleEnum.Team.ENUM_TEAM, lastHitPetId)
  if suitPetCard and suitPetCard.petBaseConf.id ~= lastHitBaseId then
    suitPetCard:RefreshByBaseConf(lastHitBaseId)
  end
  if not BattleUtils.IsWatchingBattle() and suitPetCard and suitPetCard.AppearancePath.PVPOverSuiId > 0 then
    self.SuitInfo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local tip = _G.DataConfigManager:GetLocalizationConf("fashion_suits_countpvp").msg
    local fullTip = string.format(tip, suitPetCard.name, "")
    self.NRCText_2:SetText(fullTip)
    if self.FinishData and self.FinishData.fashion_suit_info then
      self.NRCText:SetText(self.FinishData.fashion_suit_info.petbase_pvp_win_num or 0)
    else
      self.NRCText:SetText(0)
    end
  else
    self.SuitInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _G.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin() then
    self.VictoryPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.Failure:SetVisibility(UE4.ESlateVisibility.Collapsed)
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1276, "UMG_Battle_Victory_C:Show Victory")
    self:PlayAnimation(self.open)
    self:PlayAnimation(self.open_2)
    self.Text_Name:SetText(_G.BattleManager.battlePawnManager:GetPlayerMyTeam().roleInfo.base.name)
  else
    self.VictoryPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Failure:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.open_2)
    self.Text_Name:SetText(_G.BattleManager.battlePawnManager:GetPlayerEnemyTeam().roleInfo.base.name)
  end
  self.playId = _G.BattleManager.battlePawnManager:GetPlayerMyTeam().guid
  self.EnemyUIN = _G.BattleManager.battlePawnManager:GetPlayerEnemyTeam().guid
  self.RecordUpdateNumber = 1
  self.RecordUpdateUINumber = 1
  self:CombineRecordMedal()
  self:RefreshRecord()
  self:RefreshWeeklyBonusPoints()
  self:RefreshDailyFirstVictory()
  self:RefreshRandomBonusPoints()
  self:RefreshWatchBattleInfo()
end

function UMG_Battle_Victory_C:CombineRecordMedal()
  local scoreMap = {}
  if self.FinishData then
    if self.FinishData.pvp_score_records and #self.FinishData.pvp_score_records > 0 then
      for i = 1, #self.FinishData.pvp_score_records do
        local data = self.FinishData.pvp_score_records[i]
        if data.attack_uin == self.playId and data.attack_pet_id then
          local record = scoreMap[data.attack_pet_id]
          if not record then
            scoreMap[data.attack_pet_id] = data
            data.needShowMedal = true
          end
        end
      end
    end
    if self.FinishData.settle_info and self.FinishData.settle_info.monster_info and #self.FinishData.settle_info.monster_info > 0 then
      for i = 1, #self.FinishData.settle_info.monster_info do
        local monsterData = self.FinishData.settle_info.monster_info[i]
        if monsterData and monsterData.uin == self.playId and monsterData.medal_cond_complete and #monsterData.medal_cond_complete > 0 then
          local scoreData = scoreMap[monsterData.pet_id]
          if not scoreData then
            local newscoreData = ProtoMessage:newPvpScoreRecord()
            newscoreData.attack_uin = monsterData.uin
            newscoreData.attack_pet_id = monsterData.pet_id
            newscoreData.needShowMedal = true
            if not self.FinishData.pvp_score_records then
              self.FinishData.pvp_score_records = {}
            end
            table.insert(self.FinishData.pvp_score_records, newscoreData)
          end
        end
      end
    end
  end
end

function UMG_Battle_Victory_C:RefreshRecord()
  if self.FinishData and self.FinishData.pvp_score_records then
    for i = 1, #self.FinishData.pvp_score_records do
      local data = self.FinishData.pvp_score_records[i]
      if data.attack_uin == self.playId and self.RecordUpdateUINumber <= #self.BattleRecord then
        if 1 == self.RecordUpdateUINumber then
          self.ResultCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.CanvasPanel_title:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
        local ui = self.BattleRecord[self.RecordUpdateUINumber]
        self.RecordUpdateUINumber = self.RecordUpdateUINumber + 1
        if ui then
          ui:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
          ui:Show(data, i, self.FinishData.settle_info.monster_info)
        end
      end
    end
    if self.RecordUpdateUINumber > 1 then
      self:DelaySeconds(1.5, self.ShowRecordOver, self)
    else
      self:ShowRecordOver()
    end
  else
    self:ShowRecordOver()
  end
  self:PlayAnimation(self.open)
end

function UMG_Battle_Victory_C:UpdateNextRecord()
end

function UMG_Battle_Victory_C:RefreshWeeklyBonusPoints()
  if not self.FinishData then
    return
  end
  if self.FinishData.max_pvp_score and self.FinishData.total_pvp_score then
    self.BonusPointsBlock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    local isFull = self.FinishData.total_pvp_score >= self.FinishData.max_pvp_score
    local numberText = string.format("%d/%d", self.FinishData.total_pvp_score, self.FinishData.max_pvp_score)
    self.Number:SetText(numberText)
    BattleUtils.SetPvpScoreIcon(self.icon)
    local fullImageVisibility = isFull and UE4.ESlateVisibility.HitTestInvisible or UE4.ESlateVisibility.Collapsed
    self.Full:SetVisibility(fullImageVisibility)
  end
end

local function random_permutation(n)
  local arr = {}
  for i = 1, n do
    arr[i] = i
  end
  for i = n, 2, -1 do
    local j = math.random(1, i)
    arr[i], arr[j] = arr[j], arr[i]
  end
  return arr
end

function UMG_Battle_Victory_C:RefreshWatchBattleInfo()
  local needShowWatchBattleInfo = BattleUtils.IsPvp()
  local battleType = _G.BattleManager.battleRuntimeData.battleType
  if battleType == Enum.BattleType.BT_PVP or battleType == Enum.BattleType.BT_PVP_SCARE then
    needShowWatchBattleInfo = false
  end
  if not needShowWatchBattleInfo then
    return
  end
  local FinishData = self.FinishData
  local observerRecords = FinishData and FinishData.observer_pvp_score_records or {}
  local observerInfoList = _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.GetObserverBriefInfoList)
  local uinToInfo = {}
  for i, info in ipairs(observerInfoList) do
    uinToInfo[info.uin] = info
  end
  local uinToScore = {}
  for i, scoreRecord in ipairs(observerRecords) do
    uinToScore[scoreRecord.uin] = scoreRecord
  end
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local isWin = _G.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin()
  local ProtagonistPerspectiveVisibility = UE.ESlateVisibility.Collapsed
  local ViewingPerspectiveVisibility = UE.ESlateVisibility.Collapsed
  local TextNumberSpectators1Visibility = UE.ESlateVisibility.Collapsed
  local TextSpectatorRewardNumberText = ""
  local TextNumberSpectators = ""
  local TextReward = ""
  local watchRecordTweenInAnim
  local SpectatorsItemDataList = {}
  if BattleUtils.IsWatchingBattle() then
    local playerScoreRecord = uinToScore[playerUin]
    local score = playerScoreRecord and playerScoreRecord.score or 0
    TextSpectatorRewardNumberText = string.format("x%s", tostring(score))
    if not isWin then
      TextNumberSpectators1Visibility = UE.ESlateVisibility.SelfHitTestInvisible
    end
    ViewingPerspectiveVisibility = UE.ESlateVisibility.SelfHitTestInvisible
    watchRecordTweenInAnim = self.obtained_in
    self.watchRecordTweenOutAnim = self.obtained_out
  else
    local watchCount = #observerRecords
    local rewardTotalCount = 0
    for i, record in ipairs(observerRecords) do
      local score = record and record.score or 0
      rewardTotalCount = rewardTotalCount + score
      local uin = record and record.uin or 0
      local observerBriefInfo = uinToInfo[uin]
      local dataItem = {}
      dataItem.uin = uin
      dataItem.observerBriefInfo = observerBriefInfo
      dataItem.scoreRecord = record
      dataItem.isWin = isWin
      table.insert(SpectatorsItemDataList, dataItem)
    end
    local TextNumberSpectatorsConf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character30", true)
    local TextNumberSpectatorsConfStr = TextNumberSpectatorsConf and TextNumberSpectatorsConf.str or ""
    TextNumberSpectators = string.format(TextNumberSpectatorsConfStr, tostring(watchCount))
    TextReward = string.format("x%s", tostring(rewardTotalCount))
    local showMax = 999999999
    if rewardTotalCount > showMax then
      TextReward = string.format("x%s+", tostring(showMax))
    end
    BattleUtils.SetPvpScoreIcon(self.NRCImage_7)
    if #SpectatorsItemDataList > 0 then
      ProtagonistPerspectiveVisibility = UE.ESlateVisibility.Visible
      watchRecordTweenInAnim = self.People_in
      self.watchRecordTweenOutAnim = self.People_out
    end
  end
  local delayLikeAnimCout = math.min(5, #SpectatorsItemDataList)
  local indexList = random_permutation(delayLikeAnimCout)
  for i = 1, delayLikeAnimCout do
    local index = indexList[i] or 0
    local data = SpectatorsItemDataList[i]
    if data then
      data.delayPlayLikeUiSeconds = index * 0.3
    end
  end
  local emptyItemCount = math.max(0, 5 - #SpectatorsItemDataList)
  for i = 1, emptyItemCount do
    local dataItem = {}
    dataItem.isEmpty = true
    table.insert(SpectatorsItemDataList, 1, dataItem)
  end
  self.ProtagonistPerspective:SetVisibility(ProtagonistPerspectiveVisibility)
  self.ViewingPerspective:SetVisibility(ViewingPerspectiveVisibility)
  self.TextNumberSpectators_1:SetVisibility(TextNumberSpectators1Visibility)
  self.TextNumberSpectators:SetText(TextNumberSpectators)
  self.TextReward:SetText(TextReward)
  self.TextSpectatorRewardNumber:SetText(TextSpectatorRewardNumberText)
  BattleUtils.SetPvpScoreIcon(self.NRCImage_8)
  BattleUtils.SetPvpScoreIcon(self.NRCImage_10)
  self.HeadItem:InitList(SpectatorsItemDataList)
  if watchRecordTweenInAnim then
    self:PlayAnimation(watchRecordTweenInAnim)
  end
end

function UMG_Battle_Victory_C:CloseWatchBattleInfo()
  if self.watchRecordTweenOutAnim then
    self:PlayAnimation(self.watchRecordTweenOutAnim)
    self.watchRecordTweenOutAnim = nil
  end
end

function UMG_Battle_Victory_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Battle_Victory_C:PCModeScreenSetting()
  local Padding = UE4.FMargin()
  Padding.Left = -150
  Padding.Top = -70
  Padding.Right = -150
  Padding.Bottom = -70
  self.Switcher:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  self.Switcher.Slot:SetOffsets(Padding)
end

function UMG_Battle_Victory_C:ShowRecordOver()
  if BattleUtils.IsWatchingBattle() then
    self:AddButtonListener(self.BtnClose, self.OnLeaveWatchingBattle)
  elseif BattleUtils.IsPvpRank() then
    self:AddButtonListener(self.BtnClose, self.ShowRankSettlement)
  elseif BattleUtils.IsPvpScare() then
    self:AddButtonListener(self.BtnClose, self.OnClickClose)
  else
    self:AddButtonListener(self.BtnClose, self.ShowPKAgainState)
  end
end

function UMG_Battle_Victory_C:ShowRankSettlement()
  self:RemoveButtonListener(self.BtnClose, self.ShowRankSettlement)
  if self.FinishData.pvp_rank_settle_info then
    _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.OpenPVPDanGradingPanel, self.FinishData.pvp_rank_settle_info)
  else
    self:OnClickClose()
  end
  self:CloseWatchBattleInfo()
end

function UMG_Battle_Victory_C:ShowQuitState()
  if self.ChangeToAgain then
    return
  end
  self.ChangeToAgain = true
  self.Switcher:SetActiveWidgetIndex(2)
end

function UMG_Battle_Victory_C:ShowPKAgainState()
  if _G.EnableFakePVPRecord then
    _G.BattleManager.stateFsm:Resume()
    _G.BattleEventCenter:Dispatch(BattleEvent.ON_CLICK_ESCAPE, true)
    self:DoClose()
  end
  if self.ChangeToAgain then
    return
  end
  self.ChangeToAgain = true
  if self.PlayerState == UMG_Battle_Victory_C.PKState.ENUM_NONE then
    local enemyState = _G.BattleManager.battlePawnManager:GetPlayerEnemyTeam().roleInfo.base.state_bit
    if 2 == (enemyState or 0) & 1 << ProtoEnum.BATTLER_BIT_TYPE.BT_BATTLER_HUMAN then
      if enemyState & 1 << ProtoEnum.BATTLER_BIT_TYPE.BT_BATTLER_PK_AGAIN > 0 then
        self.EnemyState = UMG_Battle_Victory_C.PKState.ENUM_PK_AGAIN
      end
      self.Switcher:SetActiveWidgetIndex(1)
      self:InitPkAgain()
    end
  end
  self:CloseWatchBattleInfo()
end

function UMG_Battle_Victory_C:InitPkAgain()
  self.Btn_Quit:SetClickAble(true)
  self.Btn_Quit_1:SetClickAble(true)
  self.Btn_DiscussAgain:SetClickAble(true)
  self.Btn_DiscussAgain:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Text_Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.WaitOpTime = 30
  self:RefreshPKAgain()
  self:StartCountDown()
end

function UMG_Battle_Victory_C:RefreshPKAgain()
  if self.EnemyState == UMG_Battle_Victory_C.PKState.ENUM_PK_AGAIN then
    if self.PlayerState == UMG_Battle_Victory_C.PKState.ENUM_NONE then
      self.Btn_DiscussAgain:SetClickAble(true)
      self.Btn_DiscussAgain:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Text_Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Btn_DiscussAgain.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.EnemyState == UMG_Battle_Victory_C.PKState.ENUM_REFUSE then
    self.Btn_DiscussAgain:SetClickAble(false)
    self.Btn_DiscussAgain:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_Hint:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    if self.PlayerState == UMG_Battle_Victory_C.PKState.ENUM_NONE then
      self.Btn_DiscussAgain:SetClickAble(true)
      self.Btn_DiscussAgain:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Text_Hint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Btn_DiscussAgain.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Victory_C:StartCountDown()
  if self.PlayerState ~= UMG_Battle_Victory_C.PKState.ENUM_REFUSE then
    if (self.WaitOpTime or 0) > 0 then
      self.Btn_Quit.Title_Second:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn_Quit.Title_Second:SetText(tostring(self.WaitOpTime))
      self.Btn_Quit_1.Title_Second:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn_Quit_1.Title_Second:SetText(tostring(self.WaitOpTime))
      self.WaitOpTime = math.max(self.WaitOpTime - 1, 0)
      self:DelaySeconds(1, self.StartCountDown, self)
    else
      self:SendRefuseAgain()
    end
  end
end

function UMG_Battle_Victory_C:SendPkAgain()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if self.PlayerState == UMG_Battle_Victory_C.PKState.ENUM_NONE then
    self.Btn_DiscussAgain:SetClickAble(false)
    self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_WAIT_SERVER
    local Req = ProtoMessage:newZoneBattlePkAgainReq()
    Req.pk_again = true
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PK_AGAIN_REQ, Req, self, self.OnNetRsp, true, false)
    self.waitDelay = self:DelaySeconds(3, self.WaitOverTime, self)
  end
end

function UMG_Battle_Victory_C:SendRefuseAgain()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    self:DoClose()
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  if BattleUtils.IsPvpCanBattleAgain() and self.PlayerState ~= UMG_Battle_Victory_C.PKState.ENUM_REFUSE then
    local Req = ProtoMessage:newZoneBattlePkAgainReq()
    Req.pk_again = false
    _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PK_AGAIN_REQ, Req)
  end
  self:OnClickClose()
end

function UMG_Battle_Victory_C:WaitOverTime()
  if self.PlayerState == UMG_Battle_Victory_C.PKState.ENUM_WAIT_SERVER then
    self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_NONE
    self:RefreshPKAgain()
  end
end

function UMG_Battle_Victory_C:OnNetRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_NONE
    self:RefreshPKAgain()
  end
end

function UMG_Battle_Victory_C:OnGetPKAgainRsp(notify)
  if notify and self.PlayerState ~= UMG_Battle_Victory_C.PKState.ENUM_REFUSE then
    if notify.uin == self.playId then
      self:CancelDelayByID(self.waitDelay)
      if notify.pk_again then
        self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_PK_AGAIN
      else
        self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_NONE
      end
    else
      if notify.pk_again then
        self.EnemyState = UMG_Battle_Victory_C.PKState.ENUM_PK_AGAIN
      else
        self.EnemyState = UMG_Battle_Victory_C.PKState.ENUM_REFUSE
      end
      self:RefreshPKAgain()
    end
    self:CheckState()
  end
end

function UMG_Battle_Victory_C:CheckState()
  if self.EnemyState == UMG_Battle_Victory_C.PKState.ENUM_PK_AGAIN and self.PlayerState == UMG_Battle_Victory_C.PKState.ENUM_PK_AGAIN then
    self:OnClickClose()
  end
end

function UMG_Battle_Victory_C:OnDeactive()
  _G.NRCAudioManager:BatchSetState("UI_Music;None")
  self.FinishData = nil
  _G.BattleEventCenter:UnBind(self)
  self:RemoveAllButtonListener()
end

function UMG_Battle_Victory_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Quit.btnLevelUp, self.SendRefuseAgain)
  self:AddButtonListener(self.Btn_Quit_1.btnLevelUp, self.SendRefuseAgain)
  self:AddButtonListener(self.Btn_report.btnLevelUp, self.OnReportBtn)
  if BattleUtils.IsPvpCanBattleAgain() then
    self:AddButtonListener(self.Btn_DiscussAgain.btnLevelUp, self.SendPkAgain)
  end
end

function UMG_Battle_Victory_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PK_AGAIN then
    self:OnGetPKAgainRsp(...)
    return true
  elseif eventName == BattleEvent.RESULT_UI_STATE_UPDATE then
    local option = (...)
    return true
  end
end

function UMG_Battle_Victory_C:OnReportBtn()
  local ReportData = {}
  ReportData.uin = self.EnemyUIN
  ReportData.business_data = {}
  ReportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_GAME_MATCH_SCENE
  ReportData.business_data.report_battle_id = _G.BattleManager.battleRuntimeData.battleSettleData.data.settle_info.battle_id
  ReportData.business_data.report_battle_time = NRCModuleManager:DoCmd(BattleUIModuleCmd.GetPvpPlayerPkInfoStartTime)
  _G.NRCAudioManager:PlaySound2DAuto(1010, "UMG_Friend_Chitchat_C:OnReportBtn")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendReport, ReportData)
end

function UMG_Battle_Victory_C:OnClickClose()
  self.PlayerState = UMG_Battle_Victory_C.PKState.ENUM_REFUSE
  _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
end

function UMG_Battle_Victory_C.OnLeaveWatchingBattle()
  _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
end

function UMG_Battle_Victory_C:RefreshDailyFirstVictory(bShow)
  local bShow = self.FinishData.settle_info and self.FinishData.settle_info.daily_pvp_first_win
  self.FirstVictory:SetVisibility(bShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  if bShow then
    BattleUtils.SetPvpScoreIcon(self.NRCImage_6)
    local bonusScore = _G.DataConfigManager:GetGlobalConfigNumByKeyType("pvp_para2", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, 0)
    local ftmStr = LuaText.pvp_character1 .. "+%d"
    local fullStr = string.format(ftmStr, bonusScore)
    self.Text_FirstVictory:SetText(fullStr)
  end
end

function UMG_Battle_Victory_C:RefreshRandomBonusPoints(bShow)
  local bShow = false
  if self.FinishData.battle_pvp_score and self.FinishData.battle_pvp_score.extra_obtain_pvp_score_source then
    local flag = self.FinishData.battle_pvp_score.extra_obtain_pvp_score_source
    if 0 ~= flag & ProtoEnum.BattlePvpScoreInfo.ExtraPvpScoreSource.RANDOM_PET then
      bShow = true
    end
  end
  self.RandomBonus:SetVisibility(bShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Victory_C:UpdateSceneViewportSizeAndScale()
  local scale = UE.FVector2D()
  local offset = UE.FVector2D()
  UE.UNRCTUIStatics.GetSceneViewportSizeAndScale(scale, offset)
  local CanvasPanelTitleRetainerBox = self.CanvasPanelTitleRetainerBox
  local effectMaterial
  if UE.UObject.IsValid(CanvasPanelTitleRetainerBox) then
    effectMaterial = CanvasPanelTitleRetainerBox and CanvasPanelTitleRetainerBox:GetEffectMaterial()
  end
  if UE.UObject.IsValid(effectMaterial) then
    local scaleX = scale and scale.X or 0
    local scaleY = scale and scale.Y or 0
    local offsetX = offset and offset.X or 0
    local offsetY = offset and offset.Y or 0
    local stencilValue = BattleConst and BattleConst.BattleVictoryUiMaskStencilValue or 5
    if self:IsNeedFlipY() then
      effectMaterial:SetScalarParameterValue("ViewportScaleX", scaleX)
      effectMaterial:SetScalarParameterValue("ViewportScaleY", -scaleY)
      effectMaterial:SetScalarParameterValue("ViewportOffsetX", offsetX)
      effectMaterial:SetScalarParameterValue("ViewportOffsetY", offsetY + scaleY)
      effectMaterial:SetScalarParameterValue("CustomDepthStencilValue", stencilValue)
    else
      effectMaterial:SetScalarParameterValue("ViewportScaleX", scaleX)
      effectMaterial:SetScalarParameterValue("ViewportScaleY", scaleY)
      effectMaterial:SetScalarParameterValue("ViewportOffsetX", offsetX)
      effectMaterial:SetScalarParameterValue("ViewportOffsetY", offsetY)
      effectMaterial:SetScalarParameterValue("CustomDepthStencilValue", stencilValue)
    end
  end
end

function UMG_Battle_Victory_C:IsNeedFlipY()
  local needFlipY = false
  if RocoEnv.PLATFORM_ANDROID then
    needFlipY = true
  end
  if RocoEnv.PLATFORM_OPENHARMONY then
    needFlipY = true
  end
  return needFlipY
end

function UMG_Battle_Victory_C:IsEnableDebugFillMaskUiImage()
  local NRCModuleManager = _G.NRCModuleManager
  local battleUiModule = NRCModuleManager and NRCModuleManager:GetModule("BattleUIModule")
  local battleUiModuleData = battleUiModule and battleUiModule.data
  local enableBattleVictoryTitleFillImage = battleUiModuleData and battleUiModuleData.__enableBattleVictoryTitleFillImage
  return enableBattleVictoryTitleFillImage
end

function UMG_Battle_Victory_C:AddDebugFillMaskUiImage()
  local parentWidget = self.CanvasPanelTitle:GetParent()
  if UE.UObject.IsValid(parentWidget) then
    local imageWidget = NewObject(UE.UNRCImage)
    if UE.UObject.IsValid(imageWidget) then
      parentWidget:AddChild(imageWidget)
      local panelSlot = imageWidget and imageWidget.Slot
      local anchors = UE4.FAnchors()
      anchors.Minimum = UE4.FVector2D(0, 0)
      anchors.Maximum = UE4.FVector2D(1, 1)
      panelSlot:SetAnchors(anchors)
      panelSlot:SetOffsets(UE4.FMargin())
      imageWidget:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  end
end

return UMG_Battle_Victory_C

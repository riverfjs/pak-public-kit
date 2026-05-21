local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local MagicManualModuleEvent = reload("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local RedPointModuleEvent = require("NewRoco.Modules.System.RedPoint.RedPointModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local UMG_MagicManual_C = _G.NRCPanelBase:Extend("UMG_MagicManual_C")
UMG_MagicManual_C.GetBtnState = {ChapterReward = 0, ClueReward = 1}
local SubPanel = {
  MagicManualSubPanel = 1,
  DailySurveySubPanel = 2,
  ChallengeSubPanel = 3,
  PvPSubPanel = 4,
  ChallengePlaySubPanel = 5,
  RecallSubPanel = 6,
  TeachPanel = 7
}

function UMG_MagicManual_C:OnConstruct()
  self.LoadingText:SetText(LuaText.Loading)
  self:SetChildViews(self.MoneyBtn2, self.MoneyBtn2_1, self.MoneyBtn2_3)
  self.UmgLoaders = {
    [SubPanel.MagicManualSubPanel] = self.MagicManualLoader,
    [SubPanel.DailySurveySubPanel] = self.DailySurveyLoader,
    [SubPanel.ChallengeSubPanel] = self.ChallengeLoader,
    [SubPanel.PvPSubPanel] = self.PvPLoader,
    [SubPanel.ChallengePlaySubPanel] = self.ChallengePlayLoader,
    [SubPanel.RecallSubPanel] = self.RecallPanelLoader,
    [SubPanel.TeachPanel] = self.ChallengeTeaching
  }
  if self.MagicManualLoader then
    self.MagicManualLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadMagicManualPanelCallback)
  end
  if self.DailySurveyLoader then
    self.DailySurveyLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadDailySurveyPanelCallback)
  end
  if self.ChallengeLoader then
    self.ChallengeLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadChallengePanelCallback)
  end
  if self.PvPLoader then
    self.PvPLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadPvPPanelCallback)
  end
  if self.ChallengePlayLoader then
    self.ChallengePlayLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadChallengePlayPanelCallback)
  end
  if self.RecallPanelLoader then
    self.RecallPanelLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadRecallPanelCallback)
  end
  if self.ChallengeTeaching then
    self.ChallengeTeaching.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadTeachPanelCallback)
  end
  self.firstSelectTab = true
  self.PreChapterTaskInfo = nil
  self.IsArrive = false
  self:SetCommonTitle()
end

function UMG_MagicManual_C:UnloadAllSubPanel(_forceUnload)
  if self.UmgLoaders then
    for _, _UmgLoader in pairs(self.UmgLoaders) do
      _UmgLoader:UnLoadPanel(_forceUnload)
    end
  end
end

function UMG_MagicManual_C:LoadSubPanel(_SubPanel, ...)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    UmgLoader:LoadPanel(nil, ...)
  end
end

function UMG_MagicManual_C:AddLoadPanelCallbackDelegate(UmgLoader)
  if UmgLoader then
    UmgLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadPanelCallback)
  end
end

function UMG_MagicManual_C:OnLoadMagicManualPanelCallback()
  if self.TableIndex == SubPanel.MagicManualSubPanel then
    self.MagicManualLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.SkipLoadMagicManualText then
    else
      self.SkipLoadMagicManualText = true
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MagicManual_C:OnLoadDailySurveyPanelCallback()
  if self.TableIndex == SubPanel.DailySurveySubPanel then
    self.NeedShowAnim = false
    self.DailySurveyLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.SkipLoadDailySurveyText then
    else
      self.SkipLoadDailySurveyText = true
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MagicManual_C:OnLoadChallengePanelCallback()
  if self.TableIndex == SubPanel.ChallengeSubPanel then
    self.ChallengeLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.SkipLoadChallengeText then
    else
      self.SkipLoadChallengeText = true
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MagicManual_C:OnLoadPvPPanelCallback()
  if self.TableIndex == SubPanel.PvPSubPanel then
    self.PvPLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.SkipLoadPvPText then
    else
      self.SkipLoadPvPText = true
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MagicManual_C:OnLoadChallengePlayPanelCallback()
  if self.TableIndex == SubPanel.ChallengePlaySubPanel then
    self.ChallengePlayLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.SkipLoadChallengePlayText then
    else
      self.SkipLoadChallengePlayText = true
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MagicManual_C:OnLoadTeachPanelCallback()
  if self.TableIndex == SubPanel.TeachPanel then
    self.ChallengeTeaching:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManual_C:OnLoadRecallPanelCallback()
  if self.TableIndex == SubPanel.RecallSubPanel then
    self.RecallPanelLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.LoadingText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManual_C:UnLoadSubPanel(_SubPanel, _forceUnload)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    return UmgLoader:UnLoadPanel(_forceUnload)
  end
end

function UMG_MagicManual_C:GetSubPanel(_SubPanel)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    return UmgLoader:GetPanel()
  end
end

function UMG_MagicManual_C:OnActive(_TaskPanelInfo)
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_CLOSE_MAGICBOOK)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZonePvpInfoQueryReq)
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SyncWorldMapInfo)
  self.data = self.module:GetData("MagicManualModuleData")
  if self.module.TableIndex == self.data.TaskSortType.Task_Adventure and self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    self.TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
    if self.TaskPanelInfo and self.TaskPanelInfo.LeftPanelInfo then
      self.ParagraphId = self.TaskPanelInfo.LeftPanelInfo.id
    end
  else
    self.TaskPanelInfo = _TaskPanelInfo
    if self.TaskPanelInfo and self.TaskPanelInfo.LeftPanelInfo then
      self.ParagraphId = self.TaskPanelInfo.LeftPanelInfo.id
    end
  end
  self:OnAddEventListener()
end

function UMG_MagicManual_C:SetMagicManualDescBG(DescId)
  if not self.module.EnableShowDesc then
    self.module.EnableShowDesc = true
    return
  end
  local MagicManualPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
  if MagicManualPanel then
    MagicManualPanel:SetMagicManualDescBG(DescId)
  end
  _G.NRCAudioManager:PlaySound2DAuto(1004, "UMG_MagicManual_C:SetMagicManualDescBG")
end

function UMG_MagicManual_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateMagicManualPanel, self.UpdatePanelData)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateMagicTeachingPanel, self.UpdateTeachingPanelData)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateMagicManualNextChapterPanel, self.UpdateNextChapter)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateMagicManualChapterInfo, self.SetMagicManualChapterInfo)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateTableView, self.OnRefreshUI)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateChallengeTableView, self.OnRefreshChallengeUI)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateTeachTableView, self.OnRefreshTeachUI)
  self:RegisterEvent(self, MagicManualModuleEvent.SelectMagicChapter, self.OnSelectMagicChapter)
  self:RegisterEvent(self, MagicManualModuleEvent.GetDailyTaskInfos, self.OnUpdateDailyDatas)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateDailyDataEnd, self.UpdateDailyView)
  self:RegisterEvent(self, MagicManualModuleEvent.ChangeDailyTaskInfo, self.OnChangeDailyInfo)
  self:RegisterEvent(self, MagicManualModuleEvent.ChangeClueTaskInfo, self.OnChangeCluemInfo)
  self:RegisterEvent(self, MagicManualModuleEvent.ChangePermanentTaskInfo, self.OnChangePermanentInfo)
  self:RegisterEvent(self, MagicManualModuleEvent.ShowClueRewardTips, self.ShowClueTaskTips)
  self:RegisterEvent(self, MagicManualModuleEvent.SetClueRewardIndex, self.SetClueRewardIndex)
  self:RegisterEvent(self, MagicManualModuleEvent.GetAllClueReward, self.OnGetAllClueReward)
  self:RegisterEvent(self, MagicManualModuleEvent.GetAllPermanentReward, self.OnGetAllPermanentReward)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateFlowerDataEnd, self.UpdateFlowerView)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateBossDataEnd, self.UpdateBossView)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateLegendPetDataEnd, self.UpdateLegendPetView)
  self:RegisterEvent(self, MagicManualModuleEvent.BossListItemTick, self.BossItemsTick)
  self:RegisterEvent(self, MagicManualModuleEvent.RefreshChallengeItemBtn, self.RefreshChallengeItemBtn)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateAppearanceRateEvent, self.OnUpdateAppearanceRateEvent)
  self:RegisterEvent(self, MagicManualModuleEvent.SelectGamePlayTabTypeEvent, self.OnSelectGamePlayTabTypeEvent)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateManualTab, self.UpdateManualTab)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateSeasonManualTask, self.UpdateSeasonManualTask)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateSeasonManualBadge, self.UpdateSeasonManualBadge)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPlayerPetDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, BagModuleEvent.BagItemUpdate, self.OnBagItemDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, BagModuleEvent.BagItemAdd, self.OnBagItemDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
end

function UMG_MagicManual_C:OnUpdateRedPointData(notify)
  if notify.rp_group then
    for _, group in pairs(notify.rp_group) do
      if group.reason_type == _G.Enum.RedPointReason.RPR_ADVENTURE_TASK and group.point_data and #group.point_data > 0 then
        local MagicManualSubPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
        for _, point in pairs(group.point_data) do
          for i, RightPanelInfo in pairs(self.TaskPanelInfo.RightPanelInfo) do
            if RightPanelInfo.PlayerTaskInfo.id == tonumber(point) then
              self.TaskPanelInfo.RightPanelInfo[i].PlayerTaskInfo.state = ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT
              break
            end
          end
        end
        if MagicManualSubPanel then
          MagicManualSubPanel:SetRightPanelInfo(self.TaskPanelInfo.RightPanelInfo)
        end
        break
      end
      if group.reason_type == _G.Enum.RedPointReason.RPR_TYPE_BATTLE_TRAIN_REWARD and group.point_data and #group.point_data > 0 then
        self:UpdateTeachingPanelData()
        break
      end
    end
  end
end

function UMG_MagicManual_C:OnUpdateAppearanceRateEvent()
  if self.TableIndex == SubPanel.ChallengePlaySubPanel then
    local ChallengePlaySubPanel = self:GetSubPanel(SubPanel.ChallengePlaySubPanel)
    if ChallengePlaySubPanel then
      ChallengePlaySubPanel:OnUpdateAppearanceRate()
    end
  end
end

function UMG_MagicManual_C:OnGetAllClueReward()
  local DailySurveySubPanel = self:GetSubPanel(SubPanel.DailySurveySubPanel)
  if DailySurveySubPanel then
    DailySurveySubPanel:OnGetAllClueReward()
  end
end

function UMG_MagicManual_C:OnGetAllPermanentReward()
  local DailySurveySubPanel = self:GetSubPanel(SubPanel.DailySurveySubPanel)
  if DailySurveySubPanel then
    DailySurveySubPanel:OnGetAllPermanentReward()
  end
end

function UMG_MagicManual_C:SetMagicManualChapterInfo(_TaskPanelInfo)
  local MagicManualPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
  if MagicManualPanel then
    MagicManualPanel:SetMagicManualChapterInfo(_TaskPanelInfo)
  end
end

function UMG_MagicManual_C:SetCommonTitle()
  if self.parent then
    self.titleConf = _G.DataConfigManager:GetTitleConf(self.parent:GetPanelName())
    self.Title1:Set_MainTitle(self.titleConf.title)
    self.Title1:SetBg(self.titleConf.head_icon)
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
end

function UMG_MagicManual_C:OnRefreshUI(tabIndex, tableName, ...)
  Log.Debug(tabIndex, "UMG_MagicManual_C:OnRefreshUI")
  if self.firstSelectTab then
    self.firstSelectTab = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  end
  if tabIndex == self.TableIndex then
    return
  end
  self:SetShowWidgetByIndex(tabIndex)
  self:UnLoadSubPanel(self.TableIndex, false)
  self.firstSelectChallengeTab = true
  self.TableIndex = tabIndex
  self.module.TableIndex = tabIndex - 1
  self.panel.FirstSelect = true
  self.panel.UpdateTime = 0
  self:RefreshCommonTitle(tabIndex)
  if tableName then
  end
  self:CancelDelay()
  self.BG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#773937FF"))
  if tabIndex ~= SubPanel.ChallengeSubPanel then
    self.module.SubTableIndex = -1
    self.module:LeaveChallengeStopTick()
    self.module:LeaveChallengeBossStopTick()
  else
    self.SetActiveWidgetChallenge = true
  end
  if tabIndex == SubPanel.DailySurveySubPanel then
    self:RequestDailyViewDatas()
    if not self.SkipLoadDailySurveyText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif tabIndex == SubPanel.MagicManualSubPanel then
    if not self.SkipLoadMagicManualText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:LoadSubPanel(tabIndex, self.TaskPanelInfo, self.module)
  elseif tabIndex == SubPanel.ChallengeSubPanel then
    if not self.SkipLoadChallengeText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:LoadSubPanel(tabIndex, self.module)
    self:UpdateHealth()
  elseif tabIndex == SubPanel.PvPSubPanel then
    if not self.SkipLoadPvPText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:LoadSubPanel(tabIndex, self.module)
  elseif tabIndex == SubPanel.ChallengePlaySubPanel then
    if not self.SkipLoadChallengePlayText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.SelectBattlePlayTabAudio = false
    self:LoadSubPanel(tabIndex, self.module)
  elseif tabIndex == SubPanel.RecallSubPanel then
    if not self.SkipLoadChallengePlayText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.SelectBattlePlayTabAudio = false
    self:LoadSubPanel(tabIndex, self.module, ...)
  elseif tabIndex == SubPanel.TeachPanel then
    self.BG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#4F4E80FF"))
    if not self.SkipLoadTeachPanelText then
      self.LoadingText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.SelectBattlePlayTabAudio = false
    self:LoadSubPanel(tabIndex, self.module)
  end
  self.module:CloseWorldMapWithSource()
end

function UMG_MagicManual_C:RefreshCommonTitle(tabIndex)
  if 1 == tabIndex then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 2 == tabIndex then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif 3 == tabIndex then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
    end
  elseif 4 == tabIndex then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
    end
  elseif 5 == tabIndex then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[5].subtitle)
    end
  elseif 6 == tabIndex then
    if self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[6] then
      self.Title1:SetSubtitle(self.titleConf.subtitle[6].subtitle)
    end
  elseif 7 == tabIndex and self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[7] then
    self.Title1:SetSubtitle(self.titleConf.subtitle[7].subtitle)
  end
end

function UMG_MagicManual_C:SetShowWidgetByIndex(TableIndex)
  for i, v in pairs(self.UmgLoaders) do
    if i == TableIndex then
    else
      v:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MagicManual_C:ShowOrHideMoneyBtn(bIsHide)
  if bIsHide then
    if self.UmgLoaders[3]:GetPanel() then
      self.UmgLoaders[3]:GetPanel().MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UmgLoaders[3]:GetPanel().Button_Detail:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UmgLoaders[3]:GetPanel().SeasonalSystemBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UmgLoaders[3]:GetPanel().SeasonalSystemText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.UmgLoaders[3]:GetPanel() then
    self.UmgLoaders[3]:GetPanel().MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UmgLoaders[3]:GetPanel().Button_Detail:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UmgLoaders[3]:GetPanel().SeasonalSystemBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UmgLoaders[3]:GetPanel().SeasonalSystemText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_MagicManual_C:OnPlayerPetDataUpdate()
  if self.TaskPanelInfo and self.TaskPanelInfo.RightPanelInfo then
    local taskList = {}
    for i, RightPanelInfo in pairs(self.TaskPanelInfo.RightPanelInfo) do
      local taskConf = RightPanelInfo.TaskConf
      if taskConf and taskConf.task_condition and #taskConf.task_condition > 0 then
        for j, taskCondition in pairs(taskConf.task_condition) do
          if taskCondition.type == Enum.TaskKeyType.TKT_CHECK_PET_PROGRESS then
            table.insert(taskList, taskConf.id)
          end
        end
      end
    end
    if #taskList > 0 then
      self:OnReqTaskData(taskList)
    end
  end
end

function UMG_MagicManual_C:OnReqTaskData(taskList)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = taskList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetTaskStateInfoRsp)
end

function UMG_MagicManual_C:GetTaskStateInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.task_info_list and #rsp.task_info_list > 0 then
    for _, task in pairs(rsp.task_info_list) do
      for i, RightPanelInfo in pairs(self.TaskPanelInfo.RightPanelInfo) do
        if RightPanelInfo.PlayerTaskInfo.id == task.id then
          self.TaskPanelInfo.RightPanelInfo[i].PlayerTaskInfo = task
        end
      end
    end
    local MagicManualSubPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
    if MagicManualSubPanel then
      MagicManualSubPanel:SetRightPanelInfo(self.TaskPanelInfo.RightPanelInfo)
    end
  end
end

function UMG_MagicManual_C:OnPlayerDataUpdate()
  self:UpdateHealth()
end

function UMG_MagicManual_C:OnBagItemDataUpdate()
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:ShowHeTerOnuClearStarChain()
  end
end

function UMG_MagicManual_C:UpdateHealth()
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:UpdateHealth()
  end
end

function UMG_MagicManual_C:OnSelectGamePlayTabTypeEvent(SelectTabData)
  if self.SelectBattlePlayTabAudio then
    _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_Leve_BattleSilhouette_C:OnSelectCameraShotItemEvent")
  else
    self.SelectBattlePlayTabAudio = true
  end
  local ChallengePlaySubPanel = self:GetSubPanel(SubPanel.ChallengePlaySubPanel)
  if ChallengePlaySubPanel then
    ChallengePlaySubPanel:OnSelectGamePlayTabTypeEvent(SelectTabData)
  end
  local Text = _G.DataConfigManager:GetLocalizationConf("challenge_title_1").msg
  local Text_1 = _G.DataConfigManager:GetLocalizationConf("challenge_title_2").msg
  if SelectTabData.TabType == self.data.BattlePlayTaskType.BattleSilhouette then
  elseif SelectTabData.TabType == self.data.BattlePlayTaskType.Chieftain then
  end
end

function UMG_MagicManual_C:OnSelectMagicChapter(ChapterId)
  _G.NRCAudioManager:PlaySound2DAuto(1324, "UMG_MagicManual_Task_Tads_C:OnSelectMagicChapter")
  self.module:SetSelectMagicManualChapter(ChapterId)
end

function UMG_MagicManual_C:OnRefreshChallengeUI(tabIndex, Sort, tableName)
  if self.firstSelectChallengeTab then
    self.firstSelectChallengeTab = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  end
  if tableName then
  end
  self.module.SubTableIndex = tabIndex - 1
  if self.TableIndex == SubPanel.ChallengeSubPanel then
    local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
    if ChallengeSubPanel then
      ChallengeSubPanel:OnRefreshChallengeUI(tabIndex, Sort, tableName)
    end
  elseif self.TableIndex == SubPanel.TeachPanel then
    local TeachingSubPanel = self:GetSubPanel(SubPanel.TeachPanel)
    if TeachingSubPanel then
      TeachingSubPanel:OnRefreshTeachTabUI(tabIndex, Sort, tableName)
    end
  end
end

function UMG_MagicManual_C:OnRefreshTeachUI(type, ItemData, _conf)
  local TeachingSubPanel = self:GetSubPanel(SubPanel.TeachPanel)
  if TeachingSubPanel then
    TeachingSubPanel:OnRefreshTeachUI(type, ItemData, _conf)
  end
end

function UMG_MagicManual_C:OnReconnect()
  local GetTaskChangeList = self.data:GetMagicManualTaskParagraphIdList()
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = GetTaskChangeList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetTaskChangeInfo)
end

function UMG_MagicManual_C:UpdateTeachingPanelData()
  local req = _G.ProtoMessage:newZoneGetTeachingTabReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_TEACHING_TAB_REQ, req, self, self.OnZoneGetTeachingTabRsp)
end

function UMG_MagicManual_C:OnZoneGetTeachingTabRsp(rsp)
  self.module:OnZoneGetTeachingTabRsp(rsp)
  local TeachingSubPanel = self:GetSubPanel(SubPanel.TeachPanel)
  if TeachingSubPanel then
    TeachingSubPanel:OnRefreshPanel()
  end
end

function UMG_MagicManual_C:UpdatePanelData()
  local GetTaskChangeList = self.data:GetMagicManualTaskParagraphIdList()
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = GetTaskChangeList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetTaskChangeInfo)
end

function UMG_MagicManual_C:GetTaskChangeInfo(Rsp)
  self.data:UpDateCurrentTaskParagraphInfo(Rsp.task_info_list, true)
  local NewTaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
  local MagicManualPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
  if MagicManualPanel then
    MagicManualPanel:SetLeftPanelInfo(NewTaskPanelInfo.LeftPanelInfo)
    MagicManualPanel:SetRightPanelInfo(NewTaskPanelInfo.RightPanelInfo)
    MagicManualPanel:ShowChapter()
  end
end

function UMG_MagicManual_C:UpdateNextChapter()
  _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManual)
end

function UMG_MagicManual_C:OnClickPreviousChapter()
  _G.NRCAudioManager:PlaySound2DAuto(1220002025, "UMG_MagicManual_C:OnClickPreviousChapter")
  local ShowChapterlist, CurChapterSelect = self.data:GetShowChapter()
  local CurChapterId = self.data.CurChapterId - 1
  for i, v in pairs(ShowChapterlist) do
    if v.id == CurChapterId then
      self.CatchHardLv:SelectItemByIndex(i - 1)
    end
  end
end

function UMG_MagicManual_C:OnClickNextChapter()
  _G.NRCAudioManager:PlaySound2DAuto(1220002025, "UMG_MagicManual_C:OnClickNextChapter")
  local ShowChapterlist, CurChapterSelect = self.data:GetShowChapter()
  local CurChapterId = self.data.CurChapterId + 1
  for i, v in pairs(ShowChapterlist) do
    if v.id == CurChapterId then
      self.CatchHardLv:SelectItemByIndex(i - 1)
    end
  end
end

function UMG_MagicManual_C:OnDestruct()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_ADVENTURE)
  self:UnloadAllSubPanel(false)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateTableView, self.OnRefreshUI)
  self:UnRegisterEvent(self, MagicManualModuleEvent.GetDailyTaskInfos, self.OnUpdateDailyInfo)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateDailyDataEnd, self.UpdateDailyView)
  self:UnRegisterEvent(self, MagicManualModuleEvent.ChangeDailyTaskInfo, self.OnChangeDailyInfo)
  self:UnRegisterEvent(self, MagicManualModuleEvent.ChangeClueTaskInfo, self.OnChangeCluemInfo)
  self:UnRegisterEvent(self, MagicManualModuleEvent.ChangePermanentTaskInfo, self.OnChangePermanentInfo)
  self:UnRegisterEvent(self, MagicManualModuleEvent.ShowClueRewardTips, self.ShowClueTaskTips)
  self:UnRegisterEvent(self, MagicManualModuleEvent.SetClueRewardIndex, self.SetClueRewardIndex)
  self:UnRegisterEvent(self, MagicManualModuleEvent.GetAllClueReward, self.OnGetAllClueReward)
  self:UnRegisterEvent(self, MagicManualModuleEvent.GetAllPermanentReward, self.OnGetAllPermanentReward)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateChallengeTableView, self.OnRefreshChallengeUI)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateTeachTableView, self.OnRefreshTeachUI)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateFlowerDataEnd, self.UpdateFlowerView)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateBossDataEnd, self.UpdateBossView)
  self:UnRegisterEvent(self, MagicManualModuleEvent.BossListItemTick, self.BossItemsTick)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateManualTab, self.UpdateManualTab)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateSeasonManualTask, self.UpdateSeasonManualTask)
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateSeasonManualBadge, self.UpdateSeasonManualBadge)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  NRCEventCenter:UnRegisterEvent(self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagItemDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagItemDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPlayerPetDataUpdate)
end

function UMG_MagicManual_C:SetInitPetManualTicketRootStyle(_IsShow)
end

function UMG_MagicManual_C:SetInitPetDailyTicketRootStyle(_IsShow)
  if _IsShow then
  else
    self.CurDailyTaskIsFinish = true
  end
end

function UMG_MagicManual_C:RequestDailyViewDatas()
  if self.module then
    self.NeedShowAnim = true
    self.module:ZoneQueryInvestTaskReq()
  end
end

function UMG_MagicManual_C:UpdateDailyView()
  if 2 == self.TableIndex then
    self:LoadSubPanel(2, self.module, self.NeedShowAnim)
  end
end

function UMG_MagicManual_C:ShowClueTaskTips(index, rewards)
  local DailySurveySubPanel = self:GetSubPanel(SubPanel.DailySurveySubPanel)
  if DailySurveySubPanel then
    DailySurveySubPanel:ShowClueTaskTips(index, rewards)
  end
end

function UMG_MagicManual_C:SetClueRewardIndex(index)
end

function UMG_MagicManual_C:OnUpdateDailyDatas()
  self:UpdateDailyView()
end

function UMG_MagicManual_C:OnChangeDailyInfo(taskInfo)
end

function UMG_MagicManual_C:OnChangeCluemInfo(taskInfo)
end

function UMG_MagicManual_C:OnChangePermanentInfo(taskInfo)
end

function UMG_MagicManual_C:RequestChallengeXiShouDatas()
  if self.module then
    self.module:GetFlowerData()
  end
end

function UMG_MagicManual_C:RequestChallengeBossDatas()
  if self.module then
    self.module:GetBossData()
  end
end

function UMG_MagicManual_C:RequestLegendPetDatas()
  if self.module then
    self.module:GetLegendPetDatas()
  end
end

function UMG_MagicManual_C:UpdateLegendPetView()
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:UpdateLegendPetView()
  end
end

function UMG_MagicManual_C:UpdateFlowerView(UpdateTime)
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:UpdateFlowerView(UpdateTime)
  end
end

function UMG_MagicManual_C:UpdateBossView()
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:UpdateBossView()
  end
end

function UMG_MagicManual_C:BossItemsTick()
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:BossItemsTick()
  end
end

function UMG_MagicManual_C:RefreshChallengeItemBtn(RefreshId, next_npc_refresh_time)
  local ChallengeSubPanel = self:GetSubPanel(SubPanel.ChallengeSubPanel)
  if ChallengeSubPanel then
    ChallengeSubPanel:RefreshChallengeItemBtn(RefreshId, next_npc_refresh_time)
  end
end

function UMG_MagicManual_C:OnAnimationFinished(anim)
end

function UMG_MagicManual_C:UpdateManualTab(tabIndex, childTabIndex)
  local manaulSubPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
  if manaulSubPanel then
    manaulSubPanel:UpdateManualTab(tabIndex, childTabIndex)
  end
end

function UMG_MagicManual_C:UpdateSeasonManualTask()
  local manaulSubPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
  if manaulSubPanel then
    manaulSubPanel:UpdateSeasonManualTask()
  end
end

function UMG_MagicManual_C:UpdateSeasonManualBadge()
  local manaulSubPanel = self:GetSubPanel(SubPanel.MagicManualSubPanel)
  if manaulSubPanel then
    manaulSubPanel:UpdateSeasonManualBadge()
  end
end

return UMG_MagicManual_C

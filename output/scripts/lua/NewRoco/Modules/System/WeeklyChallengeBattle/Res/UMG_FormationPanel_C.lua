local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local ModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_FormationPanel_C = _G.NRCPanelBase:Extend("UMG_FormationPanel_C")

function UMG_FormationPanel_C:OnActive(bFromPetHeadIcon)
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_FormationPanel_C:OnActive")
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RefetchTeamList)
  self:SetChildViews(self.ComScreen)
  self:OnAddEventListener()
  self.bFromPetHeadIcon = bFromPetHeadIcon
  self.calledCloseCallback = false
  self.eventConf = self:_GetEventConf()
  self.bIsOpeningPetDetailsPanel = false
  self.bIsEditMode = false
  self.bIsSwapMode = false
  self.bIsPetListInited = false
  self.curPetDataList = {}
  self.curFilterRule = nil
  self.curSortRuleType = _G.Enum.PetSequenceDefault.SEQUENCE_CHEER_POINT_DOWN
  self.isAscending = false
  self.bIsEventOOD = false
  self.editModeTeamPetList = {
    {},
    {},
    {},
    {},
    {},
    {}
  }
  self.curSelectedPetData = {}
  self.curSelectedPetDataInWarehouse = true
  self.curSelectedPetIndex = 0
  self.lastMode = nil
  self.lastCheerPoint = nil
  self._pendingChangeSelectPetData = nil
  self:_InitPanel()
end

function UMG_FormationPanel_C:OnDeactive()
  self:OnRemoveEventListener()
  if not self.calledCloseCallback then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseTeamEditPanel)
  end
end

function UMG_FormationPanel_C:OnAddEventListener()
  self:AddButtonListener(self.BtnQuickEdit.btnLevelUp, self.OnClickQuickEditButton)
  self:AddButtonListener(self.Btn_Exchange_1.btnLevelUp, self.OnClickExchangeButton)
  self:AddButtonListener(self.Btn_Cultivate.btnLevelUp, self.OnClickSkillAdjustButton)
  self:AddButtonListener(self.RewardBtn_1, self.OnClickRewardButton)
  self:AddButtonListener(self.Btn_Details, self.OnClickPetDetailsButton)
  self:AddButtonListener(self.ResetBtn_1, self.OnClickResetButton)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseButton)
  self:AddButtonListener(self.ParticularsBtn.btnLevelUp, self.OnClickDetailButton)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnClickCollectButton)
  self:AddButtonListener(self.RecyclingBtn, self.OnReturnToInventoryButtonClick)
  self:AddButtonListener(self.RecyclingBtn_1, self.OnReturnToInventoryButtonClick)
  self:AddButtonListener(self.BloodPulse, self.OnClickBloodPulseButton)
  self:AddButtonListener(self.BtnRechristen_1, self.OnClickBtnRechristenButton)
  self:AddButtonListener(self.BloodBtn, self.OnClickTeamSkillButtonClick)
  self:AddButtonListener(self.BloodBtn_1, self.OnClickTeamSkillButtonClick)
  self:AddButtonListener(self.Exchange_1.btnLevelUp, self.OnClickTeamSkillButtonClick)
  self:AddButtonListener(self.Exchange.btnLevelUp, self.OnClickTeamSkillButtonClick)
  local comboBoxData = _G.NRCCommonDropDownListData()
  comboBoxData.Btn_LeftHandler = self.OnClickFilterButton
  comboBoxData.Btn_MidHandler = self.OnClickSortBtnClick
  comboBoxData.Btn_RightHandler = self.OnClickSwitchOrderButton
  comboBoxData.IsComboBox = false
  comboBoxData.Call = self
  self.ComScreen:SetPanelInfo(comboBoxData)
  _G.NRCEventCenter:RegisterEvent("UMG_FormationPanel_C", self, PetUIModuleEvent.PET_UI_SORT, self.OnPetSort)
  _G.NRCEventCenter:RegisterEvent("UMG_FormationPanel_C", self, PetUIModuleEvent.FilterPet, self.OnPetFilter)
  _G.NRCEventCenter:RegisterEvent("UMG_FormationPanel_C", self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnTeamEquipMagic)
  _G.NRCEventCenter:RegisterEvent("UMG_FormationPanel_C", self, PetUIModuleEvent.RefreshAdjustPetPanel, self.OnPetAdjust)
  _G.NRCEventCenter:RegisterEvent("UMG_FormationPanel_C", self, ModuleEvent.OnMainPetUIExit, self.OnMainPetUIExit)
  self:RegisterEvent(self, ModuleEvent.UpdatePetCollect, self.OnPetCollectChanged)
  self:RegisterEvent(self, ModuleEvent.OnChangePetConfirmPanelClose, self.OnChangePetConfirmPanelClose)
  self:RegisterEvent(self, ModuleEvent.OnActivityEventIdChanged, self.OnActivityEventIdChanged)
  self:RegisterEvent(self, ModuleEvent.OnTeamPetChanged, self.OnTeamPetChanged)
  self:RegisterEvent(self, ModuleEvent.OnResetDataChangedEvent, self.OnResetDataChangedEvent)
  self:RegisterEvent(self, ModuleEvent.OnAllPetBalancedDataReady, self.OnAllPetBalancedDataReady)
  self:RegisterEvent(self, ModuleEvent.OnPetSkillChanged, self.OnPetSkillChanged)
  self:RegisterEvent(self, ModuleEvent.OnMultiplePetsBalancedDataReady, self.OnMultiplePetsBalancedDataReady)
end

function UMG_FormationPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PET_UI_SORT, self.OnPetSort)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.FilterPet, self.OnPetFilter)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnTeamEquipMagic)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.RefreshAdjustPetPanel, self.OnPetAdjust)
  _G.NRCEventCenter:UnRegisterEvent(self, ModuleEvent.OnMainPetUIExit, self.OnMainPetUIExit)
  self:UnRegisterEvent(self, ModuleEvent.UpdatePetCollect)
  self:UnRegisterEvent(self, ModuleEvent.OnChangePetConfirmPanelClose)
  self:UnRegisterEvent(self, ModuleEvent.OnActivityEventIdChanged)
  self:UnRegisterEvent(self, ModuleEvent.OnTeamPetChanged)
  self:UnRegisterEvent(self, ModuleEvent.OnResetDataChangedEvent)
  self:UnRegisterEvent(self, ModuleEvent.OnAllPetBalancedDataReady)
  self:UnRegisterEvent(self, ModuleEvent.OnPetSkillChanged)
  self:UnRegisterEvent(self, ModuleEvent.OnMultiplePetsBalancedDataReady)
end

function UMG_FormationPanel_C:OnMainPetUIExit()
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SetBgmToTheater)
end

function UMG_FormationPanel_C:OnTeamPetChanged(petList)
  self:UpdateTeamPetList(petList)
  if self.lastMode == nil then
    return
  end
  if 1 == self.lastMode then
    local selectedGid = self.curSelectedPetData.gid
    if selectedGid and 0 ~= selectedGid then
      local index = 0
      local bIsInTeam = true
      local bHasData = false
      for i = 1, self.PetList:GetItemCount() do
        if self.PetList:OpItemByIndex(i, 5, selectedGid) then
          index = i
          bIsInTeam = true
          bHasData = true
          break
        end
      end
      if not bHasData then
        local warehouseListDatas = self.WarehouseList._listDatas
        if warehouseListDatas then
          for i = 1, #warehouseListDatas do
            if warehouseListDatas[i] and warehouseListDatas[i].petData and warehouseListDatas[i].petData.gid == selectedGid then
              index = i
              bIsInTeam = false
              bHasData = true
              break
            end
          end
        end
      end
      if bHasData then
        if bIsInTeam then
          self.PetList:SelectItemByIndex(index - 1)
        else
          self.WarehouseList:SelectItemByIndex(index - 1)
        end
      end
    end
  end
  if 2 == self.lastMode then
    local index = -1
    local bIsInTeam = true
    for i = 1, self.PetList:GetItemCount() do
      if self.PetList:OpItemByIndex(i, 4) then
        index = 1
        bIsInTeam = true
        break
      end
    end
    if -1 == index then
      for i = 1, self.WarehouseList:GetItemCount() do
        if self.WarehouseList:OpItemByIndex(i, 4) then
          index = i
          bIsInTeam = false
          break
        end
      end
    end
    if index > 0 then
      if bIsInTeam then
        self.PetList:SelectItemByIndex(index - 1)
      else
        self.WarehouseList:SelectItemByIndex(index - 1)
      end
    end
  end
end

function UMG_FormationPanel_C:OnActivityEventIdChanged()
  self.bIsEventOOD = true
end

function UMG_FormationPanel_C:OnPetSort(index)
  print("UMG_FormationPanel_C:OnPetSort")
  self.curSortRuleType = index
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_BAG_SEQUENCE)
  local cfgDatas = cfgTable:GetAllDatas()
  local text = ""
  for k, v in ipairs(cfgDatas) do
    if v.sequence_default == index then
      text = v.sequence_desc
    end
  end
  self.ComScreen:SetComboText(text)
  local filteredList = self:_FilterPet()
  if not self.bIsEditMode then
    local selectGid
    if self.curSelectedPetDataInWarehouse and self.curSelectedPetData then
      selectGid = self.curSelectedPetData.gid
    end
    local bHasItem, newIndex = self:UpdateWarehouseList(filteredList, selectGid)
    if bHasItem and newIndex and newIndex > 0 and self.curSelectedPetDataInWarehouse then
      self.curSelectedPetIndex = newIndex
    end
  else
    local selectedGids = {}
    local indices = self.WarehouseList:GetSelectedIndex()
    if indices and type(indices) == "table" then
      for i, v in pairs(indices) do
        local item = self.WarehouseList:GetItemByIndex(v)
        if item and item.uiData and 0 ~= item.uiData.gid then
          selectedGids[item.uiData.gid] = true
        end
        self.WarehouseList:DeselectItemByIndex(v + 1)
      end
    end
    self:UpdateWarehouseList(filteredList)
    local indicesToSelect = {}
    local size = self.WarehouseList:GetItemCount()
    for i = 0, size - 1 do
      local item = self.WarehouseList:GetItemByIndex(i)
      if item and item.uiData and 0 ~= item.uiData.gid and selectedGids[item.uiData.gid] then
        table.insert(indicesToSelect, i)
      end
    end
    for k, v in ipairs(indicesToSelect) do
      self.WarehouseList:SelectItemByIndex(v)
    end
  end
end

function UMG_FormationPanel_C:OnPetFilter(typeChooseList)
  print("UMG_FormationPanel_C:OnPetFilter")
  self.curFilterRule = typeChooseList
  local filteredList = self:_FilterPet()
  local selectGid
  if self.curSelectedPetDataInWarehouse and self.curSelectedPetData then
    selectGid = self.curSelectedPetData.gid
  end
  local bHasItem, newIndex = self:UpdateWarehouseList(filteredList, selectGid)
  if bHasItem and newIndex and newIndex > 0 and self.curSelectedPetDataInWarehouse then
    self.curSelectedPetIndex = newIndex
  end
end

function UMG_FormationPanel_C:OnClickQuickEditButton()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  if not self.bIsEditMode then
    self:_EnterEditMode()
  elseif self:_IsHigherThanLastCheerUpPoint() then
    self:_QuitEditMode()
  else
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local context = DialogContext()
    context:SetTitle(_G.LuaText.TIPS)
    context:SetContent(_G.LuaText.weekly_challenge_text_7)
    context:SetMode(DialogContext.Mode.OK_CANCEL)
    context:SetDialogType(DialogContext.DialogType.GeneralTip)
    context:SetCallback(self, self.OnStartChallengeCallback)
    context:SetForceEnableFullScreenBtn()
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, context)
  end
end

function UMG_FormationPanel_C:OnStartChallengeCallback(bIsOk)
  if bIsOk then
    self:_QuitEditMode()
  end
end

function UMG_FormationPanel_C:OnClickExchangeButton()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  if not self.bIsSwapMode then
    self:_EnterSwapMode()
  else
    self:QuitSwapMode()
  end
end

function UMG_FormationPanel_C:OnClickSkillAdjustButton()
  self.bEnterSkillChangePanel = true
  self:StopAnimation(self.Right_In)
  self:StopAnimation(self.Right_Out)
  self:PlayAnimation(self.Right_Out)
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_FormationPanel_C:OnClickSkillAdjustButton")
end

function UMG_FormationPanel_C:OnClickRewardButton()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  local rewardList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentEventRewardList)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenRewardClaimPopupPanel, rewardList, true)
end

function UMG_FormationPanel_C:OnClickPetDetailsButton()
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_FormationPanel_C:OnClickPetDetailsButton")
  if not (self.curSelectedPetData and self.curSelectedPetData.gid) or 0 == self.curSelectedPetData.gid then
    return
  end
  self.bEnterDetailPanel = true
  self:StopAnimation(self.Right_Out)
  self:StopAnimation(self.Right_In)
  self:PlayAnimation(self.Right_Out)
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_FormationPanel_C:OnClickPetDetailsButton")
end

function UMG_FormationPanel_C:OnClickResetButton()
  self:PlayAnimation(self.Press)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FormationPanel_C:OnClickResetButton")
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  if not self.eventConf then
    return
  end
  local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(self.eventConf.challenge_id[1])
  if not challengeConf then
    return
  end
  local _, level, grow, workHard = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
  local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenResetNotification, bIsNeedBalance, grow, level, workHard)
end

function UMG_FormationPanel_C:OnClickCloseButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_FormationPanel_C:OnClickCloseButton")
  self:StopAnimation(self.In)
  self:StopAnimation(self.Out)
  self:PlayAnimation(self.Out)
end

function UMG_FormationPanel_C:OnClickDetailButton()
  local titleText = _G.LuaText.weekly_challenge_text_10
  local contentStr = _G.LuaText.weekly_challenge_text_9
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_FormationPanel_C:OnClickCollectButton()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.curSelectedPetData.gid, self.curSelectedPetData.partner_mark)
end

function UMG_FormationPanel_C:OnClickBloodPulseButton()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.PetUIOpenPetBloodPulse, self.curSelectedPetData, TipEnum.OpenPetTipsType.PetMainPanel)
end

function UMG_FormationPanel_C:OnClickBtnRechristenButton()
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {
    petData = self.curSelectedPetData
  }, _G.Enum.GoodsType.GT_PET)
end

function UMG_FormationPanel_C:OnClickTeamSkillButtonClick()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  local gidList = {}
  local currentTeamList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  for k, v in ipairs(currentTeamList) do
    if v.gid and 0 ~= v.gid then
      table.insert(gidList, v.gid)
    end
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodLineMagic, _G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT, 0, gidList)
end

function UMG_FormationPanel_C:OnClickFilterButton()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenFilterPanel, PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle)
end

function UMG_FormationPanel_C:OnClickSortBtnClick()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSortPanel, self.curSortRuleType, PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle)
end

function UMG_FormationPanel_C:OnClickSwitchOrderButton()
  self.isAscending = not self.isAscending
  self:OnPetSort(self.curSortRuleType)
end

function UMG_FormationPanel_C:OnReturnToInventoryButtonClick()
  if self.bIsEventOOD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.weekly_challenge_text_24)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RemovePetFromTeam, self.curSelectedPetData.gid, true)
  local gid = self.curSelectedPetData.gid
  self:QuitSwapMode()
  self.PetList:ClearSelection()
  self.WarehouseList:ClearSelection()
end

function UMG_FormationPanel_C:_InitPanel()
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RewardBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:StopAnimation(self.Out)
  self:StopAnimation(self.In)
  self:PlayAnimation(self.In)
  self.bIsInit = true
  self:_InitPetList()
  self:_InitWarehouseList()
  self:_InitPetCategoryComboBox()
  self:_InitRewardButton()
  self:_InitSkill()
  local teamPetList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local index = 0
  for k, v in ipairs(teamPetList) do
    if v.gid and 0 ~= v.gid then
      index = k
      break
    end
  end
  if 0 ~= index then
    self.PetList:SelectItemByIndex(index - 1)
    self.bEnterDetailPanel = true
    self:StopAnimation(self.Right_Out)
    self:StopAnimation(self.Right_In)
    self:PlayAnimation(self.Right_Out)
  else
    self.RewardBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  local text = _G.DataConfigManager:GetPetBagSequence(12).sequence_desc
  self.ComScreen:SetComboText(text)
  self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local eventConf = self:_GetEventConf()
  if eventConf then
    local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
    if bIsNeedBalance then
      self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  if self.NRCText then
    self.NRCText:SetText(_G.LuaText.weekly_challenge_text_13)
  end
  self.Text_3:SetText(_G.LuaText.weekly_challenge_text_31)
end

function UMG_FormationPanel_C:_InitWarehouseList()
  local CurrentPlayerPetData = _G.DataModelMgr.PlayerDataModel:GetPetData()
  local cachedUsablePetGids = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetAllUsablePetGids)
  if cachedUsablePetGids and #cachedUsablePetGids > 0 then
    for _, gid in ipairs(cachedUsablePetGids) do
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
      if petData then
        table.insert(self.curPetDataList, petData)
      end
    end
    Log.Info(string.format("UMG_FormationPanel_C:_InitWarehouseList Using cached usable pet gids, count: %d", #self.curPetDataList))
  else
    for k, v in pairs(CurrentPlayerPetData) do
      if self:_IsThisWeekCatchPet(v) then
        table.insert(self.curPetDataList, v)
      end
    end
    Log.Info(string.format("UMG_FormationPanel_C:_InitWarehouseList Fallback to filter this week pets, count: %d", #self.curPetDataList))
  end
  if #self.curPetDataList <= 0 then
    self.Btn_Details:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Cultivate:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Exchange_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnQuickEdit:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ComScreen:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local filterList = self:_FilterPet()
  local bIsWarehouse = self:UpdateWarehouseList(filterList)
  if bIsWarehouse then
    self.DetailsR:SetActiveWidgetIndex(0)
    self.WarehouseList:SelectItemByIndex(0)
    self.bEnterDetailPanel = true
    self:StopAnimation(self.Right_Out)
    self:StopAnimation(self.Right_In)
    self:PlayAnimation(self.Right_Out)
  else
    self.DetailsR:SetActiveWidgetIndex(1)
  end
end

function UMG_FormationPanel_C:_InitPetList()
  local petDataList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local initList = {}
  for k, v in ipairs(petDataList) do
    table.insert(initList, {
      petData = v,
      parent = self,
      bIsWarehouse = false,
      bIsEditMode = self.bIsEditMode,
      bIsSwapMode = self.bIsSwapMode
    })
  end
  self.PetList:InitGridView(initList)
  self.bIsPetListInited = true
  self:_SetPetListClickable()
  local totalCheerUpPoint = self:_CalculateCheerUpPoint(petDataList)
  self:_SetTeamCheerPoint(totalCheerUpPoint)
end

function UMG_FormationPanel_C:_InitPetCategoryComboBox()
end

function UMG_FormationPanel_C:_InitRewardButton()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    self.TextClaimProgress_1:SetText("0/12")
    return
  end
  local weeklyChallengeData = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  local totalStarNum = MagicManualUtils.GetWeeklyChallengeStarNum(weeklyChallengeData)
  local finishedStarNum = weeklyChallengeData.challenge_info.highest_cheer_point or 0
  self.TextClaimProgress_1:SetText(string.format("%s/%s", finishedStarNum, totalStarNum))
  self.RedDot_1:SetupKey(371, self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId())
end

function UMG_FormationPanel_C:_InitSkill()
  self:OnTeamEquipMagic(0)
end

function UMG_FormationPanel_C:AddPetToTeam(petData, position)
  if position < 1 or position > 6 or petData.gid == nil then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.AddPetToTeam, petData, position)
end

function UMG_FormationPanel_C:RemovePetFromTeam(petGid)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RemovePetFromTeam, petGid)
end

function UMG_FormationPanel_C:UpdateTeamPetList(petDataList)
  self.CurrentTeamPets = petDataList
  if self.bIsPetListInited and self.PetList:GetItemCount() == #petDataList then
    local listDatas = self.PetList._listDatas
    for i = 1, #petDataList do
      listDatas[i].petData = petDataList[i]
      listDatas[i].bIsEditMode = self.bIsEditMode
      listDatas[i].bIsSwapMode = self.bIsSwapMode
      self.PetList:OpItemByIndex(i, 8, petDataList[i])
    end
    self:_SetPetListClickable()
    local totalCheerUpPoint = self:_CalculateCheerUpPoint(petDataList)
    self:_SetTeamCheerPoint(totalCheerUpPoint)
  else
    self:_InitPetList()
  end
  local filterList = self:_FilterPet()
  self:UpdateWarehouseList(filterList)
end

function UMG_FormationPanel_C:OnTeamEquipMagic(mainTeamIndex)
  local currentTeamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
  local skillId = 0
  if currentTeamInfo and currentTeamInfo.teams and currentTeamInfo.teams[mainTeamIndex + 1] then
    skillId = currentTeamInfo.teams[mainTeamIndex + 1].role_magic_gid
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    local bIsHasBlood = BagItemS and #BagItemS > 0 and true or false
    if bIsHasBlood and BagItemS then
      for i, bagItem in ipairs(BagItemS) do
        if bagItem.gid == skillId then
          self:UpdateTeamSkill(bagItem.id)
          return
        end
      end
    end
  end
  self:UpdateTeamSkill(0)
end

function UMG_FormationPanel_C:OnPetAdjust(rsp)
  local updatedPetGid = {}
  if rsp and rsp.ret_info and rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    for k, v in ipairs(rsp.ret_info.goods_change_info.changes) do
      local ItemType = v.type
      if ItemType == _G.Enum.GoodsType.GT_PET then
        table.insert(updatedPetGid, v.pet_data.gid)
      end
    end
  end
  if #updatedPetGid > 0 then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RefreshMultiplePetsBalancedData, updatedPetGid)
  end
  if not self.curSelectedPetData then
    return
  end
  self.curSelectedPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.curSelectedPetData.gid)
  self:UpdatePetDetailPanel(self.curSelectedPetData, self.curSelectedPetDataInWarehouse, self.curSelectedPetIndex)
  if self.curSelectedPetDataInWarehouse then
    local item = self.WarehouseList:GetItemByIndex(self.curSelectedPetIndex - 1)
    if item then
      item:UpdatePetData(self.curSelectedPetData)
    end
  else
    local item = self.PetList:GetItemByIndex(self.curSelectedPetIndex - 1)
    if item then
      item:UpdatePetData(self.curSelectedPetData)
    end
  end
  local index = 0
  for k, v in ipairs(self.curPetDataList) do
    if v.gid == self.curSelectedPetData.gid then
      index = k
      break
    end
  end
  if 0 ~= index then
    self.curPetDataList[index] = self.curSelectedPetData
  end
  self:_UpdateTeamCheerUpPointByCurrentTeam()
end

function UMG_FormationPanel_C:UpdateTeamSkill(skill)
  if not skill or 0 == skill then
    self.Switcher:SetActiveWidgetIndex(1)
  else
    self.Switcher:SetActiveWidgetIndex(0)
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(skill)
    if bagItemConf then
      self.Icon:SetPath(bagItemConf.icon)
    end
  end
end

function UMG_FormationPanel_C:UpdatePetDetailPanel(petContext, bIsWarehouse, index)
  if not (petContext and petContext.gid) or 0 == petContext.gid then
    self.curSelectedPetDataInWarehouse = false
    self.curSelectedPetData = {}
    self.curSelectedPetIndex = 0
    self.DetailsR:SetActiveWidgetIndex(1)
    if not self.bIsEditMode then
      if bIsWarehouse then
        self.PetList:ClearSelection()
      else
        self.WarehouseList:ClearSelection()
      end
    end
    return
  end
  self.DetailsR:SetActiveWidgetIndex(0)
  self.curSelectedPetData = petContext
  self.curSelectedPetDataInWarehouse = bIsWarehouse
  self.curSelectedPetIndex = index
  if not self.bIsEditMode then
    if bIsWarehouse then
      self.PetList:ClearSelection()
    else
      self.WarehouseList:ClearSelection()
    end
  end
  local _, level, grow, workHard = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
  self.textPetName:SetText(petContext.name)
  self.textPetLv:SetText(string.format("%s", level or petContext.level or 0))
  if 1 == petContext.gender then
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local gainText = ""
  if petContext.add_time then
    gainText = string.format("%s\239\188\140%s", os.date(_G.LuaText.medal_text_5, petContext.add_time), self:_GetPetCatchWay(petContext))
    if petContext.catch_lv then
      local latterPart = string.format(_G.LuaText.pet_experience_text_8, petContext.catch_lv)
      gainText = string.format("%s%s", gainText, latterPart)
    end
  end
  self.Dialogue:SetText(gainText)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petContext.base_conf_id)
  local petBloodConf = _G.DataConfigManager:GetPetBloodConf(petContext.blood_id)
  if petBaseConf then
    self.Attr1:InitGridView(petBaseConf.unit_type)
  end
  if petBloodConf then
    local bloodTypeList = {}
    table.insert(bloodTypeList, {
      Name = petBloodConf.blood_name,
      Path = petBloodConf.icon
    })
    self.Attr:InitGridView(bloodTypeList)
  end
  local breakThroughStarsList = PetUtils.GetBreakThroughStarsList(petContext)
  local starInitList = {}
  for i = 1, 5 do
    local item = breakThroughStarsList[i]
    local isShow = 0
    if grow >= i then
      isShow = 1
    else
      isShow = -1
    end
    table.insert(starInitList, {
      IsShow = isShow,
      bIsReset = item and 1 ~= item.IsShow,
      i
    })
  end
  self.CatchHardLv:InitGridView(starInitList)
  if self.Text then
    self.Text:SetText(_G.LuaText.weekly_challenge_text_6)
  end
  local totalStarCount = 0
  local initList = {}
  local cheerPointTable = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.CHEER_POINT_CONF)
  local tempIndex = 1
  for k, v in pairs(cheerPointTable) do
    table.insert(initList, {
      point = v.cheer_point,
      bHas = false,
      text = v.topic
    })
    local bHas, point = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsCheerUpRuleSatisfy, v.pet_type_1, v.pet_type_2, v.pet_type_3, petContext)
    if bHas then
      initList[tempIndex].bHas = true
    end
    tempIndex = tempIndex + 1
  end
  table.stableSort(initList, function(a, b)
    return a.point > b.point
  end)
  if petContext.cheer_point_info and #petContext.cheer_point_info > 0 then
    for k, v in ipairs(petContext.cheer_point_info) do
      if v.cheer_point and v.cheer_point > 0 then
        totalStarCount = totalStarCount + v.cheer_point
      end
    end
  end
  self.NRCGridView_230:InitGridView(initList)
  self.Headline:SetText(string.format("x%s", totalStarCount))
  self:PlayAnimation(self.Right_Cheer)
  if petContext.partner_mark and petContext.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
    self.UMG_CollectBtn.Switcher:SetActiveWidgetIndex(0)
    self.UMG_CollectBtn:UpdateInfo(petContext.partner_mark)
  else
    self.UMG_CollectBtn.Switcher:SetActiveWidgetIndex(1)
  end
  local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, petContext.gid)
  local petDataToDispatch = balancedPetData or _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petContext.gid)
  local bIsPetDetailOpening = self.module:HasPanel("PetDetail")
  if bIsPetDetailOpening then
    self:DispatchEvent(ModuleEvent.ChangeSelectPet, petDataToDispatch)
    self._pendingChangeSelectPetData = nil
  else
    self._pendingChangeSelectPetData = petDataToDispatch
  end
end

function UMG_FormationPanel_C:ConsumePendingChangeSelectPetData()
  local data = self._pendingChangeSelectPetData
  self._pendingChangeSelectPetData = nil
  return data
end

function UMG_FormationPanel_C:DeselectWarehousePetByIndex(index)
  self.WarehouseList:DeselectItemByIndex(index)
end

function UMG_FormationPanel_C:DeselectWarehousePetByGid(gid)
  if not gid or 0 == gid then
    return
  end
  local size = self.WarehouseList:GetItemCount()
  for ueIndex = 0, size - 1 do
    local item = self.WarehouseList:GetItemByIndex(ueIndex)
    if item and item.uiData and item.uiData.gid == gid then
      self.WarehouseList:DeselectItemByIndex(ueIndex + 1)
      return
    end
  end
end

function UMG_FormationPanel_C:DeselectTeamListPetByIndex(index)
  self.PetList:DeselectItemByIndex(index)
end

function UMG_FormationPanel_C:UpdateWarehouseList(newList, selectGid)
  local petDataList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local listWithoutTeamPet = {}
  if newList and #newList > 0 then
    for k, v in pairs(newList) do
      if not self:HasGid(v.gid, petDataList) then
        table.insert(listWithoutTeamPet, v)
      end
    end
  end
  listWithoutTeamPet = self:_SortPet(listWithoutTeamPet)
  local initList = {}
  for k, v in ipairs(listWithoutTeamPet) do
    table.insert(initList, {
      petData = v,
      parent = self,
      bIsWarehouse = true,
      bIsEditMode = self.bIsEditMode,
      bIsSwapMode = self.bIsSwapMode
    })
  end
  if listWithoutTeamPet and #listWithoutTeamPet > 0 then
    self.NRCSwitcher_2:SetActiveWidgetIndex(0)
    self.WarehouseList:InitList(initList)
    local index = 0
    if selectGid and 0 ~= selectGid then
      for k, v in ipairs(listWithoutTeamPet) do
        if selectGid == v.gid then
          index = k
          break
        end
      end
    end
    if self.curSelectedPetDataInWarehouse and index > 0 then
      self.WarehouseList:SelectItemByIndex(index - 1)
    end
    return true, index
  else
    self.NRCSwitcher_2:SetActiveWidgetIndex(1)
    return false
  end
end

function UMG_FormationPanel_C:_GetPetCatchWay(petContext)
  if petContext then
    if petContext.catch_way == Enum.PetCatchWay.PCW_WILD then
      local Count
      if petContext.caught_camp then
        local CampConf = _G.DataConfigManager:GetCampConf(petContext.caught_camp)
        if CampConf then
          Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_7").msg
          return string.format(Count, CampConf.camp_name)
        end
      end
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_1").msg
    elseif petContext.catch_way == Enum.PetCatchWay.PCW_VISIT then
      local Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_2").msg
      return string.format(Count, petContext.catch_visit_owner_name)
    elseif petContext.catch_way == Enum.PetCatchWay.PCW_EGGHATCH then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_3").msg
    elseif petContext.catch_way == Enum.PetCatchWay.PCW_DUNGEON then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_6").msg
    elseif petContext.catch_way == Enum.PetCatchWay.PCW_TEAMBATTLE then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_4").msg
    elseif petContext.catch_way == Enum.PetCatchWay.PCW_LEGEND then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_5").msg
    else
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_1").msg
    end
  end
end

function UMG_FormationPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self.calledCloseCallback = true
    self:DoClose()
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseTeamEditPanel)
  elseif Anim == self.In then
  elseif Anim == self.Right_Out then
    if self.bEnterSkillChangePanel then
      self.bEnterSkillChangePanel = false
      if not (self.curSelectedPetData and self.curSelectedPetData.gid) or 0 == self.curSelectedPetData.gid then
        return
      end
      local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, self.curSelectedPetData.gid)
      if balancedPetData then
        self.curSelectedPetData = balancedPetData
        _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenSkillPanel, {PetData = balancedPetData}, true, true, true)
      else
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.curSelectedPetData.gid)
        self.curSelectedPetData = petData
        _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenSkillPanel, {PetData = petData}, true, true, true)
      end
    elseif self.bEnterDetailPanel then
      self.bEnterDetailPanel = false
      if not (self.curSelectedPetData and self.curSelectedPetData.gid) or 0 == self.curSelectedPetData.gid then
        return
      end
      local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, self.curSelectedPetData.gid)
      if balancedPetData then
        self.curSelectedPetData = balancedPetData
        _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenSkillPanel, {PetData = balancedPetData}, true, false, false)
      else
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.curSelectedPetData.gid)
        self.curSelectedPetData = petData
        _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenSkillPanel, {PetData = petData}, true, false, false)
      end
    end
  elseif Anim == self.Press then
    self:PlayAnimation(self.Up)
  end
end

function UMG_FormationPanel_C:_FilterPet()
  if not self.curFilterRule then
    return self.curPetDataList
  end
  local typeChooseList = self.curFilterRule
  local departmentFilter = {}
  local departList = {}
  if typeChooseList.DepartmentFilter then
    for i, v in pairs(typeChooseList.DepartmentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(departmentFilter, enum)
      end
    end
  end
  if #departmentFilter > 0 then
    if not self.curPetDataList or #self.curPetDataList < 1 then
      return
    end
    for i = 1, #self.curPetDataList do
      if self.curPetDataList[i] then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.curPetDataList[i].base_conf_id)
        for k = 1, #petBaseConf.unit_type do
          for j = 1, #departmentFilter do
            if petBaseConf.unit_type[k] == departmentFilter[j] and not self:HasGid(self.curPetDataList[i].gid, departList) then
              table.insert(departList, self.curPetDataList[i])
            end
          end
        end
      end
    end
  else
    departList = self.curPetDataList
  end
  local talentFilter = {}
  local talentList = {}
  if typeChooseList.TalentFilter then
    for i, v in pairs(typeChooseList.TalentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(talentFilter, enum)
      end
    end
  end
  if #talentFilter > 0 then
    for i = 1, #departList do
      for j = 1, #talentFilter do
        if departList[i].talent_rank == talentFilter[j] then
          table.insert(talentList, departList[i])
          break
        end
      end
    end
  else
    talentList = departList
  end
  local naturePositiveEffectFilter = {}
  local naturePositiveEffectList = {}
  if typeChooseList.NaturePositiveEffectFilter then
    for i, v in pairs(typeChooseList.NaturePositiveEffectFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(naturePositiveEffectFilter, enum)
      end
    end
  end
  if #naturePositiveEffectFilter > 0 then
    for i = 1, #talentList do
      local naturePositive = talentList[i].changed_nature_pos_attr_type
      if not naturePositive or 0 == naturePositive then
        naturePositive = _G.DataConfigManager:GetNatureConf(talentList[i].nature).positive_effect
      else
        naturePositive = self:GetChangeAttrReqEnum(naturePositive)
      end
      for j = 1, #naturePositiveEffectFilter do
        if naturePositive == naturePositiveEffectFilter[j] then
          table.insert(naturePositiveEffectList, talentList[i])
          break
        end
      end
    end
  else
    naturePositiveEffectList = talentList
  end
  local attributeFilter = {}
  local attributeList = {}
  if typeChooseList.AttributeFilter then
    for i, v in pairs(typeChooseList.AttributeFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(attributeFilter, enum)
      end
    end
  end
  if #attributeFilter > 0 then
    for i = 1, #naturePositiveEffectList do
      for j = 1, #attributeFilter do
        if attributeFilter[j] == _G.Enum.AttributeType.AT_HPMAX and naturePositiveEffectList[i].attribute_info.hp.talent and naturePositiveEffectList[i].attribute_info.hp.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_PHYATK and naturePositiveEffectList[i].attribute_info.attack.talent and naturePositiveEffectList[i].attribute_info.attack.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEATK and naturePositiveEffectList[i].attribute_info.special_attack.talent and naturePositiveEffectList[i].attribute_info.special_attack.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_PHYDEF and naturePositiveEffectList[i].attribute_info.defense.talent and naturePositiveEffectList[i].attribute_info.defense.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEDEF and naturePositiveEffectList[i].attribute_info.special_defense.talent and naturePositiveEffectList[i].attribute_info.special_defense.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEED and naturePositiveEffectList[i].attribute_info.speed.talent and naturePositiveEffectList[i].attribute_info.speed.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
      end
    end
  else
    attributeList = naturePositiveEffectList
  end
  local PartnerMarkerFilter = {}
  local PartnerMarkerList = {}
  if typeChooseList.PartnerMarkerFilter then
    for i, v in pairs(typeChooseList.PartnerMarkerFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(PartnerMarkerFilter, enum)
      end
    end
  end
  if #PartnerMarkerFilter > 0 then
    for i = 1, #attributeList do
      for j = 1, #PartnerMarkerFilter do
        if attributeList[i].partner_mark == PartnerMarkerFilter[j] then
          table.insert(PartnerMarkerList, attributeList[i])
          break
        end
      end
    end
  else
    PartnerMarkerList = attributeList
  end
  local SpecialityFilter = {}
  local SpecialityList = {}
  if typeChooseList.SpecialityFilter then
    for i, v in pairs(typeChooseList.SpecialityFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = v.data.filter_enum_value
        table.insert(SpecialityFilter, enum)
      end
    end
  end
  if #SpecialityFilter > 0 then
    for i = 1, #PartnerMarkerList do
      for j = 1, #SpecialityFilter do
        if PartnerMarkerList[i].speciality_id then
          local petTalentConf = _G.DataConfigManager:GetPetTalentConf(PartnerMarkerList[i].speciality_id)
          if petTalentConf and petTalentConf.filter_enum_value == SpecialityFilter[j] then
            table.insert(SpecialityList, PartnerMarkerList[i])
            break
          end
        end
      end
    end
  else
    SpecialityList = PartnerMarkerList
  end
  return SpecialityList
end

function UMG_FormationPanel_C:_SortPet(filteredPetDataList)
  local list = {}
  for k, v in ipairs(filteredPetDataList) do
    table.insert(list, v)
  end
  table.stableSort(list, function(a, b)
    return a.gid < b.gid
  end)
  table.stableSort(list, function(a, b)
    return self:Compare(a, b)
  end)
  if self.isAscending then
    table.reverse(list)
  end
  return list
end

function UMG_FormationPanel_C:HasGid(gid, table)
  if not table then
    return false
  end
  for i = 1, #table do
    if table[i].gid == gid then
      return true
    end
  end
  return false
end

function UMG_FormationPanel_C:Compare(a, b)
  if self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_LEVEL_DOWN then
    return a.level > b.level
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_CATCH_DOWN then
    return a.add_time > b.add_time
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_HP_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_HPMAX].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_HPMAX].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_PHYATK_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYATK].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYATK].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_SPEATK_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEATK].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEATK].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_PHYDEF_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYDEF].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_PHYDEF].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_SPEDEF_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEDEF].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEDEF].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_SPEED_DOWN then
    return a.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEED].addi_attr > b.attribute_new_info.addi_attr_data[Enum.AttributeType.AT_SPEED].addi_attr
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_RARITY_DOWN then
    return true
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_TALENT_DOWN then
    return a.talent_rank > b.talent_rank
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_EFFORT_LEVEL_DOWN then
    local aGrowTime = a.grow_times or 0
    local bGrowTime = b.grow_times or 0
    return aGrowTime > bGrowTime
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_COLLECTION_DOWN then
    return a.partner_mark > b.partner_mark
  elseif self.curSortRuleType == _G.Enum.PetSequenceDefault.SEQUENCE_CHEER_POINT_DOWN then
    local aCheerUpPoint = 0
    local bCheerUpPoint = 0
    if a.cheer_point_info then
      for k, v in ipairs(a.cheer_point_info) do
        aCheerUpPoint = aCheerUpPoint + v.cheer_point
      end
    end
    if b.cheer_point_info then
      for k, v in ipairs(b.cheer_point_info) do
        bCheerUpPoint = bCheerUpPoint + v.cheer_point
      end
    end
    return aCheerUpPoint > bCheerUpPoint
  else
    return false
  end
end

function UMG_FormationPanel_C:OnEditModeSelect(petData)
  local index = 0
  for k, v in ipairs(self.editModeTeamPetList) do
    if not v.gid or 0 == v.gid then
      index = k
      break
    end
  end
  if 0 ~= index then
    self.editModeTeamPetList[index] = petData
    local cheerUpPoint = self:_CalculateCheerUpPoint(self.editModeTeamPetList)
    self:_SetTeamCheerPoint(cheerUpPoint)
  end
  return index
end

function UMG_FormationPanel_C:OnEditModeDeselect(petGid)
  for k, v in ipairs(self.editModeTeamPetList) do
    if v.gid and v.gid == petGid then
      self.editModeTeamPetList[k] = {}
    end
  end
  local cheerUpPoint = self:_CalculateCheerUpPoint(self.editModeTeamPetList)
  self:_SetTeamCheerPoint(cheerUpPoint)
end

function UMG_FormationPanel_C:GetEditModeTeamSlotIndexByGid(petGid)
  if not petGid or 0 == petGid then
    return 0
  end
  if not self.editModeTeamPetList then
    return 0
  end
  for k, v in ipairs(self.editModeTeamPetList) do
    if v and v.gid and v.gid == petGid then
      return k
    end
  end
  return 0
end

function UMG_FormationPanel_C:_WriteTeamBackToDataOnEditModeEnd(bIgnoreSave)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ClearTeam, true)
  for k, v in ipairs(self.editModeTeamPetList) do
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.AddPetToFirstEmptySlot, v, true)
  end
  if not bIgnoreSave then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendSaveTeamReq)
  end
end

function UMG_FormationPanel_C:_IsHigherThanLastCheerUpPoint()
  local newCheerUpPoint = self:_CalculateCheerUpPoint(self.editModeTeamPetList)
  local oldCheerUpPoint = 0
  local totalCheerUpPoint = 0
  if self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1] then
    oldCheerUpPoint = self.WeeklyChallengeEventActivityObject[1]:GetFinishWeeklyChallengeEventSchedule()
    totalCheerUpPoint = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeEventStarNum()
  end
  return newCheerUpPoint > oldCheerUpPoint or newCheerUpPoint >= totalCheerUpPoint or oldCheerUpPoint >= totalCheerUpPoint
end

function UMG_FormationPanel_C:_IsThisWeekCatchPet(petData)
  if not petData or type(petData.add_time) ~= "number" then
    return false
  end
  if not self.eventConf or type(self.eventConf.start_time) ~= "string" then
    return false
  end
  local TimeUtils = require("NewRoco.Modules.System.EnvSystem.TimeUtils")
  local startTimestamp = TimeUtils.ToTimeStamp(self.eventConf.start_time)
  if 0 == startTimestamp then
    Log.Error("UMG_FormationPanel_C:_IsThisWeekCatchPet: Failed to parse start_time:", self.eventConf.start_time)
    return false
  end
  return startTimestamp < petData.add_time
end

function UMG_FormationPanel_C:_EnterEditMode()
  if self.bIsEditMode then
    return
  end
  self:QuitSwapMode(true)
  self.bIsEditMode = true
  self.lastMode = 2
  self.DetailsR:SetActiveWidgetIndex(1)
  self.editModeTeamPetList = {
    {},
    {},
    {},
    {},
    {},
    {}
  }
  self.WarehouseList:ClearSelection()
  for i = 1, self.WarehouseList:GetItemCount() do
    self.WarehouseList:OpItemByIndex(i, 2)
  end
  self.WarehouseList:SetMultipleChoice(self.bIsEditMode)
  self.PetList:ClearSelection()
  self.PetList:SetMultipleChoice(self.bIsEditMode)
  for i = 0, self.PetList:GetItemCount() do
    local item = self.PetList:GetItemByIndex(i)
    if item and item.uiData and item.uiData.gid and 0 ~= item.uiData.gid then
      self.PetList:SelectItemByIndex(i)
    end
  end
  self.BtnQuickEdit.Title_1:SetText(_G.LuaText.weekly_challenge_text_3)
end

function UMG_FormationPanel_C:_QuitEditMode(bIgnoreSave)
  if not self.bIsEditMode then
    return
  end
  self.bIsEditMode = false
  self.DetailsR:SetActiveWidgetIndex(1)
  self.WarehouseList:ClearSelection()
  self.WarehouseList:SetMultipleChoice(self.bIsEditMode)
  for i = 1, self.PetList:GetItemCount() do
    self.PetList:OpItemByIndex(i, 3)
  end
  self.PetList:ClearSelection()
  self.PetList:SetMultipleChoice(self.bIsEditMode)
  self:_WriteTeamBackToDataOnEditModeEnd(bIgnoreSave)
  if bIgnoreSave then
    local index = -1
    local bIsInTeam = true
    for i = 1, self.PetList:GetItemCount() do
      if self.PetList:OpItemByIndex(i, 4) then
        index = 1
        bIsInTeam = true
        break
      end
    end
    if -1 == index then
      for i = 1, self.WarehouseList:GetItemCount() do
        if self.WarehouseList:OpItemByIndex(i, 4) then
          index = i
          bIsInTeam = false
          break
        end
      end
    end
    if index > 0 then
      if bIsInTeam then
        self.PetList:SelectItemByIndex(index - 1)
      else
        self.WarehouseList:SelectItemByIndex(index - 1)
      end
    end
  end
  self.BtnQuickEdit.Title_1:SetText(_G.LuaText.weekly_challenge_text_2)
end

function UMG_FormationPanel_C:_EnterSwapMode()
  if not (self.curSelectedPetData and self.curSelectedPetData.gid) or 0 == self.curSelectedPetData.gid then
    return
  end
  if self.bIsSwapMode then
    return
  end
  self:_QuitEditMode(true)
  self.bIsSwapMode = true
  self.lastMode = 1
  self:DispatchEvent(ModuleEvent.EnterSwapMode)
  self.Btn_Exchange_1.Title_1:SetText(_G.LuaText.weekly_challenge_text_5)
  for i = 1, self.PetList:GetItemCount() do
    self.PetList:OpItemByIndex(i, 0)
  end
  self.PetList:SetItemClickAble(true)
  if not self.curSelectedPetDataInWarehouse then
    self.RecyclingBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.RecyclingBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
    local activeIndex = self.NRCSwitcher_2:GetActiveWidgetIndex()
    if 1 == activeIndex then
      self.NRCImage_1:SetVisibility(UE4.ESlateVisibility.Hidden)
      self.NRCText_64:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_FormationPanel_C:QuitSwapMode(bIgnoreSave)
  if not self.bIsSwapMode then
    return
  end
  self.bIsSwapMode = false
  self:DispatchEvent(ModuleEvent.QuitSwapMode)
  self.Btn_Exchange_1.Title_1:SetText(_G.LuaText.weekly_challenge_text_4)
  for i = 1, self.PetList:GetItemCount() do
    self.PetList:OpItemByIndex(i, 1)
  end
  for i = 1, self.WarehouseList:GetItemCount() do
    self.WarehouseList:OpItemByIndex(i, 1)
  end
  self.WarehouseList:SetItemClickAble(true)
  self.RecyclingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RecyclingBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local activeIndex = self.NRCSwitcher_2:GetActiveWidgetIndex()
  if 1 == activeIndex then
    self.NRCImage_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_64:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if not bIgnoreSave then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SendSaveTeamReq)
  end
end

function UMG_FormationPanel_C:OnSwapPetDuringSwapMode(position)
  if position < 1 or position > 6 then
    return
  end
  if self.curSelectedPetDataInWarehouse then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ReplacePetByNewPetData, self.curSelectedPetData, position)
  else
    local currentPetDataList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
    local curSelectIndex = 0
    for k, v in ipairs(currentPetDataList) do
      if v.gid == self.curSelectedPetData.gid then
        curSelectIndex = k
        break
      end
    end
    if curSelectIndex > 0 then
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SwapPetPosition, curSelectIndex, position)
    end
  end
  self.WarehouseList:ClearSelection()
  self.PetList:ClearSelection()
  self:QuitSwapMode(true)
end

function UMG_FormationPanel_C:OnAddPetDuringSwapMode(position)
  if not self.bIsSwapMode then
    return
  end
  if self.curSelectedPetDataInWarehouse then
    local index = _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.AddPetToFirstEmptySlot, self.curSelectedPetData, true)
    self.WarehouseList:ClearSelection()
    self.PetList:ClearSelection()
    self:QuitSwapMode()
  else
    if position < 1 or position > 6 then
      return
    end
    local teamList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
    local index = 0
    for k, v in ipairs(teamList) do
      if v.gid == self.curSelectedPetData.gid then
        index = k
        break
      end
    end
    if index > 0 then
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.SwapPetPosition, index, position)
    end
    self.WarehouseList:ClearSelection()
    self.PetList:ClearSelection()
    self:QuitSwapMode()
  end
end

function UMG_FormationPanel_C:_GetEventConf()
  self.WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not self.WeeklyChallengeEventActivityObject or not self.WeeklyChallengeEventActivityObject[1] then
    return nil
  end
  local weekly_challenge_data = self.WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if weekly_challenge_data then
    return _G.DataConfigManager:GetWeeklyChallengeEventConf(weekly_challenge_data.event_id)
  end
  return nil
end

function UMG_FormationPanel_C:_CalculateCheerUpPoint(petDataList)
  local totalCheerUpPoint = 0
  for k, v in ipairs(petDataList) do
    if v.gid and 0 ~= v.gid and v.cheer_point_info and #v.cheer_point_info > 0 then
      for k1, v1 in ipairs(v.cheer_point_info) do
        totalCheerUpPoint = totalCheerUpPoint + v1.cheer_point
      end
    end
  end
  return totalCheerUpPoint
end

function UMG_FormationPanel_C:OnPetCollectChanged(partner_mark)
  self.curSelectedPetData.partner_mark = partner_mark
  if self.curSelectedPetDataInWarehouse then
    local item = self.WarehouseList:GetItemByIndex(self.curSelectedPetIndex - 1)
    if item then
      item:UpdatePartnerMark(partner_mark)
    end
  else
    local item = self.PetList:GetItemByIndex(self.curSelectedPetIndex - 1)
    if item then
      item:UpdatePartnerMark(partner_mark)
    end
  end
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_FormationPanel_C:OnChangePetConfirmPanelClose()
  self:StopAnimation(self.Right_Out)
  self:StopAnimation(self.Right_In)
  self:PlayAnimation(self.Right_In)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.RewardBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(41400002, "UMG_FormationPanel_C:OnChangePetConfirmPanelClose")
end

function UMG_FormationPanel_C:OnPetDataUpdate(newPetData)
  self.pendingUpdatePetGid = newPetData.gid
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.RefreshAllUsablePetBalancedData)
end

function UMG_FormationPanel_C:_DoUpdatePetDataUI(petGid)
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if not petData then
    return
  end
  for i = 0, self.PetList:GetItemCount() - 1 do
    local item = self.PetList:GetItemByIndex(i)
    if item then
      item:UpdatePetData(petData)
    end
  end
  for i = 0, self.WarehouseList:GetItemCount() - 1 do
    local item = self.WarehouseList:GetItemByIndex(i)
    if item then
      item:UpdatePetData(petData)
    end
  end
  if self.curSelectedPetData and self.curSelectedPetData.gid == petGid then
    self:UpdatePetDetailPanel(petData, self.curSelectedPetDataInWarehouse, self.curSelectedPetIndex)
  end
  local index = 0
  for k, v in ipairs(self.curPetDataList) do
    if v.gid == petGid then
      index = k
      break
    end
  end
  if 0 ~= index then
    self.curPetDataList[index] = petData
  end
end

function UMG_FormationPanel_C:_SetPetListClickable()
  self.PetList:SetItemClickAble(true)
  for i = 0, self.PetList:GetItemCount() do
    local item = self.PetList:GetItemByIndex(i)
    if item and not item:IsItemValid() then
      self.PetList:SetItemClickAbleByIndex(false, i + 1)
    end
  end
end

function UMG_FormationPanel_C:_IsSatisfyRule(petCatchList, mutationDiffTypeList, petTypeList, petData)
  if not (petData and petData.gid) or 0 == petData.gid then
    return false, 0
  end
  if not petData.cheer_point_info then
    return false, 0
  end
  for k, v in ipairs(petData.cheer_point_info) do
    local bFound1 = false
    local bFound2 = false
    local bFound3 = false
    if v.catch_way and #petCatchList > 0 then
      for k1, v1 in ipairs(petCatchList) do
        if v1 == v.catch_way then
          bFound1 = true
        end
      end
    elseif 0 == #petCatchList and (v.catch_way == nil or 0 == v.catch_way) then
      bFound1 = true
    end
    if v.mutation_type and #mutationDiffTypeList > 0 then
      for k1, v1 in ipairs(mutationDiffTypeList) do
        if v1 == v.mutation_type then
          bFound2 = true
        end
      end
    elseif 0 == #mutationDiffTypeList and (nil == v.mutation_type or 0 == v.mutation_type) then
      bFound2 = true
    end
    if v.pet_type and #petTypeList > 0 then
      for k1, v1 in ipairs(petTypeList) do
        if v1 == v.pet_type then
          bFound3 = true
        end
      end
    elseif 0 == #petTypeList and (nil == v.pet_type or 0 == v.pet_type) then
      bFound3 = true
    end
    if bFound1 and bFound2 and bFound3 then
      return true, v.cheer_point
    end
  end
  return false, 0
end

function UMG_FormationPanel_C:IsTeamSwapping()
  return self.bIsSwapMode
end

function UMG_FormationPanel_C:IsTeamEditing()
  return self.bIsEditMode
end

function UMG_FormationPanel_C:_UpdateTeamCheerUpPointByCurrentTeam()
  local petTeamList = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetCurrentTeamPetList)
  local curPetList = {}
  for k, v in ipairs(petTeamList) do
    if v.gid and 0 ~= v.gid then
      local newerPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.gid)
      table.insert(curPetList, newerPetData)
    end
  end
  local cheerUpPoint = self:_CalculateCheerUpPoint(curPetList)
  self:_SetTeamCheerPoint(cheerUpPoint)
end

function UMG_FormationPanel_C:_SetTeamCheerPoint(cheerUpPoint)
  self.Headline_1:SetText(string.format("x%s", cheerUpPoint))
  local oldCheerUpPoint = 0
  if self.WeeklyChallengeEventActivityObject and self.WeeklyChallengeEventActivityObject[1] then
    oldCheerUpPoint = self.WeeklyChallengeEventActivityObject[1]:GetFinishWeeklyChallengeEventSchedule()
  end
  if cheerUpPoint <= oldCheerUpPoint then
    self.Headline_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
  else
    self.Headline_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("000000FF"))
  end
  if self.lastCheerPoint ~= cheerUpPoint then
    self:PlayAnimation(self.Left_Cheer)
  end
  self.lastCheerPoint = cheerUpPoint
end

function UMG_FormationPanel_C:OnAllPetBalancedDataReady()
  Log.Info("UMG_FormationPanel_C:OnAllPetBalancedDataReady Refreshing all pet items")
  if self.pendingUpdatePetGid then
    self:_DoUpdatePetDataUI(self.pendingUpdatePetGid)
    self.pendingUpdatePetGid = nil
  end
  for i = 1, self.PetList:GetItemCount() do
    self.PetList:OpItemByIndex(i, 7)
  end
  for i = 1, self.WarehouseList:GetItemCount() do
    self.WarehouseList:OpItemByIndex(i, 7)
  end
  self:UpdatePetDetailPanel(self.curSelectedPetData, self.curSelectedPetDataInWarehouse, self.curSelectedPetIndex)
  if self.module and self.module:HasPanel("PetDetail") then
    local petDetailPanel = self.module:GetPanel("PetDetail")
    if petDetailPanel then
      local curGid = self.curSelectedPetData.gid
      local petData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, curGid)
      if petData then
        petDetailPanel:OnPetDataUpdate(petData)
      end
    end
  end
end

function UMG_FormationPanel_C:OnPetSkillChanged()
  self:UpdatePetDetailPanel(self.curSelectedPetData, self.curSelectedPetDataInWarehouse, self.curSelectedPetIndex)
  if self.module and self.module:HasPanel("PetDetail") then
    local petDetailPanel = self.module:GetPanel("PetDetail")
    if petDetailPanel then
      local curGid = self.curSelectedPetData.gid
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetByGid(curGid)
      petDetailPanel:OnPetDataUpdate(petData)
    end
  end
end

function UMG_FormationPanel_C:OnResetDataChangedEvent(newPetList, newResetLevel, newResetGrow, newResetWorkHard)
  for i = 1, self.PetList:GetItemCount() do
    self.PetList:OpItemByIndex(i, 7)
  end
  for i = 1, self.WarehouseList:GetItemCount() do
    self.WarehouseList:OpItemByIndex(i, 7)
  end
  self:UpdatePetDetailPanel(self.curSelectedPetData, self.curSelectedPetDataInWarehouse, self.curSelectedPetIndex)
  if self.module and self.module:HasPanel("PetDetail") then
    local petDetailPanel = self.module:GetPanel("PetDetail")
    if petDetailPanel then
      local curGid = self.curSelectedPetData.gid
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetByGid(curGid)
      if newPetList then
        for k, v in ipairs(newPetList) do
          if v.gid == curGid then
            petData = v
            break
          end
        end
      end
      petDetailPanel:OnPetDataUpdate(petData)
    end
  end
end

function UMG_FormationPanel_C:OnMultiplePetsBalancedDataReady(updatedGids)
  if not updatedGids or 0 == #updatedGids then
    return
  end
  local curGid = self.curSelectedPetData and self.curSelectedPetData.gid or 0
  local needUpdateDetail = false
  for _, gid in ipairs(updatedGids) do
    if gid == curGid then
      needUpdateDetail = true
      break
    end
  end
  if needUpdateDetail then
    local balancedPetData = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetPetBalancedDataByGid, curGid)
    if balancedPetData then
      self.curSelectedPetData = balancedPetData
    end
    self:UpdatePetDetailPanel(self.curSelectedPetData, self.curSelectedPetDataInWarehouse, self.curSelectedPetIndex)
    if self.module and self.module:HasPanel("PetDetail") then
      local petDetailPanel = self.module:GetPanel("PetDetail")
      if petDetailPanel then
        petDetailPanel:OnPetDataUpdate(self.curSelectedPetData)
      end
    end
  end
end

return UMG_FormationPanel_C

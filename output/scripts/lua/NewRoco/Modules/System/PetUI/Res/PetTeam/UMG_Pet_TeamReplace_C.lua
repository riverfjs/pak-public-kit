local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local UMG_Pet_TeamReplace_C = _G.NRCPanelBase:Extend("UMG_Pet_TeamReplace_C")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PetTeamUtils = require("NewRoco.Modules.System.PetUI.Res.PetTeam.PetTeamUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PvpBattleFilter = {
  [Enum.PlayerTeamType.PTT_PVP_BATTLE_2] = Enum.SkillDamType.SDT_WATER,
  [Enum.PlayerTeamType.PTT_PVP_BATTLE_3] = Enum.SkillDamType.SDT_INSECT
}
local PetTabType = {
  BagPet = 1,
  TrialPet = 2,
  RandomPet = 3
}
local ExChangeState = {Normal = 0, ExChanging = 1}
UMG_Pet_TeamReplace_C.SwitcherDescribeDataType = {
  None = 0,
  TeamDescription = 1,
  TeamErrorMessage = 2
}
UMG_Pet_TeamReplace_C.TabItemCountToCustomWidth = {
  [2] = 530,
  [3] = 357
}
UMG_Pet_TeamReplace_C.PetTeamUiItemCount = 6
UMG_Pet_TeamReplace_C.GridType = {
  TeamGrid = 0,
  WarehouseGrid = 1,
  RecycleBlock = 2
}
local ValueEquals = WidgetStateManager.ValueEquals
local WarehouseDefaultItemHeight = 139
local WarehouseDefaultRowCount = 3
local WarehouseDefaultColCount = 7
local DefaultSortIndexValue = -1

function UMG_Pet_TeamReplace_C:InitData()
  self.uiData = {}
  self.data = self.module:GetData("PetUIModuleData")
end

function UMG_Pet_TeamReplace_C:OnActive(teamType, selTeamIdx, petGid, slotId, mode, openType)
  if _G.GlobalConfig.DebugOpenUI then
    self:OnAddEventListener()
    NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.RefreshEditorPetTeamCache, teamType, selTeamIdx)
  local gridProxies = {
    self.TeamGridTouchProxy,
    self.WarehouseGridTouchProxy,
    self.RecycleGridTouchProxy
  }
  for i, gridProxy in ipairs(gridProxies) do
    gridProxy:ForceVolatile(true)
  end
  self:RefreshWarehouseRowAndCol()
  self.WarehouseList:InitList({})
  self.PetList:InitGridView({})
  self:OnAddEventListener()
  self.curTeamIdx = selTeamIdx
  self.curPetGid = petGid
  self.curSlotId = slotId
  do
    local _, nextState = self:GetCurrAndNextState()
    nextState.modifyPetMode = mode
    self:SetState(nextState)
  end
  self.curTeamType = teamType
  self.openType = openType
  self.curExChangeState = ExChangeState.Normal
  self.descText = {}
  self.skillId = nil
  self.uiData = {}
  do
    local _, nextState = self:GetCurrAndNextState()
    nextState.switcherDescribeData = {
      type = UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.None
    }
    self:SetState(nextState)
  end
  self.RecyclingCountMap = {}
  self.canInTeamNum = PetTeamUtils.GetCanInPetNum(teamType)
  self.canSelectNum = self.canInTeamNum
  self.data = self.module:GetData("PetUIModuleData")
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  self:SetCommonTitle()
  self:RefreshShowLockSkillBtn()
  self:InitUI()
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  if selTeamIdx and mode then
    self:RefreshPetEquipSkill()
  end
  self.trialRefreshTime = nil
  if self.curTeamType and self.curTeamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4 then
    self.trialRefreshTime = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBriefRefreshTime)
  end
  self.KeyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RandomBonus.RedDot:SetupKey(419)
  self:SetCommonComboBoxInfo(self.ComScreen)
  self:RefreshTeamData()
  self:RefreshWarehouse()
  self:UpdateRoleMagicInfo()
  self:SetPetTabType(PetTabType.BagPet)
  self:PlayAnimation(self.In)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetInQualifyingState, self.curTeamType and self.curTeamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetIsShowPetNotUnlockSkill, false)
end

function UMG_Pet_TeamReplace_C:OnTick(deltaTime)
  do
    local state = self:GetState()
    local needTick = state and state.needTick or false
    if not needTick then
      return
    end
  end
  do
    local state = self:GetState()
    local warehouseScrollToPageContext = state and state.warehouseScrollToPageContext
    local isRunning = warehouseScrollToPageContext and warehouseScrollToPageContext.isRunning
    if isRunning then
      local currScrollOffset = self.WarehouseList:GetScrollOffset()
      local subPanelSize = self.WarehouseList:GetSubCanvasPanelSize()
      local subPanelSizeX = subPanelSize and subPanelSize.X or 0
      local itemSize = self.WarehouseList:GetItemSize()
      local itemSizeX = itemSize and itemSize.X or 0
      local colCount = state and state.warehouseColCount or 1
      local pageSizeX = itemSizeX * colCount
      local maxScrollOffset = self.WarehouseList:GetMaxScrollOffset()
      maxScrollOffset = math.max(maxScrollOffset, 0)
      local warehouseCurrPageIndex = warehouseScrollToPageContext and warehouseScrollToPageContext.targetPageIndex or 1
      local targetOffset = pageSizeX * (warehouseCurrPageIndex - 1)
      targetOffset = math.min(targetOffset, maxScrollOffset)
      local diff = math.abs(targetOffset - currScrollOffset)
      local tolerance = 1
      if diff > tolerance then
        local newOffsetOffset = LuaMathUtils.FInterpTo(currScrollOffset, targetOffset, deltaTime, 10)
        local _, nextState = self:GetCurrAndNextState()
        local nextContext = {}
        table.copy(warehouseScrollToPageContext, nextContext)
        nextContext.currOffset = newOffsetOffset
        nextState.warehouseScrollToPageContext = nextContext
        self:SetState(nextState)
      else
        local _, nextState = self:GetCurrAndNextState()
        local nextContext = {}
        table.copy(warehouseScrollToPageContext, nextContext)
        nextContext.currOffset = nil
        nextContext.isRunning = false
        nextContext.isFinished = true
        nextState.warehouseScrollToPageContext = nextContext
        self:SetState(nextState)
      end
    end
  end
  do
    local state = self:GetState()
    self:RefreshWarehouseRowAndCol()
  end
end

function UMG_Pet_TeamReplace_C:OnBtnRenameClick()
  self:ResetDescText()
  local param = {
    teamType = self.curTeamType,
    TeamIdx = self.curTeamIdx,
    teamName = self:GetTeamName()
  }
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenRechristenPanel, param, nil, 2)
end

function UMG_Pet_TeamReplace_C:SetCommonComboBoxInfo(ComboBox, ComboBoxText, ComboBoxIcon)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if ComboBoxText then
    CommonDropDownListData.DropDownListText = ComboBoxText
  end
  if ComboBoxIcon then
    CommonDropDownListData.DropDownListIcon = ComboBoxIcon
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_LeftHandler = self.OpenFilterPanelBtnClick
  CommonDropDownListData.Btn_MidHandler = self.OnSortBtnButtonClick
  CommonDropDownListData.Btn_RightHandler = self.OnReversedSort
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_Pet_TeamReplace_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Pet_TeamReplace_C:IsTrialPetExpired()
  if self.trialRefreshTime then
    local servetTime = ActivityUtils.GetSvrTimestamp()
    if servetTime > self.trialRefreshTime then
      return true
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:OnDeactive()
  UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_Pet_TeamReplace")
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OnCmdTryReshowUmgPVPQualifier)
end

function UMG_Pet_TeamReplace_C:GetCurMode()
  local state = self:GetState()
  local curMode = state and state.modifyPetMode
  return curMode
end

function UMG_Pet_TeamReplace_C:GetCurExChangeState()
  local state = self:GetState()
  local curExChangeState = state and state.curExChangeState
  return curExChangeState == ExChangeState.Normal
end

function UMG_Pet_TeamReplace_C:GetCurSelPetDataGid()
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  local petGid = curSelPetData and curSelPetData.gid or 0
  return petGid
end

function UMG_Pet_TeamReplace_C:GetCurSelectIsInTeam()
  local gid = self:GetCurSelPetDataGid()
  local isInTeam = self:IsInTeam(gid)
  return isInTeam
end

function UMG_Pet_TeamReplace_C:SetPetTabType(type)
  local _, nextState = self:GetCurrAndNextState()
  nextState.petTabType = type
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnPetTeamReplaceTabSelect(tabInfoListIndex)
  tabInfoListIndex = tabInfoListIndex or 1
  local state = self:GetState()
  local tabInfoList = state and state.tabInfoList or {}
  local tabInfo = tabInfoList and tabInfoList[tabInfoListIndex]
  local TabType = tabInfo and tabInfo.tabType
  if self:IsTrialPetExpired() then
    local tips = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character4").str
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
    self:OnCloseButtonClick()
    return
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.petTabType = TabType
  nextState.isNeedGoToFirstPage = true
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:ChangePetTabData(prevType, type)
  local state = self:GetState()
  local curExChangeState = state and state.curExChangeState
  if curExChangeState == ExChangeState.ExChanging then
    self:OnExchangeBtnClick()
  end
  self:AddPetsToPetList()
  if prevType ~= type then
    local state = self:GetState()
    local curSelPetData = state and state.curSelPetData
    local petGid = curSelPetData and curSelPetData.gid
    if curSelPetData and not self:IsInTeam(petGid) then
      local _, nextState = self:GetCurrAndNextState()
      nextState.curSelPetData = nil
      self:SetState(nextState)
    end
  end
  local state = self:GetState()
  local curMode = state and state.modifyPetMode
  local prevMode = curMode
  local nextMode = prevMode
  if type == PetTabType.BagPet then
    self:RefreshUI(prevMode, nextMode)
  elseif type == PetTabType.TrialPet then
    self:RefreshUI(prevMode, nextMode)
  elseif type == PetTabType.RandomPet then
    self:RefreshUI(prevMode, nextMode)
  end
  self:SwitchUIByPetTabType(type)
end

function UMG_Pet_TeamReplace_C:OnCollectBtn()
  self:ResetDescText()
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  local petGid = curSelPetData and curSelPetData.gid
  local partner_mark = curSelPetData and curSelPetData.partner_mark
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, petGid, partner_mark)
end

function UMG_Pet_TeamReplace_C:OnRecyclingBtn()
  local state = self:GetState()
  local dragItemPetInfo = state and state.dragItemPetInfo
  local curSelPetData
  if dragItemPetInfo then
    local petData = dragItemPetInfo and dragItemPetInfo.PetData
    curSelPetData = petData and petData.PetBaseInfo
  else
    curSelPetData = state and state.curSelPetData
  end
  if not curSelPetData then
    return
  end
  local tempPetInfos = self:GetCurTempPetInfo()
  for index, value in ipairs(tempPetInfos) do
    if value.pet_gid == curSelPetData.gid then
      table.remove(tempPetInfos, index)
      break
    end
  end
  if PetUtils.CheckPvpTeamIsMirror(self.curTeamIdx, self.module.data.OpenTeamType) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_owner_inf_3)
    return false
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamInfo, tempPetInfos, self.curTeamIdx, self.module.data.OpenTeamType)
end

function UMG_Pet_TeamReplace_C:ResetWareHouseList()
  local itemcount = self.WarehouseList:GetItemCount()
  for i = 1, itemcount do
    local item = self.WarehouseList:GetChildAt(i - 1)
    if item then
    end
  end
end

function UMG_Pet_TeamReplace_C:UpdateCollect(partner_mark)
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  if not curSelPetData then
    return
  end
  local curSelPetGid = curSelPetData and curSelPetData.gid
  local prevState, nextState = self:GetCurrAndNextState()
  local nextSelPetData = {}
  table.copy(curSelPetData, nextSelPetData)
  nextSelPetData.partner_mark = partner_mark
  nextState.curSelPetData = nextSelPetData
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  if curSelPetData.is_trial_pet or team.is_mirror then
    self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CollectBtn:UpdateInfo(partner_mark)
  end
  local prevWarehousePetHeadInfo = prevState and prevState.warehousePetHeadInfo or {}
  local nextWarehousePetHeadInfo = {}
  for i = 1, #prevWarehousePetHeadInfo do
    local prevItem = prevWarehousePetHeadInfo[i]
    local petData = prevItem.PetData
    local petGid = petData and petData.gid
    local nextItem = prevItem
    local partnerMark = petData and petData.partner_mark
    if not petData then
    else
      if petGid and petGid == curSelPetGid and partnerMark and partnerMark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        local nextPetData = {}
        table.copy(petData, nextPetData)
        nextPetData.partner_mark = partner_mark
        nextItem = {}
        table.copy(prevItem, nextItem)
        prevItem.PetData = nextPetData
      else
      end
    end
    table.insert(nextWarehousePetHeadInfo, nextItem)
  end
  local prevHeadShowPetList = prevState and prevState.headShowPetList or {}
  local nextHeadShowPetList = {}
  for i = 1, #prevHeadShowPetList do
    local prevItem = prevHeadShowPetList[i]
    local petData = prevItem.PetData
    local petGid = petData and petData.gid
    local nextItem = prevItem
    local partnerMark = petData and petData.partner_mark
    if not petData then
    else
      if petGid and petGid == curSelPetGid and partnerMark and partnerMark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        local nextPetData = {}
        table.copy(petData, nextPetData)
        nextPetData.partner_mark = partner_mark
        nextItem = {}
        table.copy(prevItem, nextItem)
        prevItem.PetData = nextPetData
      else
      end
    end
    table.insert(nextHeadShowPetList, nextItem)
  end
  for i = 1, #nextWarehousePetHeadInfo do
    local prevPetInfo = nextWarehousePetHeadInfo[i]
    local petData = prevPetInfo and prevPetInfo.PetData
    local petGid = petData and petData.gid
    if petGid == curSelPetGid then
      local nextPetData = {}
      table.copy(petData, nextPetData)
      nextPetData.partner_mark = partner_mark
      local prevBasicPropertyMap = prevPetInfo and prevPetInfo.basicPropertyMap
      local nextBasicPropertyMap = {}
      table.copy(prevBasicPropertyMap, nextBasicPropertyMap)
      local basicProperty = 0
      if partner_mark then
        basicProperty = 100 - partner_mark
      end
      nextBasicPropertyMap[ProtoEnum.PetSequenceDefault.SEQUENCE_COLLECTION_DOWN] = basicProperty
      local nextPetInfo = {}
      table.copy(prevPetInfo, nextPetInfo)
      nextPetInfo.PetData = nextPetData
      nextPetInfo.basicPropertyMap = nextBasicPropertyMap
      nextWarehousePetHeadInfo[i] = nextPetInfo
      break
    end
  end
  nextState.headShowPetList = nextHeadShowPetList
  nextState.warehousePetHeadInfo = nextWarehousePetHeadInfo
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnPetTeamWarehouseItemExChanging(isInTeam, PetData)
  local _, nextState = self:GetCurrAndNextState()
  if PetData then
    if isInTeam then
      nextState.isExchangingFromPetTeam = true
    else
      nextState.isExchangingFromPetTeam = false
    end
  else
    nextState.isExchangingFromPetTeam = false
  end
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnPetTeamManagementSelChanged(selectedTeamIdx)
  local state = self:GetState()
  local prevMode = state and state.modifyPetMode
  local nextMode = prevMode
  local curExChangeState = state and state.curExChangeState
  if curExChangeState == ExChangeState.ExChanging then
    self:OnExchangeBtnClick()
  end
  self:RefreshTeamData()
  self:UpdateRoleMagicInfo()
  self:RefreshUI(prevMode, nextMode)
  local afterFilterList = state and state.afterFilterList
  local curSelPetData = state and state.curSelPetData
  local curSelPetGid = curSelPetData and curSelPetData.gid
  if afterFilterList and self.isEmptyTeam and curSelPetData then
    local findGid = false
    for i, petInfo in ipairs(afterFilterList) do
      if petInfo.PetData and petInfo.PetData.PetBaseInfo and petInfo.PetData.PetBaseInfo.gid == curSelPetGid then
        findGid = true
        break
      end
    end
    if not findGid and curSelPetGid then
      self.WarehouseList:SelectItemByIndex(0)
    end
  end
  if self.isEmptyTeam then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isNeedSelectFirstPet = true
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnAddEventListener()
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_SORT, self.SortItemInfo)
  self:RegisterEvent(self, PetUIModuleEvent.SetWarehousePetSortIndex, self.SetPetSortIndex)
  self:RegisterEvent(self, PetUIModuleEvent.TypeChooseChanged, self.OnTypeChooseChanged)
  self:RegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
  self:RegisterEvent(self, PetUIModuleEvent.PetEquipSkillFinished, self.OnPetEquipSkillFinished)
  self:RegisterEvent(self, PetUIModuleEvent.UpdatePetCollect, self.UpdateCollect)
  self:RegisterEvent(self, PetUIModuleEvent.FilterPet, self.OnFilterPet)
  self:RegisterEvent(self, PetUIModuleEvent.PlayerDataUpdate, self.OnPlayerDataUpdate)
  self:RegisterEvent(self, PetUIModuleEvent.OnBalancePetDataForPvpUpdate, self.HandleBalancePetDataForPvpUpdate)
  self:AddButtonListener(self.Btn_ShutDown, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_1, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_2, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_3, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_4, self.ResetDescText)
  self:AddButtonListener(self.Btn_ShutDown_5, self.ResetDescText)
  self:AddButtonListener(self.ExchangeGrey.btnLevelUp, self.OnBanChangeButtonClick)
  self:AddButtonListener(self.Btn_Cultivate_1.btnLevelUp, self.OnChangeButtonClick)
  self:AddButtonListener(self.RandomBonus.btnLevelUp, self.OnRandomPetBonusButtonClick)
  self:AddButtonListener(self.DeleteBtn.btnLevelUp, self.OnDeleteBtnClick)
  self:AddButtonListener(self.ExchangeBtn.btnLevelUp, self.OnExchangeBtnClick)
  self:AddButtonListener(self.ExchangeBtn_1.btnLevelUp, self.OnExchangeBtnClick)
  self:AddButtonListener(self.Return.btnClose, self.OnClose)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:AddButtonListener(self.BtnRechristen_1, self.OpenPetTips)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnCollectBtn)
  self:AddButtonListener(self.RecyclingBtn, self.OnRecyclingBtn)
  self:AddButtonListener(self.changeBtn4.btnLevelUp, self.OnClickSkillsChange)
  self:AddButtonListener(self.PetDetails.btnLevelUp, self.OnBtnCultivateClicked)
  self:AddButtonListener(self.changeBtn5.btnLevelUp, self.SaveSkillChange)
  self:AddButtonListener(self.RenameBtn.btnLevelUp, self.OnBtnRenameClick)
  self:AddButtonListener(self.ViewPet.btnLevelUp, self.OnSelectSkillClick)
  self:AddButtonListener(self.ViewPet_2.btnLevelUp, self.OnSortSkillClick)
  self:AddButtonListener(self.ViewPet_3.btnLevelUp, self.OnShowLockSkillClick)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnShareClick)
  self:AddButtonListener(self.KeyBtn.btnLevelUp, self.OnImportClick)
  self:AddButtonListener(self.Btn1.btnLevelUp, self.WarehouseGoToNextPage)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.WarehouseGoToPrevPage)
  self.Exchange_1.btnLevelUp.OnClicked:Add(self, self.OnBtnOpenMagicBag)
  self.BloodBtn.OnClicked:Add(self, self.OnBtnOpenMagicBag)
  self.BloodBtn_1.OnClicked:Add(self, self.OnBtnOpenMagicBag)
  self:RegisterEvent(self, PetUIModuleEvent.PetTeamManagementModifyTeamName, self.RefreshCurTeamUI)
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_TeamManagement_C", self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.UpdateRoleMagicInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_TeamReplace_C", self, PetUIModuleEvent.OpenChangePetConfirm, self.OnShowTipBtnClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_TeamReplace_C", self, PetUIModuleEvent.PetTeamManagementSelChanged, self.OnPetTeamManagementSelChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseMain_C", self, PetUIModuleEvent.OnBagSKillTipsPanelShowChange, self.OnBagSKillTipsPanelShowChange)
  _G.NRCEventCenter:RegisterEvent("UMG_PetWarehouseMain_C", self, PetUIModuleEvent.RefreshAdjustPetPanel, self.RefreshAdjustPetPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_TeamReplace_C", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_TeamReplace_C", self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_TeamReplace_C", self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnEquippedSuccess)
  if self.ChangePetSkillsPanel then
    self.ChangePetSkillsPanel.OnLoadPanelCallbackDelegate:Add(self, self.OnChangePetSkillPanelCallback)
  end
end

function UMG_Pet_TeamReplace_C:OnBtnCultivateClicked()
  local state = self:GetState()
  local curShowPetData = state and state.curShowPetData
  local curShowPetGid = curShowPetData and curShowPetData.gid
  local petDataInfo = curShowPetData and curShowPetData.PetBaseInfo
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petDataInfo, 1, false)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.PvpPetTeamUmg)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1014, "UMG_LobbyMain_C:OnBtnPetHeadClick")
  local skillMap = self:GetSkillMapByPetGid(curShowPetData)
  local teamParam = self:GetTeamParam(curShowPetGid)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPvpSkillData, skillMap, teamParam)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {subPanelIndex = 4, callback = nil})
end

function UMG_Pet_TeamReplace_C:SaveSkillChange()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel and ChangePetSkillsPanel and ChangePetSkillsPanel.petData and ChangePetSkillsPanel.petData.blood_id ~= Enum.PetBloodType.PBT_NIGHTMARE then
    ChangePetSkillsPanel:OnChangeButtonClick()
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.isChangeSkill = false
  self:SetState(nextState)
  self:InitFilterAndSort()
end

function UMG_Pet_TeamReplace_C:OnEquippedSuccess(_changes)
end

function UMG_Pet_TeamReplace_C:OnChangePetSkillPanelCallback()
  local _, nextState = self:GetCurrAndNextState()
  nextState.isChangePetSkillPanelLoaded = true
  self:SetState(nextState)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Pet_TeamReplace_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, PetUIModuleEvent.PET_UI_SORT, self.SortItemInfo)
  self:UnRegisterEvent(self, PetUIModuleEvent.SetWarehousePetSortIndex, self.SetPetSortIndex)
  self:UnRegisterEvent(self, PetUIModuleEvent.TypeChooseChanged, self.OnTypeChooseChanged)
  self:UnRegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnPvpPetTeamEquipPetSkills)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetEquipSkillFinished, self.OnPetEquipSkillFinished)
  self:UnRegisterEvent(self, PetUIModuleEvent.UpdatePetCollect, self.UpdateCollect)
  self:UnRegisterEvent(self, PetUIModuleEvent.FilterPet, self.OnFilterPet)
  self:UnRegisterEvent(self, PetUIModuleEvent.PlayerDataUpdate, self.OnPlayerDataUpdate)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnBalancePetDataForPvpUpdate, self.HandleBalancePetDataForPvpUpdate)
  self:RemoveButtonListener(self.Btn_ShutDown, self.ResetDescText)
  self:RemoveButtonListener(self.Btn_ShutDown_1, self.ResetDescText)
  self:RemoveButtonListener(self.Btn_ShutDown_2, self.ResetDescText)
  self:RemoveButtonListener(self.Btn_ShutDown_3, self.ResetDescText)
  self:RemoveButtonListener(self.Btn_ShutDown_4, self.ResetDescText)
  self:RemoveButtonListener(self.Btn_ShutDown_5, self.ResetDescText)
  self:RemoveButtonListener(self.Btn_Cultivate_1.btnLevelUp, self.OnChangeButtonClick)
  self:RemoveButtonListener(self.RandomBonus.btnLevelUp, self.OnRandomPetBonusButtonClick)
  self:RemoveButtonListener(self.DeleteBtn.btnLevelUp, self.OnDeleteBtnClick)
  self:RemoveButtonListener(self.ExchangeBtn.btnLevelUp, self.OnExchangeBtnClick)
  self:RemoveButtonListener(self.ExchangeBtn_1.btnLevelUp, self.OnExchangeBtnClick)
  self:RemoveButtonListener(self.Return.btnClose, self.OnClose)
  self:RemoveButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:RemoveButtonListener(self.BtnRechristen_1, self.OpenPetTips)
  self:RemoveButtonListener(self.UMG_CollectBtn.Button, self.OnCollectBtn)
  self:RemoveButtonListener(self.RecyclingBtn, self.OnRecyclingBtn)
  self:RemoveButtonListener(self.changeBtn4.btnLevelUp, self.OnClickSkillsChange)
  self:RemoveButtonListener(self.RenameBtn.btnLevelUp, self.OnBtnRenameClick)
  self:RemoveButtonListener(self.ViewPet.btnLevelUp, self.OnSelectSkillClick)
  self:RemoveButtonListener(self.ViewPet_2.btnLevelUp, self.OnSortSkillClick)
  self:RemoveButtonListener(self.ViewPet_3.btnLevelUp, self.OnShowLockSkillClick)
  self:RemoveButtonListener(self.ShareBtn.btnLevelUp, self.OnShareClick)
  self:RemoveButtonListener(self.KeyBtn.btnLevelUp, self.OnImportClick)
  self:RemoveButtonListener(self.Btn1.btnLevelUp, self.WarehouseGoToNextPage)
  self:RemoveButtonListener(self.Btn2.btnLevelUp, self.WarehouseGoToPrevPage)
  self.Exchange_1.btnLevelUp.OnClicked:Remove(self, self.OnBtnOpenMagicBag)
  self.BloodBtn.OnClicked:Remove(self, self.OnBtnOpenMagicBag)
  self.BloodBtn_1.OnClicked:Remove(self, self.OnBtnOpenMagicBag)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetTeamManagementModifyTeamName, self.RefreshCurTeamUI)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.UpdateRoleMagicInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OpenChangePetConfirm, self.OnShowTipBtnClick)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamManagementSelChanged, self.OnPetTeamManagementSelChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnBagSKillTipsPanelShowChange, self.OnBagSKillTipsPanelShowChange)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.RefreshAdjustPetPanel, self.RefreshAdjustPetPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  if self.ChangePetSkillsPanel then
    self.ChangePetSkillsPanel.OnLoadPanelCallbackDelegate:Remove(self, self.OnChangePetSkillPanelCallback)
  end
end

function UMG_Pet_TeamReplace_C:RefreshCurTeamUI()
  self.Text_1:SetText(self:GetTeamName())
end

function UMG_Pet_TeamReplace_C:UpdateRoleMagicInfo()
  local hasMagic = false
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  if team.is_mirror then
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BloodBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BloodBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Exchange_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Exchange:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if team.is_mirror then
    if team.mirror_magic_id and 0 ~= team.mirror_magic_id then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(team.mirror_magic_id)
      if BagItemConf then
        hasMagic = true
        self.Switcher_1:SetActiveWidgetIndex(0)
        self.Icon:SetPath(BagItemConf.icon)
      end
    end
  elseif team.role_magic_gid and 0 ~= team.role_magic_gid then
    local itemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByGid, team.role_magic_gid)
    if itemInfo then
      local PlayerMagicConf = _G.DataConfigManager:GetBagItemConf(itemInfo.id)
      if PlayerMagicConf then
        hasMagic = true
        self.Switcher_1:SetActiveWidgetIndex(0)
        self.Icon:SetPath(PlayerMagicConf.icon)
      end
    end
  end
  if not hasMagic then
    self.Switcher_1:SetActiveWidgetIndex(1)
  end
end

function UMG_Pet_TeamReplace_C:HandleBalancePetDataForPvpUpdate(petDataList)
  local _, nextState = self:GetCurrAndNextState()
  nextState.updateBalancedPetDataForPvpFlag = {}
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnBtnOpenMagicBag()
  local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
  if BagItemS and #BagItemS > 0 then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodLineMagic, self.curTeamType, self.curTeamIdx)
  else
    local Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_tips1")
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Conf.str)
  end
  self:ResetDescText()
end

function UMG_Pet_TeamReplace_C:OnPcClose()
  self:OnClose()
end

function UMG_Pet_TeamReplace_C:OnBloodPulse()
  self:ResetDescText()
  local state = self:GetState()
  local curShowPetData = state and state.curShowPetData
  local petBaseInfo = curShowPetData and curShowPetData.PetBaseInfo
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPetBloodPulse, petBaseInfo)
end

function UMG_Pet_TeamReplace_C:OpenPetTips()
  local state = self:GetState()
  local curShowPetData = state and state.curShowPetData
  local curShowPetGid = curShowPetData and curShowPetData.gid
  local petBaseInfo = curShowPetData and curShowPetData.PetBaseInfo
  if not petBaseInfo then
    Log.Error("\229\174\160\231\137\169\230\149\176\230\141\174\228\184\186\231\169\186,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return
  end
  self:ResetDescText()
  local TipData = {petData = petBaseInfo}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, TipData, _G.Enum.GoodsType.GT_PET)
end

function UMG_Pet_TeamReplace_C:OnPetEquipSkillFinished()
  local state = self:GetState()
  local petTabType = state and state.petTabType
  self:ChangePetTabData(petTabType, petTabType)
end

function UMG_Pet_TeamReplace_C:RefreshPetEquipSkill()
  self.data:ClearPetSkillsData()
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  if team.pet_infos then
    for _, pet in pairs(team.pet_infos) do
      local petId = pet.pet_gid
      local skills = {}
      local equip_infos = pet.equip_infos
      if equip_infos then
        for _, skillInfo in pairs(equip_infos) do
          skills[skillInfo.pos] = skillInfo.id
        end
      else
        skills = nil
      end
      self.data:SetPetSkillsData(petId, skills)
    end
  end
end

function UMG_Pet_TeamReplace_C:OpenFilterPanelBtnClick()
  self:ResetDescText()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenFilterPanel, PetUIModuleEnum.OpenSortType.TeamReplace, self.data.chooseTypeList)
end

function UMG_Pet_TeamReplace_C:OnFilterPet(typeList)
  if self.data then
    self.data.chooseTypeList = typeList
    self:OnTypeChooseChanged(typeList)
  end
end

function UMG_Pet_TeamReplace_C:OnSortBtnButtonClick()
  self:ResetDescText()
  local state = self:GetState()
  local sortIndex = state and state.sortIndex
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenSortPanel, sortIndex, PetUIModuleEnum.OpenSortType.TeamReplace)
end

function UMG_Pet_TeamReplace_C:OnRandomPetBonusButtonClick()
  local currentState = self.randomPetBonusState or {}
  local state = {}
  state.open = true
  state.starCount = currentState.starCount or 0
  state.winNum = currentState.winNum or 0
  state.hitPetNum = currentState.hitPetNum or 0
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetRandomPetBonusPanelState, state)
  if self.RandomBonus.RedDot:IsRed() then
    self.RandomBonus.RedDot:EraseRedPoint()
  end
end

function UMG_Pet_TeamReplace_C:WarehouseGoToPrevPage()
  _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_Pet_TeamReplace_C:WarehouseGoToPrevPage")
  local currState, nextState = self:GetCurrAndNextState()
  local warehouseCurrPageIndex = currState and currState.warehouseCurrPageIndex or 1
  local warehousePageCount = currState and currState.warehousePageCount or 1
  local warehouseNextPageIndex = warehouseCurrPageIndex - 1
  if warehouseNextPageIndex < 1 then
    warehouseNextPageIndex = warehousePageCount
  end
  if warehouseNextPageIndex ~= warehouseCurrPageIndex then
    local nextContext = {}
    nextContext.targetPageIndex = warehouseNextPageIndex
    nextContext.isRunning = true
    nextState.warehouseScrollToPageContext = nextContext
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:WarehouseGoToCurrPage()
  local currState, nextState = self:GetCurrAndNextState()
  local warehouseCurrPageIndex = currState and currState.warehouseCurrPageIndex or 1
  local nextContext = {}
  nextContext.targetPageIndex = warehouseCurrPageIndex
  nextContext.isRunning = true
  nextState.warehouseScrollToPageContext = nextContext
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:WarehouseGoToNextPage()
  _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_Pet_TeamReplace_C:WarehouseGoToNextPage")
  local currState, nextState = self:GetCurrAndNextState()
  local warehouseCurrPageIndex = currState and currState.warehouseCurrPageIndex or 1
  local warehousePageCount = currState and currState.warehousePageCount or 1
  local warehouseNextPageIndex = warehouseCurrPageIndex + 1
  if warehousePageCount < warehouseNextPageIndex then
    warehouseNextPageIndex = 1
  end
  if warehouseNextPageIndex ~= warehouseCurrPageIndex then
    local nextContext = {}
    nextContext.targetPageIndex = warehouseNextPageIndex
    nextContext.isRunning = true
    nextState.warehouseScrollToPageContext = nextContext
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnConstruct()
  self:SetChildViews(self.CommonPetDetails, self.UMG_PetRate, self.TeamGridTouchProxy, self.WarehouseGridTouchProxy, self.RecycleGridTouchProxy)
  self.stateManager = WidgetStateManager()
  local initOption = {}
  initOption.owner = self
  initOption.UpdateDerivedState = self.UpdateDerivedState
  initOption.DeriveStateFromProps = self.DeriveStateFromProps
  initOption.RenderWidget = self.RenderWidget
  initOption.OnWidgetDidUpdate = self.OnWidgetDidUpdate
  initOption.GetChildWidgets = self.GetChildWidgets
  initOption.autoCreateDebugger = false
  local initState = {}
  initState.headShowPetList = {}
  initState.warehousePetHeadInfo = {}
  initState.chooseTypeList = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {},
    PartnerMarkerFilter = {},
    SpecialityFilter = {},
    GetTimeFilter = {}
  }
  initState.curExChangeState = ExChangeState.Normal
  initState.isChangeSkill = false
  initState.isChangePetSkillPanelLoaded = false
  initState.enableGridTouchProxy = true
  initState.warehouseRowHeight = WarehouseDefaultItemHeight
  initState.warehouseRowCount = WarehouseDefaultRowCount
  initState.warehouseColCount = WarehouseDefaultColCount
  local fetchWarehouseUiSizeContext = {}
  fetchWarehouseUiSizeContext.restFrame = 10
  fetchWarehouseUiSizeContext.isRunning = true
  fetchWarehouseUiSizeContext.isFinished = false
  initState.fetchWarehouseUiSizeContext = fetchWarehouseUiSizeContext
  local longPressTimeConf = _G.DataConfigManager:GetGlobalConfigByKeyType("drag_mode_press_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG)
  local longPressTimeMs = longPressTimeConf and longPressTimeConf.num
  local longPressTimeSeconds = longPressTimeMs and longPressTimeMs / 1000 or 9999
  local longPressTimeSecondsDefault = 0.5
  initState.longPressTime = longPressTimeSecondsDefault
  local dragDistanceConf = _G.DataConfigManager:GetPetGlobalConfig("box_drag_minimum_distance")
  local dragDistance = dragDistanceConf and dragDistanceConf.num
  initState.dragDistanceThreshold = dragDistance or 0
  local dragAngleConf = _G.DataConfigManager:GetPetGlobalConfig("team_drag_vertical_angel")
  local dragAngle = dragAngleConf and dragAngleConf.num
  initState.dragAngleThreshold = dragAngle and 90 - dragAngle or 10
  local swipeDistanceConf = _G.DataConfigManager:GetPetGlobalConfig("vertical_swipe_distance_not_to_drag_pet")
  local swipeDistance = swipeDistanceConf and swipeDistanceConf.num
  initState.swipeDistanceThreshold = swipeDistance or 0
  local swipeAngleConf = _G.DataConfigManager:GetPetGlobalConfig("swipe_angle_to_change_team")
  local swipeAngle = swipeAngleConf and swipeAngleConf.num
  initState.swipeAngleThreshold = swipeAngle or 10
  initOption.initState = initState
  self.stateManager:Init(initOption)
end

function UMG_Pet_TeamReplace_C:OnDestruct()
  self:OnRemoveEventListener()
  UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_Pet_TeamReplace")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetInQualifyingState, false)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnDisable()
  end
  if self.data and self.data:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PvpPetTeamUmg then
    self.data:SetEnterPetPanelType(nil)
  end
  local DragItemInstance = self.DragItemInstance
  if UE.UObject.IsValid(DragItemInstance) then
    DragItemInstance:RemoveFromParent()
    self.DragItemInstance = nil
  end
  self.stateManager:DeInit()
end

function UMG_Pet_TeamReplace_C:SetParent(parent)
  self.Parent = parent
end

function UMG_Pet_TeamReplace_C:AsyncLoadSceneOver()
  UE4Helper.SetEnableWorldRendering(false, nil, "UMG_Pet_TeamReplace")
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Pet_TeamReplace_C:InitUI()
  if self.openType == PetUIModuleEnum.OpenTeamReplaceType.PvpQualifier then
    self.UMG_TeamReplaceImage:SetTeamData(self, self.curTeamType)
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_TeamReplaceImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_TeamReplaceImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:InitTeam()
  self:InitWarehouse()
  self:InitTab()
  self.Btn_Cultivate_1:SetPath("PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/ui_combtn_sure_png.ui_combtn_sure_png'")
  local state = self:GetState()
  local curMode = state and state.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    local Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_pet1")
  end
  self:RefreshCommonTitle(self.curTeamType)
  self:RefreshTitle(self.curTeamType)
end

function UMG_Pet_TeamReplace_C:RefreshCommonTitle(teamType)
  local allBattleTypeConf = _G.DataConfigManager:GetAllByName("BATTLE_TYPE_CONF")
  for i, v in pairs(allBattleTypeConf) do
    if v.player_team_type == teamType then
      self.Title1:Set_MainTitle(v.name)
      break
    end
  end
end

function UMG_Pet_TeamReplace_C:RefreshTitle(teamType)
  if teamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1 or teamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_2 or teamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_3 or teamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4 or teamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_5 then
    self.Title:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Title:SetText(_G.LuaText.PVP_rank_character2)
  else
    self.Title:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_TeamReplace_C:SetTipPanelVisible(bVisible)
  if bVisible then
  else
  end
end

function UMG_Pet_TeamReplace_C:InitTeam()
end

function UMG_Pet_TeamReplace_C:InitTab()
  local _, nextState = self:GetCurrAndNextState()
  local tabInfoList = {}
  local tabName = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character2").str
  local pvp_rank_character18Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character18")
  local pvp_rank_character18ConfStr = pvp_rank_character18Conf and pvp_rank_character18Conf.str or ""
  local pvp_rank_trial_pet_character3Conf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character3")
  local pvp_rank_trial_pet_character3ConfStr = pvp_rank_trial_pet_character3Conf and pvp_rank_trial_pet_character3Conf.str or ""
  local normalPetTabInfo = {}
  normalPetTabInfo.name = tabName
  normalPetTabInfo.tabType = PetTabType.BagPet
  local trialPetTabInfo = {}
  tabName = pvp_rank_trial_pet_character3ConfStr
  trialPetTabInfo.name = tabName
  trialPetTabInfo.tabType = PetTabType.TrialPet
  trialPetTabInfo.redKey = 382
  trialPetTabInfo.isEraseRed = true
  local randomPetTabInfo = {}
  tabName = pvp_rank_character18ConfStr
  randomPetTabInfo.name = tabName
  randomPetTabInfo.tabType = PetTabType.RandomPet
  table.insert(tabInfoList, normalPetTabInfo)
  if self.curTeamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4 then
    table.insert(tabInfoList, trialPetTabInfo)
  end
  do
    local curTeamType = self.curTeamType
    local AllowRandomPetTeamTypeMap = BattleConst.AllowRandomPetTeamTypeMap
    local allowRandomPetTeamType = curTeamType and AllowRandomPetTeamTypeMap and AllowRandomPetTeamTypeMap[curTeamType]
    if allowRandomPetTeamType then
      table.insert(tabInfoList, randomPetTabInfo)
    end
  end
  for i, tabInfo in ipairs(tabInfoList) do
    tabInfo.index = i
    tabInfo.OnSelectCallback = self.OnPetTeamReplaceTabSelect
    tabInfo.OnSelectCallbackOwner = self
  end
  nextState.tabInfoList = tabInfoList
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:InitWarehouse()
  local _, nextState = self:GetCurrAndNextState()
  nextState.sortIndex = DefaultSortIndexValue
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:RefreshTeamFromCmd()
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  local curSelPetGid = curSelPetData and curSelPetData.gid
  if curSelPetData then
    local petinfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(curSelPetGid, self.is_mirror)
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petinfo.base_conf_id)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      local _, nextState = self:GetCurrAndNextState()
      nextState.curSelPetData = petinfo
      self:SetState(nextState)
    end
  end
end

function UMG_Pet_TeamReplace_C:AddPetsToPetList()
  local currentState, nextState = self:GetCurrAndNextState()
  local currentSlotDic = currentState and currentState.slotDic or {}
  local nextTeamPetGidList = {}
  local slotIndexList = {}
  for slotIndex, _ in pairs(currentSlotDic) do
    table.insert(slotIndexList, slotIndex)
  end
  table.sort(slotIndexList)
  for i, slotIndex in ipairs(slotIndexList) do
    local petGid = currentSlotDic[slotIndex]
    if petGid then
      table.insert(nextTeamPetGidList, petGid)
    end
  end
  nextState.teamPetGidList = nextTeamPetGidList
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:BuildPetListFromGidList(petGidList, isMirror)
  local nextTeamPetList = {}
  local petList = {}
  local nextAnyTeamPetIsRandom = false
  self.trialRefreshTime = nil
  if self.curTeamType and self.curTeamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4 then
    self.trialRefreshTime = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBriefRefreshTime)
  end
  local canInTeamNum = self.canInTeamNum or 0
  for i, petGid in ipairs(petGidList) do
    local tempPetData, petInfo
    if petGid then
      local petinfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid, isMirror)
      local petBaseConf = petinfo and _G.DataConfigManager:GetPetbaseConf(petinfo.base_conf_id, true)
      local petTypeInfoType = PetUtils.GetPetTypeInfoType(petinfo)
      if petBaseConf then
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        local t = {
          level = petinfo.level,
          gid = petinfo.gid,
          energy = petinfo.energy,
          petIcon = modelConf,
          base_conf_id = petinfo.base_conf_id,
          PetBaseInfo = petinfo,
          is_trial_pet = petinfo.is_trial_pet,
          refreshTime = self.trialRefreshTime,
          skill = petinfo.skill,
          blood_id = petinfo.blood_id
        }
        tempPetData = t
        petInfo = {
          PetData = t,
          isHasPet = true,
          isPetListItem = true,
          canInTeamNum = canInTeamNum
        }
      elseif petTypeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
        local randomPetInfo = petinfo
        local temp = {
          gid = randomPetInfo.gid,
          PetBaseInfo = randomPetInfo,
          type = randomPetInfo.type
        }
        tempPetData = temp
        petInfo = {
          PetData = temp,
          isHasPet = true,
          isPetListItem = true,
          canInTeamNum = canInTeamNum
        }
        nextAnyTeamPetIsRandom = true
      end
    end
    if tempPetData then
      table.insert(nextTeamPetList, tempPetData)
    end
    if petInfo then
      table.insert(petList, petInfo)
    end
  end
  if canInTeamNum > #petList then
    for i = #petList + 1, canInTeamNum do
      table.insert(petList, {
        isHasPet = false,
        isPetListItem = true,
        canInTeamNum = canInTeamNum
      })
    end
  end
  if #petList < UMG_Pet_TeamReplace_C.PetTeamUiItemCount then
    for i = #petList + 1, UMG_Pet_TeamReplace_C.PetTeamUiItemCount do
      table.insert(petList, {
        isHasPet = false,
        isPetListItem = true,
        isLockUp = true,
        canInTeamNum = canInTeamNum
      })
    end
  end
  for i, item in ipairs(petList) do
    local petData = item and item.PetData
    local petGid = petData and petData.gid
    local key = petGid
    key = key or string.format("team-empty-slot-%s", tostring(i))
    item.key = key
    item.CallbackOwner = self
    item.OnSelectCallback = self.OnPetTeamItemSelected
  end
  return nextTeamPetList, petList, nextAnyTeamPetIsRandom
end

function UMG_Pet_TeamReplace_C:FilterRefreshUI()
  self:ResetDescText()
  self:AddPetsToPetList()
  self:RefreshWarehouse()
  local state = self:GetState()
  local petTabType = state and state.petTabType
  local curMode = state and state.modifyPetMode
  if petTabType ~= PetTabType.RandomPet then
    if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
      local _, nextState = self:GetCurrAndNextState()
      nextState.isNeedSelectFirstPet = true
      self:SetState(nextState)
    elseif curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
      local _, nextState = self:GetCurrAndNextState()
      nextState.isNeedReselectPet = true
      self:SetState(nextState)
    end
  end
end

function UMG_Pet_TeamReplace_C:GetPetDataByCurPetGid()
  if self.curPetGid then
    local state = self:GetState()
    local teamPetList = state and state.teamPetList or {}
    for _, petData in ipairs(teamPetList) do
      if petData.gid == self.curPetGid then
        return petData
      end
    end
  end
  return nil
end

function UMG_Pet_TeamReplace_C:GetFirstNotCommonEvoPet()
  local state = self:GetState()
  local teamPetList = state and state.teamPetList or {}
  local afterFilterList = state and state.afterFilterList
  local tarGetPet
  if afterFilterList and #afterFilterList > 0 then
    local _PetData = self:GetPetDataByCurPetGid()
    if #teamPetList > 0 then
      for _, petData in pairs(teamPetList) do
        if not _PetData or petData.gid ~= _PetData.gid then
          for _, petInfo in pairs(afterFilterList) do
            if petInfo.PetData then
              tarGetPet = petInfo.PetData
              break
            end
          end
          if tarGetPet then
            break
          end
        end
      end
    else
      for _, petInfo in pairs(afterFilterList) do
        tarGetPet = petInfo.PetData
        break
      end
    end
  end
  return tarGetPet
end

function UMG_Pet_TeamReplace_C:RefreshSlotDicData()
end

function UMG_Pet_TeamReplace_C:RefreshSwitcherDescribeData()
  local fantasticSkillValid = self:CheckCurrentTeamFantasticSkillValid()
  local _, nextState = self:GetCurrAndNextState()
  if not fantasticSkillValid then
    nextState.switcherDescribeData = {
      type = UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.TeamErrorMessage
    }
  else
    nextState.switcherDescribeData = {
      type = UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.TeamDescription
    }
  end
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevWarehousePetHeadInfo = prevState and prevState.warehousePetHeadInfo or {}
  local currentWarehousePetHeadInfo = currState and currState.warehousePetHeadInfo or {}
  local prevAfterFilterList = prevState and prevState.afterFilterList or {}
  local currAfterFilterList = currState and currState.afterFilterList or {}
  local prevWarehouseShowPetList = prevState and prevState.warehouseShowPetList or {}
  local currentWarehouseShowPetList = currState and currState.warehouseShowPetList or {}
  local prevTeamPetGidList = prevState and prevState.teamPetGidList or {}
  local currentTeamPetGidList = currState and currState.teamPetGidList or {}
  local prevSlotDic = prevState and prevState.slotDic or {}
  local currentSlotDic = currState and currState.slotDic or {}
  local prevSelPetData = prevState.curSelPetData
  local nextSelPetData = currState.curSelPetData
  local prevUpdateSelPetDataFlag = prevState.updateSelPetDataFlag
  local nextUpdateSelPetDataFlag = currState.updateSelPetDataFlag
  local prevHeadShowPetList = prevState.headShowPetList or {}
  local currentHeadShowPetList = currState.headShowPetList or {}
  local prevCurSelPetData = prevState.curSelPetData
  local currentSelPetData = currState.curSelPetData
  local prevShowPetData = prevState.curShowPetData
  local currentShowPetData = currState.curShowPetData
  local prevModifyPetMode = prevState and prevState.modifyPetMode
  local currentModifyPetMode = currState and currState.modifyPetMode
  local prevTeamInfoDic = prevState and prevState.teamInfoDic or {}
  local currentTeamInfoDic = currState and currState.teamInfoDic or {}
  local prevBalanceMap = prevState and prevState.balancedPetDataForPvpMap or {}
  local currentBalanceMap = currState and currState.balancedPetDataForPvpMap or {}
  local prevIsChangeSkill = prevState and prevState.isChangeSkill
  local currIsChangeSkill = currState and currState.isChangeSkill
  local prevIsChangeSkillPanelLoaded = prevState and prevState.isChangePetSkillPanelLoaded
  local currIsChangeSkillPanelLoaded = currState and currState.isChangePetSkillPanelLoaded
  local prevDragContext = prevState and prevState.dragContext
  local currDragContext = currState and currState.dragContext
  local prevTeamDragPetData = prevState and prevState.teamDragPetData
  local currTeamDragPetData = currState and currState.teamDragPetData
  local prevWarehouseDragPetData = prevState and prevState.warehouseDragPetData
  local currWarehouseDragPetData = currState and currState.warehouseDragPetData
  local prevTeamDragHoveringPetData = prevState and prevState.teamDragHoveringPetData
  local currTeamDragHoveringPetData = currState and currState.teamDragHoveringPetData
  local prevTeamDragHoveringUiDataKey = prevState and prevState.teamDragHoveringUiDataKey
  local currTeamDragHoveringUiDataKey = currState and currState.teamDragHoveringUiDataKey
  local prevWarehouseDragHoveringPetData = prevState and prevState.warehouseDragHoveringPetData
  local currWarehouseDragHoveringPetData = currState and currState.warehouseDragHoveringPetData
  local prevWarehouseDragHoveringUiDateKey = prevState and prevState.warehouseDragHoveringUiDateKey
  local currWarehouseDragHoveringUiDateKey = currState and currState.warehouseDragHoveringUiDateKey
  local prevDragPetData = prevState and prevState.dragPetData
  local currDragPetData = currState and currState.dragPetData
  local prevDragHoveringPetData = prevState and prevState.dragHoveringPetData
  local currDragHoveringPetData = currState and currState.dragHoveringPetData
  local prevDragItemPetInfo = prevState and prevState.dragItemPetInfo
  local currDragItemPetInfo = currState and currState.dragItemPetInfo
  local prevWarehouseScrollToPageContext = prevState and prevState.warehouseScrollToPageContext
  local currWarehouseScrollToPageContext = currState and currState.warehouseScrollToPageContext
  local prevFetchWarehouseUiSizeContext = prevState and prevState.fetchWarehouseUiSizeContext
  local currFetchWarehouseUiSizeContext = currState and currState.fetchWarehouseUiSizeContext
  local prevIsExchangingFromPetTeam = prevState and prevState.isExchangingFromPetTeam
  local currIsExchangingFromPetTeam = currState and currState.isExchangingFromPetTeam
  local prevEnableGridTouchProxy = prevState and prevState.enableGridTouchProxy
  local currEnableGridTouchProxy = currState and currState.enableGridTouchProxy
  local prevExChangeState = prevState and prevState.curExChangeState
  local currExChangeState = currState and currState.curExChangeState
  local prevExchangePetData = prevState and prevState.exchangePetData
  local currExchangePetData = currState and currState.exchangePetData
  local prevExchangeIsInTeam = prevState and prevState.exchangeIsInTeam
  local currExchangeIsInTeam = currState and currState.exchangeIsInTeam
  local prevWarehouseRowCount = prevState and prevState.warehouseRowCount
  local currWarehouseRowCount = currState and currState.warehouseRowCount or 1
  local prevWarehouseColCount = prevState and prevState.warehouseColCount
  local currWarehouseColCount = currState and currState.warehouseColCount or 1
  local prevRecycleInAnimPlaying = prevState and prevState.recycleInAnimPlaying
  local currRecycleInAnimPlaying = currState and currState.recycleInAnimPlaying
  local prevRecycleOutAnimPlaying = prevState and prevState.recycleOutAnimPlaying
  local currRecycleOutAnimPlaying = currState and currState.recycleOutAnimPlaying
  local prevRecycleBtnHighLightInAnimPlaying = prevState and prevState.recycleBtnHighLightInAnimPlaying
  local currRecycleBtnHighLightInAnimPlaying = currState and currState.recycleBtnHighLightInAnimPlaying
  local prevRecycleBtnHighLightOutAnimPlaying = prevState and prevState.recycleBtnHighLightOutAnimPlaying
  local currRecycleBtnHighLightOutAnimPlaying = currState and currState.recycleBtnHighLightOutAnimPlaying
  local prevIsDragHoveringRecycleArea = prevState and prevState.isDragHoveringRecycleArea
  local currIsDragHoveringRecycleArea = currState and currState.isDragHoveringRecycleArea
  local prevRecycleBtnNeedShow = prevState and prevState.recycleBtnNeedShow or false
  local currRecycleBtnNeedShow = currState and currState.recycleBtnNeedShow or false
  local prevInTeamGidDic = prevState and prevState.inTeamGidDic or {}
  local currInTeamGidDic = currState and currState.inTeamGidDic or {}
  if prevSelPetData ~= nextSelPetData then
    local deriveSelPetData = nextSelPetData
    local deriveSelPetDataAsTeamPetData = deriveSelPetData
    while deriveSelPetDataAsTeamPetData and deriveSelPetDataAsTeamPetData.PetBaseInfo do
      deriveSelPetData = deriveSelPetData.PetBaseInfo
      deriveSelPetDataAsTeamPetData = deriveSelPetData
    end
    derivedState.curSelPetData = deriveSelPetData
    local nextShowPetData = {}
    if deriveSelPetData then
      table.copy(deriveSelPetData, nextShowPetData)
      nextShowPetData.PetBaseInfo = deriveSelPetData
    else
      nextShowPetData = nil
    end
    derivedState.curShowPetData = nextShowPetData
  end
  if not ValueEquals(prevTeamPetGidList, currentTeamPetGidList) then
    local inTeamGidDic = {}
    for i, petGid in ipairs(currentTeamPetGidList) do
      if petGid then
        inTeamGidDic[petGid] = true
      end
    end
    derivedState.inTeamGidDic = inTeamGidDic
  end
  if not ValueEquals(prevSlotDic, currentSlotDic) then
    local nextTeamInfoDic = {}
    for i, petGid in pairs(currentSlotDic) do
      if petGid then
        nextTeamInfoDic[petGid] = i
      end
    end
    derivedState.teamInfoDic = nextTeamInfoDic
  end
  if not ValueEquals(prevWarehousePetHeadInfo, currentWarehousePetHeadInfo) then
    derivedState.petHeadInfo = currentWarehousePetHeadInfo
  end
  if not ValueEquals(prevAfterFilterList, currAfterFilterList) or prevWarehouseRowCount ~= currWarehouseRowCount or prevWarehouseColCount ~= currWarehouseColCount then
    local rowCount = currWarehouseRowCount
    local colCount = currWarehouseColCount
    local warehouseShowPetList = {}
    local totalPetCount = #currAfterFilterList
    local pageSize = rowCount * colCount
    local pageCount = math.ceil(totalPetCount / pageSize)
    local fullSizeList = {}
    for i, item in ipairs(currAfterFilterList) do
      table.insert(fullSizeList, item)
    end
    local fullPageCount = pageSize * pageCount
    local length = #fullSizeList
    for i = length + 1, fullPageCount do
      local petInfo = {}
      petInfo.isHasPet = false
      petInfo.key = string.format("warehouse-empty-slot-%s", tostring(i))
      table.insert(fullSizeList, petInfo)
    end
    for pageIndex = 0, pageCount - 1 do
      local pageOffset = pageIndex * pageSize
      for indexInPage = 0, pageSize - 1 do
        local row = math.floor(indexInPage / colCount)
        local col = indexInPage % colCount
        local targetIndexInPage = col * rowCount + row
        local sourceIndex = pageOffset + indexInPage + 1
        local targetIndex = pageOffset + targetIndexInPage + 1
        if fullPageCount >= sourceIndex then
          warehouseShowPetList[targetIndex] = fullSizeList[sourceIndex]
        end
      end
    end
    local sortedList = {}
    for i = 1, fullPageCount do
      if warehouseShowPetList[i] then
        table.insert(sortedList, warehouseShowPetList[i])
      end
    end
    warehouseShowPetList = sortedList
    derivedState.warehouseShowPetList = warehouseShowPetList
    derivedState.warehousePageCount = pageCount
  end
  if not (prevModifyPetMode == currentModifyPetMode and ValueEquals(prevTeamInfoDic, currentTeamInfoDic) and ValueEquals(prevWarehouseShowPetList, currentWarehouseShowPetList)) or prevCurSelPetData ~= currentSelPetData or prevDragItemPetInfo ~= currDragItemPetInfo or prevDragHoveringPetData ~= currDragHoveringPetData or prevWarehouseDragHoveringUiDateKey ~= currWarehouseDragHoveringUiDateKey or prevExchangePetData ~= currExchangePetData or prevExchangeIsInTeam ~= currExchangeIsInTeam then
    local currentSelPetGid = currentSelPetData and currentSelPetData.gid
    derivedState.warehouseShowPetList = UMG_Pet_TeamReplace_C.UpdatePetListUIState(currentWarehouseShowPetList, currentTeamInfoDic, currentSelPetGid, currentModifyPetMode, currDragItemPetInfo, currDragHoveringPetData, currWarehouseDragHoveringUiDateKey, currExchangePetData, currExchangeIsInTeam, false, true)
  end
  if not (ValueEquals(prevWarehouseShowPetList, currentWarehouseShowPetList) and ValueEquals(prevInTeamGidDic, currInTeamGidDic)) or prevDragItemPetInfo ~= currDragItemPetInfo or prevFetchWarehouseUiSizeContext ~= currFetchWarehouseUiSizeContext then
    local isFetchingSize = nil ~= currFetchWarehouseUiSizeContext
    local warehouseListItemDataList = {}
    local draggingPetGid = currDragItemPetInfo and currDragItemPetInfo.PetData and currDragItemPetInfo.PetData.gid
    for i, petInfo in ipairs(currentWarehouseShowPetList) do
      local itemData = {}
      itemData.baseInfo = petInfo
      local petInfoGid = petInfo and petInfo.PetData and petInfo.PetData.gid
      if draggingPetGid and petInfoGid == draggingPetGid then
        itemData.petSelfIsDragging = true
      end
      itemData.key = petInfoGid
      local petData = petInfo and petInfo.PetData
      local petGid = petData and petData.gid
      itemData.isWarehouseUiItem = true
      local isInTeam = currInTeamGidDic and petGid and currInTeamGidDic[petGid] or false
      itemData.isInTeam = isInTeam
      table.insert(warehouseListItemDataList, itemData)
    end
    if isFetchingSize then
      warehouseListItemDataList = {}
    end
    derivedState.warehouseListItemDataList = warehouseListItemDataList
  end
  if not (prevModifyPetMode == currentModifyPetMode and ValueEquals(prevTeamInfoDic, currentTeamInfoDic) and ValueEquals(prevHeadShowPetList, currentHeadShowPetList)) or prevCurSelPetData ~= currentSelPetData or prevDragItemPetInfo ~= currDragItemPetInfo or prevDragHoveringPetData ~= currDragHoveringPetData or prevTeamDragHoveringUiDataKey ~= currTeamDragHoveringUiDataKey or prevExchangePetData ~= currExchangePetData or prevExchangeIsInTeam ~= currExchangeIsInTeam then
    local currentSelPetGid = currentSelPetData and currentSelPetData.gid
    derivedState.headShowPetList = UMG_Pet_TeamReplace_C.UpdatePetListUIState(currentHeadShowPetList, currentTeamInfoDic, currentSelPetGid, currentModifyPetMode, currDragItemPetInfo, currDragHoveringPetData, currTeamDragHoveringUiDataKey, currExchangePetData, currExchangeIsInTeam, true, false)
  end
  if not ValueEquals(prevHeadShowPetList, currentHeadShowPetList) or prevDragItemPetInfo ~= currDragItemPetInfo then
    local petListItemDataList = {}
    local draggingPetGid = currDragItemPetInfo and currDragItemPetInfo.PetData and currDragItemPetInfo.PetData.gid
    for i, petInfo in ipairs(currentHeadShowPetList) do
      local itemData = {}
      itemData.baseInfo = petInfo
      itemData.anyPetIsDragging = nil ~= currDragItemPetInfo
      local petInfoGid = petInfo and petInfo.PetData and petInfo.PetData.gid
      if draggingPetGid and petInfoGid == draggingPetGid then
        itemData.petSelfIsDragging = true
      end
      itemData.key = petInfoGid
      itemData.isWarehouseUiItem = false
      itemData.isInTeam = true
      table.insert(petListItemDataList, itemData)
    end
    derivedState.petListItemDataList = petListItemDataList
  end
  if not ValueEquals(prevBalanceMap, currentBalanceMap) or prevShowPetData ~= currentShowPetData then
    local currentBalancePetData = currentShowPetData and currentShowPetData.balancedPetBaseInfo
    local currentShowPetGid = currentShowPetData and currentShowPetData.gid
    local nextBalancePetData = currentShowPetGid and currentBalanceMap and currentBalanceMap[currentShowPetGid]
    if currentBalancePetData ~= nextBalancePetData then
      local nextShowPetData = {}
      local curShowPetData = currentShowPetData
      table.copy(curShowPetData, nextShowPetData)
      nextShowPetData.balancedPetBaseInfo = nextBalancePetData
      derivedState.curShowPetData = nextShowPetData
    end
  end
  if prevIsChangeSkill ~= currIsChangeSkill or prevIsChangeSkillPanelLoaded ~= currIsChangeSkillPanelLoaded then
    derivedState.changePetSkillPanelCanShow = currIsChangeSkill and currIsChangeSkillPanelLoaded
  end
  if prevDragContext ~= currDragContext and currDragContext then
    local longPressTimeout = currDragContext and currDragContext.longPressTimeout
    local overDragThreshold = currDragContext and currDragContext.overDragThreshold
    local overSwipeThreshold = currDragContext and currDragContext.overSwipeThreshold
    local currIsDraggingItem = currDragContext and currDragContext.isDraggingItem or false
    local currIsScrollingList = currDragContext and currDragContext.isScrollingList or false
    local currIsClickWhenDragEnd = currDragContext and currDragContext.isClickWhenDragEnd or false
    local prevStartPosition = prevDragContext and prevDragContext.startPosition
    local prevDragPosition = prevDragContext and prevDragContext.dragPosition
    local prevStartPositionFromTouchContext = prevDragContext and prevDragContext.startPositionFromTouchContext
    local currStartPosition = currDragContext and currDragContext.startPosition
    local currDragPosition = currDragContext and currDragContext.dragPosition
    local currStartPositionFromTouchContext = currDragContext and currDragContext.startPositionFromTouchContext
    local nextIsDraggingItem = longPressTimeout or overDragThreshold or false
    local nextIsScrollingList = overSwipeThreshold or false
    local nextIsClickWhenDragEnd = true
    if currIsDraggingItem or currIsScrollingList then
      nextIsClickWhenDragEnd = false
    end
    local nextDragContext = {}
    table.copy(currDragContext, nextDragContext)
    if currIsDraggingItem ~= nextIsDraggingItem then
      nextDragContext.isDraggingItem = nextIsDraggingItem
    end
    if currIsScrollingList ~= nextIsScrollingList then
      nextDragContext.isScrollingList = nextIsScrollingList
    end
    if currIsClickWhenDragEnd ~= nextIsClickWhenDragEnd then
      nextDragContext.isClickWhenDragEnd = nextIsClickWhenDragEnd
    end
    if (prevStartPosition ~= currStartPosition or prevDragPosition ~= currDragPosition or prevStartPositionFromTouchContext ~= currStartPositionFromTouchContext) and currStartPosition and currDragPosition and currStartPositionFromTouchContext then
      local deltaPosition = currDragPosition - currStartPosition
      local dragPositionFromTouchContext = currStartPositionFromTouchContext + deltaPosition
      nextDragContext.dragPositionFromTouchContext = dragPositionFromTouchContext
    end
    if not ValueEquals(nextDragContext, currDragContext) then
      derivedState.dragContext = nextDragContext
    end
  end
  if prevTeamDragPetData ~= currTeamDragPetData or prevWarehouseDragPetData ~= currWarehouseDragPetData then
    local dragPetData
    if currTeamDragPetData then
      dragPetData = currTeamDragPetData
    elseif currWarehouseDragPetData then
      dragPetData = currWarehouseDragPetData
    end
    derivedState.dragPetData = dragPetData
  end
  if prevTeamDragHoveringPetData ~= currTeamDragHoveringPetData or prevWarehouseDragHoveringPetData ~= currWarehouseDragHoveringPetData then
    local dragHoveringPetData
    if currTeamDragHoveringPetData then
      dragHoveringPetData = currTeamDragHoveringPetData
    elseif currWarehouseDragHoveringPetData then
      dragHoveringPetData = currWarehouseDragHoveringPetData
    end
    derivedState.dragHoveringPetData = dragHoveringPetData
  end
  if prevDragPetData ~= currDragPetData or prevDragContext ~= currDragContext then
    local isDraggingItem = currDragContext and currDragContext.isDraggingItem
    local currDragPetDataId = currDragPetData and currDragPetData.gid
    local petInfo
    if isDraggingItem and currDragPetDataId then
      if currDragPetData == currTeamDragPetData then
        for i, teamPetInfo in ipairs(currentHeadShowPetList) do
          local teamPetData = teamPetInfo and teamPetInfo.PetData
          local teamPetInfoId = teamPetData and teamPetData.gid
          if teamPetInfoId and teamPetInfoId == currDragPetDataId then
            petInfo = {}
            table.copy(teamPetInfo, petInfo)
          end
        end
      elseif currDragPetData == currWarehouseDragPetData then
        for i, warehousePetInfo in ipairs(currentWarehouseShowPetList) do
          local warehousePetData = warehousePetInfo and warehousePetInfo.PetData
          local warehousePetInfoId = warehousePetData and warehousePetData.gid
          if warehousePetInfoId and warehousePetInfoId == currDragPetDataId then
            petInfo = {}
            table.copy(warehousePetInfo, petInfo)
          end
        end
      end
      if petInfo then
        local petData = petInfo and petInfo.PetData
        local petGid = petData and petData.gid
        local contextId = currDragContext and currDragContext.id
        petInfo.key = string.format("%s-%s", tostring(petGid), tostring(contextId))
        petInfo.isSelect = true
      end
    end
    derivedState.dragItemPetInfo = petInfo
  end
  if prevWarehouseScrollToPageContext ~= currWarehouseScrollToPageContext or prevFetchWarehouseUiSizeContext ~= currFetchWarehouseUiSizeContext then
    local nextNeedTick = false
    local isScrollingRunning = currWarehouseScrollToPageContext and currWarehouseScrollToPageContext.isRunning or false
    if isScrollingRunning then
      nextNeedTick = true
    end
    if currFetchWarehouseUiSizeContext and currFetchWarehouseUiSizeContext.isRunning then
      nextNeedTick = true
    end
    derivedState.warehouseIsScrollingToPage = isScrollingRunning
    derivedState.needTick = nextNeedTick
  end
  if prevEnableGridTouchProxy ~= currEnableGridTouchProxy or prevDragContext ~= currDragContext or prevIsExchangingFromPetTeam ~= currIsExchangingFromPetTeam or prevKey ~= currKey then
    local isDraggingItem = currDragContext and currDragContext.isDraggingItem or false
    local enableTeamGridTouchProxy = true
    local enableWarehouseGridTouchProxy = true
    local enableRecycleGridTouchProxy = false
    if currIsExchangingFromPetTeam then
      enableWarehouseGridTouchProxy = false
    end
    if currIsExchangingFromPetTeam and isDraggingItem then
      enableRecycleGridTouchProxy = true
    end
    if not currEnableGridTouchProxy then
      enableTeamGridTouchProxy = false
      enableWarehouseGridTouchProxy = false
      enableRecycleGridTouchProxy = false
    end
    derivedState.enableTeamGridTouchProxy = enableTeamGridTouchProxy
    derivedState.enableWarehouseGridTouchProxy = enableWarehouseGridTouchProxy
    derivedState.enableRecycleGridTouchProxy = enableRecycleGridTouchProxy
  end
  if prevModifyPetMode ~= currentModifyPetMode or prevExChangeState ~= currExChangeState then
    local enableTriggerDragAndScroll = true
    if currentModifyPetMode == PetUIModuleEnum.ModifyPetMode.QuickEdit or currExChangeState == ExChangeState.ExChanging then
      enableTriggerDragAndScroll = false
    end
    derivedState.enableTriggerDrag = enableTriggerDragAndScroll
  end
  if prevIsDragHoveringRecycleArea ~= currIsDragHoveringRecycleArea or prevDragItemPetInfo ~= currDragItemPetInfo or prevRecycleInAnimPlaying ~= currRecycleInAnimPlaying or prevRecycleOutAnimPlaying ~= currRecycleOutAnimPlaying or prevRecycleBtnHighLightInAnimPlaying ~= currRecycleBtnHighLightInAnimPlaying or prevRecycleBtnHighLightOutAnimPlaying ~= currRecycleBtnHighLightOutAnimPlaying then
    local recycleBtnHighLight = currIsDragHoveringRecycleArea and nil ~= currDragItemPetInfo
    if not currRecycleInAnimPlaying and not currRecycleOutAnimPlaying and not currRecycleBtnHighLightInAnimPlaying and not currRecycleBtnHighLightOutAnimPlaying then
      derivedState.recycleBtnHighLight = recycleBtnHighLight
    end
  end
  if prevIsExchangingFromPetTeam ~= currIsExchangingFromPetTeam or prevRecycleInAnimPlaying ~= currRecycleInAnimPlaying or prevRecycleOutAnimPlaying ~= currRecycleOutAnimPlaying or prevRecycleBtnHighLightInAnimPlaying ~= currRecycleBtnHighLightInAnimPlaying or prevRecycleBtnHighLightOutAnimPlaying ~= currRecycleBtnHighLightOutAnimPlaying then
    local needShow = currIsExchangingFromPetTeam
    if not currRecycleInAnimPlaying and not currRecycleOutAnimPlaying and not currRecycleBtnHighLightInAnimPlaying and not currRecycleBtnHighLightOutAnimPlaying then
      derivedState.recycleBtnNeedShow = needShow
    end
  end
  if prevRecycleBtnNeedShow ~= currRecycleBtnNeedShow or prevRecycleInAnimPlaying ~= currRecycleInAnimPlaying or prevRecycleOutAnimPlaying ~= currRecycleOutAnimPlaying or prevRecycleBtnHighLightInAnimPlaying ~= currRecycleBtnHighLightInAnimPlaying or prevRecycleBtnHighLightOutAnimPlaying ~= currRecycleBtnHighLightOutAnimPlaying then
    local showDisplay = currRecycleBtnNeedShow or false
    if currRecycleInAnimPlaying or currRecycleOutAnimPlaying or currRecycleBtnHighLightInAnimPlaying or currRecycleBtnHighLightOutAnimPlaying then
      showDisplay = true
    end
    derivedState.recycleBtnShowDisplay = showDisplay
  end
  if not ValueEquals(prevAfterFilterList, currAfterFilterList) or not ValueEquals(prevInTeamGidDic, currInTeamGidDic) then
    local warehouseCanInteractPetIdMap = {}
    for i, item in ipairs(currAfterFilterList) do
      local petData = item and item.PetData
      local petGid = petData and petData.gid
      local inTeam = currInTeamGidDic and petGid and currInTeamGidDic[petGid] or false
      if not inTeam and petGid then
        warehouseCanInteractPetIdMap[petGid] = true
      end
    end
    derivedState.warehouseCanInteractPetIdMap = warehouseCanInteractPetIdMap
  end
end

function UMG_Pet_TeamReplace_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevPetListItemDataList = prevState and prevState.petListItemDataList or {}
  local currPetListItemDataList = currState and currState.petListItemDataList or {}
  local prevWarehouseListItemDataList = prevState and prevState.warehouseListItemDataList or {}
  local currWarehouseListItemDataList = currState and currState.warehouseListItemDataList or {}
  local prevSelPetData = prevState and prevState.curSelPetData
  local nextSelPetData = currState and currState.curSelPetData
  local prevShowPetData = prevState and prevState.curShowPetData
  local nextShowPetData = currState and currState.curShowPetData
  local prevSortIndex = prevState and prevState.sortIndex
  local nextSortIndex = currState and currState.sortIndex
  local prevPvpPetTeamEquipPetSkillsUpdatedFlag = prevState and prevState.pvpPetTeamEquipPetSkillsUpdatedFlag
  local nextPvpPetTeamEquipPetSkillsUpdatedFlag = currState and currState.pvpPetTeamEquipPetSkillsUpdatedFlag
  local prevTabInfoList = prevState and prevState.tabInfoList or {}
  local currentTabInfoList = currState and currState.tabInfoList or {}
  local prevSwitcherDescribeData = prevState and prevState.switcherDescribeData or {}
  local currentSwitcherDescribeData = currState and currState.switcherDescribeData or {}
  local prevExChangeState = prevState and prevState.curExChangeState
  local currExChangeState = currState and currState.curExChangeState
  local prevChangePetSkillPanelCanShow = prevState and prevState.changePetSkillPanelCanShow
  local currChangePetSkillPanelCanShow = currState and currState.changePetSkillPanelCanShow
  local prevModifyPetMode = prevState and prevState.modifyPetMode
  local currModifyPetMode = currState and currState.modifyPetMode
  local prevDragContext = prevState and prevState.dragContext
  local currDragContext = currState and currState.dragContext
  local prevEnableGridTouchProxy = prevState and prevState.enableGridTouchProxy
  local currEnableGridTouchProxy = currState and currState.enableGridTouchProxy
  local prevDragItemPetInfo = prevState and prevState.dragItemPetInfo
  local currDragItemPetInfo = currState and currState.dragItemPetInfo
  local prevWarehouseScrollToPageContext = prevState and prevState.warehouseScrollToPageContext
  local currWarehouseScrollToPageContext = currState and currState.warehouseScrollToPageContext
  local prevWarehouseIsScrollingToPage = prevState and prevState.warehouseIsScrollingToPage
  local currWarehouseIsScrollingToPage = currState and currState.warehouseIsScrollingToPage
  local prevWarehousePageCount = prevState and prevState.warehousePageCount
  local currWarehousePageCount = currState and currState.warehousePageCount
  local prevWarehouseCurrPageIndex = prevState and prevState.warehouseCurrPageIndex
  local currWarehouseCurrPageIndex = currState and currState.warehouseCurrPageIndex
  local prevIsExchangingFromPetTeam = prevState and prevState.isExchangingFromPetTeam
  local currIsExchangingFromPetTeam = currState and currState.isExchangingFromPetTeam
  local prevRecycleInAnimPlaying = prevState and prevState.recycleInAnimPlaying
  local currRecycleInAnimPlaying = currState and currState.recycleInAnimPlaying
  local prevRecycleOutAnimPlaying = prevState and prevState.recycleOutAnimPlaying
  local currRecycleOutAnimPlaying = currState and currState.recycleOutAnimPlaying
  local prevEnableTeamGridTouchProxy = prevState and prevState.enableTeamGridTouchProxy
  local currEnableTeamGridTouchProxy = currState and currState.enableTeamGridTouchProxy
  local prevEnableWarehouseGridTouchProxy = prevState and prevState.enableWarehouseGridTouchProxy
  local currEnableWarehouseGridTouchProxy = currState and currState.enableWarehouseGridTouchProxy
  local prevEnableRecycleGridTouchProxy = prevState and prevState.enableRecycleGridTouchProxy
  local currEnableRecycleGridTouchProxy = currState and currState.enableRecycleGridTouchProxy
  local prevWarehouseRowCount = prevState and prevState.warehouseRowCount
  local currWarehouseRowCount = currState and currState.warehouseRowCount or 1
  local prevWarehouseColCount = prevState and prevState.warehouseColCount
  local currWarehouseColCount = currState and currState.warehouseColCount or 1
  local prevRecycleBtnHighLightInAnimPlaying = prevState and prevState.recycleBtnHighLightInAnimPlaying
  local currRecycleBtnHighLightInAnimPlaying = currState and currState.recycleBtnHighLightInAnimPlaying
  local prevRecycleBtnHighLightOutAnimPlaying = prevState and prevState.recycleBtnHighLightOutAnimPlaying
  local currRecycleBtnHighLightOutAnimPlaying = currState and currState.recycleBtnHighLightOutAnimPlaying
  local prevRecycleBtnShowDisplay = prevState and prevState.recycleBtnShowDisplay
  local currRecycleBtnShowDisplay = currState and currState.recycleBtnShowDisplay
  if prevPetListItemDataList ~= currPetListItemDataList then
    local HeadShowPetListRef = self.HeadShowPetList or {}
    local refreshAll = true
    if #prevPetListItemDataList == #currPetListItemDataList then
      local listLength = #currPetListItemDataList
      if #HeadShowPetListRef == listLength then
        refreshAll = false
        for i = 1, listLength do
          local prevItem = prevPetListItemDataList[i]
          local nextItem = currPetListItemDataList[i]
          local itemRef = HeadShowPetListRef[i]
          if prevItem ~= nextItem then
            table.clear(itemRef)
            itemRef.props = nextItem
            self.PetList:RefreshItemDataByIndex(i - 1)
          end
        end
      end
    end
    if refreshAll then
      local nextHeadShowPetListRef = {}
      for i, item in ipairs(currPetListItemDataList) do
        local itemRef = {}
        itemRef.props = item
        table.insert(nextHeadShowPetListRef, itemRef)
      end
      self.HeadShowPetList = nextHeadShowPetListRef
      self.PetList:InitGridView(nextHeadShowPetListRef)
    end
  end
  if prevWarehouseColCount ~= currWarehouseColCount or prevWarehouseRowCount ~= currWarehouseRowCount then
    local warehouseRowHeight = currState and currState.warehouseRowHeight or 0
    self.WarehouseList.ColCount = currWarehouseColCount
    self.WarehouseList.RowCount = currWarehouseRowCount
    local CanvasPanelSlot = self.WarehouseList.Slot
    local bottom = warehouseRowHeight * currWarehouseRowCount
    if UE.UObject.IsValid(CanvasPanelSlot) and bottom > 0 then
      local currOffset = CanvasPanelSlot:GetOffsets()
      local nextOffset = UE4.FMargin()
      nextOffset.Left = currOffset and currOffset.Left or 0
      nextOffset.Right = currOffset and currOffset.Right or 0
      nextOffset.Top = currOffset and currOffset.Top or 0
      nextOffset.Bottom = bottom
      CanvasPanelSlot:SetOffsets(nextOffset)
    end
    CanvasPanelSlot = self.WarehouseGridTouchProxy.Slot
    bottom = warehouseRowHeight * currWarehouseRowCount
    if UE.UObject.IsValid(CanvasPanelSlot) and bottom > 0 then
      local currOffset = CanvasPanelSlot:GetOffsets()
      local nextOffset = UE4.FMargin()
      nextOffset.Left = currOffset and currOffset.Left or 0
      nextOffset.Right = currOffset and currOffset.Right or 0
      nextOffset.Top = currOffset and currOffset.Top or 0
      nextOffset.Bottom = bottom
      CanvasPanelSlot:SetOffsets(nextOffset)
    end
    self.WarehouseList:InitList({})
  end
  if prevWarehouseListItemDataList ~= currWarehouseListItemDataList then
    if #prevWarehouseListItemDataList == #currWarehouseListItemDataList then
      local listLength = #currWarehouseListItemDataList
      for i = 1, listLength do
        local prevItem = prevWarehouseListItemDataList[i]
        local nextItem = currWarehouseListItemDataList[i]
        if prevItem ~= nextItem then
          local itemRef = {}
          itemRef.props = nextItem
          self.WarehouseList:UpdateList(itemRef, i)
        end
      end
    else
      local itemRefList = {}
      for i, item in ipairs(currWarehouseListItemDataList) do
        local itemRef = {}
        itemRef.props = item
        table.insert(itemRefList, itemRef)
      end
      self.WarehouseList:InitList(itemRefList)
    end
  end
  if prevWarehouseColCount ~= currWarehouseColCount or prevWarehouseRowCount ~= currWarehouseRowCount then
    self:ForceLayoutPrepass()
    self.WarehouseList:ForceLayoutPrepass()
  end
  if prevKey ~= currKey and currKey == WidgetStateManager.InitKey or prevShowPetData ~= nextShowPetData or prevPvpPetTeamEquipPetSkillsUpdatedFlag ~= nextPvpPetTeamEquipPetSkillsUpdatedFlag or prevChangePetSkillPanelCanShow ~= currChangePetSkillPanelCanShow then
    local petGid = nextShowPetData and nextShowPetData.gid
    local isRandomPet, _ = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
    local switcherActiveIndex = 0
    if currChangePetSkillPanelCanShow then
      switcherActiveIndex = 1
    elseif isRandomPet then
      switcherActiveIndex = 3
    elseif nextShowPetData then
      switcherActiveIndex = 0
      self:SetRightInfo(nextShowPetData)
    else
      switcherActiveIndex = 2
    end
    self.Switcher:SetActiveWidgetIndex(switcherActiveIndex)
  end
  if prevSortIndex ~= nextSortIndex then
    self:SetSortText(nextSortIndex)
  end
  if prevTabInfoList ~= currentTabInfoList then
    local currentCount = #currentTabInfoList
    local tabSlot = self.Tab and self.Tab.Slot
    local tabSlotSize = tabSlot and tabSlot:GetSize()
    local tabSlotSizeX = tabSlotSize and tabSlotSize.X or 0
    local tabSlotSizeY = tabSlotSize and tabSlotSize.Y or 0
    local tabItemWidth = tabSlotSizeX
    local tabItemHeight = tabSlotSizeY
    if currentCount >= 1 then
      tabItemWidth = tabSlotSizeX / currentCount
    end
    tabItemWidth = math.round(tabItemWidth)
    tabItemHeight = math.round(tabItemHeight)
    if tabItemWidth > 0 and tabItemHeight > 0 then
      self.Tab:SetCustomSize(tabItemWidth, tabItemHeight)
    end
    self.Tab:InitGridView(currentTabInfoList)
  end
  if prevSwitcherDescribeData ~= currentSwitcherDescribeData then
    local type = currentSwitcherDescribeData and currentSwitcherDescribeData.type
    if type == UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.TeamDescription then
      self.NRCSwitcher_Describe:SetActiveWidgetIndex(0)
      self.Text_1:SetText(self:GetTeamName())
    elseif type == UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.TeamErrorMessage then
      self.NRCSwitcher_Describe:SetActiveWidgetIndex(1)
    end
  end
  if prevExChangeState ~= currExChangeState then
    if currExChangeState == ExChangeState.ExChanging then
      self.ExchangeBtn:SetBtnText(LuaText.pvp_team_cancel_exchang)
      self.ExchangeBtn_1:SetBtnText(LuaText.pvp_team_cancel_exchang)
    else
      self.ExchangeBtn:SetBtnText(LuaText.umg_petbag_1)
      self.ExchangeBtn_1:SetBtnText(LuaText.umg_petbag_1)
    end
    self:ResetDescText()
  end
  if prevModifyPetMode ~= currModifyPetMode then
    if currModifyPetMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
      self.ExchangeBtn_1:SetIsEnabled(false)
    else
      self.ExchangeBtn_1:SetIsEnabled(true)
    end
  end
  if prevKey ~= currKey and currKey == WidgetStateManager.InitKey or prevEnableTeamGridTouchProxy ~= currEnableTeamGridTouchProxy or prevDragContext ~= currDragContext or prevWarehouseIsScrollingToPage ~= currWarehouseIsScrollingToPage then
    local teamProxyProps = {}
    if currEnableTeamGridTouchProxy then
      teamProxyProps.key = "teamProxy"
      teamProxyProps.gridType = UMG_Pet_TeamReplace_C.GridType.TeamGrid
      teamProxyProps.dragContext = currDragContext
      teamProxyProps.onItemSelectCallbackOwner = self
      teamProxyProps.onItemSelectCallback = self.OnItemSelectFromTeamGridTouchProxy
      teamProxyProps.onDragItemUpdateCallbackOwner = self
      teamProxyProps.onDragItemUpdateCallback = self.OnDragItemUpdateFromGridTouchProxy
      teamProxyProps.onDragHoveringItemUpdateCallbackOwner = self
      teamProxyProps.onDragHoveringItemUpdateCallback = self.OnDragHoveringItemUpdateFromGridTouchProxy
      teamProxyProps.onDragHoveringStateUpdateCallbackOwner = self
      teamProxyProps.onDragHoveringStateUpdateCallback = self.OnDragHoveringStateUpdateFromGridTouchProxy
      teamProxyProps.onStartTouchCallbackOwner = self
      teamProxyProps.onStartTouchCallback = self.OnTouchStartFromGridProxy
      teamProxyProps.isDebugMode = false
      teamProxyProps.canInteractWhenWarehouseIsScrolling = true
      teamProxyProps.warehouseIsScrollingToPage = currWarehouseIsScrollingToPage
    end
    self.TeamGridTouchProxy:SetProps(teamProxyProps)
  end
  if prevEnableTeamGridTouchProxy ~= currEnableTeamGridTouchProxy then
    local teamGridTouchProxyVisibility = UE4.ESlateVisibility.Collapsed
    if currEnableTeamGridTouchProxy then
      teamGridTouchProxyVisibility = UE.ESlateVisibility.Visible
    end
    self.TeamGridTouchProxy:SetVisibility(teamGridTouchProxyVisibility)
  end
  if prevKey ~= currKey and currKey == WidgetStateManager.InitKey or prevEnableWarehouseGridTouchProxy ~= currEnableWarehouseGridTouchProxy or prevDragContext ~= currDragContext or prevWarehouseIsScrollingToPage ~= currWarehouseIsScrollingToPage or prevWarehouseColCount ~= currWarehouseColCount or prevWarehouseRowCount ~= currWarehouseRowCount then
    local warehouseProxyProps = {}
    if currEnableWarehouseGridTouchProxy then
      warehouseProxyProps.key = "warehouseProxy"
      warehouseProxyProps.gridType = UMG_Pet_TeamReplace_C.GridType.WarehouseGrid
      warehouseProxyProps.dragContext = currDragContext
      warehouseProxyProps.onItemSelectCallbackOwner = self
      warehouseProxyProps.onItemSelectCallback = self.OnItemSelectFromTeamGridTouchProxy
      warehouseProxyProps.onDragItemUpdateCallbackOwner = self
      warehouseProxyProps.onDragItemUpdateCallback = self.OnDragItemUpdateFromGridTouchProxy
      warehouseProxyProps.onDragHoveringItemUpdateCallbackOwner = self
      warehouseProxyProps.onDragHoveringItemUpdateCallback = self.OnDragHoveringItemUpdateFromGridTouchProxy
      warehouseProxyProps.canInteractWhenWarehouseIsScrolling = false
      warehouseProxyProps.warehouseIsScrollingToPage = currWarehouseIsScrollingToPage
      warehouseProxyProps.onDragHoveringStateUpdateCallbackOwner = self
      warehouseProxyProps.onDragHoveringStateUpdateCallback = self.OnDragHoveringStateUpdateFromGridTouchProxy
      warehouseProxyProps.onStartTouchCallbackOwner = self
      warehouseProxyProps.onStartTouchCallback = self.OnTouchStartFromGridProxy
      warehouseProxyProps.onWheelDataUpdateCallback = _G.MakeWeakFunctor(self, self.OnWarehouseMouseWheelDataUpdate)
      warehouseProxyProps.rowCount = currWarehouseRowCount or 1
      warehouseProxyProps.colCount = currWarehouseColCount or 1
      warehouseProxyProps.isDebugMode = false
      if warehouseProxyProps and warehouseProxyProps.isDebugMode then
        local debugText = self:GetDragDebugText()
        warehouseProxyProps.debugText = debugText
      end
    end
    self.WarehouseGridTouchProxy:SetProps(warehouseProxyProps)
  end
  if prevEnableWarehouseGridTouchProxy ~= currEnableWarehouseGridTouchProxy then
    local warehouseGridTouchProxyVisibility = UE4.ESlateVisibility.Collapsed
    if currEnableWarehouseGridTouchProxy then
      warehouseGridTouchProxyVisibility = UE.ESlateVisibility.Visible
    end
    self.WarehouseGridTouchProxy:SetVisibility(warehouseGridTouchProxyVisibility)
  end
  if prevKey ~= currKey and currKey == WidgetStateManager.InitKey or prevEnableRecycleGridTouchProxy ~= currEnableRecycleGridTouchProxy or prevDragContext ~= currDragContext or prevWarehouseIsScrollingToPage ~= currWarehouseIsScrollingToPage then
    local recycleProxyProps = {}
    if currEnableRecycleGridTouchProxy then
      recycleProxyProps.key = "warehouseProxy"
      recycleProxyProps.gridType = UMG_Pet_TeamReplace_C.GridType.RecycleBlock
      recycleProxyProps.dragContext = currDragContext
      recycleProxyProps.onDragHoveringStateUpdateCallbackOwner = self
      recycleProxyProps.onDragHoveringStateUpdateCallback = self.OnDragHoveringStateUpdateFromGridTouchProxy
      recycleProxyProps.isDebugMode = false
    end
    self.RecycleGridTouchProxy:SetProps(recycleProxyProps)
  end
  if prevEnableRecycleGridTouchProxy ~= currEnableRecycleGridTouchProxy then
    local recycleGridTouchProxyVisibility = UE.ESlateVisibility.Collapsed
    if currEnableRecycleGridTouchProxy then
      recycleGridTouchProxyVisibility = UE.ESlateVisibility.Visible
    end
    self.RecycleGridTouchProxy:SetVisibility(recycleGridTouchProxyVisibility)
  end
  if prevDragItemPetInfo ~= currDragItemPetInfo or prevDragContext ~= currDragContext then
    local prevIsShow = nil ~= prevDragItemPetInfo
    local currIsShow = nil ~= currDragItemPetInfo
    local DragItemInstance = self.DragItemInstance
    if currIsShow and not UE.UObject.IsValid(DragItemInstance) then
      DragItemInstance = UE4.UWidgetBlueprintLibrary.Create(_G.UE4Helper.GetCurrentWorld(), self.DragItemTemplate)
      if UE.UObject.IsValid(DragItemInstance) then
        DragItemInstance:AddToViewport(_G.UILayerCtrlCenter.ENUM_LAYER.TOP_MSG, false)
        DragItemInstance:SetAlignmentInViewport(UE4.FVector2D(0.5, 0.5))
        self.DragItemInstance = DragItemInstance
      end
    end
    if UE.UObject.IsValid(DragItemInstance) then
      local position = currDragContext and currDragContext.dragPosition or UE.FVector2D(500, 500)
      local mousePosition = currDragContext and currDragContext.mousePosition or UE.FVector2D(500, 500)
      if prevIsShow ~= currIsShow then
        local dragItemVisibility = UE.ESlateVisibility.Collapsed
        if currIsShow then
          dragItemVisibility = UE.ESlateVisibility.HitTestInvisible
        end
        DragItemInstance:SetVisibility(dragItemVisibility)
      end
      if prevDragItemPetInfo ~= currDragItemPetInfo and currDragItemPetInfo then
        local itemDataRef = {}
        local props = {}
        props.key = currDragItemPetInfo and currDragItemPetInfo.key
        props.baseInfo = currDragItemPetInfo
        props.isDragItem = true
        itemDataRef.props = props
        DragItemInstance:OnItemUpdate(itemDataRef, {}, -1)
      end
      if RocoEnv.PLATFORM_WINDOWS then
        self.DragItemInstance:SetPositionInViewport(mousePosition, false)
      else
        self.DragItemInstance:SetPositionInViewport_ViewPosition(position, true)
      end
    end
  end
  if prevKey ~= currKey or prevWarehousePageCount ~= currWarehousePageCount or prevWarehouseCurrPageIndex ~= currWarehouseCurrPageIndex then
    local pageNumberText = ""
    if currWarehousePageCount then
      local stringConf = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character28", false)
      local stringTemp = stringConf and stringConf.str or ""
      local pageNumber = tostring(currWarehouseCurrPageIndex or 1)
      pageNumberText = string.format(stringTemp, pageNumber, tostring(currWarehousePageCount or 1))
    end
    self.Text_PageNumber:SetText(pageNumberText)
  end
  if prevRecycleBtnShowDisplay ~= currRecycleBtnShowDisplay then
    local recyclingBtnVisibility = UE4.ESlateVisibility.Collapsed
    if currRecycleBtnShowDisplay then
      recyclingBtnVisibility = UE4.ESlateVisibility.Visible
    end
    self.RecyclingBtn:SetVisibility(recyclingBtnVisibility)
  end
  if prevWarehousePageCount ~= currWarehousePageCount then
    local pageCount = currWarehousePageCount or 1
    local switchButtonVisibility = UE.ESlateVisibility.Collapsed
    if pageCount > 1 then
      switchButtonVisibility = UE.ESlateVisibility.SelfHitTestInvisible
    end
    self.Btn1:SetVisibility(switchButtonVisibility)
    self.Btn2:SetVisibility(switchButtonVisibility)
    self.Text_PageNumber:SetVisibility(switchButtonVisibility)
  end
end

function UMG_Pet_TeamReplace_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevWarehousePetHeadInfo = prevState and prevState.warehousePetHeadInfo or {}
  local nextWarehousePetHeadInfo = currState and currState.warehousePetHeadInfo or {}
  local prevWarehouseScrollToPageContext = prevState and prevState.warehouseScrollToPageContext
  local currWarehouseScrollToPageContext = currState and currState.warehouseScrollToPageContext
  local prevPetSortInfo = prevState and prevState.petSortInfo or {}
  local nextPetSortInfo = currState and currState.petSortInfo or {}
  local prevChooseTypeList = prevState and prevState.chooseTypeList or {}
  local nextChooseTypeList = currState and currState.chooseTypeList or {}
  local prevSortIndex = prevState and prevState.sortIndex
  local nextSortIndex = currState and currState.sortIndex
  local prevUpdateSelPetDataFlag = prevState.updateSelPetDataFlag
  local nextUpdateSelPetDataFlag = currState.updateSelPetDataFlag
  local prevTeamInfoDic = prevState.teamInfoDic or {}
  local currTeamInfoDic = currState.teamInfoDic or {}
  local prevInTeamGidDic = prevState.inTeamGidDic or {}
  local currInTeamGidDic = currState.inTeamGidDic or {}
  local prevTeamPetGidList = prevState.teamPetGidList or {}
  local currentTeamPetGidList = currState.teamPetGidList or {}
  local prevTeamPetList = prevState.teamPetList or {}
  local currentTeamPetList = currState.teamPetList or {}
  local prevAnyTeamPetIsRandom = prevState.anyTeamPetIsRandom or false
  local currentAnyTeamPetIsRandom = currState.anyTeamPetIsRandom or false
  local prevModifyPetMode = prevState and prevState.modifyPetMode
  local currentModifyPetMode = currState and currState.modifyPetMode
  local prevHeadShowPetList = prevState.headShowPetList or {}
  local currentHeadShowPetList = currState.headShowPetList or {}
  local prevAfterFilterList = prevState.afterFilterList or {}
  local currAfterFilterList = currState.afterFilterList or {}
  local prevWarehouseShowPetList = prevState.warehouseShowPetList or {}
  local currWarehouseShowPetList = currState.warehouseShowPetList or {}
  local prevSelPetData = prevState.curSelPetData
  local currSelPetData = currState.curSelPetData
  local prevSelPetDataId = prevSelPetData and prevSelPetData.gid
  local currSelPetDataId = currSelPetData and currSelPetData.gid
  local prevShowPetData = prevState.curShowPetData
  local currShowPetData = currState.curShowPetData
  local prevUpdateBalancedPetDataForPvpFlag = prevState.updateBalancedPetDataForPvpFlag
  local currentUpdateBalancedPetDataForPvpFlag = currState.updateBalancedPetDataForPvpFlag
  local prevTabInfoList = prevState and prevState.tabInfoList or {}
  local currentTabInfoList = currState and currState.tabInfoList or {}
  local prevPetTabType = prevState and prevState.petTabType
  local nextPetTabType = currState and currState.petTabType
  local prevExChangeState = prevState and prevState.curExChangeState
  local currExChangeState = currState and currState.curExChangeState
  local prevDragContext = prevState and prevState.dragContext
  local currDragContext = currState and currState.dragContext
  local prevDragItemPetInfo = prevState and prevState.dragItemPetInfo
  local currDragItemPetInfo = currState and currState.dragItemPetInfo
  local prevIsExchangingFromPetTeam = prevState and prevState.isExchangingFromPetTeam or false
  local currIsExchangingFromPetTeam = currState and currState.isExchangingFromPetTeam or false
  local prevExchangePetData = prevState and prevState.exchangePetData
  local currExchangePetData = currState and currState.exchangePetData
  local prevExchangeIsInTeam = prevState and prevState.exchangeIsInTeam
  local currExchangeIsInTeam = currState and currState.exchangeIsInTeam
  local prevFetchWarehouseUiSizeContext = prevState and prevState.fetchWarehouseUiSizeContext
  local currFetchWarehouseUiSizeContext = currState and currState.fetchWarehouseUiSizeContext
  local prevRecycleBtnHighLight = prevState and prevState.recycleBtnHighLight or false
  local currRecycleBtnHighLight = currState and currState.recycleBtnHighLight or false
  local prevRecycleBtnNeedShow = prevState and prevState.recycleBtnNeedShow or false
  local currRecycleBtnNeedShow = currState and currState.recycleBtnNeedShow or false
  local recycleBtnShowDisplay = currState and currState.recycleBtnShowDisplay or false
  local prevEnableTeamGridTouchProxy = prevState and prevState.enableTeamGridTouchProxy
  local currEnableTeamGridTouchProxy = currState and currState.enableTeamGridTouchProxy
  local prevEnableWarehouseGridTouchProxy = prevState and prevState.enableWarehouseGridTouchProxy
  local currEnableWarehouseGridTouchProxy = currState and currState.enableWarehouseGridTouchProxy
  local prevEnableRecycleGridTouchProxy = prevState and prevState.enableRecycleGridTouchProxy
  local currEnableRecycleGridTouchProxy = currState and currState.enableRecycleGridTouchProxy
  if prevWarehousePetHeadInfo ~= nextWarehousePetHeadInfo or prevSortIndex ~= nextSortIndex then
    self:SortItem(nextWarehousePetHeadInfo, nextSortIndex)
  end
  if prevPetSortInfo ~= nextPetSortInfo or prevChooseTypeList ~= nextChooseTypeList then
    local _, nextState = self:GetCurrAndNextState()
    local afterFilterList = self:RefreshPetListByChooseType(nextChooseTypeList, nextPetSortInfo)
    nextState.afterFilterList = afterFilterList
    self:SetState(nextState)
  end
  if prevChooseTypeList ~= nextChooseTypeList then
    self:OnTypeChooseUpdated(prevChooseTypeList, nextChooseTypeList)
  end
  if prevUpdateSelPetDataFlag ~= nextUpdateSelPetDataFlag then
    local _, nextState = self:GetCurrAndNextState()
    local petGid = currSelPetData and currSelPetData.gid
    local selPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid, self.is_mirror)
    nextState.curSelPetData = selPetData
    self:SetState(nextState)
  end
  if prevTeamPetGidList ~= currentTeamPetGidList then
    local _, nextState = self:GetCurrAndNextState()
    local isMirror = self.is_mirror or false
    local nextTeamPetList, petList, nextAnyTeamPetIsRandom
    nextTeamPetList, petList, nextAnyTeamPetIsRandom = self:BuildPetListFromGidList(currentTeamPetGidList, isMirror)
    nextState.teamPetList = nextTeamPetList
    nextState.headShowPetList = petList
    nextState.anyTeamPetIsRandom = nextAnyTeamPetIsRandom
    self:SetState(nextState)
  end
  if prevTeamPetList ~= currentTeamPetList or prevAnyTeamPetIsRandom ~= currentAnyTeamPetIsRandom then
    self:OnPetTeamListChanged(prevTeamPetList, currentTeamPetList, prevAnyTeamPetIsRandom, currentAnyTeamPetIsRandom)
  end
  if prevModifyPetMode == currentModifyPetMode and prevTeamInfoDic == currTeamInfoDic and prevWarehouseShowPetList == currWarehouseShowPetList and prevHeadShowPetList == currentHeadShowPetList and prevSelPetData == currSelPetData or currentModifyPetMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
  else
  end
  if prevModifyPetMode ~= currentModifyPetMode then
    self:OnModifyPetModeChanged(prevModifyPetMode, currentModifyPetMode)
  end
  if prevWarehousePetHeadInfo ~= nextWarehousePetHeadInfo or prevTeamPetList ~= currentTeamPetList or prevUpdateBalancedPetDataForPvpFlag ~= currentUpdateBalancedPetDataForPvpFlag then
    local allPetData = {}
    for i, petData in ipairs(currentTeamPetList) do
      table.insert(allPetData, petData)
    end
    for i, petInfo in ipairs(nextWarehousePetHeadInfo) do
      local petData = petInfo and petInfo.PetData
      if petData then
        table.insert(allPetData, petData)
      end
    end
    local balancedPetDataForPvpMap = self:TryFetchBalancePetData(allPetData)
    local _, nextState = self:GetCurrAndNextState()
    nextState.balancedPetDataForPvpMap = balancedPetDataForPvpMap
    self:SetState(nextState)
  end
  local prevTabInfoCount = #prevTabInfoList
  local currentTabInfoCount = #currentTabInfoList
  if prevTabInfoCount ~= currentTabInfoCount and currentTabInfoCount <= 1 then
    self:PlayAnimation(self.tab1)
  end
  if prevPetTabType ~= nextPetTabType then
    local petTabType = nextPetTabType or PetTabType.BagPet
    self.Tab:SelectItemByIndex(petTabType - 1)
    self:ChangePetTabData(prevPetTabType, nextPetTabType)
  end
  if prevExChangeState ~= currExChangeState or prevSelPetDataId ~= currSelPetDataId or prevInTeamGidDic ~= currInTeamGidDic or prevDragItemPetInfo ~= currDragItemPetInfo then
    if currExChangeState == ExChangeState.ExChanging then
      local exchangeIsInTeam = false
      local exchangePetData
      if currDragItemPetInfo then
        local petData = currDragItemPetInfo and currDragItemPetInfo.PetData
        local petDataBaseInfo = petData and petData.PetBaseInfo
        local petGid = petDataBaseInfo and petDataBaseInfo.gid
        exchangeIsInTeam = self:IsInTeam(petGid)
        exchangePetData = petDataBaseInfo
      else
        local curSelPetGid = currSelPetDataId
        exchangeIsInTeam = self:IsInTeam(curSelPetGid)
        exchangePetData = currSelPetData
      end
      local _, nextState = self:GetCurrAndNextState()
      nextState.exchangeIsInTeam = exchangeIsInTeam
      nextState.exchangePetData = exchangePetData
      self:SetState(nextState)
    else
      local _, nextState = self:GetCurrAndNextState()
      nextState.exchangeIsInTeam = nil
      nextState.exchangePetData = nil
      self:SetState(nextState)
    end
  end
  if prevWarehouseShowPetList ~= currWarehouseShowPetList then
    local isNeedSelectFirstPet = currState and currState.isNeedSelectFirstPet
    local isNeedReselectPet = currState and currState.isNeedReselectPet
    local isNeedGoToFirstPage = currState and currState.isNeedGoToFirstPage
    if isNeedGoToFirstPage then
      local _, nextState = self:GetCurrAndNextState()
      local currContext = currState and currState.warehouseScrollToPageContext
      if currContext then
      end
      local nextContext = {}
      nextContext.targetPageIndex = 1
      nextContext.isRunning = true
      nextState.warehouseScrollToPageContext = nextContext
      self:SetState(nextState)
    end
  end
  if not ValueEquals(prevAfterFilterList, currAfterFilterList) then
    self:UpdateSelectPet()
  end
  if prevDragItemPetInfo ~= currDragItemPetInfo and currDragItemPetInfo then
    local petData = currDragItemPetInfo and currDragItemPetInfo.PetData
    local _, nextState = self:GetCurrAndNextState()
    if nil == prevDragItemPetInfo and currDragItemPetInfo then
      nextState.curExChangeState = ExChangeState.ExChanging
    end
    self:SetState(nextState)
  end
  if prevWarehouseScrollToPageContext ~= currWarehouseScrollToPageContext or prevDragContext ~= currDragContext then
    local isRunning = currWarehouseScrollToPageContext and currWarehouseScrollToPageContext.isRunning
    local currOffsetFromScrollToPageContext
    if isRunning then
      local currOffset = currWarehouseScrollToPageContext and currWarehouseScrollToPageContext.currOffset
      if currOffset then
        currOffsetFromScrollToPageContext = currOffset
      end
    end
    local prevWarehouseScrollOffset = prevDragContext and prevDragContext.currWarehouseScrollOffset
    local currWarehouseScrollOffset = currDragContext and currDragContext.currWarehouseScrollOffset
    local prevIsDraggingItem = currDragContext and currDragContext.isDraggingItem
    local nextIsDraggingItem = currDragContext and currDragContext.isDraggingItem
    local currOffsetFromDragContext
    if prevWarehouseScrollOffset ~= currWarehouseScrollOffset and currWarehouseScrollOffset and not nextIsDraggingItem then
      currOffsetFromDragContext = currWarehouseScrollOffset
    end
    local finalOffset
    if currOffsetFromScrollToPageContext then
      finalOffset = currOffsetFromScrollToPageContext
    elseif currOffsetFromDragContext then
      finalOffset = currOffsetFromDragContext
    end
    if finalOffset then
      self.WarehouseList:SetScrollOffset(finalOffset)
      self.WarehouseList.OnUserScrolled:Broadcast(finalOffset)
    end
  end
  if prevDragContext ~= currDragContext then
    local prevIsDraggingItem = prevDragContext and prevDragContext.isDraggingItem
    local nextIsDraggingItem = currDragContext and currDragContext.isDraggingItem
    if (prevIsDraggingItem ~= nextIsDraggingItem and nextIsDraggingItem or prevDragContext and nil == currDragContext) and nil == currWarehouseScrollToPageContext then
      self:WarehouseGoToCurrPage()
    end
  end
  if prevWarehouseScrollToPageContext ~= currWarehouseScrollToPageContext then
    local isFinished = currWarehouseScrollToPageContext and currWarehouseScrollToPageContext.isFinished
    if isFinished then
      local pageIndex = currWarehouseScrollToPageContext and currWarehouseScrollToPageContext.targetPageIndex or 1
      local _, nextState = self:GetCurrAndNextState()
      nextState.warehouseScrollToPageContext = nil
      nextState.warehouseCurrPageIndex = pageIndex
      self:SetState(nextState)
    end
  end
  if prevDragContext ~= currDragContext then
  end
  if prevRecycleBtnNeedShow ~= currRecycleBtnNeedShow then
    if not prevRecycleBtnNeedShow and currRecycleBtnNeedShow then
      self:PlayAnimation(self.Recycle_In)
    elseif prevRecycleBtnNeedShow and not currRecycleBtnNeedShow then
      self:PlayAnimation(self.Recycle_Out)
    end
  end
  if prevExchangePetData ~= currExchangePetData or prevExchangeIsInTeam ~= currExchangeIsInTeam then
    self:OnPetTeamWarehouseItemExChanging(currExchangeIsInTeam, currExchangePetData)
  end
  if prevFetchWarehouseUiSizeContext ~= currFetchWarehouseUiSizeContext then
    local isFinished = currFetchWarehouseUiSizeContext and currFetchWarehouseUiSizeContext.isFinished
    if isFinished then
      local _, nextState = self:GetCurrAndNextState()
      nextState.fetchWarehouseUiSizeContext = nil
      self:SetState(nextState)
    end
  end
  if prevRecycleBtnHighLight ~= currRecycleBtnHighLight then
    if not prevRecycleBtnHighLight and currRecycleBtnHighLight then
      self:PlayAnimation(self.Recycle_move)
    elseif prevRecycleBtnHighLight and not currRecycleBtnHighLight and recycleBtnShowDisplay then
      self:PlayAnimation(self.Recycle_move_out)
    end
  end
  if prevEnableTeamGridTouchProxy ~= currEnableTeamGridTouchProxy and not currEnableTeamGridTouchProxy then
    self:OnDragHoveringStateUpdateFromGridTouchProxy(UMG_Pet_TeamReplace_C.GridType.TeamGrid, false, false)
  end
  if prevEnableWarehouseGridTouchProxy ~= currEnableWarehouseGridTouchProxy and not currEnableWarehouseGridTouchProxy then
    self:OnDragHoveringStateUpdateFromGridTouchProxy(UMG_Pet_TeamReplace_C.GridType.WarehouseGrid, false, false)
  end
  if prevEnableRecycleGridTouchProxy ~= currEnableRecycleGridTouchProxy and not currEnableRecycleGridTouchProxy then
    self:OnDragHoveringStateUpdateFromGridTouchProxy(UMG_Pet_TeamReplace_C.GridType.RecycleBlock, false, false)
  end
  if prevShowPetData ~= currShowPetData then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isChangeSkill = false
    self:SetState(nextState)
  end
  local prevChangePetSkillPanelCanShow = prevState and prevState.changePetSkillPanelCanShow
  local currChangePetSkillPanelCanShow = currState and currState.changePetSkillPanelCanShow
  if prevChangePetSkillPanelCanShow and not currChangePetSkillPanelCanShow and self.ChangePetSkillsPanel then
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:OnDisable()
    end
  end
end

function UMG_Pet_TeamReplace_C:UpdateSelectPet()
  local state = self:GetState()
  local isNeedSelectFirstPet = state and state.isNeedSelectFirstPet or false
  local isNeedReselectPet = state and state.isNeedReselectPet or false
  local isNeedTrySelectAfterRefreshUi = state and state.isNeedTrySelectAfterRefreshUi or false
  local isNeedGoToFirstPage = state and state.isNeedGoToFirstPage or false
  if isNeedSelectFirstPet then
    self:SelectFirstPet()
  elseif isNeedReselectPet then
    self:Reselect()
  elseif isNeedTrySelectAfterRefreshUi then
    self:TrySelectPetAfterRefreshUi()
  end
  if isNeedSelectFirstPet or isNeedReselectPet or isNeedGoToFirstPage or isNeedTrySelectAfterRefreshUi then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isNeedSelectFirstPet = false
    nextState.isNeedReselectPet = false
    nextState.isNeedGoToFirstPage = false
    nextState.isNeedTrySelectAfterRefreshUi = false
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:GetChildWidgets()
  local childWidgets = {}
  local viewChildViews = self.viewChildViews or {}
  for i, viewChildView in ipairs(viewChildViews) do
    table.insert(childWidgets, viewChildView)
  end
  local itemCount = self.PetList:GetItemCount()
  for i = 1, itemCount do
    local itemView = self.PetList:GetItemByIndex(i - 1)
    if itemView then
      table.insert(childWidgets, itemView)
    end
  end
  itemCount = self.WarehouseList:GetItemCount()
  for i = 1, itemCount do
    local itemView = self.WarehouseList:GetItemByIndex(i - 1)
    if itemView then
      table.insert(childWidgets, itemView)
    end
  end
  if UE.UObject.IsValid(self.DragItemInstance) then
    table.insert(childWidgets, self.DragItemInstance)
  end
  return childWidgets
end

function UMG_Pet_TeamReplace_C.DeriveStateFromProps(prevState, nextProps)
  return prevState
end

function UMG_Pet_TeamReplace_C:RefreshUI(prevMode, nextMode)
  self.PvpDepartmentFilter = PvpBattleFilter[self.curTeamType]
  self.data.chooseTypeList = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {}
  }
  if prevMode == PetUIModuleEnum.ModifyPetMode.SingleEdit and nextMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
  else
    self:RefreshWarehouse()
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.isNeedTrySelectAfterRefreshUi = true
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:TrySelectPetAfterRefreshUi()
  local state = self:GetState()
  local teamPetList = state and state.teamPetList or {}
  local curMode = state and state.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit and teamPetList then
    local curSelPetData = state and state.curSelPetData
    if curSelPetData then
    elseif self.curSlotId then
      local trySelectPet
      if 11 == self.curSlotId then
        if #teamPetList > 0 then
          trySelectPet = teamPetList[1]
        end
        if not trySelectPet then
          trySelectPet = self:GetFirstNotCommonEvoPet()
        end
      else
        trySelectPet = self:GetFirstNotCommonEvoPet()
      end
      if trySelectPet then
      else
      end
      local _, nextState = self:GetCurrAndNextState()
      nextState.curSelPetData = trySelectPet
      self:SetState(nextState)
      local petData = self:GetPetDataByCurPetGid()
      self:DispatchEvent(PetUIModuleEvent.PetTeamWarehouseItemLocked, petData, teamPetList)
    elseif self.curPetGid then
      self:Reselect()
    end
  elseif curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit and teamPetList then
    local curShowPetData = state and state.curShowPetData
    if curShowPetData then
    else
      if #teamPetList > 0 then
        local _, nextState = self:GetCurrAndNextState()
        local firstTeamPetInfo = teamPetList and teamPetList[1]
        local firstTeamPetData = firstTeamPetInfo and firstTeamPetInfo.PetBaseInfo
        nextState.curSelPetData = firstTeamPetData
        self:SetState(nextState)
      else
      end
    end
  end
end

function UMG_Pet_TeamReplace_C:UpdateExchangeBtn(state)
  if state then
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
    self.ExchangeGrey.HideAnim = true
    self.ExchangeGrey:SetShowLockIcon(false)
  end
end

function UMG_Pet_TeamReplace_C:SwitchUIByMode(mode)
  if nil == mode then
    return
  end
  if mode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    local tipStr = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character16").str
    if self.is_mirror then
      self:UpdateExchangeBtn(false)
    else
      self:UpdateExchangeBtn(true)
    end
    self.Btn_Cultivate_1:SetBtnText(tipStr)
    self.Btn_Cultivate_1:SetPath("PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/img_huanxia_png.img_huanxia_png'")
  elseif mode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
    local tipStr = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character17").str
    self:UpdateExchangeBtn(false)
    self.Btn_Cultivate_1:SetBtnText(tipStr)
    self.Btn_Cultivate_1:SetPath("PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/img_baicunpeizhi_png.img_baicunpeizhi_png'")
  end
end

function UMG_Pet_TeamReplace_C:SwitchUIByPetTabType(type)
  local randomBonusButtonVisibility = UE4.ESlateVisibility.Visible
  self.RandomBonus:SetVisibility(randomBonusButtonVisibility)
end

function UMG_Pet_TeamReplace_C:RefreshTeamData()
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  self.is_mirror = team.is_mirror
  self.isEmptyTeam = true
  if team.is_mirror then
    self.NRCText_53:SetText(string.format(LuaText.share_pet_owner_inf_2, team.mirror_friend_name))
  end
  local _, nextState = self:GetCurrAndNextState()
  local petInfoList = team and team.pet_infos or {}
  local nextSlotDic = {}
  local nextTeamPetGidList = {}
  for i = 1, #petInfoList do
    local teamPetInfoItem = petInfoList and petInfoList[i]
    local petGid = teamPetInfoItem and teamPetInfoItem.pet_gid
    if petGid then
      nextSlotDic[i] = petGid
      nextTeamPetGidList[i] = petGid
      self.isEmptyTeam = false
    end
  end
  nextState.slotDic = nextSlotDic
  nextState.teamPetGidList = nextTeamPetGidList
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:RefreshTeam()
  local state = self:GetState()
  local switcherDescribeData = state and state.switcherDescribeData
  local switcherDescribeDataType = switcherDescribeData and switcherDescribeData.type
  if switcherDescribeDataType == UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.TeamDescription then
    self.NRCSwitcher_Describe:SetActiveWidgetIndex(0)
    self.Text_1:SetText(self:GetTeamName())
  elseif switcherDescribeDataType == UMG_Pet_TeamReplace_C.SwitcherDescribeDataType.TeamErrorMessage then
    self.NRCSwitcher_Describe:SetActiveWidgetIndex(1)
  end
  local HeadShowPetList = self.HeadShowPetList or {}
end

function UMG_Pet_TeamReplace_C:GetTeamName()
  local curTeamIdx = self.curTeamIdx or 0
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[curTeamIdx + 1]
  if team.is_mirror then
    self.Btn_Cultivate_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.FriendsLineupText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.FriendsLineupText:SetText(string.format(LuaText.share_pet_owner_inf_1, team.mirror_friend_name))
    self.RenameBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Cultivate_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.FriendsLineupText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RenameBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if not team.team_name or team.team_name == "" then
    local teamNameCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name")
    return string.format(teamNameCfg.str, curTeamIdx + 1)
  else
    return team.team_name
  end
end

function UMG_Pet_TeamReplace_C:HasCommonEvolution(petGid)
  local state = self:GetState()
  local teamPetList = state and state.teamPetList or {}
  if teamPetList then
    for _, petData in pairs(teamPetList) do
      if PetUtils.IsCommonEvolution(petData.gid, petGid) then
        return true
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:IsInTeam(gid)
  local state = self:GetState()
  local inTeamGidDic = state and state.inTeamGidDic or {}
  local inTeam = inTeamGidDic and gid and inTeamGidDic[gid] or false
  return inTeam
end

function UMG_Pet_TeamReplace_C:IsCanInteractIfInWarehouse(gridType, gid)
  local state = self:GetState()
  local warehouseCanInteractPetIdMap = state and state.warehouseCanInteractPetIdMap or {}
  local isInWarehouse = gridType == UMG_Pet_TeamReplace_C.GridType.WarehouseGrid
  local isCanInteract = true
  if isInWarehouse and gid then
    isCanInteract = gid and warehouseCanInteractPetIdMap and warehouseCanInteractPetIdMap[gid] or false
  end
  return isCanInteract
end

function UMG_Pet_TeamReplace_C:RefreshWarehouse()
  self:SetPetInfoList()
end

function UMG_Pet_TeamReplace_C:SetPetInfoList()
  local currentState, nextState = self:GetCurrAndNextState()
  local inTeamGidDic = currentState and currentState.inTeamGidDic
  self.petInfoList = {}
  local petData = {}
  local state = self:GetState()
  local petTabType = state and state.petTabType
  if petTabType == PetTabType.BagPet then
    petData = _G.DataModelMgr.PlayerDataModel:GetPetData()
  elseif petTabType == PetTabType.TrialPet then
    petData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPets)
  elseif petTabType == PetTabType.RandomPet then
    local option = {
      removeSameBloodPetData = true,
      preferNonTeamPetInSameBlood = true,
      removeInTeamGid = false,
      inTeamGidDic = inTeamGidDic
    }
    petData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetRandomPets, option)
  end
  self.trialRefreshTime = nil
  if self.curTeamType and self.curTeamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4 then
    self.trialRefreshTime = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBriefRefreshTime)
  end
  local petInfoList = {}
  local EnumPetSequenceDefault = ProtoEnum.PetSequenceDefault or {}
  local petSequenceDefaultValueList = {}
  for key, j in pairs(EnumPetSequenceDefault) do
    table.insert(petSequenceDefaultValueList, j)
  end
  table.sort(petSequenceDefaultValueList)
  for i, petinfo in ipairs(petData) do
    local isFreePet = self:IsFreePet(petinfo)
    local petInfo
    if not isFreePet then
      local baseConfId = petinfo and petinfo.base_conf_id
      local petTypeInfoType = PetUtils.GetPetTypeInfoType(petinfo)
      if baseConfId then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(baseConfId)
        if petBaseConf then
          local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
          local temp = {
            level = petinfo.level,
            gid = petinfo.gid,
            petIcon = modelConf,
            pet_status_flags = petinfo.pet_status_flags or 0,
            base_conf_id = petinfo.base_conf_id,
            CanChangeTeam = petinfo.enable_change,
            CanChangeTeamSort = petinfo.enable_change and 1 or 0,
            energy = petinfo.energy,
            PetBaseInfo = petinfo,
            is_trial_pet = petinfo.is_trial_pet,
            refreshTime = self.trialRefreshTime,
            canInTeamNum = self.canInTeamNum
          }
          local basicPropertyMap = {}
          for _, j in ipairs(petSequenceDefaultValueList) do
            local PetBasicProperty
            if 1 == j then
              PetBasicProperty = petinfo.level
            elseif 2 == j then
              PetBasicProperty = petinfo.add_time
            elseif j <= 8 then
              PetBasicProperty = PetUtils.GetPetAdditionalByType(petinfo, j - 2)
            elseif 10 == j then
              PetBasicProperty = petinfo.talent_rank
            elseif 11 == j then
              if petinfo.partner_mark and petinfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
                PetBasicProperty = 100 - petinfo.partner_mark
              else
                PetBasicProperty = 0
              end
            elseif 12 == j then
              if petinfo.grow_times then
                PetBasicProperty = petinfo.grow_times
              else
                PetBasicProperty = 0
              end
            end
            if PetBasicProperty then
              basicPropertyMap[j] = PetBasicProperty
            end
          end
          local isTravel = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetPetIsTravel, petinfo.gid)
          petInfo = {
            PetData = temp,
            isHasPet = true,
            IsTravel = isTravel,
            basicPropertyMap = basicPropertyMap,
            IsFree = false,
            banFree = petBaseConf.ban_free,
            canInTeamNum = self.canInTeamNum
          }
        end
      elseif petTypeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
        local randomPetInfo = petinfo
        local temp = {
          gid = randomPetInfo.gid,
          PetBaseInfo = randomPetInfo,
          type = randomPetInfo.type
        }
        petInfo = {
          PetData = temp,
          isHasPet = true,
          IsTravel = false,
          IsFree = false,
          banFree = false,
          canInTeamNum = self.canInTeamNum
        }
      end
    end
    if petInfo then
      table.insert(petInfoList, petInfo)
    end
  end
  for i, petInfo in ipairs(petInfoList) do
    local petInfoPetData = petInfo and petInfo.PetData
    local petGid = petInfoPetData and petInfoPetData.gid
    petInfo.key = petGid
  end
  nextState.warehousePetHeadInfo = petInfoList
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:EliminateFreePet(_PetData)
  local PetData = _PetData
  local PetList = {}
  for i, PetInfo in ipairs(PetData) do
    local isExchange = PetInfo.pet_status_flags and PetInfo.pet_status_flags & ProtoEnum.PetStatusFlag.MIRACLE_CHANGING > 0
    if not isExchange then
      table.insert(PetList, PetInfo)
    end
  end
  return PetList
end

function UMG_Pet_TeamReplace_C:IsFreePet(PetInfo)
  local isExchange = PetInfo.pet_status_flags and PetInfo.pet_status_flags & ProtoEnum.PetStatusFlag.MIRACLE_CHANGING > 0
  if not isExchange then
    return false
  end
  return true
end

function UMG_Pet_TeamReplace_C:UpdatePetInfo(petHeadInfo)
  local prevState, nextState = self:GetCurrAndNextState()
  nextState.petHeadInfo = petHeadInfo
  nextState.petSortInfo = nil
  nextState.afterFilterList = nil
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:SetSortListInfo()
  local sortIndex = self.SortIndex - 1
end

function UMG_Pet_TeamReplace_C:GetPetBagSequence(sortId)
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_BAG_SEQUENCE)
  local cfgDatas = cfgTable:GetAllDatas()
  for _, val in ipairs(cfgDatas) do
    if sortId == val.sequence_default then
      return val
    end
  end
  return nil
end

function UMG_Pet_TeamReplace_C:SetSortText(sortId)
  local PetBagSequence = self:GetPetBagSequence(sortId)
  local sequence_desc = PetBagSequence and PetBagSequence.sequence_desc
  self.ComScreen:SetComboText(sequence_desc)
end

function UMG_Pet_TeamReplace_C:SortItemInfo(sortId)
  local _, nextState = self:GetCurrAndNextState()
  nextState.sortIndex = sortId
  nextState.isNeedReselectPet = true
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:SortItem(_petinfo, sortIndex)
  local sortList = self:PetListSort(true, _petinfo, sortIndex)
  local _, nextState = self:GetCurrAndNextState()
  nextState.petSortInfo = sortList
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:SetPetSortIndex(_index)
  local _, nextState = self:GetCurrAndNextState()
  nextState.sortIndex = _index
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnTypeChooseChanged(typeList)
  local _, nextState = self:GetCurrAndNextState()
  nextState.chooseTypeList = typeList
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnTypeChooseUpdated(prevTypeList, nextTypeList)
  self:FilterRefreshUI()
  local state = self:GetState()
  local curMode = state and state.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    local curSelPetData = state.curSelPetData
  else
  end
end

function UMG_Pet_TeamReplace_C:OnPetTeamListChanged(prevTeamPetList, nextTeamPetList, prevAnyTeamPetIsRandom, nextAnyTeamPetIsRandom)
  self.Text_1:SetText(self:GetTeamName())
  self:RefreshSwitcherDescribeData()
  local teamPetList = nextTeamPetList or {}
  local pureRandomPetCount = 0
  local typeRandomPetCount = 0
  for i, petData in ipairs(teamPetList) do
    local petBaseInfo = petData and petData.PetBaseInfo
    local typeInfoType = PetUtils.GetPetTypeInfoType(petBaseInfo)
    if typeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
      local typeInfo = petBaseInfo and petBaseInfo.type
      local skillDamType = typeInfo and typeInfo.param
      if 0 == skillDamType then
        pureRandomPetCount = pureRandomPetCount + 1
      else
        typeRandomPetCount = typeRandomPetCount + 1
      end
    end
  end
  local randomPetRewordConf = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetRandomPetRewordConf, pureRandomPetCount, typeRandomPetCount)
  local prevRandomPetBonusState = self.randomPetBonusState or {}
  local nextRandomPetBonusState = {}
  nextRandomPetBonusState.starCount = randomPetRewordConf and randomPetRewordConf.star or 0
  nextRandomPetBonusState.winNum = randomPetRewordConf and randomPetRewordConf.win_num or 0
  nextRandomPetBonusState.hitPetNum = randomPetRewordConf and randomPetRewordConf.hit_pet_num or 0
  self.randomPetBonusState = nextRandomPetBonusState
  if not nextAnyTeamPetIsRandom and self.RandomBonus.RedDot:IsRed() then
    self.RandomBonus.RedDot:EraseRedPoint()
  end
end

function UMG_Pet_TeamReplace_C:Reselect()
  local state = self:GetState()
  local curMode = state and state.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    local petData = self:GetPetDataByCurPetGid()
    local curSelPetData = state and state.curSelPetData
    local teamPetList = state and state.teamPetList or {}
    local _, nextState = self:GetCurrAndNextState()
    if curSelPetData then
      nextState.curSelPetData = curSelPetData
    else
      nextState.curSelPetData = petData and petData.PetBaseInfo
    end
    self:SetState(nextState)
    self:DispatchEvent(PetUIModuleEvent.PetTeamWarehouseItemLocked, petData, teamPetList)
  else
  end
end

function UMG_Pet_TeamReplace_C:OnClose(isOKClose)
  local flag = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsAnyUmgIsOpening)
  if flag then
    return
  end
  local state = self:GetState()
  local isChangeSkill = state and state.isChangeSkill or false
  if isChangeSkill then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isChangeSkill = false
    self:SetState(nextState)
    self:InitFilterAndSort()
    return
  end
  if _G.GlobalConfig.DebugOpenUI then
    self:DoClose()
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    return
  end
  if not isOKClose then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1007, " UMG_Pet_TeamReplace_C:OnClose")
  end
  self:InitFilterAndSort()
  self.teamPetList = nil
  self.data.chooseTypeList = {
    DepartmentFilter = {},
    TalentFilter = {},
    NaturePositiveEffectFilter = {},
    AttributeFilter = {}
  }
  self:HideTipsIfNeeded()
  self:OnCloseButtonClick()
end

function UMG_Pet_TeamReplace_C:HideTipsIfNeeded()
  if self.TipPanelVisible == true then
    self.TipPanelVisible = false
    self:SetTipPanelVisible(self.TipPanelVisible)
  end
end

function UMG_Pet_TeamReplace_C:OnShowTipBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1211, " UMG_Pet_TeamReplace_C:OnShowTipBtnClick")
  self.TipPanelVisible = not self.TipPanelVisible
  if self.TipPanelVisible == true then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1083, " UMG_Pet_TeamReplace_C:OnShowTipBtnClick")
  end
  self:SetTipPanelVisible(self.TipPanelVisible)
end

function UMG_Pet_TeamReplace_C:OnCultivateClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1014, "UMG_Pet_TeamReplace_C:OnCultivateClick")
  self:HideTipsIfNeeded()
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  local curSelPetGid = curSelPetData and curSelPetData.gid
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(curSelPetGid)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPanelPetData, petData, 1, false)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    Callback = self.SetPetTeamHid,
    Caller = self
  }, true)
end

function UMG_Pet_TeamReplace_C:SetPetTeamHid()
end

function UMG_Pet_TeamReplace_C:OnAnimStarted(Animation)
  if Animation == self.Recycle_In then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleInAnimPlaying = true
    self:SetState(nextState)
  elseif Animation == self.Recycle_Out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleOutAnimPlaying = true
    self:SetState(nextState)
  elseif Animation == self.Recycle_move then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleBtnHighLightInAnimPlaying = true
    self:SetState(nextState)
  elseif Animation == self.Recycle_move_out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleBtnHighLightOutAnimPlaying = true
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnAnimFinished(Animation)
  if Animation == self.Out then
    self.data:ClearPetSkillsData()
    self:DelaySeconds(0.01, function()
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamSetBtnCloseState, PetUIModuleEnum.PetTeamShowType.Normal)
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetTeamReplacePanel)
    end)
  elseif Animation == self.Recycle_In then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleInAnimPlaying = false
    self:SetState(nextState)
  elseif Animation == self.Recycle_Out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleOutAnimPlaying = false
    self:SetState(nextState)
  elseif Animation == self.Recycle_move then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleBtnHighLightInAnimPlaying = false
    self:SetState(nextState)
  elseif Animation == self.Recycle_move_out then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recycleBtnHighLightOutAnimPlaying = false
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnCloseButtonClick()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  self:PlayAnimation(self.Out)
end

function UMG_Pet_TeamReplace_C:OnExchangeBtnClick()
  local currState, nextState = self:GetCurrAndNextState()
  local curMode = currState and currState.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    local curExChangeState = currState and currState.curExChangeState
    if curExChangeState == ExChangeState.Normal then
      nextState.curExChangeState = ExChangeState.ExChanging
    else
      nextState.curExChangeState = ExChangeState.Normal
    end
  end
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:ApplyDeleteBtnClick()
  local newTeam = {}
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  if team.pet_infos == nil then
    team.pet_infos = {}
  end
  newTeam.magicID = -1
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamInfo, newTeam, self.curTeamIdx, self.module.data.OpenTeamType)
end

function UMG_Pet_TeamReplace_C:OnDeleteBtnClick()
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local teamIndex = self.curTeamIdx and self.curTeamIdx + 1
  local teams = teamInfo and teamInfo.teams
  local team = teams and teamIndex and teams[teamIndex]
  local petInfoList = team and team.pet_infos or {}
  local petInfoListCount = #petInfoList
  if petInfoListCount > 0 then
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local dialogContext = DialogContext()
    dialogContext:SetContent(LuaText.share_pet_delete_team_content):SetTitle(LuaText.share_pet_delete_team_title):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetCallbackOkOnly(self, self.ApplyDeleteBtnClick):SetToppingIconType(0)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  else
    self:ApplyDeleteBtnClick()
  end
  self:ResetDescText()
end

function UMG_Pet_TeamReplace_C:OnBanChangeButtonClick()
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  if team.is_mirror then
    NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_change_tip)
  end
end

function UMG_Pet_TeamReplace_C:OnChangeButtonClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_Pet_TeamReplace_C:OnChangeButtonClick")
  local currState, nextState = self:GetCurrAndNextState()
  local curExChangeState = currState and currState.curExChangeState
  if curExChangeState == ExChangeState.ExChanging then
    self:OnExchangeBtnClick()
  end
  currState, nextState = self:GetCurrAndNextState()
  local prevMode = currState and currState.modifyPetMode
  local nextMode = prevMode
  if prevMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    nextMode = PetUIModuleEnum.ModifyPetMode.QuickEdit
  elseif prevMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
    nextMode = PetUIModuleEnum.ModifyPetMode.SingleEdit
  end
  nextState.modifyPetMode = nextMode
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnModifyPetModeChanged(prevMode, nextMode)
  if nextMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
    self:RefreshTeamData()
    self:RefreshUI(prevMode, nextMode)
  elseif nextMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    self:SaveSkillChange()
    local state = self:GetState()
    local slotDic = state and state.slotDic or {}
    if not PetUtils.CheckPvpTeamValid(slotDic, self.curTeamType) then
      local nameLessCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_same_pet")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, nameLessCfg.str)
      return
    end
    local newTeam = {}
    for i = 1, self.canInTeamNum do
      if slotDic[i] then
        table.insert(newTeam, {
          pet_gid = slotDic[i]
        })
      end
    end
    local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
    local main_team_idx = teamInfo.main_team_idx
    local team = teamInfo.teams[self.curTeamIdx + 1]
    if team.pet_infos == nil then
      team.pet_infos = {}
    end
    if PetUtils.CheckPvpTeamIsMirror(self.curTeamIdx, self.module.data.OpenTeamType) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_owner_inf_3)
      return false
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamInfo, newTeam, self.curTeamIdx, self.module.data.OpenTeamType)
  end
  self:SwitchUIByMode(nextMode)
end

function UMG_Pet_TeamReplace_C:ChangePetTeamSuccess(retCode)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.CloseTeamReplacePanel, self.ChangePetTeamSuccess)
  if 0 == retCode then
    self:OnClose(true)
  end
end

function UMG_Pet_TeamReplace_C:GetTeamParam(PetGid)
  local teamParam = {}
  teamParam.TeamType = self.curTeamType
  teamParam.TeamIdx = self.curTeamIdx
  teamParam.PetGid = PetGid
  return teamParam
end

function UMG_Pet_TeamReplace_C:GetPvpTeamPetSkillListByPetGid(PetGid)
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  if team and team.pet_infos then
    for _, petInfo in pairs(team.pet_infos) do
      if petInfo.pet_gid == PetGid then
        if petInfo.equip_infos then
          do
            local skillList = {}
            for _, skillInfo in pairs(petInfo.equip_infos) do
              skillList[skillInfo.pos] = skillInfo.id
            end
            return skillList
          end
          break
        end
        do return nil end
        break
      end
    end
  end
  return nil
end

function UMG_Pet_TeamReplace_C:GetSkillMapByPetGid(petData)
  local PetGid = petData and petData.gid
  local PetBaseInfo = petData and petData.PetBaseInfo
  local skillList = PetBaseInfo and self:GetPetEquipSkills(PetBaseInfo) or {}
  local skillMap = {}
  if skillList then
    for index, skillInfo in pairs(skillList) do
      skillMap[skillInfo.id] = index
    end
  end
  return skillMap
end

function UMG_Pet_TeamReplace_C:OnClickSkillsChange()
  self:ResetDescText()
  self.showLockSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill)
  self:RefreshShowLockSkillBtn()
  local state = self:GetState()
  local curShowPetData = state and state.curShowPetData
  local curShowPetGid = curShowPetData and curShowPetData.gid
  if curShowPetData then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isChangeSkill = true
    self:SetState(nextState)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.PvpPetTeamUmg)
    local skillMap = self:GetSkillMapByPetGid(curShowPetData)
    local teamParam = self:GetTeamParam(curShowPetGid)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPvpSkillData, skillMap, teamParam)
    _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    local curSelPetData = state and state.curSelPetData
    local curSelPetGid = curSelPetData and curSelPetData.gid
    local posToIdDic = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, curSelPetGid, PetUIModuleEnum.PetEquipSkillType.PvpTeam)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetAssumptionEquipSkill, curSelPetGid, posToIdDic)
    if ChangePetSkillsPanel then
      self:InitFilterAndSort()
      ChangePetSkillsPanel:ShowPetSkill()
    else
      self.ChangePetSkillsPanel:LoadPanel(nil, curSelPetData)
      self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    self:ShowSkillBtnState()
  end
end

function UMG_Pet_TeamReplace_C:ShowSkillBtnState()
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  local curSelPetBloodId = curSelPetData and curSelPetData.blood_id
  if curSelPetBloodId == Enum.PetBloodType.PBT_NIGHTMARE then
    self.changeBtn5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.changeBtn5:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Pet_TeamReplace_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pet_TeamReplace_C:GetPetEquipSkills(petData)
  if not petData then
    Log.Error("UMG_Pet_TeamReplace_C:GetPetEquipSkills petData is nil")
    return {}
  end
  local petEquipSkills = self:GetPvpTeamPetSkillListByPetGid(petData.gid)
  if petEquipSkills then
    local result = {}
    for _, id in pairs(petEquipSkills) do
      table.insert(result, {id = id})
    end
    return result
  end
  petEquipSkills = self.data:GetPetSkillsData(petData.gid)
  if petEquipSkills then
    local result = {}
    for _, id in pairs(petEquipSkills) do
      table.insert(result, {id = id})
    end
    return self:EquipSkillLegalHandle(petData, result)
  end
  petEquipSkills = {}
  if petData.skill and petData.skill.skill_data then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  return petEquipSkills
end

function UMG_Pet_TeamReplace_C:EquipSkillLegalHandle(petData, equipSkill)
  local function bIsLearned(skillId)
    if petData.skill and petData.skill.skill_data then
      for i, skillData in ipairs(petData.skill.skill_data) do
        if skillData.id == skillId and skillData.is_learned then
          return true
        end
      end
    end
    return false
  end
  
  local petEquipSkills = {}
  for i, v in pairs(equipSkill) do
    if bIsLearned(v.id) then
      table.insert(petEquipSkills, {
        id = v.id
      })
    end
  end
  if #petEquipSkills < 1 and petData.skill and petData.skill.skill_data then
    for i, v in ipairs(petData.skill.skill_data) do
      if v.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
        table.insert(petEquipSkills, {
          id = v.id
        })
        break
      end
    end
  end
  return petEquipSkills
end

function UMG_Pet_TeamReplace_C:InitFeatures(skillId, lock)
  if 0 == skillId or nil == skillId then
    self.SizeBox_67:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  if skillCfg then
    if skillCfg.icon then
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SkillIcon:SetPath(NRCUtils:FormatConfIconPath(skillCfg.icon, _G.UIIconPath.SkillIconPath))
    else
      self.SkillIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SkillIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.SkillNameTxt:SetText(skillCfg.name)
    local skillDesc = skillCfg.desc
    self.NRCTextDes:SetText(skillDesc)
    self.SizeBox_67:SetVisibility(UE4.ESlateVisibility.Visible)
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.SizeBox_67:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_TeamReplace_C:ShowDescRightPanel(id)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowDescRightPanel, id)
end

function UMG_Pet_TeamReplace_C:OnDescTextClicked(descText)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Pet_TeamReplace_C:ResetDescText()
  table.clear(self.descText)
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ShutDown_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_TeamReplace_C:OnPvpPetTeamEquipPetSkills()
  local state = self:GetState()
  local isChangeSkill = state and state.isChangeSkill or false
  if isChangeSkill then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isChangeSkill = false
    self:SetState(nextState)
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.updateSelPetDataFlag = {}
  nextState.pvpPetTeamEquipPetSkillsUpdatedFlag = {}
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:RefreshAdjustPetPanel()
  local _, nextState = self:GetCurrAndNextState()
  nextState.updateSelPetDataFlag = {}
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C.ReplacePetDataPetBaseInfo(petData, nextPetBaseInfo)
  local prevPetBaseInfo = petData and petData.PetBaseInfo
  local petGid = petData and petData.gid
  if petData then
    petData.PetBaseInfo = nextPetBaseInfo
    if prevPetBaseInfo ~= nextPetBaseInfo then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CmdInvalidateBalancedPetDataForPvp, petGid)
      petData.balancedPetBaseInfo = nil
    end
  end
end

function UMG_Pet_TeamReplace_C:RefreshSkillList()
end

function UMG_Pet_TeamReplace_C:SetRightInfo(PetData, ListIndex)
  if not PetData then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_FavoriteButton_C:UpdateInfo")
  self.ListIndex = ListIndex
  self.IconList_1:ScrollToStart()
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  local curSelPetBaseConfId = curSelPetData and curSelPetData.base_conf_id
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(curSelPetBaseConfId, true)
  local commonAttrData = {}
  local commonAttrData1 = {}
  local petData = PetData and PetData.PetBaseInfo
  local balancedPetData = PetData and PetData.balancedPetBaseInfo
  if balancedPetData then
    petData = balancedPetData
  end
  if not petData then
    return
  end
  local petGid = petData and petData.gid
  local petBaseConfId = petData and petData.base_conf_id
  local PetAttrBalanceTipsVisibility = UE4.ESlateVisibility.Collapsed
  local isRandomPet, _ = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petData.gid)
  local isPvpBalance = nil ~= balancedPetData
  if isPvpBalance then
    PetAttrBalanceTipsVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  self.PetAttrBalanceTips:SetVisibility(PetAttrBalanceTipsVisibility)
  self.textPetName:SetText(petData.name)
  self:updatePetGender(petData.gender)
  self.UMG_PetRate:SetText(petData)
  self.textPetLv:SetText(petData.level)
  local PetLevel = PetUtils.GetBreakThroughStarsList(petData)
  self.CatchHardLv:InitGridView(PetLevel)
  local petType = petBaseConf and petBaseConf.unit_type or {}
  for i = 1, 2 do
    if i <= #petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType[i])
      if typeDic then
        table.insert(commonAttrData1, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  if self.Attr1 then
    self.Attr1:InitGridView(commonAttrData1)
  end
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petData.blood_id)
  if PetBloodConf then
    if not petData or petData.is_trial_pet then
      self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_CollectBtn:UpdateInfo(petData.partner_mark, true)
    end
    table.insert(commonAttrData, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
    if self.Attr then
      self.Attr:InitGridView(commonAttrData)
    end
  end
  local isTrialPet, _ = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, PetData.gid)
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  local MirrorPetData = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetMirrorPetDataByGid, petGid)
  if MirrorPetData then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  end
  if isTrialPet or MirrorPetData then
    self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  local attrList = {}
  local attrInfo = petData.attribute_info
  local positive_effect, negative_effect
  local natureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
  if 0 ~= petData.changed_nature_pos_attr_type then
    positive_effect = self:GetChangeAttrReqEnum(petData.changed_nature_pos_attr_type)
  else
    positive_effect = natureConf and natureConf.positive_effect
  end
  if 0 ~= petData.changed_nature_neg_attr_type then
    negative_effect = self:GetChangeAttrReqEnum(petData.changed_nature_neg_attr_type)
  else
    negative_effect = natureConf and natureConf.negative_effect
  end
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_HPMAX,
    arrowType = _G.Enum.AttributeType.AT_HPMAX_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_HPMAX),
    attrInfo = attrInfo.hp,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseConfId,
    name = LuaText.umg_battle_changepetconfirm_1
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYDEF,
    arrowType = _G.Enum.AttributeType.AT_PHYDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_PHYDEF),
    attrInfo = attrInfo.defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseConfId,
    name = LuaText.umg_battle_changepetconfirm_5
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_PHYATK,
    arrowType = _G.Enum.AttributeType.AT_PHYATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_PHYATK),
    attrInfo = attrInfo.attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseConfId,
    name = LuaText.umg_battle_changepetconfirm_3
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEDEF,
    arrowType = _G.Enum.AttributeType.AT_SPEDEF_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_SPEDEF),
    attrInfo = attrInfo.special_defense,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseConfId,
    name = LuaText.umg_battle_changepetconfirm_6
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEATK,
    arrowType = _G.Enum.AttributeType.AT_SPEATK_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_SPEATK),
    attrInfo = attrInfo.special_attack,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseConfId,
    name = LuaText.umg_battle_changepetconfirm_4
  })
  table.insert(attrList, {
    attrType = _G.Enum.AttributeType.AT_SPEED,
    arrowType = _G.Enum.AttributeType.AT_SPEED_PERCENT,
    addiAttrInfo = PetUtils.GetPetAdditionalByType(petData, Enum.AttributeType.AT_SPEED),
    attrInfo = attrInfo.speed,
    positive_effect = positive_effect,
    negative_effect = negative_effect,
    petConfId = petBaseConfId,
    name = LuaText.umg_battle_changepetconfirm_2,
    NoShowline = true
  })
  local petEquipSkillList = self:GetPetEquipSkills(petData)
  self.BtnHandlerList = {}
  self.BtnHandlerList.Call = self
  self.BtnHandlerList.OnTextClickedHandler = self.OnDescTextClicked
  self.BtnHandlerList.OnRestTextHandler = self.ResetDescText
  self.CommonPetDetails:InitPetBaseInfo(petData, petBaseConf, attrList, petEquipSkillList, PetUIModuleEnum.CommonPetDetailsShowType.PvpRank, self.BtnHandlerList)
  self:UpdateChangePetSkills()
end

function UMG_Pet_TeamReplace_C:InitFilterAndSort()
  self.sortRuleId = 1
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:InitFilterAndSort()
  end
  local path2 = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  self.ViewPet:SetPath(path2, path2, path2)
  self:RefreshShowLockSkillBtn()
end

function UMG_Pet_TeamReplace_C:SetPetData(PetData)
  if PetData then
    local nextPetDataBaseConfId = PetData and PetData.base_conf_id
    local state = self:GetState()
    local curSelPetData = state and state.curSelPetData
    local curSelPetBaseConfId = curSelPetData and curSelPetData.base_conf_id
    if curSelPetBaseConfId ~= nextPetDataBaseConfId then
      self:InitFilterAndSort()
    end
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.curSelPetData = PetData
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnPlayerDataUpdate()
  local _, nextState = self:GetCurrAndNextState()
  nextState.updateSelPetDataFlag = {}
  self:SetState(nextState)
  local state = self:GetState()
  local curSelPetData = state and state.curSelPetData
  if curSelPetData then
    local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
    if ChangePetSkillsPanel then
      ChangePetSkillsPanel:RefreshUI(curSelPetData)
    end
  end
  self:UpdatePvpSkillData()
  self:RefreshWarehouse()
end

function UMG_Pet_TeamReplace_C:UpdateChangePetSkills()
  local state = self:GetState()
  local curShowPetData = state and state.curShowPetData
  local curShowPetGid = curShowPetData and curShowPetData.gid
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    local skillMap = self:GetSkillMapByPetGid(curShowPetData)
    local teamParam = self:GetTeamParam(curShowPetGid)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPvpSkillData, skillMap, teamParam)
    local curSelPetData = state and state.curSelPetData
    if curSelPetData then
      ChangePetSkillsPanel:RefreshUI(curSelPetData)
    end
  end
end

function UMG_Pet_TeamReplace_C:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX then
    return Enum.AttributeType.AT_HPMAX_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYATK then
    return Enum.AttributeType.AT_PHYATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEATK then
    return Enum.AttributeType.AT_SPEATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYDEF then
    return Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEDEF then
    return Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEED then
    return Enum.AttributeType.AT_SPEED_PERCENT
  end
end

function UMG_Pet_TeamReplace_C:OnReversedSort()
  self.IsReversedSort = not self.IsReversedSort
  local state = self:GetState()
  local petTabType = state and state.petTabType
  if petTabType == PetTabType.RandomPet then
    return
  end
  local PetReversedSort = state and state.petSortInfo
  local temporaryList = {}
  if PetReversedSort then
    for i = #PetReversedSort, 1, -1 do
      if PetReversedSort[i].isHasPet == true then
        table.insert(temporaryList, PetReversedSort[i])
      end
    end
    local _, nextState = self:GetCurrAndNextState()
    nextState.petSortInfo = temporaryList
    nextState.isNeedReselectPet = true
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:TryExChangePet(PetData, targetPetData)
  local curSelPetGid = targetPetData and targetPetData.gid
  if not targetPetData then
    return
  end
  local isInTeam = self:IsInTeam(curSelPetGid)
  local tempPetInfos = self:GetCurTempPetInfo()
  if isInTeam then
    if not PetData or PetData.gid == curSelPetGid then
      return
    end
    local id1, id2
    for index, value in ipairs(tempPetInfos) do
      if value.pet_gid == curSelPetGid then
        id1 = index
      end
      if value.pet_gid == PetData.gid then
        id2 = index
      end
    end
    if id1 and id2 then
      tempPetInfos[id1], tempPetInfos[id2] = tempPetInfos[id2], tempPetInfos[id1]
    end
  elseif PetData then
    local hasSelectPet = false
    for index, value in ipairs(tempPetInfos) do
      if value.pet_gid == PetData.gid then
        tempPetInfos[index].pet_gid = curSelPetGid
        tempPetInfos[index].equip_infos = self.data:GetPetEquipInfos(curSelPetGid)
        hasSelectPet = true
        break
      end
    end
    if not hasSelectPet then
      return true
    end
  else
    table.insert(tempPetInfos, {
      pet_gid = curSelPetGid,
      equip_infos = self.data:GetPetEquipInfos(curSelPetGid)
    })
  end
  if PetUtils.CheckPvpTeamIsMirror(self.curTeamIdx, self.module.data.OpenTeamType) then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_owner_inf_3)
    return false
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetTeamInfo, tempPetInfos, self.curTeamIdx, self.module.data.OpenTeamType)
end

function UMG_Pet_TeamReplace_C.GetPetDataByGridTypeAndIndexFromProxy(state, gridType, index)
  index = index and index + 1
  local targetPetData, itemKey
  if gridType == UMG_Pet_TeamReplace_C.GridType.TeamGrid then
    index = index or -1
    local teamPetList = state and state.teamPetList or {}
    local teamPetData = teamPetList[index]
    targetPetData = teamPetData and teamPetData.PetBaseInfo
    local petListItemDataList = state and state.petListItemDataList or {}
    local petListItemData = petListItemDataList[index]
    local baseInfo = petListItemData and petListItemData.baseInfo
    itemKey = baseInfo and baseInfo.key
  else
    local rowCount = state and state.warehouseRowCount or 1
    local colCount = state and state.warehouseColCount or 1
    local pageSize = rowCount * colCount
    local currPageIndex = state and state.warehouseCurrPageIndex or 1
    local pageItemOffset = (currPageIndex - 1) * pageSize
    local finalIndex = -1
    if index and index > 0 then
      finalIndex = pageItemOffset + index
    end
    local afterFilterList = state and state.afterFilterList or {}
    local filterPetData = afterFilterList[finalIndex]
    local petData = filterPetData and filterPetData.PetData
    local indexTransform = -1
    if index and index > 0 then
      local rowIndex = math.floor((index - 1) / colCount)
      local colIndex = (index - 1) % colCount
      indexTransform = colIndex * rowCount + rowIndex + 1
    end
    local finalIndexTransform = -1
    if indexTransform and indexTransform > 0 then
      finalIndexTransform = pageItemOffset + indexTransform
    end
    local warehouseListItemDataList = state and state.warehouseListItemDataList or {}
    local warehouseListItemData = warehouseListItemDataList[finalIndexTransform]
    local isInTeam = warehouseListItemData and warehouseListItemData.isInTeam or false
    local canInteract = true
    if canInteract then
      local baseInfo = warehouseListItemData and warehouseListItemData.baseInfo
      targetPetData = petData and petData.PetBaseInfo
      itemKey = baseInfo and baseInfo.key
    end
  end
  return targetPetData, itemKey
end

function UMG_Pet_TeamReplace_C:OnItemSelectFromTeamGridTouchProxy(gridType, index)
  local state = self:GetState()
  local selectPetData = UMG_Pet_TeamReplace_C.GetPetDataByGridTypeAndIndexFromProxy(state, gridType, index)
  local petGid = selectPetData and selectPetData.gid
  local isCanInteract = self:IsCanInteractIfInWarehouse(gridType, petGid)
  if not isCanInteract then
    local pvp_rank_character29_config = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character29")
    local pvp_rank_character29_config_str = pvp_rank_character29_config and pvp_rank_character29_config.str or ""
    if not string.IsNilOrEmpty(pvp_rank_character29_config_str) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, pvp_rank_character29_config_str)
    end
    return
  end
  self:OnPetTeamItemSelected(selectPetData)
end

function UMG_Pet_TeamReplace_C:OnDragItemUpdateFromGridTouchProxy(gridType, index)
  local state = self:GetState()
  local petData = UMG_Pet_TeamReplace_C.GetPetDataByGridTypeAndIndexFromProxy(state, gridType, index)
  local petGid = petData and petData.gid
  local isCanInteract = self:IsCanInteractIfInWarehouse(gridType, petGid)
  if not isCanInteract then
    return
  end
  if gridType == UMG_Pet_TeamReplace_C.GridType.TeamGrid then
    local _, nextState = self:GetCurrAndNextState()
    nextState.teamDragPetData = petData
    self:SetState(nextState)
  elseif gridType == UMG_Pet_TeamReplace_C.GridType.WarehouseGrid then
    local _, nextState = self:GetCurrAndNextState()
    nextState.warehouseDragPetData = petData
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnDragHoveringItemUpdateFromGridTouchProxy(gridType, index)
  local state = self:GetState()
  local petData, itemKey
  petData, itemKey = UMG_Pet_TeamReplace_C.GetPetDataByGridTypeAndIndexFromProxy(state, gridType, index)
  local petGid = petData and petData.gid
  local isCanInteract = self:IsCanInteractIfInWarehouse(gridType, petGid)
  if not isCanInteract then
    return
  end
  if gridType == UMG_Pet_TeamReplace_C.GridType.TeamGrid then
    local _, nextState = self:GetCurrAndNextState()
    nextState.teamDragHoveringPetData = petData
    nextState.teamDragHoveringUiDataKey = itemKey
    self:SetState(nextState)
  elseif gridType == UMG_Pet_TeamReplace_C.GridType.WarehouseGrid then
    local _, nextState = self:GetCurrAndNextState()
    nextState.warehouseDragHoveringPetData = petData
    nextState.warehouseDragHoveringUiDataKey = itemKey
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnDragHoveringStateUpdateFromGridTouchProxy(gridType, isStartHovering, isHovering)
  if gridType == UMG_Pet_TeamReplace_C.GridType.TeamGrid then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isDragStartHoveringTeamListArea = isStartHovering
    nextState.isDragHoveringTeamListArea = isHovering
    self:SetState(nextState)
  elseif gridType == UMG_Pet_TeamReplace_C.GridType.WarehouseGrid then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isDragStartHoveringWarehouseListArea = isStartHovering
    nextState.isDragHoveringWarehouseListArea = isHovering
    self:SetState(nextState)
  elseif gridType == UMG_Pet_TeamReplace_C.GridType.RecycleBlock then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isDragStartHoveringRecycleArea = isStartHovering
    nextState.isDragHoveringRecycleArea = isHovering
    self:SetState(nextState)
  end
end

function UMG_Pet_TeamReplace_C:OnTouchStartFromGridProxy(touchContext)
  local _, nextState = self:GetCurrAndNextState()
  nextState.touchContextFromTouchProxy = touchContext
  self:GetState(nextState)
  local state = self:GetState()
  local dragContextFromMoveStart = state and state.dragContextFromMoveStart
  if dragContextFromMoveStart and touchContext then
    self:InitDragContext(dragContextFromMoveStart, touchContext)
  end
end

function UMG_Pet_TeamReplace_C:OnWarehouseMouseWheelDataUpdate(wheelData)
  wheelData = wheelData or 0
  if 0 == wheelData then
    return
  end
  local state = self:GetState()
  local currContext = state and state.warehouseScrollToPageContext
  if currContext then
    return
  end
  if wheelData < 0 then
    self:WarehouseGoToNextPage()
  elseif wheelData > 0 then
    self:WarehouseGoToPrevPage()
  end
end

function UMG_Pet_TeamReplace_C:OnPetTeamItemSelected(PetData)
  local state = self:GetState()
  local curMode = state and state.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
    self:OnPetTeamFastFormationSelected(PetData)
  elseif curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
    self:OnPetTeamWarehouseItemSelected(PetData)
  end
end

function UMG_Pet_TeamReplace_C:OnPetTeamWarehouseItemSelected(PetData)
  local currState, nextState = self:GetCurrAndNextState()
  local curSelPetData = currState and currState.curSelPetData
  local curSelPetBaseConfId = curSelPetData and curSelPetData.base_conf_id
  local petDataPetBaseConfId = PetData and PetData.base_conf_id
  local curMode = currState and currState.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit or PetData and PetData == curSelPetData then
    currState, nextState = self:GetCurrAndNextState()
    nextState.updateSelPetDataFlag = {}
    self:SetState(nextState)
    return
  end
  currState, nextState = self:GetCurrAndNextState()
  local curExChangeState = currState and currState.curExChangeState
  if curExChangeState == ExChangeState.ExChanging then
    local state = self:TryExChangePet(PetData, curSelPetData)
    if not state then
      return
    else
      self:OnExchangeBtnClick()
    end
  end
  if curSelPetBaseConfId ~= petDataPetBaseConfId then
    self:InitFilterAndSort()
  end
  currState, nextState = self:GetCurrAndNextState()
  nextState.curSelPetData = PetData
  self:SetState(nextState)
  if PetData then
    self:ResetDescText()
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_Pet_TeamReplace_C:OnPetTeamWarehouseItemSelected")
  else
    self:HideTipsIfNeeded()
  end
end

function UMG_Pet_TeamReplace_C:GetCurTempPetInfo()
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local team = teamInfo.teams[self.curTeamIdx + 1]
  local tempPetInfos = {}
  if team.pet_infos then
    for _, value in pairs(team.pet_infos) do
      local tmp = {
        pet_gid = value.pet_gid
      }
      table.insert(tempPetInfos, tmp)
    end
  end
  return tempPetInfos
end

function UMG_Pet_TeamReplace_C:CheckCurSelectValid(PetData)
  local checkTable = {}
  local state = self:GetState()
  local slotDic = state and state.slotDic or {}
  for i = 1, self.canInTeamNum do
    if slotDic[i] then
      table.insert(checkTable, slotDic[i])
    end
  end
  table.insert(checkTable, PetData.gid)
  if not PetUtils.CheckPvpTeamValid(checkTable, self.curTeamType) then
    local nameLessCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_same_pet")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, nameLessCfg.str)
    return false
  end
  return true
end

function UMG_Pet_TeamReplace_C:CheckCurrentTeamFantasticSkillValid()
  if not BattleUtils.IsBanFantasticSkillInRankPvp(self.curTeamType) then
    return true
  end
  local state = self:GetState()
  local teamPetList = state and state.teamPetList or {}
  local anySkillIsFantastic = false
  for i, petData in ipairs(teamPetList) do
    local petSkillDataList = self:GetPetEquipSkills(petData)
    local equippedFantasticId = -1
    local skillData = petData and petData.skill and petData.skill.skill_data or {}
    local fantasticId = -1
    if petData.blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or petData.blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      fantasticId = PetUtils.GetFantasticSkillInPetSkillDataList(skillData)
    end
    for _, v in ipairs(petSkillDataList) do
      if fantasticId == v.id then
        equippedFantasticId = fantasticId
        break
      end
    end
    if -1 ~= equippedFantasticId then
      anySkillIsFantastic = true
      break
    end
  end
  if anySkillIsFantastic then
    return false
  end
  return true
end

function UMG_Pet_TeamReplace_C:OnPetTeamFastFormationSelected(PetData)
  if nil == PetData then
    return
  end
  local prevState, nextState = self:GetCurrAndNextState()
  local prevSlotDic = prevState and prevState.slotDic or {}
  local nextSlotDic = {}
  table.copy(prevSlotDic, nextSlotDic)
  local teamInfoDic = prevState and prevState.teamInfoDic or {}
  if nil == teamInfoDic[PetData.gid] then
    if not self:CheckCurSelectValid(PetData) then
      return
    end
    local isFull = true
    for i = 1, self.canInTeamNum do
      if nil == nextSlotDic[i] then
        nextSlotDic[i] = PetData.gid
        isFull = false
        break
      end
    end
    if isFull then
      local strTips = string.format(LuaText.umg_pet_teamreplace_7, self.canInTeamNum)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, strTips)
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1009, "UMG_Pet_TeamReplace_C:OnPetTeamFastFormationSelected isFull")
    else
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1225, "UMG_Pet_TeamReplace_C:OnPetTeamFastFormationSelected")
    end
  else
    local index = teamInfoDic[PetData.gid]
    nextSlotDic[index] = nil
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1006, "UMG_Pet_TeamReplace_C:OnPetTeamFastFormationSelected")
  end
  nextState.slotDic = nextSlotDic
  local nextSelPetData = PetData
  local PetDataBaseInfo = PetData and PetData.PetBaseInfo
  if PetDataBaseInfo then
    nextSelPetData = PetDataBaseInfo
  end
  nextState.curSelPetData = nextSelPetData
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:HasGid(gid, table)
  if not table then
    return false
  end
  local num = #table
  for i = 1, num do
    if table[i].PetData.gid == gid then
      return true
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:CheckDepartmentFilter(DepartmentFilter, petInfo)
  if DepartmentFilter and #DepartmentFilter > 0 then
    local PetData = petInfo and petInfo.PetData
    local petBaseConfId = PetData and PetData.base_conf_id
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId, true)
    local unitTypeList = petBaseConf and petBaseConf.unit_type or {}
    for k = 1, #unitTypeList do
      for j = 1, #DepartmentFilter do
        if unitTypeList[k] == DepartmentFilter[j] then
          return true
        end
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:CheckTalentFilter(TalentFilter, petInfo)
  local PetData = petInfo and petInfo.PetData
  local PetBaseInfo = PetData and PetData.PetBaseInfo
  local talent_rank = PetBaseInfo and PetBaseInfo.talent_rank
  if TalentFilter and #TalentFilter > 0 then
    for i = 1, #TalentFilter do
      if talent_rank == TalentFilter[i] then
        return true
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:CheckNaturePositiveEffectFilter(NaturePositiveEffectFilter, petInfo)
  if NaturePositiveEffectFilter and #NaturePositiveEffectFilter > 0 then
    local PetData = petInfo and petInfo.PetData
    local PetBaseInfo = PetData and PetData.PetBaseInfo
    local changed_nature_pos_attr_type = PetBaseInfo and PetBaseInfo.changed_nature_pos_attr_type
    local nature = PetBaseInfo and PetBaseInfo.nature
    local NaturePositive = changed_nature_pos_attr_type
    if not NaturePositive or 0 == NaturePositive then
      local natureConf = _G.DataConfigManager:GetNatureConf(nature)
      NaturePositive = natureConf and natureConf.positive_effect
    else
      NaturePositive = self:GetChangeAttrReqEnum(NaturePositive)
    end
    for j = 1, #NaturePositiveEffectFilter do
      if NaturePositive == NaturePositiveEffectFilter[j] then
        return true
      end
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:CheckAttributeFilter(AttributeFilter, petInfo)
  local PetData = petInfo and petInfo.PetData
  local PetBaseInfo = PetData and PetData.PetBaseInfo
  local attributeInfo = PetBaseInfo and PetBaseInfo.attribute_info
  local hp = attributeInfo and attributeInfo.hp
  local hpTalent = hp and hp.talent
  local attack = attributeInfo and attributeInfo.attack
  local attackTalent = attack and attack.talent
  local specialAttack = attributeInfo and attributeInfo.special_attack
  local specialAttackTalent = specialAttack and specialAttack.talent
  local defense = attributeInfo and attributeInfo.defense
  local defenseTalent = defense and defense.talent
  local specialDefense = attributeInfo and attributeInfo.special_defense
  local specialDefenseTalent = specialDefense and specialDefense.talent
  local speed = attributeInfo and attributeInfo.speed
  local speedTalent = speed and speed.talent
  for j = 1, #AttributeFilter do
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_HPMAX and hpTalent and hpTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_PHYATK and attackTalent and attackTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_SPEATK and specialAttackTalent and specialAttackTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_PHYDEF and defenseTalent and defenseTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_SPEDEF and specialDefenseTalent and specialDefenseTalent > 0 then
      return true
    end
    if AttributeFilter[j] == _G.Enum.AttributeType.AT_SPEED and speedTalent and speedTalent > 0 then
      return true
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:CheckPartnerMarkerFilter(PartnerMarkerFilter, petInfo)
  local PetData = petInfo and petInfo.PetData
  local PetBaseInfo = PetData and PetData.PetBaseInfo
  local partner_mark = PetBaseInfo and PetBaseInfo.partner_mark
  for j = 1, #PartnerMarkerFilter do
    if partner_mark == PartnerMarkerFilter[j] then
      return true
    end
  end
  return false
end

function UMG_Pet_TeamReplace_C:RefreshPetListByChooseType(TypeChooseList, petSortInfo)
  self:ResetDescText()
  local state = self:GetState()
  local petTabType = state and state.petTabType
  if petTabType == PetTabType.RandomPet then
    TypeChooseList = {
      DepartmentFilter = {},
      TalentFilter = {},
      NaturePositiveEffectFilter = {},
      AttributeFilter = {},
      PartnerMarkerFilter = {},
      SpecialityFilter = {},
      GetTimeFilter = {}
    }
  end
  local DepartmentFilter = {}
  if self.PvpDepartmentFilter then
    table.insert(DepartmentFilter, self.PvpDepartmentFilter)
  end
  if TypeChooseList.DepartmentFilter then
    for i, v in pairs(TypeChooseList.DepartmentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(DepartmentFilter, enum)
      end
    end
  end
  local TalentFilter = {}
  if TypeChooseList.TalentFilter then
    for i, v in pairs(TypeChooseList.TalentFilter) do
      local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
      table.insert(TalentFilter, enum)
    end
  end
  local NaturePositiveEffectFilter = {}
  if TypeChooseList.NaturePositiveEffectFilter then
    for i, v in pairs(TypeChooseList.NaturePositiveEffectFilter) do
      local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
      table.insert(NaturePositiveEffectFilter, enum)
    end
  end
  local AttributeFilter = {}
  if TypeChooseList.AttributeFilter then
    for i, v in pairs(TypeChooseList.AttributeFilter) do
      local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
      table.insert(AttributeFilter, enum)
    end
  end
  local PartnerMarkerFilter = {}
  if TypeChooseList.PartnerMarkerFilter then
    for i, v in pairs(TypeChooseList.PartnerMarkerFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(PartnerMarkerFilter, enum)
      end
    end
  end
  local _, nextState = self:GetCurrAndNextState()
  local resultList = {}
  local InitState = true
  if #DepartmentFilter > 0 or #TalentFilter > 0 or #NaturePositiveEffectFilter > 0 or #AttributeFilter > 0 or #PartnerMarkerFilter > 0 then
    InitState = false
    self.ComScreen.ScreeningBtn:ChangeIconSelectState(2)
  else
    self.ComScreen.ScreeningBtn:ChangeIconSelectState(1)
  end
  for _, petInfo in pairs(petSortInfo) do
    if petInfo.PetData then
      local CanInsert = InitState
      if self:CheckDepartmentFilter(DepartmentFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckTalentFilter(TalentFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckNaturePositiveEffectFilter(NaturePositiveEffectFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckAttributeFilter(AttributeFilter, petInfo) then
        CanInsert = true
      end
      if not CanInsert and self:CheckPartnerMarkerFilter(PartnerMarkerFilter, petInfo) then
        CanInsert = true
      end
      if CanInsert then
        table.insert(resultList, petInfo)
      end
    end
  end
  for i, petInfo in ipairs(resultList) do
    petInfo.CallbackOwner = self
    petInfo.OnSpawnCallback = self.OnWarehouseItemSpawn
    petInfo.OnSelectCallback = self.OnPetTeamItemSelected
  end
  return resultList
end

function UMG_Pet_TeamReplace_C:PetListSort(_IsAscendingOrder, _PetList, sortIndex)
  sortIndex = sortIndex or DefaultSortIndexValue
  local newPetList = {}
  local travelPetList = {}
  for i = 1, #_PetList do
    local petInfo = _PetList[i]
    if petInfo.IsTravel then
      table.insert(travelPetList, petInfo)
    else
      table.insert(newPetList, petInfo)
    end
  end
  local petBaseConfIdToHandBookIdMap = {}
  for i, petInfo in ipairs(newPetList) do
    local petData = petInfo and petInfo.PetData
    local petBaseConfId = petData and petData.base_conf_id
    local handleBookId = PetUtils.GetHandBookIdByPetBaseConfId(petBaseConfId)
    if petBaseConfId and handleBookId then
      petBaseConfIdToHandBookIdMap[petBaseConfId] = handleBookId
    end
  end
  
  local function cmpFunction(a, b)
    return true
  end
  
  if _IsAscendingOrder then
    function cmpFunction(a, b)
      if self.RecyclingCountMap[a.PetData.gid] and self.RecyclingCountMap[b.PetData.gid] then
        return self.RecyclingCountMap[a.PetData.gid] > self.RecyclingCountMap[b.PetData.gid]
      elseif self.RecyclingCountMap[a.PetData.gid] then
        return true
      elseif self.RecyclingCountMap[b.PetData.gid] then
        return false
      elseif sortIndex == DefaultSortIndexValue then
        local petDataA = a and a.PetData
        local petDataB = b and b.PetData
        local petDataBaseInfoA = petDataA and petDataA.PetBaseInfo
        local petDataBaseInfoB = petDataB and petDataB.PetBaseInfo
        local petBaseConfIdA = petDataBaseInfoA and petDataBaseInfoA.base_conf_id
        local petBaseConfIdB = petDataBaseInfoB and petDataBaseInfoB.base_conf_id
        local handleBookIdA = petBaseConfIdA and petBaseConfIdToHandBookIdMap and petBaseConfIdToHandBookIdMap[petBaseConfIdA]
        local handleBookIdB = petBaseConfIdB and petBaseConfIdToHandBookIdMap and petBaseConfIdToHandBookIdMap[petBaseConfIdB]
        local SEQUENCE_TALENT_DOWN = ProtoEnum.PetSequenceDefault.SEQUENCE_TALENT_DOWN
        local basicPropertyMapA = a and a.basicPropertyMap
        local basicPropertyMapB = b and b.basicPropertyMap
        local aIconListSortInfo = basicPropertyMapA and basicPropertyMapA[SEQUENCE_TALENT_DOWN]
        local bIconListSortInfo = basicPropertyMapB and basicPropertyMapB[SEQUENCE_TALENT_DOWN]
        local petIdA = petDataBaseInfoA and petDataBaseInfoA.gid
        local petIdB = petDataBaseInfoB and petDataBaseInfoB.gid
        if handleBookIdA and handleBookIdB then
          return handleBookIdA < handleBookIdB
        elseif aIconListSortInfo and bIconListSortInfo then
          return aIconListSortInfo > bIconListSortInfo
        elseif petIdA and petIdB then
          return petIdA < petIdB
        end
        return false
      else
        local basicPropertyMapA = a and a.basicPropertyMap
        local basicPropertyMapB = b and b.basicPropertyMap
        local aIconListSortInfo = basicPropertyMapA and basicPropertyMapA[sortIndex]
        local bIconListSortInfo = basicPropertyMapB and basicPropertyMapB[sortIndex]
        if aIconListSortInfo and bIconListSortInfo then
          if aIconListSortInfo == bIconListSortInfo then
            return aIconListSortInfo > bIconListSortInfo
          else
            return aIconListSortInfo > bIconListSortInfo
          end
        elseif aIconListSortInfo then
          return true
        elseif bIconListSortInfo then
          return false
        else
          return false
        end
      end
    end
  else
    function cmpFunction(a, b)
      if self.RecyclingCountMap[a.PetData.gid] and self.RecyclingCountMap[b.PetData.gid] then
        return self.RecyclingCountMap[a.PetData.gid] > self.RecyclingCountMap[b.PetData.gid]
      elseif self.RecyclingCountMap[a.PetData.gid] then
        return true
      elseif self.RecyclingCountMap[b.PetData.gid] then
        return false
      elseif sortIndex == DefaultSortIndexValue then
        local petDataA = a and a.PetData
        local petDataB = b and b.PetData
        local petDataBaseInfoA = petDataA and petDataA.PetBaseInfo
        local petDataBaseInfoB = petDataB and petDataB.PetBaseInfo
        local petBaseConfIdA = petDataBaseInfoA and petDataBaseInfoA.base_conf_id
        local petBaseConfIdB = petDataBaseInfoB and petDataBaseInfoB.base_conf_id
        local handleBookIdA = petBaseConfIdA and petBaseConfIdToHandBookIdMap and petBaseConfIdToHandBookIdMap[petBaseConfIdA]
        local handleBookIdB = petBaseConfIdB and petBaseConfIdToHandBookIdMap and petBaseConfIdToHandBookIdMap[petBaseConfIdB]
        local SEQUENCE_TALENT_DOWN = ProtoEnum.PetSequenceDefault.SEQUENCE_TALENT_DOWN
        local basicPropertyMapA = a and a.basicPropertyMap
        local basicPropertyMapB = b and b.basicPropertyMap
        local aIconListSortInfo = basicPropertyMapA and basicPropertyMapA[SEQUENCE_TALENT_DOWN]
        local bIconListSortInfo = basicPropertyMapB and basicPropertyMapB[SEQUENCE_TALENT_DOWN]
        local petIdA = petDataBaseInfoA and petDataBaseInfoA.gid
        local petIdB = petDataBaseInfoB and petDataBaseInfoB.gid
        if handleBookIdA and handleBookIdB then
          return handleBookIdA > handleBookIdB
        elseif aIconListSortInfo and bIconListSortInfo then
          return aIconListSortInfo < bIconListSortInfo
        elseif petIdA and petIdB then
          return petIdA > petIdB
        end
        return false
      else
        local aIconListSortInfo = a.PetData[sortIndex]
        local bIconListSortInfo = b.PetData[sortIndex]
        if aIconListSortInfo and bIconListSortInfo then
          if aIconListSortInfo == bIconListSortInfo then
            return aIconListSortInfo < bIconListSortInfo
          else
            return aIconListSortInfo < bIconListSortInfo
          end
        elseif aIconListSortInfo then
          return false
        elseif bIconListSortInfo then
          return true
        else
          return false
        end
      end
    end
  end
  local state = self:GetState()
  local petTabType = state and state.petTabType
  if petTabType == PetTabType.RandomPet then
    function cmpFunction(a, b)
      local petDataA = a and a.PetData
      
      local petDataB = b and b.PetData
      local typeInfoA = petDataA and petDataA.type
      local typeInfoB = petDataB and petDataB.type
      local skillDamTypeA = typeInfoA and typeInfoA.param or 0
      local skillDamTypeB = typeInfoB and typeInfoB.param or 0
      return skillDamTypeA < skillDamTypeB
    end
  end
  table.sort(newPetList, cmpFunction)
  for i = 1, #travelPetList do
    table.insert(newPetList, travelPetList[i])
  end
  return newPetList
end

function UMG_Pet_TeamReplace_C:SetNameInfo(petData)
  local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petData.gid, self.is_mirror)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local petLv = PetUtils.GetCatchHardInfo(petDataInfo)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petDataInfo.blood_id)
  self.CatchHardLv:InitGridView(petLv)
  local commonAttrData1 = {}
  local petType = petBaseConf.unit_type
  for i = 1, 2 do
    if i <= #petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType[i])
      if typeDic then
        table.insert(commonAttrData1, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  if self.Attr1 then
    self.Attr1:InitGridView(commonAttrData1)
  end
end

function UMG_Pet_TeamReplace_C:SetPetNum(_petInfo)
  local petInfo = _petInfo
  local length = #petInfo
  if length < 100 then
    for i = length + 1, 100 do
      table.insert(petInfo, {isHasPet = false})
    end
  else
    local remainder = length % 6
    if remainder > 0 then
      for i = remainder + 1, 6 do
        table.insert(petInfo, {isHasPet = false})
      end
    end
  end
  return petInfo
end

function UMG_Pet_TeamReplace_C:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:ClearSkillListSelection()
  end
end

function UMG_Pet_TeamReplace_C:OnSelectSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OpenSkillFilteringPanelByCurShowSkillList()
  end
end

function UMG_Pet_TeamReplace_C:OnSortSkillClick()
  self:CloseTipsAndClearSkillListSelection()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdOpenPetSortPanel, self.sortRuleId, self.skillSortReverse)
end

function UMG_Pet_TeamReplace_C:OnPetSkillFilterRuleChange(filterRule)
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    local path
    if filterRule then
      path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen3_png.img_Screen3_png'"
    else
      path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
    end
    self.ViewPet:SetPath(path, path, path)
    ChangePetSkillsPanel:OnPetSkillFilterRuleChange(filterRule)
  end
end

function UMG_Pet_TeamReplace_C:OnPetSkillSortRuleChange(id, skillSortReverse)
  self.sortRuleId = id
  self.skillSortReverse = skillSortReverse
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    ChangePetSkillsPanel:OnPetSkillSortRuleChange(id, skillSortReverse)
  end
end

function UMG_Pet_TeamReplace_C:OnImportClick()
  self:ResetDescText()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenLoadPetTeamPanel, self.curTeamType, self.curTeamIdx)
end

function UMG_Pet_TeamReplace_C:OnShareClick()
  self:ResetDescText()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE, true)
  if isBan then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenShareTeamPanel, self.curTeamType, self.curTeamIdx)
end

function UMG_Pet_TeamReplace_C:OnShowLockSkillClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_Pet_TeamReplace_C:OnShowLockSkillClick")
  self:CloseTipsAndClearSkillListSelection()
  local ChangePetSkillsPanel = self.ChangePetSkillsPanel:GetPanel()
  if ChangePetSkillsPanel then
    self.showLockSkill = not self.showLockSkill
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsShowPetNotUnlockSkill, self.showLockSkill)
    self:RefreshShowLockSkillBtn()
    ChangePetSkillsPanel:OnShowLockSkillChange(self.showLockSkill)
  end
end

function UMG_Pet_TeamReplace_C:RefreshShowLockSkillBtn()
  local path, text
  if self.showLockSkill then
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockVisible_png.img_UnlockVisible_png'"
    text = LuaText.skill_sort_text_2
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_UnlockInvisible_png.img_UnlockInvisible_png'"
    text = LuaText.skill_sort_text_1
  end
  self.ViewPet_3:SetPath(path, path, path)
  self.ViewPet_3:SetText(text)
end

function UMG_Pet_TeamReplace_C:OnBagSKillTipsPanelShowChange(bShow)
  if bShow then
    self.NRCImage_76:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_76:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_TeamReplace_C:UpdatePvpSkillData()
  local state = self:GetState()
  local curShowPetData = state and state.curShowPetData
  local gid = curShowPetData and curShowPetData.gid
  local skillMap = self:GetSkillMapByPetGid(curShowPetData)
  local teamParam = self:GetTeamParam(gid)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPvpSkillData, skillMap, teamParam)
end

function UMG_Pet_TeamReplace_C:TryFetchBalancePetData(petDataList)
  local petGuidList = {}
  for i, petData in ipairs(petDataList) do
    local needSwitchToPvpBalancePetData = PetUtils.CheckNeedSwitchToPvpBalancePetData(petData)
    if needSwitchToPvpBalancePetData then
      local petGuid = petData and petData.gid
      if petGuid then
        table.insert(petGuidList, petGuid)
      end
    end
  end
  local balancedPetDataForPvpMap = {}
  local petGuidNeedQuery = {}
  for i, petGuid in ipairs(petGuidList) do
    local balancePetData = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CmdGetBalancedPetDataForPvp, petGuid)
    if petGuid and balancePetData then
      balancedPetDataForPvpMap[petGuid] = balancePetData
    else
      table.insert(petGuidNeedQuery, petGuid)
    end
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CmdQueryBalancedPetDataForPvp, petGuidNeedQuery)
  return balancedPetDataForPvpMap
end

function UMG_Pet_TeamReplace_C:OnWarehouseItemSpawn(petInfo)
end

function UMG_Pet_TeamReplace_C:SelectFirstPet()
  local state = self:GetState()
  local teamPetList = state and state.teamPetList or {}
  local curMode = state and state.modifyPetMode
  if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit and teamPetList then
    local trySelectPet = self:GetFirstNotCommonEvoPet()
    local curSelPetData = state and state.curSelPetData
    local curSelPetGid = curSelPetData and curSelPetData.gid
    local trySelectPetGid = trySelectPet and trySelectPet.gid
    if trySelectPetGid and trySelectPetGid == curSelPetGid then
      return
    end
    if trySelectPet then
    else
    end
    local _, nextState = self:GetCurrAndNextState()
    nextState.curSelPetData = trySelectPet
    self:SetState(nextState)
  elseif curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit and teamPetList then
    local trySelectPet = self:GetFirstNotCommonEvoPet()
    if trySelectPet then
      self:DispatchEvent(PetUIModuleEvent.PetTeamFastFormationSelected, trySelectPet)
    else
    end
  end
end

function UMG_Pet_TeamReplace_C.UpdatePetListUIState(sourceList, teamInfoDic, selPetGid, modifyPetMode, dragItemPetInfo, currDragHoveringPetData, currDragHoveringUiDataKey, exchangePetData, exchangeIsInTeam, needSelectWhenDragHovering, isWarehouseList)
  local hasAnyChange = false
  local deriveList = {}
  isWarehouseList = isWarehouseList or false
  for i, item in ipairs(sourceList) do
    local currentSelect = item and item.isSelect or false
    local currentRightNumber = item and item.rightShowNumber
    local currExchangePetData = item and item.exchangePetData
    local currExchangeIsInTeam = item and item.exchangeIsInTeam
    local isLockUp = item and item.isLockUp or false
    local nextIsSelect = false
    local nextRightNumber
    local nextExchangePetData = exchangePetData
    local nextExchangeIsInTeam = exchangeIsInTeam
    local isDraggingItem = nil ~= dragItemPetInfo
    local petData = item and item.PetData
    local petGid = petData and petData.gid
    local isInTeam = teamInfoDic and petGid and nil ~= teamInfoDic[petGid]
    if isInTeam and isWarehouseList then
      nextIsSelect = false
    elseif isDraggingItem and needSelectWhenDragHovering then
      local currDragHoveringPetId = currDragHoveringPetData and currDragHoveringPetData.gid
      local petInfoKey = item and item.key
      if (currDragHoveringPetId and currDragHoveringPetId == petGid or currDragHoveringUiDataKey == petInfoKey) and not isLockUp then
        nextIsSelect = true
      else
        nextIsSelect = false
      end
    elseif modifyPetMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
      if selPetGid and selPetGid == petGid then
        nextIsSelect = true
      end
    elseif modifyPetMode == PetUIModuleEnum.ModifyPetMode.QuickEdit and selPetGid and selPetGid == petGid then
      nextIsSelect = true
    end
    if modifyPetMode == PetUIModuleEnum.ModifyPetMode.QuickEdit and petGid and teamInfoDic[petGid] then
      nextRightNumber = teamInfoDic[petGid]
    end
    if currentSelect == nextIsSelect and currentRightNumber == nextRightNumber and currExchangePetData == nextExchangePetData and currExchangeIsInTeam == nextExchangeIsInTeam then
      table.insert(deriveList, item)
    else
      hasAnyChange = true
      local nextItem = {}
      table.copy(item, nextItem)
      nextItem.isSelect = nextIsSelect
      nextItem.rightShowNumber = nextRightNumber
      nextItem.exchangePetData = nextExchangePetData
      nextItem.exchangeIsInTeam = nextExchangeIsInTeam
      table.insert(deriveList, nextItem)
    end
  end
  if not hasAnyChange then
    return sourceList
  end
  return deriveList
end

function UMG_Pet_TeamReplace_C:OnRocoTouchStartHandler(touchIndex, position)
  local positionX = position and position.X or 0
  local positionY = position and position.Y or 0
  local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
  if 0 == scale then
    scale = 1
  end
  local positionXScaled = positionX / scale
  local positionYScaled = positionY / scale
  local currState, nextState = self:GetCurrAndNextState()
  local nextDragContext = {}
  local warehouseScrollOffset = self.WarehouseList:GetScrollOffset()
  nextDragContext.id = os.msTime()
  nextDragContext.startPosition = UE.FVector2D(positionX, positionY)
  nextDragContext.startPositionScaled = UE.FVector2D(positionXScaled, positionYScaled)
  nextDragContext.dragPosition = UE.FVector2D(positionX, positionY)
  nextDragContext.dragPositionScaled = UE.FVector2D(positionXScaled, positionYScaled)
  nextDragContext.startWarehouseScrollOffset = warehouseScrollOffset
  nextDragContext.currWarehouseScrollOffset = warehouseScrollOffset
  nextState.dragContextFromMoveStart = nextDragContext
  self:SetState(nextState)
  do
    local state = self:GetState()
    local dragContext = nextDragContext
    local touchContext = state and state.touchContextFromTouchProxy
    if dragContext and touchContext then
      self:InitDragContext(dragContext, touchContext)
    end
  end
end

function UMG_Pet_TeamReplace_C:InitDragContext(dragContextFromRocoTouchStart, touchContextFromProxy)
  if not dragContextFromRocoTouchStart or not touchContextFromProxy then
    return
  end
  local currState, nextState = self:GetCurrAndNextState()
  local currDragContext = currState and currState.dragContext
  if currDragContext then
    Log.Error("UMG_Pet_TeamReplace_C:OnRocoTouchStartHandler \229\188\128\229\167\139\230\139\150\230\139\189\230\151\182\239\188\140\229\141\180\229\143\145\231\142\176\229\133\136\229\137\141\231\154\132\230\139\150\230\139\189 context \230\156\170\233\148\128\230\175\129")
    self:DisposeDragContext(currDragContext)
  end
  local nextDragContext = {}
  table.copy(dragContextFromRocoTouchStart, nextDragContext)
  local enableTriggerDrag = currState and currState.enableTriggerDrag
  local longPressTime = currState and currState.longPressTime or 0
  local delayTime = math.max(longPressTime, 0.01)
  local longPressDelayId
  if enableTriggerDrag then
    longPressDelayId = self:DelaySeconds(delayTime, self.LongPressDelayTimeout, self)
  end
  nextDragContext.longPressDelayId = longPressDelayId
  local canInteractAtStart = touchContextFromProxy and touchContextFromProxy.canInteractAtStart
  nextDragContext.canInteractAtStart = canInteractAtStart or false
  local startPositionAbsolute = touchContextFromProxy and touchContextFromProxy.startPositionAbsolute
  nextDragContext.startPositionFromTouchContext = startPositionAbsolute or UE.FVector2D(0, 0)
  nextDragContext.mousePosition = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld()) or UE.FVector2D(0, 0)
  nextState.dragContext = nextDragContext
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:OnRocoTouchMoveHandler(touchIndex, position)
  local positionX = position and position.X or 0
  local positionY = position and position.Y or 0
  local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
  if 0 == scale then
    scale = 1
  end
  local positionXScaled = positionX / scale
  local positionYScaled = positionY / scale
  local currState, nextState = self:GetCurrAndNextState()
  local currDragContext = currState and currState.dragContext
  local enableTriggerDrag = currState and currState.enableTriggerDrag
  local teamDragPetData = currState and currState.teamDragPetData
  local warehouseDragPetData = currState and currState.warehouseDragPetData
  local isDragStartHoveringWarehouseListArea = currState and currState.isDragStartHoveringWarehouseListArea
  local dragPetData = currState and currState.dragPetData
  local dragStartedAtCanScrollArea = isDragStartHoveringWarehouseListArea
  local canDragAnyDirection = false
  if not dragStartedAtCanScrollArea then
    canDragAnyDirection = true
  end
  local nextDragContext = {}
  table.copy(currDragContext, nextDragContext)
  local nextDragPosition = UE.FVector2D(positionX, positionY)
  local nextDragPositionScaled = UE.FVector2D(positionXScaled, positionYScaled)
  nextDragContext.dragPosition = nextDragPosition
  nextDragContext.dragPositionScaled = nextDragPositionScaled
  nextDragContext.mousePosition = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld()) or UE.FVector2D(0, 0)
  local currIsDraggingItem = currDragContext and currDragContext.isDraggingItem
  local currIsScrollingList = currDragContext and currDragContext.isScrollingList
  local canInteractAtStart = currDragContext and currDragContext.canInteractAtStart
  local startPosition = currDragContext and currDragContext.startPosition
  local startPositionScaled = currDragContext and currDragContext.startPositionScaled
  local startPositionX = startPosition and startPosition.X or 0
  local startPositionY = startPosition and startPosition.Y or 0
  local startPositionXScaled = startPositionScaled and startPositionScaled.X or 0
  local startPositionYScaled = startPositionScaled and startPositionScaled.Y or 0
  local nextPositionX = nextDragPosition and nextDragPosition.X or 0
  local nextPositionY = nextDragPosition and nextDragPosition.Y or 0
  local nextPositionXScaled = nextDragPositionScaled and nextDragPositionScaled.X or 0
  local nextPositionYScaled = nextDragPositionScaled and nextDragPositionScaled.Y or 0
  local diffVector = UE.FVector2D(nextPositionXScaled - startPositionXScaled, nextPositionYScaled - startPositionYScaled)
  local diffVectorX = diffVector and diffVector.X
  local diffVectorY = diffVector and diffVector.Y
  local angleToHorizontalAxis
  if math.abs(diffVectorX) > 0.1 or math.abs(diffVectorY) > 0.1 then
    local angleRadians = math.atan(diffVector.Y, diffVector.X)
    local angleDegrees = math.abs(angleRadians * 180 / math.pi)
    if angleDegrees > 90 then
      angleToHorizontalAxis = 180 - angleDegrees
    else
      angleToHorizontalAxis = angleDegrees
    end
  end
  local angleToVerticalAxis
  if angleToHorizontalAxis then
    angleToVerticalAxis = math.abs(90 - angleToHorizontalAxis)
  end
  nextDragContext.angleToHorizontalAxis = angleToHorizontalAxis
  if not currIsDraggingItem and not currIsScrollingList and nil ~= angleToHorizontalAxis then
    local dragAngleThreshold = currState and currState.dragAngleThreshold or 0
    local isInDragDirectionRange = angleToVerticalAxis <= dragAngleThreshold or canDragAnyDirection
    local currDragDistance = diffVectorY and diffVectorY and math.abs(diffVectorY) or 0
    if canDragAnyDirection then
      currDragDistance = math.max(currDragDistance, diffVectorX and diffVectorX and math.abs(diffVectorX) or 0)
    end
    local swipeAngleThreshold = currState and currState.swipeAngleThreshold or 0
    local isInSwipeDirectionRange = angleToHorizontalAxis <= swipeAngleThreshold
    local currSwipeDistance = diffVectorX and diffVectorX and math.abs(diffVectorX) or 0
    local dragDistanceThreshold = currState and currState.dragDistanceThreshold or 0
    local overDragThreshold = currDragDistance > dragDistanceThreshold
    local swipeDistanceThreshold = currState and currState.swipeDistanceThreshold or 0
    local overSwipeThreshold = currSwipeDistance > swipeDistanceThreshold
    if isInDragDirectionRange and overDragThreshold and nil ~= dragPetData and enableTriggerDrag then
      nextDragContext.overDragThreshold = true
    elseif isInSwipeDirectionRange and overSwipeThreshold and dragStartedAtCanScrollArea then
      nextDragContext.overSwipeThreshold = true
    end
  end
  nextState.dragContext = nextDragContext
  self:SetState(nextState)
  self:RefreshWarehouseScrollOffset()
end

function UMG_Pet_TeamReplace_C:OnRocoTouchEndHandler(touchIndex)
  local currState, nextState = self:GetCurrAndNextState()
  local currDragContext = currState and currState.dragContext
  local isDraggingItem = currDragContext and currDragContext.isDraggingItem
  local isScrollingList = currDragContext and currDragContext.isScrollingList
  if isDraggingItem then
    local dragPetData = currState and currState.dragPetData
    local teamDragPetData = currState and currState.teamDragPetData
    local warehouseDragPetData = currState and currState.warehouseDragPetData
    local dragHoveringPetData = currState and currState.dragHoveringPetData
    local teamDragHoveringPetData = currState and currState.teamDragHoveringPetData
    local warehouseDragHoveringPetData = currState and currState.warehouseDragHoveringPetData
    local isDragHoveringTeamListArea = currState and currState.isDragHoveringTeamListArea
    local isDragHoveringRecycleArea = currState and currState.isDragHoveringRecycleArea
    local petData, targetData
    local isRecyclePet = false
    if dragPetData and dragPetData == teamDragPetData then
      if isDragHoveringRecycleArea then
        isRecyclePet = true
      elseif dragHoveringPetData and dragHoveringPetData == teamDragHoveringPetData or isDragHoveringTeamListArea then
        petData = dragHoveringPetData
        targetData = dragPetData
      end
    elseif dragPetData and dragPetData == warehouseDragPetData and (dragHoveringPetData and dragHoveringPetData == teamDragHoveringPetData or isDragHoveringTeamListArea) then
      petData = dragHoveringPetData
      targetData = dragPetData
    end
    local state = self:GetState()
    local curExChangeState = state and state.curExChangeState
    if curExChangeState == ExChangeState.ExChanging then
      if isRecyclePet then
        self:OnRecyclingBtn()
      else
        self:TryExChangePet(petData, targetData)
      end
      self:OnExchangeBtnClick()
    end
  elseif isScrollingList then
    local startWarehouseScrollOffset = currDragContext and currDragContext.startWarehouseScrollOffset
    local currWarehouseScrollOffset = currDragContext and currDragContext.currWarehouseScrollOffset
    if startWarehouseScrollOffset and currWarehouseScrollOffset then
      local diffAbs = math.abs(startWarehouseScrollOffset - currWarehouseScrollOffset)
      local swipeDistanceThreshold = currState and currState.swipeDistanceThreshold or 0
      if diffAbs > swipeDistanceThreshold then
        if startWarehouseScrollOffset > currWarehouseScrollOffset then
          self:WarehouseGoToPrevPage()
        end
        if startWarehouseScrollOffset < currWarehouseScrollOffset then
          self:WarehouseGoToNextPage()
        end
      end
    end
  end
  self:DisposeDragContext(currDragContext)
  currState, nextState = self:GetCurrAndNextState()
  nextState.dragContext = nil
  nextState.dragContextFromMoveStart = nil
  nextState.touchContextFromTouchProxy = nil
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:DisposeDragContext(dragContext)
  local longPressDelayId = dragContext and dragContext.longPressDelayId
  if longPressDelayId then
    self:CancelDelayByID(longPressDelayId)
  end
end

function UMG_Pet_TeamReplace_C:LongPressDelayTimeout()
  local currState, nextState = self:GetCurrAndNextState()
  local currDragContext = currState and currState.dragContext
  if nil == currDragContext then
    return
  end
  local dragPetData = currState and currState.dragPetData
  if nil == dragPetData then
    return
  end
  local currIsScrollingList = currDragContext and currDragContext.isScrollingList
  if currIsScrollingList then
    return
  end
  local enableTriggerDrag = currState and currState.enableTriggerDrag
  if not enableTriggerDrag then
    return
  end
  local nextDragContext = {}
  table.copy(currDragContext, nextDragContext)
  nextDragContext.longPressTimeout = true
  nextState.dragContext = nextDragContext
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:RefreshWarehouseRowAndCol()
  local state = self:GetState()
  local currRowCount = state and state.warehouseRowCount
  local warehouseRowHeight = state and state.warehouseRowHeight or 1
  local containerGeometry = self.WarehouseListContainer:GetCachedGeometry()
  local containerSize = UE4.USlateBlueprintLibrary.GetLocalSize(containerGeometry)
  local containerSizeX = containerSize and containerSize.X or 0
  local containerSizeY = containerSize and containerSize.Y or 0
  if 0 == containerSizeX and 0 == containerSizeY then
    local currState, nextState = self:GetCurrAndNextState()
    local currFetchWarehouseUiSizeContext = currState and currState.fetchWarehouseUiSizeContext
    if currFetchWarehouseUiSizeContext then
      local nextContext = {}
      table.copy(currFetchWarehouseUiSizeContext, nextContext)
      local restFrame = currFetchWarehouseUiSizeContext and currFetchWarehouseUiSizeContext.restFrame or 0
      if restFrame <= 0 then
        nextContext.isRunning = false
        nextContext.isFinished = true
        Log.Error("[UMG_Pet_TeamReplace_C] \230\156\170\232\131\189\230\173\163\231\161\174\232\142\183\229\143\150 warehouse ui \231\154\132\229\176\186\229\175\184\239\188\140fetch context \229\183\178\232\162\171\229\188\186\229\136\182\231\187\147\230\157\159")
      else
        nextContext.restFrame = restFrame - 1
      end
      nextState.fetchWarehouseUiSizeContext = nextContext
      self:SetState(nextState)
    end
    return
  end
  local nextRowCount = math.floor(containerSizeY / warehouseRowHeight)
  if nextRowCount <= 0 then
    nextRowCount = 1
  end
  local currState, nextState = self:GetCurrAndNextState()
  nextState.warehouseRowCount = nextRowCount
  local currFetchWarehouseUiSizeContext = currState and currState.fetchWarehouseUiSizeContext
  if currFetchWarehouseUiSizeContext then
    local nextContext = {}
    table.copy(currFetchWarehouseUiSizeContext, nextContext)
    nextContext.isRunning = false
    nextContext.isFinished = true
    nextState.fetchWarehouseUiSizeContext = nextContext
  end
  self:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:RefreshWarehouseScrollOffset()
  local currState, nextState = self:GetCurrAndNextState()
  local currDragContext = currState and currState.dragContext
  local isDragStartHoveringWarehouseListArea = currState and currState.isDragStartHoveringWarehouseListArea
  local canInteractAtStart = currDragContext and currDragContext.canInteractAtStart
  local startPositionFromTouchContext = currDragContext and currDragContext.startPositionFromTouchContext
  local dragPositionFromTouchContext = currDragContext and currDragContext.dragPositionFromTouchContext
  if isDragStartHoveringWarehouseListArea and canInteractAtStart and startPositionFromTouchContext and dragPositionFromTouchContext then
    local startWarehouseLocalPosition = self.WarehouseGridTouchProxy:GetLocalPositionFromScreenPosition(startPositionFromTouchContext)
    local currentWarehouseLocalPosition = self.WarehouseGridTouchProxy:GetLocalPositionFromScreenPosition(dragPositionFromTouchContext)
    local startWarehouseLocalPositionX = startWarehouseLocalPosition and startWarehouseLocalPosition.X
    local currentWarehouseLocalPositionX = currentWarehouseLocalPosition and currentWarehouseLocalPosition.X
    local startWarehouseScrollOffset = currDragContext and currDragContext.startWarehouseScrollOffset
    if startWarehouseScrollOffset and startWarehouseLocalPositionX and currentWarehouseLocalPositionX then
      nextState.startWarehouseScrollOffset = startWarehouseScrollOffset
      nextState.startWarehouseLocalPositionX = startWarehouseLocalPositionX
      nextState.currWarehouseLocalPositionX = currentWarehouseLocalPositionX
      local currWarehouseScrollOffset = startWarehouseScrollOffset - (currentWarehouseLocalPositionX - startWarehouseLocalPositionX)
      local minOffset = 0
      local maxOffset = self.WarehouseList:GetMaxScrollOffset()
      currWarehouseScrollOffset = math.clamp(currWarehouseScrollOffset, minOffset, maxOffset)
      local nextDragContext = {}
      table.copy(currDragContext, nextDragContext)
      nextDragContext.currWarehouseScrollOffset = currWarehouseScrollOffset
      nextState.dragContext = nextDragContext
      self:SetState(nextState)
    end
  end
end

function UMG_Pet_TeamReplace_C:GetDragDebugText()
  local state = self:GetState()
  local touchContextMap = state and state.touchContextMap or {}
  local dragContext = state and state.dragContext
  local sourceGridType = dragContext and dragContext.sourceGridType
  local touchContext = touchContextMap and sourceGridType and touchContextMap[sourceGridType]
  local startPosition = dragContext and dragContext.startPosition or UE.FVector2D(0, 0)
  local dragPosition = dragContext and dragContext.dragPosition or UE.FVector2D(0, 0)
  local startPositionFromTouchContext = dragContext and dragContext.startPositionFromTouchContext or UE.FVector2D(0, 0)
  local dragPositionFromTouchContext = dragContext and dragContext.dragPositionFromTouchContext or UE.FVector2D(0, 0)
  local dragPositionScaled = dragContext and dragContext.dragPositionScaled or UE.FVector2D(0, 0)
  local mousePosition = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld()) or UE.FVector2D(0, 0)
  local deltaPosition = dragPosition - startPosition
  local BorderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
  local BorderHeight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
  local world = UE4Helper.GetCurrentWorld()
  local dragPositionViewport = UE.FVector2D(0, 0)
  UE.USlateBlueprintLibrary.ScreenToViewportConsiderBorder(world, dragPosition, dragPositionViewport)
  local dragPositionAbsolute = startPositionFromTouchContext + deltaPosition
  local dragPositionText = string.format("dragPositionFromTouchContext: (%.2f, %.2f)", dragPositionFromTouchContext.X, dragPositionFromTouchContext.Y)
  local dragPositionScaledText = string.format("dragPositionScaled: (%.2f, %.2f)", dragPositionScaled.X, dragPositionScaled.Y)
  local dragPositionViewportText = string.format("dragPositionViewport: (%.2f, %.2f)", dragPositionViewport.X, dragPositionViewport.Y)
  local dragPositionAbsoluteText = string.format("dragPositionAbsolute: (%.2f, %.2f)", dragPositionAbsolute.X, dragPositionAbsolute.Y)
  local mousePositionText = string.format("mousePosition: (%.2f, %.2f)", mousePosition.X, mousePosition.Y)
  local textList = {
    dragPositionText,
    dragPositionScaledText,
    dragPositionViewportText,
    dragPositionAbsoluteText,
    mousePositionText
  }
  local text = ""
  for i, textItem in ipairs(textList) do
    if i > 1 then
      text = text .. "\n"
    end
    text = text .. textItem
  end
  return text
end

function UMG_Pet_TeamReplace_C:GetProps()
  return self.stateManager:GetProps()
end

function UMG_Pet_TeamReplace_C:SetProps(nextProps)
  self.stateManager:SetProps(nextProps)
end

function UMG_Pet_TeamReplace_C:GetState()
  return self.stateManager:GetState()
end

function UMG_Pet_TeamReplace_C:SetState(nextState)
  self.stateManager:SetState(nextState)
end

function UMG_Pet_TeamReplace_C:GetCurrAndNextState()
  return self.stateManager:GetCurrAndNextState()
end

return UMG_Pet_TeamReplace_C

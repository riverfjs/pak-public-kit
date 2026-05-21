local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local NPCShopUIModuleEvent = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local Delegate = require("Utils.Delegate")
local UIUtils = require("NewRoco.Utils.UIUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PER_PETBOX_MAX_SIZE = 30
local UMG_PetPortableBag_C = _G.NRCPanelBase:Extend("UMG_PetPortableBag_C")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local EnumPetTalent = {
  Soso = 1,
  NotBad = 2,
  Good = 3,
  Amazing = 4
}
local MAX_TEAM_PET_NUM = 6

function UMG_PetPortableBag_C:OnConstruct()
  self.curTeamInfo = nil
  self.TeamIndex = nil
  self.SelectBoxIndex = 1
  self.SelectBoxData = nil
  self.CacheFilterData = nil
  self.LastOpenBoxId = 1
  self.isReleaseLifeMode = false
  self.isShowFilterPanel = false
  self.CurAllPetPage = 1
  self.CurAllPetPageMax = 1
  self.CurSelectPetIndex = 0
  self.CurSelectPetGid = 0
  self.CurSelectItem = nil
  self.CurBackpackPetList = nil
  self.CurBattleTeamPetIndex = 0
  self.maxNameLength = _G.DataConfigManager:GetPetGlobalConfig("box_name_length").num
  self.startPos = UE4.FVector2D(0, 0)
  self:OnAddEventListener()
  self.OnGuidanceScrollUp = Delegate()
  self.OnGuidanceScrollDown = Delegate()
  self.NRCText_74:SetText(LuaText.umg_bag_7)
  self.NRCText_1:SetText(LuaText.Select_Null_Pet_Detail)
  self.Title_1:SetText(LuaText.box_drag_to_free)
  self.minInterval = _G.DataConfigManager:GetPetGlobalConfig("box_click_minimum_interval").num
  self.minDis = _G.DataConfigManager:GetPetGlobalConfig("box_drag_minimum_distance").num
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfigByKeyType("drag_mode_press_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num / 1000
  self.pcExtraPressTime = _G.DataConfigManager:GetPetGlobalConfig("PC_hold_extra_time").num / 1000
  self.pcMinDis = _G.DataConfigManager:GetPetGlobalConfig("PC_drag_least_distance").num
end

function UMG_PetPortableBag_C:OnAddEventListener()
  self.ScrollPageController:SetPageChangeHandler(self.OnPageChangeHandle, self)
  self.ScrollPageController.pageScrollTime = 0.25
  self:AddButtonListener(self.SwitchBtn.btnLevelUp, self.ClosePanel)
  self:AddButtonListener(self.EditBoxButton, self.OnClickEditBoxBtn)
  self:AddButtonListener(self.ScreenBtn.btnLevelUp, self.OnClickScreenBtn)
  self:AddButtonListener(self.ReleaseLifeBtn.btnLevelUp, self.OnSwitchReleaseLifeMode)
  self:AddButtonListener(self.Btn_ReleaseLife.btnLevelUp, self.OnFreeBtnClick)
  self:AddButtonListener(self.LeftArrowBtn.btnLevelUp, self.OnClickLeftArrowBtn)
  self:AddButtonListener(self.RightArrowBtn.btnLevelUp, self.OnClickRightArrowBtn)
  self:AddButtonListener(self.QuickSelectionBtn.btnLevelUp, self.OnClickQuickSelection)
  self.EditBoxButton.OnPressed:Add(self, self.OnPressedEditBoxBtn)
  self.EditBoxButton.OnReleased:Add(self, self.OnReleasedEditBoxBtn)
  self:RegisterEvent(self, PetUIModuleEvent.OnClickSelectPetBagBoxItem, self.OnUpdateBoxInfo)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxChangeNotifyEvent, self.OnPetBoxChangeNotify)
  self:RegisterEvent(self, PetUIModuleEvent.OnBigWorldTeamPetChangeEvent, self.OnBigWorldTeamPetChangeEvent)
  self:RegisterEvent(self, PetUIModuleEvent.OnLeavePetBoxFilter, self.OnLeavePetBoxFilter)
  self:RegisterEvent(self, PetUIModuleEvent.PetBagOnPetItemClick, self.OnUpdatePetItemClickIndex)
  self:RegisterEvent(self, PetUIModuleEvent.PetBagOnSelectPetBag, self.OnPetBagSelectByGid)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxFilter, self.OnFilter)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxMarkChange, self.OnPetBoxMarkChange)
  self:RegisterEvent(self, PetUIModuleEvent.ApplyBatchSelectFree, self.ApplyBatchSelectFree)
  self:RegisterEvent(self, PetUIModuleEvent.OnExchangePetFail, self.OnExchangePetFail)
  self:RegisterEvent(self, PetUIModuleEvent.OnEnterBoxEditState, self.OnEnterBoxEditState)
  self:RegisterEvent(self, PetUIModuleEvent.ChangeChoosePet, self.ChangeChoosePet)
  self:RegisterEvent(self, PetUIModuleEvent.PET_TEAM_CHANGE, self.PetTeamChanage)
  self:RegisterEvent(self, PetUIModuleEvent.PET_FREE_CANCEL, self.OnPetFreeCancel)
  self:RegisterEvent(self, PetUIModuleEvent.ShowPetInfoMainUI, self.OnShowPetEvo)
  self:RegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.OnUpdateEvoPetModel)
  self:RegisterEvent(self, PetUIModuleEvent.OnSendPetSuccess, self.OnSendPetSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.OnUpdatePetBagEmptyView, self.UpdateEmptyView)
  self:RegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUpdatePetLevel)
  self:RegisterEvent(self, PetUIModuleEvent.UpdatePetCollect, self.OnUpdatePetCollect)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewPetBagRightPanelClose, self.OnNewPetBagRightPanelClose)
  self:RegisterEvent(self, PetUIModuleEvent.OpenDetailPanelEvent, self.OnOpenDetailPanel)
  self:RegisterEvent(self, PetUIModuleEvent.OnDisablePetBagItems, self.OnSwitchBagItemDisableState)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewPetBagExitFree, self.OnNewPetBagExitFree)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewPetBagExitScreen, self.OnNewPetBagExitScreen)
  self:RegisterEvent(self, PetUIModuleEvent.AttributeChangeSetEggBtn, self.AttributeChangeSetEggBtn)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetBoxUpdate, self.OnPetBoxUpdate)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.ShowPetBoxListView)
  _G.NRCEventCenter:RegisterEvent("UMG_PetPortableBag_C", self, PetUIModuleEvent.PetBagDragSelectItem, self.OnDragSelectItem)
  _G.NRCEventCenter:RegisterEvent("UMG_PetPortableBag_C", self, PetUIModuleEvent.SetPanelCanScroll, self.SetPetListPanelCanScroll)
  _G.NRCEventCenter:RegisterEvent("UMG_PetPortableBag_C", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_PetPortableBag_C", self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_PetPortableBag_C", self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
end

function UMG_PetPortableBag_C:OnDeactive()
  self:UnRegisterEvent(self, PetUIModuleEvent.OnClickSelectPetBagBoxItem, self.OnUpdateBoxInfo)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxChangeNotifyEvent, self.OnPetBoxChangeNotify)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnBigWorldTeamPetChangeEvent, self.OnBigWorldTeamPetChangeEvent)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnLeavePetBoxFilter, self.OnLeavePetBoxFilter)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxFilter, self.OnFilter)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxMarkChange, self.OnPetBoxMarkChange)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetBagOnSelectPetBag, self.OnPetBagSelectByGid)
  self:UnRegisterEvent(self, PetUIModuleEvent.ApplyBatchSelectFree, self.ApplyBatchSelectFree)
  self:UnRegisterEvent(self, PetUIModuleEvent.ChangeChoosePet, self.ChangeChoosePet)
  self:UnRegisterEvent(self, PetUIModuleEvent.PET_TEAM_CHANGE, self.PetTeamChanage)
  self:UnRegisterEvent(self, PetUIModuleEvent.PET_FREE_CANCEL, self.OnPetFreeCancel)
  self:UnRegisterEvent(self, PetUIModuleEvent.ShowPetInfoMainUI, self.OnShowPetEvo)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.OnUpdateEvoPetModel)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnSendPetSuccess, self.OnSendPetSuccess)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnUpdatePetBagEmptyView, self.UpdateEmptyView)
  self:UnRegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUpdatePetLevel)
  self:UnRegisterEvent(self, PetUIModuleEvent.UpdatePetCollect, self.OnUpdatePetCollect)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagRightPanelClose, self.OnNewPetBagRightPanelClose)
  self:UnRegisterEvent(self, PetUIModuleEvent.OpenDetailPanelEvent, self.OnOpenDetailPanel)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnDisablePetBagItems, self.OnSwitchBagItemDisableState)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagExitFree, self.OnNewPetBagExitFree)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagExitScreen, self.OnNewPetBagExitScreen)
  self:UnRegisterEvent(self, PetUIModuleEvent.AttributeChangeSetEggBtn, self.AttributeChangeSetEggBtn)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnPetBoxUpdate, self.OnPetBoxUpdate)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.ShowPetBoxListView)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetBagDragSelectItem, self.OnDragSelectItem)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.SetPanelCanScroll, self.SetPetListPanelCanScroll)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  if UE4.UObject.IsValid(self.DragItemInstance) then
    self.DragItemInstance:RemoveFromParent()
    self.DragItemInstance = nil
  end
  self:CancelDelay()
  self.module:CloseNewPetBagBoxPanel(true)
end

function UMG_PetPortableBag_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxLastOpenBoxReq, self.LastOpenBoxId)
  self:DispatchEvent(PetUIModuleEvent.OnNewPetBagEnterScreenState, false, false)
  self:DispatchEvent(PetUIModuleEvent.OnOpenNewPetBag, false)
  self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, 3)
  self:DispatchEvent(PetUIModuleEvent.OnOpenNewPetBagDetails, false)
  self:ClearChildrenPanelState()
end

function UMG_PetPortableBag_C:OnActive()
  Log.Debug("UMG_PetPortableBag_C:OnActive")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").OPEN
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  self:InitData()
  self:ShowPetTeamListView()
  self:ShowPetBoxListView()
  self:UpdateReleaseLifeModeUI()
  local CurSelectListIndex, CurSelectItemIndex
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCurSelectInfoInPortableBag)
  local bNeedAutoSelectTeamPet = true
  if nil ~= CurSelectItemIndex then
    bNeedAutoSelectTeamPet = false
  end
  self:DispatchEvent(PetUIModuleEvent.OnOpenNewPetBag, true, bNeedAutoSelectTeamPet)
  if self:IsShowChildrenPanel() then
    self:DispatchEvent(PetUIModuleEvent.OnOpenNewPetBagDetails, true)
  else
    self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, 2)
  end
  self:PlayAnimation(self.In)
  self:DelayFrames(10, function()
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.RealOpenNewPetBagBoxPanel)
  end)
end

function UMG_PetPortableBag_C:InitData()
  self:InitOrResetFreeData()
  self:ClearSelectData()
  self:InitOrResetAllQuickSelectPetGidList()
  self:SetIsCanHandleFreeListInReleaseLifeMode(true)
  self.FreeLimitNum = _G.DataConfigManager:GetPetGlobalConfig("pet_depot_release_maximun").num
  self.CanScroll = true
  self.bIsPendingResPetUpdatePkg = false
  self.ScrollPageController:SetVisibility(UE4.ESlateVisibility.Visible)
  self.PetBagDragList:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ScrollPageController.bCyclicScrolling = true
  self.ScrollPageController.touchScrollSensitivity = _G.DataConfigManager:GetPetGlobalConfig("swipe_distance_to_change_pet_team").num
  local cacheFilterData = self.module:GetCachePetBoxFilterData()
  local isCondition = self.module:IsFilteringCondition(cacheFilterData.Condition)
  if isCondition then
    self.ScreenBtn:SetPath(UEPath.Box_Screen_1, UEPath.Box_Screen_1, UEPath.Box_Screen_1)
  else
    self.ScreenBtn:SetPath(UEPath.Box_Screen_2, UEPath.Box_Screen_2, UEPath.Box_Screen_2)
  end
  self.bInitBagPet = false
end

function UMG_PetPortableBag_C:InitOrResetAllQuickSelectPetGidList()
  self.AllQuickSelectPetGidList = {}
  self.AllQuickSelectPetGidList[EnumPetTalent.Soso] = {}
  self.AllQuickSelectPetGidList[EnumPetTalent.NotBad] = {}
  self.AllQuickSelectPetGidList[EnumPetTalent.Good] = {}
  self.AllQuickSelectPetGidList[EnumPetTalent.Amazing] = {}
end

function UMG_PetPortableBag_C:InitOrResetFreeData()
  self.FreePetDataList = {}
  self.FreeListFastLookupMap = {}
  self.AllBoxFreeNumList = {}
  self.CurHandleFreePetData = nil
  self:DispatchEvent(PetUIModuleEvent.OnFreeListClear)
end

function UMG_PetPortableBag_C:GetBoxPetIndex(pet_gid)
  local boxInfos = self:GetPetBoxDatas()
  for _, v in pairs(boxInfos or {}) do
    if v.petBoxInfo then
      for j, gid in pairs(v.petBoxInfo.pet_gid or {}) do
        if gid == pet_gid then
          local selectBoxId = v.petBoxInfo.box_id
          local selectIndex = j - 1
          return selectBoxId, selectIndex
        end
      end
    end
  end
  return nil, nil
end

function UMG_PetPortableBag_C:GetDefaultSelectIndex()
  local box_id, select_idx, selectGID, bSelectTeamPet
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  local isOpenPetBag, gid = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetBag)
  if isOpenPetBag then
    selectGID = gid
    box_id, select_idx = self:GetBoxPetIndex(gid)
    bSelectTeamPet = false
  elseif openPetData and openPetData.gid then
    local isHaveTeam = false
    local pet_gid = openPetData.gid
    selectGID = pet_gid
    if pet_gid and self.battlePetInfos then
      for i, v in pairs(self.battlePetInfos) do
        if v.gid == pet_gid then
          select_idx = i - 1
          isHaveTeam = true
          bSelectTeamPet = true
          break
        end
      end
    end
    if not isHaveTeam then
      box_id, select_idx = self:GetBoxPetIndex(openPetData.gid)
      bSelectTeamPet = false
    end
  end
  Log.Debug("UMG_PetPortableBag_C:GetDefaultSelectIndex box_id=[", box_id or 0, "], select_idx=[", select_idx or 0, "], selectGID=[", selectGID or 0, "], bSelectTeamPet=[", bSelectTeamPet, "]")
  return box_id, select_idx, selectGID, bSelectTeamPet
end

function UMG_PetPortableBag_C:OnPetItemClick(idx, isSelected, petData, tuiItem)
  self.CurSelectPetIndex = idx
  self.CurSelectItem = tuiItem
  self.CurSelectPetGid = petData and petData.gid or nil
  if idx > MAX_TEAM_PET_NUM then
    self.BattlePetList:ClearSelection()
  else
    self.BagPetList:ClearSelection()
  end
end

function UMG_PetPortableBag_C:UpdateEmptyView()
  local CurSelectPetGID = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurSelectPetGIDInPortableBag)
  local isFiltering, filterList = self:GetCachePetListInfo()
  local IsEmptyFilterView = false
  if isFiltering and 0 == #filterList then
    IsEmptyFilterView = true
  end
  local bDetailsPanelOpen = false
  if not self.module:GetOpenPetAttribute() then
    bDetailsPanelOpen = true
  end
  local bEditBoxPanelOpen = false
  if self.module:GetNewPetBagBoxPanelOpenState() then
    bEditBoxPanelOpen = true
  end
  local bFilterPanelOpen = false
  if self.module:GetNewPetBagWarehouseScreeningPanelOpenState() then
    bFilterPanelOpen = true
  end
  if not IsEmptyFilterView and not bDetailsPanelOpen and not bEditBoxPanelOpen and not bFilterPanelOpen and (nil == CurSelectPetGID or nil ~= CurSelectPetGID and 0 == CurSelectPetGID) then
    self.PetEmptyState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PetEmptyState:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetPortableBag_C:OnSwitchDefaultMode()
  self.LockImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SortedOut:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ScreenBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  self:UpdateBottomPanel()
  for i = 1, self.BagPetList:GetItemCount() do
    local item = self.BagPetList:GetItemByIndex(i - 1)
    if item then
      item:SwitchToReset()
    end
  end
  for i = 1, self.BattlePetList:GetItemCount() do
    local item = self.BattlePetList:GetItemByIndex(i - 1)
    if item then
      item:SwitchToReset()
    end
  end
end

function UMG_PetPortableBag_C:OnSwitchFilterMode()
  self.LockImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:UpdateBottomPanel()
  for i = 1, self.BattlePetList:GetItemCount() do
    local item = self.BattlePetList:GetItemByIndex(i - 1)
    if item then
      item:SwitchToReset()
    end
  end
end

function UMG_PetPortableBag_C:OnSwitchFilterDisableMode()
  for i = 1, self.BagPetList:GetItemCount() do
    local item = self.BagPetList:GetItemByIndex(i - 1)
    if UE4.UObject.IsValid(item) then
      item:SwitchToChange()
    end
  end
  for i = 1, self.BattlePetList:GetItemCount() do
    local item = self.BattlePetList:GetItemByIndex(i - 1)
    if UE4.UObject.IsValid(item) then
      item:SwitchToChange()
    end
  end
  self.SortedOut:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ScreenBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetPortableBag_C:UpdateBottomPanel()
  local isFiltering, filterList = self:GetCachePetListInfo()
  self.NRCSwitcher_0:SetActiveWidgetIndex(isFiltering and 1 or 0)
  if not self.isShowFilterPanel then
    if isFiltering and 0 == #filterList then
      self.LeftArrowBtn.btnLevelUp:SetIsEnabled(false)
      self.RightArrowBtn.btnLevelUp:SetIsEnabled(false)
    elseif isFiltering and #filterList > 0 then
      self.LeftArrowBtn.btnLevelUp:SetIsEnabled(true)
      self.RightArrowBtn.btnLevelUp:SetIsEnabled(true)
    elseif not isFiltering then
      self.LeftArrowBtn.btnLevelUp:SetIsEnabled(true)
      self.RightArrowBtn.btnLevelUp:SetIsEnabled(true)
    end
  else
    self.LeftArrowBtn.btnLevelUp:SetIsEnabled(false)
    self.RightArrowBtn.btnLevelUp:SetIsEnabled(false)
  end
  self:DispatchEvent(PetUIModuleEvent.OnNewPetBagEnterScreenState, isFiltering)
  self.Mask:SetVisibility(self.isShowFilterPanel and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.ScreenBtnMask:SetVisibility(self.isShowFilterPanel and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.ReleaseLifeBtnMask:SetVisibility(self.isShowFilterPanel and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.QuickSelectionBtnMask:SetVisibility(self.QuickSelectionBtn:GetVisibility() == UE4.ESlateVisibility.Visible and self.isShowFilterPanel and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.SwitchBtn.btnLevelUp:SetIsEnabled(not self.isShowFilterPanel)
  self.QuickSelectionSwitcher:SetActiveWidgetIndex(self.isShowFilterPanel and 1 or 0)
  self.ReleaseLifeSwitcher:SetActiveWidgetIndex(not self.isShowFilterPanel and #self.FreePetDataList > 0 and 0 or 1)
  self:UpdateReleaseLifeModeUI()
  if isFiltering then
    self:UpdateFilterPageText()
  end
end

function UMG_PetPortableBag_C:UpdateBigWorldTeamDataAndUI()
  self:SetTeamInfo()
  self:SetCurTeamPetList(self.TeamIndex)
end

function UMG_PetPortableBag_C:OnSwitchBagItemDisableState(isDisable)
  if isDisable then
    if self.isReleaseLifeMode then
      self.BatchReleaseAnimals:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:OnSwitchFilterDisableMode()
  else
    if self.isReleaseLifeMode then
      self.BatchReleaseAnimals:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.Left:SetVisibility(UE4.ESlateVisibility.Visible)
    self:OnSwitchDefaultMode()
  end
end

function UMG_PetPortableBag_C:OnSwitchReleaseLifeMode()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  self.isReleaseLifeMode = not self.isReleaseLifeMode
  self:DispatchEvent(PetUIModuleEvent.OnNewPetBagEnterScreenState, nil, self.isReleaseLifeMode)
  self:StopAnimation(self.Free_In)
  self:StopAnimation(self.Free_Out)
  if self.isReleaseLifeMode then
    self.ScrollPageController.LongPressDrag = false
    self.PetBagDragList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Free_In)
  else
    self.ScrollPageController.LongPressDrag = true
    self.PetBagDragList:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.Free_Out)
  end
  self:ClearSelection()
  self:InitOrResetFreeData()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_PetPortableBag_C:OnSwitchReleaseLifeMode")
  self:UpdateBottomPanel()
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.isReleaseLifeMode)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetCanShowSendBtn, not self.isReleaseLifeMode)
end

function UMG_PetPortableBag_C:IsReleaseLifeMode()
  return self.isReleaseLifeMode or false
end

function UMG_PetPortableBag_C:OnNewPetBagExitFree()
  if self:IsReleaseLifeMode() then
    self:OnSwitchReleaseLifeMode()
  end
end

function UMG_PetPortableBag_C:UpdateReleaseLifeModeUI()
  self.BatchReleaseAnimals:SetVisibility(self.isReleaseLifeMode and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.BatchReleaseAnimals:SetRenderOpacity(1)
  self.ReleaseLifeBtn:SwitchState(self.isReleaseLifeMode and 2 or 1)
  self.SelectQuantityText:SetText(self.FreePetDataList and #self.FreePetDataList or 0)
  self.ReleaseLifeSwitcher:SetActiveWidgetIndex(not self.isShowFilterPanel and #self.FreePetDataList > 0 and 0 or 1)
  self.QuickSelectionBtn:SetVisibility(self.isReleaseLifeMode and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetPortableBag_C:SetIsCanHandleFreeListInReleaseLifeMode(Flag)
  self.isCanFreePetInReleaseLifeMode = Flag
end

function UMG_PetPortableBag_C:GetIsCanHandleFreeListInReleaseLifeMode()
  return self.isCanFreePetInReleaseLifeMode or false
end

function UMG_PetPortableBag_C:UpdateAllQuickSelectPetGidList()
  self:InitOrResetAllQuickSelectPetGidList()
  local RawPetDataList = {}
  local NumList = {
    [EnumPetTalent.Soso] = 0,
    [EnumPetTalent.NotBad] = 0,
    [EnumPetTalent.Good] = 0
  }
  local cacheFilterData = self.module:GetCachePetBoxFilterData()
  local PetDataListInFilter = cacheFilterData.RawFilterList
  if PetDataListInFilter and #PetDataListInFilter > 0 then
    RawPetDataList = PetDataListInFilter
  else
    RawPetDataList = self.module:GetAllPetDatasWithoutBigWorldTeam()
  end
  for i = 1, #RawPetDataList do
    if not BattleUtils.GetBit(RawPetDataList[i].pet_status_flags, 1) then
      for j = 1, 4 do
        if RawPetDataList[i] and RawPetDataList[i].talent_rank == j and self:CheckIsCanBeQuickSelect(RawPetDataList[i]) and RawPetDataList[i].gid then
          table.insert(self.AllQuickSelectPetGidList[j], RawPetDataList[i].gid)
          if nil == NumList[j] then
            NumList[j] = 1
          else
            NumList[j] = NumList[j] + 1
          end
        end
      end
    end
  end
  return NumList
end

function UMG_PetPortableBag_C:CheckIsCanBeQuickSelect(petData)
  local IsCanBeQuickSelect = false
  local IsInBigWorldTeam = PetUtils.CheckIsBigWorldTeamPet(petData.gid)
  local IsCanBeFree = self:CheckIsCanFree(petData, true, false)
  local IsInFreeList = self:CheckIsInFreeList(petData)
  local IsGrown = false
  if petData and petData.grow_times and petData.grow_times > 0 then
    IsGrown = true
  end
  if IsCanBeFree and not IsInBigWorldTeam and not IsInFreeList and not IsGrown then
    IsCanBeQuickSelect = true
  end
  return IsCanBeQuickSelect
end

function UMG_PetPortableBag_C:OnClickQuickSelection()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_FavoriteButton_C:UpdateInfo")
  if not self:IsReleaseLifeMode() then
    return
  end
  local RetNumList = self:UpdateAllQuickSelectPetGidList()
  local sosoNum = RetNumList[EnumPetTalent.Soso]
  local notBadNum = RetNumList[EnumPetTalent.NotBad]
  local goodNUm = RetNumList[EnumPetTalent.Good]
  self.module:OpenPanel("QuickSelection", sosoNum, notBadNum, goodNUm)
end

function UMG_PetPortableBag_C:ApplyBatchSelectFree(TalentIndexList)
  for i, v in pairs(TalentIndexList or {}) do
    local TalentIndex = v.TalentIndex
    for _, petGid in pairs(self.AllQuickSelectPetGidList[TalentIndex] or {}) do
      if petGid then
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
        if petData and not self:CheckIsInFreeList(petData) then
          self:AddOrRemoveItemFromFreeList(petData, true)
        end
      end
    end
  end
  local isFiltering, filterList = self:GetCachePetListInfo()
  self:JumpToTargetBoxOrPage(isFiltering and self.CurAllPetPage or self.SelectBoxIndex)
end

function UMG_PetPortableBag_C:AddOrRemoveItemFromFreeList(petData, isAdd, bIgnorePvpOrPveTeam, FreeReasonType)
  bIgnorePvpOrPveTeam = bIgnorePvpOrPveTeam or false
  FreeReasonType = FreeReasonType or PetUIModuleEnum.PetFreeReasonType.FreeInFreeMode
  local IsAddOrRemoveSuccess = false
  if nil == petData then
    return IsAddOrRemoveSuccess
  end
  if not self:GetIsCanHandleFreeListInReleaseLifeMode() then
    return IsAddOrRemoveSuccess
  end
  self.CurHandleFreePetData = petData
  if isAdd then
    local IsCanFree = self:CheckIsCanFree(petData, false, bIgnorePvpOrPveTeam, FreeReasonType)
    if not IsCanFree and isAdd then
      return IsAddOrRemoveSuccess
    end
  end
  local AlreadyInFreeListIndex = 0
  for i, v in ipairs(self.FreePetDataList) do
    if v.gid == petData.gid then
      AlreadyInFreeListIndex = i
      break
    end
  end
  if isAdd and AlreadyInFreeListIndex > 0 then
    Log.Error("UMG_PetPortableBag_C:AddOrRemoveItemFromFreeList - petData.gid is already in free list - petData.gid=[" .. petData.gid .. "]")
    return IsAddOrRemoveSuccess
  end
  if isAdd then
    table.insert(self.FreePetDataList, petData)
    self.FreeListFastLookupMap[petData.gid] = petData
    local BoxID = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetBelongBoxID, petData.gid)
    if BoxID and self.AllBoxFreeNumList then
      if nil == self.AllBoxFreeNumList[BoxID] then
        self.AllBoxFreeNumList[BoxID] = 0
      end
      self.AllBoxFreeNumList[BoxID] = self.AllBoxFreeNumList[BoxID] + 1
    end
    IsAddOrRemoveSuccess = true
  elseif AlreadyInFreeListIndex > 0 then
    table.remove(self.FreePetDataList, AlreadyInFreeListIndex)
    self.FreeListFastLookupMap[petData.gid] = nil
    local BoxID = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetBelongBoxID, petData.gid)
    if BoxID and self.AllBoxFreeNumList and nil ~= self.AllBoxFreeNumList[BoxID] then
      self.AllBoxFreeNumList[BoxID] = self.AllBoxFreeNumList[BoxID] - 1
      if self.AllBoxFreeNumList[BoxID] < 0 then
        self.AllBoxFreeNumList[BoxID] = 0
      end
    end
    IsAddOrRemoveSuccess = true
  end
  self:DispatchEvent(PetUIModuleEvent.OnAddOrRemoveItemFromFreeList, isAdd, petData)
  self:UpdateReleaseLifeModeUI()
  return IsAddOrRemoveSuccess
end

function UMG_PetPortableBag_C:CheckIsCanFree(petData, onlyCheck, bIgnorePvpOrPveTeam, FreeReasonType)
  bIgnorePvpOrPveTeam = bIgnorePvpOrPveTeam or false
  FreeReasonType = FreeReasonType or PetUIModuleEnum.PetFreeReasonType.FreeInFreeMode
  if self.FreePetDataList and #self.FreePetDataList >= self.FreeLimitNum then
    if not onlyCheck then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\233\128\137\230\139\169\231\178\190\231\129\181\230\149\176\232\190\190\229\136\176\228\184\138\233\153\144")
    end
    return false
  end
  return _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CheckPetIsCanFree, petData, onlyCheck, bIgnorePvpOrPveTeam, self, self.ApplyFreePvpOrPvePetCallback, FreeReasonType)
end

function UMG_PetPortableBag_C:ApplyFreePvpOrPvePetCallback(FreeReasonType)
  if FreeReasonType == PetUIModuleEnum.PetFreeReasonType.FreeInFreeMode then
    if self.CurHandleFreePetData == nil then
      return
    end
    local ListSelectIndex = self.CurSelectPetIndex
    local HandleList = self.BattlePetList
    if self.CurSelectPetIndex > MAX_TEAM_PET_NUM then
      ListSelectIndex = self.CurSelectPetIndex - MAX_TEAM_PET_NUM
      HandleList = self.BagPetList
    else
      ListSelectIndex = ListSelectIndex + (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
    end
    local item = HandleList:GetItemByIndex(ListSelectIndex - 1)
    if item and item.uiData and item.uiData.gid and item.uiData.gid == self.CurHandleFreePetData.gid then
      item:OnItemClickInReleaseLifeMode(true)
    end
  elseif FreeReasonType == PetUIModuleEnum.PetFreeReasonType.DragToFree then
    self:DragToFree(self.CurHandleFreePetData.gid, true)
  end
end

function UMG_PetPortableBag_C:CheckIsInFreeList(petData)
  return self.FreeListFastLookupMap[petData.gid] ~= nil
end

function UMG_PetPortableBag_C:UpdateAllBoxFreeNumList()
  self.AllBoxFreeNumList = {}
  local boxInfos = self:GetPetBoxDatas()
  for i, v in pairs(boxInfos) do
    self.AllBoxFreeNumList[i] = 0
    if v and v.petBoxInfo and v.petBoxInfo.pet_gid then
      for j, petGID in pairs(v.petBoxInfo.pet_gid) do
        local TempPetData = {gid = petGID}
        if self:CheckIsInFreeList(TempPetData) then
          self.AllBoxFreeNumList[i] = self.AllBoxFreeNumList[i] + 1
        end
      end
    end
  end
  self:DispatchEvent(PetUIModuleEvent.OnAllBoxFreeNumListUpdate)
end

function UMG_PetPortableBag_C:OnPetBoxUpdate()
  self:UpdateAllBoxFreeNumList()
end

function UMG_PetPortableBag_C:GetBoxFreePetNum(box_id)
  local RetNum = 0
  if self.AllBoxFreeNumList and self.AllBoxFreeNumList[box_id] then
    RetNum = self.AllBoxFreeNumList[box_id]
  end
  return RetNum
end

function UMG_PetPortableBag_C:OnFreeBtnClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_FREE, true)
  if isBan then
    return
  end
  if not self.FreePetDataList then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetPortableBag_C:OnFreeBtnClick")
  if 1 == #self.FreePetDataList then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBackpackPetFreePanel, self.FreePetDataList)
  elseif #self.FreePetDataList > 1 then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetFreePanel, self.FreePetDataList)
  end
end

function UMG_PetPortableBag_C:DragToFree(gid, bIgnorePvpOrPveTeam)
  bIgnorePvpOrPveTeam = bIgnorePvpOrPveTeam or false
  if gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
    if petData then
      self:InitOrResetFreeData()
      if self:AddOrRemoveItemFromFreeList(petData, true, bIgnorePvpOrPveTeam, PetUIModuleEnum.PetFreeReasonType.DragToFree) then
        self:OnFreeBtnClick()
      end
    end
  end
end

function UMG_PetPortableBag_C:OnPetFreeFailed()
  self:InitOrResetFreeData()
  self:UpdateViewAfterFreePet()
end

function UMG_PetPortableBag_C:OnPetFreeSuccess()
  self:InitOrResetFreeData()
  self:UpdateViewAfterFreePet()
end

function UMG_PetPortableBag_C:OnPetFreeCancel()
  if not self.isReleaseLifeMode then
    self:InitOrResetFreeData()
  end
  local BagPetListNum = self.BagPetList:GetItemCount()
  for i = 0, BagPetListNum - 1 do
    local item = self.BagPetList:GetItemByIndex(i)
    if item then
      item:UpdateUIInReleaseLifeMode()
    end
  end
  local BattlePetListNum = self.BattlePetList:GetItemCount()
  for i = 0, BattlePetListNum - 1 do
    local item = self.BattlePetList:GetItemByIndex(i - 1)
    if item then
      item:UpdateUIInReleaseLifeMode()
    end
  end
end

function UMG_PetPortableBag_C:UpdateViewAfterFreePet()
  self:SetIsCanHandleFreeListInReleaseLifeMode(false)
  local isFiltering, filterList = self:GetCachePetListInfo()
  if not isFiltering then
    self:JumpToTargetBoxOrPage(self.SelectBoxIndex)
  end
  self:UpdateReleaseLifeModeUI()
  self:SetIsCanHandleFreeListInReleaseLifeMode(true)
end

function UMG_PetPortableBag_C:UpdateFilterPageText()
  self.BoxText_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if 0 == self.CurAllPetPageMax then
    self.BoxText_1:SetText(LuaText.filter_result_zero_page)
  else
    self.BoxText_2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BoxText_2:SetText(LuaText.filter_result_zero_page)
    self.BoxText_1:SetText(string.format("%s/%s", self.CurAllPetPage, self.CurAllPetPageMax))
  end
end

function UMG_PetPortableBag_C:ShowPetTeamListView()
  self:SetTeamInfo()
  self:SetCurTeamPetList(self.TeamIndex)
  local LeftPanelSelectPetData = self.module:GetCurrPetData()
  for index, petInfo in pairs(self.battlePetInfos or {}) do
    if petInfo.petData and petInfo.petData.gid == LeftPanelSelectPetData.gid then
      break
    end
  end
end

function UMG_PetPortableBag_C:SetTeamInfo()
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  self.curTeamInfo = teamInfo
  self.TeamIndex = self.TeamIndex or teamInfo.main_team_idx and teamInfo.main_team_idx + 1 or 1
  self.Dot_List:InitGridView(self.curTeamInfo.teams)
  local TotalNum = #teamInfo.teams * MAX_TEAM_PET_NUM
  local curPage
  if self.curTeamIndex then
    curPage = self.curTeamIndex - 1
  end
  self.ScrollPageController:SetValidItemTotalNum(TotalNum, curPage)
end

function UMG_PetPortableBag_C:SetCurTeamPetList(teamIndex, autoSelectPet)
  local bForceNotCreate = false
  if self.curTeamIndex and self.curTeamIndex == teamIndex then
    bForceNotCreate = true
  end
  self.curTeamIndex = teamIndex
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurShowTeamIndexInPortableBag, self.curTeamIndex)
  self.battlePetInfos = {}
  if self.curTeamInfo.teams[teamIndex] == nil then
    return
  end
  local selectTeam = self.curTeamInfo.teams[teamIndex]
  for index = 1, #self.curTeamInfo.teams do
    for i = 1, MAX_TEAM_PET_NUM do
      table.insert(self.battlePetInfos, {
        petInfo = {},
        parent = self
      })
    end
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo(index - 1)
    for i, pet_data in ipairs(battlePetList) do
      local petInfo = {
        gid = pet_data.gid,
        base_conf_id = pet_data.base_conf_id,
        showPetHp = true,
        IsAllUpdate = true,
        level = pet_data.level,
        petData = pet_data,
        indexBase = 0
      }
      local realIndex = i + (index - 1) * MAX_TEAM_PET_NUM
      self.battlePetInfos[realIndex].petInfo = petInfo
    end
  end
  self.BattlePetList:InitList(self.battlePetInfos, bForceNotCreate)
  if not bForceNotCreate then
    self.ScrollPageController:ScrollToPage(self.curTeamIndex - 1, 0.01, false)
  end
  self.Dot_List:SelectItemByIndex(teamIndex - 1)
  if not self.IsInitTeam then
    self.IsInitTeam = true
    return
  end
  if self.TeamIndex ~= teamIndex or autoSelectPet then
  end
end

function UMG_PetPortableBag_C:ShowPetBoxListView()
  Log.Debug("UMG_PetPortableBag_C:ShowPetBoxListView")
  local toFilter, cacheInfos = self:GetCachePetListInfo()
  if toFilter then
    self:OnFilter(cacheInfos)
  else
    local boxId, petIdx, SelectPetGID, bSelectTeamPet = self:GetDefaultSelectIndex()
    if not boxId and not petIdx then
      Log.Debug("UMG_PetPortableBag_C:ShowPetBoxListView \230\178\161\230\156\137\232\183\179\232\189\172\230\149\176\230\141\174")
      self.LastOpenBoxId = self.module:GetLastOpenBoxId()
      self:SetCurBoxInfo(self.LastOpenBoxId)
    else
      Log.Debug("UMG_PetPortableBag_C:ShowPetBoxListView \230\156\137\229\164\150\233\131\168\232\183\179\232\189\172\230\149\176\230\141\174")
      self.LastOpenBoxId = boxId
      if nil ~= boxId and nil ~= petIdx and nil ~= SelectPetGID and nil ~= bSelectTeamPet then
        Log.Debug("UMG_PetPortableBag_C:ShowPetBoxListView boxId=[", boxId, "], petIdx=[", petIdx, "], SelectPetGID=[", SelectPetGID, "], bSelectTeamPet=[", bSelectTeamPet, "]")
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetCurSelectInfoInPortableBag, boxId, petIdx + 1)
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetCurSelectItemTypeInPortableBag, bSelectTeamPet and PetUIModuleEnum.PortableBagSelectItemType.TeamItem or PetUIModuleEnum.PortableBagSelectItemType.PageItem)
      end
      self:JumpToTargetBoxOrPage(boxId, false)
    end
  end
end

function UMG_PetPortableBag_C:GetCachePetListInfo()
  if self.CacheFilterData == nil then
    self.CacheFilterData = self.module:GetCachePetBoxFilterData()
  end
  local isCondition = self.module:IsFilteringCondition(self.CacheFilterData.Condition)
  local filterList = self.CacheFilterData and self.CacheFilterData.FinalFilterList or {}
  return isCondition, filterList
end

function UMG_PetPortableBag_C:UpdatePetBoxList(list, select_idx)
  local cacheFilterData = self.module:GetCachePetBoxFilterData()
  local bFiltering = self.module:IsFilteringCondition(cacheFilterData.Condition)
  local bForceNotCreate = self.bInitBagPet and not bFiltering
  self.CurBackpackPetList = list
  self.BagPetList:InitList(list, bForceNotCreate)
  self.bInitBagPet = true
  if select_idx then
    self.BagPetList:SelectItemByIndex(select_idx)
  end
end

function UMG_PetPortableBag_C:SetCurBoxInfo(box_id, select_idx)
  local needToPlayRefreshAnim = box_id and box_id ~= self.curBoxID
  self.curBoxID = box_id
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurShowPageIndexInPortableBag, box_id)
  local curBoxData, idx = self:GetPetBoxDataById(box_id)
  self.SelectBoxData = curBoxData
  self.SelectBoxIndex = idx
  local backpackPetList = _G.DataModelMgr.PlayerDataModel:GetPetWarehouseBoxPetDatas(box_id)
  local backpackPetInfos = self:CreatePetDataInfos(backpackPetList, needToPlayRefreshAnim)
  self:UpdatePetBoxList(backpackPetInfos, select_idx)
  self:OnChangeBoxPageButton()
end

function UMG_PetPortableBag_C:SeAllPetInfo()
  local allPets = self.module:GetAllPetDatasWithoutBigWorldTeam()
  local allData = self:CreatePetDataInfos(allPets)
  return allData
end

function UMG_PetPortableBag_C:CreatePetDataInfos(petDatas, needToPlayRefreshAnim)
  local backpackPetInfos = {}
  for i = 1, #petDatas do
    local pet_data = petDatas[i]
    if next(pet_data) == nil then
      table.insert(backpackPetInfos, {
        petInfo = {},
        parent = self,
        needToPlayRefreshAnim = needToPlayRefreshAnim
      })
    else
      local IsTravel = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetPetIsTravel, pet_data.gid)
      local IsInHome = false
      if pet_data.business_identity and pet_data.business_identity == _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_PET then
        IsInHome = true
      end
      local IsInGuard = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePlantGuardPetGid) == pet_data.gid
      local IsConfigBanFree = PetUtils.CheckIsBanFreePet(pet_data)
      local IsInFreeList = self:CheckIsInFreeList(pet_data)
      table.insert(backpackPetInfos, {
        petInfo = {
          gid = pet_data.gid,
          base_conf_id = pet_data.base_conf_id,
          showPetHp = true,
          IsAllUpdate = true,
          IsTravel = IsTravel,
          IsInHome = IsInHome,
          IsConfigBanFree = IsConfigBanFree,
          IsInGuard = IsInGuard,
          IsInFreeList = IsInFreeList,
          sortNum = self:GetSortPriority(IsTravel, IsInHome, IsInGuard),
          level = pet_data.level,
          petData = pet_data,
          indexBase = MAX_TEAM_PET_NUM
        },
        parent = self,
        needToPlayRefreshAnim = needToPlayRefreshAnim
      })
    end
  end
  return backpackPetInfos
end

function UMG_PetPortableBag_C:GetSortPriority(IsInTravel, IsInHome, IsInGuard)
  if IsInTravel then
    return 1
  elseif IsInGuard then
    return 2
  elseif IsInHome then
    return 3
  else
    return 0
  end
end

function UMG_PetPortableBag_C:SortFilterPetList(petList)
end

function UMG_PetPortableBag_C:OnChangeBoxPageButton()
  local boxData = self.SelectBoxData
  if nil == boxData or nil == boxData.petBoxInfo then
    return
  end
  local boxInfo = boxData.petBoxInfo
  local mark_type = boxInfo and boxInfo.mark_type or _G.Enum.WarehouseMarkType.WMT_DEFAULT
  local warehouseConf = _G.DataConfigManager:GetPetWarehouseConf(boxData.id)
  local collectConf
  local confs = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetAllWarehousCollectMarkConfigs)
  for _, conf in pairs(confs) do
    if conf.mark_type == mark_type then
      collectConf = conf
      break
    end
  end
  if nil ~= collectConf then
    self:SetBoxName(boxInfo.box_name or warehouseConf.warehouse_default_name)
    self.MarkIcon:SetPath(boxData.isLock and collectConf.locked_mark_icon or collectConf.mark_small_flat_icon)
  end
  self.QuantityText:SetText(boxInfo.box_id)
  if boxInfo and boxInfo.lock then
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetPortableBag_C:IsHasBoxPanel()
  return self.module:HasPanel("NewPetBagBox")
end

function UMG_PetPortableBag_C:JumpToTargetBoxOrPage(BoxIndex, IsNeedAutoSelect)
  if nil == IsNeedAutoSelect then
    IsNeedAutoSelect = true
  end
  self:SetIsCanHandleFreeListInReleaseLifeMode(false)
  self:UpdateBigWorldTeamDataAndUI()
  local cacheFilterData = self.module:GetCachePetBoxFilterData()
  local IsFilteringCondition = self.module:IsFilteringCondition(cacheFilterData.Condition)
  local filterList = cacheFilterData.FinalFilterList
  if filterList and IsFilteringCondition then
    self.CurAllPetPage = BoxIndex
    if self.CurAllPetPage > self.CurAllPetPageMax then
      self.CurAllPetPage = 1
    elseif self.CurAllPetPage < 1 then
      self.CurAllPetPage = self.CurAllPetPageMax
    end
    local lst = table.move(filterList, (self.CurAllPetPage - 1) * PER_PETBOX_MAX_SIZE + 1, self.CurAllPetPage * PER_PETBOX_MAX_SIZE, 1, {})
    local datas = self:CreatePetDataInfos(lst)
    self.NRCSwitcher_1:SetActiveWidgetIndex(0 == #datas and 1 or 0)
    self.LeftArrowBtn.btnLevelUp:SetIsEnabled(0 ~= #datas)
    self.RightArrowBtn.btnLevelUp:SetIsEnabled(0 ~= #datas)
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurShowPageIndexInPortableBag, self.CurAllPetPage)
    self:UpdatePetBoxList(datas)
    self:UpdateFilterPageText()
  else
    local realSelectBoxIndex = BoxIndex
    local boxInfos = self:GetPetBoxDatas()
    local maxPage = 0
    for i, boxInfo in ipairs(boxInfos) do
      if boxInfo.isLock == false then
        maxPage = maxPage + 1
      end
    end
    if BoxIndex > maxPage then
      realSelectBoxIndex = 1
    elseif BoxIndex <= 0 then
      realSelectBoxIndex = maxPage
    end
    if self:IsHasBoxPanel() then
      self:DispatchEvent(PetUIModuleEvent.OnChageSelectPetBagBoxItem, realSelectBoxIndex - 1)
    end
    self:OnUpdateBoxInfo(boxInfos[realSelectBoxIndex], realSelectBoxIndex)
  end
  self:SetIsCanHandleFreeListInReleaseLifeMode(false)
  if IsNeedAutoSelect then
    self:UpdateAutoSelect()
  end
  self:SetIsCanHandleFreeListInReleaseLifeMode(true)
end

function UMG_PetPortableBag_C:GetPetBoxDatas()
  local boxInfos = self.module:GetPetBoxDatas()
  return boxInfos
end

function UMG_PetPortableBag_C:GetPetBoxDataById(box_id)
  local boxInfos = self:GetPetBoxDatas()
  for i, boxInfo in ipairs(boxInfos) do
    if boxInfo.id == box_id then
      return boxInfo, i
    end
  end
  return nil, 1
end

function UMG_PetPortableBag_C:OnUpdatePetItemClickIndex(index)
  Log.Debug("UMG_PetPortableBag_C:OnUpdatePetItemClickIndex index=[", index or 0, "]")
  if index > MAX_TEAM_PET_NUM then
    return
  end
  self.CurBattleTeamPetIndex = index - 1
  local OriginalSelectItemIndex = self.CurBattleTeamPetIndex + (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
  Log.Debug("UMG_PetPortableBag_C:OnUpdatePetItemClickIndex OriginalSelectItemIndex=[", OriginalSelectItemIndex or 0, "]")
  self.BattlePetList:SelectItemByIndex(OriginalSelectItemIndex)
end

function UMG_PetPortableBag_C:OnPetBagSelectByGid(gid)
  local boxId, idx = self:GetBoxPetIndex(gid)
  Log.Error("\233\128\137\228\184\173gid", gid, boxId, idx)
end

function UMG_PetPortableBag_C:OnUpdateBoxInfo(boxData, index)
  self:SetIsCanHandleFreeListInReleaseLifeMode(false)
  if boxData then
    self:SetCurBoxInfo(boxData.id)
    self.module:SetLastOpenBoxId(boxData.id)
    self.LastOpenBoxId = boxData.id
  end
  self.SelectBoxIndex = index
  self:SetIsCanHandleFreeListInReleaseLifeMode(true)
end

function UMG_PetPortableBag_C:OnLeavePetBoxFilter()
  self.isShowFilterPanel = false
  self.CacheFilterData = self.module:GetCachePetBoxFilterData()
  if not self.module:IsFilteringCondition(self.CacheFilterData.Condition) then
  end
  self:OnSwitchDefaultMode()
  self:UpdateBottomPanel()
  local isCondition = self.module:IsFilteringCondition(self.CacheFilterData.Condition)
  if isCondition then
    self.ScreenBtn:SetPath(UEPath.Box_Screen_1, UEPath.Box_Screen_1, UEPath.Box_Screen_1)
  else
    self.ScreenBtn:SetPath(UEPath.Box_Screen_2, UEPath.Box_Screen_2, UEPath.Box_Screen_2)
  end
  local isFiltering, filterList = self:GetCachePetListInfo()
  if isFiltering and 0 == #filterList then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
  end
end

function UMG_PetPortableBag_C:OnRefreshNewPetBagFilter()
  self.bInitBagPet = false
  self:SetIsCanHandleFreeListInReleaseLifeMode(false)
  self.LastOpenBoxId = self.module:GetLastOpenBoxId()
  self:SetCurBoxInfo(self.LastOpenBoxId)
  self:SetIsCanHandleFreeListInReleaseLifeMode(true)
end

function UMG_PetPortableBag_C:OnFilter(_, isProactiveUpdate)
  if isProactiveUpdate then
    self:ClearSelection()
  end
  if self.module:HasPanel("PetSkillTips") then
    return
  end
  local cacheFilterData = self.module:GetCachePetBoxFilterData()
  if cacheFilterData and cacheFilterData.Condition and cacheFilterData.Condition.FilterTraceBackCondition and #cacheFilterData.Condition.FilterTraceBackCondition > 0 and not PetUtils.CheckCurIsInTraceBackTime() then
    local newFilterCondition = table.copy(cacheFilterData.Condition)
    newFilterCondition.FilterTraceBackCondition = {}
    self.module:SetCachePetBoxFilterDataCondition(newFilterCondition)
    self.module:UpdateCachePetBoxFilterData(false, false)
    cacheFilterData = self.module:GetCachePetBoxFilterData()
  end
  local filterList = cacheFilterData.FinalFilterList
  local isCondition = self.module:IsFilteringCondition(cacheFilterData.Condition)
  if isCondition then
    self.ScreenBtn:SetPath(UEPath.Box_Screen_1, UEPath.Box_Screen_1, UEPath.Box_Screen_1)
  else
    self.ScreenBtn:SetPath(UEPath.Box_Screen_2, UEPath.Box_Screen_2, UEPath.Box_Screen_2)
  end
  self.CurAllPetPageMax = math.floor(#filterList / PER_PETBOX_MAX_SIZE)
  if #filterList % PER_PETBOX_MAX_SIZE > 0 then
    self.CurAllPetPageMax = self.CurAllPetPageMax + 1
  end
  if not self.module:IsFilteringCondition(cacheFilterData.Condition) then
    self:OnRefreshNewPetBagFilter()
    self.module:InitCachePetBoxFilterData()
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
    self.module:SetCachePetBoxFilterData(cacheFilterData)
    self.LeftArrowBtn.btnLevelUp:SetIsEnabled(true)
    self.RightArrowBtn.btnLevelUp:SetIsEnabled(true)
    self:UpdateFilterPageText()
    return
  end
  self.module:SetCachePetBoxFilterData(cacheFilterData)
  if not self:GetKeepSelectCurPet() then
    local IsNeedAutoSelect = not isProactiveUpdate
    self:JumpToTargetBoxOrPage(self.CurAllPetPage, IsNeedAutoSelect)
  else
    local CurSelectPetGID = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCurSelectPetGIDInPortableBag)
    local CurSelectItemType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCurSelectItemTypeInPortableBag)
    local TargetJumpPage = self.CurAllPetPage
    local IsFindSuccess = false
    if CurSelectItemType and CurSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem then
      for i, petData in pairs(cacheFilterData.FinalFilterList or {}) do
        if petData and petData.gid and CurSelectPetGID and petData.gid == CurSelectPetGID then
          local Index = i % PER_PETBOX_MAX_SIZE
          if 0 == i % PER_PETBOX_MAX_SIZE then
            TargetJumpPage = math.floor(i / PER_PETBOX_MAX_SIZE)
            Index = PER_PETBOX_MAX_SIZE
          else
            TargetJumpPage = math.floor(i / PER_PETBOX_MAX_SIZE) + 1
          end
          _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetCurSelectInfoInPortableBag, TargetJumpPage, Index)
          IsFindSuccess = true
          break
        end
      end
    end
    if not IsFindSuccess then
      self:ClearSelection()
    end
    self:JumpToTargetBoxOrPage(TargetJumpPage, false)
  end
  self:OnSwitchFilterMode()
end

function UMG_PetPortableBag_C:UpdateAutoSelect()
  local IsSelectItemHasValidPet = false
  local IsFiltering, FilterList = self:GetCachePetListInfo()
  local LastSelectItemType = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurSelectItemTypeInPortableBag)
  local LastSelectListIndex, LastSelectItemIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurSelectInfoInPortableBag)
  local LastSelectPetGID = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurSelectPetGIDInPortableBag)
  local LastSelectPetData
  if nil == LastSelectListIndex or nil == LastSelectItemIndex then
    return
  end
  if LastSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.TeamItem then
    if self.curTeamInfo and self.curTeamInfo.teams and self.curTeamInfo.teams[LastSelectListIndex] and self.curTeamInfo.teams[LastSelectListIndex].pet_infos and self.curTeamInfo.teams[LastSelectListIndex].pet_infos[LastSelectItemIndex] then
      local CurSelectPetGID = self.curTeamInfo.teams[LastSelectListIndex].pet_infos[LastSelectItemIndex].pet_gid
      if CurSelectPetGID then
        LastSelectPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(LastSelectPetGID)
      end
    end
  elseif LastSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem then
    if IsFiltering then
      local CurShowPageIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurShowPageIndexInPortableBag)
      if FilterList then
        if LastSelectPetGID then
          LastSelectPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(LastSelectPetGID)
        else
          local SelectIndex = (LastSelectListIndex - 1) * PER_PETBOX_MAX_SIZE + LastSelectItemIndex
          if FilterList[SelectIndex] then
            LastSelectPetData = FilterList[SelectIndex]
          end
        end
      end
    else
      local SelectBoxList = _G.DataModelMgr.PlayerDataModel:GetPetWarehouseBoxPetDatas(LastSelectListIndex)
      if SelectBoxList and SelectBoxList[LastSelectItemIndex] and next(SelectBoxList[LastSelectItemIndex]) then
        LastSelectPetData = SelectBoxList[LastSelectItemIndex]
      end
    end
  end
  if nil ~= LastSelectPetData and nil ~= LastSelectPetData.gid and not PetUtils.CheckIsForbidSelectPetInFreeMode(LastSelectPetData.gid, false) then
    IsSelectItemHasValidPet = true
  end
  if not IsSelectItemHasValidPet and nil ~= LastSelectPetGID then
    if LastSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.TeamItem then
      local IsCurTeamHasPet = false
      local teamPetNum = MAX_TEAM_PET_NUM * self.curTeamIndex
      for i = teamPetNum, 1, -1 do
        local item = self.BattlePetList:GetItemByIndex(i - 1)
        if item and item.hasPet and not item:IsRawGrayInFreeMode(false) then
          IsCurTeamHasPet = true
          self.BattlePetList:SelectItemByIndex(i - 1)
          break
        end
      end
      if not IsCurTeamHasPet then
        local selectIndex = (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
        self.BattlePetList:SelectItemByIndex(selectIndex)
      end
    elseif LastSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem then
      if IsFiltering then
        if #FilterList > 0 then
          local CurShowPageIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurShowPageIndexInPortableBag)
          if LastSelectListIndex == CurShowPageIndex then
            local IsSelectSuccess = false
            for i = LastSelectItemIndex, 1, -1 do
              local item = self.BagPetList:GetItemByIndex(i - 1)
              if item and item.hasPet and not item:IsRawGrayInFreeMode(false) then
                self.BagPetList:SelectItemByIndex(i - 1)
                IsSelectSuccess = true
                break
              end
            end
            if not IsSelectSuccess then
              for i = 1, PER_PETBOX_MAX_SIZE do
                local item = self.BagPetList:GetItemByIndex(i - 1)
                if item and item.hasPet and not item:IsRawGrayInFreeMode(false) then
                  self.BagPetList:SelectItemByIndex(i - 1)
                  IsSelectSuccess = true
                  break
                end
              end
              if not IsSelectSuccess then
                self:ClearSelection()
              end
            end
          else
            local LastSelectItemPetData
            local SelectIndex = (LastSelectListIndex - 1) * PER_PETBOX_MAX_SIZE + LastSelectItemIndex
            if FilterList[SelectIndex] then
              LastSelectItemPetData = FilterList[SelectIndex]
            end
            if LastSelectItemPetData and not PetUtils.CheckIsForbidSelectPetInFreeMode(LastSelectItemPetData.gid, false) then
              _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, LastSelectItemPetData.gid)
              local TempPetInfo = {
                petData = LastSelectItemPetData,
                gid = LastSelectItemPetData.gid,
                base_conf_id = LastSelectItemPetData.base_conf_id
              }
              _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, LastSelectItemIndex + 6, TempPetInfo, true, false)
            else
              local IsFindValidPet = false
              for i = #FilterList, 1, -1 do
                if FilterList[i] and next(FilterList[i]) and not PetUtils.CheckIsForbidSelectPetInFreeMode(FilterList[i].gid, false) then
                  local TargetSelectPetGid = FilterList[i].gid
                  local TargetSelectListIndex = math.floor(i / PER_PETBOX_MAX_SIZE) + 1
                  local TargetSelectItemIndex = i % PER_PETBOX_MAX_SIZE
                  if 0 == TargetSelectItemIndex then
                    TargetSelectListIndex = math.floor(i / PER_PETBOX_MAX_SIZE)
                    TargetSelectItemIndex = PER_PETBOX_MAX_SIZE
                  end
                  if TargetSelectListIndex == CurShowPageIndex then
                    self.BagPetList:SelectItemByIndex(TargetSelectItemIndex - 1)
                  else
                    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, TargetSelectPetGid)
                    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetCurSelectInfoInPortableBag, TargetSelectListIndex, TargetSelectItemIndex)
                    local TempPetInfo = {
                      petData = FilterList[i],
                      gid = FilterList[i].gid,
                      base_conf_id = FilterList[i].base_conf_id
                    }
                    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, TargetSelectItemIndex + 6, TempPetInfo, true, false)
                  end
                  IsFindValidPet = true
                  break
                end
              end
              if not IsFindValidPet then
                self:ClearSelection()
              end
            end
          end
        else
          self:ClearSelection()
        end
      else
        local CurShowPageIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurShowPageIndexInPortableBag)
        if LastSelectListIndex ~= CurShowPageIndex then
          _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, nil)
          _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, nil, nil, true, false)
        else
          Log.Error("UMG_PetPortableBag_C:UpdateAutoSelect, Not FilterList, LastSelectListIndex == CurShowPageIndex, CurShowPageIndex=[", CurShowPageIndex, "]")
        end
      end
    end
  end
end

function UMG_PetPortableBag_C:SelectTeamItemByIndex(index)
  self.BattlePetList:SelectItemByIndex(index - 1)
end

function UMG_PetPortableBag_C:SelectBagItemByIndex(index)
  self.BagPetList:SelectItemByIndex(index - 1)
end

function UMG_PetPortableBag_C:ClearSelection()
  self.BattlePetList:ClearSelection()
  self.BagPetList:ClearSelection()
  local NeedAudio = false
  local NotNeddUpdatePetMiddlePanel = false
  self:ClearSelectData()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, nil, nil, NeedAudio, NotNeddUpdatePetMiddlePanel)
  self.CurSelectPetGid = nil
end

function UMG_PetPortableBag_C:ClearSelectData()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectItemTypeInPortableBag, PetUIModuleEnum.PortableBagSelectItemType.None)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, nil)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectInfoInPortableBag, nil, nil)
end

function UMG_PetPortableBag_C:FoldRightPanel()
  if self.module:HasPanel("PetRightPanel") then
    local rightPanel = self.module:GetPanel("PetRightPanel")
    rightPanel:ClosePanel()
    self.CacheRightOpenState = true
  end
end

function UMG_PetPortableBag_C:PetTeamChanage()
end

function UMG_PetPortableBag_C:OnShowPetEvo(bShow, bAnim)
  self:PlayAnimation(bShow and self.Evo_Out or self.Evo_In)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false)
  self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, bShow and 2 or 3)
end

function UMG_PetPortableBag_C:OnUpdateEvoPetModel(itemDatas)
  if UE4.UObject.IsValid(self.CurSelectItem) then
    for i, data in pairs(itemDatas) do
      if data.type == _G.Enum.GoodsType.GT_PET then
        local petData = data.pet_data
        self.CurSelectItem:UpdatePetData(petData)
        break
      end
    end
  end
end

function UMG_PetPortableBag_C:OnUpdatePetName(rsp)
  if rsp.ret_info == nil or nil == rsp.ret_info.goods_change_info then
    return
  end
  local petData = rsp.ret_info.goods_change_info.changes[1].pet_data
  if UE4.UObject.IsValid(self.CurSelectItem) then
    self.CurSelectItem:UpdatePetData(petData)
  end
end

function UMG_PetPortableBag_C:OnUpdatePetLevel(itemDatas)
  if UE4.UObject.IsValid(self.CurSelectItem) then
    for i, data in pairs(itemDatas) do
      if data.type == _G.Enum.GoodsType.GT_PET then
        local petData = data.pet_data
        self.CurSelectItem:UpdatePetData(petData)
        break
      end
    end
  end
end

function UMG_PetPortableBag_C:OnUpdatePetCollect(mark)
  if UE4.UObject.IsValid(self.CurSelectItem) and self.CurSelectItem.uiData.petData then
    local petData = {}
    petData = self.CurSelectItem.uiData.petData
    petData.partner_mark = mark
    self.CurSelectItem:UpdatePetData(petData)
    if self.isReleaseLifeMode and mark ~= _G.Enum.PetPartnerMarkType.PPMT_NONE then
      self:AddOrRemoveItemFromFreeList(self.CurSelectItem.uiData.petData, false)
      self.CurSelectItem:UpdateUIInReleaseLifeMode()
    end
  end
end

function UMG_PetPortableBag_C:AttributeChangeSetEggBtn(showing)
  self.lastClickTime = UE4.UNRCStatics.GetMilliSeconds()
  self.CacheRightOpenState = showing
  self:UpdateEmptyView()
end

function UMG_PetPortableBag_C:OnNewPetBagRightPanelClose(panelName)
  if "NewPetBagBox" == panelName and self.module:HasPanel("NewPetBagWarehouseScreening") then
    return
  end
  if "NewPetBagWarehouseScreening" == panelName and self.module:HasPanel("NewPetBagBox") and self.module:GetNewPetBagBoxPanelOpenState() then
    return
  end
  if self.CacheRightOpenState then
    self.CacheRightOpenState = false
    self.module:FoldOrOpenRightPanel()
  end
end

function UMG_PetPortableBag_C:OnOpenDetailPanel(isOpenDetailedInfoPanel)
  self:PlayAnimation(isOpenDetailedInfoPanel and self.Evo_In or self.Evo_Out)
end

function UMG_PetPortableBag_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetBox")
end

function UMG_PetPortableBag_C:OnPageChangeHandle(_page)
  self.TeamIndex = _page + 1
  if self.TeamIndex > #self.curTeamInfo.teams then
    self.TeamIndex = 1
  end
  if self.TeamIndex < self.curTeamIndex then
    if self.OnGuidanceScrollUp then
      self.OnGuidanceScrollUp:Invoke(self)
    end
  elseif self.TeamIndex > self.curTeamIndex and self.OnGuidanceScrollDown then
    self.OnGuidanceScrollDown:Invoke(self)
  end
  self.curTeamIndex = self.TeamIndex
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurShowTeamIndexInPortableBag, self.curTeamIndex)
  self:SetIsCanHandleFreeListInReleaseLifeMode(false)
  local Start = (self.TeamIndex - 1) * MAX_TEAM_PET_NUM + 1
  local End = Start + 5
  for i = Start, End do
    local item = self.BattlePetList:GetItemByIndex(i - 1)
    if item then
      item:InitSelectItem()
    end
  end
  self:SetIsCanHandleFreeListInReleaseLifeMode(true)
  self.Dot_List:SelectItemByIndex(self.TeamIndex - 1)
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_PetPortableBag_C:OnPageChangeHandle")
end

function UMG_PetPortableBag_C:OnClickSwitchTeamBtn()
  self.TeamIndex = self.TeamIndex + 1
  if self.TeamIndex > #self.curTeamInfo.teams then
    self.TeamIndex = 1
  end
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_PetPortableBag_C:OnClickSwitchTeamBtn")
  if self:IsHaveTeamPage() then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, self.TeamIndex - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
  else
    self:SetCurTeamPetList(self.TeamIndex, true)
  end
end

function UMG_PetPortableBag_C:IsHaveTeamPage()
  self:SetTeamInfo()
  if self.curTeamInfo.teams and #self.curTeamInfo.teams >= self.TeamIndex and self.curTeamInfo.teams[self.TeamIndex].pet_infos and #self.curTeamInfo.teams[self.TeamIndex].pet_infos > 0 then
    for i, v in pairs(self.curTeamInfo.teams[self.TeamIndex].pet_infos) do
      if v.pet_gid and v.pet_gid > 0 then
        return true
      end
    end
  end
  return false
end

function UMG_PetPortableBag_C:SetValidTeamIndex()
  self:SetTeamInfo()
  if self:IsHaveTeamPage() then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, self.TeamIndex - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
  elseif self.curTeamInfo.teams and #self.curTeamInfo.teams > 0 then
    local validIndexes = {}
    for index, team in pairs(self.curTeamInfo.teams) do
      if team and team.pet_infos then
        for _, v in pairs(team.pet_infos) do
          if v.pet_gid and v.pet_gid > 0 and index ~= self.TeamIndex then
            table.insert(validIndexes, index)
          end
        end
      end
    end
    if #validIndexes > 0 then
      local closestIndex
      local smallerIndexes = {}
      local largerIndexes = {}
      for _, index in ipairs(validIndexes) do
        if index < self.TeamIndex then
          table.insert(smallerIndexes, index)
        elseif index > self.TeamIndex then
          table.insert(largerIndexes, index)
        end
      end
      if #smallerIndexes > 0 then
        closestIndex = smallerIndexes[1]
        for _, index in ipairs(smallerIndexes) do
          if index > closestIndex then
            closestIndex = index
          end
        end
      elseif #largerIndexes > 0 then
        closestIndex = largerIndexes[1]
        for _, index in ipairs(largerIndexes) do
          if index < closestIndex then
            closestIndex = index
          end
        end
      end
      if closestIndex then
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, closestIndex - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
      end
    end
  end
end

function UMG_PetPortableBag_C:OnClickEditBoxBtn()
  if self:CheckIsSelectBtn() then
    return false
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").SUBPANEL
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  if self.lastClickTime and UE4.UNRCStatics.GetMilliSeconds() - self.lastClickTime < 600 then
    return
  end
  if self.module:HasPanel("NewPetBagBox") and self.module:GetNewPetBagBoxPanelOpenState() then
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PetPortableBag_C:OnClickEditBoxBtn")
    self.module:CloseNewPetBagBoxPanel()
  else
    self:SetIsCanHandleFreeListInReleaseLifeMode(false)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenNewPetBagBoxPanel)
    self:SetIsCanHandleFreeListInReleaseLifeMode(true)
  end
  self.lastClickTime = UE4.UNRCStatics.GetMilliSeconds()
end

function UMG_PetPortableBag_C:OnPressedEditBoxBtn()
  self:PlayAnimation(self.Press)
end

function UMG_PetPortableBag_C:OnReleasedEditBoxBtn()
  self:PlayAnimation(self.Up)
end

function UMG_PetPortableBag_C:OnClickScreenBtn()
  if self.module:HasPanel("NewPetBagWarehouseScreening") then
    return
  end
  if self:CheckIsSelectBtn() then
    return false
  end
  if self.lastClickTime and UE4.UNRCStatics.GetMilliSeconds() - self.lastClickTime < 600 then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").SUBPANEL
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  self.isShowFilterPanel = true
  self.module:OnSavePetBagChildrenPanelState("Screening", true)
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetPortableBag_C:OnClickScreenBtn")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenNewPetBagWarehouseScreeningPanel)
  self.module:CloseNewPetBagBoxPanel()
  self:UpdateBottomPanel()
  self.lastClickTime = UE4.UNRCStatics.GetMilliSeconds()
end

function UMG_PetPortableBag_C:OnClickLeftArrowBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetPortableBag_C:OnClickLeftArrowBtn")
  if not self.CanScroll then
    return
  end
  local isFiltering, filterList = self:GetCachePetListInfo()
  self:JumpToTargetBoxOrPage(isFiltering and self.CurAllPetPage - 1 or self.SelectBoxIndex - 1)
end

function UMG_PetPortableBag_C:OnClickRightArrowBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetPortableBag_C:OnClickRightArrowBtn")
  if not self.CanScroll then
    return
  end
  local isFiltering, filterList = self:GetCachePetListInfo()
  self:JumpToTargetBoxOrPage(isFiltering and self.CurAllPetPage + 1 or self.SelectBoxIndex + 1)
end

function UMG_PetPortableBag_C:OnPetBoxMarkChange(box_id, mark_type, box_name, lock)
  if self.SelectBoxData and self.SelectBoxData.id == box_id then
    self.SelectBoxData.mark_type = mark_type
    if box_name and "" ~= box_name then
      self.SelectBoxData.box_name = box_name
      self:SetBoxName(box_name)
    end
    self.SelectBoxData.lock = lock
    if self.SelectBoxData.lock then
      self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local confs = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetAllWarehousCollectMarkConfigs)
    for _, conf in pairs(confs or {}) do
      if conf.mark_type == mark_type then
        if conf and conf.mark_small_flat_icon then
          self.MarkIcon:SetPath(conf.mark_small_flat_icon)
        end
        break
      end
    end
  end
end

function UMG_PetPortableBag_C:SetBoxName(boxName)
  local newName = string.ExtraLongAndOmittedWithWidth(boxName, self.maxNameLength)
  self.BoxText:SetText(newName)
end

function UMG_PetPortableBag_C:OnPcClose()
  if self.readyToClose then
    return
  end
  self.readyToClose = true
  if not self.module:GetOpenPetAttribute() then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetRightPanelPcClose)
    self.readyToClose = false
    return
  end
  if self:IsReleaseLifeMode() then
    self:OnNewPetBagExitFree()
    self.readyToClose = false
    return
  end
  self:SetPetListPanelCanScroll(true)
  self:ClosePanel()
end

function UMG_PetPortableBag_C:ClosePanel()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").CLOSE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetInfoMain").LEFTPANELOPEN
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetInfoMain", touchReasonType1)
  self:SetValidTeamIndex()
  self:SetPetListPanelCanScroll(true)
  self:OnNewPetBagExitFree()
  self:PlayAnimation(self.Out)
  self:ClearSelectData()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_PetPortableBag_C:ClosePanel")
  if self.module:HasPanel("PetInfoMain") then
    local petInfoMain = self.module:GetPanel("PetInfoMain")
    local petleftPanel = petInfoMain.petLeftPanel
    if petleftPanel then
      petleftPanel:IsShowTitle(true)
    end
  end
  if self.module:HasPanel("NewPetBagBox") then
    self.module:ClosePanel("NewPetBagBox")
  end
end

function UMG_PetPortableBag_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self.isReleaseLifeMode = false
    NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, false)
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").CLOSE
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
    self:OnClose()
  elseif Anim == self.switch_2 then
    self:StopAnimation(self.put_in)
    self:PlayAnimation(self.put_Out)
    if self.CanScroll then
      self.DragArea:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif Anim == self.switch_1 then
    self:SetFreeAreaPos()
  elseif Anim == self.In then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").OPEN
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  end
end

function UMG_PetPortableBag_C:ChangeChoosePet(index, petInfo)
  self.currentPetInfo = petInfo
  self.currentPetPos = index
  self:UpdateEmptyView()
end

function UMG_PetPortableBag_C:OnEnterBoxEditState(bEnter)
  if bEnter then
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ScreenBtnMask:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ReleaseLifeBtnMask:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.QuickSelectionBtn:GetVisibility() == UE4.ESlateVisibility.Visible then
      self.QuickSelectionBtnMask:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.SwitchBtn.btnLevelUp:SetIsEnabled(false)
    self.ReleaseLifeSwitcher:SetActiveWidgetIndex(1)
    self.LockImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.LeftArrowBtn.btnLevelUp:SetIsEnabled(false)
    self.RightArrowBtn.btnLevelUp:SetIsEnabled(false)
  else
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.LockImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:UpdateBottomPanel()
  end
  self:OnItemEnterLockState(bEnter)
end

function UMG_PetPortableBag_C:OnItemEnterLockState(bEnter)
  for i = 0, #self.battlePetInfos - 1 do
    local item = self.BattlePetList:GetItemByIndex(i)
    if item then
      item:EnterDisableDragState(bEnter)
    end
  end
  for i = 0, #self.CurBackpackPetList - 1 do
    local item = self.BagPetList:GetItemByIndex(i)
    if item then
      item:EnterDisableDragState(bEnter)
    end
  end
end

function UMG_PetPortableBag_C:SetPetListPanelCanScroll(CanScroll, ItemUiData, ItemIndex)
  if CanScroll then
    self:SetDragItemTemp(nil)
  end
  if self.CanScroll == CanScroll then
    return
  end
  self.CanScroll = CanScroll
  if CanScroll then
    self:OnDragEnd()
  else
    self:OnDragStart(ItemUiData, ItemIndex)
  end
end

function UMG_PetPortableBag_C:OnDragStart(ItemUiData, ItemIndex)
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetPortableBag_C:OnDragStart")
  self.PetBagDragList:SetInfo(self.BagPetList:GetItemSize(), self.BagPetList:GetScrollOffset())
  self.PetBagDragList.IsLongPress = true
  self.ScrollPageController.IsLongPress = true
  self.ScrollPageController:SetCanScroll(false)
  self.DragData = ItemUiData
  self.dragPetInfo = ItemUiData
  self.dragPetPos = ItemIndex + 1
  self.dragTickTime = 0
  self.SwitchBtn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.ClickImage:SetVisibility(UE4.ESlateVisibility.Visible)
  self.DragArea:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.BagPetList:EndInertialScrolling()
  self.BagPetList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.BagPetList:ForceLayoutPrepass()
  self:ShowExchangeIcon(true)
  self:OnInitDragItem()
  self:CheckBoxPanel(true)
  if self.DragEndDelayHandle then
    self:CancelDelayByID(self.DragEndDelayHandle)
    self.DragEndDelayHandle = nil
  end
  self:StopAnimation(self.switch_1)
  self:StopAnimation(self.switch_2)
  self:PlayAnimation(self.switch_1)
end

function UMG_PetPortableBag_C:OnDragEnd()
  _G.NRCAudioManager:PlaySound2DAuto(40002005, "UMG_PetPortableBag_C:OnDragEnd")
  if self.DragEndDelayHandle then
    self:CancelDelayByID(self.DragEndDelayHandle)
    self.DragEndDelayHandle = nil
  end
  self.DragEndDelayHandle = self:DelayFrames(5, function()
    self:StopAnimation(self.switch_1)
    self:StopAnimation(self.switch_2)
    self:PlayAnimation(self.switch_2)
  end)
  self.BagPetList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.BagPetList:ForceLayoutPrepass()
  self.ScrollPageController:SetCanScroll(true)
  self.SwitchBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ClickImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SortedOut:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:TryDisableDragItem()
  self:CancelExchangeOperation()
  self:SetFreeAreaPos(true)
end

function UMG_PetPortableBag_C:OnExchangeOperationEnd()
  for i = 0, #self.battlePetInfos - 1 do
    local item = self.BattlePetList:GetItemByIndex(i)
    if item then
      item.clickable = true
      item:SwitchToNormalMode()
      item.IsToChange = false
    end
  end
  self.module:SetRightPanelMarkBtnVisible(false)
  if self.CurBackpackPetList and #self.CurBackpackPetList > 0 then
    for i = 0, #self.CurBackpackPetList - 1 do
      local item = self.BagPetList:GetItemByIndex(i)
      if item then
        if item.isEmptyItem then
          item.clickable = false
        else
          item.clickable = true
        end
        item:SwitchToNormalMode()
        item.preparedForChange = false
      end
    end
  end
  self:ShowExchangeIcon(false)
  if not self.selectTargetPetInfo and self.RemovePet and self.currentPetPos and self.currentPetInfo then
    local teamIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerBattleTeamIndexByGid(self.currentPetInfo.gid)
    if teamIndex then
      self.BattlePetList:SelectItemByIndex(self.currentPetPos - 1)
    else
      self.BagPetList:SelectItemByIndex(self.currentPetPos - MAX_TEAM_PET_NUM - 1)
    end
  end
  self:CheckBoxPanel(false)
  self.dragPetInfo = nil
  self.exchangeTargetPetInfo = nil
  self.DragData = nil
  self.dragPetPos = nil
  self.RemovePet = false
  self.selectTargetPetInfo = nil
  self.PetBagDragList.IsLongPress = false
  self.ScrollPageController.IsLongPress = false
  self.dragTickTime = nil
end

function UMG_PetPortableBag_C:ShowExchangeIcon(_bShow)
  if _bShow then
    self.bDragTeamPet = false
  end
  local bDragSpecialPet = false
  if self.dragPetInfo then
    local petData = self.dragPetInfo.petInfo
    if petData then
      if _bShow then
        local teamIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerBattleTeamIndexByGid(petData.gid)
        if teamIndex then
          self.bDragTeamPet = true
        end
      end
      bDragSpecialPet = self:CheckIsSpecialPet(self.dragPetInfo.petInfo.gid)
    end
  end
  local isFiltering, _ = self:GetCachePetListInfo()
  for i = 0, #self.battlePetInfos - 1 do
    local item = self.BattlePetList:GetItemByIndex(i)
    if item then
      item:ShowExchangeIcon(_bShow, self.bDragTeamPet, bDragSpecialPet)
    end
  end
  for i = 0, #self.CurBackpackPetList - 1 do
    local item = self.BagPetList:GetItemByIndex(i)
    if item then
      item:ShowExchangeIcon(_bShow, isFiltering, self.bDragTeamPet)
    end
  end
end

function UMG_PetPortableBag_C:TryDisableDragItem()
  self.DragItemInstance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.startPos = UE4.FVector2D(0, 0)
end

function UMG_PetPortableBag_C:CancelExchangeOperation()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_PetPortableBag_C:CancelExchangeOperation")
  if self.RemovePet then
    return
  end
  self:OnExchangeOperationEnd()
end

function UMG_PetPortableBag_C:GetPetTeamIndexOrBoxID(pet_gid)
  if pet_gid and 0 ~= pet_gid then
    local teamIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerBattleTeamIndexByGid(pet_gid)
    if teamIndex then
      return teamIndex, true, nil
    else
      local boxID, pos = self:GetBoxPetIndex(pet_gid)
      pos = pos and pos + 1
      return boxID, false, pos
    end
  end
  return nil, nil, nil
end

function UMG_PetPortableBag_C:OnDragSelectItem(ItemUiData, IsTeam, ItemIndex)
  if self.DragData and not self.CanScroll then
    self:ExchangePetPos(ItemUiData, IsTeam, ItemIndex)
  end
end

function UMG_PetPortableBag_C:ExchangePetPos(PetData, IsTeam, ItemIndex)
  if nil == PetData or nil == self.dragPetInfo then
    return
  end
  self.RemovePet = true
  self.exchangeTargetPetInfo = PetData
  local exchangePetGid = 0
  if self.exchangeTargetPetInfo.gid and self.exchangeTargetPetInfo.gid ~= "IsNil" then
    exchangePetGid = self.exchangeTargetPetInfo.gid
  end
  local dragPetGid = self.dragPetInfo.petInfo.gid
  if exchangePetGid and dragPetGid and exchangePetGid == dragPetGid then
    self.RemovePet = false
    self:OnExchangeOperationEnd()
    return
  elseif not exchangePetGid and not dragPetGid then
    self.RemovePet = false
    self:OnExchangeOperationEnd()
    return
  end
  if dragPetGid and exchangePetGid then
    local dragPetIndex, dragPetIsInTeam = self:GetPetTeamIndexOrBoxID(dragPetGid)
    local exchangePetIndex, exchangePetIsInTeam, exchangePetPos = self:GetPetTeamIndexOrBoxID(exchangePetGid)
    if not exchangePetPos then
      if IsTeam then
        exchangePetPos = ItemIndex + 1 - (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
      else
        exchangePetPos = ItemIndex + 1
      end
    end
    if 0 == exchangePetGid then
      exchangePetIsInTeam = IsTeam
      if IsTeam then
        exchangePetIndex = self.curTeamIndex
        exchangePetPos = self:GetFirstBattlePetListEmptyPos()
      else
        exchangePetIndex = self.curBoxID
      end
    end
    if not self:CheckCanExchange(dragPetGid, exchangePetGid, dragPetIsInTeam, exchangePetIsInTeam) then
      self.RemovePet = false
      self:OnExchangeOperationEnd()
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_pet_cannot_exchange)
      return
    end
    if dragPetIndex and exchangePetIndex then
      if not dragPetIsInTeam then
        local _, petPos = self:GetBoxPetIndex(dragPetGid)
        self.dragPetPos = petPos + 1
      else
        self.dragPetPos = self.dragPetPos - (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
      end
      local ori_info = {
        pet_gid = dragPetGid,
        is_in_team = dragPetIsInTeam,
        id = dragPetIndex,
        pos = self.dragPetPos
      }
      local tar_info = {
        pet_gid = exchangePetGid,
        is_in_team = exchangePetIsInTeam,
        id = exchangePetIndex,
        pos = exchangePetPos
      }
      self.selectTargetPetInfo = table.deepCopy(tar_info)
      if ori_info.is_in_team and tar_info.is_in_team and 0 == tar_info.pet_gid then
        self.selectTargetPetInfo.pos = self.selectTargetPetInfo.pos - 1
      end
      if tar_info then
        local targetItem
        if tar_info.is_in_team then
          local realTeamIndex = (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM + exchangePetPos
          targetItem = self.BattlePetList:GetItemByIndex(realTeamIndex - 1)
        else
          if self.PetBagDragList.OnMouseButtonReleased then
            self.PetBagDragList:OnMouseButtonReleased()
          end
          targetItem = self.BagPetList:GetItemByIndex(exchangePetPos - 1)
        end
        if targetItem and UE4.UObject.IsValid(targetItem) and targetItem.OnMouseButtonReleased then
          targetItem:OnMouseButtonReleased()
        end
      end
      self.CurSelectPetGid = nil
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxChangePetReq, ori_info, tar_info)
      return
    end
  end
  self.RemovePet = false
  self:OnExchangeOperationEnd()
end

function UMG_PetPortableBag_C:CheckCanExchange(dragPetGid, exchangeTargetPetGid, isDragPetInTeam, isExchangePetInTeam)
  if 0 ~= dragPetGid then
    local isDragPetSpecial = self:CheckIsSpecialPet(dragPetGid)
    if isDragPetSpecial and isExchangePetInTeam then
      return false
    elseif 0 ~= exchangeTargetPetGid then
      local isTargetPetSpecial, _ = self:CheckIsSpecialPet(exchangeTargetPetGid)
      if isDragPetInTeam and isTargetPetSpecial then
        return false
      end
    end
  else
    return false
  end
  return true
end

function UMG_PetPortableBag_C:CheckIsSpecialPet(petGid)
  local IsInHome = false
  local IsInGuard = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePlantGuardPetGid) == petGid
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if petData and petData.business_identity then
    IsInHome = petData.business_identity == _G.ProtoEnum.PetBusinessIdentity.PBI_HOME_PET
  end
  return IsInHome or IsInGuard
end

function UMG_PetPortableBag_C:GetFirstBattlePetListEmptyPos()
  if self.battlePetInfos then
    local startIndex = (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM + 1
    local endIndex = (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM + MAX_TEAM_PET_NUM
    for i, pet in pairs(self.battlePetInfos) do
      if i >= startIndex and i <= endIndex and pet and pet.petInfo and not pet.petInfo.gid then
        local index = i - (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
        return index
      end
    end
  end
  return 1
end

function UMG_PetPortableBag_C:DragPetToBox(box_id, pos)
  if self.dragPetInfo and self.dragPetInfo.petInfo and box_id and pos then
    local dragPetGid = self.dragPetInfo.petInfo.gid
    if dragPetGid then
      local dragPetIndex, dragPetIsInTeam = self:GetPetTeamIndexOrBoxID(dragPetGid)
      if dragPetIndex ~= box_id or dragPetIsInTeam then
        if dragPetIsInTeam then
          self.dragPetPos = self.dragPetPos - (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
        end
        local ori_info = {
          pet_gid = dragPetGid,
          is_in_team = dragPetIsInTeam,
          id = dragPetIndex,
          pos = self.dragPetPos
        }
        local tar_info = {
          pet_gid = 0,
          is_in_team = false,
          id = box_id,
          pos = pos
        }
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxChangePetReq, ori_info, tar_info)
      end
    end
  end
end

function UMG_PetPortableBag_C:OnPetBoxChangeNotify()
  if self.DelayPetBoxChangeID then
    self:CancelDelayByID(self.DelayPetBoxChangeID)
    self.DelayPetBoxChangeID = nil
  end
  self.DelayPetBoxChangeID = self:DelayFrames(1, function()
    local CacheFilterData = self.module:GetCachePetBoxFilterData()
    if not self.module:IsFilteringCondition(CacheFilterData.Condition) and self.curBoxID then
      self:SetCurBoxInfo(self.curBoxID)
    end
    if self.selectTargetPetInfo and not self.selectTargetPetInfo.is_in_team then
      local isFiltering, _ = self:GetCachePetListInfo()
      if isFiltering and self.dragPetInfo and self.dragPetInfo.petInfo then
        local gid = self.dragPetInfo.petInfo.gid
        if gid then
          self:DelayFrames(10, function()
            local bSelected = false
            for i = 1, self.BagPetList:GetItemCount() do
              local item = self.BagPetList:GetItemByIndex(i - 1)
              if item and item.uiData.gid == gid then
                bSelected = true
                self.BagPetList:SelectItemByIndex(i - 1)
                break
              end
            end
            if not bSelected and self.BagPetList:GetItemCount() > 0 then
              self.BagPetList:SelectItemByIndex(0)
            end
          end)
        end
      else
        self.BagPetList:SelectItemByIndex(self.selectTargetPetInfo.pos - 1)
      end
      self:OnExchangeOperationEnd()
    end
  end)
end

function UMG_PetPortableBag_C:OnPlayerDataUpdate(UpdateGoodType, PetDataChangeItemList)
  if UpdateGoodType and (UpdateGoodType == _G.Enum.VisualItem.VI_DIAMOND or UpdateGoodType == _G.Enum.VisualItem.VI_COUPON or UpdateGoodType == _G.Enum.VisualItem.VI_COIN) then
    return
  end
  local CacheFilterData = self.module:GetCachePetBoxFilterData()
  if self.module:IsFilteringCondition(CacheFilterData.Condition) and UpdateGoodType == _G.Enum.GoodsType.GT_PET then
    local bTargetPetDataChange = false
    local ChangePetGID
    if PetDataChangeItemList and 1 == #PetDataChangeItemList and PetDataChangeItemList[1] and PetDataChangeItemList[1].PetDataUpdateReasonType and (PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.LevelUp or PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.Evolve or PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.GrowUp or PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.BreakThrough or PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.TalentChange) then
      bTargetPetDataChange = true
      ChangePetGID = PetDataChangeItemList[1].PetGID
    end
    if bTargetPetDataChange then
      local CurSelectPetGID = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCurSelectPetGIDInPortableBag)
      local CurSelectItemType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCurSelectItemTypeInPortableBag)
      if ChangePetGID and CurSelectPetGID and CurSelectItemType and ChangePetGID == CurSelectPetGID and CurSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem then
        self:SetKeepSelectCurPet(true)
      end
    end
    if self:GetIsNeedUpdateCachePetBoxFilterData() then
      self.module:UpdateCachePetBoxFilterData(true, false)
    end
    if self:GetKeepSelectCurPet() then
      self:SetKeepSelectCurPet(false)
    end
  end
  if PetDataChangeItemList and 1 == #PetDataChangeItemList and PetDataChangeItemList[1] and PetDataChangeItemList[1].PetDataUpdateReasonType and PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.TraceBack then
    return
  end
  if PetDataChangeItemList then
    for i = 1, #PetDataChangeItemList do
      local changeInfo = PetDataChangeItemList[i]
      if UE4.UObject.IsValid(self.CurSelectItem) and self.CurSelectItem.uiData and changeInfo.PetGID == self.CurSelectItem.uiData.gid then
        local changePetdata = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(changeInfo.PetGID)
        self.CurSelectItem:UpdatePetData(changePetdata)
        self:DispatchEvent(PetUIModuleEvent.OnUpdatePetImage3dData, changePetdata)
        break
      end
    end
  end
  if PetDataChangeItemList and #PetDataChangeItemList > 0 and self.TeamIndex then
    self:SetCurTeamPetList(self.TeamIndex, true)
  end
end

function UMG_PetPortableBag_C:GetIsNeedUpdateCachePetBoxFilterData()
  local bNeedUpdate = true
  if self.module:OnCmdCheckIsOpenEvoPanel() then
    bNeedUpdate = false
  end
  return bNeedUpdate
end

function UMG_PetPortableBag_C:SetKeepSelectCurPet(Flag)
  self.KeepSelectCurPet = Flag
end

function UMG_PetPortableBag_C:GetKeepSelectCurPet()
  return self.KeepSelectCurPet
end

function UMG_PetPortableBag_C:OnBigWorldTeamPetChangeEvent()
  if self.DelayPetBattleChangeID then
    self:CancelDelayByID(self.DelayPetBattleChangeID)
    self.DelayPetBattleChangeID = nil
  end
  self:ClearSelectData()
  self.DelayPetBattleChangeID = self:DelayFrames(1, function()
    self:SetValidTeamIndex()
    if self.curTeamIndex then
      self:SetCurTeamPetList(self.curTeamIndex)
    end
    if self.selectTargetPetInfo and self.selectTargetPetInfo.is_in_team then
      local selectItemIndex = self.selectTargetPetInfo.pos - 1 + (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
      self.BattlePetList:SelectItemByIndex(selectItemIndex)
      self:OnExchangeOperationEnd()
    end
  end)
end

function UMG_PetPortableBag_C:OnInitDragItem()
  if not self.DragItemInstance and self.startPos then
    self.DragItemInstance = UE4.UWidgetBlueprintLibrary.Create(_G.UE4Helper.GetCurrentWorld(), self.DragItem)
    if self.DragItemInstance then
      self.DragItemInstance:AddToViewport(_G.UILayerCtrlCenter.ENUM_LAYER.TOP_MSG, false)
      self.DragItemInstance:SetAlignmentInViewport(UE4.FVector2D(0.5, 0.5))
      self:ShowDragItemStartPos()
    end
  elseif self.DragItemInstance then
    self:ShowDragItemStartPos()
  end
end

function UMG_PetPortableBag_C:ShowDragItemStartPos()
  if self.DragItemInstance then
    local viewportPos = UIUtils.ScreenPositionToViewport(self.startPos)
    self.DragItemInstance:SetPositionInViewport(viewportPos, false)
  end
  if self.DragData then
    self.DragItemInstance:AsDragItemInitInfo(self.DragData)
  end
  self.DragItemInstance:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_PetPortableBag_C:OnRocoTouchMoveHandler(touchIndex, position)
  if self.dragItemTemp and self.bCheckDragItem and self.touchStartTime then
    local currentTime = UE4.UNRCStatics.GetMilliSeconds()
    local interval = currentTime - self.touchStartTime
    if interval > self.minInterval then
      local bDrag = false
      local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
      if scale > 0 then
        local pressMoveOffsetX = 0
        local pressMoveOffsetY = 0
        pressMoveOffsetX = math.abs(position.X - self.startPos.X) / scale
        pressMoveOffsetY = math.abs(position.Y - self.startPos.Y) / scale
        local dis = math.sqrt(pressMoveOffsetX * pressMoveOffsetX + pressMoveOffsetY * pressMoveOffsetY)
        if dis > self.minDis then
          bDrag = true
          self.dragItemTemp:LongPress()
          self.bCheckDragItem = false
          if self.touchDelayHandle then
            self:CancelDelayByID(self.touchDelayHandle)
            self.touchDelayHandle = nil
          end
          if self.touchDelayPCHandle then
            self:CancelDelayByID(self.touchDelayPCHandle)
            self.touchDelayPCHandle = nil
          end
        end
      end
      self.touchStartTime = nil
    end
  end
  if self.CanScroll then
    return
  end
  local viewportPos = UIUtils.ScreenPositionToViewport(position)
  self.DragItemInstance:SetPositionInViewport(viewportPos, false)
  self:DealWithCheckArea()
end

function UMG_PetPortableBag_C:SetDragItemTemp(dragItem)
  if dragItem then
    if dragItem and dragItem.uiData and dragItem.uiData.gid then
      self.ScrollPageController:SetCanScroll(false)
      self.dragItemTemp = dragItem
      self.bCheckDragItem = true
      self.BagPetList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  else
    if self.dragItemTemp and self.bCheckDragItem then
      self.dragItemTemp:OnTouchEnded()
    end
    self.dragItemTemp = nil
    self.bCheckDragItem = false
    self.BagPetList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetPortableBag_C:OnLongPress()
  if self.touchDelayPCHandle then
    self:CancelDelayByID(self.touchDelayPCHandle)
    self.touchDelayPCHandle = nil
  end
  if self:CheckIsDrag() then
    self:OnRealLongPress()
  elseif self.pcExtraPressTime then
    self.touchDelayPCHandle = self:DelaySeconds(self.pcExtraPressTime, self.OnRealLongPress, self)
  else
    self:OnRealLongPress()
  end
end

function UMG_PetPortableBag_C:CheckIsDrag()
  if RocoEnv.PLATFORM_WINDOWS then
    local currentPos = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld())
    if currentPos and self.touchStartMousePos and self.pcMinDis and math.abs(currentPos.x - self.touchStartMousePos.x) < self.pcMinDis and math.abs(currentPos.y - self.touchStartMousePos.y) < self.pcMinDis then
      return false
    end
  end
  return true
end

function UMG_PetPortableBag_C:OnRealLongPress()
  if self.dragItemTemp then
    self.dragItemTemp:LongPress()
    self.touchStartTime = nil
    self.bCheckDragItem = false
  end
end

function UMG_PetPortableBag_C:OnRocoTouchStartHandler(touchIndex, position)
  self.startPos.X = position.X
  self.startPos.Y = position.Y
  self.touchStartTime = UE4.UNRCStatics.GetMilliSeconds()
  if RocoEnv.PLATFORM_WINDOWS then
    self.touchStartMousePos = UE4.UWidgetLayoutLibrary.GetMousePositionOnViewport(_G.UE4Helper.GetCurrentWorld())
  end
  self.touchDelayHandle = self:DelaySeconds(self.LongPressTime, self.OnLongPress, self)
end

function UMG_PetPortableBag_C:OnRocoTouchEndHandler(touchIndex)
  self.ScrollPageController:SetCanScroll(true)
  self.touchStartTime = nil
  self.touchStartMousePos = nil
  if self.touchDelayHandle then
    self:CancelDelayByID(self.touchDelayHandle)
    self.touchDelayHandle = nil
  end
  if self.touchDelayPCHandle then
    self:CancelDelayByID(self.touchDelayPCHandle)
    self.touchDelayPCHandle = nil
  end
  if self.CurrentGuide and self.CurrentGuide:IsCompleteWithButtonReleased() then
    Log.Debug("UMG_PetPortableBag_C:OnRocoTouchEndHandler CurrentGuide IsCompleteWithButtonReleased")
    return
  end
  local FreePetGid = 0
  if self:CheckIsHoverFreeBtn() and self.dragPetInfo and self.dragPetInfo.petInfo and self.dragPetInfo.petInfo.gid then
    FreePetGid = self.dragPetInfo.petInfo.gid
  end
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnPetPortableBagTouchEnded)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, true)
  if 0 ~= FreePetGid then
    self:DragToFree(FreePetGid)
  end
end

function UMG_PetPortableBag_C:SetFreeAreaPos(bReset)
  if bReset then
    self.freeAreaPos = nil
  elseif UE4Helper.GetCurrentWorld() then
    local freeAreaPos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.DragArea:GetCachedGeometry(), UE4.FVector2D(0, 0))
    local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
    if freeAreaPos and scale and scale > 0 then
      self.freeAreaPos = freeAreaPos / scale
    end
  end
end

function UMG_PetPortableBag_C:DealWithCheckArea()
  local bHoverFreeBtn = self:CheckIsHoverFreeBtn()
  if bHoverFreeBtn == self.bHoverFreeBtn then
    return
  end
  self.bHoverFreeBtn = bHoverFreeBtn
  if self.bHoverFreeBtn then
    self:StopAnimation(self.put_Out)
    self:StopAnimation(self.put_in)
    self:PlayAnimation(self.put_in)
    self.DragAreaBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:StopAnimation(self.put_in)
    self:StopAnimation(self.put_Out)
    self:PlayAnimation(self.put_Out)
  end
end

function UMG_PetPortableBag_C:CheckIsHoverFreeBtn()
  if self.freeAreaPos and self.DragItemInstance then
    local screenPos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.DragItemInstance:GetCachedGeometry(), UE4.FVector2D(0, 0))
    local scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
    if screenPos and scale and scale > 0 and self.DragItemInstance:GetCachedGeometry() then
      screenPos = screenPos / scale
      local dragItemSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.DragItemInstance:GetCachedGeometry())
      local freeAreaSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.DragArea:GetCachedGeometry())
      if dragItemSize and freeAreaSize then
        local maxX = self.freeAreaPos.x + freeAreaSize.x
        local maxY = self.freeAreaPos.y + freeAreaSize.y
        local minX = self.freeAreaPos.x
        local minY = self.freeAreaPos.y
        if minX <= screenPos.x + dragItemSize.x / 2 and maxX >= screenPos.x + dragItemSize.x / 2 and minY <= screenPos.y + dragItemSize.y / 2 and maxY >= screenPos.y + dragItemSize.y / 2 then
          return true
        end
      end
    end
  end
  return false
end

function UMG_PetPortableBag_C:OnExchangePetFail()
  self:OnExchangeOperationEnd()
end

function UMG_PetPortableBag_C:IsDragPet(gid)
  if self.dragPetInfo and self.dragPetInfo.petInfo and self.dragPetInfo.petInfo.gid == gid then
    return true
  end
  return false
end

function UMG_PetPortableBag_C:IsSelectedPet(gid)
  if self.dragPetInfo and self.currentPetInfo and self.currentPetInfo.gid and self.currentPetInfo.gid == gid then
    return true
  end
  return false
end

function UMG_PetPortableBag_C:OnTick(deltaTime)
  if self.dragTickTime then
    self:SetFreeAreaPos()
    self:DealWithCheckArea()
  end
end

function UMG_PetPortableBag_C:CheckBoxPanel(bDragStart)
  if self.readyToClose then
    return
  end
  local isFiltering, _ = self:GetCachePetListInfo()
  if isFiltering then
    return
  end
  if not bDragStart then
    if self.module:HasPanel("NewPetBagBox") and self.module:GetNewPetBagBoxPanelOpenState() then
      if not self.bOpenBoxPanel then
        _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PetPortableBag_C:CheckBoxPanel")
        self.module:CloseNewPetBagBoxPanel()
      end
      self.bOpenBoxPanel = nil
    end
  elseif self.module:HasPanel("NewPetBagBox") and self.module:GetNewPetBagBoxPanelOpenState() then
    self.bOpenBoxPanel = true
  else
    self.bOpenBoxPanel = nil
    self:SetIsCanHandleFreeListInReleaseLifeMode(false)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenNewPetBagBoxPanel)
    self:SetIsCanHandleFreeListInReleaseLifeMode(true)
  end
end

function UMG_PetPortableBag_C:OnSendPetSuccess()
  self.oldIndex = self.BagPetList:GetSelectedIndex()
  self:SetCurTeamPetList(self.curTeamIndex)
  self:SetCurBoxInfo(self.curBoxID)
end

function UMG_PetPortableBag_C:SelectPetOnSendPetSuc()
  local itemCount = self.BagPetList:GetTotalItemNumber()
  for i = self.oldIndex - 1, 0, -1 do
    local pet = self.BagPetList:GetItemByIndex(i)
    if pet and not pet.IsNilPet then
      self.BagPetList:SelectItemByIndex(i)
      return
    end
  end
  for i = self.oldIndex + 1, itemCount - 1 do
    local pet = self.BagPetList:GetItemByIndex(i)
    if pet and not pet.IsNilPet then
      self.BagPetList:SelectItemByIndex(i)
      return
    end
  end
  local BattlePetCount = self.BattlePetList:GetTotalItemNumber()
  if BattlePetCount > 0 then
    local selectPetIndex = (self.curTeamIndex - 1) * MAX_TEAM_PET_NUM
    self.BattlePetList:SelectItemByIndex(selectPetIndex)
  end
end

function UMG_PetPortableBag_C:LockSwitchBtn(bLock)
  if bLock then
    local path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_Switch_Grey_png.img_Switch_Grey_png'"
    self.SwitchBtn:SetPath(path, path, path)
  else
    local path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_Switch_png.img_Switch_png'"
    self.SwitchBtn:SetPath(path, path, path)
  end
end

function UMG_PetPortableBag_C:OnMouseWheel(MyGeometry, InTouchEvent)
  if not self.CanScroll then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  if self.module:HasPanel("NewPetBagBox") then
    local bagboxPanel = self.module:GetPanel("NewPetBagBox")
    if bagboxPanel then
      local scrollView = bagboxPanel.ItemList
      if UE4.UObject.IsValid(scrollView) and scrollView:GetScrollBoxHandleScrollingState() then
        return UE4.UWidgetBlueprintLibrary.Unhandled()
      end
    end
  end
  if self.lastWheelTime and UE4.UNRCStatics.GetMilliSeconds() - self.lastWheelTime < 500 then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  self.lastWheelTime = UE4.UNRCStatics.GetMilliSeconds()
  local wheelData = UE4.UKismetInputLibrary.PointerEvent_GetWheelDelta(InTouchEvent)
  if wheelData > 0 then
    self:CancelLongPress()
    self:OnClickLeftArrowBtn()
  elseif wheelData < 0 then
    self:CancelLongPress()
    self:OnClickRightArrowBtn()
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetPortableBag_C:CancelLongPress()
  if self.touchDelayHandle then
    self:CancelDelayByID(self.touchDelayHandle)
    self.touchDelayHandle = nil
  end
  if self.touchDelayPCHandle then
    self:CancelDelayByID(self.touchDelayPCHandle)
    self.touchDelayPCHandle = nil
  end
  self:SetDragItemTemp(nil)
end

function UMG_PetPortableBag_C:OnBeginGuideTarget(config)
  self.CurrentGuide = config
  if config:IsCompleteWithButtonScroll() then
    self.ScrollPageController.LongPressDrag = false
  elseif config:IsCompleteWithButtonLongPress() or config:IsCompleteWithButtonReleased() then
    self.ScrollPageController:SetCanScroll(false)
  end
end

function UMG_PetPortableBag_C:OnEndGuideTarget(config)
  self.CurrentGuide = nil
  self.ScrollPageController.LongPressDrag = true
  self.ScrollPageController:SetCanScroll(true)
end

function UMG_PetPortableBag_C:IsShowChildrenPanel()
  return self.module:OnGetPetBagChilderenPanelState() or not self.module:GetOpenPetAttribute()
end

function UMG_PetPortableBag_C:ClearChildrenPanelState()
  self.module:ClearChildrenPanelState()
end

function UMG_PetPortableBag_C:OnNewPetBagExitScreen()
  local filterCondition = {
    FilterPetIdCondition = {},
    FilterTalentCondition = {},
    FilterDepartCondition = {},
    FilterNatureCondition = {},
    FilterAttributeCondition = {},
    FilterPetMarkCondition = {},
    FilterStrongCondition = {},
    FilterTimeCondition = {}
  }
  self.module:InitCachePetBoxFilterData()
  self.module:OnCmdFilterPetBoxData({}, filterCondition, true)
  self:OnLeavePetBoxFilter()
end

return UMG_PetPortableBag_C

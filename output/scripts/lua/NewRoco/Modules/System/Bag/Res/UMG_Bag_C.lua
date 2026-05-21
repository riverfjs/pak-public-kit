local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local StarChainEnum = require("NewRoco.Modules.System.StarChain.StarChainEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local HomeEnum = require("NewRoco/Modules/System/Home/HomeEnum")
local UMG_Bag_C = _G.NRCPanelBase:Extend("UMG_Bag_C")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_BAG
local BagTabTypeFunctionEntrance = {
  [Enum.ItemLableType.ILT_USEFUL_ITEM] = Enum.FunctionEntrance.FE_BAG_TAB_BALL,
  [Enum.ItemLableType.ILT_MATERIAL] = Enum.FunctionEntrance.FE_BAG_TAB_MATERIAL,
  [Enum.ItemLableType.ILT_PRECIOUS] = Enum.FunctionEntrance.FE_BAG_TAB_PRECIOUS,
  [Enum.ItemLableType.ILT_SKILL_MACHINE] = Enum.FunctionEntrance.FE_BAG_TAB_SKILL_MACHINE,
  [Enum.ItemLableType.ILT_TASK] = Enum.FunctionEntrance.FE_BAG_TAB_TASK,
  [Enum.ItemLableType.ILT_PET_EGG] = Enum.FunctionEntrance.FE_BAG_TAB_PET_EGG,
  [Enum.ItemLableType.ILT_PET_FRUIT] = Enum.FunctionEntrance.FE_BAG_TAB_PET_FRUIT
}

local function CheckIfBan(labelType, showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  if not isBan and labelType then
    local functionEntrance = BagTabTypeFunctionEntrance[labelType]
    if functionEntrance then
      isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, functionEntrance, showMsg)
    end
  end
  return isBan
end

function UMG_Bag_C:OnConstruct()
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BAG)
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BAG)
  local isPauseBgm = _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.IsPauseUiBgm)
  if StateGroup and not isPauseBgm then
    _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.MusicUPanelPause)
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SwapEggs_Precious:SetVisibility(UE.ESlateVisibility.Collapsed)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, false, "UMG_Bag_C")
  self.NeedAddEventListener = true
  self.NeedAddBtnListener = true
  local db = _G.DataConfigManager:GetGlobalConfigByKeyType("ui_audio_reduction_db", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  UE4.UNRCAudioManager.SetWorldListenerVolumeOffset(db)
  self.CommonPath = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/SkillBase/"
  self.IsCanClickCloseBtn = false
  self.LastItemType = nil
  self.bIsScreening = false
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:SetCommonTitle()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:BindInputAction()
  self.functionBanUIController = FunctionBanUIController()
  do
    local functionBanUIController = self.functionBanUIController
    for labelType, functionEntrance in pairs(BagTabTypeFunctionEntrance) do
      functionBanUIController:RegisterCustomCallback(functionEntrance, self.OnBagTabVisibilityChangeHandler, self, labelType)
    end
    if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
      functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnBagTabVisibilityChangeHandler, self, -1)
    end
    functionBanUIController:Activate()
  end
end

function UMG_Bag_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_BagUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseBagUI", self, "OnPcClose")
    mappingContext:BindAction("IA_CloseBagQuick", self, "OnPcClose")
  end
end

function UMG_Bag_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnCloseButtonClicked()
end

function UMG_Bag_C:SetMagicIcon()
  local hasMagic = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, Enum.BagItemType.BI_MAGIC)
  if not hasMagic then
    self:ShowMagicIcon(false)
  else
    self:ShowMagicIcon(true)
  end
end

function UMG_Bag_C:ShowMagicIcon(IsShow)
  for i = #self.TabList, 1, -1 do
    if self.TabList[i] == Enum.BagItemType.BI_MAGIC then
      if not IsShow then
        goto lbl_16
      end
      do break end
      ::lbl_16::
      table.remove(self.TabList, i)
      break
    end
  end
end

function UMG_Bag_C:SetBagCanClick(Visible)
  if not Visible then
    self.TouchBg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.TouchBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Bag_C:OnDestruct()
  self.GridView1:ClearSelection()
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BAG)
  if StateGroup then
    _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.MusicUPanelPlay)
  end
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BAG)
  if not self.module.IsPetInfoMainToPanel then
  else
    self.module.IsPetInfoMainToPanel = false
  end
  self.module.IsWaitChangeRsp = false
  self.module.PetOpenUseAction = nil
  self.data.Canfilter = true
  table.clear(self.module.CharacterPanelList)
  self.data.PetCharacterItem = nil
  self.data.PetTalentItem = nil
  self.data.PetBloodItem = nil
  self.data.curSelectedItemData = nil
  self.data:ClearPopUpPanelData()
  if self.displayMode == BagModuleEnum.DisplayMode.BattleCatch then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowOrHideBattlePopUpTips, true)
  end
  self.data:SetDisplayMode(BagModuleEnum.DisplayMode.Zone)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil ~= localPlayer and type(localPlayer) ~= "boolean" then
    localPlayer.inputComponent:SetInputEnable(self, true, "UMG_Bag_C")
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseTipsPanel)
  if self.functionBanUIController then
    self.functionBanUIController:Deactivate()
  end
  self:CancleFruitItemListTimer()
  self:CancleFruitItemTimer()
end

function UMG_Bag_C:InitBagInfo()
  if self.displayMode == BagModuleEnum.DisplayMode.BattleCatch then
    for i = #self.TabList, 2, -1 do
      table.remove(self.TabList, i)
    end
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
    for i = #self.TabList, 1, -1 do
      if 6 ~= self.TabList[i] then
        table.remove(self.TabList, i)
      end
    end
  elseif self.displayMode == BagModuleEnum.DisplayMode.PetEgg then
    for i = #self.TabList, 1, -1 do
      if 8 ~= self.TabList[i] then
        table.remove(self.TabList, i)
      end
    end
  elseif self.displayMode == BagModuleEnum.DisplayMode.PetOpenToBagByUseAction then
    for i = #self.TabList, 1, -1 do
      if 4 ~= self.TabList[i] then
        table.remove(self.TabList, i)
      end
    end
  end
  if self.data.hasEquip == true and self.data.curEquipItemData then
    self:SetCurEquipItem(self.data:GetCurEquipItem().id)
    self:SetCurEquipItemVisible(true)
  else
    self:SetCurEquipItemVisible(false)
  end
  self:BtnInit()
end

function UMG_Bag_C:OnActive(itemconf, bIsOpenByBag, TableIndex)
  self.GridView1.bShowAll = false
  self.List1.bShowAll = false
  self.bPlayOpenAnim = false
  self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HasItemSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _G.GlobalConfig.DebugOpenUI then
    self:OnAddBtnListener()
    self.IsCanClickCloseBtn = true
    self.data = self.module:GetData("BagModuleData")
    return
  end
  self.CloseBtn.NRCSwitcher_1:SetActiveWidgetIndex(1)
  self.NeeItemSelectedAudio = false
  self.data = self.module:GetData("BagModuleData")
  self.displayMode = self.data.displayMode
  self.descText = ""
  self.lastSkillId = nil
  self.data:SetIsFirstOpenPanel(true)
  self:OnAddEventListener()
  self.data:ResetFurnitureFilterTabMap()
  self.data:ResetSortRule()
  self.TabList = {
    1,
    2,
    4,
    6,
    9,
    8,
    10,
    Enum.ItemLableType.ILT_FURNITURE + 1
  }
  self:InitBagInfo()
  self.Tab:InitGridView(self.TabList)
  self.Tab:SetItemCanClickChecker(self.CheckTabCanClick, self)
  self:SetvItemNum()
  self:ShowMoneyBtn()
  if itemconf then
    if self.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
      self.SkillMachinePetData = itemconf
      self:OnSelectTabByIndex(6)
    elseif self.displayMode == BagModuleEnum.DisplayMode.PetEgg then
      self:OnSelectTabByIndex(8)
    elseif self.displayMode == BagModuleEnum.DisplayMode.PetOpenToBagByUseAction then
      self.UseActionPetData = itemconf
      self:OnSelectTabByIndex(4)
    else
      local selectItemData = self.module:OnGetBagItemByID(itemconf.id)
      if selectItemData then
        self.module:OnCmdSetSelectedItem(selectItemData, 0)
      end
      local Iconindex = itemconf.lable_type + 1
      self:OnSelectTabByIndex(Iconindex)
    end
  elseif 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(1)
  elseif 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(2)
  elseif 4 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(3)
  elseif 5 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(4)
  elseif 6 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(6)
  elseif 7 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(5)
  elseif 8 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:GetChooseItemTypeInfo(7)
  elseif self.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
    self:GetChooseItemTypeInfo(5)
  elseif self.displayMode == BagModuleEnum.DisplayMode.PetEgg then
    self:GetChooseItemTypeInfo(7)
  elseif self.displayMode == BagModuleEnum.DisplayMode.PetOpenToBagByUseAction then
    self:GetChooseItemTypeInfo(Enum.ItemLableType.ILT_PRECIOUS)
  elseif TableIndex then
    if 4 == TableIndex then
      self:OnSelectTabByIndex(6)
    elseif 5 == TableIndex then
      self:OnSelectTabByIndex(9)
    elseif 6 == TableIndex then
      self:OnSelectTabByIndex(8)
    elseif 7 == TableIndex then
      self:OnSelectTabByIndex(10)
    else
      if 3 == TableIndex then
        self:OnSelectTabByIndex(4)
      else
      end
    end
  else
    self:OnSelectTabByIndex(1)
  end
  self:OnInitScreenState()
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  local SortList = self:GetSortList()
  local DropDownListInfo = {}
  for i = 1, #SortList do
    table.insert(DropDownListInfo, {
      ComType = CommonBtnEnum.ComboBoxType.Bag,
      name = SortList[i].text,
      sortList = SortList,
      isHideRedDot = true
    })
  end
  local comboBoxText, selectIndex
  if self.data.SortIndex == _G.Enum.Sequence.SEQUENCE_DEFAULT then
    comboBoxText = SortList[1].text
    selectIndex = 1
  elseif self.data.SortIndex == _G.Enum.Sequence.SEQUENCE_QUALITY_UP or self.data.SortIndex == _G.Enum.Sequence.SEQUENCE_QUALITY_DOWN or self.data.SortIndex == _G.Enum.Sequence.SEQUENCE_QUALITY then
    comboBoxText = SortList[2].text
    selectIndex = 2
  end
  self:SetCommonComboBoxInfo(self.ComboBox, DropDownListInfo, selectIndex, comboBoxText)
  self.ComboBox:ShowOrHideBtnLeft(false, true)
  self.module:TryGetBagInfo()
  _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenBagExpiredItemsConversion)
  if not bIsOpenByBag then
    return
  end
  self.BackgroundCapture:SetVisibility(UE4.ESlateVisibility.visible)
end

function UMG_Bag_C:OnSelectTabByIndex(index)
  for i, v in pairs(self.TabList) do
    if v == index then
      self.Tab:SelectItemByIndex(i - 1)
      break
    end
  end
end

function UMG_Bag_C:OnEnable()
end

function UMG_Bag_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnPreNtfEnterScene)
  self:OnRemoveEventListener()
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  if self.data then
    self.data:ResetFurnitureFilterTabMap()
  end
  if self.DelaySortItemId then
    _G.DelayManager:CancelDelayById(self.DelaySortItemId)
    self.DelaySortItemId = nil
  end
end

function UMG_Bag_C:_OnPreNtfEnterScene()
  self.IsCanClickCloseBtn = true
  self:OnCloseButtonClicked()
end

function UMG_Bag_C:OnAddEventListener()
  if not self.NeedAddEventListener then
    return
  end
  _G.NRCEventCenter:RegisterEvent("UMG_Bag_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self.NeedAddEventListener = false
  self:RegisterEvent(self, BagModuleEvent.ChooseBagItemType, self.GetChooseItemTypeInfo)
  self:RegisterEvent(self, BagModuleEvent.SetChooseItemInfo, self.SetItemInfo)
  self:RegisterEvent(self, BagModuleEvent.SetSortType, self.SortItem)
  self:RegisterEvent(self, BagModuleEvent.RefreshBagInfo, self.RefreshBagInfo)
  self:RegisterEvent(self, BagModuleEvent.UpdateEquipState, self.RefreshEquipState)
  self:RegisterEvent(self, BagModuleEvent.ChangeTypeTab, self.LastSelecedIndex)
  self:RegisterEvent(self, BagModuleEvent.ChangeBagBackGround, self.ChangBagBG)
  self:RegisterEvent(self, BagModuleEvent.OnFinishDecomposeFurniture, self.OnFinishDecomposeFurniture)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClicked)
  self:RegisterEvent(self, BagModuleEvent.UpdateFilter, self.RefreshFilterBagInfo)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:RegisterEvent(self, HomeModuleEvent.OnEquipSeedChange, self.HandleOnEquipSeedChange)
  end
  self.NRCTextDes.OnRichTextClick:Add(self, self.OnDescTextClicked)
  _G.NRCEventCenter:RegisterEvent("BagModule", self, BagModuleEvent.UpdateSort, self.UpdateSort)
  _G.NRCEventCenter:RegisterEvent("BagModule", self, BagModuleEvent.OnFilter, self.OnFilterSkillStone)
  _G.NRCEventCenter:RegisterEvent("BagModule", self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnBattlePassInfoUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_Bag_C", self, MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo, self.UpdateBagItemNumMagicReplayVideo)
end

function UMG_Bag_C:OnUseBagItemRsp(UsedBagItemConf)
  local itemData = self.data:GetCurSelectedItemData()
  if UsedBagItemConf.id == itemData.id then
    local Cur_Use_Action = UsedBagItemConf and UsedBagItemConf.item_behavior[1] and UsedBagItemConf.item_behavior[1].use_action
    if Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetTalentList = self:GetPetCanUseTalentList(UsedBagItemConf, true)
      if PetTalentList and #PetTalentList >= 1 then
        self.List:InitGridView(PetTalentList)
      end
    end
    if Cur_Use_Action == _G.Enum.ItemBehavior.IB_IMPROVE_TALENT then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetTalentList = self:GetPetCanUseTalentList(UsedBagItemConf, true)
      if PetTalentList and #PetTalentList >= 1 then
        self.List:InitGridView(PetTalentList)
      end
    end
    if Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE or self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD or self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS or self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetBloodPulseList = self:GetPetCanUseBloodPulseList(UsedBagItemConf, true)
      if PetBloodPulseList and #PetBloodPulseList >= 1 then
        self.List:InitGridView(PetBloodPulseList)
      end
    end
    if Cur_Use_Action == _G.Enum.ItemBehavior.IB_NIGHTMARE_ELITE_RECOVERY then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local evolutionaryPetList = self:GetEvolutionaryPetShowList()
      if evolutionaryPetList and #evolutionaryPetList >= 1 then
        self.List:InitGridView(evolutionaryPetList)
      end
    end
  end
end

function UMG_Bag_C:OnPlayerDataUpdate()
  if self.MoneyBtn then
    for i = 0, self.MoneyBtn:GetItemCount() - 1 do
      local Item = self.MoneyBtn:GetItemByIndex(i)
      Item:RefreshMoneyNum()
    end
  end
  if self.data and self.data:InFurnitureDecomposeMode() then
    return
  end
  if self.SkillMachinePetData then
    local itemData = self.data:GetCurSelectedItemData()
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(itemData.id)
    self.SkillMachinePetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.SkillMachinePetData.gid)
    local petSkillLernList = self:GetPetSkillLernList(bagItemInfo)
    if petSkillLernList and #petSkillLernList >= 1 then
      self.List:InitGridView(petSkillLernList)
    end
  else
    local itemData = self.data:GetCurSelectedItemData()
    local bagItemInfo = itemData and _G.DataConfigManager:GetBagItemConf(itemData.id)
    if bagItemInfo and bagItemInfo.lable_type == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
      local petSkillLernList = self:GetPetSkillLernList(bagItemInfo)
      if petSkillLernList and #petSkillLernList >= 1 then
        self.List:Clear()
        self.List:InitGridView(petSkillLernList)
      else
        self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  if self.UseActionPetData and self.Cur_Use_Action then
    local itemData = self.data:GetCurSelectedItemData()
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(itemData.id)
    self.UseActionPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.UseActionPetData.gid)
    if self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetTalentList = self:GetPetCanUseTalentList(bagItemInfo, true)
      if PetTalentList and #PetTalentList >= 1 then
        self.List:InitGridView(PetTalentList)
      end
    end
    if self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_IMPROVE_TALENT then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetTalentList = self:GetPetCanUseTalentList(bagItemInfo, true)
      if PetTalentList and #PetTalentList >= 1 then
        self.List:InitGridView(PetTalentList)
      end
    end
    if self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE or self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD or self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS or self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetBloodPulseList = self:GetPetCanUseBloodPulseList(bagItemInfo, true)
      if PetBloodPulseList and #PetBloodPulseList >= 1 then
        self.List:InitGridView(PetBloodPulseList)
      end
    end
    if self.Cur_Use_Action == _G.Enum.ItemBehavior.IB_NIGHTMARE_ELITE_RECOVERY then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local evolutionaryPetList = self:GetEvolutionaryPetShowList()
      if evolutionaryPetList and #evolutionaryPetList >= 1 then
        self.List:InitGridView(evolutionaryPetList)
      end
    end
  end
end

function UMG_Bag_C:OnAddBtnListener()
  if not self.NeedAddBtnListener then
    return
  end
  self.NeedAddBtnListener = false
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseButtonClicked)
  if -1 == self.displayMode then
    self:AddButtonListener(self.MiddleBtn3.btnLevelUp, self.OnBtnMiddle3Clicked)
  else
    self:AddButtonListener(self.LeftBtn1.btnLevelUp, self.OnBtnLeft1Clicked)
    self:AddButtonListener(self.LeftBtn2.btnLevelUp, self.OnBtnLeft2Clicked)
    self:AddButtonListener(self.RightBtn.btnLevelUp, self.OnBtnRightClicked)
    self:AddButtonListener(self.Btn_ShutDown, self.ResetDescText)
    self:AddButtonListener(self.Btn_ShutDown_1, self.ResetDescText)
    self:AddButtonListener(self.Btn_ShutDown_2, self.ResetDescText)
    self:AddButtonListener(self.Btn_ShutDown_3, self.ResetDescText)
    self:AddButtonListener(self.Btn_ShutDown_4, self.ResetDescText)
    self:AddButtonListener(self.Btn_ShutDown_5, self.ResetDescText)
    self.MiddleBtn1.btnLevelUp.OnPressed:Add(self, self.OnBtnPressed)
    self.MiddleBtn1.btnLevelUp.OnReleased:Add(self, self.OnBtnReleasedMiddleBtn1)
    self.MiddleBtn2.btnLevelUp.OnPressed:Add(self, self.OnBtnPressed)
    self.MiddleBtn2.btnLevelUp.OnReleased:Add(self, self.OnBtnReleasedMiddleBtn2)
    self.RightBtn.btnLevelUp.OnPressed:Add(self, self.OnBtnPressed)
    self.RightBtn.btnLevelUp.OnReleased:Add(self, self.OnBtnReleased)
    self.MiddleBtn1_1.btnLevelUp.OnPressed:Add(self, self.OnBtnPressed)
    self.MiddleBtn1_1.btnLevelUp.OnReleased:Add(self, self.OnBtnReleasedMiddleBtn1_1)
  end
  self:AddButtonListener(self.DecompositionBtn.btnLevelUp, self.OnFurnitureDecompositionClick)
  local Bar = self.AddSubtract_NoProgressBar
  Bar:SetPanelInfo({
    Call = self,
    MultipleAddBtnHandler = self.OnMultipleAddFurnitureDecompose,
    MultipleSubtractBtnHandler = self.OnMultipleSubFurnitureDecompose,
    SubtractBtnHandler = self.OnSubFurnitureDecompose,
    AddBtnHandler = self.OnAddFurnitureDecompose,
    MultipleAddBtnText = "+5",
    MultipleSubtractBtnText = "-5",
    SelectNum = ""
  })
end

function UMG_Bag_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Bag_C:OnBtnPressed()
  self:StopAnimation(self.Btn_up)
  self:PlayAnimation(self.Btn_Press)
  self:ResetDescText()
end

function UMG_Bag_C:OnBtnReleased()
  self:StopAnimation(self.Btn_Press)
  self:PlayAnimation(self.Btn_up)
end

function UMG_Bag_C:OnBtnReleasedMiddleBtn1()
  self:StopAnimation(self.Btn_Press)
  self:PlayAnimation(self.Btn_up)
  self:OnBtnMiddle1Clicked()
end

function UMG_Bag_C:OnBtnReleasedMiddleBtn2()
  self:StopAnimation(self.Btn_Press)
  self:PlayAnimation(self.Btn_up)
  self:OnBtnMiddle2Clicked()
end

function UMG_Bag_C:OnBtnReleasedMiddleBtn1_1()
  self:StopAnimation(self.Btn_Press)
  self:PlayAnimation(self.Btn_up)
  self:OnBtnEggClicked()
end

function UMG_Bag_C:OnRemoveEventListener()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:UnRegisterEvent(self, BagModuleEvent.ChooseBagItemType)
  self:UnRegisterEvent(self, BagModuleEvent.SetChooseItemInfo)
  self:UnRegisterEvent(self, BagModuleEvent.SetSortType)
  self:UnRegisterEvent(self, BagModuleEvent.RefreshBagInfo)
  self:UnRegisterEvent(self, BagModuleEvent.ChangeTypeTab)
  self:UnRegisterEvent(self, BagModuleEvent.UpdateEquipState)
  self:UnRegisterEvent(self, BagModuleEvent.ChangeBagBackGround)
  self:UnRegisterEvent(self, BagModuleEvent.UpdateFilter)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEquipSeedChange)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.UpdateSort, self.UpdateSort)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnFilter, self.OnFilterSkillStone)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnBattlePassInfoUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo, self.UpdateBagItemNumMagicReplayVideo)
end

function UMG_Bag_C:SetCommonComboBoxInfo(ComboBox, DropDownListInfo, DropDownListIndex, DropDownListText, ComboBoxText, ComboBoxIcon)
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if DropDownListInfo then
    CommonDropDownListData.DropDownListInfo = DropDownListInfo
  end
  CommonDropDownListData.ComType = CommonBtnEnum.ComboBoxType.Bag
  if DropDownListIndex then
    CommonDropDownListData.DropDownListIndex = DropDownListIndex
  end
  if DropDownListText then
    CommonDropDownListData.DropDownListText = DropDownListText
  end
  if ComboBoxText then
    CommonDropDownListData.DropDownListText = ComboBoxText
  end
  if ComboBoxIcon then
    CommonDropDownListData.DropDownListIcon = ComboBoxIcon
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_LeftHandler = self.OnScreenBtn
  CommonDropDownListData.Btn_RightHandler = self.OnSequenceBtn
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_Bag_C:SetvItemNum()
  local num1 = self.data:GetvItemNum(_G.Enum.VisualItem.VI_COIN)
  local num2 = self.data:GetvItemNum(_G.Enum.VisualItem.VI_DIAMOND)
  local MoneyDatas = {
    {
      moneyType = _G.Enum.VisualItem.VI_COIN,
      sum = num1
    },
    {
      moneyType = _G.Enum.VisualItem.VI_DIAMOND,
      sum = num2
    }
  }
  self.MoneyBtn:InitGridView(MoneyDatas)
end

function UMG_Bag_C:OnScreenBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_BagIcon_Ani_4_C:OnTouchEnded")
  self:PlayAnimation(self.Click_ScreenBtn)
  local type = self.data:GetCurItemType()
  if type == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
    local bagInfoList = self.data:SortItemListByLableType(self.data:GetCurItemType(), self.data.SortIndex)
    for i = 1, #bagInfoList do
      local filterData = {}
      filterData.bagitem_id = bagInfoList[i].id
      filterData.gid = bagInfoList[i].gid
      bagInfoList[i].filterData = filterData
    end
    local condition = {}
    condition.FilterPetCondition = self.data.FilterPetCondition
    condition.FilterDepartCondition = self.data.FilterDepartCondition
    condition.FilterClassifyCondition = self.data.FilterClassifyCondition
    _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, bagInfoList, _G.DataConfigManager.ConfigTableId.SKILLMACHINE_FILTER_CONF, condition)
  end
  if type == Enum.ItemLableType.ILT_FURNITURE then
    local extraData
    local filterMode = HomeEnum.FurnitureFilterMode.Bag
    if self.data:InFurnitureDecomposeMode() then
      extraData = self.data:GetFurnitureDisplayNumInTabDecompose()
      filterMode = HomeEnum.FurnitureFilterMode.BagDecompose
    else
      extraData = self.data:GetFurnitureDisplayNumInTab()
      filterMode = HomeEnum.FurnitureFilterMode.Bag
    end
    if _G.HomeModuleCmd then
      _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenFurnitureFilterPanel, nil, filterMode, nil, extraData)
    end
  end
  self:ResetDescText()
end

function UMG_Bag_C:OnSortBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Bag_C:OnSortBtn")
  self:PlayAnimation(self.SortingBtn_Press)
  local bagItemType = self.data:GetCurItemType()
  local sortList = self.data:GetSortTypesByItemType(bagItemType)
  local list = {}
  for i = 1, #sortList do
    local sortInfo = {}
    local sortId = sortList[i]
    local name = _G.DataConfigManager:GetBagItemSequence(sortId + 1).sequence_desc
    sortInfo.text = name
    sortInfo.sequence = sortId
    table.insert(list, sortInfo)
  end
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenBagSortPanel, list, self.data.SortIndex)
  self:ResetDescText()
end

function UMG_Bag_C:GetSortList()
  local bagItemType = self.data:GetCurItemType()
  local sortList = self.data:GetSortTypesByItemType(bagItemType)
  if self.sequenceList == nil then
    self.sequenceList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BAG_ITEM_SEQUENCE):GetAllDatas()
  end
  local list = {}
  for i = 1, #sortList do
    local sortInfo = {}
    local sortId = sortList[i]
    for _, v in pairs(self.sequenceList) do
      if v.sequence == sortId then
        local name = v.sequence_desc
        sortInfo.text = name
        sortInfo.sequence = sortId
        break
      end
    end
    table.insert(list, sortInfo)
  end
  return list
end

function UMG_Bag_C:OnSequenceBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Bag_C:OnSequenceBtn")
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.ReversalBagSort)
  self:OnInitScreenState()
end

function UMG_Bag_C:OnFilterSkillStone(filterPet, condition)
  local filterPets = filterPet
  self.data:SetSkillStoneFilter(filterPets, condition)
  self:DispatchEvent(BagModuleEvent.UpdateFilter)
end

function UMG_Bag_C:OnInitScreenState()
  self:PlayAnimation(self.Click_sequencebtn)
  self:ShowSortingBtnIsReversal()
  if self.data.FilterPetCondition == nil then
    self.data.FilterPetCondition = {}
  end
  if nil == self.data.FilterDepartCondition then
    self.data.FilterDepartCondition = {}
  end
  if nil == self.data.FilterClassifyCondition then
    self.data.FilterClassifyCondition = {}
  end
  if #self.data.FilterPetCondition > 0 or #self.data.FilterDepartCondition > 0 or #self.data.FilterClassifyCondition > 0 then
    self.bIsScreening = true
    self.ComboBox.ScreeningBtn:ChangeIconSelectState(2)
  elseif not self.data:GetIsFirstOpenPanel() then
    self.bIsScreening = false
    self.ComboBox.ScreeningBtn:ChangeIconSelectState(1)
  end
  local ItemType = self.data:GetCurItemType()
  if ItemType == Enum.ItemLableType.ILT_FURNITURE then
    if self.data:HasFurnitureFilters() then
      self.ComboBox.ScreeningBtn:ChangeIconSelectState(2)
    else
      self.ComboBox.ScreeningBtn:ChangeIconSelectState(1)
    end
  end
end

function UMG_Bag_C:GetUseActionItemList()
  local ItemIdList = {}
  if self.module.PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Blood then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("normal_blood_effect_item").numList
  elseif self.module.PetOpenUseAction == BagModuleEnum.PetOpenUseAction.NightMareBlood then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("nightmare_blood_effect_item").numList
  elseif self.module.PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Talent then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("talent_effect_item").numList
  elseif self.module.PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Nature then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("nature_effect_item").numList
  end
  local ItemList = self.module:GetCanUseBagItemByItemId(ItemIdList, self.module.PetOpenUseAction)
  return ItemList
end

function UMG_Bag_C:RefreshFilterBagInfo()
  self.NeeItemSelectedAudio = false
  self.NRCImage_bigicon_Outline:SetRenderOpacity(1)
  local GridView1
  if self:IsExchangeStyle() then
    GridView1 = self.List1
  else
    GridView1 = self.GridView1
  end
  local ItemType = self.data:GetCurItemType()
  local IsFilterBag = true
  local bagTypeInfo = {}
  if self.module.PetOpenUseAction then
    bagTypeInfo = self:GetUseActionItemList()
  else
    bagTypeInfo = self.data:SortItemListByLableType(ItemType, self.data.SortIndex, IsFilterBag)
  end
  if nil == bagTypeInfo then
    bagTypeInfo = {}
  end
  local isNotLast = 0 == self.lastBagTypeInfoNum and self.lastBagTypeInfoNum == #bagTypeInfo
  GridView1:InitList(bagTypeInfo)
  self:OnInitScreenState()
  self.HasItemSwitcher:SetActiveWidgetIndex(0)
  self.BGSwitcher:SetActiveWidgetIndex(0)
  if bagTypeInfo and #bagTypeInfo > 0 then
    self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.LastItemType == ItemType then
      if 0 == self.lastBagTypeInfoNum then
        self:PlayAnimation(self.ScreenBtn_open)
      else
        self:PlayAnimation(self.Change_Icon)
      end
    else
      self:PlayAnimation(self.ScreenBtn_open)
    end
    if #bagTypeInfo > 0 and not self.data:InFurnitureDecomposeMode() then
      GridView1:SelectItemByIndex(0)
    end
    self.CloseBtn.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self:ResetDescText()
  else
    self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CloseBtn.NRCSwitcher_1:SetActiveWidgetIndex(2)
    if isNotLast and 0 == #bagTypeInfo then
      self:PlayAnimation(self.ScreenBtn_none_refresh)
    else
      self:ResetDescText()
      self:PlayAnimation(self.ScreenBtn_none)
    end
  end
  self.lastBagTypeInfoNum = #bagTypeInfo
  self.LastItemType = ItemType
  if ItemType == Enum.ItemLableType.ILT_FURNITURE then
    if self.data:InFurnitureDecomposeMode() then
      self:InternalRefreshFurnitureDecomposition()
    else
      self:RefreshDecompositionBtnVisibility()
    end
  end
end

function UMG_Bag_C:UpdateSort(index, data)
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OnSequenceSelected, index, data)
end

function UMG_Bag_C:RefreshBagInfo()
  self.NRCImage_bigicon_Outline:SetRenderOpacity(1)
  local GridView1
  if self:IsExchangeStyle() then
    GridView1 = self.List1
  else
    GridView1 = self.GridView1
  end
  local ItemType = self.data:GetCurItemType()
  local bagTypeInfo = self.data:GetBagItemByLableType(ItemType)
  if nil ~= bagTypeInfo and #bagTypeInfo > 0 then
    self.HasItemSwitcher:SetActiveWidgetIndex(0)
    self.BGSwitcher:SetActiveWidgetIndex(0)
    self:SortItem(ItemType, self.data.SortIndex)
    self:SetSortListInfo(ItemType)
  else
    self.HasItemSwitcher:SetActiveWidgetIndex(1)
    self:OnHasItemSwitcherShow()
    local type
    if ItemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
      type = Enum.BagItemType.BI_PET_BALL
    elseif ItemType == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
      type = Enum.BagItemType.BI_SKILL_MACHINE
    elseif ItemType == _G.Enum.ItemLableType.ILT_PET_EGG then
      type = Enum.BagItemType.BI_PET_EGG
    elseif ItemType == _G.Enum.ItemLableType.ILT_FURNITURE then
      type = Enum.BagItemType.BI_FURNITURE
    end
    if type then
      local BagTypeNum = self.data:GetBagItemNumInBagByType(type)
      local TypeConf = _G.DataConfigManager:GetBagItemTypeConf(type)
      if TypeConf and TypeConf.type_number_limit and 0 ~= TypeConf.type_number_limit then
        self.NRCSwitcher_26:SetActiveWidgetIndex(1)
        self.UpperLimit:InitNum(BagTypeNum, TypeConf.type_number_limit)
      else
        self.NRCSwitcher_26:SetActiveWidgetIndex(0)
      end
    else
      self.NRCSwitcher_26:SetActiveWidgetIndex(0)
    end
    self.BGSwitcher:SetActiveWidgetIndex(1)
  end
end

function UMG_Bag_C:RefreshEquipState(itemData)
  if self.data and self.data:InFurnitureDecomposeMode() then
    return
  end
  local GridView1
  if self:IsExchangeStyle() then
    GridView1 = self.List1
  else
    GridView1 = self.GridView1
  end
  local SelectedItemId = self.data:GetCurSelectedItemData().id
  local sortList = {}
  if self.module.PetOpenUseAction then
    sortList = self:GetUseActionItemList()
  else
    sortList = self.data:SortItemListByLableType(self.data:GetCurItemType(), self.data.SortIndex)
  end
  GridView1:InitList(sortList)
  for i, v in ipairs(sortList) do
    if SelectedItemId == v.id then
      GridView1:SelectItemByIndex(i - 1)
      break
    end
  end
  if self.IsUse then
    _G.NRCAudioManager:PlaySound2DAuto(1002, "OnBtnLeft2Clicked")
  else
    _G.NRCAudioManager:PlaySound2DAuto(1006, "OnBtnLeft2Clicked")
  end
end

function UMG_Bag_C:GetChooseItemTypeInfo(ItemType, bagItemConf)
  Log.Debug("[Bag] step2 UMG_Bag_C:GetChooseItemTypeInfo", ItemType, bagItemConf)
  local isBan = CheckIfBan(ItemType, false)
  self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self:ResetDescText()
  if ItemType == Enum.ItemLableType.ILT_FURNITURE then
    local MoneyDatas = {
      {
        moneyType = _G.Enum.VisualItem.VI_FURNITURE_COIN,
        sum = self.data:GetvItemNum(_G.Enum.VisualItem.VI_FURNITURE_COIN)
      }
    }
    self.MoneyBtn:InitGridView(MoneyDatas)
    if not self.data:InFurnitureDecomposeMode() then
      self:ResetFurniture()
    end
  else
    self:ResetFurniture()
    self:SetvItemNum()
  end
  self.data:SetCurItemType(ItemType)
  self.AlreadyEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self:IsExchangeStyle() then
    self.GridView1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.List1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.GridView1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.List1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local bagTypeInfo = self.data:GetBagItemByLableType(ItemType)
  self:RefreshCommonTitle(ItemType)
  self.ParticleSystemWidget2_30:SetVisibility(ItemType ~= _G.Enum.ItemLableType.ILT_SKILL_MACHINE and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if nil ~= bagTypeInfo and #bagTypeInfo > 0 then
    self.HasItemSwitcher:SetActiveWidgetIndex(0)
    self.BGSwitcher:SetActiveWidgetIndex(0)
    self:SortItem(ItemType, self.data.SortIndex, bagItemConf)
    self:SetSortListInfo(ItemType)
    if ItemType == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
      self.ComboBox:ShowOrHideBtnLeft(true)
      self.HasItemSwitcher:SetActiveWidgetIndex(0)
      self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BGSwitcher:SetActiveWidgetIndex(0)
      self.RightBtn:SetBtnText(LuaText.umg_bag_15)
      self.RightBtn:SetTitleTextAndIcon()
      self.MiddleBtn1_1:SetTitleTextAndIcon()
      self.MiddleBtn1_1:SetBtnText(LuaText.umg_bag_15)
    else
      self.ComboBox:ShowOrHideBtnLeft(false, true)
      self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if ItemType == _G.Enum.ItemLableType.ILT_PET_EGG then
        self.MiddleBtn1_1:SetBtnText(LuaText.umg_bag_14)
      end
      self.RightBtn:SetTitleTextAndIcon()
      if ItemType == _G.Enum.ItemLableType.ILT_TASK then
        self.RightBtn:SetBtnText(LuaText.umg_petbag_7)
      else
        self.RightBtn:SetBtnText(LuaText.umg_bag_13)
        local data = self.data:GetCurSelectedItemData()
        if data and data.conf then
          self:BP_SetGiftVoucherInfo(data.conf)
        end
      end
    end
    local LabelType = ItemType
    if LabelType == Enum.ItemLableType.ILT_FURNITURE then
      self.ComboBox:ShowOrHideBtnLeft(true)
      self:InternalRefreshFurnitureDecomposition(true)
    else
      self.DecompositionBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      if not self.data:GetIsFirstOpenPanel() then
        self:PlayAnimation(self.ScreenBtn_open)
      end
    end
  else
    local isSceen = #self.data.FilterPetCondition > 0 or #self.data.FilterDepartCondition > 0 or #self.data.FilterClassifyCondition > 0
    if ItemType == _G.Enum.ItemLableType.ILT_SKILL_MACHINE and isSceen or ItemType == _G.Enum.ItemLableType.ILT_FURNITURE and self.data:HasFurnitureFilters() then
      self.HasItemSwitcher:SetActiveWidgetIndex(0)
      self.BGSwitcher:SetActiveWidgetIndex(0)
      self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ComboBox:ShowOrHideBtnLeft(true)
      if not self.bAlreadyNone then
        self:PlayAnimation(self.ScreenBtn_none)
        self.bAlreadyNone = true
      elseif self.data:InFurnitureDecomposeMode() then
        self:PlayAnimation(self.ScreenBtn_none_refresh)
      end
    else
      self.HasItemSwitcher:SetActiveWidgetIndex(1)
      self:OnHasItemSwitcherShow()
      self.BGSwitcher:SetActiveWidgetIndex(1)
      self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ComboBox:ShowOrHideBtnLeft(false, true)
      self:PlayAnimation(self.ScreenBtn_open)
    end
    if ItemType == _G.Enum.ItemLableType.ILT_FURNITURE then
      self.DecompositionBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.CanvasPanel_62:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.lastBagTypeInfoNum = 0
    end
  end
  local type
  if ItemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
    type = Enum.BagItemType.BI_PET_BALL
  elseif ItemType == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
    type = Enum.BagItemType.BI_SKILL_MACHINE
  elseif ItemType == _G.Enum.ItemLableType.ILT_PET_EGG then
    type = Enum.BagItemType.BI_PET_EGG
  elseif ItemType == _G.Enum.ItemLableType.ILT_FURNITURE then
    type = Enum.BagItemType.BI_FURNITURE
  end
  if type then
    local TypeConf = _G.DataConfigManager:GetBagItemTypeConf(type)
    if TypeConf and TypeConf.type_number_limit and 0 ~= TypeConf.type_number_limit then
      self.NRCSwitcher_26:SetActiveWidgetIndex(1)
      local BagTypeNum = self.data:GetBagItemNumInBagByType(type)
      self.UpperLimit:InitNum(BagTypeNum, TypeConf.type_number_limit)
    else
      self.NRCSwitcher_26:SetActiveWidgetIndex(0)
    end
  else
    self.NRCSwitcher_26:SetActiveWidgetIndex(0)
  end
  self:SetItemTypeInfo()
  self:HandleOnEquipSeedChange()
  local SortList = self:GetSortList()
  local DropDownListInfo = {}
  for i = 1, #SortList do
    table.insert(DropDownListInfo, {
      ComType = CommonBtnEnum.ComboBoxType.Bag,
      name = SortList[i].text,
      sortList = SortList,
      isHideRedDot = true
    })
  end
  self.ComboBox:UpdateData(DropDownListInfo)
  self:ShowSortingBtnIsReversal()
end

function UMG_Bag_C:RefreshCommonTitle(ItemType)
  if self.titleConf then
    if ItemType == Enum.ItemLableType.ILT_USEFUL_ITEM then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_MATERIAL then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_PRECIOUS then
      self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_SKILL_MACHINE then
      self.Title1:SetSubtitle(self.titleConf.subtitle[6].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_PET_EGG then
      self.Title1:SetSubtitle(self.titleConf.subtitle[7].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_TASK then
      self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_PET_FRUIT then
      self.Title1:SetSubtitle(self.titleConf.subtitle[8].subtitle)
    elseif ItemType == Enum.ItemLableType.ILT_FURNITURE then
      self.Title1:SetSubtitle(self.titleConf.subtitle[9].subtitle)
    end
  end
end

function UMG_Bag_C:IsExchangeStyle()
  return false
end

function UMG_Bag_C:SetItemTypeInfo()
  local ItemType = self.data:GetCurItemType()
  self.LastItemType = ItemType
end

function UMG_Bag_C:GetPetSkillLernList(bagItemInfo)
  local petSkillLernList = {}
  petSkillLernList = _G.BagModuleUtils.GetPetSkillLearnList(bagItemInfo, self.SkillMachinePetData)
  return petSkillLernList
end

function UMG_Bag_C:GetPetCanUseTalentList(bagItemInfo, _IsNeedFail)
  local PetInfoList = {}
  if self.UseActionPetData then
    PetInfoList = {
      self.UseActionPetData
    }
  else
    PetInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  end
  local PetTalentList = {}
  if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_IMPROVE_TALENT then
    if PetInfoList and #PetInfoList >= 1 then
      for i, PetInfo in ipairs(PetInfoList) do
        local attribute_info = PetInfo.attribute_info
        if attribute_info.hp.talent_add_value and 0 ~= attribute_info.hp.talent_add_value and attribute_info.hp.talent_add_value < 10 then
          table.insert(PetTalentList, {PetInfo, 0})
        elseif attribute_info.attack.talent_add_value and 0 ~= attribute_info.attack.talent_add_value and attribute_info.attack.talent_add_value < 10 then
          table.insert(PetTalentList, {PetInfo, 0})
        elseif attribute_info.special_attack.talent_add_value and 0 ~= attribute_info.special_attack.talent_add_value and attribute_info.special_attack.talent_add_value < 10 then
          table.insert(PetTalentList, {PetInfo, 0})
        elseif attribute_info.defense.talent_add_value and 0 ~= attribute_info.defense.talent_add_value and attribute_info.defense.talent_add_value < 10 then
          table.insert(PetTalentList, {PetInfo, 0})
        elseif attribute_info.special_defense.talent_add_value and 0 ~= attribute_info.special_defense.talent_add_value and attribute_info.special_defense.talent_add_value < 10 then
          table.insert(PetTalentList, {PetInfo, 0})
        elseif attribute_info.speed.talent_add_value and 0 ~= attribute_info.speed.talent_add_value and attribute_info.speed.talent_add_value < 10 then
          table.insert(PetTalentList, {PetInfo, 0})
        elseif _IsNeedFail then
          table.insert(PetTalentList, {PetInfo, 1})
        end
      end
    end
  elseif bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
    if PetInfoList and #PetInfoList >= 1 then
      for i, PetInfo in ipairs(PetInfoList) do
        table.insert(PetTalentList, {PetInfo, 0})
      end
    end
  elseif PetInfoList and #PetInfoList >= 1 then
    for i, PetInfo in ipairs(PetInfoList) do
      table.insert(PetTalentList, {PetInfo, 0})
    end
  end
  return PetTalentList
end

function UMG_Bag_C:CanChangeBlood(behavior, blood_id)
  local petBloodConf = _G.DataConfigManager:GetPetBloodConf(blood_id)
  local canUse = false
  if petBloodConf then
    local IBArray = petBloodConf.change_blood_action
    for _, IB in ipairs(IBArray) do
      if IB == behavior then
        canUse = true
        break
      end
    end
  end
  return canUse
end

function UMG_Bag_C:GetPetCanUseBloodPulseList(bagItemInfo, _IsNeedFail)
  local BloodPulseIdTempList = {}
  local PetBloodPulseList = {}
  local PetInfoList = {}
  if self.UseActionPetData then
    PetInfoList = {
      self.UseActionPetData
    }
  else
    PetInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  end
  if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD then
    local BloodPulseIdList = bagItemInfo.item_behavior[1].ratio2
    if #BloodPulseIdList > 0 then
      for i = 1, #BloodPulseIdList do
        local BloodPulseIdTemp = _G.DataConfigManager:GetPetEvolutionConf(BloodPulseIdList[i])
        for j = 1, #BloodPulseIdTemp.evolution_chain do
          table.insert(BloodPulseIdTempList, #BloodPulseIdTempList + 1, BloodPulseIdTemp.evolution_chain[j].petbase_id)
        end
      end
      if PetInfoList and #PetInfoList >= 1 then
        for i, PetInfo in ipairs(PetInfoList) do
          if not self:CanChangeBlood(bagItemInfo.item_behavior[1].use_action, PetInfo.blood_id) then
            if true == _IsNeedFail then
              table.insert(PetBloodPulseList, {PetInfo, 2})
            end
          else
            for j = 1, #BloodPulseIdTempList do
              if PetInfo.base_conf_id == BloodPulseIdTempList[j] and PetInfo.blood_id ~= bagItemInfo.item_behavior[1].ratio[1] then
                table.insert(PetBloodPulseList, {PetInfo, 0})
                break
              end
              if PetInfo.base_conf_id == BloodPulseIdTempList[j] and PetInfo.blood_id == bagItemInfo.item_behavior[1].ratio[1] and true == _IsNeedFail then
                table.insert(PetBloodPulseList, {PetInfo, 1})
                break
              end
              if j == #BloodPulseIdTempList and true == _IsNeedFail then
                table.insert(PetBloodPulseList, {PetInfo, 2})
              end
            end
          end
        end
      end
    elseif PetInfoList and #PetInfoList >= 1 then
      for i, PetInfo in ipairs(PetInfoList) do
        if not self:CanChangeBlood(bagItemInfo.item_behavior[1].use_action, PetInfo.blood_id) then
          if true == _IsNeedFail then
            table.insert(PetBloodPulseList, {PetInfo, 2})
          end
        elseif PetInfo.blood_id ~= bagItemInfo.item_behavior[1].ratio[1] then
          table.insert(PetBloodPulseList, {PetInfo, 0})
        elseif true == _IsNeedFail then
          table.insert(PetBloodPulseList, {PetInfo, 1})
        end
      end
    end
  elseif bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
    if PetInfoList and #PetInfoList >= 1 then
      for i, PetInfo in ipairs(PetInfoList) do
        if not self:CanChangeBlood(bagItemInfo.item_behavior[1].use_action, PetInfo.blood_id) then
          if true == _IsNeedFail then
            table.insert(PetBloodPulseList, {PetInfo, 2})
          end
        else
          table.insert(PetBloodPulseList, {PetInfo, 0})
        end
      end
    end
  elseif bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS and PetInfoList and #PetInfoList >= 1 then
    for i, PetInfo in ipairs(PetInfoList) do
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(PetInfo.base_conf_id)
      if PetInfo.blood_id == Enum.PetBloodType.PBT_BOSS then
        if true == _IsNeedFail then
          table.insert(PetBloodPulseList, {PetInfo, 1})
        end
      elseif not (self:CanChangeBlood(bagItemInfo.item_behavior[1].use_action, PetInfo.blood_id) and petBaseConf.bosspetbase_id_arry) or not (#petBaseConf.bosspetbase_id_arry > 0) then
        if true == _IsNeedFail then
          table.insert(PetBloodPulseList, {PetInfo, 2})
        end
      else
        table.insert(PetBloodPulseList, {PetInfo, 0})
      end
    end
  end
  return PetBloodPulseList
end

function UMG_Bag_C:GetSkillTypePath(type, damage_type)
  if type == Enum.SkillType.ST_DAMAGE then
    if damage_type == Enum.DamageType.DT_SPC then
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_04_png.ui_pet_attribute_04_png'"
    else
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_02_png.ui_pet_attribute_02_png'"
    end
  elseif type == Enum.SkillType.ST_DEFEND then
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_DEFENSE_png.AT_DEFENSE_png'"
  else
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_CLASSIFICATION_png.AT_CLASSIFICATION_png'"
  end
end

function UMG_Bag_C:SetItemInfo(itemID, ItemGid, bClickByUser)
  Log.Debug("[Bag] UMG_Bag_C:SetItemInfo", itemID)
  self:ResetDescText()
  if 1 == self.HasItemSwitcher:GetActiveWidgetIndex() then
    return
  end
  local bagItemInfo = _G.DataConfigManager:GetBagItemConf(itemID)
  if nil == bagItemInfo then
    return
  end
  local itemData = self.data:GetCurSelectedItemData()
  if bagItemInfo.id == 100616 then
    self.UsageCount:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_UsageCount:SetText(itemData.remain_use_cnt .. "/" .. itemData.max_use_cnt)
  else
    self.UsageCount:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_BagItemTemplate_C:OnItemSelected")
  local BagTypeNum = self.data:GetBagItemNumInBagByType(bagItemInfo.type)
  local TypeConf = _G.DataConfigManager:GetBagItemTypeConf(bagItemInfo.type)
  if TypeConf and TypeConf.type_number_limit and 0 ~= TypeConf.type_number_limit then
    self.NRCSwitcher_26:SetActiveWidgetIndex(1)
    self.UpperLimit:InitNum(BagTypeNum, TypeConf.type_number_limit)
  else
    self.NRCSwitcher_26:SetActiveWidgetIndex(0)
  end
  if bagItemInfo.lable_type == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
    self.IconSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.List:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SkillAttributes:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Attr:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImage_101:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Skill:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.iconskill:SetPath(bagItemInfo.big_icon)
    local petSkillLernList = {}
    local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
    if not self.lastSkillId then
      self.lastSkillId = skillConf.id
    elseif self.lastSkillId ~= skillConf.id then
      self:ResetDescText()
      self.lastSkillId = skillConf.id
    end
    self.NumericalValue_1:SetText(skillConf.energy_cost[1])
    self.Department:SetPath(self:GetSkillTypePath(skillConf.Skill_Type, skillConf.damage_type))
    if 1 ~= skillConf.damage_type then
      self.NumericalValue:SetText(tostring(skillConf.dam_para[1]))
    else
      self.NumericalValue:SetText("-")
    end
    self.SkillConf = skillConf
    self:SetSkillMachineIcon(skillConf.icon)
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Visible)
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    local typeList = {
      {
        Name = typeDic.short_name,
        Path = typeDic.type_icon
      }
    }
    self.Attr:InitGridView(typeList)
    petSkillLernList = self:GetPetSkillLernList(bagItemInfo)
    if petSkillLernList and #petSkillLernList >= 1 then
      self.List:Clear()
      self.List:InitGridView(petSkillLernList)
    else
      self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local skillDesc = skillConf.desc
    self.descText = skillDesc
    self.NRCTextDes:SetText(skillDesc)
    self.Switcher:SetActiveWidgetIndex(0)
    self.EggItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.IconSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SkillConf = nil
    self.SkillAttributes:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_101:SetVisibility(UE4.ESlateVisibility.Visible)
    self:SetIcon(bagItemInfo.big_icon)
    self.Skill:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RightBtn:SetTitleTextAndIcon()
    if bagItemInfo.lable_type == _G.Enum.ItemLableType.ILT_TASK then
      self.RightBtn:SetBtnText(LuaText.umg_petbag_7)
    else
      self.RightBtn:SetBtnText(LuaText.umg_bag_13)
      local petBoxItemID = 390001
      if itemID == petBoxItemID then
        self.RightBtn:SetBtnText(LuaText.use_pet_box_button)
      end
    end
    local itemDes = bagItemInfo.description
    if bagItemInfo.lable_type == _G.Enum.ItemLableType.ILT_PET_EGG then
      if itemData.egg_data and 0 ~= itemData.egg_data.conf_id then
        local isHaveBook, name, desc = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, bagItemInfo.id)
        if isHaveBook then
          itemDes = desc
        end
      end
      if itemData.egg_data and itemData.egg_data.src and itemData.egg_data.src == _G.Enum.EggAcquireWayType.EAWT_BLESSING then
        local srcDes = string.format(LuaText.interactiontree_cifu_text_1, itemData.egg_data.from_player_name, itemData.egg_data.from_pet_name)
        itemDes = string.format("%s%s", itemDes, srcDes)
      end
      self.Switcher:SetActiveWidgetIndex(0)
      local itemSelectData = self.data:GetCurSelectedItemData()
      local eggData = itemSelectData.egg_data
      self:SetEggaInfo(eggData, itemSelectData.update_time)
    elseif bagItemInfo.lable_type == _G.Enum.ItemLableType.ILT_PET_FRUIT then
      local isHaveBook, name, desc = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, bagItemInfo.id)
      if isHaveBook then
        itemDes = desc
      end
      self.EggItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Switcher:SetActiveWidgetIndex(0)
      self.EggItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.NRCTextDes:SetText(itemDes)
  end
  if bagItemInfo.flavor_text then
    self.SizeBox_37:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.NRCTextDes_1:SetText(bagItemInfo.flavor_text)
  else
    self.SizeBox_37:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local request = NRCResourceManager:LoadResAsync(self, bagItemInfo.big_icon, -1, -1, function(caller, resRequest, asset)
    if self and UE4.UObject.IsValid(self) and not self.isDestruct and self.SetModelAnimation then
      self:SetModelAnimation(asset)
    end
  end, nil, nil)
  if self.lastShowItemId ~= itemData.gid then
    self:PlayAnimation(self.Change_Icon)
    self:RandomPlayAnimation()
    local gainWayList = self:GetGaiWay(bagItemInfo)
    self.ItemGainWay:InitGridView(gainWayList)
    for i = 1, #gainWayList do
      local item = self.ItemGainWay:GetItemByIndex(i - 1)
      self:DelaySeconds(0.05 * i, function()
        item:SetVisibility(UE.ESlateVisibility.Visible)
        item:PlayAnimation(item.In)
      end)
    end
  end
  self.lastShowItemId = itemData.gid
  if nil == self.oldItemId or self.oldItemId ~= itemID then
    self.oldItemId = itemID
  end
  local itemName = bagItemInfo.name
  if bagItemInfo.type == _G.Enum.BagItemType.BI_PET_EGG or bagItemInfo.type == _G.Enum.BagItemType.BI_PET_FRUIT then
    local isHaveBook = false
    if itemData.egg_data and 0 ~= itemData.egg_data.conf_id or bagItemInfo.type == _G.Enum.BagItemType.BI_PET_FRUIT then
      isHaveBook, haveName, des = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, bagItemInfo.id)
      if isHaveBook then
        itemName = haveName
      end
    end
    local Conf
    local isRandomEgg = false
    if bagItemInfo.item_behavior[1] and bagItemInfo.item_behavior[1].ratio[1] and 0 ~= bagItemInfo.item_behavior[1].ratio[1] then
      Conf = _G.DataConfigManager:GetPetEggConf(bagItemInfo.item_behavior[1].ratio[1])
    elseif bagItemInfo.item_behavior[1] and bagItemInfo.item_behavior[1].ratio2[1] then
      Conf = _G.DataConfigManager:GetPetRandomEggConf(bagItemInfo.item_behavior[1].ratio2[1])
      isRandomEgg = true
    end
    if itemData.egg_data and itemData.egg_data.precious_egg_type and itemData.egg_data.precious_egg_type ~= ProtoEnum.PreciousEggType.PET_NONE then
      if itemData.egg_data.precious_egg_type == ProtoEnum.PreciousEggType.PET_PARTNER then
      elseif not isHaveBook and not isRandomEgg then
        itemName = LuaText.cifu_precious_petegg
      end
    elseif Conf and Conf.precious_egg_type then
    else
      if itemData.egg_data and itemData.egg_data.precious_egg_type and itemData.egg_data.precious_egg_type == _G.Enum.PreciousEggType.PET_PRECIOUS and not isHaveBook and not isRandomEgg then
        itemName = LuaText.cifu_precious_petegg
      else
      end
    end
    if bagItemInfo.type == _G.Enum.BagItemType.BI_PET_EGG and itemData.egg_data and itemData.gid then
      self.PetEggTypeIconItem:SetItemIcon(itemData.gid, false)
      self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SwapEggs_Precious:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.EggMark:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  else
    self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SwapEggs_Precious:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.EggMark:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self.ItemName:SetText(itemName)
  self.ItemProperty:SetText(bagItemInfo.type_desc)
  self:ShowFruitTimeText(itemData.fruit_active_timestamp)
  self:UpdateFruitItemTimer(itemData.fruit_active_timestamp)
  if -1 == self.displayMode then
    self.BtnSwitcher:SetActiveWidgetIndex(3)
    local petBaseLst, catchRateGrade = BattleUtils.GetCatchRateInvalidEnemyPets(itemID)
    if not petBaseLst or BattleUtils.IsTeam() then
      self.CurEquipMid_red:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      if BattleUtils.IsMultiMode() then
        self.UMG_BagPetItem_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.UMG_BagPetItem_2:SetVisibility(UE.ESlateVisibility.Collapsed)
      else
        self.UMG_BagPetItem_1:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.UMG_BagPetItem_2:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
      self.NRCSwitcher_65:SetVisibility(UE.ESlateVisibility.Collapsed)
      if 1 == catchRateGrade then
        self.NRCSwitcher_65:SetActiveWidgetIndex(0)
        local text = _G.DataConfigManager:GetBattleGlobalConfig("catch_pr_low").str
        self.TextBlock_6:SetText(text)
      else
        self.NRCSwitcher_65:SetActiveWidgetIndex(1)
        local text = _G.DataConfigManager:GetBattleGlobalConfig("catch_pr_middle").str
        self.TextBlock_6:SetText(text)
      end
      local notShow = BattleUtils.IsMultiMode() and petBaseLst and #petBaseLst > 0
      self.CurEquipMid_red:SetVisibility(notShow and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.LowCatchRateWarning:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    local bMulty = false
    if bagItemInfo.type == _G.Enum.BagItemType.BI_PET_BALL then
      bMulty = true
    end
    if 1 == bagItemInfo.can_use_in_bag then
      if bagItemInfo.type == _G.Enum.BagItemType.BI_MAGIC then
        self:SetBtnSwitcher(1, 1)
        if nil ~= itemData.bag_item_flags and 1 == itemData.bag_item_flags & 1 then
          self:SetEquipState(true, bMulty)
        else
          local EquipMagicInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
          if EquipMagicInfo and itemData.gid == EquipMagicInfo.gid then
            self:SetEquipState(true, bMulty)
          else
            self:SetEquipState(false, bMulty)
          end
        end
      elseif bagItemInfo.type == _G.Enum.BagItemType.BI_PET_EGG then
        self.BtnSwitcher:SetActiveWidgetIndex(2)
      else
        self:SetBtnSwitcher(1, 0)
      end
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_MAGIC then
      self:SetBtnSwitcher(0, 1)
      if nil ~= itemData.bag_item_flags and 1 == itemData.bag_item_flags & 1 then
        self:SetEquipState(true, bMulty)
      else
        local EquipMagicInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
        if EquipMagicInfo and itemData.gid == EquipMagicInfo.gid then
          self:SetEquipState(true, bMulty)
        else
          self:SetEquipState(false, bMulty)
        end
      end
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_PET_EGG then
      self.BtnSwitcher:SetActiveWidgetIndex(2)
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_PET_BALL then
      self:SetBtnSwitcher(0, 1)
      self:SetEquipState(false, bMulty)
    else
      self:SetBtnSwitcher(0, 0)
    end
    local use_action = bagItemInfo.item_behavior[1] and bagItemInfo.item_behavior[1].use_action
    self.Cur_Use_Action = use_action
    if bagItemInfo.type == _G.Enum.BagItemType.BI_MAGIC then
      local EquipMagicInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
      if EquipMagicInfo then
        self.data.hasEquip = true
        self:SetCurEquipItem(EquipMagicInfo.id)
        self:SetCurEquipItemVisible(true)
      else
        self.data.hasEquip = false
        self:SetCurEquipItemVisible(false)
      end
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_PRECIOUS then
      self:SetCurEquipItemVisible(false)
      if use_action == _G.Enum.ItemBehavior.IB_OPEN_GP_BAG then
        self:UpdateSeedEquipInfo()
      end
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_MATERIAL then
      self:SetCurEquipItemVisible(false)
      if use_action == _G.Enum.ItemBehavior.IB_CHANGE_NATURE_EFFECT or use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
        self:SetCurEquipItemVisible(false)
      end
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_ITEM then
      if use_action == _G.Enum.ItemBehavior.IB_CHOOSE_ITEMS then
        self:SetCurEquipItemVisible(false)
      end
      if use_action == _G.Enum.ItemBehavior.IB_GET_AWARD then
        self:SetCurEquipItemVisible(false)
      end
    elseif bagItemInfo.type == _G.Enum.BagItemType.BI_PLAYERSKILL then
      self:SetBtnSwitcher(0, 1)
      self:SetNumInfo(itemData)
      self:SetCurrentEquipmentInfo()
      if itemData.bag_item_flags == _G.ProtoEnum.BagItemFlag.EQUIPPED then
        self:SetEquipState(true, bMulty)
      else
        self:SetEquipState(false, bMulty)
      end
    end
    if use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
      self:SetCurEquipItemVisible(false)
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetTalentList = self:GetPetCanUseTalentList(bagItemInfo, true)
      if PetTalentList and #PetTalentList >= 1 then
        self.List:Clear()
        self.List:InitGridView(PetTalentList)
      else
        self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if use_action == _G.Enum.ItemBehavior.IB_IMPROVE_TALENT then
      self:SetCurEquipItemVisible(false)
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetTalentList = self:GetPetCanUseTalentList(bagItemInfo, true)
      if PetTalentList and #PetTalentList >= 1 then
        self.List:Clear()
        self.List:InitGridView(PetTalentList)
      else
        self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE or use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD or use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS or use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
      self:SetCurEquipItemVisible(false)
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local PetBloodPulseList = self:GetPetCanUseBloodPulseList(bagItemInfo, true)
      if PetBloodPulseList and #PetBloodPulseList >= 1 then
        self.List:Clear()
        self.List:InitGridView(PetBloodPulseList)
      else
        self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if use_action == _G.Enum.ItemBehavior.IB_OPEN_TALE_INTERFACE and bagItemInfo.item_behavior[1].ratio[1] then
      self.RightBtn.RedDot:SetupKey(246, {
        bagItemInfo.item_behavior[1].ratio[1]
      })
    else
      self.RightBtn.RedDot:SetupKey(0)
    end
    if use_action == _G.Enum.ItemBehavior.IB_NIGHTMARE_ELITE_RECOVERY then
      self.List:SetVisibility(UE4.ESlateVisibility.Visible)
      local evolutionaryPetList = self:GetEvolutionaryPetShowList()
      if evolutionaryPetList and #evolutionaryPetList >= 1 then
        self.List:Clear()
        self.List:InitGridView(evolutionaryPetList)
      else
        self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if self.module.data:InFurnitureDecomposeMode() then
      self.BtnSwitcher:SetActiveWidget(self.AddSubtract_NoProgressBar)
    end
  end
  self:TryUpdateFurnitureDecomposeStats(bagItemInfo, bClickByUser)
  if nil ~= bagItemInfo.expire_time then
    self:BP_SetGiftVoucherInfo(bagItemInfo)
    self.DeadlineNotice:SetVisibility(UE.ESlateVisibility.Visible)
  else
    self.RightBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.DeadlineNotice:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.ComfortLevel then
    if bagItemInfo.type == _G.Enum.BagItemType.BI_FURNITURE then
      self.ComfortLevel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.ComfortLevelText:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      local Conf = DataConfigManager:GetFurnitureItemConf(bagItemInfo.id, true) or DataConfigManager:GetInteriorFinishConf(bagItemInfo.id, true)
      self.ComfortLevelText:SetText(Conf and Conf.comfort or 0)
    else
      self.ComfortLevel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
  if not self.bPlayOpenAnim then
    if self.displayMode == BagModuleEnum.DisplayMode.PetEgg then
      self:PlayAnimation(self.open_normal)
    else
      if self:IsAnimationPlaying(self.ScreenBtn_open) then
      else
      end
    end
    self.bPlayOpenAnim = true
  end
end

function UMG_Bag_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Bag_C:ResetDescText(bDisableResetComboBox)
  if not bDisableResetComboBox then
    self:ResetComboBox()
  end
  self:HideCloseBtn()
end

function UMG_Bag_C:ResetComboBox()
  if self.ComboBox and self.ComboBox.CommonDropDownListData then
    self.ComboBox:SetPopupVisible(false)
  end
end

function UMG_Bag_C:ShowCloseBtn()
  self.Btn_ShutDown_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_ShutDown_2:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_ShutDown_3:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_ShutDown_4:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Btn_ShutDown_5:SetVisibility(UE4.ESlateVisibility.Visible)
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Bag_C:HideCloseBtn()
  self.Btn_ShutDown_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ShutDown_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ShutDown_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ShutDown_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ShutDown_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BtnClosePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Bag_C:SetCurrentEquipmentInfo()
  local PlayerSkill = self.data:GetBagItemByLableType(Enum.ItemLableType.ILT_PLAYERSKILL)
  local id
  for i, _PlayerSkill in ipairs(PlayerSkill) do
    if 1 == _PlayerSkill.bag_item_flags then
      self.data.hasEquip = true
      id = _PlayerSkill.id
      break
    end
  end
  if not id then
    self.data.hasEquip = false
  end
  self:SetCurEquipItem(id)
end

function UMG_Bag_C:SetNumInfo(itemData)
  local UseCnt = itemData.remain_use_cnt
  local Text = string.format("/%s", itemData.max_use_cnt)
end

function UMG_Bag_C:SetSkillMachineIcon(_icon)
  local Temp = string.len("Texture2D'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/SkillIcon/")
  local addr = string.sub(_icon, Temp + 1, string.len(_icon))
  local IconIndex = string.len(addr) / 2
  local IconName = string.sub(addr, 1, IconIndex - 1) .. "_png"
  local lightPath = string.format("%s%s.%s'", self.CommonPath, IconName, IconName)
  self.NRCImage_4:SetPathWithCallBack(lightPath, {
    self,
    self.OnHasItemSwitcherShow
  })
end

function UMG_Bag_C:SetEggaInfo(eggData, findTime)
  if nil == eggData then
    return
  end
  local update_time = os.date("%Y/%m/%d", findTime)
  local eggFindTimeInfo = {
    name = LuaText.umg_bag_1,
    type = 2,
    des = update_time
  }
  local eggHeightInfo = {
    name = LuaText.umg_bag_2,
    type = 0,
    des = eggData.height * 0.01
  }
  local eggWeightInfo = {
    name = LuaText.umg_bag_4,
    type = 1,
    des = eggData.weight * 0.001
  }
  local eggInfoList = {
    eggHeightInfo,
    eggWeightInfo,
    eggFindTimeInfo
  }
  self.EggItem:SetVisibility(UE.ESlateVisibility.Visible)
  for i = 1, 3 do
    local name = string.format("EggItem%d", i)
    self[name]:OnShowItem(eggInfoList[i])
  end
  self.eggConfId = eggData.conf_id
  local eggCount = 0
  local backpack_info = _G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info
  if backpack_info and backpack_info.egg_gid then
    eggCount = #backpack_info.egg_gid
  end
  local maxCount = _G.DataConfigManager:GetPetGlobalConfig("hatch_limit").num
  local eggCountText = string.format("<span color=\"#CF3D3E\">%d</>", eggCount)
  self.MiddleBtn1_1:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.umg_petbag_8 .. "\239\188\154 ", eggCount .. "/" .. maxCount)
  self.Full:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.umg_petbag_8 .. "\239\188\154 ", eggCountText .. "/" .. maxCount)
  self.Full.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Full:SetBtnText(LuaText.umg_petbag_9)
  self.Full:SetClickAble(false)
  if eggCount >= maxCount then
    self.Full:SetVisibility(UE4.ESlateVisibility.Visible)
    self.MiddleBtn1_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Full:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.MiddleBtn1_1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Bag_C:GetGaiWay(bagItemInfo)
  local real_acquire_struct = {}
  for i = 1, #bagItemInfo.acquire_struct do
    if bagItemInfo.acquire_struct[i].acquire_way_text == nil then
      goto lbl_30
    else
      table.insert(real_acquire_struct, {
        acquire_struct = bagItemInfo.acquire_struct[i],
        IsFirstOpenPanel = self.data:GetIsFirstOpenPanel(),
        itemId = bagItemInfo.id
      })
    end
    ::lbl_30::
  end
  return real_acquire_struct
end

function UMG_Bag_C:SetSortListInfo(bagItemType)
  Log.Debug("[Bag] step3 UMG_Bag_C:SetSortListInfo", bagItemType)
  local sortList = self.data:GetSortTypesByItemType(bagItemType)
  self.data:SetCurSortList(sortList)
  local SortSelectIndex = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetTableSortSelectIndex, bagItemType)
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OnSequenceSelected, SortSelectIndex)
end

function UMG_Bag_C:ChangeSortText(bagItemType)
  local sequenceList
  if not self.sequenceList then
    self.sequenceList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BAG_ITEM_SEQUENCE):GetAllDatas()
  end
  sequenceList = self.sequenceList
  local sortText = ""
  local sortList = self.data:GetSortTypesByItemType(bagItemType)
  local SortSelectIndex = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetTableSortSelectIndex, bagItemType)
  local sortIndex = sortList[SortSelectIndex]
  for i, sequenceConf in pairs(sequenceList) do
    if sequenceConf.sequence == sortIndex then
      sortText = sequenceConf.sequence_desc
      self.ComboBox:OnItemSelectedTextChange(SortSelectIndex)
      break
    end
  end
  self.ComboBox:SetComboText(sortText)
end

function UMG_Bag_C:SortItem(itemType, sortType, bagItemConf)
  if self.DelaySortItemId then
    _G.DelayManager:CancelDelayById(self.DelaySortItemId)
    self.DelaySortItemId = nil
  end
  self.DelaySortItemId = _G.DelayManager:DelayFrames(1, function()
    self.DelaySortItemId = nil
    self:SortItem1(itemType, sortType, bagItemConf)
  end)
end

function UMG_Bag_C:SortItem1(itemType, sortType, bagItemConf)
  local sortList = {}
  if self.module.PetOpenUseAction then
    sortList = self:GetUseActionItemList()
  else
    sortList = self.data:SortItemListByLableType(itemType, sortType)
  end
  local GridView1
  if self:IsExchangeStyle() then
    GridView1 = self.List1
  else
    GridView1 = self.GridView1
  end
  local Selectindex = -1
  if bagItemConf then
    for i = 1, #sortList do
      if sortList[i].id == bagItemConf.id then
        Selectindex = i - 1
      end
    end
  end
  if -1 == Selectindex then
    self.data:SetFirstOpenPanelId(-1)
  end
  if 0 == #sortList then
    local isSceen = #self.data.FilterPetCondition > 0 or #self.data.FilterDepartCondition > 0 or #self.data.FilterClassifyCondition > 0
    if itemType == _G.Enum.ItemLableType.ILT_SKILL_MACHINE and isSceen or itemType == _G.Enum.ItemLableType.ILT_FURNITURE and self.data:HasFurnitureFilters() then
      self.HasItemSwitcher:SetActiveWidgetIndex(0)
      self.ScreenCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CloseBtn.NRCSwitcher_1:SetActiveWidgetIndex(2)
      self:PlayAnimation(self.ScreenBtn_none_refresh)
    else
      self.HasItemSwitcher:SetActiveWidgetIndex(1)
      self:OnHasItemSwitcherShow()
      local type
      if itemType == _G.Enum.ItemLableType.ILT_USEFUL_ITEM then
        type = Enum.BagItemType.BI_PET_BALL
      elseif itemType == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
        type = Enum.BagItemType.BI_SKILL_MACHINE
      elseif itemType == _G.Enum.ItemLableType.ILT_PET_EGG then
        type = Enum.BagItemType.BI_PET_EGG
      elseif itemType == _G.Enum.ItemLableType.ILT_FURNITURE then
        type = Enum.BagItemType.BI_FURNITURE
      end
      if type then
        local BagTypeNum = self.data:GetBagItemNumInBagByType(type)
        local TypeConf = _G.DataConfigManager:GetBagItemTypeConf(type)
        if TypeConf and TypeConf.type_number_limit and 0 ~= TypeConf.type_number_limit then
          self.NRCSwitcher_26:SetActiveWidgetIndex(1)
          self.UpperLimit:InitNum(BagTypeNum, TypeConf.type_number_limit)
        else
          self.NRCSwitcher_26:SetActiveWidgetIndex(0)
        end
      else
        self.NRCSwitcher_26:SetActiveWidgetIndex(0)
      end
      self.BGSwitcher:SetActiveWidgetIndex(1)
    end
  end
  GridView1:InitList(sortList)
  self:CancleFruitItemListTimer()
  if itemType == _G.Enum.ItemLableType.ILT_PET_FRUIT then
    self:UpdateFruitItemListTimer(sortList)
  end
  if self.displayMode == BagModuleEnum.DisplayMode.BattleCatch then
    local battleData = self.data:GetCurSelectedItemDataBattle()
    if not battleData or 0 == battleData then
      GridView1:SelectItemByIndex(0)
    else
      local gid = battleData.curUseBallGID
      local bIsFindInBag = false
      if not gid then
        GridView1:SelectItemByIndex(0)
      end
      for idx, item in ipairs(sortList) do
        if item.gid == gid then
          GridView1:SelectItemByIndex(idx - 1)
          bIsFindInBag = true
          break
        end
      end
      if not bIsFindInBag then
        GridView1:SelectItemByIndex(0)
      end
    end
  else
    local SelectItem = self.data:GetCurSelectedItemData()
    local FindItemIndex
    if SelectItem and SelectItem.id then
      FindItemIndex = self:FindUseItemIndex(SelectItem, sortList)
    end
    if FindItemIndex then
      GridView1:SelectItemByIndex(FindItemIndex)
    elseif -1 == Selectindex then
      if sortList and #sortList > 0 then
        if self.delayId then
          self:CancelDelayByID(self.delayId)
          self.delayId = nil
        end
        self.delayId = self:DelayFrames(3, function()
          GridView1:SelectItemByIndex(0)
        end)
        if #sortList > 0 and self.data:InFurnitureDecomposeMode() then
          self:CancelDelayByID(self.delayId)
          self:InternalRefreshFurnitureDecomposition(false, true)
        end
      end
    else
      GridView1:SelectItemByIndex(Selectindex)
    end
  end
  self:ChangeSortText(itemType)
  self:OnInitScreenState()
end

function UMG_Bag_C:FindUseItemIndex(SelectItem, _sortList)
  local ItemType = self.data:GetCurItemType()
  local sortList = _sortList or {}
  if sortList and #sortList > 0 then
  elseif self.module.PetOpenUseAction then
    sortList = self:GetUseActionItemList()
  else
    sortList = self.data:SortItemListByLableType(ItemType, self.data.SortIndex)
  end
  for i, BagItem in ipairs(sortList) do
    if BagItem.id == SelectItem.id then
      return i - 1
    end
  end
  return nil
end

function UMG_Bag_C:SetBtnSwitcher(canUse, canEquip)
  local vec = self.MiddleBtn1.Slot:GetPosition()
  self.BtnSwitcher:SetActiveWidgetIndex(canUse)
  if 0 == canUse then
    if 0 == canEquip then
      self.BtnSwitcher0:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
      self.BtnSwitcher0:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif 0 == canEquip then
    self.LeftBtn1:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.LeftBtn2:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.RightBtn.Slot:SetPosition(vec)
  else
    self.LeftBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.LeftBtn2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.RightBtn.Slot:SetPosition(-144.092316, -82)
  end
end

function UMG_Bag_C:OnBtnLeft1Clicked()
  self.NeeItemSelectedAudio = false
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Bag_C:OnBtnLeft1Clicked")
  local CurSelectedItem = self.data:GetCurSelectedItemData()
  _G.NRCModuleManager:DoCmd(BagModuleCmd.OnEquipStateChanged, CurSelectedItem.gid, 1)
end

function UMG_Bag_C:OnBtnLeft2Clicked()
  self.NeeItemSelectedAudio = false
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Bag_C:OnBtnLeft2Clicked")
  local CurSelectedItem = self.data:GetCurSelectedItemData()
  _G.NRCModuleManager:DoCmd(BagModuleCmd.OnEquipStateChanged, CurSelectedItem.gid, 0)
end

function UMG_Bag_C:OnBtnRightClicked()
  self.NeeItemSelectedAudio = false
  local CanUseStamp = self:IsCanUseStamp()
  local SelectItemData = self.data:GetCurSelectedItemData()
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(SelectItemData.id)
  if CanUseStamp then
    if BagItemConf.type == _G.Enum.BagItemType.BI_SKILL_MACHINE then
      local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_LEARN_SKILL, true)
      if isBan then
        return
      end
      local petSkillLernlist = self:GetPetSkillLernList(BagItemConf)
      for i = 1, #petSkillLernlist do
        if 0 == petSkillLernlist[i][2] then
          if self.displayMode ~= BagModuleEnum.DisplayMode.SkillMachine then
            _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagPopUp, petSkillLernlist, self.data.CustomEnum.SKILL_MACHINE, SelectItemData)
          else
            if not self.SkillMachinePetData then
              return
            end
            local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
            local dialogContext = DialogContext()
            local skillMachineid = BagItemConf.item_behavior[1].ratio[1]
            local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
            local TipsContent = string.format("\229\141\179\229\176\134\228\184\186%s\229\173\166\228\185\160<span color=\"#D76C07FF\">%s</>", self.SkillMachinePetData.name, skillConf.name)
            
            local function Callback()
              local isBanFunc = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_LEARN_SKILL, true)
              if isBanFunc then
                return
              end
              _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, SelectItemData.gid, SelectItemData.id, 1, self.SkillMachinePetData.gid)
              _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagPopUp, self.SkillMachinePetData, self.data.CustomEnum.PetToSKILL_MACHINE, SelectItemData)
            end
            
            dialogContext:SetContent(TipsContent):SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCallbackOkOnly(self, Callback):SetToppingIconType(2)
            NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
          end
          _G.NRCAudioManager:PlaySound2DAuto(1009, "UMG_Bag_C:OnBtnRightClicked")
          return
        end
      end
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bag_6)
    else
      local use_action = BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action
      if use_action == _G.Enum.ItemBehavior.IB_CHOOSE_ITEMS then
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenChooseItemPanel, SelectItemData, BagItemConf.item_behavior[1].ratio)
      elseif use_action == _G.Enum.ItemBehavior.IB_CHANGE_NATURE_EFFECT then
        local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_CHANGE_NATURE_EFFECT, true)
        if isBan then
          return
        end
        if self.UseActionPetData then
          self.data.PetCharacterItem = self.UseActionPetData
          _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.PetCharacterPopUp, true)
        else
          _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.PetCharacterTips, true)
        end
      elseif use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT or use_action == _G.Enum.ItemBehavior.IB_IMPROVE_TALENT then
        if use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
          local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_CHANGE_TALENT, true)
          if isBan then
            return
          end
        elseif use_action == _G.Enum.ItemBehavior.IB_IMPROVE_TALENT then
          local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_IMPROVE_TALENT, true)
          if isBan then
            return
          end
        end
        if self.UseActionPetData then
          do
            local PetTalentList = self:GetPetCanUseTalentList(BagItemConf, false)
            if PetTalentList and #PetTalentList > 0 then
              self.data.PetTalentItem = self.UseActionPetData
              _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.TalentPopup, true)
            else
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bag_7)
              goto lbl_1294
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bag_7)
            end
          end
        else
          local PetTalentList = self:GetPetCanUseTalentList(BagItemConf, false)
          if PetTalentList and #PetTalentList > 0 then
            _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.BagBright, true, PetTalentList)
          else
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bag_7)
          end
        end
      elseif use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE or use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD or use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS or use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
        local PetBloodPulseList = self:GetPetCanUseBloodPulseList(BagItemConf, false)
        if self.UseActionPetData then
          self.data.PetBloodItem = self.UseActionPetData
          if PetBloodPulseList and #PetBloodPulseList > 0 then
            _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.BagBloodPopup, true)
          else
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bag_7)
          end
        elseif PetBloodPulseList and #PetBloodPulseList > 0 then
          _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.BagBlood, true, PetBloodPulseList)
        else
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bag_7)
        end
      elseif use_action == _G.Enum.ItemBehavior.IB_GET_VITEM then
        local Limit = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit").num
        local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
        if Limit <= StarNum then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.no_more_star)
        else
          _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, self.data:GetCurSelectedItemData().gid, self.data:GetCurSelectedItemData().id, 1)
        end
      elseif use_action == Enum.ItemBehavior.IB_OPEN_TALE_INTERFACE then
        _G.NRCModuleManager:DoCmd(TaskModuleCmd.OpenLegendaryPanel, table.unpack(BagItemConf.item_behavior[1].ratio))
      elseif use_action == Enum.ItemBehavior.IB_GIVE_MEDAL then
        if BagItemConf then
          local MedalId = BagItemConf.item_behavior[1].ratio[1]
          local MedalConf = _G.DataConfigManager:GetMedalConf(MedalId)
          if MedalConf.medal_type == _G.Enum.MedalType.MT_BOND then
            if #self.data:GetMedalPetList(MedalConf) and #self.data:GetNoEquipmentMedalPet(self.data:GetMedalPetList(MedalConf), MedalConf) > 0 then
              _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenCommonPopUp, SelectItemData)
            else
              _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\178\161\230\156\137\229\143\175\228\187\165\228\189\191\231\148\168\231\154\132\231\178\190\231\129\181")
            end
          elseif #self.data:GetNoEquipmentMedalPet(self.data:GetMedalPetList(MedalConf), MedalConf) > 0 then
            _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenCommonPopUp, SelectItemData)
          else
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\178\161\230\156\137\229\143\175\228\187\165\228\189\191\231\148\168\231\154\132\231\178\190\231\129\181")
          end
        end
      elseif use_action == Enum.ItemBehavior.IB_NIGHTMARE_ELITE_RECOVERY then
        if self.UseActionPetData then
          _G.NRCModuleManager:DoCmd(BagModuleCmd.SetEvolutionarySelectedItem, {
            self.UseActionPetData
          })
          _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenEvolutionaryUsePanel)
        else
          local evolutionaryPetList = self:GetEvolutionaryPetUseList()
          if 0 == #evolutionaryPetList then
            _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\178\161\230\156\137\231\178\190\231\129\181\229\143\175\228\187\165\229\135\128\229\140\150")
          else
            _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenEvolutionarySelectPanel, evolutionaryPetList)
          end
        end
      elseif use_action == Enum.ItemBehavior.IB_READ then
        _G.NRCModuleManager:DoCmd(DialogueModuleCmd.OpenReadingMatter, BagItemConf.item_behavior[1].ratio[1])
      elseif use_action == Enum.ItemBehavior.IB_OPEN_GP_BAG then
        _G.NRCModuleManager:DoCmd(HomeModuleCmd.OpenSeedBagPanel, nil, _G.MakeWeakFunctor(self, self.HideMoneyBtn), _G.MakeWeakFunctor(self, self.ShowMoneyBtn))
      elseif use_action == Enum.ItemBehavior.IB_UNLOCK_BP_BASICS then
        local BP_Module = _G.NRCModuleManager:GetModule("BattlePassModule")
        local BP_Data = BP_Module:GetData("BattlePassModuleData")
        if BP_Data.PlayerBattlePassInfo and BP_Data.PlayerBattlePassInfo.battle_pass_id then
          local battlePassConf = _G.DataConfigManager:GetBattlePassConf(BP_Data.PlayerBattlePassInfo.battle_pass_id)
          local close_time = battlePassConf.close_time
          local open_time = battlePassConf.open_time
          if ActivityUtils.ToTimestamp(close_time) < ActivityUtils.GetSvrTimestamp() or ActivityUtils.ToTimestamp(open_time) > ActivityUtils.GetSvrTimestamp() then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips6)
            return
          end
          local initData = _G.NRCCommonPopUpData()
          initData.TitleText = _G.DataConfigManager:GetLocalizationConf("bp_gift_unlock_confirm_title").msg
          if BP_Data.PlayerBattlePassInfo.battle_pass_brief_info.gift_grade ~= _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE then
            initData.ContentText = _G.DataConfigManager:GetLocalizationConf("bagitem_BP_basics_tips1").msg
            initData.HideBtn = true
          else
            local bpInfo = BP_Data:GetPlayerBattlePassInfo()
            initData.Call = self
            initData.Btn_LeftText = _G.DataConfigManager:GetLocalizationConf("NO").msg
            initData.Btn_RightText = _G.DataConfigManager:GetLocalizationConf("YES").msg
            if 0 == bpInfo.theme_id or bpInfo.theme_id == nil then
              local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BP, true)
              if isBan then
                _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips5)
                return
              end
              initData.ContentText = _G.DataConfigManager:GetLocalizationConf("bagitem_BP_basics_tips2").msg
              initData.Btn_RightHandler = self.BP_SelectTeam
            else
              local petBase_id = _G.DataConfigManager:GetBattlePassThemeConf(bpInfo.theme_id).theme_petbase_id
              local petName = _G.DataConfigManager:GetPetbaseConf(petBase_id).name
              initData.ContentText = string.format(_G.LuaText.bagitem_BP_basics_tips3, petName)
              initData.Btn_RightHandler = self.BP_Unlock
            end
          end
          _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, initData)
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips6)
        end
      elseif use_action == Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE then
        local BP_Module = _G.NRCModuleManager:GetModule("BattlePassModule")
        local BP_Data = BP_Module:GetData("BattlePassModuleData")
        if BP_Data.PlayerBattlePassInfo and BP_Data.PlayerBattlePassInfo.battle_pass_id then
          local battlePassConf = _G.DataConfigManager:GetBattlePassConf(BP_Data.PlayerBattlePassInfo.battle_pass_id)
          local close_time = battlePassConf.close_time
          local open_time = battlePassConf.open_time
          if ActivityUtils.ToTimestamp(close_time) < ActivityUtils.GetSvrTimestamp() or ActivityUtils.ToTimestamp(open_time) > ActivityUtils.GetSvrTimestamp() then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips6)
            return
          end
          local initData = _G.NRCCommonPopUpData()
          initData.Call = self
          initData.Btn_LeftText = _G.DataConfigManager:GetLocalizationConf("NO").msg
          initData.Btn_RightText = _G.DataConfigManager:GetLocalizationConf("YES").msg
          initData.TitleText = _G.DataConfigManager:GetLocalizationConf("bp_gift_unlock_confirm_title").msg
          if BP_Data.PlayerBattlePassInfo.battle_pass_brief_info.gift_grade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_COLLECTION or BP_Data.PlayerBattlePassInfo.battle_pass_brief_info.gift_grade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_SPREAD then
            initData.ContentText = _G.DataConfigManager:GetLocalizationConf("bagitem_BP_upgrade_tips1").msg
            initData.HideBtn = true
          elseif BP_Data.PlayerBattlePassInfo.battle_pass_brief_info.gift_grade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_NORMAL then
            initData.ContentText = _G.DataConfigManager:GetLocalizationConf("bagitem_BP_upgrade_tips2").msg
            initData.Btn_RightHandler = self.BP_Unlock
            initData.CountdownTime = 6
            initData.Btn_GrayStateText = _G.DataConfigManager:GetLocalizationConf("YES").msg
          else
            local bpInfo = BP_Data:GetPlayerBattlePassInfo()
            if 0 == bpInfo.theme_id or bpInfo.theme_id == nil then
              local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BP, true)
              if isBan then
                _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips5)
                return
              end
              initData.ContentText = _G.DataConfigManager:GetLocalizationConf("bagitem_BP_upgrade_tips3").msg
              initData.Btn_RightHandler = self.BP_SelectTeam
            else
              local petBase_id = _G.DataConfigManager:GetBattlePassThemeConf(bpInfo.theme_id).theme_petbase_id
              local petName = _G.DataConfigManager:GetPetbaseConf(petBase_id).name
              initData.ContentText = string.format(_G.LuaText.bagitem_BP_upgrade_tips4, petName)
              initData.Btn_RightHandler = self.BP_Unlock
            end
          end
          _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, initData)
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips6)
        end
      elseif use_action == Enum.ItemBehavior.IB_UNLOCK_BP_BASICS_SPECIFIC or use_action == Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE_SPECIFIC then
        if self:IsGiftVoucherItem() then
          self:DoGiftVoucherItem(BagItemConf, self.data:GetCurSelectedItemData().gid)
        else
          local BP_Module = _G.NRCModuleManager:GetModule("BattlePassModule")
          local BP_Data = BP_Module:GetData("BattlePassModuleData")
          local initData = _G.NRCCommonPopUpData()
          initData.Call = self
          initData.Btn_LeftText = _G.DataConfigManager:GetLocalizationConf("NO").msg
          initData.Btn_RightText = _G.DataConfigManager:GetLocalizationConf("YES").msg
          initData.TitleText = _G.DataConfigManager:GetLocalizationConf("use_bp_gift_card_title").msg
          local bpInfo = BP_Data:GetPlayerBattlePassInfo()
          if 0 == bpInfo.theme_id or bpInfo.theme_id == nil then
            initData.TitleText = _G.DataConfigManager:GetLocalizationConf("bp_gift_unlock_confirm_title").msg
            initData.ContentText = _G.DataConfigManager:GetLocalizationConf("bagitem_BP_upgrade_tips3").msg
            initData.Btn_RightHandler = self.BP_SelectTeam
          else
            initData.ContentText = _G.DataConfigManager:GetLocalizationConf("use_bp_gift_card_text").msg
            initData.Btn_RightHandler = self.OnUseGiftVoucherItem
          end
          _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, initData)
        end
      elseif use_action == Enum.ItemBehavior.IB_JUMP_BEHAVIOR then
        local behaviorId = BagItemConf.item_behavior[1].ratio and BagItemConf.item_behavior[1].ratio[1]
        if behaviorId then
          local behaviorData = _G.DataConfigManager:GetBehaviorConf(behaviorId)
          if behaviorData then
            if behaviorData.behavior_type == Enum.BehaviorType.BT_WEBSITE then
              _G.NRCSDKManager:OpenWebView(behaviorData.action_param1, tonumber(behaviorData.param1), false, false, nil, false)
            elseif behaviorData.behavior_type == Enum.BehaviorType.BT_WEBSITE_WITH_LOGINSTATE then
              _G.NRCSDKManager:OpenWebView(behaviorData.action_param1, tonumber(behaviorData.param1), false, false, nil, true)
            elseif behaviorData.behavior_type == Enum.BehaviorType.BT_CMD then
              _G.NRCModuleManager:DoCmd(behaviorData.action_param1, behaviorData.param1, behaviorData.param2, behaviorData.param3)
            end
          end
        end
      elseif use_action == Enum.ItemBehavior.IB_SIM then
        _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenCulturalActivitiesTips)
      elseif use_action == Enum.ItemBehavior.IB_ACTIVITY_FACTION then
        _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenCampExperienceCardPanel, BagItemConf.item_behavior[1].ratio[1], SelectItemData.finished_faction)
      else
        _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, self.data:GetCurSelectedItemData().gid, self.data:GetCurSelectedItemData().id or 0, 1)
      end
    end
    ::lbl_1294::
    _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_Bag_C:OnBtnRightClicked")
  else
    local LocalizationConf = _G.DataConfigManager:GetLocalizationConf("Noguide_use_stamp_item")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LocalizationConf.msg)
  end
end

function UMG_Bag_C:OnBtnMiddle1Clicked()
  self.NeeItemSelectedAudio = false
  self.IsUse = true
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Bag_C:OnBtnLeft2Clicked")
  local CurSelectedItem = self.data:GetCurSelectedItemData()
  if CurSelectedItem.type == _G.Enum.BagItemType.BI_PLAYERSKILL then
    if 0 == CurSelectedItem.remain_use_cnt then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Dialog_SetDialogCallBack, self.OnConfirmUse, LuaText.player_skill_equip_tip, self)
    else
      _G.NRCModeManager:DoCmd(BagModuleCmd.EquipProtagonistMagicStateChanged, CurSelectedItem.gid, CurSelectedItem.id)
    end
  elseif CurSelectedItem.type == _G.Enum.BagItemType.BI_PET_BALL then
    local isCollect = _G.NRCModuleManager:DoCmd(BagModuleCmd.CheckBallIsCollectOptimization, CurSelectedItem.id)
    if isCollect then
      _G.NRCModuleManager:DoCmd(BagModuleCmd.OnZoneUpdateBagItemIdFlagReq, CurSelectedItem.id, 0)
    else
      _G.NRCModuleManager:DoCmd(BagModuleCmd.OnZoneUpdateBagItemIdFlagReq, CurSelectedItem.id, 1)
    end
    self.GridView1:ClearSelection()
  else
    _G.NRCModuleManager:DoCmd(BagModuleCmd.OnEquipStateChanged, CurSelectedItem.gid, 1)
  end
end

function UMG_Bag_C:OnConfirmUse(_ok)
  if _ok then
    local CurSelectedItem = self.data:GetCurSelectedItemData()
    _G.NRCModeManager:DoCmd(BagModuleCmd.EquipProtagonistMagicStateChanged, CurSelectedItem.gid, CurSelectedItem.id)
  end
end

function UMG_Bag_C:OnBtnMiddle2Clicked()
  self.NeeItemSelectedAudio = false
  self.IsUse = false
  self.UnEquipTimeSave = UE4.UNRCStatics.GetMilliSeconds()
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Bag_C:OnBtnLeft2Clicked")
  local CurSelectedItem = self.data:GetCurSelectedItemData()
  if CurSelectedItem.type == _G.Enum.BagItemType.BI_PLAYERSKILL then
    _G.NRCModeManager:DoCmd(BagModuleCmd.EquipProtagonistMagicStateChanged, 0, 0)
  else
    _G.NRCModuleManager:DoCmd(BagModuleCmd.OnEquipStateChanged, CurSelectedItem.gid, 0)
  end
end

function UMG_Bag_C:OnBtnEggClicked()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
  isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_START, true)
  if isBan then
    return
  end
  if not self.ClickEggTime then
    self.ClickEggTime = os.time()
  elseif os.time() - self.ClickEggTime <= 1 then
    return
  else
    self.ClickEggTime = os.time()
  end
  local CurSelectedItem = self.data:GetCurSelectedItemData()
  if CurSelectedItem and CurSelectedItem.id then
    NRCModuleManager:DoCmd(RedPointModuleCmd.EraseRedPoint, 469, {
      CurSelectedItem.id
    })
  end
  _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenHatchTips)
  _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, CurSelectedItem.gid, CurSelectedItem.id, 1)
  _G.NRCAudioManager:PlaySound2DAuto(1220002037, "UMG_Bag_C:OnBtnEggClicked")
end

function UMG_Bag_C:OnBtnMiddle3Clicked()
  self.NeeItemSelectedAudio = false
  local ItemData = self.data:GetCurSelectedItemData()
  _G.NRCModuleManager:DoCmd(BattleModuleCmd.OnSelectExtraCatchBall, ItemData and ItemData.gid)
  self:OnCloseButtonClicked()
end

function UMG_Bag_C:SetCurEquipItem(itemId)
  if self.data.hasEquip == false then
    self:SetCurEquipItemVisible(false)
  else
    self:SetCurEquipItemVisible(true)
  end
end

function UMG_Bag_C:SetCurEquipItemVisible(visible)
  if visible then
  else
  end
end

function UMG_Bag_C:IsCanUseStamp()
  local SelectItemDataId = self.data:GetCurSelectedItemData().id
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(SelectItemDataId)
  local itemBehavior = BagItemConf.item_behavior[1]
  if itemBehavior and itemBehavior.use_action and itemBehavior.use_action == _G.Enum.ItemBehavior.IB_UNLOCK_MAP_STAMP then
    return false
  end
  return true
end

function UMG_Bag_C:SetEquipState(equipState, bMulty)
  self.curEquipState = equipState
  if true == equipState then
    self.LeftBtn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.MiddleBtn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.LeftBtn2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.MiddleBtn2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.AlreadyEquip:SetText(LuaText.umg_bag_8)
    self.AlreadyEquip:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.LeftBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.MiddleBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.LeftBtn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.MiddleBtn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.AlreadyEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if bMulty then
    local CurSelectedItem = self.data:GetCurSelectedItemData()
    local isCollect = _G.NRCModuleManager:DoCmd(BagModuleCmd.CheckBallIsCollectOptimization, CurSelectedItem.id)
    self.MiddleBtn1:SetTitleTextAndIcon()
    if isCollect then
      self.MiddleBtn1:SetBtnText(LuaText.used_ball_cancel_button)
      self.AlreadyEquip:SetText(LuaText.used_ball_set_condition)
      self.AlreadyEquip:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.MiddleBtn1:SetBtnText(LuaText.used_ball_set_button)
      self.AlreadyEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.MiddleBtn1:SetBtnText(LuaText.umg_bag_9)
  end
end

function UMG_Bag_C:LastSelecedIndex(index)
  Log.Debug("[Bag] step1 UMG_Bag_C:LastSelecedIndex", index)
  self.NeeItemSelectedAudio = false
  _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenBagExpiredItemsConversion)
  self.GridView1:ClearSelection()
  self:GetChooseItemTypeInfo(index - 1)
  self:PlayAnimation(self.change)
  self.lastShowItemId = -1
  self:RandomPlayAnimation()
end

function UMG_Bag_C:RandomPlayAnimation()
  local index = math.random(1, 4)
  local aimName = string.format("star%d", index)
  self:PlayAnimation(self[aimName])
end

function UMG_Bag_C:OnCloseButtonClicked()
  if self:TryExitFurnitureDecomposition() then
    return
  end
  if self.IsCanClickCloseBtn == false then
    return
  end
  if _G.GlobalConfig.DebugOpenUI then
    self:OnClose()
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_BagUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseBagUI")
    mappingContext:UnBindAction("IA_CloseBagQuick")
  end
  self.data:ClearSkillStoneFilter()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_Bag_C:OnCloseButtonClicked")
  if self.displayMode == BagModuleEnum.DisplayMode.Zone then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  end
  if self.displayMode == BagModuleEnum.DisplayMode.PetEgg then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.EnablePanelPetMain)
    self:DoClose()
    return
  end
  if self.module.IsPetInfoMainToPanel then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.EnablePanelPetMain)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowRightPanel)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowTipsPanel)
    self:DoClose()
  else
    UE4Helper.SetEnableWorldRendering(true, false)
    self:StopAllAnimations()
    self:OnClose()
  end
end

function UMG_Bag_C:OnAnimationStarted(Anim)
  Log.Debug("[Bag] OnAnimationStarted", Anim:GetName())
  if Anim == self.ScreenBtn_none then
    self.bAlreadyNone = true
  elseif Anim == self.ScreenBtn_open then
    self.bAlreadyNone = false
  end
end

function UMG_Bag_C:OnAnimFinished(Animation)
  Log.Debug("[Bag] OnAnimationFinished", Animation:GetName())
  if Animation == self.close then
    UE4.UNRCAudioManager.ResetWorldListenerVolumeOffset()
    if self.displayMode == BagModuleEnum.DisplayMode.NewItemIn then
      local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      self:DelaySeconds(0.2, function()
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
      end)
    else
    end
    self.module.IsPetInfoMainToPanel = false
  elseif Animation == self.open or Animation == self.open_normal then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.data:SetIsFirstOpenPanel(false)
    self.data:SetFirstOpenPanelId(-1)
    self.IsCanClickCloseBtn = true
    self:PlayAnimation(self.loop, 0)
  elseif Animation == self.Change_Icon then
    self.NRCImage_bigicon_Outline:SetRenderOpacity(0)
  end
end

function UMG_Bag_C:ChangBagBG()
  if self.Image_mohuceshi then
    self.Image_mohuceshi:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Bag_C:BagIsHasCur()
  local curitemlist = self.data.BagInfo.item_list[1].items
  if nil == curitemlist then
    return false
  end
  for i, item in ipairs(curitemlist) do
    if self.data.hasEquip == true and self.data:GetCurEquipItem() then
      local GetCurEquipItem = self.data:GetCurEquipItem().id
      if GetCurEquipItem == item.id then
        return true
      end
    end
  end
  return false
end

function UMG_Bag_C:BtnInit()
  self:OnAddBtnListener()
  if -1 == self.displayMode then
    self.MiddleBtn3:SetBtnText(LuaText.umg_bag_11)
  else
    self.MiddleBtn1:SetBtnText(LuaText.umg_bag_9)
    self.MiddleBtn2:SetBtnText(LuaText.umg_bag_12)
    self.RightBtn:SetTitleTextAndIcon()
    self.RightBtn:SetBtnText(LuaText.umg_bag_13)
    self.LeftBtn1:SetBtnText(LuaText.umg_bag_9)
    self.LeftBtn2:SetBtnText(LuaText.umg_bag_12)
    self.MiddleBtn1_1:SetBtnText(LuaText.umg_bag_15)
    self.MiddleBtn2_1:SetBtnText(LuaText.umg_bag_15)
    self.CanvasPanel2_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Bag_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Bag_C:GetEvolutionaryPetUseList()
  local petList = {}
  local bagPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  for i = 1, #bagPetInfo do
    if bagPetInfo[i].blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
      table.insert(petList, {
        bagPetInfo[i],
        0,
        isEvolutionary = true
      })
    end
  end
  return petList
end

function UMG_Bag_C:GetEvolutionaryPetShowList()
  local petList = {}
  local battlePetInfo = {}
  if self.UseActionPetData then
    battlePetInfo = {
      self.UseActionPetData
    }
  else
    battlePetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  end
  for i = 1, #battlePetInfo do
    local switchId
    if battlePetInfo[i].blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
      switchId = 0
    else
      switchId = 2
    end
    table.insert(petList, {
      battlePetInfo[i],
      switchId
    })
  end
  return petList
end

function UMG_Bag_C:HandleOnEquipSeedChange(unEquipSeed, equipSeed)
  local itemData = self.data:GetCurSelectedItemData()
  if itemData and itemData.type == _G.Enum.BagItemType.BI_PRECIOUS then
    local bagItemConf = DataConfigManager:GetBagItemConf(itemData.id)
    if bagItemConf and bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_OPEN_GP_BAG then
      self:UpdateSeedEquipInfo()
    end
  end
end

function UMG_Bag_C:UpdateSeedEquipInfo()
  local seedIcon, seedName
  local equipSeedId = _G.NRCModeManager:DoCmd(HomeModuleCmd.GetEquipSeed)
  if equipSeedId and equipSeedId > 0 then
    local seedBagItemConf = DataConfigManager:GetBagItemConf(equipSeedId)
    if seedBagItemConf then
      seedIcon = seedBagItemConf.icon
      seedName = seedBagItemConf.name
    end
  end
  if seedIcon then
    self.RightBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.seed_pocket_bagitem_equip, seedName, seedIcon)
  else
    self.RightBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.seed_pocket_bagitem_equip_none)
  end
  self.RightBtn:SetBtnText(LuaText.seed_pocket)
end

function UMG_Bag_C:ResetFurniture()
  self.CanvasPanel_74:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.ChooseFurniture:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.data:InitFurnitureBagData()
  self.Tab:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  self.DecompositionBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_Bag_C:OnFurnitureDecompositionClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Bag_C:OnFurnitureDecompositionClick")
  if self.module.data:InFurnitureDecomposeMode() then
    self.module:OpenPanel("UMG_FurnitureDisassemblyPanel")
  else
    local Type = self.data:GetCurItemType()
    if Type == Enum.ItemLableType.ILT_FURNITURE then
      self.module.data:SetFurnitureDecomposeMode(true)
      local sortList = self.data:SortItemListByLableType(Type, self.data.SortIndex)
      if not sortList or not (#sortList > 0) then
        self.module.data:SetFurnitureDecomposeMode(false)
        if _G.DataConfigManager:GetLocalizationConf("empty_decompose_furniture_tips", true) then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.empty_decompose_furniture_tips)
        end
        return
      end
      self:DispatchEvent(BagModuleEvent.UpdateFilter)
      self:InternalRefreshFurnitureDecomposition(false, true)
    end
  end
end

function UMG_Bag_C:OnFinishDecomposeFurniture()
  local Type = self.data:GetCurItemType()
  if Type == Enum.ItemLableType.ILT_FURNITURE then
    self.module:GetData():SetFurnitureDecomposeMode(true)
    local sortList = self.data:SortItemListByLableType(Type, self.data.SortIndex)
    if not sortList or not (#sortList > 0) then
      self.module:GetData():SetFurnitureDecomposeMode(false)
      self:GetChooseItemTypeInfo(Type)
    end
  end
end

function UMG_Bag_C:TryExitFurnitureDecomposition()
  if self.module.data:InFurnitureDecomposeMode() then
    self.LastItemType = nil
    self.module.data:SetFurnitureDecomposeMode(false)
    self:ResetFurniture()
    self:InternalRefreshFurnitureDecomposition()
    self:DispatchEvent(BagModuleEvent.UpdateFilter)
    return true
  end
end

function UMG_Bag_C:InternalTryRefreshFurnitureDecomposeFlag(itemLabelType)
  if itemLabelType ~= Enum.ItemLableType.ILT_FURNITURE then
    return
  end
  local ViewList = self.List1
  local ItemNum = ViewList:GetItemCount()
  for k = 0, ItemNum - 1 do
    local v = ViewList:GetItemByIndex(k)
    if v then
      v.FurnitureNumber:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Bag_C:InternalRefreshFurnitureDecomposition(bInitFromTab, bNeedInDecomposeAnim)
  if bInitFromTab then
    self.DecompositionBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.AddSubtract_NoProgressBar:SetSelectNumText("")
  end
  if self.module.data:InFurnitureDecomposeMode() then
    if 0 == self.lastBagTypeInfoNum then
      self.CanvasPanel_62:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      self.CanvasPanel_62:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.BtnSwitcher:SetActiveWidget(self.AddSubtract_NoProgressBar)
    local itemData = self.data:GetCurSelectedItemData()
    if 0 == self.lastBagTypeInfoNum or itemData and DataConfigManager:GetFurnitureItemConf(itemData.id, true) then
      self.ChooseFurniture:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.CanvasPanel_74:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.AddSubtract_NoProgressBar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      self.ChooseFurniture:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasPanel_74:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.AddSubtract_NoProgressBar:SetVisibility(UE.ESlateVisibility.Collapsed)
      if bNeedInDecomposeAnim and self.lastBagTypeInfoNum > 0 then
        self:PlayAnimation(self.Resolve_in)
      end
    end
    self:InternalFurnitureDecomposeStats()
    self.Tab:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.CanvasPanel_62:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ChooseFurniture:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.CanvasPanel_74:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.BtnSwitcher:SetActiveWidget(self.AddSubtract_NoProgressBar)
    self.AddSubtract_NoProgressBar:SetVisibility(UE.ESlateVisibility.Collapsed)
    local itemData = self.data:GetCurSelectedItemData()
    if itemData and DataConfigManager:GetFurnitureItemConf(itemData.id, true) then
      self:PlayAnimation(self.Resolve_change)
    end
    self.Tab:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Bag_C:OnMultipleAddFurnitureDecompose()
  self:OnDecomposeNumChanged(5)
end

function UMG_Bag_C:OnMultipleSubFurnitureDecompose()
  self:OnDecomposeNumChanged(-5)
end

function UMG_Bag_C:OnSubFurnitureDecompose()
  self:OnDecomposeNumChanged(-1)
end

function UMG_Bag_C:OnAddFurnitureDecompose()
  self:OnDecomposeNumChanged(1)
end

function UMG_Bag_C:OnDecomposeNumChanged(Num)
  if self.module.data:InFurnitureDecomposeMode() then
    local itemData = self.data:GetCurSelectedItemData()
    local Conf = DataConfigManager:GetFurnitureItemConf(itemData.id, true)
    if Conf then
      self.module.data:SelectFurnitureForDecompose(itemData, Num)
      self:InternalFurnitureDecomposeStats()
    end
  end
end

function UMG_Bag_C:InternalRefreshFurnitureButtons(bNeedAutoSelectDecompose)
  local itemData = self.data:GetCurSelectedItemData()
  local Conf = itemData and DataConfigManager:GetFurnitureItemConf(itemData.id, true)
  if not Conf then
    self.AddSubtract_NoProgressBar:SetVisibility(UE.ESlateVisibility.Collapsed)
    return
  else
    self.AddSubtract_NoProgressBar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  local num = self.module.data:GetFurnitureDecomposeNum(itemData)
  if 0 == (num or 0) and bNeedAutoSelectDecompose and self.module.data:InFurnitureDecomposeMode() then
    self.module.data:SelectFurnitureForDecompose(itemData, 1)
    num = self.module.data:GetFurnitureDecomposeNum(itemData)
  end
  self.AddSubtract_NoProgressBar:SetSelectNumText((num or 0) > 0 and tostring(num) or "")
  if (num or 0) > 0 then
    self.AddSubtract_NoProgressBar:SetSubtractBtnIsEnabledNewStyle(true)
  else
    self.AddSubtract_NoProgressBar:SetSubtractBtnIsEnabledNewStyle(false)
  end
  if (num or 0) < itemData.num then
    self.AddSubtract_NoProgressBar:SetAddBtnIsEnabledNewStyle(true)
  else
    self.AddSubtract_NoProgressBar:SetAddBtnIsEnabledNewStyle(false)
  end
  local Btn = self.AddSubtract_NoProgressBar.QuickAdditionBtn
  if Btn then
    if num + 5 <= itemData.num then
      Btn:SetIsEnabled(true)
    else
      Btn:SetIsEnabled(false)
    end
  end
  Btn = self.AddSubtract_NoProgressBar.FastReductionBtn
  if Btn then
    if num - 5 < 0 then
      Btn:SetIsEnabled(false)
    else
      Btn:SetIsEnabled(true)
    end
  end
  return itemData
end

function UMG_Bag_C:InternalFurnitureDecomposeStats(bNeedAutoSelectDecompose)
  local itemData = self:InternalRefreshFurnitureButtons(bNeedAutoSelectDecompose)
  self:InternalFurnitureDecomposeRewards()
  self:DispatchEvent(BagModuleEvent.RefreshBagItemFurnitureInfoByGid, itemData and itemData.gid)
end

function UMG_Bag_C:InternalFurnitureDecomposeRewards()
  local bHasDecomposeItems = self.module.data:HasFurnitureDecomposeItems()
  local itemList = self.data:GetBagItemByLableType(Enum.ItemLableType.ILT_FURNITURE)
  local totalNum = 0
  if itemList then
    for k, v in pairs(itemList) do
      totalNum = totalNum + v.num
    end
  end
  local decomposeNum = self.module.data:GetTotalDecomposeNum()
  if bHasDecomposeItems then
    self.TextDone:SetText(string.format(LuaText.home_furni_break_tips2, decomposeNum, totalNum))
  else
    self.TextDone:SetText(string.format(LuaText.home_furni_break_tips1, totalNum))
  end
  local RewardItemInfoList = self.data:GetDecomposeReturnItemInfos()
  self.DecomposeRewards:InitGridView(RewardItemInfoList)
  if #RewardItemInfoList > 0 then
    self.NRCText_86:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCText_86:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self:RefreshDecompositionBtnVisibility()
end

function UMG_Bag_C:RefreshDecompositionBtnVisibility()
  if not self.lastBagTypeInfoNum then
    return
  end
  local bVisible = self.lastBagTypeInfoNum > 0
  if bVisible and self.data:InFurnitureDecomposeMode() then
    local RewardItemInfoList = self.data:GetDecomposeReturnItemInfos()
    if not RewardItemInfoList or 0 == #RewardItemInfoList then
      bVisible = false
    end
  end
  if bVisible then
    self.DecompositionBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.DecompositionBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_Bag_C:TryUpdateFurnitureDecomposeStats(bagItemConf, bClickByUser)
  if bagItemConf and bagItemConf.lable_type == Enum.ItemLableType.ILT_FURNITURE then
    self:InternalFurnitureDecomposeStats(bClickByUser)
    self:InternalRefreshFurnitureDecomposition()
  end
end

function UMG_Bag_C:BP_SelectTeam()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenBattlePass)
end

function UMG_Bag_C:BP_Unlock()
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItem, self.module.data.curSelectedItemData.gid, self.module.data.curSelectedItemData.id or 0, 1)
end

function UMG_Bag_C:IsGiftVoucherItem()
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if not curPassInfo then
    Log.Warning("[BP] IsGiftVoucherItem: curPassInfo is nil")
    return false, nil
  end
  local grade = curPassInfo.battle_pass_brief_info and curPassInfo.battle_pass_brief_info.gift_grade or _G.Enum.BattlePassGiftGrade.BPGG_FREE
  return grade ~= _G.Enum.BattlePassGiftGrade.BPGG_FREE
end

function UMG_Bag_C:UpdateExpireTimeDisplay(giftBagItem)
  if not giftBagItem then
    Log.Warning("[BP] UpdateExpireTimeDisplay: giftBagItem is nil")
    return
  end
  local color = "#F4EEE1FF"
  self.DeadlineText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(color))
  self.Countdown:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
  local expireStatus = self.module.data:CheckItemExpireStatus(giftBagItem, expireThreshold)
  self.RightBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  if expireStatus.isExpired then
    Log.Info("[BP] UpdateExpireTimeDisplay: Item is expired")
    self.RightBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DeadlineText:SetText(LuaText.item_expired_text04)
  elseif expireStatus.isNearExpire then
    Log.Info("[BP] UpdateExpireTimeDisplay: Item is near expire, hours remaining = ", expireStatus.hoursRemaining)
    local text = string.format("%s %s", LuaText.item_expired_text03, giftBagItem.expire_time)
    self.DeadlineText:SetText(text)
    local color = "#AF3D3EFF"
    self.DeadlineText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(color))
    self.Countdown:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  else
    Log.Info("[BP] UpdateExpireTimeDisplay: Item is normal, hours remaining = ", expireStatus.hoursRemaining)
    local text = string.format("%s%s%s", LuaText.item_expired_text01, giftBagItem.expire_time, LuaText.item_expired_text02)
    self.DeadlineText:SetText(text)
  end
end

function UMG_Bag_C:BP_SetGiftVoucherInfo(CurBagItemConf)
  if not CurBagItemConf then
    Log.Warning("[BP] BP_SetGiftVoucherInfo: CurBagItemConf is nil")
    return
  end
  local isGiftVoucher = self:IsGiftVoucherItem() and CurBagItemConf.type == _G.Enum.BagItemType.BI_BP_GIFT_SUB
  self:UpdateExpireTimeDisplay(CurBagItemConf)
  if isGiftVoucher then
    self.RightBtn:SetBtnText(LuaText.bagitem_bp_gift_card_button01)
  else
    self.RightBtn:SetBtnText(LuaText.umg_bag_13)
  end
end

function UMG_Bag_C:DoGiftVoucherItem(BagItemConf, Gid)
  if not BagItemConf then
    Log.Warning("[BP] DoGiftVoucherItem: BagItemConf is nil")
    return
  end
  local giftVoucherData = self:OnRefreshGiftVoucheData(BagItemConf, Gid)
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenGiftVoucherSharing, giftVoucherData)
end

function UMG_Bag_C:OnRefreshGiftVoucheData(BagItemConf, Gid)
  local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
  local expireStatus = self.module.data:CheckItemExpireStatus(BagItemConf, expireThreshold)
  local giftVoucherData = {
    bagItemConf = BagItemConf,
    gid = Gid,
    expireStatus = expireStatus
  }
  self.data:SetGiftVoucherData(giftVoucherData)
  return giftVoucherData
end

function UMG_Bag_C:OnBattlePassInfoUpdate()
  if not self:GetVisibility() == UE4.ESlateVisibility.Visible then
    return
  end
  local curSelectedItem = self.data:GetCurSelectedItemData()
  if not curSelectedItem or not curSelectedItem.id then
    return
  end
  local bagItemInfo = _G.DataConfigManager:GetBagItemConf(curSelectedItem.id)
  if not bagItemInfo then
    return
  end
  self:SetItemInfo(curSelectedItem.id)
  self:OnRefreshGiftVoucheData(bagItemInfo, self.data:GetCurSelectedItemData().gid)
end

function UMG_Bag_C:CheckTabCanClick(tabItem, tabIndex, userClick)
  local isBan = false
  if userClick then
    local value = self.TabList[tabIndex + 1]
    if value then
      isBan = CheckIfBan(value - 1, true)
    end
  end
  return not isBan
end

function UMG_Bag_C:OnBagTabVisibilityChangeHandler(labelType, funcId, bHide)
  if funcId == FunctionEntranceMain or labelType == self.data:GetCurItemType() then
    local isBan = bHide or CheckIfBan(labelType, false)
    self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Bag_C:OnBlockBtnClicked()
  local isBan = CheckIfBan(self.data:GetCurItemType(), true)
  if not isBan then
    Log.Error("UMG_Bag_C:OnBlockBtnClicked: isBan is false")
  end
end

function UMG_Bag_C:OnUseGiftVoucherItem()
  Log.Debug("UMG_Bag_C:OnUseGiftVoucherItem")
  local GoodsId = self.module.data.curSelectedItemData.id
  local GoodsUniqueId = self.module.data.curSelectedItemData.gid
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeAndUnlockGift, GoodsId, GoodsUniqueId)
end

function UMG_Bag_C:ShowMoneyBtn()
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Bag_C:HideMoneyBtn()
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Bag_C:OnHasItemSwitcherShow()
  self.HasItemSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Bag_C:UpdateFruitItemTimer(timestamp)
  if self.fruitTimer and self.fruitTimer < 0 or nil == timestamp then
    self.fruitTimer = 0
    self:CancleFruitItemTimer()
    return
  end
  self:CancleFruitItemTimer()
  self.fruitTimer = timestamp
  self.fruitTimerId = _G.DelayManager:DelaySeconds(1, function()
    self:ShowFruitTimeText(self.fruitTimer)
    self:UpdateFruitItemTimer(self.fruitTimer)
  end, self)
end

function UMG_Bag_C:ShowFruitTimeText(timestamp)
  local isNotCd, timeStr = _G.NRCModuleManager:DoCmd(_G.SleepingOwlModuleCmd.OnGetFruitCd, timestamp)
  self.FruitCoolingTime:SetVisibility(isNotCd and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCText_UsageCount_1:SetText(string.format(LuaText.fruit_CD, timeStr))
end

function UMG_Bag_C:CancleFruitItemTimer()
  if self.fruitTimerId then
    _G.DelayManager:CancelDelayById(self.fruitTimerId)
  end
end

function UMG_Bag_C:UpdateFruitItemListTimer(sortList)
  self:CancleFruitItemListTimer()
  self.cacheFruitSortList = sortList
  self.fruitItemListTimerDic = {}
  self.fruitItemListTimer = 0
  local isCountdown = false
  for _, fruitItem in pairs(sortList) do
    local fruitCd = _G.NRCModuleManager:DoCmd(_G.SleepingOwlModuleCmd.GetActiveCountdown, fruitItem.fruit_active_timestamp)
    if fruitCd > 0 then
      if self.fruitItemListTimerDic[fruitCd] == nil then
        self.fruitItemListTimerDic[fruitCd] = {}
      end
      table.insert(self.fruitItemListTimerDic[fruitCd], fruitItem.gid)
      isCountdown = true
    end
  end
  if isCountdown then
    self:CountdownFruitItemListTimer()
  end
end

function UMG_Bag_C:CountdownFruitItemListTimer()
  local function is_empty_table(t)
    if type(t) ~= "table" then
      return false
    end
    return next(t) == nil
  end
  
  if self.cacheFruitSortList == nil or nil == self.fruitItemListTimerDic or is_empty_table(self.fruitItemListTimerDic) or is_empty_table(self.cacheFruitSortList) then
    self:CancleFruitItemListTimer()
    return
  end
  self.fruitListTimerId = _G.DelayManager:DelaySeconds(1, function()
    self.fruitItemListTimer = self.fruitItemListTimer + 1
    if self.fruitItemListTimerDic[self.fruitItemListTimer] ~= nil and #self.fruitItemListTimerDic[self.fruitItemListTimer] > 0 then
      local gids = self.fruitItemListTimerDic[self.fruitItemListTimer]
      for i = 1, #gids do
        local gid = gids[i]
        for j = 1, #self.cacheFruitSortList do
          local fruitItem = self.cacheFruitSortList[j]
          if fruitItem.gid == gid then
            self:ClearFruitItemTimerCd(j - 1)
          end
        end
      end
      self.fruitItemListTimerDic[self.fruitItemListTimer] = nil
    end
    self:CountdownFruitItemListTimer()
  end, self)
end

function UMG_Bag_C:ClearFruitItemTimerCd(index)
  self.GridView1:GetItemByIndex(index):UpdateFruitCD(true)
end

function UMG_Bag_C:CancleFruitItemListTimer()
  if self.fruitListTimerId then
    _G.DelayManager:CancelDelayById(self.fruitListTimerId)
  end
end

function UMG_Bag_C:SetIcon(icon_path)
  local itemSelectData = self.data:GetCurSelectedItemData()
  if itemSelectData then
    local eggData = itemSelectData.egg_data
    if eggData then
      self.IconSwitcher:SetActiveWidgetIndex(1)
      self.PetEggIcon:SetEggIcon(eggData, icon_path, "BagMain")
      return
    end
  end
  self.IconSwitcher:SetActiveWidgetIndex(0)
  self.NRCImage_101:SetPathWithCallBack(icon_path, {
    self,
    self.OnHasItemSwitcherShow
  })
end

function UMG_Bag_C:ShowBallMarkBtn()
  self.BtnSwitcher0:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Bag_C:ShowSortingBtnIsReversal()
  local itemType = self.data:GetCurItemType()
  local isReversal = self.data:GetTabSortIsReversalSort(itemType)
  if isReversal and UE4.UKismetSystemLibrary.IsValid(self.ComboBox.SortingBtn) then
    self.ComboBox.SortingBtn:SetRenderScale(UE4.FVector2D(-1, 1))
  else
    self.ComboBox.SortingBtn:SetRenderScale(UE4.FVector2D(-1, -1))
  end
end

function UMG_Bag_C:UpdateBagItemNumMagicReplayVideo()
  local ItemType = self.data:GetCurItemType()
  if ItemType == _G.Enum.ItemLableType.ILT_MATERIAL then
    self:RefreshBagInfo()
  end
end

return UMG_Bag_C

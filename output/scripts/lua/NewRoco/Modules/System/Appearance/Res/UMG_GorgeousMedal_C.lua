local UMG_GorgeousMedal_C = _G.NRCPanelBase:Extend("UMG_GorgeousMedal_C")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")

function UMG_GorgeousMedal_C:OnConstruct()
  self:OnAddEventListener()
  self:InitData()
  self:SetMoneyUIShow()
  self:SetSortUIShow()
  self:RefreshTabList()
  self.Upgrade:SetBtnText(LuaText.ashion_suits_unlock_jump_btn)
  local storeIds = {
    AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG,
    AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION
  }
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckIfSuitPurchasableReq, storeIds)
end

function UMG_GorgeousMedal_C:OnUnDoFoldCollapsed()
  local curType = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurTopExclusionPanel)
  if curType ~= AppearanceModuleEnum.ExclusionPanelType.GorgeousMedal then
    return
  end
  self:StopAllAnimations()
  local medalId
  if self.curSelectMedal then
    medalId = self.curSelectMedal.conf.id
  end
  self.skipTabAndBondSelectAudio = true
  self:OnActive(medalId)
  self.skipTabAndBondSelectAudio = false
  _G.NRCAudioManager:PlaySound2DAuto(40010017, "UMG_GorgeousMedal_C:OnUpgradeComponentClose")
end

function UMG_GorgeousMedal_C:OnActive(medalId)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTopExclusionPanel, AppearanceModuleEnum.ExclusionPanelType.GorgeousMedal)
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnGorgeousMedalOpen)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:RefreshMedalState()
  if medalId then
    local conf = _G.DataConfigManager:GetFashionBondConf(medalId)
    if conf and self.MedalInfoMap[conf.fashion_bond_band] then
      self.curTabType = conf.fashion_bond_band
      for i, v in ipairs(self.MedalInfoMap[self.curTabType]) do
        if v.conf.id == medalId then
          self.curSelectMedal = v
          break
        end
      end
    end
    self:UpdateDetailButton(conf.fashion_bond_quality)
    self.bLeftPanelShow = false
  else
    self.bLeftPanelShow = true
  end
  self:PlayOpenAnim()
  self.skipSelectAnim = nil ~= medalId
  for i = 1, self.Appearance_Tab1:GetItemCount() do
    local item = self.Appearance_Tab1:GetItemByIndex(i - 1)
    if item and item.uiData == self.curTabType then
      self.Appearance_Tab1:SelectItemByIndex(i - 1)
      break
    end
  end
  self:OnTabSelected(self.curTabType)
  if medalId then
    if self.SelectMedalDelayId then
      _G.DelayManager:CancelDelayById(self.SelectMedalDelayId)
      self.SelectMedalDelayId = nil
    end
    self.SelectMedalDelayId = _G.DelayManager:DelaySeconds(0.5, function()
      self:SelectMedalById(medalId)
    end)
  end
  if self.curSelectMedal then
    self:RefreshRightView(self.curSelectMedal)
  end
  self.skipSelectAnim = false
end

function UMG_GorgeousMedal_C:OnAddEventListener()
  self:AddButtonListener(self.Return.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.BrandIconBtn, self.OnBrandIconBtnClick)
  self:AddButtonListener(self.NotUnlocked.btnLevelUp, self.OnNotUnlockedBtnClick)
  self:AddButtonListener(self.ToUnlock.btnLevelUp, self.OnToUnlockBtnClick)
  self:AddButtonListener(self.Upgrade.btnLevelUp, self.OnUpgradeBtnClick)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnParticularsBtnClick)
  self:AddButtonListener(self.Intimate.btnLevelUp, self.OnParticularsBtnClick)
  self.BrandIconBtn.OnPressed:Add(self, self.OnBrandIconBtnPressed)
  self.BrandIconBtn.OnReleased:Add(self, self.OnBrandIconBtnReleased)
  _G.NRCEventCenter:RegisterEvent("UMG_GorgeousMedal_C", self, AppearanceModuleEvent.OnUpgradeComponentOpen, self.OnUpgradeComponentOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_GorgeousMedal_C", self, AppearanceModuleEvent.OnUpgradeComponentClose, self.OnUpgradeComponentClose)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_GorgeousMedal_C", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:RegisterEvent("UMG_GorgeousMedal_C", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
end

function UMG_GorgeousMedal_C:OnRemoveEventListener()
  self:RemoveAllButtonListener()
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnUpgradeComponentOpen, self.OnUpgradeComponentOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnUpgradeComponentClose, self.OnUpgradeComponentClose)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
end

function UMG_GorgeousMedal_C:OnDestruct()
  if self.SelectMedalDelayId then
    _G.DelayManager:CancelDelayById(self.SelectMedalDelayId)
    self.SelectMedalDelayId = nil
  end
  self:ClearCurTabRedPoint()
  self:OnRemoveEventListener()
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnGorgeousMedalClose)
end

function UMG_GorgeousMedal_C:InitData()
  self.MedalInfoMap = {}
  self.curTabType = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnCmdGetFashionBondLastTab)
  self.curTabConf = nil
  self.bLeftPanelShow = true
  self.curSelectMedal = nil
  self.sortTypeList = {
    {
      type = AppearanceModuleEnum.FashionMedalSortType.UnLockTime,
      name = LuaText.fashion_bond_unlock_time
    },
    {
      type = AppearanceModuleEnum.FashionMedalSortType.Pet,
      name = LuaText.fashion_bond_pet_turn
    },
    {
      type = AppearanceModuleEnum.FashionMedalSortType.Style,
      name = LuaText.fashion_bond_style_turn
    }
  }
  self.curSortIndex = 1
  self.bReverseSort = false
  self.playerGender = Enum.ESexValue.SEX_MALE
  self.collectionProgressUIList = {
    {
      BrandDescriptionText = self.EveningTwilightText,
      CollectProgressText = self.CollectionProgressText_3,
      CollectProgressBar = self.CollectionProgress_3
    },
    {
      BrandDescriptionText = self.quadrantText,
      CollectProgressText = self.CollectionProgressText_1,
      CollectProgressBar = self.CollectionProgress_1
    },
    {
      BrandDescriptionText = self.FourthQuadrantText,
      CollectProgressText = self.CollectionProgressText,
      CollectProgressBar = self.CollectionProgress
    },
    {
      BrandDescriptionText = self.GritText,
      CollectProgressText = self.CollectionProgressText_2,
      CollectProgressBar = self.CollectionProgress_2
    },
    {
      BrandDescriptionText = self.VoiceprintText,
      CollectProgressText = self.CollectionProgressText_4,
      CollectProgressBar = self.CollectionProgress_4
    }
  }
  self.bIsGoToOtherPanel = false
  if not self.MedalInfoMap then
    self.MedalInfoMap = {}
  end
  local medalGetTimeMap = {}
  local medalInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBondInfo()
  if medalInfo.fashion_bond_item then
    for i, v in ipairs(medalInfo.fashion_bond_item) do
      medalGetTimeMap[v.id] = v.get_time
    end
  end
  local suitIdIndex = 1
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    self.playerGender = player.gender
    if player.gender == Enum.ESexValue.SEX_MALE then
      suitIdIndex = 1
    elseif player.gender == Enum.ESexValue.SEX_FEMALE then
      suitIdIndex = 2
    end
  end
  local allBondConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.FASHION_BOND_CONF)
  for i, v in pairs(allBondConf) do
    local fashionMedalInfo = {}
    fashionMedalInfo.conf = v
    fashionMedalInfo.suitId = v.suits_id[suitIdIndex]
    fashionMedalInfo.state = self:GetFashionMedalState(v, fashionMedalInfo.suitId, medalGetTimeMap[v.id])
    fashionMedalInfo.getTime = medalGetTimeMap[v.id]
    if fashionMedalInfo.state ~= AppearanceModuleEnum.FashionMedalState.NotShow then
      if not self.MedalInfoMap[v.fashion_bond_band] then
        self.MedalInfoMap[v.fashion_bond_band] = {}
      end
      table.insert(self.MedalInfoMap[v.fashion_bond_band], fashionMedalInfo)
    end
  end
  if not self.MedalInfoMap[self.curTabType] then
    self.curTabType = next(self.MedalInfoMap)
  end
end

function UMG_GorgeousMedal_C:RefreshMedalState()
  if not self.MedalInfoMap then
    Log.Error("UMG_GorgeousMedal_C:RefreshMedalState(): self.MedalInfoMap is nil")
    return
  end
  local medalGetTimeMap = {}
  local medalInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBondInfo()
  if medalInfo.fashion_bond_item then
    for i, v in ipairs(medalInfo.fashion_bond_item) do
      medalGetTimeMap[v.id] = v.get_time
    end
  end
  for i, v in pairs(self.MedalInfoMap) do
    for j, v2 in pairs(v) do
      v2.state = self:GetFashionMedalState(v2.conf, v2.suitId, medalGetTimeMap[v2.conf.id])
      v2.getTime = medalGetTimeMap[v2.conf.id]
      if self.curSelectMedal and self.curSelectMedal.suitId == v2.suitId then
        self.curSelectMedal = v2
      end
    end
  end
end

function UMG_GorgeousMedal_C:GetFashionMedalState(fashionBondConf, suitId, getTime)
  if fashionBondConf then
    if fashionBondConf.fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
      if getTime then
        return AppearanceModuleEnum.FashionMedalState.Unlocked
      else
        local bOwned = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, suitId)
        if bOwned then
          return AppearanceModuleEnum.FashionMedalState.NotUpgraded
        else
          local bCanBuy = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSuitAtMonthlyShop, suitId)
          if bCanBuy then
            return AppearanceModuleEnum.FashionMedalState.UnLockable
          end
          local exchangeGoodsId = self:CheckSuitInExchangeShop(suitId)
          if exchangeGoodsId then
            return AppearanceModuleEnum.FashionMedalState.UnLockable
          end
          local randomShop = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSuitAtShopGiftOrMonthlyShop_Old, suitId)
          if randomShop then
            return AppearanceModuleEnum.FashionMedalState.NotUnLockable
          end
        end
      end
    elseif fashionBondConf.fashion_bond_source == Enum.FashionBondSource.FBS_REWARD then
      if getTime then
        return AppearanceModuleEnum.FashionMedalState.Unlocked
      else
        local bCanGet = false
        local activityObjects = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_CONDITION_GROUP_REWARD)
        if activityObjects and #activityObjects > 0 then
          for i, v in ipairs(activityObjects) do
            if v:IsInProgress() then
              bCanGet = true
              break
            end
          end
        end
        if bCanGet then
          return AppearanceModuleEnum.FashionMedalState.UnLockable
        else
          return AppearanceModuleEnum.FashionMedalState.NotUnLockable
        end
      end
    end
  end
  return AppearanceModuleEnum.FashionMedalState.NotShow
end

function UMG_GorgeousMedal_C:MedalSortHandle(medalList)
  if not medalList then
    return nil
  end
  local curSort = self.sortTypeList[self.curSortIndex].type
  local n = #medalList
  for i = 1, n - 1 do
    for j = 1, n - i do
      local a = medalList[j]
      local b = medalList[j + 1]
      if not a or not b then
      else
        local aValue = 0
        local bValue = 0
        if curSort == AppearanceModuleEnum.FashionMedalSortType.UnLockTime then
          aValue = a.getTime or 1.0E20
          bValue = b.getTime or 1.0E20
        elseif curSort == AppearanceModuleEnum.FashionMedalSortType.Pet then
          local aConf = _G.DataConfigManager:GetFashionSuitsConf(a.suitId, true)
          if aConf and aConf.petbase_id and aConf.petbase_id[1] then
            aValue = aConf.petbase_id[1]
          end
          local bConf = _G.DataConfigManager:GetFashionSuitsConf(b.suitId, true)
          if bConf and bConf.petbase_id and bConf.petbase_id[1] then
            bValue = bConf.petbase_id[1]
          end
        elseif curSort == AppearanceModuleEnum.FashionMedalSortType.Style then
          aValue = a.conf and a.conf.fashion_bond_quality or 0
          bValue = b.conf and b.conf.fashion_bond_quality or 0
        end
        local shouldSwap = false
        if aValue == bValue then
          local aConf = _G.DataConfigManager:GetFashionSuitsConf(a.suitId, true)
          if aConf and aConf.petbase_id and aConf.petbase_id[1] then
            aValue = aConf.petbase_id[1]
          end
          local bConf = _G.DataConfigManager:GetFashionSuitsConf(b.suitId, true)
          if bConf and bConf.petbase_id and bConf.petbase_id[1] then
            bValue = bConf.petbase_id[1]
          end
        end
        if self.bReverseSort then
          shouldSwap = aValue < bValue
        else
          shouldSwap = aValue > bValue
        end
        if shouldSwap then
          medalList[j], medalList[j + 1] = medalList[j + 1], medalList[j]
        end
      end
    end
  end
  return medalList
end

function UMG_GorgeousMedal_C:GetCollectionProgress()
  if not self.MedalInfoMap[self.curTabType] then
    return 0, 0
  end
  local getNum = 0
  local allNum = #self.MedalInfoMap[self.curTabType]
  for i, v in pairs(self.MedalInfoMap[self.curTabType]) do
    if v.getTime then
      getNum = getNum + 1
    end
  end
  return getNum, allNum
end

function UMG_GorgeousMedal_C:OnPlayerDataUpdate()
  self:SetMoneyUIShow()
end

function UMG_GorgeousMedal_C:OnBagChange()
  self:SetMoneyUIShow()
end

function UMG_GorgeousMedal_C:RefreshTabList()
  local medalTypeList = {}
  for i, v in pairs(self.MedalInfoMap) do
    table.insert(medalTypeList, i)
  end
  self.Appearance_Tab1:InitGridView(medalTypeList)
end

function UMG_GorgeousMedal_C:RefreshMedalList(type, clearSelect)
  self.curTabType = type
  self.curTabConf = _G.DataConfigManager:GetBondTabConf(type)
  if clearSelect then
    self.curSelectMedal = nil
  end
  local sortedData = self:MedalSortHandle(self.MedalInfoMap[type]) or {}
  local curSelectMedalId = self.curSelectMedal and self.curSelectMedal.conf.id or 0
  self.MedalList:ClearSelection()
  self.MedalList:SetCustomData({curSelectMedalId = curSelectMedalId})
  self.MedalList:InitList(sortedData)
  for i, v in pairs(sortedData) do
    if v.conf.id == curSelectMedalId then
      self.MedalList:SelectItemByIndex(i - 1)
    end
  end
end

function UMG_GorgeousMedal_C:RefreshLeftView()
  local type = self.curTabType
  local uiSet = self.collectionProgressUIList[type]
  local getNum, allNum = self:GetCollectionProgress()
  if uiSet then
    if uiSet.BrandDescriptionText and self.curTabConf then
      uiSet.BrandDescriptionText:SetText(self.curTabConf.band_long_text)
    end
    if uiSet.CollectProgressText then
      uiSet.CollectProgressText:SetText(getNum .. "/" .. allNum)
    end
    if uiSet.CollectProgressBar then
      if getNum > 0 and allNum > 0 then
        uiSet.CollectProgressBar:SetPercent(getNum / allNum)
      else
        uiSet.CollectProgressBar:SetPercent(0)
      end
    end
  else
    Log.Error("UMG_GorgeousMedal_C uiSet is nil")
  end
  self.Description:SetActiveWidgetIndex(type - 1)
  self.DecorativeDesign:SetPath("Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Medal/img_bond_mark_" .. type .. ".img_bond_mark_" .. type .. "'")
  self.BrandIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Appearance/Raw/Frames/img_bond_btn_" .. type .. "_png.img_bond_btn_" .. type .. "_png'")
  self.CardImage:SetPath("Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Medal/img_kapai_" .. type .. ".img_kapai_" .. type .. "'")
end

function UMG_GorgeousMedal_C:RefreshRightView(medalInfo)
  if medalInfo then
    local petName = ""
    if medalInfo.conf.petbase_id and #medalInfo.conf.petbase_id > 0 then
      petName = (_G.DataConfigManager:GetPetbaseConf(medalInfo.conf.petbase_id[1]) or {}).name or ""
    end
    self.TextTitle:SetText(petName)
    self.Subtitle:SetText("")
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(medalInfo.suitId, true)
    if suitConf then
      self.TextTitle:SetText(suitConf.name)
      self.Icon:SwitchToSetBrushFromMaterialInstanceMode(medalInfo.state ~= AppearanceModuleEnum.FashionMedalState.Unlocked and medalInfo.state ~= AppearanceModuleEnum.FashionMedalState.NotUpgraded)
      self.Icon:SetPath(suitConf.suits_icon)
      if medalInfo.conf.fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
        self.Icon:SetVisibility(medalInfo.state == AppearanceModuleEnum.FashionMedalState.NotUnLockable and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
      end
      local packageId = suitConf and suitConf.package_id
      local packageConf = _G.DataConfigManager:GetFashionPackageConf(packageId, true)
      if packageConf then
        self.Subtitle:SetText(packageConf.name)
      end
    end
    self.Image_Icon:SetPath(medalInfo.conf.fashion_bond_big_icon)
    self.Projection:SetPath(medalInfo.conf.fashion_bond_big_icon)
    self.FX_Icon_light:SetPath(medalInfo.conf.fashion_bond_big_icon)
    self.Fx_icon_light2:SetPath(medalInfo.conf.fashion_bond_big_icon)
    if medalInfo.conf.fashion_bond_big_icon then
      self.Image_Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Projection:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.FX_Icon_light:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.FX_Icon_light2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Image_Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Projection:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.FX_Icon_light:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.FX_Icon_light2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.MedalStyle:SetText(medalInfo.conf.fashion_bond_style)
    if self.curTabConf then
      self.ForgeBrand:SetText(self.curTabConf.band_name)
      self.DetailedStructure:SetText(self.curTabConf.band_short_text)
    else
      self.ForgeBrand:SetText("")
      self.DetailedStructure:SetText("")
    end
    self.DetailsIntroduction:SetText(medalInfo.conf.exhibit_text)
    if medalInfo.conf.fashion_bond_source == Enum.FashionBondSource.FBS_REWARD then
      self.NRCText_7:SetText(LuaText.dimo_fashion_bond_unlocked_text)
    else
      self.NRCText_7:SetText(LuaText.fashion_bond_unlocked_word)
    end
    self.NRCText_7:SetAutoWrapText(true)
    if medalInfo.getTime then
      local competeTimeDetail = ActivityUtils.ToTimeDetailData(medalInfo.getTime)
      self.UnlockTime:SetText(competeTimeDetail.year .. "/" .. competeTimeDetail.month .. "/" .. competeTimeDetail.day)
    else
      self.UnlockTime:SetText(LuaText.fashion_bond_unlocked_tips)
    end
    local btnIndex = 0
    self.NRCSwitcher_2:SetActiveWidgetIndex(0)
    if medalInfo.state == AppearanceModuleEnum.FashionMedalState.Unlocked then
      btnIndex = 3
    elseif medalInfo.state == AppearanceModuleEnum.FashionMedalState.NotUpgraded then
      btnIndex = 2
    elseif medalInfo.state == AppearanceModuleEnum.FashionMedalState.UnLockable then
      btnIndex = 1
      self.NRCSwitcher_2:SetActiveWidgetIndex(1)
    elseif medalInfo.state == AppearanceModuleEnum.FashionMedalState.NotUnLockable then
      btnIndex = 0
      self.NRCSwitcher_2:SetActiveWidgetIndex(1)
    end
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(btnIndex)
  end
end

function UMG_GorgeousMedal_C:SetMoneyUIShow()
  local viConf = _G.DataConfigManager:GetFashionViConf(3)
  if not viConf then
    return
  end
  local sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNumByType(viConf.goods_type, viConf.goods_id)
  local costGoodType = viConf.goods_type
  local bShowBuyIcon = false
  if costGoodType == _G.Enum.GoodsType.GT_VITEM then
    bShowBuyIcon = viConf.goods_id == Enum.VisualItem.VI_COUPON or viConf.goods_id == Enum.VisualItem.VI_DIAMOND or viConf.goods_id == Enum.VisualItem.VI_PIKA_POINT
  end
  local moneyInfo = {}
  table.insert(moneyInfo, {
    moneyType = viConf.goods_type,
    currencyId = viConf.goods_id,
    currencyType = viConf.goods_type,
    sum = sumMoneyNum,
    showColor = 0,
    IsShowBuyIcon = bShowBuyIcon,
    bigIcon = false
  })
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_GorgeousMedal_C:SetSortUIShow()
  local dropDownListInfo = {}
  for i = 1, #self.sortTypeList do
    table.insert(dropDownListInfo, {
      ComType = CommonBtnEnum.ComboBoxType.GorgeousMedal,
      name = self.sortTypeList[i].name,
      isHideRedDot = true
    })
  end
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  CommonDropDownListData.DropDownListInfo = dropDownListInfo
  CommonDropDownListData.DropDownListIndex = self.curSortIndex
  CommonDropDownListData.DropDownListText = self.sortTypeList[self.curSortIndex].name
  CommonDropDownListData.ComType = CommonBtnEnum.ComboBoxType.GorgeousMedal
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_RightHandler = self.OnReverseSortHandle
  self.ComboBox_White:SetPanelInfo(CommonDropDownListData)
  self.ComboBox_White.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ComboBox_White.bShowList = true
  self:CloseComboboxList()
end

function UMG_GorgeousMedal_C:SelectMedalById(medalId)
  for i = 1, self.MedalList:GetItemCount() do
    local item = self.MedalList:GetItemByIndex(i - 1)
    if item and item.uiData and item.uiData.conf.id == medalId then
      item:OnItemSelected(true)
      self.MedalList:SelectItemByIndex(i - 1)
      break
    end
  end
end

function UMG_GorgeousMedal_C:ClearCurTabRedPoint()
  local count = self.MedalList:GetItemCount()
  if count > 0 then
    for i = 1, count do
      local item = self.MedalList:GetItemByIndex(i - 1)
      if item then
        item.RedDot:EraseRedPoint()
      end
    end
  end
end

function UMG_GorgeousMedal_C:OnCloseBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_GorgeousMedal_C:OnCloseBtnClick")
  self:CloseComboboxList()
  self.bIsGoToOtherPanel = false
  self:PlayCloseAnim()
end

function UMG_GorgeousMedal_C:OnBrandIconBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40010019, "UMG_GorgeousMedal_C:OnBrandIconBtnClick")
  self:CloseComboboxList()
  if self.bLeftPanelShow then
    self:PlayAnimation(self.Page_in)
  else
    self:PlayAnimation(self.Word_change_out)
    self:PlayAnimation(self.Details_panel_out)
  end
  self:RefreshLeftView()
end

function UMG_GorgeousMedal_C:OnBrandIconBtnPressed()
  self:PlayAnimation(self.BrandIcon_press)
end

function UMG_GorgeousMedal_C:OnBrandIconBtnReleased()
  self:PlayAnimation(self.BrandIcon_up)
end

function UMG_GorgeousMedal_C:OnNotUnlockedBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_GorgeousMedal_C:OnNotUnlockedBtnClick")
  self:CloseComboboxList()
  if self.curSelectMedal then
    local medalInfo = self.curSelectMedal
    if medalInfo.conf.fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.tips_notice_fashion_bond_lock)
    elseif medalInfo.conf.fashion_bond_source == Enum.FashionBondSource.FBS_REWARD then
    end
  end
end

function UMG_GorgeousMedal_C:OnToUnlockBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_GorgeousMedal_C:OnToUnlockBtnClick")
  self:CloseComboboxList()
  if self.curSelectMedal then
    if self.curSelectMedal.conf.fashion_bond_source == Enum.FashionBondSource.FBS_REWARD then
      _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenMainPanel, Enum.ActivityType.ATP_CONDITION_GROUP_REWARD)
    elseif self.curSelectMedal.conf.fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
      local voucherId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetExchangeVoucherIdBySuitId, self.curSelectMedal.suitId)
      if voucherId then
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, voucherId)
        if bagItem then
          _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanelByTableIndex, 3, voucherId)
          self.bIsGoToOtherPanel = true
          self:PlayCloseAnim()
          return
        end
      end
      local goodsShopConf = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetNormalShopConfBySuitId, self.curSelectMedal.suitId)
      if goodsShopConf then
        local svrTime = _G.ZoneServer:GetServerTime() or 0
        if goodsShopConf.enable then
          local startTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.enable_time) * 1000
          local endTimeStamp = ActivityUtils.ToTimestamp(goodsShopConf.disable_time) * 1000
          if svrTime > startTimeStamp and (svrTime < endTimeStamp or 0 == endTimeStamp) then
            self.bIsGoToOtherPanel = true
            self:PlayCloseAnim()
            _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShop, AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG)
            return
          end
        end
        local exchangeGoodsId = self:CheckSuitInExchangeShop(self.curSelectMedal.suitId)
        if exchangeGoodsId then
          self.bIsGoToOtherPanel = true
          self:PlayCloseAnim()
          _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OpenMainPanel, 3)
          return
        end
      end
    end
  end
end

function UMG_GorgeousMedal_C:CheckSuitInExchangeShop(suitId)
  local goodsId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetExchangeGoodsIdBySuitId, suitId)
  if not goodsId then
    return nil
  end
  local goodsData = _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION, goodsId, true)
  if goodsData then
    Log.Info(string.format("UMG_GorgeousMedal_C:CheckSuitInExchangeShop suitId=%d found in exchange shop, goodsId=%d", suitId, goodsId))
    return goodsId
  end
  return nil
end

function UMG_GorgeousMedal_C:OnUpgradeBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_GorgeousMedal_C:OnUpgradeBtnClick")
  self:CloseComboboxList()
  if self.curSelectMedal then
    self.bIsGoToOtherPanel = true
    self:PlayCloseAnim()
    self:DispatchEvent(AppearanceModuleEvent.SetAppearanceTabSelectedIndex, 0)
    self:DelayFrames(2, function()
      local closetPanel = self.module:GetPanel("AppearanceCloset")
      if closetPanel then
        closetPanel:GoToSuitUpgrade(self.curSelectMedal.suitId, true)
      end
    end)
  end
end

function UMG_GorgeousMedal_C:OnUpgradeComponentOpen()
  self:StopAllAnimations()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_GorgeousMedal_C:OnUpgradeComponentClose(bSkipSetVisibility)
  self:StopAllAnimations()
  local medalId
  if self.curSelectMedal then
    medalId = self.curSelectMedal.conf.id
  end
  self.skipTabAndBondSelectAudio = true
  if bSkipSetVisibility then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:OnActive(medalId)
  end
  self.skipTabAndBondSelectAudio = false
  _G.NRCAudioManager:PlaySound2DAuto(40010017, "UMG_GorgeousMedal_C:OnUpgradeComponentClose")
end

function UMG_GorgeousMedal_C:OnParticularsBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_GorgeousMedal_C:OnParticularsBtnClick")
  self:CloseComboboxList()
  if self.curSelectMedal then
    local context = {
      bIsShiningMedal = true,
      title = LuaText.popup_magic_award,
      image = self.playerGender == Enum.ESexValue.SEX_MALE and self.curSelectMedal.conf.fashion_bond_album_male or self.curSelectMedal.conf.fashion_bond_album_female,
      leftImage = self.curSelectMedal.conf.fashion_bond_icon,
      desc = self.curSelectMedal.conf.popup_text,
      bondId = self.curSelectMedal.conf.id
    }
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenShiningMedalDetailPanel, context)
  end
end

function UMG_GorgeousMedal_C:OnTabSelected(type)
  self:CloseComboboxList()
  if not self.skipTabAndBondSelectAudio then
    _G.NRCAudioManager:PlaySound2DAuto(40010019, "UMG_GorgeousMedal_C:OnTabSelected")
  end
  local bTapChange = self.curTabType ~= type
  if bTapChange then
    self:ClearCurTabRedPoint()
    self:RefreshMedalList(type, true)
  else
    self:RefreshMedalList(type, false)
  end
  if not self.skipSelectAnim then
    if self.bLeftPanelShow then
      self:PlayAnimation(self.Page_in)
    elseif bTapChange then
      self:PlayAnimation(self.Word_change_out)
      self:PlayAnimation(self.Details_panel_out)
    else
      self:PlayAnimation(self.Word_change_in)
    end
  end
  self:RefreshLeftView()
end

function UMG_GorgeousMedal_C:OnBondSelected(medalInfo)
  self:CloseComboboxList()
  if self.curSelectMedal == medalInfo and not self.bLeftPanelShow then
    return
  end
  local bondClass = _G.Enum.FashionBondQuality.FBQ_A
  if medalInfo.conf then
    bondClass = medalInfo.conf.fashion_bond_quality
  end
  self:UpdateDetailButton(medalInfo.conf.fashion_bond_quality)
  if self.bLeftPanelShow and not self.skipSelectAnim then
    self:PlayAnimation(self.Details_panel_open)
    if not self.skipTabAndBondSelectAudio then
      _G.NRCAudioManager:PlaySound2DAuto(40010017, "UMG_GorgeousMedal_C:OnBondSelected")
    end
  else
    self:PlayAnimation(self.Word_change_in)
  end
  self.curSelectMedal = medalInfo
  self:RefreshRightView(medalInfo)
end

function UMG_GorgeousMedal_C:OnReverseSortHandle()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_GorgeousMedal_C:OnReverseSortHandle")
  self.bReverseSort = not self.bReverseSort
  self:RefreshMedalList(self.curTabType, false)
end

function UMG_GorgeousMedal_C:OnGorgeousMedalSortChange(index)
  if self.curSortIndex == index then
    return
  end
  self.curSortIndex = index
  self:RefreshMedalList(self.curTabType, false)
end

function UMG_GorgeousMedal_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self:CloseComboboxList()
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_GorgeousMedal_C:CloseComboboxList()
  if self.ComboBox_White.bShowList then
    self.ComboBox_White:SetPopupVisible(false)
  end
end

function UMG_GorgeousMedal_C:PlayOpenAnim()
  if self.curSelectMedal then
    self:PlayAnimation(self.In2)
  else
    self:PlayAnimation(self.In)
  end
end

function UMG_GorgeousMedal_C:PlayCloseAnim()
  if self.curSelectMedal then
    self:PlayAnimation(self.Out2)
  else
    self:PlayAnimation(self.Out)
  end
end

function UMG_GorgeousMedal_C:OnAnimationStarted(Anim)
  if Anim == self.Details_panel_open then
    self.bLeftPanelShow = false
  elseif Anim == self.In then
    self.bLeftPanelShow = true
  elseif Anim == self.Page_in then
    self.bLeftPanelShow = true
  elseif Anim == self.Details_panel_out then
    self.bLeftPanelShow = true
  end
  if self.bLeftPanelShow then
    self.BrandIconBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BrandIconBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_GorgeousMedal_C:OnAnimationFinished(Anim)
  if self.isDestruct then
    return
  end
  if Anim == self.Out or Anim == self.Out2 then
    if self.bIsGoToOtherPanel then
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self:ClearCurTabRedPoint()
      self:DoClose()
    end
  elseif Anim == self.Details_panel_open then
    self:PlayAnimation(self.Icon_loop)
  elseif Anim == self.Icon_loop then
    self:PlayAnimation(self.Icon_loop)
  elseif Anim == self.Word_change_in then
    self:PlayAnimation(self.Icon_loop)
  end
end

function UMG_GorgeousMedal_C:UpdateDetailButton(bondClass)
  if bondClass == _G.Enum.FashionBondQuality.FBQ_S then
    self.Particulars:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Intimate:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Particulars:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Intimate:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_GorgeousMedal_C

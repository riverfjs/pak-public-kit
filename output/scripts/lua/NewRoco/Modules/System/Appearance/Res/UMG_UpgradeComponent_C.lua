local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local UMG_UpgradeComponent_C = _G.NRCPanelBase:Extend("UMG_UpgradeComponent_C")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")

function UMG_UpgradeComponent_C:OnConstruct()
end

function UMG_UpgradeComponent_C:OnActive(showItemList, parentPanel, suitInfo, defaultSelectIndex)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTopExclusionPanel, AppearanceModuleEnum.ExclusionPanelType.UpgradeComponent)
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnUpgradeComponentOpen)
  self:OnAddEventListener()
  self.BecameEffective:SetIsEnabled(false)
  self.BecameEffective.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  self.showItemInfo = showItemList
  self.parent = parentPanel
  self.suitInfo = suitInfo
  self.detailSuitId = self.suitInfo.suitId
  self.curSelectedItem = nil
  self.enableTouch = true
  self.bHasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, self.detailSuitId)
  self.bEnableWearReq = true
  self.medalId = nil
  self.bIsPlayingMedalAnim = false
  self.bTouchEnded = true
  self.bIsEnoughForUpgrade = false
  self.defaultSelectIndex = defaultSelectIndex
  self.selectedItemStack = {}
  self.titleAndButtonStateStack = {}
  local sgSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, self.suitInfo.suitId)
  self.titleAndButtonStateStack[1] = {
    itemId = self.suitInfo.suitId,
    type = _G.Enum.GoodsType.GT_FASHION_SUITS,
    mainTitle = self.suitInfo.suitTitle,
    subTitle = self.suitInfo.packageTitle,
    bShowDetail = true,
    bShowGorgeous = sgSuitId == self.suitInfo.suitId,
    gorgeousType = 0
  }
  self:InitPanel()
  self:SetCommonTitle()
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.SetCustomCloseAnim, "Out_WithoutBg")
end

function UMG_UpgradeComponent_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.ResetCloseAnim)
  if _G.GlobalConfig.DebugOpenUI then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
    return
  end
end

function UMG_UpgradeComponent_C:OnAddEventListener()
  self:AddButtonListener(self.GorgeousMagicBtn, self.OnClickGorgeousMagicBtn)
  self:AddButtonListener(self.Return.btnClose, self.OnClickReturnBtn)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnClickDetailBtn)
  self:AddButtonListener(self.Btn_UpgradeUnlock.btnLevelUp, self.OnClickUnlockBtn)
  self:AddButtonListener(self.Btn_ViewDetails.btnLevelUp, self.OnClickMedalDetailBtn)
  self:AddButtonListener(self.Btn_ViewDetails_1.btnLevelUp, self.OnClickMedalDetailBtn)
  self:AddButtonListener(self.Btn_ViewDetails_2.btnLevelUp, self.OnClickMedalDetailBtn)
  self:AddButtonListener(self.Ununlocked.btnLevelUp, self.OnClickUnunlockBtn)
  self:AddButtonListener(self.Btn_MyMedal.btnLevelUp, self.OnClickMyMedalBtn)
  self:AddButtonListener(self.GorgeousBadgeBtn, self.OnMedalCloudClicked)
  self:AddButtonListener(self.BtnWear.btnLevelUp, self.OnClickWearBtn)
  self:AddButtonListener(self.Btn_Demount.btnLevelUp, self.OnClickDemountBtn)
  _G.NRCEventCenter:RegisterEvent("UMG_UpgradeComponent_C", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
  _G.NRCEventCenter:RegisterEvent("UMG_UpgradeComponent_C", self, AppearanceModuleEvent.OnGorgeousMedalOpen, self.OnGorgeousMedalOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_UpgradeComponent_C", self, AppearanceModuleEvent.OnGorgeousMedalClose, self.OnGorgeousMedalClose)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_UpgradeComponent_C", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:RegisterEvent("UMG_UpgradeComponent_C", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
end

function UMG_UpgradeComponent_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnGorgeousMedalOpen, self.OnGorgeousMedalOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnGorgeousMedalClose, self.OnGorgeousMedalClose)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
end

function UMG_UpgradeComponent_C:OnReConnectStart()
  if UE.UObject.IsValid(self) then
    self:StopAllAnimations()
    self:PlayAnimation(self.Close)
  end
end

function UMG_UpgradeComponent_C:OnGorgeousMedalOpen()
  if not UE.UObject.IsValid(self) then
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_UpgradeComponent_C:OnGorgeousMedalClose()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:PlayAnimation(self.Open)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_UpgradeComponent_C:OnPlayerDataUpdate()
  self:UpdateMoney()
  for i = 0, self.ItemList_4:GetItemCount() - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    item:UpdateCurrency()
  end
end

function UMG_UpgradeComponent_C:OnBagChange()
  self:UpdateMoney()
  for i = 0, self.ItemList_4:GetItemCount() - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    item:UpdateCurrency()
  end
end

function UMG_UpgradeComponent_C:OnConstruct()
  self.data = self.module:GetData("AppearanceModuleData")
end

function UMG_UpgradeComponent_C:OnDestruct()
  self:OnRemoveEventListener()
  local isOpen = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.AppearanceTryOnPanelIsOpen)
  local bHide = self.parent.bIsFromTryOn == true and isOpen
  self.parent.bIsFromTryOn = false
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnUpgradeComponentClose, bHide)
end

function UMG_UpgradeComponent_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if self.titleConf.title then
    self.Title1:Set_MainTitle(self.titleConf.title)
  end
  if self.titleConf.head_icon then
    self.Title1:SetBg(self.titleConf.head_icon)
  end
  if self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
end

function UMG_UpgradeComponent_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if not self.enableTouch then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  self.TouchStartTime = 0
  UpdateManager:Register(self)
  if not self.bTouchEnded then
    self.bTouchEnded = true
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_UpgradeComponent_C:LuaOnTouchMoved(dir)
  if not self.enableTouch then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  if self.TouchStartTime and self.TouchStartTime < 0.1 then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  if self.bTouchEnded then
    self.bTouchEnded = false
  end
  self.module:SetAvatarRotation(dir.X, self.module.closetAvatarPlayer)
end

function UMG_UpgradeComponent_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if not self.enableTouch then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  self.TouchStartTime = 0
  UpdateManager:UnRegister(self)
  if not self.bTouchEnded then
    self.bTouchEnded = true
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_UpgradeComponent_C:OnTick(deltaTime)
  if self.TouchStartTime then
    self.TouchStartTime = self.TouchStartTime + deltaTime
  end
end

function UMG_UpgradeComponent_C:InitPanel()
  if self.module._bIsPlayingShiningMedalSkill then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayClosetShiningMedalSkillEnd)
  end
  self.bEnableWearReq = false
  self.ItemList_4:ClearSelection()
  self.bEnableWearReq = true
  self.Btn_MyMedal.Title_1:SetText(_G.LuaText.my_fashion_bond_function_btn)
  self.Btn_ViewDetails.Title_1:SetText(_G.LuaText.fashion_bond_func_btn)
  self.Btn_ViewDetails_1.Title_1:SetText(_G.LuaText.fashion_bond_func_btn)
  self.Btn_ViewDetails_2.Title_1:SetText(_G.LuaText.fashion_bond_func_btn)
  for k, v in ipairs(self.showItemInfo) do
    if v.componentData.lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
      self.medalId = v.componentData.lv_item_id
    end
    v.parent = self
  end
  self.ItemList_4:InitGridView(self.showItemInfo)
  self.ItemList_4:SetMultipleChoice(true)
  for i = 0, self.ItemList_4:GetItemCount() - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    if item then
      item:SetEnableSound(false)
    end
  end
  self.CanvasMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, self.suitInfo.suitId)
  self.Title_1:SetText(LuaText.fashion_suits_all_unlock)
  if isUnlockAllComps then
    self.Switcher_66:SetActiveWidgetIndex(1)
    _G.NRCAudioManager:PlaySound2DAuto(40010015, "UMG_UpgradeComponent_C:PlayMaxLevelAnim")
    self:PlayAnimation(self.Level_up)
  else
    self.Switcher_66:SetActiveWidgetIndex(0)
    local unlockCompNum = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitUnlockComponentsNum, self.suitInfo.suitId)
    local totalCompNum = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitComponentsTotalNum, self.suitInfo.suitId)
    local str = string.format("%d/%d", unlockCompNum, totalCompNum)
    self.LevelPrompt:SetText(string.format(_G.LuaText.fashion_suits_unlock_title, str))
  end
  self:UpdateTitleAndButtonStateFromStack()
  local selectionIndices, bHasMedal = self:_GetDefaultSelectionIndices()
  local index = -1
  for k, v in ipairs(self.showItemInfo) do
    if 0 == v.buy_num then
      index = k
      break
    end
  end
  if selectionIndices then
    if not self.defaultSelectIndex and -1 ~= index then
      table.insert(selectionIndices, index - 1)
    end
    if self.defaultSelectIndex then
      if table.include(selectionIndices, self.defaultSelectIndex) then
        table.removeValue(selectionIndices, self.defaultSelectIndex)
      end
      table.insert(selectionIndices, self.defaultSelectIndex)
    end
    for k, v in ipairs(selectionIndices) do
      if k ~= #selectionIndices then
        self.bIsInitSelection = true
        self.ItemList_4:SelectItemByIndex(v)
      else
        self.bIsInitSelection = false
        self.ItemList_4:SelectItemByIndex(v)
      end
    end
  else
    Log.Error("UMG_UpgradeComponent_C selectionIndices is nil")
  end
  for i = 0, self.ItemList_4:GetItemCount() - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    if item then
      item:SetEnableSound(true)
    end
  end
  self:UpdateMoney()
  self:PlayAnimation(self.Open)
end

function UMG_UpgradeComponent_C:OnClickGorgeousMagicBtn()
  if 0 == self.NRCSwitcher_1:GetActiveWidgetIndex() then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicVideoDetailsPanel, Enum.GoodsType.GT_FASHION_SUITS, self.suitInfo.suitId)
  elseif 1 == self.NRCSwitcher_1:GetActiveWidgetIndex() or 2 == self.NRCSwitcher_1:GetActiveWidgetIndex() then
    if self.titleAndButtonStateStack == nil or 0 == #self.titleAndButtonStateStack then
      Log.Error("\230\160\135\233\162\152\230\160\143\228\184\138\228\184\139\230\150\135\230\156\137\233\151\174\233\162\152\239\188\129")
      return
    end
    local element = self.titleAndButtonStateStack[#self.titleAndButtonStateStack]
    if not element then
      Log.Error("\230\160\135\233\162\152\230\160\143\228\184\138\228\184\139\230\150\135\230\156\137\233\151\174\233\162\152\239\188\129")
      return
    end
    local context = {}
    context.bIsPendanta = true
    context.context = {}
    context.context.itemId = element.itemId
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
  end
end

function UMG_UpgradeComponent_C:OnClickMedalDetailBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_UpgradeComponent_C:OnClickMedalDetailBtn")
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.suitInfo.suitId)
  if suitConf then
    local conf = _G.DataConfigManager:GetFashionBondConf(suitConf.bond_id)
    if conf then
      local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      local context = {
        bIsShiningMedal = true,
        title = LuaText.popup_magic_award,
        image = player and player.gender == Enum.ESexValue.SEX_MALE and conf.fashion_bond_album_male or conf.fashion_bond_album_female,
        leftImage = conf.fashion_bond_icon,
        desc = conf.popup_text,
        bondId = suitConf.bond_id
      }
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenShiningMedalDetailPanel, context)
    end
  end
end

function UMG_UpgradeComponent_C:OnClickReturnBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_UpgradeComponent_C:OnAnimationFinished")
  if _G.GlobalConfig.DebugOpenUI then
    self:PlayAnimation(self.Close)
    return
  end
  local selectedIndices = self.ItemList_4:GetSelectedIndex()
  local bShouldShowTips = false
  local size = self.ItemList_4:GetItemCount()
  for i = 0, size - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    if item then
      if item:GetItemType() == _G.Enum.GoodsType.GT_FASHION_SUITS then
        item:RestoreComponent()
      elseif not item.bIsWoreComponent then
        item:RestoreComponent()
      end
    end
    if item and selectedIndices[item.itemIndex] ~= nil and not item.bIsWoreComponent and not bShouldShowTips then
      bShouldShowTips = not _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, i, self.suitInfo.suitId)
    end
  end
  if bShouldShowTips and not self.parent.bDirectToUpgrade and not self.parent.bIsFromTryOn then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.lv_up_dress_fail)
  end
  if self.bIsPlayingMedalAnim then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayClosetShiningMedalSkillEnd)
  end
  local closetAvatar = self.parent.module.closetAvatarPlayer
  self.parent.module:SetPlayerAngle(_G.Enum.FashionLabelType.FLT_TOPS, closetAvatar, "Closet")
  self:StopAllAnimations()
  self:PlayAnimation(self.Close)
end

function UMG_UpgradeComponent_C:OnClickDetailBtn()
  if not self.detailSuitId then
    return
  end
  _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.detailSuitId)
end

function UMG_UpgradeComponent_C:OnClickUnlockBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_UpgradeComponent_C:OnClickUnlockBtn")
  local hasCostMoney = 0
  local price = self:_GetTotalSelectedUpgradeItemCost()
  local currentSelectedItem = self.ItemList_4:GetSelectedItem()
  if currentSelectedItem then
    local k, v = next(currentSelectedItem)
    if v then
      hasCostMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(v.itemData.componentData.lv_cost_type) or 0
    end
  end
  local lockItemList = {}
  if currentSelectedItem then
    for _, item in pairs(currentSelectedItem or {}) do
      local isUnlock = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, item.itemIndex - 1, self.suitInfo.suitId)
      if not isUnlock then
        table.insert(lockItemList, item.itemIndex - 1)
      end
    end
  end
  if price <= hasCostMoney then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnCmdSuitUpgradeToLevelReq, lockItemList, self.suitInfo.suitId)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.fashionmall_no_enough_pikapoint)
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.JudgeUpgradeSuitLevel, price)
  end
end

function UMG_UpgradeComponent_C:OnClickWearBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_UpgradeComponent_C:OnClickWearBtn")
  if self.bHasSuit and self.bEnableWearReq then
    local indices = self:_GetWornComponentIndices(true)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnCmdSuitChangeWoreComponentReq, self.suitInfo.suitId, indices)
  end
end

function UMG_UpgradeComponent_C:OnClickDemountBtn(index)
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_UpgradeComponent_C:OnClickDemountBtn")
  if self.bHasSuit and self.bEnableWearReq then
    local indices = self:_GetWornComponentIndices(false, index)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnCmdSuitChangeWoreComponentReq, self.suitInfo.suitId, indices)
  end
end

function UMG_UpgradeComponent_C:OnClickUnunlockBtn()
  if self.bHasSuit then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.tips_notice_suits_escalate)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.levelup_tips_buy_clothes)
  end
end

function UMG_UpgradeComponent_C:OnClickMyMedalBtn()
  if self.suitInfo then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.suitInfo.suitId)
    if suitConf then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenGorgeousMedalPanel, suitConf.bond_id)
    end
  end
end

function UMG_UpgradeComponent_C:OnUpgradeSuccCallBack()
  self:PlayMaxLevelAnim()
end

function UMG_UpgradeComponent_C:UpdateMoney()
  local viConf = _G.DataConfigManager:GetFashionViConf(2)
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
  local hasCostMoney = 0
  local price = self:_GetTotalSelectedUpgradeItemCost()
  local currentSelectedItem = self.ItemList_4:GetSelectedItem()
  if currentSelectedItem then
    local k, v = next(currentSelectedItem)
    if v then
      hasCostMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(v.itemData.componentData.lv_cost_type) or 0
    end
  end
  if price <= hasCostMoney then
    self.Btn_UpgradeUnlock.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE0FF"))
  else
    self.Btn_UpgradeUnlock.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
  end
end

function UMG_UpgradeComponent_C:RefreshShowItemInfo(suitId)
  if suitId ~= self.suitInfo.suitId then
    return
  end
  for i = 0, self.ItemList_4:GetItemCount() - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    local newBuyNum = 0
    local isUnlock = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, i, self.suitInfo.suitId)
    if isUnlock then
      newBuyNum = 1
    end
    local newData = {parent = self, buy_num = newBuyNum}
    item:UpdateItemInfoByNewData(newData)
  end
  self:UpdateMoney()
  local iconPath, bIsGoods, bFashion, itemType = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetNextLockedItemIconPath, self.suitInfo.suitId)
  local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, self.suitInfo.suitId)
  if isUnlockAllComps then
    self.Switcher_66:SetActiveWidgetIndex(1)
    self.parent:UpdateViewButtonState(true, false, iconPath, bIsGoods, bFashion, itemType, false)
  else
    self.Switcher_66:SetActiveWidgetIndex(0)
    local unlockCompNum = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitUnlockComponentsNum, self.suitInfo.suitId)
    local totalCompNum = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitComponentsTotalNum, self.suitInfo.suitId)
    local str = string.format("%d/%d", unlockCompNum, totalCompNum)
    self.LevelPrompt:SetText(string.format(LuaText.fashion_suits_unlock_title, str))
    self.parent:UpdateViewButtonState(true, true, iconPath, bIsGoods, bFashion, itemType, false)
  end
  self:OnItemSelectionChanged()
end

function UMG_UpgradeComponent_C:PlayMaxLevelAnim()
  local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, self.suitInfo.suitId)
  if isUnlockAllComps then
    self.Switcher_66:SetActiveWidgetIndex(1)
    _G.NRCAudioManager:PlaySound2DAuto(40010015, "UMG_UpgradeComponent_C:PlayMaxLevelAnim")
    self:PlayAnimation(self.Level_up)
  end
end

function UMG_UpgradeComponent_C:UpdateSubTitle(suitId)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if not suitConf then
    return
  end
  self.detailSuitId = suitId
  self.PetTitle:SetText(suitConf.name)
end

function UMG_UpgradeComponent_C:OnItemSelectedCallback(index)
  self.curSelectedItem = self.showItemInfo[index]
end

function UMG_UpgradeComponent_C:OnItemSelectedUpdateLevelUpButton(index, props)
  if 0 == index then
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  elseif 1 == index then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.Btn_UpgradeUnlock:SetCommonText(LuaText.btn_escalate_fashion_item)
    self.Btn_UpgradeUnlock.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_UpgradeUnlock.Tips:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_UpgradeUnlock.DescNum:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_ViewDetails_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if props and props.bShouldShowDetailBtn then
      self.Btn_ViewDetails_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if props and props.buttonText and props.buttonText ~= "" then
      self.Btn_UpgradeUnlock.Title_1:SetText(props.buttonText)
    end
    local selectedIndex = self.ItemList_4._selectedItemIndex or 1
    local selectedItem = self.ItemList_4:GetItemByIndex(selectedIndex - 1)
    local vitemType = _G.Enum.VisualItem.VI_PIKA_POINT
    if selectedItem and selectedItem.GetItemCostType then
      vitemType = selectedItem:GetItemCostType()
    end
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(vitemType)
    self.Btn_UpgradeUnlock.MoneyIcon:SetPath(vItemsConf.bigIcon)
    self.Btn_UpgradeUnlock.Quantity:SetText(props.price)
    self.bIsEnoughForUpgrade = props.bIsEnough
    if props.bIsEnough then
      self.Btn_UpgradeUnlock.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE0FF"))
    else
      self.Btn_UpgradeUnlock.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
    end
  elseif 2 == index then
    self.BtnSwitcher:SetActiveWidgetIndex(2)
    self.Ununlocked:SetCommonText(LuaText.btn_escalate_fashion_item)
    self.Ununlocked:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Ununlocked.MoneyIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Ununlocked.Quantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Ununlocked.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_ViewDetails_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if props and props.bShouldShowDetailBtn then
      self.Btn_ViewDetails_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.Ununlocked.Tips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Ununlocked.Tips:SetText(_G.LuaText.levelup_without_clothes)
    self.Ununlocked.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 3 == index then
  elseif 4 == index then
  elseif 5 == index then
    self.BtnSwitcher:SetActiveWidgetIndex(5)
  end
end

function UMG_UpgradeComponent_C:_IsZoomedIn()
  if self.parent and self.parent.GetUpgradeZoomIn then
    return self.parent:GetUpgradeZoomIn()
  end
  return false
end

function UMG_UpgradeComponent_C:ZoomIn()
  if self:_IsZoomedIn() then
    return
  end
  if self.bIsInitSelection then
    return
  end
  if self.parent and self.parent.SetUpgradeZoomIn then
    self.parent:SetUpgradeZoomIn(true)
  end
end

function UMG_UpgradeComponent_C:ZoomOut()
  if not self:_IsZoomedIn() then
    return
  end
  if self.bIsInitSelection then
    return
  end
  if self.parent and self.parent.SetUpgradeZoomIn then
    self.parent:SetUpgradeZoomIn(false)
  end
end

function UMG_UpgradeComponent_C:OnAnimationFinished(Anim)
  if Anim == self.Close then
    if not self.parent.bDirectToUpgrade then
      local isOpen = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.AppearanceTryOnPanelIsOpen)
      local bAlreadySaved = false
      if self.parent.bIsFromTryOn and isOpen then
        self:SaveCurrentOutfit()
        self:GoBackToTryOnPage()
        bAlreadySaved = true
      end
      if _G.GlobalConfig.DebugOpenUI then
        self:DoClose()
        return
      end
      if self:_IsZoomedIn() then
        if self.parent and self.parent.SetUpgradeZoomIn then
          self.parent:SetUpgradeZoomIn(false)
        else
          self.module:OnCmdPlayMeiRongSkillByType(true)
        end
      end
      if not bAlreadySaved and self.parent.bIsFromTryOn and self.bHasSuit and self.parent and self.parent.OnConfirmBtnClicked then
        self.parent:OnConfirmBtnClicked()
      end
      self:StopAllAnimations()
      self:DoClose()
    elseif self.parent.bDirectToUpgrade then
      local isGorgeousMedalOpen = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GorgeousMedalPanelIsOpen)
      if isGorgeousMedalOpen then
        if self:_IsZoomedIn() then
          if self.parent and self.parent.SetUpgradeZoomIn then
            self.parent:SetUpgradeZoomIn(false)
          else
            self.module:OnCmdPlayMeiRongSkillByType(true)
          end
        end
        self:StopAllAnimations()
        self:DoClose()
      else
        self:SaveCurrentOutfit()
        self:StopAllAnimations()
        self:DoClose()
      end
    end
  elseif Anim == self.Level_up then
    self:PlayAnimation(self.Level_up_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  elseif Anim == self.Cloud_in then
  elseif Anim == self.Cloud_out then
    self:StopAnimation(self.Cloud_loop)
    self.CanvasMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_UpgradeComponent_C:OnSuitChanged(woreIndex, itemId)
  local size = self.ItemList_4:GetItemCount()
  for i = 0, size - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    if item then
      item:OnHeteroChromeMount(woreIndex, itemId)
    end
  end
end

function UMG_UpgradeComponent_C:OnWornComponentChanged(wornComponentIndices, suitId)
  if suitId ~= self.suitInfo.suitId then
    return
  end
  local originalWoreIndices = self:_GetWornComponentIndices()
  local size = self.ItemList_4:GetItemCount()
  for i = 0, size - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    if item then
      item:SetWorePrompt(false)
    end
  end
  if wornComponentIndices then
    for k, v in ipairs(wornComponentIndices) do
      local item = self.ItemList_4:GetItemByIndex(v)
      if item then
        item:SetWorePrompt(true)
      end
    end
  end
  local selectedItem = self.ItemList_4:GetSelectedItem()
  local add, remove = self:_FindDiffComponent(originalWoreIndices, wornComponentIndices)
  for k, v in ipairs(remove) do
    local item = self.ItemList_4:GetItemByIndex(v)
    if item and (item:GetItemType() ~= _G.Enum.GoodsType.GT_FASHION_SUITS or 0 == #add) then
      item:DemountComponent()
    end
  end
  for k, v in ipairs(add) do
    local item = self.ItemList_4:GetItemByIndex(v)
    if item then
      item:MountComponent(true)
    end
  end
end

function UMG_UpgradeComponent_C:_GetWornComponentIndices(bIsWear, index)
  local result = {}
  local size = self.ItemList_4:GetItemCount()
  for i = 0, size - 1 do
    local item = self.ItemList_4:GetItemByIndex(i)
    if item and item:IsComponentWorn() and item:GetItemType() ~= _G.Enum.GoodsType.GT_FASHION_SUITS then
      table.insertUnique(result, i)
    end
  end
  local selfIndex = self.ItemList_4._selectedItemIndex - 1
  if true == bIsWear then
    local items = self.ItemList_4:GetSelectedItem()
    for k, v in pairs(items) do
      if v then
        if v:GetItemType() == _G.Enum.GoodsType.GT_FASHION_SUITS then
          for i = 0, size - 1 do
            local arrElem = self.ItemList_4:GetItemByIndex(i)
            if arrElem and arrElem:GetItemType() == _G.Enum.GoodsType.GT_FASHION_SUITS then
              table.removeValue(result, i)
            end
          end
        end
        if v:GetItemType() == _G.Enum.GoodsType.GT_FASHION_SUITS then
        else
          local isUnlock = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, v.itemIndex - 1, self.suitInfo.suitId)
          if isUnlock then
            table.insertUnique(result, v.itemIndex - 1)
          end
        end
      end
    end
  elseif false == bIsWear then
    table.removeValue(result, index - 1)
  end
  return result
end

function UMG_UpgradeComponent_C:UpdateButtonState(item)
  local type = item:GetItemType()
  local id = item:GetItemId()
  if not item.itemIndex then
    return
  end
  if self.bHasSuit then
    local buttonText = LuaText.fashion_unlock_dress_btn
    local price = self:_GetTotalSelectedUpgradeItemCost()
    local isUnlock = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, item.itemIndex - 1, self.suitInfo.suitId)
    if type == _G.Enum.GoodsType.GT_FASHION_BOND and isUnlock then
      self:OnItemSelectedUpdateLevelUpButton(5)
    else
      local props = {
        price = price,
        bIsEnough = false,
        bShouldShowDetailBtn = type == _G.Enum.GoodsType.GT_FASHION_BOND,
        buttonText = buttonText
      }
      local hasCostMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(item:GetItemCostType()) or 0
      if hasCostMoney >= props.price then
        props.bIsEnough = true
      end
      self:OnItemSelectedUpdateLevelUpButton(1, props)
    end
  else
    local props = {
      bShouldShowDetailBtn = type == _G.Enum.GoodsType.GT_FASHION_BOND,
      itemIndex = item.itemIndex
    }
    self:OnItemSelectedUpdateLevelUpButton(2, props)
  end
end

function UMG_UpgradeComponent_C:OnUpgradeItemClicked(itemData, index)
  local type = itemData.componentData.lv_item_type
  local itemId = itemData.componentData.lv_item_id
  self:PushNewItemToStack(itemId, type)
  table.insert(self.selectedItemStack, index)
  self:OnItemSelectionChanged()
  if type == _G.Enum.GoodsType.GT_FASHION_BOND then
    if not self.bIsInitSelection then
      self:StopAnimation(self.Cloud_out)
      self:StopAnimation(self.Cloud_loop)
      self:StopAnimation(self.Cloud_in)
      self.CanvasMedal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Cloud_in)
      local medalConf = _G.DataConfigManager:GetFashionBondConf(itemId)
      if medalConf then
        if medalConf.fashion_bond_quality == _G.Enum.FashionBondQuality.FBQ_S then
          self:PlayAnimation(self.Cloud_loop_1, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
          self:PlayAnimation(self.Cloud_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
        elseif medalConf.fashion_bond_quality == _G.Enum.FashionBondQuality.FBQ_A then
          self:PlayAnimation(self.Cloud_loop_2, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
        end
      end
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetClosetAvatarAngle, 0)
      self.enableTouch = false
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayClosetShiningMedalSkillStart)
      self.bIsPlayingMedalAnim = true
    end
    local bondConf = _G.DataConfigManager:GetFashionBondConf(itemData.componentData.lv_item_id)
    if bondConf then
      if bondConf.fashion_bond_quality == _G.Enum.FashionBondQuality.FBQ_S then
        self.Switcher_bg:SetActiveWidgetIndex(1)
      else
        self.Switcher_bg:SetActiveWidgetIndex(0)
      end
      local icon = bondConf.fashion_bond_big_icon
      self.Icon:SetPath(icon)
    end
  else
    if self.bIsPlayingMedalAnim then
      self:StopAnimation(self.Cloud_out)
      self:StopAnimation(self.Cloud_loop)
      self:StopAnimation(self.Cloud_in)
      self:PlayAnimation(self.Cloud_out)
      if not self.bIsInitSelection then
        self.enableTouch = true
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayClosetShiningMedalSkillEnd)
        self.bIsPlayingMedalAnim = false
      end
    end
    if itemData.buy_num > 0 then
      self:OnClickWearBtn()
    end
  end
  if type == _G.Enum.GoodsType.GT_SALON then
    self:ZoomIn()
  else
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId, true)
    if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_GLASSES then
      self:ZoomIn()
    else
      self:ZoomOut()
    end
  end
end

function UMG_UpgradeComponent_C:OnUpgradeItemCanceled(itemData, index)
  local type = itemData.componentData.lv_item_type
  local itemId = itemData.componentData.lv_item_id
  self:RemoveItemFromStack(itemId, type)
  table.removeValue(self.selectedItemStack, index)
  self:OnItemSelectionChanged()
  if type == _G.Enum.GoodsType.GT_FASHION_BOND then
    if self.bIsPlayingMedalAnim then
      self:StopAnimation(self.Cloud_out)
      self:StopAnimation(self.Cloud_loop)
      self:PlayAnimation(self.Cloud_out)
      self.enableTouch = true
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayClosetShiningMedalSkillEnd)
      self.bIsPlayingMedalAnim = false
    end
  else
    self:OnClickDemountBtn(index)
  end
end

function UMG_UpgradeComponent_C:_FindDiffComponent(original, current)
  local add = {}
  local remove = {}
  local originalSet = {}
  if original then
    for _, index in ipairs(original) do
      originalSet[index] = true
    end
  end
  local newSet = {}
  if current then
    for _, index in ipairs(current) do
      newSet[index] = true
    end
  end
  if current then
    for _, index in ipairs(current) do
      if not originalSet[index] then
        table.insert(add, index)
      end
    end
  end
  if original then
    for _, index in ipairs(original) do
      if not newSet[index] then
        table.insert(remove, index)
      end
    end
  end
  return add, remove
end

function UMG_UpgradeComponent_C:_GetMaxSelectedIndex()
  local items = self.ItemList_4:GetSelectedItem()
  local index = 0
  for k, v in pairs(items) do
    index = math.max(k, index)
  end
  return index
end

function UMG_UpgradeComponent_C:_GetTotalSelectedUpgradeItemCost()
  local totalPrice = 0
  local selectedItem = self.ItemList_4:GetSelectedItem()
  if selectedItem then
    for k, item in pairs(selectedItem) do
      if item and 0 == item.itemData.buy_num then
        totalPrice = totalPrice + item.itemData.componentData.lv_cost_price
      end
    end
  end
  return totalPrice
end

function UMG_UpgradeComponent_C:_GetDefaultSelectionIndices()
  local suitInfos = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().suit_info
  if not suitInfos then
    return {}, false
  end
  for k, v in ipairs(suitInfos) do
    if v.suit_id == self.suitInfo.suitId and v.components_is_worn then
      local bIncludeMedal = false
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v.suit_id)
      if suitConf and suitConf.lv_up_closet and #suitConf.lv_up_closet > 0 and v.components_is_worn then
        for k1, v1 in ipairs(v.components_is_worn) do
          if suitConf.lv_up_closet[v1 + 1] and suitConf.lv_up_closet[v1 + 1].lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
            bIncludeMedal = true
          end
        end
      end
      local resList = {}
      table.deepCopy(v.components_is_worn, resList)
      table.sort(resList)
      return resList, bIncludeMedal
    end
  end
  return {}, false
end

function UMG_UpgradeComponent_C:OnItemSelectionChanged()
  if #self.selectedItemStack > 0 then
    local item = self.ItemList_4:GetItemByIndex(self.selectedItemStack[#self.selectedItemStack] - 1)
    if item then
      local type = item:GetItemType()
      if item.itemData.buy_num > 0 then
        if type == _G.Enum.GoodsType.GT_FASHION_BOND then
          self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self:UpdateButtonState(item)
        else
          self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateButtonState(item)
      end
    else
      self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateTitleAndButtonStateFromStack()
end

function UMG_UpgradeComponent_C:_GetSaveItemIdList(originalFashionIds, originalSalonIds)
  local suitsUpgradeInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().suit_info
  local wornIndices
  if suitsUpgradeInfo then
    for k, v in ipairs(suitsUpgradeInfo) do
      if v.suit_id == self.suitInfo.suitId then
        wornIndices = v.components_is_worn
      end
    end
  end
  if not wornIndices then
    return originalFashionIds, originalSalonIds
  end
  local curFashionTypeMap = {}
  local curSalonTypeMap = {}
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.suitInfo.suitId)
  if suitConf and suitConf.lv_up_closet and #suitConf.lv_up_closet > 0 then
    for k, v in ipairs(suitConf.lv_up_closet) do
      if v.lv_item_type == _G.Enum.GoodsType.GT_FASHION then
        table.removeValue(originalFashionIds, v.lv_item_id)
      elseif v.lv_item_type == _G.Enum.GoodsType.GT_SALON then
        table.removeValue(originalSalonIds, v.lv_item_id)
      end
    end
  end
  for k, v in ipairs(originalFashionIds) do
    local itemConf = _G.DataConfigManager:GetFashionItemConf(v)
    if itemConf then
      curFashionTypeMap[itemConf.type] = v
    end
  end
  for k, v in ipairs(originalSalonIds) do
    local itemConf = _G.DataConfigManager:GetSalonItemConf(v)
    if itemConf then
      curSalonTypeMap[itemConf.type] = v
    end
  end
  for k, v in ipairs(wornIndices) do
    local item = self.ItemList_4:GetItemByIndex(v)
    if item then
      if item:GetItemType() == _G.Enum.GoodsType.GT_FASHION then
        local itemConf = _G.DataConfigManager:GetFashionItemConf(item:GetItemId())
        if itemConf then
          curFashionTypeMap[itemConf.type] = itemConf.id
        end
      elseif item:GetItemType() == _G.Enum.GoodsType.GT_SALON then
        local itemConf = _G.DataConfigManager:GetSalonItemConf(item:GetItemId())
        if itemConf then
          curSalonTypeMap[itemConf.type] = itemConf.id
        end
      end
    end
  end
  local fashionResult = {}
  local salonResult = {}
  for k, v in pairs(curFashionTypeMap) do
    table.insert(fashionResult, v)
  end
  for k, v in pairs(curSalonTypeMap) do
    table.insert(salonResult, v)
  end
  return fashionResult, salonResult
end

function UMG_UpgradeComponent_C:GoBackToTryOnPage()
  self.module:InitAvatarRotationData(self.module.tempTryOnAvatar, nil, nil, "TryOn")
  local packageId = self.parent.TempPackageId
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenTryOnByPackageId, packageId, self.suitInfo.suitId)
end

function UMG_UpgradeComponent_C:SaveCurrentOutfit()
  if self.parent.bSkipSaveOnExit then
    return
  end
  if (self.parent.bDirectToUpgrade or self.parent.bIsFromTryOn) and self.bHasSuit then
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo and fashionInfo.wardrobe_data and #fashionInfo.wardrobe_data > 0 then
      local index = self.module.data.lastSelectedWardrobeIndex
      if not index or index <= 0 then
        index = (fashionInfo.current_wardrobe_index or 0) + 1
      end
      local fashionIds = {}
      if self.module.data.TempAppearData and #self.module.data.TempAppearData > 0 then
        for k, v in ipairs(self.module.data.TempAppearData) do
          table.insert(fashionIds, v.FashionId)
        end
      else
        local fashionItems = fashionInfo.wardrobe_data[index].wearing_item
        for _, v in pairs(fashionItems or {}) do
          table.insert(fashionIds, v.wearing_item_id)
        end
      end
      local salonIds = {}
      if self.module.data.TempBeautyData and #self.module.data.TempBeautyData > 0 then
        for k, v in ipairs(self.module.data.TempBeautyData) do
          table.insert(salonIds, v.SalonId)
        end
      else
        local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        local gender = 1
        if localPlayer then
          gender = localPlayer.gender
        end
        salonIds = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetAvatarDefaultSalonIdsByGender, gender)
      end
      local newFashionIds, newSalonIds = self:_GetSaveItemIdList(fashionIds, salonIds)
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.BuyAndWearSuitReq, index - 1, newFashionIds, newSalonIds, true)
    end
  end
end

function UMG_UpgradeComponent_C:WearNewComponent()
  self.bEnableWearReq = false
  local indices = self:_GetWornComponentIndices(true)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnCmdSuitChangeWoreComponentReq, self.suitInfo.suitId, indices)
  self.bEnableWearReq = true
  self.bIsInitSelection = false
end

function UMG_UpgradeComponent_C:SetTitleAndButtonState(mainTitleText, subTitleText, bShowDetail, bShowGorgeous, gorgeousType)
  self.PetTitle:SetText(mainTitleText)
  if subTitleText and "" ~= subTitleText then
    self.SuitTitle:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SuitTitle:SetText(subTitleText)
  else
    self.SuitTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if bShowDetail then
    self.Particulars:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Particulars:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if bShowGorgeous then
    self.GorgeousMagicBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    if nil == gorgeousType then
      self:StopAnimation(self.Privilege_loop)
      self.NRCSwitcher_1:SetActiveWidgetIndex(0)
    else
      self:PlayAnimation(self.Privilege_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
      self.NRCSwitcher_1:SetActiveWidgetIndex(gorgeousType)
    end
  else
    self:StopAnimation(self.Privilege_loop)
    self.GorgeousMagicBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_UpgradeComponent_C:PushNewItemToStack(itemId, type)
  if type == _G.Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionItemConf then
      local element = {}
      element.itemId = itemId
      element.type = type
      element.mainTitle = fashionItemConf.name
      element.subTitle = self.suitInfo.suitTitle
      element.bShowDetail = false
      element.bShowGorgeous = fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA
      element.gorgeousType = 2
      if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
        local bagCharmConf = _G.DataConfigManager:GetFashionBagcharmConf(itemId)
        element.bShowGorgeous = bagCharmConf.charm_kind ~= _G.Enum.BagCharm.BGC_NORMALCHARM
        if bagCharmConf and bagCharmConf.charm_kind == _G.Enum.BagCharm.BGC_PETCHARM and 0 ~= bagCharmConf.privilege_effect then
          element.gorgeousType = 1
        end
      end
      table.insert(self.titleAndButtonStateStack, element)
    end
  elseif type == _G.Enum.GoodsType.GT_SALON then
    local salonItemConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if salonItemConf then
      local element = {}
      element.itemId = itemId
      element.type = type
      element.mainTitle = salonItemConf.name
      element.subTitle = self.suitInfo.suitTitle
      element.bShowDetail = false
      element.bShowGorgeous = false
      element.gorgeousType = 0
      table.insert(self.titleAndButtonStateStack, element)
    end
  elseif type == _G.Enum.GoodsType.GT_FASHION_BOND then
    local bondConf = _G.DataConfigManager:GetFashionBondConf(itemId)
    if bondConf then
      local element = {}
      element.itemId = itemId
      element.type = type
      element.mainTitle = bondConf.name
      element.subTitle = self.suitInfo.suitTitle
      element.bShowDetail = false
      element.bShowGorgeous = false
      element.gorgeousType = 0
      table.insert(self.titleAndButtonStateStack, element)
    end
  elseif type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    if suitConf then
      local element = {}
      element.itemId = itemId
      element.type = type
      element.mainTitle = suitConf.name
      element.subTitle = self.suitInfo.suitTitle
      element.bShowDetail = false
      element.bShowGorgeous = false
      element.gorgeousType = 0
      table.insert(self.titleAndButtonStateStack, element)
    end
  end
end

function UMG_UpgradeComponent_C:RemoveItemFromStack(itemId, type)
  if not self.titleAndButtonStateStack or 0 == #self.titleAndButtonStateStack then
    Log.Error("\229\143\179\228\184\138\232\167\146\230\160\135\233\162\152\230\160\136\229\135\186\231\142\176\231\169\186\231\154\132\230\131\133\229\134\181\239\188\140\232\191\153\228\184\141\230\173\163\229\184\184\239\188\129")
    return
  end
  local index = -1
  for k, v in ipairs(self.titleAndButtonStateStack) do
    if v.itemId == itemId and type == v.type then
      index = k
    end
  end
  if -1 ~= index then
    table.remove(self.titleAndButtonStateStack, index)
  end
end

function UMG_UpgradeComponent_C:UpdateTitleAndButtonStateFromStack()
  if not self.titleAndButtonStateStack or 0 == #self.titleAndButtonStateStack then
    Log.Error("\229\143\179\228\184\138\232\167\146\230\160\135\233\162\152\230\160\136\229\135\186\231\142\176\231\169\186\231\154\132\230\131\133\229\134\181\239\188\140\232\191\153\228\184\141\230\173\163\229\184\184\239\188\129")
    return
  end
  local item = self.titleAndButtonStateStack[#self.titleAndButtonStateStack]
  if not item then
    Log.Error("\229\143\179\228\184\138\232\167\146\230\160\135\233\162\152\230\160\136\229\135\186\231\142\176\231\169\186\229\133\131\231\180\160\239\188\140\232\191\153\228\184\141\230\173\163\229\184\184\239\188\129")
    return
  end
  if item.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    self.detailSuitId = item.itemId
  end
  self:SetTitleAndButtonState(item.mainTitle, item.subTitle, item.bShowDetail, item.bShowGorgeous, item.gorgeousType)
end

function UMG_UpgradeComponent_C:OnMedalCloudClicked()
  self:OnClickMedalDetailBtn()
end

return UMG_UpgradeComponent_C

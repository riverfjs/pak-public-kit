local UMG_Shop_CombinationBag_C = _G.NRCPanelBase:Extend("UMG_Shop_CombinationBag_C")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_FASHION_STORE
local ShopTypeFunctionEntrance = {
  [Enum.ShopType.ST_FASHION_PIKA] = Enum.FunctionEntrance.FE_FASHION_BUY_SUITS,
  [Enum.ShopType.ST_FASHION_RANDOM] = Enum.FunctionEntrance.FE_FASHION_BUY_RANDOM_SHOP
}

local function CheckIfBan(shopType, showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  if not isBan and shopType then
    local functionEntrance = ShopTypeFunctionEntrance[shopType]
    if functionEntrance then
      isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, functionEntrance, showMsg)
    end
  end
  return isBan
end

local function CheckIfHide(shopType)
  local isHide = false
  if shopType then
    local functionEntrance = ShopTypeFunctionEntrance[shopType]
    if functionEntrance then
      isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, functionEntrance)
    end
  end
  return isHide
end

function UMG_Shop_CombinationBag_C:OnConstruct()
  self.uiData = {}
  self.bIgnoreSameSelectAction = false
  self.ShowingFashionPackageIndex = 0
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClicked)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnClickGoCheckPackageDetail)
  self:AddButtonListener(self.NRCButton_52, self.OnClickGoCheckPackageDetail)
  self:AddButtonListener(self.ViewBtn.btnLevelUp, self.OnClickBuy)
  self:AddButtonListener(self.GorgeousMagicBtn, self.OnClickedGorgeousMagicBtn)
  self:AddButtonListener(self.ParticularsBtn, self.OnShowRandomDetail)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClicked)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_Shop_CombinationBag_C", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:RegisterEvent("UMG_Shop_CombinationBag_C", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  self.ParticularsBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.RegisterMoneyBtn, "SeasonalCombinationBagShop", self.MoneyBtn)
  self:BindInputAction()
  self.MoneyTypeList = {
    self.MoneyBtn1,
    self.MoneyBtn2,
    self.MoneyBtn3
  }
  self.ShopTypeToTabIndex = {}
  self.TabIndexToShopType = {}
  self.AllItemDataArray = {}
  self.ShopIdHadRequestData = {}
  self.ShopDataLifeTime = {}
  self.LastInvalidDataCauseRequest = {}
  self.RefreshingUI = false
  self.bOnActiveScope = false
  self:SetCommonTitle()
  self.functionBanUIController = FunctionBanUIController()
  do
    local functionBanUIController = self.functionBanUIController
    for shopType, functionEntrance in pairs(ShopTypeFunctionEntrance) do
      functionBanUIController:RegisterCustomCallback(functionEntrance, self.OnShopTabVisibilityChangeHandler, self, shopType)
    end
    if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
      functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnShopTabVisibilityChangeHandler, self, -1)
    end
    functionBanUIController:Activate()
  end
end

function UMG_Shop_CombinationBag_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.RegisterMoneyBtn, "SeasonalCombinationBagShop", self.MoneyBtn, true)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PIKO_FASHION)
  if StateGroup then
    _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.MusicUPanelPlay)
  end
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PIKO_FASHION)
  self:StopCountDown()
  self:StopLeftTabRefreshTimer()
  if self.functionBanUIController then
    self.functionBanUIController:Deactivate()
  end
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
end

function UMG_Shop_CombinationBag_C:OnEnable()
end

function UMG_Shop_CombinationBag_C:OnDisable()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SwitchGorgeousMagicUMG, false)
  self:ReleaseResLoadRequest()
end

function UMG_Shop_CombinationBag_C:OnActive(shopId, param1, oriNetReq, rsp)
  self.bOnActiveScope = true
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PIKO_FASHION)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PIKO_FASHION)
  if StateGroup then
    _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.MusicUPanelPause)
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self:CheckOpenContext()
  _G.NRCAudioManager:PlaySound2DAuto(1365, "UMG_Shop_CombinationBag_C:OnActive")
  self:InitLeftTab(rsp)
  self.ShopIdHadRequestData = {}
  self.LastInvalidDataCauseRequest = {}
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.EraseFashionPackageShopRedPoint)
  self:OnAddEventListener()
  self:OnReceiveShopData(shopId, rsp, param1)
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  self.bOnActiveScope = false
  self:CheckDirectToTryOnPanel()
end

function UMG_Shop_CombinationBag_C:OnDeactive()
  self.bIgnoreSameSelectAction = false
  self:OnRemoveEventListener()
  self:StopCountDown()
  self:StopLeftTabRefreshTimer()
end

function UMG_Shop_CombinationBag_C:OnAddEventListener()
  self:RegisterEvent(self, AppearanceModuleEvent.FashionMallTabClick, self.OnClickTab)
  self:RegisterEvent(self, AppearanceModuleEvent.ReceiveFashionShopData, self.OnReceiveShopData)
  self:RegisterEvent(self, AppearanceModuleEvent.UpdateShowingFashionPackage, self.OnUpdateShowingFashionPackage)
  self:RegisterEvent(self, AppearanceModuleEvent.UpdateFashionMall, self.OnUpdateFashionMall)
end

function UMG_Shop_CombinationBag_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, AppearanceModuleEvent.FashionMallTabClick)
  self:UnRegisterEvent(self, AppearanceModuleEvent.ReceiveFashionShopData)
  self:UnRegisterEvent(self, AppearanceModuleEvent.UpdateShowingFashionPackage)
  self:UnRegisterEvent(self, AppearanceModuleEvent.UpdateFashionMall, self.OnUpdateFashionMall)
end

function UMG_Shop_CombinationBag_C:OnUpdateShowingFashionPackage(index)
  local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
  if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
    return
  end
  local itemData = myItemDataArray[index]
  if nil == itemData and #myItemDataArray > 0 then
    index = 1
  end
  self.ShowingFashionPackageIndex = index
  self:UpdateShowingPackageInfo()
end

function UMG_Shop_CombinationBag_C:UpdateShowingPackageInfo()
  local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
  if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
    return
  end
  local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
  if nil == itemData then
    return
  end
  local fashionGoodsConf = DataConfigManager:GetNormalShopConf(itemData.shopItemId)
  local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(itemData.FashionPackageId, true)
  if fashionGoodsConf and fashionPackageConf then
    local CostGoodsType = fashionGoodsConf.price_goods_type
    local CostGoodsId = fashionGoodsConf.price_goods_id
    local GoodsOriginPrice = fashionGoodsConf.origin_price
    local GoodsRealPrice = fashionGoodsConf.price
    local packageData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.uiData.ShopId, itemData.shopItemId)
    if packageData then
      CostGoodsType = packageData.real_price.goods_type
      CostGoodsId = packageData.real_price.goods_id
      GoodsOriginPrice = packageData.origin_price.num
      GoodsRealPrice = packageData.real_price.num
    else
      Log.Warning("UMG_Shop_CombinationBag_C:UpdateShowingPackageInfo", "packageData is nil", self.uiData.ShopId, itemData.shopItemId)
    end
    local packagePrice, packageFreePrice, bHadOwnEntirePackage, availablePikaPointInPackageContent = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CalcFashionPackagePrice, itemData.FashionPackageId, GoodsRealPrice, self.uiData.ShopId, itemData.shopItemId)
    local pikaPointWouldGet = availablePikaPointInPackageContent
    self.packagePrice = packagePrice
    self.packagePriceGoodsType = CostGoodsType
    self.packagePriceGoodsId = CostGoodsId
    local btnPriceText = ""
    local iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(CostGoodsType, CostGoodsId)
    if bHadOwnEntirePackage then
      self.NRCSwitcher_51:SetActiveWidgetIndex(1)
      btnPriceText = LuaText.tailor_owned_btn
      self.AlreadyOwned.MoneyIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.AlreadyOwned.Quantity:SetText(btnPriceText)
      self.AlreadyOwned.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.ViewBtn:ResetButtonDiscountState()
      self.NRCSwitcher_51:SetActiveWidgetIndex(0)
      btnPriceText = packagePrice
      self.ViewBtn.MoneyIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ViewBtn:SetDiscount(packageFreePrice)
      self.ViewBtn:SetClickAble(true)
      self.ViewBtn:SetAppearanceButtonContext(iconPath, btnPriceText, pikaPointWouldGet)
      self.ViewBtn:SetBtnText(LuaText.tailor_buy_btn)
    end
    if self.bOnActiveScope then
      self.Bg:SetPath(fashionPackageConf.kv_big)
      self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif self:IsAnimationPlaying(self.ContentSwitching) then
      self.Bg:SetPath(fashionPackageConf.kv_big)
      self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Bg_4:SetPath(fashionPackageConf.kv_big)
      self:PlayAnimation(self.ContentSwitching)
    end
  end
  self:UpdateGorgeousMagicBtnVisible()
  self:UpdateBuyButtonTextColor()
end

function UMG_Shop_CombinationBag_C:UpdateShowingFashionInfo()
end

function UMG_Shop_CombinationBag_C:UpdateMoneyBar(shopId)
  if nil == shopId then
    return
  end
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  if nil == shopConf then
    return
  end
  local moneyInfo = {}
  if shopConf.goods then
    local showTypeNum = #shopConf.goods
    for i = 1, showTypeNum do
      local bShowBuyIcon = false
      local costGoodType = shopConf.goods[i].goods_type
      local costGoodId = shopConf.goods[i].goods_id
      if costGoodType == Enum.GoodsType.GT_VITEM then
        bShowBuyIcon = costGoodId == Enum.VisualItem.VI_COUPON or costGoodId == Enum.VisualItem.VI_DIAMOND or costGoodId == Enum.VisualItem.VI_PIKA_POINT
      end
      table.insert(moneyInfo, {
        currencyType = costGoodType,
        currencyId = shopConf.goods[i].goods_id,
        moneyType = costGoodType,
        sum = 0,
        IsShowBuyIcon = bShowBuyIcon
      })
    end
  end
  self.MoneyBtn:InitGridView(moneyInfo)
  self:RefreshMoneyList()
end

function UMG_Shop_CombinationBag_C:ShowTopMoney(DataList, UmgList)
  for i = 1, #UmgList do
    if i > #DataList then
      UmgList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      UmgList[i]:OnActive(DataList[i])
      UmgList[i]:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_Shop_CombinationBag_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_FashionMall")
  if mappingContext then
    mappingContext:BindAction("IA_CloseFashionMallUI", self, "OnPcClose")
    mappingContext:BindAction("IA_CloseFashionMallQuick", self, "OnPcClose")
  end
end

function UMG_Shop_CombinationBag_C:OnPcClose()
  if self:IsAnimationPlaying(self.out) then
    return
  end
  self:OnCloseBtnClicked()
end

function UMG_Shop_CombinationBag_C:OnCloseBtnClicked()
  self:SetPanelReadyToClosed()
  self:PlayAnimation(self.Out)
  _G.NRCAudioManager:PlaySound2DAuto(1220002047, "UMG_Shop_CombinationBag_C:OnCloseBtnClicked")
end

function UMG_Shop_CombinationBag_C:InitLeftTab(_rsp)
  local itemDataArray
  if _rsp and _rsp.shop_data and _rsp.shop_data.goods_data then
    itemDataArray = {
      Enum.ShopType.ST_FASHION_PIKA,
      Enum.ShopType.ST_FASHION_RANDOM,
      Enum.ShopType.ST_FASHION_DISCOUNT
    }
  else
    itemDataArray = {
      Enum.ShopType.ST_FASHION_RANDOM,
      Enum.ShopType.ST_FASHION_DISCOUNT
    }
  end
  for idx, shopType in ipairs(itemDataArray) do
    self.ShopTypeToTabIndex[shopType] = idx
    self.TabIndexToShopType[idx] = shopType
  end
  self.bIsOpenShopPage = true
  self.TabGridView:InitGridView(itemDataArray)
  self.TabGridView:SetItemCanClickChecker(self.CheckTabCanClick, self)
  local discountShopId, nextOpeningDiscountShopId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.FindOpeningFashionShopId, Enum.ShopType.ST_FASHION_DISCOUNT, true)
  if nil == discountShopId then
    self.TabGridView:SetItemCount(#itemDataArray - 1)
  end
  if nil ~= nextOpeningDiscountShopId then
    local refreshTimeStamp
    local nextDiscountShopConf = DataConfigManager:GetShopConf(nextOpeningDiscountShopId)
    if nextDiscountShopConf and nextDiscountShopConf.shop_type == Enum.ShopType.ST_FASHION_DISCOUNT then
      refreshTimeStamp = ActivityUtils.ToTimestamp(nextDiscountShopConf.enable_time)
      local serverTimestamp = ActivityUtils.GetSvrTimestamp()
      local leftTime = refreshTimeStamp - serverTimestamp
      if leftTime > 0 then
        self:StartLeftTabRefreshTimer(refreshTimeStamp)
      end
    end
  end
end

function UMG_Shop_CombinationBag_C:GetSelectedShopId()
  local selectItem = self.TabGridView:GetSelectedItem()
  if selectItem then
    return selectItem.ShopType
  end
  return nil
end

function UMG_Shop_CombinationBag_C:OnClickGoCheckPackageDetail()
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_Shop_CombinationBag_C:OnClickGoCheckPackageDetail")
  if self.uiData.ShopId ~= _G.AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG then
    return
  end
  NRCProfilerLog:NRCClickBtn(true, "AppearanceTryOn")
  local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
  local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
  if itemData then
    local goodsExpireTime
    local goodsConf = _G.DataConfigManager:GetNormalShopConf(itemData.shopLibId)
    if goodsConf then
      goodsExpireTime = ActivityUtils.ToTimestamp(goodsConf.disable_time)
    end
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceTryOn, itemData, nil, nil, goodsExpireTime)
  else
    Log.Error("\229\189\147\229\137\141\231\187\132\229\144\136\229\140\133\230\149\176\230\141\174\228\184\186\231\169\186")
  end
end

function UMG_Shop_CombinationBag_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Shop_CombinationBag_C:OnClickBuy()
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_Shop_CombinationBag_C:OnClickGoCheckPackageDetail")
  local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
  if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
    return
  end
  local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
  if nil == itemData then
    return
  end
  local goodsExpireTime
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(itemData.shopItemId)
  if goodsConf then
    goodsExpireTime = ActivityUtils.ToTimestamp(goodsConf.disable_time)
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionShopConfirm, self.uiData.ShopId, itemData, true, goodsExpireTime)
end

function UMG_Shop_CombinationBag_C:OnClickedGorgeousMagicBtn()
  local sgPkgId = self:GetSGFashionPkgId()
  if sgPkgId > 0 then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicVideoDetailsPanel, Enum.GoodsType.GT_FASHION_PACKAGE, sgPkgId)
  end
end

function UMG_Shop_CombinationBag_C:UpdateGorgeousMagicBtnVisible()
  self.GorgeousMagicBtn:SetVisibility(self:FindMinSGSuitId() and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Shop_CombinationBag_C:FindMinSGSuitId()
  local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
  if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
    return
  end
  local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
  if nil == itemData then
    return
  end
  local minSGSutiId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.FindMinSGSuitId, itemData.FashionPackageId)
  return minSGSutiId
end

function UMG_Shop_CombinationBag_C:GetSGFashionPkgId()
  local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
  if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
    return
  end
  local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
  if nil == itemData then
    return
  end
  return itemData.FashionPackageId
end

function UMG_Shop_CombinationBag_C:OnReceiveShopData(shopId, _rsp, param1)
  if param1 then
    self.param = param1
  end
  if nil == shopId or nil == _rsp then
    return
  end
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  if nil == shopConf then
    Log.Error("\228\184\141\229\173\152\229\156\168\231\154\132\229\149\134\229\159\142id", shopId)
    return
  end
  if shopConf.shop_type ~= _G.Enum.ShopType.ST_FASHION_PIKA and shopConf.shop_type ~= _G.Enum.ShopType.ST_FASHION_RANDOM and shopConf.shop_type ~= _G.Enum.ShopType.ST_FASHION_DISCOUNT then
    self:OnUpdateFashionMall()
    return
  end
  local bPlayChangePageAnim = false
  if shopId ~= self.uiData.ShopId and not self.bOnActiveScope then
    bPlayChangePageAnim = true
  end
  if _rsp and _rsp.shop_data and _rsp.shop_data.goods_data then
    self.uiData.ShopId = shopId
    self.uiData.ShopType = shopConf.shop_type
  else
    self.uiData.ShopId = 104
    self.uiData.ShopType = _G.Enum.ShopType.ST_FASHION_RANDOM
  end
  self.ShopIdHadRequestData[shopId] = true
  self.uiData.Param1 = param1
  self.bIgnoreSameSelectAction = false
  local fashionMallShopIdEnum = _G.AppearanceModuleEnum.FashionMallShopId
  local playerGender = self.module.player.gender
  local pikaActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PIKA)
  local SortPriority = {}
  local priority = 0
  if pikaActivityInst and #pikaActivityInst > 0 then
    local subItemIds = pikaActivityInst[1]:GetPartIds()
    local activityPikaConf = _G.DataConfigManager:GetActivityPikaConf(subItemIds[1])
    if activityPikaConf then
      for idx, genderPackage in ipairs(activityPikaConf.kv_path) do
        if playerGender == genderPackage.gender then
          for idx1, packageId in ipairs(genderPackage.package_id1) do
            SortPriority[packageId] = priority
            priority = priority + 1
            break
          end
        end
      end
    end
  end
  if shopId == fashionMallShopIdEnum.SEASONAL_COMBINATION_BAG then
    local itemDataArray = {}
    if _rsp and _rsp.shop_data and _rsp.shop_data.goods_data then
      for idx, goodsData in ipairs(_rsp.shop_data.goods_data) do
        local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(goodsData.goods_id)
        if nil == fashionGoodsConf then
        elseif fashionGoodsConf.Type ~= Enum.GoodsType.GT_FASHION_PACKAGE then
        else
          local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(fashionGoodsConf.item_id, true)
          local goodsExpireTime = self:GetGoodsExpiredTime(goodsData.goods_id, shopId)
          if fashionPackageConf and playerGender == fashionPackageConf.gender then
            table.insert(itemDataArray, {
              FashionPackageId = fashionGoodsConf.item_id,
              shopId = shopId,
              shopItemId = goodsData.goods_id,
              shopLibId = goodsData.goods_id,
              boughtNum = goodsData.buy_num,
              next_refresh_time = goodsData.next_refresh_time,
              goodsExpireTime = goodsExpireTime
            })
          else
            Log.Warning("\231\154\174\229\141\161\229\149\134\229\159\142\230\149\176\230\141\174\229\188\130\229\184\184\239\188\140\230\128\167\229\136\171\228\184\141\229\140\185\233\133\141", fashionGoodsConf.item_id, playerGender)
          end
        end
      end
    end
    table.sort(itemDataArray, function(a, b)
      local priorityA = SortPriority[a.FashionPackageId] or math.maxinteger
      local priorityB = SortPriority[b.FashionPackageId] or math.maxinteger
      return priorityA < priorityB
    end)
    self:StoreShopItemDataArray(shopId, itemDataArray)
  elseif shopId == fashionMallShopIdEnum.RANDOM_FASHION or shopId == fashionMallShopIdEnum.DISCOUNT_FASHION then
    local itemDataArray = {}
    if _rsp.shop_data.goods_data then
      for idx, goodsData in ipairs(_rsp.shop_data.goods_data) do
        local goodsExpireTime = self:GetGoodsExpiredTime(goodsData.goods_id, shopId)
        table.insert(itemDataArray, {
          bHadRevealed = false,
          shopId = shopId,
          shopItemId = goodsData.goods_id,
          shopLibId = goodsData.goods_id,
          boughtNum = goodsData.buy_num,
          next_refresh_time = goodsData.next_refresh_time,
          goodsExpireTime = goodsExpireTime,
          origin_price_type = goodsData.origin_price and goodsData.origin_price.goods_id or 3,
          origin_price_num = goodsData.origin_price and goodsData.origin_price.num or 0,
          real_price_type = goodsData.real_price and goodsData.real_price.goods_id or 3,
          real_price_num = goodsData.real_price and goodsData.real_price.num or 0
        })
      end
    end
    local cardRevealState = _rsp.shop_data.random_shop_shown_indexes or {}
    for _, cardIdxHadRevealed in ipairs(cardRevealState) do
      if itemDataArray[cardIdxHadRevealed] then
        itemDataArray[cardIdxHadRevealed].bHadRevealed = true
      end
    end
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.SyncCardRevealedState, shopId, cardRevealState)
    self:StoreShopItemDataArray(shopId, itemDataArray)
  end
  self:RefreshUI(true, true, bPlayChangePageAnim, self.param)
end

function UMG_Shop_CombinationBag_C:RefreshUI(DontRequest, bServerDriven, bPlayChangePageAnim, param1)
  self.RefreshingUI = true
  local shopId = self.uiData.ShopId
  local myShopType = self.uiData.ShopType
  if nil == shopId then
    return
  end
  if myShopType == Enum.ShopType.ST_FASHION_PIKA then
    local myData = self:GetShopItemDataArray(shopId)
    self.TabGridView_1:InitGridView(myData)
    self.NRCSwitcher_42:SetActiveWidgetIndex(0)
    self.NRCButton_52:SetVisibility(UE4.ESlateVisibility.Visible)
    local bSpecificSelectingPackage = false
    if param1 and param1 > 0 then
      for idx, itemData in ipairs(myData) do
        if itemData.FashionPackageId == param1 then
          self.TabGridView_1:SelectItemByIndex(idx - 1)
          bSpecificSelectingPackage = true
          break
        end
      end
    end
    if not bSpecificSelectingPackage and #myData > 0 then
      self.TabGridView_1:SelectItemByIndex(0)
    end
    if 1 == #myData then
      self.TabGridView_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.TabGridView_1:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif myShopType == Enum.ShopType.ST_FASHION_RANDOM or myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
    local myData = self:GetShopItemDataArray(shopId)
    if 0 == #myData then
      if self.NRCSwitcher_83 then
        self.NRCSwitcher_83:SetActiveWidgetIndex(1)
      end
      if self.NRCText_45 then
        local text = _G.DataConfigManager:GetLocalizationConf("fashion_shop_everything_null").msg
        if text then
          self.NRCText_45:SetText(text)
        end
      end
    elseif self.NRCSwitcher_83 then
      self.NRCSwitcher_83:SetActiveWidgetIndex(0)
    end
    self.NRCScrollView_99:InitList(myData)
    self.NRCSwitcher_42:SetActiveWidgetIndex(1)
    self.NRCButton_52:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if myShopType == Enum.ShopType.ST_FASHION_RANDOM then
    if self.ParticularsBtn then
      self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.BG_Loop then
      self:PlayAnimation(self.BG_Loop, 0, 0)
    end
  else
    if self.ParticularsBtn then
      self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.BG_Loop then
      self:StopAnimation(self.BG_Loop)
    end
  end
  self:RefreshCommonTitle(myShopType)
  self:UpdateMoneyBar(shopId)
  self:UpdateGorgeousMagicBtnVisible()
  local imagePath
  local imageId = 1
  if myShopType == Enum.ShopType.ST_FASHION_PIKA then
    local myItemDataArray = self:GetShopItemDataArray(shopId)
    if nil ~= self.ShowingFashionPackageIndex and nil ~= myItemDataArray then
      local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
      if itemData then
        local fashionGoodsConf = DataConfigManager:GetNormalShopConf(itemData.shopItemId)
        local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(itemData.FashionPackageId, true)
        if fashionGoodsConf and fashionPackageConf then
          imagePath = fashionPackageConf.kv_big
        end
      end
    end
  elseif myShopType == Enum.ShopType.ST_FASHION_RANDOM then
    imageId = 2
  elseif myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
    imageId = 3
  end
  if nil == imagePath then
    imagePath = string.format(UEPath.FMT_FASHION_SHOP_BG, imageId, imageId)
  end
  if bPlayChangePageAnim then
    self.Bg_4:SetPath(imagePath)
    if self.bOnActiveScope then
      self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:PlayAnimation(self.ChangePage)
  else
    self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Bg:SetPath(imagePath)
    self.Bg_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SyncTabSelected(myShopType)
  self:StartCountDown(DontRequest, bServerDriven)
  self.RefreshingUI = false
end

function UMG_Shop_CombinationBag_C:RefreshCommonTitle(myShopType)
  if 1 == myShopType then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 2 == myShopType then
    self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
  end
end

function UMG_Shop_CombinationBag_C:ChangeShop(newShopId, bForceRequest)
  if nil == newShopId then
    return
  end
  if self.bIgnoreSameSelectAction then
    return
  end
  if bForceRequest or self:IsShopNeedRequest(newShopId) then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, newShopId)
    return
  end
  if not self:IsShopNeedRequest(newShopId) then
    local shopConf = DataConfigManager:GetShopConf(newShopId)
    if nil == shopConf then
      return
    end
    local bChangeToOtherShop = false
    if newShopId ~= self.uiData.ShopId then
      bChangeToOtherShop = true
    end
    local bGiveUpRefresh = not bChangeToOtherShop and self.RefreshingUI
    self.uiData.ShopId = newShopId
    self.uiData.ShopType = shopConf.shop_type
    if not bGiveUpRefresh then
      self:RefreshUI(true, false, bChangeToOtherShop, self.param)
    end
    return
  end
end

function UMG_Shop_CombinationBag_C:SyncTabSelected(shopType)
  if shopType ~= self:GetSelectedShopId() then
    local TabIndex = self.ShopTypeToTabIndex[shopType]
    if nil == TabIndex then
      Log.Error("\230\156\141\229\138\161\229\153\168\228\184\139\229\143\145\228\186\134\229\137\141\231\171\175\233\162\132\232\174\161\228\185\139\229\164\150\231\154\132\230\151\182\232\163\133\229\149\134\229\159\142Type\231\154\132\230\149\176\230\141\174", shopType)
      return
    end
    if not self.bIsOpenShopPage then
      self.bIsOpenShopPage = false
      self.bIgnoreSameSelectAction = true
    end
    self.TabGridView:SelectItemByIndex(TabIndex - 1)
    self.bIgnoreSameSelectAction = false
  end
end

function UMG_Shop_CombinationBag_C:StartCountDown(DontRequest, bServerDriven)
  self:DoCountDown(DontRequest, bServerDriven)
end

function UMG_Shop_CombinationBag_C:StopCountDown()
  if self.CountDownTimerId then
    _G.DelayManager:CancelDelayById(self.CountDownTimerId)
    self.CountDownTimerId = nil
  end
end

function UMG_Shop_CombinationBag_C:DoCountDown(DontRequest, bServerDriven)
  self:StopCountDown()
  local shopId = self.uiData.ShopId
  local myShopType = self.uiData.ShopType
  if nil == shopId or nil == myShopType then
    return
  end
  if nil == DontRequest then
    DontRequest = false
  end
  if nil == bServerDriven then
    bServerDriven = false
  end
  local endTimestamp
  local serverTimestamp = ActivityUtils.GetSvrTimestamp()
  local bEvenBeforeRandomStoreFirstOpen = false
  if myShopType == Enum.ShopType.ST_FASHION_PIKA then
    local myItemDataArray = self:GetShopItemDataArray(shopId)
    if type(myItemDataArray) == "table" and #myItemDataArray > 0 then
      local goodsConf = _G.DataConfigManager:GetNormalShopConf(myItemDataArray[1].shopItemId)
      if goodsConf then
        local endTime = goodsConf.disable_time
        endTimestamp = ActivityUtils.ToTimestamp(endTime)
      end
    end
  elseif myShopType == Enum.ShopType.ST_FASHION_RANDOM then
    local shopConf = DataConfigManager:GetShopConf(shopId)
    if nil == shopConf then
      return
    end
    local startTime = shopConf.refresh_time
    local duration = shopConf.duration
    if nil == startTime or nil == duration then
      return
    end
    local startTimeSecond = ActivityUtils.ToTimestamp(startTime)
    local durationSecond = self:ParseRandomShopDurationSecond(duration)
    if 0 == durationSecond then
      return
    end
    local RefreshRound = (serverTimestamp - startTimeSecond) / durationSecond
    if RefreshRound >= 0 then
      local PreClosestRefreshPoint = startTimeSecond + durationSecond * math.floor(RefreshRound)
      if DontRequest then
        if serverTimestamp < PreClosestRefreshPoint then
          endTimestamp = PreClosestRefreshPoint
        else
          endTimestamp = PreClosestRefreshPoint + durationSecond
        end
      elseif serverTimestamp <= PreClosestRefreshPoint then
        endTimestamp = PreClosestRefreshPoint
      else
        endTimestamp = PreClosestRefreshPoint + durationSecond
      end
    else
      endTimestamp = startTimeSecond
      bEvenBeforeRandomStoreFirstOpen = true
    end
  elseif myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
    local shopConf = DataConfigManager:GetShopConf(self.uiData.ShopId)
    if nil == shopConf then
      return
    end
    endTimestamp = ActivityUtils.ToTimestamp(shopConf.disable_time)
  end
  if nil == endTimestamp or endTimestamp <= 0 then
    return
  end
  endTimestamp = endTimestamp + 1
  if bServerDriven then
    self.ShopDataLifeTime[shopId] = endTimestamp
  end
  local leftTime = math.max(endTimestamp - serverTimestamp, 0)
  local timeStr = self:GetCountDownStr(leftTime)
  if myShopType == Enum.ShopType.ST_FASHION_RANDOM and bEvenBeforeRandomStoreFirstOpen then
    timeStr = LuaText.fashionmall_random_text
  end
  Log.Debug("UMG_Shop_CombinationBag_C:DoCountDown", myShopType, endTimestamp, serverTimestamp, leftTime, DontRequest, bServerDriven)
  if myShopType == Enum.ShopType.ST_FASHION_PIKA then
    self.TimeRemaining_1:SetText(timeStr)
  else
    self.TimeRemaining_3:SetText(timeStr)
  end
  if leftTime > 0 then
    local nextUpdate = math.min(leftTime, 60)
    self.CountDownTimerId = _G.DelayManager:DelaySeconds(nextUpdate, self.DoCountDown, self)
  else
    local shouldRequest = not DontRequest
    local targetShopId = self.uiData.ShopId
    if myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
      targetShopId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.FindOpeningFashionShopId, Enum.ShopType.ST_FASHION_DISCOUNT)
      if nil == targetShopId then
        targetShopId = AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
        self.TabGridView:SetItemCount(2)
      end
    end
    self:ChangeShop(targetShopId, shouldRequest)
  end
end

function UMG_Shop_CombinationBag_C:OnAnimationFinished(anim)
  if anim == self.ChangePage then
    local myShopId = self.uiData.ShopId
    local imageId = 1
    local imagePath
    local myShopType = self.uiData.ShopType
    if myShopType == Enum.ShopType.ST_FASHION_PIKA then
      local myItemDataArray = self:GetShopItemDataArray(myShopId)
      if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
        return
      end
      local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
      if nil == itemData then
        return
      end
      local fashionGoodsConf = DataConfigManager:GetNormalShopConf(itemData.shopItemId)
      local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(itemData.FashionPackageId, true)
      if fashionGoodsConf and fashionPackageConf then
        imagePath = fashionPackageConf.kv_big
      end
    elseif myShopType == Enum.ShopType.ST_FASHION_RANDOM then
      imageId = 2
    elseif myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
      imageId = 3
    end
    if nil == imagePath then
      imagePath = string.format(UEPath.FMT_FASHION_SHOP_BG, imageId, imageId)
    end
    if imagePath then
      self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Bg:SetPath(imagePath)
    end
    self:PlayAnimation(self.Normal)
  elseif anim == self.ContentSwitching then
    local myShopId = self.uiData.ShopId
    local imageId = 1
    local imagePath
    local myShopType = self.uiData.ShopType
    if myShopType == Enum.ShopType.ST_FASHION_PIKA then
      local myItemDataArray = self:GetShopItemDataArray(myShopId)
      if self.ShowingFashionPackageIndex == nil or nil == myItemDataArray then
        return
      end
      local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
      if nil == itemData then
        return
      end
      local fashionGoodsConf = DataConfigManager:GetNormalShopConf(itemData.shopItemId)
      local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(itemData.FashionPackageId, true)
      if fashionGoodsConf and fashionPackageConf then
        imagePath = fashionPackageConf.kv_big
      end
    elseif myShopType == Enum.ShopType.ST_FASHION_RANDOM then
      imageId = 2
    elseif myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
      imageId = 3
    end
    if nil == imagePath then
      imagePath = string.format(UEPath.FMT_FASHION_SHOP_BG, imageId, imageId)
    end
    if imagePath then
      self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Bg:SetPath(imagePath)
    end
    self:PlayAnimation(self.Normal)
  elseif anim == self.Out then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
    _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnShopCombinationBagPanelClosed)
    self:DoClose()
  end
end

function UMG_Shop_CombinationBag_C:GetShopItemDataArray(shopId)
  if nil == shopId then
    return {}
  end
  if nil == self.AllItemDataArray[shopId] then
    self.AllItemDataArray[shopId] = {}
  end
  return self.AllItemDataArray[shopId]
end

function UMG_Shop_CombinationBag_C:StoreShopItemDataArray(shopId, itemDataArray)
  if nil == shopId then
    return false
  end
  self.AllItemDataArray[shopId] = itemDataArray
end

function UMG_Shop_CombinationBag_C:OnClickTab(shopType, tabIndex)
  local isBan = CheckIfBan(shopType, false)
  self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if not self.bOnActiveScope then
    _G.NRCAudioManager:PlaySound2DAuto(1028, "UMG_Shop_CombinationBag_C:OnClickTab")
  end
  local targetShopId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.FindOpeningFashionShopId, shopType)
  if shopType == Enum.ShopType.ST_FASHION_DISCOUNT and nil == targetShopId then
    targetShopId = AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
    self.TabGridView:SetItemCount(2)
  end
  self:ChangeShop(targetShopId)
  self:SendTLogShopAction(targetShopId, shopType, tabIndex)
end

function UMG_Shop_CombinationBag_C:SendTLogShopAction(shopId, TabID, actionType)
  if not (shopId and TabID) or not actionType then
    return
  end
  local key = "ShopInteractionLog"
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local value = string.format("%s|%s|%d|%d|%d", key, roleDataStr, shopId, TabID, actionType - 1)
  Log.Debug("UMG_Shop_CombinationBag_C:SendTLogShopAction", key, value)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function UMG_Shop_CombinationBag_C:OnUpdateFashionMall(shopId)
  if self.uiData == nil then
    return
  end
  self:RefreshUI(true, false, false, self.param)
end

function UMG_Shop_CombinationBag_C:StartLeftTabRefreshTimer(refreshTimeStamp)
  self:OnTimerCheckLeftTabRefresh(refreshTimeStamp)
end

function UMG_Shop_CombinationBag_C:StopLeftTabRefreshTimer()
  if self.LeftTabRefreshTimer then
    _G.DelayManager:CancelDelayById(self.LeftTabRefreshTimer)
    self.LeftTabRefreshTimer = nil
  end
end

function UMG_Shop_CombinationBag_C:OnTimerCheckLeftTabRefresh(refreshTimeStamp)
  self:StopLeftTabRefreshTimer()
  if nil == refreshTimeStamp or refreshTimeStamp <= 0 then
    return
  end
  local serverTimestamp = ActivityUtils.GetSvrTimestamp()
  local leftTime = refreshTimeStamp - serverTimestamp
  if leftTime <= 0 then
    self:InitLeftTab()
  else
    self.LeftTabRefreshTimer = _G.DelayManager:DelaySeconds(leftTime, self.OnTimerCheckLeftTabRefresh, self, refreshTimeStamp)
  end
end

function UMG_Shop_CombinationBag_C:IsShopNeedRequest(shopId)
  self:CheckShopDataLifeTime(shopId)
  return self.ShopIdHadRequestData[shopId] == nil
end

function UMG_Shop_CombinationBag_C:CheckShopDataLifeTime(shopId)
  local lifeTime = self.ShopDataLifeTime[shopId]
  if lifeTime and lifeTime > 0 then
    local serverTimestamp = ActivityUtils.GetSvrTimestamp()
    if lifeTime <= serverTimestamp and serverTimestamp - (self.LastInvalidDataCauseRequest[shopId] or 0) > 60 then
      Log.Debug("UMG_Shop_CombinationBag_C:CheckShopDataLifeTime", lifeTime, serverTimestamp, self.LastInvalidDataCauseRequest[shopId] or 0)
      self.ShopIdHadRequestData[shopId] = nil
      self.ShopDataLifeTime[shopId] = nil
      self.LastInvalidDataCauseRequest[shopId] = serverTimestamp
    end
  end
end

function UMG_Shop_CombinationBag_C:GetCountDownStr(leftTime)
  if 0 == leftTime then
    return LuaText.fashionmall_failed_text
  end
  local timeStr = ActivityUtils.GetTimeFormatStr(leftTime)
  return timeStr
end

function UMG_Shop_CombinationBag_C:ParseRandomShopDurationSecond(duration)
  if type(duration) ~= "string" then
    return 0
  end
  local splitStr = string.split(duration, " ")
  if 2 ~= #splitStr then
    return 0
  end
  local splitDayTimeStr = string.split(splitStr[2], ":")
  if 3 ~= #splitDayTimeStr then
    return 0
  end
  return splitStr[1] * 86400 + splitDayTimeStr[1] * 3600 + splitDayTimeStr[2] * 60 + splitDayTimeStr[3]
end

function UMG_Shop_CombinationBag_C:GetGoodsExpiredTime(shopLibId, shopId)
  if nil == shopId then
    return
  end
  local shopConf = DataConfigManager:GetShopConf(shopId)
  local myShopType = shopConf.shop_type
  local endTimestamp
  local serverTimestamp = ActivityUtils.GetSvrTimestamp()
  if myShopType == Enum.ShopType.ST_FASHION_PIKA then
    local goodsConf = _G.DataConfigManager:GetNormalShopConf(shopLibId)
    if goodsConf then
      local endTime = goodsConf.disable_time
      endTimestamp = ActivityUtils.ToTimestamp(endTime)
    end
  elseif myShopType == Enum.ShopType.ST_FASHION_RANDOM then
    local startTime = shopConf.refresh_time
    local duration = shopConf.duration
    if nil == startTime or nil == duration then
      return
    end
    local startTimeSecond = ActivityUtils.ToTimestamp(startTime)
    local durationSecond = self:ParseRandomShopDurationSecond(duration)
    if 0 == durationSecond then
      return
    end
    local RefreshRound = (serverTimestamp - startTimeSecond) / durationSecond
    if RefreshRound >= 0 then
      local PreClosestRefreshPoint = startTimeSecond + durationSecond * math.floor(RefreshRound)
      if serverTimestamp <= PreClosestRefreshPoint then
        endTimestamp = PreClosestRefreshPoint
      else
        endTimestamp = PreClosestRefreshPoint + durationSecond
      end
    else
      endTimestamp = startTimeSecond
    end
  elseif myShopType == Enum.ShopType.ST_FASHION_DISCOUNT then
    endTimestamp = ActivityUtils.ToTimestamp(shopConf.disable_time)
  end
  return endTimestamp
end

function UMG_Shop_CombinationBag_C:OnShowRandomDetail()
  local DialogContext = DialogContext()
  local Content = LuaText.random_shop_game_rules
  local title = LuaText.random_shop_game_rules_title
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_Pass_Select_C:OnOpenTips")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Shop_CombinationBag_C:CheckTabCanClick(tabItem, tabIndex, userClick)
  if userClick then
    local shopType = self.TabIndexToShopType[tabIndex + 1]
    return not CheckIfBan(shopType, true)
  end
  return true
end

function UMG_Shop_CombinationBag_C:OnShopTabVisibilityChangeHandler(shopType, funcId, bHide)
  local tabIndex = self.TabGridView:GetSelectedIndex() + 1
  if funcId == FunctionEntranceMain or shopType == self.TabIndexToShopType[tabIndex] then
    local isBan = bHide or CheckIfBan(shopType, false)
    self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Shop_CombinationBag_C:OnBlockBtnClicked()
  local tabIndex = self.TabGridView:GetSelectedIndex() + 1
  local shopType = self.TabIndexToShopType[tabIndex]
  local isBan = CheckIfBan(shopType, true)
  if not isBan then
    Log.Error("UMG_Shop_CombinationBag_C:OnBlockBtnClicked: isBan is false")
  end
end

function UMG_Shop_CombinationBag_C:CheckOpenContext()
  if self.module and self.module.data and type(self.module.data.combinationBagShopOpenContext) == "table" then
    local combinationBagShopOpenContext = self.module.data.combinationBagShopOpenContext
    ActivityUtils.SendTLogActivityAction(combinationBagShopOpenContext.Activity, combinationBagShopOpenContext.BaseId, ActivityEnum.TLogActionType.Finish, combinationBagShopOpenContext.ActionId)
  end
end

function UMG_Shop_CombinationBag_C:OnPlayerDataUpdate()
  self:RefreshMoneyList()
  self:UpdateBuyButtonTextColor()
end

function UMG_Shop_CombinationBag_C:OnBagChange()
  self:RefreshMoneyList()
  self:UpdateBuyButtonTextColor()
end

function UMG_Shop_CombinationBag_C:RefreshMoneyList()
  if self.MoneyBtn:GetItemCount() > 0 then
    for i = 1, self.MoneyBtn:GetItemCount() do
      self.MoneyBtn:GetItemByIndex(i - 1):RefreshMoneyNum()
    end
  end
end

function UMG_Shop_CombinationBag_C:UpdateBuyButtonTextColor()
  if self.packagePrice and self.packagePriceGoodsType and self.packagePriceGoodsId then
    local currentOwnedAmount = NPCShopUtils:GetGoodsCurrencyNumByType(self.packagePriceGoodsType, self.packagePriceGoodsId) or 0
    if currentOwnedAmount >= self.packagePrice then
      self.ViewBtn:SetQuantityTextColor("050505FF")
    else
      self.ViewBtn:SetQuantityTextColor("C7494AFF")
    end
  end
end

function UMG_Shop_CombinationBag_C:CheckDirectToTryOnPanel()
  if self.module.bDirectOpenTryOn then
    local closetPanel = self.module:GetPanel("AppearanceCloset")
    if closetPanel then
      closetPanel.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      closetPanel.Suit:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.uiData.ShopId ~= _G.AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG then
      return
    end
    NRCProfilerLog:NRCClickBtn(true, "AppearanceTryOn")
    local myItemDataArray = self:GetShopItemDataArray(self.uiData.ShopId)
    local itemData = myItemDataArray[self.ShowingFashionPackageIndex]
    if itemData then
      local goodsExpireTime
      local goodsConf = _G.DataConfigManager:GetNormalShopConf(itemData.shopLibId)
      if goodsConf then
        goodsExpireTime = ActivityUtils.ToTimestamp(goodsConf.disable_time)
      end
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceTryOn, itemData, nil, nil, goodsExpireTime, self.module.directOpenSuitId)
    else
      Log.Error("\229\189\147\229\137\141\231\187\132\229\144\136\229\140\133\230\149\176\230\141\174\228\184\186\231\169\186")
    end
    self.module.directOpenSuitId = nil
    self.module.bDirectOpenTryOn = nil
    if self.module.bOnlyTryOn then
      self.module.bOnlyTryOn = nil
      self:DelayFrames(1, function()
        self:DoClose()
      end)
    end
  end
end

return UMG_Shop_CombinationBag_C

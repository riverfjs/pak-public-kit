local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local UMG_TryOn_C = _G.NRCPanelBase:Extend("UMG_TryOn_C")

function UMG_TryOn_C:OnConstruct()
  self:SetChildViews(self.TryOnImage)
  self.data = self.module:GetData("AppearanceModuleData")
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.RegisterMoneyBtn, "AppearanceTryOn", self.MoneyBtn)
end

function UMG_TryOn_C:OnActive(param, vItemType, price, goodsExpireTime, resListData, directWearSuitId, bPreviewMode, previewSuitIds)
  _G.NRCAudioManager:PlaySound2DAuto(40006004, "UMG_TryOn_C:OnActive")
  self.firstSuitId = directWearSuitId
  self.MoneyBtnList = {
    self.MoneyBtn1,
    self.MoneyBtn2,
    self.MoneyBtn3
  }
  self.Btn_Upgrade:SetVisibility(UE4.ESlateVisibility.Visible)
  self.uiData = param
  self.curvItemType = vItemType
  self.curPrice = price
  self.goodsExpireTime = goodsExpireTime
  self.shopItemsList = {}
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.curChooseShopLibId = 0
  self.curChooseSuitId = 0
  self.curSelectedSuitIndex = 0
  self.bTouchEnded = true
  self.bIsSuitUnlockListInit = false
  self.bPreviewMode = bPreviewMode
  self.previewSuitIds = previewSuitIds
  self.animManager = self.module.animManager
  local animPriorityTable = {
    HZMoZhangStar = 2,
    HZMoZhangLoop = 2,
    HZMoZhangEnd = 2,
    ShiningMedalOpen = 2,
    ShiningMedalLoop = 2,
    ShiningMedalEnd = 2
  }
  self.animManager:InitPriorityTable(animPriorityTable)
  self.SuitUnlockList:SetMultipleChoice(true)
  self.curSelectedGoodsType = {}
  self.selectedTitleContextStack = {}
  self.nameCardTitleContext = nil
  self.titleStack = {}
  self.chosenSuitId = nil
  self.originalSalon = {}
  if _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo() then
    local wardrobeIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().current_wardrobe_index
    if wardrobeIndex then
      local currentWardrobe = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().wardrobe_data[wardrobeIndex + 1]
      if currentWardrobe then
        self.originalSalon = currentWardrobe.salon_item_wear_id
      end
    end
  end
  self.bIsZoomIn = false
  self.TargetFOV = nil
  self.CurrentFOV = 60.0
  self.FOVInterpSpeed = 100.0
  self:UpdatePanelInfo()
end

function UMG_TryOn_C:OnDeactive()
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnUpgradeComponentClose, false)
end

function UMG_TryOn_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClicked)
  self:AddButtonListener(self.Btn_SingleSet.btnLevelUp, self.OnSingleBuyBtnClicked)
  self:AddButtonListener(self.Btn_Combination.btnLevelUp, self.OnSuitBuyBtnClicked)
  self:AddButtonListener(self.GorgeousMagicBtn, self.OnClickedGorgeousMagicBtn)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnClickDetailBtn)
  self:AddButtonListener(self.Btn_Upgrade.btnLevelUp, self.OnClickUpgradeButton)
  self:AddButtonListener(self.Btn_Upgrade_1.btnLevelUp, self.OnClickUpgradeButton)
  self:RegisterEvent(self, AppearanceModuleEvent.UpdateFashionMall, self.OnUpdateFashionMall)
  self:RegisterEvent(self, AppearanceModuleEvent.ReceiveFashionShopData, self.RefreshPanel)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:RegisterEvent("UMG_TryOn_C", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:RegisterEvent("UMG_TryOn_C", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  NRCEventCenter:RegisterEvent("UMG_TryOn_C", self, AppearanceModuleEvent.OnShiningMedalDetailClosed, self.OnShiningMedalDetailClosed)
end

function UMG_TryOn_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, AppearanceModuleEvent.UpdateFashionMall, self.OnUpdateFashionMall)
  self:UnRegisterEvent(self, AppearanceModuleEvent.ReceiveFashionShopData, self.RefreshPanel)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnShiningMedalDetailClosed, self.OnShiningMedalDetailClosed)
end

function UMG_TryOn_C:OnPlayerDataUpdate()
  self:RefreshMoneyList()
  if not self.uiData then
    return
  end
  if self.uiData.FashionPackageId then
    self:SetPkgBtn()
  end
  self:UpdateSingleBtnText(self.curChooseShopLibId)
end

function UMG_TryOn_C:OnBagChange()
  self:RefreshMoneyList()
  if not self.uiData then
    return
  end
  if self.uiData.FashionPackageId then
    self:SetPkgBtn()
  end
  self:UpdateSingleBtnText(self.curChooseShopLibId)
end

function UMG_TryOn_C:OnShiningMedalDetailClosed()
  local count = self.SuitUnlockList:GetItemCount()
  for i = 1, count do
    local index = i - 1
    local item = self.SuitUnlockList:GetItemByIndex(index)
    if item and item:GetItemType() == _G.Enum.GoodsType.GT_FASHION_BOND then
      self.SuitUnlockList:DeselectItemByIndex(i)
    end
  end
end

function UMG_TryOn_C:RefreshSelectedSuitComponent(suitId)
  if self.curChooseSuitId ~= suitId then
    return
  end
  for i = 1, self.SuitUnlockList:GetItemCount() do
    local isUnlocked = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, i - 1, suitId)
    self.SuitUnlockList:OpItemByIndex(i, 1, isUnlocked)
  end
  local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, suitId)
  self:_HandleUpgradeTitleStyle(isUnlockAllComps)
  self:_UpdatePetIconBackground()
end

function UMG_TryOn_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.RegisterMoneyBtn, "AppearanceTryOn", self.MoneyBtn, true)
  self:OnRemoveEventListener()
end

function UMG_TryOn_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_TryOn_C:InitMoneyBtn()
  local curShopId = 0
  local moneyTable
  if self.uiData == nil then
    return
  end
  if self.bPreviewMode then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.uiData.FashionPackageId then
    local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopLibId)
    if goodsShopConf then
      curShopId = goodsShopConf.shop_id
    else
      Log.Warning("\230\178\161\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132goodsShopConf\233\133\141\231\189\174", self.uiData.shopLibId)
    end
  elseif self.uiData.shopId then
    curShopId = self.uiData.shopId
  end
  local moneyInfo = {}
  local shopConf = _G.DataConfigManager:GetShopConf(curShopId)
  if shopConf then
    moneyTable = shopConf.goods
    if moneyTable and #moneyTable > 0 then
      for k, v in ipairs(moneyTable) do
        local bShowBuyIcon = false
        local costGoodType = v.goods_type
        local costGoodId = v.goods_id
        if costGoodType == Enum.GoodsType.GT_VITEM then
          bShowBuyIcon = costGoodId == Enum.VisualItem.VI_COUPON or costGoodId == Enum.VisualItem.VI_DIAMOND or costGoodId == Enum.VisualItem.VI_PIKA_POINT
        end
        table.insert(moneyInfo, {
          currencyType = costGoodType,
          currencyId = v.goods_id,
          moneyType = costGoodType,
          sum = 0,
          IsShowBuyIcon = bShowBuyIcon
        })
      end
    end
  end
  self.MoneyBtn:InitGridView(moneyInfo)
  self:RefreshMoneyList()
end

function UMG_TryOn_C:OnCloseBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_TryOn_C:OnCloseBtnClicked")
  self:DoClose()
end

function UMG_TryOn_C:OnSingleBuyBtnClicked()
  local falseCount = 0
  local bOneLeft = false
  local packageNormalShopConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopLibId)
  if packageNormalShopConf and packageNormalShopConf.goods_list then
    for k, v in ipairs(packageNormalShopConf.goods_list) do
      local itemConf = _G.DataConfigManager:GetNormalShopConf(v)
      if itemConf then
        local bHasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, itemConf.item_id)
        if not bHasSuit then
          falseCount = falseCount + 1
        end
      end
    end
  end
  if 1 == falseCount then
    bOneLeft = true
  end
  if bOneLeft then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionShopConfirm, 103, {
      shopLibId = self.uiData.shopLibId
    }, true, self.goodsExpireTime)
  else
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionShopConfirm, self.uiData.shopId, {
      shopLibId = self.curChooseShopLibId
    }, false, self.goodsExpireTime)
  end
end

function UMG_TryOn_C:OnSuitBuyBtnClicked()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionShopConfirm, 103, {
    shopLibId = self.uiData.shopLibId
  }, true, self.goodsExpireTime)
end

function UMG_TryOn_C:OnClickedGorgeousMagicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TryOn_C:OnClickedGorgeousMagicBtn")
  if 0 == self.NRCSwitcher_1:GetActiveWidgetIndex() then
    if self.curChooseSuitId > 0 then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicVideoDetailsPanel, Enum.GoodsType.GT_FASHION_SUITS, self.curChooseSuitId)
    end
  elseif 1 == self.NRCSwitcher_1:GetActiveWidgetIndex() or 2 == self.NRCSwitcher_1:GetActiveWidgetIndex() then
    local pendantaId = self:_GetItemIdFromStackByType(_G.Enum.FashionLabelType.FLT_PENDANTA)
    if not pendantaId or 0 == pendantaId then
      Log.Error("\229\176\157\232\175\149\229\156\168\229\140\133\230\140\130\228\184\141\229\173\152\229\156\168\231\154\132\230\151\182\229\128\153\230\137\147\229\188\128\229\140\133\230\140\130\232\175\166\230\131\133\229\188\185\231\170\151\239\188\140\232\191\153\230\156\137\233\151\174\233\162\152\239\188\129")
      return
    end
    local context = {}
    context.bIsPendanta = true
    context.context = {}
    context.context.itemId = pendantaId
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
  elseif 3 == self.NRCSwitcher_1:GetActiveWidgetIndex() then
    local wandId = self:_GetItemIdFromStackByType(_G.Enum.FashionLabelType.FLT_WAND)
    if not wandId or 0 == wandId then
      Log.Error("\229\176\157\232\175\149\229\156\168\230\179\149\230\157\150\228\184\141\229\173\152\229\156\168\231\154\132\230\151\182\229\128\153\230\137\147\229\188\128\230\179\149\230\157\150\232\175\166\230\131\133\229\188\185\231\170\151\239\188\140\232\191\153\230\156\137\233\151\174\233\162\152\239\188\129")
      return
    end
    local context = {}
    context.bIsWand = true
    context.context = {}
    context.context.WandId = wandId
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
  end
end

function UMG_TryOn_C:_GetItemIdFromStackByType(type)
  local topIndex = self.titleStack[#self.titleStack]
  if not topIndex then
    return nil
  end
  local curShowItem = self.selectedTitleContextStack[topIndex]
  if not curShowItem or not curShowItem.context then
    return nil
  end
  local detailContext = curShowItem.context
  if detailContext.context then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(detailContext.context.item_id, true)
    if fashionConf and fashionConf.type == type then
      return detailContext.context.item_id
    end
  end
  return nil
end

function UMG_TryOn_C:UpdateGorgeousMagicBtnVisible()
  self.GorgeousMagicBtn:SetVisibility(self:FindSGSuitId() and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_TryOn_C:FindSGSuitId()
  if not self.uiData or not self.uiData.FashionPackageId and not self.uiData.shopItemId then
    return
  end
  if self.uiData.FashionPackageId then
    local minSGSutiId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.FindMinSGSuitId, self.uiData.FashionPackageId)
    return minSGSutiId
  else
    local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
    local sgSuitId = fashionGoodsConf and _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, fashionGoodsConf.item_id)
    return sgSuitId
  end
end

function UMG_TryOn_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if not self.bTouchEnded then
    self.bTouchEnded = true
    self.ScrollBoxA:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_TryOn_C:LuaOnTouchMoved(dir)
  if self.bTouchEnded then
    self.bTouchEnded = false
    self.ScrollBoxA:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self.TryOnImage:SetAvatarRotation(dir.X)
end

function UMG_TryOn_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if not self.bTouchEnded then
    self.bTouchEnded = true
    self.ScrollBoxA:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_TryOn_C:UpdatePanelInfo()
  if self.uiData == nil then
    return
  end
  self:InitMoneyBtn()
  self:UpdateGorgeousMagicBtnVisible()
  self.Buy_List:SetMultipleChoice(true)
  if not self.bPreviewMode then
    self:InitNormalMode()
  else
    self:InitPreviewMode()
  end
  local iconPath
  local viConf = _G.DataConfigManager:GetFashionViConf(2)
  if viConf then
    iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(viConf.goods_type, viConf.goods_id)
  end
  if self.NRCImage_9 then
    self.NRCImage_9:SetPath(iconPath)
  end
  if self.Title then
    self.Title:SetText(_G.LuaText.fashion_suits_level_up_diamonds)
  end
  if self.Title_1 then
    self.Title_1:SetText(LuaText.fashion_suits_whole_unlock)
  end
  if self.Btn_Upgrade_1 then
    self.Btn_Upgrade_1:SetCommonText(LuaText.fashion_suits_view_jump_btn)
  end
  if self.Btn_Upgrade then
    self.Btn_Upgrade:SetCommonText(LuaText.ashion_suits_unlock_jump_btn)
  end
end

function UMG_TryOn_C:RefreshPanel(shopId, rsp)
  if self.uiData == nil then
    return
  end
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  if nil == shopConf then
    Log.Error("\228\184\141\229\173\152\229\156\168\231\154\132\229\149\134\229\159\142id", shopId)
    return
  end
  self:InitMoneyBtn()
  if shopConf.shop_type == _G.Enum.ShopType.ST_FASHION_CLOSET then
    return
  end
  if self.uiData.FashionPackageId then
    local pkgId = 0
    pkgId = self.uiData.FashionPackageId
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(pkgId)
    local packageGoodsData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.uiData.shopId, self.uiData.shopLibId)
    if not packageGoodsData and not self.bPreviewMode then
      Log.Error("UMG_TryOn_C:RefreshPanel InvalidGoodServerData when RefreshPanel", self.uiData.shopId, self.uiData.shopLibId)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.fashionmall_expired)
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CloseAppearanceTryOn)
      return
    end
    local packageNormalShopConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopLibId)
    if fashionPackageConf and packageGoodsData and packageNormalShopConf and packageGoodsData.sub_goods then
      self.SuitTitle:SetText(fashionPackageConf.name)
      local defaultSuitId
      local initTable = {}
      for idx, subGoodsData in ipairs(packageGoodsData.sub_goods) do
        local normalShopConf = _G.DataConfigManager:GetNormalShopConf(subGoodsData and subGoodsData.goods_id)
        if normalShopConf then
          if nil == defaultSuitId and normalShopConf and normalShopConf.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
            defaultSuitId = normalShopConf.item_id
          end
          local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, defaultSuitId)
          table.insert(initTable, {
            data = normalShopConf,
            parent = self,
            bIsMaxLevel = isUnlockAllComps,
            fashionPackageId = pkgId,
            bIsFree = subGoodsData.is_gift
          })
        end
      end
      table.sort(initTable, function(a, b)
        local goodsTypeA = a and a.data and a.data.type or _G.Enum.GoodsType.GT_NONE
        local goodsTypeB = b and b.data and b.data.type or _G.Enum.GoodsType.GT_NONE
        if goodsTypeA == goodsTypeB and goodsTypeA == _G.Enum.GoodsType.GT_FASHION then
          local fashionItemConfA = _G.DataConfigManager:GetFashionItemConf(a and a.data and a.data.item_id, true)
          local fashionItemConfB = _G.DataConfigManager:GetFashionItemConf(b and b.data and b.data.item_id, true)
          local fashionTypeA = fashionItemConfA and fashionItemConfA.type or _G.Enum.FashionLabelType.FLT_BEGIN
          local fashionTypeB = fashionItemConfB and fashionItemConfB.type or _G.Enum.FashionLabelType.FLT_BEGIN
          return (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeB] or math.maxinteger)
        elseif goodsTypeA and goodsTypeB then
          return (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeB] or math.maxinteger)
        else
          return nil ~= goodsTypeA
        end
      end)
      for i = 0, #initTable - 1 do
        local item = self.Buy_List:GetItemByIndex(i)
        if item then
          item:UpdateItemInfoWithData(initTable[i + 1])
        end
      end
    end
    self.Btn_Combination:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetPkgBtn()
  else
    local showItem = {}
    local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
    if fashionGoodsConf then
      table.insert(showItem, {
        goods_shop_id = self.uiData.shopLibId,
        id = fashionGoodsConf.item_id,
        item_id = fashionGoodsConf.item_id,
        item_name = fashionGoodsConf.goods_name,
        type = fashionGoodsConf.Type
      })
      self.SuitTitle:SetText(fashionGoodsConf.goods_name)
      local indices = self.Buy_List:GetSelectedIndex()
      local initTable = {}
      for k, v in ipairs(initTable) do
        table.insert(initTable, {data = v, parent = self})
      end
      self.Buy_List:InitGridView(initTable)
      self:DelayFrames(1, function()
        if type(indices) == "table" then
          for k, v in ipairs(indices) do
            self.Buy_List:SelectItemByIndex(v)
          end
        elseif type(indices) == "number" then
          self.Buy_List:SelectItemByIndex(indices)
        end
      end)
      self.Btn_Combination:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      logError(self.uiData.shopItemId, "\230\178\161\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132fashionGoodsConf\233\133\141\231\189\174")
    end
  end
end

function UMG_TryOn_C:CheckOwnedByTypeAndId(type, itemId)
  local bOwned = false
  if type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    bOwned = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckHasSuit, itemId)
  elseif type == _G.Enum.GoodsType.GT_FASHION then
    bOwned = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckHasOwned, type, itemId)
  elseif type == _G.Enum.GoodsType.GT_CARD_SKIN then
    bOwned = _G.NRCModuleManager:DoCmd(FriendModuleCmd.HasCardSkin, itemId)
  end
  return bOwned
end

function UMG_TryOn_C:OnUpdateFashionMall(shopId)
  Log.Info("UMG_TryOn_C:OnUpdateFashionMall", shopId)
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, shopId)
end

function UMG_TryOn_C:RefreshTryOnUnlockShop(shopItemList)
  if not self.module.data.bIsBuyItem then
  end
  if self.module.data.bIsBuyItem then
    self.module.data.bIsBuyItem = false
  end
end

function UMG_TryOn_C:UpdateUpgradeComponents(showItemList)
  local initList = {}
  for k, v in ipairs(showItemList) do
    table.insert(initList, {data = v, parent = self})
  end
  if not self.bIsSuitUnlockListInit then
    self.SuitUnlockList:InitGridView(initList)
    self.bIsSuitUnlockListInit = true
  end
  for i = 0, #initList - 1 do
    local item = self.SuitUnlockList:GetItemByIndex(i)
    item.Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal_png.img_daojukuangnormal_png'")
    item:UpdateItemInfoByData(initList[i + 1])
  end
end

function UMG_TryOn_C:SetPkgBtn()
  local pkgId = 0
  if self.uiData and self.uiData.FashionPackageId then
    pkgId = self.uiData.FashionPackageId
  end
  if not self.bPreviewMode then
    if pkgId > 0 then
      local btnPriceText = ""
      local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
      local costGoodsType = fashionGoodsConf.price_goods_type
      local costGoodsId = fashionGoodsConf.price_goods_id
      local GoodsOriginPrice = fashionGoodsConf.origin_price
      local GoodsRealPrice = fashionGoodsConf.price
      local packageData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.uiData.shopId, self.uiData.shopItemId)
      if packageData then
        costGoodsType = packageData.real_price.goods_type
        costGoodsId = packageData.real_price.goods_id
        GoodsOriginPrice = packageData.origin_price.num
        GoodsRealPrice = packageData.real_price.num
      else
        Log.Warning("UMG_TryOn_C:SetPkgBtn", "packageData is nil", self.uiData.shopId, self.uiData.shopItemId)
      end
      local iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(costGoodsType, costGoodsId)
      local packagePrice, packageFreePrice, bHadOwnEntirePackage, availablePikaPointInPackageContent = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CalcFashionPackagePrice, pkgId, GoodsRealPrice, self.uiData.shopId, self.uiData.shopItemId)
      local pikaPointWouldGet = availablePikaPointInPackageContent
      if bHadOwnEntirePackage then
        self.NRCSwitcher_93:SetActiveWidgetIndex(1)
        btnPriceText = LuaText.tailor_owned_btn
        self.AlreadyOwned_1.MoneyIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.AlreadyOwned_1.Quantity:SetText(btnPriceText)
        self.AlreadyOwned_1.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:SetButtonVisibility(true)
      else
        self.NRCSwitcher_93:SetActiveWidgetIndex(0)
        self.Btn_Combination:ResetButtonDiscountState()
        btnPriceText = packagePrice
        self.Btn_Combination:SetClickAble(true)
        self.Btn_Combination:SetDiscount(packageFreePrice)
        self.Btn_Combination:SetAppearanceButtonContext(iconPath, btnPriceText, pikaPointWouldGet)
        self.curPackagePrice = packagePrice
        self:_UpdateButtonPriceColor(packagePrice, nil, costGoodsType, costGoodsId)
        self:SetButtonVisibility(false)
      end
    end
  else
    self.HorizontalBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TryOn_C:SetSingleBtnText(goodsId, bOwned, extraPikaPoint)
  local goodsSevData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.uiData.shopId, goodsId)
  if goodsSevData then
    local iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(goodsSevData.real_price.goods_type, goodsSevData.real_price.goods_id)
    local btnPriceText = ""
    if bOwned then
      self.AlreadyOwned:SetShowLockIcon(false)
      self.AlreadyOwned:SetTitleTextAndIcon(nil, nil, nil, nil, _G.LuaText.tailor_owned_btn)
    else
      btnPriceText = goodsSevData.real_price.num
      self.Btn_SingleSet:SetClickAble(true)
      self.Btn_SingleSet:SetAppearanceButtonContext(iconPath, btnPriceText, extraPikaPoint)
      self:_UpdateButtonPriceColor(nil, btnPriceText, goodsSevData.real_price.goods_type, goodsSevData.real_price.goods_id)
    end
  end
end

function UMG_TryOn_C:UpdateSingleOwnedState()
  self.AlreadyOwned:SetShowLockIcon(false)
  self.AlreadyOwned:SetTitleTextAndIcon(nil, nil, nil, nil, _G.LuaText.tailor_owned_btn)
end

function UMG_TryOn_C:SetCurSelectItem(type, id, goodsId)
  if type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    self.curChooseShopLibId = goodsId
    if self.bPreviewMode then
      self:UpdateSuitTitle(id)
    end
  end
  if type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(id)
    if fashionSuitConf.lv_up_closet and #fashionSuitConf.lv_up_closet > 0 then
      self:SetUnlockListVisible(true)
    else
      self:SetUnlockListVisible(false)
    end
    self:SetImageAvatarAppearance(nil, self.originalSalon, self.data.curTryOnItemInfo.id)
    self.curChooseSuitId = id
    self.curSelectedSuitIndex = 0
    for i = 0, self.SuitUnlockList:GetItemCount() - 1 do
      local item = self.SuitUnlockList:GetItemByIndex(i)
      if item and item.uiData and item.uiData.item_id == id then
        self.curSelectedSuitIndex = i
      end
    end
  elseif type == _G.Enum.GoodsType.GT_FASHION or type == _G.Enum.GoodsType.GT_SALON then
    self:SetUnlockListVisible(false)
    local fashionIds = {}
    table.insert(fashionIds, self.data.curTryOnItemInfo.id)
    self:SetImageAvatarAppearance(fashionIds)
  else
    self:SetUnlockListVisible(false)
  end
  if not self.bPreviewMode then
    self:UpdateSingleBtnText(self.curChooseShopLibId)
  end
end

function UMG_TryOn_C:SetImageAvatarAppearance(fashionIds, salonIds, suitId)
  self.TryOnImage:SetAvatarAppearance(fashionIds, salonIds, suitId)
end

function UMG_TryOn_C:OnClickUpgradeButton()
  if self.module:HasPanel("AppearanceCloset") then
    local closetPanel = self.module:GetPanel("AppearanceCloset")
    local suitId = self.curChooseSuitId
    local packageId = self.uiData.FashionPackageId
    self.module:ClosePanel("SeasonalCombinationBagShop")
    self.module.tempTryOnAvatar = self.TryOnImage.AvatarPlayer
    self.module:InitAvatarRotationData(self.module.closetAvatarPlayer, nil, nil, "Closet")
    self:SetPanelReadyToClosed()
    self:Disable()
    self.bPanelHiddenByUpgradeBtn = true
    if closetPanel then
      closetPanel:EnterSuitUpgradePanel(suitId, packageId)
    end
  else
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true, true, self.curChooseSuitId)
  end
end

function UMG_TryOn_C:OnClickDetailBtn()
  if not self.curDetailContext then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_TryOn_C:OnClickDetailBtn")
  if self.curDetailContext.bIsShopItem then
    if self.curDetailContext.context.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.curDetailContext.context.item_id)
    elseif self.curDetailContext.context.type == _G.Enum.GoodsType.GT_FASHION then
      local itemConf = _G.DataConfigManager:GetFashionItemConf(self.curDetailContext.context.item_id, true)
      if itemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
        local context = {}
        context.bIsWand = true
        context.context = {}
        context.context.WandId = self.curDetailContext.context.item_id
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
      end
    end
  else
    local type, itemId
    if self.curDetailContext.context and self.curDetailContext.context.componentData then
      type = self.curDetailContext.context.componentData.lv_item_type
      itemId = self.curDetailContext.context.componentData.lv_item_id
    end
    if not type or not itemId then
      return
    end
    if type == _G.Enum.GoodsType.GT_FASHION then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
      if not fashionItemConf or fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
      end
    end
  end
end

function UMG_TryOn_C:SetUnlockListVisible(bVisible)
  if self.bPreviewMode then
    self.UpgradePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UpgradePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_TryOn_C:SetCardBG(id)
  local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(id)
  self.TryOnBg:SetPath(string.format(UEPath.CARD_COMMON_PATH, cardSkinConf.skin_resource_path, "1", cardSkinConf.skin_resource_path, "1"))
end

function UMG_TryOn_C:SetTitleAndGorgeousBtnState(petTitle, suitTitle, bShouldShowGorgeousButton, bShouldShowDetail, context)
  if bShouldShowGorgeousButton then
    self.GorgeousMagicBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if context.bIsShopItem then
      self:StopAnimation(self.Privilege_loop)
      if context.gorgeousBtnType then
        self.NRCSwitcher_1:SetActiveWidgetIndex(context.gorgeousBtnType)
      else
        self.NRCSwitcher_1:SetActiveWidgetIndex(0)
      end
    else
      self.NRCSwitcher_1:SetActiveWidgetIndex(1)
      self:PlayAnimation(self.Privilege_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    end
    if context.gorgeousBtnIconPath and not string.IsNilOrEmpty(context.gorgeousBtnIconPath) then
      self.MagicIcon:SetPath(context.gorgeousBtnIconPath)
    end
    if context.gorgeousBtnText and not string.IsNilOrEmpty(context.gorgeousBtnText) then
      self.NRCText_1:SetText(context.gorgeousBtnText)
    end
  else
    self:StopAnimation(self.Privilege_loop)
    self.GorgeousMagicBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.PetTitle:SetText(petTitle)
  self.SuitTitle:SetText(suitTitle)
  if bShouldShowDetail then
    self.Particulars:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Particulars:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TryOn_C:BindDetailBtnContext(context)
  self.curDetailContext = context
end

function UMG_TryOn_C:_HasConflict(newGoodsType, subType)
  if newGoodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    if self.curSelectedGoodsType[newGoodsType] ~= nil then
      return true, self.curSelectedGoodsType[newGoodsType]
    end
  elseif newGoodsType == _G.Enum.GoodsType.GT_FASHION then
    if self.curSelectedGoodsType[newGoodsType] and self.curSelectedGoodsType[newGoodsType][subType] then
      return true, self.curSelectedGoodsType[newGoodsType][subType]
    end
  elseif newGoodsType == _G.Enum.GoodsType.GT_SALON and self.curSelectedGoodsType[newGoodsType] and self.curSelectedGoodsType[newGoodsType][subType] then
    return true, self.curSelectedGoodsType[newGoodsType][subType]
  end
  return false, nil
end

function UMG_TryOn_C:_HandleDeselectConflictOption(goodsType, subType)
  if goodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local bIsConflict, item = self:_HasConflict(goodsType)
    if bIsConflict then
      item.container:DeselectItemByIndex(item.index)
    end
  elseif goodsType == _G.Enum.GoodsType.GT_FASHION then
    local bIsConflict, item = self:_HasConflict(goodsType, subType)
    if bIsConflict then
      item.container:DeselectItemByIndex(item.index)
    end
  elseif goodsType == _G.Enum.GoodsType.GT_SALON then
    local bIsConflict, item = self:_HasConflict(goodsType, subType)
    if bIsConflict then
      item.container:DeselectItemByIndex(item.index)
    end
  end
end

function UMG_TryOn_C:HandleMutualExclusiveChoice(bIsSelected, curNewSelected, goodsType, bIsBuyList)
  local containerRef = self.Buy_List
  if not bIsBuyList then
    containerRef = self.SuitUnlockList
  end
  if bIsSelected then
    if goodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
      self:_HandleDeselectConflictOption(goodsType)
      self:ZoomOut()
      containerRef:SetItemClickAbleByIndex(false, curNewSelected.index)
      if self.curSelectedGoodsType[goodsType] then
        self.curSelectedGoodsType[goodsType].container:SetItemClickAbleByIndex(true, self.curSelectedGoodsType[goodsType].index)
      end
      if not self.curSelectedGoodsType[goodsType] then
        self.curSelectedGoodsType[goodsType] = {}
      end
      self.curSelectedGoodsType[goodsType] = {
        container = containerRef,
        index = curNewSelected.index,
        bIsBuyList = bIsBuyList
      }
      for k1, v in pairs(self.curSelectedGoodsType) do
        if k1 == _G.Enum.GoodsType.GT_FASHION then
          for k2, element in pairs(v) do
            if element and not element.bIsBuyList then
              local item = self.SuitUnlockList:GetItemByIndex(self.curSelectedGoodsType[k1][k2].index - 1)
              local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(item.uiData.goods_id)
              if fashionGoodsConf and fashionGoodsConf.Type == _G.Enum.GoodsType.GT_FASHION then
                self.TryOnImage:DemountFashionById(fashionGoodsConf.item_id)
              end
              self.curSelectedGoodsType[k1][k2] = nil
            end
          end
        end
        if k1 == _G.Enum.GoodsType.GT_SALON then
          for k2, element in pairs(v) do
            if element and not element.bIsBuyList then
              local item = self.SuitUnlockList:GetItemByIndex(self.curSelectedGoodsType[k1][k2].index - 1)
              local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(item.uiData.goods_id)
              if fashionGoodsConf and fashionGoodsConf.Type == _G.Enum.GoodsType.GT_SALON then
                self.TryOnImage:RecoverToOriginalSalons()
              end
              self.curSelectedGoodsType[k1][k2] = nil
            end
          end
        end
      end
    elseif goodsType == _G.Enum.GoodsType.GT_FASHION then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(curNewSelected.uiData.item_id)
      self:_HandleDeselectConflictOption(goodsType, fashionItemConf.type)
      if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_GLASSES then
        self:ZoomIn()
      else
        self:ZoomOut(fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND)
      end
      if not self.curSelectedGoodsType[goodsType] then
        self.curSelectedGoodsType[goodsType] = {}
      end
      if not self.curSelectedGoodsType[goodsType][fashionItemConf.type] then
        self.curSelectedGoodsType[goodsType][fashionItemConf.type] = {}
      end
      self.curSelectedGoodsType[goodsType][fashionItemConf.type] = {
        container = containerRef,
        index = curNewSelected.index,
        bIsBuyList = bIsBuyList
      }
    elseif goodsType == _G.Enum.GoodsType.GT_SALON then
      local salonItemConf = _G.DataConfigManager:GetSalonItemConf(curNewSelected.uiData.item_id)
      self:_HandleDeselectConflictOption(goodsType, salonItemConf.type)
      self:ZoomIn()
      if not self.curSelectedGoodsType[goodsType] then
        self.curSelectedGoodsType[goodsType] = {}
      end
      if not self.curSelectedGoodsType[goodsType][salonItemConf.type] then
        self.curSelectedGoodsType[goodsType][salonItemConf.type] = {}
      end
      self.curSelectedGoodsType[goodsType][salonItemConf.type] = {
        container = containerRef,
        index = curNewSelected.index,
        bIsBuyList = bIsBuyList
      }
    end
  elseif goodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    if self.curSelectedGoodsType[goodsType] and self.curSelectedGoodsType[goodsType].index == curNewSelected.index then
      return
    end
    self.curSelectedGoodsType[goodsType].contianer:SetItemClickAbleByIndex(true, self.curSelectedGoodsType[goodsType].index)
    self.curSelectedGoodsType[goodsType] = nil
  elseif goodsType == _G.Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(curNewSelected.uiData.item_id)
    self.curSelectedGoodsType[goodsType][fashionItemConf.type] = nil
  elseif goodsType == _G.Enum.GoodsType.GT_SALON then
    self.curSelectedGoodsType[goodsType] = nil
  end
end

function UMG_TryOn_C:PushNewSelectedElementToStack(title, packageTitle, bShouldShowDetailButton, bShouldShowGorgeousButton, context, itemId)
  self:BindDetailBtnContext(context)
  if context.bIsShopItem then
    if context.context.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      self.selectedTitleContextStack[1] = {
        title = title,
        packageTitle = packageTitle,
        bShouldShowDetailButton = bShouldShowDetailButton,
        bShouldShowGorgeousButton = bShouldShowGorgeousButton,
        context = context
      }
      local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, itemId)
      self:_HandleUpgradeTitleStyle(isUnlockAllComps)
      self:_UpdateUpgradeComponentList(itemId)
      table.removeValue(self.titleStack, 1)
      table.insert(self.titleStack, 1)
      self.nameCardTitleContext = nil
    elseif context.context.type ~= _G.Enum.GoodsType.GT_CARD_SKIN then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId, true)
      if fashionItemConf then
        if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
          context.gorgeousBtnType = 2
        elseif fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
          context.gorgeousBtnType = 3
        end
      end
      table.insert(self.selectedTitleContextStack, {
        title = title,
        packageTitle = packageTitle,
        bShouldShowDetailButton = bShouldShowDetailButton,
        bShouldShowGorgeousButton = bShouldShowGorgeousButton,
        context = context
      })
      table.insert(self.titleStack, #self.selectedTitleContextStack)
      self.nameCardTitleContext = nil
    else
      self.nameCardTitleContext = {}
      self.nameCardTitleContext.title = title
      self.nameCardTitleContext.packageTitle = packageTitle
      self.nameCardTitleContext.bShouldShowDetailButton = bShouldShowDetailButton
      self.nameCardTitleContext.bShouldShowGorgeousButton = bShouldShowGorgeousButton
      self.context = context
    end
  else
    table.insert(self.selectedTitleContextStack, {
      title = title,
      packageTitle = packageTitle,
      bShouldShowDetailButton = bShouldShowDetailButton,
      bShouldShowGorgeousButton = bShouldShowGorgeousButton,
      context = context
    })
    table.insert(self.titleStack, #self.selectedTitleContextStack)
    self.nameCardTitleContext = nil
  end
  self:_UpdateTitle()
end

function UMG_TryOn_C:_UpdatePetIconBackground()
  local size = self.Buy_List:GetItemCount()
  for i = 0, size - 1 do
    local item = self.Buy_List:GetItemByIndex(i)
    if item.uiData.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, item.uiData.item_id)
      item:UpdatePetIconBackground(isUnlockAllComps)
    end
  end
end

function UMG_TryOn_C:_RemoveElementFromStack(item_id)
  for i = #self.selectedTitleContextStack, 2, -1 do
    local element = self.selectedTitleContextStack[i]
    if element and element.context.context.item_id == item_id then
      table.remove(self.selectedTitleContextStack, i)
      table.removeValue(self.titleStack, i)
      for k, v in ipairs(self.titleStack) do
        if i < v then
          self.titleStack[k] = v - 1
        end
      end
    end
  end
end

function UMG_TryOn_C:HandleSuitNameRecover(item_id)
  self:_RemoveElementFromStack(item_id)
  self:_UpdateTitle()
end

function UMG_TryOn_C:DemountUpgradeComponent(type, itemId)
  if type == _G.Enum.GoodsType.GT_SALON then
    self.TryOnImage:DemountSalonById(itemId)
  elseif type == _G.Enum.GoodsType.GT_FASHION then
    self.TryOnImage:DemountFashionById(itemId)
  elseif type == _G.Enum.GoodsType.GT_FASHION_SUITS then
  elseif type == _G.Enum.GoodsType.GT_BAGITEM or type == _G.Enum.GoodsType.GT_FASHION_BOND then
  end
end

function UMG_TryOn_C:SetSingleBuyBtnState(bOwned)
  if bOwned then
    self:UpdateSingleOwnedState()
    self.NRCSwitcher_68:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_68:SetActiveWidgetIndex(1)
  end
end

function UMG_TryOn_C:_UpdateTitle()
  if self.nameCardTitleContext then
    self:SetTitleAndGorgeousBtnState(self.nameCardTitleContext.title, self.nameCardTitleContext.packageTitle, self.nameCardTitleContext.bShouldShowGorgeousButton, self.nameCardTitleContext.bShouldShowDetailButton)
    self:BindDetailBtnContext(self.nameCardTitleContext.context)
  else
    local curShowItem = self.selectedTitleContextStack[self.titleStack[#self.titleStack]]
    if curShowItem then
      self:SetTitleAndGorgeousBtnState(curShowItem.title, curShowItem.packageTitle, curShowItem.bShouldShowGorgeousButton, curShowItem.bShouldShowDetailButton, curShowItem.context)
      self:BindDetailBtnContext(curShowItem.context)
    end
  end
end

function UMG_TryOn_C:_HandleUpgradeTitleStyle(bUnlockAllComps)
  if bUnlockAllComps then
    self.Switcher_66:SetActiveWidgetIndex(1)
  else
    self.Switcher_66:SetActiveWidgetIndex(0)
  end
end

function UMG_TryOn_C:_UpdateUpgradeComponentList(suitId)
  self.SuitUnlockList:ClearSelection()
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if not suitConf then
    return
  end
  local dataList = {}
  if suitConf.lv_up_closet then
    for k, v in pairs(suitConf.lv_up_closet) do
      local buyNum = 0
      local isUnlock = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckComponentIsUnlocked, k - 1, suitId)
      if isUnlock then
        buyNum = 1
      end
      table.insert(dataList, {
        buy_num = buyNum,
        componentData = v,
        newPanel = false,
        text = v.goods_ui_text
      })
    end
  end
  local initList = {}
  for k, v in ipairs(dataList) do
    table.insert(initList, {
      data = v,
      parent = self,
      belongToSuit = suitConf
    })
  end
  if #initList > 0 then
    self.SuitUnlockList:InitGridView(initList)
  end
end

function UMG_TryOn_C:ZoomIn(bIgnoreAvatarAnim)
  if self.bIsZoomIn then
    return
  end
  self.bIsZoomIn = true
  self:PlayZoomInSkill(bIgnoreAvatarAnim)
end

function UMG_TryOn_C:ZoomOut(bIgnoreAvatarAnim)
  if not self.bIsZoomIn then
    return
  end
  self.bIsZoomIn = false
  self:PlayZoomOutSkill(bIgnoreAvatarAnim)
end

function UMG_TryOn_C:PlayZoomInSkill(bIgnoreAvatarAnim)
  if not self.MainCamera then
    self.MainCamera = self.TryOnImage.TryOnWorldView:GetCameraActor()
  end
  local caster = self.TryOnImage.FakeAvatar
  local skillClass = UE4.UClass.Load("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_WuTai_MR_Start.G6_CosPlay_WuTai_MR_Start_C'")
  local skillComponent = caster.RocoSkill
  if not skillComponent or not skillClass then
    return
  end
  local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if skillObj then
    caster.RocoSkill:StopCurrentSkill()
    skillObj:SetCaster(caster)
    skillObj:RegisterEventCallback("Start", self, self.OnTryOnSkillPlayStart)
    skillObj:RegisterEventCallback("SetCamera", self, self.OnTryOnSetCamera)
    skillObj:RegisterEventCallback("End", self, self.OnTryOnSkillPlayEnd)
    caster.RocoSkill:LoadAndPlaySkill(skillObj)
  end
  caster = self.TryOnImage.AvatarPlayer
  skillComponent = caster.RocoSkill
  if not skillComponent or not skillClass then
    return
  end
  skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if skillObj then
    caster.RocoSkill:StopCurrentSkill()
    if not bIgnoreAvatarAnim then
      skillObj:SetCaster(caster)
      skillObj:RegisterEventCallback("End", self, self.OnTryOnFakeAvatarSkillPlayEnd)
      skillObj:RegisterEventCallback("PlayHZIdleAnim", self, self.OnStartPlayHZIdleAnim)
      skillObj:RegisterEventCallback("PlayHZMeiRongStartAnim", self, self.OnStartPlayHZMeiRongStartAnim)
      skillObj:RegisterEventCallback("PlayIdleAnim", self, self.OnStartPlayIdleAnim)
      caster.RocoSkill:LoadAndPlaySkill(skillObj)
    end
  end
end

function UMG_TryOn_C:OnStartPlayHZIdleAnim()
  local avatar = self.TryOnImage.AvatarPlayer
  if avatar then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.1
    param.blendOutTime = 0.2
    self.animManager:TryPlayAnimByNameWithParam(avatar, "HZIdle", false, param)
  end
end

function UMG_TryOn_C:OnStartPlayHZMeiRongStartAnim()
  local avatar = self.TryOnImage.AvatarPlayer
  if avatar then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.2
    param.blendOutTime = 0.3
    self.animManager:TryPlayAnimByNameWithParam(avatar, "HZMeiRongStart", false, param)
  end
end

function UMG_TryOn_C:OnStartPlayIdleAnim()
  local avatar = self.TryOnImage.AvatarPlayer
  if avatar then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.4
    param.blendOutTime = 0.1
    param.loopCount = -1
    self.animManager:TryPlayAnimByNameWithParam(avatar, "Idle", false, param)
  end
end

function UMG_TryOn_C:PlayZoomOutSkill(bIgnoreAvatarAnim)
  if not self.MainCamera then
    self.MainCamera = self.TryOnImage.TryOnWorldView:GetCameraActor()
  end
  local caster = self.TryOnImage.FakeAvatar
  local skillClass = UE4.UClass.Load("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_WuTai_MR_End.G6_CosPlay_WuTai_MR_End_C'")
  local skillComponent = caster.RocoSkill
  if not skillComponent or not skillClass then
    return
  end
  local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if skillObj then
    caster.RocoSkill:StopCurrentSkill()
    skillObj:SetCaster(caster)
    skillObj:RegisterEventCallback("Start", self, self.OnTryOnSkillPlayStart)
    skillObj:RegisterEventCallback("SetCamera", self, self.OnTryOnSetCamera)
    skillObj:RegisterEventCallback("End", self, self.OnTryOnSkillPlayEnd)
    caster.RocoSkill:LoadAndPlaySkill(skillObj)
  end
  caster = self.TryOnImage.AvatarPlayer
  skillComponent = caster.RocoSkill
  if not skillComponent or not skillClass then
    return
  end
  skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if skillObj then
    caster.RocoSkill:StopCurrentSkill()
    if not bIgnoreAvatarAnim then
      skillObj:SetCaster(caster)
      skillObj:RegisterEventCallback("End", self, self.OnTryOnFakeAvatarSkillPlayEnd)
      skillObj:RegisterEventCallback("PlayIdleAnim", self, self.OnEndPlayIdleAnim)
      skillObj:RegisterEventCallback("PlayHZIdleAnim", self, self.OnEndPlayHZIdleAnim)
      caster.RocoSkill:LoadAndPlaySkill(skillObj)
    end
  end
end

function UMG_TryOn_C:OnEndPlayIdleAnim()
  local avatar = self.TryOnImage.AvatarPlayer
  if avatar then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.1
    param.blendOutTime = 0.3
    self.animManager:TryPlayAnimByNameWithParam(avatar, "Idle", false, param)
  end
end

function UMG_TryOn_C:OnEndPlayHZIdleAnim()
  local avatar = self.TryOnImage.AvatarPlayer
  if avatar then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.3
    param.blendOutTime = 0.3
    self.animManager:TryPlayAnimByNameWithParam(avatar, "HZIdle", false, param)
  end
end

function UMG_TryOn_C:OnTryOnSetCamera(Event, Skill)
  local camera = Skill.Blackboard:GetValueAsObject("camActor_0001")
  if camera then
    local camComp = camera:GetComponentByClass(UE4.UCameraComponent)
    if camComp then
      self.TargetFOV = camComp.FieldOfView
    end
  end
  self:DelayFrames(2, function()
    self.TryOnSkillCameraActor = Skill.Blackboard:GetValueAsObject("camActor_0001")
    local mainCamComp = self.MainCamera:GetComponentByClass(UE4.UCameraComponent)
    if mainCamComp then
      self.CurrentFOV = mainCamComp.FieldOfView
    end
  end)
end

function UMG_TryOn_C:OnTryOnSkillPlayStart(Event, Skill)
end

function UMG_TryOn_C:OnTryOnFakeAvatarSkillPlayEnd(Event, Skill)
  if self.FakeAvatarSkillCamera then
    self.FakeAvatarSkillCamera:K2_DestroyActor()
    self.FakeAvatarSkillCamera = nil
  end
  if self.FakeAvatarSkillCameraMesh then
    self.FakeAvatarSkillCameraMesh:K2_DestroyActor()
    self.FakeAvatarSkillCameraMesh = nil
  end
  self.FakeAvatarSkillCamera = Skill.Blackboard:GetValueAsObject("camActor_0001")
  self.FakeAvatarSkillCameraMesh = Skill.Blackboard:GetValueAsObject("camActor_0001_SA")
  Skill.Blackboard:RemoveObjectValue("camActor_0001")
  Skill.Blackboard:RemoveObjectValue("camActor_0001_SA")
end

function UMG_TryOn_C:OnTryOnSkillPlayEnd(Event, Skill)
  self:DelayFrames(2, function()
    if self.TryOnSkillCameraActor and UE.UObject.IsValid(self.TryOnSkillCameraActor) then
      self.TryOnSkillCameraActor:K2_DestroyActor()
      self.TryOnSkillCameraActor = nil
    end
    if self.TryOnSkillCameraActorMesh and UE.UObject.IsValid(self.TryOnSkillCameraActorMesh) then
      self.TryOnSkillCameraActorMesh:K2_DestroyActor()
      self.TryOnSkillCameraActorMesh = nil
    end
    self.TryOnSkillCameraActor = Skill.Blackboard:GetValueAsObject("camActor_0001")
    self.TryOnSkillCameraActorMesh = Skill.Blackboard:GetValueAsObject("camActor_0001_SA")
    Skill.Blackboard:RemoveObjectValue("camActor_0001")
    Skill.Blackboard:RemoveObjectValue("camActor_0001_SA")
  end)
end

function UMG_TryOn_C:StopAvatarSkill()
  if not self.TryOnImage.AvatarPlayer and not self.TryOnImage.AvatarPlayer.RocoSkill then
    return
  end
  self.TryOnImage.AvatarPlayer.RocoSkill:StopCurrentSkill()
end

function UMG_TryOn_C:OnTick(deltaSecond)
  if self.TryOnSkillCameraActor and UE.UObject.IsValid(self.TryOnSkillCameraActor) then
    local transform = self.TryOnSkillCameraActor:Abs_GetTransform()
    local camera = self.TryOnSkillCameraActor:GetComponentByClass(UE4.UCameraComponent)
    if camera then
      self.TargetFOV = camera.FieldOfView
    end
    self.MainCamera:Abs_K2_SetActorTransform_WithoutHit(transform)
    if self.TargetFOV then
      self.CurrentFOV = UE4.UKismetMathLibrary.FInterpTo(self.CurrentFOV, self.TargetFOV, deltaSecond, self.FOVInterpSpeed)
      local mainCamComp = self.MainCamera:GetComponentByClass(UE4.UCameraComponent)
      if mainCamComp then
        mainCamComp.FieldOfView = self.CurrentFOV
      end
    end
  end
end

function UMG_TryOn_C:_UpdateButtonPriceColor(packagePrice, suitPrice, costGoodsType, costGoodsId)
  local hasCostMoney = NPCShopUtils:GetGoodsCurrencyNumByType(costGoodsType, costGoodsId) or 0
  if packagePrice then
    if packagePrice <= hasCostMoney then
      self.Btn_Combination:SetQuantityTextColor("050505FF")
    else
      self.Btn_Combination:SetQuantityTextColor("C7494AFF")
    end
  end
  if suitPrice then
    if suitPrice <= hasCostMoney then
      self.Btn_SingleSet:SetQuantityTextColor("050505FF")
    else
      self.Btn_SingleSet:SetQuantityTextColor("C7494AFF")
    end
  end
end

function UMG_TryOn_C:UpdateSingleBtnText(goodsId)
  if not goodsId then
    return
  end
  local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
  local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
  local bOwned = false
  if fashionGoodsConf and fashionGoodsConf.Type and fashionGoodsConf.item_id then
    bOwned = self:CheckOwnedByTypeAndId(fashionGoodsConf.Type, fashionGoodsConf.item_id)
  end
  self.Btn_SingleSet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn_SingleSet:SetBtnText(LuaText.fashion_single_suit)
  local extraPikaPoint = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CalcPikaPoint, self.uiData.shopId, goodsId) or 0
  self:SetSingleBtnText(goodsId, bOwned, extraPikaPoint)
end

function UMG_TryOn_C:SetButtonVisibility(bOwnedPackage)
  if bOwnedPackage then
    self.NRCSwitcher_68:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCSwitcher_68:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_TryOn_C:UpdateTryOnAvatar(initSuit, initSalon)
  self.originalSalon = initSalon
  self.TryOnImage:UpdateSalonIds(initSuit, initSalon)
end

function UMG_TryOn_C:RefreshMoneyList()
  if self.MoneyBtn:GetItemCount() > 0 then
    for i = 1, self.MoneyBtn:GetItemCount() do
      local itemWidget = self.MoneyBtn:GetItemByIndex(i - 1)
      if itemWidget then
        itemWidget:RefreshMoneyNum()
      end
    end
  end
end

function UMG_TryOn_C:InitNormalMode()
  if self.uiData.FashionPackageId then
    local pkgId = 0
    pkgId = self.uiData.FashionPackageId
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(pkgId)
    local packageGoodsData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.uiData.shopId, self.uiData.shopLibId)
    local packageNormalShopConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopLibId)
    if not packageGoodsData then
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:DelaySeconds(0.1, function()
        Log.Error("UMG_TryOn_C:InitNormalMode InvalidGoodServerData", self.uiData.shopId, self.uiData.shopLibId)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.fashionmall_expired)
        self:DoClose()
      end)
    end
    if fashionPackageConf and packageGoodsData and packageNormalShopConf and packageGoodsData.sub_goods then
      self.SuitTitle:SetText(fashionPackageConf.name)
      local defaultSuitId = self.firstSuitId
      local initTable = {}
      for idx, subGoodsData in ipairs(packageGoodsData.sub_goods) do
        local normalShopConf = _G.DataConfigManager:GetNormalShopConf(subGoodsData and subGoodsData.goods_id)
        if normalShopConf then
          local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, normalShopConf.item_id)
          table.insert(initTable, {
            data = normalShopConf,
            parent = self,
            bIsMaxLevel = isUnlockAllComps,
            fashionPackageId = pkgId,
            bIsFree = subGoodsData.is_gift
          })
        end
      end
      table.sort(initTable, function(a, b)
        local goodsTypeA = a and a.data and a.data.type or _G.Enum.GoodsType.GT_NONE
        local goodsTypeB = b and b.data and b.data.type or _G.Enum.GoodsType.GT_NONE
        if goodsTypeA == goodsTypeB and goodsTypeA == _G.Enum.GoodsType.GT_FASHION then
          local fashionItemConfA = _G.DataConfigManager:GetFashionItemConf(a and a.data and a.data.item_id, true)
          local fashionItemConfB = _G.DataConfigManager:GetFashionItemConf(b and b.data and b.data.item_id, true)
          local fashionTypeA = fashionItemConfA and fashionItemConfA.type or _G.Enum.FashionLabelType.FLT_BEGIN
          local fashionTypeB = fashionItemConfB and fashionItemConfB.type or _G.Enum.FashionLabelType.FLT_BEGIN
          return (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeB] or math.maxinteger)
        elseif goodsTypeA and goodsTypeB then
          return (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeB] or math.maxinteger)
        else
          return nil ~= goodsTypeA
        end
      end)
      local defaultIndex = 0
      for k, v in ipairs(initTable) do
        if v.data.item_id == self.firstSuitId then
          defaultIndex = k - 1
          break
        end
      end
      self.Buy_List:InitGridView(initTable)
      self:DelayFrames(1, function()
        self.Buy_List:SelectItemByIndex(defaultIndex)
      end)
      self.TryOnImage:SetFirstSuit(nil, self.originalSalon, defaultSuitId)
    end
    self.Btn_Combination:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_Combination:SetBtnText(LuaText.fashion_package)
    self:SetPkgBtn()
  else
    local showItem = {}
    local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopItemId)
    if fashionGoodsConf then
      table.insert(showItem, {
        goods_shop_id = self.uiData.shopLibId,
        id = fashionGoodsConf.item_id,
        item_id = fashionGoodsConf.item_id,
        item_name = fashionGoodsConf.goods_name,
        type = fashionGoodsConf.Type
      })
      self.SuitTitle:SetText(fashionGoodsConf.goods_name)
      local initTable = {}
      for k, v in ipairs(initTable) do
        table.insert(initTable, {data = v, parent = self})
      end
      self.Buy_List:InitGridView(initTable)
      if fashionGoodsConf.Type == _G.Enum.GoodsType.GT_FASHION_SUITS then
        self.TryOnImage:SetFirstSuit(nil, nil, showItem[1].item_id)
      elseif fashionGoodsConf.Type == _G.Enum.GoodsType.GT_FASHION then
        self.TryOnImage:SetFirstSuit(showItem[1].item_id, nil, nil)
      else
        self.TryOnImage:SetFirstSuit()
      end
      self.Btn_Combination:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:DelayFrames(2, function()
        self.Buy_List:SelectItemByIndex(0)
      end)
    else
      Log.Error(self.uiData.shopItemId, "\230\178\161\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132fashionGoodsConf\233\133\141\231\189\174")
    end
  end
end

function UMG_TryOn_C:BuildGoodsDataFromPackage(packageId, goodsId)
  local result = {}
  result.sub_goods = {}
  local normalShopConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
  if normalShopConf then
    if normalShopConf.goods_list and #normalShopConf.goods_list then
      for idx, id in ipairs(normalShopConf.goods_list) do
        table.insert(result.sub_goods, {
          goods_id = id,
          is_gift = false,
          original_price = {},
          real_price = {}
        })
      end
    end
    if normalShopConf.gift_list and #normalShopConf.gift_list then
      for idx, id in ipairs(normalShopConf.gift_list) do
        table.insert(result.sub_goods, {
          goods_id = id,
          is_gift = true,
          original_price = {},
          real_price = {}
        })
      end
    end
  end
  return result
end

function UMG_TryOn_C:BuildGoodsDataFromSuitId(suitIds)
  local result = {}
  result.sub_goods = {}
  for i, v in ipairs(suitIds) do
    local goodsId
    if self.data.FashionIdToGoodsIdMap[v] then
      if type(self.data.FashionIdToGoodsIdMap[v]) == "table" then
        goodsId = self.data.FashionIdToGoodsIdMap[v].id
      elseif type(self.data.FashionIdToGoodsIdMap[v]) == "number" then
        goodsId = self.data.FashionIdToGoodsIdMap[v]
      end
    end
    if goodsId and 0 ~= goodsId then
      table.insert(result.sub_goods, {
        goods_id = goodsId,
        is_gift = false,
        original_price = {},
        real_price = {}
      })
    end
  end
  return result
end

function UMG_TryOn_C:InitPreviewMode()
  if self.uiData.FashionPackageId then
    local pkgId = 0
    pkgId = self.uiData.FashionPackageId
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(pkgId)
    local packageGoodsData = self:BuildGoodsDataFromPackage(pkgId, self.uiData.shopLibId)
    local packageNormalShopConf = _G.DataConfigManager:GetNormalShopConf(self.uiData.shopLibId)
    if fashionPackageConf and packageGoodsData and packageNormalShopConf and packageGoodsData.sub_goods then
      self.SuitTitle:SetText(fashionPackageConf.name)
      local defaultSuitId = self.firstSuitId
      local initTable = {}
      for idx, subGoodsData in ipairs(packageGoodsData.sub_goods) do
        local normalShopConf = _G.DataConfigManager:GetNormalShopConf(subGoodsData and subGoodsData.goods_id)
        if normalShopConf then
          local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, normalShopConf.item_id)
          table.insert(initTable, {
            data = normalShopConf,
            parent = self,
            bIsMaxLevel = isUnlockAllComps,
            fashionPackageId = pkgId,
            bIsFree = subGoodsData.is_gift,
            bIsPreview = self.bPreviewMode
          })
        end
      end
      table.sort(initTable, function(a, b)
        local goodsTypeA = a and a.data and a.data.type or _G.Enum.GoodsType.GT_NONE
        local goodsTypeB = b and b.data and b.data.type or _G.Enum.GoodsType.GT_NONE
        if goodsTypeA == goodsTypeB and goodsTypeA == _G.Enum.GoodsType.GT_FASHION then
          local fashionItemConfA = _G.DataConfigManager:GetFashionItemConf(a and a.data and a.data.item_id, true)
          local fashionItemConfB = _G.DataConfigManager:GetFashionItemConf(b and b.data and b.data.item_id, true)
          local fashionTypeA = fashionItemConfA and fashionItemConfA.type or _G.Enum.FashionLabelType.FLT_BEGIN
          local fashionTypeB = fashionItemConfB and fashionItemConfB.type or _G.Enum.FashionLabelType.FLT_BEGIN
          return (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_fashionTypePriority[fashionTypeB] or math.maxinteger)
        elseif goodsTypeA and goodsTypeB then
          return (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeA] or math.maxinteger) < (AppearanceModuleEnum.Sort_typeToPriority[goodsTypeB] or math.maxinteger)
        else
          return nil ~= goodsTypeA
        end
      end)
      local defaultIndex = 0
      for k, v in ipairs(initTable) do
        if v.data.item_id == self.firstSuitId then
          defaultIndex = k - 1
          break
        end
      end
      self.Buy_List:InitGridView(initTable)
      self:DelayFrames(1, function()
        self.Buy_List:SelectItemByIndex(defaultIndex)
      end)
      self.TryOnImage:SetFirstSuit(nil, self.originalSalon, defaultSuitId)
    end
  else
    local packageGoodsData = self:BuildGoodsDataFromSuitId(self.previewSuitIds)
    if packageGoodsData and packageGoodsData.sub_goods and 0 ~= #packageGoodsData.sub_goods then
      self.SuitTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
      local initTable = {}
      for k, subGoodsData in ipairs(packageGoodsData.sub_goods) do
        local normalShopConf = _G.DataConfigManager:GetNormalShopConf(subGoodsData and subGoodsData.goods_id)
        local isUnlockAllComps = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsUnlockedAllComponents, normalShopConf.item_id)
        table.insert(initTable, {
          data = normalShopConf,
          parent = self,
          bIsMaxLevel = isUnlockAllComps,
          fashionPackageId = 0,
          bIsFree = subGoodsData.is_gift,
          bIsPreview = self.bPreviewMode
        })
      end
      local defaultIndex = 0
      for k, v in ipairs(initTable) do
        if v.data.item_id == self.firstSuitId then
          defaultIndex = k - 1
          break
        end
      end
      self.Buy_List:InitGridView(initTable)
      self:DelayFrames(1, function()
        self.Buy_List:SelectItemByIndex(defaultIndex)
      end)
      self.TryOnImage:SetFirstSuit(nil, self.originalSalon, self.firstSuitId)
    end
  end
  self.Btn_Combination:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn_Combination:SetBtnText(LuaText.fashion_package)
  self:SetPkgBtn()
end

function UMG_TryOn_C:UpdateSuitTitle(suitId)
  local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if suitsConf and suitsConf.package_id and 0 ~= suitsConf.package_id then
    local packageConf = _G.DataConfigManager:GetFashionPackageConf(suitsConf.package_id)
    if packageConf then
      self.SuitTitle:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SuitTitle:SetText(packageConf.name)
    end
  else
    self.SuitTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TryOn_C:IsPreviewMode()
  return self.bPreviewMode
end

return UMG_TryOn_C

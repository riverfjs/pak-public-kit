local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ShopModuleEvent = reload("NewRoco.Modules.System.Shop.ShopModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PayModuleEvent = require("NewRoco.Modules.System.ChargePay.PayModuleEvent")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local UMG_Shop_C = _G.NRCPanelBase:Extend("UMG_Shop_C")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_CHARGE

function UMG_Shop_C:OnConstruct()
  self.shopTabMallConf = {}
  self.functionBanUIController = FunctionBanUIController()
  local functionBanUIController = self.functionBanUIController
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnShopTabVisibilityChangeHandler, self, -1)
  end
  functionBanUIController:Activate()
end

function UMG_Shop_C:OnDestruct()
  if not self.EnableWorldRender then
    UE4Helper.SetEnableWorldRendering(nil, false, "UMG_Shop_C")
  end
  local functionBanUIController = self.functionBanUIController
  if functionBanUIController then
    functionBanUIController:Deactivate()
  end
end

function UMG_Shop_C:OnActive(index, selectItemID, OpenMallType)
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SHOP)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SHOP)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.index = index
  self.data = self.module:GetData("ShopModuleData")
  self.TOPUPIndex = -1
  self.OpenItemAnimation = true
  self.DeltaTime = 0
  self.CanUpdate = false
  self.ItemDeltaTimer = 0
  self.itemDeltaTime = 0.016
  self.ItemCount = 0
  self.ItemIndex = 0
  self.RefreshItemTimer = 1
  self.CanSelectUpdate = true
  self.deltaTimer = 0
  self:SetCommonTitle()
  self:InitTabList(OpenMallType)
  self:OnAddEventListener()
  self.selectItemID = selectItemID
  if index or OpenMallType and self.index then
    self.TabGridView:SelectItemByIndex(self.index)
  elseif 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self.TabGridView:SelectItemByIndex(1)
  elseif 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self.TabGridView:SelectItemByIndex(2)
  else
    self.TabGridView:SelectItemByIndex(0)
  end
  for i = 1, self.TabGridView:GetItemCount() do
    local item = self.TabGridView:GetItemByIndex(i - 1)
    item.PlayAudio = true
  end
  self.GridView1 = self.ItemGridView
  self.OpenAnim = true
  self:BindInputAction()
  _G.NRCEventCenter:RegisterEvent("UMG_Shop_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.CloseAllBattleChatRelatedUI)
  if self.module and self.module.customCloseAnimName then
    self:SetCustomCloseAnim(self.module.customCloseAnimName)
  end
end

function UMG_Shop_C:OnEnable()
  if self.data then
    self:RefreshItemList()
  end
end

function UMG_Shop_C:_OnPreNtfEnterScene()
  local mappingContext = self:GetInputMappingContext("IMC_ShopUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseShopUI")
    mappingContext:UnBindAction("IA_CloseShopQuick")
  end
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_LevelMain_C:OnSystemShopIconClicked")
  local SourceReturnFlag = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetShopSourceReturnFlag)
  local SourceReturnFunc = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetShopSourceReturnFunc)
  if SourceReturnFlag then
    SourceReturnFunc()
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdSetShopSourceReturnFlag, false)
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  self:DoClose()
end

function UMG_Shop_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SHOP)
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  self:ClearAllEnhancedInput()
  _G.NRCEventCenter:DispatchEvent(ShopModuleEvent.RefreshTopUpRebateData)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:OnRemoveEventListener()
end

function UMG_Shop_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_ShopUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseShopUI", self, "OnPcClose")
    mappingContext:BindAction("IA_CloseShopQuick", self, "OnPcClose")
  end
end

function UMG_Shop_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnCloseBtn()
end

function UMG_Shop_C:InitTabList(OpenMallType)
  local ShopList = table.copy(self.data:GetShopList())
  for i = 1, #ShopList do
    if ShopList[i].shopConf[1].mall_type == Enum.MallType.MT_TOPUP then
      self.TOPUPIndex = i - 1
    end
    if self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[i] then
      ShopList[i].title = self.titleConf.subtitle[i].subtitle
    end
  end
  do
    local index = #ShopList
    while index > 0 do
      local isHide = false
      local mallConf = ShopList[index].shopConf[1]
      local functionEntrance = mallConf and mallConf.system_control_id
      if functionEntrance and 0 ~= functionEntrance then
        isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, functionEntrance)
      end
      if not isHide and mallConf and mallConf.mall_type == Enum.MallType.MT_FASHION then
        local shopData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetCachedShopData, mallConf.shop_id)
        if not (shopData and shopData.goods_data) or 0 == #shopData.goods_data then
          isHide = true
        end
      end
      if isHide then
        table.remove(ShopList, index)
      end
      index = index - 1
    end
    local shopTabMallConf = self.shopTabMallConf
    local functionBanUIController = self.functionBanUIController
    if shopTabMallConf and functionBanUIController then
      for i = 1, #ShopList do
        local mallConf = ShopList[i].shopConf[1]
        shopTabMallConf[i - 1] = mallConf
        local functionEntrance = mallConf and mallConf.system_control_id
        if functionEntrance and 0 ~= functionEntrance then
          functionBanUIController:RegisterCustomCallback(functionEntrance, self.OnShopTabVisibilityChangeHandler, self, i - 1)
        end
      end
    end
  end
  if OpenMallType then
    for i = 1, #ShopList do
      if ShopList[i].shopConf[1].mall_type == OpenMallType then
        self.index = i - 1
      end
    end
  end
  self.TabGridView:Clear()
  self.TabGridView:InitGridView(ShopList)
  self.TabGridView:SetItemCanClickChecker(self.CheckTabCanClick, self)
  self.ShopList = ShopList
end

function UMG_Shop_C:RefreshMoneyInfo()
  local shopId = self.data:GetShopId()
  local showType = _G.DataConfigManager:GetShopConf(shopId)
  local ShowSumMoneyInfo = {}
  local showTypeNum = showType.goods
  if showTypeNum then
    for i, v in ipairs(showTypeNum) do
      local sumMoneyNum = 0
      if v.goods_type == _G.Enum.GoodsType.GT_VITEM then
        sumMoneyNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(v.goods_id) or 0
      elseif v.goods_type == _G.Enum.GoodsType.GT_BAGITEM then
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, v.goods_id)
        if bagItem then
          sumMoneyNum = bagItem.num or 0
        end
      end
      table.insert(ShowSumMoneyInfo, {
        currencyType = v.goods_type,
        currencyId = v.goods_id,
        num = sumMoneyNum,
        showColor = 0,
        showbg = true,
        bigIcon = v.goods_type ~= Enum.VisualItem.VI_COUPON
      })
    end
  end
  self:ShowTopMoney(ShowSumMoneyInfo)
end

function UMG_Shop_C:RefreshItemList()
  local list = self.data:GetItemListData()
  local Shopid = self.data:GetShopId()
  if 8070 == Shopid then
    local found8070InShopList = false
    for i = 1, #self.ShopList do
      if 8070 == self.ShopList[i].shopConf[1].shop_id then
        found8070InShopList = true
        break
      end
    end
    if 0 == #list and found8070InShopList then
      self:_HandleFashionExchangeTabEmpty()
      return
    elseif #list > 0 and not found8070InShopList then
      self:_HandleFashionExchangeTabReappear()
    elseif 0 == #list and not found8070InShopList then
      return
    end
  end
  for i = 1, #self.ShopList do
    if self.ShopList[i].shopConf[1].shop_id == Shopid then
      self.index = i - 1
      self:RefreshCommonTitle(i)
      if self.ShopList[i].shopConf[1].mall_type == Enum.MallType.MT_TOPUP then
        self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Switcher:SetActiveWidgetIndex(1)
        self.MonthlyCard:UnLoadPanel()
        self.GridView1 = self.ItemGridView_Recharge
        break
      end
      if self.ShopList[i].shopConf[1].mall_type == Enum.MallType.MT_MONTHLY_PASS then
        self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.MonthlyCard:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.MonthlyCard:LoadPanel(self, Shopid, list)
        self.GridView1 = nil
        break
      end
      self.GridView1 = self.ItemGridView
      self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Switcher:SetActiveWidgetIndex(0)
      _G.NRCModuleManager:DoCmd(ShopModuleCmd.OnCmdCloseMonthlyCardCheckInProgress)
      self.MonthlyCard:UnLoadPanel()
      break
    end
  end
  if self.GridView1 then
    self.GridView1:InitGridView(list)
    for i, val in ipairs(list) do
      if self.selectItemID and self.selectItemID == val.shopItemId then
        self.GridView1:SelectItemByIndex(i - 1)
        self.selectItemID = nil
      end
    end
  end
  if self.lastShopId and self.lastShopId ~= Shopid then
    self.ScrollBox:SetScrollOffset(0)
    self.ScrollBox_Recharge:SetScrollOffset(0)
  end
  self.lastShopId = Shopid
  self.CanUpdate = false
  self:ItemPlayInAnimation()
  if #list > 10 then
    self.ScrollBox:SetAlwaysShowScrollbar(true)
    self.ScrollBox_Recharge:SetAlwaysShowScrollbar(true)
  else
    self.ScrollBox:SetAlwaysShowScrollbar(false)
    self.ScrollBox_Recharge:SetAlwaysShowScrollbar(true)
  end
  self:InitMoneyTypeList(Shopid)
  if self.OpenAnim then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.In)
    self.OpenAnim = false
  end
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
end

function UMG_Shop_C:InitItemTabList(hasTab, tablist)
  local isBan = self:CheckIfTabBan(self.TabGridView:GetSelectedIndex(), false)
  self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.LianXiButton:SetVisibility(UE4.ESlateVisibility.Visible)
  if hasTab then
    self.UMG_ShopTab2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_ShopTab2:SetTabList(tablist)
    self.UMG_ShopTab2.TabGridView:SelectItemByIndex(0)
    for i = 1, self.UMG_ShopTab2.TabGridView:GetItemCount() do
      local item = self.UMG_ShopTab2.TabGridView:GetItemByIndex(i - 1)
      item.PlayAudio = true
    end
  else
    self.UMG_ShopTab2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Shop_C:RefreshCommonTitle(index)
  if index and self.titleConf and self.titleConf.subtitle and self.titleConf.subtitle[index] then
    self.Title1:SetSubtitle(self.titleConf.subtitle[index].subtitle)
  end
end

function UMG_Shop_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Shop_C:SetItemCanSelected()
  self.TabGridView:SetItemClickAble(self.CanSelectUpdate)
  self.UMG_ShopTab2.TabGridView:SetItemClickAble(self.CanSelectUpdate)
end

function UMG_Shop_C:InitMoneyTypeList(shopid)
  local showType = _G.DataConfigManager:GetShopConf(shopid)
  local ShowSumMoneyInfo = {}
  local showTypeNum = showType and showType.goods
  if showTypeNum then
    for i, v in ipairs(showTypeNum) do
      local sumMoneyNum = 0
      if v.goods_type == _G.Enum.GoodsType.GT_VITEM then
        sumMoneyNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(v.goods_id) or 0
      elseif v.goods_type == _G.Enum.GoodsType.GT_BAGITEM then
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, v.goods_id)
        if bagItem then
          sumMoneyNum = bagItem.num or 0
        end
      end
      table.insert(ShowSumMoneyInfo, {
        currencyType = v.goods_type,
        currencyId = v.goods_id,
        num = sumMoneyNum,
        showColor = 0,
        showbg = true,
        bigIcon = v.goods_type ~= Enum.VisualItem.VI_COUPON
      })
    end
  end
  self:ShowTopMoney(ShowSumMoneyInfo)
end

function UMG_Shop_C:OnPlayerDataUpdate()
  self:RefreshMoneyList()
end

function UMG_Shop_C:RefreshMoneyList()
  for i = 1, self.MoneyBtn:GetItemCount() do
    self.MoneyBtn:GetItemByIndex(i - 1):RefreshMoneyNum()
  end
end

function UMG_Shop_C:ShowTopMoney(DataList)
  local moneyInfo = {}
  for i = 1, #DataList do
    if DataList[i].currencyType == Enum.VisualItem.VI_DIAMOND then
      table.insert(moneyInfo, {
        moneyType = DataList[i].currencyType,
        sum = DataList[i].num,
        IsShowBuyIcon = true,
        currencyType = DataList[i].currencyType,
        currencyId = DataList[i].currencyId
      })
    elseif DataList[i].currencyType == Enum.VisualItem.VI_COUPON then
      if self.data.bInShopRechargePanel then
        table.insert(moneyInfo, {
          moneyType = DataList[i].currencyType,
          sum = DataList[i].num,
          IsShowBuyIcon = false,
          currencyType = DataList[i].currencyType,
          currencyId = DataList[i].currencyId
        })
      else
        table.insert(moneyInfo, {
          moneyType = DataList[i].currencyType,
          sum = DataList[i].num,
          IsShowBuyIcon = true,
          currencyType = DataList[i].currencyType,
          currencyId = DataList[i].currencyId
        })
      end
    else
      table.insert(moneyInfo, {
        moneyType = DataList[i].currencyType,
        sum = DataList[i].num,
        IsShowBuyIcon = false,
        currencyType = DataList[i].currencyType,
        currencyId = DataList[i].currencyId
      })
    end
  end
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_Shop_C:HideOrShowMoneyBtn(_IsHide)
  if _IsHide then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Shop_C:OnRemoveEventListener()
  _G.BattleEventCenter:UnBind(self)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
end

function UMG_Shop_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtn)
  self:AddButtonListener(self.LianXiButton.btnLevelUp, self.OnLianXiButtonClick)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClicked)
  self:RegisterEvent(self, ShopModuleEvent.InitShopTabList, self.InitItemTabList)
  self:RegisterEvent(self, ShopModuleEvent.RefreshShopItemList, self.RefreshItemList)
  self:RegisterEvent(self, ShopModuleEvent.GoTOPUPInShop, self.OnTOPUPInShop)
  self:RegisterEvent(self, ShopModuleEvent.SetItemHidden, self.SetItemCanvasHidden)
  self:RegisterEvent(self, ShopModuleEvent.SetItemRefresh, self.SetItemRefreshTimeOut)
  self:RegisterEvent(self, ShopModuleEvent.CloseRefreshBtn, self.CloseRefreshBtn)
  self:RegisterEvent(self, ShopModuleEvent.SetItemPlayAnimUp, self.ItemPlayAnimUp)
  self:RegisterEvent(self, PayModuleEvent.OnChargeBackgroundSuccess, self.RefreshMoneyInfo)
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_START, BattlePerformEvent.TurnPlayStart)
  _G.NRCEventCenter:RegisterEvent("UMG_Shop_C", self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
end

function UMG_Shop_C:OnLeaveBattle()
  self:DoClose()
end

function UMG_Shop_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.ROUND_START or eventName == BattlePerformEvent.TurnPlayStart then
    self:DoClose()
  end
end

function UMG_Shop_C:OnLianXiButtonClick()
  _G.NRCSDKManager:CustomerService(3)
end

function UMG_Shop_C:OnUserScrolledInfo()
end

function UMG_Shop_C:ItemPlayAnimUp()
  local item1 = self.ItemGridView:GetSelectedItem()
  if item1 then
    item1:PlayAnimUp()
  end
end

function UMG_Shop_C:OnTick(deltaTime)
  self.DeltaTime = self.DeltaTime + deltaTime
  if self.DeltaTime >= 1 then
    self.DeltaTime = 0
    local svr_time = math.floor(_G.ZoneServer:GetServerTime() / 1000)
    self:updateItemTimeCountDown(svr_time)
  end
  if self.CanUpdate then
    self.RefreshItemTimer = self.RefreshItemTimer + deltaTime
    if self.RefreshItemTimer >= 1 then
      self.RefreshItemTimer = 0
      self.CanUpdate = false
      local Shopid = self.data:GetShopId()
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetStoreListReq, Shopid)
    end
  end
  if not self.CanSelectUpdate then
    self.deltaTimer = self.deltaTimer + deltaTime
    if self.deltaTimer >= 0.35 then
      self.deltaTimer = 0
      self.CanSelectUpdate = true
      self:SetItemCanSelected()
    end
  end
end

function UMG_Shop_C:CloseRefreshBtn()
  self.CanSelectUpdate = false
  self:SetItemCanSelected()
  self.data.bInShopRechargePanel = self.TabGridView:IsItemIndexSelected(self.TOPUPIndex + 1)
end

function UMG_Shop_C:SetItemRefreshTimeOut()
  self.CanUpdate = true
end

function UMG_Shop_C:OnCloseBtn()
  if self:IsAnimationPlaying(self.In) then
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_ShopUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseShopUI")
    mappingContext:UnBindAction("IA_CloseShopQuick")
  end
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_LevelMain_C:OnSystemShopIconClicked")
  local SourceReturnFlag = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetShopSourceReturnFlag)
  local SourceReturnFunc = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetShopSourceReturnFunc)
  if SourceReturnFlag then
    SourceReturnFunc()
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdSetShopSourceReturnFlag, false)
  end
  self.EnableWorldRender = true
  UE4Helper.SetEnableWorldRendering(nil, false, "UMG_Shop_C")
  self:StopAllAnimations()
  local closeAnim = self:GetCurrentCloseAnim()
  self:PlayAnimation(closeAnim)
end

function UMG_Shop_C:SetItemCanvasHidden()
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.MonthlyCard:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Shop_C:updateItemTimeCountDown(svr_time)
  local ItemCount = self.GridView1 and self.GridView1:GetItemCount() or 0
  if ItemCount > 0 then
    for i = 1, ItemCount do
      local item = self.GridView1:GetItemByIndex(i - 1)
      item:updateTimeCountDown(svr_time)
    end
  end
  self:DispatchEvent(ShopModuleEvent.updateTipsTimeCountDown, svr_time)
end

function UMG_Shop_C:ItemPlayInAnimation()
  self.ItemCount = self.GridView1 and self.GridView1:GetItemCount() or 0
  self.ItemIndex = 0
  self.OpenItemAnimation = true
end

function UMG_Shop_C:OnTOPUPInShop(specificMallType)
  _G.NRCAudioManager:PlaySound2DAuto(1072, "UMG_Shop_C:OnTOPUPInShop")
  if nil == specificMallType then
    if self.TOPUPIndex >= 0 then
      self.TabGridView:SelectItemByIndex(self.TOPUPIndex)
    end
  else
    local ShopList = self.data:GetShopList()
    if ShopList then
      for i = 1, self.TabGridView:GetItemCount() do
        local item = self.TabGridView:GetItemByIndex(i - 1)
        if item and item.uiData and item.uiData and item.uiData.shopConf and item.uiData.shopConf[1] and item.uiData.shopConf[1].mall_type == specificMallType then
          self.TabGridView:SelectItemByIndex(i - 1)
          break
        end
      end
    end
  end
end

function UMG_Shop_C:OnAnimationFinished(anim)
  if anim == self.Out or anim == self.Out_WithoutBg then
    if 1 == self.index then
      Log.Error("UMG_Shop_C:OnAnimationFinished Out Index == 1")
    end
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
    self:DoClose()
    _G.NRCModuleManager:DoCmd(StarChainModuleCmd.ShowOrHideMapRecoveryTime, true)
  elseif anim == self.In or anim == self.Loop then
    self:PlayAnimation(self.Loop)
  end
  if anim == self.In then
    UE4Helper.SetEnableWorldRendering(false, false, "UMG_Shop_C")
  end
end

function UMG_Shop_C:CheckIfTabBan(tabIndex, showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  if not isBan and tabIndex then
    local mallConf = self.shopTabMallConf[tabIndex]
    local functionEntrance = mallConf and mallConf.system_control_id
    if functionEntrance and 0 ~= functionEntrance then
      isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, functionEntrance, showMsg)
    end
  end
  return isBan
end

function UMG_Shop_C:CheckTabCanClick(tabItem, tabIndex, userClick)
  if userClick then
    return not self:CheckIfTabBan(tabIndex, true)
  end
  return true
end

function UMG_Shop_C:OnShopTabVisibilityChangeHandler(tabIndex, funcId, bHide)
  if funcId == FunctionEntranceMain or tabIndex == self.TabGridView:GetSelectedIndex() then
    local isBan = bHide or self:CheckIfTabBan(tabIndex, false)
    self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Shop_C:OnBlockBtnClicked()
  local isBan = self:CheckIfTabBan(self.TabGridView:GetSelectedIndex(), true)
  if not isBan then
    Log.Error("UMG_Shop_C:OnBlockBtnClicked: isBan is false")
  end
end

function UMG_Shop_C:_RefreshTabGridViewAfterChange(selectIndex)
  self.TabGridView:Clear()
  self.TabGridView:InitGridView(self.ShopList)
  self.TabGridView:SetItemCanClickChecker(self.CheckTabCanClick, self)
  self.shopTabMallConf = {}
  for i = 1, #self.ShopList do
    self.shopTabMallConf[i - 1] = self.ShopList[i].shopConf[1]
  end
  self.TOPUPIndex = -1
  for i = 1, #self.ShopList do
    if self.ShopList[i].shopConf[1].mall_type == Enum.MallType.MT_TOPUP then
      self.TOPUPIndex = i - 1
      break
    end
  end
  if #self.ShopList > 0 and selectIndex >= 0 then
    self.TabGridView:SelectItemByIndex(selectIndex)
  end
end

function UMG_Shop_C:_HandleFashionExchangeTabEmpty()
  local removedIndex
  local currentSelectedIndex = self.TabGridView:GetSelectedIndex()
  for i = #self.ShopList, 1, -1 do
    if self.ShopList[i].shopConf[1].shop_id == 8070 then
      removedIndex = i - 1
      table.remove(self.ShopList, i)
      break
    end
  end
  if nil == removedIndex then
    return
  end
  if 0 == #self.ShopList then
    self:_RefreshTabGridViewAfterChange(-1)
    return
  end
  local newSelectIndex
  if currentSelectedIndex == removedIndex then
    newSelectIndex = 0
  else
    newSelectIndex = currentSelectedIndex
    if currentSelectedIndex > removedIndex then
      newSelectIndex = currentSelectedIndex - 1
    end
  end
  self:_RefreshTabGridViewAfterChange(newSelectIndex)
end

function UMG_Shop_C:_HandleFashionExchangeTabReappear()
  local fullShopList = self.data:GetShopList()
  local shop8070Data
  for i = 1, #fullShopList do
    if fullShopList[i].shopConf[1].shop_id == 8070 then
      shop8070Data = fullShopList[i]
      break
    end
  end
  if not shop8070Data then
    return
  end
  local insertPos = #self.ShopList + 1
  local shop8070TabId = shop8070Data.shopConf[1].tab_id_1
  for i = 1, #self.ShopList do
    if shop8070TabId > self.ShopList[i].shopConf[1].tab_id_1 then
      insertPos = i
      break
    end
  end
  table.insert(self.ShopList, insertPos, shop8070Data)
  local currentSelectedIndex = self.TabGridView:GetSelectedIndex()
  local newSelectIndex = currentSelectedIndex
  local insertedIndex = insertPos - 1
  if currentSelectedIndex >= insertedIndex then
    newSelectIndex = currentSelectedIndex + 1
  end
  self:_RefreshTabGridViewAfterChange(newSelectIndex)
end

function UMG_Shop_C:SetCustomCloseAnim(animName)
  self.customCloseAnimName = animName
end

function UMG_Shop_C:GetCurrentCloseAnim()
  if self.customCloseAnimName and self[self.customCloseAnimName] then
    return self[self.customCloseAnimName]
  end
  return self.Out
end

return UMG_Shop_C

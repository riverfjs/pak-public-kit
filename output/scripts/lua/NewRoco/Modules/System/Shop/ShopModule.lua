local ShopModuleEvent = reload("NewRoco.Modules.System.Shop.ShopModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local ShopItemFilename = "ShopItem"
local MonthlyCardTipsFilename = "MonthlyCardTipsFilename"
local ShopModule = NRCModuleBase:Extend("ShopModule")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local PayModuleEvent = require("NewRoco.Modules.System.ChargePay.PayModuleEvent")
local PayEnum = require("NewRoco.Modules.System.ChargePay.PayEnum")
local ShopModuleSortData = require("NewRoco.Modules.System.Shop.ShopModuleSortData")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local MonthlyCardBuyStatus = {
  None = 0,
  Buying = 1,
  WaitingRefresh = 2
}

function ShopModule:OnConstruct()
  _G.ShopModuleCmd = reload("NewRoco.Modules.System.Shop.ShopModuleCmd")
  self.data = self:SetData("ShopModuleData", "NewRoco.Modules.System.Shop.ShopModuleData")
  self:RegPanel("Shop", "UMG_Shop", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true, nil, "Out", true)
  self:RegPanel("ShopBuyTips", "UMG_Shop_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MonthlyCardTips", "UMG_MonthlyCard_Tips", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true, "In", "Out")
  self:RegPanel("DiamondExchangePanel", "UMG_Shop_Exchange", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out")
  self:RegPanel("MonthlyCardCheckInProgress", "UMG_MonthlyCard_CheckInProgress", _G.Enum.UILayerType.UI_LAYER_POPUP, nil)
  self.ExChangeDiamondNum = nil
end

function ShopModule:OnCmdOpenExchangePanel(ExchangeConf, maxItemCount, defaultItemCount)
  self:OpenPanel("DiamondExchangePanel", ExchangeConf, maxItemCount, defaultItemCount)
end

function ShopModule:OnActive()
  self:InitMonthCardData()
  _G.NRCEventCenter:RegisterEvent("ShopModule", self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("ShopModule", self, PayModuleEvent.MidasPaySuccess, self.OnMidasPaySuccess)
  _G.NRCEventCenter:RegisterEvent("ShopModule", self, PayModuleEvent.MidasPayFailed, self.OnMidasPayFailed)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_RSP, self.OnZoneMonthCardGetInfoRsp)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_NTY, self.OnZoneMonthCardGetInfoNty)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.OnZoneGoodsRewardNotify)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  end
  local ShopConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.MALL_FRAME_CONF)
  local ShopID = 8000
  for _, _Conf in pairs(ShopConf) do
    if _Conf.mall_type and _Conf.mall_type == Enum.MallType.MT_MONTHLY_PASS then
      ShopID = _Conf.shop_id
      break
    end
  end
  local reqShopData = {
    shopId = ShopID,
    Caller = self,
    rspHandler = self.GetMonthShopDataRspHandler,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "ShopModule:GetMonthShopDataRspHandler"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
  local monthCardTipsCache = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TryGetCardTipsCache)
  if monthCardTipsCache then
    self:TryOpenMonthCardTips(monthCardTipsCache.reward, monthCardTipsCache.index)
  end
end

function ShopModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, PayModuleEvent.MidasPaySuccess, self.OnMidasPaySuccess)
  _G.NRCEventCenter:UnRegisterEvent(self, PayModuleEvent.MidasPayFailed, self.OnMidasPayFailed)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_RSP, self.OnZoneMonthCardGetInfoRsp)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_NTY, self.OnZoneMonthCardGetInfoNty)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.OnZoneGoodsRewardNotify)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    _G.NRCSDKManager:RemoveEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  end
end

function ShopModule:GetMonthShopDataRspHandler()
  Log.Debug("ShopModule:GetMonthShopDataRspHandler")
end

function ShopModule:OnZoneGoodsRewardNotify(notify)
  Log.Dump(notify, 6, "ShopModule::OnZoneGoodsRewardNotify")
  local goods_reward = notify.ret_info and notify.ret_info.goods_reward
  local RewardList = goods_reward and goods_reward.rewards or {}
  local Items = {}
  for _, reward in ipairs(RewardList) do
    if reward.reward_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_DISTRIBUTE_REWARD then
      table.insert(Items, reward)
    end
  end
  if #Items > 0 then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, Items, LuaText.emailmodule_1, nil, true, nil, true)
  end
end

function ShopModule:OnRelogin()
end

function ShopModule:OnDestruct()
end

function ShopModule:OnEnterSceneFinishNtyAck()
  self:InitMonthCardData()
end

function ShopModule:OnMidasPaySuccess(goodsType, shopID)
  Log.Debug("OnMidasPaySuccess with goodsType:", goodsType, "shopID:", shopID)
  if self.monthCardBuyStatus == MonthlyCardBuyStatus.Buying and goodsType == PayEnum.PayType.DirectPurchase then
    self.monthCardBuyStatus = MonthlyCardBuyStatus.WaitingRefresh
  end
  if goodsType == PayEnum.PayType.DirectPurchase and nil ~= shopID and 0 ~= shopID then
    Log.Debug("OnMidasPaySuccess with shopID:", shopID)
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, shopID)
  end
end

function ShopModule:OnMidasPayFailed()
  self.monthCardBuyStatus = MonthlyCardBuyStatus.None
end

function ShopModule:OnWebViewOptNotify()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    self.monthCardBuyStatus = MonthlyCardBuyStatus.None
  end
end

function ShopModule:SetUpdateTimeOut()
  self:DispatchEvent(ShopModuleEvent.SetItemRefresh)
end

function ShopModule:InRechargePanel()
  if self:HasPanel("Shop") then
    return self.data.bInShopRechargePanel or false
  end
  return false
end

function ShopModule:OpenTopUpShop(bDisableWarn, specificMallType)
  if self:InRechargePanel() then
    return false
  end
  if bDisableWarn then
    self:InternalOpenTopUpShop(true, specificMallType)
  else
    local Ctx = DialogContext()
    Ctx:SetTitle(LuaText.TIPS)
    Ctx:SetContent(LuaText.Recharge_Tips1)
    Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
    if specificMallType then
      local function internalOpenTopUpShopWrapper(InShopModule, bOk)
        if InShopModule and InShopModule.InternalOpenTopUpShop then
          InShopModule:InternalOpenTopUpShop(bOk, specificMallType)
        end
      end
      
      Ctx:SetCallbackOkOnly(self, internalOpenTopUpShopWrapper)
    else
      Ctx:SetCallbackOkOnly(self, self.InternalOpenTopUpShop)
    end
    Ctx:SetCloseOnCancel(true)
    Ctx:SetButtonText(LuaText.YES, LuaText.NO)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
  end
  return true
end

function ShopModule:InternalOpenTopUpShop(bOk, specificMallType)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CHARGE, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_CHARGE, true)
  if isBan or isHide then
    return
  end
  if nil == specificMallType then
    specificMallType = Enum.MallType.MT_TOPUP
  end
  if self:HasPanel("Shop") then
    self:DispatchEvent(ShopModuleEvent.GoTOPUPInShop, specificMallType)
    if self:HasPanel("ShopBuyTips") then
      local panel = self:GetPanel("ShopBuyTips")
      panel:OnCancel()
    end
  else
    local ShopList = self.data:GetShopList()
    local index = 0
    for i = 1, #ShopList do
      if ShopList[i].shopConf[1].mall_type == specificMallType then
        index = i - 1
      end
    end
    _G.NRCModuleManager:DoCmd(StarChainModuleCmd.ShowOrHideMapRecoveryTime, false)
    local reqShopData = {
      shopId = 8070,
      Caller = self,
      rspHandler = self.GetExchangeFashionShopDataRsp,
      needModal = false,
      ignoreErrorTip = true,
      reqTag = "ShopModule:InternalOpenTopUpShop"
    }
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
    self.needToOpenShopMallType = specificMallType
    self.needToOpenShopIndex = index
  end
end

function ShopModule:OnCmdHideOrShowMoneyBtn(_IsHide)
  if self:HasPanel("Shop") then
    local panel = self:GetPanel("Shop")
    panel:HideOrShowMoneyBtn(_IsHide)
  end
end

function ShopModule:OnCmdOpenPikaRandomStore()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShop, _G.AppearanceModuleEnum.FashionMallShopId.RANDOM_FASHION)
end

function ShopModule:OnCmdEnableOrDisableShopOnPopUpOpen(isEnable, bNeedClose)
  if self:HasPanel("ShopBuyTips") then
    local panel = self:GetPanel("ShopBuyTips")
    if bNeedClose then
      panel:DoClose()
    elseif isEnable then
      panel:SetNeedAnimOnDisable(false)
      panel:Enable()
    else
      panel:SetNeedAnimOnDisable(true)
      panel:Disable()
    end
  end
end

function ShopModule:OpenExchangeDiamond()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_DIAMOND_EXCHANGE, true)
  if isBan then
    return
  end
  local ExchangeIdConf = _G.DataConfigManager:GetPaymentGlobalConfig("EUT_DIAMOND_USE_COUPON")
  if not ExchangeIdConf then
    self:LogError("cannot found exchange id conf in payment global conf, key=EUT_DIAMOND_USE_COUPON")
    return
  end
  local ExchangeId = ExchangeIdConf.num
  local ExchangeConf = DataConfigManager:GetExchangeConf(ExchangeId)
  if not ExchangeConf then
    self:LogError("cannot found invalid exchange config")
    return
  end
  if ExchangeConf.use_type ~= Enum.ExchangeUseType.EUT_DIAMOND_USE_COUPON then
    self:LogError("use type invalid, Enum.ExchangeUseType.EUT_DIAMOND_USE_COUPON expected", ExchangeId, ExchangeConf.use_type)
    return
  end
  if not ExchangeConf.cost_item[1] or not ExchangeConf.get_item[1] then
    self:LogError("not cost item or get item", ExchangeId)
    return
  end
  if ExchangeConf.cost_item[1].cost_goods_id[1] ~= Enum.VisualItem.VI_COUPON or ExchangeConf.get_item[1].get_goods_id ~= Enum.VisualItem.VI_DIAMOND then
    self:LogError("invalid params, ", ExchangeConf.cost_item[1].cost_goods_id[1], ExchangeConf.get_item[1].get_goods_id)
    return
  end
  local UseItemType = ExchangeConf.cost_item[1].cost_goods_id[1]
  local UseItemCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(UseItemType)
  local UseItemPerCount = ExchangeConf.cost_item[1].cost_goods_num
  local MaxiItemCount = math.floor(UseItemCount / UseItemPerCount)
  self:OpenPanel("DiamondExchangePanel", ExchangeConf, MaxiItemCount)
  return true
end

function ShopModule:OpenExchangePoint(VI_type)
  local exchangeConf = _G.DataConfigManager:GetExchangeConf(_G.DataConfigManager:GetVisualItemConf(VI_type).exchange_id)
  local NPCShopUIModule = _G.NRCModuleManager:GetModule("NPCShopUIModule")
  if NPCShopUIModule:HasPanel("NPCShop") then
    local NPCShop = NPCShopUIModule:GetPanel("NPCShop")
    local MaxiItemCount = 0
    for _, v in ipairs(NPCShop.uiData.itemList1) do
      MaxiItemCount = MaxiItemCount + (v.limitNum - v.boughtNum) * v.priceNum
    end
    MaxiItemCount = math.max(MaxiItemCount - _G.DataModelMgr.PlayerDataModel:GetVItemCount(VI_type), 0)
    local UseItemType = exchangeConf.cost_item[1].cost_goods_id[1]
    local UseItemCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(UseItemType)
    local UseItemPerCount = exchangeConf.cost_item[1].cost_goods_num
    local MaxiItemCount2 = math.floor(UseItemCount / UseItemPerCount)
    local defaultNum = math.min(MaxiItemCount, MaxiItemCount2)
    if UseItemType ~= Enum.VisualItem.VI_COUPON then
      MaxiItemCount = math.min(MaxiItemCount, MaxiItemCount2)
    end
    self:OpenPanel("DiamondExchangePanel", exchangeConf, MaxiItemCount, defaultNum)
  end
end

function ShopModule:ExchangeDiamond()
  if not self.ExChangeDiamondNum then
    return
  end
  local CanBuy = self:JudgeBuyCouponGiftItem(self.ExChangeDiamondNum)
  if CanBuy then
    local ExchangeIdConf = _G.DataConfigManager:GetPaymentGlobalConfig("EUT_DIAMOND_USE_COUPON")
    if not ExchangeIdConf then
      self:LogError("cannot found exchange id conf in payment global conf, key=EUT_DIAMOND_USE_COUPON")
      return
    end
    local ExchangeId = ExchangeIdConf.num
    local ExchangeConf = DataConfigManager:GetExchangeConf(ExchangeId)
    if not ExchangeConf then
      self:LogError("cannot found invalid exchange config")
      return
    end
    if ExchangeConf.use_type ~= Enum.ExchangeUseType.EUT_DIAMOND_USE_COUPON then
      self:LogError("use type invalid, Enum.ExchangeUseType.EUT_DIAMOND_USE_COUPON expected", ExchangeId, ExchangeConf.use_type)
      return
    end
    if not ExchangeConf.cost_item[1] or not ExchangeConf.get_item[1] then
      self:LogError("not cost item or get item", ExchangeId)
      return
    end
    if ExchangeConf.cost_item[1].cost_goods_id[1] ~= Enum.VisualItem.VI_COUPON or ExchangeConf.get_item[1].get_goods_id ~= Enum.VisualItem.VI_DIAMOND then
      self:LogError("invalid params, ", ExchangeConf.cost_item[1].cost_goods_id[1], ExchangeConf.get_item[1].get_goods_id)
      return
    end
    local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      local ActorId = localPlayer.serverData.base.actor_id
      local ExchangeNum = 0
      if ExchangeConf and ExchangeConf.cost_item and ExchangeConf.cost_item[1] and ExchangeConf.cost_item[1].cost_goods_num and ExchangeConf.cost_item[1].cost_goods_num > 0 then
        ExchangeNum = math.floor(self.ExChangeDiamondNum / ExchangeConf.cost_item[1].cost_goods_num)
      end
      self:Log("ExchangeDiamond,", ExchangeConf.id, self.ExChangeDiamondNum, 1, ActorId, ExchangeConf.cost_item[1].cost_goods_id)
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SendExchangeReq, ExchangeConf.id, ExchangeNum, 1, ActorId, ExchangeConf.cost_item[1].cost_goods_id)
    end
  end
  self.ExChangeDiamondNum = nil
end

function ShopModule:OnCmdOpenMonthlyCardCheckInProgress(_tips)
  if self:HasPanel("MonthlyCardCheckInProgress") then
    return
  end
  self:OpenPanel("MonthlyCardCheckInProgress", _tips)
end

function ShopModule:OnCmdCloseMonthlyCardCheckInProgress(_tips)
  if not self:HasPanel("MonthlyCardCheckInProgress") then
    return
  end
  self:ClosePanel("MonthlyCardCheckInProgress", _tips)
end

function ShopModule:JudgeBuyCouponGiftItem(CostCouponNum)
  local PlayerCouponNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(Enum.VisualItem.VI_COUPON)
  if CostCouponNum <= PlayerCouponNum then
    return true
  end
  local NeedCouponNum = CostCouponNum - PlayerCouponNum
  local ItemConf = DataConfigManager:GetVisualItemConf(Enum.VisualItem.VI_COUPON)
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.TIPS)
  Ctx:SetContent(string.format(LuaText.Recharge_Tips3, NeedCouponNum, ItemConf.displayName))
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetCallbackOkOnly(self, self.OpenTopUpShop)
  Ctx:SetCloseOnCancel(true)
  Ctx:SetButtonText(LuaText.YES, LuaText.NO)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
  return false
end

function ShopModule:JudgeBuyDiamondGiftItem(CostDiamondNum)
  local PlayerDiamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(Enum.VisualItem.VI_DIAMOND)
  if CostDiamondNum <= PlayerDiamondNum then
    return true
  end
  local NeedDiamondNum = CostDiamondNum - PlayerDiamondNum
  local ItemConf = DataConfigManager:GetVisualItemConf(Enum.VisualItem.VI_DIAMOND)
  local CostItemConf = DataConfigManager:GetVisualItemConf(Enum.VisualItem.VI_COUPON)
  self.ExChangeDiamondNum = NeedDiamondNum
  local ExchangeIdConf = _G.DataConfigManager:GetPaymentGlobalConfig("EUT_DIAMOND_USE_COUPON")
  if ExchangeIdConf then
    local ExchangeId = ExchangeIdConf.num
    local ExchangeConf = DataConfigManager:GetExchangeConf(ExchangeId)
    if ExchangeConf and ExchangeConf.cost_item and ExchangeConf.cost_item[1] and ExchangeConf.cost_item[1].cost_goods_num then
      self.ExChangeDiamondNum = NeedDiamondNum * ExchangeConf.cost_item[1].cost_goods_num
    end
  end
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.TIPS)
  Ctx:SetContent(string.format(LuaText.Recharge_Tips2, NeedDiamondNum, ItemConf.displayName, self.ExChangeDiamondNum, CostItemConf.displayName))
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetCallbackOkOnly(self, self.ExchangeDiamond)
  Ctx:SetCloseOnCancel(true)
  Ctx:SetButtonText(LuaText.YES, LuaText.NO)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog2, Ctx)
  return false
end

function ShopModule:JudgeUpgradeSuitLevel(CostPikaPointNum)
  local PlayerPikaPointNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PIKA_POINT)
  if CostPikaPointNum <= PlayerPikaPointNum then
    return true
  end
  local NeedPikaPointNum = CostPikaPointNum - PlayerPikaPointNum
  local ItemConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_PIKA_POINT)
  local Ctx = DialogContext()
  Ctx:SetTitle(_G.LuaText.TIPS)
  Ctx:SetContent(string.format(LuaText.Recharge_Tips3, NeedPikaPointNum, ItemConf.displayName))
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetCallbackOkOnly(self, self.OnJudgeUpgradeSuitLevelClickOkButton)
  Ctx:SetCloseOnCancel(true)
  Ctx:SetButtonText(_G.LuaText.YES, _G.LuaText.NO)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
  return false
end

function ShopModule:OnJudgeUpgradeSuitLevelClickOkButton()
  self:OpenTopUpShop(true, Enum.MallType.MT_CREDIT)
end

function ShopModule:CmdCloseRefreshBtn()
  self:DispatchEvent(ShopModuleEvent.CloseRefreshBtn)
end

function ShopModule:OnOpenMainPanel(tableIndex, selectItemIndex, mallType)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CHARGE)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_CHARGE)
  if isBan or isHide then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip6)
    end
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
    return
  end
  local index = 0
  if tableIndex and tableIndex >= 1 then
    index = tableIndex - 1
  end
  if self:HasPanel("Shop") then
    local needCloseFirst = _G.NRCPanelManager:CheckNeedCloseFirst(self:GetPanelData("Shop"))
    if needCloseFirst then
      self:ClosePanel("Shop")
    else
      local Panel = self:GetPanel("Shop")
      if Panel.index ~= index and Panel:CheckTabCanClick(nil, index, true) then
        Panel.TabGridView:SelectItemByIndex(index)
      end
      if self:HasPanel("ShopBuyTips") then
        local panel = self:GetPanel("ShopBuyTips")
        panel:OnCancel()
      end
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
      return
    end
  end
  self.data:InitShopList()
  local shopList = self.data:GetShopList()
  if shopList then
    local shopData = shopList[index + 1]
    if shopData and shopData.shopConf then
      local selectMallConf = shopData.shopConf[1]
      local tabEntrance = selectMallConf and selectMallConf.system_control_id
      if tabEntrance and 0 ~= tabEntrance then
        local tabIsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, tabEntrance, true)
        if tabIsBan then
          _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
          return
        end
      end
    end
  end
  local reqShopData = {
    shopId = 8070,
    Caller = self,
    rspHandler = self.GetExchangeFashionShopDataRsp,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "ShopModule:InternalOpenTopUpShop"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
  self.needToOpenShopIndex = index
  self.needToOpenShopSelectItemIndex = selectItemIndex
  self.needToOpenShopMallType = _G.Enum.MallType[mallType]
end

function ShopModule:EnableMainPanel()
  local panel = self:GetPanel("Shop")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function ShopModule:PreLoadMainPanel()
  self:PreLoadPanel("Shop", 10)
end

function ShopModule:CloseMainPanel()
  if self:HasPanel("Shop") then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
    self:ClosePanel("Shop")
  end
end

function ShopModule:OnCmdGetStoreListReq(shopId)
  self:DispatchEvent(ShopModuleEvent.SetItemHidden)
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, shopId)
end

function ShopModule:GetStoreListRsp(_rsp)
  Log.Dump(_rsp, 5, "ShopModule:GetStoreListRsp")
  local itemListInfo = {}
  if _rsp.shop_data == nil then
    return
  end
  local shopId = _rsp.shop_data.id
  local itemListInfo = ShopModuleSortData:ProcessShopGoodsDataOptimized(_rsp.shop_data.goods_data, shopId)
  self.data:SetItemListData(itemListInfo)
  self.data:SetShopId(shopId)
  self:DispatchEvent(ShopModuleEvent.RefreshShopItemList)
end

function ShopModule:OnCmdMallBuyItemReq(itemInfo)
  local ItemInfo = {itemInfo}
  self.shopItemId = itemInfo.shopItemId
  self.selectedNum = itemInfo.selectedNum
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.MallBuyItemReq, self.data.ShopId, ItemInfo)
end

function ShopModule:OnCmdGetIsHiddenShopItemRed(shopid)
  local ShopItemFile = JsonUtils.LoadSaved(ShopItemFilename, {})
  local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_MALLGOODS_POINT_REWARD)
  local delimiter = "."
  local subValues = {}
  if pointData and #pointData > 0 then
    for _, v in pairs(pointData) do
      local index = 0
      local IsShopItemValue = false
      for subValue in string.gmatch(v, "([^" .. delimiter .. "]+)") do
        index = index + 1
        if shopid then
          if 1 == index and shopid == tonumber(subValue) then
            IsShopItemValue = true
          end
          if 2 == index and IsShopItemValue then
            table.insert(subValues, subValue)
          end
        elseif 2 == index then
          index = 0
          table.insert(subValues, subValue)
        end
      end
    end
  end
  for i, v in pairs(subValues) do
    if ShopItemFile[i] then
    else
      return false
    end
  end
  return true
end

function ShopModule:MallBuyItemRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:OnCmdGetStoreListReq(_rsp.shop_id)
    local CommonPopUpData
    local rewardlsit = {}
    local GoodsConf = _G.DataConfigManager:GetNormalShopConf(self.shopItemId)
    if GoodsConf.Type == Enum.GoodsType.GT_REWARD then
      local rewardconf = _G.DataConfigManager:GetRewardConf(GoodsConf.item_id)
      for i = 1, #rewardconf.RewardItem do
        local rewarditem = {
          id = rewardconf.RewardItem[i].Id,
          type = rewardconf.RewardItem[i].Type,
          num = rewardconf.RewardItem[i].Count
        }
        table.insert(rewardlsit, #rewardlsit + 1, rewarditem)
      end
    elseif GoodsConf.Type == Enum.GoodsType.GT_BAGITEM then
      local Bagitemconf = _G.DataConfigManager:GetBagItemConf(GoodsConf.item_id)
      local rewarditem = {
        id = Bagitemconf.id,
        type = Enum.GoodsType.GT_BAGITEM,
        num = self.selectedNum * GoodsConf.item_num
      }
      table.insert(rewardlsit, 1, rewarditem)
    elseif GoodsConf.Type == Enum.GoodsType.GT_VITEM then
      local Bagitemconf = _G.DataConfigManager:GetVisualItemConf(GoodsConf.item_id)
      local rewarditem = {
        id = Bagitemconf.id,
        type = Enum.GoodsType.GT_VITEM,
        num = self.selectedNum * GoodsConf.item_num
      }
      table.insert(rewardlsit, 1, rewarditem)
    end
    if _rsp.shop_id == 8070 then
      CommonPopUpData = _G.NRCCommonPopUpData()
      CommonPopUpData.OnlyHideRightBtn = true
      CommonPopUpData.Call = self
      CommonPopUpData.Btn_LeftHandler = self.OnMallBuyItemRspPopupClickGoToUseButton
    end
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardlsit, "", nil, nil, nil, nil, nil, CommonPopUpData)
  end
end

function ShopModule:OnMallBuyItemRspPopupClickGoToUseButton()
  self:CloseMainPanel()
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanelByTableIndex, 3)
end

function ShopModule:OnOpenShopTipsPanel(data)
  self:OpenPanel("ShopBuyTips", data)
end

function ShopModule:InitShopTabList(ShopId, hasTab)
  self:DispatchEvent(ShopModuleEvent.InitShopTabList, ShopId, hasTab)
end

function ShopModule:RegPanel(name, path, layer, customDisableRendering, openAnim, closeAnim, autoSetDesiredCursor)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Shop/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.openAnimName = openAnim
  registerData.closeAnimName = closeAnim
  registerData.autoSetDesiredCursor = autoSetDesiredCursor
  self:RegisterPanel(registerData)
end

function ShopModule:OnCmdGetShopSourceReturnFlag()
  return self.data:GetShopSourceReturnFlag()
end

function ShopModule:OnCmdSetShopSourceReturnFlag(flag)
  self.data:SetShopSourceReturnFlag(flag)
end

function ShopModule:OnCmdGetShopSourceReturnFunc()
  return self.data:GetShopSourceReturnFunc()
end

function ShopModule:OnCmdSetShopSourceReturnFunc(func)
  self.data:SetShopSourceReturnFunc(func)
end

function ShopModule:InitMonthCardData()
  if not self.monthCardInit then
    self.monthCardInit = _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_REQ, _G.ProtoMessage:newZoneMonthCardGetInfoReq())
  end
end

function ShopModule:CanOpenRepeatMonthlyCardTips(continue_time, IsDailyTipsShow)
  if IsDailyTipsShow and 0 ~= IsDailyTipsShow then
    return
  end
  
  local function IsExactlyFourOClock(_timestamp)
    local timestamp = math.floor(_timestamp)
    local hour = tonumber(os.date("%H", timestamp))
    local minute = tonumber(os.date("%M", timestamp))
    local second = tonumber(os.date("%S", timestamp))
    return 4 == hour and 0 == minute and 0 == second
  end
  
  local RepeatDayNum = _G.DataConfigManager:GetGlobalConfigNumByKey("yueka_tips_param2", 1)
  local severTime = _G.ZoneServer:GetServerTime()
  severTime = math.floor(severTime / 1000)
  local outOfDay = (severTime - (continue_time + 86400)) / 86400
  if outOfDay >= 0 and RepeatDayNum > outOfDay then
    self:SendZoneRptMonthCardTipsShowReq()
    local tip = TipObject.CreateMonthlyCardDailyRewardTips("NullType", "NullId")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, tip)
  end
end

function ShopModule:SendZoneRptMonthCardTipsShowReq()
  if self.data.monthCardData then
    self.data.monthCardData.daily_tips_show = 1
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_RPT_MONTH_CARD_TIPS_SHOW_REQ, _G.ProtoMessage:newZoneRptMonthCardTipsShowReq())
end

function ShopModule:OnZoneMonthCardGetInfoRsp(_protoData)
  if _protoData and 0 == _protoData.ret_info.ret_code then
    self.monthCardBuyStatus = MonthlyCardBuyStatus.None
    self.data:UpdateMonthCardData(_protoData.month_data)
    if _protoData.month_data and _protoData.month_data.continue_time then
      self:CanOpenRepeatMonthlyCardTips(_protoData.month_data.continue_time, _protoData.month_data.daily_tips_show)
    end
  end
end

function ShopModule:OnZoneMonthCardGetInfoNty(_protoData)
  if _protoData then
    self.monthCardBuyStatus = MonthlyCardBuyStatus.None
    self.data:UpdateMonthCardData(_protoData.month_data)
  end
end

function ShopModule:TryOpenMonthCardTips(reward, order)
  if not reward then
    return
  end
  if self.data.monthCardData then
    self:SendZoneRptMonthCardTipsShowReq()
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateMonthlyCardDailyRewardTips(reward.type, reward.id, reward.num, order))
  else
    self.monthCardTipsReward = reward
    self.monthCardTipsOrder = order
    self.monthCardInit = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MONTH_CARD_GET_INFO_REQ, _G.ProtoMessage:newZoneMonthCardGetInfoReq(), self, self.TryGetMonthCardGetInfoRsp, true, true)
  end
end

function ShopModule:TryGetMonthCardGetInfoRsp(_protoData)
  if _protoData and 0 == _protoData.ret_info.ret_code then
    self.data:UpdateMonthCardData(_protoData.month_data)
    if self.monthCardTipsReward then
      self:SendZoneRptMonthCardTipsShowReq()
      local reward = self.monthCardTipsReward
      local order = self.monthCardTipsOrder or 0
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateMonthlyCardDailyRewardTips(reward.type, reward.id, reward.num, order))
    end
  end
  self.monthCardTipsReward = nil
  self.monthCardTipsOrder = nil
end

function ShopModule:OnCmdGetClientMonthCardConf()
  return self.data:GetClientMonthCardConf()
end

function ShopModule:OnCmdGetMonthCardData()
  return self.data:GetMonthCardData()
end

function ShopModule:OnCmdSetBuyingMonthCard()
  self.monthCardBuyStatus = MonthlyCardBuyStatus.Buying
end

function ShopModule:OnCmdCanBuyMonthCard()
  local status = self.monthCardBuyStatus
  if status and status ~= MonthlyCardBuyStatus.None then
    return false
  end
  return true
end

function ShopModule:OnCmdOpenMonthlyCardTips(_tip)
  if self:HasPanel("MonthlyCardTips") then
    return
  end
  self:OpenPanel("MonthlyCardTips", _tip)
end

function ShopModule:OnCmdGetGoodsReturnAmount(goodsType, goodsId, playerGender)
  return self.data:GetGoodsReturnAmount(goodsType, goodsId, playerGender)
end

function ShopModule:OnCmdGetGlobalConfigKeyByNum(num)
  return self.data:GetGlobalConfigKeyByNum(num)
end

function ShopModule:GetExchangeFashionShopDataRsp(rsp)
  self:OpenPanel("Shop", self.needToOpenShopIndex, self.needToOpenShopSelectItemIndex, self.needToOpenShopMallType)
  self.needToOpenShopIndex = nil
  self.needToOpenShopSelectItemIndex = nil
  self.needToOpenShopMallType = nil
  if self.customCloseAnimName and self:HasPanel("Shop") then
    local panel = self:GetPanel("Shop")
    panel:SetCustomCloseAnim(self.customCloseAnimName)
  end
end

function ShopModule:OnCmdSetCustomCloseAnim(animName)
  self.customCloseAnimName = animName
  if self:HasPanel("Shop") then
    local panel = self:GetPanel("Shop")
    panel:SetCustomCloseAnim(animName)
  end
end

function ShopModule:OnCmdResetCloseAnim()
  self.customCloseAnimName = nil
  if self:HasPanel("Shop") then
    local panel = self:GetPanel("Shop")
    panel:SetCustomCloseAnim(nil)
  end
end

return ShopModule

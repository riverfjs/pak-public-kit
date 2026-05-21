local NPCShopUIModule = NRCModuleBase:Extend("NPCShopUIModule")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local NPCShopUIModuleEnum = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEnum")

function NPCShopUIModule:OnConstruct()
  _G.NPCShopUIModuleCmd = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleCmd")
  self.data = self:SetData("NPCShopUIModuleData", "NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleData")
  self.ReqShopDataMap = {}
  self.ReqBuyItemDataMap = {}
  self.BatchGetShopData = nil
end

function NPCShopUIModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  NRCEventCenter:UnRegisterEvent(self, NRCPanelEvent.OpenPanelFailed, self.OnOpenPanelFailed)
end

function NPCShopUIModule:OnActive()
  Log.Debug("\230\179\168\229\134\140\229\145\189\228\187\164NPCShopMainPanel")
  self:RegisterCmd(NPCShopUIModuleCmd.OpenNPCShopMainPanel, self.OpenNPCShopMainPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.GetStoreListReq, self.OnCmdGetStoreListReq)
  self:RegisterCmd(NPCShopUIModuleCmd.TestGetAppearanceStoreListReq, self.CmdTestGetAppearanceStoreListReq)
  self:RegisterCmd(NPCShopUIModuleCmd.TestGetBeautyStoreListReq, self.CmdTestGetBeautyStoreListReq)
  self:RegisterCmd(NPCShopUIModuleCmd.MallBuyItemReq, self.OnCmdMallBuyItemReq)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenNPCShopConfirm, self.OnCmdOpenNPCShopConfirmPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenNPCShopConfirmNew, self.OnCmdOpenNPCShopConfirmPanelNew)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenNPCShopClaimReward, self.OnCmdOpenNPCShopClaimReward)
  self:RegisterCmd(NPCShopUIModuleCmd.RefreshClaimRewardPanel, self.OnCmdRefreshClaimRewardPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.PlayHappyAnimAfterBuying, self.OnCmdPlayHappyAnimAfterBuying)
  self:RegisterCmd(NPCShopUIModuleCmd.RefreshNPCShopPanel, self.OnCmdRefreshNPCShopPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.FinishNPCActionOpenShop, self.OnCmdFinishNPCActionOpenShop)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenPVPShop, self.OnCmdOpenPvPShop)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenShopById, self.OnCmdOpenShopById)
  self:RegisterCmd(NPCShopUIModuleCmd.FinishNPCActionOpenGPShop, self.OnCmdFinishNPCActionOpenGPShop)
  self:RegisterCmd(NPCShopUIModuleCmd.SetNpcShopOpenType, self.OnCmdNpcShopOpenType)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, self.OnCmdOpenNPCShopItemRewardsPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.ActionOpenNPCShopItemRewardsPanel, self.ActionOpenNPCShopItemRewardsPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.CloseNPCShopItemRewardsPanel, self.CmdCloseNPCShopItemRewardsPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdSetUpdateTimeOut, self.SetUpdateTimeOut)
  self:RegisterCmd(NPCShopUIModuleCmd.GetPackageContentHadOwnedWhenPurchase, self.OnCmdGetPackageContentHadOwnedWhenPurchase)
  self:RegisterCmd(NPCShopUIModuleCmd.HideOrShowNPCShopMoneyBtn, self.OnCmdHideOrShowNPCShopMoneyBtn)
  self:RegisterCmd(NPCShopUIModuleCmd.SetMysteriousStoreShopList, self.OnCmdSetMysteriousStoreShopList)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenPlaneSellConfirm, self.OnCmdOpenPlaneSellConfirm)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdReqGetShopData, self.OnCmdReqGetShopData)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdBuyItemReq, self.OnCmdBuyItemReq)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, self.OnCmdGetGoodsSeverData)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdGetSubGoodsSeverData, self.OnCmdGetSubGoodsSeverData)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdGetShopVersion, self.OnCmdGetShopVersion)
  self:RegisterCmd(NPCShopUIModuleCmd.OpenNPCShopTempPanel, self.OnCmdOpenNPCShopTempPanel)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdBatchGetShopData, self.OnCmdBatchGetShopData)
  self:RegisterCmd(NPCShopUIModuleCmd.TestBatchGetShopData, self.TestBatchGetShopData)
  self:RegisterCmd(NPCShopUIModuleCmd.OnCmdGetCachedShopData, self.OnCmdGetCachedShopData)
  _G.NRCEventCenter:RegisterEvent("NPCShopUIModule", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  NRCEventCenter:RegisterEvent("BagModule", self, SceneEvent.LoadMapStart, self.ChangeScene)
  NRCEventCenter:RegisterEvent("NPCShopUIModule", self, NRCPanelEvent.OpenPanelFailed, self.OnOpenPanelFailed)
  NRCEventCenter:RegisterEvent("NPCShopUIModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.bForceNPCShopCache = false
  self.IsOpenShopTemp = false
  if _G.bForceNPCShopCache then
    self:RegPanel("NPCShop", "UMG_NPCShop", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, NRCPanelRegisterData.PanelCacheType.PreCache, nil, true)
  else
    self:RegPanel("NPCShop", "UMG_NPCShop", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_3DUI2, true)
  end
  self:RegPanel("NPCShopConfirm", "UMG_NPCShopConfirm", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NPCShopConfirmNew", "UMG_NPCShop_Purchase", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NPCShopClaimReward", "UMG_NPCShop_ClaimReward", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NPCShopItemRewards", "UMG_ItemRewards", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NPCShopTemp", "UMG_NPCShop_Temp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NPCShopPlantSell", "UMG_NPCShop_PlantAcquisition", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, _G.NRCPanelEnum.PanelTypeEnum.PANEL_3DUI2, true)
  self:RegPanel("NPCShopPlantSellConfirm", "UMG_SellPlants", _G.Enum.UILayerType.UI_LAYER_POPUP)
end

function NPCShopUIModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function NPCShopUIModule:OnReconnect()
  Log.Debug("NPCShopUIModule:OnReconnect")
  if self.ReqShopDataMap then
    self.ReqShopDataMap = {}
  end
  if self.ReqBuyItemDataMap then
    self.ReqBuyItemDataMap = {}
  end
end

function NPCShopUIModule:ChangeScene()
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.ChangeScene)
end

function NPCShopUIModule:OnOpenPanelFailed(reason, panelData)
  if reason == NRCPanelEnum.OpenFailedReason.RspError and panelData.panelName == "NPCShop" and self.data.NPCActionOpenShop ~= nil then
    self.data.NPCActionOpenShop:Finish()
    self.data.NPCActionOpenShop = nil
  end
end

function NPCShopUIModule:OnDialogueEnded(bIsConnected)
  if bIsConnected then
    self:ClosePanel("NPCShopConfirm")
  end
end

function NPCShopUIModule:OnCmdOpenNPCShopMainPanel(_PanelName, _param, _param1, _param2)
  if _G.bForceNPCShopCache and self.IsOpenShopTemp == false then
    self:EnablePanel(_PanelName, 1, _param, _param1, _param2)
    local panel = self:GetPanel(_PanelName)
    panel:Active(_param, _param1, _param2)
  else
    self:OpenPanel(_PanelName, _param, _param1, _param2)
  end
end

function NPCShopUIModule:OnCmdOpenNPCShopConfirmPanel(_param, _param1)
  self:OpenPanel("NPCShopConfirm", _param, _param1)
end

function NPCShopUIModule:OnCmdOpenNPCShopConfirmPanelNew(_param, _param1, _param2, _param3)
  self:OpenPanel("NPCShopConfirmNew", _param, _param1, _param2, _param3)
end

function NPCShopUIModule:OnCmdOpenNPCShopClaimReward(_param, _param1)
  self:OpenPanel("NPCShopClaimReward", _param, _param1)
end

function NPCShopUIModule:OnCmdRefreshClaimRewardPanel()
  if self:HasPanel("NPCShopClaimReward") then
    local panel = self:GetPanel("NPCShopClaimReward")
    panel:RefreshInfos()
  end
end

function NPCShopUIModule:OnCmdPlayHappyAnimAfterBuying()
  if self:HasPanel("NPCShop") then
    local panel = self:GetPanel("NPCShop")
    panel:PlayHappyAnimAfterBuying()
  end
end

function NPCShopUIModule:OnCmdHideOrShowNPCShopMoneyBtn(_IsShow)
  if self:HasPanel("NPCShop") then
    local panel = self:GetPanel("NPCShop")
    panel:HideOrShowMoneyBtn(_IsShow)
  end
end

function NPCShopUIModule:OnCmdRefreshNPCShopPanel(_rsp)
  if self:HasPanel("NPCShop") then
    local panel = self:GetPanel("NPCShop")
    panel:RefreshInfos(_rsp)
  end
end

function NPCShopUIModule:OnCmdOpenNPCShopItemRewardsPanel(_param, _param1, IsLevelReward, IsOpenByBattleRewardPanel, IsOpenLegendaryBattleClosePanel, IsWorldOpen, bIsSpecialAward, PopUpData, IsBestowBlessings)
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, _param, _param1, IsLevelReward, IsOpenByBattleRewardPanel, IsOpenLegendaryBattleClosePanel, IsWorldOpen, bIsSpecialAward, PopUpData, IsBestowBlessings)
end

function NPCShopUIModule:ActionOpenNPCShopItemRewardsPanel(reward_id, action, IsWorldOpen)
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.ActionOpenNPCShopItemRewardsPanel, reward_id, action, IsWorldOpen)
end

function NPCShopUIModule:CmdCloseNPCShopItemRewardsPanel()
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.CloseNPCShopItemRewardsPanel)
end

function NPCShopUIModule:SetUpdateTimeOut()
  if self:HasPanel("NPCShop") then
    local panel = self:GetPanel("NPCShop")
    panel:SetItemRefreshTimeOut()
  end
end

function NPCShopUIModule:OnCmdOpenNPCShopTempPanel()
  local shopId = 2001
  self.IsOpenShopTemp = true
end

function NPCShopUIModule:CmdTestGetAppearanceStoreListReq()
  local req = _G.ProtoMessage:newZoneShopGetInfoReq()
  req.shop_id = 101
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ClosePanelLobbyMain)
  local reqShopData = {
    shopId = 101,
    Caller = self,
    rspHandler = self.GetShopDataRspHandler,
    needModal = false,
    ignoreErrorTip = false,
    reqTag = "NPCShopUIModule:CmdTestGetAppearanceStoreListReq"
  }
  self:OnCmdReqGetShopData(reqShopData)
end

function NPCShopUIModule:CmdTestGetBeautyStoreListReq()
  local req = _G.ProtoMessage:newZoneShopGetInfoReq()
  req.shop_id = 102
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ClosePanelLobbyMain)
  local reqShopData = {
    shopId = 102,
    Caller = self,
    rspHandler = self.GetShopDataRspHandler,
    needModal = false,
    ignoreErrorTip = false,
    reqTag = "NPCShopUIModule:CmdTestGetBeautyStoreListReq"
  }
  self:OnCmdReqGetShopData(reqShopData)
end

function NPCShopUIModule:OnCmdGetStoreListReq(shopId)
  local req = _G.ProtoMessage:newZoneShopGetInfoReq()
  req.shop_id = shopId
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_GET_INFO_REQ, true, "NPCShop")
  local reqShopData = {
    shopId = shopId,
    Caller = self,
    rspHandler = self.GetShopDataRspHandler,
    needModal = false,
    ignoreErrorTip = false,
    reqTag = "NPCShopUIModule:OnCmdGetStoreListReq"
  }
  self:OnCmdReqGetShopData(reqShopData)
end

function NPCShopUIModule:OnCmdMallBuyItemReq(shopId, itemInfo)
  local req = _G.ProtoMessage:newZoneShopBuyItemReq()
  local goodsType = ProtoEnum.ShopGoodsType.SGT_GOODS
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  local shopType = shopConf.shop_type
  if 101 == shopId or shopType == Enum.ShopType.ST_FASHION_CLOSET then
    goodsType = ProtoEnum.ShopGoodsType.SGT_FASHION_GOODS
  elseif 102 == shopId then
    goodsType = ProtoEnum.ShopGoodsType.SGT_SALON_GOODS
  else
    goodsType = ProtoEnum.ShopGoodsType.SGT_GOODS
  end
  local systemshoplist = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MALL_FRAME_CONF):GetAllDatas()
  for i = 1, #systemshoplist do
    if systemshoplist[i].shop_id == shopId then
      goodsType = ProtoEnum.ShopGoodsType.SGT_MALL_GOODS
      break
    end
  end
  local itemCnt = #itemInfo
  for i = 1, itemCnt do
    if itemInfo[i].selectedNum > 0 then
      table.insert(req.buy_item_info, {
        goods_shop_id = itemInfo[i].shopLibId,
        goods_item_num = itemInfo[i].selectedNum,
        goods_id = itemInfo[i].shopItemId or itemInfo[i].shopLibId
      })
    end
  end
  req.shop_id = shopId
  local contentID = self.data:GetNPCContentID(shopId)
  if contentID then
    Log.Debug("NPCShopUIModule:OnCmdMallBuyItemReq contentID", shopId, contentID)
    req.content_id = contentID
  end
  local reqBuyItemData = {
    req = req,
    Caller = self,
    rspHandler = self.MallBuyItemRspHandler,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "NPCShopUIModule:OnCmdMallBuyItemReq"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdBuyItemReq, reqBuyItemData)
end

function NPCShopUIModule:OnCmdNpcShopOpenType(OpenType)
  self.data:SetOpenNpcShopType(OpenType)
end

function NPCShopUIModule:OnCmdOpenPvPShop()
  self:OnCmdFinishNPCActionOpenShop(nil, 2004)
end

function NPCShopUIModule:OnCmdOpenShopById(shopId)
  if not shopId then
    return
  end
  if type(shopId) == "string" then
    shopId = tonumber(shopId)
  end
  if 0 ~= shopId then
    self:OnCmdFinishNPCActionOpenShop(nil, shopId)
  end
end

function NPCShopUIModule:OnCmdFinishNPCActionOpenShop(NPCAction, ShopId, param)
  self.data.NPCActionOpenShop = NPCAction
  _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.SetNPCActionOpenShop, NPCAction)
  local shopId = 2001
  if NPCAction and NPCAction.Config.action_param1 then
    shopId = tonumber(NPCAction.Config.action_param1)
  elseif ShopId then
    shopId = ShopId
  end
  Log.Debug(shopId, "24124124124124")
  if 101 ~= shopId and 102 ~= shopId then
    local reqParamList = _G.NRCPanelOpenReqData()
    reqParamList.cmdId = _G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_GET_INFO_REQ
    reqParamList.reqClass = _G.ProtoMessage:newZoneShopGetInfoReq()
    reqParamList.paramList = {shop_id = shopId}
    reqParamList.ignoreErrorTip = false
    reqParamList.needModal = false
    reqParamList.NPCAction = NPCAction
    reqParamList.Caller = self
    reqParamList.Callback = self.GetShopDataRsp
    local shopConf = DataConfigManager:GetShopConf(shopId)
    local shopType = shopConf.shop_type
    if shopType == _G.Enum.ShopType.ST_FASHION_TAILOR then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenTailorShop, shopId, reqParamList)
    elseif shopType == _G.Enum.ShopType.ST_FASHION_PIKA or shopType == _G.Enum.ShopType.ST_FASHION_RANDOM or shopType == _G.Enum.ShopType.ST_FASHION_DISCOUNT then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShopDirectly, shopId, param, reqParamList)
    elseif shopType == _G.Enum.ShopType.ST_EXCHANGE then
      self:OpenPanel("NPCShopPlantSell", shopId, reqParamList, _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
    else
      self:OpenPanel("NPCShop", shopId, reqParamList, _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
    end
  end
end

function NPCShopUIModule:OnCmdFinishNPCActionOpenGPShop(NPCAction, ShopId)
  self.data.NPCActionOpenShop = NPCAction
  local shopId = 2005
  if NPCAction and NPCAction.Config.action_param1 then
    shopId = tonumber(NPCAction.Config.action_param1)
  elseif ShopId then
    shopId = ShopId
  end
  if 101 ~= shopId and 102 ~= shopId then
    local reqParamList = _G.NRCPanelOpenReqData()
    reqParamList.cmdId = _G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_GET_INFO_REQ
    reqParamList.reqClass = _G.ProtoMessage:newZoneShopGetInfoReq()
    reqParamList.paramList = {shop_id = shopId}
    reqParamList.ignoreErrorTip = false
    reqParamList.needModal = false
    reqParamList.Caller = self
    reqParamList.Callback = self.GetShopDataRsp
    self:OpenPanel("NPCShop", shopId, reqParamList, _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
  end
end

function NPCShopUIModule:RegPanel(name, path, layer, cacheType, panelType, customDisableRendering)
  cacheType = cacheType or NRCPanelRegisterData.PanelCacheType.DonntCache
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/NPCShopUI/Res/%s", path)
  registerData.panelLayer = layer
  registerData.panelCacheType = cacheType
  registerData.panelType = panelType
  registerData.customDisableRendering = customDisableRendering or false
  self:RegisterPanel(registerData)
end

function NPCShopUIModule:OnCmdGetPackageContentHadOwnedWhenPurchase(shopLibId)
  return self.data.PackageContentHadOwnedWhenPurchase[shopLibId]
end

function NPCShopUIModule:OnCmdSetMysteriousStoreShopList(itemInfo)
  return self.data:SetMysteriousStoreShopList(itemInfo)
end

function NPCShopUIModule:CloseNPCShopPanel()
  if self:HasPanel("NPCShop") and self:IsPanelEnabled("NPCShop") then
    local panel = self:GetPanel("NPCShop")
    if panel and panel.OnCloseButtonClicked then
      panel:OnCloseButtonClicked()
    end
  end
end

function NPCShopUIModule:OnCmdOpenPlaneSellConfirm(...)
  self:OpenPanel("NPCShopPlantSellConfirm", ...)
end

function NPCShopUIModule:OnCmdReqGetShopData(reqShopData)
  if not reqShopData then
    Log.Error("NPCShopUIModule:OnCmdReqGetShopData", "reqShopData is nil")
    return
  end
  local req = _G.ProtoMessage:newZoneShopGetInfoReq()
  local shopId = reqShopData.shopId
  req.shop_id = shopId
  local ReqList = self.ReqShopDataMap[shopId]
  if nil == ReqList then
    ReqList = {}
    self.ReqShopDataMap[shopId] = ReqList
  end
  Log.Info("NPCShopUIModule:OnCmdReqGetShopData", shopId, "reqTag:", reqShopData.reqTag)
  local bSuccess = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_GET_INFO_REQ, req, self, self.GetShopDataRsp, reqShopData.needModal, true)
  if not bSuccess then
    Log.Error("NPCShopUIModule:OnCmdReqGetShopData", "send request failed", shopId, reqShopData.reqTag)
  else
    table.insert(ReqList, reqShopData)
    Log.Info("NPCShopUIModule:OnCmdReqGetShopData", "send request success", shopId, reqShopData.reqTag)
  end
  return bSuccess
end

function NPCShopUIModule:GetShopDataRsp(rsp)
  if not rsp then
    Log.Error("NPCShopUIModule:GetShopDataRsp", "rsp is nil")
    if self:HasPanel("NPCShop") or self:IsPanelInOpening("NPCShop") then
      self:ClosePanel("NPCShop")
    end
    return
  end
  if rsp.ret_info == nil then
    Log.Error("NPCShopUIModule:GetShopDataRsp", "ret_info is nil")
    if self:HasPanel("NPCShop") or self:IsPanelInOpening("NPCShop") then
      self:ClosePanel("NPCShop")
    end
    return
  end
  if 0 ~= rsp.ret_info.ret_code then
    if rsp.ret_info.ret_code ~= ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_SHOP_DATA_NEWEST then
      Log.Error("NPCShopUIModule:GetShopDataRsp", "ret_code:", rsp.ret_info.ret_code)
      if self:HasPanel("NPCShop") or self:IsPanelInOpening("NPCShop") then
        self:ClosePanel("NPCShop")
      end
      return
    else
      Log.Info("NPCShopUIModule:GetShopDataRsp use cache data", "ret_code:", rsp.ret_info.ret_code)
    end
  end
  Log.Info("NPCShopUIModule:GetShopDataRsp")
  if rsp.shop_data and rsp.shop_data.id then
    self.data:SetShopData(rsp)
    local shopId = rsp.shop_data.id
    local reqShopDataList = self.ReqShopDataMap[shopId]
    if reqShopDataList then
      for _, reqShopData in ipairs(reqShopDataList) do
        if reqShopData and reqShopData.Caller and reqShopData.rspHandler then
          local ShopRsp = self.data:GetShopData(shopId)
          if ShopRsp then
            reqShopData.rspHandler(reqShopData.Caller, ShopRsp)
          else
            Log.Warning("NPCShopUIModule:GetShopDataRsp", "ShopRsp is nil", shopId)
          end
        else
          Log.Warning("NPCShopUIModule:GetShopDataRsp", "reqShopData is nil or reqShopData.Caller is nil or reqShopData.rspHandler is nil", shopId)
        end
      end
    end
    self.ReqShopDataMap[shopId] = nil
  else
    Log.Warning("NPCShopUIModule:GetShopDataRsp", "shop_data is nil or shop_data.id is nil")
  end
end

function NPCShopUIModule:OnCmdBuyItemReq(reqBuyItemData)
  if not reqBuyItemData then
    Log.Error("NPCShopUIModule:OnCmdBuyItemReq", "reqBuyItemData is nil")
    return
  end
  local req = reqBuyItemData.req
  local shopId = req.shop_id
  local ReqList = self.ReqBuyItemDataMap[shopId]
  if nil == ReqList then
    ReqList = {}
    self.ReqBuyItemDataMap[shopId] = ReqList
  end
  local version = self.data:GetShopDataVersion(shopId)
  req.version = version
  Log.Dump(req, 6, "NPCShopUIModuleDump---NPCShopUIModule:OnCmdBuyItemReq")
  local bSuccess = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_BUY_ITEM_REQ, req, self, self.BuyItemRsp, reqBuyItemData.needModal, reqBuyItemData.ignoreErrorTip)
  if not bSuccess then
    Log.Error("NPCShopUIModule:OnCmdBuyItemReq", "send request failed", shopId, reqBuyItemData.reqTag)
  else
    table.insert(ReqList, reqBuyItemData)
    Log.Info("NPCShopUIModule:OnCmdBuyItemReq", "send request success", shopId, reqBuyItemData.reqTag)
  end
  return bSuccess
end

function NPCShopUIModule:BuyItemRsp(rsp)
  if not rsp then
    Log.Error("NPCShopUIModule:BuyItemRsp", "rsp is nil")
    return
  end
  local shopId = rsp.shop_id
  local reqBuyItemDataList = self.ReqBuyItemDataMap[shopId]
  if reqBuyItemDataList then
    for _, reqBuyItemData in ipairs(reqBuyItemDataList) do
      if reqBuyItemData and reqBuyItemData.Caller and reqBuyItemData.rspHandler then
        reqBuyItemData.rspHandler(reqBuyItemData.Caller, rsp)
      else
        Log.Error("NPCShopUIModule:BuyItemRsp", "reqBuyItemData is nil or reqBuyItemData.Caller is nil or reqBuyItemData.rspHandler is nil", reqBuyItemData.reqTag)
      end
    end
    self.ReqBuyItemDataMap[shopId] = nil
  else
    Log.Warning("NPCShopUIModule:BuyItemRsp", "reqBuyItemDataList is nil", shopId)
  end
  if nil ~= rsp.shop_data then
    Log.Info("NPCShopUIModule:BuyItemRsp", "NPCSHOP_REFRESH_SHOP_DATA", rsp.shop_data.id)
    self:DispatchEvent(NPCShopUIModuleEvent.NPCSHOP_REFRESH_SHOP_DATA, rsp.shop_data)
  end
  if 0 == rsp.ret_info.ret_code or rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_SHOP_VERSION_NOT_MATCH then
    self:OnCmdGetStoreListReq(shopId)
  end
end

function NPCShopUIModule:OnCmdGetShopVersion(shopId)
  local version = self.data:GetShopDataVersion(shopId)
  if version then
    return version
  end
  return 0
end

function NPCShopUIModule:OnCmdGetGoodsSeverData(shopID, goodsID, ignoreWarning)
  local goodsData = self.data:GetGoodsSeverData(shopID, goodsID, ignoreWarning)
  if goodsData then
    return goodsData
  end
  return nil
end

function NPCShopUIModule:OnCmdGetSubGoodsSeverData(shopID, goodsID, subGoodsID)
  local subGoodsData = self.data:GetSubGoodsSeverData(shopID, goodsID, subGoodsID)
  if subGoodsData then
    return subGoodsData
  end
  return nil
end

function NPCShopUIModule:GetShopDataRspHandler(_rsp)
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_GET_INFO_REQ, false, "NPCShop")
  Log.Dump(_rsp, 8, "NPCShopUIModuleDump---NPCShopUIModule:GetShopDataRspHandler_Dump")
  if not _rsp or not _rsp.shop_data then
    Log.Warning("NPCShopUIModule:GetShopDataRspHandler", "Invalid shop data response", _rsp and "shop_data is nil" or "response is nil")
    return
  end
  local shopId = _rsp.shop_data.id
  Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Processing shop data for shopId", shopId)
  if self:IsRechargeShop(shopId) then
    Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Redirecting to recharge shop module", shopId)
    _G.NRCModuleManager:DoCmd(ShopModuleCmd.OnCmdGetStoreListRsp, _rsp)
    return
  end
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  if not shopConf then
    Log.Error("NPCShopUIModule:GetShopDataRspHandler", "Shop config not found", shopId)
    return
  end
  local moneyType = self:ExtractMoneyTypes(shopConf)
  self.data.showMoneyType = moneyType
  Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Extracted money types", moneyType)
  self.lastRefresh = 0
  local nextRefresh = 0
  local myShopType = shopConf.shop_type
  Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Shop type", myShopType)
  if self.IsOpenShopTemp then
    Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Processing temp shop", shopId)
    self:ProcessTempShop(_rsp, shopId, moneyType, nextRefresh)
    return
  end
  if self:IsFashionShop(myShopType) then
    Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Processing fashion shop", shopId, myShopType)
    self:ProcessFashionShop(shopId, _rsp, myShopType, nextRefresh)
    return
  end
  if self:IsExchangeShop(myShopType) then
    Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Processing exchange shop", shopId, myShopType)
    self:ProcessExchangeShop(shopId, _rsp, myShopType, nextRefresh)
    return
  end
  Log.Info("NPCShopUIModule:GetShopDataRspHandler", "Processing normal shop", shopId)
  self:ProcessNormalShop(shopId, _rsp, nextRefresh)
end

function NPCShopUIModule:IsRechargeShop(shopId)
  local systemshoplist = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MALL_FRAME_CONF):GetAllDatas()
  if not systemshoplist then
    Log.Warning("NPCShopUIModule:IsRechargeShop", "Failed to get system shop list")
    return false
  end
  for i, v in pairs(systemshoplist) do
    if systemshoplist[i].shop_id == shopId then
      Log.Info("NPCShopUIModule:IsRechargeShop", "Found recharge shop", shopId)
      return true
    end
  end
  Log.Debug("NPCShopUIModule:IsRechargeShop", "Not a recharge shop", shopId)
  return false
end

function NPCShopUIModule:ExtractMoneyTypes(shopConf)
  local moneyType = {}
  if not shopConf or not shopConf.goods then
    Log.Warning("NPCShopUIModule:ExtractMoneyTypes", "Invalid shop config or vitem_type is nil")
    return moneyType
  end
  for k, v in pairs(shopConf.goods) do
    if v.goods_type == Enum.GoodsType.GT_VITEM and v.goods_id ~= nil then
      table.insert(moneyType, v.goods_id)
    end
  end
  Log.Debug("NPCShopUIModule:ExtractMoneyTypes", "Extracted money types count", #moneyType)
  return moneyType
end

function NPCShopUIModule:ProcessTempShop(_rsp, shopId, moneyType, nextRefresh)
  local itemListInfo = {}
  if not _rsp.shop_data.goods_data then
    Log.Warning("NPCShopUIModule:ProcessTempShop", "No goods data in temp shop", shopId)
  else
    Log.Info("NPCShopUIModule:ProcessTempShop", "Processing goods data", shopId, #_rsp.shop_data.goods_data)
    for k, v in ipairs(_rsp.shop_data.goods_data) do
      local goodsConf = _G.DataConfigManager:GetNormalShopConf(v.goods_id)
      if not goodsConf then
        Log.Warning("NPCShopUIModule:ProcessTempShop", "Goods config not found", v.goods_id, v.goods_shop_id)
      else
        table.insert(itemListInfo, {
          shopItemId = v.goods_id,
          shopLibId = v.goods_shop_id,
          priceNum = v.real_price.num or 0,
          itemId = goodsConf.item_id,
          limitType = goodsConf.buy_cond_type,
          limitNum = v.limit_buy_num,
          boughtNum = v.buy_num,
          selectedNum = 0,
          selectedState = false,
          npcShopId = shopId,
          showMoneyType = moneyType,
          showMoneyCost = {
            0,
            0,
            0
          },
          next_refresh_time = v.next_refresh_time
        })
      end
    end
  end
  Log.Info("NPCShopUIModule:ProcessTempShop", "Built item list", shopId, #itemListInfo)
  if self:HasPanel("NPCShopTemp") and self:IsPanelEnabled("NPCShopTemp") then
    Log.Info("NPCShopUIModule:ProcessTempShop", "Refreshing temp panel", shopId)
    NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL, itemListInfo, shopId, nextRefresh)
  else
    Log.Info("NPCShopUIModule:ProcessTempShop", "Opening temp panel", shopId)
    self:OnCmdOpenNPCShopMainPanel("NPCShopTemp", itemListInfo, shopId, nextRefresh)
  end
  self.IsOpenShopTemp = false
  Log.Info("NPCShopUIModule:ProcessTempShop", "Temp shop processing completed", shopId)
end

function NPCShopUIModule:IsFashionShop(myShopType)
  local isFashion = myShopType == _G.Enum.ShopType.ST_FASHION_PIKA or myShopType == _G.Enum.ShopType.ST_FASHION_RANDOM or myShopType == _G.Enum.ShopType.ST_FASHION_DISCOUNT or myShopType == _G.Enum.ShopType.ST_FASHION_CLOSET or myShopType == _G.Enum.ShopType.ST_FASHION_TAILOR
  Log.Debug("NPCShopUIModule:IsFashionShop", "Shop type check", myShopType, isFashion)
  return isFashion
end

function NPCShopUIModule:ProcessFashionShop(shopId, _rsp, myShopType, nextRefresh)
  if myShopType == _G.Enum.ShopType.ST_FASHION_TAILOR then
    Log.Info("NPCShopUIModule:ProcessFashionShop", "Processing tailor shop", shopId)
    NRCModuleManager:GetModule("AppearanceModule"):DispatchEvent(AppearanceModuleEvent.TailorShopReceiveShopData, shopId, _rsp, nextRefresh)
  else
    Log.Info("NPCShopUIModule:ProcessFashionShop", "Processing other fashion shop", shopId, myShopType)
    NRCModuleManager:DoCmd(AppearanceModuleCmd.GetStoreListRsp, _rsp)
  end
end

function NPCShopUIModule:ProcessNormalShop(shopId, _rsp, nextRefresh)
  if self:HasPanel("NPCShop") and self:IsPanelEnabled("NPCShop") then
    Log.Info("NPCShopUIModule:ProcessNormalShop", "Refreshing normal shop panel", shopId)
    NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL, shopId, _rsp, nextRefresh)
  else
    Log.Info("NPCShopUIModule:ProcessNormalShop", "Normal shop panel not available", shopId)
  end
end

function NPCShopUIModule:MallBuyItemRspHandler(_rsp)
  self:DispatchEvent(NPCShopUIModuleEvent.OnReceiveMallBuyItemRspHandler)
  local shopType
  local shopConf = DataConfigManager:GetShopConf(_rsp.shop_id)
  if shopConf then
    shopType = shopConf.shop_type
  end
  Log.Info("NPCShopUIModule:MallBuyItemRspHandler", "Processing purchase response", shopId, _rsp.ret_info.ret_code, shopType)
  if 0 ~= _rsp.ret_info.ret_code then
    Log.Warning("NPCShopUIModule:MallBuyItemRspHandler", "Purchase failed", shopId, _rsp.ret_info.ret_code)
    self:HandlePurchaseFailure(_rsp, shopType)
    return
  end
  Log.Info("NPCShopUIModule:MallBuyItemRspHandler", "Purchase successful", shopId)
  self:HandlePurchaseSuccess(_rsp, shopType)
end

function NPCShopUIModule:HandlePurchaseFailure(_rsp, shopType)
  local retCode = _rsp.ret_info.ret_code
  local shopId = _rsp.shop_id
  if self:IsFashionShop(shopType) and (shopType == _G.Enum.ShopType.ST_FASHION_PIKA or shopType == _G.Enum.ShopType.ST_FASHION_RANDOM or shopType == _G.Enum.ShopType.ST_FASHION_DISCOUNT) then
    Log.Info("NPCShopUIModule:HandlePurchaseFailure", "Handling fashion shop failure", shopId, shopType)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnFashionBuyFail, _rsp)
  end
  Log.Warning("NPCShopUIModule:HandlePurchaseFailure", "Handling other errors", shopId, retCode)
  self:HandleOtherErrors(retCode, shopType)
end

function NPCShopUIModule:HandlePurchaseSuccess(_rsp, shopType)
  local shopId = _rsp.shop_id
  if self:IsRechargeShop(shopId) then
    Log.Info("NPCShopUIModule:HandlePurchaseSuccess", "Redirecting to recharge shop", shopId)
    _G.NRCModuleManager:DoCmd(ShopModuleCmd.OnCmdMallBuyItemRsp, _rsp)
    return
  end
  Log.Info("NPCShopUIModule:HandlePurchaseSuccess", "Closing purchase panel", shopId)
  NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.NPCSHOPPURCHASE_CLOSE)
  if self:IsFashionShop(shopType) and (shopType == _G.Enum.ShopType.ST_FASHION_PIKA or shopType == _G.Enum.ShopType.ST_FASHION_RANDOM or shopType == _G.Enum.ShopType.ST_FASHION_DISCOUNT or shopType == _G.Enum.ShopType.ST_FASHION_TAILOR) then
    Log.Info("NPCShopUIModule:HandlePurchaseSuccess", "Handling fashion shop success", shopId, shopType)
    self:HandleFashionShopSuccess(_rsp, shopType)
  end
  if shopType == Enum.ShopType.ST_FASHION_CLOSET then
    Log.Info("NPCShopUIModule:HandlePurchaseSuccess", "Handling closet shop success", shopId)
    self:HandleClosetShopSuccess(_rsp)
  end
  if shopType == Enum.ShopType.ST_EXCHANGE then
    Log.Info("NPCShopUIModule:HandlePurchaseSuccess", "Handling exchange shop success", shopId)
    self:HandleExchangeShopSuccess(_rsp)
  end
end

function NPCShopUIModule:HandleFashionShopSuccess(_rsp, shopType)
  local shopId = _rsp.shop_id
  Log.Info("NPCShopUIModule:HandleFashionShopSuccess", "Updating fashion mall", shopId, shopType)
  NRCModuleManager:GetModule("AppearanceModule"):DispatchEvent(AppearanceModuleEvent.UpdateFashionMall, shopId)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnFashionBuySuccess, _rsp)
  Log.Info("NPCShopUIModule:HandleFashionShopSuccess", "Fashion shop success handled", shopId)
end

function NPCShopUIModule:HandleClosetShopSuccess(_rsp)
  local shopId = _rsp.shop_id
  local rewards = _rsp.ret_info.goods_reward.rewards
  Log.Info("NPCShopUIModule:HandleClosetShopSuccess", "Processing closet shop success", shopId)
  if rewards and #rewards > 0 then
    Log.Info("NPCShopUIModule:HandleClosetShopSuccess", "Opening upgrade success panel", shopId, #rewards)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceUpgradeSuccPanel, _rsp)
    NRCModuleManager:GetModule("AppearanceModule"):DispatchEvent(AppearanceModuleEvent.UpdateUpgradeMall, shopId, _rsp)
  else
    Log.Warning("NPCShopUIModule:HandleClosetShopSuccess", "No rewards found", shopId)
  end
end

function NPCShopUIModule:HandleExchangeShopSuccess(_rsp)
  local shopId = _rsp.shop_id
  local rewards = _rsp.ret_info.goods_reward.rewards
  Log.Info("NPCShopUIModule:HandleExchangeShopSuccess", "Processing exchange shop success", shopId)
  if rewards and #rewards > 0 then
    self:OnCmdOpenNPCShopItemRewardsPanel(rewards)
  else
    Log.Warning("NPCShopUIModule:HandleExchangeShopSuccess", "No rewards found", shopId)
  end
end

function NPCShopUIModule:HandleOtherErrors(retCode, shopType)
  Log.Warning("NPCShopUIModule:HandleOtherErrors", "Handling error", retCode, shopType)
  local key = ""
  if shopType == Enum.ShopType.ST_FASHION_CLOSET then
    key = _G.DataConfigManager:GetLocalizationConf("fashionmall_no_enough_pikapoint").msg
    Log.Info("NPCShopUIModule:HandleOtherErrors", "Closet shop error", key)
  else
    key = string.format("Error_Code_%d", retCode)
    key = LuaText[key]
    Log.Info("NPCShopUIModule:HandleOtherErrors", "Generic error", retCode, key)
  end
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, key)
  if self:HasPanel("NPCShopConfirm") then
    Log.Info("NPCShopUIModule:HandleOtherErrors", "Showing confirm panel button")
    local panel = self:GetPanel("NPCShopConfirm")
    panel:ShowBtn(true)
  else
    Log.Info("NPCShopUIModule:HandleOtherErrors", "Confirm panel not found")
  end
end

function NPCShopUIModule:IsExchangeShop(myShopType)
  local bExchangeShop = myShopType == _G.Enum.ShopType.ST_EXCHANGE
  Log.Debug("NPCShopUIModule:IsExchangeShop", "Shop type check", myShopType, bExchangeShop)
  return bExchangeShop
end

function NPCShopUIModule:ProcessExchangeShop(shopId, _rsp, myShopType, nextRefresh)
  if myShopType == _G.Enum.ShopType.ST_EXCHANGE and self:HasPanel("NPCShopPlantSell") and self:IsPanelEnabled("NPCShopPlantSell") then
    NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL, shopId, _rsp, nextRefresh)
  end
end

function NPCShopUIModule:OnCmdBatchGetShopData(batcheReqData)
  if nil == batcheReqData then
    Log.Error("NPCShopUIModule:OnCmdBatchGetShopData batcheReqData is nil")
    return
  end
  local shopIDList = batcheReqData.shopIDList
  if nil == shopIDList then
    Log.Error("NPCShopUIModule:OnCmdBatchGetShopData shopIDList is nil or empty")
    return
  end
  if type(shopIDList) ~= "table" then
    Log.Error("NPCShopUIModule:OnCmdBatchGetShopData shopIDList is not a table, type:", type(shopIDList))
    return
  end
  if 0 == #shopIDList then
    Log.Error("NPCShopUIModule:OnCmdBatchGetShopData shopIDList is empty")
    return
  end
  local shopIdStr = table.concat(shopIDList, ",")
  self.BatchGetShopData = batcheReqData
  local req = _G.ProtoMessage:newZoneShopBatchGetInfoReq()
  req.shop_ids = shopIDList
  Log.Info("NPCShopUIModule:OnCmdReqGetShopData", shopIdStr, "reqTag:", batcheReqData.reqTag)
  local bSuccess = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SHOP_BATCH_GET_INFO_REQ, req, self, self.GetBatchShopDataRsp, batcheReqData.needModal, batcheReqData.ignoreErrorTip)
  if not bSuccess then
    self.BatchGetShopData = nil
    Log.Error("NPCShopUIModule:OnCmdBatchGetShopData", "send request failed", shopIdStr, batcheReqData.reqTag)
  else
    Log.Info("NPCShopUIModule:OnCmdBatchGetShopData", "send request success", shopIdStr, batcheReqData.reqTag)
  end
  return bSuccess
end

function NPCShopUIModule:GetBatchShopDataRsp(rsp)
  Log.Dump(rsp, 6, "NPCShopUIModuleDump---GetBatchShopDataRsp")
  if nil == rsp then
    Log.Error("NPCShopUIModule:GetBatchShopDataRsp rsp is nil")
    return
  end
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local retinfo = rsp.ret_info
    local shopDataList = rsp.shop_datas
    if shopDataList and #shopDataList > 0 then
      for _, shopData in ipairs(shopDataList) do
        local Rsp = _G.ProtoMessage:newZoneShopGetInfoRsp()
        Rsp.ret_info = retinfo
        Rsp.shop_data = shopData
        self.data:SetShopData(Rsp)
      end
    end
  end
  local batcheReqData = self.BatchGetShopData
  if nil == batcheReqData then
    Log.Error("NPCShopUIModule:GetBatchShopDataRsp batcheReqData is nil")
    return
  end
  if batcheReqData and batcheReqData.Caller and batcheReqData.rspHandler then
    batcheReqData.rspHandler(batcheReqData.Caller, rsp)
  end
end

function NPCShopUIModule:TestBatchGetShopData()
  local batcheReqData = {}
  batcheReqData.Caller = self
  batcheReqData.rspHandler = self.TestGetBatchShopDataRsp
  batcheReqData.needModal = true
  batcheReqData.ignoreErrorTip = true
  batcheReqData.reqTag = "TestBatchGetShopData"
  batcheReqData.shopIDList = {103, 104}
  NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdBatchGetShopData, batcheReqData)
end

function NPCShopUIModule:TestGetBatchShopDataRsp(rsp)
  Log.Dump(rsp, 6, "NPCShopUIModuleDump---TestGetBatchShopDataRsp")
end

function NPCShopUIModule:OnCmdGetCachedShopData(shopID)
  local Rsp = self.data:GetShopData(shopID)
  if Rsp then
    return Rsp.shop_data
  end
  return nil
end

return NPCShopUIModule

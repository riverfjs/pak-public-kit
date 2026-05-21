local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local NPCActionOpenShop = require("NewRoco.Modules.Core.NPC.Actions.NPCActionOpenShop")
local ShopModuleSortData = require("NewRoco.Modules.System.Shop.ShopModuleSortData")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local NPCShopUIModuleEnum = require("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEnum")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local StarChainModuleEvent = require("NewRoco.Modules.System.StarChain.StarChainModuleEvent")
_G.NPCShopUIModuleCmd = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleCmd")
local UMG_NPCShop_C = _G.NRCPanelBase:Extend("UMG_NPCShop_C")

function UMG_NPCShop_C:OnConstruct()
  self.uiData = {}
  self.data = self.module:GetData("NPCShopUIModuleData")
  local Action = self.data and self.data.NPCActionOpenShop
  if Action then
    local NPC = Action:GetOwnerNPC()
    if NPC then
      self.animComp = NPC:GetAnimComponent()
    end
  end
  self.DeltaTime = 0
  self.RandomPlayTimeCount = 0
  self.RefreshItemTimer = 1
  self.CanUpdate = true
  self.animDelayTime = 0
  self.randomAnimDelayHandler = nil
  self.randomAnimRestartHandler = nil
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1069, "UMG_NPCShop_C:OnConstruct")
  self.World = _G.UE4Helper.GetCurrentWorld()
  self.curTime = _G.ZoneServer:GetServerTime()
  self.realTime = self:GetRealTime()
  self.hasStopTick = false
  self:OnAddEventListener()
  self:BtnInit()
  _G.NRCEventCenter:RegisterEvent("UMG_NPCShop_C", self, DialogueModuleEvent.DialogueEnded, self.OnCloseVisit)
  self:BindInputAction()
  self.UMG_Btn4:SetClickAble(false)
  self.UMG_Btn3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetCommonTitle()
end

function UMG_NPCShop_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_NPCShop_C:OnDestruct()
  self.uiData = nil
  self.randomAnimDelayHandler = nil
  self.randomAnimRestartHandler = nil
  if 0 == GlobalConfig.OpenMainPanelFromDebugBtn and self.data.NPCActionOpenShop and self.data.NPCActionOpenShop.Owner.owner.viewObj then
    self.data.NPCActionOpenShop.Owner.owner:SetVisible(true)
  end
  self:RestoreHudStatus()
  if 0 == GlobalConfig.OpenMainPanelFromDebugBtn and self.data.NPCActionOpenShop then
    self.data.NPCActionOpenShop.Owner.owner:LockVisibility(false)
    if nil ~= self.data.NPCActionOpenShop then
      self.data.NPCActionOpenShop:Finish()
      self.data.NPCActionOpenShop = nil
    end
  end
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOPPURCHASE_CLOSE)
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.RefreshHasCountAfterClaimReward)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnCloseVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnPreNtfEnterScene)
  self:StartCaptureTick(false)
  UE4Helper.SetEnableWorldRendering(nil, false, "UMG_NPCShop_C_Capture")
end

function UMG_NPCShop_C:_OnPreNtfEnterScene()
  self:ReleaseCaptureResource()
  self:ShopClose()
end

function UMG_NPCShop_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_NpcShop")
  if mappingContext then
    mappingContext:BindAction("IA_CloseNpcShopUI", self, "OnPcClose")
  end
end

function UMG_NPCShop_C:OnPcClose()
  self:OnCloseButtonClicked()
end

function UMG_NPCShop_C:RestoreHudStatus()
  local npcActionOpenShop = self.data.NPCActionOpenShop
  local owner = npcActionOpenShop and npcActionOpenShop.Owner and npcActionOpenShop.Owner.owner
  local viewObj = owner and owner.viewObj
  if UE4.UObject.IsValid(viewObj) then
    local nameComponent = viewObj:GetComponentByClass(UE4.URocoWidgetComponent)
    if nameComponent then
      nameComponent:SetComponentTickEnabled(true)
      nameComponent:SetRenderStatus(true, MainUIModuleEnum.DisableHudOpSource.EnterNpcShop)
    end
  end
end

function UMG_NPCShop_C:SetItemList(List)
  if List and #List > 0 then
    local ItemNum = {}
    if GlobalConfig.bShowProfilerLog then
      for i = 1, 6 do
        table.insert(ItemNum, List[i])
      end
      List = ItemNum
    end
    for i = 1, #List do
      List[i].callbackCaller = self
      List[i].callbackFunc = self.OnListItemSelected
      List[i].callbackFuncClcikBtn = self.OnClickBtnSetListItemSelected
    end
    self.ItemList:ClearSelection()
    self.ItemList:InitList(List)
    if self.curSelectedIndex and self.curSelectedIndex - 1 >= 0 then
      self.ItemList:SelectItemByIndex(self.curSelectedIndex - 1)
    else
      self.curSelectedIndex = 1
      self.ItemList:SelectItemByIndex(0)
    end
    self.data:InitItemData(List)
  else
  end
end

local function SortShopItem(a, b)
  if a.AlreadyHasItem then
    return false
  elseif b.AlreadyHasItem then
    return true
  end
  if a.can_buy == b.can_buy then
    return a.Pos < b.Pos
  elseif a.can_buy then
    return true
  elseif b.can_buy then
    return false
  end
end

function UMG_NPCShop_C:GetUnsoldGoodsNameList(goodsConf, shopId, currentGoodsId)
  local goodsNameList = {}
  local param1 = tonumber(goodsConf.buy_cond_param) or 0
  if 1 == param1 then
    local requiredGoodsIds = goodsConf.buy_cond_param1 or {}
    if type(requiredGoodsIds) == "table" then
      for _, goodsId in ipairs(requiredGoodsIds) do
        local goodsSeverData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, goodsId)
        if goodsSeverData then
          local isSoldOut = goodsSeverData.limit_buy_num and goodsSeverData.limit_buy_num > 0 and goodsSeverData.buy_num and goodsSeverData.buy_num >= goodsSeverData.limit_buy_num
          if not isSoldOut then
            local requiredGoodsConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
            if requiredGoodsConf and requiredGoodsConf.goods_name then
              table.insert(goodsNameList, requiredGoodsConf.goods_name)
            end
          end
        end
      end
    end
  else
    local shopData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetCachedShopData, shopId)
    if shopData and shopData.goods_data then
      for _, otherGoodsData in ipairs(shopData.goods_data) do
        if otherGoodsData.goods_id ~= currentGoodsId then
          local isSoldOut = otherGoodsData.limit_buy_num and otherGoodsData.limit_buy_num > 0 and otherGoodsData.buy_num and otherGoodsData.buy_num >= otherGoodsData.limit_buy_num
          if not isSoldOut then
            local otherGoodsConf = _G.DataConfigManager:GetNormalShopConf(otherGoodsData.goods_id)
            if otherGoodsConf and otherGoodsConf.goods_name then
              table.insert(goodsNameList, otherGoodsConf.goods_name)
            end
          end
        end
      end
    end
  end
  return goodsNameList
end

function UMG_NPCShop_C:OnActive(param0, param, param1, param2, bIsRefreshNPCShop, ...)
  self.NPCAction = param.NPCAction
  self.CanUpdate = true
  local IsRefreshNPCShop = bIsRefreshNPCShop
  local shopId = tonumber(param0)
  self.data:SetNPCContentID(self.NPCAction, shopId)
  local showType = _G.DataConfigManager:GetShopConf(shopId)
  local moneyType = {}
  if showType and showType.goods and #showType.goods > 0 then
    for k, v in pairs(showType.goods) do
      if v.goods_id ~= nil then
        table.insert(moneyType, v.goods_id)
      end
    end
  end
  local _param = {}
  if showType then
    local playerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
    if param1 and param1.shop_data and param1.shop_data.goods_data then
      if showType.shop_type ~= _G.Enum.ShopType.ST_RANDOM_SHOP then
        for k, v in ipairs(param1.shop_data.goods_data) do
          local goodsShopConf = _G.DataConfigManager:GetNormalShopConf(v.goods_id)
          if goodsShopConf then
            if goodsShopConf.shop_id == 2005 then
              self.UMG_Btn2:SetBtnText(LuaText.umg_exchange_text)
            end
            local shoppos = 0
            if 0 == goodsShopConf.shop_pos then
              shoppos = #param1.shop_data.goods_data + k
            else
              shoppos = goodsShopConf.shop_pos
            end
            local refreshResetType
            if goodsShopConf.reset_type and goodsShopConf.reset_type ~= Enum.ShopResetType.SRTG_NULL then
              refreshResetType = goodsShopConf.reset_type
            end
            local can_buy = true
            local limitBuyType = -1
            local SoldOut_goodsNameList, limitBuyParam, buy_cond_param
            if goodsShopConf.buy_cond_type == Enum.BuyLimited.BL_SOLDOUT then
              SoldOut_goodsNameList = self:GetUnsoldGoodsNameList(goodsShopConf, shopId, v.goods_id)
              buy_cond_param = goodsShopConf.buy_cond_param
            end
            local goodsConf = NPCShopUtils:GetAdjustGoodConf(v.goods_id, shopId)
            local AlreadyHasItem = false
            can_buy, limitBuyType, limitBuyParam = ShopModuleSortData:CheckBuyCondition(v, goodsShopConf, playerLevel, param1.shop_data.goods_data)
            if can_buy and 2 ~= limitBuyType then
              AlreadyHasItem = self:CheckHasItem(goodsConf.Type, goodsConf.item_id)
              if AlreadyHasItem then
                can_buy = false
              end
            end
            table.insert(_param, {
              shopItemId = v.goods_id,
              shopLibId = v.goods_id,
              priceNum = v.real_price.num,
              itemId = goodsShopConf.item_id,
              limitType = goodsShopConf.buy_cond_type,
              limitNum = 0 ~= v.limit_buy_num and v.limit_buy_num or goodsShopConf.buy_limit_num,
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
              Pos = shoppos,
              next_refresh_time = v.next_refresh_time,
              goods_unlock_type = goodsShopConf.unlock_type,
              bIsUnlock = v.is_unlock,
              RefreshResetType = refreshResetType,
              can_buy = can_buy,
              limitBuyType = limitBuyType,
              SoldOut_goodsNameList = SoldOut_goodsNameList,
              limitBuyParam = limitBuyParam,
              buy_cond_param = buy_cond_param,
              AlreadyHasItem = AlreadyHasItem
            })
          end
        end
        table.sort(_param, SortShopItem)
      else
        for k, v in ipairs(param1.shop_data.goods_data) do
          local goodsShopConf = _G.DataConfigManager:GetRandomGoodsConf(v.goods_id)
          if goodsShopConf then
            table.insert(_param, {
              shopItemId = v.goods_id,
              shopLibId = v.goods_id,
              priceNum = v.real_price.num,
              itemId = goodsShopConf.item_id,
              limitType = 0,
              limitNum = v.limit_buy_num or 0,
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
              Pos = 0,
              next_refresh_time = v.next_refresh_time,
              goods_unlock_type = 0,
              bIsUnlock = v.is_unlock,
              RefreshResetType = nil,
              disable_time = v.disable_time,
              can_buy = true,
              limitBuyType = -1
            })
          end
        end
      end
    else
      Log.Debug("UMG_NPCShop_C", "param1.shop_data.goods_data is nil")
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:DelaySeconds(0.1, function()
        Log.Debug("UMG_NPCShop_C", "param1.shop_data.goods_data is nil,tryClose")
        self:ReleaseCaptureResource()
        self:ShopClose()
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.shop_tips)
      end)
      return
    end
  end
  if not IsRefreshNPCShop then
    self:PlayAnimation(self.open)
  end
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerCameraManager = player:GetUEController().PlayerCameraManager
  local camera1 = _G.NRCModuleManager:DoCmd(DialogueModuleCmd.GetUICamera)
  local cameraTransform = playerCameraManager:Abs_GetTransform()
  if camera1 and UE4.UObject.IsValid(camera1) then
    cameraTransform = camera1:Abs_GetTransform()
  end
  if 0 == GlobalConfig.OpenMainPanelFromDebugBtn and self.data.NPCActionOpenShop then
    local npcActionOpenShop = self.data.NPCActionOpenShop
    local owner = npcActionOpenShop and npcActionOpenShop.Owner and npcActionOpenShop.Owner.owner
    owner:LockVisibility(true)
    local viewObj = owner and owner.viewObj
    if UE4.UObject.IsValid(viewObj) and viewObj.Mesh then
      UE4.UNRCStatics.ForceUpdateStreamingAssets(viewObj.Mesh.SkeletalMesh, 3)
      viewObj.Mesh:SetForcedLOD(1)
    end
  end
  _param = self:SortSoldGoods(_param)
  _param = self:SetMysteriousStoreShopList(param0, _param, param1.shop_data)
  self.uiData.itemList1 = _param
  self.uiData.shopId = tonumber(param0)
  self.uiData.CoinCost = self.data.sumCoinCost
  self.uiData.DiamondCost = self.data.sumDiamondCost
  if param1.shop_data and param1.shop_data.consume_info then
    self.uiData.consume_info = param1.shop_data.consume_info
  end
  self:SetConsumeInfo()
  self:CheckIsReward()
  self:updatePanelInfo()
  local OpenNpcShopType = self.data:GetOpenNpcShopType()
  local NPCShoTypeEnum = NPCShopUIModuleEnum.OpenNPCShopFormType
  UE4.ACharacterStatusComputeActor.SetTickEnabled(false)
  local bCaptureNPC = self.data.NPCActionOpenShop and self.animComp
  if not bCaptureNPC and not IsRefreshNPCShop then
    self.previewImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if OpenNpcShopType ~= NPCShoTypeEnum.MagicManualMain and not IsRefreshNPCShop then
    self:CaptureBackgroundAndNPC(bCaptureNPC)
  end
  _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.ForceSetLensFlaresActorVisibility, false)
  local dTime = self:GetRealTime() - self.realTime
  local svrTime = self.curTime + dTime
  local deltaTime = 0 - svrTime
  self.uiData.deltaTime = deltaTime
  local ShopConf = _G.DataConfigManager:GetShopConf(self.uiData.shopId)
  if _param then
    local len = #_param
    if len >= 1 then
      if self.curSelectedIndex and self.curSelectedIndex > 0 and len >= self.curSelectedIndex then
        self:OnItemClick(self.curSelectedIndex)
      else
        Log.Info("UMG_NPCShop_C:OnActive: self.curSelectedIndex is invalid, set to 1", self.curSelectedIndex, len)
        self.curSelectedIndex = 1
        self:OnItemClick(1)
      end
    end
  else
    Log.Warning("UMG_NPCShop_C:OnActive: _param is empty")
  end
  self.Title1:SetSubtitle(ShopConf.shop_name)
  if ShopConf.shop_icon then
    self.Title1:SetBg(ShopConf.shop_icon)
  end
  self:UpdateItemTimeCountDownTimer()
  if not IsRefreshNPCShop then
    self:PlayAnimTimer()
  end
  if ShopConf and ShopConf.shop_type == _G.Enum.ShopType.ST_RANDOM_SHOP then
    self.DetailsBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.DetailsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NPCShop_C:CheckHasItem(ItemType, ItemId)
  if ItemType == Enum.GoodsType.GT_FASHION_SUITS then
    local hasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, ItemId)
    return hasSuit
  end
  return false
end

function UMG_NPCShop_C:CaptureBackgroundAndNPC(bCaptureNPC)
  UE4Helper.SetEnableWorldRendering(true, false, "UMG_NPCShop_C_Capture")
  if bCaptureNPC then
    self:StartCaptureTick(true)
    self.previewImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CaptureBackground:SetVisibility(UE4.ESlateVisibility.Collapsed)
    
    local function waitUntilNpcCaptureFinished(InSelf)
      self.previewImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:StartCaptureTick(false)
      
      local function splitHideAndStopCapture()
        if 0 == GlobalConfig.OpenMainPanelFromDebugBtn and self.data.NPCActionOpenShop then
          local npc = self.data.NPCActionOpenShop.Owner.owner
          if npc then
            npc:SetVisible(false)
          end
        end
        self.UMG_CaptureBackground:StartCapture()
        
        local function waitUntilBGCaptureFinished()
          UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_NPCShop_C_Capture")
          local FillBackgroundMat = "Material'/Game/ArtRes/Material/UI/MI_UI_FIllBackground.MI_UI_FIllBackground'"
          self:LoadPanelRes(FillBackgroundMat, 255, function(caller, resRequest, asset)
            local UICameraClass = _G.NRCBigWorldPreloader:Get("DialogueUICamera")
            local CameraActor = UE4.UGameplayStatics.GetActorOfClass(UE4Helper.GetCurrentWorld(), UICameraClass)
            local CameraCom = CameraActor and CameraActor:GetComponentByClass(UE4.UCameraComponent)
            if CameraCom then
              CameraCom:AddOrUpdateBlendable(asset, 1.0)
            end
            self:SetDialogueUICameraCullingMask(128, true)
            self:SetActorCullingMask(128, true)
            
            local function HideOldNPCCapture()
              if 0 == GlobalConfig.OpenMainPanelFromDebugBtn and self.data.NPCActionOpenShop then
                local npc = self.data.NPCActionOpenShop.Owner.owner
                if npc then
                  npc:SetVisible(true)
                end
              end
              self.previewImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
            end
            
            self:DelayFrames(2, HideOldNPCCapture, self)
          end, nil, nil)
        end
        
        self:DelayFrames(3, waitUntilBGCaptureFinished, self)
      end
      
      self:DelayFrames(1, splitHideAndStopCapture, self)
    end
    
    self:DelayFrames(3, waitUntilNpcCaptureFinished, self)
  else
    self.previewImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CaptureBackground:StartCapture()
    
    local function OnCaptureBackgroundDone()
      self.UMG_CaptureBackground:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_NPCShop_C_Capture")
    end
    
    self:DelayFrames(3, OnCaptureBackgroundDone, self)
  end
end

function UMG_NPCShop_C:CheckIsReward()
  if self.uiData.consume_info and self.uiData.consume_info.reward_taken_info then
    local rewardTakenList = self.uiData.consume_info.reward_taken_info
    local isRewardCanTake = false
    for i = 1, #rewardTakenList do
      if rewardTakenList[i].is_reward_taken == false then
        isRewardCanTake = true
        break
      end
    end
    if isRewardCanTake then
      self.RedDot:SetupKey(245, {
        self.uiData.shopId
      })
      self:PlayAnimation(self.Reward_in)
    else
      if self.RedDot:IsRed() then
        self.RedDot:EraseRedPoint(245, {
          self.uiData.shopId
        })
      end
      if self:IsAnimationPlaying(self.Reward_loop) then
        self:StopAnimation(self.Reward_loop)
        self:PlayAnimation(self.Reward_out)
      else
        self:PlayAnimation(self.Reward_normal)
      end
    end
  end
end

function UMG_NPCShop_C:RefreshInfos(_rsp)
  if 0 == _rsp.ret_info.ret_code and _rsp.shop_data.consume_info then
    self.uiData.consume_info = _rsp.shop_data.consume_info
    self:CheckIsReward()
    self:RefreshSelectItemInfo()
  end
end

function UMG_NPCShop_C:SetConsumeInfo()
  local shopConf = _G.DataConfigManager:GetShopConf(self.uiData.shopId)
  local iconPath = ""
  if self.uiData.consume_info then
    local totalConsumptionConf = _G.DataConfigManager:GetShopTotalConsumptionConf(self.uiData.shopId)
    self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.MoneyCost:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ConsumeText1:SetText(_G.DataConfigManager:GetLocalizationConf("total_consumption_tips").msg)
    local lastLevelConsumeData = {}
    local nextLevelConsumeData = {}
    local totalConsumeNum = self.uiData.consume_info.total_consume_num
    if totalConsumptionConf then
      iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(totalConsumptionConf.price_goods_type, totalConsumptionConf.price_goods_id)
      for i = 1, #totalConsumptionConf.shop_consumption_reward do
        if totalConsumeNum < totalConsumptionConf.shop_consumption_reward[i].total_consumption_num then
          if i - 1 >= 1 then
            lastLevelConsumeData = totalConsumptionConf.shop_consumption_reward[i - 1]
          else
            lastLevelConsumeData = nil
          end
          nextLevelConsumeData = totalConsumptionConf.shop_consumption_reward[i]
          break
        end
      end
    end
    self.CostIcon:SetPath(iconPath)
    if not nextLevelConsumeData.total_consumption_num then
      self.CostNum:SetText(0)
      self.ProgressBar_84:SetPercent(1)
    else
      local needCostNum = nextLevelConsumeData.total_consumption_num - totalConsumeNum
      local levelNeedCostNum
      if lastLevelConsumeData and lastLevelConsumeData.total_consumption_num then
        levelNeedCostNum = nextLevelConsumeData.total_consumption_num - lastLevelConsumeData.total_consumption_num
      else
        levelNeedCostNum = nextLevelConsumeData.total_consumption_num
      end
      local leftCostNum = levelNeedCostNum - needCostNum
      self.CostNum:SetText(needCostNum)
      self.ProgressBar_84:SetPercent(leftCostNum / levelNeedCostNum)
    end
  elseif shopConf.is_cumulative then
    local totalConsumptionConf = _G.DataConfigManager:GetShopTotalConsumptionConf(self.uiData.shopId)
    self.ConsumeText1:SetText(_G.DataConfigManager:GetLocalizationConf("total_consumption_tips").msg)
    if totalConsumptionConf then
      iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(totalConsumptionConf.price_goods_type, totalConsumptionConf.price_goods_id)
      self.CostNum:SetText(totalConsumptionConf.shop_consumption_reward[1].total_consumption_num)
    end
    self.CostIcon:SetPath(iconPath)
    self.ProgressBar_84:SetPercent(0)
  else
    self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NPCShop_C:Tick(MyGeometry, InDeltaTime)
end

function UMG_NPCShop_C:GetRealTime()
  local realTime = UE4.UGameplayStatics.GetAccurateRealTime(self.World)
  return realTime
end

function UMG_NPCShop_C:RefreshNPCShopMainPanel(_param, param, param1, ...)
  self.data = self.module:GetData("NPCShopUIModuleData")
  self.uiData = {}
  self.data.itemData = {}
  self.data.costInfo = {
    0,
    0,
    0
  }
  self.data.sumCoinCost = 0
  self.data.sumDiamondCost = 0
  local bIsRefreshNPCShop = true
  self:OnActive(_param, param, param, param1, bIsRefreshNPCShop, ...)
end

function UMG_NPCShop_C:OnDeactive()
  if self.NPCShopUITimer ~= nil then
    self.NPCShopUITimer:Clear()
    _G.TimerManager:RemoveTimer(self.NPCShopUITimer)
  end
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  self:CancelDelay()
  self:ReleaseCaptureResource()
  _G.NRCModuleManager:DoCmd(EnvSystemModuleCmd.ForceSetLensFlaresActorVisibility, true)
  UE4.ACharacterStatusComputeActor.SetTickEnabled(true)
end

function UMG_NPCShop_C:updatePanelInfo()
  self:updateListInfo(self.uiData.itemList1)
  self:ShowMoney()
end

function UMG_NPCShop_C:updateTimeCountDown()
  self.uiData.deltaTime = self.uiData.deltaTime - 1
  if self.uiData.deltaTime > 0 then
    local days = math.floor(self.uiData.deltaTime / 60 / 60 / 24)
    local hours = math.floor((self.uiData.deltaTime - days * 24 * 3600) / 3600)
    local minutes = math.floor((self.uiData.deltaTime - days * 24 * 3600 - hours * 3600) / 60)
    local seconds = self.uiData.deltaTime - days * 24 * 3600 - hours * 3600 - minutes * 60
  else
  end
end

function UMG_NPCShop_C:timeOutGetStoreListReq()
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, self.uiData.shopId)
end

function UMG_NPCShop_C:refreshShopList()
  if self.uiData then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, self.uiData.shopId)
  end
end

function UMG_NPCShop_C:ShowMoney()
  local showType = _G.DataConfigManager:GetShopConf(self.uiData.shopId)
  local showTypeNum = #showType.goods
  local ShowSumMoneyInfo = {}
  local ShowCostMoneyInfo = {}
  local sumMoneyNum
  local costMoneyNum = self.data.costInfo[i]
  for i = 1, showTypeNum do
    sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNumByType(showType.goods[i].goods_type, showType.goods[i].goods_id) or 0
    local IsShowBuyIcon = false
    if showType.goods[i].goods_type == _G.Enum.GoodsType.GT_VITEM then
      local visualItemConf = _G.DataConfigManager:GetVisualItemConf(showType.goods[i].goods_id)
      if visualItemConf and visualItemConf.exchange_id and 0 ~= visualItemConf.exchange_id then
        IsShowBuyIcon = true
      end
      if showType.goods[i].goods_id == _G.Enum.VisualItem.VI_DIAMOND then
        IsShowBuyIcon = true
      end
      table.insert(ShowSumMoneyInfo, {
        currencyType = showType.goods[i].goods_type,
        currencyId = showType.goods[i].goods_id,
        moneyType = showType.goods[i].goods_id,
        sum = sumMoneyNum,
        showColor = 0,
        showbg = true,
        bigIcon = true,
        IsShowBuyIcon = IsShowBuyIcon
      })
    elseif showType.goods[i].goods_type == _G.Enum.GoodsType.GT_BAGITEM then
      table.insert(ShowSumMoneyInfo, {
        currencyType = showType.goods[i].goods_type,
        currencyId = showType.goods[i].goods_id,
        sum = sumMoneyNum,
        showColor = 0,
        showbg = true,
        bigIcon = true,
        IsShowBuyIcon = IsShowBuyIcon
      })
    end
  end
  self.MoneyBtn:InitGridView(ShowSumMoneyInfo)
  self:ShowSelectAllNum()
end

function UMG_NPCShop_C:updateListInfo(_items)
  self:Log("updateListInfo:", _items)
  local itemListCount = _items and #_items or 0
  self:SetItemList(_items)
end

function UMG_NPCShop_C:RandomPlayShowAnim(deltaTime)
  local randomNum = 2
  if self.animComp and UE.UObject.IsValid(self.animComp) then
    if self.animComp:IsAnimPlaying("IdleRelax2") then
      self.animComp:StopAnimByName("IdleRelax2")
    end
    if self.animComp:IsAnimPlaying("Show2") then
      self.animComp:StopAnimByName("Show2")
    end
    if self.animComp:IsAnimPlaying("Happy1") then
      self.animComp:StopAnimByName("Happy1")
    end
    if 1 == randomNum then
      self.animComp:PlayAnimByName("IdleRelax2")
      self.animDelayTime = self.animComp:GetAnimLengthByName("IdleRelax2")
    elseif 2 == randomNum then
      self.animComp:PlayAnimByName("Show2")
      self.animDelayTime = self.animComp:GetAnimLengthByName("Show2")
    end
  end
end

function UMG_NPCShop_C:PlayHappyAnimAfterBuying()
  if UE4.UObject.IsValid(self.animComp) and self.animComp then
    if self.animComp:IsAnimPlaying("IdleRelax2") then
      self.animComp:StopAnimByName("IdleRelax2")
    end
    if self.animComp:IsAnimPlaying("Show2") then
      self.animComp:StopAnimByName("Show2")
    end
    if not self.animComp:IsAnimPlaying("Happy1") then
      self.animComp:PlayAnimByName("Happy1")
      if self.randomAnimDelayHandler then
        self:CancelDelayByID(self.randomAnimDelayHandler)
        self.randomAnimDelayHandler = nil
      end
      if self.randomAnimRestartHandler then
        self:CancelDelayByID(self.randomAnimRestartHandler)
        self.randomAnimRestartHandler = nil
      end
      self.animDelayTime = 0
      local delayTime = self.animComp:GetAnimLengthByName("Happy1")
      self.randomAnimRestartHandler = self:DelaySeconds(delayTime + 0.1, function()
        self.randomAnimRestartHandler = nil
        self:PlayAnimTimer()
      end)
    end
  end
end

function UMG_NPCShop_C:OnListItemSelected(item, index)
  self.curSelectedIndex = index
  self:getCurSelectItem()
end

function UMG_NPCShop_C:OnClickBtnSetListItemSelected(index)
  if self.curSelectedIndex ~= index then
    self.ItemList:SelectItemByIndex(index - 1)
  end
end

function UMG_NPCShop_C:GetCurGoodsConf()
  local index = self.curSelectedIndex
  local uiData = self.uiData
  if index and uiData and uiData.itemList1 then
    local item = uiData.itemList1[index]
    local itemId = item and item.shopItemId
    if itemId and uiData.shopId then
      return NPCShopUtils:GetAdjustGoodConf(itemId, uiData.shopId)
    end
  end
end

function UMG_NPCShop_C:getCurSelectItem()
  self:OnItemClick(self.curSelectedIndex)
end

function UMG_NPCShop_C:OnItemClick(index)
  local _itemId = self.uiData.itemList1[index].shopItemId
  self.uiData.itemList1[index].selectedState = true
  local goodsConf = NPCShopUtils:GetAdjustGoodConf(_itemId, self.uiData.shopId)
  if nil == goodsConf then
    return
  end
  if self.lastClickItemId == _itemId then
    return
  end
  self.lastClickItemId = _itemId
  self.IconSwitcher:SetActiveWidgetIndex(0)
  if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
    if bagItemConf then
      if nil ~= bagItemConf.type_desc then
        self.ItemProperty:SetText(bagItemConf.type_desc)
      end
      if bagItemConf.big_icon then
        self:SetIcon(bagItemConf.big_icon, bagItemConf)
      end
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      local gainWayList = self:GetGaiWay(bagItemConf)
      self.ItemGainWay:InitGridView(gainWayList)
      self.ItemDesc:SetText(bagItemConf.description)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsConf.item_id)
    if vItemConf then
      if nil ~= vItemConf.type_desc then
        self.ItemProperty:SetText(vItemConf.type_desc)
      end
      if vItemConf.bigIcon then
        self.HeadIcon:SetPath(vItemConf.bigIcon)
      end
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      local gainWayList = self:GetGaiWay(vItemConf)
      self.ItemGainWay:InitGridView(gainWayList)
      self.ItemDesc:SetText(vItemConf.discription)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(goodsConf.item_id)
    if cardSkinConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      local path = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
      self.HeadIcon:SetPath(path)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_CARD_ICON then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(goodsConf.item_id)
    if cardIconConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      local path = string.format("%s%s.%s", UEPath.CARD_HEAD_PATH, cardIconConf.icon_resource_path, cardIconConf.icon_resource_path)
      self.HeadIcon:SetPath(path)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_CARD_LABEL then
    local cardLabelConf = _G.DataConfigManager:GetCardLabelConf(goodsConf.item_id)
    if cardLabelConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(cardLabelConf.label_icon or UEPath.CARD_LABEL_PATH)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(goodsConf.item_id)
    if fashionConf then
      self.ItemProperty:SetText(fashionConf.grade_name or "")
      self.ItemDesc:SetText(fashionConf.flavor_text or "")
      self.HeadIcon:SetPath(fashionConf.suits_icon)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(goodsConf.item_id)
    if fashionConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(fashionConf.icon)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(goodsConf.item_id)
    if salonConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(salonConf.icon)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_SHARE_FORM then
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(goodsConf.item_id)
    if shareConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(shareConf.item_icon)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(goodsConf.item_id)
    if itemConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(itemConf.icon_path)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_EMOJI then
    local chatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(goodsConf.item_id)
    if chatEmojiConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(chatEmojiConf.emoji_goods_icon)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_PACKAGE then
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(goodsConf.item_id)
    if fashionPackageConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_FASHION_BOND then
    local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(goodsConf.item_id)
    if fashionBondConf then
      self.ItemProperty:SetText("")
      self.ItemDesc:SetText("")
      self.HeadIcon:SetPath(fashionBondConf.fashion_bond_icon)
      if self._itemId ~= _itemId then
        self.UMG_Common_BIconPar:CloseOpen()
        self._itemId = _itemId
      end
      self.ItemGainWay:InitGridView({})
    end
  else
    self.ItemGainWay:InitGridView({})
    self.ItemProperty:SetText("")
    self.ItemDesc:SetText("")
  end
  self.ItemName:SetText(goodsConf.goods_name)
  if not self:IsAnimationPlaying(self.open) then
    self:PlayAnimation(self.change_icon)
  end
  if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
    if bagItemConf.type == Enum.BagItemType.BI_MUSIC then
      self.NRCImage_193:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.hasCount:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif 0 == bagItemConf.can_see or bagItemConf.tips_not_show_inventory then
      self.NRCImage_193:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.hasCount:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.NRCImage_193:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.hasCount:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    local itemData = NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, goodsConf.item_id)
    if nil ~= itemData then
      self.hasCount:SetText(itemData.num)
    elseif bagItemConf.is_auto_use then
      local num = self:GetAutoUseItemNum(bagItemConf.item_behavior)
      self.hasCount:SetText(num)
    else
      self.hasCount:SetText(0)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
    local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(goodsConf.item_id)
    if nil ~= num then
      self.hasCount:SetText(num)
    else
      self.hasCount:SetText(0)
    end
  else
    self.NRCImage_193:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.hasCount:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NPCShop_C:GetAutoUseItemNum(_item_behavior)
  local item_behavior = _item_behavior and _item_behavior[1] or nil
  if item_behavior and item_behavior.use_action == _G.Enum.ItemBehavior.IB_GET_AWARD and item_behavior.ratio and item_behavior.ratio[1] then
    local rewardConf = _G.DataConfigManager:GetRewardConf(item_behavior.ratio[1])
    if rewardConf and rewardConf.RewardItem then
      local _unlockRolePlays = _G.DataModelMgr.PlayerDataModel:GetRolePlayList()
      for i, v in pairs(rewardConf.RewardItem) do
        if v.Type == Enum.GoodsType.GT_RP_BEHAVIOR then
          local roleConf = _G.DataConfigManager:GetRoleplayBehaviorConf(v.Id, true)
          if roleConf then
            for j, k in pairs(_unlockRolePlays) do
              if roleConf.RPbehavior_type == k then
                return 1
              end
            end
          end
        end
      end
    end
  end
  return 0
end

function UMG_NPCShop_C:RefreshSelectItemInfo()
  self:getCurSelectItem()
end

function UMG_NPCShop_C:updateMoneyCost(_itemID, _selectedNum)
  self.data:ChangeItemNum(_itemID, _selectedNum, self.uiData.shopId)
end

function UMG_NPCShop_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.UMG_Btn2.btnLevelUp, self.OnBuyBtnClick)
  self:AddButtonListener(self.RewardBtn, self.OnRewardBtnClick)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnDetailsBtnClick)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_UI_REFRESH_MONEY_COST, self.updateMoneyCost)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL, self.RefreshNPCShopMainPanel)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_GET_NPCACTION_OPENSHOP_INFO, self.OnNPCActionOpenShop)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_REFRESH_SUM_COST, self.OnRefreshSumCost)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_CLOSE, self.CloseNPCShop)
  self:RegisterEvent(self, NPCShopUIModuleEvent.SoldOutBtnState, self.SwitchBtnSoldOutState)
  self:RegisterEvent(self, StarChainModuleEvent.PurchaseSucceed, self.ShowMoney)
  self:RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOPPURCHASE_CLOSE, self.OnBuySuccess)
  self:RegisterEvent(self, NPCShopUIModuleEvent.RefreshHasCountAfterClaimReward, self.OnClaimSuccess)
  _G.NRCEventCenter:RegisterEvent("UMG_NPCShop_PlantAcquisition_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self._OnPreNtfEnterScene)
end

function UMG_NPCShop_C:OnDetailsBtnClick()
  Log.Debug("UMG_NPCShop_C:OnDetailsBtnClick")
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_NPCShop_C:OnDetailsBtnClick")
  local Content = LuaText.random_shop_rule_text
  local title = LuaText.activity_tip_headline
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_NPCShop_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_UI_REFRESH_MONEY_COST)
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_REFRESH_MAIN_PANEL)
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_GET_NPCACTION_OPENSHOP_INFO)
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_REFRESH_SUM_COST)
  self:UnRegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_CLOSE, self.CloseNPCShop)
  self:UnRegisterEvent(self, StarChainModuleEvent.PurchaseSucceed, self.ShowMoney)
end

function UMG_NPCShop_C:UpdateItemTimeCountDownTimer()
  self:DelaySeconds(1, function()
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    local CurServerTime = _G.ZoneServer:GetServerTime()
    if type(CurServerTime) == "number" then
      local svr_time = math.floor(CurServerTime / 1000)
      self:updateItemTimeCountDown(svr_time)
    end
    self:UpdateItemTimeCountDownTimer()
  end)
end

function UMG_NPCShop_C:PlayAnimTimer()
  local delayAddTime = 0
  if self.animDelayTime then
    delayAddTime = self.animDelayTime
  end
  self.randomAnimDelayHandler = self:DelaySeconds(7 + delayAddTime, function()
    self.randomAnimDelayHandler = nil
    self:RandomPlayShowAnim()
    self:PlayAnimTimer()
  end)
end

function UMG_NPCShop_C:IsAnimPlaying()
  if self.animComp then
    return self.animComp:IsAnimPlaying("IdleRelax2") or self.animComp:IsAnimPlaying("Show2")
  end
end

function UMG_NPCShop_C:updateItemTimeCountDown(svr_time)
  if 0 == GlobalConfig.OpenMainPanelFromDebugBtn and self.ItemList then
    local ItemCount = self.ItemList:GetItemCount()
    if ItemCount > 0 then
      for i = 1, ItemCount do
        local item = self.ItemList:GetItemByIndex(i - 1)
        item:updateTimeCountDown(svr_time)
      end
    end
  end
end

function UMG_NPCShop_C:SetItemRefreshTimeOut()
  if self.CanUpdate then
    self.CanUpdate = false
    if self.ItemTickTimer then
      self:CancelDelayByID(self.ItemTickTimer)
      self.ItemTickTimer = nil
    end
    self.ItemTickTimer = self:DelaySeconds(1, function()
      self:refreshShopList()
      self.CanUpdate = true
    end)
  end
end

function UMG_NPCShop_C:OnRefreshSumCost(cost)
  self:RefreshSumCost(cost)
  self:ShowMoney()
end

function UMG_NPCShop_C:OnNPCActionOpenShop(NPCActionInfo)
  self.uiData.npcaction = NPCActionInfo
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.GetStoreListReq, NPCActionInfo.Config.action_param1)
end

function UMG_NPCShop_C:OnCloseButtonClicked()
  self:Log("UMG_NPCShop_C OnCloseButtonClicked")
  if self:IsAnimationPlaying(self.close_an) then
    return
  end
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.close_an)
  self:ReleaseCaptureResource()
end

function UMG_NPCShop_C:OnCloseVisit()
  self:Log("UMG_NPCShop_C OnCloseButtonClicked")
  self:ShopCloseVisit()
end

function UMG_NPCShop_C:SetDialogueUICameraCullingMask(Mask, bCache)
  local UICameraClass = _G.NRCBigWorldPreloader:Get("DialogueUICamera")
  local CameraActor = UE4.UGameplayStatics.GetActorOfClass(UE4Helper.GetCurrentWorld(), UICameraClass)
  local CameraCom = CameraActor and CameraActor:GetComponentByClass(UE4.UCameraComponent)
  if CameraCom then
    if bCache then
      self.CachedCameraCullingMask = CameraCom.CullingMask
    end
    CameraCom.CullingMask = Mask or -1
  end
end

function UMG_NPCShop_C:SetActorCullingMask(Mask, bCache)
  local ActionOpenShop = self.data and self.data.NPCActionOpenShop
  local owner = ActionOpenShop and ActionOpenShop.Owner and ActionOpenShop.Owner.owner
  if owner and owner.viewObj then
    if bCache then
      self.CachedActorCullingMask = owner.viewObj.NRCLayerMask
    end
    owner.viewObj:SetLayerMask(Mask or 1, true)
  end
end

function UMG_NPCShop_C:HideOrShowMoneyBtn(_IsShow)
  if _IsShow then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NPCShop_C:CloseNPCShop(shopId)
  if 101 ~= shopId and 102 ~= shopId then
    self:StartCaptureTick(false)
    self:DelaySeconds(1, function()
      self:ShopClose()
    end)
  end
end

function UMG_NPCShop_C:SetNPCShopBtnEnable()
end

function UMG_NPCShop_C:OnAnimationFinished(anim)
  self:Log("UMG_NPCShop_C OnAnimationFinished:", anim:GetName())
  if anim == self.close_an then
    self:ShopClose()
  elseif anim == self.open then
    self:PlayAnimation(self.change_icon)
  elseif anim == self.Reward_in then
    self:PlayAnimation(self.Reward_loop, 0, 1000)
  elseif anim == self.Reward_out then
    self:PlayAnimation(self.Reward_normal)
  end
end

function UMG_NPCShop_C:ShopClose()
  if self.data then
    self:StartCaptureTick(false)
    self.data.itemData = {}
    self.data.costInfo = {
      0,
      0,
      0
    }
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1008, "UMG_NPCShop_C:OnCloseButtonClicked")
    if self.data:GetOpenNpcShopType() == NPCShopUIModuleEnum.OpenNPCShopFormType.MagicManualMain then
      _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.CmdShowMagicManualMain)
    elseif self.data:GetOpenNpcShopType() == NPCShopUIModuleEnum.OpenNPCShopFormType.PvpQualifier then
      _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ShowUmgPVPQualifier)
    end
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.SetNpcShopOpenType, nil)
    self:DoClose()
  end
end

function UMG_NPCShop_C:ShopCloseVisit()
  if self.data then
    self:StartCaptureTick(false)
    self.data.itemData = {}
    self.data.costInfo = {
      0,
      0,
      0
    }
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1008, "UMG_NPCShop_C:OnCloseButtonClicked")
    self:RestoreHudStatus()
    self:ReleaseCaptureResource()
    if 0 == GlobalConfig.OpenMainPanelFromDebugBtn then
      self.data.NPCActionOpenShop.Owner.owner:LockVisibility(false)
      if self.data.NPCActionOpenShop ~= nil and not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        self.data.NPCActionOpenShop = nil
      end
    end
    self:DoClose()
  end
end

function UMG_NPCShop_C:OnClearBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1006, "UMG_NPCShop_C:OnClearBtnClick")
  for i = 1, #self.uiData.itemList1 do
    self.uiData.itemList1[i].selectedNum = 0
  end
  self.data.itemData = {}
  self.data.costInfo = {
    0,
    0,
    0
  }
  self:updatePanelInfo()
  self:RefreshSumCost(self.data.costInfo)
  self.data.sumCoinCost = 0
  self.data.sumDiamondCost = 0
  self.uiData.CoinCost = 0
  self.uiData.DiamondCost = 0
end

function UMG_NPCShop_C:RefreshSumCost(cost)
  for i = 1, #self.uiData.itemList1 do
    for j = 1, 3 do
      self.uiData.itemList1[i].showMoneyCost[j] = cost[j]
    end
  end
  local count = self.ItemList:GetItemCount()
  for i = 1, count do
  end
end

function UMG_NPCShop_C:OnBuyBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_NPCShop_C:OnBuyBtnClick")
  local npcShopUIModule = _G.NRCModuleManager:GetModule("NPCShopUIModule")
  if npcShopUIModule:HasPanel("NPCShopConfirmNew") then
    local panel = npcShopUIModule:GetPanel("NPCShopConfirmNew")
    if panel then
      panel:DoClose()
    end
  end
  local item = self.uiData.itemList1[self.curSelectedIndex]
  local index = self.curSelectedIndex
  local ShopConf = _G.DataConfigManager:GetShopConf(self.uiData.shopId)
  if ShopConf and ShopConf.shop_type == Enum.ShopType.ST_RANDOM_SHOP then
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      local npcRefreshId = self.module.data:GetNPCContentID(self.uiData.shopId)
      local CanBuy = bigMapModule.data:CanShowRandomShopHint(npcRefreshId)
      if not CanBuy then
        self:OnCloseButtonClicked()
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.random_shop_timeout_tips_1)
        return
      end
    end
  end
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopConfirmNew, item, self.uiData, self.data, self.curSelectedIndex)
  self:HideOrShowMoneyBtn()
end

function UMG_NPCShop_C:OnRewardBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_NPCShop_C:OnBuyBtnClick")
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopClaimReward, self.uiData.consume_info, self.uiData.shopId)
end

function UMG_NPCShop_C:OnTitleBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1005, "UMG_NPCShop_C:OnTitleBtnClick")
end

function UMG_NPCShop_C:ShowSelectAllNum()
  local itemCnt = #self.data.itemData
  local num = 0
  if self.data.itemData then
    for i = 1, itemCnt do
      num = num + self.data.itemData[i].itemNum
    end
  end
  if num > 0 then
    self.NRCText_allnum:SetText(num)
  else
    self.CanvasPanelBuyNum:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_NPCShop_C:GetGaiWay(bagItemInfo)
  local real_acquire_struct = {}
  for i = 1, #bagItemInfo.acquire_struct do
    if bagItemInfo.acquire_struct[i].acquire_way_text == nil then
      goto lbl_40
    elseif 0 == bagItemInfo.acquire_struct[i].behavior_id then
      table.insert(real_acquire_struct, 1, {
        acquire_struct = bagItemInfo.acquire_struct[i]
      })
    else
      table.insert(real_acquire_struct, {
        acquire_struct = bagItemInfo.acquire_struct[i]
      })
    end
    ::lbl_40::
  end
  return real_acquire_struct
end

function UMG_NPCShop_C:ShowTopMoney(datas, umgs, IsTop)
  if not IsTop then
    for i = 1, #umgs do
      if i > #datas then
        umgs[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        umgs[i]:SetInfo(datas[i].currencyType, datas[i].num, false)
        umgs[i]:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    end
  else
    for i = 1, #umgs do
      if i > #datas then
        umgs[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        umgs[i]:OnActive(datas[i])
        umgs[i]:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    end
  end
end

function UMG_NPCShop_C:StartCaptureTick(bStart)
  if self.data == nil then
    Log.Error("UMG_NPCShop_C  self.data is nil\239\188\140\230\156\137\233\151\174\233\162\152\239\188\129\229\133\136\229\138\160\228\191\157\230\138\164\239\188\140\233\152\178\230\173\162\229\141\161\230\173\187")
    return
  end
  if self.data.NPCActionOpenShop and bStart ~= self.hasStopTick then
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.SetUICameraCaptureTickable, bStart)
    self.hasStopTick = bStart
  end
end

function UMG_NPCShop_C:BtnInit()
  self.UMG_Btn2:SetBtnText(LuaText.umg_npcshopitem_1_4)
  self.UMG_Btn2:SetPath("PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/ui_combtn_cancel_png.ui_combtn_cancel_png'")
end

function UMG_NPCShop_C:SwitchBtnSoldOutState(_issoldout, isUnlock, SoldOut_goodsNameList, LockParam, AlreadyHasItem)
  if _issoldout then
    self.UMG_Btn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_Btn4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Btn4:SetShowLockIcon(false)
    self.UMG_Btn4:SetTitleTextAndIcon()
    self.UMG_Btn4:SetBtnText(LuaText.goods_soldout)
  elseif not isUnlock then
    self.UMG_Btn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_Btn4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if AlreadyHasItem then
      self.UMG_Btn4:SetShowLockIcon(false)
      self.UMG_Btn4:SetTitleTextAndIcon()
      self.UMG_Btn4:SetBtnText(LuaText.tailor_owned_btn)
    else
      self.UMG_Btn4:SetShowLockIcon(true)
      if SoldOut_goodsNameList then
        local goodsNames = table.concat(SoldOut_goodsNameList, "\227\128\129")
        local text = string.format(LuaText.buy_cond_soldout_1, goodsNames)
        if LockParam and 0 == LockParam.buy_cond_param then
          text = LuaText.buy_cond_soldout_0
        end
        self.UMG_Btn4:SetTitleTextAndIcon(nil, nil, nil, nil, nil, text)
      elseif LockParam then
        local limitType = LockParam.limitType
        local limitBuyParam = LockParam.limitBuyParam
        local text = ""
        if limitType and limitBuyParam then
          if limitType == Enum.BuyLimited.BL_PLAYER_LEVEL then
            text = string.format(LuaText.buy_cond_player_level, limitBuyParam)
          elseif limitType == Enum.BuyLimited.BL_PLAYER_BP_LEVEL then
            text = string.format(LuaText.buy_cond_player_bp_level, limitBuyParam)
          elseif limitType == Enum.BuyLimited.BL_WORLD_LEVEL then
            local limitWorldLevel = tonumber(limitBuyParam)
            local WorldLevelConf = _G.DataConfigManager:GetWorldLevelConf(limitWorldLevel + 1)
            text = string.format(LuaText.buy_cond_world_level, WorldLevelConf and WorldLevelConf.title)
          end
        end
        self.UMG_Btn4:SetTitleTextAndIcon(nil, nil, nil, nil, nil, text)
      else
        self.UMG_Btn4:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.goods_unlock_des, nil)
      end
      self.UMG_Btn4:SetTitleTextColor("#c7494aFF")
      self.UMG_Btn4:SetBtnText(LuaText.goods_unlock_tips)
    end
  else
    self.UMG_Btn2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_Btn4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanelBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:PlayAnimation(self.change_icon)
end

function UMG_NPCShop_C:SortSoldGoods(_goods)
  local soldOutGoods = {}
  local availableGoods = {}
  local AlreadyHasItemGoods = {}
  for i, item in ipairs(_goods) do
    if item.AlreadyHasItem then
      table.insert(AlreadyHasItemGoods, item)
    elseif 0 ~= item.limitNum and item.boughtNum >= item.limitNum then
      table.insert(soldOutGoods, item)
    else
      table.insert(availableGoods, item)
    end
  end
  for i, item in ipairs(soldOutGoods) do
    table.insert(availableGoods, item)
  end
  for i, item in ipairs(AlreadyHasItemGoods) do
    table.insert(availableGoods, item)
  end
  return availableGoods
end

function UMG_NPCShop_C:SetMysteriousStoreShopList(shopID, shopList, shopData)
  local shopConf = _G.DataConfigManager:GetShopConf(shopID)
  if shopConf and shopConf.shop_type ~= _G.Enum.ShopType.ST_RANDOM_SHOP then
    return shopList
  end
  local HotItemList = {}
  local CommonItemList = {}
  for _, item in ipairs(shopList) do
    local itemCfg = _G.DataConfigManager:GetRandomGoodsConf(item.shopItemId)
    if itemCfg then
      if itemCfg.is_special_good then
        table.insert(HotItemList, item)
      else
        table.insert(CommonItemList, item)
      end
    end
  end
  local tempList = {}
  for _, item in ipairs(HotItemList) do
    local itemQuality = 0
    local sortId = 0
    local goodsConf = _G.DataConfigManager:GetRandomGoodsConf(item.shopItemId)
    if not goodsConf then
      Log.Warning("UMG_NPCShop_C:SetMysteriousStoreShopList", item.shopItemId)
      return
    end
    if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
      itemQuality = bagItemConf.item_quality or 0
      sortId = bagItemConf.sort_id or 0
    elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsConf.item_id)
      itemQuality = vItemConf.item_quality or 0
      sortId = vItemConf.sort_id or 0
    end
    item.isSpecial = true
    item.lastRefreshTime = shopData.last_refresh_time
    table.insert(tempList, {
      item = item,
      itemQuality = itemQuality,
      sortId = sortId
    })
  end
  table.sort(tempList, function(a, b)
    if a.itemQuality ~= b.itemQuality then
      return a.itemQuality > b.itemQuality
    else
      return a.sortId < b.sortId
    end
  end)
  local tempList2 = {}
  for _, item in ipairs(CommonItemList) do
    local itemQuality = 0
    local sortId = 0
    local goodsConf = _G.DataConfigManager:GetRandomGoodsConf(item.shopItemId)
    if not goodsConf then
      Log.Warning("UMG_NPCShop_C:SetMysteriousStoreShopList", item.shopItemId)
      return
    end
    if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
      itemQuality = bagItemConf.item_quality or 0
      sortId = bagItemConf.sort_id or 0
    elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(goodsConf.item_id)
      itemQuality = vItemConf.item_quality or 0
      sortId = vItemConf.sort_id or 0
    end
    item.isSpecial = false
    item.lastRefreshTime = shopData.last_refresh_time
    table.insert(tempList2, {
      item = item,
      itemQuality = itemQuality,
      sortId = sortId
    })
  end
  table.sort(tempList2, function(a, b)
    if a.itemQuality ~= b.itemQuality then
      return a.itemQuality > b.itemQuality
    else
      return a.sortId < b.sortId
    end
  end)
  local shopList = {}
  local soldOutList = {}
  for _, v in ipairs(tempList) do
    local item = v.item
    if 0 ~= item.limitNum and item.boughtNum >= item.limitNum then
      table.insert(soldOutList, item)
    else
      table.insert(shopList, item)
    end
  end
  for _, v in ipairs(tempList2) do
    local item = v.item
    if 0 ~= item.limitNum and item.boughtNum >= item.limitNum then
      table.insert(soldOutList, item)
    else
      table.insert(shopList, item)
    end
  end
  for _, item in ipairs(soldOutList) do
    table.insert(shopList, item)
  end
  return shopList
end

function UMG_NPCShop_C:SetIcon(icon_path, bag_item_conf)
  if icon_path and bag_item_conf and bag_item_conf.type == _G.Enum.BagItemType.BI_PET_EGG and bag_item_conf.item_behavior and bag_item_conf.item_behavior[1] and bag_item_conf.item_behavior[1].ratio2 and bag_item_conf.item_behavior[1].ratio2[1] then
    local eggInfo = {}
    eggInfo.random_egg_conf = bag_item_conf.item_behavior[1].ratio2[1]
    self.IconSwitcher:SetActiveWidgetIndex(1)
    self.PetEggIcon:SetEggIcon(eggInfo, icon_path)
    return
  end
  if icon_path then
    self.IconSwitcher:SetActiveWidgetIndex(0)
    self.HeadIcon:SetPath(icon_path)
  end
end

function UMG_NPCShop_C:OnBuySuccess()
  local goodsConf = self:GetCurGoodsConf()
  if not goodsConf then
    return
  end
  if goodsConf.Type == Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(goodsConf.item_id)
    local itemData = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, goodsConf.item_id)
    if nil ~= itemData then
      self.hasCount:SetText(itemData.num)
    elseif nil ~= bagItemConf and bagItemConf.is_auto_use then
      local num = self:GetAutoUseItemNum(bagItemConf.item_behavior)
      self.hasCount:SetText(num)
    end
  elseif goodsConf.Type == Enum.GoodsType.GT_VITEM then
    local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(goodsConf.item_id)
    if nil ~= num then
      self.hasCount:SetText(num)
    end
  end
end

function UMG_NPCShop_C:OnClaimSuccess()
  self:OnBuySuccess()
end

function UMG_NPCShop_C:ReleaseCaptureResource()
  UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_NPCShop_C_Capture")
  if not self.data then
    return
  end
  local npcActionOpenShop = self.data.NPCActionOpenShop
  local owner = npcActionOpenShop and npcActionOpenShop.Owner and npcActionOpenShop.Owner.owner
  local viewObj = owner and owner.viewObj
  if UE4.UObject.IsValid(viewObj) and viewObj.Mesh then
    viewObj.Mesh:SetForcedLOD(0)
  end
  self:StartCaptureTick(false)
  self:SetDialogueUICameraCullingMask(self.CachedCameraCullingMask)
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "r.Shadow.CSMCaching.ForceUpdate 10")
  self:SetActorCullingMask(self.CachedActorCullingMask)
end

function UMG_NPCShop_C:OnBringToFront()
  self:HideOrShowMoneyBtn(true)
end

return UMG_NPCShop_C

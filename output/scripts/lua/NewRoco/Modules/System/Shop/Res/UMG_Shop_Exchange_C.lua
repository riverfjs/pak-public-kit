local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local UMG_Shop_Exchange_C = _G.NRCPanelBase:Extend("UMG_Shop_Exchange_C")

function UMG_Shop_Exchange_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_Shop_Exchange_C:OnActive(ExchangeConf, MaxiItemCount, defaultNum)
  if defaultNum then
    self.bEnough = 0 == MaxiItemCount
  end
  MaxiItemCount = math.max(1, MaxiItemCount or 1)
  self.ExchangeConf = ExchangeConf
  self.bNeedCloseShopTip = false
  self:SetCommonPopUpInfo(self.PopUp, LuaText.visual_item_exchange)
  self:SetCommonAddSubtractData(MaxiItemCount)
  if defaultNum then
    self.SliderPanel:SetProgressBarPercent(defaultNum / MaxiItemCount)
    self.SliderPanel:SetSliderValue(defaultNum)
  else
    self.SliderPanel:SetProgressBarPercent(1.0 / MaxiItemCount)
  end
  self:SetInput(1)
  self.Item1 = {
    itemId = ExchangeConf.cost_item[1].cost_goods_id[1],
    itemType = ExchangeConf.cost_item[1].cost_goods_type,
    bShowTip = true,
    itemNum = ExchangeConf.cost_item[1].cost_goods_num,
    bShowNum = true,
    IsCanClick = true
  }
  self.Item2 = {
    itemId = ExchangeConf.get_item[1].get_goods_id,
    itemType = ExchangeConf.get_item[1].get_goods_type,
    bShowTip = true,
    itemNum = ExchangeConf.get_item[1].get_goods_num,
    bShowNum = true,
    IsCanClick = true
  }
  self.ListItemIcon:OnItemUpdate(self.Item1, nil, 0)
  self.ListItemIcon_1:OnItemUpdate(self.Item2, nil, 1)
  self.SliderPanel:SetMultipleAddBtnText(1)
  self.SliderPanel:SetSelectNumText(MaxiItemCount)
  self:LoadAnimation(0)
  if self.NRCImage then
    self.NRCImage:SetPath((DataConfigManager:GetVisualItemConf(self.Item2.itemId, true) or {}).iconPath)
  end
  self:OnSliderValueChanged()
end

function UMG_Shop_Exchange_C:SetCommonAddSubtractData(MaxiItemCount)
  local SliderInfo = {num1 = 0, num2 = MaxiItemCount}
  local ProgressBarInfo = {num1 = 0, num2 = MaxiItemCount}
  local CommonPopUpData = _G.NRCCommonAddSubtractData()
  CommonPopUpData.Call = self
  CommonPopUpData.SliderInfo = SliderInfo
  CommonPopUpData.ProgressBarInfo = ProgressBarInfo
  CommonPopUpData.SubtractBtnHandler = self.OnReqReduceOnce
  CommonPopUpData.AddBtnHandler = self.OnReqIncreaseOnce
  CommonPopUpData.MaxBtnOnReleasedHandler = self.OnReqIncreaseMax
  CommonPopUpData.SliderHandler = self.OnSliderValueChanged
  self.SliderPanel:SetPanelInfo(CommonPopUpData)
end

function UMG_Shop_Exchange_C:OpenTopUpShop()
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenTopUpShop)
end

function UMG_Shop_Exchange_C:OnDeactive()
  _G.NRCAudioManager:PlaySound2DAuto(1220002047, "UMG_BagItemTemplate_C:OnItemSelected")
  self.ExchangeConf = nil
end

function UMG_Shop_Exchange_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.ClosePanel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Shop_Exchange_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn, self.ClosePanel)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.ClosePanel)
  self:AddButtonListener(self.Btn3.btnLevelUp, self.SendExchangeReq)
  self.BuildTimeText.OnTextChanged:Add(self, self.OnInputChanged)
  self.BuildTimeText.OnTextCommitted:Add(self, self.OnTextCommitted)
  self.ListItemIcon.ParentView = self
  self.ListItemIcon_1.ParentView = self
  self.ListItemIcon.BroadcastOnClicked = FPartial(self.OnChildItemClick, self, self.ListItemIcon)
  self.ListItemIcon_1.BroadcastOnClicked = FPartial(self.OnChildItemClick, self, self.ListItemIcon_1)
end

function UMG_Shop_Exchange_C:OnChildItemClick(View)
  if View == self.ListItemIcon then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.Item1.itemId, self.Item1.itemType, false)
  elseif View == self.ListItemIcon_1 then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.Item2.itemId, self.Item2.itemType, false)
  end
end

function UMG_Shop_Exchange_C:SetInput(Value)
  self.LastInput = Value
  self.BuildTimeText:SetText(tostring(Value))
  self.SliderPanel:SetDigitalEnable(tonumber(Value))
end

function UMG_Shop_Exchange_C:OnInputChanged()
  local Text = self.BuildTimeText:GetText()
  if "" ~= Text then
    local Num = math.tointeger(Text)
    if not Num then
      Text = self._LastInputRealtime or ""
    end
  end
  self._LastInputRealtime = Text
  self.BuildTimeText:SetText(Text)
  self.SliderPanel:SetDigitalEnable(tonumber(Text))
end

function UMG_Shop_Exchange_C:OnTextCommitted()
  local Text = self.BuildTimeText:GetText()
  local Num = "" == Text and 1 or math.tointeger(Text)
  if not Num then
    Num = self.LastInput
  elseif Num > self.SliderPanel:GetSliderMaxValue() then
    Num = self.SliderPanel:GetSliderMaxValue()
  end
  self.SliderPanel:SetSliderValue(Num)
  self:OnSliderValueChanged()
end

function UMG_Shop_Exchange_C:OnReqReduceOnce()
  self.SliderPanel:SetSliderValue(math.max(1, self.SliderPanel:GetSliderValue() - 1))
  self:OnSliderValueChanged()
end

function UMG_Shop_Exchange_C:OnReqIncreaseOnce()
  self.SliderPanel:SetSliderValue(math.min(self.SliderPanel:GetSliderValue() + 1, self.SliderPanel:GetSliderMaxValue()))
  self:OnSliderValueChanged()
  Log.Info("UMG_Shop_Exchange_C:OnReqIncreaseOnce")
end

function UMG_Shop_Exchange_C:OnReqIncreaseMax()
  Log.Info("UMG_Shop_Exchange_C:OnReqIncreaseMax Start")
  self.SliderPanel:SetSliderValue(self.SliderPanel:GetSliderMaxValue())
  self:OnSliderValueChanged()
  Log.Info("UMG_Shop_Exchange_C:OnReqIncreaseMax End")
end

function UMG_Shop_Exchange_C:OnSliderValueChanged()
  local CurValue = self.SliderPanel:GetSliderValue()
  local MaxValue = self.SliderPanel:GetSliderMaxValue()
  CurValue = math.max(1.0, CurValue)
  local Percent = CurValue / MaxValue
  self.SliderPanel:SetProgressBarPercent(Percent)
  self.SliderPanel:SetSliderValue(CurValue)
  self:SetInput(math.floor(CurValue))
end

function UMG_Shop_Exchange_C:ClosePanel()
  self:LoadAnimation(2)
end

function UMG_Shop_Exchange_C:SendExchangeReq()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_BagItemTemplate_C:OnItemSelected")
  if not self.ExchangeConf then
    self:LogError("logical error!!!")
    return
  end
  local UseItemType = self.ExchangeConf.cost_item[1].cost_goods_id[1]
  if UseItemType == Enum.VisualItem.VI_COUPON then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_DIAMOND_EXCHANGE, true)
    if isBan then
      return
    end
  end
  if self.bEnough then
    if UseItemType == Enum.VisualItem.VI_COUPON then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("shop_exchange_limit").msg)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("shop_exchange_notenough_tips").msg)
    end
    return
  end
  local CurValue = self.SliderPanel:GetSliderValue()
  local ExchangeNum = math.floor(math.max(1, CurValue))
  local UseItemCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(UseItemType)
  local UseItemPerCount = self.ExchangeConf.cost_item[1].cost_goods_num
  local NeedNum = ExchangeNum * UseItemPerCount
  if UseItemCount < NeedNum then
    local ItemConf = DataConfigManager:GetVisualItemConf(UseItemType)
    local Ctx = DialogContext()
    Ctx:SetTitle(LuaText.TIPS)
    Ctx:SetContent(string.format(LuaText.Recharge_Tips3, NeedNum - UseItemCount, ItemConf.displayName))
    Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
    Ctx:SetCallbackOkOnly(self, function(_)
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenTopUpShop, true)
      if self.bNeedCloseShopTip then
        _G.NRCModuleManager:DoCmd(ShopModuleCmd.EnableOrDisableShopOnPopUpOpen, false, true)
      else
        _G.NRCModuleManager:DoCmd(ShopModuleCmd.EnableOrDisableShopOnPopUpOpen, true)
      end
      self:DoClose()
    end)
    Ctx:SetCloseOnCancel(true)
    Ctx:SetButtonText(LuaText.YES, LuaText.NO)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
    return
  end
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local ActorId = localPlayer.serverData.base.actor_id
  self:Log("pay exchange,", self.ExchangeConf.id, ExchangeNum, 1, ActorId, self.ExchangeConf.cost_item[1].cost_goods_id)
  _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SendExchangeReq, self.ExchangeConf.id, ExchangeNum, 1, ActorId, self.ExchangeConf.cost_item[1].cost_goods_id)
  self.bNeedCloseShopTip = true
  self:ClosePanel()
end

function UMG_Shop_Exchange_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if self.bNeedCloseShopTip then
      _G.NRCModuleManager:DoCmd(ShopModuleCmd.EnableOrDisableShopOnPopUpOpen, false, true)
    else
      _G.NRCModuleManager:DoCmd(ShopModuleCmd.EnableOrDisableShopOnPopUpOpen, true)
    end
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

return UMG_Shop_Exchange_C

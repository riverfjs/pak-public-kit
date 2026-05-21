local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local BigMapModuleEvent = require("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local StarChainEnum = require("NewRoco.Modules.System.StarChain.StarChainEnum")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local UMG_MoneyButton_C = Base:Extend("UMG_MoneyButton_C")
UMG_MoneyButton_C.EnterType = {
  Common = 0,
  BloodBattle = 1,
  MythicalCreatures = 2
}

function UMG_MoneyButton_C:OnConstruct()
  self.IsShowStarChainTimePanel = false
  self.IsCloseCall = nil
  self.currencyId = nil
  self.owner = nil
  self.CurrentEnterType = self.EnterType.Common
  self.touchLimitData = nil
  self.bCanClick = false
  self:OnAddEventListener()
end

function UMG_MoneyButton_C:OnAddEventListener()
  self:AddButtonListener(self.AddBtn, self.OnClickAddBtn)
  self:AddButtonListener(self.ClickItemBtn, self.OnClickItemBtn)
  self:AddButtonListener(self.ShowStarChainTimeBtn, self.OnClickShowStarChainTimeBtn)
end

function UMG_MoneyButton_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.AddBtn, self.OnClickAddBtn)
  self:RemoveButtonListener(self.ClickItemBtn, self.OnClickItemBtn)
  self:RemoveButtonListener(self.ShowStarChainTimeBtn, self.OnClickShowStarChainTimeBtn)
end

function UMG_MoneyButton_C:SetCurrentEnterType(_CurrentEnterType)
  self.CurrentEnterType = _CurrentEnterType
end

function UMG_MoneyButton_C:OnTouchEnded(MyGeometry, InTouchEvent)
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_MoneyButton_C:SetViewData()
end

function UMG_MoneyButton_C:DoSetChildViewDataAndConstruct()
end

function UMG_MoneyButton_C:OnDestruct()
  for _, id in pairs(self.DelayIDs or {}) do
    _G.DelayManager:CancelDelayById(id)
  end
  self.DelayIDs = nil
end

function UMG_MoneyButton_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.Full:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _data.IsShareButton then
    self.AddBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 1 == _data.moneyType then
      self.MoneyIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_QuestionMark_png.img_QuestionMark_png'")
    elseif 2 == _data.moneyType then
      self.MoneyIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_ExclamationMark_png.img_ExclamationMark_png'")
    end
    self.SumNum:SetText(_data.sum)
  else
    self:SetInfo(_data.moneyType, _data.sum, _data.IsShowBuyIcon, _data.touchLimitData, _data.bCanClick, _data.bLegendary)
    if _data.ShowColor then
      self.SumNum:SetColorAndOpacity(_data.ShowColor)
    end
    if _data.SourceReturnFlag then
      self.SourceReturnFlag = _data.SourceReturnFlag
    end
    if _data.SourceReturnFunc then
      self.SourceReturnFunc = _data.SourceReturnFunc
    end
  end
end

function UMG_MoneyButton_C:SetCurrencyInfo()
  local moneyType, moneyId
  if self.data and self.data.currencyType then
    moneyType = self.data.currencyType
  end
  if self.data and self.data.currencyId then
    moneyId = self.data.currencyId
    self.moneyId = moneyId
  end
  local iconPath, displayName = NPCShopUtils:GetGoodsCurrencyIconByType(moneyType, moneyId)
  if iconPath then
    self.MoneyIcon:SetPath(iconPath)
  end
end

function UMG_MoneyButton_C:SetInfo(moneyType, sum, IsShowBuyIcon, touchLimitData, bCanClick, bLegendary)
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self:OnRemoveEventListener()
  self:OnAddEventListener()
  self.moneyType = moneyType
  self.bCanClick = bCanClick or false
  self.CurrentEnterType = self.CurrentEnterType or self.EnterType.Common
  self.touchLimitData = touchLimitData
  self.bLegendary = bLegendary
  if moneyType then
    if moneyType < 100000 then
      local vItemsConf = _G.DataConfigManager:GetVisualItemConf(moneyType)
      if vItemsConf then
        self.currencyId = vItemsConf.id
        if self.MoneyIcon then
          self.MoneyIcon:SetPath(vItemsConf.iconPath)
        end
      end
    else
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(moneyType)
      self.currencyId = bagItemConf.id
      if self.MoneyIcon then
        self.MoneyIcon:SetPath(bagItemConf.icon)
      end
    end
  end
  self:SetCurrencyInfo()
  if self.ShowStarChainTimeBtn then
    self.ShowStarChainTimeBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    Log.Error("self.ShowStarChainTimeBtn Not Found")
  end
  self.IsShowBuyIcon = IsShowBuyIcon
  if IsShowBuyIcon then
    self.SumNum:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SumNum_1:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.currencyId == Enum.VisualItem.VI_STAR_DEBRIS or self.currencyId == _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num or bLegendary then
      self.AddBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
      self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.AddBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.moneyType == _G.Enum.VisualItem.VI_STAR or self.moneyType == _G.Enum.VisualItem.VI_STAR_DEBRIS or self.currencyId == _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num or bLegendary then
      self.ShowStarChainTimeBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ShowStarChainTimeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.ClickItemBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsCloseCall = true
    self.SumNum_1:SetText(sum)
  else
    self.IsCloseCall = true
    self.SumNum:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SumNum_1:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.AddBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ClickItemBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SumNum:SetText(sum)
  end
end

function UMG_MoneyButton_C:SetSumText(text, showFull)
  self.SumNum:SetText(text)
  self.SumNum_1:SetText(text)
  self.Full:SetVisibility(showFull and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_MoneyButton_C:RefreshMoneyNum()
  local bValidParamCall, finalNewNum = self:RefreshMoneyNumNew()
  if not bValidParamCall and self.moneyType then
    finalNewNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(self.moneyType)
  end
  if self.SumNum:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.SumNum:SetText(finalNewNum)
  elseif self.SumNum_1:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.SumNum_1:SetText(finalNewNum)
  end
end

function UMG_MoneyButton_C:RefreshMoneyNumNew()
  local bValidParamCall = true
  local moneyType, moneyId
  if self.data and self.data.currencyType then
    moneyType = self.data.currencyType
  end
  if self.data and self.data.currencyId then
    moneyId = self.data.currencyId
  end
  if moneyType == _G.Enum.GoodsType.GT_VITEM then
    local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(moneyId)
    return bValidParamCall, num
  elseif moneyType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, moneyId)
    if bagItem then
      return bValidParamCall, bagItem.num
    else
      Log.Warning("UMG_MoneyButton_C:RefreshMoneyNumNew Invalid bagItemId", moneyType, moneyId)
      return bValidParamCall, 0
    end
  end
  bValidParamCall = false
  return bValidParamCall
end

function UMG_MoneyButton_C:OnClickAddBtn()
  if self.moneyId == Enum.VisualItem.VI_COUPON then
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenTopUpShop)
  elseif self.moneyId == Enum.VisualItem.VI_DIAMOND then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_DIAMOND_EXCHANGE, true)
    if isBan then
      return
    end
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenExchangeDiamond)
    _G.NRCModuleManager:DoCmd(ShopModuleCmd.EnableOrDisableShopOnPopUpOpen, false)
  elseif self.moneyId == Enum.VisualItem.VI_PIKA_POINT then
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenTopUpShop, false, Enum.MallType.MT_CREDIT)
  elseif self.moneyId == Enum.VisualItem.VI_ACTIVITY_COCO_INTERGRAL then
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenExchangePoint, self.moneyId)
  end
end

function UMG_MoneyButton_C:OnClickItemBtn()
  if self.data and self.data.IsShareButton then
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenShareTeamDiffOrLackPanel, self.data.moneyType)
  elseif self.data and self.data.currencyType and self.data.currencyId then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.data.currencyId, self.data.currencyType, false)
    _G.NRCModuleManager:DoCmd(BagModuleCmd.HideDescPanel)
  elseif self.currencyId then
    _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_Activity_LegendaryBattle_C:OnHabitBtnClicked")
    if self.currencyId < 100000 then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.currencyId, _G.Enum.GoodsType.GT_VITEM, false)
    else
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.currencyId, _G.Enum.GoodsType.GT_BAGITEM, false)
    end
    _G.NRCModuleManager:DoCmd(BagModuleCmd.HideDescPanel)
  end
end

function UMG_MoneyButton_C:OnClickShowStarChainTimeBtn()
  if self:CheckIsSelectBtn() then
    return
  end
  if self.currencyId == Enum.VisualItem.VI_STAR then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_STAMINA_EXCHANGE, true)
    if isBan then
      return
    end
  end
  if self.IsShowBuyIcon and not self.bCanClick then
    if self.currencyId == Enum.VisualItem.VI_STAR then
      self:OpenRecoveryTimePanelByEnterType(StarChainEnum.OpenType.Common)
    elseif self.currencyId == Enum.VisualItem.VI_STAR_DEBRIS then
      if self.CurrentEnterType == self.EnterType.Common then
        if self.data and self.data.Call and self.data.Handler then
          self.data.Handler(self.data.Call)
        end
        _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, self.SourceReturnFlag)
        if self.data then
          _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, self.SourceReturnFunc, self.data.Call)
        end
        self:LockSelectBtn()
        _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenStarDebrisRecoveryTime, false, StarChainEnum.OpenType.Common, true, self.currencyId, self.touchLimitData)
        _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.ShowOrHideMoneyBtn, true)
        _G.NRCModuleManager:DoCmd(StarChainModuleCmd.ShowOrHideMoneyBtn, true)
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowOrHideMoneyBtn, true)
      elseif self.CurrentEnterType == self.EnterType.BloodBattle then
        self:LockSelectBtn()
        _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, self.SourceReturnFlag)
        _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, self.SourceReturnFunc)
        _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenStarDebrisRecoveryTime, false, StarChainEnum.OpenType.Common, true, self.currencyId, self.touchLimitData)
        _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.ShowOrHideMoneyBtn, true)
        _G.NRCModuleManager:DoCmd(StarChainModuleCmd.ShowOrHideMoneyBtn, true)
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowOrHideMoneyBtn, true)
      end
    elseif self.currencyId == _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num or self.bLegendary then
      self:LockSelectBtn()
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.currencyId, 1, false)
    end
    _G.NRCModuleManager:DoCmd(BagModuleCmd.HideDescPanel)
  end
  _G.NRCEventCenter:DispatchEvent(BagModuleEvent.OnMoneyBtnClick, self.currencyId)
end

function UMG_MoneyButton_C:OpenRecoveryTimePanelByEnterType(OpenType)
  if self.CurrentEnterType == self.EnterType.Common then
    if self.data and self.data.Call and self.data.Handler then
      self.data.Handler(self.data.Call)
    end
    self:LockSelectBtn()
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, self.SourceReturnFlag)
    if self.data then
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, self.SourceReturnFunc, self.data.Call)
    end
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime, false, OpenType, true, self.touchLimitData)
    _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.ShowOrHideMoneyBtn, true)
    _G.NRCModuleManager:DoCmd(StarChainModuleCmd.ShowOrHideMoneyBtn, true)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowOrHideMoneyBtn, true)
  elseif self.CurrentEnterType == self.EnterType.BloodBattle then
    self:LockSelectBtn()
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, self.SourceReturnFlag)
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, self.SourceReturnFunc)
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime, false, OpenType, true, self.touchLimitData)
  end
end

function UMG_MoneyButton_C:SetSourceReturnFlagAndFunc(flag, func)
  self.SourceReturnFlag = flag
  self.SourceReturnFunc = func
end

function UMG_MoneyButton_C:SetHandler(_Call, _Handler)
  if not self.data then
    self.data = {}
  end
  self.data.Call = _Call
  self.data.Handler = _Handler
end

function UMG_MoneyButton_C:CheckIsSelectBtn()
  if self.touchLimitData then
    return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, self.touchLimitData.module, self.touchLimitData.panel)
  else
    return false
  end
end

function UMG_MoneyButton_C:LockSelectBtn()
  if self.touchLimitData then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, self.touchLimitData.panel).MONEYTIMECLICK
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, self.touchLimitData.module, self.touchLimitData.panel, touchReasonType)
  end
end

function UMG_MoneyButton_C:PlayCollectAnim(InFinalNum)
  self.finalNum = InFinalNum
  self:PlayAnimation(self.Add_Yuanwangshuijing_In)
end

function UMG_MoneyButton_C:OnAnimationFinished(Anim)
  if Anim == self.Add_Yuanwangshuijing_In then
    self:PlayAnimation(self.Add_Yuanwangshuijing_Loop)
    self.tickNum = 100
    self.curTimeCnt = 0
    self.curNum = tonumber(self.SumNum:GetText())
    self.DelayIDs = {}
    local tickTime = 0.01
    for i = 1, self.tickNum do
      local id = _G.DelayManager:DelaySeconds(tickTime * i, self.OnChangeNum, self)
      table.insert(self.DelayIDs, id)
    end
  elseif Anim == self.Add_Yuanwangshuijing_Loop then
    self:PlayAnimation(self.Add_Yuanwangshuijing_Out)
    self.SumNum:SetText(self.finalNum)
  end
end

function UMG_MoneyButton_C:OnChangeNum()
  if self.curTimeCnt + 1 < self.tickNum then
    local num = (self.finalNum - self.curNum) / self.tickNum * self.curTimeCnt + self.curNum
    self.curTimeCnt = self.curTimeCnt + 1
    self.SumNum:SetText(math.floor(num + 0.5))
    if self.DelayIDs and #self.DelayIDs > 0 then
      table.remove(self.DelayIDs, 1)
    end
  end
end

return UMG_MoneyButton_C

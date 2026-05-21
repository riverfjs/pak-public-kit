local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local StarChainEnum = require("NewRoco.Modules.System.StarChain.StarChainEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_Pet_RecoveryTime_C = _G.NRCPanelBase:Extend("UMG_Pet_RecoveryTime_C")

function UMG_Pet_RecoveryTime_C:OnConstruct()
  self.ItemList = {}
  self.SelectItem = nil
  self.SelectIndex = 0
  self.leftStarChallengeTimes = 0
  self:SetChildViews(self.PopUp4)
  self:OnAddEventListener()
end

function UMG_Pet_RecoveryTime_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_Pet_RecoveryTime_C:OnActive(_data)
  self.leftStarChallengeTimes = _data.available_challenge_num_via_star
  self:SetCommonPopUpInfo(self.PopUp4)
  self:SetListInfo()
  self:SetPanelInfo()
  self:LoadAnimation(0)
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.CloseAllBattleChatRelatedUI)
end

function UMG_Pet_RecoveryTime_C:OnDeactive()
end

function UMG_Pet_RecoveryTime_C:OnPcClose()
  self:Cancel()
end

function UMG_Pet_RecoveryTime_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_Pet_RecoveryTime_C", self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.OnBagChange)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateData)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
end

function UMG_Pet_RecoveryTime_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.OnBagChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateData)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
end

function UMG_Pet_RecoveryTime_C:SetListInfo()
  local rewardsTable = {}
  local starNum2 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR) or 0
  local costNum2 = _G.DataConfigManager:GetLegendaryGlobalConfig("star_consume").num
  local ItemData = _G.NRCCommonItemIconData()
  ItemData.itemType = _G.Enum.GoodsType.GT_VITEM
  ItemData.itemId = _G.Enum.VisualItem.VI_STAR
  ItemData.itemNum = starNum2
  ItemData.BagNum = starNum2
  ItemData.ConsumeNum = costNum2
  ItemData.bShowNum = true
  ItemData.bShowTip = true
  ItemData.IsDoCmd = true
  ItemData.DoCmd = "BattleUIModuleCmd.SelectPetRecoverTime"
  table.insert(rewardsTable, ItemData)
  local costItemId1, costNum1 = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum)
  local starNum1 = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, costItemId1)
  if nil == starNum1 then
    starNum1 = 0
  else
    starNum1 = starNum1.num
  end
  if starNum1 > 0 then
    local ItemData_1 = _G.NRCCommonItemIconData()
    ItemData_1.itemType = _G.Enum.GoodsType.GT_BAGITEM
    ItemData_1.itemId = costItemId1
    ItemData_1.itemNum = starNum1
    ItemData_1.BagNum = starNum1
    ItemData_1.ConsumeNum = costNum1
    ItemData_1.bShowNum = true
    ItemData_1.bShowTip = true
    ItemData_1.IsDoCmd = true
    ItemData_1.DoCmd = "BattleUIModuleCmd.SelectPetRecoverTime"
    table.insert(rewardsTable, ItemData_1)
  end
  self.ItemList = rewardsTable
  if self.leftStarChallengeTimes and self.leftStarChallengeTimes > 0 and starNum2 > 0 then
    self.SelectIndex = 0
  elseif self.leftStarChallengeTimes and self.leftStarChallengeTimes < 0 then
    self.SelectIndex = 1
  end
end

function UMG_Pet_RecoveryTime_C:SetPanelInfo()
  self.IconList:InitGridView(self.ItemList)
  self.IconList:SelectItemByIndex(self.SelectIndex)
  self:UpdateCoin()
end

function UMG_Pet_RecoveryTime_C:SelectPetRecoverTime(_index, uiData)
  self.SelectItem = uiData
  if uiData.itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(uiData.itemId)
    local confirmation = string.format(LuaText.star_chain_module_text_6, uiData.ConsumeNum, vItemsConf.displayName, self.leftStarChallengeTimes)
    self.PopUp4:SetDescInfo(confirmation)
    self.PopUp4.Btn_Right:SetTitleTextAndIcon(vItemsConf.bigIcon, uiData.ConsumeNum)
    if uiData.ConsumeNum > uiData.BagNum then
      self.PopUp4.Btn_Right:SetQuantityTextColor("#FF494BFF")
    else
      self.PopUp4.Btn_Right:SetQuantityTextColor("#F4EEE0FF")
    end
  elseif uiData.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(uiData.itemId)
    local confirmation = string.format(LuaText.star_chain_module_text_7, uiData.ConsumeNum, bagItemConf.name)
    self.PopUp4:SetDescInfo(confirmation)
    self.PopUp4.Btn_Right:SetTitleTextAndIcon(bagItemConf.icon, uiData.ConsumeNum)
    if uiData.ConsumeNum > uiData.BagNum then
      self.PopUp4.Btn_Right:SetQuantityTextColor("#FF494BFF")
    else
      self.PopUp4.Btn_Right:SetQuantityTextColor("#F4EEE0FF")
    end
  end
end

function UMG_Pet_RecoveryTime_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = false
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.Cancel
  CommonPopUpData.ClosePanelHandler = self.Cancel
  CommonPopUpData.Btn_RightHandler = self.Confirm
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Pet_RecoveryTime_C:UpdateData()
  local starNum2 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR) or 0
  local IsHasStar = false
  for i, Item in ipairs(self.ItemList) do
    if _G.Enum.GoodsType.GT_VITEM == Item.itemType and _G.Enum.VisualItem.VI_STAR == Item.itemId and starNum2 > 0 then
      Item.itemNum = starNum2
      Item.BagNum = starNum2
      if starNum2 < Item.ConsumeNum then
        self.PopUp4.Btn_Right:SetQuantityTextColor("#FF494BFF")
      else
        self.PopUp4.Btn_Right:SetQuantityTextColor("#F4EEE0FF")
      end
      local ItemInfo = self.IconList:GetItemByIndex(i - 1)
      if ItemInfo then
        ItemInfo:UpdateNum(starNum2)
      end
      IsHasStar = true
      break
    end
  end
  if IsHasStar then
    self.SelectItem.itemNum = starNum2
    self.SelectItem.BagNum = starNum2
    self:UpdateCoin()
  end
end

function UMG_Pet_RecoveryTime_C:OnBagChange(item)
  self:UpdateCoin()
  for i, Item in ipairs(self.ItemList) do
    if item.type == Item.itemType and item.id == Item.itemId then
      Item.itemNum = item.bag_item.num
      Item.BagNum = item.bag_item.num
      if Item.ConsumeNum > item.bag_item.num then
        self.PopUp4.Btn_Right:SetQuantityTextColor("#FF494BFF")
      else
        self.PopUp4.Btn_Right:SetQuantityTextColor("#F4EEE0FF")
      end
      local ItemInfo = self.IconList:GetItemByIndex(i - 1)
      if ItemInfo then
        ItemInfo:UpdateNum(item.bag_item.num)
      end
      break
    end
  end
  if item.id == self.SelectItem.itemId then
    self.SelectItem.itemNum = item.bag_item.num
    self.SelectItem.BagNum = item.bag_item.num
  end
end

function UMG_Pet_RecoveryTime_C:UpdateCoin()
  local moneyInfo = {}
  local costItemId1, _ = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum)
  local costItemId2 = _G.Enum.VisualItem.VI_STAR
  local starNum1 = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, costItemId1)
  local starNum2 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR) or 0
  if nil == starNum1 then
    starNum1 = 0
  else
    starNum1 = starNum1.num
  end
  table.insert(moneyInfo, {
    moneyType = costItemId2,
    sum = starNum2,
    IsShowBuyIcon = true
  })
  table.insert(moneyInfo, {
    moneyType = costItemId1,
    sum = starNum1,
    IsShowBuyIcon = true,
    bLegendary = true
  })
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_Pet_RecoveryTime_C:Cancel()
  self:LoadAnimation(2)
end

function UMG_Pet_RecoveryTime_C:Confirm()
  if not self.SelectItem then
    return
  end
  if self.SelectItem.itemType == _G.Enum.GoodsType.GT_VITEM then
    if self.leftStarChallengeTimes <= 0 then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.star_chain_module_text_8)
      return
    elseif self.SelectItem.ConsumeNum > self.SelectItem.BagNum then
      self:GoToShopCallBack(true)
      return
    end
  elseif self.SelectItem.itemType == _G.Enum.GoodsType.GT_BAGITEM and self.SelectItem.ConsumeNum > self.SelectItem.BagNum then
    self:GoToShopCallBack(true)
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.CloseIFCatchPanel, {
    IsConfirm = true,
    ticket_id = self.SelectItem.itemId
  })
  self:DoClose()
end

function UMG_Pet_RecoveryTime_C:OpenDialog()
  if self.SelectItem and self.SelectItem.ConsumeNum and self.SelectItem.BagNum and self.SelectItem.ConsumeNum > self.SelectItem.BagNum then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local Ctx = self:GetCheckGoToShopCtx()
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog2, Ctx)
  else
    self:OpenSelfFunc()
  end
end

function UMG_Pet_RecoveryTime_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if not self.bIsHideMoneyBtn then
      _G.BattleEventCenter:Dispatch(BattleEvent.CloseIFCatchPanel, {
        IsConfirm = false,
        ticket_id = self.SelectItem.itemId
      })
      self:DoClose()
    else
      self.bIsHideMoneyBtn = false
      self:Disable()
    end
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_Pet_RecoveryTime_C:GetCheckGoToShopCtx()
  local Name = _G.DataConfigManager:GetVisualItemConf(self.SelectItem.itemId).displayName
  local Ctx = DialogContext()
  local tips = string.format(LuaText.legendary_battle_tips_7, Name)
  Ctx:SetTitle(LuaText.TIPS)
  Ctx:SetContent(tips)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetButtonText(LuaText.YES, LuaText.NO)
  Ctx:SetBanFullScreenBtn()
  Ctx:SetCallback(self, self.GoToShopCallBack)
  return Ctx
end

function UMG_Pet_RecoveryTime_C:ShowOrHideMoneyBtn(bIsHide)
  if bIsHide then
    self.bIsHideMoneyBtn = true
    self:LoadAnimation(2)
  else
    self:Enable()
  end
end

function UMG_Pet_RecoveryTime_C:OnEnable()
  self:LoadAnimation(0)
end

function UMG_Pet_RecoveryTime_C:GoToShopCallBack(isEnter)
  if isEnter then
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, true)
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, self.OpenSelfFunc, self)
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime, false, StarChainEnum.OpenType.Common, true)
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.FadeOut)
    self:ShowOrHideMoneyBtn(true)
  else
    self:PlayAnimation(self.FadeIn)
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Pet_RecoveryTime_C:OpenSelfFunc()
  self:PlayAnimation(self.FadeIn)
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Pet_RecoveryTime_C:OnLeaveBattle()
  self:Cancel()
end

return UMG_Pet_RecoveryTime_C

local StarChainModuleEvent = require("NewRoco.Modules.System.StarChain.StarChainModuleEvent")
local StarChainEnum = require("NewRoco.Modules.System.StarChain.StarChainEnum")
local UMG_StarChainAward_C = _G.NRCPanelBase:Extend("UMG_StarChainAward_C")

function UMG_StarChainAward_C:OnConstruct()
  UE4Helper.SetDesiredShowCursor(true, "UMG_StarChainAward_C")
  self:SetChildViews(self.PopUp4)
end

function UMG_StarChainAward_C:OnActive()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1291, "UMG_StarChainAward_C:OnActive")
  self:LoadAnimation(0)
  self:SetCommonPopUpInfo(self.PopUp4)
  self:SetBtnInfo()
  self:SetListInfo()
  self:SetPanelInfo()
  self:OnAddEventListener()
end

function UMG_StarChainAward_C:OnDeactive()
  UE4Helper.ReleaseDesiredShowCursor("UMG_StarChainAward_C")
  self:OnRemoveEventListener()
  self.module:DispatchEvent(StarChainModuleEvent.EnterPanelClosed, self.Ret_Param, self.IsReplenish)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function UMG_StarChainAward_C:OnAddEventListener()
  self.PopUp4.Btn_Right.btnLevelUp.OnPressed:Add(self, self.OnBtnPressed)
  self.PopUp4.Btn_Right.btnLevelUp.OnReleased:Add(self, self.OnBtnReleased)
  self:RegisterEvent(self, StarChainModuleEvent.Tips_PlayerDataChange, self.UpdatePanelInfo)
  NRCEventCenter:RegisterEvent("UMG_StarChainAward_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function UMG_StarChainAward_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnClickClose
  CommonPopUpData.Btn_RightHandler = self.OnBtnClickConfirm
  CommonPopUpData.ClosePanelHandler = self.OnBtnClickClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_StarChainAward_C:OnReconnect()
  self:SetPanelInfo()
end

function UMG_StarChainAward_C:UpdatePanelInfo()
  self:SetListInfo()
  self:SetPanelInfo(true)
end

function UMG_StarChainAward_C:SetPanelInfo(_IsBPlaySound)
  self.id = _G.NRCModuleManager:DoCmd(StarChainModuleCmd.GetCurrentAwardId)
  self.VItemCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(Enum.VisualItem.VI_STAR)
  self.StarAwardConf = _G.DataConfigManager:GetStarAwardConf(self.id)
  local TextInfo = string.format("%s%s", self.StarAwardConf.text_1, self.StarAwardConf.text_2)
  self.PopUp4:SetTitleTextInfo(self.StarAwardConf.title)
  self.ContentText:SetText(TextInfo)
  local vItemsConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
  local useLegendaryCoinNum = self.StarAwardConf.star_amount
  self.PopUp4:SetRightBtnIconInfo(vItemsConf.bigIcon, useLegendaryCoinNum)
  local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local stamina = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StaminaProportion = string.format("%s%s%s", StarNum, "/", stamina.num)
  local touchLimitData = self:GetTouchLimitData()
  self.MoneyBtn2_1:SetInfo(_G.Enum.VisualItem.VI_STAR, StaminaProportion, true, touchLimitData)
  local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
  StarDebrisNum = StarDebrisNum or 0
  local staminaA = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit")
  local StaminaProportionA = ""
  if StarDebrisNum == staminaA.num then
    self.MoneyBtn2.SumNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FFC65FFF"))
    StaminaProportionA = string.format(LuaText.star_chain_module_text_1, staminaA.num)
  elseif StarDebrisNum >= 0 then
    StaminaProportionA = string.format("%s", StarDebrisNum)
  end
  self.MoneyBtn2:SetInfo(_G.Enum.VisualItem.VI_STAR_DEBRIS, StaminaProportionA, true, touchLimitData)
  self.Switcher:SetActiveWidgetIndex(1)
  local rewardsTable = self:SetRewards(self.IconListData, _IsBPlaySound)
  self.IconList:InitGridView(rewardsTable)
  local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
  local CostStar = self.StarAwardConf.star_amount
  if StarDebrisNum >= CostStar and StarNum >= CostStar then
    self.IconList:SelectItemByIndex(0)
  elseif StarDebrisNum < CostStar and StarNum >= CostStar then
    self.IconList:SelectItemByIndex(0)
  elseif StarDebrisNum >= CostStar and StarNum < CostStar then
    self.IconList:SelectItemByIndex(1)
  elseif StarDebrisNum < CostStar and StarNum < CostStar then
    self.IconList:SelectItemByIndex(0)
  end
end

function UMG_StarChainAward_C:RefreshConfirmation(recoveryItemType, _data)
  if _data then
    local Num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(recoveryItemType)
    local CostStar = self.StarAwardConf.star_amount
    if Num >= CostStar then
      self.PopUp4.Btn_Right.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE0FF"))
    else
      self.PopUp4.Btn_Right.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#af3d3eff"))
    end
  end
  if recoveryItemType == _G.Enum.VisualItem.VI_STAR then
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
    local useLegendaryCoinNum = self.StarAwardConf.star_amount
    self.PopUp4:SetRightBtnIconInfo(vItemsConf.bigIcon, useLegendaryCoinNum)
    local Text = _G.DataConfigManager:GetLocalizationConf("staraward_exchange").msg
    self.PopUp4:SetDescInfo(Text)
  elseif recoveryItemType == _G.Enum.VisualItem.VI_STAR_DEBRIS then
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR_DEBRIS)
    local useLegendaryCoinNum = self.StarAwardConf.star_amount
    self.PopUp4:SetRightBtnIconInfo(vItemsConf.bigIcon, useLegendaryCoinNum)
    local Text = _G.DataConfigManager:GetLocalizationConf("staraward_exchange_2").msg
    self.PopUp4:SetDescInfo(Text)
  end
  if not _data.IsBPlaySound then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_StarChainAward_C:RefreshConfirmation")
  end
  self:SetPlaySound()
end

function UMG_StarChainAward_C:SetPlaySound()
  local Count = self.IconList:GetItemCount()
  for i = 1, Count do
    local Item = self.IconList:GetItemByIndex(i - 1)
    if Item then
      Item:SetPlaySound(false)
    end
  end
end

function UMG_StarChainAward_C:SetListInfo()
  self.IconListData = {}
  self.ItemId_1 = Enum.VisualItem.VI_STAR_DEBRIS
  self.ItemId_2 = Enum.VisualItem.VI_STAR
  self.ItemNum_1 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(self.ItemId_1)
  self.ItemNum_2 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(self.ItemId_2)
  self.itemType1 = _G.Enum.GoodsType.GT_VITEM
  self.itemType2 = _G.Enum.GoodsType.GT_VITEM
  local id = _G.NRCModuleManager:DoCmd(StarChainModuleCmd.GetCurrentAwardId)
  local CostStar = _G.DataConfigManager:GetStarAwardConf(id).star_amount
  table.insert(self.IconListData, {
    ItemId = self.ItemId_2,
    ItemNum = self.ItemNum_2,
    itemType = self.itemType2,
    ConsumeNum = CostStar
  })
  if CostStar <= self.ItemNum_1 then
    table.insert(self.IconListData, {
      ItemId = self.ItemId_1,
      ItemNum = self.ItemNum_1,
      itemType = self.itemType1,
      ConsumeNum = CostStar
    })
  end
end

function UMG_StarChainAward_C:SetRewards(itemInfo, _IsBPlaySound)
  local rewardsTable = {}
  for k, v in ipairs(itemInfo) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.itemType
    rewards.itemId = v.ItemId
    rewards.itemNum = v.ItemNum
    rewards.bShowNum = true
    rewards.bShowTip = true
    rewards.IsDoCmd = true
    rewards.bSelectItem = true
    rewards.touchLimitData = self:GetTouchLimitData()
    if v.ItemId == Enum.VisualItem.VI_STAR_DEBRIS and v.ItemNum < v.ConsumeNum then
      rewards.IsCanClick = false
    end
    rewards.IsBPlaySound = _IsBPlaySound
    table.insert(rewardsTable, rewards)
  end
  return rewardsTable
end

function UMG_StarChainAward_C:OnRemoveEventListener()
  self:RemoveAllButtonListener()
end

function UMG_StarChainAward_C:OnBtnClickClose()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "UMG_StarChainAward").CANCEL
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "StarChain", "UMG_StarChainAward", touchReasonType)
  self.Ret_Param = "0"
  self.IsReplenish = false
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1006, "UMG_StarChainAward_C:OnBtnClickClose")
  self:LoadAnimation(2)
end

function UMG_StarChainAward_C:OnBtnClickConfirm()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "UMG_StarChainAward").CONFIRM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "StarChain", "UMG_StarChainAward", touchReasonType)
  local selectRecoveryItemType = _G.NRCModeManager:DoCmd(BattleUIModuleCmd.GetSelectRecoveryItem)
  if selectRecoveryItemType == _G.Enum.VisualItem.VI_STAR_DEBRIS then
    local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
    if StarDebrisNum < self.StarAwardConf.star_amount then
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "StarChain", "UMG_StarChainAward", touchReasonType)
      local touchLimitData = self:GetTouchLimitData()
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenStarDebrisRecoveryTime, false, StarChainEnum.OpenType.Common, nil, _G.Enum.VisualItem.VI_STAR_DEBRIS, touchLimitData)
      self:ShowOrHideMoneyBtn(true)
      return
    end
  elseif selectRecoveryItemType == _G.Enum.VisualItem.VI_STAR and self.VItemCount < self.StarAwardConf.star_amount then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "StarChain", "UMG_StarChainAward", touchReasonType)
    local touchLimitData = self:GetTouchLimitData()
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime, false, StarChainEnum.OpenType.Common, nil, touchLimitData)
    self:ShowOrHideMoneyBtn(true)
    return
  end
  self.Ret_Param = tostring(selectRecoveryItemType)
  self.IsReplenish = false
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_StarChainAward_C:OnBtnClickConfirm")
  self:LoadAnimation(2)
end

function UMG_StarChainAward_C:ShowOrHideMoneyBtn(bIsHide)
  if bIsHide then
    self.bIsHideMoneyBtn = true
    self:LoadAnimation(2)
  else
    self:Enable()
  end
end

function UMG_StarChainAward_C:OnEnable()
  self:LoadAnimation(0)
end

function UMG_StarChainAward_C:OnBtnPressed()
  self:StopAnimation(self.Btn_up)
  self:PlayAnimation(self.Btn_Press)
end

function UMG_StarChainAward_C:OnBtnReleased()
  self:StopAnimation(self.Btn_Press)
  self:PlayAnimation(self.Btn_up)
end

function UMG_StarChainAward_C:OnBtnClickReplenish()
  _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime)
end

function UMG_StarChainAward_C:SetBtnInfo()
  self.PopUp4:SetBtnLeftText(LuaText.umg_starchainaward_1)
  self.PopUp4:SetBtnRightText(LuaText.umg_starchainaward_2)
end

function UMG_StarChainAward_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if not self.bIsHideMoneyBtn then
      local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "UMG_StarChainAward").CANCEL
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "StarChain", "UMG_StarChainAward", touchReasonType1)
      local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "UMG_StarChainAward").CONFIRM
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "StarChain", "UMG_StarChainAward", touchReasonType2)
      self:DoClose()
    else
      self.bIsHideMoneyBtn = false
      self:Disable()
    end
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_StarChainAward_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "StarChain", "UMG_StarChainAward")
end

function UMG_StarChainAward_C:GetTouchLimitData()
  return {
    module = "StarChain",
    panel = "UMG_StarChainAward"
  }
end

return UMG_StarChainAward_C

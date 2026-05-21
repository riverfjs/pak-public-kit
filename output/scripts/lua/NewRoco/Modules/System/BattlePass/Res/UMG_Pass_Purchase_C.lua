local PayModuleEvent = reload("NewRoco.Modules.System.ChargePay.PayModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Pass_Purchase_C = _G.NRCPanelBase:Extend("UMG_Pass_Purchase_C")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local GiftType = {
  MAIN = "main",
  COUPLE = "couple",
  SUB = "sub",
  UNKNOWN = "unknown"
}

function UMG_Pass_Purchase_C:OnActive()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReqBattlePassShopData)
  if _G.GlobalConfig.DebugOpenUI then
    self:OnAddEventListener()
    self.SpineWidget_Blue:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SpineWidget_Pink:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SpineWidget_Pink:ClearTrack(0)
    self.SpineWidget_Blue:SetAnimation(0, "Idle", true)
    self:OnSwitcherSwitcher_bg(1)
    return
  end
  self:InitBtn()
  self:InitUIData()
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.gender = player.gender
  self.NORMAL_GRADE = 68
  self.COLLECTION_GRADE = 128
  self:OnAddEventListener()
  self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  self.NRCSwitcher:SetActiveWidgetIndex(0)
  self.NRCSwitcher_2:SetActiveWidgetIndex(0)
  self:InitSpineWidget()
  _G.NRCAudioManager:PlaySound2DAuto(1220002005, "UMG_Pass_Purchase_C:OnActive")
  self:ShowPanel(true)
  self:UnlockIsSelectBtn()
  self:BindInputAction()
  self.CurIsUpdateStateAim = false
  self.disableTimer = _G.TimerManager:CreateTimer(self, "UMG_Pass_Purchase_C:OnUpdateDisableTime", math.maxinteger, self.OnUpdateDisableTime, nil, 1)
  self:OnUpdateDisableTime()
end

function UMG_Pass_Purchase_C:InitSpineWidget()
  self.module:InitSpineWidgetForPanel(self, "BattlePurchasePanel", "UMG_Pass_Purchase")
end

function UMG_Pass_Purchase_C:OnUpdateDisableTime()
  self:OnRefreshBtns(_G.Enum.BattlePassGiftGrade.BPGG_NORMAL)
  if self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    self:OnRefreshBtns(_G.Enum.BattlePassGiftGrade.BPGG_SPREAD)
  else
    self:OnRefreshBtns(_G.Enum.BattlePassGiftGrade.BPGG_COLLECTION)
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.DoDeactiveBattlepass)
end

function UMG_Pass_Purchase_C:OnRefreshBtns(giftGrade)
  Log.Info("UMG_Pass_Purchase_C:InitGiftSection giftGrade", giftGrade, self.passConf.id, self.theme_id, self.gender)
  local _, selectGiftConf = self.module.data:GetBattlePassGiftData(self.passConf.id, self.theme_id, giftGrade, self.gender)
  if not selectGiftConf then
    return
  end
  Log.Info("selectGiftConf", selectGiftConf.id)
  self:SetCoupleGoodsInfo(selectGiftConf, giftGrade)
  self:SetSingleBtn(selectGiftConf, giftGrade)
  self:SetCoupleBtn(selectGiftConf, giftGrade)
end

function UMG_Pass_Purchase_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.OnUnlockPassSuccess, self.OnSucceLock)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnEndOfCollection)
  _G.NRCSDKManager:RemoveEventListener(self, PayModuleEvent.MidasPaySuccess, self.OnRecharge)
  _G.NRCSDKManager:RemoveEventListener(self, PayModuleEvent.MidasPayFailed, self.OnNotRecharge)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.OnDirectPurchase, self.OnDirectPurchase)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, true)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.RefreshBagInfo, self.OnRefreshBagInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GlobalRefreshBagInfo, self.OnGlobalRefreshBagInfo)
  self:UnBindInputAction()
  if not self.module:HasPanel("BattlePassAwardMain") then
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(_G.Enum.MusicApplyType.MAT_UI, _G.Enum.InterfaceType.IT_BP, self.module.ActivityPassBgmState)
  end
  if self.disableTimer then
    _G.TimerManager:RemoveTimer(self.disableTimer)
    self.disableTimer = nil
  end
end

function UMG_Pass_Purchase_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_SubClosePanel")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseSubPanel")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_Pass_Purchase_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseSubPanel")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_SubClosePanel")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_Pass_Purchase_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  local battleThemConf = _G.DataConfigManager:GetBattlePassThemeConf(self.theme_id)
  if nil == battleThemConf then
    Log.Error("UMG_Pass_Purchase_C:SetCommonTitle battleThemConf is nil", self.theme_id)
    return
  end
  if self.Title1 then
    self.Title1:Set_MainTitle(battleThemConf.theme_name)
    self.Title1:SetBg(self.titleConf.head_icon)
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
  if self.Title1_1 then
    self.Title1_1:Set_MainTitle(battleThemConf.theme_name)
    self.Title1_1:SetBg(self.titleConf.head_icon)
    self.Title1_1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
end

function UMG_Pass_Purchase_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnClickbackBtn()
end

function UMG_Pass_Purchase_C:OnAddEventListener()
  self:AddButtonListener(self.Department, self.OnDepartmentClick)
  self:AddButtonListener(self.UMG_Details.btnLevelUp, self.OnOpenPetPanel)
  self:AddButtonListener(self.backBtn.btnClose, self.OnClickbackBtn)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnOpenTips)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Purchase_C", self, BattlePassModuleEvent.OnUnlockPassSuccess, self.OnSucceLock)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Purchase_C", self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnEndOfCollection)
  _G.NRCSDKManager:AddEventListener(self, PayModuleEvent.MidasPaySuccess, self.OnRecharge)
  _G.NRCSDKManager:AddEventListener(self, PayModuleEvent.MidasPayFailed, self.OnNotRecharge)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Purchase_C", self, BattlePassModuleEvent.OnDirectPurchase, self.OnDirectPurchase)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Purchase_C", self, BagModuleEvent.RefreshBagInfo, self.OnRefreshBagInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Purchase_C", self, BagModuleEvent.GlobalRefreshBagInfo, self.OnGlobalRefreshBagInfo)
end

function UMG_Pass_Purchase_C:ShowPanel(isUpdateStateAim)
  UIUtils.SafeSetVisibility(self.List2, UE4.ESlateVisibility.Visible)
  UIUtils.SafeSetVisibility(self.List3, UE4.ESlateVisibility.Visible)
  UIUtils.SafeSetVisibility(self.List1_1, UE4.ESlateVisibility.Collapsed, true)
  UIUtils.SafeSetVisibility(self.List1_2, UE4.ESlateVisibility.Collapsed, true)
  self.CurIsUpdateStateAim = isUpdateStateAim or false
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self.passConf = _G.DataConfigManager:GetBattlePassConf(curPassInfo.battle_pass_id)
  self.themeConf = _G.DataConfigManager:GetBattlePassThemeConf(curPassInfo.theme_id)
  self.theme_id = curPassInfo.theme_id
  self:InitPanel()
  local spread_gift_id = 1 == self.gender and self.themeConf.male_spread_gift_id or self.themeConf.female_spread_gift_id
  self.differenceGoodId = self:GetGoodId(spread_gift_id)
  local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_DIAMOND)
  self:SetState(self.curGrade, curPassInfo.battle_pass_id)
  if self.curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_NORMAL then
    if isUpdateStateAim then
      if self.theme_id == self.passConf.theme_id[1] then
        self:PlayAnimation(self.Receive_Red_1)
      else
        self:PlayAnimation(self.Receive_Blue_1)
      end
    end
  else
    if (self.curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_COLLECTION or self.curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_SPREAD) and isUpdateStateAim and self.curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_COLLECTION then
      if self.theme_id == self.passConf.theme_id[2] then
        self:PlayAnimation(self.Receive_Red_2)
      else
        self:PlayAnimation(self.Receive_Blue_2)
      end
    else
    end
  end
  self.NRCText_73:SetText(_G.DataConfigManager:GetLocalizationConf("battlepass_package_des01").msg)
  self:ShowPetName()
  self:SetThemeRes()
  self:SetCommonTitle()
end

function UMG_Pass_Purchase_C:OnEndOfCollection()
  self:ShowPanel(true)
  self:OnUpdateDisableTime()
end

function UMG_Pass_Purchase_C:SetThemeRes()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_Purchase", self)
  local isThemeA = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.IsThemeA, self.theme_id)
  if isThemeA then
    self.SpineWidget_Blue:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SpineWidget_Pink:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SpineWidget_Pink:ClearTrack(0)
    self.SpineWidget_Blue:SetAnimation(0, "Idle", true)
    self:OnSwitcherSwitcher_bg(1)
  else
    self.SpineWidget_Blue:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SpineWidget_Pink:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.SpineWidget_Blue:ClearTrack(0)
    self.SpineWidget_Pink:SetAnimation(0, "Idle", true)
    self.SpineWidget_Pink:SetScaleX(-1)
    self:OnSwitcherSwitcher_bg(0)
  end
end

function UMG_Pass_Purchase_C:SetState(grade, pass_id)
  local isClose = self:DisablePass(pass_id)
end

function UMG_Pass_Purchase_C:DisablePass(pass_id)
  local countdownTime = _G.DataConfigManager:GetPaymentGlobalConfig("BP_close_protect").num * 3600
  local closeTime = _G.DataConfigManager:GetBattlePassConf(pass_id).close_time
  local passOverTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, closeTime)
  local curTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurServerTime)
  local overTime = passOverTime - curTime
  Log.Info("\231\187\147\230\157\159\230\151\182\233\151\180", passOverTime, countdownTime)
  return countdownTime >= overTime
end

function UMG_Pass_Purchase_C:ShowPetName()
  if not self.themeConf then
    Log.Error("UMG_Pass_Purchase_C:ShowPetName   themeConf is nil")
    return
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.themeConf.theme_petbase_id)
  self.textPetName:SetText(petBaseConf.name)
  self:ShowTypeIcons(petBaseConf)
end

function UMG_Pass_Purchase_C:ShowTypeIcons(petBaseConf)
  local unit_type = petBaseConf.unit_type
  self.Attr:InitGridView(ActivityUtils.CreatePetCommonAttrListData(unit_type))
end

function UMG_Pass_Purchase_C:GetGoodId(giftId)
  local giftConf = _G.DataConfigManager:GetBattlePassGiftConf(giftId)
  if giftConf then
    return giftConf.gift_goods_id
  end
  return nil
end

function UMG_Pass_Purchase_C:OnSucceLock(goodShopId)
  self.module.IsOpenBattlePurchasePanel = false
  self:DoClose()
end

function UMG_Pass_Purchase_C:OnAnimFinished(anim)
  if anim == self.Out then
    self.module.IsOpenBattlePurchasePanel = false
  end
end

function UMG_Pass_Purchase_C:OnClickAddMoneyBtn()
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenTopUpShop)
end

function UMG_Pass_Purchase_C:OnOpenPetPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Pass_Select_C:OnOpenStartPetPanel")
  local petId = self.themeConf.theme_petbase_id
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petId, true)
end

function UMG_Pass_Purchase_C:OnSwitcherSwitcher_bg(SwitcherIndex)
  self.Switcher_bg:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Pass_Purchase_C:OnClickShowStarChainTimeBtn()
  _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, 3, _G.Enum.GoodsType.GT_VITEM, false)
end

function UMG_Pass_Purchase_C:OnClickbackBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_Pass_Purchase_C:OnClickbackBtn")
  self:OnClose()
end

function UMG_Pass_Purchase_C:OnOpenTips()
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_Pass_Select_C:OnOpenTips")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = "\230\180\187\229\138\168\232\175\180\230\152\142"
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  local rule_tips_id = _G.DataConfigManager:GetBattlePassConf(BattlePassInfo.battle_pass_id).rule_tips_id
  local Content = _G.DataConfigManager:GetLocalizationConf(rule_tips_id).msg
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Pass_Purchase_C:OnBuyGoods(goodsShopId, Callback)
  self.CurIsUpdateStateAim = false
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(goodsShopId)
  if goodsConf then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.BuyLevelReq, goodsShopId, 1, self, Callback)
  end
  Log.Info("\229\143\145\233\128\129\232\180\173\228\185\176\229\141\143\232\174\174\239\188\140id\228\184\186", goodsShopId)
end

function UMG_Pass_Purchase_C:OnTick(deltaTime)
  if self.SpineWidget_Pink then
    self.SpineWidget_Pink:Tick(deltaTime, false)
  end
  if self.SpineWidget_Blue then
    self.SpineWidget_Blue:Tick(deltaTime, false)
  end
end

function UMG_Pass_Purchase_C:OnRecharge()
  Log.Error("\230\148\182\229\136\176\230\148\175\228\187\152\230\136\144\229\138\159\231\154\132\233\128\154\231\159\165\231\173\137\229\190\133\229\155\158\229\140\133\239\188\140\229\166\130\230\158\156\230\148\182\228\184\141\229\136\176\229\155\158\229\140\1333s\229\144\142\232\135\170\229\138\168\229\136\183\230\150\176\231\149\140\233\157\162")
  self:DelaySeconds(3, function()
    if self.CurIsUpdateStateAim == false then
      Log.Error("\229\136\183\230\150\176bp\228\191\161\230\129\175")
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo)
    end
  end)
end

function UMG_Pass_Purchase_C:OnNotRecharge()
  Log.Error("\230\148\182\229\136\176\230\148\175\228\187\152\229\164\177\232\180\165\231\154\132\233\128\154\231\159\165\231\173\137\229\190\133\229\155\158\229\140\133\239\188\140\229\166\130\230\158\156\230\148\182\228\184\141\229\136\176\229\155\158\229\140\1333s\229\144\142\232\135\170\229\138\168\229\136\183\230\150\176\231\149\140\233\157\162")
  self:DelaySeconds(3, function()
    if self.CurIsUpdateStateAim == false then
      Log.Error("\229\136\183\230\150\176bp\228\191\161\230\129\175")
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo)
    end
  end)
end

function UMG_Pass_Purchase_C:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").UNLOCK)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TICKET)
end

function UMG_Pass_Purchase_C:InitPanel()
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self.curGrade = curPassInfo.battle_pass_brief_info.gift_grade
  if self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_FREE then
    self:InitGiftSection(_G.Enum.BattlePassGiftGrade.BPGG_NORMAL)
    self:InitGiftSection(_G.Enum.BattlePassGiftGrade.BPGG_COLLECTION)
  elseif self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    self:InitGiftSection(_G.Enum.BattlePassGiftGrade.BPGG_NORMAL)
    self:InitGiftSection(_G.Enum.BattlePassGiftGrade.BPGG_SPREAD)
  elseif self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
    self:InitGiftSection(_G.Enum.BattlePassGiftGrade.BPGG_NORMAL)
    self:InitGiftSection(_G.Enum.BattlePassGiftGrade.BPGG_COLLECTION)
  end
  self:InitRewardList()
  self.Btn_ArrowR:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ArrowL:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pass_Purchase_C:InitGiftSection(giftGrade)
  Log.Info("UMG_Pass_Purchase_C:InitGiftSection giftGrade", giftGrade, self.passConf.id, self.theme_id, self.gender)
  local giftDataList, selectGiftConf = self.module.data:GetBattlePassGiftData(self.passConf.id, self.theme_id, giftGrade, self.gender)
  if not selectGiftConf then
    return
  end
  Log.Info("selectGiftConf", selectGiftConf.id)
  local gridView = giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL and self.List2 or self.List3
  gridView:InitGridView(giftDataList)
  self:SetCoupleGoodsInfo(selectGiftConf, giftGrade)
  self:SetSingleBtn(selectGiftConf, giftGrade)
  self:SetCoupleBtn(selectGiftConf, giftGrade)
end

function UMG_Pass_Purchase_C:SetCoupleBtn(giftConf, giftGrade)
  local gift_goods_couple_id = giftConf.gift_goods_couple_id or 0
  local goodsCoupleConf = _G.DataConfigManager:GetNormalShopConf(gift_goods_couple_id)
  if nil == goodsCoupleConf then
    Log.Error("goodsCoupleConf is nil id is ", gift_goods_couple_id)
    return
  end
  local subItemIds = self.module.data:GetSubCouponItemIdsWithGoodsConf(goodsCoupleConf)
  local gift_goods_sub_id = giftConf.gift_goods_sub_id or 0
  local goodsSubConf = _G.DataConfigManager:GetNormalShopConf(gift_goods_sub_id)
  if nil == goodsSubConf then
    Log.Error("goodsSubConf is nil id is ", gift_goods_sub_id)
    return
  end
  local itemIds = self.module.data:GetSubCouponItemIdsWithGoodsConf(goodsSubConf)
  for _, subItemId in ipairs(subItemIds) do
    table.insert(itemIds, subItemId)
  end
  local hasBought = false
  local CurPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if CurPassInfo and CurPassInfo.bought_gift_sub_bag_item_ids then
    for _, itemId in ipairs(itemIds) do
      for _, boughtItemId in ipairs(CurPassInfo.bought_gift_sub_bag_item_ids) do
        if itemId == boughtItemId then
          hasBought = true
          Log.Info("UMG_Pass_Purchase_C hasBought", itemId)
          break
        end
      end
    end
  end
  local ownSubCouponItemID = 0
  for _, itemId in ipairs(itemIds) do
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, itemId)
    if bagItem and bagItem.num and bagItem.num > 0 then
      ownSubCouponItemID = itemId
      break
    end
  end
  if giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    self.ownNormalSubCouponItemID = ownSubCouponItemID
  elseif giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
    self.ownCollectionSubCouponItemID = ownSubCouponItemID
  end
  if hasBought then
    if giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
      if self.ownNormalSubCouponItemID and self.ownNormalSubCouponItemID > 0 then
        self.NRCSwitcher_0:SetActiveWidgetIndex(2)
      else
        self.NRCSwitcher_0:SetActiveWidgetIndex(1)
      end
    elseif giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
      if self.ownCollectionSubCouponItemID and self.ownCollectionSubCouponItemID > 0 then
        self.NRCSwitcher_2:SetActiveWidgetIndex(2)
      else
        self.NRCSwitcher_2:SetActiveWidgetIndex(1)
      end
    end
  else
    local _, isDisable = self:GetGoodsPrice(goodsSubConf)
    local targetIndex = isDisable and 1 or 0
    if giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
      self.NRCSwitcher_0:SetActiveWidgetIndex(targetIndex)
      if isDisable then
        self.Btn2_1.Title_1:SetText(LuaText.button_goods_expired)
      end
    elseif giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION or giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_SPREAD then
      self.NRCSwitcher_2:SetActiveWidgetIndex(targetIndex)
      if isDisable then
        self.Btn2_3.Title_1:SetText(LuaText.button_goods_expired)
      end
    end
  end
  self:SetDoubleCorner(giftGrade, hasBought)
end

function UMG_Pass_Purchase_C:SetDoubleCorner(giftGrade, hasBought)
  if hasBought then
    if giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
      UIUtils.SafeSetVisibility(self.CornerMarker4, UE4.ESlateVisibility.Collapsed)
    elseif giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
      UIUtils.SafeSetVisibility(self.CornerMarker1, UE4.ESlateVisibility.Collapsed)
    end
  elseif giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    UIUtils.SafeSetVisibility(self.CornerMarker4, UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.curGrade >= _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
      UIUtils.SafeSetText(self.CornerMarkerText_3, LuaText.bp_umg_text02)
    else
      UIUtils.SafeSetText(self.CornerMarkerText_3, LuaText.bp_umg_text01)
    end
  elseif giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION or giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_SPREAD then
    UIUtils.SafeSetVisibility(self.CornerMarker1, UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
      UIUtils.SafeSetText(self.CornerMarkerText, LuaText.bp_umg_text02)
    else
      UIUtils.SafeSetText(self.CornerMarkerText, LuaText.bp_umg_text01)
    end
  end
end

function UMG_Pass_Purchase_C:InitRewardList()
  if self.passConf == nil then
    Log.Error("passConf is nil id is ", self.passConf.id, self.theme_id, self.gender)
    return
  end
  local _, selectGiftConf = self.module.data:GetBattlePassGiftData(self.passConf.id, self.theme_id, _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION, self.gender)
  if not selectGiftConf then
    Log.Error("selectGiftConf is nil id is ", self.passConf.id, self.theme_id, self.gender)
    return
  end
  local gift_rewards_id = selectGiftConf.gift_rewards_id
  local rewardConf = _G.DataConfigManager:GetRewardConf(gift_rewards_id)
  local bp_level = 0
  local RewardList = {}
  if rewardConf then
    for _, rewardItem in ipairs(rewardConf.RewardItem) do
      local itemData = {
        itemType = rewardItem.type,
        itemId = rewardItem.id,
        itemNum = rewardItem.count,
        bShowTip = true,
        IsCanClick = true,
        bShowNum = true,
        numTextHexColor = "FFC65FFF"
      }
      if rewardItem.type == _G.Enum.GoodsType.GT_VITEM then
        if rewardItem.id == _G.Enum.VisualItem.VI_BP_LEVEL then
          bp_level = rewardItem.count
        else
          table.insert(RewardList, itemData)
        end
      else
        table.insert(RewardList, itemData)
      end
    end
    self.NRCText_97:SetText(bp_level)
    self.List1:InitGridView(RewardList)
  end
end

function UMG_Pass_Purchase_C:SetCoupleGoodsInfo(giftConf, giftGrade)
  local gift_goods_id = giftConf.gift_goods_id or 0
  local gift_goods_couple_id = giftConf.gift_goods_couple_id or 0
  if self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL and giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    gift_goods_couple_id = giftConf.gift_goods_sub_id or 0
  elseif self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL and giftGrade == _G.Enum.BattlePassGiftGrade.BPGG_SPREAD then
    gift_goods_couple_id = giftConf.gift_goods_couple_id or 0
  elseif self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
    gift_goods_couple_id = giftConf.gift_goods_sub_id
  end
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(gift_goods_id)
  if nil == goodsConf then
    Log.Error("goodsShopConf is nil id is ", gift_goods_id)
    return
  end
  local goodsCoupleConf = _G.DataConfigManager:GetNormalShopConf(gift_goods_couple_id)
  if nil == goodsCoupleConf then
    Log.Error("goodsCoupleShopConf is nil id is ", gift_goods_couple_id)
    return
  end
  if giftConf.bp_grade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    self.RechargeNormalGoodsID = gift_goods_id
    self.NormalGiftItemMainID = giftConf.gift_item_main_id
    self.ReChargeNormalGoodsSubID = giftConf.gift_goods_sub_id
    self.RechargeNormalSideGoodsID = gift_goods_couple_id
    self.giftConfMap[gift_goods_id] = giftConf
    self.giftConfMap[gift_goods_couple_id] = giftConf
    self:SetNormalGradeUI(goodsCoupleConf)
  elseif giftConf.bp_grade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION or giftConf.bp_grade == _G.Enum.BattlePassGiftGrade.BPGG_SPREAD then
    self.RechargeCollectionGoodsID = gift_goods_id
    self.CollectionGiftItemMainID = giftConf.gift_item_main_id
    self.ReChargeCollectionGoodsSubID = giftConf.gift_goods_sub_id
    self.RechargeCollectionSideGoodsID = gift_goods_couple_id
    self.giftConfMap[gift_goods_id] = giftConf
    self.giftConfMap[gift_goods_couple_id] = giftConf
    self:SetCollectionGradeUI(goodsCoupleConf)
  end
end

function UMG_Pass_Purchase_C:GetGoodsPrice(goodsConf)
  local price = goodsConf.origin_price
  local isDisable = true
  local goodsSevData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, goodsConf.shop_id, goodsConf.id, true)
  if goodsSevData then
    price = goodsSevData.real_price.num
    if goodsSevData.disable_time and goodsSevData.disable_time > 0 then
      local severTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
      if severTime >= goodsSevData.disable_time then
        isDisable = true
      else
        isDisable = false
      end
    end
  end
  return price, isDisable
end

function UMG_Pass_Purchase_C:SetNormalGradeUI(goodsCoupleConf)
  local price, isDisable = self:GetGoodsPrice(goodsCoupleConf)
  if goodsCoupleConf then
    local Text = string.format("\239\191\165%d", price)
    local RichText = string.format("<span size=\"36\">%s</>", Text)
    self.Btn.Title_1:SetText(RichText)
    local itemData = {
      itemType = goodsCoupleConf.Type,
      itemId = goodsCoupleConf.item_id,
      bShowNum = true,
      bShowTip = true,
      IsCanClick = true,
      IsBPlaySound = true
    }
    self.ContractGiftItem1:SetItemInfo(itemData)
  end
end

function UMG_Pass_Purchase_C:SetCollectionGradeUI(goodsCoupleConf)
  local price = self:GetGoodsPrice(goodsCoupleConf)
  if goodsCoupleConf then
    local Text = string.format("\239\191\165%d", price)
    local RichText = string.format("<span size=\"36\">%s</>", Text)
    self.Btn_1.Title_1:SetText(RichText)
    local itemData = {
      itemType = goodsCoupleConf.Type,
      itemId = goodsCoupleConf.item_id,
      bShowNum = true,
      bShowTip = true,
      IsCanClick = true,
      IsBPlaySound = true
    }
    self.ContractGiftItem2:SetItemInfo(itemData)
  end
end

function UMG_Pass_Purchase_C:SetSingleBtn(giftConf, fixGrade)
  local bagItemNum = 0
  local NumText = ""
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(giftConf.gift_goods_id)
  if goodsConf and goodsConf then
    if fixGrade == _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
      if 0 ~= self.NormalGiftItemMainID then
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.NormalGiftItemMainID)
        bagItemNum = bagItem and bagItem.num or 0
        if bagItem then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItem.id)
          if bagItemConf then
            self.Icon:SetPath(bagItemConf.icon)
          end
        end
      end
      self.NormalSideBagItemNum = bagItemNum
      NumText = string.format("%d/1", bagItemNum)
      self:SetNormalGradeButton(bagItemNum, NumText, goodsConf)
    elseif fixGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION or fixGrade == _G.Enum.BattlePassGiftGrade.BPGG_SPREAD then
      if 0 ~= self.CollectionGiftItemMainID and self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_FREE then
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.CollectionGiftItemMainID)
        bagItemNum = bagItem and bagItem.num or 0
        if bagItem then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItem.id)
          if bagItemConf then
            self.Icon2:SetPath(bagItemConf.icon)
          end
        end
      end
      self.CollectionSideBagItemNum = bagItemNum
      NumText = string.format("%d/1", bagItemNum)
      self:SetCollectionGradeButton(bagItemNum, NumText, goodsConf, fixGrade)
    end
  end
end

function UMG_Pass_Purchase_C:SetNormalGradeButton(bagItemNum, NumText, goodsSubConf)
  UIUtils.SafeSetVisibility(self.CornerMarker3, UE4.ESlateVisibility.Collapsed)
  if self.curGrade >= _G.Enum.BattlePassGiftGrade.BPGG_NORMAL then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
  else
    local price, isDisable = self:GetGoodsPrice(goodsSubConf)
    local targetIndex = 0 == bagItemNum and isDisable and 1 or 0
    self.NRCSwitcher_1:SetActiveWidgetIndex(targetIndex)
    if 0 == bagItemNum then
      NumText = string.format("\239\191\165%d", price)
      if isDisable then
        self.Btn2.Title_1:SetText(LuaText.button_goods_expired)
      end
    end
    if self.Icon then
      self.Icon:SetVisibility(bagItemNum > 0 and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    end
    self.NRCText_7:SetText(NumText)
  end
end

function UMG_Pass_Purchase_C:SetCollectionGradeButton(bagItemNum, NumText, goodsSubConf, fixGrade)
  if self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_COLLECTION then
    self.NRCSwitcher:SetActiveWidgetIndex(1)
    UIUtils.SafeSetVisibility(self.CornerMarker2, UE4.ESlateVisibility.Collapsed)
  else
    UIUtils.SafeSetVisibility(self.CornerMarker2, UE4.ESlateVisibility.Visible)
    if fixGrade == _G.Enum.BattlePassGiftGrade.BPGG_SPREAD then
      UIUtils.SafeSetText(self.CornerMarkerText_1, LuaText.bp_umg_text04)
    else
      UIUtils.SafeSetText(self.CornerMarkerText_1, LuaText.bp_umg_text03)
    end
    local price, isDisable = self:GetGoodsPrice(goodsSubConf)
    local targetIndex = 0 == bagItemNum and isDisable and 1 or 0
    self.NRCSwitcher:SetActiveWidgetIndex(targetIndex)
    if 0 == bagItemNum then
      NumText = string.format("\239\191\165%d", price)
      if isDisable then
        self.Btn2_2.Title_1:SetText(LuaText.button_goods_expired)
      end
    end
    if self.Icon2 then
      self.Icon2:SetVisibility(bagItemNum > 0 and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    end
    self.NRCText_6:SetText(NumText)
  end
end

function UMG_Pass_Purchase_C:InitUIData()
  self.RechargeNormalGoodsID = 0
  self.RechargeNormalSideGoodsID = 0
  self.RechargeCollectionGoodsID = 0
  self.RechargeCollectionSideGoodsID = 0
  self.ReChargeNormalGoodsSubID = 0
  self.ReChargeCollectionGoodsSubID = 0
  self.NormalSideBagItemNum = 0
  self.CollectionSideBagItemNum = 0
  self.NormalGiftItemMainID = 0
  self.CollectionGiftItemMainID = 0
  self.UseBagItemID = 0
  self.UseBagItemReChargeGoodsMap = {}
  self.giftConfMap = {}
end

function UMG_Pass_Purchase_C:InitBtn()
  self:AddButtonListener(self.NRCButton_1, self.OnBuyNormalBtn)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnHasBuyNormalBtn)
  self:AddButtonListener(self.Btn.btnLevelUp, self.OnBuyNormalSideBtn)
  self:AddButtonListener(self.Btn2_1.btnLevelUp, self.OnHasBuyNormalSideBtn)
  self:AddButtonListener(self.Btn_Use1.btnLevelUp, self.OnUseNormalSideBtn)
  self:AddButtonListener(self.NRCButton, self.OnBuyCollectionBtn)
  self:AddButtonListener(self.Btn2_2.btnLevelUp, self.OnHasBuyCollectionBtn)
  self:AddButtonListener(self.Btn_1.btnLevelUp, self.OnBuyCollectionSideBtn)
  self:AddButtonListener(self.Btn2_3.btnLevelUp, self.OnHasBuyCollectionSideBtn)
  self:AddButtonListener(self.Btn_Use2.btnLevelUp, self.OnUseCollectionSideBtn)
  self.NRCButton_1.OnPressed:Add(self, self.OnBuyNormalBtnPressed)
  self.NRCButton_1.OnReleased:Add(self, self.OnBuyNormalBtnReleased)
  self.NRCButton.OnPressed:Add(self, self.OnBuyCollectionBtnPressed)
  self.NRCButton.OnReleased:Add(self, self.OnBuyCollectionBtnReleased)
end

function UMG_Pass_Purchase_C:OnBuyNormalBtnPressed()
  if self.UpBtnPress then
    self:PlayAnimation(self.UpBtnPress)
  end
end

function UMG_Pass_Purchase_C:OnBuyNormalBtnReleased()
  if self.UpBtnUp then
    self:PlayAnimation(self.UpBtnUp)
  end
end

function UMG_Pass_Purchase_C:OnBuyCollectionBtnPressed()
  if self.DownBtnPress then
    self:PlayAnimation(self.DownBtnPress)
  end
end

function UMG_Pass_Purchase_C:OnBuyCollectionBtnReleased()
  if self.DownBtnUp then
    self:PlayAnimation(self.DownBtnUp)
  end
end

function UMG_Pass_Purchase_C:OnBuyNormalBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Pass_Purchase_C:btn")
  self:DoRecharge(self.RechargeNormalGoodsID, self.NormalGiftItemMainID, false)
end

function UMG_Pass_Purchase_C:OnHasBuyNormalBtn()
end

function UMG_Pass_Purchase_C:OnBuyNormalSideBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Pass_Purchase_C:btn")
  self:DoRecharge(self.RechargeNormalSideGoodsID, nil, false)
end

function UMG_Pass_Purchase_C:OnHasBuyNormalSideBtn()
end

function UMG_Pass_Purchase_C:OnUseNormalSideBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Pass_Purchase_C:btn")
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanelByTableIndex, nil, self.ownNormalSubCouponItemID)
end

function UMG_Pass_Purchase_C:OnUseCollectionSideBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Pass_Purchase_C:btn")
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanelByTableIndex, nil, self.ownCollectionSubCouponItemID)
end

function UMG_Pass_Purchase_C:OnBuyCollectionBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Pass_Purchase_C:btn")
  self:DoRecharge(self.RechargeCollectionGoodsID, self.CollectionGiftItemMainID, true)
end

function UMG_Pass_Purchase_C:OnHasBuyCollectionBtn()
end

function UMG_Pass_Purchase_C:OnBuyCollectionSideBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Pass_Purchase_C:btn")
  self:DoRecharge(self.RechargeCollectionSideGoodsID, nil, true)
end

function UMG_Pass_Purchase_C:OnHasBuyCollectionSideBtn()
end

function UMG_Pass_Purchase_C:IsDisablePass()
  local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if nil == curPassInfo then
    Log.Error("UMG_Pass_AwardMain_C:DisablePass curPassInfo is nil")
    return true
  end
  local pass_id = curPassInfo.battle_pass_id
  if nil == pass_id then
    Log.Error("UMG_Pass_AwardMain_C:DisablePass pass_id is nil")
    return true
  end
  local closeTime = _G.DataConfigManager:GetBattlePassConf(pass_id).close_time
  local passOverTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, closeTime)
  local curTime = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurServerTime)
  local overTime = passOverTime - curTime
  Log.Info("UMG_Pass_Purchase_C:DisablePass overTime", overTime, curTime, passOverTime)
  if overTime < 0 then
    return true
  end
  return false
end

function UMG_Pass_Purchase_C:DoRecharge(RechargeGoodsId, GiftItemMainID, isCollection)
  Log.Debug("UMG_Pass_Purchase_C DoRecharge,RechargeGoodsId:", RechargeGoodsId, GiftItemMainID)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local goodsSubConf = _G.DataConfigManager:GetNormalShopConf(RechargeGoodsId)
  if not goodsSubConf then
    return
  end
  local title = _G.DataConfigManager:GetLocalizationConf("bp_gift_purchase_confirm_title").msg
  local DesText = _G.DataConfigManager:GetLocalizationConf("bp_gift_purchase_confirm_text").msg
  local Price = self:GetGoodsPrice(goodsSubConf)
  local des = string.format(DesText, Price, goodsSubConf.goods_name)
  local Context = DialogContext()
  if GiftItemMainID and 0 ~= GiftItemMainID and self.curGrade == _G.Enum.BattlePassGiftGrade.BPGG_FREE then
    self.UseBagItemID = GiftItemMainID
    self.UseBagItemReChargeGoodsMap[self.UseBagItemID] = RechargeGoodsId
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, GiftItemMainID)
    local bagItemNum = bagItem and bagItem.num or 0
    if bagItemNum > 0 and bagItem then
      local confirmText = _G.DataConfigManager:GetLocalizationConf("bp_gift_unlock_confirm_text").msg
      local bagConfig = _G.DataConfigManager:GetBagItemConf(bagItem.id)
      local bagItemName = ""
      if bagConfig then
        bagItemName = bagConfig.name
      end
      local confirmDes = string.format(confirmText, bagItemName, goodsSubConf.goods_name)
      Log.Debug("UMG_Pass_Purchase_C UseBagItem,bagItem:", bagItem.gid, bagItem.num)
      Context:SetTitle(title):SetContent(confirmDes):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, function()
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItem, bagItem.gid, bagItem.id, 1)
      end):SetCloseOnCancel(true):SetButtonText(LuaText.general_confirm, LuaText.general_cancel)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
      return
    end
  end
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.DoPayForItem):SetCloseOnCancel(true):SetButtonText(LuaText.general_confirm, LuaText.general_cancel)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  self.DoPayGoodsId = RechargeGoodsId
end

function UMG_Pass_Purchase_C:DoPayForItem()
  Log.Info("UMG_Pass_Purchase_C:DoPayForItem", self.DoPayGoodsId)
  local isDisablePass = self:IsDisablePass()
  if isDisablePass then
    Log.Info("UMG_Pass_Purchase_C:DoPayForItem isDisablePass")
    local TipsText = LuaText.bp_gift_expired
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, TipsText)
    return
  end
  local goodsConf = _G.DataConfigManager:GetNormalShopConf(self.DoPayGoodsId)
  if goodsConf then
    local shopId = goodsConf.shop_id
    _G.NRCModuleManager:DoCmd(_G.PayModuleCmd.PayForItem, self.DoPayGoodsId, shopId)
  else
    Log.Error("UMG_Pass_Purchase_C:DoPayForItem goodsConf is nil")
  end
end

function UMG_Pass_Purchase_C:OnBuyGoodsCallback(Rsp)
  if nil == Rsp then
    Log.Error("UMG_Pass_Purchase_C:OnBuyGoodsCallback Rsp is nil")
    return
  end
  Log.Info("UMG_Pass_Purchase_C:OnBuyGoodsCallback Rsp", Rsp.ret_info.ret_code)
  if 0 == Rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo)
    local GoodsReward = Rsp.ret_info.goods_reward
    local RewardList = {}
    if GoodsReward then
      for _, reward in ipairs(GoodsReward.rewards) do
        local itemData = {
          type = reward.type,
          id = reward.id,
          num = reward.num
        }
        table.insert(RewardList, itemData)
      end
      Log.Info("UMG_Pass_Purchase_C:OnBuyGoodsCallback RewardList", #RewardList)
      self:OnPurchaseFinish(RewardList)
    end
  end
end

function UMG_Pass_Purchase_C:OnClosePurchaseSuccessfulTips()
  Log.Info("UMG_Pass_Purchase_C:OnClosePurchaseSuccessfulTips")
  if self.GoodsRewardList then
    self:ShowReward(self.GoodsRewardList)
  else
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.CloseBattlePassPurchasePanel)
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel)
  end
end

function UMG_Pass_Purchase_C:ShowReward(rewardList)
  if not rewardList then
    Log.Error("UMG_Pass_Purchase_C:ShowReward rewardList is nil")
    self:DoCloseWithSideGoods()
    return
  end
  local Rewards = rewardList
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.Finish
  CommonPopUpData.HideBtn = true
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, Rewards, LuaText.emailmodule_1, nil, nil, nil, nil, false, CommonPopUpData)
end

function UMG_Pass_Purchase_C:RewardOnCancelBtnClicked()
  Log.Info("UMG_Pass_Purchase_C:RewardOnCancelBtnClicked")
end

function UMG_Pass_Purchase_C:RewardOnOKBtnClicked()
  Log.Info("UMG_Pass_Purchase_C:RewardOnOKBtnClicked")
end

function UMG_Pass_Purchase_C:Finish()
  Log.Info("UMG_Pass_Purchase_C:Finish", self.DoPayGoodsId)
  if not self.module or not self.module.data then
    return
  end
  local cacheLevelUpData = self.module.data:GetCacheLevelUpData()
  self.module.data:ClearCacheLevelUpData()
  self:DoCloseWithSideGoods()
  if nil ~= cacheLevelUpData then
    local oldLv = cacheLevelUpData.oldLv or 0
    local newLv = cacheLevelUpData.newLv or 0
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenLevelUpShowPanel, oldLv, newLv)
  end
end

function UMG_Pass_Purchase_C:DoCloseWithSideGoods()
  if self.DoPayGoodsId ~= self.RechargeNormalSideGoodsID and self.DoPayGoodsId ~= self.RechargeCollectionSideGoodsID then
    self:DoClose()
  end
end

function UMG_Pass_Purchase_C:OnDirectPurchase(RewardList)
  Log.Info("UMG_Pass_Purchase_C:OnDirectPurchase", #RewardList)
  self:OnPurchaseFinish(RewardList)
end

function UMG_Pass_Purchase_C:OnPurchaseFinish(RewardList)
  Log.Info("UMG_Pass_Purchase_C:OnPurchaseFinish", #RewardList)
  self.GoodsRewardList = RewardList
  self:ShowUnlockEffect(self.DoPayGoodsId)
end

function UMG_Pass_Purchase_C:ShowUnlockEffect(UnlockItemID)
  Log.Info("UMG_Pass_Purchase_C:ShowUnlockEffect", UnlockItemID)
  local giftType, effectText, effectIcon = self:GetPurchaseEffectRes(UnlockItemID)
  if giftType == GiftType.SUB or giftType == GiftType.UNKNOWN then
    self:ShowReward(self.GoodsRewardList)
    return
  end
  local purchaseData = {
    goodsId = UnlockItemID,
    closeCallback = self.OnClosePurchaseSuccessfulTips,
    closeCallbackParam = self,
    effectText = effectText,
    effectIcon = effectIcon,
    titleText = _G.LuaText.bp_gift_shining_unlock_title
  }
  Log.Info("UMG_Pass_Purchase_C:OnPurchaseFinish", purchaseData.goodsId)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPurchaseSuccessfulTips, purchaseData)
end

function UMG_Pass_Purchase_C:GetPurchaseEffectRes(goodsId)
  if not goodsId then
    Log.Error("UMG_Pass_Purchase_C:GetPurchaseEffectRes goodsId is nil")
    return
  end
  local giftType, giftConf = self:GetGoodsType(goodsId)
  if not giftConf then
    Log.Warning("UMG_Pass_Purchase_C: \230\156\170\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132gift\233\133\141\231\189\174\239\188\140\229\149\134\229\147\129ID:", goodsId)
    return GiftType.UNKNOWN, nil, nil
  end
  if giftType == GiftType.SUB then
    Log.Info("UMG_Pass_Purchase_C: \229\137\175\229\136\184\232\180\173\228\185\176\239\188\140\228\184\141\230\146\173\230\148\190\231\137\185\230\149\136\239\188\140\229\149\134\229\147\129ID:", goodsId)
  end
  local effectText = ""
  local effectIcon = ""
  if giftType == GiftType.MAIN then
    effectText = giftConf.main_effect_text or ""
    effectIcon = giftConf.main_effect_icon or ""
    Log.Info("UMG_Pass_Purchase_C: \230\146\173\230\148\190\228\184\187\228\189\147\231\164\188\229\140\133\231\137\185\230\149\136\239\188\140\229\149\134\229\147\129ID:", goodsId, "\231\137\185\230\149\136\230\150\135\229\173\151:", effectText, "\231\137\185\230\149\136\229\155\190\230\160\135:", effectIcon)
  elseif giftType == GiftType.COUPLE then
    effectText = giftConf.couple_effect_text or ""
    effectIcon = giftConf.couple_effect_icon or ""
    Log.Info("UMG_Pass_Purchase_C: \230\146\173\230\148\190\229\143\140\228\186\186\231\164\188\229\140\133\231\137\185\230\149\136\239\188\140\229\149\134\229\147\129ID:", goodsId, "\231\137\185\230\149\136\230\150\135\229\173\151:", effectText, "\231\137\185\230\149\136\229\155\190\230\160\135:", effectIcon)
  else
    Log.Warning("UMG_Pass_Purchase_C: \230\156\170\231\159\165\229\149\134\229\147\129\231\177\187\229\158\139\239\188\140\229\149\134\229\147\129ID:", goodsId, "\231\177\187\229\158\139:", giftType)
  end
  return giftType, effectText, effectIcon
end

function UMG_Pass_Purchase_C:GetGoodsType(goodsId)
  if not goodsId then
    return GiftType.UNKNOWN, nil
  end
  for _, giftConf in pairs(self.giftConfMap) do
    if goodsId == giftConf.gift_goods_id then
      return GiftType.MAIN, giftConf
    elseif goodsId == giftConf.gift_goods_couple_id then
      return GiftType.COUPLE, giftConf
    elseif goodsId == giftConf.gift_goods_sub_id then
      return GiftType.SUB, giftConf
    end
  end
  return GiftType.UNKNOWN, nil
end

function UMG_Pass_Purchase_C:OnGlobalRefreshBagInfo()
  Log.Info("UMG_Pass_Purchase_C:OnGlobalRefreshBagInfo")
  self:InitPanel()
end

function UMG_Pass_Purchase_C:OnRefreshBagInfo(rsp)
  Log.Info("UMG_Pass_Purchase_C:OnRefreshBagInfo", rsp)
  if 0 == rsp.ret_info.ret_code then
    Log.Debug("UMG_Pass_Purchase_C:OnRefreshBagInfo", rsp.use_bag_id)
    if rsp.use_bag_id == self.UseBagItemID then
      local RechargeGoodsId = self.UseBagItemReChargeGoodsMap[self.UseBagItemID]
      if RechargeGoodsId then
        local GoodsReward = rsp.ret_info.goods_reward
        local RewardList = {}
        if GoodsReward and GoodsReward.rewards and #GoodsReward.rewards > 0 then
          for _, reward in ipairs(GoodsReward.rewards) do
            local itemData = {
              type = reward.type,
              id = reward.id,
              num = reward.num
            }
            table.insert(RewardList, itemData)
          end
          Log.Info("UMG_Pass_Purchase_C:OnRefreshBagInfo RewardList", #RewardList)
          self.GoodsRewardList = RewardList
        end
        self:ShowUnlockEffect(RechargeGoodsId)
      end
    end
  end
end

function UMG_Pass_Purchase_C:OnDepartmentClick()
  if not self.themeConf then
    return
  end
  local uiData = {}
  local petData = {}
  petData.base_conf_id = self.themeConf.theme_petbase_id
  uiData.petData = petData
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, uiData, _G.Enum.GoodsType.GT_PET)
end

return UMG_Pass_Purchase_C

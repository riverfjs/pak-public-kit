local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_ArdourUpPanel_C = _G.NRCPanelBase:Extend("UMG_ArdourUpPanel_C")

function UMG_ArdourUpPanel_C:OnActive(data)
  local title = _G.DataConfigManager:GetLocalizationConf("alchemy_HPup_title")
  self.TitleText:SetText(title and title.msg or "\232\175\183\233\133\141\231\189\174alchemy_HPup_title")
  self.itemInsufficient = _G.DataConfigManager:GetLocalizationConf("alchemy_make_item_short").msg
  self.coinInsufficient = _G.DataConfigManager:GetLocalizationConf("exchange_no_enough_currency").msg
  local MaxLevelHint = _G.DataConfigManager:GetLocalizationConf("alchemy_hp_is_max")
  self.isMaxLevelHint = MaxLevelHint and MaxLevelHint.msg or "\232\175\183\233\133\141\231\189\174alchemy_hp_is_max"
  local LevelRequiredNotMeet = _G.DataConfigManager:GetLocalizationConf("alchemy_HPup_grade_short")
  self.LevelRequiredNotMeet = LevelRequiredNotMeet and LevelRequiredNotMeet.msg or "\231\173\137\231\186\167\228\184\141\232\182\179,\230\178\161\233\133\141\230\150\135\230\156\172"
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  local LevelUpButtonText = _G.DataConfigManager:GetLocalizationConf("exchange_academic_execute")
  self.LevelUpButtonText = LevelUpButtonText and LevelUpButtonText.msg or "\232\175\183\233\133\141\231\189\174"
  self.UMG_CoinButton:SetClickAble(true)
  self.UMG_CoinButton:SetBtnText(self.LevelUpButtonText)
  self.CoinEnough = false
  self.ItemEnough = false
  self.shouldClose = false
  self.action = data.action
  self:OnAddEventListener()
  self:ShowOpen()
  self:BindInputAction()
end

function UMG_ArdourUpPanel_C:OnDeactive()
  self:OnRemoveEventListener()
  self:UnBindInputAction()
end

function UMG_ArdourUpPanel_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CommonCloseUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseUI")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_ArdourUpPanel_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseUI")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CommonCloseUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_ArdourUpPanel_C:OnPcClose()
  if not self.closeState then
    self:OnClose()
  end
end

function UMG_ArdourUpPanel_C:OnAnimationFinished(Animation)
  if Animation == self.open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif Animation == self.close and self.shouldClose then
    _G.NRCEventCenter:DispatchEvent(_G.AlchemyModuleEvent.ArdourUpPanelClosed)
    self:DoClose()
  end
end

function UMG_ArdourUpPanel_C:RefreshPanel()
  self.data = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetRoleHpMaxData)
  self.RestoreList = {}
  if 0 == #self.RestoreList then
    for i = 1, self.data.current_value do
      table.insert(self.RestoreList, {isNormal = true})
    end
    for i = math.max(self.data.current_value + 1, 1), self.data.max_value do
      table.insert(self.RestoreList, {isNormal = false})
      break
    end
  end
  self.ClickEnable = true
  if self.data.exchangeId and 0 ~= self.data.exchangeId then
    local exchange_conf = _G.DataConfigManager:GetExchangeConf(self.data.exchangeId)
    self.ClickEnable = AlchemyUtils.GetCanExchangeNum(exchange_conf) > 0
    self.CoinEnough = AlchemyUtils.GetCoinCanExchangeNum(exchange_conf) > 0
    self.ItemEnough = AlchemyUtils.GetItemCanExchangeNum(exchange_conf) > 0
  end
  if not self.ItemEnough then
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
    self.UMG_CoinButton2.Title_1:SetText(self.LevelUpButtonText)
  elseif not self.CoinEnough then
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
    self.UMG_CoinButton2.Title_1:SetText(self.LevelUpButtonText)
  elseif self.data.origin_value == self.data.target_value then
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
    self.UMG_CoinButton2.Title_1:SetText(self.isMaxLevelHint)
  elseif _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() < self.data.requiredLevel then
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2.btnLevelUp:SetIsEnabled(false)
    self.UMG_CoinButton2.Title_1:SetText(string.format(self.LevelRequiredNotMeet, self.data.requiredLevel))
  else
    self.UMG_CoinButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CoinButton2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.data.exchangeId, 1)
  self.DriveList:InitGridView(self.RestoreList)
  self:UpdateCostIcon(self.data.exchangeId, 1)
end

function UMG_ArdourUpPanel_C:UpdateCostIcon(exchangeId, item_num)
  if 0 == exchangeId then
    self.UMG_CoinButton.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CoinButton2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local currencyIcon
    if exchangeConf and exchangeConf.visual_item_cost_num and 0 ~= exchangeConf.visual_item_cost_num then
      self.UMG_CoinButton.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_CoinButton2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local CostCoinNum = exchangeConf.visual_item_cost_num
      if item_num and 0 ~= item_num then
        CostCoinNum = CostCoinNum * item_num
      end
      local current_coin_num = 0
      if exchangeConf.visual_item_cost_type == _G.Enum.VisualItem.VI_COIN then
        current_coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_COIN) or 0
        currencyIcon = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BagItem/1.1'"
      else
        Log.Error("\232\191\153\228\184\170\230\149\176\230\141\174\230\156\137\233\151\174\233\162\152\239\188\140\231\155\174\229\137\141\229\143\170\230\148\175\230\140\129\230\180\155\229\133\139\232\180\157\239\188\140\230\156\137\230\150\176\232\180\167\229\184\129\230\182\136\232\128\151\232\175\183\230\143\144\230\150\176\233\156\128\230\177\130")
      end
      self.UMG_CoinButton:SetClickAble(true)
      self.UMG_CoinButton:SetTitleTextAndIcon(currencyIcon, CostCoinNum)
      self.UMG_CoinButton2:SetTitleTextAndIcon(currencyIcon, CostCoinNum)
      if CostCoinNum > current_coin_num then
        self.UMG_CoinButton.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
        self.UMG_CoinButton2.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#CF3D3E"))
      else
        self.UMG_CoinButton.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
        self.UMG_CoinButton2.Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
      end
    else
      self.UMG_CoinButton.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_CoinButton2.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ArdourUpPanel_C:OnLevelUp()
  if not UIUtils.IsClickable(self) then
    return
  end
  if self:IsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_ArdourUpPanel_C:OnLevelUp")
  if self.ClickEnable then
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.PauseRoleHpShow)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.DisableClick)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RequestForUpgrade, _G.Enum.VisualItem.VI_ROLE_HP_MAX, self.data.upgradeId, self.data.exchangeId, self.data.origin_value, self.data.target_value)
  else
    Log.Error("\232\181\176\229\136\176\232\191\153\233\135\140\229\176\177\230\152\175bug")
  end
end

function UMG_ArdourUpPanel_C:OnClose()
  if not UIUtils.IsClickable(self) then
    return
  end
  if self:IsPlayingAnimation() then
    return
  end
  self.shouldClose = true
  self:PlayAnimation(self.close)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CloseMaterialItems)
end

function UMG_ArdourUpPanel_C:OnAddEventListener()
  self:AddButtonListener(self.ReturnBtn.btnClose, self.OnClose)
  self:AddButtonListener(self.UMG_CoinButton.btnLevelUp, self.OnLevelUp)
  _G.NRCEventCenter:RegisterEvent("UMG_ArdourUpPanel_C", self, DialogueModuleEvent.DialogueEnded, self.OnClose)
  _G.NRCEventCenter:RegisterEvent("UMG_ArdourUpPanel_C", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnClose)
end

function UMG_ArdourUpPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnClose)
end

function UMG_ArdourUpPanel_C:ShowClose()
  self.closeState = true
  self:StopAllAnimations()
  self:PlayAnimation(self.close)
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_ArdourUpPanel_C:ShowOpen()
  self.closeState = nil
  self:StopAllAnimations()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.open)
  self:RefreshPanel()
end

return UMG_ArdourUpPanel_C

local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_RecoverUpPanel_C = _G.NRCPanelBase:Extend("UMG_RecoverUpPanel_C")

function UMG_RecoverUpPanel_C:OnActive(data)
  local title = _G.DataConfigManager:GetLocalizationConf("alchemy_bottle_volume_title")
  self.Title:SetText(title and title.msg or "\232\175\183\233\133\141\231\189\174alchemy_bottle_volume_title")
  local insufficientText = _G.DataConfigManager:GetLocalizationConf("alchemy_bottle_volume_item_short")
  self.insufficientText = insufficientText and insufficientText.msg or "\230\157\144\230\150\153\228\184\141\232\182\179\230\178\161\233\133\141\230\150\135\230\156\172"
  local MaxLevelHint = _G.DataConfigManager:GetLocalizationConf("alchemy_bottle_volume_is_max")
  self.isMaxLevelHint = MaxLevelHint and MaxLevelHint.msg or "\232\175\183\233\133\141\231\189\174alchemy_bottle_volume_is_max"
  local LevelRequiredNotMeet = _G.DataConfigManager:GetLocalizationConf("alchemy_bottle_volume_grade_short")
  self.LevelRequiredNotMeet = LevelRequiredNotMeet and LevelRequiredNotMeet.msg or "\231\173\137\231\186\167\228\184\141\232\182\179,\230\150\135\230\156\172\232\175\187\228\184\141\229\136\176"
  local LevelUpButtonText = _G.DataConfigManager:GetLocalizationConf("alchemy_bottle_volume_upgrade")
  self.LevelUpText = LevelUpButtonText and LevelUpButtonText.msg or "\232\175\183\233\133\141\231\189\174alchemy_bottle_volume_upgrade"
  self.UpgradeButton:SetBtnText(self.LevelUpText)
  self.action = data.action
  self.shouldClose = false
  self:OnAddEventListener()
  self:ShowOpen()
end

function UMG_RecoverUpPanel_C:OnAnimationFinished(Animation)
  if Animation == self.open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif Animation == self.close and self.shouldClose then
    if self.action then
      self.action:EndAction()
    end
    self:DoClose()
  end
end

function UMG_RecoverUpPanel_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_RecoverUpPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClose)
  self:AddButtonListener(self.UpgradeButton.btnLevelUp, self.OnLevelUp)
  _G.NRCEventCenter:RegisterEvent("UMG_RecoverUpPanel_C", self, DialogueModuleEvent.DialogueEnded, self.OnClose)
  _G.NRCEventCenter:RegisterEvent("UMG_RecoverUpPanel_C", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnClose)
  _G.NRCEventCenter:RegisterEvent("UMG_RecoverUpPanel_C", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  _G.NRCEventCenter:RegisterEvent("UMG_RecoverUpPanel_C", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
end

function UMG_RecoverUpPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnClose)
end

function UMG_RecoverUpPanel_C:OnBagChange()
  self:UpdatePanel()
end

function UMG_RecoverUpPanel_C:UpdatePanel()
  self.data = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetBottleVolumeData)
  self.ClickEnable = true
  for _, value in pairs(self.data.item_list) do
    if value.itemNum < value.itemNeedNum then
      self.ClickEnable = false
    end
  end
  if not self.ClickEnable then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.MaxLevelHint_2:SetText(self.insufficientText)
  elseif self.data.origin_value == self.data.target_value then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.MaxLevelHint_2:SetText(self.isMaxLevelHint)
  elseif _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() < self.data.requiredLevel then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.MaxLevelHint_2:SetText(string.format(self.LevelRequiredNotMeet, self.data.requiredLevel))
  else
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  end
  if self.data.origin_value == self.data.target_value then
    self.TextSwitcher:SetActiveWidgetIndex(1)
    self.MaxText:SetText(self.data.origin_value)
  else
    self.TextSwitcher:SetActiveWidgetIndex(0)
    self.OriginText:SetText(self.data.origin_value)
    self.TargetText:SetText(self.data.target_value)
  end
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.data.exchangeId, 1)
end

function UMG_RecoverUpPanel_C:ShowClose()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:StopAllAnimations()
  self:PlayAnimation(self.close)
end

function UMG_RecoverUpPanel_C:ShowOpen()
  self:StopAllAnimations()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.open)
  self:UpdatePanel()
end

function UMG_RecoverUpPanel_C:OnClose()
  if not UIUtils.IsClickable(self) then
    return
  end
  if self:IsPlayingAnimation() then
    return
  end
  self:PlayAnimation(self.close)
  self.shouldClose = true
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CloseMaterialItems)
end

function UMG_RecoverUpPanel_C:OnLevelUp()
  if not UIUtils.IsClickable(self) then
    return
  end
  if self:IsPlayingAnimation() then
    return
  end
  if self.ClickEnable then
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.DisableClick)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RequestForUpgrade, _G.Enum.VisualItem.VI_BOTTLE_VOLUME, self.data.upgradeId, self.data.exchangeId, self.data.origin_value, self.data.target_value)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.insufficientText or "\228\184\141\231\159\165\233\129\147\228\184\186\228\187\128\228\185\136\230\152\175\231\169\186\231\154\132")
  end
end

return UMG_RecoverUpPanel_C

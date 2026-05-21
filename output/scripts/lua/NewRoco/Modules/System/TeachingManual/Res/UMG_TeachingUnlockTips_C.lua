local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_TeachingUnlockTips_C = _G.NRCPanelBase:Extend("UMG_TeachingUnlockTips_C")

function UMG_TeachingUnlockTips_C:OnConstruct(tip)
  self:OnAddEventListener()
  local curModule = self.module
  self.tipsDisplayController = curModule and curModule.getTeachingUnlockTipsController
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
  self:PCKeySetting()
end

function UMG_TeachingUnlockTips_C:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TeachingUnlockTips_C:OnPlayTips(tip)
  local tipData = tip.customData
  self.teachId = tipData.TeachId
  Log.Debug(self.teachId, "UMG_TeachingUnlockTips_C:OnPlayTips")
  self.TeachConf = _G.DataConfigManager:GetTeachConf(self.teachId)
  if self.TeachConf.unlock_icon then
    self.TeachIcon:SetPath(self.TeachConf.unlock_icon)
  else
    self.TeachIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/TeachingManual/Raw/Frames/img_icon_png.img_icon_png'")
  end
  if self.TeachConf.unlock_text_main then
    self.text:SetText(self.TeachConf.unlock_text_main)
  else
    self.text:SetText(self.TeachConf.list_des)
  end
  if self.TeachConf.unlock_text_sub then
    self.RichText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RichText:SetText(self.TeachConf.unlock_text_sub)
  else
    self.RichText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PlayAnimation(self.Appear)
  self.ShowTime = tip.timeLeft
  self.text_1:SetText(string.format(LuaText.TeachingUnlockTips, self.ShowTime))
  if self.tipsDisplayController and self.tipsDisplayController:GetExecutor():IsPaused() then
    Log.Debug("TeachingUnlockTipsDisplayExecutorIsPause")
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008001, "UMG_TeachingUnlockTips_C:OnPlayTips")
end

function UMG_TeachingUnlockTips_C:OnAllTipsFinished()
  self:ClosePanel()
end

function UMG_TeachingUnlockTips_C:ClosePanel()
  self:PlayAnimation(self.Disappear)
end

function UMG_TeachingUnlockTips_C:OnPlayTipStatusChange(pause)
  if pause then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    if self:IsAnimationPlaying(self.Disappear) then
      self.IsClose = true
      self:DoClose()
      return
    end
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_TeachingUnlockTips_C:OnUpdateTips(tip, interval)
  if tip and tip.timeLeft then
    self.ShowTime = tip.timeLeft
    self.text_1:SetText(string.format(LuaText.TeachingUnlockTips, self.ShowTime))
  end
end

function UMG_TeachingUnlockTips_C:PCKeySetting()
  if SystemSettingModuleCmd then
    local InputAction = string.format("IA_MessageDetails")
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, InputAction)
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey:SetKeyVisibility(true)
  end
end

function UMG_TeachingUnlockTips_C:OnDeactive()
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
  end
end

function UMG_TeachingUnlockTips_C:OnAnimationFinished(anim)
  if anim == self.Disappear and not self.IsClose then
    self:DoClose()
  end
end

function UMG_TeachingUnlockTips_C:OnAddEventListener()
  self:AddButtonListener(self.TipsBtn, self.OpenPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_TeachingUnlockTips_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_TeachingUnlockTips_C:OpenPanel()
  if self.tipsDisplayController then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    if tip and self.TeachConf then
      _G.NRCModeManager:DoCmd(NPCShopUIModuleCmd.CloseNPCShopItemRewardsPanel)
      _G.NRCModeManager:DoCmd(TeachingManualModuleCmd.OpenMainPanel, true, self.TeachConf.id)
    end
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  else
    self:DoClose()
  end
end

function UMG_TeachingUnlockTips_C:HasValidData()
  if self.tipsDisplayController then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    return nil ~= tip
  end
  return false
end

return UMG_TeachingUnlockTips_C

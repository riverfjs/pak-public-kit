local UMG_Pass_levelUp_C = _G.NRCPanelBase:Extend("UMG_Pass_levelUp_C")

function UMG_Pass_levelUp_C:OnConstruct()
  self:AddButtonListener(self.Button_116, self.OnCloseBtnClick)
end

function UMG_Pass_levelUp_C:OnPcClose()
  if self._isClosing then
    return
  end
  self:OnCloseBtnClick()
end

function UMG_Pass_levelUp_C:OnDestruct()
end

function UMG_Pass_levelUp_C:OnActive(oldLv, newLv)
  self._isClosing = false
  self.oldLv = oldLv
  self.newLv = newLv
  self:InitUI()
  _G.NRCAudioManager:PlaySound2DAuto(1220002007, "UMG_Bag_C:OnConstruct")
end

function UMG_Pass_levelUp_C:OnUpdatePanel(oldLv, newLv)
  Log.Error("\232\176\131\231\148\168\229\136\183\230\150\176\239\188\129", oldLv, newLv)
  self._isClosing = false
  self.oldLv = oldLv
  self.newLv = newLv
  self:InitUI()
  _G.NRCAudioManager:PlaySound2DAuto(1220002007, "UMG_Bag_C:OnConstruct")
end

function UMG_Pass_levelUp_C:OnDeactive()
end

function UMG_Pass_levelUp_C:OnAddEventListener()
end

function UMG_Pass_levelUp_C:OnAnimationFinished(anim)
  if anim == self.Close or anim == self.Close_2 then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.TriggerCacheRewardPanel)
    self:DoClose()
  elseif anim == self.Open or anim == self.Open_0 then
    self.UMG_Pass_AwardItem_Lizi:PlayLoopAnim()
    self.Button_116:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Pass_levelUp_C:InitUI()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_levelUp", self)
  local server_time = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurServerTime)
  local date = os.date("*t", server_time)
  self.NRCText_96:SetText(string.format("%d.%d.%d", date.year, date.month, date.day))
  local title = _G.DataConfigManager:GetLocalizationConf("BP_level_up_desc").msg
  self.Title:SetText(title)
  self.Button_116:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Title_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Title_1:SetText(self.oldLv)
  self.Title_2:SetText(self.newLv)
  local bpInfo = self.module.data:GetPlayerBattlePassInfo()
  self.themeId = bpInfo.theme_id
  local isThemeA = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.IsThemeA, self.themeId)
  if isThemeA then
    self.PSW_Blue:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PSW_Pink:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Theme_TintColorImage:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#002BFFFF"))
    self.NRCText_20:SetText(LuaText.battlepass_bule_level)
  else
    self.PSW_Blue:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PSW_Pink:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Theme_TintColorImage:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#E981FFFF"))
    self.NRCText_20:SetText(LuaText.battlepass_pink_level)
  end
  self:PlayAnimation(self.Open)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_levelUp", self)
end

function UMG_Pass_levelUp_C:OnCloseBtnClick()
  if self._isClosing then
    return
  end
  self._isClosing = true
  _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_Pass_levelUp_C:OnCloseBtnClick")
  self.Button_116:SetIsEnabled(false)
  local isThemeA = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.IsThemeA, self.themeId)
  if self.themeId and not isThemeA then
    self:PlayAnimation(self.Close)
  else
    self:PlayAnimation(self.Close_2)
  end
end

return UMG_Pass_levelUp_C

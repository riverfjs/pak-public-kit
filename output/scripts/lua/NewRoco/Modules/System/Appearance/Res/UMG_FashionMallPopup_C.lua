local UMG_FashionMallPopup_C = _G.NRCPanelBase:Extend("UMG_FashionMallPopup_C")

function UMG_FashionMallPopup_C:OnConstruct()
end

function UMG_FashionMallPopup_C:OnActive(param)
  Log.Dump(param, 3, "UMG_FashionMallPopup_C:OnActive")
  UE4Helper.SetDesiredShowCursor(true, "UMG_FashionMallPopup_C")
  _G.NRCAudioManager:PlaySound2DAuto(1247, "UMG_FashionMallPopup_C:OnActive")
  self.uiData = param
  self:OnAddEventListener()
  self:PlayAnimation(self.In)
  self:UpdatePanelInfo()
  if param and param.hideBtn2 then
    self.Btn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_FashionMallPopup_C:OnDeactive()
end

function UMG_FashionMallPopup_C:OnAddEventListener()
  self:AddButtonListener(self.BtnClose.btnClose, self.OnCloseBtnClicked)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnGotoBtnClicked)
  self:AddButtonListener(self.NRCButton_0, self.OnCloseBtnClicked)
end

function UMG_FashionMallPopup_C:OnRemoveEventListener()
end

function UMG_FashionMallPopup_C:OnDestruct()
  self:OnRemoveEventListener()
  self.module:OnCmdOpenFashionMallPopup()
  if self.uiData and self.uiData.closeCallback then
    self.uiData.closeCallback()
  end
  UE4Helper.ReleaseDesiredShowCursor("UMG_FashionMallPopup_C")
end

function UMG_FashionMallPopup_C:OnCloseBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1247, "UMG_FashionMallPopup_C:OnCloseBtnClicked")
  self:PlayAnimation(self.Out)
end

function UMG_FashionMallPopup_C:OnGotoBtnClicked()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShop, _G.AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG, self.uiData.pkgId)
  if self.module and self.module.OnCmdClearFashionMallPopup then
    self.module:OnCmdClearFashionMallPopup()
  end
  self:PlayAnimation(self.Out)
end

function UMG_FashionMallPopup_C:UpdatePanelInfo()
  self.Bg1:SetPath(self.uiData.kvBg)
  local text = self:GetShowTime(self.uiData.leftTime)
  self.TimeRemaining:SetText(text)
end

function UMG_FashionMallPopup_C:GetShowTime(seconds)
  if seconds > 0 then
    local day = seconds // 86400
    local hour = (seconds - 86400 * day) // 3600
    local minute = (seconds - 86400 * day - 3600 * hour) // 60
    if day > 0 then
      return string.format(LuaText.activity_RTS1, day, hour)
    elseif hour > 0 or minute > 0 then
      return string.format(LuaText.activity_RTS2, hour, minute)
    else
      return LuaText.activity_RTS3
    end
  end
end

function UMG_FashionMallPopup_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

return UMG_FashionMallPopup_C

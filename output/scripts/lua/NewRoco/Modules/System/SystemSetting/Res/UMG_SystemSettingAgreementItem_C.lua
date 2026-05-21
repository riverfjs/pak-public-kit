local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_SystemSettingAgreementItem_C = Base:Extend("UMG_SystemSettingAgreementItem_C")

function UMG_SystemSettingAgreementItem_C:OnConstruct()
  self.Btn:SetVisibility(UE4.ESlateVisibility.Visible)
  self:AddButtonListener()
end

function UMG_SystemSettingAgreementItem_C:OnDestruct()
end

function UMG_SystemSettingAgreementItem_C:AddButtonListener()
  self.Btn.OnClicked:Add(self, self.OnBtnClicked)
end

function UMG_SystemSettingAgreementItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.PrivacyOptions = self.uiData.PrivacyOptions
  self:InitInfo()
end

function UMG_SystemSettingAgreementItem_C:OnInformationTextClick(url_key)
  self:Log("UMG_SystemSettingMain_C.OnInformationTextClick", url_key)
  for _, v in pairs(self.PrivacyOptions) do
    if v and v.key == url_key and v.func then
      v.func(self.uiData.Caller, v)
    end
  end
end

function UMG_SystemSettingAgreementItem_C:OnDeactive()
end

function UMG_SystemSettingAgreementItem_C:InitInfo()
  if self.uiData.privacyText then
    self.Text:SetText(self.uiData.privacyText)
    self.Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Text:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_SystemSettingAgreementItem_C:OnBtnClicked()
  if self.cdTimer then
    return
  end
  self.cdTimer = _G.TimerManager:CreateTimer(self, "UMG_SystemSettingAgreementItem_C_OnBtnClicked", 1, nil, function()
    self.cdTimer = nil
  end, 0.1)
  self:PlayAnimation(self.Press)
end

function UMG_SystemSettingAgreementItem_C:OnAnimationFinished(anim)
  if anim == self.Press then
    self:PlayAnimation(self.Up)
  elseif anim == self.Up then
    if 0 == self.uiData.privacyType and self.uiData.key and self.uiData.Caller then
      self:OnInformationTextClick(self.uiData.key)
    elseif 1 == self.uiData.privacyType then
      local url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_protect_platform", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
      self:Log("UMG_SystemSettingMain_C:OnPromptTextClick", url)
      local screenType = 2
      if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
        screenType = 1
      end
      local isFullScreen = false
      local isUseURLEncode = false
      local entraJson = ""
      local bIsBrowser = false
      UE4.UWebViewStatics.OpenURL(url, screenType, isFullScreen, isUseURLEncode, entraJson, bIsBrowser)
    end
  end
end

return UMG_SystemSettingAgreementItem_C

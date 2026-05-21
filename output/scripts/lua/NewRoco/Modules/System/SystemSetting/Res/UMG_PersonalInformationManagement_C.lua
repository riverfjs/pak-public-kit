local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local UMG_PersonalInformationManagement_C = _G.NRCPanelBase:Extend("NewRoco.Modules.System.SystemSetting.Res.UMG_PersonalInformationManagement_C")

function UMG_PersonalInformationManagement_C:OnConstruct()
  if self.BtnModifyName and self.BtnModifyName.btnLevelUp then
    self:AddButtonListener(self.BtnModifyName.btnLevelUp, self.OnBtnModifyNameClick)
  end
  if self.BtnGO and self.BtnGO.btnLevelUp then
    self:AddButtonListener(self.BtnGO.btnLevelUp, self.OnBtnGOClick)
  end
  if self.BtnContactCustomerService and self.BtnContactCustomerService.btnLevelUp then
    self:AddButtonListener(self.BtnContactCustomerService.btnLevelUp, self.OnBtnContactCustomerServiceClick)
  end
  self:DynamicAddChildView(self.PopUp)
  self:SetCommonPopUpInfo(self.PopUp)
  if self.Name then
    self.Name:SetText(string.format("%s%s", LuaText.privacy_setting_49, _G.DataModelMgr.PlayerDataModel:GetPlayerName()))
  end
end

function UMG_PersonalInformationManagement_C:OnActive()
  self:LoadAnimation(0)
end

function UMG_PersonalInformationManagement_C:OnDestruct()
  self:Log("UMG_PersonalInformationManagement_C:OnDestruct")
  if self.BtnModifyName and self.BtnModifyName.btnLevelUp then
    self:RemoveButtonListener(self.BtnModifyName.btnLevelUp)
  end
  if self.BtnGO and self.BtnGO.btnLevelUp then
    self:RemoveButtonListener(self.BtnGO.btnLevelUp)
  end
  if self.BtnContactCustomerService and self.BtnContactCustomerService.btnLevelUp then
    self:RemoveButtonListener(self.BtnContactCustomerService.btnLevelUp)
  end
end

function UMG_PersonalInformationManagement_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.btnClose = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtn
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_PersonalInformationManagement_C:ChangePlayerName()
  if self.Name then
    self.Name:SetText(string.format("%s%s", LuaText.privacy_setting_49, _G.DataModelMgr.PlayerDataModel:GetPlayerName()))
  end
end

function UMG_PersonalInformationManagement_C:OnCloseBtn()
  self:LoadAnimation(2)
end

function UMG_PersonalInformationManagement_C:OnBtnModifyNameClick()
  self:Log("OnBtnModifyNameClick")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChangeCardLabel, nil, nil, 2)
end

function UMG_PersonalInformationManagement_C:OnBtnGOClick()
  self:Log("OnBtnGOClick")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, nil, FriendEnum.AdminFriendType.Own, FriendEnum.Source.Friend, nil)
end

local URL_Data = {
  kefu_qq_url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("kefu_qq_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
  privacy_protect_platform = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_protect_platform", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
}

function UMG_PersonalInformationManagement_C:OnBtnContactCustomerServiceClick()
  self:Log("OnBtnContactCustomerServiceClick")
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.TitleText = LuaText.privacy_setting_44
  popUpData.Call = self
  popUpData.HideBtn = true
  popUpData.bUseContentText1 = true
  popUpData.ContentTextOnRichTextClickHandle = self.OnContentTextOnRichTextClick
  popUpData.ContentText = string.format(LuaText.privacy_setting_43, string.format("<a id=\"%s\">%s</>", URL_Data.kefu_qq_url, "kefu_qq_url"), string.format("<a id=\"%s\">%s</>", URL_Data.privacy_protect_platform, "privacy_protect_platform"))
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function UMG_PersonalInformationManagement_C:OnContentTextOnRichTextClick(key)
  Log.Info("UMG_PersonalInformationManagement_C:OnContentTextOnRichTextClick ", key)
  if URL_Data[key] then
    UE4.UWebViewStatics.OpenURL(URL_Data[key])
  end
end

function UMG_PersonalInformationManagement_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  elseif anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_PersonalInformationManagement_C:OnPcClose()
  self:Log("OnPcClose")
  self:LoadAnimation(2)
end

return UMG_PersonalInformationManagement_C

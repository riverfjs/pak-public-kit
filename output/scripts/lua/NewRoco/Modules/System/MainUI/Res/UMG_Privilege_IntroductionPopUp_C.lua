local UMG_Privilege_IntroductionPopUp_C = _G.NRCPanelBase:Extend("UMG_Privilege_IntroductionPopUp_C")

function UMG_Privilege_IntroductionPopUp_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Privilege_IntroductionPopUp_C:OnActive(ChangeType)
  if ChangeType then
    self.ChannelType = ChangeType
  else
    local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    self.ChannelType = 1
    local loginChannelType = accountInfo and accountInfo.plat_info and accountInfo.plat_info.cli_login_channel or nil
    if accountInfo then
      if loginChannelType == Enum.CliLoginChannel.CLC_WX then
        self.ChannelType = 1
      elseif loginChannelType == Enum.CliLoginChannel.CLC_QQ then
        self.ChannelType = 2
      end
    end
  end
  if 1 ~= self.ChannelType and 2 ~= self.ChannelType then
    Log.Error("Login Channel is not can opening self")
  end
  local LocalText = 1 == self.ChannelType and LuaText.privilege_open_path_prompts_wx or LuaText.privilege_open_path_prompts_qq
  self.Text1:SetText(LocalText)
  self.Icon1:SetActiveWidgetIndex(self.ChannelType - 1)
  self.Switcher:SetActiveWidgetIndex(self.ChannelType - 1)
  self:UpdatePopupBox()
end

function UMG_Privilege_IntroductionPopUp_C:UpdatePopupBox()
  local Title = LuaText.Privilege_Wechat_IntroductionPopUp_Title
  local Desc = LuaText.Privilege_Wechat_Desc
  if 2 == self.ChannelType then
    Title = LuaText.Privilege_QQ_IntroductionPopUp_Title
    Desc = LuaText.Privilege_QQ_Desc
  end
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = Title
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCancel
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Desc = Desc
  CommonPopUpData.textBG = true
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Privilege_IntroductionPopUp_C:OnPcClose()
  self:OnClose()
end

function UMG_Privilege_IntroductionPopUp_C:OnCancel()
  self:OnClose()
end

function UMG_Privilege_IntroductionPopUp_C:OnDeactive()
end

function UMG_Privilege_IntroductionPopUp_C:OnAddEventListener()
end

return UMG_Privilege_IntroductionPopUp_C

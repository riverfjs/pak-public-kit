local UMG_SecondaryPasswordSet_C = _G.NRCPanelBase:Extend("UMG_SecondaryPasswordSet_C")

function UMG_SecondaryPasswordSet_C:OnActive()
  self:SetCommonPopUpInfo()
  self:ReqSecondaryPasswordGetAuthInfo()
  self.SetTips:SetText(LuaText.secondary_pwd_setup_screen_text)
  self:LoadAnimation(0)
end

function UMG_SecondaryPasswordSet_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.RefreshSecondaryList)
end

function UMG_SecondaryPasswordSet_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_SecondaryPasswordSet_C:OnDestruct()
end

function UMG_SecondaryPasswordSet_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnClickCloseBtn)
end

function UMG_SecondaryPasswordSet_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_SecondaryPasswordSet_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = LuaText.secondary_pwd_setup_modal_title
  CommonPopUpData.Btn_LeftHandler = self.OnClickCloseBtn
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_SecondaryPasswordSet_C:ReqSecondaryPasswordGetAuthInfo()
  local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordGetAuthInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_GET_AUTH_INFO_REQ, reqMsg, self, self.OnSecondaryPasswordGetAuthInfoRsp, nil, false)
end

function UMG_SecondaryPasswordSet_C:OnSecondaryPasswordGetAuthInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local passwordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
    if passwordInfo then
      if passwordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Unset and rsp.status == ProtoEnum.SecondaryPasswordStatus.SPS_Set then
        Log.Info("UMG_SecondaryPasswordSet_C:OnSecondaryPasswordGetAuthInfoRsp status not same")
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2535)
        _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
        self:DoClose()
      else
        self.authInfo = rsp
      end
    end
  end
end

function UMG_SecondaryPasswordSet_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ShowMagicMessage_C:OnClickCloseBtn")
  self:LoadAnimation(2)
end

function UMG_SecondaryPasswordSet_C:OnClickConfirm()
  if self.authInfo == nil then
    return
  end
  
  local function is_valid_format(str)
    if #str >= 4 and #str <= 8 and string.match(str, "^%d+$") then
      return true
    end
    return false
  end
  
  local inputText = self.InputText:GetText()
  local inputTextAgain = self.InputTextAgain:GetText()
  if is_valid_format(inputText) and is_valid_format(inputTextAgain) then
    if inputText == inputTextAgain then
      local password = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.EncryptInputText, inputText, self.authInfo)
      if "" ~= password then
        local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordCheckReq()
        reqMsg.action = ProtoEnum.ZoneSecondaryPasswordAction.SPA_SET
        reqMsg.encode_secondary_password = password
        reqMsg.pass_action = 1
        reqMsg.public_key_md5 = self.authInfo.public_key_md5
        _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_CHECK_REQ, reqMsg, self, self.OnSecondaryPasswordCheckRsp, nil, false)
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_setup_pwd_mismatch)
    end
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_invalid_format)
  end
end

function UMG_SecondaryPasswordSet_C:OnSecondaryPasswordCheckRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_setup_success)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
    self:DoClose()
  end
end

return UMG_SecondaryPasswordSet_C

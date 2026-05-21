local UMG_SecondaryPasswordVerify_C = _G.NRCPanelBase:Extend("UMG_SecondaryPasswordVerify_C")

function UMG_SecondaryPasswordVerify_C:OnActive()
  self:SetCommonPopUpInfo()
  self:ReqSecondaryPasswordGetAuthInfo()
  self:InitTips()
  self:LoadAnimation(0)
end

function UMG_SecondaryPasswordVerify_C:OnDeactive()
end

function UMG_SecondaryPasswordVerify_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_SecondaryPasswordVerify_C:OnDestruct()
  if self.Timer then
    _G.TimerManager:RemoveTimer(self.Timer)
    self.Timer = nil
  end
end

function UMG_SecondaryPasswordVerify_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnClickCloseBtn)
  self.ForgotPassword.OnRichTextClick:Add(self, self.OnClickForget)
end

function UMG_SecondaryPasswordVerify_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_SecondaryPasswordVerify_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = LuaText.secondary_pwd_verify_screen_title
  CommonPopUpData.Btn_LeftHandler = self.OnClickCloseBtn
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_SecondaryPasswordVerify_C:ReqSecondaryPasswordGetAuthInfo()
  local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordGetAuthInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_GET_AUTH_INFO_REQ, reqMsg, self, self.OnSecondaryPasswordGetAuthInfoRsp, nil, false)
end

function UMG_SecondaryPasswordVerify_C:OnSecondaryPasswordGetAuthInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.authInfo = rsp
  end
end

function UMG_SecondaryPasswordVerify_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "OnClickCloseBtn:OnClickCloseBtn")
  self:LoadAnimation(2)
end

function UMG_SecondaryPasswordVerify_C:OnClickForget()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "OnClickCloseBtn:OnClickForget")
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ForgetSecondaryPassword)
  self:DoClose()
end

function UMG_SecondaryPasswordVerify_C:OnClickConfirm()
  if self.authInfo == nil then
    return
  end
  local inputText = self.InputText:GetText()
  local passWord = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.EncryptInputText, inputText, self.authInfo)
  if "" ~= passWord then
    local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordCheckReq()
    reqMsg.action = ProtoEnum.ZoneSecondaryPasswordAction.SPA_PASS
    reqMsg.encode_secondary_password = passWord
    reqMsg.pass_action = 1
    reqMsg.public_key_md5 = self.authInfo.public_key_md5
    reqMsg.default_free = 1
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_CHECK_REQ, reqMsg, self, self.OnSecondaryPasswordCheckRsp, nil, false)
  end
end

function UMG_SecondaryPasswordVerify_C:OnSecondaryPasswordCheckRsp(rsp)
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_SCE_PWD_WAIT then
    local waiting_duration = self.authInfo.waiting_duration
    local leftSec
    if 0 == self.authInfo.status_timestamp then
      leftSec = waiting_duration
    else
      local curSec = _G.ZoneServer:GetServerTime() / 1000
      leftSec = waiting_duration - (curSec - self.authInfo.status_timestamp)
    end
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.secondary_pwd_cd_tips, math.ceil(leftSec / 60)))
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
    self:DoClose()
    return
  end
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_verify_success)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
    self:DoClose()
  end
end

function UMG_SecondaryPasswordVerify_C:InitTips()
  local passwordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
  if passwordInfo then
    if passwordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
      self.WidgetSwitcher_Tips:SetActiveWidgetIndex(1)
      self.CancelDisableTips:SetText(LuaText.secondary_pwd_remove_pwd_warning)
      self.LeftTimeTips:SetText(LuaText.secondary_pwd_force_close_countdown)
      local statusStamp = passwordInfo.status_timestamp
      local currentTime = _G.ZoneServer:GetServerTime() / 1000
      if currentTime - statusStamp > 0 then
        self.leftTime = 259200 - (currentTime - statusStamp)
        if self.leftTime > 0 then
          self:SetTimeText(self.leftTime)
          self.Timer = _G.TimerManager:CreateTimer(self, "UMG_SecondaryPasswordVerify_C", self.leftTime, self.OnTimerUpdate, self.OnTimerEnd, 1)
        end
      end
    else
      self.WidgetSwitcher_Tips:SetActiveWidgetIndex(0)
      self.VerifyTips:SetText(LuaText.secondary_pwd_verify_screen_text)
    end
  end
end

function UMG_SecondaryPasswordVerify_C:OnTimerUpdate()
  if self.leftTime then
    self.leftTime = self.leftTime - 1
    if self.leftTime > 0 then
      self:SetTimeText(self.leftTime)
    end
  end
end

function UMG_SecondaryPasswordVerify_C:OnTimerEnd()
  self:DoClose()
end

function UMG_SecondaryPasswordVerify_C:SetTimeText(leftTime)
  local hour = math.floor(leftTime / 3600)
  local minute = math.floor((leftTime - 3600 * hour) / 60)
  local sec = math.floor(leftTime - 3600 * hour - 60 * minute)
  self.Time:SetText(string.format("%02d:%02d:%02d", hour, minute, sec))
end

return UMG_SecondaryPasswordVerify_C

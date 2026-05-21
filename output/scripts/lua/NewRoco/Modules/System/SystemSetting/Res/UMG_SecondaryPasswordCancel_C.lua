local UMG_SecondaryPasswordCancel_C = _G.NRCPanelBase:Extend("UMG_SecondaryPasswordCancel_C")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")

function UMG_SecondaryPasswordCancel_C:OnActive()
  self:SetCommonPopUpInfo()
  self:ReqSecondaryPasswordGetAuthInfo()
  self.CancelTips:SetText(LuaText.secondary_pwd_remove_screen_text)
  self:LoadAnimation(0)
end

function UMG_SecondaryPasswordCancel_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.RefreshSecondaryList)
end

function UMG_SecondaryPasswordCancel_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_SecondaryPasswordCancel_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.OnSecondPasswordStatusChange)
end

function UMG_SecondaryPasswordCancel_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnClickCloseBtn)
  self.ForgotPassword.OnRichTextClick:Add(self, self.OnClickForget)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.OnSecondPasswordStatusChange)
end

function UMG_SecondaryPasswordCancel_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_SecondaryPasswordCancel_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = LuaText.secondary_pwd_remove_screen_title
  CommonPopUpData.Btn_LeftHandler = self.OnClickCloseBtn
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_SecondaryPasswordCancel_C:ReqSecondaryPasswordGetAuthInfo()
  local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordGetAuthInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_GET_AUTH_INFO_REQ, reqMsg, self, self.OnSecondaryPasswordGetAuthInfoRsp, nil, false)
end

function UMG_SecondaryPasswordCancel_C:OnSecondaryPasswordGetAuthInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.authInfo = rsp
  end
end

function UMG_SecondaryPasswordCancel_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_SecondaryPasswordCancel_C:OnClickCloseBtn")
  self:LoadAnimation(2)
end

function UMG_SecondaryPasswordCancel_C:OnClickForget()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_SecondaryPasswordCancel_C:OnClickForget")
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ForgetSecondaryPassword)
  self:DoClose()
end

function UMG_SecondaryPasswordCancel_C:OnClickConfirm()
  if self.authInfo == nil then
    return
  end
  local inputText = self.InputText:GetText()
  local passWord = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.EncryptInputText, inputText, self.authInfo)
  if passWord then
    local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordCheckReq()
    reqMsg.action = ProtoEnum.ZoneSecondaryPasswordAction.SPA_UNSET
    reqMsg.encode_secondary_password = passWord
    reqMsg.pass_action = 1
    reqMsg.public_key_md5 = self.authInfo.public_key_md5
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_CHECK_REQ, reqMsg, self, self.OnSecondaryPasswordCheckRsp, nil, false)
  end
end

function UMG_SecondaryPasswordCancel_C:OnSecondaryPasswordCheckRsp(rsp)
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
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_remove_success)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
    self:DoClose()
  end
end

function UMG_SecondaryPasswordCancel_C:OnSecondPasswordStatusChange(oldStatus, newStatus)
  if oldStatus == ProtoEnum.SecondaryPasswordStatus.SPS_Disable and newStatus == ProtoEnum.SecondaryPasswordStatus.SPS_Unset then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.Error_Code_2535))
    self:DoClose()
  end
end

return UMG_SecondaryPasswordCancel_C

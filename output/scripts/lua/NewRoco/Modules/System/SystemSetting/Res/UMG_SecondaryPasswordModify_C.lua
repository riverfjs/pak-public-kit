local UMG_SecondaryPasswordModify_C = _G.NRCPanelBase:Extend("UMG_SecondaryPasswordModify_C")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")

function UMG_SecondaryPasswordModify_C:OnActive()
  self:SetCommonPopUpInfo()
  self:ReqSecondaryPasswordGetAuthInfo()
  self:LoadAnimation(0)
end

function UMG_SecondaryPasswordModify_C:OnDeactive()
end

function UMG_SecondaryPasswordModify_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_SecondaryPasswordModify_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.OnSecondPasswordStatusChange)
end

function UMG_SecondaryPasswordModify_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnClickCloseBtn)
  self.ForgotPassword.OnRichTextClick:Add(self, self.OnClickForget)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.OnSecondPasswordStatusChange)
end

function UMG_SecondaryPasswordModify_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_SecondaryPasswordModify_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnClickCloseBtn
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_SecondaryPasswordModify_C:ReqSecondaryPasswordGetAuthInfo()
  local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordGetAuthInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_GET_AUTH_INFO_REQ, reqMsg, self, self.OnSecondaryPasswordGetAuthInfoRsp, nil, false)
end

function UMG_SecondaryPasswordModify_C:OnSecondaryPasswordGetAuthInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.authInfo = rsp
  end
end

function UMG_SecondaryPasswordModify_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_SecondaryPasswordModify_C:OnClickCloseBtn")
  self:LoadAnimation(2)
end

function UMG_SecondaryPasswordModify_C:OnClickForget()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_SecondaryPasswordModify_C:OnClickForgetBtn")
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ForgetSecondaryPassword)
  self:DoClose()
end

function UMG_SecondaryPasswordModify_C:OnClickConfirm()
  if self.authInfo == nil then
    return
  end
  
  local function is_valid_format(str)
    if #str >= 4 and #str <= 8 and string.match(str, "^%d+$") then
      return true
    end
    return false
  end
  
  local inputTextOld = self.InputText_Old:GetText()
  local inputTextNew = self.InputText_New:GetText()
  local inputTextNewAgain = self.InputText_NewAgain:GetText()
  if is_valid_format(inputTextNew) and is_valid_format(inputTextNewAgain) then
    if inputTextNew == inputTextNewAgain then
      local oldPassword = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.EncryptInputText, inputTextOld, self.authInfo)
      local newPassword = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.EncryptInputText, inputTextNew, self.authInfo)
      if "" ~= oldPassword and "" ~= newPassword then
        local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordCheckReq()
        reqMsg.action = ProtoEnum.ZoneSecondaryPasswordAction.SPA_SET
        reqMsg.encode_secondary_password = newPassword
        reqMsg.old_encode_secondary_password = oldPassword
        reqMsg.pass_action = 1
        reqMsg.public_key_md5 = self.authInfo.public_key_md5
        _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_CHECK_REQ, reqMsg, self, self.OnSecondaryPasswordCheckRsp, nil, false)
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_change_pwd_mismatch)
    end
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_invalid_format)
  end
end

function UMG_SecondaryPasswordModify_C:OnSecondaryPasswordCheckRsp(rsp)
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
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_change_success)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
    self:DoClose()
  end
end

function UMG_SecondaryPasswordModify_C:OnSecondPasswordStatusChange(oldStatus, newStatus)
  if oldStatus == ProtoEnum.SecondaryPasswordStatus.SPS_Disable and newStatus == ProtoEnum.SecondaryPasswordStatus.SPS_Unset then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.Error_Code_2535))
    self:DoClose()
  end
end

return UMG_SecondaryPasswordModify_C

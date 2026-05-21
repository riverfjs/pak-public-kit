local UMG_SecondaryPasswordCancelForceDisable_C = _G.NRCPanelBase:Extend("UMG_SecondaryPasswordCancelForceDisable_C")

function UMG_SecondaryPasswordCancelForceDisable_C:OnActive()
  self:SetCommonPopUpInfo()
  self:InitTime()
  self.ContentText:SetText(LuaText.secondary_pwd_recall_request_screen_text)
  self:LoadAnimation(0)
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnDeactive()
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnDestruct()
  if self.Timer then
    _G.TimerManager:RemoveTimer(self.Timer)
    self.Timer = nil
  end
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnAddEventListener()
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnClickCloseBtn)
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_SecondaryPasswordCancelForceDisable_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = LuaText.secondary_pwd_recall_request_modal_title
  CommonPopUpData.Btn_LeftHandler = self.OnClickCloseBtn
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_SecondaryPasswordCancelForceDisable_C:OnClickCloseBtn")
  self:LoadAnimation(2)
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnClickConfirm()
  local reqMsg = _G.ProtoMessage:newZoneSecondaryPasswordForceDisableReq()
  reqMsg.action_type = ProtoEnum.ZoneSecondaryPasswordForceDisable.SPFD_CANCEL
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SECONDARY_PASSWORD_FORCE_DISABLE_REQ, reqMsg, self, self.OnSecondaryPasswordForceDisableRsp, nil, false)
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnSecondaryPasswordForceDisableRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.action_type == ProtoEnum.ZoneSecondaryPasswordForceDisable.SPFD_CANCEL then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.secondary_pwd_toast_recall_success)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OnSecondaryPasswordStatusChange, rsp.status, rsp.status_timestamp, rsp.default_free)
    self:DoClose()
  end
end

function UMG_SecondaryPasswordCancelForceDisable_C:InitTime()
  local passwordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
  if passwordInfo and passwordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
    self.LeftTimeTips:SetText(LuaText.secondary_pwd_recall_request_countdown)
    local statusStamp = passwordInfo.status_timestamp
    local currentTime = _G.ZoneServer:GetServerTime() / 1000
    if currentTime - statusStamp > 0 then
      self.leftTime = 259200 - (currentTime - statusStamp)
      if self.leftTime > 0 then
        self:SetTimeText(self.leftTime)
        self.Timer = _G.TimerManager:CreateTimer(self, "UMG_SecondaryPasswordCancelForceDisable_C", self.leftTime, self.OnTimerUpdate, self.OnTimerEnd, 1)
      else
        if statusStamp <= 0 then
          Log.Error("\228\188\160\229\133\165\231\154\132\229\128\146\232\174\161\230\151\182\230\151\182\233\151\180\230\136\179\229\188\130\229\184\184!!!")
        end
        self.Time:SetText("00:00:00")
      end
    end
  end
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnTimerUpdate()
  local statusStamp = 0
  local passwordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
  if passwordInfo and passwordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
    statusStamp = passwordInfo.status_timestamp
  end
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  if currentTime - statusStamp > 0 then
    self.leftTime = 259200 - (currentTime - statusStamp)
    if self.leftTime > 0 then
      self:SetTimeText(self.leftTime)
    end
  end
end

function UMG_SecondaryPasswordCancelForceDisable_C:OnTimerEnd()
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.Error_Code_2535))
  self:DoClose()
end

function UMG_SecondaryPasswordCancelForceDisable_C:SetTimeText(leftTime)
  local hour = math.floor(leftTime / 3600)
  local minute = math.floor((leftTime - 3600 * hour) / 60)
  local sec = math.floor(leftTime - 3600 * hour - 60 * minute)
  self.Time:SetText(string.format("%02d:%02d:%02d", hour, minute, sec))
end

return UMG_SecondaryPasswordCancelForceDisable_C

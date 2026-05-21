local OnlineModuleEvent = reload("NewRoco.Modules.Core.Online.OnlineModuleEvent")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")
local OnlineModule = NRCModuleBase:Extend("OnlineModule")

function OnlineModule:OnConstruct()
  self.data = self:SetData("OnlineModuleData", "NewRoco.Modules.Core.Online.OnlineModuleData")
  self.isLogin = false
  self.isLoginFromUI = false
  self.isHavePlayer = false
  self.isConnected = false
  self.getLocationCountdown = 0
  self.preLoginRspCode = 0
  self.delayCallIds = {}
  NRCEventCenter:RegisterEvent(self.moduleName, self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  NRCEventCenter:RegisterEvent(self.moduleName, self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnectProc)
  NRCEventCenter:RegisterEvent(self.moduleName, self, _G.NRCGlobalEvent.ON_STATECHANGED, self.OnStateChangedProc)
  _G.NRCEventCenter:RegisterEvent("OnlineModule", self, OnlineModuleEvent.SetIsHavePlayer, self.SetIsHavePlayer)
end

function OnlineModule:OnDestruct()
  for id, _ in pairs(self.delayCallIds) do
    _G.DelayManager:CancelDelayByIdEx(id)
  end
  self.delayCallIds = {}
end

function OnlineModule:OnActive()
  self.isLogin = false
  self.isHavePlayer = false
  self.isConnected = false
  self.preLoginRspCode = 0
  _G.ZoneServer:Init()
end

function OnlineModule:OnDeactive()
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnectProc)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_STATECHANGED, self.OnStateChangedProc)
end

function OnlineModule:OnConnected(errorCode, extend, extend2, extend3)
  self:Log("OnlineModule::OnConnected", errorCode, extend, extend2, extend3)
  if 0 == errorCode then
    self:Log("OnConnected Suc")
    self.isConnected = true
    if self.autoLogin then
      self:Login()
    end
  else
    self:LogError("OnlineModule:OnConnected fail", errorCode)
  end
end

function OnlineModule:OnDisconnectProc(errorCode, extend, extend2, extend3)
  self:Log("OnlineModule::OnDisconnectProc", errorCode, extend, extend2, extend3)
  self.isLogin = false
  self.isHavePlayer = false
  self.isConnected = false
end

function OnlineModule:OnStateChangedProc(state, errorCode, extend, extend2, extend3)
  self:Log("OnlineModule::OnStateChangedProc", state, errorCode, extend, extend2, extend3)
  self.isLogin = false
  self.isHavePlayer = false
  self.isConnected = false
end

function OnlineModule:GetLoginState()
  return self.isLogin
end

function OnlineModule:SetNetBarData(netbar_open_id, ret_code, net_bar_token, net_bar_cli_ip, net_bar_macs)
  self:Log("SetNetBarData", netbar_open_id, ret_code, net_bar_token, net_bar_cli_ip, net_bar_macs and table.concat(net_bar_macs, ";") or "nil")
  self.data:SetNetBarData(netbar_open_id, ret_code, net_bar_token, net_bar_cli_ip, net_bar_macs)
end

function OnlineModule:GetNetBarData()
  return self.data.net_bar_data
end

function OnlineModule:SetUserAccountInfo(openid, accessToken, loginChannel, reg_channel_dis, cli_startup_channel, extraInfo)
  self:Log("SetUserAccountInfo", " openid ", openid, " accessToken ", accessToken, " loginChannel ", loginChannel, " reg_channel_dis ", reg_channel_dis, " cli_startup_channel ", cli_startup_channel)
  self.data.openid = openid
  self.data.accessToken = accessToken
  if extraInfo then
    if not self.data.extraAccountInfo then
      self.data.extraAccountInfo = {}
    end
    self:Log("SetUserAccountInfo extraInfo", extraInfo)
    for k, v in pairs(extraInfo) do
      if "ctt" == k then
        if RocoEnv.PLATFORM_WINDOWS and self.data.cli_info ~= nil then
          if nil == self.data.cli_info.token_info then
            self.data.cli_info.token_info = ProtoMessage:newClientTokenInfo()
          end
          self.data.cli_info.token_info.wg_login_info = v
        end
      else
        self.data.extraAccountInfo[k] = v
      end
    end
  end
  self.data:SetLoginChannel(loginChannel)
  self.data:SetRegChannelDis(reg_channel_dis)
  self.data:SetCliStartUpChannel(cli_startup_channel)
  if self.data.cli_info ~= nil then
    if nil == self.data.cli_info.token_info then
      self.data.cli_info.token_info = ProtoMessage:newClientTokenInfo()
    end
    self.data.cli_info.token_info.access_token = accessToken
  end
  _G.ZoneServer:SetUserAccountInfo(openid, accessToken)
end

function OnlineModule:SetTpnsToken(tpns_token)
  self:Log("SetTpnsToken", " tpns_token ", tpns_token)
  self.data.tpns_token = tpns_token
  if self.data.cli_info ~= nil then
    if nil == self.data.cli_info.token_info then
      self.data.cli_info.token_info = ProtoMessage:newClientTokenInfo()
    end
    self.data.cli_info.token_info.tpns_token = tpns_token
  end
end

function OnlineModule:SetUserPayInfo(pf, payToken)
  self:Log("SetUserPayInfo")
  self.data.pf = pf
  self.data.payToken = payToken
  if self.data.cli_info ~= nil then
    if nil == self.data.cli_info.token_info then
      self:Log("newClientTokenInfo")
      self.data.cli_info.token_info = ProtoMessage:newClientTokenInfo()
    end
    self.data.cli_info.token_info.pf = self.data.pf
    self.data.cli_info.token_info.pay_token = self.data.payToken
  end
end

function OnlineModule:Connect(serverName, typeid, zoneid, ip, port, encryptMethod, keyMakingMethod, authType, authChannel, clbIpStrArr)
  self:Log("Connect", serverName, ip, port)
  self.data.serverName = serverName
  self.data.typeid = typeid
  self.data.zoneid = zoneid
  self.data.ip = ip
  self.data.port = port
  self.isLogin = false
  self.isHavePlayer = false
  self.isConnected = false
  self.autoLogin = false
  self.clbIpStrArr = clbIpStrArr
  _G.ZoneServer:Connect(typeid, zoneid, ip, port, encryptMethod, keyMakingMethod, authType, authChannel, clbIpStrArr)
end

function OnlineModule:Login(name)
  if name then
    self.data.userName = name
  end
  self.isLogin = false
  self.isHavePlayer = false
  self.data:UpdateDeviceInfo()
  local loginReq = ProtoMessage:newZoneLoginReq()
  loginReq.openid = self.data.openid
  loginReq.plat_info = self.data.plat_info
  loginReq.cli_info = self.data.cli_info
  loginReq.is_login = self.isLoginFromUI
  loginReq.quality = UE4.UNRCQualityLibrary.GetImageQuality()
  self.isLoginFromUI = false
  Log.Dump(loginReq, 99, "OnlineModule:Login")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_REQ, loginReq, self, self.OnLoginRsp, true, true)
  _G.ZoneServer:SetOnlineState(OnlineState.Logining)
end

function OnlineModule:OnLoginRsp(rsp)
  self:Log("OnLoginRsp ", rsp.ret_info.ret_code)
  local FeatureData = rsp.feature_data
  if FeatureData then
    _G.NRCSDKManager:OnLightFeatureReceived(FeatureData.feature_name, FeatureData.feature_data, FeatureData.data_len, FeatureData.data_crc)
  end
  if 0 == rsp.ret_info.ret_code then
    _G.GEMPostManager:GEMPostStepEvent("WhiteListLimit")
    local serverTime = rsp.svr_time
    _G.ZoneServer:SetServerTimeOnlyForInit(serverTime)
    if rsp.svr_time_zone then
      _G.ZoneServer:SetServerTimeZoneOffset(rsp.svr_time_zone)
    end
    self:Log("OnLoginRsp OnLoginSuc", rsp.player_info.brief_info.uin, rsp.player_info.brief_info.name)
    self:Log("OnLoginRsp zonesvr_buspp_inst_id:", rsp.player_info.brief_info.zonesvr_buspp_inst_id)
    _G.NRCNetworkManager:SetValidServerId(_G.ZoneServer.connectID, rsp.player_info.brief_info.zonesvr_buspp_inst_id)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_NEED_REGIST then
    self:Log("OnLoginRsp ERR_ZONE_NEED_REGIST")
    _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
    _G.GEMPostManager:GEMPostStepEvent("WhiteListLimit", tostring(rsp.ret_info.ret_code))
    self:Register(self.data.openid, self.data.userName)
    return
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_NOT_IN_WHITE_LIST then
    self:LogError("OnLoginRsp ERR_COMMON_NOT_IN_WHITE_LIST")
    _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
    _G.GEMPostManager:GEMPostStepEvent("WhiteListLimit", tostring(rsp.ret_info.ret_code))
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
    NRCEventCenter:DispatchEvent(LoginModuleEvent.WhiteListBlocked)
    Context:SetTitle(LuaText.onlinemodule_1):SetContent(string.format(LuaText.onlinemodule_2)):SetMode(DialogContext.Mode.OK):SetCallbackOkOnly(self, function()
      if RocoEnv.PLATFORM_WINDOWS and not string.IsNilOrEmpty(self.data.loginChannel) then
        UE4.UNRCStatics.QuitGame()
      end
    end)
    Log.Error("\231\153\189\229\144\141\229\141\149\233\153\144\229\136\182, device id: ", self.data.cli_info.dev_info.device_id)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    UE4.UNRCStatics.ClipboardCopy(self.data.cli_info.dev_info.device_id)
    return
  elseif ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_NOT_IN_CPU_WHITE_LIST and rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_NOT_IN_CPU_WHITE_LIST then
    self:LogError("OnLoginRsp ERR_COMMON_NOT_IN_CPU_WHITE_LIST")
    _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
    _G.GEMPostManager:GEMPostStepEvent("WhiteListLimit", tostring(rsp.ret_info.ret_code))
    local NotifyContent = LuaText.onlinemodule_3
    if _G.ENABLE_DEBUG_CPU_HADRWARE_INFO and not RocoEnv.IS_SHIPPING then
      NotifyContent = string.format([[
%s
(%s)]], NotifyContent, self.data.cli_info.dev_info.cpu_hardware)
    end
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
    NRCEventCenter:DispatchEvent(LoginModuleEvent.WhiteListBlocked)
    Context:SetTitle(LuaText.onlinemodule_1):SetContent(NotifyContent or ""):SetMode(DialogContext.Mode.OK):SetCallbackOkOnly(self, function()
      if RocoEnv.PLATFORM_WINDOWS and not string.IsNilOrEmpty(self.data.loginChannel) then
        UE4.UNRCStatics.QuitGame()
      end
    end)
    Log.Error("\231\153\189\229\144\141\229\141\149\233\153\144\229\136\182, cpu_hardware: ", self.data.cli_info.dev_info.cpu_hardware)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    if _G.ENABLE_DEBUG_CPU_HADRWARE_INFO then
      UE4.UNRCStatics.ClipboardCopy(self.data.cli_info.dev_info.cpu_hardware)
    end
    _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
    return
  else
    _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
    _G.GEMPostManager:GEMPostStepEvent("WhiteListLimit", tostring(rsp.ret_info.ret_code))
    if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_BAN then
      Log.Debug("OnLoginRsp ret_code=ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_BAN")
    elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CLIENT_VERSION_TOO_HIGH then
      self:Log("\232\181\132\230\186\144\231\137\136\230\156\172\232\191\135\233\171\152", tostring(rsp.ret_info.ret_code))
      local delayId = _G.DelayManager:DelayFrames(1, self.Logout, self)
      if delayId then
        self.delayCallIds[delayId] = true
      end
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local Context = DialogContext()
      Context:SetTitle(LuaText.TIPS):SetContent(LuaText.onlinemodule_14):SetMode(DialogContext.Mode.OK):SetCallback(self, function()
        NRCModuleManager:DoCmd(LoginModuleCmd.RestartLogin)
      end):SetCloseOnOK(true):SetButtonText(LuaText.onlinemodule_11):SetDebugInfo(ProtoCMD:GetMessageName(ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_RSP) .. rsp.ret_info.ret_code)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_DATA_VERSION_ERR then
      self:Log("\232\181\132\230\186\144\231\137\136\230\156\172\232\191\135\228\189\142", tostring(rsp.ret_info.ret_code))
      local delayId = _G.DelayManager:DelayFrames(1, self.Logout, self)
      if delayId then
        self.delayCallIds[delayId] = true
      end
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local Context = DialogContext()
      Context:SetTitle(LuaText.TIPS):SetContent(LuaText.onlinemodule_7):SetMode(DialogContext.Mode.OK):SetCallback(self, self.OnVersionErrorDialogResult):SetCloseOnOK(true):SetButtonText(LuaText.onlinemodule_11):SetDebugInfo(ProtoCMD:GetMessageName(ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_RSP) .. rsp.ret_info.ret_code)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_LOGIN_RATE_LIMITED then
      self.preLoginRspCode = rsp.ret_info.ret_code
      local TipsText = LuaText["Error_Code_" .. rsp.ret_info.ret_code]
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, TipsText)
      _G.ZoneServer:OpenWaitingUI("ServerRateLimit", LuaText["Error_Code_" .. rsp.ret_info.ret_code])
      local delayId = _G.DelayManager:DelaySeconds(5, function()
        self.preLoginRspCode = 0
        _G.ZoneServer:CloseWaitingUI("ServerRateLimit")
        _G.ZoneServer:DisConnect(false, false)
      end)
      if delayId then
        self.delayCallIds[delayId] = true
      end
    elseif ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_WEGAME_LOGIN_AUTH_FAILED and rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_WEGAME_LOGIN_AUTH_FAILED then
      if RocoEnv.PLATFORM_WINDOWS then
        self:Log("windows ctt auth fail")
        local failAuthInfo = rsp.wg_auth_result
        local displayErrCode = -1
        if failAuthInfo then
          displayErrCode = failAuthInfo.error_code or -1
          self:Log("error_message in wegameAuthResult is ", failAuthInfo.error_message or "nil")
        end
        local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
        local Context = DialogContext()
        Context:SetTitle(LuaText.TIPS):SetContent(LuaText.wg_login_tips and string.format(LuaText.wg_login_tips, displayErrCode) or "Error_code_" .. displayErrCode):SetMode(DialogContext.Mode.OK):SetCallback(self, self.OnWindowsVerifyCTTFailed):SetCloseOnOK(true):SetButtonText(LuaText.onlinemodule_11):SetDebugInfo(ProtoCMD:GetMessageName(ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_RSP) .. rsp.ret_info.ret_code)
        NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
      end
    else
      self:Log("\231\153\187\229\189\149\229\164\177\232\180\165", tostring(rsp.ret_info.ret_code))
      local delayId = _G.DelayManager:DelayFrames(1, self.Logout, self)
      if delayId then
        self.delayCallIds[delayId] = true
      end
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local Context = DialogContext()
      Context:SetTitle(LuaText.TIPS):SetContent(LuaText["Error_Code_" .. rsp.ret_info.ret_code]):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnDialogResult):SetCloseOnCancel(true):SetButtonText(LuaText.RETRY, LuaText.BACK):SetDebugInfo(ProtoCMD:GetMessageName(ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_RSP) .. rsp.ret_info.ret_code)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return
  end
  _G.ZoneServer:SetOnlineState(OnlineState.Logined)
  self.isLogin = true
  self.getLocationCountdown = 0
  self.loginData = rsp
  DataModelMgr.PlayerDataModel:SetLoginData(self.loginData)
  _G.DataModelMgr.PlayerDataModel.loginData = rsp
  local openid = rsp.player_info.brief_info.openid
  self:Log("Login Suc", openid, _G.GameSetting.LastLogin, self.data.serverName)
  if openid ~= _G.GameSetting.LastLogin or self.data.serverName ~= _G.GameSetting.LastLoginServer then
    _G.GameSetting.LastLogin = openid
    _G.GameSetting.LastLoginServer = self.data.serverName
    _G.GameSetting:Save()
  end
  self:Log("OnlineModule: SendAppleASALog")
  _G.GEMPostManager:SendAppleASALog()
  local uin = rsp.player_info and rsp.player_info.brief_info and rsp.player_info.brief_info.uin or 0
  NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ON_LOGIN, true, uin)
  if RocoEnv.PLATFORM_IOS then
    UE4.UNRCQualityLibrary.ReSetFrameQuality()
  end
end

function OnlineModule:OnDialogResult(result)
  self:Log("OnDialogResult", result)
  if result then
    self:Relogin()
  else
    _G.AppMain.BackToLogin()
  end
end

function OnlineModule:OnVersionErrorDialogResult(result)
  local BackToUpdate = true
  _G.AppMain.BackToLogin(BackToUpdate)
end

function OnlineModule:OnWindowsVerifyCTTFailed(result)
  local delayId = _G.DelayManager:DelayFrames(1, function()
    UE4.UNRCStatics.QuitGame()
  end)
  if delayId then
    self.delayCallIds[delayId] = true
  end
end

function OnlineModule:ConnectAndLogin(serverName, typeid, zoneid, ip, port, name, encryptMethod, keyMakingMethod, authType, authChannel, clbIpStrArr)
  self:Connect(serverName, typeid, zoneid, ip, port, encryptMethod or 0, keyMakingMethod or 0, authType, authChannel, clbIpStrArr)
  self.autoLogin = true
  self.data.userName = name
  self.isLoginFromUI = true
end

function OnlineModule:Logout()
  self.isLogin = false
  self.isHavePlayer = false
  self.isConnected = false
  _G.ZoneServer:DisConnect(true)
end

function OnlineModule:Relogin()
  self.isLogin = false
  self.isHavePlayer = false
  self.isConnected = false
  _G.ZoneServer:ReConnect()
end

function OnlineModule:Register(openid, name)
  self:Log("OnRegisterReq:", openid, name)
  self.data:UpdateDeviceInfo()
  local req = _G.ProtoMessage:newZoneRegisterReq()
  req.openid = openid
  req.name = name
  req.plat_info = self.data.plat_info
  req.cli_info = self.data.cli_info
  Log.Dump(req, 99, "OnlineModule:Register")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_REGISTER_REQ, req, self, self.OnRegisterRsp)
end

function OnlineModule:OnRegisterRsp(rsp)
  self:Log("OnRegisterRsp", rsp.ret_info.ret_code)
  if 0 == rsp.ret_info.ret_code then
    self.isLoginFromUI = true
    self:Login(self.data.userName)
  else
    self:LogError("OnRegisterRsp failed", rsp.ret_info.ret_code)
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    Context:SetTitle(LuaText.TIPS):SetContent(LuaText.Error_Code_13021):SetMode(DialogContext.Mode.OK):SetCallback(self, self.OnRegisterDialogResult):SetCloseOnCancel(true):SetIfHideCloseBtn(true)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function OnlineModule:OnRegisterDialogResult()
  _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
  local delayId = _G.DelayManager:DelayFrames(1, self.Logout, self)
  if delayId then
    self.delayCallIds[delayId] = true
  end
  _G.AppMain.BackToLogin()
end

function OnlineModule:OnTick(deltaTime)
  if self.isLogin and _G.ZoneServer:IsEnteredCell() then
    self:DoTickGetLocation(deltaTime)
  end
end

function OnlineModule:DoTickGetLocation(deltaTime)
  if self.getLocationCountdown then
    self.getLocationCountdown = self.getLocationCountdown + deltaTime
    if self.getLocationCountdown >= 0.5 then
      self.getLocationCountdown = 0
      if self.isHavePlayer then
        local LocalPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        if LocalPlayer then
          _G.NRCModuleManager:DoCmd(_G.UpdateUIModuleCmd.SetLocation, LocalPlayer)
        end
      end
    end
  end
end

function OnlineModule:SetIsHavePlayer(isHavePlayer)
  self.isHavePlayer = isHavePlayer
end

function OnlineModule:GetUserAccountInfo()
  return self.data
end

function OnlineModule:GetDeviceInfo()
  return self.data.cli_info.dev_info
end

function OnlineModule:UpdateDeviceInfoAsync(key, value)
  self.data:UpdateDeviceInfoAsync(key, value)
end

function OnlineModule:IsServerLimited()
  return self.preLoginRspCode == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_LOGIN_RATE_LIMITED
end

function OnlineModule:GetOpenID()
  if self.data then
    return self.data.openid
  end
  return nil
end

function OnlineModule:GetLoginChannel()
  if self.data then
    return self.data.loginChannel
  end
  return nil
end

function OnlineModule:GetPackageChannel()
  if self.data then
    return self.data.package_channel
  end
  return nil
end

function OnlineModule:SetPackageChannel(package_channel)
  if string.IsNilOrEmpty(package_channel) then
    return
  end
  Log.Debug("OnlineModule:SetPackageChannel ", package_channel)
  if self.data then
    self.data:SetChannel(package_channel)
  end
end

return OnlineModule

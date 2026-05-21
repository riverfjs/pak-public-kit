local rapidjson = require("rapidjson")
local LoginObserver = NRCClass()
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local JsonUtils = require("Common.JsonUtils")

function LoginObserver:Initialize()
  Log.PrintScreenMsg("LoginObserver replaced")
  Log.Debug("LoginObserver:Initialize")
end

function LoginObserver:notifyPayModule(LoginRet)
  local payInfo = {
    openId = tostring(LoginRet.openID),
    token = tostring(LoginRet.token),
    channel = tostring(LoginRet.channel),
    channelInfo = tostring(LoginRet.channelInfo),
    pf = tostring(LoginRet.pf),
    pfKey = tostring(LoginRet.pfKey),
    userName = tostring(LoginRet.userName)
  }
  Log.Dump(payInfo, 2, "Info from MSDK")
  _G.NRCModuleManager:DoCmd(PayModuleCmd.SetPayInfo, payInfo)
end

function LoginObserver:GetClientStartUpChannel(channel, extraJson)
  local cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
  if not extraJson then
    return cli_startup_channel
  end
  local extraData = rapidjson.decode(extraJson)
  if not extraData then
    return cli_startup_channel
  end
  if extraData.params then
    if type(extraData.params) == "string" then
      extraData = rapidjson.decode(extraData.params)
      Log.Warning("LoginObserver:ParseLaunchFrom decode params")
    elseif type(extraData.params) == "table" then
      Log.Warning("LoginObserver:ParseLaunchFrom params is table")
      extraData = extraData.params
    else
      Log.Warning("LoginObserver:ParseLaunchFrom params is not string or table")
      return cli_startup_channel
    end
  end
  if not extraData then
    return cli_startup_channel
  end
  if tostring(channel) == LoginEnum.ChannelNames.QQ then
    Log.Info("launchfrom ", tostring(extraData.launchfrom))
    if extraData.launchfrom and tostring(extraData.launchfrom) == "sq_gamecenter" then
      cli_startup_channel = Enum.CliStartUpChannel.CSUC_QQ_GAME_CENTER
    end
  elseif tostring(channel) == LoginEnum.ChannelNames.WeChat then
    if RocoEnv.PLATFORM_ANDROID then
      if extraData._wxobject_message_ext and tostring(extraData._wxobject_message_ext) == "WX_GameCenter" then
        cli_startup_channel = Enum.CliStartUpChannel.CSUC_WX_GAME_CENTER
      end
    elseif RocoEnv.PLATFORM_IOS and extraData.messageExt and "WX_GameCenter" == tostring(extraData.messageExt) then
      cli_startup_channel = Enum.CliStartUpChannel.CSUC_WX_GAME_CENTER
    end
  end
  return cli_startup_channel
end

function LoginObserver:OnLoginRetNotify(LoginRet)
  if not LoginRet then
    Log.Warning("LoginObserver:OnLoginRetNotify Get Nil Result")
    return
  end
  Log.Debug("LoginObserver:OnLoginRetNotify", LoginRet.retCode, LoginRet.thirdCode, "Show OpenID", LoginRet.openID, " reg_channel_dis ", LoginRet.regChannelDis, " channel ", tostring(LoginRet.channel))
  NRCModuleManager:DoCmd(LoginModuleCmd.CleanTimeoutTimer)
  local LoginFsm = LoginUtils.GetMainFsm()
  if not LoginFsm then
    Log.Warning("LoginObserver:OnLoginRetNotify not loginning", LoginRet.retCode, LoginRet.thirdCode)
    if not NRCModuleManager:GetModule("LoginModule") then
      if LoginRet.retCode ~= UE.MSDKError.SUCCESS then
        NRCEventCenter:DispatchEvent(LoginModuleEvent.OnReceiveLoginRetOutside, LoginRet)
      elseif LoginRet.retCode == UE.MSDKError.SUCCESS then
        self:notifyPayModule(LoginRet)
        local cli_startup_channel = self:GetClientStartUpChannel(tostring(LoginRet.channel), self.BaseRetExtraJson)
        local reg_channel_dis = LoginRet.regChannelDis
        UE4.UPushStatics.UnregisterXGPush("XG")
        UE4.UPushStatics.RegisterXGPush("XG", tostring(LoginRet.openID))
        Log.Debug("LoginObserver:OnLoginRetNotify openID ", LoginRet.openID, " token ", LoginRet.token, " channel ", LoginRet.channel, " reg_channel_dis ", reg_channel_dis, "cli_startup_channel ", cli_startup_channel, "tpns_token")
        NRCModuleManager:DoCmd(OnlineModuleCmd.SetUserAccountInfo, tostring(LoginRet.openID), tostring(LoginRet.token), tostring(LoginRet.channel), tostring(reg_channel_dis), cli_startup_channel)
        NRCModuleManager:DoCmd(PayModuleCmd.UpdateBalance)
      end
    end
    return
  end
  if LoginRet.retCode == UE.MSDKError.LOGIN_NO_CACHED_DATA then
    UE4.UPushStatics.UnregisterXGPush("XG")
    LoginFsm:SendEvent(LoginModuleEvent.LoginFail)
    _G.GEMPostManager:GEMPostStepEvent("MSDKLogin", LoginRet.retCode)
  elseif LoginRet.retCode == UE.MSDKError.LOGIN_CACHED_DATA_EXPIRED then
    UE4.UPushStatics.UnregisterXGPush("XG")
    LoginFsm:SendEvent(LoginModuleEvent.LoginFail)
    _G.GEMPostManager:GEMPostStepEvent("MSDKLogin", LoginRet.retCode)
  elseif LoginRet.retCode == UE.MSDKError.LOGIN_URL_USER_LOGIN then
    UE4.UPushStatics.UnregisterXGPush("XG")
    LoginFsm:SendEvent(LoginModuleEvent.LoginFail)
    _G.GEMPostManager:GEMPostStepEvent("MSDKLogin", LoginRet.retCode)
  elseif LoginRet.retCode == UE.MSDKError.LOGIN_NEED_LOGIN then
    UE4.UPushStatics.UnregisterXGPush("XG")
    LoginFsm:SendEvent(LoginModuleEvent.LoginFail)
    _G.GEMPostManager:GEMPostStepEvent("MSDKLogin", LoginRet.retCode)
  elseif LoginRet.retCode == UE.MSDKError.NEED_REALNAME then
    Log.Debug("NEED_REALNAME wait for success or fail notify")
  elseif LoginRet.retCode == UE.MSDKError.SUCCESS then
    Log.Debug("LoginObserver: LoginSuccess", LoginRet.retCode, LoginRet.openID)
    LoginUtils.GetLoginData():SetOpenID(tostring(LoginRet.openID))
    LoginUtils.GetLoginData():SetToken(tostring(LoginRet.token))
    LoginUtils.GetLoginData():SetChannel(tostring(LoginRet.channel))
    LoginUtils.GetLoginData():SetRegChannelDis(tostring(LoginRet.regChannelDis))
    LoginUtils.GetLoginData():SetUserName(LoginRet.userName)
    self:PersistUserName(LoginRet.userName)
    local cli_startup_channel = self:GetClientStartUpChannel(tostring(LoginRet.channel), self.BaseRetExtraJson)
    LoginUtils.GetLoginData():SetCliStartUpChannel(cli_startup_channel)
    NRCModuleManager:DoCmd(OnlineModuleCmd.SetUserAccountInfo, tostring(LoginRet.openID), tostring(LoginRet.token), tostring(LoginRet.channel), tostring(LoginRet.regChannelDis), cli_startup_channel)
    Log.Info("LoginObserver:OnLoginRetNotify openID ", LoginRet.openID, " token ", LoginRet.token, " channel ", LoginRet.channel, " reg_channel_dis ", LoginRet.regChannelDis, " cli_startup_channel ", cli_startup_channel, " username ", LoginRet.userName)
    self:notifyPayModule(LoginRet)
    _G.NRCModuleManager:DoCmd(PayModuleCmd.InitializeMidas)
    if tostring(LoginRet.channel) == LoginEnum.ChannelNames.QQ then
      NRCModuleManager:DoCmd(LoginModuleCmd.OverwriteAndSaveCondition, LoginEnum.Conditions.LoginChannel, LoginEnum.ChannelNames.QQ)
      _G.NRCSDKManager:CallTssSDKSetUserInfo(LoginEnum.TssSDKLoginType.QQ, LoginRet.openID)
    else
      NRCModuleManager:DoCmd(LoginModuleCmd.OverwriteAndSaveCondition, LoginEnum.Conditions.LoginChannel, LoginEnum.ChannelNames.WeChat)
      _G.NRCSDKManager:CallTssSDKSetUserInfo(LoginEnum.TssSDKLoginType.Wechat, LoginRet.openID)
    end
    LoginFsm:SendEvent(LoginModuleEvent.LoginSuccess)
    _G.GEMPostManager:GEMPostStepEvent("MSDKLogin")
    self:InstantiateXGPushObserver()
    UE4.UPushStatics.RegisterXGPush("XG", tostring(LoginRet.openID))
  else
    UE4.UPushStatics.UnregisterXGPush("XG")
    Log.Error("LoginObserver: LoginFailed", LoginRet.retCode, LoginRet.thirdCode, "Show OpenID", LoginRet.openID)
    LoginFsm:SendEvent(LoginModuleEvent.LoginFail)
    _G.GEMPostManager:GEMPostStepEvent("MSDKLogin", LoginRet.retCode)
  end
end

function LoginObserver:InstantiateXGPushObserver()
  Log.Debug("LoginObserver:InstantiateXGPushObserver")
  local Instance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not _G.GlobalConfig.bPushObserverSet then
    _G.GlobalConfig.bPushObserverSet = true
    local Observer = NewObject(UE.UPushObserver, Instance, "PushObserver", "Core.Service.GCloud.PushObserver")
    Instance.PushObserver = Observer
    UE.UPushStatics.SetPushObserver(Observer)
  end
end

function LoginObserver:SetClientStartupChannel(cli_startup_channel)
  self.cli_startup_channel = cli_startup_channel
end

function LoginObserver:OnBaseRetNotify(BaseRet)
  if not BaseRet then
    Log.Warning("LoginObserver:OnBaseRetNotify get Nil Result")
    return
  end
  Log.Warning("LoginObserver:OnBaseRetNotify methodNameID 111111 ", BaseRet.methodNameID, " retCode ", BaseRet.retCode, " extraJson ", BaseRet.extraJson)
  if 119 == BaseRet.methodNameID then
    Log.Warning("LoginObserver:OnBaseRetNotify methodNameID 111112", BaseRet.extraJson, " retCode ", BaseRet.retCode)
    self.BaseRetExtraJson = tostring(BaseRet.extraJson)
    local bShowSwitchUser = self:HandlerLoginPrivilegeFrom()
    if BaseRet.retCode == UE.MSDKError.SUCCESS then
      Log.Warning("LoginObserver:OnBaseRetNotify methodNameID 111113")
      local cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
      if LoginUtils.GetLoginData() then
        cli_startup_channel = LoginUtils.GetLoginData():GetCliStartUpChannel()
      else
        cli_startup_channel = self.cli_startup_channel
      end
      local loginState = ZoneServer:GetOnlineState()
      Log.Warning("LoginObserver:OnBaseRetNotify methodNameID 111114", tostring(loginState), "cli_startup_channel", tostring(cli_startup_channel))
      if loginState ~= OnlineState.Begin and loginState ~= OnlineState.Logouted and loginState ~= OnlineState.End and cli_startup_channel ~= Enum.CliStartUpChannel.CSUC_NONE then
        local req = ProtoMessage:newZoneClientStartUpReq()
        req.cli_startup_channel = cli_startup_channel
        Log.Warning("LoginObserver:OnBaseRetNotify methodNameID 111115", tostring(loginState))
        _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_START_UP_REQ, req)
        self.cli_startup_channel = nil
      end
    else
      Log.Info("LoginObserver: WakeUp Failed", BaseRet.retCode, BaseRet.thirdCode, BaseRet.extraJson)
      if BaseRet.retCode == UE.MSDKError.LOGIN_URL_USER_LOGIN or BaseRet.retCode == UE.MSDKError.LOGIN_NEED_LOGIN or BaseRet.retCode == UE.MSDKError.LOGIN_NEED_SELECT_ACCOUNT or BaseRet.retCode == UE.MSDKError.LOGIN_ACCOUNT_REFRESH then
        self:HandleDiffAccount(BaseRet)
      end
    end
  end
end

function LoginObserver:HandlerLoginPrivilegeFrom()
  local bShowSwitchUser = false
  local cli_startup_channel = Enum.CliStartUpChannel.CSUC_NONE
  local launchFrom = self:ParseLaunchFrom(self.BaseRetExtraJson)
  if launchFrom then
    Log.Warning("\232\167\163\230\158\144\229\136\176\231\154\132\229\144\175\229\138\168\230\157\165\230\186\144\229\173\151\230\174\181:", launchFrom)
    if "sq_gamecenter" == launchFrom then
      bShowSwitchUser = true
      cli_startup_channel = self:GetClientStartUpChannel(tostring(LoginEnum.ChannelNames.QQ), self.BaseRetExtraJson)
    elseif "WX_GameCenter" == launchFrom then
      bShowSwitchUser = true
      cli_startup_channel = self:GetClientStartUpChannel(tostring(LoginEnum.ChannelNames.WeChat), self.BaseRetExtraJson)
      Log.Warning("\231\148\168\230\136\183\228\187\142\229\190\174\228\191\161\230\184\184\230\136\143\228\184\173\229\191\131\229\144\175\229\138\168")
    else
      Log.Warning("\231\148\168\230\136\183\228\187\142\229\133\182\228\187\150\230\184\160\233\129\147\229\144\175\229\138\168:", launchFrom)
    end
  else
    Log.Warning("\230\156\170\232\131\189\232\167\163\230\158\144\229\136\176\229\144\175\229\138\168\230\157\165\230\186\144\229\173\151\230\174\181")
  end
  if LoginUtils.GetLoginData() then
    LoginUtils.GetLoginData():SetCliStartUpChannel(cli_startup_channel)
  else
    self:SetClientStartupChannel(cli_startup_channel)
  end
  return bShowSwitchUser
end

function LoginObserver:OnQrCodeNotify(QrCodeRet)
  Log.Debug("LoginObserver:OnQrCodeNotify")
  UE.UKismetSystemLibrary.LaunchURL(tostring(QrCodeRet.qrCodeUrl))
end

function LoginObserver:HandleDiffAccount(BaseRet)
  Log.Info("LoginObserver:HandleDiffAccount  ")
  if BaseRet.retCode == UE.MSDKError.LOGIN_NEED_SELECT_ACCOUNT then
    Log.Warning("LoginObserver:HandleDiffAccount LOGIN_NEED_SELECT_ACCOUNT")
    if _G.TipsModuleCmd.Dialog_OpenDialog then
      local Context = _G.DialogContext()
      Context:SetTitle(LuaText.Login_different_account4)
      Context:SetContent(LuaText.Login_different_account1)
      Context:SetMode(_G.DialogContext.Mode.OK_CANCEL)
      Context:SetDialogType(_G.DialogContext.DialogType.SystemNotice)
      Context:SetDialogTag(_G.DialogContext.DialogTag.DifferentAccount)
      Context:SetButtonText(LuaText.Login_different_account2, LuaText.Login_different_account3)
      Context:SetCallbackOkOnly(self, function()
        self:SwitchUser()
      end)
      Context:SetCallback(self, function()
        self:CancelSwitchUser()
      end)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context, nil, _G.Enum.UILayerType.UI_LAYER_TOP)
    else
      Log.Warning("LoginObserver:HandleDiffAccount TipsModuleCmd.Dialog_OpenDialog is nil")
    end
  elseif BaseRet.retCode == UE.MSDKError.LOGIN_NEED_LOGIN then
    Log.Warning("LoginObserver:HandleDiffAccount LOGIN_NEED_LOGIN,BackToLogin")
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.QQ, "", false)
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.WeChat, "", false)
    NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
    _G.AppMain.BackToLogin()
  elseif BaseRet.retCode == UE.MSDKError.LOGIN_ACCOUNT_REFRESH then
    Log.Warning("LoginObserver:HandleDiffAccount LOGIN_ACCOUNT_REFRESH")
  elseif BaseRet.retCode == UE.MSDKError.LOGIN_URL_USER_LOGIN then
    Log.Warning("LoginObserver:HandleDiffAccount LOGIN_URL_USER_LOGIN")
  else
    Log.Warning("LoginObserver:HandleDiffAccount bShowSwitchUser is false")
  end
end

function LoginObserver:SwitchUser()
  Log.Info("LoginObserver:SwitchUser")
  UE.ULoginStatics.Logout(LoginEnum.ChannelNames.QQ, "", false)
  UE.ULoginStatics.Logout(LoginEnum.ChannelNames.WeChat, "", false)
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  _G.AppMain.BackToLogin()
  UE.ULoginStatics.SwitchUser(true)
end

function LoginObserver:CancelSwitchUser()
  Log.Info("LoginObserver:CancelSwitchUser")
  UE.ULoginStatics.SwitchUser(false)
end

function LoginObserver:ParseLaunchFrom(extraJson)
  if not extraJson or "" == extraJson then
    Log.Warning("LoginObserver:ParseLaunchFrom extraJson is nil")
    return nil
  end
  local extraData = rapidjson.decode(extraJson)
  if not extraData then
    Log.Warning("LoginObserver:ParseLaunchFrom decode extraData is nil")
    return nil
  end
  local paramsData = extraData
  if extraData.params then
    if type(extraData.params) == "string" then
      paramsData = rapidjson.decode(extraData.params)
      Log.Warning("LoginObserver:ParseLaunchFrom decode params")
    elseif type(extraData.params) == "table" then
      Log.Warning("LoginObserver:ParseLaunchFrom params is table")
      paramsData = extraData.params
    else
      Log.Warning("LoginObserver:ParseLaunchFrom params is not string or table")
      return nil
    end
  end
  if paramsData.launchfrom and tostring(paramsData.launchfrom) == "sq_gamecenter" then
    return "sq_gamecenter"
  else
    Log.Warning("LoginObserver:ParseLaunchFrom android launchfrom is not sq_gamecenter")
  end
  if RocoEnv.PLATFORM_ANDROID then
    if paramsData._wxobject_message_ext and tostring(paramsData._wxobject_message_ext) == "WX_GameCenter" then
      return "WX_GameCenter"
    else
      Log.Warning("LoginObserver:ParseLaunchFrom android _wxobject_message_ext is nil")
    end
  elseif RocoEnv.PLATFORM_IOS then
    if paramsData.messageExt and "WX_GameCenter" == tostring(paramsData.messageExt) then
      return "WX_GameCenter"
    else
      Log.Warning("LoginObserver:ParseLaunchFrom ios messageExt is nil")
    end
  end
  if paramsData.launchfrom then
    return tostring(paramsData.launchfrom)
  end
  return nil
end

function LoginObserver:PersistUserName(userName)
  local loginUserInfo = JsonUtils.LoadSaved("LoginUserInfo", {})
  loginUserInfo.userName = userName
  JsonUtils.DumpSaved("LoginUserInfo", loginUserInfo)
  Log.Debug("LoginObserver: Persisted userName to local storage:", userName)
end

return LoginObserver

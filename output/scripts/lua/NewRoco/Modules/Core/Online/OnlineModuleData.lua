local OnlineModuleData = _G.NRCData:Extend("OnlineModuleData")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local CommonUtils = require("NewRoco.Utils.CommonUtils")

function OnlineModuleData:Ctor()
  NRCData.Ctor(self)
  self.openid = ""
  self.accessToken = ""
  self.loginChannel = ""
  self.loginChannelType = Enum.CliLoginChannel.CLC_NONE
  self.channelInfo = ""
  self.pf = ""
  self.payToken = ""
  self.tpns_token = ""
  self.cli_info = ProtoMessage:newClientInfo()
  self.cli_info.dev_info.device_id = AppMain:GetDeviceId()
  if RocoEnv.PLATFORM_WINDOWS then
    self.extraAccountInfo = {}
  end
  if not RocoEnv.PLATFORM_WINDOWS then
    self.package_channel = UE.ULoginStatics.GetConfigChannel()
  end
  self.cli_info.dev_info.package_channel = self.package_channel
  Log.Info("OnlineModuleData:package_channel", self.package_channel)
  local bag_item_use_page = 1
  self.cli_info.ext_info.bag_item_use_page = bag_item_use_page
  self.plat_info = ProtoMessage:newPlatInfo()
  local AppInfo = _G.App
  if AppInfo then
    self.cli_info.ver_info.cli_version = tonumber(AppInfo:GetAppRevision()) or 0
    self.cli_info.ver_info.cli_res_version = tonumber(AppInfo:GetResRevision()) or 0
    self.cli_info.ver_info.app_version = AppInfo:GetAppVersion()
    self.cli_info.ver_info.res_version = AppInfo:GetResVersion()
  else
    Log.Error("Failed to get app info")
  end
  if RocoEnv.PLATFORM_IOS then
    self.plat_info.plat_id = ProtoEnum.PlatType.PT_IOS
  elseif RocoEnv.PLATFORM_ANDROID then
    self.plat_info.plat_id = ProtoEnum.PlatType.PT_ANDROID
  elseif RocoEnv.PLATFORM_WINDOWS then
    if RocoEnv.IS_EDITOR then
      self.plat_info.plat_id = ProtoEnum.PlatType.PT_EDITOR
    else
      self.plat_info.plat_id = ProtoEnum.PlatType.PT_PC
    end
  elseif RocoEnv.PLATFORM_OPENHARMONY then
    self.plat_info.plat_id = ProtoEnum.PlatType.PT_HARMONY_OS
  end
  self.cli_info.dev_info.plat_id = self.plat_info.plat_id
  self.plat_info.world_id = 0
  Log.Dump(self.cli_info, 99, "LoginData self.cli_info")
  Log.Dump(self.plat_info, 99, "LoginData self.plat_info")
end

function OnlineModuleData:UpdateDeviceInfoAsync(key, value)
  if "user_agent" == key and self.cli_info then
    self.cli_info.dev_info.user_agent = tostring(value)
  end
end

function OnlineModuleData:UpdateDeviceInfo()
  local TDMInfo = UE.UTDMStatics.PullDeviceInfo()
  local NetworkInfo = UE.UNetworkStatics.GetNetworkDetail()
  self.cli_info.dev_info.cpu_hardware = string.format("%s|%s|%s", TDMInfo["CPU.Chipset"], TDMInfo["CPU.Count"], TDMInfo["CPU.Brand"] or "")
  self.cli_info.dev_info.density = TDMInfo.DPI
  if RocoEnv.PLATFORM_IOS then
    self.cli_info.dev_info.aid = TDMInfo.CAID
  elseif RocoEnv.PLATFORM_ANDROID then
    self.cli_info.dev_info.aid = TDMInfo.OAID
  elseif RocoEnv.PLATFORM_OPENHARMONY then
    self.cli_info.dev_info.aid = UE.UNRCDeviceInfoHelper.GetOAID()
  else
    self.cli_info.dev_info.aid = RocoEnv.MAC_ADDR
  end
  self.cli_info.dev_info.memory = TDMInfo.RAM
  self.cli_info.dev_info.device_info = TDMInfo.Device
  self.cli_info.dev_info.system_hardware = TDMInfo.Model
  self.cli_info.dev_info.system_software = TDMInfo["OS.Ver"]
  local State = NetworkInfo:state()
  if 2 == State then
    self.cli_info.dev_info.network = "Wifi"
  elseif 3 == State then
    self.cli_info.dev_info.network = "Other"
  elseif 4 == State then
    self.cli_info.dev_info.network = "WWAN"
  elseif 5 == State then
    self.cli_info.dev_info.network = "2G"
  elseif 6 == State then
    self.cli_info.dev_info.network = "3G"
  elseif 7 == State then
    self.cli_info.dev_info.network = "4G"
  elseif 8 == State then
    self.cli_info.dev_info.network = "5G"
  end
  self.cli_info.dev_info.telecom_oper = TDMInfo.SimCode
  if TDMInfo.ScreenHeight then
    self.cli_info.dev_info.screen_hight = TDMInfo.ScreenHeight
  end
  if TDMInfo.ScreenWidth then
    self.cli_info.dev_info.screen_width = TDMInfo.ScreenWidth
  end
  if TDMInfo.IMEI then
    self.cli_info.dev_info.IMEI = TDMInfo.IMEI
  end
  if not string.IsNilOrEmpty(UE.UNRCDeviceInfoHelper.GetCAID("DeviceToken", "PreVersion")) then
    local oldCaidWithVersion = string.gsub(UE.UNRCDeviceInfoHelper.GetCAID("DeviceToken", "PreVersion"), "%|", "$")
    self.cli_info.dev_info.old_caid = not string.IsNilOrEmpty(oldCaidWithVersion) and oldCaidWithVersion or ""
  end
  if RocoEnv.PLATFORM_ANDROID then
    local bIsGameCloudEnv = CommonUtils.IsGameCloudEnv()
    self.cli_info.dev_info.is_gamematrix = bIsGameCloudEnv and 1 or 0
  end
end

function OnlineModuleData:GetOpenID()
  return self.openid
end

function OnlineModuleData:SetNetBarData(netbar_open_id, ret_code, net_bar_token, net_bar_cli_ip, net_bar_macs)
  self.net_bar_data = {}
  self.net_bar_data.open_id = netbar_open_id
  self.net_bar_data.net_bar_ret_code = ret_code
  self.net_bar_data.net_bar_token = net_bar_token
  self.net_bar_data.net_bar_client_ip = net_bar_cli_ip
  self.net_bar_data.net_bar_macs = net_bar_macs
  Log.Debug("OnlineModuleData:SetNetBarData ", netbar_open_id, ret_code, net_bar_token, net_bar_cli_ip, net_bar_macs and table.concat(net_bar_macs, ";") or "nil")
end

function OnlineModuleData:GetNetBarOpenId()
  if self.net_bar_data then
    return self.net_bar_data.open_id
  end
  return nil
end

function OnlineModuleData:GetNetBarReqRetCode()
  if self.net_bar_data then
    return self.net_bar_data.net_bar_ret_code
  end
  return nil
end

function OnlineModuleData:GetNetBarToken()
  if self.net_bar_data then
    return self.net_bar_data.net_bar_token
  end
  return nil
end

function OnlineModuleData:GetNetBarCliIp()
  if self.net_bar_data then
    return self.net_bar_data.net_bar_client_ip
  end
  return nil
end

function OnlineModuleData:GetNetBarMacs()
  if self.net_bar_data then
    return self.net_bar_data.net_bar_macs
  end
  return nil
end

function OnlineModuleData:SetLoginChannel(loginChannelStr)
  self.loginChannel = loginChannelStr
  if loginChannelStr == LoginEnum.ChannelNames.QQ then
    self.loginChannelType = Enum.CliLoginChannel.CLC_QQ
  elseif loginChannelStr == LoginEnum.ChannelNames.WeChat then
    self.loginChannelType = Enum.CliLoginChannel.CLC_WX
  else
    self.loginChannelType = Enum.CliLoginChannel.CLC_NONE
  end
  self.plat_info.cli_login_channel = self.loginChannelType
end

function OnlineModuleData:SetCliStartUpChannel(cliStartUpChannel)
  self.cli_startup_channel = cliStartUpChannel
  self.plat_info.cli_startup_channel = self.cli_startup_channel
end

function OnlineModuleData:SetRegChannelDis(reg_channel_dis)
  self.reg_channel_dis = reg_channel_dis
  self.plat_info.reg_channel = reg_channel_dis
end

function OnlineModuleData:SetChannel(channel)
  if channel then
    Log.Debug("OnlineModuleData:SetChannel" .. channel)
  end
  self.package_channel = channel
  self.cli_info.dev_info.package_channel = self.package_channel
end

return OnlineModuleData

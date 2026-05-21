local Singleton = _G.Singleton
local GEMPostManager = Singleton:Extend("GEMPostManager")
local boundaryContent = "--MyBoundary"
local TLogData1 = "Content-Disposition: form-data; name = \"name\""
local TLogData2 = "Content-Disposition: form-data; name = \"payload\""
local rapidjson = require("rapidjson")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")

function GEMPostManager:Ctor(name)
  self.name = name or "GEMPostManager"
  Singleton.Ctor(self, self.name)
  self.DeviceDetailInfo = "nil"
  self:SetGEMState()
end

function GEMPostManager:Free()
  Singleton.Free(self)
end

function GEMPostManager:SendNRCTLog(key, value)
  local finalContent = string.format("--%s\r\n%s\r\n\r\n%s\r\n--%s\r\n%s\r\n\r\n%s\r\n--%s--\r\n", boundaryContent, TLogData1, key, boundaryContent, TLogData2, value, boundaryContent)
  local TLogUrl = "http://innerhttp-test.nrc.woa.com/nrc-main/http/tlog"
  if _G.AppMain:GetFormalPipeline() then
    TLogUrl = "https://prod-http-01.nrc.qq.com/tlog"
  end
  UE4.UNRCStatics.HttpPost(TLogUrl, finalContent, boundaryContent)
end

function GEMPostManager:InitDeviceDetailInfo()
  if not self.DeviceDetailInfo or self.DeviceDetailInfo == "nil" then
    self.DeviceDetailInfo = DeviceUtils.GetDeviceDetailInfo() or "nil"
    self.DeviceDetailInfo = string.gsub(self.DeviceDetailInfo, "\n", ",")
    self.DeviceDetailInfo = string.gsub(self.DeviceDetailInfo, "|", "%%7C")
    self.DeviceDetailInfo = string.gsub(self.DeviceDetailInfo, "=", "%%3D")
    self.DeviceDetailInfo = string.gsub(self.DeviceDetailInfo, "&", "%%26")
  end
end

function GEMPostManager:SendTLog(stateId)
  local bLogin = 0
  if _G.OnlineModuleCmd and _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetLoginState) then
    bLogin = 1
  else
    bLogin = 0
  end
  local uin = 0
  local roleName = "unknown"
  if 1 == bLogin then
    uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
  else
    uin = 0
  end
  local loginIp = "nil"
  local platId = AppMain:GetPlatId() or -1
  local worldId = 0
  local openId = "nil"
  local deviceId = AppMain:GetDeviceId() or "nil"
  local systemHardWare = "nil"
  local systemSoftWare = "nil"
  local netWork = "nil"
  local IMEI = deviceId
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    local deviceInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetDeviceInfo)
    if needData and type(needData) == "table" then
      loginIp = needData.ip or "nil"
      worldId = needData.plat_info.world_id or 0
      openId = needData.openid or "nil"
    end
    if deviceInfo and type(deviceInfo) == "table" then
      systemHardWare = deviceInfo.system_hardware or "nil"
      systemSoftWare = deviceInfo.system_software or "nil"
      netWork = deviceInfo.network or "nil"
      IMEI = deviceInfo.IMEI or deviceId
    end
  end
  self:InitDeviceDetailInfo()
  local value1 = "ClientLoginInfoFlow"
  local tempString = "ClientLoginInfoFlow|%d|%s|%s|%s|%s|%s|%d|%d|%s|%d|%s|%s|%d|%s|%s|%s|%s|%s|%s"
  local deviceInfo = string.gsub(RocoEnv.DEVICE_INFO, "|", "-")
  local MacAddr = deviceId
  local System = deviceInfo
  local CAID = AppMain:GetCAID() or "nil"
  local OAID = AppMain:GetOAID() or "nil"
  local LoginChannel = self:GetPackageChannel()
  local GameAppID = self:GetGameAppID()
  local value2 = string.format(tempString, bLogin, os.date("%Y-%m-%d %H:%M:%S"), IMEI, System, MacAddr, loginIp, platId, worldId, openId, uin, roleName, netWork, 1, stateId, self.DeviceDetailInfo, CAID, OAID, LoginChannel, GameAppID)
  self:SendNRCTLog(value1, value2)
end

function GEMPostManager:GetGameAppID()
  local gameAppID = "nil"
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if playerInfoData and playerInfoData.loginChannel then
    if string.lower(playerInfoData.loginChannel) == "wechat" then
      gameAppID = "wxdca9f9a612d43085"
    elseif string.lower(playerInfoData.loginChannel) == "qq" then
      gameAppID = "1110613799"
    end
  end
  return gameAppID
end

function GEMPostManager:GetPackageChannel()
  if not RocoEnv.PLATFORM_WINDOWS then
    if not self.MobilePackageChannel then
      self.MobilePackageChannel = UE.ULoginStatics.GetConfigChannel() or "nil"
    end
    return self.MobilePackageChannel
  else
    return _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetPackageChannel) or "nil"
  end
end

function GEMPostManager:GEMPostStepEvent(actionName, errorMsg)
  if not _G.RocoEnv.IS_EDITOR then
    local GEMStepId = self:GetGEMBigState(actionName)
    local ErrorMessage = "success"
    local status = 0
    if errorMsg then
      status = 1
      ErrorMessage = tostring(errorMsg)
    else
      status = 0
    end
    if GEMStepId then
      Log.Debug("[GEMPostManager:GEMPostStepEvent]", GEMStepId, status, ErrorMessage)
      self:SendTLog(tostring(GEMStepId))
      if "EnterBigWorld" ~= actionName then
        _G.NRCSDKManager:PostLoginStepEvent("login", GEMStepId, status, 0, ErrorMessage, "", false, false)
      else
        _G.NRCSDKManager:PostLoginStepEvent("login", GEMStepId, status, 0, ErrorMessage, "", false, true)
      end
    end
  end
end

function GEMPostManager:SetGEMState()
  self.GEMState = {
    "AgreementsAccepted",
    "UpdateAppSuccess",
    "UpdateDolphinRes",
    "DeviceInfoReport",
    "BlackListLimit",
    "PSOAndDownloadStart",
    "PSOEnd",
    "ResDownloadEnd",
    "OpenLoginLevel",
    "MSDKLogin",
    "ShowLoginPanel",
    "OpenAnnouncement",
    "WhiteListLimit",
    "KickOutNotify",
    "ClickNameButton",
    "EnterLoading",
    "EnterLoadingEnd",
    "EnterSequenceEnd",
    "CommonLoadingEnd",
    "EnterBigWorld"
  }
  self.GEMStatePC = {
    "AgreementsAccepted",
    "UpdateAppSuccess",
    "UpdateDolphinRes",
    "PSOAndDownloadStart",
    "PSOEnd",
    "ResDownloadEnd",
    "OpenLoginLevel",
    "DeviceInfoReport",
    "BlackListLimit",
    "MSDKLogin",
    "ShowLoginPanel",
    "OpenAnnouncement",
    "WhiteListLimit",
    "KickOutNotify",
    "ClickNameButton",
    "EnterLoading",
    "EnterLoadingEnd",
    "EnterSequenceEnd",
    "CommonLoadingEnd",
    "EnterBigWorld"
  }
end

function GEMPostManager:GetGEMBigState(stateName)
  local StateList
  if RocoEnv.PLATFORM_WINDOWS then
    StateList = self.GEMStatePC
  else
    StateList = self.GEMState
  end
  for k, v in ipairs(StateList) do
    if v == stateName then
      return k
    end
  end
end

function GEMPostManager:GetRoleDataForTLog()
  local roleLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() or 0
  return string.format("%s|%d", self:GetGeneralRoleDataForTLog(), roleLevel)
end

function GEMPostManager:GetGeneralRoleDataForTLog()
  local gameSvrId = "nil"
  local eventTimeStr = os.date("%Y-%m-%d %H:%M:%S")
  local gameAppId = "1110613799"
  local platId = AppMain:GetPlatId() or -1
  local zoneAreaId = 0
  local openId = "nil"
  local roleId = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or "nil"
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if accountInfo then
    gameSvrId = accountInfo.serverName or "nil"
    openId = accountInfo.openid or "nil"
    zoneAreaId = accountInfo.plat_info and accountInfo.plat_info.world_id or 0
  end
  return string.format("%s|%s|%s|%d|%d|%s|%s|%s", gameSvrId, eventTimeStr, gameAppId, platId, zoneAreaId, openId, roleId, roleName)
end

function GEMPostManager:SendActivityTLog(activityId)
  local key = "ActivityLog"
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local platId = -1
  local openId = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local playerLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local gameAppId = "1110613799"
  if accountInfo then
    platId = accountInfo.plat_info.plat_id or -1
    openId = accountInfo.openid or "nil"
  end
  local tempString = "ActivityLog|%s|%s|%s|%d|%d|%s|%s|%s|%d|%s"
  local value = string.format(tempString, "0", os.date("%Y-%m-%d %H:%M:%S"), gameAppId, platId, "0", openId, uin, playerName, playerLv, activityId)
  self:SendNRCTLog(key, value)
end

function GEMPostManager:SendHDVideoPlayFaildataLog()
  local key = "HDvideoPlayFaildataLog"
  local roleDataStr = self:GetRoleDataForTLog()
  self:InitDeviceDetailInfo()
  local netWork = "nil"
  local clientVersion = AppMain:GetAppVersion() or "nil"
  local systemSoftWare = "nil"
  local systemHardWare = "nil"
  local cpuHardware = "nil"
  local memory = 0
  if _G.OnlineModuleCmd then
    local deviceInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetDeviceInfo)
    if deviceInfo and type(deviceInfo) == "table" then
      systemHardWare = deviceInfo.system_hardware or "nil"
      systemSoftWare = deviceInfo.system_software or "nil"
      netWork = deviceInfo.network or "nil"
      cpuHardware = deviceInfo.cpu_hardware or "nil"
      Log.Info("deviceInfo.memory ", deviceInfo.memory)
      memory = tonumber(deviceInfo.memory) or 0
    end
  end
  local tempString = "HDvideoPlayFaildataLog|%s|%s|%s|%s|%s|%s|%s|%d"
  local value = string.format(tempString, roleDataStr, self.DeviceDetailInfo, netWork, clientVersion, systemSoftWare, systemHardWare, cpuHardware, memory)
  Log.Info("GEMPostManager:SendHDvideoPlayFaildataLog value:", value)
  self:SendNRCTLog(key, value)
end

function GEMPostManager:SendExitLog(typeEnum, id)
  local key = "ExitLog"
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local platId = -1
  local openId = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local playerLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local gameAppId = "1110613799"
  if accountInfo then
    platId = accountInfo.plat_info.plat_id or -1
    openId = accountInfo.openid or "nil"
  end
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerPos = UE4.FVectorZero
  if localPlayer then
    playerPos = localPlayer:GetActorLocation()
  end
  local tempString = "ExitLog|%s|%s|%s|%d|%s|%s|%d|%s|%d|%f|%f|%f|%d|%d"
  local value = string.format(tempString, "0", os.date("%Y-%m-%d %H:%M:%S"), gameAppId, platId, "0", openId, uin, playerName, playerLv, playerPos.X, playerPos.Y, playerPos.Z, typeEnum, id)
  self:SendNRCTLog(key, value)
end

function GEMPostManager:SendOptionChangeTLog(ParamSet)
  if _G.RocoEnv.IS_EDITOR then
    return
  end
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local key = "OptionChange"
  local svrID = "0"
  local appID = "1110613799"
  local platID = -1
  local zoneAreaID = 0
  local openID = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  if accountInfo then
    svrID = accountInfo.serverName or "0"
    platID = accountInfo.plat_info.plat_id or -1
    openID = accountInfo.openid or "nil"
    zoneAreaID = accountInfo.plat_info.world_id or 0
  end
  local DisplayMode = 1
  local Resolution = ""
  local bPC = _G.RocoEnv.PLATFORM == "PLATFORM_WINDOWS"
  if bPC then
    local cur_x, cur_y, ResolutionIndex = UE4.UNRCQualityLibrary.GetPCResolution()
    DisplayMode = ResolutionIndex > 1 and 0 or 1
    Resolution = string.format("%d*%d", cur_x, cur_y)
  else
    Resolution = string.format("%d*%d", UE4.UNRCQualityLibrary.GetMobileResolution())
  end
  ParamSet.BrightLevel = math.floor((UE4.UNRCQualityLibrary.GetSceneColorIntensity() - 0.2) / 1.6 * 100 + 0.5)
  ParamSet.Resolution = Resolution
  ParamSet.DisplayMode = DisplayMode
  local tempString = "OptionChange|%s|%s|%s|%d|%d|%s|%s|%s|%s|%s|%d|%d|%s|%d"
  local value = string.format(tempString, svrID, os.date("%Y-%m-%d %H:%M:%S"), appID, platID, zoneAreaID, openID, uin, playerName, ParamSet.QualityId, ParamSet.QualityName, ParamSet.QualityLevel, ParamSet.BrightLevel, ParamSet.Resolution, ParamSet.DisplayMode)
  self:SendNRCTLog(key, value)
end

function GEMPostManager:SendPayFailEvent(errorCode, failReason)
  if _G.RocoEnv.IS_EDITOR then
    return
  end
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local key = "PayEvent"
  local svrID = "0"
  local appID = "1110613799"
  local platID = -1
  local zoneAreaID = 0
  local openID = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  if accountInfo then
    svrID = accountInfo.serverName or "0"
    platID = accountInfo.plat_info.plat_id or -1
    openID = accountInfo.openid or "nil"
    zoneAreaID = accountInfo.plat_info.world_id or 0
  end
  local tmpStr = "PayEvent|%s|%s|%s|%s|%s|%s|%s|%s|%d|%s"
  failReason = tostring(failReason)
  failReason = string.gsub(failReason, "|", "%%7C")
  failReason = string.gsub(failReason, "\n", "%%0A")
  local value = string.format(tmpStr, svrID, os.date("%Y-%m-%d %H:%M:%S"), appID, platID, zoneAreaID, openID, uin, playerName, errorCode, failReason)
  self:SendNRCTLog(key, value)
end

function GEMPostManager:SendAppleASALog()
  if not RocoEnv.PLATFORM_IOS then
    Log.Warning("GEMPostManager:SendAppleASALog: not iOS platform")
    return
  end
  local key = "asaiadinfo"
  local AppleASA = AppMain:GetAppleASA()
  if nil == AppleASA then
    Log.Error("GEMPostManager:SendAppleASALog: AppleASA is nil")
    return
  else
    Log.Debug("GEMPostManager:SendAppleASALog: AppleASA ", AppleASA)
  end
  local JsonStr = tostring(AppleASA)
  local ok, data = pcall(rapidjson.decode, JsonStr)
  if not ok or type(data) ~= "table" then
    Log.Error("GEMPostManager:SendAppleASALog: json decode failed")
    return
  end
  local adId = data["iad-adId"] or 0
  local conversionType = data["iad-conversion-type"] or ""
  local orgId = data["iad-org-id"] or 0
  local clickDate = data["iad-click-date"] or ""
  local impressionDate = data["iad-impressionDate"] or ""
  local countryOrRegion = data["iad-country-or-region"] or ""
  local keywordId = data["iad-keyword-id"] or 0
  local campaignId = data["iad-campaign-id"] or 0
  local claimType = data["iad-claimType"] or ""
  local attribution = data["iad-attribution"] or false
  local attributionValue = 0
  if attribution then
    attributionValue = 1
  end
  local adgroupId = data["iad-adgroup-id"] or 0
  local asaDataString = string.format("%d|%d|%d|%s|%s|%s|%s|%d|%s|%d|%d", attributionValue or 0, orgId or 0, campaignId or 0, conversionType or "", claimType or "", clickDate or "", impressionDate or "", adgroupId or 0, countryOrRegion or "", keywordId or 0, adId or 0)
  local roleDataStr = self:GetRoleDataForTLog()
  local tempString = "%s|%s|%s"
  local value = string.format(tempString, key, roleDataStr, asaDataString)
  Log.Debug("GEMPostManager:SendAppleASALog: value ", value)
  self:SendNRCTLog(key, value)
end

return GEMPostManager

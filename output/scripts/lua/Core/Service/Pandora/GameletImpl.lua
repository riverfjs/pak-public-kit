local GameletImpl = Class()
local NRCSDKManagerEvent = reload("Core.Service.SDKManager.NRCSDKManagerEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local JsonUtils = require("Common.JsonUtils")
GameletImpl.PandoraActivityObjs = {}

function GameletImpl:OnGameletRefreshUserData()
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if playerInfoData.loginChannel == nil then
    Log.Debug("no valid playerInfoData")
    return
  end
  local userData = UE4.TMap("", "")
  local accountType = ""
  local appID = ""
  local area = 1
  userData:Add("sOpenId", playerInfoData.openid)
  if RocoEnv.PLATFORM_WINDOWS then
    if not RocoEnv.IS_EDITOR then
      accountType = "wegame"
      appID = "2002304"
      area = string.lower(playerInfoData.loginChannel) == "wechat" and 1 or string.lower(playerInfoData.loginChannel) == "qq" and 2
      userData:Add("sPartition", area)
    else
      accountType = string.lower(playerInfoData.loginChannel) == "wechat" and "wx" or "qq"
      appID = string.lower(playerInfoData.loginChannel) == "wechat" and "wxdca9f9a612d43085" or "1110613799"
      area = string.lower(playerInfoData.loginChannel) == "wechat" and 1 or 2
      userData:Add("sPlatID", "1")
    end
  elseif string.lower(playerInfoData.loginChannel) == "wechat" then
    appID = "wxdca9f9a612d43085"
    accountType = "wx"
    area = 1
  elseif string.lower(playerInfoData.loginChannel) == "qq" then
    appID = "1110613799"
    accountType = "qq"
    area = 2
  end
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
  userData:Add("sPlatID", (not RocoEnv.IS_EDITOR or not "1") and (not RocoEnv.PLATFORM_WINDOWS or not "2") and (not RocoEnv.PLATFORM_ANDROID or not "1") and (not RocoEnv.PLATFORM_IOS or not "0") and RocoEnv.PLATFORM_OPENHARMONY and "12")
  userData:Add("sRoleId", nil ~= roleName and roleName or "")
  userData:Add("sAccountType", accountType)
  userData:Add("sAppId", appID)
  userData:Add("sArea", area)
  userData:Add("sAccessToken", nil ~= playerInfoData.accessToken and playerInfoData.accessToken or "")
  userData:Add("sGameVer", nil ~= _G.AppMain:GetAppVersion() and _G.AppMain:GetAppVersion() or "")
  userData:Add("sServiceType", "rocom")
  UE.UGamelet.Get():RefreshUserdata(userData)
  return 0
end

function GameletImpl:OnGameViewCreated(widget, appInfo)
  Log.Debug("OnGameViewCreated invoked with appInfo: ", appInfo)
  if not string.IsNilOrEmpty(appInfo) then
    local msgTable = JsonUtils.StringToJson(appInfo)
    if not table.isEmpty(msgTable) then
      local activityId = msgTable.appId
      local activityObj = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, activityId)
      if UE4.UObject.IsValid(widget) and activityObj and activityObj.SetPandoraViewClass then
        if widget:GetClass() then
          activityObj:SetPandoraViewClass(widget:GetClass())
        else
          Log.Error("widget class is nil")
        end
      end
    end
  end
  Log.Error("not add to activity module")
end

function GameletImpl:OnGameletViewDestroyed(widget, appInfo)
  Log.Debug("OnGameletViewDestroyed invoked with appInfo: ", appInfo)
  if not string.IsNilOrEmpty(appInfo) then
    local msgTable = JsonUtils.StringToJson(appInfo)
    if not table.isEmpty(msgTable) and msgTable.appId then
      local activityId = msgTable.appId
      if _G.NRCModuleManager:GetModule("ActivityModule") then
        local activityObj = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, activityId)
        if activityObj and activityObj.SetActivityCompleted then
          activityObj:SetActivityCompleted()
        end
      end
    end
  else
    Log.Error("OnGameletViewDestroyed - appInfo is nil or empty")
  end
end

function GameletImpl:OnGameletSDKMessage(Msg)
  Log.Debug("NRCSDKManagerEvent.OnGameletSDKMessage invoked")
  local MsgTable = JsonUtils.StringToJson(Msg)
  if MsgTable.type ~= nil and MsgTable.type == "pandoraShowEntrance" then
    if nil ~= MsgTable.appId then
      local infoTable = {
        activityId = MsgTable.appId,
        activityName = MsgTable.appName,
        maintabId = MsgTable.maintabId or 1,
        priority = MsgTable.priority or 1,
        icon = MsgTable.icon or "",
        iconSelect = MsgTable.iconSelect or ""
      }
      if _G.NRCModuleManager:GetModule("ActivityModule") then
        _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.UploadLocalActivity, ActivityEnum.ActivitySource.Pandora, infoTable)
      else
        table.insert(GameletImpl.PandoraActivityObjs, infoTable)
      end
      Log.Debug("NRCSDKManagerEvent.OnNewGameletAppReady invoked")
      _G.NRCEventCenter:DispatchEvent(NRCSDKManagerEvent.OnNewGameletAppReady, MsgTable.appId, nil ~= MsgTable.appName and MsgTable.appName or "")
    end
  elseif MsgTable.type == nil or MsgTable.type == "pandoraShowRedpoint" then
  end
end

function GameletImpl:OnGameletReportData(eventName, data)
  Log.Debug(string.format("OnGameletReportData with eventName:%d and data:%s", eventName, data))
end

return GameletImpl

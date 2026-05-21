local WeGameObserver = NRCClass()
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local LoginModuleCmd = require("NewRoco.Modules.System.LoginModule.LoginModuleCmd")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")

function WeGameObserver:Initialize(Parent)
  self.Parent = Parent
end

function WeGameObserver:RailEventSystemStateChanged(eventParamState)
  Log.Debug("RailEventSystemStateChanged invoked with eventParamState", eventParamState)
  if eventParamState == UE4.RailSystemState.kSystemStatePlatformOffline or eventParamState == UE4.RailSystemState.kSystemStatePlatformExit or eventParamState == UE4.RailSystemState.kSystemStatePlayerOwnershipExpired or eventParamState == UE4.RailSystemState.kSystemStateGameExitByAntiAddiction then
    local Ctx = DialogContext()
    Ctx:SetTitle(LuaText.TIPS):SetContent(LuaText.quit_game_wegame_exit):SetMode(DialogContext.Mode.OK):SetCallback(self, function()
      Log.Debug("QuitGame since wegame callback system state changed")
      UE4.UNRCStatics.QuitGame()
    end):SetButtonText(LuaText.YES)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
  end
end

function WeGameObserver:RailEventSessionTicketGetSessionTicket(accountInfo)
  Log.Debug("RailEventSessionTicketGetSessionTicket invoked with accountInfo")
  if _G.NRCModuleManager:GetModule("LoginModule") then
    NRCModuleManager:DoCmd(LoginModuleCmd.SetConditionInData, LoginEnum.Conditions.LoginResCode, accountInfo.error_code)
    NRCModuleManager:DoCmd(LoginModuleCmd.CleanTimeoutTimer)
  end
  local LoginFsm = LoginUtils.GetMainFsm()
  if not LoginFsm then
    if accountInfo and 0 == accountInfo.error_code then
      Log.Debug("WeGameObserver RailEventSessionTicketGetSessionTicket accountInfo.error_code == 0")
    else
      if accountInfo and accountInfo.error_code then
        Log.Error("OnReceiveLoginRetOutside with error_code:", accountInfo.error_code)
      end
      NRCEventCenter:DispatchEvent(LoginModuleEvent.OnReceiveLoginRetOutside)
    end
    return
  end
  if 0 == accountInfo.error_code then
    UE.ULoginStatics.ReportLoginChannelID()
    local channelID = UE.ULoginStatics.GetMSDKConfigChannelID("")
    if not string.IsNilOrEmpty(channelID) then
      LoginUtils.GetLoginData():SetPackageChannel(channelID)
    end
    local OpenID = tostring(accountInfo.open_id:data())
    local Token = tostring(accountInfo.token:data())
    local Channel = tostring(accountInfo.channel:data())
    local ExtraStr = tostring(accountInfo.ext_str:data())
    if string.IsNilOrEmpty(ExtraStr) then
      Log.Error("ExtraStr is nil")
      ExtraStr = ""
    end
    LoginUtils.GetLoginData():SetOpenID(OpenID)
    LoginUtils.GetLoginData():SetChannel(Channel)
    LoginUtils.GetLoginData():SetToken(Token)
    LoginUtils.GetLoginData():SetUserName(tostring(accountInfo.user_name:data()))
    NRCModuleManager:DoCmd(OnlineModuleCmd.SetUserAccountInfo, OpenID, Token, Channel, "", "")
    if accountInfo.picture_url:data() then
      local extraLoginInfo = {
        avatarUrl = tostring(accountInfo.picture_url:data()),
        ctt = ExtraStr
      }
      LoginUtils.GetLoginData():SetExtraInfo(extraLoginInfo)
    else
      Log.Error("accountInfo.picture_url is nil")
    end
    local payInfo = {
      openId = tostring(accountInfo.open_id:data()),
      pf = tostring(accountInfo.pf:data()),
      pfKey = tostring(accountInfo.pf_key:data()),
      token = tostring(accountInfo.token:data())
    }
    Log.Dump(payInfo, 1, "WeGameObserver SetPayInfo")
    NRCModuleManager:DoCmd(PayModuleCmd.SetPayInfo, payInfo)
    if tostring(accountInfo.channel:data()) == LoginEnum.ChannelNames.QQ then
      NRCModuleManager:DoCmd(LoginModuleCmd.OverwriteAndSaveCondition, LoginEnum.Conditions.LoginChannel, LoginEnum.ChannelNames.QQ)
    else
      NRCModuleManager:DoCmd(LoginModuleCmd.OverwriteAndSaveCondition, LoginEnum.Conditions.LoginChannel, LoginEnum.ChannelNames.WeChat)
    end
    LoginFsm:SendEvent(LoginModuleEvent.LoginSuccess)
    _G.GEMPostManager:GEMPostStepEvent("RealNameCertification")
  else
    Log.Error("WeGameObserver OnRailEvent AccountLogin Failed with error_code:", accountInfo.error_code, ", and error_msg:", accountInfo.error_msg:data())
    LoginFsm:SendEvent(LoginModuleEvent.LoginFail)
    _G.GEMPostManager:GEMPostStepEvent("RealNameCertification", accountInfo.error_code ~= nil and accountInfo.error_code or -1)
  end
end

function WeGameObserver:RailEventQueryFriendsOnlineState(friendsOnlineInfo)
  Log.Debug("RailEventQueryFriendsOnlineState invoked with friendsOnlineInfo")
  local friends = friendsOnlineInfo:ToTable()
  if friends and table.len(friends) > 0 then
    _G.NRCEventCenter:DispatchEvent(NRCSDKManagerEvent.OnWeGameFriendStateUpdate, friends)
  else
    Log.Error("RailEventQueryFriendsOnlineState with no friend info")
  end
end

function WeGameObserver:QueryFriendsListResult(friendsInfo)
  Log.Debug("QueryFriendsListResult invoked with friendsInfo")
  local friends = friendsInfo:ToTable()
  if friends and table.len(friends) > 0 then
    local friendInfosTable = {}
    for _, friend in ipairs(friends) do
      table.insert(friendInfosTable, {
        openID = friend.OpenID,
        onlineState = friend.State,
        nickName = friend.NickName,
        avatarUrl = friend.AvatarUrl,
        isWeGameFriend = true,
        platformOpenID = friend.PlatformOpenID
      })
    end
    _G.NRCEventCenter:DispatchEvent(NRCSDKManagerEvent.OnWeGameFriendInfoUpdate, friendInfosTable)
  else
    Log.Error("QueryFriendsListResult with no friend info")
  end
end

function WeGameObserver:RailInviteFriendResult(result)
  Log.Debug("RailInviteFriendResult result: " .. result)
end

function WeGameObserver:OnBranchInfo(branchName, branchType, branchId, buildNumber, versionId)
  Log.Debug("branchName, branchType and branchId is ", tostring(branchName:data()), tostring(branchType:data()), tostring(branchId:data()))
  NRCModuleManager:DoCmd(LoginModuleCmd.SetConditionInData, LoginEnum.Conditions.WeGameBranchName, not string.IsNilOrEmpty(tostring(branchName:data())) and tostring(branchName:data()) or "")
  NRCModuleManager:DoCmd(LoginModuleCmd.SetConditionInData, LoginEnum.Conditions.WeGameBranchType, not string.IsNilOrEmpty(tostring(branchType:data())) and tostring(branchType:data()) or "")
  NRCModuleManager:DoCmd(LoginModuleCmd.SetConditionInData, LoginEnum.Conditions.WeGameBranchId, not string.IsNilOrEmpty(tostring(branchId:data())) and tostring(branchId:data()) or "")
end

function WeGameObserver:UnInitialize()
  self.Parent = nil
end

function WeGameObserver.OnReportLoginResult(ret, msg)
  Log.Debug("OnReportLoginResult with ret " .. ret .. " and msg " .. msg)
end

return WeGameObserver

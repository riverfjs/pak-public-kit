local JsonUtils = require("Common.JsonUtils")
local FullLoginFsm = require("NewRoco.Modules.System.LoginModule.FullLoginFsm")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local rapidjson = require("rapidjson")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local UpdateAppTask = require("Core.Service.GCloud.Tasks.UpdateAppTask")
local FsmEnum = require("NewRoco.Modules.Core.Fsm.FsmEnum")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")
local FullLoginFsmPC = require("NewRoco.Modules.System.LoginModule.FullLoginFsmPC")
local DebugUtility
if _G.AppMain:HasDebug() then
  DebugUtility = require("NewRoco.Modules.System.Debug.DebugUtility")
end
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local UpdateStageLocalText = require("NewRoco.Modules.System.UpdateUIModule.UpdateStageLocalText")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local CloudGameUtil = require("NewRoco.Modules.System.UpdateUIModule.CloudGameUtil")
local NoWifiNotciceMBThreshold = 20
local LoginModule = NRCModuleBase:Extend("LoginModule")

function LoginModule:OnConstruct()
  self.LoadLoginNoticeCallBackOwner = nil
  self.LoadLoginNoticeCallBack = nil
  self.HasShowedLowEndDeviceNotice = false
end

function LoginModule:OnDestruct()
  self.LoadNoticeCallBackOwner = nil
  self.LoadNoticeCallBack = nil
end

function LoginModule:RestartLogin()
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.OnDisconnected)
end

function LoginModule:AddEventListener()
  self.LoginFsm:RegisterEvent(FsmEnum.Events.EnterAction, self, self.OnLoginActionEnter)
  _G.NRCEventCenter:RegisterEvent("LoginModule", self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
  NRCEventCenter:RegisterEvent("CreatePlayerModule", self, LoginModuleEvent.EnableSelection, self.EnableSelection)
end

function LoginModule:RemoveEventListener()
  self.LoginFsm:RemoveEvent(FsmEnum.Events.EnterAction, self, self.OnLoginActionEnter)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.EnableSelection, self.EnableSelection)
end

function LoginModule:OnActive()
  Log.Debug("LoginModule:OnActive")
  self.CurrentPanelName = nil
  self.data = self:SetData("LoginData", "NewRoco.Modules.System.LoginModule.LoginData")
  if RocoEnv.PLATFORM_WINDOWS then
    _G.NRCSDKManager:GetBranchInfo()
  end
  UE4.UNRCStatics.SetEnvTime(0)
  if LoadingUIModuleCmd then
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseLoadingUI, 1)
  end
  self:RegPanel("CharacterPick", "UMG_CharacterPick", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, true)
  self:RegPanel("PrivacyTips", "UMG_Login_PrivacyTips", _G.Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, true)
  self:RegPanel("AnnouncementPanel", "Res/UMG_Announcement", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ScanLoginPanel", "UMG_Login_ScanCodePopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_Login_StrongPopUp", "UMG_Login_StrongPopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, false)
  if DebugUtility then
    DebugUtility.SetFullScreen()
  end
end

function LoginModule:StartLoginFsm()
  if RocoEnv.PLATFORM_WINDOWS then
    self.LoginFsm = FullLoginFsmPC()
  else
    self.LoginFsm = FullLoginFsm()
  end
  self:AddEventListener()
  Log.Debug("LoginModule:StartLoginFsm")
  local panelData = _G.NRCPanelRegisterData()
  panelData.panelName = LoginEnum.PanelNames.NRCLoginPanel
  panelData.panelPath = "/Game/NewRoco/Modules/System/LoginModule/UMG_Login_New"
  panelData.customDisableRendering = true
  panelData.isSingleTouchPanel = true
  panelData.enablePcEsc = false
  self:RegisterPanel(panelData)
  local MapleTask = require("Core.Service.GCloud.Tasks.MapleTask")
  if not self.Observer then
    self.Observer = MapleTask()
  end
  self:BindCameraToController()
  self.LoginFsm:Play()
end

function LoginModule:OnDeactive()
  self:UnRegisterAllCmd()
  self:ClearAllData()
  if self.LoginFsm then
    self:RemoveEventListener()
    self.LoginFsm:Stop()
  end
  if self.ChildFsms then
    for i = 1, #self.ChildFsms do
      self.ChildFsms[i]:Stop()
    end
    table.clear(self.ChildFsms)
  end
  if self.Observer then
    self.Observer:Stop()
    self.Observer = nil
  end
  self.EnterBigWorldDelayId = nil
end

function LoginModule:TrackFsm(fsm)
  if not self.ChildFsms then
    self.ChildFsms = {}
  end
  table.insert(self.ChildFsms, fsm)
end

function LoginModule:OnOpenMainPanel()
  self:OpenPanel(LoginEnum.PanelNames.NRCLoginPanel)
  self.CurrentPanelName = LoginEnum.PanelNames.NRCLoginPanel
end

function LoginModule:OnOpenScanLoginPanel()
  self:OpenPanel(LoginEnum.PanelNames.ScanLoginPanel)
  self.CurrentPanelName = LoginEnum.PanelNames.ScanLoginPanel
end

function LoginModule:TurnCamera()
  if self:HasPanel(LoginEnum.PanelNames.NRCLoginPanel) then
    local LoginPanel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
    LoginPanel:StartCamera()
  end
end

function LoginModule:OpenPreNRCPanel()
  self:OpenPanel(LoginEnum.PanelNames.PreNRCPanel)
  self.CurrentPanelName = LoginEnum.PanelNames.PreNRCPanel
end

function LoginModule:SetLauncherOpenId()
  local OnlineData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if OnlineData then
    OnlineData.openid = "skipmsdk"
  end
end

function LoginModule:GetTDirUrl()
  return self.data:GetTDirUrl()
end

function LoginModule:RefreshServerNode(NodeID)
  Log.Debug("start refresh server node")
  local suc = self.Observer:Start(self.data:GetOpenID(), self, self.OnReceiveServerNodeResult, NodeID)
  if suc then
    self.RefreshNodeTimeout = false
    if self.RefreshNodeDelay then
      _G.DelayManager:CancelDelayById(self.RefreshNodeDelay)
      self.RefreshNodeDelay = nil
    end
    self.RefreshNodeDelay = _G.DelayManager:DelaySeconds(30, self.OnReceiveServerNodeFail, self)
  else
    self:OnReceiveServerNodeFail()
  end
end

function LoginModule:OnReceiveServerNodeResult(Success, Content)
  _G.DelayManager:CancelDelayById(self.RefreshNodeDelay)
  if self.RefreshNodeTimeout then
    return
  end
  if Success then
    self:GetActiveServers(Content)
    NRCEventCenter:DispatchEvent(LoginModuleEvent.OnServerNodeUpdated, Content[1].flag == UE4.GTreeNodeFlag.TnFlagFine)
  else
    self:OnReceiveServerNodeFail()
  end
end

function LoginModule:OnReceiveServerNodeFail()
  Log.Error("Fail to receive server node from maple")
  self.RefreshNodeTimeout = true
  NRCEventCenter:DispatchEvent(LoginModuleEvent.OnServerNodeUpdated, false)
end

function LoginModule:RefreshServerList()
  Log.Debug("start refresh server list")
  local suc = self.Observer:Start(self.data:GetOpenID(), self, self.OnReceiveMapleResult)
  if suc then
    self.MapleTimeout = false
    self.MapleTimeoutDelay = DelayManager:DelaySeconds(30, self.OnMapleQueryTimeOut, self)
  end
end

function LoginModule:OnMapleQueryTimeOut()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  Log.Error("[LoginModule:OnMapleQueryTimeOut]")
  self.Observer:Stop()
  self:OnRecieveMapleFail()
end

function LoginModule:OnRecieveMapleFail()
  Log.Error("Fail to receive server list from maple")
  self.MapleTimeout = true
  self:GetActiveServers(JsonUtils.LoadDefaultServerList({}))
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  Panel:RefreshServerList()
  NRCEventCenter:DispatchEvent(LoginModuleEvent.OnServerListUpdated)
end

function LoginModule:GetActiveServers(InServerList)
  InServerList = InServerList or JsonUtils.LoadDefaultServerList({})
  local Channel = self.data:GetCondition(LoginEnum.Conditions.LoginChannel)
  local ActiveServers = {}
  local ChannelAsInt = {}
  local ChannelStr = Channel and Channel or ""
  ChannelAsInt = UE4.UNRCStatics.GetArrayFromGGameIni("/Script/NRC.Maple", ChannelStr .. "ChannelNames"):ToTable()
  local SelectedServerCache
  local DefaultServerChoice = 1
  local ServerInfo = string.split(tostring(AppMain.launchParams.servers), "|")
  local LauncherServerChoice = tonumber(ServerInfo[1])
  local BaseEnvironment = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.Maple", "BaseEnvironment")
  local AuditEnvironment = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.Maple", "AuditEnvironment")
  local PreEnvironment = UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.Maple", "PreEnvironment")
  local userDefineStr = AppMain.userDefineStr
  Log.Debug("userDefineStr  :  ", userDefineStr)
  local settings = {}
  if userDefineStr then
    for key, value in string.gmatch(userDefineStr, "([^&=]+)=([^&]*)") do
      if not settings[key] then
        settings[key] = {}
      end
      table.insert(settings[key], value)
    end
  end
  Log.Dump(settings, 3, "settings data")
  local MapleEnvironment
  if settings and table.containsKey(settings, "MapleId") then
    for _, value in ipairs(settings.MapleId) do
      MapleEnvironment = tostring(value)
    end
  end
  MapleEnvironment = MapleEnvironment or BaseEnvironment
  Log.Debug("MapleEnvironment  :  ", MapleEnvironment)
  for _, channel in pairs(ChannelAsInt) do
    Log.Debug("ChannelAsInt -- ", channel)
  end
  Log.Debug("BaseEnvironment -- ", BaseEnvironment)
  Log.Debug("AuditEnvironment -- ", AuditEnvironment)
  Log.Debug("PreEnvironment -- ", PreEnvironment)
  Log.Debug("MapleEnvironment -- ", MapleEnvironment)
  for _, server in pairs(InServerList) do
    if not (not _G.RocoEnv.IS_EDITOR and _G.AppMain:GetFormalPipeline()) or nil ~= LauncherServerChoice then
      table.insert(ActiveServers, server)
    else
      local ServerEnvironment = tostring(server.Environment)
      if RocoEnv.PLATFORM_WINDOWS and RocoEnv.IS_SHIPPING and table.contains(ChannelAsInt, server.Platform) then
        if not string.IsNilOrEmpty(self.data:GetCondition(LoginEnum.Conditions.WeGameBranchName)) and not string.IsNilOrEmpty(self.data:GetCondition(LoginEnum.Conditions.WeGameBranchType)) then
          local ifPreBranch = string.sub(self.data:GetCondition(LoginEnum.Conditions.WeGameBranchName), 1, string.len("Pre")) == "Pre"
          if table.contains(LoginEnum.DefaultReleaseBranchType, self.data:GetCondition(LoginEnum.Conditions.WeGameBranchType)) and not ifPreBranch then
            if ServerEnvironment == MapleEnvironment then
              table.insert(ActiveServers, server)
            end
          elseif ifPreBranch then
            if "3" == ServerEnvironment then
              table.insert(ActiveServers, server)
            end
          elseif ServerEnvironment == MapleEnvironment then
            table.insert(ActiveServers, server)
          end
        elseif ServerEnvironment == MapleEnvironment then
          table.insert(ActiveServers, server)
        end
      elseif table.contains(ChannelAsInt, server.Platform) and ServerEnvironment == MapleEnvironment then
        table.insert(ActiveServers, server)
      end
    end
  end
  if nil ~= LauncherServerChoice then
    for index, server in pairs(ActiveServers) do
      if server.id == LauncherServerChoice then
        Log.Debug("\230\156\137\229\144\175\229\138\168\229\153\168\229\143\130\230\149\176,\233\128\137\230\139\169", server.key, LauncherServerChoice)
        DefaultServerChoice = index
        break
      end
    end
  else
    local LastLogin = _G.GameSetting.LastLoginServer
    if not string.IsNilOrEmpty(LastLogin) then
      for index, server in pairs(ActiveServers) do
        if server.key == _G.GameSetting.LastLoginServer then
          Log.Debug("\230\156\137\228\184\138\228\184\128\230\172\161\233\128\137\230\139\169\231\154\132\231\187\147\230\158\156,\233\128\137\230\139\169", server.key, LauncherServerChoice)
          DefaultServerChoice = index
          break
        end
      end
    end
  end
  if DefaultServerChoice > 0 then
    SelectedServerCache = ActiveServers[DefaultServerChoice]
    if SelectedServerCache then
      Log.PrintScreenMsg("\233\187\152\232\174\164\233\128\137\230\139\169\231\154\132\230\156\141\229\138\161\229\153\168\230\152\175 %s", SelectedServerCache.key)
    end
  else
    Log.Error("\230\178\161\230\156\137\233\187\152\232\174\164\233\128\137\230\139\169\231\154\132\230\156\141\229\138\161\229\153\168")
  end
  self.data:SetServerList(ActiveServers)
  if RocoEnv.IS_SHIPPING then
    if #ActiveServers > 0 then
      self.data:SetServer(ActiveServers[DefaultServerChoice])
    else
      Log.Error("No valid server")
    end
    if SelectedServerCache then
      self.data:SetServer(SelectedServerCache)
    end
  else
    local SelectedServerName = "None"
    if SelectedServerCache then
      SelectedServerName = SelectedServerCache.key
      self.data:SetServer(SelectedServerCache)
    elseif #ActiveServers > 0 and ActiveServers[DefaultServerChoice] then
      SelectedServerName = ActiveServers[DefaultServerChoice].key
      self.data:SetServer(ActiveServers[DefaultServerChoice])
    end
    Log.PrintScreenMsg("\230\156\172\229\186\148\232\135\170\229\138\168\233\128\137\230\139\169" .. tostring(SelectedServerName) .. "\230\156\141\229\138\161\229\153\168\239\188\140\228\189\134\230\152\175\232\191\153\228\184\141\230\152\175shipping\229\140\133\230\137\128\228\187\165\230\178\161\230\156\137\232\135\170\229\138\168\233\128\137\230\139\169")
  end
  if SelectedServerCache and SelectedServerCache.flag == UE4.GTreeNodeFlag.TnFlagUnavailable and not _G.AppMain:HasLaunchParams() then
    _G.GEMPostManager:GEMPostStepEvent("OpenAnnouncement")
    self:LoadLoginNoticeData(self, function(Self, noticeList)
      if UE4.UNoticeStatics.IsLoginNotice() then
        _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.OpenAnnouncementPanel, noticeList)
      end
    end)
  end
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    Panel:OnServerSelected(self.data.selectedServer)
  end
  return ActiveServers
end

function LoginModule:OnReceiveMapleResult(Success, Content)
  DelayManager:CancelDelay(self.OnMapleQueryTimeOut)
  if self.MapleTimeout then
    return
  end
  if Success then
    local bDumpSuccess = JsonUtils.DumpDefaultServerList(Content)
    if not bDumpSuccess then
      Log.Error("DumpDefaultServerList failed")
    end
    self:GetActiveServers(Content)
  else
    self:OnRecieveMapleFail()
    Log.Error("MapleFail, check openid")
    return
  end
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    Panel:RefreshServerList()
  else
    Log.Error("LoginModule:OnReceiveMapleResult  LoginPanel is not ready")
  end
  NRCEventCenter:DispatchEvent(LoginModuleEvent.OnServerListUpdated)
end

function LoginModule:OverwriteAndSaveCondition(Condition, Value)
  Log.Debug("LoginModule:OverwriteAndSaveCondition", Condition, Value)
  local CachedConditions = JsonUtils.LoadSaved("LoginConditions", {})
  CachedConditions[Condition] = Value
  local Success = JsonUtils.DumpSaved("LoginConditions", CachedConditions)
  self.data:SetCondition(Condition, Value)
end

function LoginModule:ShowPlatformChoices(CompleteEvent)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  Panel:ShowPlatformLoginPanel(true, CompleteEvent)
end

function LoginModule:ResetDownloadBasePaksWithoutLoginFlag()
  _G.AppMain:SetIfDownloadBasePaksWithoutLogin(false)
  self.data:SetIfDownloadBasePaksWithoutLogin(false)
end

function LoginModule:RefreshUserName()
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  Panel:SetUsername(self.data:GetOpenID())
end

function LoginModule:SetSelectTabIndex(index)
  NRCEventCenter:DispatchEvent(LoginModuleEvent.ClearBtnSelection)
  self.selectBtnIndex = index
end

function LoginModule:GetSelectTabIndex()
  return self.selectBtnIndex
end

function LoginModule:HidePlatformChoices(CompleteEvent)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  Panel:ShowPlatformLoginPanel(false, CompleteEvent)
end

function LoginModule:ShowUserNameAndServer(TurnOn)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  Panel:ShowUserNameAndServer(TurnOn)
end

function LoginModule:ReportSensitive()
  UE.USensitiveStatics.SetCouldCollectSensitiveInfo(true)
  local InfoList = string.split(RocoEnv.DEVICE_INFO, "|")
  local Model
  if #InfoList >= 2 then
    Model = InfoList[1]
  else
    Model = RocoEnv.DEVICE_INFO
  end
  local Payload = {Model = Model}
  local PayloadStr = rapidjson.encode(Payload)
  Log.Debug("LoginModule:ReportSensitive", PayloadStr)
  UE.USensitiveStatics.SetSensitiveInfo(PayloadStr)
  UE.USensitiveStatics.SetCollectSensitiveInfo(PayloadStr)
end

function LoginModule:StartQQLogin(DoLogin)
  if DoLogin then
    if LoginUtils.Debug then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.LoginSuccess)
    else
      Log.Warning("LoginModule:StartQQLogin")
      if not self:LockLogin(true) then
        Log.Warning("LoginModule:StartQQLogin not locked, proceed login")
        local bUseQrCode = self.data:GetCondition(LoginEnum.Conditions.UseQrCodeLogin)
        if bUseQrCode then
          UE.ULoginStatics.Login(LoginEnum.ChannelNames.QQ, "", "", "{\"QRCode\":true}")
        else
          if not UE4.ULoginStatics.IsQQInstalled() and not UE4.UNRCStatics.IsRunningOnWindows() then
            UE.ULoginStatics.Login(LoginEnum.ChannelNames.QQ, "", "", "")
          else
            UE.ULoginStatics.Login(LoginEnum.ChannelNames.QQ, "", "", self:GetLoginExtraJson())
          end
          _G.ZoneServer:OpenWaitingUI("QQVXLogin", "")
          self.WaitingUIOn = true
        end
      else
        Log.Warning("waiting for loginret")
      end
    end
  else
    Log.Warning("LoginModule:StartQQLogOut")
    UE.UPushStatics.UnregisterXGPush("XG")
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.QQ, "", false)
  end
end

function LoginModule:OnLoginTimeOut()
  Log.Warning("[LoginModule][OnLoginTimeOut]")
  if self.WaitingUIOn then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.LoginFail)
  end
end

function LoginModule:CloseLoginWaitingUI()
  if self.WaitingUIOn then
    self.WaitingUIOn = false
    _G.ZoneServer:CloseWaitingUI("QQVXLogin")
  end
end

function LoginModule:StartVXLogin(DoLogin)
  if DoLogin then
    Log.Warning("LoginModule:StartVXLogin")
    if not self:LockLogin(true) then
      Log.Warning("LoginModule:StartVXLogin not locked, proceed login")
      local bUseQrCode = self.data:GetCondition(LoginEnum.Conditions.UseQrCodeLogin)
      if bUseQrCode then
        UE.ULoginStatics.Login(LoginEnum.ChannelNames.WeChat, "", "", "{\"QRCode\":true}")
      else
        if not UE4.ULoginStatics.IsVxInstalled() and not UE4.UNRCStatics.IsRunningOnWindows() then
          UE.ULoginStatics.Login(LoginEnum.ChannelNames.WeChat, "", "", self:GetLoginQRJson())
        else
          UE.ULoginStatics.Login(LoginEnum.ChannelNames.WeChat, "", "", self:GetLoginExtraJson())
        end
        self.WaitingUIOn = true
        _G.ZoneServer:OpenWaitingUI("QQVXLogin", "")
      end
    else
      Log.Warning("waiting for loginret")
    end
  else
    Log.Warning("LoginModule:StartVXLogout")
    UE.UPushStatics.UnregisterXGPush("XG")
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.WeChat, "", false)
  end
end

function LoginModule:LockLogin(ToLock)
  return false
end

function LoginModule:GetLoginQRJson()
  return "{\"QRCode\":true}"
end

function LoginModule:GetLoginExtraJson()
  local extra = ""
  if UE4.UNRCStatics.IsRunningOnWindows() then
    extra = "{\"login_use_msdk_webview\": 1, \"webview_type\": 1}"
  end
  return extra
end

function LoginModule:GetLoginExtraJsonUseH5()
  local extra = "{\"login_use_msdk_webview\": 1, \"webview_type\": 2}"
  return extra
end

function LoginModule:ShowCanvas(CanvasName, TurnOn, CompleteEvent)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    Panel:ShowCanvas(CanvasName, TurnOn, CompleteEvent)
  else
    Log.Error("\231\153\187\229\189\149ui\230\156\170\230\139\137\232\181\183")
  end
end

function LoginModule:PlayAnimation(CanvasName)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  Panel:DoPlayAnimation(CanvasName)
end

function LoginModule:SetProgress(Percent, Hint, Total, Now, Speed)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel and Hint then
    if string.find(Hint, LuaText.updateuimodule_29) then
      if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
        Hint = Hint .. " (" .. LuaText.Download_All_tips3 .. ")"
      end
      if Speed then
        Hint = Hint .. " " .. tostring(Speed)
      end
      if Now then
        Hint = Hint .. " " .. tostring(Now)
      end
      if Total then
        Hint = Hint .. "/" .. tostring(Total)
      end
    end
    Panel:SetProgress(Percent, Hint)
  end
end

function LoginModule:SetPanelIsDownloading(isDownloading)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    Panel:SetIsDownloading(isDownloading)
  end
end

function LoginModule:CheckIfShowDownloadResBtn()
  local bIsNeedDownloadBasePaks = _G.PufferUpdateResTask:IsNeedDownloadBasePaksWithPatch()
  Log.Debug("bIsNeedDownloadBasePaks: ", bIsNeedDownloadBasePaks)
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    Panel:SetIfShowResDownloadBtn(bIsNeedDownloadBasePaks)
    if not self.bHasShownDownloadBtnRedDot then
      self.bHasShownDownloadBtnRedDot = true
      Panel:SetIfShowResDownloadBtnRedDot(true)
    end
  end
end

function LoginModule:CheckIfShowNotificationBtn()
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if RocoEnv.PLATFORM_ANDROID then
    local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE4.ENRCPermissionType.Notifications)
    Panel:SetIfShowNotificationBtn(not bGranted)
  else
    Panel:SetIfShowNotificationBtn(false)
  end
end

function LoginModule:CheckDownloadBaseRes()
  self.data:SetDownloadBaseResFlag(false)
  if not _G.ZoneServer:IsConnected() then
    Log.Debug("\230\156\170\232\191\158\230\142\165\239\188\140\229\186\148\232\175\165\230\152\175\233\135\141\232\175\149\230\136\150\232\128\133\228\187\142\230\140\137\233\146\174\232\183\179\232\189\172\232\191\135\230\157\165\231\154\132\239\188\140\231\155\180\230\142\165\229\188\128\229\167\139\228\184\139\232\189\189")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DownloadBaseResAfterLogin)
    return
  end
  local bNeedToDownload = _G.PufferUpdateResTask:IsNeedDownloadBasePaksWithPatch()
  if bNeedToDownload then
    local bTaskFinish = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MINI_PACKAGE_DONE)
    Log.Debug("[LoginModule:CheckDownloadBaseRes]bTaskFinish: ", bTaskFinish)
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.CheckTaskIsFinished, bTaskFinish)
    _G.NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
    _G.NRCSDKManager:CloseGamelet()
    local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
    local GB = string.format("%.2f", SizeNeedToDownload / 1024 / 1024 / 1024)
    if bTaskFinish then
      local Context = DialogContext()
      local Content
      if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
        local AppendText = string.format([[

%s]], LuaText.Download_All_tips3)
        Content = string.format(LuaText.Download_All_tips1, AppendText, GB)
      else
        Content = string.format(LuaText.Download_All_tips1, "", GB)
      end
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
        if result then
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.BaseDownloadBtn)
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DownloadBaseResAfterLogin)
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.RefuseBaseDownloadBtn)
          self:PufferBackToSDKLoginSuccessState()
        end
      end):SetButtonText(LuaText.Download_All_button2, LuaText.Download_All_button1)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    else
      Log.Debug("[LoginModule:CheckDownloadBaseRes]New User And Need To Download Base Paks")
      local Context = DialogContext()
      local Content
      if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
        local AppendText = string.format([[

%s]], LuaText.Download_All_tips3)
        Content = string.format(LuaText.Download_All_tips2, AppendText, GB)
      else
        Content = string.format(LuaText.Download_All_tips2, "", GB)
      end
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
        if result then
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DelayDownloadBaseRes)
        else
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DownloadBaseResAfterLogin)
        end
      end):SetButtonText(LuaText.Download_All_button3, LuaText.Download_All_button2)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  else
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.CheckTaskIsFinished)
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.NoNeedToDownloadBaseRes)
  end
end

function LoginModule:CheckIfShowEnterBtn()
  local bDownloadBaseRes = self.data:GetDownloadBaseResFlag()
  if bDownloadBaseRes then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.ShowEnterBtn)
  else
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.NotShowEnterBtn)
  end
end

function LoginModule:AutoLoginAndEnterWorld()
  local Panel = self:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if _G.ZoneServer:IsConnected() then
    Panel:OnClickEnter()
  else
    self.data:SetEnterWorldWithoutDownloadRes(true)
    Panel:OnClickLogin()
  end
end

function LoginModule:PostPufferResAllUpdateDoneEvent()
  self:UnRegisterPufferEvents()
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.BaseResDownloadDone)
end

function LoginModule:RegisterPufferEvents()
  _G.NRCEventCenter:RegisterEvent("LoginModule", self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnDownloadBatchProgress)
  _G.NRCEventCenter:RegisterEvent("LoginModule", self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:RegisterEvent("LoginModule", self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
end

function LoginModule:UnRegisterPufferEvents()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchProgress, self.OnDownloadBatchProgress)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferDownloadBatchReturn, self.OnPufferDownloadBatchReturn)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnPufferNetworkChanged, self.OnPufferNetworkStatusChanged)
end

function LoginModule:DownloadBasePak()
  _G.NRCAutoDownloadManager:RemoveAllDownloadTasks()
  self.data:SetDownloadBaseResFlag(true)
  self:RegisterPufferEvents()
  self:StartDownloadBaseRes()
end

function LoginModule:OnPufferInitFailed(ErrorCode)
  Log.Error("[LoginModule:OnInitReturn] Puffer init error: ", ErrorCode)
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateError)
  local PufferErrorCodeDesc = require("Core.Service.GCloud.PufferErrorCodeDesc")
  _G.GEMPostManager:GEMPostStepEvent("UpdateResSuccess", PufferErrorCodeDesc:GetDesc(ErrorCode))
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(PufferErrorCodeDesc:GetDesc(ErrorCode)):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
    if not result then
      self:PufferBackToSDKLoginSuccessState()
    else
      self:PufferRetryUpdate()
    end
  end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function LoginModule:OnDownloadBatchProgress(BatchTaskId, NowSize, TotalSize)
  local Percent = 0
  if 0 ~= TotalSize then
    Percent = NowSize / TotalSize
  end
  local UpdateTask = _G.PufferUpdateResTask
  Log.Debug("LoginModule:OnDownloadBatchProgress...", BatchTaskId, Percent, UpdateTask:GetCurrentSpeed())
  self:SetProgress(Percent, UpdateStageLocalText.PufferBasePaksDownloading, UpdateTask:FormatBytes(TotalSize), UpdateTask:FormatBytes(NowSize), UpdateTask:GetCurrentSpeed())
end

function LoginModule:OnPufferDownloadBatchReturn(BatchTaskId, FiledId, IsSuccess, ErrorCode, BatchType, SingleFileErrorCode)
  _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
  if IsSuccess then
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadEnd, LoginEnum.DownloadReportType.BaseDownloadEnd, BatchTaskId)
    Log.Warning("[LoginModule:OnPufferDownloadBatchReturn] Base pak download finish")
    self:PostPufferResAllUpdateDoneEvent()
  else
    Log.Error(string.format("[LoginModule:OnPufferDownloadBatchReturn] ErrorCode:%s, BatchType:%s, FiledId:%s", ErrorCode, BatchType, FiledId))
    if BatchType == UE.PufferBatchDownloadType.PBT_BatchTask then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.UpdateError)
      local PufferErrorCodeDesc = require("Core.Service.GCloud.PufferErrorCodeDesc")
      local ErrorCodeDescContent = PufferErrorCodeDesc:GetDesc(ErrorCode)
      Log.Debug("[UpdateUIModule:OnPufferDownloadBatchReturn] Batch ErrorCodeDesc:", ErrorCodeDescContent)
      if SingleFileErrorCode and 0 ~= SingleFileErrorCode then
        ErrorCodeDescContent = PufferErrorCodeDesc:GetDesc(SingleFileErrorCode)
        Log.Debug("[UpdateUIModule:OnPufferDownloadBatchReturn] File ErrorCodeDesc:", ErrorCodeDescContent)
      end
      local ReportErrorCode
      if SingleFileErrorCode and 0 ~= SingleFileErrorCode then
        ReportErrorCode = SingleFileErrorCode
      else
        ReportErrorCode = ErrorCode
      end
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, string.format("ErrorCode:%s", ReportErrorCode), BatchTaskId)
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(ErrorCodeDescContent):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
        if not result then
          self:PufferBackToSDKLoginSuccessState()
        else
          self:PufferRetryUpdate()
        end
      end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
end

function LoginModule:OnPufferNetworkStatusChanged(NewStatus)
  Log.Debug("[LoginModule:OnPufferNetworkStatusChanged] Receiving network change callback", NewStatus, self.CurrentNetworkStatus or 0)
  if not self.CurrentNetworkStatus then
    self.CurrentNetworkStatus = 0
    Log.Debug("[LoginModule:OnPufferNetworkStatusChanged] set CurrentNetworkStatus to 0")
  end
  local LastNetworkStatus = self.CurrentNetworkStatus
  self.CurrentNetworkStatus = NewStatus
  if self.bPufferOpenNoWifiNoticeDialog then
    Log.Warning("[LoginModule:OnPufferNetworkStatusChanged] self.bPufferOpenNoWifiNoticeDialog = true")
    return
  end
  if 0 ~= LastNetworkStatus and 0 == NewStatus then
  elseif 1 ~= LastNetworkStatus and 1 == NewStatus then
    local NetworkType = UE.UNetworkStatics.GetNetworkState()
    if 1 ~= NetworkType then
      Log.Debug("[LoginModule:OnPufferNetworkStatusChanged] network status is already not WWAN")
      return
    end
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(false)
    local TaskId = self.data:GetDownloadingTaskId()
    if not _G.PufferUpdateResTask:IsTaskDownloading(TaskId) then
      Log.Warning("[LoginModule:OnPufferNetworkStatusChanged] Task is not downloading")
      return
    end
    Log.Debug("[LoginModule:OnPufferNetworkStatusChanged] Pause download puffer task")
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Pause download because no wifi", TaskId)
    local bPuaseSuccess = _G.PufferUpdateResTask:PauseTask(TaskId)
    if bPuaseSuccess then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PufferNoWifi)
    else
      Log.Error("[LoginModule:OnPufferNetworkStatusChanged] Pause download puffer task failed")
      self:PufferRetryUpdate()
    end
  end
end

function LoginModule:PufferOpenNoWifiNoticeDialog()
  self.bPufferOpenNoWifiNoticeDialog = true
  local Context = DialogContext()
  Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
    self.bPufferOpenNoWifiNoticeDialog = false
    if result then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.ContinuePufferUpdate)
    else
      self:PufferBackToSDKLoginSuccessState()
    end
  end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnNetworkStatusTurnToWifi(Context.EAutoCloseOnWifiBtnHandlerType.OK)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function LoginModule:PufferResumeDownload()
  Log.Debug("[LoginModule:PufferResumeDownload]")
  local bSuccess = _G.PufferUpdateResTask:ResumeTask(self.data:GetDownloadingTaskId())
  if bSuccess then
    _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
    Log.Debug("[LoginModule:PufferResumeDownload] Resume puffer download success")
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, LoginEnum.DownloadReportType.BaseDownloadBegin, self.data:GetDownloadingTaskId())
  else
    self:PufferRetryUpdate()
  end
end

function LoginModule:PufferRetryUpdate()
  Log.Warning("[LoginModule:PufferRetryUpdate]")
  _G.DelayManager:DelayFrames(1, function()
    self:CancelUpdates()
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
  end)
end

function LoginModule:PufferBackToSDKLoginSuccessState()
  Log.Debug("[LoginModule:PufferBackToSDKLoginSuccessState]")
  _G.DelayManager:DelayFrames(1, function()
    self:CancelUpdates()
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.BackToSDKLoginSuccess)
  end)
end

function LoginModule:CancelUpdates()
  self:UnRegisterPufferEvents()
  _G.PufferUpdateResTask:RemoveAllTasks()
end

function LoginModule:MountDownloadedPaks()
  if not RocoEnv.IS_EDITOR then
    local BasePakList = _G.PufferDownloadInfo:GetBasePakListWithPatch()
    if not _G.PufferUpdateResTask:MountPakList(BasePakList) then
      Log.Error("[LoginModule:MountDownloadedPaks] mount failed")
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Mount failed")
      LoginUtils.ShowPufferGenericErrorDailog(-3, UE4.UNRCStatics.QuitGame, function()
        _G.DelayManager:DelayFrames(1, function()
          self:CancelUpdates()
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
        end)
      end)
      return
    end
  end
  _G.GEMPostManager:GEMPostStepEvent("UpdateEndState")
  _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.MountDownloadedPakDone)
end

function LoginModule:LoadLoginNoticeData(callBackOwner, callBack)
  self:Log("LoadLoginNoticeData")
  self.LoadLoginNoticeCallBackOwner = callBackOwner
  self.LoadLoginNoticeCallBack = callBack
  UE4.UNoticeStatics.LoadNoticeData("login", "0")
end

function LoginModule:CancelLoadLoginNoticeCallback()
  self:Log("CancelLoadLoginNoticeCallback")
  self.LoadLoginNoticeCallBackOwner = nil
  self.LoadLoginNoticeCallBack = nil
end

function LoginModule:OnLoadLoginNoticeData(noticeList)
  self:Log("OnLoadLoginNoticeData")
  if self.LoadLoginNoticeCallBack then
    if self.LoadLoginNoticeCallBackOwner then
      self.LoadLoginNoticeCallBack(self.LoadLoginNoticeCallBackOwner, noticeList)
    else
      self.LoadLoginNoticeCallBack(noticeList)
    end
  end
  self.LoadLoginNoticeCallBackOwner = nil
  self.LoadLoginNoticeCallBack = nil
end

function LoginModule:StartDownloadBaseRes()
  local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
  if NeedToDownloadBasePakList then
    if #NeedToDownloadBasePakList > 0 then
      Log.Debug("[LoginModule:DownloadBasePak] get total file size: ", SizeNeedToDownload)
      if not self:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize) then
        return
      end
      self:CheckInternetConnection(function(this)
        local BasePakTaskId = _G.PufferUpdateResTask:DownloadBatchListByPakList(NeedToDownloadBasePakList)
        if BasePakTaskId then
          _G.NRCBackgroundDownloadMgr:SetIsUpdating(true)
          _G.NRCBackgroundDownloadMgr:SetBackgroundDownloadInfo(UE4.EBackgroundDownloadType.Base, BasePakTaskId)
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBegin, LoginEnum.DownloadReportType.BaseDownloadBegin, BasePakTaskId)
        else
          _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Create Puffer Task Failed")
        end
        this.data:SetDownloadingTaskId(BasePakTaskId)
      end, self, SizeNeedToDownload)
    else
      Log.Debug("[LoginModule:DownloadBasePak] No Base Pak Need To Download")
      self:PostPufferResAllUpdateDoneEvent()
    end
  else
    self:OnPufferInitFailed(-2)
  end
end

function LoginModule:CheckPufferFreeDiskSpace(SizeNeedToDownload, LargestSize)
  Log.Debug(string.format("[LoginModule:CheckPufferFreeDiskSpace] get total file size:%s largestSize:%s ", SizeNeedToDownload, LargestSize))
  local FreeDiskSpace = UE.UNRCStatics.GetFreeDiskSpace()
  Log.Debug("[LoginModule:CheckPufferFreeDiskSpace] FreeDiskSpace:", FreeDiskSpace)
  local BytesRequired = SizeNeedToDownload + LargestSize * 2
  local RealLimitSpace = BytesRequired / 1024 / 1024
  Log.Debug("[LoginModule:CheckPufferFreeDiskSpace] RealLimitSpace:", RealLimitSpace)
  if FreeDiskSpace >= 0 and FreeDiskSpace < RealLimitSpace then
    _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "No Free Disk Space")
    self:CancelUpdates()
    local LimitSpace = BytesRequired / 1000 / 1000 / 1000
    local ShowRet = CloudGameUtil:TryShowCloudGameDialog(LuaText.cloudgame_disk_space_tips, false)
    if not ShowRet then
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(string.format(LuaText.free_disk_space_check_tips, LimitSpace)):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
        if not result then
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.BackToSDKLoginSuccess)
        else
          LoginUtils.SendEventToLoginFsm(LoginModuleEvent.RetryUpdate)
        end
      end):SetButtonText(LuaText.RETRY, LuaText.umg_minigame_giveup_1)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
    return false
  end
  return true
end

function LoginModule:CheckInternetConnection(Callback, Caller, SizeNeedToDownload)
  local NetworkType = UE.UNetworkStatics.GetNetworkState()
  if 1 == NetworkType then
    self.CurrentNetworkStatus = 1
    if SizeNeedToDownload then
      local SizeNeedToDownloadMB = SizeNeedToDownload / 1024 / 1024
      if SizeNeedToDownloadMB <= NoWifiNotciceMBThreshold then
        Log.Debug("[LoginModule:CheckInternetConnection] skip no wifi notice")
        Callback(self)
        return
      end
    end
    local Context = DialogContext()
    Context:SetTitle(LuaText.updateuimodule_24):SetContent(LuaText.updateuimodule_25):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
      if result then
        Callback(self)
      else
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Reject download because no wifi")
        Log.Warning("Cancel Update")
        self:PufferBackToSDKLoginSuccessState()
      end
    end):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    self.CurrentNetworkStatus = 2
    Callback(self)
  end
end

function LoginModule:BindCameraToController()
  local CameraActor
  local CameraActorList = UE4.UGameplayStatics.GetAllActorsOfClass(UE4Helper.GetCurrentWorld(), UE4.ACineCameraActor)
  for _, actor in tpairs(CameraActorList) do
    CameraActor = actor
  end
  local Controller = LoginUtils.GetLoginController()
  Controller:SetViewTargetWithBlend(CameraActor, 1)
  Controller.centerCamera = CameraActor
end

function LoginModule:TryAutoLogin()
  if _G.GlobalConfig.UserKickedOutFromGame then
  end
  Log.Debug("TryAutoLogin")
  self:ReportSensitive()
  UE4.ULoginStatics.AutoLogin()
end

function LoginModule:TryWeGameReqTicket()
  Log.Debug("TryWeGameReqTicket invoked")
  if _G.GlobalConfig.UserKickedOutFromGame then
  end
  local WeGameManager = UE4.UNRCPlatformGameInstance.GetInstance():GetSDKManager().WeGameManager
  WeGameManager:StartAsyncReqTicket("Login")
end

function LoginModule:TryNetBarReq()
  if RocoEnv.PLATFORM_WINDOWS then
    local gameId = tonumber(UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.NetBarSettings", "GameId"))
    local zoneId = tonumber(UE4.UNRCStatics.GetStringFromGGameIni("/Script/NRC.NetBarSettings", "ZoneId"))
    local openId = tostring(LoginUtils.GetLoginData():GetOpenID())
    local token = tostring(LoginUtils.GetLoginData():GetToken())
    Log.Info("LoginModule:TryNetBarReq gameId:", gameId, " zoneId:", zoneId, " openId:", openId, " token:", token)
    UE.UNetBarStatics.ReqNetbarLv2(gameId, zoneId, openId, token, 3000)
  end
end

function LoginModule:CheckNeedNoticeUpgradeDriverVersion()
  if not RocoEnv.PLATFORM_ANDROID then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
    Log.Debug("[LoginModule:CheckNeedNoticeUpgradeDriverVersion] check only android")
    return
  end
  if self.HasShowedLowEndDeviceNotice then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
    Log.Debug("[LoginModule:CheckNeedNoticeUpgradeDriverVersion] \228\184\128\230\172\161\230\184\184\231\142\169\229\143\170\230\152\190\231\164\186\228\184\128\230\172\161")
    return
  end
  if UE.UNRCPlatformStatics.IsQualcommWithOldDriver and UE.UNRCPlatformStatics.IsQualcommWithOldDriver() then
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "r.ScreenPercentage 40")
  end
  local JsonObj = JsonUtils.LoadSaved("NoticeUpgradeDriverVersion", {bShowed = false})
  if JsonObj and JsonObj.bShowed then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
    Log.Debug("[LoginModule:CheckNeedNoticeUpgradeDriverVersion] \228\184\128\230\172\161\229\174\137\232\163\133\229\143\170\230\152\190\231\164\186\228\184\128\230\172\161")
    return
  end
  local bNeedShowNotice = false
  local DriverVersion = 378
  if UE.UNRCPlatformStatics.IsAdreno6xxWithOldDriver() then
    DriverVersion = 444
    bNeedShowNotice = true
  elseif UE.UNRCPlatformStatics.IsQualcommWithOldDriver and UE.UNRCPlatformStatics.IsQualcommWithOldDriver() then
    bNeedShowNotice = true
  end
  if bNeedShowNotice then
    JsonUtils.DumpSaved("NoticeUpgradeDriverVersion", {bShowed = true})
    self.HasShowedLowEndDeviceNotice = true
    local Context = DialogContext()
    Context:SetTitle(LuaText.onlinemodule_1):SetContent(string.format(LuaText.low_device_performance_tips, tostring(DriverVersion))):SetMode(DialogContext.Mode.OK):SetButtonText(LuaText.tips_dialog_butten_accept):SetCallback(self, function(this, result)
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
    end)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.DeviceCheckPassed)
  end
end

function LoginModule:AccountSwitchOnPC()
  Log.Debug("AccountSwitchOnPC")
  UE4.UNRCStatics.QuitGame()
end

function LoginModule:PopConfirmWindow(...)
  LoginUtils.PopConfirmWindow(self, ...)
end

function LoginModule:PopUpWindow(...)
  LoginUtils.ShowPopUpWindow(self, ...)
end

function LoginModule:ShowBanner(...)
  LoginUtils.ShowBanner(self, ...)
end

function LoginModule:OnDialogResult(result, ConfirmEvent, CancelEvent)
  self:Log("OnDialogResult", result)
  if result then
    LoginUtils.SendEventToLoginFsm(ConfirmEvent)
  else
    LoginUtils.SendEventToLoginFsm(CancelEvent)
  end
end

function LoginModule:OnStartLogin(caller, callback)
  function self.LoginPanelCallback()
    callback(caller)
  end
end

function LoginModule:ShowPanel(PanelName, TurnOn, Caller, Callback)
  if TurnOn then
    local boo, v = self:HasPanel(PanelName)
    if boo then
      if Callback then
        Callback(Caller)
      end
    else
      LoginUtils.RegisterCallback(self, Caller, Callback)
      self:OpenPanel(PanelName, TurnOn, Caller, Callback)
      self.CurrentPanelName = PanelName
    end
  else
    self:ClosePanel(PanelName)
    if Callback then
      Callback(Caller)
    end
  end
end

function LoginModule:OnOpenPanelCallback(panelName, panelIndex, isSucc)
  NRCModuleBase.OnOpenPanelCallback(self, panelName, panelIndex, isSucc)
  if panelName == self.CurrentPanelName then
    LoginUtils.CallAndRemoveCallback(self)
  end
  if "LoginPanel" == panelName then
    self:LoginPanelCallback()
  end
end

function LoginModule:OverwriteWorldVisibility(bSetAllInvisible)
  UE4Helper.SetEnableWorldRendering(not bSetAllInvisible)
  local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(UE4Helper.GetCurrentWorld(), UE4.AActor):ToTable()
  for i = 1, #AllActors do
    local curActor = AllActors[i]
    curActor:SetActorTickEnabled(not bSetAllInvisible)
  end
end

function LoginModule:PlayVideo(VideoPath, bLoop, ...)
  local Panel = self:GetPanel(self.CurrentPanelName)
  if not Panel then
    Log.Error("Panel Not Opened Yet")
    return
  end
  return Panel:PlayVideo(VideoPath, bLoop, ...)
end

function LoginModule:ReqEnter()
  self:Log("LoginModule:ReqEnter")
  NRCEventCenter:RegisterEvent("LoginModule", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  NRCModuleManager:DoCmd(UpdateUIModuleCmd.OpenMainPanel, false)
  NRCModuleManager:DoCmd(AppearanceLoginModuleCmd.OpenBeautyLoginPanel, false)
  local AccountInfos = JsonUtils.LoadSaved("DebugTabAccounts", {})
  local username = self.data:GetOpenID()
  if AccountInfos and not AccountInfos[username] then
    AccountInfos[username] = 0
    JsonUtils.DumpSaved("DebugTabAccounts", AccountInfos)
  end
  NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 0.1)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  self:CloseAllPanel()
  self.EnterBigWorldDelayId = nil
  NRCModeManager:ActiveMode("BigWorldMode")
end

function LoginModule:OnConnected()
  if self.EnterBigWorldDelayId then
    DelayManager:CancelDelayById(self.EnterBigWorldDelayId)
    self.EnterBigWorldDelayId = nil
  end
end

function LoginModule:GetMainLoginFsm()
  if self.LoginFsm then
    return self.LoginFsm
  else
    return NRCModuleManager:DoCmd(CreatePlayerModuleCmd.GetCreatePlayerFsm)
  end
end

function LoginModule:RegPanel(name, path, layer, openAnimName, closeAnimName, disablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/LoginModule/%s", path)
  registerData.panelLayer = layer
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = not disablePcEsc
  self:RegisterPanel(registerData)
end

function LoginModule:OpenStrongPopUpPanel(noticeInfo)
  if AppMain.launchParams.disable_login_pop_up then
    return
  end
  self:OpenPanel("UMG_Login_StrongPopUp", noticeInfo)
end

function LoginModule:CloseStrongPopUpPanel()
  self:ClosePanel("UMG_Login_StrongPopUp")
end

function LoginModule:OpenAnnouncementPanel(NoticeList)
  self:OpenPanel("AnnouncementPanel", NoticeList)
end

function LoginModule:SetAnnouncementNotice(NoticeContent)
  if self:HasPanel("AnnouncementPanel") then
    local AnnouncementPanel = self:GetPanel("AnnouncementPanel")
    AnnouncementPanel:SetNoticeContent(NoticeContent)
  end
end

function LoginModule:SetTLogInfo()
  local netWork = _G.NRCNetworkManager:GetTConndRTT()
end

function LoginModule:OnLoginActionEnter(fsm, action)
  _G.GEMPostManager:GEMPostStepEvent(action.name)
end

function LoginModule:OnEnterForeground()
  if self.WaitingUIOn then
    self:CleanTimeoutTimer()
    self.hasTimeoutTimer = true
    DelayManager:DelayFrames(1, self.DelayTimeoutCheckNextFrame, self)
  end
end

function LoginModule:DelayTimeoutCheckNextFrame()
  if self.WaitingUIOn then
    DelayManager:DelaySeconds(10, self.OnLoginTimeOut, self)
  end
end

function LoginModule:CleanTimeoutTimer()
  if self.hasTimeoutTimer then
    Log.Debug("[LoginModule][CleanTimeoutTimer]")
    DelayManager:CancelDelay(self.OnLoginTimeOut)
    DelayManager:CancelDelay(self.DelayTimeoutCheckNextFrame)
    self.hasTimeoutTimer = false
  end
end

function LoginModule:EnableSelection()
  Log.Error("EnableSelection")
  if not self:HasPanel("CharacterPick") then
    self:OpenPanel("CharacterPick")
  else
    local panel = self:GetPanel("CharacterPick")
    panel:OnActive()
  end
end

function LoginModule:SetConditionInData(Condition, Value)
  Log.Debug("LoginModule SetConditionInData with Condition: ", Condition, ", and Value:", Value)
  if self.data then
    self.data:SetCondition(Condition, Value)
  end
end

function LoginModule:ShowFailInfo()
  Log.PrintScreenMsg("ShowFailInfo invoked")
  local errCode = self.data:GetCondition(LoginEnum.Conditions.LoginResCode)
  LoginUtils.PopConfirmWindow(self, "", string.format(LuaText.wegame_login_fail_tips .. "(" .. LuaText.error_tip .. ")", errCode), "FINISHED", "", true)
end

function LoginModule:ShowAgreement()
  if self.data:GetCondition(LoginEnum.Conditions.FirstTimeInstall) == nil or self.data:GetCondition(LoginEnum.Conditions.FirstTimeInstall) then
    Log.Debug("FirstTime install")
    self:OverwriteAndSaveCondition(LoginEnum.Conditions.FirstTimeInstall, false)
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PopUpWindowConfirm)
    return
  end
  self:OverwriteAndSaveCondition(LoginEnum.Conditions.FirstTimeInstall, false)
  local AgreementConfig = _G.DataConfigManager:GetGlobalConfig("login_notice")
  if nil == AgreementConfig then
    Log.Error("Empty agreement config")
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PopUpWindowConfirm)
    return
  end
  local Context = DialogContext()
  Context:SetTitle(AgreementConfig.title):SetContent(AgreementConfig.str):SetCloseOnCancel(true):SetButtonText(AgreementConfig.button_right, AgreementConfig.button_left)
  self:OpenPanel("PrivacyTips", Context)
end

function LoginModule:SetCurRegisterGender(gender)
  self.data:SetRegisterGender(gender)
end

function LoginModule:GetCurRegisterGender()
  return self.data:GetRegisterGender()
end

function LoginModule:SetNeedDelayRotation(bNeedDelayRotation)
  self.data:SetNeedDelayRotation(bNeedDelayRotation)
end

function LoginModule:GetNeedDelayRotation()
  return self.data:GetNeedDelayRotation()
end

function LoginModule:OnCmdCheckNameUsable()
  local hasPanel = self:HasPanel("CharacterPick")
  if hasPanel then
    local panel = self:GetPanel("CharacterPick")
    panel:CheckNameUsable()
  end
end

return LoginModule
